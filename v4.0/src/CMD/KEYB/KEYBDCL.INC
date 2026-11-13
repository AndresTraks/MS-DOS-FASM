STRUC PARM_LIST RET_CODE_1_=0, RET_CODE_2_=0, RET_CODE_3_=0, RET_CODE_4_=0, LANGUAGE_PARM_=0, CODE_PAGE_PARM_=0, PATH_OFFSET_=0, PATH_LENGTH_=0, ID_PARM_=0
{
;*******************CNS******************
;*******************CNS******************
    .RET_CODE_1	    DB	 RET_CODE_1_ ;;  \
    .RET_CODE_2	    DB	 RET_CODE_2_ ;;  |
    .RET_CODE_3	    DB	 RET_CODE_3_ ;;  |
;*******************CNS******************
    .RET_CODE_4	    DB	 RET_CODE_4_ ;;  |;AN000;
;*******************CNS******************
    .LANGUAGE_PARM   DW	 LANGUAGE_PARM_ ;;   }  PARAMETER
    .CODE_PAGE_PARM  DW	 CODE_PAGE_PARM_ ;;  |	    LIST
    .PATH_OFFSET     DW	 PATH_OFFSET_ ;;  |
    .PATH_LENGTH     DW	 PATH_LENGTH_ ;;  /
;*******************CNS******************
    .ID_PARM	    DW	 ID_PARM_ ;AN000;
;*******************CNS******************
}
match =PARM_LIST_LAID_OUT, PARM_LIST_LAID_OUT
{
    PARM_LIST_LAID_OUT equ 1
    virtual at 0
      PARM_LIST PARM_LIST 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.PARM_LIST = $ - PARM_LIST
    end virtual
}
STRUC DESIG_CP_STRUC NUM_DESIGNATES_=0, NUM_FONTS_=0, NUM_HW_CPS_=0, DESIG_CP_ENTRY_=0
{
    .NUM_DESIGNATES  DW	 NUM_DESIGNATES_ ;;
    .NUM_FONTS	    DW	 NUM_FONTS_ ;;
    .NUM_HW_CPS	    DW	 NUM_HW_CPS_ ;;
    .DESIG_CP_ENTRY  DW	 DESIG_CP_ENTRY_ ;;
}
match =DESIG_CP_STRUC_LAID_OUT, DESIG_CP_STRUC_LAID_OUT
{
    DESIG_CP_STRUC_LAID_OUT equ 1
    virtual at 0
      DESIG_CP_STRUC DESIG_CP_STRUC 0, 0, 0, 0
      sizeof.DESIG_CP_STRUC = $ - DESIG_CP_STRUC
    end virtual
}

.XLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBDCL.INC
;; ----------
;;
;; Root File Name:  KEYB.ASM
;; ---------------
;;
;; Description:
;; ------------
;;	 Common declarations for structures in procedures for KEYB.COM
;;
;; Change History:
;; ---------------
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.LIST

