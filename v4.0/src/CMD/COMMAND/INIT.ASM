 PAGE 80,132
;	SCCSID = @(#)init.asm	4.13 85/11/03
;	SCCSID = @(#)init.asm	4.13 85/11/03
TITLE	COMMAND Initialization

	include 'COMSW.ASM'

.xlist
.xcref
	include 'DOSSYM.INC'
	include 'DOSCNTRY.INC';AC000;
	include 'COMSEG.ASM'
	include 'COMEQU.ASM'
	include 'RESMSG.EQU';AN000;
.list
.cref


ENVIRONSIZ		EQU	0A0H	;Must agree with values in EVIRONMENT segment
ENVIRONSIZ2		EQU	092H

ENVBIG			EQU	32768
ENVSML			EQU	160
KOREA_COUNTRY_CODE	EQU	82

if SEGSEL = S_CODERES	;AC000;
;	EXTRN	CONTC:NEAR
;	EXTRN	DskErr:NEAR
;	EXTRN	endinit:near
;	EXTRN	INT_2E:NEAR
;	EXTRN	LODCOM:NEAR
;	EXTRN	RSTACK:WORD
end if

if SEGSEL = S_DATARES	;AC000;
;	EXTRN	abort_char:byte 	;AN000;
;	EXTRN	append_state:word	;AN042;
;	EXTRN	BADFAT_OP_SEG:WORD	;AN000;
;	EXTRN	BATCH:WORD
;	EXTRN	COM_FCB1:DWORD
;	EXTRN	COM_FCB2:DWORD
;	EXTRN	COM_PTR:DWORD
;	EXTRN	com_xlat_addr:word
;	EXTRN	COMDRV:BYTE
;	EXTRN	COMPRMT1_SEG:WORD	;AN000;
;	EXTRN	COMPRMT1_SEG2:WORD	;AN000;
;	EXTRN	COMSPEC:BYTE
;	EXTRN	comspec_print:word
;	EXTRN	comspec_end:word
;	EXTRN	cpdrv:byte
;	EXTRN	crit_msg_off:word	;AN000;
;	EXTRN	crit_msg_seg:word	;AN000;
;	EXTRN	critical_msg_start:byte ;AN000;
;	EXTRN	DATARESEND:BYTE 	;AC000;
;	EXTRN	dbcs_vector_addr:word	;AN000;
;	EXTRN	DEVE_OP_SEG:WORD	;AN000;
;	EXTRN	DEVE_OP_SEG2:WORD	;AN000;
;	EXTRN	disp_class:byte 	;AN000;
;	EXTRN	DRVNUM_OP_SEG:WORD	;AN000;
;	EXTRN	DRVNUM_OP_SEG2:WORD	;AN000;
;	EXTRN	EchoFlag:BYTE
;	EXTRN	ENVIRSEG:WORD
;	EXTRN	ERR15_OP_SEG:WORD	;AN000;
;	EXTRN	ERR15_OP_SEG2:WORD	;AN000;
;	EXTRN	ERR15_OP_SEG3:WORD	;AN000;
;	EXTRN	extended_msg_start:byte ;AN000;
;	EXTRN	extmsgend:byte		;AN000;
;	EXTRN	fFail:BYTE
;	EXTRN	fucase_addr:word	;AN000;
;	EXTRN	InitFlag:BYTE
;	EXTRN	IO_SAVE:WORD
;	EXTRN	LTPA:WORD		;AC000;
;	EXTRN	MEMSIZ:WORD
;	EXTRN	MYSEG:WORD		;AC000;
;	EXTRN	MYSEG1:WORD
;	EXTRN	MYSEG2:WORD
;	EXTRN	nest:word
;	EXTRN	number_subst:byte	;AN000;
;	EXTRN	OldTerm:DWORD
;	EXTRN	PARENT:WORD
;AD060; EXTRN	pars_msg_off:word	;AN000;
;AD060; EXTRN	pars_msg_seg:word	;AN000;
;	EXTRN	parse_msg_start:byte	;AN000;
;	EXTRN	parsemes_ptr:word	;AN000;
;	EXTRN	PERMCOM:BYTE
;	EXTRN	RES_TPA:WORD
;	EXTRN	resmsgend:word		;AN000;
;	EXTRN	RSWITCHAR:BYTE
;	EXTRN	SINGLECOM:WORD
;	EXTRN	SUM:WORD
;	EXTRN	TRNSEG:WORD
;	EXTRN	TrnMvFlg:BYTE
end if

if SEGSEL = S_BATARENA	;AC000;
end if

if SEGSEL = S_BATSEG	;AC000;
end if

if SEGSEL = S_ENVARENA	;AC000;
end if

if SEGSEL = S_ENVIRONMENT	; Default COMMAND environment
;	EXTRN	ECOMSPEC:BYTE
;	EXTRN	ENVIREND:BYTE
;	EXTRN	PATHSTRING:BYTE
end if

if SEGSEL = S_TAIL
;	EXTRN	TRANSTART:WORD
end if

if SEGSEL = S_TRANCODE	;AC000;
;	EXTRN	DATINIT:FAR
;	EXTRN	printf_init:far
end if

if SEGSEL = S_TRANSPACE	;AC000;
;	EXTRN	TRANSPACEEND:BYTE
end if

; This is the area used for the autoexec.bat file.  BATARENA is a pad for the
; the address mark placed by DOS.

if SEGSEL = S_BATARENA

;	ORG 0	; the flat layout is already here
	DB  10h  DUP (?)		;Pad for memory allocation addr mark

end if

if SEGSEL = S_BATSEG	;Autoexec.bat segment

;	ORG	0	; the flat layout is already here
initbat 	BatchSegment		;batch segment
	DB  31	 DUP (0)		;reserve area for batch file name & pad

end if

; *******************************************************************
; START OF INIT PORTION
; This code is overlayed the first time the TPA is used.

if SEGSEL = S_INIT

;	EXTRN	AUTOBAT:byte
;	EXTRN	BADCSPFL:byte
;	EXTRN	bslash:byte
;	EXTRN	CHUCKENV:byte
;	EXTRN	command_c_syn:byte	;AN000;
;	EXTRN	command_d_syn:byte	;AN000;
;	EXTRN	command_e_syn:byte	;AN000;
;	EXTRN	command_f_syn:byte	;AN000;
;	EXTRN	command_m_syn:byte	;AN000;
;	EXTRN	command_p_syn:byte	;AN000;
;	EXTRN	comnd1_syn:word 	;AN000;
;	EXTRN	comnd1_addr:dword	;AN000;
;	EXTRN	COMSPECT:byte
;	EXTRN	comspstring:byte
;	EXTRN	dswitch:byte		;AN018;
;	EXTRN	ECOMLOC:word
;	EXTRN	EnvMax:WORD
;	EXTRN	EnvSiz:WORD
;	EXTRN	equalsign:byte
;	EXTRN	eswitch:byte		;AN018;
;	EXTRN	ext_msg:byte		;AN000;
;	EXTRN	fslash:byte
;	EXTRN	INITADD:dword
;	EXTRN	initend:word
;	EXTRN	init_parse:dword	;AN054;
;	EXTRN	INTERNAT_INFO:BYTE	;AN000; 3/3/KK
;	EXTRN	KAUTOBAT:byte		;AN000; 3/3/KK
;	EXTRN	lcasea:byte
;	EXTRN	lcasez:byte
;	EXTRN	num_positionals:word	;AN000;
;	EXTRN	oldenv:word
;	EXTRN	old_parse_ptr:word	;AN057;
;	EXTRN	parse_command:byte	;AN000;
;	EXTRN	pars_msg_off:word	;AN060;
;	EXTRN	pars_msg_seg:word	;AN060;
;	EXTRN	PRDATTM:byte
;	EXTRN	resetenv:word		;AC000;
;	EXTRN	scswitch:byte
;	EXTRN	space:byte
;	EXTRN	triage_add:dword	;AC000;
;	EXTRN	trnsize:word
;	EXTRN	ucasea:byte
;	EXTRN	usedenv:word


;AD054; EXTRN	SYSPARSE:NEAR

;	PUBLIC	CONPROC
;	PUBLIC	init_contc_specialcase

;ASSUME	CS:RESGROUP,DS:RESGROUP,ES:RESGROUP,SS:RESGROUP

;	ORG	0	; the flat layout is already here
ZERO	=	$


CONPROC:
	MOV	SP,RSTACK                 ; MUST be first instruction

	CALL	SYSLOADMSG			;AN000; check dos version
	JNC	okdos				;AN000; if no problem - continue

	mov	ax,BADVER			;AN000; set DOS version
	invoke	sysdispmsg			;AN000; must be incorrect version
	mov	ax,es
	cmp	[es:PDB_Parent_PID],AX		; If command is its own parent,
here:						;  loop forever.
	Jz	here
	int	20h				; Otherwise, exit.

;
;  Turn APPEND off during initialization processing
;
okdos:
	mov	ax,AppendInstall		;AN042; see if append installed
	int	2fh				;AN042;
	cmp	al,0				;AN042; append installed?
	je	set_msg_addr			;AN042; no - continue
	mov	ax,AppendDOS			;AN042; see if append DOS version right
	int	2fh				;AN042;
	cmp	ax,-1				;AN042; append version correct?
	jne	set_msg_addr			;AN042; no - continue
	mov	ax,AppendGetState		;AN042; Get the state of Append
	int	2fh				;AN042;
	mov	[APPEND_STATE],bx ;AN042; save append state
	xor	bx,bx				;AN042; clear out state
	mov	ax,AppendSetState		;AN042; Set the state of Append
	int	2fh				;AN042;     set everything off

set_msg_addr:
;
;  Get addresses of old critical and parse errors and save so they can
;  be reset if COMMAND needs to exit
;

	push	es				;AN000; SAVE ES DESTROYED BY INT 2FH
;AD060; mov	ah,multdos			;AN000; set up to call DOS through int 2fh
;AD060; mov	al,message_2f			;AN000; call for message retriever
	mov	ax,(MultDOS shl 8 or MESSAGE_2F);AN060; set up to call DOS through int 2fh
	mov	dl,GET_PARSE_MSG		;AN000; get parse message address
	int	2fh				;AN000;
	mov	[cs:PARS_MSG_SEG],es       ;AN000; save returned segment
	mov	[cs:PARS_MSG_OFF],di       ;AN000; save returned offset

;AD060; mov	ah,multdos			;AN000; set up to call DOS through int 2fh
;AD060; mov	al,message_2f			;AN000; call for message retriever
	mov	ax,(MultDOS shl 8 or MESSAGE_2F);AN060; set up to call DOS through int 2fh
	mov	dl,GET_CRITICAL_MSG		;AN000; get critical error message address
	int	2fh				;AN000;
	mov	[cs:CRIT_MSG_SEG],es       ;AN000; save returned segment
	mov	[cs:CRIT_MSG_OFF],di       ;AN000; save returned offset
	pop	es				;AN000; RESTORE ES DESTROYED BY INT 2FH

;
;  Set addresses of critical and parse errors in this level of COMMAND
;

;AD060; mov	ah,multdos			;AN000; set up to call DOS through int 2fh
;AD060; mov	al,message_2f			;AN000; call for message retriever
;AD060; mov	dl,set_parse_msg		;AN000; set up parse message address
	mov	di,PARSE_MSG_START                 ;AN000; start address
;AD060; int	2fh				;AN000;
	call	Set_parse_2f			;AN060; set parse error address


;AD060; mov	ah,multdos			;AN000; set up to call DOS through int 2fh
;AD060; mov	al,message_2f			;AN000; call for message retriever
	mov	ax,(MultDOS shl 8 or MESSAGE_2F);AN060; set up to call DOS through int 2fh
	mov	dl,SET_CRITICAL_MSG		;AN000; set up critical error message address
	mov	di,CRITICAL_MSG_START                 ;AN000; start address
	int	2fh				;AN000;

	mov	di,DATARESEND+15                 ;AN000; get address of resident end
	mov	[RESMSGEND],di			;AN000; save it
	call	sysloadmsg			;AN000; load message addresses
	call	GET_MSG_PTR			;AN000; set up pointers to some translated chars
	mov	ah,GetExtCntry			;g get extended country information
	mov	al,2				;g minor function - ucase table
	mov	dx,-1				;g
	mov	bx,-1				;g
	mov	cx,5				;g number of bytes we want
	mov	di,COM_XLAT_ADDR                 ;g buffer to put address in
	int	int_command			;g

	mov	ah,GetExtCntry			;AN000;  get extended country info
	mov	al,4				;AN000; get file ucase table
	mov	dx,-1				;AN000;
	mov	bx,-1				;AN000;
	mov	cx,5				;AN000; number of bytes we want
	mov	di,FUCASE_ADDR                 ;AN000; buffer for address
	int	int_command			;AN000;

	mov	dx,TRANSTART+15                 ;eg  get end of init code
	mov	cl,4				;eg change to paragraphs
	shr	dx,cl				;eg
	mov	ax,cs				;eg get current segment
	add	ax,dx				;eg calculate segment of end of init
	mov	[initend],ax			;eg save this

	push	ds				;AN000;
	mov	ax, (ECS_CALL SHL 8) OR GetLeadBTBL ;AN000; get dbcs vector
	int	int_command			;AN000;
	mov	bx,ds				;AN000; get segment to bx
	pop	ds				;AN000;
	mov	[Dbcs_vector_addr],si      ;AN000; save address of
	mov	[Dbcs_vector_addr+2],bx    ;AN000;     dbcs vector


	mov	ax,word [ds:PDB_Parent_PID]     ; Init PARENT so we can exit
	mov	[PARENT],ax			;  correctly.
	MOV	AX,word [ds:PDB_Exit]
	MOV	word [OldTerm],AX
	MOV	AX,word [ds:PDB_Exit+2]
	MOV	word [OldTerm+2],AX

	MOV	AX,ENVIREND + 15
	MOV	CL,4				; ax = size of resident part of
	SHR	AX,CL				;  command in paragraphs.  Add
	MOV	CX,CS				;  this to CS and you get the
	ADD	AX,CX				;  segment of the TPA.

	MOV	[RES_TPA], AX			; Temporarily save the TPA segment
	AND	AX, 0F000H
	ADD	AX, 01000H			; Round up to next 64K boundary
	JNC	TPASET				; Memory wrap if carry set
	MOV	AX, [RES_TPA]
TPASET:
	MOV	[LTPA],AX			; Good enough for the moment
	MOV	AX,word [ds:PDB_block_len]     ; ax = # of paras given to command

	MOV	[MYSEG1],DS			; These 3 variables are used as part of
	MOV	[MYSEG2],DS			;  3 long ptrs that the transient will
	MOV	[MYSEG],DS			;  use to call resident routines.
	MOV	[MEMSIZ],AX			; Needed for execing other programs
;
; Compute maximum size of environment
;
	MOV	word [EnvMax],(ENVIRONSIZ + 15) / 16 + (EnvMaximum-zero + 15)/16 - 1
;
; Compute minimum size of environment
;

	MOV	word [EnvSiz], ENVSML / 16

	MOV	DX,TRANSPACEEND + 15                  ; dx = size of transient
	MOV	CL,4				;  in paragraphs.
	SHR	DX,CL
	mov	[trnsize],dx			;eg save size of transient in paragraphs

	SUB	AX,DX				; max seg addr - # para's needed for transient
	MOV	[TRNSEG],AX			;  = seg addr to load the transient at.
	MOV	AX,[ds:PDB_environ]		; ax = environment segment
	OR	AX,AX				; If there is no environment segment,
	JZ	BUILDENV			;  go compute one.
	INC	byte [CHUCKENV]      ; Flag no new ENVIRONSEG to set up
	jmp     ENVIRONPASSED    ; Otherwise one was passed to us.

BUILDENV:	; (this label isn't very accurate)
	MOV	AX,PATHSTRING                 ; Compute the segment of the
	MOV	CL,4				;  environment and put it in
	SHR	AX,CL				;  ax.
	MOV	DX,DS
	ADD	AX,DX

ENVIRONPASSED:
	MOV	[ENVIRSEG],AX			; Save the environment's segment and
	MOV	ES,AX				;  load into es.
;ASSUME	ES:ENVIRONMENT

GOTTHEENVIR:
	MOV	AX,Char_Oper SHL 8		; Get the switch character and store it
	INT	int_command			;  in RSWITCHAR.
	MOV	[RSWITCHAR],DL

	CMP	DL,[fslash] ; If backslashes are being used as the
	JNZ	IUSESLASH			;  path separator, change the forward
	mov	al,[bslash] ;  slash in COMSPECT and ECOMSPEC (if
	MOV	[COMSPECT],al			;  there is a new ENVIRONSEG) to
	CMP	byte [CHUCKENV],0      ;  backslash.
	JNZ	IUSESLASH
	MOV	[es:ECOMSPEC-ENVIRONMENT$],al	;eg

IUSESLASH:
;
; Initialize the command drive
;
	MOV	AH,Get_Default_Drive
	INT	21h
	INC	AL
	MOV	[COMDRV],AL

	MOV	AL,byte [ds:FCB]      ; al = default drive number for command
	OR	AL,AL
	JZ	NOCOMDRV			; no drive specified

	MOV	AH,':'
	MOV	[COMDRV],AL
	ADD	AL,40H				; Convert number to uppercase character

	STD
	CMP	byte [CHUCKENV],0      ; If a new environment is being built,
	JNZ	NOTWIDENV			;  move the default comspec string in it
	PUSH	DS				;  2 bytes to make room for a drivespec.
	PUSH	ES				;  The drivespec is in ax and is copied
	POP	DS				;  on to the front of the string.
	MOV	DI,ECOMSPEC-ENVIRONMENT$+ENVIRONSIZ2-1 ;eg
	MOV	SI,ECOMSPEC-ENVIRONMENT$+ENVIRONSIZ2-3 ;eg

	MOV	CX,ENVIRONSIZ2 - 2
	REP	MOVSB
	POP	DS
	MOV	word [es:ECOMSPEC-ENVIRONMENT$],AX

NOTWIDENV:
	CLD					; Add the drivespec to the string
	MOV	word [AUTOBAT],AX      ;  used to reference autoexec.bat
	MOV	word [KAUTOBAT],AX      ;AN000;  used to reference kautoexe.bat 3/3/KK

NOCOMDRV:
	invoke	SETVECT 			; Set interrupt vectors 22h, 23h, & 24h

;*********************************
; PARSING STARTS HERE
;*********************************

	push	cs				;AN000; get local segment
	push	cs				;AN000;   into DS,ES
	pop	ds				;AN000;
	pop	es				;AN000;

;ASSUME	DS:RESGROUP,ES:RESGROUP 		;AN000;

	MOV	SI,80H				;AC000; get command line
	LODSB					;AC000; get length of line
	MOV	DI,SI				;AN000; get line position in DI
	XOR	AH,AH				;AC000; ax = length of command line
;
; Insure that the command line correctly ends with a CR
;
	ADD	DI,AX				;AC000; go to end of command line
	MOV	byte [DI],0Dh      ;AC000; insert a carriage return
	xor	cx,cx				;AC000; clear cx
	mov	[num_positionals],cx       ;AC000; initialize positionals
;
; Scan the command line looking for the parameters
;

parse_command_line:
	mov	di,PARSE_COMMAND                ;AN000; Get address of parse_command
	mov	cx,[num_positionals]       ;AN000; Get number of positionals
	xor	dx,dx				;AN000; clear dx
	mov	[old_parse_ptr],si ;AN057; save position before calling parser
	call	[init_parse] ;AN054; call parser
	mov	[num_positionals],cx       ;AN000; Save number of positionals
	cmp	ax,end_of_line			;AC000; are we at end of line?
	jz	ArgsdoneJ3			;AC000; yes - exit
	cmp	ax,result_no_error		;AN000; did an error occur
	jz	parse_cont			;AN000; no - continue

;
; Before issuing error message - make sure switch is not /C
;

parse_line_error:
	push	si				;AN057; save line position
	push	ax				;AN057; save error number
	cmp	ax,BadSwt_Ptr			;AN057; Was error invalid switch?
	jnz	parse_line_error_disp		;AN057; No - just issue message
	mov	di,si				;AN057; Get terminating pointer in DI
	mov	si,[old_parse_ptr] ;AN057; Get starting pointer in SI

init_chk_delim:
	cmp	si,di				;AN057; at end of parsed parameter?
	jz	parse_line_error_disp		;AN057; Yes - just display message
	lodsb					;AN057;
	cmp	al,[space] ;AN057; Skip blank spaces
	jz	init_chk_delim			;AN057;
	cmp	al,tab_chr			;AN057; Skip tab characters
	jz	init_chk_delim			;AN057;

	cmp	al,[RSWITCHAR]			;AN057; Switch?
	jnz	parse_line_error_disp		;AN057; No - just issue message
	lodsb					;AN057; Get the char after the switch
	invoke	ITESTKANJ			;AN057; Is it DBCS?
	jnz	parse_line_error_disp		;AN057; Yes - can't be /C
	invoke	iupconv 			;AN057; upper case it
	cmp	al,[scswitch] ;AN057; it is /C?
	jnz	parse_line_error_disp		;AN057;
	pop	dx				;AN057; even up stack
	pop	dx				;AN057; even up stack
	jmp	SetSSwitch			;AN057; Yes - go set COMMAND /C

parse_line_error_disp:
	pop	ax				;AN057; restore error number
	pop	si				;AN057; restore line position
	mov	byte [DISP_CLASS],parse_msg_class  ;AN000; set up parse error msg class
	mov	dx,ax				;AN000; get message number
	call	print_message			;AN000; issue error message
	jmp     parse_command_line   ;AN000; continue parsing

parse_cont:
;
; See if a switch was entered
;

	cmp	word [COMND1_SYN],COMMAND_F_SYN          ;AC000; was /F entered?
	jz	SetFSwitch				 ;AC000; yes go set fail switch
	cmp	word [COMND1_SYN],COMMAND_P_SYN          ;AC000; was /P entered?
	Jz	SetPSwitch				 ;AC000; yes go set up PERMCOM
	cmp	word [COMND1_SYN],COMMAND_D_SYN          ;AC000; was /D entered?
	jz	SetDSwitch				 ;AC000; yes go set date switch
	cmp	word [COMND1_SYN],COMMAND_C_SYN          ;AC000; was /C entered?
	jz	SetSSwitch				 ;AC000; yes go set up SINGLECOM
	cmp	word [COMND1_SYN],COMMAND_E_SYN          ;AC000; was /E entered?
	jz	SetESwitch				 ;AC000; yes go set up environment
	cmp	word [COMND1_SYN],COMMAND_M_SYN          ;AN000; was /MSG entered?
	jz	SetMSwitchjmp				 ;AN000; yes go set up message flag
	jmp	CHKOTHERARGS				 ;AC000; Must be something else

SetMSwitchjmp:					;AN018; long jump needed
	jmp	SetMSwitch			;AN018;

ArgsdoneJ3:					;AN018; long jump needed
	jmp	ARGSDONE			;AN018;

SetFSwitch:
	cmp	byte [fFail],-1    ;AN018; has fail switch been set?
	jnz	failok				;AN018; no - set it
	mov	ax,MoreArgs_Ptr 		;AN018; set up too many arguments
	jmp	parse_line_error		;AN018; go issue error message

failok:
	MOV	byte [fFail],-1    ;AC000; fail all INT 24s.
	JMP	parse_command_line		;AC000;

SetPSwitch:
;
; We have a permanent COMMAND switch /P.  Flag this and stash the
; termination address.
;
	cmp	byte [PERMCOM],0   ;AN018; has /p switch been set?
	jz	permcomok			;AN018; no - set it
	mov	ax,MoreArgs_Ptr 		;AN018; set up too many arguments
	jmp	parse_line_error		;AN018; go issue error message

permcomok:
	INC	byte [PERMCOM]
	MOV	word [OldTerm],LODCOM
	MOV	word [OldTerm+2],DS
;
; Make sure that we display the date and time.	If the flag was not
; initialized, set it to indicate yes, do prompt.
;
	CMP	byte [PRDATTM],-1
	JNZ	Parse_command_line_jmp		;AC018; keep parsing
	MOV	byte [PRDATTM],0      ; If not set explicit, set to prompt

Parse_command_line_jmp: 			;AN018;
	JMP	parse_command_line		;AC000; keep parsing

ArgsDoneJump:
	JMP	ARGSDONE

SetDSwitch:
;
; Flag no date/time prompting.
;
	cmp	byte [dswitch],0   ;AN018; has /D switch been set?
	jz	setdateok			;AN018; no - set it
	mov	ax,MoreArgs_Ptr 		;AN018; set up too many arguments
	jmp	parse_line_error		;AN018; go issue error message

setdateok:
	inc	byte [dswitch]     ;AN018; indicate /D entered
	MOV	byte [PRDATTM],1      ; User explicitly says no date time
	JMP	parse_command_line		;AC000; continue parsing

SetSSwitch:
;
; Set up pointer to command line, flag no date/time and turn off singlecom.
;
	MOV	[SINGLECOM],SI			; Point to the rest of the command line
	MOV	byte [PERMCOM],0   ; A SINGLECOM must not be a PERMCOM
	MOV	byte [PRDATTM],1      ; No date or time either, explicit
	JMP	ARGSDONE
;
; Look for environment-size setting switch
;
; The environment size is represented in decimal bytes and is
; converted into pargraphs (rounded up to the next paragraph).
;

SetESwitch:
	cmp	byte [eswitch],0   ;AN018; has fail switch been set?
	jz	eswitchok			;AN018; no - set it
	mov	ax,MoreArgs_Ptr 		;AN018; set up too many arguments
	jmp	parse_line_error		;AN018; go issue error message

eswitchok:
	inc	byte [eswitch]     ;AN018; indicate /E entered
	mov	di,COMND1_ADDR                 ;AN000; get number returned
	mov	bx,word [di]      ;AN000;     into bx

	ADD	BX, 0FH 			; Round up to next paragraph
	mov	cl,4				;AC000; convert to pargraphs
	SHR	BX, cl				;AC000;   by right 4

	MOV	[EnvSiz],BX ; EnvSiz is in paragraphs
	JMP	parse_command_line		;AC000; continue parsing command line

SetMSwitch:
	cmp	byte [ext_msg],SET_EXTENDED_MSG    ;AN018; has /MSG switch been set?
	jnz	setMswitchok			;AN018; no - set it
	mov	ax,MoreArgs_Ptr 		;AN018; set up too many arguments
	jmp	parse_line_error		;AN018; go issue error message
setMswitchok:
	MOV	byte [ext_msg],SET_EXTENDED_MSG    ;AN000; set /MSG switch
	JMP	parse_command_line		;AN000; keep parsing

ARGSDONEJ:
	JMP  ARGSDONE

;
; We have a non-switch character here.
;
CHKOTHERARGS:
	push	ds				;AN054;
	push	si				;AC000; save place in command line
	lds	si,dword [COMND1_ADDR]     ;AN000; get address of filespec
;	assume	ds:nothing			;AN054;

	mov	dx,si				;AN000; put in dx also
	MOV	AX,(Open SHL 8) OR 2		; Read and write
	INT	int_command
	JC	CHKSRCHSPEC			; Wasn't a file
	MOV	BX,AX
	MOV	AX,IOCtl SHL 8
	INT	int_command
	TEST	DL,80H
	JNZ	ISADEVICE

BADSETCON:					;AN022;
	MOV	AH,Close			; Close initial handle, wasn't a device
	INT	int_command
	JMP	CHKSRCHSPEC

ISADEVICE:
	XOR	DH,DH
	OR	DL,3				; Make sure has CON attributes
	MOV	AX,(IOCtl SHL 8) OR 1
	INT	int_command
	JC	BADSETCON			;AN022; Can't set attributes - quit
	MOV	DX,BX				; Save new handle
;eg	POP	BX				; Throw away saved SI
;eg	POP	BX				; Throw away saved CX
	PUSH	CX
	MOV	CX,3
	XOR	BX,BX

RCCLLOOP:					; Close 0,1 and 2
	MOV	AH,Close
	INT	int_command
	INC	BX
	LOOP	RCCLLOOP
	MOV	BX,DX				; New device handle
	MOV	AH,XDup
	INT	int_command			; Dup to 0
	MOV	AH,XDup
	INT	int_command			; Dup to 1
	MOV	AH,XDup
	INT	int_command			; Dup to 2
	MOV	AH,Close
	INT	int_command			; Close initial handle
	POP	CX
	pop	si				;AN000; restore position of command line
	pop	ds				;AN054;
	JMP	parse_command_line		;AC000; continue parsing

CHKSRCHSPEC:					; Not a device, so must be directory spec

	MOV	byte [CHUCKENV],0      ; If search specified -- no inheritance
	MOV	AX,PATHSTRING                 ; Figure environment pointer
	MOV	CL,4
	SHR	AX,CL
;AD054; MOV	DX,DS
	MOV	DX,CS				;AC054;
	ADD	AX,DX
	MOV	[ENVIRSEG],AX

	MOV	ES,AX
	push	si				;AN000; remember location of file
	xor	cx,cx				;AN000; clear cx for counting

countloop:
	lodsb					;AN000; get a character
	inc	cx				;AN000; increment counter
	cmp	al,end_of_line_out		;AN000; are we at end of line?
	jnz	countloop			;AN000; no - keep counting

	mov	al,[space]
	dec	si				;AN000; move back one
	MOV	byte [SI],al      ;AN000; put a space at end of line
	pop	si				;AC000; get location back

	MOV	DI,[ECOMLOC]

COMTRLOOP:
	LODSB
	DEC	CX
	CMP	AL,[space]
	JZ	SETCOMSR
	STOSB

;;;	IF	KANJI		3/3/KK
	XOR	AH,AH
;;;	ENDIF			3/3/KK

	JCXZ	SETCOMSR

;;;;	IF	KANJI		3/3/KK
	PUSH	DS				;AN054; Make sure we have
	PUSH	CS				;AN054;    local DS for
	POP	DS				;AN054;      ITESTKANJ
	invoke	ITESTKANJ
	POP	DS				;AN054; restore PARSER DS
	JZ	COMTRLOOP
	DEC	CX
	MOVSB
	INC	AH
	JCXZ	SETCOMSR
;;;;	ENDIF			3/3/KK

	jmp     COMTRLOOP

SETCOMSR:
	PUSH	CX

	PUSH	CS				;AN054; Get local segment
	POP	DS				;AN054;
;	assume	ds:resgroup			;AN054;

	PUSH	DS
	MOV	SI,COMSPECT
	MOV	CX,14

	MOV	AL,[es:DI-1]

;;;;	IF	KANJI		3/3/KK
	OR	AH,AH
	JNZ	INOTROOT			; Last char was KANJI second byte, might be '\'
;;;;	ENDIF			3/3/KK

	CALL	PATHCHRCMPR
	JNZ	INOTROOT
	INC	SI				; Don't make a double /
	DEC	CX

INOTROOT:
	REP	MOVSB

	MOV	DX,[ECOMLOC]			; Now lets make sure its good!
	PUSH	ES
	POP	DS

	MOV	AX,Open SHL 8
	INT	int_command			; Open COMMAND.COM
	POP	DS
	JC	SETCOMSRBAD			; No COMMAND.COM here
	MOV	BX,AX				; Handle
	MOV	AH,Close
	INT	int_command			; Close COMMAND.COM

SETCOMSRRET:
	POP	CX
	POP	SI
	POP	DS				;AN054;
;	assume	ds:resgroup			;AN054;

ARGSDONEJ2:
	PUSH	CS				;AN000; Make sure local ES is
	POP	ES				;AN000;     restored
	JMP	parse_command_line		;AC000; continue parsing command line

SETCOMSRBAD:
	MOV	DX,BADCOMLKMES_PTR		;AC000; get message number
	invoke	TriageError
	cmp	ax, 65
	jnz	doprt
	mov	dx,BADCOMACCMES_PTR		;AC000; get error message number
doprt:
	call	print_message
	MOV	SI,COMSPECT
	MOV	DI,[ECOMLOC]
	MOV	CX,14
	REP	MOVSB				; Get my default back

	jmp     SETCOMSRRET

;*********************************
; PARSING ENDS HERE
;*********************************

ARGSDONE:
	mov	es,[ENVIRSEG]			;AC000; get environment back
;	ASSUME	ES:ENVIRONMENT			;AN000;
;AD060; cmp	ext_msg,set_extended_msg	;AN000; was /msg specified?
;AD060; jnz	check_permcom			;AN000; No, go check permcom
;AD060; cmp	[permcom],0			;AN000; Yes - was permcom set?
;AD060; jz	permcom_error			;AN000; No - error cannot have /MSG without /P

;AD060; mov	ah,multdos			;AN000; set up to call DOS through int 2fh
;AD060; mov	al,message_2f			;AN000; call for message retriever
;AD060; mov	dl,set_extended_msg		;AN000; set up extended error message address
;AD060; push	es				;AN016; save environment segment
;AD060; push	cs				;AN016; get local segment to ES
;AD060; pop	es				;AN016;
;AD060; mov	di,offset resgroup:extended_msg_start ;AN000; start address
;AD060; int	2fh				;AN000;
;AD060; pop	es				;AN016; restore environment segment
;AD060; mov	di,offset resgroup:extmsgend+15 ;AN000; get address of resident end
;AD060; mov	[resmsgend],di			;AN000; save it
;AD060; call	sysloadmsg			;AN000; load message addresses
;AD060; jmp	short process_permcom		;AN000; now go process /P switch

;AD060;permcom_error:
;AD060; mov	disp_class,parse_msg_class	;AN000; set up parse error msg class
;AD060; mov	dx,LessArgs_Ptr 		;AN000; get message number for "Required parameter missing"
;AD060; call	print_message			;AN000; issue error message
;AD060; jmp	short comreturns		;AN000; we already know /P wasn't entered

;AD060;check_permcom:
	CMP	byte [PERMCOM],0
	JZ	COMRETURNS

;AD060;process_permcom:
	PUSH	ES				; Save environment pointer
	MOV	AH,Set_Current_PDB
	MOV	BX,DS
	MOV	ES,BX
	INT	int_command			; Current process is me
	MOV	DI,PDB_Exit			; Diddle the addresses in my header
	MOV	AX,LODCOM
	STOSW
	MOV	AX,DS
	STOSW
	MOV	AX,CONTC
	STOSW
	MOV	AX,DS
	STOSW
	MOV	AX,DSKERR
	STOSW
	MOV	AX,DS
	STOSW
	MOV	word [ds:PDB_Parent_PID],DS     ; Parent is me forever

	MOV	DX,INT_2E
	MOV	AX,(Set_Interrupt_Vector SHL 8) OR 02EH
	INT	int_command			;Set magic interrupt
	POP	ES				;Remember environment

COMRETURNS:
	MOV	AX,word [ds:PDB_Parent_PID]
	MOV	[PARENT],AX			; Save parent
	MOV	word [ds:PDB_Parent_PID],DS     ; Parent is me
	MOV	AX,word [ds:PDB_JFN_Table]
	MOV	[IO_SAVE],AX			; Get the default stdin and out
	MOV	word [COM_PTR+2],DS      ; Set all these to resident
	MOV	word [COM_FCB1+2],DS
	MOV	word [COM_FCB2+2],DS
	MOV	DI,COMSPEC

	MOV	SI,[ECOMLOC]
	CMP	byte [CHUCKENV],0

	MOV	AX,DS				; XCHG ES,DS
	PUSH	ES
	POP	DS
	MOV	ES,AX

	JZ	COPYCOMSP			; All set up for copy

	PUSH	CS
	POP	DS

	MOV	SI,COMSPSTRING
	PUSH	ES
	PUSH	DI
	CALL	IFINDE
	MOV	SI,DI
	PUSH	ES
	POP	DS
	POP	DI
	POP	ES
	JNC	COPYCOMSP

COMSPECNOFND:
	MOV	SI,[cs:ECOMLOC] 		;AC062
	ADD	SI,PATHSTRING
	PUSH	CS
	POP	DS

;assume	es:resgroup
COPYCOMSP:
	mov	[es:COMSPEC_PRINT],di      ; Save ptr to beginning of comspec path
	cmp	byte [si+1],':'                 ; Is there a drive specifier in comspec
	jnz	COPYCOMSPLOOP			; If not, do not skip over first 2 bytes
	add	word [es:COMSPEC_PRINT],2

COPYCOMSPLOOP:
	LODSB
	STOSB
	OR	AL,AL
	JNZ	COPYCOMSPLOOP
	mov	[es:comspec_end],di        ; Save ptr to end of comspec path
	dec	word [es:comspec_end]
	mov	ah,[es:COMDRV]
	add	ah,'A'-1
	mov	[es:cpdrv],ah ; Load drive letter in comprmt2
;assume	es:environment

	call	setup_for_messages		;AN060; set up parse and extended error messages
	PUSH	CS
	POP	DS
	MOV	BX,[RESMSGEND]			;AC000; get end of resident
	MOV	CL,4
	SHR	BX,CL
;Public EnvMaximum
EnvMaximum:
;
; NOTE: The transient has to loaded directly after shrinking to the
;	resident size.
;	There is an assumption made when loading the transient that it
;	still intact after the resident portion.
;	If any other ALLOC/DEALLOC/SETBLOCK operations are performed
;	inbetween, then there is a real good chance that the non-resident
;	portion will be overwritten by arena information.
;
	MOV	AH,Setblock
	INT	int_command			; Shrink me to the resident only
;
; Load in the transient and compute the checksum.  We may do this in one of
; two ways:  First, cheat and use the transient loading code that exists in
; the resident piece.  This may be OK except that it will hit the disk.
;
; But we do not need to hit the disk!  The transient is already loaded but is
; in the wrong place.  We need to block transfer it up to the correct spot.
;
GOTENVIR:
	MOV	byte [TrnMvFlg], 1 ; Indicate that transient has been moved
	PUSH	ES
	MOV	SI,TRANSTART
	MOV	DI,0
	mov	ES,[TRNSEG]
	MOV	CX,TRANSPACEEND
;
; We need to ensure that we do not have the potential of overwriting our
; existing code in this move
; It is OK to move if (SI+CX+Segment of Transient < TrnSeg).
;
	push	cx
	mov	ax,cx				; Get size of transient in bytes
	add	ax,si				; Calculate end of transient section
	mov	cl,4
	shr	ax,cl				; Convert to paragraphs
	inc	ax				; Round up (for partial paragraph)
	mov	cx,ds
	add	ax,cx				; Add in current segment
	cmp	ax,[TRNSEG] ; See if there is overlap
	pop	cx
; If we are too close to be safe, call LOADCOM instead of moving the code.
	jb	Ok_To_Move
	invoke	LOADCOM
	jmp     Trans_Loaded
Ok_To_Move:
;
; Everything is set for an upward move. WRONG!	We must move downward.
;
	ADD	SI,CX
	DEC	SI
	ADD	DI,CX
	DEC	DI
	STD
	REP	MOVSB
	CLD

Trans_Loaded:
	POP	ES

	invoke	CHKSUM				; Compute the checksum
	MOV	[SUM],DX			; Save it

	CMP	byte [PRDATTM],0      ;eg
	JNZ	NOBATCHSEG			;eg Don't do AUTOEXEC or date time
;
; Allocate batch segment for D:/autoexec.bat + no arguments
;
	MOV	BX,((sizeof.BatchSegment) + 15 + 1 + 0Fh)/16       ;eg
	MOV	AH,Alloc			;eg
	INT	int_command			;eg
	JC	NOBATCHSEG			;eg didn't allocate - pretend no batch
	MOV	[BATCH],AX ;eg save batch segment

NOBATCHSEG:
	MOV	BX, 0FFFFH			; Get size of largest block for env
	MOV	AH, Alloc
	INT	int_command

; Only allocate maximum 64K worth of environment

	SUB	BX,[trnsize] ;eg subtract # of transient paragraphs
	SUB	BX,128				;eg make sure we have 2K left
	MOV	[EnvMax], BX
	CMP	BX, 4096			; 64K = 4096 paragraphs
	JB	MAXOK
	MOV	BX, 4096-1
	MOV	[EnvMax], BX
MAXOK:

	MOV	AH, Alloc			; Get max size
	INT	int_command

	mov	bx,[ENVIRSEG]			;g get old environment segment
	mov	[oldenv],bx ;g save it
	mov	word [usedenv],0   ;g initialize env size counter
	MOV	DS,bx
;	ASSUME	DS:NOTHING
	MOV	[ENVIRSEG],AX
	MOV	ES,AX
	XOR	SI,SI
	MOV	DI,SI
	MOV	BX,[EnvMax] ; Copy over as much of the environment
						; as possible
	SHL	BX,1
	SHL	BX,1
	SHL	BX,1
	SHL	BX,1
	MOV	[EnvMax], BX ; Convert EnvMax to bytes
	DEC	BX				; Dec by one to leave room for double 0
	XOR	DX,DX				; Use DX to indicate that there was
						; no environment size error.
;Public Nxtstr
Nxtstr:
	CALL	GetStrLen			; Get the size of the current env string
	push	ds				;g get addressability to environment
	push	cs				;g			 counter
	pop	ds				;g
;	ASSUME	DS:RESGROUP
	add	[usedenv],cx ;g  add the string length to env size
	pop	ds				;g
;	ASSUME	DS:NOTHING
	CMP	CX,1				; End of environment was encountered.
	JZ	EnvExit
	SUB	BX,CX
	JAE	OKCpyStr			; Can't fit in all of enviroment.
	INC	DX				; Out of env space msg must be displayed
	JMP	EnvExit
OKCpyStr:
	JMP	Nxtstr
EnvExit:

	PUSH	CS
	POP	DS
;	ASSUME	DS:RESGroup
	OR	DX,DX				; DX will be non-zero if error
	JZ	EnvNoErr
	MOV	DX,OUTENVERR_PTR		;AC000; get message number
	call	print_message

EnvNoErr:
	; BX now has the left over size of the maximum environment
	; We want to shrink the environment down to the minimum size
	; Set the environment size to max(Envsiz,Env used)

	MOV	CX, [EnvMax]
	SUB	CX, BX				; CX now has the environment used
	ADD	CX, 16				; Round up to next paragraph
	SHR	CX, 1
	SHR	CX, 1
	SHR	CX, 1
	SHR	CX, 1
	CMP	CX, [EnvSiz] ; Is environment used > Envsiz
	JB	EnvSet
	MOV	[EnvSiz], CX
EnvSet:
	MOV	BX, [EnvSiz] ; Set environment to size needed
	mov	ax,es				;eg get environment segment
	add	ax,bx				;eg add number of environment paragraphs
	cmp	ax,[initend] ;eg does this go past end of init?
	ja	envsetok			;eg yes - do the setblock
	mov	ax,es				;eg no - get back the environment segment
	mov	bx,[initend] ;eg get the segment at end of init
	sub	bx,ax				;eg setblock envir segment to end of init code
	mov	byte [resetenv],1  ;eg set flag so we know to set envir later

envsetok:
	MOV	AH, Setblock
	INT	int_command

	IF MSVER
	CMP	word [SINGLECOM],0
	JNZ	NOPHEAD 			; Don't print header if SINGLECOM
	MOV	DX,HEADER_PTR			;AC000; get message number
	call	print_message
NOPHEAD:
end if

	CMP	word [BATCH],0     ;eg did we set up a batch segment?
	JNZ	dodate				;eg yes - go initialize it
	JMP	NODTTM				; Don't do AUTOEXEC or date time
;
; Allocate batch segment for D:/autoexec.bat + no arguments
;
dodate:
	MOV	AX,[BATCH] ;eg get batch segment
	MOV	byte [ECHOFLAG],3  ; set batch echo
	MOV	word [NEST],1      ; g set nest flag to 1 batch
	MOV	ES,AX
;
; Initialize the segment
;
	XOR	DI,DI
	MOV	AL,BatchType
	STOSB
	MOV	AL,1				; G initialize echo for batch exit
	STOSB					; G
	XOR	AX,AX				; initialize to zero
	STOSW					; G batch segment of last job - batlast
	STOSW					; G segment for FOR
	STOSB					; G FOR flag
	STOSW					; position in file - batseek
	STOSW
;
; Clean out the parameters
;
	MOV	AX,-1				; initialize to no parameters
	MOV	CX,10
	REP	STOSW
;
; Decide whether we should grab the default drive
;
	CMP	byte [AUTOBAT],0

	JNZ	NOAUTSET
	MOV	AH,Get_Default_Drive
	INT	int_command
	ADD	AL,[ucasea]

	MOV	[AUTOBAT],AL
	MOV	[KAUTOBAT],AL			;AN000;  3/3/KK

NOAUTSET:
;
; Copy in the batch file name (including NUL)
;
	MOV	SI,AUTOBAT
	MOV	CX,8
	REP	MOVSW
	MOVSB					;AN027;  move in carraige return to terminate string

	MOV	DX,AUTOBAT
	MOV	AX,Open SHL 8
	INT	int_command			; See if AUTOEXEC.BAT exists
	JC	NOABAT
	MOV	BX,AX
	MOV	AH,Close
	INT	int_command
	JMP	DRV0				;AC000; go process autoexec

NOABAT:
	push	ax
	call	setup_seg
	mov	word [triage_add+2],ax
	pop	ax
	call	[triage_add]
	cmp	ax, 65
	jz	AccDenErr			;AN000; was network access denied


; If AUTOEXEC.BAT is not found, then check for KAUTOEXE.BAT.  Changed
; by Ellen to check only when in Korea.  The country information
; returned will overlay the old parse data area, but we don't care
; since we won't need the parse information or country information.
; We only care about the country code returned in BX.

	MOV	DX,INTERNAT_INFO                 ;AN000; Set up internat vars
	MOV	AX,International SHL 8		;AN000;  get country dependent info
	INT	21H				;AN000;
	JC	NOKABAT 			;AN000; Error - don't bother with it
	CMP	BX,KOREA_COUNTRY_CODE		;AN000; Are we speaking Korean?
	JNZ	openerr 			;AN000; No, don't check for KAUTOEXE

	MOV	DI, BatchSegment.BatFile   ;AN000;  3/3/KK
	MOV	SI,KAUTOBAT                 ;AN000;  Another trial to do	3/3/KK
	MOV	CX,8				;AN000;  auto execution for the 3/3/KK
	REP	MOVSW				;AN000;  non-English country	3/3/KK
	MOVSB					;AN027;  move in carraige return to terminate string
	MOV	DX,KAUTOBAT                 ;AN000;  3/3/KK
	MOV	AX,Open SHL 8			;AN000;  3/3/KK
	INT	int_command			;AN000;  See if KAUTOEXE.BAT exists    3/3/KK
	JC	NOKABAT 			;AN000;  3/3/KK
	MOV	BX,AX				;AN000;  3/3/KK
	MOV	AH,Close			;AN000;  3/3/KK
	INT	int_command			;AN000;  3/3/KK
	jmp     DRV0     ;AN000;  3/3/KK

NOKABAT:					;AN000;  3/3/KK
	call	[triage_add] ;AN000;  get extended error
	cmp	ax, 65				;AN000;  network access denied?
	jnz	openerr 			;AN000;  no - go deallocate batch

AccDenErr:					;AN000;  yes - put out message
	mov	DX,[AccDen] ;AC000; get message number
	call	print_message

openerr:
	MOV	ES,[BATCH]			; Not found--turn off batch job
	MOV	AH,Dealloc
	INT	int_command
	MOV	word [BATCH],0     ; AFTER DEALLOC in case of ^C
	MOV	byte [ECHOFLAG],1
	mov	word [NEST],0      ;g indicate no batch in progress

DODTTM:
	MOV	AX,DATINIT
	MOV	word [INITADD],AX
	MOV	AX,[TRNSEG]
	MOV	word [INITADD+2],AX
	CALL	dword [INITADD]

NODTTM:

	IF IBMVER
	CMP	word [SINGLECOM],0
	JNZ	DRV0				; Don't print header if SINGLECOM
	MOV	DX,HEADER_PTR			;AC000; get message number
	call	print_message
end if

DRV0:						; Reset APPEND state
	push	ds				;AN042; save data segment
	push	cs				;AN042; Get local segment into DS
	pop	ds				;AN042;
	mov	ax,AppendSetState		;AN042; Set the state of Append
	mov	bx,[APPEND_STATE] ;AN042;     back to the original state
	int	2fh				;AN042;
	pop	ds				;AN042; get data segment back
	JMP	ENDINIT 			;G Finish initializing

;
;	Get length of string pointed to by DS:SI.  Length includes NULL.
;	Length is returned in CX
;
GetStrLen:
	xor	cx,cx
NxtChar:
	lodsb
	inc	cx
	or	al,al
	jnz	NxtChar
	ret
;
; If the transient has been loaded in TranSeg, then we need to use that
; segment for calls to routines in the transient area. Otherwise, the current
; code segment is used
; Segment returned in AX.
;
setup_seg:
	mov	ax,[TRNSEG]
	cmp	byte [TrnMvFlg], 1 ; Has transient portion been moved
	jz	setup_end
	push	bx
	mov	bx,cs
	mov	ax,TRANSTART
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	add	ax,bx
	pop	bx
setup_end:
	ret

print_message:
	push	ax
	PUSH	DS				;AN000; save data and extra segment
	PUSH	ES				;AN000;     registers
	MOV	AX,CS				;AN000; get local segment
	MOV	ES,AX				;AN000; set ES and DS to point to it
	MOV	DS,AX				;AN000;
;AD054; PUSH	BX				;AC000; save BX register
;AD054; PUSH	CX				;AC000; save CX register
;AD054; PUSH	DX				;AC000; save DX register
;AD054; MOV	AX,DX				;AC000; get message number
;AD054; MOV	DH,DISP_CLASS			;AC000; get display class
;AD054; MOV	DL,NO_CONT_FLAG 		;AN000; set control flags off
;AD054; MOV	BX,NO_HANDLE_OUT		;AC000; set message handler to use function 1-12
;AD054; XOR	CH,CH				;AC000; clear upper part of cx
;AD054; MOV	CL,NUMBER_SUBST 		;AC000; set number of substitutions
;AD054; invoke	SYSDISPMSG			;AC000; display the message
;AD054; MOV	DISP_CLASS,UTIL_MSG_CLASS	;AC000; reset display class
;AD054; MOV	NUMBER_SUBST,NO_SUBST		;AC000; reset number of substitutions
;AD054; POP	DX				;AC000; restore registers
;AD054; POP	CX				;AC000;
;AD054; POP	BX				;AC000;
	invoke	RPRINT				;AC054;

	POP	ES				;AN000;
	POP	DS				;AN000;
	pop	ax
	ret

PATHCHRCMPR:
	push	dx
	mov	dl,[fslash]
	CMP	[RSWITCHAR],dl
	JZ	RNOSLASHT
	CMP	AL,dl
	JZ	RET41
RNOSLASHT:
	CMP	AL,[bslash]
RET41:
	pop	dx
	RET


IFINDE:
	CALL	IFIND				; FIND THE NAME
	JC	IFIND2				; CARRY MEANS NOT FOUND
	JMP	ISCASB1 			; SCAN FOR = SIGN
;
; On return of FIND1, ES:DI points to beginning of name
;
IFIND:
	CLD
	CALL	ICOUNT0 			; CX = LENGTH OF NAME
	MOV	ES,[ENVIRSEG]
	XOR	DI,DI

IFIND1:
	PUSH	CX
	PUSH	SI
	PUSH	DI

IFIND11:
	LODSB

;;;;	IF	KANJI		3/3/KK
	invoke	ITESTKANJ
	JZ	NotKanj4_INIT
	DEC	SI
	LODSW
	INC	DI
	INC	DI
	CMP	AX,[es:DI-2]
	JNZ	IFIND12
	DEC	CX
	LOOP	IFIND11
	jmp     IFIND12

NotKanj4_INIT:
;;;;	ENDIF			3/3/KK

	CALL	iupconv
	INC	DI
	CMP	AL,[es:DI-1]
	JNZ	IFIND12
	LOOP	IFIND11

IFIND12:
	POP	DI
	POP	SI
	POP	CX
	JZ	IFIND2
	PUSH	CX
	CALL	ISCASB2 			; SCAN FOR A NUL
	POP	CX
	CMP	byte [es:DI],0
	JNZ	IFIND1
	STC					; INDICATE NOT FOUND

IFIND2:
	RET

ICOUNT0:
	PUSH	DS
	POP	ES
	MOV	DI,SI

	PUSH	DI				; COUNT NUMBER OF CHARS UNTIL "="
	CALL	ISCASB1
	jmp     ICOUNTX
	PUSH	DI				; COUNT NUMBER OF CHARS UNTIL NUL
	CALL	ISCASB2

ICOUNTX:
	POP	CX
	SUB	DI,CX
	XCHG	DI,CX
	RET

ISCASB1:
	MOV	AL,[equalsign] ; SCAN FOR AN =
	jmp     ISCASBX

ISCASB2:
	XOR	AL,AL				; SCAN FOR A NUL

ISCASBX:
	MOV	CX,100H
	REPNZ	SCASB
	RET


; ****************************************************************
; *
; * ROUTINE:	 IUPCONV    (ADDED BY EMG 4.00)
; *
; * FUNCTION:	 This routine returns the upper case equivalent of
; *		 the character in AL from the file upper case table
; *		 in DOS if character if above  ascii 128, else
; *		 subtracts 20H if between "a" and "z".
; *
; * INPUT:	 DS	      set to resident
; *		 AL	      char to be upper cased
; *		 FUCASE_ADDR  set to the file upper case table
; *
; * OUTPUT:	 AL	      upper cased character
; *
; ****************************************************************

;assume	ds:resgroup				;AN000;

iupconv:			;AN000;

	cmp	al,80h				;AN000; see if char is > ascii 128
	jb	other_fucase			;AN000; no - upper case math
	sub	al,80h				;AN000; only upper 128 chars in table
	push	ds				;AN000;
	push	bx				;AN000;
	lds	bx,dword [FUCASE_ADDR+1]   ;AN000;  get table address
	add	bx,2				;AN000;  skip over first word
	xlat	byte [ds:bx]      ;AN000;  convert to upper case
	pop	bx				;AN000;
	pop	ds				;AN000;
	jmp     iupconv_end    ;AN000;  we finished - exit

other_fucase:					;AN000;
	cmp	al,[lcasea] ;AC000; if between "a" and "z",
	jb	iupconv_end			;AC000;     subtract 20h to get
	cmp	al,[lcasez] ;AC000; upper case equivalent.
	ja	iupconv_end			;AC000;
	sub	al,20h				;AC000; Change lower-case to upper

iupconv_end:					;AN000;
	ret

;iupconv endp					;AN000;

init_contc_specialcase:
						; This routine is called if control-C
	add	sp,6				;  is type during the date/time prompt
	push	si				;  at initialization time.  The desired
	mov	si,dx				;  response is to make it look like the
	mov	word [si+1],0d00h      ;  user typed <CR> by "popping" the
	pop	si				;  INT 21h stuff off the stack, putting
	iret					;  a <CR> in the user's buffer, and
						;  returning directly to the user.
						; In this case the user is TCODE.

; ****************************************************************
; *
; * ROUTINE:	 GET_MSG_PTR
; *
; * FUNCTION:	 Fill in translatable char table starting at
; *		 at Abort_char with translated characters.
;		 Set segments of resident messages.
; *
; * INPUT:	 none
; *
; * OUTPUT:	 none
; *
; ****************************************************************

CHAR_START	EQU	201			;AN000; first character translate is 1
CHAR_END	EQU	207			;AN000;        last is 6

GET_MSG_PTR:			;AN000;

	MOV	AX,CHAR_START			;AN000; get first char translation
	MOV	BX,abort_char                 ;AN000; get first char offset
MOVEMES:					;AN000;
	MOV	DH,-1				;AN000; utility message
	invoke	SYSGETMSG			;AN000; get the offset of the char
	MOV	CL,byte [SI]      ;AN000; get the character in CL
	MOV	byte [BX],CL      ;AN000; put the character in the table
	INC	BX				;AN000; point to next position in table
	INC	AX				;AN000; increment message number
	CMP	AX,CHAR_END			;AN000; are we at the end?
	JNZ	MOVEMES 			;AN000; no - keep loading

	MOV	AX,DS				;AN000; get data segment
	MOV	[DRVNUM_OP_SEG],AX ;AN000; set up segments for
	MOV	[DRVNUM_OP_SEG2],AX        ;AN000;    message substitutions
	MOV	[DEVE_OP_SEG],AX ;AN000;    used in the resident
	MOV	[DEVE_OP_SEG2],AX ;AN000;    portion of command
	MOV	[ERR15_OP_SEG],AX ;AN000;    during initialization
	MOV	[ERR15_OP_SEG2],AX ;AN000;    to save resident
	MOV	[ERR15_OP_SEG3],AX ;AN000;    space.
	MOV	[BADFAT_OP_SEG],AX ;AN000;
	MOV	[COMPRMT1_SEG],AX ;AN000;
	MOV	[COMPRMT1_SEG2],AX ;AN000;

	RET					;AN000;

;GET_MSG_PTR	ENDP				;AN000;


; ****************************************************************
; *
; * ROUTINE:	 Setup_for_messages
; *
; * FUNCTION:	 Sets up system for PARSE and EXTENDED ERROR
; *		 messages as follows:
; *
; *		 IF /P and /MSG are entered
; *		    keep PARSE and EXTENDED ERRORS in memory
; *		 ELSE IF /P is entered
; *		    use PARSE and EXTENDED ERRORS on disk
; *		    remove PARSE ERRORS from memory
; *		 ELSE
; *		    remove PARSE ERRORS from memory
; *		 ENDIF
; *
; * INPUT:	 PERMCOM	Set up with user input
; *		 EXT_MSG	Set up with user input
; *		 System set up to retain PARSE ERRORS
; *
; * OUTPUT:	 registers unchanged
; *
; ****************************************************************


setup_for_messages:			;AN060;

	push	ds				;AN060; save data segment
	push	es				;AN060; save environment segment
	push	ax				;AN060;
	push	dx				;AN060;
	push	di				;AN060;
	mov	ax,cs				;AN060; get local segment to ES and DS
	mov	ds,ax				;AN060;
	mov	es,ax				;AN060;

	cmp	byte [PERMCOM],0   ;AN060; was permcom set?
	jz	no_permcom			;AN060; No - don't worry about messages
	cmp	byte [ext_msg],SET_EXTENDED_MSG    ;AN060; was /msg specified?
	jz	permcom_slash_msg		;AN060; Yes - go process it
	push	es				;AN060;
	mov	ax,1				;AN060; Set ES to 1 as a flag to the message
	mov	es,ax				;AN060;    services that messages are on disk
	mov	di,EXTENDED_MSG_START-100h                 ;AN060; start address
	call	Set_ext_2f			;AN060; set extended error address
	mov	di,PARSE_MSG_START-0100h                 ;AN060; start address
	call	Set_parse_2f			;AN060; set parse error address
	pop	es				;AN060;
;	IF2					;AN060;;
;	IFNDEF	READ_DISK_INFO			;AN060;;
;		Extrn	READ_DISK_PROC:Far	;AN060;;
;	ENDIF					;AN060;;
;	ENDIF					;AN060;;
	MOV	AX,DOS_GET_EXT_PARSE_ADD	;AN060;; 2FH Interface
	MOV	DL,DOS_SET_ADDR 		;AN060;; Set the READ_DISK_PROC address
	LEA	DI,[READ_DISK_PROC];AN060;;
	INT	2FH				;AN060;; Private interface
	jmp     permcom_end    ;AN060; and exit

permcom_slash_msg:				;AN060; Keep messages in memory
	mov	di,EXTENDED_MSG_START                 ;AN060; start address
	call	Set_ext_2f			;AN060; set the extended message address
	mov	di,EXTMSGEND+15                 ;AN060; get address of resident end
	mov	[RESMSGEND],di			;AN060; save it
	jmp     permcom_end    ;AN060; exit

no_permcom:					;AN060;
	cmp	byte [ext_msg],SET_EXTENDED_MSG    ;AN060; was /msg specified?
	jnz	no_slash_msg			;AN060; no - no error
	mov	byte [DISP_CLASS],parse_msg_class  ;AN060; set up parse error msg class
	mov	dx,LessArgs_Ptr 		;AN060; get message number for "Required parameter missing"
	call	print_message			;AN060; issue error message

no_slash_msg:
	mov	ax,(MultDOS shl 8 or MESSAGE_2F);AN060; reset parse message pointers
	mov	dl,SET_PARSE_MSG		;AN060; set up parse message address
	mov	di,[PARS_MSG_OFF] ;AN060; old offset of parse messages
	mov	es,[PARS_MSG_SEG] ;AN060; old segment of parse messages
	int	2fh				;AN060; go set it

permcom_end:
	call	sysloadmsg			;AN060; load message addresses
	pop	di				;AN060;
	pop	dx				;AN060;
	pop	ax				;AN060;
	pop	es				;AN060; get environment back
	pop	ds				;AN060;

	ret					;AN060;

;setup_for_messages	endp			;AN060;

; ****************************************************************
; *
; * ROUTINE:	 Set_parse_2f
; *
; * FUNCTION:	 Does the INT 2Fh to DOS to set the PARSE
; *		 message address that will later be retrieved
; *		 by the message services.
; *
; * INPUT:	 ES set to segment of messages
; *		 DI points to offset of messages
; *
; * OUTPUT:	 none
; *
; ****************************************************************

Set_parse_2f:			;AN060;

	mov	ax,(MultDOS shl 8 or MESSAGE_2F);AN060; set up to call DOS through int 2fh
	mov	dl,SET_PARSE_MSG		;AN060; set up parse message address
	int	2fh				;AN060;

	ret					;AN060;

;Set_parse_2f	endp				;AN060;

; ****************************************************************
; *
; * ROUTINE:	 Set_ext_2f
; *
; * FUNCTION:	 Does the INT 2Fh to DOS to set the EXTENDED
; *		 message address that will later be retrieved
; *		 by the message services.
; *
; * INPUT:	 ES set to segment of messages
; *		 DI points to offset of messages
; *
; * OUTPUT:	 none
; *
; ****************************************************************

Set_ext_2f:			;AN060;

	mov	ax,(MultDOS shl 8 or MESSAGE_2F);AN060; set up to call DOS through int 2fh
	mov	dl,SET_EXTENDED_MSG		;AN060; set up extended error message address
	int	2fh				;AN060;

	ret					;AN060;

;Set_ext_2f	endp				;AN060;


;ASSUME	DS:RESGROUP, ES:RESGROUP

.xlist
.xcref

include 'SYSMSG.INC'  ;AN000; include message services

.list
.cref

MSG_UTILNAME <COMMAND>				;AN000; define utility name

MSG_SERVICES <COMR,NEARmsg,LOADmsg,NOCHECKSTDIN,NOCHECKSTDOUT>	;AC026; include message services macro

include 'MSGDCL.INC'

end if

;	END
