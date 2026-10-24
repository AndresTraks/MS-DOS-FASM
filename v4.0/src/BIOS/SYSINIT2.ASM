	PAGE	,132			;
;	SCCSID = @(#)sysinit2.asm	1.13 85/10/15
TITLE	BIOS SYSTEM INITIALIZATION
;%OUT ...SYSINIT2

;==============================================================================
;REVISION HISTORY:
;AN000 - New for DOS Version 4.00 - J.K.
;AC000 - Changed for DOS Version 4.00 - J.K.
;AN00x - PTM number for DOS Version 4.00 - J.K.
;==============================================================================
;AN001; p132 Multiple character device installation problem.	    6/27/87 J.K.
;AN002; d24  MultiTrack= command added. 			    6/29/87 J.K.
;AN003; p29  Extra space character in parameters passed.
;	     (Modification on ORGANIZE routine for COMMENT= fixed this
;	      problem too)					    6/29/87 J.K.
;AN004; d41  REM command in CONFIG.SYS				    7/7/87  J.K.
;AN005; d184 Set DEVMARK for MEM command			    8/25/87 J.K.
;AN006; p1820 New Message SKL file				   10/20/87 J.K.
;AN007; p1821 Include the COPYRIGH.INC file			   10/22/87 J.K.
;AN008; p2210 IBMDOS returns incorrect DBCS vector table length    11/02/87 J.K.
;AN009; p2667 ccMono_Ptr problem				   11/30/87 J.K.
;AN010; p2792 Device?driver.sys /d:2 command should not work	   12/09/87 J.K.
;AN011; p3120 REM followed by CR, LF causes problem		   01/13/88 J.K.
;AN012; p3111 Take out the order dependency of the INSTALL=	   01/25/88 J.K.
;AN013; d479  New option to disable extended INT 16h function call 02/12/88 J.K.
;AN014; D486 SHARE installation for big media			   02/23/88 J.K.
;AN015; D526 Add /NC parameter when installing SHARE.EXE	   04/28/88 J.K.
;==============================================================================

TRUE	    EQU 0FFFFh
FALSE	    EQU 0
; fasm's EQU has to stand before the line that uses it, and the code
; below tests these; they were written down beside the switch list they
; go with, which is at the end of the module.  The list is still there.
switchnum	equ 11111000B		; which switches require number
flagec35	equ 00000100B		; electrically compatible 3.5 inch disk drive
flagdrive	equ 00001000B
flagcyln	equ 00010000B
flagseclim	equ 00100000B
flagheads	equ 01000000B
flagff		equ 10000000B
SWTCHR	    EQU     "/"             ; switch follows this character

LF	=	10
CR	=	13
TAB	=	 9

IBMVER	   EQU	   TRUE
IBM	   EQU	   IBMVER
STACKSW    EQU	   TRUE 		;Include Switchable Hardware Stacks
IBMJAPVER  EQU	   FALSE		;If TRUE set KANJI true also
MSVER	   EQU	   FALSE
ALTVECT    EQU	   FALSE		;Switch to build ALTVECT version
KANJI	   EQU	   FALSE

	if	IBMJAPVER
NOEXEC	EQU	TRUE
	else
NOEXEC	EQU	FALSE
	end if

DOSSIZE EQU	0A000H

;.xlist
;	INCLUDE dossym.INC
	INCLUDE '../INC/SMDOSSYM.INC'	;J.K. Reduced version of DOSSYM.INC
	INCLUDE '../INC/DEVSYM.INC'
	INCLUDE '../INC/IOCtl.INC'
	INCLUDE 'DEVMARK.INC'
;.list

	if	NOT IBM
	if	NOT IBMJAPVER
;	EXTRN	RE_INIT:FAR
	end if
	end if

;code segment public 'code'
;	extrn EC35_Flag: byte
;code ends

;SYSINITSEG	SEGMENT PUBLIC 'SYSTEM_INIT' BYTE

;ASSUME	CS:SYSINITSEG,DS:NOTHING,ES:NOTHING,SS:NOTHING

;	EXTRN	BADOPM:BYTE,CRLFM:BYTE,BADCOM:BYTE,BADMEM:BYTE,BADBLOCK:BYTE
;	EXTRN	BADSIZ_PRE:BYTE,BADLD_PRE:BYTE
;	 EXTRN	 BADSIZ_POST:BYTE,BADLD_POST:BYTE
;	EXTRN	SYSSIZE:BYTE,BADCOUNTRY:BYTE

;	EXTRN  dosinfo:dword,entry_point:dword,
;	EXTRN  MEMORY_SIZE:WORD,fcbs:byte,keep:byte
;	EXTRN  DEFAULT_DRIVE:BYTE,confbot:word,alloclim:word
;	EXTRN  BUFFERS:WORD,zero:byte,sepchr:byte
;	EXTRN  FILES:BYTE
;	EXTRN  count:word,chrptr:word
;	EXTRN  bufptr:byte,memlo:word,prmblk:byte,memhi:word
;	EXTRN  ldoff:word,area:word,PACKET:BYTE,UNITCOUNT:BYTE,
;	EXTRN  BREAK_ADDR:DWORD,BPB_ADDR:DWORD,drivenumber:byte
;	extrn  COM_Level:byte, CMMT:byte, CMMT1:byte, CMMT2:byte
;	extrn  Cmd_Indicator:byte
;	extrn  DoNotShowNum:byte
;	extrn  MultDeviceFlag:byte
;	extrn  DevMark_Addr:word			;AN005;
;	extrn  SetDevMarkFlag:byte			;AN005;
;	extrn  Org_Count:word				;AN012;

;	EXTRN  Stall:near
;	EXTRN  Error_Line:near

;	PUBLIC Int24,Open_Dev,Organize,Mem_Err,Newline,CallDev,Badload
;	PUBLIC PrnDev,AuxDev,Config,Commnd,Condev,GetNum,BadFil,PrnErr
;	PUBLIC Round,Delim,Print,Set_Break
;	PUBLIC SetParms, ParseLine, DiddleBack
;	PUBLIC Skip_delim,SetDOSCountryInfo,Set_Country_Path,Move_Asciiz
;	PUBLIC Cntry_Drv,Cntry_Root,Cntry_Path
;	PUBLIC Delim
;	public PathString				;AN014;
;	public LShare					;AN014;

;
; The following set of routines is used to parse the DRIVPARM = command in
; the CONFIG.SYS file to change the default drive parameters.
;
SetParms:
	push	ds
	push	ax
	push	bx
	push	cx
	push	dx
	push	cs
	pop	ds
;	ASSUME DS:SYSINITSEG
	xor	bx,bx
	mov	bl,byte [drive]
	inc	bl		    ; get it correct for IOCTL call (1=A,2=B...)
	mov	dx,DeviceParameters
	mov	ah, IOCtl
	mov	al, GENERIC_IOCTL
	mov	ch, RAWIO
	mov	cl, SET_DEVICE_PARAMETERS
	int	21H
	test	word [Switches], flagec35
	jz	Not_EC35

	mov	cl, byte [drive]	; which drive was this for?
	mov	ax, CODE		; get Code segment
	mov	ds, ax			; set code segment
;	assume ds:code
	mov	al, 1			; assume drive 0
	shl	al, cl			; set proper bit depending on drive
	or	[EC35_Flag], al	; set the bit in the permanent flags

Not_EC35:
	pop	dx			; fix up all the registers
	pop	cx
	pop	bx
	pop	ax
	pop	ds
;	assume ds:nothing
	ret

;
; Replace default values for further DRIVPARM commands
;
DiddleBack:
	push	ds
	push	cs
	pop	ds
;	assume	ds:sysinitseg
	mov	word [DeviceParameters+A_DEVICEPARAMETERS.DP_CYLINDERS],80
	mov	byte [DeviceParameters+A_DEVICEPARAMETERS.DP_DEVICETYPE], DEV_3INCH720KB
	mov	word [DeviceParameters+A_DEVICEPARAMETERS.DP_DEVICEATTRIBUTES],0
	mov	word [Switches],0	    ; zero all switches
	pop	ds
;	assume	ds:nothing
	ret

;
; Entry point is ParseLine. AL contains the first character in command line.
;
ParseLine:			    ; don't get character first time
	push	ds
	push	cs
	pop	ds
;	ASSUME	DS:SYSINITSEG
NextSwtch:
	cmp	al,CR			; carriage return?
	jz	done_line
	cmp	al,LF			; linefeed?
	jz	put_back		; put it back and done
; Anything less or equal to a space is ignored.
	cmp	al,' '                  ; space?
	jbe	get_next		; skip over space
	cmp	al,'/'
	jz	getparm
	stc			    ; mark error invalid-character-in-input
	jmp	short exitpl

getparm:
	call	Check_Switch
	mov	word [Switches],BX	     ; save switches read so far
	jc	swterr
get_next:
	invoke	GETCHR
	jc	done_line
	jmp	NextSwtch
swterr:
	jmp	exitpl		    ; exit if error

done_line:
	test	word [Switches],flagdrive  ; see if drive specified
	jnz	okay
	stc			    ; mark error no-drive-specified
	jmp	short exitpl

okay:
	mov	ax,word [Switches]
	and	ax,0003H	    ; get flag bits for changeline and non-rem
	mov	word [DeviceParameters+A_DEVICEPARAMETERS.DP_DEVICEATTRIBUTES],ax
	mov	word [DeviceParameters+A_DEVICEPARAMETERS.DP_TRACKTABLEENTRIES], 0
	clc			    ; everything is fine
	call	SetDeviceParameters
exitpl:
	pop	ds
	ret

put_back:
	inc	[COUNT_SYSINIT]			; one more char to scan
	dec	[CHRPTR]			; back up over linefeed
	jmp	short done_line
;
; Processes a switch in the input. It ensures that the switch is valid, and
; gets the number, if any required, following the switch. The switch and the
; number *must* be separated by a colon. Carry is set if there is any kind of
; error.
;
Check_Switch:
	invoke	GETCHR
	jc	err_check
	and	al,0DFH 	    ; convert it to upper case
	cmp	al,'A'
	jb	err_check
	cmp	al,'Z'
	ja	err_check
	push	es
	push	cs
	pop	es
	mov	cl,byte [switchlist]	     ; get number of valid switches
	mov	ch,0
	mov	di,1+switchlist	; point to string of valid switches
	repne	scasb
	pop	es
	jnz	err_check
	mov	ax,1
	shl	ax,cl		; set bit to indicate switch
	mov	bx,word [Switches]	 ; get switches so far
	or	bx,ax		; save this with other switches
	mov	cx,ax
	test	ax, switchnum	; test against switches that require number to follow
	jz	done_swtch
	invoke	GETCHR
	jc	err_swtch
	cmp	al,':'
	jnz	err_swtch
	invoke	GETCHR
	push	bx			; preserve switches
	mov	byte [cs:SepChr],' '          ; allow space separators
	call	GETNUM
	mov	byte [cs:SepChr],0
	pop	bx			; restore switches
; Because GetNum does not consider carriage-return or line-feed as OK, we do
; not check for carry set here. If there is an error, it will be detected
; further on (hopefully).
	call	Process_Num

done_swtch:
	clc
	ret

err_swtch:
	xor	bx,cx			; remove this switch from the records
err_check:
	stc
	ret

;
; This routine takes the switch just input, and the number following (if any),
; and sets the value in the appropriate variable. If the number input is zero
; then it does nothing - it assumes the default value that is present in the
; variable at the beginning. Zero is OK for form factor and drive, however.
;
Process_Num:
	test	word [Switches],cx	 ; if this switch has been done before,
	jnz	done_ret	    ; ignore this one.
	test	cx,flagdrive
	jz	try_f
	mov	byte [drive],al
	jmp	short done_ret

try_f:
	test	cx,flagff
	jz	try_t
; Ensure that we do not get bogus form factors that are not supported
	;cmp	al,Max_Dev_Type
	;ja	done_ret
	mov	byte [DeviceParameters+A_DEVICEPARAMETERS.DP_DEVICETYPE],al
	jmp	short done_ret

try_t:
	or	ax,ax
	jz	done_ret	    ; if number entered was 0, assume default value
	test	cx,flagcyln
	jz	try_s
	mov	word [DeviceParameters+A_DEVICEPARAMETERS.DP_CYLINDERS],ax
	jmp	short done_ret

try_s:
	test	cx,flagseclim
	jz	try_h
	mov	word [slim],ax
	jmp	short done_ret
;
; Must be for number of heads
try_h:
	mov	word [hlim],ax

done_ret:
	clc
	ret

;
; SetDeviceParameters sets up the recommended BPB in each BDS in the
; system based on the form factor. It is assumed that the BPBs for the
; various form factors are present in the BPBTable. For hard files,
; the Recommended BPB is the same as the BPB on the drive.
; No attempt is made to preserve registers since we are going to jump to
; SYSINIT straight after this routine.
;
SetDeviceParameters:
	push	es
	push	cs
	pop	es
;ASSUME ES:SYSINITSEG
	xor	bx,bx
	mov	bl,byte [DeviceParameters+A_DEVICEPARAMETERS.DP_DEVICETYPE]
	cmp	bl,DEV_5INCH
	jnz	Got_80
	mov	cx,40			; 48tpi has 40 cylinders
	mov	word [DeviceParameters+A_DEVICEPARAMETERS.DP_CYLINDERS],cx
Got_80:
	shl	bx,1			; get index into BPB table
	mov	si,BPBTable
	mov	si,word [si+bx]	; get address of BPB
Set_RecBPB:
	mov	di,DeviceParameters.DP_BPB	 ; es:di -> BPB
	mov	cx,sizeof.A_BPB
	cld
	repe	movsb
	pop	es
;ASSUME ES:NOTHING
	test	word [Switches],flagseclim
	jz	see_heads
	mov	ax,word [slim]
	mov	word [DeviceParameters+A_DEVICEPARAMETERS.DP_BPB+A_BPB.BPB_SECTORSPERTRACK],ax
see_heads:
	test	word [Switches],flagheads
	jz	Set_All_Done
	mov	ax,word [hlim]
	mov	word [DeviceParameters+A_DEVICEPARAMETERS.DP_BPB+A_BPB.BPB_HEADS],ax
;
; We need to set the media byte and the total number of sectors to reflect the
; number of heads. We do this by multiplying the number of heads by the number
; of 'sectors per head'. This is not a fool-proof scheme!!
;
	mov	cx,ax			; cx has number of heads
	dec	cl			; get it 0-based
	mov	ax,word [DeviceParameters+A_DEVICEPARAMETERS.DP_BPB+A_BPB.BPB_TOTALSECTORS]	; this is OK for two heads
	sar	ax,1			; ax contains # of sectors/head
	sal	ax,cl
	jc	Set_All_Done		; We have too many sectors - overflow!!
	mov	word [DeviceParameters+A_DEVICEPARAMETERS.DP_BPB+A_BPB.BPB_TOTALSECTORS],ax
; Set up correct Media Descriptor Byte
	cmp	cl,1
	mov	bl,0F0H
	mov	al,2			; AL contains sectors/cluster
	ja	Got_Correct_Mediad
	mov	bl,byte [DeviceParameters+A_DEVICEPARAMETERS.DP_BPB+A_BPB.BPB_MEDIADESCRIPTOR]
	je	Got_Correct_Mediad
; We have one head - OK for 48tpi medium
	mov	al,1			; AL contains sectors/cluster
	mov	ch,[DeviceParameters+A_DEVICEPARAMETERS.DP_DEVICETYPE]
	cmp	ch,DEV_5INCH
	jz	Dec_Mediad
	mov	bl,0F0H
	jmp	short Got_Correct_Mediad
Dec_Mediad:
	dec	bl			; adjust for one head
Got_Correct_Mediad:
	mov	byte [DeviceParameters+A_DEVICEPARAMETERS.DP_BPB+A_BPB.BPB_MEDIADESCRIPTOR],bl
	mov	byte [DeviceParameters+A_DEVICEPARAMETERS.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER],al
	clc
Set_All_Done:
	RET

;ASSUME DS:NOTHING, ES:NOTHING

NOCHAR1: STC
	 return

ORGANIZE:
	MOV	CX,[cs:COUNT_SYSINIT]
	JCXZ	NOCHAR1
	CALL	MAPCASE
	XOR	SI,SI
	MOV	DI,SI
	xor	ax,ax
	mov	[cs:COM_Level], 0

;ORG1:	 CALL	 GET			 ;SKIP LEADING CONTROL CHARACTERS
;	 CMP	 AL,' '
;	 JB	 ORG1
Org1:
	call	Skip_Comment		;AN000;
	jz	End_Commd_Line		;AN000; found a comment string and skipped.
	call	GET2			;AN000; Not a comment string. Then get a char.
	cmp	al, LF			;AN000;
	je	End_Commd_Line		;AN000; starts with a blank line.
	cmp	al, ' '                 ;AN000;
	jbe	Org1			;AN000; skip leading control characters
	jmp	Findit			;AN000;
End_Commd_Line: 			;AN000;
	stosb				;AN000; store line feed char in buffer for the LineCount.
	mov	[cs:COM_Level], 0		;AN000; reset the command level.
	jmp	Org1			;AN000;
Findit: 				;AN000;
	PUSH	CX
	PUSH	SI
	PUSH	DI
	MOV	BP,SI
	DEC	BP
	MOV	SI,COMTAB	;Prepare to search command table
	MOV	CH,0
FINDCOM:
	MOV	DI,BP
	MOV	CL,[SI]
	INC	SI
	JCXZ	NOCOM
	REPE	CMPSB
	LAHF
	ADD	SI,CX			;Bump to next position without affecting flags
	SAHF
	LODSB				;Get indicator letter
	JNZ	FINDCOM
	cmp	byte [es:di], CR	;AN011;The next char might be CR,LF
	je	GotCom0 		;AN011; such as in "REM",CR,LF case.
	cmp	byte [es:di], LF	;AN011;
	je	GotCom0 		;AN011;
	push	ax			;AN010;
	mov	al, byte [es:di]	;AN010;Now the next char. should be a delim.
	call	DELIM			;AN010;
	pop	ax			;AN010;
	jnz	FINDCOM 		;AN010;
GotCom0:
	POP	DI
	POP	SI
	POP	CX
	JMP	SHORT GOTCOM

NOCOM:
	POP	DI
	POP	SI
	POP	CX
	MOV	AL,'Z'
	stosb				;AN000; save indicator char.
Skip_Line:				;AN000;
	call	GET2			;AN000;
	cmp	al, LF			;AN000; skip this bad command line
	jne	Skip_Line		;AN000;
	jmp	End_Commd_Line		;AN000; handle next command line

GOTCOM: STOSB				;SAVE INDICATOR CHAR IN BUFFER
	mov	[cs:Cmd_Indicator], al	;AN000; save it for the future use.

ORG2:	CALL	GET2			;SKIP the commad name UNTIL DELIMITER
	cmp	al, LF			;AN011;
	je	Org21			;AN011;
	cmp	al, CR			;AN011;
	je	Org21			;AN011;
	CALL	DELIM			;
	JNZ	ORG2
	jmp	short	Org3		;AN011;
Org21:					;AN011;if CR or LF then
	dec	si			;AN011; undo SI, CX register
	inc	cx			;AN011;  and continue

;ORG4:	 CALL	 GET2
;	 call	 Delim			 ;J.K. 5/30/86. To permit "device=filename/p..." stuff.
;	 jz	 ORG_EXT		 ;J.K. 5/30/86
;Org4_Cont:
;	 STOSB
;	 CMP	 AL,' '
;	 JA	 ORG4
;	 CMP	 AL,10
;	 JZ	 ORG1
;
;	 MOV	 BYTE PTR ES:[DI-1],0

Org3:
	cmp	[cs:Cmd_Indicator], 'Y'      ;AN000; Comment= command?
	je	Get_Cmt_token		;AN000;
	cmp	[cs:Cmd_Indicator], 'I'      ;AN000; Install= command?
	je	Org_file		;AN000;
	cmp	[cs:Cmd_Indicator], 'D'      ;AN000; Device= command?
	je	Org_file		;AN000;
	cmp	[cs:Cmd_Indicator], 'J'      ;AN000; IFS= command?
	je	Org_file		;AN000;
	cmp	[cs:Cmd_Indicator], 'S'      ;AN000; Shell= is a special one!!!
	je	Org_file		;AN000;
	cmp	[cs:Cmd_Indicator], '1'      ;AN013; SWITCHES= command?
	je	Org_Switch		;AN013;
	jmp	Org4			;AN000;
Org_Switch:
	call	Skip_Comment		;AN013;
	jz	End_Commd_Line_Brdg	;AN013;
	call	GET2			;AN013;
	call	Org_Delim		;AN013;
	jz	Org_Switch		;AN013;
	stosb				;AN013;
	jmp	Org5			;AN013;
Org_file:				;AN000; Get the filename and put 0 at end,
	call	Skip_Comment		;AN000;
	jz	Org_Put_Zero		;AN000;
	call	GET2			;AN000; Not a comment
	call	DELIM			;AN000;
	jz	Org_file		;AN000; Skip the possible delimeters
	stosb				;AN000; copy the first non delim char found in buffer
Org_Copy_File:				;AN000;
	call	Skip_Comment		;AN000; comment char in the filename?
	jz	Org_Put_Zero		;AN000; then stop copying filename at that point
	call	GET2			;AN000;
	cmp	al, '/'                 ;AN000; a switch char? (device=filename/xxx)
	je	End_file_slash		;AN000; this will be the special case.
	stosb				;AN000; save the char. in buffer
	call	DELIM			;AN000;
	jz	End_Copy_File		;AN000;
	cmp	al, ' '                 ;AN000;
	ja	Org_Copy_File		;AN000; keep copying
	jmp	End_Copy_File		;AN000; otherwise, assume end of the filename.
Get_Cmt_token:				;AN000; get the token. Just max. 2 char.
	call	GET2			;AN000;
	cmp	al, ' '                 ;AN000; skip white spaces or "=" char.
	je	Get_Cmt_token		;AN000; (we are allowing the other special
	cmp	al, TAB 		;AN000;  charaters can used for comment id.
	je	Get_Cmt_token		;AN000;  character.)
	cmp	al, '='                 ;AN000; = is special in this case.
	je	Get_Cmt_token		;AN000;
	cmp	al, CR			;AN000;
	je	Get_Cmt_End		;AN000; cannot accept the carridge return
	cmp	al, LF			;AN000;
	je	Get_Cmt_End		;AN000;
	mov	[cs:CMMT1], al		;AN000; store it
	mov	[cs:CMMT], 1 		;AN000; 1 char. so far.
	call	GET2			;AN000;
	cmp	al, ' '                 ;AN000;
	je	Get_Cmt_End		;AN000;
	cmp	al, TAB 		;AN000;
	je	Get_Cmt_End		;AN000;
	cmp	al, CR			;AN000;
	je	Get_Cmt_End		;AN000;
	cmp	al, LF			;AN000;
	je	End_Commd_Line_Brdg	;AN000;
	mov	[cs:CMMT2], al		;AN000;
	inc	[cs:CMMT]			;AN000;
Get_Cmt_End:				;AN000;
	call	GET2			;AN000;
	cmp	al, LF			;AN000;
	jne	Get_Cmt_End		;AN000; skip it.
End_Commd_Line_Brdg: jmp End_Commd_Line ;AN000; else jmp to End_Commd_Line

Org_Put_Zero:				;AN000; Make the filename in front of
	mov	byte [es:di], 0	;AN000;  the comment string to be an asciiz.
	inc	di			;AN000;
	jmp	End_Commd_Line		;AN000;  (Maybe null if device=/*)
End_file_slash: 			;AN000; AL = "/" option char.
	mov	byte [es:di],0	;AN000; make a filename an asciiz
	inc	di			;AN000; and
	stosb				;AN000; store "/" after that.
	jmp	Org5			;AN000; continue with the rest of the line

End_Copy_File:				;AN000;
	mov	byte [es:di-1], 0	;AN000; make it an asciiz and handle the next char.
	cmp	al, LF			;AN000;
	je	End_Commd_Line_Brdg	;AN000;
	jmp	Org5			;AN000;

Org4:					;AN000; Org4 skips all delimiters after the command name except for '/'
	call	Skip_Comment		;AN000;
	jz	End_Commd_Line_Brdg	;AN000;
	call	GET2			;AN000;
	call	Org_Delim		;AN000; skip delimiters EXCEPT '/' (mrw 4/88)
	jz	Org4			;AN000;
	jmp	Org51			;AN000;
Org5:					;AN000; rest of the line
	call	Skip_Comment		;AN000; Comment?
	jz	End_Commd_Line_Brdg	;AN000;
	call	GET2			;AN000; Not a comment.
Org51:					;AN000;
	stosb				;AN000; copy the character
	cmp	al, '"'                 ;AN000; a quote ?
	je	At_Quote		;AN000;
	cmp	al, ' '                 ;AN000;
	ja	Org5			;AN000;
	cmp	al, LF			;AN000; line feed?
	je	Org1_brdg		;AN000; handles the next command line.
	jmp	Org5			;AN000; handles next char in this line.
Org1_brdg: jmp	 Org1			;AN000;
At_Quote:				;AN000;
	cmp	[cs:COM_Level], 0		;AN000;
	je	Up_Level		;AN000;
	mov	[cs:COM_Level], 0		;AN000; reset it.
	jmp	Org5			;AN000;
Up_Level:				;AN000;
	inc	[cs:COM_Level]		;AN000; set it.
	jmp	Org5			;AN000;


;ORG5:	 CALL	 GET2
;	 STOSB
;	 CMP	 AL,10
;	 JNZ	 ORG5
;	 JMP	 ORG1
;
;ORG_EXT:
;	 cmp	 al,' '                  ;space?
;	 je	 Org4_Cont		 ;then do not make an exception. Go back.
;	 cmp	 al,9			 ;Tab?
;	 je	 Org4_Cont
;	 mov	 byte ptr es:[di], 0	 ;put 0 at the current DI to make it an ASCIIZ
;	 inc	 DI			 ;
;	 stosb				 ;and copy the delimeter char.
;	 jmp	 short ORG5		 ;and continue as usual.


GET2:
	JCXZ	NOGET
	MOV	AL,[es:SI]
	INC	SI
	DEC	CX
	return

;GET:	 JCXZ	 NOGET
;	 MOV	 AL,ES:[SI]
;	 INC	 SI
;	 DEC	 CX
;	 CALL	 Org_DELIM
;	 JZ	 GET
;	 return

Skip_Comment:
;J.K.Skip the commented string until LF, if current es:si-> a comment string.
;J.K.In) ES:SI-> sting
;J.K.	 CX -> length.
;J.K.Out) Zero flag not set if not found a comment string.
;J.K.	  Zero flag set if found a comment string and skipped it. AL will contain
;J.K.	  the line feed charater at this moment when return.
;J.K.	  AX register destroyed.
;J.K.	  If found, SI, CX register adjusted accordingly.

	jcxz	NOGET		;AN000; Get out of the Organize routine.
	cmp	[cs:COM_Level], 0	;AN000; only check it if parameter level is 0.
	jne	No_Commt	;AN000;  (Not inside quotations)

	cmp	[cs:CMMT], 1 	;AN000;
	jb	No_Commt	;AN000;
	mov	al, [es:si]	;AN000;
	cmp	[cs:CMMT1], al	;AN000;
	jne	No_Commt	;AN000;
	cmp	[cs:CMMT], 2 	;AN000;
	jne	Skip_Cmmt	;AN000;
	mov	al, [es:si+1]	;AN000;
	cmp	[cs:CMMT2], al	;AN000;
	jne	No_Commt	;AN000;
Skip_Cmmt:			;AN000;
	jcxz	NOGET		;AN000; get out of Organize routine.
	mov	al, [es:si]	;AN000;
	inc	si		;AN000;
	dec	cx		;AN000;
	cmp	al, LF		;AN000; line feed?
	jne	Skip_Cmmt	;AN000;
No_Commt:			;AN000;
	ret			;AN000;


DELIM:
	CMP	AL,'/'          ;J.K. 5/30/86. IBM will assume "/" as an delimeter.
	RETZ
	cmp	al, 0		;J.K. 5/23/86 Special case for sysinit!!!
	RETZ
Org_Delim:			;AN000;  Used by Organize routine except for getting
	CMP	AL,' '          ;the filename.
	RETZ
	CMP	AL,9
	RETZ
	CMP	AL,'='
	RETZ
	CMP	AL,','
	RETZ
	CMP	AL,';'
	return


NOGET:	POP	CX
	MOV	[cs:COUNT_SYSINIT],DI
	mov	[cs:Org_Count], DI	;AN012;
	XOR	SI,SI
	MOV	[cs:CHRPTR],SI
	return

;Get3:	 jcxz	 NOGET		 ;J.K.do not consider '/',',' as a delim.
;	 mov	 al, es:[si]
;	 inc	 si
;	 dec	 cx
;	 call	 DELIM
;	 jnz	 Get3_ret
;	 cmp	 al,'/'
;	 je	 Get3_ret
;	 cmp	 al,','
;	 jne	 Get3
;Get3_ret:
;	 ret



;
;  NEWLINE RETURNS WITH FIRST CHARACTER OF NEXT LINE
;
NEWLINE:invoke	GETCHR			;SKIP NON-CONTROL CHARACTERS
	retc
	CMP	AL,LF			;LOOK FOR LINE FEED
	JNZ	NEWLINE
	invoke	GETCHR
	return

MAPCASE:
	PUSH	CX
	PUSH	SI
	PUSH	DS
	PUSH	ES
	POP	DS
	XOR	SI,SI
CONVLOOP:
	LODSB

	if	KANJI
	CALL	TESTKANJ
	JZ	NORMCONV
	INC	SI			;Skip next char
	DEC	CX
	JCXZ	CONVDONE		;Just ignore 1/2 kanji error
;Fall through, know AL is not in 'a'-'z' range
NORMCONV:
	end if

	CMP	AL,'a'
	JB	NOCONV
	CMP	AL,'z'
	JA	NOCONV
	SUB	AL,20H
	MOV	[SI-1],AL
NOCONV:
	LOOP	CONVLOOP
CONVDONE:
	POP	DS
	POP	SI
	POP	CX
	return

	if	KANJI
TESTKANJ:
	CMP	AL,81H
	JB	NOTLEAD
	CMP	AL,9FH
	JBE	ISLEAD
	CMP	AL,0E0H
	JB	NOTLEAD
	CMP	AL,0FCH
	JBE	ISLEAD
NOTLEAD:
	PUSH	AX
	XOR	AX,AX			;Set zero
	POP	AX
	return

ISLEAD:
	PUSH	AX
	XOR	AX,AX			;Set zero
	INC	AX			;Reset zero
	POP	AX
	return
	end if

;ASSUME DS:NOTHING

Yes_Break_Failed:			;device driver Init failed and aborted.
	stc
	pop	ax
	return

SET_BREAK:
;J.K. 8/14/86  For DOS 3.3, this routine is modified to take care of the
;Device driver's initialization error and abort.
;If [break_addr+2] == [memhi] && [break_addr] = 0 then assume
;that the device driver's initialization has an error and wanted to
;abort the device driver.  In this case, this routine will set carry
;and return to the caller.
;J.K. 6/26/87 If MultDeviceFlag <> 0, then do not perform the check.
;This is to allow the multiple character device driver which uses
;the same ending address segment with the offset value 0 for each
;of the drives.

	PUSH	AX
	MOV	AX,word [cs:BREAK_ADDR+2]  ;REMOVE THE INIT CODE
	cmp	[cs:MultDeviceFlag], 0	    ;AN001;
	jne	Set_Break_Continue	    ;AN001;Do not check it.
	cmp	ax, [cs:MEMHI]
	jne	Set_Break_Continue	    ;if not same, then O.K.

	cmp	word [cs:BREAK_ADDR],0
	je	Yes_Break_Failed	    ;[Break_addr+2]=[MEMHI] & [Break_addr]=0

Set_Break_Continue:
	MOV	[cs:MEMHI],AX
	MOV	AX,word [cs:BREAK_ADDR]
	MOV	[cs:MEMLO],AX
	POP	AX			    ; NOTE FALL THROUGH
	or	[cs:SetDevMarkFlag], SETBRKDONE	;AN005; Signal the successful Set_break

;
; Round the values in MEMLO and MEMHI to paragraph boundary.
; Perform bounds check.
;
ROUND:
	PUSH	AX
	MOV	AX,[cs:MEMLO]

	invoke	ParaRound		; para round up

	ADD	[cs:MEMHI],AX
	MOV	[cs:MEMLO],0
	mov	ax,[cs:MEMHI]		; ax = new memhi
	CMP	AX,[cs:ALLOCLIM]		; if new memhi >= alloclim, error
	JAE	MEM_ERR
	test	[cs:SetDevMarkFlag], FOR_DEVMARK	    ;AN005;
	jz	Skip_Set_DEVMARKSIZE			;AN005;
	push	es					;AN005;
	push	si					;AN005;
	mov	si, [cs:DevMark_Addr]			;AN005;
	mov	es, si					;AN005;
	sub	ax, si					;AN005;
	dec	ax					;AN005;
	mov	[es:DEVMARK.DEVMARK_SIZE], ax			;AN005; Paragraph
	and	[cs:SetDevMarkFlag], NOT_FOR_DEVMARK	    ;AN005;
	pop	si					;AN005;
	pop	es					;AN005;
Skip_Set_DEVMARKSIZE:					;AN005;
	POP	AX
	clc				;clear carry
	return

MEM_ERR:
	MOV	DX,BADMEM
	PUSH	CS
	POP	DS
	CALL	PRINT
	JMP	STALL

CALLDEV:MOV	DS,word [cs:ENTRY_POINT+2]
	ADD	BX,word [cs:ENTRY_POINT]	;Do a little relocation
	MOV	AX,[BX]
	PUSH	word [cs:ENTRY_POINT]
	MOV	word [cs:ENTRY_POINT],AX
	MOV	BX,PACKET
	CALL	dword [cs:ENTRY_POINT]
	POP	word [cs:ENTRY_POINT]
	return

BADNUM:
	MOV	[cs:SepChr],0
	XOR	AX,AX		; Set Zero flag, and AX = 0
	pop	bx		; J.K.
	stc			; AND carry set
	return

ToDigit:
	SUB	AL,'0'
	JB	NotDig
	CMP	AL,9
	JA	NotDig
	CLC
	return
NotDig: STC
	return

; GetNum parses a decimal number.
; Returns it in AX, sets zero flag if AX = 0 (MAY BE considered an
; error), if number is BAD carry is set, zero is set, AX=0.
GETNUM: push	bx			; J.K.
	XOR	BX,BX			; running count is zero
B2:	CALL	ToDigit 		; do we have a digit
	JC	BADNUM			; no, bomb
	XCHG	AX,BX			; put total in AX
	PUSH	BX			; save digit
	MOV	BX,10			; base of arithmetic
	MUL	BX			; shift by one decimal di...
	POP	BX			; get back digit
	ADD	AL,BL			; get total
	ADC	AH,0			; make that 16 bits
	JC	BADNUM			; too big a number
	XCHG	AX,BX			; stash total

	invoke	GETCHR			;GET NEXT DIGIT
	JC	B1			; no more characters
	cmp	al, ' '                 ;J.K. 5/23/86 space?
	jz	b15			;J.K. 5/23/86 then end of digits
	cmp	al, ','                 ;J.K. 5/23/86 ',' is a seperator!!!
	jz	b15			;J.K. 5/23/86 then end of digits.
	cmp	al, TAB 		;J.K. 5/23/86 TAB
	jz	b15			;J.K.
	CMP	AL,[cs:SepChr]		; allow 0 or special separators
	JZ	b15
	cmp	al,SWTCHR		; See if another switch follows
	JZ	b15
	cmp	al,LF			; Line-feed?
	jz	b15
	cmp	al,CR			; Carriage return?
	jz	b15
	OR	AL,AL			; end of line separator?
	JNZ	B2			; no, try as a valid char...
b15:	INC	[cs:COUNT_SYSINIT]			; one more character to s...
	DEC	[cs:CHRPTR]			; back up over separator
B1:	MOV	AX,BX			; get proper count
	OR	AX,AX			; Clears carry, sets Zero accordingly
	pop	bx
	return

SKIP_DELIM:				;J.K.
;Skip the delimeters pointed by CHRPTR.  AL will contain the first non delimeter
;character encountered and CHRPTR will point to the next character.
;This rouitne will assume the second "," found as a non delimiter character. So
;in case if the string is " , , ", this routine will stop at the second ",". At
;this time, Zero flag is set.
;If COUNT is exhausted, then carry will be set.
Skip_delim_char:
	call	GETCHR
	jc	Skip_delim_exit
	cmp	al, ','                 ;the first comma?
	je	Skip_delim_next
	call	DELIM			;check the charater in AL.
	jz	Skip_delim_char
	jmp	short Skip_delim_exit	;found a non delim char
Skip_delim_next:
	call	GETCHR
	jc	Skip_delim_exit
	cmp	al, ','                 ;the second comma?
	je	Skip_delim_exit 	;done
	call	DELIM
	jz	Skip_delim_next
Skip_delim_exit:
	return
;SKIP_DELIM	endp

;J.K. 5/26/86 *****************************************************************
SetDOSCountryInfo:
;Input: ES:DI -> pointer to DOS_COUNTRY_CDPG_INFO
;	DS:0  -> buffer.
;	SI = 0
;	AX = country id
;	DX = code page id. (If 0, then use ccSysCodePage as a default.)
;	BX = file handle
;	This routine can handle maxium 72 COUNTRY_DATA entries.
;Output: DOS_country_cdpg_info set.
;	 Carry set if any file read failure or wrong information in the file.
;	 Carry set and CX = -1 if cannot find the matching COUNTRY_id, CODEPAGE
;	 _id in the file.

	push	di
	push	ax
	push	dx

	xor	cx,cx
	xor	dx,dx
	mov	ax, 512 		;read 512 bytes
	call	ReadInControlBuffer	;Read the file header
	jc	SetDOSData_fail
	push	es
	push	si
	push	cs
	pop	es
	mov	di, COUNTRY_FILE_SIGNATURE
	mov	cx, 8			;length of the signature
	repz	cmpsb
	pop	si
	pop	es
	jnz	SetDOSData_fail 	;signature mismatch

	add	si, 18			;SI -> county info type
	cmp	byte [si], 1	;Only accept type 1 (Currently only 1 header type)
	jne	SetDOSData_fail 	;cannot proceed. error return
	inc	si			;SI -> file offset
	mov	dx, word [si]	;Get the INFO file offset.
	mov	cx, word [si+2]
	mov	ax, 1024		;read 1024 bytes.
	call	ReadInControlBuffer	;Read INFO
	jc	SetDOSData_fail
	mov	cx, word [si]	;get the # of country, codepage combination entries
	cmp	cx, 72			;cannot handle more than 72 entries.
	ja	SetDOSData_fail
	inc	si
	inc	si			;SI -> entry information packet
	pop	dx			;restore code page id
	pop	ax			;restore country id
	pop	di

SetDOSCntry_find:			;Search for desired country_id,codepage_id.
	cmp	ax, word [si+2]	;compare country_id
	jne	SetDOSCntry_next
	cmp	dx, 0			;No user specified code page ?
	je	SetDOSCntry_any_CodePage;then no need to match code page id.
	cmp	dx, word [si+4]	;compare code page id
	je	SetDOSCntry_got_it
SetDOSCntry_next:
	add	si, word [si]	;next entry
	inc	si
	inc	si			;take a word for size of entry itself
	loop	SetDOSCntry_find
	mov	cx, -1			;signals that bad country id entered.
SetDOSCntry_fail:
	stc
	ret

SetDOSData_fail:
	pop	si
	pop	cx
	pop	di
	jmp	short	SetDOSCntry_fail

SetDOSCntry_any_CodePage:		;use the code_page_id of the country_id found.
	mov	dx, word [si+4]
SetDOSCntry_got_it:			;found the matching entry
	mov	[cs:CntryCodePage_Id], dx ;save code page ID for this country.
	mov	dx, word [si+10] ;get the file offset of country data
	mov	cx, word [si+12]
	mov	ax, 512 		;read 512 bytes
	call	ReadInControlBuffer
	jc	SetDOSCntry_fail
	mov	cx, word [si]	;get the number of entries to handle.
	inc	si
	inc	si			;SI -> first entry

SetDOSCntry_data:
	push	di			;ES:DI -> DOS_COUNTRY_CDPG_INFO
	push	cx			;save # of entry left
	push	si			;si -> current entry in Control buffer

	mov	al, byte [si+2]	;get data entry id
	call	GetCountryDestination	;get the address of destination in ES:DI
	jc	SetDOSCntry_data_next	;No matching data entry id in DOS


	mov	dx, word [si+4]	;get offset of data
	mov	cx, word [si+6]
	mov	ax, 4200h
	stc
	int	21h			;move pointer
	jc	SetDOSData_fail
	mov	dx, 512 		;start of data buffer
;	 mov	 cx, word ptr es:[di]	 ;length of the corresponding data in DOS.
;	 add	 cx, 10 		 ;Signature + A word for the length itself
	mov	cx, 20			;read 20 bytes only. We only need to
	mov	ah, 3fh 		;look at the length of the data in the file.
	stc
	int	21h			;read the country.sys data
	jc	SetDOSData_fail 	;read failure
	cmp	ax, cx
	jne	SetDOSData_fail

	mov	dx, word [si+4]	;AN008;get offset of data again.
	mov	cx, word [si+6]	;AN008;
	mov	ax, 4200h		;AN008;
	stc				;AN008;
	int	21h			;AN008;move pointer back again
	jc	SetDOSData_fail 	;AN008;

	push	si			;AN008;
	mov	si, (512+8)		;AN008;get length of the data from the file
	mov	cx, word [si]	;AN008;
	pop	si			;AN008;
	mov	dx, 512 		;AN008;start of data buffer
	add	cx, 10			;AN008;Signature + A word for the length itself
	mov	ah, 3fh 		;AN008;Read the data from the file.
	stc				;AN008;
	int	21h			;AN008;
	jc	SetDOSData_fail 	;AN008;
	cmp	ax, cx			;AN008;
	jne	SetDOSData_fail 	;AN008;

	mov	al, byte [si+2]	;save Data id for future use.
	mov	si, (512+8)		;SI-> data buffer + id tag field
	mov	cx, word [si]	;get the length of the file
	inc	cx			;Take care of a word for lenght of tab
	inc	cx			;itself.
	cmp	cx, (2048 - 512 - 8)	;Fit into the buffer?
	ja	SetDOSData_fail
	cmp	al, SetCountryInfo	;is the data for SetCountryInfo table?
	jne	SetDOSCntry_Mov 	;no, don't worry
	push	word [es:di+DOS_country_cdpg_info.ccMono_Ptr-DOS_country_cdpg_info.ccCountryInfoLen]	;AN009;Cannot destroy ccMono_ptr address. Save them.
	push	word [es:di+DOS_country_cdpg_info.ccMono_Ptr-DOS_country_cdpg_info.ccCountryInfoLen+2]	;AN009;At this time DI -> ccCountryInfoLen
	push	di			;save DI

	push	ax
	mov	ax,[cs:CntryCodePage_Id]	;Do not use the Code Page info in Country_Info
	mov	[si+4], ax		;Use the saved one for this !!!!
	pop	ax

SetDOSCntry_Mov:
	rep	movsb			;copy the table into DOS
	cmp	al, SetCountryInfo	;was the ccMono_ptr saved?
	jne	SetDOSCntry_data_next
	pop	di			;restore DI
	pop	word [es:di+DOS_country_cdpg_info.ccMono_Ptr-DOS_country_cdpg_info.ccCountryInfoLen+2]	 ;AN009;restore
	pop	word [es:di+DOS_country_cdpg_info.ccMono_Ptr-DOS_country_cdpg_info.ccCountryInfoLen]	 ;AN009;

SetDOSCntry_data_next:
	pop	si			;restore control buffer pointer
	pop	cx			;restore # of entries left
	pop	di			;restore pointer to DSO_COUNTRY_CDPG
	add	si, word [si]	;try to get the next entry
	inc	si
	inc	si			;take a word of entry length itself
;	 loop	 SetDOSCntry_data
	dec	cx			;AN008;
	cmp	cx,0			;AN008;
	je	SetDOSCntry_OK		;AN008;
	jmp	SetDOSCntry_data	;AN008;
SetDOSCntry_OK: 			;AN008;
	ret
;SetDOSCountryInfo	endp
;

GetCountryDestination:
;Get the destination address in the DOS country info table.
;Input: AL - Data ID
;	ES:DI -> DOS_COUNTRY_CDPG_INFO
;On return:
;	ES:DI -> Destination address of the matching data id
;	carry set if no matching data id found in DOS.

	push	cx
	add	di, DOS_country_cdpg_info.ccNumber_of_entries ;skip the reserved area, syscodepage etc.
	mov	cx, word [es:di]	;get the number of entries
	inc	di
	inc	di			;SI -> the first start entry id
GetCntryDest:
	cmp	byte [es:di], al
	je	GetCntryDest_OK
	cmp	byte [es:di], SetCountryInfo ;was it SetCountryInfo entry?
	je	GetCntryDest_1
	add	di, 5			;next data id
	jmp	short GetCntryDest_loop
GetCntryDest_1:
	add	di, NEW_COUNTRY_SIZE + 3 ;next data id
GetCntryDest_loop:
	loop	GetCntryDest
	stc
	jmp	short	GetCntryDest_Exit
GetCntryDest_OK:
	cmp	al, SetCountryInfo	;select country info?
	jne	GetCntryDest_OK1
	inc	di			;now DI -> ccCountryInfoLen
	jmp	short	GetCntryDest_Exit
GetCntryDest_OK1:
	les	di, dword [es:di+1] ;get the destination in ES:DI
GetCntryDest_Exit:
	pop	cx
	ret
;GetCountryDestination	endp

;
ReadInControlBuffer:
;Move file pointer to CX:DX
;Read AX bytes into the control buffer. (Should be less than 2 Kb)
;SI will be set to 0 hence DS:SI points to the control buffer.
;Entry:  CX,DX offset from the start of the file where the read/write pointer
;	 be moved.
;	 AX - # of bytes to read
;	 BX - file handle
;	 DS - buffer seg.
;Return: The control data information is read into DS:0 - DS:0200.
;	 CX,DX value destroyed.
;	 Carry set if error in Reading file.
;
	push	ax			;# of bytes to read
	mov	ax, 4200h
	stc
	int	21h			;move pointer
	pop	cx			;# of bytes to read
	jc	RICB_exit
	xor	dx,dx			;ds:dx -> control buffer
	xor	si,si
	mov	ah,3fh			;read into the buffer
	stc
	int	21h			;should be less than 1024 bytes.
RICB_exit:
	ret
;ReadInControlBuffer	endp

;
SET_COUNTRY_PATH:
;In:  DS - SYSINITSEG, ES - CONFBOT, SI -> start of the asciiz path string
;     DOSINFO_EXT, CNTRY_DRV, CNTRY_ROOT, CNTRY_PATH
;     Assumes current directory is the ROOT directory.
;Out: DS:DI -> full path (CNTRY_DRV).
;     Set the CNTRY_DRV string from the COUNTRY=,,path command.
;     DS, ES, SI value saved.

	push	si
	push	ds			;switch ds, es
	push	es
	pop	ds
	pop	es			;now DS -> CONFBOT, ES -> SYSINITSEG

	call	CHK_DRIVE_LETTER	;current DS:[SI] is a drive letter?
	jc	SCP_Default_drv 	;no, use current default drive.
	mov	al, byte [SI]
	inc	si
	inc	si			;SI -> next char after ":"
	jmp	short SCP_SetDrv
SCP_Default_drv:
	mov	ah, 19h
	int	21h
	add	al, "A"                 ;convert it to a character.
SCP_SetDrv:
	mov	[cs:CNTRY_DRV], al	;set the drive letter.
	mov	di, CNTRY_PATH
	mov	al, byte [SI]
	cmp	al, "\"
	je	SCP_Root_Dir
	cmp	al, [cs:SWTCHR]		;let's accept "/" as an directory delim
	je	SCP_Root_Dir
	jmp	short SCP_Path
SCP_Root_Dir:
	dec	di			;DI -> CNTRY_ROOT
SCP_Path:
	call	MOVE_ASCIIZ		;copy it
	mov	di, CNTRY_DRV
SCPath_Exit:
	push	ds			;switch ds, es
	push	es
	pop	ds
	pop	es			;DS, ES value restored
	pop	si
	RET
;SET_COUNTRY_PATH	endp

;
CHK_DRIVE_LETTER:
;Check if DS:[SI] is a drive letter followed by ":".
;Assume that every alpha charater is already converted to UPPER CASE.
;Carry set if not.
;
	push	ax
	cmp	byte [si], "A"
	jb	CDLetter_NO
	cmp	byte [si], "Z"
	ja	CDLetter_NO
	cmp	byte [si+1], ":"
	jne	CDLetter_NO
	jmp	short CDLetter_exit
CDLetter_NO:
	stc
CDLetter_exit:
	pop	ax
	ret
;CHK_DRIVE_LETTER	endp

;
MOVE_ASCIIZ:
;In: DS:SI -> source ES:DI -> target
;Out: copy the string until 0.
;Assumes there exists a 0.
MASCIIZ_loop:
	movsb
	cmp	byte [SI-1], 0	;Was it 0?
	jne	MASCIIZ_loop
	ret
;MOVE_ASCIIZ	endp

;
;	DS:DX POINTS TO STRING TO OUTPUT (ASCIZ)
;
;	PRINTS <BADLD_PRE> <STRING> <BADLD_POST>
;
;
;
BADFIL:
	PUSH	CS
	POP	ES
	MOV	SI,DX
BADLOAD:
	MOV	DX,BADLD_PRE	;WANT TO PRINT CONFIG ERROR
;	 MOV	 BX,OFFSET BADLD_POST
	mov	bx, CRLFM	;AN006;
PRNERR:
	PUSH	CS
	POP	DS
	call	PRINT
PRN1:	MOV	DL,[es:SI]
	OR	DL,DL
	JZ	PRN2
	MOV	AH,Std_Con_Output
	INT	21H
	INC	SI
	JMP	PRN1
PRN2:	MOV	DX,BX
	call	PRINT
	cmp	[cs:DoNotShowNum], 1 	;AN000;  suppress line number when handling COMMAND.COM
	je	PRNEXIT
	call	Error_Line
PRNEXIT:
	return

PRINT:	MOV	AH,Std_Con_String_Output
	INT	21H
	return


	if	NOEXEC
;
; LOAD NON EXE FILE CALLED [DS:DX] AT MEMORY LOCATION ES:BX
;
LDFIL:
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
	PUSH	DS
	PUSH	BX
	XOR	AX,AX			;OPEN THE FILE
	MOV	AH,Open
	STC				;IN CASE OF INT 24
	INT	21H
	POP	DX			;Clean stack in case jump
	JC	LDRET
	PUSH	DX
	MOV	BX,AX			;Handle in BX
	XOR	CX,CX
	XOR	DX,DX
	MOV	AX,(LSeek SHL 8) OR 2
	STC				;IN CASE OF INT 24
	INT	21H			; Get file size in DX:AX
	JC	LDCLSP
	OR	DX,DX
	JNZ	LDERRP			; File >64K
	POP	DX
	PUSH	DX
	MOV	CX,ES			; CX:DX is xaddr
	ADD	DX,AX			; Add file size to Xaddr
	JNC	DOSIZE
	ADD	CX,1000H		; ripple carry
DOSIZE:
	mov	ax,dx
	call	ParaRound
	mov	dx,ax

	ADD	CX,DX
	CMP	CX,[cs:ALLOCLIM]
	JB	OKLD_SYSINIT2
	JMP	MEM_ERR

OKLD_SYSINIT2:				; SYSINIT1 has an OKLD of its own
	XOR	CX,CX
	XOR	DX,DX
	MOV	AX,LSeek SHL 8		;Reset pointer to beginning of file
	STC				;IN CASE OF INT 24
	INT	21H
	JC	LDCLSP
	POP	DX
	PUSH	ES			;READ THE FILE IN
	POP	DS			;Trans addr is DS:DX
	MOV	CX,0FF00H		; .COM files arn't any bigger than
					; 64k-100H
	MOV	AH,Read
	STC				;IN CASE OF INT 24
	INT	21H
	JC	LDCLS
	MOV	SI,DX			;CHECK FOR EXE FILE
	CMP	word [SI],"ZM"
	CLC				; Assume OK
	JNZ	LDCLS			; Only know how to do .COM files
	STC
	JMP	SHORT LDCLS

LDERRP:
	STC
LDCLSP:
	POP	DX			;Clean stack
LDCLS:
	PUSHF
	MOV	AH,Close		;CLOSE THE FILE
	STC
	INT	21H
	POPF

LDRET:	POP	DS
	POP	SI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	return
	end if

;
;  OPEN DEVICE POINTED TO BY DX, AL HAS ACCESS CODE
;   IF UNABLE TO OPEN DO A DEVICE OPEN NULL DEVICE INSTEAD
;
OPEN_DEV:
	CALL	OPEN_FILE
	JNC	OPEN_DEV3
OPEN_DEV1:
	MOV	DX,NULDEV
	CALL	OPEN_FILE
	return

OPEN_DEV3:
	MOV	BX,AX			; Handle from open to BX
	XOR	AX,AX			; GET DEVICE INFO
	MOV	AH,IOCtl
	INT	21H
	TEST	DL,10000000B
	retnz
	MOV	AH,Close
	INT	21H
	JMP	OPEN_DEV1

OPEN_FILE:
	MOV	AH,Open
	STC
	INT	21H
	return

;J.K. TEST INT24. Return back to DOS with the fake user response of "FAIL"
INT24:
	mov	al, 3			;AN000; Fail the system call
	iret				;AN000; Return back to DOS.


;INT24:  ADD	 SP,6			 ;RESTORE MACHINE STATE
;	 POP	 AX
;	 POP	 BX
;	 POP	 CX
;	 POP	 DX
;	 POP	 SI
;	 POP	 DI
;	 POP	 BP
;	 POP	 DS
;	 POP	 ES
;	 PUSH	 AX
;	 MOV	 AH,GET_DEFAULT_DRIVE	 ;INITIALIZE DOS
;	 INT	 21H
;	 POP	 AX
;	 IRET				 ;BACK TO USER

	if	ALTVECT
BOOTMES DB	13,10,"MS-DOS version "
	DB	MAJOR_VERSION + "0"
	DB	"."
	DB	(MINOR_VERSION / 10) + "0"
	DB	(MINOR_VERSION MOD 10) + "0"
	DB	13,10
	DB	"Copyright 1981,88 Microsoft Corp.",13,10,"$"
	end if

INCLUDE '../INC/COPYRIGH.INC'			;P1821; Copyright statement

NULDEV	DB	"NUL",0
CONDEV	DB	"CON",0
AUXDEV	DB	"AUX",0
PRNDEV	DB	"PRN",0

CONFIG	DB	"\CONFIG.SYS",0

CNTRY_DRV   DB	  "A:"
CNTRY_ROOT  DB	  "\"
CNTRY_PATH  DB	  "COUNTRY.SYS",0
	    DB	  52 DUP (0)

COUNTRY_FILE_SIGNATURE db 0FFh,'COUNTRY'

CntryCodePage_Id DW ?

COMMND	DB	"\COMMAND.COM",0
	DB	51 dup (0)

PathString db	64 dup (0)		;AN014;
LShare	db	"SHARE.EXE",0,"/NC",0Dh,0Ah ;AN014;AN015;To be used by Load/exec.
					;/NC parm will disable file sharing check.

COMTAB:
;;;;	   DB	   8,"AVAILDEV",'A'     ; NO LONGER SUPPORTED
	DB	7,"BUFFERS",  'B'
	DB	5,"BREAK",    'C'
	DB	6,"DEVICE",   'D'
	DB	5,"FILES",    'F'
	DB	4,"FCBS",     'X'
	DB	9,"LASTDRIVE",'L'
	db     10,"MULTITRACK", 'M'     ;AN002;
	DB	8,"DRIVPARM", 'P'       ; RS for DOS 3.2
		if     STACKSW
	DB	6,"Stacks",   'K'       ; BAS for DOS 3.2
		end if
	DB	7,"COUNTRY",  'Q'
	DB	5,"SHELL",    'S'
	db	7,"INSTALL",  'I'       ;AN000;
	db	3,"IFS",      'J'       ;AN000;
	db	4,"CPSW",     'W'       ;AN000;
;;;;	   DB	   8,"SWITCHAR",'W'     ; NO LONGER SUPPORTED
	db	7,"COMMENT",  'Y'       ;AN000;
	db	3,"REM",      '0'       ;AN004;
	db	8,"Switches", '1'       ;AN013;
	DB	0

;public DeviceParameters
DeviceParameters A_DEVICEPARAMETERS 0,DEV_3INCH720KB,0,80

hlim	    dw	    2
slim	    dw	    9

;public drive
drive	db	?

;public switches
Switches    dw	0

;
; The following are the recommended BPBs for the media that we know of so
; far.

; 48 tpi diskettes

BPB48T_SYSINIT2	DW	512
	DB	2
	DW	1
	DB	2
	DW	112
	DW	2*9*40
	DB	0FDH
	DW	2
	DW	9
	DW	2
	DD	0
        DD      0

; 96tpi diskettes

BPB96T_SYSINIT2	DW	512
	DB	1
	DW	1
	DB	2
	DW	224
	DW	2*15*80
	DB	0F9H
	DW	7
	DW	15
	DW	2
	DD	0
        DD      0

; 3 1/2 inch diskette BPB

BPB35_SYSINIT2	DW	512
	DB	2
	DW	1
	DB	2
	DW	70h
	DW	2*9*80
	DB	0F9H
	DW	3
	DW	9
	DW	2
	DD	0
        DD      0
      
BPB35H	DW	0200H
	DB	01H
	DW	0001H
	DB	02H
	DW	0E0h
	DW	0B40H
	DB	0F0H
	DW	0009H
	DW	0012H
	DW	0002H
	DD	0
        DD      0

BPBTable    dw	    BPB48T_SYSINIT2		; 48tpi drives
	    dw	    BPB96T_SYSINIT2		; 96tpi drives
	    dw	    BPB35_SYSINIT2		; 3.5" drives
; The following are not supported, so default to 3.5" media layout
	    dw	    BPB35_SYSINIT2		; Not used - 8" drives
	    dw	    BPB35_SYSINIT2		; Not Used - 8" drives
	    dw	    BPB35_SYSINIT2		; Not Used - hard files
	    dw	    BPB35_SYSINIT2		; Not Used - tape drives
	    dw	    BPB35H		; 3-1/2" 1.44MB drive

switchlist  db	8,"FHSTDICN"         ; Preserve the positions of N and C.

; The following depend on the positions of the various letters in SwitchList

;switchnum	equ 11111000B		; which switches require number

;flagec35	equ 00000100B		; electrically compatible 3.5 inch disk drive
;flagdrive	equ 00001000B
;flagcyln	equ 00010000B
;flagseclim	equ 00100000B
;flagheads	equ 01000000B
;flagff		equ 10000000B

;SWTCHR	    EQU     "/"             ; switch follows this character

;SYSINITSEG	ENDS
;	END
