; EXE2BIN.EXE, from E2BINIT.ASM and DISPLAY.ASM, in the order EXE2BIN.LNK
; names them.
;
; Four segments and no group: CODE for the program, DATA for its data and its
; messages, STACK for nothing but the stack, and ZLOAD, one byte naming the
; place the .EXE being converted is read into.  ZLOAD comes last because the
; image read there grows past it into whatever memory follows.  So an offset
; is counted from the segment it is in, which is what four fasm segments
; give, and the walk below is the kernel's -- read the modules once per
; segment.

format MZ

; MASM's listing directives, in the spellings the modules use.
macro title [x] {
}
macro TITLE [x] {
}
macro PAGE [x] {
}
macro SUBTTL [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}
macro .XCREF [x] {
}
macro .CREF [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}
macro page [x] {
}
macro subttl [x] {
}
macro Title [x] {
}
macro Subttl [x] {
}
macro Page [x] {
}

; The message retriever's own data table is asked for in the DATA segment --
; MSG_SERVICES <MSGDATA> stands in E2BINIT.ASM's DATA part -- so DS is the
; register that reaches it, and not CS as it is for a program of one segment.
; SYSMSG.INC reads this and leaves its own default alone.
M_SEG$ equ ds

S_CODE  = 1
S_DATA  = 2
S_STACK = 3
S_ZLOAD = 4

macro walk
{
	include 'E2BINIT.ASM'
	include 'DISPLAY.ASM'
}

segment CODE_
SEGSEL = S_CODE
	walk

segment DATA_
SEGSEL = S_DATA
	walk

segment STACK_
SEGSEL = S_STACK
	walk

segment ZLOAD_
SEGSEL = S_ZLOAD
	walk

; The stack the source declares is 362 bytes, so its top is the end of it.
stack STACK_:362

; INC/DOSMAC.INC declares a macro called entry, which the modules have read
; by now, so the name has to be given back to the assembler before the entry
; point can be named -- once for each of the four readings of the modules,
; since every one of them declares it again and purge takes away the latest.
	purge entry,entry,entry,entry
entry CODE_:Main_Init		; the source ends with END MAIN_INIT
