	PAGE	60,132;
	TITLE	EDLIN

;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: EDLIN.SAL
;
; DESCRIPTIVE NAME: LINE TEXT EDITOR
;
; FUNCTION: EDLIN IS A SIMPLE, LINE ORIENTED TEXT EDITOR.  IT PROVIDES
;	    USERS OF DOS THE ABILITY TO CREATE AND EDIT TEXT FILES.
;
; ENTRY POINT: EDLIN
;
; INPUT: DOS COMMAND LINE
;	 EDLIN COMMANDS
;	 TEXT
;
; EXIT NORMAL: NA
;
; EXIT ERROR: NA
;
; INTERNAL REFERENCES:
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: EDLCMD1 - CONTAINS ROUTINES CALLED BY EDLIN
;		 EDLCMD1 - CONTAINS ROUTINES CALLED BY EDLIN
;		 EDLMES  - CONTAINS ROUTINES CALLED BY EDLIN
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK EDLIN+EDLCMD1+EDLCMD2+EDLMES+EDLPARSE
;
; REVISION HISTORY:
;
;	AN000	VERSION 4.00 - REVISIONS MADE RELATE TO THE FOLLOWING:
;
;				- IMPLEMENT SYSPARSE
;				- IMPLEMENT MESSAGE RETRIEVER
;				- IMPLEMENT DBCS ENABLING
;				- ENHANCED VIDEO SUPPORT
;				- EXTENDED OPENS
;				- SCROLLING ERROR
;
; COPYRIGHT: "MS DOS EDLIN UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;	     "LICENSED MATERIAL - PROPERTY OF Microsoft"
;
;
;	MICROSOFT REVISION HISTORY:
;									;
;	V1.02										;
;									;
;	V2.00	9/13/82  M.A.U						;
;									;
;		2/23/82  Rev. 13	N. P					;
;		    Changed to 2.0 system calls.				;
;		    Added an error message for READ-ONLY files		;
;									;
;		11/7/83  Rev. 14	N. P					;
;		    Changed to .EXE format and added Printf		;
;									;
;	V2.50	11/15/83 Rev. 1 	M.A. U					;
;		    Official dos 2.50 version. Some random bug		;
;		fixes and message changes.					;
;									;
;		11/30/83 Rev. 2 	MZ						;
;		    Close input file before rename.				;
;		    Jmp to replace after line edit				;
;									;
;		02/01/84 Rev. 3 	M.A. U			;
;		    Now it is called 3.00 dos. Repaired problem 	;
;		with using printf and having %'s as data.                       ;
;									;
;		02/15/84 MZ make out of space a fatal error with output;
;									;
;		03/28/84 MZ fixes bogus (totally) code in MOVE/COPY	;
;									;
;		04/02/84 MZ fixes DELETE and changes MOVE/COPY/EDIT	;
;									;
;	V3.20 08/29/86 Rev. 1 S.M. G					;
;									;
;		08/29/86 M001 MSKK TAR 593, TAB MOVEMENT		;
;									;
;		08/29/86 M002 MSKK TAR 157, BLKMOVE 1,1,1m, 1,3,1m	;
;									;
;		08/29/86 M003 MSKK TAR 476, EDLCMD2,MAKECAPS,kana char;
;									;
;		08/29/86 M004 MSKK TAR 191, Append load size		;
;									;
;		08/29/86 M005 IBMJ TAR Transfer Load command		;
;
;
;======================= END OF SPECIFICATIONS ===========================									;

include 'EDLEQU.ASM'

SUBTTL	Contants and Data areas
PAGE
;	extrn	parser_command:near		;an000;SYSPARSE

if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_CSTACK
end if

if SEGSEL = S_DATA
end if

;DG_	GROUP	CODE,CONST,cstack,DATA

if SEGSEL = S_CONST

;	public	bak,file$$$,delflg,loadmod,txt1,txt2

;	EXTRN	BADDRV_ptr:word,NDNAME_ptr:word,bad_vers_err:byte,opt_err_ptr:word
;	EXTRN	NOBAK_ptr:word,BADCOM_ptr:word,NEWFIL_ptr:word,DEST_ptr:word,MRGERR_ptr:word
;	EXTRN	NODIR_ptr:word,FILENM_ptr:word,ro_err_ptr:word,bcreat_ptr:word
;	EXTRN	TOO_MANY_ptr:word,lf_ptr:word,prompt_ptr:word
;	EXTRN	MemFul_Ptr:word

BAK	DB	".BAK",0

FILE$$$ DB	".$$$",0

fourth	db	0			;fourth parameter flag

loadmod db	0			;Load mode flag, 0 = ^Z marks the
					; end of a file, 1 = viceversa.
optchar db	"-"

TXT1	db 0
	rb      80H
TXT2	db 0
	rb      80H
DELFLG	DB	0
fNew	DB	0			; old file
HAVEOF	DB	0

end if

if SEGSEL = S_CSTACK
	rb      STKSIZ
end if

if SEGSEL = S_DATA

;	extrn	arg_buf_ptr:word		;an000;
;	extrn	line_num_buf_ptr:word		;an000;

;	public	path_name,ext_ptr,start,line_num,line_flag
;	public	arg_buf,wrt_handle,temp_path
;	public	current,pointer,qflg,editbuf,amnt_req,fname_len,delflg,lastlin
;	public	olddat,oldlen,newlen,srchflg,srchmod
;	public	comline,lstfnd,numpos,lstnum,last,srchcnt
;	public	rd_handle,haveof,ending,three4th,one4th

;	public	lc_adj				;an000;page length adj. factor
;	public	lc_flag 			;an000;display cont. flag
;	public	pg_count			;an000;lines left on screen
;	public	Disp_Len			;an000;display length
;	public	Disp_Width			;an000;display width
;	public	continue			;an000;boolean T/F
;	public	temp_path			;an000;pointer to filespec buf

label Video_Buffer word   ;an000;buffer for video attr
	db	0				;an000;dms;
	db	0				;an000;dms;
	dw	14				;an000;dms;
	dw	0				;an000;dms;
	db	?				;an000;dms;
	db	0				;an000;dms;
	dw	?				;an000;dms;# of colors
	dw	?				;an000;dms;# of pixels in width
	dw	?				;an000;dms;# of pixels in len.
	dw	?				;an000;dms;# of chars in width
	dw	?				;an000;dms;# of chars in length


video_org	rb      1 ;an000;original video mode on
						;      entry to EDLIN.
lc_adj		rb      1 ;an000;page length adj. factor
lc_flag 	rb      1 ;an000;display cont. flag
pg_count	rb      1 ;an000;lines left on screen
Disp_Len	rb      1 ;an000;display length
Disp_Width	rb      1 ;an000;display width
continue	rb      1 ;an000;boolean T/F


;-----------------------------------------------------------------------;
; This is a table that is sequentially filled via GetNum.  Any additions to it
; must be placed in the correct position.  Currently Param4 is known to be a
; count and thus is treated specially.

;	public	param1,param2,Param3,param4,ParamCt
PARAM1	rw      1
PARAM2	rw      1
PARAM3	rw      1
PARAM4	rw      1
ParamCt rw      1 ; count of passed parameters
	if	kanji			; Used in TESTKANJ:
LBTbl	rd      1 ;  long pointer to lead byte table
	end if ;  in the dos (from syscall 63H)

;-----------------------------------------------------------------------;

;PUBLIC PTR_1, PTR_2, PTR_3, OLDLEN, NEWLEN, LSTFND, LSTNUM, NUMPOS, SRCHCNT
;PUBLIC CURRENT, POINTER, ONE4TH, THREE4TH, LAST, ENDTXT, COPYSIZ
;PUBLIC COMLINE, LASTLIN, COMBUF, EDITBUF, EOL, QFLG, ENDING, SRCHFLG
;PUBLIC PATH_NAME, FNAME_LEN, RD_HANDLE, TEMP_PATH, WRT_HANDLE, EXT_PTR
;PUBLIC MRG_PATH_NAME, MRG_HANDLE, amnt_req, olddat, srchmod, MOVFLG, org_ds
if	kanji
;public	lbtbl
end if

;
; These comprise the known state of the internal buffer.  All editing
; functions must preserve these values.
;
CURRENT     rw      1  ; the 1-based index of the current line
POINTER     rw      1  ; pointer to the current line
ENDTXT	    rw      1  ; pointer to end of buffer. (at ^Z)
LAST	    rw      1  ; offset of last byte of memory
;
; The label Start is the beginning of the in-core buffer.
;

;
; Internal temporary pointers
;
PTR_1		rw      1
PTR_2		rw      1
PTR_3		rw      1

QFLG		rb      1  ; TRUE => query for replacement
OLDLEN	rw      1
NEWLEN	rw      1
LSTFND	rw      1
LSTNUM	rw      1
NUMPOS	rw      1
SRCHCNT     rw      1
ONE4TH	rw      1
THREE4TH    rw      1
COPYSIZ     rw      1  ; total length to copy
COPYLEN     rw      1  ; single copy length
COMLINE     rw      1
LASTLIN     rw      1
COMBUF	rb      82H
EDITBUF     rb      258
EOL		rb      1
ENDING	rb      1
SRCHFLG     rb      1
PATH_NAME   DB	    128 DUP(0)
FNAME_LEN   rw      1
RD_HANDLE   rw      1
TEMP_PATH   rb      128
WRT_HANDLE  rw      1
EXT_PTR     rw      1
MRG_PATH_NAME rb      128
MRG_HANDLE  rw      1
amnt_req    rw      1  ; amount of bytes requested to read
olddat	rb      1  ; Used in replace and search, replace
					; by old data flag (1=yes)
srchmod     rb      1  ; Search mode:	1=from current+1 to
					; end of buffer, 0=from beg.  of
					; buffer to the end (old way).
MOVFLG	    rb      1
org_ds	    rw      1  ;Orginal ds points to header block

arg_buf rb      258

EA_Flag 	db	FALSE		;an000; dms;set to false

EA_Buffer_Size	rw      1 ;an000; dms;EA buffer's size

label EA_Parm_List word  ;an000; dms;EA parms
		dw START;an000; dms;ptr to EA's
	dw DG_
		dw	0001h		;an000; dms;additional parms
		db	06h		;an000; dms;
		dw	0002h		;an000; dms;iomode


line_num    rw      1

line_flag   db	?,0
	EVEN			;align on word boundaries
;
; Byte before start of data buffer must be < 40H  !!!!!!
;
	    dw	0		;we scan backwards looking for
				;a character which can't be part
				;of a two-byte seqence.  This
				;double byte sequence will cause the back
				;scan to stop here.
label START word

end if


if SEGSEL = S_CODE

;ASSUME	CS:DG_,DS:NOTHING,ES:NOTHING,SS:CStack



;	extrn	pre_load_message:near		;an000;message loader
;	extrn	disp_fatal:near 		;an000;fatal message
;	extrn	printf:near			;an000;new PRINTF routine

;	extrn	findlin:near,shownum:near,loadbuf:near,crlf:near,lf:near
;	extrn	abortcom:near,delbak:near,unquote:near,kill_bl:near
;	extrn	make_caps:near,dispone:near,DISPLAY_:near,query:near
;	extrn	quit:near,make_cntrl:near,scanln:near,scaneof:near
;	extrn	fndfirst:near,fndnext:near,replace:near,memerr:near
;	extrn	xerror:near,bad_read:near,append:near
;	extrn	nocom:near,pager:near,list:near,search_from_curr:near
;	extrn	replac_from_curr:near,ewrite:near,wrt:near,delete:near


;	extrn	filespec:byte			;an000;parser's filespec
;	extrn	parse_switch_b:byte		;an000;result of switch scan

;	public	std_printf,command,chkrange,comerr
						;      exit from EDLIN

	IF	KANJI
;	extrn	testkanj:near
	end if

EDLIN:
	JMP	SHORT SIMPED

std_printf:            ;ac000;convert to proc

	push	dx
	call	printf
	pop	dx				;an000;balance the push
	ret

;std_printf	endp				;ac000;end proc

NONAME:
	MOV	DX,ndname_ptr
	JMP	xERROR

SIMPED:
	mov	[cs:org_ds],DS
	push	ax			;ac000;save for drive compare

	push	cs			;an000;exchange cs/es
	pop	es			;an000;

	push	cs			;an000;exchange cs/ds
	pop	ds			;an000;
;	assume	ds:DG_,es:DG_		;an000;establish addressibility

	MOV	byte [ENDING],0
	mov	sp,STACK_
	call	EDLIN_DISP_GET			;an000;get current video
						;      mode & set it to
						;      text

;=========================================================================
; invoke PRE_LOAD_MESSAGE here.  If the messages were not loaded we will
; exit with an appropriate error message.
;
;	Date	   : 6/14/87
;=========================================================================

	call	PRE_LOAD_MESSAGE	;an000;invoke SYSLOADMSG
;	if$	c			;an000;if the load was unsuccessful
	JNC IF1$$
		mov ah,Exit		;an000;exit EDLIN. PRE_LOAD_MESSAGE
					;      has said why we are exiting
		mov al,00h		;an000
		int 21h 		;an000;exit
;	endif$				;an000;
IF1$$:



VERS_OK:
;----- Check for valid drive specifier --------------------------------;

	pop	ax
	OR	AL,AL
	JZ	get_switch_char
	MOV	DX,baddrv_ptr
	JMP	xERROR
get_switch_char:
	MOV	AX,(Char_Oper SHL 8)	;GET SWITCH CHARACTER
	INT	21H
	CMP	DL,"/"
	JNZ	CMD_LINE		;IF NOT / , THEN NOT PC
	MOV	byte [optchar],"/" ;IN PC, OPTION CHAR = /

	IF	KANJI
	push	ds			; SAVE! all regs destroyed on this
	push	es
	push	si			; call !!
	mov	ax,(ECS_CALL shl 8) or 00h  ; get kanji lead tbl
	int	21h
;assume	ds:nothing
;assume	es:nothing
	mov	word [LBTbl],si
	mov	word [LBTbl+2],ds
	pop	si
	pop	es
	pop	ds
;assume	ds:DG_
;assume	es:DG_
	end if


CMD_LINE:
	push	cs
	pop	es
;	ASSUME	ES:DG_

;----- Process any options ------------------------------------------;

;=========================================================================
;  The system parser, called through PARSER_COMMAND, parses external
;  command lines.  In the case of EDLIN we are looking for two parameters
;  on the command line.
;
;  Parameter 1 - Filespec (REQUIRED)
;  Parameter 2 - \B switch (OPTIONAL)
;
;  PARSER_COMMAND  -  exit_normal : ffffh
;		      exit_error  : not = ffffh
;=========================================================================


	call	parser_command		;an000;invoke sysparse
					;      DMS:6/11/87
	cmp	ax,nrm_parse_exit	;an000;was it a good parse
;	if$	z			;an000;it was a good parse
	JNZ IF3$$
		call EDLIN_COMMAND	;an000;interface results
					;      into EDLIN
;	else$				;an000;
	JMP SHORT EN3$$
IF3$$:
		cmp ax,too_many 	;an000;too many operands
;		if$ z			;an000;we have too many
		JNZ IF5$$
		    jmp Badopt		;an000;say why and exit
;		endif$
IF5$$:

		cmp ax,op_missing	;an000;required parm missing
;		if$ z			;an000;missing parm
		JNZ IF7$$
		    jmp NONAME		;an000;say why and exit
;		endif$			;an000;
IF7$$:

		cmp ax,sw_missing	;an000;is it an invalid switch
;		if$ z			;an000;invalid switch
		JNZ IF9$$
		    jmp Badopt		;an000;say why and exit
;		endif$			;an000;
IF9$$:

;	endif$				;an000;
EN3$$:

;=========================================================================
;======================= begin .BAK check ================================
; Check for .BAK extension on the filename

	push	ds			;an000;save reg.
	push	cs			;an000;set up addressibility
	pop	ds			;an000;
;	assume	ds:DG_			;an000;

	push	ax			;an000;save reg.
	mov	ax,PATH_NAME        ;an000;point to path_name
	add	ax,[FNAME_LEN]		;an000;calculate end of path_name
	mov	si,ax			;an000;point to end of path_name
	pop	ax			;an000;restore reg.

	MOV	CX,4			;compare 4 bytes
	SUB	SI,4			;Point 4th to last char
	MOV	DI,BAK        ;Point to string ".BAK"
	REPE	CMPSB			;Compare the two strings
	pop	ds
;	ASSUME	DS:NOTHING
	JNZ	NOTBAK
	JMP	HAVBAK

;======================= end .BAK check ==================================

;======================= begin NOTBAK ====================================
; we have a file without a .BAK extension, try to open it

NOTBAK:
	push	ds
	push	cs
	pop	ds
;	ASSUME	DS:DG_

;=========================================================================
; implement EXTENDED OPEN
;=========================================================================

	push	es			;an000;save reg.
	mov	bx,rw_			;an000;open for read/write
	mov	cx,attr 		;an000;file attributes
	mov	dx,rw_flag		;an000;action to take on open
	mov	di,0ffffh		;an000;nul parm list

	call	EXT_OPEN1		;an000;open for R/W;DMS:6/10/87
	pop	es			;an000;restore reg.

;=========================================================================
	pop	ds
;	ASSUME	DS:NOTHING
	JC	CHK_OPEN_ERR		;an open error occurred
	MOV	[cs:RD_HANDLE],AX ;Save the handle

	call	Calc_Memory_Avail	;an000; dms;enough memory?

	mov	bx,[cs:RD_HANDLE] ;an000; dms;set up for call
	call	Query_Extend_Attrib	;an000; dms;memory required?

	cmp	dx,cx			;an000; dms;enough memory for EA's?
;	if$	b			;an000; dms;no
	JNB IF12$$
		call	EA_Fail_Exit	;an000; dms;say why and exit
;	endif$				;an000; dms;
IF12$$:

	mov	bx,[cs:RD_HANDLE] ;an000; dms;set up for call
	mov	byte [cs:EA_Flag],TRUE ;an000; dms;
	call	Get_Extended_Attrib	;an000; dms;get attribs

	Jmp	HAVFIL			;work with the opened file

;======================= end NOTBAK ======================================

Badopt:
	MOV	DX,opt_err_ptr     ;Bad option specified
	JMP	xERROR

;=========================================================================
;
; The open of the file failed.	We need to figure out why and report the
; correct message. The circumstances we can handle are:
;
;   open returns pathnotfound => bad drive or file name
;   open returns toomanyopenfiles => too many open files
;   open returns access denied =>
;	chmod indicates read-only => cannot edit read only file
;	else => file creation error
;   open returns filenotfound =>
;	creat ok => close, delete, new file
;	creat fails => file creation error
;   else => file cre
;

CHK_OPEN_ERR:
	cmp	ax,error_path_not_found
	jz	BadDriveError
	cmp	ax,error_too_many_open_files
	jz	TooManyError
	cmp	ax,error_access_denied
	jnz	CheckFNF
	push	ds
	push	cs
	pop	ds
;	assume	ds:DG_
	mov	ax,(CHMod shl 8)
	MOV	DX,PATH_NAME
	int	21h
	jc	FileCreationError
	test	cx,attr_read_only
	jz	FileCreationError
	jmp	ReadOnlyError

CheckFNF:
	cmp	ax,error_file_not_found
	jnz	FileCreationError
;
; Try to create the file to see if it is OK.
;
	push	ds
	push	cs
	pop	ds
;	assume ds:DG_
;=========================================================================
; implement EXTENDED OPEN
;=========================================================================

	mov	bx,rw_			;an000;open for read/write
	mov	cx,attr 		;an000;file attributes
	mov	dx,creat_flag		;an000;action to take on open
	mov	di,0ffffh		;an000;null parm list
	call	EXT_OPEN1		;an000;create file;DMS:6/10/87

;=========================================================================

	pop	ds
;	assume	ds:nothing
	jc	CreateCheck
	mov	bx,ax
	mov	ah,Close
	int	21h
	push	ds
	push	cs
	pop	ds
;	assume	ds:DG_
	mov	ah,Unlink
	MOV	DX,PATH_NAME
	int	21h
	pop	ds
;	assume	ds:nothing
	jc	FileCreationError	; This should NEVER be taken!!!
	MOV	byte [cs:HAVEOF],0FFH ; Flag from a system 1.xx call
	MOV	byte [cs:fNew],-1
	JMP	HAVFIL

CreateCheck:
	cmp	ax,error_access_denied
	jnz	BadDriveError
DiskFull:
	MOV	DX,nodir_ptr
	jmp	xERROR

FileCreationError:
	mov	dx,bcreat_ptr
	jmp	xERROR

ReadOnlyError:
	MOV	DX,ro_err_ptr
	jmp	xERROR

BadDriveError:
	MOV	DX,baddrv_ptr
	jmp	xERROR

TooManyError:
	MOV	DX,too_many_ptr
	jmp	xERROR


CREAT_ERR:
	CMP	byte [cs:DELFLG],0
	JNZ	DiskFull
	push	cs
	pop	ds
	CALL	DELBAK
	JMP	MAKFIL

HAVBAK:
	MOV	DX,nobak_ptr
	JMP	xERROR

HAVFIL:
	push	cs
	pop	ds
;	ASSUME	DS:DG_
	CMP	byte [fNew],0
	JZ	MakeBak
	MOV	DX,newfil_ptr        ; Print new file message
	call	std_printf
MakeBak:
	MOV	SI,PATH_NAME
	MOV	CX,[FNAME_LEN]
	PUSH	CX
	MOV	DI,TEMP_PATH
	REP	MOVSB
	DEC	DI
	MOV	DX,DI
	POP	CX
	MOV	AL,"."
	STD
	REPNE	SCASB
	JZ	FOUND_EXT
	MOV	DI,DX			;Point to last char in filename
FOUND_EXT:
	CLD
	INC	DI
	MOV	[EXT_PTR],DI
	MOV	SI,FILE$$$
	MOV	CX,5
	REP	MOVSB

;Create .$$$ file to make sure directory has room
MAKFIL:

;=========================================================================
; implement EXTENDED OPEN
;=========================================================================

	mov	bx,rw_			;an000;open for read/write
	mov	cx,attr 		;an000;file attributes
	mov	dx,creat_open_flag	;an000;action to take on open
	cmp	byte [EA_Flag],TRUE ;an000;EA_Buffer used?
;	if$	e			;an000;yes
	JNE IF14$$
		mov	di,EA_Parm_List        ;an000; point to buffer
;	else$				;an000;
	JMP SHORT EN14$$
IF14$$:
		mov	di,0ffffh	;an000;nul parm list
;	endif$				;an000;
EN14$$:
	call	EXT_OPEN2		;an000;create file;DMS:6/10/87

;=========================================================================

	JC	CREAT_ERR
	MOV	[WRT_HANDLE],AX
;
; We determine the size of the available memory.  Use the word in the PDB at
; [2] to determine the number of paragraphs.  Then truncate this to 64K at
; most.
;
	push	ds				;save ds for size calc
	mov	ds,[org_ds]
	MOV	CX,[ds:2]
	MOV	DI,CS
	SUB	CX,DI
	CMP	CX,1000h
	JBE	GotSize
	MOV	CX,0FFFh
GotSize:
	SHL	CX,1
	SHL	CX,1
	SHL	CX,1
	SHL	CX,1
	pop	ds				;restore ds after size calc
	DEC	CX
	MOV	[LAST],CX
	MOV	DI,START
	TEST	byte [fNew],-1
	JNZ	SAVEND
	SUB	CX,START        ;Available memory
	SHR	CX,1			;1/2 of available memory
	MOV	AX,CX
	SHR	CX,1			;1/4 of available memory
	MOV	[ONE4TH],CX		;Save amount of 1/4 full
	ADD	CX,AX			;3/4 of available memory
	MOV	DX,CX
	ADD	DX,START
	MOV	[THREE4TH],DX		;Save pointer to 3/4 full
	MOV	DX,START
SAVEND:
	CLD
	MOV	byte [DI],1AH
	MOV	[ENDTXT],DI
	MOV	byte [COMBUF],128
	MOV	byte [EDITBUF],255
	MOV	byte [EOL],10
	MOV	word [POINTER],START
	MOV	word [CURRENT],1
	MOV	word [ParamCt],1
	MOV	word [PARAM1],0 ;M004 Leave room in memory, was -1
	TEST	byte [fNew],-1
	JNZ	COMMAND
;
; The above setting of PARAM1 to -1 causes this call to APPEND to try to read
;  in as many lines that will fit, BUT.... What we are doing is simulating
;  the user issuing an APPEND command, and if the user asks for more lines
;  than we get then an "Insufficient memory" error occurs. In this case we
;  DO NOT want this error, we just want as many lines as possible read in.
;  The twiddle of ENDING suppresses the memory error
;
	MOV	byte [ENDING],1     ;Suppress memory errors
	CALL	APPEND
	MOV	byte [ENDING],0 ; restore correct initial value

BREAK	<Main COMMAND loop>

;
; Main read/parse/execute loop.  We reset the stack all the time as there
; are routines that JMP back here.  Don't blame me; Tim Paterson write this.
;
COMMAND:
	push	cs				;an000;set up addressibility
	pop	ds				;an000;
	push	cs				;an000;
	pop	es				;an000;
;	assume	ds:DG_,es:DG_			;an000;

	MOV	SP, STACK_
	MOV	AX,(Set_Interrupt_Vector SHL 8) OR 23H
	MOV	DX,ABORTCOM
	INT	21H
	mov	dx,prompt_ptr
	call	std_printf
	MOV	DX,COMBUF
	MOV	AH,Std_Con_String_Input
	INT	21H
	MOV	word [COMLINE],COMBUF + 2
	mov	dx,lf_ptr
	call	std_printf
PARSE:
	MOV	word [PARAM2],0
	MOV	word [PARAM3],0
	MOV	word [PARAM4],0
	mov	byte [fourth],0 ;reset the fourth parameter flag
	MOV	byte [QFLG],0
	MOV	SI,[COMLINE]
	MOV	BP,PARAM1
	XOR	DI,DI
CHKLP:
	CALL	GETNUM
;
; AL has first char after arg
;
	MOV	[ds:BP+DI],DX
	ADD	DI,2

	MOV	[ParamCt],DI ; set up count of parameters
	SHR	[ParamCt],1 ; convert to index (1-based)

	CALL	SKIP1			; skip to next parameter
	CMP	AL,","			; is there a comma?
	JZ	CHKLP			; if so, then get another arg
	DEC	SI			; point at char next
	CALL	kill_bl 		; skip all blanks
	CMP	AL,"?"			; is there a ?
	JNZ	DISPATCH		; no, got command letter
	MOV	byte [QFLG],-1 ; signal query
	CALL	kill_bl
DISPATCH:
	CMP	AL,5FH
	JBE	UPCASE
	cmp	al,"z"
	ja	UPCASE
	AND	AL,5FH
UPCASE:
	MOV	DI,COMTAB
	MOV	CX,NUMCOM
	REPNE	SCASB
	JNZ	COMERR
	SUB	DI,1+COMTAB        ; convert to index
	MOV	BX,DI
	MOV	AX,[PARAM2]
	OR	AX,AX
	JZ	PARMOK
	CMP	AX,[PARAM1]
	JB	COMERR			; Param. 2 must be >= param 1
PARMOK:
	MOV	[COMLINE],SI
	SHL	BX,1
	CALL	[BX+TABLE]
COMOVER:
	MOV	SI,[COMLINE]
	CALL	kill_bl
	CMP	AL,0DH
	JZ	COMMANDJ
	CMP	AL,1AH
	JZ	DELIM
	CMP	AL,";"
	JNZ	NODELIM
DELIM:
	INC	SI
NODELIM:
	DEC	SI
	MOV	[COMLINE],SI
	JMP	PARSE

COMMANDJ:
	JMP	COMMAND

SKIP1:
	DEC	SI
	CALL	kill_bl
ret1:	return

BREAK	<Range Checking and argument parsing>

;
; People call here.  we need to reset the stack.
;   Inputs: BX has param1
;   Outputs: Returns if BX <= Param2
;

CHKRANGE:
	CMP	word [PARAM2],0
	retz
	CMP	BX,[PARAM2]
	JBE	ret1
	POP	DX			; clean up return address
COMERR:
	MOV	DX,badcom_ptr
COMERR1:
	call	std_printf
	JMP	COMMAND

;
; GetNum parses off 1 argument from the command line.  Argument forms are:
;   nnn     a number < 65536
;   +nnn    current line + number
;   -nnn    current line - number
;   .	    current line
;   #	    lastline + 1
;
;

GETNUM:
	CALL	kill_bl
	cmp	di,6			;Is this the fourth parameter?
	jne	sk1
	mov	byte [fourth],1 ;yes, set the flag
sk1:
	CMP	AL,"."
	JZ	CURLIN
	CMP	AL,"#"
	JZ	MAXLIN
	CMP	AL,"+"
	JZ	FORLIN
	CMP	AL,"-"
	JZ	BACKLIN
	MOV	DX,0
	MOV	CL,0			;Flag no parameter seen yet
NUMLP:
	CMP	AL,"0"
	JB	NUMCHK
	CMP	AL,"9"
	JA	NUMCHK
	CMP	DX,6553 		;Max line/10
	JAE	COMERR			;Ten times this is too big
	MOV	CL,1			;Parameter digit has been found
	SUB	AL,"0"
	MOV	BX,DX
	SHL	DX,1
	SHL	DX,1
	ADD	DX,BX
	SHL	DX,1
	CBW
	ADD	DX,AX
	LODSB
	JMP	SHORT NUMLP
NUMCHK:
	CMP	CL,0
	retz
	OR	DX,DX
	JZ	COMERR			;Don't allow zero as a parameter
	return

CURLIN:
	cmp	byte [fourth],1 ;the fourth parameter?
	je	comerra 		;yes, an error
	MOV	DX,[CURRENT]
	LODSB
	return
MAXLIN:
	cmp	byte [fourth],1 ;the fourth parameter?
	je	comerra 		;yes, an error
	MOV	DX,1
	MOV	AL,0Ah
	PUSH	DI
	MOV	DI,START
	MOV	CX,[ENDTXT]
	SUB	CX,DI
MLoop:
	JCXZ	MDone
	REPNZ	SCASB
	JNZ	MDone
	INC	DX
	JMP	MLoop
MDone:
	POP	DI
	LODSB
	return
FORLIN:
	cmp	byte [fourth],1 ;the fourth parameter?
	je	comerra 		;yes, an error
	CALL	GETNUM
	ADD	DX,[CURRENT]
	return
BACKLIN:
	cmp	byte [fourth],1 ;the fourth parameter?
	je	comerra 		;yes, an error
	CALL	GETNUM
	MOV	BX,[CURRENT]
	SUB	BX,DX
	JA	OkLin			; if negative or zero
	MOV	BX,1			; use first line
OkLin:
	MOV	DX,BX
	return

comerra:
	jmp	COMERR

BREAK	<DISPATCH TABLE>

;-----------------------------------------------------------------------;
;   Careful changing the order of the next two tables.	They are linked and
;   changes should be be to both.

COMTAB	DB	13,";ACDEILMPQRSTW"
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
NUMCOM	=	$-COMTAB

TABLE	DW	NOCOM			; Blank line
	DW	NOCOM			; ;
	DW	APPEND			; A(ppend)
	DW	COPY			; C(opy)
	DW	DELETE			; D(elete)
	DW	ENDED			; E(xit)
	DW	INSERT			; I(nsert)
	DW	LIST			; L(ist)
	DW	MOVE			; M(ove)
	DW	PAGER			; P(age)
	DW	QUIT			; Q(uit)
	dw	replac_from_curr	; R(eplace)
	dw	search_from_curr	; S(earch)
	DW	MERGE			; T(merge)
	DW	EWRITE			; W(rite)

ERRORJ:
	JMP	COMERR
ERROR1J:
	JMP	COMERR1

BREAK	<MOVE and COPY commands>

;PUBLIC MOVE
MOVE:
	CMP	word [ParamCt],3
	JNZ	ERRORJ
	MOV	byte [MOVFLG],1
	JMP	SHORT BLKMOVE

;PUBLIC COPY
COPY:
	CMP	word [ParamCt],3
	JB	ERRORJ
	MOV	byte [MOVFLG],0
;
; We are to move/copy a number of lines from one range to another.
;
; Memory looks like this:
;
;   START:	line 1
;		...
;   pointer->	line n		Current has n in it
;		...
;		line m
;   endtxt->	^Z
;
; The algoritm is:
;
;   Bounds check on args.
;   set ptr1 and ptr2 to range before move
;   set copysiz to number to move
;   open up copysize * count for destination
;   if destination is before ptr1 then
;	add copysize * count to both ptrs
;   while count > 0 do
;	move from ptr1 to destination for copysize bytes
;	count --
;   if moving then
;	move from ptr2 through end to ptr1
;   set endtxt to last byte moved.
;   set current, pointer to original destination
;

BLKMOVE:
;
; Make sure that all correct arguments are specified.
;
	MOV	BX,[PARAM3]		; get destination of move/copy
	OR	BX,BX			; must be specified (non-0)
	MOV	DX,dest_ptr
	JZ	ERROR1J 		; is 0 => error
;
; get arg 1 (defaulting if necessary) and range check it.
;
	MOV	BX,[PARAM1]		; get first argument
	OR	BX,BX			; do we default it?
	JNZ	NXTARG			; no, assume it is OK.
	MOV	BX,[CURRENT]		; Defaults to the current line
	CALL	CHKRANGE		; Make sure it is good.
	MOV	[PARAM1],BX		; set it
NXTARG:
	CALL	FINDLIN 		; find first argument line
	JNZ	ERRORJ			; line not found
	MOV	[PTR_1],DI
;
; get arg 2 (defaulting if necessary) and range check it.
;
	MOV	BX,[PARAM2]		; Get the second parameter
	OR	BX,BX			; do we default it too?
	JNZ	HAVARGS 		; Nope.
	MOV	BX,[CURRENT]		; Defaults to the current line
	MOV	[PARAM2],BX		; Stash it away
HAVARGS:
	CALL	FINDLIN
	JNZ	ERRORJ			; line not found
	MOV	BX,[PARAM2]
	INC	BX			;Get pointer to line Param2+1
	CALL	FINDLIN
	MOV	[PTR_2],DI		;Save it
;
; We now have true line number arguments and pointers to the relevant places.
; ptr_1 points to beginning of region and ptr_2 points to first byte beyond
; that region.
;
; Check args for correct ordering of first two arguments
;
	mov	dx,[PARAM1]
	cmp	dx,[PARAM2]
	jbe	havargs1		; first must be <= second
	jmp	COMERR
havargs1:
;
; make sure that the third argument is not contained in the first range
;
	MOV	DX,[PARAM3]
	CMP	DX,[PARAM1]		; third must be <= first or
	JBE	NOERROR
	CMP	DX,[PARAM2]
	JA	NOERROR 		; third must be > last
	JMP	COMERR
NOERROR:
;
; Determine number to move
;
	MOV	CX,[PTR_2]
	SUB	CX,[PTR_1] ; Calculate number of bytes to copy
	MOV	[COPYSIZ],CX
	MOV	[COPYLEN],CX ; Save for individual move.
	MOV	AX,[PARAM4]		; Was count defaulted?
	OR	AX,AX
	JZ	SizeOK			; yes, CX has correct value
	MUL	[COPYSIZ]		; convert to true size
	MOV	CX,AX			; move to count register
	OR	DX,DX			; overflow?
	JZ	SizeOK			; no
	JMP	MEMERR			; yes, bomb.
SizeOK:
	MOV	[COPYSIZ],CX
;
; Check to see that we have room to grow by copysiz
;
	MOV	AX,[ENDTXT]		; get pointer to last byte
	MOV	DI,[LAST]		; get offset of last location in memory
	SUB	DI,AX			; remainder of space
	CMP	DI,CX			; is there at least copysiz room?
	JAE	HAV_ROOM		; yes
	JMP	MEMERR
HAV_ROOM:
;
; Find destination of move/copy
;
	MOV	BX,[PARAM3]
	CALL	FINDLIN
	MOV	[PTR_3],DI
;
; open up copysiz bytes of space at destination
;
;	move (p3, p3+copysiz, endtxt-p3);
;
	MOV	SI,[ENDTXT] ; get source pointer to end
	MOV	CX,SI
	SUB	CX,DI			; number of bytes from here to end
	INC	CX			; remember ^Z at end
	MOV	DI,SI			; destination starts at end
	ADD	DI,[COPYSIZ]		; plus size we are opening
	MOV	[ENDTXT],DI		; new end point
	STD				; go backwards
	REP	MOVSB			; and store everything
	CLD				; go forward
;
; relocate ptr_1 and ptr_2 if we moved them
;
	MOV	BX,[PTR_3]
	CMP	BX,[PTR_1] ; was dest before source?
	JA	NoReloc 		; no, above. no relocation
	MOV	BX,[COPYSIZ]
	ADD	[PTR_1],BX
	ADD	[PTR_2],BX ; relocate pointers
NoReloc:
;
; Now we copy for count times copylen bytes from ptr_1 to ptr_3
;
;	move (ptr_1, ptr_3, copylen);
;
	MOV	BX,[PARAM4] ; count (0 and 1 are both 1)
	MOV	DI,[PTR_3] ; destination
CopyText:
	MOV	CX,[COPYLEN] ; number to move
	MOV	SI,[PTR_1] ; start point
	REP	MOVSB			; move the bytes
	SUB	BX,1			; exhaust count?
	JG	CopyText		; no, go for more
;
; If we are moving
;
	CMP	byte [MOVFLG],0
	JZ	CopyDone
;
; Delete the source text between ptr_1 and ptr_2
;
;	move (ptr_2, ptr_1, endtxt-ptr_2);
;
	MOV	DI,[PTR_1] ; destination
	MOV	SI,[PTR_2] ; source
	MOV	CX,[ENDTXT] ; pointer to end
	SUB	CX,SI			; number of bytes to move
	CLD				; forwards
	REP	MOVSB
	MOV	byte [es:DI],1Ah     ; remember ^Z terminate
	MOV	[ENDTXT],DI ; new end of file
;
; May need to relocate current line (parameter 3).
;
	MOV	BX,[PARAM3] ; get new current line
	CMP	BX,[PARAM1] ; do we need to relocate
	JBE	CopyDone		; no, current line is before removed M002
	ADD	BX,[PARAM1] ; add in first
	SUB	BX,[PARAM2] ; current += first-last - 1;
	DEC	BX
	MOV	[PARAM3],BX
CopyDone:
;
; we are done.	Make current line the destination
;
	MOV	BX,[PARAM3] ; set parameter 3 to be current
	CALL	FINDLIN
	MOV	[POINTER],DI
	MOV	[CURRENT],BX
	return

BREAK	<MOVEFILE - Open up a hole in the internal file>

;
;   MoveFile moves the text in the buffer to create a hole
;
;   Inputs:	DX is spot in buffer for destination
;		DI is spot in buffer for source
MOVEFILE:
	MOV	CX,[ENDTXT]		;Get End-of-text marker
	MOV	SI,CX
	SUB	CX,DI			;Calculate number of bytes to copy
	INC	CX			; remember ^Z
	MOV	DI,DX
	STD
	REP	MOVSB			;Copy CX bytes
	XCHG	SI,DI
	CLD
	INC	DI
	MOV	BP,SI
SETPTS:
	MOV	[POINTER],DI		;Current line is first free loc
	MOV	[CURRENT],BX		;   in the file
	MOV	[ENDTXT],BP		;End-of-text is last free loc before
	return

NAMERR:
	cmp	ax,error_file_not_found
	jne	otherMergeErr
	MOV	DX,filenm_ptr
	JMP	COMERR1

otherMergeErr:
	MOV	DX,baddrv_ptr
	JMP	COMERR1

;PUBLIC MERGE
MERGE:
	CMP	word [ParamCt],1
	JZ	MergeOK
	JMP	COMERR
MergeOK:
	CALL	kill_bl
	DEC	SI
	MOV	DI,MRG_PATH_NAME
	XOR	CX,CX
	CLD
MRG1:
	LODSB
	CMP	AL," "
	JE	MRG2
	CMP	AL,9
	JE	MRG2
	CMP	AL,CR
	JE	MRG2
	CMP	AL,";"
	JE	MRG2
	STOSB
	JMP	SHORT MRG1
MRG2:
	MOV	byte [DI],0
	DEC	SI
	MOV	[COMLINE],SI

;=========================================================================
; implement EXTENDED OPEN
;=========================================================================

	push	es			;an000;save reg.
	mov	bx,ext_read		;an000;open for read
	mov	cx,attr 		;an000;file attributes
	mov	dx,open_flag		;an000;action to take on open
	mov	di,0ffffh		;an000;null parm list
	call	EXT_OPEN3		;an000;create file;DMS:6/10/87
	pop	es			;an000;restore reg.

;=========================================================================

	JC	NAMERR

	MOV	[MRG_HANDLE],AX
	MOV	AX,(Set_Interrupt_Vector SHL 8) OR 23H
	MOV	DX,ABORTMERGE
	INT	21H
	MOV	BX,[PARAM1]
	OR	BX,BX
	JNZ	MRG
	MOV	BX,[CURRENT]
	CALL	CHKRANGE
MRG:
	CALL	FINDLIN
	MOV	BX,DX
	MOV	DX,[LAST]
	CALL	MOVEFILE
	MOV	DX,[POINTER]
	MOV	CX,[ENDTXT]
	SUB	CX,[POINTER]
	PUSH	CX
	MOV	BX,[MRG_HANDLE]
	MOV	AH,Read
	INT	21H
	POP	DX
	MOV	CX,AX
	CMP	DX,CX
	JA	FILEMRG 			; M005
	MOV	DX,mrgerr_ptr
	call	std_printf
	MOV	CX,[POINTER]
	JMP	SHORT RESTORE_
FILEMRG:
	ADD	CX,[POINTER]
	MOV	SI,CX
	dec	si
	LODSB
	CMP	AL,1AH
	JNZ	RESTORE_
	dec	cx
RESTORE_:
	MOV	DI,CX
	MOV	SI,[ENDTXT]
	INC	SI
	MOV	CX,[LAST]
	SUB	CX,SI
	inc	cx			; remember ^Z
	REP	MOVSB
	dec	di			; unremember ^Z
	MOV	[ENDTXT],DI
	MOV	BX,[MRG_HANDLE]
	MOV	AH,Close
	INT	21H
	return

;PUBLIC INSERT
INSERT:
	CMP	word [ParamCt],1
	JBE	OKIns
	JMP	COMERR
OKIns:
	MOV	AX,(Set_Interrupt_Vector SHL 8) OR 23H	;Set vector 23H
	MOV	DX,ABORTINS
	INT	21H
	MOV	BX,[PARAM1]
	OR	BX,BX
	JNZ	INS_
	MOV	BX,[CURRENT]
	CALL	CHKRANGE
INS_:
	CALL	FINDLIN
	MOV	BX,DX
	MOV	DX,[LAST]
	CALL	MOVEFILE
INLP:
	CALL	SETPTS			;Update the pointers into file
	CALL	SHOWNUM
	MOV	DX,EDITBUF
	MOV	AH,Std_Con_String_Input
	INT	21H
	CALL	LF
	MOV	SI,2 + EDITBUF
	CMP	byte [SI],1AH
	JZ	ENDINS
;-----------------------------------------------------------------------
	call	unquote 		;scan for quote chars if any
;-----------------------------------------------------------------------
	MOV	CL,[SI-1]
	MOV	CH,0
	MOV	DX,DI
	INC	CX
	ADD	DX,CX
	JC	MEMERRJ1
	JZ	MEMERRJ1
	CMP	DX,BP
	JB	MEMOK
MEMERRJ1:
	CALL	END_INS
	JMP	MEMERR
MEMOK:
	REP	MOVSB
	MOV	AL,10
	STOSB
	INC	BX
	JMP	SHORT INLP

ABORTMERGE:
	MOV	DX,START
	MOV	AH,Set_DMA
	INT	21H

ABORTINS:
	MOV	AX,CS			;Restore segment registers
	MOV	DS,AX
	MOV	ES,AX
	MOV	AX,CSTACK
	MOV	SS,AX
	MOV	SP,STACK_
	STI
	CALL	CRLF
	CALL	ENDINS
	JMP	COMOVER

ENDINS:
	CALL	END_INS
	return

END_INS:
	MOV	BP,[ENDTXT]
	MOV	DI,[POINTER]
	MOV	SI,BP
	INC	SI
	MOV	CX,[LAST]
	SUB	CX,BP
	REP	MOVSB
	DEC	DI
	MOV	[ENDTXT],DI
	MOV	AX,(Set_Interrupt_Vector SHL 8) OR 23H
	MOV	DX,ABORTCOM
	INT	21H
	return


FILLBUF:
	MOV	word [PARAM1],-1 ;Read in max. no of lines
	MOV	word [ParamCt],1
	CALL	APPEND
	MOV	word [PARAM1],0
;PUBLIC ENDED
ENDED:

;Write text out to .$$$ file

	CMP	word [ParamCt],1
	JZ	Ended1
CERR:	JMP	COMERR
Ended1:
	CMP	word [PARAM1],0
	JNZ	CERR
	MOV	byte [ENDING],1     ;Suppress memory errors
	MOV	BX,-1			;Write max. no of lines
	CALL	WRT
	TEST	byte [HAVEOF],-1
	JZ	FILLBUF
	MOV	DX,[ENDTXT]
	MOV	CX,1
	MOV	BX,[WRT_HANDLE]
	MOV	AH,Write
	INT	21H			;Write end-of-file byte

;Close input file			; MZ 11/30
					; MZ 11/30
	MOV	BX,[RD_HANDLE]		; MZ 11/30
	MOV	AH,Close		; MZ 11/30
	INT	21H			; MZ 11/30

;Close .$$$ file

	MOV	BX,[WRT_HANDLE]
	MOV	AH,Close
	INT	21H

;Rename original file .BAK

	MOV	DI,[EXT_PTR]
	MOV	SI,BAK
	MOVSW
	MOVSW
	MOVSB
	MOV	DX,PATH_NAME
	MOV	DI,TEMP_PATH
	MOV	AH,Rename
	INT	21H
	MOV	DI,[EXT_PTR]
	MOV	SI,FILE$$$
	MOVSW
	MOVSW
	MOVSB

;Rename .$$$ file to original name

	MOV	DX,TEMP_PATH
	MOV	DI,PATH_NAME
	MOV	AH,Rename
	INT	21H
						;      mode
	mov	ah,Exit
	xor	al,al
	int	21h

;=========================================================================
; EDLIN_DISP_GET: This routine will give us the attributes of the
;		  current display, which are to be used to restore the screen
;		  back to its original state on exit from EDLIN.  We also
;		  set the screen to a text mode here with an 80 X 25 color
;		  format.
;
;	Inputs	: VIDEO_GET - 0fH (get current video mode)
;		  VIDEO_SET - 00h (set video mode)
;		  VIDEO_TEXT- 03h (80 X 25 color mode)
;
;	Outputs : VIDEO_ORG - Original video attributes on entry to EDLIN
;
;=========================================================================

EDLIN_DISP_GET:            ;an000;video attributes

	push	ax				;an000;save affected regs.
	push	bx				;an000;
	push	cx				;an000;
	push	dx				;an000;
	push	si				;an000;
	push	ds				;an000;

	push	cs				;an000;exchange cs/ds
	pop	ds				;an000;

	mov	ax,440Ch			;an000;generic ioctl
	mov	bx,std_out			;an000;Console
	mov	cx,(display_attr shl 8) or Get_Display ;an000;get display
	mov	dx,Video_Buffer        ;an000;buffer for video attr.
	int	21h				;an000;
;	if$	nc				;an000;function returned a
	JC IF17$$
						;      buffer
		mov	si,dx			;an000;get pointer
		mov	ax,word [si+Display_Length_Char]      ;an000;get video len.
		dec	ax			;an000;allow room for message
		mov	[Disp_Len],al ;an000;put it into var.
		mov	ax,word [si+Display_Width_Char]     ;an000;get video width
		mov	[Disp_Width],al ;an000;put it into var.
;	else$					;an000;function failed use
	JMP SHORT EN17$$
IF17$$:
						;      default values
		mov	al,Def_Disp_Len 	;an000;get default length
		dec	al			;an000;leave room for messages
		mov	[Disp_Len],al ;an000;use default length
		mov	byte [Disp_Width],Def_Disp_Width ;an000;use default width
;	endif$					;an000;
EN17$$:

	pop	ds				;an000;restore affected regs.
	pop	si				;an000;
	pop	dx				;an000;
	pop	cx				;an000;
	pop	bx				;an000;
	pop	ax				;an000;

	ret					;an000;return to caller

;EDLIN_DISP_GET	endp				;an000;end proc.


;=========================================================================
; EXT_OPEN1 : This routine opens a file for read/write access.	If the file
;	      if not present for opening the open will fail and return with a
;	      carry set.
;
;	Inputs : BX - Open mode
;		 CX - File attributes
;		 DX - Open action
;
;	Outputs: CY - If error
;
;	Date	   : 6/10/87
;=========================================================================

EXT_OPEN1:            ;an000;open for R/W

;	assume	ds:DG_
	push	ds				;an000;save regs
	push	si				;an000;

	mov	ah,ExtOpen			;an000;extended open
	mov	al,0				;an000;reserved by system
	mov	si,PATH_NAME         ;an000;point to PATH_NAME

	int	21h				;an000;invoke function
	pop	si				;an000;restore regs
	pop	ds				;an000;

	ret					;an000;return to caller

;EXT_OPEN1	endp				;an000;end proc.

;=========================================================================
; EXT_OPEN2  : This routine will attempt to create a file for read/write
;	       access.	If the files exists the create will fail and return
;	       with the carry set.
;
;	Inputs : BX - Open mode
;		 CX - File attributes
;		 DX - Open action
;
;	Outputs: CY - If error
;
;	Date	   : 6/10/87
;=========================================================================

EXT_OPEN2:            ;an000;create a file

;	assume	ds:DG_
	push	ds				;an000;save regs
	push	si				;an000;

	mov	ah,ExtOpen			;an000;extended open
	mov	al,0				;an000;reserved by system
	mov	si,TEMP_PATH         ;an000;point to TEMP_PATH

	int	21h				;an000;invoke function

	pop	si				;an000;restore regs
	pop	ds				;an000;

	ret					;an000;return to caller

;EXT_OPEN2	endp				;an000;end proc.

;=========================================================================
; EXT_OPEN3  : This routine will attempt to create a file for read
;	       access.	If the files exists the create will fail and return
;	       with the carry set.
;
;	Inputs : BX - Open mode
;		 CX - File attributes
;		 DX - Open action
;
;	Outputs: CY - If error
;
;	Date	   : 6/10/87
;=========================================================================

EXT_OPEN3:            ;an000;create a file

;	assume	ds:DG_
	push	ds				;an000;save regs
	push	si				;an000;

	mov	ah,ExtOpen			;an000;extended open
	mov	al,0				;an000;reserved by system
	mov	si,MRG_PATH_NAME        ;an000;point to mrg_path_name

	int	21h				;an000;invoke function

	pop	si				;an000;restore regs
	pop	ds				;an000;

	ret					;an000;return to caller

;EXT_OPEN3	endp				;an000;end proc.


;=========================================================================
; EDLIN_COMMAND : This routine provides an interface between the new
;		  parser and the existing logic of EDLIN.  We will be
;		  interfacing the parser with three existing variables.
;
;	Inputs : FILESPEC - Filespec entered by the user and passed by
;			    the parser.
;
;		 PARSE_SWITCH_B - Contains the result of the parse for the
;				/B switch.  This is passed by the parser.
;
;	Outputs: PATH_NAME - Filespec
;		 LOADMOD   - Flag for /B switch
;		 FNAME_LEN - Length of filespec
;
;	Date	   : 6/11/87
;=========================================================================

EDLIN_COMMAND:            ;an000;interface parser

	push	ax				;an000;save regs.
	push	cx				;an000;
	push	di				;an000
	push	si				;an000;

	mov	si,filespec         ;an000;get its offset
	mov	di,PATH_NAME         ;an000;get its offset

	mov	cx,00h				;an000;cx will count filespec
						;      length
	cmp	byte [parse_switch_b],TRUE ;an000;do we have /B switch
;	if$	z				;an000;we have the switch
	JNZ IF20$$
		mov	byte [loadmod],01h ;an000;signal switch found
;	endif$					;an000
IF20$$:

;	do$					;an000;while we have filespec
DO22$$:
		lodsb				;an000;move byte to al
		cmp	al,nul			;an000;see if we are at
						;      the end of the
						;      filespec
;		leave$	e			;an000;exit while loop
		JE EN22$$
		stosb				;an000;move byte to path_name
		inc	cx			;an000;increment the length
						;      of the filespec
;	enddo$					;an000;end do while
	JMP SHORT DO22$$
EN22$$:

	mov	[FNAME_LEN],cx			;an000;save filespec's length

	pop	si				;an000; restore regs
	pop	di				;an000;
	pop	cx				;an000;
	pop	ax				;an000;

	ret					;an000;return to caller

;EDLIN_COMMAND		endp			;an000;end proc

;=========================================================================
; Get_Extended_Attrib	: This routine gets the extended attributes of
;			  the file that was opened.
;
;=========================================================================

Get_Extended_Attrib:           ;an000; dms;

	mov	ax,5702h			;an000; dms;get extended attrib
	mov	si,0ffffh			;an000; dms;all attribs
	mov	cx,[EA_Buffer_Size] ;an000; dms;buffer size
	mov	di,START         ;an000; dms;point to buffer
	int	21h				;an000; dms;
	ret					;an000; dms;

;Get_Extended_Attrib	endp			;an000; dms;


;=========================================================================
; Query_Extend_Attrib	: This routine gets the extended attributes of
;			  the file that was opened.
;
;	Inputs	: Start - Buffer for extended attributes
;
;	Outputs : CX - size in paras
;
;=========================================================================

Query_Extend_Attrib:           ;an000; dms;

	mov	ax,5702h			;an000; dms;get extended attrib
	mov	si,0ffffh			;an000; dms;all attribs
	mov	cx,0000h			;an000; dms;get buffer size
	mov	di,START         ;an000; dms;point to buffer
	int	21h				;an000; dms;
	mov	[EA_Buffer_Size],cx ;an000; dms;save buffer size
	ret					;an000; dms;

;Query_Extend_Attrib	endp			;an000; dms;


;=========================================================================
; Calc_Memory_Avail	: This routine will calculate the memory
;			  available for use by EDLIN.
;
;	Inputs	: ORG_DS - DS of PSP
;
;	Outputs : DX	 - paras available
;=========================================================================

Calc_Memory_Avail:           ;an000; dms;

	push	ds				;save ds for size calc
	push	cx				;an000; dms;
	push	di				;an000; dms;

	mov	ds,[cs:org_ds]
	MOV	CX,[ds:2]
	MOV	DI,CS
	SUB	CX,DI
	mov	dx,cx				;an000; dms;put paras in DX

	pop	di				;an000; dms;
	pop	cx				;an000; dms;
	pop	ds				;an000; dms;

	ret					;an000; dms;

;Calc_Memory_Avail	endp			;an000; dms;

;=========================================================================
; EA_Fail_Exit		: This routine tells the user that there was
;			  Insufficient memory and exits EDLIN.
;
;	Inputs	: MemFul_Ptr - "Insufficient memory"
;
;	Outputs : message
;=========================================================================

EA_Fail_Exit:            ;an000; dms;

	mov	dx,memful_ptr         ;an000; dms;"Insufficient

	push	cs				;an000; dms;xchange ds/cs
	pop	ds				;an000; dms;
						;	     memory"
	call	std_printf			;an000; dms;print message
	mov	ah,Exit 			;an000; dms;exit
	xor	al,al				;an000; dms;clear al
	int	21h				;an000; dms;
	ret					;an000; dms;

;EA_Fail_Exit		endp			;an000; dms;

end if
;	END	EDLIN

