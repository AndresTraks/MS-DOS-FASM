.XLIST
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - - NLS Support - Keyboard Definition File
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBMAC.INC
;; ----------
;;
;; Description:
;; ------------
;;	 Include file containing macros for the Keyboard Definition File.
;;
;; Change History:
;; ---------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dead key flags
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
ACUTE		    =   80H	       ;; NLS_FLAG_1
GRAVE		    =   40H	       ;;
DIARESIS	    =   20H	       ;;
CIRCUMFLEX	    =   10H	       ;;
CEDILLA 	    =   08H	       ;;
TILDE		    =   04H	       ;;
				       ;; NLS_FLAG_2 : nothing defined yet
				       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State IDs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
DEAD_LOWER	    EQU    1	       ;; dead keys on lower shift
DEAD_UPPER	    EQU    2	       ;;
ALPHA_LOWER	    EQU    3	       ;;
ALPHA_UPPER	    EQU    4	       ;;
NON_ALPHA_LOWER     EQU    5	       ;;
NON_ALPHA_UPPER     EQU    6	       ;;
THIRD_SHIFT	    EQU    7	       ;;
ACUTE_LOWER	    EQU    8	       ;;
ACUTE_UPPER	    EQU    9	       ;;
ACUTE_SPACE	    EQU   10	       ;;
GRAVE_LOWER	    EQU   11	       ;;
GRAVE_UPPER	    EQU   12	       ;;
GRAVE_SPACE	    EQU   13	       ;;
DIARESIS_LOWER	    EQU   14	       ;;
DIARESIS_UPPER	    EQU   15	       ;;
DIARESIS_SPACE	    EQU   16	       ;;
CIRCUMFLEX_LOWER    EQU   17	       ;;
CIRCUMFLEX_UPPER    EQU   18	       ;;
CIRCUMFLEX_SPACE    EQU   19	       ;;
CEDILLA_LOWER	    EQU   20	       ;;
CEDILLA_UPPER	    EQU   21	       ;;
CEDILLA_SPACE	    EQU   22	       ;;
CEDILLA_CEDILLA     EQU   23	       ;;
DEAD_THIRD	    EQU   24	       ;;
ACUTE_ACUTE	    EQU   25	       ;;
GRAVE_GRAVE	    EQU   26	       ;;
DIARESIS_DIARESIS   EQU   27	       ;;
CIRCUMFLEX_CIRCUMFLEX EQU 28	       ;;
FOURTH_SHIFT	    EQU   29	       ;;
DEAD_FOURTH	    EQU   30	       ;;
TILDE_LOWER	    EQU   31	       ;;
TILDE_UPPER	    EQU   32	       ;;
TILDE_SPACE	    EQU   33	       ;;
ALT_CASE	    EQU   34	       ;;
CTRL_CASE	    EQU   35	       ;;
NUMERIC_PAD	    EQU   36	       ;;
DIVIDE_SIGN	    EQU   37	       ;;
BOTLH_CAPS	    EQU   38	       ;;
BOTRH_CAPS	    EQU   39	       ;;
BOTLH_F_CAPS	    EQU   40	       ;;
BOTRH_F_CAPS	    EQU   41	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Logic Macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;

UNKNOWN = 255

macro FIND_FLAG FLAG_MASK
{
       define idn$keybmac1 idn$no
       match =SCAN_MATCH, FLAG_MASK \{ define idn$keybmac1 idn$yes \}
       match =idn$yes, idn$keybmac1 \{
	  FLAG_ID = EXT_KB_FLAG_ID
       \}
       match =idn$no, idn$keybmac1 \{
       define idn$keybmac2 idn$no
       match =EITHER_SHIFT, FLAG_MASK \\{ define idn$keybmac2 idn$yes \\}
       match =idn$yes, idn$keybmac2 \\{
	  FLAG_ID = EXT_KB_FLAG_ID
       \\}
       match =idn$no, idn$keybmac2 \\{
       define idn$keybmac3 idn$no
       match =CAPS_STATE, FLAG_MASK \\\{ define idn$keybmac3 idn$yes \\\}
       match =idn$yes, idn$keybmac3 \\\{
	  FLAG_ID = KB_FLAG_ID
       \\\}
       match =idn$no, idn$keybmac3 \\\{
       define idn$keybmac4 idn$no
       match =NUM_STATE, FLAG_MASK \\\\{ define idn$keybmac4 idn$yes \\\\}
       match =idn$yes, idn$keybmac4 \\\\{
	  FLAG_ID = KB_FLAG_ID
       \\\\}
       match =idn$no, idn$keybmac4 \\\\{
       define idn$keybmac5 idn$no
       match =EITHER_CTL, FLAG_MASK \\\\\{ define idn$keybmac5 idn$yes \\\\\}
       match =idn$yes, idn$keybmac5 \\\\\{
	  FLAG_ID = EXT_KB_FLAG_ID
       \\\\\}
       match =idn$no, idn$keybmac5 \\\\\{
       define idn$keybmac6 idn$no
       match =EITHER_ALT, FLAG_MASK \\\\\\{ define idn$keybmac6 idn$yes \\\\\\}
       match =idn$yes, idn$keybmac6 \\\\\\{
	  FLAG_ID = EXT_KB_FLAG_ID
       \\\\\\}
       match =idn$no, idn$keybmac6 \\\\\\{
       define idn$keybmac7 idn$no
       match =LEFT_SHIFT, FLAG_MASK \\\\\\\{ define idn$keybmac7 idn$yes \\\\\\\}
       match =idn$yes, idn$keybmac7 \\\\\\\{
	  FLAG_ID = KB_FLAG_ID
       \\\\\\\}
       match =idn$no, idn$keybmac7 \\\\\\\{
       define idn$keybmac8 idn$no
       match =RIGHT_SHIFT, FLAG_MASK \\\\\\\\{ define idn$keybmac8 idn$yes \\\\\\\\}
       match =idn$yes, idn$keybmac8 \\\\\\\\{
	  FLAG_ID = KB_FLAG_ID
       \\\\\\\\}
       match =idn$no, idn$keybmac8 \\\\\\\\{
       define idn$keybmac9 idn$no
       match =ALT_SHIFT, FLAG_MASK \\\\\\\\\{ define idn$keybmac9 idn$yes \\\\\\\\\}
       match =idn$yes, idn$keybmac9 \\\\\\\\\{
	  FLAG_ID = KB_FLAG_ID
       \\\\\\\\\}
       match =idn$no, idn$keybmac9 \\\\\\\\\{
       define idn$keybmac10 idn$no
       match =CTL_SHIFT, FLAG_MASK \\\\\\\\\\{ define idn$keybmac10 idn$yes \\\\\\\\\\}
       match =idn$yes, idn$keybmac10 \\\\\\\\\\{
	  FLAG_ID = KB_FLAG_ID
       \\\\\\\\\\}
       match =idn$no, idn$keybmac10 \\\\\\\\\\{
       define idn$keybmac11 idn$no
       match =R_ALT_SHIFT, FLAG_MASK \\\\\\\\\\\{ define idn$keybmac11 idn$yes \\\\\\\\\\\}
       match =idn$yes, idn$keybmac11 \\\\\\\\\\\{
	  FLAG_ID = KB_FLAG_3_ID
       \\\\\\\\\\\}
       match =idn$no, idn$keybmac11 \\\\\\\\\\\{
       define idn$keybmac12 idn$no
       match =R_CTL_SHIFT, FLAG_MASK \\\\\\\\\\\\{ define idn$keybmac12 idn$yes \\\\\\\\\\\\}
       match =idn$yes, idn$keybmac12 \\\\\\\\\\\\{
	  FLAG_ID = KB_FLAG_3_ID
       \\\\\\\\\\\\}
       match =idn$no, idn$keybmac12 \\\\\\\\\\\\{
       define idn$keybmac13 idn$no
       match =TILDE, FLAG_MASK \\\\\\\\\\\\\{ define idn$keybmac13 idn$yes \\\\\\\\\\\\\}
       match =idn$yes, idn$keybmac13 \\\\\\\\\\\\\{
	  FLAG_ID = NLS_FLAG_1_ID
       \\\\\\\\\\\\\}
       match =idn$no, idn$keybmac13 \\\\\\\\\\\\\{
       define idn$keybmac14 idn$no
       match =ACUTE, FLAG_MASK \\\\\\\\\\\\\\{ define idn$keybmac14 idn$yes \\\\\\\\\\\\\\}
       match =idn$yes, idn$keybmac14 \\\\\\\\\\\\\\{
	  FLAG_ID = NLS_FLAG_1_ID
       \\\\\\\\\\\\\\}
       match =idn$no, idn$keybmac14 \\\\\\\\\\\\\\{
       define idn$keybmac15 idn$no
       match =GRAVE, FLAG_MASK \\\\\\\\\\\\\\\{ define idn$keybmac15 idn$yes \\\\\\\\\\\\\\\}
       match =idn$yes, idn$keybmac15 \\\\\\\\\\\\\\\{
	  FLAG_ID = NLS_FLAG_1_ID
       \\\\\\\\\\\\\\\}
       match =idn$no, idn$keybmac15 \\\\\\\\\\\\\\\{
       define idn$keybmac16 idn$no
       match =DIARESIS, FLAG_MASK \\\\\\\\\\\\\\\\{ define idn$keybmac16 idn$yes \\\\\\\\\\\\\\\\}
       match =idn$yes, idn$keybmac16 \\\\\\\\\\\\\\\\{
	  FLAG_ID = NLS_FLAG_1_ID
       \\\\\\\\\\\\\\\\}
       match =idn$no, idn$keybmac16 \\\\\\\\\\\\\\\\{
       define idn$keybmac17 idn$no
       match =CEDILLA, FLAG_MASK \\\\\\\\\\\\\\\\\{ define idn$keybmac17 idn$yes \\\\\\\\\\\\\\\\\}
       match =idn$yes, idn$keybmac17 \\\\\\\\\\\\\\\\\{
	  FLAG_ID = NLS_FLAG_1_ID
       \\\\\\\\\\\\\\\\\}
       match =idn$no, idn$keybmac17 \\\\\\\\\\\\\\\\\{
       define idn$keybmac18 idn$no
       match =CIRCUMFLEX, FLAG_MASK \\\\\\\\\\\\\\\\\\{ define idn$keybmac18 idn$yes \\\\\\\\\\\\\\\\\\}
       match =idn$yes, idn$keybmac18 \\\\\\\\\\\\\\\\\\{
	  FLAG_ID = NLS_FLAG_1_ID
       \\\\\\\\\\\\\\\\\\}
       match =idn$no, idn$keybmac18 \\\\\\\\\\\\\\\\\\{
       define idn$keybmac19 idn$no
       match =LC_E0, FLAG_MASK \\\\\\\\\\\\\\\\\\\{ define idn$keybmac19 idn$yes \\\\\\\\\\\\\\\\\\\}
       match =idn$yes, idn$keybmac19 \\\\\\\\\\\\\\\\\\\{
	  FLAG_ID = KB_FLAG_3_ID
       \\\\\\\\\\\\\\\\\\\}
       match =idn$no, idn$keybmac19 \\\\\\\\\\\\\\\\\\\{
	  FLAG_ID = UNKNOWN
       \\\\\\\\\\\\\\\\\\\}
       \\\\\\\\\\\\\\\\\\}
       \\\\\\\\\\\\\\\\\}
       \\\\\\\\\\\\\\\\}
       \\\\\\\\\\\\\\\}
       \\\\\\\\\\\\\\}
       \\\\\\\\\\\\\}
       \\\\\\\\\\\\}
       \\\\\\\\\\\}
       \\\\\\\\\\}
       \\\\\\\\\}
       \\\\\\\\}
       \\\\\\\}
       \\\\\\}
       \\\\\}
       \\\\}
       \\\}
       \\}
       \}
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro FLAG FLAG_MASK
{
       FIND_FLAG FLAG_MASK
       IF (FLAG_ID = UNKNOWN)
;	  IF2
;	      %OUT Unknown parameter FLAG_MASK on FLAG MACRO
;	  ENDIF
       ELSE
	  DB FLAG_ID
	  DB FLAG_MASK
       end if
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro IFF FLAG_MASK,MASK_TYPE
{
    MAC_OK = 1
    match , MASK_TYPE \{
	 NOT_BIT = 00000000B
    \}
    match any$, MASK_TYPE \{
	 define idn$keybmac20 idn$no
	 match =NOT, MASK_TYPE \\{ define idn$keybmac20 idn$yes \\}
	 match =idn$yes, idn$keybmac20 \\{
	     NOT_BIT = 00001000B
	 \\}
	 match =idn$no, idn$keybmac20 \\{
	     MAC_OK = 0
;	     IF2
;		 %OUT Unknown parameter MASK_TYPE on IFF MACRO
;	     ENDIF
	 \\}
    \}
    IF MAC_OK
       FIND_FLAG FLAG_MASK
       IF (FLAG_ID = UNKNOWN)
;	  IF2
;	      %OUT Unknown parameter FLAG_MASK on IFF MACRO
;	  ENDIF
       ELSE
	  DB IFF_COMMAND+NOT_BIT+FLAG_ID
	  DB FLAG_MASK
       end if
    end if
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro IFKBD SYS
{
       DB IFKBD_COMMAND
       DW SYS
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro ANDF FLAG_MASK,MASK_TYPE
{
    MAC_OK = 1
    match , MASK_TYPE \{
	 NOT_BIT = 00000000B
    \}
    match any$, MASK_TYPE \{
	 define idn$keybmac21 idn$no
	 match =NOT, MASK_TYPE \\{ define idn$keybmac21 idn$yes \\}
	 match =idn$yes, idn$keybmac21 \\{
	     NOT_BIT = 00001000B
	 \\}
	 match =idn$no, idn$keybmac21 \\{
	     MAC_OK = 0
;	     IF2
;		 %OUT Unknown parameter MASK_TYPE on ANDF MACRO
;	     ENDIF
	 \\}
    \}
    IF MAC_OK
       FIND_FLAG FLAG_MASK
       IF (FLAG_ID = UNKNOWN)
;	  IF2
;	      %OUT Unknown parameter FLAG_MASK on ANDF MACRO
;	  ENDIF
       ELSE
	  DB ANDF_COMMAND+NOT_BIT+FLAG_ID
	  DB FLAG_MASK
       end if
    end if
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro ELSEF 
{
       DB  ELSEF_COMMAND
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro ENDIFF 
{
       DB  ENDIFF_COMMAND
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro XLATT STATE
{
       DB  XLATT_COMMAND
       DB  STATE
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro PUT_ERROR_CHAR STATE
{
       DB  PUT_ERROR_COMMAND
       DB  STATE
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro OPTION MASK,MASK_TYPE
{
    MAC_OK = 1
    match , MASK_TYPE \{
	 NOT_BIT = 00000000B
    \}
    match any$, MASK_TYPE \{
	 define idn$keybmac22 idn$no
	 match =NOT, MASK_TYPE \\{ define idn$keybmac22 idn$yes \\}
	 match =idn$yes, idn$keybmac22 \\{
	     NOT_BIT = 00001000B
	 \\}
	 match =idn$no, idn$keybmac22 \\{
	     MAC_OK = 0
;	     IF2
;		 %OUT Unknown parameter MASK_TYPE on OPTION MACRO
;	     ENDIF
	 \\}
    \}
    IF MAC_OK
       DB  OPTION_COMMAND+NOT_BIT
       DB  MASK
    end if
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro SET_FLAG STATE
{
       DB  SET_FLAG_COMMAND
       DB  STATE
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro RESET_NLS 
{
       DB  RESET_NLS_COMMAND
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro BEEP 
{
       DB  BEEP_COMMAND
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro GOTO GOTO_OFFSET
{
       DB  GOTO_COMMAND
       DW  GOTO_OFFSET-$-2
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro EXIT_INT_9 
{
       DB  GOTO_COMMAND+EXIT_INT_9_FLAG
       DW  0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro EXIT_STATE_LOGIC 
{
       DB  GOTO_COMMAND+EXIT_STATE_LOGIC_FLAG
       DW  0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro CHECK_FOR_CORE_KEY 
{
       DB  CHECK_CORE_COMMAND
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.LIST
