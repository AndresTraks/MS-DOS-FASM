

;;	TODO -
;;		split CON and KBD
;;		interruptible waits and unwinding
;;		per screen keyboard buffers

;------------------------------------------------------------------------
;		Revision History
;
;	V1.00	04/10/84	M.A.Ulloa
;		First Implementation: Only one segment used and only
;		one screen in the color card (alpha mode).
;
;	V1.01	04/15/84	M.A.Ulloa
;		Re-enabled the blocking of writing from processes not
;		with the current screen.
;
;	V1.02	04/16/84	M.A.Ulloa
;		Increased to 8 the num of screens. Added the screen
;		blanking when reading and writing the screen data
;		(see BLANK switch). Added screen # for writes.
;
;	V1.03	04/17/84	M.A.Ulloa
;		Corrected problem with flush.
;
;	V1.05	04/30/84	A.R.Whitney
;		Added conditional compilation to allow linking with
;		resident BIOS.
;
;	V1.06	05/08/84	A.R.Whitney
;		Added ANSI escape sequences.  Conditional on ANSI.
;
;	V1.07	05/15/84	A.R.Whitney
;		Fixed compatibility problems with Eagle PC Turbo.
;		Fixed BLANK conditional code to allow saving graphics
;		mode screens.
;		Added enable/disable 25th line to Ansi.
;
;	V1.08	05/22/84	A.R.Whitney
;		Fixed problem with scrolling in screen modes other
;		than 80x25.  Bug due to 25th line stuff.
;
;------------------------------------------------------------------------

;DEBUGFLG	=	1

	INCLUDE 'DEFDBUG.INC'

FALSE	=	0
TRUE	=	-1

CVERS	=	01			; update version number!!
CREV	=	08

BLANK	=	TRUE			; blank screen during data r/w
INBIOS	=	TRUE			; link with BIOS
ANSI	=	TRUE			; include ANSI escape sequences
  LINE25 =	TRUE			;   special 25th line like VT52
EAGLE	=	TRUE			; Eagle PC ROM botches CRT_LEN



;------------------------------------------------------------------------
;	Screen Information Block (SIB) Definition
;
;	This structure contains all information necessary to
; describe the state of the screen, plus pointers to buffers
; which contain the actual screen content.
;

;------------------------------------------------------------------------
MaxSEG	=	2			; NOTE: assumption is made in the
					;   code that all SIB's have same
					;   number os SEGs
STRUC SEGst
{
        .SizeNeeded     dw 0		; needed size for seg, (0 = unused)
        .MemFlag        dw 0
        .MPointer       dd 0
}

if SEGSEL = S_CODE
virtual at 0
  SEGst SEGst
  sizeof.SEGst = $ - SEGst
end virtual
end if
;------------------------------------------------------------------------
MaxSIB	=	8			; maximum number of Screens


IF	ANSI
TermSize	=	20		; max. size of terminal emulation state
end if

STRUC SIBst
{
        .ctlS           db 0		; if the screen is NOT frozen = 0
        					; NOTE: this field should be the
        					;   FIRST of each SIB !! (see ConWrit)
        .OffsetVal      dw 7		; start of Seg Descriptors
        .SegCnt         dw MaxSEG		; max number of Segments
        .SIBlen         dw (sizeof.SIBst)	; length of the SIB
        ;--- Segments
        		db	((sizeof.SEGst) * MaxSEG) dup (0)
        ;--- PC video state info
        .xCRT_MODE      db 0
        .xCRT_COLS      dw 0
        .xCRT_LEN       dw 0
        .xCRT_START     dw 0
        .xCURSOR_POSN   dw 8 dup (0)
        .xCURSOR_MODE   dw 0
        .xACTIVE_PAGE   db 0
        .xADDR_6845     dw 0
        .xCRT_MODE_SET  db 0
        .xCRT_PALETTE   db 0
        .xTERM_STATE    db TermSize dup (0)
}

if SEGSEL = S_CODE
virtual at 0
  SIBst SIBst
  sizeof.SIBst = $ - SIBst
end virtual
end if

;------------------------------------------------------------------------
;	Request packet offset definitions
;

CMDLEN	=	0			;LENGTH OF THIS COMMAND
UNIT	=	1			;SUB UNIT SPECIFIER
CMD	=	2			;COMMAND CODE
STATUS	=	3			;STATUS
MEDIA	=	13			;MEDIA DESCRIPTOR
TRANS	=	14			;TRANSFER ADDRESS
COUNT	=	18			;COUNT OF BLOCKS OR CHARACTERS
START	=	20			;FIRST BLOCK TO TRANSFER



;------------------------------------------------------------------------
;	IBM-PC ROM Data area Locations
;

if SEGSEL = S_CODE
RomData = 40H
virtual at 0
	ORG	1AH
BufferHead	DW      0
BufferTail	DW      0
KeyBuffer	DW	16 dup (0)
KeyBufLen       =     ($-KeyBuffer)	; length of KeyBuffer

	ORG	49H
CRT_MODE	DB      0
CRT_COLS	DW      0
CRT_LEN		DW      0
CRT_START	DW      0
CURSOR_POSN	DW	8 dup (0)
CURSOR_MODE	DW      0
ACTIVE_PAGE	DB      0
ADDR_6845	DW      0
CRT_MODE_SET	DB      0
CRT_PALETTE	DB      0

CrtLen		=	($-CRT_MODE)	; length of screen state area
end virtual
end if

if SEGSEL = S_CODE
MonoSc = 0B000H
virtual at 0
;--- 4k of screen memory
end virtual
end if

if SEGSEL = S_CODE
ColorSc = 0B800H
virtual at 0
;--- 16k of screen memory
end virtual
end if

BRKADR	=	006CH			; Break vector address




if SEGSEL = S_CODE

;------------------------------------------------------------------------
;	Device Header
;

ASSUME	cs:Code,ds:NOTHING,es:NOTHING,ss:NOTHING

IF	INBIOS
CONDEV	dd	AUXDEV$FAR
ELSE
CONDEV	dw	0FFFFh,0FFFFh
end if	;INBIOS
;*** should ioctl bit be set for gen ioctl too?
	dw	1100000000010011b	; console in and out
	dw	Strategy$CON
	dw	Entry_
	db	"CON     "


;------------------------------------------------------------------------
;	Command dispatch table
;

ComTbl:
;--- 2.0
	dw	ConInit$	; Initialization function
	dw	StatusComplete		; Media Check
	dw	StatusComplete		; Build BPB
	dw	CmdErr			; IOCTL Input
	dw	ConRead$		; Input (Read)
	dw	ConRdnd$		; Non-Destructive read, no wait
	dw	StatusComplete		; Input Status
	dw	ConFlsh$		; Input Flush
	dw	ConWrit$		; Output (Write)
	dw	ConWrit$		; Output with verify
	dw	StatusComplete		; Output Status
	dw	StatusComplete		; Output Flush
	dw	StatusComplete		; IOCTL Output
;--- 3.0
	dw	StatusComplete		; Device Open
	dw	StatusComplete		; Device Close
	dw	StatusComplete		; Removable Media
;--- 4.0
	dw	GenIOCTL$		; Generic IOCTL
	dw	ConStop$		; Pause Device
	dw	ConStart$		; Continue Device

ComTblEnd:

CTSIZE	=	(ComTblEnd - ComTbl)/2	; number of table entries



;------------------------------------------------------------------------
;	Device Data Area
;

SaveFlg db	0			; Screen being saved flag, (true = 1)
IF	INBIOS
ELSE
DosFunction dd      0; pointer to dos "helper" functions
end if	;INBIOS
AltAH	db	0			; Side buffer for input
CurrSc	dw	0			; Current screen number
CurrSIB dw	SIB			; offset to the current SIB
label SIB
SIB$0	SIBst
SIB$1	SIBst
SIB$2	SIBst
SIB$3	SIBst
SIB$4	SIBst
SIB$5	SIBst
SIB$6	SIBst
SIB$7	SIBst; allocate room for SIB's

IF	EAGLE
ScreenLen	db	08h		; table of (high byte of) regen. buffer
		db	08h		;  len.  Indexed by screen mode.
		db	10h		; 80x25 text modes
		db	10h
		db	40h		; graphics modes
		db	40h
		db	40h
		db	10h		; monochrome
end if


if defined DEBUGFLG
IF	INBIOS
ELSE
BUGBITS db	0ffh,0ffh
end if
end if


;------------------------------------------------------------------------
;	2.0 Interrupt Routine (Not Used)
;

EntryP:
Entry_:	RETF


;------------------------------------------------------------------------
;	2.0 Strategy$CON Routine, main entry point
;
; entry
;	ES:BX	points to Request packet
;

StratP:

Strategy$CON:
IF	INBIOS

	push	si
	mov	si,ComTbl
	jmp	Interrupt
ELSE
	push	ax			; save all
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	ds

	push	es			; DS = ES
	pop	ds

	push	es
	push	bx
	mov	al, byte [DS:bx+CMD]
	cmp	al,CTSIZE		; Command within range?
	jae	CmdErr			; no must be an error
	mov	cx, word [DS:bx+COUNT]
	les	di, dword [DS:bx+TRANS]
	xor	ah,ah
	mov	si, ComTbl
	add	si,ax
	add	si,ax

	jmp	word [CS:si]	; dispatch
end if	;INBIOS




;------------------------------------------------------------------------
;	Exit Routines, Common to all device functions
;

IF	INBIOS
ELSE

ASSUME	ds:NOTHING,es:NOTHING

StatusDevReady:
	mov	ah,00000011b		; device busy
	jmp	short errEx

CmdErr:
	mov	al,3			; Unknown command Error
StatusError:
	mov	ah,10000001b
	jmp	short errEx

ExitP:
StatusComplete:	mov	ah,00000001b
errEx:	pop	bx
	pop	es

	mov	word [ES:bx+STATUS],ax	; put status out

	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	RETF

end if	;INBIOS



;------------------------------------------------------------------------
;	Break interrupt routine
;

ASSUME	ds:NOTHING,es:NOTHING

Break_:
	int	32H			; save registers
	cli				; ints should be off, make sure!
	mov	ax,RomData
	mov	ds,ax
    ASSUME	ds:RomData
	mov	ax,KeyBuffer
	mov	[BufferHead],ax
	mov	[BufferTail],ax
    ASSUME	ds:NOTHING
	mov	ax,3			; send char to system
	mov     dx,5                    ; ConsInputFilter subfunction
	call    dword [CS:DosFunction]
	jz	brk1			; key was eaten by system
	mov	[CS:AltAH],al		; force a ^C
brk1:
	iret

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
KeySem          db      0               ; non-zero if someone waiting on input

KeyboardInterrupt:
	INT     32H                     ; Save regs
	MOV     AX,RomData
	MOV     DS,AX
    ASSUME      DS:RomData

	PUSHF                           ; Save flags to simulate INT
	CALL    dword [CS:OldKeyInterrupt]      ; Now do ROM code
; Now tell DOS keyboard had char
	cli                             ; interrupts off!
	mov     bx,[BufferTail]           ; Get tail of queue
	cmp     bx,[BufferHead]           ; Anything in keyboard queue?
	JE      NoKey                   ; No, don't requeue then
	dec     bx
	dec     bx
	cmp     bx,KeyBuffer
	jae     kbi1                    ; no wrap around in buffer
	mov     bx,KeyBuffer+(KeyBufLen-2)
kbi1:
	mov     ax,[bx]                 ; get last queued char.
	mov     dx,5                    ; ConsInputFilter subfunction
	call    dword [CS:DosFunction]
	jnz     kbi2                    ; key should remain in buffer
	mov     [BufferTail],bx           ; discard key from buffer
	jmp     SHORT NoKey
kbi2:
	cli
	CMP     [CS:KeySem],0                ; Outstanding request?
	JE      NoKey                   ; No, may not be inited either
	push    ax
	push    bx
	push    cx
	push    dx
	mov     ax,cs
	mov     bx,KeySem
	mov     byte [CS:bx],0      ; reset keyboard semaphore
	mov     dx,10                   ;; ProcRun
	call    dword [CS:DosFunction]           ; awaken anyone waiting on input
	pop     dx
	pop     cx
	pop     bx
	pop     ax
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
;       WARNING: The following routines can be entered recursively
;                due to the fact that the ROM BIOS routines called
;                reenable interrupts.  It's not usually a problem
;                since interrupts will generally be processed faster
;                than anyone can type.

OldKbdHandler   dd      0
ScrnIoOk	dd      0

;-------------------------------------------------------------

KeyBoardHandler:
	or      ah,ah
	je      DoLocalRead
	cmp     ah,1
	je      DoLocalStat
OldKBint:
	jmp     dword [CS:OldKbdHandler]

DoLocalStat:
	push    bx
	push    ds
	lds     bx,[CS:ScrnIoOk]
	test    byte [bx],0FFh
	pop     ds
	pop     bx
	jnz     OldKBint
	xor     ax,ax
	RETF     2
DoInt16:; entry for ChrIn
DoLocalRead:
	push    ax
	push    bx
	push    cx
	push    dx
DoLocalRd1:
	push    ds
	lds     bx,[CS:ScrnIoOk]
	mov     ax,ds
	test    byte [bx],0FFh
	pop     ds
	jnz     DoLocalRd2
	xor     cx,cx
	mov     dx,9                    ;; ProcBlock
	call    dword [CS:DosFunction]           ; sleep until a screen switch
	jmp     DoLocalRd1

DoLocalRd2:
	mov     ah,1                    ; get console status
	pushf                           ; simulate INT to old handler
	cli
	call    dword [CS:OldKbdHandler]
	cli                             ; subfunction 1 unconditionally sets IF
	jnz     LocalRead               ; go read character
	mov     ax,cs
	mov     bx,KeySem
	mov     byte [CS:bx],0FFh   ; set keyboard semaphore
	xor     cx,cx
	mov     dx,9                    ;; ProcBlock
	call    dword [CS:DosFunction]           ; sleep until a char is typed
	jmp     DoLocalRd1

LocalRead:
	pop     dx
	pop     cx
	pop     bx
	pop     ax
	jmp     dword [CS:OldKbdHandler]         ; read the character and return




;------------------------------------------------------------------------
;	Console Input (Read)
;
; entry:
;	DS:BX = pointer to Request packet
;	ES:DI = Transfer address
;	CX = Count
;

ASSUME	ds:NOTHING,es:NOTHING

ConRead$:
	and	cx,cx
	jnz	jgl2
	jmp	CRExit
;	jcxz	CRExit			; no chars to read BUGBUG restore
jgl2:	cld				; make sure!
	mov	dx,word [DS:bx+START]	; get screen number
	cmp	dx,(MaxSIB-1)		; valid number?
	jbe	ConRLoop		; yes, do input
	mov	al,0BH			; no, READ FAULT ERROR
	jmp	StatusError
ConRLoop:
;	DEBUG	10h,1,<CONR:$x=$x? >,<dx,CurrSc>
	cmp	dx,[CS:CurrSc]
	je	sjp0
	call	GetSIBAdr		; get pointer to the SIB
;	DEBUG	10h,1,<Block read wrong screen >,<>
	call	DoPBlock		; block the process
	jmp	short ConRLoop		; test flag again
sjp0:
	call	ChrIn
	stosb
;	loop	ConRLoop
	loop	jgl3
CRExit: jmp	StatusComplete

jgl3:	jmp	ConRLoop


;------------------------------------------------------------------------
;	Read a single character In
;
; exit:
;	Character in AL
;
; modifies:	AX
;

ASSUME	ds:NOTHING,es:NOTHING

ChrIn:
;	DEBUG	10h,1,<in.ChrIn >,<>
	xor	ax,ax
	xchg	al,[CS:AltAH]		; Get Character & zero AltAH
	or	al,al			; A char available?
	jnz	KeyRet
;
;--- NOTE: The blocking on read is done at int 16h level
;	in IBMBIO. No need to block here.
;
;	DEBUG	10h,1,< con.do.16 >,<>
	mov	ah,0			; no, do a read call
	pushf
	call	BiosSeg:DoInt16
;;	int	16h
;	DEBUG	10h,1,< con.got.$x >,<ax>
	or	ax,ax			; check for non-key after BREAK
	jnz	jgl1
	jmp	ChrIn

jgl1:	cmp	ax,7200h		; CTRL-PRTSC ?
	jnz	sja0
	mov	al,10h			; yes, make it a ctrl-P
sja0:	or	al,al			; special case?
	jnz	KeyRet
	mov	[CS:AltAH],ah
KeyRet:
	ret



;------------------------------------------------------------------------
;	Console non-destructive Input, no wait
;
; entry:
;	DS:BX = pointer to Request packet
;

ASSUME	ds:NOTHING,es:NOTHING

ConRdnd$:
	mov	dx,word [DS:bx+START]	; get screen number
	cmp	dx,(MaxSIB-1)		; valid number?
	jbe	sjq0			; yes, do input
	mov	al,0BH			; no, READ FAULT ERROR
	jmp	StatusError
sjq0:
;	DEBUG	10h,1,<CNDR:$x=$x? >,<dx,CurrSc>
	cmp	dx,[CS:CurrSc]
if defined DEBUGFLG
	je	sjq1
	jmp	ConBus
ELSE
	jne	ConBus			; not current screen, no char avail
end if
;	call	GetSIBAdr		; get pointer to the SIB
;	call	DoPBlock		; block the process
;	jmp	short sjq0		; test flag again
sjq1:
	mov	al,[CS:AltAH]		; char avail already?
	or	al,al
	jnz	rdExit
;	DEBUG	10h,1,< NRD:do.16 >,<>
	mov	ah,1			; no, get status
	int	16h
	jz	ConBus
;	DEBUG	10h,1,< NRD:nonbus $x >,<ax>
	or	ax,ax
	jnz	NotBk			; Check for null after break
	mov	ah,0			; flush the null
	int	16h
	jmp	ConRdnd$		; try again
;	jmp	short $ConRdnd		; try again BUGBUG
NotBk:
	cmp	ax,7200h		; CTRL-PRTSC ?
	jnz	rdExit
	mov	al,10h			; yes, make it a ctrl-P
rdExit:
	mov	byte [DS:bx+MEDIA],al	; save character
DoExit: jmp	StatusComplete

ConBus:;DEBUG	10h,1,< ConBus - >,<>
	jmp	StatusDevReady



;------------------------------------------------------------------------
;	Console Flush Input
;
; entry:
;	DS:BX = pointer to Request packet
;

ASSUME	ds:NOTHING,es:NOTHING

ConFlsh$:
	mov	dx,word [DS:bx+START]	; get screen number
	cmp	dx,(MaxSIB-1)		; valid number?
	jbe	sjr0			; yes, do flush
	mov	al,0BH			; no, READ FAULT ERROR
	jmp	StatusError
sjr0:
	cmp	dx,[CS:CurrSc]
	je	sjr1
	call	GetSIBAdr		; get pointer to the SIB
	call	DoPBlock		; block the process
	jmp	short sjr0		; test flag again
sjr1:
	mov	[CS:AltAH],0		; clear side bufer
	push	ds
	mov	ax,RomData
	mov	ds,ax
    ASSUME	ds:RomData
	cli				; Disable interrupts
	mov	ax,KeyBuffer	; Start of Rom buffer
	mov	[BufferHead],ax
	mov	[BufferTail],ax		; Empty the queue
	sti
	pop	ds
    ASSUME	ds:NOTHING
	jmp	StatusComplete



;------------------------------------------------------------------------
;	Console Output (Write)
;
; entry:
;	DS:BX = pointer to Request packet
;	ES:DI = Transfer address
;	CX = Count
;

ASSUME	ds:NOTHING,es:NOTHING

ConWrit$:
	jcxz	CWExit
	mov	dx, word [DS:bx+START]	; get screen number
	cmp	dx,(MaxSIB-1)		; valid screen number?
	jbe	sjb0
	mov	al,0AH			; no, write fault error
	jmp	StatusError
sjb0:	push	cs
	pop	ds
    ASSUME	ds:Code
	mov	bx,[CurrSIB]

ConWLoop:
	cmp	dx,[CurrSc]		; Is it to the current screen?
	je	sjb2			; yes, do not block
	call	GetSIBAdr		; get pointer to the SIB
sjb1:	call	DoPBlock		; block the process
	jmp	short ConWLoop		; test ALL flags again
sjb2:
	cmp	[bx+SIBst.ctlS],0		; is the screen frozen?
	je	sjb3
	mov	ax,bx			; AX = [CurrSIB] = [CurrSIB].ctlS !!!!
	jmp	short sjb1		; yes, block the process
sjb3:
	cmp	[SaveFlg],0		; are we in the middle of a save?
	je	sjb4			; no, do write
	mov	ax,SaveFlg
	jmp	short sjb1		; yes, block...
sjb4:
	mov	al,[ES:di]		; get a character
	inc	di
	call	CharOut
	loop	ConWLoop
CWExit: jmp	StatusComplete



;------------------------------------------------------------------------
;	Output a character to the screen
;
; entry:
;	AL =	Character to write
;
; preserves:
;	BX, CX, DX, DI, DS & ES
;

ASSUME	ds:NOTHING,es:NOTHING

IF	ANSI
	INCLUDE 'ansi.inc'
ELSE
CharOut:
	push	bx
	push	di
	mov	bx,7
	mov	ah,14
	int	10h			; Write Character
	pop	di
	pop	bx
	ret
end if



;------------------------------------------------------------------------
;	Generic IOCTL
;
; entry:
;	DS:BX = pointer to Request packet
;

;--- Offsets into the request packet
;*** Check offset are correct
FunCode =	14			; Function Code
FunCat	=	13			; Function Category
;***
RegSI	=	15			; Contents of SI
RegDI	=	17			; Contents of DI
DatBuf	=	19			; Pointer to data buffer

;--- Code & Category definitions
IOC_SC	=	03h			;--- Screen Control
IOSC_LS =	41h			; Locate SIB
IOSC_SS =	42h			; save segment
IOSC_RS =	43h			; restore segment
IOSC_EI =	44h			; re-enable i/o
IOSC_IS =	45h			; initialize screen

ASSUME	ds:NOTHING,es:NOTHING

GenIOCTL$:
	cmp	byte [DS:bx+FunCode],IOC_SC
	jne	GI_BadCode		; function not suported
	mov	si,word [DS:bx+RegSI]
	mov	al,byte [DS:bx+FunCat]
	cmp	al,IOSC_LS
	jne	sjc0
	jmp	short do_IOSC_LS
sjc0:	cmp	al,IOSC_SS
	jne	sjc1
	jmp	short do_IOSC_SS
sjc1:	cmp	al,IOSC_RS
	jne	sjc2
	jmp	do_IOSC_RS
sjc2:	cmp	al,IOSC_EI
	jne	sjc3
	jmp	do_IOSC_EI
sjc3:	cmp	al,IOSC_IS
	jne	GI_BadCode
	jmp	do_IOSC_IS

GI_BadCode:
	jmp	CmdErr			; error exit: Command error



;------------------------------------------------------------------------
;	Locate SIB
;
; entry:
;	SI = SIB Number
;	DS:BX = pointer to Request packet
;

ASSUME	ds:NOTHING,es:NOTHING

do_IOSC_LS:
	cmp	si,(MaxSIB-1)		; index within range?
	ja	BadNum
	push	bx
	push	ds
	push	cs
	pop	ds
    ASSUME	ds:Code
	cmp	si,[CurrSc]		; is it the current screen?
	je	CurrLS
	mov	[CurrSc],si		; no, just switch curr screens
	mov	dx,si			; index
	call	GetSIBAdr		; get pointer to SIB
	mov	[CurrSIB],ax		; save pointer to curr SIB
	jmp	short retLS

CurrLS:
	mov	[SaveFlg],1		; Signal we are Saving the screen

;*** Only one segment for now

	mov	ax,0
	call	GetSegAdr		; on return BX points to segment
	mov	ax,RomData
	mov	es,ax
    ASSUME	es:RomData
IF	EAGLE
	mov	al,[ES:CRT_MODE]
	xor	ah,ah
	mov	si,ax
	mov	ah,[ScreenLen+si]
	xor	al,al
ELSE
	mov	ax,[ES:CRT_LEN]
    ASSUME	es:NOTHING		; not true, but just to be safe
end if
	mov	[bx+SEGst.SizeNeeded],ax	; save size of segment
	mov	ax,dx			; pointer to current SIB
retLS:
	pop	ds
	pop	bx
    ASSUME	ds:NOTHING
	mov	word [DS:bx+DatBuf],ax	; offset
	mov	word [DS:bx+DatBuf+2],cs	; segment
	mov	word [DS:bx+RegSI],0	; operation ok
	jmp	StatusComplete

BadNum:
	mov	word [DS:bx+RegSI],1	; bad SIB number error
	jmp	StatusComplete



;------------------------------------------------------------------------
;	Save Segment
;
; entry:
;	SI = Segment Index (into the Current SIB)
;	DS:BX = pointer to Request packet
;

ASSUME	ds:NOTHING,es:NOTHING

do_IOSC_SS:
	cmp	si,(MaxSEG-1)		; within range?
BadNumJ1:
	ja	BadNum			; no, somebody screwed up...
	push	bx
	push	ds
	cmp	si,0			; first segment save?
	jne	nfSS			; no, just save screen data
;--- save screen state data
	push	si			; save index
	mov	ax,RomData
	mov	ds,ax			; DS = ROM data area
    ASSUME	ds:RomData
	mov	si,CRT_MODE
	mov	cx,CrtLen		; length of screen state data
	push	cs
	pop	es
    ASSUME	es:Code
	mov	di,[CS:CurrSIB]
	lea	di,[di+SIBst.xCRT_MODE]
	cld
    rep	movsb				; copy ROM info to SIB area
IF	ANSI
	push	cs
	pop	ds
    ASSUME	ds:Code
	mov	si,AnsiState	; point to ANSI state info
	mov	cx,AnsiSize
    rep	movsb				; save ANSI state info in SIB
end if
	pop	si			; restore segment index
;--- save a segment of screen data
nfSS:
	push	cs
	pop	ds
    ASSUME	ds:Code
	mov	ax,si
	call	GetSegAdr		; get adress of segment and curr SIB ptr
	mov	cx,[bx+SEGst.SizeNeeded]	; CX = Ammount to transfer
	shr	cx,1			; words!
	les	di,[bx+SEGst.MPointer]	; ES:DI = Screen save area
    ASSUME	es:NOTHING

;*** For now we are using only one segment

	mov	si,dx			; SI points to the current SIB
	mov	bx,ColorSc		; assume color card
	cmp	[si+SIBst.xCRT_MODE],7	; is this a BW monitor?
	jne	do_save
	mov	bx,MonoSc
do_save:
IF	BLANK
	mov	dx,[si+SIBst.xADDR_6845]	; point to mode register
	add	dx,4
	mov	al,[si+SIBst.xCRT_MODE_SET]	;  and get value
	and	al,NOT 8
	out	dx,al			; turn off video
end if
	mov	ds,bx			; DS points to apropiate screen area
    ASSUME	ds:NOTHING
	mov	si,0
	cld
    rep	movsw				; copy the screen
IF	BLANK
	or	al,8
	out	dx,al			; turn on video
end if
	pop	ds
	pop	bx
	mov	word [DS:bx+RegSI],0	; operation ok
	jmp	StatusComplete



;------------------------------------------------------------------------
;	Restore Segment
;
; entry:
;	SI = Segment Index (into the Current SIB)
;	DS:BX = pointer to Request packet
;

ASSUME	ds:NOTHING,es:NOTHING

do_IOSC_RS:
	cmp	si,(MaxSEG-1)		; within range?
	ja	BadNumJ1		; no, somebody screwed up...
	push	bx
	push	ds
	push	cs
	pop	ds
    ASSUME	ds:Code
	cmp	si,0			; first segment save?
	jne	nfRS			; no, just restore screen data
;--- restore screen state data
	push	si			; save index
	mov	si,[CurrSIB]
	push	si
	lea	si,[si+SIBst.xCRT_MODE]
	mov	ax,RomData
	mov	es,ax			; ES = ROM data area
    ASSUME	es:RomData
	mov	cx,CrtLen		; length of screen state data
	mov	di,CRT_MODE
	cld
    rep	movsb				; copy ROM info from SIB area
IF	ANSI
	push	es
	push	cs
	pop	es
    ASSUME	es:Code
	mov	di,AnsiState	; point to ANSI state info
	mov	cx,AnsiSize
    rep	movsb				; restore ANSI state info from SIB
	pop	es
    ASSUME	es:RomData
end if

;--- Setup new screen state
	pop	si
	mov	al,[si+SIBst.xCRT_MODE]
	cmp	al,7			; is this the BW monitor?
	jne	sjd0
	mov	al,2			; this is the "real" mode
sjd0:
	mov	ah,0
	int	10h			; set new mode
	mov	cx,[si+SIBst.xCURSOR_MODE]
	mov	ah,1
	int	10h			; set cursor type
	mov	dx,[si+SIBst.xCURSOR_POSN]
	mov	bh,[si+SIBst.xACTIVE_PAGE]
	mov	ah,2
	int	10h			; set cursor position
	mov	al,[si+SIBst.xACTIVE_PAGE]
	mov	ah,5
	int	10h			; set page #
	mov	dx,[si+SIBst.xADDR_6845]
	add	dx,5
	mov	al,[si+SIBst.xCRT_PALETTE]
	out	dx,al			; set color port
	mov	[ES:CRT_PALETTE],al
	pop	si			; restore segment index
;--- restore a segment of screen data
nfRS:
	mov	ax,si
	call	GetSegAdr		; get adress of segment
	mov	cx,[bx+SEGst.SizeNeeded]	; CX = Ammount to transfer
	shr	cx,1			; words!
	lds	si,[bx+SEGst.MPointer]	; DS:SI = Screen save area
    ASSUME	ds:NOTHING

;*** For now we are using only one segment

	mov	di,dx			; DI points to the current SIB
	mov	bx,ColorSc		; assume color card
	cmp	[CS:di+SIBst.xCRT_MODE],7	; is this a BW monitor?
	jne	do_rest
	mov	bx,MonoSc
do_rest:
IF	BLANK
	mov	dx,[CS:di+SIBst.xADDR_6845]	; point to mode register
	add	dx,4
	mov	al,[CS:di+SIBst.xCRT_MODE_SET]	;  and get value
	and	al,NOT 8
	out	dx,al			; turn off video
end if
	mov	es,bx			; ES points to apropiate screen area
    ASSUME	es:NOTHING
	mov	di,0
	cld
    rep	movsw				; copy the screen
IF	BLANK
	or	al,8
	out	dx,al			; turn on video
end if

	pop	ds
    ASSUME	ds:NOTHING
	pop	bx
	mov	word [DS:bx+RegSI],0	; operation ok
	jmp	StatusComplete

BadNumJ:
	jmp	BadNum



;------------------------------------------------------------------------
;	Re-enable i/o
;
; entry:
;	DS:BX = pointer to Request packet
;

ASSUME	ds:NOTHING,es:NOTHING

do_IOSC_EI:
	mov	[CS:SaveFlg],0		; Signal we are done Saving the screen
	mov	ax,SaveFlg
	call	DoPRun			; ProcRun
	mov	ax,[CS:CurrSIB]		; pointer to current SIB
	call	DoPRun			; ProcRun any output blocked because
					;  screen was not current
	jmp	StatusComplete



;------------------------------------------------------------------------
;	Initialize Screen
;
; entry:
;	SI = SIB Number
;	DS:BX = pointer to Request packet
;

ASSUME	ds:NOTHING,es:NOTHING

do_IOSC_IS:
	cmp	si,(MaxSIB-1)		; index within range?
	ja	BadNumJ
	push	ds
	push	cs
	pop	ds
    ASSUME	ds:Code
	mov	[CurrSc],si		; switch curr screens
	mov	dx,si			; index
	call	GetSIBAdr		; get pointer to SIB
	mov	[CurrSIB],ax		; save pointer to curr SIB
	mov	si,ax
	mov	[si+SIBst.ctlS],0		; screen not frozen
;--- set screen mode to pc mode 3 (80x25 BW)
	mov	ax,0003			; Set mode 3
	int	10h
	pop	ds
    ASSUME	ds:NOTHING
	mov	word [DS:bx+RegSI],0	; operation ok
	jmp	StatusComplete



;------------------------------------------------------------------------
;	Stop (freeze) console output
;

ASSUME	ds:NOTHING,es:NOTHING

ConStop$:
	mov	bx,[CS:CurrSIB]		; pointer to current SIB
	mov	[CS:bx+SIBst.ctlS],01		; set the freeze flag
	jmp	StatusComplete



;------------------------------------------------------------------------
;	Start (continue) console output
;

ASSUME	ds:NOTHING,es:NOTHING

ConStart$:
	mov	bx,[CS:CurrSIB]		; pointer to current SIB
	cmp	[CS:bx+SIBst.ctlS],0		; is it already going?
	je	csRet			; yes, no need to re-enable
	mov	[CS:bx+SIBst.ctlS],0		; reset the freeze flag
	lea	ax,[bx+SIBst.ctlS]		; get address of current ctlS
	call	DoPRun			; do ProcRun
csRet:	jmp	StatusComplete



;------------------------------------------------------------------------
;	Block the current process
;
; entry:
;	CS:AX = address to block on
;
; modifies:	AX, FLAGS
;

ASSUME	ds:NOTHING,es:NOTHING

DoPBlock:
	push	bx
	push	cx
	push	dx
	mov	bx,ax
	mov	ax,cs			; AX:BX = event identifier
	xor	cx,cx			; No timeout
;;	mov	dx,0109h	;;BUGBUG - should be interruptible wait; will
				;;  give InternalError (SchedFind - not on Q)
	mov	dx,0009h		; PROCBLOC function
	cli				; No races!
	call	dword [CS:DosFunction]
	pop	dx			; on return ints are back on
	pop	cx
	pop	bx
	ret



;------------------------------------------------------------------------
;	Restart a process
;
; entry:
;	CS:AX = address to signal on (same as blocked on)
;
; modifies:	AX, FLAGS
;

ASSUME	ds:NOTHING,es:NOTHING

DoPRun:
	push	bx
	push	cx
	push	dx
	mov	bx,ax
	mov	ax,cs
	mov	dx,10			; PROCRUN function
	call	dword [CS:DosFunction]
	pop	dx
	pop	cx
	pop	bx
	ret



;------------------------------------------------------------------------
;	Returns the adress of the specified SIB
;
; entry:
;	DX = index to the SIB
;
; exit:
;	AX = pointer to the SIB
;
; preserves:	ALL
;

ASSUME	ds:Code,es:NOTHING

GetSIBAdr:
	push	dx			; save screen #
	mov	ax,dx			; index
	mov	dx,(sizeof.SIBst)
	mul	dx			; multiply by size of SIB entry
	pop	dx			; restore screen #
	add	ax,SIB		; AX = pointer to SIB for the write
	ret



;------------------------------------------------------------------------
;	Returns the adress of a segment in the current SIB
;
; entry:
;	AX = index to the segment
;
; exit:
;	BX = pointer to the segment
;	DX = pointer to the Current SIB
;

ASSUME	ds:Code,es:NOTHING

GetSegAdr:
	mov	dx,(sizeof.SEGst)
	mul	dx			; multiply by size of SEG entry
	mov	bx,[CurrSIB]		; pointer to SIB
	mov	dx,bx			; save for exit
	mov	bx,[bx+SIBst.OffsetVal]	; pointer to start of SEGs in SIB
	add	bx,ax			; BX = pointer to SEG from start of SIB
	add	bx,dx			; BX = absolute pointer to SEG to use
	ret

if defined DEBUGFLG
if	NOT INBIOS
	INCLUDE 'BUGCODE.INC'
end if
end if



;------------------------------------------------------------------------
;	Initialization Routine
;
;entry:
;	DS:BX = pointer to Request packet
;	ES:DI = Dos Functions entry point address
;

ASSUME	ds:NOTHING,es:NOTHING

ConInit$:
IF	NOT INBIOS
	push	ds			; print greeting
	push	cs
	pop	ds
	mov	dx,Intro
	MOV	ah,9
	int	21h
	pop	ds
	mov	word [DS:bx+TRANS], ConInit$
	mov	word [DS:bx+TRANS+2],cs
end if
	mov	word [CS:DosFunction],di  ; Save pointer to service routines
	mov	word [CS:DosFunction+2],es

	mov     ax,0
	mov     cx,1
	mov     dx,16
	call    dword [CS:DosFunction]		; get DOS variable ScrnIoOk
	mov     word [CS:ScrnIoOk],ax
	mov     word [CS:ScrnIoOk+2],dx

;*	Initialize interrupt vectors.
;;BUGBUG - we should be using Get/Set_Interrupt_Vector calls

	xor	ax,ax			; initialize break interrupt handler
	mov	es,ax			; points to page 0
	mov	ax,cs
	mov	word [ES:BRKADR],Break_
	mov	word [ES:BRKADR+2],ax ; Vector for Break

	MOV     DI,9*4			; INT 9 - Keyboard interrupt vector
	MOV     CX,[ES:DI]              ; Save old addr to hook to
	MOV     word [CS:OldKeyInterrupt],CX
	MOV     CX,[ES:2+DI]
	MOV     word [CS:OldKeyInterrupt+2],CX
	MOV     CX,KeyboardInterrupt
	XCHG    AX,CX
	STOSW
	XCHG    AX,CX
	STOSW                           ; Set new keyboard interrupt

	mov	di,16h*4		; INT 16 - keyboard input
	MOV     CX,[ES:DI]              ; Save INT 16 addr to hook to
	MOV     word [CS:OldKbdHandler],CX
	MOV     CX,[ES:2+DI]
	MOV     word [CS:OldKbdHandler+2],CX
	MOV     CX,KeyBoardHandler
	XCHG    AX,CX
	STOSW
	XCHG    AX,CX                   ; Set new keyboard Handler
	STOSW
	jmp	StatusComplete


end if

if SEGSEL = S_BIOSINIT

Intro	db	"--- Installing MTCON Device Driver V"
	db	CVERS+"0",".",CREV/10+"0"
	db	(CREV-CREV/10*10)+"0"," ---"
	db	13,10,"$"

end if

