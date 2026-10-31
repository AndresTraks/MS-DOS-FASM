 PAGE 80,132
;	SCCSID = @(#)tmisc2.asm 4.3 85/06/25
;	SCCSID = @(#)tmisc2.asm 4.3 85/06/25
TITLE	Part7 COMMAND Transient Routines

;	More misc routines


.xlist
.xcref
	include 'COMSW.ASM'
	include 'DOSSYM.INC'
	include 'COMSEG.ASM'
	include 'COMEQU.ASM'
	include 'IOCTL.INC'
.list
.cref


if SEGSEL = S_CODERES	;AC000;
end if

if SEGSEL = S_DATARES	;AC000;
;	EXTRN	IFFlag:BYTE
;	EXTRN	PIPEFLAG:BYTE
;	EXTRN	RE_OUTSTR:BYTE
;	EXTRN	RE_OUT_APP:BYTE
end if

if SEGSEL = S_TRANDATA	;AC000;
;	EXTRN	AccDen_PTR:WORD
;	EXTRN	Extend_buf_ptr:word	;AN000;
;	EXTRN	FULDIR_PTR:WORD
;	EXTRN	msg_disp_class:byte	;AN000;
end if

if SEGSEL = S_TRANSPACE	;AC000;
;	EXTRN	DESTINFO:BYTE
;	EXTRN	DESTISDIR:BYTE
;	EXTRN	KPARSE:BYTE		;AC000;
;	EXTRN	ONE_CHAR_VAL:BYTE	;AN011;
;	EXTRN	PATHCNT:WORD
;	EXTRN	PATHPOS:WORD
;	EXTRN	PATHSW:WORD
;	EXTRN	RE_INSTR:BYTE
;	EXTRN	RESSEG:WORD
;	EXTRN	SRCBUF:BYTE
;	EXTRN	SWITCHAR:BYTE

	IF  IBM
;	EXTRN	ROM_CALL:BYTE
;	EXTRN	ROM_CS:WORD
;	EXTRN	ROM_IP:WORD
end if

end if

if SEGSEL = S_TRANCODE

;ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;	EXTRN	CERROR:NEAR

	IF	IBM
;	EXTRN	ROM_EXEC:NEAR
;	EXTRN	ROM_SCAN:NEAR
end if

;	PUBLIC	IOSET
;	PUBLIC	MOVE_TO_SRCBUF		;AN000;
;	PUBLIC	PGETARG
;	PUBLIC	SETPATH
;	PUBLIC	TESTDOREIN
;	PUBLIC	TESTDOREOUT


;ASSUME	DS:TRANGROUP

SETPATH:
;
; Get an ASCIZ argument from the unformatted parms
; DESTISDIR set if pathchars in string
; DESTINFO  set if ? or * in string
;
	MOV	AX,[PATHCNT]			;AC000; get length of string
	MOV	SI,[PATHPOS]			;AC000; get start of source buffer

GETPATH:
	MOV	byte [DESTINFO],0
	MOV	byte [DESTISDIR],0
	MOV	SI,[PATHPOS]
	MOV	CX,[PATHCNT]
	MOV	DX,SI
	JCXZ	PATHDONE
	PUSH	CX
	PUSH	SI
	invoke	SWITCH
	MOV	[PATHSW],AX
	POP	BX
	SUB	BX,SI
	POP	CX
	ADD	CX,BX
	MOV	DX,SI

SKIPPATH:

;;;;	IF	KANJI	3/3/KK
	MOV	byte [KPARSE],0

SKIPPATH2:
;;;;	ENDIF		3/3/KK

	JCXZ	PATHDONE
	DEC	CX
	LODSB

;;;;	IF	KANJI	3/3/KK
	invoke	TESTKANJ
	JZ	TESTPPSEP
	DEC	CX
	INC	SI
	INC	byte [KPARSE]
	JMP	SKIPPATH2

TESTPPSEP:
;;;;	ENDIF		3/3/KK

	invoke	PATHCHRCMP
	JNZ	TESTPMETA
	INC	byte [DESTISDIR]

TESTPMETA:
	CMP	AL,'?'
	JNZ	TESTPSTAR
	OR	byte [DESTINFO],2

TESTPSTAR:
	CMP	AL,star
	JNZ	TESTPDELIM
	OR	byte [DESTINFO],2

TESTPDELIM:
	invoke	DELIM
	JZ	PATHDONEDEC
	CMP	AL,[SWITCHAR]
	JNZ	SKIPPATH

PATHDONEDEC:
	DEC	SI

PATHDONE:
	XOR	AL,AL
	XCHG	AL,[SI]
	INC	SI
	CMP	AL,0DH
	JNZ	NOPSTORE
	MOV	[SI],AL 			;Don't loose the CR

NOPSTORE:
	MOV	[PATHPOS],SI
	MOV	[PATHCNT],CX
	return

PGETARG:
	MOV	SI,80H
	LODSB
	OR	AL,AL
	retz
	CALL	PSCANOFF
	CMP	AL,13
	return

PSCANOFF:
	LODSB
	invoke	DELIM
	JNZ	PSCANOFFD
	CMP	AL,';'
	JNZ	PSCANOFF			; ';' is not a delimiter

PSCANOFFD:
	DEC	SI				; Point to first non-delimiter
	return

IOSET:
;
; ALL REGISTERS PRESERVED
;
;ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

	PUSH	DS
	PUSH	DX
	PUSH	AX
	PUSH	BX
	PUSH	CX
	MOV	DS,[cs:RESSEG]
;ASSUME	DS:RESGROUP

	CMP	byte [PIPEFLAG],0
	JNZ	NOREDIR 			; Don't muck up the pipe
	TEST	byte [IFFLAG],-1
	JNZ	NOREDIR
	CALL	TESTDOREIN
	CALL	TESTDOREOUT

NOREDIR:
	POP	CX
	POP	BX
	POP	AX
	POP	DX
	POP	DS
;ASSUME	DS:NOTHING
	return

TESTDOREIN:

;ASSUME	DS:RESGROUP

	CMP	byte [cs:RE_INSTR],0
	retz
	PUSH	DS
	PUSH	CS
	POP	DS
	MOV	DX,RE_INSTR
	MOV	AX,(Open SHL 8)
	MOV	BX,AX
	INT	int_command
	POP	DS
	JC	REDIRERR
	MOV	BX,AX
	MOV	AL,0FFH
;
; Mega sleaze!! We move the SFN from the new handle spot into the old stdin
; spot.  We invalidate the new JFN we got.
;
	XCHG	AL,[BX+Process_data_block.PDB_JFN_Table]
	MOV	byte [ds:Process_data_block.PDB_JFN_Table],AL

	return
;
; We had some kind of error on the redirection.  Figure out what the
; appropriate message should be; BX has the system call that failed
;
REDIRERR:
	PUSH	CS
	POP	DS
	Call	TriageError
;
; At this point, we have recognized the network-generated access denied error.
; The correct message is in DX
;
	CMP	AX,65
	JZ	CERRORJ_TMISC2 			;AC000; just issue message returned
	CMP	BH,Open
	JZ	OpenError
;
; The error was for a create operation.  Report the error as a creation error.
;
	MOV	DX,FulDir_Ptr

CERRORJ_TMISC2:
	JMP	CERROR
;
; The system call was an OPEN.	Report either file not found or path not found.
;

OpenError:
	mov	byte [cs:msg_disp_class],ext_msg_class        ;AN000; set up extended error msg class
	mov	dx,Extend_Buf_ptr                  ;AC000; get extended message pointer
	mov	[cs:Extend_Buf_ptr],ax        ;AN000; get message number in control block
	JMP	CERROR

TESTDOREOUT:

;ASSUME	DS:RESGROUP

	CMP	byte [RE_OUTSTR],0
	JNZ	REOUTEXISTS			;AN017; need long jump
	JMP	NOREOUT 			;AN017;

REOUTEXISTS:
	CMP	byte [RE_OUT_APP],0
	JZ	REOUTCRT
;
; The output redirection was for append.  We open for write and seek to the
; end.
;
	MOV	DX,RE_OUTSTR
	MOV	AX,(Open SHL 8) OR 2		;AC011; Open for read/write
	PUSH	AX
	INT	int_command
	POP	BX
	JC	OpenWriteError

	MOV	BX,AX
	MOV	AX,IOCtl SHL 8			;AN035; Get attributes of handle
	INT	int_command			;AN035;
	TEST	DL,devid_ISDEV			;AN035; Is it a device?
	JNZ	SET_REOUT			;AN035; Yes, don't read from it

	MOV	AX,(LSeek SHL 8) OR 2
	MOV	CX,-1				;AC011; MOVE TO EOF -1
	MOV	DX,CX				;AC011;
	INT	int_command
	PUSH	CS				;AN011; Get transient seg to DS
	POP	DS				;AN011;
;	assume	DS:Trangroup			;AN011;
	MOV	AX,(Read SHL 8) 		;AN011; Read one byte from the
	MOV	CX,1				;AN011;   file into one_char_val
	MOV	DX,one_char_val                 ;AN011;
	INT	int_command			;AN011;
	JC	OpenWriteError			;AN011; If error, exit
	cmp	ax,cx				;AN017; Did we read 1 byte?
	jnz	reout_0_length			;AN017; No - file must be 0 length

	cmp	byte [one_char_val],01ah   ;AN011; Was char an eof mark?
	mov	DS,[RESSEG]			;AN011; Get resident segment back
;	assume	DS:Resgroup			;AN011;
	JNZ	SET_REOUT			;AN011; No, just continue
	MOV	AX,(LSeek SHL 8) OR 1		;AN011; EOF mark found
	MOV	CX,-1				;AN011; LSEEK back one byte
	MOV	DX,CX				;AN011;
	INT	int_command			;AN011;
	jmp     SET_REOUT

reout_0_length: 				;AN017; We have a 0 length file
	mov	DS,[cs:RESSEG]			;AN017; Get resident segment back
;	assume	DS:Resgroup			;AN017;
	MOV	AX,(LSeek SHL 8)		;AN017; Move to beginning of file
	XOR	CX,CX				;AN017; Offset is 0
	MOV	DX,CX				;AN017;
	INT	int_command			;AN017;
	jmp     SET_REOUT     ;AN017; now finish setting up redirection

OpenWriteError:
	CMP	AX,error_access_denied
	STC					; preserve error
	JNZ	REOUTCRT			;AN017; need long jump
	JMP	REDIRERR			;AN017;

REOUTCRT:
	MOV	DX,RE_OUTSTR
	XOR	CX,CX
	MOV	AH,Creat
	PUSH	AX
	INT	int_command
	POP	BX
	JNC	NOREDIRERR			;AC011;
	JMP	REDIRERR			;AC011;

NOREDIRERR:					;AN011;
	MOV	BX,AX

SET_REOUT:
;
; Mega sleaze!! We move the SFN from the new handle spot into the old stdout
; spot.  We invalidate the new JFN we got.
;
	MOV	AL,0FFH
	XCHG	AL,[BX+Process_data_block.PDB_JFN_Table]
	MOV	byte [ds:Process_data_block.PDB_JFN_Table+1],AL

NOREOUT:
	return

;
; Compute length of string (including NUL) in DS:SI into CX.  Change no other
; registers
;
procedure   DSTRLEN,NEAR

	SaveReg <AX>
	XOR	CX,CX
	CLD

DLoop:	LODSB
	INC	CX
	OR	AL,AL
	JNZ	DLoop
	SUB	SI,CX
	RestoreReg  <AX>
	return

EndProc DSTRLEN

BREAK	<Extended error support>

;
; TriageError will examine the return from a carry-set system call and
; return the correct error if applicable.
;
;   Inputs:	outputs from a carry-settable system call
;		No system calls may be done in the interrim
;   Outputs:	If carry was set on input
;		    carry set on output
;		    DX contains trangroup offset to printf message
;		else
;		    No registers changed
;

procedure TriageError,NEAR

	retnc					; no carry => do nothing...
	PUSHF
	SaveReg <BX,CX,SI,DI,BP,ES,DS,AX,DX>
	MOV	AH,GetExtendedError
	INT	21h
	RestoreReg  <CX,BX>			; restore original AX
	MOV	DX,AccDen_Ptr
	CMP	AX,65				; network access denied?
	JZ	NoMove				; Yes, return it.
	MOV	AX,BX
	MOV	DX,CX

NoMove:
	RestoreReg  <DS,ES,BP,DI,SI,CX,BX>
	popf
	return

EndProc TriageError

;PUBLIC Triage_Init
Triage_Init:
	call	TriageError
	RETF
;Triage_Init endp


; ****************************************************************
; *
; * ROUTINE:	 MOVE_TO_SRCBUF
; *
; * FUNCTION:	 Move ASCIIZ string from DS:SI to SRCBUF.  Change
; *		 terminating 0 to 0dH.	Set PATHCNT to length of
; *		 string.  Set PATHPOS to start of SRCBUF.
; *
; * INPUT:	 DS:SI points to ASCIIZ string
; *		 ES    points to TRANGROUP
; *
; * OUTPUT:	 SRCBUF filled in with string terminated by 0dH
; *		 PATHCNT set to length of string
; *		 PATHPOS set to start of SRCBUF
; *		 CX,AX	 changed
; *
; ****************************************************************

;assume	es:trangroup,ds:nothing 		;AN000;

MOVE_TO_SRCBUF:			;AN000;

	push	si				;AN000;  save si,di
	push	di				;AN000;
	push	cx				;AN000;
	mov	di,SRCBUF                  ;AN000;  set ES:DI to srcbuf
	xor	cx,cx				;AN000; clear cx for counint
	mov	ax,cx				;AN000; clear ax
	push	di				;AN000; save start of srcbuf
	lodsb					;AN000; get a character from DS:SI

mts_get_chars:					;AN000;
	cmp	al,0				;AN000; was it a null char?
	jz	mts_end_string			;AN000; yes - exit
	stosb					;AN000; no - store it in srcbuf
	inc	cx				;AN000; increment length count
	lodsb					;AN000; get a character from DS:SI
	jmp     mts_get_chars    ;AN000; go check it

mts_end_string: 				;AN000; we've reached the end of line
	mov	al,end_of_line_in		;AN000; store 0dH in srcbuf
	stosb					;AN000;
	pop	di				;AN000; restore start of srcbuf

	push	cs				;AN000; set DS to local segment
	pop	ds				;AN000;
;assume	ds:trangroup				;AN000;
	mov	[PATHCNT],cx			;AN000; set patchcnt to length count
	mov	[PATHPOS],di			;AN000; set pathpos to start of srcbuf
	pop	cx				;AN000; restore cx,di,si
	pop	di				;AN000;
	pop	si				;AN000;

	RET					;AN000; exit

;MOVE_TO_SRCBUF	ENDP				;AN000;

end if
;	    END
