PAGE	60,132				;
	TITLE	DEBMES.SAL - DEBUGGER MESSAGES PC DOS
;	IF1
;	    %OUT    COMPONENT=DEBUG, MODULE=DEBMES
;	ENDIF

;******************* START OF SPECIFICATIONS *****************************
;
; MODULE NAME:DEBMES.SAL
;
; DESCRIPTIVE NAME: SUPPLIES APPLICABLE MESSAGES TO DEBUG.ASM
;
; FUNCTION: THIS ROUTINE PROVIDES A MEANS BY WHICH MESSAGES MAY BE
;	    OUTPUT FOR DEBUG.  THIS IS HANDLED THROUGH THE MESSAGE
;	    RETRIEVER FUNCTION SYSDISPMSG.  TO
;	    FACILITATE MIGRATION AWAY FROM THE PRINTF UTILITY
;	    THE INTERFACE FOR INVOKING MESSAGES HAS REMAINED THE SAME.
;	    THIS IS ACCOMPLISHED THROUGH THE USE OF MACROS AND TABLES.
;	    EACH MESSAGE HAS A TABLE OF VALUES REQUIRED BY THE MESSAGE
;	    RETRIEVER UTILITIES.  THE MACROS OPERATE ON THESE TABLES
;	    TO SUPPLY SYSDISPMSG WITH THE VALUES NECESSARY
;	    TO PRINT A MESSAGE.
;
; ENTRY POINT: PRINTF
;
; INPUT: PRINTF IS INVOKED AS IT HAS ALWAYS BEEN INVOKED.  DX MUST
;	 POINT TO THE OFFSET OF A MESSAGE TABLE.  THE TABLE POINTED TO
;	 BY DX CONTAINS ALL THE NECESSARY INFORMATION FOR THAT MESSAGE
;	 TO BE PRINTED.
;
; EXIT-NORMAL: NO CARRY
;
; EXIT-ERROR: CARRY SET - EITHER MESSAGE NOT FOUND OR UNABLE TO BE DISPLAYED
;
; INTERNAL REFERENCES:
;
;	ROUTINE:DISP_MESSAGE - THIS MACRO IS USED TO DIPLAY A MESSAGE
;			       VIA SYSDISPMSG.	IT TAKES AS INPUT A POINTER
;			       IN DX.  THIS POINTER POINTS TO A TABLE OF
;			       VALUES FOR THE REQUESTED MESSAGE.
;			       DISP_MESSAGE OBTAINS THE VALUES IT NEEDS TO
;			       TO INVOKE SYSDISPMSG FROM THIS TABLE.
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: SYSMSG.INC  - THIS ROUTINE IS SUPPLIED TO INTERFACE THE
;			       MESSAGE RETRIEVER SERVICES.
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
.XLIST

	include 'SYSMSG.INC' ;an000;message retriever

.LIST

MSG_UTILNAME <DEBUG>			;an000;DEBUG messages

;=========================================================================
;revised debmes.asm
;=========================================================================

fatal_error	equ	45		;fatal message handler error
unlim_width	equ	00h		;unlimited output width
pad_blank	equ	20h		;blank pad
pre_load	equ	00h		;an000;normal pre-load
pad_zero	equ	30h		;an000;zero pad


FALSE	EQU	0
TRUE	equ	(NOT FALSE)

;SYSVER 	 EQU FALSE		 ;if true, i/o direct to bios
	include 'SYSVER.INC'

;=========================================================================
; macro disp_message: the macro takes the message obtained in get_message
;		      and displays it to the applicable screen device.
;=========================================================================

macro disp_message tbl
{

	push	si			;an000;save affected reg
	push	di			;an000;
	push	ax			;an000;
	push	bx			;an000;
	push	cx			;an000;
	push	dx			;an000;

	push	tbl			;an000;exchange tbl with si
	pop	si			;an000;

	mov	ax,[si] 		;an000;move message number to ax
	mov	bx,[si+3]		;an000;display handle
	mov	cx,[si+7]		;an000;number of subs
	mov	dl,[si+9]		;an000;function type
	mov	di,[si+10]		;an000;input buffer if appl.
	mov	dh,[si+2]		;an000;message type
	mov	si,[si+5]		;an000;sublist

	call	SYSDISPMSG		;an000;display the message

	pop	dx			;an000;restore affected reg
	pop	cx			;an000;
	pop	bx			;an000;
	pop	ax			;an000;
	pop	di			;an000;
	pop	si			;an000;


} ;an000;end macro disp_message

;=========================================================================
; macro disp_message: end macro
;=========================================================================



if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_CSTACK
end if

if SEGSEL = S_DATA

end if

;DG	GROUP	CODE,CONST,CSTACK,DATA


if SEGSEL = S_CODE;an000;code segment
;	assume	cs:dg,ds:dg,ss:dg,es:dg ;an000;

;	public	printf			;an000;share printf
;;	public	disp_fatal		;an000;fatal error display
;	public	pre_load_message	;an000;message pre load

.XLIST

MSG_SERVICES <MSGDATA>

.LIST

;=========================================================================
;	  include sysmsg.inc - message retriever services
;options selected:
;		   NEARmsg
;		   DISPLAYmsg
;		   LOADmsg
;		   INPUTmsg
;		   CHARmsg
;		   NUMmsg
;		   CLSAmsg
;		   CLSBmsg
;		   CLSCmsg
;		   CLSDmsg
;=========================================================================

.XLIST

MSG_SERVICES <LOADmsg>			;an000;load the messages
MSG_SERVICES <DISPLAYmsg,CHARmsg,NUMmsg>;an000;get and display messages
MSG_SERVICES <INPUTmsg> 		;an000;input from keyboard
MSG_SERVICES <DEBUG.CLA,DEBUG.CLB>	;an000;message types
MSG_SERVICES <DEBUG.CLC,DEBUG.CLD>	;an000;
MSG_SERVICES <DEBUG.CL1,DEBUG.CL2>	;an000;

.LIST

;=========================================================================
; printf: printf is a replacement of the printf procedure used in DOS
;	  releases prior 4.00.	printf invokes the macros get_message and
;	  disp_message to invoke the new message handler.  the interface
;	  into printf will continue to be a pointer to a message passed
;	  in DX.  the pointer is pointing to more than a message now.  it
;	  is pointing to a table for that message containing all relevant
;	  information for retieving and printing the message.  the macros
;	  get_message and disp_message operate on these tables.
;=========================================================================

printf:            ;an000;printf procedure

	disp_message dx 		;an000;display a message
;;	if$	c			;an000;if an error occurred
;;		call disp_fatal 	;an000;display the fatal error
;;	endif$				;an000;

	ret				;an000;return to caller

;printf	endp				;an000;end printf


;=========================================================================
; disp_fatal: this routine displays a fatal error message in the event
;	      an error occurred in disp_message.
;=========================================================================

;;disp_fatal	  proc	  near		  ;an000;fatal error message
;;
;;	  mov	  ax,fatal_error	  ;an000;fatal_error number
;;	  mov	  bx,stdout		  ;an000;print to console
;;	  mov	  cx,0			  ;an000;no parameters
;;	  mov	  dl,no_input		  ;an000;no input will be coming
;;	  mov	  dh,UTILITY_MSG_CLASS	     ;an000;utility messages
;;	  call	  sysdispmsg		  ;an000;dispaly fatal error
;;	  ret				  ;an000;return to caller
;;
;;disp_fatal	  endp			  ;an000;end disp_fatal


;=========================================================================
; PRE_LOAD_MESSAGE : This routine provides access to the messages required
;		     by DEBUG.	This routine will report if the load was
;		     successful.  An unsuccessful load will cause DEBUG
;		     to terminate with an appropriate error message.
;
;	Date	  : 6/15/87
;=========================================================================

PRE_LOAD_MESSAGE:           ;an000;pre-load messages

	call	SYSLOADMSG			;an000;invoke loader

;	if$	c				;an000;if an error
	JNC IF1$$S
		pushf				;an000;save flags
		call	SYSDISPMSG		;an000;let him say why
		popf				;an000;restore flags
;	endif$					;an000;
IF1$$S:

	ret					;an000;return to caller

;PRE_LOAD_MESSAGE	endp			;an000;end proc

include 'MSGDCL.INC'

end if ;an000;end code segment


if SEGSEL = S_CONST

;	PUBLIC	ENDMES_PTR,CRLF_PTR,NAMBAD_PTR
;	PUBLIC	NOTFND_PTR,NOROOM_PTR,BADVER
;	PUBLIC	NOSPACE_PTR,DRVLET
;	PUBLIC	ACCMES_PTR,PROMPT_PTR
;	PUBLIC	TOOBIG_PTR,SYNERR_PTR,BACMES_PTR
;	PUBLIC	HEXERR_PTR,HEXWRT_PTR,WRTMES_PTR,EXEBAD_PTR,EXEWRT_PTR
;	PUBLIC	EXECEMES_PTR, PARITYMES_PTR, NONAMESPEC_PTR
;	PUBLIC	dr1_ptr,dr2_ptr,dr3_ptr,dr4_ptr 	;ac000;new messages
;	PUBLIC	CHANGE_FLAG_PTR,DF_ERROR,BF_ERROR,BR_ERROR,BP_ERROR
;	PUBLIC	CONSTEND

;======================= TABLE STRUCTURE =================================
;
;	byte 1	-	message number of message to be displayed
;	byte 2	-	message type to be used, i.e.;class 1, utility, etc.
;	byte 3	-	display handle, i.e.; console, printer, etc.
;	byte 4	-	pointer to substitution list, if any.
;	byte 6	-	number of replaceable parameters, if any.
;	byte 7	-	type of input from keyboard, if any.
;	byte 8	-	pointer to buffer for keyboard input, if any.
;
;=========================================================================

	IF	SYSVER

;	    PUBLIC  BADDEV_PTR,BADLSTMES_PTR


label baddev_ptr word     ;an000;"Bad device name",0
	    dw	    0006		;an000;message number 6
	    db	    UTILITY_MSG_CLASS	   ;an000;utility message
	    dw	    STDOUT		;an000;display handle
	    dw	    00			;an000;sublist
	    dw	    00			;an000;no subs
	    db	    NO_INPUT		;an000;no keyboard input
	    dw	    00			;an000;no keyboard buffer

label badlstmes_ptr word  ;an000;"Couldn't open list device
					;      PRN","Enter name of list
					;      device?"
	    dw	    0007		;an000;message number 7
	    db	    UTILITY_MSG_CLASS	   ;an000;utility message
	    dw	    STDOUT		;an000;display handle
	    dw	    00			;an000;sublist
	    dw	    00			;an000;no subs
	    db	    DOS_KEYB_INP	;an000;keyboard input
	    dw	    00			;an000;no keyboard buffer


	end if

;================= REPLACEABLE PARAMETER SUBLIST STRUCTURE ===============
;
;	byte 1	-	substitution list size, always 11
;	byte 2	-	reserved for use by message handler
;	byte 3	-	pointer to parameter to be used as a substitution
;	byte 7	-	which parameter is this to replace, %1, %2, etc.
;	byte 8	-	determines how the parameter is to be output
;	byte 9	-	determines the maximum width of the parameter string
;	byte 10 -	determines the minimum width of the parameter string
;	byte 11 -	define what is to be used as a pad character
;
;=========================================================================


;=========================================================================
;		replaceable parameter sublists
;=========================================================================

label db_synerr_sub dword  ;an000;synerr parameters
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw arg_buf;an000;point to argument buffer
	dw DG_
	db	01			;an000;parameter one
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum width
	db	pad_blank		;an000;blank pad

label db_change_sub dword  ;an000;synerr parameters
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw arg_buf;an000;point to argument buffer
	dw DG_
	db	01			;an000;parameter one
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum width
	db	pad_blank		;an000;blank pad

label db_drive_error dword  ;an000;drive error parameters
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw drvlet;an000;point to drive letter
	dw DG_
	db	01			;an000;parameter one
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	01			;an000;1 byte
	db	01			;an000;1 byte
	db	pad_blank		;an000;blank pad



;=========================================================================
;		end replaceable parameter sublists
;=========================================================================


label crlf_ptr word   ;an000;13,10,0
	dw	0008			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label bacmes_ptr word   ;an000;32,8,0
	dw	0044			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label badver word   ;an000;"Incorrect DOS version"
	dw	0001			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label endmes_ptr word   ;an000;13,10,"Program terminated
					;	      normally",0
	dw	0009			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label nambad_ptr word   ;an000;"Invalid drive specification",0
	dw	0010			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label notfnd_ptr word   ;an000;"File not found",0
	dw	0002			;an000;message number
	db	EXT_ERR_CLASS		;an000;extended error
	dw	STDERR			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label noroom_ptr word   ;an000;"File creation error",0
	dw	0012			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label nospace_ptr word   ;an000;"Insufficient space on disk",0
	dw	0013			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label dr1_ptr word   ;an000;"Disk error reading drive %1"
	dw	0014			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_drive_error	;an000;sublist
	dw	01			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label dr2_ptr word   ;an000;"Disk error writing drive %1"
	dw	0015			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_drive_error	;an000;sublist
	dw	01			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label dr3_ptr word   ;an000;"Write protect error reading
					;	drive %1"
	dw	0016			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_drive_error	;an000;sublist
	dw	01			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label dr4_ptr word   ;an000;"Write protect error writing
					;	drive %1"
	dw	0017			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_drive_error	;an000;sublist
	dw	01			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label toobig_ptr word   ;an000;"Insufficient memory",0
	dw	0008			;an000;message number
	db	EXT_ERR_CLASS		;an000;utility message
	dw	STDERR			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label synerr_ptr word   ;an000;"%1^Error",0
	dw	0019			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_synerr_sub	;an000;sublist
	dw	01			;an000;1 sub - leading spaces
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label hexerr_ptr word   ;an000;"Error in EXE or HEX file",0
	dw	0020			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label exebad_ptr word   ;an000;"Error in EXE or HEX file",0
	dw	0020			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label hexwrt_ptr word   ;an000;"EXE and HEX files cannot be
					;	written",0
	dw	0021			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label exewrt_ptr word   ;an000;"EXE and HEX files cannot be
					;	written",0
	dw	0021			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label execemes_ptr word   ;an000;"EXEC failure",0
	dw	0022			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label nonamespec_ptr word  ;an000;"(W)rite error, no destination
					;	defined",0
	dw	0023			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label accmes_ptr word   ;an000;Access denied",0
	dw	0024			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label paritymes_ptr word  ;an000;"Parity error or nonexistant
					;	memory error detected",0
	dw	0025			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label prompt_ptr word   ;an000;"-",0
	dw	0026			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label change_flag_ptr word  ;an000;"%1 -",0
	dw	0027			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_change_sub	;an000;sublist
	dw	01			;an000;no subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

df_error	db	"df",0
bf_error	db	"bf",0
br_error	db	"br",0
bp_error	db	"bp",0
drvlet		db	"A",0

label CONSTEND byte

end if

if SEGSEL = S_DATA

;	PUBLIC	HEX_ARG1,HEX_ARG2,HEX_PTR,ARG_BUF
;	PUBLIC	ARG_BUF_PTR,ADD_PTR,ERR_TYPE
;	PUBLIC	CRLF_PTR,ADD_ARG,SUB_ARG,PROMPT_PTR
;	PUBLIC	REGISTER_PTR,REG_NAME,REG_CONTENTS
;	PUBLIC	SINGLE_REG_PTR,SINGLE_REG_ARG
;	PUBLIC	ERRMES_PTR,LOC_PTR,LOC_ADD
;	PUBLIC	LITTLE_PTR,BIG_PTR,LITTLE_CONTENTS
;	PUBLIC	BIG_CONTENTS,COMP_PTR,COMP_ARG1,COMP_ARG2
;	PUBLIC	COMP_ARG3,COMP_ARG4,COMP_ARG5,COMP_ARG6
;	PUBLIC	WRTMES_PTR,WRT_ARG1,WRT_ARG2
;	PUBLIC	IOTYP,MESTYP
;	PUBLIC	ONE_CHAR_BUF,ONE_CHAR_BUF_PTR
;	PUBLIC	OPBUF,UNASSEM_LN_PTR

;	PUBLIC	xm_han_ret_ptr
;	PUBLIC	xm_mapped_ptr
;	PUBLIC	xm_err80_ptr
;	PUBLIC	xm_err83_ptr
;	PUBLIC	xm_err84_ptr
;	PUBLIC	xm_err85_ptr
;	PUBLIC	xm_err86_ptr
;	PUBLIC	xm_err87_ptr
;	PUBLIC	xm_err88_ptr
;	PUBLIC	xm_err89_ptr
;	PUBLIC	xm_err8a_ptr
;	PUBLIC	xm_err8b_ptr
;	PUBLIC	xm_err8d_ptr
;	PUBLIC	xm_err8e_ptr
;	PUBLIC	xm_err_gen_ptr
;	PUBLIC	xm_parse_err_ptr
;	PUBLIC	xm_status_ptr
;	PUBLIC	xm_page_seg_ptr
;	PUBLIC	xm_deall_ptr
;	PUBLIC	xm_errff_ptr
;	PUBLIC	xm_unall_ptr
;	PUBLIC	xm_han_alloc_ptr

;	EXTRN	XM_HANDLE_RET:word
;	EXTRN	XM_LOG:byte
;	EXTRN	XM_PHY:byte
;	EXTRN	XM_PAGE_CNT:word
;	EXTRN	XM_FRAME:word
;	EXTRN	XM_DEALL_HAN:word
;	EXTRN	XM_ALLOC_PG:word
;	EXTRN	XM_TOTAL_PG:word
;	EXTRN	XM_HAN_ALLOC:word
;	EXTRN	XM_HAN_TOTAL:word

;=========================================================================
;		    begin parameter sublists
;=========================================================================

;======================= unassemble parameter sublists ===================

label db_unassem_sb1 dword  ;an000;unassemble parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw arg_buf;an000;point to argument buffer
	dw DG_
	db	01			;an000;parameter one
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum width
	db	pad_blank		;an000;blank pad

label db_unassem_sb2 dword  ;an000;unassemble parameter 2
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw opbuf;an000;point to argument buffer
	dw DG_
	db	02			;an000;parameter two
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum width
	db	pad_blank		;an000;blank pad


;================== hex argument parameter sublists ======================

label db_hexarg_sb1 dword  ;an000;hex argument parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw hex_arg1;an000;point to argument buffer
	dw DG_
	db	01			;an000;parameter one
	db	Right_Align+Bin_Hex_Word
					;an000;right align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

label db_hexarg_sb2 dword  ;an000;hex argument parameter 2
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw hex_arg2;an000;point to argument buffer
	dw DG_
	db	02			;an000;parameter two
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

label db_hexarg_sb3 dword  ;an000;hex argument parameter 3
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw arg_buf;an000;point to argument buffer
	dw DG_
	db	03			;an000;parameter one
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum width
	db	pad_blank		;an000;blank pad


;================== hex add parameter sublists ===========================

label db_hexadd_sb1 dword  ;an000;hex add parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw add_arg;an000;point to add_arg
	dw DG_
	db	01			;an000;parameter one
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

label db_hexadd_sb2 dword  ;an000;hex argument parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw sub_arg;an000;point to sub_arg
	dw DG_
	db	02			;an000;parameter two
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;================== end hex add parameter sublists =======================

;================== single register parameter sublists ===================
;string: "%1 %2",13,10,":",0

label db_singrg_sb1 dword  ;an000;single register parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw arg_buf;an000;point to argument buffer
	dw DG_
	db	01			;an000;parameter one
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

label db_singrg_sb2 dword  ;an000;single register parameter 2
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw single_reg_arg;an000;point single_reg_arg
	dw DG_
	db	02			;an000;parameter two
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;================== register parameter sublists ==========================
;string: "%1=%2  ",0

label db_regist_sb1 dword  ;an000;register parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw reg_name;an000;point to reg_name
	dw DG_
	db	01			;an000;parameter one
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	02			;an000;unlimited width
	db	02			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

label db_regist_sb2 dword  ;an000;register parameter 2
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw reg_contents;an000;point to reg_contents
	dw DG_
	db	02			;an000;parameter two
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;================== error message parameter sublists =====================
;string: "%1 Error",0

label db_error_sb1 dword  ;an000;error message parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw err_type;an000;point to argument buffer
	dw DG_
	db	01			;an000;parameter one
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

;================== writing message parameter sublists ===================
;string: "Writing %1%2 bytes",0

label db_wrtmes_sb1 dword  ;an000;wrtmes parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw wrt_arg1;an000;point to argument buffer
	dw DG_
	db	01			;an000;parameter one
	db	Right_Align+Bin_Hex_Word
					;an000;right align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

label db_wrtmes_sb2 dword  ;an000;wrtmes parameter 2
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw wrt_arg2;an000;point to argument buffer
	dw DG_
	db	02			;an000;parameter two
	db	Left_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;================== loc address parameter sublists =======================
;string: "%1:%2=",0

label db_locadd_sb1 dword  ;an000;loc address parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw arg_buf;an000;point to argument buffer
	dw DG_
	db	01			;an000;parameter one
	db	Right_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIZZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

label db_locadd_sb2 dword  ;an000;loc address parameter 2
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw loc_add;an000;point to loc_add
	dw DG_
	db	02			;an000;parameter two
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;================== little contents parameter sublists ===================
;string "%1",0

label db_little_sb1 dword  ;an000;one byte output parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw little_contents;an000;point to little_contents
	dw DG_
	db	01			;an000;parameter one
	db	Right_Align+Bin_Hex_Byte
					;an000;left align/byte/hexadecimal
	db	02			;an000;maximum of 2 bytes
	db	02			;an000;minimum of 2 bytes
	db	pad_zero		;an000;blank pad

;================== big argument parameter sublists ======================
;string: "%1",0

label db_big_sb1 dword   ;an000;word argument parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw big_contents;an000;point to big_contents
	dw DG_
	db	01			;an000;parameter one
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;======================= comp argument parameter sublists ================
;string "%1:%2  %3  %4  %5:%6",0

label db_comp_sb1 dword   ;an000;comp argument parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw comp_arg1;an000;point to comp_arg1
	dw DG_
	db	01			;an000;parameter one
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

label db_comp_sb2 dword   ;an000;comp argument parameter 2
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw comp_arg2;an000;point to comp_arg2
	dw DG_
	db	02			;an000;parameter two
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

label db_comp_sb3 dword   ;an000;comp argument parameter 3
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw comp_arg3;an000;point to comp_arg3
	dw DG_
	db	03			;an000;parameter three
	db	Right_Align+Bin_Hex_Byte
					;an000;left align/byte/hexadecimal
	db	02			;an000;maximum of 2 bytes
	db	02			;an000;minimum of 2 bytes
	db	pad_zero		;an000;blank pad

label db_comp_sb4 dword   ;an000;comp argument parameter 4
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw comp_arg4;an000;point to comp_arg4
	dw DG_
	db	04			;an000;parameter four
	db	Right_Align+Bin_Hex_Byte
					;an000;left align/byte/hexadecimal
	db	02			;an000;maximum of 2 bytes
	db	02			;an000;minimum of 2 bytes
	db	pad_zero		;an000;blank pad

label db_comp_sb5 dword   ;an000;comp argument parameter 5
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw comp_arg5;an000;point to comp_arg5
	dw DG_
	db	05			;an000;parameter five
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

label db_comp_sb6 dword   ;an000;comp argument parameter 6
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw comp_arg6;an000;
	dw DG_
	db	06			;an000;parameter 6
	db	Right_Align+Bin_Hex_Word
					;an000;left align/word/hexadecimal
	db	04			;an000;maximum of 4 bytes
	db	04			;an000;minimum of 4 bytes
	db	pad_zero		;an000;blank pad

;======================= disk error parameter sublists ===================
;string: "%1 error %2 drive %3",0

label db_disk_sb1 dword   ;an000;disk argument parameter 1
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw mestyp;an000;point to mestyp
	dw DG_
	db	01			;an000;parameter one
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

label db_disk_sb2 dword   ;an000;disk argument parameter 2
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw iotyp;an000;point to iotyp
	dw DG_
	db	02			;an000;parameter two
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

label db_disk_sb3 dword   ;an000;disk argument parameter 3
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw drive;an000;point to drive
	dw DG_
	db	03			;an000;parameter three
	db	Left_Align+Char_Field_Char
					;an000;left align/character/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

label arg_buf_sb1 dword   ;an000;argument sublist
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw arg_buf;an000;point to argument buffer
	dw DG_
	db	01			;an000;parameter one
	db	Left_Align+Char_Field_ASCIIZ
					;an000;left align/ASCIIZ/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

label one_char_sb1 dword  ;an000;character buffer sublist
	db	Sublist_Length		;an000;sublist size
	db	Reserved		;an000;reserved
	dw one_char_buf;an000;point to argument buffer
	dw DG_
	db	01			;an000;parameter one
	db	Left_Align+Char_Field_Char
					;an000;left align/character/character
	db	unlim_width		;an000;unlimited width
	db	00			;an000;minimum of 0 bytes
	db	pad_blank		;an000;blank pad

label xm_han_sub dword  ;an000;sublist for handles
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_handle_ret;an000;parameter 1
	dw DG_
	db	01			;an000;parameter 1
	db	Right_Align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	30h			;an000;pad with zeros

label xm_map_sub dword  ;an000;sublist for mappings
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_log;an000;parameter 1
	dw DG_
	db	01			;an000;parameter 1
	db	Right_Align+Bin_Hex_Byte;an000;
	db	02			;an000;maximum width
	db	02			;an000;minimum width
	db	30h			;an000;pad with zeros

	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_phy;an000;parameter 2
	dw DG_
	db	02			;an000;parameter 2
	db	Right_Align+Bin_Hex_Byte;an000;
	db	02			;an000;maximum width
	db	02			;an000;minimum width
	db	30h			;an000;pad with zeros

label xm_sta_sub word  ;an000;sublist for status
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_handle_ret;an000;parameter 1
	dw DG_
	db	01			;an000;parameter 1
	db	Right_Align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	30h			;an000;pad with zeros

	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_page_cnt;an000;parameter 2
	dw DG_
	db	02			;an000;parameter 2
	db	Right_Align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	30h			;an000;pad with zeros

label xm_page_seg_sub word  ;an000;sublist for frame seg status
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_phy;an000;parameter 1
	dw DG_
	db	01			;an000;parameter 1
	db	Right_Align+Bin_Hex_Byte;an000;
	db	02			;an000;maximum width
	db	02			;an000;minimum width
	db	30h			;an000;pad with zeros

	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_frame;an000;parameter 2
	dw DG_
	db	02			;an000;parameter 2
	db	Right_Align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	30h			;an000;pad with zeros

label xm_deall_sub word  ;an000;sublist for handle deallocation
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_deall_han;an000;parameter 1
	dw DG_
	db	01			;an000;parameter 1
	db	Right_Align+Bin_Hex_Byte;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	30h			;an000;pad with zeros

label xm_unall_sub word  ;an000;sublist unallocated page report
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_alloc_pg;an000;parameter 1
	dw DG_
	db	01			;an000;parameter 1
	db	Right_Align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	20h			;an000;pad with blanks

	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_total_pg;an000;parameter 1
	dw DG_
	db	02			;an000;parameter 1
	db	Right_Align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	20h			;an000;pad with zeros


label xm_han_alloc_sub word    ;an000;sublist unallocated page report
	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_han_alloc;an000;parameter 1
	dw DG_
	db	01			;an000;parameter 1
	db	Right_Align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	20h			;an000;pad with blanks

	db	Sublist_Length		;an000;11 bytes
	db	Reserved		;an000;reserved field
	dw xm_han_total;an000;parameter 1
	dw DG_
	db	02			;an000;parameter 1
	db	Right_Align+Bin_Hex_Word;an000;
	db	04			;an000;maximum width
	db	04			;an000;minimum width
	db	20h			;an000;pad with zeros
;=========================================================================
;		    end parameter sublists
;=========================================================================


label unassem_ln_ptr word  ;an000;"%1%2",0
	dw	0032			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_unassem_sb1	;an000;sublist
	dw	02			;an000;2 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label hex_ptr word   ;an000;"%1:%2 %3",0
	dw	0033			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_hexarg_sb1	;an000;sublist
	dw	03			;an000;3 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label add_ptr word   ;an000;"%1  %2",0
	dw	0034			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_hexadd_sb1	;an000;sublist
	dw	02			;an000;2 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer



label single_reg_ptr word  ;an000;"%1 %2",13,10,":",0
	dw	0035			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_singrg_sb1	;an000;sublist
	dw	02			;an000;2 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer



label register_ptr word   ;an000;"%1=%2  ",0 ex: AX=FFFF
	dw	0036			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_regist_sb1	;an000;sublist
	dw	02			;an000;2 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label errmes_ptr word   ;an000;"%1 Error",0
	dw	0037			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_error_sb1 	;an000;sublist
	dw	01			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label wrtmes_ptr word   ;an000;"Writing %1 bytes",0
	dw	0038			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_wrtmes_sb1	;an000;sublist
	dw	01			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label loc_ptr word   ;an000:"%1;%2=",0 ex:CX:0000
	dw	0039			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_locadd_sb1	;an000;sublist
	dw	02			;an000;2 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label little_ptr word   ;an000;"%1",0 ex:FF
	dw	0040			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_little_sb1	;an000;sublist
	dw	01			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label big_ptr word   ;an000;"%1",0
	dw	0041			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_big_sb1		;an000;sublist
	dw	01			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label comp_ptr word   ;an000;"%1:%2  %3  %4  %5:%6",0
	dw	0042			;an000;message number
	db	UTILITY_MSG_CLASS	   ;an000;utility message
	dw	STDOUT			;an000;display handle
	dw	db_comp_sb1		;an000;sublist
	dw	06			;an000;6 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label arg_buf_ptr word  ;an000;"%1"
	dw	0046			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	arg_buf_sb1		;an000;sublist
	dw	01			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer


label one_char_buf_ptr word  ;an000;"%1"
	dw	0047			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	one_char_sb1 	;an000;sublist
	dw	01			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_unall_ptr word  ;an000;unallocated message report
	dw	0050			;an000;"%1 of a total %2 EMS pages
					;      have been allocated",cr,lf
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	xm_unall_sub 	;an000;sublist
	dw	02			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_han_alloc_ptr word   ;an000;unallocated message report
	dw	0051			;an000;"%1 of a total %2 EMS handles
					;      have been allocated",cr,lf
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	xm_han_alloc_sub	;an000;sublist
	dw	02			;an000;2 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_han_ret_ptr word  ;an000;prints handle created
	dw	0055			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	xm_han_sub		;an000;sublist
	dw	01			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_mapped_ptr word  ;an000;prints log/phy pages
	dw	0056			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	xm_map_sub		;an000;sublist
	dw	02			;an000;2 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err80_ptr word  ;an000;ems error message
	dw	0057			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err83_ptr word  ;an000;ems error message
	dw	0058			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err84_ptr word  ;an000;ems error message
	dw	0059			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err85_ptr word  ;an000;ems error message
	dw	0060			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err86_ptr word  ;an000;ems error message
	dw	0061			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err87_ptr word  ;an000;ems error message
	dw	0062			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err88_ptr word  ;an000;ems error message
	dw	0063			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err89_ptr word  ;an000;ems error message
	dw	0064			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err8a_ptr word  ;an000;ems error message
	dw	0065			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err8b_ptr word  ;an000;ems error message
	dw	0066			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err8d_ptr word  ;an000;ems error message
	dw	0067			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err8e_ptr word  ;an000;ems error message
	dw	0068			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_err_gen_ptr word  ;an000;ems error message
	dw	0070			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_parse_err_ptr word  ;an000;input error message
	dw	0071			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;1 sub
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_status_ptr word  ;an000;prints status of EMS
	dw	0072			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	xm_sta_sub		;an000;sublist
	dw	02			;an000;2 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_page_seg_ptr word  ;an000;"Physical page %1 = Frame
					;	segment %2"
	dw	0075			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	xm_page_seg_sub	;an000;sublist
	dw	02			;an000;2 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_deall_ptr word  ;an000;"Handle %1 deallocated"

	dw	0076			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	xm_deall_sub 	;an000;sublist
	dw	01			;an000;1 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

label xm_errff_ptr word      ;an000;"EMS not installed"

	dw	0078			;an000;message number
	db	UTILITY_MSG_CLASS	;an000;utility messages
	dw	STDOUT			;an000;display handle
	dw	00			;an000;sublist
	dw	00			;an000;0 subs
	db	NO_INPUT		;an000;no keyboard input
	dw	00			;an000;no keyboard buffer

arg_buf 	rb      80       ;an000;argument buffer
one_char_buf	rb      1;an000;character buffer

opbuf	rb      51h

hex_arg1 rw      1
hex_arg2 rw      1

add_arg rw      1
sub_arg rw      1

single_reg_arg rw      1

reg_name rw      1
reg_contents rw      1

err_type db	3	dup(0)		;ac000;changed to hold bf,bp,etc.

wrt_arg1 rw      1
wrt_arg2 rw      1

loc_add rw      1

little_contents rw      1
big_contents rw      1

comp_arg1 rw      1
comp_arg2 rw      1
comp_arg3 rw      1
comp_arg4 rw      1
comp_arg5 rw      1
comp_arg6 rw      1

mestyp	rw      1
iotyp	rw      1
drive	rb      1


end if
;	END
