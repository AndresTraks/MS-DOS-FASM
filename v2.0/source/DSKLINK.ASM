; DISKCOPY.COM, from DISKCOPY.ASM and the messages in DISKMES.ASM.
;
; The release ships a DISKCOPY.COM and it runs here; this builds it from the
; source.  Three segments in one group and ORG 100H, which is CHKDSK's shape:
; a .COM, so the walk reads the modules once per segment and lays them out
; flat in the order the modules declare them -- CODE, then CONST, then DATA.
;
; DISKCOPY works a disk a track at a time through INT 25H and INT 26H, so what
; it exercises is the driver in IO.ASM as much as itself.

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
        include 'DISKCOPY.ASM'
        include 'DISKMES.ASM'
}

SEGSEL = S_CODE
        walk
SEGSEL = S_CONST
        walk
SEGSEL = S_DATA
        walk
