FALSE   =     0
TRUE    =     -1

SYSVER  =     FALSE                   ;if true, i/o direct to bios
                                        ; so DOS can be debugged
IBMJAPVER   = FALSE                   ; true for their special parity stuff


FIRSTDRV =    "A"

if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_DATA
end if



if SEGSEL = S_CODE
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG

TrapParity:
        IF IBMJAPVER
        PUSH    BX
        PUSH    ES
        PUSH    DX                      ; save location of new offset
        MOV     DX,NMIInt     ; DS:DX has new interrupt vector
        CALL    SwapInt                 ; diddle interrupts
        ASSUME  ES:NOTHING
        MOV     word [NMIPtr],BX    ; save old offset
        MOV     word [NMIPtr+2],ES  ; save old segment
        POP     DX                      ; get old regs back
        POP     ES                      ; restore old values
        ASSUME  ES:DG
        POP     BX
        MOV     byte [ParityFlag],0 ; no interrupts detected yet!
        RET
SwapInt:
        PUSH    AX
        MOV     AX,(GET_INTERRUPT_VECTOR SHL 8) + 2
        INT     21h                     ; get old nmi vector
        MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) + 2
        INT     21h                     ; let OS set new vector
        POP     AX
        end if
        RET
ReleaseParity:
        IF  IBMJAPVER
        PUSH    DX
        PUSH    DS
        PUSH    BX
        PUSH    ES
        LDS     DX,dword [NMIPtr]   ; get old vector
        CALL    SwapInt                 ; diddle back to original
        POP     ES
        POP     BX
        POP     DS
        POP     DX
        MOV     [ParityFlag],0          ; no interrupts possible!
        end if
        RET

NMIInt:
        IF IBMJAPVER
        PUSH    AX                      ; save AX
        IN      AL,0A0h                 ; get status register
        OR      AL,1                    ; was there parity check?
        POP     AX                      ; get old AX back
        JZ      NMIChain                ; no, go chain interrupt
        OUT     0A2h,AL                 ; reset NMI detector
        MOV     [CS:ParityFlag],1       ; signal detection
        IRET
NMIChain:
        JMP     dword [CS:NMIPtr]   ; chain the vectors
NMIPtr  DD      0; where old NMI gets stashed
        end if
NMIIntEnd:

DRVERR: MOV     DX,DISK
        OR      AL,AL
        JNZ     SAVDRV
        MOV     DX,WRTPRO
SAVDRV:
        PUSH    CS
        POP     DS
        PUSH    CS
        POP     ES
        ADD     byte [DRVLET],FIRSTDRV
        MOV     SI,READM
        MOV     DI,ERRTYP
        CMP     byte [RDFLG],WRITE
        JNZ     MOVMES
        MOV     SI,WRITM
MOVMES:
        MOVSW
        MOVSW
        CALL    RPRBUF
        MOV     DX,DSKERR
        JMP     RESTART
CODEEND:

end if


if SEGSEL = S_CONST


        IF      SYSVER
BADDEV      DB      "Bad device name",13,10,"$"
BADLSTMES   DB    "Couldn't open list device PRN",13,10
            DB      "Enter name of list device? $"
        end if

BADVER      DB      "Incorrect DOS version",13,10,"$"
ENDMES      DB      13,10,"Program terminated normally"
CARRET      DB      13,10,"$"
NAMBAD      DB      "Invalid drive specification",13,10,"$"
NOTFND      DB      "File not found",13,10,"$"
NOROOM      DB      "File creation error",13,10,"$"
NOSPACE     DB      "Insufficient space on disk",13,10,"$"


DISK        DB      "Disk$"
WRTPRO      DB      "Write protect$"
DSKERR      DB      " error "
ERRTYP      DB      "reading drive "
DRVLET      DB      "A",13,10,"$"
READM       DB      "read"
WRITM       DB      "writ"


TOOBIG      DB      "Insufficient memory",13,10,"$"
SYNERR      DB      '^'
ERRMES      DB      " Error",13,10+80H
BACMES      DB      32,8+80H
label EXEBAD byte
HEXERR      DB      "Error in EXE or HEX file",13,10,"$"
label EXEWRT byte
HEXWRT      DB      "EXE and HEX files cannot be written",13,10,"$"
WRTMES1     DB      "Writing $"
WRTMES2     DB      " bytes",13,10,"$"
EXECEMES    DB     "EXEC failure",13,10,"$"
ACCMES      DB      "Access denied",13,10,"$"
ParityMes   DB      "Parity error or nonexistant memory error detected",13,10,"$"

CONSTEND:

end if
