; KEYBOARD.SYS, from the twenty modules KEYBOARD.LNK names.
;
; This is neither a driver nor a program: it is the file of keyboard layouts
; KEYB reads, and the .SYS on the end of it is the release's own naming.
; There is not an instruction in the whole of it -- every module lays tables
; down and nothing else -- so nothing is entered at and there is no prefix
; and no header in front of the first byte.  The release links the twenty
; objects and runs EXE2BIN over the result, which is what this writes.
;
; One segment to lay down, CODE, which every module declares and every
; module's ASSUME puts CS and DS on.  KDFNOW is the file header and the two
; tables of pointers -- one by language code, one by keyboard ID -- and it
; takes the state logic and the two code page tables of each language with an
; EXTRN; the eighteen modules after it are a language apiece and make those
; three names PUBLIC.  KDFEOF is the copyright and the 1AH that ends the
; file.
;
; Five more .ASM files in the directory are earlier copies the link file does
; not name: KDF.ASM, which the comments in the others still point at for the
; linkage instructions, and KDFFR, KDFIT and KDFUK, each of which was split
; in two when a second keyboard ID wanted a layout of its own -- and KDFSU,
; Finland, which KDFSV serves instead.

use16


; MASM's listing directives, in the spellings the modules use.
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


	include 'KDFNOW.ASM'
	include 'KDFSP.ASM'
	include 'KDFPO.ASM'
	include 'KDFFR120.ASM'
	include 'KDFFR189.ASM'
	include 'KDFDK.ASM'
	include 'KDFSG.ASM'
	include 'KDFGE.ASM'
	include 'KDFIT141.ASM'
	include 'KDFIT142.ASM'
	include 'KDFUK166.ASM'
	include 'KDFUK168.ASM'
	include 'KDFSF.ASM'
	include 'KDFBE.ASM'
	include 'KDFNL.ASM'
	include 'KDFNO.ASM'
	include 'KDFCF.ASM'
	include 'KDFSV.ASM'
	include 'KDFLA.ASM'
	include 'KDFEOF.ASM'
