; XMAEM.SYS, from the ten modules XMAEM.ARF names.
;
; One segment, PROG, holding the emulator, its descriptor and interrupt
; tables, its messages and the initialisation alike -- so there is one
; address space and the modules are read once, not once per segment the way
; the programs with two of them are.
;
; Unlike the other drivers this one is an .EXE: the release's makefile runs
; LINK over the ten objects and keeps what LINK wrote, with no EXE2BIN after
; it.  It has to be one, because the initialisation builds the task state
; segment the virtual 8086 task runs under and puts the driver's own segment
; in four of its fields -- MOV WORD PTR [BX].ETSS_GS,SEG PROG and three more
; -- which is a number only the loader knows.  SYSCONF loads a driver with
; EXEC's third subfunction, the one that loads an overlay, and that reads an
; .EXE header and relocates what it finds inside; the device header is at the
; front of the image either way, which is what DOS reads it from.  So the
; CS:IP and SS:SP in the header are never used, the overlay call keeping the
; caller's.
;
; Three of the headers are .MAC files, which is what the release calls a
; header that holds nothing but macros.  INDEINS.MAC is the one to know
; about: MASM 3.0 did not know the 386's instructions, so the release
; hand-assembles the ones it wants out of DBs, and those macros are read
; here as they stand.

format MZ


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


; MASM's ORG moved the location counter, and a counter moved back over what
; had already been laid down meant that what came next was written over it.
; Both of the jump tables here are built that way -- a REPT lays an entry
; down for every op-code or every port, all of them jumping to the routine
; that passes the thing through, and then an ORG and a JMP for each one the
; emulator handles itself, written over the entry it lands on.  fasm writes
; its output as it goes and cannot move back over it, so the jump is
; assembled where it belongs inside a VIRTUAL block and the three bytes of it
; are stored over the entry.  Three, because MASM assembled a JMP to a name
; it had not read yet as a near one and every entry of the table is that
; wide; the entries themselves say NEAR for the same reason.
macro jmpover$ where, target
{
	virtual at where
		JMP	near target
		load jmpover$op byte from where
		load jmpover$rel word from where + 1
	end virtual
	store byte jmpover$op at where
	store word jmpover$rel at where + 1
}


segment PROG_

; The segment's own address, which the four lines above read as a number and
; the loader fills in.
PROG equ PROG_

	include 'INDEINI.ASM'
	include 'INDEEXC.ASM'
	include 'INDEEMU.ASM'
	include 'INDEXMA.ASM'
	include 'INDEDMA.ASM'
	include 'INDEI15.ASM'
	include 'INDEIDT.ASM'
	include 'INDEGDT.ASM'
	include 'INDEMSG.ASM'
	include 'INDEPAT.ASM'

; The release linked no stack segment, so LINK wrote nothing for SS:SP and
; nothing for the room a stack wants; naming the segment itself and nought
; is what that comes to, and fasm will not take a stack of no size at all.
; An overlay keeps the caller's stack and the caller's CS:IP, so neither
; this nor the entry point -- which no line here names, and which fasm
; writes as nought -- is ever read.
stack PROG_:0
