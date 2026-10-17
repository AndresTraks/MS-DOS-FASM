;
; This version of COMMAND is divided into three distinct parts.  First is the
; resident portion, which includes handlers for interrupts 22H (terminate),
; 23H (Cntrl-C), 24H (fatal error), and 27H (stay resident); it also has code
; to test and, if necessary, reload the transient portion.  Following the
; resident is the init code, which is overwritten after use.  Then comes the
; transient portion, which includes all command processing (whether internal
; or external).  The transient portion loads at the end of physical memory,
; and it may be overlayed by programs that need as much memory as possible.
; When the resident portion of command regains control from a user program, a
; checksum is performed on the transient portion to see if it must be
; reloaded.  Thus programs which do not need maximum memory will save the time
; required to reload COMMAND when they terminate.

;
; REV 1.17
;    05/19/82   Fixed bug in BADEXE error (relocation error must return to
;               resident since the EXELOAD may have overwritten the transient.
; REV 1.18
;    05/21/82   IBM version always looks on drive A
;               MSVER always looks on default drive
;
; REV 1.19
;    06/03/82   Drive spec now entered in command line
;    06/07/82   Added VER command (print DOS version number) and VOL command
;               (print volume label)
; REV 1.20
;    06/09/82   Prints "directory" after directories
;    06/13/82   MKDIR, CHDIR, PWD, RMDIR added
; REV 1.50
;               Some code for new 2.0 DOS, sort of HACKey.  Not enough time to
;               do it right.
; REV 1.70
;               EXEC used to fork off new processes
; REV 1.80
;               C switch for single command execution
; REV 1.90
;               Batch uses XENIX
; Rev 2.00
;               Lots of neato stuff
;               IBM 2.00 level
; Rev 2.01
;               'D' switch for date time suppression
; Rev 2.02
;               Default userpath is NUL rather than BIN
;                       same as IBM
;               COMMAND split into pieces
; Rev 2.10
;               INTERNATIONAL SUPPORT
; Rev 2.11      COMMAND split into more pieces




if SEGSEL = S_DATARES

        IF      IBMVER
        END IF

end if



if SEGSEL = S_INIT
end if




if SEGSEL = S_TRANDATA
end if


if SEGSEL = S_TRANSPACE
end if






if SEGSEL = S_ENVIRONMENT


ENVARENA DB     10H DUP (?)     ; Pad for mem arena
PATHSTRING DB   "PATH="
label USERPATH byte

        DB      0               ; Null path
        DB      "COMSPEC="
ECOMSPEC DB     "/COMMAND.COM"
        DB      134 DUP (0)

label ENVIREND byte

ENVIRONSIZ = $-PATHSTRING
ENVIRONSIZ2 = $-ECOMSPEC
end if


; START OF RESIDENT PORTION


if SEGSEL = S_CODERES


        IF      IBMVER
        END IF

ASSUME  CS:RESGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING



ZERO    =       $


PROGSTART:
        JMP     CONPROC

        DB      (80H - 3) DUP (?)
label RSTACK word

IF IBMVER
SYSCALL_:
        CMP     AH,Exec
        JZ      do_exec
        JMP     dword [CS:SYS_CALL]

do_exec:
        PUSH    ES
        PUSH    DS
        PUSH    BP
        PUSH    DI
        PUSH    SI
        PUSH    DX
        PUSH    CX
        PUSH    BX
        PUSH    AX
        MOV     [CS:USER_SS],SS
        MOV     [CS:USER_SP],SP
;
; are we running on RSTACK already?
;
        PUSH    CS
        POP     BX              ; BX <- CS
        PUSH    SS
        POP     AX              ; AX <- SS
        CMP     AX,BX           ; IF AX == BX then no stack switch!
        JZ      Get_mem
        MOV     SS,BX
ASSUME  SS:RESGROUP
        MOV     SP,RSTACK

Get_mem:
        MOV     BX,0FFFFH       ; allocate all of memory
        MOV     AH,Alloc
        INT     int_command
        MOV     AX,ZEXECDATAEND + 15
        MOV     CL,4
        SHR     AX,CL
        MOV     CX,AX          ; Save in CX
        CMP     BX,AX          ; enough for EXEC?
        JB      execmer        ; nope... cry
        MOV     AH,Alloc
        INT     int_command
        JC      execmer         ; Memory arenas probably trashed
        ADD     BX,AX
        MOV     [SS:MEMSIZ],BX
        SUB     BX,CX
        MOV     [SS:EXESEG],BX     ; exec
        MOV     ES,AX
        MOV     AH,Dealloc
        INT     int_command
        PUSH    CS
        POP     DS
ASSUME  DS:RESGROUP
        CALL    EXECHK
        CMP     DX,[EXESUM]
        JZ      HAVEXEC         ; EXEC OK
        MOV     DX,COMSPEC
        MOV     AX,Open SHL 8
        INT     int_command             ; Open COMMAND.COM
        JC      execmer
        MOV     BX,AX           ; Handle
        MOV     DX,TRANSTART
        ADD     DX,EXECSTART - 100H
        XOR     CX,CX           ; Seek loc
        MOV     AX,LSeek SHL 8
        INT     int_command
        MOV     CX,ZEXECCODEEND
        MOV     DS,[EXESEG]
ASSUME  DS:NOTHING
        MOV     AH,Read
        INT     int_command
        PUSH    AX
        MOV     AH,Close
        INT     int_command             ; Close COMMAND.COM
        POP     CX
        CMP     CX,ZEXECCODEEND
        JNZ     execmer         ; Size matched

        CALL    EXECHK
        CMP     DX,[SS:EXESUM]
        JNZ     execmer
HAVEXEC:
        MOV     [SS:LOADING],0             ; Flag to DSKERR
        CALL    dword [SS:ZEXEC]
        JMP     SHORT execret
execmer:
        LDS     SI,dword [SS:USER_SP]
        MOV     [SI+user_environ.user_AX],exec_not_enough_memory
        PUSH    [SI+user_environ.user_F]
        POPF
        STC
        PUSHF
        POP     [SI+user_environ.user_F]
execret:
        MOV     SS,[SS:USER_SS]
ASSUME  SS:NOTHING
        MOV     SP,[CS:USER_SP]
        POP     AX              ; PUSH    ES
        POP     BX              ; PUSH    DS
        POP     CX              ; PUSH    BP
        POP     DX              ; PUSH    DI
        POP     SI              ; PUSH    SI
        POP     DI              ; PUSH    DX
        POP     BP              ; PUSH    CX
        POP     DS              ; PUSH    BX
        POP     ES              ; PUSH    AX
        IRET

EXECHK:
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        PUSH    DS
        MOV     DS,[CS:EXESEG]
        MOV     CX,ZEXECCODEEND
        XOR     SI,SI
        JMP     CHECK_SUM
END IF

EXEC_ERR:                       ; Select the correct error message
        MOV     DX,RBADNAM
        CMP     AX,exec_file_not_found
        JZ      GOTEXECEMES
        CMP     AX,error_access_denied
        JZ      GOTEXECEMES
        MOV     DX,TOOBIG
        CMP     AX,exec_not_enough_memory
        JZ      GOTEXECEMES
        MOV     DX,EXEBAD
        CMP     AX,exec_bad_format
        JZ      GOTEXECEMES
        MOV     DX,EXECEMES
GOTEXECEMES:
        PUSH    CS
        POP     DS
        CALL    RPRINT
        JMP     SHORT NOEXEC

EXT_EXEC:
;
; we are now running in free space.  anything we do from here
; on may get trashed.  Move the stack (also in free space) to
; allocated space because since EXEC restores the stack,
; somebody may trash what is on the stack.
;
        MOV     CX,CS
        MOV     SS,CX
        MOV     SP,RSTACK
;
; Oops!! We have to make sure that the EXEC code doesn't blop a newstack!
;
;
        INT     int_command     ; Do the EXEC
        JC      EXEC_ERR        ; EXEC failed
EXEC_WAIT:
        MOV     AH,Wait
        INT     int_command     ; Get the return code
        MOV     [CS:RETCODE],AX
NOEXEC:
        JMP     LODCOM

CONTC:
        STI
        MOV     AX,CS
        MOV     DS,AX
ASSUME  DS:RESGROUP
        MOV     AH,Disk_Reset
        INT     int_command     ; Reset disks in case files were open
        TEST    [BATCH],-1
        JZ      CONTCTERM
        JMP     ASKEND          ; See if user wants to terminate batch
CONTCTERM:
        XOR     BP,BP           ; Indicate no read
        MOV     [FORFLAG],0     ; Turn off for processing
        MOV     [PIPEFLAG],0    ; Turn off any pipe
        CMP     [SINGLECOM],0   ; See if we need to set SINGLECOM
        JZ      NOSETSING
        MOV     [SINGLECOM],-1  ; Cause termination on pipe, batch, for
NOSETSING:
        CMP     [EXTCOM],0
        JNZ     DODAB           ; Internal ^C
        JMP     LODCOM1
DODAB:
        STC                     ; Tell DOS to abort
        procedure   ZZY,FAR
        RETF                     ; Leave flags on stack

BADMEMERR:                              ; Allocation error loading transient
        MOV     DX,BMEMMES
FATALC:
        PUSH    CS
        POP     DS
        CALL    RPRINT
        CMP     [PERMCOM],0
        JZ      FATALRET
        CMP     [SINGLECOM],0                   ; If PERMCOM and SINGLECOM
        JNZ     FATALRET                        ; Must take INT_2E exit
        MOV     DX,HALTMES
        CALL    RPRINT
STALL:
        JMP     STALL                           ; Crash the system nicely

FATALRET:
        MOV     DX,FRETMES
        CALL    RPRINT
FATALRET2:
        CMP     [PERMCOM],0                     ; If we get here and PERMCOM,
        JNZ     RET_2E                          ; must be INT_2E
IF IBM
        LDS     DX,dword [SYS_CALL]
ASSUME  DS:NOTHING
        MOV     AX,(Set_Interrupt_Vector SHL 8) + int_command
        INT     int_command
END IF
        MOV     AX,[CS:PARENT]
        MOV     word [CS:Process_data_block.PDB_Parent_PID],AX
        MOV     AX,(Exit SHL 8)                 ; Return to lower level
        INT     int_command

RET_2E:
        PUSH    CS
        POP     DS
ASSUME  DS:RESGROUP,ES:NOTHING,SS:NOTHING
        MOV     [SINGLECOM],0   ; Turn off singlecom
        MOV     ES,[LTPA]
        MOV     AH,Dealloc
        INT     int_command             ; Free up space used by transient
        MOV     BX,[SAVE_PDB]
        MOV     AH,SET_CURRENT_PDB
        INT     int_command             ; Current process is user
        MOV     AX,[RETCODE]
        CMP     [EXTCOM],0
        JNZ     GOTECODE
        XOR     AX,AX           ; Internals always return 0
GOTECODE:
        MOV     [EXTCOM],1      ; Force external
        JMP     dword [INT_2E_RET];"IRET"

INT_2E:                         ; Magic command executer
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        POP     word [CS:INT_2E_RET]
        POP     word [CS:INT_2E_RET+2]    ;Get return address
        POP     AX              ;Chuck flags
        PUSH    CS
        POP     ES
        MOV     DI,80H
        MOV     CX,64
        REP     MOVSW
        MOV     AH,GET_CURRENT_PDB
        INT     int_command             ; Get user's header
        MOV     [CS:SAVE_PDB],BX
        MOV     AH,SET_CURRENT_PDB
        MOV     BX,CS
        INT     int_command             ; Current process is me
        MOV     [CS:SINGLECOM],81H
        MOV     [CS:EXTCOM],1      ; Make sure this case forced

LODCOM:                         ; Termination handler
        CMP     [CS:EXTCOM],0
        JZ      LODCOM1         ; If internal, memory already allocated
        MOV     BX,0FFFFH
        MOV     AH,Alloc
        INT     int_command
        MOV     AX,TRANSPACEEND + 15
        MOV     CL,4
        SHR     AX,CL

        IF      IBM
        PUSH    AX
        MOV     AX,ZEXECDATAEND + 15
        MOV     CL,4
        SHR     AX,CL
        POP     CX
        ADD     AX,CX
        END IF

        ADD     AX,20H
        CMP     BX,AX           ; Is less than 512 byte buffer worth it?
        JNC     MEMOK
BADMEMERRJ:
        JMP BADMEMERR           ; Not enough memory
MEMOK:
        MOV     AH,Alloc
        INT     int_command
        JC      BADMEMERRJ      ; Memory arenas probably trashed
        MOV     [CS:EXTCOM],0      ; Flag not to ALLOC again
        MOV     [CS:LTPA],AX       ; New TPA is base just allocated
        ADD     BX,AX
        MOV     [CS:MEMSIZ],BX

        MOV     AX,TRANSPACEEND + 15
        MOV     CL,4
        SHR     AX,CL

        IF      IBM
        PUSH    AX
        MOV     AX,ZEXECDATAEND + 15
        MOV     CL,4
        SHR     AX,CL
        POP     CX
        ADD     AX,CX
        END IF

        SUB     BX,AX
        MOV     [CS:TRNSEG],BX     ; Transient starts here
LODCOM1:
        MOV     AX,CS
        MOV     SS,AX
ASSUME  SS:RESGROUP
        MOV     SP,RSTACK
        MOV     DS,AX
ASSUME  DS:RESGROUP
        CALL    HEADFIX     ; Make sure files closed stdin and stdout restored
        XOR     BP,BP           ; Flag command ok
        MOV     AX,-1
        XCHG    AX,[VERVAL]
        CMP     AX,-1
        JZ      NOSETVER
        MOV     AH,Set_Verify_On_Write  ; AL has correct value
        INT     int_command
NOSETVER:
        CMP     [SINGLECOM],-1
        JNZ     NOSNG
        JMP     FATALRET2       ; We have finished the single command
NOSNG:
        CALL    SETVECT

IF IBMVER
        CALL    EXECHK          ; Check exe loader
        CMP     DX,[EXESUM]
        JNZ     BOGUS_COM
END IF

        CALL    CHKSUM          ; Check the transient
        CMP     DX,[SUM]
        JZ      HAVCOM          ; Transient OK
BOGUS_COM:
        MOV     [LOADING],1     ; Flag DSKERR routine
        CALL    LOADCOM
CHKSAME:

IF IBMVER
        CALL    EXECHK
        CMP     DX,[EXESUM]
        JNZ     ALSO_BOGUS
END IF

        CALL    CHKSUM
        CMP     DX,[SUM]
        JZ      HAVCOM          ; Same COMMAND
ALSO_BOGUS:
        CALL    WRONGCOM
        JMP     SHORT CHKSAME
HAVCOM:
        MOV     AX,Char_Oper SHL 8
        INT     int_command
        MOV     [RSWITCHAR],DL
        CMP     DL,'/'
        JNZ     USESLASH
        MOV     [RDIRCHAR],'\'          ; Select alt path separator
USESLASH:
        MOV     [LOADING],0             ; Flag to DSKERR
        MOV     SI,TRANVARS
        MOV     DI,HEADCALL
        MOV     ES,[TRNSEG]
        CLD
        MOV     CX,8
        REP     MOVSW                   ; Transfer INFO to transient
        MOV     AX,[MEMSIZ]
        MOV     word [DS:Process_data_block.PDB_block_len],AX  ; Adjust my own header
        JMP     dword [TRANS]

; Far call to REMCHECK for TRANSIENT
        procedure   TREMCHECK,FAR
        CALL    REMCHECK
        RETF

REMCHECK:
;All registers preserved. Returns zero if media removable, NZ if fixed
; AL is drive (0=DEF, 1=A,...)
        IF      IBM
        PUSH    AX
        OR      AL,AL
        JNZ     GOTDRV2
        MOV     AH,Get_Default_Drive
        INT     int_command
        INC     AL              ;A=1
GOTDRV2:
        PUSH    BX
        MOV     BL,AL
        INT     11H             ;IBM EQUIP CALL
        ROL     AL,1
        ROL     AL,1
        AND     AL,3
        JNZ     NOT_SINGLE
        INC     AL
NOT_SINGLE:
        INC     AL              ; AL is now MAX floppy #
        CMP     BL,AL
        POP     BX
        JBE     SETREM          ; Is an IBM floppy and so is removable
        OR      AL,AL           ; Know AL is non-zero
        JMP     SHORT SETNREM
SETREM:
        ELSE
        PUSH    AX
        END IF

        XOR     AX,AX           ;Zero

        IF      IBM
SETNREM:
        END IF

        POP     AX
        RET

; Far call to HEADFIX for TRANSIENT
        procedure   THEADFIX,FAR
        CALL    HEADFIX
        RETF

HEADFIX:
        XOR     BX,BX           ; Clean up header
        MOV     CX,[IO_SAVE]
        MOV     DX,word [DS:Process_data_block.PDB_JFN_Table]
        CMP     CL,DL
        JZ      CHK1            ; Stdin matches
        MOV     AH,Close
        INT     int_command
        MOV     [DS:Process_data_block.PDB_JFN_Table],CL   ; Restore stdin
CHK1:
        INC     BX
        CMP     CH,DH           ; Stdout matches
        JZ      CHKOTHERHAND
        MOV     AH,Close
        INT     int_command
        MOV     [DS:Process_data_block.PDB_JFN_Table+1],CH ; Restore stdout
CHKOTHERHAND:
        ADD     BX,4                    ; Skip 2,3,4
        MOV     CX,FilPerProc - 5       ; Already done 0,1,2,3,4
CLOSELOOP:
        MOV     AH,Close
        INT     int_command
        INC     BX
        LOOP    CLOSELOOP
        RET

SAVHAND:
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        PUSH    DS
        PUSH    BX              ; Set stdin to sterr, stdout to stderr
        PUSH    AX
        MOV     AH,GET_CURRENT_PDB
        INT     int_command             ; Get user's header
        MOV     DS,BX
        MOV     AX,word [DS:Process_data_block.PDB_JFN_Table]
        MOV     [CS:HANDLE01],AX           ; Save user's stdin, stdout
        MOV     AL,[DS:Process_data_block.PDB_JFN_Table+2]
        MOV     AH,AL
        MOV     word [DS:Process_data_block.PDB_JFN_Table],AX   ; Dup stderr
        POP     AX
        POP     BX
        POP     DS
        RET

ASSUME  DS:RESGROUP
GETCOMDSK2:
        CALL    GETCOMDSK
        JMP     LODCOM1         ; Memory already allocated

RESTHAND:
        PUSH    DS
        PUSH    BX              ; Restore stdin, stdout to user
        PUSH    AX
        MOV     AH,GET_CURRENT_PDB
        INT     int_command             ; Point to user's header
        MOV     AX,[HANDLE01]
        MOV     DS,BX
ASSUME DS:NOTHING
        MOV     word [DS:Process_data_block.PDB_JFN_Table],AX   ; Stuff his old 0 and 1
        POP     AX
        POP     BX
        POP     DS
        RET
ASSUME DS:RESGROUP,SS:RESGROUP

HOPELESS:
        MOV     DX,NOCOM
        JMP     FATALC

GETCOMDSK:
        MOV     DX,NEEDCOM
GETCOMDSK3:
        MOV     AL,[COMDRV]
        CALL    REMCHECK
        JNZ     HOPELESS                ;Non-removable media
        CALL    RPRINT
        MOV     DX,DRVMSG
        CMP     [COMDRV],0
        JNZ     GETCOM1
        MOV     DX,DEFMSG
GETCOM1:
        CALL    RPRINT
        MOV     DX,PROMPT
        CALL    RPRINT
        CALL    GetRawFlushedByte
        RET

; flush world and get raw input
GetRawFlushedByte:
        MOV     AX,(Std_Con_Input_Flush SHL 8) OR Raw_Con_Input
        INT     int_command             ; Get char without testing or echo
        MOV     AX,(Std_Con_Input_Flush SHL 8) + 0
        INT     int_command
        return

LOADCOM:                        ; Load in transient
        INC     BP              ; Flag command read
        MOV     DX,COMSPEC
        MOV     AX,Open SHL 8
        INT     int_command             ; Open COMMAND.COM
        JNC     READCOM
        CMP     AX,open_too_many_open_files
        JNZ     TRYDOOPEN
        MOV     DX,NOHANDMES
        JMP     FATALC          ; Fatal, will never find a handle

TRYDOOPEN:
        CALL    GETCOMDSK
        JMP     SHORT LOADCOM

READCOM:
        MOV     BX,AX           ; Handle
        MOV     DX,TRANSTART
        XOR     CX,CX           ; Seek loc
        MOV     AX,LSeek SHL 8
        INT     int_command
        JC      WRONGCOM1
        MOV     CX,TRANSPACEEND - 100H

        IF      IBM
        ADD     CX,15
        AND     CX,0FFF0H
        ADD     CX,ZEXECCODEEND
        END IF

        PUSH    DS
        MOV     DS,[TRNSEG]
ASSUME  DS:NOTHING
        MOV     DX,100H
        MOV     AH,Read
        INT     int_command
        POP     DS
ASSUME  DS:RESGROUP
WRONGCOM1:
        PUSHF
        PUSH    AX
        MOV     AH,Close
        INT     int_command             ; Close COMMAND.COM
        POP     AX
        POPF
        JC      WRONGCOM        ; If error on READ
        CMP     AX,CX
        JZ      RET10           ; Size matched
WRONGCOM:
        MOV     DX,COMBAD
        CALL    GETCOMDSK3
        JMP     SHORT LOADCOM   ; Try again

CHKSUM:                         ; Compute transient checksum
        PUSH    DS
        MOV     DS,[TRNSEG]
        MOV     SI,100H
        MOV     CX,TRANDATAEND - 100H

CHECK_SUM:
        CLD
        SHR     CX,1
        XOR     DX,DX
CHK:
        LODSW
        ADD     DX,AX
        LOOP    CHK
        POP     DS
RET10:  RET

SETVECT:                        ; Set useful vectors
        MOV     DX,LODCOM
        MOV     AX,(Set_Interrupt_Vector SHL 8) OR 22H        ; Set Terminate address
        INT     int_command
        MOV     DX,CONTC
        MOV     AX,(Set_Interrupt_Vector SHL 8) OR 23H        ; Set Ctrl-C address
        INT     int_command
        MOV     DX,DSKERR
        MOV     AX,(Set_Interrupt_Vector SHL 8) OR 24H        ; Set Hard Disk Error address
        INT     int_command
        RET

end if

; This TAIL segment is used to produce a PARA aligned label in the resident
; group which is the location where the transient segments will be loaded
; initial.


if SEGSEL = S_TAIL
label TRANSTART word
end if

; This TAIL segment is used to produce a PARA aligned label in the transient
; group which is the location where the exec segments will be loaded
; initial.


if SEGSEL = S_TRANTAIL
label EXECSTART word
end if

IF IBMVER
END IF

