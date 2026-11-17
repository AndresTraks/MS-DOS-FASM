; IBMMTCON, the Multitasking DOS console driver, as its object file has it.
;
; As with src/BIOLNK.ASM, this assembles the one module alone so that what
; FASM lays down can be held against IBMMTCON.OBJ.  The bootable IBMBIO.COM
; is src/BIOSLNK.ASM's, which reads all three modules together.
;
; Two segments in the group BiosSeg, Code and BiosInit, which the object
; declares at 2959 and 47 bytes.  Three more are SEGMENT AT and lay nothing
; down, so they are not walked: RomData is the ROM's own data at 40H, and
; MonoSc and ColorSc are the display buffers at B000H and B800H.  The object
; declares those two with no length at all, which is what a window on
; somebody else's memory comes to.
;
; The module is the one that would have been linked with the resident BIOS --
; it says INBIOS, and all four of its switches are on -- so the externals
; below are IBMBIO's and IBMDSK's, each assembled on its own as this is.

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
CmdErr			= 0	; and its four status exits
StatusComplete		= 0
StatusError		= 0
StatusDevReady		= 0

; A FAR external is a segment and an offset, and an equ of a seg:off pair is
; substituted as it stands, so a DD of one comes out a far pointer as MASM
; laid it down.  The name carries the spelling of its EXTRN rather than its
; own, because the link that builds the whole BIOS reads IBMBIO too and there
; the name is IBMBIO's label -- see src/BIOSLNK.ASM.
AUXDEV$FAR		equ 0:0	; the serial device header, in IBMBIO

; The group's own base, which MASM wrote on the far call of DoInt16 and left
; to LINK.  Assembled by itself there is nothing for it to be but zero, and
; the object's fixup covers the bytes it reaches.
BiosSeg			= 0

S_CODE		= 1
S_BIOSINIT	= 2

macro walk
{
	include 'IBMMTCON.ASM'
}

SEGSEL = S_CODE
	walk
SEGSEL = S_BIOSINIT
	walk
