; PRINT.COM, from PRINT_v211.ASM.
;
; The release ships two sources for PRINT and one binary.  PRINT.ASM accepts
; DOS 1.10 to 2.00 and PRINT_v211.ASM accepts 1.10 to 2.11, which is what this
; DOS reports, so that is the one built here; they differ in four lines, the
; other three being the IBM and MSVER switches and the path on the include.
; The shipped binary came from the other source and answers "Incorrect DOS
; version" here, so there is nothing to compare this one against.
;
; Two segments in one group and ORG 100H, so the walk is CHKDSK's with one
; pass fewer.  The ORG 0 the source puts at the top of its data segment goes:
; MASM counts a segment's offsets from the segment, and flattened into one
; address space that ORG would wind the counter back over the code.
;
; PRINT is the one resident program here.  It installs handlers on INT 28H,
; the idle interrupt DOS raises while it waits for the console, and -- built
; IBM, as the 2.11 source comes -- on INT 1CH, the ROM's user timer tick, and
; prints a character at a time from them.  It also hooks INT 13H so that it
; knows when someone else is using the disk, and INT 05H, 14H and 17H to find
; which device the list device is.  Characters go to the device driver, by
; calling the strategy and interrupt entries in its header, not to the card.
;
; The timer handler refuses to run while the INDOS flag is set, which it is
; for as long as DOS is inside a call -- including all the time DOS spends
; waiting in the console driver for a key.  So at the prompt the INT 28H path
; is the only one that moves, and it moves one character per interrupt, which
; is what tests/print.sh has to pump.

include 'DOSMAC_v211.ASM'       ; ASSUME, and the macros DOSSYM expects

FALSE   = 0
TRUE    = -1
IBMVER  = FALSE
MSVER   = TRUE
KANJI   = FALSE

include 'DOSSYM.ASM'            ; once, the module being read twice

S_CODE  = 1
S_DATA  = 2

macro walk
{
        include 'PRINT_v211.ASM'
}

SEGSEL = S_CODE
        walk
SEGSEL = S_DATA
        walk
