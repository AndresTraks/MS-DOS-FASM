




if SEGSEL = S_DATARES
end if



if SEGSEL = S_CODERES



ASSUME  CS:RESGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;********************************************
; TERMINATE BATCH JOB PROMPTER

ASSUME  DS:RESGROUP
ASKEND:
        CALL    SAVHAND
ASKEND2:
        MOV     DX,ENDBATMES
        CALL    RPRINT
        MOV     AX,(Std_Con_Input_Flush SHL 8)+Std_Con_Input
        INT     int_command
        AND     AL,5FH
        CMP     AL,"N"
        JZ      RESTHJ
        CMP     AL,"Y"
        JNZ     ASKEND2
        MOV     ES,[BATCH]
        MOV     AH,Dealloc
        INT     int_command
        MOV     [BATCH],0               ; Flag no batch AFTER DEALLOC in case
                                        ;   of ^C
        MOV     [ECHOFLAG],1            ; Make sure ECHO turned back on
RESTHJ:
        CALL    RESTHAND
        JMP     CONTCTERM



DSKERR:
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        ; ******************************************************
        ;       THIS IS THE DEFAULT DISK ERROR HANDLING CODE
        ;       AVAILABLE TO ALL USERS IF THEY DO NOT TRY TO
        ;       INTERCEPT INTERRUPT 24H.
        ; ******************************************************
        STI
        PUSH    DS
        PUSH    ES
        PUSH    DI
        PUSH    CX
        PUSH    AX
        MOV     DS,BP
        MOV     AX,[SI+SYSDEV.SDEVATT]
        MOV     [CS:CDEVAT],AH
        PUSH    CS
        POP     ES
        MOV     DI,DEVENAM
        MOV     CX,8
        ADD     SI,SYSDEV.SDEVNAME             ; Suck up device name (even on Block)
        REP     MOVSB
        POP     AX
        POP     CX
        POP     DI
        POP     ES                      ; Stack just contains DS at this point
        CALL    SAVHAND
        PUSH    CS
        POP     DS              ; Set up local data segment
ASSUME  DS:RESGROUP

        PUSH    DX
        CALL    CRLF
        POP     DX

        ADD     AL,"A"          ; Compute drive letter (even on character)
        MOV     [DRVLET],AL
        TEST    AH,80H          ; Check if hard disk error
        JZ      NOHARDE
        TEST    [CDEVAT],DEVTYP SHR 8
        JNZ     NOHARDE
        JMP     FATERR
NOHARDE:
        MOV     SI,MREAD
        TEST    AH,1
        JZ      SAVMES
        MOV     SI,MWRITE
SAVMES:
        LODSW
        MOV     word [IOTYP],AX
        LODSW
        MOV     word [IOTYP+2],AX
        AND     DI,0FFH
        CMP     DI,12
        JBE     HAVCOD
        MOV     DI,12
HAVCOD:
        MOV     [ERRCD_24],DI
        SHL     DI,1
        MOV     DI,word [DI+MESBAS] ; Get pointer to error message
        XCHG    DI,DX           ; May need DX later
        CALL    RPRINT          ; Print error type
        MOV     DX,ERRMES
        CALL    RPRINT
        TEST    [CDEVAT],DEVTYP SHR 8
        JZ      BLKERR
        MOV     DX,DEVEMES
        MOV     AH,Std_Con_String_Output
        INT     int_command
        JMP     SHORT ASK       ; Don't ralph on COMMAND

BLKERR:
        MOV     DX,DRVNUM
        CALL    RPRINT
        CMP     [LOADING],0
        JZ      ASK
        CALL    RESTHAND
        JMP     GETCOMDSK2      ; If error loading COMMAND, re-prompt
ASK:
        MOV     DX,REQUEST
        CALL    RPRINT
        MOV     AX,(Std_Con_Input_Flush SHL 8)+Std_Con_Input
        INT     int_command             ; Get response
        CALL    CRLF
        OR      AL,20H          ; Convert to lower case
        MOV     AH,0            ; Return code for ignore
        CMP     AL,"i"          ; Ignore?
        JZ      EEXIT
        INC     AH
        CMP     AL,"r"          ; Retry?
        JZ      EEXIT
        INC     AH
        CMP     AL,"a"          ; Abort?
        JNZ     ASK
        XOR     DX,DX
        XCHG    DL,[PIPEFLAG]   ; Abort a pipe in progress
        OR      DL,DL
        JZ      CHECKFORA
        CMP     [SINGLECOM],0
        JZ      CHECKFORA
        MOV     [SINGLECOM],-1   ; Make sure SINGLECOM exits
CHECKFORA:
        CMP     [ERRCD_24],0    ; Write protect
        JZ      ABORTFOR
        CMP     [ERRCD_24],2    ; Drive not ready
        JNZ     EEXIT           ; Don't abort the FOR
ABORTFOR:
        MOV     [FORFLAG],0     ; Abort a FOR in progress
        CMP     [SINGLECOM],0
        JZ      EEXIT
        MOV     [SINGLECOM],-1   ; Make sure SINGLECOM exits
EEXIT:
        MOV     AL,AH
        MOV     DX,DI
RESTHD:
        CALL    RESTHAND
        POP     DS
        IRET

FATERR:
        MOV     DX,BADFAT
        CALL    RPRINT
        MOV     DX,ERRMES
        CALL    RPRINT
        MOV     DX,DRVNUM
        CALL    RPRINT
        MOV     AL,2            ; Abort
        JMP     RESTHD


;*********************************************
; Print routines for Tokenized resident messages

ASSUME DS:RESGROUP,SS:RESGROUP

CRLF:
        MOV     DX,NEWLIN

RPRINT:
        PUSH    AX              ; Tokenized message printer
        PUSH    BX
        PUSH    DX
        PUSH    SI
        MOV     SI,DX
RPRINT1:
        LODSB
        PUSH    AX
        AND     AL,7FH
        CMP     AL,"0"
        JB      RPRINT2
        CMP     AL,"9"
        JA      RPRINT2
        SUB     AL,"0"
        CBW
        SHL     AX,1
        MOV     BX,MESADD
        ADD     BX,AX
        MOV     DX,[BX]
        CALL    RPRINT
        JMP     SHORT RPRINT3
RPRINT2:
        MOV     DL,AL
        MOV     AH,Std_Con_Output
        INT     int_command
RPRINT3:
        POP     AX
        TEST    AL,10000000B                    ; High bit set indicates end
        JZ      RPRINT1
        POP     SI
        POP     DX
        POP     BX
        POP     AX
        RET

end if
