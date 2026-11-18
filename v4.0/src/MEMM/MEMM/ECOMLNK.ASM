; EMM386.COM, from the two modules in the order EMMCOM.LNK names them.
;
; One segment, _TEXT, holding the program, its data and its stack alike, and
; no group -- so there is one address space and the modules are read once,
; not once per segment the way the programs with two of them are.  MEMMCOM
; comes first because EMMCOM.LNK names it first, and what that decides is
; where the stack goes: the 256 bytes under Stack_Top are the last thing
; MEMMCOM lays down and MEMMONF's data and code are laid down after them, so
; the stack stands in the middle of the image, as it did in LINK's.
;
; _TEXT starts where the load module does, which for a .COM is the program's
; own prefix: cmd_line names the command tail DOS leaves at 81h of it, and
; the org 100H after that is where DOS enters.  Neither of the two lays
; anything down, so the image is what follows the second of them.
;
; That is what LINK and EXE2BIN would have made of it, and nothing in the
; release did: MAKEFILE beside this declares emm386.com, the rule that links
; the two objects and converts them, and the two rules that would assemble
; the modules -- and every one of the four is commented out.  So this is the
; one program in the release made of assembler alone that Microsoft's own
; build leaves unbuilt.  Nothing else under src/MEMM can be built here:
; EMM386.EXE links ..\emm\emmlib.lib, which is C.
;
; abs0 is a segment at 0 and holds nothing: it names the vector of INT 67H,
; two words at 19Ch that the program reads to find the driver, and reading
; them is all it does with the segment.

use16


; MASM's listing directives, in the spellings the two modules and the header
; they read use between them.  .LFCOND asked for the lines of a conditional
; that was not assembled to be listed anyway.
macro page [x] {
}
macro title [x] {
}
macro subttl [x] {
}
macro .lfcond [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}


	include 'MEMMCOM.ASM'
	include 'MEMMONF.ASM'
