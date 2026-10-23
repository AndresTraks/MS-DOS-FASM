FALSE   =     0
TRUE    =     -1

IBMVER  =     TRUE                   ; Set conditional switches
MSVER   =     FALSE

SYSVER  =     FALSE                   ; if true, i/o direct to bios
                                        ; so DOS can be debugged
IBMJAPAN =    FALSE

SETCNTC =     TRUE                    ; If this is FALSE, DEBUG will not set
                                        ; the Control C int vector

ZIBO    =     TRUE                    ; true if P traces over interrupts
                                        ; and calls and dump looks pretty
PROMPT  =     "-"
FCB     =     5CH
EXEFCB  =     FCB
BUFLEN  =     80                      ; Maximum length of line input buffer
BPMAX   =     10                      ; Maximum number of breakpoints
BPLEN   =     5*BPMAX                 ; Length of breakpoint table
REGTABLEN =   14                      ; Number of registers
SEGDIF  =     0
BUFSIZ  =     512

BXREG   =     "B"+5800H               ; "BX"
BPREG   =     "B"+5000H               ; "BP"
SIREG   =     "S"+4900H               ; "SI"
DIREG   =     "D"+4900H               ; "DI"
COMMA   =     2C00H
OPBUFLEN        =     35
