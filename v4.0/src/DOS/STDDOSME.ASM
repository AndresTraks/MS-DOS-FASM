;	SCCSID = @(#)stddosmes.as	1.2 85/10/07
;	SCCSID = @(#)stddosmes.as	1.2 85/10/07
;
; Standard device IO for MSDOS (first 12 function calls)
;

;.xlist
;.xcref
INCLUDE 'STDSW.ASM'
INCLUDE '../INC/DOSSEG.ASM'
;.cref
;.list

debug=0

TITLE   STDDOSMES - DOS OEM dependancies
NAME    STDDOSMES

INCLUDE 'DOSMES.ASM'
