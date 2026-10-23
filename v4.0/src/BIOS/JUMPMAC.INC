						  ;;Rev 3.30 Modification
;
; given a label <lbl> either 2 byte jump to another label <lbl>_J
; if it is near enough or 3 byte jump to <lbl>
;
; The macro below was redefined, right where it stood, to always take the
; three-byte near jump, and that redefinition is what every module got -- so
; it is the only one converted here.  The original is left as it was: it kept
; a <lbl>_J copy of each label it had already jumped to and took the two-byte
; jump when one was within reach, which is work fasm does by itself.
;
;jump	macro lbl
;	local a
;.xcref
;
;	ifndef lbl&_j			;; is this the first invocation
;a:
;				JMP lbl
;	ELSE
;	    IF (lbl&_J GE $) OR ($-lbl&_J GT 126)
;a:
;				JMP lbl ;; is the jump too far away?
;	    ELSE
;a:
;			       JMP lbl&_J  ;; do the short one...
;	    ENDIF
;	ENDIF
;lbl&_j = a
;.cref
;	endm
;.xcref	jump
;REDEFINE THE ABOVE MACRO TO ALWAYS TRY A 3 BYTE NEAR JUMP
macro JUMP LBL								 ;
{
					JMP LBL 			 ;
}					;;End of Modification

; The modules call it JUMP, jump and Jump, all three being the same name to
; MASM.  fasm tells them apart, so the other two spellings are defined as
; well rather than rewritten at four dozen call sites.
macro jump LBL
{
	JUMP	LBL
}
macro Jump LBL
{
	JUMP	LBL
}
