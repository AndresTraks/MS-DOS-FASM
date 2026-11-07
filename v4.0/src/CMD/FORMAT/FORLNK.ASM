; FORMAT.COM, from the seven modules in the order FORMAT.LNK names them.
;
; Five segments and no group at all, which makes FORMAT the first of these
; with an address space for every segment: PSP, data, stack, code and
; End_Of_Memory, in the order DISPLAY.ASM declares them -- that module is
; nothing but .SEQ and the five empty declarations, which is how MASM was
; told the order to lay them down in.  Each is a fasm segment of its own, and
; a reference across them carries the segment, which the loader fixes up.
; The walk below is the kernel's: read the modules once per segment, so that
; every module's contribution to a segment is laid down with the rest of it.
;
; PSP is the segment outside the program: FOREXEC declares it to name what
; DOS leaves in the prefix, and it holds nothing of FORMAT's own.  The
; reading that gives those names their offsets is done inside a VIRTUAL
; block, which writes nothing and leaves the address counter where it found
; it, as CHKDSK's is.
;
; End_Of_Memory is last because it is where the program's image ends and the
; buffers begin: FORMAT asks for the paragraph with "mov bx,End_Of_Memory"
; and lays the FAT and the directory it builds out above it.
;
; The release links the seven into FORMAT.EXE, runs TOOLS/CONVERT over it and
; calls what comes out FORMAT.COM -- the program asks for a segment by name,
; so it needs the fixups, and DOS reads the signature and not the extension.
; That is what this writes, as CHKDSK.COM and EDLIN.COM are written.

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

; The message retriever keeps its table of addresses in MSGDATA, which
; DISPLAY.ASM lays down in the data segment, so the program reaches it
; through DS.  Left unsaid, SYSMSG.INC reaches it through CS.
M_SEG$ equ ds

; MASM's ordering directive, which says to lay the segments down in the
; order they are declared in: that order is this file.
macro .SEQ [x] {
}
macro .seq [x] {
}

; MASM's NAME, which named the object module and is nothing here.
macro NAME [x] {
}
macro name [x] {
}

; The headers that lay structures out, read here rather than left to the
; modules.  A module's own INCLUDE of one stands inside its segment's IF, and
; fasm's preprocessor reads an INCLUDE whichever way the IF went -- so the
; guard that keeps a structure from being laid out twice was being set on a
; pass that laid it out not at all, which is what MSDOSLNK.ASM and SYSLNK.ASM
; met before this.  Read once here, outside the walk, each structure is laid
; out exactly once and every pass can see it.
;
; The three the modules keep to themselves lay bytes down and not structures:
; BOOT.INC and BOOT11.INC are boot sectors, as the DB statements MASM made of
; them, and PARSE.ASM is the parser itself.
include 'DOSMAC.INC'		; BREAK and the rest of MASM's listing macros, which
				; the headers below are written with
include 'DPB.INC'		; the drive parameter block
include 'BPB.INC'		; the BIOS parameter block of a medium
include 'DIRENT.INC'		; a directory entry
include 'CURDIR.INC'		; the current directory structure
include 'CPMFCB.INC'		; the old file control block
include 'PDB.INC'		; the program segment prefix
include 'IOCTL.INC'		; the device parameters a driver answers with
include 'BOOTFORM.INC'		; the boot record FORMAT writes
include 'SYSVAR.INC'		; the kernel's variables, for the boot drive

S_PSP		= 1
S_DATA		= 2
S_STACK		= 3
S_CODE		= 4
S_END_OF_MEMORY = 5

macro walk
{
	include 'DISPLAY.ASM'
	include 'FORINIT.ASM'
	include 'FORLABEL.ASM'
	include 'FORMAT.ASM'
	include 'FORPROC.ASM'
	include 'MSFOR.ASM'
	include 'FOREXEC.ASM'
}

; The prefix, which lays nothing down.
virtual at 0
	SEGSEL = S_PSP
	walk
end virtual

segment data_
	SEGSEL = S_DATA
	walk

segment stack_
	SEGSEL = S_STACK
	walk
stack_top$ = $

segment code_
	SEGSEL = S_CODE
	walk

segment End_Of_Memory_
	SEGSEL = S_END_OF_MEMORY
	walk

; SS and SP as LINK set them from the segment declared with the stack
; combine type.
stack stack_:stack_top$

; INC/DOSMAC.INC declares a macro called entry, and the shared headers are
; read over five readings apiece, so the name is given back to the assembler
; before the entry point can be named.  A purge of a name that holds no
; macro does nothing, so the count here only has to be large enough.
rept 64 { purge entry }

entry code_:START		; the source ends with END START
