;	SCCSID = @(#)ibmdosmes.asm	1.1 85/04/10
;
; Standard device IO for MSDOS (first 12 function calls)
;
debug=0
;.xlist
;.xcref
INCLUDE '../DOS/MSSW.ASM'
INCLUDE 'DOSSEG.ASM'
;.cref
;.list

TITLE   IBMDOSMES - DOS OEM dependancies
NAME    IBMDOSMES

INCLUDE '../DOS/DOSMES.ASM'
