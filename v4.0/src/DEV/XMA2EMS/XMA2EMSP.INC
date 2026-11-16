
IncSW	EQU	0			;INCLUDE PSDATA.INC			;AN000;
FarSW	EQU	0			;CALL THE PARSER BY NEAR CALL
DateSW	EQU	1	;		;SUPPRESS DATE CHECKING 		;AN000;
TimeSW	EQU	1	;		;SUPPRESS TIME CHECKING 		;AN000;
FileSW	EQU	1			;SUPPORT CHECKING FILE SPECIFICATION   ;AN000;
CAPSW	EQU	1	;		;SUPPRESS FILE TABLE CAPS		;AN000;
CmpxSW	EQU	1	;		;SUPPRESS CHECKING COMPLEX LIST
DrvSW	EQU	1	;		;SUPPRESS SUPPORT OF DRIVE ONLY FORMAT
QusSW	EQU	1	;		;SUPPRESS SUPPORT OF QUOTED STRING FORMAT ;AN000;
NumSW	EQU	1	;		;SUPPRESS CHECKING NUMERIC VALUE
KeySW	EQU	1			;SUPPORT KEYWORDS			 ;AN000;
SwSW	EQU	1			;DO SUPPORT SWITCHES			 ;AN000;
Val1SW	EQU	1			;SUPPORT  VALUE DEFINITION 1		 ;AN000;
Val2SW	EQU	1	;		;SUPPRESS SUPPORT  OF VALUE DEFINITION 2 ;AN000;
Val3SW	EQU	1			;DO SUPPORT VALUE DEFINITION 3

include 'PSDATA.INC'

;***********************************************************************

;-------------------------------------------------------------------
;
;	parser stuff for XMA2EMS.SYS
;
;-------------------------------------------------------------------

p_block:
	dw	px_block         ; address of extended parms block
	db	0			; number of extra stuff

;P_PARMS_Blk <offset px_block, 0, 0>	 ; parm block

;------------------------
;	extended parameter block for APPEND first load

px_block:
	db	1			; min number positional operands
	db	1			; max number positional operands
	dw	dummy_ctl        ; dummy control block

	db	1			; /X only switch
	dw	X_Switch         ; control block for /X switch

	db	7			; max number of keywords
	dw	frame_ctl        ; offset of FRAME= keyword control block
	dw	p0_ctl         ; offset of p0 keyword control block
	dw	p1_ctl         ; offset of p1 keyword control block
	dw	p2_ctl         ; offset of p2 keyword control block
	dw	p3_ctl         ; offset of p3 keyword control block
	dw	p254_ctl         ; offset of p254 keyword control block
	dw	p255_ctl         ; offset of p255 keyword control block

;------------------------

dummy_ctl:
	dw	0200h			;
	dw	0			; no caps
	dw	dum_result        ; pointer to dummy result block
	dw	dum_values        ; pointer to null values block
	db	0			; number of switches and synonyms

dum_values:
	dw	0			; null value list

X_Switch:
	dw	P_Num_Val		; /X:64
	dw	0002			; caps
	dw	X_Result         ; pointer to result block
	dw	X_Values         ; pointer to values block, none
	db	1			; number of switches and synonyms
	db	"/X",0                  ; only /X is valid

X_Values:
	db	1			; numeric values
	db	1			; 1 ranges
	db	1			; = 1 means good range
	dd	4			; valid values range from 4 (64Kb)...
	dd	512			; 512 (8MB)

;------------------------

frame_ctl:
	dw	P_Simple_S		; used for FRAME= and Pxxx=
	dw	0			; cap by char table
	dw	frame_result        ; pointer to result block
	dw	address_values        ; pointer to values block
	db	1			; number of synonyms
	db	"FRAME=",0

p0_ctl:
	dw	P_Simple_S		; used for FRAME= and Pxxx=
	dw	0			; cap by char table
	dw	p0_result        ; pointer to result block
	dw	address_values        ; pointer to values block
	db	3			; number of synonyms
	db	"P0=",0
	db	"P00=",0
	db	"P000=",0

p1_ctl:
	dw	P_Simple_S		; used for FRAME= and Pxxx=
	dw	0			; cap by char table
	dw	p1_result        ; pointer to result block
	dw	address_values        ; pointer to values block
	db	3			; number of synonyms
	db	"P1=",0
	db	"P01=",0
	db	"P001=",0

p2_ctl:
	dw	P_Simple_S		; used for FRAME= and Pxxx=
	dw	0			; cap by char table
	dw	p2_result        ; pointer to result block
	dw	address_values        ; pointer to values block
	db	3			; number of synonyms
	db	"P2=",0
	db	"P02=",0
	db	"P002=",0

p3_ctl:
	dw	P_Simple_S		; used for FRAME= and Pxxx=
	dw	0			; cap by char table
	dw	p3_result        ; pointer to result block
	dw	address_values        ; pointer to values block
	db	3			; number of synonyms
	db	"P3=",0
	db	"P03=",0
	db	"P003=",0

p254_ctl:
	dw	P_Simple_S		; used for FRAME= and Pxxx=
	dw	0			; cap by char table
	dw	p254_result        ; pointer to result block
	dw	address_values        ; pointer to values block
	db	1			; number of synonyms
	db	"P254=",0

p255_ctl:
	dw	P_Simple_S		; used for FRAME= and Pxxx=
	dw	0			; cap by char table
	dw	p255_result        ; pointer to result block
	dw	address_values        ; pointer to values block
	db	1			; number of synonyms
	db	"P255=",0

;------------------------

address_values:
	db	3			; strings
	db	0			; zeroes here for ranges
	db	0			; and values
	db	24			; 24 possible strings
	db	0A0h
	dw	A0_str
	db	0A4h
	dw	A4_str
	db	0A8h
	dw	A8_str
	db	0ACh
	dw	AC_str
	db	0B0h
	dw	B0_str
	db	0B4h
	dw	B4_str
	db	0B8h
	dw	B8_str
	db	0BCh
	dw	BC_str
	db	0C0h
	dw	C0_str
	db	0C4h
	dw	C4_str
	db	0C8h
	dw	C8_str
	db	0CCh
	dw	CC_str
	db	0D0h
	dw	D0_str
	db	0D4h
	dw	D4_str
	db	0D8h
	dw	D8_str
	db	0DCh
	dw	DC_str
	db	0E0h
	dw	E0_str
	db	0E4h
	dw	E4_str
	db	0E8h
	dw	E8_str
	db	0ECh
	dw	EC_str
	db	0F0h
	dw	F0_str
	db	0F4h
	dw	F4_str
	db	0F8h
	dw	F8_str
	db	0FCh
	dw	FC_str



A0_str	  db	  "A000",0
A4_str	  db	  "A400",0
A8_str	  db	  "A800",0
AC_str	  db	  "AC00",0
B0_str	  db	  "B000",0
B4_str	  db	  "B400",0
B8_str	  db	  "B800",0
BC_str	  db	  "BC00",0
C0_str	  db	  "C000",0
C4_str	  db	  "C400",0
C8_str	  db	  "C800",0
CC_str	  db	  "CC00",0
D0_str	  db	  "D000",0
D4_str	  db	  "D400",0
D8_str	  db	  "D800",0
DC_str	  db	  "DC00",0
E0_str	  db	  "E000",0
E4_str	  db	  "E400",0
E8_str	  db	  "E800",0
EC_str	  db	  "EC00",0
F0_str	  db	  "F000",0
F4_str	  db	  "F400",0
F8_str	  db	  "F800",0
FC_str	  db	  "FC00",0

;------------------------

dum_result	P_Result_Blk    ; dummy result block
X_Result	P_Result_Blk    ; /X result block
frame_result	P_Result_Blk    ; FRAME= result block
p0_result	P_Result_Blk    ; p0= result block
p1_result	P_Result_Blk    ; p1= result block
p2_result	P_Result_Blk    ; p2= result block
p3_result	P_Result_Blk    ; p3= result block
p255_result	P_Result_Blk    ; p254= result block
p254_result	P_Result_Blk    ; p255= result block


