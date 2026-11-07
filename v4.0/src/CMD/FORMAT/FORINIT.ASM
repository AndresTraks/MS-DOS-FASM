
;


;*****************************************************************************
;*****************************************************************************
;UTILITY NAME: FORMAT.COM
;
;MODULE NAME: FORINIT.SAL
;
;
;
; ÚÄÄÄÄÄÄÄÄÄÄÄ¿
; ³ Main_Init ³
; ÀÄÂÄÄÄÄÄÄÄÄÄÙ
;   ³
;   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿     ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   Ã´Init_Input_OutputÃÄÄÄÄÂ´Preload_Messages³
;   ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ    ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;   ³			    ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   ³			    Ã´Check_For_FS_SwitchÃÄÄÂ´Parse_For_FS_Switch³
;   ³			    ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;   ³			    ³			    ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   ³			    ³			    À´EXEC_FS_Format³
;   ³			    ³			     ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;   ³			    ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   ³			    À´Parse_Command_Line ÃÄÄÄ´Interpret_Parse³
;   ³			     ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   Ã´Validate_Target_DriveÃÂ´Check_Target_Drive³
;   ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;   ³			    ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   ³			    Ã´Check_For_Network³
;   ³			    ³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;   ³			    ³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   ³			    À´Check_Translate_Drive³
;   ³			     ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;   ³ÚÄÄÄÄÄÄÄÄÄÄÄÄ¿
;   À´Hook_CNTRL_C³
;    ÀÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;
; Change List: AN000 - New code DOS 3.3 spec additions
;	       AC000 - Changed code DOS 3.3 spec additions
;*****************************************************************************
;*****************************************************************************

if SEGSEL = S_DATA


Command_Line db NO
PSP_Segment dw	0

;These should stay togather
; ---------------------------------------	;				;AN000;
FS_String_Buffer db 13 dup(" ") 		;				;AN000;
FS_String_End db "FMT.EXE",0			;				;AN000;
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
Len_FS_String_End = $ - FS_String_End 	;				;AN000;
						;				;AN000;
;----------------------------------------

Vol_Label_Count  db 80h 			;an000; dms;max. string length
Vol_Label_Len	 db 00h 			;an000; dms;len. entered
Vol_Label_Buffer db 80h dup(0)			;				;AN000;
Vol_Label_Buffer_Length = $ - Vol_Label_Buffer ;				 ;AN000;

Command_Line_Buffer db 80h dup(0)		;				;AN000;
Command_Line_Length = $ - Command_Line_Buffer ;				;AN000;
Fatal_Error db	0				;				;AN000;

Command_Old_Ptr rw      1

end if

if SEGSEL = S_CODE
;	assume	cs:code,ds:data,es:data
end if

;
;*****************************************************************************
; Include files
;*****************************************************************************
;

.xlist
include 'FORCHNG.INC'
include 'FORMACRO.INC'
include 'SYSCALL.INC'
include 'IOCTL.INC'
include 'FOREQU.INC'
include 'FORPARSE.INC'
include 'FORSWTCH.INC'
.list

;
;*****************************************************************************
; Public Data
;*****************************************************************************
;

;	Public	FS_String_Buffer
;	Public	Command_Line
;	Public	Fatal_Error
;	Public	Vol_Label_Count
;	Public	Vol_Label_Buffer
;	Public	PSP_Segment
;	Public	Command_Old_Ptr


;
;*****************************************************************************
; Public Routines
;*****************************************************************************
;


;	Public	Main_Init

;
;*****************************************************************************
; External Routine Declarations
;*****************************************************************************
;

;	Extrn	Main_Routine:Near
;	Extrn	SysLoadMsg:Near
;	Extrn	Get_11_Characters:Near
;	Extrn	ControlC_Handler:Near
;	Extrn	SysDispMsg:Near
;	Extrn	SysLoadMsg:Near

IF FSExec					;/FS: conditional assembly	;an018; dms;

;	Extrn	EXEC_FS_Format:Near

end if ;/FS: conditional assembly end	;an018;dms;

;	Extrn	GetDeviceParameters:Near
;
;*****************************************************************************
; External Data Declarations
;*****************************************************************************
;

;	Extrn	SwitchMap:Word
;	Extrn	ExitStatus:Byte
;	Extrn	Drive:Byte
;	Extrn	DriveLetter:Byte
;	Extrn	TranSrc:Byte
;	Extrn	TrackCnt:Word
;	Extrn	NumSectors:Word
;	Extrn	BIOSFile:Byte
;	Extrn	DOSFile:Byte
;	Extrn	CommandFile:Byte
;	Extrn	MsgNeedDrive:Byte
;	Extrn	MsgBadVolumeID:Byte
;	Extrn	MsgBadDrive:Byte
;	Extrn	MsgAssignedDrive:Byte
;	Extrn	MsgNetDrive:Byte
;	Extrn	Parse_Error_Msg:Byte
;	Extrn	Extended_Error_Msg:Byte
;	Extrn	SizeMap:Byte
;	Extrn	MsgSameSwitch:Byte
;	Extrn	Org_AX:word			;an000; dms;AX on prog. entry
;	Extrn	DeviceParameters:Byte		;an000; dms;
;	Extrn	FAT_Flag:Byte			;an000; dms;
;	Extrn	Sublist_MsgParse_Error:Dword	;an000; dms;


if SEGSEL = S_CODE

;*****************************************************************************
;Routine name:	Main_Init
;*****************************************************************************
;
;Description: Main control routine for init section
;
;Called Procedures: Message (macro)
;		    Check_DOS_Version
;		    Init_Input_Output
;		    Validate_Target_Drive
;		    Hook_CNTRL_C
;
;Input: None
;
;Output: None
;
;Change History: Created	5/1/87	       MT
;
;Psuedocode
; ---------
;
;	Get PSP segment
;	Fatal_Error = NO
;	Setup I/O (CALL Init_Input_Output)
;	IF !Fatal_Error
;	   Check target drive letter (CALL Validate_Target_Drive)
;	   IF !Fatal_Error
;	      Set up Control Break (CALL Hook_CNTRL_C)
;	      IF !Fatal_Error
;		 CALL Main_Routine
;	      ENDIF
;	   ENDIF
;	ENDIF
;	Exit program
;*****************************************************************************

Procedure Main_Init				;				;AN000;


	Set_Data_Segment			;Set DS,ES to Data segment	;AN000;
	DOS_Call GetCurrentPSP			;Get PSP segment address
	mov	[PSP_Segment],bx ;Save it for later
	mov	byte [Fatal_Error],NO ;Init the error flag		;AN000;
	call	Init_Input_Output		;Setup messages and parse	;AN000;
	cmp	byte [Fatal_Error],YES ;Error occur?			;AN000;
;	IF$	NE				;Nope, keep going		;AN000;
	JE IF1$$I
	   call    Validate_Target_Drive	;Check drive letter		;AN000;
	   cmp	   byte [Fatal_Error],YES ;Error occur?			;AN000;
;	   IF$	   NE				;Nope, keep going		;AN000;
	   JE IF2$$I
	      call    Hook_CNTRL_C		;Set CNTRL -Break hook		;AN000;
	      cmp     byte [Fatal_Error],YES ;Error occur?			;AN000;
;	      IF$     NE			;Nope, keep going		;AN000;
	      JE IF3$$I
		 call	 Main_Routine		;Go do the real program 	;AN000;
;	      ENDIF$				;				;AN000;
IF3$$I:
;	   ENDIF$				;				;AN000;
IF2$$I:
;	ENDIF$					;				;AN000;
IF1$$I:
	mov	al,[ExitStatus] ;Get Errorlevel 		;AN000;
	DOS_Call Exit				;Exit program			;AN000;
	int	20h				;If other exit fails		;AN000;

;Main_Init endp					;				;AN000;

;*****************************************************************************
;Routine name: Init_Input_Output
;*****************************************************************************
;
;Description: Initialize messages, Parse command line, allocate memory as
;	      needed. If there is a /FS switch, go handle it first as
;	      syntax of IFS format may be different from FAT format.
;
;Called Procedures: Preload_Messages
;		    Parse_For_FS_Switch
;		    Parse_Command_Line
;
;Change History: Created	4/1/87	       MT
;
;Input: PSP command line at 81h and length at 80h
;	Fatal_Error  = No
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;
;	Load messages (CALL Preload_Messages)
;	IF !Fatal_Error
;	   See if EXEC another file system (CALL Parse_For_FS_Switch)
;	   IF !FATAL_Error (in this case means FS was found and exec'd)
;	      CALL Parse_Command_Line
;	      IF !Fatal_Error
;		 CALL Interpret_Parse
;	      ENDIF
;	   ENDIF
;	ENDIF
;	ret
;*****************************************************************************

Procedure Init_Input_Output			;				;AN000;

	Set_Data_Segment			;Set DS,ES to Data segment	;AN000;
	call	Preload_Messages		;Load up message retriever	;AN000;

IF FSExec					;/FS: conditional assembly	;an018; dms;

	cmp	byte [Fatal_Error],YES ;Quit?				;AN000;
;	IF$	NE				;Nope, keep going		;AN000;
	JE IF7$$I
	   call    Check_For_FS_Switch		;Specify FS other than FAT?	;AN000;

end if ;/FS: conditional assembly end	;an018;dms;

	   cmp	   byte [Fatal_Error],YES ;drive is invalid for format?	;an000;
;	   if$	   ne				;no				;an000;
	   JE IF8$$I
		   call    Parse_Command_Line ;Parse in command line input	;AN000;
		   cmp	   byte [Fatal_Error],YES ;Quit?				;AN000;
;		   IF$	   NE			;Nope, keep going		;AN000;
		   JE IF9$$I
			   call    Determine_FAT_Non_FAT;see if drive was non_FAT ;an000;
			   call    Check_For_Invalid_Drive;Drive joined?	;an000;
;		   ENDIF$			;				;AN000;
IF9$$I:
;	    ENDIF$				;				;AN000;
IF8$$I:

IF FSExec					;/FS: conditional assembly	;an018; dms;

;	ENDIF$					;				;an000;
IF7$$I:

end if ;/FS: conditional assembly end	;an018;dms;

	ret					;				;AN000;

;Init_Input_Output endp				;				;AN000;

;*****************************************************************************
;Routine name: Preload_Messages
;*****************************************************************************
;
;Description: Preload messages using common message retriever routines.
;
;Called Procedures: SysLoadMsg
;
;
;Change History: Created	5/1/87	       MT
;
;Input: Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;
;	Preload All messages (Call SysLoadMsg)
;	IF error
;	   Display SysLoadMsg error message
;	   Fatal_Error = YES
;	ENDIF
;	ret
;*****************************************************************************

Procedure Preload_Messages			;				;AN000;
						;
	Set_Data_Segment			;Set DS,ES to Data segment	;AN000;
	call	SYSLOADMSG			;Preload the messages		;AN000;
;	IF$	C				;Error? 			;AN000;
	JNC IF13$$I
	   call    SYSDISPMSG			;Display preload msg		;AN000;
	   mov	   byte [Fatal_Error], YES ;Indicate error exit		;AN000;
;	ENDIF$					;				;AN000;
IF13$$I:
	ret					;				;AN000;

;Preload_Messages endp				;				;AN000;




IF FSExec					;/FS: conditional assembly	;an018; dms;


;*****************************************************************************
;Routine name: Check_For_FS_Switch
;*****************************************************************************
;
;Description: Parse to see if /FS switch entered, and if so, go EXEC the
;	      asked for file system. Set Fatal_Error = YES if FS found
;	      If we do find /FS, we need to build a string of xxxxxfmt.exe,0
;	      where xxxxx is the first 5 characters or less of /FS:xxxxx
;
;Called Procedures: Parse_For_FS_Switch
;		    EXEC_FS_Format
;
;Change History: Created	6/21/87 	MT
;
;Input: Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;	 Exit_Status set
;
;Psuedocode
;----------
;
;	Parse for /FS switch (CALL Parse_For_FS_Switch)
;	IF !FATAL_ERROR
;	   IF /FS found
;	      Point at what was entered on /FS:xxxxx
;	      DO
;	      LEAVE end of entered string
;		Got good char, move into path
;	      ENDDO already got 5 chars (max in xxxxxfmt.exe)
;	      Tack on the rest of the string  (fmt.exe,0)
;	      Go exec the needed format (CALL EXEC_FS_Format)
;	   ENDIF
;	ENDIF
;	ret
;*****************************************************************************

Procedure Check_For_FS_Switch			;				;AN000;
						;AN000;
	Set_Data_Segment			;Set DS,ES to Data segment	;AN000;
	call	Parse_For_FS_Switch		;See if /FS entered		;AN000;
	cmp	byte [Fatal_Error],YES ;Bad stuff entered??		;AN000;
;	IF$	NE				;Nope, cruise onward		;AN000;
	JE IF15$$I
	   cmp	   word [Switch_String_Buffer+Switch_Return.Switch_Pointer],Switch_FS_Control+Control.Keyword ; ;AN000;
;	   IF$	   E				;We got the switch		;AN000;
	   JNE IF16$$I
	      mov     byte [Switch_FS_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	      test    word [SWITCHMAP],SWITCH_FS ;Have this already?		;AN002;
;	      IF$     Z 			;Nope				;AN002;
	      JNZ IF17$$I
		 push	 ds			;Get addressibility		;AN000;
		 pop	 es			; "  "	  "  "			;AN000;
						;
;		 assume  ds:nothing,es:data	;				;AN000;
						;
		 mov	 ax,[es:Switch_String_Buffer.Switch_String_Seg] ;Get the entered FS ;AN000;
		 mov	 ds,ax			;				;AN000;
		 mov	 si,[es:Switch_String_Buffer.Switch_String_Off] ; 	       ;AN000;
		 mov	 cx,FS_String_Max_Length ;				 ;AN000;
		 mov	 di,FS_String_Buffer        ;			   ;AN000;
;		 DO$				;Move whatever user entered	;AN000;
DO18$$I:
		    cmp     byte [si],Asciiz_End     ;End of the string?	   ;AN000;
;		 LEAVE$  E			;Yep				;AN000;
		 JE EN18$$I
		    movsb			;Put character in buffer	;AN000;
		    dec     cx			;Dec character counter
		    cmp     cx,0		;Nope, reached max # chars?	;AN000;
;		 ENDDO$  E			;Yes				;AN000;
		 JNE DO18$$I
EN18$$I:
		 Set_Data_Segment		;Set DS,ES to Data segment	;AN000;
		 mov	 cx,Len_FS_String_End	;Tack the FMT.EXE onto it	   ;AN000;
		 mov	 si,FS_String_End        ;DI still points at string	    ;AN000;
		 rep	 movsb			;We now have Asciiz path!	;AN000;
		 call	 Exec_FS_Format 	;Go try to EXEC it..... 	;AN000;
;	      ELSE$				;				;AN002;
	      JMP SHORT EN17$$I
IF17$$I:
		 Message msgSameSwitch		;				;AN002;
		 mov	 byte [es:Fatal_Error],YES ;				;AN002;
;	      ENDIF$				;				;AN002;
EN17$$I:
;	   ENDIF$				;				;AN000;
IF16$$I:
;	ENDIF$					;				;AN000;
IF15$$I:
	ret					;				;AN000;

;Check_For_FS_Switch endp			;				;AN000;

;*****************************************************************************
;Routine name: Parse_For_FS_Switch
;*****************************************************************************
;
;Description: Copy the command line. Parse the new command line (Parse routines
;	      destroy the data being parsed, so need to work on copy so that
;	      complete command line can be passed to child format).
;	      The only thing we care about is if the /FS: switch exists, so
;	      parse until  end of command line found. If there was an error,
;	      and it occurred on the /FS switch, then give parse error,
;	      otherwise ignore the parse error, because it might be something
;	      file system specific that doesn't meet DOS syntax rules. Also
;	      check for drive letter, as it is alway required.
;
;Called Procedures: Message (macro)
;		    SysLoadMsg
;		    Preload_Error
;		    SysParse
;
;Change History: Created	5/1/87	       MT
;
;Input: Command line at 80h in PSP
;	   Fatal_Error = NO
;	   PSP_Segment
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;	Copy command line to buffer
;	DO
;	   Parse command line (Call SysParse)
;	LEAVE end of parse
;	ENDDO found /FS
;	IF drive letter not found (This assumes drive letter before switches)
;	   Tell user
;	   Fatal_Error = YES
;	ENDIF
;	ret
;*****************************************************************************

Procedure Parse_For_FS_Switch			;				;AN000;
						;
	Set_Data_Segment			;Set DS,ES to Data segment	;AN000;
	mov	[es:Drive_Letter_Buffer.Drive_Number],INIT ; 			;AN000;
	mov	cx,[es:PSP_Segment] ;Get segment of PSP		;AN000;
	mov	ds,cx				;  "  "    "  " 		;AN000;
;	assume	ds:nothing			;
						;
	mov	si,Command_Line_Parms		;Point at command line		;AN000;
	mov	di,Command_Line_Buffer        ;Where to put a copy of it	   ;AN000;
	mov	cx,Command_Line_Length		;How long was input?		;AN000;
	repnz	movsb				;Copy it			;AN000;
	Set_Data_Segment			;Set DS,ES to Data segment	;AN000;
	xor	cx,cx				;				;AN000;
	xor	dx,dx				;Required for SysParse call	;AN000;
	mov	si,Command_Line_Buffer        ;Pointer to parse line		  ;AN000;
	mov	di,Switch_FS_Table        ;Pointer to control table	   ;AN000;
;	DO$					;Setup parse call		;AN000;
DO25$$I:
	   call    SysParse			;Go parse			;AN000;
	   cmp	   ax,End_Of_Parse		;Check for end of parse 	;AN000;
;	LEAVE$	E,OR				;Exit if it is end, or		;AN000;
	JE EN25$$I
	   cmp	   ax,Operand_Missing		; exit if positional missing	;AN000;
;	LEAVE$	E				;In other words, no drive letter;AN000;
	JE EN25$$I
	   cmp	   word [es:Switch_String_Buffer+Switch_Return.Switch_Pointer],Switch_FS_Control+Control.Keyword ;AN000;
;	ENDDO$	E				;Exit if we find /FS		;AN000;
	JNE DO25$$I
EN25$$I:
	cmp	[es:Drive_Letter_Buffer.Drive_Type],Type_Drive ;Check for drive letter found;AN000;
;	IF$	NE				;Did we not find one?		;AN000;
	JE IF28$$I
	   Message msgNeedDrive 		;Must enter drive letter	;AN000;
	   mov	   byte [es:Fatal_Error],YES ;Indicate error on exit 	;AN000;
;	ENDIF$					;				;AN000;
IF28$$I:
	ret					;				;AN000;

;Parse_For_FS_Switch endp			;				;AN000;


end if ;/FS: conditional assembly end	;an018;dms;


;*****************************************************************************
;Routine name: Parse_Command_Line
;*****************************************************************************
;
;Description: Parse the command line. Check for errors, and display error and
;		 exit program if found. Use parse error messages except in case
;		 of no parameters, which has its own message
;
;Called Procedures: Message (macro)
;		    SysParse
;		    Interpret_Parse
;
;Change History: Created	5/1/87	       MT
;
;Input: Fatal_Error = NO
;	PSP_Segment
;
;Output: Fatal_Error = YES/NO
;
;
;Psuedocode
;----------
;
;	Assume Fatal_Error = NO on entry
;	SEARCH
;	EXITIF Fatal_Error = YES,OR  (This can be set by Interpret_Parse)
;	   Parse command line (CALL SysParse)
;	EXITIF end of parsing command line
;	   Figure out last thing parsed (Call Interpret_Parse)
;	ORELSE
;	   See if parse error
;	LEAVE parse error,OR
;	   See what was parsed (Call Interpret_Parse)
;	LEAVE if interpret error such as bad volume label
;	ENDLOOP
;	   Display parse error message and print error operand
;	   Fatal_Error = YES
;	ENDSRCH
;	ret
;*****************************************************************************

Procedure Parse_Command_Line			;				;AN000;

	Set_Data_Segment			;Set DS,ES to Data segment	;AN000;
	push	ds
	mov	cx,[es:PSP_Segment] ;Get segment of PSP		;AN000;
	mov	ds,cx				;  "  "    "  " 		;AN000;

;	assume	ds:nothing,es:data

	xor	cx,cx				;Parse table @DI		;AN000;
	xor	dx,dx				;Parse line @SI 		;AN000;
	mov	si,Command_Line_Parms		;Pointer to parse line		;AN000;
	mov	word [es:Command_Old_Ptr],si
	mov	di,Command_Line_Table        ;Pointer to control table	;AN000;
;	SEARCH$ 				;Loop until all parsed		;AN000;
DO30$$I:
	   cmp	   byte [es:Fatal_Error],YES ;Interpret something bad?	;AN000;
;	EXITIF$ E,OR				;If so, don't parse any more    ;AN000;
	JE LL31$$I
	   call    SysParse			;Go parse			;AN000;
	   cmp	   ax,End_Of_Parse		;Check for end of parse 	;AN000;
;	EXITIF$ E				;Is it? 			;AN000;
	JNE IF30$$I
LL31$$I:
						;All done			;AN000;
;	ORELSE$ 				;Not end			;AN000;
	JMP SHORT SR30$$I
IF30$$I:
	   cmp	   ax,0 			;Check for parse error		;AN000;
;	LEAVE$	NE				;Stop if there was one		;AN000;
	JNE EN30$$I
	   mov	word [es:Command_Old_Ptr],si
	   call    Interpret_Parse		;Go find what we parsed 	;AN000;
;	ENDLOOP$				;Parse error, see what it was	;AN000;
	JMP SHORT DO30$$I
EN30$$I:
	   mov	byte [ds:si],0
	   push di
	   push ax
	   mov	di,Sublist_msgParse_Error
	   mov	ax,word [es:Command_Old_Ptr]
	   mov	word [es:di+2],ax
	   mov	word [es:di+4],ds
	   pop	ax
	   pop	di
	   Parse_Message			;Display parse error		;AN000;
	   mov	   byte [es:Fatal_Error],YES ;Indicate death!		;AN000;
;	ENDSRCH$				;				;AN000;
SR30$$I:
	pop	ds				;				;AN000;
	ret					;				;AN000;

;Parse_Command_Line endp 			;				;AN000;

;*****************************************************************************
;Routine name: Interpret_Parse
;*****************************************************************************
;
;Description: Set the SwitchMap  field with the switches found on the
;	      command line. Get the drive letter. /FS will be handled before
;	      here, will not be seen in this parse or accepted. Also, if /V
;	      see if volume label entered and verify it is good, setting up
;	      FCB for later create
;
;Called Procedures: Get_11_Characters
;
;Change History: Created	5/1/87	       MT
;
;Input: Fatal_Error = NO
;
;Output: SwitchMap set
;	 DriveLetter set
;	 DriveNum set A=0,B=1 etc...
;	 Command_Line = YES/NO
;	 Fatal_Error = YES/NO
;
;Psuedocode
;----------
;
;	IF Drive letter parsed
;	Drive = Parsed drive number -1
;	DriveLetter = (Parsed drive number - 1) +'A'
;	ENDIF
;	IF /1
;	  or	SwitchMap,Switch_1
;	ENDIF
;	IF /4
;	  or	SwitchMap,Switch_4
;	ENDIF
;	IF /8
;	  or	SwitchMap,Switch_8
;	ENDIF
;	IF /S
;	  or	SwitchMap,Switch_S
;	ENDIF
;	IF /BACKUP
;	  or	SwitchMap,Switch_BACKUP
;	ENDIF
;	IF /B
;	  or	SwitchMap,Switch_B
;	ENDIF
;	IF /T
;	  or	SwitchMap,Switch_T
;	  TrackCnt = entered value
;	ENDIF
;	IF /N
;	  or	SwitchMap,Switch_N
;	  NumSectors = entered value
;	ENDIF
;	IF /SELECT
;	  or	SwitchMap,Switch_SELECT
;	ENDIF
;	IF /V
;	  or	SwitchMap,Switch_V
;	  IF string entered
;	     Build ASCIIZ string for next call (CALL Build_String)
;	     Verify DBCS and setup FCB (CALL Get_11_Characters)
;	     Command_Line = YES
;		IF error
;		  Invalid label message
;		  Fatal_Error = YES
;		ENDIF
;	  ENDIF
;	ENDIF
;	IF /AUTOTEST
;	  or	SwitchMap,Switch_AUTOTEST
;	ENDIF
;
;	IF /F
;	  or	SwitchMap,Switch_F
;	  or	Size_Map,Item_Tag
;	ENDIF
;	IF /Z	(only if assembled)
;	  or	SwitchMap,Switch_Z
;	ENDIF
;	ret
;*****************************************************************************

Procedure Interpret_Parse			;				;AN000;

	push	ds				;Save segment			;AN000;
	push	si				;Restore SI for parser		;AN000;
	push	cx				;				;AN000;
	push	di				;
	Set_Data_Segment			;Set DS,ES to Data segment	;AN000;
	cmp	byte [es:Drive_Letter_Buffer.Drive_Type],Type_Drive ;Have drive letter?	 ;AN000;
;	IF$	E				;Yes, save info 		;AN000;
	JNE IF36$$I
	   mov	   al,[es:Drive_Letter_Buffer.Drive_Number] ;Get drive entered	   ;AN000;
	   dec	   al				;Make it 0 based		;AN000;
	   mov	   [es:drive],al ; "  "	  "  "			;AN000;
	   add	   al,'A'			;Make it a drive letter 	;AN000;
	   mov	   [es:driveLetter],al ;Save it			;AN000;
;	ENDIF$					;				;AN000;
IF36$$I:
	cmp	[es:Switch_Buffer.Switch_Pointer],Switch_1_Control+Control.Keyword ;;AN000;
;	IF$	E				;				;AN000;
	JNE IF38$$I
	   mov	   byte [es:Switch_1_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   or	   word [es:SWITCHMAP],SWITCH_1 ;				;AN000;
;	ENDIF$					;				;AN000;
IF38$$I:
	cmp	[es:Switch_Buffer.Switch_Pointer],Switch_4_Control+Control.Keyword ;;AN000;
;	IF$	E				;				;AN000;
	JNE IF40$$I
	   mov	   byte [es:Switch_4_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   or	   word [es:SWITCHMAP],SWITCH_4 ;				;AN000;
;	ENDIF$					;				;AN000;
IF40$$I:
	cmp	[es:Switch_Buffer.Switch_Pointer],Switch_8_Control+Control.Keyword ;;AN000;
;	IF$	E				;				;AN000;
	JNE IF42$$I
	   mov	   byte [es:Switch_8_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   or	   word [es:SWITCHMAP],SWITCH_8 ;				;AN000;
;	ENDIF$					;				;AN000;
IF42$$I:
	cmp	[es:Switch_Buffer.Switch_Pointer],Switch_S_Control+Control.Keyword ;;AN000;
;	IF$	E				;				;AN000;
	JNE IF44$$I
	   mov	   byte [es:Switch_S_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   or	   word [es:SWITCHMAP],SWITCH_S ;				;AN000;
;	ENDIF$					;				;AN000;
IF44$$I:
	cmp	[es:Switch_Buffer.Switch_Pointer],Switch_Backup_Control+Control.Keyword ;AN000;
;	IF$	E				;				;AN000;
	JNE IF46$$I
	   mov	   byte [es:Switch_Backup_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   or	   word [es:SWITCHMAP],SWITCH_BACKUP ;				;AN000;
;	ENDIF$					;				;AN000;
IF46$$I:
	cmp	[es:Switch_Buffer.Switch_Pointer],Switch_Select_Control+Control.Keyword ;AN000;
;	IF$	E				;				;AN000;
	JNE IF48$$I
	   mov	   byte [es:Switch_Select_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   or	   word [es:SWITCHMAP],SWITCH_SELECT ;				;AN000;
;	ENDIF$					;				;AN000;
IF48$$I:
	cmp	[es:Switch_Buffer.Switch_Pointer],Switch_B_Control+Control.Keyword ;AN000;
;	IF$	E				;				;AN000;
	JNE IF50$$I
	   mov	   byte [es:Switch_B_Control+Control.Keyword],20H
	   or	   word [es:SWITCHMAP],SWITCH_B ;				;AN000;
;	ENDIF$					;				;AN000;
IF50$$I:
	cmp	[es:Switch_Num_Buffer.Switch_Num_Pointer],Switch_T_Control+Control.Keyword ;AN000;
;	IF$	E				;				;AN000;
	JNE IF52$$I
	   mov	   byte [es:Switch_T_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   mov	   [es:Switch_Num_Buffer.Switch_Num_Pointer],0 ;Init for next switch ;AN008;
	   test    word [es:SWITCHMAP],SWITCH_T ;Don't allow if switch already  ;AN002;
;	   IF$	   Z				; entered			;AN002;
	   JNZ IF53$$I
	      or      word [es:SWITCHMAP],SWITCH_T ;				;AN000;
	      mov     ax,[es:Switch_Num_Buffer.Switch_Number_Low] ;Get entered tracks   ;AN000;
	      mov     [es:TrackCnt],ax ;1024 or less, so always dw	;AN000;
;	   ELSE$				;				;AN002;
	   JMP SHORT EN53$$I
IF53$$I:
	      Message msgSameSwitch		;				;AN002;
	      mov     byte [es:Fatal_Error],YES ;				;AN002;
;	   ENDIF$				;				;AN000;
EN53$$I:
;	ENDIF$					;				;AN002;
IF52$$I:
	cmp	[es:Switch_Num_Buffer.Switch_Num_Pointer],Switch_N_Control+Control.Keyword ;AN000;
;	IF$	E				;				;AN000;
	JNE IF57$$I
	   mov	   byte [es:Switch_N_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   mov	   [es:Switch_Num_Buffer.Switch_Num_Pointer],0 ;Init for next switch ;AN008;
	   test    word [es:SWITCHMAP],SWITCH_N ;Make sure switch not already	;AN002;
;	   IF$	   Z				; entered			;AN002;
	   JNZ IF58$$I
	      or      word [es:SWITCHMAP],SWITCH_N ;				;AN000;
	      mov     ax,[es:Switch_Num_Buffer.Switch_Number_Low] ;Get entered tracks   ;AN000;
	      xor     ah,ah			;clear high byte		;an000;
	      mov     [es:NumSectors],ax ;Save tracks per sector 	;AN000;
;	   ELSE$				;				;AN002;
	   JMP SHORT EN58$$I
IF58$$I:
	      Message msgSameSwitch		;				;AN002;
	      mov     byte [es:Fatal_Error],YES ;				;AN002;
;	   ENDIF$				;				;AN000;
EN58$$I:
;	ENDIF$					;				;AN002;
IF57$$I:
	cmp	[es:Switch_String_Buffer.Switch_String_Pointer],Switch_V_Control+Control.Keyword ;AN000;
;	IF$	E				;If /v and haven't already done ;AN000;
	JNE IF62$$I
	   mov	   [es:Switch_String_Buffer.Switch_String_Pointer],0 ;Init for next switch ;AN008;
	   mov	   byte [es:Switch_V_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   test    word [es:SWITCHMAP],SWITCH_V ; it - Only allow one /V entry	;AN002;
;	   IF$	   Z				;				;AN002;
	   JNZ IF63$$I
	      or      word [es:SWITCHMAP],SWITCH_V ;Set /v indicator		;AN000;
	      mov     si,[es:Switch_String_Buffer.Switch_String_Seg] ;Get string address ;;AN000;
	      mov     ds,si			;				;AN000;

;	      assume  ds:nothing

	      mov     si,[es:Switch_String_Buffer.Switch_String_Off] ;		   ;AN000;
	      cmp     byte [ds:si],None     ;Is there a string there?	;AN000;
;	      IF$     NE			;Yep				;AN000;
	      JE IF64$$I
		 cld				;				;AN000;
		 mov	 di,Vol_Label_Buffer        ;Point at buffer to move string;AN000;
		 mov	 cx,Label_Length+1	;Max length of string		;AN000;
		 rep	 movsb			;This will copy string & always ;AN000;
						; leave ASCIIZ end in buffer,	;     ;
						; which is init'd to 13 dup(0)  ;     ;
		 mov	 si,Vol_Label_Buffer        ;Point at string 	   ;AN000;
		 Set_Data_Segment		;Set DS,ES to Data segment	;AN000;
		 mov	 byte [es:Command_Line],YES ;Set flag indicating vol label	;AN000;
		 call	 Get_11_Characters	;Check DBCS and build FCB	;AN000;
;		 IF$	 C			;Bad DBCS setup 		;AN000;
		 JNC IF65$$I
		    Message msgBadVolumeId	;Tell user			;AN000;
		    mov     byte [es:Fatal_Error],YES ;Indicate time to quit		;AN000;
;		 ENDIF$ 			;				;AN000;
IF65$$I:
;	      ENDIF$				;				;AN000;
IF64$$I:
;	   ELSE$				;				;AN002;
	   JMP SHORT EN63$$I
IF63$$I:
	      Message msgSameSwitch		;				;AN002;
	      mov     byte [es:Fatal_Error],YES ;				;AN002;
;	   ENDIF$				;				;AN002;
EN63$$I:
;	ENDIF$					;				;AN000;
IF62$$I:
	cmp	[es:Switch_Buffer.Switch_Pointer],Switch_Autotest_Control+Control.Keyword ;AN000;
;	IF$	E				;				;AN000;
	JNE IF71$$I
	   mov	   byte [es:Switch_Autotest_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   or	   word [es:SWITCHMAP],SWITCH_AUTOTEST ;				;AN000;
;	ENDIF$					;				;AN000;
IF71$$I:

IF ShipDisk

	cmp	[es:Switch_Buffer.Switch_Pointer],Switch_Z_Control+Control.Keyword ;an000; dms;/Z switch?
;	IF$	E				;				;an000; dms;yes
	JNE IF73$$I
	   mov	   byte [es:Switch_Z_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   or	   word [es:SWITCHMAP],SWITCH_Z ;				;an000; dms;signal switch found
;	ENDIF$					;				;an000; dms;
IF73$$I:

end if

	cmp	word [es:Switch_String_Buffer+Switch_Return.Switch_Pointer],Switch_F_Control+Control.Keyword ;  ;AN000;
;	IF$	E				;				;AN000;
	JNE IF75$$I
	   mov	   byte [es:Switch_F_Control+Control.Keyword],20h ;an000; dms;remove switch from table
	   mov	   word [es:Switch_String_Buffer+Switch_Return.Switch_Pointer],0 ;an000; dms; clear out ptr for next iteration
	   mov	   [es:Switch_Num_Buffer.Switch_Num_Pointer],0 ;Init for next switch ;AN008;
	   test    word [es:SWITCHMAP],SWITCH_F ; it - do this because SysParse ;AN002;
;	   IF$	   Z				; reuses string buffer each time;AN002;
	   JNZ IF76$$I
	      or      word [es:SWITCHMAP],SWITCH_F ;				;AN000;
	      mov     al,[es:Switch_String_Buffer.Switch_String_Item_Tag] ; Indicate what size;AN000;
	      or      [es:SizeMap],al ;				;AN000;
;	   ELSE$				;				;AN002;
	   JMP SHORT EN76$$I
IF76$$I:
	      Message msgSameSwitch		;				;AN002;
	      mov     byte [es:Fatal_Error],YES ;				;AN002;
;	   ENDIF$				;				;AN002;
EN76$$I:
;	ENDIF$					;				;AN000;
IF75$$I:
	pop	di				;Restore parse regs		;AN000;
	pop	cx				;				;AN000;
	pop	si				;				;AN000;
	pop	ds				;				;AN000;
	ret					;				;AN000;

;Interpret_Parse endp				;				;AN000;



;*****************************************************************************
;Routine name: Validate_Target_Drive
;*****************************************************************************
;
;Description: Control routine for validating the specified format target drive.
;	      If any of the called routines find an error, they will print
;	      message and terminate program, without returning to this routine
;
;Called Procedures: Check_Target_Drive
;		    Check_For_Network
;		    Check_Translate_Drive
;
;Change History: Created	5/1/87	       MT
;
;Input: Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;
;	CALL Check_Target_Drive
;	IF !Fatal_Error
;	   CALL Check_For_Network
;	   IF !Fatal_Error
;	      CALL Check_Translate_Drive
;	   ENDIF
;	ENDIF
;	ret
;*****************************************************************************

Procedure Validate_Target_Drive 		;				;AN000;
						;
	call	Check_Target_Drive		;See if valid drive letter	;AN000;
	cmp	byte [es:Fatal_Error],YES ;Can we continue?		;AN000;
;	IF$	NE				;Yep				;AN000;
	JE IF80$$I
	   call    Check_For_Network		;See if Network drive letter	;AN000;
	   cmp	   byte [es:Fatal_Error],YES ;Can we continue?		;AN000;
;	   IF$	   NE				;Yep				;AN000;
	   JE IF81$$I
	      call    Check_Translate_Drive	;See if Subst, Assigned 	;AN000;
;	   ENDIF$				;- Fatal_Error passed back	;AN000;
IF81$$I:
;	ENDIF$					;				;AN000;
IF80$$I:
	ret					;				;AN000;

;Validate_Target_Drive endp			;				;AN000;

;*****************************************************************************
;Routine name: Check_Target_Drive
;*****************************************************************************
;
;Description: Check to see if valid DOS drive by checking if drive is
;	      removable. If error, the drive is invalid. Save default
;	      drive info.
;
;Called Procedures: Message (macro)
;
;Change History: Created	5/1/87	       MT
;
;Input: Fatal_Error = NO
;
;Output: BIOSFile = default drive letter
;	 DOSFile = default drive letter
;	 CommandFile = default drive letter
;	 Fatal_Error = YES/NO
;
;Psuedocode
;----------
;
;	Get default drive (INT 21h, AH = 19h)
;	Convert it to drive letter
;	Save into BIOSFile,DOSFile,CommandFile
;	See if drive removable (INT 21h, AX=4409h IOCtl)
;	IF error - drive invalid
;	   Display Invalid drive message
;	   Fatal_Error= YES
;	ENDIF
;	ret
;*****************************************************************************

Procedure Check_Target_Drive			;				;AN000;
						;
	DOS_Call Get_Default_Drive		;Find the current drive 	;AC000;
	add	al,'A'				;Convert to drive letter	;     ;
	mov	[es:BiosFile],al ;Put it into path strings	;     ;
	mov	[es:DosFile],al ;   "  "	"  "		;     ;
	mov	[es:CommandFile],al ;   "  "	"  "		;     ;
	mov	bl,[es:drive] ;Set up for next call		;AN000;
	inc	bl				;A=1,B=2 for IOCtl call 	;AN000;
	mov	al,09h				;See if drive is local		;AC000;
	DOS_Call IOCtl				;-this will fail if bad drive	;AC000;
;	IF$	C				;CY means invalid drive 	;AC000;
	JNC IF84$$I
	   Extended_Message			;Print message			;AC000;
	   mov	   byte [es:Fatal_Error],YES ;Indicate error 		;AN000;
;	ENDIF$					;				;AN000;
IF84$$I:
	ret					;And we're outa here            ;AN000;

;Check_Target_Drive endp 			;				;AN000;

;*****************************************************************************
;Routine name: Check_For_Network
;*****************************************************************************
;
;Description: See if target drive isn't local, or if it is a shared drive. If
;	      so, exit with error message. The IOCtl call is not checked for
;	      an error because it is called previously in another routine, and
;	      invalid drive is the only error it can generate. That condition
;	      would not get this far
;
;Called Procedures: Message (macro)
;
;Change History: Created	5/1/87	       MT
;
;Input: Drive
;	   Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;	See if drive is local (INT 21h, AX=4409 IOCtl)
;	IF not local
;	   Display network message
;	   Fatal_ERROR = YES
;	ELSE
;	   IF  8000h bit set on return
;	      Display assign message
;	      Fatal_Error = YES
;	   ENDIF
;	ENDIF
;	ret
;*****************************************************************************

Procedure Check_For_Network			;				;AN000;
						;
	mov	bl,[es:drive] ;Drive is 0=A, 1=B		;     ;
	inc	bl				;Get 1=A, 2=B for IOCtl call	;     ;
	mov	al,09h				;See if drive is local or remote;AC000;
	DOS_Call IOCtl				;We will not check for error	;AC000;
	test	dx,Net_Check			;if (x & 1200H)(redir or shared);     ;
;	IF$	NZ				;Found a net drive		;AC000;
	JZ IF86$$I
	   Message msgNetDrive			;Tell 'em                       ;AC000;
	   mov	   byte [es:Fatal_Error],YES ;Indicate bad stuff		;AN000;
;	ELSE$					;Local drive, now check assign	;AN000;
	JMP SHORT EN86$$I
IF86$$I:
	   test    dx,Assign_Check		;8000h bit is bad news		;     ;
;	   IF$	   NZ				;Found it			;AC000;
	   JZ IF88$$I
	      Message msgAssignedDrive		;Tell error			;AC000;
	      mov     byte [es:Fatal_Error],YES ;Indicate bad stuff		;AN000;
;	   ENDIF$				;				;AN000;
IF88$$I:
;	ENDIF$					;				;AN000;
EN86$$I:
	ret					;				;AN000;

;Check_For_Network endp				;				;AN000;

;*****************************************************************************
;Routine name: Check_Translate_Drive
;*****************************************************************************
;
;Description: Do a name translate call on the drive letter to see if it is
;	      assigned by SUBST or ASSIGN
;
;Called Procedures: Message (macro)
;
;Change History: Created	5/1/87	       MT
;
;Input: Drive
;	   Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;
;Psuedocode
;----------
;	Put drive letter in ASCIIZ string "d:\",0
;	Do name translate call (INT 21)
;	IF drive not same
;	   Display assigned message
;	   Fatal_Error = YES
;	ENDIF
;	ret
;*****************************************************************************

Procedure Check_Translate_Drive 		;				;AN000;
						;
	mov	bl,[es:drive] ;Get drive			;     ;
	add	byte [es:TRANSRC],bl   ;Make string "d:\"		;     ;
	mov	si,TRANSRC         ;Point to translate string	;     ;
	push	ds				;Set ES=DS (Data segment)	;     ;
	pop	es				;     "  "	"  "		;     ;
	mov	di,Command_Line_Buffer        ;Point at output buffer 	;     ;
	DOS_Call xNameTrans			;Get real path			;AC000;
	mov	bl,byte [es:TRANSRC]   ;Get drive letter from path	;     ;
	cmp	bl,byte [es:Command_Line_Buffer] ;Did drive letter change?	;     ;
;	IF$	NE				;If not the same, it be bad	;AC000;
	JE IF91$$I
	   Message msgAssignedDrive		;Tell user			;AC000;
	   mov	   byte [es:Fatal_Error],YES ;Setup error flag		;AN000;
;	ENDIF$					;				;AN000;
IF91$$I:
	ret					;				;AN000;

;Check_Translate_Drive endp			;				;AN000;

;*****************************************************************************
;Routine name: Hook_CNTRL_C
;*****************************************************************************
;
;Description: Change the interrupt handler for INT 13h to point to the
;	      ControlC_Handler routine
;
;Called Procedures: None
;
;Change History: Created	4/21/87 	MT
;
;Input: None
;
;Output: None
;
;Psuedocode
;----------
;
;	Point at ControlC_Handler routine
;	Set interrupt handler (INT 21h, AX=2523h)
;	ret
;*****************************************************************************

Procedure Hook_CNTRL_C				;				;AN000;
						;
	mov	al,23H				;Specify CNTRL handler		;     ;
	mov	dx, ControlC_Handler        ;Point at it			;     ;
	push	ds				;Save data seg			;     ;
	push	cs				;Point to code segment		;     ;
	pop	ds				;				;     ;
	DOS_Call Set_Interrupt_Vector		;Set the INT 23h handler	;AC000;
	pop	ds				;Get Data degment back		;     ;
	ret					;				;AN000;

;Hook_CNTRL_C endp				;				;AN000;

;=========================================================================
; Check_For_Invalid_Drive	: This routine checks the AX received by
;				  FORMAT on its entry.	This value will
;				  tell us if we are attempting to format
;				  a JOINED drive.
;
;	Inputs	: Org_AX	- AX on entry to FORMAT
;
;	Outputs : Fatal_Error	- Yes if AL contained FFh
;=========================================================================

Procedure Check_For_Invalid_Drive		;an000; dms;

	push	ax				;an000; dms;save ax
	cmp	byte [es:FAT_Flag],YES ;an000; dms;FAT system?
;	if$	e				;an000; dms;yes
	JNE IF93$$I
		mov	ax,[es:Org_AX] ;an000; dms;get its org. value
		cmp	al,0ffh 		;an000; dms;Invalid drive?
;		if$	e			;an000; dms;yes
		JNE IF94$$I
			mov	byte [es:Fatal_Error],YES ;an000; dms;flag an error
			mov	ax,Invalid_Drive;an000; dms;error message
			Extended_Message	;an000; dms;tell error
;		endif$				;an000; dms;
IF94$$I:
;	endif$					;an000; dms;
IF93$$I:
	pop	ax				;an000; dms;
	ret					;an000; dms;

;Check_For_Invalid_Drive endp			;an000; dms;


;=========================================================================
; Determine_FAT_Non_FAT 	- This routine determines whether or
;				  not a device is formatted to a FAT
;				  specification versus a Non-FAT
;				  specification.
;
;	Inputs	: DX - Pointer to device parameters buffer
;
;	Outputs : DeviceParameters - buffer containing BPB.
;
;	Date	: 11/6/87
;=========================================================================

Procedure Determine_FAT_Non_FAT 						;an012; dms;

	push	ax								;an012; dms;save regs
	push	dx								;an012; dms;

	lea	dx,[deviceParameters]     ;an012; dms;point to buffer
	mov	[es:deviceParameters.DP_SPECIALFUNCTIONS], 0 ;an012; dms;get default BPB
	call	GetDeviceParameters						;an012; dms;make the call
;	if$	nc								;an012; dms;no error occurred
	JC IF97$$I
		cmp	byte [es:deviceParameters.DP_BPB+A_BPB.BPB_NUMBEROFFATS],00h ;an012; dms;non-FAT system?
;		if$	e							;an012; dms;yes
		JNE IF98$$I
			mov	byte [es:FAT_Flag],NO ;an012; dms;signal system non-FAT
			mov	ax,5f07h					;an012; dms;allow access to disk
			mov	dl,[es:drive] ;an012; dms;get 0 based driver number
			int	21h						;an012; dms;allow access to the drive
;		else$								;an012; dms;FAT system
		JMP SHORT EN98$$I
IF98$$I:
			mov	byte [es:FAT_Flag],YES ;an012; dms;flag FAT system
;		endif$								;an012; dms;
EN98$$I:
;	endif$									;an012; dms;
IF97$$I:

	pop	dx								;an012; dms;restore regs
	pop	ax								;an012; dms;

	ret									;an012; dms;

;Determine_FAT_Non_FAT	endp							;an012; dms;




end if
;	end

