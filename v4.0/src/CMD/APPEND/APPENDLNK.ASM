; APPEND.EXE, from APPEND.ASM -- the one module the makefile links.
;
; Two segments and no group: cseg, which holds the program, all of its data
; and the message tables, and sseg, which holds nothing but the stack.  So
; an offset is counted from the segment it is in, which is what two fasm
; segments give, and the walk below is the kernel's -- read the module once
; per segment.
;
; APPENDM.ASM is not read.  It held the messages before the message
; retriever took them over -- @@11 in the module's own history -- the
; makefile does not name it, and the appendm.inc it reads is not in the
; release.
;
; The release links the one module and stops: this is an .EXE in its own
; right, with no EXE2BIN over it.  APPEND hooks the multiplex interrupt on
; function B7H and keeps the whole of itself up to end_address resident, so
; that a program asking DOS for a file it cannot find is given the
; directories APPEND was told to look in.

format MZ

; MASM's listing directives, in the spellings the module and the shared
; headers use.  APPEND writes its own in lower case and the headers theirs
; in upper.
macro title [x] {
}
macro page [x] {
}
macro PAGE [x] {
}
macro SUBTTL [x] {
}
macro .sall [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}

; The page heading one of the shared headers asks for before anything has
; declared the macro that writes one.  APPEND declares a break of its own
; further down -- a dummy, so that PDB.INC can call one -- which takes this
; one's place from there on, as MASM's second declaration did.
macro BREAK [x] {
}
macro break [x] {
}

; A probe, for finding where the machine goes: one byte out of port 0E9h,
; which QEMU writes to the file -debugcon names.
macro probe$ n
{
	push	ax
	mov	al, n
	out	0E9h, al
	pop	ax
}

S_CSEG = 1
S_SSEG = 2

macro walk
{
	include 'APPEND.ASM'
}

segment cseg_
SEGSEL = S_CSEG
	walk

segment sseg_
SEGSEL = S_SSEG
	walk
; The top of the stack the source declared, which is the end of the
; segment: APPEND lays down 512 words and names the one after them mystack,
; which is where it puts SP itself once it is running.  $ inside the stack
; directive is not where the segment has got to, so the end is named here.
stack_top$:
stack sseg_:stack_top$

entry cseg_:main_begin		; the source ends with END main_begin
