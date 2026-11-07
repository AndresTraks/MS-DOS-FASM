; DEBUG.COM, from the eleven modules in the order DEBUG.LNK names them.
;
; Four segments in one group, DG -- code, const, cstack and data, in the
; order DEBUG.ASM declares them -- so there is one address space and an
; offset is counted from the group, which is CHKDSK's shape.  All four ask
; for BYTE, so LINK laid them down one after another with no padding between
; them, and so does the walk below.  The walk is the kernel's: read the
; modules once per segment, so that every module's contribution to a segment
; is laid down with the rest of it.
;
; A_CREATE_BLOCK is the segment outside the group, and the first thing in the
; image.  DEBUG.ASM says why, and says not to move it: the routine in it
; issues the 1.0 call that makes a program prefix, and that call takes the
; prefix from CS, so the routine has to sit where CS can be made to point at
; one.  It is a far call away, which is the only reason the segment exists.
;
; The release links the eleven into DEBUG.EXE and runs TOOLS/CONVERT over it,
; which wraps the image in a jump, the word "Converted", and a loader that
; applies the fixups itself, and calls what comes out DEBUG.COM.  That is
; what this writes, as CHKDSK.COM and EDLIN.COM are written.

format MZ

; MASM's listing directives, in the spellings the modules use.
macro TITLE [x] {
}
macro title [x] {
}
macro PAGE [x] {
}
macro page [x] {
}
macro SUBTTL [x] {
}
macro subttl [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}
macro .lall [x] {
}
macro .sall [x] {
}
macro .xall [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}
macro .XCREF [x] {
}
macro .CREF [x] {
}
macro .LALL [x] {
}
macro .SALL [x] {
}
macro .XALL [x] {
}

; MASM padded to the next even address, with a NOP in a code segment where
; fasm's align writes a zero.
macro EVEN
{
	align 2
}
macro even
{
	align 2
}

; The numbers and the structures the modules share, read here rather than
; left to them.  A module's own INCLUDE of one stands inside its segment's
; IF, and fasm's preprocessor reads an INCLUDE whichever way the IF went, so
; the guard that keeps a structure from being laid out twice was being set on
; a pass that laid it out not at all.  Read once here, outside the walk, each
; structure is laid out exactly once and every pass can see it.  DOSSYM.INC
; brings VERSION.INC with it, which is where IBMVER and the other switches
; DEBEQU asks about are set.
include 'DOSSYM.INC'		; the structures and the numbers
include 'SYSVER.INC'		; whether DEBUG is to talk straight to the BIOS
include 'DEBEQU.ASM'		; DEBUG's own numbers and structures

; DEBUG.SKL writes the carriage return and the line feed in lower case,
; twenty-two times, and DEBEQU.ASM declares them in upper.  MASM read the two
; spellings as one name; fasm reads them as two, so one is given the other --
; after the header that declares them, because what an EQU stands for is
; taken where it is written.
cr equ CR
lf equ LF

S_A_CREATE_BLOCK = 1
S_CODE		 = 2
S_CONST 	 = 3
S_CSTACK	 = 4
S_DATA		 = 5

macro walk
{
	include 'DEBUG.ASM'
	include 'DEBCOM1.ASM'
	include 'DEBCOM2.ASM'
	include 'DEBCOM3.ASM'
	include 'DEBASM.ASM'
	include 'DEBUASM.ASM'
	include 'DEBERR.ASM'
	include 'DEBCONST.ASM'
	include 'DEBMES.ASM'
	include 'DEBEMS.ASM'
	include 'DEBDATA.ASM'
}

; A segment of the group, with every module's contribution to it in the link
; order.  All four ask for BYTE, so nothing is padded.
macro group$ selector
{
	SEGSEL = selector
	walk
}

; The message retriever keeps its table of addresses in the group, which the
; program reaches through DS.
M_SEG$ equ ds

; The segment that has to be first, and is its own address space.
segment A_CREATE_BLOCK_
	SEGSEL = S_A_CREATE_BLOCK
	walk

segment DG_
	group$ S_CODE
	group$ S_CONST

; The top of the stack is the end of cstack, which is what LINK set SP to:
; the segment is in the group, so SS is the group's and the offset is counted
; from there.
	group$ S_CSTACK
stack_top$:

	group$ S_DATA

stack DG_:stack_top$

; INC/DOSMAC.INC declares a macro called entry, and the shared headers are
; read over five readings apiece, so the name is given back to the assembler
; as many times before the entry point can be named.  A purge of a name that
; holds no macro does nothing, so the count here only has to be large enough.
rept 64 { purge entry }

entry DG_:START 		; the source ends with END START
