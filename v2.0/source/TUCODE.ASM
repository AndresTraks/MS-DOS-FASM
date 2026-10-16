




if SEGSEL = S_DATARES
end if


if SEGSEL = S_TRANDATA
end if


if SEGSEL = S_TRANSPACE
end if


if SEGSEL = S_TRANCODE


        IF      KANJI
        END IF

ASSUME  CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

;***************************************
; ARE YOU SURE prompt when deleting *.*

NOTEST2:
        MOV     CX,11
        MOV     SI,FCB+1
AMBSPEC:
        LODSB
        CMP     AL,"?"
        JNZ     ALLFIL
        LOOP    AMBSPEC
ALLFIL:
        CMP     CX,0
        JNZ     NOPRMPT
ASKAGN:
        MOV     DX,SUREMES ; "Are you sure (Y/N)?"
        CALL    PRINT
        MOV     SI,80H
        MOV     DX,SI
        MOV     word [SI],120       ; zero length
        MOV     AX,(Std_Con_Input_Flush SHL 8) OR Std_Con_String_Input
        INT     int_command
        LODSW
        OR      AH,AH
        JZ      ASKAGN
        CALL    SCANOFF
        OR      AL,20H                  ; Convert to lower case
        CMP     AL,'n'
        JZ      RETERA
        CMP     AL,'y'
        PUSHF
        CALL    CRLF2
        POPF
        JNZ     ASKAGN
NOPRMPT:
        MOV     AH,FCB_Delete
        MOV     DX,FCB
        INT     int_command
        PUSH    AX
        CALL    RESTUDIR
        POP     AX
        MOV     DX,NOTFND
        INC     AL
        JZ      CERRORJ
RETERA:
        RET


;************************************************
; ECHO, BREAK, and VERIFY commands. Check for "ON" and "OFF"

ECHO:
ASSUME  DS:TRANGROUP,ES:TRANGROUP
        CALL    ON_OFF
        JC      DOEMES
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        JNZ     ECH_OFF
        MOV     [ECHOFLAG],1
        RET
ECH_OFF:
        MOV     [ECHOFLAG],0
        RET

ASSUME  DS:TRANGROUP
DOEMES:
        MOV     AL,byte [DS:80H]
        CMP     AL,2
        JB      PECHO                   ; Gota have at least 2 characters
        MOV     DX,82H                  ; Skip one char after "ECHO"
        CALL    CRPRINT
        JMP     CRLF2

PECHO:
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        MOV     BL,[ECHOFLAG]
        PUSH    CS
        POP     DS
ASSUME  DS:TRANGROUP
        MOV     DX,ECHOMES
        JMP     SHORT PYN


CERRORJ:
        JMP     CERROR

; is rest of line blank?
IsBlank:
        MOV     SI,81h                  ; point at text spot
        CALL    SCANOFF                 ; skip separators
        SUB     SI,81h                  ; number of characters advanced
        MOV     CX,SI                   ; put count in byte addressable spot
        CMP     CL,[DS:80h]             ; compare with count
        return                          ; bye!

;The BREAK command
CNTRLC:
        CALL    ON_OFF
        MOV     AX,(Set_CTRL_C_Trapping SHL 8) OR 1
        JC      PCNTRLC
        JNZ     CNTRLC_OFF
        MOV     DL,1
        INT     int_command             ; Set ^C
        RET
CNTRLC_OFF:
        XOR     DL,DL
        INT     int_command             ; Turn off ^C check
        RET

PCNTRLC:
        CALL    IsBlank                 ; rest of line blank?
        JNZ     CERRORJ                 ; no, oops!
        XOR     AL,AL
        INT     int_command
        MOV     BL,DL
        MOV     DX,CTRLCMES
PYN:
        CALL    PRINT
        MOV     DX,ONMES
        OR      BL,BL
        JNZ     PRINTVAL
        MOV     DX,OFFMES
PRINTVAL:
        JMP     PRINT

VERIFY:
        CALL    ON_OFF
        MOV     AX,(Set_Verify_On_Write SHL 8) OR 1
        JC      PVERIFY
        JNZ     VER_OFF
        INT     int_command             ; Set verify
        RET
VER_OFF:
        DEC     AL
        INT     int_command             ; Turn off verify after write
        RET

PVERIFY:
        CALL    IsBlank                 ; is rest of line blank?
        JNZ     CERRORJ                 ; nope...
        MOV     AH,Get_Verify_On_Write
        INT     int_command
        MOV     BL,AL
        MOV     DX,VERIMES
        JMP     PYN

ON_OFF:
        MOV     SI,FCB+1
        LODSB
        OR      AL,20H
        CMP     AL,'o'
        JNZ     BADONF
        LODSW
        OR      AX,2020H                ; Convert to lower case
        CMP     AL,'n'
        JNZ     OFFCHK
        CMP     AH,' '                  ; ' ' ORed with 20H is still ' '
        JNZ     BADONF
        RET                             ; Carry clear from CMP
OFFCHK:
        CMP     AX,6666H                ; 'ff'
        JNZ     BADONF
        LODSB
        CMP     AL,' '
        JNZ     BADONF
        INC     AL                      ; Reset zero Carry clear from CMP
        RET
BADONF:
        MOV     DX,BAD_ON_OFF
        STC
        RET

;********************************
; Print volume ID info

ASSUME  DS:TRANGROUP,ES:TRANGROUP

PRINTVOL:
        PUSH    AX                      ; AX return from SEARCH_FIRST for VOL ID
        MOV     DX,VOLMES
        CALL    PRINT
        MOV     AL,[DS:FCB]
        ADD     AL,'@'
        CMP     AL,'@'
        JNZ     DRVOK
        MOV     AL,[CURDRV]
        ADD     AL,'A'
DRVOK:
        CALL    OUT_
        POP     AX
        OR      AL,AL
        JZ      GOODVOL
        MOV     DX,NOVOL
        CALL    PRINT
        JMP     CRLF2
GOODVOL:
        MOV     DX,GOTVOL
        CALL    PRINT
        MOV     SI,DIRBUF + 8
        MOV     CX,11
        MOV     DI,CHARBUF
        MOV     DX,DI
        REP     MOVSB
        MOV     AX,0A0DH
        STOSW
        XOR     AX,AX
        STOSB
        JMP     ZPRINT

;*************************************************************************
; print date
PRINT_DATE:
        PUSH    ES
        PUSH    DI
        PUSH    CS
        POP     ES
        MOV     DI,CHARBUF
        MOV     AH,Get_Date
        INT     int_command             ; Get date in CX:DX
        CBW
        CALL    GetDate                 ; get date and put into DI
        MOV     AL," "
        STOSB
        MOV     SI,CURDAT_MID
        CALL    MESTRAN
        CALL    P_DATE
        XOR     AX,AX
        STOSB
        MOV     DX,CHARBUF
        CALL    ZPRINT
        POP     ES
        POP     DI
        return

GetDate:
        MOV     SI,AX
        SHL     SI,1
        ADD     SI,AX           ; SI=AX*3
        ADD     SI,WEEKTAB
        MOV     BX,CX
        MOV     CX,3
        REP     MOVSB
        return

end if
