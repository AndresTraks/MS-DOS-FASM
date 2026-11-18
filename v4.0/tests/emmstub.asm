; A stand-in for the EMM386 driver, for tests/emm386.sh.
;
; EMM386.COM reads and sets the mode of the EMM386 driver, and the driver is
; one of the things in this release that cannot be built here: EMM386.EXE
; links ..\emm\emmlib.lib, which is C.  So with nothing installed the one
; message of the eight the utility can reach is "driver not installed", and
; everything past the check -- the far call into the driver, the parse of ON,
; OFF and AUTO, and the seven other messages -- is unreachable.
;
; This is what the utility looks for, and nothing else.  It is not an
; expanded memory manager and answers no EMM function: what it has is the
; two fields EMM386.COM reads of a driver and a mode byte to keep.
;
;   * Inst_chk takes the segment out of the vector of INT 67H, compares the
;     37 bytes at 14h of it with its own signature, and reads the general
;     entry point from the word at 12h.  So this points the vector at the
;     paragraph above its own prefix -- which is where its org puts its
;     first byte -- and lays the entry point and the signature at 12h and
;     14h from there.
;   * ELIM_link far-calls that entry point.  AH=0 is read the mode, which
;     comes back in AH; AH=1 is set it from AL, with carry set if it will
;     not.  0 is active, 1 inactive, and 2 or more auto, which is what the
;     utility's own tests of the answer say.
;
; A command tail with an R in it -- the test loads it as EMMSTUB /R -- makes
; every set refuse, which is the arm of the utility that adds max_args/2+1 to
; the parse's answer and prints one of the three "Unable to" messages.

; The frame is a paragraph above the prefix, so a label counted from the
; prefix, as everything in a .COM is, is that much further on than the
; offset the utility will read it at.
FRAME = 100h

use16
org 100h

	jmp	setup

; The two fields the utility reads, at 12h and 14h of the frame.
	times	FRAME + 12h - $ db 0
elim_point:
	dw	elim_entry - FRAME
signature:
	db	'MICROSOFT EXPANDED MEMORY MANAGER 386'

mode	db	0			; 0 active, 1 inactive, 2 auto
refuse	db	0			; whether a set is to be refused

; The general entry point (not "entry": that is a word of fasm's own),
; far-called through the word at 12h.  CS is the
; frame here and DS is the caller's, so the two bytes this keeps of its own
; it reads through CS -- as a driver's would, those being in its own code.
elim_entry:
	cmp	ah,1			; q: set the mode?
	je	setmode			; y
	mov	ah,[cs:mode - FRAME]	; n: read it
	clc
	retf
setmode:
	cmp	byte [cs:refuse - FRAME],0
	jne	refused
	mov	[cs:mode - FRAME],al
	clc
	retf
refused:
	stc				; the driver would not
	retf

; Where the vector points, for the sake of pointing somewhere: the utility
; reads the segment of it and never calls it, and no EMM function is here.
vector:
	iret

resident_end:

; What is left runs once and is not kept.
setup:
	mov	si,81h			; the command tail
scan:
	lodsb
	cmp	al,13			; q: the end of it?
	je	hook			; y: no R in it
	or	al,20h			; n: a letter, in lower case
	cmp	al,'r'
	jne	scan
	mov	byte [refuse],1		; refuse every set
hook:
	xor	ax,ax
	mov	es,ax
	mov	word [es:67h*4],vector - FRAME
	mov	ax,cs
	add	ax,10h			; the paragraph above the prefix
	mov	[es:67h*4+2],ax
	mov	dx,told
	mov	ah,9
	int	21h
	mov	dx,(resident_end + 15) shr 4
	mov	ax,3100h		; keep what is above, and go
	int	21h

told	db	'EMM386 driver stand-in resident.',13,10,'$'
