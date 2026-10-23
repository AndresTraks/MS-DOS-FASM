; DEBUG.COM, from DEBUG.ASM and the seven modules beside it.
;
; Three segments in one group -- CODE, CONST, DATA -- across eight modules,
; the most of either in this release.  Each module's contribution to each
; segment is wrapped in "if SEGSEL = S_<name>" by convert_utility.py, and the
; walk below reads all eight once per segment, as the linker did.
;
; The ORG 100H stays where the source puts it, at the top of DEBUG.ASM's
; CODE, which is why DEBUG.ASM is read first.
;
; DEBUG declares what it takes from its neighbours with EXTRN rather than
; leaving the linker to find it, so nothing here depends on the order of the
; other seven; the order they are in decides the layout and nothing else, and
; the release keeps no response file to say what it was.
;
; The DEBUG.COM the release ships says "Vers 2.10" and this source says
; "Vers 2.30": the binary was built from an earlier DEBUG, and among the
; things it has not got is the call to TrapParity that the source makes six
; instructions in.  So ours is 385 bytes larger and no comparison of the two
; files would mean anything.  It does accept this version, though -- it asks
; for 2.00 or better and sets no upper bound -- so tests/debug.sh runs both
; over the same script of commands and compares what they print.
;
; A debugger names its labels after the instructions it debugs: there are
; labels here called IN, OUT, TEST, ERR, LOAD, STORE, STACK, ENTER, FSAVE and
; INT3, every one of which FASM wants for itself.  The conversion gives each
; a trailing underscore, leaving the mnemonic of a line alone so that the
; instructions still assemble.

include 'DOSMAC_v211.ASM'       ; ASSUME, and the macros DOSSYM expects

include 'DEBEQU.ASM'            ; the switches, and DEBUG's own equates

include 'DOSSYM.ASM'            ; once, the modules being read three times

S_CODE  = 1
S_CONST = 2
S_DATA  = 3

macro walk
{
        include 'DEBUG.ASM'
        include 'DEBCOM1.ASM'
        include 'DEBCOM2.ASM'
        include 'DEBASM.ASM'
        include 'DEBUASM.ASM'
        include 'DEBMES.ASM'
        include 'DEBCONST.ASM'
        include 'DEBDATA.ASM'
}

SEGSEL = S_CODE
        walk
SEGSEL = S_CONST
        walk
SEGSEL = S_DATA
        walk
