; Ask the system for the same thing twice, once each way.
;
; A program under MS-DOS asks through INT 21H with the function in AH.  A
; program carried over from CP/M asks with a CALL 5 and the function in CL,
; and the kernel keeps that door open for it: it writes a long call at offset
; 5 of a program's base pointing at (0CH-n):(n*16), and leaves a long jump to
; its own dispatcher at 0:00C0 -- a megabyte below.  An 8086 has twenty
; address lines and no twenty-first, so the call arrives at 00C0 and the wrap
; is the mechanism.
;
; IBMDOS.COM is a binary here and this is the only way to see that entry
; work.  Nothing else in the release uses it, so the system comes up either
; way; what decides it is the A20 gate, which SeaBIOS leaves open and which
; the QEMU build of the BIOS closes at START$ under QEMUA20.  tests/boot.sh
; runs this on that build and wants all three lines.

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
