;	SCCSID = @(#)cpmio.asm	1.1 85/04/10
TITLE	CPMIO - device IO for MSDOS
NAME	CPMIO
;
; Standard device IO for MSDOS (first 12 function calls)
;

;.xlist
;.xcref
INCLUDE '../INC/DOSSEG.ASM'
;.cref
;.list

;
; Old style CP/M 1-12 system calls to talk to reserved devices
;
;   $Std_Con_Input_No_Echo
;   $Std_Con_String_Output
;   $Std_Con_String_Input
;   $RawConIO
;   $RawConInput
;   RAWOUT
;   RAWOUT2
;
;   Revision history:
;
;     A000     version 4.00 - Jan 1988
;     A002     PTM    -- dir >lpt3 hangs
;
;
;
;
;
;
;
;
;
;

if SEGSEL = S_CODE
;	ASSUME	SS:DOSGROUP,CS:DOSGROUP

;.xcref
;.xlist
INCLUDE '../INC/DOSSYM.INC'
INCLUDE '../INC/DEVSYM.INC'
INCLUDE '../INC/DOSCNTRY.INC'			;AN000		2/12/KK
;.list
;.cref

; DEFINED answers differently on fasm's first pass and its later ones, so a
; default given under it makes the assembly oscillate; MATCH asks the
; preprocessor whether the name has a meaning yet, which is what IFNDEF asked.
match =KANJI, KANJI { KANJI EQU 0 }	;FALSE

; The following routines form the console I/O group (funcs 1,2,6,7,8,9,10,11).
; They assume ES and DS NOTHING, while not strictly correct, this forces data
; references to be SS or CS relative which is desired.

    i_need  CARPOS,BYTE
    i_need  STARTPOS,BYTE
    i_need  INBUF,128
    i_need  INSMODE,BYTE
    i_need  user_SP,WORD
;    EXTRN   EscChar:BYTE		; lead byte for function keys
;    EXTRN   CanChar:BYTE		; Cancel character
;    EXTRN   OUTCHA:NEAR 		;AN000 char out with status check 2/11/KK
    i_need  PRINTER_FLAG,BYTE
    i_need  SCAN_FLAG,BYTE
    i_need  DATE_FLAG,WORD
    i_need  Packet_Temp,WORD		; temporary packet used by readtime
    i_need  DEVCALL,DWORD
    i_need  InterChar,BYTE		;AN000;interim char flag ( 0 = regular char)
    i_need  InterCon,BYTE		;AN000;console flag ( 1 = in interim mode )
    i_need  SaveCurFlg,BYTE		;AN000;console out ( 1 = print and do not advance)
    i_need  COUNTRY_CDPG,byte		;AN000; 	2/12/KK
    i_need  TEMP_VAR,WORD		;AN000; 	2/12/KK
    i_need  DOS34_FLAG,WORD		;AN000; 	2/12/KK



Break
 if  DBCS							  ;AN000;

;-------------------------------- Start of Korean Support 2/11/KK
	procedure   STD_CON_INPUT_NO_ECHO$,NEAR   ;System call 8  ;AN000;
;ASSUME	DS:NOTHING,ES:NOTHING					  ;AN000;

StdCILop:							  ;AN000;
	invoke	INTER_CON_INPUT_NO_ECHO 			  ;AN000;
	transfer InterApRet		; go to return fuction	  ;AN000;

EndProc STD_CON_INPUT_NO_ECHO$					  ;AN000;

	procedure   INTER_CON_INPUT_NO_ECHO,NEAR		  ;AN000;
;ASSUME	DS:NOTHING,ES:NOTHING					  ;AN000;
;-----------------------------------End of Korean Support 2/11/KK

; Inputs:
;	None
; Function:
;	Same as $STD_CON_INPUT_NO_ECHO but uses interim character read from
;	the device.
; Returns:
;	AL = character
;	Zero flag SET if interim character, RESET otherwise

 else								  ;AN000;


;
; Inputs:
;	None
; Function:
;	Input character from console, no echo
; Returns:
;	AL = character

	procedure   STD_CON_INPUT_NO_ECHO$,NEAR   ;System call 8
;ASSUME	DS:NOTHING,ES:NOTHING

 end if
	PUSH	DS
	PUSH	SI
INTEST:
	invoke	STATCHK
	JNZ	Get
;*************************************************************************
	cmp	byte [PRINTER_FLAG],0	; is printer idle?
	jnz	no_sys_wait_CPMIO
	mov	ah,5			; get input status with system wait
	invoke	IOFUNC
no_sys_wait_CPMIO:
;**************************************************************************
	MOV	AH,84h
	INT	int_IBM

;;; 7/15/86  update the date in the idle loop
;;; Dec 19, 1986 D.C.L. changed following CMP to Byte Ptr from Word Ptr
;;;;		 to shorten loop in consideration of the PC Convertible

	CMP	byte [DATE_FLAG],-1 ; date is updated may be every
	JNZ	NoUpdate		; 65535 x ? ms if no one calls
	PUSH	AX
	PUSH	BX			; following is tricky,
	PUSH	CX			; it may be called by critical handler
	PUSH	DX			; at that time, DEVCALL is used by
					; other's READ or WRITE
	PUSH	DS			; save DS = SFT's sgement
	PUSH	CS			; READTIME must use DS=CS
	POP	DS

	MOV	AX,0			; therefore, we save DEVCALL
	CALL	Save_Restore_Packet	; save DEVCALL packet
	invoke	READTIME		; readtime
	MOV	AX,1
	CALL	Save_Restore_Packet	; restore DEVCALL packet

	PUSH	BX			; the follwing code is to
	MOV	BX,DATE_FLAG
	ADD	BX,2			; check the TAG
	CMP	word [cs:BX],22642
	JZ	check_ok
	invoke	DOSINIT 		; should never come here
check_ok:
	POP	BX

	POP	DS			; restore DS
	POP	DX
	POP	CX
	POP	BX
	POP	AX
NoUpdate:
	INC	word [DATE_FLAG]

;;; 7/15/86 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	JMP	INTEST
Get:
	XOR	AH,AH
	invoke	IOFUNC
	POP	SI
	POP	DS
;;; 7/15/86
	MOV	byte [SCAN_FLAG],0
	CMP	AL,0	    ; extended code ( AL )
	JNZ	noscan
	MOV	byte [SCAN_FLAG],1	; set this flag for ALT_Q key

noscan:
;;; 7/15/86
 if  DBCS			    ;AN000;
	cmp	[cs:InterChar],1    ;AN000; set the zero flag if the character3/31/KK ;AN000;
 end if				    ;AN000;
	return
 if  DBCS			    ;AN000;
EndProc INTER_CON_INPUT_NO_ECHO     ;AN000;  ;2/11/KK				      ;AN000;
 else				    ;AN000;
EndProc STD_CON_INPUT_NO_ECHO$
 end if				    ;AN000;

Break

; Inputs:
;	DS:DX Point to output string '$' terminated
; Function:
;	Print the string on the console device
; Returns:
;	None

	procedure   STD_CON_STRING_OUTPUT$,NEAR   ;System call 9
;ASSUME	DS:NOTHING,ES:NOTHING

	MOV	SI,DX
STRING_OUT1:
	LODSB
 if  DBCS				;AN000;
	invoke	TESTKANJ		;AN000; 	      2/11/KK		 ;AN000;
	jz	SBCS00			;AN000; 	      2/11/KK		 ;AN000;
	invoke	OUTT			;AN000; 	      2/11/KK		 ;AN000;
	LODSB				;AN000; 	      2/11/KK		 ;AN000;
	JMP	NEXT_STR1		;AN000; 	      2/11/KK		 ;AN000;
SBCS00: 				;AN000; 	      2/11/KK		 ;AN000;
 end if					;AN000;
	CMP	AL,'$'
	retz
NEXT_STR1:
	invoke	OUTT
	JMP	STRING_OUT1

EndProc STD_CON_STRING_OUTPUT$

if  DBCS				;AN000;
INCLUDE 'KSTRIN.ASM'			;AN000;
else					;AN000;
INCLUDE 'STRIN.ASM'
end if					;AN000;

Break

; Inputs:
;	DL = -1 if input
;	else DL is output character
; Function:
;	Input or output raw character from console, no echo
; Returns:
;	AL = character

	procedure   RAW_CON_IO$,NEAR   ; System call 6
;ASSUME	DS:NOTHING,ES:NOTHING

	MOV	AL,DL
	CMP	AL,-1
	JZ	RAW22				      ;AN000;
	JMP	RAWOUT				      ;AN000;
RAW22:						      ;AN000;
	LES	DI,dword [user_SP]		      ; Get pointer to register save area
	XOR	BX,BX
	invoke	get_io_sft
	retc
 if  DBCS				;AN000;
	push	word [InterCon]	;AN000;
	mov	[InterCon],0		;AN000; disable interim characters
 end if					;AN000;
	MOV	AH,1
	invoke	IOFUNC
	JNZ	RESFLG
 if  DBCS				;AN000;
	pop	word [InterCon]	;AN000; restore interim flag
 end if					;AN000;
	invoke	SPOOLINT
	OR	byte [es:DI+user_environ.user_F],40H ; Set user's zero flag
	XOR	AL,AL
	return

RESFLG:
	AND	byte [es:DI+user_environ.user_F],0FFH-40H    ; Reset user's zero flag
 if  DBCS				;AN000;
	XOR	AH,AH			;AN000;
	invoke	IOFUNC			;AN000; get the character
	pop	word [InterCon]	;AN000;
	return				;AN000;
 end if					;AN000; 				;AN000;

RILP:
	invoke	SPOOLINT

; Inputs:
;	None
; Function:
;	Input raw character from console, no echo
; Returns:
;	AL = character

	entry	RAW_CON_INPUT$	      ; System call 7

	PUSH	BX
	XOR	BX,BX
	invoke	get_io_sft
	POP	BX
	retc
	MOV	AH,1
	invoke	IOFUNC
	JNZ	Got
	MOV	AH,84h
	INT	int_IBM
	JMP	RILP
Got:
	XOR	AH,AH
	invoke	IOFUNC
 if  DBCS				;AN000;
	cmp	[InterChar],1		;AN000;    2/11/KK
;								2/11/KK
;	Sets the application zero flag depending on the 	2/11/KK
;	zero flag upon entry to this routine. Then returns	2/11/KK
;	from system call.					2/11/KK
;								2/11/KK
entry	InterApRet			;AN000; 		2/11/KK 	;AN000;
	pushf				;AN000; 3/16/KK
	push	ds			;AN000; 3/16/KK
	push	bx			;AN000; 3/16/KK
	Context DS			;AN000; 3/16/KK
	MOV	BX,COUNTRY_CDPG+DOS_country_cdpg_info.ccDosCodePage
	cmp	word [bx],934	;AN000; 3/16/KK       korean code page ?
	pop	bx			;AN000; 3/16/KK
	pop	ds			;AN000; 3/16/KK
	je	do_koren		;AN000; 3/16/KK
	popf				;AN000; 3/16/KK
	return				;AN000; 3/16/KK
do_koren:				;AN000; 3/16/KK
	popf				;AN000;
	LES	DI,dword [user_SP]	;AN000; Get pointer to register save area KK
	jnz	sj0_CPMIO			;AN000; 		      2/11/KK
	OR	byte [es:DI+user_environ.user_F],40H	;AN000; Set user's zero flag  2/11/KK
	return				;AN000; 		2/11/KK
sj0_CPMIO:					;AN000; 		2/11/KK
	AND	byte [es:DI+user_environ.user_F],0FFH-40H ;AN000; Reset user's zero flag 2/KK
 end if						 ;AN000;
	return					 ;AN000;
;
;	Output the character in AL to stdout
;
	entry	RAWOUT

	PUSH	BX
	MOV	BX,1

	invoke	get_io_sft
	JC	RAWRET1

	MOV	BX,[SI+sf_entry.sf_flags]

 ;
 ; If we are a network handle OR if we are not a local device then go do the
 ; output the hard way.
 ;

	AND	BX,sf_isnet + devid_device
	CMP	BX,devid_device
	JNZ	RAWNORM
 if  DBCS					;AN000;
	TEST	[SaveCurFlg],01H		;AN000; print but no cursor adv?
	JNZ	RAWNORM 			;AN000;    2/11/KK
 end if						;AN000;

;	TEST	BX,sf_isnet			; output to NET?
;	JNZ	RAWNORM 			; if so, do normally
;	TEST	BX,devid_device 		; output to file?
;	JZ	RAWNORM 			; if so, do normally

	PUSH	DS
	LDS	BX,[SI+sf_entry.sf_devptr]		; output to special?
	TEST	byte [BX+SYSDEV.SDEVATT],ISSPEC
	POP	DS
	JZ	RAWNORM 			; if not, do normally
	INT	int_fastcon			; quickly output the char
RAWRET:
	CLC
RAWRET1:
	POP	BX
	return
RAWNORM:
	CALL	RAWOUT3
	JMP	RAWRET

;
;	Output the character in AL to handle in BX
;
	entry	RAWOUT2

	invoke	get_io_sft
	retc
RAWOUT3:
	PUSH	AX
	JMP	SHORT RAWOSTRT
ROLP:
	invoke	SPOOLINT
	OR	word [DOS34_FLAG],CTRL_BREAK_FLAG ;AN002; set control break
	invoke	DSKSTATCHK		     ;AN002; check control break
RAWOSTRT:
	MOV	AH,3
	invoke	IOFUNC
	JZ	ROLP
	POP	AX
	MOV	AH,2
	invoke	IOFUNC
	CLC			; Clear carry indicating successful
	return
EndProc RAW_CON_IO$

; Inputs:
;	AX=0 save the DEVCALL request packet
;	  =1 restore the DEVCALL request packet
; Function:
;	save or restore the DEVCALL packet
; Returns:
;	none

	procedure   Save_Restore_Packet,NEAR
;ASSUME	DS:NOTHING,ES:NOTHING

	PUSH	DS
	PUSH	ES
	PUSH	SI
	PUSH	DI
	CMP	AX,0		; save packet
	JZ	save_packet
restore_packet:
	MOV	SI,Packet_Temp	 ;sourec
	MOV	DI,DEVCALL	 ;destination
	JMP	set_seg
save_packet:
	MOV	DI,Packet_Temp	 ;destination
	MOV	SI,DEVCALL	 ;source
set_seg:
	MOV	AX,CS		; set DS,ES to DOSGROUP
	MOV	DS,AX
	MOV	ES,AX
	MOV	CX,11		; 11 words to move
	REP	MOVSW

	POP	DI
	POP	SI
	POP	ES
	POP	DS
	return
EndProc Save_Restore_Packet

end if
;    END
