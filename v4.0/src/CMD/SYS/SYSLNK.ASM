; SYS.COM, from the three modules in the order SYS.LNK names them.
;
; Two segments, CODE and DATA, and no group -- so there are two address
; spaces over one stretch of output, which is what COMMAND.COM's two groups
; are.  The walk below is the kernel's: read the modules once per segment.
;
; CODE comes first and begins at ORG 80H, the command line DOS leaves in the
; PSP; the file itself begins at 100H, where DOS enters a .COM, which is what
; LINK and EXE2BIN made of it -- the release links the three and runs EXE2BIN
; over the result.
;
; DATA is not reached through a fixed-up segment, which is why a .COM can be
; made of this at all.  BEGIN works the segment out for itself:
;
;	mov	ax,OFFSET Data_Space
;	add	ax,15			; round up to the next paragraph
;	mov	cl,4
;	shr	ax,cl
;	mov	cx,ds			; the PSP, where a .COM is loaded
;	add	ax,cx
;	mov	ds,ax
;
; so DATA starts on the first paragraph at or after Data_Space, which is the
; label SYSSR.ASM ends the code with.  The padding below puts it there and
; the ORG 0 counts DATA's own offsets from it.

use16

; MASM's listing directives, in the spellings the modules use.
macro TITLE [x] {
}
macro page [x] {
}
macro PAGE [x] {
}
macro SUBTTL [x] {
}
macro subttl [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}

; MASM padded to the next even address, with a NOP in a code segment where
; fasm's align writes a zero.  SYS1 asks for it once, before its stack.
macro even
{
	align 2
}

; A page heading, which writes nothing.
macro BREAK [x] {
}

S_CODE = 1
S_DATA = 2

macro walk
{
	include 'SYS1.ASM'
	include 'SYS2.ASM'
	include 'SYSSR.ASM'
}

; The message retriever keeps its table of addresses in DATA, which the
; program reaches through DS.
M_SEG$ equ ds

; Its structures, laid out before either reading.
;
; SYS1 asks for them from inside its DATA segment and SYSSR from outside
; both, so on the reading that lays the code down SYS1's request is passed
; over -- and the guard that keeps a structure from being laid out twice is
; the preprocessor's, which answers when the line is read and not on whether
; the IF around it holds.  SYS1's request would therefore set the guard and
; lay nothing out, and SYSSR's would find the guard set.  The request is
; made here instead, where no IF stands in the way, and the two inside the
; modules find the work done.
	include 'SYSMSG.INC'
	MSG_UTILNAME <SYS>

	SEGSEL = S_CODE
	walk

	times (16 - $ mod 16) mod 16 db 0
	org	0
	SEGSEL = S_DATA
	walk
