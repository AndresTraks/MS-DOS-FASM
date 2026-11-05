	PAGE 60,132;
	TITLE EDLCMD1.ASM

;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: EDLCMD1.SAL
;
; DESCRIPTIVE NAME: EDLIN ROUTINES
;
; FUNCTION: THIS MODULE PROVIDES ROUTINES NEEDED FOR EDLIN'S EXECUTION.
;
; ENTRY POINT: ANY CALLED ROUTINE
;
; EXIT NORMAL: NA
;
; EXIT ERROR : NA
;
; INTERNAL REFERENCES:
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: EDLCMD2 - ROUTINES MAY BE CALLED FROM EDLCMD2
;		 EDLMES  - ROUTINES MAY BE CALLED FROM EDLMES
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK EDLIN+EDLCMD1+EDLCMD2+EDLMES+EDLPARSE
;
; REVISION HISTORY:
;
;	AN000	VERSION DOS 4.00 - REVISIONS MADE RELATE TO THE FOLLOWING:
;
;					- IMPLEMENT SYSPARSE
;					- IMPLEMENT MESSAGE RETRIEVER
;					- IMPLEMENT DBCS ENABLING
;					- ENHANCED VIDEO SUPPORT
;					- EXTENDED OPENS
;					- SCROLLING ERROR
;
; COPYRIGHT: "MS DOS EDLIN UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;
;======================= END OF SPECIFICATIONS ===========================

include 'EDLEQU.ASM'

SUBTTL	Contants and Data areas
PAGE


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
;	EXTRN	DSKFUL_ptr:word,READ_ERR_PTR:word
;	EXTRN	NOSUCH_ptr:word,TOOLNG_ptr:word,EOF_ptr:word
;	extrn	txt1:byte,txt2:byte
end if

if SEGSEL = S_CSTACK
end if

if SEGSEL = S_DATA
;	extrn	ParamCt:WORD
;	extrn	current:word,pointer:word,start:word,endtxt:word
;	extrn	wrt_handle:word,editbuf:byte,path_name:byte,fname_len:word
;	extrn	arg_buf:byte,arg_buf_ptr:word
;	extrn	olddat:byte,oldlen:word,newlen:word,param1:word,param2:word
;	extrn	srchflg:byte,srchmod:byte,comline:word,lstfnd:word,numpos:word
;	extrn	lstnum:word,srchcnt:word,amnt_req:word,delflg:byte,lastlin:word
;	extrn	three4th:word,one4th:word,last:word,rd_handle:word,ending:byte
;	extrn	haveof:byte
;	extrn	Disp_Len:Byte

end if

if SEGSEL = S_CODE
;ASSUME	CS:DG_,DS:DG_,SS:CStack,ES:DG_

;	extrn	findlin:near,shownum:near,loadbuf:near
;	extrn	delbak:near,unquote:near,lf:near
;	extrn	dispone:near,DISPLAY_:near,query:near
;	extrn	quit:near,scanln:near,scaneof:near
;	extrn	fndfirst:near,fndnext:near,replace:near,memerr:near
;	extrn	std_printf:near,chkrange:near,comerr:near

;	public	xerror,bad_read,append,nocom,pager,list
;	public	delete,replac_from_curr,search_from_curr,ewrite,wrt

NOMOREJ:JMP	NOMORE

APPEND:
	CMP	word [ParamCt],1
	JZ	AppendOK
	JMP	COMERR
AppendOK:
	TEST	byte [HAVEOF],-1
	JNZ	NOMOREJ
	MOV	DX,[ENDTXT]
	CMP	word [PARAM1],0 ;See if parameter is missing
	JNZ	PARMAPP
	CMP	DX,[THREE4TH]	;See if already 3/4ths full
	jb	PARMAPP
	return			;If so, then done already
PARMAPP:
	MOV	DI,DX
	MOV	CX,[LAST]
	SUB	CX,DX		;Amount of memory available
	jnz	sj53
	jmp	MEMERR
sj53:
	MOV	DX,[ENDTXT]
	MOV	BX,[RD_HANDLE]
	mov	[amnt_req],cx	;Save number of chars requested
	MOV	AH,Read
	INT	21H		;Fill memory with file data
	CMP	CX,AX		;Did we read less than we asked for?
	JZ	sj55
; Make sure this is an end-of-file by trying to read more
	PUSH	AX		;Save old byte count
	ADD	DX,AX		;Point to next open space in buffer
	MOV	CX,1		;Just one character past EOF
	MOV	AH,Read
	INT	21H
	CMP	AX,0		      ;Is it EOF?
	POP	AX
	JNZ	SJ54		      ;No -- we have one more character
	MOV	byte [HAVEOF],1       ;Yes - set old style system call flag
	JMP	SHORT sj55
SJ54:
	INC	AX		      ;Include one more char in byte count
sj55:
	MOV	CX,AX		      ;Want byte count in CX
	PUSH	CX		      ;Save actual byte count
	CALL	SCANEOF
	JNZ	NOTEND
	MOV	byte [HAVEOF],1     ;Set flag if 1AH found in file
NOTEND:
	XOR	DX,DX
	MOV	BX,[PARAM1]
	OR	BX,BX
	JNZ	COUNTLN
	MOV	AX,DI
	ADD	AX,CX		;First byte after loaded text
	CMP	AX,[THREE4TH]	;See if we made 3/4 full
	JBE	COUNTLN
	MOV	DI,[THREE4TH]
	MOV	CX,AX
	SUB	CX,DI		;Length remaining over 3/4
	MOV	BX,1		;Look for one more line
COUNTLN:
	CALL	SCANLN		;Look for BX lines
	CMP	[DI-1],AL	;Check for full line
	JZ	FULLN
	CMP	byte [HAVEOF],1
	JNZ	DoBackScan
;
; We have an incomplete line in the buffer at end of file.  Fix it up to be
; pretty.
;
	MOV	byte [DI],13     ; CR
	MOV	byte [DI+1],10     ; LF
	ADD	DI,2			; length is 2 greater
	POP	CX
	ADD	CX,2
	PUSH	CX
	JMP	SHORT FULLN

DoBackScan:
	DEC	DI
	MOV	CX,[LAST]
	STD
	REPNE	SCASB			;Scan backwards for last line
	CLD
	INC	DI
	INC	DI
	DEC	DX
FULLN:
	POP	CX				    ;Actual amount read
	MOV	word [DI],1AH          ;Place EOF after last line
	SUB	CX,DI
	XCHG	DI,[ENDTXT]
	ADD	DI,CX				    ;Amount of file read but not used
; Must seek for old partial line
	OR	DI,DI
	JZ	FULLN1
	PUSH	DX
	PUSH	BX
	MOV	BX,[RD_HANDLE]
	MOV	DX,DI
	NEG	DX
	MOV	CX,-1
	MOV	AL,1
	MOV	AH,LSeek
	INT	21H
	POP	BX
	POP	DX
	JC	BAD_READ
FULLN1:
	CMP	BX,DX
	JNZ	EOFCHK
	MOV	byte [HAVEOF],0
	return
NOMORE:
	MOV	DX,eof_ptr
	call	std_printf
ret3:	return

BAD_READ:
	MOV	DX,read_err_ptr
	MOV	DI,PATH_NAME
	ADD	DI,[FNAME_LEN]
	MOV	AL,0
	STOSB
	JMP	xERROR

EOFCHK:
	TEST	byte [HAVEOF],-1
	JNZ	NOMORE
	TEST	byte [ENDING],-1
	retnz			;Suppress memory error during End
	JMP	MEMERR

EWRITE:
	CMP	word [ParamCt],1
	JBE	EWriteOK
	JMP	COMERR
EWriteOK:
	MOV	BX,[PARAM1]
	OR	BX,BX
	JNZ	WRT
	MOV	CX,[ONE4TH]
	MOV	DI,[ENDTXT]
	SUB	DI,CX		;Write everything in front of here
	JBE	ret3
	CMP	DI,START        ;See if there's anything to write
	JBE	ret3
	XOR	DX,DX
	MOV	BX,1		;Look for one more line
	CALL	SCANLN
	JMP	SHORT WRTADD
WRT:
	INC	BX
	CALL	FINDLIN
WRTADD:
	CMP	byte [DELFLG],0
	JNZ	WRTADD1
	PUSH	DI
	CALL	DELBAK			;Want to delete the .BAK file
					;as soon as the first write occurs
	POP	DI
WRTADD1:
	MOV	CX,DI
	MOV	DX,START
	SUB	CX,DX			;Amount to write
	retz
	MOV	BX,[WRT_HANDLE]
	MOV	AH,Write
	INT	21H
	JC	WRTERR
	CMP	AX,CX			; MZ correct full disk detection
	JNZ	WRTERR			; MZ correct full disk detection
	MOV	SI,DI
	MOV	DI,START
	MOV	[POINTER],DI
	MOV	CX,[ENDTXT]
	SUB	CX,SI
	INC	CX			;Amount of text remaining
	CLD
	REP	MOVSB
	DEC	DI			;Point to EOF
	MOV	[ENDTXT],DI
	MOV	word [CURRENT],1
	return

WRTERR:
	MOV	BX,[WRT_HANDLE]
	MOV	AH,Close
	INT	21H
	MOV	DX,dskful_ptr
xERROR:
	push	cs
	pop	ds
	call	std_printf
	mov	al,0ffh
	mov	ah,Exit
	int	21h

NOTFNDJ:JMP	NOTFND

replac_from_curr:
	CMP	word [ParamCt],2
	JBE	Replace1
	JMP	COMERR
Replace1:
	mov	byte [srchmod],1       ;search from curr+1 line
	jmp	short sj6

REPLAC:
	mov	byte [srchmod],0       ;search from beg of buffer
sj6:
	MOV	byte [SRCHFLG],0
	CALL	FNDFIRST
	JNZ	NOTFNDJ
REPLP:
	MOV	SI,[NUMPOS]
	CALL	LOADBUF 	;Count length of line
	SUB	DX,[OLDLEN]
	MOV	CX,[NEWLEN]
	ADD	DX,CX		;Length of new line
	CMP	DX,254
	jbe	len_ok
	Jmp	TOOLONG
len_ok:
	MOV	BX,[LSTNUM]
	PUSH	DX
	CALL	SHOWNUM
	POP	DX
	MOV	CX,[LSTFND]
	MOV	SI,[NUMPOS]
	SUB	CX,SI		;Get no. of char on line before change
	DEC	CX
	mov	di,arg_buf        ;Initialize the output string buffer
	CALL	OUTCNT		;Output first part of line
	PUSH	SI
	MOV	SI,1+ TXT2
	MOV	CX,[NEWLEN]
	CALL	OUTCNT		;Output change
	POP	SI
	ADD	SI,[OLDLEN]	;Skip over old stuff in line
	MOV	CX,DX		;DX=no. of char left in line
	ADD	CX,2		;Include CR/LF
	CALL	OUTCNT		;Output last part of line
	xor	al,al
	stosb
	mov	dx,arg_buf_ptr
	call	std_printf
	CALL	QUERY		;Check if change OK
	JNZ	REPNXT
	CALL	PUTCURS
	MOV	DI,[LSTFND]
	DEC	DI
	MOV	SI,1+ TXT2
	MOV	DX,[OLDLEN]
	MOV	CX,[NEWLEN]
	DEC	CX
	ADD	[LSTFND],CX	;Bump pointer beyond new text
	INC	CX
	DEC	DX
	SUB	[SRCHCNT],DX	;Old text will not be searched
	JAE	SOMELEFT
	MOV	word [SRCHCNT],0
SOMELEFT:
	INC	DX
	CALL	REPLACE
REPNXT:
	CALL	FNDNEXT
	retnz
	JMP	REPLP

OUTCNT:
	JCXZ	RET8
OUTLP:
	LODSB
	stosb
	DEC	DX
	LOOP	OUTLP
RET8:	return

TOOLONG:
	MOV	DX,toolng_ptr
	JMP	SHORT PERR

search_from_curr:
	CMP	word [ParamCt],2
	JBE	Search1
	JMP	COMERR
Search1:
	mov	byte [srchmod],1       ;search from curr+1 line
	jmp	short sj7

SEARCH:
	mov	byte [srchmod],0       ;search from beg of buffer
sj7:
	MOV	byte [SRCHFLG],1
	CALL	FNDFIRST
	JNZ	NOTFND
SRCH:
	MOV	BX,[LSTNUM]
	MOV	SI,[NUMPOS]
	CALL	DISPONE
	MOV	DI,[LSTFND]
	MOV	CX,[SRCHCNT]
	MOV	AL,10
	CLD
	REPNE	SCASB
	JNZ	NOTFND
	MOV	[LSTFND],DI
	MOV	[NUMPOS],DI
	MOV	[SRCHCNT],CX
	INC	word [LSTNUM]
	CALL	QUERY
	JZ	putcurs1
	CALL	FNDNEXT
	JZ	SRCH
NOTFND:
	MOV	DX,nosuch_ptr
PERR:
	call	std_printf
	return

;
; Replace enters here with LSTNUM pointing to the correct line.
;
PUTCURS:
	MOV	BX,[LSTNUM]
	jmp	short putcursor
;
; Search enters here with LSTNUM pointing AFTER the correct line
;
putcurs1:
	MOV	BX,[LSTNUM]
	DEC	BX			;Current <= Last matched line

putcursor:
	CALL	FINDLIN
	MOV	[CURRENT],DX
	MOV	[POINTER],DI
	return

;
; n,mD	    deletes a range of lines.  Allowable values for n are:
;   1 ... LAST.  Allowable values for m are:
;   1 ... LAST.
; nD	    deletes a single line
; D	    deletes the current line
;
DELETE:
	CMP	word [ParamCt],2 ; at most two parameters specified.
	JA	COMERRJ
	MOV	BX,[PARAM1]
	OR	BX,BX			; default first arg?
	JNZ	DelParm2
	MOV	BX,[CURRENT] ; use current as default
	MOV	[PARAM1],BX
DelParm2:
	MOV	BX,[PARAM2] ; did we default second arg?
	OR	BX,BX
	JNZ	DelCheck		; no, use it.
	MOV	BX,[PARAM1] ; use param1 as default
	MOV	[PARAM2],BX
DelCheck:
	MOV	BX,[PARAM1]
	CALL	CHKRANGE		; returns by itself if bad range
;
; BX is first line of range to be deleted. Param2 is last line in range to
; be deleted.  Get pointer to beginning of block.  Save location
;
	CALL	FINDLIN 		; Grab line
	retnz				; If not found => return
	PUSH	BX
	PUSH	DI
;
; Get pointer past end of block (Param2+1).
;
	MOV	BX,[PARAM2]
	INC	BX
	CALL	FINDLIN
;
; Set up pointers.  Compute number of chars to move.
;
	MOV	SI,DI			; move from second line+1
	POP	DI			; restore destination (first line)
	POP	[CURRENT] ; Current line is first param
	MOV	[POINTER],DI ; internal current line
	MOV	CX,[ENDTXT] ; compute count
	SUB	CX,SI
	JB	COMERRJ 		; should never occur: ChkRange
	INC	CX			; remember ^Z at end
	CLD
	REP	MOVSB			; move data
	DEC	DI
	MOV	[ENDTXT],DI ; reset end pointer
	return

COMERRJ:
	JMP	COMERR

PAGER:
	CMP	word [ParamCt],2
	JA	COMERRJ
	xor	bx,bx		;get last line in the buffer
	call	FINDLIN
	mov	[LASTLIN],dx

	mov	bx,[PARAM1]
	or	bx,bx		;was it specified?
	jnz	frstok		;yes, use it
	mov	bx,[CURRENT]
	cmp	bx,1		;if current line =1 start from there
	je	frstok
	inc	bx		;start from current+1 line
frstok:
	cmp	bx,[LASTLIN]	;check that we are in the buffer
	jbe	frstok1
	return			;if not just quit
frstok1:
	mov	dx,[PARAM2]
	or	dx,dx		;was param2 specified?
	jnz	scndok		;yes,....
	mov	dx,bx		;no, take the end line to be the
				;    start line + length of active display

;=========================================================================
; This modification is to provide support for screens larger than
; 24 lines.
;
;	Date	   : 6/10/87
;=========================================================================

	push	ax		;an000;save affected registers

	mov	ah,00h		;an000;zero out high byte
	mov	al,[Disp_Len] ;an000;set ax to active display length
	sub	ax,2		;an000;adjust for length of screen & current
				;      line
	add	dx,ax		;an000;this gives us the last line to be
				;      printed
	pop	ax		;an000;restore affected registers

;=========================================================================

scndok:
	inc	dx
	cmp	dx,[LASTLIN]	;check that we are in the buffer
	jbe	infile
	mov	dx,[LASTLIN]	;we are not, take the last line as end
infile:
	cmp	dx,bx		;is param1 < param2 ?
	retz
	ja	sj33
	jmp	COMERR		;yes, no backwards listing, print error
sj33:
	push	dx		;save the end line
	push	bx		;save start line
	mov	bx,dx		;set the current line
	dec	bx
	call	FINDLIN
	mov	[POINTER],di
	mov	[CURRENT],dx
	pop	bx		;restore start line
	call	FINDLIN 	;get pointer to start line
	mov	si,di		;save pointer
	pop	di		;get end line
	sub	di,bx		;number of lines
	jmp	short display_lines


LIST:
	CMP	word [ParamCt],2
	JBE	ListOK
	JMP	COMERR
ListOK:
	MOV	BX,[PARAM1]
	OR	BX,BX
	JNZ	CHKP2
	MOV	BX,[CURRENT]
	SUB	BX,11
	JA	CHKP2
	MOV	BX,1
CHKP2:
	CALL	FINDLIN
	retnz
	MOV	SI,DI
	MOV	DI,[PARAM2]
	INC	DI
	SUB	DI,BX
	JA	display_lines

;=========================================================================
; This modification is to provide support for screens larger than
; 24 lines.
;
;	Date	   : 6/10/87
;=========================================================================

	push	ax			;an000;save affected registers

	mov	ah,00h			;an000;zero out high byte
	mov	al,[Disp_Len] ;an000;set ax to active display length	       dec     ax		       ;an000;allow room at bottom for
					;      messages
	mov	di,ax			;an000;number of lines to print an
					;      entire screen less 1.
	pop	ax			;an000;restore affected registers

;=========================================================================

display_lines:
	call	DISPLAY_
	return

BREAK <NOCOM - edit a single line>

;
; NOCOM is called when there is a single line being edited.  This occurs when
; the command letter is CR or is ;.
;
NOCOM:
	CMP	word [ParamCt],2
	JB	NoComOK
	JMP	COMERR
NoComOK:
	DEC	word [COMLINE]
	MOV	BX,[PARAM1]
	OR	BX,BX
	JNZ	HAVLIN
	MOV	BX,[CURRENT]
	INC	BX	;Default is current line plus one
	CALL	CHKRANGE
HAVLIN:
	CALL	FINDLIN
	MOV	SI,DI
	MOV	[CURRENT],DX
	MOV	[POINTER],SI
	jz	sj12
ret12:	return
sj12:
	CMP	SI,[ENDTXT]
	retz
	CALL	LOADBUF
	MOV	[OLDLEN],DX
	MOV	SI,[POINTER]
	CALL	DISPONE
	CALL	SHOWNUM
	MOV	AH,Std_Con_String_Input 	  ;Get input buffer
	MOV	DX,EDITBUF
	INT	21H
	CALL	LF
	MOV	CL,[EDITBUF+1]
	MOV	CH,0
	JCXZ	ret12
	MOV	DX,[OLDLEN]
	MOV	SI,2 + EDITBUF
;-----------------------------------------------------------------------
	call	unquote 		;scan for quote chars if any
;-----------------------------------------------------------------------
	mov	cl,[EDITBUF+1]		;an000; dms;get new line length
	mov	ch,0			;an000; dms;clear high byte
	MOV	DI,[POINTER]
	JMP	REPLACE 		; MZ 11/30

end if
;	END
