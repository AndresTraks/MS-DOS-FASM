
if SEGSEL = S_PRINTF_CODE

;ASSUME CS:PRINTF_CODE,DS:PRINTF_CODE,ES:PRINTF_CODE,SS:PRINTF_CODE

FarSW	 EQU   0	   ;CALL parser by near call
DateSW	 EQU   0	   ;NO date checking code
TimeSW	 EQU   0	   ;NO time checking code
FileSW	 EQU   1	   ;have to check for font file name
CAPSW	 EQU   0	   ;don't have to display file names
CmpxSW	 EQU   1	   ;have complex list in codepage syntax
DrvSW	 EQU   0	   ;just a drive is never legal
QusSW	 EQU   0	   ;quoted string is not legal
NumSW	 EQU   1	   ;need to check a numeric value occaisionally
KeySW	 EQU   1	   ;oodles of keywords to check
SwSW	 EQU   1	   ;/status
Val1SW	 EQU   1	   ;handle numeric ranges
Val2SW	 EQU   1	   ;handle list of numbers
Val3SW	 EQU   1	   ;handle list of strings
BaseSW	 EQU   1	   ;use DS addressability for PSDATA.INC variables
;IncSW	  EQU	1

include 'PARSE.ASM'

;PUBLIC	 SYSPARSE

end if

;END
