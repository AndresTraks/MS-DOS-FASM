;	SCCSID = @(#)stdcpmio.asm	1.1 85/04/10
;
; Standard device IO for MSDOS (first 12 function calls)
;

;.xlist
;.xcref
INCLUDE 'STDSW.ASM'
INCLUDE '../INC/DOSSEG.ASM'
;.cref
;.list

TITLE   STDCPMIO - device IO for MSDOS
NAME    STDCPMIO

INCLUDE 'CPMIO.ASM'
