	PAGE	,132			;

	TITLE	CODE TO BE MADE RESIDENT BY MODE

.XLIST
   include 'STRUC.INC'
.LIST
;.SALL

;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป				   ;AN000;
;บ											  บ				   ;AN000;
															   ;AN000;
;  AC000 - P2852: Infinite retry check at beginning of INT 14 handler was using
;		  wrong bit pattern.

;  AC001 - P5148: retry_flag was addressing the wrong segment

;บ											  บ				   ;AN000;
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ				   ;AN000;
															   ;AN000;

;ษออออออออออออออออออออออออออออออออ  M A C R O S  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

macro DISPLAY MSG
{
	MOV	DX,MSG
	CALL	PRINTF
}

macro GET_INT_VECT INT_NO
{
	PUSH	AX
	MOV	AL,INT_NO		;
	MOV	AH,35H			;FUNCTION CALL "GET VECTOR"
	INT	21H			;Output: ES:BX = the address in the vector
	POP	AX
}

macro SET REG,VALUE
{

	PUSH	AX
	MOV	AX,VALUE
	MOV	REG,AX
	POP	AX

}

macro SET_INT_VECT INT_NO
{
	PUSH	AX			;	DS:DX = CS:IP value to set the interrupt to
	MOV	AL,INT_NO		;Output: the vector "INT_NO" contains DS:DX
	MOV	AH,25H			;function call "SET VECTOR"
	INT	21H
	POP	AX
}

macro store_vector dword_holder
{
					;	ES:BX - the address (vector) to be stored
   MOV	word [dword_holder],BX   ;Output: "dword_holder"=the value passed in ES:BX
   MOV	word [dword_holder+2],ES

}

;บ											  บ
;ศออออออออออออออออออออออออออออออออ  M A C R O S  อออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออออ  E Q U A T E S  ออออออออออออออออออออออออออออออออออออออออออป
;บ											    บ

ADJUSTMENT equ	((ENTPT - move_destination))	;# of bytes the resident code is moved
adjustment_in_paragraphs  equ  ((ADJUSTMENT / 10H))	;# paragraphs the code moved
COM_status_bios	EQU	03		  ;BIOS input for com status request	;AN001;
E_rescode		EQU	1		  ;value of "res_com_retry_type" for E retry requested	 ;AN001;
false		EQU	0
framing_error	EQU	0000100000000000B ;bit returned in AX from com status			 ;AN001;
holding_empty	EQU	0010000000000000B ;bit returned in AX from com status			 ;AN001;
INT14		EQU	014H
INT17		EQU	017H
LPT_status	EQU	02		  ;value of AH for printer status checks					   ;AN000;
not_busy	EQU	80H		  ;just the not busy bit on
overrun_error	EQU	0000001000000000B ;bit returned in AX from com status			 ;AN001;
parity_error	EQU	0000010000000000B ;bit returned in AX from com status			 ;AN001;
P14_model_byte	EQU	0F9H		  ;P14's have a F9 at F000:FFFE
R		EQU	3		  ;value of "res_com_retry_type" for R retry requested	 ;AN001;
shift_empty	EQU	0100000000000000B ;bit returned in AX from com status			 ;AN001;
time_out	EQU	1000000000000000B ;time out bit returned in AX from com status		 ;AN001;
TO_SCREEN	EQU	9		  ;REQUEST OUTPUT TO SCREEN
TRUE		EQU	0FFH
USER_ABORT	EQU	00H

;บ											    บ
;ศอออออออออออออออออออออออออออออออ  E Q U A T E S  ออออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออ  S T R U C T U R E S  ออออออออออออออออออออออออออออออออออออป
;บ											  บ


;บ											  บ
;ศอออออออออออออออออออออออออออออ  S T R U C T U R E S  ออออออออออออออออออออออออออออออออออออผ


if SEGSEL = S_ABSOLUTE
virtual at 0F000H
	ORG	0E739H
RS232:
	ORG	0EFD2H
PRINTER_IO:
;NOTE: THE VALUES REPRESENTED BY THIS SEGMENT ARE NOT NECESSARILY
; THE ONES USED BY THE SUBSEQUENT PROCEDURES.  THESE HERE MERELY
; SERVE AS SAMPLES.  THE ACTUAL VALUES IN THE INSTRUCTIONS:
;	JMP	0F000H:RS232
;	JMP	0F000H:PRINTER_IO
; WILL BE MOVED INTO THESE INSTRUCTIONS FROM THE VECTOR TABLE USING
; THE THEN CURRENT VALUES OF INT 14H FOR RS232 AND OF INT 17H FOR
; THE PRINTER_IO JUMP TARGETS.	THIS IS TO ALLOW FOR SOME USER
; TO HAVE INTERCEPTED THESE VECTORS AND DIRECTED THEIR REQUESTS TO
; HIMSELF INSTEAD OF TO THE ROM.

	ORG	0FFFEH
;model_byte	 LABEL	 BYTE
end virtual
end if

if SEGSEL = S_ABSOLUTE
virtual at 0
	ORG	50H
label VECT14H dword   ;RS232 CALL
	ORG	5CH
label VECT17H dword   ;PRINTER I/O CALL
	ORG	471H
label BREAK_FLAG byte   ;BREAK FLAG
BREAK_BIT EQU	80H			;ON=BREAK
	ORG	530H
label RESSEG dword   ;VECTOR OF MODETO, INIT TO ZERO
end virtual
end if


;****************************************************************
if SEGSEL = S_PRINTF_CODE
;	ASSUME	CS:PRINTF_CODE,DS:PRINTF_CODE


;ษอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;EXTRN	 device_type:BYTE	 ;see parse.asm
;EXTRN	 COMX:ABS		 ;see parse.asm
;EXTRN	 LPTX:ABS		 ;see parse.asm
;EXTRN	MAIN:NEAR
;EXTRN	MOVED_MSG:WORD	    ;CR,LF,"Resident portion of MODE loaded",CR,LF,"$"
;EXTRN	busy_status:ABS      ;value of lpt1_retry_type[BX] when user wants actual status, see modeprin
;EXTRN	PRINTF:NEAR		;interface to message retriever, see display.asm
;EXTRN	 reroute_requested:BYTE    ;see parse.asm
;EXTRN	 retry_requested:BYTE	 ;see parse.asm

;บ											  บ
;ศอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออผ



;ษอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;PUBLIC	 first_char_in_command_line	     ;location of the command line parameters
;PUBLIC	FIXUP
;PUBLIC	 lpt1_retry_type	 ;filled in and used to get at other two lpt retry masks in modeprin
;PUBLIC	rescode_length		;REFERENCED IN MAIN PROCEDURE
;PUBLIC	MODETO
;PUBLIC	move_destination	;location of the resident code after it has been moved
;PUBLIC	NEW_PTSFLAG		;RESIDENT THE FLAG WILL BE ACCESSABLE TO
;PUBLIC	NEW_SCRNTABL		;MODESCRN NEEDS TO KNOW WHERE IT WENT
;PUBLIC	OFFPTS			;USED IN MODEECHO TO ADDRESS MODEPTS
;PUBLIC	OFFRETRY
;PUBLIC	 ptsflag1		 ;make available to display_printer_reroute_status
;PUBLIC	P14_model_byte
;PUBLIC	res_com_retry_type
;PUBLIC  res_lpt_retry_type
;PUBLIC	 resflag2		 ;make available to display_printer_reroute_status
;PUBLIC	RES_MODEFLAG		; RESIDENT THE FLAG WILL BE ACCESSABLE
;PUBLIC	RESSEG			;SCRNTABL NEEDS TO FOLLOW THIS VECTOR TO ADDRESS VIDEO PARMS
;PUBLIC	SCRNTABL
;PUBLIC	submodel_byte		 ;holder for machine's secondary model byte
;PUBLIC	VECTOR14
;PUBLIC	VECTOR17

;บ											  บ
;ศอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออผ

	ORG	2CH
label environ_seg word        ;segment address of the environment, used as the block of memory to free so	   ;AN000;
					  ;environment is not part of resident code.

	ORG	60H			  ;first usable byte of PSP. If you change this check the
					  ;calculation of paragraphs in 'main'

label move_destination word        ;where the resident will be moved to

;    THIS STRUCTURE DEFINES THE PROGRAM SEGMENT PREFIX AREA
;     POINTED TO BY THE ES REGISTER.  THIS MUST BE DEFINED HERE, IT REPLACES THE
;     'ORG 100'

	ORG	80H
label command_line_length byte   ;not used, just place holder to allign next field
	ORG	81H
label first_char_in_command_line byte     ;location of the command line parameters
;command_line		     DB      7FH DUP(?) 	 ;PARM AREA

	ORG	100H
ENTPT:	JMP	main			;ENTRY POINT, START AT THE MAIN PROCEDURE
	SUBTTL	SERIAL RETRY
	PAGE
;THIS PROC WILL BE POINTED TO BY INT VECTOR 14H


MODETO:




PUSH  CX
MOV   CL,DL		   ;CL=DL=0,1,2 or 3
SHL   CL,1		   ;CL= 0, 2, 4 or 6 for COM 1,2,3 or 4 respectively						   ;AC000;
XOR   CH,CH		   ;CH=0 ready for ANDing in the mask								   ;AC000;
OR    CH,00000011B	   ;CH=00000011, mask for any type of retry, to be shifted into proper position 		   ;AC000;
SHL   CH,CL		   ;CH=00000011, 00001100, 00110000 or 11000000 for COM 1,2,3 or 4 respectively
AND   CH,byte [cs:RES_MODEFLAG]     ;see if any bit is on for this COM port ;AC001;
MOV   [cs:retry_type],CX  ;AC001; save for check after call to old INT 14		 ;AN001;
POP   CX
JNZ   PUSHAX





label VECTOR14 word   ;THE NEXT JMP INSTRUCTION HAS 5 BYTES,
;		    THE LAST 4 ARE THE CONTENTS OF INT 14H,
;		    WHICH NORMALLY POINTS TO THE ROM RS232
;		    HANDLER.  THE CODE GENERATED HERE BY THE
;		    ASSEMBLER IS REPLACED BY THE ACTUAL
;		    CONTENTS OF INT 14H.

TOROM:
	JMP	0F000H:RS232			;NO RETRY, GO DIRECTLY TO ROM ENTRY IRET from there
PUSHAX:
	MOV	[cs:request],AH ;save request type
	PUSH	AX			;SAVE ENTRY PARAMETERS FOR LATER RETRY
	PUSH	DS			;SAVE REGS
	PUSH	AX			;SAVE REGS
	SUB	AX,AX			;POINT TO
	MOV	DS,AX			; PAGE ZERO
	AND	byte [ds:BREAK_FLAG],0FFH-BREAK_BIT ;RESET BREAK FLAG
	POP	AX			;RESTORE
	POP	DS			; REGS
	PUSHF				;SAVE FLAGS TO SIMULATE INT INSTRUCTION

VEC	equ	((VECTOR14 +1))	;OFFSET TO IMMEDIATE FIELD OF PREVIOUSLY SET
;				FAR JMP INSTRUCTION, FILLED WITH THE
;				ORIGINAL CONTENTS OF THE INTERRUPT VECTOR
	CALL	dword [cs:VEC]         ;CALL PREVIOUS RS232 HANDLER
	.IF <<[cs:request]> EQ COM_status_bios> ;IF a status request THEN			      ;AN001;
	   PUSH    CX			  ;need CX for shift count in CL				      ;AN001;
	   MOV	   CX,[cs:retry_type] ;AC001; get back retry type for this port				     ;AN001;
	   SHR	   CH,CL		  ;put back in first two bits for retry type check below	      ;AN001;
	   .IF <CH EQ E_rescode> ;AN001;
	      MOV  AX,time_out+framing_error+parity_error+overrun_error     ;indicate the port is on fire     ;AN001;
	   .ELSEIF <CH EQ R> ;AN001;
	      MOV  AX,shift_empty+holding_empty+CLEAR_TO_SEND+DATA_SET_READY  ;indicate the port is ready     ;AN001;
	   .ENDIF					;otherwise assume B retry and pass actual status      ;AN001;
	   POP	   CX			  ;restore reg							      ;AN001;
	.ELSE				  ;continue as if a send request				      ;AN001;
	   PUSH    AX			   ;SAVE REGS
	   PUSH    DS			   ; REGS
	   SUB	   AX,AX		   ;POINT TO
	   MOV	   DS,AX		   ; PAGE ZERO
	   TEST    byte [ds:BREAK_FLAG],BREAK_BIT ;TEST BREAK FLAG
	   POP	   DS			   ;RESTORE
	   POP	   AX			   ; REGS
	   JZ	   TESTER		   ;BRANCH IF NO BREAK
	   OR	   AH,80H		   ;SIMULATE TIMEOUT ERROR ON BREAK
	.ENDIF				   ;ENDIF status request					      ;AN001;
FLUSH:
	INC	SP			;FLUSH THE
	INC	SP			; STACK
	IRET				;RETURN
;
TESTER:
	TEST	AH,80H			;TEST IF A REAL TIMEOUT
	JZ	FLUSH			;IF NOT, RETURN
	POP	AX			;RETRIEVE ORIGINAL ENTRY PARAMETERS
	JMP	PUSHAX			;DO RETRY
;**********************************************************************
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
RES_MODEFLAG = $			;WHEN THIS CODE IS RESIDENT THE FLAG WILL BE
					; ACCESSABLE BY MODECOM AS AN OFFSET FROM ADDRESS
					; POINTED TO BY VECT14H AND RESSEG
res_com_retry_type = $

	    DB	  0			;AN665;no retry of any type active for any port
;
;	    bits comx		00=>no retry for any port
;	    ---- ----		01=>E for COM1, no retry for 2, 3 and 4
;	    0-1  com1		02=>B for COM1, no retry for 2, 3 and 4
;	    2-3  com2		03=>R for COM1, no retry for 2, 3 and 4
;	    4-5  com3		04=>E for COM2, no retry for 1, 3 and 4
;	    6-7  com4		05=>E for COM2, E for COM1, none for 3 and 4
;				06=>E for COM2, B for COM1, none for 3 and 4
;	    bit 		07=>E for COM2, R for COM1, none for 3 and 4
;	   pair 		08=>B for COM2, none for 1, 3 and 4
;	  value  active 	09=>B for COM2, E for COM1, none for 3 and 4
;	  -----  ------ 	0A=>B for COM2, B for COM1, none for 3 and 4
;	      0  unknown	0B=>B for COM2, R for COM1, none for 3 and 4
;	      1  E		0C=>R for COM2, no retry for 1, 3 and 4
;	      2  B		0D=>R for COM2, E for COM1, none for 3 and 4
;	      3  R		0E=>R for COM2, B for COM1, none for 3 and 4
;				0F=>R for COM2, R for COM1, none for 3 and 4
;				10=>E for COM3, none for 1, 2 and 4
;					  etc.
;MODETO	ENDP
;**************************************************************
	SUBTTL	DETERMINE PARALLEL TO SERIAL, OR PARALLEL TIMEOUT
	PAGE
;THIS PROC MAY BE POINTED TO BY INT VECTOR 17H
MODEPTS:
OFFPTS	equ	(MODEPTS - MODETO)
	TEST	DL,1			;DETERMINE IF REDIRECTION APPLIES
;		NOTE: THIS IMMEDIATE FIELD IS Revised BY MODE
;
;THIS NEXT JUMP INSTRUCTION IS Revised BY MODEECHO TO REFLECT WHICH
;LPTN IS TO BE REDIRECTED TO WHICH COMM.
	virtual at $
	JNZ	CK			;THIS JNZ IS Revised BY MODE
	end virtual
;
	virtual at $
	JZ	CK			;IT MAY BE CHANGED TO THIS
	end virtual
;
	JMP	SHORT NOREDIRECT	;  OR THIS...
;
NOREDIRECT:
OFFRETRY =	$		;disp into resident code of retry flgs
;THIS NEXT SECTION WILL TEST FOR THE OPTIONAL RETRY ON PARALLEL TIMEOUT.
	TEST	DL,1			;TEST TO SEE IF PARALLEL RETRY IS ACTIVE
;THIS NEXT JUMP INSTRUCTION IS Revised BY MODEPRIN TO REFLECT WHICH
;LPT1n DEFICE IS TO BE RETRIED.  IT WILL APPEAR IN SEVERAL FORMS:
	virtual at $
	JNZ	PAR_RETRY		;THIS INSTRUCTION MAY BE Revised
	end virtual
;
	virtual at $
	JZ	PAR_RETRY
	end virtual
;
	JMP	SHORT ASIS
;
label VECTOR17 word
ASIS:	JMP	0F000H:PRINTER_IO		;NO REDIRECTION, GO DIRECTLY TO PREVIOUS INT 17H
;**************************************************************
	SUBTTL	RETRY PARALLEL ON TIMEOUT.
	PAGE
PAR_RETRY:
RT_:
      MOV   [cs:request],AH      ;save the function requested for check after return from call to INT 17		  ;AN000;
      PUSH  AX			    ;SAVE ENTRY PARAMETERS FOR LATER USE
      PUSH  DS			    ;SAVE CALLER'S REGS
      PUSH  AX			    ;SAVE REGS
;
      SUB   AX,AX		    ;POINT TO PAGE ZERO
      MOV   DS,AX		    ; USING THE DATA SEG REG
;
      AND   byte [ds:BREAK_FLAG],0FFH-BREAK_BIT ;RESET BREAK FLAG
;
      POP   AX			    ;RESTORE CALLER'S REGS
      POP   DS			    ;RESTORE REGS
      PUSHF			    ;SAVE FLAGS TO SIMULATE INT INSTRUCTION
PVEC  equ   (VECTOR17+1)	;OFFSET TO IMMEDIATE FIELD OF PREVIOUSLY SET
;		    FAR JUMP INSTRUCTION, FILLED WITH THE
;		    ORIGINAL CONTENTS OF THE INT 17H VECTOR.
      CALL  dword [cs:PVEC]       ;CALL PREVIOUS PARALLEL PORT HANDLER
      CMP   byte [cs:request],LPT_status       ;AN000;
      JNE   init_or_write												   ;AN000;
	 TEST  AH,not_busy	    ;see if the printer was busy (not busy bit off)					   ;AN000;
	 JNZ   PFLUSH		    ;IF busy dork the status byte							   ;AN000;
	    PUSH  BX													   ;AN000;
	    MOV   BX,DX 	       ;BX=zero based printer number							   ;AN000;
	    CMP   byte [cs:lpt1_retry_type+BX],busy_status     ;IF status should be changed THEN		     ;AN000;
	    JZ	  dont_modify					     ;busy setting means user wants actual status	   ;AN000;
	       MOV   AH,byte [cs:lpt1_retry_type+BX]     ;change to status set by prior retry setting request for this LPT ;AN000;
	    dont_modify:												   ;AN000;
	    POP   BX													   ;AN000;
      JMP   PFLUSH		    ;return to caller									   ;AN000;
init_or_write:														   ;AN000;
      PUSH  AX			    ;SAVE RETURN CODE IN AH
      PUSH  DS			    ;SAVE DATA SEGMENT REG
;
      SUB   AX,AX		    ;POINT TO
      MOV   DS,AX		    ;  SEGMENT AT ZERO
;
      TEST  byte [ds:BREAK_FLAG],BREAK_BIT ;TEST BREAK FLAG BIT
      POP   DS			    ;RESTORE SEG REG
      POP   AX			    ;RESTORE RETURN CODE TO AH
      JZ    PTEST_		    ;BRANCH IF NO BREAK REQUESTED
;
      OR    AH,USER_ABORT	    ;SIMULATE TIMEOUT
PFLUSH:
      INC   SP			    ;FLUSH THE
      INC   SP			    ;  STACK
      IRET			    ;RETURN TO CALLER
;
PTEST_:
      TEST  AH,01H		    ;TEST IF A REAL PARALLEL TIMEOUT
      JZ    PFLUSH		    ;IF NOT, RETURN
      POP   AX			    ;RETRIEVE ORIGINAL ENTRY PARAMETERS
      JMP   RT_			    ;DO RETRY
;**************************************************************
	SUBTTL	REDIRECT PARALLEL I/O TO SERIAL
	PAGE
CK:
FIXUP	equ	(CK - NOREDIRECT)
	CMP	AH,1			;CHECK FOR 'INITIALIZE' CODE
;			AH=0, PRINT THE CHAR IN AL
;			AH=1, INITIALIZE
;			AH=2, READ STATUS
	JNZ	PTCHR			;IT IS PRINT CHARACTER OR READ STATUS
;			SINCE IT IS 'INITIALIZE'
	MOV	AH,80H			;PASS BACK 'NOT BUSY' RETURN CODE FROM
;			AH=1, (INITIALIZE)
	IRET
;
PTCHR:
;			IT IS PRINT CHARACTER OR READ STATUS
	PUSH	BX			;SAVE THE
	PUSH	AX			; REGS
	PUSH	DX			;SAVE MORE REGS
	MOV	BX,RESFLAG2               ;POINT AT PARALLEL TO SERIAL
;				     CORRESPONDENCE TABLE IN RESIDENT CODE
	ADD	BX,DX			;INDEX USING PRINTER SELECTION (0,1,OR 2)
	MOV	DL,[cs:BX]		;GET CORRESPONDING SERIAL PORT SELECT
	CMP	AH,0			;CHECK FOR 'PRINT CHAR' CODE
	JZ	SENDCHAR		; YES, PRINT CHAR
;				  NO, MUST BE READ STATUS
	MOV	AH,3			;SET TO INT 14 'READ STAT' ENTRY PT
	INT	14H			;GO RS232 AND READ STATUS INTO AX
;
;			AH HAS LINE STATUS:
;			IF TRANSFER HOLDING REG EMPTY, AND
;			IF TRANSMIT SHIFT REGISTER READY, THEN SERIAL PORT
;			NOT BUSY
CLEAR_TO_SEND	EQU	10H
DATA_SET_READY	EQU	20H		;DATA SET READY LINE HIGH
	AND	AL,CLEAR_TO_SEND+DATA_SET_READY 	;SEE IF PRINTER HAS A CHANCE
;	IF$	Z			;DSR and CTS low, so probably off or out of paper
	JNZ IF1$$
	   MOV	   AH,29H		;PAR 'BUSY' 'OUT OF PAPER' 'I/O ERROR' 'TIME OUT'
;	ELSE$
	JMP SHORT EN1$$
IF1$$:
	   CMP	   AL,CLEAR_TO_SEND+DATA_SET_READY
;	   IF$	   E			;IF clear to send and dsta set ready THEN
	   JNE IF3$$
	      MOV     AH,90H		;'NOT BUSY' 'SELECTED'
;	   ELSE$			;ELSE clear to send high OR data set ready high
	   JMP SHORT EN3$$
IF3$$:
	      MOV     AH,10H		   ;SET TO PARALLEL 'BUSY' 'SELECTED'
;	   ENDIF$
EN3$$:
;	ENDIF$
EN1$$:
	POP	DX			;RESTORE REG
	JMP	SHORT POPPER		;RESTORE REGS AND EXIT
;
SENDCHAR:
	MOV	AH,1			;SET TO INT 14 'SEND CHAR' ENTRY PT
	INT	14H			;GO RS232 SEND CHAR
;
	POP	DX			;RESTORE REG
	TEST	AH,80H			;TEST IF TIMEOUT RS232 ERROR
	MOV	AH,90H			;SET UP NORMAL RETURN AS IF FROM PRINTER
;			THAT IS: PARALLEL 'NOT BUSY' 'SELECTED'
	JZ	POPPER			;IF NO ERROR
	MOV	AH,09H			;RESET AH TO PARALLEL TIMEOUT ERROR CODE
;		    RET CODE='BUSY', 'I/O ERROR', 'TIMEOUT'
;		    THE USUAL RETURN FROM A WRITE DATA
;		    TO A PARALLEL PRINTER THAT IS OFFLINE
POPPER:
	POP	BX			;RETRIEVE ORIGINAL AX
	MOV	AL,BL			;RESTORE ORIGINAL AL VALUE LEAVING NEW AH
	POP	BX			;RESTORE BX
	IRET				;RETURN

;**********************************************************************
PAGE

PTSFLAG1 DB	0			;FLAG FOR MODE COMMAND:

NEW_PTSFLAG equ (PTSFLAG1 - MODETO)	;WHEN THIS CODE IS
					; RESIDENT THE FLAG WILL BE ACCESSABLE TO
					; MODEECHO AS AN OFFSET FROM ADDRESS
					; POINTED TO BY VECT14H AND RESSEG
;		0=NO INTERCEPT
;		1=INTERCEPT LPT1
;		2=INTERCEPT LPT2
;		3=INTERCEPT LPT1 AND LPT2
;		4=INTERCEPT LPT3
;		5=INTERCEPT LPT1 AND LPT3
;		6=INTERCEPT LPT2 AND LPT3
;		7=INTERCEPT LPT1, LPT2, AND LPT3
RESFLAG2 =	$			;WHERE PTSFLAG2 IS IN THE RESIDENT CODE
PTSFLAG2 DB	0			;FLAG FOR MODE COMMAND:
;		    LPT1 CORRESPONDENCE VALUE:
;		0=COM1
;		1=COM2
;		2=COM3
;		3=COM4
;RESFLAG2 EQU	 (PTSFLAG2 - MODETO)+BASE ;WHERE PTSFLAG2
					; IS IN THE RESIDENT CODE
PTSFLAG3 DB	0			;FLAG FOR MODE COMMAND:
;		    LPT2 CORRESPONDENCE VALUE:
;		0=COM1
;		1=COM2
;		2=COM3
;		3=COM4
PTSFLAG4 DB	0			;FLAG FORMODE COMMAND:
;		    LPT3 CORRESPONDENCE VALUE:
;		0=COM1
;		1=COM2
;		2=COM3
;		3=COM4


lpt1_retry_type   DB	0	 ;holder of mask for status return byte 					;AN000;
lpt2_retry_type   DB	0	 ;can be one of no_retry_flag, error_status,					;AN000;
lpt3_retry_type   DB	0	 ;busy_status or ready_status, see MODEPRIN				       ;AN000;

;PUBLIC lpt1_retry_type


;THE FOLLOWING AREA IS USED BY MODESCRN TO STORE THE VIDEO PARMS THAT
;ALLOW FOR THE SHIFTING RIGHT OR LEFT OF THE SCREEN IMAGE.
SCRNTABL DB	16 DUP("PARM")		;64 BYTES OF SPACE
NEW_SCRNTABL equ (SCRNTABL - MODETO)	;OFFSET INTO RESIDENT
;			CODE OF THE 64 BYTE SCREEN TABLE

request     DB	  0	      ;holder for INT 14 or INT 17 request passed in AH
retry_type  DW	  0	      ;holder for INT 14 retry type and shift count

;MODEPTS ENDP

rescode_length	  =	((($ - ENTPT) / 16) + 1)	;length of resident code in paragraphs

MOVELEN =	($ - ENTPT)	;length of resident code in bytes


;*******************************************************************************

	SUBTTL	LOAD THE RESIDENT PORTION OF MODE

	PAGE


MODELOAD:
;	PUBLIC	MODELOAD
;		    GET THE CONTENTS OF INT VECTOR 14H
;		    TO SEE IF THE RESIDENT CODE IS
;		    ALREADY LOADED
;		    SET UP REGS TO MOVE IT INTO PLACE
   PUSH    DS			   ;SAVE SEG REG
   PUSH    ES			   ;SAVE SEG REG
   PUSH    DI
   PUSH    SI			   ;SAVE FOR CALLING PROCEDURE
   PUSH    DX			   ;SAVE FOR CALLING PROCEDURE
   PUSH    AX			   ;SAVE FOR CALLING PROCEDURE
   PUSH    BX
   MOV	   AX,0 		   ;GET THE PARAGRAPH NUMBER OF DESTINATION
   MOV	   ES,AX		   ; TO THE EXTRA SEGMENT BASE
   LES	   DI,[es:RESSEG]   ;GET POINTER TO RETRY CODE
;  IF THE CODE IS NOT ALREADY MOVED,
   .IF <DI EQ 0>, NEAR	;AC000;IF nothing at 50:30 THEN code is not loaded
;
;		    SINCE CODE HAS NOT YET BEEN MOVED,
;		    PATCH PROPER ADDRESSES INTO IT

;     .IF <retry_requested EQ true> AND      ;AN000;
;     .IF <device_type EQ COMX> THEN	     ;AN000;
;
;	 XOR	 AX,AX
;	 MOV	 ES,AX		     ;BACK TO THE VECTOR AT ZERO
;	 MOV	 AX,WORD PTR ES:VECT14H ;GET THE VECTOR OF INT 14H
;	 MOV	 VECTOR14+1,AX	     ; INTO CODE TO BE MOVED
;
;	 MOV	 AX,WORD PTR ES:VECT14H[2] ;MOVE REST OF VECTOR
;	 MOV	 VECTOR14+3,AX
;
;     .ENDIF				     ;AN000;
;
;     .IF <device_type EQ LPTX> AND	     ;AN000;
;     .IF <retry_requested EQ true> OR	     ;AN000;
;     .IF <reroute_requested EQ true> THEN   ;AN000;
;
;	 MOV	 AX,WORD PTR ES:VECT17H ;GET VECTOR OF INT 17H
;	 MOV	 VECTOR17+1,AX	     ; INTO CODE TO BE MOVED
;
;	 MOV	 AX,WORD PTR ES:VECT17H[2] ;MOVE REST OF VECTOR
;	 MOV	 VECTOR17+3,AX
;
;     .ENDIF				     ;AN000;


      PUSH    ES		  ;SAVE POINTER TO VECTOR ZERO

;Get and save previous interrupt handlers

      GET_INT_VECT 14H		    ;get vector of INT 17H, ES:BX=vector
      MOV     [VECTOR14+1],BX ;put offset INTO CODE TO BE MOVED
      MOV     [VECTOR14+3],ES ;save segment

      GET_INT_VECT 17H		    ;get vector of INT 17H, ES:BX=vector
      MOV     [VECTOR17+1],BX ;put offset INTO CODE TO BE MOVED
      MOV     [VECTOR17+3],ES ;save segment


      MOV     SI,ENTPT          ;WILL BE MOVED FROM HERE
      MOV     DI,move_destination        ;WILL BE MOVED TO HERE
      MOV     CX,MOVELEN	  ;NUMBER OF BYTES TO BE MOVED
      PUSH    CS		  ;GET SEGMENT OF PROGRAM HEADER
      POP     ES		  ; INTO ES, THE DESTINATION SEGMENT
      CLD			  ;INCREMENT SI AND DI AFTER EACH BYTE IS MOVED
      REP     MOVSB		  ;MOVE CX BYTES FROM DS:SI TO ES:DI
      POP     ES


;Put a pointer to the resident code 50:30 (0:530)

      CLI			  ;DISABLE UNTIL VECTOR SET

      MOV   word [es:RESSEG],MODETO             ;offset of "modeto" in res code pointer
      MOV   AX,CS
      SUB   AX,adjustment_in_paragraphs 	   ;adjust res CS by amount the code moved
      MOV   word [es:RESSEG+2],AX        ;store segment of res code in pointer

      STI			   ;allow some interrupts

;Set interrupts 14 and 17 to point to their respective handlers.  AX has correct segment.

      MOV   DS,AX				   ;DS=resident code segment
      MOV   DX,MODETO             ;DS:DX=> INT14 handler "modeto"
      SET_INT_VECT  INT14

      MOV   DX,MODEPTS             ;DS:DX=> INT17 handler "modepts"
      SET_INT_VECT  INT17

      MOV   ES,[cs:environ_seg] ;ES=segment of the block to be returned
      MOV   AH,49H		 ;49 is the Free Allocated Memory function call
      INT   21H 		 ;free the environment

      MOV     byte [cs:1],27H     ;SET EXIT TO REMAIN RESIDENT by dorking opcode in the PSP
;
      PUSH  CS
      POP   DS		;"PRINTF" requires that DS be the segment containing the messages

      DISPLAY moved_msg 	  ;"Resident portion of MODE loaded"
      MOV     byte [cs:LOADED_YET],1   ;SET FLAG TO INDICATE ABOVE MSG
;				   HAS BEEN DISPLAYED
;				   MODESCRN MAY NEED TO REPEAT MESSAGE
      MOV     byte [stay_resident],TRUE
   .ENDIF			   ;AC000;END IS CODE ALREADY LOADED? TEST

	POP	BX
	POP	AX			;RESTORE FOR CALLING PROCEDURE
	POP	DX			;RESTORE FOR CALLING PROCEDURE
	POP	SI			;RESTORE FOR CALLING PROCEDURE
	POP	DI
	POP	ES			;RESTORE SEG REG
	POP	DS			;RESTORE SEG REG
	RET
;MODELOAD ENDP

;************************************************************
	SUBTTL	COMMON PARMAMETER DES_STRT_PACKET.LIST AND WORKAREA
	PAGE
; THE FOLLOWING AREA IS USED TO STORE PARSED PARAMETER LIST, AND WORK STORAGE
; USED BY OTHER MODULES

;ษอออออออออออออออออออออ  N O N	 R E S I D E N T   D A T A  ออออออออออออออออออออออออออออออป
;บ											  บ

CTRL_ST DB	5 DUP(24)		;PRINTER CONFIGURATION CONTROL STRING
PARM1_	DB	10 DUP(0)
PARM2	DB	-1			;-1 INDICATES TO SERVER THAT THIS PARM IS UNCHANGED
PARM3	DB	0
MODE	DB	0
FLAG	DB	0
INDEX	DW	00			;REDIRECTED PRINTER NETWORK REDIRECTION LIST INDEX
IS_LOCAL DB	TRUE			;INITIALIZE for MODEPRIN
LOADED_YET DB	false
LOCAL_NAME DB	16 DUP(0)		;HOLDING AREA FOR GET ASSIGN LIST ENTRY CALL USE
machine_type  DB 0FFH			;holder for the machine type
NOERROR DB	TRUE			;INDICATE NO ERROR MESSAGES HAVE BEEN ISSUED YET
NEW_VIDEO_PARMS_OFFSET DW 090H		;OFFSET OF INIT TABLE FOR SCREEN SHIFTING
NEW_VIDEO_PARMS_SEGMENT DW 040H 	;SEGMENT OF INIT TABLE FOR SCREEN SHIFTING
REMOTE_DEV DB	50 DUP(0)		;HOLDING AREA FOR GET ASSIGN LIST ENTRY CALL USE
stay_resident	  DB	false		;boolean indicating should stay resident when terminate
submodel_byte	  DB	0FFH		;secondary model byte


;บ											  บ
;ศอออออออออออออออออออออ  N O N	 R E S I D E N T   D A T A  ออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;PUBLIC	PARM1_,PARM2,PARM3,MODE,FLAG,CTRL_ST,INDEX,LOCAL_NAME,REMOTE_DEV       ;AC000;
;PUBLIC	IS_LOCAL
;PUBLIC	LOADED_YET
;PUBLIC	machine_type		;holder for machine type, found in "main"
;PUBLIC	NOERROR
;PUBLIC	NEW_VIDEO_PARMS_OFFSET
;PUBLIC	NEW_VIDEO_PARMS_SEGMENT
;PUBLIC	stay_resident

;บ											  บ
;ศอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออผ

end if
;	END	ENTPT
