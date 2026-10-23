;	IF1								  ;3.30

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

;	ENDIF								  ;3.30
