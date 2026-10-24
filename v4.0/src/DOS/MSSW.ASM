;	SCCSID = @(#)ibmsw.asm	1.1 85/04/10

INCLUDE '../INC/VERSION.INC'

IBM		EQU	IBMVER
WANG		EQU	FALSE

; Set this switch to cause DOS to move itself to the end of memory
HIGHMEM EQU	FALSE

; Turn on switch below to allow testing disk code with DEBUG. It sets
; up a different stack for disk I/O (functions > 11) than that used for
; character I/O which effectively makes the DOS re-entrant.

	if	IBM
ESCCH	EQU	0			; character to begin escape seq.
CANCEL	EQU	27			;Cancel with escape
TOGLPRN EQU	TRUE			;One key toggles printer echo
ZEROEXT EQU	TRUE
	else
ESCCH	EQU	1BH
CANCEL	EQU	"X"-"@" 		;Cancel with Ctrl-X
TOGLPRN EQU	FALSE			;Separate keys for printer echo on
					;and off
ZEROEXT EQU	TRUE
	end if
