PAGE ,132 ;
TITLE MODEECHO - REDIRECT PRINTER OUTPUT FROM PARALLEL TO SERIAL

.XLIST
include 'STRUC.INC'
.LIST

include 'COMMON.STC' ;definition of parm_list_entry struc

macro DISPLAY MSG
{
	MOV	DX,MSG
	CALL	PRINTF
}

macro SET REG,VALUE
{
	PUSH	AX
	MOV	AX,VALUE
	MOV	REG,AX
	POP	AX
}


;*****************************************************************
if SEGSEL = S_ABSOLUTE
virtual at 0
		ORG	50H
;VECT14H 	LABEL	DWORD	;RS232 CALL, WILL POINT TO MODETO AFTER
				; RESIDENT CODE IS LOADED.
		ORG	400H
RS232_BASE	rw      1 ;ADDR OF RS232 ADAPTER FOR COM1
		DW	?	;ADDR OF RS232 ADAPTER FOR COM2
		DW	?	;ADDR OF RS232 ADAPTER FOR COM3
		DW	?	;ADDR OF RS232 ADAPTER FOR COM4
;
		ORG	408H
PRINTR		rw      1 ;LPT1
		DW	?	;LPT2
		DW	?	;LPT3
;
		ORG	530H
;RESSEG		DD	?	;VECTOR OF MODETO, IF RESIDENT,OR 0
end virtual
end if
;*****************************************************************
ascii_to_int_	EQU   0FH     ;ANDed with an ascii 0-9 value yeilds binary 0-9
CR		EQU	13	;CARRIAGE RETURN
LF		EQU	10	;LINE FEED
parm_list	equ	BP	;AN000; 					 ;AN000;
TO_SCREEN	EQU	9	;REQUEST OUTPUT TO SCREEN

;PUBLIC	       LPTNO	      ;used by modeprin and modepars
;PUBLIC		PRINTR
;PUBLIC	       display_printer_reroute_status

PAGE
;***************************************************************
if SEGSEL = S_PRINTF_CODE
;	ASSUME CS:PRINTF_CODE,DS:PRINTF_CODE,ES:NOTHING

;ษอออออออออออออออออออออออออออออออออออ  D A T A	ออออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

two	       DB    2	      ;used to change byte displacement to word disp. See 'modeecho'
LPTNO	       DB    0	      ;holder of ASCII form of the LPT number (1 thru 3)

;บ											  บ
;ศอออออออออออออออออออออออออออออออออออ  D A T A	ออออออออออออออออออออออออออออออออออออออออออผ

;EXTRN PARM1:BYTE,PARM2:BYTE,PARM3:BYTE,MODE:BYTE,FLAG:BYTE
;PARM1	DB	10 DUP(0)
;PARM2	DB	0
;PARM3	DB	0
;MODE	DB	0
;FLAG	DB	0
ENDPARM EQU	MODE
;EXTRN CRLF:BYTE 		    ;AN000;carriage return linefeed
;EXTRN	 parm_lst:BYTE		    ;AN000;
;EXTRN	illegal_device_ptr:WORD     ;AN000;pointer to bad com device name string
;EXTRN MODELOAD:NEAR
;EXTRN PRINTF:NEAR		;FORMATTED "C" LIKE SCREEN OUTPUT ROUTINE
;EXTRN REDIRMSG:WORD	     ;CR,LF,"LPT"
;EXTRN REDPT:BYTE		;" "
;				": rerouted to COM"
;EXTRN REDCOM:BYTE		;" "
;				":",CR,LF,"$"
;
;EXTRN NOTREMSG:WORD	     ;CR,LF,"LPT"
;EXTRN NOTREDPT:BYTE		 ;" "
;				": not redirected.",CR,LF,"$"
;EXTRN printer_reroute_mask:BYTE    ;mask for testing ptsflag1 to see if a printer is rerouted
;EXTRN ptsflag1:BYTE		    ;see rescode.sal
;EXTRN  ERR1:WORD	    ;"ILLEGAL DEVICE NAME"
;EXTRN resflag2:ABS	    ;see rescode
;EXTRN FIXUP:ABS 		;IN MODEPTS, OFFSET USED BY COND. JMP
;EXTRN OFFPTS:ABS		;WHERE MODEPTS IS RELATIVE TO BEGINNING
				; OF MODETO
;EXTRN NEW_PTSFLAG:ABS		;WHERE PTSFLAG1 IS IN THE RESIDENT CODE
				; RELATIVE TO BEGINING OF MODETO
;
;***************************************************************
VERIFY:
;	PUBLIC	VERIFY
;
	SUB	AX,AX		;CLEAR A REG
	MOV	ES,AX		;SET ES TO LOW MEMORY
;DETERMINE WHAT PRINTER IS INVOLVED (LOOK AT n OF LPTn:)
	MOV	AL,byte [ds:LPTNO]
	MOV	[REDPT],AL ;PUT n OF LPTn IN REDIRECT MESSAGE
	MOV	[NOTREDPT],AL ;AND INTO NOT REDIRECTED MSG
;	IF PRINTER DEVICE IS LPT1
	CMP	AL,"1"
	JNE	ELSEIF01A
;
	  MOV	AH,01H	 ;SET FLAG FOR LPT1
	  MOV	SI,1	;SAVE LPT NUMBER AS OFFSET TO FLAG BYTE ARRAY
;	ELSEIF PRINTER DEVICE IS LPT2
	JMP SHORT ENDIF01_modeecho
ELSEIF01A:
	CMP	AL,"2"
	JNE	ELSEIF01B
;
	  MOV	AH,02H	 ;SET FLAG FOR LPT2
	  MOV	SI,2	;SAVE LPT NUMBER AS OFFSET TO FLAG BYTE ARRAY
;	ELSEIF PRINTER DEVICE IS LPT3
	JMP SHORT ENDIF01_modeecho
ELSEIF01B:
;	CMP	AL,"3"
;	JNE	ELSE01
;
	  MOV	AH,04H	 ;SET FLAG FOR LPT3
	  MOV	SI,03	;SAVE LPT NUMBER AS OFFSET TO FLAG BYTE ARRAY
;	ELSE ,SINCE NONE OF THE ABOVE, MUST BE INVALID
;	JMP	SHORT ENDIF01
;ELSE01:
;	  DISPLAY ERR1		 ;FUSS ABOUT INVALID n OF LPTn
;	  MOV	AH,0		;SET FLAG TO INVALID
;	ENDIF ,END OF CHECK FOR DEVICE NO. IN LPTn
ENDIF01_modeecho:
;AT EXIT: AH=MASK FOR NEW_PTSFLAG REPRESENTING WHICH LPTn, (OR 0 IF n INVALID)
;	AH HAS 0000 0XXX , WHERE BIT ON REPRESENTS:
;		|| --LPT1
;		| ---LPT2
;		----LPT3
;	SI=SET TO HEX 1,2, OR 3 TO BE USED AS OFFSET BEYOND NEW_PTSFLAG
;	TO ADDRESS THE BYTES PTSFLAG2, PTSFLAG3, AND PTSFLAG4
;	(SEE MODECODE FOR BYTE DEFINITIONS)
	RET
;VERIFY	ENDP
;***************************************************************


MODEECHO:
;	PUBLIC MODEECHO


;INPUT:

;	SI=printer number value (one based)
;	AH=printer number mask: lpt1=1, lpt2=2, lpt3=4
;	AL=com number character
;	all values are known to be valid, but the existence of the com port has
;	  not been checked.


;REGISTER
;  USAGE :  DL - hold the binary COM number
;	    BX - general use




MOV   [REDCOM],AL ;PUT m OF COMm TO REDIRECT MESSAGE
PUSH  ES		;SAVE SEG REG
SET   ES,0

MOV   BH,AH			    ;save the lpt number
AND   AL,ascii_to_int_		    ;convert to 1 based integer
MOV   DL,AL			    ;FLAG FOR COM1, see 'ptsflag2' in 'rescode'
;see if the COM# ACTUALLY EXISTS
DEC   AL			    ;AL= 0 based com number
MUL   [two]     ;AL=disp from 40:0 of com port address word
MOV   AH,BH			    ;restore the lpt number
XOR   BX,BX			    ;prepare for byte move
MOV   BL,AL			    ;BX=disp from 40:0 of com port address word
.IF <<[es:RS232_BASE+BX]> NE 0>;IF the com adapter does exist THEN

   ;AT THIS POINT WE KNOW THAT LPTn AND COMm ARE BOTH LEGAL

   ;THE FOLLOWING IS WHERE THE APPROPRIATE ADDRESS WORD FOR THE PRINTER
   ;INVOLVED IS SET TO 0001H TO INDICATE TO BASIC THAT IT CAN OPEN THE
   ;DEVICE BECAUSE IT HAS BEEN REDIRECTED.  SEE TECH REF PAGE A-2
   ;RS232 AND PRINTER BASE.

	       SAL SI,1 	   ;2*SI TO GET TO THE APPROPRIATE WORD
   ;	   : : IF THE PRINTER ACTUALLY EXISTS
	       CMP [es:PRINTR-2+SI],0000H  ;IF THE WORD IS NONZERO THE
	       JNE ENDIF10_modeecho	   ;DEVICE EXISTS SO DON'T PUT A 1 THERE.
		 MOV	   [es:PRINTR-2+SI],0001H  ;PUT 0001H IN PRINTER WORD n
   ;	   : : ENDIF PRINTER EXISTS
   ENDIF10_modeecho:
	       SAR SI,1 	   ;RESTORE SI TO n OF LPTn
   ;
	       CALL	   MODELOAD	   ;WITHIN 'MODECODE' MODULE
   ;
   ;AH HAS A MASK SET BY THE 'VERIFY' PROC TO CORRESPOND TO THE LPTn
	       PUSH	   ES	   ;I'M ABOUT TO USE ES, SO I'LL SAVE IT
	       PUSH	   DI
	       LES	   DI,[es:RESSEG]  ;FETCH POINTER TO MODETO IN RESIDENT CODE
	       MOV	   BX,NEW_PTSFLAG  ; FROM MODETO INTO BX
	       ADD	   BX,DI   ;ES:BX IS ADDRESS OF PTSFLAG1 IN RESIDENT
				   ; CODE (PROC MODEPTS)
	       OR	   AH,byte [es:BX]        ;TURN ON THIS PRINTER'S BIT
	       MOV	   byte [es:BX],AH        ;RECORD WHICH LPT IS TO BE
						   ; REDIRECTED
   ;				   SI=LPTn, DL=COMm
	       DEC	   DL	   ;NOW DL=0 FOR COM1, DL=1 FOR COM2
   ;				   SINCE SI=1, 2, OR 3, THIS PUTS A 0 OR 1 INTO
   ;				    PTSFLAG2, PTSFLAG3, OR PTSFLAG4
	       MOV	   byte [es:BX+SI],DL      ;RECORD FOR THIS LPTn
   ;				    WHICH COMm THE LPTn IS REDIRECTED TO
	       POP	   DI
	       POP	   ES	   ;RESTORE SEG REG USED FOR CHECKING/SETTING ADDRESS
			   ; WORDS AND NEW_PTSFLAG
	       CALL	   ECHO     ;CHANGE JMP IN MODEPTS COPY IN LOW MEMORY
   ;				    SO PROPER LPTn GETS REDIRECTED
	       DISPLAY	   CRLF 					;AN000;
	       DISPLAY	   REDIRMSG

.ELSE				    ;valid com name, adapter not there
   MOV	 DI,0			    ;COM device name is always the first parm, the value of "LPTX[:]=value"    ;AN000;
   MOV	 BP,parm_lst          ;address the parm list via parm_list which is [BP]
   MOV	 CX,[parm_list+DI+parm_list_entry.value1] ;AN000;					     ;AN000;
   MOV	[illegal_device_ptr],CX   ;AN000;set up message with bad com device name string
   DISPLAY ERR1 		       ;"Illegal device name - COMX"
.ENDIF


	POP	ES			;RESTORE SEG REG
	RET
;MODEECHO ENDP
;***************************************************************
MODEECNO:
;	PUBLIC MODEECNO
;INPUT: PARM1 AREA HAS:
;	LPTN:
;	OF WHICH VERIFICATION HAS BEEN MADE OF ONLY:
;	L???:
	PUSH	ES		 ;SAVE SEG REG
	CALL	VERIFY		 ;VERIFY THE n OF LPTn
;		SET AH ACCORDINGLY
;		ON EXIT FROM VERIFY, ES=0
;
;	IF n OF LPTn IS OK
	CMP	AH,0
	JE	ENDIF06_modeecho
;	: IF IT IS POSSIBLE THAT REDIRECTION IS IN EFFECT
	  CMP	word [es:530H],0000H   ;HAS THE POINTER BEEN SET?
	  JE	ENDIF05_modeecho 	;SINCE THE POINTER HASN'T BEEN SET, THE
				; CODE HASN'T BEEN LOADED, THEREFORE
				; THE LPT CAN'T BE REDIRECTED, SO THERE
				; IS NO NEED TO UNREDIRECT IT
;		SINCE n OF LPTn IS OK,
;		AND SI HAS 1,2,OR 3 TO CORRESPOND TO n
;		AND AH HAS:
;		0000 0001 - LPT1
;		0000 0010 - LPT2
;		0000 0100 - LPT3
	    XOR 	AH,0FFH 	;NOW AL HAS
;				1111 1110 - LPT1
;				1111 1101 - LPT2
;				1111 1011 - LPT3
	    PUSH	ES	;SAVE ES=0, SET BY VERIFY
	    PUSH	DI		;WILL BE USED AS OFFSET IN SEGMENT 0
				;ES:=O
	    LES 	DI,[es:RESSEG] ;FETCH POINTER TO MODETO IN RESIDENT CODE
	    PUSH	BX	;TO AVOID 'TYPE MISMATCH' I PUT OFFSET
	    MOV 	BX,NEW_PTSFLAG	;FROM MODETO INTO BX
	    AND 	AH,byte [es:DI+BX]       ;CLEAR THIS PRINTER'S BIT
	    MOV 	byte [es:DI+BX],AH       ;RESTORE Revised FLAG BYTE
	    POP 	BX
	    POP 	DI
	    POP 	ES		;RESTORE ES=0
;
;LPTn IS BEING UNREDIRECTED.  IF THE PRINTER EXISTS, THE ADDRESS WORD FOR
;THAT DEVICE WILL NOT CONTAIN 0001H.  IF IT DOES CONTAIN 0001H, IT MUST BE SET
;TO 0000H SO BASIC WILL NOT ALLOW IT TO BE OPENED.  SEE PROCEDURE MODEECHO
;IN THIS MODULE, AND TECH REF PAGE A-2 (RS232 AND PRINTER BASE).
;
	    SAL 	SI,1	;SI=WORD n FOR LPTn
;	: : IF THE DUMMY PRINTER EXISTS
	    CMP 	[es:PRINTR-2+SI],0001H	;DOES THE PRINTER EXIST?
	    JNE 	ENDIF07_modeecho ;  IF SO, DON'T MESS WITH THE ADDRESS WORD
	      MOV	[es:PRINTR-2+SI],0000H	;IF NOT, ZERO THE ADDRESS WORD
;	: : ENDIF PRINTER EXISTS
ENDIF07_modeecho:
	    SAR 	SI,1	;RESTORE SI TO n OF LPTn
;				 SO PROPER LPTn GETS REDIRECTED
;
;IF THE PRINTER EXISTS THE ADDRESS WORD IS NOW WHAT IT STARTED OUT AS
;AT POWER UP INITIALIZATION TIME. IF THE PRINTER DOESN'T EXIST, THE ADDRESS
;WORD IS NOW EQUAL TO 0000H.
;
	    CALL	ECHO		;GO INFORM THE RESIDENT CODE
;
ENDIF05_modeecho:
	    DISPLAY	CRLF	       ;AN000;carriage return linefeed
	    DISPLAY	NOTREMSG
;	: ENDIF IS REDIRECTION IN EFFECT
;	ENDIF IS n OF LPTn OK?
ENDIF06_modeecho:
	POP	ES		;RESTORE SEG REG
;
;A RETURN CODE IS PASSED BACK TO THE CALLER, MODEPRIN.
;AH=0 MEANS INVALID LPTn
;AH not= 0 MEANS LPTn IS OK
;
	RET			;RETURN TO CALLER
;MODEECNO ENDP
;***************************************************************
ECHO:
;'MODEPTS' STARTS WITH THREE INSTRUCTIONS:
;	F6 C2 01	TEST  DL,1
;	75 05		JNZ   CK
;	EA ---- ----	JMP   0F000H:PRINTER_IO
;		CK: (REDIRECT TO COMm)
;'PTSFLAG' HAS A FLAG BYTE SHOWING WHICH LPTn GETS REDIRECTED.
;THIS CODE HERE IS TO MODIFY THE FIRST TWO INSTRUCTIONS AT 'MODEPTS'
;SO REDIRECTED LPTn GOES TO 'CK:' AND OTHER LPTn GOES TO PRINTER_IO.
;
	PUSH   DI
	;ES:=0
	LES	DI,[es:RESSEG] ;FETCH POINTER TO MODETO IN RESIDENT CODE
	PUSH   BX		;TO AVOID 'TYPE MISMATCH' I PUT THE OFFSET
	PUSH	CX		;NEED A HOLDER FOR FIXUP
	MOV	BX,NEW_PTSFLAG	; FROM MODETO INTO BX
	MOV	AL,byte [es:DI+BX]       ;FIND WHICH LPTn GET REDIRECTED
	MOV	BX,DI		;PUT OFFSET OF MODETO INTO BX
	POP	DI
	ADD	BX,OFFPTS	;ADD OFFSET OF MODEPTS FROM MODETO, NOW
				; ES:BX POINTS TO MODEPTS
	MOV	CX,FIXUP	;HOLD FIXUP IN WORD FORM SO LINKER CAN FILL IN
	CLI			;IF AN INTERRUPT OCCURS HERE THE JUMP WOULD
				; BE INCORRECT
	MOV	byte [es:BX+4],CL      ;SET JUMP TARGET (CK) TO +3BH
	POP	CX		;RETURN FIXUP'S WORD FORM HOLDER
	MOV	AH,0		;CLEAR HIGH BYTE
	SHL	AL,1		;COUNT WAS 0,1,2,3,...7
;				COUNT IS NOW 0,2,4,6...14
	MOV	SI,AX		;GET INDEX OF BR TABLE ENTRY
	JMP	[SI+CASE_]
;
label CASE_ word
	DW	P0_modeecho
	DW	P1_modeecho
	DW	P2_modeecho
	DW	P3_modeecho
	DW	P4_modeecho
	DW	P5_modeecho
	DW	P6_modeecho
	DW	P7_modeecho
;
P0_modeecho:
;		SINCE NO PRINTER IS TO BE REDIRECTED
	MOV	word [es:BX+3],00EBH     ;MAKE JUMP INTO NO-OP
;		TO CAUSE 'FALL THRU' TO JMP 0F000H:PRINTER_IO INSTR
	JMP	SHORT ENDC_modeecho
P1_modeecho:
;	REDIRECT LPT1 ONLY
	MOV	word [es:BX+2],7403H     ;TEST 3 : JZ CK
	JMP	SHORT ENDC_modeecho
;
P2_modeecho:
;	REDIRECT LPT2 ONLY
	MOV	word [es:BX+2],7501H     ;TEST 1 : JNZ CK
	JMP	SHORT ENDC_modeecho
;
P3_modeecho:
;	REDIRECT LPT1 AND LPT2 ONLY
	MOV	word [es:BX+2],7402H     ; TEST 2 : JZ CK
	JMP	SHORT ENDC_modeecho
;
P4_modeecho:
;	REDIRECT LPT3 ONLY
	MOV	word [es:BX+2],7502H     ;TEST 2 :JNZ CK
	JMP	SHORT ENDC_modeecho
;
P5_modeecho:
;	REDIRECT LPT1 AND LPT3 ONLY
	MOV	word [es:BX+2],7401H     ;TEST 1 : JZ CK
	JMP	SHORT ENDC_modeecho
;
P6_modeecho:
;	REDIRECT LPT2 AND LPT3 ONLY
	MOV	word [es:BX+2],7503H     ;TEST 3 : JNZ CK
	JMP	SHORT ENDC_modeecho
;
P7_modeecho:
;	REDIRECT ALL THREE: LPT1, LPT2, AND LPT3
	MOV	word [es:BX+2],0EB00H     ;TEST 0 : JMP CK
ENDC_modeecho:
	STI			;REENABLE INTERRUPTS
	POP	BX
	RET
;ECHO	ENDP


;ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ					   ;AN000;
;ณ
;ณ DISPLAY_PRINTER_REROUTE_STATUS
;ณ ------------------------------
;ณ
;ณ  Setup message for the reroute status of the specified printer.
;ณ
;ณ  INPUT: BL - mask for ptsflag1 (1, 2 or 4)
;ณ	   REDPT - contains ASCII form of n OF LPTn in redirmsg "LPTn rerouted to COMm"
;ณ	   NOTREDPT - contains ASCII form of n of LPTn in message "LPTn not rerouted"
;ณ
;ณ
;ณ
;ณ  RETURN: REDCOM - filled with ASCII form of m OF COMm in MESSAGE "LPTn rerouted to COMn"none
;ณ
;ณ
;ณ
;ณ  MESSAGES:  REDIRMSG if the printer is rerouted
;ณ	       NOTREMSG if the printer is not rerouted
;ณ
;ณ
;ณ  REGISTER
;ณ  USAGE:
;ณ
;ณ
;ณ
;ณ  ASSUMPTIONS: input is valid
;ณ
;ณ
;ณ  SIDE EFFECT: ES - lost
;ณ		 SI - lost
;ณ															   ;AN000;
;ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ					   ;AN000;

display_printer_reroute_status:

XOR  CX,CX								;AN665;
MOV  ES,CX			       ;set segment to zero		;AN665;

.IF <<word [es:RESSEG]> NE 0000H>, AND   ;IF the resident code is loaded AND
MOV  ES,word [es:RESSEG+2]             ;AN665;
;;XOR	BX,BX
;;MOV	BL,printer_reroute_mask
TEST  BL,[es:PTSFLAG1]  ;see if the printer is rerouted
.IF NZ				     ;the printer is rerouted
   SHR	 BL,1	  ;was 1, 2, or 4, now is 0, 1, or 2
;;;INC	 BL	  ;now is 1, 2, or 3
;;;ADD	 BL,resflag2		    ;ES:BX=>the com byte for the desired printer
   ADD	 BX,RESFLAG2		    ;ES:BX=>the com byte for the desired printer
   .SELECT

      .WHEN <<byte [es:BX]> EQ 0>
	 MOV   byte [REDCOM],"1"    ;printer rerouted to COM1

      .WHEN <<byte [es:BX]> EQ 1>
	 MOV   byte [REDCOM],"2"    ;printer rerouted to COM2

      .WHEN <<byte [es:BX]> EQ 2>
	 MOV   byte [REDCOM],"3"    ;printer rerouted to COM3

      .WHEN <<byte [es:BX]> EQ 3>
	 MOV   byte [REDCOM],"4"    ;printer rerouted to COM4

   .ENDSELECT
   DISPLAY  REDIRMSG	   ;"LPTn rerouted to COMm"
.ELSE
   DISPLAY  NOTREMSG	   ;"LPTn not rerouted"
.ENDIF




RET

;display_printer_reroute_status	ENDP

end if
;	END
