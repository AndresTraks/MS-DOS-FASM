BADDOS equ 1
ALLINS equ 2
FNF    equ 3
FLAG1  equ (Left_Align+Char_Field_ASCIIZ)

;*****************************************************************************
;******************************************************************************
;		VALUES FOR THE MSG_DESC CONTROL BLOCK
ONE_SUBS       EQU   1		   ;ONE VARIABLE FIELD IN MESSAGE
TWO_SUBS       EQU   2		   ;TWO VARIABLE FIELDS IN MESSAGE
THREE_SUBS     EQU   3		   ;THREE VARIABLE FIELDS IN MESSAGE
CLASS_1        EQU   EXT_ERR_CLASS ;CLASS 1 (DOS EXTENDED ERRORS)
CLASS_2        EQU   PARSE_ERR_CLASS ;CLASS 2 (PARSE ERRORS)
CLASS_A        EQU   UTILITY_MSG_CLASS ;CLASS A TYPE MESSAGE

;THIS MESSAGE DESCRIPTOR CONTROL BLOCK IS GENERATED, ONE PER MESSAGE,
;TO DEFINE THE SEVERAL PARAMETERS THAT ARE EXPECTED TO BE PASSED IN
;CERTAIN REGISTERS WHEN THE SYSDISPMSG FUNCTION IS TO BE INVOKED.

;MSG_DESC	   STRUC
;MSG_NUM	   DW	 0	    ;MESSAGE NUMBER (TO AX)
;MSG_HAND	   DW	 0	     ;HANDLE OF OUTPUT DEVICE (TO BX)
;MSG_SUBLIST	   Dd	 0	    ;POINTER TO SUBLIST (TO SI)
;MSG_COUNT	   DW	 0	    ;SUBSTITUTION COUNT (TO CX)
;MSG_CLASS	   DB	 0	    ;MESSAGE CLASS (IN HIGH BYTE, TO DH)
;				    ; LOW BYTE HAS 0 (FUNCTION "NO INPUT", TO DL)
;MSG_DESC	   ENDS
;		VALUES FOR THE SUBLIST CONTROL BLOCK
PC_ID_0        EQU   0		   ;ID OF " - " TRAILER TO MESSAGE
PC_ID_1        EQU   1		   ;ID OF PERCENT VARIABLE FIELD
PC_ID_2        EQU   2		   ;ID OF PERCENT VARIABLE FIELD
PC_ID_3        EQU   3		   ;ID OF PERCENT VARIABLE FIELD
MAX_0	       EQU   0		   ;MAXIMUM WIDTH OF STRING FIELD (0=NO LIMIT)
MIN_1	       EQU   1		   ;MINIMUM WIDTH OF STRING FIELD
ID_0	       EQU   0

;Message PARM LIST Structure
label PARMLIST1 byte      ;PARM LIST
       ;(File not found - 'PATH_SPEC')
       DB  11	      ;PARMLIST size
       DB  0	      ;reserved
       dw PATH_SPEC
	dw NLS_DATA_
       DB  ID_0       ;; n of %n
       DB  FLAG1      ;; data type
       DB  MAX_0      ;;max width
       DB  MIN_1      ;;min width
       DB  PAD_CHAR   ;;char defined to be space


label PARMLIST2 byte      ;PARM LIST
       ;(NLSFUNC already installed)
       DB  11	      ;PARMLIST size
       DB  0	      ;reserved
       dw UTILITY    ;; ptr to data
	dw NLS_DATA_
       DB  1	      ;; n of %n
       DB  FLAG1      ;; data type
       DB  0	      ;;max width
       DB  1	      ;;min width
       DB  PAD_CHAR   ;;char defined

label PARMLIST3 byte      ;PARM LIST
       ;(Invalid parameter 'PATH_SPEC')
       DB  11	      ;PARMLIST size
       DB  0	      ;reserved
       dw PATH_SPEC   ;; ptr to data
	dw NLS_DATA_
       DB  ID_0       ;; n of %n
       DB  FLAG1      ;; data type
       DB  0	      ;;max width
       DB  1	      ;;min width
       DB  PAD_CHAR   ;;char defined

;		THE NEXT GROUP ARE ALL CLASS "1" MESSAGES

;		PUBLIC MSGNUM_EXTERR
;MSGNUeM_EXTERR  MSG_DESC <FNF,STDERR,,,CLASS_1> ;ALL EXTENDED DOS ERRORS
				   ;File not found - %0

;		THE NEXT GROUP ARE ALL CLASS "2" MESSAGES

;		PUBLIC MSGNUM_PARSE ;SO PARSE DRIVER CAN FIND IT
;MSGNUM_PARSE	MSG_DESC <,STDERR,,,CLASS_2> ;ALL PARSING ERRORS BUT INVALID
						;SYNTAX
				   ;ERROR NUMBER WILL NEED TO BE FILLED IN

;		THE NEXT GROUP ARE ALL CLASS "A" MESSAGES
;		THESE ARE THE "CANNED" MESSAGES ALWAYS PRESENT

;		PUBLIC MSGNUM_VER
;MSGNUM_VER	MSG_DESC <1,STDERR> ;"Incorrect DOS Version"

;		PUBLIC MSGNUM_INST
;MSGNUM_INST	MSG_DESC <ALLINS,STDERR> ;"%1 - already installed"
;end of MSGHAN.INC
