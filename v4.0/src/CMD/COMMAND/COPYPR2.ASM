 PAGE 80,132
;	SCCSID = @(#)copypr2.asm	1.1 85/05/14
;	SCCSID = @(#)copypr2.asm	1.1 85/05/14
	include 'COMSW.ASM'

.xlist
.xcref
	include 'DOSSYM.INC'
	include 'COMSEG.ASM'
	include 'COMEQU.ASM'
.list
.cref


if SEGSEL = S_TRANDATA	;AC000;
;	EXTRN	FulDir_ptr:word 	;AN052;
end if

if SEGSEL = S_TRANSPACE	;AC000;
;	EXTRN	ASCII:BYTE
;	EXTRN	BINARY:BYTE
;	EXTRN	CONCAT:BYTE
;	EXTRN	DESTBUF:BYTE
;	EXTRN	DESTFCB:BYTE
;	EXTRN	DESTINFO:BYTE
;	EXTRN	DESTISDIR:BYTE
;	EXTRN	DESTTAIL:WORD
;	EXTRN	DESTVARS:BYTE
;	EXTRN	DIRBUF:BYTE
;	EXTRN	DIRCHAR:BYTE
;	EXTRN	FIRSTDEST:BYTE
;	EXTRN	INEXACT:BYTE
;	EXTRN	MELCOPY:BYTE
;	EXTRN	NXTADD:WORD
;	EXTRN	PLUS:BYTE
;	EXTRN	SDIRBUF:BYTE
;	EXTRN	SRCINFO:BYTE
;	EXTRN	srcxname:byte
;	EXTRN	TPA:WORD
;	EXTRN	trgxname:byte
;	EXTRN	USERDIR1:BYTE
end if

if SEGSEL = S_TRANCODE

;	EXTRN	BADPATH_ERR:NEAR	;AN022;
;	EXTRN	COPERR:NEAR		;AN052;
;	EXTRN	EXTEND_SETUP:NEAR	;AN022;

;	PUBLIC	BUILDPATH
;	PUBLIC	SETSTARS
;	PUBLIC	SETASC

;ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

SETASC:
;
; Given switch vector in AX,
;	Set ASCII switch if A is set
;	Clear ASCII switch if B is set
;	BINARY set if B specified
;	Leave ASCII unchanged if neither or both are set
; Also sets INEXACT if ASCII is ever set. AL = ASCII on exit, flags set
;
	AND	AL,SwitchA+SwitchB
	JPE	LOADSW				; PE means both or neither are set
	PUSH	AX
	AND	AL,SwitchB
	MOV	[BINARY],AL
	POP	AX
	AND	AL,SwitchA
	MOV	[ASCII],AL
	OR	[INEXACT],AL

LOADSW:
	MOV	AL,[ASCII]
	OR	AL,AL
	return

;public builddest
BUILDDEST:
	cmp	byte [DESTISDIR],-1
	jnz	KNOWABOUTDEST			; Already done the figuring
	MOV	DI,USERDIR1
	mov	bp,DESTVARS
	call	BUILDPATH
	invoke	RESTUDIR1

; Now know all about the destination

KNOWABOUTDEST:
	xor	al,al
	xchg	al,[FIRSTDEST]
	or	al,al
	jnz	FIRSTDST
	jmp	NOTFIRSTDEST

FIRSTDST:
	mov	si,[DESTTAIL]			; Create an FCB of the original DEST
	mov	di,DESTFCB
	mov	ax,Parse_File_Descriptor SHL 8
	INT	int_command
	CMP	byte [SI],0
	JZ	GoodParse
;AD052; MOV	BYTE PTR [DI+1],"|"             ; must be illegal file name character
	mov	dx,FulDir_Ptr                  ;AN052; Issue "File creation error"
	jmp	COPERR				;AN052;

GoodParse:
	mov	ax,word [DESTBUF]      ; Get drive
	cmp	ah,':'
	jz	DRVSPEC4
	mov	al,'@'

DRVSPEC4:
	MOV	CL,[ASCII]			; Save current ASCII setting
	or	al,20h
	sub	al,60h
	mov	[DESTFCB],al
	mov	al,[DESTINFO]
	mov	ah,[SRCINFO]
	and	ax,0202H
	or	al,al
	jz	NOTMELCOPY
	cmp	al,ah
	jnz	NOTMELCOPY
	cmp	byte [PLUS],0
	jz	NOTMELCOPY
	inc	byte [MELCOPY]     ; ambig source, ambig dest, and pluses
	xor	al,al
	jmp     SETCONC

NOTMELCOPY:
	xor	al,2				; al=2 if unambig dest, =0 if ambig dest
	and	al,ah
	shr	al,1				; al=1 if unambig dest AND ambig sorce
						;   Implies concatenation
SETCONC:
	or	al,[PLUS]			; al=1 if concat
	mov	[CONCAT],al
	shl	al,1
	shl	al,1
	mov	[INEXACT],al			; Concat -> inexact copy
	cmp	byte [BINARY],0
	jnz	NOTFIRSTDEST			; Binary explicitly given, all OK
	mov	[ASCII],al			; Concat -> ASCII
	or	cl,cl
	jnz	NOTFIRSTDEST			; ASCII flag set before, DATA read correctly
	or	al,al
	JZ	NOTFIRSTDEST			; ASCII flag did not change states
;
; At this point there may already be binary read data in the read buffer.
; We need to find the first ^Z (if there is one) and trim the amount
; of data in the buffer correctly.
;
	MOV	CX,[NXTADD]
	JCXZ	NOTFIRSTDEST			; No data, everything OK
	MOV	AL,1AH
	PUSH	ES
	XOR	DI,DI
	MOV	ES,[TPA]
	REPNE	SCASB				; Scan for EOF
	POP	ES
	JNZ	NOTFIRSTDEST			; No ^Z in buffer, everything OK
	DEC	DI				; Point at ^Z
	MOV	[NXTADD],DI			; New buffer

NOTFIRSTDEST:
	mov	bx,DIRBUF+1                  ; Source of replacement chars
	cmp	byte [CONCAT],0
	jz	GOTCHRSRC			; Not a concat
	mov	bx,SDIRBUF+1                  ; Source of replacement chars

GOTCHRSRC:
	mov	si,DESTFCB+1                  ; Original dest name
	mov	di,[DESTTAIL]			; Where to put result

;public buildname
BUILDNAME:
	mov	cx,8

BUILDMAIN:
	lodsb
	cmp	al,'?'
	jnz	NOTAMBIG
	mov	al,byte [BX]

NOTAMBIG:
	cmp	al,' '
	jz	NOSTORE
	stosb

NOSTORE:
	inc	bx
	loop	BUILDMAIN
	mov	cl,3
	mov	al,' '
	cmp	byte [SI],al
	jz	ENDDEST 			; No extension
	mov	al,dot_chr
	stosb

BUILDEXT:
	lodsb
	cmp	al,'?'
	jnz	NOTAMBIGE
	mov	al,byte [BX]

NOTAMBIGE:
	cmp	al,' '
	jz	NOSTOREE
	stosb

NOSTOREE:
	inc	bx
	loop	BUILDEXT
ENDDEST:
	xor	al,al
	stosb					; NUL terminate
	return

BUILDPATH:
	test	byte [BP+VARSTRUC.INFO],2
	jnz	NOTPFILE			; If ambig don't bother with open
	mov	dx,bp
	add	dx,VARSTRUC.BUF    ; Set DX to spec

	push	di				;AN000;
	MOV	AX,ExtOpen SHL 8		;AC000; open the file
	mov	bx,read_open_mode		;AN000; get open mode for COPY
	xor	cx,cx				;AN000; no special files
	mov	si,dx				;AN030; get file name offset
	mov	di,-1				;AN030; no parm list
	mov	dx,read_open_flag		;AN000; set up open flags
	INT	int_command
	pop	di				;AN000;
	jnc	pure_file			;AN022; is pure file
	invoke	Get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_file_not_found 	;AN022; if file not found - okay
	jz	NOTPFILE			;AN022;
	cmp	ax,error_path_not_found 	;AN022; if path not found - okay
	jz	NOTPFILE			;AN022;
	cmp	ax,error_access_denied		;AN022; if access denied - okay
	jz	NOTPFILE			;AN022;
	jmp	extend_setup			;AN022; exit with error

pure_file:
	mov	bx,ax				; Is pure file
	mov	ax,IOCtl SHL 8
	INT	int_command
	mov	ah,Close
	INT	int_command
	test	dl,devid_ISDEV
	jnz	ISADEV				; If device, done
	test	byte [BP+VARSTRUC.INFO],4
	jz	ISSIMPFILE			; If no path seps, done

NOTPFILE:
	mov	dx,word [BP+VARSTRUC.BUF]
	cmp	dl,0				;AN034; If no drive specified, get
	jz	set_drive_spec			;AN034;    default drive dir
	cmp	dh,':'
	jz	DRVSPEC5

set_drive_spec: 				;AN034;
	mov	dl,'@'

DRVSPEC5:
	or	dl,20h
	sub	dl,60h				; A = 1
	invoke	SAVUDIR1
	jnc	curdir_ok			;AN022; if error - exit
	invoke	Get_ext_error_number		;AN022; get the extended error
	jmp	extend_setup			;AN022; exit with error

curdir_ok:					;AN022;
	mov	dx,bp
	add	dx,VARSTRUC.BUF    ; Set DX for upcomming CHDIRs
	mov	bh,byte [BP+VARSTRUC.INFO]
	and	bh,6
	cmp	bh,6				; Ambig and path ?
	jnz	CHECKAMB			; jmp if no
	mov	si,word [BP+VARSTRUC.TTAIL]
	mov	bl,':'
	cmp	byte [si-2],bl
	jnz	KNOWNOTSPEC
	mov	byte [BP+VARSTRUC.ISDIR],2 ; Know is d:/file
	jmp     DOPCDJ

KNOWNOTSPEC:
	mov	byte [BP+VARSTRUC.ISDIR],1 ; Know is path/file
	dec	si				; Point to the /

DOPCDJ:
	jmp	DOPCD				;AC022; need long jump

CHECKAMB:
	cmp	bh,2
	jnz	CHECKCD

ISSIMPFILE:
ISADEV:
	mov	byte [BP+VARSTRUC.ISDIR],0 ; Know is file since ambig but no path
	return

CHECKCD:
	invoke	SETREST1
	mov	ah,CHDir
	INT	int_command
	jc	NOTPDIR
	mov	di,dx
	xor	ax,ax
	mov	cx,ax
	dec	cx

Kloop_COPYPR2:						;AN000;  3/3/KK
	MOV	AL,[es:DI]			;AN000;  3/3/KK
	INC	DI				;AN000;  3/3/KK
	OR	AL,AL				;AN000;  3/3/KK
	JZ	Done				;AN000;  3/3/KK
	xor	ah,ah				;AN000;  3/3/KK
	invoke	TESTKANJ			;AN000;  3/3/KK
	JZ	Kloop_COPYPR2				;AN000;  3/3/KK
	INC	DI				;AN000;  3/3/KK
	INC	AH				;AN000;  3/3/KK
	jmp	Kloop_COPYPR2				;AN000;  3/3/KK

Done:						;AN000;  3/3/KK
	dec	di
	mov	al,[DIRCHAR]
	mov	byte [bp+VARSTRUC.ISDIR],2 ; assume d:/file
	OR	AH, AH				;AN000; 3/3/KK
	JNZ	Store_pchar_COPYPR2			;AN000; 3/3/KK	 this is the trailing byte of ECS code
	cmp	al,[di-1]
	jz	GOTSRCSLSH

Store_pchar_COPYPR2:					;AN000; 3/3/KK
	stosb
	mov	byte [bp+VARSTRUC.ISDIR],1 ; know path/file

GOTSRCSLSH:
	or	byte [bp+VARSTRUC.INFO],6
	call	SETSTARS
	return


NOTPDIR:
	invoke	Get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_path_not_found 	;AN022; if path not found - okay
	jz	notpdir_try			;AN022;
	cmp	ax,error_access_denied		;AN022; if access denied - okay
	jnz	EXTEND_SETUPJ			;AN022; otherwise - exit error

notpdir_try:					;AN022;
	mov	byte [bp+VARSTRUC.ISDIR],0 ; assume pure file
	mov	bh,byte [bp+VARSTRUC.INFO]
	test	bh,4
	retz					; Know pure file, no path seps
	mov	byte [bp+VARSTRUC.ISDIR],2 ; assume d:/file
	mov	si,word [bp+VARSTRUC.TTAIL]
	cmp	byte [si],0
	jz	BADCDERRJ2			; Trailing '/'
	mov	bl,dot_chr
	cmp	byte [si],bl
	jz	BADCDERRJ2			; If . or .. pure cd should have worked
	mov	bl,':'
	cmp	byte [si-2],bl
	jz	DOPCD				; Know d:/file
	mov	byte [bp+VARSTRUC.ISDIR],1 ; Know path/file
	dec	si				; Point at last '/'

DOPCD:
	xor	bl,bl
	xchg	bl,[SI] 			; Stick in a NUL
	invoke	SETREST1
	CMP	DX,SI				;AN000;  3/3/KK
	JAE	LookBack			;AN000;  3/3/KK
	PUSH	SI				;AN000;  3/3/KK
	PUSH	CX				;AN000;  3/3/KK
	MOV	CX,SI				;AN000;  3/3/KK
	MOV	SI,DX				;AN000;  3/3/KK

Kloop2: 					;AN000;  3/3/KK
	LODSB					;AN000;  3/3/KK
	invoke	TESTKANJ			;AN000;  3/3/KK
	jz	NotKanj4_COPYPR2			;AN000;  3/3/KK
	LODSB					;AN000;  3/3/KK
	CMP	SI,CX				;AN000;  3/3/KK
	JB	Kloop2				;AN000;  3/3/KK
	POP	CX				;AN000;  3/3/KK
	POP	SI				;AN000;  3/3/KK
	jmp     DoCdr     ;AN000;  3/3/KK  Last char is ECS code, don't check for
						;		 trailing path sep
NotKanj4_COPYPR2:					;AN000;  3/3/KK
	CMP	SI,CX				;AN000;  3/3/KK
	JB	Kloop2				;AN000;  3/3/KK
	POP	CX				;AN000;  3/3/KK
	POP	SI				;AN000;  3/3/KK

LookBack:					;AN000;  3/3/KK
	CMP	BL,[SI-1]			; if double slash, then complain.
	JZ	BADCDERRJ2

DoCdr:						;AN000;  3/3/KK
	mov	ah,CHDir
	INT	int_command
	xchg	bl,[SI]
	retnc
	invoke	Get_ext_error_number		;AN022; get the extended error

EXTEND_SETUPJ:					;AN022;
	JMP	extend_setup			;AN022; go issue the error message

BADCDERRJ2:
	jmp	badpath_err			;AC022; go issue path not found message

SETSTARS:
	mov	word [bp+VARSTRUC.TTAIL],DI
	add	byte [bp+VARSTRUC.SIZ],12
	mov	ax,dot_qmark
	mov	cx,8
	rep	stosb
	xchg	al,ah
	stosb
	xchg	al,ah
	mov	cl,3
	rep	stosb
	xor	al,al
	stosb
	return

;PUBLIC CompName
COMPNAME:

	mov	si,DESTBUF                  ;g do name translate of target
	mov	di,TRGXNAME                  ;g save for name comparison
	mov	ah,xNameTrans			;g
	int	int_command			;g

	MOV	si,SRCXNAME                  ;g get name translate of source
	MOV	di,TRGXNAME                  ;g get name translate of target


	invoke	STRCOMP

	return

end if
;	 END
