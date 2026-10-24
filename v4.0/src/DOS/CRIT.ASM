;	SCCSID = @(#)crit.asm	1.1 85/04/10
TITLE CRIT - Critical Section Routines
NAME  CRIT
;
; Critical Section Routines
;
;   Critical section handlers
;
;   Modification history:
;
;       Created: ARR 30 March 1983
;

;.xlist
;
; get the appropriate segment definitions
;
INCLUDE '../INC/DOSSEG.ASM'

if SEGSEL = S_CODE
;	ASSUME  SS:NOTHING,CS:DOSGROUP

;.xcref
INCLUDE '../INC/DOSSYM.INC'
;.cref
;.list

	I_need  USER_IN_AX,WORD
	i_need  CurrentPDB,WORD
if debug
	I_need  BugLev,WORD
	I_need  BugTyp,WORD
INCLUDE '../INC/BUGTYP.ASM'
end if

Break   <Critical section handlers>

;
;   Each handler must leave everything untouched; including flags!
;
;   Sleaze for time savings:  first instruction is a return.  This is patched
;   by the sharer to be a PUSH AX to complete the correct routines.
;
Procedure   EcritDisk,NEAR
;	public  EcritMem
;	public  EcritSFT
EcritMem:
EcritSFT:
	RET
;       PUSH    AX
	fmt     TypSect,LevReq,<"PDB x$ entering x$">,<CurrentPDB,sect>
	MOV     AX,8000h+critDisk
	INT     int_IBM
	POP     AX
	return
EndProc EcritDisk

Procedure   LcritDisk,NEAR
;	public  LcritMem
;	public  LcritSFT
LcritMem:
LcritSFT:
	RET
;       PUSH    AX
	fmt     TypSect,LevReq,<"PDB x$ entering x$">,<CurrentPDB,sect>
	MOV     AX,8100h+critDisk
	INT     int_IBM
	POP     AX
	return
EndProc LcritDisk

Procedure   EcritDevice,NEAR
	RET
;       PUSH    AX
	fmt     TypSect,LevReq,<"PDB x$ entering x$">,<CurrentPDB,sect>
	MOV     AX,8000h+critDevice
	INT     int_IBM
	POP     AX
	return
EndProc EcritDevice

Procedure   LcritDevice,NEAR
	RET
;       PUSH    AX
	MOV     AX,8100h+critDevice
	INT     int_IBM
	POP     AX
	return
EndProc LcritDevice

end if
;    END
