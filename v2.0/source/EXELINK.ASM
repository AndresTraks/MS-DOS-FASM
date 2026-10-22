; EXE2BIN.EXE, from EXE2BIN.ASM and the messages in EXEMES.ASM.
;
; The release ships an EXE2BIN.EXE and it runs here, so this is built for the
; sake of building it -- but it is the first .EXE this repository assembles,
; everything else being a .COM, and the only program in it with segments of
; its own rather than one address space to share: DATA for the variables,
; STACK for the stack, ZLOAD for the scratch area, CODE for the code.  FASM
; keeps the words CODE, DATA and STACK for itself, so the conversion renames
; them with a trailing underscore.
;
; The segments are declared in the order the source declares them, which is
; what the linker laid them out in: an empty "code segment byte" at the top
; of EXE2BIN.ASM puts CODE first, then DATA, STACK and ZLOAD.  ZLOAD has to
; be last.  It holds nothing -- LOAD EQU ZLOAD is simply the address the .EXE
; being converted is read in at -- and everything above it has to be free,
; which it is, maxalloc staying 0FFFFh so DOS hands over all the memory it
; can.
;
; Each segment name is a relocated base here as it was in MASM, so MOV DX,
; DATA_ loads the paragraph DOS put the data at and the loader fixes it up.

format MZ
entry CODE_:LOCATE              ; the source ends with END LOCATE

include 'DOSMAC_v211.ASM'       ; ASSUME, and the macros DOSSYM expects

FALSE   = 0
TRUE    = -1
IBMVER  = FALSE
MSVER   = TRUE
KANJI   = FALSE
OLDLINK = 0                     ; 1 to allow for the old linker's version word

include 'DOSSYM.ASM'            ; once, the modules being read once per segment

S_CODE  = 1
S_DATA  = 2
S_STACK = 3
S_ZLOAD = 4

macro walk
{
        include 'EXE2BIN.ASM'
        include 'EXEMES.ASM'
}

segment CODE_
SEGSEL = S_CODE
        walk

segment DATA_
SEGSEL = S_DATA
        walk

segment STACK_
SEGSEL = S_STACK
        walk
stack STACK_:$                  ; as deep as the source declared it

segment ZLOAD
SEGSEL = S_ZLOAD
        walk
