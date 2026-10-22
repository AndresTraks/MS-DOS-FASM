; SORT.EXE, from SORT.ASM and the messages in SORTMES.ASM.
;
; The release ships a SORT.EXE and it runs here; this builds it from the
; source.  An .EXE for the sake of its stack, but not an .EXE like EXE2BIN:
; CODE, CONST and CSTACK are all in one group, DG, so they share an address
; space and a symbol's offset is counted from the group.  One FASM segment
; holding the three of them in the order the source declares them gives
; exactly that, and the walk is CHKDSK's -- read the modules once per segment
; -- rather than EXE2BIN's segment directives.
;
; So SS and CS both end up pointing at the one segment, where MASM had SS on
; CSTACK and CS on the group.  That addresses the same bytes: nothing in SORT
; names a variable in the stack, which holds 224 bytes of nothing in two
; pieces, and the stack directive below puts SP at the top of them.

format MZ
entry DG_:SORT                  ; the source ends with END SORT

; SORT asks DOS for its buffer with function 48H, so it must not be given all
; of memory to begin with: FASM's default maxalloc of 0FFFFh leaves nothing to
; allocate and SORT says "SORT: Insufficient memory" and stops.  One paragraph
; is what LINK asked for, and what this asks for.
heap 1

include 'DOSMAC_v211.ASM'       ; ASSUME, and the macros DOSSYM expects

FALSE   = 0
TRUE    = -1
IBMVER  = FALSE
MSVER   = TRUE
KANJI   = FALSE

include 'DOSSYM.ASM'            ; once, the modules being read three times

S_CODE   = 1
S_CONST  = 2
S_CSTACK = 3

macro walk
{
        include 'SORT.ASM'
        include 'SORTMES.ASM'
}

segment DG_
SEGSEL = S_CODE
        walk
SEGSEL = S_CONST
        walk
SEGSEL = S_CSTACK
        walk
stack DG_:$                     ; the top of the stack the source declared
