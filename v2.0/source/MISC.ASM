;TITLE MISC - Miscellanious routines for MS-DOS
;
; Miscellaneous system calls most of which are CAVEAT
;
; $SLEAZEFUNC
; $SLEAZEFUNCDL
; $GET_INDOS_FLAG
; $GET_IN_VARS
; $GET_DEFAULT_DPB
; $GET_DPB
; $DISK_RESET
; $SETDPB
; $Dup_PDB
; $CREATE_PROCESS_DATA_BLOCK
; SETMEM
;
;
; get the appropriate segment definitions
;

ENTRYPOINTSEG   EQU     0CH
MAXDIF          EQU     0FFFH
SAVEXIT         EQU     10

        i_need  LASTBUFFER,DWORD
        i_need  INDOS,BYTE
        i_need  SYSINITVAR,BYTE
        i_need  CurrentPDB,WORD
        i_need  CreatePDB,BYTE
        i_need  EXIT_TYPE,BYTE
        i_need  EXIT_CODE,WORD
        i_need  LASTENT,WORD
        i_need  THISDPB,DWORD
        i_need  ATTRIB,BYTE
        i_need  EXTFCB,BYTE
        i_need  DMAADD,DWORD
        i_need  DIRSTART,WORD
        i_need  CURBUF,DWORD
        i_need  USER_SP,WORD
        i_need  ENTLAST,WORD
        i_need  THISDRV,BYTE

ASSUME  SS:DOSGROUP

;BREAK <SleazeFunc -- get a pointer to media byte>

;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        procedure   _SLEAZEFUNC,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       None
; Function:
;       Return Stuff sort of like old get fat call
; Outputs:
;       DS:BX = Points to FAT ID byte (IBM only)
;               GOD help anyone who tries to do ANYTHING except
;               READ this ONE byte.
;       DX = Total Number of allocation units on disk
;       CX = Sector size
;       AL = Sectors per allocation unit
;          = -1 if bad drive specified

        MOV     DL,0
    entry   _SLEAZEFUNCDL
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     AL,DL
        invoke  GETTHISDRV
        MOV     AL,-1
        JC      BADSLDRIVE
        invoke  FATREAD
        MOV     DX,[ES:BP+dpb.dpb_max_cluster]
        DEC     DX
        MOV     AL,[ES:BP+dpb.dpb_cluster_mask]
        INC     AL
        MOV     CX,[ES:BP+dpb.dpb_sector_size]
        ADD     BP,dpb.dpb_media
BADSLDRIVE:
        invoke  get_user_stack
ASSUME  DS:NOTHING
        MOV     [SI+user_environ.user_CX],CX
        MOV     [SI+user_environ.user_DX],DX
        MOV     [SI+user_environ.user_BX],BP
        MOV     [SI+user_environ.user_DS],ES
        return
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;



;BREAK <_ABORT -- Terminate a process>
        procedure   _ABORT,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       CS:00 must point to valid program header block
; Function:
;       Restore terminate and Cntrl-C addresses, flush buffers
;       and transfer to the terminate address
; Returns:
;       TO THE TERMINATE ADDRESS

        XOR     AL,AL
        MOV     [SS:exit_type],.Exit_abort

;
; abort_inner must have AL set as the exit code!
;
        entry   abort_inner
        MOV     AH,[SS:exit_type]
        MOV     [SS:exit_code],AX
        invoke  get_user_stack
        MOV     DS,[SI+user_environ.user_CS]         ; set up old interrupts
        XOR     AX,AX
        MOV     ES,AX
        MOV     SI,SAVEXIT
        MOV     DI,addr_int_terminate
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        MOVSW
        transfer    reset_environment

;BREAK <_Dir_Search_First -- Start a directory search>
        procedure   _DIR_SEARCH_FIRST,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX Points to unopenned FCB
; Function:
;       Directory is searched for first matching entry and the directory
;       entry is loaded at the disk transfer address
; Returns:
;       AL = -1 if no entries matched, otherwise 0

        invoke  GETFILE
ASSUME  DS:DOSGROUP
SAVPLCE:
; Search-for-next enters here to save place and report
; findings.
        MOV     DL,0            ; Do not XOR!!!
        JC      KILLSRCH
        OR      AH,AH           ; Is it I/O device?
        JS      KILLIT          ; If so, sign bit will end search
        MOV     AX,[LASTENT]
        INC     DL
KILLIT:
        MOV     [ES:DI+sys_fcb.fcb_FILSIZ],AX
        MOV     AX,WORD [THISDPB]
        MOV     [ES:DI+sys_fcb.fcb_DRVBP],AX
        MOV     AX,WORD [THISDPB+2]
        MOV     [ES:DI+sys_fcb.fcb_DRVBP+2],AX
        MOV     AX,[DIRSTART]
        MOV     [ES:DI+sys_fcb.fcb_DRVBP+4],AX
; Information in directory entry must be copied into the first
; 33 bytes starting at the disk transfer address.
        MOV     SI,BX
        LES     DI,[DMAADD]
        MOV     AX,00FFH
        CMP     AL,[EXTFCB]
        JNZ     NORMFCB
        STOSW
        INC     AL
        STOSW
        STOSW
        MOV     AL,[ATTRIB]
        STOSB
NORMFCB:
        MOV     AL,[THISDRV]
        INC     AL
        STOSB   ; Set drive number
        OR      DL,DL
        JZ      DOSRELATIVE
        MOV     DS,WORD [CURBUF+2]
ASSUME  DS:NOTHING
DOSRELATIVE:

        IF      KANJI
        MOVSW
        CMP     BYTE [ES:DI-2],5
        JNZ     NOTKTRAN
        MOV     BYTE [ES:DI-2],0E5H
NOTKTRAN:
        MOV     CX,15
        ELSE
        MOV     CX,16
        END IF

        REP     MOVSW   ; Copy 32 bytes of directory entry
        XOR     AL,AL
        return

ASSUME  DS:NOTHING
KILLSRCH1:
        PUSH    DS
        POP     ES      ; Make ES:DI point to the FCB
KILLSRCH:
        MOV     AX,-1
        MOV     WORD [ES:DI+sys_fcb.fcb_FILSIZ],AX
        return

;BREAK <_Dir_Search_Next -- Find next matching directory entry>
        procedure   _DIR_SEARCH_NEXT,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX points to unopenned FCB returned by _DIR_SEARCH_FIRST
; Function:
;       Directory is searched for the next matching entry and the directory
;       entry is loaded at the disk transfer address
; Returns:
;       AL = -1 if no entries matched, otherwise 0

        invoke  MOVNAMENOSET
ASSUME  ES:DOSGROUP
        MOV     DI,DX
        JC      KILLSRCH1
        MOV     AX,[DI+sys_fcb.fcb_FILSIZ] ; ???
        LES     BP,DWORD [DI+sys_fcb.fcb_DRVBP]
        OR      AX,AX
        JS      KILLSRCH1
        MOV     BX,[DI+sys_fcb.fcb_DRVBP+4]
        PUSH    DX
        PUSH    DS
        PUSH    AX
        MOV     WORD [SS:THISDPB],BP
        MOV     WORD [SS:THISDPB+2],ES
        invoke  SETDIRSRCH
        POP     AX
        MOV     [ENTLAST],-1
        invoke  GETENT
        invoke  NEXTENT
        POP     ES
        ASSUME  ES:NOTHING
        POP     DI
        JMP     SAVPLCE

;BREAK <_Get_FCB_File_Length -- Return size of file in current records>
        procedure   _GET_FCB_FILE_LENGTH,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX points to unopenned FCB
; Function:
;       Set random record field to size of file
; Returns:
;       AL = -1 if no entries matched, otherwise 0

        invoke  GETFILE
ASSUME  DS:DOSGROUP
        MOV     AL,-1
        jc RET14
        ADD     DI,sys_fcb.fcb_RR       ; Write size in RR field
        MOV     CX,WORD [ES:DI+sys_fcb.fcb_RECSIZ-sys_fcb.fcb_RR]
        OR      CX,CX
        JNZ     RECOK
        MOV     CX,128
RECOK:
        XOR     DX,DX           ; Intialize size to zero
        INC     SI
        INC     SI              ; Point to length field
        MOV     DS,WORD [CURBUF+2]
ASSUME  DS:NOTHING
        MOV     AX,[SI+2]       ; Get high word of size
        DIV     CX
        PUSH    AX              ; Save high part of result
        LODSW           ; Get low word of size
        DIV     CX
        OR      DX,DX           ; Check for zero remainder
        POP     DX
        JZ      DEVSIZ
        INC     AX              ; Round up for partial record
        JNZ     DEVSIZ          ; Propagate carry?
        INC     DX
DEVSIZ:
        STOSW
        MOV     AX,DX
        STOSB
        MOV     AL,0
        CMP     CX,64
        JAE     RET14           ; Only 3-byte field if fcb_RECSIZ >= 64
        MOV     [ES:DI],AH
RET14:  return

;BREAK <_Get_Fcb_Position -- Set random record field to current position>
        procedure   _GET_FCB_POSITION,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX points to openned FCB
; Function:
;       Sets random record field to be same as current record fields
; Returns:
;       None

        invoke  GETREC
        MOV     WORD [DI+sys_fcb.fcb_RR],AX
        MOV     [DI+sys_fcb.fcb_RR+2],DL
        CMP     [DI+sys_fcb.fcb_RECSIZ],64
        JAE     RET16
        MOV     [DI+sys_fcb.fcb_RR+2+1],DH      ; Set 4th byte only if record size < 64
RET16:  return

;BREAK <_Disk_Reset -- Flush out all dirty buffers>
        procedure   _DISK_RESET,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       None
; Function:
;       Flush and invalidate all buffers
; Returns:
;       Nothing

        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     AL,-1
        invoke  FLUSHBUF
        MOV     WORD [LASTBUFFER+2],-1
        MOV     WORD [LASTBUFFER],-1
        invoke  SETVISIT
ASSUME  DS:NOTHING
NBFFR:                                  ; Free ALL buffers
        MOV     [DI+BUFFINFO.VISIT],1            ; Mark as visited
        CMP     BYTE [DI+BUFFINFO.BUFDRV],-1
        JZ      SKPBF                   ; Save a call to PLACEBUF
        MOV     WORD [DI+BUFFINFO.BUFDRV],00FFH
        invoke  SCANPLACE
SKPBF:
        invoke  SKIPVISIT
        JNZ     NBFFR
        return

        procedure   _RAW_CON_IO,NEAR   ; System call 6
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DL = -1 if input
;       else DL is output character
; Function:
;       Input or output raw character from console, no echo
; Returns:
;       AL = character

        MOV     AL,DL
        CMP     AL,-1
        JNZ     RAWOUT
        LES     DI,DWORD [SS:user_SP]                ; Get pointer to register save area
        XOR     BX,BX
        invoke  GET_IO_FCB
        jc _RAW_CON_IO_ret
        MOV     AH,1
        invoke  IOFUNC
        JNZ     RESFLG
        invoke  SPOOLINT
        OR      BYTE [ES:DI+user_environ.user_F],40H ; Set user's zero flag
        XOR     AL,AL
_RAW_CON_IO_ret:
        ret

RESFLG:
        AND     BYTE [ES:DI+user_environ.user_F],0FFH-40H    ; Reset user's zero flag

RILP:
        invoke  SPOOLINT
    entry   _RAW_CON_INPUT        ; System call 7

; Inputs:
;       None
; Function:
;       Input raw character from console, no echo
; Returns:
;       AL = character

        XOR     BX,BX
        invoke  GET_IO_FCB
        jc _RAW_CON_INPUT_ret
        MOV     AH,1
        invoke  IOFUNC
        JZ      RILP
        XOR     AH,AH
        invoke  IOFUNC
_RAW_CON_INPUT_ret:
        return
;
;       Output the character in AL to stdout
;
entry   RAWOUT

        PUSH    BX
        MOV     BX,1

        invoke  GET_IO_FCB
        JC      RAWRET1

        TEST    [SI+sys_fcb.fcb_DEVID],080H             ; output to file?
        JZ      RAWNORM                         ; if so, do normally
        PUSH    DS
        PUSH    SI
        LDS     SI,DWORD [SI+sys_fcb.fcb_FIRCLUS]   ; output to special?
        TEST    BYTE [SI+SYSDEV.SDEVATT],devid_SPECIAL
        POP     SI
        POP     DS
        JZ      RAWNORM                         ; if not, do normally
        INT     int_fastcon                     ; quickly output the char
        JMP     SHORT RAWRET
RAWNORM:

        CALL    RAWOUT3
RAWRET: CLC
RAWRET1:
        POP     BX
        return

;
;       Output the character in AL to handle in BX
;
entry   RAWOUT2

        invoke  GET_IO_FCB
        jc RAWOUT2_ret
RAWOUT3:
        PUSH    AX
        JMP     SHORT RAWOSTRT
ROLP:
        invoke  SPOOLINT
RAWOSTRT:
        MOV     AH,3
        CALL    IOFUNC
        JZ      ROLP
        POP     AX
        MOV     AH,2
        CALL    IOFUNC
        CLC                     ; Clear carry indicating successful
RAWOUT2_ret:
        return

; This routine is called at DOS init

        procedure   OUTMES,NEAR ; String output for internal messages
        LODS    BYTE [CS:SI]
        CMP     AL,"$"
        jz OUTMES_ret
        invoke  _OUT
        JMP     OUTMES
OUTMES_ret:
        return
        ASSUME  SS:DOSGROUP

;BREAK <_Parse_File_Descriptor -- Parse an arbitrary string into an FCB>
        procedure   _PARSE_FILE_DESCRIPTOR,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:SI Points to a command line
;       ES:DI Points to an empty FCB
;       Bit 0 of AL = 1 At most one leading separator scanned off
;                   = 0 Parse stops if separator encountered
;       Bit 1 of AL = 1 If drive field blank in command line - leave FCB
;                   = 0  "    "    "     "         "      "  - put 0 in FCB
;       Bit 2 of AL = 1 If filename field blank - leave FCB
;                   = 0  "       "      "       - put blanks in FCB
;       Bit 3 of AL = 1 If extension field blank - leave FCB
;                   = 0  "       "      "        - put blanks in FCB
; Function:
;       Parse command line into FCB
; Returns:
;       AL = 1 if '*' or '?' in filename or extension, 0 otherwise
;       DS:SI points to first character after filename

        invoke  MAKEFCB
        PUSH    SI
        invoke  get_user_stack
        POP     [SI+user_environ.user_SI]
        return

;BREAK <_Create_Process_Data_Block,SetMem -- Set up process data block>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        procedure   _Dup_PDB,NEAR:
ASSUME  DS:NOTHING,ES:NOTHING
        MOV     BYTE [SS:CreatePDB], 0FFH  ; indicate a new process


        procedure   _CREATE_PROCESS_DATA_BLOCK,NEAR
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING

; Inputs:
;       DX = Segment number of new base
; Function:
;       Set up program base and copy term and ^C from int area
; Returns:
;       None
; Called at DOS init

        MOV     ES,DX
        TEST    BYTE [CS:CreatePDB],0FFh
        JZ      Create_PDB_old
        MOV     DS,[CS:CurrentPDB]
        JMP     SHORT Create_copy

Create_PDB_old:
        invoke  get_user_stack
        MOV     DS,[SI+user_environ.user_CS]

Create_copy:
        XOR     SI,SI                   ; copy all 80h bytes
        MOV     DI,SI
        MOV     CX,80H
        REP     MOVSW

        TEST    BYTE [CS:CreatePDB],0FFh   ; Shall we create a process?
        JZ      Create_PDB_cont         ; nope, old style call
;
; Here we set up for a new process...
;

        PUSH    CS
        POP     DS
        ASSUME  DS:DOSGROUP
        XOR     BX,BX                   ; dup all jfns
        MOV     CX,FilPerProc

Create_dup_jfn:
        PUSH    ES                      ; save new PDB
        invoke  get_jfn_pointer         ; ES:DI is jfn
        JC      create_skip             ; not a valid jfn
        PUSH    ES                      ; save him
        PUSH    DI
        invoke  get_sf_from_jfn         ; get sf pointer
        JC      create_no_inc
        INC     [ES:DI+sf_entry.sf_ref_count]    ; new fh

create_no_inc:
        POP     DI
        POP     ES                      ; get old jfn
        MOV     AL,[ES:DI]              ; get sfn
        POP     ES
        PUSH    ES
        MOV     AL,[ES:BX]              ; copy into new place!

create_skip:
        POP     ES
        INC     BX                      ; next jfn...
        LOOP    Create_dup_jfn

        PUSH    [CurrentPDB]            ; get current process
        POP     BX
        PUSH    BX
        POP     [ES:Process_data_block.PDB_Parent_PID]     ; stash in child
        MOV     [CurrentPDB],ES
        ASSUME  DS:NOTHING
        MOV     DS,BX
;
; end of new process create
;
Create_PDB_cont:
        MOV     BYTE [CS:CreatePDB],0h ; reset flag
        MOV     AX,[DS:2]               ; set up size for fall through

entry SETMEM
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING

; Inputs:
;       AX = Size of memory in paragraphs
;       DX = Segment
; Function:
;       Completely prepares a program base at the
;       specified segment.
; Called at DOS init
; Outputs:
;       DS = DX
;       ES = DX
;       [0] has INT int_abort
;       [2] = First unavailable segment ([ENDMEM])
;       [5] to [9] form a long call to the entry point
;       [10] to [13] have exit address (from int_terminate)
;       [14] to [17] have ctrl-C exit address (from int_ctrl_c)
;       [18] to [21] have fatal error address (from int_fatal_abort)
; DX,BP unchanged. All other registers destroyed.

        XOR     CX,CX
        MOV     DS,CX
        MOV     ES,DX
        MOV     SI,addr_int_terminate
        MOV     DI,SAVEXIT
        MOV     CX,6
        REP     MOVSW
        MOV     [ES:2],AX
        SUB     AX,DX
        CMP     AX,MAXDIF
        JBE     HAVDIF
        MOV     AX,MAXDIF
HAVDIF:
        MOV     BX,ENTRYPOINTSEG
        SUB     BX,AX
        MOV     CL,4
        SHL     AX,CL
        MOV     DS,DX
        MOV     WORD [DS:Process_data_block.PDB_CPM_Call+1],AX
        MOV     WORD [DS:Process_data_block.PDB_CPM_Call+3],BX
        MOV     [DS:Process_data_block.PDB_Exit_Call],(int_abort SHL 8) + mi_INT
        MOV     BYTE [DS:Process_data_block.PDB_CPM_Call],mi_Long_CALL
        MOV     WORD [DS:Process_data_block.PDB_Call_system],(int_command SHL 8) + mi_INT
        MOV     BYTE [DS:Process_data_block.PDB_Call_system+2],mi_Long_RET
        return

        do_ext
