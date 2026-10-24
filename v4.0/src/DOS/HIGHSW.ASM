;	SCCSID = @(#)highsw.asm	1.1 85/04/10
TRUE	EQU	0FFFFH
FALSE	EQU	NOT TRUE

; Use the switches below to produce the standard Microsoft version or the IBM
; version of the operating system
MSVER	EQU	TRUE
IBM	EQU	FALSE
WANG	EQU	FALSE
ALTVECT EQU	FALSE

; Set this switch to cause DOS to move itself to the end of memory
HIGHMEM EQU	TRUE

	if	IBM
ESCCH	EQU	0			; character to begin escape seq.
TOGLPRN EQU	TRUE			;One key toggles printer echo
ZEROEXT EQU	TRUE
	else
	if	WANG			;Are we assembling for WANG?
ESCCH	EQU	1FH			;Yes. Use 1FH for escape character
	else
ESCCH	EQU	1BH
	end if
CANCEL	EQU	"X"-"@" 		;Cancel with Ctrl-X
TOGLPRN EQU	FALSE			;Separate keys for printer echo on
					;and off
ZEROEXT EQU	TRUE
	end if
