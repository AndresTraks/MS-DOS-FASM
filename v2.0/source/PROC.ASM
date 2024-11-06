;
; process control system calls for MSDOS
;

        ASSUME  SS:DOSGROUP,CS:DOSGROUP

    i_need  CurrentPDB,WORD
    i_need  CreatePDB,BYTE
    i_need  NUMIO,BYTE
    i_need  Exit_type,BYTE
    i_need  INDOS,BYTE
    i_need  DMAADD,DWORD
    i_need  DidCTRLC,BYTE

;SUBTTL $WAIT - return previous process error code
PAGE
;
; process control data
;
        i_need  exit_code,WORD          ; code of exit

;
;   Assembler usage:
;           MOV     AH, Wait
;           INT     int_command
;         AX has the exit code
        procedure   _WAIT,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        MOV     AX,[SS:exit_code]
        XOR     DX,DX
        MOV     [SS:exit_code],DX
        transfer    SYS_RET_OK

IF IBM
        procedure   _EXEC,NEAR
        error   error_invalid_function
END IF
IF IBM = 0
INCLUDE 'EXEC.ASM'
END IF

;SUBTTL Terminate and stay resident handler
PAGE
;
; Input:    DX is  an  offset  from  CurrentPDB  at which to
;           truncate the current block.
;
; output:   The current block is truncated (expanded) to be [DX+15]/16
;           paragraphs long.  An exit is simulated via resetting CurrentPDB
;           and restoring the vectors.
;
        procedure   _Keep_Process,NEAR
        ASSUME DS:NOTHING,ES:NOTHING,SS:DOSGROUP

        PUSH    AX                      ; keep exit code around
        MOV     BYTE [SS:exit_type],.Exit_Keep_process
        MOV     ES,[SS:CurrentPDB]
        CMP     DX,6h                   ; keep enough space around for system
        JAE     keep_shrink             ; info
        MOV     DX,6h
keep_shrink:
        MOV     BX,DX
        PUSH    BX
        PUSH    ES
        invoke  _SETBLOCK               ; ignore return codes.
        POP     DS
        POP     BX
        JC      keep_done               ; failed on modification
        MOV     AX,DS
        ADD     AX,BX
        MOV     [DS:Process_data_block.PDB_block_len],AX

keep_done:
        POP     AX
        JMP     SHORT exit_inner        ; and let abort take care of the rest

        procedure   Stay_resident,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        MOV     AX,(Keep_Process SHL 8) + 0 ; Lower part is return code
        ADD     DX,15
        MOV     CL,4
        SHR     DX,CL

        transfer    COMMAND

;SUBTTL $EXIT - return to parent process
PAGE
;
;   Assembler usage:
;           MOV     AL, code
;           MOV     AH, Exit
;           INT     int_command
;   Error return:
;           None.
;
        procedure   _EXIT,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING,SS:DOSGROUP
        XOR     AH,AH
        XCHG    AH,BYTE [SS:DidCTRLC]
        OR      AH,AH
        MOV     BYTE [SS:exit_type],.Exit_terminate
        JZ      exit_inner
        MOV     BYTE [SS:exit_type],.Exit_Ctrl_C

exit_inner:
        invoke  get_user_stack
        PUSH    [SS:CurrentPDB]
        POP     [SI+user_environ.user_CS]
        transfer    abort_inner

do_ext
