STRUC SRCHFCB
{
	Rb	44
}
match =SRCHFCB_LAID_OUT, SRCHFCB_LAID_OUT
{
    SRCHFCB_LAID_OUT equ 1
    virtual at 0
      SRCHFCB SRCHFCB
      sizeof.SRCHFCB = $ - SRCHFCB
    end virtual
}
TITLE	CHKPROC - PART1 Procedures called from chkdsk
page	,132					;

	.xlist
	include 'CHKSEG.INC'
	include 'CHKCHNG.INC'
	include 'DOSSYM.INC'
	include 'CHKEQU.INC'
	include 'CHKMACRO.INC'
	include 'PATHMAC.INC'
	.list


if SEGSEL = S_DATA
;	EXTRN	FIXMES_ARG:word,DIREC_ARG:word
;	EXTRN	NULDMES:byte,NULNZ:byte,BADCLUS:byte,NORECDOT:byte
;	EXTRN	NoRecDDot:Byte
;	EXTRN	BADCHAIN:byte,NDOTMES:byte,CDDDMES:byte
;	EXTRN	NORECDDOT1:byte,NORECDDOT2:byte,NORECDDOT3:byte
;	EXTRN	STACKMES:byte
;	EXTRN	BADDPBDIR:byte, BadSubDir:byte
;	EXTRN	BADTARG_PTR:byte,BADTARG2:byte,JOINMES:byte
;	EXTRN	PTRANDIR:byte,PTRANDIR2:byte
;	EXTRN	CROSS_ARG:word,NOISY_ARG:word
;	EXTRN	FILE_ARG1:WORD,FILE_ARG2:WORD,FILE_ARG:word
;	EXTRN	DOTMES:byte,NOISY:byte,DOTENT:byte,HAVFIX:byte
;	EXTRN	DOFIX:byte,DIRBUF:byte,PARSTR:byte,DDOTENT:byte
;	EXTRN	NUL:byte,ERRSUB:word,SECONDPASS:byte,ALLFILE:byte
;	EXTRN	HIDCNT:dword,HIDSIZ:word,FILCNT:dword,FILSIZ:word	   ;an049;bgb
;	EXTRN	DIRCNT:dword							;an049;bgb
;	EXTRN	DIRSIZ:word							;an049;bgb
;	EXTRN	DIRTYFAT:byte,
;	EXTRN	HECODE:byte
;	EXTRN	ALLDRV:byte,FIXMFLG:byte,DIRCHAR:byte
;	EXTRN	BIGFAT:byte,EOFVAL:word,BADVAL:word
;	Extrn	fTrunc:BYTE							;ac048;bgb
;	Extrn	dirsec:word							;ac048;bgb

;	EXTRN	THISDPB:dword,DOTSNOGOOD:byte,NUL_ARG:byte,STACKLIM:word
;	EXTRN	ZEROTRUNC:byte,NAMBUF:byte,SRFCBPT:word,FATMAP:word
;	EXTRN	ISCROSS:byte,MCLUS:word,CSIZE:byte,SSIZE:word,fattbl:byte
;	EXTRN	DSIZE:word,ARG1:word,ARG_BUF:byte,TMP_SPC:BYTE
;	EXTRN	SECBUF:word
;	EXTRN	Inv_XA_Msg:Byte,Alloc_XA_Msg:Byte
;	Extrn	Data_Start_Low:Word,Data_Start_High:Word
;	EXTRN	Read_Write_Relative:Byte
;	EXTRN	MClus:Word,Chain_End:Word

XA_Buffer XAL       ;XA buffer space to read in 1st sector	;AN000;
Head_Mark db	0				;Flag for MarkMap			;AN000;
BClus	dw	0				;Bytes/Cluster
;public cross_clus
Cross_Clus dw	0				;Cluster crosslink occurred on
Cluster_Count dw 0				;				;AN000;
First_Cluster dw 0				;				;AN000;
Previous_Cluster	dw	0		;				;AN000;
XA_Pass db	0				;				;AN000;
File_Size_High dw 0				;				;AN000;
File_Size_Low dw 0				;				;AN000;
Chain_Size_Low	dw	0			;				;AN000;
Chain_Size_High dw	0			;				;AN000;


;public Head_Mark
;public BClus
;public Cluster_Count
;public First_Cluster
;public Previous_Cluster
;public XA_Pass
;public File_Size_High
;public File_Size_Low
;public Chain_Size_Low
;public Chain_Size_High
end if


if SEGSEL = S_CODE
;ASSUME	CS:DG_,DS:DG_,ES:DG_,SS:DG_
;Structures used by DIRPROC
; MASM worked LENGTH out as the number of elements a variable was
; declared with and SIZE as the bytes they take up.  The arrays these
; ask about are all of bytes, so the two come to the same number.
SFCBSIZ EQU	sizeof.SRCHFCB
;	EXTRN	PRINTF_CRLF:NEAR,SUBERRP:NEAR,FCB_TO_ASCZ:NEAR
;	EXTRN	FIGREC:NEAR,EPRINT:NEAR
;	EXTRN	DOINT26:NEAR,PROMPTYN:NEAR
;	EXTRN	DOTCOMBMES:NEAR,FATAL:NEAR,MARKMAP:NEAR,GETFILSIZ:NEAR
;	EXTRN	SYSTIME:NEAR, Read_Disk:Near,DoCRLF:Near
;	extrn	crosschk:near
;	extrn	UNPACK:near, PACK:near
;public DOTDOTHARDWAY, NODOT, DOEXTMES1, MESD1, CANTREC, DOTGOON, NODDOT
;public DOEXTMES2, MESD2, NFIX, CANTREC2, NULLDIRERR, DOEXTMES3, DOTSBAD
;public dotsbad2, DIRPROC, STACKISOK, NOPRINT, JOINERR
;public NONULLDERr, DOTOK, DATTOK, DLINKOK, BADDSIZ, DSIZOK, CHKDOTDOT
;public DOTDOTOK, DDATTOK, DDLINKOK, BADDDSIZ, DDSIZOK, ROOTDIR
;public DODDH, DIRDONE, MOREDIR, FPROC1, NOPRINT2, HIDENFILE, NORMFILE, NEWDIR
;public DPROC1, CONVDIR, DPROC2, CANTTARG, BogusDir, ASKCONV
;public PRINTTRMES, CROSSLOOK, CHLP, CROSSLINK, CHAINDONE
;public FIXENT2, RET20, FIXENT, GETENT, CLUSISOK
;public SKIPLP, GOTCLUS, DOROOTDIR, RDRETRY, RDOK2, WANTROOT, CHECKNOFMES, ret14
;public CHECKERR, get_currdirERR, ok_pri_dir, get_thiselERR, ok_pri_el
;public get_THISEL, get_THISEL2, get_currdir, GET_END, ERRLOOP, LPDONE
;public CHECK_SPLICE, NT_SPLC, MarkFAT, Bad_Cluster, Check_Chain_Sizes
;public print_filename								;ac048;bgb
;public NOTROOT									;ac048;bgb
;public FIXDOT									;ac048;bgb


	pathlabl chkproc
SUBTTL	DIRPROC -- Recursive directory processing
PAGE
;**************************************************************************
; DOTDOTHARDWAY - change dir to the previous directory using '..'
;
; called by -
;
; inputs - parse string '..'
;
; outputs - new default directory
;
;NOTE
; On versions of DOS < 2.50 "cd .." would fail if there was no ".."
;    entry in the current directory. On versions >= 2.50 "cd .."
;    is handled as a string manipulation and therefore should always
;    work. On < 2.50 this routine didddled the current directory string
;    INSIDE THE DOS DATA STRUCTURES. This is no longer desirable, or
;    needed.
;**************************************************************************
Procedure dotdothardway
	MOV	DX,PARSTR
	DOS_Call CHDir				;				;AC000;
	RET
EndProc dotdothardway


;**************************************************************************	;ac048;bgb
; NODOT - come here if there is no . entry in the first entry of the sub-	;ac048;bgb
;	  directory.  The . entry is a pointer to the subdirectory itself.	;ac048;bgb
;	  The entry from the search first did not find it, and the subdir is	;ac048;bgb
;	  not joined.  So, try to put a new . entry into the first slot.	;ac048;bgb
;										;ac048;bgb
; called by - nonullderr							;ac048;bgb
;										;ac048;bgb
; inputs -  SI - points to arg_buf, which is a filespec 			;ac048;bgb
;	    DI - points to tmp_spc, which is a filespec 			;ac048;bgb
;	    AX - return value from search first 				;ac048;bgb
;										;ac048;bgb
; outputs - if the /f parm was entered, tries to replace the . entry		;ac048;bgb
;	    AX - saves the return value from search first			;ac048;bgb
;										;ac048;bgb
; logic: 1. go display error messages.	Different messages are displayed,	;ac048;bgb
;	    depending on /f and /v parms.					;ac048;bgb
;										;ac048;bgb
;	2. go get the sector number and read it into ram			;ac048;bgb
;										;ac048;bgb
;	3. if the first entry is erased (begins with hex e5), then we can	;ac048;bgb
;	   fill it with the corrected . entry. Otherwise, go to #6.		;ac048;bgb
;										;ac048;bgb
;	4. So, fill entry with all the dir fields - name, ext, attr, date,	;ac048;bgb
;	   time, size, cluster #.						;ac048;bgb
;										;ac048;bgb
;	5. write it back to disk.						;ac048;bgb
;										;ac048;bgb
;	6. go check out the .. entry						;ac048;bgb
;**************************************************************************	;ac048;bgb
NODOT:						;No .				;ac048;bgb
	PUSH	AX			;save the return value from search 1st	;ac048;bgb
;display msgs				;;;;;;;;jnz	doextmes1		;ac048;bgb
	CMP	byte [NOISY],OFF ;was /v parm entered?			;ac048;bgb;AC000;
;	IF$	Z			;display no /v msgs			;ac048;bgb
	JNZ IF1$$C
	    call    SUBERRP							;ac048;bgb
					;;;;;;;;jmp	short mesd1		;ac048;bgb
;	ELSE$				;display /v msgs			;ac048;bgb
	JMP SHORT EN1$$C
IF1$$C:
DOEXTMES1:  mov     si,DOTMES        ;first find out where we are		;ac048;bgb
	    call    get_currdirERR						;ac048;bgb
	    mov     dx,ndotmes        ;print dir, dot, and 'not found' msg	;ac048;bgb
	    call    EPrint							;ac048;bgb
;	ENDIF$									;ac048;bgb
EN1$$C:
										;ac048;bgb
;go find the sector								;ac048;bgb
MESD1:	XOR	AX,AX			;set entry number to zero		;ac048;bgb
	PUSH	BX			;save					;ac048;bgb
	PUSH	BP			;save					;ac048;bgb
	CALL	GETENT			;get the sector number			;ac048;bgb
	POP	BP			;restore bp				;ac048;bgb
	PUSH	BP			;put it back				;ac048;bgb
	CMP	byte [DI],0E5H     ;is this 1st entry erased/open? 	;ac048;bgb
;	if$	nz								;ac048;bgb
	JZ IF4$$C
;cant fill . entry			 ;JNZ	  CANTREC			;ac048;bgb  ;Nope
CANTREC:    INC     byte [DOTSNOGOOD] ;ac048;bgb
	    CMP     byte [NOISY],OFF  ;				;ac048;bgb    ;AC000;
;	    if$     nz								;ac048;bgb
	    JZ IF5$$C
						 ;JZ	  DOTGOON		;ac048;bgb
		MOV	DX,norecdot            ;ac048;bgb
		CALL	EPrint							;ac048;bgb
;	    endif$								;ac048;bgb
IF5$$C:
	    jmp     DOTGOON							;ac048;bgb
;	endif$									;ac048;bgb
IF4$$C:

;get filename
fixdot: MOV	SI,DOTENT        ;point to valid . entry
	MOV	CX,11			;move filename and ext
	REP	MOVSB				;Name
	PUSH	AX			;save disk number
;move attr byte
	MOV	AL,ISDIR		;hex 10
	STOSB					;Attribute
; Add in time for directory - BAS July 17/85
	ADD	DI,10
	push	dx			;save starting sector number		;ac048;bgb
	CALL	Systime
	STOSW					; Time
	MOV	AX,DX
	STOSW					; Date
	MOV	AX,[BP+6]
	STOSW					;Alloc #
	XOR	AX,AX
	STOSW
	STOSW					;Size
	pop	dx			;restore starting sector number 	;ac048;bgbb
	POP	AX			;
;write back to disk
	MOV	byte [HAVFIX],1 ;Have a fix
	CMP	byte [DOFIX],0 ; /f parm entered?
;	if$	nz								;ac048;bgb
	JZ IF8$$C
					 ;JZ	  DOTGOON			;ac048;bgbif not F
	    MOV     CX,1							;ac048;bgb
	    CALL    DOINT26							;ac048;bgb
					 ;JMP	  SHORT DOTGOON 		;ac048;bgb
;	endif$									;ac048;bgb
IF8$$C:
;go check out .. entry
DOTGOON: POP	 BP
	POP	BX
	POP	AX
	MOV	SI,DIRBUF
	JMP	CHKDOTDOT			;Go look for ..
;*****************************************************************************




NODDOT:             ;No ..
	PUSH	AX				;Return from SRCH
	CMP	byte [NOISY],OFF ;				;AC000;
	JNZ	DOEXTMES2
	CALL	SUBERRP
	JMP	SHORT MESD2
DOEXTMES2:
	MOV	SI,PARSTR
	CALL	get_currdirERR
	MOV	DX,ndotmes
	CALL	EPrint

MESD2:
	MOV	AX,1
	PUSH	BX
	PUSH	BP
	CALL	GETENT
	POP	BP
	PUSH	BP
	CMP	byte [DI],0E5H      ;Place to put it?
	JNZ	CANTREC2			;Nope
	MOV	SI,DDOTENT
	MOV	CX,11
	REP	MOVSB				;Name
	PUSH	AX
	MOV	AL,ISDIR
	STOSB					;Attribute
	ADD	DI,10
;
; Add in time for directory - BAS July 17/85
	push	dx			;save starting sector number		;ac048;bgb
	CALL	Systime
	STOSW					; Time
	MOV	AX,DX
	STOSW					; Date
	MOV	AX,[BP+4]
	STOSW					;Alloc #
	XOR	AX,AX
	STOSW
	STOSW					;Size
	pop	dx			;restore starting sector number 	;ac048;bgbb
	POP	AX
	MOV	byte [HAVFIX],1 ;Got a fix
	CMP	byte [DOFIX],0
	JZ	NFIX				;No fix if no F, carry clear
	MOV	CX,1
	CALL	DOINT26
NFIX:
	RestoreReg <bp,bx,ax>							;ac048;bgb
	MOV	SI,DIRBUF
	JMP	DG_:ROOTDIR 			;Process files

CANTREC2:
	RestoreReg <bp,bx,ax>							;ac048;bgb
	CMP	byte [NOISY],OFF ;				;AC000;
	JZ	dotsbad2
	MOV	DX,norecddot
	JMP	DOTSBAD

NULLDIRERR:              ;dir is empty
	CMP	byte [NOISY],OFF ;				;AC000;
	JNZ	DOEXTMES3
	CALL	SUBERRP
	JMP	SHORT dotsbad2
DOEXTMES3:
	MOV	SI,NUL
	CALL	get_currdirERR
	MOV	DX,nuldmes
DOTSBAD:					;Can't recover
	mov	word [file_arg2],badtarg2
	inc	byte [NUL_ARG]
	MOV	byte [fTrunc],TRUE
	CALL	EPrint
dotsbad2:
	CALL	dotdothardway
	INC	byte [DOTSNOGOOD]
	MOV	SP,BP				;Pop local vars
	POP	BP				;Restore frame
	RET	4				;Pop args




PAGE
;***************************************************************************
; DIRPROC - recursive tree walker
;
; called by - main-routine in chkdsk1.sal
;
; inputs    - ax=0
;	    - two words of 0 on the stack
;
;Recursive tree walker
;dirproc(self,parent)
;****************************************************************************
DIRPROC:
    MOV     byte [DOTSNOGOOD],0 ;Init to dots OK - set . or .. error flag to false
    MOV     word [ERRSUB],0  ;No subdir errors yet
    PUSH    BP				    ;Save frame pointer - 0
    MOV     BP,SP			    ;ffe2 - 2c = ffb6
    SUB     SP,SFCBSIZ			    ;Only local var

; are we at stack overflow ?
    CMP     SP,[STACKLIM]		    ; ffb6 vs. 5943		    ;an005;bgb
;   IF$     NA
    JA IF10$$C
;;;;;;;;JA	STACKISOK
	MOV	BX,stackmes         ;Out of stack
	JMP	FATAL
;   ENDIF$
IF10$$C:

STACKISOK:
;print the files as they are found
    CMP     byte [NOISY],OFF ; off= 0				    ;AC000;
;   IF$     NZ				;if not noisy, dont print filenames
    JZ IF12$$C
;;;;;;;;JZ	NOPRINT
	CMP	byte [SECONDPASS],FALSE ;				;AC000;
;	IF$	Z		      ;only print on the first pass
	JNZ IF13$$C
;;;;;;;;;;;;JNZ     NOPRINT			    ;Don't do it again on second pass
	    MOV     SI,NUL
	    CALL    get_currdir
	    mov     dx,direc_arg            ;Tell user where we are
	    CALL    PRINTF_CRLF
;	ENDIF$
IF13$$C:
;   ENDIF$
IF12$$C:

; initialize search fcb
NOPRINT:
    MOV     SI,ALLFILE           ;extended fcb
    MOV     DI,SP
    PUSH    DI
    MOV     CX,SFCBSIZ		    ;move 44dec bytes
    REP     MOVSB		    ;from allfile (ds:si) to es:di
; find this file
    POP     DX			    ; from push bp
    MOV     BX,DX			    ;BX points to SRCH FCB
    DOS_Call Dir_Search_First		;search for any file		    ;AC000;
;
    CMP     word [BP+6],0      ;attribute byte- root will = zero
;   if$     z
    JNZ IF16$$C
	jmp  DG_:ROOTDIR	 ;yes, we are at the root
;   endif$
IF16$$C:
	OR	AL,AL		 ;check return code from search first
	JZ	NONULLDERR
	CALL	CHECK_SPLICE			; See if dir is spliced
;	if$	c
	JNC IF18$$C
;;;;;;;;;;;;JC	    nulldirerr			    ; Not spliced, error
	    jmp     NULLDIRERR
;	endif$
IF18$$C:
JOINERR:
	MOV	SI,NUL
	CALL	get_currdir
	mov	byte [fTrunc],TRUE
	mov	dx,joinmes         ;				;AC000;
	call	PRINTF_CRLF			;				;AC000;
	mov	dx,badtarg2         ;				;AC000;
	call	PRINTF_CRLF			;				;AC000;
	CALL	dotdothardway
	MOV	SP,BP				;Pop local vars
	POP	BP				;Restore frame
	RET	4				;Pop args



NONULLDERR:
	MOV	SI,DIRBUF + DIRENT.DIRNAM
	MOV	DI,DOTENT
	MOV	CX,11
	REP	CMPSB
	JZ	DOTOK				;Got a . as first entry
	push	ax			;save return code from search first	;an045;bgb
	CALL	CHECK_SPLICE			; See if dir is spliced
;	IF$	C			;carry means no join on this dir	;an045;bgb
	JNC IF20$$C
	    pop ax			;restore return code			 ;an045;bgb
	    jmp NODOT			;goto no . entry code			;an045;bgb
;	ELSE$				;no carry means dir is joined		;an045;bgb
	JMP SHORT EN20$$C
IF20$$C:
	    pop ax			;restore return code			 ;an045;bgb
	    jmp JOINERR 		;goto join error code			;an045;bgb
;	ENDIF$				;no carry means dir is joined		;an045;bgb
EN20$$C:
;;;;;;;;JNC	JOINERR 			; spliced, stop 		;an045;bgb
;;;;;;;;JMP	NODOT				;No .				;an045;bgb

DOTOK:
	MOV	SI,DIRBUF
	MOV	AL,[SI+DIRENT.DIRATT]
	TEST	AL,ISDIR
	JNZ	DATTOK
	PUSH	SI				;. not a dir?
	MOV	SI,DOTMES
						;MOV	 DX,offset BADATT
	mov	dx,norecddot2         ;				;AN000;
	CALL	DOTCOMBMES
	POP	SI
	OR	[SI+DIRENT.DIRATT],ISDIR
	CALL	FIXENT				;Fix it
DATTOK:
	MOV	AX,[SI+DIRENT.DIRCLUS]
	CMP	AX,[BP+6]			;. link = MYSELF?
	JZ	DLINKOK
	PUSH	SI				;Link messed up
	MOV	SI,DOTMES
						;MOV	 DX,offset CLUSBAD
	mov	dx,norecddot1         ;				;AN000;
	CALL	DOTCOMBMES
	POP	SI
	MOV	AX,[BP+6]
	MOV	[SI+DIRENT.DIRCLUS],AX
	CALL	FIXENT				;Fix it
DLINKOK:
	MOV	AX,word [SI+DIRENT.DIRESIZ]
	OR	AX,AX
	JNZ	BADDSIZ
	MOV	AX,word [SI+DIRENT.DIRESIZ+2]
	OR	AX,AX
	JZ	DSIZOK
BADDSIZ:					;Size should be zero
	PUSH	SI
	MOV	SI,DOTMES
						;MOV	 DX,offset BADSIZM
	mov	dx,norecddot3         ;				;AN000;
	CALL	DOTCOMBMES
	POP	SI
	XOR	AX,AX
	MOV	word [SI+DIRENT.DIRESIZ],AX
	MOV	word [SI+DIRENT.DIRESIZ+2],AX
	CALL	FIXENT				;Fix it
DSIZOK: 					;Get next (should be ..)
	MOV	DX,BX
	DOS_Call Dir_Search_Next		;				;AC000;
CHKDOTDOT:					;Come here after . failure
	OR	AL,AL
	JZ	DOTDOTOK
	 JMP	NODDOT				;No ..
DOTDOTOK:
	MOV	SI,DIRBUF + DIRENT.DIRNAM
	MOV	DI,DDOTENT
	MOV	CX,11
	REP	CMPSB
;	if$	nz
	JZ IF23$$C
	    jmp     NODDOT
;;; ;;;;;;;;JNZ     NODDOT			    ;No ..
;	endif$
IF23$$C:
	MOV	SI,DIRBUF
	MOV	AL,[SI+DIRENT.DIRATT]
	TEST	AL,ISDIR
	JNZ	DDATTOK 			;.. must be a dir
	PUSH	SI
	MOV	SI,PARSTR
						;MOV	 DX,offset BADATT
	mov	dx,norecddot2         ;				;AN000;
	CALL	DOTCOMBMES
	POP	SI
	OR	[SI+DIRENT.DIRATT],ISDIR
	CALL	FIXENT				;Fix it
DDATTOK:
	PUSH	SI
	MOV	AX,[SI+DIRENT.DIRCLUS]
	CMP	AX,[BP+4]			;.. link must be PARENT
	JZ	DDLINKOK
	MOV	SI,PARSTR
						;MOV	 DX,offset CLUSBAD
	mov	dx,norecddot1         ;				;AN000;
	CALL	DOTCOMBMES
	POP	SI
	MOV	AX,[BP+4]
	MOV	[SI+DIRENT.DIRCLUS],AX
	CALL	FIXENT				;Fix it
DDLINKOK:
	MOV	AX,word [SI+DIRENT.DIRESIZ]
	OR	AX,AX
	JNZ	BADDDSIZ
	MOV	AX,word [SI+DIRENT.DIRESIZ+2]
	OR	AX,AX
;	if$	z
	JNZ IF25$$C
	    jmp     DDSIZOK
;	endif$
IF25$$C:
BADDDSIZ:					;.. size should be 0
	PUSH	SI
	MOV	SI,PARSTR
						;MOV	 DX,offset BADSIZM
	mov	dx,norecddot3         ;				;AN000;
	CALL	DOTCOMBMES
	POP	SI
	XOR	AX,AX
	MOV	word [SI+DIRENT.DIRESIZ],AX
	MOV	word [SI+DIRENT.DIRESIZ+2],AX
	CALL	FIXENT				;Fix it


;***************************************************************************
; DDSIZOK - search for the next file in this directory
;***************************************************************************
DDSIZOK:
	MOV	DX,BX				;search for Next entry
	DOS_Call Dir_Search_Next		;func=12			;AC000;

ROOTDIR:          ;come here after search first .. failure also
	OR	AL,AL			; was a matching filename found?
	JZ	MOREDIR     ;zero = yes 	;More to go
	CMP	word [BP+6],0     ;nz=no	;Am I the root?
	JZ	DIRDONE 			;Yes, no chdir
	MOV	DX,PARSTR
	DOS_Call CHDir				;				;AC000;
	JNC	DIRDONE 			;Worked

; NOTE************************************************
;   On DOS >= 2.50 "cd .." should ALWAYS work since it is
;   a string manipulation. Should NEVER get to here.

	CMP	byte [NOISY],OFF ;				;AC000;
	JZ	DODDH
	MOV	SI,NUL
	CALL	get_currdirERR
	MOV	DX,cdddmes
	CALL	EPrint
DODDH:
	CALL	dotdothardway			;Try again
DIRDONE:
	MOV	SP,BP				;Pop local vars
	POP	BP				;Restore frame
	RET	4				;Pop args



;*****************************************************************
; found at least one file in this subdir!
;*****************************************************************
MOREDIR:
	MOV	SI,DIRBUF         ;point to where ext fcb of found file is
	TEST	[SI+DIRENT.DIRATT],ISDIR ;attr 010h = sub-directory
	JNZ	NEWDIR				;Is a new directory?
	CMP	byte [SECONDPASS],FALSE ;no, same dir			;AC000;
	JZ	FPROC1				;2nd pass here
	CALL	CROSSLOOK			;Check for cross links
	JMP	DDSIZOK 		      ;Next

FPROC1:
	CMP	byte [NOISY],OFF ;				;AC000;
;	IF$	NZ		 ;print filenames?
	JZ IF27$$C
	    call    print_filename
;	ENDIF$
IF27$$C:
NOPRINT2:
	mov	word [Cluster_Count],0 ;No clusters for vol label	;AN000;
	mov	cx,0				;setup cx for 0 size vol labels ;an016;bgb
	TEST	[SI+DIRENT.DIRATT],VOLIDA ;attr=08	;Don't chase chains on labels   ;AC000;
;	IF$	Z		     ;no, regular file
	JNZ IF29$$C
	    MOV     AL,81H			    ;Head of file
	    mov     di,word [si+DIRENT+DIRENT.DIRESIZ+0] ;Get file size
	    mov     [File_Size_Low],di    ;
	    mov     di,word [si+DIRENT+DIRENT.DIRESIZ+2] ;
	    mov     [File_Size_High],di    ;
	    mov     di,[si+DIRENT+DIRENT.DIRCLUS] ;First cluster of file	    ;AN000;
	    CALL    MarkFAT
	    MOV     CX,[Cluster_Count]    ;Get number of clusters
;;;;;;;;;;;;PUSH    CX				    ;Save them
;;;;;;;;;;;;CALL    Check_Extended_Attributes	    ;See if XA exist, and handle    ;AN000;
;;;;;;;;;;;;POP     CX				    ;Get File length clusters
;;;;;;;;;;;;ADD     CX,Cluster_Count		    ;Add in XA clusters
	    TEST    [SI+DIRENT.DIRATT],HIDDN ;
	    JZ	    NORMFILE			    ;
;	ENDIF$
IF29$$C:
hidenfile:
	add	word [HIDCNT],1   ;found another hidden file	       ;an049;bgb
	adc	word [HIDCNT+2],0   ;add high word if > 64k files	     ;an049;bgb
	add	[HIDSIZ],cx ;it was this many bytes 	     ;an049;bgb
	JMP	DDSIZOK 			;Next
NORMFILE:
	add	word [FILCNT],1   ;inc file counter		     ;an049;bgb
	adc	word [FILCNT+2],0   ;add high word if >64k files	     ;an049;bgb
	add	[FILSIZ],cx ;add in size of file		     ;an049;bgb
	JMP	DDSIZOK 			;Next


;***************************************************************************
; NEWDIR - come here whenever you find another directory entry
; inputs: SI - points to directory entry
;***************************************************************************
NEWDIR:
	CMP	byte [SECONDPASS],FALSE ;are we on 2nd pass?			;AC000;
	JZ	DPROC1			;zero means no - skip next part
	CALL	CROSSLOOK		;2nd pass - Check for cross links
	JMP	SHORT DPROC2		;goto dproc2
DPROC1: 				;1st pass
	MOV	AL,82H				;Head of dir
	mov	di,[si+DIRENT+DIRENT.DIRCLUS] ;get 1st clus num from dir entry	;AN000;
	mov	word [File_Size_Low],0 ;	;Set to zero, shouldn't         ;AN000;
	mov	word [File_Size_High],0 ; be looked at for dir		;AN000;
	CALL	MarkFAT
	add	word [DIRCNT],1    ;add 1 to the dir counter	     ;an047;bgb
	adc	word [DIRCNT+2],0    ;add 1 to the high word if carry    ;an047;bgb
	MOV	CX,[Cluster_Count] ;Add count of clusters in files ;AN000;
	CMP	byte [ZEROTRUNC],0 ;did we modify the file size?		;an026;bgb
	JZ	DPROC2				;Dir not truncated
CONVDIR:				;yes, dir size truncated
	AND	[SI+DIRENT.DIRATT],NOT ISDIR ;Turn into file
	CALL	FIXENT
	POP	BX			;Get my SRCH FCB pointer back
	POP	word [ERRSUB] ;restore from prev dir
	JMP	DDSIZOK 			;Next
DPROC2:
	add	[DIRSIZ],cx ;add in siz of clusters 		;an049;bgb
; put 4 words on the stack - for next call to dirproc?
	PUSH	word [ERRSUB] ;save the fcb ptr from prev dir
	PUSH	BX				;Save my srch FCB pointer
	MOV	AX,[SI+DIRENT+DIRENT.DIRCLUS] ;get 1st cluster number
	PUSH	AX			; Give him his own first clus pointer
	PUSH	word [BP+6] ; His PARENT is me
;copy fcb name to msg string name
	ADD	SI,DIRENT.DIRNAM		;point to name, +08
	MOV	DI,NAMBUF
	SaveReg <di,ax> 		;copy to msg string
	CALL	FCB_TO_ASCZ
	RestoreReg <ax,di>
;check out validity of dir
	OR	AX,AX			;does the 1st clus in dir point to zero?
	JZ	BogusDir		; no, it is bogus
	mov	dx,di
	DOS_Call CHDir			; chdir to it				;AC000;
	JC	CANTTARG		; carry means bad dir
; go check out new dir
	CALL	DIRPROC
	POP	BX			;Get my SRCH FCB pointer back
	POP	word [ERRSUB] ;restore from prev dir
	CMP	byte [DOTSNOGOOD],0
	JNZ	ASKCONV
	JMP	DDSIZOK 			;Next
;newdir error routines
CANTTARG:
;cant chdir
	ADD	SP,8				; Clean stack
	mov	SI,dx				; Pointer to bad DIR
	CALL	get_currdirERR
	MOV	DX,badtarg_ptr
	mov	byte [fTrunc],TRUE
	call	PRINTF_CRLF
	JMP	DDSIZOK 			;Next
BogusDir:
;bad dir entry
	ADD	SP,8				; clean off stack
	MOV	SI,DX				; pointer to bad dir
	CALL	get_currdirERR			; output message with dir
	MOV	DX,badsubdir         ; real error message
	CALL	EPrint				; to stderr...
ASKCONV:
	CMP	byte [SECONDPASS],FALSE ;				;AC000;
;	if$	nz
	JZ IF31$$C
	    jmp    DDSIZOK
;;;;;;;;;;;;JNZ     DDSIZOK			    ;Leave on second pass
;	endif$
IF31$$C:
	cmp	byte [NOISY],ON ; /v entered ?			  ;An027;bgb
;	IF$	E			; no, skip next msg		  ;An027;bgb
	JNE IF33$$C
	    MOV     DX,ptrandir          ;unrecoverable error in directory ;An027;bgb
	    call    PRINTF_CRLF 	    ;display msg		      ;An027;bgb
;	ENDIF$
IF33$$C:
PRINTTRMES:
	MOV	DX,ptrandir2        ;either case - "convert dir to file?" ;An027;bgb
	CALL	PromptYN			;Ask user what to do
;	if$	nz
	JZ IF35$$C
	    jmp    DDSIZOK
;;;;;;;;;;; JNZ     DDSIZOK			    ;Leave on second pass
;	endif$
IF35$$C:
	PUSH	BP
	PUSH	BX
	MOV	AX,[BX+THISENT] 		;Entry number
	CALL	GETENT				;Get the entry
	MOV	SI,DI
	MOV	DI,DIRBUF
	PUSH	DI
	ADD	DI,DIRENT.DIRNAM
	MOV	CX,32
	REP	MOVSB				;Transfer entry to DIRBUF
	POP	SI
	PUSH	SI
	MOV	SI,[SI+DIRENT.DIRCLUS] ;First cluster
	CALL	getfilsiz
	POP	SI
	POP	BX
	POP	BP
	MOV	word [SI+DIRENT.DIRESIZ],AX ;Fix entry
	MOV	word [SI+DIRENT.DIRESIZ+2],DX
	JMP	CONVDIR 				   ;convert directory
;*****************************************************************************
;end of newdir
;*****************************************************************************



SUBTTL	fat-Look routines
PAGE
;*****************************************************************************
; CROSSLOOK - look at the fat, check for cross linked files
; called by -
;****************************************************************************
CROSSLOOK:
;Same as MRKFAT only simpler for pass 2
	MOV	[SRFCBPT],BX				   ;an014;bgb
	MOV	BX,SI					   ;an014;bgb
	MOV	SI,[BX+DIRENT.DIRCLUS] ;an014;bgb
	CALL	CROSSCHK				   ;an014;bgb
	JNZ	CROSSLINK				   ;an014;bgb
;;;;;;;;mov	XA_Pass,False				   ;an014;bgb			   ;an014;bgb

CHLP:
	PUSH	BX					   ;an014;bgb
	CALL	UNPACK					   ;an014;bgb
	POP	BX					   ;an014;bgb
	XCHG	SI,DI					   ;an014;bgb
	CMP	SI,[EOFVAL]				   ;an014;bgb
	jae	CHAINDONE				   ;an014;bgb			   ;an014;bgb
;;;;;;;;JAE	Check_XA_Cross				   ;an014;bgb			   ;an014;bgb
	CALL	CROSSCHK				   ;an014;bgb
	JZ	CHLP					   ;an014;bgb
	JMP SHORT CROSSLINK				   ;an014;bgb
							   ;an014;bgb
Check_XA_Cross: 			;					;AN000;

;;;;;;;;mov	SI,[BX.DIR_XA]		;See if extended attribute ;an014;bgb		   ;AN000;
;;;;;;;;cmp	si,0			;Is there?		   ;an014;bgb		   ;AN000;
;;;;;;;;je	ChainDoneJ		;No if zero		   ;an014;bgb		   ;AN000;
;	CALL	CROSSCHK		;Yes, see if crosslinked   ;an014;bgb		   ;AN000;
;	JNZ	CROSSLINKJ		;NZ means yes		   ;an014;bgb		   ;AN000;
;A_Cross_Loop:				;			   ;an014;bgb		   ;AN000;
;	PUSH	BX			;			   ;an014;bgb		   ;AN000;
;	CALL	UNPACK			;Get next cluster	   ;an014;bgb		   ;AN000;
;	POP	BX			;			   ;an014;bgb		   ;AN000;
;	XCHG	SI,DI			;			   ;an014;bgb		   ;AN000;
;	CMP	SI,[EOFVAL]		;Reach the end? 	   ;an014;bgb		   ;AN000;
;	JAE	ChainDoneJ	       ;Leave if so		   ;an014;bgb		  ;AN000;
;	CALL	CROSSCHK		;See if crosslink	   ;an014;bgb		   ;AN000;
;	JZ	XA_Cross_Loop		;Go check next cluster if not		;AN000;
;	jmp	CrossLink		;Go handle crosslink	   ;an014;bgb		   ;AN000;
;

;NOCLUSTERSJ: JMP NOCLUSTERS


 CHASELOOP:							   ;an014;bgb
	 PUSH	 BX						   ;an014;bgb
	 CALL	 UNPACK 					   ;an014;bgb
	 POP	 BX						   ;an014;bgb
	 INC	 CX						   ;an014;bgb
	 XCHG	 SI,DI						   ;an014;bgb
	 CMP	 SI,[EOFVAL]					   ;an014;bgb
	 JAE	 CHAINDONE					   ;an014;bgb
	 CMP	 SI,2						   ;an014;bgb
	 JB	 MRKBAD 					   ;an014;bgb
	 CMP	 SI,[MCLUS]					   ;an014;bgb
	 JBE	 MRKOK						   ;an014;bgb
 MRKBAD:					 ;Bad cluster # in chain
	 PUSH	 CX						   ;an014;bgb
	 PUSH	 DI						   ;an014;bgb
	 CALL	 get_thiselERR					   ;an014;bgb
	 MOV	 DX,badchain              ;an014;bgb
	 CALL	 EPrint 					   ;an014;bgb
	 POP	 SI						   ;an014;bgb
	 MOV	 DX,0FFFH			 ;Insert EOF	   ;an014;bgb
	 CMP	 byte [BIGFAT],0   ;an014;bgb
	 JZ	 FAT12_1					   ;an014;bgb
	 MOV	 DX,0FFFFH					   ;an014;bgb
 FAT12_1:							   ;an014;bgb ;an014;bgb ;an014;bgb
	 PUSH	 BX						   ;an014;bgb
	 CALL	 PACK						   ;an014;bgb
	 POP	 BX						   ;an014;bgb
	 POP	 CX						   ;an014;bgb
	 JMP SHORT CHAINDONE					   ;an014;bgb

 MRKOK:
	 CALL	 markmap					   ;an014;bgb
	 JZ	 CHASELOOP					   ;an014;bgb
;Public	CrossLink
CROSSLINK:					;File is cross linked
	INC	byte [ISCROSS]       ;an014;bgb
	CMP	byte [SECONDPASS],FALSE ;		       ;an014;bgb	   ;AC000;
	JZ	CHAINDONE			;Crosslinks only on second pass ;an014;bgb
	mov	[Cross_Clus],si 		;Cluster number    ;an014;bgb
	CALL	get_THISEL					   ;an014;bgb
	Message file_arg			;Print file out    ;an014;bgb		   ;AN000;
	MOV	DX,cross_arg         ;Print message out ;an014;bgb		   ;AC000;
	CALL	PRINTF_CRLF					   ;an014;bgb
;Public	ChainDone
CHAINDONE:
	 TEST	 [BX+DIRENT.DIRATT],ISDIR
	 JNZ	 NOSIZE 			 ;Don't size dirs
	 CMP	 byte [ISCROSS],0
	 JNZ	 NOSIZE 			 ;Don't size cross linked files;an014;bgb
	 CMP	 byte [SECONDPASS],FALSE ;
	 JNZ	 NOSIZE 			 ;Don't size on pass 2  (CX garbage)
	 MOV	 AL,[CSIZE]
	 XOR	 AH,AH
	 MUL	 [SSIZE]
	 PUSH	 AX				 ;Size in bytes of one alloc unit
	 MUL	 CX
	 MOV	 DI,DX				 ;Save allocation size
	 MOV	 SI,AX
	 SUB	 AX,word [BX+DIRENT.DIRESIZ]
	 SBB	 DX,word [BX+DIRENT.DIRESIZ+2]
	 JC	 BADFSIZ			 ;Size to big
	 OR	 DX,DX
	 JNZ	 BADFSIZ			 ;Size to small
	 POP	 DX
	 CMP	 AX,DX
	 JB	 NOSIZE 			 ;Size within one Alloc unit
	 PUSH	 DX				 ;Size too small
; PUBLIC  BadFSiz
 BADFSIZ:
	 POP	 DX
	 PUSH	 CX				 ;Save size of file
	 MOV	 word [BX+DIRENT.DIRESIZ],SI
	 MOV	 word [BX+DIRENT.DIRESIZ+2],DI
	 CALL	 FIXENT2			 ;Fix it
	 CALL	 get_thiselERR
	 MOV	 DX,badclus
	 CALL	 EPrint
	 POP	 CX				 ;Restore size of file
 NOSIZE:
	MOV	SI,BX
	MOV	BX,[SRFCBPT]
	RET

 NOCLUSTERS:
						 ;File is zero length
	 OR	 SI,SI
	 JZ	 CHKSIZ 			 ;Firclus is OK, Check size
	 MOV	 DX,nulnz
 ADJUST:
	 PUSH	 DX
	 CALL	 get_thiselERR
	 POP	 DX
	 CALL	 EPrint
	 XOR	 SI,SI
	 MOV	 [BX+DIRENT.DIRCLUS],SI ;Set it to 0
	 MOV	 word [BX+DIRENT.DIRESIZ],SI ;Set size too
	 MOV	 word [BX+DIRENT.DIRESIZ+2],SI
	 CALL	 FIXENT2			 ;Fix it
	 INC	 byte [ZEROTRUNC] ;Indicate truncation
	 JMP	 CHAINDONE

; PUBLIC  ChkSiz
 CHKSIZ:
	 MOV	 DX,badclus
	 CMP	 word [BX+DIRENT.DIRESIZ],0
	 JNZ	 ADJUST 			 ;Size wrong
	 CMP	 word [BX+DIRENT.DIRESIZ+2],0
	 JNZ	 ADJUST 			 ;Size wrong
	 JMP	 CHAINDONE			 ;Size OK


SUBTTL	Routines for manipulating dir entries
PAGE

FIXENT2:
;Same as FIXENT only [SRFCBPT] points to the search FCB, BX points to the entry
	SaveReg <si,bx,cx>
	MOV	SI,BX
	MOV	BX,[SRFCBPT]
	CALL	FIXENT
	RestoreReg <cx,bx,si>
RET20:	RET

FIXENT:
;BX Points to search FCB
;SI Points to Entry to fix
	MOV	byte [HAVFIX],1 ;Indicate a fix
	CMP	byte [DOFIX],0 ;did the user enter /f flag?
	JZ	fixret			;zero means no - dont fix it
	SaveReg <bp,bx,si,si>
	MOV	AX,[BX+THISENT] 		;Entry number
	CALL	GETENT
	POP	SI				;Entry pointer
	ADD	SI,DIRENT.DIRNAM			;Point to start of entry
	MOV	CX,32
	REP	MOVSB
	INC	CL
	CALL	DOINT26
	RestoreReg <si,bx,bp>
fixret: RET



;*****************************************************************************	;ac048;bgb
; GETENT - calculate, and read into ram, the sector of the directory entry	;ac048;bgb
;	   that is invalid.  This entry can be in either the root directory,	;ac048;bgb
;	   or in a sub-directory.  If it is in the root, it can be in the first ;ac048;bgb
;	   sector of the root dir, or in a subsequent sector.  If it is in a	;ac048;bgb
;	   subdirectory, it can be in the first cluster of the subdir, or in	;ac048;bgb
;	   any subsequent cluster.  It can also be in the first sector of the	;ac048;bgb
;	   cluster, or in any of the following sectors within that cluster.	;ac048;bgb
;										;ac048;bgb
; WARNING!! NOTE!! --> this procedure has a limit on the input value of 64k	;ac048;bgb
;		       entries.  If the disk fails on an entry in a subdir	;ac048;bgb
;		       which has an invalid entry past this value, then the	;ac048;bgb
;		       calling procedure will probably wrap on this word value, ;ac048;bgb
;		       causing getent to calc the wrong sector, and then	;ac048;bgb
;		       corrupting the disk.  Not likely, but poss.		;ac048;bgb
;										;ac048;bgb
; called by - nodot/mesd1	 - no . entry found  (always subdir)		;ac048;bgb
;	    - noddot/mesd2	 - no .. entry found (always subdir)		;ac048;bgb
;	    - askconv/printtrmes - convert dir to file (can be in root) 	;ac048;bgb
;	    - makfillp		 - find root entry in which to place lost clus	;ac048;bgb
;										;ac048;bgb
; inputs - AX - desired entry num (in curr dir, reffed off BP)			;ac048;bgb
;		0=.   1=..   2=first entry					;ac048;bgb
;	   DX - number of lost clusters
;	   BP - ptr to extended fcb for this dir				;ac048;bgb
;	   BP+6 - 1st cluster number of this dir				;ac048;bgb
;										;ac048;bgb
; output - AX - contains number of the disk to use for int26			;ac048;bgb
;	   DI - points to entry in subdir in ram				;ac048;bgb
;	   DX - low sector number of the dir					;ac048;bgb
;	   BX - ram offset of the sector					;ac048;bgb
;	   Read_Write_Relative.Start_Sector_Hi - hi sector number of the dir	;ac048;bgb
;										;ac048;bgb
; Regs abused - all of 'em !! (ok, well, maybe not bp...)                       ;ac048;bgb
;										;ac048;bgb
;logic: 1. make sure there will not be a problem with the cluster number. This	;ac048;bgb
;	   should not be a problem, since if the cluster number is invalid, it	;ac048;bgb
;	   should have been flagged by previous routines.			;ac048;bgb
;										;ac048;bgb
;	2. calc clus-num & offset						;ac048;bgb
;	   Entries * bytes/entry / BPS --> number of sectors from the beg of	;ac048;bgb
;	   the dir.  There are 16 entries per sector (starting at zero).  The	;ac048;bgb
;	   bytes/entry and bytes/sector are condensed, giving a div by 16,	;ac048;bgb
;	   instead of "* 32 / 512".  Now we have the first cluster (0-fff7),	;ac048;bgb
;	   the sector-offset (0-fff), and the entry-offset (0-f).		;ac048;bgb
;										;ac048;bgb
;	   forumla: entry (0-ffff)  /  16 = sector-offset (0-fff)  ax		;ac048;bgb
;					  = entry-offset  (0-f)    dx		;ac048;bgb
;										;ac048;bgb
;      3. if we are in the root directory, then we have the correct sector	;ac048;bgb
;	  number, so just add it to the starting sector number of the		;ac048;bgb
;	  directory.								;ac048;bgb
;										;ac048;bgb
;      4. otherwise, we are in a subdirectory.	Here, we need to get the	;ac048;bgb
;	  cluster-offset, since the sector-offset can be more than 1 cluster	;ac048;bgb
;	  in length.  So, divide the sectors by (secs/clus) to get cluster-	;ac048;bgb
;	  offset.  This value is now a power of 2, from 2 up to 16.		;ac048;bgb
;										;ac048;bgb
;	   / sectors/cluster (2-16)   = cluster offset AL			;ac048;bgb
;				      = sector	offset AH			;ac048;bgb
;										;ac048;bgb
;      5. If AL > 0, then we have to walk the fat chain to find the cluster	;ac048;bgb
;	  where this sector is.  Fortunately, we have the starting cluster	;ac048;bgb
;	  number (BX), UNPACK will find the next cluster number, and we have	;ac048;bgb
;	  the number of clusters to jump (AL).	So, move the appropriate	;ac048;bgb
;	  into the regs, and loop until completed.  Now BX has the correct	;ac048;bgb
;	  cluster number.							;ac048;bgb
;										;ac048;bgb
;      6. Now we need to translate the cluster and sector numbers into an	;ac048;bgb
;	  absolute, double word, sector number.  FIGREC will do this.		;ac048;bgb
;										;ac048;bgb
;      7. Now, from either root dir, or from subdir, we have the absolute	;ac048;bgb
;	  sector, so set up the regs, and call READ_DISK to read it into ram.	;ac048;bgb
;	  Now DX contains the sector number (low), and BX points to the 	;ac048;bgb
;	  sector in ram.							;ac048;bgb
;										;ac048;bgb
;      8. Finally, get the entry-offset that we had stored on the stack, and	;ac048;bgb
;	  translate it into a byte-offset by multpying it times the number of	;ac048;bgb
;	  bytes per entry (32).  Now DI points to the entry in ram.		;ac048;bgb
;*****************************************************************************	;ac048;bgb
GETENT: 									;ac048;bgb
	mov	bx,[bp+6]		;Get 1st cluster of subdir		;ac048;bgb
;double check for invalid cluster						;ac048;bgb
	cmp	bx,[EOFVAL]		;Last entry in cluster? 		;ac048;bgb
;	IF$	NB								;ac048;bgb
	JB IF37$$C
	    mov     bx,baddpbdir            ;This should never happen	;ac048;bgb
	    jmp     FATAL			    ;Danger, warning Phil Robins;ac048;bgbon
;	ENDIF$									;ac048;bgb
IF37$$C:
										;ac048;bgb
CLUSISOK:									;ac048;bgb
;calc cluster number and offset 						;ac048;bgb
	mov	cx,16			;32 bytes/entry  /  512 bytes/sec	;ac048;bgb
	xor	dx,dx			;zero out hi word for divide		;ac048;bgb
	div	cx    ;NOW- bx=first clus, ax=sec-offset, dx=entry-offset	;ac048;bgb
				    ;NOTE: ax can be > 1 cluster		;ac048;bgb
;are we at the root?								;ac048;bgb
	or	bx,bx			;cluster zero?				;ac048;bgb
;	IF$	Z			;yes, then we are in root dir		;ac048;bgb
	JNZ IF39$$C
	    ;;;;;;;;jz	    wantroot		    ;Cluster 0 means root dir	;ac048;bgb
WANTROOT:   push    dx			;restored as di- ptr to invalid entry	;ac048;bgb
	    mov     dx,ax		;get sector offset			;ac048;bgb
	    add     dx,[dirsec] 	;add in first sector of dir		;ac048;bgb
	    mov     [Read_Write_Relative.Start_Sector_High],0 ;save hi value	;ac048;bgb
	    ;;;;;;;;;;;JMP     DOROOTDIR ;now ready for int25			;ac048;bgb
										;ac048;bgb
;	ELSE$		;not in root dir					;ac048;bgb
	JMP SHORT EN39$$C
IF39$$C:
NOTROOT:    div     [CSIZE] ;divide by sectors/cluster (2-16)	;ac048;bgb
			     ;AL=# cluster-offset (QUO), AH= sector-offset (REM);ac048;bgb
	    mov     cl,al		;get cluster offset from al		;ac048;bgb
	    xor     ch,ch		;zero out hi byte to make word value	;ac048;bgb
	    or	    cx,cx    ;do we have more than one cluster worth to go yet? ;ac048;bgb
;	    IF$     NZ	     ;yes - we have to walk the chain to find it	;ac048;bgb
	    JZ IF41$$C
	    ;;;;;;;;JCXZ    GOTCLUS		    ;jump if cx reg = zero	;ac048;bgb
		mov	si,bx		    ;move the cluster num for input	;ac048;bgb
SKIPLP: 	call	UNPACK		    ;find the next cluster number	;ac048;bgb
		xchg	si,di		    ;move it into input position	;ac048;bgb
		loop	SKIPLP		    ;do for number of cluster-offset	;ac048;bgb
		mov	bx,si		    ;now we have the cluster number	;ac048;bgb
;	    ENDIF$								;ac048;bgb
IF41$$C:
										;ac048;bgb
;calculate the sector from the cluster & sec-offset				;ac048;bgb
GOTCLUS:    push    dx		     ;restored as di -> entry offset		;ac048;bgb
	    call    figrec	     ;Convert to sector # - ax=low, dx=hi	;ac048;bgb
;	ENDIF$	;are we in root dir?						;ac048;bgb
EN39$$C:
										;ac048;bgb
DOROOTDIR:									;ac048;bgb
	mov	bx,[SECBUF]		;get offset of ram area 		;ac048;bgb
	mov	al,[ALLDRV]		;get drive number			;ac048;bgb
	dec	al			;adjust for int25			;ac048;bgb
RDRETRY: mov	 cx,1			 ;read 1 sector 			;ac048;bgb
	call	read_disk		;do it					;ac048;bgb
	jnc	RDOK2			;was it good?				;ac048;bgb
;Need to handle 'Fail' option of critical error here				;ac048;bgb
	JZ	RDRETRY 							;ac048;bgb
										;ac048;bgb
RDOK2:	pop	ax			;get byte-offset into sector		;ac048;bgb
	mov	cl,5		    ;value of 32= bytes per entry		;ac048;bgb
	shl	ax,cl		    ;mul entry offset to get byte offset	;ac048;bgb
	add	ax,bx			;add in offset of dir in ram		;ac048;bgb
	mov	di,ax								;ac048;bgb
	mov	al,[ALLDRV]		;get drive number			;ac048;bgb
	dec	al			;adjust for int26			;ac048;bgb
	RET				;di now points to offending entry	;ac048;bgb
;*****************************************************************************	;ac048;bgb




CHECKNOFMES:
	MOV	AL,1
	XCHG	AL,[FIXMFLG]
	OR	AL,AL
	JNZ	ret14				;Don't print it more than once
	CMP	byte [DOFIX],0
	JNZ	ret14				;Don't print it if F switch specified
	mov	dx,fixmes_arg
	CALL	PRINTF_CRLF
	call	DOCRLF				;				;AN000;
ret14:	RET

CHECKERR:
	CALL	CHECKNOFMES
	CMP	byte [SECONDPASS],FALSE ;				;AC000;
	RET

get_currdirERR:
	CALL	CHECKERR
	jz	ok_pri_dir
	mov	byte [ARG_BUF],0
	ret
ok_pri_dir:
	CALL	get_currdir
	ret

get_thiselERR:
	CALL	CHECKERR
	jz	ok_pri_el
	mov	byte [ARG_BUF],0
ok_pri_el:
	CALL	get_THISEL
	RET

get_THISEL:
	MOV	SI,BX
	ADD	SI,DIRENT.DIRNAM
;*****************************************************************************
; called by: checkfiles
; inputs:	AX - number of fragments
;		SI
;*****************************************************************************
get_THISEL2:
	MOV	DI,NAMBUF
	PUSH	DI
	CALL	FCB_TO_ASCZ
	POP	SI
get_currdir:
	PUSH	SI
; get drive letter prefix (c:\)
	mov	di,ARG_BUF
	MOV	al,[ALLDRV]
	ADD	al,'@'
	stosb
	MOV	al,DRVCHAR
	stosb
	mov	al,[DIRCHAR]
	stosb
	MOV	SI,DI
; get the name of the current directory, and put it into es:di
	MOV	DL,[ALLDRV]
	DOS_Call Current_Dir			;				;AC000;
GET_END:
;find the end of the string - it will be hex zero
	LODSB
	OR	AL,AL
	JNZ	GET_END
;
	DEC	SI				; Point at NUL
	MOV	DI,SI
	POP	SI			;point to begin of string
	CMP	byte [SI],0
	JZ	LPDONE				;If tail string NUL, no '/'
; move '\' for between path and filename
	MOV	al,[DIRCHAR]
	CMP	byte [DI - 1],AL
	JZ	ERRLOOP 			; Don't double '/' if root
	stosb
ERRLOOP:
; move filename from ds:si to es:di until find hex zero
	LODSB
	OR	AL,AL
	JZ	LPDONE
	stosb
	JMP	ERRLOOP
LPDONE:
; finish off string with hex zero for asciiz
	mov	al,0
	stosb
	RET

CHECK_SPLICE:
; Carry set if current directory is NOT spliced (joined) onto.
; Carry clear if current directory is spliced (joined) onto.

	MOV	SI,NUL
	CALL	get_currdir			; Build ASCIZ text of current dir
						;  at arg_buf
	mov	si,ARG_BUF
	mov	di,TMP_SPC
	DOS_Call xNameTrans			;				;AC000;
	JC	NT_SPLC 			; Say NOT spliced if error
	CMP	word [TMP_SPC+1],"\" SHL 8 OR ":"
	JNZ	NT_SPLC
	CMP	byte [TMP_SPC+3],0
	JNZ	NT_SPLC
	MOV	AL,byte [ARG_BUF]      ; Source drive letter
	CMP	AL,byte [TMP_SPC]      ; Different from dest if spliced
	JZ	NT_SPLC 			; Drive letter didn't change
	CLC
	RET

NT_SPLC:
	STC
	RET


;*****************************************************************************
;Routine name: MarkFAT
;*****************************************************************************
;
;Description: Trace the fat chain for a single file, marking entries in FATMap,
;	      and handling errors -
;	      (crosslink, truncation, allocation error, invalid cluster entry)
;
; called by :	moredir
;		newdir
;
;Called Procedures: Unpack
;		    Bad_Cluster
;		    MarkMap
;		    Check_Chain_Sizes
;		    ThisEl
;		    Eprint
;
;Change History: Created	5/10/87 	MT
;
;Input: BX = pointer to search FCB
;	AL is head mark with app type =81h
;	SI = points to dir entry
;	DI = cluster entry of file or XA in directory
;	File_Size_Low/High = bytes length directory or XA structure says
;				the data area is
;	SecondPass = TRUE/FALSE
;	XA_Pass = TRUE/FALSE
;	EOFVal = 0FF8h/0FFF8h
;
;Output:
;	 ZEROTRUNC is non zero if the file was trimmed to zero length
;	 ISCROSS is non zero if the file is cross linked
;	 BX,SI preserved
;	 Cluster_Count = number of clusters in chain
;	 carry flag is set if the clusters are ok
;	 fatmap entries - 81h = head of file,
;			  01h = used cluster
;
;Psuedocode
;----------
;
;	ZeroTrunc,IsCross = FALSE, SRFCBPT = BX, Cluster_Count = 0
;	Get file cluster entry (CALL Unpack)
;	IF cluster < 2 or > maximum cluster (MClus)
;	   Go handle invalid cluster (CALL Bad_Cluster)
;	ELSE
;	   SEARCH
;	      Go mark cluster in FATMap (CALL MarkMAP)
;	      Turn off head bit on FATMap marker
;	   EXITIF Crosslink
;	      IsCross = TRUE
;	      IF SecondPass = FALSE
;		 Setup filename for message (CALL ThisEl)
;		 Display crosslink message (Call Eprint)
;	      ENDIF
;	   ORELSE (no crosslink)
;	      Get next cluster (CALL Unpack)
;	      IF Cluster >= EOFVAL [(0/F)FF8h]
;		 Verify file sizes (CALL Check_Chain_Sizes)
;		 clc  (Force loop to end)
;	      ELSE
;		 IF cluster < 2 or > maximum cluster (MClus)
;		    Go handle invalid cluster (CALL Bad_Cluster)
;		    clc  (Force loop to end)
;		 ELSE
;		     stc  (Force loop to keep goining
;		 ENDIF
;	      ENDIF
;	   ENDLOOP clc
;	   ENDSRCH
;	ENDIF
;	ret
;*****************************************************************************
Procedure MarkFAT				;			       ;AN000;
	push	si				;AN000;
	push	bx				;AN000;
	mov	[Head_Mark],al ;Save flag to put in map	;AN000;
	mov	byte [ZEROTRUNC],FALSE ;Init values			;     ;
	mov	byte [ISCROSS],FALSE ;				;     ;
	mov	word [Cluster_Count],0 ;Init count of clusters 	;     ;
	mov	[SRFCBPT],bx ;Pointer to search FCB		;     ;
	mov	[First_Cluster],di ;				;AN000;
	mov	[Previous_Cluster],di ;Init pointer
	cmp	di,2				;Cluster < 2?			;AC000;
;	IF$	B,OR				;    or 			;AC000;
	JB LL44$$C
	cmp	di,[MCLUS] ;Cluster > total clusters?	;AC000;
;	IF$	A				;				;AC000;
	JNA IF44$$C
LL44$$C:
	    cmp word [si+DIRENT+DIRENT.DIRCLUS],0 ;if both cluster and size = 0,		;an025;bgb
;	    IF$ NE,OR			;then its not an error, 		;an025;bgb
	    JNE LL45$$C
	    cmp word [si+DIRENT+DIRENT.DIRESIZ],0 ;and dont print msg			;an025;bgb
;	    IF$ NE								;an025;bgb
	    JE IF45$$C
LL45$$C:
		call	Bad_Cluster		     ;Yes, go indicate bad stuff     ;AN000;
;	    ENDIF$
IF45$$C:
;	ELSE$					;Cluster in valid range 	;AN000;
	JMP SHORT EN44$$C
IF44$$C:
;	   SEARCH$				;Chase the cluster chain	;AN000;
DO48$$C:
	      mov     al,[Head_Mark] ;Get flag for map 01		;AC000;
	      call    markmap			;Mark the cluster (SI)		;AC000;
	      push    ax			;Save head mark 		;AN000;
	      lahf				;Save CY status
	      and     byte [Head_Mark],Head_Mask ;Turn off head bit of map flag	;AC000;
	      sahf				;Get CY flags back
	      pop     ax			;Get haed mark back		;AN000;
;	   EXITIF$ C				;Quit if crosslink		;AC000;
	   JNC IF48$$C
	      mov     byte [ISCROSS],TRUE ;Set crosslink flag		;AC000;
	      cmp     byte [SECONDPASS],TRUE ;Handle crosslink 2nd pass only ;AC000;
;	      IF$     E 			;This is first pass		;AC000;
	      JNE IF50$$C
		 mov	 [Cross_Clus],di ;Put cluster in message 	;AN000;
		 push	 bx			;Get dir pointer into bx	;AN000;
		 push	 si			;				;AN000;
		 mov	 bx,si			; for the call			;AN000;
		 call	 get_thiselERR		;				;AC000;
		 mov	 dx,cross_arg        ;Specify error message		;AC000;
		 call	 EPrint 		;Go print file and error	;AC000;
		 pop	 si			;				;AN000;
		 pop	 bx			;				;AN000;
		 Message cross_arg		;				;AC000;
;	      ENDIF$				;				;AN000;
IF50$$C:
;	   ORELSE$				;No crosslink found		;AN000;
	   JMP SHORT SR48$$C
IF48$$C:
	      push    si			;Save dir pointer
	      mov     si,di			;Provide current cluster
	      mov     [Previous_Cluster],di ;Save current cluster
	      call    UNPACK			;Get next cluster entry (di)	;AC000;
	      inc     word [Cluster_Count] ;Got a cluster			;AN000;
	      pop     si			;Get dir pointer back
	      cmp     di,[EOFVAL] ;Is it the last clus in file?	;AC000;
;	      IF$     AE			;Yes - good chain so far	;AN000;
	      JNAE IF53$$C
		 call	 Check_Chain_Sizes	;Go verify file sizes		;AN000;
		 clc				;Clear CY to force exit 	;AN000;
;	      ELSE$				;Not end of chain
	      JMP SHORT EN53$$C
IF53$$C:
		 cmp	 di,2			;Cluster < 2?			;AC000;
;		 IF$	 B,OR			;    or 			;AC000;
		 JB LL55$$C
		 cmp	 di,[MCLUS] ;Cluster > total clusters?	;AC000;
;		 IF$	 A			;Yep				;AN000;
		 JNA IF55$$C
LL55$$C:
		    call    Bad_Cluster 	;Yes, go indicate bad stuff	;AN000;
		    clc 			;Clear CY to force loop exit	;AN000;
;		 ELSE$				;No, more clusters to go	;AN000;
		 JMP SHORT EN55$$C
IF55$$C:
		    stc 			;Set CY to keep going		;AN000;
;		 ENDIF$ 			;				;AN000;
EN55$$C:
;	      ENDIF$				;
EN53$$C:
;	   ENDLOOP$ NC				;Exit if done with chain	;AN000;
	   JC DO48$$C
;	   ENDSRCH$				;End of chain chase loop       ;AN000;
SR48$$C:
;	ENDIF$					;
EN44$$C:
	pop	bx				;Restore registers		;AN000;
	pop	si				;				;AN000;
	ret					;				;AN000;
;MarkFAT endp					;				;AN000;

;*****************************************************************************
;Routine name: Bad_Cluster
;*****************************************************************************
;
;description: IF first cluster =0, truncate file or XA to zero length.
;	      If bad cluster elsewhere, put in EOFVal.
;
;Called Procedures: Get_ThisElErr
;		    Eprint
;		       FixENT2
;
;Change History: Created	5/10/87 	MT
;
;Input: First_Cluster
;	   Chain_End
;	   XA_PASS = TRUE/FALSE
;	   DI = Cluster entry
;	   SI = dir block pointer
;	   First_Cluster = first cluster or extended XA
;	   Previous_Cluster = last good cluster number
;
;Output: ZeroTrunc = TRUE/FALSE
;
;Psuedocode
;----------
;
;	Setup filename for any messages (Call Get_ThisELErr)
;	IF cluster = First_Cluster
;	   IF XA_PASS = FALSE
;		 Zero out file length in DIR
;		 Setup message (CALL Get_ThisElErr)
;		 Display message (Call Eprint)
;	   ELSE (XA pass)
;	      Zero out XA pointer
;	      Setup message (CALL Get_ThisElErr)
;	      Display message (Call Eprint)
;	   ENDIF
;	   Write out corrected directory (CALL FixENT2)
;	ELSE (cluster other than first in chain)
;	   IF XA_Pass = TRUE
;	     Display Bad XA cluster message
;	   ELSE (!XA_Pass)
;	     Display bad file chain message
;	   ENDIF
;	   Move EOF into bad cluster (CALL PACK - Chain_End)
;	ENDIF
;	ret
;*****************************************************************************
Procedure Bad_Cluster				;				;AN000;
	SaveReg <si,di,dx,si,di,bx>		;Preserve registers		;AN000;
	mov	bx,si				; for the call			;AN000;
	call	get_thiselERR			;Setup message			;AC000;
	RestoreReg <bx,di,si>
	cmp	di,[First_Cluster] ;does 1st clus point to itself? 	;Need to change the directory	;AC000;
;	IF$	E,OR			;yes					; pointer if the dir cluster or ;AC000;
	JE LL62$$C
	push	di			;if not, try this next test		; XA is bad, or the last good	;AN000;
	mov	di,[Previous_Cluster] ;get prev cluster			; entry was the dir cluster or	;AN000;
	cmp	di,[First_Cluster] ;does prev clus = 1st clus?		; XA cluster.			;AN000;
	pop	di			;means the 1st cluster is bad
;	IF$	E			;yes	       ;			       ;AN000;
	JNE IF62$$C
LL62$$C:
	    cmp word [si+DIRENT+DIRENT.DIRCLUS],0 ;is cluster num already 0?		;an025;bgb
;	    IF$ NE			;no, its bad				;an025;bgb
	    JE IF63$$C
		mov	dx,nulnz          ;1st cluster number is invalid;an025;bgb
		call	EPrint			  ;Go print file and error	;an025;bgb
		mov	word [si+DIRENT+DIRENT.DIRCLUS],0 ;set cluster number to 0	;an025;bgb
		mov	byte [ZEROTRUNC],TRUE ;modified the file size 		;an026;bgb
;	    ENDIF$			;already set to 0, dont print err msg	;an025;bgb
IF63$$C:
	    mov     word [si+DIRENT+DIRENT.DIRESIZ],0 ;set file size to 0	      ;Kill the file size	      ;AC000;
	    mov     word [si+DIRENT+DIRENT.DIRESIZ+2],0 ;Kill the file size	    ;AC000;0;
	    mov  bx,si				 ;Get pointer to directory	 ;AN000;
	    call    FIXENT2			 ;Write out updated directory	 ;AC000;
;	ELSE$					;Not first cluster in chain	;AN000;
	JMP SHORT EN62$$C
IF62$$C:
	      mov     dx,badchain        ;Tell user file and error	;AN000;
	      call    EPrint							;AN000;
	   mov	   dx,[CHAIN_END] ;Terminate chain at bad spot	;AC000;
	   mov	   si,[Previous_Cluster] ;Change the last good cluster	;AC000;
	   call    PACK 			;Go fix it			;AC000;
;	ENDIF$					;				;AN000;
EN62$$C:
	RestoreReg <dx,di,si>
	ret					;
;Bad_Cluster endp				;				;AN000;

;*****************************************************************************
;Routine name: Check_Chain_Sizes
;*****************************************************************************
;
;description: See if length of chain as listed in dir or XA matches up
;	      with the number of clusters allocated. Don't check if crosslink
;	      error, or chasing directory chain.
;
;Called Procedures: FixEnt
;		    Bad_Chain_Size
;
;
;Change History: Created	5/10/87 	MT
;
;Input: CSIZE = sectors per cluster
;	SSIZE = bytes per sector
;	Cluster_Count = number of clusters in chain
;	File_Size_Low/High = bytes dir or XA says is in chain
;	SI = Pointer to Dir entry
;
;Output: Cluster_Count = Size of chain in clusters
;	 SI = Pointer to dir entry
;	 BX = SRFCBPT
;
;Psuedocode
;----------
;
;	IF !Directory attribute,AND
;	IF !Crosslinked (ISCROSS = FALSE),AND
;	IF !Second pass (SecondPass = FALSE)
;	   Compute bytes/cluster
;	   Compute bytes/chain
;	   IF size > File_Size_High/Low
;	      Fix the size (CALL Bad_Chain_Size)
;	      ELSE
;		 Subtract file size from chain length
;		 IF Difference in Chain_Length and Size >= bytes/cluster
;		    Fix the size (CALL Bad_Chain_Size)
;		 ENDIF
;	      ENDIF
;	   ENDIF
;	ENDIF
;	CX = Cluster_Count  (kept for compatibility with old code)
;	BX = SRFCPT (kept for compatibility with old code)
;	ret
;*****************************************************************************
Procedure Check_Chain_Sizes			;AN000;
	push	si				;				;AN000;
	push	ax				;				;AN000;
	test	[si+DIRENT+DIRENT.DIRATT],Dir_Attribute ;Is this a directory?		;AC000;
;	IF$	Z,AND				;No				;AC000;
	JNZ IF67$$C
	cmp	byte [ISCROSS],FALSE ; and,is it crosslinked?	;AC000;
;	IF$	E,AND				;No				;AC000;
	JNE IF67$$C
	cmp	byte [SECONDPASS],FALSE ;and, is this the first pass?	;AC000;
;	IF$	E				;Yes,				;AC000;
	JNE IF67$$C
	   xor	   ax,ax			;AX =0				;AC000;
	   mov	   ax,[SSIZE] ;Get (bytes/sector) *		;AC000;
	   mov	   cl,[CSIZE] ; (Sectors/cluster)		;AC000;
	   mul	   cx				;AX=Bytes/cluster  (< 64k)	;AC000;
	   mov	   [BClus],ax ;Save Bytes/cluster		 ;AN000;
	   mov	   cx,[Cluster_Count] ;Number of clusters in chain	;AC000;
	   mul	   cx				;DX:AX = bytes/chain		;AC000;
	   mov	   [Chain_Size_Low],ax ;Save allocation size in bytes	;AN000;
	   mov	   [Chain_Size_High],dx ;				;AN000;
	   cmp	   dx,[File_Size_High] ;See if file size if greater	;AN000;
;	   IF$	   E,AND			; than chain length - if	;AN000;
	   JNE IF68$$C
	   cmp	   ax,[File_Size_Low] ; so, than there is an		;AC000;
;	   IF$	   B				; allocation error.		;AC000;
	   JNB IF68$$C
	      call    Bad_Chain_Size		;Fix it!			;AC013;bgb
;	   ELSE$				;Chain larger than file 	;AC000;
	   JMP SHORT EN68$$C
IF68$$C:
	      cmp     dx,[File_Size_High] ;See if high part lower 	;AN000;
;	      IF$     B 			;Chain < filsize if so		;AN000;
	      JNB IF70$$C
		 call	 Bad_Chain_Size 	;Fix it!			;AC013;bgb
;	      ELSE$				;Chain > filesize		;AN000;
	      JMP SHORT EN70$$C
IF70$$C:
		 mov	 cx,[File_Size_Low] ;See if within 1 cluster	;AN000;
		 mov	 bx,[File_Size_High] ;				;AN000;
		 sub	 ax,cx			;Subtract file size from	;AC000;
		 sbb	 dx,bx			; the chain size		;AN000;
		 cmp	 dx,0			;See if within 1 cluster	;AN000;
;		 IF$	 NE,OR			;Not if high size set,or	;AN000;
		 JNE LL72$$C
		 cmp	 ax,[BClus] ;Within (bytes/cluster -1)?	;AC000;
;		 IF$	 AE			;Nope, allocation error 	;AC000;
		 JNAE IF72$$C
LL72$$C:
		    call    Bad_Chain_Size	;Go fix the chain		;AN013;bgb
;		 ENDIF$ 			;				;AN000;
IF72$$C:
;	      ENDIF$				;				;AN000;
EN70$$C:
;	   ENDIF$				;				;AN000;
EN68$$C:
;	ENDIF$					;				;AN000;
IF67$$C:
	mov	bx,[SRFCBPT] ; Needed for compat		;AC000;
	pop	ax				;Restore used regs		;AN000;
	pop	si				;SI = Dir pointer		;AN000;
	ret					;				;     ;
;check_chain_sizes endp				;				;AN000;



Procedure print_filename			;AN000;
	    PUSH    BX
	    MOV     BX,SI
	    CALL    get_THISEL
	    mov     dx,noisy_arg
	    call    PRINTF_CRLF
	    MOV     SI,BX
	    POP     BX
	    return
;print_filename	  endp				;				;AN000;

;these procedures were for the extended attribute support, which was removed	;an006;bgb

;*****************************************************************************
;Routine name: Bad_Chain_Size
;*****************************************************************************
;
;Description: adjust
;	      filesize to allocation length.
;
;Called Procedures: Truncate_XA
;		    FixEnt2
;		    Get_ThisElErr
;		    Eprint
;
;Change History: Created	5/11/87 	MT
;
;Input: XA_Pass = TRUE/FALSE
;	Chain_Size_High/Low
;	SI = Dir pointer
;	Chain_Size_Low/High = length in bytes of allocation chain
;
;Output: None
;
;Psuedocode
;----------
;
;	IF XA_Pass
;	   Delete XA chain (CALL Truncate_XA)
;	ELSE
;	   Set directory entry to length = Total allocation size
;	   Go write out (CALL FixEnt2)
;	   Setup message (CALL Get_Thiselerr)
;	   Display it (Call Eprint)
;	ENDIF
;	ret
;*****************************************************************************
Procedure Bad_Chain_Size			;				;AN000;
	push	es
	push	ax				;Save register			;AN000;

	push	ds		 ;make es point to DG_
	pop	es
;;;;;; cmp     XA_Pass,True		       ;Are we handling XA's?          ;AN013;bgb
;;;;;;;;IF$	E				;Yes				;AN013;bgb
;;;;;;;;;;;call    Truncate_XA			;Go truncate the chain		;AN013;bgb
;;;;;;;;ELSE$					;Normal file chain		;AN013;bgb
	   mov	   ax,[Chain_Size_Low] ;Get length of allocation	;AN000;
	   mov	   dx,[Chain_Size_High] ; chain for filesize		;AN000;
	   mov	   word [si+DIRENT+DIRENT.DIRESIZ],ax ;Put it in the directory	;AC000;
	   mov	   word [si+2+DIRENT.DIRESIZ],dx ;   "  "       "  "		;AC000;
	   push    bx				;				;AN000;
	   push    si				;				;AN000;
	   mov	   bx,si			;Get pointer to directory	;AN000;
	   call    FIXENT2			;Write dir to disk		;AC000;
	   call    get_thiselERR		;Setup message			;AC000;
	   mov	   dx,badclus         ;Specify error message		;AC000;
	   call    EPrint			;Go print file and error	;AC000;
	   pop	   si				;				;AN000;
	   pop	   bx				;				;AN000;
;;;;;;;;ENDIF$					;				;AN013;bgb
	pop	ax				;Restore registers		;AN000;
	pop	es
	ret					;

;Bad_Chain_Size endp				;				;AN000;

;*****************************************************************************
;Routine name: Truncate_XA
;*****************************************************************************
;
;Description: If /F entered, than truncate XA chain and remove pointer.
;	      If XA allocation error, than deallocate all of XA chain.
;
;Called Procedures: Get_ThisElErr
;		    Eprint
;		    MarkMap
;		    Unpack
;		    Pack
;
;Change History: Created	5/11/87 	MT
;
;Input: First_Cluster
;	   Chain_End
;	   SI = directory entry pointer
;
;
;Output: FATMap entries for XA chain zero'd out
;
;Psuedocode
;----------
;
;	Set XA pointer in dir to 0
;	Write it out (CALL FixEnt2)
;	Setup message (Call get_ThisElErr
;	Display message (Call Eprint)
;	Get first cluster number (First_Cluster)
;	DO
;	   Get first cluster entry (Call Unpack)
;	   Go mark cluster in FATMap with "Open" (CALL MarkMAP)
;	   Set cluster entry with 0000 (Call Pack)
;	ENDDO cluster value >= EOFVal
;	ret
;*****************************************************************************

;rocedure Truncate_XA				;				;AN000;
;
;	push	si			     ;Save dir pointer			;AN000;
;	push	bx			     ;					;AN000;
;	push	si			     ;					;AN000;
;	mov	bx,si			     ;Get directory pointer		;AN000;
;	call	Get_ThisEl		     ;Setup message			;AN000;
;	mov	dx,offset Alloc_XA_Msg    ;Specify error message		;AC000;
;	call	EPrint			     ;Go print file and error		;AC000;
;	pop	si			     ;					;AN000;
;	mov	word ptr [si].DIR_XA,No_Ext_Attrib ;Erase XA pointer		;AN000;
;	call	FixENT2 		     ;Write dir entry out		;AN000;
;	pop	bx			     ;					;AN000;
;	mov	si,First_Cluster	     ;Get first cluster 		;AN000;
;	DO$				     ;Chase and erase XA chain		;AN000;
;	   call    Unpack		     ;Get next cluster			;AN000;
;	   push    di			     ;Save it- DI next, SI current	;AN000;
;	   mov	   al,No_Entry		     ;Free entry in map 		;AN000;
;	   call    MarkMap		     ; "  "    "  "			;AN000;
;	   mov	   dx,No_Entry		     ;Free up cluster in Fat		;AN000;
;	   call    Pack 		     ; "  "    "  "			;AN000;
;	   pop	   si			     ;Get back next cluster		;AN000;
;	   cmp	   si,[EOFVal]		     ;Reached end of chain?		;AN000;
;	ENDDO$	   AE			     ;Keep looping if not		;AN000;
;	pop	si			     ;Restore Dir pointer		;AN000;
;	ret				     ;					;AN000;
;
;runcate_XA endp			     ;					;AN000;

;*****************************************************************************
;Routine name: Check_Extended_Attributes
;*****************************************************************************
;
;Description: Get the first cluster of XA chain, if it is zero, than erase
;	      extended attribute pointer (/F only). Otherwise, map the
;	      cluster in the FATMAP. If crosslink found on first cluster,
;	      no more processing is done. If value other than EOF mark
;	      found in first cluster
;
;Called Procedures: Load_XA
;		    Fix_Bad_XA
;		    Check_XA_Structure
;		    MarkFAT
;
;Change History: Created	5/10/87 	MT
;
;Input: SI = pointer to directory entry
;
;Output: FATMap marked with XA_Cluster for each XA cluster found
;	    XA_PASS = NO
;
;Psuedocode
;----------
;
;	IF (XA exists for file)
;	   XA_PASS = YES
;	   DI = XA entry cluster in dir
;	   Load in first sector of XA (CALL Load_XA)
;	   IF !error
;	      File_Size_Low/High = length of XA's in bytes
;	      AL = chain head mark (XA_Chain)
;	      Trace chain and map it (CALL MarkFAT)
;	   ELSE
;	      call Bad_Cluster
;	   ENDIF
;	ENDIF
;	ret
;*****************************************************************************

;rocedure Check_Extended_Attributes		;				;AN000;
;
;	push	ax				;Save register			;AN000;
;	push	cx				;				;AN000;
;	push	dx				;				;AN000;
;	push	di				;				;AN000;
;	mov	ax,[si].DIR_XA			;Get first cluster of XA's      ;AN000;
;	cmp	ax,No_Ext_Attrib		;Are there extended attrib's    ;AN000;
;	IF$	NE				;Quit if no			;AN000;
;	   mov	   di,ax			;Pointer to current cluster	;AN000;
;	   mov	   First_Cluster,di		;Remember first cluster 	;AN000;
;	   mov	   XA_Pass,Yes			;Indicate processing XA's       ;AN000;
;	   call    Load_XA			;Go load sector 		;AN000;
;	   IF$	   NC				;CY means load error		;AN000;
;	      mov     ax,XA_Buffer.XAL_TSIZE	;Get bytes in XA chain		;AN000;
;	      mov     File_Size_High,0		;Save it			;AN000;
;	      mov     File_Size_Low,ax		;				;AN000;
;	      mov     al,XA_Chain		;Set up mark for map		;AN000;
;	      call    MarkFAT			;Go map out chain		;AN000;
;	   ELSE$				;Error on read of XA		;AN000;
;	      call    Bad_Cluster		;Delete extended attribs	;AN000;
;;	   ENDIF$				;				;AN000;
;	ENDIF$
;	pop	di				;Restore registers
;	pop	dx				;				;AN000;
;	pop	cx				;				;AN000;
;	pop	ax				;				;AN000;
;	ret					;				;AN000;
;
;heck_Extended_Attributes endp			;				;AN000;


;*****************************************************************************
;Routine name: Load_XA
;*****************************************************************************
;
;description: Read in the first XA cluster
;
;Called Procedures: Read_Disk
;
;
;Change History: Created	5/13/87 	MT
;
;Input: AX has start cluster of XA chain
;	SI = dir pointer
;Output: CY if read failed
;
;Psuedocode
;----------
;
;	Get start of data area
;	Get start cluster
;	Compute XA location from starting cluster
;	Read it in (CALL Read_Disk)
;	IF error
;	   stc
;	ENDIF  (NC if didn't take IF)
;	ret
;*****************************************************************************

;rocedure Load_XA				;				;AN000;
;
;	push	si				;Save used registers		;AN000;
;	push	cx				;				;AN000;
;	push	dx				;				;AN000;
;	push	bx				;				;AN000;
;	sub	ax,2				;Make cluster 0 based		;AN000;
;	mov	cl,CSize			;Get sectors/cluster		;AN000;
;	mul	cl				;Offset sec in data area	;AN000;
;	add	ax,Data_Start_Low		;Get actual sector in partition ;AN000;
;	adc	dx,Data_Start_High		;   "  "    "  "		;AN000;
;	mov	Read_Write_Relative.Start_Sector_High,dx ;Setup high sector addr;AN000;
;	mov	bx,offset XA_Buffer		;Read into buffer		;AN000;
;	mov	cx,1				;Get just first sector		;AN000;
;	mov	dx,ax				;Get logical sector low 	;AN000;
;	mov	al,AllDrv			;Get drive number 1=A,2=B	;AN000;
;	dec	al				;Make 0 based drive 0=A 	;AN000;
;	call	Read_Disk			;Read in sector 		;AN000;
;	IF$	C				;Problem?			;AN000;
;	   stc					;				;AN000;
;	ENDIF$					;				;AN000;
;	pop	bx				;Restore registers		;AN000;
;	pop	dx				;				;AN000;
;	pop	cx				;				;AN000;
;	pop	si				;				;AN000;
;	ret					;				;AN000;
;
;oad_XA endp					;				;AN000;

;****************************************************************************
;WARNING!!! this must be the last label in the code section
;	    any changes to chkdsk.arf must take into account this area.
;	    it is used for reading things from disk into memory, such as dir
;Public	CHKPRMT_End
label Chkprmt_End byte
;****************************************************************************
	pathlabl chkproc
end if
;	END
