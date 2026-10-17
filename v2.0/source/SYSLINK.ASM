; SYS.COM, from SYS.ASM and the messages in SYSMES.ASM.
;
; The release does ship a SYS.COM, but it was built for 2.00 and refuses to
; run on the 2.11 this DOS reports -- "Incorrect DOS version" and nothing
; else.  The source says 1.54 to 2.11, so built from it here it runs.
;
; Three segments in one group, laid out in the order they are declared in:
; CODE, then CONST, then DATA.  Each module's contribution to each is wrapped
; in "if SEGSEL = S_<name>" by convert_utility.py, and the walk below reads
; both modules once per segment, as the linker did.

include 'DOSMAC_v211.ASM'       ; ASSUME, and the macros DOSSYM expects

FALSE   = 0
TRUE    = -1
IBMJAPVER = FALSE
IBMVER  = FALSE
MSVER   = TRUE
KANJI   = FALSE

include 'DOSSYM.ASM'            ; once, the modules being read three times

; DOSSYM.ASM makes an instance of each structure the kernel itself uses, so
; that a field can be named as struc.field.  Five it leaves as bare STRUCs,
; and SYS reads the directory entry a search returns, so find_buf needs one.
virtual at 0
  find_buf find_buf
  sizeof.find_buf = $ - find_buf
end virtual

S_CODE  = 1
S_CONST = 2
S_DATA  = 3

macro walk
{
        include 'SYS.ASM'
        include 'SYSMES.ASM'
}

        org     100h
SEGSEL = S_CODE
        walk
SEGSEL = S_CONST
        walk
SEGSEL = S_DATA
        walk
