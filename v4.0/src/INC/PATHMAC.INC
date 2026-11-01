;;***********************************************************************
;; NAME: pathlabl
;; DESC: creates a public label at the spot it is placed, using the name
;;       given.
;; INPUT: either module name or procedure name
;; OUTPUT: public label
;; LOGIC: LBL-parameter-name will have four values -
;;            - one for each pass (2)
;;            - one for start and one for stop
;;        if LBL is not defined, it is first pass, at beginning label
;;              - set it to 1 and create the start label
;;        if LBL = 1, it is first pass, at end label
;;              - set it to 2 and create stop label
;;        if LBL = 2, it is second pass, at beginning label
;;              - set it to 3 and create the start label
;;        if LBL = 3, it is second pass, at end label
;;              - set it to 4 and create stop label
;;        if LBL = 4, it is second pass,
;;              - this macro has been invoked more than twice with same parm
;;              - issue error message
;;***********************************************************************
;IF1
;    %OUT COMPONENT=COMMON, MODULE=PATHMAC.INC ...
;ENDIF

; The two labels this made, $$A_START_<name> and $$A_STOP_<name>, were
; public symbols for PATHGEN to find a module's extent by in the link map.
; They are the only thing the macro wrote, nothing in a program refers to
; them, and they lay down no bytes, so here the name stands for nothing.
; The switch below counted the four readings MASM gave it, two per pass.
; MASM did not mind the case and fasm does: every module writes PATHLABL,
; so that is the name here, where the release wrote pathlabl.
macro PATHLABL pnam
{
}
;pathlabl MACRO pnam
;IFNDEF LBL_&pnam                        ;;IF THIS IS THE FIRST TIME,
;    LBL_&pnam = 0                       ;;DEFINE IT, INITIALLY ZERO
;ELSE                                    ;;SINCE IT IS DEFINED
;    IF (LBL_&pnam GT 3)                 ;;IF USED TOO MANY TIMES,
;        .ERR NON-UNIQUE OPERAND ON PATHLABL
;        EXITM                           ;;ABORT THIS GENERATION
;    ENDIF
;ENDIF
;
;IF (LBL_&pnam EQ 0) OR (LBL_&pnam EQ 2) ;;ready for START?
;    $$A_START_&pnam:                    ;;create START label
;    PUBLIC $$A_START_&pnam              ;;make it public
;ELSE                                    ;;SINCE SWITCH MAY BE 1 OR 3,
;    $$A_STOP_&pnam:                     ;;create STOP label
;    PUBLIC $$A_STOP_&pnam               ;;make it public
;ENDIF
;LBL_&pnam = LBL_&pnam + 1               ;;INCREMENT SWITCH
;ENDM
