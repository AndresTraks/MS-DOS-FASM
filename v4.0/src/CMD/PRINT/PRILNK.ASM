; PRINT.COM, from the four modules in the order PRINT.LNK names them.
;
; Four segments, three of them in a group: Code, Data and Stack are DG, and
; CodeR is outside it.  So there are two address spaces -- the resident
; part, which CodeR holds, and the transient part, which DG holds -- and
; each is a fasm segment of its own.  The walk below is the kernel's: read
; the modules once per segment, so that every module's contribution to a
; segment is laid down with the rest of it.
;
; CodeR goes first because PRINT_RM, which PRINT.LNK links first, opens it
; first: its 512 bytes of room for the INT 24H messages are the top of the
; resident part, and the resident code, the queue and the buffer follow.
; The transient part is the command line parser and the installation code,
; which runs once and is let go: PRINT keeps everything up to EndRes and
; frees the rest, so the two have to be the way round they are.
;
; The release links the four and runs TOOLS/CONVERT over the result, which
; only renames it -- DOS reads the signature and not the extension -- so
; what comes out here is the MZ image under the release's name.

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

; The page heading, which the shared headers ask for in three spellings and
; PRINT's modules in two.
macro BREAK [x] {
}
macro Break [x] {
}
macro break [x] {
}

S_CODER = 1
S_CODE  = 2
S_DATA  = 3
S_STACK = 4

macro walk
{
	include 'PRINT_RM.ASM'
	include 'PRINT_R.ASM'
	include 'PRINT_T.ASM'
	include 'PRINT_TM.ASM'
}

; The resident part, which stays behind.
segment CodeR_
	SEGSEL = S_CODER
	walk

; The transient part: the three segments of DG in the order PRIDEFS.INC
; declares them.  Code asks for PARA and Data for BYTE, so nothing is padded
; between them; Stack asks for PARA, which is the alignment TransSize is
; measured with -- "only because code is para algned", as PRINT_T says where
; it names the end of the stack.
segment DG_
	SEGSEL = S_CODE
	walk
	SEGSEL = S_DATA
	walk
	times (16 - $ mod 16) mod 16 db 0
	SEGSEL = S_STACK
	walk
stack_top$ = $

; SS and SP as LINK set them: the stack is a segment of the group, so its
; offset is counted from the group and SS holds the group itself.  PRINT
; reads its own data through SS where DS cannot be trusted -- after the
; transient part has moved itself up, "the ASSEMBLED DG is bogus" as the
; comment there says, and the two words that have to be put right are
; written as [ss:insert_ptr_seg] and [ss:P_PTR_H] -- which only reaches
; them because SS is the group and not the 200 bytes at the top of it.
stack DG_:stack_top$

; INC/DOSMAC.INC declares a macro called entry, and the shared headers are
; read over four readings apiece, so the name is given back to the assembler
; before the entry point can be named.  A purge of a name that holds no
; macro does nothing, so the count here only has to be large enough.
rept 64 { purge entry }

entry DG_:TRANSIENT		; the source ends with END Transient
