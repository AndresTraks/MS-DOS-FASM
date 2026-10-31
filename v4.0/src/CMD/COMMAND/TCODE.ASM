 PAGE 80,132
;	SCCSID = @(#)tcode.asm	1.1 85/05/14
;	SCCSID = @(#)tcode.asm	1.1 85/05/14
TITLE	Part1 COMMAND Transient Routines

	include 'COMSW.ASM'
.xlist
.xcref
	include 'DOSSYM.INC'
	include 'COMSEG.ASM'
	include 'COMEQU.ASM'
.list
.cref


if SEGSEL = S_CODERES	;AC000;
;	EXTRN	EXEC_WAIT:NEAR
end if

if SEGSEL = S_DATARES	;AC000;
;	EXTRN	BATCH:WORD
;	EXTRN	CALL_BATCH_FLAG:byte
;	EXTRN	CALL_FLAG:BYTE
;	EXTRN	ECHOFLAG:BYTE
;	EXTRN	envirseg:word
;	EXTRN	EXTCOM:BYTE
;	EXTRN	FORFLAG:BYTE
;	EXTRN	IFFLAG:BYTE
;	EXTRN	next_batch:word
;	EXTRN	nullflag:byte
;	EXTRN	PIPEFILES:BYTE
;	EXTRN	PIPEFLAG:BYTE
;	EXTRN	RE_OUT_APP:BYTE
;	EXTRN	RE_OUTSTR:BYTE
;	EXTRN	RESTDIR:BYTE
;	EXTRN	SINGLECOM:WORD
;	EXTRN	VERVAL:WORD
end if

if SEGSEL = S_TRANDATA	;AC000;
;	EXTRN	BadNam_Ptr:word 	;AC000;
end if

if SEGSEL = S_TRANSPACE	;AC000;
;	EXTRN	APPEND_EXEC:BYTE	;AN041;
;	EXTRN	ARG1S:WORD
;	EXTRN	ARG2S:WORD
;	EXTRN	ARGTS:WORD
;	EXTRN	BYTCNT:WORD
;	EXTRN	COMBUF:BYTE
;	EXTRN	COMSW:WORD
;	EXTRN	CURDRV:BYTE
;	EXTRN	HEADCALL:DWORD
;	EXTRN	IDLEN:BYTE
;	EXTRN	INTERNATVARS:BYTE
;	EXTRN	PARM1:BYTE
;	EXTRN	PARM2:BYTE
;	EXTRN	RE_INSTR:BYTE
;	EXTRN	RESSEG:WORD
;	EXTRN	SPECDRV:BYTE
;	EXTRN	STACK:WORD
;	EXTRN	SWITCHAR:BYTE
;	EXTRN	TPA:WORD
;	EXTRN	UCOMBUF:BYTE
;	EXTRN	USERDIR1:BYTE
	IF  IBM
;	EXTRN	ROM_CALL:BYTE
;	EXTRN	ROM_CS:WORD
;	EXTRN	ROM_IP:WORD
end if

end if

; ********************************************************************
; START OF TRANSIENT PORTION
; This code is loaded at the end of memory and may be overwritten by
; memory-intensive user programs.

if SEGSEL = S_TRANCODE	;AC000;

;ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;	EXTRN	$EXIT:NEAR
;	EXTRN	DRVBAD:NEAR
;	EXTRN	EXTERNAL:NEAR
;	EXTRN	FNDCOM:NEAR
;	EXTRN	FORPROC:NEAR
;	EXTRN	PIPEPROC:NEAR
;	EXTRN	PIPEPROCSTRT:NEAR

;	PUBLIC	COMMAND
;	PUBLIC	DOCOM
;	PUBLIC	DOCOM1
;	PUBLIC	NOPIPEPROC
;	PUBLIC	TCOMMAND

	IF  IBM
;	PUBLIC	ROM_EXEC
;	PUBLIC	ROM_SCAN
end if

	ORG	0
ZERO	=	$

	rb	100H				; Allow for 100H parameter area

SETDRV:
	MOV	AH,Set_Default_Drive
	INT	int_command
;
; TCOMMAND is the recycle point in COMMAND.  Nothing is known here.
; No registers (CS:IP) no flags, nothing.
;

TCOMMAND:
	MOV	DS,[RESSEG]
;ASSUME	DS:RESGROUP
	MOV	AX,-1
	XCHG	AX,[VERVAL]
	CMP	AX,-1
	JZ	NOSETVER2
	MOV	AH,Set_Verify_On_Write		; AL has correct value
	INT	int_command

NOSETVER2:
	CALL	[HEADCALL]			; Make sure header fixed
	XOR	BP,BP				; Flag transient not read
	CMP	word [SINGLECOM],-1
	JNZ	COMMAND

EXITPREP$:
	PUSH	CS
	POP	DS
	JMP	Exit$				; Have finished the single command
;ASSUME	DS:NOTHING
;
; Main entry point from resident portion.
;
;   If BP <> 0, then we have just loaded transient portion otherwise we are
;   just beginning the processing of another command.
;

COMMAND:

;
; We are not always sure of the state of the world at this time.  We presume
; worst case and initialize the relevant registers: segments and stack.
;
;	ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	CLD
	MOV	AX,CS
	CLI
	MOV	SS,AX
;ASSUME	SS:TRANGROUP
	MOV	SP,STACK_
	STI
	MOV	ES,AX
	MOV	DS,AX				;AN000; set DS to transient
;ASSUME	ES:TRANGROUP,DS:TRANGROUP		;AC000;
	invoke	TSYSLOADMSG			;AN000; preload messages
	invoke	SETSTDINOFF			;AN026; turn off critical error on STDIN
	invoke	SETSTDOUTOFF			;AN026; turn off critical error on STDOUT
	mov	byte [append_exec],0       ;AN041; set internal append state off

	MOV	DS,[RESSEG]
;ASSUME	DS:RESGROUP

	MOV	byte [UCOMBUF],COMBUFLEN   ; Init UCOMBUF
	MOV	byte [COMBUF],COMBUFLEN    ; Init COMBUF (Autoexec doing DATE)
;
; If we have just loaded the transient, then we do NOT need to initialize the
; command buffer.  ????  DO WE NEED TO RESTORE THE USERS DIRECTORY ????  I
; guess not:  the only circumstances in which we reload the command processor
; is after a transient program execution.  In this case, we let the current
; directory lie where it may.
;
	OR	BP,BP				; See if just read
	JZ	TESTRDIR			; Not read, check user directory
	MOV	word [UCOMBUF+1],0D01H     ; Reset buffer
	jmp     NOSETBUF

TESTRDIR:
	CMP	byte [RESTDIR],0
	JZ	NOSETBUF			; User directory OK
	PUSH	DS
;
; We have an unusual situation to handle.  The user *may* have changed his
; directory as a result of an internal command that got aborted.  Restoring it
; twice may not help us:  the problem may never go away.  We just attempt it
; once and give up.
;
	MOV	byte [RESTDIR],0   ; Flag users dirs OK
	PUSH	CS
	POP	DS
;ASSUME	DS:TRANGROUP
	MOV	DX,USERDIR1
	MOV	AH,CHDir
	INT	int_command			; Restore users directory
	POP	DS
;ASSUME	DS:RESGROUP

NOSETBUF:
	CMP	byte [PIPEFILES],0
	JZ	NOPCLOSE			; Don't bother if they don't exist
	CMP	byte [PIPEFLAG],0
	JNZ	NOPCLOSE			; Don't del if still piping
	invoke	PIPEDEL

NOPCLOSE:
	MOV	byte [EXTCOM],0    ; Flag internal command
	MOV	AX,CS				; Get segment we're in
	MOV	DS,AX
;ASSUME	DS:TRANGROUP

	PUSH	AX
	MOV	DX,INTERNATVARS
	MOV	AX,International SHL 8
	INT	21H
	POP	AX
	SUB	AX,[TPA]			; AX=size of TPA in paragraphs
	PUSH	BX
	MOV	BX,16
	MUL	BX				; DX:AX=size of TPA in bytes
	POP	BX
	OR	DX,DX				; See if over 64K
	JZ	SAVSIZ				; OK if not
	MOV	AX,-1				; If so, limit to 65535 bytes

SAVSIZ:
;
; AX is the number of bytes free in the buffer between the resident and the
; transient with a maximum of 64K-1.  We round this down to a multiple of 512.
;
	CMP	AX,512
	JBE	GotSize_TCODE
	AND	AX,0FE00h			; NOT 511 = NOT 1FF

GotSize_TCODE:
	MOV	[BYTCNT],AX			; Max no. of bytes that can be buffered
	MOV	DS,[RESSEG]			; All batch work must use resident seg.
;ASSUME	DS:RESGROUP

	TEST	byte [ECHOFLAG],1
	JZ	GETCOM				; Don't do the CRLF
	invoke	SINGLETEST
	JB	GETCOM
	TEST	byte [PIPEFLAG],-1
	JNZ	GETCOM
	TEST	byte [FORFLAG],-1 ; G  Don't print prompt in FOR
	JNZ	GETCOM				; G
	TEST	word [BATCH], -1  ; G  Don't print prompt if in batch
	JNZ	GETCOM				; G
	invoke	CRLF2

GETCOM:
	MOV	byte [CALL_FLAG],0 ; G Reset call flags
	MOV	byte [CALL_BATCH_FLAG],0   ; G
	MOV	AH,Get_Default_Drive
	INT	int_command
	MOV	[CURDRV],AL
	TEST	byte [PIPEFLAG],-1        ; Pipe has highest presedence
	JZ	NoPipe_TCODE
	JMP	PIPEPROC			; Continue the pipeline

NoPipe_TCODE:
	TEST	byte [ECHOFLAG],1
	JZ	NOPDRV				; No prompt if echo off
	invoke	SINGLETEST
	JB	NOPDRV
	TEST	byte [FORFLAG],-1 ; G  Don't print prompt in FOR
	JNZ	NOPDRV				; G
	TEST	word [BATCH], -1  ; G  Don't print prompt if in batch
	JNZ	TESTFORBAT			; G
	invoke	print_prompt			; Prompt the user

NOPDRV:
	TEST	byte [FORFLAG],-1 ; FOR has next highest precedence
	JZ	TESTFORBAT
	JMP	forproc 			; Continue the FOR

TESTFORBAT:
	MOV	byte [RE_INSTR],0  ; Turn redirection back off
	MOV	byte [RE_OUTSTR],0
	MOV	byte [RE_OUT_APP],0
	MOV	byte [IFFLAG],0    ; no more ifs...
	TEST	word [BATCH],-1   ; Batch has lowest precedence
	JZ	ISNOBAT

	push	es				;AN000; save ES
	push	ds				;AN000; save DS
	mov	ax,mult_shell_get		;AN000; check to see if SHELL has command
	mov	es,[BATCH]			;AN000; get batch segment
	mov	di,BatchSegment.BatFile    ;AN000; get batch file name
	push	cs				;AN000; get local segment to DS
	pop	ds				;AN000;
	mov	dx,COMBUF                  ;AN000; pass communications buffer
	int	2fh				;AN000; call the shell
	cmp	al,shell_action 		;AN000; does shell have a commmand?
	pop	ds				;AN000; restore DS
	pop	es				;AN000; restore ES
	jz	JDOCOM1 			;AN000; yes - go process command

	PUSH	DS				;G
	invoke	ReadBat 			; Continue BATCH
	POP	DS				;G
	mov	byte [NULLFLAG],0  ;G reset no command flag
	TEST	word [BATCH],-1   ;G
	JNZ	JDOCOM1 			;G if batch still in progress continue
	MOV	BX,[NEXT_BATCH] ;G
	CMP	BX,0				;G see if there is a new batch file
	JZ	JDOCOM1 			;G no - go do command
	MOV	[BATCH],BX ;G get segment of next batch file
	MOV	word [NEXT_BATCH],0        ;G reset next batch
JDOCOM1:
	PUSH	CS				;G
	POP	DS				;G
	jmp     DOCOM1     ; echoing already done

ISNOBAT:
	CMP	word [SINGLECOM],0
	JZ	REGCOM
	MOV	SI,-1
	XCHG	SI,[SINGLECOM]
	MOV	DI,COMBUF + 2
	XOR	CX,CX

SINGLELOOP:
	LODSB
	STOSB
	INC	CX
	CMP	AL,0DH
	JNZ	SINGLELOOP
	DEC	CX
	PUSH	CS
	POP	DS
;ASSUME	DS:TRANGROUP
	MOV	[COMBUF + 1],CL
;
; do NOT issue a trailing CRLF...
;
	JMP	DOCOM1

;
; We have a normal command.  
; Printers are a bizarre quantity.  Sometimes they are a stream and
; sometimes they aren't.  At this point, we automatically close all spool
; files and turn on truncation mode.
;

REGCOM:
	MOV	AX,(ServerCall SHL 8) + 9
	INT	21h
	MOV	AX,(ServerCall SHL 8) + 8
	MOV	DL,1
	INT	21h

	PUSH	CS
	POP	DS				; Need local segment to point to buffer
	MOV	DX,UCOMBUF
	MOV	AH,Std_Con_String_Input
	INT	int_command			; Get a command
	MOV	CL,[UCOMBUF]
	XOR	CH,CH
	ADD	CX,3
	MOV	SI,UCOMBUF
	MOV	DI,COMBUF
	REP	MOVSB				; Transfer it to the cooked buffer

;---------------

if SEGSEL = S_TRANSPACE
;    extrn   arg:byte				; the arg structure!
end if
;---------------


DOCOM:
	invoke	CRLF2

DOCOM1:
	invoke	PRESCAN 			; Cook the input buffer
	JZ	NOPIPEPROC
	JMP	PIPEPROCSTRT			; Fire up the pipe

nullcomj:
	jmp	nullcom

NOPIPEPROC:
	invoke	parseline
	jnc	OkParse 			; user error?  or maybe we goofed?

BadParse:
	PUSH	CS
	POP	DS
	MOV	DX,BadNam_Ptr
	invoke	STD_EPRINTF
	JMP	TCOMMAND

OkParse:
	test	byte [ARG+arg_unit.argv+0+argv_ele.argflags], MASK wildcard
	jnz	BadParse			; ambiguous commands not allowed
	cmp	word [ARG+arg_unit.argvcnt], 0     ; there WAS a command, wasn't there?
	jz	nullcomj
	cmp	word [ARG+arg_unit.argv+0+argv_ele.arglen], 0      ; probably an unnecessary check...
	jz	nullcomj			; guarantees argv[0] at least x<NULL>

	MOV	SI,COMBUF+2
	MOV	DI,IDLEN
	MOV	AX,(Parse_File_Descriptor SHL 8) OR 01H ; Make FCB with blank scan-off
	INT	int_command
	mov	BX, word [ARG+arg_unit.argv+0+argv_ele.argpointer]
	cmp	byte [BX+1],':'                 ; was a drive specified?
	jne	DRVGD         ; no, use default of zero...

	mov	DL, byte [BX]      ; pick-up drive letter
	and	DL, NOT 20H			; uppercase the sucker
	sub	DL, capital_A			; convert it to a drive number, A=0

	CMP	AL,-1				; See what PARSE said about our drive letter.
	JZ	drvbadj2			; It was invalid.

	mov	DI, word [ARG+arg_unit.argv+0+argv_ele.argstartel]
	cmp	byte [DI], 0      ; is there actually a command there?
	jnz	DRVGD				; if not, we have:  "d:", "d:\", "d:/"
	jmp	SETDRV				; and set drive to new drive spec

drvbadj2:
	jmp	DRVBAD

DRVGD:
	MOV	AL,[DI]
	MOV	[SPECDRV],AL
	MOV	AL,' '
	MOV	CX,9
	INC	DI
	REPNE	SCASB				; Count no. of letters in command name
	MOV	AL,8
	SUB	AL,CL
	MOV	[IDLEN],AL			; IDLEN is truly the length
	MOV	DI,81H
	PUSH	SI

	mov	si, COMBUF+2                  ; Skip over all leading delims
	invoke	SCANOFF

do_skipcom:
	lodsb					; move command line pointer over
	invoke	DELIM				; pathname -- have to do it ourselves
	jz	do_skipped			; 'cause parse_file_descriptor is dumb
	cmp	AL, 0DH 			; can't always depend on argv[0].arglen
	jz	do_skipped			; to be the same length as the user-
	cmp	AL, [SWITCHAR]			; specified command string
	jnz	do_skipcom

do_skipped:
	dec	SI
	XOR	CX,CX

COMTAIL:
	LODSB
	STOSB					; Move command tail to 80H
	CMP	AL,13
	LOOPNZ	COMTAIL
	DEC	DI
	MOV	BP,DI
	NOT	CL
	MOV	byte [ds:80H],CL
	POP	SI

;-----
; Some of these comments are sadly at odds with this brave new code.
;-----
; If the command has 0 parameters must check here for
; any switches that might be present.
; SI -> first character after the command.

	mov	DI, word [ARG+arg_unit.argv+0+argv_ele.argsw_word]
	mov	[COMSW], DI			; ah yes, the old addressing mode problem...
	mov	SI, word [ARG+arg_unit.argv+1 * sizeof.argv_ele+argv_ele.argpointer]       ; s = argv[1];
	OR	SI,SI				;   if (s == NULL)
	JNZ	DoParse_TCODE
	MOV	SI,BP				;	s = bp; (buffer end)

DoParse_TCODE:
	MOV	DI,FCB
	MOV	AX,(Parse_File_Descriptor SHL 8) OR 01H
	INT	int_command
	MOV	[PARM1],AL			; Save result of parse

	mov	DI, word [ARG+arg_unit.argv+1*sizeof.argv_ele+argv_ele.argsw_word]
	mov	[ARG1S], DI
	mov	SI, word [ARG+arg_unit.argv+2*sizeof.argv_ele+argv_ele.argpointer] ; s = argv[2];
	OR	SI,SI				;   if (s == NULL)
	JNZ	DoParse2
	MOV	SI,BP				;	s = bp; (bufend)1

DoParse2:
	MOV	DI,FCB+10H
	MOV	AX,(Parse_File_Descriptor SHL 8) OR 01H
	INT	int_command			; Parse file name
	MOV	[PARM2],AL			; Save result

	mov	DI, word [ARG+arg_unit.argv+2*sizeof.argv_ele+argv_ele.argsw_word]
	mov	[ARG2S], DI
	mov	DI, word [ARG+arg_unit.argv+0+argv_ele.argsw_word]
	not	DI				; ARGTS doesn't include the flags
	and	DI, word [ARG+arg_unit.argswinfo]  ; from COMSW...
	mov	[ARGTS], DI

	MOV	AL,[IDLEN]
	MOV	DL,[SPECDRV]
	or	DL, DL				; if a drive was specified...
	jnz	externalj1			; it MUST be external, by this time
	dec	al				; (I don't know why -- old code did it)
	jmp	fndcom				; otherwise, check internal com table

externalj1:
	jmp	EXTERNAL

nullcom:
	MOV	DS,[RESSEG]
;ASSUME	DS:RESGROUP
	TEST	word [BATCH], -1  ;G Are we in a batch file?
	JZ	nosetflag			;G only set flag if in batch
	mov	byte [NULLFLAG],nullcommand        ;G set flag to indicate no command

nosetflag:
	CMP	word [SINGLECOM],-1
	JZ	EXITJ
	JMP	GETCOM

EXITJ:
	JMP	EXITPREP$

IF IBM
	include 'MSHALO.ASM'
end if

end if
;	END
