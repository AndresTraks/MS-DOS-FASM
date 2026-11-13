STRUC KEYBSYS_HEADER KH_MAX_COM_SZ_=0, KH_MAX_SPEC_SZ_=0, KH_MAX_LOGIC_SZ_=0, KH_RESV_2_=0, KH_NUM_ID_=0, KH_NUM_LANG_=0, KH_LANG_PTRS_=0
{
				       ;;
.KH_SIGNATURE	DB   0FFh,'KEYB   '    ;; signature
.KH_RESV_1	DB   8 DUP(0)	       ;; reserved
.KH_MAX_COM_SZ	DW   KH_MAX_COM_SZ_ ;AN000;**chg  ;; maximum size of Common Xlat Sect
.KH_MAX_SPEC_SZ	DW   KH_MAX_SPEC_SZ_ ;AN000;;**chg   ;; max size of Specific Xlat Sect
.KH_MAX_LOGIC_SZ DW   KH_MAX_LOGIC_SZ_ ;AN000;;**chg   ;; max size of State Logic
.KH_RESV_2	Dw   KH_RESV_2_ ;AN000;;**chg   ;; reserved CNS
.KH_NUM_ID	Dw   KH_NUM_ID_ ;AN000;;; ************* CNS
.KH_NUM_LANG	DW   KH_NUM_LANG_ ;; number of languages
.KH_LANG_PTRS	DB   KH_LANG_PTRS_ ;; language pointers start here
;********************* CNS **********************
;KH_NUM_ID	  DW   0		 ;; number of languages
;KH_ID_PTRS	  DB   0		 ;; id pointers start here
;********************* CNS **********************
}
match =KEYBSYS_HEADER_LAID_OUT, KEYBSYS_HEADER_LAID_OUT
{
    KEYBSYS_HEADER_LAID_OUT equ 1
    virtual at 0
      KEYBSYS_HEADER KEYBSYS_HEADER 0, 0, 0, 0, 0, 0, 0
      sizeof.KEYBSYS_HEADER = $ - KEYBSYS_HEADER
    end virtual
}
STRUC KEYBSYS_ID_PTRS KP_ID_CODE_=0, KP_LANG_PTR_=0
{

.KP_ID_CODE	DW   KP_ID_CODE_ ;AN000;
.KP_LANG_PTR	DD   KP_LANG_PTR_ ;AN000;

}
match =KEYBSYS_ID_PTRS_LAID_OUT, KEYBSYS_ID_PTRS_LAID_OUT
{
    KEYBSYS_ID_PTRS_LAID_OUT equ 1
    virtual at 0
      KEYBSYS_ID_PTRS KEYBSYS_ID_PTRS 0, 0
      sizeof.KEYBSYS_ID_PTRS = $ - KEYBSYS_ID_PTRS
    end virtual
}
STRUC KEYBSYS_LANG_PTRS KP_LANG_CODE_=0, KP_ENTRY_PTR_=0
{
				       ;; Next two entries repeat:
.KP_LANG_CODE	DW   KP_LANG_CODE_ ;;   language code
.KP_ENTRY_PTR	DD   KP_ENTRY_PTR_ ;;   language entry pointer
				       ;;
}
match =KEYBSYS_LANG_PTRS_LAID_OUT, KEYBSYS_LANG_PTRS_LAID_OUT
{
    KEYBSYS_LANG_PTRS_LAID_OUT equ 1
    virtual at 0
      KEYBSYS_LANG_PTRS KEYBSYS_LANG_PTRS 0, 0
      sizeof.KEYBSYS_LANG_PTRS = $ - KEYBSYS_LANG_PTRS
    end virtual
}
STRUC KEYBSYS_LANG_ENTRY KL_LANG_CODE_='XX', KL_ID_CODE_=0, KL_LOGIC_PTR_=0, KL_NUM_ID_=0, KL_NUM_CP_=0, KL_CP_PTRS_=0
{
				       ;;
.KL_LANG_CODE	DW   KL_LANG_CODE_ ;; language code
.KL_ID_CODE	DW   KL_ID_CODE_ ;; reserved (ID CODE)
.KL_LOGIC_PTR	DD   KL_LOGIC_PTR_ ;AC000;;**chg  ;; State Logic pointer
.KL_NUM_ID	DB   KL_NUM_ID_ ;AN000;;CNS    ;; number of valid IDs for this lang
.KL_NUM_CP	DB   KL_NUM_CP_ ;; number of valid CPs for this lang
.KL_CP_PTRS	DB   KL_CP_PTRS_ ;; CP table pointers start here
				       ;;
}
match =KEYBSYS_LANG_ENTRY_LAID_OUT, KEYBSYS_LANG_ENTRY_LAID_OUT
{
    KEYBSYS_LANG_ENTRY_LAID_OUT equ 1
    virtual at 0
      KEYBSYS_LANG_ENTRY KEYBSYS_LANG_ENTRY 'XX', 0, 0, 0, 0, 0
      sizeof.KEYBSYS_LANG_ENTRY = $ - KEYBSYS_LANG_ENTRY
    end virtual
}
STRUC KEYBSYS_CP_PTRS KC_CODE_PAGE_=0, KC_ENTRY_PTR_=0
{
				       ;; Next two entries repeat:
.KC_CODE_PAGE	DW   KC_CODE_PAGE_ ;;  code page
.KC_ENTRY_PTR	DD   KC_ENTRY_PTR_ ;; ptr to Specific Translate Section
				       ;;
}
match =KEYBSYS_CP_PTRS_LAID_OUT, KEYBSYS_CP_PTRS_LAID_OUT
{
    KEYBSYS_CP_PTRS_LAID_OUT equ 1
    virtual at 0
      KEYBSYS_CP_PTRS KEYBSYS_CP_PTRS 0, 0
      sizeof.KEYBSYS_CP_PTRS = $ - KEYBSYS_CP_PTRS
    end virtual
}
STRUC KEYBSYS_STATE_LOGIC KT_LOGIC_LEN_=0, KT_SPECIAL_FEATURES_=0, KT_LOGIC_CMDS_=0
{
				       ;;
.KT_LOGIC_LEN	DW   KT_LOGIC_LEN_ ;; length of state logic
.KT_SPECIAL_FEATURES  DW  KT_SPECIAL_FEATURES_ ;; Special Features (see KEYBSHAR.INC)
.KT_LOGIC_CMDS	DB   KT_LOGIC_CMDS_ ;; state logic commands begin here
				       ;;
}
match =KEYBSYS_STATE_LOGIC_LAID_OUT, KEYBSYS_STATE_LOGIC_LAID_OUT
{
    KEYBSYS_STATE_LOGIC_LAID_OUT equ 1
    virtual at 0
      KEYBSYS_STATE_LOGIC KEYBSYS_STATE_LOGIC 0, 0, 0
      sizeof.KEYBSYS_STATE_LOGIC = $ - KEYBSYS_STATE_LOGIC
    end virtual
}
STRUC KEYBSYS_XLAT_SECT KX_SECTION_LEN_=0, KX_CP_ID_=0, KX_FIRST_STATE_=0
{
				       ;;
.KX_SECTION_LEN	 DW    KX_SECTION_LEN_ ;; Length of this section
.KX_CP_ID	 DW    KX_CP_ID_ ;; code page id
.KX_FIRST_STATE	 DB    KX_FIRST_STATE_ ;;
				       ;;
}
match =KEYBSYS_XLAT_SECT_LAID_OUT, KEYBSYS_XLAT_SECT_LAID_OUT
{
    KEYBSYS_XLAT_SECT_LAID_OUT equ 1
    virtual at 0
      KEYBSYS_XLAT_SECT KEYBSYS_XLAT_SECT 0, 0, 0
      sizeof.KEYBSYS_XLAT_SECT = $ - KEYBSYS_XLAT_SECT
    end virtual
}
STRUC KEYBSYS_STATE KX_STATE_LEN_=0, KX_STATE_ID_=0, KX_KBD_TYPE_=0, KX_ERROR_CHAR_=0, KX_FIRST_XLAT_=0
{
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     ;; Translate Sections contains multiple States.
	     ;; A State contains the translate tables for a single
	     ;; shift state (IE lower case, upper case ....)
	     ;; The last State is a null State containing only the
	     ;; KX_STATE_LEN field with a value of 0.
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.KX_STATE_LEN	 DW    KX_STATE_LEN_ ;; length of state section
.KX_STATE_ID	 DB    KX_STATE_ID_ ;; State ID
.KX_KBD_TYPE	 DW    KX_KBD_TYPE_ ;; Keyboard Type
.KX_ERROR_CHAR	 DW    KX_ERROR_CHAR_ ;; Buffer entry for error character
.KX_FIRST_XLAT	 DB    KX_FIRST_XLAT_ ;; XLAT tables begin here
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     ;; Each State consists of multiple translate tables.
	     ;; The last translate table within a state is a null
	     ;; table containing only the
	     ;; KX_XLAT_LEN field with a value of 0.
	     ;; Refer to KEYBSHAR.INC for translate table format.
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
}
match =KEYBSYS_STATE_LAID_OUT, KEYBSYS_STATE_LAID_OUT
{
    KEYBSYS_STATE_LAID_OUT equ 1
    virtual at 0
      KEYBSYS_STATE KEYBSYS_STATE 0, 0, 0, 0, 0
      sizeof.KEYBSYS_STATE = $ - KEYBSYS_STATE
    end virtual
}
.XLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBSYS.INC
;; ----------
;;
;; Root File Name:  KEYB.ASM
;; ---------------
;;
;; Description:
;; ------------
;;	 Include file containing structure definitions and equates
;;	 for the KEYBOARD.SYS file.
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; File header - contains pointers to keyboard tables for each language
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;******************CNS*******************
				       ;;
;*****************CNS********************
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Language Entry - pointed to by KH_ENTRY_PTR in KEYBSYS_HEADER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
				       ;;
				       ;;
;; Everything from here down is new
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State Logic - pointed to by KL_LOGIC_PTR in KEYBSYS_LANG_ENTRY
;; Common Translate Section follows immediately after the State Logic.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Translate Section - Common and Specific Translate Sections
;; are both in this form.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.LIST

