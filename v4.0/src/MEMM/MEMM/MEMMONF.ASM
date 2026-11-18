

	page	58,132
;******************************************************************************
	title	MEMMONF - (C) Copyright MICROSOFT Corp. 1986
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   MEMMONF - parse for on/off/auto and perform the function
;
;   Version:  0.02
;
;   Date:     June 4, 1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   06/04/86  Original
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;
;******************************************************************************
;
;   Functional Description:
;	MEMMONF is used by MEMM.EXE UTILITY code and MEMM.COM to parse
;   the command line for ON, OFF, or AUTO and perform the function
;   via a call to ELIM_Entry.  It also displays the appropriate message
;   depending on the results of the parsing and call to ELIM_Entry.
;
;******************************************************************************
.lfcond 				; list false conditionals
;.386p
	page
;******************************************************************************
;			P U B L I C   D E C L A R A T I O N S
;******************************************************************************
;
;	public	onf_func
;	public	get_token
;
;******************************************************************************
;			E X T E R N A L   R E F E R E N C E S
;******************************************************************************



;_TEXT	segment byte use16 public 'CODE'
;	extrn	Inst_chk:near
;	extrn	ELIM_link:near
;_TEXT	ends
;
	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;
MSDOS		equ	21h			; MS-DOS function call

	include 'ASCII_SM.EQU'

;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************
;
;_TEXT	segment byte use16 public 'CODE'
;	assume	cs:_TEXT, ds:_TEXT, es:_TEXT, ss:_TEXT
;
;******************************************************************************
;			L O C A L   D A T A   A R E A
;******************************************************************************
;
	include 'MEMM_MSG.INC'
;
label msg_tbl word   ; table of final messages to display
		dw	vmode        ; on
		dw	rmode        ; off
		dw	amode        ; auto
		dw	0		; no parameter will use above msgs
		dw	parmerr        ; invalid parameter
		dw	verr_msg        ; error entering vmode
		dw	rerr        ; error entering rmode
		dw	aerr        ; error entering amode
;
;	the valid arguments
;
on_arg		db	"on"
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
on_len		=	($ - on_arg)

off_arg 	db	"off"
off_len 	=	($ - off_arg)

auto_arg	db	"auto"
auto_len	=	($ - auto_arg)

null_arg	db	" "
null_len	equ	1
max_arg_len	equ	11
arg_str 	db	max_arg_len	dup(0)		; storage for get_token
;
label arg_tbl word   ; table of valid arguments
		dw	on_arg
		dw	off_arg
		dw	auto_arg
;
no_arg		=	($ - arg_tbl)
		dw	null_arg         ; should be last entry
max_args	=	($ - arg_tbl)
;
label arg_len word   ; table of argument lengths
		dw	on_len
		dw	off_len
		dw	auto_len
;
		dw	null_len

page
;******************************************************************************
;	onf_func - Check command line for ON OFF or AUTO and perform function
;
;	ENTRY: es:di points to command line terminated by CR or LF
;
;	EXIT: The appropriate message is displayed
;
;	USED: none
;
;******************************************************************************
onf_func:

	push	ax
	push	dx
	push	di

	cld
;
; check for driver installed
;
	call	Inst_chk		; ax = 0/1 => isn't/is installed
	or	ax,ax			; q: is it installed?
	jnz	drvr_installed
	mov	dx,not_there        ; Not installed message
	jmp	term			; display message and quit
;
drvr_installed:
;
	call	parse_onf		; look for ON/OFF
	jc	msg_disp		; invalid parameter
	cmp	ax,no_arg/2		; q: no argument?
	je	get_status		; y: get status
	push	ax			; save on/off indicator
	mov	ah,1			; ah=1 for set status routine
	call	ELIM_link		; go turn it on or off
	pop	ax			; restore on/off indicator
	jnc	get_status		; no error in status routine
	add	ax,max_args/2+1 	; indicate error
	jmp	msg_disp
;
get_status:
	xor	ah,ah			; get status
	call	ELIM_link		; status in ah
	mov	al,ah
	xor	ah,ah			; status in ax
	cmp	ax,2			; q: auto mode?
	jb	msg_disp		; n: display mode
	push	ax			; save it
	mov	dx,amode
	mov	ah,9
	int	MSDOS			; print auto mode
	pop	ax			; restore mode
	sub	ax,2			; get on or off indicator
;
msg_disp:
	shl	ax,1			; make it a word index
	mov	di,ax			; offset into message table
	mov	dx,[di+msg_tbl] ; get appropriate message
term:
	mov	ah,9
	int	MSDOS			; display error message
;
	pop	di
	pop	dx
	pop	ax

	ret
;onf_func	endp

	page
;******************************************************************************
;	get_token - Retrieve a non-white-space string from a source string
;
;	ENTRY: es:di points to command line terminated by CR or LF
;	       ds:si points to storage for token
;	       cx = maximum length to store
;
;	EXIT: cx = length of token (0 => end of source string)
;	      es:di points to first char after new token in source string
;	      string of length cx stored in ds:si (and converted to lower case)
;
;	USED: see above
;
;******************************************************************************
get_token:
	push	si		; save storage area
	push	bx
	push	ax
;
	mov	bx,cx		; number to store
	xor	cx,cx		; no chars found so far
;
; go to first non-blank character
;
gloop1:
	mov	al,[es:di]	; get a character
	inc	di		; point to next
	cmp	al,' '		; Q: space ?
	je	gloop1		; y: skip it
	cmp	al,TAB		; Q: TAB ?
	je	gloop1		; y: skip it
	dec	di		; N: start parsing and reset di
gloop2:
	mov	al,[es:di]	; get next char
	cmp	al,CR		; q: carriage return?
	je	token_xit	; y: quit
	cmp	al,LF		; q: line feed?
	je	token_xit	; y: quit
	cmp	al,' '		; Q: space ?
	je	token_xit	; y: quit
	cmp	al,TAB		; Q: TAB ?
	je	token_xit	; y: quit
	inc	di		; n: point to next
	inc	cx		; increment number of chars found
	cmp	cx,bx		; q: have we stored our limit yet?
	ja	gloop2		; y: don't store any more
	or	al,20h		; make it lower case
	mov	[ds:si],al	; store it
	inc	si		; and point to next
	jmp	short gloop2	; continue
token_xit:
;
	pop	ax
	pop	bx
	pop	si
	ret
;get_token	endp

	page
;******************************************************************************
;	parse_onf - Parse command line for ON or OFF
;
;	ENTRY: es:di points to command line terminated by CR or LF
;
;	EXIT: ax = 0 => ON
;	      ax = 1 => OFF
;	      ax = 2 => AUTO
;	      ax = 3 => no argument encountered
;	      ax = 4 => Error in command line
;	      CARRY = cleared if no errors
;		      set if error (ax will also = 4)
;	      es:di points to end of parsed string
;
;	USED: see above
;
;******************************************************************************
parse_onf:
;
	push	si
	push	ds
	push	bx
	push	es
;
	mov	bx,no_arg	; initialize to no parameters encountered
	cld			; go foward
;
;	es:di = 1st char
;
	mov	si,arg_str        ; ds:si = storage for argument
	push	cs
	pop	ds		; arg storage in _CODE
	mov	cx,max_arg_len	; maximum argument length
	call	get_token	; get an argument
	or	cx,cx		; q: any parms?
	jz	parse_xit	; n: quit
	push	di		; y: save di for later
	push	ds		; es:di = parameter table
	pop	es

	xor	bx,bx		; index into parameter table
ploop2:
	cmp	cx,[bx+arg_len] ; q: lengths equal?
	jne	not_found	; n: keep looking
	mov	di,[bx+arg_tbl] ; get destination address
	push	si		; save source string addr
	repe	cmpsb		; q: is this a valid argument?
	pop	si		;     restore source string address (command line)
	je	found		; y: matched one
not_found:
	inc	bx
	inc	bx		; update table pointer
	cmp	bx,max_args	; q: have we done them all yet?
	jne	ploop2		; n: keep looking
parse_inv:
	mov	bx,max_args	; y: invalid
	pop	di		; restore di
	jmp	short parse_xit ; leave
found:
	pop	di		; restore original string addr
	pop	es
	mov	cx,1		; just need to check for one non blank
	call	get_token	; get another token
	or	cx,cx		; q: was there another one?
	jz	parse_xit2	; n: good
	mov	bx,max_args	; y: invalid
	jmp	short parse_xit2
parse_xit:
	pop	es
parse_xit2:
	shr	bx,1		; get result of parse
	mov	ax,bx		; put in ax
	mov	bx,max_args/2-1
	cmp	bx,ax		; set/clear carry on invalid/valid return
;
	pop	bx
	pop	ds
	pop	si
;
	ret
;parse_onf	endp

;_TEXT	ends

;	end
