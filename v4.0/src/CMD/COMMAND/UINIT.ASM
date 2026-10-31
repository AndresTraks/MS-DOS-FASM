 PAGE 80,132
;	SCCSID = @(#)uinit.asm	4.5 85/12/04
;	SCCSID = @(#)uinit.asm	4.5 85/12/04
TITLE	COMMAND Initialization messages

.XCREF
.XLIST
include 'COMSW.ASM'
include 'COMSEG.ASM'
include 'IFEQU.ASM'
.LIST
.CREF

macro addr sym,name {
;     public name
     match , name \{

	    dw sym
     \}
     match any, name \{

name	    dw	sym
     \}
}


if SEGSEL = S_ENVIRONMENT	;AC000;
;	EXTRN	ECOMSPEC:BYTE
end if

if SEGSEL = S_TRANCODE	;AC000;
;	extrn	Printf_init:FAR
;	extrn	Triage_Init:FAR
;	extrn	append_parse:FAR		;AN054;
end if

if SEGSEL = S_INIT	;AC000;


;	public	icondev
;	public	BADCSPFL
;	public	COMSPECT
;	public	AUTOBAT
;	public	fslash
;	public	bslash
;	public	space
;	public	PRDATTM
;	public	INITADD
;	public	print_add
;	public	CHUCKENV
;	public	scswitch
;	public	ucasea
;	public	ECOMLOC
;	public	equalsign
;	public	lcasea
;	public	lcasez
;	public	comspstring
;	public	EnvSiz
;	public	EnvMax
;	public	initend
;	public	trnsize
;	public	resetenv			;AC000;
;	public	ext_msg 			;AC000;
;	public	num_positionals
;	public	internat_info
;	public	parsemes_ptr

;	PUBLIC	triage_add
;	PUBLIC	oldenv
;	PUBLIC	usedenv
;	PUBLIC	KAUTOBAT			;AN000;  3/3/KK
;	public	eswitch 			;AN018;
;	public	dswitch 			;AN018;
;	public	init_parse			;AN054;
;	public	old_parse_ptr			;AN057;
;	PUBLIC	pars_msg_off			;AN060;
;	PUBLIC	pars_msg_seg			;AN060;

include 'RESMSG.EQU'  ;AC000;


label ICONDEV byte
		DB	"/DEV/"
		DB	"CON",0,0,0,0,0,0               ; Room for 8 char device
BADCSPFL	DB	0
COMSPECT	DB	"/COMMAND.COM",0,0
AUTOBAT 	DB	0,":\AUTOEXEC.BAT",0,0DH        ;AC027;
KAUTOBAT	DB	0,":\KAUTOEXE.BAT",0,0DH        ;AC027;  3/3/KK

PRDATTM 	DB	-1				;Init not to prompt for date time
INITADD 	DD	?
label print_add dword
		DW	printf_init
		DW	0
label triage_add dword
		DW	Triage_Init
		DW	0
CHUCKENV	DB	0
;eg ECOMLOC	DW	OFFSET ENVIRONMENT:ECOMSPEC-10H
ECOMLOC 	DW	ECOMSPEC-ENVIRONMENT$	;eg

COMSPSTRING	DB	"COMSPEC="
equalsign	db	"="
lcasea		db	"a"
lcasez		db	"z"
fslash		db	"/"
bslash		db	"\"
space		db	" "
scswitch	db	"C"                             ; Single command
ucasea		db	"A"

EnvSiz		DW	0				; size user wants to allocate
EnvMax		DW	0				; maximum size allowed.
oldenv		DW	0				; envirseg at initialization
usedenv 	DW	0				; amount of envirseg used
PARS_MSG_OFF	DW	0				;AN060;  SAVED PARSE ERROR MESSAGE OFFSET
PARS_MSG_SEG	DW	0				;AN060;  SAVED PARSE ERROR MESSAGE SEGMENT

;Do not separate the following two words.  Used to call transient PARSE routine

label init_parse dword    ;AN054;
init_p		DW	Append_parse            ;AN054;
initend 	DW	0				;eg segment address of end of init

;End of data that shouldn't be separated.

trnsize 	DW	0				;eg size of transient in paragraphs
resetenv	DB	0				;eg set if we need to setblck env at endinit
ext_msg 	DB	0				;AN000; set if /MSG switch entered
eswitch 	db	0				;AN018; set if /e was entered
dswitch 	db	0				;AN018; set if /d was entered
parsemes_ptr	dw	0			;AN000; word to store parse error number

;
; PARSE BLOCK FOR COMMAND
;
;PUBLIC	PARSE_COMMAND				;AN000;
;PUBLIC	COMND1_OUTPUT				;AN000;
;PUBLIC	COMND1_TYPE				;AN000;
;PUBLIC	COMND1_CODE				;AN000;
;PUBLIC	COMND1_SYN				;AN000;
;PUBLIC	COMND1_ADDR				;AN000;
;PUBLIC	COMMAND_F_SYN				;AN000;
;PUBLIC	COMMAND_P_SYN				;AN000;
;PUBLIC	COMMAND_C_SYN				;AN000;
;PUBLIC	COMMAND_D_SYN				;AN000;
;PUBLIC	COMMAND_E_SYN				;AN000;
;PUBLIC	COMMAND_M_SYN				;AN000;

;
;  The following parse control block is used for COMMAND.  This block is
;  used for parsing during initialization.  The sytax for COMMAND is:
;  COMMAND [d:][path][/P][/F][/D][/E:xxxxx][/MSG][/C executable]
;  Anything on the command line after the /C switch will be passed to the
;  executable command, so if /C is used, it must be specified last. The
;  /MSG switch can only be specified if the /P switch is specified.
;

ENVBIG	EQU	32768				;AN000; maximum environment size
ENVSML	EQU	160				;AN000; minimum environment size

label INTERNAT_INFO byte   ;AN000; used for country info after parsing is completed
label PARSE_COMMAND byte   ;AN000;
		DW	COMMAND_PARMS          ;AN000;
		DB	0			;AN000; no extra delimiter

label COMMAND_PARMS byte   ;AN000;
		DB	0,1			;AN000; 1 positional parm
		DW	COMMAND_FILE          ;AN000;
		DB	6			;AN000; 6 switches
		DW	COMMAND_SWITCH1          ;AN000;
		DW	COMMAND_SWITCH2          ;AN000;
		DW	COMMAND_SWITCH3          ;AN000;
		DW	COMMAND_SWITCH4          ;AN000;
		DW	COMMAND_SWITCH5          ;AN000;
		DW	COMMAND_SWITCH6          ;AN000;
		DB	0			;AN000; no keywords

label COMMAND_FILE byte   ;AN000;
		DW	0201H			;AN000; filespec - optional
		DW	1			;AN000; capitalize - file table
		DW	COMND1_OUTPUT          ;AN000; result buffer
		DW	NO_VAL           ;AN000;
		DB	0			;AN000; no keywords

label COMMAND_SWITCH1 byte   ;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	COMND1_OUTPUT          ;AN000; result buffer
		DW	NO_VAL           ;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_P_SYN	DB	"/P",0                  ;AN000; /P switch

label COMMAND_SWITCH2 byte   ;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	COMND1_OUTPUT          ;AN000; result buffer
		DW	NO_VAL           ;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_F_SYN	DB	"/F",0                  ;AN000; /F switch

label COMMAND_SWITCH3 byte   ;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	COMND1_OUTPUT          ;AN000; result buffer
		DW	NO_VAL           ;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_D_SYN	DB	"/D",0                  ;AN000; /D switch

label COMMAND_SWITCH4 byte   ;AN000;
		DW	8000H			;AN000; numeric value - required
		DW	0			;AN000; no function flags
		DW	COMND1_OUTPUT          ;AN000; result buffer
		DW	COMMAND_E_VAL          ;AN000; pointer to value list
		DB	1			;AN000; 1 keyword
COMMAND_E_SYN	DB	"/E",0                  ;AN000; /E switch

label COMMAND_E_VAL byte   ;AN000;
		DB	1			;AN000;
		DB	1			;AN000; 1 range
		DB	1			;AN000; returned if result
		DD	ENVSML,ENVBIG		;AN000; minimum & maximum value
		DB	0			;AN000; no numeric values
		DB	0			;AN000; no string values

label COMMAND_SWITCH5 byte   ;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	COMND1_OUTPUT          ;AN000; result buffer
		DW	NO_VAL           ;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_C_SYN	DB	"/C",0                  ;AN000; /C switch

label COMMAND_SWITCH6 byte   ;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	COMND1_OUTPUT          ;AN000; result buffer
		DW	NO_VAL           ;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_M_SYN	DB	"/MSG",0                ;AN000; /MSG switch

label COMND1_OUTPUT byte   ;AN000;
COMND1_TYPE	DB	0			;AN000; type
COMND1_CODE	DB	0			;AN000; return value
COMND1_SYN	DW	0			;AN000; synonym pointer
COMND1_ADDR	DD	0			;AN000; numeric value / address
						;	of string value

NO_VAL		DB	0			;AN000; no values
num_positionals DW	0			;AN000; counter for positionals
old_parse_ptr	DW	0			;AN057; SI position before calling parser

.xlist
.xcref

include 'SYSMSG.INC'  ;AN000; get message services routine

.list
.cref

;ASSUME DS:RESGROUP,ES:RESGROUP,CS:RESGROUP

MSG_UTILNAME <COMMAND>				;AN000; define utility name

MSG_SERVICES <COMR,COMMAND.CLB> 		;AN000; include initialization messages

include 'MSGDCL.INC'

end if

;	END
