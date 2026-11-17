; IBMBIO, the Multitasking DOS 4.0 BIOS, as its object file has it.
;
; This assembles the one module alone, the way MASM did, so that what FASM
; lays down can be held against IBMBIO.OBJ.  The bootable IBMBIO.COM is built
; by src/BIOSLNK.ASM, which reads all three modules at once and lays them out
; where LINK put them; this file is the check on one of the three.
;
; Two segments, Code and BiosInit, which the source groups as BiosSeg and
; which the object declares in that order at 1009 and 1502 bytes.  The walk
; reads the module once per segment and lays them out flat from one origin,
; as a group shares one address space.  RomData is a SEGMENT AT 40H in three
; places and lays nothing down, so it is not walked: the conversion makes a
; virtual block of each.
;
; The externals are the ones MASM left to LINK, and here they are numbers
; that stand in for them.  Every one is a fixup in the object, so the bytes
; they land in are bytes the comparison has to ignore in any case:
;
;   * CURRENT_DOS_LOCATION, FINAL_DOS_LOCATION, DEVICE_LIST, MEMORY_SIZE,
;     DEFAULT_DRIVE and SYSINIT come from SYSINI.OBJ, which has no source.
;   * CONDEV is the console device header in IBMMTCON and Floppydevice the
;     disk one in IBMDSK, each assembled on its own as this is.

include 'BIOSMAC.INC'		; ASSUME, which MASM had and FASM has not
include 'DEFDBUG.INC'

; What LINK would have resolved.  Zero for all of them: the comparison reads
; the object's FIXUPP records and ignores the bytes they cover.
;
; The five SYSINIT declares are storage, and the conversion gives a reference
; to one of them the brackets MASM did not need, the EXTRN having said which
; of them is a byte, a word and a double word.
CURRENT_DOS_LOCATION	= 0
FINAL_DOS_LOCATION	= 0
MEMORY_SIZE		= 0
DEFAULT_DRIVE		= 0
DEVICE_LIST		= 0

; A NEAR external is an offset in this same group.
CONDEV			= 0	; the console header, in IBMMTCON
Floppydevice		= 0	; the disk header, in IBMDSK
Disk_Init		= 0	; and its initialisation

; A FAR one is a segment and an offset, and the difference is a byte on the
; instruction: MASM assembled CALL and JMP of these as 9A and EA, five bytes
; each, where a near one is three.  An equ of a seg:off pair is substituted
; as it stands, so the call sites read as far calls without being rewritten.
;
; FloppyTimer carries the spelling of its EXTRN rather than its own, because
; the link that builds the whole BIOS reads IBMDSK too and there the name is
; IBMDSK's label -- see src/BIOSLNK.ASM.
SYSINIT			equ 0:0	; the module that was never published
FloppyTimer$FAR		equ 0:0	; the floppy's share of the timer tick, in IBMDSK

; The group's own base, which MASM wrote on a far pointer and left to LINK.
; This module calls IBMDSK's FloppyTimer through one and writes its device
; headers with the base spelled out as BIOSEG; assembled by itself there is
; nothing for it to be but zero, and the object's fixups cover every byte it
; reaches.
BiosSeg			= 0

; And the two paragraph addresses MASM was asked for with SEG, which are
; fixups in the object for the same reason: one names the module that was
; never published, the other is this module's own second segment, whose base
; only LINK knew.
SYSINIT$SEG		= 0
BiosInit$SEG		= 0

; The module is laid down as the release wrote it: the two changes QEMU's
; floppy controller wants are not in this module, and they are what the object
; this is held against knows nothing of.
QEMUFDC		= 0

S_CODE		= 1
S_BIOSINIT	= 2

macro walk
{
	include 'IBMBIO.ASM'
}

SEGSEL = S_CODE
	walk
SEGSEL = S_BIOSINIT
	walk
