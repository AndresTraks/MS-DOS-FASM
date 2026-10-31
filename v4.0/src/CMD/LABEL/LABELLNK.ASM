; LABEL.COM, from LABEL.ASM and the message module in LABELM.ASM, in the
; order LABEL.LNK names them.
;
; One segment, CSEG, holding the program, its data and its stack alike, and
; no group -- so there is one address space and the modules are read once,
; not once per segment the way the programs with two of them are.  The org
; 5Ch, 80h and 81h at the top of LABEL.ASM name the fields of the program's
; own PSP and write nothing; the image is what follows the org 100h after
; them, which is where DOS enters a .COM.  That is what LINK and EXE2BIN
; made of it.

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
macro .xlist [x] {
}
macro .list [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}

; LABEL.ASM asks for a page heading once at line 127, four lines before it
; declares the HEADER macro that writes one.  So the name has to mean
; something already, and it means the same nothing it will mean after the
; module's own declaration replaces this.
macro HEADER [TEXT]
{
}

; MASM padded to the next even address with a NOP in a code segment, where
; fasm's align writes a zero.  The one place LABEL asks for it is between the
; entry jump and the stack area, so the byte is read by nothing.
macro EVEN
{
	align 2
}

	include 'LABEL.ASM'
	include 'LABELM.ASM'
