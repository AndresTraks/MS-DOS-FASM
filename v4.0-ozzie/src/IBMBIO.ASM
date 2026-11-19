
;   Modified for 3.0, July '83, Marc McDonald
;
;   arw 02/01/84
;	split disk driver into separate file
;   arw 05/01/84
;	split out console driver

;::::::::::::::::::::::::::::::::::::::::::::::
;
;	IBM ADDRESSES FOR I/O
;
;::::::::::::::::::::::::::::::::::::::::::::::

;DEBUGFLG =	1		; don't enable debug printfs
CONSFLAG =	0		; =1 to include console driver here

	INCLUDE 'DEFDBUG.INC'

	BIOSEG=70H		;0070	SEGMENT FOR THE BIOS
	SYSIZE=100H		;Number of paragraphs in sysinit module
	RSINIT=0A3H		;RS232 INITIALIZATION
				;9600 BAUD:NO PARITY:1 STOP:8 BIT WORD
	LF=10			;LINE FEED
	CR=13			;CARRIAGE RETURN
	BACKSP=8		;BACKSPACE
	BRKADR=6CH		;006C  BREAK VECTOR ADDRESS
	DSKADR=1EH*4		;ADDRESS OF PTR TO DISK PARAMETERS
	SEC9=522H		;ADDRESS OF DISK PARAMETERS
	AKPORT=20H
	EOI=20H


;**	Timer and Clock Definitions

SCHEDCOUNT	=	50		; # msec/scheduler tick
MOTORCOUNT	=	55		; # msec/ROM BIOS tick


if SEGSEL = S_CODE

   ASSUME CS:BiosSeg,DS:NOTHING,ES:NOTHING

START$:
IF	QEMUA20
	IN	AL,92H		; the A20 gate is bit 1 of port A, and
	AND	AL,0FDH		;  closed is what twenty address lines
	OUT	92H,AL		;  give: the top of memory wraps, which
end if				;  is what the CALL 5 entry is built on
	JMP	INIT

	DB	20 DUP (0)	; IBM WANTS SOME ZEROED AREA

;--------------------------------------------------------------
;
;	COMMAND JUMP TABLES
;
;	BEWARE - These tables overlap somewhat! -c.p.
;
IF	CONSFLAG
CONTBL:
	DW	SetAddr
	DW	StatusComplete
	DW	StatusComplete
	DW	CmdErr
	DW	CON$READ
	DW	CON$RDND
	DW	StatusComplete
	DW	CON$FLSH
	DW	CON$WRIT
	DW	CON$WRIT
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
end if	;CONSFLAG

AUXTBL:
	DW	StatusComplete
	DW	StatusComplete
	DW	StatusComplete
	DW	CmdErr
	DW	AUX$READ
	DW	AUX$RDND
	DW	StatusComplete
	DW	AUX$FLSH
	DW	AUX$WRIT
	DW	AUX$WRIT
	DW	AUX$WRST
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr

TIMTBL:
	DW	StatusComplete
	DW	StatusComplete
	DW	StatusComplete
	DW	CmdErr
	DW	TIM$READ
	DW	StatusDevReady
	DW	StatusComplete
	DW	StatusComplete
	DW	TIM$WRIT
	DW	TIM$WRIT

PRNTBL:
	DW	StatusComplete
	DW	StatusComplete
	DW	StatusComplete
	DW	CmdErr
	DW	StatusNoXfer		; Printer doesn't read
	DW	StatusDevReady
	DW	StatusComplete
	DW	StatusComplete
	DW	PRN$WRIT
	DW	PRN$WRIT
	DW	PRN$STAT
	DW	StatusComplete
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr
	DW	CmdErr

;---------------------------------------------------
;
;	Device Entry point
;
CMDLEN	=	0	;LENGTH OF THIS COMMAND
UNIT	=	1	;SUB UNIT SPECIFIER
CMD	=	2	;COMMAND CODE
STATUS	=	3	;STATUS
MEDIA	=	13	;MEDIA DESCRIPTOR
TRANS	=	14	;TRANSFER ADDRESS
Dfun	=	dword 14		; Passed addr of dos function
COUNT	=	18	;COUNT OF BLOCKS OR CHARACTERS
START	=	20	;FIRST BLOCK TO TRANSFER

AUXNUM	DB	0	;WHICH AUX DEVICE WAS REQUESTED

; Dos routine to do functions for device drivers
DosFunction	DD	0	; Device help function entry point
ScrnIOok	dd	0	; (char *) true if in current screen locus

TIM_DRV DB	-1		; TIME WHEN LAST DISK I/O PERFORMED
TIM_REM DW	0		; scheduler tics left until media presumed
				; changed

;**	Debugging control:
;
;	Group	Level	Controls
;	 01		General BIOS, bootstrapping and initialization
;		 01		Device initialization
;		 02		MS-DOS bootstrapping
;		 04		Driver error conditions
;		 10		Command dispatch
;	 04		Diskette driver
;		 01		Initialization
;		 02		System entrys
;		 04		Details of read/write processing
;	 08		Hard disk driver
;		 01		Initialization
;		 02		System entrys
;	 10		Console display driver


BUGBITS DB  000H			; group bits
	DB  0ffH			; level bits

Strategy:
	RETF

IF	CONSFLAG
CON$IN:
	PUSH	SI
	MOV	SI,CONTBL
	JMP	SHORT Interrupt
end if	;CONSFLAG

AUX0$IN:
	PUSH	SI
	PUSH	AX
	XOR	AL,AL
	JMP	SHORT AUXENT

AUX1$IN:
	PUSH	SI
	PUSH	AX
	MOV	AL,1
AUXENT:
	MOV	SI,AUXTBL
	JMP	SHORT entry1

PRN0$IN:
	PUSH	SI
	PUSH	AX
	XOR	AL,AL
	JMP	SHORT PRNENT

PRN1$IN:
	PUSH	SI
	PUSH	AX
	MOV	AL,1
	JMP	SHORT PRNENT

PRN2$IN:
	PUSH	SI
	PUSH	AX
	MOV	AL,2
PRNENT:
	MOV	SI,PRNTBL
	JMP	SHORT entry1

TIM$IN:
	PUSH	SI
	MOV	SI,TIMTBL


;COMMENT *
;   Interrupt is the main part of the interrupt device entry point( a
;misnomer, actually is the execute function entry ) for all devices.
;The various devices set up the dispatch table address and unit choice
;and then jump to Interrupt which then dispatches to the appropriate
;device routine.
;
;Entry parameters:
;	SI	Address of device dispatch table
;	AL	Unit # for Aux/Prn( stored in AuxNum )
;	ES:BX	Device request packet address
;
;Exit parameters:	( to device routine )
;	AL	Unit code from packet
;	AH	Media descriptor from packet
;	CX	Count from packet
;	DX	Start sector from packet
;	ES:DI	Buffer address from packet
;	DS:BX	Packet address
;	SS	TaskArea segment( from dos call )
;	*

Interrupt:
	PUSH	AX
entry1:
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	BP
	PUSH	DS
	PUSH	ES
	PUSH	BX
;	debug	1,10H,< INTERRUPT cmdtbl $x >,<si>
	MOV	[CS:AUXNUM],AL		; Save unit choice of AUX/PRN
	MOV	AX,ES
	MOV	DS,AX			; DS:BX also points to packet

	MOV	AL,[DS:BX+CMD]		; Get device command
	XOR	AH,AH
	ADD	SI,AX
	ADD	SI,AX			; Get Address of routine
	CMP	AL,18			; Too high a command number?
	JA	CmdErr			; Yes, error
	MOV	AL,[DS:BX+UNIT]		;AL = Unit code
	MOV	AH,[DS:BX+MEDIA]	;AH = Media descriptor
	MOV	CX,[DS:BX+COUNT]	;CX = Count
	MOV	DX,[DS:BX+START]	;DX = Start sector
	LES	DI,[DS:BX+TRANS]	; ES:DI = buffer addr
;	debug	1,10H,<un $x xfer $x:$x rtn $x\n>,<ax,es,di,cs:[si]>
	JMP	word [CS:SI]	; Do request

;COMMENT	*
;   All routines on this page are various exits for device functions.
;They each return different information in the request packet for the
;dos. The routines are as follows:
;
;	StatusDevReady
;		  The busy and done bits are set in the packet. This
;		means that the device has input to be read or can
;		do output without any waiting.
;
;	StatusPartialXfer
;		  The device was unable to do the I/O for the requested
;		number of bytes/blocks. CX contains the number that are
;		left to do. Fall into StatusError to set error has
;		happened.
;
;	StatusError
;		  Set the error and done bits in the status.
;
;	StatusNoXfer
;		  The device couldn't do the read or write, set the
;		number of bytes transferred to 0, but don't set the
;		error bit.
;
;	StatusComplete
;		  The device actually completed the request and every-
;		thing was just fine, so just set the done bit in the
;		request status.
;
;	StatusWait
;		  The device driver is for 3.0 and saw that it would
;		have to wait in a loop to do the request, so instead
;		it will not set the done bit which tells the dos to
;		put the task into the I/O wait queue.
;
;Entry parameters:	( for all of the above routines )
;	DS:BX	Address of device request packet
;	CX	Count of bytes/blocks left to transfer if applicable
;	AL	Error code if applicable
;
;Exit parameters:
;	ES:BX	Pointer to packet
;	AX	Destroyed
;	SI	Destroyed
;	All other registers preserved
;	*

StatusDevReady:; Device has data or can send
	MOV	AH,00000011B		; Done + busy
	JMP	SHORT SetStatus

CmdErr:; Bad device command number
;	debug	1,4,< CMDERR - $b $x\n>,<ax,si>
	MOV	AL,3			; Unknown command error

StatusPartialXfer:
	SUB	[BX+COUNT],CX		;# of successful I/O's

StatusError:
	MOV	AH,10000001B		; Error + done
	JMP	SHORT SetStatus

StatusNoXfer:
	XOR	AX,AX
	MOV	[BX+COUNT],AX		; No chars read

StatusComplete:
	MOV	AH,00000001B		; Done
SetStatus:
	POP	BX
	POP	ES
	MOV	word [ES:BX+STATUS],AX     ;MARK OPERATION COMPLETE
	POP	DS
	POP	BP
	POP	DI
	POP	DX
	POP	CX
	POP	AX
	POP	SI
XXX:
	RETF				;RESTORE REGS AND RETURN

StatusWait:
	MOV	AH,0			; Don't set done bit
	MOV	[BX+COUNT],CX		; Set number completed
	MOV	word [BX+TRANS],DI	; Set new offset
	JMP	SetStatus

IF	CONSFLAG
; Set the address of the dos function routine for drivers
SetAddr:
	MOV	AX,word [BX+Dfun]
	MOV	word [CS:DosFunction],AX
	MOV	AX,word [BX+2+Dfun]
	MOV	word [CS:DosFunction+2],AX
	mov	ax,0
	mov	cx,1
	mov	dx,16
	call	dword [CS:DosFunction]
	mov	word [CS:ScrnIOok],ax
	mov	word [CS:ScrnIOok+2],dx
	JMP	StatusComplete


;-------------------------------------------------------------
;
;	CHROUT - WRITE OUT CHAR IN AL USING CURRENT ATTRIBUTE
;
;	CALLED VIA INT 29H
;
CHROUT	=	29H

OUTCHR: STI
	PUSH	AX
	MOV	BX,7
	MOV	AH,14		;WRITE CHARACTER
	INT	10H		;SEND THE CHARACTER
	POP	AX
	IRET
end if	;CONSFLAG

;----------------------------------------------
;
;	SET DX TO AUXNUM
;
GETDX:	MOV	DL,[CS:AUXNUM]
	XOR	DH,DH
	RET

;COMMENT	*
;   This is the console( CON ) device driver. The input side is assigned
;to the keyboard and the output to the video screen. The output code
;remains more or less the same as in 2.0. The input side, however, is
;changed for 4.0 to enter an I/O wait rather than loop waiting for a
;character.
;	*

IF	CONSFLAG
label CONDEV word;HEADER FOR DEVICE "CON"
	DW	AUXDEV,BIOSEG
	DW	1000000000010011B	;CON IN AND CON OUT + SPECIAL
	DW	Strategy
	DW	CON$IN
	DB	'CON     '
ELSE
end if	;CONSFLAG

IF	CONSFLAG
Key2ndPart	DB	0		; Leftover byte of 2 key codes

if SEGSEL = S_CODE
RomData = 40H
virtual at 0
	ORG	1AH
Bufferhead	DW      0
BufferTail	DW      0
label KeyBuffer word
KeyBufLen	=	32		; length of KeyBuffer
end virtual
end if

; BREAK interrupt routine
; ROM interrupt handler resets buffer pointers to beginning of buffer
; and places a 0000h dummy character into the buffer.

Break:
	mov	[CS:Key2ndPart],3		; Force next char to be ^C( stop )
	IRET


;COMMENT *
;   The console read dispatch tries to read the selected number of
;characters from the keyboard. If at any point there is no key in
;the queue, it returns to the dos to allow another process to run
;until a key is depressed.
;
;Entry parameters:
;	ES:DI	Pointer to buffer in which to store characters
;	CX	Number of characters to read
;	DS:BX	Pointer to device request packet
;
;Exit parameters:
;	CX	Number of characters left to read
;	DS:BX	Pointer to device request packet
;	*

Con$Read:
	JCXZ	StatusComplete
CON$LOOP:
	PUSH	CX		;SAVE COUNT
	CALL	ChrIn		;GET CHAR IN AL
	POP	CX
	STOSB			;STORE CHAR AT ES:DI
	LOOP	CON$LOOP
	JMP	StatusComplete
Con$Read	ENDP

;COMMENT *
;    ChrIn attempts to read a character from the keyboard queue that
;is maintained by the ROM BIOS. If the queue is not empty, the code
;is returned. Otherwise, the packet is added to the list of keyboard
;reads and carry is set to cause the driver routine to return to the
;dos with the done bit not set which results in an I/O wait.
;
;Entry parameters:
;	DS:BX	Pointer to device request packet
;
;Exit parameters:
;	AL	Character from keyboard if present
;*

ChrIn:
ConReadLoop:
	XOR	AX,AX
	XCHG	AL,[CS:Key2ndPart]		; GET CHARACTER & ZERO Key2ndPart
	OR	AL,AL
	JNZ	KeyRet
	MOV	AH,0
	INT	16H			; Get the char
	OR	AX,AX		;Check for non-key after BREAK
	JZ	ConReadLoop
	CMP	AX,7200H	;Check for CTRL-PRTSC
	JNZ	ALT15
	MOV	AL,16
ALT15:
	OR	AL,AL		; 2 byte keycode?
	JNZ	KeyRet		; No, have whole code
	MOV	[CS:Key2ndPart],AH	; Yes, store scan code for next read
KeyRet: RET


;COMMENT *
;   The non-destructive keyboard read routine returns the next char
;in the queue if there is one.
;
;Entry parameters:
;	DS:BX	Pointer to device request packet
;
;Exit parameters:
;	DS:BX	Pointer to device request packet
;	*
Con$RdNd:
	MOV	AL,[CS:Key2ndPart]
	OR	AL,AL
	JNZ	RDexit
	mov	ah,1
	int	16h
	JZ	CONBUS
	OR	AX,AX
	JNZ	NOTBRK			;CHECK FOR NULL AFTER BREAK
	MOV	AH,0
	INT	16H			;READ THE NULL
	JMP	CON$RDND		;AND GET A REAL STATUS
NOTBRK: CMP	AX,7200H		;CHECK FOR CTRL-PRTSC
	JNZ	RDexit
	MOV	AL,16
RDexit:
	MOV	[BX+MEDIA],AL
EXVEC:	JMP	StatusComplete
CONBUS: JMP	StatusDevReady
Con$RdNd	ENDP

;--------------------------------------------------------------
;
;	KEYBOARD FLUSH ROUTINE
;
Con$Flsh:
	MOV	[CS:Key2ndPart],0		       ;Clear out holding buffer

	CALL	Flush			; Flush the keyboard
	JMP	EXVEC
Con$Flsh	ENDP


Flush:
	PUSH	DS
	MOV	AX,RomData
	MOV	DS,AX
    ASSUME	DS:RomData

	CLI				; ** Disable interrupts
	MOV	AX,KeyBuffer  ; Start of Rom buffer
	MOV	[Bufferhead],AX
	MOV	[BufferTail],AX		; Empty the queue
	STI				; ** enable interrupts
	POP	DS
    ASSUME	DS:NOTHING

	RET


;----------------------------------------------------------
;
;	CONSOLE WRITE ROUTINE
;
CON$WRIT:
	JCXZ	EXVEC
CON$LP: MOV	AL,[ES:DI]	;GET CHAR
	INC	DI
	PUSH	CX
	PUSH	DI
	INT	CHROUT		;OUTPUT CHAR
	POP	DI
	POP	CX
	LOOP	CON$LP		;REPEAT UNTIL ALL THROUGH
	JMP	EXVEC

; Replacement for ROM keyboard interrupt, tacks on the front.
; OldKeyInterrupt is set to original contents of INT 09H.
; The input character is passed to the O.S. console input filter
; to determine if any special action should be taken.  The filter
; return value indicates if the character should be saved in the
; type ahead buffer or if it should be discarded.  A keyboard
; semaphore exists to indicate if a process is waiting for input.
; If the keboard semaphore is set all of the processes sleeping on
; it are woken up.

OldKeyInterrupt DD      0
KeySem		db	0		; non-zero if someone waiting on input

KeyboardInterrupt:
	INT	32H			; Save regs
	MOV	AX,RomData
	MOV	DS,AX
    ASSUME	DS:RomData

	PUSHF				; Save flags to simulate INT
	CALL	dword [CS:OldKeyInterrupt]	; Now do ROM code
; Now tell scheduler keyboard had char
	cli				; interrupts off!
	mov	bx,[BufferTail]		; Get tail of queue
	cmp	bx,[Bufferhead]		; Anything in keyboard queue?
	JE	NoKey			; No, don't requeue then
	dec	bx
	dec	bx
	cmp	bx,KeyBuffer
	jae	kbi1			; no rap around in buffer
	mov	bx,KeyBuffer+KeyBufLen
kbi1:
	mov	ax,[bx]			; get last queued char.
	mov	dx,5			; ConsInputFilter subfunction
	call	dword [CS:DosFunction]
	jnz	kbi2			; key should remain in buffer
	mov	[BufferTail],bx		; discard key from buffer
	jmp	SHORT NoKey
kbi2:
	cli
	CMP	[CS:KeySem],0		; Outstanding request?
	JE	NoKey			; No, may not be inited either
	push	ax
	push	bx
	push	cx
	push	dx
	mov	ax,cs
	mov	bx,KeySem
	mov	byte [CS:bx],0	; reset keyboard semaphore
	mov	dx,10			;; ProcRun
	call	dword [CS:DosFunction]		; awaken anyone waiting on input
	pop	dx
	pop	cx
	pop	bx
	pop	ax
NoKey:
	IRET

;-------------------------------------------------------------
; Keyboard INT 16 intercept routine to allow console input to sleep.
; Only console input function 1 is intercepted, all other functions
; are allowed to go directly to the ROM BIOS.  For the function 1
; the input status is checked, if a character is ready the function
; is allowed to go to the ROM BIOS.  Otherwise the keyboard semaphore
; is set and the process is put to sleep on the address of the
; semaphore.  When a key is typed the keyboard interrupt routine
; will wakeup any processes sleeping on this semaphore.
;
;	WARNING: The following routines can be entered recursively
;		 due to the fact that the ROM BIOS routines called
;		 reenable interrupts.  It's not usually a problem
;		 since interrupts will generally be processed faster
;		 than anyone can type.

OldKbdHandler	dd      0

;-------------------------------------------------------------

KeyBoardHandler:
	or	ah,ah
	je	DoLocalRead
	cmp	ah,1
	je	DoLocalStat
OldKBint:
	jmp	dword [CS:OldKbdHandler]

DoLocalStat:
	push	bx
	push	ds
	lds	bx,[CS:ScrnIOok]
	test	byte [bx],0FFh
	pop	ds
	pop	bx
	jnz	OldKBint
	xor	ax,ax
	RETF	2

DoLocalRead:
	push	ax
	push	bx
	push	cx
	push	dx
DoLocalRd1:
	push	ds
	lds	bx,[CS:ScrnIOok]
	mov	ax,ds
	test	byte [bx],0FFh
	pop	ds
	jnz	DoLocalRd2
	xor	cx,cx
	mov	dx,9			;; ProcBlock
	call	dword [CS:DosFunction]		; sleep until a char is typed
	jmp	DoLocalRd1

DoLocalRd2:
	mov	ah,1			; get console status
	pushf				; simulate INT to old handler
	cli
	call	dword [CS:OldKbdHandler]
	cli				; subfunction 1 unconditionally sets IF
	jnz	LocalRead		; go read character
	mov	ax,cs
	mov	bx,KeySem
	mov	byte [CS:bx],0FFh	; set keyboard semaphore
	xor	cx,cx
	mov	dx,9			;; ProcBlock
	call	dword [CS:DosFunction]		; sleep until a char is typed
	jmp	DoLocalRd1

LocalRead:
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	jmp	dword [CS:OldKbdHandler]		; read the character and return


end if	;CONSFLAG

;------------------------------------------------------
;
;	A U X - AUXILARY DEVICE DRIVER
;
label AUXDEV word;HEADER FOR DEVICE "AUX"
	DW	PRNDEV,BIOSEG
	DW	1000000000000000B
	DW	Strategy
	DW	AUX0$IN
	DB	'AUX     '

label COM1DEV word
	DW	LPT1DEV,BIOSEG
	DW	1000000000000000B
	DW	Strategy
	DW	AUX0$IN
	DB	'COM1    '

label COM2DEV word
	DW	-1,BIOSEG
	DW	1000000000000000B
	DW	Strategy
	DW	AUX1$IN
	DB	'COM2    '

AUXBUF	DB	0,0
;-------------------------------------------------------
;
;	READ FROM AUXILARY DEVICE
;
AUX$READ:
	JCXZ	EXVEC2
	CALL	GETBX
	XOR	AX,AX
	XCHG	AL,[BX]		;Get character and zero buffer
	OR	AL,AL
	JNZ	AUX2
AUX1:	CALL	AUXIN
AUX2:	STOSB			;STORE CHARACTER
	LOOP	AUX1
EXVEC2: JMP	StatusComplete

AUXIN:	MOV	AH,2		;INDICATES A READ
	CALL	AUXOP		;READ THE AUXILIARY PORT
	TEST	AH,0EH		;Check framing, parity, overrun
	JZ	AROK
	POP	AX		;Clean up the stack
	MOV	AL,0BH		;READ ERROR
	JMP	StatusPartialXfer
AROK:	RET
;--------------------------------------------------------
;
;	AUX NON-DESTRUCTIVE READ, NO WAITING
;
AUX$RDND:
	CALL	GETBX
	MOV	AL,[BX]		;GET KEY AND ZERO BUFFER
	OR	AL,AL
	JNZ	AUXRDX		;KEY IN BUFFER?
	CALL	AUXSTAT
	TEST	AH,00000001B		;TEST DATA READY
	JZ	AUXBUS
	TEST	AL,00100000B		;TEST DATA SET READY
	JZ	AUXBUS
	CALL	AUXIN
	CALL	GETBX
	MOV	[BX],AL	    ;GET AND SAVE KEY
AUXRDX: JMP	StatusComplete
AUXBUS: JMP	StatusDevReady
;----------------------------------------------------------
;
;	AUX OUTPUT STATUS
;
AUX$WRST:
	CALL	AUXSTAT
	TEST	AL,00100000B	;TEST DATA SET READY
	JZ	AUXBUS
	TEST	AH,00100000B	;TEST CLEAR TO SEND
	JZ	AUXBUS
	JMP	EXVEC2

AUXSTAT:
	MOV	AH,3
AUXOP:	CALL	GETDX
	INT	14H
	RET
;---------------------------------------------------------
;
;	FLUSH AUX INPUT BUFFER
;
AUX$FLSH:
	CALL	GETBX
	MOV	byte [BX],0
	JMP	EXVEC2
;---------------------------------------------------------
;
;	WRITE TO AUXILARY DEVICE
;
AUX$WRIT:
	JCXZ	EXVEC2
AUX$LOOP:
	MOV	AL,[ES:DI]	;GET CHAR
	INC	DI		;POINT TO NEXT ONE
	MOV	AH,1		;INDICATES A WRITE
	CALL	AUXOP		;SEND CHARACTER OVER AUX PORT
	TEST	AH,80H		;CHECK FOR ERROR
	JZ	AWOK
	MOV	AL,10		;INDICATE WRITE FAULT
	JMP	StatusPartialXfer
AWOK:	LOOP	AUX$LOOP
	JMP	EXVEC2

GETBX:	CALL	GETDX
	MOV	BX,DX
	ADD	BX,AUXBUF
	RET
;-------------------------------------------------------------
;
;	P R N - PRINTER DEVICE
;
label PRNDEV word;HEADER FOR DEVICE "PRN"
	DW	TIMDEV,BIOSEG
	DW	1000000000000000B
	DW	Strategy
	DW	PRN0$IN
	DB	'PRN     '

label LPT1DEV word
	DW	LPT2DEV,BIOSEG
	DW	1000000000000000B
	DW	Strategy
	DW	PRN0$IN
	DB	'LPT1    '

label LPT2DEV word
	DW	LPT3DEV,BIOSEG
	DW	1000000000000000B
	DW	Strategy
	DW	PRN1$IN
	DB	'LPT2    '

label LPT3DEV word
	DW	COM2DEV,BIOSEG
	DW	1000000000000000B
	DW	Strategy
	DW	PRN2$IN
	DB	'LPT3    '

ERRFLG	DB	0

;----------------------------------------------------------
;
;	WRITE TO PRINTER DEVICE
;
PRN$WRIT:
	JCXZ	EXVEC3
PRN$LOOP:
	MOV	AL,[ES:DI]	;GET CHAR INTO AL
	INC	DI		;POINT TO NEXT CHAR
	MOV	[CS:ERRFLG],0	;INITIALIZE RETRY FLAG

PRETRY: XOR	AH,AH		;AH=0
	CALL	PRNOP		;TO INDICATE PRINT CHAR IN AL

ERRCHK: JZ	PROK
	XOR	[CS:ERRFLG],1	      ;DO 1 AUTOMATIC RETRY
	JNZ	PRETRY
PMESSG: JMP	StatusPartialXfer	  ;RETURN WITH THE ERROR

PROK:	LOOP	PRN$LOOP
EXVEC3: JMP	StatusComplete
;--------------------------------------------------------
;
;	PRINTER STATUS ROUTINE
;
PRN$STAT:
	CALL	PRNSTAT		;DEVICE IN DX
	JNZ	PMESSG
	TEST	AH,10000000B
	JNZ	EXVEC3
	JMP	StatusDevReady

PRNSTAT:
	MOV	AH,2
PRNOP:	CALL	GETDX
	INT	17H

	MOV	AL,2
	TEST	AH,0001B	;TEST FOR NOT READY
	JNZ	PRNOP2

	MOV	AL,10		;WRITE FAULT CODE
	TEST	AH,1000B	;TEST FOR I/O ERROR
	JZ	PRNOP2

	TEST	AH,00100000B	;OUT-OF-PAPER?
	JZ	PRNOP1
	MOV	AL,9		;OUT OF PAPER CODE
PRNOP1: OR	AL,AL		;SET NZ FLAG
PRNOP2: RET


;**	Time Functions
;
;	Uses clock with 1000 ticks per second. User sees only
;	time in hours, minutes, seconds, and 1/100 second, in registers
;	CH, CL, DH, DL respectively. (Each is a binary number.)
;	      Modified for 4.0. The ROM bios timer routines are completely
;	replaced with code on this page. This provides a better time base
;	for the scheduler.


label TIMDEV word
	DW	Floppydevice,BIOSEG
	DW	1000000000001000B
	DW	Strategy
	DW	TIM$IN
	DB	'CLOCK$  '

DAYCNT	DW	0

;--------------------------------------------------------------------
;
; Settime sets the current time
;
; On entry ES:[DI] has the current time:
;
;	number of days since 1-1-80	(WORD)
;	minutes (0-59)			(BYTE)
;	hours (0-23)			(BYTE)
;	hundredths of seconds (0-99)	(BYTE)
;	seconds (0-59)			(BYTE)
;
; Each number has been checked for the correct range.

TIM$WRIT:
	PUSH	BX
	MOV	AX,[ES:DI]
	MOV	[CS:DAYCNT],AX
	MOV	CX,[ES:DI+2]
	MOV	AL,60
	MUL	CH		;Hours to minutes
	MOV	CH,0
	ADD	AX,CX		;Total minutes
	MOV	CX,60000	;60*1000
	MUL	CX		;Convert to milliseconds
	MOV	SI,AX
	MOV	BX,DX		; Save hours, min in Msecs in BX:SI
	MOV	AL,[ES:DI+5]	; Get # seconds
	MOV	CX,100
	MUL	CL		; Get seconds in 1/100s
	MOV	CL,[ES:DI+4]	; Hundredths of second
	ADD	AX,CX		; Now have seconds and 1/100ths
	MOV	CL,10
	MUL	CX		; Get DX:AX = milliseconds
	ADD	AX,SI
	MOV	[CS:TickLow],AX
	ADC	BX,0
	MOV	[CS:TickHigh],BX	; Set time in milliseconds
	POP	BX
	JMP	StatusComplete


;***************************************
;
; Gettime reads date and time
; and returns the following information:
;
;	ES:[DI]	 =count of days since 1-1-80
;	ES:[DI+2]=minutes
;	ES:[DI+3]=hours
;	ES:[DI+4]=hundredths of seconds
;	ES:[DI+5]=seconds
;
;***************************************
TIM$READ:
	PUSH	BX
	MOV	AX,[CS:DAYCNT]
	STOSW			; return day
	MOV	DX,[CS:TickHigh]
	MOV	AX,[CS:TickLow]	; Get current time
	MOV	CX,60000	; # milliseconds in a minute
	DIV	CX		; Get AX= minutes, DX = seconds&msecs
	MOV	BX,DX		; Save seconds and fraction
	XOR	DX,DX
	MOV	CX,60		; # minutes/hour
	DIV	CX		; Get AX= hour, DX= minute
	xchg	ax,dx
	STOSB			; Return minutes
	xchg	ax,dx
	STOSB			; Return hours
	MOV	AX,BX
	XOR	DX,DX
	MOV	CX,1000
	DIV	CX		; Get AX= seconds, DX= milliseconds
	xchg	ax,bx		; (bx) = seconds
	MOV	AX,DX
	XOR	DX,DX
	MOV	CX,10
	DIV	CX		; Get hundredths of second
	STOSB			; Return hundredths of second
	xchg	ax,bx
	STOSB			; Return second
	POP	BX
	JMP	StatusComplete


;COMMENT *
;   The clock code in the ROM is replaced with the following code which
;provides the clock interface to the scheduler and a 1 ms time base. The
;1AH interrupt is simulated to return the approximate time for those
;routines which still call 1AH. The time period for motor start up is
;preserved since that code has not yet been rewritten.
;	*

if SEGSEL = S_CODE
RomData = 040H
virtual at 0
	ORG	03FH
Motor_Status	DB	1 dup (0)
Motor_Count	DB	1 dup (0)
end virtual
end if

TickLow		DW      0; Low part of time in Msec
TickHigh	DW      0; High part of time in msec
MotorFlag	DB	0		; There is an active motor
MotorTick	DB	MOTORCOUNT	; # ticks until 1/18.2 secs
SchedTick	DB	SCHEDCOUNT	; Scheduler countdown

; Interrupt 8H -	timer interrupt

    ASSUME	DS:NOTHING
TimerInterrupt:
	PUSH	AX
	INC	[CS:TickLow]
	JNZ	NoOverFlow
	INC	[CS:TickHigh]
NoOverFlow:
	CMP	[CS:TickHigh],1318		; Close to 24 hours?
	JNZ	NotDay			; No
	CMP	[CS:TickLow],23552		; Reach 24 hours?
	JNZ	NotDay			; No
; Have reached a day, bump day count
	INC	[CS:DAYCNT]
	XOR	AX,AX
	MOV	[CS:TickHigh],AX
	MOV	[CS:TickLow],AX		; Reset time of day
NotDay:
;;	DEC	MotorTick		; Time to decrement motor?
;;	JNZ	CheckSched			; No
;;	MOV	MotorTick,MOTORCOUNT	; Reset 1/18 sec worth of msecs
;;	PUSH	DS
;;	MOV	AX,RomData
;;	MOV	DS,AX
;;    ASSUME	DS:RomData

;;	TEST	MotorFlag,0FFH		; Active motor timer?
;;	JZ	CheckMotor		; No, see if new one
;;	DEC	Motor_Count
;;	JNZ	CheckMotor		; Not time to shut down
;;	AND	Motor_Status,0F0H	; Turn off motor running bits
;;	MOV	AL,0CH
;;	PUSH	DX
;;	MOV	DX,03F2H
;;	OUT	DX,AL			; Turn off the motors
;;	POP	DX
;;	MOV	MotorFlag,0		; No motor timeout running
;;	POP	DS
;;	JMP	CheckSched		; Go see if time to sched

;;CheckMotor:
;;	MOV	AL,Motor_Count
;;	POP	DS
;;	JNZ	CheckSched		; Motor already active
;;	OR	AL,AL			; Need to start countdown?
;;	JZ	CheckSched		; No
;;	MOV	MotorFlag,0FFH		; Yes, set flag
;;	MOV	MotorTick,MOTORCOUNT	; 1/18.2 sec later

; The scheduler is called every 10ms, rather than every 1 ms to see if
; it should switch tasks.
CheckSched:
; First reset the timer so will interrupt again
	MOV	AL,36H
	OUT	43H,AL
	MOV	AL,169
	OUT	40H,AL
	MOV	AL,4
	OUT	40H,AL			; Set 1 msec delay
	MOV	AL,20H
	OUT	20H,AL			; Tell 8259 interrupt done
; Now see if should call scheduler
	DEC	[CS:SchedTick]		; Time to call scheduler?
	JNZ	NoSched			; No, all done
	MOV	[CS:SchedTick],SCHEDCOUNT	; Reset countdown
csch1:	POP	AX			; Stack is now clean
	INT	32H			; Save all regs
	CMP	word [CS:DosFunction+2],0	; Dos installed?
	JE	NoSchedActive		; Not yet, don't call sched
	sub	dx,dx			; (dx) = 0 = tic subfunction
	mov	ax,SCHEDCOUNT		; 10 milliseconds per tic
	CALL	dword [CS:DosFunction]		; Do the tick
	CALL	FloppyTimer$FAR		; timer service for floppy disk also
NoSchedActive:
	IRET				; All done

NoSched:
	POP	AX
INTRET: IRET				; All done

; INT 1AH -	Get/Set time based in 55msec tick

TimeOfDay:
	OR	AH,AH			; Function 0: Read time?
	JZ	ReadOld			; Yes
	DEC	AH			; Function 1: Write time?
	JZ	WriteOld		; Yes
	IRET				; No, bad function code

; Read old( 1/18.2 second tick ) time
ReadOld:
	MOV	AX,[CS:TickHigh]
	xor	dx,dx
	MOV	CX,MOTORCOUNT		; # milliseconds in 1/18.2 secs
	DIV	CX			; Get value in old ticks
	push	ax
	MOV	AX,[CS:TickLow]
	div	cx
	pop	cx			; get high order count
	XOR	AL,AL			; Never have oveflow
	IRET				; Return the time

; Set time using old resolution
WriteOld:
	MOV	AX,DX
	push	bx
	MOV	BX,MOTORCOUNT		; Conversion factor
	MUL	BX
	MOV	[CS:TickLow],AX		; Set low part of time
	mov	ax,cx
	mov	cx,dx
	MUL	BX
	pop	bx
	ADD	AX,CX			; Combine high parts
	MOV	[CS:TickHigh],AX		; Set time
	IRET				; Return with new time set

;++++
memsizmsg	db	13,10,'Error - Interrupt 12',13,10,0
memsizint	dd	0

memsizhandler:
	push	ax
	push	bx
	push	si
	push	ds
	push	cs
	pop	ds
	mov	SI,memsizmsg
	call	WRMSG
	pop	ds
	pop	si
	pop	bx
	pop	ax
	jmp	dword [CS:memsizint]
;++++

;----------------------------------------------
;	WRITE OUT MESSAGE POINTED TO BY [SI]
;
WRMSG:	LODSB			;GET THE NEXT CHARACTER OF THE MESSAGE
	AND	AL,7FH		;SEE IF END OF MESSAGE
	JZ	WRMRET
	MOV	BX,7
	MOV	AH,14		;WRITE CHARACTER
	INT	10H		;SEND THE CHARACTER
	JMP	SHORT WRMSG
WRMRET: RET

	INCLUDE 'BUGCODE.INC'

end if

;-----------------------------------------------------------------
;
;	DISK INTERFACE ROUTINES
;
if SEGSEL = S_BIOSINIT

DRVMAX	DB	  4

    ASSUME	CS:BiosSeg

MAXERR	=	5
LSTDRV	=	504H

label WRTVERIFY word
RFLAG	DB	2	;2 for read, 3 for write
VERIFY	DB	0	;1 if verify after write
SINGLE	DB	0	;1 if single drive system
SWPFLG	DB	0	;1 if BIOS swapped out
SECCNT	DW	0
HARDNUM DB	99	;logical drive number of first hardfile

RESSEC	=	3
DRVLIM	=	8	;Number of sectors on device
SECLIM	=	13	;MAXIMUM SECTOR
HDLIM	=	15	;MAXIMUM HEAD
HIDSEC	=	17	;NUMBER OF HIDDEN SECTORS

;WARNING - preserve order of drive and curhd! -c.p.

DRIVE	DB	0	;PHYSICAL DRIVE CODE
CURHD	DB	0	;CURRENT HEAD
CURSEC	DB	0	;CURRENT SECTOR
CURTRK	DW	0	;CURRENT TRACK


ERRIN:	;DISK ERRORS RETURNED FROM THE IBM ROM
	DB	80H		;NO RESPONSE
	DB	40H		;Seek failure
	DB	10H		;BAD CRC
	DB	8		;DMA OVERRUN
	DB	4		;SECTOR NOT FOUND
	DB	3		;WRITE ATTEMPT TO WRITE-PROTECT DISK
LSTERR	DB	0		;ALL OTHER ERRORS


ERROUT: ;RETURNED ERROR CODES CORRESPONDING TO ABOVE
	DB	2		;NO RESPONSE
	DB	6		;SEEK FAILURE
	DB	4		;BAD CRC
	DB	4		;DMA OVERRUN
	DB	8		;SECTOR NOT FOUND
	DB	0		;WRITE ATTEMPT ON WRITE-PROTECT DISK
	DB	12		;GENERAL ERROR

NUMERR= ERROUT-ERRIN
;---------------------------------------------------------------------
SPSAV	DW	0	;SAVE THE STACK POINTER
;

GETBP:	PUSH	AX
	PUSH	CX
	PUSH	DX
	PUSH	BX
	MOV	CL,AH		;SAVE MEDIA
	AND	CL,0F8H		;NORMALIZE
	CMP	CL,0F8H		;COMPARE WITH GOOD MEDIA BYTE
	JZ	GOODID
	MOV	AH,0FEH		;DEFAULT TO 8-SECTOR, SINGLE-SIDED
GOODID: MOV	DI,HDRIVE
	CMP	AL,[CS:HARDNUM]
	JZ	GETRET
	JB	GETBP1
	MOV	DI,DRIVEX
	JMP	SHORT GETRET

GETBP1: MOV	AL,1		;SET NUMBER OF FAT SECTORS
	MOV	BX,64*256+8	;SET DIR ENTRIES AND SECTOR MAX
	MOV	CX,40*8		;SET SIZE OF DRIVE
	MOV	DX,01*256+1	;SET HEAD LIMIT AND SEC/ALL UNIT
	MOV	DI,FDRIVE
	TEST	AH,00000010B	;TEST FOR 8 OR 9 SECTOR
	JNZ	HAS8		;NZ = HAS 8 SECTORS
	INC	AL		;INC NUMBER OF FAT SECTORS
	INC	BL		;INC SECTOR MAX
	ADD	CX,40		;INCREASE SIZE
HAS8:	TEST	AH,00000001B	;TEST FOR 1 OR 2 HEADS
	JZ	HAS1		;Z = 1 HEAD
	ADD	CX,CX		;DOUBLE SIZE OF DISK
	MOV	BH,112		;INCREASE NUMBER OF DIRECTORY ENTRIES
	INC	DH		;INC SEC/ALL UNIT
	INC	DL		;INC HEAD LIMIT
HAS1:	MOV	[CS:DI+2],DH
	MOV	[CS:DI+6],BH
	MOV	[CS:DI+8],CX
	MOV	[CS:DI+10],AH
	MOV	[CS:DI+11],AL
	MOV	[CS:DI+13],BL
	MOV	[CS:DI+15],DL
GETRET: POP	BX
RET88:	POP	DX
	POP	CX
	POP	AX
	RET

;*********************************************************************
;	"FDRIVE" IS A FLOPPY DISK, VARIOUS PARAMETERS ARE PATCHED
;	BY GETBP TO REFLECT THE TYPE OF MEDIA INSERTED
FDRIVE:
	DW	512		;Physical sector size in bytes
	DB	1		;Sectors/allocation unit
	DW	1		;Reserved sectors for DOS
	DB	2		;No. allocation tables
	DW	64		;Number directory entries
	DW	9*40		;Number sectors (at 512 bytes ea.)
	DB	11111100B	;Media descriptor
	DW	2		;Number of FAT sectors
	DW	9		;Sector limit
	DW	1		;Head limit
	DW	0		;Hidden sector count

;------------------------------------------------------------
;
;	DISK I/O HANDLER
;
;	AL = DRIVE NUMBER (0-3)
;	AH = MEDIA DESCRIPTOR
;	CX = SECTOR COUNT
;	DX = FIRST SECTOR
;	ES:DI = TRANSFER ADDRESS
;	[RFLAG]=OPERATION (2=READ, 3=WRITE)
;	[VERIFY]=1 FOR VERIFY AFTER WRITE
;
;	IF SUCCESSFUL CARRY FLAG = 0
;	  ELSE CF=1 AND AL CONTAINS ERROR CODE
;
DISKRD:
;	debug	1,4,<DISKRD: $x $x $x $x:$x\n>,<ax,cx,dx,es,di>
	MOV	[CS:RFLAG],2
DISKIO:
	CLC
	JCXZ	IORET
	MOV	[CS:TIM_DRV],AL		;SAVE DRIVE LETTER

	MOV	[CS:SPSAV],SP		;SAVE SP
	XCHG	BX,DI			;ES:BX = TRANSFER ADDRESS
	CALL	GETBP			;CS:DI = PTR TO B.P.B
	MOV	SI,DX
	ADD	SI,CX
	ADD	DX,[CS:DI+HIDSEC]	;ADD IN THE HIDDEN SECTORS
	CMP	SI,[CS:DI+DRVLIM]	;COMPARE AGAINST DRIVE MAX
	JBE	INRANGE
	MOV	AL,8
STCRET: STC
IORET:	RET

INRANGE:CMP	AL,[CS:HARDNUM]
	JB	NOTHARD
	MOV	AL,[CS:HARDDRV] ;SET DRIVE NUMBER OF HARDFILE
	JZ	RDWR
	INC	AL
	JMP	SHORT RDWR

NOTHARD:CMP	[CS:SINGLE],1	;SINGLE FLOPPY INSTALLED?
	JNZ	RDWR
	CALL	SWPDSK		;ASK USER FOR CORRECT DISK
RDWR:
	MOV	[CS:DRIVE],AL
	MOV	[CS:SECCNT],CX	;SAVE SECTOR COUNT
	XCHG	AX,DX		;SETUP LOGICAL SECTOR FOR DIVIDE
	XOR	DX,DX
	DIV	word [CS:DI+SECLIM] ;DIVIDE BY SEC PER TRACK
	INC	DL
	MOV	[CS:CURSEC],DL		  ;SAVE CURRENT SECTOR
	MOV	CX,[CS:DI+HDLIM]	;GET NUMBER OF HEADS
	XOR	DX,DX		;DIVIDE TRACKS BY HEADS PER CYLINDER
	DIV	CX
	MOV	[CS:CURHD],DL	;SAVE CURRENT HEAD
	MOV	[CS:CURTRK],AX	;SAVE CURRENT TRACK

;	debug	1,4,< Drv $b  Hd $b  Trk $x  Sec $b\n>,<<word ptr DRIVE>,<word ptr CURHD>,CURTRK,<word ptr CURSEC>>
	MOV	AX,[CS:SECCNT]
	MOV	SI,ES		;Check for 64k boundary error
	SHL	SI,1
	SHL	SI,1
	SHL	SI,1
	SHL	SI,1		;Segment converted to absolute address
	ADD	SI,BX		;Combine with offset
	ADD	SI,511		;Add sector size and see if overflow
	JC	BUFIO		;Must handle special if so

	XCHG	BX,SI
	SHR	BH,1
	MOV	AH,128		;Max. sectors in 64K
	SUB	AH,BH		;Number of sectors left in this 64K
	XCHG	BX,SI

	CMP	AH,AL		;Does it exceed total request?
	JBE	FIRBLK
	MOV	AH,AL		;If so, limit transfer to the request
FIRBLK:
;At this point, AL=total number of sectors to be read, AH=number
;  of sectors that can be read before 64K boundary error. AH<=AL.
;    ES:BX points to load area, DS:DI points to B.P.B

	PUSH	AX
	MOV	AL,AH		;No. of sectors to read at once (<>0)
	CALL	BLOCK		;Transfer portion before boundary
	POP	AX
	SUB	AL,AH
	JZ	DONE
BUFIO:
	PUSH	AX
	PUSH	ES
	PUSH	BX		;SAVE CURRENT TRANSFER ADDRESS
	CALL	SWAP		;SWAP BUFFER WITH BIOS CODE

	ADD	BH,2		;POINT TO TEMP BUFFER
	CALL	DISK1		;Perform disk operation

	POP	BX		;RECALL TRANSFER ADDRESS
	POP	ES
	POP	AX
	CALL	SWAP		;SWAP BACK

	DEC	AL		;Dec sectors to read by 1
	ADD	BH,2		;Add 200H to transfer address
	CALL	BLOCK		;Read the remaining sectors
DONE:
;	debug	1,4,< DISKIO DONE\n>
	CLC			;No error
	RET			;From subroutine DISKIO

;	Swap 512 bytes of BIOS with transfer address

SWAP:	PUSH	DI
	PUSH	BX
	PUSH	AX
	MOV	DI,BX		;ES:DI POINTS TO USER BUFFER
	ADD	BH,2
	MOV	SI,BX		;ES:SI POINTS TO TEMP BUFFER
	CLD
;	debug	1,4,< SWAP $x:$x <==> $x:$x\n>,<es,di,es,si>
	MOV	CX,256			;256 WORDS TO SWAP
SWAP1:	MOV	BX,word [ES:DI]	;GET USER WORD
	MOV	AX,word [ES:SI]	;GET SCRATCH WORD
	MOV	word [ES:SI],BX	;PUT SCRATCH WORD
	STOSW				;PUT BIOS WORD
	INC	SI
	INC	SI
	LOOP	SWAP1
	XOR	[CS:SWPFLG],1		;TOGGLE SWAPPED FLAG
	POP	AX
	POP	BX
	POP	DI
RETZ:	RET

;Read the number of sectors specified in AL, handling track boundaries

BLOCK:	OR	AL,AL		;See if any sectors to read
	JZ	RETZ

	MOV	AH,[CS:DI+SECLIM]	;Sectors per track
	INC	AH
	SUB	AH,[CS:CURSEC]	;Number of sectors left on this track
	CMP	AH,AL		;Compare with no. of sectors needed
	JBE	DOIO
	MOV	AH,AL		;Limit to only those requested
DOIO:
	PUSH	AX
	MOV	AL,AH		;Put count where ROM needs it
	CALL	DISK		;Call ROM and trap errors
	POP	AX
	SUB	AL,AH		;Reduce request by amount just done
	SHL	AH,1		;AH * 2^8 = no. of bytes
	ADD	BH,AH		;Bump address pointer
	JMP	BLOCK

;Perform disk I/O with retries
; AL = number of sectors (1-8, all on one track)
; ES:BX = Transfer address (must not cross a 64K physical boundary)
; [RFLAG] = 2 if read, 3 if write
; [VERIFY] = 0 for normal, 1 for verify after write

DISK1:	MOV	AL,1		;Only one sector for buffered I/O

DISK:	MOV	SI,MAXERR
	MOV	AH,[CS:RFLAG]	;Get read/write indicator

RETRY:	PUSH	AX

CALLROM:MOV	DX,[CS:CURTRK]	;Load current cylinder
	MOV	CL,6		;move high bits of cyl to sec
	SHL	DH,CL
	OR	DH,[CS:CURSEC]
	MOV	CX,DX
	XCHG	CH,CL			 ;CL = sector, CH = cylinder
	MOV	DX,word [CS:DRIVE]	 ;Load physical drive number
					 ;and current head number
;;	debug	1,4,< CALLROM $x $x $x $x  $x\n>,<ax,bx,cx,dx,es>
	INT	13H			 ;Request disk read/write
	JC	DSKERR
	POP	AX		;Restore sector count
	PUSH	AX
	CMP	[CS:WRTVERIFY],103H	;Check for write and verify
	JNZ	NOVERIFY
	MOV	AH,4		;Request verify
	INT	13H
	JC	DSKERR
NOVERIFY:
;;	debug	1,4,< back from ROM\n>,<>
	POP	AX
	AND	CL,03FH		;Eliminate cylinder bits from sector
	XOR	AH,AH
	SUB	[CS:SECCNT],AX	;Reduce count of sectors to go
	ADD	CL,AL		;Next sector
	MOV	[CS:CURSEC],CL
	CMP	CL,[CS:DI+SECLIM]	; Reached limit?
	JBE	RET1

	MOV	[CS:CURSEC],1	;Start with first sector of next track
	MOV	DH,[CS:CURHD]
	INC	DH
	CMP	DH,[CS:DI+HDLIM]
	JB	NOXOR
	XOR	DH,DH
	INC	[CS:CURTRK]	;NEXT TRACK
NOXOR:	MOV	[CS:CURHD],DH

RET1:	RET

DSKERR:
;	debug	1,4,< DSKERR $x >,<ax>
	PUSH	AX		;Save error code
	MOV	AH,0		;Ask for disk reset
	INT	13H
	POP	AX		;Restore error code
	DEC	SI		;decrement retry count
	JZ	HARDERR
	CMP	AH,80H		;Timeout?
	JZ	HARDERR		;***
DSKERR1:POP	AX		;Restore sector count
	JMP	RETRY

HARDERR:
	CMP	[CS:SWPFLG],0	;If BIOS swapped out
	JZ	HARD1
	POP	BX		;Get disk1 return address
	POP	BX		;Get low part of transfer address
	POP	ES		;Get high part of transfer address
	CALL	SWAP		;swap it back in
HARD1:	PUSH	CS
	POP	ES		;Make ES the local segment
	MOV	AL,AH		;Put error code in AL
	MOV	[CS:LSTERR],AL	;Terminate list with error code
	MOV	CX,NUMERR	;Number of possible error conditions
	MOV	DI,ERRIN ;Point to error conditions
	REPNE	SCASB
	MOV	AL,[ES:NUMERR-1+DI] ;Get translation
	MOV	CX,[CS:SECCNT]	;Get count of sectors to go
	MOV	SP,[CS:SPSAV]	;Recover entry stack pointer
	STC			;Flag error condition
	RET			;and return

INITAB	DW	FDRIVE
	DW	FDRIVE
	DW	FDRIVE
	DW	FDRIVE
INITABH DW	HDRIVE
	DW	DRIVEX

if SEGSEL = S_CODE
RomData = 040H
virtual at 0
	ORG	03EH
Seek_Status	DB	1 dup (0)
end virtual
end if


;-------------------------------------------------
;
;  ASK TO SWAP THE DISK IN DRIVE A:
;
SWPDSK: PUSH	DS
	XOR	SI,SI		;Select segment 0
	MOV	DS,SI
	MOV	AH,AL			;Make copy of drive number
	XCHG	AH,[DS:LSTDRV]		;Xchange with last drive used
	CMP	AL,AH		;See if same as last drive
	JZ	RDWR0
;Using a different drive in a one drive system so request the user change disks
	ADD	AL,"A"		;Add "A" to convert to drive letter
	MOV	[CS:DRVLET],AL
	push	cs
	pop	ds
	MOV	SI,SNGMSG
	PUSH	BX
	CALL	WRMSG		;Print disk change message
	XOR	AH,AH
	INT	16H		;Wait for a keyboard character
	POP	BX
RDWR0:
	POP	DS
	XOR	AL,AL		;Always use drive 0
	RET


SNGMSG	DB	CR,LF,"Insert diskette for drive "
DRVLET	DB	"A: and strike",CR,LF,"any key when ready",CR,LF,LF,0
HNUM	DB	0		;NUMBER OF HARDFILES


;**	End of Permanently Resident BIOS


HARDDRV DB	80H	;Physical drive number of first hardfile
;**********************************************************************
;	"HDRIVE" IS A HARD DISK WITH 512 BYTE SECTORS
;*********************************************************************
HDRIVE:
	DW	512
	DB	1		;Sectors/allocation unit
	DW	1		;Reserved sectors for DOS
	DB	2		;No. of allocation tables
	DW	16		;Number of directory entries
	DW	0000		;Number of sectors (at 512 bytes each)
	DB	11111000B	;Media descriptor
	DW	1		;Number of FAT sectors
	DW	00		;Sector limit
	DW	00		;Head limit
	DW	00		;Hidden sector count
;**********************************************************************
;	"DRIVEX " IS AN EXTRA TYPE OF DRIVE USUALLY RESERVED FOR AN
;	ADDITIONAL HARD FILE
;*********************************************************************
DRIVEX:
	DW	512
	DB	00		;Sectors/allocation unit
	DW	1		;Reserved sectors for DOS
	DB	2		;No. of allocation tables
	DW	0000		;Number of directory entries
	DW	0000		;Number of sectors (at 512 bytes each)
	DB	11111000B	;Media descriptor
	DW	0000		;Number of FAT sectors
	DW	00		;Sector limit
	DW	00		;Head limit
	DW	00		;Hidden sector count

;*********************************************************
;	SYSTEM INITIALIZATION
;
;	THE ENTRY CONDITIONS ARE ESTABLISHED BY THE BOOTSTRAP
;	LOADER AND ARE CONSIDERED UNKNOWN. THE FOLLOWING JOBS
;	WILL BE PERFORMED BY THIS MODULE:
;
;	1.	ALL DEVICE INITIALIZATION IS PERFORMED
;	2.	A LOCAL STACK IS SET UP AND DS:SI ARE SET
;		TO POINT TO AN INITIALIZATION TABLE. THEN
;		AN INTER-SEGMENT CALL IS MADE TO THE FIRST
;		BYTE OF THE DOS
;	3.	ONCE THE DOS RETURNS FROM THIS CALL THE DS
;		REGISTER HAS BEEN SET UP TO POINT TO THE START
;		OF FREE MEMORY. THE INITIALIZATION WILL THEN
;		LOAD THE COMMAND PROGRAM INTO THIS AREA
;		BEGINNING AT 100 HEX AND TRANSFER CONTROL TO
;		THIS PROGRAM.
;
;********************************************************

DRVFAT	DW	0000		;DRIVE AND FAT ID OF DOS
BIOS$	DW	0000		;FIRST SECTOR OF DATA
DOSCNT	DW	0000		;HOW MANY SECTORS TO READ

BootBufr	=	17C0H	; High memory scratch area

    ASSUME	DS:NOTHING,ES:NOTHING

INIT:	mov	dx,1000h
	MOV	SS,DX
	MOV	SP,7C00h	;LOCAL STACK  1000:7C00
	STI
	PUSH	CX		;Save number of floppies
	MOV	[CS:BIOS$],BX
	PUSH	AX		;Save Drive info
	MOV	AL,EOI
	OUT	AKPORT,AL	;TURN ON THE TIMER

	MOV	SI,LPT3DEV
	CALL	PRINT_INIT		;INIT LPT3
	MOV	SI,LPT2DEV
	CALL	PRINT_INIT		;INIT LPT2
	MOV	SI,LPT1DEV
	CALL	PRINT_INIT		;INIT LPT1

	MOV	SI,COM2DEV
	CALL	AUX_INIT		;INIT COM2
	MOV	SI,COM1DEV
	CALL	AUX_INIT		;INIT COM1
;*	Can't do any DEBUG prints till now
;	debug	1,1,<AUX and PRN devices initialized\n>,<>
	XOR	DX,DX
	MOV	DS,DX			;TO INITIALIZE PRINT SCREEN VECTOR
	MOV	ES,DX

	MOV	AX,CS					;FETCH SEGMENT

IF	CONSFLAG
	MOV	word [DS:BRKADR],Break
	MOV	[DS:BRKADR+2],AX			;VECTOR FOR BREAK
	MOV	word [DS:CHROUT*4],OUTCHR
	MOV	[DS:CHROUT*4+2],AX
end if
	MOV	word [DS:DSKADR],SEC9		;DISK PARAMETERS
	MOV	[DS:DSKADR+2],ES

	MOV	DI,4
	MOV	BX,INTRET		; Rest just return
	XCHG	AX,BX
	STOSW						;Location 4
	XCHG	AX,BX
	STOSW				;INT 1		;Location 6
	ADD	DI,4
	XCHG	AX,BX
	STOSW						;Location 12
	XCHG	AX,BX
	STOSW				;INT 3		;Location 14
	XCHG	AX,BX
	STOSW						;Location 16
	XCHG	AX,BX
	STOSW				;INT 4		;Location 18
; Set up some vectors for scheduler and change rom interrupts
;
	CLI				; Disable, changing int vectors
	ADD	DI,3*4			; Move up to INT 8
	MOV	CX,TimerInterrupt
	XCHG	AX,CX
	STOSW
	XCHG	AX,CX
	STOSW				; Set new INT 8: Timer
IF	CONSFLAG
	MOV	CX,[DS:DI]		; Save old addr to hook to
	MOV	word [CS:OldKeyInterrupt],CX
	MOV	CX,[DS:2+DI]
	MOV	word [CS:OldKeyInterrupt+2],CX
	MOV	CX,KeyboardInterrupt
	XCHG	AX,CX
	STOSW
	XCHG	AX,CX
	STOSW				; Set new keyboard interrupt
ELSE
	ADD	DI,4
end if
	XCHG	AX,BX
	STOSW
	XCHG	AX,BX			; INT 0A unused
	STOSW
	XCHG	AX,BX
	STOSW
	XCHG	AX,BX			; INT 0B unused
	STOSW
	add	di,4*6			; skip 0C - 11
	MOV	CX,[DS:DI]		; Save INT 12 addr to hook to
	MOV	word [CS:memsizint],CX
	MOV	CX,[DS:2+DI]
	MOV	word [CS:memsizint+2],CX
	mov	cx,memsizhandler
	xchg	ax,cx
	stosw
	xchg	ax,cx
	stosw
	add	di,4*2			; skip 13 - 14
	STI
; End of new 3.0 vectors
	XCHG	AX,BX
	STOSW				;INT 15		;Location 60
	XCHG	AX,BX
	STOSW						;Location 62
IF	CONSFLAG
	MOV	CX,[DS:DI]		; Save INT 16 addr to hook to
	MOV	word [CS:OldKbdHandler],CX
	MOV	CX,[DS:2+DI]
	MOV	word [CS:OldKbdHandler+2],CX
	MOV	CX,KeyBoardHandler
	XCHG	AX,CX
	STOSW
	XCHG	AX,CX			; Set new keyboard Handler
	STOSW
; Set new get/set time vector, time base changed
	ADD	DI,4*3			; skip 17 - 19
ELSE
	ADD	DI,4*4			; skip 16 - 19
end if	;CONSFLAG
	MOV	CX,TimeOfDay
	XCHG	AX,CX
	STOSW				; setup 1A to TimeofDay
	XCHG	AX,CX
	STOSW
	ADD	DI,4*23			; skip 1B - 31
	XCHG	AX,BX
	STOSW				; no-op INT 32 until Sched:SchedInit
	XCHG	AX,BX
	STOSW
;	debug	1,1,<Interrupt vectors initialized\n>,<>

	MOV	word [DS:500H],DX	;SET PRINT SCREEN & BREAK =0
	MOV	word [DS:LSTDRV],DX	;clean out last drive spec

	MOV	DI,SEC9			;location of drive table
	MOV	AX,02DFH		;Stuff the disk speedup/9 sector
	STOSW					;code
	MOV	AX,0225H
	STOSW
	MOV	AX,2A09H
	STOSW
	MOV	AX,50FFH
	STOSW
	MOV	AX,00F6H
	STOSW
	MOV	AL,2
	STOSB

	pushf				;simulate int 12h
	call	dword [CS:memsizint]		;Get memory size--1K blocks in AX
	MOV	CL,6
	SHL	AX,CL			;Convert to 16-byte blocks(segment no.)
	POP	CX			;Recall drive info
	MOV	[CS:DRVFAT],CX		;SAVE DRIVE TO LOAD DOS

	MOV	DX,SYSINIT$SEG
	MOV	DS,DX

    ASSUME	DS:SYSINIT$SEG

	MOV	word [MEMORY_SIZE],AX
	INC	CL
	MOV	byte [DEFAULT_DRIVE],CL	 ;SAVE DEFAULT DRIVE SPEC

	add	dx,SYSIZE
	MOV	word [CURRENT_DOS_LOCATION],dx			; load address of DOS

	MOV	word [FINAL_DOS_LOCATION],BiosInit$SEG
;	debug	1,2,<DOS will load at $x, will move to $x\n>,<dx,FINAL_DOS_LOCATION>
	MOV	word [DEVICE_LIST],CONDEV	  ;DS:SI = ptr to device list
	MOV	AX,CS
	MOV	word [DEVICE_LIST+2],AX
;**************************************************************
;	WILL INITIALIZE THE NUMBER OF DRIVES
;	AFTER THE EQUIPMENT CALL (INT 11H) BITS 6&7 WILL TELL
;	THE INDICATIONS ARE AS FOLLOWS:
;
;	BITS	7	6	DRIVES
;		0	0	1
;		0	1	2
;		1	0	3
;		1	1	4
;**************************************************************
	PUSH	CS
	PUSH	CS
	POP	DS
	POP	ES

    ASSUME	DS:BiosSeg,ES:BiosSeg

	INT	11H			;GET EQUIPMENT STATUS
	AND	AL,11000000B	;MASK DRIVE BITS
	JNZ	NOTSNGL		;Zero means single drive system
	INC	[SINGLE]	;REMEMBER THIS
NOTSNGL:
	POP	AX			;BOOT specifies number of floppies
	MOV	[HARDNUM],AL	;Remember which drive is hard disk
	MOV	[DRVMAX],AL	;And set initial number of drives
	MOV	AH,8
	MOV	DL,80H
	INT	13H		;Request number of hardfiles attached
	JC	ENDDRV		;Carry indicates old rom, so no hardfile
	MOV	[HNUM],DL
ENDDRV:
	MOV	DL,80H
	MOV	DI,HDRIVE
	CMP	[HNUM],0
	JLE	ITSOK1
	CALL	SETHRD		;SET UP FIRST HARDFILE

	MOV	DL,81H		;SET UP FOR NEXT CALL
	MOV	DI,DRIVEX
	JC	NOTOK
	CMP	[HNUM],2
	JZ	SETIT
	JMP	SHORT ITSOK

NOTOK:	MOV	[HARDDRV],DL
	MOV	DI,HDRIVE
	DEC	[HNUM]
	CMP	[HNUM],0
	JZ	ITSOK1
SETIT:	CALL	SETHRD		;SET UP SECOND HARDFILE
	JNC	ITSOK
	DEC	[HNUM]

; End of drive initialization

ITSOK:	MOV	AL,[HNUM]
	OR	AL,AL
	JZ	ITSOK1
	ADD	AL,[HARDNUM]
	MOV	[DRVMAX],AL
	MOV	AL,[HNUM]
	JMP	SHORT ITSOK2		;GO SET DESTINATION SEGMENT

ITSOK1: CMP	byte [SINGLE],1
	JMP	SHORT GOINIT

    ASSUME	DS:BiosSeg

ITSOK2:
	DEC	AL

GOINIT:
;	debug	1,1,<hardnum/hnum  $x  drvfat $x\n>,<<word ptr hnum>,drvfat>
	PUSH	CS
	POP	DS

    ASSUME	DS:BiosSeg,ES:NOTHING

	CALL	GETFAT		;READ IN THE FAT SECTOR
	XOR	DI,DI
	MOV	AL,[ES:DI]		;GET FAT ID BYTE
	MOV	byte [DRVFAT+1],AL	;SAVE FAT BYTE
;	debug	1,2,< FAT ID: $b ds:$x\n>,<ax,ds>
	MOV	AX,[DRVFAT]
	CALL	GETBP			;GET DISK POINTER
	MOV	CL,[DI+2]		;GET SECTORS/CLUSTER
	MOV	AX,[DI+HIDSEC]		;GET NUMBER OF HIDDEN SECTORS
	SUB	[BIOS$],AX		;SUBTRACT HIDDEN SECTOR OFFSET
	XOR	CH,CH			;CX = SECTORS/CLUSTER
	PUSH	DS
	XOR	DI,DI
	MOV	DS,DI
;
;	THE BOOT PROGRAM HAS LEFT THE DIRECTORY AT 0:500
;
	MOV	BX,word [DS:53AH]	;GET FIRST CLUSTER OF DOS
	POP	DS			;BX = FIRST CLUSTER OF DOS
LOADIT: MOV	AX,SYSINIT$SEG
	add	ax,SYSIZE
	MOV	ES,AX			;ES:DI POINTS TO LOAD LOCATION
	CALL	GETCLUS			;READ IN A CLUSTER
	CMP	BX,0FFFH
	JNZ	LOADIT			;END OF FILE?

	call	Disk_Init		; do some device driver initialization
;	debug	1,2,<System loaded, going to sysinit\n>,<>
	JMP	SYSINIT


;
;	READ A FAT SECTOR INTO 17C0:0
;
GETFAT:;debug	1,2,<GETFAT.>,<>
	XOR	DI,DI
	MOV	CX,1
	MOV	DX,CX
	MOV	AX,BootBufr
	MOV	ES,AX
	MOV	AL,byte [DRVFAT]
	MOV	AH,0FCH
	JMP	DISKRD
;
;	READ A BOOT RECORD INTO 17C0:0
;
GETBOOT:;debug	1,2,<GETBOOT.>,<>
	MOV	CX,1
	MOV	AX,0201H
	MOV	BX,BootBufr
	MOV	ES,BX
	XOR	BX,BX
	MOV	DH,BH
	INT	13H
	JC	SETRET
	CMP	word [ES:1FEH],0AA55H
	JNZ	SETRET
	RET
;
;	SETUP VARIABLE SIZED HARDFILE
;	ON ENTRY DL=DRIVE NUMBER (80 OR 81)
;		 DI=PTR TO B.P.B
;
SETHRD: PUSH	DX
	MOV	AH,8		;GET DRIVE PARAMETERS
	INT	13H
	INC	DH
	MOV	[DI+HDLIM],DH
	POP	DX
	JC	SETRET
	AND	CL,3FH
	MOV	[DI+SECLIM],CL
	CALL	GETBOOT		;GET THE BOOT RECORD
	JC	SETRET
	MOV	BX,1C2H
SET1:	CMP	byte [ES:BX],1
	JZ	SET2
	ADD	BX,16
	CMP	BX,202H
	JNZ	SET1
SETRET: STC			;NOT FOUND SO USE DEFAULTS
	RET

SET2:	MOV	AX,[ES:BX+4]
	MOV	[DS:DI+HIDSEC],AX	;SET HIDDEN SECTOR COUNT
	MOV	AX,[ES:BX+8]
	CMP	AX,64			;HAS TO BE AT LEAST 32K
	JB	SETRET
	MOV	[DS:DI+8],AX		;SAVE LOGICAL SECTOR COUNT
	MOV	CX,0100H		;SET CLUS SIZE AND SHIFT COUNT
	MOV	DX,64			;SET NUMBER OF DIR ENTRIES
	CMP	AX,512
	JBE	SET3

	ADD	CH,CH
	INC	CL
	MOV	DX,112
	CMP	AX,2048
	JBE	SET3

	ADD	CH,CH
	INC	CL
	MOV	DX,256
	CMP	AX,8192
	JBE	SET3

	ADD	CH,CH
	INC	CL
	ADD	DX,DX
	CMP	AX,32680	;NOT 32768! MAX NUMBER OF CLUSTERS=4085
	JBE	SET3

	ADD	CH,CH
	INC	CL
	ADD	DX,DX
SET3:
;
;	DX=NUMBER OF DIR ENTRIES, CH=NUMBER OF SECTORS PER CLUSTER
;				  CL=LOG BASE 2 OF CH
;
;	NOW CALCULATE SIZE OF FAT TABLE
;
	MOV	[DI+6],DX		;SAVE NUMBER OF DIR ENTRIES
	MOV	[DI+2],CH		;SAVE SECTORS PER CLUSTER
	XOR	BX,BX
	MOV	BL,CH
	DEC	BX
	ADD	BX,AX
	SHR	BX,CL			;DIVIDE BY SECTORS/CLUSTER
	INC	BX
	AND	BL,11111110B		;MAKE SURE COUNT IS EVEN
	MOV	SI,BX
	SHR	BX,1
	ADD	BX,SI			;MULTIPY BY 1.5
	ADD	BX,511
	SHR	BH,1
	MOV	[DI+11],BH		;SAVE NUMBER OF FAT SECTORS
	CLC
	RET
;
;  READ CLUSTER SPECIFIED IN BX
;  CX = SECTORS PER CLUSTER
;  DI = LOAD LOCATION
;
GETCLUS:;debug	1,2,<GETCLUS bx $x cx $x es:di $x:$x  >,<bx,cx,es,di>
	PUSH	CX
	PUSH	DI
	MOV	[DOSCNT],CX	;SAVE NUMBER OF SECTORS TO READ
	MOV	AX,BX
	DEC	AX
	DEC	AX
	MUL	CX		;CONVERT TO LOGICAL SECTOR
	ADD	AX,[BIOS$]	;ADD IN FIRST DATA SECTOR
	MOV	DX,AX		;DX = FIRST SECTOR TO READ

GETCL1: CALL	UNPACK		;SI = BX, BX = NEXT ALLOCATION UNIT
	SUB	SI,BX
	CMP	SI,-1		;one apart?
	JNZ	GETCL2
	ADD	[DOSCNT],CX
	JMP	GETCL1

GETCL2: PUSH	BX
	MOV	AX,[DRVFAT]	;GET DRIVE AND FAT SPEC
	MOV	CX,[DOSCNT]
	CALL	DISKRD		;READ THE CLUSTERS
	POP	BX
	POP	DI
	MOV	AX,[DOSCNT]	;GET NUMBER OF SECTORS READ
	XCHG	AH,AL		;MULTIPLY BY 256
	SHL	AX,1		;TIMES 2 EQUAL 512
	ADD	DI,AX		;UPDATE LOAD LOCATION
	POP	CX		;RESTORE SECTORS/CLUSTER
	RET
;
;	GET THE FAT ENTRY AT BX, WHEN FINISHED SI=ENTRY BX
;
UNPACK: PUSH	DS
	PUSH	BX
	MOV	SI,BootBufr
	MOV	DS,SI
	MOV	SI,BX
	SHR	SI,1
	MOV	BX,[SI+BX]
	JNC	HAVCLUS
	SHR	BX,1
	SHR	BX,1
	SHR	BX,1
	SHR	BX,1
HAVCLUS:AND	BX,0FFFH
	POP	SI
	POP	DS
	RET
;
; SI POINTS TO DEVICE HEADER
;
PRINT_INIT:
	MOV	BH,1
	MOV	DL,17H
	JMP	SHORT DEV_INIT
AUX_INIT:
	MOV	BX,RSINIT
	MOV	DL,14H
DEV_INIT:
	MOV	[CS:INTNUM],DL
	MOV	AL,[CS:SI+13]	;GET DEVICE NUMBER FROM THE NAME
	SUB	AL,"1"
	CBW
	MOV	DX,AX
	MOV	AX,BX		;SET THE CALL
	DB	0CDH		;INT 17H
INTNUM	DB	17H
	RET

END$:

end if
