; FC.EXE, from FC.ASM and the messages in FCMES.ASM.
;
; The release ships an FC.EXE and it runs here; this builds it from the
; source.  Laid out like SORT: code, const and data are in one group, dg, so
; one FASM segment holding the three of them in declaration order gives the
; group-relative offsets the source counts on.  The stack is outside the
; group, as the source declares it, so it gets a segment of its own and the
; stack directive takes its depth from the walk.
;
; FASM keeps the words CODE, DATA and STACK, so those three are renamed with
; a trailing underscore; CONST it does not mind.
;
; It comes out four times the size of the FC.EXE in bin, 10720 bytes against
; 2553.  The difference is the buffers: FC declares two of 4K at the end of
; its data, LINK left trailing uninitialised data out of the file and had DOS
; clear it on loading, and a FASM segment holds every byte it is given.  The
; program is the same; the file is longer.
;
; FC asks for DOSSYM in lower case, "include dossym.asm", so it is easy to
; read the module as needing none.  It needs one, and the walk reading the
; modules four times means it is included here instead.

format MZ
entry DG_:start                 ; the source ends with END START

include 'DOSMAC_v211.ASM'       ; ASSUME, which this source writes in lower case

FALSE   = 0
TRUE    = 0FFH                  ; what FC and FCMES both make it, not -1
IBMVER  = FALSE
MSVER   = TRUE
KANJI   = FALSE

include 'DOSSYM.ASM'            ; once, the modules being read four times

S_CODE  = 1
S_CONST = 2
S_DATA  = 3
S_STACK = 4

macro walk
{
        include 'FC.ASM'
        include 'FCMES.ASM'
}

segment DG_
SEGSEL = S_CODE
        walk
SEGSEL = S_CONST
        walk
SEGSEL = S_DATA
        walk

segment STACK_
SEGSEL = S_STACK
        walk
stack STACK_:$                  ; as deep as the source declared it
