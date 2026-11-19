; Ask the system for the same thing twice, once each way, and say whether the
; A20 gate was open when we did.
;
; A program under MS-DOS asks through INT 21H with the function in AH.  A
; program carried over from CP/M asks with a CALL 5 and the function in CL,
; and the kernel still keeps that entry for it in 4.00: MISC.ASM writes a
; long call at offset 5 of the program's base, pointing at (0CH-n):(n*16),
; and DISP.ASM takes the call in at the other end.  That address is a
; megabyte above 0:00C0, where the kernel leaves a long jump to its
; dispatcher, so the wrap at the top of an 8088's twenty address lines is
; what joins the two.
;
; A command tail with a C in it closes the A20 gate first, which is what
; makes this machine the machine that wrap belongs to.  The system must not
; do that for itself here: by 4.00 RAMDRIVE, SMARTDRV and XMA2EMS reach above
; the first megabyte, so the gate is live state that software owns, and the
; BIOS closing it would take the extended memory with it.  tests/call5.sh
; runs this both ways round.

use16
org 100h

	mov	si,81h			; the command tail
scan:
	lodsb
	cmp	al,13
	je	ask
	or	al,20h
	cmp	al,'c'
	jne	scan
	in	al,92h			; port A: bit 1 is the A20 gate
	and	al,0FDh			; closed, so the top of memory wraps
	out	92h,al
	mov	dx,closed
	mov	ah,9
	int	21h
ask:
	mov	dx,m1
	mov	ah,9
	int	21h			; the DOS way
	mov	dx,m2
	mov	cl,9
	call	5			; the CP/M way
	mov	dx,m3
	mov	ah,9
	int	21h			; and back from it
	mov	ax,4C00h
	int	21h

closed:	db	'A20 closed',13,10,'$'
m1:	db	'INT 21H: yes',13,10,'$'
m2:	db	'CALL 5: yes',13,10,'$'
m3:	db	'and back from it',13,10,'$'
