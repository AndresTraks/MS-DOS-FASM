; CHKDSK.COM, from CHKDSK.ASM, the procedures in CHKPROC.ASM and the messages
; in CHKMES.ASM.
;
; The release ships a CHKDSK.COM, but it was built for an earlier DOS and
; answers "Incorrect DOS version" to the 2.11 this one reports.  The source
; here is CHKDSK 2.30 and says 1.54 to 2.11, so built from it CHKDSK runs.
;
; CHKDSK knows no FAT ID below 0F8h, 1.44M disks being four years in its
; future, so it asks "Probable non-DOS disk.  Continue (Y/N)?" about every
; disk this repository boots.  Answer Y and the report that follows is right
; to the byte; tests/chkdsk.sh checks it against a disk carrying one file of
; a known size.
;
; CHKDSK spends long stretches with DS pointing at a DPB or at a directory
; buffer, so a reference to one of its own variables wants [SS:x] -- or
; [CS:x] where it reaches the group through CS -- rather than the bare name
; MASM's ASSUME let the source write.
;
; Three segments in one group, laid out in the order they are declared in:
; CODE, then CONST, then DATA.  Each module's contribution to each is wrapped
; in "if SEGSEL = S_<name>" by convert_utility.py, and the walk below reads
; all three modules once per segment, as the linker did.

include 'DOSMAC_v211.ASM'       ; ASSUME, and the macros DOSSYM expects

FALSE   = 0
TRUE    = -1
IBMJAPVER = FALSE
IBMVER  = FALSE
MSVER   = TRUE
KANJI   = FALSE

; The 2.11 symbols, not the 2.0 ones: this CHKDSK is version 2.30 and reads
; the international block, which DOSSYM.ASM does not describe.
include 'DOSSYM_v211.ASM'       ; once, the modules being read three times

S_CODE  = 1
S_CONST = 2
S_DATA  = 3

macro walk
{
        include 'CHKDSK.ASM'
        include 'CHKPROC.ASM'
        include 'CHKMES.ASM'
}

        org     100h
SEGSEL = S_CODE
        walk
SEGSEL = S_CONST
        walk
SEGSEL = S_DATA
        walk
