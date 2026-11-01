; COMP.COM, from the five modules in the order COMP.LNK names them.
;
; One segment, CSEG, holding the program, its data and its stack alike, and
; no group -- so there is one address space and the modules are read once.
; COMP1.ASM is the frame: it names the fields of the program's own PSP with
; orgs that write nothing -- the memory size at 02h, the first FCB at 5Ch and
; the command line at 80h -- and the image is what follows the org 100H after
; them, which is where DOS enters a .COM.  That is what LINK and EXE2BIN made
; of it.
;
; The labels Microsoft's SALUT preprocessor left behind are named $$IF1 and
; the like; the leading dollars go to the end, since $$ is fasm's name for
; where the output starts.  MASM assembled the modules apart, so each could
; have its own $$IF1, and COMP2.ASM and COMPPAR.ASM both have some of the
; same names: COMPPAR's carry the module's mark after the dollars.

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
macro page [x] {
}
macro subttl [x] {
}
macro header [TEXT] {
}

; MASM padded to the next even address, with a NOP in a code segment where
; fasm's align writes a zero.  COMP asks for it before its stack.
macro even
{
	align 2
}
macro EVEN
{
	align 2
}

; A page heading is asked for before the modules that write one declare it,
; so the name means this nothing until their own declaration replaces it.
macro HEADER [TEXT]
{
}

	include 'COMP1.ASM'
	include 'COMPPAR.ASM'
	include 'COMPP.ASM'
	include 'COMPSM.ASM'
	include 'COMP2.ASM'
