; FASTOPEN.EXE, from the five modules in the order FASTOPEN.LNK names them.
;
; Five segments and no group at all, which FASTSEGS.INC declares in the
; order .seq tells LINK to lay them down: STACK, CSEG_MAIN, CSEG_OPEN,
; CSEG_SEEK and CSEG_INIT.  So an offset is counted from the segment it is
; in, which is what five fasm segments give, and each is an address space of
; its own; the walk below is the kernel's -- read the modules once per
; segment, so that every module's contribution to a segment is laid down
; with the rest of it.  Four of the five modules contribute to more than
; one.
;
; The segments are the program's own account of itself, laid out in the
; comment at the head of FASTINIT.ASM: CSEG_MAIN is the entry DOS and the
; multiplex interrupt come in at and the dispatcher that sends a call on,
; with the routine that builds the drive headers and the cache buffers
; after it; CSEG_OPEN is the directory and file cache; CSEG_SEEK is the
; cluster cache; and CSEG_INIT is the initialisation, which reads the
; command line, works out how much room the caches want, writes whichever
; of the two caches was not asked for over its own code, and keeps the rest
; resident.  They are separate segments so that one can be written over
; another, which is the one thing a group would have made impossible.
;
; The release links the five and stops: this is an .EXE in its own right,
; with no EXE2BIN or CONVERT over it.

format MZ

; MASM's listing directives, in the spellings the modules use.
macro TITLE [x] {
}
macro title [x] {
}
macro Title [x] {
}
macro PAGE [x] {
}
macro page [x] {
}
macro Page [x] {
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
macro .SEQ [x] {
}
macro .seq [x] {
}
macro NAME [x] {
}
macro name [x] {
}

; The page heading, which the shared headers ask for in three spellings and
; FASTP, which declares one of its own, asks for before it declares it.
macro BREAK [x] {
}
macro Break [x] {
}
macro break [x] {
}
macro HEADER [TEXT] {
}

; FASTOPEN pads each of its three resident segments out to a paragraph with
; "IF ($-Cseg_Main) MOD 16" and an ORG, and measures how much of itself to
; keep with the same subtraction.  Inside a fasm segment an offset is
; counted from the start already, so the name the count starts at is
; nought; where the name is the segment itself -- the lines that load a
; register with it -- the rules write the fasm segment's own name instead.
Cseg_Main = 0
Cseg_Open = 0
Cseg_Seek = 0
Cseg_Init = 0

S_STACK     = 1
S_CSEG_MAIN = 2
S_CSEG_OPEN = 3
S_CSEG_SEEK = 4
S_CSEG_INIT = 5

macro walk
{
	include 'FASTOPEN.ASM'
	include 'FASTSEEK.ASM'
	include 'FASTINIT.ASM'
	include 'FASTP.ASM'
	include 'FASTSM.ASM'
}

; The stack, which is FASTINIT's 512 bytes of the word "STACK" and nothing
; else.  FASTSEGS.INC declares it first, so LINK laid it down first.
segment STACK_
	SEGSEL = S_STACK
	walk
stack_top$ = $

segment CSEG_MAIN_
	SEGSEL = S_CSEG_MAIN
	walk

segment CSEG_OPEN_
	SEGSEL = S_CSEG_OPEN
	walk

segment CSEG_SEEK_
	SEGSEL = S_CSEG_SEEK
	walk

segment CSEG_INIT_
	SEGSEL = S_CSEG_INIT
	walk

; SS and SP as LINK set them from the segment declared with the stack
; combine type: the top of it is the end of those 512 bytes.
stack STACK_:stack_top$

; INC/DOSMAC.INC declares a macro called entry, and the shared headers are
; read over five readings apiece, so the name is given back to the assembler
; before the entry point can be named.  A purge of a name that holds no
; macro does nothing, so the count here only has to be large enough.
rept 64 { purge entry }

entry CSEG_INIT_:START		; the source ends with END START
