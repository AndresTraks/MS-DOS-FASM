 PAGE 80,132
;	SCCSID = @(#)tcmd2a.asm 4.1 85/06/25
;	SCCSID = @(#)tcmd2a.asm 4.1 85/06/25
TITLE	PART5 COMMAND Transient routines.

	include 'COMSW.ASM'

.xlist
.xcref
	include 'DOSSYM.INC'
	include 'COMEQU.ASM'
	include 'COMSEG.ASM'
	include 'IOCTL.INC'
.list
.cref


if SEGSEL = S_CODERES	;AC000;
end if

if SEGSEL = S_DATARES	;AC000;
end if

if SEGSEL = S_TRANDATA	;AC000;
;	EXTRN	arg_buf_ptr:word
;	EXTRN	BadCurDrv:byte		;AC000;
;	EXTRN	clsstring:byte
;	EXTRN	dback_ptr:word
;	EXTRN	display_ioctl:word	;AN000;
;	EXTRN	display_width:word	;AN000;
;	EXTRN	Extend_buf_ptr:word	;AN049;
;	EXTRN	linperpag:word		;AN000;
;	EXTRN	msg_disp_class:byte	;AN049;
;	EXTRN	nulpath_ptr:word
;	EXTRN	prompt_table:word
;	EXTRN	string_buf_ptr:word	;AC000;
;	EXTRN	vermes_ptr:word
end if

if SEGSEL = S_TRANSPACE	;AC000;
;	EXTRN	Arg_Buf:byte
;	EXTRN	bwdbuf:byte
;	EXTRN	curdrv:byte
;	EXTRN	dirchar:byte
;	EXTRN	major_ver_num:word
;	EXTRN	minor_ver_num:word
;	EXTRN	srcxname:byte		;AN049;
;	EXTRN	string_ptr_2:word
end if

if SEGSEL = S_TRANCODE

;ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;---------------

if SEGSEL = S_TRANSPACE	;AC000;
;	EXTRN	arg:byte		; the arg structure!
end if
;---------------

;	EXTRN	cerror:near		;AN049;
;	EXTRN	crlf2:near
;	EXTRN	drvbad:near
;	EXTRN	std_printf:near

;	PUBLIC	build_dir_for_chdir
;	PUBLIC	build_dir_for_prompt
;	PUBLIC	build_dir_string
;	PUBLIC	cls
;	PUBLIC	path
;	PUBLIC	print_char
;	PUBLIC	print_drive
;	PUBLIC	print_version
;	PUBLIC	print_b
;	PUBLIC	print_back
;	PUBLIC	print_eq
;	PUBLIC	print_esc
;	PUBLIC	print_g
;	PUBLIC	print_l
;	PUBLIC	print_prompt
;	PUBLIC	version

	BREAK	VERSION
;assume	ds:trangroup,es:trangroup

VERSION:
	call	CRLF2
	call	print_version
	jmp	CRLF2

print_version:
	mov	ah,Get_Version
	int	int_command
	push	ax
	xor	ah,ah
	mov	[major_ver_num],ax
	pop	ax
	xchg	ah,al
	xor	ah,ah
	mov	[minor_ver_num],ax
	mov	dx,VerMes_Ptr
	jmp	STD_PRINTF

print_prompt:
	push	ds
	push	cs
	pop	ds				; MAKE SURE DS IS IN TRANGROUP
	push	es
	invoke	FIND_PROMPT			; LOOK FOR PROMPT STRING
	jc	PP0				; CAN'T FIND ONE
	cmp	byte [es:di],0
	jnz	PP1
PP0:
	call	print_drive			; USE DEFAULT PROMPT
	mov	al,SYM
	call	print_char
	jmp     PP5

PP1:
	mov	al,[es:di]			; GET A CHAR
	inc	di
	or	al,al
	jz	PP5				; NUL TERMINATED
	cmp	al,dollar			; META CHARACTER?
	jz	PP2				; NOPE
PPP1:
	call	print_char
	jmp	PP1

PP2:
	mov	al,[es:di]
	inc	di
	mov	bx,PROMPT_TABLE-3
	or	al,al
	jz	PP5

PP3:
	add	bx,3
	invoke	upconv
	cmp	al,[bx]
	jz	PP4
	cmp	byte [bx],0
	jnz	PP3
	jmp	PP1

PP4:
	push	es
	push	di
	push	cs
	pop	es
	call	[bx+1]
	pop	di
	pop	es
	jmp	PP1

PP5:
	pop	es				; RESTORE SEGMENTS
	pop	ds
	return


print_back:
	mov	dx,Dback_Ptr
	jmp	STD_PRINTF

print_EQ:
	mov	al,'='
	jmp     print_char

print_esc:
	mov	al,1BH
	jmp     print_char

print_G:
	mov	al,rabracket
	jmp     print_char

print_L:
	mov	al,labracket
	jmp     print_char

print_B:
	mov	al,vbar

print_char:
	push	es
	push	ds
	pop	es
	push	di
	push	dx
	mov	dl,al				;AC000; Get char into al
	mov	ah,Std_Con_Output		;AC000; print the char to stdout
	int	int_command			;AC000;
	pop	dx
	pop	di
	pop	es
	ret

print_drive:
	mov	ah,Get_Default_Drive
	int	int_command
	add	al,capital_A
	call	print_char
	ret

;ASSUME	DS:TRANGROUP,ES:TRANGROUP

build_dir_for_prompt:
	xor	dl,dl
	mov	si,BWDBUF
	mov	di,SI
	mov	al,[CURDRV]
	add	al,'A'
	mov	ah,':'
	stosw
	mov	al,[DIRCHAR]
	stosb
	xchg	si,di
	mov	[string_ptr_2],di
	mov	ah,Current_Dir
	int	int_command
	mov	dx,String_Buf_Ptr
	jnc	DoPrint
	mov	dx,BadCurDrv
DoPrint:
	call	STD_PRINTF

	ret

build_dir_for_chdir:
	call	build_dir_string
	mov	dx,BWDBUF
	mov	[string_ptr_2],dx
	mov	dx,String_Buf_Ptr
	call	STD_PRINTF
	ret

build_dir_string:
	mov	dl,[ds:FCB]
	mov	al,DL
	add	al,'@'
	cmp	al,'@'
	jnz	gotdrive_TCMD2A
	add	al,[CURDRV]
	inc	al

gotdrive_TCMD2A:
	push	ax
	mov	si,BWDBUF+3
	mov	ah,Current_Dir
	int	int_command
	jnc	dpbisok
	push	cs
	pop	ds
	jmp	DRVBAD

dpbisok:
	mov	di,BWDBUF
	mov	dx,di
	pop	ax
	mov	ah,':'
	stosw
	mov	al,[DIRCHAR]
	stosb

	ret

	BREAK	PATH
;assume	ds:trangroup,es:trangroup

PATH:
	xor	al,al				;AN049; Set up holding buffer
	mov	di,SRCXNAME                  ;AN049;   for PATH while parsing
	stosb					;AN049; Initialize PATH to null
	dec	di				;AN049; point to the start of buffer
	invoke	PGETARG 			; Pre scan for arguments
	jz	disppath			; Print the current path
	cmp	al,semicolon			;AC049; NUL path argument?
	jnz	pathslp 			;AC049;
	inc	si				;AN049; point past semicolon
	jmp     scan_white    ;AC049; Yes - make sure nothing else on line

pathslp:					; Get the user specified path
	lodsb					; Get a character
	cmp	al,end_of_line_in		;AC049; Is it end of line?
	jz	path_eol			;AC049; yes - end of command

	invoke	TESTKANJ			;See if DBCS
	jz	NotKanj2_TCMD2A			;No - continue
	stosb					;AC049; Yes - store the first byte
	lodsb					;skip second byte of DBCS

path_hold:					;AN049;
	stosb					;AC049; Store a byte in the PATH buffer
	jmp     pathslp     ;continue parsing

NotKanj2_TCMD2A:
	invoke	upconv				;upper case the character
	cmp	al,semicolon			;AC049; ';' not a delimiter on PATH
	jz	path_hold			;AC049; go store it
	invoke	DELIM				;delimiter?
	jnz	path_hold			;AC049; no - go store character

scan_white:					;AN049; make sure were at EOL
	lodsb					;AN049; get a character
	cmp	al,end_of_line_in		;AN049; end of line?
	jz	path_eol			;AN049; yes - go set path
	cmp	al,blank			;AN049; whitespace?
	jz	scan_white			;AN049; yes - continue scanning
	cmp	al,tab_chr			;AN049; whitespace?
	jz	scan_white			;AN049; yes - continue scanning

	mov	dx,Extend_Buf_ptr                  ;AN049; no - set up error message
	mov	word [Extend_Buf_ptr],MoreArgs_Ptr ;AN049; get "Too many parameters" message number
	mov	byte [msg_disp_class],parse_msg_class      ;AN049; set up parse error msg class
	jmp	CERROR				;AN049;

path_eol:					;AN049; Parsing was clean
	xor	al,al				;AN049; null terminate the PATH
	stosb					;AN049;    buffer
	invoke	FIND_PATH			;AN049; Find PATH in environment
	invoke	DELETE_PATH			;AC049; Delete any offending name
	invoke	SCAN_DOUBLE_NULL		;AC049; Scan to end of environment
	invoke	MOVE_NAME			;AC049; move in PATH=
	mov	si,SRCXNAME                  ;AN049; Set up source as PATH buffer

store_path:					;AN049; Store the PATH in the environment
	lodsb					;AN049; Get a character
	cmp	al,end_of_line_out		;AN049; null character?
	jz	got_paths			;AN049; yes - exit
	invoke	STORE_CHAR			;AN049; no - store character
	jmp     store_path    ;AN049; continue

got_paths:					;AN049; we're finished
	xor	ax,ax				;null terminate the PATH in
	stosw					;    the environment
	return

disppath:
	invoke	FIND_PATH			;AN049;
	call	print_path
	call	CRLF2
	return

print_path:
	cmp	byte [es:di],0
	jnz	path1

path0:
	mov	dx,NulPath_Ptr
	push	cs
	pop	es
	push	cs
	pop	ds
	jmp	STD_PRINTF

path1:
	push	es
	pop	ds
	sub	di,5
	mov	si,di
;ASSUME	DS:RESGROUP
	invoke	SCASB2				; LOOK FOR NUL
	cmp	cx,0FFH
	jz	path0
	push	cs
	pop	es
	mov	di,arg_buf
	mov	dx,100h
	sub	dx,cx
	xchg	dx,cx
	rep	movsb
	mov	dx,arg_Buf_Ptr
	push	cs
	pop	ds
	jmp	STD_PRINTF

;ASSUME	DS:TRANGROUP

	BREAK	CLS

; ****************************************************************
; *
; * ROUTINE:	 CLS
; *
; * FUNCTION:	 Clear the screen using INT 10h.  If ANSI.SYS is
; *		 installed, send a control string to clear the
; *		 screen.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

;assume	ds:trangroup,es:trangroup

ANSI_installed		equ    0ffh

CLS:
	mov	ah,mult_ansi			;AN000; see if ANSI.SYS installed
	mov	al,0				;AN000;
	int	2fh				;AN000;
	cmp	al,ANSI_installed		;AN000;
	jz	ansicls 			;AN000; installed - go do ANSI CLS

check_lines:
	mov	ax,(IOCtl SHL 8) + GENERIC_IOCTL_HANDLE ;AN000; get lines per page on display
	mov	bx,stdout			;AN000; lines for stdout
	mov	ch,IOC_SC			;AN000; type is display
	mov	cl,get_generic			;AN000; get information
	mov	dx,display_ioctl                  ;AN000;
	int	int_command			;AN000;
	jc	no_variable			;AN000; function had error, use default
	mov	ax,[linperpag] ;AN000; get number of rows returned
	mov	dh,al				;AN000; set number of rows
	mov	ax,[display_width] ;AN000; get number of columns returned
	mov	dl,al				;AN000; set number of columns
	jmp     regcls     ;AN000; go do cls

no_variable:
	mov	bx,stdout			;AC000; set handle as stdout
	mov	ax,IOCtl SHL 8			;AC000; do ioctl - get device
	int	int_command			;AC000;    info
	test	dl,devid_ISDEV			;AC000; is handle a device
	jz	ansicls 			;AC000; If a file put out ANSI
	test	dl,devid_SPECIAL		;AC000;
	jnz	cls_normal			;AC000; If not special CON, do ANSI

ansicls:
	call	ansi_cls			;AN000; clear the screen
	jmp     cls_ret     ;AN000; exit

;
; Get video mode
;

cls_normal:					;AC000;

	mov	ah,GET_VIDEO_STATE		;AC000; set up to get video state
	int	VIDEO_IO_INT			;AC000; do int 10h - BIOS video IO
	cmp	al,VIDEO_ALPHA			;AC000; see if in text mode
	jbe	DoAlpha
	cmp	al,VIDEO_BW			;AC000; see if black & white card
	jz	DoAlpha
;
; We are in graphics mode.  Bogus IBM ROM does not scroll correctly.  We will
; be just as bogus and set the mode that we just got.  This will blank the
; screen too.
;
	mov	ah,SET_VIDEO_MODE		;AC000; set video mode call
	int	VIDEO_IO_INT			;AC000; do int 10h - BIOS video IO
	jmp     cls_ret     ;AC000; exit

DoAlpha:
;
; Get video mode and number of columns to scroll
;
	mov	ah,GET_VIDEO_STATE		;AC000; set up to get current video state
	int	VIDEO_IO_INT			;AC000; do int 10h - BIOS video IO
	mov	dl,ah
	mov	dh,LINESPERPAGE 		;AC000; have 25 rows on the screen

regcls:
	call	reg_cls 			;AC000; go clear the screen

cls_ret:
	ret					;AC000; exit

; ****************************************************************
; *
; * ROUTINE:	 REG_CLS
; *
; * FUNCTION:	 Clear the screen using INT 10H.
; *
; * INPUT:	 DL = NUMBER OF COLUMNS
; *		 DH = NUMBER OF ROWS
; *
; * OUTPUT:	 none
; *
; ****************************************************************

reg_cls:			;AC000;

;
; Set overscan to black.
;

	dec	dh				;AC000;  decrement rows and columns
	dec	dl				;AC000;     to zero base
	push	dx				;AN000;  save rows,columns
	mov	ah,SET_COLOR_PALETTE		;AC000;  set up to set the color to blank
	xor	bx,bx
	int	VIDEO_IO_INT			;AC000; do int 10h - BIOS video IO
	pop	dx				;AN000;  retore rows,colums

	xor	ax,ax				;AC000;  zero out ax
	mov	CX,ax				;AC000;     an cx
;
; Scroll active page
;
	mov	ah,SCROLL_VIDEO_PAGE		;AC000; set up to scroll page up
	mov	bh,VIDEO_ATTRIBUTE		;AC000; attribute for blank line
	xor	bl,bl				;AC000; set BL to 0
	int	VIDEO_IO_INT			;AC000; do int 10h - BIOS video IO
;
; Seek to cursor to 0,0
;
	mov	ah,SET_CURSOR_POSITION		;AC000; set up to set cursor position
	xor	dx,dx				;AC000; row and column 0
	mov	bh,0				;AC000;
	int	VIDEO_IO_INT			;AC000; do into 10h - BIOS video IO

	ret					;AC000;

;reg_cls endp					;AC000;



; ****************************************************************
; *
; * ROUTINE:	 ANSI_CLS
; *
; * FUNCTION:	 Clear the screen using by writing a control code
; *		 to STDOUT.
; *
; * INPUT:	 none
; *
; * OUTPUT:	 none
; *
; ****************************************************************

ansi_cls:			;AC000;

	mov	si,CLSSTRING
	lodsb
	mov	cl,al
	xor	ch,ch
	mov	ah,Raw_Con_IO
clrloop:
	lodsb
	mov	DL,al
	int	int_command
	loop	clrloop
	return

;ansi_cls	endp				;AC000;

end if
;	    end
