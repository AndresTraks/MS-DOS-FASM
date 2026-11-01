; RECOVER.COM, from the four modules in the order RECOVER.LNK names them.
;
; Five segments in one group, DG -- DATA, CODE, CONST, CSTACK and LASTSEG, in
; the order RECSEG.INC declares them -- so there is one address space and an
; offset is counted from the group.  One group is one fasm segment, and the
; walk below is the kernel's: read the modules once per segment, so that
; every module's contribution to a segment is laid down with the rest of it.
;
; The release links the modules into RECOVER.EXE and runs TOOLS/CONVERT over
; it, which wraps the image in a jump, the word "Converted", and a loader
; that applies the fixups itself; what comes out is called RECOVER.COM.  The
; program needs those fixups -- Set_Data_Segment asks for the group's segment
; by name -- and DOS reads the signature and not the extension, so an MZ
; image called RECOVER.COM is loaded and fixed up as the .EXE it is.  That is
; what this writes, and the wrapper is not needed for it.
;
; LASTSEG is last and empty: its one label is where the program ends, and the
; FAT RECOVER reads is put there, past everything.  CSTACK is the stack, and
; every module reads RECSEG.INC, so each one lays down its own 490 bytes of
; it -- 1960 bytes in all, which is what LINK gathered as well.

format MZ

; MASM's listing directives, in the spellings the modules use.
macro title [x] {
}
macro TITLE [x] {
}
macro PAGE [x] {
}
macro page [x] {
}
macro SUBTTL [x] {
}
macro subttl [x] {
}
macro .XLIST [x] {
}
macro .xlist [x] {
}
macro .LIST [x] {
}
macro .list [x] {
}
macro .XCREF [x] {
}
macro .xcref [x] {
}
macro .CREF [x] {
}
macro .cref [x] {
}
macro .LALL [x] {
}
macro .lall [x] {
}
macro .SALL [x] {
}
macro .sall [x] {
}

; RECPROC.ASM declares a page heading called BREAK, which is a word fasm
; keeps for itself as a directive; as the name of a macro it is its own, and
; a heading writes nothing either way.
macro BREAK [x] {
}

; MASM padded to the next even address.  RECOVER.ASM asks for it three times.
macro even
{
	align 2
}

S_DATA    = 1
S_CODE    = 2
S_CONST   = 3
S_CSTACK  = 4
S_LASTSEG = 5

macro walk
{
	include 'RECDISP.ASM'
	include 'RECINIT.ASM'
	include 'RECPROC.ASM'
	include 'RECOVER.ASM'
}

; A segment of the group, with every module's contribution to it in the link
; order, and paragraph aligned where the segment asked for PARA.  CSTACK asks
; for WORD.
macro group$ selector, para
{
    if para
	times (16 - $ mod 16) mod 16 db 0
    else
	times $ mod 2 db 0
    end if
	SEGSEL = selector
	walk
}

segment DG_

	group$ S_DATA,    1
	group$ S_CODE,    1
	group$ S_CONST,   1
	group$ S_CSTACK,  0
stack_top:
	group$ S_LASTSEG, 1

; SS and SP as LINK set them from the stack segment: the group holds CSTACK,
; so SS is the group and SP the end of the room the four readings reserved.
stack DG_:stack_top

; INC/DOSMAC.INC declares a macro called entry, and every module reads it
; through INC/DOSSYM.INC: four modules over five readings is twenty, so the
; name is given back to the assembler twenty times before the entry point
; can be named.  purge takes the latest declaration away each time.
	purge entry,entry,entry,entry,entry
	purge entry,entry,entry,entry,entry
	purge entry,entry,entry,entry,entry
	purge entry,entry,entry,entry,entry
entry DG_:Main_Init		; the source ends with END MAIN_INIT
