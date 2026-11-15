; PRINTER.SYS, from the five modules PRINTER.LNK names.
;
; One segment, CSEG, holding the driver, the fonts, the font writer, the
; parser, the message retriever and the initialisation alike, and no group
; -- so there is one address space and the modules are read once, not once
; per segment the way the programs with two of them are.
;
; A driver is not a program and has no prefix in front of it: DOS reads the
; device header at the front of the file and the image begins at its first
; byte.  So there is no org and nothing is entered at.  The release links
; the five and runs EXE2BIN over the result with ZERO.DAT on its input --
; one byte, a 0 -- which is the answer to the question EXE2BIN asks about
; an image that has fixups in it: what segment to resolve them against.
; Nothing here has a header to be fixed up, so the images agree.
;
; CPSFONT.ASM, CPSPI.ASM, PARSE4E.ASM and PTRMSG.ASM in the same directory
; are earlier copies of three of these modules and the text the message
; retriever took over.  PRINTER.LNK links none of them.
;
; The 4201, 4208 and 5202 directories beside them hold the printer fonts,
; which the release's build makes into .CPI files with a tool of its own.
; None of that is part of this.

use16


; CSEG begins where the image does, which is the first byte of the driver,
; so an offset counted from it is the offset itself.
CSEG = 0


; MASM's listing directives, in the spellings the modules and the shared
; headers they read use between them.
macro PAGE [x] {
}
macro TITLE [x] {
}
macro SUBTTL [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}
macro .sall [x] {
}
macro .xall [x] {
}
macro .SALL [x] {
}
macro .XALL [x] {
}
macro .lall [x] {
}
macro .LALL [x] {
}
macro .xcref [x] {
}
macro .XCREF [x] {
}
macro .cref [x] {
}
macro .CREF [x] {
}


	include 'CPSPM10.ASM'
	include 'CPSFONT3.ASM'
	include 'PRTINT2F.ASM'
	include 'CPSPI07.ASM'
	include 'PARSER.ASM'
