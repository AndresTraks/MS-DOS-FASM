;	SCCSID = @(#)shrprint.asm	1.1 85/04/10
TITLE	SHRPRINT - PRINTF at SHARE level
NAME	SHRPRINT
;
;
;   Modification history:
;
;	Created: MZ 16 June 1984
;

;.xlist
;
; get the appropriate segment definitions
;
INCLUDE '../INC/DOSSEG.ASM'

if SEGSEL = S_SHARE
;	ASSUME	SS:DOSGROUP,CS:SHARE

;.xcref
INCLUDE '../INC/DOSSYM.INC'
INCLUDE '../INC/DEVSYM.INC'
;.cref
;.list
;.sall

	I_Need	Proc_ID,WORD
	I_Need	User_ID,WORD

BREAK	<debugging output>

INCLUDE 'PRINT.ASM'

end if
;END
