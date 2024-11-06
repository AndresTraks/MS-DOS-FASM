;
; ^C status routines for MSDOS
;

        ASSUME  SS:DOSGROUP,CS:DOSGROUP

        i_need  DevIOBuf,BYTE
        i_need  DidCTRLC,BYTE
        i_need  INDOS,BYTE
        i_need  DSKSTCOM,BYTE
        i_need  DSKSTCALL,BYTE
        i_need  DSKSTST,WORD
        i_need  BCON,DWORD
        i_need  DSKCHRET,BYTE
        i_need  DSKSTCNT,WORD
        i_need  IDLEINT,BYTE
        i_need  CONSWAP,BYTE
        i_need  user_SS,WORD
        i_need  user_SP,WORD
        i_need  ERRORMODE,BYTE
        i_need  ConC_spSave,WORD
        i_need  Exit_type,BYTE
        i_need  PFLAG,BYTE
        i_need  ExitHold,DWORD
        i_need  WPErr,BYTE
        i_need  ReadOp,BYTE
        i_need  CONTSTK,WORD
        i_need  Exit_Code,WORD
        i_need  CurrentPDB,WORD
        i_need  DIVMES,BYTE
        i_need  DivMesLen,BYTE

;SUBTTL Checks for ^C in CON I/O
PAGE
ASSUME  DS:NOTHING,ES:NOTHING

DSKSTATCHK: ; Check for ^C if only one level in
        CMP     BYTE [SS:INDOS],1
        jz DSKSTATCHK_noret
        ret                   ; Do NOTHING
DSKSTATCHK_noret:
        PUSH    CX
        PUSH    ES
        PUSH    BX
        PUSH    DS
        PUSH    SI
        PUSH    CS
        POP     ES
        PUSH    CS
        POP     DS
ASSUME  DS:DOSGROUP
        XOR     CX,CX
        MOV     BYTE [DSKSTCOM],DEVRDND
        MOV     BYTE [DSKSTCALL],DRDNDHL
        MOV     [DSKSTST],CX
        MOV     BX,DSKSTCALL
        LDS     SI,[BCON]
ASSUME  DS:NOTHING
        invoke  DEVIOCALL2
        TEST    [SS:DSKSTST],STBUI
        JNZ     ZRET                    ; No characters available
        MOV     AL,BYTE [SS:DSKCHRET]
DSK1:
        CMP     AL,"C"-"@"
        JNZ     RET36
        MOV     BYTE [SS:DSKSTCOM],DEVRD
        MOV     BYTE [SS:DSKSTCALL],DRDWRHL
        MOV     BYTE [SS:DSKCHRET],CL
        MOV     [SS:DSKSTST],CX
        INC     CX
        MOV     [SS:DSKSTCNT],CX
        invoke  DEVIOCALL2              ; Eat the ^C
        POP     SI
        POP     DS
        POP     BX                      ; Clean stack
        POP     ES
        POP     CX
        JMP     SHORT CNTCHAND

ZRET:
        XOR     AL,AL                   ; Set zero
RET36:
        POP     SI
        POP     DS
        POP     BX
        POP     ES
        POP     CX
        return

NOSTOP:
        CMP     AL,"P"-"@"
        JZ      INCHK

        IF      TOGLPRN = 0
        CMP     AL,"N"-"@"
        JZ      INCHK
        END     IF

        CMP     AL,"C"-"@"
        JZ      INCHK
        return

        procedure   SPOOLINT,NEAR
        PUSHF
        CMP     BYTE [SS:IDLEINT],0
        JZ      POPFRET
        CMP     BYTE [SS:ERRORMODE],0
        JNZ     POPFRET                 ;No spool ints in error mode
        INT     int_spooler
POPFRET:
        POPF
RET18:  return

        procedure   STATCHK,NEAR

        invoke  DSKSTATCHK              ; Allows ^C to be detected under
                                        ; input redirection
        PUSH    BX
        XOR     BX,BX
        invoke  GET_IO_FCB
        POP     BX
        JC      RET18
        MOV     AH,1
        invoke  IOFUNC
        JZ      SPOOLINT
        CMP     AL,'S'-'@'
        JNZ     NOSTOP
        XOR     AH,AH
        invoke  IOFUNC                  ; Eat Cntrl-S
        JMP     SHORT PAUSOSTRT
PRINTOFF:
PRINTON:
        NOT     BYTE [SS:PFLAG]
PRINTON_ret:
        return

PAUSOLP:
        CALL    SPOOLINT
PAUSOSTRT:
        MOV     AH,1
        invoke  IOFUNC
        JZ      PAUSOLP
INCHK:
        PUSH    BX
        XOR     BX,BX
        invoke  GET_IO_FCB
        POP     BX
        JC      RET18
        XOR     AH,AH
        invoke  IOFUNC
        CMP     AL,'P'-'@'
        JZ      PRINTON
        IF      TOGLPRN = 0
        CMP     AL,'N'-'@'
        JZ      PRINTOFF
        END     IF
        CMP     AL,'C'-'@'
        jnz PRINTON_ret

        procedure   CNTCHAND,NEAR
; Ctrl-C handler.
; "^C" and CR/LF is printed.  Then the user registers are restored and
; the user CTRL-C handler is executed.  At this point the top of the stack
; has 1) the interrupt return address should the user CTRL-C handler wish
; to allow processing to continue; 2) the original interrupt return address
; to the code that performed the function call in the first place.  If
; the user CTRL-C handler wishes to continue, it must leave all registers
; unchanged and RET (not IRET) with carry CLEAR.  If carry is SET then
; an terminate system call is simulated.
        MOV     AL,3                ; Display "^C"
        invoke  BUFOUT
        invoke  CRLF
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        CMP     BYTE [CONSWAP],0
        JZ      NOSWAP
        invoke  SWAPBACK
NOSWAP:
        CLI                         ; Prepare to play with stack
        MOV     SP,[user_SP]
        MOV     SS,[user_SS]        ; User stack now restored
ASSUME  SS:NOTHING
        invoke  restore_world       ; User registers now restored
ASSUME  DS:NOTHING
        MOV     BYTE [CS:INDOS],0  ; Go to known state
        MOV     BYTE [CS:ERRORMODE],0
        MOV     [CS:ConC_spsave],SP    ; save his SP
        INT     int_ctrl_c          ; Execute user Ctrl-C handler
        MOV     [CS:user_SS],AX        ; save the AX
        PUSHF                       ; and the flags (maybe new call)
        POP     AX
        CMP     SP,[CS:ConC_spsave]
        JNZ     ctrlc_try_new       ; new syscall maybe?
ctrlc_repeat:
        MOV     AX,[CS:user_SS]        ; no...
        transfer    COMMAND         ; Repeat command otherwise

ctrlc_try_new:
        SUB     [CS:ConC_spsave],2     ; Are there flags on the stack?
        CMP     SP,[CS:ConC_spsave]
        JZ      ctrlc_new           ; yes, new system call

ctrlc_abort:
        MOV     AX,(Exit SHL 8) + 0
        MOV     BYTE [CS:DidCTRLC],0FFh

        transfer    COMMAND         ; give up by faking $EXIT

ctrlc_new:
        PUSH    AX
        POPF
        POP     [CS:user_SS]
        JNC     ctrlc_repeat        ; repeat operation
        JMP     ctrlc_abort         ; indicate ^ced

;SUBTTL DIVISION OVERFLOW INTERRUPT
PAGE
; Default handler for division overflow trap
        procedure   DIVOV,NEAR
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        MOV     SI,DIVMES
        CALL    RealDivOv
        JMP     ctrlc_abort     ; Use Ctrl-C abort on divide overflow

;
; RealDivOv: perform actual divide overflow stuff.
; Inputs:   none
; Outputs:  message to BCON
;
        procedure   RealDivOv,NEAR  ; Do divide overflow and clock process

        PUSH    CS                  ; get ES addressability
        POP     ES

        PUSH    CS                  ; get DS addressability
        POP     DS

        MOV     BYTE [DSKSTCOM],DEVWRT
        MOV     BYTE [DSKSTCALL],DRDWRHL
        MOV     [DSKSTST],0
        MOV     BL,[DivMesLen]
        XOR     BH,BH
        MOV     [DSKSTCNT],BX
        MOV     BX,DSKSTCALL
        MOV     WORD [DSKCHRET+1],SI    ; transfer address (need an EQU)
        LDS     SI,[BCON]
ASSUME  DS:NOTHING
        invoke  DEVIOCALL2
        MOV     WORD [CS:DSKCHRET+1],DEVIOBUF
        MOV     [CS:DSKSTCNT],1
        return

;SUBTTL CHARHRD,HARDERR,ERROR -- HANDLE DISK ERRORS AND RETURN TO USER
PAGE
        procedure   CHARHARD,NEAR
ASSUME  DS:NOTHING,ES:NOTHING,SS:DOSGROUP

; Character device error handler
; Same function as HARDERR

        MOV     WORD [SS:EXITHOLD+2],ES
        MOV     WORD [SS:EXITHOLD],BP
        PUSH    SI
        AND     DI,STECODE
        MOV     BP,DS                   ;Device pointer is BP:SI
        CALL    FATALC
        POP     SI
        return

        procedure   HARDERR,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Hard disk error handler. Entry conditions:
;       DS:BX = Original disk transfer address
;       DX = Original logical sector number
;       CX = Number of sectors to go (first one gave the error)
;       AX = Hardware error code
;       DI = Original sector transfer count
;       ES:BP = Base of drive parameters
;       [READOP] = 0 for read, 1 for write
                                        ;
        XCHG    AX,DI                   ; Error code in DI, count in AX
        AND     DI,STECODE              ; And off status bits
        CMP     DI,WRECODE              ; Write Protect Error?
        JNZ     NOSETWRPERR
        PUSH    AX
        MOV     AL,[ES:BP+dpb.dpb_drive]
        MOV     BYTE [SS:WPERR],AL              ; Flag drive with WP error
        POP     AX
NOSETWRPERR:
        SUB     AX,CX                   ; Number of sectors successfully transferred
        ADD     DX,AX                   ; First sector number to retry
        PUSH    DX
        MUL     [ES:BP+dpb.dpb_sector_size]          ; Number of bytes transferred
        POP     DX
        ADD     BX,AX                   ; First address for retry
        XOR     AH,AH                   ; Flag disk section in error
        CMP     DX,[ES:BP+dpb.dpb_first_FAT]    ; In reserved area?
        JB      ERRINT
        INC     AH                      ; Flag for FAT
        CMP     DX,[ES:BP+dpb.dpb_dir_sector]   ; In FAT?
        JB      ERRINT
        INC     AH
        CMP     DX,[ES:BP+dpb.dpb_first_sector]       ; In directory?
        JB      ERRINT
        INC     AH                      ; Must be in data area
ERRINT:
        SHL     AH,1                    ; Make room for read/write bit
        OR      AH,BYTE [SS:READOP]
        entry   FATAL
        MOV     AL,[ES:BP+dpb.dpb_drive]      ; Get drive number
        entry   FATAL1
        MOV     WORD [SS:EXITHOLD+2],ES
        MOV     WORD [SS:EXITHOLD],BP  ; The only things we preserve
        LES     SI,[ES:BP+dpb.dpb_driver_addr]
        MOV     BP,ES                   ; BP:SI points to the device involved
FATALC:
        CMP     BYTE [SS:ERRORMODE],0
        JNZ     SETIGN                  ; No INT 24s if already INT 24
        MOV     [SS:CONTSTK],SP
        PUSH    SS
        POP     ES
ASSUME  ES:DOSGROUP
        CLI                             ; Prepare to play with stack
        INC     BYTE [SS:ERRORMODE]    ; Flag INT 24 in progress
        DEC     BYTE [SS:INDOS]        ; INT 24 handler might not return
        MOV     SS,[SS:user_SS]
ASSUME  SS:NOTHING
        MOV     SP,[ES:user_SP]         ; User stack pointer restored
        INT     int_fatal_abort         ; Fatal error interrupt vector, must preserve ES
        MOV     [ES:user_SP],SP         ; restore our stack
        MOV     [ES:user_SS],SS
        MOV     SP,ES
        MOV     SS,SP
ASSUME  SS:DOSGROUP
        MOV     SP,[SS:CONTSTK]
        INC     BYTE [SS:INDOS]        ; Back in the DOS
        MOV     BYTE [SS:ERRORMODE],0  ; Back from INT 24
        STI
IGNRET:
        LES     BP,[SS:EXITHOLD]
ASSUME  ES:NOTHING
        CMP     AL,2
        JZ      error_abort
        MOV     BYTE [SS:WPERR],-1              ;Forget about WP error
        return

SETIGN:
        XOR     AL,AL                   ;Flag ignore
        JMP     SHORT IGNRET

error_abort:
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        CMP     BYTE [CONSWAP],0
        JZ      NOSWAP2
        invoke  SWAPBACK
NOSWAP2:
        MOV     BYTE [exit_type],.Exit_Hard_Error
        MOV     DS,[CurrentPDB]
ASSUME  DS:NOTHING

;
; reset_environment checks the DS value against the CurrentPDB.  If they
; are different, then an old-style return is performed.  If they are
; the same, then we release jfns and restore to parent.  We still use
; the PDB at DS:0 as the source of the terminate addresses.
;
; output:   none.
;
        entry   reset_environment
        ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    DS                      ; save PDB of process

        MOV     AL,int_terminate
        invoke  _GET_INTERRUPT_VECTOR   ; and who to go to
        MOV     WORD [SS:EXITHOLD+2],ES ; save return address
        MOV     WORD [SS:EXITHOLD],BX

        MOV     BX,[SS:CurrentPDB]         ; get current process
        MOV     DS,BX                   ;
        MOV     AX,[DS:Process_data_block.PDB_Parent_PID]  ; get parent to return to
        POP     CX
;
; AX = parentPDB, BX = CurrentPDB, CX = ThisPDB
; Only free handles if AX <> BX and BX = CX and [exit_code].upper is not
; Exit_keep_process
;
        CMP     AX,BX
        JZ      reset_return            ; parentPDB = CurrentPDB
        CMP     BX,CX
        JNZ     reset_return            ; CurrentPDB <> ThisPDB
        PUSH    AX                      ; save parent
        CMP     BYTE [SS:exit_type],.Exit_Keep_process
        JZ      reset_to_parent         ; keeping this process

        invoke  arena_free_process

        ; reset environment at [CurrentPDB]; close those handles
        MOV     CX,FilPerProc

reset_free_jfn:
        MOV     BX,CX
        PUSH    CX
        DEC     BX                      ; get jfn
        invoke  _CLOSE                  ; close it, ignore return
        POP     CX
        LOOP    reset_free_jfn          ; and do 'em all

reset_to_parent:
        POP     [SS:CurrentPDB]            ; set up process as parent

reset_return:                           ; come here for normal return
        PUSH    CS
        POP     DS
        ASSUME  DS:DOSGROUP
        MOV     AL,-1
        invoke  FLUSHBUF                ; make sure that everything is clean

        CLI
        MOV     BYTE [INDOS],0               ;Go to known state
        MOV     BYTE [WPERR],-1              ;Forget about WP error
;
; Snake into multitasking... Get stack from CurrentPDB person
;
        MOV     DS,[CurrentPDB]
        ASSUME  DS:NOTHING
        MOV     SS,WORD [DS:Process_data_block.PDB_User_stack+2]
        MOV     SP,WORD [DS:Process_data_block.PDB_User_stack]

        ASSUME  SS:NOTHING
        invoke  restore_world
        ASSUME  ES:NOTHING
        POP     AX                      ; suck off CS:IP of interrupt...
        POP     AX
        POP     AX
        MOV     AX,0F202h               ; STI
        PUSH    AX
        PUSH    WORD [CS:EXITHOLD+2]
        PUSH    WORD [CS:EXITHOLD]
        STI
        IRET            ; Long return back to user terminate address

        ASSUME  SS:DOSGROUP

do_ext
