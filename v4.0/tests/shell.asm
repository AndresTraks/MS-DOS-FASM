; A stand-in for COMMAND.COM, to see the system through to the end of its
; initialisation.
;
; SYSINIT finishes by EXECing the command interpreter, and there is none
; here yet: the thirty-odd utilities under src/CMD are not converted.  So
; this takes its place.  It says so through INT 21H function 9, which is the
; whole point -- the message only appears if the kernel is dispatching, the
; console driver in the BIOS is writing and EXEC loaded the program at all --
; and then reads characters with function 1 and writes each back, so that a
; keystroke sent to the machine proves the input side as well.
	use16
	org	100h

	mov	ah,9
	mov	dx,hello
	int	21h

typed:
	mov	ah,1			; read a character, with echo
	int	21h
	cmp	al,1Bh			; ESC says stop
	jz	bye
	jmp	typed

bye:
	mov	ah,9
	mov	dx,goodbye
	int	21h
	mov	ax,4C00h		; the interpreter should never exit,
	int	21h			;   but say so properly if it does

hello	db	13,10,"MS-DOS 4.00 built by fasm is running.",13,10
	db	"Type anything; ESC to finish.",13,10,"$"
goodbye db	13,10,"ESC seen, so this shell is done.",13,10,"$"
