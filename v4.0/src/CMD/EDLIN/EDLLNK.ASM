; EDLIN.COM, from the five modules in the order EDLIN.LNK names them.
;
; Four segments in one group, DG -- CODE, CONST, cstack and DATA, in the
; order EDLIN.ASM declares them -- so there is one address space and an
; offset is counted from the group, which is RECOVER's shape.  The walk below
; is the kernel's: read the modules once per segment, so that every module's
; contribution to a segment is laid down with the rest of it.
;
; cstack is the one of the four that is laid down on its own.  It holds
; nothing but EDLIN.ASM's 200H bytes and no name points into it, and EDLIN
; sets its own stack up with
;
;	MOV	AX,CSTACK
;	MOV	SS,AX
;	MOV	SP,STACK	; 200H, the size of it
;
; which wants the segment that starts where those bytes do, not the group's.
; A fasm segment of its own is that segment, and the name the source asks for
; is its name.
;
; The release links the modules into EDLIN.EXE and runs TOOLS/CONVERT over
; it, which wraps the image in a jump, the word "Converted", and a loader
; that applies the fixups itself, and calls what comes out EDLIN.COM.  The
; program needs those fixups -- it asks for the group's segment by name -- and
; DOS reads the signature and not the extension, so an MZ image called
; EDLIN.COM is loaded and fixed up as the .EXE it is.  That is what this
; writes, as RECOVER.COM is written.
;
; CODE is paragraph aligned, which is MASM's default for a segment that does
; not say; CONST and DATA ask for WORD, and cstack, which holds nothing but
; EDLIN.ASM's 200H bytes, takes the paragraph a stack segment gets.

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
macro .xlist [x] {
}
macro .list [x] {
}

; MASM padded to the next even address, with a NOP in a code segment where
; fasm's align writes a zero.
macro EVEN
{
	align 2
}

; EDLSTDSW.INC expects the switches EDLVERS.INC set, and the release does
; not ship that file: IBM says which of the two versions is being built and
; kanji whether the double-byte code is wanted.  Both are false here, which
; is the Microsoft version without it -- INC/VERSION.INC, which the rest of
; the tree reads, says IBM EQU IBMVER and KANJI EQU INTERNAT and both of
; those are false.  EDLCMD2.ASM asks after the switch in lower case, which is
; the name it is given here.
IBM   = 0
kanji = 0

S_CODE   = 1
S_CONST  = 2
S_CSTACK = 3
S_DATA   = 4

macro walk
{
	include 'EDLIN.ASM'
	include 'EDLCMD1.ASM'
	include 'EDLCMD2.ASM'
	include 'EDLMES.ASM'
	include 'EDLPARSE.ASM'
}

; A segment of the group, with every module's contribution to it in the link
; order, aligned the way that segment asked for.
macro group$ selector, align
{
    if align = 16
	times (16 - $ mod 16) mod 16 db 0
    else
	times $ mod 2 db 0
    end if
	SEGSEL = selector
	walk
}

segment DG_

	group$ S_CODE,   16
	group$ S_CONST,   2
	group$ S_DATA,    2

segment CSTACK
	SEGSEL = S_CSTACK
	walk

; EDLIN pushes the byte DOS leaves in AL -- whether the drive letter in the
; first FCB is a real one -- and then sets SP to the top of this stack, which
; is where SP already was, so the push is thrown away; the POP that reads it
; back takes the word just above the stack instead, and reports "Invalid
; drive or file name" unless it is zero.  In the release's layout that word is
; the first of DATA, which begins with two zero bytes, so the check passes
; and the drive is never really looked at.  The stack is a segment of its own
; here, so the two bytes stand here.
	dw	0

; SS and SP as LINK set them from the stack segment: the 200H bytes EDLIN.ASM
; reserves are the whole of it, so the top of the stack is the end of them.
stack CSTACK:200h

; INC/DOSMAC.INC declares a macro called entry, and EDLEQU.ASM reads it
; through INC/DOSSYM.INC: three of the modules read EDLEQU over four
; readings, so the name is given back to the assembler twelve times before
; the entry point can be named.
	purge entry,entry,entry,entry,entry,entry
	purge entry,entry,entry,entry,entry,entry
entry DG_:EDLIN			; the source ends with END EDLIN
