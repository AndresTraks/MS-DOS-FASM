 PAGE 80,132
;	SCCSID = @(#)command2.asm	4.3 85/10/16
;	SCCSID = @(#)command2.asm	4.3 85/10/16
TITLE	COMMAND2 - resident code for COMMAND.COM part II
;NAME	COMMAND2
.XCREF
.XLIST
	include 'DOSSYM.INC'
	include 'COMSW.ASM'
	include 'COMEQU.ASM'
	include 'RESMSG.EQU';AN000;
.LIST
.CREF

tokenized = FALSE

if SEGSEL = S_CODERES	;AC000;
end if

if SEGSEL = S_DATARES
;	EXTRN	append_state:word	;AN020;
;	EXTRN	append_flag:byte	;AN020;
;	EXTRN	COMDRV:BYTE
;	EXTRN	comprmt1_block:byte	;AN000;
;	EXTRN	comprmt1_subst:byte	;AN000;
;	EXTRN	COMSPEC:BYTE
;	EXTRN	cpdrv:byte
;	EXTRN	envirseg:word
;	EXTRN	EXTCOM:BYTE
;	EXTRN	HANDLE01:WORD
;	EXTRN	InitFlag:BYTE
;	EXTRN	INT_2E_RET:DWORD	;AC000;
;	EXTRN	IO_SAVE:WORD
;	EXTRN	LOADING:BYTE
;	EXTRN	LTPA:WORD
;	EXTRN	MEMSIZ:WORD
;	EXTRN	number_subst:byte	;AN000;
;	EXTRN	OldTerm:DWORD		;AC000;
;	EXTRN	PARENT:WORD		;AC000;
;	EXTRN	PERMCOM:BYTE
;	EXTRN	RDIRCHAR:BYTE
;	EXTRN	RES_TPA:WORD
;	EXTRN	RETCODE:WORD
;	EXTRN	rsrc_xa_seg:word	;AN030;
;	EXTRN	RSWITCHAR:BYTE
;	EXTRN	SAVE_PDB:WORD
;	EXTRN	SINGLECOM:WORD
;	EXTRN	SUM:WORD
;	EXTRN	TRANS:WORD
;	EXTRN	TranVarEnd:BYTE
;	EXTRN	TRANVARS:BYTE
;	EXTRN	TRNSEG:WORD
;	EXTRN	VERVAL:WORD
end if

if SEGSEL = S_BATARENA	;AC000;
end if

if SEGSEL = S_BATSEG	;AC000;
end if

if SEGSEL = S_ENVARENA	;AC000;
end if

if SEGSEL = S_ENVIRONMENT	; Default COMMAND environment
end if

if SEGSEL = S_INIT
;	EXTRN	envsiz:word
;	EXTRN	oldenv:word
;	EXTRN	resetenv:byte
;	EXTRN	usedenv:word
end if

if SEGSEL = S_TAIL
end if

if SEGSEL = S_TRANCODE
end if

if SEGSEL = S_TRANDATA
;	EXTRN	TRANDATAEND:BYTE
end if

if SEGSEL = S_TRANSPACE
;	EXTRN	TRANSPACEEND:BYTE
;	EXTRN	HEADCALL:DWORD
end if

if SEGSEL = S_TRANTAIL
end if

;RESGROUP  GROUP CODERES,DATARES,BATARENA,BATSEG,ENVARENA,ENVIRONMENT,INIT,TAIL
;TRANGROUP GROUP TRANCODE,TRANDATA,TRANSPACE,TRANTAIL

; START OF RESIDENT PORTION

if SEGSEL = S_CODERES	;AC000;

;	PUBLIC	CHKSUM
;	PUBLIC	endinit
;	PUBLIC	GETCOMDSK2
;	PUBLIC	INT_2E
;	PUBLIC	LOADCOM
;	PUBLIC	LODCOM
;	PUBLIC	LODCOM1
;	PUBLIC	RESTHAND
;	PUBLIC	SAVHAND
;	PUBLIC	SETVECT
;	PUBLIC	THEADFIX
;	PUBLIC	TREMCHECK
;	PUBLIC	tjmp

;ASSUME	CS:RESGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;	EXTRN	contc:near
;	EXTRN	DSKERR:NEAR
;	EXTRN	rstack:word
;
; If we cannot allocate enough memory for the transient or there was some
; other allocation error, we display a message and then die.
;
BADMEMERR:				; Allocation error loading transient
	MOV	DX,[BMEMMES]       ;AC000; get message number
FATALC:
	PUSH	CS
	POP	DS
;	ASSUME	DS:ResGroup
	invoke	RPRINT
;
; If this is NOT a permanent (top-level) COMMAND, then we exit; we can't do
; anything else!
;
	CMP	byte [PERMCOM],0
	JZ	FATALRET
;
; We are a permanent command.  If we are in the process of the magic interrupt
; (Singlecom) then exit too.
;
	CMP	word [SINGLECOM],0 ; If PERMCOM and SINGLECOM
	JNZ	FATALRET		; Must take INT_2E exit
;
; Permanent command.  We can't do ANYthing except halt.
;
	MOV	DX,[HALTMES]       ;AC000; get message number
	invoke	RPRINT
	STI
STALL:
	JMP	STALL			; Crash the system nicely

FATALRET:
	MOV	DX,[FRETMES]       ;AC000; get message number
	invoke	RPRINT
FATALRET2:
	CMP	byte [PERMCOM],0   ; If we get here and PERMCOM,
	JNZ	RET_2E			; must be INT_2E
	invoke	reset_msg_pointers	;AN000; reset critical & parse error messages
	MOV	AX,[PARENT]
	MOV	word [cs:PDB_Parent_PID],AX
	MOV	AX,word [OldTerm]
	MOV	word [cs:PDB_Exit],AX
	MOV	AX,word [OldTerm+2]
	MOV	word [cs:PDB_Exit+2],AX
	MOV	AX,(Exit SHL 8) 	; Return to lower level
	INT	int_command

RET_2E:
	PUSH	CS
	POP	DS
;ASSUME	DS:RESGROUP,ES:NOTHING,SS:NOTHING
	MOV	word [SINGLECOM],0 ; Turn off singlecom
	MOV	ES,[RES_TPA]
	MOV	AH,Dealloc
	INT	int_command		; Free up space used by transient
	MOV	BX,[SAVE_PDB]
	MOV	AH,Set_Current_PDB
	INT	int_command		; Current process is user
	MOV	AX,[RETCODE]
	CMP	byte [EXTCOM],0
	JNZ	GOTECODE
	XOR	AX,AX			; Internals always return 0
GOTECODE:
	MOV	byte [EXTCOM],1    ; Force external
	JMP	[INT_2E_RET]		;"IRET"

INT_2E: 				; Magic command executer
;ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	POP	word [INT_2E_RET]
	POP	word [INT_2E_RET+2]     ;Get return address
	POP	AX			;Chuck flags
	PUSH	CS
	POP	ES
	MOV	DI,80H
	MOV	CX,64
	REP	MOVSW
	MOV	AH,Get_Current_PDB
	INT	int_command		; Get user's header
	MOV	[SAVE_PDB],BX
	MOV	AH,Set_Current_PDB
	MOV	BX,CS
	INT	int_command		; Current process is me
	MOV	word [SINGLECOM],81H
	MOV	byte [EXTCOM],1    ; Make sure this case forced

LODCOM: 				; Termination handler
	CMP	byte [EXTCOM],0
	jz	LODCOM1 		; if internal, memory already allocated
	mov	bx,0ffffh
	MOV	AH,Alloc
	INT	int_command
	CALL	SetSize
	ADD	AX,20H
	CMP	BX,AX			; Is less than 512 byte buffer worth it?
	JNC	MEMOK
BADMEMERRJ:
	JMP BADMEMERR			; Not enough memory

; SetSize - get transient size in paragraphs
procedure   SetSize,NEAR
	MOV	AX,TRANSPACEEND + 15
	MOV	CL,4
	SHR	AX,CL
	return
EndProc SetSize

MEMOK:
	MOV	AH,Alloc
	INT	int_command
	JC	BADMEMERRJ		; Memory arenas probably trashed
	MOV	byte [EXTCOM],0    ; Flag not to ALLOC again
	MOV	[RES_TPA], AX		; Save current TPA segment
	AND	AX, 0F000H
	ADD	AX, 01000H		; Round up to next 64K boundary
	JC	BAD_TPA 		; Memory wrap if carry set
; Make sure that new boundary is within allocated range
	MOV	DX, [RES_TPA]
	ADD	DX, BX			; Compute maximum address
	CMP	DX, AX			; Is 64K address out of range?
	JBE	BAD_TPA
; Must have 64K of usable space.
	SUB	DX, AX			; Compute the usable space
	CMP	DX, 01000H		; Is space >= 64K ?
	JAE	LTPASET
BAD_TPA:
	MOV	AX, [RES_TPA]
LTPASET:
	MOV	[LTPA],AX		; Usable TPA is 64k buffer aligned
	MOV	AX, [RES_TPA]		; Actual TPA is buffer allocated
	ADD	BX,AX
	MOV	[MEMSIZ],BX
	CALL	SetSize
	SUB	BX,AX
	MOV	[TRNSEG],BX		; Transient starts here
LODCOM1:
	MOV	AX,CS
	MOV	SS,AX
;ASSUME	SS:RESGROUP
	MOV	SP,RSTACK
	MOV	DS,AX
;ASSUME	DS:RESGROUP
	CALL	HEADFIX 		; Make sure files closed stdin and stdout restored
	XOR	BP,BP			; Flag command ok
	MOV	AX,-1
	XCHG	AX,[VERVAL]
	CMP	AX,-1
	JZ	NOSETVER
	MOV	AH,Set_Verify_On_Write	; AL has correct value
	INT	int_command
NOSETVER:
	CMP	word [SINGLECOM],-1
	JNZ	NOSNG
	JMP	FATALRET2		; We have finished the single command
NOSNG:
	CALL	CHKSUM			; Check the transient
	CMP	DX,[SUM]
	JZ	HAVCOM			; Transient OK
BOGUS_COM:
	MOV	byte [LOADING],1   ; Flag DSKERR routine
	CALL	LOADCOM
CHKSAME:

	CALL	CHKSUM
	CMP	DX,[SUM]
	JZ	HAVCOM			; Same COMMAND
ALSO_BOGUS:
	CALL	WRONGCOM
	jmp     CHKSAME
HAVCOM:
	MOV	AX,Char_Oper SHL 8
	INT	int_command
	MOV	[RSWITCHAR],DL
	CMP	DL,'/'
	JNZ	USESLASH
	mov	cl,'\'
	MOV	[RDIRCHAR],cl		; Select alt path separator
USESLASH:
	MOV	byte [LOADING],0   ; Flag to DSKERR
	MOV	SI,TRANVARS
	MOV	DI,HEADCALL
	MOV	ES,[TRNSEG]
	CLD
	MOV	CX,TranVarEnd
	SUB	CX,SI
	REP	MOVSB			; Transfer INFO to transient
	MOV	AX,[MEMSIZ]
	MOV	word [ds:PDB_block_len],AX     ; Adjust my own header

; Just a public label so this spot can be found easily.
tjmp:
	JMP	dword [TRANS]

; Far call to REMCHECK for TRANSIENT
TREMCHECK:
	CALL	REMCHECK
	RET
;TREMCHECK ENDP

REMCHECK:
;All registers preserved. Returns ZF set if media removable, NZ if fixed
; AL is drive (0=DEF, 1=A,...).
	SaveReg <AX,BX>
	MOV	BX,AX
	MOV	AX,(IOCtl SHL 8) + 8
	INT	21h
	jnc	RCcont			; If an error occurred, assume the media
	or	ax,ax			;  is NON-removable.
					;  AX contains the non-zero error code
					;  from the INT 21, so the OR AX,AX sets
					;  Non-zero. This behavior makes Network
					;  drives appear to be non-removable.
	jmp     ResRegs
RCcont:
	AND	AX,1
	NOT	AX
ResRegs:
	RestoreReg  <BX,AX>
	return

; Far call to HEADFIX for TRANSIENT
THEADFIX:
	CALL	HEADFIX
	RET
;THEADFIX ENDP

HEADFIX:
	CALL	SETVECT
	XOR	BX,BX			; Clean up header
	MOV	CX,[IO_SAVE]
	MOV	DX,word [ds:PDB_JFN_Table]
	CMP	CL,DL
	JZ	CHK1			; Stdin matches
	MOV	AH,Close
	INT	int_command
	MOV	[ds:PDB_JFN_Table],CL	; Restore stdin
CHK1:
	INC	BX
	CMP	CH,DH			; Stdout matches
	JZ	CHKOTHERHAND
	MOV	AH,Close
	INT	int_command
	MOV	[ds:PDB_JFN_Table+1],CH ; Restore stdout
CHKOTHERHAND:
	ADD	BX,4			; Skip 2,3,4
	MOV	CX,FilPerProc - 5	; Already done 0,1,2,3,4
CLOSELOOP:
	MOV	AH,Close
	INT	int_command
	INC	BX
	LOOP	CLOSELOOP
	push	ds			;AN020; save data segment
	push	cs			;AN020; Get local segment into DS
	pop	ds			;AN020;
	cmp	byte [APPEND_FLAG],-1      ;AN020; Do we need to reset APPEND?
	jnz	append_fix_end		;AN030; no - just exit
	mov	ax,AppendSetState	;AN020; Set the state of Append
	mov	bx,[APPEND_STATE]  ;AN020;     back to the original state
	int	2fh			;AN020;
	mov	byte [APPEND_FLAG],0       ;AN020; Set append flag to invalid
append_fix_end: 			;AN030;
	cmp	word [rsrc_xa_seg],no_xa_seg       ;AN030; Is there any active XA segment?
	jz	xa_fix_end		;AN030; no - exit
	push	es			;AN030; Yes - deallocate it
	mov	es,[rsrc_xa_seg]   ;AN030;
	mov	ax,(Dealloc SHL 8)	;AN030; Deallocate memory call
	int	int_command		;AN030;
	pop	es			;AN030;
	mov	word [rsrc_xa_seg],no_xa_seg       ;AN030; reset to no segment
xa_fix_end:
	pop	ds			;AN020; get data segment back
	return

SAVHAND:
;ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
	PUSH	DS
	PUSH	BX			; Set stdin to sterr, stdout to stderr
	PUSH	AX
	MOV	AH,Get_Current_PDB
	INT	int_command		; Get user's header
	MOV	DS,BX
	LDS	BX,dword [ds:PDB_JFN_Pointer]      ; get pointer to JFN table...
	MOV	AX,word [ds:BX]
	MOV	[HANDLE01],AX		; Save user's stdin, stdout
	MOV	AL,[cs:PDB_JFN_Table+2] ; get COMMAND stderr
	MOV	AH,AL
	MOV	word [ds:BX],AX     ; Dup stderr
	POP	AX
	POP	BX
	POP	DS
	return

;ASSUME	DS:RESGROUP
GETCOMDSK2:
	CALL	GETCOMDSK
	JMP	LODCOM1 		; Memory already allocated

RESTHAND:
	PUSH	DS
	PUSH	BX			; Restore stdin, stdout to user
	PUSH	AX
	MOV	AH,Get_Current_PDB
	INT	int_command		; Point to user's header
	MOV	AX,[HANDLE01]
	MOV	DS,BX
;ASSUME DS:NOTHING
	LDS	BX,dword [ds:PDB_JFN_Pointer]      ; get pointer to JFN table...
	MOV	word [ds:BX],AX     ; Stuff his old 0 and 1
	POP	AX
	POP	BX
	POP	DS
	return
;ASSUME DS:RESGROUP,SS:RESGROUP

HOPELESS:
	MOV	DX,[COMBAD]        ;AC000;
	JMP	FATALC

GETCOMDSK:
	mov	al,[COMDRV]
	CALL	REMCHECK
	jNZ	HOPELESS		;Non-removable media
getcomdsk3:
	cmp	dx,[COMBAD]        ;AC000;
	jnz	getcomdsk4
	mov	dx,[COMBAD]        ;AN000; get message number
	invoke	RPRINT			; Say command is invalid
getcomdsk4:
	cmp	byte [cpdrv],0     ;g is there a drive in the comspec?
	jnz	users_drive		;g yes - use it
	mov	ah,Get_Default_Drive	;g use default drive
	int	21h			;g
	add	al,"A"                  ;g convert to ascii
	mov	[cpdrv],al		;g put in message to print out

users_drive:				;g
	mov	dx,[comprmt1]      ;AC000; Prompt for diskette containing command
IF tokenized
	or	byte [si],80h
end if
	MOV	AL,[COMPRMT1_SUBST]        ;AN000; get number of substitutions
	MOV	SI,COMPRMT1_BLOCK                 ;AN000; get address of subst block
	MOV	[NUMBER_SUBST],AL  ;AN000;
	invoke	RPRINT
if tokenized
	and	byte [si],NOT 80h
end if
	mov	dx,[PROMPT]        ;AN047; Tell the user to strike a key
	invoke	RPRINT			;AN047;
	CALL	GetRawFlushedByte
	return

; flush world and get raw input
GetRawFlushedByte:
	MOV	AX,(Std_Con_Input_Flush SHL 8) OR Raw_Con_Input
	INT	int_command		; Get char without testing or echo
	MOV	AX,(Std_Con_Input_Flush SHL 8) + 0
	INT	int_command
	return

LOADCOM:				; Load in transient
	INC	BP			; Flag command read
	MOV	DX,COMSPEC
	MOV	AX,Open SHL 8
	INT	int_command		; Open COMMAND.COM
	JNC	READCOM
	CMP	AX,error_too_many_open_files
	JNZ	TRYDOOPEN
	MOV	DX,[NOHANDMES]     ;AC000;
	JMP	FATALC			; Fatal, will never find a handle

TRYDOOPEN:
	CALL	GETCOMDSK
	JMP	LOADCOM

READCOM:
	MOV	BX,AX			; Handle
	MOV	DX,TRANSTART
	XOR	CX,CX			; Seek loc
	MOV	AX,LSeek SHL 8
	INT	int_command
	JC	WRONGCOM1
	MOV	CX,TRANSPACEEND - 100H

	PUSH	DS
	MOV	DS,[TRNSEG]
;ASSUME	DS:NOTHING
	MOV	DX,100H
	MOV	AH,Read
	INT	int_command
	POP	DS
;ASSUME	DS:RESGROUP
WRONGCOM1:
	PUSHF
	PUSH	AX
	MOV	AH,Close
	INT	int_command		; Close COMMAND.COM
	POP	AX
	POPF
	JC	WRONGCOM		; If error on READ
	CMP	AX,CX
	retz				; Size matched
WRONGCOM:
	MOV	DX,[COMBAD]        ;AC000;
	CALL	GETCOMDSK
	JMP	LOADCOM 		; Try again

CHKSUM: 				; Compute transient checksum
	PUSH	DS
	MOV	DS,[TRNSEG]
	MOV	SI,100H
	MOV	CX,TRANDATAEND  - 100H

CHECK_SUM:
	CLD
	SHR	CX,1
	XOR	DX,DX
CHK:
	LODSW
	ADD	DX,AX
	ADC	DX,0
	LOOP	CHK
	POP	DS
	return

SETVECT:				; Set useful vectors
	MOV	DX,LODCOM
	MOV	AX,(Set_Interrupt_Vector SHL 8) OR 22H
	MOV	word [ds:PDB_Exit],DX
	MOV	word [ds:PDB_Exit+2],DS
	INT	int_command
	MOV	DX,CONTC
	INC	AL
	INT	int_command
	MOV	DX,DSKERR
	INC	AL
	INT	int_command
	return


;
;  This routine moves the environment to a newly allocated segment
;  at the end of initialization
;

ENDINIT:
	push	ds			;g save segments
	push	es			;g
	push	cs			;g get resident segment to DS
	pop	ds			;g
;	ASSUME	DS:RESGROUP
	mov	cx,[usedenv]       ;g get number of bytes to move
	mov	es,[ENVIRSEG]      ;g get target environment segment

;	ASSUME	ES:NOTHING
	mov	[ds:PDB_environ],es	;g put new environment in my header	   ;AM067;
	mov	ds,[oldenv]        ;g source environment segment		   ;AM067;
;	ASSUME	DS:NOTHING							   ;AM067;
	xor	si,si			;g set up offsets to start of segments	   ;AM067;
	xor	di,di			;g					   ;AM067;
	cld				;g make sure we move the right way!	   ;AM067;
	rep	movsb			;g move it				   ;AM067;
	xor	ax,ax			;g					   ;AM067;
	stosb				;g make sure there are double 0 at end	   ;AM067;

	cmp	byte [resetenv],1  ;eg Do we need to setblock to env end?
	jnz	NoReset_COMMAND2 		;eg no - we already did it
	mov	bx,[EnvSiz]        ;eg get size of environment in paragraphs
	push	es			;eg save environment - just to make sure
	mov	ah,Setblock		;eg
	int	int_command		;eg
	pop	es			;eg

NoReset_COMMAND2:
	mov	byte [InitFlag],FALSE      ;AC042; Turn off init flag
	pop	es			;g
	pop	ds			;g
	jmp	LODCOM			;g allocate transient

end if

; This TAIL segment is used to produce a PARA aligned label in the resident
; group which is the location where the transient segments will be loaded
; initial.

if SEGSEL = S_TAIL
;	ORG	0	; the flat layout is already here
;	PUBLIC	TranStart
label TRANSTART word
end if

; This TAIL segment is used to produce a PARA aligned label in the transient
; group which is the location where the exec segments will be loaded
; initial.

if SEGSEL = S_TRANTAIL
;	ORG	0	; the flat layout is already here
label EXECSTART word
end if

;	END
