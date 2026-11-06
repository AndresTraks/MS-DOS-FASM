 TITLE	 CHKDSK - MS-DOS Disk consistancy checker ;
page	,132					;

	.xlist
	include 'CHKSEG.INC'     ;an005;bgb
	include 'CHKCHNG.INC'
	include 'DOSSYM.INC'
	include 'SYSCALL.INC'     ;an041;bgb
	include 'IOCTL.INC'     ;an041;bgb;an041;bgb
	include 'CHKEQU.INC'
	include 'CHKMACRO.INC'
	include 'CHKDATA.INC'     ;an005;bgb
	include 'PATHMAC.INC'

if SEGSEL = S_CODE
;ASSUME	CS:DG_,DS:NOTHING,ES:DG_,SS:DG_
; EXTRN	INT_23:NEAR,   readft:near	    ;an005;bgb
; EXTRN	FATAL:NEAR, PROMPTYN:NEAR, GET_CURRDIR:NEAR
; extrn	calc_fatmap_seg:near, FINDCHAIN:NEAR, CHECKERR:NEAR, DIRPROC:NEAR
; extrn	CHKMAP:NEAR, Main_Init:Near					     ;an049;bgb
; EXTRN	CHKCROSS:NEAR, AMDONE:NEAR, UNPACK:NEAR, GET_THISEL2:NEAR
; EXTRN	PRINTF_CRLF:NEAR, DOCRLF:NEAR, REPORT:NEAR
; extrn	init_fatmap:near, CHKPRMT_END:near					;an005;bgb
; extrn	hook_interrupts:near
; extrn	CHECK_DBCS_CHARACTER:NEAR						;an055;bgb

;public SETSTACK, OkDrive, DRVISOK, Root_CD_Ok, NOTVOLID, fat16b, SMALLFAT
;public BAD_STACK, RDLOOP, NORETRY1, RDOK, IDOK, ALLDONE, CHECKFILES, GotPath
;public IS_ROOT_DIR, NOT_ROOT_DIR, VALID_PATH, ParseName, ScanFile, FRAGCHK
;public EACHCLUS, LASTCLUS, NXTCHK, GETNXT, MSGCHK, FILSPOK, CDONE, CDONE1
;public PRINTID, FIGREC, Main_Routine, checkit
	.list


	pathlabl chkdsk1
CHKDSK:
; find out if we have enough memory to do the job
    mov     [cs:save_drive],al ;save drive validity
;;;;int     12h 			;1k blocks (640k = 280h)		;an054;bgb;an050;bgb
;;;;mov     bx,64			;number of paragraphs			;an054;bgb;an050;bgb
;;;;mul     bx				;640k = a000				;an054;bgb;an050;bgb
;;;;mov     cs:[mem_size],ax		    ;returns number of 1k blocks	;an054;bgb;an050;bgb
    DOS_Call GetCurrentPSP		    ;Get PSP segment address		;Ac034;bgb
    mov     [cs:PSP_Segment],bx        ;ac034;bgb
    mov     ds,bx			    ;ds points to the psp		;Ac034;bgb
;    Assume  DS:Nothing
    MOV     DX,[ds:2]			    ;High break
    mov     [cs:mem_size],dx		    ;move it into data area		;an054;bgb
    MOV     BX,0FFFFH			    ;need at least 64k bytes
    MOV     CX,CS	    ;get segment of where we are
    SUB     DX,CX	    ;top-of-mem  -  pgm  =  # para left in alloc block
    CMP     DX,0FFFH	    ; is the space available > 64K ?
;   IF$     B
    JNB IF1$$1
	MOV	CX,4		; Yes, set SP to BX (FFF0)
	SHL	DX,CL		; Convert remaining memory to bytes
	MOV	BX,DX
;   ENDIF$
IF1$$1:
SETSTACK:	       ;***Set_Memory*********
    CLI
    PUSH    CS
    POP     SS
;ASSUME	SS:DG_
    MOV     SP,BX
    STI
    PUSH    AX
    JMP     Main_Init			    ;Go to init routines


;**************************************************************************
; MAIN-ROUTINE
;
; called by - main-init
;
; LOGIC
; *****
;	- get the dpb addr
;	- set the default drive to here
;	- save the directory we are on
;	- set the directory to the root of the drive
;	- print the volume name
;	- get the dpb info
;	- get the addr of the fatmap area
;	- calculate the amount of stack space we have
;**************************************************************************
Main_Routine:
    Set_Data_Segment
OkDrive:
;get the dpb addr  from this drive
    mov      dl,[ss:ALLDRV]   ;Get drive number		     ;AN000;
    DOS_Call Get_DPB		 ;func 32    ;Get DPB pointer		     ;AC000;
;    ASSUME  DS:NOTHING,cs:DG_
    CMP     AL,-1			   ;is this a good drive?
;   IF$  Z
    JNZ IF3$$1
;;;;;;;;JNZ	DRVISOK 		   ;Bad drive (should always be ok)
	LEA	DX,[baddrv_arg]   ;This should never happen		;AC000;
	push	cs
	pop	ds
	call	PRINTF_CRLF		       ;			       ;AC000;
	mov	byte [ss:ExitStatus],Bad_Exit ;Get return code			;AC000;
	ret					;Go back to Main_Init		;AC000;
;   ENDIF$
IF3$$1:
    MOV     word [cs:THISDPB+2],DS         ;get the dpb segment
    Set_Data_Segment			    ;reset ds to the pgm
    MOV     word [ss:THISDPB],BX      ;get the dpb offset

;**Set_Drive_Info*************************************************************
DRVISOK:
    push    dx
    push    es
    call    Hook_Interrupts
    pop     es
    pop     dx
; make this drive the default drive
    DEC     DL				    ;A=0 b=1 c=2
    DOS_Call	    Set_Default_Drive	    ;func 0e - no return	       ;AC000;

;get the name of the current directory
    INC     DL				    ;drive number a=1 b=2 c=3
    LEA     SI,[ss:USERDIR+1] ;				    ;AC000;
    DOS_Call	    Current_Dir 	    ;				    ;AC000;
;;;;PUSH    CS
;;;;POP     ES

;change the current directory to the root
    lea     DX,[ROOTSTR] ;					;an005;bgb
    DOS_Call	    CHDir		    ;				    ;AC000;
;   IF$     C				;will this ever happen?
    JNC IF5$$1
;;;;;;;;jnc	Root_CD_Ok			;				;AN000;
	MOV	DX,badcd_arg
	call	Display_Interface		       ;			       ;AC000;
	mov	byte [ss:ExitStatus],Bad_Exit ;Get return code		       ;AC000;
	ret					;Go back to Main_Init	       ;AC000;
;   ENDIF$
IF5$$1:

;get the dpb info
    LDS     BX,[ss:THISDPB] ;ds:bx--> dpb area
;    ASSUME  DS:NOTHING
    MOV     AX,[BX+dpb.dpb_sector_size] ;Bytes/sector
    MOV     [ss:SSIZE],AX ;Sector size in bytes
    MOV     AL,[BX+dpb.dpb_cluster_mask]
    INC     AL
    MOV     [ss:CSIZE],AL ;Sectors per cluster
    MOV     AX,[BX+dpb.dpb_max_cluster] ; number of clusters in the disk
    MOV     [ss:MCLUS],AX ;Bound for FAT searching
    DEC     AX			    ;ax= max clusters - 1			;an005;bgb
    MOV     [ss:DSIZE],AX   ;Total data clusters on disk		;an005;bgb
    CMP     AX,4096-8			;Big or little FAT?
;   IF$     NB
    JB IF7$$1
fat16b: INC	byte [es:BIGFAT] ;set 16-bit fat flag to true
	MOV	word [es:EOFVAL],0FFF8H ;set 16-bit compare fields for fat
	MOV	word [es:CHAIN_END],0FFFFh ;Marker for end of chain	   ;AC000;
	MOV	word [es:BADVAL],0FFF7H ;set 16-bit compare fields for fat
;   ENDIF$
IF7$$1:
    mov     ax,[bx+dpb.dpb_FAT_size] ;Sectors for one fat (DCR)			;an005;bgb
    mov     [ss:fatsiz],ax ;Sectors for one fat (DCR)			;an005;bgb
    MOV     CL,[BX+dpb.dpb_FAT_count] ;Number of FATs			;an005;bgb
    mov     [ss:fatcnt],cl   ;an005;bgb
    MOV     DX,[BX+dpb.dpb_first_FAT] ;First sector of FAT 		;an005;bgb
    MOV     [ss:firstfat],dx ;First sector of FAT 		;an005;bgb
    MOV     DX,[BX+dpb.dpb_first_sector] ;First sector of data		;ac048;bgb
    MOV     [ss:firstsec],dx ;First sector of data		;ac048;bgb
    MOV     DX,[BX+dpb.dpb_dir_sector] ;First sector of dir			;ac048;bgb
    MOV     [ss:dirsec],dx ;First sector of dir			;ac048;bgb
    MOV     DX,[BX+dpb.dpb_root_entries] ;First sector of dir			;ac048;bgb
    MOV     [ss:root_entries],dx ;First sector of dir		;ac048;bgb
    Set_Data_Segment			;reset ds to point to data area

;calc fatmap area
SMALLFAT:	    ;do this for both size fats
    ;old calculation
    ;;;;DEC	AX			;ax= max clusters - 1			    ;an005;bgb
    ;;;;MOV	[DSIZE],AX		;Total data clusters on disk		    ;an005;bgb
    ;;;;MOV	AX,[BX.dpb_FAT_size]	;Sectors for one fat (DCR)		    ;an005;bgb
    ;;;;MOV	CX,AX			;CX = Sectors/Fat			    ;an005;bgb
    ;;;;MUL	[SSIZE] 		;times bytes/sector = bytes per fat	    ;an005;bgb
    ;;;;ADD	fatmap,AX	      ;Allocate FAT space			    ;an005;bgb
    ;;;;MOV	AX,fatmap		 ;  get seg of fatmap			    ;an005;bgb

Root_CD_Ok:					 ;				;AN000;
;set dta area----do i need to do this since we are using int 25?
;set it to fat table
    call    calc_fatmap_seg	    ;find the addr of where to put the fat map	;an005;bgb
;see if we still have enough memory
    mov     ax,[ss:mem_size]  ;get top of memory
    cmp     ax,[ss:end_of_fatmap] ;mem_size must be greater or equal
;   IF$     B			     ; if not, display error msg
    JNB IF9$$1
	MOV	DX,no_mem_arg
	invoke	PRINTF_CRLF
	jmp	ALLDONE 	     ;finished with pgm
;   ENDIF$
IF9$$1:
    push    ds				;save ds
    mov     ds,[ss:fattbl_seg] ;get seg
    xor     dx,dx			;ds:dx--> dta area
;;;;mov     fatmap,dx
    DOS_Call	    Set_DMA		;function 1a			    ;AC000;
    pop     ds				;restore ds

;look for volume entry in dir
    lea     DX,[VOLID]     ;Look for VOL ID			;an005;bgb
    DOS_Call	    Dir_Search_First	    ;function 11		    ;AC000;
    CMP     AL,0			;did we find it?
;   IF$     Z				;yes
    JNZ IF11$$1
;;;;;;;;JZ	NOTVOLID
	CALL	PRINTID 		;print volume name, date, time
;   ENDIF$
IF11$$1:
NOTVOLID:
    call    Get_Serial_Num		;print volume serial number		;an024;bgb
;;;;call    hook_interrupts
; calculate the place where we run out of ram space				;an005;bgb
;;;;ADD     AX,[MCLUS]	    ;5000    ;fatmap seg + num of clusters?					      ;an005;bgb
;;;;ADD     AX,2	    ;5002   ;Insurance					;an005;bgb
;;;;MOV     [SECBUF],AX 	    ;Allocate fatmap space			;an005;bgb
    mov     ax, Chkprmt_End        ;this label must be the last thing in the code segment
    mov     [ss:SECBUF],AX   ;location of read/write buffer for dir entries ;an005;bgb
;;;;ADD     AX,[SSIZE]	    ;5202						;an005;bgb
;;;;ADD     AX,20	    ;5216   ;Insurance					;an005;bgb
    mov     ax,0ffffh	    ;get end of segment
    lea     bx,[fattbl]   ;get end of program
    sub     ax,bx	    ;this is the amount of stack space we have
    MOV     [ss:STACKLIM],AX  ;Limit on recursion 			;an005;bgb
; see if we have already overrun the stack
    MOV     DI,SP		     ;where is the stack pointer now?		;an005;bgb
    SUB     DI,100H		    ; Want AT LEAST this much stack from	;an005;bgb
				       ;  our current location			;an005;bgb
    CMP     DI,AX
;   IF$     B
    JNB IF13$$1
;;;;;;;;JB	BAD_STACK		; Already in trouble
BAD_STACK:
	MOV	BX,stackmes        ;Out of stack
	PUSH	CS
	POP	DS
	JMP	FATAL
;   ENDIF$
IF13$$1:

;
;**Read in FAT*****************************************************************
;;;;MOV     DI,fatsiz			;sectors per fat			;an005;bgb
;;;;MOV     CL,[BX.dpb_FAT_count]	   ;Number of FATs
;;;;MOV     DX,[BX.dpb_first_FAT]	   ;First sector of FAT
    mov     cx,[ss:fatsiz] ;number of sectors to read		;an005;bgb
    mov     dx,[ss:firstfat] ;starting sector number 		;an005;bgb
    mov     es,[ss:fattbl_seg] ;set up bx for read-disk				;an005;bgb
    xor     bx,bx								;an005;bgb
    MOV     AL,[ss:ALLDRV]  ;set up al with drive letter for read-disk
    DEC     AL		    ;zero based
;;;;MOV     AH,1
RDLOOP:
;;;;XCHG    CX,DI			    ;DI has # of Fats
    call    ReadFt		    ;	readft ();				;AN005;bgb
;   IF$     C			    ; could the fat be read from disk?		;AN005;bgb
    JNC IF15$$1
	inc	byte [ss:NUL_ARG]       ;an005;bgb
;;;;;;;;mov	[fatal_arg2],offset baddrvm					;an005;bgb
	mov	word [ss:fatmsg2],baddrvm        ;an005;bgb
	lea	BX,[badread]     ;an022;bgb
	JMP	FATAL			;Couldn't read any FAT, BARF            ;an005;bgb
;   ENDIF$			    ;fat could be read from disk		;AN005;bgb
IF15$$1:

;   savereg <dx,cx,di,ax>							;an005;bgb
;   mov     Read_Write_Relative.Start_Sector_High,0 ;			    ;AN000;
;   call     Read_Disk		     ;Read in the FAT			     ;AC000;
;   IF$      C
;;;;;;;;JNC	RDOK
;;;;;;;;mov	[badrw_str],offset reading
;	POP	AX			; Get fat# in ah
;	PUSH	AX			; Back on stack
;	xchg	al,ah			; Fat # to AL
;	xor	ah,ah			; Make it a word
;	mov	[badrw_num],ax
;	mov	dx,offset badr_arg
;	invoke	printf_crlf
;	restorereg <ax,cx,di,dx>						;an005;bgb
;	INC	AH
;	ADD	DX,DI
;	LOOP	RDLOOP			;Try next FAT
;;;;;;;;JMP	NORETRY1		;Couldn't read either                   ;AC000;
NORETRY1:
;	inc	byte ptr [nul_arg]
;	mov	[fatal_arg2],offset baddrvm
;	MOV	BX,offset BADRDMES
;	JMP	FATAL			;Couldn't read any FAT, BARF
;   ENDIF$
RDOK:	;**Check_for_FAT_ID**********************************************
;;;;restorereg <ax,ax,ax,ax>	    ;Clean up					;an005;bgb
    mov     es,[ss:fattbl_seg] ;segment of fat-table			;an005;bgb
    xor     si,si		     ;offset of first byte in fat-table 	;an005;bgb
;;;;LODSB			    ;Check FAT ID byte
    mov     al,byte [es:si]         ;get first byte of fat table
    CMP     AL,0F8H		    ;is it the correct id byte?
;   IF$     B,AND
    JNB IF17$$1
;;;;;;;;JAE	IDOK
    CMP     AL,0F0H		    ;if not, Is it a "strange" medium?
;   IF$     NZ
    JZ IF17$$1
;;;;;;;;jz	IDOK		    ;neither fat nor strange
	MOV	DX,badidbyt        ;FAT ID bad
	CALL	PromptYN		;Ask user to stop or not
;	IF$	NZ
	JZ IF18$$1
;;;;;;;;;;;;JZ	    IDOK
	    JMP     ALLDONE		    ;User said stop
;	ENDIF$
IF18$$1:
;   ENDIF$
IF17$$1:

;initialize the fatmap area to all zeros
IDOK:
    call    init_fatmap

;set the dta addr to here for all searches
    MOV     DX,DIRBUF            ;FOR ALL SEARCHING
    DOS_Call	    Set_DMA	    ;					    ;AC000;
    XOR     AX,AX		    ;zero out ax
    PUSH    AX			    ;I am root
    PUSH    AX			    ;Parent is root
;
    Set_Data_Segment
checkit:
    CALL    DIRPROC
    CALL    CHKMAP		    ;Look for badsectors, orphans
    CALL    CHKCROSS		    ;Check for second pass
    invoke  DOCRLF		     ;display new line
    CALL    REPORT		     ;finished, display data to screen

;*****************************************************************************
ALLDONE:
    CALL    AMDONE
;;;;;MOV     AH,EXIT
;;;;;;;;XOR	AL,AL
;;;;;; ;mov	ExitStatus,Bad_Exit	;Get return code			;AC000;
;;;;;;;;INT	21H
	ret				;Ret to Main_Init for common exit	;AN000;

;ASSUME	DS:DG_
;**Extent_Check***************************************************************
BREAK	<Check for extents in specified files>
;
; Search the directory for the files specified on the command line and report
; the number of fragmented allocation units found in each one.	We examine the
; given path name for a directory.  If it is found, we CHDIR to it.  In any
; event, we move to the file name part and do a parseFCB call to convert it
; into an FCB for a dir_search_first.  If the parse did NOT advance the
; pointer to the null byte terminating the string, then we have a bogus anme
; and we should report it.
;

CHECKFILES:
	Set_Data_Segment
; see if there is a '\' in the path name
	MOV	DI,PATH_NAME
	MOV	SI,DI
	MOV	CX, [FNAME_LEN] ;					;an011;bgb
	ADD	DI,CX			; ES:DI points to char AFTER last char
	DEC	DI			; Point to last char
doagain: MOV	 AL,[DIRCHAR]		 ;try to find '\' in path name
	STD
	REPNE	SCASB
	CLD
;	IF$	Z			;a '\' was found in path		;an055;bgb
	JNZ IF21$$1
	    mov     al,[di]		;get byte preceding '\' 		;an055;bgb
	    call    Check_DBCS_Character ;see if dbcs leading char		;an055;bgb
;	    IF$     C			;carry means dbcs leading char		;an055;bgb
	    JNC IF22$$1
		jmp	doagain 	;so ignore				;an055;bgb
;	    ELSE$								;an055;bgb
	    JMP SHORT EN22$$1
IF22$$1:
		jmp	GotPath 	;found a '\' and not dbcs		;an055;bgb
;	    ENDIF$								;an055;bgb
EN22$$1:
;	ENDIF$									;an055;bgb
IF21$$1:
;;;;;;;;;;;;;;;;;;;;;JZ      GotPath		     ; found path char. 	;an055;bgb
; No '\' was found.  set up pointers for parse FCB call.
	MOV	DI,PATH_NAME
	CMP	byte [DI+1],':'      ;was a drive letter entered?
	JNZ	ParseName
	ADD	DI,2
	JMP	SHORT ParseName

;*****************************************************************************
; found a '\' in the path name
;Change directories and set up the appropriate FCB
GotPath:
	INC	DI			; DI points AT the path sep
	PUSH	word [DI]      ; Save two chars here
	PUSH	DI			; Save location
	SUB	SI,DI
	JZ	IS_ROOT_DIR		; SI=DI=First char which is a dirchar
	NEG	SI
	CMP	SI,2
	JNZ	NOT_ROOT_DIR
	CMP	byte [DI-1],':'     ; d:\ root spec?
	JNZ	NOT_ROOT_DIR		; Nope
IS_ROOT_DIR:
	INC	DI			; Don't zap the path sep, zap NEXT char
NOT_ROOT_DIR:
	MOV	byte [DI],0
	MOV	DX,PATH_NAME
	DOS_Call	CHDir		;					;AC000;
	POP	DI			; Recall loc
	POP	word [DI]      ; recall chars
	JNC	VALID_PATH
	invoke	DOCRLF
	MOV	DX,invpath_arg
	invoke	PRINTF_CRLF
	JMP	CDONE1

;*****************************************************************************
VALID_PATH:
	INC	byte [DIR_FIX]
	INC	DI		; Point past path sep to first char of name
ParseName:
; parse the filename and get back a formatted fcb for it in es:di
	MOV	SI,DI		      ; DS:SI points to name
	MOV	DI,fcb_copy        ; ES:DI points to FCB
	MOV	AL,[ALLDRV]     ; drive number
	STOSB			      ; put it into fcb
	DEC	DI		      ; Back to start of FCB
	MOV	[pFileName],SI     ; save end of file name
	MOV	AL,00000010B	      ; tell parse to change drive letter if needed
	DOS_Call	Parse_File_Descriptor	;				;AC000;
	CMP	byte [SI],0           ;ds:si should point past filename
	JZ	ScanFile
;
; Twiddle the file name to be truly bogus.  Zorch the drive letter
;
	MOV	byte [es:DI],-1
ScanFile:
	invoke	DOCRLF
;set dma pointer to here
	MOV	DX,DIRBUF        ;FOR ALL SEARCHING
	MOV	BP,DX
	ADD	BP,27			;bp points to clus in the dir entry
	DOS_Call	Set_DMA 	;set dma ptr here for dir search	 ;AC000;
;try to find the file specified
	MOV	AH,Dir_Search_First		 ;Look for the first file
FRAGCHK:
	MOV	DX,fcb_copy
	INT	21H
	OR	AL,AL			;Did we find it?
	JNZ	MSGCHK			;No -- we're done
; we found the file
; look for fragmentation
	XOR	AX,AX			;Initialize the fragment counter
	MOV	SI,[BP] 		;Get the first cluster		     ;an005;bgb
	CALL	UNPACK			;see what that cluster points to
	CMP	DI,[EOFVAL]		;End-of-file?
	JAE	NXTCHK			;Yes -- go report the results
	INC	SI
	CMP	SI,DI
	JZ	EACHCLUS
	INC	AX
EACHCLUS:
	MOV	[OLDCLUS],DI		;Save the last cluster found
	MOV	SI,DI			;Get the next cluster
	CALL	UNPACK
	INC	word [OLDCLUS] ;Bump the old cluster
	CMP	DI,[OLDCLUS]		;Are they the same?
	JNZ	LASTCLUS		;No -- check for end-of-file
	JMP	SHORT EACHCLUS		;Continue processing
LASTCLUS:
	CMP	DI,[EOFVAL]		;End-of-file?
	JAE	NXTCHK			;Yes -- go report the results
	INC	AX			;No -- found a fragement
	JMP	SHORT EACHCLUS		;Continue processing
NXTCHK: 	      ;reached the end of a file
	OR	AX,AX			;did we find any fragmentation?
	JZ	GETNXT
;we found fragmentation
	MOV	byte [FRAGMENT],2 ;Signal that we output at least one file
	inc	ax			;bump by one for ends
	mov	[block_num],ax
	mov	word [rarg1],ax     ;					 ;an011;bgb
	mov	word [rarg1+2],0
	mov	si,DIRBUF        ;point to filename			;an011;bgb
	INC	SI			;move pointer past drive letter
; get the full path name for this file
	CALL	get_THISEL2
; print it out
	mov	dx,extent_arg
	invoke	PRINTF_CRLF
GETNXT:
	MOV	AH,Dir_Search_Next	    ;Look for the next file
	JMP	FRAGCHK
MSGCHK:
	CMP	AH,Dir_Search_First	;was this the first file searched for?
	JNZ	FILSPOK
;	MOV	SI,offset FCB_copy + 1   ;File not found error
;	CALL	get_THISEL2
	MOV	SI,[pFileName]
	CALL	get_currdir
	mov	dx,opnerr_arg
	invoke	PRINTF_CRLF		    ;bad file spec
	jmp	short CDONE
FILSPOK:
	CMP	byte [FRAGMENT],2
	JZ	CDONE
; all files were ok
	mov	dx,noext_arg
	invoke	PRINTF_CRLF
CDONE:
	CMP	byte [DIR_FIX],0
	JZ	CDONE1
	MOV	DX,USERDIR
	DOS_Call	CHDir			;				;AC000;
CDONE1:
	RET



; This is the old parameter passing scheme					;ac048;bgb
; inputs: AH - the sector number within the cluster				;ac048;bgb
;	  BX - cluster number							;ac048;bgb
; output: DX - absolute sector number						;ac048;bgb
;*****************************************************************************	;ac048;bgb
; FIGREC - This procedure calculates the absolute sector number of a logical	;ac048;bgb
;	   drive, given any cluster number and the sector within that cluster.	;ac048;bgb
;	   You can use this to find the sector number for a file.		;ac048;bgb
;										;ac048;bgb
;	   This procedure was entirely re-written for dos 4.0, since the	;ac048;bgb
;	   sector number can now be a DOUBLE word value.			;ac048;bgb
;										;ac048;bgb
; called by: getent in chkproc							;ac048;bgb
;										;ac048;bgb
; inputs: BX - cluster number							;ac048;bgb
;	  AH - sector number within cluster					;ac048;bgb
;	  csize - sectors per cluster (from dpb)				;ac048;bgb
;	  firstsec - starting sector number of the data area (from dpb) 	;ac048;bgb
;										;ac048;bgb
;outputs: DX - absolute sector number (low order)				;ac048;bgb
;	  INT26.start_sector_high     (hi  order)				;ac048;bgb
;										;ac048;bgb
;regs changed: DX only								;ac048;bgb
;										;ac048;bgb
;formula: cluster (3-fff7) * secs/cluster (1-8) = (3-7ffb8)			;ac048;bgb
;	  + sector-offset (0-8) + first-sector (1-ffff) = (7ffb9-8ffbf) 	;ac048;bgb
;										;ac048;bgb
; logic: 1. adjust the cluster number, since the 1st two clusters in the fat	;ac048;bgb
;	    are not used. cluster number can be from 3-fff7.			;ac048;bgb
;	 2. get the sectors-per-cluster, and multiply it times cluster number	;ac048;bgb
;	    in AX.  since this is a word multiply, the high order number goes	;ac048;bgb
;	    into DX.								;ac048;bgb
;	 3. add in the sector-number-within-the-cluster.  Each cluster		;ac048;bgb
;	    (usually) contains several sectors within a cluster.  This sector	;ac048;bgb
;	    number is that number.  It may be from zero to the max number of	;ac048;bgb
;	    sectors/cluster (which can be up to 8 so far on IBM systems).	;ac048;bgb
;	    Do an ADC in case there is a overflow of the word register. 	;ac048;bgb
;	 4. add in the starting cluster number of the data area.  This now	;ac048;bgb
;	    gives you the logical sector number within that drive.		;ac048;bgb
;*****************************************************************************	;ac048;bgb
Procedure figrec								;ac048;bgb
	push	ax		   ;save registers				;ac048;bgb
	push	bx		   ;save registers				;ac048;bgb
	push	cx		   ;save registers				;ac048;bgb
										;ac048;bgb
	xor	ch,ch		 ;clear out hi byte of sector-offset		;ac048;bgb
	mov	cl,ah		 ;move sector-offset into cx			;ac048;bgb
	mov	ax,bx		   ;move cluster number into ax for mult	;ac048;bgb
										;ac048;bgb
	xor	bh,bh		   ;zero out bh 				;ac048;bgb
	mov	bl,[CSIZE]  ;get sectors per cluster			;ac048;bgb
	dec	ax		   ; sub 2 for the 1st 2 unused clus in the fat ;ac048;bgb
	dec	ax			;					;ac048;bgb
	mul	bx		   ;ax=low word, dx=hi word			;ac048;bgb
										;ac048;bgb
	add	ax,cx		   ;add sector offset				;ac048;bgb
	adc	dx,0		   ;inc hi word if overflow			;ac048;bgb
	add	ax,[firstsec]	   ;add first data sector			;ac048;bgb
	adc	dx,0		   ;inc hi word if overflow			;ac048;bgb
										;ac048;bgb
	mov	[Read_Write_Relative.Start_Sector_High],dx ;save hi value 	;ac048;bgb
	mov	dx,ax		 ;convert to old format- dx=low 		;ac048;bgb
										;ac048;bgb
	pop	cx								;ac048;bgb
	pop	bx								;ac048;bgb
	pop	ax								;ac048;bgb
	RET									;ac048;bgb
EndProc figrec									;ac048;bgb


;*****************************************************************************
SUBTTL	PRINTID - Print Volume ID info
PAGE
PRINTID:
;ASSUME	DS:DG_
	call	DOCRLF				;				;AN000;
;get volume name								;an012;bgb
	xor	si,si			;Point at DTA where find first just done;;an005;bgb
	lea	DI,[ARG_BUF];Where to put vol name for message	;AC000;
	add	si,DIRENT.DIRNAM		;Point at the vol label name		;AN000;
;;;;;;;;lea	DI,arg_buf		;Point at vol label location in arg_Buf ;AC000;
	MOV	CX,11			; Pack the name
	push	ds								;an005;bgb
	mov	ds,[fattbl_seg]     ;an005;bgb
	REP	MOVSB			; Move all of it
;get the year									;an012;bgb
	xor	si,si			;Get back pointer to FCB		;an009;bgb
	mov	ax,[ds:si+DIRENT+DIRENT.DIRDAT] ;yyyyyyym mmmddddd Put in SysDisp form  ;AN009;bgb
	and	ax,Year_Mask		;yyyyyyy0 00000000			;AN000;
	shr	ax,1			;0yyyyyyy 00000000			;AN000;
	xchg	al,ah			;00000000 0yyyyyyy			;AN000;
	add	ax,1980 		;					;AN000;
; MASM worked LENGTH out as the number of elements a variable was
; declared with and SIZE as the bytes they take up.  The arrays these
; ask about are all of bytes, so the two come to the same number.
	mov	word [es:Sublist_msg_IDmes+Sublist_Struc.Sublist_Offset+(sizeof.Sublist_Struc)],ax ;	   ;AN009;bgb
;get the month									;an012;bgb
	mov	ax,[ds:si+DIRENT+DIRENT.DIRDAT] ;yyyyyyym mmmddddd			   ;AN009;bgb
	and	ax,Month_Mask		;0000000m mmm00000			;AN000;
	mov	cl,5			;					;AN000;
	shr	ax,cl			;00000000 0000mmmm			;AN000;
	mov	cl,al			;0000mmmm				;AN000;
;get the day									;an012;bgb
	mov	ax,[ds:si+DIRENT+DIRENT.DIRDAT] ;yyyyyyym mmmddddd			   ;AN009;bgb
	and	ax,Day_Mask		;00000000 000ddddd			;AN000;
	mov	ah,cl			;0000mmmm 000ddddd			;AN000;
	xchg	ah,al			;make it display correctly		;an012;bgb
	mov	word [es:Sublist_msg_IDmes+Sublist_Struc.Sublist_Segment+(sizeof.Sublist_Struc)],ax ;	   ;AN009;bgb
;get the time									;an012;bgb
	mov	ax,[ds:si+DIRENT+DIRENT.DIRTIM] ;hhhhhmmm mmmsssss			   ;AN009;bgb
	and	ax,Hour_Mask		;hhhhh000 00000000			;AN000;
	mov	cl,11			;					;AN000;
	shr	ax,cl			;00000000 000hhhhh			;AN000;
	mov	ch,al			;000hhhhh				;AN000;
	mov	ax,[ds:si+DIRENT+DIRENT.DIRTIM] ;hhhhhmmm mmmsssss			   ;AN009;bgb
	and	ax,Minute_Mask		;00000mmm mmm00000			;AN000;
	mov	cl,3			;					;AN000;
	shl	ax,cl			;00mmmmmm 00000000		       ;AN000;
	mov	al,ch			;00mmmmmm 000hhhhh			;AN000;
	mov	word [es:Sublist_msg_IDmes+Sublist_Struc.Sublist_Offset+(sizeof.Sublist_Struc)+(sizeof.Sublist_Struc)],ax ;AN009;bgb
	mov	word [es:Sublist_msg_IDmes+Sublist_Struc.Sublist_Segment+(sizeof.Sublist_Struc)+(sizeof.Sublist_Struc)],0 ;AN009;bgb
	pop	ds								;an009;bgb
	Message idmes_arg		; the parts out as needed		;AC000'
;;;;;;;;call	doCRLF
	ret				;




;*****************************************************************************	;an024;bgb
; Get the volume serial number							;an024;bgb
;*****************************************************************************	;an024;bgb
; Input:  FCB_Drive								;an024;bgb
; Output: SerNum if no carry							;an024;bgb
; Notes:  Only DOS Version 3.4 and above will contain serial numbers		;an024;bgb
;*****************************************************************************	;an024;bgb
;   PUBLIC GET_SERIAL_NUM							;an024;bgb
Procedure Get_Serial_Num		;AN000;S				     ;an024;bgb
   mov	al,GENERIC_IOCTL	   ;AN000;S					;an041;bgb;an024;bgb
   xor	bx,bx			   ;zero out bx 				;an041;bgb;an024;bgb
   mov	bl,[ALLDRV]   ;AN000;S Which drive to check		;an024;bgb
   mov	ch,RAWIO		   ;8 = disk io 				;an041;bgb;an024;bgb
   mov	cl,GET_MEDIA_ID 	   ;66h = get media id				;an041;bgb;an024;bgb
   LEA	dx,[SerNumBuf]   ;AN000;S Pt to the buffer			;an024;bgb
   DOS_Call IOCtl		   ;AN000;S Make the call			;an041;bgb;an024;bgb
;  IF$	NC
   JC IF26$$1
       Message	msgSerialNumber 						    ;an024;bgb
;  ENDIF$
IF26$$1:
   ret				   ;AN000;S					;an024;bgb
EndProc Get_Serial_Num			   ;AN000;S					;an024;bgb
	pathlabl chkdsk1							;an024;bgb
end if
;	END	CHKDSK
