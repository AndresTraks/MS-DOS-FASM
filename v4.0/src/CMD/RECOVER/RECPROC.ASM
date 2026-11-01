page	,132					;
TITLE	RECPROC.SAL
;*****************************************************************************
; Include files
;*****************************************************************************
.xlist
	include 'RECSEG.INC' ;AN000;bgb
 include 'DOSSYM.INC' ;AN000;bgb
 include 'SYSCALL.INC' ;AN000;bgb
 include 'RECMACRO.INC' ;AN000;bgb
 include 'RECEQU.INC' ;AN000;bgb
	include 'PATHMAC.INC'
.xcref
macro BREAK subtitle
{
	SUBTTL	subtitle
	PAGE
}
.cref
;
;*****************************************************************************
; Extrn Declarations
;*****************************************************************************
if SEGSEL = S_DATA;AC000;bgb
;	EXTRN	secs_per_64k:word
;	EXTRN	paras_per_fat:word
;	EXTRN	paras_per_64k:word
;	EXTRN	bytes_per_sector:word
;	EXTRN	sec_count:word
;	EXTRN	OFMSG_PTR:WORD
;	EXTRN	y_value_lo:WORD 	;AN000;bgb
;	EXTRN	y_value_hi:WORD 	;AN000;bgb	   ; AC000;SM
;	EXTRN	x_value_lo:WORD 	;AN000;bgb	   ; AC000;SM
;	EXTRN	x_value_hi:WORD 	;AN000;bgb	   ; AC000;SM
;	EXTRN	dbcs_vector:byte	 ;AN000;bgb	    ; AC000;SM
;	EXTRN	dbcs_vector_off:word	 ;AN000;bgb	    ; AC000;SM
;	EXTRN	dbcs_vector_seg:word	 ;AN000;bgb	    ; AC000;SM
;	EXTRN	filsiz:WORD		;AN000;bgb
;	EXTRN	read_write_relative:byte ;AN000;bgb
end if ;AC000;bgb

;*****************************************************************************
; recproc procedures
;*****************************************************************************
if SEGSEL = S_CODE;AC000;bgb
	pathlabl recproc
;public report				       ;AN000;bgb
;public Read_Disk			;AN000;bgb
;public Write_Disk			;AN000;bgb
;public Build_String			;AN000;bgb
;public ChANge_BlANks			;AN000;bgb
;public Check_DBCS_CharACter		;AN000;bgb
.list

;******************************************
; Prints the XXX of YYY bytes recovered message.
; The XXX value is a dword at di+16 on entry.
; The YYY value is a dword (declared as a word) at filsiz.
;*************************************************************
Procedure report				;				;AN000;bgb
	lea	dx,[ofmsg_ptr]
	mov	si,[di+16]			;Get the XXX value
	mov	[x_value_lo],si
	mov	di,[di+18]
	mov	[x_value_hi],di
	mov	si,[filsiz] ;Get the YYY value
	mov	[y_value_lo],si
	mov	di,[filsiz+2]
	mov	[y_value_hi],di
	call	Display_Interface		; AC000;SM
	ret
;report endp

;=========================================================================	;an005;bgb
; READ_DISK	:	This routine reads the logical sector count requested.	;an005;bgb
;			It will read a maximum of 64k in one read.  If more	;an005;bgb
;			than 64k exists it will continue looping until		;an005;bgb
;			all sectors have been read.				;an005;bgb
;										;an005;bgb
;	Inputs	:	AL - Drive letter					;an005;bgb
;			ES:BX - Segment:offset of transfer address		;an005;bgb
;			CX - Sector count					;an005;bgb
;			DX - 1st  sector					;an005;bgb
;										;an005;bgb
;	Outputs :	Logical sectors read					;an005;bgb
; LOGIC 									;an005;bgb
; ***** 									;an005;bgb
;    adjust es:bx to es:00							;an005;bgb
;    calcluate sectors-per-64k (how many sectors are there that can fit within a 64k segment?)
;    DO while there are more sectors to read than sectors-per-64k		;an005;bgb
;	set sector-count to sectors-per-64k					;an005;bgb
;	perform the disk read							;an005;bgb
;	bump the seg addr to the new addr					;an005;bgb
;	dec  the number of sectors to read by sectors-per-64k			;an005;bgb
;	bump the starting sector number by the sectors-per-64k			;an005;bgb
;    ENDDO									;an005;bgb
;    perform a disk read for less than sectors-per-64k				;an005;bgb
;=========================================================================	;an005;bgb
Procedure	read_disk							;an005;bgb
	SaveReg <ax,bx,cx,dx,es>
	call	seg_adj 			;an000;calc new seg:off 	;an005;bgb
	call	calc_sp64k			;an000;secs/64k 		;an005;bgb
;	$DO				; do while more than 64k		;an005;bgb
DO1$$P:
	    cmp     cx,[secs_per_64k]   ;an000;exceed 64k			;an005;bgb
;	$LEAVE	LE			    ;an000;yes				;an005;bgb
	JLE EN1$$P
	    mov     [sec_count],cx ;an000;save cx				;an005;bgb
	    mov     cx,[secs_per_64k] ;an000;get maximum read 		;an005;bgb
	    call    Read_once		;an000;read it				;an005;bgb
;	$LEAVE	C								;an005;bgb
	JC EN1$$P
	    mov     cx,es							;an005;bgb
	    add     cx,[paras_per_64k] ; adjust transfer area			;an005;bgb
	    mov     es,cx							;an005;bgb
	    mov     cx,[sec_count] ; restore sector count			;an005;bgb
	    sub     cx,[secs_per_64k] ;an000;get sectors remaining		;an005;bgb
	    add     dx,[secs_per_64k] ;an000;adjust starting sector		;an005;bgb
;	$ENDDO									;an005;bgb
	JMP SHORT DO1$$P
EN1$$P:
	call	Read_once	    ;an000;read it				;an005;bgb
	RestoreReg <es,dx,cx,bx,ax>
	ret									;an005;bgb
;read_disk	endp								 ;an005;bgb
										;an005;bgb
										;an005;bgb
;*****************************************************************************	;an005;bgb
;Routine name: Read_once							;an005;bgb
;*****************************************************************************	;an005;bgb
;										;an005;bgb
;description: Read in data using Generic IOCtl					;an005;bgb
;										;an005;bgb
;Called Procedures: None							;an005;bgb
;										;an005;bgb
;										;an005;bgb
;Change History: Created	5/13/87 	MT				;an005;bgb
;										;an005;bgb
;Input: AL = Drive number (0=A) 						;an005;bgb
;	DS:BX = Transfer address						;an005;bgb
;	CX = Number of sectors							;an005;bgb
;	Read_Write_Relative.Start_Sector_High = Number of sectors high		;an005;bgb
;	DX = logical sector number low						;an005;bgb
;										;an005;bgb
;Output: CY if error								;an005;bgb
;	 AH = INT 25h error code						;an005;bgb
;										;an005;bgb
;Psuedocode									;an005;bgb
;----------									;an005;bgb
;	Save registers								;an005;bgb
;	Setup structure for function call					;an005;bgb
;	Read the disk (AX=440Dh, CL = 6Fh)					;an005;bgb
;	Restore registers							;an005;bgb
;	ret									;an005;bgb
;*****************************************************************************	;an005;bgb
Procedure Read_once				;				;an005;bgb
	SaveReg  <ax,bx,cx,dx,si,di,bp,es,ds>	;Change it to Read relative sect;an005;bgb
	mov	[Read_Write_Relative.Buffer_Offset],bx ;Get transfer buffer add	 ;an005;bgb
	mov	bx,es				;				;AN005;bgb
	mov	[Read_Write_Relative.Buffer_Segment],bx ;Get segment		;an005;bgb
	mov	[Read_Write_Relative.Number_Sectors],cx ;Number of sec to read	;an005;bgb
	mov	[Read_Write_Relative.Start_Sector_Low],dx ;Start sector		;an005;bgb
	mov	bx,Read_Write_Relative        ;				;an005;bgb
	mov	cx,0FFFFh			;Read relative sector		;an005;bgb
	INT	25h				;Do the read			;an005;bgb
	pop dx					;Throw away flags on stack	;an005;bgb
	RestoreReg <ds,es,bp,di,si,dx,cx,bx,ax> 				;an005;bgb
	return									;an005;bgb
; Read_once endp 								;an005;bgb
										;an005;bgb
										;an005;bgb
;=========================================================================	;an005;bgb
; WRITE-DISK	:	This routine reads the logical sector count requested.	;an005;bgb
;			It will read a maximum of 64k in one read.  If more	;an005;bgb
;			than 64k exists it will continue looping until		;an005;bgb
;			all sectors have been read.				;an005;bgb
;										;an005;bgb
;	Inputs	:	AL - Drive letter					;an005;bgb
;			ES:BX - Segment:offset of transfer address		;an005;bgb
;			CX - Sector count					;an005;bgb
;			DX - 1st  sector					;an005;bgb
;										;an005;bgb
;	Outputs :	Logical sectors read					;an005;bgb
; LOGIC 									;an005;bgb
; ***** 									;an005;bgb
;    adjust es:bx to es:00							;an005;bgb
;    calcluate sectors-per-64k (how many sectors are there that can fit within a 64k segment?)
;    DO while there are more sectors to read than sectors-per-64k		;an005;bgb
;	set sector-count to sectors-per-64k					;an005;bgb
;	perform the disk read							;an005;bgb
;	bump the seg addr to the new addr					;an005;bgb
;	dec  the number of sectors to read by sectors-per-64k			;an005;bgb
;	bump the starting sector number by the sectors-per-64k			;an005;bgb
;    ENDDO									;an005;bgb
;    perform a disk read for less than sectors-per-64k				;an005;bgb
;=========================================================================	;an005;bgb
Procedure      write_disk							;an005;bgb
	mov	[Read_Write_Relative.Start_Sector_High],bp ;		       ;;an027;bgb;an023;bgb
	call	seg_adj 		;an000;calc new seg:off 		;an005;bgb
;	$DO				; do while more than 64k		;an005;bgb
DO5$$P:
	    cmp     cx,[secs_per_64k] ;an000;exceed 64k			;an005;bgb
;	$LEAVE	LE			;an000;yes				;an005;bgb
	JLE EN5$$P
	    mov     [sec_count],cx ;an000;save cx				;an005;bgb
	    mov     cx,[secs_per_64k] ;an000;get maximum read 		;an005;bgb
	    call   Write_once		;an000;read it				;an005;bgb
;	$LEAVE	C								;an005;bgb
	JC EN5$$P
	    mov     cx,es							;an005;bgb
	    add     cx,[paras_per_64k] ; adjust transfer area			;an005;bgb
	    mov     es,cx							;an005;bgb
	    mov     cx,[sec_count] ; restore sector count			;an005;bgb
	    sub     cx,[secs_per_64k] ;an000;get sectors remaining		;an005;bgb
	    add     dx,[secs_per_64k] ;an000;adjust starting sector		;an005;bgb
;	$ENDDO									;an005;bgb
	JMP SHORT DO5$$P
EN5$$P:
	call	Write_once		;an000;read it				;an005;bgb
	ret									;an005;bgb
;write_disk	endp								;an005;bgb
										;an005;bgb
;*****************************************************************************
;Routine name: Write_Once
;*****************************************************************************
;
;description: Write Data using int 26
;
;Called Procedures: None
;
;
;Change History: Created	5/13/87 	MT
;
;Input: AL = Drive number (0=A)
;	DS:BX = Transfer address
;	CX = Number of sectors
;	Read_Write_Relative.Start_Sector_High = Number of sectors high
;	DX = logical sector number low
;
;Output: CY if error
;	 AH = INT 26h error code
;
;Psuedocode
;----------
;	Save registers
;	Setup structure for function call
;	Write to disk (AX=440Dh, CL = 4Fh)
;	Restore registers
;	ret
;*****************************************************************************
Procedure Write_once				 ;				;AN000;bgb
    SaveReg <ax,bx,cx,dx,di,si,bp,es,ds>	 ;This is setup for INT 26h right;AN000;bgb
    mov  [Read_Write_Relative.Buffer_Offset],bx ;Get transfer buffer add	;AN000;bgb
    mov  bx,es					 ;				;AN005;bgb
    mov  [Read_Write_Relative.Buffer_Segment],bx ;Get segment			;AN000;bgb
    mov  [Read_Write_Relative.Number_Sectors],cx ;Number of sec to write	;AN000;bgb
    mov  [Read_Write_Relative.Start_Sector_Low],dx ;Start sector			;AN000;bgb
    mov  cx,0FFFFh				 ;Write relative sector 	;AN000;bgb
    lea  bx,[Read_Write_Relative]  ;
    INT  026h					 ;Do the write			;AN000;bgb
    pop  dx					 ;flags is returned on the stack;AN000;bgb
    RestoreReg <ds,es,bp,si,di,dx,cx,bx,ax>	 ;				;AN000;bgb
	ret					 ;				;AN000;bgb
;Write_once endp 				 ;				;AN000;bgb

;=========================================================================	;an005;bgb
; SEG_ADJ	:	This routine adjusts the segment:offset to prevent	;an005;bgb
;			address wrap.						;an005;bgb
;										;an005;bgb
;	Inputs	:	bx - Offset to adjust segment with			;an005;bgb
;			es - Segment to be adjusted				;an005;bgb
;										;an005;bgb
;	Outputs :	bx - New offset 					;an005;bgb
;			es - Adjusted segment					;an005;bgb
;=========================================================================	;an005;bgb
Procedure	seg_adj 							;an005;bgb
	SaveReg <ax,cx,dx>							;an005;bgb
	mov	ax,bx				;an000;get offset		;an005;bgb
	mov	bx,0010h			;divide by 16			;an005;bgb
	xor	dx,dx				;an000;clear dx 		;an005;bgb
	div	bx				;an000;get para count		;an005;bgb
	mov	bx,es				;an000;get seg			;an005;bgb
	add	bx,ax				;an000;adjust for paras 	;an005;bgb
	mov	es,bx				;an000;save new seg		;an005;bgb
	mov	bx,dx				;an000;new offset		;an005;bgb
	RestoreReg <dx,cx,ax>							;an005;bgb
	ret									;an005;bgb
;seg_adj 	endp								;an005;bgb
										;an005;bgb
										;an005;bgb
;=========================================================================	;an005;bgb
; SECS_PER_64K	:	This routine calculates how many sectors, for this	;an005;bgb
;			particular media, will fit into 64k.			;an005;bgb
;										;an005;bgb
;	Inputs	:	DPB_SECTOR_SIZE - bytes/sector				;an005;bgb
;										;an005;bgb
;	Outputs :	SECS_PER_64K	- Sectors / 64k 			;an005;bgb
;			PARAS_PER_64K	- paragraphs per 64k			;an005;bgb
;=========================================================================	;an005;bgb
Procedure	calc_sp64k							;an005;bgb
	SaveReg <ax,bx,cx,dx>							;an005;bgb
	mov	ax,0ffffh			;an000;64k			;an005;bgb
	mov	bx,[bytes_per_sector] ;an000;get bytes/sector 	;an005;bgb
	xor	dx,dx				;an000;clear dx 		;an005;bgb
	div	bx				;an000;sector count		;an005;bgb
	mov	[secs_per_64k],ax ;an000;save sector count	;an005;bgb
	mov	ax,[bytes_per_sector] ;an000;get bytes/sector 	;an005;bgb
	mov	bx,010h 			; divide by paras		;an005;bgb
	xor	dx,dx				;an000;clear dx 		;an005;bgb
	div	bx				; paras per sector		;an005;bgb
	mul	[secs_per_64k] ; times sectors 		;an005;bgb
	mov	[paras_per_64k],ax ; = paras per 64k		;an005;bgb
	RestoreReg <dx,cx,bx,ax>		;an000;restore dx		;an005;bgb
	ret					;an000; 			;an005;bgb
;calc_sp64k	endp				;an000; 			;an005;bgb


;*****************************************************************************
;Routine name: Build_String
;*****************************************************************************
;
;Description: Build AN ASCIIZ string from the FCB filename input.
;
;Called Procedures: None
;
;ChANge History: Created	6/29/87 	MT
;
;Input: DS:SI = String containing FCB input
;	ES:DI = Where to build string
;
;Output: ES:DI = Input string starting at first non-blANk charACter
;
;Psuedocode
;----------
;
;	Save regs
;	DO
;	LEAVE Next charACter is 0,OR
;	LEAVE 12th charACter,OR
;	   Get charACter
;	LEAVE BlANk
;	   Inc counter
;	ENDDO
;	Set next charACter to 0
;	Restore regs
;
;*****************************************************************************

Procedure Build_String				;				;AN000;
	cld					;Set string ops to up		;AN000;
	push	ax				;Save registers 		;AN000;
	push	cx				;  "  "    "  " 		;AN000;
	push	si				;Save pointer reg		;AN000;
	xor	cx,cx				;Init the counter		;AN000;
;	$DO					;Loop until entire string found ;AN000;
DO9$$P:
	   cmp	   byte [si],Asciiz_End     ;Is next charACter 0?		;AN000;
;	$LEAVE	E,OR				;Yes, end loop			;AN000;
	JE EN9$$P
	   cmp	   cx,FCB_Filename_Length	;Looked at 11 chars?		;AN000;
;	$LEAVE	E,OR				;Yes, end of string		;AN000;
	JE EN9$$P
	   lodsb				;Nope, get charACter		;AN000;
	   cmp	   al,Blank			;Find end of filename?		;AN000;
;	$LEAVE	E				;Yes, quit looping		;AN000;
	JE EN9$$P
	   stosb				;Move the char
	   inc	   cx				;No, inc counter ANd try next	;AN000;
;	$ENDDO					;				;AN000;
	JMP SHORT DO9$$P
EN9$$P:
	mov	byte [di],Asciiz_End     ;Make ASCIIZ string		;AN000;
	pop	si				;Get bACk pointer to string	;AN000;
	pop	cx				;Restore regsisters		;AN000;
	pop	ax				; "  "	  "  "			;AN000;
	ret					;				;AN000;
;Build_String endp				;				;AN000;

;*****************************************************************************
;Routine name: ChANge_BlANks
;*****************************************************************************
;
;Description: ReplACe all DBCS blANks with SBCS blANks
;
;Called Procedures: Check_DBCS_CharACter
;
;ChANge History: Created	6/12/87 	MT
;
;Input: DS:SI = ASCIIZ string containing volume label input
;
;Output: DS:SI = ASCIIZ string with all DBCS blANks replACed with 2 SBCS blANks
;
;
;Psuedocode
;----------
;
;	Save pointer to string
;	DO
;	LEAVE End of string (0)
;	   See if DBCS charACter (Check_DBCS_CharACter)
;	   IF CY (DBCS char found)
;	      IF first byte DBCS blANk, AND
;	      IF second byte DBCS blANk
;		 Convert to SBCS blANks
;	      ENDIF
;	      Point to next byte to compensate for DBCS charACter
;	   ENDIF
;	ENDDO
;	Restore pointer to string
;
;*****************************************************************************
Procedure ChANge_BlANks 			;				;AN000;
;	$DO					;Do while not CR		;AN000;
DO12$$P:
	   cmp	   byte [si],Asciiz_End     ;Is it end of string?		;AN000;
;	$LEAVE	E				;All done if so 		;AN000;
	JE EN12$$P
	   call    Check_DBCS_CharACter 	;Test for dbcs lead byte	;AN000;
;	   $IF	   C				;We have a lead byte		;AN000;
	   JNC IF14$$P
	      cmp     byte [si],DBCS_Lead     ;Is it a lead blANk?		;AN000;
;	      $IF     E,AND			;If a dbcs char 		;AN000;
	      JNE IF15$$P
	      cmp     byte [si+1],DBCS_Blank     ;Is it AN AsiAN blANk?    ;AN000;
;	      $IF     E 			;If AN AsiAN blANk		     ;AN000;
	      JNE IF15$$P
		 mov	 byte [si+1],Blank     ;set up moves		      ;AN000;
		 mov	 byte [si],Blank     ;  to replACe			;AN000;
;	      $ENDIF				;				     ;AN000;
IF15$$P:
	      inc     si			;Point to dbcs char		;AN000;
;	   $ENDIF				;End lead byte test		;AN000;
IF14$$P:
	   inc	   si				;Point to si+1			;AN000;
;	$ENDDO					;End do while			;AN000;
	JMP SHORT DO12$$P
EN12$$P:
	ret					;return to caller		;AN000;
;ChANge_BlANks endp				;				;AN000;


;*****************************************************************************
;Routine name: Check_DBCS_CharACter
;*****************************************************************************
;
;Description: Check if specified byte is in rANges of DBCS vectors
;
;Called Procedures: None
;
;ChANge History: Created	6/12/87 	MT
;
;Input: AL = CharACter to check for DBCS lead charACter
;	DBCS_Vector = YES/NO
;
;Output: CY set if DBCS charACter
;	 DBCS_VECTOR = YES
;
;
;Psuedocode
;----------
;	Save registers
;	IF DBCS vector not found
;	   Get DBCS environmental vector (INT 21h
;	   Point at first set of vectors
;	ENDIF
;	SEARCH
;	LEAVE End of DBCS vectors
;	EXITIF CharACter > X1,AND  (X1,Y1) are environment vectors
;	EXITIF CharACter < Y1
;	  STC (DBCS charACter)
;	ORELSE
;	   Inc pointer to next set of vectors
;	ENDLOOP
;	   CLC (Not DBCS charACter)
;	ENDSRCH
;	Restore registers
;	ret
;*****************************************************************************
Procedure	Check_DBCS_CharACter		      ; 			      ;AN000;
	push	ds				;Save registers 		;AN000;
	push	si				; "  "	  "  "			;AN000;
	push	ax				; "  "	  "  "			;AN000;
	push	ds				; "  "	  "  "			;AN000;
	pop	es				;Establish addressability	;AN000;
	cmp	byte [es:DBCS_Vector],YES   ;Have we set this yet?		;AN000;
	push	ax				;Save input charACter		;AN000;
;	$IF	NE				;Nope				;AN000;
	JE IF19$$P
	   mov	   al,0 			;Get DBCS environment vectors	;AN000;
	   DOS_Call Hongeul			;  "  "    "  " 		;AN000;
	   mov	   byte [es:DBCS_Vector],YES   ;Indicate we've got vector      ;AN000;
	   mov	   [es:DBCS_Vector_Off],si ;Save the vector		;AN000;
	   mov	   ax,ds			;				;AN000;
	   mov	   [es:DBCS_Vector_Seg],ax ;				;AN000;
;	$ENDIF					; for next time in		;AN000;
IF19$$P:
	pop	ax				;Restore input charACter	;AN000;
	mov	si,[es:DBCS_Vector_Seg] ;Get saved vector pointer	;AN000;
	mov	ds,si				;				;AN000;
	mov	si,[es:DBCS_Vector_Off] ;				;AN000;
;	$SEARCH 				;Check all the vectors		;AN000;
DO21$$P:
	   cmp	   word [ds:si],End_Of_Vector     ;End of vector table? 	  ;AN000;
;	$LEAVE	E				;Yes, done			;AN000;
	JE EN21$$P
	   cmp	   al,[ds:si]			;See if char is in vector	;AN000;
;	$EXITIF AE,AND				;If >= to lower, ANd		;AN000;
	JNAE IF21$$P
	   cmp	   al,[ds:si+1] 		; =< thAN higher rANge		;AN000;
;	$EXITIF BE				; then DBCS charACter		;AN000;
	JNBE IF21$$P
	   stc					;Set CY to indicate DBCS	;AN000;
;	$ORELSE 				;Not in rANge, check next	;AN000;
	JMP SHORT SR21$$P
IF21$$P:
	   add	   si,DBCS_Vector_Size	     ;Get next DBCS vector	     ;AN000;
;	$ENDLOOP				;We didn't find DBCS char       ;AN000;
	JMP SHORT DO21$$P
EN21$$P:
	   clc					;Clear CY for exit		;AN000;
;	$ENDSRCH				;				;AN000;
SR21$$P:
	pop	ax				;Restore registers		;AN000;
	pop	si				; "  "	  "  "			;AN000;
	pop	ds				;Restore data segment		;AN000;
	ret					;				;AN000;
;Check_DBCS_CharACter endp			;				;AN000;

	pathlabl recproc
end if
;	end
