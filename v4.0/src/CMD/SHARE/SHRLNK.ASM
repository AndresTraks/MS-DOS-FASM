; SHARE.EXE, from the eight modules in the order SHARE.LNK names them.
;
; Four of them are SHARE's own -- GSHARE and GSHARE2, the two halves of the
; sharer, SHARESR, which holds the parser and the message retriever, and
; SHARELNK, a stub for each of the kernel's names the sharer calls -- and
; four are the kernel's: NIBDOS, CONST2, MSDATA and MSDOSME out of src/INC,
; the same four modules, read the same way, that MSDOSLNK.ASM reads first.
;
; The sharer runs inside the kernel.  It is entered through JShare, the
; jump table MSCONST.ASM lays down in the kernel's CONSTANTS, and so with
; the kernel's own SS: what it reads of the kernel's data it reads through
; that register, at the offset this assembly gives the name.  That is why
; the release linked the kernel's data modules in beside its own, and why
; every routine here says ASSUME SS:DOSGROUP.  The copy of DOSGROUP that
; comes out in SHARE.EXE is there for its offsets and not for its bytes:
; the installation code patches the kernel's table and frees everything but
; the sharer itself, and nothing in the copy is ever read.
;
; Eight segments and three address spaces.  Share is the sharer, outside the
; group and first because GSHARE, which SHARE.LNK links first, declares it
; first.  DOSGROUP is the kernel's six -- START, CONSTANTS, DATA, TABLE,
; CODE, LAST, in the order DOSSEG.ASM gives them -- which the four kernel
; modules fill as they fill the kernel's own, with SHARELNK's stubs in CODE.
; STACK is the third and last, 406 bytes of it, which SHARE needs only until
; it is installed.
;
; So the walk is the kernel's: read all eight modules once per segment, with
; SEGSEL saying which pass it is, so that every module's contribution to a
; segment is laid down with the rest of it.  What a module opened with
; "Share SEGMENT" it now opens with "if SEGSEL = S_SHARE", and on the other
; seven passes that contribution is skipped.
;
; The release links the eight and stops: this is an .EXE in its own right,
; and the only one of the utilities whose segments the loader has to relocate
; -- SHARE tells the kernel where its 2FH handler is with a segment of its
; own, "dw SHARE", and the MZ header carries the fixup for it.

format MZ

; MASM's listing directives, in the spellings the modules use.
macro TITLE [x] {
}
macro Title [x] {
}
macro title [x] {
}
macro NAME [x] {
}
macro name [x] {
}
macro SUBTTL [x] {
}
macro subttl [x] {
}
macro PAGE [x] {
}
macro page [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}
macro .XCREF [x] {
}
macro .CREF [x] {
}
macro .sall [x] {
}
macro .xall [x] {
}
macro .lall [x] {
}
macro .SALL [x] {
}
macro .XALL [x] {
}
macro .LALL [x] {
}

; The page heading.
macro BREAK [x] {
}
macro Break [x] {
}
macro break [x] {
}

S_SHARE     = 1
S_START     = 2
S_CONSTANTS = 3
S_DATA      = 4
S_TABLE     = 5
S_CODE      = 6
S_LAST      = 7
S_STACK     = 8

; The modules, in the order SHARE.LNK gave the linker.
macro walk
{
	include 'GSHARE.ASM'		; the sharer, part one
	include 'GSHARE2.ASM'		; part two, and the installation
	include 'SHARESR.ASM'		; the parser and the messages
	include 'SHARELNK.ASM'		; a stub for each kernel name
	include '../../INC/NIBDOS.ASM'	; the kernel's switches and constants
	include '../../INC/CONST2.ASM'
	include '../../INC/MSDATA.ASM'	; the kernel's data segment
	include '../../INC/MSDOSME.ASM'
}

; The sharer itself: PARA, as GSHARE declares it.
segment Share_
	SEGSEL = S_SHARE
	walk

; The kernel's group, which is one address space: DOSSEG.ASM says how the
; linker aligned each of the six -- START, TABLE and CODE on a byte,
; CONSTANTS and DATA on a word, LAST on a paragraph.
segment DOSGROUP_
	SEGSEL = S_START
	walk
	align	2
	SEGSEL = S_CONSTANTS
	walk
	align	2
	SEGSEL = S_DATA
	walk
; The data segment is as long as MS_DATA.ASM's declarations, which share
; their space with the kernel's initialisation code above and emit nothing
; of their own.  Nothing here ever runs that code or reads that data -- this
; is the copy whose offsets the sharer measures from -- but the segment has
; to be the length the linker gave it, so that what follows it is where the
; kernel has it.
    if ($ - DATA_SEG_START) > MS_DATA_SIZE
	display "the init code is longer than the data it overlays",13,10
	err
    end if
	times	MS_DATA_SIZE - ($ - DATA_SEG_START) db 0
	SEGSEL = S_TABLE
	walk
	SEGSEL = S_CODE
	walk
	align	16
	SEGSEL = S_LAST
	walk

; The stack, which GSHARE2 declares with the STACK combine type: LINK put SS
; on it and SP at the top, which is what the two lines at the end say here.
segment STACK_
	SEGSEL = S_STACK
	walk
stack_top$ = $

; INC/DOSMAC.INC declares a macro called entry, and the shared headers are
; read over eight readings apiece, so the name is given back to the assembler
; before the entry point can be named.  A purge of a name that holds no
; macro does nothing, so the count here only has to be large enough.
rept 128 { purge entry }

stack STACK_:stack_top$
entry Share_:SHAREINIT		; the source ends with END shareinit
