; A stand-in interpreter that runs one of the converted utilities, so that it
; can be seen working on the system this builds.
;
; COMMAND.COM is not converted yet, and a filter reads what it works on from
; handle 0, so this does what the interpreter would have done for
; "PROGRAM < FILE": it gives back the memory a .COM program is handed, puts
; the file on handle 0, and EXECs the program.  Which program and which file
; comes from RUN.INC, which the test writes.
	use16
	org	100h

	mov	ah,9
	mov	dx,hello
	int	21h

; EXEC needs memory, and this program was given all of it.
	mov	ax,cs
	mov	es,ax
	mov	bx,100h			; four kilobytes is plenty
	mov	ah,4Ah
	int	21h
	jc	noroom

; The file MORE is to page, on the handle MORE reads from.
	mov	dx,txtfile
	mov	ax,3D00h		; open, for reading
	int	21h
	jc	nofile
	mov	bx,ax
	xor	cx,cx			; handle 0
	mov	ah,46h			; and make it a copy of the file
	int	21h
	mov	ah,3Eh			; the first handle is done with
	int	21h

; This segment is where the command tail and the two file control blocks
; EXEC asks for are, so it goes into the parameter block here.
	mov	ax,cs
	mov	[tailseg],ax
	mov	[fcb1seg],ax
	mov	[fcb2seg],ax
	mov	[savess],ss
	mov	[savesp],sp
	mov	bx,block
	mov	dx,prog
	mov	ax,4B00h		; load and run
	int	21h
	mov	ax,cs			; EXEC leaves the segment registers
	mov	ds,ax			;   and the stack to the caller
	mov	es,ax
	cli
	mov	ss,[savess]
	mov	sp,[savesp]
	sti
	jc	failed

	mov	ah,9
	mov	dx,done
	int	21h
rest:
	mov	ah,1			; read a character, with echo
	int	21h
	cmp	al,1Bh			; ESC says stop
	jnz	rest
	mov	ax,4C00h
	int	21h

noroom:
	mov	dx,nomem
	jmp	short say
nofile:
	mov	dx,noopen
	jmp	short say
failed:
	mov	dx,noexec
say:
	mov	ah,9
	int	21h
	jmp	rest

block	dw	0			; the environment, inherited
	dw	tail
tailseg dw	0
	dw	fcb
fcb1seg dw	0
	dw	fcb
fcb2seg dw	0

tail	db	0,13			; nothing on the command line
fcb	db	0,"           ",0,0,0,0
include 'RUN.INC'		; the program to run and the file to give it
savess	dw	0
savesp	dw	0

hello	db	13,10,"Running the program on the file.",13,10,"$"
done	db	13,10,"The program returned.",13,10,"$"
nomem	db	13,10,"No memory to give back.",13,10,"$"
noopen	db	13,10,"The file would not open.",13,10,"$"
noexec	db	13,10,"The program would not run.",13,10,"$"
