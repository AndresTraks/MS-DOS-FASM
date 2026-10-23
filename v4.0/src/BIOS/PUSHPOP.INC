;	IF1								  ;3.30

; ?stackdepth is the count these keep, and nothing in the release defines
; it before the first SaveReg adds to it, so it starts here.
?stackdepth = 0

; Both are called with the register list in angle brackets -- SaveReg <AX,ES>
; -- which fasm reads as one argument holding the lot, the same as MASM did,
; so IRP takes it apart inside.  Nothing in the BIOS calls either of these;
; SYSCONF.ASM does.
macro SaveReg	reglist 		;; push those registers
{
    irp reg, reglist \{
	?stackdepth = ?stackdepth + 1
	PUSH	reg \}
}
;.xcref	SaveReg


macro RestoreReg   reglist		;; pop those registers
{
    irp reg, reglist \{
	?stackdepth = ?stackdepth - 1
	POP	reg \}
}
;.xcref	RestoreReg

; The modules call these SAVEREG and SaveReg both, one name to MASM, so
; the other spelling stands as a name for the same macro.
macro SAVEREG reglist
{
	SaveReg <reglist>
}
macro RESTOREREG reglist
{
	RestoreReg <reglist>
}

;	ENDIF								  ;3.30
