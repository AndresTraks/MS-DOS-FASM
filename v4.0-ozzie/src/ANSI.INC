;	Termcap description of capabilities:

;ibmans4:mtcon:IBM PC with V4.0 ANSI driver:\
;	:al=\E[L:am:bs:ce=\E[K:cl=\E[2J\E[H:cm=\E[%;%H:co#80:\
;	:dl=\E[M:do=\E[B:ho=\E[H:li#24:mi:nd=\E[C:\
;	:ms:pt:se=\E[m:so=\E[1;36m:up=\E[A:\
;	:kb=^h:ku=\E[A:kd=\E[B:kl=\E[D:kr=\E[C:kh=\E[H:kn#8:\
;	:k1=\ES:k2=\ET:k3=\EU:k4=\EV:k5=\EW:\
;	:k6=\EP:k7=\EQ:k8=\ER:

CMDTABL DB	'A'
	DW	CUU		;CUrsor Up
	DB	'B'
	DW	CUD		;CUrsor Down
	DB	'C'
	DW	CUF		;CUrsor Forward
	DB	'D'
	DW	CUB		;CUrsor Back
	DB	'H'
	DW	CUP		;CUrsor Position
	DB	'J'
	DW	ED		;Erase in Display
	DB	'K'
	DW	EL		;Erase in Line
	DB	'L'
	DW	IL		;Insert Line
	DB	'M'
	DW	xDL		;Delete Line
;;	DB	'R'
;;	DW	CPR		;Cursor Postion Report
	DB	'f'
	DW	HVP		;Horizontal and Vertical Position
	DB	'h'
	DW	SM		;Set Mode
	DB	'l'
	DW	RM		;Reset Mode
	DB	'm'
	DW	SGR		;Select Graphics Rendition
;;	DB	'n'
;;	DW	DSR		;Device Status Report
	DB	's'
	DW	SCP		;Save Cursor Position
	DB	'u'
	DW	RCP		;Restore Cursor Position
	DB	00

;	Graphic Rendition modes:  parameter, mask, set
GRMODE	DB	00,00000000B,00000111B	; all off
	DB	01,11111111B,00001000B	; bold (increased intensity)
	DB	04,11111000B,00000001B	; underscore
	DB	05,11111111B,10000000B	; blink
	DB	07,11111000B,01110000B	; reverse video
	DB	08,10001000B,00000000B	; concealed
	DB	30,11111000B,00000000B	; foreground colors ...
	DB	31,11111000B,00000100B
	DB	32,11111000B,00000010B
	DB	33,11111000B,00000110B
	DB	34,11111000B,00000001B
	DB	35,11111000B,00000101B
	DB	36,11111000B,00000011B
	DB	37,11111000B,00000111B
	DB	40,10001111B,00000000B	; background colors ...
	DB	41,10001111B,01000000B
	DB	42,10001111B,00100000B
	DB	43,10001111B,01100000B
	DB	44,10001111B,00010000B
	DB	45,10001111B,01010000B
	DB	46,10001111B,00110000B
	DB	47,10001111B,01110000B
	DB	0FFH

; Set/Reset Modes:  indexed by (SelChar-'<'*8) + (PARAM0 AND 7)
SRMODE	DW	0,0,0,0,0,0,0,0		; SelChar '<'
	DW	1,1,1,1,1,1,1,WRAP	; SelChar '='	
	DW	0,EnaL25,0,0,0,0,0,0	; SelChar '>'
	DW	0,0,0,0,0,0,0,WRAP	; SelChar '?'	

;	The following are duplicates of the same variables from the ROM
;
;* WARNING - the following two variables are accessed as a word
MODE	DB	3
MAXCOL	DB	79
IF	LINE25		; special treatment of line 25?
maxrow	=	24
ELSE
maxrow	=	25
end if
;* WARNING - the following two variables are accessed as a word
COL	DB	0			; current column
ROW	DB	0			; current row


label AnsiState byte; the following must be saved on a screen swap
WRAP	DB	1		; 0 = NO WRAP, 1 = WRAP
EnaL25	DB	0		; 0 = 25th line disabled, 1 = enabled
STATE	DW	S1
SAVCR	DW	0			; saved cursor position
;* WARNING - the following two variables are accessed as a word
SelChar	DB	0			; <,=,> or ? private use indicators
label PRMCNT byte; number of parameters for command
PRMCNTW	DW	0
NUMPARAM =	5			; max. number of parameters
PARAM	DB	NUMPARAM dup (0)	; buffer for command parameters
;* WARNING - the following two variables are accessed as a word
label attrw word
ATTR	DB	00000111B	;CHARACTER ATTRIBUTE
BPAGE	DB	0		;BASE PAGE

AnsiSize	=	($-AnsiState)

IF	(AnsiSize > TermSize)
	err ; ERROR - Terminal state not big enough
end if

;-------------------------------------------------------------
;
;	CHROUT - WRITE OUT CHAR IN AL USING CURRENT ATTRIBUTE
;
base	   dw	0b800h
screen_seg dw	00000h

chrout: cmp	al,13		; carriage return?
	ja	outchr
	jnz	trylf
	mov	[CS:COL],0
;;	jmp	short setit
	jmp	setit

trylf:	cmp	al,10		; line feed?
	jz	lf
	cmp	al,7		; bell?
	jnz	trytab
torom:
	mov	bx,[CS:attrw]
	and	bl,7
	mov	ah,14
	int	10h
ret5:	ret

trytab:
	cmp	al,9		; tab?
	jnz	tryback
	mov	al,[CS:COL]
	add	al,8
	mov	ah,al
	and	ah,7
	sub	al,ah
	cmp	al,[CS:MAXCOL]
	jb	tunder
	mov	al,[CS:MAXCOL]
tunder:
	mov	[CS:COL],al
		jmp	short setit

tryback:
	cmp	al,8		; backspace?
	jnz	outchr
	cmp	[CS:COL],0
	jz	ret5
	dec	[CS:COL]
	jmp	short setit

outchr:
	mov	bx,[CS:attrw]
	mov	cx,1
	mov	ah,9
	int	10h
	inc	[CS:COL]
	mov	al,[CS:COL]
	cmp	al,[CS:MAXCOL]
	jbe	setit
	cmp	[CS:WRAP],1
	jz	outchr1
	dec	[CS:COL]
	ret
outchr1:
	mov	[CS:COL],0
lf:	cmp	[CS:ROW],(maxrow-1)
	ja	setit				; on line 25, don't move
	jz	lf1				; on 24th line, scroll
	inc	[CS:ROW]
	jmp	short setit
lf1:	call	scroll

setit:	mov	dx,word [CS:COL]
	mov	bh,[CS:BPAGE]
	mov	ah,2
	int	10h
	ret

scroll: mov	al,[CS:MODE]
	cmp	al,2
	jz	myscroll
	cmp	al,3
	jz	myscroll
IF	LINE25
	xor	cx,cx			; from 0,0
	mov	dh,(maxrow-1)		; to maxrow-1,maxcol
	mov	dl,[CS:MAXCOL]
	mov	bh,[CS:ATTR]
	mov	ax,0601h		; scroll  up one line
	int	10h
	ret
ELSE
	mov	al,10
	jmp	torom
end if
myscroll:
	mov	bh,[CS:ATTR]
	mov	bl,' '
	mov	bp,80
	mov	ax,[CS:base]
	add	ax,[CS:screen_seg]
	mov	es,ax
	mov	ds,ax
	xor	di,di
	mov	si,160
	mov	cx,(maxrow-1)*80
	cld

;	This code will never get executed since we get here when
;  mode = 2 or 3 only.
;;	cmp	cs:[base],0b800h
;;	jz	colorcard

;;    rep	movsw
;;	mov	ax,bx
;;	mov	cx,bp
;;    rep	stosw
;;	jmp	short sret

;;colorcard:
	mov	dx,3dah
wait2:	in	al,dx
	test	al,8
	jz	wait2
	mov	al,25h
	mov	dx,3d8h
	out	dx,al		;turn off video
    rep	movsw
	mov	ax,bx
	mov	cx,bp
	rep	stosw
	mov	al,29h
	mov	dx,3d8h
	out	dx,al		;turn on video
sret:	push	cs
	pop	ds
	ret


CharOut:	PUSH	AX		; Main entry point
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
	PUSH	DI
	PUSH	ES
	PUSH	BP

	MOV	[CS:base],0B800H
	XCHG	AX,SI			; SAVE CHARACTER TO STUFF
	MOV	AX,40H			; POINT TO ROS BIOS
	MOV	DS,AX
	MOV	AX,[DS:49H]		; AL=MODE, AH=MAX COL
	DEC	AH			; ANSI NEEDS 0-79 OR 0-39
	MOV	word [CS:MODE],AX	; SAVE MODE AND MAX COL
	CMP	AL,7
	JNZ	NOT_BW
	MOV	word [CS:base],0B000H
NOT_BW: MOV	AL,[DS:62H]		; GET ACTIVE PAGE
	MOV	[CS:BPAGE],AL
	CBW
	ADD	AX,AX
	MOV	BX,AX
	MOV	AX,[DS:BX+50H]		; AL=COL, AH=ROW
	MOV	word [CS:COL],AX	; SAVE ROW AND COLUMN
	MOV	AX,[DS:4EH]		; GET START OF SCREEN SEG
	MOV	CL,4
	SHR	AX,CL			; CONVERT TO A SEGMENT
	PUSH	CS
	POP	DS
	MOV	[CS:screen_seg],AX
	XCHG	AX,SI			; GET BACK CHARACTER IN AL

	CALL	VIDEO
	POP	BP
	POP	ES
	POP	DI
	POP	SI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET


;----------------------------------------------------------
;
;	OUTPUT SINGLE CHAR IN AL TO VIDEO DEVICE
;
VIDEO:	MOV	SI,STATE
	JMP	word [SI]

S2:	CMP	AL,'['
	JZ	S22
	JMP	S1
S22:	MOV	word [SI],S30
	XOR	BX,BX
	MOV	word [CS:SelChar],BX
	MOV	word [CS:PARAM],BX
	JMP	SHORT S3B

S30:	CMP	AL,'?'			; experimental use selector (SM/RM)?
	JA	S7
	mov	[CS:SelChar],al
	MOV	word [SI],S3
	cmp	al,'<'
	jae	S3B

S3:	CMP	AL,';'
	JNZ	S3C
S3A:	INC	[CS:PRMCNT]
S3B:	CALL	GETPTR
	XOR	AX,AX
	MOV	word [BX],AX    ;DEFAULT VALUE IS ZERO
	RET

S3C:	CMP	AL,'0'
	JB	S3D
	CMP	AL,'9'
	JA	S7
	CALL	GETPTR
	SUB	AL,'0'
	XCHG	AL,byte [BX]
	MOV	AH,10
	MUL	AH			;*10
	ADD	byte [BX],AL	;MOVE IN DIGIT
	RET

S3D:
;;	CMP	AL,'"'                  ;BEGIN QUOTED STRING
;;	JZ	S3E
;;	CMP	AL,"'"
	JNZ	S7
;;S3E:	MOV	WORD PTR [SI],OFFSET S4
;;	MOV	[INQ],AL
S3RET:	RET

;
;   ENTER QUOTED STRINGS
;

;;S4:	CMP	AL,[INQ]		;CHECK FOR STRING TERMINATOR
;;	JNZ	S4A
;;	DEC	PRMCNT			;TERMINATE STRING
;;	MOV	WORD PTR [SI],OFFSET S3
;;	RET

;;S4A:	CALL	GETPTR
;;	MOV	BYTE PTR [BX],AL
;;	MOV	WORD PTR [SI],OFFSET S4
;;	JMP	S3A
;
;  LOOK FOR ANSI COMMAND SPECIFIED IN AL
;

S7:	MOV	BX,CMDTABL-3
;
S7A:	ADD	BX,3
	CMP	byte [BX],0
	JZ	S1B
	CMP	byte [BX],AL
	JNZ	S7A
;
S7B:	MOV	AX,word [BX+1]     ;AX = JUMP ADDRESS
	MOV	BX,PARAM
	MOV	DL,byte [BX]
	XOR	DH,DH		       ;DX = FIRST PARAMETER
	MOV	CX,DX
	OR	CX,CX
	JNZ	S7C
	INC	CX		       ; if DX=0, CX=1 else CX = DX
S7C:	JMP	AX		       ;AL = COMMAND

S1:	CMP	AL,1Bh		       ;ESCAPE SEQUENCE?
	JNZ	S1B
	MOV	word [SI],S2
	RET

S1B:	CALL	chrout
S1A:	MOV	word [CS:STATE],S1
	RET

MOVCUR: CMP	byte [BX],AH
	JZ	SETCUR
	ADD	byte [BX],AL
	LOOP	MOVCUR
SETCUR: MOV	DX,word [CS:COL]
	XOR	BX,BX
	MOV	AH,2
	int	10h			; call ROM
	JMP	S1A

HVP:
CUP:
IF	LINE25
	CMP	CL,(maxrow+1)
	jb	cup3			; new row is 24 or less
	JA	SETCUR			; error - 26 or greater
	cmp	[CS:EnaL25],0		; else 25, is it allowed?
	jz	SETCUR
cup3:
ELSE
	CMP	CL,maxrow
	JA	SETCUR
end if
	MOV	AL,[CS:MAXCOL]
	MOV	CH,byte [BX+1]
	OR	CH,CH
	JZ	CUP1
	DEC	CH
CUP1:	CMP	AL,CH
	JA	CUP2
	MOV	CH,AL
CUP2:	XCHG	CL,CH
	DEC	CH
	MOV	word [CS:COL],CX
	JMP	SETCUR

CUF:	MOV	AH,[CS:MAXCOL]
	MOV	AL,1
CUF1:	MOV	BX,COL
	JMP	MOVCUR

CUB:	MOV	AX,00FFH
	JMP	CUF1

CUU:	MOV	AX,00FFH
CUU1:	MOV	BX,ROW
	JMP	MOVCUR

CUD:	MOV	AX,(maxrow-1)*256+1
IF	LINE25
	cmp	ah,[CS:ROW]			; at bottom of screen?
	ja	SETCUR
end if
	JMP	CUU1

SCP:	MOV	AX,word [CS:COL]
	MOV	[CS:SAVCR],AX
	JMP	SETCUR

RCP:	MOV	AX,[CS:SAVCR]
IF	LINE25
	cmp	ch,maxrow
	jb	rcp1
	cmp	[CS:EnaL25],0
	jz	rcp2
end if
rcp1:	MOV	word [CS:COL],AX
rcp2:	JMP	SETCUR

SGR:	XOR	CX,CX
	XCHG	CL,[CS:PRMCNT]
	CALL	GETPTR
	INC	CX
SGR1:	MOV	AL,byte [BX]
	PUSH	BX
	MOV	BX,GRMODE
SGR2:	MOV	AH,byte [BX]
	ADD	BX,3
	CMP	AH,0FFH
	JZ	SGR3
	CMP	AH,AL
	JNZ	SGR2
	MOV	AX,word [BX-2]
	AND	[CS:ATTR],AL
	OR	[CS:ATTR],AH
SGR3:	POP	BX
	INC	BX
	LOOP	SGR1
	JMP	SETCUR

ED:
IF	LINE25
	cmp	[CS:ROW],maxrow		; on 25th line?
	je	EL			; yes, treat like Erase in Line
end if
	xor	cx,cx
	mov	dl,[CS:MAXCOL]
	mov	dh,(maxrow-1)
	cmp	[CS:PARAM],1			; which subcommand?
	ja	el2			; all
	jb	ed1
	mov	dh,[CS:ROW]			; to beginning
	dec	dh
	jle	EL
	jmp	short ed2
ed1:	mov	ch,[CS:ROW]			; to end
	inc	ch
	cmp	ch,dh
	jae	EL
ed2:	mov	bh,[CS:ATTR]
	MOV	AX,0600H
	int	10h			; call ROM

EL:	MOV	CX,word [CS:COL]
	MOV	dx,cx
	mov	al,[CS:PARAM]
	inc	al			; 0,1,2 => 1,2,3
	test	al,1			; to end?
	je	el1
	mov	dl,[CS:MAXCOL]
el1:	test	al,2			; to beginning?
	je	el2
	mov	cl,0
el2:	mov	bh,[CS:ATTR]
	mov	ax,0600H
	int	10h
S1A_j:	jmp	S1A

IL:	mov	ah,7			; scroll down
	jmp	short dl1

xDL:	mov	ah,6			; scroll up
dl1:	mov	al,cl			; number of lines
	mov	ch,[CS:ROW]
	xor	cl,cl
	mov	dh,(maxrow-1)
	mov	dl,[CS:MAXCOL]
	mov	bh,[CS:ATTR]
	int	10h
	jmp	S1A_j

RM:	XOR	CL,CL
	JMP	SHORT SM1

SM:	MOV	CL,1
SM1:	mov	bl,[CS:SelChar]		; get selection character
	sub	bl,'<'			; adjust
	jb	S1A_j			; less than '<'
	cmp	bl,4
	jae	S1A_j			; greater than '?'
	xor	bh,bh
	shl	bx,1
	shl	bx,1
	shl	bx,1
	MOV	AL,DL
	CMP	AL,7
	JA	S1A_j
	or	bl,al
	shl	bx,1
	mov	bx,[CS:SRMODE+bx]		; get function indicator
	cmp	bx,1			; no or special function?
	jb	S1A_j
	jz	SM2			; sets screen mode
	MOV	[bx],CL
	JMP	S1A_j

SM2:	MOV	AH,0
	int	10h			; call ROM
	JMP	S1A_j

;	GetPtr - get a pointer to the current parameter
GETPTR: MOV	BX,[CS:PRMCNTW]
	CMP	BX,NUMPARAM
	JB	GET1
	DEC	[CS:PRMCNT]
	JMP	GETPTR
GET1:	ADD	BX,PARAM
	RET
