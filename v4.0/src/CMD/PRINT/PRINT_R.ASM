	page	80,132
	TITLE	DOS - PRINT - RESIDENT
;			SALUT$ (4,25,30,41)
			include 'PRIDEFS.INC'

; include Extended Atribute support

			include 'EA.INC'

			BREAK <Resident Portion>
;
;	DOS PRINT
;
;	Resident Portion
;

if SEGSEL = S_CODE
;			extrn TransRet:WORD,TransSize:WORD,NameBuf:WORD
;			extrn GoDispMsg:FAR
end if

			BREAK <Resident Data>

if SEGSEL = S_CODER

;			public SliceCnt, BusyTick, MaxTick, TimeSlice
;			public EndRes, BlkSiz, QueueLen, PChar
;			public ListName, FileQueue, EndQueue, Buffer
;			public EndPtr, NxtChr, MoveTrans
;			public TO_DOS

;			public MESBAS


;			ASSUME CS:CodeR

			db   " - PRINT utility - "

			include 'COPYRIGH.INC'

			db   01Ah	; fake end of file for 'TYPE'
			rb      (361 - 80h) + 310      ; (362 - 80h) is IBM's New
					; recommended Stack Size -
					; Old recommended Stack Size
					; == New stack growth
label ISTACK word   ;Stack starts here and grows down the

;Resident data

;
; Due to flagrant bogosity by file servers, BUSY is *ALWAYS* relevant.
;
BUSY			DB   0		;Internal ME flag

;
; WARNING!!! The *&^%(*&^ 286 chip hangs if you access a word that will wrap
; at the segment boundary.  Make the initial INDOS point somewhere reasonable.
;
label INDOS dword
	dw TIMESLICE	;DOS buisy flag
	dw CodeR_
NEXTINT 		rd      1 ;Chain for int
NEXT_REBOOT		rd      1 ;Chain for ROM bootstrap

fFake			db   0		; TRUE => do not diddle I/O ports
SOFINT			DB   0		;Internal ME flag
TICKCNT 		DB   0		;Tick counter
TICKSUB 		DB   0		;Tick miss counter
SLICECNT		DB   DefTimeSlice ;Time slice counter, init to same val
					; as TIMESLICE

TIMESLICE		DB   DefTimeSlice ;The PRINT scheduling time slice. PRINT
					; lets this many "ticks" go by before
					; using a time slice to pump out characters.
					; Setting this to 3 for instance means PRINT
					; Will skip 3 slices, then take the fourth.
					; Thus using up 1/4 of the CPU. Setting it
					; to one gives PRINT 1/2 of the CPU.
					; The above examples assume MAXTICK is
					; 1. The actual PRINT CPU percentage is
					; (MAXTICK/(1+TIMESLICE))*100

MAXTICK 		DB   DefMaxTick ;The PRINT in timeslice. PRINT will pump
					; out characters for this many clock ticks
					; and then exit. The selection of a value
					; for this is dependent on the timer rate.

BUSYTICK		DB   DefBusyTick ;If PRINT sits in a wait loop waiting for
					; output device to come ready for this
					; many ticks, it gives up its time slice.
					; Setting it greater than or equal to
					; MAXTICK causes it to be ignored.

;User gets TIMESLICE ticks and then PRINT takes MAXTICK ticks unless BUSYTICK
;	ticks go by without getting a character out.

QueueLen		db   DefQueueLen ; Actual length of print queue
			align 2
EndQueue		rw      1 ; pointer to end of print queue
QueueTail		dw   FileQueue        ; pointer to next free entry
					;  in the print queue
buffer			rw      1 ; pointer to data buffer

I24_ERR 		rw      1 ;Save location for INT 24H error code
Ctrlc			rb      1 ; saved ^C trapping state
SPNEXT			rd      1 ;Chain location for INT 28
COMNEXT 		rd      1 ;Chain location for INT 2F
SSsave			rw      1 ;Stack save area for INT 24
SPsave			rw      1
HERRINT 		rd      1 ;Place to save Hard error interrupt
LISTDEV 		rd      1 ;Pointer to Device
COLPOS			DB   0		;Column position for TAB processing
CURRFIL 		DB   0
CURRCP			DW   -1 	; Current file's CP in binary           ;AN000;
NXTCHR			rw      1
CURRHAND		DW   -1
PrinterNum		DW   no_lptx	; index for printer
no_lptx 		=  (-1)	; no valid LPTx
QueueLock		db   0		; queue lock, 0=unlocked


PChar			rb      1 ; path character
AmbCan			rb      1 ; = 1 ambigous cancel
CanFlg			rb      1 ; = 1 Current was already canceled
ACanOcrd		rb      1 ; = 1 a file was found during an
					;  ambigous cancel

;--- Warnning: this is a FCB!!

ACBuf			rb      1
ACName			rb      8
ACExt			rb      3
			rb      4     ; how big is an unopened fcb???


CONTXTFLAG		DB   0		;0 means his context, NZ means me
HISPDB			rw      1
PABORT			DB   0		;Abort flag
BLKSIZ			DW   DefBufferLen ;Size of the PRINT I/O block in bytes
ENDPTR			rw      1

label COMDISP word   ; Communications dispatch table

			DW   INST_REQ
			DW   ADDFIL
			DW   CANFIL
			DW   CanAll
			DW   QSTAT
			DW   EndStat
			DW   QSTATDEV

label query_list word

			dw   1
			qea$1 QEA EAISBINARY,EASYSTEM,2,"C"
			db   "P"	; specify name as CP

label list word
			dw   1		; only one EA of interest
			ea$1 EA EAISBINARY,EASYSTEM,?,2,2,"C"
			db   "P"
code_page		dw   0		; CP initialized to 0

; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
list_size		=  ($ - list)
					;--------------------------------------
					; Resident Message Buffer - Data area
					;--------------------------------------

ERRMES			DB   13,10,13,10
			DB   "**********"
			DB   13,10,"$"

BELMES			DB   13,0CH,7,"$"

CRLF			DB   13,10,0

					;--------------------------------------
					; Resident Message Pointer Control Block
					;--------------------------------------

MESBAS			rw      1 ; offset ERR0	   This list is order sensitive
			DW   ?		; offset ERR1	   and must not be changed without
			DW   ?		; offset ERR2	   considering the logic in
			DW   ?		; offset ERR3	   Load_R_Msg
			DW   ?		; offset ERR4
			DW   ?		; offset ERR5
			DW   ?		; offset ERR6
			DW   ?		; offset ERR7
			DW   ?		; offset ERR8
			DW   ?		; offset ERR9
			DW   ?		; offset ERR10
			DW   ?		; offset ERR11
			DW   ?		; offset ERR12
ERRMEST_PTR		rw      1 ; offset ERRMEST
ErrMesT2_PTR		rw      1 ; offset ErrMesT2
CANMES_PTR		rw      1 ; offset CANMES
CanFilNam_PTR		rw      1 ; offset CanFilNam
AllCan_PTR		rw      1 ; offset AllCan
FATMES_PTR		rw      1 ; offset FATMES
BADDRVM_PTR		rw      1 ; offset BADDRVM

ENDRES			rw      1 ; filled in at initialization time

PRTDPL			DPL 

end if

BREAK			<Resident Code>

if SEGSEL = S_CODER

BREAK			<Server critical section routines>

;  SALUT$ (4,4,9,41)

TestSetServer:

   clc
   push ax
   mov	ax,8700h			; Can I run?
   int	2Ah
   pop	ax

   ret

LeaveServer:

   push ax
   mov	ax,8701h
   int	2Ah
   pop	ax

   ret
					;---------------------------------------
					; Interrupt routines
					;---------------------------------------

;ASSUME CS:CodeR,DS:nothing,ES:nothing,SS:nothing

					;---------------------------------------
					;
					; PRINT is stimulated by a hardware
					;	interrupt.
					;
					;
					; The Server may also stimulate us
					; during timer ticks (if we handled
					; the ticks ourselves, it would be
					; disasterous).  Therefore, we have a
					; substitute entry here that simulates
					; the timer stuff but does NOT muck
					; with the ports.
					;
					;---------------------------------------
FakeINT1C:

   mov	byte [cs:fFake],-1
   jmp	SHORT InnerHardInt

HDSPINT:				;Hardware interrupt entry point

   mov	byte [cs:fFake],0

InnerHardInt:

   call TestSetServer

;  if$	nc				;				       ;AC000;
   JC IF1$$

       inc  byte [cs:TICKCNT] ;Tick
       inc  byte [cs:TICKSUB] ;Tick
       cmp  byte [cs:SLICECNT],0

;      if$  nz				;				       ;AC000;
       JZ IF2$$

	   dec	byte [cs:SLICECNT] ;Count down

;      else$				;				       ;AC000;
       JMP SHORT EN2$$
IF2$$:

	   cmp	byte [cs:BUSY],0 ; interrupting ourself ?

;	   if$	z,and			; if NOT interupting ourselves and ... ;AC000;
	   JNZ IF4$$

	   push ax			; check for nested interrupts
	   mov	al,00001011b		; select ISR in 8259
	   out	20h,al
	   jmp	x

x:

	   in	al,20H			; get ISR register
	   and	al,0FEH 		; mask timer int
	   pop	ax

;	   if$	z,and			; if there are no other ints to service;AC000;
	   JNZ IF4$$

	   push ds
	   push si
	   lds	si,[cs:INDOS] ;Check for making DOS calls

					;---------------------------------------
					;
					; WARNING!!! Due to INT 24 clearing the
					; INDOS flag, we must test both INDOS
					; and ERRORMODE at once!
					;
					; These must be contiguous in MSDATA.
					;
					;---------------------------------------
	   cmp	word [SI-1],0
	   pop	SI
	   pop	DS

;	   if$	z			; if no errors			       ;AC000;
	   JNZ IF4$$

	       inc  byte [cs:BUSY] ;Exclude furthur interrupts
	       mov  byte [cs:TICKCNT],0 ;Reset tick counter
	       mov  byte [cs:TICKSUB],0 ;Reset tick counter
	       sti			;Keep things rolling
	       test byte [cs:fFake],-1

;	       if$  z			;if needed			       ;AC000;
	       JNZ IF5$$

		   push ax
		   mov	al,EOI		;Acknowledge interrupt
		   out	AKPORT,al
		   pop	ax

;	       endif$			; endif 			       ;AC000;
IF5$$:

	       call DOINT
	       cli
	       push ax
	       mov  al,[cs:TIMESLICE]
	       mov  [cs:SLICECNT],al ;Either soft or hard int resets time slice
	       pop  ax
	       dec  byte [cs:BUSY] ;Done, let others in

;	   endif$			;				       ;AC000;
IF4$$:

;      endif$				;				       ;AC000;
EN2$$:

       Call LeaveServer

;  endif$				;				       ;AC000;
IF1$$:

   test byte [cs:fFake],-1

;  if$	z				;				       ;AC000;
   JNZ IF10$$

       jmp  [cs:NEXTINT] ; chain to next clock routine

;  endif$				;				       ;AC000;
IF10$$:

   iret

					;---------------------------------------
					; PRINT is stimulated by a
					;  spooler idle interrupt
					;---------------------------------------

SPINT:					; INT 28H entry point

   call TestSetServer

;  if$	nc				; if no server			       ;AC000;
   JC IF12$$

       cmp  byte [cs:BUSY],0

;      if$  z				; if not busy			       ;AC000;
       JNZ IF13$$

	   inc	byte [cs:BUSY] ; exclude hardware interrupt
	   inc	byte [cs:SOFINT] ; indicate a software int in progress
	   sti				; hardware interrupts ok on INT 28H entry
	   call DOINT
	   cli
	   mov	byte [cs:SOFINT],0 ;Indicate INT done
	   push ax
	   mov	al,[cs:TIMESLICE]
	   mov	[cs:SLICECNT],al ;Either soft or hard int resets time slice
	   pop	ax
	   dec	byte [cs:BUSY]

;      endif$				;				       ;AC000;
IF13$$:

       call LeaveServer

;  endif$				;				       ;AC000;
IF12$$:

   jmp	[cs:SPNEXT] ;Chain to next INT 28

					;---------------------------------------
					; Since we may be entering at arbitrary
					; times, we need to get/set the extended
					; error as we may end up blowing it away.
					; We do not do this on spooler ints.
					;---------------------------------------

SaveState DPL      ; empty DPL

;   public enterprint

EnterPRINT:

   test byte [cs:SOFINT],-1

;  if$	z				;if not soft int		       ;AC000;
   JNZ IF16$$

       mov  ah,GetExtendedError
       call DO_21
       mov  [cs:SaveState.DPL_AX],AX
       mov  [cs:SaveState.DPL_BX],BX
       mov  [cs:SaveState.DPL_CX],CX
       mov  [cs:SaveState.DPL_DX],DX
       mov  [cs:SaveState.DPL_SI],SI
       mov  [cs:SaveState.DPL_DI],DI
       mov  [cs:SaveState.DPL_DS],DS
       mov  [cs:SaveState.DPL_ES],ES

;  endif$				;				       ;AC000;
IF16$$:

   ret

;   public leaveprint

LeavePRINT:

   test byte [cs:SOFINT],-1

;  if$	z				; if soft int			       ;AC000;
   JNZ IF18$$

       mov  ax,(ServerCall SHL 8) + 10
       push cs
       pop  ds
       mov  dx,SaveState
       call DO_21

;  endif$				;				       ;AC000;
IF18$$:

   ret

;   public doint

DOINT:

;   ASSUME CS:CodeR,DS:nothing,ES:nothing,SS:nothing

   cmp	byte [cs:CURRFIL],0
   jnz	GOAHEAD

SPRET:

   ret					;Nothing to do

GOAHEAD:

   cmp	byte [cs:QueueLock],1
   je	SPRET				; queue locked, do nothing...
   push ax				;Need a working register
   mov	[cs:SSsave],ss
   mov	[cs:SPsave],sp
   mov	ax,cs
   cli
					;---------------------------------------
					; Go to internal stack to prevent
					; INT 24 overflowing system stack
					;---------------------------------------
   mov	ss,ax
   mov	sp,ISTACK
   sti
   push es
   push ds
   push bp
   push bx
   push cx
   push dx
   push si
   push di
   push cs
   pop	ds

;   ASSUME DS:CodeR

   call EnterPRINT
   mov	bx,[NXTCHR]
   cmp	bx,[ENDPTR]
   jb	PLOOP
   jmp	READBUFF			;Buffer empty

DONEJMPJP:

   popf 				;				       ;AC000;

DONEJMPJ:

   jmp	DONEJMP

FILEOFJ:

;   ASSUME DS:CodeR

   jmp	FILEOF

PLOOP:

   mov	bx,[NXTCHR]
   cmp	bx,[ENDPTR]
   jae	DONEJMPJ			;Buffer has become empty
   cmp	byte [SOFINT],0
   jnz	STATCHK
   push ax
   mov	al,[MAXTICK]
   cmp	[TICKCNT],al			;Check our time slice
   pop	ax
   jae	DONEJMPJ

STATCHK:

   call PSTAT
   pushf
   cmp	byte [CURRFIL],0
   jz	DONEJMPJP			;File got cancelled by error
   popf 				;				       ;AC000;
   jz	DOCHAR				;Printer ready
   cmp	byte [SOFINT],0
   jnz	DONEJMP 			;If soft int give up
   push ax
   mov	al,[BUSYTICK]
   cmp	[TICKSUB],al			;Check our busy timeout
   pop	ax
   jae	DONEJMP
   jmp	PLOOP

DOCHAR:

   mov	al,byte [BX]
   cmp	al,1Ah				;^Z?
   jz	FILEOFJ 			;CPM EOF
   cmp	al,0Dh				;CR?

;  if$	z				; if CR 			       ;AC000;
   JNZ IF20$$

       mov  byte [COLPOS],0

;  endif$				;				       ;AC000;
IF20$$:

   cmp	al,9				;TAB?
   jnz	NOTABDO
   mov	cl,[COLPOS]			;expand tab to # spaces
   or	cl,0F8h
   neg	cl
   xor	ch,ch
   jcxz TABDONE 			;CX contains # spaces to print

;G	TABLP:

   mov	al," "
   inc	byte [COLPOS]
   push cx
   call POUT
   pop	cx
   dec	cx				;G
   jz	TABDONE 			;G We're done - get next char
   jmp	PLOOP				;G Keep processing tab

;G	LOOP	TABLP
;G	JMP	TABDONE

NOTABDO:

   cmp	al,8				;Back space?
   jnz	NOTBACK
   dec	byte [COLPOS]

NOTBACK:

   cmp	al,20h				;Non Printing char?

;  if$	ae				; if not printable
   JNAE IF22$$

       inc  byte [COLPOS] ;Printing char

;  endif$				;
IF22$$:

   call POUT				;Print it

TABDONE:

   inc	word [NXTCHR] ;Next char
   mov	byte [TICKSUB],0 ;Got a character out, Reset counter
   cmp	byte [SOFINT],0 ;Soft int does one char at a time
   jnz	DONEJMP
   jmp	PLOOP

DONEJMP:

   call CONTEXT_BACK
   call LeavePRINT
   pop	di
   pop	si
   pop	dx
   pop	cx
   pop	bx
   pop	bp
   pop	ds
   pop	es

;   ASSUME DS:nothing,ES:nothing

   cli
   mov	ss,[cs:SSsave] ;Restore Entry Stack
   mov	sp,[cs:SPsave]
   sti
   pop	ax

   ret

CONTEXT_BACK:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   cmp	byte [cs:CONTXTFLAG],0

;  if$	nz				; if not in context		       ;AC000;
   JZ IF24$$

       SaveReg <AX,BX>
       mov  bx,[cs:HISPDB]
       mov  ah,Set_Current_PDB
       call DO_21
       RestoreReg <BX,AX>
       mov  byte [cs:CONTXTFLAG],0

;  endif$				;				       ;AC000;
IF24$$:

   ret

CONTEXT_SWITCH:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   cmp	byte [cs:CONTXTFLAG],0

;  if$	z				; if context off		       ;AC000;
   JNZ IF26$$

       SaveReg <BX,AX>
       mov  ah,Get_Current_PDB
       call DO_21
       mov  [cs:HISPDB],bx
       mov  bx,cs
       sub  bx,10h			; The 2.5 print is an exe program
       mov  ah,Set_Current_PDB
       call DO_21
       RestoreReg <AX,BX>
       mov  byte [cs:CONTXTFLAG],1

;  endif$				;				       ;AC000;
IF26$$:

   ret
					;---------------------------------------
					;--- Refill the print buffer ---
					;---------------------------------------
READBUFF:

;   ASSUME DS:CodeR,ES:NOTHING,SS:NOTHING

   call Set24				; switch Int24 vector
   mov	byte [PABORT],0 ;No abort
   mov	BX,[CURRHAND]
   mov	CX,[BLKSIZ]
   mov	DX,[buffer]
   mov	AH,Read
   call My21
   pushf
   call Res24				; reset Int 24 vector
   cmp	byte [PABORT],0
   jz	NOHERR
   pop	ax				;Flags from read
   jmp	FilClose			;Barf on this file, got INT 24

NOHERR:

   popf 				;				       ;AC000;
   jc	FILEOF
   cmp	ax,0
   jz	FILEOF				;Read EOF?
   mov	bx,[buffer]			;Buffer full
   mov	di,bx
   add	di,ax
   mov	[NXTCHR],bx
   mov	cx,[BLKSIZ]
   sub	cx,ax

;  if$	ncxz				; if buffer is not completely full     ;AC000;
   JCXZ IF28$$

       push cs
       pop  es
       mov  al,1Ah
       cld
       rep  stosb			; pad the buffer

;  endif$				; endif 			       ;AC000;
IF28$$:

   jmp	DONEJMP

FILEOF:

   mov	al,0Ch				;Form feed
   call POUT
					;---------------------------------------
					;--- Close file
					;
					;      note: we came here from an i24
					;	     then PAbort is already = 1
					;---------------------------------------
FilClose:

   call Set24
   mov	byte [PABORT],-1
   mov	bx,[CURRHAND]
   call CloseFile			;				       ;AC000;
   call Res24
   mov	byte [CURRFIL],0 ; No file
   mov	word [CURRHAND],-1 ; Invalid handle
   mov	ax,[ENDPTR]
   mov	[NXTCHR],ax			; Buffer empty

					;---------------------------------------
					;--- Send close on output device
					;---------------------------------------
   call Close_Dev

					;---------------------------------------
					;--- compact the print queue
					;---------------------------------------

CompQAgn:

   call CompQ

					;---------------------------------------
					;--- Check if there are any more
					;	    files to print
					;---------------------------------------
   mov	si,FileQueue
   cmp	byte [si],0       ; no more left if name starts with nul
   je	NoFilesLeft
   call Set24
   mov	byte [PABORT],0 ;No abort
   mov	dx,si				; DS:DX points to file name
   call OpenFile			; try opening new file		       ;AC000;
   pushf
   call Res24
   cmp	byte [PABORT],0
   je	NoI24a
   popf 				;				       ;AC000;
   jmp	short CompQAgn			; try next file

NoI24a:

   popf 				;				       ;AC000;
   jnc	GotNewFile
   call PrtOpErr
   jmp	short CompQAgn

GotNewFile:				; buffer was already marked as empty

   mov	[CURRHAND],ax
   mov	byte [CURRFIL],1

					;---------------------------------------
					;--- Send Open on output device
					;---------------------------------------
   call Open_Dev

NoFilesLeft:

   jmp	DONEJMP

					;---------------------------------------
					;--- Print open error ---
					;	 - preserves DS
					;---------------------------------------

PrtOpErr:

;   ASSUME DS:CodeR,ES:nothing

					;---------------------------------------
					; This stuff constitutes a "file" so it
					; is bracketed by an open/close
					; on the output device.
					;---------------------------------------

					;---------------------------------------
					;--- Send Open on output device
					;---------------------------------------
   call Open_Dev

   push cs
   pop	es

;   ASSUME ES:CodeR

   mov	si,ERRMES
   call LISTMES
   mov	si,[ErrMesT2_PTR] ;				       ;AC000;
   call LISTMES
   mov	si,FileQueue
   call ListMes2
   mov	si,BELMES
   call LISTMES

					;---------------------------------------
					;--- Send close on output device
					;---------------------------------------

   call Close_Dev

   ret


					;---------------------------------------
					;--- Compact File Queue ---
					;      - modifies: AX,CX,SI,DI,ES
					;---------------------------------------

CompQ:

;   ASSUME DS:CodeR,ES:nothing,SS:nothing

   push cs
   pop	es

;   ASSUME ES:CodeR

   mov	di,FileQueue        ; ES:DI points to top of queue
   mov	si,(FileQueue + MaxFileLen)        ; DS:SI points to next entry
   mov	cx,[EndQueue]
   sub	cx,si				; length in bytes of the queue
   cld
   rep	movsb				; compact the queue
   mov	ax,[QueueTail]			; normalize tail pointer as we
   sub	ax,MaxFileLen			;  know have a new "next empty slot"
   mov	[QueueTail],ax
   mov	si,ax
   mov	byte [si],0       ; nul first byte of last entry

   ret


   BREAK <Resident DSKERR>

					;---------------------------------------
					;--- Set Local Int 24 vector ---
					;	 -  modifies: AX,DX
					;---------------------------------------

Set24:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   push es
   push bx
   push dx
   mov	al,24h
   mov	ah,Get_Interrupt_Vector
   call DO_21
   mov	word [cs:HERRINT+2],es   ; Save current vector
   mov	word [cs:HERRINT],bx
   mov	dx,DSKERR
   mov	al,24h
   mov	ah,Set_Interrupt_Vector 	; Install our own
   call DO_21				; Spooler must catch its errors
   pop	dx
   pop	bx
   pop	es

   ret
					;---------------------------------------
					;--- Reset Old Int 24 vector ---
					;	  -  modifies: none
					;---------------------------------------
Res24:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   push ds
   push ax
   push dx
   lds	dx,[cs:HERRINT]

;   ASSUME DS:nothing

   mov	al,24h
   mov	ah,Set_Interrupt_Vector
   call DO_21				;Restore Error INT
   pop	dx
   pop	ax
   pop	ds

   ret
					;---------------------------------------
					;--- INT 24 handler ---
					;---------------------------------------
DSKERR:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   cmp	byte [cs:PABORT],0

;  if$	z				; if not to ignore		       ;AC000;
   JNZ IF30$$

       sti
       push bx
       push cx
       push dx
       push di
       push si
       push bp
       push es
       push ds
       push cs
       pop  ds
       push cs
       pop  es

;       ASSUME DS:CodeR,ES:CodeR

       mov  si,[BADDRVM_PTR] ; Fix up Drive ID for FATMES	       ;AC000;
       add  [ds:si],al			;				       ;AC000;
       mov  si,ERRMES
       call LISTMES
       test AH,080H

;      if$  z				; if not fat error		       ;AC000;
       JNZ IF31$$

	   and	di,0FFh
	   cmp	di,12

;	   if$	a			; if greater - force it to 12	       ;AC000;
	   JNA IF32$$

	       mov  di,12

;	   endif$			;				       ;AC000;
IF32$$:

	   mov	[I24_ERR],di
	   shl	di,1
	   mov	di,word [di+MESBAS]     ; Get pointer to error message
	   mov	si,di
	   call LISTMES 		; Print error type
	   mov	si,[ERRMEST_PTR] ;				       ;AC000;
	   call LISTMES
	   mov	si,FileQueue        ; print filename
	   call ListMes2		; print name
	   mov	si,BELMES
	   call LISTMES

;      else$				;				       ;AC000;
       JMP SHORT EN31$$
IF31$$:

	   mov	word [I24_ERR],0FFh
	   mov	si,[FATMES_PTR] ;				       ;AC000;
	   call LISTMES

;      endif$				;				       ;AC000;
EN31$$:

       inc  byte [PABORT] ;Indicate abort
       pop  ds
       pop  es
       pop  bp
       pop  si
       pop  di
       pop  dx
       pop  cx
       pop  bx

;  endif$				;				       ;AC000;
IF30$$:

   xor	al,al				;Ignore

   iret

   BREAK <Resident SPCOMINT>

					;---------------------------------------
					;--- Communications interrupt ---
					;---------------------------------------

SPCOMINT:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   cmp	ah,1
   jbe	MINE
   jmp	[cs:COMNEXT]

MINE:

   cmp	al,0F8h
   jae	RESERVED_RET
   cmp	ax,0080h
   jnz	CheckPSP
   jmp	FakeINT1C

CheckPSP:

   or	ah,ah
   jne	PSPDO
   mov	al,1				; Tell PSPRINT to go away (AH = 1)

RESERVED_RET:

   iret

PSPDO:

   or	al,al
   jne	PSPDISP

INST_REQ:

   mov	al,0FFh

   iret

PSPDISP:

   cmp	byte [cs:BUSY],0
   jz	SETCBUSY

ErrBusy:

   mov	ax,error_busy

setcret:

   push bp
   mov	bp,sp
   or	word [bp+6],f_Carry
   pop	bp

   iret

SETCBUSY:

   XOR	AH,AH
   CMP	AX,6				; check function within valid range
   Jbe	GoForIt
   mov	ax,error_invalid_function
   jmp	setcret

GoForIt:

   inc	byte [cs:BUSY] ;Exclude
   sti					;Turn ints back on
   push di				;G
   push es
   push ds
   push cs
   pop	ds

;   ASSUME DS:CodeR

   mov	byte [QueueLock],0 ; unlock the print queue
   shl	ax,1				;Turn into word index
   mov	di,ax
   call [DI+COMDISP]

;   ASSUME DS:nothing

;  if$	nc				; if no error			       ;AC000;
   JC IF37$$

;       ASSUME DS:CodeR,ES:nothing

       push ds
       push cs
       pop  ds

;       ASSUME DS:CodeR,ES:nothing

       call PSTAT			; Tweek error counter
       pop  ds

;       ASSUME DS:nothing

;  endif$				;				       ;AC000;
IF37$$:

   pushf
   call CONTEXT_BACK
   popf 				;				       ;AC000;
   cli
   dec	byte [cs:BUSY] ; leaves carry alone!
   pop	ds

;   ASSUME DS:nothing

   pop	es
   pop	di				;G
   jc	setcret
   push bp
   mov	bp,sp
   and	word [bp+6],NOT f_Carry
   pop	bp

   iret

;SpComInt Endp

   BREAK <Get queue status>

					;---------------------------------------
					;--- Return pointer to file queue ---
					;---------------------------------------

QSTAT:

;   ASSUME DS:CodeR,ES:nothing

   mov	byte [QueueLock],1 ; lock the print queue
   call PSTAT				; Tweek error counter
   push bp
   mov	bp,sp				;  0	2    4
   mov	[bp+ 2 + 2],cs			; <BP> <RET> <DS>
   pop	bp
   mov	si,FileQueue
   mov	dx,[ERRCNT]			; return error count
   clc

   ret
					;---------------------------------------
					;--- Return pointer to device ---
					;     --- driver if active ---
					;---------------------------------------
QSTATDEV:

;   ASSUME DS:CodeR,ES:nothing

   xor	ax,ax				;g assume not busy
   mov	byte [QueueLock],1 ;g lock the print queue
   call PSTAT				;g Tweek error counter
   cmp	byte [FileQueue],0    ;g is there anything in the queue?
   clc					;g
   jz	qstatdev_end			;g no - just exit
   mov	ax,error_queue_full		;g yes - set error queue full
   mov	si,word [LISTDEV+2]      ;g get segment of list device
   push bp				;g
   mov	bp,sp				;g  0	 2   4
   mov	[bp+2+2],si			;g <BP><RET><DS> seg of device to DS
   pop	bp				;g
   mov	si,word [LISTDEV]      ;g offset of device to SI
   stc					;g

qstatdev_end:				;g

   mov	byte [QueueLock],0 ;g unlock the print queue
   ret					;g

   BREAK <Resident EndStat>

					;---------------------------------------
					;--- Unlock the print queue ---
					;---------------------------------------

EndStat:

;   ASSUME DS:CodeR,ES:nothing

   mov	byte [QueueLock],0
   clc

   ret

   BREAK <Cancel all available files in the queue>

					;---------------------------------------
					; Note: Loop until the background is free
					;---------------------------------------

CanAll:

;   ASSUME DS:CodeR,ES:nothing

   cmp	byte [CURRFIL],0 ; are we currently printing?

;  if$	nz				;
   JZ IF39$$

					;---------------------------------------
					;--- Cancel active file
					;---------------------------------------

       mov  bx,[CURRHAND]		; close the current file
       call Set24
       mov  byte [PABORT],1 ; no Int24's
       call CloseFile			; close the file		       ;AC000;
       call Res24
       mov  byte [CURRFIL],0 ; no files to print
       mov  word [CURRHAND],-1 ; invalidate handle
       mov  ax,[ENDPTR] 		; buffer empty
       mov  [NXTCHR],ax

					;---------------------------------------
					;--- Cancel rest of files
					;---------------------------------------

       mov  si,FileQueue
       mov  [QueueTail],si		; next free entry is the first
       mov  byte [si],0      ; nul first byte of firts entry
       mov  si,[AllCan_PTR] ;				       ;AC000;
       call LISTMES			; print cancelation message
       mov  si,BELMES
       call LISTMES			; ring!!

					;---------------------------------------
					;--- Send close on output device
					;---------------------------------------

       call Close_Dev
       clc

;  endif$				;				       ;AC000;
IF39$$:

   ret

   BREAK <Cancel a file in progress>

CANFIL:

;   ASSUME DS:CodeR,ES:nothing

   cmp	byte [CURRFIL],0
   jnz	DOCAN

   ret					;  carry is clear

DOCAN:
					;---------------------------------------
					;--- find which file to cancel
					;---------------------------------------
   push bp
   mov	bp,sp				;  0	2    4
   mov	ds,[bp+ 2 + 2]			; <BP> <RET> <DS>
   pop	bp

;   ASSUME DS:nothing

   push cs
   pop	es

;   ASSUME ES:CodeR

   mov	byte [es:CanFlg],0 ; reset message flag
   mov	byte [es:ACanOcrd],0 ; no cancelation has ocured yet
   mov	bx,FileQueue        ; ES:BX points to 1st entry in queue
   call AmbChk

AnotherTry:

   mov	di,bx				; ES:DI points to 1st entry in queue
   mov	si,dx				; DS:SI points to filename to cancel

MatchLoop:

   lodsb
   cmp	al,byte [es:di]      ; names in queue are all in upper case
   je	CharMatch
   jmp	AnotherName			; a mismatch, try another name

CharMatch:

   cmp	byte [es:di],0         ; was this the terminating nul?
   je	NameFound			; yes we got our file...
   inc	di
   jmp	MatchLoop

AnotherName:

   cmp	byte [es:AmbCan],1 ; ambigous file name specified?
   jne	AnName				; if not then no more work to do
   cmp	al,"?"
   jne	AnName
   cmp	byte [es:di],"."
   je	FindPeriod
   cmp	byte [es:di],0      ; if nul then file names match
   jne	CharMatch			;  only if only ?'s are left...

FindNul:

   lodsb
   cmp	al,"?"
   je	FindNul
   cmp	al,"."
   je	FindNul
   or	al,al
   jne	AnName				; found something else, no match
   jmp	short NameFound

FindPeriod:				; ambigous files always have 8 chars

   lodsb				;  in name so we can not look for the
   or	al,al				;  period twice (smart uh?)
   je	AnName				; no period found, files do not match
   cmp	al,"."
   jne	FindPeriod
   jmp	short CharMatch

AnName:

   add	bx,MaxFileLen
   cmp	byte [es:bx],0      ; end of queue?
   jne	AnotherTry			; no, continue...
   cmp	byte [es:ACanOcrd],1 ; yes, was there a file found?
   jne	sk2
   push cs
   pop	ds

;   ASSUME DS:CodeR			; StartAnFil likes it this way...

   jmp	StartAnFil			; restart printing

sk2:

;   ASSUME DS:nothing

   mov	ax,error_file_not_found
   stc

   ret
					;---------------------------------------
					;--- Name found, check if current file
					;---------------------------------------
NameFound:

   push cs
   pop	ds

;   ASSUME DS:CodeR

   mov	byte [ACanOcrd],1 ; remember we found a file
   cmp	bx,FileQueue        ; is the file being printed?

;  if$	e,and				; if it is and ..................      ;AC000;
   JNE IF41$$

   cmp	byte [CanFlg],0 ;				:

;  if$	e				; if not in cancel mode ........:      ;AC000;
   JNE IF41$$

					;---------------------------------------
					;--- Cancel current file
					;---------------------------------------

       mov  byte [CanFlg],1 ; remeber we already canceled current
       push bx
       mov  bx,[CURRHAND]		; close the current file
       call Set24
       mov  byte [PABORT],1 ; no Int24's
       call CloseFile			; close the file		       ;AC000;
       call Res24
       mov  byte [CURRFIL],0 ; no files to print
       mov  word [CURRHAND],-1 ; invalidate handle
       mov  ax,[ENDPTR] 		; buffer empty
       mov  [NXTCHR],ax
       pop  bx
					;---------------------------------------
					;--- print cancelation message
					;---------------------------------------
       push bx
       mov  si,[CANMES_PTR] ;				       ;AC000;
       call LISTMES			; print cancelation message
       mov  si,bx			; points to filename
       call ListMes2			; print filename
       mov  si,[CanFilNam_PTR] ;				       ;AC000;
       call LISTMES
       mov  si,BELMES
       call LISTMES			; ring!!
       pop  bx
					;---------------------------------------
					;--- Send close on output device
					;---------------------------------------
       call Close_Dev

;  endif$				;				       ;AC000;
IF41$$:

   mov	di,bx				; DI points to entry to cancel
   mov	si,bx
   add	si,MaxFileLen			; SI points to next entry
   cmp	si,[QueueTail]			; is the entry being canceled the last?

;  if$	e				; if it is			       ;AC000;
   JNE IF43$$

       mov  byte [di],0      ; yes, just nul the first byte

;  else$				;				       ;AC000;
   JMP SHORT EN43$$
IF43$$:

       mov  cx,[EndQueue]		; CX points to the end of the queue
       sub  cx,si			; length of the remainning of the queue
       cld
       rep  movsb			; compact the queue

;  endif$				;				       ;AC000;
EN43$$:

   mov	ax,[QueueTail]			; remember new end of queue
   sub	ax,MaxFileLen
   mov	[QueueTail],ax
   mov	si,ax
   mov	byte [si],0       ; nul first byte of last entry

   cmp	byte [bx],0       ; is there another file to consider?
   je	StartAnFil
   push bp
   mov	bp,sp				;  0	2    4
   mov	ds,[bp+ 2 + 2]			; <BP> <RET> <DS>
   pop	bp

;   ASSUME DS:nothing

   jmp	AnotherTry			; yes do it again...

					;---------------------------------------
					;--- Start new file...
					;---------------------------------------
StartAnFil:

;   ASSUME DS:CodeR

   cmp	word [CURRHAND],-1 ; was the canceled name the current?
   jne	NoneLeft			; no, just quit

StartAnFil2:

   mov	si,FileQueue        ; points to new current file
   cmp	byte [si],0      ; is there one there?
   je	NoneLeft			; no, we canceled current and are none left
   call Set24
   mov	byte [PABORT],0
   mov	dx,si
   call OpenFile			; try to open the file		       ;AC000;
   pushf
   call Res24
   cmp	byte [PABORT],0
   je	NoI24b
   popf 				;				       ;AC000;
   call CompQ				; compact file queue
   jmp	short StartAnFil2

NoI24b:

   popf 				;				       ;AC000;
   jnc	GoodNewCurr
   call PrtOpErr			; print open error
   call CompQ				; compact file queue
   jmp	short StartAnFil2

GoodNewCurr:

   mov	[CURRHAND],ax			; save handle
   mov	byte [CURRFIL],1 ; signal active (buffer is already empty)

					;---------------------------------------
					;--- Send Open on output device
					;---------------------------------------
   call Open_Dev

NoneLeft:

   clc

   ret
					;---------------------------------------
					;--- Ambigous file name check ---
					;     entry:	 ds:dx points to filename
					;    preserves ds:dx and es
					;---------------------------------------
;   ASSUME DS:nothing,ES:CodeR

AmbChk:

   mov	byte [es:AmbCan],0 ; assume not ambigous
   mov	si,dx
   cld

;  do$					;				       ;AC000;
DO46$$:

       lodsb
       or   al,al			; the nul?

;  enddo$ e				;				       ;AC000;
   JNE DO46$$

   dec	si				; points to nul
   std					; scan backwards

;  do$					;				       ;AC000;
DO48$$:

       lodsb
       cmp  al,"*"

;      if$  e				; if a *			       ;AC000;
       JNE IF49$$

	   mov	byte [es:AmbCan],1

;      endif$				;				       ;AC000;
IF49$$:

       cmp  al,"?"

;      if$  e				; if a ?			       ;AC000;
       JNE IF51$$

	   mov	byte [es:AmbCan],1

;      endif$				;				       ;AC000;
IF51$$:

       cmp  al,[es:PChar]

;  enddo$ e				;				       ;AC000;
   JNE DO48$$

   cld					; be safe
   cmp	byte [es:AmbCan],1 ; an ambigous cancel?

;  if$	e				; if its an ambiguous cancel	       ;AC000;
   JNE IF54$$

					;---------------------------------------
					;--- transform * to ?'s
					;---------------------------------------
       inc  si
       inc  si				; points to actual name (past path char)
       mov  di,ACBuf
       push di
       mov  cx,12
       mov  al,20h
       cld
       rep  stosb			; fill fcb with blanks
       pop  di
       push si
       mov  ax,(Parse_File_Descriptor shl 8) and 0FF00h
       call My21
       pop  si

					;---------------------------------------
					;--- Copy name to expanded name
					;---------------------------------------

       push ds
       pop  es

;       ASSUME DS:nothing

       push cs
       pop  ds

;       ASSUME DS:CodeR

       push es
       mov  di,si
       mov  si,ACName
       mov  cx,8

;      do$				;				       ;AC000;
DO55$$:

	   lodsb			; move name
	   cmp	al,20h

;      leave$ e 			;				       ;AC000;
       JE EN55$$

	   stosb

;      enddo$ loop			;				       ;AC000;
       LOOP DO55$$
EN55$$:

       mov  si,ACExt
       cmp  byte [si],20h      ; extension starts with blank ?

;      if$  ne				; if it does not		       ;AC000;
       JE IF58$$

	   mov	al,"."
	   stosb
	   mov	cx,3

;	   do$				;				       ;AC000;
DO59$$:

	       lodsb			; move name
	       cmp  al,20h

;	   leave$ e			;				       ;AC000;
	   JE EN59$$

	       stosb

;	   enddo$ loop			;				       ;AC000;
	   LOOP DO59$$
EN59$$:

;      endif$				;				       ;AC000;
IF58$$:

       mov  byte [es:di],0      ; nul terminate
       pop  ds

;       ASSUME DS:nothing

       push cs
       pop  es

;  endif$				;				       ;AC000;
IF54$$:

;   ASSUME ES:CodeR

   ret

   BREAK <Add a file to the queue>

ADDFIL:

;   ASSUME DS:CodeR,ES:nothing

					;---------------------------------------
					;--- Check that queue is not full
					;---------------------------------------

   mov	di,[QueueTail]			; load pointer to next empty entry
   cmp	di,[EndQueue]			; queue full?
   jb	OkToQueue			; no, place in queue...
   mov	ax,error_queue_full
   stc

   ret
					;---------------------------------------
					;--- Copy name to empty slot in queue
					;---------------------------------------
OkToQueue:

					;
					; Retrieve old DS
					;
   push bp
   mov	bp,sp				;  0	2    4
   mov	ds,[bp+ 2 + 2]			; <BP> <RET> <DS>
   pop	bp

;   ASSUME DS:nothing

   push cs
   pop	es				; ES:DI points to empty slot

;   ASSUME ES:CodeR

   mov	si,dx				; DS:SI points to submit packet
   cmp	byte [ds:si],0
   jnz	IncorrectLevel
   lds	si,dword [ds:si+1]      ; DS:SI points to filename
   mov	cx,MaxFileLen			; maximum length of file name

CopyLop:

   lodsb
   stosb
   or	al,al				; nul?
   je	CopyDone			; yes, done with move...
   loop CopyLop
   push cs
   pop	ds

;   ASSUME DS:CodeR

   mov	ax,error_name_too_long		; if normal exit from the loop then
   stc

   ret

IncorrectLevel:

   mov	ax,error_invalid_function
   stc

   ret

;   ASSUME DS:nothing,ES:nothing 	; es:nothing = not true but lets

CopyDone:				;   avoid possible problems...

   push cs
   pop	ds

;   ASSUME DS:CodeR

					;---------------------------------------
					;--- advance queue pointer
					;---------------------------------------

   mov	si,[QueueTail]			; pointer to slot just used
   push si				; save for test open later
   add	si,MaxFileLen
   mov	[QueueTail],si			; store for next round
   mov	byte [si],0       ; nul next entry (maybe the EndQueue)

					;---------------------------------------
					;--- Check that file exists
					;---------------------------------------

   call Set24
   mov	byte [PABORT],0
   pop	dx				; get pointer to filename
   call OpenFile			;				       ;AC000;
   pushf
   push dx
   call Res24
   pop	dx
;;;popff				;; dcl removed for p1020	       ;AC000;
   popf 				;; dcl to fix p1020
   jnc	GotFil
					;---------------------------------------
					; See if brain damaged user entered
					;    an invalid drive
					;---------------------------------------
   push ax
   mov	si,dx
   cmp	byte [cs:SI+1],':'
   jz	GotDrive
   pop	ax
   jmp	SHORT	I24BF

GotDrive:

   mov	ah,Get_Default_Drive		; get current
   call My21
   push ax
   mov	dl,[cs:SI]			; get drive letter to test
   or	dl,20h
   sub	dl,'a'
   mov	ah,Set_Default_Drive		; set it
   call My21
   mov	ah,Get_Default_Drive		; get it back
   call My21
   cmp	al,dl				; same? 		;; dcl change al,al to al,dl
   jnz	BadDrive			; no, bad drive
   pop	dx				; get original back
   mov	ah,Set_Default_Drive		; set original
   call My21
   pop	ax
   mov	dx,si
   jmp	SHORT I24BF

BadDrive:

   pop	dx				; get original back
   mov	ah,Set_Default_Drive		; set original
   call My21
   pop	ax
   mov	ax,error_invalid_drive
   mov	dx,si

I24BF:

   mov	si,[QueueTail]			; take bad name out of queue
   sub	si,MaxFileLen			; SI points to the slot with bad name
   mov	[QueueTail],si
   mov	byte [si],0       ; nul the first byte
   stc

   ret


					;---------------------------------------
					;--- Check if print currently busy
					;---------------------------------------

GotFil:

   cmp	byte [CURRFIL],0 ; currently printing?

;  if$	nz				; if currently printing 	       ;AC000;
   JZ IF64$$

       mov  bx,ax			; busy, close handle
       call Set24
       mov  byte [PABORT],1 ; no Int24's
       call CloseFile			; close the file		       ;AC000;
       call Res24

;  else$				;				       ;AC000;
   JMP SHORT EN64$$
IF64$$:
					;---------------------------------------
					;--- Save file data
					;---------------------------------------

       mov  [CURRHAND],ax		; Valid handle
       mov  ax,[ENDPTR]
       mov  [NXTCHR],ax 		; Buffer empty
       mov  byte [CURRFIL],1
					;---------------------------------------
					;--- Send Open on output device
					;---------------------------------------
       call Open_Dev

;  endif$				;				       ;AC000;
EN64$$:

   clc

   ret

   BREAK <Fake int 21H>

					;---------------------------------------
					; perform a  system call as myself
					;---------------------------------------

My21:

   call CONTEXT_SWITCH
   call DO_21

   ret

;   Public do_21

DO_21:

;   ASSUME DS:nothing,ES:nothing

   CMP	byte [cs:INT15FLAG],0

;  if$	nz				; if for PRINT			       ;AC000;
   JZ IF67$$

       push ds
       push bx
       lds  bx,[cs:INT15PTR]
       inc  byte [bx]
       pop  bx
       pop  ds
       call OffSave
       int  21h
       call OnSave
       push ds
       push bx
       pushf				; Flags from system call
       lds  bx,[cs:INT15PTR]
       dec  byte [BX]
       popf				;
       pop  bx				;AC000;
       pop  ds

;  else$				;				       ;AC000;
   JMP SHORT EN67$$
IF67$$:

       call OffSave
       int  21h
       call OnSave

;  endif$				;				       ;AC000;
EN67$$:

   ret

OffSave:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   push ax
   push dx
   mov	ax,Set_CTRL_C_Trapping SHL 8 + 2
   xor	dl,dl
   int	21h
   mov	[cs:Ctrlc],dl
   pop	dx
   pop	ax

   ret

OnSave:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   push ax
   push dx
   mov	ax,Set_CTRL_C_Trapping SHL 8 + 2
   mov	dl,[cs:Ctrlc]
   int	21h
   pop	dx
   pop	ax

   ret

   BREAK <Priter Support>

ListMes2:

;   ASSUME DS:CodeR,ES:nothing

   lodsb
   cmp	al,0
   jz	LMESDONE
   call LOUT
   jmp	SHORT ListMes2


LISTMES:

;   ASSUME DS:CodeR,ES:nothing

   lodsb
   cmp	al,"$"
   jz	LMESDONE
   call LOUT
   jmp	SHORT LISTMES

LMESDONE:

   ret

LOUT:

   push bx

LWAIT:

   call PSTAT
   jz	PREADY
   cmp	word [ERRCNT],ERRCNT2
   ja	POPRET				;Don't get stuck
   jmp	SHORT LWAIT

PREADY:

   call POUT

POPRET:

   pop	bx

   ret


   BREAK <TO_DOS>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	TO_DOS
;
;  FUNCTION:	Make a SERVER DOS call
;
;  INPUT:
;
;  OUTPUT:
;
;  NOTE:
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:
;
;  NORMAL
;  EXIT:
;
;  ERROR
;  EXIT:
;
;  CHANGE	12/16/87 - Add SERVER DOS call - F. G
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START TO_DOS
;
;	ret
;
;	END TO_DOS
;
;******************** END   - PSEUDOCODE ***************************************

TO_DOS:

;   ASSUME DS:NOTHING,ES:NOTHING

;  Call the dos via server dos call using a DPL.  The currentPDB *must* be
;  properly set before this call!
;  INPUT: Regs set for INT 21
;  OUTPUT: Of INT 21



   MOV	[cs:PRTDPL.DPL_DS],DS ;				       ;AN010;
   PUSH CS				;				       ;AN010;
   POP	DS				;				       ;AN010;

   MOV	[cs:PRTDPL.DPL_BX],BX ;				       ;AN010;
   MOV	BL,AL				; set up DRIVE ID		       ;AN010;
   SUB	BL,40h				; convert to number		       ;AN010;
   XOR	AL,AL				; remove file ID		       ;AN010;
   MOV	[cs:PRTDPL.DPL_AX],AX ;				       ;AN010;
   MOV	[cs:PRTDPL.DPL_CX],CX ;				       ;AN010;
   MOV	[cs:PRTDPL.DPL_DX],DX ;				       ;AN010;
   MOV	[cs:PRTDPL.DPL_SI],SI ;				       ;AN010;
   MOV	[cs:PRTDPL.DPL_DI],DI ;				       ;AN010;
   MOV	[cs:PRTDPL.DPL_ES],ES ;				       ;AN010;
   XOR	AX,AX				;				       ;AN010;
   MOV	[cs:PRTDPL.DPL_reserved],AX ;				       ;AN010;
   MOV	[cs:PRTDPL.DPL_UID],AX ;				       ;AN010;
   MOV	AX,CS				;				       ;AN010;
   SUB	AX,10h				;				       ;AN010;
   MOV	[cs:PRTDPL.DPL_PID],AX ;				       ;AN010; ;				      ;AN010;
					; IOCtl call to see if target drive is local
					;   x = IOCTL (getdrive, Drive+1)      ;AN010;
   mov	ax,(IOCtl SHL 8) + 9		;				       ;AN010;
   INT	21h				; IOCtl + dev_local  <4409>	       ;AN010;

   MOV	BX,[cs:PRTDPL.DPL_BX] ; restore register		       ;AN010;

;  if$	nc,and				; target drive local and	       ;AN010;
   JC IF70$$

   test dx,1200H			; check if (x & 0x1000) 	       ;AN010;
					;      (redirected or shared)
;  if$	z				; if RC indicates NOT a network drive  ;AN010;
   JNZ IF70$$

       MOV  DX,PRTDPL        ;				       ;AN010;
       MOV  AX,(ServerCall SHL 8)	; make a SERVER DOS call	       ;AN010;

;  else$				;				       ;AN010;
   JMP SHORT EN70$$
IF70$$:

       MOV  DX,[cs:PRTDPL.DPL_DX] ; fix up reg			       ;AN010;
       MOV  AX,[cs:PRTDPL.DPL_AX] ; make a normal DOS call	       ;AN010;
       PUSH word [cs:PRTDPL.DPL_DS] ; fix up segment reg		       ;AN010;
       POP  DS				;				       ;AN010;

;  endif$				;				       ;AN010;
EN70$$:

   CALL My21				;				       ;AN010;

   RETF    ;				       ;AN010;

;   TO_DOS ENDP

   BREAK <Open_Device>
					;---------------------------------------
					; Stuff for BIOS interface
					;---------------------------------------

;			SALUT$ (4,25,30,41)

IOBUSY			EQU  0200H
IOERROR 		EQU  8000H

BYTEBUF 		rb      1

CALLAD			rd      1

IOCALL			DB   22
			DB   0
IOREQ			rb      1
IOSTAT			DW   0
			rb      8
			DB   0
			DW   BYTEBUF
INTSEG			rw      1
IOCNT			DW   1
			DW   0

;  SALUT$ (4,4,9,41)

					;---------------------------------------
					; Following two routines perform device
					; open and close on output device.
					; NO REGISTERS (including flags) are
					;  Revised. No errors generated.
					;---------------------------------------

;   public open_dev

Open_Dev:

;   ASSUME DS:nothing,ES:nothing

					;---------------------------------------
					; We are now going to use the printer...
					; We must lock down the printer so that
					; the network does not intersperse output
					; on us...
					; We must also signal the REDIRector for
					; stream open.	We must ask DOS to set
					; the Printer Flag to busy
					;---------------------------------------

   push bx
   pushf
   push ax
   push dx
   mov	dx,[cs:PrinterNum]
   cmp	dx,-1

;  if$	nz				;				       ;AC000;
   JZ IF73$$

       mov  ax,0203h			; redirector lock
       int  2Fh
       mov  ax,0201H			; Redirector OPEN
       int  2Fh

;  endif$				;
IF73$$:

   mov	ax,(Set_Printer_Flag SHL 8) + 01
   int	21h
   pop	dx
   pop	ax
   mov	bl,DEVOPN			; Device OPEN
   call OP_CL_OP
   popf 				;				       ;AC000;
   pop	bx

   ret

OP_CL_OP:

   push ds
   push si
   lds	si,[cs:LISTDEV]

;   ASSUME DS:nothing

   test [SI+SYSDEV.SDEVATT],DEVOPCL

;  if$	nz				;				       ;AC000;
   JZ IF75$$

       push cs
       pop  ds

;       ASSUME DS:CodeR

       mov  byte [IOCALL],DOPCLHL
       call DOCALL

;  endif$				;				       ;AC000;
IF75$$:

   pop	si
   pop	ds

;   ASSUME DS:nothing

   ret

;   public close_dev

Close_Dev:

;   ASSUME DS:nothing,ES:nothing

					;---------------------------------------
					; At this point, we release the ownership
					; of the printer... and do a redirector
					; CLOSE.
					; Also tell DOS to reset the Printer Flag
					;---------------------------------------

   push bx
   pushf
   mov	bl,DEVCLS
   call OP_CL_OP			; Device CLOSE
   push ax
   push dx
   mov	dx,[cs:PrinterNum]
   cmp	dx,-1

;  if$	nz				;				       ;AC000;
   JZ IF77$$

       mov  ax,0202h			; redirector CLOSE
       int  2Fh
       mov  ax,0204h			; redirector clear
       int  2Fh

;  endif$				;				       ;AC000;
IF77$$:

   mov	ax,(Set_Printer_Flag SHL 8) +00
   int	21h
   pop	dx
   pop	ax
   popf 				;				       ;AC000;
   pop	bx

   ret

PSTAT:

;   ASSUME DS:CodeR

   push bx
   inc	word [ERRCNT]
   mov	BL,DEVOST
   mov	byte [IOCALL],DSTATHL
   call DOCALL
   test word [IOSTAT],IOERROR

;  if$	nz				;				       ;AC000;
   JZ IF79$$

       or   word [IOSTAT],IOBUSY ;If error, show buisy

;  endif$				;				       ;AC000;
IF79$$:

   test word [IOSTAT],IOBUSY

;  if$	z				; if				       ;AC000;
   JNZ IF81$$

       mov  word [ERRCNT],0

;  endif$				;				       ;AC000;
IF81$$:

   pop	bx

   ret

POUT:

;   ASSUME DS:CodeR

   mov	[BYTEBUF],al
   mov	bx,DEVWRT
   mov	byte [IOCALL],DRDWRHL

DOCALL:

   push es
   mov	[IOREQ],bl
   mov	bx,cs
   mov	es,bx
   mov	word [IOSTAT],0
   mov	word [IOCNT],1
   push ds
   push si
   push ax
   call CONTEXT_SWITCH
   mov	bx,IOCALL
   lds	si,[LISTDEV]

;   ASSUME DS:nothing

   mov	ax,[SI+SYSDEV.SDEVSTRAT]
   mov	word [cs:CALLAD],ax
   call [cs:CALLAD]
   mov	AX,[SI+SYSDEV.SDEVINT]
   mov	word [cs:CALLAD],ax
   call [cs:CALLAD]
   pop	ax
   pop	si
   pop	ds

;   ASSUME DS:CodeR

   pop	es

   ret

;			SALUT$ (4,25,30,41)

REAL_INT_13		rd      1

INT_13_RETADDR		DW   INT_13_BACK

;  SALUT$ (4,4,9,41)

INT_13:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   pushf
   inc	byte [cs:BUSY] ;Exclude if dumb program call ROM
   push cs
   push word [cs:INT_13_RETADDR]
   push word [cs:REAL_INT_13+2]
   push word [cs:REAL_INT_13]

   retf

;   INT_13 ENDP

INT_13_BACK:

   pushf
   dec	byte [cs:BUSY]
   popf 				;				       ;AC000;

   retf	2   ;Chuck saved flags

;   INT_13_BACK ENDP

;			SALUT$ (4,25,30,41)

REAL_INT_15		rd      1
INT15FLAG		DB   0		; Init to off
INT15PTR		rd      1

;  SALUT$ (4,4,9,41)

INT_15:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   cmp	ah,20h
   jnz	REAL_15 			; Not my function
   cmp	AL,1
   ja	REAL_15 			; I only know 0 and 1
   je	FUNC1
   inc	byte [cs:INT15FLAG] ; Turn ON
   mov	word [cs:INT15PTR],bx   ; Save counter loc
   mov	word [cs:INT15PTR+2],es

   iret

FUNC1:

   mov	byte [cs:INT15FLAG],0 ; Turn OFF

   iret

REAL_15:

   jmp	[cs:REAL_INT_15]

;   INT_15 ENDP

;			SALUT$ (4,25,30,41)

FLAG17_14		DB   0		; Flags state of AUX/PRN redir
REAL_INT_5		rd      1
REAL_INT_17		rd      1
INT_17_NUM		DW   0

;  SALUT$ (4,4,9,41)

INT_17:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   cmp	byte [cs:FLAG17_14],1
   jnz	DO_INT_17			;The PRN device is not used
   cmp	byte [cs:CURRFIL],0
   jz	DO_INT_17			;Nothing pending, so OK
   cmp	dx,[cs:INT_17_NUM]
   jnz	DO_INT_17			;Not my unit
   cmp	byte [cs:BUSY],0
   jnz	DO_INT_17			;You are me
   sti
   mov	ah,0A1h 			;You are bad, get time out

   iret

DO_INT_17:

   jmp	[cs:REAL_INT_17] ;Do a 17

;			SALUT$ (4,25,30,41)

REAL_INT_14		rd      1
INT_14_NUM		DW   0

;  SALUT$ (4,4,9,41)

INT_14:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   cmp	byte [cs:FLAG17_14],2
   jnz	DO_INT_14			;The AUX device is not used
   cmp	byte [cs:CURRFIL],0
   jz	DO_INT_14			;Nothing pending, so OK
   cmp	DX,[cs:INT_14_NUM]
   jnz	DO_INT_14			;Not my unit
   cmp	byte [cs:BUSY],0
   jnz	DO_INT_14			;You are me
   sti
   or	ah,ah
   jz	SET14_AX
   cmp	ah,2
   jbe	SET14_AH

SET14_AX:

   mov	al,0

SET14_AH:

   mov	ah,80h				;Time out

   iret

DO_INT_14:

   jmp	[cs:REAL_INT_14] ;Do a 14

INT_5:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   cmp	byte [cs:FLAG17_14],1
   jnz	DO_INT_5			;The PRN device is not used
   cmp	byte [cs:CURRFIL],0
   jz	DO_INT_5			;Nothing pending, so OK
   cmp	word [cs:INT_17_NUM],0
   jnz	DO_INT_5			;Only care about unit 0

   iret 				;Pretend it worked

DO_INT_5:

   jmp	[cs:REAL_INT_5] ;Do a 5

;			SALUT$ (4,25,30,41)

ERRCNT			DW   0

;  SALUT$ (4,4,9,41)

   BREAK <Bootstrap Cleanup Code>

ReBtINT:

;   ASSUME CS:CodeR,DS:nothing,ES:nothing,SS:nothing

   cli
   push cs
   pop	ds

IntWhileBusy_:

   int	ComInt
   jnc	NotBusy
   jmp	IntWhileBusy_

NotBusy:

   inc	byte [cs:BUSY] ; Exclude hardware interrupts
   inc	byte [cs:SOFINT] ; Exclude software interrupts

   call CanAll				; Purge the Queue

   lds	dx,[cs:COMNEXT]
   mov	ax,(Set_Interrupt_Vector shl 8) or ComInt
   int	21h				;Set int 2f vector

   lds	dx,[cs:NEXTINT]
   mov	ax,(Set_Interrupt_Vector shl 8) or INTLOC
   int	21h				;Set hardware interrupt

   mov	ax,(Set_Interrupt_Vector shl 8) or 15h
   lds	dx,[cs:REAL_INT_15] ; Reset the wait on event on ATs
   int	21h

   mov	ax,(Set_Interrupt_Vector shl 8) or 17h
   lds	dx,[cs:REAL_INT_17]
   int	21h				;Set printer   interrupt

   mov	ax,(Set_Interrupt_Vector shl 8) or 5h
   lds	dx,[cs:REAL_INT_5]
   int	21h				;Set print screen   interrupt

   mov	ax,(Set_Interrupt_Vector shl 8) or 14h
   lds	dx,[cs:REAL_INT_14]
   int	21h				;Set printer   interrupt

   mov	ax,(Set_Interrupt_Vector shl 8) or 24h
   lds	dx,[cs:HERRINT]
   int	21h				;Set printer   interrupt

   mov	ax,(Set_Interrupt_Vector shl 8) or REBOOT
   lds	dx,[cs:NEXT_REBOOT]
   int	21h				;Set bootstrap interrupt

   sti
   int	19h

   BREAK <OpenFile>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	OpenFile    - PRINT Open a File for printing
;
;  FUNCTION:	This subroutine will mannage all environment changes required
;		for Code Page switching support. This is accomplished as set
;		out in the pseudocode below.
;
;  INPUT:	(DS:DX) = ASCIIZ of file to print
;
;  OUTPUT:	(AX) = handle of file
;		No CPSW     - File opened using INT 21 - 3D
;		CPSW active - no CP on print file
;				    - Print file opened using INT 21 - 3D
;			    - valid CP on print file
;				    - PRINTER.SYS locked from CP change
;				    - Print file opened using INT 21 - 6C
;				    - Print file CP in CURRCP
;				    - Printer set to CURRCP
;
;  NOTE:	PRINT - PRINTER.SYS  2F Interface
;
;		(AX) =	AD40h	 - ADh is the function id
;				 - 40h is the sub-function id
;		(BX) =	n	 - change to this code page (binary value)
;				     and save current CP or any further
;				     change requested
;		       -1	 - restore saved CP and unlock
;		(DX)	m	 - LPTm #
;
;
;  REGISTERS USED:  T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	Called by FILEOF, CANFIL and ADDFIL
;
;  EXTERNAL	Calls to: My21
;   ROUTINES:
;
;  NORMAL	CF = 0
;  EXIT:
;
;  ERROR	CF = 1
;  EXIT:
;
;  CHANGE	03/11/87 - First release      - F. Gnuechtel
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START OpenFile
;
;	set up for INT 21 - 33 to see if CPSW is active
;	call MY_21
;	if CPSW is active and
;		set up for  INT 21 - 6C Extended Open
;		call MY_21 to open file
;	if no error and
;	if valid CP
;		if valid LPTx
;			update CURRCP
;			call INT 2F to lock and set PRINTER.SYS to CURRCP
;		endif
;	else
;		set up for INT 21 - 3D Open
;		call MY_21 to open file
;	endif
;	return
;
;	END OpenFile
;
;******************** END   - PSEUDOCODE ***************************************

OpenFile:

nop
;int 3
nop

   mov	bx,dx				; save pointer for later	       ;AN000;
   mov	ax,(Set_CTRL_C_Trapping shl 8) + GET_CPSW ; set up for INT 21 - 33     ;AN000;
					;	      to see if CPSW is active
   call My21				; call MY_21			       ;AN000;
   xchg dx,bx				; recover pointer		       ;AN000;
   cmp	bl,CPSW_on			; is CPSW active ?		       ;AN000;			;AN000;

;  if$	e				; if CPSW is active		       ;AC006;
   JNE IF83$$

       mov  ax,(ExtOpen shl 8) + 0	; set for INT 21-6C		       ;AN000;
       xor  cx,cx			;		   Extended Open       ;AN000;
       mov  bx,open_mode		;				       ;AN000;
       mov  si,dx			; set DS:SI to name		       ;AC006;
       mov  dx,(ignore_cp shl 8) + (failopen shl 4) + openit ; open if exists  ;AC001;
       mov  di,cx			;				       ;AC001;
       dec  di				;				       ;AC001;
       mov  al,[ds:si]			; recover drive - TO_DOS needs it
       call CodeR_:TO_DOS			; call TO_DOS to open file (SERVER DOS);AC010;

;      if$  nc,and			; if no error and		       ;AN000;
       JC IF84$$

       mov  bx,ax			;				       ;AN001;
       mov  ax,(File_Times SHL 8) + get_ea_by_handle ; now find out what CP    ;AN001;
       mov  cx,list_size		;				       ;AN001;
       lea  si,[query_list];				       ;AN001;
       lea  di,[list] ;				       ;AN001;
       call My21			; to get the CP 		       ;AN001;

;      if$  nc,and			; if no error and		       ;AN000;
       JC IF84$$

       mov  ax,bx			; move HANDLE back to where its needed ;AN001;

       mov  bx,[cs:code_page] ; is there a valid CP ? 	       ;AC006;

       cmp  bx,0			; is there a valid CP ? 	       ;AC006;

;      if$  g				; if valid CP ie: 0 < CP < -1	       ;AN000;
       JNG IF84$$

	   cmp	word [cs:PrinterNum],no_lptx ; is there a valid LPTx ?	       ;AN000;			;AN000;

;	   if$	ne			; if valid LPTx available	       ;AN000;
	   JE IF85$$

	       mov  cx,ax		; save file handle		       ;AN008;
	       mov  [cs:CURRCP],bx ; update CURRCP 		       ;AN000;
	       mov  dx,[cs:PrinterNum] ;				       ;AN000;
	       mov  ax,(major_code shl 8) + minor_code ; semophore PRINTER.SYS ;AN000;
	       int  2Fh 		; call INT 2F to lock and set	       ;AN000;
					;     PRINTER.SYS to CURRCP
	       mov  ax,cx		; restore file handle		       ;AN008;
;	   endif$			; endif 			       ;AN000;
IF85$$:
;      endif$				; endif 			       ;AN006;
IF84$$:

;  else$				; else				       ;AN000;
   JMP SHORT EN83$$
IF83$$:

       mov  si,dx
       mov  al,[ds:si]			; recover drive - TO_DOS needs it
       mov  ah,(Open)			; set up for INT 21 - 3D Open	       ;AN000;
       mov  cx,016h			; set up search attribute for Server   ;AN011;
					;			    DOS Open
       call CodeR_:TO_DOS			; call TO_DOS to open file (SERVER DOS);AC010;

;  endif$				; endif 			       ;AN000;
EN83$$:

   ret					; return			       ;AN000;

;   OpenFile ENDP

   BREAK <CloseFile>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	CloseFile    - PRINT Close a File for printing
;
;  FUNCTION:	This subroutine will mannage all environment changes required
;		for Code Page switching support. This is accomplished by:
;
;		       (see pseudocode)
;
;  INPUT:	(BX) = handle of file to close
;		(DS) = CodeR
;
;  OUTPUT:	File closed
;		CPSW active - PRINTER.SYS unlocked
;			    - CHECKCP is reset
;
;  REGISTERS USED:  T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:	Called by FILEOF, CANALL, CANFIL and ADDFIL
;
;  EXTERNAL	Calls to: My21
;   ROUTINES:
;
;  NORMAL	CF = 0
;  EXIT:
;
;  ERROR	CF = 1
;  EXIT:
;
;  CHANGE	03/11/87 - First release      - F. G
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START CloseFile
;
;	if CHECKCP != 0 then
;		call INT 2F to unlock PRINTER.SYS
;		reset CHECKCP
;	endif
;	set up for My21
;	call My21 to close file
;
;	return
;
;	END CloseFile
;
;******************** END   - PSEUDOCODE ***************************************

CloseFile:

   cmp	word [cs:CURRCP],0 ; is 0 < CHECKCP < -1 ? 	       ;AN000;

;  if$	g				; if CHECKCP is valid		       ;AN000;
   JNG IF90$$

       push bx				; save file handle		       ;AN000;
       xor  bx,bx			; set CP to unlock		       ;AN000;
       dec  bx				;				       ;AN000;
       mov  dx,[cs:PrinterNum] ; set which LPTx		       ;AN000;
       mov  ax,(major_code shl 8) + minor_code ; semophore to PRINTER.SYS      ;AN000;
       int  2Fh 			; call INT 2F to unlock PRINTER.SYS    ;AN000;
       mov  word [cs:CURRCP],0 ; reset CHECKCP 		       ;AN000;
       pop  bx				; recover file handle		       ;AN000;

;  endif$				; endif 			       ;AN000;
IF90$$:

   mov	ax,(Close shl 8)		; set up for INT 21 - close	       ;AN000;
   call My21				; call My21 to close file	       ;AC010;

   ret					; return			       ;AN000;

;   CloseFile ENDP

   BREAK <QUeue & buffer Space>

;			SALUT$ (4,25,30,41)

					;---------------------------------------
					;
					; NOTE: FileQueue is the actuall end of
					;	the RESIDENT PRINT code. The
					;	code that follows this is still
					;	initialization code - and is NOT
					;	left resident.
					;
					; --- File name Queue and data buffer
					;	follows here
					;
					;---------------------------------------

label FileQueue byte

			db   0		; the file queue starts empty


			BREAK <SETDEV>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	SETDEV
;
;  FUNCTION:
;
;  INPUT:	LISTNAME has the 8 char device name IN UPPER CASE
;
;  OUTPUT:
;
;  NOTE:
;
;  REGISTERS USED: Only DS preserved
;  (NOT RESTORED)
;
;  LINKAGE:	Called by: MoveTrans
;
;  NORMAL	CF = 0
;  EXIT:
;
;  ERROR	CF = 1 - Bad Device name
;  EXIT:
;
;  CHANGE	05/20/87 - Header added       - F. G
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START SETDEV
;
;	ret
;
;	END SETDEV
;
;******************** END   - PSEUDOCODE ***************************************

					;---------------------------------------
					; Reserved names for parallel card
					;---------------------------------------
label INT_17_HITLIST byte

			DB   8,"PRN     ",0
			DB   8,"LPT1    ",0
			DB   8,"LPT2    ",1
			DB   8,"LPT3    ",2
			DB   0

					;---------------------------------------
					; Reserved names for Async adaptor
					;---------------------------------------
label INT_14_HITLIST byte

			DB   8,"AUX     ",0
			DB   8,"COM1    ",0
			DB   8,"COM2    ",1
			DB   0
					;---------------------------------------
					; Default  Device Name
					;---------------------------------------

LISTNAME		DB   "PRN     " ;Device name

;  SALUT$ (4,4,9,41)

SETDEV:

;   ASSUME CS:CodeR,DS:CodeR,ES:nothing,SS:nothing


   mov	ah,Get_In_Vars
   call My21
   push es
   pop	ds
   lea	si,[es:bx+SysInitVars.SYSI_DEV]

;   ASSUME DS:nothing

   push cs
   pop	es

;   ASSUME ES:CodeR

   mov	di,LISTNAME

;  search$				;				       ;AN000;
DO92$$:

       test [si+SYSDEV.SDEVATT],DEVTYP ;

;      if$  nz,and			; if type is character		       ;AN000;
       JZ IF93$$

       push si				;
       push di				;
       add  si,SYSDEV.SDEVNAME 		; Point at name
       mov  cx,8			;
       repe cmpsb			;
       pop  di				;
       pop  si				;

;      if$  z				; if the end was reached with a match  ;AN000;
       JNZ IF93$$

	   stc				; signal end			       ;AN000;

;      else$
       JMP SHORT EN93$$
IF93$$:

	   clc				; keep looking

;      endif$				;				       ;AN000;
EN93$$:

;  exitif$ c				;				       ;AN000;
   JNC IF92$$

       mov  word [es:CALLAD+2],ds  ;Get I/O routines
       mov  word [es:LISTDEV+2],ds  ;Get I/O routines
       mov  word [es:LISTDEV],si
       push cs
       pop  ds

;       ASSUME DS:CodeR

       mov  word [PrinterNum],-1 ; Assume not an INT 17 device
       push cs
       pop  es

;       ASSUME ES:CodeR

       mov  bp,LISTNAME
       mov  si,bp
       mov  di,INT_17_HITLIST

       call chk_int17_dev

;  orelse$				;				       ;AN000;
   JMP SHORT SR92$$
IF92$$:

       lds  si,[si+SYSDEV.SDEVNEXT] ;
       cmp  si,-1			;

;  endloop$ z				;				       ;AN000;
   JNZ DO92$$

       push cs
       pop  ds
       stc

;  endsrch$				;				       ;AN000;
SR92$$:

   ret

;   SETDEV ENDP

   BREAK <chk_int17_dev>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	chk_int17_dev
;
;  FUNCTION:
;
;  INPUT:	(DS) = CodeR
;		(ES) = CodeR
;
;  OUTPUT:
;
;  NOTE:
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:
;
;  NORMAL
;  EXIT:
;
;  ERROR
;  EXIT:
;
;  CHANGE	05/20/87 - Header added       - F. G
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START chk_int17_dev
;
;	ret
;
;	END chk_int17_dev
;
;******************** END   - PSEUDOCODE ***************************************

chk_int17_dev:

;  search$				;				       ;AC000;
DO100$$:
       mov  si,bp
       mov  cl,[di]
       inc  di

;      if$  ncxz			;				       ;AC000;
       JCXZ IF101$$

	   clc				;				       ;AC000;

;      else$				;				       ;AC000;
       JMP SHORT EN101$$
IF101$$:

	   stc				;				       ;AC000;

;      endif$				;				       ;AC000;
EN101$$:

;  exitif$ c				;				       ;AC000;
   JNC IF100$$

       mov  di,INT_14_HITLIST

       call chk_int14_dev		;				       ;AC000;

;  orelse$				;				       ;AC000;
   JMP SHORT SR100$$
IF100$$:

       repe cmpsb
       lahf
       add  di,cx			;Bump to next position without affecting flags
       mov  bl,[di]			;Get device number
       inc  di
       sahf

;  endloop$ z				;				       ;AC000;
   JNZ DO100$$

       xor  bh,bh
       mov  [INT_17_NUM],bx
       mov  [PrinterNum],bx ; Set this as well to the INT 17 device
       mov  byte [FLAG17_14],1
       clc
					;
;  endsrch$				;				       ;AC000;
SR100$$:

   ret

;   chk_int17_dev ENDP

   BREAK <chk_int14_dev>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	chk_int14_dev
;
;  FUNCTION:
;
;  INPUT:	(DS) = CodeR
;		(ES) = CodeR
;
;  OUTPUT:
;
;  NOTE:
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:
;
;  NORMAL
;  EXIT:
;
;  ERROR
;  EXIT:
;
;  CHANGE	05/20/87 - Header added       - F. G
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START chk_int14_dev
;
;	ret
;
;	END chk_int14_dev
;
;******************** END   - PSEUDOCODE ***************************************

chk_int14_dev:

;  search$				;				       ;AC000;
DO108$$:

       mov  si,bp
       mov  cl,[di]
       inc  di

;      if$  ncxz			;				       ;AC000;
       JCXZ IF109$$

	   clc				;				       ;AC000;

;      else$				;				       ;AC000;
       JMP SHORT EN109$$
IF109$$:

	   stc				;				       ;AC000;

;      endif$				;				       ;AC000;
EN109$$:

;  exitif$ c				;				       ;AC000;
   JNC IF108$$

       mov  byte [FLAG17_14],0

;  orelse$				;				       ;AC000;
   JMP SHORT SR108$$
IF108$$:

       repe cmpsb
       lahf
       add  di,cx			;Bump to next position without affecting flags
       mov  bl,[di]			;Get device number
       inc  di
       sahf

;  endloop$ z				;				       ;AC000;
   JNZ DO108$$

       xor  bh,bh
       mov  [INT_14_NUM],bx
       mov  byte [FLAG17_14],2

;  endsrch$				;				       ;AC000;
SR108$$:

   clc					;				       ;AC015;

   ret

;   chk_int14_dev ENDP

   BREAK <BADSPOOL>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	BADSPOOL
;
;  FUNCTION:
;
;  INPUT:
;
;  OUTPUT:
;
;  NOTE:
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:
;
;  NORMAL
;  EXIT:
;
;  ERROR
;  EXIT:
;
;  CHANGE	05/20/87 - Header added       - F. G
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START BADSPOOL
;
;	ret
;
;	END BADSPOOL
;
;******************** END   - PSEUDOCODE ***************************************

BADSPOOL:

;   ASSUME CS:CodeR,DS:CodeR,ES:nothing,SS:nothing

   mov	ax,(CLASS_B shl 8) + BADMES	;				       ;AC000;
   call DG_:GoDispMsg			;				       ;AC002;
;*********************************************************************
   mov	ax,(Set_Printer_Flag SHL 8)	; Set flag to Idle
   int	21h
;*********************************************************************
   mov	ax,(Exit SHL 8) OR 0FFH
   int	21h

;   BADSPOOL ENDP

   BREAK <MoveTrans>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	MoveTrans
;
;  FUNCTION:	Move the transient out of the way of the Buffer space
;
;  INPUT:
;
;  OUTPUT:
;
;  NOTE:
;
;  REGISTERS USED: T.B.D.
;  (NOT RESTORED)
;
;  LINKAGE:
;
;  NORMAL
;  EXIT:
;
;  ERROR
;  EXIT:
;
;  CHANGE	05/20/87 - Header added       - F. G
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************** START - PSEUDOCODE ***************************************
;
;	START MoveTrans
;
;	ret
;
;	END MoveTrans
;
;******************** END   - PSEUDOCODE ***************************************

ContTrans rd      1 ; transient continuation address after move

MoveTrans:

;   ASSUME CS:CodeR,DS:CodeR,ES:CodeR,SS:nothing

   cli
   cld
   mov	[INTSEG],cs
   call SETDEV				;

;   ASSUME ES:nothing

   jc	BADSPOOL
   mov	dx,SPINT
   mov	al,SOFTINT
   mov	ah,Get_Interrupt_Vector
   int	21h				;Get soft vector
   mov	word [SPNEXT+2],es
   mov	word [SPNEXT],bx
   mov	al,SOFTINT
   mov	ah,Set_Interrupt_Vector
   int	21h				;Set soft vector
   mov	dx,SPCOMINT
   mov	al,ComInt
   mov	ah,Get_Interrupt_Vector
   int	21h				;Get communication vector
   mov	word [COMNEXT+2],es
   mov	word [COMNEXT],bx
   mov	al,ComInt
   mov	ah,Set_Interrupt_Vector 	;Set communication vector
   int	21h
   mov	al,13h
   mov	AH,Get_Interrupt_Vector
   int	21h
   mov	word [REAL_INT_13+2],es
   mov	word [REAL_INT_13],bx
   mov	DX,INT_13
   mov	al,13h
   mov	ah,Set_Interrupt_Vector
   int	21h				;Set diskI/O interrupt

   mov	al,15h
   mov	ah,Get_Interrupt_Vector
   int	21h
   mov	word [REAL_INT_15+2],es
   mov	word [REAL_INT_15],bx
   mov	dx,INT_15
   mov	al,15h
   mov	ah,Set_Interrupt_Vector
   int	21h				;Set INT 15 vector
   mov	al,17h
   mov	ah,Get_Interrupt_Vector
   int	21h
   mov	word [REAL_INT_17+2],es
   mov	word [REAL_INT_17],bx
   mov	dx,INT_17
   mov	al,17H
   mov	ah,Set_Interrupt_Vector
   int	21h				;Set printer interrupt
   mov	al,14h
   mov	ah,Get_Interrupt_Vector
   int	21h
   mov	word [REAL_INT_14+2],es
   mov	word [REAL_INT_14],bx
   mov	dx,INT_14
   mov	al,14h
   mov	ah,Set_Interrupt_Vector
   int	21h				;Set RS232 port interrupt
   mov	al,5
   mov	ah,Get_Interrupt_Vector
   int	21h
   mov	word [REAL_INT_5+2],es
   mov	word [REAL_INT_5],bx
   mov	DX,INT_5
   mov	al,5
   mov	ah,Set_Interrupt_Vector
   int	21h				;Set print screen interrupt
   mov	ah,Get_InDOS_Flag
   int	21h

;   ASSUME ES:nothing

   mov	word [INDOS+2],es      ;Get indos flag location
   mov	word [INDOS],bx
   mov	al,INTLOC
   mov	ah,Get_Interrupt_Vector
   int	21h
   mov	word [NEXTINT+2],es
   mov	word [NEXTINT],bx

   mov	al,REBOOT			; We also need to chain
   mov	ah,Get_Interrupt_Vector 	; Into the INT 19 sequence
   int	21h				; To properly "unhook"
   mov	word [NEXT_REBOOT+2],es     ; ourselves from the TimerTick
   mov	word [NEXT_REBOOT],bx     ; sequence
   mov	ax,0B800h
   int	2Fh
   cmp	al,0
   je	SET_HDSPINT			; No NETWORK, set hardware int
   test bx,0000000011000100B
   jnz	NO_HDSPINT			; DO NOT set HDSPINT if RCV|MSG|SRV

SET_HDSPINT:

   mov	dx,HDSPINT
   mov	al,INTLOC
   mov	ah,Set_Interrupt_Vector
   int	21h				;Set hardware interrupt

   mov	dx,ReBtINT
   mov	al,REBOOT
   mov	ah,Set_Interrupt_Vector
   int	21h				;Set bootstrap interrupt

NO_HDSPINT:

   mov	ax,(CLASS_B shl 8) + GOODMES	;				       ;AC000;
   call DG_:GoDispMsg			;				       ;AC002;

					;---------------------------------------
					;--- Move transient
					;      Note: do not use stack, it may
					;	     get trashed in move!
					;---------------------------------------

;   public RealMove

RealMove:

   mov	ax,TransRet
   mov	word [ContTrans],ax      ; store return offset
   mov	cx,DG_
   mov	word [ContTrans+2],cx     ; return segment
   mov	ax,CodeR_
   add	ax,[ENDRES]			; get start of moved transient, actually
					;  this is 100 bytes more than need be
					;  because of lack of pdb, but who cares?

					; NOTE: The following IF$ was added for
					;	 DOS 4.0.  For earlier versions,
					;	 the transient would even be moved
					;	 IN if required < available
					;	 - this would now clobber the
					;	    message code.

   cmp	ax,cx				; is required size > available size ?

;  if$	a				; if it is - move transient out
   JNA IF116$$

       mov  word [ContTrans+2],ax     ; return segment
       mov  es,ax			; new location for dg group

;       ASSUME ES:nothing

       mov  ax,DG_
       mov  ds,ax

;       ASSUME DS:nothing

       mov  cx,TransSize
       mov  si,cx			; start from the bottom and move up
       mov  di,cx
       std
       rep  movsb			; move all code, data and stack
       cld				; restore to expected setting...

					;---------------------------------------
					;--- normalize transient segment regs
					;---------------------------------------
       mov  ax,es
       mov  ds,ax
       sub  ax,DG_			; displacement
       mov  dx,ss
       add  dx,ax			; displace stack segemnt
       mov  ss,dx

;  endif$
IF116$$:

;   ASSUME DS:nothing,ES:nothing,SS:nothing

   jmp	[cs:ContTrans] ; back to the transient...

end if

;   End
