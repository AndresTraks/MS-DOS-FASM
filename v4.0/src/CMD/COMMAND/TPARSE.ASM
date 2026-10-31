 PAGE 80,132
;	SCCSID = @(#)tparse.asm 4.1 87/04/28
;	SCCSID = @(#)tparse.asm 4.1 87/04/28
TITLE	COMMAND interface to SysParse

.xlist
.xcref
	include 'COMSEG.ASM';AN000;
.list
.cref

if SEGSEL = S_TRANSPACE	;AN000;

	CmpxSW	equ	0		;AN000; do not check complex list
	KeySW	equ	0		;AN000; do not support keywords
	Val2SW	equ	0		;AN000; do not Support value definition 2
	IncSW	equ	0		;AN000; do not include psdata.inc
	QusSW	equ	0		;AN025; do not include quoted string
	LFEOLSW equ	0		;AN044; do not use 0ah as line terminator

.xlist
.xcref

include 'PSDATA.INC' ;AN000;

.list
.cref

end if			;AN000;

if SEGSEL = S_TRANCODE	;AN000;

;ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING	 ;AN054;

; ****************************************************************
; *
; * ROUTINE:	 CMD_PARSE
; *
; * FUNCTION:	 Interface for transient COMMAND to invoke
; *		 SYSPARSE.
; *
; * INPUT:	 inputs to SYSPARSE
; *
; * OUTPUT:	 outputs from SYSPARSE
; *
; ****************************************************************

;	public	Cmd_parse		;AN000;

.xlist
.xcref
	include 'PARSE.ASM';AN000;
.list
.cref

Cmd_parse:			;AN000;

	call	SysParse		;AN000;

	ret				;AN000;

;Cmd_parse	endp			;AN000;

;	public	Append_parse		;AN010;

Append_parse:			;AN010;

	call	SysParse		;AN010;

	RETF   ;AN010;

;Append_parse	endp			;AN010;

end if			;AN000;
;	    end 			;AN000;
