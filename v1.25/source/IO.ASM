; I/O System for 86-DOS version 1.20 and later. Revised 8-02-82.
;
; Assumes a CPU Support card at F0 hex for character I/O,
; with disk drivers for SCP, Tarbell, or Cromemco controllers.
;
; Select whether console input is interrupt-driven or polled.
INTINP		=	1
;
; Select whether the auxiliary port is the Support Card parallel port
; or on channel 1 of a Multiport Serial card addressed at 10H.
PARALLELAUX	EQU	1
SERIALAUX	EQU	0
;
; Select whether the printer is connected to the Support card parallel
; output port (standard) or channel 0 of a Multiport Serial card
; addressed at 10H.
PARALLELPRN	EQU	1
SERIALPRN	EQU	0
;
; If the Multiport Serial was chosen for either the auxiliary or the
; printer, select the baud rate here. Refer to Multiport Serial manual
; page 11 to pick the correct value for a given baud rate.
PRNBAUD	EQU	7		; 1200 baud
AUXBAUD	EQU	0FH		; 19200 baud
;
; Select disk controller here.
IBM		=	1
SCP		=	0
TARBELLSD	=	0
TARBELLDD	=	0
CROMEMCO4FDC	=	0
CROMEMCO16FDC	=	0
;
; Select if you want a special conversion version which can read/write
; both the new Microsoft format and the old SCP format.
; For a two drive system, drives A and B are the new Microsoft format,
; and drives C and D are the old SCP format (where C is the same physical
; drive as A, and D is the same drive as B).  CONVERT has no effect
; on 5.25-inch drives.
CONVERT	EQU	1
;
; Select disk configuration:
LARGE	EQU	1		; Large drives.
COMBIN	EQU	0		; Two 8-inch and one 5.25-inch.
SMALL	EQU	0		; Three 5.25-inch drives.
CUSTOM	EQU	0		; User defined.
;
; If 8-inch drives are PerSci, select FASTSEEK here:
; (Fastseek with Tarbell controllers doesn't work yet).
FASTSEEK	EQU	1
;
; For double-density controllers, select double-sided operation of
; 8-inch disks in double-density mode.
LARGEDS	EQU	0
;
; For double-density controllers, select double-sided operation of
; 5.25-inch disks in double-density mode.
SMALLDS	EQU	0
;
; Use table below to select head step speed. Step times for 5" drives
; are double that shown in the table. Times for Fast Seek mode (using
; PerSci drives) is very small - 200-400 microseconds.
;
; Step value	1771	1793
;
;     0		 6ms	 3ms
;     1		 6ms	 6ms
;     2		10ms	10ms
;     3		20ms	15ms
;
STPSPD	EQU	0
;
; ****** End of selections ********************************************
;
	IF	IBM
BIOSSEG	=	60H		; I/O system segment.
	ELSE
BIOSSEG	=	40H		; I/O system segment.
	END	IF
BIOSLEN	EQU	2048		; Maximum length of I/O system.
DOSLEN	EQU	8192		; Maximum length of MS-DOS.
QSIZE	EQU	80		; Input queue size.
PBUFSIZ	EQU	128		; Size of print buffer
BASE	EQU	0F0H		; CPU Support card base port number.
SIOBASE	EQU	10H		; Base port number of Multiport Serial card.
STAT	EQU	BASE+7		; Serial I/O status port.
DATA	EQU	BASE+6		; Serial I/O data port.
DAV		EQU	2		; Data available bit.
TBMT	EQU	1		; Transmitter buffer empty bit.
SERIAL	EQU	SERIALPRN+SERIALAUX
STCDATA EQU	BASE+4		; Ports for 9513 Timer chip.
STCCOM	EQU	BASE+5

	IF	SERIALAUX
AUXSTAT	=	SIOBASE+3
AUXDATA	=	SIOBASE+2
	END	IF

	IF	PARALLELAUX
AUXSTAT	=	BASE+13
AUXDATA	=	BASE+12
	END	IF

	IF	SERIALPRN
PRNSTAT	=	SIOBASE+1
PRNDATA	=	SIOBASE+0
	END	IF

	IF	PARALLELPRN
PRNSTAT	=	BASE+13
PRNDATA	=	BASE+12
	END	IF

STKSAV	EQU	1701H+DOSDIF
DMAADD	EQU	15B4H+DOSDIF

	IF	IBM
IVT_KEYBOARD_VECTOR		=	09H*4
IVT_KEYBOARD_SEGMENT	=	09H*4+2

PIC1	=	20h

KB_SHIFT	=	1
KB_CTRL		=	2
KB_EXTENDED	=	4

FLOPPY_SECTORS_PER_HEAD		=	18
FLOPPY_HEADS_PER_CYLINDER	=	2
	END	IF

	ORG	0

	JMP	INIT
	NOP;	align because of short jump
	JMP	STATUS
	JMP	INP
	JMP	OUTP
	JMP	PRINT
	JMP	AUXIN
	JMP	AUXOUT
	JMP	READ
	JMP	WRITE
	JMP	DSKCHG
	JMP	SETDATE
	JMP	SETTIME
	JMP	GETTIME
	JMP	FLUSH
	JMP	MAPDEV
	NOP;	align because of short jump
MAPDEV:
	RETF

INIT:
	XOR	BP,BP		; Set up stack just below I/O system.
	MOV	SS,BP
	IF	IBM
	MOV	SP,7C00H
	ELSE
	MOV	SP,BIOSSEG*16
	END	IF

	IF	INTINP-1
	MOV	AL,0FFH		; Mask all interrupts.
	OUT	BASE+3,AL
	END	IF

	IF	INTINP
	CLI			; Set up keyboard interrupt vector.
	IF	IBM
	MOV	word[IVT_KEYBOARD_VECTOR],KBINT
	MOV	[IVT_KEYBOARD_SEGMENT],CS
	ELSE
	MOV	word[BP+64H],KBINT
	MOV	[BP+66H],CS
	END	IF
	STI
	END	IF

	IF	IBM	=	0
	MOV	word[BP+4*38H],PRNFCB
	MOV	[BP+4*38H+2],CS
	PUSH	CS
	POP	DS
;
; Initialize time-of-day clock.
;
	MOV	SI,STCTAB
	MOV	CX,4		;Initialize 4 registers
	CLD
INITSTC:
	LODSB
	OUT	STCCOM,AL		;Select register to initialize
	LODSB
	OUT	STCDATA,AL
	LODSB
	OUT	STCDATA,AL
	LOOP	INITSTC
	END	IF

	IF	SERIAL
	MOV	CX,4
SERINIT:
	LODSB
	OUT	SIOBASE+1,AL
	OUT	SIOBASE+3,AL
	LOOP	SERINIT
	LODSB			;Baud rate for channel 0
	OUT	SIOBASE+8,AL
	LODSB			;Baud rate for channel 1
	OUT	SIOBASE+9,AL
	END	IF
;
; Move MS-DOS down to the first segment just above the I/O system.
;
	IF	IBM
	MOV	AX,BIOSSEG
	MOV	DS,AX
	END	IF
	MOV	SI,BIOSLEN	; Source points to where MS-DOS currently is.
	MOV	AX,DOSSEG	; Destination is beginning of DOSSEG.
	MOV	ES,AX
	SUB	DI,DI
	MOV	CX,DOSLEN/2	; CX is number of words to move.
	REP
	MOVSW

	MOV	SI,INITTAB
	MOV	DX,1		; Do auto memory scan.
	CALL	DOSSEG:0
;
; Change disk read and write vectors (INT 37 and INT 38) to go to
; DIRECTREAD and DIRECTWRITE rather than READ and WRITE.
;
	SUB	BP,BP
	MOV	word[BP+37*4],DIRECTREAD
	MOV	word[BP+38*4],DIRECTWRITE

	MOV	DX,100H
	MOV	AH,26		;Set DMA address
	INT	33
	MOV	CX,[6]		;Get size of segment
	MOV	BX,DS		;Save segment for later
;
; DS must be set to CS so we can point to the FCB.
;
	MOV	AX,CS
	MOV	DS,AX
	MOV	DX,FCB		;File Control Block for COMMAND.COM
	MOV	AH,15
	INT	33		;Open COMMAND.COM
	OR	AL,AL
	JNZ	COMERR		;Error if file not found
	XOR	AX,AX
	MOV	[FCB+33],AX	; Set 4-byte Random Record field to
	MOV	[FCB+35],AX	;  beginning of file.
	INC	AX
	MOV	[FCB+14],AX	;Set record length field
	MOV	AH,39		;Block read (CX already set)
	INT	33
	JCXZ	COMERR		;Error if no records read
	TEST	AL,1
	JZ	COMERR		;Error if not end-of-file
;
; Make all segment registers the same.
;
	MOV	DS,BX
	MOV	ES,BX
	MOV	SS,BX
	MOV	SP,5CH		;Set stack to standard value
	XOR	AX,AX
	PUSH	AX		;Put zero on top of stack for return
	MOV	DX,80H
	MOV	AH,26
	INT	33		;Set default transfer address (DS:0080)
	PUSH	BX		;Put segment on stack
	MOV	AX,100H
	PUSH	AX		;Put address to execute within segment on stack
	RETF		;Jump to COMMAND

COMERR:
	MOV	DX,BADCOM
	MOV	AH,9		;Print string
	INT	33
	STI
STALL:	JMP	STALL

STCTAB:	DB	17H		;Select master mode register
	DW	84F3H		;Enable time-of-day
	DB	1		;Counter 1 mode register
	DW	0138H
	DB	2
	DW	0038H
	DB	3
	DW	0008H		;Set counter 3 to count days

	IF	SERIAL
	DB	0B7H, 77H, 4EH, 37H, PRNBAUD, AUXBAUD
	END	IF

BADCOM:	DB	13,10,"Error in loading Command Interpreter",13,10,"$"
FCB:	DB	1,"COMMAND COM"
	DB	25	DUP(?)
;
; ************ Time and Date ************
;
IF	IBM
;Days of each month (from MSDOS.ASM)
MONTAB  DB      31              ;January
        DB      28              ;February--reset each time year changes
        DB      31              ;March
        DB      30              ;April
        DB      31              ;May
        DB      30              ;June
        DB      31              ;July
        DB      31              ;August
        DB      30              ;September
        DB      31              ;October
        DB      30              ;November
        DB      31              ;December
END	IF

BCD_TO_BIN:
	PUSH	BX
	MOV	BH,AL		; BH = ones digit
	AND	BH,0Fh
	SHR	AL,4		; AL = tens digit
	MOV	AH,10		; AX = 10 * AL + BH
	MUL	AH
	ADD	AL,BH
	POP	BX
	RET

GETTIME:
IF	IBM
	PUSH	BX

	MOV	AH,4
	INT	1AH

	MOV	AL,DH		; DH = month
	CALL	BCD_TO_BIN
	MOV	DH,AL

	MOV	AL,DL		; DL = day
	CALL	BCD_TO_BIN
	MOV	DL,AL

	MOV	AL,CH		; BX = centuries in years
	CALL BCD_TO_BIN
	MOV	BX,100
	PUSH DX
	MUL	BX
	POP	DX
	MOV	BX,AX

	MOV	AL,CL		; AX = year
	CALL	BCD_TO_BIN

	ADD	AX,BX		; Add centuries
	SUB	AX,1980		; Number of years passed since 01-01-1980
	MOV	BX,AX

	MOV	AX,365		; Total days per year
	PUSH	DX
	MUL	BX
	POP	DX
	SHR	BX,2		; Add leap years
	ADD	AX,BX

	XOR	CX,CX		; Add days for the months in the current year
	XOR	BX,BX
	DEC	DH			; 0-based month
ADD_MONTH_DAYS:
	CMP	BL,DH
	JGE	ADD_DAYS
	MOV	CL,[CS:MONTAB+BX]	; Get the number of days in the current month
	ADD	AX,CX
	INC	BL
	JMP	ADD_MONTH_DAYS

ADD_DAYS:
	AND	DX,0FFH			; Add current month days
	ADD	AX,DX
	MOV	BX,AX

	MOV	AH,2
	INT	1AH

	MOV	AL,CH	; hours
	CALL	BCD_TO_BIN
	MOV	CH,AL

	MOV	AL,CL	; minutes
	CALL	BCD_TO_BIN
	MOV	CL,AL

	MOV	AL,DH	; seconds
	CALL	BCD_TO_BIN
	MOV	DH,AL

	XOR	DL,DL	; TODO: use INT	1AH, AH=0 to get time with milliseconds

	MOV	AX,BX
	POP	BX
	RETF
ELSE
	MOV	AL,0A7H		;Save counters 1,2,3
	OUT	STCCOM,AL
	MOV	AL,0E0H		;Enable data pointer sequencing
	OUT	STCCOM,AL
	MOV	AL,19H		;Select hold 1 / hold cycle
	OUT	STCCOM,AL
	CALL	STCTIME		;Get seconds & 1/100's
	XCHG	AX,DX
	CALL	STCTIME		;Get hours & minutes
	XCHG	AX,CX
	IN	AL,STCDATA
	MOV	AH,AL
	IN	AL,STCDATA
	XCHG	AL,AH		;Count of days
	JP	POINTSTAT

STCTIME:
	CALL	STCBYTE
	MOV	CL,AH
STCBYTE:
	IN	AL,STCDATA
	MOV	AH,AL
	SHR	AH,1
	SHR	AH,1
	SHR	AH,1
	SHR	AH,1
	AND	AL,0FH		;Unpack BCD digits
	AAD			;Convert to binary
	MOV	AH,AL
	MOV	AL,CL
	RET
END	IF

SETTIME:
	PUSH	CX
	PUSH	DX
	CALL	LOAD0		;Put 0 into load registers to condition timer
	MOV	AL,43H		;Load counters 1 & 2
	OUT	STCCOM,AL
	POP	DX
	POP	CX
	CALL	_LOAD
	MOV	AL,43H
	OUT	STCCOM,AL		;Load counters 1&2
	CALL	LOAD0
	MOV	AL,27H		;Arm counters 1,2,3
	OUT	STCCOM,AL
	JP	POINTSTAT

LOAD0:
	XOR	CX,CX
	MOV	DX,CX
_LOAD:
	MOV	AL,09		;Counter 1 load register
	CALL	OUTDX
	MOV	AL,0AH		;Counter 2 load register
	MOV	DX,CX
OUTDX:
	OUT	STCCOM,AL	;Select a load register
	MOV	AL,DL
	CALL	OUTBCD
	MOV	AL,DH
OUTBCD:
	AAM			;Convert binary to unpacked BCD
	SHL	AH,1
	SHL	AH,1
	SHL	AH,1
	SHL	AH,1
	OR	AL,AH		;Packed BCD
	OUT	STCDATA,AL
	RET

SETDATE:
	XCHG	AX,DX		;Put date in DX
	MOV	AL,0BH		;Select Counter 3 load register
	OUT	STCCOM,AL
	XCHG	AX,DX
	OUT	STCDATA,AL
	MOV	AL,AH
	OUT	STCDATA,AL
	MOV	AL,44H		;Load counter 3
	OUT	STCCOM,AL
POINTSTAT:
	PUSH	AX
	MOV	AL,1FH		;Point to status register
	OUT	STCCOM,AL		;   so power-off glitches won't hurt
	POP	AX
	RETF
;
; ************ CONSOLE INPUT ************
;

	IF	INTINP-1	; Non-interrupt driven input.
STATUS:
	IN	AL,STAT
	AND	AL,DAV
	JZ	NOTHING		; Jump if nothing there.
	PUSHF			; Save Z flag.
	IN	AL,DATA
	AND	AL,7FH
	MOV	[CS:QUEUE],AL	; Put new character in buffer.
	POPF			; Return with Z flag clear.
	RETF
NOTHING:
	MOV	AL,[CS:QUEUE]	; See if there's anything in the buffer.
	NOT	AL		; Set up the Z flag.
	TEST	AL,80H
	PUSHF
	NOT	AL
	POPF
	RETF

INP:
	MOV	AL,-1
	XCHG	AL,[CS:QUEUE]	; Remove the character from the buffer.
	AND	AL,AL
	JNS	INRET		; Return if we have a character.
INLOOP:
	IN	AL,STAT		; Wait till a character is available.
	AND	AL,DAV
	JZ	INLOOP
	IN	AL,DATA
	AND	AL,7FH
INRET:
FLUSH:
	RETF

QUEUE:	DB	-1		; For storing characters from STATUS to INP.
	END	IF

	IF	INTINP		; Interrupt-driven input.
;
; Console keyboard interrupt handler.
;
KBINT:
	PUSH	AX
	PUSH	SI
IF	IBM
	IN	AL,60H	; get key

	CMP	AL,1DH
	JE	KB_STATUS_CTRL
	CMP	AL,2AH
	JE	KB_STATUS_SHIFT
	CMP	AL,9DH
	JE	KB_STATUS_CTRL_UP
	CMP	AL,0AAH
	JE	KB_STATUS_SHIFT_UP

	TEST	[CS:KB_STATUS],KB_CTRL
	JNZ	KB_HANDLE_CTRL
	TEST	[CS:KB_STATUS],KB_EXTENDED
	JNZ	KB_STATUS_EXTENDED_UP

	CMP	AL,0E0H
	JE	KB_STATUS_EXTENDED
	CMP	AL,80H
	JAE	LEAVINT

	PUSH	SI		; Load character map
	MOV	SI,KB_MAP_SHIFT
	TEST	[CS:KB_STATUS],KB_SHIFT
	JNZ KB_HANDLE_KEYCODE
	MOV	SI,KB_MAP

KB_HANDLE_KEYCODE:
	XOR	AH,AH
	ADD	SI,AX
	MOV	AH,AL
	MOV AL,[CS:SI]
	POP	SI
	CMP	AL,0
	JZ	LEAVINT
	CMP	AL,-1
	JNE	FLSH
	JMP LEAVINT

KB_HANDLE_CTRL:
	CMP AL,0x7F
	JAE	LEAVINT
	SUB	AL,2BH
	JMP	FLSH

KB_STATUS_CTRL:
	OR	[CS:KB_STATUS],KB_CTRL
	JMP	LEAVINT
KB_STATUS_CTRL_UP:
	AND	[CS:KB_STATUS],NOT	KB_CTRL
	JMP	LEAVINT

KB_STATUS_SHIFT:
	OR	[CS:KB_STATUS],KB_SHIFT
	JMP	LEAVINT
KB_STATUS_SHIFT_UP:
	AND	[CS:KB_STATUS],NOT	KB_SHIFT
	JMP	LEAVINT

KB_STATUS_EXTENDED:
	OR	[CS:KB_STATUS],KB_EXTENDED
	JMP	LEAVINT
KB_STATUS_EXTENDED_UP:
	AND	[CS:KB_STATUS],NOT	KB_EXTENDED
	JMP	LEAVINT

KB_STATUS DB 0

KB_MAP:
	DB 0
	DB 0
	DB '1234567890+_'
	DB 0xe
	DB 0
	DB 'qwertyuiop'
	DB '[]'
	DB 13
	DB 0
	DB 'asdfghjkl'
	DB ';'
	DB "'"
	DB '`'
	DB ? ; LSHIFT
	DB '\'
	DB 'zxcvbnm'
	DB ',./'
	DB ? ; RSHIFT
	DB '*'
	DB -1
	DB ' '
	DB -1
	DB 10 dup(-1) ; F1-F10
	DB 2 dup(-1)
	DB '789-'
	DB '456+'
	DB '123'
	DB '0,'
	DB 2 dup(-1)
	DB 1 dup('\')
	DB 41 dup(-1)

KB_MAP_SHIFT:
	DB 0
	DB 0
	DB '!@#$%^&*()_+'
	DB 0xe
	DB '_'
	DB 'QWERTYUIOP'
	DB '{}'
	DB 13
	DB 0
	DB 'ASDFGHJKL'
	DB ':'
	DB '"'
	DB '|'
	DB 0
	DB '\'
	DB 'ZXCVBNM'
	DB '<>?'
	DB -1
	DB '*'
	DB -1
	DB ' '
	DB 13 dup(-1)
	DB '789-'
	DB '456+'
	DB '123'
	DB '0,'
	DB 2 dup(-1)
	DB 1 dup('|')
	DB 41 dup(-1)
ELSE
	MOV	AL,20H		;End of Interrupt command
	OUT	BASE+2,AL	;Send to slave
	IN	AL,DATA		;Get the character
END	IF

	AND	AL,7FH
	CMP	AL,"C"-"@"
	JZ	FLSH
	CMP	AL,"S"-"@"
	JZ	FLSH
	CMP	AL,"F"-"@"
	JNZ	SAVKY
FLSH:
	CALL	BIOSSEG:13*3	; Call I/O system keyboard buffer flush.
SAVKY:
	MOV	SI,[CS:REAR]	;Pointer to rear of queue
	CALL	INCQ
	CMP	SI,[CS:FRONT]	;Any room in queue?
	JZ	QFULL
	MOV	[CS:SI],AL		;Put character in queue
	MOV	[CS:REAR],SI	;Save pointer
LEAVINT:
IF	IBM
	MOV	AL,20h		; Mark end of interrupt
	OUT	PIC1,AL
END	IF
	POP	SI
	POP	AX
	IRET
QFULL:
	MOV	AL,7		; BELL character.
	CALL	BIOSSEG:3*3	; Call I/O system console output function.
	JMP	LEAVINT

STATUS:
	PUSH	SI
	IF	IBM
	JMP	NOPRN
	END	IF
;See if printer ready
	IN	AL,PRNSTAT
	AND	AL,TBMT
	JZ	NOPRN
	MOV	SI,[CS:PFRONT]
	CMP	SI,[CS:PREAR]	;Anything in print queue?
	JNZ	SENDPRN
	CMP	[CS:PRNFCB],-1	;Print spooling in progress?
	JZ	NOPRN		;If not, nothing to print
;Print spooling in progress. Get next buffer
	PUSH	DS
	PUSH	CS
	POP	DS
	PUSH	AX
	PUSH	CX
	PUSH	DX
	PUSH	word[STKSAV]
	PUSH	word[STKSAV+2]
	PUSH	word[DMAADD]
	PUSH	word[DMAADD+2]
	MOV	DX,PQUEUE
	MOV	AH,26		;Set DMA address
	INT	33
	MOV	DX,PRNFCB
	MOV	CX,PBUFSIZ
	MOV	AH,39		;Read buffer
	INT	33
	OR	AL,AL
	JZ	NOTEOF
	MOV	[PRNFCB],-1	;Turn off print spooling at EOF
NOTEOF:
	POP	word[DMAADD+2]
	POP	word[DMAADD]
	POP	word[STKSAV+2]
	POP	word[STKSAV]
	MOV	SI,CX
	POP	DX
	POP	CX
	POP	AX
	POP	DS
	OR	SI,SI
	JZ	NOPRN
	ADD	SI,PQUEUE-1
	MOV	[CS:PREAR],SI
	MOV	SI,ENDPQ-1
SENDPRN:
	CALL	INCPQ
	MOV	[CS:PFRONT],SI
	CS LODSB			;Get character to print
	OUT	PRNDATA,AL
NOPRN:
	CLI			; Disable interrupts while checking queue.
	MOV	SI,[CS:FRONT]
	CMP	SI,[CS:REAR]	; Anything in queue?
	JZ	NOCHR		; Jump if nothing in queue.
	CALL	INCQ
	CS LODSB			;Get character (if there is one)
	OR	SI,SI		;Reset zero flag
NOCHR:
	STI
	POP	SI
	RETF		;Zero clear if we have a character

INP:
	CALL	BIOSSEG:STATUS	; Get I/O system console input status.
	JZ	INP
	PUSH	SI
	CLI			; Disable interrupts while changing queue pointers.
	MOV	SI,[CS:FRONT]
	CALL	INCQ		; Permanently remove char from queue
	MOV	[CS:FRONT],SI
	STI
	POP	SI
	RETF

FLUSH:
	CLI
	MOV	[CS:REAR],QUEUE
	MOV	[CS:FRONT],QUEUE
	STI
	RETF

INCQ:
	INC	SI
	CMP	SI,ENDQ		;Exceeded length of queue?
	JB	INCQ_RET
	MOV	SI,QUEUE
INCQ_RET:
	RET

INCPQ:
	INC	SI
	CMP	SI,ENDPQ	;Exceeded length of queue?
	JB	INCPQ_RET
	MOV	SI,PQUEUE
INCPQ_RET:
	RET

FRONT	DW	QUEUE
REAR	DW	QUEUE
QUEUE	DB	QSIZE DUP(?)
ENDQ	=	$
PFRONT	DW	PQUEUE
PREAR	DW	PQUEUE
PQUEUE	DB	PBUFSIZ DUP(?)
ENDPQ	=	$
PRNFCB	DB	-1
	DB	36 DUP(?)
	END	IF

;
; ************ Console and Printer Output ************
;
OUTP:
	IF	IBM
	PUSH	BX
	MOV	AH,0EH
	MOV	BH,0
	INT	10H
	POP	BX
	ELSE
	PUSH	AX
OUTLP:
	IN	AL,STAT
	AND	AL,TBMT
	JZ	OUTLP
	POP	AX
	OUT	DATA,AL
	END	IF
	RETF

PRINT:
	PUSH	SI
	MOV	SI,[CS:PREAR]
	CALL	INCPQ
PRINLP:
	CMP	SI,[CS:PFRONT]
	JNZ	PRNCHR
;Print queue is full
	PUSH	AX
	CALL	BIOSSEG:STATUS	;Poll and maybe print something
	POP	AX
	JMP	PRINLP
PRNCHR:
	MOV	[CS:PREAR],SI
	MOV	[CS:SI],AL
	POP	SI
	RETF
;
; ************ Auxiliary I/O ************
;
AUXIN:
	IN	AL,AUXSTAT
	AND	AL,DAV
	JZ	AUXIN
	IN	AL,AUXDATA
	RETF

AUXOUT:
	PUSH	AX
AUXLP:
	IN	AL,AUXSTAT
	AND	AL,TBMT
	JZ	AUXLP
	POP	AX
	OUT	AUXDATA,AL
	RETF
;
; ************ 1771/1793-type controller disk I/O ************
;
TARBELL	=	TARBELLSD+TARBELLDD
CROMEMCO	=	CROMEMCO4FDC+CROMEMCO16FDC

WD1791	=	SCP+TARBELLDD+CROMEMCO16FDC
WD1771	=	TARBELLSD+CROMEMCO4FDC

	IF	WD1791
READCOM	=	80H
WRITECOM	=	0A0H
	END	IF

	IF	WD1771
READCOM	=	88H
WRITECOM	=	0A8H
	END	IF

	IF	SCP > 0
SMALLBIT	=	10H
BACKBIT	=	04H
DDENBIT	=	08H
DONEBIT	=	01H
DISK	=	0E0H
	END	IF

	IF	TARBELL > 0
BACKBIT	=	40H
DDENBIT	=	08H
DONEBIT	=	80H
DISK	=	78H
	END	IF

	IF	CROMEMCO > 0
SMALLBIT	=	10H
BACKBIT	=	0FDH		; Send this to port 4 to select back.
DDENBIT	=	40H
DONEBIT	=	01H
DISK	=	30H
	END	IF

	IF	SMALLDS
SMALLDDSECT	=	16
	ELSE
SMALLDDSECT	=	8
	END	IF

	IF	LARGEDS
LARGEDDSECT	=	16
	ELSE
LARGEDDSECT	=	8
	END	IF
;
; Disk change function.
; On entry:
;	AL = disk drive number.
; On exit:
;	AH = -1 (FF hex) if disk is changed.
;	AH = 0 if don't know.
;	AH = 1 if not changed.
;
;	CF clear if no disk error.
;	AL = disk I/O driver number.
;
;	CF set if disk error.
;	AL = disk error code (see disk read below).
;
	IF	WD1771
DSKCHG:
	MOV	AH,0		; AH = 0 in case we don't know.
	CMP	AL,[CS:CURDRV]
	JNZ	RETL
	PUSH	AX		; Save drive number.

	IF	CROMEMCO
	IN	AL,DISK+4
	END	IF

	IF	TARBELL
	IN	AL,DISK
	END	IF

	AND	AL,20H		; Look at head load bit
	POP	AX
	JZ	RETL
	MOV	AH,1		; AH = 1, disk not changed.
RETL:
	CLC			; No disk error.
	RETF
	END	IF			; End of 1771 DSKCHG.

	IF	WD1791
DSKCHG:
	MOV	AH,0		; AH = 0 in case we don't know.
	CMP	AL,[CS:CURDRV]
	JNZ	DENSCHK		; Check density if not same drive.
	PUSH	AX

	IF	SCP+CROMEMCO
	IN	AL,DISK+4
	END	IF

	IF	TARBELL
	IN	AL,DISK
	END	IF

	AND	AL,20H		; Look at head load bit
	POP	AX
	JZ	DENSCHK		; Check density if head not loaded.
	MOV	AH,1		; AH = 1, disk not changed.
	MOV	BX,PREVDENS
	CS	XLATB			; Get previous density
	CLC			; No disk error.
	RETF
DENSCHK:
	CALL	CHKNEW		; Unload head if selecting new drive.
	CBW
	XCHG	AX,SI
	ADD	SI,PREVDENS
	MOV	CX,4		; Try each density twice
	MOV	AH,0		; Disk may not have been changed.
CHKDENS:
	MOV	AL,[CS:SI]	; Get previous disk I/O driver number.
	MOV	BX,DRVTAB
	CS	XLATB		; Get drive select byte for previous density

	IF	CROMEMCO16FDC
	CALL	MOTOR		; Wait for motor to come up to speed.
	END	IF

	OUT	DISK+4,AL	; Select disk
	MOV	AL,0C4H		; READ ADDRESS command
	CALL	DCOM
	AND	AL,98H
	IN	AL,DISK+3	; Eat last byte to reset DRQ
	JZ	HAVDENS		; Jump if no error in reading address.
	NOT	AH		; AH = -1 (disk changed) if new density works.
	XOR	byte[CS:SI],1	; Try other density
	LOOP	CHKDENS
	MOV	AX,2		; Couldn't read disk at all, AH = 0 for don't 
	STC			;  know if disk changed, AL = error code 2 -
	RETF		;  disk not ready, carry set to indicate error.

HAVDENS:
	CS	LODSB		; AL = disk I/O driver number.
	CLC			; No disk error.
	RETF

PREVDENS:DB	1,3,5,7,9,11,13	; Table of previous disk I/O driver numbers.
	END	IF			; End of 1793 DSKCHG function.

CHKNEW:
	IF	IBM	=	0
	MOV	AH,AL		; Save disk drive number in AH.
	; AL = previous disk drive number,
	XCHG	AL,[CS:CURDRV]	;  make new drive current.
	CMP	AL,AH		; Changing drives?
	JZ	CHKNEW_RET
;
; If changing drives, unload head so the head load delay one-shot will
; fire again. Do it by seeking to the same track with the H bit reset.
;
	IN	AL,DISK+1		; Get current track number
	OUT	DISK+3,AL		; Make it the track to seek to
	MOV	AL,10H		; Seek and unload head
	CALL	DCOM
	MOV	AL,AH		; Restore current drive number
CHKNEW_RET:
	END IF
	RET

	IF	CROMEMCO16FDC
MOTOR:
	PUSH	AX
	MOV	AH,AL
	IN	AL,DISK+4	; See if the motor is on.
	TEST	AL,08H
	MOV	AL,AH
	OUT	DISK+4,AL		; Select drive & start motor.
	JNZ	MOTORSON	; No delay if motors already on.
	PUSH	CX
	MOV	CX,43716	; Loop count for 1 second.
MOTORDELAY:			;  (8 MHz, 16-bit memory).
	AAM			; 83 clocks.
	AAM			; 83 clocks.
	LOOP	MOTORDELAY	; 17 clocks.
	POP	CX
MOTORSON:
	POP	AX
	RET
	END	IF
;
; Disk read function.
;
; On entry:
;	AL = Disk I/O driver number
;	BX = Disk transfer address in DS
;	CX = Number of sectors to transfer
;	DX = Logical record number of transfer
; On exit:
;	CF clear if transfer complete
;
;	CF set if hard disk error.
;	CX = number of sectors left to transfer.
;	AL = disk error code
;		0 = write protect error
;		2 = not ready error
;		4 = "data" (CRC) error
;		6 = seek error
;		8 = sector not found
;	       10 = write fault
;	       12 = "disk" (none of the above) error
;
READ:
	IF	IBM
	PUSH	ES
	PUSH	DS
	POP	ES

	PUSH	CX
	PUSH	AX
	MOV	AX,DX
	MOV	CH,FLOPPY_SECTORS_PER_HEAD
	DIV	CH
	MOV	CL,AH
	INC	CL		; sector
	XOR	AH,AH
	MOV	CH,FLOPPY_HEADS_PER_CYLINDER
	DIV	CH
	MOV	CH,AL	; cylinder
	POP	DX
	MOV	DH,AH	; head
	POP	AX
	MOV	AH,2
	INT	13H
	ELSE
	CALL	SEEK		;Position head
	JC	ERROR
	PUSH	ES		; Make ES same as DS.
	MOV	BX,DS
	MOV	ES,BX
RDLP:
	CALL	READSECT	;Perform sector read
	JC	POPESERROR
	INC	DH		;Next sector number
	LOOP	RDLP		;Read each sector requested
	CLC			; No errors.
	END	IF

	POP	ES		; Restore ES register.
	RETF
;
; Disk write function.
; Registers same on entry and exit as read above.
;
WRITE:
	IF	IBM
	PUSH	ES
	PUSH	DS
	POP	ES

	PUSH	CX
	PUSH	AX
	MOV	AX,DX
	MOV	CH,FLOPPY_SECTORS_PER_HEAD
	DIV	CH
	MOV	CL,AH
	INC	CL		; sector
	XOR	AH,AH
	MOV	CH,FLOPPY_HEADS_PER_CYLINDER
	DIV	CH
	MOV	CH,AL	; cylinder
	POP	DX
	MOV	DH,AH	; head
	POP AX
	MOV	AH,3
	INT	13H

	POP	ES
ELSE
	CALL	SEEK		;Position head
	JC	ERROR
WRTLP:
	CALL	WRITESECT	;Perform sector write
	JC	ERROR
	INC	DH		;Bump sector counter
	LOOP	WRTLP		;Write CX sectors
	CLC			; No errors.
WRITERET:
END	IF
	RETF

POPESERROR:
	POP	ES		; Restore ES register.
ERROR:
	MOV	BL,-1
	MOV	[CS:DI],BL		; Indicate we don't know where head is.
	MOV	SI,ERRTAB
GETCOD:
	INC	BL		; Increment to next error code.
	CS LODSB
	TEST	AH,AL		; See if error code matches disk status.
	JZ	GETCOD		; Try another if not.
	MOV	AL,BL		; Now we've got the code.
	SHL	AL,1		; Multiply by two.
	STC
	RETF

ERRTAB:
	DB	40H		;Write protect error
	DB	80H		;Not ready error
	DB	8		;CRC error
	DB	2		;Seek error
	DB	10H		;Sector not found
	DB	20H		;Write fault
	DB	7		;"Disk" error
;
; Direct disk read and write from INT 37 and INT 38.  Subroutine GETIODRIVER
; calls DSKCHG to convert disk drive number to I/O driver number.
;
; Setting CURDRV to -1 before calling DSKCHG forces DSKCHG to check the disk's
; density before returning the I/O driver number.  This is necessary because
; programs such as FORMAT could change the density of a disk and leave the
; head loaded.  If the head is loaded DSKCHG assumes the disk hasn't been
; changed and returns the old I/O driver number which could be wrong.
;
; CURDRV is set to -1 before returning so when DSKCHG is called by the
; operating system, it will tell the operating system the disk may have
; been changed (because it may have been).
;
DIRECTREAD:

	IF	WD1791
	CALL	GETIODRIVER	; Convert drive number to I/O driver number.
	JC	DIRECTRET	; Return if DSKCHG returned error.
	END	IF

	CALL	BIOSSEG:7*3	; Call READ.
	JMP	DIRECTRET

DIRECTWRITE:

	IF	WD1791
	CALL	GETIODRIVER	; Convert drive number to I/O driver number.
	JC	DIRECTRET	; Return if DSKCHG returned error.
	END	IF

	CALL	BIOSSEG:8*3	; Call WRITE.
DIRECTRET:
	MOV	byte[CS:CURDRV],-1	; Force DSKCHG to do density check.
	RETF

	IF	IBM	=	0
	IF	WD1791
GETIODRIVER:
	MOV	byte[CS:CURDRV],-1	; Force DSKCHG to do density check.
	PUSH	BX
	PUSH	CX
	CALL	BIOSSEG:9*3	; Call DSKCHG.
	POP	CX
	POP	BX
	RET
	END	IF
;
; Function:
;	Seeks to proper track.
; On entry:
;	Same as for disk read or write above.
; On exit:
;	AH = Drive select byte
;	DL = Track number
;	DH = Sector number
;	SI = Disk transfer address in DS
;	DI = pointer to drive's track counter in CS
;	CX unchanged (number of sectors)
;
SEEK:
	MOV	SI,BX		; Save transfer address
	CBW
	MOV	BX,AX		; Prepare to index on drive number

	IF	WD1791		; If two disk formats per drive.
	SHR	AL,1		; Convert to physical disk drive number.
	END	IF

	CALL	CHKNEW		; Unload head if changing drives.
	MOV	AL,[CS:BX+DRVTAB]	; Get drive-select byte.

	IF	CROMEMCO16FDC
	CALL	MOTOR		; Wait for the motors to come up to speed.
	END	IF

	OUT		DISK+4,AL	; Select drive.

	IF	CROMEMCO
	OR	AL,80H		; Set auto-wait bit.
	END	IF

	MOV	AH,AL		; Save drive-select byte in AH.
	XCHG	AX,DX		; AX = logical sector number.
	MOV	DL,26		; 26 sectors/track unless changed below

	IF	SCP
	TEST	DH,SMALLBIT	; Check if small disk.
	JZ	BIGONE		; Jump if big disk.
	MOV	DL,18		; Assume 18 sectors on small track.
	TEST	DH,DDENBIT	; Check if double-density.
	JZ	HAVSECT		; Jump if not.
	MOV	DL,SMALLDDSECT	; Number of sectors on small DD track.
	JP	HAVSECT
BIGONE:
	TEST	DH,DDENBIT	; Check if double-density.
	JZ	HAVSECT		; Jump if not.
	MOV	DL,LARGEDDSECT	; Number of sectors on big DD track.
	END	IF

	IF	TARBELLDD	; Tarbell DD controller.
	TEST	DH,DDENBIT	; Check for double-density.
	JZ	HAVSECT
	MOV	DL,LARGEDDSECT	; Number of sectors on DD track.
	END	IF

	IF	CROMEMCO4FDC
	TEST	DH,SMALLBIT	; Check if small disk.
	JNZ	HAVSECT		; Jump if not.
	MOV	DL,18		; 18 sectors on small disk track.
	END	IF

	IF	CROMEMCO16FDC
	TEST	DH,SMALLBIT	; Check if small disk.
	JNZ	BIGONE		; Jump if big disk.
	MOV	DL,18		; Assume 18 sectors on small track.
	TEST	DH,DDENBIT	; Check if double-density.
	JZ	HAVSECT		; Jump if not.
	MOV	DL,SMALLDDSECT	; Number of sectors on small DD track.
	JP	HAVSECT
BIGONE:
	TEST	DH,DDENBIT	; Check if double-density.
	JZ	HAVSECT		; Jump if not.
	MOV	DL,LARGEDDSECT	; Number of sectors on big DD track.
	END	IF

HAVSECT:
	DIV	DL		; AL = track, AH = sector.
	XCHG	AX,DX		; AH has drive-select byte, DX = track & sector.
	INC	DH		; Sectors start at one, not zero.
	MOV	BL,[CS:BX+TRKPT]	; Get this drive's displacement into track table.
	ADD	BX,TRKTAB	; BX now points to track counter for this drive.
	MOV	DI,BX
	MOV	AL,DL		; Move new track number into AL.
	XCHG	AL,[CS:DI]	; Xchange current track with desired track
	OUT	DISK+1,AL		; Inform controller chip of current track
	CMP	AL,DL		; See if we're at the right track.
	JZ	SEEK_RET
	MOV	BH,2		; Seek retry count
	CMP	AL,-1		; Head position known?
	JNZ	NOHOME		; If not, home head
TRYSK:
	CALL	HOME
	JC	SEEKERR
NOHOME:
	MOV	AL,DL		; AL = new track number.
	OUT	DISK+3,AL
	MOV	AL,1CH+STPSPD	; Seek command.
	CALL	MOVHEAD
	AND	AL,98H		; Accept not ready, seek, & CRC error bits.
	JZ	SEEK_RET
	JS	SEEKERR		; No retries if not ready
	DEC	BH
	JNZ	TRYSK
SEEKERR:
	MOV	AH,AL		; Put status in AH.
	TEST	AL,80H		; See if it was a Not Ready error.
	STC
	JNZ	SEEK_RET		; Status is OK for Not Ready error.
	MOV	AH,2		; Everything else is seek error.
SEEK_RET:
	RET

SETUP:
	MOV	BL,DH		; Move sector number to BL to play with

	IF	SCP+CROMEMCO16FDC
	TEST	AH,DDENBIT	; Check for double density.
	JZ	CHECKSMALL	; Not DD, check size for SD.
	END	IF

	IF	TARBELLDD
	TEST	AH,DDENBIT	; Check for double density.
	JZ	CHECK26		; Not DD.
	END	IF

	IF	WD1791

	IF	(SCP+TARBELL)*LARGEDS+SCP*SMALLDS
	MOV	AL,AH		; Select front side of disk.
	OUT	DISK+4,AL
	END	IF

	IF	CROMEMCO*(LARGEDS+SMALLDS)
	MOV	AL,0FFH		; Select front side of disk.
	OUT	04H
	END	IF

	CMP	BL,8		; See if legal DD sector number.
	JBE	PUTSEC		; Jump if ok.

	IF	(LARGEDS-1)*((SMALLDS*(SCP+CROMEMCO))-1)
	JP	STEP		; If only SS drives, we gotta step.
	END	IF

	IF	SCP*LARGEDS*(SMALLDS-1)
	TEST	AH,SMALLBIT	; Check for 5.25 inch disk.
	JNZ	STEP		; Jump if small because SMALLDS is off.
	END	IF

	IF	SCP*SMALLDS*(LARGEDS-1)
	TEST	AH,SMALLBIT	; Check for 8 inch disk.
	JZ	STEP		; Jump if large because LARGEDS is off.
	END	IF

	IF	CROMEMCO16FDC*LARGEDS*(SMALLDS-1)
	TEST	AH,SMALLBIT	; Check for 5.25 inch disk.
	JZ	STEP		; Jump if small because SMALLDS is off.
	END	IF

	IF	CROMEMCO16FDC*SMALLDS*(LARGEDS-1)
	TEST	AH,SMALLBIT	; Check for 8 inch disk.
	JNZ	STEP		; Jump if large because LARGEDS is off.
	END	IF

	IF	LARGEDS+SMALLDS*(SCP+CROMEMCO)
	SUB	BL,8		; Find true sector for back side.
	CMP	BL,8		; See if ok now.
	JA	STEP		; Have to step if still too big.

	IF	SCP+TARBELLDD
	MOV	AL,AH		; Move drive select byte into AL.
	OR	AL,BACKBIT	; Select back side.
	OUT	DISK+4,AL
	END	IF

	IF	CROMEMCO16FDC
	MOV	AL,BACKBIT	; Select back side.
	OUT	04H
	END	IF

	JP	PUTSEC
	END	IF

	END	IF

	IF	SCP
CHECKSMALL:
	TEST	AH,SMALLBIT	; See if big disk.
	JZ	CHECK26		; Jump if big.
	END	IF

	IF	CROMEMCO
CHECKSMALL:
	TEST	AH,SMALLBIT	; See if big disk.
	JNZ	CHECK26		; Jump if big.
	END	IF

	IF 	SCP+CROMEMCO
	CMP	BL,18		; See if legal small SD/SS sector.
	JA	STEP		; Jump if not.
	END	IF

CHECK26:
	CMP	BL,26		; See if legal large SD/SS sector.
	JBE	PUTSEC		; Jump if ok.
STEP:
	INC	DL		; Increment track number.
	MOV	AL,58H		; Step in with update.
	CALL	DCOM
	INC	byte [CS:DI]		; Increment the track pointer.
	MOV	DH,1		; After step, do first sector.
	MOV	BL,DH		; Fix temporary sector number also.
PUTSEC:
	MOV	AL,BL		; Output sector number to controller.
	OUT	DISK+2,AL
	CLI			; Interrupts not allowed until I/O done

	IF	SCP+CROMEMCO
	IN	AL,DISK+4		; Get head-load bit.
	END	IF

	IF	TARBELL
	IN	AL,DISK
	END	IF

	NOT	AL
	AND	AL,20H		; Check head load status
	JZ	PUTSEC_RET
	MOV	AL,4
PUTSEC_RET:
	RET

READSECT:
	CALL	SETUP
	MOV	BL,10		; Retry count for hard error.
	XCHG	DI,SI		; Transfer address to DI.
	PUSH	DX		; Save track & sector number.
	MOV	DL,DISK+3	; Disk controller data port.
RDAGN:
	OR	AL,READCOM
	OUT	DISK,AL

	IF	CROMEMCO
	MOV	AL,AH		; Turn on auto-wait.
	OUT	DISK+4,AL
	END	IF

	MOV	BP,DI		; Save address for retry.
	JMP	RLOOPENTRY
RLOOP:
	STOSB			; Write into memory.
RLOOPENTRY:

	IF	SCP
	IN	AL,DISK+5		; Wait for DRQ or INTRQ.
	END	IF

	IF	TARBELL+CROMEMCO
	IN	AL,DISK+4
	END	IF

	IF	TARBELL
	SHL	AL,1
	IN	AL,DX		; Read data from disk controller chip.
	JC	RLOOP
	END	IF

	IF	SCP+CROMEMCO
	SHR	AL,1
	IN	AL,DX		; Read data from disk controller chip.
	JNC	RLOOP
	END	IF

	STI			; Interrupts OK now
	CALL	GETSTAT
	AND	AL,9CH
	JZ	RDPOP
	MOV	DI,BP		; Get origainal address back for retry.
	MOV	BH,AL		; Save error status for report
	MOV	AL,0
	DEC	BL
	JNZ	RDAGN
	MOV	AH,BH		; Put error status in AH.
	STC
RDPOP:
	POP	DX		; Get back track & sector number.
	XCHG	SI,DI		; Address back to SI.

	IF	TARBELL
FORCINT:
	MOV	AL,0D0H		; Tarbell controllers need this Force Interrupt
	OUT	DISK,AL		;  so that Type I status is always available
	MOV	AL,10		;  at the 1771/1793 status port so we can find
INTDLY:				;  out if the head is loaded.  SCP and Cromemco
	DEC	AL		;  controllers have head-load status available
	JNZ	INTDLY		;  at the DISK+4 status port.
	END	IF

	RET

WRITESECT:
	CALL	SETUP
	MOV	BL,10
	PUSH	DX		; Save track & sector number.
	MOV	DL,DISK+3	; Disk controller data port.
WRTAGN:
	OR	AL,WRITECOM
	OUT	DISK,AL

	IF	CROMEMCO
	MOV	AL,AH		; Turn on auto-wait.
	OUT	DISK+4,AL
	END	IF

	MOV	BP,SI
WRLOOP:

	IF	SCP
	IN	AL,DISK+5
	END	IF

	IF	TARBELL+CROMEMCO
	IN	AL,DISK+4
	END	IF

	IF	SCP+CROMEMCO
	SHR	AL,1
	LODSB			; Get data from memory.
	OUT	DX,AL		; Write to disk.
	JNC	WRLOOP
	END	IF

	IF	TARBELL
	SHL	AL,1
	LODSB			; Get data from memory.
	OUT		DX,AL	; Write to disk.
	JC	WRLOOP
	END	IF

	STI			; Interrupts OK now.
	DEC	SI
	CALL	GETSTAT
	AND	AL,0FCH
	JZ	WRPOP
	MOV	SI,BP
	MOV	BH,AL
	MOV	AL,0
	DEC	BL
	JNZ	WRTAGN
	MOV	AH,BH		; Error status to AH.
	STC
WRPOP:
	POP	DX		; Get back track & sector number.

	IF	TARBELL
	JMP	FORCINT
	END	IF

	IF	SCP+CROMEMCO
	RET
	END	IF
;
; Subroutine to restore the read/write head to track 0.
;
	IF	SCP+CROMEMCO+TARBELL*(FASTSEEK-1)
HOME:
	END	IF

	IF	FASTSEEK*CROMEMCO
	TEST	AH,SMALLBIT	; Check for large disk.
	JNZ	_RESTORE		; Big disks are fast seek PerSci.
	END	IF

	MOV	BL,3
TRYHOM:

	IF	SCP*FASTSEEK
	MOV	AL,AH		; Turn on Restore to PerSci.
	OR	AL,80H
	OUT	DISK+4,AL
	END	IF

	MOV	AL,0CH+STPSPD	; Restore with verify command.
	CALL	DCOM
	AND	AL,98H

	IF	SCP*FASTSEEK
	MOV	AL,AH		; Restore off.
	OUT	DISK+4,AL
	END	IF

	JZ	TRYHOM_RET
	JS	HOMERR		; No retries if not ready
	MOV	AL,58H+STPSPD	; Step in with update
	CALL	DCOM
	DEC	BL
	JNZ	TRYHOM
HOMERR:
	STC
TRYHOM_RET:
	RET
;
; RESTORE for PerSci drives.
; Doesn't exist yet for Tarbell controllers.
;
	IF	FASTSEEK*TARBELL
HOME:
_RESTORE:
	RET
	END	IF

	IF	FASTSEEK*CROMEMCO4FDC
_RESTORE:
	MOV	AL,0C4H		;READ ADDRESS command to keep head loaded
	OUT	DISK,AL
	MOV	AL,77H
	OUT	4,AL
CHKRES:
	IN	AL,4
	AND	AL,40H
	JZ	RESDONE
	IN	AL,DISK+4
	TEST	AL,DONEBIT
	JZ	CHKRES
	IN	AL,DISK
	JP	_RESTORE		;Reload head
RESDONE:
	MOV	AL,7FH
	OUT	4,AL
	CALL	GETSTAT
	MOV	AL,0
	OUT	DISK+1,AL	;Tell 1771 we're now on track 0
	RET
	END	IF

	IF	FASTSEEK*CROMEMCO16FDC
_RESTORE:
	MOV	AL,0D7H		; Turn on Drive-Select and Restore.
	OUT	4,AL
	PUSH	AX
	AAM			; 10 uS delay.
	POP	AX
RESWAIT:
	IN	AL,4	; Wait till Seek Complete is active.
	TEST	AL,40H
	JNZ	RESWAIT
	MOV	AL,0FFH		; Turn off Drive-Select and Restore.
	OUT	4,AL
	SUB	AL,AL		; Tell 1793 we're on track 0.
	OUT	DISK+1,AL
	RET
	END	IF
;
; Subroutine to move the read/write head to the desired track.
; Usually falls through to DCOM unless special handling for
; PerSci drives is required in which case go to FASTSK.
;
	IF	SCP+CROMEMCO+TARBELL*(FASTSEEK-1)
MOVHEAD:
	END	IF

	IF	CROMEMCO*FASTSEEK
	TEST	AH,SMALLBIT	; Check for PerSci.
	JNZ	FASTSK
	END	IF

DCOM:
	OUT	DISK,AL
	PUSH	AX
	AAM			;Delay 10 microseconds
	POP	AX
GETSTAT:
	IN	AL,DISK+4
	TEST	AL,DONEBIT

	IF	TARBELL
	JNZ	GETSTAT
	END IF

	IF	SCP+CROMEMCO
	JZ	GETSTAT
	END IF

	IN	AL,DISK
	RET
;
; Fast seek code for PerSci drives.
; Tarbell not installed yet.
;
	IF	FASTSEEK*TARBELL
MOVHEAD:
FASTSK:
	RET
	END IF

	IF	FASTSEEK*CROMEMCO
FASTSK:
	MOV	AL,6FH
	OUT	4,AL
	MOV	AL,18H
	CALL	DCOM
SKWAIT:
	IN	AL,4
	TEST	AL,40H
	JNZ	SKWAIT
	MOV	AL,7FH
	OUT	4,AL
	MOV	AL,0
	RET
	END IF
	END IF

CURDRV	DB	-1
;
; Explanation of tables below.
;
; DRVTAB is a table of bytes which are sent to the disk controller as drive-
; select bytes to choose which physical drive is selected for each disk I/O
; driver.  It also selects whether the disk is 5.25-inch or 8-inch, single-
; density or double-density.  Always select side 0 in the drive-select byte if
; a side-select bit is available.  There should be one entry in the DRVTAB
; table for each disk I/O driver.  Exactly which bits in the drive-select byte
; do what depends on which disk controller is used.
;
; TRKTAB is a table of bytes used to store which track the read/write
; head of each drive is on.  Each physical drive should have its own
; entry in TRKTAB.
;
; TRKPT is a table of bytes which indicates which TRKTAB entry each
; disk I/O driver should use.  Since each physical drive may be used for
; more than one disk I/O driver, more than one entry in TRKPT may point
; to the same entry in TRKTAB.  Drives such as PerSci 277s which use
; the same head positioner for more than one drive should share entrys
; in TRKTAB.
;
; INITTAB is the initialization table for 86-DOS as described in the
; 86-DOS Programer's Manual under "Customizing the I/O System."

IF IBM
DSKCHG:
	XOR	AL,AL	; AL = disk I/O driver number.
	CLC			; No disk error.
	RETF

HOME:
	RET

MOVHEAD:
	RET

DRVTAB:
		DB	0
TRKPT:	DB	0
TRKTAB:	DB	-1
INITTAB:
		DB	1	; NUMIO

		DB	0	; Physical unit no
		DW	DPT

DPT:
		DW	512		; sector size
		DB	1		; sectors per cluster
		DW	1		; reserved sectors
		DB	2		; FAT count
		DW	224		; MAXENT
		DW	2880	; num sectors
END	IF

	IF	SCP*COMBIN*FASTSEEK
;
; A PerSci 277 or 299 and one 5.25-inch drive.
;
DRVTAB:	DB	00H,08H,01H,09H,10H,18H,00H,08H,01H,09H
TRKPT:	DB	0,0,0,0,1,1,0,0,0,0
TRKTAB:	DB	-1,-1
INITTAB:
	IF	CONVERT-1
	DB	6		; Number of disk I/O drivers.
	END	IF

	IF	CONVERT
	DB	10
	END	IF

	DB	0		; Disk I/O driver 0 uses disk drive 0.
	DW	LSDRIVE		; Disk I/O driver 0 is 8-inch single-density.
	DB	0		; Disk I/O driver 1 uses disk drive 0.
	DW	LDDRIVE		; Disk I/O driver 1 is 8-inch double-density.
	DB	1		; Etc.
	DW	LSDRIVE
	DB	1
	DW	LDDRIVE
	DB	2
	DW	SSDRIVE
	DB	2
	DW	SDDRIVE

	IF	CONVERT
	DB	3
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLDDRIVE
	DB	4
	DW	OLDLSDRIVE
	DB	4
	DW	OLDLDDRIVE
	END	IF
	END	IF

	IF	SCP*LARGE*FASTSEEK
;
; PerSci 277 or 299.
;
DRVTAB:	DB	00H,08H,01H,09H,00H,08H,01H,09H
TRKPT:	DB	0,0,0,0,0,0,0,0
TRKTAB:	DB	-1
INITTAB:
	IF	CONVERT-1
	DB	4
	END	IF

	IF	CONVERT
	DB	8
	END	IF

	DB	0
	DW	LSDRIVE
	DB	0
	DW	LDDRIVE
	DB	1
	DW	LSDRIVE
	DB	1
	DW	LDDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	2
	DW	OLDLDDRIVE
	DB	3
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLDDRIVE
	END	IF
	END	IF

	IF	TARBELLDD
;
; Two 8-inch Shugart-type drives.
;
DRVTAB:	DB	0,8,10H,18H,0,8,10H,18H
TRKPT:	DB	0,0,1,1,0,0,1,1
TRKTAB:	DB	-1,-1
INITTAB:

	IF	CONVERT-1
	DB	4
	END	IF

	IF	CONVERT
	DB	8
	END	IF

	DB	0
	DW	LSDRIVE
	DB	0
	DW	LDDRIVE
	DB	1
	DW	LSDRIVE
	DB	1
	DW	LDDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	2
	DW	OLDLDDRIVE
	DB	3
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLDDRIVE
	END	IF
	END	IF

	IF	TARBELLSD
;
; Four 8-inch Shugart-type drives.
;
DRVTAB:	DB	0F2H,0E2H,0F2H,0E2H
TRKPT:	DB	0,1,0,1
TRKTAB:	DB	-1,-1
INITTAB:

	IF	CONVERT-1
	DB	2
	END	IF

	IF	CONVERT
	DB	4
	END	IF

	DB	0
	DW	LSDRIVE
	DB	1
	DW	LSDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLSDRIVE
	END	IF
	END	IF
;
; Cromemco drive select byte is derived as follows:
;	Bit 7 = 0
;	Bit 6 = 1 if double density (if 16FDC)
;	Bit 5 = 1 (motor on)
;	Bit 4 = 0 for 5", 1 for 8" drives
;	Bit 3 = 1 for drive 3
;	Bit 2 = 1 for drive 2
;	Bit 1 = 1 for drive 1
;	Bit 0 = 1 for drive 0
;
	IF	CROMEMCO4FDC*LARGE
;
; PerSci 277 drive.
;
DRVTAB:	DB	31H,32H,31H,32H
TRKPT:	DB	0,0,0,0
TRKTAB:	DB	-1
INITTAB:

	IF	CONVERT-1
	DB	2
	END	IF

	IF	CONVERT
	DB	4
	END	IF

	DB	0
	DW	LSDRIVE
	DB	1
	DW	LSDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLSDRIVE
	END	IF
	END	IF

	IF	CROMEMCO4FDC*COMBIN
;
; A PerSci 277 and one 5.25-inch drive.
;
DRVTAB:	DB	31H,32H,24H,31H,32H
TRKPT:	DB	0,0,1,0,0
TRKTAB:	DB	-1,-1
INITTAB:

	IF	CONVERT-1
	DB	3
	END	IF

	IF	CONVERT
	DB	5
	END	IF

	DB	0
	DW	LSDRIVE
	DB	1
	DW	LSDRIVE
	DB	2
	DW	SSDRIVE

	IF	CONVERT
	DB	3
	DW	OLDLSDRIVE
	DB	4
	DW	OLDLSDRIVE
	END	IF
	END	IF

	IF	CROMEMCO4FDC*SMALL
;
; Three 5.25-inch drives.
;
DRVTAB:	DB	21H,22H,24H
TRKPT:	DB	0,1,2
TRKTAB:	DB	-1,-1,-1
INITTAB:DB	3
	DB	0
	DW	SSDRIVE
	DB	1
	DW	SSDRIVE
	DB	2
	DW	SSDRIVE
	END	IF

	IF	CUSTOM
;
; Cromemco 4FDC with two 8-inch Shugart-type drives.
;
DRVTAB:	DB	31H,32H,31H,32H
TRKPT:	DB	0,1,0,1
TRKTAB:	DB	-1,-1
INITTAB:
	IF	CONVERT-1
	DB	2
	END	IF

	IF	CONVERT
	DB	4
	END	IF

	DB	0
	DW	LSDRIVE
	DB	1
	DW	LSDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLSDRIVE
	END	IF
	END	IF

	IF	CROMEMCO16FDC*SMALL
;
; Three 5.25-inch drives.
;
DRVTAB:	DB	21H,61H,22H,62H,24H,64H
TRKPT:	DB	0,0,1,1,2,2
TRKTAB:	DB	-1,-1,-1
INITTAB:DB	6
	DB	0
	DW	SSDRIVE
	DB	0
	DW	SDDRIVE
	DB	1
	DW	SSDRIVE
	DB	1
	DW	SDDRIVE
	DB	2
	DW	SSDRIVE
	DB	2
	DW	SDDRIVE
	END	IF

	IF	CROMEMCO16FDC*COMBIN
;
; A PerSci 277 or 299 and one 5.25-inch drive.
;
DRVTAB:	DB	31H,71H,32H,72H,24H,64H,31H,71H,32H,72H
TRKPT:	DB	0,0,0,0,1,1,0,0,0,0
TRKTAB:	DB	-1,-1
INITTAB:
	IF	CONVERT-1
	DB	6
	END	IF

	IF	CONVERT
	DB	10
	END	IF

	DB	0
	DW	LSDRIVE
	DB	0
	DW	LDDRIVE
	DB	1
	DW	LSDRIVE
	DB	1
	DW	LDDRIVE
	DB	2
	DW	SSDRIVE
	DB	2
	DW	SDDRIVE

	IF	CONVERT
	DB	3
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLDDRIVE
	DB	4
	DW	OLDLSDRIVE
	DB	4
	DW	OLDLDDRIVE
	END	IF
	END	IF

	IF	CROMEMCO16FDC*LARGE
;
; A PerSci 277 or 299.
;
DRVTAB:	DB	31H,71H,32H,72H,31H,71H,32H,72H
TRKPT:	DB	0,0,0,0,0,0,0,0
TRKTAB:	DB	-1
INITTAB:
	IF	CONVERT-1
	DB	4
	END	IF

	IF	CONVERT
	DB	8
	END	IF

	DB	0
	DW	LSDRIVE
	DB	0
	DW	LDDRIVE
	DB	1
	DW	LSDRIVE
	DB	1
	DW	LDDRIVE

	IF	CONVERT
	DB	2
	DW	OLDLSDRIVE
	DB	2
	DW	OLDLDDRIVE
	DB	3
	DW	OLDLSDRIVE
	DB	3
	DW	OLDLDDRIVE
	END	IF
	END	IF

	IF	SMALL+COMBIN
SSDRIVE:
	DW	128		; Sector size in bytes.
	DB	2		; Sector per allocation unit.
	DW	54		; Reserved sectors.
	DB	2		; Number of allocation tables.
	DW	64		; Number of directory entrys.
	DW	720		; Number of sectors on the disk.

	IF	SMALLDS-1
SDDRIVE:			; This is the IBM Personal Computer
	DW	512		; disk format.
	DB	1
	DW	1
	DB	2
	DW	64
	DW	320
	END	IF

	IF	SMALLDS
SDDRIVE:
	DW	512
	DB	2
	DW	1
	DB	2
	DW	112
	DW	640
	END	IF
	END	IF			; End of small drive DPTs.

	IF	COMBIN+LARGE
LSDRIVE:
	DW	128		; Size of sector in bytes.
	DB	4		; Sectors per allocation unit.
	DW	1		; Number of reserved sectors.
	DB	2		; Number of File Allocation Tables.
	DW	68		; Number of directory entrys.
	DW	77*26		; Number of sectors on the disk.

	IF	CONVERT
OLDLSDRIVE:
	DW	128
	DB	4
	DW	52		; Old format had two tracks reserved.
	DB	2
	DW	64		; 64 directory entrys.
	DW	77*26
	END	IF

	IF	LARGEDS-1
OLDLDDRIVE:
LDDRIVE:
	DW	1024
	DB	1
	DW	1
	DB	2
	DW	96
	DW	77*8
	END	IF

	IF	LARGEDS
LDDRIVE:
	DW	1024
	DB	1
	DW	1
	DB	2
	DW	192		; 192 directory entrys in new 8-inch DD/DS format.
	DW	77*8*2

	IF	CONVERT
OLDLDDRIVE:
	DW	1024
	DB	1
	DW	1
	DB	2
	DW	128		; 128 directory entrys in old 8-inch DD/DS format.
	DW	77*8*2
	END	IF
	END	IF

	END	IF			; End of large drive DPTs.

DOSSEG	=	($+15)/16+BIOSSEG	; Compute segment to use for 86-DOS.
DOSDIF	=	16*(DOSSEG-BIOSSEG)
