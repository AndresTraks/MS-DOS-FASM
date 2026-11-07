; ASSIGN.COM, from the two modules in the order the makefile links them.
;
; One segment, code, holding the program, its tables and its stack alike, and
; no group -- so there is one address space and the modules are read once,
; not once per segment the way the programs with two of them are.
;
; code starts where the load module does, which for a .COM is the program's
; own prefix: ASSGMAIN names that start ASSIGN_BASE, so that it can measure
; what to keep resident from it, and the org 100H after it is where DOS
; enters.  The release links the two and runs EXE2BIN over the result, which
; is the flat image fasm writes here.
;
; ASSIGN keeps the whole of itself: the handler it hooks interrupt 21H with
; maps a drive letter in whatever call is being made and hands the call on,
; and the initialisation that reads the command line is thrown away by
; nothing -- it stays resident with the rest.

use16


; MASM's listing directives, in the spellings the modules use.
macro title [x] {
}
macro TITLE [x] {
}
macro PAGE [x] {
}
macro page [x] {
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

; code begins where the load module does, which is the start of the
; program's own segment, so an offset counted from it -- ASSGMAIN writes
; OFFSET CODE:routine for the entries of its table of calls -- is the
; offset itself.
CODE = 0

; ASSGMAIN counts what its SaveReg has pushed in ?stackdepth and never
; starts the count: MASM read a name it had no value for as zero and the
; assignment gave it one, where fasm wants the name to mean something
; already.  Nothing reads the count here -- the macros that would, the
; procedure and EndProc of INC/DOSMAC.INC, are not among the ones ASSIGN
; reads -- so what it counts from is the zero MASM counted from.
?stackdepth = 0

; A probe, for finding where the machine goes: one byte out of port 0E9h,
; which QEMU writes to the file -debugcon names.
macro probe$ n
{
	push	ax
	mov	al, n
	out	0E9h, al
	pop	ax
}

; ASSGMAIN reads five of the shared headers before it declares the BREAK
; macro that writes a page heading, and the headers ask for headings of
; their own, so the name has to mean something already -- the same nothing
; it means once ASSGMAIN's declaration replaces this.
macro BREAK [x] {
}
macro Break [x] {
}
macro break [x] {
}

; And ASSGPARM asks for a heading of its own before the macro that writes
; one is declared, the declaration going the way every listing directive
; here goes.
macro HEADER [TEXT] {
}

	include 'ASSGMAIN.ASM'
	include 'ASSGPARM.ASM'
