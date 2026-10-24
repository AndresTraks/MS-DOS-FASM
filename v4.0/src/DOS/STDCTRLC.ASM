;	SCCSID = @(#)stdctrlc.asm	1.1 85/04/10
;
; ^C and error handler for MSDOS
;

;.xlist
;.xcref
INCLUDE 'STDSW.ASM'
;.cref
;.list

TITLE   Control C detection, Hard error and EXIT routines
NAME    STDCTRLC

INCLUDE 'CTRLC.ASM'
