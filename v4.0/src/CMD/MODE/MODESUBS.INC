
;ษออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;  AX001 - P3976: Need to have all pieces of messages in MODE.SKL so have to
;		  implement the SYSGETMSG method of getting addressability to
;		  the pieces.  This means that the code does a SYSGETMSG call
;		  which returns a pointer (DS:SI) to the message piece.  The
;		  address is then put in the sublist block for the message
;		  being issued.

;  AC002 - P3258: PS/2 only COM parameters were being allowed on non-PS/2
;		  machines.  Added checks for baud=19200, parity=mark or space,
;		  data=5 or 6, stop=1.5 for both keyword and positional forms
;		  in MODEPARSE.ASM.  Had to enlarge the possible parm size for
;		  "Function not supported on this computer - ?????????????"

;บ											  บ
;ศออออออออออออออออออออออออออออออออ  P R O L O G  อออออออออออออออออออออออออออออออออออออออออผ


;ษอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออป
;บ											  บ

;PUBLICs for the sublists are handled in modemes.asm
;PUBLIC	 Utility_Msg_Class		  ;AN001;

;บ											  บ
;ศอออออออออออออออออออออออออออออออ  P U B L I C S  ออออออออออออออออออออออออออออออออออออออออผ


;
;*****************************************************************************
; External data declarations
;*****************************************************************************



;
;*****************************************************************************
; Message Retriever equates
;*****************************************************************************
;

include 'COMMON.STC'   ;contains the following structure

;sublist_def  STRUC

;	      db  ?  ;Sublist Length, fixed
;	      db  ?  ;Reserved, not used yet		       ;AN000;
;	      dw  ?  ;offset
;sublist_seg  dw  ?  ;segment part of pointer to piece of message
;	      db  ?  ;number of this piece of the message,0 indicates special end of message format ;AN000;
;	      db  ?  ;flags
;	      db  ?  ;maximum field width
;	      db  ?  ;minimum field width
;	      db  ?  ;character to use for padding

;sublist_def  ENDS



include 'MODEQUAT.INC'   ;contains the following two equates for this file

;FLAGS field bit(s) values

;Left_Align		 equ	 0	 ;00xxxxxx
;Right_Align		 equ	 80h	 ;10xxxxxx

Char_Field_Char    equ	   0		 ;a0000000
Char_Field_ASCIIZ  equ	   00010000B	 ;a0010000

;Unsgn_Bin_Byte    equ	   11h	   ;a0010001
Unsgn_Bin_Word	  equ	  21h	  ;a0100001
Unsgn_Bin_DWord   equ	  31h	  ;a0110001

Sgn_Bin_Byte	  equ	  12h	  ;a0010010
Sgn_Bin_Word	  equ	  22h	  ;a0100010
Sgn_Bin_DWord	  equ	  32h	  ;a0110010

Bin_Hex_Byte	     equ     13h     ;a0010011
Bin_Hex_Word	     equ     23h     ;a0100011
Bin_Hex_DWord	     equ     33h     ;a0110011



blank			equ	" "
No_Function		equ	0
No_Replace		equ	0

Msg_Ser_Class		equ	0
Ext_Err_Class		equ	1
Parse_Error_Class	equ	2
Utility_Msg_Class	equ	0FFh

Reserved		equ	0

Sublist_Length		equ	sizeof.sublist_def

to_be_filled_in 	EQU	 77H	  ;conspicious number



;
;*****************************************************************************
; Message Sublist Tables
;*****************************************************************************
;
;The  following  control  blocks  are	used   for   messages  with
;replaceable  paramters.  These  control  blocks  are  used by	the
;SysDispMsg routine.
;

;---------------------------			;
label first_sublist byte

label sublist_invalid_switch byte      ;AN000;description of %0
label sublist_invalid_parameter byte    ;AN000;description of %0
						;
	db		Sublist_Length		;fixed				;AN000;
	db		Reserved		;not used yet			;AN000;
label offending_parameter_ptr word
	dw		OFFENDING_PARAMETER          ;pointer to string or binary value	;AN000;
	dw		to_be_filled_in 	;
	db		0			;ID, special end of message format ;AN000;
sub_typ db		Left_Align+Char_Field_ASCIIZ ;maybe changed	     ;AN000;
	db		0			;Max width 123, 128-"MODE "    ;AN000;
	db		1			;May be one char long	       ;AN000;
	db		blank			;				;AN000;
;---------------------------			;

label sublist_err1 byte   ;AN000;description of %0
						;
	db		Sublist_Length		;fixed				;AN000;
	db		Reserved		;not used yet			;AN000;
label illegal_device_ptr word
	dw		?			;pointer to device name string filled in by modecom;AN000;
	dw		to_be_filled_in 	;
	db		0			;ID, special end of message format ;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;		;AN000;
	db		5			;Max width, "LPT1:"    ;AN000;
	db		4			;"COM3"                        ;AN000;
	db		blank			;				;AN000;
;---------------------------			;
label Sublist_PT80 byte   ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		PT80N         ;where the printer number is stashed ;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;ID, only one sublist		;AN000;
	db		Left_Align+Char_Field_Char ;			   ;AN000;
	db		1			;				;AN000;
	db		1			;				;AN000;
	db		blank			;no filler needed but still have this field to fill
;---------------------------			;
label Sublist_PT132 byte   ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		PT132N         ;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_Char ;			   ;AN000;
	db		1			;				;AN000;
	db		1			;				;AN000;
	db		blank			;				;AN000;
;---------------------------			;
label Sublist_initmsg byte   ;CR,LF,"COM%c: %3s,%c,%c,%c,%c",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		DEVICE         ;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;first of 6		       ;AN000;
	db		Left_Align+Char_Field_Char			      ;AN000;
	db		1			;				;AN000;
	db		1			;one char number between 1 and 4;AN000;
	db		blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label pbaud_ptr word
	dw		pBAUD         ;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		2			;second of 6			;AN000;
	db		Left_Align+Char_Field_ASCIIZ			      ;AN000;
	db		0;RPS			;19200				;AN000;
	db		3			;110, 300 etc the shortest
	db		blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label pparity_ptr word    ;allow access from invoke
	dw		pPARITY         ;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		3			;third of 6		       ;AN000;
	db		Left_Align+Char_Field_Char			      ;AN000;
	db		1			;				;AN000;
	db		1			;one char, n, o, e.
	db		blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		pDATA         ;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		4			;fourth of 6			;AN000;
	db		Left_Align+Char_Field_Char			      ;AN000;
	db		1			;				;AN000;
	db		1			;one char number between 6 and 8;AN000;
	db		blank			;never used, will display at least the default data bits

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label pstop_ptr word
	dw		pSTOP         ;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		5			;fifth of 6		       ;AN000;
	db		Left_Align+Char_Field_ASCIIZ			      ;AN000;
	db		0			;big enough for "1.5"           ;AN000;
	db		1			;one char number between 1 and 2;AN000;
	db		blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		Pparm         ;				;AN000;
	dw		to_be_filled_in 	;				;AN000;
	db		6			;last of 6		      ;AN000;
	db		Left_Align+Char_Field_Char			      ;AN000;
	db		1			;				;AN000;
	db		1			;one char "P" or "-"
	db		blank			;				;AN000;
;---------------------------			;
label sublist_SHIFT_MSG byte  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label lftm_or_rghtm_ptr word
;AC001; dw		offset leftmost   ;filled in with pointer to "leftmost 0?" or "rightmost 9?"
	dw		?		  ;AC001;filled in with pointer to "leftmost 0?" or "rightmost 9?"
	dw		to_be_filled_in 	;				;AN000;
	db		1			;only 1 sub list			       ;AN000;
	db		Left_Align+Char_Field_ASCIIZ			  ;AN000;
	db		0;RPS			;rightmost 9?		       ;AN000;
	db		10			;leftmost 0?		       ;AN000;
	db		blank			;				;AN000;
;---------------------------			;
label Sublist_redirmsg byte  ;AN000; CR,LF,"LPT%1: rerouted to COM%2:",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		REDPT         ;filled with printer number
	dw		to_be_filled_in
	db		1			;first of 2			;AN000;
	db		Left_Align+Char_Field_Char ;			  ;AN000;
	db		1			;				;AN000;
	db		1
	db		blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		REDCOM         ;filled with COM port number
	dw		to_be_filled_in
	db		2			;second of 2			 ;AN000;
	db		Left_Align+Char_Field_Char ;			  ;AN000;
	db		1			;				;AN000;
	db		1
	db		blank			;				;AN000;

;---------------------------			;
label Sublist_notremsg byte  ;AN000; CR,LF,"LPT%1: not rerouted",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		NOTREDPT         ;filled with printer number
	dw		to_be_filled_in
	db		1			;only one
	db		Left_Align+Char_Field_Char ;			  ;AN000;
	db		1			;				;AN000;
	db		1
	db		blank			;				;AN000;

;---------------------------			;
label sublist_RETPARTO byte   ;	;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
;AC001;inf_or_no_ptr	       LABEL WORD	       ;filled in with pointer to "No" or "infinit"
;AC001; dw		offset infinite      ;				     ;AN000;
	dw		?			;AC001;filled in with pointer to "No" or "infinit"
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ			   ;AN000;
	db		0;RPS			;				;AN000;
	db		2			;				;AN000;
	db		blank			;				;AN000;
;---------------------------			;
label sublist_CANT_SHIFT byte     ;"Unable to shift screen ...." ;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label LEFT_OR_RIGHT_PTR word      ;AN000;
;AC001; dw		offset left		;FILLED WITH OFFSET OF 'left' or 'right'
	dw		?			;AC001;FILLED WITH OFFSET OF 'left' or 'right'
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ			   ;AN000;
	db		0;RPS			;				;AN000;
	db		4			;				;AN000;
	db		blank			;				;AN000;
;---------------------------			;
label Sublist_CPMSG2 byte   ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label CPMSGLST2DEV word   ;filled with pointer to device name
	dw		?
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0			;				;AN000;
	db		3			;				;AN000;
	db		blank			;				;AN000;

;---------------------------			;
label Sublist_CPMSG6 byte   ;"Active codepage for device %S is %D",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label CPMSGLST6DEV word   ;filled with pointer to device name
	dw		?
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0			;				;AN000;
	db		3			;				;AN000;
	db		blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		CPMSGLST6CP        ;pointer to area FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID
	dw		to_be_filled_in 	;				;AN000;
	db		2			;2nd of 2			;AN000;
	db		Left_Align+Unsgn_Bin_Word ;AN000;00100001B
	db		5			;codepage numbers could be 5 digits long
	db		1			;theoretically could be 1 digit ;AN000;
	db		blank			;				;AN000;

;---------------------------			;
label Sublist_CPMSG7 byte   ;"Device %1 not prepared",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label CPMSGLST7DEV word   ;FILLED IN BY "QUERY" ROUTINE WITH PTR TO DEVICE NAME
	dw		?
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0			;don't know how long the device name
	db		3			;				;AN000;
	db		blank			;				;AN000;

;---------------------------			;
label sublist_cpmsg8 byte   ;"%1 codepages:",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		?			;filled in with OFFSET TO "HARDWARE" OR "PREPARED"
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS			; both "Hardware" and                  ;AC001;
	db		8			;	"Prepared" are 8 chars long    ;AC001;
	db		blank			;				;AN000;


;---------------------------			;
label Sublist_CPMSG9 byte   ;"  Codepage %d",CR,LF,EOM

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		CPMSGLST9CP        ;pointer to area filled in by "DISPLAY_CPID" in modecp.sal
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Unsgn_Bin_Word ;00100001B
	db		3
	db		3			;				;AN000;
	db		blank			;				;AN000;

;---------------------------			;
label sublist_cpmsg10 byte   ;"MODE %1 Codepage function completed",CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		?			;;FILLED IN TO POINT TO:
						;	     "Status",EOM
						;	     "Prepare",EOM
						;	     "Select",EOM
						;	     "Refresh",EOM
						;	     "Global",EOM
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS
	db		5			;				;AN000;
	db		blank			;				;AN000;

;---------------------------			;
label Sublist_CPMSG13 byte   ;"   %D - %S Codepage",CR,LF,EOM
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label CPMSGLST13CP word     ;FILLED IN WITH CODEPAGE ID
	dw		?
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS			;				;AN000;
	db		3			;				;AN000;
	db		blank			;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label CPMSGLST13TYP word    ;FILLED IN TO POINT TO:
							       ; "Selected",EOM
							       ; "System",EOM
	dw		?
	dw		to_be_filled_in 	;				;AN000;
	db		2			;2nd of 2			;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS			;all codepage numbers are 3 chars long
	db		6			;				;AN000;
	db		blank			;				;AN000;


;---------------------------			;
label sublist_cpmsg17 byte   ;"Device error during %1",BEEP,CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		?			;;FILLED IN TO POINT TO:
						;     "Status",EOM
						;     "Prepare",EOM
						;     "Select",EOM
						;     "Refresh",EOM
						;     "write of font file to device",EOM
	dw		to_be_filled_in
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS			;"write of font file to device",EOM
	db		6			;"Status",EOM
	db		blank			;				;AN000;


;---------------------------			;
label Sublist_LINES_equal byte  ;"LINES=%1",CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label ROW_PTR word     ;FILLED IN TO POINT TO: "NONE", or a row value
	dw		?			;
	dw		to_be_filled_in 	;filled in at initialization time with PRINTF_CODE
	db		1			;				;AN000;
row_type db		Right_Align+Char_Field_ASCIIZ ; 		    ;AN000;
	db		0;RPS			;"NONE"
	db		2			;25, 43, 50			;AN000;
	DB		blank

;---------------------------			;
label Sublist_COLUMNS_equal byte      ;"COLUMNS=%1",CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label COLUMNS_PTR word        ;FILLED IN TO POINT TO: "NONE", or a columns value
	dw		?			;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
COLUMNS_type db 	    Right_Align+Char_Field_ASCIIZ ;			;AN000;
	db		0;RPS
	db		2			;				;AN000;
	DB		blank
;---------------------------			;
label Sublist_RATE_equal byte            ;"RATE=%1",CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label RATE_PTR word      ;FILLED IN TO POINT TO: "NONE", or a rate value
	dw		?			;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
RATE_type db		 Right_Align+Char_Field_ASCIIZ ;		     ;AN000;
	db		0;RPS
	db		2			;				;AN000;
	DB		blank
;---------------------------			;
label Sublist_DELAY_equal byte  ;"DELAY=%1",CR,LF,EOM
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label DELAY_PTR word       ;FILLED IN TO POINT TO: "NONE", or a delay value
	dw		?			;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
DELAY_type db		  Right_Align+Char_Field_ASCIIZ ;		      ;AN000;
	db		0;RPS
	db		1			;				;AN000;
	DB		blank
;---------------------------			;
label Sublist_not_supported byte  ;"Function not supported on this computer -%1"
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label not_supported_PTR word      ;FILLED IN TO POINT TO: the parameter that is not supported
	dw		nada             ;
	dw		to_be_filled_in 	;filled with segment of the .COM file	;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		0;RPS			;AC002;maximum length of the string
	db		1			;				;AN000;
	DB		blank
;---------------------------			;
label Sublist_status_for_device byte    ;"Status for device %1:"
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label stat_dev_ptr word         ;FILLED IN TO POINT TO ONE of the device names in parse.asm
	dw		?			;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Char_Field_ASCIIZ ; 		    ;AN000;
dev_name_size	  db	4			;changed by invoke: 3 for CON, 4 for others
	db		3			;				;AN000;
	db		blank			;				;AN000;

;---------------------------			;

label Sublist_retry_equal byte   ;"RETRY=%1"
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
label retry_type_ptr word
	dw		?			;
	dw		to_be_filled_in 	;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Char_Field_ASCIIZ ; 		    ;AN000;
	db		0;RPS			;max size, "NONE"
	db		1			;min size, "E"                  ;AN000;
	db		blank			;				;AN000;

;---------------------------			;
label sublist_syntax_error byte      ;AN000;description of %0
						;
	db		Sublist_Length		;fixed				;AN000;
	db		Reserved		;not used yet			;AN000;
label syntax_error_ptr word
	dw		OFFENDING_PARAMETER          ;pointer to string or binary value	;AN000;
	dw		to_be_filled_in 	;
	db		0			;ID, special end of message format ;AN000;
	db		Left_Align+Char_Field_ASCIIZ	   ;AN000;
	db		0			;Max width 123, 128-"MODE "    ;AN000;
	db		1			;May be one char long	       ;AN000;
	db		blank			;				;AN000;







; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
Number_of_sublists   =   ((($ - first_sublist) / (sizeof.sublist_def)))



;		    MESSAGE PIECES
;-------------------------------------------------------

PT80N		DB  " "   ;PT80 - CR,LF,"LPT%c: set for 80",CR,LF,EOM

PT132N		DB  " "   ;PT132 - CR,LF,"LPT%c: set for 132",CR,LF,EOM

;INITMSG - CR,LF,"COM%c: %3s,%c,%c,%c,%c",CR,LF,EOM
DEVICE	       DB  " "
pBAUD	       DB  5 DUP(" "),EOM
pPARITY        DB  "e"        ;DEFAULT IS EVEN PARITY
pDATA	       DB  "7"        ;DEFAULT IS 7 DATA BITS PER BYTE
pSTOP	       DB  "1",EOM    ;DEFAULT FOR BAUD > 110, CHANGED TO 2 FOR 110
Pparm	       DB  " "
baud_19200     DB   "19200",EOM

;REDIRMSG - CR,LF,"LPT%c: rerouted to COM%c:",CR,LF,EOM
REDPT		DB  " "
REDCOM		DB  " "

;NOTREMSG - CR,LF,"LPT%c: not rerouted",CR,LF,EOM
NOTREDPT	DB  " "

OFFENDING_PARAMETER  DB 123 DUP (EOM)

nada	    DB	  8,8,8,"   ",0        ;backspace over the " - "

CPMSGLST6CP    DW    44H   ;AC665;FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID


CPMSGLST9CP    DW    99H		 ;FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID


row_value      rb      1  ;filled in by invoke.asm with screen lines requested or current setting
