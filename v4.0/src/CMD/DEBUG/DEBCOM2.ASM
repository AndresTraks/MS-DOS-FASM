	PAGE	60,132 ;
	TITLE	DEBCOM2.ASM - PART2 DEBUGGER COMMANDS	PC DOS
;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: DECOM2.SAL
;
; DESCRIPTIVE NAME: DEBUGGING TOOL
;
; FUNCTION: PROVIDES USERS WITH A TOOL FOR DEBUGGING PROGRAMS.
;
; ENTRY POINT: ANY CALLED ROUTINE
;
; INPUT: NA
;
; EXIT NORMAL: NA
;
; EXIT ERROR: NA
;
; INTERNAL REFERENCES:
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: DEBCOM1 - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBCOM3 - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBASM  - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBUASM - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBMES  - CONTAINS ROUTINES CALLED BY DEBUG
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK DEBUG+DEBCOM1+DEBCOM2+DEBCOM3+DEBASM+DEBUASM+DEBERR+
;	      DEBCONST+DEBDATA+DEBMES
;
; REVISION HISTORY:
;
;	AN000	VERSION 4.00 - REVISIONS MADE RELATE TO THE FOLLOWING:
;	AC000	VERSION 4.00 -
;
;				- IMPLEMENT DBCS HANDLING	DMS:6/17/87
;				- IMPLEMENT MESSAGE RETRIEVER	DMS:6/17/87
;				- IMPLEMENT > 32MB SUPPORT	DMS:6/17/87
;
; COPYRIGHT: "MS DOS DEBUG UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;	     "LICENSED MATERIAL - PROPERTY OF Microsoft  "
;
;======================= END OF SPECIFICATIONS ===========================

; Routines to perform debugger commands except ASSEMble and UASSEMble

;	IF1
;	    %OUT COMPONENT=DEBUG, MODULE=DEBCOM2
;	ENDIF
.XLIST
.XCREF
	include 'DOSSYM.INC'
	include 'DEBEQU.ASM'
.CREF
.LIST
if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
;	EXTRN	NOTFND_PTR:BYTE,NOROOM_PTR:BYTE,DRVLET:BYTE,ERRMES_PTR:BYTE
;	EXTRN	NAMBAD_PTR:BYTE,NOSPACE_PTR:BYTE,TOOBIG_PTR:BYTE
;	EXTRN	HEXERR_PTR:BYTE,HEXWRT_PTR:BYTE,ACCMES_PTR:BYTE
;	EXTRN	EXEBAD_PTR:BYTE,EXEWRT_PTR:BYTE
;	EXTRN	EXECEMES_PTR:BYTE,NONAMESPEC_PTR:BYTE

;	EXTRN	FLAGTAB:WORD,EXEC_BLOCK:BYTE,COM_LINE:DWORD,COM_FCB1:DWORD
;	EXTRN	COM_FCB2:DWORD,COM_SSSP:DWORD,COM_CSIP:DWORD,RETSAVE:WORD
;	EXTRN	NEWEXEC:BYTE,HEADSAVE:WORD
;	EXTRN	REGTAB:BYTE,TOTREG:BYTE,NOREGL:BYTE
;	EXTRN	USER_PROC_PDB:WORD,STACK_:BYTE,RSTACK:WORD,AXSAVE:WORD
;	EXTRN	BXSAVE:WORD,DSSAVE:WORD,ESSAVE:WORD,CSSAVE:WORD,IPSAVE:WORD
;	EXTRN	SSSAVE:WORD,CXSAVE:WORD,SPSAVE:WORD,FLSAVE:WORD
;	EXTRN	SREG:BYTE,SEGTAB:WORD,REGDIF:ABS,RDFLG:BYTE
;	EXTRN	REGTABEND:WORD
;	EXTRN	NAMESPEC:BYTE
end if

if SEGSEL = S_CSTACK
end if

if SEGSEL = S_DATA
;	EXTRN	DEFDUMP:BYTE,TRANSADD:DWORD,INDEX:WORD,BUFFER:BYTE
;	EXTRN	ASMADD:BYTE,DISADD:BYTE,NSEG:WORD
;	EXTRN	SWITCHAR:BYTE,XNXCMD:BYTE,XNXOPT:BYTE
;	EXTRN	AWORD:BYTE,EXTPTR:WORD,HANDLE:WORD,PARSERR:BYTE
;	EXTRN	REG_NAME:WORD,REG_CONTENTS:WORD,REGISTER_PTR:BYTE
;	EXTRN	ARG_BUF:BYTE,ARG_BUF_PTR:BYTE,LOC_ADD:WORD,LOC_PTR:BYTE
;	EXTRN	BIG_CONTENTS:WORD,BIG_PTR:BYTE,LITTLE_CONTENTS:WORD,LITTLE_PTR:BYTE
;	EXTRN	SINGLE_REG_ARG:WORD,CHANGE_FLAG_PTR:BYTE,DF_ERROR:BYTE
;	EXTRN	BR_ERROR:BYTE,BF_ERROR:BYTE,SINGLE_REG_PTR:WORD
;	EXTRN	WRT_ARG1:WORD,WRT_ARG2:WORD,WRTMES_PTR:BYTE,BEGSEG:WORD
;	EXTRN	FILESTRT:WORD,FILEEND:WORD
;	EXTRN	ERR_TYPE:BYTE			;ac000;converted to buffer

;	extrn	rel_read_write_tab:dword		;an000;primitive I/O
;	extrn	rel_rw_add:dword			;an000;transfer address
;	extrn	rel_low_sec:word			;an000;low sector word
;	extrn	rel_high_sec:word			;an000;high sector word
;	extrn	rel_sec_num:word			;an000;# of sectors

fnd_dbcs db    0
end if

;DG	GROUP	CODE,CONST,CSTACK,DATA

if SEGSEL = S_CODE
;ASSUME	CS:DG,DS:DG,ES:DG,SS:DG
;	PUBLIC	DEFIO,PREPNAME,DEBUG_FOUND
;	PUBLIC	REG,LOAD_
;	PUBLIC	NAMED,DWRITE
;	PUBLIC	DISPREG,ERR_,DELIM1,DELIM2,delim0
;	public	getchrup,open1,open2,open3,open4,oc_file,opnret 		;an001;bgb
;	public	delete_a_file, parse_a_file, exec_a_file, open_a_file, create_a_file ;an001;bgb
;	public	gcur,ifhex							;an001;bgb
;	public	comtail 							;an001;bgb
;	extrn	test_lead:near							;an001;bgb
;	EXTRN	OUTSI:NEAR,OUTDI:NEAR,INBUF:NEAR,SCANB:NEAR,SCANP:NEAR
;	EXTRN	COMMAND:NEAR,DISASLN:NEAR,SET_TERMINATE_VECTOR:NEAR
;	EXTRN	RESTART:NEAR,TERMINATE:NEAR,DRVERR:NEAR
;	EXTRN	GETHEX:NEAR,GETEOL:NEAR,SKIP_FILE:NEAR
;	EXTRN	HEXCHK:NEAR,GETHEX1:NEAR,PRINT:NEAR
;	EXTRN	CRLF:NEAR,BLANK:NEAR
;	EXTRN	HEX:NEAR,DIGIT:NEAR
;	EXTRN	FIND_DEBUG:NEAR
;	EXTRN	ADDRESS:NEAR,PERROR:NEAR
;	EXTRN	STD_PRINTF:NEAR,PRINTF_CRLF:NEAR
DEBCOM2:
DISPLAY_LINE:
	mov	ax,word [si]      ;an000;move reg name to ax
	MOV	[reg_name],ax			;ac000;save it in reg_name
	ADD	SI,3
	MOV	AX,[BX]
	ADD	BX,2
	MOV	[reg_contents],AX
	MOV	DX,register_ptr
	CALL	STD_PRINTF

	LOOP	DISPLAY_LINE

	return

DISPLAY_FLAGS:
	MOV	DI,arg_buf
	MOV	AL,CHAR_BLANK
	STOSB
DISPLAY_FLAGS_2:
	MOV	SI,FLAGTAB
	MOV	CX,16
	MOV	DX,[FLSAVE]
DFLAGS:
	LODS	word [cs:SI]
	SHL	DX,1
	JC	FLAGSET

	MOV	AX,[cs:SI+30]
FLAGSET:
	OR	AX,AX
	JZ	NEXT_FLAG

	STOSW
	MOV	AL,CHAR_BLANK
	STOSB
NEXT_FLAG:
	LOOP	DFLAGS
	XOR	AL,AL
	STOSB
	return

DISPREG:
	MOV	SI,REGTAB
	MOV	DI,arg_buf
	MOV	BX,AXSAVE
	MOV	byte [TOTREG],CR
	MOV	CH,0
	MOV	CL,[NOREGL]
SET_DISPLAY:
REPEAT_DISPLAY:
	SUB	[TOTREG],CL
	CALL	DISPLAY_LINE

	CALL	CRLF

	XOR	CH,CH
	MOV	CL,[NOREGL]
	CMP	CL,[TOTREG]
	JB	REPEAT_DISPLAY

	MOV	CL,[TOTREG]
	CALL	DISPLAY_LINE

	CALL	DISPLAY_FLAGS

	MOV	DX,arg_buf_ptr
	CALL	PRINTF_CRLF

	MOV	AX,[IPSAVE]
	MOV	word [DISADD],AX
	PUSH	AX
	MOV	AX,[CSSAVE]
; MASM read a type name in an expression as the number of bytes it
; takes up, so BYTE on its own is 1 and WORD is 2.
	MOV	word [DISADD+2],AX
	PUSH	AX
	MOV	word [NSEG],-1
	CALL	DISASLN

	POP	word [DISADD+2]
	POP	word [DISADD]
	MOV	AX,[NSEG]
	CMP	AL,-1
	JNZ	ASSEM_LIN_CONT

	JMP	CRLF

ASSEM_LIN_CONT:
	CMP	AH,-1
	JZ	NOOVER

	XCHG	AL,AH
NOOVER:
	CBW
	MOV	BX,AX
	SHL	BX,1
	MOV	AX,word [BX+SREG]
	MOV	DI,arg_buf
	STOSB
	XCHG	AL,AH
	STOSB
	XOR	AL,AL
	STOSB
	MOV	DX,[INDEX]
	MOV	[loc_add],DX
	MOV	DX,loc_ptr
	CALL	STD_PRINTF

	MOV	BX,[BX+SEGTAB]
	PUSH	DS
	MOV	DS,[BX]
	MOV	BX,[cs:INDEX]
	MOV	BX,[BX]
	POP	DS
	MOV	[big_contents],BX
	MOV	DX,big_ptr
	TEST	byte [AWORD],-1
	JNZ	SHOW_CHARS

	XOR	BH,BH
	MOV	[little_contents],BX
	MOV	DX,little_ptr
SHOW_CHARS:
	CALL	PRINTF_CRLF

	return

DISPREGJ:
	JMP	DISPREG

; Perform register dump if no parameters or set register if a
; register designation is a parameter.
REG:
	CALL	SCANP

	JZ	DISPREGJ

	MOV	DL,[SI]
	INC	SI
	MOV	DH,[SI]
	CMP	DH,CR
	JZ	FLAG

	INC	SI
	CALL	GETEOL

	CMP	DH,CHAR_BLANK
	JZ	FLAG

	MOV	DI,REGTAB
	XCHG	AX,DX
	PUSH	CS
	POP	ES
	XOR	CX,CX
CHECK_NEXT_REG:
	CMP	AX,word [ DI]
	JZ	REG_FOUND

	ADD	DI,3
	INC	CX
	CMP	DI,REGTABEND
	JB	CHECK_NEXT_REG

	JMP	BADREG

REG_FOUND:
	CMP	DI,REGTABEND
	JNZ	NOTPC

	DEC	DI
	DEC	DI
	DEC	DI
	MOV	AX,[cs:DI-2]
NOTPC:
	PUSH	DI
	MOV	DI,arg_buf
	STOSB
	XCHG	AL,AH
	STOSB
	XOR	AL,AL
	STOSB
	POP	DI
	PUSH	DS
	POP	ES
	LEA	BX,[DI+REGDIF]
	SUB	BX,CX
	MOV	DX,[BX]
	MOV	[single_reg_arg],DX
	MOV	DX,single_reg_ptr
	CALL	STD_PRINTF

	CALL	INBUF

	CALL	SCANB

	retz

	push	bx				;an000;save bx - we stomp it
	MOV	CX,4
	CALL	GETHEX1
	pop	bx				;an000;restore it

	CALL	GETEOL

	MOV	[BX],DX
	return
BADREG:
	MOV	DX,br_error        ; BR ERROR
	JMP	ERR_

FLAG:
	CMP	DL,UPPER_F
	JNZ	BADREG

	MOV	DI,arg_buf
	CALL	DISPLAY_FLAGS_2

	MOV	DX,change_flag_ptr
	CALL	STD_PRINTF

	CALL	INBUF

	CALL	SCANB

	XOR	BX,BX
	MOV	DX,[FLSAVE]
GETFLG:
	LODSW
	CMP	AL,CR
	JZ	SAVCHG

	CMP	AH,CR
	JZ	FLGERR

	MOV	DI,FLAGTAB
	MOV	CX,32
	PUSH	CS
	POP	ES
	REPNE	SCASW
	JNZ	FLGERR

	MOV	CH,CL
	AND	CL,0FH
	MOV	AX,1
	ROL	AX,CL
	TEST	AX,BX
	JNZ	REPFLG

	OR	BX,AX
	OR	DX,AX
	TEST	CH,16
	JNZ	NEXFLG

	XOR	DX,AX
NEXFLG:
	CALL	SCANP

	JMP	SHORT GETFLG

REPFLG:
	MOV	DX,df_error        ; DF ERROR
FERR:
	CALL	SAVCHG
ERR_:
	push	si				;an000;save affected registers
	push	di				;an000;
	push	cx				;an000;
	mov	cx,03h				;an000;move only three bytes
	mov	di,err_type         ;an000;point to buffer
	mov	si,dx				;an000;dx holds the string
	rep	movsb				;an000;fill up the buffer
	pop	cx				;an000;restore registers
	pop	di				;an000;
	pop	si				;an000;
	MOV	DX,errmes_ptr
	JMP	PRINT

SAVCHG:
	MOV	[FLSAVE],DX
	return

FLGERR:
	MOV	DX,bf_error        ; BF ERROR
	JMP	SHORT FERR

PREPNAME:
	MOV	ES,[DSSAVE]
	PUSH	SI
	MOV	DI,81H
COMTAIL:
	LODSB
	STOSB
	CMP	AL,CR
	JNZ	COMTAIL

	SUB	DI,82H
	XCHG	AX,DI
	MOV	byte [es:80H],AL
	POP	SI
	MOV	DI,FCB			;05cH
	MOV	AX,(Parse_File_Descriptor SHL 8) OR SET_DRIVEID_OPTION ;AL=01H
	INT	21H

	MOV	byte [AXSAVE],AL     ; Indicate analysis of first parm
	CALL	SKIP_FILE

	MOV	DI,6CH
	MOV	AX,(Parse_File_Descriptor SHL 8) OR SET_DRIVEID_OPTION ;AL=01H
	INT	21H

	MOV	byte [AXSAVE+1],AL     ; Indicate analysis of second parm
	return

;  OPENS A XENIX PATHNAME SPECIFIED IN THE UNFORMATTED PARAMETERS
;  VARIABLE [XNXCMD] SPECIFIES WHICH COMMAND TO OPEN IT WITH

;  VARIABLE [HANDLE] CONTAINS THE HANDLE
;  VARIABLE [EXTPTR] POINTS TO THE FILES EXTENSION
DELETE_A_FILE:
	MOV	byte [XNXCMD],Unlink
	JMP	SHORT OC_FILE

PARSE_A_FILE:
	MOV	byte [XNXCMD],0
	JMP	SHORT OC_FILE

EXEC_A_FILE:
	MOV	byte [cs:XNXCMD],Exec
	MOV	byte [cs:XNXOPT],1
	JMP	SHORT OC_FILE

OPEN_A_FILE:
	MOV	byte [XNXCMD],Open
	MOV	byte [XNXOPT],2     ; Try read write
	CALL	OC_FILE

	retnc
	MOV	byte [XNXCMD],Open
	MOV	byte [XNXOPT],0     ; Try read only
	JMP	SHORT OC_FILE

CREATE_A_FILE:
	MOV	byte [XNXCMD],Creat
OC_FILE:
	PUSH	DS
	PUSH	ES
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
	XOR	AX,AX
	MOV	[cs:EXTPTR],AX		; INITIALIZE POINTER TO EXTENSIONS
	MOV	AH,Char_Oper
	INT	21H

	MOV	[cs:SWITCHAR],DL	; GET THE CURRENT SWITCH CHARACTER
	MOV	SI,81H

open1:	CALL	GETCHRUP		;convert 1 byte to uppercase
	CALL	DELIM2			; END OF LINE?
	JZ	OPEN4

	CALL	DELIM1			; SKIP LEADING DELIMITERS
	JZ	open1

	MOV	DX,SI			; SAVE POINTER TO BEGINNING
	cmp	byte [fnd_dbcs],1
;	if$	z
	JNZ IF1$$2
	    dec   dx			;dec it twice if dbcs
;	endif$
IF1$$2:
	DEC	DX
open2:	CMP	AL,CHAR_PERIOD		; LAST CHAR A "."?
	JNZ	OPEN3

	MOV	[cs:EXTPTR],SI		; SAVE POINTER TO THE EXTENSION
OPEN3:
	CALL	GETCHRUP

	CALL	DELIM1			; LOOK FOR END OF PATHNAME

	JZ	OPEN4

	CALL	DELIM2

	JNZ	open2

OPEN4:	DEC	SI			; POINT BACK TO LAST CHAR
	PUSH	word [SI] ; SAVE TERMINATION CHAR
	MOV	byte [SI],0      ; NULL TERMINATE THE STRING
	MOV	AL,[cs:XNXOPT]
	MOV	AH,[cs:XNXCMD]		; OPEN OR CREATE FILE
	OR	AH,AH
	JZ	OPNRET

	MOV	[cs:FILESTRT],DX	; Set values for later call on this file
	MOV	[cs:FILEEND],SI
	PUSH	CS
	POP	ES			; Set ES seg for EXEC_BLOCK
	MOV	BX,EXEC_BLOCK
	XOR	CX,CX
	INT	21H

	MOV	[cs:HANDLE],AX		; SAVE ERROR CODE OR HANDLE
OPNRET:
	POP	word [SI]
	POP	SI
	POP	DX
	POP	CX
	POP	BX
	POP	AX			; blow away error code...
	POP	ES
	POP	DS
	return

GETCHRUP:									;an001;bgb
	lodsb				;get the character from [si]		;an001;bgb
	call	TEST_LEAD		;is it a dbcs lead byte?		;an001;bgb
;	IF$	C			;yes					;an001;bgb
	JNC IF3$$2
	    inc     si			;bump ptr to past 2nd dbcs byte 	;an001;bgb
	    mov     byte [fnd_dbcs],1 ;found a dbcs char
	    jmp     gcur		;dont capitalize it			;an001;bgb
;	ENDIF$									;an001;bgb
IF3$$2:
					;					;an001;bgb
	mov	byte [fnd_dbcs],0 ;did not find a dbcs char
	cmp	al,LOWER_A		;is it >= "a" ? 			;an001;bgb
	jb	gcur			;no - exit				;an001;bgb
										;an001;bgb
	cmp	al,LOWER_Z		;is it =< "z" ? 			;an001;bgb
	ja	gcur			;no - exit				;an001;bgb
										;an001;bgb
;if we get here, the char is lowercase, so change it				;an001;bgb
	sub	al,32			;convert to uppercase			;an001;bgb
	mov	[si-1],al		;move it back (si points 1 past)	;an001;bgb
gcur:	return									;an001;bgb

DELIM0:
	CMP	AL,CHAR_LEFT_BRACKET
	retz
DELIM1:
	CMP	AL,CHAR_BLANK		; SKIP THESE GUYS
	retz

	CMP	AL,CHAR_SEMICOLON
	retz

	CMP	AL,CHAR_EQUAL
	retz

	CMP	AL,CHAR_TAB
	retz

	CMP	AL,CHAR_COMMA
	return

DELIM2:
	CMP	AL,[cs:SWITCHAR]	; STOP ON THESE GUYS
	retz

	CMP	AL,CR
	return

NAMED:
	OR	byte [NAMESPEC],1 ; Flag a name command executed
	CALL	PREPNAME

	MOV	AL,byte [AXSAVE]
	MOV	[PARSERR],AL
	PUSH	ES
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,FCB			; DS:SI points to user FCB
	MOV	DI,SI			; ES:DI points to DEBUG FCB
	MOV	CX,82
	REP	MOVSW
	return

BADNAM:
	MOV	DX,nambad_ptr
	JMP	RESTART

IFHEX:
	CMP	byte [PARSERR],-1     ; Invalid drive specification?
	JZ	BADNAM

	CALL	PARSE_A_FILE

	MOV	BX,[EXTPTR]
	CMP	word [ds:BX],"EH"     ; "HE"
	retnz

	CMP	byte [ds:BX+2],UPPER_X
	return

IFEXE:
	PUSH	BX
	MOV	BX,[EXTPTR]
	CMP	word [ds:BX],"XE"     ; "EX"
	JNZ	RETIF

	CMP	byte [ds:BX+2],UPPER_E
RETIF:
	POP	BX
	return

LOAD_:
	MOV	byte [RDFLG],Read
	JMP	SHORT DSKIO

DWRITE:
	MOV	byte [RDFLG],Write
DSKIO:
	MOV	BP,[CSSAVE]
	CALL	SCANB

	JNZ	PRIMIO

	JMP	DEFIO

PRIMIO:
	CALL	ADDRESS

	CALL	SCANB

	JNZ	PRMIO

	JMP	FILEIO

;=========================================================================
; PRMIO:	This routine builds the necessary table for the new
;		generic IOCtl primitive read/write logical sector function.
;
;	Inputs : Binary addresses and values converted by GETHEX
;
;	Outputs: REL_READ_WRITE_TAB -	Table needed by IOCtl function to
;					perform 32 bit sector addressing.
;
;	Date	   : 6/17/87
;=========================================================================

PRMIO:
	mov	word [rel_rw_add],dx     ;ac000;save transfer address
						;      in table
	mov	word [rel_rw_add+2],ax     ;ac000;save segment of transfer
						;      address
	MOV	CX,2
	CALL	GETHEX			; Drive number must be 2 digits or less

	PUSH	DX			;save drive number
	MOV	CX,8			;ac000;allow 32 bit addressibilty
	CALL	GETHEX			; Logical record number
	mov	word [rel_low_sec],dx     ;ac000;save low word of logical
						;      sector address
	mov	word [rel_high_sec],bx     ;ac000;save high word of
						;      logical sector address

	MOV	CX,3
	CALL	GETHEX			; Number of records
	mov	word [rel_sec_num],dx     ;ac000;save number of sectors
						;      to read/write

	CALL	GETEOL

	POP	BX			;ac000;drive number
	CBW				; Turn off verify after write
	MOV	byte [drvlet],bl   ;ac000;save drive in case of error
	PUSH	BX
	MOV	DL,bL			;ac000;move drive to dl
; Clean off the buffer cache for physical I/O
	push	ds
	MOV	AH,Disk_Reset
	INT	21H

	INC	DL
	MOV	AH,Get_DPB
	INT	21H
	pop	ds

	or	al,al			;ac000;see if an error occurred
	pop	ax			;ac000;restore drive

	JNZ	DRVERRJ

	CMP	byte [cs:RDFLG],Write
;	if$	z			;an000;we will write to sector(s)
	JNZ IF5$$2
		call ABSWRT		;an000;logical sector write
;	else$				;an000;
	JMP SHORT EN5$$2
IF5$$2:
		call ABSREAD		;an000;we will read sector(s)
;	endif$				;an000;
EN5$$2:


ENDABS:
	JNC	RET0

DRVERRJ:
	JMP	DRVERR

RET0:
; Clean cache again...
	MOV	AH,Disk_Reset
	INT	21H

	return


;called from debug.sal
DEFIO:
	MOV	AX,[CSSAVE]		; Default segment
	MOV	DX,100H 		; Default file I/O offset
	CALL	IFHEX
	JNZ	EXECHK
	XOR	DX,DX			; If HEX file, default OFFSET is zero
HEX2BINJ:
	JMP	HEX2BIN

FILEIO:
; AX and DX have segment and offset of transfer, respectively
	CALL	IFHEX
	JZ	HEX2BINJ

EXECHK:
	CALL	IFEXE
	JNZ	BINFIL
	CMP	byte [RDFLG],Read
	JZ	EXELJ
	MOV	DX,exewrt_ptr
	JMP	RESTART 		; Can't write .EXE files

BINFIL:
	CMP	byte [RDFLG],Write
	JZ	BINLOAD
	CMP	word [ds:BX],4F00H + UPPER_C     ;"CO"
	JNZ	BINLOAD
	CMP	byte [ds:BX+2],UPPER_M
	JNZ	BINLOAD

EXELJ:
	DEC	SI
	CMP	DX,100H
	JNZ	PRER

	CMP	AX,[CSSAVE]
	JZ	OAF

PRER:
	JMP	PERROR

OAF:
	CALL	OPEN_A_FILE

	JNC	GDOPEN

	MOV	AX,error_file_not_found
	JMP	EXECERR

GDOPEN:
	XOR	DX,DX
	XOR	CX,CX
	MOV	BX,[HANDLE]
	MOV	AL,2
	MOV	AH,LSeek
	INT	21H

	CALL	IFEXE			; SUBTRACT 512 BYTES FOR EXE

	JNZ	BIN2			; FILE LENGTH BECAUSE OF

	SUB	AX,512			; THE HEADER
BIN2:
	MOV	[BXSAVE],DX		; SET UP FILE SIZE IN DX:AX
	MOV	[CXSAVE],AX
	MOV	AH,Close
	INT	21H

	JMP	EXELOAD

NO_MEM_ERR:
	MOV	DX,toobig_ptr
	CALL	PRINTF_CRLF

	JMP	COMMAND

WRTFILEJ:
	JMP	WRTFILE
NOFILEJ:
	JMP	NOFILE

BINLOAD:
	PUSH	AX
	PUSH	DX
	CMP	byte [RDFLG],Write
	JZ	WRTFILEJ

	CALL	OPEN_A_FILE

	JC	NOFILEJ

	MOV	BX,[HANDLE]
	MOV	AX,(LSeek SHL 8) OR LSEEK_EOF_OPTION
	XOR	DX,DX			;CX:DX=DISTANCE (OFFSET) TO MOVE IN BYTES
	MOV	CX,DX
	INT	21H			; GET SIZE OF FILE

	MOV	SI,DX
	MOV	DI,AX			; SIZE TO SI:DI
	MOV	AX,(LSeek SHL 8) OR LSEEK_FROM_START
	XOR	DX,DX
	MOV	CX,DX
	INT	21H			; RESET POINTER BACK TO BEGINNING

	POP	AX
	POP	BX
	PUSH	BX
	PUSH	AX			; TRANS ADDR TO BX:AX
	ADD	AX,15
	RCR	AX,1
	MOV	CL,3
	MOV	CL,4
	SHR	AX,CL
	ADD	BX,AX			; Start of transfer rounded up to seg
	MOV	DX,SI
	MOV	AX,DI			; DX:AX is size
	cmp	dx,10h
	jnc	NO_MEM_ERR
	MOV	CX,16
	DIV	CX
	OR	DX,DX
	JZ	NOREM

	INC	AX
NOREM:					; AX is number of paras in transfer
	ADD	AX,BX			; AX is first seg that need not exist
	jc	NO_MEM_ERR
	CMP	AX,[cs:Process_data_block.PDB_block_len]
	JA	NO_MEM_ERR

	MOV	[CXSAVE],DI
	MOV	[BXSAVE],SI
	POP	DX
	POP	AX
; AX:DX is disk transfer address (segment:offset)
; SI:DI is length (32-bit number)
RDWR:
RDWRLOOP:
	MOV	BX,DX			; Make a copy of the offset
	AND	DX,000FH		; Establish the offset in 0H-FH range
	MOV	CL,4
	SHR	BX,CL			; Shift offset and
	ADD	AX,BX			; Add to segment register to get new Seg:offset
	PUSH	AX
	PUSH	DX			; Save AX,DX register pair
	MOV	word [TRANSADD],DX
	MOV	word [TRANSADD+2],AX
	MOV	CX,0FFF0H		; Keep request in segment
	OR	SI,SI			; Need > 64K?
	JNZ	BIGRDWR

	MOV	CX,DI			; Limit to amount requested
BIGRDWR:
	PUSH	DS
	PUSH	BX
	MOV	BX,[HANDLE]
	MOV	AH,[RDFLG]
	LDS	DX,[TRANSADD]
	INT	21H			; Perform read or write

	POP	BX
	POP	DS
	JC	BADWR

	CMP	byte [RDFLG],Write
	JNZ	GOODR

	CMP	CX,AX
	JZ	GOODR

BADWR:
	MOV	CX,AX
	STC
	POP	DX			; READ OR WRITE BOMBED OUT
	POP	AX
	return

GOODR:
	MOV	CX,AX
	SUB	DI,CX			; Request minus amount transferred
	SBB	SI,0			; Ripple carry
	OR	CX,CX			; End-of-file?
	POP	DX			; Restore DMA address
	POP	AX
	JZ	DOCLOSE

	ADD	DX,CX			; Bump DMA address by transfer length
	MOV	BX,SI
	OR	BX,DI			; Finished with request
	JNZ	RDWRLOOP

DOCLOSE:
	SaveReg <AX,BX>
	MOV	BX,[HANDLE]
	MOV	AH,Close
	INT	21H

	RestoreReg <BX,AX>
	return

NOFILE:
	MOV	DX,notfnd_ptr
	JMP	RESTART

NO_NAME_GIVEN:
	MOV	DX,nonamespec_ptr
RESTARTJMP:
	JMP	RESTART

WRTFILE:
	CMP	byte [NAMESPEC],0
	JZ	NO_NAME_GIVEN		; Hey User, you forgot to specify a name

	CALL	CREATE_A_FILE		; Create file we want to write to

	JC	CHECKREADONLY		; ARR 2.4

	MOV	SI,[BXSAVE] ; Get high order number of bytes to transfer
	CMP	SI,000FH
	JLE	WRTSIZE 		; Is bx less than or equal to FH

	XOR	SI,SI			; Ignore BX if greater than FH - set to zero
WRTSIZE:
	MOV	[wrt_arg2],SI
	MOV	DI,[CXSAVE]
	MOV	[wrt_arg1],DI
	MOV	DX,wrtmes_ptr
	CALL	PRINTF_CRLF

	POP	DX
	POP	AX
	CALL	RDWR

	JNC	CLSFLE

	CALL	CLSFLE

	CALL	DELETE_A_FILE

	MOV	DX,nospace_ptr
	JMP	RESTARTJMP

	CALL	CLSFLE			;is this dead code? - edk

	JMP	COMMAND

CHECKREADONLY:				; ARR 2.4
	MOV	DX,[FILESTRT]
	MOV	SI,[FILEEND]
	PUSH	word [SI]
	MOV	byte [SI],0
	MOV	AX,CHMod SHL 8		;AL=0,REQUEST FILE'S CURRENT
					;  ATTRIBUTE BE RETURNED IN CX
	INT	21H

	POP	word [SI]
	MOV	DX,noroom_ptr        ; Creation error - report error
	JC	RESTARTJMP

	TEST	CX,attr_read_only+attr_hidden+attr_system
	JZ	RESTARTJMP

	MOV	DX,accmes_ptr        ; Write on read only file
	JMP	RESTARTJMP

CLSFLE:
	MOV	AH,Close
	MOV	BX,[HANDLE]
	INT	21H

	return

EXELOAD:
	POP	word [RETSAVE] ; Suck up return addr
	INC	byte [NEWEXEC]
	MOV	BX,[USER_PROC_PDB]
	MOV	AX,[BEGSEG]
	MOV	DS,AX
;	ASSUME	DS:NOTHING

	CMP	AX,BX
	JZ	DEBUG_CURRENT

	JMP	FIND_DEBUG

DEBUG_CURRENT:
	MOV	AX,[cs:DSSAVE]
DEBUG_FOUND:
	MOV	byte [cs:NEWEXEC],0
	MOV	[cs:HEADSAVE],AX
	PUSH	word [cs:RETSAVE] ; Get the return address back
	PUSH	AX
	MOV	BX,CS
	SUB	AX,BX
	PUSH	ES
	MOV	ES,[cs:BEGSEG]
;	ASSUME	ES:NOTHING

	MOV	BX,AX			; size of debug in para.
	ADD	BX,10H
	MOV	AX,CS			; and the size of printf in para.
	SUB	AX,[cs:BEGSEG]
	ADD	BX,AX
	MOV	AH,Setblock
	INT	21H

	POP	ES
	POP	AX
	MOV	word [cs:COM_LINE+2],AX
	MOV	word [cs:COM_FCB1+2],AX
	MOV	word [cs:COM_FCB2+2],AX
	PUSH	DS
	PUSH	CS
	POP	DS
	CALL	EXEC_A_FILE

	POP	DS
	MOV	AX,[cs:HANDLE]
	JC	EXECERR

	CALL	SET_TERMINATE_VECTOR	; Reset int 22

	MOV	AH,Get_Current_PDB
	INT	21H

	MOV	[cs:USER_PROC_PDB],BX
	MOV	[cs:DSSAVE],BX
	MOV	[cs:ESSAVE],BX
	MOV	ES,BX
	MOV	word [es:Process_data_block.PDB_Exit],TERMINATE
	MOV	word [es:Process_data_block.PDB_Exit+2],CS
	LES	DI,[cs:COM_CSIP]
	MOV	[cs:CSSAVE],ES
	MOV	[cs:IPSAVE],DI
	MOV	word [cs:DISADD+2],ES
	MOV	word [cs:DISADD],DI
	MOV	word [cs:ASMADD+2],ES
	MOV	word [cs:ASMADD],DI
	MOV	word [cs:DEFDUMP+2],ES
	MOV	word [cs:DEFDUMP],DI
	MOV	BX,DS
	MOV	AH,Set_Current_PDB
	INT	21H

	LES	DI,[cs:COM_SSSP]
	MOV	AX,[es:DI]
	INC	DI
	INC	DI
	MOV	[cs:AXSAVE],AX
	MOV	[cs:SSSAVE],ES
	MOV	[cs:SPSAVE],DI
	return

EXECERR:
	PUSH	CS
	POP	DS
	MOV	DX,notfnd_ptr
	CMP	AX,error_file_not_found
	JZ	GOTEXECEMES

	MOV	DX,accmes_ptr
	CMP	AX,error_access_denied
	JZ	GOTEXECEMES

	MOV	DX,toobig_ptr
	CMP	AX,error_not_enough_memory
	JZ	GOTEXECEMES

	MOV	DX,exebad_ptr
	CMP	AX,error_bad_format
	JZ	GOTEXECEMES

	MOV	DX,execemes_ptr
GOTEXECEMES:
	CALL	PRINTF_CRLF

	JMP	COMMAND

HEX2BIN:
	MOV	[ss:INDEX],DX
	MOV	DX,hexwrt_ptr
	CMP	byte [ss:RDFLG],Write
	JNZ	RDHEX

	JMP	RESTARTJ2

RDHEX:
	MOV	ES,AX
	CALL	OPEN_A_FILE

	MOV	DX,notfnd_ptr
	JNC	HEXFND

	JMP	RESTART

HEXFND:
	XOR	BP,BP
	MOV	SI,(BUFFER+BUFSIZ)        ; Flag input buffer as empty
READHEX:
	CALL	GETCH

	CMP	AL,CHAR_COLON		; Search for : to start line
	JNZ	READHEX

	CALL	GETBYT			; Get byte count

	MOV	CL,AL
	MOV	CH,0
	JCXZ	HEXDONE

	CALL	GETBYT			; Get high byte of load address

	MOV	BH,AL
	CALL	GETBYT			; Get low byte of load address

	MOV	BL,AL
	ADD	BX,[ss:INDEX] ; Add in offset
	MOV	DI,BX
	CALL	GETBYT			; Throw away type byte

READLN:
	CALL	GETBYT			; Get data byte

	STOSB
	CMP	DI,BP			; Check if this is the largest address so far
	JBE	HAVBIG

	MOV	BP,DI			; Save new largest
HAVBIG:
	LOOP	READLN

	JMP	SHORT READHEX

GETCH:
	CMP	SI,(BUFFER+BUFSIZ)
	JNZ	NOREAD

	MOV	DX,BUFFER
	MOV	SI,DX
	MOV	AH,Read
	PUSH	BX
	PUSH	CX
	MOV	CX,BUFSIZ
	MOV	BX,[cs:HANDLE]
	INT	21H

	POP	CX
	POP	BX
	OR	AX,AX
	JZ	HEXDONE

NOREAD:
	LODSB
	CMP	AL,CHAR_EOF
	JZ	HEXDONE

	OR	AL,AL
	retnz

HEXDONE:
	MOV	[ss:CXSAVE],BP
	MOV	word [ss:BXSAVE],0
	return

HEXDIG:
	CALL	GETCH

	CALL	HEXCHK

	retnc

	MOV	DX,hexerr_ptr
RESTARTJ2:
	JMP	RESTART

GETBYT:
	CALL	HEXDIG

	MOV	BL,AL
	CALL	HEXDIG

	SHL	BL,1
	SHL	BL,1
	SHL	BL,1
	SHL	BL,1
	OR	AL,BL
	return

;=========================================================================
; ABSREAD:	This routine performs a primitive logical sector read of
;		the specified drive.  This routine replaces the old
;		INT 25h function which only allowed 16 bit addressibility.
;		The new generic IOCtl logical sector read will permit
;		32 bit addressibility on a disk device.
;
;	Inputs : REL_READ_WRITE_TAB	- Table provides dword sector
;					  addressibility.
;
;	Outputs: Data located at specified transfer address.
;
;	Error  : Carry is set on error.
;
;	Date	  : 6/17/87
;=========================================================================

ABSREAD:            ;an000;read logical sector(s)

	push	ds			;an000;save affected regs
	push	cx			;an000;save affected regs
	push	bx			;an000;

	mov	cx,-1			;an000;extended format
	mov	bx,REL_READ_WRITE_TAB         ;an000;point to read/write table
	int	25h			;an000;invoke relative sector read
	pop	bx			;an000;discard stack word

	pop	bx			;an000;restore regs
	pop	cx			;an000;
	pop	ds			;an000;

	ret				;an000;return to caller

;ABSREAD 	endp			;an000;end proc


;=========================================================================
; ABSWRT:	This routine performs a primitive logical sector write of
;		the specified drive.  This routine replaces the old
;		INT 26h function which only allowed 16 bit addressibility.
;		The new generic IOCtl logical sector write will permit
;		32 bit addressibility on a disk device.
;
;	Inputs : REL_READ_WRITE_TAB	- Table provides dword sector
;					  addressibility.
;
;	Outputs: Data moved from transfer address to applicable sector(s).
;
;	Error  : Carry is set on error.
;
;	Date	  : 6/17/87
;=========================================================================

ABSWRT:            ;an000;write logical sector(s)

	push	ds			;an000;save affected regs
	push	cx			;an000;
	push	bx			;an000;

	mov	cx,-1			;an000;extended format
	mov	bx,REL_READ_WRITE_TAB         ;an000;point to read/write table
	int	26h			;an000;invoke relative sector write
	pop	bx			;an000;discard stack word

	pop	bx			;an000;restore regs
	pop	cx			;an000;
	pop	ds			;an000;

	ret				;an000;return to caller

;ABSWRT		endp			;an000;end proc


end if
;	END	DEBCOM2
