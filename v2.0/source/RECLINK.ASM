; RECOVER.COM, from RECOVER.ASM and the messages in RECMES.ASM.
;
; The release ships a RECOVER.COM and it runs here; this builds it from the
; source.  Three segments in one group and ORG 100H, the same shape as
; DISKCOPY and CHKDSK, so the walk reads the modules once per segment.
;
; RECOVER has two jobs.  Given a file it reads it allocation unit by
; allocation unit, drops the units that will not read and writes the rest
; back, so a file with a bad sector in it loses a cluster instead of all of
; it.  Given a drive it rebuilds the root directory from the FAT, naming what
; it finds FILEnnnn.REC, which is the one way back from a directory that no
; longer reads.

include 'DOSMAC_v211.ASM'       ; ASSUME, and the macros DOSSYM expects

FALSE   = 0
TRUE    = -1
IBMVER  = FALSE
MSVER   = TRUE
KANJI   = FALSE

include 'DOSSYM.ASM'            ; once, the modules being read three times

S_CODE  = 1
S_CONST = 2
S_DATA  = 3

macro walk
{
        include 'RECOVER.ASM'
        include 'RECMES.ASM'
}

SEGSEL = S_CODE
        walk
SEGSEL = S_CONST
        walk
SEGSEL = S_DATA
        walk
