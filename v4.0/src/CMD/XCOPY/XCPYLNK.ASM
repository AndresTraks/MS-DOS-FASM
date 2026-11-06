; XCOPY.EXE, from the three modules in the order XCOPY.LNK names them.
;
; Four segments, two of them in a group: SSEG is the stack, DSEG and
; DSEG_INIT are DGROUP, and CSEG is the code, which is outside it.  So there
; are two address spaces -- the group, which DS and ES point at, and the
; code, which CS points at -- and each is a fasm segment of its own.  The
; walk below is the kernel's: read the modules once per segment, so that
; every module's contribution to a segment is laid down with the rest of it.
;
; The release links the three into XCOPY.EXE and stops there: no CONVERT, so
; this is an .EXE in its own right and the name is the release's.
;
; The order the segments go down in is the stack, then the group, then the
; code, and the code has to come last.  XCPYINIT's INIT_BUFFER sets the
; buffer the whole copy runs through to
;
;	MOV	AX, OFFSET INIT
;	PUSH	CS
;	POP	DX
;	MOV	BUFFER_PTR, DX
;	CALL	SET_BUFFER_PTR		; BUFFER_PTR += (AX >> 4) + 1 + header
;
; -- the paragraph just past the initialisation code, inside CSEG, which is
; finished with by then -- and lets it run up to the top of memory.  Anything
; laid down above CSEG is written over as soon as the first file is read, so
; the group and the stack go below it.  LINK put DSEG_INIT above CSEG and let
; it be written over, the parser's result buffers having been read by then;
; here the group is laid down in one piece, which is the same program with
; one fewer thing to know about it.

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

; The message retriever keeps its table of addresses in DSEG, which the
; program reaches through DS.
M_SEG$ equ ds

S_SSEG	    = 1
S_DSEG	    = 2
S_DSEG_INIT = 3
S_CSEG	    = 4

macro walk
{
	include 'XCOPY.ASM'
	include 'XCPYINIT.ASM'
	include 'XCOPYPAR.ASM'
}

; The stack, which is XCOPY.ASM's 512 bytes and nothing else.
segment SSEG_
	SEGSEL = S_SSEG
	walk
stack_top$ = $

; The group, with its two segments in the order they are declared in.
; DSEG_INIT asks for PARA, as every segment here does.
segment DGROUP_
	SEGSEL = S_DSEG
	walk
	times (16 - $ mod 16) mod 16 db 0
	SEGSEL = S_DSEG_INIT
	walk

segment CSEG_
	SEGSEL = S_CSEG
	walk

; SS and SP as LINK set them from the segment declared with the stack
; combine type: the top of it is the end of those 512 bytes.
stack SSEG_:stack_top$

; INC/DOSMAC.INC declares a macro called entry, and the shared headers are
; read over four readings apiece, so the name is given back to the assembler
; before the entry point can be named.  A purge of a name that holds no
; macro does nothing, so the count here only has to be large enough.
rept 64 { purge entry }

entry CSEG_:MAIN		; the source ends with END MAIN
