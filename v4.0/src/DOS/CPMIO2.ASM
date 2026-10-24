;	SCCSID = @(#)cpmio2.asm 1.1 85/04/11
TITLE	CPMIO2 - device IO for MSDOS
NAME	CPMIO2

;.xlist
;.xcref
INCLUDE '../INC/DOSSEG.ASM'
;.cref
;.list

;
; Old style CP/M 1-12 system calls to talk to reserved devices
;
;   $Std_Con_Input
;   $Std_Con_Output
;   OUTT
;   TAB
;   BUFOUT
;   $Std_Aux_Input
;   $Std_Aux_Output
;   $Std_Printer_Output
;   $Std_Con_Input_Status
;   $Std_Con_Input_Flush
;
;   Revision History:
;
;	AN000	 version 4.00 - Jan. 1988
;

if SEGSEL = S_CODE
;	ASSUME	SS:DOSGROUP,CS:DOSGROUP

;.xcref
;.xlist
INCLUDE '../INC/DOSSYM.INC'
INCLUDE '../INC/DEVSYM.INC'
;.list
;.cref

; The following routines form the console I/O group (funcs 1,2,6,7,8,9,10,11).
; They assume ES and DS NOTHING, while not strictly correct, this forces data
; references to be SS or CS relative which is desired.

    i_need  CARPOS,BYTE
    i_need  CharCo,BYTE
    i_need  PFLAG,BYTE
    i_need  CurrentPDB,WORD			 ;AN000;
    i_need  InterCon,BYTE			 ;AN000;
    i_need  SaveCurFlg,BYTE			 ;AN000;


Break

; Inputs:
;	None
; Function:
;	Input character from console, echo
; Returns:
;	AL = character

	procedure   STD_CON_INPUT$,NEAR   ;System call 1
;ASSUME	DS:NOTHING,ES:NOTHING

 if  DBCS					;AN000;
	push	word [ss:InterCon]		;AN000;
	mov	[ss:InterCon],01H			;AN000;
	invoke	INTER_CON_INPUT_NO_ECHO 	;AN000;
	pop	word [ss:InterCon]		;AN000;
	pushf					;AN000;
	push	AX				;AN000;
	mov	[ss:SaveCurFlg],0			;AN000;
	jnz	sj0_CPMIO2				;AN000;
	mov	[ss:SaveCurFlg],1			;AN000;
sj0_CPMIO2:						;AN000;
	invoke	OUTT				;AN000;
	mov	[ss:SaveCurFlg],0			;AN000;
	pop	AX				;AN000;
	popf					;AN000;
	jz	STD_CON_INPUT$			;AN000;
 else						;AN000;
	invoke	STD_CON_INPUT_NO_ECHO$
	PUSH	AX
	invoke	OUTT
	POP	AX
 end if						;AN000;
	return
EndProc STD_CON_INPUT$

Break

; Inputs:
;	DL = character
; Function:
;	Output character to console
; Returns:
;	None

	procedure   STD_CON_OUTPUT$,NEAR   ;System call 2
;	public	OUTCHA			       ;AN000;
;ASSUME	DS:NOTHING,ES:NOTHING

	MOV	AL,DL

	entry	OUTT
	CMP	AL,20H
	JB	CTRLOUT
	CMP	AL,c_DEL
	JZ	OUTCH
OUTCHA: 				   ;AN000;
	INC	byte [ss:CARPOS]
OUTCH:
	PUSH	DS
	PUSH	SI
	INC	byte [ss:CharCo]		;invoke  statchk...
	AND	byte [ss:CharCo],00111111B	;AN000; every 64th char
	JNZ	OUTSKIP
	PUSH	AX
	invoke	STATCHK
	POP	AX
OUTSKIP:
	invoke	RAWOUT				;output the character
	POP	SI
	POP	DS
 if  DBCS				;AN000;
	TEST	[ss:SaveCurFlg],01H	;AN000;print but no cursor adv? 2/13/KK
	retnz				;AN000;if so then do not send to prt2/13/KK
 end if
	TEST	byte [ss:PFLAG],-1
	retz
	PUSH	BX
	PUSH	DS
	PUSH	SI
	MOV	BX,1
	invoke	get_io_sft
	JC	TRIPOPJ
	MOV	BX,[SI+sf_entry.sf_flags]
	TEST	BX,sf_isnet			; output to NET?
	JNZ	TRIPOPJ 			; if so, no echo
	TEST	BX,devid_device 		; output to file?
	JZ	TRIPOPJ 			; if so, no echo
	MOV	BX,4
	invoke	get_io_sft
	JC	TRIPOPJ
	TEST	[SI+sf_entry.sf_flags],sf_net_spool	; StdPrn redirected?
	JZ	LISSTRT2J			; No, OK to echo
	MOV	byte [ss:PFLAG],0		; If a spool, NEVER echo
TRIPOPJ:
	JMP	TRIPOP

LISSTRT2J:
	JMP	LISSTRT2

CTRLOUT:
	CMP	AL,c_CR
	JZ	ZERPOS
	CMP	AL,c_BS
	JZ	BACKPOS
	CMP	AL,c_HT
	JNZ	OUTCH
	MOV	AL,[ss:CARPOS]
	OR	AL,0F8H
	NEG	AL

	entry	TAB

	PUSH	CX
	MOV	CL,AL
	MOV	CH,0
	JCXZ	POPTAB
TABLP:
	MOV	AL," "
	invoke	OUTT
	LOOP	TABLP
POPTAB:
	POP	CX
	return

ZERPOS:
	MOV	byte [ss:CARPOS],0
	JMP	OUTCH
OUTJ:	JMP	OUTT

BACKPOS:
	DEC	byte [ss:CARPOS]
	JMP	OUTCH

	entry	BUFOUT
	CMP	AL," "
	JAE	OUTJ		;Normal char
	CMP	AL,9
	JZ	OUTJ		;OUT knows how to expand tabs

;DOS 3.3  7/14/86
	CMP	AL,"U"-"@"      ; turn ^U to section symbol
	JZ	CTRLU
	CMP	AL,"T"-"@"      ; turn ^T to paragraph symbol
	JZ	CTRLU
NOT_CTRLU:
;DOS 3.3  7/14/86

	PUSH	AX
	MOV	AL,"^"
	invoke	OUTT		;Print '^' before control chars
	POP	AX
	OR	AL,40H		;Turn it into Upper case mate
CTRLU:
	invoke	OUTT
	return
EndProc STD_CON_OUTPUT$

Break

; Inputs:
;	None
; Function:
;	Returns character from aux input
; Returns:
;	Character in AL

	procedure   STD_AUX_INPUT$,NEAR   ;System call 3
;ASSUME	DS:NOTHING,ES:NOTHING

	invoke	STATCHK
	MOV	BX,3
	invoke	get_io_sft
	retc
	JMP	SHORT TAISTRT
AUXILP:
	invoke	SPOOLINT
TAISTRT:
	MOV	AH,1
	invoke	IOFUNC
	JZ	AUXILP
	XOR	AH,AH
	invoke	IOFUNC
	return
EndProc STD_AUX_INPUT$

Break

; Inputs:
;	Character in DL
; Function:
;	Output character to aux output
; Returns:
;	Nothing

	procedure   STD_AUX_OUTPUT$,NEAR   ;System call 4
;ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	BX
	MOV	BX,3
	JMP	SHORT SENDOUT

EndProc STD_AUX_OUTPUT$

Break

; Inputs:
;	DL = Character
; Function:
;	Output the character to the list device
; Returns:
;	None

	procedure   STD_PRINTER_OUTPUT$,NEAR   ;System call 5
;ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	BX
	MOV	BX,4

SENDOUT:
	MOV	AL,DL
	PUSH	AX
	invoke	STATCHK
	POP	AX
	PUSH	DS
	PUSH	SI
LISSTRT2:
	invoke	RAWOUT2
TRIPOP:
	POP	SI
	POP	DS
	POP	BX
	return
EndProc STD_PRINTER_OUTPUT$

Break

; Inputs:
;	None
; Function:
;	Check console input status
; Returns:
;	AL = -1 character available, = 0 no character

	procedure   STD_CON_INPUT_STATUS$,NEAR	 ;System call 11
;ASSUME	DS:NOTHING,ES:NOTHING

	invoke	STATCHK
	MOV	AL,0			; no xor!!
	retz
	OR	AL,-1
	return
EndProc STD_CON_INPUT_STATUS$

Break

; Inputs:
;	AL = DOS function to be called after flush (1,6,7,8,10)
; Function:
;	Flush console input buffer and perform call in AL
; Returns:
;	Whatever call in AL returns or AL=0 if AL was not 1,6,7,8 or 10

	procedure   STD_CON_INPUT_FLUSH$,NEAR	;System call 12
;ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	AX
	PUSH	DX
	XOR	BX,BX
	invoke	get_io_sft
	JC	BADJFNCON
	MOV	AH,4
	invoke	IOFUNC

BADJFNCON:
	POP	DX
	POP	AX
	MOV	AH,AL
	CMP	AL,1
	JZ	REDISPJ
	CMP	AL,6
	JZ	REDISPJ
	CMP	AL,7
	JZ	REDISPJ
	CMP	AL,8
	JZ	REDISPJ
	CMP	AL,10
	JZ	REDISPJ
	MOV	AL,0
	return

REDISPJ:
 if  DBCS			  ;AN000;
	mov	ds,[ss:CurrentPDB]   ;AN000;
				  ;AN000; set DS same as one from COMMAND entry
 end if
	CLI
	transfer    REDISP
EndProc STD_CON_INPUT_FLUSH$

end if
;    END
