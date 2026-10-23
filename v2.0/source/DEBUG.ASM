; DEBUG-86 8086 debugger runs under 86-DOS       version 2.30
;
; Modified 5/4/82 by AaronR to do all I/O direct to devices
; Runs on MS-DOS 1.28 and above
; REV 1.20
;       Tab expansion
;       New device interface (1.29 and above)
; REV 2.0
;       line by line assembler added by C. Peters
; REV 2.1
;       Uses EXEC system call
; REV 2.2
;       Ztrace mode by zibo.
;       Fix dump display to indent properly
;       Parity nonsense by zibo
;
; REV 2.3
;       Split into seperate modules to allow for
;       assembly on an IBM PC
;



        INCLUDE 'DEBEQU.ASM'

        IF      SYSVER

; Structure for system call 72

STRUC SYSINITVAR
{
        .DPBHEAD        dd 0
        .sft_addr       dd 0
        ; The following address points to the CLOCK device
        .BCLOCK         dd 0
        ; The following address is used by DISKSTATCHK it is always
        ; points to the console input device header
        .BCON           dd 0
        .NUMIO          db 0                   ; Number of disk tables
        .MAXSEC         dw 0                   ; Maximum allowed sector size
        .BUFFHEAD       dd 0
        .DEVHEAD        dd 0
}

virtual at 0
  SYSINITVAR SYSINITVAR
  sizeof.SYSINITVAR = $ - SYSINITVAR
end virtual
        end if


if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST


        IF  IBMVER
        end if

        IF      SYSVER
        end if

end if

if SEGSEL = S_DATA


end if



if SEGSEL = S_CODE
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG


        IF  SYSVER
        end if



        ORG     100H

START:
DEBUG:
        JMP     SHORT DSTRT

HEADER DB       "Vers 2.30"

DSTRT:
DOSVER_HIGH     =  0200H              ; 2.00 in hex
        MOV     AH,GET_VERSION
        INT     21H
        XCHG    AH,AL                   ; Turn it around to AH.AL
        CMP     AX,DOSVER_HIGH
        JAE     OKDOS
GOTBADDOS:
        MOV     DX,BADVER
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        INT     20H

OKDOS:
        CALL    TrapParity              ; scarf up those parity guys
        MOV     AH,GET_CURRENT_PDB
        INT     21H
        MOV     [USER_PROC_PDB],BX      ; Initially set to DEBUG

        IF      SYSVER
        MOV     [IOSEG],CS
        end if

        MOV     SP,STACK_
        MOV     [PARSERR],AL
        MOV     AH,GET_IN_VARS
        INT     21H


        IF      SYSVER
        LDS     SI,[ES:BX+SYSINITVAR.BCON]
        MOV     word [CS:CIN+2],DS
        MOV     word [CS:CIN],SI
        MOV     word [CS:COUT+2],DS
        MOV     word [CS:COUT],SI
        PUSH    CS
        POP     DS
        MOV     DX,CONFCB
        MOV     AH,FCB_OPEN
        INT     21H
        OR      AL,AL
        JZ      GOTLIST
        MOV     DX,BADLSTMES
        CALL    RPRBUF
        CALL    RBUFIN
        CALL    CRLF
        MOV     CL,[LBUFFCNT]
        OR      CL,CL
        JZ      NOLIST1                 ; User didn't specify one
        XOR     CH,CH
        MOV     DI,(CONFCB + 1)
        MOV     SI,LINEBUF
        REP     MOVSB
        MOV     DX,CONFCB
        MOV     AH,FCB_OPEN
        INT     21H
        OR      AL,AL
        JZ      GOTLIST                 ; GOOD
        MOV     DX,BADDEV
        CALL    RPRBUF
NOLIST1:
        MOV     word [POUT+2],CS
        MOV     word [POUT],LONGRET
        JMP     NOLIST

XXX:
LONGRET:RETF
        end if

GOTLIST:
        IF      SYSVER
        MOV     SI,DX
        LDS     SI,dword [DS:SI+sys_fcb.fcb_FIRCLUS]
        MOV     word [CS:POUT+2],DS
        MOV     word [CS:POUT],SI
        end if
NOLIST:
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX

; Code to print header
;       MOV     DX,OFFSET DG:HEADER
;       CALL    RPRBUF

        CALL    SET_TERMINATE_VECTOR

        IF      SETCNTC
        MOV     AL,23H                  ; Set vector 23H
        MOV     DX,DABORT
        INT     21H
        end if

        MOV     DX,CS                   ; Get DEBUG's segment
        MOV     AX,DATAEND + 15   ; End of debug
        SHR     AX,1                    ; Convert to segments
        SHR     AX,1
        SHR     AX,1
        SHR     AX,1
        ADD     DX,AX                   ; Add siz of debug in paragraphs
        MOV     AH,CREATE_PROCESS_DATA_BLOCK    ; create program segment just after DEBUG
        INT     21H
        MOV     AX,DX
        MOV     DI,DSSAVE
        CLD
        STOSW
        STOSW
        STOSW
        STOSW
        MOV     word [DISADD+2],AX
        MOV     word [ASMADD+2],AX
        MOV     word [DEFDUMP+2],AX
        MOV     AX,100H
        MOV     word [DISADD],AX
        MOV     word [ASMADD],AX
        MOV     word [DEFDUMP],AX
        MOV     DS,DX
        MOV     ES,DX
        MOV     DX,80H
        MOV     AH,SET_DMA
        INT     21H                     ; Set default DMA address to 80H
        MOV     AX,word [DS:6]
        MOV     BX,AX
        CMP     AX,0FFF0H
        PUSH    CS
        POP     DS
        JAE     SAVSTK
        MOV     AX,word [DS:6]
        PUSH    BX
        MOV     BX,DATAEND + 15
        AND     BX,0FFF0H               ; Size of DEBUG in bytes (rounded up to PARA)
        SUB     AX,BX
        POP     BX
SAVSTK:
        PUSH    BX
        DEC     AX
        DEC     AX
        MOV     BX,AX
        MOV     word [BX],0
        POP     BX
        MOV     [SPSAVE],AX
        DEC     AH
        MOV     word [ES:6],AX
        SUB     BX,AX
        MOV     CL,4
        SHR     BX,CL
        ADD     word [ES:8],BX

        IF IBMVER
        ; Get screen size and initialize display related variables
        MOV     AH,15
        INT     10H
        CMP     AH,40
        JNZ     PARSCHK
        MOV     byte [DSIZ],7
        MOV     byte [NOREGL],4
        MOV     [DISPB],64
        end if

PARSCHK:
; Copy rest of command line to test program's parameter area
        MOV     DI,FCB
        MOV     SI,81H
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
        INT     21H
        CALL    SKIP_FILE               ; Make sure si points to delimiter
        CALL    PREPNAME
        PUSH    CS
        POP     ES
FILECHK:
        MOV     DI,80H
        CMP     byte [ES:DI],0      ; ANY STUFF FOUND?
        JZ      COMMAND                 ; NOPE
FILOOP: INC     DI
        CMP     byte [ES:DI],13     ; COMMAND LINE JUST SPACES?
        JZ      COMMAND
        CMP     byte [ES:DI]," "
        JZ      FILOOP
        CMP     byte [ES:DI],9
        JZ      FILOOP

        CALL    DEFIO                   ; WELL READ IT IN
        MOV     AX,[CSSAVE]
        MOV     word [DISADD+2],AX
        MOV     word [ASMADD+2],AX
        MOV     AX,[IPSAVE]
        MOV     word [DISADD],AX
        MOV     word [ASMADD],AX
COMMAND:
        CLD
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX
        MOV     SS,AX
        MOV     SP,STACK_
        STI
        CMP     [ParityFlag],0          ; did we detect a parity error?
        JZ      GoPrompt                ; nope, go prompt
        MOV     [ParityFlag],0          ; reset flag
        MOV     DX,ParityMes  ; message to print
        MOV     AH,STD_CON_STRING_OUTPUT; easy way out
        INT     21h                     ; blam
GoPrompt:
        MOV     AL,PROMPT
        CALL    OUT_
        CALL    INBUF                   ; Get command line
; From now and throughout command line processing, DI points
; to next character in command line to be processed.
        CALL    SCANB                   ; Scan off leading blanks
        JZ      COMMAND                 ; Null command?
        LODSB                           ; AL=first non-blank character
; Prepare command letter for table lookup
        SUB     AL,"A"                  ; Low end range check
        JB      ERR1
        CMP     AL,"Z"-"A"              ; Upper end range check
        JA      ERR1
        SHL     AL,1                    ; Times two
        CBW                             ; Now a 16-bit quantity
        XCHG    BX,AX                   ; In BX we can address with it
        CALL    [CS:BX+COMTAB]          ; Execute command
        JMP     SHORT COMMAND           ; Get next command
ERR1:   JMP     PERR

SET_TERMINATE_VECTOR:
        MOV     AX,(SET_INTERRUPT_VECTOR SHL 8) OR 22H  ; Set vector 22H
        MOV     DX,TERMINATE
        INT     21H
        RET

TERMINATE:
        CMP     byte [CS:QFLAG],0
        JNZ     QUITING
        MOV     [CS:USER_PROC_PDB],CS
        CMP     byte [CS:NEWEXEC],0
        JZ      NORMTERM
        MOV     AX,CS
        MOV     DS,AX
        MOV     SS,AX
        MOV     SP,STACK_
        MOV     AX,[HEADSAVE]
        JMP     DEBUG_FOUND

NORMTERM:
        MOV     DX,ENDMES
        JMP     SHORT RESTART

QUITING:
        MOV     AX,(EXIT SHL 8)
        INT     21H

DABORT:
        MOV     DX,CARRET
RESTART:
        MOV     AX,CS
        MOV     DS,AX
        MOV     SS,AX
        MOV     SP,STACK_
        CALL    RPRBUF
        JMP     COMMAND

        IF      SYSVER
SETUDEV:
        MOV     DI,CONFCB
        MOV     AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
        INT     21H
        CALL    USERDEV
        JMP     DISPREG

USERDEV:
        MOV     DX,CONFCB
        MOV     AH,FCB_OPEN
        INT     21H
        OR      AL,AL
        JNZ     OPENERR
        MOV     SI,DX
        TEST    byte [SI+sys_fcb.fcb_DEVID],080H    ; Device?
        JZ      OPENERR                 ; NO
        LDS     SI,dword [CONFCB+sys_fcb.fcb_FIRCLUS]
        MOV     word [CS:CIN],SI
        MOV     word [CS:CIN+2],DS
        MOV     word [CS:COUT],SI
        MOV     word [CS:COUT+2],DS
        PUSH    CS
        POP     DS
        RET


OPENERR:
        MOV     DX,BADDEV
        CALL    RPRBUF
        RET
        end if

; Get input line. Convert all characters NOT in quotes to upper case.

INBUF:
        CALL    RBUFIN
        MOV     SI,LINEBUF
        MOV     DI,BYTEBUF
CASECHK:
        LODSB
        CMP     AL,'a'
        JB      NOCONV
        CMP     AL,'z'
        JA      NOCONV
        ADD     AL,"A"-"a"              ; Convert to upper case
NOCONV:
        STOSB
        CMP     AL,13
        JZ      INDONE
        CMP     AL,'"'
        JZ      QUOTSCAN
        CMP     AL,"'"
        JNZ     CASECHK
QUOTSCAN:
        MOV     AH,AL
KILLSTR:
        LODSB
        STOSB
        CMP     AL,13
        JZ      INDONE
        CMP     AL,AH
        JNZ     KILLSTR
        JMP     SHORT CASECHK

INDONE:
        MOV     SI,BYTEBUF

; Output CR/LF sequence

CRLF:
        MOV     AL,13
        CALL    OUT_
        MOV     AL,10
        JMP     OUT_

; Physical backspace - blank, backspace, blank

BACKUP:
        MOV     SI,BACMES

; Print ASCII message. Last char has bit 7 set

PRINTMES:
        LODS    byte [CS:SI]        ; Get char to print
        CALL    OUT_
        SHL     AL,1                    ; High bit set?
        JNC     PRINTMES
        RET

; Scan for parameters of a command

SCANP:
        CALL    SCANB                   ; Get first non-blank
        CMP     byte [SI],","       ; One comma between params OK
        JNE     EOLCHK                  ; If not comma, we found param
        INC     SI                      ; Skip over comma

; Scan command line for next non-blank character

SCANB:
        PUSH    AX
SCANNEXT:
        LODSB
        CMP     AL," "
        JZ      SCANNEXT
        CMP     AL,9
        JZ      SCANNEXT
        DEC     SI                      ; Back to first non-blank
        POP     AX
EOLCHK:
        CMP     byte [SI],13
        RET

; Hex addition and subtraction

HEXADD:
        MOV     CX,4
        CALL    GETHEX
        MOV     DI,DX
        MOV     CX,4
        CALL    GETHEX
        CALL    GETEOL
        PUSH    DX
        ADD     DX,DI
        CALL    OUT16
        CALL    BLANK
        CALL    BLANK
        POP     DX
        SUB     DI,DX
        MOV     DX,DI
        CALL    OUT16
        JMP     SHORT CRLF

; Print the hex address of DS:SI

OUTSI:
        MOV     DX,DS                   ; Put DS where we can work with it
        CALL    OUT16                   ; Display segment
        MOV     AL,":"
        CALL    OUT_
        MOV     DX,SI
        JMP     SHORT OUT16             ; Output displacement

; Print hex address of ES:DI
; Same as OUTSI above

OUTDI:
        MOV     DX,ES
        CALL    OUT16
        MOV     AL,":"
        CALL    OUT_
        MOV     DX,DI

; Print out 16-bit value in DX in hex

OUT16:
        MOV     AL,DH                   ; High-order byte first
        CALL    HEX
        MOV     AL,DL                   ; Then low-order byte

; Output byte in AL as two hex digits

HEX:
        MOV     AH,AL                   ; Save for second digit
; Shift high digit into low 4 bits
        PUSH    CX
        MOV     CL,4
        SHR     AL,CL
        POP     CX

        CALL    DIGIT                   ; Output first digit
        MOV     AL,AH                   ; Now do digit saved in AH
DIGIT:
        AND     AL,0FH                  ; Mask to 4 bits
; Trick 6-byte hex conversion works on 8086 too.
        ADD     AL,90H
        DAA
        ADC     AL,40H
        DAA

; Console output of character in AL. No registers affected but bit 7
; is reset before output.

        IF      SYSVER
OUT_:
        PUSH    AX
        AND     AL,7FH
        CMP     AL,7FH
        JNZ     NOTDEL
        MOV     AL,8                    ; DELETE same as backspace
NOTDEL:
        CMP     AL,9
        JZ      TABDO
        CALL    DOCONOUT
        CMP     AL,0DH
        JZ      ZEROPOS
        CMP     AL,0AH
        JZ      ZEROPOS
        CMP     AL,8
        JNZ     OOKRET
        MOV     AL," "
        CALL    DOCONOUT
        MOV     AL,8
        CALL    DOCONOUT
        CMP     byte [CS:COLPOS],0
        JZ      NOTINC
        DEC     byte [CS:COLPOS]
        JMP     NOTINC
ZEROPOS:
        MOV     byte [CS:COLPOS],0FFH
OOKRET:
        INC     byte [CS:COLPOS]
NOTINC:
        TEST    byte [CS:PFLAG],1
        JZ      POPRET
        CALL    LISTOUT
POPRET:
        POP     AX
        RET

TABDO:
        MOV     AL,[CS:COLPOS]
        OR      AL,0F8H
        NEG     AL
        PUSH    CX
        MOV     CL,AL
        XOR     CH,CH
        JCXZ    POPTAB
TABLP:
        MOV     AL," "
        CALL    OUT_
        LOOP    TABLP
POPTAB:
        POP     CX
        POP     AX
        RET


DOCONOUT:
        PUSH    DS
        PUSH    SI
        PUSH    AX
CONOWAIT:
        LDS     SI,[CS:COUT]
        MOV     AH,10
        CALL    DEVIOCALL
        MOV     AX,[CS:IOSTAT]
        AND     AX,200H
        JNZ     CONOWAIT
        POP     AX
        PUSH    AX
        MOV     AH,8
        CALL    DEVIOCALL
        POP     AX
        POP     SI
        POP     DS
        RET


LISTOUT:
        PUSH    DS
        PUSH    SI
        PUSH    AX
LISTWAIT:
        LDS     SI,[CS:POUT]
        MOV     AH,10
        CALL    DEVIOCALL
        MOV     AX,[CS:IOSTAT]
        AND     AX,200H
        JNZ     LISTWAIT
        POP     AX
        PUSH    AX
        MOV     AH,8
        CALL    DEVIOCALL
        POP     AX
        POP     SI
        POP     DS
        RET

DEVIOCALL:
        PUSH    ES
        PUSH    BX
        PUSH    CS
        POP     ES
        MOV     BX,IOCALL
        MOV     [CS:IOCOM],AH
        MOV     word [CS:IOSTAT],0
        MOV     word [CS:IOCNT],1
        MOV     [CS:IOBUFF],AL
        MOV     word [CS:IOADDR+2],DS
        MOV     AX,[SI+6]
        MOV     word [CS:IOADDR],AX
        CALL    dword [CS:IOADDR]
        MOV     AX,[SI+8]
        MOV     word [CS:IOADDR],AX
        CALL    dword [CS:IOADDR]
        MOV     AL,[CS:IOBUFF]
        POP     BX
        POP     ES
        RET
        ELSE

OUT_:
        PUSH    DX
        PUSH    AX
        AND     AL,7FH
        MOV     DL,AL
        MOV     AH,2
        INT     21H
        POP     AX
        POP     DX
        RET
        end if


        IF      SYSVER
RBUFIN:
        PUSH    AX
        PUSH    ES
        PUSH    DI
        PUSH    CS
        POP     ES
        MOV     byte [LBUFFCNT],0
        MOV     DI,LINEBUF
FILLBUF:
        CALL    IN_
        CMP     AL,0DH
        JZ      BDONE
        CMP     AL,8
        JZ      ECHR
        CMP     AL,7FH
        JZ      ECHR
        CMP     byte [LBUFFCNT],BUFLEN
        JAE     BFULL
        STOSB
        INC     byte [LBUFFCNT]
        JMP     SHORT FILLBUF

BDONE:
        STOSB
        POP     DI
        POP     ES
        POP     AX
        RET

BFULL:
        MOV     AL,8
        CALL    OUT_
        MOV     AL,7
        CALL    OUT_
        JMP     SHORT FILLBUF

ECHR:
        CMP     DI,LINEBUF
        JZ      FILLBUF
        DEC     DI
        DEC     byte [LBUFFCNT]
        JMP     SHORT FILLBUF
        ELSE

RBUFIN:
        PUSH    AX
        PUSH    DX
        MOV     AH,10
        MOV     DX,LBUFSIZ
        INT     21H
        POP     DX
        POP     AX
        RET
        end if


        IF      SYSVER
RPRBUF:
        PUSHF
        PUSH    AX
        PUSH    SI
        MOV     SI,DX
PLOOP:
        LODSB
        CMP     AL,"$"
        JZ      PRTDONE
        CALL    OUT_
        JMP     SHORT PLOOP
PRTDONE:
        POP     SI
        POP     AX
        POPF
        RET
        ELSE

RPRBUF:
        MOV     AH,9
        INT     21H
        RET
        end if

; Output one space

BLANK:
        MOV     AL," "
        JMP     OUT_

; Output the number of blanks in CX

TAB:
        CALL    BLANK
        LOOP    TAB
        RET

; Command Table. Command letter indexes into table to get
; address of command. PERR prints error for no such command.

COMTAB  DW      ASSEM                   ; A
        DW      PERR                    ; B
        DW      COMPARE                 ; C
        DW      DUMP                    ; D
        DW      ENTER_                   ; E
        DW      FILL                    ; F
        DW      GO                      ; G
        DW      HEXADD                  ; H
        DW      INPUT                   ; I
        DW      PERR                    ; J
        DW      PERR                    ; K
        DW      LOAD_                    ; L
        DW      MOVE                    ; M
        DW      NAME                    ; N
        DW      OUTPUT                  ; O
        IF      ZIBO
        DW      ZTRACE
        ELSE
        DW      PERR                    ; P
        end if
        DW      QUIT                    ; Q (QUIT)
        DW      REG                     ; R
        DW      SEARCH                  ; S
        DW      TRACE                   ; T
        DW      UNASSEM                 ; U
        DW      PERR                    ; V
        DW      DWRITE                  ; W
        IF      SYSVER
        DW      SETUDEV                 ; X
        ELSE
        DW      PERR
        end if
        DW      PERR                    ; Y
        DW      PERR                    ; Z

QUIT:
        INC     byte [QFLAG]
        MOV     BX,[USER_PROC_PDB]
FIND_DEBUG:
IF  NOT SYSVER
        MOV     AH,SET_CURRENT_PDB
        INT     21H
end if
        CALL    ReleaseParity           ; let system do normal parity stuff
        MOV     AX,(EXIT SHL 8)
        INT     21H

end if
