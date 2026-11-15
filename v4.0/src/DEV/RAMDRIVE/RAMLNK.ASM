; RAMDRIVE.SYS, from the two modules RAMDRIVE.LNK names.
;
; One segment, RAMCODE, holding the driver, its tables, the text of its
; messages and the initialisation alike -- so there is one address space
; and the modules are read once, not once per segment the way the programs
; with two of them are.  The other two segments the driver declares lay
; nothing down: BiosSeg AT 40h names the ROM BIOS's data, where it looks
; for the 6300 PLUS reset address, and R_Mode_IDT AT 0 the interrupt
; vectors.
;
; A driver is not a program and has no prefix in front of it: DOS reads the
; device header at the front of the file and the image begins at its first
; byte.  So there is no org and nothing is entered at; that is what the
; release made of it as well, linking the two objects and running EXE2BIN
; over the result.
;
; Every header RAMDRIVE reads is a copy of its own, in this directory --
; DEVSYM, SYSCALL, DIRENT and MI have namesakes in src/INC and all four
; differ from them.  A relative include is read from the including file's
; own directory first, by fasm as by MASM, so these are the ones it gets.

use16


; MASM's listing directives, in the spellings the modules use.
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


	include 'RAMDRIVE.ASM'
	include 'MESSAGES.ASM'
