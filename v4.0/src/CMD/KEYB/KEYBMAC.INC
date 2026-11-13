.XLIST
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - Keyboard Definition File
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBMAC.INC
;; ----------
;;
;; Description:
;; ------------
;;       Include file containing macros for the Keyboard Definition File.
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
ACUTE               EQU   80H          ;; NLS_FLAG_1
GRAVE               EQU   40H          ;;
DIARESIS            EQU   20H          ;;
CIRCUMFLEX          EQU   10H          ;;
CEDILLA             EQU   08H          ;;
TILDE               EQU   04H          ;;
                                       ;; NLS_FLAG_2 : nothing defined yet
                                       ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State IDs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;
DEAD_LOWER          EQU    1           ;; dead keys on lower shift
DEAD_UPPER          EQU    2           ;;
ALPHA_LOWER         EQU    3           ;;
ALPHA_UPPER         EQU    4           ;;
NON_ALPHA_LOWER     EQU    5           ;;
NON_ALPHA_UPPER     EQU    6           ;;
THIRD_SHIFT         EQU    7           ;;
ACUTE_LOWER         EQU    8           ;;
ACUTE_UPPER         EQU    9           ;;
ACUTE_SPACE         EQU   10           ;;
GRAVE_LOWER         EQU   11           ;;
GRAVE_UPPER         EQU   12           ;;
GRAVE_SPACE         EQU   13           ;;
DIARESIS_LOWER      EQU   14           ;;
DIARESIS_UPPER      EQU   15           ;;
DIARESIS_SPACE      EQU   16           ;;
CIRCUMFLEX_LOWER    EQU   17           ;;
CIRCUMFLEX_UPPER    EQU   18           ;;
CIRCUMFLEX_SPACE    EQU   19           ;;
CEDILLA_LOWER       EQU   20           ;;
CEDILLA_UPPER       EQU   21           ;;
CEDILLA_SPACE       EQU   22           ;;
CEDILLA_CEDILLA     EQU   23           ;;
DEAD_THIRD          EQU   24           ;;
ACUTE_ACUTE         EQU   25           ;;
GRAVE_GRAVE         EQU   26           ;;
DIARESIS_DIARESIS   EQU   27           ;;
CIRCUMFLEX_CIRCUMFLEX EQU 28           ;;
FOURTH_SHIFT        EQU   29           ;;
DEAD_FOURTH         EQU   30           ;;
TILDE_LOWER         EQU   31           ;;
TILDE_UPPER         EQU   32           ;;
TILDE_SPACE         EQU   33           ;;
ALT_CASE            EQU   34           ;;
CTRL_CASE           EQU   35           ;;
NUMERIC_PAD         EQU   36           ;;
DIVIDE_SIGN         EQU   37           ;;
                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Logic Macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                       ;;

UNKNOWN = 255

macro FIND_FLAG FLAG_MASK
{
       match =SCAN_MATCH, FLAG_MASK \{
          FLAG_ID = EXT_KB_FLAG_ID
       ELSE
       match =EITHER_SHIFT, FLAG_MASK \\{
          FLAG_ID = EXT_KB_FLAG_ID
       ELSE
       match =CAPS_STATE, FLAG_MASK \\\{
          FLAG_ID = KB_FLAG_ID
       ELSE
       match =NUM_STATE, FLAG_MASK \\\\{
          FLAG_ID = KB_FLAG_ID
       ELSE
       match =EITHER_CTL, FLAG_MASK \\\\\{
          FLAG_ID = EXT_KB_FLAG_ID
       ELSE
       match =EITHER_ALT, FLAG_MASK \\\\\\{
          FLAG_ID = EXT_KB_FLAG_ID
       ELSE
       match =LEFT_SHIFT, FLAG_MASK \\\\\\\{
          FLAG_ID = KB_FLAG_ID
       ELSE
       match =RIGHT_SHIFT, FLAG_MASK \\\\\\\\{
          FLAG_ID = KB_FLAG_ID
       ELSE
       match =ALT_SHIFT, FLAG_MASK \\\\\\\\\{
          FLAG_ID = KB_FLAG_ID
       ELSE
       match =CTL_SHIFT, FLAG_MASK \\\\\\\\\\{
          FLAG_ID = KB_FLAG_ID
       ELSE
       match =R_ALT_SHIFT, FLAG_MASK \\\\\\\\\\\{
          FLAG_ID = KB_FLAG_3_ID
       ELSE
       match =R_CTL_SHIFT, FLAG_MASK \\\\\\\\\\\\{
          FLAG_ID = KB_FLAG_3_ID
       ELSE
       match =TILDE, FLAG_MASK \\\\\\\\\\\\\{
          FLAG_ID = NLS_FLAG_1_ID
       ELSE
       match =ACUTE, FLAG_MASK \\\\\\\\\\\\\\{
          FLAG_ID = NLS_FLAG_1_ID
       ELSE
       match =GRAVE, FLAG_MASK \\\\\\\\\\\\\\\{
          FLAG_ID = NLS_FLAG_1_ID
       ELSE
       match =DIARESIS, FLAG_MASK \\\\\\\\\\\\\\\\{
          FLAG_ID = NLS_FLAG_1_ID
       ELSE
       match =CEDILLA, FLAG_MASK \\\\\\\\\\\\\\\\\{
          FLAG_ID = NLS_FLAG_1_ID
       ELSE
       match =CIRCUMFLEX, FLAG_MASK \\\\\\\\\\\\\\\\\\{
          FLAG_ID = NLS_FLAG_1_ID
       ELSE
       match =LC_E0, FLAG_MASK \\\\\\\\\\\\\\\\\\\{
          FLAG_ID = KB_FLAG_3_ID
       ELSE
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
       IF (FLAG_ID EQ UNKNOWN)
          IF2
;              %OUT Unknown parameter FLAG_MASK on FLAG MACRO
          end if
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
         match =NOT, MASK_TYPE \\{
             NOT_BIT = 00001000B
         ELSE
             MAC_OK = 0
             IF2
;                 %OUT Unknown parameter MASK_TYPE on IFF MACRO
             \\}
         \}
    end if
    IF MAC_OK
       FIND_FLAG FLAG_MASK
       IF (FLAG_ID EQ UNKNOWN)
          IF2
;              %OUT Unknown parameter FLAG_MASK on IFF MACRO
          end if
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
         match =NOT, MASK_TYPE \\{
             NOT_BIT = 00001000B
         ELSE
             MAC_OK = 0
             IF2
;                 %OUT Unknown parameter MASK_TYPE on ANDF MACRO
             \\}
         \}
    end if
    IF MAC_OK
       FIND_FLAG FLAG_MASK
       IF (FLAG_ID EQ UNKNOWN)
          IF2
;              %OUT Unknown parameter FLAG_MASK on ANDF MACRO
          end if
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
         match =NOT, MASK_TYPE \\{
             NOT_BIT = 00001000B
         ELSE
             MAC_OK = 0
             IF2
;                 %OUT Unknown parameter MASK_TYPE on OPTION MACRO
             \\}
         \}
    end if
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
