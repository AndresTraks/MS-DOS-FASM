; Ask the system for the same thing twice, once each way.
;
; A program under MS-DOS asks through INT 21H with the function in AH.  A
; program carried over from CP/M asks with a CALL 5 and the function in CL,
; and the kernel keeps that entry for it: MISC.ASM writes a long call at
; offset 5 of the program's base, pointing at (0CH-n):(n*16), and leaves a
; long jump to its own dispatcher at 0:00C0.  Those two addresses are a
; megabyte apart, and an 8088's twenty address lines are what close the gap.
;
; So this prints one line through each entry and a third to show it came
; back.  tests/call5.sh runs it.  With the A20 gate open -- which is how a
; modern BIOS leaves it, and QEMU's does -- the second line never appears and
; the machine is gone; IO.ASM closes the gate at HWINIT so that it does.

use16
org 100h

	mov	dx,m1
	mov	ah,9
	int	21h			; the DOS way
	mov	dx,m2
	mov	cl,9
	call	5			; the CP/M way
	mov	dx,m3
	mov	ah,9
	int	21h			; and back from it
	int	20h

m1:	db	'INT 21H: yes',13,10,'$'
m2:	db	'CALL 5: yes',13,10,'$'
m3:	db	'and back from it',13,10,'$'
