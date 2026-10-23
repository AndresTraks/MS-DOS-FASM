; EDLIN.COM, from EDLIN.ASM, the procedures in EDLPROC.ASM and the messages
; in EDLMES.ASM.
;
; The release ships an EDLIN.COM and it runs here; this builds it from the
; source.  Three segments in one group and ORG 100H, the shape CHKDSK and
; DISKCOPY have, so the walk reads the modules once per segment.
;
; The modules go in the order CHKDSK's do -- the program, its procedures, its
; messages -- nothing in the source saying otherwise.  RET1 and RET9 are each
; declared in two of them, local returns that never met while the modules were
; assembled apart, so the second of each is renamed.

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
        include 'EDLIN.ASM'
        include 'EDLPROC.ASM'
        include 'EDLMES.ASM'
}

SEGSEL = S_CODE
        walk
SEGSEL = S_CONST
        walk
SEGSEL = S_DATA
        walk
