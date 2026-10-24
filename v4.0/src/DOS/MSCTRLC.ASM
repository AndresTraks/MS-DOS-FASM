;	SCCSID = @(#)ibmctrlc.asm	1.1 85/04/10
;
; ^C and error handler for MSDOS
;

;.xlist
;.xcref
INCLUDE 'MSSW.ASM'
;.cref
;.list

TITLE	Control C detection, Hard error and EXIT routines
NAME	IBMCTRLC

INCLUDE 'CTRLC.ASM'
