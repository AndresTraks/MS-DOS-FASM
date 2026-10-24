;	SCCSID = @(#)srvcall.asm	1.4 85/08/02
TITLE SRVCALL - Server DOS call
NAME  SRVCALL
;
; Server DOS call functions
;
;
;   $ServerCall
;
;   Modification history:
;
;	Created: ARR 08 August 1983
;

;.xlist
;
; get the appropriate segment definitions
;
INCLUDE '../INC/DOSSEG.ASM'

if SEGSEL = S_CODE
;	ASSUME	SS:DOSGROUP,CS:DOSGROUP

;.xcref
INCLUDE '../INC/DOSSYM.INC'
INCLUDE '../INC/DEVSYM.INC'
;.cref
;.list

AsmVars <Installed>

INCLUDE '../INC/DPL.ASM'

Installed = TRUE

	i_need	USER_ID,WORD
	i_need	PROC_ID,WORD
	i_need	SaveBX,WORD
	i_need	SaveDS,WORD
	i_need	SWAP_START,BYTE
	i_need	Swap_Always,BYTE
	i_need	SWAP_END,BYTE
	I_Need	THISSFT,DWORD
	I_need	fSharing,BYTE
	i_need	OPENBUF,128
	I_Need	EXTERR,WORD
	I_Need	EXTERR_ACTION,BYTE
	I_Need	EXTERRPT,DWORD
	I_Need	EXTERR_LOCUS,BYTE	; Extended Error Locus
	i_need	JShare,DWORD
	i_need	SWAP_AREA_TABLE,BYTE
	i_need	SWAP_ALWAYS_AREA,DWORD
	i_need	SWAP_ALWAYS_AREA_LEN,WORD
	i_need	SWAP_AREA_LEN,WORD

BREAK <ServerCall -- Server DOS call>

; MASM let the table segment be opened inside the code segment and the
; assembler sorted the pieces out; here the code segment's pass has to be
; closed first, or the table would be laid down in the wrong one.
end if

if SEGSEL = S_TABLE
;Public SRVC001S,SRVC001E
SRVC001S:

ServerTab	DW	SERVER_DISP
SERVERLEAVE	DW	ServerReturn
SERVER_DISP	DB	(SERVER_DISP_END-SERVER_DISP-1)/2
		DW	SRV_CALL	; 0
		DW	COMMIT_ALL	; 1
		DW	CLOSE_NAME	; 2
		DW	CLOSE_UID	; 3
		DW	CLOSE_UID_PID	; 4
		DW	GET_LIST	; 5
		DW	GET_DOS_DATA	; 6
		DW	SPOOL_OPER	; 7
		DW	SPOOL_OPER	; 8
		DW	SPOOL_OPER	; 9
		DW	SetExtendedError$   ; 10
SERVER_DISP_END:

SRVC001E:

end if

if SEGSEL = S_CODE

; Inputs:
;	DS:DX -> DPL  (except calls 7,8,9)
; Function:
;	AL=0	Server DOS call
;	AL=1	Commit All files
;	AL=2	Close file by name (SHARING LOADED ONLY) DS:DX in DPL -> name
;	AL=3	Close all files for DPL_UID
;	AL=4	Close all files for DPL_UID/PID_PID
;	AL=5	Get open file list entry
;		    IN: BX File Index
;			CX User Index
;		    OUT:ES:DI -> Name
;			BX = UID
;		    CX = # locked blocks held by this UID
;	AL=6	Get DOS data area
;		    OUT: DS:SI -> Start
;			CX size in bytes of swap if indos
;			DX size in bytes of swap always
;	AL=7	Get truncate flag
;	AL=8	Set truncate flag
;	AL=9	Close all spool files
;	AL=10	SetExtendedError
;	AL=11	DOS4.00 Get DOS data area
;		    DS:SI -> swap table

	procedure   ServerCall$,NEAR
;ASSUME	DS:NOTHING,ES:NOTHING
	CMP	AL,7
	JB	SET_STUFF
	CMP	AL,9
	JBE	NO_SET_ID		; No DPL on calls 7,8,9
	CMP	AL,11				   ;IFS.			;AN000;
	JNZ	SET_STUFF			   ;IFS.			;AN000;
	MOV	DI,SWAP_AREA_TABLE ;IFS.			;AN000;
	PUSH	SS				   ;IFS.			;AN000;
	POP	ES				   ;IFS.			;AN000;
	invoke	get_user_stack			   ;IFS.			;AN000;
	MOV	[SI+user_environ.user_DS],ES 		   ;IFS.   ds:si -> swap tab	;AN000;
	MOV	[SI+user_environ.user_SI],DI 		   ;IFS.			;AN000;
	transfer SYS_RET_OK			   ;IFS.			;AN000;
SET_STUFF:
	MOV	SI,DX			; Point to DPL with DS:SI
	MOV	BX,[SI+DPL.DPL_UID]
	MOV	[ss:USER_ID],BX		; Set UID
	MOV	BX,[SI+DPL.DPL_PID]
	MOV	[ss:PROC_ID],BX		; Set process ID
NO_SET_ID:
	PUSH	word [ss:SERVERLEAVE]		; push return address
	PUSH	word [ss:ServerTab]		; push table address
	PUSH	AX
	Invoke	TableDispatch
	MOV	byte [ss:EXTERR_LOCUS],errLOC_Unk ; Extended Error Locus
	error	error_invalid_function
ServerReturn:
	return

; Commit - iterate through the open file list and make sure that the
; directory entries are correctly updated.

COMMIT_ALL:
;ASSUME	DS:NOTHING,ES:NOTHING
	XOR	BX,BX			;   for (i=0; ThisSFT=getSFT(i); i++)
	Context DS
	EnterCrit   critSFT		; Gonna scan SFT cache, lock it down
CommitLoop:
	SaveReg <BX>
	Invoke	SFFromSFN
	JC	CommitDone
	CMP	[es:DI+sf_entry.sf_ref_count],0	;	if (ThisSFT->refcount != 0)
	JZ	CommitNext
	CMP	[es:DI+sf_entry.sf_ref_count],sf_busy  ; BUSY SFTs have god knows what
	JZ	CommitNext		      ;   in them.
;	TEST	ES:[DI].sf_flags,sf_isnet
	invoke	TEST_IFS_REMOTE 	;IFS.					;AN000;
	JNZ	CommitNext		;  Skip Network SFTs so the SERVER
					;	doesn't deadlock
	MOV	word [THISSFT],DI
	MOV	word [THISSFT+2],ES
	Invoke	DOS_COMMIT		;	    DOSCommit ();
CommitNext:
	RestoreReg  <BX>
	INC	BX
	JMP	CommitLoop
CommitDone:
	LeaveCrit   critSFT
	RestoreReg  <BX>
	transfer    SYS_RET_OK

CLOSE_NAME:
;ASSUME	DS:NOTHING,ES:NOTHING

if Installed
	Call	dword [ss:JShare+5*4]
else
	Call	MFTcloN
end if
CheckReturns:
	JC	func_err
	transfer SYS_RET_OK
func_err:
	transfer SYS_RET_ERR

CLOSE_UID:
;ASSUME	DS:NOTHING,ES:NOTHING

if Installed
	Call	dword [ss:JShare+3*4]
else
	Call	MFTclU
end if
	JMP	CheckReturns

CLOSE_UID_PID:
;ASSUME	DS:NOTHING,ES:NOTHING

if Installed
	Call	dword [ss:JShare+4*4]
else
	Call	MFTCloseP
end if
	JMP	CheckReturns

GET_LIST:
;ASSUME	DS:NOTHING,ES:NOTHING
if Installed
	Call	dword [ss:JShare+9*4]
else
	Call	MFT_get
end if
	JC	func_err
	invoke	get_user_stack
	MOV	[SI+user_environ.user_BX],BX
	MOV	[SI+user_environ.user_DI],DI
	MOV	[SI+user_environ.user_ES],ES
SetCXOK:
	MOV	[SI+user_environ.user_CX],CX
	transfer    SYS_RET_OK

SRV_CALL:
;ASSUME	DS:NOTHING,ES:NOTHING
	POP	AX			; get rid of call to $srvcall
	SaveReg <DS,SI>
	invoke	get_user_stack
	RestoreReg  <DI,ES>
;
; DS:SI point to stack
; ES:DI point to DPL
;
	invoke	XCHGP
;
; DS:SI point to DPL
; ES:DI point to stack
;
; We now copy the registers from DPL to save stack
;
	SaveReg <SI>
	MOV	CX,6
	REP	MOVSW			; Put in AX,BX,CX,DX,SI,DI
	INC	DI
	INC	DI			; Skip user_BP
	MOVSW				; DS
	MOVSW				; ES
	RestoreReg  <SI>		; DS:SI -> DPL
	MOV	AX,[SI+DPL.DPL_AX]
	MOV	BX,[SI+DPL.DPL_BX]
	MOV	CX,[SI+DPL.DPL_CX]
	MOV	DX,[SI+DPL.DPL_DX]
	MOV	DI,[SI+DPL.DPL_DI]
	MOV	ES,[SI+DPL.DPL_ES]
	PUSH	word [SI+DPL.DPL_SI]
	MOV	DS,[SI+DPL.DPL_DS]
	POP	SI
	MOV	[ss:SaveDS],DS
	MOV	[ss:SaveBX],BX
	MOV	byte [ss:fSharing],-1		; set no redirect flag
	transfer REDISP

GET_DOS_DATA:
;ASSUME	DS:NOTHING,ES:NOTHING
	LES	DI,[ss:SWAP_ALWAYS_AREA]	     ;IFS. get beginning addr of swap ;AC000;
	MOV	DX,[ss:SWAP_ALWAYS_AREA_LEN]    ;IFS. get swap always area len   ;AC000;
	AND	DX,7FFFH		     ;IFS. clear high bit	      ;AC000;
	MOV	CX,[ss:SWAP_AREA_LEN]	     ;IFS. get swap len 	      ;AC000;
	invoke	get_user_stack
	MOV	[SI+user_environ.user_DS],ES 	     ;	set user regs
	MOV	[SI+user_environ.user_SI],DI 	     ;
	MOV	[SI+user_environ.user_DX],DX 	     ;
	JMP	SetCXOK 		     ;				      ;AN000;

SPOOL_OPER:
;ASSUME	DS:NOTHING,ES:NOTHING
	CallInstall NETSpoolOper,MultNET,37,AX,BX
	JC	func_err2
	transfer SYS_RET_OK
func_err2:
	transfer SYS_RET_ERR

Break	<SetExtendedError$ - Set extended error for later retrieval>

;
; $SetExtendedError takes extended error information and loads it up for the
; next extended error call.  This is used by interrupt-level proccessors to
; mask their actions.
;
;   Inputs: DS:SI points to DPL which contains all registers
;   Outputs: none
;

SetExtendedError$:
;	ASSUME	DS:NOTHING,ES:NOTHING
	MOV	AX,[SI+DPL.DPL_AX]
	MOV	[ss:EXTERR],AX
	MOV	AX,[SI+DPL.DPL_DI]
	MOV	word [ss:EXTERRPT],AX
	MOV	AX,[SI+DPL.DPL_ES]
	MOV	word [ss:EXTERRPT+2],AX
	MOV	AX,[SI+DPL.DPL_BX]
	MOV	word [ss:EXTERR_ACTION],AX
	MOV	AX,[SI+DPL.DPL_CX]
	MOV	[ss:EXTERR_LOCUS],AH
	return
EndProc ServerCall$

end if
;    END
