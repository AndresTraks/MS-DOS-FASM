; PROFIL.COM, from PROFIL.ASM and the clock module in PCLOCK_IBM.ASM.
;
; The profiler is the one program in the release that was shipped as an object
; file rather than a binary: bin/PROFIL.OBJ is this PROFIL.ASM assembled, and
; there is no PROFIL.COM beside it, because PROFILE.DOC leaves one module to
; the OEM -- the clock, which has to start and stop whatever timer the machine
; has and hand the interrupt to PROFIL's CLK_INTER.  PCLOCK.ASM in this
; directory is Microsoft's own for the Seattle Computer Products 8086, which
; is not a PC; PCLOCK_IBM.ASM beside it is this repository's, for the 8253
; counter 0 the IBM ROM keeps the time of day with.
;
; So until now the profiler was built on the system under test: MASM on the
; clock module, LINK on it and PROFIL.OBJ, EXE2BIN on what came out, about
; nine minutes of a floppy.  With PROFIL.ASM converted there is nothing left
; to link and assemble.sh builds the .COM here.
;
; Which is also how the conversion was checked, bin/PROFIL.OBJ being this
; PROFIL.ASM as MASM assembled it.  Its three segments are 870, 616 and 460
; bytes, the first 256 of CODE being the ORG 100H, and FASM lays down 612,
; 616 and 460.  Held against the object:
;
;   * DATA is identical.  All 298 initialised bytes of it match, and the
;     rest is the storage MASM reserved and LINK filled with zeros, which
;     is what DB n DUP(?) becomes here.
;   * INIT is 197 instructions and every one of them is the same
;     instruction, the same length, in the same place.
;   * CODE is 254 instructions and every one of them is the same
;     instruction, two of which FASM writes shorter: AND BX,0FH and
;     AND DX,000FH.  MASM 1.x gives a logical operation on a word register
;     the full word immediate, 81 /4 and four bytes, where FASM takes the
;     8086's sign extended byte form, 83 /4 and three.  It optimises
;     ADD, SUB, ADC, SBB and CMP the same way MASM does -- SUB BX,2 and
;     ADD BX,10H come out the same length -- and only the logical ones
;     differ.  So the program is two bytes shorter than the one LINK built
;     and nothing in it depends on its own length: every address PROFIL
;     works out, the program area and the bucket count among them, it works
;     out at run time from the labels.
;
; The clock module needs no such allowance: MASM made 108 bytes of it and so
; does FASM.  To redo any of this, read the OMF records of bin/PROFIL.OBJ --
; LNAMES, SEGDEF, LEDATA and FIXUPP, a dozen lines of Python -- and hold the
; LEDATA against this build, taking a byte a FIXUPP covers as a wildcard
; because LINK is what filled those in.
;
; Three segments in one group and ORG 100H, which is CHKDSK's shape and
; DISKCOPY's: a .COM, so the walk reads both modules once per segment and
; lays them out flat in the order PROFIL.ASM declares them under the heading
; "Segments in load order" -- CODE, then DATA, then INIT.  CODE is the only
; one both modules contribute to; the clock module adds its two saved vector
; words to the end of it, which is where LINK put them.
;
; INIT holds the code that asks the questions, and PROFIL overwrites it with
; the program it is profiling as soon as it has the answers.  So it is last
; on purpose, and the three segments are in the order they are for that
; reason and not by accident.
;
; PROFIL includes no DOSSYM: the dozen system calls it makes are numbered at
; the top of PROFIL.ASM in its own equates, as FIND's are.

include 'DOSMAC_v211.ASM'       ; ASSUME, which both modules write

S_CODE  = 1
S_DATA  = 2
S_INIT  = 3

macro walk
{
        include 'PROFIL.ASM'            ; sets ORG 100H in its CODE segment
        include 'PCLOCK_IBM.ASM'        ; CLOCKON, CLOCKOFF and LEAVE_INT
}

SEGSEL = S_CODE
        walk
SEGSEL = S_DATA
        walk
SEGSEL = S_INIT
        walk
