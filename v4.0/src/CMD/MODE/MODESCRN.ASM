PAGE ,132 ;
TITLE MODESCRN.ASM - SCREEN SUPPORT FOR THE MODE COMMAND

.XLIST
include 'STRUC.INC'
.LIST

include 'COMMON.STC' ;definitions of message sublist blocks ;AC001;

;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป				   ;AN000;
;บ											  บ				   ;AN000;
															   ;AN000;
;  AC000 - P3200: Was displaying a message that Sam Nunn had deleted from the
;		  USA.MSG file because it looked like a common message.  Now
;		  I use a different (better) message.  It was "Invalid paramters",
;		  is now "Function not supported - ????".

;  AX001 - P3976: Need to have all pieces of messages in MODE.SKL so have to
;		  implement the SYSGETMSG method of getting addressability to
;		  the pieces.  This means that the code does a SYSGETMSG call
;		  which returns a pointer (DS:SI) to the message piece.  The
;		  address is then put in the sublist block for the message
;		  being issued.

;  AX002 - P5159: Need to use get extended country call (6523) to get the yes
;     7-14-88	  no answer

;บ											  บ				   ;AN000;
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ				   ;AN000;

;ษออออออออออออออออออออออออออออออออ  M A C R O S  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

macro BREAK X
{
   JMP	   ENDCASE_#X#_modescrn
}


macro SCRN COMMAND,MOD
{
		      MOV    AH,COMMAND ;REQUEST FUNCTION OF SCREEN BIOS
 match any$, MOD \{
		      MOV    AL,MOD	;SET MODE TO SCREEN
 \}
		      INT    10H	;CALL BIOS SCREEN HANDLER
;
}
;
macro DISPLAY MSG
{
match any$, MSG \{
	MOV	DX,MSG
\}
	CALL	PRINTF
}


macro SET_LEFT_SHIFT_LIMIT 
{
	local	LIMIT_SET
;	ASSUME	DS:ROM_BIOS
;
	PUSH	DS
	PUSH	AX
	MOV	AX,ROM_BIOS_SEG
	MOV	DS,AX
	CMP	byte [ds:MACHINE_TYPE_ROM],JUNIOR ;IF this machine is a Junior THEN
	JNE	LIMIT_SET
	  MOV	byte [cs:LEFT_LIMIT],JR_LEFT_LIMIT   ;USE THE JUNIOR'S LEFT LIMIT
	LIMIT_SET:
	POP	AX
	POP	DS
;
;	ASSUME	DS:PRINTF_CODE
;
}

macro set_submessage_ptr submessage,message
{

MOV   AX,[submessage]			     ;AX=message number 		;AN001;
MOV   DH,Utility_Msg_Class		     ;DH=message class=utility class	;AN001;
CALL  SYSGETMSG 			     ;DS:SI=>message piece				  ;AN001;
MOV   BP,sublist_#message             ;address the sublist control block ;AN001;
MOV   [BP+sublist_def.sublist_off],SI ;the sublist now points to the desired message piece ;AN001;
} ;AN001;


;---------------------------------------------------------------------------
;   SET_UP_FOR_PRINTF
;PRINTF depends on DS containing the segment that the messages are in, so if
;DS is being used to address data areas elsewhere it needs to be temporarily
;set to the message file segment.
;---------------------------------------------------------------------------
;
macro SET_UP_FOR_PRINTF 
{

	PUSH	DS		;SAVE DS
	PUSH	CS
	POP	DS		;DS NOW HAS MESSAGE SEGMENT
;
}

;----------------------------------------------------------------------------
;   REPLACE_DS
;Replace the contents DS had before the PRINTF call. Assume that DS was pushed.
;-----------------------------------------------------------------------------

macro REPLACE_DS 
{

	POP	DS
;
}

;บ											  บ
;ศออออออออออออออออออออออออออออออออ  M A C R O S  อออออออออออออออออออออออออออออออออออออออออผ

CURRENT_VIDEO_STATE EQU 15 ;REQUEST TO BIOS SCREEN TO RETURN SCREEN STATE
SET_SCREEN_MODE EQU 0	      ;REQUEST TO BIOS SCREEN TO SET SCREEN MODE
COL40	 EQU	1	 ;FLAG BIT TO REQUEST 40 COL
COL80	 EQU	2	 ;FLAG BIT TO REQUEST 80 COL
CNT4	 EQU	4	 ;COUNT NO. TIMES TO DISPLAY "NUMBERS" FOR 40COL
CNT8	 EQU	8	 ;COUNT NO. TIMES TO DISPLAY "NUMBERS" FOR 80COL
FORTY	 EQU	40	 ;SCREEN WIDTH
MONO_MODE EQU	7	 ;MONOCHROME SCREEN MODE
no	 EQU	 0	;AC002;value to compare with when user responds with no character
NOEXIT	  EQU	 0		  ;EXIT SWITCH VALUE TO REPEAT LOOP
EXIT	  EQU	 1		  ;EXIT SWITCH VALUE TO LEAVE LOOP
YES	  EQU	  1	;AC002;value AX will be if user types yes character ("y", "s", "j" etc)
;





;	 OFFSETS INTO VIDEO TABLE, AT 40:90
SHIFCT40 EQU	02H		  ;SHIFT COUNT FOR 40 COL
SHIFCT80 EQU	012H		  ;SHIFT COUNT FOR 80 COL
SHIFCTGR EQU	022H		  ;SHIFT COUNT FOR GRAPHICS
CR	    EQU    13		  ;CARRIAGE RETURN
LF	    EQU    10		  ;LINE FEED
BEEP	    EQU    7		  ;SOUND THE AUDIBLE ALARM
LOWERCASE   EQU    20H		  ;ADD THIS TO UPPER, GET LOWER CASE
TRUE	EQU	0FFH

RIGHT_LIMIT EQU    01	  ;SAME FOR ALL TYPES OF MACHINES
JUNIOR	    EQU    0FDH 	  ;MACHINE TYPE SIGNITURE FOR PC JUNIOR
JR_LEFT_LIMIT  EQU 031H 	  ;LEFT LIMIT FOR SCREEN SHIFT ON PC JUNIOR
;
EGA_SIG 	EQU	0AA55H	  ;SIGNITURE FOR THE EGA CARD
;
if SEGSEL = S_ABSOLUTE
virtual at 0F000H
	ORG	0FFFEH
;
label MACHINE_TYPE_ROM byte   ;MACHINE TYPE BURNED IN ROM
;
end virtual
end if

ROM_BIOS_SEG	EQU	0F000H
;
if SEGSEL = S_ABSOLUTE
virtual at 0C000H;SEGMENT OF EGA AREA
	ORG	0
SIGWORD rw      1 ;SIGNITURE OF THE EGA IS STORED HERE IF THE CARD IS PRESENT
end virtual
end if
;
if SEGSEL = S_PRINTF_CODE
;     ASSUME CS:PRINTF_CODE,DS:PRINTF_CODE
;


;ษอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;PUBLIC	 HANDLE_40_OR_80	 ;make available to "ANALYZE_AND_INVOKE"
;PUBLIC	 SHIFT_SCREEN		 ;make available to "ANALYZE_AND_INVOKE"


;บ											  บ
;ศอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;EXTRN CANT_SHIFT:WORD	    ;CR,LF,"Unable to shift screen",BEEP,EOM
;EXTRN PRINTF:NEAR		;interface to message service ROUTINE
;EXTRN SCRNTAB:NEAR		;LOADS VIDEO INIT TABLE RETURNING POINTER TO IT
;
;EXTRN PARM1:BYTE,PARM2:BYTE,PARM3:BYTE,MODE:BYTE,FLAG:BYTE
;PARM1	DB	10 DUP(0)
;PARM2	DB	0
;PARM3	DB	0
;MODE	DB	0
;FLAG	DB	0
;EXTRN NEW_VIDEO_PARMS_SEGMENT:WORD
;EXTRN	NOERROR:BYTE		  ;INDICATE IF AN ERROR OCCURED YET
ENDPARM EQU	MODE
;EXTRN	ALT_SELECT:ABS		;INT 10 FUNCTION GET MONITOR TYPE
;EXTRN	EGA_INFO:ABS		;INT 10 FUNCTION GET INFO
;EXTRN	COLOR_ON_IT:ABS 	;INT 10 RETURN FOR COLOR MONITOR HOOKED TO EGA
;
LEFT_LIMIT  DB	   02EH 	  ;SCREEN SHIFT LEFT LIMIT, MAY BE Revised
;
SWITCH	  DB	 0		  ;LOOP CONTROLLER
;AC000;OK	 DB	1		 ;INDICATOR OF VALID REQUEST:
;				     1=BAD, 0=GOOD
;
;EXTRN L_item_tag:ABS			  ;see MODEpars.asm	  ;AN000;
;EXTRN R_item_tag:ABS			  ;see MODEpars.asm	  ;AN000;
;EXTRN T_item_tag:ABS			  ;see MODEpars.asm	  ;AN000;

;EXTRN RIGHTMOST:WORD	;message number for "rightmost 9",EOM	;AC001;
;EXTRN LEFTMOST:WORD    ;message number for "leftmost 0",EOM	;AC001;
;AC001;EXTRN LFTM_OR_RGHTM_PTR:WORD
;EXTRN SHIFT_MSG:WORD	    ;CR,LF,"Do you see the ...",CR,LF,EOM ;AX000;
;AC000;EXTRN MSGI:WORD	  ;CR,LF,"Invalid parameters",BEEP,CR,LF,"$"	 ;AX000;
;EXTRN NUMBERS:WORD   ;"0123456789"				  ;AX000;
;EXTRN LEFT:WORD 		;message number for "left",EOM	  ;AC001;
;EXTRN RIGHT:WORD		;message number for "right",EOM   ;AC001;
;AC001;EXTRN LEFT_OR_RIGHT_PTR:WORD	      ;PART OF MESSAGE "Unable to shift screen ..."
;EXTRN sublist_cant_shift:BYTE	 ;definition of submessage ;AC001;
;EXTRN sublist_shift_msg:BYTE	 ;definition of submessage ;AC001;
;EXTRN SYSGETMSG:NEAR		 ;used to get the address of a message part ;AC001;
;EXTRN utility_msg_class:ABS	 ;input for sysgetmsg	;AC001;


;บ											  บ
;ศอออออออออออออออออออออออออออออออ  E X T R N S	ออออออออออออออออออออออออออออออออออออออออออผ



;----------------------------------------------------------------------------


HANDLE_40_OR_80:                ;AN000;

;      SCREEN WIDTH IN BL
;
       SCRN   CURRENT_VIDEO_STATE,0 ;GET CURRENT SCREEN MODE
       MOV    [ds:MODE],AL   ;STORE CURRENT MODE
;      IF THE REQUEST WAS FOR 40 COL,
       CMP    BL,FORTY		  ;COMPARE WITH BL, OUTPUT FROM 'MODELENG'
       JNE    ELSE01_modescrn
;
;AC000;  MOV	OK,0		    ;INDICATE A LEGAL FUNCTION DONE
;	 CASE	current mode =

;	    0,
;	    2,
;	    5,
;	    6,
;	    7,
;	    11:

			   .IF <<[ds:MODE]> EQ 0>, OR
			   .IF <<[ds:MODE]> EQ 2>, OR
			   .IF <<[ds:MODE]> EQ 5>, OR
			   .IF <<[ds:MODE]> EQ 6>, OR
			   .IF <<[ds:MODE]> EQ 7>, OR
			   .IF <<[ds:MODE]> EQ 011H>
	       MOV   byte [ds:MODE],0 ;SWITCH TO 40 COL, BW
	       BREAK 0
			   .ENDIF

;	    1,
;	    3,
;	    4,
;	    12,
;	    13:

			   .IF <<[ds:MODE]> EQ 1>, OR
			   .IF <<[ds:MODE]> EQ 3>, OR
			   .IF <<[ds:MODE]> EQ 4>, OR
			   .IF <<[ds:MODE]> EQ 012H>, OR
			   .IF <<[ds:MODE]> EQ 013H>
	       MOV   byte [ds:MODE],1 ;SWITCH TO 40 COL, COLOR
	       BREAK 0
			   .ENDIF


	 ENDCASE_0_modescrn:


	 SCRN	SET_SCREEN_MODE,[ds:MODE] ;SWITCH TO 40 COL
;      ELSE ,SINCE REQUEST NOT FOR 40 COL,
       JMP    SHORT ENDIF01_modescrn
ELSE01_modescrn:
;    : : IF REQUEST FOR 80 COL
	 CMP	BL,80
	 JNE	ENDIF02_modescrn
;
;AC000;    MOV	  OK,0		    ;INDICATE A LEGAL FUNCTION DONE
  ;	   CASE   current mode =

  ;	      0,
  ;	      2,
  ;	      5,
  ;	      6,
  ;	      7,
  ;	      11:

			     .IF <<[ds:MODE]> EQ 0>, OR
			     .IF <<[ds:MODE]> EQ 2>, OR
			     .IF <<[ds:MODE]> EQ 5>, OR
			     .IF <<[ds:MODE]> EQ 6>, OR
			     .IF <<[ds:MODE]> EQ 7>, OR
			     .IF <<[ds:MODE]> EQ 011H>
		 MOV   byte [ds:MODE],2 ;SWITCH TO 80 COL, BW
		 BREAK 1
			     .ENDIF

  ;	      1,
  ;	      3,
  ;	      4,
  ;	      12,
  ;	      13:

			     .IF <<[ds:MODE]> EQ 1>, OR
			     .IF <<[ds:MODE]> EQ 3>, OR
			     .IF <<[ds:MODE]> EQ 4>, OR
			     .IF <<[ds:MODE]> EQ 012H>, OR
			     .IF <<[ds:MODE]> EQ 013H>
		 MOV   byte [ds:MODE],3 ;SWITCH TO 80 COL, COLOR
		 BREAK 1
			     .ENDIF


	   ENDCASE_1_modescrn:

	   SCRN   SET_SCREEN_MODE,[ds:MODE]
;    : : ENDIF ,END REQUEST FOR 80 COL
ENDIF02_modescrn:
;    : ENDIF ,END REQUEST FOR 40 COL
ENDIF01_modescrn:


RET		     ;AN000;

;HANDLE_40_OR_80   ENDP			  ;AN000;


;------------------------------------------------------------------------------


SHIFT_SCREEN:                  ;AN000;shift the screen

;    DO SHIFT UNTIL HE CAN SEE END CHAR
     MOV    byte [SWITCH],NOEXIT ;SET TO REPEAT NEXT LOOP
DO01:
;    : IF second PARM (sd) IS AN "R"?
       CMP   byte [ds:PARM2],R_item_tag ;AC000;
       JE    SKIP03				;IT'S AN R SO TRY TO SHIFT RIGHT
       JMP   ELSE03_modescrn				;NOT AN R SO CHECK FOR L
;
       SKIP03:
;AC000;  MOV	CS:OK,0 	  ;INDICATE A LEGAL FUNCTION DONE
	 SCRN	CURRENT_VIDEO_STATE,0		;CHECK CURRENT VIDEO MODE
	 CMP	AL,MONO_MODE			;IF mode >= mono THEN must be EGA mono so ...
;	 IF$	GE
	 JNGE IF1$$S
;AC001;    MOV	LEFT_OR_RIGHT_PTR,OFFSET RIGHT	  ;YELL BECAUSE CAN'T SHIFT AN EGA OR MONO
	   set_submessage_ptr right,CANT_SHIFT	  ;set up message sublist with pointer to "right"
	   DISPLAY	CANT_SHIFT		  ;YELL BECAUSE CAN'T SHIFT AN EGA OR MONO
;	 ELSE$	LONG				  ;JUMP PAST SHIFT LOOP
	 JMP EN1$$S
IF1$$S:
;
CHECK_FOR_EGA:					;SEE IF SCREEN IS HOOKED TO EGA
	MOV	AX,0C000H			;GET TO SEGMENT OF SIGNITURE WORD
	MOV	ES,AX				;ADDRESS THROUGH ES
	CMP	word [es:SIGWORD],EGA_SIG   ;IF EGA card being used THEN
	JNE	TRY_TO_SHIFT
	  MOV	  AH,ALT_SELECT   ;AH GETS INT FUNCTION SPECIFIER
	  MOV	  BL,EGA_INFO	  ;SPECIFY IN BL THE OPTION OF THE FUNCTION OF INT 10 WE
	  MOV	  BH, COLOR_ON_IT ;protect against RT PC problem
	  not	  bh		  ; masm 5.0 won't allow "not color_on_it"
	  INT	  10H		  ;RETURN MONITOR TYPE HOOKED TO EGA IN BH
	  CMP	  BH,COLOR_ON_IT   ;IF COLOR HOOKED TO EGA THEN
	  JNE	  TRY_TO_SHIFT
;AC001;     MOV  LEFT_OR_RIGHT_PTR,OFFSET RIGHT  ;  YELL BECAUSE CAN'T SHIFT AN EGA
	    set_submessage_ptr right,CANT_SHIFT    ;set up message sublist with pointer to "right"
	    DISPLAY	 CANT_SHIFT
	    JMP  ELSE05_modescrn 			 ;  JUMP PAST SHIFT LOOP
;
TRY_TO_SHIFT:
	 CALL	SCRNTAB 	  ;LOAD VIDEO TABLE IN WORK AREA
;	     DS NOW POINTS TO THE SEGMENT WHERE THE VIDEO TABLE WAS MOVED TO.
;	     BX HAS THE NEW OFFSET OF THE VIDEO TABLE

	  CMP	  byte [ds:BX+SHIFCT40],RIGHT_LIMIT      ;IF haven't shifted max right THEN
	  JG	  SHIFT_RIGHT
	    SET_UP_FOR_PRINTF
;AC001;     MOV 	LEFT_OR_RIGHT_PTR,OFFSET RIGHT
	    set_submessage_ptr right,CANT_SHIFT    ;set up message sublist with pointer to "right"
	    DISPLAY	CANT_SHIFT		;"Unable to shift screen right"
	    REPLACE_DS
	    JMP 	ELSE05_modescrn
  SHIFT_RIGHT:
	 MOV	AL,[ds:BX+SHIFCT40]  ;GET SHIFT COUNT FOR 40COL
	 SUB	AL,1		      ;SHIFT IT LEFT 1
	 MOV	[ds:BX+SHIFCT40],AL  ;STORE IT BACK
	 MOV	AL,[ds:BX+SHIFCT80]  ;GET SHIFT COUNT FOR 80COL
	 SUB	AL,2		      ;SHIFT LEFT 2
	 MOV	[ds:BX+SHIFCT80],AL  ;STORE IT BACK
	 MOV	AL,[ds:BX+SHIFCTGR]  ;GET GRAPHICS SHIFT COUNT
	 SUB	AL,1		      ;SHIFT LEFT 1
	 MOV	[ds:BX+SHIFCTGR],AL  ;STORE IT BACK
;    : ELSE ,SINCE PARM2 IS NOT AN "R"
       JMP ENDIF03_modescrn
ELSE03_modescrn:
;    : : IF THIS CHAR IS AN "L"?
	 CMP byte [ds:PARM2],L_item_tag ;AC000;
	 JE  SKIP05				;L WAS SPECIFIED SO TRY TO SHIFT LEFT
	 JMP	ELSE05_modescrn				;WASN'T "L" OR "R" SO DONT'T TRY TO SHIFT
;	     SINCE IT IS "L",
;
	 SKIP05:
;AC000;    MOV	  CS:OK,0		  ;INDICATE A LEGAL FUNCTION DONE
	   SCRN CURRENT_VIDEO_STATE,0		;CHECK CURRENT VIDEO MODE
	   CMP	AL,MONO_MODE			;IF mode >= mono THEN must be EGA or mono so ...
	   JB	CHK_FOR_EGA
;AC001;      MOV	LEFT_OR_RIGHT_PTR,OFFSET LEFT	  ;YELL BECAUSE CAN'T SHIFT AN EGA
	     set_submessage_ptr left,CANT_SHIFT    ;set up message sublist with pointer to "left" ;AC001;
	     DISPLAY	CANT_SHIFT
	     JMP	ELSE05_modescrn				  ;JUMP PAST SHIFT LOOP
;
	   CHK_FOR_EGA: 				;SEE IF SCREEN IS HOOKED TO EGA
	     MOV	AX,0C000H			;GET TO SEGMENT OF SIGNITURE WORD
	     MOV	ES,AX				;ADDRESS THROUGH ES
	     CMP	word [es:SIGWORD],EGA_SIG   ;IF EGA card being used THEN
	     JNE	TRY_TO_SHIFT_LEFT
	       MOV	  AH,ALT_SELECT   ;AH GETS INT FUNCTION SPECIFIER
	       MOV	  BL,EGA_INFO	  ;SPECIFY IN BL THE OPTION OF THE FUNCTION OF INT 10 WE
	       INT	  10H		  ;RETURN MONITOR TYPE HOOKED TO EGA IN BH
	       CMP	  BH,COLOR_ON_IT   ;IF COLOR HOOKED TO EGA THEN
	       JNE	  TRY_TO_SHIFT_LEFT
;AC001; 	 MOV	LEFT_OR_RIGHT_PTR,OFFSET LEFT	;  YELL BECAUSE CAN'T SHIFT AN EGA
		 set_submessage_ptr left,CANT_SHIFT    ;set up message sublist with pointer to "left"  ;AC001;
		 DISPLAY	CANT_SHIFT
		 JMP	ELSE05_modescrn				;  JUMP PAST SHIFT LOOP
;
TRY_TO_SHIFT_LEFT:
	   CALL   SCRNTAB	  ;LOAD VIDEO TABLE IN WORK AREA
;	     DS NOW POINTS TO THE SEGMENT OF THE RESIDENT CODE,
;	     WHERE THE VIDEO TABLE WAS MOVED TO.
;
	   SET_LEFT_SHIFT_LIMIT 	;SET LIMIT TO SUIT MACHINE TYPE
;
	   MOV	  AL,byte [ds:BX+SHIFCT40]      ;AL=current horizontal sync position
	   CMP	  AL,[cs:LEFT_LIMIT] ;IF haven't shifted max left THEN
	     JL 	  SHIFT_LEFT
	     SET_UP_FOR_PRINTF
;AC001;      MOV	LEFT_OR_RIGHT_PTR,OFFSET LEFT
	     set_submessage_ptr left,CANT_SHIFT    ;set up message sublist with pointer to "left"  ;AC001;
	     DISPLAY	CANT_SHIFT
	     REPLACE_DS
	     JMP	ELSE05_modescrn
  SHIFT_LEFT:
	   MOV	  AL,[ds:BX+SHIFCT40]  ;GET SHIFT COUNT 40COL
	   ADD	  AL,1		      ;SHIFT RIGHT ONE
	   MOV	  [ds:BX+SHIFCT40],AL  ;STORE IT BACK
	   MOV	  AL,[ds:BX+SHIFCT80]  ;GET SHIFT COUNT 80COL
	   ADD	  AL,2		      ;SHIFT RIGHT 2
	   MOV	  [ds:BX+SHIFCT80],AL  ;STORE IT BACK
	   MOV	  AL,[ds:BX+SHIFCTGR]  ;GET GRAPHICS COUNT
	   ADD	  AL,1		      ;SHIFT RIGHT 8 PIXELS
	   MOV	  [ds:BX+SHIFCTGR],AL  ;STORE IT BACK
;    : : ELSE ,SINCE CHAR IS NEITHER "R" NOR "L", QUIT
	 JMP	SHORT ENDIF05_modescrn
;	 ENDIF$ ;EGA or MONO
EN1$$S:
ELSE05_modescrn:
	   MOV	  byte [cs:SWITCH],EXIT ;REQUEST LOOP BE TERMINATED
;    : : ENDIF ,END IS THIS CHAR AN "L"? TEST
ENDIF05_modescrn:
;    : ENDIF END, IS PARM2 AN "R"? TEST
ENDIF03_modescrn:

;PUBLIC	 ENDIF03_modescrn

       MOV    AX,CS		  ;RESTORE THIS SEG
       MOV    DS,AX		  ; TO DS
;    LEAVE IF THE EXIT SWITCH IS SET
;AC001;     CMP    SWITCH,EXIT
;AC001;     JE	   ENDDO01
     .IF <<[SWITCH]> NE EXIT>, NEAR
;
       SCRN CURRENT_VIDEO_STATE,0
       MOV    [ds:MODE],AL ;SAVE CURRENT MODE
;	     LEAVING CURRENT MODE IN AL,
       SCRN   SET_SCREEN_MODE	  ;RESET IN CURRENT MODE
;    : IF THIS IS "T"
       CMP    byte [ds:PARM3],T_item_tag ;AC000;
       JNE    ELSE06_modescrn
;
;	 DECIDE WHICH QUESTION TO DISPLAY...
;    : : IF REQUESTED FUNCTION IS "R"
	 CMP	 byte [ds:PARM2],R_item_tag ;AC000;
	 JNE	 ELSE08_modescrn

;AC001;    MOV	   LFTM_OR_RGHTM_PTR,OFFSET LEFTMOST
	   set_submessage_ptr leftmost,SHIFT_MSG   ;set up message sublist with pointer to "leftmost"  ;AC001;
;    : : ELSE ,SINCE WAS NOT "R"
	 JMP	 SHORT ENDIF08_modescrn
ELSE08_modescrn:
;AC001;    MOV	   LFTM_OR_RGHTM_PTR,OFFSET RIGHTMOST
	   set_submessage_ptr rightmost,SHIFT_MSG   ;set up message sublist with pointer to "rightmost"  ;AC001;
;    : : ENDIF END FUNCTION IS "R"? TEST
ENDIF08_modescrn:

;	 decide how many times to display "0123456789"
	 OR	byte [ds:MODE],01H ;SET UP TO TEST FOR COLOR OR B/W
	 MOV	CX,CNT8 	  ;(GUESS IT IS 80COL) SET LOOP CTR TO 8
;    : : IF 40 COL?
	 CMP	byte [ds:MODE],COL40
	 JNE	ENDIF07_modescrn
;
	   MOV	  CX,CNT4	  ;(FIX ABOVE GUESS) SET LOOP CTR TO 4
;    : : ENDIF ,END IS IT 40 COL? TEST
ENDIF07_modescrn:
;
	 .REPEAT
	    SCRN   SET_SCREEN_MODE,[ds:MODE] ;clear the screen
	    PUSH  CX		    ;save loop counter
	    DO02:		      ;DO UNTIL LINE IS DISPLAYED across entire screen
	       DISPLAY NUMBERS	      ;DISPLAY 0123456789
;	    ENDDO WHEN CNT IN CX = 0
	    LOOP    DO02
	    DISPLAY   SHIFT_MSG     ;AN000;DISPLAY QUESTION, msg services will do the keyboard input, see modedefs.inc
	    MOV    DL,AL	    ;AC002;DL=character user entered
	    MOV   AX,6523H	    ;AN002;yes no check get extended error
	    INT   21H		    ;AN002;AX returned with indication of yes or no
	    POP   CX		    ;restore loop counter
	 .UNTIL <AX EQ YES>, OR
	 .UNTIL <AX EQ no>
;    : : IF RESPONSE IS "Y"
	 CMP	AL,YES
	 JNE	ENDIF09_modescrn
	   MOV	  byte [SWITCH],EXIT ;TERMINATE THE LOOP
;    : : ENDIF ,END IS RESPONSE "N"? TEST
ENDIF09_modescrn:
;    : ELSE ,SINCE "T" NOT SPECIFIED
       JMP    SHORT ENDIF06_modescrn
ELSE06_modescrn:
	 MOV	byte [SWITCH],EXIT ;TERMINATE THE LOOP
;    : ENDIF ,END IS THIS "T"? TEST
ENDIF06_modescrn:
;    LEAVE IF EXIT SWITCH IS SET
     CMP    byte [SWITCH],EXIT
     JE     ENDDO01
;
;    ENDDO GO BACK AND SHIFT MORE
     JMP    DO01
     .ENDIF
ENDDO01:
;
;    IF NO LEGAL FUNCTIONS DONE,
;AC000;;    CMP    OK,0
;AC000;     JZ	   ENDIF10

;AC000;       DISPLAY MSGI		 ;FUSS ABOUT ILLEGAL PARAMETERS
;    ENDIF ,END ARE NO LEGAL FUNCTIONS DONE? TEST
;AC000;ENDIF10:
     RET			  ;RETURN TO MODE MAIN ROUTINE
;SHIFT_SCREEN	ENDP			;AN000;
end if
;	 END
