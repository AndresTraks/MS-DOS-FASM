; SORT.EXE, from SORT.ASM and the collating table in SORTMES.ASM.
;
; An .EXE for the sake of its stack, but not an .EXE like EXE2BIN's: CODE,
; CONST and CSTACK are all in one group, DG, so they share an address space
; and a symbol's offset is counted from the group.  One fasm segment holding
; the three of them in the order the source declares them gives exactly that,
; and the walk below is the kernel's -- read the modules once per segment --
; rather than a segment directive for each.
;
; So SS and CS both point at the one segment, where MASM had SS on CSTACK and
; CS on the group.  Those are the same bytes: nothing in SORT names a
; variable in the stack, and the stack directive puts SP at the top of it.

format MZ

; SORT asks DOS for its buffer with function 48H, so it must not be given all
; of memory to begin with.  One paragraph is what LINK asked for.
heap 1

; MASM's listing directives, in the spellings the modules use.
macro PAGE [x] {
}
macro SUBTTL [x] {
}
macro TITLE [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}

S_CODE   = 1
S_CONST  = 2
S_CSTACK = 3

macro walk
{
	include 'SORT.ASM'
	include 'SORTMES.ASM'
}

segment DG_
SEGSEL = S_CODE
	walk
SEGSEL = S_CONST
	walk
SEGSEL = S_CSTACK
	walk
; The top of the stack the source declared, which is the end of the segment.
; It is named rather than written as $, because $ inside the stack directive
; is not where the segment has got to and the stack would start outside the
; block DOS allocates.
stacktop$:
stack DG_:stacktop$

entry DG_:SORT			; the source ends with END SORT
