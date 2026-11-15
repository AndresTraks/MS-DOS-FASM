; DISPLAY.SYS, from the three modules DISPLAY.LNK names.
;
; One segment, CODE, holding the driver, its tables, the switch parser and
; the initialisation alike, and no group -- so there is one address space
; and the modules are read once, not once per segment the way the programs
; with two of them are.
;
; A driver is not a program and has no prefix in front of it: DOS reads the
; device header at the front of the file and the image begins at its first
; byte.  So there is no org and nothing is entered at; that is what the
; release made of it as well, linking the three objects and running EXE2BIN
; over the result.
;
; DISPMES.ASM in the same directory is this driver's text before the
; message retriever took it over: DISPLAY.LNK does not link it, and the
; header it reads is not in the release at all.
;
; The EGA and LCD directories beside it hold the code page fonts the driver
; loads, which the release's build makes into EGA.CPI and LCD.CPI with a
; tool of its own.  Neither is part of this.

use16


; CODE begins where the image does, which is the first byte of the driver,
; so an offset counted from it is the offset itself.  INIT writes DW SEG
; CODE twice -- the segment of the end of the resident part, and the one the
; message retriever reads its text through -- and fills both words in with
; CS before anything reads them, which is what the loader would have done
; for a program with a header to relocate from.
CODE = 0


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


	include 'DISPLAY.ASM'
	include 'INIT.ASM'
	include 'PARSER.ASM'
