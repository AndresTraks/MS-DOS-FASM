; VDISK.SYS, from the one module VDISK.LNK names.
;
; One segment to lay down, CSEG, which holds the driver, its tables, the
; parser, the message retriever and the initialisation alike -- so the
; module is read once, not once per segment the way the programs with two
; of them are.  INT_VEC is the other segment it declares, AT 0, and it
; names the two words of the INT 15H vector rather than laying anything
; down: the driver hooks that interrupt so that nothing else hands out the
; extended memory it has taken for itself.
;
; A driver is not a program and has no prefix in front of it: DOS reads the
; device header at the front of the file and the image begins at its first
; byte.  So there is no org and nothing is entered at; that is what the
; release made of it as well, linking the one object and running EXE2BIN
; over the result.
;
; VDISK.ASM in the same directory is this driver as it was before the
; message retriever took its text over, and VDISKMSG.ASM is the text it
; took: VDISK.LNK links neither, and nothing here reads them.

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


	include 'VDISKSYS.ASM'
