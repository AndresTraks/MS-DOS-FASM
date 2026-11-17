; IBMDSK, the Multitasking DOS disk drivers, as its object file has them.
;
; As with src/BIOLNK.ASM and src/MTCLNK.ASM, this assembles the one module
; alone so that what FASM lays down can be held against IBMDSK.OBJ.  The
; bootable IBMBIO.COM is src/BIOSLNK.ASM's, which reads all three modules
; together.
;
; Two segments in the group BiosSeg, Code and BiosInit, which the object
; declares at 3925 and 361 bytes.  This module writes the second inside the
; first rather than after it -- MASM lets a segment stand inside another, and
; the object shows what came of it: CODE lays down bytes up to 0x334, then the
; whole of BIOSINIT, then CODE again from 0x334.  A segment so written is
; suspended and resumed rather than ended, which is what the walk below does
; with it.
;
; The six structure instances the module declares -- the two drivers' state
; and the four per-drive tables -- are the six LIDATA records of the object,
; MASM's way of writing repeated data: a structure instance is the defaults
; its declaration gives, laid down field by field.

include 'BIOSMAC.INC'		; ASSUME, which MASM had and FASM has not
include 'DEFDBUG.INC'

; What LINK would have resolved.  Every one of them is a fixup in the object,
; so the bytes they land in are bytes the comparison has to ignore in any
; case.
DosFunction		= 0	; the DOS function routine, in IBMBIO
BUGBITS			= 0	; the debug flags, in IBMBIO
DPRINTF			= 0	; and the printf they feed, which is only
				; assembled when DEBUGFLG is defined
Interrupt		= 0	; the BIOS interrupt entry, in IBMBIO
CmdErr			= 0	; and its five status exits
StatusComplete		= 0
StatusError		= 0
StatusDevReady		= 0
SetStatus		= 0
Com1Dev			= 0	; the serial device header, in IBMBIO: the
				; next link of the device chain, which the
				; fixed disk's header points at

; The group's own base, which MASM wrote on the far pointer from the floppy's
; device header to the fixed disk's and left to LINK.  Assembled by itself
; there is nothing for it to be but zero, and the object's fixup covers the
; bytes it reaches.
BiosSeg			= 0

; The module is laid down as the release wrote it: the two changes QEMU's
; floppy controller wants are in IBMDSK alone -- see convert.py's table, and they are what the object
; this is held against knows nothing of.
QEMUFDC		= 0

S_CODE		= 1
S_BIOSINIT	= 2

macro walk
{
	include 'IBMDSK.ASM'
}

SEGSEL = S_CODE
	walk
SEGSEL = S_BIOSINIT
	walk
