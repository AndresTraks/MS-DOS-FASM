; FIND.EXE, from FIND.ASM and the messages in FINDMES.ASM.
;
; The release ships a FIND.EXE and it runs here; this builds it from the
; source.  An .EXE, like EXE2BIN, so the link file is in FASM's MZ format --
; but a simpler one: the code is all in a single segment, and the only other
; is the stack, which the source declares at the end of FIND.ASM and the
; stack directive below takes its depth from.  FASM keeps the words CODE and
; STACK, so the conversion renames both with a trailing underscore.
;
; The one program here that includes no DOSSYM: it declares the half dozen
; DOS equates it needs itself, at the top of FIND.ASM.

format MZ
entry CODE_:start               ; the source ends with END START

include 'DOSMAC_v211.ASM'       ; ASSUME, which this source writes in lower case

S_CODE  = 1
S_STACK = 2

macro walk
{
        include 'FIND.ASM'
        include 'FINDMES.ASM'
}

segment CODE_
SEGSEL = S_CODE
        walk

segment STACK_
SEGSEL = S_STACK
        walk
stack STACK_:stack_top          ; as the source sizes it
