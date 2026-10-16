;
; Standard device IO for MSDOS -- system calls 1 through 12
;

;TITLE   DOSIO - device IO for MSDOS

; The MS-DOS 2.0 source release does not contain this module.  STDIO.ASM
; says INCLUDE IO.ASM and IO.ASM is simply absent from the tree, so the
; conversion had the twelve character calls stubbed out with a bare RET and
; the system could never print anything.
;
; What follows is rebuilt from the I/O code in v1.25/source/MSDOS.ASM, which
; is this module's direct ancestor, expressed with the primitives v2.0 keeps
; elsewhere: GET_IO_FCB, IOFUNC and RAWOUT2 in place of calls through the
; v1.25 BIOS jump table, and the handles SYSINIT opens -- 0 and 1 for the
; console, 3 for AUX, 4 for PRN -- in place of fixed devices.  STATCHK,
; INCHK and the ^C handler, which v1.25 kept here, live in CTRLC.ASM in
; v2.0 and are called rather than repeated.  STRIN.ASM holds call 10 and
; MISC.ASM calls 6 and 7, as the v2.0 link map has them.
;
; The file is DOSIO.ASM rather than IO.ASM because IO.ASM in this directory
; is the BIOS.

; GET_IO_FCB and the routines reached through it return in DS:SI and leave
; the rest of the world alone, so a caller that has its own pointers live --
; OUTMES walking a message with DS:SI, STRIN editing a line with ES:DI --
; needs them put back.
macro iopush
{
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    BP
        PUSH    SI
        PUSH    DI
        PUSH    DS
        PUSH    ES
}

; POP leaves the flags alone, so a status call may test after restoring.
macro iopop
{
        POP     ES
        POP     DS
        POP     DI
        POP     SI
        POP     BP
        POP     DX
        POP     CX
        POP     BX
}

ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP

;BREAK <_STD_CON_OUTPUT, _OUT, TAB -- console output>

        procedure   _STD_CON_OUTPUT,NEAR    ; System call 2

; Inputs:
;       DL = character
; Function:
;       Send the character to standard output
; Returns:
;       None

        MOV     AL,DL
    entry   _OUT

; Inputs:
;       AL = character
; Function:
;       Send the character to standard output, expanding tabs, keeping
;       CARPOS in step and echoing to the printer while PFLAG is set
; Returns:
;       AL is the character, everything else preserved

        CMP     AL,20H
        JB      CTRLOUT
        CMP     AL,7FH
        JZ      OUTCH
        INC     BYTE [SS:CARPOS]
OUTCH:
        iopush
        PUSH    AX
        invoke  STATCHK                 ; catch ^S, ^P and ^C between
        POP     AX                      ;  characters, as v1.25 did
        PUSH    AX
        MOV     BX,1                    ; standard output
        invoke  RAWOUT2
        POP     AX
        TEST    BYTE [SS:PFLAG],-1
        JZ      OUTCHDN
        MOV     BX,4                    ; the printer, echoed after ^P
        invoke  RAWOUT2
OUTCHDN:
        iopop
        return

CTRLOUT:
        CMP     AL,13
        JZ      ZERPOS
        CMP     AL,8
        JZ      BACKPOS
        CMP     AL,9
        JNZ     OUTCH
        MOV     AL,[SS:CARPOS]
        OR      AL,0F8H
        NEG     AL                      ; spaces to the next eight-column stop
    entry   TAB

; Inputs:
;       AL = number of spaces
; Function:
;       Send that many spaces to standard output
; Returns:
;       None

        PUSH    CX
        MOV     CL,AL
        XOR     CH,CH
        JCXZ    POPTAB
TABLP:
        MOV     AL," "
        invoke  _OUT
        LOOP    TABLP
POPTAB:
        POP     CX
        return

ZERPOS:
        MOV     BYTE [SS:CARPOS],0
        JMP     OUTCH

BACKPOS:
        DEC     BYTE [SS:CARPOS]
        JMP     OUTCH

;BREAK <BUFOUT -- console output with control characters shown>

        procedure   BUFOUT,NEAR

; Inputs:
;       AL = character
; Function:
;       As _OUT, but print a control character as ^ and a letter
; Returns:
;       None

        CMP     AL," "
        JAE     BUFOUTJ
        CMP     AL,9
        JZ      BUFOUTJ
        PUSH    AX
        MOV     AL,"^"
        invoke  _OUT
        POP     AX
        OR      AL,40H
BUFOUTJ:
        transfer    _OUT

;BREAK <_STD_CON_INPUT -- console input with echo>

        procedure   _STD_CON_INPUT,NEAR     ; System call 1

; Inputs:
;       None
; Function:
;       Wait for a character from standard input and echo it
; Returns:
;       AL = character

        invoke  _STD_CON_INPUT_NO_ECHO
        PUSH    AX
        invoke  _OUT
        POP     AX
        return

;BREAK <_STD_CON_INPUT_NO_ECHO -- console input without echo>

        procedure   _STD_CON_INPUT_NO_ECHO,NEAR ; System call 8

; Inputs:
;       None
; Function:
;       Wait for a character from standard input without echoing it.
;       INCHK swallows ^P and ^N and takes ^C to the handler, and returns
;       zero when it has eaten the character rather than passing it on.
; Returns:
;       AL = character

CONINLP:
        iopush
        invoke  SPOOLINT
        invoke  INCHK
        iopop
        JZ      CONINLP
        return

;BREAK <_STD_CON_INPUT_STATUS -- is a character waiting?>

        procedure   _STD_CON_INPUT_STATUS,NEAR  ; System call 11

; Inputs:
;       None
; Function:
;       Report whether standard input has a character ready
; Returns:
;       AL = -1 if so, 0 if not

        iopush
        invoke  STATCHK
        iopop
        MOV     AL,0
        JZ      STATRET
        MOV     AL,-1
STATRET:
        return

;BREAK <_STD_CON_INPUT_FLUSH -- discard pending input, then another call>

        procedure   _STD_CON_INPUT_FLUSH,NEAR   ; System call 12

; Inputs:
;       AL = system call to perform once the input is thrown away
; Function:
;       Flush standard input, then make that call if it is one of the five
;       that read the console
; Returns:
;       Whatever the second call returns, or AL = 0 if there was none

        PUSH    AX
        iopush
        XOR     BX,BX
        invoke  GET_IO_FCB
        JC      FLUSHED
        MOV     AH,4                    ; flush
        invoke  IOFUNC
FLUSHED:
        iopop
        POP     AX
        MOV     AH,AL
        CMP     AL,1
        JZ      REDISPJ
        CMP     AL,6
        JZ      REDISPJ
        CMP     AL,7
        JZ      REDISPJ
        CMP     AL,8
        JZ      REDISPJ
        CMP     AL,10
        JZ      REDISPJ
        MOV     AL,0
        return

REDISPJ:
        transfer    REDISP

;BREAK <_STD_CON_STRING_OUTPUT -- print a $ terminated string>

        procedure   _STD_CON_STRING_OUTPUT,NEAR ; System call 9

; Inputs:
;       DS:DX points to a string ending in "$"
; Function:
;       Send it to standard output
; Returns:
;       None

        MOV     SI,DX
OUTSTR:
        LODSB
        CMP     AL,"$"
        JZ      OUTSTRX
        invoke  _OUT
        JMP     OUTSTR
OUTSTRX:
        return

;BREAK <_STD_AUX_INPUT, _STD_AUX_OUTPUT, _STD_PRINTER_OUTPUT>

        procedure   _STD_AUX_INPUT,NEAR     ; System call 3

; Inputs:
;       None
; Function:
;       Wait for a character from AUX
; Returns:
;       AL = character

        iopush
        invoke  STATCHK
        MOV     BX,3                    ; the AUX handle SYSINIT opened
        invoke  GET_IO_FCB
        JC      AUXINX
        XOR     AH,AH
        invoke  IOFUNC
AUXINX:
        iopop
        return

        procedure   _STD_AUX_OUTPUT,NEAR    ; System call 4

; Inputs:
;       DL = character
; Function:
;       Send the character to AUX
; Returns:
;       None

        MOV     AL,DL
        iopush
        PUSH    AX
        invoke  STATCHK
        POP     AX
        MOV     BX,3
        invoke  RAWOUT2
        iopop
        return

        procedure   _STD_PRINTER_OUTPUT,NEAR ; System call 5

; Inputs:
;       DL = character
; Function:
;       Send the character to PRN
; Returns:
;       None

        MOV     AL,DL
        iopush
        PUSH    AX
        invoke  STATCHK
        POP     AX
        MOV     BX,4                    ; the PRN handle SYSINIT opened
        invoke  RAWOUT2
        iopop
        return

        INCLUDE 'STRIN.ASM'
