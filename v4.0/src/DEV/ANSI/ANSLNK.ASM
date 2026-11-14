; ANSI.SYS, from the four modules ANSI.LNK names.
;
; One segment, CODE, holding the driver, its tables, the escape-sequence
; parser, the switch parser and the initialisation alike, and no group -- so
; there is one address space and the modules are read once, not once per
; segment the way the programs with two of them are.
;
; A driver is not a program and has no prefix in front of it: DOS reads the
; device header at the front of the file -- CON's, this being the console
; driver and the one the kernel's own CON gives way to -- and the image
; begins at its first byte.  So there is no org and nothing is entered at;
; that is what the release made of it as well, linking the four objects and
; running EXE2BIN over the result.

use16


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
macro .sall [x] {
}
macro .xall [x] {
}
macro .lall [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}
macro .SALL [x] {
}
macro .XALL [x] {
}
macro .LALL [x] {
}
macro .XCREF [x] {
}
macro .CREF [x] {
}

; INC/VECTOR.INC and INC/MULT.INC ask for a page heading with Break, and
; ANSI.ASM, which reads them, declares a macro called BREAK for the same
; thing: one name to MASM, three to fasm, which is why the kernel's own
; DOSMAC.INC declares all three.  What the heading comes to is a SUBTTL and
; a PAGE, which are the two directives above, so the other spellings are
; nothing here as well.
macro Break [x] {
}
macro break [x] {
}


	include 'ANSI.ASM'
	include 'IOCTL.ASM'
	include 'ANSIINIT.ASM'
	include 'PARSER.ASM'
