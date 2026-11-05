
	page	60,132;
	title	EDLPARSE for EDLIN


;******************* START OF SPECIFICATIONS *****************************
;
; MODULE NAME: EDLPARSE.SAL
;
; DESCRIPTIVE NAME: PARSES THE EXTERNAL COMMAND LINE FOR EDLIN
;
; FUNCTION: THIS ROUTINE PROVIDES PARSING CAPABILITIES FOR THE
;	    EXTERNAL COMMAND LINE OF EDLIN.  IT PARSES FOR THE PRESENCE
;	    OF A REQUIRED FILESPEC AND AN OPTIONAL SWITCH (/B).
;
; ENTRY POINT: PARSER_COMMAND
;
; INPUT: DOS COMMAND LINE
;
; EXIT NORMAL: AX = 0FFH    - VALID SWITCH AND FILESPEC SPECIFIED
;
; EXIT ERROR:  AX NOT= 0FFH - INVALID SWITCH OR NO FILESPEC SPECIFIED
;
; INTERNAL REFERENCES
;
;	ROUTINE: PARSER_COMMAND - THIS ROUTINE PARSES FOR THE PRESENCE
;				  OF THE /B SWITCH AND A FILESPEC.  THE
;				  FILEPSEC IS REQUIRED, WHILE THE SWITCH
;				  IS OPTIONAL.
;
; EXTERNAL REFERENCES:
;
;     ROUTINE: PARSE.ASM - THIS IS THE PARSER CODE.
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK EDLIN+EDLCMD1+EDLCMD2+EDLMES+EDLPARSE
;
; REVISION HISTORY:
;
;	AN000	VERSION 4.00 - IMPLEMENTS THE SYSTEM PARSER (SYSPARSE)
;
; COPYRIGHT: "THE IBM PERSONAL COMPUTER EDLIN UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988"
;	     "LICENSED MATERIAL - PROPERTY OF Microsoft"
;
;
;******************** END OF SPECIFICATIONS ******************************


;======================= equates for edlparse ============================

parse_ok	equ	0			;an000;good parse return
parse_command	equ	081h			;an000;offset of command line
nul		equ	0			;an000;nul
fs_flag 	equ	05h			;an000;filespec found
sw_flag 	equ	03h			;an000;switch found
; INC/DOSSYM.INC declares TRUE and FALSE, which EDLEQU.ASM reads for the
; other four modules; this module declared them again for itself, in
; lower case, and one assembly can only have the one.  The values agree --
; 0FFFFH is -1 in sixteen bits -- but the comparisons here are against
; bytes, and -1 is the one that goes in a byte, so the shared pair is what
; is kept and these two lines are left as they were written.
;true		equ	0ffffh			;an000;true
;false		equ	00h			;an000;false
too_many	equ	01h			;an000;too many parms

;======================= end equates =====================================


if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_CSTACK
end if

if SEGSEL = S_DATA

;	extrn	path_name:byte
;	extrn	org_ds:word			;an000; dms;

;	public	parse_switch_b			;an000;parse switch result
;	public	filespec			;an000;actual filespec

;======================= input parameters control blocks =================
; these control blocks are used by sysparse and must be pointed to by
; es:di on invocation.

;		public	parms			;an000;share parms
label parms byte    ;an000;parms control block
		dw	parmsx		;an000;point to parms structure
		db	00h			;an000;no additional delims.

label parmsx byte    ;an000;parameter types
		db	1,1			;an000;must have filespec
		dw	fs_pos		;an000;filespec control block
		db	1			;an000;max. number of switches
		dw	sw_b 		;an000;\b switch control block
		db	00h			;an000;no keywords

;======================= filespec positional tables ======================

label fs_pos byte    ;an000;filespec positional
		dw	0200h			;an000;filespec/not optional
		dw	0001h			;an000;cap
		dw	filespec_res 	;an000;filespec result table
		dw	noval		;an000;value list/none
		db	0			;an000;no keyword/switch syns.

label filespec_res byte   ;an000;filespec result table
parse_fs_res	rb      1 ;an000;must be filespec (05)
parse_fs_tag	rb      1 ;an000;item tag
parse_fs_syn	rw      1 ;an000;synonym pointer
parse_fs_off	rw      1 ;an000;offset to filespec
parse_fs_seg	rw      1 ;an000;segment of filespec

;======================= switch tables /b ================================

label sw_b byte    ;an000;/b switch
		dw	0000h			;an000;no match flags
		dw	0000h			;an000;no cap
		dw	switch_res		;an000;result buffer
		dw	noval		;an000;value list/none
		db	1			;an000;1 switch
sw_b_switch	db	"/B",0			;an000;/B means ignore CTL-Z

label switch_res byte   ;an000;switch result table
parse_sw_res	rb      1 ;an000;must be string (03)
parse_sw_tag	rb      1 ;an000;item tag
parse_sw_syn	rw      1 ;an000;synonym pointer
parse_sw_ptr	rd      1 ;an000;pointer to result

label noval byte    ;an000;value table
		db	0			;an000;no values


;======================= end input parameter control blocks ==============

filespec	db	128 dup (0)		;an000;holds filespec
parse_switch_b	rb      1 ;an000;hold boolean result
						;      of /b parse
parse_sw_b	db	"/B"			;an000;comparison switch

end if

;DG_	GROUP	CODE,CONST,cstack,DATA

if SEGSEL = S_CODE;an000;code segment
;	assume cs:DG_,ds:DG_,es:DG_,ss:CStack	;an000;

;	public	parser_command			;an000;share this routine



;======================= begin main routine ==============================
.xlist

include 'PARSE.ASM'  ;an000;parser

.list

parser_command:            ;an000;parse routine

	push	es				;an000;save registers
	push	ds				;an000;
	push	di				;an000;
	push	si				;an000;

	mov	byte [parse_switch_b],FALSE ;an000;init. to false
	xor	cx,cx				;an000;set cx to 0
	xor	dx,dx				;an000;set dx to 0
	mov	di,parms         ;an000;point to parms
	mov	si,parse_command		;an000;point to ds:81h
	mov	ds,[org_ds] ;an000;get ds at entry
;	assume	ds:nothing			;an000;

parse_continue: 				;an000;loop return point

	call	SysParse			;an000;invoke parser
	cmp	ax,parse_ok			;an000;is it a good parse
	jne	parse_end			;an000;continue on good parse
	push	si
	mov	si,dx
	cmp	byte [es:si],fs_flag     ;an000;do we have a filespec
;	if$	e				;an000;yes we do
	JNE IF1$$P
		call build_fs			;an000;save filespec
;	else$					;an000;
	JMP SHORT EN1$$P
IF1$$P:
		cmp  byte [cs:parse_switch_b],TRUE ;an000;see if already set
;		if$  nz 			;an000;if not
		JZ IF3$$P
		     call val_sw		;an000;see which switch
;		else$				;an000;
		JMP SHORT EN3$$P
IF3$$P:
		     mov  ax,too_many		;an000;set error level
		     jmp  parse_end		;an000;exit parser
;		endif$				;an000;
EN3$$P:
;	endif$					;an000;
EN1$$P:

	pop	si
	jmp	parse_continue			;an000;continue parsing

parse_end:					;an000;end parse routine

	pop	si				;an000;restore registers
	pop	di				;an000; for return to caller
	pop	ds				;an000;
;	assume	ds:DG_				;an000;
	pop	es				;an000;

	ret					;an000;return to caller

;parser_command	endp				;an000;end parser_command


;======================= subroutine area =================================


;=========================================================================
; build_fs: This routine saves the filespec for use by the calling program.
;=========================================================================

build_fs:            ;an000;save filespec

	push	ax				;an000;save affected regs.
	push	di				;an000;
	push	si				;an000;
	push	ds				;an000;
	push	es				;an000;

	mov	di,filespec         ;an000;point to filespec buffer
	lds	si,dword [es:parse_fs_off]   ;an000;get offset

build_cont:					;an000;continue routine

	lodsb					;an000;mov ds:si to al
	cmp	al,nul				;an000;is it end of filespec
;	if$	nz				;an000;if not
	JZ IF7$$P
		stosb				;an000;move byte to filespec
		jmp build_cont			;an000;continue buffer fill
;	endif$					;an000;
IF7$$P:
	stosb					;an000;save nul

	pop	es				;an000;restore regs
	pop	ds				;an000;
	pop	si				;an000;
	pop	di				;an000;
	pop	ax				;an000;

	ret					;an000;return to caller

;build_fs	endp				;an000;end proc

;=========================================================================
; val_sw : determines which switch we have.
;=========================================================================

val_sw:             ;an000;switch determination

	cmp	word [es:parse_sw_syn],sw_b_switch	;an000;/B switch?
;	if$	e				;an000;compare good
	JNE IF9$$P
		mov	byte [parse_switch_b],TRUE ;an000;signal /B found
;	else$					;an000;
	JMP SHORT EN9$$P
IF9$$P:
		mov	byte [parse_switch_b],FALSE ;an000;signal /B not found
;	endif$					;an000;
EN9$$P:

	ret					;an000;return to caller

;val_sw		endp				;an000;end proc


end if ;an000;end segment
;	end					;an000;
