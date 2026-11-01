;***********************************************************************
; NAME: pathlabl
; DESC: creates a public label at the spot it is placed, using the name
;       given.
; INPUT: either module name or procedure name
; OUTPUT: public label
;***********************************************************************

; The two labels this made, $$A_START_<name> and $$A_STOP_<name>, were
; public symbols for PATHGEN to find a module's extent by in the link map.
; They are the only thing the macro wrote, nothing in a program refers to
; them, and they lay down no bytes, so here the name stands for nothing.
; IF1 asked whether this was MASM's first pass, so that the second would not
; lay the labels down again; fasm reads the source once.
;
; This is RECOVER's own copy of the macro, an older one than INC/PATHMAC.INC
; holds, and the modules write the name in lower case.
macro pathlabl pnam
{
}

; The release's text, which MASM read:
;
;
;;***********************************************************************
;; NAME: pathlabl
;; DESC: creates a public label at the spot it is placed, using the name
;;       given.
;; INPUT: either module name or procedure name
;; OUTPUT: public label
;; LOGIC: if masm is in pass1 (pass2 will gen dup labels)
;;           if this label has not been gen before
;;              then create the label
;;                   - $$A to place at begin of map
;;                   - start means first occurence
;;                   - use module/proc name last
;;                   define this label for creation of 'stop' label
;;              else create stop label
;;                   - same as start except name
;;***********************************************************************
;.LALL
;pathlabl MACRO pnam
;IF1                                     ;if pass 1
;    IFNDEF LBL_&pnam                    ;switch not defined if first creation
;        $$A_START_&pnam:                ;create label
;        PUBLIC $$A_START_&pnam          ;make it public
;        LBL_&pnam = 1                   ;set switch
;    ELSE                                ;start label already created
;        $$A_STOP_&pnam:                 ;create stop label
;        PUBLIC $$A_STOP_&pnam           ;make it public
;    ENDIF
;ENDIF
;ENDM
;
;
