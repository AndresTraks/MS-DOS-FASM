;	SCCSID = @(#)forproc.asm	1.2 85/07/25
;
.xlist
.xcref
macro BREAK subtitle
{
	SUBTTL	subtitle
	PAGE
}

	include 'FORCHNG.INC'
	include 'SYSCALL.INC'
	include 'FOREQU.INC'
	include 'FORMACRO.INC'
	include 'FORSWTCH.INC'
	include 'IOCTL.INC'
.cref
.list
if SEGSEL = S_DATA
end if

if SEGSEL = S_CODE
;	assume	cs:code,ds:data

;	PUBLIC	FormatAnother?,Yes?,REPORT,USER_STRING
;	public	fdsksiz,badsiz,syssiz,datasiz,biosiz
;	public	AllocSize,AllocNum

;	extrn	std_printf:near,crlf:near,PrintString:near
;	extrn	Multiply_32_Bits:near
;	extrn	AddToSystemSize:near

end if
if SEGSEL = S_DATA
;	extrn	driveLetter:byte
;	extrn	msgInsertDisk:byte
;	extrn	msgFormatAnother?:byte
;	extrn	msgTotalDiskSpace:byte
;	extrn	msgSystemSpace:byte
;	extrn	msgBadSpace:byte
;	extrn	msgDataSpace:byte
;	extrn	Read_Write_Relative:byte
;	extrn	msgAllocSize:byte
;	extrn	MsgAllocNum:Byte
;	extrn	deviceParameters:byte
;	extrn	bios:byte
;	extrn	dos:byte
;	extrn	command:byte
;	extrn	Serial_Num_Low:Word
;	extrn	Serial_Num_High:Word
;	extrn	msgSerialNumber:Byte
;	extrn	SwitchMap:Word


;	extrn	inbuff:byte

fdsksiz dd	0

syssiz	dd	0
biosiz	dd	0

badsiz	dd	0

datasiz dd	0

AllocSize dd	0				;				;AN000;
AllocNum dw	0				;				;AN000;
	dw	driveLetter
end if
if SEGSEL = S_CODE

FormatAnother?:
; Wait for key. If yes return carry clear, else no. Insures
;   explicit Y or N answer.
	Message msgFormatAnother?		;				;AC000;
	CALL	YES?
	JNC	WAIT20
	JZ	WAIT20
	CALL	crlf
	JMP	SHORT FormatAnother?
WAIT20: 					;				;AC000;
	RET					;				;AC000;
;FormatAnother? endp

;*****************************************************************************
;Routine name:Yes?
;*****************************************************************************
;
;Description: Validate that input is valid Y/N for the country dependent info
;	      Wait for key. If YES return carry clear,else carry set.
;	      If carry is set, Z is set if explicit NO, else key was not Yes or No.
;
;Called Procedures: Message (macro)
;		    User_String
;
;Change History: Created	4/32/87 	MT
;
;Input: None
;
;Output: CY = 0 Yes is entered
;	 CY = 1, Z = No
;	 CY = 1, NZ = other
;
;Psuedocode
;----------
;
;	Get input (CALL USER STRING)
;	IF got character
;	   Check for country dependent Y/N (INT 21h, AX=6523h Get Ext Country)
;	   IF Yes
;	      clc
;	   ELSE (No)
;	      IF No
;		 stc
;		 Set Zero flag
;	      ELSE (Other)
;		 stc
;		 Set NZ
;	      ENDIF
;	   ENDIF
;	ELSE  (nothing entered)
;	   stc
;	   Set NZ flag
;	ENDIF
;	ret
;*****************************************************************************

Procedure YES?					;				;AN000;

	call	USER_STRING			;Get character			;     ;
;	IF$	NZ				;Got one if returned NZ 	;AC000;
	JZ IF1$$P
	   mov	   al,23h			;See if it is Y/N		;AN000;
	   mov	   dl,[INBUFF+2]		;Get character			;AN000;
	   DOS_Call GetExtCntry 		;Get country info call		;AN000;
	   cmp	   ax,Found_Yes 		;Which one?			;AC000;
;	   IF$	   E				;Got a Yes			;AC000;
	   JNE IF2$$P
	      clc				;Clear CY for return		;AN000;
;	   ELSE$				;Not a Yes			;AN000;
	   JMP SHORT EN2$$P
IF2$$P:
	      cmp     ax,Found_No		;Is it No?			;AC000;
;	      IF$     E 			;Yep				;AN000;
	      JNE IF4$$P
		 stc				;Set CY for return		;AC000;
;	      ELSE$				;Something else we don't want   ;AN000;
	      JMP SHORT EN4$$P
IF4$$P:
		 xor	 al,al			;Set NZ flag for ret		;AC000;
		 cmp	 al,1			; " "	 " "			;AC000;
		 stc				;And CY flag for good measure	;AN000;
;	      ENDIF$				;				;AN000;
EN4$$P:
;	   ENDIF$				;				;AN000;
EN2$$P:
;	ELSE$					;No char found at all		;AN000;
	JMP SHORT EN1$$P
IF1$$P:
	   xor	   al,al			;Set NZ flag for ret		;AN000;
	   cmp	   al,1 			; " "	 " "			;AN000;
	   stc					;And CY flag for good measure	;AN000;
;	ENDIF$					;				;AN000;
EN1$$P:
	ret					;				;     ;

;Yes?	endp					;				;AN000;


USER_STRING:
; Get a string from user. Z is set if user typed no chars (imm CR)
;  We need to flush a second time to get rid of incoming Kanji characters also.
	MOV	AX,(Std_Con_Input_Flush SHL 8) + 0 ; Clean out input
	INT	21H
	MOV	DX,INBUFF
	MOV	AH,Std_Con_String_Input
	INT	21H
	MOV	AX,(Std_Con_Input_Flush SHL 8) + 0 ; Clean out input
	INT	21H
	CMP	byte [INBUFF+1],0
	RET

;*********************************************
; Make a status report including the following information:
; Total disk capacity
; Total system area used
; Total bad space allocated
; Total data space available
; Number of allocation units
; Size of allocation units

REPORT:
	call	crlf

	call	Calc_System_Space		;an013; dms;calc system space
	call	Calc_Total_Addressible_Space	;an013; dms;calc total space

	Message msgTotalDiskSpace		;				;AC000;
						;call	 std_printf
	cmp	word [syssiz],0
	JNZ	SHOWSYS
	cmp	word [syssiz+2],0
	JZ	CHKBAD
SHOWSYS:
	Message msgSystemSpace			;				;AC000;
						;CALL	 std_printf		 ;Report space used by system
CHKBAD:
	cmp	word [badsiz],0
	JNZ	SHOWBAD
	cmp	word [badsiz+2],0
	JZ	SHOWDATA
SHOWBAD:
	Message msgBadSpace			;				;AC000;
						;call	 std_printf
SHOWDATA:


	MOV	CX,word [fdsksiz]
	MOV	BX,word [fdsksiz+2]
	SUB	CX,word [badsiz]
	SBB	BX,word [badsiz+2]
	SUB	CX,word [syssiz]
	SBB	BX,word [syssiz+2]
	MOV	word [datasiz],CX
	MOV	word [datasiz+2],BX
	Message msgDataSpace			;				;AC000;
						;call	 std_printf

	call	crlf				;				;AN000;
	mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR] ; 		;AN000;
	mov	cl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER] ;		;AN000;
	xor	ch,ch				;				;AN000;
	mul	cx				;Get bytes per alloc		;AN000;

	mov	word [AllocSize],ax    ;Save allocation size		;AN000;
	mov	word [AllocSize+2],dx    ; for message			;AN000;
	Message msgAllocSize			;Print size of cluster		;AN000;
	call	Get_Free_Space			;an013; dms;get disk space

	mov	word [AllocNum],bx    ;Put result in msg		;AN000;
	Message msgAllocNum			; = cluster/disk		;AN000;
	call	crlf				;				;AN000;
	test	word [SWITCHMAP], SWITCH_8 ;If 8 tracks, don't display     ;AN027;
	jnz	NOSERIALNUMBER			;serial number			;AN027;
	Message msgSerialNumber 		;Spit out serial number 	;AN000;
	call	crlf				;
NOSERIALNUMBER: 								;AN027;
	RET					;

;*****************************************************************************
;Routine name: Read_Disk
;*****************************************************************************
;
;description: Read in data using Generic IOCtl
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
;	 AH = INT 25h error code
;
;Psuedocode
;----------
;	Save registers
;	Setup structure for function call
;	Read the disk (AX=440Dh, CL = 6Fh)
;	Restore registers
;	ret
;*****************************************************************************

Procedure Read_Disk				;				;AN000;

						;This is setup for INT 25h right;AN000;
						;Change it to Read relative sect;AN000;
	push	bx				;Save registers 		;AN000;
	push	cx				;				;AN000;
	push	dx				;				;AN000;
	push	si				;				;AN000;
	push	di				;				;AN000;
	push	bp				;				;AN000;
	push	es				;				;AN000;
	push	ds				;
	mov	si,data_ 			;				;AN000;
	mov	es,si				;				;AN000;

;	assume	es:data,ds:nothing		;				;AN000;

	mov	[es:Read_Write_Relative.Buffer_Offset],bx ;Get transfer buffer add;AN000;
	mov	bx,ds				;				;AN000;
	mov	[es:Read_Write_Relative.Buffer_Segment],bx ;Get segment		;AN000;
	mov	bx,data_ 			;Point DS at parameter list	;AN000;
	mov	ds,bx				;				;AN000;

;	assume	ds:data,es:data

	mov	[Read_Write_Relative.Number_Sectors],cx ;Number of sec to read	;AN000;
	mov	[Read_Write_Relative.Start_Sector_Low],dx ;Start sector		;AN000;
	mov	bx,Read_Write_Relative        ;				  ;AN000;
	mov	cx,0FFFFh			;Read relative sector		;AN000;
	INT	25h				;Do the read			;AN000;
	pop	dx				;Throw away flags on stack	;AN000;
	pop	ds				;
	pop	es				;				;AN000;
	pop	bp				;				;AN000;
	pop	di				;				;AN000;
	pop	si				;				;AN000;
	pop	dx				;Restore registers		;AN000;
	pop	cx				;				;AN000;
	pop	bx				;				;AN000;
	ret					;				;AN000;


;Read_Disk endp					;				;AN000;

;*****************************************************************************
;Routine name: Write_Disk
;*****************************************************************************
;
;description: Write Data using Generic IOCtl
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

Procedure Write_Disk				;				;AN000;


						;This is setup for INT 26h right
						;Change it to Read relative sect

	push	bx				;Save registers 		;AN000;
	push	cx				;				;AN000;
	push	dx				;				;AN000;
	push	si				;				;AN000;
	push	di				;				;AN000;
	push	bp				;				;AN000;
	push	es				;				;AN000;
	push	ds				;
	mov	si,data_ 			;				;AN000;
	mov	es,si				;				;AN000;

;	assume	es:data,ds:nothing		;				;AN000;

	mov	[es:Read_Write_Relative.Buffer_Offset],bx ;Get transfer buffer add;AN000;
	mov	bx,ds				;				;AN000;
	mov	[es:Read_Write_Relative.Buffer_Segment],bx ;Get segment		;AN000;
	mov	bx,data_ 			;Point DS at parameter list	;AN000;
	mov	ds,bx				;				;AN000;

;	assume	ds:data,es:data

	mov	[Read_Write_Relative.Number_Sectors],cx ;Number of sec to write	;AN000;
	mov	[Read_Write_Relative.Start_Sector_Low],dx ;Start sector		;AN000;
	mov	bx,Read_Write_Relative        ;				;AN000;
	mov	cx,0FFFFh			;Write relative sector		;AN000;
	INT	26h				;Do the write			;AN000;
	pop	dx				;Throw away flags on stack	;AN000;
	pop	ds				;				;AN000;
	pop	es				;				;AN000;
	pop	bp				;				;AN000;
	pop	di				;				;AN000;
	pop	si				;				;AN000;
	pop	dx				;Restore registers		;AN000;
	pop	cx				;				;AN000;
	pop	bx				;				;AN000;
	ret					;				;AN000;

;Write_Disk endp 				;				;AN000;

;=========================================================================
; Calc_Total_Addressible_Space	: Calculate the total space that is
;				  addressible on the the disk by DOS.
;
;	Inputs	: none
;
;	Outputs : Fdsksiz - Size in bytes of the disk
;=========================================================================

Procedure Calc_Total_Addressible_Space		;an013; dms;

	push	ax				;an013; dms;save affected regs
	push	dx				;an013; dms;
	push	bx				;an013; dms;

	call	Get_Free_Space			;an013; dms;get free disk space

	push	bx				;an013; dms;save avail. cluster
	push	dx				;an013; dms;save total. cluster

	mov	ax,dx				;an013; dms;get total clusters

	xor	bx,bx				;an013; dms;clear bx
	xor	cx,cx				;an013; dms;clear cx
	mov	cl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER] ;an013; dms;get total sectors
	call	Multiply_32_Bits		;an013; dms;multiply

	xor	cx,cx				;an013; dms;clear cx
	mov	cx,word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR] ;an013; dms;get total bytes
	call	Multiply_32_Bits		;an013; dms; multiply

	mov	word [fdsksiz],ax    ;an013; dms;save high word
	mov	word [fdsksiz+2],bx    ;an013; dms;save low word

	pop	dx				;an000; dms;get total clusters
	pop	bx				;an000; dms;get avail clusters

	mov	ax,dx				;an013; dms;get total clusters
	sub	ax,bx				;an013; dms;get bad clusters

	xor	bx,bx				;an013; dms;clear bx
	xor	cx,cx				;an013; dms;clear cx
	mov	cl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER] ;an013; dms;get total sectors
	call	Multiply_32_Bits		;an013; dms;multiply

	xor	cx,cx				;an013; dms;clear cx
	mov	cx,word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR] ;an013; dms;get total bytes
	call	Multiply_32_Bits		;an013; dms; multiply

	sub	ax,word [syssiz]    ;an013; dms;account for system
	sbb	bx,word [syssiz+2]    ;an013; dms;size

	mov	word [badsiz],ax    ;an013; dms;save high word
	mov	word [badsiz+2],bx    ;an013; dms;save low word

	pop	bx				;an013; dms;
	pop	dx				;an013; dms;restore regs
	pop	ax				;an013; dms;

	ret					;an013; dms;

;Calc_Total_Addressible_Space	endp		;an013; dms;


;=========================================================================
; Get_Free_Space	: Get the free space on the disk.
;
;	Inputs	: none
;
;	Outputs : BX - Available space in clusters
;		  DX - Total space in clusters
;=========================================================================

Procedure Get_Free_Space			;an013; dms;

	xor	ax,ax				;an013; dms;clear ax
	mov	ah,36h				;an013; dms;Get disk free space
	mov	dl,[driveLetter] ;an013; dms;get drive letter
	sub	dl,"A"				;an013; dms;get 0 based number
	inc	dl				;an013; dms;make it 1 based
	int	21h				;an013; dms;
	ret					;an013; dms;

;Get_Free_Space	endp				;an013; dms;

;=========================================================================
; Calc_System_Space	: This routine calculates the space occupied by
;			  the system on the disk.
;
;	Inputs	: DOS.FileSizeInBytes
;		  BIOS.FileSizeInBytes
;		  Command.FileSizeInBytes
;
;	Outputs : SysSiz			- Size of the system
;=========================================================================

Procedure Calc_System_Space							;an013; dms;

	push	ax								;an013; dms;save regs
	push	dx								;an013; dms;

	mov	word [syssiz+0],00h        ;an013; dms;clear variable
	mov	word [syssiz+2],00h        ;an013; dms;

	mov	ax,word [dos.fileSizeInBytes+0]        ;an013; dms;get low word
	mov	dx,word [dos.fileSizeInBytes+2]        ;an013; dms;get high word
	call	AddToSystemSize 						;an013; dms;add in values

	mov	ax,word [bios.fileSizeInBytes+0]        ;an013; dms;get bios size
	mov	dx,word [bios.fileSizeInBytes+2]        ;an013; dms;
	call	AddToSystemSize 						;an013; dms;add in values

	mov	ax,word [command.fileSizeInBytes+0]        ;an013; dms;get command size
	mov	dx,word [command.fileSizeInBytes+2]        ;an013; dms;
	call	AddToSystemSize 						;an013; dms;add in values

	pop	dx								;an013; dms;restore regs
	pop	ax								;an013; dms;

	ret									;an013; dms;

;Calc_System_Space	endp							;an013; dms;



end if
;	end
