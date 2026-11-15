; SMARTDRV.SYS, from the one module SMARTDRV.LNK names.
;
; One segment, INT13CODE, holding the cache's own INT 13H handler, its
; tables, the text of its messages and the initialisation alike.  The other
; two segments it declares lay nothing down: BiosSeg AT 40h names the ROM
; BIOS's data, where it looks for the 6300 PLUS reset address, and
; R_Mode_IDT AT 0 the interrupt vectors.
;
; A driver is not a program and has no prefix in front of it: DOS reads the
; device header at the front of the file and the image begins at its first
; byte.  So there is no org and nothing is entered at; that is what the
; release made of it too, linking the one object and running EXE2BIN over
; the result.
;
; Every header it reads is a copy of its own, in this directory, written
; with an .ASM name though it is a header: a relative include is read from
; the including file's own directory first, by fasm as by MASM.
;
; FLUSH13.C, FL13.ASM and FLMES.ASM beside it build FLUSH13.EXE, which
; empties the cache from the command line.  None of them is part of this.

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


	include 'SMARTDRV.ASM'
