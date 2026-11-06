; CHKDSK.COM, from the nine modules in the order CHKDSK.LNK names them.
;
; Five segments in one group, DG -- data, const, code, cstack and lastseg, in
; the order CHKSEG.INC declares them -- so there is one address space and an
; offset is counted from the group, which is EDLIN's shape.  The walk below
; is the kernel's: read the modules once per segment, so that every module's
; contribution to a segment is laid down with the rest of it.
;
; PSP is the sixth segment and the one outside the group: CHKINIT declares it
; to name the two FCBs DOS leaves in the program's prefix, at 5Ch and 6Ch,
; and it holds nothing of the program's.  The reading that gives those two
; names their offsets is done inside a VIRTUAL block, which writes nothing
; and leaves the address counter where it found it.
;
; The release links the modules into CHKDSK.EXE and runs TOOLS/CONVERT over
; it, which wraps the image in a jump, the word "Converted", and a loader
; that applies the fixups itself, and calls what comes out CHKDSK.COM.  The
; program needs those fixups -- it asks for the group's segment by name -- and
; DOS reads the signature and not the extension, so an MZ image called
; CHKDSK.COM is loaded and fixed up as the .EXE it is.  That is what this
; writes, as EDLIN.COM and RECOVER.COM are written.

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
macro .LALL [x] {
}
macro .SALL [x] {
}
macro .XALL [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
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

S_PSP     = 1
S_DATA    = 2
S_CONST   = 3
S_CODE    = 4
S_CSTACK  = 5
S_LASTSEG = 6

macro walk
{
	include 'CHKDISK.ASM'
	include 'CHKDISP.ASM'
	include 'CHKDSK1.ASM'
	include 'CHKDSK2.ASM'
	include 'CHKFAT.ASM'
	include 'CHKINIT.ASM'
	include 'CHKPRMT.ASM'
	include 'CHKPROC2.ASM'
	include 'CHKPROC.ASM'
}

; A segment of the group, with every module's contribution to it in the link
; order.  All five ask for PARA, which is what a segment that does not say
; gets as well.
macro group$ selector
{
	times (16 - $ mod 16) mod 16 db 0
	SEGSEL = selector
	walk
}

; The prefix, which lays nothing down.
virtual at 0
	SEGSEL = S_PSP
	walk
end virtual

segment DG_

	group$ S_DATA
	group$ S_CONST
	group$ S_CODE
	group$ S_CSTACK

; The top of the stack is the end of cstack, which is what LINK set SP to:
; the segment is in the group, so SS is the group's and the offset is counted
; from there.
stack_top$:

	group$ S_LASTSEG

stack DG_:stack_top$

; INC/DOSMAC.INC declares a macro called entry, and seven of the modules
; read it through INC/DOSSYM.INC over six readings apiece, so the name is
; given back to the assembler as many times before the entry point can be
; named.  A purge of a name that holds no macro does nothing, so the count
; here only has to be large enough.
rept 64 { purge entry }

entry DG_:CHKDSK		; the source ends with END CHKDSK
