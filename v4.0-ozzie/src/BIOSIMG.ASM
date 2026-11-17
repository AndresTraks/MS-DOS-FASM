; IBMBIO.COM: the whole Multitasking DOS BIOS, the way BIOSOBJ.MAK built it.
;
; Both src/BIOSLNK.ASM and src/QEMULNK.ASM read this file; they differ only in
; the one switch below.
;
;	link ibmbio ibmmtcon ibmdsk sysini sysimes,ibmbio,ibmbio/map;
;	exe2bin ibmbio ibmbio.com
;
; Three of those five objects have sources, and src/BIOLNK.ASM, src/MTCLNK.ASM
; and src/DSKLNK.ASM assemble each of them alone to be held against its own
; object.  This is the other build: all three at once, laid out where LINK put
; them, with the two objects that have no source laid down from the objects
; themselves.  What comes out is a bootable file, which is the only test of
; this BIOS that is not a comparison.
;
; SYSINI.OBJ and SYSIMES.OBJ are the SYSINIT program, and the READ_ME says no
; source is supplied.  Nothing can be converted, but nothing needs to be: the
; two are closed.  The only names SYSINI imports are the seven messages
; SYSIMES exports, so sysinit.py resolves the pair into SYSINITSEG on its own
; and writes bin/SYSINIT.BIN -- 2539 bytes which are IBMBIO.COM's own, byte
; for byte -- and the only names they export are the eight below, which are
; where their PUBDEF records say they are.
;
; THE LAYOUT.  LINK combined the segments of like name in the order the
; command line gives the modules, each on a paragraph, each module's share of
; a segment aligned the way its SEGDEF asks:
;
;	CODE	    0000	IBMBIO 1009, IBMMTCON 2959, IBMDSK 3925
;	BIOSINIT    1EE0	IBMBIO 1502, IBMMTCON 47, IBMDSK 361
;	SYSINITSEG  2660	SYSINI 2404, SYSIMES 135
;
; which comes to 304Bh, and 304Bh is the length of the IBMBIO.COM Microsoft
; shipped.  The first 256 bytes of SYSINITSEG are unwritten, so the file ends
; 9EBh after 2660h rather than 964h.
;
; THE LOAD SEGMENT is 70h, and the object files say so rather than the
; documentation: four of their fixups are pointers, and in the shipped file
; each one's segment word is 0070h.  A fifth asks for the paragraph of
; SYSINIT's own segment and reads 02D6h, which is 70h + 2660h/16 -- so the
; layout above is the file's and not a guess.  EXE2BIN was given 70h as the
; base segment it asked for, and this build writes the same number.
;
; NOTHING IS EXTERNAL ANY MORE, which is the point of reading the three
; modules together: a name one of them defines is a label the others can see,
; and no number stands in for it.  Three names had to be said all the same:
;
;   * FloppyTimer$FAR and AUXDEV$FAR, where MASM had EXTRN FloppyTimer:FAR and
;     EXTRN AUXDEV:FAR.  MASM told the external from the label by which file it
;     was reading, and in one name space the name belongs to the label; so the
;     reference carries the spelling of its EXTRN and is given the pair here.
;   * Com1Dev, which needs no renaming at all: MASM was blind to the case of a
;     name and IBMBIO spells it COM1DEV, so the two are already two names.
;
; THE PADDING.  Our IBMMTCON comes out 3 bytes shorter than its object and our
; IBMDSK 4, which checkobj.py accounts for: MASM left a NOP behind wherever it
; shortened one of its own forward jumps.  Those bytes are made up at the end
; of each module's share, so that the next module and in the end SYSINITSEG
; begin where LINK had them, and a NOP is what they are made up with.  The
; offsets inside those two modules are therefore a few bytes below MASM's
; from the first dropped NOP onwards, which is why this build is held against
; the shipped file by what it does and not byte for byte.

include 'BIOSMAC.INC'		; ASSUME, which MASM had and FASM has not
include 'DEFDBUG.INC'

; QEMUFDC says whether the two changes QEMU's floppy controller wants are in
; -- four Sense Interrupt Status commands after a controller reset, and 300
; kbps instead of 250.  They are changes to what the source does and not
; conversions of it, so neither build makes the choice for itself: whichever
; file read this one has already said which it is, and convert.py's table says
; what goes wrong without them.

S_CODE		= 1
S_BIOSINIT	= 2

; The group's base, which every segment of the BIOS is addressed from, and
; what EXE2BIN bound the segment references to.  IBMBIO.ASM says 70h itself,
; in the BIOSEG its device headers are written with.
BiosSeg		= 70h

; SYSINITSEG: where it ends up, and the eight names its two objects export at
; the offsets their PUBDEF records give.
SYSINIT$SEG		= 2D6h	; 70h + 2660h/16, as LINK resolved it
SYSINIT			equ SYSINIT$SEG:100h
CURRENT_DOS_LOCATION	= 105h
FINAL_DOS_LOCATION	= 109h
DEVICE_LIST		= 10Bh
MEMORY_SIZE		= 10Fh
DEFAULT_DRIVE		= 111h

; BiosInit's own paragraph, which MASM asked for with SEG and LINK filled in.
; 1EE0h is where BIOSINIT begins, and the assembly stops below if it does not.
BiosInit$SEG		= BiosSeg + 1EE0h shr 4

; The three names above, as a segment and an offset or as an offset alone.
FloppyTimer$FAR		equ BiosSeg:FloppyTimer		; in IBMDSK
AUXDEV$FAR		equ BiosSeg:AUXDEV		; in IBMBIO
Com1Dev			equ BiosSeg:COM1DEV		; in IBMBIO
Floppydevice		= FloppyDevice			; in IBMDSK

; fill: out to where LINK's own segment ended, with NOPs, which is what the
; bytes being made up were.  A segment that has grown past LINK's -- which the
; four senses above make of CODE, by twelve bytes -- is left as it is, and the
; paragraph it ends on is what has to come out right; was() is the check on
; that.
macro fill want*, where*
{
	if ($ - $$) < want
		times want - ($ - $$) db 90h
	end if
}

; para: the gap LINK left to begin a segment on a paragraph, which it left as
; zeros.
macro para
{
	times ((-($ - $$)) and 15) db 0
}

; was: the assembly stops rather than write a file laid out differently from
; the one SYSINITSEG's pointers were resolved for.
macro was where*, want*
{
	if ($ - $$) <> want
		display 'the BIOS is not laid out the way LINK laid it: ', where, 13, 10
		err
	end if
}

org 0

SEGSEL = S_CODE
	include 'IBMBIO.ASM'		; the BIOS proper
	include 'IBMMTCON.ASM'		; the console
	include 'IBMDSK.ASM'		; the disks
	fill 1ED5h, 'CODE'
para
	was 'BIOSINIT', 1EE0h

SEGSEL = S_BIOSINIT
	include 'IBMBIO.ASM'		; what runs once, in the same order
para					;  -- each share began on a paragraph
	include 'IBMMTCON.ASM'
para
	include 'IBMDSK.ASM'
	fill 2659h, 'BIOSINIT'
para
	was 'SYSINITSEG', 2660h

; And SYSINIT, which is nobody's source: the two objects resolved.
file '../bin/SYSINIT.BIN'
	was 'the end of the file', 304Bh
