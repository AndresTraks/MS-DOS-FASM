STRUC SUB_LIST DATA_OFF_=0, DATA_SEG_=0, MSG_ID_=0, FLAGS_=0, MAX_WIDTH_=0, MIN_WIDTH_=0, PAD_CHAR_=0
{
	DB	11			;AN000;
	DB	0			;AN000;
.DATA_OFF DW	DATA_OFF_ ;AN000; offset of data to be inserted
.DATA_SEG DW	DATA_SEG_ ;AN000; offset of data to be inserted
.MSG_ID	DB	MSG_ID_ ;AN000; n of %n
.FLAGS	DB	FLAGS_ ;AN000; Flags
.MAX_WIDTH DB	MAX_WIDTH_ ;AN000; Maximum field width
.MIN_WIDTH DB	MIN_WIDTH_ ;AN000; Minimum field width
.PAD_CHAR DB	PAD_CHAR_ ;AN000; character for pad field

}
match =SUB_LIST_LAID_OUT, SUB_LIST_LAID_OUT
{
    SUB_LIST_LAID_OUT equ 1
    virtual at 0
      SUB_LIST SUB_LIST
      sizeof.SUB_LIST = $ - SUB_LIST
    end virtual
}
	PAGE	,132			;
TITLE	XCPYINIT - XCOPY INITIALIZATION PROGRAM - Ver. 4.00

;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: XCPYINIT
;
; DESCRIPTIVE NAME: Called by XCOPY(MAIN) to perform initialization
;		    functions.
;
; FUNCTION:  Performs Parsing, Resource validation and Tagging, Error
;	     hooking and then returns to XCOPY(MAIN). This code will
;	     then be overwritten, providing additional memory for the
;	     copy process.
;
; ENTRY POINT: INIT
;
; INPUT: (DOS COMMAND LINE PARAMETERS)
;
;	      SOURCE OPERAND:			   TARGET OPERAND:
;
;	      [d:] [path] filename[.ext]	   [d:] [path] [filename[.ext]]
;		or
;	      [d:] path [filename[.ext]]
;		or
;	      d: [path] [filename[.ext]]
;
;	      SWITCHES:
;
;	      /A /D /E /M /P /S /V /W
;
; EXIT-NORMAL:	ERRORLEVEL_0 - This is the normal completion code.
;		ERRORLEVEL_2 - This is due to termination via Control-Break.
;		ERRORLEVEL_4 - This is used to indicate an error condition.
;
; INTERNAL REFERENCES:
;
;    ROUTINES:
;
;    DATA AREAS:
;
;
; EXTERNAL REFERENCES:
;
;    ROUTINES:
;
;    DATA AREAS:
;
;
; NOTES: This module should be processed with the SALUT pre-processor
;	 with the re-alignment not requested, as:
;
;		SALUT XCOPY,NUL,;
;
;	 To assemble these modules, the sequential
;	 ordering of segments may be used.
;
;	 For LINK instructions:
;		link  profile ..\lib
;
; REVISION HISTORY: A000 Version 4.00: add PARSER, System Message Handler,
;			 Remove the BELL char.,turn off APPEND during TREE
;			 search,Extended Attribute processing, Uppercasing
;			 and "Out Of Space" during write to standard out.
;		    NOTE: SEE XCOPY.SAL FOR TOTAL HISTORY.
;
;     Label: "The DOS XCOPY Utility"
;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licensed Material - Program Property of Microsoft"
;
;****************** END OF SPECIFICATIONS *****************************
;EQUATES
include 'XCOPY.EQU'
include 'DOS.EQU'
include 'VERSIONA.INC'

;
if SEGSEL = S_CSEG;PLACE HOLDER FOR INIT CODE
end if

;******************************************************************************

;DGROUP	GROUP	DSEG, DSEG_INIT
if SEGSEL = S_DSEG
;--- EXTERNAL VARIABLES ---
;EXTRN	ERRORLEVEL:BYTE
;EXTRN	PSP_SEG:WORD			;PSP segment ** USE OF ES SHOULD BE EXAMINED FURTHER
;EXTRN	SAV_DEFAULT_DRV:BYTE		;1 = A, 2 = B ...
;EXTRN	SAV_DEFAULT_DIR:BYTE
;EXTRN	SAV_S_DRV:BYTE
;EXTRN	SAV_S_CURDIR:BYTE
;EXTRN	SAV_T_DRV:BYTE
;EXTRN	SAV_T_CURDIR:BYTE
;EXTRN	TOP_OF_MEMORY:WORD
;EXTRN	S_DRV_NUMBER:BYTE		;source drive number, 1 = A, 2 = B ...
;EXTRN	T_DRV_NUMBER:BYTE		;target drive number
;EXTRN	SO_DRIVE:BYTE			;AN000;S DRIVE LETTER SPECIFIED IN PARSE
;EXTRN	S_DRV:BYTE
;EXTRN	S_DRV_1:BYTE
;EXTRN	S_DRV_PATH:BYTE 		;formal source drv, path
;EXTRN	S_PATH:BYTE
;EXTRN	T_DRV_PATH:BYTE 		;formal target drv, path
;EXTRN	T_PATH:BYTE
;EXTRN	TAR_DRIVE:BYTE			;AN000;T DRIVE LETTER SPECIFIED IN PARSE
;EXTRN	PARMS:DWORD			;AN000;PARSER PARAMETER CONTROL BLOCK
;EXTRN	CURRENT_PARM:WORD		;AN004;POINTER TO NEXT CMD LINE OPERAND
;EXTRN	T_DRV:BYTE			;target drv letter
;EXTRN	T_DRV_1:BYTE			;target drv letter
;EXTRN	T_DRV_2:BYTE
;EXTRN	S_FILE:BYTE			;source filename
;EXTRN	T_FILENAME:BYTE
;EXTRN	T_TEMPLATE:BYTE
;EXTRN	DISP_S_PATH:BYTE		;input mirror image source path
;EXTRN	DISP_T_PATH:BYTE		;input mirror image target path
;EXTRN	BUFFER_PTR:WORD
;EXTRN	BUFFER_BASE:WORD
;EXTRN	BUFFER_LEFT:WORD
;EXTRN	MAX_BUFFER_SIZE:WORD
;EXTRN	MAX_CX:WORD
;EXTRN	S_ARC_DRV:BYTE			;source drv, path for archieve bit handling
;EXTRN	S_ARC_PATH:BYTE
;EXTRN	T_MKDIR_LVL:BYTE		;# of target starting directories created.
;EXTRN	MSG_NUM:WORD			;AN000;MESSAGE NUMBER
;EXTRN	MSG_CLASS:BYTE			;AN000;MESSAGE CLASS
;EXTRN	INPUT_FLAG:BYTE 		;AN000;TYPE INT21 USED FOR KBD INPUT
;EXTRN	SUBST_COUNT:WORD		;AN000;MESSAGE SUBSTITUTION COUNT
;EXTRN	SUBLIST1:DWORD			;AN000;MSG SUBLIST USED BY INIT & MAIN
;
;EXTRN	MY_FLAG:BYTE
;EXTRN	SYS_FLAG:BYTE
;EXTRN	COPY_STATUS:BYTE
;EXTRN	OPTION_FLAG:BYTE
;
;EXTRN	INPUT_DATE:WORD
;EXTRN	INPUT_TIME:WORD
;
;
end if
;
if SEGSEL = S_DSEG_INIT;AN000;
;--- Local variables for INIT which will be free into memory after init.
;----include file(s)------
include 'XINITMSG.EQU' ;AN000;xcopy initialization, prompt msg
;----variables------------
S_INPUT_PARM DB 80 DUP (0)		;source image of input parm
T_INPUT_PARM DB 80 DUP (0)		;target image of input parm
T_TRANS_PATH DB 128 DUP (0)		;AN016;TARGET BUFFER FOR NAME TRANSLATE
S_TRANS_PATH DB 128 DUP (0)		;AN016;SOURCE BUFFER FOR NAME TRANSLATE

;PUBLIC	PARM_FLAG
PARM_FLAG DB	0
;	first_parm_flag equ	01h	;first parm entered in input parm
;	second_parm_flag equ	 02h	;second parm entered.
;	end_of_parm_flag equ	 04h	;end of parm reached
;	copy_onto_itself_flag equ     08h ;copy onto itself flag
;	cyclic_flag equ     10h 	;cyclic copy flag
;	inv_time_flag equ     20h	;invalid time
;	inv_date_flag equ     40h	;invalid date
;	init_error_flag equ    80h	;critical initialization error. Should abort.

PARM1_FLAG DB	0
;	inv_s_path_flag equ	01h	;invalid source path (path not found)
;	inv_t_path_flag equ	02h	;invalid target path
;	s_file_flag equ     04h 	;source filename entered
;	t_file_flag equ     08h 	;target filename entered
;	INV_SW_flag equ     10h 	;AN004;DUPLICATE OR INVALID SW ENTERED
;
TEMP_T_FILENAME DB 15 DUP (0)		;temporary target filename holder
FILENAME_FOR_PROMPT DB 15 DUP (0)	;upper case lettered TEMP_T_FILENAME for prompts
;** The following definitions are used for "Does ... specify a file name
;** or directory name (F:file, D:directory)?.
ALPHA_FILE rw      1 ;AN000;THIS IS THE TRANSLATION OF 'F'
ALPHA_DIR rw      1 ;AN000;THIS IS THE TRANSLATION OF 'D'
USER_INPUT rw      1 ;AC000;KEYBOARD SAVE - MAY BE DBCS -

Maxdays db	31,28,31,30,31,30,31,31,30,31,30,31 ;Max days per month
Day	rb      1 ;
Month	rb      1 ;
Year	rw      1 ;
Parmdate rw      1 ;date parameter used in file date
;
COUNTRY_INFO DB 34 DUP (0)
;-------------------------------
;    Structures
;-------------------------------


end if
;*******************************************************************************

if SEGSEL = S_CSEG;ATTACHED TO MAIN PROGRAM
;	ASSUME	CS:CSEG, DS:DGROUP, ES:DGROUP
;
;--- PUBLIC   PROCEDURES ---		;USED BY PARSER
;PUBLIC	GET_PARMS			;AN000;
;---------------------------

;--- EXTERNAL PROCEDURES ---
;EXTRN	SET_BUFFER_PTR:NEAR
;EXTRN	STRING_LENGTH:NEAR
;EXTRN	CONCAT_ASCIIZ:NEAR
;EXTRN	LAST_DIR_OUT:NEAR
;EXTRN	CHK_DBCS:NEAR			;AN010;NEEDED TO PARSE THE PATH STRING
;EXTRN	COMPRESS_FILENAME:NEAR
;EXTRN	CHK_DRV_LETTER:NEAR
;EXTRN	SET_DEFAULT_DRV:NEAR
;EXTRN	PRINT_STDOUT:NEAR
;EXTRN	PRINT_STDERR:NEAR
;EXTRN	MAIN_EXIT:NEAR
;EXTRN	MAIN_EXIT_A:NEAR
;EXTRN	CTRL_BREAK_EXIT:NEAR
;EXTRN	PARSER:NEAR			;AN000;PROCESS THE KBD INPUT STRING
;EXTRN	SYSGETMSG:NEAR			;AN000;TO GET THE 'F'ILE or 'D'IRECTORY
;EXTRN	MY_INT24:WORD
;---
;EXTRN	SAV_INT24_OFF:WORD		;int 24, critical error handler addr.
;EXTRN	SAV_INT24_SEG:WORD
;
;--- PARSER REFERENCES ---
;
;EXTRN	RESULT1:BYTE			;AN000;
;EXTRN	RESULT_PTR1:DWORD		;AN000;
;EXTRN	TYPE1:BYTE			;AN000;
;EXTRN	RESULT2:BYTE			;AN000;
;EXTRN	RESULT_PTR2:DWORD		;AN000;
;EXTRN	TYPE2:BYTE			;AN000;
;EXTRN	RESULTSW1:BYTE			;AN000;
;EXTRN	RESULTSWSYN:WORD		;AN000;
;EXTRN	SW_A:BYTE			;AN000;
;EXTRN	SW_E:BYTE			;AN000;
;EXTRN	SW_M:BYTE			;AN000;
;EXTRN	SW_P:BYTE			;AN000;
;EXTRN	SW_S:BYTE			;AN000;
;EXTRN	SW_V:BYTE			;AN000;
;EXTRN	SW_W:BYTE			;AN000;
;EXTRN	SW_D:BYTE			;AN000;
;EXTRN	DATE_YEAR:WORD			;AN000;
;EXTRN	DATE_MONTH:BYTE 		;AN000;
;EXTRN	DATE_DAY:BYTE			;AN000;
;---

;PUBLIC	INIT
INIT:
	CMP	AX, 0			;check drv validity
;	IF$	NE
	JE IF1$$I
	    MOV     DX, MSG_INVALID_DRV ;AC000;GET THE MESSAGE ID
	    OR	    byte [PARM_FLAG], INIT_ERROR_FLAG ;critical error. Abort
;	ELSE$
	JMP SHORT EN1$$I
IF1$$I:
	    CALL    HOOK_CTRL_BREAK	;hooks control break
	    CALL    SAV_HOOK_INT24	;hooks critical err handler
	    CALL    GET_CUR_DRV 	;save current default drv
	    MOV     DL, [SAV_DEFAULT_DRV]
	    LEA     SI,[SAV_DEFAULT_DIR]
	    CALL    GET_CUR_DIR 	;save current default dir
	    CALL    PARSE_INPUT_PARM
	    TEST    byte [PARM_FLAG], INIT_ERROR_FLAG
;	    IF$     Z			;no error
	    JNZ IF3$$I
		CALL	TOP_OF_MEM	;set top_of_memory
		CALL	INIT_BUFFER	;init buffer information

		MOV	DL, [S_DRV_NUMBER]
		DEC	DL
		CALL	SET_DEFAULT_DRV ;set source as a default drv
;	    ENDIF$
IF3$$I:
;	ENDIF$
EN1$$I:
	TEST	byte [PARM_FLAG], INIT_ERROR_FLAG ;any error?
;	IF$	NZ			;yes. critical error
	JZ IF6$$I
	    CMP     DX,MSG_INV_SW	;AN004;MSG REQUIRES SUB LIST
;	    IF$     NE,AND		;AC023;NO SUBLIST REQUIRED
	    JE IF7$$I
	    CMP     DX,MSG_INVALID_PARM ;AN004;MSG REQUIRES SUB LIST
;	    IF$     NE,AND		;AC023;NO SUBLIST REQUIRED
	    JE IF7$$I
	    CMP     DX,MSG_INV_NUM_PARM ;AN004;MSG REQUIRES SUB LIST
;	    IF$     NE			;AC023;NO SUBLIST REQUIRED
	    JE IF7$$I
		MOV	word [SUBST_COUNT],NO_SUBST ;AN000;NO SUBSTITUTION TEXT
		CMP	DX,SYSPRM_MISSING_OP ;AN024;OPERANDS MISSING(2) ERR?
;		IF$	E		;AN024;
		JNE IF8$$I
		    MOV DX,MSG_INV_NUM_PARM ;AN024;NO SUBLIST REQUIRED
;		ENDIF$			;AN024;
IF8$$I:
		MOV	[MSG_NUM],DX ;AN000;NEED MESSAGE ID FOR PRINT
;	    ELSE$			;AN004;SUBST LIST REQUIRED
	    JMP SHORT EN7$$I
IF7$$I:
		MOV	[MSG_NUM],DX ;AN004;NEED MESSAGE ID FOR PRINT
		MOV	word [SUBST_COUNT],PARM_SUBST_ONE ;AN004;PARM SUBST COUNT=1
;
		MOV	DX,[CURRENT_PARM] ;AN004;OFFSET TO BAD SWITCH
		LEA	SI,[SUBLIST1] ;AN004; address to sublist
		MOV	[SI+SUB_LIST.DATA_OFF],DX ;AN004; save data offset
		MOV	[SI+SUB_LIST.DATA_SEG],DS ;AN004; save data segment
		MOV	[SI+SUB_LIST.MSG_ID],0 ;AN023; message ID
		MOV	[SI+SUB_LIST.FLAGS],010H ;AN004; ASCIIZ str,l align
		MOV	[SI+SUB_LIST.MAX_WIDTH],0 ;AN004; MAXIMUM FIELD WITH
		MOV	[SI+SUB_LIST.MIN_WIDTH],0 ;AN004; MINIMUM FIELD WITH
;	    ENDIF$			;AN004;
EN7$$I:
	    MOV     byte [INPUT_FLAG],NO_INPUT ;AN000;NO INPUT = 0
	    MOV     byte [MSG_CLASS],UTILITY_MSG_CLASS ;AN000;MESSAGE CLASS = -1
	    CALL    PRINT_STDERR	;AN000;print error. AX point to msg ID
	    MOV     byte [ERRORLEVEL], 4 ;error ending
	    STC 			;set carry and exit to the main_exit
;	ELSE$
	JMP SHORT EN6$$I
IF6$$I:
	    CLC
;	ENDIF$
EN6$$I:
	RET
;INIT	ENDP

;
PARSE_INPUT_PARM:
;
	CALL	PARSER		    ;AN000;the PARSER interface routine
;	IF$	C		    ;AC000;if no non_delimiter chr?
	JNC IF14$$I
	    TEST    byte [PARM_FLAG],INIT_ERROR_FLAG ;AN000;PARM ERR HAS OCCURRED
;	    IF$     Z		    ;AN000;NO, MUST BE PARSER ERROR
	    JNZ IF15$$I
		OR	byte [PARM_FLAG],INIT_ERROR_FLAG ;AN000;SET THE FLAG
		CMP	AX,SYSPRM_EX_MANY ;AN000;TOO MANY OPERANDS (1) ERR?
;		IF$	E	    ;AN000;
		JNE IF16$$I
		    MOV     byte [SI],NUL     ;AN024;DELIMIT BAD PARM
		    MOV     DX,MSG_INV_NUM_PARM ;AN000;MSG NUM = 21
;		ELSE$		    ;AN000;
		JMP SHORT EN16$$I
IF16$$I:
		    CMP     AX,SYSPRM_DUP_SW ;AN004;DUPLICATE SW REQUESTED
;		    IF$     E	    ;AN004;
		    JNE IF18$$I
			MOV	byte [SI],NUL     ;AN004;DELIMIT BAD PARM
			MOV	DX,MSG_INV_SW ;AN004;MSG NUM = 35
;		    ELSE$	    ;AN004;
		    JMP SHORT EN18$$I
IF18$$I:
			CMP	AX,SYSPRM_MISSING_OP ;AN006;MISSING PARM=2
;			IF$	E   ;AN006;
			JNE IF20$$I
			    MOV     DX,AX     ;AN024 ;MSG NUM=21-NO SUBLIST
;			ELSE$	    ;AN006;
			JMP SHORT EN20$$I
IF20$$I:
			    MOV     byte [SI],NUL     ;AN024;DELIMIT BAD PARM
			    MOV     DX,MSG_INVALID_PARM ;AN000;MSG NUM = 3
;			ENDIF$	    ;AN006;
EN20$$I:
;		    ENDIF$	    ;AN004;
EN18$$I:
;		ENDIF$		    ;AN000;
EN16$$I:
;	    ELSE$		    ;AN006;INIT_ERROR_FLAG ALSO SET
	    JMP SHORT EN15$$I
IF15$$I:
		TEST	byte [PARM_FLAG],inv_date_flag ;AN006;WAS DATE INVALID?
;		IF$	NZ	    ;AN006;THE DATE IS INVALID
		JZ IF26$$I
		    MOV     DX,MSG_INVALID_DATE ;AN006;MSG NUM = 9
;		ENDIF$		    ;AN006;
IF26$$I:
;	    ENDIF$		    ;AN000;
EN15$$I:
;	ELSE$			    ;AN000;
	JMP SHORT EN14$$I
IF14$$I:
	    CALL    GET_DRIVES	    ;get source, target drive
	    TEST    byte [PARM_FLAG], INIT_ERROR_FLAG ;critical syntax error?
;	    IF$     Z		    ;if not,
	    JNZ IF30$$I
		CALL	CHK_SLASH_W ;with /w, show "Press any key to begin ... " msg.
		call	SAVE_FOR_DISPLAY ;save source, target parm for display purposes
		CALL	CHK_SET_PARMS ;check and set each parms.
		TEST	byte [PARM_FLAG], INIT_ERROR_FLAG ;critical syntax error?
;		IF$	Z	    ;no
		JNZ IF31$$I
		    call    MODIFY_FOR_DISPLAY ;set the source, target parm for display
;		ENDIF$
IF31$$I:
;	    ENDIF$
IF30$$I:
;	ENDIF$
EN14$$I:
	MOV	AL, 0
	LEA	DI,[S_PATH]
	CALL	STRING_LENGTH		;cx - # of chr
	LEA	SI,[S_PATH]
	LEA	DI,[S_ARC_PATH]
	REP	MOVSB			;s_path => s_arc_path
	RET
;PARSE_INPUT_PARM ENDP
;

CHK_SLASH_W:
;if /W option is specified, then
;show "Press any key to begin copying file(z)" message and wait for a key stroke.


	TEST	byte [OPTION_FLAG], slash_w ;/W option taken?
;	IF$	NZ			;yes.
	JZ IF35$$I
	    PUSH    AX			;AN000;
	    MOV     AX, MSG_TO_BEGIN	;AC000;GET THE MESSAGE ID
	    MOV     [MSG_NUM],AX ;AN000;SET THE MESSAGE NUMBER
	    MOV     word [SUBST_COUNT],NO_SUBST ;AN000;NO SUBSTITUTION TEXT
	    MOV     byte [INPUT_FLAG],DOS_KEYB_INP ;AN000;RESPONSE EXPECTED = 1
	    MOV     byte [MSG_CLASS],UTILITY_MSG_CLASS ;AN000;MESSAGE CLASS = -1
	    CALL    PRINT_STDOUT	;AN000;MSG AX points to message ID

	    MOV     AX,MSG_CR_LF_STR	;AN000; JUST CR,LF
	    MOV     [MSG_NUM],AX ;AN000; set message number
	    MOV     byte [INPUT_FLAG],NO_INPUT ;AN000; NO INPUT
	    CALL    PRINT_STDOUT	;AN000; Display message

	    POP     AX			;AN000;
;	ENDIF$
IF35$$I:
	RET

;CHK_SLASH_W ENDP
;
PROMPT_TO_USER:
;guide the user to enter the input parameters
;get user input to S_INPUT_PARM, T_INPUT_PARM for source, target parms.
;INPUT: ES - PSP seg
;	DS - data seg
;	SAV_DEFAULT_DRV
;
	MOV	dx, MSG_INV_NUM_PARM	;AC000;GET THE MESSAGE ID
	or	byte [PARM_FLAG], INIT_ERROR_FLAG
	RET
;PROMPT_TO_USER ENDP
;
GET_PARMS:
;Get the first parameter(s), second parameter(s) and option(s).
;Not checking correct character entered.
;The logic is:
;1). Find the first non_delim from the Parser control block. This is the
;    start of the first parm. Validate the length and put into S_INPUT_PARM.
; Note that this routine currently does not check the S_INPUT_PARM to see
;    if it is valid or not.
;2). Find the next non_delim from the Parser control block. This is the
;    start of the second parm. Validate the length and put into T_INPUT_PARM.
; Note that this routine currently does not check the T_INPUT_PARM to see
;    if it is valid or not.
;3). Find the switch(es) from the parser control block and set the
;    corresponding bit in the option flag word(OPTION_FLAG) by calling
;    GET_OPTIONS.
;
;INPUT:
;      BX - PARSER OPERAND POINTER

	PUSH	DS			;AN000;
	CMP	BX,RESULT1        ;AN000;WAS FIRST FILESPEC SPECIFIED?
;	IF$	E			;AN000;IF FIRST FILESPEC SPECIFIED,
	JNE IF37$$I
	    LDS     SI,[RESULT_PTR1] ;AN000;GET WHERE THE STRING IS
;	    ASSUME  DS:NOTHING		;AN000;
; MASM read a type name in an expression as the number of bytes it
; takes up, so BYTE on its own is 1 and WORD is 2.
	    CMP     byte [ds:SI+1],COLON        ;AN000;DOES FILESPEC START WITH
					;DRIVE?
;	    IF$     E			;AN000;STARTS WITH DRIVE
	    JNE IF38$$I
		LODSW			;AN000;GET JUST THE DRIVE LETTER AND
		MOV	[es:SO_DRIVE],AL ;AN000;ALSO ADJUSTS WHERE THE STRING IS
		LEA	DI,[es:S_INPUT_PARM] ;AN000;MOVE PARM TO SOURCE FILESPEC
		STOSW			;AN000;MOVE DRIVE TO FILESPEC
;	    ELSE$			;AN000;DOES NOT START WITH DRIVE
	    JMP SHORT EN38$$I
IF38$$I:
		LEA	DI,[es:S_INPUT_PARM] ;AN000;MOVE PARM TO SOURCE FILESPEC
;	    ENDIF$			;AN000;FILESPEC HAVE DRIVE?
EN38$$I:
	    CMP     byte [es:TYPE1],5 ;AN000;FILESPEC ?
;	    IF$     E			;AN000;MORE THAN JUST DRIVE
	    JNE IF41$$I
					;MOVE PARM TO WHERE FIND FIRST/NEXT
					; WILL KNOW WHERE TO START
		PUSH	BX		;AN000;SAVE THE DATABASE POINTER
		XOR	BX,BX		;AN000;ZERO FOR THE PARAMETER LENGTH
;		DO$	COMPLEX 	;AN000;
		JMP SHORT SD42$$I
DO42$$I:
		    INC     BX		;AN000;CALCULATE LENGTH
		    STOSB		;AN000;MOVE CHAR TO FILESPEC
;		STRTDO$ 		;AN000;
SD42$$I:
		    LODSB		;AN000;GET NEXT CHAR FROM COMMAND LINE
		    CMP     AL,NUL	;AN000;IS THAT THE END OF THE STRING
;		ENDDO$	E		;AN000;GOT IT ALL, QUIT
		JNE DO42$$I
		CALL	CHK_MAX_LENGTH	;AN000;LENGTH OF STRING <=64
		POP	BX		;AN000;RESTORE THE DATA BASE POINTER
;		IF$	NC		;no, less than or equal
		JC IF45$$I
		    OR	    byte [es:PARM_FLAG], first_parm_flag
;		ELSE$			;AN000;
		JMP SHORT EN45$$I
IF45$$I:
		    MOV     DX, MSG_LONG_PATH ;AN000;ADDRESS OF MESSAGE TXT
		    OR	    byte [es:PARM_FLAG], INIT_ERROR_FLAG ;AN000;
;		ENDIF$			;AN000;CRITICAL ERROR INDICATED
EN45$$I:
;	    ENDIF$			;AN000;MOVE ALL DONE
IF41$$I:
;	ELSE$				;AN000;IF SECOND FILESPEC SPECIFIED,
	JMP SHORT EN37$$I
IF37$$I:
	    CMP     BX,RESULT2        ;AN000;WAS 2nd FILESPEC SPECIFIED?
;	    IF$     E			;AN000;IF SECOND FILESPEC SPECIFIED
	    JNE IF50$$I
		LDS	SI,[es:RESULT_PTR2] ;AN000;GET WHERE THE STRING IS
;		ASSUME	DS:NOTHING	;AN000;
		CMP	byte [ds:SI+1],COLON        ;AN000;DOES FILESPEC START
					;WITH DRIVE?
;		IF$	E		;AN000;STARTS WITH DRIVE
		JNE IF51$$I
		    LODSW		;AN000;GET JUST THE DRIVE LETTER AND
		    MOV     [es:TAR_DRIVE],AL ;AN000;ALSO ADJUSTS WHERE THE STRING IS
		    LEA     DI,[es:T_INPUT_PARM] ;AN000;MOVE PARM TO TARGET FILESPEC
		    STOSW		;AN000;MOVE DRIVE TO FILESPEC
;		ELSE$			;AN000;DOES NOT START WITH DRIVE
		JMP SHORT EN51$$I
IF51$$I:
		    LEA     DI,[es:T_INPUT_PARM] ;AN000;MOVE PARM TO TARGET FILESPEC
;		ENDIF$			;AN000;FILESPEC HAVE DRIVE?
EN51$$I:
		CMP	byte [es:TYPE2],5 ;AN000;FILESPEC ?
;		IF$	E		;AN000;MORE THAN JUST DRIVE
		JNE IF54$$I
					;AN000;MOVE PARM TO WHERE FIND FIRST/NEXT
					;AN000; WILL KNOW WHERE TO START
		    PUSH    BX		;AN000;SAVE THE DATABASE POINTER
		    XOR     BX,BX	;AN000;ZERO FOR THE PARAMETER LENGTH
;		    DO$     COMPLEX	;AN000;
		    JMP SHORT SD55$$I
DO55$$I:
			INC	BX	;AN000;CALCULATE LENGTH
			STOSB		;AN000;MOVE CHAR TO FILESPEC
;		    STRTDO$		;AN000;
SD55$$I:
			LODSB		;AN000;GET NEXT CHAR FROM COMMAND LINE
			CMP	AL,NUL	;AN000;IS THAT THE END OF THE STRING
;		    ENDDO$  E		;AN000;GOT IT ALL, QUIT
		    JNE DO55$$I
		    CALL    CHK_MAX_LENGTH ;AN000;LENGTH OF STRING <=64
		    POP     BX		;AN000;RESTORE THE DATA BASE POINTER
;		    IF$     NC
		    JC IF58$$I
			OR	byte [es:PARM_FLAG], second_parm_flag
;		    ELSE$
		    JMP SHORT EN58$$I
IF58$$I:
			MOV	DX, MSG_LONG_PATH ;AN000;ADDRESS OF MESSAGE TXT
			OR	byte [es:PARM_FLAG], INIT_ERROR_FLAG ;AN000;
;		    ENDIF$		;AN000;CRITICAL ERROR INDICATED
EN58$$I:
;		ENDIF$			;AN000;SECOND FILESPEC
IF54$$I:
;	    ELSE$			;AN000;FILESPEC NOT SPECIFIED
	    JMP SHORT EN50$$I
IF50$$I:
		CALL	GET_OPTIONS	;AN000;PROCESS THE SWITCHES
;	    ENDIF$			;AN000;MOVE ALL DONE
EN50$$I:
;	ENDIF$				;AN000;FILESPEC?
EN37$$I:
	POP	DS			;AN000;
;	ASSUME	DS:DGROUP		;AN000;
	RET
;GET_PARMS ENDP
;
SAVE_FOR_DISPLAY:
;save first parm, second parm into DISP_S_PATH, DISP_T_PATH.
;at this time, this is not gauranteed to be a path. They may
;contains filename in it.
;input: S_INPUT_PARM, T_INPUT_PARM, PARM_FLAG
;	DS: data seg
;	ES: psp

	PUSH	ES			;save ES
	PUSH	DS
	POP	ES			;ES = DS
	TEST	byte [PARM_FLAG], first_parm_flag ;first parm entered?
;	IF$	NZ			;yes
	JZ IF65$$I
	    MOV     AL, 0		;asciiz
	    LEA     DI,[S_INPUT_PARM]
	    CALL    STRING_LENGTH	;now CX has length
	    LEA     SI,[S_INPUT_PARM]
	    LEA     DI,[DISP_S_PATH];source path for display
	    CALL    MOV_STRING		;AC000;s_input_parm => disp_s_path

;	ENDIF$
IF65$$I:
	TEST	byte [PARM_FLAG], second_parm_flag ;second parm entered?
;	IF$	NZ
	JZ IF67$$I
	    MOV     AL, 0
	    LEA     DI,[T_INPUT_PARM]
	    CALL    STRING_LENGTH
	    LEA     SI,[T_INPUT_PARM]
	    LEA     DI,[DISP_T_PATH]
	    CALL    MOV_STRING		;AC000;s_input_parm => disp_s_path
;	ENDIF$
IF67$$I:
	POP	ES
	RET
;SAVE_FOR_DISPLAY ENDP
;
MOV_STRING:            ;AN000;
; move string from DS:SI to ES:DI
; CX should indicate string length
	cld
;	DO$
DO69$$I:
	    CMP     CX, 0
;	LEAVE$	Z
	JZ EN69$$I
	    LODSB			;[si] => AL
	    STOSB			;AL => [di]
	    DEC     CX
;	ENDDO$
	JMP SHORT DO69$$I
EN69$$I:
	RET
;MOV_STRING ENDP 			;AN000;
;
MODIFY_FOR_DISPLAY:
;finally trims DISP_S_PATH, DISP_T_PATH into good shape.
;input: DS, ES = data seg. S_FILE_FLAG, T_FILE_FLAG

	LEA	DI,[DISP_S_PATH]
	LEA	SI,[DISP_S_PATH]
	TEST	byte [PARM1_FLAG], s_file_flag ;source filename entered?
	JZ	MFD_NO_FILE1		;no
	CALL	MASSAGE_DISP_PATH	;yes, entered.
	JMP	SHORT MFD_TARGET
MFD_NO_FILE1:				;no source filename
	CALL	CHK_DRV_LETTER		;using [si]
	JC	MFD_CHK_TAIL1
	CMP	byte [SI], 0     ;D:,0 case
	JE	MFD_TARGET		;OK
	CMP	byte [SI], '\'
	JNE	MFD_CHK_TAIL1		;D:dir... case
	CMP	byte [SI+1], 0     ;D:\,0 case
	JE	MFD_TARGET		;OK
MFD_CHK_TAIL1:				;else check tail
	CALL	CHK_TAIL_CHR		;chk tail and put \ at the end. using di
MFD_TARGET:
	LEA	DI,[DISP_T_PATH]
	LEA	SI,[DISP_T_PATH]
	TEST	byte [PARM1_FLAG], t_file_flag
	JZ	MFD_NO_FILE2
	CALL	MASSAGE_DISP_PATH
	JMP	SHORT MFD_EXIT
MFD_NO_FILE2:
	CALL	CHK_DRV_LETTER
	JC	MFD_CHK_TAIL2
	CMP	byte [SI], 0
	JE	MFD_EXIT
	CMP	byte [SI], '\'
	JNE	MFD_CHK_TAIL2
	CMP	byte [SI+1], 0
	JE	MFD_EXIT
MFD_CHK_TAIL2:
	CALL	CHK_TAIL_CHR
MFD_EXIT:
	RET
;MODIFY_FOR_DISPLAY ENDP
;
CHK_TAIL_CHR:
;check the last chr of ASCIIZ string pointed by DI.
;if it is \,0 then OK, else put \ there.
;DS, ES = data seg
;DI points to string.
;OUTPUT: Revised string.
;AX, BX, CX - destroyed
	MOV	AL, 0			;asciiz
	PUSH	DI			;save di
	CALL	STRING_LENGTH		;now cx got the length including 0
	POP	DI			;restore di
	DEC	CX
	DEC	CX
	MOV	BX, CX
	CMP	byte [DI+BX], '\'      ;last chr before 0
	JE	CTC_EXIT		;\,0 case
	MOV	byte [DI+BX+1], '\'      ;change 0 to '\'
	MOV	byte [DI+BX+2], 0      ;make it asciiz again.
CTC_EXIT:
	RET
;CHK_TAIL_CHR ENDP
;
MASSAGE_DISP_PATH:
;INPUT: DS, ES = data seg
;	DI = points to source. Used for LAST_DIR_OUT
;	SI = points to source. Used for CHK_DRV_LETTER routine
;OUTPUT: Revised source string

	CALL	LAST_DIR_OUT
;	IF$	C			;failure? no '\' found
	JNC IF72$$I
	    CALL    CHK_DRV_LETTER	;drive letter?
;	    IF$     NC			;yes. "D:filename",0 case
	    JC IF73$$I
		MOV	byte [ds:SI], 0     ;make it "D:",0 since SI now points to the next chr
;	    ELSE$			;no. "filename",0 case
	    JMP SHORT EN73$$I
IF73$$I:
		MOV	byte [DI], 0     ;set DISP_S_PATH to 0
;	    ENDIF$
EN73$$I:
;	ELSE$				;found '\' and last '\' became 0
	JMP SHORT EN72$$I
IF72$$I:
	    MOV     DI, AX		;we want to restore '\' and put 0 just after that.
	    DEC     DI			;for ex, "D:\filename"=>"D:"=>"D:\"
	    MOV     byte [DI], '\'     ;	 "D:dir1\dir2"=>"D:dir1"=>"D:dir1\"
	    MOV     byte [DI+1], 0
;	ENDIF$
EN72$$I:
	RET
;MASSAGE_DISP_PATH ENDP
;
CHK_MAX_LENGTH:
;Check the length of the source or target input string although this does not
;gaurantee the validity of the length of path.	This will just check/reduce
;the possibilities of long path.
;If the path string is longer than 64 (this includes 0 at the end of the string)
;then, carry will be set.
;INPUT: ds - data seg
;	es - psp seg
;	SI - points to the starting chr of the string.
;	BX - length of the string
;OUTPUT:
;	carry will set if the length if longer than we expected.

	PUSH	BX			;AN000;
	PUSH	DI
	PUSH	SI
					;AC001;DELETED CODE FOR PTM0011
	CMP	byte [SI], '\'     ;SI points to '\'?
	JNE	CML_LENGTH		;no, now compare the length
	DEC	BX			;AC000;decrease length by 1 for '\'
CML_LENGTH:
	CMP	BX, 63			;AC000;length of string > 63?
	JG	CML_CARRY		;AC027;WORK WITH ONLY + CMP RESULT
	CLC				;NO.  OK.
	JMP	CML_EXIT
CML_CARRY:
	STC				;not OK
CML_EXIT:
	POP	SI
	POP	DI
	POP	BX			;AN000;
	RET

;CHK_MAX_LENGTH ENDP
;
;
GET_OPTIONS:
;get options from the PARSER and
;set OPTION_FLAG.
;INPUT:
;      BX - PARSER OPERAND POINTER
;
	CMP	BX,RESULTSW1        ;AN000;WAS SW 1 THROUGH 7 SPECIFIED?
	MOV	DI,[RESULTSWSYN] ;AN000;GET THE SYNONYM POINTER [ES]

;	IF$	E,LONG			;AN000;IF SWITCH SPECIFIED
	JE XL1$$I
	JMP IF78$$I
XL1$$I:
	    CMP     byte [es:DI+1],ALPHA_S        ;AC000;"S"
	    JNE     GO_A
	    OR	    byte [OPTION_FLAG], slash_s ;set the walk the tree bit on.
	    MOV     byte [SW_S],SPACE ;AN004;DISALLOW DUPLICATE SWITCHES
	    JMP     GO_EXIT		;AC000;
GO_A:
	    CMP     byte [es:DI+1],ALPHA_A        ;AN000;"A"
	    JNE     GO_M
	    MOV     byte [SW_A],SPACE ;AN004;DISALLOW DUPLICATE SWITCHES
	    TEST    byte [OPTION_FLAG], slash_m ;hard archieve already on?
	    JZ	    GO_A1		;if not, continue
	    AND     byte [OPTION_FLAG], reset_slash_m ;else turn it off
GO_A1:
	    OR	    byte [OPTION_FLAG], slash_a ;set soft archieve
	    JMP     GO_EXIT		;AC000;
GO_M:
	    CMP     byte [es:DI+1],ALPHA_M        ;AN000;"M"
	    JNE     GO_P
	    MOV     byte [SW_M],SPACE ;AN004;DISALLOW DUPLICATE SWITCHES
	    TEST    byte [OPTION_FLAG], slash_a ;soft archieve already on?
	    JZ	    GO_M1		;if not, skip this part
	    AND     byte [OPTION_FLAG], reset_slash_a ;else turn off the soft archieve bit
GO_M1:
	    OR	    byte [OPTION_FLAG], slash_m ;turn on the hard archieve bit.
	    JMP     GO_EXIT		;AC000;
GO_P:
	    CMP     byte [es:DI+1],ALPHA_P        ;AN000;"P"
	    JNE     GO_E
	    MOV     byte [SW_P],SPACE ;AN004;DISALLOW DUPLICATE SWITCHES
	    OR	    byte [OPTION_FLAG], slash_p
	    OR	    byte [MY_FLAG], single_copy_flag ;if user want prompt, then should be single copy (not a multi copy).
	    JMP     SHORT  GO_EXIT	;AC000;
GO_E:
	    CMP     byte [es:DI+1],ALPHA_E        ;AN000;"E"
	    JNE     GO_V
	    MOV     byte [SW_E],SPACE ;AN004;DISALLOW DUPLICATE SWITCHES
	    OR	    byte [OPTION_FLAG], slash_e ;turn on "creating empty dir" bit.
	    JMP     SHORT  GO_EXIT	;AC000;
GO_V:
	    CMP     byte [es:DI+1],ALPHA_V        ;AN000;"V"
	    JNE     GO_W
	    MOV     byte [SW_V],SPACE ;AN004;DISALLOW DUPLICATE SWITCHES
	    MOV     AH, 54h		;get verify setting
	    INT     21H
	    CMP     AL, 0
	    JNE     GO_EXIT		;AC000;if not 0, then already on.
	    MOV     AX, 2E01h		;else set it on
	    INT     21h
	    OR	    byte [SYS_FLAG], turn_verify_off_flag ;don't forget it off when exit to dos.
	    JMP     SHORT   GO_EXIT	;AC000;
GO_W:
	    OR	    byte [OPTION_FLAG], slash_w
	    MOV     byte [SW_W],SPACE ;AN004;DISALLOW DUPLICATE SWITCHES
	    JMP     SHORT   GO_EXIT	;AC000;
;	ELSE$				;AN000;SINCE SWITCH 1 - 7 NOT SPECIFIED
	JMP SHORT EN78$$I
IF78$$I:
					; IT MUST BE THE DATE SWITCH
	    CALL    GET_INPUT_DATE	;AN000;get date from parser control block
	    OR	    byte [OPTION_FLAG], slash_d
	    MOV     byte [SW_D],SPACE ;AN004;DISALLOW DUPLICATE SWITCHES
;	ENDIF$				;AN000;
EN78$$I:
GO_EXIT:
	RET
;GET_OPTIONS ENDP

GET_INPUT_DATE:
;get the input date from the parser and save it to  INPUT_DATE form which
;it can be used for comparison with FILE_DATE_DTA.
;INPUT:
;
;
;OUTPUT:
;
;
;

	CALL	VALIDATE_INPUT_DATE	;AN006;GO CHECK THE DATE
;	IF$	C			;AN006;SET IF THE DATE WAS INVALID
	JNC IF81$$I
	    OR	    byte [PARM_FLAG],inv_date_flag ;AN006;SET THE FLAG FOR DATE ERROR
	    OR	    byte [PARM_FLAG],INIT_ERROR_FLAG ;AN006;SET THE FLAG FOR ERROR
;	ELSE$				;AN006;DATE WAS OK
	JMP SHORT EN81$$I
IF81$$I:
	    MOV     AX,[DATE_YEAR] ;AN000;GET YEAR FROM PARSER CTRL BLOCK
	    SUB     AX,1980		;AN000;SUBTRACT THE BASE YEAR
	    mov     cl,4		;AN000;SHIFT REG COUNT = 4
	    shl     ax,cl		;AN000;Shift it over 4
	    xor     dh,dh		;AN000;CLEAR THE AREA
	    mov     dl,[DATE_MONTH] ;AN000;GET MONTH FROM PARSER CTRL BLOCK
	    add     ax,dx		;AN000;Add in the Month
	    inc     cl			;AN000;BUMP SHIFT COUNT
	    shl     ax,cl		;AN000;Shift it over 5
	    xor     dh,dh		;AN000;CLEAR THE AREA
	    mov     dl,[DATE_DAY] ;AN000;GET DAY FROM PARSER CTRL BLOCK
	    add     ax,dx		;AN000;Add in the Day
	    mov     [INPUT_DATE],ax ;AN000;Store the date in DOS FCB format
	    CLC 			;AN000;CLEAR THE CARRY
;	ENDIF$				;AN006;
EN81$$I:
	RET
;GET_INPUT_DATE ENDP
;
VALIDATE_INPUT_DATE:
;CHECK FOR VALID DATE.
;
;OUTPUT: INVALID DATE = CARRY SET
;
;
;
;
	MOV	AH,Get_Date		;AN006;DOS INT 2AH
	INT	21H			;AN006;MAKE THE CALL
	PUSH	CX			;AN006;YEAR
	PUSH	DX			;AN006;MONTH,DAY
	MOV	AH,Set_Date		;AN006;DOS INT 2BH
	MOV	CX,[DATE_YEAR] ;AN006;GET YEAR FROM PARSER CTL BLOCK
	MOV	DH,[DATE_MONTH] ;AN006;GET MONTH FROM PARSER CTL BLOCK
	MOV	DL,[DATE_DAY] ;AN006;GET DAY FROM PARSER CTL BLOCK
	INT	21H			;AN006;MAKE THE CALL
	POP	DX			;AN006;GET THE SYSTEM MONTH,DAY
	POP	CX			;AN006;GET THE SYSTEM YEAR
	OR	AL,AL			;AN006;WAS MY INPUT DATE VALID?
	STC				;AN006;SET THE CARRY
	JNZ	ERR_DATE		;AN006;GET OUT WITH C SET
	CLC				;AN006;CLEAR THE CARRY, NO ERROR
	MOV	AH,Set_Date		;AN006;RESTORE THE SYSTEM DATE
	INT	21H			;AN006;MAKE THE CALL
ERR_DATE:				;AN006;
	RET				;AN006;
;
;VALIDATE_INPUT_DATE ENDP
;
CHK_SET_PARMS:
;This does a semantic checking on the given S_INPUT_PARM, T_INPUT_PARM and
;sets each of the starting drv path into S_PATH, T_PATH.
;The basic logic is:
;1). Try to change dir to a given S_INPUT_PARM.
;    if a success, then it must be the path. Chdir to it and get current
;    source directory using S_DRV_NUMBER by issuing GET_Current_directory call,
;    which starts from the root of the source drive.  In this way, you don't
;    have to worry about what type of path for the source has been entered.
;    You just try to chdir according to S_INPUT_PARM and
;    then call get_cur_dir to get the S_PATH which will always start
;    from the root of the source drive.
;    if not, then there must be the filename at the end, or there might be
;    garbage in the path.  So, take the last path name (which is, hopely,
;    a filename) and try chdir again.  If a success, then current source dir
;    is determined. Otherwise, error. Issue "Invalid direcory name". If a
;    success, then check the saved filename to make sure that there are no
;    invalid chr's in it. (When you try to take the last_dir_out, and
;    it has failed (carry set), then it was a filename candidate itself
;    (sometimes together with an drive id d:).	In this case, you have to
;    check the filename candidate if it has a drive id in front of it.
;    if it is, then take the drive id d: off from it and reshape the
;    filename candidate.  And check the invalid characters if any. Of cause
;    in this case, current direcory of source drv becomes S_PATH.
;2). Try to change dir to a given T_INPUT_PARM, if any. (If no T_INPUT_PARM
;    entered, then set current directory to the starting path of target using
;    T_DRV_NUMBER.)
;    If a success, then no problem.  It is a strating target path.
;    If not, then take the last dir out and try again.	If a failure, then
;    error "Invalid directory".
;    If a success, then check the saved filename to see if any illigal
;    characters in it.	If they are, then error. Else issue fun.29h
;    to see if there are any global characters in it.  If there
;    are, then assume a filename.  If there are not, then ask user
;    "Is XXXXX a filename in the target? (n)" If no, then it is a
;    subdirectory name.  Make a new subdirectory in the target and
;    concatenate a new directory name to the T_INPUT_PARM and chdir to
;    the new path (, which is the original path in fact) again.
;INPUT:
;	ES - PSP seg ; this will be changed to DS within this routine
;	DS - data seg

	PUSH	DS
	POP	ES			;set ES to DS
	TEST	byte [PARM_FLAG], first_parm_flag ;first parm entered?
;	IF$	Z,AND			;NO
	JNZ IF84$$I
	TEST	byte [PARM_FLAG], second_parm_flag ;second parm entered?
;	IF$	Z			;NO
	JNZ IF84$$I
	    MOV     DX, MSG_INV_NUM_PARM ;AC000;GET THE MESSAGE ID
	    OR	    byte [PARM_FLAG], INIT_ERROR_FLAG ;critical error. exit program
;	ELSE$
	JMP SHORT EN84$$I
IF84$$I:

	    MOV     DL, [S_DRV_NUMBER]
	    LEA     SI,[SAV_S_CURDIR]
	    CALL    GET_CUR_DIR 	;get and save current source directory
	    OR	    byte [SYS_FLAG], default_s_dir_flag ;indicates source dir saved
	    TEST    byte [PARM_FLAG], first_parm_flag ;first parm only entered?
;	    IF$     Z			;no first parm
	    JNZ IF86$$I
		LEA	SI,[S_PATH];then make current source dir as S_PATH
		CALL	GET_CUR_DIR
;	    ELSE$			;else first parm entered. check it
	    JMP SHORT EN86$$I
IF86$$I:
		LEA	DX,[S_INPUT_PARM];try to chdir to S_INPUT_PARM
		MOV	AH, Chdir	;= 3Bh
		INT	21h
;		IF$	NC		;success?
		JC IF88$$I
		    MOV     DL, [S_DRV_NUMBER]
		    LEA     SI,[S_PATH];get current dir and save it
		    CALL    GET_CUR_DIR ;as a starting dir to S_PATH
;		ELSE$
		JMP SHORT EN88$$I
IF88$$I:
		    LEA     BX,[S_INPUT_PARM]
		    LEA     DX,[S_FILE];source filename
		    CALL    TAKE_PATH_TAIL ;take out the tail part of S_INPUT_PARM
		    LEA     DX,[S_INPUT_PARM]
		    MOV     AH, Chdir	;= 3Bh
		    INT     21h 	;try chdir again
;		    IF$     NC,AND	;success?
		    JC IF90$$I
		    CMP     byte [S_FILE], 0 ;check s_file if something is there
;		    IF$     NE		;yes, filename entered.
		    JE IF90$$I
			MOV	DL, [S_DRV_NUMBER]
			LEA	SI,[S_PATH]
			CALL	GET_CUR_DIR ;save current dir
			OR	byte [PARM1_FLAG], s_file_flag ;source filename entered
			call	CHK_S_RESERVED_NAME ;is it a reserved name?
;		    ELSE$
		    JMP SHORT EN90$$I
IF90$$I:
			MOV	DX, MSG_INVALID_PATH ;AC000;GET THE MESSAGE ID
			OR	byte [PARM_FLAG], INIT_ERROR_FLAG ;critical error
;		    ENDIF$
EN90$$I:
;		ENDIF$
EN88$$I:
;	    ENDIF$
EN86$$I:
;	ENDIF$
EN84$$I:
	TEST	byte [PARM_FLAG], INIT_ERROR_FLAG
;	IF$	Z,LONG			;no error so far,
	JZ XL2$$I
	JMP IF96$$I
XL2$$I:
	    TEST    byte [SYS_FLAG], one_disk_copy_flag ;if one disk copy
;	    IF$     NZ			;then saved source default directory
	    JZ IF97$$I
		LEA	DX,[SAV_S_DRV];is the same as target current dir
		MOV	AH, Chdir	;=3Bh
		INT	21h		;so restore target default dir.
;	    ENDIF$
IF97$$I:
	    MOV     DL, [T_DRV_NUMBER]
	    LEA     SI,[SAV_T_CURDIR]
	    CALL    GET_CUR_DIR 	;save current target directory
	    OR	    byte [SYS_FLAG], default_t_dir_flag ;indicates target dir saved
	    TEST    byte [PARM_FLAG], second_parm_flag ;second parm has been entered?
;	    IF$     Z			;second parm not entered
	    JNZ IF99$$I
		LEA	SI,[T_PATH]
		CALL	GET_CUR_DIR	;make the current target dir as T_PATH
;	    ELSE$			;then deals with the second parm
	    JMP SHORT EN99$$I
IF99$$I:

		LEA	DX,[T_INPUT_PARM];try to chdir according to T_INPUT
		MOV	AH, Chdir
		INT	21h		;= 3Bh
;		IF$	C		;FAILURE?
		JNC IF101$$I
		    CALL    PARSE_SECOND_PARM
;		ENDIF$
IF101$$I:

		TEST	byte [PARM_FLAG], INIT_ERROR_FLAG ;no error so far?
;		IF$	Z		;no error
		JNZ IF103$$I
		    MOV     DL, [T_DRV_NUMBER]
		    LEA     SI,[T_PATH]
		    CALL    GET_CUR_DIR ;save target starting dir
		    CMP     byte [TEMP_T_FILENAME], 0 ;any non_global target file name entered?
;		    IF$     NE		;yes
		    JE IF104$$I
			MOV	CX, 13	;maximum 13 char.
			LEA	SI,[TEMP_T_FILENAME]
			LEA	DI,[T_FILENAME];then move it to T_FILENAME while convert it to capital letter.
			CALL	MOV_STRING ;AC000; SI => DI
;		    ENDIF$
IF104$$I:
;		ENDIF$			;end - no error so far
IF103$$I:
;	    ENDIF$			;end - second parm not entered
EN99$$I:
;	ENDIF$
IF96$$I:

	TEST	byte [PARM_FLAG], INIT_ERROR_FLAG
;	IF$	Z			;no error
	JNZ IF109$$I
	    CALL    CHK_CYCLIC_COPY	;check source, target parms
	    TEST    byte [PARM_FLAG], INIT_ERROR_FLAG ;cyclic copy?
;	    IF$     Z,AND		;no
	    JNZ IF110$$I
	    TEST    byte [SYS_FLAG], one_disk_copy_flag ;if one disk drv letter copy
;	    IF$     NZ			;then set the starting dir
	    JZ IF110$$I
		LEA	DX,[S_DRV_PATH];to that of source.
		MOV	AH, Chdir	; = 3Bh
		INT	21H		;should succeed since alreay tested.
;	    ENDIF$
IF110$$I:
;	ENDIF$
IF109$$I:

	RET
;CHK_SET_PARMS ENDP
;
PARSE_SECOND_PARM:
;called after the initial chdir to T_INPUT_PARM failed.  Remember the second parm should
;exist when you call this routine.
;INPUT: DS, ES - data seg
;OUTPUT:if error, init_error_flag will be set.
;
	LEA	SI,[T_INPUT_PARM]
	CALL	CHK_HEAD_PARM		;check the head part of parm. SI will points
					;to the next chr after the header.
	TEST	byte [PARM_FLAG], INIT_ERROR_FLAG
	JNZ	PSP_EXIT		;YES, ERROR.
	CALL	NEXT_PATH_DELIM 	;Let SI points to the next path delim "\" or 0
	LEA	DX,[T_INPUT_PARM]
	CALL	PARSING_T_PATH		;chdir for every directory starting from the
					;first. If it fails, then create a directory
					;and chdir to it.
PSP_EXIT:
	RET
;PARSE_SECOND_PARM ENDP
;
NEXT_PATH_DELIM:
;starting from SI, check every chr until it is '\' or 0 or ':'.
;if the starting chr is '\' or 0 or ':', then SI won't change.
;the caller should be sure that it is an ASCIIZ string.
;INPUT: DS, ES - data seg
;	SI - starting point
;OUTPUT:
;	SI - next path delimeter

	CLD
	PUSH	DI
	PUSH	SI
	POP	DI			;NOW DI POINTS TO THE STARTING CHR
NPD_LOOP:
;	DO$				;AN010;
DO113$$I:
	    CLC 			;AN010;INITIALIZE TO NOT DBCS
	    MOV     AL,byte [DI]     ;AN010;GET THE 1st CHAR TO TEST
	    CALL    Chk_DBCS		;AN010;SEE IF WE ARE IN DBCS
;	LEAVE$	NC			;AN010;THIS IS NOT DBCS
	JNC EN113$$I
	    INC     DI			;AN010;GO TO THE NEXT CHAR TO CHECK
	    INC     DI			;AN010;DITO
;	ENDDO$				;AN010;
	JMP SHORT DO113$$I
EN113$$I:
	MOV	AL, 0
	SCASB				;0 - ES:[DI], DI=DI+1
	JZ	NPD_FOUND
	DEC	DI			;check it again if it is '\'
	MOV	AL, '\'
	SCASB
	JZ	NPD_FOUND
	DEC	DI
	MOV	AL, ':' 		;is it a filename terminator not filter before?
	SCASB
	JZ	NPD_FOUND
	JMP	SHORT NPD_LOOP
NPD_FOUND:
	DEC	DI			;adjust DI to the chr found
	PUSH	DI
	POP	SI			;now SI points to the chr
	POP	DI			;restore DI
	RET
;NEXT_PATH_DELIM ENDP
;

CHK_HEAD_PARM:
;check the starting header part of parameter pointed by SI to eliminate
;error such as A:\\..., A:\.., \\, \.. etc.
;This routine will change the current target directory to the root
;when "d:\" or "\" has been found.
;The parameter string should be ASCIIZ and should exist.
;INPUT: DS, ES - DATA SEG
;	SI - POINTS TO THE PARAMETER
;OUTPUT:SI POINTS TO THE NEXT VALID PATH
;	DX WILL POINTS TO THE ERROR MESSAGE

	CALL	CHK_DRV_LETTER		;si points to the next chr after drv letter, if found.
	CMP	byte [SI], 0     ;"A:0" case
;	IF$	E
	JNE IF116$$I
	    MOV     byte [SI], '.'
	    INC     SI
	    MOV     byte [SI], 0     ;make it "A:.0"
;	ELSE$
	JMP SHORT EN116$$I
IF116$$I:
	    CMP     byte [SI], '\'
;	    IF$     E			;A:\--- or \--- cases
	    JNE IF118$$I
		INC	SI
		CLC			;AN010;INITIALIZE TO NOT DBCS
		MOV	AL,byte [ds:SI]     ;AN010;GET THE 1st CHAR TO TEST
		CALL	Chk_DBCS	;AN010;SEE IF WE ARE IN DBCS
;		IF$	NC		;AN010;THIS IS NOT DBCS
		JC IF119$$I
		    CMP     byte [SI], '\'
;		    IF$     E		;A:\\--- or \\--- cases ; ERROR
		    JNE IF120$$I
			MOV	DX, MSG_INVALID_PATH ;AC000;GET THE MESSAGE ID
			OR	byte [PARM_FLAG], INIT_ERROR_FLAG
;		    ELSE$
		    JMP SHORT EN120$$I
IF120$$I:
			CMP	byte [SI], '.'
;			IF$	E	;A:\.--- or \.--- cases
			JNE IF122$$I
			    INC     SI
			    MOV     AL,byte [ds:SI]     ;AN010;GET 1st CHAR
					;      TO TEST
			    CALL    Chk_DBCS ;AN010;SEE IF WE ARE IN
					;      DBCS
;			    IF$     NC	;AN010;THIS IS NOT DBCS
			    JC IF123$$I
				CMP	byte [SI], '.'
;				IF$	E,OR
				JE LL124$$I
				CMP	byte [SI], '\'
;				IF$	NE ;if not A:\.\--- or \.\--- cases
				JE IF124$$I
LL124$$I:
				    MOV     DX, MSG_INVALID_PATH ;AC000;MSG ID
				    OR	    byte [PARM_FLAG], INIT_ERROR_FLAG
;				ENDIF$
IF124$$I:
;			    ENDIF$	;AN010;END OF DBCS TEST
IF123$$I:
			    CLC 	;AN010;
;			ENDIF$
IF122$$I:
;		    ENDIF$
EN120$$I:
		    LEA     DX,[T_DRV]
		    MOV     AH, Chdir
		    INT     21h 	;"Chdir to root" is no problem.
;		ENDIF$			;AN010;DBCS TEST END
IF119$$I:
		CLC			;AN010;
;	    ENDIF$
IF118$$I:
;	ENDIF$
EN116$$I:
	RET
;CHK_HEAD_PARM ENDP
;
PARSING_T_PATH:
;chdir to every path element from the first. If fails, create the directory and
;try to chdir again.  T_MKDIR_LVL will increase when new starting directory is created
;INPUT: DX - OFFSET OF T_INPUT_PARM
;	SI - points to '\' or 0, or ':'
;OUTPUT: directories are created if necessary.
;	 DX points to the last path entry
;	 if fails to create a directory, then INIT_ERROR_FLAG set and
;	 DX points to MSG_NOT_CREATE_DIR msg.

	PUSH	DX			;save DX
	MOV	DL, [T_DRV_NUMBER]
	DEC	DL
	CALL	SET_DEFAULT_DRV 	;set target drive as a default
	POP	DX			;restore DX
PTP_NEXT:
	CMP	byte [SI], 0     ;end of string? the last path element?
	JE	PTP_LAST
	CMP	byte [SI], ':'     ;filename terminator not checked before?
	JNE	PTP_CHDIR		;else it is '\'.
	MOV	byte [SI], 0     ;change ':' to 0 for termination.
PTP_LAST:
	CALL	LAST_T_PATH
	JMP	PTP_EXIT
PTP_CHDIR:
	MOV	byte [SI], 0     ;replace '\' with 0
	MOV	AH, Chdir		;=38h
	INT	21h
	JC	PTP_MKDIR
	MOV	byte [SI], '\'     ;restore '\'
	INC	SI			;SI points to next to old '\'
	MOV	DX, SI			;DX points to next path entry
	CALL	NEXT_PATH_DELIM
	JMP	PTP_NEXT		;handles next path element
PTP_MKDIR:
	MOV	AH, Mkdir		;=39h
	INT	21h
	JC	PTP_ERROR		;cannot make directory
	INC	byte [T_MKDIR_LVL] ;# of MKDIR for the starting directory.
	JMP	PTP_CHDIR		;try again to chdir
PTP_ERROR:
	MOV	DX, MSG_NOT_CREATE_DIR	;AC000;GET THE MESSAGE ID
	OR	byte [PARM_FLAG], INIT_ERROR_FLAG ;critical error
PTP_EXIT:
	RET

;PARSING_T_PATH ENDP
;
LAST_T_PATH:
;called when the second parm reached last. *** this routine is the same as the old routine ***
;and the initial try to chdir to the given T_INPUT_PARM has been failed.
;INPUT: ES, DS - data seg
;	DX - points to the last path entry
;OUTPUT:target starting directory.

	MOV	AH, Chdir		;try to chdir to the last path entry
	INT	21h
;	IF$	C,LONG			;if fail.
	JC XL3$$I
	JMP IF132$$I
XL3$$I:

	    LEA     BX,[T_INPUT_PARM]
	    LEA     DX,[TEMP_T_FILENAME];take the last path element into TEMP_T_FILENAME
	    CALL    TAKE_PATH_TAIL
	    CMP     byte [TEMP_T_FILENAME], 0 ;any filename candidate entered?
;	    IF$     NE,LONG		;yes. let's check it has any global chr.
	    JNE XL4$$I
	    JMP IF133$$I
XL4$$I:
		PUSH	ES
		MOV	AH, 29h
		LEA	SI,[TEMP_T_FILENAME]
		MOV	ES, [PSP_SEG] ;ES - psp seg
		MOV	DI, PSPFCB2_DRV ;use this area for this test purposes
		MOV	AL, 0		;control bit
		INT	21h
		POP	ES
		CMP	AL, 0		;no global filename entered?
;		IF$	E		;yes, no globals
		JNE IF134$$I
		    CALL    PROMPT_CREATE_DIR ;then ask the user, it is a filename or subdir name?
		    MOV     DX,[USER_INPUT] ;AN000;SET UP FOR COMPAIR
		    CMP     DX, [ALPHA_DIR] ;directory?
;		    IF$     E		;yes, a subdir name.
		    JNE IF135$$I
			LEA	DX,[TEMP_T_FILENAME]
			MOV	AH, Mkdir ;=39h
			INT	21h	;create a new subdir
;			IF$	NC
			JC IF136$$I
			    INC     byte [T_MKDIR_LVL] ;one more directory has been made.
			    MOV     AH, Chdir
			    INT     21h ;Chdir to a new dir. This time it should be a success.
			    MOV     byte [TEMP_T_FILENAME], 0 ;mark temp_t_filename that it is empty
;			ELSE$		;ERROR IN CREATING DIRECTORY
			JMP SHORT EN136$$I
IF136$$I:
			    MOV     DX, MSG_NOT_CREATE_DIR ;AC000;GET THE MESSAGE ID
			    OR	    byte [PARM_FLAG], INIT_ERROR_FLAG
;			ENDIF$
EN136$$I:
;		    ELSE$		;USER ANSWERED IT A FILENAME
		    JMP SHORT EN135$$I
IF135$$I:
			OR	byte [PARM1_FLAG], t_file_flag ;set target file entered.
;		    ENDIF$		;use TEMP_T_FILENAME as a filename
EN135$$I:
;		ELSE$			;GLOBALS IN THE FILENAME
		JMP SHORT EN134$$I
IF134$$I:
		    MOV     byte [TEMP_T_FILENAME], 0 ;mark it to 0 since we don;t need this.
		    CALL    MAKE_TEMPLATE ;make a template of the target filename
		    OR	    byte [PARM1_FLAG], t_file_flag ;set target file entered flag
;		ENDIF$			;GLOBAL TEST
EN134$$I:
;	    ENDIF$			;NO, FILENAME NOT ENTERED. TEMP_T_FILENAME = 0
IF133$$I:
;	ENDIF$				;CHDIR FAIL
IF132$$I:
	RET
;LAST_T_PATH ENDP
;
;
CHK_S_RESERVED_NAME:
;check the source filename entered, and if it does not have any global chr,
;then check it whether it is reserved filename or not.
;input: es,ds - data seg

	mov	ax, 3d00h		;let's try to open it
	lea	dx,[S_DRV_1] ;'A:S_FILE'
	int	21h
	jc	csrn_exit		;open failure? jmp to exit
	mov	bx, ax			;else ax has file handle
	mov	ax, 4400h		;get device info.
	int	21h			;ioctl fun call
	test	dx, 80h 		;ISDEV ?
	jz	csrn_close		;no, block device. close handle and exit
	PUSH	AX			;AN000;
	MOV	AX, MSG_RES_S_NAME	;AC000;reserved file name as a source"
	MOV	[MSG_NUM],AX ;AN000;NEED MESSAGE ID FOR PRINT
	MOV	word [SUBST_COUNT],NO_SUBST ;AN000;NO SUBSTITUTION TEXT
	MOV	byte [INPUT_FLAG],NO_INPUT ;AN000;NO INPUT = 0
	MOV	byte [MSG_CLASS],UTILITY_MSG_CLASS ;AN000;MESSAGE CLASS = -1
	CALL	PRINT_STDERR		;AN000;print error. AX points to msg ID
	POP	AX			;AN000;
	mov	byte [ERRORLEVEL], 4 ;abnormal termination
	or	byte [PARM_FLAG], INIT_ERROR_FLAG ;set init_error_flag
	jmp	MAIN_EXIT
csrn_close:
	mov	ah, 3eh 		;close filehandle in bx
	int	21h
csrn_exit:
	ret
;CHK_S_RESERVED_NAME ENDP
;
PROMPT_CREATE_DIR:
;DS, ES - data seg
	PUSH	AX			;AN000;
	mov	cx, 13
	lea	si,[TEMP_T_FILENAME]
	lea	di,[FILENAME_FOR_PROMPT]
	call	MOV_STRING		;AC000;

;CALL GET MESSAGE TO DETERMINE WHAT THIS COUNTRY INPUT FOR 'F' OR 'D' IS.

	PUSH	DS			;AN000;
;	ASSUME	DS:NOTHING		;AN000;TELL THE ASSEMBLER
	MOV	AX,MSG_F_D		;AN000;MESSAGE NUMBER = 29 = 'F D '
	MOV	DH,UTILITY_MSG_CLASS	;AN000;MESSAGE DEFINED FOR XCPYINIT
	CALL	SYSGETMSG		;AN000;GET THE MESSAGE
	LODSW				;AN000;'F'PART OF MSG (DS:SI => AX)
	CMP	AH,SPACE		;AN000;NOT 'SPACE' THEN IT IS DBCS !
;	IF$	E			;AN000;IGNORE THE NEXT WORD
	JNE IF145$$I
	    MOV     AH,NUL		;AN000;THE END OF THE STRING
;	ENDIF$				;AN000;NOW GET TRANSLATION OF 'D'
IF145$$I:
	MOV	[es:ALPHA_FILE],AX ;AN000;TRANSLATED CHAR FOR 'F' TO BUFF
	LODSW				;AN000;'D'PART OF MSG (DS:SI => AX)
	CMP	AH,SPACE		;AN000;NOT 'SPACE' THEN IT IS DBCS !
;	IF$	E			;AN000;IGNORE THE NEXT WORD
	JNE IF147$$I
	    MOV     AH,NUL		;AN000;REMOVE SPACE CHARACTER
;	ENDIF$				;AN000;NOW GET TRANSLATION OF 'D'
IF147$$I:
	MOV	[es:ALPHA_DIR],AX ;AN000;TRANSLATED CHAR FOR 'D' TO BUFF
	POP	DS			;AN000;RESTORE AFTER CALL TO MSG HANDLR
;	ASSUME	DS:DGROUP		;AN000;TELL THE ASSEMBLER
					;remember this may be DBCS
PCD_AGAIN:
; Set message substitution list
	LEA	SI,[SUBLIST1];AN000; get addressability to sublist
	LEA	DX,[FILENAME_FOR_PROMPT] ;AN000; offset to file name
	MOV	[SI+SUB_LIST.DATA_OFF],DX ;AN000; save data offset
	MOV	[SI+SUB_LIST.DATA_SEG],DS ;AN000; save data segment
	MOV	[SI+SUB_LIST.MSG_ID],1 ;AN000; message ID
	MOV	[SI+SUB_LIST.FLAGS],010H ;AN000; ASCIIZ string, left align
	MOV	[SI+SUB_LIST.MAX_WIDTH],0 ;AN000; MAXIMUM FIELD WITH
	MOV	[SI+SUB_LIST.MIN_WIDTH],0 ;AN000; MINIMUM FIELD WITH

	MOV	AX,MSG_CREATE_DIR	;AN000;ID OF MESSAGE TO BE DISPLAYED
	MOV	[MSG_NUM],AX ;AN000;SET THE MESSAGE NUMBER
	MOV	word [SUBST_COUNT],PARM_SUBST_ONE ;AN000;PARM SUBSTITUTION COUNT=1
	MOV	byte [MSG_CLASS],UTILITY_MSG_CLASS ;AN000;MESSAGE CLASS = -1
	MOV	byte [INPUT_FLAG],Keyboard_Input ;AN000;KEYBOARD INPUT EXPECTED FUNCTION
	CALL	PRINT_STDOUT		;show prompt and get user input

	MOV	[USER_INPUT],AX ;AN000;RESPONSE BUFF FOR CAPITALIZATION

	MOV	AX,MSG_CR_LF_STR	;AN000; JUST CR,LF
	MOV	[MSG_NUM],AX ;AN000; set message number
	MOV	word [SUBST_COUNT],NO_SUBST ;AN000;NO PARAMETER SUBSTITUTION
	MOV	byte [INPUT_FLAG],NO_INPUT ;AN000; NO INPUT
	CALL	PRINT_STDOUT		;AN000; Display message

	MOV	AX,Upper_Case_String	;AN000;AX = 6521H GET EXT CTRY INFO
	LEA	DX,[USER_INPUT];AN000;RESPONSE BUFF FOR CAPITALIZATION
	MOV	CX,2			;AN000;TWO CHARACTERS, ONE WORD
	INT	21H			;AN000;ISSUE INT TO CAP STRING (DBCS?)
	MOV	AX,[USER_INPUT] ;AN000;SO I CAN DO THE COMPARE
	CMP	AX,[ALPHA_FILE] ;AN000;KEYBOARD INPUT AX = 'F' ?
	JE	PCD_EXIT
	CMP	AX,[ALPHA_DIR] ;AN000;KEYBOARD INPUT AX = 'D' ?
	JE	PCD_EXIT
	JMP	SHORT  PCD_AGAIN
PCD_EXIT:

	POP	AX			;AN000;
	RET
;PROMPT_CREATE_DIR ENDP
;
TAKE_PATH_TAIL:
;check the tail of the source input parm.
;Call LAST_DIR_OUT
;If carry set
;	then check the drive letter
;	     if entered, then save the rest of the string after drv: into
;	     a tempory filename holder, and put "." after the drive letter
;	     (For ex, if the input had been 'A:name1',0 then no change after
;	      LAST_DIR_OUT.  This has to be changed to 'A:.',0 and name1.)
;	else save the last dir into a filename, and
;	     check the result path
;	     if it is a drive only, then put "\" ( For ex, if the input
;	     had been 'A:\name1',0 then after LAST_DIR_OUT, it will be changed
;	     to 'A:',0 and 'name1',0.  In this case, we have to change the
;	     path to A:\)
;	     else OK.
;INPUT: DS - data seg
;	ES - data seg
;	BX - offset value of S_INPUT_PARM or T_INPUT_PARM
;	DX - offset value of TEMP_S_FILENAME or TEMP_T_FILENAME


	MOV	DI, BX			;offset of S(T)_INPUT_PARM
	CALL	LAST_DIR_OUT
;	IF$	C			;Not found a "\"
	JNC IF149$$I
	    MOV     SI, DI		;set si = di
	    CALL    CHK_DRV_LETTER	;if drv letter:, then SI will
					;point to next chr. Otherwise no change
	    cmp     byte [si], 0     ;only drv letter has entered. No filename
;	    IF$     NE			;filename entered
	    JE IF150$$I
		push	si		;save si
		MOV	CX, 13		;max # of filename in ASCIIZ
		MOV	DI, DX
		REP	MOVSB		;save it to temporay name holder
		pop	si		;restore si
;	    ENDIF$
IF150$$I:
	    mov     byte [si], A_dot     ;to be used for Chdir fun call
	    mov     byte [si+1], 0     ;make it ASCIIZ
;	ELSE$				;at least found a "\"
	JMP SHORT EN149$$I
IF149$$I:
	    mov     cx, 13		;let's save tail into filename holder first
	    mov     si, ax		;AX is an offset value of the tail
	    mov     di, DX		;TEMP_FILENAME
	    rep     movsb
	    mov     si, BX		;return to the Revised input
	    CALL    CHK_DRV_LETTER	;it starts with drv letter?
	    cmp     byte [si], 0     ;si points to the end of string?
;	    IF$     E
	    JNE IF153$$I
		MOV	byte [SI], '\'     ;then add '\' in the Revised S_INPUT_PARM
		MOV	byte [SI+1], 0
;	    ENDIF$
IF153$$I:
;	ENDIF$
EN149$$I:
	RET

;TAKE_PATH_TAIL ENDP
;
CHK_CYCLIC_COPY:
;With the one_disk_copy case, if the starting source path is a member of
;parent directory of the startind target path, then infinite copy cycle
;can occur.  This routine prevents that situation.
;ES: data seg
;DS: data seg

	PUSH	DS
	POP	ES			;set ES to DS (ES = DS)
	CALL	TRANS_NAMES		;AN016;CHK ASSIGN, JOIN & SUBST CONDITN
	TEST	byte [SYS_FLAG], one_disk_copy_flag ;source, target drv let same
;	IF$	NZ			;if they are, then check below facts
	JZ IF156$$I
	    MOV     DI, T_TRANS_PATH        ;AC025;
	    MOV     AL, 0
	    CALL    STRING_LENGTH
	    MOV     DX, CX		;save the length of S_PATH
	    MOV     DI, S_TRANS_PATH        ;AC025;
	    CALL    STRING_LENGTH
	    CMP     DX,CX		;compare the length
;	    IF$     AE			;if target length >= source length
	    JNAE IF157$$I
		MOV	SI, S_TRANS_PATH        ;AC025;
		MOV	DI, T_TRANS_PATH        ;AC025;
		DEC	CX		;get the actual length of chr's
		DEC	DX
		CLD
;		SEARCH$ 		;current CX = source length
DO158$$I:
		    CMP     CX, 0
;		EXITIF$ E		;exit if cx = 0
		JNE IF158$$I
		    CMP     DX, 0	;target length = 0 too?
;		    IF$     E		;yes, source = target
		    JNE IF160$$I
			TEST	byte [OPTION_FLAG], slash_s ; tree copy?
;			IF$	NZ,OR	;yes
			JNZ LL161$$I
			TEST	byte [OPTION_FLAG], slash_e
;			IF$	NZ
			JZ IF161$$I
LL161$$I:
			    MOV     DX, MSG_CYCLIC_COPY ;AC000;GET THE MESSAGE ID
			    OR	    byte [PARM_FLAG], INIT_ERROR_FLAG ;critical error
;			ELSE$		;same length, but not a tree copy.
			JMP SHORT EN161$$I
IF161$$I:
			    OR	    byte [COPY_STATUS], maybe_itself_flag ;possibly, copy onto itself.
;			ENDIF$		;cannot fully determine this time until file creation time
EN161$$I:
;		    ELSE$		;target > source
		    JMP SHORT EN160$$I
IF160$$I:
			TEST	byte [OPTION_FLAG], slash_s ;tree copy?
;			IF$	NZ,OR
			JNZ LL165$$I
			TEST	byte [OPTION_FLAG], slash_e
;			IF$	NZ
			JZ IF165$$I
LL165$$I:
			    CMP     byte [DI], '\'     ;source = d:\abc, target = d:\abc\def case
;			    IF$     E,OR
			    JE LL166$$I
			    CMP     byte [DI-1], '\'     ;source = d:\, target=d:\abc case
;			    IF$     E
			    JNE IF166$$I
LL166$$I:
				MOV	DX, MSG_CYCLIC_COPY ;AC000;GET THE MESSAGE ID
				OR	byte [PARM_FLAG], INIT_ERROR_FLAG ; critical error
;			    ENDIF$
IF166$$I:
;			ENDIF$
IF165$$I:
;		    ENDIF$
EN160$$I:
;		ORELSE$
		JMP SHORT SR158$$I
IF158$$I:
		    LODSB		;[SI] => AL, SI = SI + 1
		    SCASB		;AL vs. [DI], DI = DI + 1
;		LEAVE$	NE		;leave if not same
		JNE EN158$$I
		    DEC     CX
		    DEC     DX		;decrease target length, too
;		ENDLOOP$
		JMP SHORT DO158$$I
EN158$$I:
;		ENDSRCH$
SR158$$I:
;	    ENDIF$
IF157$$I:
;	ENDIF$
IF156$$I:
	RET

;CHK_CYCLIC_COPY ENDP
;
TRANS_NAMES:
;TRANSLATE THE INPUT TARGET AND SOURCE PATH TO DETERMINE
;IF ASSIGN, JOIN OR SUBSD WAS USET TO MODIFY HIDE THE TRUE
;PATH. THIS INFO. WILL BE USED TO DETERMINE CYCLIC COPY.
;INPUT: T_DRV_PATH, S_DRV_PATH

	PUSH	SI			;AN016;SI WILL BE DESTROYED
	PUSH	DI			;AN016;DI WILL BE DESTROYED

	MOV	SI,T_DRV_PATH           ;AN016;DO NAME TRANSLATE OF TAR
	MOV	DI,T_TRANS_PATH         ;AN025;SAVE FOR COMPARE
	MOV	AH,60h			;AN016;NAMETRANSLATE
	INT	21h			;AN016;EXECUTE

	MOV	SI,S_DRV_PATH           ;AN016;DO NAME TRANSLATE OF SRC
	MOV	DI,S_TRANS_PATH         ;AN025;SAVE FOR COMPARE
	MOV	AH,60h			;AN016;NAMETRANSLATE
	INT	21h			;AN016;EXECUTE

;NOW COMPARE THE TRANSLATED NAMES

	MOV	SI,T_TRANS_PATH         ;AN025;GET THE TAR FOR COMPARE
	MOV	DI,S_TRANS_PATH         ;AN025;GET THE SRC FOR COMPARE
	CALL	STR_COMP		;AN016;DO THE COMPARE
;	IF$	Z			;AN016;STRING DID COMPARE
	JNZ IF176$$I
	   OR	byte [SYS_FLAG], one_disk_copy_flag ;AN016;source, target drv let same
;	ENDIF$				;AN016;
IF176$$I:

	POP	DI			;AN016;restore DI
	POP	SI			;AN016;restore SI
	RET
;TRANS_NAMES ENDP
;
STR_COMP:
;COMPARE ASCIIZ DS:SI WITH ES:DI
;DI,SI ARE DESTROYED

STRCOMP:
	CMPSB				;AN016;ONE BYTE AT A TIME
;	IF$ NZ				;AN016;DID NOT COMPARE
	JZ IF178$$I
	    RET 			;AN016;NZ = DIFFERENCE
;	ENDIF$				;AN016;
IF178$$I:
	CMP	byte [SI-1],NUL     ;AN016;CHK FOR END OF THE STRING
;	IF$ Z				;ANO16;IT IS E O S
	JNZ IF180$$I
	    RET 			;AN016;IT COMPARED
;	ENDIF$				;AN016;
IF180$$I:
	JMP	SHORT STRCOMP		;AN016;GO AGAIN
;STR_COMP ENDP

MAKE_TEMPLATE:
;copy the formatted filename into the T_TEMPLATE which will be
;used to name a new filename.
;INPUT: PSP FCB 6ch for filename which have global chr.
;
	PUSH	DS			;ES = DS = DATA SEG

	MOV	DS, [PSP_SEG] ;DS = PSP_SEG

	MOV	SI, PSPFCB2_DRV
	INC	SI
	LEA	DI,[T_TEMPLATE]
	MOV	CX, 11
	REP	MOVSB			;filename => t_template

	POP	DS			;restore DS
	RET
;MAKE_TEMPLATE ENDP

GET_DRIVES:
;get source and target phisical drive letter from parser area.
;set ONE_DISK_COPY_FLAG, if the user XCOPY using the same drive letter.

	MOV	AL, [SO_DRIVE] ;AN000;source drive letter
	CMP	AL,SPACE		;AN000;IS DRIVE LETTER BLANK?
;	IF$	E			;AN000;YES, GET THE DEFAULT
	JNE IF182$$I
	    MOV     AL, [SAV_DEFAULT_DRV] ;(1=A, 2=B,...)
;	ELSE$				;AN000;NO, CHANGE FROM CHAR TO #
	JMP SHORT EN182$$I
IF182$$I:
	    SUB     AL,BASE_OF_ALPHA_DRV ;AN000;NEED THE DRV # HERE
;	ENDIF$
EN182$$I:
	MOV	[S_DRV_NUMBER], AL ;SAVE DRV #
	ADD	AL, BASE_OF_ALPHA_DRV
	MOV	[S_DRV], AL ;save source drive letter
	MOV	[S_DRV_1], AL
	MOV	[S_ARC_DRV], AL
	MOV	[SAV_S_DRV], AL

	MOV	AL, [TAR_DRIVE] ;AN000;target drive letter
	CMP	AL,SPACE		;AN000;IS DRIVE LETTER BLANK?
;	IF$	E			;AN000;YES, GET THE DEFAULT
	JNE IF185$$I
	    MOV     AL, [SAV_DEFAULT_DRV] ;AN000;(1=A, 2=B,...)
;	ELSE$				;AN000;NO, CHANGE FROM CHAR TO #
	JMP SHORT EN185$$I
IF185$$I:
	    SUB     AL,BASE_OF_ALPHA_DRV ;AN000;NEED THE DRV # HERE
;	ENDIF$
EN185$$I:
	MOV	[T_DRV_NUMBER], AL ;save target drv #

	CMP	[S_DRV_NUMBER], AL ;s_drv_number = t_drv_number?
;	IF$	E
	JNE IF188$$I
	    OR	    byte [SYS_FLAG], one_disk_copy_flag ;same logical drv copy
;	ENDIF$
IF188$$I:

	ADD	AL, BASE_OF_ALPHA_DRV	;make target drv # to drive letter
	MOV	[T_DRV], AL ;target drive letter
	MOV	[T_DRV_1], AL
	MOV	[T_DRV_2], AL
	MOV	[SAV_T_DRV], AL
	RET
;GET_DRIVES ENDP
;
;
GET_CUR_DRV:
;get the current default drive number (0 = A, 1 = B ..),
;change it to BIOS drive number and save it.
	MOV	AH, Current_Disk	; = 19h
	INT	21h
	INC	AL			;(1 = A, 2 = B ..)
	MOV	[SAV_DEFAULT_DRV], AL ;save it
	RET
;GET_CUR_DRV ENDP
;
GET_CUR_DIR:
;get current directory and save it
;input: DL - drive # (0 = default, 1 = A etc)
;	DS:SI - pointer to 64 byte user memory

	MOV	AH, Get_Current_Directory
	INT	21H
	RET
;GET_CUR_DIR ENDP
;
TOP_OF_MEM:
;set Top_of_memory

	PUSH	ES
	MOV	BX, [PSP_SEG]
	MOV	ES, BX
	MOV	AX, [es:2] ;PSP top of memory location
	SUB	AX, 140H		;subtract dos transient area (5k)
	MOV	[TOP_OF_MEMORY], AX ;save it for buffer top
	POP	ES
	RET
;TOP_OF_MEM ENDP

INIT_BUFFER:
;initialize buffer information
;set buffer_base, max_buffer_size
;	call	set_block		;SET BLOCK FOR BUFFR (for new 3.2 linker)
	MOV	AX, INIT
	PUSH	CS			;cs segment is the highest segment in this program
	POP	DX
	MOV	[BUFFER_PTR], DX
	CALL	SET_BUFFER_PTR
	MOV	AX, [BUFFER_PTR]
	MOV	[BUFFER_BASE], AX ;set buffer_base
	MOV	AX, [BUFFER_LEFT]
	CMP	AX, 140h		;BUFFER_LEFT < 5K which is the minimum size this program supports?
	JAE	IB_CONT
	PUSH	AX			;AN000;
	MOV	AX, MSG_INSUF_MEMORY	;AC000;GET THE MESSAGE ID
	MOV	[MSG_NUM],AX ;AN000;NEED MESSAGE ID FOR PRINT
	MOV	word [SUBST_COUNT],NO_SUBST ;AN000;NO SUBSTITUTION TEXT
	MOV	byte [INPUT_FLAG],NO_INPUT ;AN000;NO INPUT = 0
	MOV	byte [MSG_CLASS],UTILITY_MSG_CLASS ;AN000;MESSAGE CLASS = -1
	CALL	PRINT_STDERR		;AN000;print error. AX points to msg ID
	POP	AX			;AN000;
	MOV	byte [ERRORLEVEL], 4 ;abnormal termination
	JMP	MAIN_EXIT_A		;terminate this program
IB_CONT:
	MOV	[MAX_BUFFER_SIZE], AX ;set max buffer size in para
	CMP	AX, 0FFFh		;max_buffer_size > 64 K in para ?
;	IF$	B
	JNB IF190$$I
	    MOV     CX, 16
	    MUL     CX			;AX = AX * 16 (DX part will be 0)
	    SUB     AX, 544		;AN000;subtract header size
	    MOV     [MAX_CX], AX ;this will be max_cx
;	ELSE$
	JMP SHORT EN190$$I
IF190$$I:
	    MOV     word [MAX_CX], 0FFD0h ;else max_cx = fff0 - 32 bytes
					;which is the max # this program can support.
;	ENDIF$				;(min # this program support for buffer is 5 k
EN190$$I:
					; which has been decided by BIG_FILE )
	RET
;INIT_BUFFER ENDP
;
HOOK_CTRL_BREAK:
;
	PUSH	DS			;save DS
	PUSH	CS
	POP	DS			;ds = cs
	MOV	AX, 2523h
	MOV	DX, CTRL_BREAK_EXIT
	INT	21H
	POP	DS			;restore ds
	RET
;HOOK_CTRL_BREAK ENDP
;
SAV_HOOK_INT24:
;sav the int_24 addr, and hooks it to my_int24
	PUSH	ES
	MOV	AH, 35h
	MOV	AL, 24h 		;get critical error handler addr
	INT	21h
	MOV	[cs:SAV_INT24_OFF], BX ;offset ip
	MOV	[cs:SAV_INT24_SEG], ES ;seg cs
	POP	ES
	PUSH	DS			;save DS
	PUSH	CS
	POP	DS			;ds = cs
	MOV	AH, 25h
	MOV	AL, 24h
	MOV	DX, MY_INT24        ;now DS:DX contains the addr.
	INT	21h			;hook it to my_int24 routine
	POP	DS			;restore ds
	RET
;SAV_HOOK_INT24 ENDP
;
end if
;	END

