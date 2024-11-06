TRUE    EQU     0FFFFH
FALSE   EQU     NOT TRUE

; Use the switches below to produce the standard Microsoft version or the IBM
; version of the operating system
MSVER   EQU     0
IBM     EQU     1
WANG    EQU     0
ALTVECT EQU     0

; Set this switch to cause DOS to move itself to the end of memory
HIGHMEM EQU     FALSE

        IF      IBM
ESCCH   =     0                       ; character to begin escape seq.
CANCEL  =     27
TOGLINS =     1                       ;One key toggles insert mode
TOGLPRN =     1                       ;One key toggles printer echo
ZEROEXT =     1
        ELSE
        IF      WANG                    ;Are we assembling for WANG?
ESCCH   =     1FH                     ;Yes. Use 1FH for escape character
        ELSE
ESCCH   =     1BH
        END     IF
CANCEL  =     "X"-"@"                 ;Cancel with Ctrl-X
TOGLINS =     WANG                    ;Separate keys for insert mode on
                                        ;and off if not WANG
TOGLPRN =     FALSE                   ;Separate keys for printer echo on
                                        ;and off
ZEROEXT =     TRUE
        END     IF

