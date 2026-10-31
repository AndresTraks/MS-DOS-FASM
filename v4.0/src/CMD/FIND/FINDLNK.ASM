; FIND.EXE, from FIND.ASM and the heading in FINDMES.ASM.
;
; Two segments and no group: CODE, which holds the program and all of its
; data, and STACK, which holds nothing but the stack.  So an offset is
; counted from the segment it is in, which is what two fasm segments give,
; and the walk below is the kernel's -- read the modules once per segment.

format MZ

; FIND asks DOS for no memory of its own: its buffer and its stack are both
; declared in the image.  One paragraph is what LINK asked for.
heap 1

; MASM's listing directives, in the spellings the modules use.
macro title [x] {
}
macro PAGE [x] {
}
macro SUBTTL [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}

S_CODE  = 1
S_STACK = 2

macro walk
{
	include 'FIND.ASM'
	include 'FINDMES.ASM'
}

segment CODE_
SEGSEL = S_CODE
	walk

segment STACK_
SEGSEL = S_STACK
	walk
; The top of the stack the source declared, which is the end of the segment.
; It is named rather than written as $, because $ inside the stack directive
; is not where the segment has got to.
stack STACK_:stack_top

entry CODE_:START		; the source ends with END START
