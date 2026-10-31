 PAGE 80,132
;	SCCSID = @(#)tdata.asm	4.3 85/05/17
;	SCCSID = @(#)tdata.asm	4.3 85/05/17
TITLE	COMMAND Transient Initialized DATA

; MODIFICATION HISTORY
;
;	EE 10-20-83	Changed the drive check indicator bytes (DCIB's) in
;			COMTAB to be a flag byte in which bit 0 is now the
;			DCIB(bit) and bit 1 is on if the command can take
;			switches.

macro fmt name,string,args {
	local	a
a	db  string
;PUBLIC	name
name	dw  a
irp val, args \{
	dw  val
\}
}

macro btab b,sym {
    db	b
    dw	    sym
}

.xlist
.xcref
	include 'COMSW.ASM'  ;AC000;
	include 'COMSEG.ASM'
	include 'EA.INC'   ;AN030;
	include 'DIRENT.INC'  ;AN042;
.list
.cref

macro BREAK subtitle {
	SUBTTL	subtitle
	PAGE
}

;
; WARNING: DO NOT INCLUDE DOSSYM.INC BECAUSE IT DESTROYS THE MACRO 'FMT' THAT
; has been defined above - RS.
;
	include 'CURDIR.INC'
	include 'ERROR.INC'
	include 'IFEQU.ASM'
	include 'COMEQU.ASM'

if SEGSEL = S_TRANSPACE	;AC000;
;	EXTRN	arg_buf:BYTE
;	EXTRN	bwdbuf:byte
;	EXTRN	bytes_free:WORD
;	EXTRN	charbuf:byte
;	EXTRN	copy_Num:WORD
;	EXTRN	cpyflag:BYTE
;	EXTRN	DATE_OUTPUT:BYTE	;AC000;
;	EXTRN	Dir_Num:WORD
;	EXTRN	DRIVE_OUTPUT:BYTE	;AC000;
;	EXTRN	file_size_high:WORD
;	EXTRN	file_size_low:WORD
;	EXTRN	major_ver_num:WORD
;	EXTRN	minor_ver_num:WORD
;	EXTRN	one_char_val:BYTE
;	EXTRN	PARSE1_OUTPUT:BYTE	;AC000;
;	EXTRN	srcbuf:byte
;	EXTRN	string_ptr_2:WORD
;	EXTRN	system_cpage:word
;	EXTRN	TIME_OUTPUT:BYTE	;AC000;
;	EXTRN	vol_drv:BYTE
;	EXTRN	vol_serial:dword	;AN000;
end if

if SEGSEL = S_TRANCODE	;AC000;
;	EXTRN	$CALL:NEAR
;	EXTRN	$CHDIR:NEAR
;	EXTRN	$EXIT:NEAR
;	EXTRN	$FOR:NEAR
;	EXTRN	$IF:NEAR
;	EXTRN	$MKDIR:NEAR
;	EXTRN	$RMDIR:NEAR
;	EXTRN	ADD_NAME_TO_ENVIRONMENT:NEAR
;	EXTRN	ADD_PROMPT:NEAR
;	EXTRN	build_dir_for_prompt:near
;	EXTRN	CATALOG:NEAR
;	EXTRN	CHCP:NEAR
;	EXTRN	CLS:NEAR
;	EXTRN	CNTRLC:NEAR
;	EXTRN	COPY:NEAR
;	EXTRN	CRENAME:NEAR
;	EXTRN	CRLF2:NEAR
;	EXTRN	CTIME:NEAR
;	EXTRN	CTTY:NEAR
;	EXTRN	DATE:NEAR
;	EXTRN	ECHO:NEAR
;	EXTRN	ERASE:NEAR
;	EXTRN	GOTO:NEAR
;	EXTRN	IFERLEV:NEAR
;	EXTRN	IFEXISTS:NEAR
;	EXTRN	IFNOT:NEAR
;	EXTRN	PATH:NEAR
;	EXTRN	PAUSE:NEAR
;	EXTRN	PRINT_B:NEAR
;	EXTRN	PRINT_BACK:NEAR
;	EXTRN	PRINT_DATE:NEAR
;	EXTRN	PRINT_CHAR:NEAR
;	EXTRN	PRINT_DRIVE:NEAR
;	EXTRN	PRINT_EQ:NEAR
;	EXTRN	PRINT_ESC:NEAR
;	EXTRN	PRINT_G:NEAR
;	EXTRN	PRINT_L:NEAR
;	EXTRN	PRINT_TIME:NEAR
;	EXTRN	PRINT_VERSION:NEAR
;	EXTRN	SHIFT:NEAR
;	EXTRN	TCOMMAND:NEAR
;	EXTRN	TRUENAME:NEAR		;AN000;
;	EXTRN	TYPEFIL:NEAR
;	EXTRN	VERSION:NEAR
;	EXTRN	VOLUME:NEAR
;	EXTRN	VERIFY:NEAR
;
; WARNING!!! No code may appear after this label!!!!
;
;PUBLIC	TranCodeLast
label TranCodeLast byte
end if

; Data for transient portion

if SEGSEL = S_TRANDATA

;	PUBLIC	accden_ptr		;AN000;
;	PUBLIC	acrlf_ptr		;AN000;
;	PUBLIC	arg_buf_ptr		;AN000;
;	PUBLIC	badbat_ptr		;AN000;
;	PUBLIC	badcd_ptr		;AN000;
;	PUBLIC	badCPmes_ptr		;AN000;
;	PUBLIC	badcurdrv		;AN000;
;	PUBLIC	baddat_ptr		;AN000;
;	PUBLIC	baddev_ptr		;AN000;
;	PUBLIC	baddrv_ptr		;AN000;
;	PUBLIC	badlab_ptr		;AN000;
;	PUBLIC	badmkd_ptr		;AN000;
;	PUBLIC	badnam_ptr		;AN000;
;	PUBLIC	bad_on_off_ptr		;AN000;
;	PUBLIC	badPmes_ptr		;AN000;
;	PUBLIC	badrmd_ptr		;AN000;
;	PUBLIC	badtim_ptr		;AN000;
;	PUBLIC	batext
;	PUBLIC	bytmes_ptr		;AN000;
;	PUBLIC	CLSSTRING
;	PUBLIC	comext
;	PUBLIC	COMSPECSTR
;	PUBLIC	COMTAB
;	PUBLIC	copied_ptr		;AN000;
;	PUBLIC	cp_active_ptr		;AN000;
;	PUBLIC	cp_not_all_ptr		;AN000;
;	PUBLIC	cp_not_set_ptr		;AN000;
;	PUBLIC	ctrlcmes_ptr		;AN000;
;	PUBLIC	curdat_mo_day		;AN000;
;	PUBLIC	curdat_ptr		;AN000;
;	PUBLIC	curdat_yr		;AN000;
;	PUBLIC	curtim_hr_min		;AN000;
;	PUBLIC	curtim_ptr		;AN000;
;	PUBLIC	curtim_sec_hn		;AN000;
;	PUBLIC	dback_ptr		;AN000;
;	PUBLIC	del_Y_N_ptr		;AN000;
;	PUBLIC	devwmes_ptr		;AN000;
;	PUBLIC	dirdattim_ptr		;AN000;
;	PUBLIC	dirdat_mo_day		;AN000;
;	PUBLIC	dirdat_yr		;AN000;
;	PUBLIC	dirhead_ptr		;AN000;
;	PUBLIC	dirmes_ptr		;AN000;
;	PUBLIC	dirtim_hr_min		;AN000;
;	PUBLIC	dirtim_sec_hn		;AN000;
;	PUBLIC	DIR_W_SYN		;AN000;
;	PUBLIC	disp_file_size_ptr	;AN000;
;	PUBLIC	dmes_ptr		;AN000;
;	PUBLIC	echomes_ptr		;AN000;
;	PUBLIC	enverr_ptr		;AN000;
;	PUBLIC	eurdat_ptr		;AN000;
;	PUBLIC	exeext
;	PUBLIC	extend_buf_off		;AN000;
;	PUBLIC	extend_buf_ptr		;AN000;
;	PUBLIC	extend_buf_seg		;AN000;
;	PUBLIC	extend_buf_sub		;AN000;
;	PUBLIC	file_name_ptr		;AN000;
;	PUBLIC	fornestmes_ptr		;AN000;
;	PUBLIC	fuldir_ptr		;AN000;
;	PUBLIC	IFTAB
;	PUBLIC	inBdev_ptr		;AN000;
;	PUBLIC	inornot_ptr		;AN000;
;	PUBLIC	Inv_code_page		;AN000;
;	PUBLIC	inval_path_ptr		;AN000;
;	PUBLIC	japdat_ptr		;AN000;
;	PUBLIC	Losterr_ptr		;AN000;
;	PUBLIC	md_exists_ptr		;AN006;
;	PUBLIC	msg_cont_flag		;AN000;
;	PUBLIC	msg_disp_class		;AN000;
;	PUBLIC	needbat_ptr		;AN000;
;	PUBLIC	newdat_format		;AN000;
;	PUBLIC	newdat_ptr		;AN000;
;	PUBLIC	newtim_ptr		;AN000;
;	PUBLIC	NLSFUNC_ptr		;AN000;
;	PUBLIC	nospace_ptr		;AN000;
;	PUBLIC	no_values		;AN000;
;	PUBLIC	nulpath_ptr		;AN000;
;	PUBLIC	offmes_ptr		;AN000;
;	PUBLIC	onmes_ptr		;AN000;
;	PUBLIC	overwr_ptr		;AN000;
;	PUBLIC	PARSE_BREAK		;AN000;
;	PUBLIC	PARSE_CHCP		;AN000;
;	PUBLIC	PARSE_CHDIR		;AN000;
;	PUBLIC	PARSE_CTTY		;AN000;
;	PUBLIC	PARSE_DATE		;AN000;
;	PUBLIC	PARSE_DIR		;AN000;
;	PUBLIC	PARSE_ERASE		;AN000;
;	PUBLIC	PARSE_MRDIR		;AN000;
;	PUBLIC	PARSE_RENAME		;AN000;
;	PUBLIC	PARSE_TIME		;AN000;
;	PUBLIC	PARSE_VOL		;AN000;
;	PUBLIC	PATH_TEXT
;	PUBLIC	pausemes_ptr		;AN000;
;	PUBLIC	pipeEmes_ptr		;AN000;
;	PUBLIC	promptdat_moday 	;AN000;
;	PUBLIC	promptdat_ptr		;AN000;
;	PUBLIC	promptdat_yr		;AN000;
;	PUBLIC	PROMPT_TABLE
;	PUBLIC	PROMPT_TEXT
;	PUBLIC	promtim_hr_min		;AN000;
;	PUBLIC	promtim_ptr		;AN000;
;	PUBLIC	promtim_sec_hn		;AN000;
;	PUBLIC	renerr_ptr		;AN000;
;	PUBLIC	SLASH_P_SYN		;AN000;
;	PUBLIC	string_buf_ptr		;AN000;
;	PUBLIC	suremes_ptr		;AN000;
;	PUBLIC	switch_list
;	PUBLIC	syntmes_ptr		;AN000;
;	PUBLIC	tab_ptr 		;AN000;
;	PUBLIC	TRANDATAEND
;	PUBLIC	usadat_ptr		;AN000;
;	PUBLIC	verimes_ptr		;AN000;
;	PUBLIC	vermes_ptr		;AN000;
;	PUBLIC	volmes_ptr		;AN000;
;	PUBLIC	volmes_ptr_2		;AN000;
;	PUBLIC	volsermes_ptr		;AN000;
;	PUBLIC	WEEKTAB
;	PUBLIC	xa_cp			;AN030;

include 'TRANMSG.ASM'

CLSSTRING DB	4,01BH,"[2J"            ; ANSI Clear screen

label PROMPT_TABLE byte
	btab	"B",print_B
	btab	"D",PRINT_DATE
	btab	"E",print_esc
	btab	"G",print_G
	btab	"H",print_back
	btab	"L",print_L
	btab	"N",print_drive
	btab	"P",build_dir_for_prompt
	btab	"Q",print_EQ
	btab	"T",PRINT_TIME
	btab	"V",print_version
	btab	"_",CRLF2
	btab	"$",print_char
	DB	0				; NUL TERMINATED

label IFTAB byte    ; Table of IF conditionals
	DB	3,"NOT"                         ; First byte is count
	DW	IFNOT
	DB	10,"ERRORLEVEL"
	DW	IFERLEV
	DB	5,"EXIST"
	DW	IFEXISTS
	DB	0

; Table for internal command names
COMTAB	DB	3,"DIR",fSwitchAllowed+fCheckDrive
	DW	CATALOG                  ; In TCMD1.ASM
	DB	4,"CALL",fSwitchAllowed
	DW	CALL$                   ; In TBATCH2.ASM
	DB	4,"CHCP",fSwitchAllowed
	DW	CHCP                   ; In TCMD2B.ASM
	DB	6,"RENAME",fSwitchAllowed+fCheckDrive  ;AC018; P3903
	DW	CRENAME                  ; In TCMD1.ASM
	DB	3,"REN",fSwitchAllowed+fCheckDrive     ;AC018; P3903
	DW	CRENAME                  ; In TCMD1.ASM
	DB	5,"ERASE",fSwitchAllowed+fCheckDrive
	DW	ERASE                   ; In TCMD1.ASM
	DB	3,"DEL",fSwitchAllowed+fCheckDrive
	DW	ERASE                   ; In TCMD1.ASM
	DB	4,"TYPE",fSwitchAllowed+fCheckDrive  ;AC018; P3903
	DW	TYPEFIL                  ; In TCMD1.ASM
	DB	3,"REM",fSwitchAllowed
	DW	TCOMMAND                  ; In TCODE.ASM
	DB	4,"COPY",fSwitchAllowed+fCheckDrive
	DW	COPY                   ; In COPY.ASM
	DB	5,"PAUSE",fSwitchAllowed
	DW	PAUSE_                   ; In TCMD1.ASM
	DB	4,"DATE",fSwitchAllowed
	DW	DATE                   ; In TPIPE.ASM
	DB	4,"TIME",fSwitchAllowed         ;AC018; P3903
	DW	CTIME                   ; In TPIPE.ASM
	DB	3,"VER",0
	DW	VERSION                  ; In TCMD2.ASM
	DB	3,"VOL",fSwitchAllowed+fCheckDrive   ;AC018; P3903
	DW	VOLUME                   ; In TCMD1.ASM
	DB	2,"CD",fSwitchAllowed+fCheckDrive    ;AC018; P3903
	DW	CHDir$                   ; In TENV.ASM
	DB	5,"CHDIR",fSwitchAllowed+fCheckDrive ;AC018; P3903
	DW	CHDir$                   ; In TENV.ASM
	DB	2,"MD",fSwitchAllowed+fCheckDrive    ;AC018; P3903
	DW	MKDir$                   ; In TENV.ASM
	DB	5,"MKDIR",fSwitchAllowed+fCheckDrive ;AC018; P3903
	DW	MKDir$                   ; In TENV.ASM
	DB	2,"RD",fSwitchAllowed+fCheckDrive    ;AC018; P3903
	DW	RMDir$                   ; In TENV.ASM
	DB	5,"RMDIR",fSwitchAllowed+fCheckDrive ;AC018; P3903
	DW	RMDir$                   ; In TENV.ASM
	DB	5,"BREAK",fSwitchAllowed        ;AC018; P3903
	DW	CNTRLC                   ; In TUCODE.ASM
	DB	6,"VERIFY",fSwitchAllowed       ;AC018; P3903
	DW	VERIFY                   ; In TUCODE.ASM
	DB	3,"SET",fSwitchAllowed
	DW	ADD_NAME_TO_ENVIRONMENT                 ; In TENV.ASM
	DB	6,"PROMPT",fSwitchAllowed
	DW	ADD_PROMPT                  ; In TENV.ASM
	DB	4,"PATH",fSwitchAllowed
	DW	PATH                   ; In TCMD2.ASM
	DB	4,"EXIT",0
	DW	Exit$                   ; In TCMD2.ASM
	DB	4,"CTTY",fCheckDrive+fSwitchAllowed
	DW	CTTY                   ; In TCMD2.ASM
	DB	4,"ECHO",fSwitchAllowed
	DW	ECHO                   ; In TUCODE.ASM
	DB	4,"GOTO",fSwitchAllowed
	DW	GOTO                   ; In TBATCH.ASM
	DB	5,"SHIFT",fSwitchAllowed
	DW	Shift                   ; In TBATCH.ASM
	DB	2,"IF",fSwitchAllowed
	DW	IF$                   ; In TBATCH.ASM
	DB	3,"FOR",fSwitchAllowed
	DW	FOR$                   ; In TBATCH.ASM
	DB	3,"CLS",0
	DW	CLS                   ; In TCMD2.ASM
	DB	8,"TRUENAME",fSwitchAllowed+fCheckDrive  ;AN000; P3903 changed
	DW	TRUENAME                  ;AN000;
	DB	0				; Terminate command table


comext	dB	".COM"
exeext	dB	".EXE"
batext	dB	".BAT"

switch_list	DB	"VBAPW"                 ; flags we can recognize


label XA_cp byte      ;AN030; list for one extended attribute
	DW	  1				;AN030;
	DB	  EAISBINARY			;AN030; type
	DW	  EASYSTEM			;AN030; flags
	DB	  2				;AN030; name length
	DB	  "CP"                          ;AN030; name




;PUBLIC	BatBufLen
BatBufLen   DW	BatLen

; *****************************************************
; EMG 4.00
; DATA STARTING HERE WAS ADDED BY EMG FOR 4.00
; FOR IMPLEMENTATION OF COMMON PARSE ROUTINE
; *****************************************************

;
; COMMON PARSE BLOCKS
;

;
; Indicates no value list for PARSE.
;

NO_VALUES	DW	0			;AN000;  no values

;
; PARSE control block for a required file specification (upper cased)
;

label FILE_REQUIRED byte   ;AN000;
		DW	0200H			;AN000;  filespec - required
		DW	1			;AN000;  capitalize - file table
		DW	PARSE1_OUTPUT           ;AN000;  result buffer
		DW	NO_VALUES           ;AN000;
		DB	0			;AN000;  no keywords

;
; PARSE control block for an optional file specification (upper cased)
; or drive number
;

label FILE_OPTIONAL byte   ;AN000;
		DW	0301H			;AN000;  filespec or drive number
						;	 optional
		DW	1			;AN000;  capitalize - file table
		DW	PARSE1_OUTPUT           ;AN000;  result buffer
		DW	NO_VALUES           ;AN000;
		DB	0			;AN000;  no keywords

;
; PARSE control block for an optional file specification (upper cased)
;

label FILE_OPTIONAL2 byte   ;AN000;
		DW	0201H			;AN000;  filespec or drive number
						;	 optional
		DW	1			;AN000;  capitalize - file table
		DW	PARSE1_OUTPUT           ;AN000;  result buffer
		DW	NO_VALUES           ;AN000;
		DB	0			;AN000;  no keywords

;
; PARSE control block for an optional /P switch
;

label SLASH_P_SWITCH byte   ;AN000;
		DW	0			;AN000;  no match flags
		DW	2			;AN000;  capitalize - char table
		DW	PARSE1_OUTPUT           ;AN000;  result buffer
		DW	NO_VALUES           ;AN000;
		DB	1			;AN000;  1 keyword
SLASH_P_SYN	DB	"/P",0                  ;AN000;  /P switch



; PARSE BLOCK FOR BREAK, VERIFY, ECHO

;
; The following parse control block can be used for any command which
; needs only the optional "ON" and "OFF" keywords as operands.  Allows
; the equal sign as an additional delimiter.  Returns verified result
; in PARSE1_OUTPUT.  Currently used for the BREAK, VERIFY, and	ECHO
; internal commands.
;

label PARSE_BREAK byte   ;AN000;
		DW	BREAK_PARMS           ;AN000;
		DB	0			;AN032; no extra delimiter

label BREAK_PARMS byte   ;AN000;
		DB	0,1			;AN000;  1 positional parm
		DW	BREAK_CONTROL1          ;AN000;
		DB	0			;AN000;  no switches
		DB	0			;AN000;  no keywords

label BREAK_CONTROL1 byte   ;AN000;
		DW	2001H			;AN000;  string value - optional
		DW	2			;AN000;  capitalize - char table
		DW	PARSE1_OUTPUT           ;AN000;  result buffer
		DW	BREAK_VALUES           ;AN000;
		DB	0			;AN000;  no keywords

label BREAK_VALUES byte   ;AN000;
		DB	3			;AN000;
		DB	0			;AN000;  no ranges
		DB	0			;AN000;  no numeric values
		DB	2			;AN000;  2 string values
		DB	0			;AN000;  returned if ON
		DW	BREAK_ON           ;AN000;  point to ON string
		DB	'f'                     ;AN000;  returned if OFF
		DW	BREAK_OFF           ;AN000;  point to OFF string

BREAK_ON	DB	"ON",0                  ;AN000;
BREAK_OFF	DB	"OFF",0                 ;AN000;

;
; PARSE BLOCK FOR CHCP
;

;
; The following parse control block can be used for any command which
; needs only one optional three digit decimal parameter for operands.
; Returns verified result in PARSE1_OUTPUT.  Currently used for the
; CHCP internal command.
;
CHCP_MINVAL	EQU	100			;AN000;
CHCP_MAXVAL	EQU	999			;AN000;

label PARSE_CHCP byte   ;AN000;
		DW	CHCP_PARMS           ;AN000;
		DB	0			;AN000;  no extra delimiter

label CHCP_PARMS byte   ;AN000;
		DB	0,1			;AN000;  1 positional parm
		DW	CHCP_CONTROL1           ;AN000;
		DB	0			;AN000;  no switches
		DB	0			;AN000;  no keywords

label CHCP_CONTROL1 byte   ;AN000;
		DW	8001H			;AN000;  numeric value - optional
		DW	0			;AN000;  no function flags
		DW	PARSE1_OUTPUT           ;AN000;  result buffer
		DW	CHCP_VALUES           ;AN000;
		DB	0			;AN000;  no keywords

label CHCP_VALUES byte   ;AN000;
		DB	1			;AN000;
		DB	1			;AN000;  1 range
		DB	1			;AN000;  returned if result
		DD	CHCP_MINVAL,CHCP_MAXVAL ;AN000;  minimum & maximum value
		DB	0			;AN000;  no numeric values
		DB	0			;AN000;  no string values


;
; PARSE BLOCK FOR DATE
;

;
; The following parse control block can be used for any command which
; needs only an optional date string as an operand.  Returns unverified
; result in DATE_OUTPUT.  Currently used for the DATE internal command.
;

label PARSE_DATE byte   ;AN000;
		DW	DATE_PARMS           ;AN000;
		DB	0			;AN000;  no extra delimiter

label DATE_PARMS byte   ;AN000;
		DB	0,1			;AN000;  1 positional parm
		DW	DATE_CONTROL1           ;AN000;
		DB	0			;AN000;  no switches
		DB	0			;AN000;  no keywords

label DATE_CONTROL1 byte   ;AN000;
		DW	1001H			;AN000;  date - optional
		DW	0			;AN000;  no function flags
		DW	DATE_OUTPUT           ;AN000;  result buffer
		DW	NO_VALUES           ;AN000;
		DB	0			;AN000;  no keywords

;
; PARSE BLOCK FOR TIME
;

;
; The following parse control block can be used for any command which
; needs only an optional time string as an operand.  Returns unverified
; result in TIME_OUTPUT.  Currently used for the TIME internal command.
;

label PARSE_TIME byte   ;AN000;
		DW	TIME_PARMS           ;AN000;
		DB	0			;AN000;  no extra delimiter

label TIME_PARMS byte   ;AN000;
		DB	0,1			;AN000;  1 positional parm
		DW	TIME_CONTROL1           ;AN000;
		DB	0			;AN000;  no switches
		DB	0			;AN000;  no keywords

label TIME_CONTROL1 byte   ;AN000;
		DW	0801H			;AN000;  TIME - optional
		DW	0			;AN000;  no function flags
		DW	TIME_OUTPUT           ;AN000;  result buffer
		DW	NO_VALUES           ;AN000;
		DB	0			;AN000;  no keywords


;
; PARSE BLOCK FOR VOL
;

;
; The following parse control block can be used for any command which
; needs only an optional drive letter as an operand.  Returns unverified
; drive number (one based) in DRIVE_OUTPUT.  Currently used for the VOL
; internal command.
;

label PARSE_VOL byte   ;AN000;
		DW	VOL_PARMS           ;AN000;
		DB	0			;AN000;  no extra delimiter

label VOL_PARMS byte   ;AN000;
		DB	0,1			;AN000;  1 positional parm
		DW	DRIVE_CONTROL1          ;AN000;
		DB	0			;AN000;  no switches
		DB	0			;AN000;  no keywords

label DRIVE_CONTROL1 byte   ;AN000;
		DW	0101H			;AN000;  DRIVE - optional
		DW	1			;AN000;  capitalize - file table
		DW	DRIVE_OUTPUT           ;AN000;  result buffer
		DW	NO_VALUES           ;AN000;
		DB	0			;AN000;  no keywords


;
; PARSE BLOCK FOR MKDIR, RMDIR, TYPE
;

;
; The following parse control block can be used for any command which
; needs only one required file specification as an operand.  Returns a
; pointer to the unverified string in PARSE1_OUTPUT.  Currently used
; for the MKDIR, RMDIR, and TYPE internal commands.
;

label PARSE_MRDIR byte   ;AN000;
		DW	MRDIR_PARMS           ;AN000;
		DB	0			;AN000;  no extra delimiter

label MRDIR_PARMS byte   ;AN000;
		DB	1,1			;AN000;  1 positional parm
		DW	FILE_REQUIRED           ;AN000;
		DB	0			;AN000;  no switches
		DB	0			;AN000;  no keywords

;
; PARSE BLOCK FOR CHDIR, TRUENAME
;

;
; The following parse control block can be used for any command which
; needs only one optional file specification an operand.  Returns a
; pointer to the unverified string in PARSE1_OUTPUT.  Currently used
; for the CHDIR and TRUENAME internal commands.
;

label PARSE_CHDIR byte   ;AN000;
		DW	CHDIR_PARMS           ;AN000;
		DB	0			;AN000;  no extra delimiter

label CHDIR_PARMS byte   ;AN000;
		DB	0,1			;AN000;  1 positional parm
		DW	FILE_OPTIONAL           ;AN000;
		DB	0			;AN000;  no switches
		DB	0			;AN000;  no keywords

;
; PARSE BLOCK FOR ERASE
;

;
; The following parse control block is used for the DEL/ERASE internal
; commands.  This command has one required file specification and an
; optional switch (/p) as operands. The verified switch or unverified
; file specification is returned in PARSE1_OUTPUT.
;

label PARSE_ERASE byte   ;AN000;
		DW	ERASE_PARMS           ;AN000;
		DB	0			;AN000;  no extra delimiter

label ERASE_PARMS byte   ;AN000;
		DB	1,1			;AN000;  1 positional parm
		DW	FILE_REQUIRED           ;AN000;
		DB	1			;AN000;  1 switch
		DW	SLASH_P_SWITCH          ;AN000;
		DB	0			;AN000;  no keywords

;
; PARSE BLOCK FOR DIR
;

;
; The following parse control block is used for the DIR internal command.
; This command has one optional file specification and two optional
; switches (/p and /w) as operands.  The verified switch or unverified
; file specification is returned in PARSE1_OUTPUT.
;

label PARSE_DIR byte   ;AN000;
		DW	DIR_PARMS           ;AN000;
		DB	0			;AN000;  no extra delimiter

label DIR_PARMS byte   ;AN000;
		DB	0,1			;AN000;  1 positional parm
		DW	FILE_OPTIONAL2          ;AN000;
		DB	2			;AN000;  2 switches
		DW	SLASH_P_SWITCH          ;AN000;
		DW	DIR_SWITCH1           ;AN000;
		DB	0			;AN000;  no keywords

label DIR_SWITCH1 byte   ;AN000;
		DW	0			;AN000;  no match flags
		DW	2			;AN000;  capitalize by char table
		DW	PARSE1_OUTPUT           ;AN000;  result buffer
		DW	NO_VALUES           ;AN000;
		DB	1			;AN000;  1 keyword
DIR_W_SYN	DB	"/W",0                  ;AN000;  /W switch

;
; PARSE BLOCK FOR RENAME
;

;
; The following parse control block can be used for any command which
; needs only two required file specifications as operands.  Returns
; pointers to the unverified string in PARSE1_OUTPUT.
; Currently used for the RENAME internal command.
;

label PARSE_RENAME byte   ;AN000;
		DW	RENAME_PARMS           ;AN000;
		DB	0			;AN000;  no extra delimiter

label RENAME_PARMS byte   ;AN000;
		DB	2,2			;AN000;  2 positional parms
		DW	FILE_REQUIRED           ;AN000;
		DW	FILE_REQUIRED           ;AN000;
		DB	0			;AN000;  no switches
		DB	0			;AN000;  no keywords

;
; PARSE BLOCK FOR CTTY
;

;
; The following parse control block can be used for any command which
; needs one required device name as an operand.  Returns a pointer to
; unverified string in PARSE1_OUTPUT. Currently used for the CTTY
; internal command.
;

label PARSE_CTTY byte   ;AN000;
		DW	CTTY_PARMS           ;AN000;
		DB	0			;AN000;  no extra delimiter

label CTTY_PARMS byte   ;AN000;
		DB	1,1			;AN000;  1 positional parm
		DW	CTTY_CONTROL1           ;AN000;
		DB	0			;AN000;  no switches
		DB	0			;AN000;  no keywords

label CTTY_CONTROL1 byte   ;AN000;
		DW	2000H			;AN000;  string value - required
		DW	11H			;AN000;  capitalize - file table
						;AN000;  remove colon at end
		DW	PARSE1_OUTPUT           ;AN000;  result buffer
		DW	NO_VALUES           ;AN000;
		DB	0			;AN000;  no keywords

end if

if SEGSEL = S_TRANCODE	;AN000;

.xlist
.xcref

include 'SYSMSG.INC'  ;AN000;

.list
.cref

;ASSUME DS:TRANGROUP,ES:TRANGROUP,CS:TRANGROUP

MSG_UTILNAME <COMMAND>				;AN000; define utility name

MSG_SERVICES <COMT,COMMAND.CLF,COMMAND.CL1,COMMAND.CL2> ;AN000; The transient messages

include 'MSGDCL.INC'

end if			;AN000;

if SEGSEL = S_TRANDATA

label TRANDATAEND byte

end if			;AN000;

;	END
