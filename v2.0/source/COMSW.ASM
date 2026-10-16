; Use the following booleans to set assembly flags
FALSE   EQU     0
TRUE    EQU     NOT FALSE

; Use the switches below to produce the standard Microsoft version or the IBM
; version of the operating system
;
; IBMVER was set here and MSVER clear.  They are the other way round now, and
; the reason is EXEC.  Every reference COMMAND makes to the EGROUP segments --
; ZEXEC_CODE, ZEXEC_DATA, ZEXECCODEEND, OFFSET ZEXEC_CODE:_EXEC -- sits under
; IF IBM or IF IBMVER, and COMMAND.ASM ends with "IF IBMVER / INCLUDE
; EXEC.ASM", so the IBM build carries EXEC inside COMMAND.COM as a third
; group.  That is why PROC.ASM in the kernel answers _EXEC with
; error_invalid_function.  This DOS has EXEC in the kernel instead, the near
; build out of EXEC.ASM, which is what the Microsoft link does -- so this is
; the half that matches, and COMMAND asks for EXEC through INT 21h like any
; other program.
IBMVER  EQU     FALSE   ; Switch to build IBM version of Command
IBM     EQU     IBMVER
MSVER   EQU     TRUE    ; Switch to build MS-DOS version of Command

HIGHMEM EQU     FALSE   ; Run resident part above transient (high memory)
KANJI   EQU     FALSE   ; Support for dual byte Microsoft KANJI standard
IBMJAPAN        EQU     FALSE   ;MUST BE TRUE (along with IBM and KANJI)
