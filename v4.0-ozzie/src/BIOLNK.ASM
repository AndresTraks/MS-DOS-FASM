; IBMBIO, the Multitasking DOS 4.0 BIOS, as its object file has it.
;
; This does not build a bootable IBMBIO.COM and it cannot.  BIOSOBJ.MAK makes
; one out of five objects --
;
;	link ibmbio ibmmtcon ibmdsk sysini sysimes,ibmbio,ibmbio/map;
;	exe2bin ibmbio ibmbio.com
;
; -- and the sources of the last two were never published: bin/DISK2/BIOS has
; SYSINI.OBJ and SYSIMES.OBJ and no .ASM for either, and sysini.asm would
; want dossym.inc, devsym.inc and syscalls.inc, which are not there either.
; So what this file is for is to assemble the one module the way MASM did,
; alone, so that what FASM lays down can be held against IBMBIO.OBJ, which
; is the only check there is here.
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
SYSINIT			equ 0:0	; the module that was never published
FloppyTimer		equ 0:0	; the floppy's share of the timer tick, in IBMDSK

; And the two paragraph addresses MASM was asked for with SEG, which are
; fixups in the object for the same reason: one names the module that was
; never published, the other is this module's own second segment, whose base
; only LINK knew.
SYSINIT$SEG		= 0
BiosInit$SEG		= 0

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
