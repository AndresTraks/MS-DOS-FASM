;TITLE DIRCALL - Directory manipulation internal calls

; $MKDIR
; $CHDIR
; $RMDIR

        ASSUME  SS:DOSGROUP,CS:DOSGROUP

        i_need  AUXSTACK,BYTE
        i_need  NoSetDir,BYTE
        i_need  CURBUF, DWORD
        i_need  DIRSTART,WORD
        i_need  THISDPB,DWORD
        i_need  NAME1,BYTE
        i_need  LASTENT,WORD
        i_need  ATTRIB,BYTE
        i_need  THISFCB,DWORD
        i_need  AUXSTACK,BYTE
        i_need  CREATING,BYTE
        i_need  DRIVESPEC,BYTE
        i_need  ROOTSTART,BYTE
        i_need  SWITCH_CHARACTER,BYTE

; XENIX CALLS
;BREAK <$MkDir - Make a directory entry>
MKNERRJ: JMP    MKNERR
NODEEXISTSJ: JMP NODEEXISTS
        procedure   _MKDIR,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX Points to asciz name
; Function:
;       Make a new directory
; Returns:
;       STD XENIX Return
;       AX = mkdir_path_not_found if path bad
;       AX = mkdir_access_denied  If
;               Directory cannot be created
;               Node already exists
;               Device name given
;               Disk or directory(root) full
        invoke  Validate_path
        JC      MKNERRJ
        MOV     SI,DX
        MOV     WORD [SS:THISFCB+2],SS
        MOV     WORD [SS:THISFCB],AuxStack-40  ; Scratch space
        MOV     AL,attr_directory
        MOV     WORD [SS:CREATING],0E500h
        invoke  MAKENODE
ASSUME  DS:DOSGROUP
        MOV     AL,mkdir_path_not_found
        JC      MKNERRJ
        JNZ     NODEEXISTSJ
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
        SUB     SI,DI
        PUSH    SI              ; Pointer to fcb_FIRCLUS
        PUSH    [DI+BUFFINFO.BUFSECNO]   ; Sector of new node
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        PUSH    [DIRSTART]      ; Parent for .. entry
        XOR     AX,AX
        MOV     [DIRSTART],AX   ; Null directory
        invoke  NEWDIR
        JC      NODEEXISTSPOPDEL    ; No room
        invoke  GETENT          ; First entry
        LES     DI,[CURBUF]
        MOV     [ES:DI+BUFFINFO.BUFDIRTY],1
        ADD     DI,BUFINSIZ     ; Point at buffer
        MOV     AX,202EH        ; ". "
        STOSW
        MOV     DX,[DIRSTART]   ; Point at itself
        invoke  SETDOTENT
        MOV     AX,2E2EH        ; ".."
        STOSW
        POP     DX              ; Parent
        invoke  SETDOTENT
        LES     BP,[THISDPB]
        POP     DX              ; Entry sector
        XOR     AL,AL           ; Pre read
        invoke  GETBUFFR
        MOV     DX,[DIRSTART]
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
ZAPENT:
        POP     SI              ; fcb_Firclus pointer
        ADD     SI,DI
        MOV     [SI],DX
        XOR     DX,DX
        MOV     [SI+2],DX
        MOV     [SI+4],DX
DIRUP:
        MOV     [DI+BUFFINFO.BUFDIRTY],1
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     AL,[ES:BP+dpb.dpb_drive]
        invoke  FLUSHBUF
SYS_RET_OKJ:
        JMP     SYS_RET_OK

NODEEXISTSPOPDEL:
        POP     DX              ; Parent
        POP     DX              ; Entry sector
        LES     BP,[THISDPB]
        XOR     AL,AL           ; Pre read
        invoke  GETBUFFR
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
        POP     SI              ; dir_first pointer
        ADD     SI,DI
        SUB     SI,dir_entry.dir_first    ; Point back to start of dir entry
        MOV     BYTE [SI],0E5H    ; Free the entry
        CALL    DIRUP
NODEEXISTS:
        MOV     AL,mkdir_access_denied
MKNERR:
        JMP     SYS_RET_ERR

;BREAK <$ChDir -- Change current directory on a drive>
        procedure   _CHDIR,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX Points to asciz name
; Function:
;       Change current directory
; Returns:
;       STD XENIX Return
;       AX = chdir_path_not_found if error

        invoke  Validate_path
        JC      PATHTOOLONG

        PUSH    DS
        PUSH    DX
        MOV     SI,DX
        invoke  GETPATH
        JC      PATHNOGOOD
        JNZ     PATHNOGOOD
ASSUME  DS:DOSGROUP
        MOV     AX,[DIRSTART]
        MOV     BX,AX
        XCHG    BX,[ES:BP+dpb.dpb_current_dir]
        OR      AX,AX
        POP     SI
        POP     DS
ASSUME  DS:NOTHING
        JZ      SYS_RET_OKJ
        MOV     DI,BP
        ADD     DI,dpb.dpb_dir_text
        MOV     DX,DI
        CMP     [SS:DRIVESPEC],0
        JZ      NODRIVESPEC
        INC     SI
        INC     SI
NODRIVESPEC:
        MOV     CX,SI
        CMP     [SS:ROOTSTART],0
        JZ      NOTROOTPATH
        INC     SI
        INC     CX
        JMP     SHORT COPYTHESTRINGBXZ
NOTROOTPATH:
        OR      BX,BX           ; Previous path root?
        JZ      COPYTHESTRING   ; Yes
        XOR     BX,BX
ENDLOOP:
        CMP     BYTE [ES:DI],0
        JZ      PATHEND
        INC     DI
        INC     BX
        JMP     SHORT ENDLOOP
PATHEND:
        MOV     AL,'/'
        CMP     AL,[SS:switch_character]
        JNZ     SLASHOK
        MOV     AL,'\'                  ; Use the alternate character
SLASHOK:
        STOSB
        INC     BX
        JMP     SHORT CHECK_LEN

PATHNOGOOD:
        POP     AX
        POP     AX
PATHTOOLONG:
        error   error_path_not_found

ASSUME  DS:NOTHING

INCBXCHK:
        INC     BX
BXCHK:
        CMP     BX,DIRSTRLEN
        return

COPYTHESTRINGBXZ:
        XOR     BX,BX
COPYTHESTRING:
        LODSB
        OR      AL,AL

        JNZ     FOOB
        JMP     CPSTDONE
FOOB:
        CMP     AL,'.'
        JZ      SEEDOT
        CALL    COPYELEM
CHECK_LEN:
        CMP     BX,DIRSTRLEN
        JB      COPYTHESTRING
        MOV     AL,[ES:DI-1]
        invoke  PATHCHRCMP
        JNZ     OK_DI
        DEC     DI
OK_DI:
        XOR     AL,AL
        STOSB                   ; Correctly terminate the path
        MOV     [ES:BP+dpb.dpb_current_dir],-1      ; Force re-validation
        JMP     SHORT PATHTOOLONG

SEEDOT:
        LODSB
        OR      AL,AL           ; Check for null
        JZ      CPSTDONEDEC
        CMP     AL,'.'
        JNZ     COPYTHESTRING   ; eat ./
        CALL    DELELMES        ; have   ..
        LODSB                   ; eat the /
        OR      AL,AL           ; Check for null
        JZ      CPSTDONEDEC
        JMP     SHORT COPYTHESTRING

; Copy one element from DS:SI to ES:DI include trailing / not trailing null
; LODSB has already been done
COPYELEM:
        PUSH    DI                      ; Save in case too long
        PUSH    CX
        MOV     CX,800h                 ; length of filename
        MOV     AH,'.'                  ; char to stop on
        CALL    CopyPiece               ; go for it!
        CALL    BXCHK                   ; did we go over?
        JAE     POPCXDI                 ; yep, go home
        CMP     AH,AL                   ; did we stop on .?
        JZ      CopyExt                 ; yes, go copy ext
        OR      AL,AL                   ; did we end on nul?
        JZ      DECSIRET                ; yes, bye
CopyPathEnd:
        STOSB                           ; save the path char
        CALL    INCBXCHK                ; was there room for it?
        JAE     POPCXDI                 ; Nope
        INC     SI                      ; guard against following dec
DECSIRET:
        DEC     SI                      ; point back at null
        POP     CX
        POP     AX                      ; toss away saved DI
        return
POPCXDI:
        POP     CX                      ; restore
        POP     DI                      ; point back...
        return
CopyExt:
        STOSB                           ; save the dot
        CALL    INCBXCHK                ; room?
        JAE     POPCXDI                 ; nope.
        LODSB                           ; get next char
        XOR     AH,AH                   ; NUL here
        MOV     CX,300h                 ; at most 3 chars
        CALL    CopyPiece               ; go copy it
        CALL    BXCHK                   ; did we go over
        JAE     POPCXDI                 ; yep
        OR      AL,AL                   ; sucessful end?
        JZ      DECSIRET                ; yes
        JMP     CopyPathEnd             ; go stash path char

DELELMES:
; Delete one path element from ES:DI
        DEC     DI                      ; the '/'
        DEC     BX

        IF      KANJI
        PUSH    AX
        PUSH    CX
        PUSH    DI
        PUSH    DX
        MOV     CX,DI
        MOV     DI,DX
DELLOOP:
        CMP     DI,CX
        JZ      GOTDELE
        MOV     AL,ES:[DI]
        INC     DI
        invoke  TESTKANJ
        JZ      NOTKANJ11
        INC     DI
        JMP     DELLOOP

NOTKANJ11:
        invoke  PATHCHRCMP
        JNZ     DELLOOP
        MOV     DX,DI                   ; Point to char after '/'
        JMP     DELLOOP

GOTDELE:
        MOV     DI,DX
        POP     DX
        POP     AX                      ; Initial DI
        SUB     AX,DI                   ; Distance moved
        SUB     BX,AX                   ; Set correct BX
        POP     CX
        POP     AX
        return
        ELSE
DELLOOP:
        CMP     DI,DX
        jz DELLOOP
        PUSH    AX
        MOV     AL,[ES:DI-1]
        invoke  PATHCHRCMP
        POP     AX
        jz DELLOOP
        DEC     DI
        DEC     BX
        JMP     SHORT DELLOOP
        END IF

CPSTDONEDEC:
        DEC     DI                      ; Back up over trailing /
CPSTDONE:
        STOSB                           ; The NUL
        JMP     SYS_RET_OK

; copy a piece CH chars max until the char in AH (or path or NUL)
CopyPiece:
        STOSB                           ; store the character
        INC     CL                      ; moved a byte
        CALL    INCBXCHK                ; room enough?
        JAE     CopyPieceRet            ; no, pop CX and DI
        OR      AL,AL                   ; end of string?
        JZ      CopyPieceRet            ; yes, dec si and return

        IF KANJI
        CALL    TestKanj                ; was it kanji?
        JZ      NotKanj                 ; nope
        MOVSB                           ; move the next byte
        CALL    INCBXCHK                ; room for it?
        JAE     CopyPieceRet            ; nope
        INC     CL                      ; moved a byte
NotKanj:
        END IF

        CMP     CL,CH                   ; move too many?
        JBE     CopyPieceNext           ; nope

        IF KANJI
        CALL    TestKanj                ; was the last byte kanji
        JZ      NotKanj2                ; no only single byte backup
        DEC     DI                      ; back up a char
        DEC     BX
NotKanj2:
        END IF

        DEC     DI                      ; back up a char
        DEC     BX
CopyPieceNext:
        LODSB                           ; get next character
        invoke  PATHCHRCMP              ; end of road?
        JZ      CopyPieceRet            ; yep, return and don't dec SI
        CMP     AL,AH                   ; end of filename?
        JNZ     CopyPiece               ; go do name
CopyPieceRet:
        return                          ; bye!

;BREAK <$RmDir -- Remove a directory>
NOPATHJ: JMP    NOPATH

        procedure   _RMDIR,NEAR         ; System call 47
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX Points to asciz name
; Function:
;       Delete directory if empty
; Returns:
;       STD XENIX Return
;       AX = rmdir_path_not_found If path bad
;       AX = rmdir_access_denied If
;               Directory not empty
;               Path not directory
;               Root directory specified
;               Directory malformed (. and .. not first two entries)
;       AX = rmdir_current_directory

        invoke  Validate_path
        JC      NOPATHJ
        MOV     SI,DX
        invoke  GETPATH
        JC      NOPATHJ
ASSUME  DS:DOSGROUP
        JNZ     NOTDIRPATH
        MOV     DI,[DIRSTART]
        OR      DI,DI
        JZ      NOTDIRPATH
        MOV     CX,[ES:BP+dpb.dpb_current_dir]
        CMP     CX,-1
        JNZ     rmdir_current_dir_check
        invoke  GETCURRDIR
        invoke  get_user_stack
        MOV     DX,[SI+user_environ.user_DX]
        MOV     DS,[SI+user_environ.user_DS]
        JMP     _RMDIR

NOTDIRPATHPOP:
        POP     AX
        POP     AX
NOTDIRPATH:
        error   error_access_denied

rmdir_current_dir_check:
        CMP     DI,CX
        JNZ     rmdir_get_buf
        error   error_current_directory

rmdir_get_buf:
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
        SUB     BX,DI
        PUSH    BX                      ; Save entry pointer
        PUSH    [DI+BUFFINFO.BUFSECNO]           ; Save sector number
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        PUSH    SS
        POP     ES
        MOV     DI,NAME1
        MOV     AL,'?'
        MOV     CX,11
        REP     STOSB
        XOR     AL,AL
        STOSB
        invoke  STARTSRCH
        invoke  GETENTRY
        MOV     DS,WORD [CURBUF+2]
ASSUME  DS:NOTHING
        MOV     SI,BX
        LODSW
        CMP     AX,(' ' SHL 8) OR '.'
        JNZ     NOTDIRPATHPOP
        ADD     SI,32-2
        LODSW
        CMP     AX,('.' SHL 8) OR '.'
        JNZ     NOTDIRPATHPOP
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     [LASTENT],2             ; Skip . and ..
        invoke  GETENTRY
        MOV     [ATTRIB],attr_directory+attr_hidden+attr_system
        invoke  SRCH
        JNC     NOTDIRPATHPOP
        LES     BP,[THISDPB]
        MOV     BX,[DIRSTART]
        invoke  RELEASE
        POP     DX
        XOR     AL,AL
        invoke  GETBUFFR
        LDS     DI,[CURBUF]
ASSUME  DS:NOTHING
        POP     BX
        ADD     BX,DI
        MOV     BYTE [BX],0E5H      ; Free the entry
        JMP     DIRUP

NOPATH:
        error   error_path_not_found

        do_ext
