TITLE	CHKDSK - MS-DOS Disk consistancy checker
page	,132					;

	.xlist
	include 'CHKSEG.INC'
	include 'CHKCHNG.INC'
	include 'DOSSYM.INC'
	include 'CHKEQU.INC'
	include 'CHKMACRO.INC'
	include 'PATHMAC.INC'
	.list

SUBTTL	Initialized Data
PAGE
if SEGSEL = S_CONST
;	EXTRN  BADVER:byte,BADDRV_ARG:word,INVPATH_ARG:word
;	EXTRN  FILE_ARG:word
;	EXTRN  BADCD_ARG:word,BADSUBDIR:byte
;	EXTRN  BADDRVM:byte
;	EXTRN  BADIDBYT:byte
;	EXTRN  OPNERR_ARG:word,NOEXT_ARG:word,EXTENT_ARG:word
;	EXTRN  IDMES_ARG:WORD
;	EXTRN  FILE_ARG1:WORD,FILE_ARG2:WORD
;	EXTRN  badrw_num:word,BADRW_STR:WORD,BLOCK_NUM:WORD
;	EXTRN  BADSW_ARG:WORD,DSKSPC:WORD
;	EXTRN  HIDMES:WORD,DIRMES:WORD,FILEMES:WORD,ORPHMES2:WORD
;	EXTRN  ORPHMES3:WORD,BADSPC:WORD,FRESPC:WORD
;	EXTRN  TOTMEM:WORD,FREMEM:WORD,REPORT_ARG:WORD,CRLF_ARG:WORD
;	EXTRN  RARG1:dWORD,RARG3:dWORD,ORPHCNT:dWORD		    ;an049;bgb
;	EXTRN  SubstErr:BYTE
;	extrn  tot_bytes_lo:word, tot_bytes_hi:word

;	extrn	SWITCHAR:byte,TCHAR:byte,HECODE:byte,CONBUF:byte
;	extrn	DOTMES:byte,NOISY:byte,HAVFIX:byte
;	extrn	DOFIX:byte,DIRBUF:near,PARSTR:byte
;	extrn	NUL:byte,ERRSUB:word,ALLFILE:byte
;	extrn	ORPHFCB:byte,ORPHEXT:byte,HIDCNT:dword
;	extrn	HIDSIZ:word,FILCNT:dword,FILSIZ:word,DIRCNT:dword		 ;an049;bgb
;	extrn	DIRSIZ:word,CROSSCNT:dword,BADSIZ:word			     ;an049;bgb
;	extrn	ORPHSIZ:word						    ;an049;bgb
;	extrn	LCLUS:word						    ;an049;bgb
;	extrn	USERDIR:byte,FRAGMENT:byte
;	extrn	ALLDRV:byte,FIXMFLG:byte,DIRCHAR:byte
;	extrn	EOFVAL:word						     ;an050;bgb
;	extrn	Idmes2:Byte,Idmes1:Byte,idmes3:byte				;an017;bgb
end if

SUBTTL	Un-initialized Data
PAGE
if SEGSEL = S_DATA
;	extrn	THISDPB:dword,DOTSNOGOOD:byte,NUL_ARG:byte
;	extrn	NAMBUF:byte,SRFCBPT:word
;	extrn	ISCROSS:byte,MCLUS:word,CSIZE:byte,SSIZE:word
;	extrn	DSIZE:word,ARG1:word,ARG_BUF:byte,ERRCNT:byte
;	extrn	USERDEV:byte,HARDCH:dword,CONTCH:dword
;	extrn	mem_size:word							;an055;bgb
;	extrn	psp_segment:word						;an030;bgb
;	extrn	write_fault:byte						;an045;bgb
end if

if SEGSEL = S_CODE
;ASSUME	CS:DG_,DS:DG_,ES:DG_,SS:DG_
;	EXTRN	INT_23:NEAR
;	EXTRN	PROMPTYN:NEAR,GET_CURRDIRERR:NEAR,GET_CURRDIR:NEAR
;	EXTRN	FINDCHAIN:NEAR,CHECKERR:NEAR
;	EXTRN	Write_Disk:Near, multiply_32_bits:near

;	PUBLIC	PRINTF_CRLF,DOCRLF,SUBERRP,FCB_TO_ASCZ,EPRINT
;	PUBLIC	DOINT26,DOTCOMBMES,REPORT
;	public	ramcarv


;EPRINT:
;	 CALL	 CHECKERR
;	 JNZ	 RET14
;	 cmp	 byte ptr [nul_arg],0
;	 jnz	 hav_eprint_arg
;	 mov	 [file_arg2],offset nul
;hav_eprint_arg:
;	 mov	 [file_arg1],dx
;	;mov	 dx,offset file_arg
;	 mov	 dx,file_arg			 ;Get offset of message 	 ;AC000;
;	 call	 printf_crlf
;	 mov	 byte ptr [nul_arg],0
;RET14:  ret


EPrint:
	call	CHECKERR			;See if we should display msg
	pathlabl chkdsk2
;	IF$	Z				;Yes if Z set			;AC000;
	JNZ IF1$$2
	push	dx				;Save message			;AC000;
	Message file_arg			;Put out file in question	;AC000;
	pop	dx				;Get back message		;AC000;
	call	PRINTF_CRLF			;Print it
	cmp	byte [NUL_ARG],0      ;Is there a second message?
;	IF$	NZ				;Yes if not nul 		;AC000;
	JZ IF2$$2
	mov	dx,[file_arg2] ;Display it			;AN000;
	call	PRINTF_CRLF			;				;AN000;
;	ENDIF$					;				;AC000;
IF2$$2:
	mov	byte [NUL_ARG],0      ;Re-init this field
;	ENDIF$
IF1$$2:
	ret					;

DOTCOMBMES:
	CMP	byte [NOISY],0
	JZ	SUBERRP
	mov	[file_arg2],dx
	CALL	get_currdirERR
       ;MOV	DX,offset CENTRY		;Centry got split into 3 msg's
       ;inc	byte ptr [nul_arg]		;
	CALL	EPrint
	RET

SUBERRP:
	MOV	AL,1			;found a subdir error
	XCHG	AL,byte [ERRSUB]     ;set error flag and get old flag
	CMP	AL,0			;were any errors found before?
;	if$	z			;no errors found yet
	JNZ IF5$$2
					 ;JNZ	  RET32
	    MOV     SI,NUL           ;display error msgs
	    CALL    get_currdirERR
	    MOV     DX,badsubdir
	    CALL    EPrint
;	endif$
IF5$$2:
RET32:	RET

;****************************************************************************
; called by:  get_thisel2
; inputs:   DS:SI - pointer to file name
;****************************************************************************
FCB_TO_ASCZ:				;Convert DS:SI to ASCIZ ES:DI
	PUSH	CX
;move filename from ds:si to es:di
	MOV	CX,8			; Pack the name
	REP	MOVSB			; Move all of it
main_kill_tail:
; delete trailing spaces in name
	CMP	byte [es:DI-1]," "     ;was the last char in name a space?
	JNZ	find_check_dot
	DEC	DI			; Back up over trailing space
	INC	CX
	CMP	CX,8
	JB	main_kill_tail
find_check_dot:
; ???
	CMP	word [SI],(" " SHL 8) OR " "
	JNZ	got_ext 		; Some chars in extension
	CMP	byte [SI+2]," "
	JZ	find_done		; No extension
got_ext:
; move period for extension
	MOV	AL,"."
	STOSB
; move 3 byte extension
	MOV	CX,3
	REP	MOVSB
ext_kill_tail:
;delete trailing blanks
	CMP	byte [es:DI-1]," "     ;
	JNZ	find_done		;
	DEC	DI			; Back up over trailing space
	JMP	ext_kill_tail		;
find_done:				;
; put hex zero at the end
	XOR	AL,AL			;
	STOSB				; NUL terminate
	POP	CX
	RET


DOINT26:
;	PUSH	CX			;reg saves are handled in write_disk	;ac048;bgb;an045;bgb
;	PUSH	DX			;reg saves are handled in write_disk	;ac048;bgb;an045;bgb
;	PUSH	BX			;reg saves are handled in write_disk	;ac048;bgb;an045;bgb
	call	write_disk		;					;an045;bgb;AC000;
;	POP	BX			;reg saves are handled in write_disk	;ac048;bgb;an045;bgb
;	POP	DX			;reg saves are handled in write_disk	;ac048;bgb;an045;bgb
;	POP	CX			;reg saves are handled in write_disk	;ac048;bgb;an045;bgb
;	JNC	RET23								;ac048;bgb;an045;bgb
       ;MOV	SI,offset WRITING						;ac048;bgb;an045;bgb
       ;CALL	DSKERR								;ac048;bgb;an045;bgb
;      IF$	C								;ac048;bgb;an045;bgb
       JNC IF7$$2
	   mov	   dx,write_fault            ;ac048;bgb;an045;bgb
	   invoke  PRINTF_CRLF							;ac048;bgb;an045;bgb
;      ENDIF$									;ac048;bgb;an045;bgb
IF7$$2:
;										;ac048;bgb;ac048;bgb;an045;bgb
;Need to handle 'Fail' option of critical error here.				;ac048;bgb;an045;bgb
;										;ac048;bgb;an045;bgb
										;ac048;bgb;an045;bgb
;	JZ	DOINT26 							;ac048;bgb;an045;bgb
RET23:	RET									;ac048;bgb;an045;bgb



;**************************************
; Prints all reporting data
;**************************************

REPORT:
;total disk space
    mov     bx,dskspc
    mov     dx,[tot_bytes_hi] ;total bytes   in disk		;AN006;bgb
    mov     ax,[tot_bytes_lo] ;total bytes   in disk		;AN006;bgb
    xor     si,si			;no file count
    xor     di,di			;no file count
    call    report_mes_2		;				;AN006;bgb
;hidden files
    mov     ax,[HIDSIZ] ;get cluster count		;an049;bgb
    or	    ax,ax			;are there any hidden files?
;   IF$     NZ				;yes				       ;AC000;
    JZ IF9$$2
	mov	si,word [HIDCNT]   ;si=low file count		    ;an049;bgb
	mov	di,word [HIDCNT+2]   ;di=hi file count		    ;an049;bgb
	mov	bx,hidmes        ;bx=msg ;
	call	report_mes_1			;
;   ENDIF$				    ;				    ;AC000;
IF9$$2:
;space in subdirectories
    mov     ax,[DIRSIZ] ;get cluster count
    or	    ax,ax			;Are there any directories?    ;an049;bgb
;   IF$     NZ				;yes				       ;AC000;
    JZ IF11$$2
	mov	si,word [DIRCNT]   ;si=low file count		    ;an049;bgb
	mov	di,word [DIRCNT+2]   ;di=hi file count		    ;an049;bgb
	mov	bx,dirmes        ;bx=msg
	call	report_mes_1						    ;an049;bgb
;   ENDIF$				    ;				    ;AC000;
IF11$$2:
;user files
    mov     ax,[FILSIZ] ;get cluster count
    or	    ax,ax			;Are there any user files?    ;an049;bgb
;   IF$     NZ				;yes				       ;AC000;
    JZ IF13$$2
	mov	si,word [FILCNT]   ;si=lo file count		    ;an049;bgb
	mov	di,word [FILCNT+2]   ;di=hi file count		    ;an049;bgb
	mov	bx,filemes        ;bx=msg
	call	report_mes_1
;   ENDIF$				    ;				    ;AC000;
IF13$$2:
;chains of lost clusters
    mov     ax,[ORPHSIZ] ;get cluster count
    or	    ax,ax			;Are there any lost clusters?	;an049;bgb
;   IF$     NZ				;yes				       ;AC000;
    JZ IF15$$2
	mov	si,word [orphcnt]   ;si=lo file count
	mov	di,word [orphcnt+2]   ;di=hi file count
	cmp	byte [DOFIX],0 ;/F entered?
;	IF$	Z			;no				;AC000;
	JNZ IF16$$2
	    mov     bx,orphmes3        ;bytes would be recovered
;	else$
	JMP SHORT EN16$$2
IF16$$2:
	    mov     bx,orphmes2        ;bytes were	recovered
;	ENDIF$					;				;AC000;
EN16$$2:
	call	report_mes_1
;   ENDIF$				    ;				    ;AC000;
IF15$$2:
;clusters of bad spots
    mov     ax,[BADSIZ] ;get cluster count
    or	    ax,ax			;Are there any bad spots on disk?
;   IF$     NZ				;if low word > zero, then yes	       ;AC000;
    JZ IF20$$2
	xor	si,si			;no files to count
	xor	di,di			;no files to count
	mov	bx,badspc         ;Issue report
	call	report_mes_1
;   ENDIF$				    ;				    ;AC000;
IF20$$2:
;bytes on disk left - free space
	mov	ax,[DSIZE]		;get total disk clusters
	sub	ax,[DIRSIZ]		; - dirs
	sub	ax,[FILSIZ]		; - files
	sub	ax,[HIDSIZ]		; - hidden files
	sub	ax,[BADSIZ]		; - bad spots
	sub	ax,[ORPHSIZ]		; - lost clusters recovered
	sub	ax,[LCLUS]		; - lost clusters not recovered
	xor	si,si
	xor	di,di
	mov	bx,frespc
	call	report_mes_1		;Free space is whats left
	call	DOCRLF				;				;AN000;
;size of each allocation unit
	xor	dx,dx				;Figure out cluster size	;AN000;
	xor	ah,ah				;				;AN000;
	mov	cx,[SSIZE] ;Bytes/sector * 		;AN000;
	mov	al,[CSIZE] ; Sectors/cluster		;AN000;
	mul	cx				; = Bytes/Cluster in AX 	;AN000;
	mov	bx,idmes2         ;Allocation size message	;AN000;
	xor	si,si
	xor	di,di
	call	report_mes_2			;				;AN000;
;total clusters
	mov	ax,[MCLUS] ;Allocation units available	;AN000;
	dec	ax				;MCLUS is # clusters+1
	xor	dx,dx				;				;AN000;
	mov	bx,idmes1         ;				;AN000;
	xor	si,si
	xor	di,di
	call	report_mes_2			;				;AN000;
;;;;;;;;call	docrlf			;					;an017;bgb
;avail clusters 								;an017;bgb
;public avail_clus
avail_clus:
	mov	ax,[DSIZE]		;total clusters on disk 		;an017;bgb
	sub	ax,[DIRSIZ]		; - clusters in subdirs 		;an017;bgb
	sub	ax,[FILSIZ]		; - user files				;an017;bgb
	sub	ax,[HIDSIZ]		; - hidden files			;an017;bgb
	sub	ax,[BADSIZ]		; - bad spots				;an017;bgb
	sub	ax,[ORPHSIZ]		; - lost clusters recovered					   ;an017;bgb
	sub	ax,[LCLUS]		; - lost clusters not recovered 	;an017;bgb
	mov	bx,idmes3         ;				;an017;bgb
	xor	dx,dx				;				;AN017;bgb
	xor	si,si
	xor	di,di
	call	report_mes_2		;dont convert to bytes! 		;an017;bgb
	call	DOCRLF								;an017;bgb


;dcl Jan 8, 87 Compensate for RAM Carving - Start

ramcarv:
	push	es								;AN000;
	xor	bx,bx								;AN000;
	mov	ah,0c1h 		; return Ext'd Bios Data Seg Address    ;AN000;
	int	15h								;AN000;
;	IF$	NC			; ram carving exists if no carry	;AC000; 				;AN000;
	JC IF22$$2
	   xor	   ax,ax		; zero out ax
	   mov	   al,byte [es:0]     ; pointer to # of 1k blocks of RAM Carve;AN000;
	   mov	   dx,64		; convert 1k blocks to paras		;AN000;
	   mul	   dx								   ;AN000;
	   mov	   bx,ax		   ; save value in BX			   ;AN000;
;	ENDIF$					;				;AC000; 				;AN000;
IF22$$2:
	pop	es								;AN000;

;dcl Jan 8, 87 Compensate for RAM Carving - End

	mov	ax,[mem_size]	     ;Find out about memory
	add	ax,bx			; dcl Jan 8, 87 Compensate for RAM Carving
	mov	dx,16			;Mul to convert kbytes to bytes
	mul	dx
	mov	bx,totmem
	call	report_mes_2
	mov	ax,[mem_size]
;;;;;;; mov	dx,psp_segment							;an030;bgb
	sub	ax,[PSP_Segment]     ;an030;bgb
	mov	dx,16
	mul	dx
	mov	bx,fremem
	call	report_mes_2
	ret

;*************************************************************
;
;  Print the message specified by the control string.
;
; REPORT_MES_1
; On entry:
;     BX contains the address of the control string.
;     AX contains a cluster count for the %ld argument in the control string.
;     CX contains a word count for the %d argument in the control string
;	 or is meaningless.
;
; REPORT_MES_2
; On entry:
;     BX contains the address of the control string.
;     AX,DX contain a long integer.
;     CX contains a word count for the %d argument in the control string
;	 or is meaningless.
;
;*************************************************************

;*****************************************************************************
; REPORT_MES_1 -  Print the report messages.  Display the file count and
;		 translate the number of clusters into the number of bytes.
;
; WARNING!! NOTE!! -->
;
; called by - PROCEDURE NAME
;
; inputs: AX - cluster count (1-ffff)
;	  BX - offset of control string
;	  CX -
;	  DX - high word of cluster count is zero'd out here.
;	  SP -
;	  BP -
;	  SI - low word of file count
;	  DI - hi  word of file count
;	  DS - segment of control string
;	  ES -
;
; output: DISPLAY OF DATA TO SCREEN
;
; Regs abused - ALL
;
;logic: 1. zero out hi word of cluster count, and multiply by sectors per
;	   cluster.  This gives number of sectors, which is a double word.
;
;	2. multiply by bytes per sector to give number of bytes.
;
;	3. place values in diplay fields, and call the msg. retriever.
;
;*****************************************************************************
report_mes_1:
	push	bx			;save it
	xor	dx,dx			;zero out hi word for multiply
	mov	cl,[CSIZE] ;get sectors per cluster
	xor	ch,ch			;zero out hi byte of word
	mul	cx			;Convert cluster count to sector count ax/dx

	mov	bx,dx			;bx:ax is number to be mult;bgb
	mov	cx,[SSIZE] ;cx is number to mult with  ;bgb
	call	Multiply_32_Bits		       ;bgb
	mov	dx,bx			;move hi value to dx
	pop	bx			;retore pointer;bgb

report_mes_2:
	mov	word [rarg1],ax   ;Lo word of bytes in ax
	mov	word [rarg1+2],dx   ;Hi word of bytes in dx
	mov	word [rarg3],si   ;lo word of file count in si
	mov	word [rarg3+2],di   ;hi word of file count in di
	mov	[report_arg],bx ;Store the offset of the ctrl string
	mov	dx,bx			;dx has ptr to msg for disp_interface  ;AC000;
	call	PRINTF_CRLF		;print msg, then carraige return
	ret

PRINTF_CRLF:
	call	Display_Interface   ;					    ;AC000;
DOCRLF: mov	dx,crlf_arg
	call	Display_Interface	;Replace old printf call with SysDispMsg;AN000;
	ret				;					;AN000;


	pathlabl chkdsk2
end if
;	END
