	PAGE	80,132 ;
	TITLE	DEBERR.ASM - DEBUGGER DISK ERROR HANDLER

;******************* START OF SPECIFICATIONS *****************************
;
; MODULE NAME:DEBERR.SAL
;
; DESCRIPTIVE NAME: DISK ERROR HANDLER
;
; FUNCTION: THIS ROUTINE IS A CATCHALL ERROR HANDLER.  IT PRIMARILY
;	    HANDLES DISK ERROR.
;
; ENTRY POINT: ANY CALLED ROUTINE
;
; INPUT: NA
;
; EXIT-NORMAL: NA
;
; EXIT-ERROR: NA
;
; INTERNAL REFERENCES:
;
;
; EXTERNAL REFERENCES:
;
; NOTES: THIS MODULE SHOULD BE PROCESSED WITH THE SALUT PRE-PROCESSOR
;	 WITH OPTIONS "PR".
;	 LINK DEBUG+DEBCOM1+DEBCOM2+DEBCOM3+DEBASM+DEBUASM+DEBERR+DEBCONST+
;	      DEBDATA+DEBMES
;
; REVISION HISTORY:
;
;	AN000	VERSION DOS 4.0 - MESSAGE RETRIEVER IMPLEMENTED.  DMS:6/17/87
;
;
; COPYRIGHT: "MS DOS DEBUG Utility"
;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Property of Microsoft  "
;
;******************** END OF SPECIFICATIONS ******************************


;	IF1
;	    %OUT COMPONENT=DEBUG, MODULE=DEBERR
;	ENDIF
.XLIST
.XCREF
	include 'DOSSYM.INC'
.CREF
.LIST

	include 'DEBEQU.ASM'

FIRSTDRV EQU	"A"

if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
;	EXTRN	RDFLG:BYTE
;	EXTRN	DRVLET:BYTE
;	EXTRN	dr1_ptr:word,dr2_ptr:word,dr3_ptr:word,dr4_ptr:word ;ac000
end if

if SEGSEL = S_CSTACK
end if

if SEGSEL = S_DATA
;	EXTRN	PARITYFLAG:BYTE
end if

;DG	GROUP	CODE,CONST,CSTACK,DATA

if SEGSEL = S_CODE
;	ASSUME	CS:DG,DS:DG,ES:DG,SS:DG

;	EXTRN	RESTART:NEAR
;	PUBLIC	DRVERR, TRAPPARITY, RELEASEPARITY, NMIINT, NMIINTEND

TRAPPARITY:
	IF	IBMJAPAN
	    PUSH    BX
	    PUSH    ES
	    PUSH    DX			; save location of new offset
	    MOV     DX,NMIInt        ; DS:DX has new interrupt vector
	    CALL    SWAPINT		; diddle interrupts
;	    ASSUME  ES:NOTHING

	    MOV     word [NMIPTR],BX     ; save old offset
	    MOV     word [NMIPTR+2],ES     ; save old segment
	    POP     DX			; get old regs back
	    POP     ES			; restore old values
;	    ASSUME  ES:DG

	    POP     BX
	    MOV     byte [PARITYFLAG],0     ; no interrupts detected yet!
	    RET

SWAPINT:
	    PUSH    AX
	    MOV     AX,(Get_Interrupt_Vector SHL 8) + 2
	    INT     21H 		; Get old NMI Vector
	    MOV     AX,(Set_Interrupt_Vector SHL 8) + 2
	    INT     21h 		; let OS set new vector
	    POP     AX
	end if
	RET

RELEASEPARITY:
	IF	IBMJAPAN
	    PUSH    DX
	    PUSH    DS
	    PUSH    BX
	    PUSH    ES
	    LDS     DX,dword [NMIPTR]     ; get old vector
	    CALL    SWAPINT		; diddle back to original
	    POP     ES
	    POP     BX
	    POP     DS
	    POP     DX
	    MOV     byte [PARITYFLAG],0 ; no interrupts possible!
	end if
	RET

NMIInt:
	IF	IBMJAPAN
	    PUSH    AX			; save AX
	    IN	    AL,0A0H		; get status register
	    OR	    AL,1		; was there parity check?
	    POP     AX			; get old AX back
	    JZ	    NMICHAIN		; no, go chain interrupt
	    OUT     0A2H,AL		; reset NMI detector
	    MOV     byte [cs:PARITYFLAG],1 ; signal detection
	    IRET
NMICHAIN:
	    JMP     dword [cs:NMIPTR]     ; chain the vectors
NMIPTR	    rd      1  ; where old NMI gets stashed
	end if
NMIINTEND:

DRVERR:

	or	al,al				;ac000;see if drive specified
;	if$	nz				;an000;drive specified
	JZ IF1$$E
		add	byte [drvlet],FIRSTDRV  ;ac000;determine drive letter
		cmp	byte [RDFLG],Write   ;ac000;see if it is read/write
;		if$	z			;an000;it is write
		JNZ IF2$$E
			mov	dx,dr2_ptr        ;an000;message
;		else$				;an000;it is read
		JMP SHORT EN2$$E
IF2$$E:
			mov	dx,dr1_ptr        ;an000;message
;		endif$				;an000;
EN2$$E:
;	else$					;an000;write protect error
	JMP SHORT EN1$$E
IF1$$E:
		add	byte [drvlet],FIRSTDRV  ;ac000;determine drive letter
		cmp	byte [RDFLG],Write   ;ac000;see if it is read/write
;		if$	z			;an000;it is write
		JNZ IF6$$E
			mov	dx,dr4_ptr        ;an000;message
;		else$				;an000;it is read
		JMP SHORT EN6$$E
IF6$$E:
			mov	dx,dr3_ptr        ;an000;message
;		endif$				;an000;
EN6$$E:
;	endif$					;an000;
EN1$$E:

; CLEAN OUT THE DISK...
	MOV	AH,Disk_Reset
	INT	21H

	JMP	RESTART
CODEEND:

end if
;	END
