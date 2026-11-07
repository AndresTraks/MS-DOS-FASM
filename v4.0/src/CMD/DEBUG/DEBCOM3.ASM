STRUC INTERRUPT_FRAME OLDBP_=0, OLDIP_=0, OLDCS_=0, OLDF_=0, OLDERIP_=0, OLDERCS_=0, OLDERF_=0
{
.OLDBP	DW	OLDBP_
.OLDIP	DW	OLDIP_
.OLDCS	DW	OLDCS_
.OLDF	DW	OLDF_
.OLDERIP DW	OLDERIP_
.OLDERCS DW	OLDERCS_
.OLDERF	DW	OLDERF_
}
match =INTERRUPT_FRAME_LAID_OUT, INTERRUPT_FRAME_LAID_OUT
{
    INTERRUPT_FRAME_LAID_OUT equ 1
    virtual at 0
      INTERRUPT_FRAME INTERRUPT_FRAME
      sizeof.INTERRUPT_FRAME = $ - INTERRUPT_FRAME
    end virtual
}
	PAGE	80,132 ;
	TITLE	DEBCOM3.ASM - PART3 DEBUGGER COMMANDS
; ROUTINES TO PERFORM DEBUGGER COMMANDS

;	IF1
;	    %OUT COMPONENT=DEBUG, MODULE=DEBCOM3
;	ENDIF
.XLIST
.XCREF
	include 'DOSSYM.INC'
	include 'DEBEQU.ASM'
	include 'DPL.ASM'
.CREF
.LIST
if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
;	EXTRN	USER_PROC_PDB:WORD,RSTACK:WORD,STACK_:BYTE
;	EXTRN	DSSAVE:WORD,CSSAVE:WORD,IPSAVE:WORD,axSAVE:WORD,dxSAVE:WORD
;	EXTRN	SSSAVE:WORD,SPSAVE:WORD,FLSAVE:WORD
;	EXTRN	NEXTCS:WORD,NEXTIP:WORD, RSETFLAG:BYTE
end if

if SEGSEL = S_CSTACK
end if

if SEGSEL = S_DATA
;	EXTRN	BRKCNT:WORD,TCOUNT:WORD,SWITCHAR:BYTE,BPTAB:BYTE
;	EXTRN	BP_ERROR:BYTE,COMP_ARG1:WORD,COMP_ARG2:WORD,COMP_ARG3:WORD
;	EXTRN	COMP_ARG4:WORD,COMP_ARG5:WORD,COMP_ARG6:WORD,COMP_PTR:BYTE
;	EXTRN	ARG_BUF:BYTE,ARG_BUF_PTR:BYTE
;	EXTRN	FZTRACE:BYTE, SYNERR_PTR:BYTE
;	EXTRN	BEGSEG:WORD
	IF	IBMVER
;	    EXTRN   OLD_MASK:BYTE
	end if
;	EXTRN	SAVESTATE:BYTE
end if

;DG	GROUP	CODE,CONST,CSTACK,DATA

if SEGSEL = S_CODE
;ASSUME	CS:DG,DS:DG,ES:DG,SS:DG
;	PUBLIC	COMPARE,INPUT,OUTPUT,GO
;	PUBLIC	TRACE,ZTRACE,SKIP_FILE
;	EXTRN	GETHEX:NEAR,GETEOL:NEAR,CRLF:NEAR,ERR_:NEAR, PERR:NEAR
;	EXTRN	HEX:NEAR,DIGIT:NEAR,SCANP:NEAR,DISPREG:NEAR
;	EXTRN	COMMAND:NEAR,DABORT:NEAR,DELIM1:NEAR,DELIM2:NEAR
;	EXTRN	NMIINT:NEAR,NMIINTEND:NEAR,PRINTF_CRLF:NEAR
;	EXTRN	ADDRESS:NEAR,HEXIN:NEAR,DSRANGE:NEAR
; just like trace except skips OVER next INT or CALL.
DEBCOM3:
ZTRACE:
	MOV	byte [FZTRACE],-1
	CALL	SETADD
	CALL	SCANP
	CALL	HEXIN
	MOV	DX,1
	JC	ZSTOCNT
	MOV	CX,4
	CALL	GETHEX
	CALL	CHECKNONE
ZSTOCNT:
	MOV	[TCOUNT],DX
	CALL	GETEOL
	MOV	DX,[NextCS]
	MOV	[CSSAVE],DX
	MOV	DX,[NextIP]
	MOV	[IPSAVE],DX
ZSTEP:
	MOV	ES,[CSSAVE]		; point to instruction to execute
	MOV	DI,[IPSAVE]		; include offset in segment
	XOR	DX,DX			; where to place breakpoint
get_opcode:
	MOV	AL,[es:DI]		; get the opcode
	cmp	al,0f0h 		; lock
	je	Is_override
	cmp	al,26h			; es:
	je	Is_override
	cmp	al,2eh			; cs:
	je	Is_override
	cmp	al,36h			; ss:
	je	Is_override
	cmp	al,3eh			; ds:
	jne	Not_override
Is_override:
;	inc	dx			; this seemed to put us in an endless
	inc	di			; loop, try this.
	jmp	get_opcode
Not_override:
	CMP	AL,11101000B		; direct intra call
	JZ	ZTRACE3 		; yes, 3 bytes
	CMP	AL,10011010B		; direct inter call
	JZ	ZTRACE5 		; yes, 5 bytes
	CMP	AL,11111111B		; indirect?
	JZ	ZTRACEMODRM		; yes, go figure length
	CMP	AL,11001100B		; short interrupt?
	JZ	ZTRACE1 		; yes, 1 byte
	CMP	AL,11001101B		; long interrupt?
	JZ	ZTRACE2 		; yes, 2 bytes
	CMP	AL,11100010B		; loop
	JZ	ZTRACE2 		; 2 byter
	CMP	AL,11100001B		; loopz/loope
	JZ	ZTRACE2 		; 2 byter
	CMP	AL,11100000B		; loopnz/loopne
	JZ	ZTRACE2 		; 2 byter
	AND	AL,11111110B		; check for rep
	CMP	AL,11110010B		; perhaps?
	JZ	FOO1
	JMP	STEP			; can't do anything special, step
FOO1:
	MOV	AL,[es:DI+1]		; next instruction
	AND	AL,11111110B		; ignore w bit
	CMP	AL,10100100B		; MOVS
	JZ	ZTRACE2 		; two byte
	CMP	AL,10100110B		; CMPS
	JZ	ZTRACE2 		; two byte
	CMP	AL,10101110B		; SCAS
	JZ	ZTRACE2 		; two byte
	CMP	AL,10101100B		; LODS
	JZ	ZTRACE2 		; two byte
	CMP	AL,10101010B		; STOS
	JZ	ZTRACE2 		; two byte
	JMP	STEP			; bogus, do single step

ZTRACEMODRM:
	MOV	AL,[es:DI+1]		; get next byte
	AND	AL,11111000B		; get mod and type
	CMP	AL,01010000B		; indirect intra 8 bit offset?
	JZ	ZTRACE3 		; yes, three byte whammy
	CMP	AL,01011000B		; indirect inter 8 bit offset
	JZ	ZTRACE3 		; yes, three byte guy
	CMP	AL,10010000B		; indirect intra 16 bit offset?
	JZ	ZTRACE4 		; four byte offset
	CMP	AL,10011000B		; indirect inter 16 bit offset?
	JZ	ZTRACE4 		; four bytes
	CMP	AL,11010000B		; indirect through reg?
	JZ	ZTRACE2 		; two byte instruction
	JMP	STEP			; can't figger out what this is!
ZTRACE5:
	INC	DX
ZTRACE4:
	INC	DX
ZTRACE3:
	INC	DX
ZTRACE2:
	INC	DX
ZTRACE1:
	INC	DX
	ADD	DI,DX			; offset to breakpoint instruction
	MOV	word [BPTAB],DI     ; save offset
	MOV	word [BPTAB+2],ES     ; save segment
	MOV	AL,[es:DI]		; get next opcode byte
	MOV	byte [BPTAB+4],AL     ; save it
	MOV	byte [es:DI],0CCH     ; break point it
	MOV	word [BRKCNT],1 ; only this breakpoint
	JMP	DEXIT			; start the operation!

; Trace 1 instruction or the number of instruction specified
; by the parameter using 8086 trace mode. Registers are all
; set according to values in save area
TRACE:
	MOV	byte [FZTRACE],0
	CALL	SETADD
	CALL	SCANP
	CALL	HEXIN
	MOV	DX,1
	JC	STOCNT
	MOV	CX,4
	CALL	GETHEX
	CALL	CHECKNONE
STOCNT:
	MOV	[TCOUNT],DX
	CALL	GETEOL
	MOV	DX,[NextCS]
	MOV	[CSSAVE],DX
	MOV	DX,[NextIP]
	MOV	[IPSAVE],DX
STEP:
	MOV	word [BRKCNT],0
; The 286 has a problem with trace mode and software interrupt instructions;
; it treats them as atomic operations.	We simulate the operation in software.
	MOV	ES,[CSSAVE]		; Get next instruction pointer
	MOV	DI,[IPSAVE]
	MOV	AL,[es:DI]		; get next opcode
	cmp	al,0e4h 		; check for 'IN' opcode
	jne	not_inal_op
	cmp	byte [es:di+1],21h
	jne	not_mask_op
	add	word [IPSAVE],2
	JMP	SETalmask

not_inal_op:
	cmp	al,0ech 		; in al,DX ?
	jne	not_mask_op
	cmp	word [DXSAVE],21h
	jne	not_mask_op
	add	word [IPSAVE],1
SETalmask:
	mov	ax,[AXSAVE]
	in	al,21h
	mov	[AXSAVE],ax
	JMP	SETENVIRON

not_mask_op:
	CMP	AL,0CDH 		; trace over an interrupt?
	JZ	DOINT			; no, check for other special cases
	CMP	AL,0CEH 		; how about int overflow
	JNZ	CHECKCC
	TEST	word [FLSAVE],f_Overflow ; see it overflow is present
	JZ	CHECKOP
	MOV	BX,4			; INTO = INT 4
	DEC	word [IPSAVE] ; INTO is a singel byte
	JMP	SHORT DOVAL
CHECKCC:
	CMP	AL,0CCH
	JNZ	CHECKOP
	MOV	BX,3			; INT 3 = CC
	DEC	word [IPSAVE]
	JMP	SHORT DOVAL
DOINT:
; We have a software interrupt.  Get destination vector
	MOV	BL,byte [es:DI+1]     ; get vector number
	XOR	BH,BH			; clear out upper
DOVAL:
	SHL	BX,1			; word index
	SHL	BX,1			; dword index
	XOR	DI,DI			; interrupt table
	MOV	ES,DI
	MOV	AX,[es:BX]		; point to vector
	MOV	BX,[es:BX+2]		; point to vector
; AX:BX is the vector.	Swap it with currect CS:IP
	XCHG	AX,[IPSAVE] ; new CS:IP
	XCHG	BX,[CSSAVE]
; AX:BX is old CS:IP.  We 'PUSH' flags, oldCS and oldIP, reset flags (ifl) and
; set CS:IP to point to interrupt instruction.
	MOV	ES,[SSSAVE] ; point to user stack
	MOV	DI,[SPSAVE]
; Take old flags and PUSH the flags.
	MOV	CX,[FLSAVE] ; get flags
	SUB	DI,2			; PUSHF
	MOV	[es:DI],CX		; rest of push
; Push the old CS
	SUB	DI,2			; PUSH CS
	MOV	[es:DI],BX		; rest of push
; Push the old IP
	SUB	DI,2			; PUSH IP
	ADD	AX,2			; increment IP
	MOV	[es:DI],AX		; rest of push
; Update stack
	MOV	[SPSAVE],DI ; store
; Take flags and turn interrupts off and trace mode off
	AND	CX,NOT f_Interrupt	; CLI
	AND	CX,NOT f_Trace		; no trace
	MOV	[FLSAVE],CX ; rest of CLI
; Set up correct process and go to normal reentry code.
	IF	NOT SYSVER
	    MOV     BX,[USER_PROC_PDB]
	    MOV     AH,Set_Current_PDB
	    INT     21H
	end if
	JMP	SETENVIRON
; We need to special case the following instructions that may push a TRACE bit
; on the stack:  PUSHF (9C)

; Save the opcode in A Special place
CHECKOP:
	MOV	[RSETFLAG],AL ; no bits to turn off
SETTRACE:
	OR	word [FLSAVE],f_Trace ; Turn on trace bit
	IF	IBMVER
	    CLI
	    IN	    AL,MASK_PORT	; Get current mask
	    JMP     SHORT FOO
FOO:
	    MOV     [OLD_MASK],AL	; Save it
	    MOV     AL,INT_MASK 	; New mask
	    OUT     MASK_PORT,AL	; Set it
	    STI
	end if
DEXIT:
	IF	NOT SYSVER
	    MOV     BX,[USER_PROC_PDB]
	    MOV     AH,Set_Current_PDB
	    INT     21H
	end if
; Unfortunately, any system call we issue will muck with the current extended
; errors.  Here we must restore the extended error state so that if the user
; program gets it, we do not interfere.
	MOV	AX,(ServerCall SHL 8) + 10
	MOV	DX,SAVESTATE
	INT	21H
	PUSH	DS
	XOR	AX,AX
	MOV	DS,AX
	MOV	word [ds:12],BREAKFIX            ; Set vector 3--breakpoint instruction
	MOV	word [ds:14],CS
	MOV	word [ds:4],REENTER            ; Set vector 1--Single step
	MOV	word [ds:6],CS
	CLI
	IF	SETCNTC
	    MOV     word [ds:8CH],CONTC            ; Set vector 23H (CTRL-C)
	    MOV     word [ds:8EH],CS
	end if
	POP	DS
	MOV	SP,STACK_
	POP	AX
	POP	BX
	POP	CX
	POP	DX
	POP	BP
	POP	BP
	POP	SI
	POP	DI
	POP	ES
	POP	ES
	POP	SS
	MOV	SP,[SPSAVE]
	PUSH	word [FLSAVE]
	PUSH	word [CSSAVE]
	PUSH	word [IPSAVE]
	MOV	DS,[DSSAVE]
	IRET
STEP1:
	CALL	CRLF
	CALL	DISPREG
	TEST	byte [FZTRACE],-1
	JNZ	STEPZ
	JMP	STEP
STEPZ:	JMP	ZSTEP

; Re-entry point from CTRL-C. Top of stack has address in 86-DOS for
; continuing, so we must pop that off.
CONTC:
	ADD	SP,6
	JMP	SHORT REENTERREAL

; Re-entry point from breakpoint. Need to decrement instruction
; pointer so it points to location where breakpoint actually
; occured.
BREAKFIX:
	PUSH	BP
	MOV	BP,SP
	DEC	word [BP+INTERRUPT_FRAME.OLDIP]
	POP	BP
	JMP	REENTERREAL

; Re-entry point from trace mode or interrupt during execution.  All registers
; are saved so they can be displayed or modified.

;ASSUME	CS:DG,DS:NOTHING,ES:NOTHING,SS:NOTHING
; ReEnter is the main entry point for breakpoint interrupts and for trace mode
; interrupts.  We treat both of these cases identically:  save state, display
; registers and go for another command.  If we get NMI's, we skip them or if
; it turns out that we are debugging ourselves, we skip them.

; Due to bogosities in the 808x chip, Consider tracing over an interrupt and
; then setting a breakpoint to where the interrupt returns.  You get the INT 3
; and then trace mode gets invoked!  This is why we ignore interrupts within
; ourselves.
REENTER:
	PUSH	BP
	MOV	BP,SP			; get a frame to address from
	PUSH	AX
;	MOV	AX,CS
;	CMP	AX,[BP].OLDCS		; Did we interrupt ourselves?
;	JNZ	GOREENTER		; no, go reenter
	IF	IBMJAPAN
	    MOV     AX,[BP+INTERRUPT_FRAME.OLDIP]
	    CMP     AX,NMIInt        ; interrupt below NMI interrupt?
	    JB	    GOREENTER		; yes, go reenter
	    CMP     [BP+INTERRUPT_FRAME.OLDIP],NMIINTEND
	    JAE     GOREENTER		; interrupt above NMI interrupt?
	    POP     AX			; restore state
	    POP     BP
	    SUB     SP,6		; switch TRACE and NMI stack frames
	    PUSH    BP
	    MOV     BP,SP		; set up frame
	    PUSH    AX			; get temp variable
	    MOV     AX,[BP+INTERRUPT_FRAME.OLDERIP] ; get NMI Vector
	    MOV     [BP+INTERRUPT_FRAME.OLDIP],AX ; stuff in new NMI vector
	    MOV     AX,[BP+INTERRUPT_FRAME.OLDERCS] ; get NMI Vector
	    MOV     [BP+INTERRUPT_FRAME.OLDCS],AX ; stuff in new NMI vector
	    MOV     AX,[BP+INTERRUPT_FRAME.OLDERF] ; get NMI Vector
	    AND     AH,0FEH		; turn off Trace if present
	    MOV     [BP+INTERRUPT_FRAME.OLDF],AX ; stuff in new NMI vector
	    MOV     [BP+INTERRUPT_FRAME.OLDERF],AX
	    MOV     [BP+INTERRUPT_FRAME.OLDERIP],REENTER ; offset of routine
	    MOV     [BP+INTERRUPT_FRAME.OLDERCS],CS ; and CS
	    POP     AX
	    POP     BP
	    IRET			; go try again
	end if
GOREENTER:
	IF	IBMVER
	    MOV     AL,[cs:OLD_MASK]	; Recover Old mask
	    OUT     MASK_PORT,AL	; Restore it
	end if
	MOV	AL,[cs:RSETFLAG]
; Determine, based on the previous instruction, what we are supposed to do
; to flags on the users stack.
	CMP	AL,09CH 		; PUSHF
	JNZ	NOFIX
; OlderIP = flags.  Turn off trace bit
	AND	[BP+INTERRUPT_FRAME.OLDERIP],NOT f_Trace
NOFIX:
	POP	AX
	POP	BP
REENTERREAL:
	MOV	[cs:SPSAVE+SEGDIF],SP
	MOV	[cs:SSSAVE+SEGDIF],SS
	MOV	[cs:FLSAVE],CS
	MOV	SS,[cs:FLSAVE]
	MOV	SP,RSTACK
;	ASSUME	SS:DG

	PUSH	ES
	PUSH	DS
	PUSH	DI
	PUSH	SI
	PUSH	BP
	DEC	SP
	DEC	SP
	PUSH	DX
	PUSH	CX
	PUSH	BX
	PUSH	AX
	PUSH	SS
	POP	DS
;	ASSUME	DS:DG

	MOV	SS,[SSSAVE]
	MOV	SP,[SPSAVE]
;	ASSUME	SS:NOTHING

	POP	word [IPSAVE]
	POP	word [CSSAVE]
	POP	AX
	AND	AX,NOT f_Trace		; TURN OFf trace mode bit
	MOV	[FLSAVE],AX
	MOV	[SPSAVE],SP
SETENVIRON:
	PUSH	DS
	POP	ES
;	ASSUME	ES:DG

	PUSH	DS
	POP	SS
;	ASSUME	SS:DG

	MOV	SP,STACK_
	PUSH	DS
	XOR	AX,AX
	MOV	DS,AX
;	ASSUME	DS:NOTHING

	IF	SETCNTC
	    MOV     word [ds:8CH],DABORT            ; Set Ctrl-C vector
	    MOV     word [ds:8EH],CS
	end if
	POP	DS
;	ASSUME	DS:DG

	STI
	CLD
; Since we are about to issue system calls, let's grab the current user's
; extended error info.
	MOV	AH,GetExtendedError
	INT	21H
;	ASSUME	DS:NOTHING,ES:NOTHING

	MOV	[ss:SAVESTATE.DPL_AX],AX
	MOV	[ss:SAVESTATE.DPL_BX],BX
	MOV	[ss:SAVESTATE.DPL_CX],CX
	MOV	[ss:SAVESTATE.DPL_DX],DX
	MOV	[ss:SAVESTATE.DPL_SI],SI
	MOV	[ss:SAVESTATE.DPL_DI],DI
	MOV	[ss:SAVESTATE.DPL_DS],DS
	MOV	[ss:SAVESTATE.DPL_ES],ES
	MOV	AX,CS
	MOV	DS,AX
	MOV	ES,AX
;	ASSUME	DS:DG,ES:DG

	IF	NOT SYSVER
	    MOV     AH,Get_Current_PDB
	    INT     21H
	    MOV     [USER_PROC_PDB],BX
	    MOV     BX,[BEGSEG]
	    MOV     AH,Set_Current_PDB
	    INT     21H
	end if
	MOV	SI,BPTAB
	MOV	CX,[BRKCNT]
	JCXZ	SHOREG
	PUSH	ES
CLEARBP:
	LES	DI,dword [SI]
	ADD	SI,4
	MOVSB
	LOOP	CLEARBP
	POP	ES
SHOREG:
	DEC	word [TCOUNT]
	JZ	CHECKDISP
	JMP	STEP1
CHECKDISP:
	CALL	CRLF
	CALL	DISPREG
	JMP	COMMAND

; Input from the specified port and display result
INPUT:
	MOV	CX,4			; Port may have 4 digits
	CALL	GETHEX			; Get port number in DX
	CALL	GETEOL

	IN	AL,DX			; Variable port input

	PUSH	CS
	POP	ES
	MOV	DI,arg_buf
	CALL	HEX			; And display

	XOR	AL,AL
	STOSB
	MOV	DX,arg_buf_ptr
	JMP	PRINTF_CRLF

; Output a value to specified port.
OUTPUT:
	MOV	CX,4			; Port may have 4 digits
	CALL	GETHEX			; Get port number
	PUSH	DX			; Save while we get data
	MOV	CX,2			; Byte output only
	CALL	GETHEX			; Get data to output
	CALL	GETEOL
	XCHG	AX,DX			; Output data in AL
	POP	DX			; Port in DX

	OUT	DX,AL			; Variable port output

	return

SETADD:
	MOV	DX,[CSSAVE] ; set up start addresses
	MOV	[NextCS],DX
	MOV	DX,[IPSAVE]
	MOV	[NextIP],DX
	MOV	BP,[CSSAVE]
	CALL	SCANP
	CMP	byte [SI],"="
	retnz
	INC	SI
	CALL	ADDRESS
	MOV	[NextCS],AX
	MOV	[NextIP],DX
	return

; Jump to program, setting up registers according to the
; save area. up to 10 breakpoint addresses may be specified.
GO:
	MOV	byte [RSETFLAG],0
	CALL	SETADD
	XOR	BX,BX
	MOV	DI,BPTAB
GO1:
	CALL	SCANP
	JZ	DEXEC
	MOV	BP,[CSSAVE]
	PUSH	DI
	PUSH	BX			;AN000; DMS;SAVE BX - ADDRESS KILLS IT
	CALL	ADDRESS
	POP	BX			;AN000; DMS;RESTORE BX
	POP	DI
	MOV	[DI],DX 		; Save offset
	MOV	[DI+2],AX		; Save segment
	ADD	DI,5			; Leave a little room
	INC	BX
	CMP	BX,1+BPMAX
	JNZ	GO1
	MOV	DX,bp_error        ; BP ERROR
	JMP	ERR_
DEXEC:
	MOV	[BRKCNT],BX
	MOV	CX,BX
	JCXZ	NOBP
	MOV	DI,BPTAB
	PUSH	DS
SETBP:
	LDS	SI,dword [es:DI]
	ADD	DI,4
	MOVSB
	MOV	byte [SI-1],0CCH
	LOOP	SETBP
	POP	DS
NOBP:
	MOV	DX,[NextCS]
	MOV	[CSSAVE],DX
	MOV	DX,[NextIP]
	MOV	[IPSAVE],DX
	MOV	word [TCOUNT],1
	JMP	DEXIT

SKIP_FILE:
	MOV	AH,Char_Oper
	INT	21H
	MOV	[cs:SWITCHAR],DL	; GET THE CURRENT SWITCH CHARACTER
FIND_DELIM:
	LODSB
	CALL	DELIM1
	JZ	GOTDELIM
	CALL	DELIM2
	JNZ	FIND_DELIM
GOTDELIM:
	DEC	SI
	return

COMPARE:
	CALL	DSRANGE
	PUSH	CX
	PUSH	AX
	PUSH	DX
	CALL	ADDRESS 		; Same segment
	CALL	GETEOL
	POP	SI
	MOV	DI,DX
	MOV	ES,AX
	POP	DS
	POP	CX			; Length
	DEC	CX
	CALL	COMP			; Do one less than total
	INC	CX			; CX=1 (do last one)
COMP:
	REPE	CMPSB
	retz
; Compare error. Print address, value; value, address.
	DEC	SI
	MOV	[cs:comp_arg1],DS
	MOV	[cs:comp_arg2],SI
	XOR	AH,AH
	LODSB
	MOV	[cs:comp_arg3],AX
	DEC	DI
	MOV	AL,[es:DI]
	MOV	[cs:comp_arg4],AX
	MOV	[cs:comp_arg5],ES
	MOV	[cs:comp_arg6],DI
	INC	DI
	PUSH	DS
	PUSH	CS
	POP	DS
	MOV	DX,comp_ptr
	CALL	PRINTF_CRLF
	POP	DS
	XOR	AL,AL
	JMP	SHORT COMP

	procedure CHECKNONE,NEAR
	OR	DX,DX
	retnz
	MOV	DX,synerr_ptr        ; ERROR MESSAGE
	JMP	PERR
	EndProc CHECKNONE

end if
;	END	DEBCOM3
