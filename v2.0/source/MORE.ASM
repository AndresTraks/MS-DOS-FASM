FALSE   =     0
TRUE    =     -1

IBMVER  =     TRUE
KANJI   =	FALSE
MSVER   =     FALSE

        INCLUDE 'DOSSYM.ASM'

        ORG     100H
ASSUME  CS:CODE,DS:CODE,ES:CODE,SS:CODE
START:

        MOV     AH,GET_VERSION
        INT     21H
        XCHG    AH,AL                   ; Turn it around to AH.AL
        CMP     AX,200H
        JAE     OKDOS
        MOV     DX,BADVER
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        INT     20H
OKDOS:

        IF      IBMVER
        IF      KANJI
        MOV     byte [MAXROW],24
        ELSE
        MOV     byte [MAXROW],25
        end if
        MOV     AH,15
        INT     10H             ; 16 decimal, MASM's default radix
        MOV     [MAXCOL],AH
        end if

        MOV     DX,CRLFTXT       ; INITIALIZE CURSOR
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H

        XOR     BX,BX                   ; DUP FILE HANDLE 0
        MOV     AH,XDUP
        INT     21H
        MOV     BP,AX

        MOV     AH,CLOSE                ; CLOSE STANDARD IN
        INT     21H

        MOV     BX,2                    ; DUP STD ERR TO STANDARD IN
        MOV     AH,XDUP
        INT     21H

ALOOP:
        CLD
        MOV     DX,BUFFER
        MOV     CX,4096
        MOV     BX,BP
        MOV     AH,READ
        INT     21H
        OR      AX,AX
        JNZ     SETCX
DONE:   INT     20H
SETCX:  MOV     CX,AX
        MOV     SI,DX

TLOOP:
        LODSB
        CMP     AL,1AH
        JZ      DONE
        CMP     AL,13
        JNZ     NOTCR
        MOV     byte [CURCOL],1
        JMP     SHORT ISCNTRL

NOTCR:  CMP     AL,10
        JNZ     NOTLF
        INC     byte [CURROW]
        JMP     SHORT ISCNTRL

NOTLF:  CMP     AL,8
        JNZ     NOTBP
        CMP     byte [CURCOL],1
        JZ      ISCNTRL
        DEC     byte [CURCOL]
        JMP     SHORT ISCNTRL

NOTBP:  CMP     AL,9
        JNZ     NOTTB
        MOV     AH,[CURCOL]
        ADD     AH,7
        AND     AH,11111000B
        INC     AH
        MOV     [CURCOL],AH
        JMP     SHORT ISCNTRL

NOTTB:
        IF      MSVER                   ; IBM CONTROL CHARACTER PRINT
        CMP     AL,' '
        JB      ISCNTRL
        end if

        IF      IBMVER
        CMP     AL,7                    ; ALL CHARACTERS PRINT BUT BELL
        JZ      ISCNTRL
        end if

        INC     byte [CURCOL]
        MOV     AH,[CURCOL]
        CMP     AH,[MAXCOL]
        JBE     ISCNTRL
        INC     byte [CURROW]
        MOV     byte [CURCOL],1

ISCNTRL:
        MOV     DL,AL
        MOV     AH,STD_CON_OUTPUT
        INT     21H
        MOV     AH,[CURROW]
        CMP     AH,[MAXROW]
        JB      CHARLOOP

ASKMORE:
        MOV     DX,MORETXT
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H                     ; ASK MORE?

        MOV     AH,STD_CON_INPUT_FLUSH  ; WAIT FOR A KEY, NO ECHO
        MOV     AL,STD_CON_INPUT
        INT     21H

        MOV     DX,CRLFTXT
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H

        MOV     byte [CURCOL],1
        MOV     byte [CURROW],1

CHARLOOP:
        DEC     CX
        JZ      GOBIG
        JMP     TLOOP
GOBIG:  JMP     ALOOP

MAXROW  DB      24
MAXCOL  DB      80
CURROW  DB      1
CURCOL  DB      1

