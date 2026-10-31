 PAGE 80,132
;	SCCSID = @(#)tenv2.asm	1.1 85/05/14
;	SCCSID = @(#)tenv2.asm	1.1 85/05/14
TITLE	Part6 COMMAND Transient routines.

;	Environment utilities and misc. routines

	include 'COMSW.ASM'

.xlist
.xcref
	include 'DOSSYM.INC'
	include 'COMSEG.ASM'
	include 'COMEQU.ASM'
.list
.cref


if SEGSEL = S_DATARES	;AC000;
;	EXTRN	pipeflag:byte
end if

if SEGSEL = S_TRANDATA	;AC000;
;	EXTRN	ACRLF_PTR:WORD
;	EXTRN	BadCD_Ptr:WORD
;	EXTRN	Badmkd_ptr:word
;	EXTRN	BADRMD_PTR:WORD
;	EXTRN	Extend_buf_ptr:word	;AN000;
;	EXTRN	Extend_buf_sub:byte	;AN022;
;	EXTRN	MD_exists_ptr:word	;AN006;
;	EXTRN	msg_disp_class:byte	;AC000;
;	EXTRN	NOSPACE_PTR:WORD
;	EXTRN	parse_chdir:byte	;AC000;
;	EXTRN	parse_mrdir:byte	;AC000;
;	EXTRN	PIPEEMES_PTR:WORD
;	EXTRN	string_buf_ptr:word
end if

if SEGSEL = S_TRANSPACE	;AC000;
;	EXTRN	CURDRV:BYTE
;	EXTRN	DESTINFO:BYTE
;	EXTRN	DESTTAIL:WORD
;	EXTRN	DIRCHAR:BYTE
;	EXTRN	dirflag:byte		;AN015;
;	EXTRN	KPARSE:BYTE		;AC000;  3/3/KK
;	EXTRN	msg_numb:word		;AN022;
;	EXTRN	parse1_addr:dword	;AC000;
;	EXTRN	parse1_type:byte	;AC000;
;	EXTRN	PATHPOS:WORD
;	EXTRN	RESSEG:WORD
;	EXTRN	srcxname:byte		;AC000;
;	EXTRN	string_ptr_2:word
;	EXTRN	SWITCHAR:BYTE
;	EXTRN	USERDIR1:BYTE
end if

if SEGSEL = S_TRANCODE

;ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;	EXTRN	cerror:near

;	PUBLIC	$chdir
;	PUBLIC	$mkdir
;	PUBLIC	$rmdir
;	PUBLIC	crlf2
;	PUBLIC	crprint
;	PUBLIC	delim
;	PUBLIC	error_output
;	PUBLIC	fcb_to_ascz
;	PUBLIC	pathchrcmp
;	PUBLIC	pathcrunch
;	PUBLIC	savudir
;	PUBLIC	savudir1
;	PUBLIC	scanoff
;	PUBLIC	strcomp

BREAK	CHDir$

; ****************************************************************
; *
; * ROUTINE:	 $CHDIR
; *
; * FUNCTION:	 Entry point for CHDIR command. Parse the command
; *		 line. If path is found, CHDIR to path. If a drive
; *		 letter is found, get and display the current dir
; *		 of the specified drive. If nothing is found, get
; *		 and display the current dir of the default drive.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

;assume	ds:trangroup,es:trangroup

CHDir$:

	mov	si,81H
	mov	di,PARSE_CHDIR                  ;AN000; Get adderss of PARSE_CHDIR
	xor	cx,cx				;AN000; clear cx,dx
	xor	dx,dx				;AN000;
	invoke	parse_with_msg			;AC018; call parser

	cmp	ax,end_of_line			;AC000; are we at end of line?
	jz	bwdJ				; No args
	cmp	ax,result_no_error		;AC000; did we have an error?
	jnz	ChDirErr			;AC018; yes - exit

	cmp	byte [PARSE1_TYPE],result_drive    ;AC000; was a drive entered?
	jnz	REALCD				; no
;
; D: was found.  See if there is anything more.
;
	mov	di,PARSE_CHDIR                  ;AC000; get address of parse_chdir
	xor	dx,dx				;AC000;
	invoke	parse_check_eol 		;AC000; call parser
	jnz	ChDirErr			;AC000;

bwdJ:
	invoke	build_dir_for_chdir		; Drive only specified
	call	CRLF2
	return

REALCD:

	push	si				;AN000; save position in line
	lds	si,dword [PARSE1_ADDR]     ;AN000; get address of filespec
	invoke	MOVE_TO_SRCBUF			;AN000; move to srcbuf
	pop	si				;AN000; restore position in line
	mov	di,PARSE_CHDIR                  ;AC000; get address of parse_chdir
	xor	dx,dx				;AC000;
	invoke	parse_check_eol 		;AC000; call parser
	jnz	ChDirErr			;AC000;

	invoke	SETPATH
	TEST	byte [DESTINFO],2
	JNZ	BadChDir
	MOV	AH,CHDir
	INT	int_command
	retnc

	invoke	Get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_path_not_found 	;AN022; see if path not found
	jz	BadChDir			;AN022; yes - issue old message
	call	Set_ext_error_subst		;AN022;
	jmp     ChDirErr      ;AN022;

BadChDir:
	MOV	DX,BadCD_Ptr

ChDirErr:
	invoke	STD_EPRINTF
	return

BREAK	MKDir$

;assume	ds:trangroup,es:trangroup

MKDir$:
	CALL	SETRMMK
	JC	MkDirErr
	MOV	AH,MKDir
	INT	int_command
	retnc

	invoke	Get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_path_not_found 	;AN022; see if path not found
	jz	MD_other_err			;AN022; yes - issue old message
	cmp	ax,error_access_denied		;AN022; access denied?
	jz	BADMDERR			;AN022; yes - see if file exists

	call	Set_ext_error_subst		;AN022;
	jmp     MkDirErr     ;AC022; yes - go print it

BADMDERR:
	mov	dx,SRCXNAME                  ;AN006; Set Disk transfer address
	mov	ah,Set_DMA			;AN006;
	int	int_command			;AN006;
	MOV	AH,Find_First			;AN006; see if file/dir exists
	mov	cx,attr_directory		;AN006;   search for directory
	INT	int_command			;AN006;
	jc	MD_other_err			;AN006; doesn't exist - must be something else
	mov	dl,byte [SRCXNAME+find_buf.find_buf_attr]  ;AN006; we found a file/dir
	test	dl,attr_directory		;AN006; was it a directory?
	jz	MD_other_err			;AN006; no - must have been a file
	mov	dx,MD_exists_ptr                  ;AN006; set up already exists error
	jmp     MkDirErr     ;AN006; make sure we didn't have network error
MD_other_err:					;AN006;
	MOV	DX,BadMkD_Ptr
MkDirErr:
	invoke	STD_EPRINTF
	return

BREAK	<Common MKDir/RMDir set up code>

;****************************************************************
;*
;* ROUTINE:	SETRMMK
;*
;* FUNCTION:	Parse routine for the internal MKDIR and RMDIR
;*		commands. Parses the command line for a required
;*		filespec.
;*
;* INPUT:	command line at offset 81H
;*
;* OUTPUT:	carry clear
;*		    DS:DX points to ASCIIZ argument
;*		carry set
;*		    DS:DX has error message pointer
;*
;****************************************************************

SETRMMK:
	mov	si,81H
	mov	di,PARSE_MRDIR                  ;AN000; Get adderss of PARSE_MRDIR
	xor	cx,cx				;AN000; clear cx,dx
	xor	dx,dx				;AN000;
	invoke	parse_with_msg			;AC000; call parser
	cmp	ax,result_no_error		;AC000; did we have an error?
	jnz	 NOARGERR			;AC000; yes - exit

	mov	di,SRCXNAME                  ;AN000; get address of srcxname
	push	di				;AN000; save address
	push	si				;AN000; save position in line
	lds	si,dword [PARSE1_ADDR]     ;AN000; get address of path

mrdir_move_filename:				;AN000; put filespec in srcxname
	lodsb					;get a char from buffer
	stosb					;AN000; store in srcxname
	cmp	al,end_of_line_out		;AC000; it char a terminator?
	jnz	mrdir_move_filename		;AC000; no - keep moving
	pop	si				;AN000; get line position back

;
; we have scanned an argument.	See if any args beyond.
;

	mov	di,PARSE_MRDIR                  ;AC000; get address of parse_mrdir
	invoke	parse_check_eol 		;AC000; are we at end of line?
	pop	dx				;AC000; get address of SRCXNAME
	retz					;yes - return no error
NOARGERR:
	mov	dx,Extend_Buf_ptr                   ;AC000; get extended message pointer
	XOR	AX,AX
	STC
	return

BREAK	RMDir$

;assume	ds:trangroup,es:trangroup

RMDir$:
	CALL	SETRMMK
	JC	RmDirErr
	JNZ	BADRDERR
	MOV	AH,RMDir
	INT	int_command
	retnc

	invoke	Get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_path_not_found 	;AN022; see if path not found
	jz	BADRDERR			;AN022; yes - issue old message
	cmp	ax,error_access_denied		;AN022; access denied?
	jz	BADRDERR			;AN022; yes - issue old message

	call	Set_ext_error_subst		;AN022;
	jmp     RmDirErr     ;AC022; yes - go print it

BADRDERR:
	MOV	DX,BadRmD_Ptr

RmDirErr:
	invoke	STD_EPRINTF
	return

;****************************************************************
;*
;* ROUTINE:	Set_ext_error_subst
;*
;* FUNCTION:	Sets up substitution for extended error
;*
;* INPUT:	AX - extended error number
;*		DX - offset of string
;*
;* OUTPUT:	Extend_Buf_Ptr set up for STD_EPRINTF
;*
;****************************************************************

Set_ext_error_subst:			;AN022;

	mov	byte [msg_disp_class],ext_msg_class        ;AN022; set up extended error msg class
	mov	[string_ptr_2],dx ;AN022; get address of failed string
	mov	byte [Extend_Buf_sub],one_subst    ;AN022; put number of subst in control block
	mov	dx,Extend_Buf_ptr                  ;AN022; get extended message pointer
	mov	[Extend_Buf_ptr],ax        ;AN022; get message number in control block

	ret					;AN022; return

;Set_ext_error_subst  endp			;AN022;





BREAK	<SAVUDIR - preserve the users current directory on a particular drive>

;
; SavUDir - move the user's current directory on a drive into UserDir1
; SavUDir1 - move the user's current directory on a drive into a specified
;   buffer
;
;   Inputs:	DL has 1-based drive number
;		ES:DI has destination buffer (SavUDir1 only)
;   Outputs:	Carry Clear
;		    DS = TranGroup
;		Carry Set
;		    AX has error code
;   Registers Modified: AX, SI
;

SAVUDIR:
	MOV	DI,USERDIR1

SAVUDIR1:
	MOV	AL,DL
	ADD	AL,'@'
	CMP	AL,'@'
	JNZ	GOTUDRV
	ADD	AL,[CURDRV]
	INC	AL				; A = 1

GOTUDRV:
	STOSB
	MOV	AH,[DIRCHAR]
	MOV	AL,':'
	STOSW
	PUSH	ES
	POP	DS
;ASSUME	DS:NOTHING

	MOV	SI,DI
	MOV	AH,Current_Dir			; Get the Directory Text
	INT	int_command
	retc
	PUSH	CS
	POP	DS
;ASSUME	DS:TRANGROUP

	return


CRLF2:
	PUSH	DX
	MOV	DX,ACRLF_Ptr

PR:
	PUSH	DS
	PUSH	CS
	POP	DS
	invoke	STD_PRINTF
	POP	DS
	POP	DX

	return

;
; These routines (SCANOFF, DELIM) are called in batch processing when DS
; may NOT be TRANGROUP
;
;ASSUME	DS:NOTHING,ES:NOTHING

SCANOFF:
	LODSB
	CALL	DELIM
	JZ	SCANOFF
	DEC	SI				; Point to first non-delimiter
	return

;
; Input:    AL is character to classify
; Output:   Z set if delimiter
;	    NZ set otherwise
; Registers modified: none
;

DELIM:
	CMP	AL,' '
	retz
	CMP	AL,'='
	retz
	CMP	AL,','
	retz
	CMP	AL,';'
	retz
	CMP	AL,9				; Check for TAB character
	retz
	CMP	AL,0ah				; Check for line feed character - BAS
	return


;ASSUME	DS:TRANGROUP,ES:TRANGROUP


FCB_TO_ASCZ:					; Convert DS:SI to ASCIZ ES:DI
	MOV	CX,8

MAINNAME:
	LODSB
	CMP	AL,' '
	JZ	SKIPSPC
	STOSB

SKIPSPC:
	LOOP	MAINNAME
	LODSB
	CMP	AL,' '
	JZ	GOTNAME
	MOV	AH,AL
	MOV	AL,dot_chr
	STOSB
	XCHG	AL,AH
	STOSB
	MOV	CL,2

EXTNAME:
	LODSB
	CMP	AL,' '
	JZ	GOTNAME
	STOSB
	LOOP	EXTNAME

GOTNAME:
	XOR	AL,AL
	STOSB
	return

STRCOMP:
;
; Compare ASCIZ DS:SI with ES:DI.
; SI,DI destroyed.
;
	CMPSB
	retnz					; Strings not equal
	cmp	byte [SI-1],0      ; Hit NUL terminator?
	retz					; Yes, strings equal
	jmp     STRCOMP     ; Equal so far, keep going


CRPRINT:
	PUSH	AX
	MOV	AL,13
	PUSH	CX
	PUSH	DI
	MOV	DI,DX
	MOV	CX,-1
	PUSH	ES
	PUSH	DS
	POP	ES

	REPNZ	SCASB				; LOOK FOR TERMINATOR
	mov	byte [di-1],0      ; nul terminate the string
	POP	ES
	mov	[string_ptr_2],dx
	mov	dx,String_Buf_Ptr
	invoke	STD_PRINTF
	mov	byte [ds:di-1],13      ; now put the CR back
	JC	ERROR_OUTPUT

	POP	DI
	POP	CX
	POP	AX

	return

ERROR_OUTPUT:
	PUSH	CS
	POP	DS
;ASSUME	DS:TRANGROUP
	MOV	ES,[RESSEG]
;ASSUME	ES:RESGROUP

	MOV	DX,NoSpace_Ptr
	CMP	byte [PIPEFLAG],0
	JZ	GO_TO_ERROR_TENV2

	invoke	PipeOff
	MOV	DX,PipeEMes_Ptr
GO_TO_ERROR_TENV2:
	JMP	CERROR

;ASSUME	DS:TRANGROUP,ES:TRANGROUP

PATHCHRCMP:
;---- Mod for path invocation ----
;PUBLIC pathchrcmp
;----

	push	ax
	mov	ah,'/'
	CMP	[SWITCHAR],ah
	JZ	NOSLASHT
	CMP	AL,'/'
	jz	pccont_TENV2

NOSLASHT:
	CMP	AL,'\'
pccont_TENV2:
	pop	ax

	return

; Drive taken from FCB
; User dir saved in userdir1
;
; Zero set if path dir, CHDIR to this dir, FCB filled with ?
; NZ set if path/file, CHDIR to file, FCB has file (parsed fill ' ')
;	[DESTTAIL] points to parse point
; Carry set if no CHDIRs worked, FCB not altered.
; DESTISDIR set non zero if PATHCHRs in path (via SETPATH)
;
PATHCRUNCH:
	mov	word [msg_numb],0  ;AN022; Set up message flag
	MOV	DL,[ds:FCB]
	CALL	SAVUDIR
	jc	pcrunch_cderrj			;AN022; if error on current dir - report

	invoke	SETPATH
	TEST	byte [DESTINFO],2
	JNZ	TRYPEEL 			; If ? or * cannot be pure dir

	MOV	AH,CHDir
	INT	int_command
	jnc	chdir_worked			;AN022; no error - continue

	invoke	Get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_path_not_found 	;AN022; if path not found
	jz	TRYPEEL 			;AC022;     keep trying
	cmp	ax,error_access_denied		;AN022; if access denied
	jz	TRYPEEL 			;AC022;     keep trying
	mov	[msg_numb],ax			;AN022; set up message flag
	jmp	PEELFAIL			;AN022; exit with other error

chdir_worked:
	invoke	SETREST1
	MOV	AL,'?'                          ; *.* is default file spec if pure dir
	MOV	DI,5DH
	MOV	CX,11
	REP	STOSB
	XOR	AL,AL				; Set zero
	return

pcrunch_cderrj: 				;AN022; need this for long jmp
	jmp	pcrunch_cderr			;AN022;

TRYPEEL:
	MOV	SI,[PATHPOS]
	DEC	SI				; Point at NUL
	MOV	AL,[SI-1]

	CMP	byte [KPARSE],0
	JNZ	DELSTRT 			; Last char is second KANJI byte, might be '\'

	CALL	PATHCHRCMP
	JZ	PEELFAIL			; Trailing '/'

DELSTRT:
	MOV	CX,SI
	MOV	SI,DX
	PUSH	DX
DELLOOP:
	CMP	SI,CX
	JZ	GOTDELE
	LODSB
	invoke	TESTKANJ
	JZ	NOTKANJ8
	INC	SI
	JMP	DELLOOP

NOTKANJ8:
	CALL	PATHCHRCMP
	JNZ	DELLOOP
	MOV	DX,SI
	DEC	DX
	JMP	DELLOOP

GOTDELE:
	MOV	SI,DX
	POP	DX
	CMP	SI,DX
	JZ	BADRET
	MOV	CX,SI
	MOV	SI,DX
DELLOOP2:					; Set value of KPARSE
	CMP	SI,CX
	JZ	TRYCD
	MOV	byte [KPARSE],0
	LODSB
	invoke	TESTKANJ
	JZ	DELLOOP2
	INC	SI
	INC	byte [KPARSE]
	JMP	DELLOOP2

TRYCD:
	push	ax
	mov	al,dot_chr
	CMP	byte [SI+1],al
	pop	ax
	JZ	PEELFAIL			; If . or .., pure cd should have worked
	mov	al,[si-1]
	CMP	al,':'                          ; Special case d:\file
	JZ	BADRET

	CMP	byte [KPARSE],0
	JNZ	NOTDOUBLESL			; Last char is second KANJI byte, might be '\'

	CALL	PATHCHRCMP
	JNZ	NOTDOUBLESL
PEELFAIL:
	STC					; //
	return
NOTDOUBLESL:
	MOV	byte [SI],0
	MOV	AH,CHDir
	INT	int_command
	JNC	CDSUCC
pcrunch_cderr:
	invoke	Get_ext_error_number		;AN022; get the extended error
	mov	[msg_numb],ax			;AN022; set up message flag
	or	si,si				;AN022; set up zero flag to not zero
	stc					;AN022; set up carry flag
	return

BADRET:
	MOV	AL,[SI]
	CALL	PATHCHRCMP			; Special case 'DIRCHAR'file
	STC
	retnz
	XOR	BL,BL
	XCHG	BL,[SI+1]
	MOV	AH,CHDir
	INT	int_command
	jc	pcrunch_cderr			;AN022; go to error exit
	MOV	[SI+1],BL
CDSUCC:
	invoke	SETREST1
	INC	SI				; Reset zero
	MOV	[DESTTAIL],SI
	pushf					;AN015; save flags
	cmp	byte [dirflag],-1  ;AN015; don't do parse if in DIR
	jz	pcrunch_end			;AN015;
	MOV	DI,FCB
	MOV	AX,(Parse_File_Descriptor SHL 8) OR 02H ; Parse with default drive
	INT	int_command
pcrunch_end:
	popf					;AN015; get flags back
	return

end if
;	    end
