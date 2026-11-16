; XMA2EMS.SYS, from the one module the release's makefile assembles.
;
; One segment to lay down, CSEG, which holds the driver, its tables, the
; parser, the initialisation and the diagnostics alike -- so the module is
; read once, not once per segment the way the programs with two of them are.
; The ten headers it reads are read from inside it, as the release read them.
;
; Three more segments it declares AT 0 and lays nothing down in: INT_VEC,
; INT_VEC15 and INT_VEC13 name the vectors for interrupts 67H, 15H and 13H
; rather than reserving anything, the driver hooking all three.
;
; A driver is not a program and has no prefix in front of it: DOS reads the
; device header at the front of the file and the image begins at its first
; byte.  So there is no org and nothing is entered at; that is what the
; release made of it as well, linking the one object and running EXE2BIN
; over the result.
;
; DIAGS.ASM in the same directory is the diagnostics as they were before the
; message retriever took their text over, and EMS_US.MSG is the text it
; took: the makefile reads neither, and nothing here does.

use16


; MASM's listing directives, in the spellings the module and the shared
; headers it reads use between them.
macro PAGE [x] {
}
macro TITLE [x] {
}
macro SUBTTL [x] {
}
macro page [x] {
}
macro title [x] {
}
macro subttl [x] {
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


	include 'XMA2EMS.ASM'
