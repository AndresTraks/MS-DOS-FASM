;
; xenix file calls for MSDOS
;

        ASSUME  SS:DOSGROUP,CS:DOSGROUP

;TITLE   XENIX - IO system to mimic UNIX

        i_need  NoSetDir,BYTE
        i_need  CURDRV,BYTE
        i_need  IOCALL,BYTE
        i_need  IOMED,BYTE
        i_need  IOSCNT,WORD
        i_need  IOXAD,DWORD
        i_need  DIRSTART,WORD
        i_need  ATTRIB,BYTE
        i_need  THISFCB,DWORD
        i_need  AuxStack,BYTE
        i_need  Creating,BYTE
        i_need  ThisDRV,BYTE
        i_need  NAME1,BYTE
        i_need  LastEnt,WORD
        i_need  ThisDPB,DWORD
        i_need  EntLast,WORD
        i_need  CurrentPDB,WORD
        i_need  sft_addr,DWORD              ; pointer to head of table
        i_need  CURBUF,DWORD                ; pointer to current buffer
        i_need  DMAADD,DWORD                ; pointer to current dma address

;BREAK <Local data>


;BREAK <Validate_path - check to see if there are meta characters in path>

;
; Input: DS:DX is an ASCIZ path
; Output: Carry set if meta-characters present or path malformed and
;           Zero is set if the only problem is that meta-characters
;               are present in the last element of the path
procedure Validate_path,near
        ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    AX
        PUSH    CX
        PUSH    SI
        MOV     SI,DX
        MOV     CX,0FFH                 ;No path seps yet
        MOV     AX,[SI]                 ; Get first two bytes
        OR      AL,AL
        JZ      validate_malformed      ; NUL path
        CMP     AH,':'
        JNZ     validate_loop           ; OK so far
        CMP     BYTE [SI+2],0
        JZ      validate_malformed      ; NUL path (just d:)
validate_loop:
        LODSB
validate_loop1:

        IF      KANJI
        invoke  TESTKANJ
        JZ      NOTKANJ6
        INC     SI
        JMP     validate_loop

NOTKANJ6:
        END IF

        OR      AL,AL
        JZ      validate_end
        CMP     AL,"?"
        JZ      validate_error
        CMP     AL,"*"
        JZ      validate_error
        invoke  PATHCHRCMP
        JNZ     validate_loop
        JCXZ    validate_malformed      ;If path sep, cannot have meta yet
        LODSB                           ;Look ahead one char
        OR      AL,AL
        JZ      validate_checktslsh     ;Trailing path sep
        invoke  PATHCHRCMP
        JNZ     validate_loop1          ;Double path sep?
validate_malformed:
        INC     CX
        OR      CX,CX                   ;Reset zero
        JMP     SHORT validate_set_carry

validate_error:
        XOR     CX,CX                   ;Flag metas found
        JMP     validate_loop

validate_checktslsh:
;A bizarre case, "/" is OK, "d:/" is OK, anything else is an error
        SUB     SI,DX
        CMP     SI,2
        JZ      validate_end            ;Two chars, the '/' and the NUL
        CMP     SI,4
        JNZ     validate_malformed      ;Four chars, "D:/<NUL>"
        MOV     SI,DX
        CMP     BYTE [SI+1],':'
        JNZ     validate_malformed      ;Second char must be a ':'

validate_end:
        OR      CX,CX                   ;Clears carry
        JNZ     validate_ok             ;No metas found, leave carry clear
validate_set_carry:
        STC
validate_ok:
        POP     SI
        POP     CX
        POP     AX
validate_ok_ret:
        return

BREAK <Access_path - determine if file found>

;
; Input: DS:DX point to a path
; Output: Carry reset - outputs of GetPath
;         carry set - AL has error code
;
        procedure   Access_path,NEAR
        CALL    Validate_path
        JC      access_no_path
        MOV     SI,DX
        invoke  GETPATH
        jnc validate_ok_ret
        MOV     AL,error_file_not_found
        OR      CL,CL
        JNZ     access_ret
access_no_path:
        MOV     AL,error_path_not_found
access_ret:
        STC
        return

;BREAK <Find_free_jfn - return a free jfn in users PDB>
;
; system file table data
;

;
; The system file table is two linear tables.  The first table is the
; DOS initialization table containing a default number of FCBs.  The
; first word in the table is a link to the second table, which
; SYSINIT sets up, the second word is the number of FCBs in the table.
;

;
; find_free_jfn
; input:    none
; output:   JNC <found>
;               ES:DI is pointer to free JFN
;           JC  <no free jfns>
;               ES,DI indeterminate
;
        procedure   Find_free_jfn,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    AX
        PUSH    CX
        MOV     AL,0FFh
        MOV     ES,[SS:CurrentPDB]
        MOV     DI,Process_data_block.PDB_JFN_Table
        MOV     CX,FilPerProc
        REPNE   SCASB
        STC
        JNZ     Find_jfn_ret
        DEC     DI
        CLC
Find_jfn_ret:
        POP     CX
        POP     AX
        return

;BREAK <find_free_sfn - return a free sfn and sf pointer>
;
; find_free_sfn
; input:    none
; output:   JNC <found>
;               ES:DI is free sf entry
;               SI is sfn
;           JC  <not found>
;               ES,DI,SI indeterminate
;
; sft_addr -->  (link) count (fcbs)
; links = -1 means end of list
;
        procedure   Find_free_sfn,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    BX
        PUSH    CX
        LES     BX,[SS:sft_addr]           ; head of chain of tables
        XOR     SI,SI                   ; count of sfn

        ; ES:BX points to table... search through table
Find_sfn_in_table:
        CMP     BX,-1                   ; end of chain
        JZ      Find_no_free_sfns
        MOV     DI,sft.sft_table            ; offset to sf entry
        MOV     CX,[ES:BX+sft.sft_count]    ; count of fcbs in table

Find_sfn:
        CMP     BYTE [ES:BX+DI+sf_entry.sf_ref_count],0h
        JZ      Find_got_sfn            ; ref count is 0 -> free entry
        ADD     DI,sizeof.sf_entry        ; look to next entry
        INC     SI                      ; bump sfn
        LOOP    Find_sfn
        LES     BX,[ES:BX+sft.sft_link]     ; link to next
        JMP     SHORT Find_sfn_in_table ; look for more

Find_no_free_sfns:
        STC
        JMP     SHORT find_ret
Find_got_sfn:
        ADD     DI,BX
        CLC
find_ret:
        POP     CX
        POP     BX
        RET

;BREAK <$Open - open a file handle>
;
;   Assembler usage:
;           LDS     DX, Name
;           MOV     AH, Open
;           MOV     AL, access
;           INT     int_command
;
;       ACCESS          Function
;       ------          --------
;       open_for_read   file is opened for reading
;       open_for_write  file is opened for writing
;       open_for_both   file is opened for both reading and writing.
;
;   Error returns:
;           AX = error_invalid_access
;              = error_file_not_found
;              = error_access_denied
;              = error_too_many_open_files
;

        procedure   _OPEN,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        MOV     [SS:Cr_read_only],0
Open_create:
        CMP     AL,open_for_both        ; validate access
        JBE     OPEN_get_jfn
        error   error_invalid_access

OPEN_get_jfn:
        MOV     [SS:open_name+2],DS
        context DS
        MOV     [open_name],DX
        MOV     [open_access],AL

        invoke  Find_free_jfn           ; scan through user's area
        ; ES:DI is the jfn entry
        JNC     OPEN_get_sfn
OPEN_too_many:
        error   error_too_many_open_files

OPEN_get_sfn:
        MOV     [open_jfn_b],ES
        MOV     [open_jfn],DI
        invoke  Find_free_sfn           ; get a free sft entry
        ; ES:DI is the SFT entry that's free, SI is the sfn
        JC      OPEN_too_many

OPEN_file:
        MOV     [open_sfn],SI
        MOV     [open_sfoff],DI
        MOV     [open_sfn_b],ES
;
; open the file
;
        PUSH    DS
        LDS     DX,DWORD [open_name]
        ASSUME  DS:NOTHING
        CALL    Access_path
        POP     DS
        ASSUME  DS:DOSGROUP
        JNC     open_check_access       ; carry set -> error
        transfer    SYS_RET_ERR

open_check_access:
        MOV     ES,WORD [CURBUF+2]           ; get buffer location
        MOV     [open_devid],AH
        TEST    AH,080h
        JNZ     open_set_FCB_dev        ;is a device
        MOV     AL,[ES:BX+dir_entry.dir_attr]
        TEST    AL,attr_directory       ; can't open directories
        JZ      open_try_volid

open_bad_access:
        error   error_access_denied

open_try_volid:
        TEST    AL,attr_volume_id       ; can't open volume ids
        JNZ     open_bad_access
        TEST    AL,attr_read_only       ; check write on read only
        JZ      open_set_FCB
        CMP     [Cr_read_only],0
        JNZ     open_set_FCB            ; ok if creating read only file
        CMP     [open_access], open_for_read
        JNZ     open_bad_access         ; writing on a read only file
        JMP     SHORT open_set_FCB

open_set_FCB_dev:
        PUSH    SS
        POP     ES                      ;Device opens are DOSGROUP relative

open_set_FCB:
        MOV     CX,11                   ; copy name into FCB...
        PUSH    SI                      ; ES:BX is source, must change
        MOV     SI,BX                   ; ES:SI is source
        MOV     DI,[open_sfoff]         ; ??:DI is dest
        PUSH    DS
        PUSH    ES
        MOV     ES,[open_sfn_b]         ; ES:DI is dest
        POP     DS                      ; DS:SI is source
        ASSUME  DS:NOTHING
;
; need to save attribute for the close operation
;
        MOV     AH,[DS:BX+dir_entry.dir_attr]     ; save attribute for close
        MOV     [ES:DI+sf_entry.sf_attr],AH

        ADD     DI,sf_entry.sf_fcb+1             ; point to name

        IF      KANJI
        MOVSB
        CMP     BYTE [ES:DI-1],5
        JNZ     NOTKTRAN
        MOV     BYTE [ES:DI-1],0E5H
NOTKTRAN:
        DEC     CX
        END IF

        REP     MOVSB                   ; move in parsed name
        POP     DS
        ASSUME  DS:DOSGROUP
        POP     SI
        LES     DI,DWORD [open_sfoff]
        ADD     DI,sf_entry.sf_fcb               ; offset on fcb in sf entry
        MOV     AH,[open_devid]
        invoke  DOOPEN                  ; let open code fill in blanks
        context DS
        LES     DI,DWORD [open_sfoff]
        INC     [ES:DI+sf_entry.sf_ref_count]    ; reference this FCB
        MOV     AL,[open_access]          ; stash the access
        MOV     BYTE [ES:DI+sf_entry.sf_mode],AL
        XOR     AX,AX
        MOV     WORD [ES:DI+sf_entry.sf_fcb+sys_fcb.fcb_RR],AX       ; beginning of file
        MOV     WORD [ES:DI+sf_entry.sf_fcb+sys_fcb.fcb_RR+2],AX
        INC     AX
        MOV     WORD [ES:DI+sf_entry.sf_fcb+sys_fcb.fcb_RECSIZ],AX   ; byte io only
        LES     DI,DWORD [open_jfn]
        MOV     AX,[open_sfn]
        MOV     BYTE [ES:DI],AL     ; stash sfn in PDB
        SUB     DI,Process_data_block.PDB_JFN_Table        ; get jfn for user
        MOV     AX,DI
        transfer    SYS_RET_OK


BREAK <$UNLINK - delete a file entry>
;
;   Assembler usage:
;           LDS     DX, name
;           MOV     AH, Unlink
;           INT     21h
;
;   Error returns:
;           AX = error_file_not_found
;              = error_access_denied
;
        procedure   _UNLINK,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        CALL    Access_path
        JNC     unlink_check_attr
        transfer    SYS_RET_ERR

unlink_check_attr:
        JZ      unlink_dir
        LDS     DI,DWORD [SS:CURBUF]   ; get directory entry
        TEST    [DS:BX+dir_entry.dir_attr],attr_read_only
        JZ      unlink_doit

unlink_dir:
        error   error_access_denied

unlink_doit:
        MOV     BYTE [DS:BX+dir_entry.dir_name],0E5h  ; delete dir entry
        MOV     BYTE [DS:DI+BUFFINFO.BUFDIRTY],1     ; dirty the buffer
        LODSW
        MOV     BX,AX
        AND     BX,0FFFh
        context DS
        JZ      unlink_flush
        invoke  RELEASE
unlink_flush:
        MOV     AL,BYTE [ES:BP+dpb.dpb_drive]
        invoke  FLUSHBUF
        transfer    SYS_RET_OK

;BREAK <$CREAT - creat a new file and open him for input>
;
;   Assembler usage:
;           LDS     DX, name
;           MOV     AH, Creat
;           MOV     CX, access
;           INT     21h
;       ; AX now has the handle
;
;   Error returns:
;           AX = error_access_denied
;              = error_path_not_found
;              = error_too_many_open_files
;


        procedure   _CREAT,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        CALL    Validate_path
        JNC     unlink_do_make
        error   error_path_not_found
unlink_do_make:
        PUSH    DX
        PUSH    DS
        context DS
        MOV     WORD [CREATING],0E5FFh
        MOV     WORD [THISFCB+2],SS
        MOV     WORD [THISFCB],AuxStack-40
        MOV     SI,DX
        MOV     AL,CL
        AND     CL,attr_read_only
        MOV     [Cr_read_only],CL
        POP     DS
        PUSH    DS
ASSUME  DS:NOTHING
        invoke  MAKENODE
        POP     DS
        POP     DX
        OR      AL,AL
        JZ      creat_open
        CMP     AL,3
        JZ      creat_open
creat_no_access:
        error   error_access_denied
creat_open:
        MOV     AL,open_for_both
        JMP     Open_create


;BREAK <$DUP - duplicate a jfn>
;
;   Assembler usage:
;           MOV     BX, fh
;           MOV     AH, Dup
;           INT     int_command
;         AX has the returned handle
;   Errors:
;           AX = dup_invalid_handle
;              = dup_too_many_open_files
        procedure   _DUP,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        context DS
        invoke  Find_free_jfn
        JC      dup_no_free_handles

dup_force:
        PUSH    ES
        PUSH    DI
        invoke  get_sf_from_jfn
        POP     SI
        POP     DS
        JC      dup_bad_handle
        ; ES:DI is pointer to sf entry
        ; DS:DI is pointer to jfn
        INC     [ES:DI+sf_entry.sf_ref_count]    ; another jfn reference...
        MOV     AL,[BX+Process_data_block.PDB_JFN_Table]   ; get old sfn
        MOV     [SI],AL                 ; store in new place
        SUB     SI,Process_data_block.PDB_JFN_Table        ; get jfn
        MOV     AX,SI
        transfer    SYS_RET_OK

dup_no_free_handles:
        error   error_too_many_open_files

dup_bad_handle:
        error   error_invalid_handle
;BREAK <$DUP2 - force a dup on a particular jfn>
;
;   Assembler usage:
;           MOV     BX, fh
;           MOV     CX, newfh
;           MOV     AH, Dup2
;           INT     int_command
;   Error returns:
;           AX = error_invalid_handle
;
        procedure   _DUP2,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        XCHG    BX,CX                   ; BX < destination jfn
        PUSH    BX
        PUSH    CX
        invoke  _CLOSE                  ; close BX
        context DS
        POP     CX
        POP     BX
        invoke  get_jfn_pointer
        XCHG    BX,CX
        JNC     dup_force
lseek_bad_handle:
        error   error_invalid_handle


;BREAK <$CHMOD - change file attributes>
;
;   Assembler usage:
;           LDS     DX, name
;           MOV     CX, attributes
;           INT     21h
;   Error returns:
;           AX = error_path_not_found
;           AX = error_access_denied
;
        procedure   _CHMOD,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        CMP     AL,1
        JBE     chmod_save
        error   error_invalid_function
chmod_save:
        JB      chmod_try_file
        MOV     BX,CX
        AND     BX,NOT attr_changeable
        JZ      chmod_try_file

chmod_bad:
        error   error_access_denied

chmod_bye:
        transfer    SYS_RET_ERR
chmod_try_file:
        PUSH    CX
        PUSH    AX
        CALL    Access_path
        POP     DX
        POP     CX
        JC      chmod_bye
        LES     DI,[SS:CURBUF]
        context DS
        OR      DL,DL
        JZ      chmod_fetch
        AND     BYTE [ES:BX+dir_entry.dir_attr],NOT attr_changeable
        OR      BYTE [ES:BX+dir_entry.dir_attr],CL
        MOV     [ES:DI+BUFFINFO.BUFDIRTY],1
        MOV     AL,-1
        invoke  FLUSHBUF
        transfer    SYS_RET_OK
chmod_fetch:
        XOR     CX,CX
        MOV     CL,BYTE [ES:BX+dir_entry.dir_attr]
        invoke  get_user_stack
        MOV     [SI+user_environ.user_CX],CX
        transfer    SYS_RET_OK

;BREAK <$CURRENT_DIR - dump the current directory into user space>
;
;   Assembler usage:
;               LDS     SI,area
;               MOV     DL,drive
;               INT     21h
;           ; DS:SI is a pointer to 64 byte area that contains drive
;           ; current directory.
;   Error returns:
;           AX = error_invalid_drive
;
procedure   _CURRENT_DIR,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    DS
        PUSH    BX
        PUSH    SI
        invoke  _GET_DPB
;
; ES:BP points to DPB.  DS:SI points to user stack, unless error
;
        CMP     AL,0FFh
        JNZ     current_copy
        POP     AX              ; Clean Stack
        POP     AX
        POP     AX
        error   error_invalid_drive

current_copy:
        POP     DI              ; where to move to
        POP     [SI+user_environ.user_BX]    ; restore old BX
        POP     BX
        MOV     [SI+user_environ.user_DS],BX ; and restore old DS
;
; ES:BP is pointer to DPB. BX:DI is pointer to destination
;
        CMP     [ES:BP+dpb.dpb_current_dir],-1
        JNZ     current_ok
        PUSH    BX
        PUSH    DI
        MOV     [SS:ATTRIB],attr_all
        invoke  GETCURRDIR
        POP     DI
        POP     BX
current_ok:
        MOV     SI,BP           ; ES:SI is source
        PUSH    ES
        POP     DS              ; DS:SI is source
        MOV     ES,BX           ; ES:DI is destination
        CMP     [SI+dpb.dpb_current_dir],0
        JNZ     current_move
        MOV     BYTE [SI+dpb.dpb_dir_text],0

current_move:
        ADD     SI,dpb.dpb_dir_text
        MOV     CX,DIRSTRLEN
current_loop:
        LODSB
        STOSB
        OR      AL,AL
        LOOPNZ  current_loop
        transfer    SYS_RET_OK


;BREAK <$RENAME - move directory entries around>
;
;   Assembler usage:
;           LDS     DX, source
;           LES     DI, dest
;           MOV     AH, Rename
;           INT     21h
;
;   Error returns:
;           AX = error_file_not_found
;              = error_not_same_device
;              = error_access_denied
procedure   _RENAME,near

        MOV     WORD [SS:rename_source],DX
        MOV     WORD [SS:rename_source+2],DS
        MOV     WORD [SS:rename_dest],DI
        MOV     WORD [SS:rename_dest+2],ES
        CALL    Access_path
        JNC     rename_check_dir
        transfer    SYS_RET_ERR

rename_check_dir:
        JZ      rename_no_access
        MOV     DS,WORD [SS:CURBUF+2]
        PUSH    [BX+dir_entry.dir_date]
        PUSH    [BX+dir_entry.dir_first]
        PUSH    [BX+dir_entry.dir_size_h]
        PUSH    [BX+dir_entry.dir_size_l]
        PUSH    [BX+dir_entry.dir_time]
        PUSH    WORD [BX+dir_entry.dir_attr]
        PUSH    WORD [SS:THISDRV]
        LDS     SI,[SS:rename_dest]
        invoke  GETPATH
        POP     AX
        JC      rename_check_drives
rename_bad_access:
        ADD     SP,12
rename_no_access:
        error   error_access_denied
rename_check_drives:
        CMP     AL,[SS:THISDRV]
        JZ      rename_create
        ADD     SP,12
        error   error_not_same_device
rename_create:
        LDS     SI,[SS:rename_dest]
        POP     AX
        PUSH    AX
        MOV     WORD [SS:CREATING],0E5FFh
        MOV     WORD [SS:THISFCB+2],SS
        MOV     WORD [SS:THISFCB],AuxStack-40
        invoke  MAKENODE
        JC      rename_bad_access
        LDS     SI,[SS:CURBUF]
        POP     AX
        MOV     [BX+dir_entry.dir_attr],AL
        POP     [BX+dir_entry.dir_time]
        POP     [BX+dir_entry.dir_size_l]
        POP     [BX+dir_entry.dir_size_h]
        POP     [BX+dir_entry.dir_first]
        POP     [BX+dir_entry.dir_date]
        MOV     [SI+BUFFINFO.BUFDIRTY],1
        LDS     SI,[SS:rename_source]
        invoke  GETPATH
        LDS     SI,[SS:CURBUF]
        MOV     BYTE [BX],0E5h
        MOV     [SI+BUFFINFO.BUFDIRTY],1
        context DS
        MOV     AL,0FFh
        invoke  FLUSHBUF
        transfer    SYS_RET_OK

;BREAK <$FIND_FIRST - find first matching xenix filename>
;
;   Assembler usage:
;           MOV AH, FindFirst
;           LDS DX, name
;           MOV CX, attr
;           INT 21h
;       ; DMA address has datablock
;
;   Error Returns:
;           AX = error_file_not_found
;              = error_no_more_files
;
procedure   _FIND_FIRST,near
        ASSUME  DS:NOTHING,ES:NOTHING
        CALL    Validate_path
        JNC     find_get
        JZ      find_get
        error   error_file_not_found
find_get:
        MOV     SI,DX
        PUSH    CX
        INC     BYTE [SS:NoSetDir] ; if we find a dir, don't change to it
        MOV     WORD [SS:CREATING],0E500h
        CALL    GETPATH
        POP     CX
        MOV     [SS:ATTRIB],CL
find_check:
        JNC     find_check_attr
find_no_more:
        error   error_no_more_files
find_check_attr:
        MOV     DS,WORD [SS:CURBUF+2]
        MOV     CH,[BX+dir_entry.dir_attr]
        invoke  MatchAttributes
        JZ      found_it
        PUSH    [SS:LASTENT]
        MOV     BX,[SS:DIRSTART]
        JMP     find_it_next
found_it:
        LES     DI,[SS:DMAADD]
        MOV     AL,[SS:ATTRIB]
        STOSB                           ; find_buf 0 = attribute in search
        MOV     AL,[SS:THISDRV]
        STOSB                           ; find_buf 1 = drive
        MOV     CX,11
        PUSH    BX
        MOV     SI,NAME1; find_buf 2 = formatted name
        PUSH    DS
        PUSH    SS
        POP     DS

        IF      KANJI
        MOVSB
        CMP     BYTE [ES:DI-1],5
        JNZ     NOTKANJB
        MOV     BYTE [ES:DI-1],0E5H
NOTKANJB:
        DEC     CX
        END IF

        REP     MOVSB
        POP     DS
        MOV     AX,[SS:LASTENT]
        STOSW                           ; find_buf 13 = LastEnt
        MOV     AX,WORD [SS:THISDPB]
        STOSW                           ; find_buf 15 = ThisDPB
        MOV     AX,WORD [SS:THISDPB+2]
        STOSW
        MOV     AX,[SS:DIRSTART]
        STOSW                           ; find_buf 19 = DirStart
        MOV     AL,[BX+dir_entry.dir_attr]
        STOSB                           ; find_buf 21 = attribute found
        MOV     AX,[BX+dir_entry.dir_time]
        STOSW                           ; find_buf 22 = time
        MOV     AX,[BX+dir_entry.dir_date]
        STOSW                           ; find_buf 24 = date
        MOV     AX,[BX+dir_entry.dir_size_l]
        STOSW                           ; find_buf 26 = low(size)
        MOV     AX,[BX+dir_entry.dir_size_h]
        STOSW                           ; find_buf 28 = high(size)
        POP     SI
        MOV     CX,8                    ; find_buf 30 = packed name
find_loop_name:
        LODSB
        STOSB
        CMP     AL," "
        LOOPNZ  find_loop_name
        JNZ     find_check_dot
        DEC     DI
find_check_dot:
        ADD     SI,CX
        CMP     BYTE [SI]," "
        JZ      find_done
        MOV     AL,"."
        STOSB
        MOV     CX,3
find_loop_ext:
        LODSB
        STOSB
        CMP     AL," "
        LOOPNZ  find_loop_ext
        JNZ     find_done
        DEC     DI
find_done:
        XOR     AL,AL
        STOSB
        transfer    SYS_RET_OK

;BREAK <$FIND_NEXT - scan for match in directory>
;
;   Assembler usage:
;       ; dma points at area returned by find_first
;           MOV AH, findnext
;           INT 21h
;       ; next entry is at dma
;
;   Error Returns:
;           AX = error_no_more_files
;
procedure   _FIND_NEXT,near
        ASSUME  DS:NOTHING,ES:NOTHING
        LDS     SI,[SS:DMAADD]
        MOV     DX,SI
        INC     DX
        PUSH    SI
        invoke  MOVNAMENOSET
        POP     SI
        JNC     find_load
findnext_no_more:
        error   error_no_more_files
find_load:
        MOV     AX,[SI+find_buf.find_buf_LastEnt]
        LES     BP,[SI+find_buf.find_buf_ThisDPB]
        OR      AX,AX
        JS      findnext_no_more
        MOV     BX,[SI+find_buf.find_buf_DirStart]
        MOV     DL,[SI+find_buf.find_buf_sattr]
        MOV     [SS:ATTRIB],DL
        PUSH    AX
;        MOV     WORD [SS:THISPDB],BP
;        MOV     WORD [SS:THISPDB+2],ES
find_it_next:
        invoke  SETDIRSRCH
        ASSUME  DS:DOSGROUP
        POP     AX
        MOV     [ENTLAST],-1
        invoke  GETENT
        invoke  NEXTENT
        JMP     find_check

do_ext
