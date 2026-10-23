; PRINT.COM, from PRINT_v211.ASM.
;
; The release ships two sources for PRINT and one binary.  PRINT.ASM accepts
; DOS 1.10 to 2.00 and PRINT_v211.ASM accepts 1.10 to 2.11, which is what this
; DOS reports, so that is the one built here; they differ in four lines, the
; other three being the IBM and MSVER switches and the path on the include.
;
; Two segments in one group and ORG 100H, so the walk is CHKDSK's with one
; pass fewer.  The ORG 0 the source puts at the top of its data segment goes:
; MASM counts a segment's offsets from the segment, and flattened into one
; address space that ORG would wind the counter back over the code.
;
; It is not finished.  It installs -- "Resident part of PRINT installed" --
; and then the machine stops: QEMU's monitor finds the CPU at 0100:07F1 with
; identical registers from one second to the next, and the bytes there are
; F0 F1, a LOCK prefix on an invalid opcode, which SeaBIOS's INT 6 handler
; IRETs from so that it runs for ever.  Something has returned or jumped into
; memory that holds an interrupt frame rather than code, which is the same
; shape of failure CHKDSK showed before its missing overrides were found.
;
; What has been ruled out, so nobody spends the time again:
;
;   * the overrides.  checkassume.py found 54 references in the resident part
;     that MASM had put a CS: on and the conversion had not -- the handlers
;     run with DS belonging to whatever was interrupted -- and they are fixed.
;     The pass is clean now, and the fault survived the fix.
;   * the size of an indirect call or jump.  PRINT chains through CALLAD,
;     NEXTINT and REAL_INT_17, all declared DD, and MASM takes the far form
;     from the declaration.  So does FASM: "call [cs:vec]" with vec declared
;     dd assembles as FF /3, the far form, exactly as MASM assembles it.  The
;     same question was asked of the kernel's JMP [CS:OEM_HANDLER] and
;     SYSINIT's CALL [CS:ENTRY_POINT], and both are right for the same
;     reason.
;
; What to look at next: the EOI this build sends for itself.  IBM sets AINT,
; so the INT 1CH handler acknowledges the interrupt at port 20H, and INT 1CH
; is called from the ROM's INT 8 handler, which acknowledges it as well.
; Two EOIs for one interrupt is what the hardware sees, and what that does to
; the ROM's handler on the way back is worth measuring before anything else.
;
; PRINT is the one resident program here.  It installs a handler on INT 28H,
; the idle interrupt DOS raises while it waits for the console, and prints a
; sector at a time from there, which is how a single tasking system prints in
; the background.  Built IBM, as the 2.11 source comes: it goes to the card
; through INT 17H rather than through the DOS device.

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
