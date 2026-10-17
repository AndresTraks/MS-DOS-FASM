
FALSE   =     0
TRUE    =     -1

IBMVER  =     FALSE


        ASSUME  CS:CODE,DS:CODE,ES:CODE


        ;Wait for "Y" or "N"
WAITYN:
        MOV     DX,MORMSG        ;Point to the message
        CALL    PRINT                   ;And print it
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8) OR STD_CON_INPUT
                                        ;Flush buffer and wait for keystroke
        INT     21H                     ;Input character now a Y or N
        AND     AL,0DFH                 ;So lower case works too
        CMP     AL,"Y"
        JZ      WAIT20
        CMP     AL,"N"
        JZ      WAIT10
        CALL    CRLF
        JMP     SHORT WAITYN
WAIT10: STC
WAIT20: RET


;*********************************************
; Make a status report including the following information:
; Total disk capacity
; Total system area used
; Total bad space allocated
; Total data space available
;NOTE:
;       The DISP32BITS routine prints the number in DI:SI followed
;          by the message pointed to by BX. If it is desired to print
;          a message before the number, point at the message with DX
;          and call PRINT.

REPORT:
        MOV     AX,word [FDSKSIZ]
        MUL     [SECSIZ]
        MOV     CX,[CLUSSIZ]
        CALL    UNSCALE
        MOV     word [FDSKSIZ],AX
        MOV     word [FDSKSIZ+2],DX
        MOV     SI,AX
        MOV     DI,DX
        MOV     BX,DSKSPC
        CALL    DISP32BITS              ;Report total disk space
        MOV     SI,word [SYSSIZ]
        MOV     DI,word [SYSSIZ+2]
        CMP     SI,0
        JNZ     SHOWSYS
        CMP     DI,0
        JZ      CHKBAD
SHOWSYS:
        MOV     BX,SYSSPC
        CALL    DISP32BITS              ;Report space used by system
CHKBAD:
        MOV     SI,word [BADSIZ]
        MOV     DI,word [BADSIZ+2]
        CMP     SI,0
        JNZ     SHOWBAD
        CMP     DI,0
        JZ      SHOWDATA
SHOWBAD:
        MOV     BX,BADSPC
        CALL    DISP32BITS              ;Report space used by bad sectors
SHOWDATA:
        MOV     CX,word [FDSKSIZ]
        MOV     BX,word [FDSKSIZ+2]
        SUB     CX,word [BADSIZ]
        SBB     BX,word [BADSIZ+2]
        SUB     CX,word [SYSSIZ]
        SBB     BX,word [SYSSIZ+2]
        MOV     SI,CX
        MOV     DI,BX
        MOV     BX,DATASPC
        CALL    DISP32BITS              ;Report space left for user
        RET


BADVER  DB      "Incorrect DOS version",13,10,"$"
SNGMSG  DB      "Insert new diskette for drive "
SNGDRV  DB      "x:",13,10,"and strike any key when ready$"
HRDMSG  DB      "Press any key to begin formatting "
HRDDRV  DB      "x: $"
SYSTRAN DB      "System transferred",13,10,"$"
MORMSG  DB      "Format another (Y/N)?$"
CRLFMSG DB      13,10,"$"
INVCHR  DB      "Invalid characters in volume label",13,10,"$"
INVDRV  DB      "Invalid drive specification$"
INVPAR  DB      "Invalid parameter$"
TARGMSG DB      "Re-insert diskette for drive "
TARGDRV DB      "x:",13,10,"and strike any key when ready$"
SYSMSG  DB      "Insert DOS disk in drive "
SYSDRV  DB      "x:",13,10,"and strike any key when ready$"
FRMTERR DB      "Format failure",13,10,13,10,"$"
NOTSYS  DB      "Disk unsuitable for system disk",13,10,"$"
NOUSE   DB      "Track 0 bad - disk unusable",13,10,"$"
MEMEX   DB      "Insufficient memory for system transfer",13,10,"$"

;Report messages
DSKSPC  DB      " bytes total disk space",13,10,"$"
SYSSPC  DB      " bytes used by system",13,10,"$"
BADSPC  DB      " bytes in bad sectors",13,10,"$"
DATASPC DB      " bytes available on disk",13,10,13,10,"$"

        IF      IBMVER
ASGERR  DB      "Cannot format an ASSIGNed drive. $"
        end if

LABPRMT DB      "Volume label (11 characters, ENTER for none)? $"


