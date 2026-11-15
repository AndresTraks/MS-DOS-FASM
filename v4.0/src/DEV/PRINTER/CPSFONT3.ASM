
	PAGE	,132

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  FILENAME:	  CPS Device Driver -- Font Parser
;;  MODULE NAME:  CPSFONT
;;  TYPE:	  Font Parser Module
;;  LINK PROCEDURE:  Link CPS+CPSSUB+CPSINT9+...+CPSINIT into .EXE format
;;		     CPS must be first.  CPSINIT must be last.	Everything
;;		     before CPSINIT will be resident.
;;  INCLUDE FILES:
;;			CPSPEQU.INC
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
include 'CPSPEQU.INC' ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
;CSEG	SEGMENT PUBLIC 'CODE'           ;;
;	ASSUME	CS:CSEG 		;;
;	ASSUME	DS:NOTHING		;;
					;;
;PUBLIC	FTABLE,FONT_PARSER		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  ************************************
;;  **				      **
;;  **	     Resident Code	      **
;;  **				      **
;;  ************************************
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	FONT_PARSER data
;;
;;	-- Interface table : FTABLE
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FTABLE  FBUFS 0FFFFH,,,    ;; for temporary testing
FTB1	FTBLK                 ;; -- at most 12 entries
FTB2	FTBLK                 ;;
FTB3	FTBLK                 ;;
FTB4	FTBLK                 ;;
FTB5	FTBLK                 ;;
FTB6	FTBLK                 ;;
FTB7	FTBLK                 ;;
FTB8	FTBLK                 ;;
FTB9	FTBLK                 ;;
FTBa	FTBLK                 ;;
FTBb	FTBLK                 ;;
FTBc	FTBLK                 ;;
					;;
FP_ERROR	DW   0000H		;; internal error register
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; the followings are bytes accumulated
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FTAG_LEN	EQU	8		;; FILE TAGE in the font file header
FTAG_COUNT	DW	0000H		;;
					;;
label FTAG_PATTERN byte  ;;
	DB	0FFH			;;
	DB	'FONT   '               ;;
					;;
					;;
					;; POINTER in the font file header
label fptr_LOW word   ;;
fptr_LOL DB	00H			;; NEXT
fptr_LOH DB	00H			;;
label fptr_HIGH word   ;;
fptr_HIL DB	00H			;;
fptr_HIH DB	00H			;;
					;;
					;;
					;;
label ENTRY_WORD word   ;;
ENTRY_LOB DB	00H			;; ENTRY COUNT
ENTRY_HIB DB	00H			;;
label NEXT_LOW word   ;;
NEXT_LOL DB	00H			;; NEXT
NEXT_LOH DB	00H			;;
label NEXT_HIGH word   ;;
NEXT_HIL DB	00H			;;
NEXT_HIH DB	00H			;;
label TYPE_WORD word   ;;
TYPE_LOB DB	00H			;; TYPE
TYPE_HIB DB	00H			;;
TID_CNT DW	00000H			;; TYPEID COUNT(0 to 8)
TYPE_ID :	DB '        '           ;; TYPEID
label CPG_WORD word   ;;
CPG_LOB DB	00H			;; CODE PAGE
CPG_HIB DB	00H			;;
label FONT_LOW word   ;;
FONT_LOL DB	00H			;; FONT ADDRESS
FONT_LOH DB	00H			;;
label FONT_HIGH word   ;;
FONT_HIL DB	00H			;;
FONT_HIH DB	00H			;;
;; the followings are contained in the font-block in the exact order & length
label MOD_WORD word   ;;
MOD_LOB DB	00H			;; MODIFIER
MOD_HIB DB	00H			;;
label FONTS_WORD word   ;;
FONTS_LOB DB	00H			;; FONTS
FONTS_HIB DB	00H			;;
label FDLEN_WORD word   ;;
FDLEN_LOB DB	00H			;; FONT DATA LENGTH
FDLEN_HIB DB	00H			;;
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
PRE_FONT_ND	= (($-MOD_WORD))	;; used to update target for font data
					;; to follow. -- for NON-DISPLAY
DISP_ROWS DB	00H			;; DISPLAY's parameters :
DISP_COLS DB	00H			;; BOX SIZE
DISP_X	  DB	00H			;; ASPECT RATIO
DISP_Y	  DB	00H			;;
label COUNT_WORD word     ;; NO. OF DISPLAY CHARACTERS
COUNT_LOB DB	00H			;;
COUNT_HIB DB	00H			;;
PRE_FONT_D	= (($-MOD_WORD))	;; used to update target for font data
					;; to follow. -- for DISPLAY
					;;
label PTR_SEL_WORD word  ;;
PTR_SELOB DB	00H			;;
PTR_SEHIB DB	00H			;;
PRE_FONT_P0	= (($-PTR_SELOB+PRE_FONT_ND))	;; to update target for font data
					;; to follow -- for PRINTER with
					;; selection type = 0.
					;;
label PTR_LEN_WORD word  ;;
PTR_LNLOB DB	00H			;;
PTR_LNHIB DB	00H			;;
PRE_FONT_P	= (($-PTR_SELOB+PRE_FONT_ND))	;; to update target for font data
					;; to follow -- for PRINTER with
					;; selection type <> 0.
					;;
					;;
;; also update STAGE_CASES and indexing constants
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; the stage the parsing is in :  ;;;;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
label STAGE_CASES word   ;; the stage the parsing is in :
					;;
					;; *** INDEXED BY  STAGE-INDEX
					;;
	DW	ENTRYLO         ;; 0
	DW	ENTRYHI         ;; 1
	DW	NEXTLOL         ;; 2
	DW	NEXTLOH         ;; 3
	DW	NEXTHIL         ;; 4
	DW	NEXTHIH         ;; 5
	DW	TYPELO         ;; 6
	DW	TYPEHI         ;; 7
	DW	TYPEIDS         ;; 8
	DW	CPGLO         ;; 9
	DW	CPGHI         ;; A
	DW	FONTLOL         ;; B
	DW	FONTLOH         ;; C
	DW	FONTHIL         ;; D
	DW	FONTHIH         ;; E
	DW	00H			;; MATCH case -- end of SEARCH stages
	DW	00H			;; SCAN  case -- before PRE-FOUND stage
	DW	MODLO         ;; 11
	DW	MODHI         ;; 12
	DW	FONTSLO         ;; 13
	DW	FONTSHI         ;; 14
	DW	FDLENLO         ;; 15
	DW	FDLENHI         ;; 16 -- lead to FONT case,NON- DISPLAY
	DW	DSPROWS         ;; 17 -- DISPLAY only
	DW	DSPCOLS         ;; 18
	DW	DSPX         ;; 19
	DW	DSPY         ;; 1A
	DW	DSPCOUNTLO        ;; 1B
	DW	DSPCOUNTHI        ;; 1C -- lead to FONT case, DISPLAY
	DW	PTRSELLO               ;;  1D -- PRINTER only
	DW	PTRSELHI               ;;  1E
	DW	PTRLENLO               ;;  1F
	DW	PTRLENHI               ;;  20 -- lead to FONT case, PRINTER
	DW	00H			;; FOUND    case
	DW	00H			;; GET_FONT case
	DW	00H			;; PASS special stage
	DW	filetag         ;; 24
	DW	fptrLOL         ;; 25
	DW	fptrLOH         ;; 26
	DW	fptrHIL         ;; 27
	DW	fptrHIH         ;; 28
	DW	00H			;; FPTR_SKIP_CASE
					;;
					;; The followings are individual stage
STAGE_MAX =	(($-STAGE_CASES)/2)	;;  number of stages
					;;
					;; STAGE-INDEX
					;;
					;; **** INDEX TO STAGE_CASES  ****
ENTRY_LOX EQU	00H			;;
ENTRY_HIX EQU	01H			;;
NEXT_LOLX EQU	02H			;; NEXT
NEXT_LOHX EQU	03H			;;
NEXT_HILX EQU	04H			;;
NEXT_HIHX EQU	05H			;;
TYPE_LOBX EQU	06H			;; TYPE
TYPE_HIBX EQU	07H			;;
TYPE_IDX EQU	08H			;; TYPEID
CPG_LOBX EQU	09H			;; CODE PAGE
CPG_HIBX EQU	0AH			;;
FONT_LOLX EQU	0BH			;; FONT ADDRESS
FONT_LOHX EQU	0CH			;;
FONT_HILX EQU	0DH			;;
FONT_HIHX EQU	0EH			;;
					;; ------------------------------
MATCHX	EQU	0FH			;; MATCH is the end of SEARCH's stages
SCANX	EQU	10H			;; SCANX is before the PRE-FOUND stages
					;; ------------------------------
MOD_LOBX EQU	11H			;; MODIFIER
MOD_HIBX EQU	12H			;;
FONTS_LOBX EQU	13H			;; FONTS
FONTS_HIBX EQU	14H			;;
FDLEN_LOBX EQU	15H			;; FONT DATA LENGTH
FDLEN_HIBX EQU	16H			;;
DISP_ROWSX EQU	17H			;; DISPLAY -- CHAR. SIZE
DISP_COLSX EQU	18H			;;
DISP_XX    EQU	19H			;; DISPLAY -- ASPECT RATIO
DISP_YX    EQU	1AH			;;
COUNT_LOBX EQU	1BH			;; DISPLAY -- COUNT
COUNT_HIBX EQU	1CH			;;
PTRSELLOX  EQU	1DH			;;
PTRSELHIX  EQU	1EH			;;
PTRLENLOX  EQU	1FH			;;
PTRLENHIX  EQU	20H			;;
					;;
					;; ------------------------------
FOUNDX	EQU	21H			;; GET_FX is the end of PRE-FOUND stage
GET_FX	EQU	22H			;;
					;; ------------------------------
PASSX	EQU	23H			;; see pass_brk table
					;; ------------------------------
FTAGX	EQU	24H			;; RESTART ==> FILE TAG
					;;
fptr_LOLX EQU	25H			;; POINTER in font file header
fptr_LOHX EQU	26H			;;
fptr_HILX EQU	27H			;;
fptr_HIHX EQU	28H			;; ---------------------------------
					;;
fptr_SKIPX EQU	29H			;; ==> ENTRY_LOX
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; PASS -- to skip some bytes ;;;;;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; the PASS mechanism is used to skip
					;; a number of bytes between two fields
					;; The numbers are tabulated in
					;; PASS_BRK table in the accumulative
					;; sum. The PASS_POSTX(and PASS_POSTXX)
					;; are used to tell what is the stage
					;; after all the bytes have skipped.
					;;
PASS_POSTX  DW	 STAGE_MAX		;; the stage after pass-stage
					;;
FILE_OFFSET    EQU     0BH	       ;; spaces to be skipped in font file :
					;; ( after TAG, before POINTER)
					;;
PASS_CNT DW	0			;;
label PASS_BRK word   ;;
	DW	FILE_OFFSET		;; skip in the font file header
	DW	FILE_OFFSET+2		;; pass header-length, needs to reset
					;; PASS_CNT for each of the font_header
	DW	FILE_OFFSET+8		;; pass header-reserved bytes
PASS_INDX =	(($-PASS_BRK)/2)	;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; the control variables :  ;;;;;;;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STAGE	DW	STAGE_MAX		;; of the STAGE-INDEX
					;;
Pre_font_len	DW	00000H		;; no. of bytes before the FONT DATA
					;;
					;;
COUNT_LO DW	00000H			;; no. of bytes parsed so far
COUNT_hI DW	00000H			;;
					;;
HIT_LO	DW	00000H			;; the next byte that is addressed by :
HIT_HI	DW	00000H			;; either NEXT or TARGET in FTBLK.
					;;
HIT_FLAG DW	00000H			;; IF ZERO, the NEXT is approaching
HIT_BX	DW	00000H			;; where FTB is found for nearest hit
					;;
NUM_FTB DW	00000H			;; as defined in the FP_BUFFER
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	FONT_PARSER routine
;;
;;	-- to be called at every packet received to extract informations
;;	   from Font File on byte basis.
;;
;;	-- Interface though FTABLE
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
FONT_PARSER:       ;;
	PUSH	DS			;; save all registers Revised
	PUSH	ES			;;
	PUSH	AX			;;
	PUSH	BX			;;
	PUSH	CX			;;
	PUSH	DX			;;
	PUSH	DI			;;
	PUSH	SI			;;
					;; BP isn't used, so it isn't saved
	LEA	BX,[FTABLE];;
	PUSH	CS			;;
	POP	ES			;; ES:[BX]
	LDS	SI,dword [FTP+FBUFS.BUFFER_ADDR] ;; DS:[SI]
	MOV	CX,word [FTP+FBUFS.BUFFER_LEN] ;; CX = length of packet
	MOV	DX,word [FTP+FBUFS.NUM_FTBLK] ;; DX = number of FTB
	MOV	[cs:NUM_FTB],DX   ;;
	AND	DX,DX			;;
	JNZ	VALID_BUFFER		;;
	MOV	word [cs:FP_ERROR],0020H ;; ERROR 0020H
	JMP	FP_RET			;;
VALID_BUFFER :				;;
	MOV	AX,word [FTP+FBUFS.FLAG] ;;
	AND	AX,FLAG_RESTART 	;;
	Jnz	has_restart		;;
	JMP	NO_RESTART		;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
has_restart :				;;
	PUSH	BX			;; reset all the output fields
	ADD	BX,sizeof.FBUFS ;; FTP = FONT BLOCK
	XOR	AX,AX			;;
					;;
	MOV	[cs:FTAG_COUNT],AX  ;;
	MOV	[cs:fptr_LOW],AX   ;;
	MOV	[cs:fptr_HIGH],AX   ;;
	MOV	[cs:Pre_font_len],AX ;;
	MOV	[cs:COUNT_LO],AX   ;;
	MOV	[cs:COUNT_hI],AX   ;;
	MOV	[cs:NEXT_LOW],AX   ;;
	MOV	[cs:NEXT_HIGH],AX   ;;
	MOV	[cs:HIT_LO],AX   ;;
	MOV	[cs:HIT_HI],AX   ;;
	MOV	[cs:HIT_FLAG],AX   ;;
	MOV	[cs:PASS_CNT],AX   ;;
	MOV	word [cs:PASS_POSTX],STAGE_MAX ;;
					;;
	MOV	word [cs:STAGE],STAGE_MAX ;;
					;;
RESET_FTB :				;;
	MOV	word [FTP+FTBLK.FTB_STATUS],FSTAT_SEARCH
	MOV	word [FTP+FTBLK.FTB_TYPE],AX ;;
	MOV	word [FTP+FTBLK.FTB_MOD],AX ;;
	MOV	word [FTP+FTBLK.FTB_FONTS],AX ;;
	MOV	byte [FTP+FTBLK.FTB_ROWS],AL ;;
	MOV	byte [FTP+FTBLK.FTB_COLS],AL ;;
	MOV	byte [FTP+FTBLK.FTB_X],AL ;;
	MOV	byte [FTP+FTBLK.FTB_Y],AL ;;
	MOV	word [FTP+FTBLK.FTB_COUNT],AX ;;
	MOV	word [FTP+FTBLK.FTB_DLEFT],AX ;;
	MOV	word [FTP+FTBLK.FTB_DLEN],AX ;;
	MOV	word [FTP+FTBLK.FTB_DALO],AX ;;
	MOV	word [FTP+FTBLK.FTB_DAHI],AX ;;
	MOV	word [FTP+FTBLK.TARGET_LO],AX ;;
	MOV	word [FTP+FTBLK.TARGET_HI],AX ;;
					;;
	ADD	BX, sizeof.FTBLK ;;
					;;
	DEC	DX			;;
	AND	DX,DX			;;
	JNZ	RESET_FTB		;;
					;;
	POP	BX			;;
NO_RESTART :				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; any FTBLKs have their data all
					;; returned ? if so set their status
					;; from FOUND to COMPLETE
	PUSH	BX			;;
	ADD	BX,sizeof.FBUFS ;; FTP = FONT BLOCK
					;;
	MOV	DX,[cs:NUM_FTB]   ;;
					;;
SET_COMPLETE :				;;
	MOV	AX,word [FTP+FTBLK.FTB_STATUS] ;;
	CMP	AX,FSTAT_FONT		;;
	JNE	SET_NEXT		;;
					;;
	MOV	AX,word [FTP+FTBLK.FTB_DLEFT] ;;
	AND	AX,AX			;;
	JNZ	SET_NEXT		;;
					;;
	MOV	word [FTP+FTBLK.FTB_STATUS],FSTAT_COMPLETE
					;;
SET_NEXT :				;;
					;;
	ADD	BX,sizeof.FTBLK ;;
					;;
	DEC	DX			;;
	AND	DX,DX			;;
	JNZ	SET_COMPLETE		;;
					;;
	POP	BX			;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ADD	BX,sizeof.FBUFS ;; FTP = FONT BLOCK
					;;
	PUSH	CX			;; STACK 1 = CX
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; DO WHILE CX is not zero :
;;
;; -- on each loop, the CX, COUNTs are updated
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
FTB_LOOP :				;;
	POP	AX			;; STACK -1
	SUB	AX,CX			;;
	ADD	[cs:COUNT_LO],AX   ;;
	JNC	NO_CARRY		;;
	ADD	word [cs:COUNT_hI],1000H ;;
NO_CARRY :				;;
	PUSH	CX			;; STACK 1 = CX
	AND	CX,CX			;;
	JNZ	FTB_CONT		;;
	JMP	FTB_LPEND		;;
					;; DO CASES :
FTB_CONT :				;; ==========
					;;
	MOV	AX,[cs:STAGE]   ;;
					;;
	CMP	AX,STAGE_MAX		;;
	JNE	FTB_010 		;;
	JMP	START_CASE		;; ** RESTART **
					;;
FTB_010 :				;;
	CMP	AX,MATCHX		;;
	JAE	FTB_020 		;;
	JMP	SEARCH_CASE		;; ** SEARCH **
					;;
FTB_020 :				;;
	CMP	AX,MATCHX		;;
	JNE	FTB_030 		;;
	JMP	MATCH_CASE		;; ** MATCH **
					;;
FTB_030 :				;;
	CMP	AX,SCANX		;;
	JNE	FTB_040 		;;
	JMP	SCAN_CASE		;; ** SCAN **
					;;
FTB_040 :				;;
	CMP	AX,FOUNDX		;;
	JAE	FTB_050 		;;
	JMP	PRE_FOUND_CASE		;; ** PRE-FOUND **
					;;
FTB_050 :				;;
	CMP	AX,FOUNDX		;;
	JNE	FTB_060 		;;
	JMP	FOUND_CASE		;; ** FOUND  **
					;;
FTB_060 :				;;
	CMP	AX,GET_FX		;;
	JNE	FTB_070 		;;
	JMP	GETFONT_CASE		;; ** GET_FONT **
					;;
FTB_070 :				;;
	CMP	AX,PASSX		;;
	JNE	FTB_080 		;;
	JMP	PASS			;; ** PASS **
					;;
FTB_080 :				;;
	CMP	AX,fptr_SKIPX		;;
	JAE	FTB_090 		;;
	JMP	SEARCH_CASE		;; ** SEARCH **
					;;
FTB_090 :				;;
	CMP	AX,fptr_SKIPX		;;
	JNE	FTB_FFF 		;;
	JMP	FPTR_SKIP_CASE		;; ** SEARCH **
					;;
FTB_FFF :				;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_DEVERR
	JMP	FTB_LPEND		;; ** DEVICE ERROR **
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; at the entry of each STAGES /CASES
;;
;; --	DS:[SI]  (FPKT) points to PACKET, of DOS's buffer
;; --	CX	 remaining packet length
;; --	ES:[BX]  points to the first FTBLK
;; --	COUNT_LO, COUNT_HI, upto but and including the address pointed by FPKT
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
;============================================================================
START_CASE :				;; pass the FILE leading bytes
					;;
	MOV	word [cs:FTAG_COUNT],0 ;;
	MOV	word [cs:STAGE],FTAGX ;;
	JMP	FTB_LOOP		;;
					;;
;=============================================================================
FPTR_SKIP_CASE :			;; skip until the ENTRY pointed by
					;; POINTER (in FPTR) is reached.
					;;
					;; **************
	MOV	AX,[cs:fptr_LOW]   ;; * HIT = FPTR *
	MOV	[cs:HIT_LO],AX   ;; **************
	MOV	DX,[cs:fptr_HIGH]   ;;
	MOV	[cs:HIT_HI],DX   ;;
					;;
	CMP	AX,0FFFFH		;;
	JNE	FPTR_SKIP_VALID 	;;
	CMP	DX,0FFFFH		;;
	JNE	FPTR_SKIP_VALID 	;;
					;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_BADATA ;; returned at the first FTBLK
	JMP	fptr_skip_more		;;
					;;
FPTR_SKIP_VALID :			;;
					;; normalised HIT_HI, HIT_LO
	MOV	AX,DX			;;
	AND	AX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	AX,CL			;;
	POP	CX			;;
	AND	DX,0F000H		;;
	ADD	AX,[cs:HIT_LO]   ;;
	JNC	NO_CARRY10		;;
	ADD	DX,01000H		;;
NO_CARRY10:				;;
	MOV	[cs:HIT_LO],AX   ;;
	MOV	[cs:HIT_HI],DX   ;;
					;; **************************
					;; * compare FPTR and COUNT *
					;; **************************
					;; DX:AX = HIT_HI:HIT_LO (normalised)
					;;
	SUB	AX,[cs:COUNT_LO]   ;;
	Jnc	more_fptrlo		;;
	sub	dx,01000h		;;
	jc	fptr_bad		;;
					;;
more_fptrlo :				;;
	SUB	DX,[cs:COUNT_hI]   ;;
	JC	fptr_bad		;;
					;;
	INC	AX			;; COUNT can be at the HIT, then AX=0
	JNC	NO_CARRY11		;; INC AX to make AX comparable to CX
	ADD	DX,01000H		;; i.e. AX = offset + 1
					;;
NO_CARRY11:				;;
	CMP	AX,CX			;;
	JA	fptr_skip_more		;; AX > CX, whole CX to be skipped
					;;
	PUSH	DX			;;  normalise dx:ax
	AND	DX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	DX,CL			;;
	POP	CX			;;
	ADD	AX,DX			;;
	POP	DX			;;
	JNC	NO_CARRY13		;;
	ADD	DX,01000H		;;
NO_CARRY13:				;;
	AND	DX,0F000H		;;
					;;
	PUSH	AX			;;
	PUSH	DX			;; STACK +1 : normalosed DX:AX
	SUB	AX,CX			;;
	JNC	NO_BORROW11		;;
	SUB	DX,1000H		;;
	JC	fptr_MORE_CXP		;; dx:ax < cx
NO_BORROW11:				;;
					;; dx:ax >= cx
	AND	AX,AX			;;
	JNE	fptr_skip_morep 	;;
	AND	DX,DX			;;
	JNE	fptr_skip_morep 	;;
					;; dx:ax = cx, or
					;; offset + 1 = CX
					;;
					;; ************************************
					;; * POINTER is within the current CX *
					;; ************************************
fptr_MORE_CXP : 			;;
	POP	DX			;;
	POP	AX			;; STACK -1
					;;
fptr_MORE_CX :				;; DX = 0,to have more CX than offset+1
	DEC	AX			;; = offset : 0 and above
	SUB	CX,AX			;;
	ADD	SI,AX			;; where the first byte is
					;;
	MOV	word [cs:STAGE],ENTRY_LOX ;; ENTRIES in the font file
					;;
	JMP	FTB_LOOP		;;  ******  RETURN  *******
					;;
					;; ***********************************
					;; * more to skip ==> FPTR_SKIP_CASE *
					;; ***********************************
fptr_skip_morep:			;;
	POP	DX			;;
	POP	AX			;; STACK -1
					;;
fptr_skip_more :			;;
	ADD	SI,CX			;;
	SUB	CX,CX			;;
	JMP	FTB_LOOP		;; ******  RETURN  *****
					;;
					;; ***********************************
					;; * bad POINTER in font file header *
					;; ***********************************
					;;
fptr_bad :				;;
	MOV	word [cs:fptr_LOW],0FFFFH ;;
	MOV	word [cs:fptr_HIGH],0FFFFH ;;
					;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_BADATA ;; returned at the first FTBLK
					;;
	JMP	fptr_skip_more		;;
					;;
;=============================================================================
SEARCH_CASE :				;;
					;; still looking for header to match
					;; the input : codepage and typeid
					;;
	MOV	DI,[cs:STAGE]   ;;
					;;
	ADD	DI,DI			;; double to index to WORD-offset
					;;
	JMP	[cs:STAGE_CASES+DI] ;; call routine to process the stage
					;;
					;;
;===========================================================================
MATCH_CASE :				;;
					;;
	PUSH	BX			;;
	MOV	DX,[cs:NUM_FTB]   ;;
					;;
					;;
MATCH_LOOP :				;;
	MOV	AX,word [FTP+FTBLK.FTB_STATUS] ;;
	CMP	AX,FSTAT_SEARCH 	;;
	JE	MATCH_SEARCH		;;
	JMP	MATCH_NEXT		;;
					;;
MATCH_SEARCH :				;;
	MOV	AX,word [FTP+FTBLK.FTB_CP] ;; check the FTB with SEARCH status
	CMP	AX,[cs:CPG_WORD]   ;;
	JNE	MATCH_MORE		;;
	PUSH	DS			;; code page matched
	PUSH	SI			;;
	PUSH	CX			;;
					;;
	PUSH	CS			;;
	POP	DS			;;
	MOV	SI,TYPE_ID        ;;
	LEA	DI,[BX+FTBLK.FTB_TID] ;;
	MOV	CX,8			;;
	REPE	CMPSB			;;
					;;
	POP	CX			;;
	POP	SI			;;
	POP	DS			;;
					;;
	JNE	MATCH_MORE		;;
					;; MATCH !!!!!	(type_id matched)
	MOV	word [FTP+FTBLK.FTB_STATUS],FSTAT_MATCH
	MOV	AX,[cs:TYPE_WORD]   ;;
	MOV	word [FTP+FTBLK.FTB_TYPE],AX ;;
	MOV	AX,[cs:FONT_LOW]   ;;
	MOV	word [FTP+FTBLK.TARGET_LO],AX ;;
	MOV	AX,[cs:FONT_HIGH]   ;;
	MOV	word [FTP+FTBLK.TARGET_HI],AX ;;
					;;
	JMP	MATCH_NEXT		;;
					;;
MATCH_MORE :				;; if this is the last rounf ?
					;;
	MOV	AX,[cs:NEXT_LOW]   ;; NEXT = FFFF:FFFF means no more
	CMP	AX,-1			;;	  header to come.
	JNE	MATCH_NEXT		;;
					;;
	MOV	AX,[cs:NEXT_HIGH]   ;;
	CMP	AX,-1			;;
	JNE	MATCH_NEXT		;;
					;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_NOFIND ;; ERROR : no match
					;;
MATCH_NEXT :				;;
	ADD	BX,word [FTP+FTBLK.FTB_LENGTH] ;;
	DEC	DX			;;
	AND	DX,DX			;;
	JZ	MATCH_ALL		;;
	JMP	MATCH_LOOP		;;
					;;
MATCH_ALL :				;;
	MOV	word [cs:STAGE],SCANX ;;
					;;
MATCH_DONE :				;;
	POP	BX			;;
	JMP	FTB_LOOP		;;
					;;
;===========================================================================
SCAN_CASE :				;;
					;; **********************************
					;; * determine whether it the font  *
					;; * data(TARGET),or the next font  *
					;; * header(NEXT) that is approaching
					;; **********************************
					;;
	MOV	AX,[cs:NEXT_LOW]   ;;
	MOV	[cs:HIT_LO],AX   ;;
	MOV	AX,[cs:NEXT_HIGH]   ;;
	MOV	[cs:HIT_HI],AX   ;;
	XOR	AX,AX			;;
	MOV	[cs:HIT_FLAG],AX   ;;
					;;
	MOV	DI,[cs:HIT_HI]   ;; normalised HIT_HI, HIT_LO
	MOV	AX,DI			;;
	AND	AX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	AX,CL			;;
	POP	CX			;;
	AND	DI,0F000H		;;
	ADD	AX,[cs:HIT_LO]   ;;
	JNC	NO_CARRY2		;;
	ADD	DI,01000H		;;
NO_CARRY2 :				;;
	MOV	[cs:HIT_LO],AX   ;;
	MOV	[cs:HIT_HI],DI   ;;
					;;
	MOV	DX,[cs:NUM_FTB]   ;;
					;;
	PUSH	BX			;;
SCAN_LOOP :				;;
	MOV	AX,word [FTP+FTBLK.FTB_STATUS] ;;
	CMP	AX,FSTAT_MATCH		;;
	JNE	SCAN_NEXT		;;
					;;
					;;
	MOV	DI,word [FTP+FTBLK.TARGET_HI] ;; NORMALISED TARGET
	MOV	AX,DI			;;
	AND	AX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	AX,CL			;;
	POP	CX			;;
	AND	DI,0F000H		;;
	ADD	AX,word [FTP+FTBLK.TARGET_LO] ;;
	JNC	NO_CARRY1		;;
	ADD	DI,01000H		;;
NO_CARRY1 :				;; DI:AX = NORMALISED TARGET
					;;
					;; ** compare the TARGET and the NEXT
					;;
	CMP	DI,[cs:HIT_HI]   ;;
	JA	SCAN_NEXT		;;
					;;
	JE	SCAN_EQU		;;
	JMP	NEAR_FONT		;;
					;;
SCAN_EQU :				;;
	CMP	AX,[cs:HIT_LO]   ;;
	JA	SCAN_NEXT		;;
	JE	SCAN_ERROR_CHK		;;
					;; **********************************
					;; * the font data is approaching   *
					;; **********************************
NEAR_FONT :				;;
	MOV	word [cs:HIT_FLAG],-1 ;;
	MOV	[cs:HIT_LO],AX   ;;
	MOV	[cs:HIT_HI],DI   ;;
	MOV	[cs:HIT_BX],BX   ;; used for BAD_BX and in FOUND_CASE
	JMP	SCAN_NEXT		;;
					;;
					;; **********************************
					;; * the NEXT header is approaching *
					;; **********************************
SCAN_ERROR_CHK :			;;
	MOV	AX,[cs:HIT_FLAG]   ;;
	AND	AX,AX			;;
	JNZ	SCAN_NEXT		;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_BADATA ;; next header and font cannot be the
					;; same
					;;
SCAN_NEXT :				;;
	DEC	DX			;;
	AND	DX,DX			;;
	JZ	SCAN_DONE		;;
					;;
	ADD	BX,word [FTP+FTBLK.FTB_LENGTH] ;;
	JMP	SCAN_LOOP		;; ** is there any closer font data ?
					;;
					;; ************************************
					;; * the HIT is either font data(TARGET
					;; * or the font block (NEXT).	      *
					;; ************************************
SCAN_DONE :				;;
	POP	BX			;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	DX,[cs:HIT_HI]   ;; HIT_FLAG, HIT_LO, HIT_HI defined
	MOV	AX,[cs:HIT_LO]   ;;
					;;
	CMP	AX,0FFFFH		;;
	JNE	NOT_FFFF_HIT		;;
	CMP	DX,0FFFFH		;;
	JNE	NOT_FFFF_HIT		;;
	JMP	SCAN_MORE		;; stage remained as SCAN, discard data
					;;
NOT_FFFF_HIT :				;;
					;; DX:AX = HIT_HI:HIT_LO (normalised)
	SUB	AX,[cs:COUNT_LO]   ;;
	JNC	NO_BORROW		;;
	SUB	DX,01000H		;;
	JC	SCAN_BAD		;;
NO_BORROW:				;;
	SUB	DX,[cs:COUNT_hI]   ;;
	JC	SCAN_BAD		;;
					;;
	INC	AX			;; COUNT can be at the HIT, then AX=0
	JNC	NO_CARRYX		;; INC AX to make AX comparable to CX
	ADD	DX,01000H		;; i.e. AX = offset + 1
					;;
NO_CARRYX :				;;
	CMP	AX,CX			;;
	JA	SCAN_MORE		;;
					;;
	PUSH	DX			;;
	AND	DX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	DX,CL			;;
	POP	CX			;;
	ADD	AX,DX			;;
	POP	DX			;;
	JNC	NO_CARRY3		;;
	ADD	DX,01000H		;;
NO_CARRY3 :				;;
	AND	DX,0F000H		;;
					;;
					;;
	PUSH	AX			;;
	PUSH	DX			;;
	SUB	AX,CX			;;
	JNC	NO_BORROW1		;;
	SUB	DX,1000H		;;
	JC	MORE_CXP		;;
NO_BORROW1 :				;;
					;; dx:ax >= cx
	AND	AX,AX			;;
	JNE	SCAN_MOREP		;;
	AND	DX,DX			;;
	JNE	SCAN_MOREP		;;
					;;
					;; offset + 1 = CX
					;;
MORE_CXP :				;;
	POP	DX			;;
	POP	AX			;;
					;;
MORE_CX :				;; DX = 0,to have more CX than offset+1
	DEC	AX			;; = offset : 0 and above
	SUB	CX,AX			;;
	ADD	SI,AX			;; where the first byte is
	MOV	AX,[cs:HIT_FLAG]   ;;
	AND	AX,AX			;;
	JE	NEXT_REACHED		;;
					;;
	MOV	word [cs:STAGE],MOD_LOBX ;; font-data reached,
					;;
	JMP	FTB_LOOP		;;  ****** RETURN   *******
					;;
NEXT_REACHED :				;;
	MOV	word [cs:STAGE],PASSX ;;
	MOV	word [cs:PASS_POSTX],NEXT_LOLX ;;
	MOV	word [cs:PASS_CNT],FILE_OFFSET ;;
					;;
					;;
	JMP	FTB_LOOP		;; ******  RETURN   *******
					;;
					;; ***********************************
SCAN_MOREP :				;; * scan more FTBLK for the nearest *
					;; * font data			     *
					;; ***********************************
	POP	DX			;;
	POP	AX			;;
					;;
SCAN_MORE :				;;
	ADD	SI,CX			;;
	SUB	CX,CX			;;
	JMP	FTB_LOOP		;; more SCAN stage
					;;
SCAN_BAD:				;; *************************
	MOV	AX,[cs:HIT_FLAG]   ;; * scan is bad	      *
	AND	AX,AX			;; *************************
	JNZ	BAD_BX			;;
	MOV	AX,-1			;; NEXT is pointing backwards
	MOV	[cs:NEXT_LOW],AX   ;;
	MOV	[cs:NEXT_HIGH],AX   ;; no more NEXT
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_BADATA ;; returned at the first FTBLK
	JMP	FTB_LOOP		;;
					;;
BAD_BX	:				;;
	PUSH	BX			;; FONT is pointing backwards
	MOV	BX,[cs:HIT_BX]   ;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_BADATA
	POP	BX			;;
	JMP	FTB_LOOP		;;
					;;
;===========================================================================
PRE_FOUND_CASE :			;;
					;; extract informations from the font
					;; block until font_length is defined
					;;
	MOV	DI,[cs:STAGE]   ;;
					;;
	ADD	DI,DI			;; double to index to WORD-offset
					;;
	JMP	[cs:STAGE_CASES+DI] ;; call routine to process the stage
					;;
;===========================================================================
FOUND_CASE :				;;
	MOV	DI,FTB_LOOP        ;; as FOUND has two places to return to
	PUSH	DI			;;
;===========================================================================
FOUND_DO :				;;
					;; define informations into FTBLK of
					;; HIT_BX defined in the SCAN case
	PUSH	BX			;;
	MOV	BX,[cs:HIT_BX]   ;;
					;; FTBLK :
	MOV	AX,[cs:MOD_WORD]   ;;
	MOV	word [FTP+FTBLK.FTB_MOD],AX ;;
	MOV	AX,[cs:FONTS_WORD]  ;;
	MOV	word [FTP+FTBLK.FTB_FONTS],AX ;;
					;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	MOV	word [FTP+FTBLK.FTB_DLEFT],AX ;;
	MOV	word [FTP+FTBLK.FTB_DLEN],0 ;;
	MOV	word [FTP+FTBLK.FTB_DALO],0 ;;
	MOV	word [FTP+FTBLK.FTB_DAHI],0 ;;
					;;
	MOV	word [FTP+FTBLK.FTB_STATUS],FSTAT_FOUND
					;;
	CMP	word [FTP+FTBLK.FTB_TYPE],TYPE_DISPLAY ;
	JNE	CHECK_PTR_TYPE		;;
	CMP	word [cs:Pre_font_len],PRE_FONT_D ;;
	JNE	DISPLAY_BAD		;;
	JMP	DISPLAY_DONE		;;
					;;
CHECK_PTR_TYPE :			;;
	CMP	word [FTP+FTBLK.FTB_TYPE],TYPE_PRINTER ;
	JNE	SET_STAGE		;;
	CMP	word [cs:PTR_SEL_WORD],0 ;;
	JNE	PRINTER_HAS_SEL 	;;
	CMP	word [cs:Pre_font_len],PRE_FONT_P0 ;;
	JNE	PRINTER_BAD		;;
	JMP	PRINTER_DONE		;;
					;;
PRINTER_HAS_SEL :			;;
	CMP	word [cs:Pre_font_len],PRE_FONT_P ;;
	JNE	PRINTER_BAD		;;
	JMP	PRINTER_DONE		;;
					;;
DISPLAY_BAD :				;;
					;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_BADATA ;the FDLEN_WORD should be 0.
					;;
DISPLAY_DONE :				;;
	MOV	AL,[cs:DISP_ROWS]   ;;
	MOV	byte [FTP+FTBLK.FTB_ROWS],AL ;;
	MOV	AL,[cs:DISP_COLS]   ;;
	MOV	byte [FTP+FTBLK.FTB_COLS],AL ;;
	MOV	AL,[cs:DISP_X]   ;;
	MOV	byte [FTP+FTBLK.FTB_X],AL ;;
	MOV	AL,[cs:DISP_Y]   ;;
	MOV	byte [FTP+FTBLK.FTB_Y],AL ;;
	MOV	AX,[cs:COUNT_WORD]  ;;
	MOV	word [FTP+FTBLK.FTB_COUNT],AX ;;
	JMP	SET_STAGE		;;
					;;
PRINTER_BAD :				;;
					;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_BADATA ;the FDLEN_WORD should be 0.
					;;
PRINTER_DONE :				;;
	MOV	AX,[cs:PTR_SEL_WORD]  ;;
	MOV	word [FTP+FTBLK.FTB_SELECT],AX ;;
	MOV	AX,[cs:PTR_LEN_WORD]  ;;
	MOV	word [FTP+FTBLK.FTB_SELLEN],AX ;;
					;;
SET_STAGE :				;; STAGE :
	MOV	AX,[cs:FDLEN_WORD]  ;; if no font data to follow
	AND	AX,AX			;;
	JNZ	GET_FDATA		;;
	MOV	word [cs:STAGE],SCANX ;; then scan for next header or font
	JMP	FONT_RET		;;
					;;
GET_FDATA :				;; update the moving target
	MOV	word [cs:STAGE],GET_FX ;;
	MOV	AX,[cs:Pre_font_len]  ;;
	ADD	word [FTP+FTBLK.TARGET_LO],AX ;;
	JNC	FONT_RET		;;
	ADD	word [FTP+FTBLK.TARGET_HI],01000H ;;
					;;
FONT_RET :				;;
	POP	BX			;;
	RET				;;
					;;
;===========================================================================
GETFONT_CASE :				;; as ES:[SI], at COUNT, there is font
					;; data
	MOV	DX,[cs:NUM_FTB]   ;;
	PUSH	BX			;;
					;;
	MOV	word [cs:HIT_HI],0 ;; temp. register
	MOV	word [cs:HIT_FLAG],0 ;; assumed can be changed to SCAN stage
					;;
	MOV	DI,[cs:COUNT_hI]   ;; normalised COUNT_HI,COUNT_LO
	MOV	AX,DI			;;
	AND	AX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	AX,CL			;;
	POP	CX			;;
	AND	DI,0F000H		;;
	ADD	AX,[cs:COUNT_LO]   ;;
	JNC	NO_CARRY4		;;
	ADD	DI,01000H		;;
NO_CARRY4 :				;;
	MOV	[cs:COUNT_LO],AX   ;;
	MOV	[cs:COUNT_hI],DI   ;;
					;;
					;;
GETFONT_LOOP :				;;
	MOV	AX,word [FTP+FTBLK.FTB_STATUS] ;;
	CMP	AX,FSTAT_FONT		;;
	JE	GETFONT_CONT		;;
					;;
	CMP	AX,FSTAT_FOUND		;;
	JE	GETFONT_FOUND		;;
					;;
	JMP	NEXT_GETFONT		;;
					;;
GETFONT_FOUND : 			;;
	MOV	AX,word [FTP+FTBLK.FTB_DLEFT] ;;
	AND	AX,AX			;;
	JZ	NEXT_GF 		;;
	MOV	word [FTP+FTBLK.FTB_STATUS],FSTAT_FONT ;
	JMP	GETFONT_CONT1		;;
					;;
					;;
GETFONT_CONT :				;;
	MOV	AX,word [FTP+FTBLK.FTB_DLEFT] ;;
	AND	AX,AX			;;
	JNZ	GETFONT_CONT1		;;
NEXT_GF :				;;
	JMP	NEXT_GETFONT		;;
					;; only on FOUND and DLEFT <> 0
GETFONT_CONT1:				;;
	MOV	DI,word [FTP+FTBLK.TARGET_HI] ;; normalised TARGET
	MOV	AX,DI			;;
	AND	AX,00FFFH		;;
	PUSH	CX			;;
	MOV	CX,4			;;
	SHL	AX,CL			;;
	POP	CX			;;
	AND	DI,0F000H		;;
	ADD	AX,word [FTP+FTBLK.TARGET_LO] ;;
	JNC	NO_CARRY5		;;
	ADD	DI,01000H		;;
NO_CARRY5 :				;; DI:AX = TARGET (normalised)
					;;
	CMP	DI,[cs:COUNT_hI]   ;;
	JB	GETFONT_BAD		;;
	JNE	NEXT_GETFONT		;;
	CMP	AX,[cs:COUNT_LO]   ;;
	JB	GETFONT_BAD		;;
	JNE	NEXT_GETFONT		;;
					;;
	MOV	word [FTP+FTBLK.FTB_DALO],SI ;; where the font data is in the packet
	MOV	word [FTP+FTBLK.FTB_DAHI],DS ;;
					;;
	MOV	AX,word [FTP+FTBLK.FTB_DLEFT] ;;
	CMP	AX,CX			;;
	JAE	UPTO_CX 		;;
					;; upto FDLEFT
	MOV	word [FTP+FTBLK.FTB_DLEFT],0 ;;
	MOV	word [FTP+FTBLK.FTB_DLEN],AX ;;
	CMP	[cs:HIT_HI],AX   ;;
	JNB	NOT_HIGHER0		;;
	MOV	[cs:HIT_HI],AX   ;;
NOT_HIGHER0 :				;;
	ADD	word [FTP+FTBLK.TARGET_LO],AX ;;
	JNC	NEXT_GETFONT		;;
	ADD	word [FTP+FTBLK.TARGET_HI],01000H ;;
	JMP	NEXT_GETFONT		;;
					;;
GETFONT_BAD :				;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_BADATA ;; pointing backwards
	JMP	NEXT_GETFONT		;;
					;;
UPTO_CX :				;;
	SUB	AX,CX			;;
	MOV	word [FTP+FTBLK.FTB_DLEFT],AX ;;
	MOV	word [FTP+FTBLK.FTB_DLEN],CX ;;
	MOV	[cs:HIT_HI],CX   ;;
	ADD	word [FTP+FTBLK.TARGET_LO],CX ;;
	JNC	NO_CARRYOVER		;;
	ADD	word [FTP+FTBLK.TARGET_HI],01000H ;;
NO_CARRYOVER :				;;
	AND	AX,AX			;; all data have been returned ?
	JZ	NEXT_GETFONT		;;
					;;
	MOV	word [cs:HIT_FLAG],-1 ;; no ! stay in the GET_FONT stage
					;;
NEXT_GETFONT :				;;
	ADD	BX,word [FTP+FTBLK.FTB_LENGTH] ;;
	DEC	DX			;;
	AND	DX,DX			;;
	JZ	GETFONT_END		;;
	JMP	GETFONT_LOOP		;;
					;;
GETFONT_END :				;;
	MOV	AX,[cs:HIT_HI]   ;;
	ADD	SI,AX			;;
	SUB	CX,AX			;;
					;;
	CMP	word [cs:HIT_FLAG],0 ;;
	Jne	GETFONT_DONE		;;
	MOV	word [cs:STAGE],SCANX ;; no more in the GET_FONT stage
					;;
					;;
GETFONT_DONE :				;;
	POP	BX			;;
	JMP	FTB_LOOP		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; STAGES --  "called by" SERACH_CASE
;;
;; --	DS:[SI]  (FPKT) points to PACKET, of DOS's buffer
;; --	CX	 remaining packet length
;; --	ES:[BX]  points to the first FTBLK
;; --	COUNT_LO, COUNT_HI, upto but not including the address pointed by FPKT
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;+++++++++++++++++++++++++++++++++
filetag :				;;
					;;
;	mov	ax,ftag_len		;;
	cmp	word [cs:FTAG_COUNT],FTAG_LEN ;;
	jB	VALID_FTAG		;;
	JE	FTAG_FAILED		;;
					;;
	mov	word [FTP+FTBLK.FTB_STATUS],STAT_DEVERR
	mov	word [cs:FP_ERROR],00022H ;; ERROR 0022H
					;;
FTAG_FAILED :				;; discard all the bytes, while
	ADD	SI,CX			;; stage stays as FTAGX
	SUB	CX,CX			;;
	JMP	FTB_LOOP		;; **** RETURN (bytes discarded) ****
					;;
VALID_FTAG :				;;
	MOV	AX,[FPKT] ;;
	INC	SI			;;
	DEC	CX			;;
					;;
	MOV	DI,[cs:FTAG_COUNT]  ;;
	CMP	AL,[cs:FTAG_PATTERN+DI]   ;;
	JE	FTAG_NEXTB		;;
					;;
	mov	word [FTP+FTBLK.FTB_STATUS],STAT_BADATA
	MOV	ax,FTAG_LEN		;; stays in FTAGX to consume all bytes
	MOV	[cs:FTAG_COUNT],ax  ;; stays in FTAGX to consume all bytes
	JMP	FTB_LOOP		;; **** RETURN (FAILED !)  ****
					;;
FTAG_NEXTB :				;;
	INC	DI			;;
	MOV	[cs:FTAG_COUNT],DI  ;;
					;;
	CMP	DI,FTAG_LEN		;;
	JE	FTAG_DONE		;;
					;;
	JMP	FTB_LOOP		;; **** RETURN ( MORE TO COME) ****
					;;
FTAG_DONE :				;;
	MOV	word [cs:PASS_CNT],0 ;;
	MOV	word [cs:STAGE],PASSX ;;
	MOV	word [cs:PASS_POSTX],fptr_LOLX ;;
					;;
	JMP	FTB_LOOP		;; **** NEXT STAGE ****
					;;
					;;+++++++++++++++++++++++++++++++++
fptrLOL :				;; STAGE the low byte of the low fptr
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_fptrLO		;;
	MOV	[cs:fptr_LOL],AL   ;;
	MOV	word [cs:STAGE],fptr_LOHX ;;
	JMP	FTB_LOOP		;;
WORD_fptrLO :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:fptr_LOW],AX   ;;
	MOV	word [cs:STAGE],fptr_HILX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
fptrLOH :				;; STAGE the high byte of the low fptr
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:fptr_LOH],AL   ;;
	MOV	word [cs:STAGE],fptr_HILX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
fptrHIL :				;; STAGE the low byte of the high fptr
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_fptrHI		;;
	MOV	[cs:fptr_HIL],AL   ;;
	MOV	word [cs:STAGE],fptr_HIHX ;;
	JMP	FTB_LOOP		;;
WORD_fptrHI :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:fptr_HIGH],AX   ;;
	MOV	word [cs:STAGE],fptr_SKIPX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
fptrHIH :				;; STAGE the high byte of the high fptr
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:fptr_HIH],AL   ;;
	MOV	word [cs:STAGE],fptr_SKIPX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
ENTRYLO :				;; STAGE - ENTRY LOW BYTE
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_ENTRY		;;
	MOV	[cs:ENTRY_LOB],AL   ;;
	MOV	word [cs:STAGE],ENTRY_HIX ;;
	JMP	FTB_LOOP		;;
WORD_ENTRY :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:ENTRY_WORD],AX  ;;
	MOV	word [cs:STAGE],PASSX ;; 2 bytes to be passed
	MOV	word [cs:PASS_POSTX],NEXT_LOLX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
ENTRYHI :				;; stage - ENTRY HIGN BYTE
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:ENTRY_HIB],AL   ;;
	MOV	word [cs:STAGE],PASSX ;; 2 bytes to be passed
	MOV	word [cs:PASS_POSTX],NEXT_LOLX ;;
	AND	CX,CX			;;
	JNZ	ENTHI_PASS1		;;
	JMP	FTB_LOOP		;;
ENTHI_PASS1 :				;;
	INC	SI			;;
	INC	word [cs:PASS_CNT] ;;
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	ENTHI_PASS2		;;
	JMP	FTB_LOOP		;;
ENTHI_PASS2 :				;;
	INC	SI			;;
	INC	word [cs:PASS_CNT] ;;
	DEC	CX			;;
	MOV	word [cs:STAGE],NEXT_LOLX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
NEXTLOL :				;; STAGE the low byte of the low NEXT
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_NEXTLO		;;
	MOV	[cs:NEXT_LOL],AL   ;;
	MOV	word [cs:STAGE],NEXT_LOHX ;;
	JMP	FTB_LOOP		;;
WORD_NEXTLO :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:NEXT_LOW],AX   ;;
	MOV	word [cs:STAGE],NEXT_HILX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
NEXTLOH :				;; STAGE the high byte of the low NEXT
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:NEXT_LOH],AL   ;;
	MOV	word [cs:STAGE],NEXT_HILX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
NEXTHIL :				;; STAGE the low byte of the high NEXT
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_NEXTHI		;;
	MOV	[cs:NEXT_HIL],AL   ;;
	MOV	word [cs:STAGE],NEXT_HIHX ;;
	JMP	FTB_LOOP		;;
WORD_NEXTHI :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:NEXT_HIGH],AX   ;;
	MOV	word [cs:STAGE],TYPE_LOBX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
NEXTHIH :				;; STAGE the high byte of the high NEXT
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:NEXT_HIH],AL   ;;
	MOV	word [cs:STAGE],TYPE_LOBX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
TYPELO	:				;; STAGE the low byte of the TYPE
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_TYPE		;;
	MOV	[cs:TYPE_LOB],AL   ;;
	MOV	word [cs:STAGE],TYPE_HIBX ;;
	JMP	FTB_LOOP		;;
WORD_TYPE :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:TYPE_WORD],AX   ;;
	MOV	word [cs:STAGE],TYPE_IDX ;;
	MOV	word [cs:TID_CNT],0 ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
TYPEHI	:				;; STAGE the high byte of the TYPE
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:TYPE_HIB],AL   ;;
	MOV	word [cs:STAGE],TYPE_IDX ;;
	MOV	word [cs:TID_CNT],0 ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
TYPEIDS :				;; STAGE the type id
	CMP	word [cs:TID_CNT],8 ;;
	JNA	VALID_TID		;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_DEVERR
	MOV	word [cs:FP_ERROR],00021H ;; ERROR 0021H
	ADD	SI,CX			;;
	SUB	CX,CX			;;
	JMP	FTB_LOOP		;;
					;;
VALID_TID :				;;
	MOV	AX,8			;;
	SUB	AX,[cs:TID_CNT]   ;;
	CMP	CX,AX			;;
	JNB	TID_ALL 		;;
					;; all data in FPKT are stored
	PUSH	ES			;;
	PUSH	CS			;;
	POP	ES			;;
					;;
	MOV	DI,TYPE_ID        ;;
	ADD	DI,[cs:TID_CNT]   ;;
	ADD	[cs:TID_CNT],CX   ;;
	REP	MOVSB			;; SI is incremented accordingly
	POP	ES			;;
					;;
	MOV	CX,0			;; STAGE remained
	JMP	FTB_LOOP		;;
TID_ALL :				;;
	PUSH	CX			;;
					;;
	PUSH	ES			;;
	PUSH	CS			;;
	POP	ES			;;
					;;
	MOV	DI,TYPE_ID        ;;
	ADD	DI,[cs:TID_CNT]   ;;
	MOV	CX,AX			;;
	REP	MOVSB			;; SI is incremented accordingly
	POP	ES			;;
					;;
	ADD	[cs:TID_CNT],AX   ;;
	POP	CX			;;
	SUB	CX,AX			;;
					;;
	MOV	word [cs:STAGE],CPG_LOBX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
CPGLO	:				;; STAGE the low byte of the CODE PAGE
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_CPG		;;
	MOV	[cs:CPG_LOB],AL   ;;
	MOV	word [cs:STAGE],CPG_HIBX ;;
	JMP	FTB_LOOP		;;
WORD_CPG :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:CPG_WORD],AX   ;;
	MOV	word [cs:STAGE],PASSX ;;
	MOV	word [cs:PASS_POSTX],FONT_LOLX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
CPGHI	:				;; STAGE the high byte of the CODE PAGE
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:CPG_HIB],AL   ;;
	MOV	word [cs:STAGE],PASSX ;;
	MOV	word [cs:PASS_POSTX],FONT_LOLX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTLOL :				;; STAGE the low byte of the low FONT
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_FONTLO		;;
	MOV	[cs:FONT_LOL],AL   ;;
	MOV	word [cs:STAGE],FONT_LOHX ;;
	JMP	FTB_LOOP		;;
WORD_FONTLO :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:FONT_LOW],AX   ;;
	MOV	word [cs:STAGE],FONT_HILX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTLOH :				;; STAGE the high byte of the low FONT
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:FONT_LOH],AL   ;;
	MOV	word [cs:STAGE],FONT_HILX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTHIL :				;; STAGE the low byte of the high FONT
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_FONTHI		;;
	MOV	[cs:FONT_HIL],AL   ;;
	MOV	word [cs:STAGE],FONT_HIHX ;;
	JMP	FTB_LOOP		;;
WORD_FONTHI :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:FONT_HIGH],AX   ;;
;;;;;;	MOV	cs:stage,MOD_LOBX	   ;; end of SCAN
					;; anymore headers to be processed ?
	MOV	word [cs:STAGE],MATCHX ;;
	MOV	AX,[cs:ENTRY_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:ENTRY_WORD],AX  ;;
	AND	AX,AX			;;
	JNZ	CHECK_NEXT		;;
					;; no more header to be processed !
	MOV	AX,-1			;;
	MOV	[cs:NEXT_LOW],AX   ;;
	MOV	[cs:NEXT_HIGH],AX   ;; as ENTRY has been consumed
	JMP	FTB_LOOP		;;
					;;
CHECK_NEXT :				;;
	MOV	AX,[cs:NEXT_LOW]   ;;
	AND	AX,AX			;;
	JNZ	MORE_HEADER		;;
	MOV	AX,[cs:NEXT_HIGH]   ;;
	AND	AX,AX			;;
	JNZ	MORE_HEADER		;;
					;; no more header to be processed !
	MOV	AX,-1			;;
	MOV	[cs:NEXT_LOW],AX   ;; as NEXT is nil
	MOV	[cs:NEXT_HIGH],AX   ;;
					;;
MORE_HEADER :				;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTHIH :				;; STAGE the high byte of the high FONT
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:FONT_HIH],AL   ;;
;;;;;	MOV	cs:stage,MOD_LOBX	   ;; end of SCAN
					;;
	MOV	word [cs:STAGE],MATCHX ;;
					;; anymore headers to be processed ?
	MOV	AX,[cs:ENTRY_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:ENTRY_WORD],AX  ;;
	AND	AX,AX			;;
	JNZ	CHECK_NEXT0		;;
					;; no more header to be processed !
	MOV	AX,-1			;;
	MOV	[cs:NEXT_LOW],AX   ;;
	MOV	[cs:NEXT_HIGH],AX   ;; as ENTRY has been consumed
	JMP	FTB_LOOP		;;
					;;
CHECK_NEXT0 :				;;
	MOV	AX,[cs:NEXT_LOW]   ;;
	AND	AX,AX			;;
	JNZ	MORE_HEADER0		;;
	MOV	AX,[cs:NEXT_HIGH]   ;;
	AND	AX,AX			;;
	JNZ	MORE_HEADER0		;;
					;; no more header to be processed !
	MOV	AX,-1			;;
	MOV	[cs:NEXT_LOW],AX   ;; as NEXT is nil
	MOV	[cs:NEXT_HIGH],AX   ;;
					;;
MORE_HEADER0 :				;;
	JMP	FTB_LOOP		;;
					;;
					;;+++++++++++++++++++++++++++++++++
MODLO	:				;; STAGE the low byte of the MODIFIER
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_MOD		;;
	MOV	[cs:MOD_LOB],AL ;;
	MOV	word [cs:STAGE],MOD_HIBX ;;
	JMP	FTB_LOOP		;;
WORD_MOD :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:MOD_WORD],AX   ;;
	MOV	word [cs:STAGE],FONTS_LOBX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
MODHI	:				;; STAGE the high byte of the MODIFIER
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:MOD_HIB],AL   ;;
	MOV	word [cs:STAGE],FONTS_LOBX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTSLO :				;; STAGE the low byte of the FONTS
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_FONTS		;;
	MOV	[cs:FONTS_LOB],AL   ;;
	MOV	word [cs:STAGE],FONTS_HIBX ;;
	JMP	FTB_LOOP		;;
WORD_FONTS :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:FONTS_WORD],AX  ;;
	MOV	word [cs:STAGE],FDLEN_LOBX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FONTSHI :				;; STAGE the high byte of the FONTS
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:FONTS_HIB],AL   ;;
	MOV	word [cs:STAGE],FDLEN_LOBX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
FDLENLO :				;; the low byte of the FONT-LENGTH
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	AND	CX,CX			;;
	JNZ	WORD_FDLEN		;;
	MOV	[cs:FDLEN_LOB],AL   ;;
	MOV	word [cs:STAGE],FDLEN_HIBX ;;
	JMP	FTB_LOOP		;;
WORD_FDLEN :				;;
	INC	SI			;;
	DEC	CX			;;
	MOV	word [cs:Pre_font_len],PRE_FONT_ND ;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	AND	AX,AX			;;
	JZ	NO_DISP_PTR		;;
	CMP	word [cs:TYPE_WORD],TYPE_DISPLAY ;;
	JE	DISPLAY_TYPE1		;;
	CMP	word [cs:TYPE_WORD],TYPE_PRINTER ;;
	JE	PRINTER_TYPE1		;;
					;;
NO_DISP_PTR :				;;
	MOV	word [cs:STAGE],FOUNDX ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
DISPLAY_TYPE1 : 			;;
	MOV	word [cs:STAGE],DISP_ROWSX ;;
	JMP	FTB_LOOP		;;
PRINTER_TYPE1 : 			;;
	MOV	word [cs:STAGE],PTRSELLOX ;;
	JMP	FTB_LOOP		;;
					;;
					;;+++++++++++++++++++++++++++++++++
FDLENHI :				;; STAGE the high byte of the F-LENGTH
	MOV	word [cs:Pre_font_len],PRE_FONT_ND
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:FDLEN_HIB],AL   ;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	AND	AX,AX			;;
	JZ	NO_DISP_PTR2		;;
	CMP	word [cs:TYPE_WORD],TYPE_DISPLAY ;;
	JE	DISPLAY_TYPE2		;;
	CMP	word [cs:TYPE_WORD],TYPE_PRINTER ;;
	JE	PRINTER_TYPE2		;;
NO_DISP_PTR2:				;;
	MOV	word [cs:STAGE],FOUNDX ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
DISPLAY_TYPE2 : 			;;
	MOV	word [cs:STAGE],DISP_ROWSX ;;
	JMP	FTB_LOOP		;;
PRINTER_TYPE2 : 			;;
	MOV	word [cs:STAGE],PTRSELLOX ;;
	JMP	FTB_LOOP		;;
					;;
					;;+++++++++++++++++++++++++++++++++
DSPROWS :				;; STAGE : get the rows
	XOR	AX,AX			;;
	MOV	[cs:DISP_ROWS],AL   ;;
	MOV	[cs:DISP_COLS],AL   ;;
	MOV	[cs:DISP_X],AL   ;;
	MOV	[cs:DISP_Y],AL   ;;
	MOV	[cs:COUNT_WORD],AX  ;;
					;;
	INC	word [cs:Pre_font_len] ;;
	MOV	AX,[FPKT] ;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:DISP_ROWS],AL   ;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	JZ	NO_DISP_FONT3		;;
	MOV	word [cs:STAGE],DISP_COLSX ;;
	JMP	FTB_LOOP		;;
NO_DISP_FONT3 : 			;;
	MOV	word [cs:STAGE],FOUNDX ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
DSPCOLS :				;; STAGE : get the COLS
	INC	word [cs:Pre_font_len] ;;
	MOV	AX,[FPKT] ;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:DISP_COLS],AL   ;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	JZ	NO_DISP_FONT3		;;
	MOV	word [cs:STAGE],DISP_XX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
DSPX :					;; STAGE : get the aspect X
	INC	word [cs:Pre_font_len] ;;
	MOV	AX,[FPKT] ;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:DISP_X],AL ;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	JZ	NO_DISP_FONT3		;;
	MOV	word [cs:STAGE],DISP_YX ;;
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
DSPY :					;; STAGE : get the aspect Y
	INC	word [cs:Pre_font_len] ;;
	MOV	AX,[FPKT] ;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:DISP_Y],AL   ;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	JZ	NO_DISP_FONT3		;;
	MOV	word [cs:STAGE],COUNT_LOBX ;;
	JMP	FTB_LOOP		;;
					;;
					;;+++++++++++++++++++++++++++++++++
DSPCOUNTLO :				;; the low byte of the FONT-LENGTH
	INC	word [cs:Pre_font_len] ;;
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	PUSH	AX			;; check if length is enough
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	POP	AX			;;
	JNZ	A_WORD_COUNT		;;
	JMP	NO_DISP_FONT3		;;
A_WORD_COUNT :				;;
	AND	CX,CX			;;
	JNZ	WORD_COUNT		;;
	MOV	[cs:COUNT_LOB],AL   ;;
	MOV	word [cs:STAGE],COUNT_HIBX ;;
	JMP	FTB_LOOP		;;
WORD_COUNT :				;;
	INC	word [cs:Pre_font_len] ;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:COUNT_WORD],AX  ;;
;	MOV	cs:pre_font_len,PRE_FONT_D;
					;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	MOV	word [cs:STAGE],FOUNDX ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
					;;
					;;+++++++++++++++++++++++++++++++++
DSPCOUNTHI :				;; STAGE the high byte of the F-LENGTH
	INC	word [cs:Pre_font_len] ;;
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:COUNT_HIB],AL   ;;
;	MOV	cs:pre_font_len,PRE_FONT_D;
					;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	MOV	word [cs:STAGE],FOUNDX ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
					;;
					;;
					;;+++++++++++++++++++++++++++++++++
PTRSELLO :				;; the low byte of the SELECTION_TYPE
	INC	word [cs:Pre_font_len] ;;
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	PUSH	AX			;; check if length is enough
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	POP	AX			;;
	JNZ	A_WORD_SEL		;;
	JMP	NO_PTR_FONT3		;;
A_WORD_SEL :				;;
	AND	CX,CX			;;
	JNZ	WORD_SEL		;;
	MOV	[cs:PTR_SELOB],AL   ;;
	MOV	word [cs:STAGE],PTRSELHIX ;;
	JMP	FTB_LOOP		;;
WORD_SEL :				;;
	INC	word [cs:Pre_font_len] ;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:PTR_SEL_WORD],AX  ;;
					;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
					;;
	CMP	word [cs:PTR_SEL_WORD],0 ;;
	JNE	PTR_SEL_NOT0		;;
					;;
					;;
	MOV	word [cs:STAGE],FOUNDX ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
					;;
PTR_SEL_NOT0 :				;;
	MOV	word [cs:STAGE],PTRLENLOX ;;
	JMP	FTB_LOOP		;;
					;;
					;;+++++++++++++++++++++++++++++++++
PTRSELHI:				;; STAGE the high byte of SELECT_TYPE
	INC	word [cs:Pre_font_len] ;;
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:PTR_SEHIB],AL   ;;
					;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
					;;
	CMP	word [cs:PTR_SEL_WORD],0 ;;
	JNE	PTR_SEL_NOT0		;;
					;;
					;;
	MOV	word [cs:STAGE],FOUNDX ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
					;;
					;;
					;;+++++++++++++++++++++++++++++++++
PTRLENLO :				;; the low byte of SELECTION_LENGTH
	INC	word [cs:Pre_font_len] ;;
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	PUSH	AX			;; check if length is enough
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	POP	AX			;;
	JNZ	A_WORD_SELEN		;;
	JMP	NO_PTR_FONT3		;;
A_WORD_SELEN :				;;
	AND	CX,CX			;;
	JNZ	WORD_SELEN		;;
	MOV	[cs:PTR_LNLOB],AL   ;;
	MOV	word [cs:STAGE],PTRLENHIX ;;
	JMP	FTB_LOOP		;;
WORD_SELEN :				;;
	INC	word [cs:Pre_font_len] ;;
	INC	SI			;;
	DEC	CX			;;
	MOV	[cs:PTR_LEN_WORD],AX  ;;
					;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	MOV	word [cs:STAGE],FOUNDX ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
					;;
					;;+++++++++++++++++++++++++++++++++
PTRLENHI :				;; STAGE the high byte of SELECT_LENGTH
	INC	word [cs:Pre_font_len] ;;
	MOV	AX,[FPKT] ;;
	INC	SI			;; byte by byte
	DEC	CX			;;
	MOV	[cs:PTR_LNHIB],AL   ;;
					;;
	MOV	AX,[cs:FDLEN_WORD]  ;;
	DEC	AX			;;
	MOV	[cs:FDLEN_WORD],AX  ;;
	MOV	word [cs:STAGE],FOUNDX ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
					;;
NO_PTR_FONT3 :				;;
	MOV	word [cs:STAGE],FOUNDX ;; FSTAT is to be changed
	JMP	FTB_LOOP		;;
					;;+++++++++++++++++++++++++++++++++
PASS	:				;; STAGE - PASS DUMMY BYTES
					;;
	PUSH	DX			;;
	PUSH	ES			;;
	PUSH	DI			;;
					;;
	PUSH	CS			;;
	POP	ES			;;
	MOV	DI,PASS_BRK        ;;
	MOV	DX,PASS_INDX		;;
	MOV	AX,[cs:PASS_CNT]   ;;
					;;
NEXT_BRK:				;; find the next pass-break
	CMP	AX,[es:DI]		;;
					;;
	JB	UPTO_BRK		;;
					;;
	DEC	DX			;;
	JZ	PASS_ERR		;;
	INC	DI			;;
	INC	DI			;;
	JMP	NEXT_BRK		;;
					;;
UPTO_BRK :				;; next break point found
	MOV	DX,[es:DI]		;;
	SUB	DX,AX			;; bytes to be skipped
	CMP	CX,DX			;; all to be skipped ?
	JAE	PASS_ALL		;;
					;;
	ADD	[cs:PASS_CNT],CX   ;;
	ADD	SI,CX			;;
	SUB	CX,CX			;;
	JMP	PASS_END		;;
					;;
PASS_ALL :				;;
	ADD	[cs:PASS_CNT],DX   ;;
	ADD	SI,DX			;;
	SUB	CX,DX			;;
					;;
	MOV	AX,[cs:PASS_POSTX]  ;;
	MOV	[cs:STAGE],AX   ;;
					;;
;	cmp	ax,passx		;; is the next stage a pass-stage ?
;	jne	not_passx		;;
;	mov	ax,pass_postxx		;;
;	mov	pass_postx,ax		;;
;	mov	pass_postxx,stage_max	;; can support only 2 consecutive pass
					;;
;not_passx :				 ;;
					;;
	JMP	PASS_END		;;
					;;
PASS_ERR :				;; DEVICE ERROR, wrong stage
	POP	DI			;;
	POP	ES			;;
	POP	DX			;;
	MOV	word [FTP+FTBLK.FTB_STATUS],STAT_DEVERR
	SUB	CX,CX			;; ignore all the input string
	JMP	PASS_DONE		;;
					;;
PASS_END :				;;
	POP	DI			;;
	POP	ES			;;
	POP	DX			;;
PASS_DONE :				;;
	JMP	FTB_LOOP		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
FTB_LPEND :				;;
					;;
	CMP	word [cs:STAGE],FOUNDX ;;
	JNE	NOT_FOUNDX		;;
					;;
	CALL	FOUND_DO		;;
					;;
NOT_FOUNDX :				;;
					;;
	POP	CX			;; STACK -1
					;;
FP_RET	:				;;
	POP	SI			;; restore registers
	POP	DI			;;
	POP	DX			;;
	POP	CX			;;
	POP	BX			;;
	POP	AX			;;
	POP	ES			;;
	POP	DS			;;
					;;
	RET				;;
;FONT_PARSER ENDP			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;CSEG	ENDS
;	END
