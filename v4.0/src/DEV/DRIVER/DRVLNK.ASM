; DRIVER.SYS, from the one module DRIVER.LNK names.
;
; One segment, CODE, holding the driver, its tables, the parser, the message
; retriever and the initialisation code alike -- so there is one address
; space and the module is read once, not once per segment the way the
; programs with two of them are.
;
; A driver is not a program and has no prefix in front of it: DOS reads the
; device header at the front of the file, keeps the two addresses in it, and
; calls the strategy routine at an interrupt's remove from whatever asked.
; So the image begins at the first byte of the segment, there is no org, and
; nothing is entered at -- the module's END names nobody.  That is what the
; release made of it as well, linking the one object and running EXE2BIN
; over the result.
;
; What the driver needs of the rest of the system it asks the BIOS's own
; block driver for, through INT 2FH multiplex 8: function 1 hands it the BDS
; it has filled in, and from then on DSK$IN passes every request on through
; function 2.  So nothing of the kernel is linked here.

use16


; MASM's listing directives, in the spellings the module and the shared
; headers it reads use between them.
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


	include 'DRIVER.ASM'
