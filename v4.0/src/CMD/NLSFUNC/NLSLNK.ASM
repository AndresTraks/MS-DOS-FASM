; NLSFUNC.EXE, from the two modules in the order the makefile links them.
;
; Three segments and no group: NLS_DATA, which holds the buffers the country
; information is read into and the message text; NLS_INIT_CODE, which holds
; the whole of the code; and STACK, which holds nothing but the stack.  So
; an offset is counted from the segment it is in, which is what three fasm
; segments give, and the walk below is the kernel's -- read the modules once
; per segment.  Both modules contribute to the first two, which is how LINK
; put them together.
;
; The release links the two and stops: this is an .EXE in its own right,
; with no EXE2BIN or CONVERT over it.  NLSFUNC hooks the multiplex interrupt
; and keeps the resident part of itself behind, which it moves down over the
; initialisation first.

format MZ

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
macro subttl [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}
macro .XCREF [x] {
}
macro .CREF [x] {
}
macro .SALL [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}
macro .sall [x] {
}

; DOESMAC.INC declares the macro that writes a page heading inside the one
; that calls an installed function -- where MASM declared it the first time
; that one was called -- and asks for a heading of its own before then, so
; the name has to mean something already.  The shared headers ask in three
; spellings.
macro BREAK [x] {
}
macro Break [x] {
}
macro break [x] {
}

; And NLSPARM asks for a heading of its own before the macro that writes one
; is declared, the declaration going the way every listing directive here
; goes.
macro HEADER [TEXT] {
}

; NLSFUNC measures its data segment with ($-NLS_DATA), the offset of the end
; of it counted from the start.  Inside a fasm segment an offset is counted
; from the start already, so the name the count starts at is nought.  Where
; the segment's name is the segment itself -- the two lines that load DS --
; the rules write the fasm segment's own name instead.
NLS_DATA = 0

; DOESMAC.INC's SaveReg counts what it has pushed in ?stackdepth and nothing
; starts the count: MASM read a name it had no value for as zero and the
; assignment gave it one.  Nothing reads the count here either -- the
; procedure and EndProc of INC/DOSMAC.INC are not among the macros NLSFUNC
; reads -- so it starts from the zero MASM started from.
?stackdepth = 0

; The message retriever keeps its table of addresses where the MSG_UTILNAME
; that asks for the services stands, and NLSFUNC's stands in NLS_DATA, which
; it keeps DS on.  Left unsaid, SYSMSG.INC reaches the table through CS --
; and SYSLOADMSG writes it and SYSDISPMSG reads it through the same wrong
; segment, so the messages are found and the code segment is written over
; instead.
M_SEG$ equ ds

; A probe, for finding where the machine goes: one byte out of port 0E9h,
; which QEMU writes to the file -debugcon names.
macro probe$ n
{
	push	ax
	mov	al, n
	out	0E9h, al
	pop	ax
}

S_NLS_DATA      = 1
S_NLS_INIT_CODE = 2
S_STACK         = 3

macro walk
{
	include 'NLSFUNC.ASM'
	include 'NLSPARM.ASM'
}

segment NLS_DATA_
SEGSEL = S_NLS_DATA
	walk

segment NLS_INIT_CODE_
SEGSEL = S_NLS_INIT_CODE
	walk

segment STACK_
SEGSEL = S_STACK
	walk
; The top of the stack the source declared, which is the end of the segment:
; NLSFUNC declares 512 bytes and gives the end of them no name, and $ inside
; the stack directive is not where the segment has got to.
stack_top$:
stack STACK_:stack_top$

entry NLS_INIT_CODE_:MAIN	; the source ends with END MAIN
