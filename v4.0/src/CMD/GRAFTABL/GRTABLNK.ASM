; GRAFTABL.COM, from the ten modules in the order GRAFTABL.LNK names them.
;
; One segment, CSEG, holding the program, its tables and its stack alike, and
; no group -- so there is one address space and the modules are read once,
; not once per segment the way the programs with two of them are.
;
; CSEG starts where the load module does, which for a .COM is the program's
; own prefix: GRTABHAN's org 60H names MOV_DEST in it, where the resident
; handler and its 1K table are moved to and left, and the org 100H after
; that is where DOS enters.  Neither writes anything, so the image is what
; follows the second of them.  That is what LINK and EXE2BIN made of it.
;
; DUMMY_SEG is a segment at 0 holding one FAR label and no bytes: it is there
; to make MASM write a direct far jump, whose address the loader patches with
; the previous owner of the interrupt vector.

use16


; MASM's listing directives, in the spellings the modules use.
macro title [x] {
}
macro TITLE [x] {
}
macro PAGE [x] {
}
macro SUBTTL [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}
macro .XCREF [x] {
}
macro .CREF [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}

; CSEG begins where the load module does, which is the start of the
; program's own segment, so an offset counted from it -- GRTABHAN measures
; its resident part with ($-CSEG) -- is the offset itself.
CSEG = 0

; A probe, for finding where the machine goes: one byte out of port 0E9h,
; which QEMU writes to the file -debugcon names.
macro probe$ n
{
	push	ax
	mov	al, n
	out	0E9h, al
	pop	ax
}

; GRTABHAN asks for a page heading at line 106 and GRTABMS.INC declares the
; HEADER macro that writes one, so the name has to mean something already --
; the same nothing it means once that declaration replaces this.
macro HEADER [TEXT]
{
}

; The labels Microsoft's SALUT preprocessor left behind are named $$IF9 and
; the like, and the leading dollars go to the end -- $$ is fasm's name for
; where the output starts.  MASM assembled the modules apart, so each could
; have its own $$IF9; GRTABHAN's and GRTABPAR's carry the module's mark.
	include 'GRTABHAN.ASM'
	include 'GRTABUS.ASM'
	include 'GRTABML.ASM'
	include 'GRTABPO.ASM'
	include 'GRTABCF.ASM'
	include 'GRTABNO.ASM'
	include 'GRTABSM.ASM'
	include 'GRTABPAR.ASM'
	include 'GRTABP.ASM'
	include 'GRTAB.ASM'



