;	SCCSID = @(#)search.asm 1.1 85/04/10
TITLE	SEARCH - Directory Scan system calls
NAME	SEARCH

;
;
; Directory search system calls.  These will be passed direct text of the
; pathname from the user.  They will need to be passed through the macro
; expander prior to being sent through the low-level stuff.  I/O specs are
; defined in DISPATCH.	The system calls are:
;
;
;   $Dir_Search_First	  written
;   $Dir_Search_Next	  written
;   $Find_First 	  written
;   $Find_Next		  written
;   PackName		  written
;
;   Modification history:
;
;	Created: ARR 4 April 1983
;

;.xlist
;
; get the appropriate segment definitions
;
INCLUDE '../INC/DOSSEG.ASM'

if SEGSEL = S_CODE
;	ASSUME	SS:DOSGroup,CS:DOSGroup

;.xcref
INCLUDE '../INC/DOSSYM.INC'
INCLUDE '../INC/DEVSYM.INC'
INCLUDE '../INC/FASTOPEN.INC'
INCLUDE '../INC/FASTXXXX.INC'
;.cref
;.list

	i_need	SEARCHBUF,53
	i_need	SATTRIB,BYTE
	I_Need	OPENBUF,128
	I_need	DMAADD,DWORD
	I_need	THISFCB,DWORD
	I_need	CURDRV,BYTE
	I_need	EXTFCB,BYTE
	I_need	FastOpenFlg,BYTE
	I_need	DOS34_FLAG,WORD

; Inputs:
;	DS:DX Points to unopenned FCB
; Function:
;	Directory is searched for first matching entry and the directory
;	entry is loaded at the disk transfer address
; Returns:
;	AL = -1 if no entries matched, otherwise 0

	procedure DIR_SEARCH_FIRST$,NEAR
;ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup

	MOV	word [ss:THISFCB],DX
	MOV	word [ss:THISFCB+2],DS
	MOV	SI,DX
	CMP	byte [SI],0FFH
	JNZ	NORMFCB4
	ADD	SI,7			; Point to drive select byte
NORMFCB4:
	SaveReg <word [SI]>			; Save original drive byte for later
	Context ES			; get es to address DOSGroup
	MOV	DI,OPENBUF  ; appropriate buffer
	invoke	TransFCB		; convert the FCB, set SATTRIB EXTFCB
	JNC	SearchIt		; no error, go and look
	RestoreReg <BX> 		; Clean stack
;
; Error code is in AX
;
	transfer FCB_RET_ERR		; error

SearchIt:
	Context DS			; get ready for search
	SaveReg <word [DMAADD], word [DMAADD+2]>
	MOV	word [DMAADD],SEARCHBUF
	MOV	word [DMAADD+2],DS
	invoke	GET_FAST_SEARCH 	; search
	RestoreReg <word [DMAADD+2], word [DMAADD]>
	JNC	SearchSet		; no error, transfer info
	RestoreReg <BX> 		; Clean stack
;
; Error code is in AX
;
	transfer FCB_RET_ERR

;
; The search was successful (or the search-next).  We store the information
; into the user's FCB for continuation.
;
SearchSet:
	MOV	SI,SEARCHBUF
	LES	DI,[THISFCB]		; point to the FCB
	TEST	byte [EXTFCB],0FFH		;
	JZ	NORMFCB1
	ADD	DI,7			; Point past the extension
NORMFCB1:
	RestoreReg <BX> 		; Get original drive byte
	OR	BL,BL
	JNZ	SearchDrv
	MOV	BL,[CURDRV]
	INC	BL
SearchDrv:
	LODSB				; Get correct search contin drive byte
	XCHG	AL,BL			; Search byte to BL, user byte to AL
	INC	DI
;	STOSB				; Store the correct "user" drive byte
					;  at the start of the search info
	MOV	CX,20/2
	REP	MOVSW			; Rest of search cont info, SI -> entry
	XCHG	AL,BL			; User drive byte back to BL, search
					;   byte to AL
	STOSB				; Search contin drive byte at end of
					;   contin info
	LES	DI,[DMAADD]
	TEST	byte [EXTFCB],0FFH
	JZ	NORMFCB2
	MOV	AL,0FFH
	STOSB
	INC	AL
	MOV	CX,5
	REP	STOSB
	MOV	AL,[SATTRIB]
	STOSB
NORMFCB2:
	MOV	AL,BL			; User Drive byte
	STOSB
 if  DBCS									;AN000;
	MOVSW				; 2/13/KK				;AN000;
	CMP	byte [es:DI-2],5	; 2/13/KK				;AN000;
	JNZ	NOTKTRAN		; 2/13/KK				;AN000;
	MOV	byte [es:DI-2],0E5H ; 2/13/KK				;AN000;
NOTKTRAN:				; 2/13/KK				;AN000;
	MOV	CX,15			; 2/13/KK				;AN000;
 else										;AN000;
	MOV	CX,16			; 32 / 2 words of dir entry		;AN000;
 end if										;AN000;
	REP	MOVSW
	transfer FCB_RET_OK

EndProc DIR_SEARCH_FIRST$

; Inputs:
;	DS:DX points to unopenned FCB returned by $DIR_SEARCH_FIRST
; Function:
;	Directory is searched for the next matching entry and the directory
;	entry is loaded at the disk transfer address
; Returns:
;	AL = -1 if no entries matched, otherwise 0

	procedure DIR_SEARCH_NEXT$,NEAR
;ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup

	MOV	word [ss:THISFCB],DX
	MOV	word [ss:THISFCB+2],DS
	MOV	byte [ss:SATTRIB],0
	MOV	byte [ss:EXTFCB],0
	Context ES
	MOV	DI,SEARCHBUF
	MOV	SI,DX
	CMP	byte [SI],0FFH
	JNZ	NORMFCB6
	ADD	SI,6
	LODSB
	MOV	[ss:SATTRIB],AL
	DEC	byte [ss:EXTFCB]
NORMFCB6:
	LODSB				; Get original user drive byte
	SaveReg <AX>			; Put it on stack
	MOV	AL,[SI+20]		; Get correct search contin drive byte
	STOSB				; Put in correct place
	MOV	CX,20/2
	REP	MOVSW			; Transfer in rest of search contin info
	Context DS
	SaveReg <word [DMAADD], word [DMAADD+2]>
	MOV	word [DMAADD],SEARCHBUF
	MOV	word [DMAADD+2],DS
	invoke	DOS_SEARCH_NEXT 	; Find it
	RestoreReg <word [DMAADD+2], word [DMAADD]>
	JC	SearchNoMore
	JMP	SearchSet		; Ok set return

SearchNoMore:
	LES	DI,[THISFCB]
	TEST	byte [EXTFCB],0FFH
	JZ	NORMFCB8
	ADD	DI,7			; Point past the extension
NORMFCB8:
	RestoreReg <BX> 		; Get original drive byte
	MOV	[es:DI],BL		; Store the correct "user" drive byte
					;  at the right spot
;
; error code is in AX
;
	transfer FCB_RET_ERR

EndProc DIR_SEARCH_NEXT$

;   Assembler usage:
;	    MOV AH, FindFirst
;	    LDS DX, name
;	    MOV CX, attr
;	    INT 21h
;	; DMA address has datablock
;
;   Error Returns:
;	    AX = error_path_not_found
;	       = error_no_more_files

	procedure FIND_FIRST$,NEAR
;ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup

	MOV	SI,DX			; get name in appropriate place
	MOV	[ss:SATTRIB],CL		; Search attribute to correct loc
	MOV	DI,OPENBUF  ; appropriate buffer
	invoke	TransPathSet		; convert the path
	JNC	Find_it 		; no error, go and look
FindError:
	error	error_path_not_found	; error and map into one.
Find_it:
	Context DS
	SaveReg <word [DMAADD], word [DMAADD+2]>
	MOV	word [DMAADD],SEARCHBUF
	MOV	word [DMAADD+2],DS
	invoke	GET_FAST_SEARCH 	; search
	RestoreReg <word [DMAADD+2], word [DMAADD]>
	JNC	FindSet 		; no error, transfer info
	transfer SYS_RET_ERR

FindSet:
	MOV	SI,SEARCHBUF
	LES	DI,[DMAADD]
	MOV	CX,21
	REP	MOVSB
	PUSH	SI			; Save pointer to start of entry
	MOV	AL,[SI+dir_entry.dir_attr]
	STOSB
	ADD	SI,dir_entry.dir_time
	MOVSW				; dir_time
	MOVSW				; dir_date
	INC	SI
	INC	SI			; Skip dir_first
	MOVSW				; dir_size (2 words)
	MOVSW
	POP	SI			; Point back to dir_name
 if  DBCS									;AN000;
	PUSH	DI			; XXXX save dest name 2/13/KK		;AN000;
	CALL	PackName							;AN000;
	POP	DI			; XXXX Recover dest name 2/13/KK	;AN000;
	CMP	byte [es:DI],05H	; XXXX Need fix?	 2/13/KK	;AN000;
	JNZ	FNXXX			; XXXX No		 2/13/KK	;AN000;
	MOV	byte [es:DI],0E5H	; XXXX Yes, Fix 	 2/13/KK	;AN000;
FNXXX:					; 2/13/KK				;AN000;
 else										;AN000;
	CALL	PackName
 end if
	transfer    SYS_RET_OK		; bye with no errors
EndProc FIND_FIRST$

	procedure FIND_NEXT$,NEAR
;ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup

;   Assembler usage:
;	; dma points at area returned by find_first
;	    MOV AH, findnext
;	    INT 21h
;	; next entry is at dma
;
;   Error Returns:
;	    AX = error_no_more_files

	Context ES
	MOV	DI,SEARCHBUF
	LDS	SI,[ss:DMAADD]
	MOV	CX,21
	REP	MOVSB			; Put the search continuation info
					;  in the right place
	Context DS			; get ready for search
	SaveReg <word [DMAADD], word [DMAADD+2]>
	MOV	word [DMAADD],SEARCHBUF
	MOV	word [DMAADD+2],DS
	invoke	DOS_SEARCH_NEXT 	; Find it
	RestoreReg <word [DMAADD+2], word [DMAADD]>
	JNC	FindSet 		; No error, set info
	transfer SYS_RET_ERR

EndProc FIND_NEXT$

Break	<PackName - convert file names from FCB to ASCIZ>
;
;   PackName - transfer a file name from DS:SI to ES:DI and convert it to
;	the ASCIZ format.
;
;   Input:	DS:SI points to an 11 character FCB or dir entry name
;		ES:DI points to a destination area (13 bytes)
;   Output:	Above pointers advanced
;   Registers modified: SI,DI,CX,AL
	Procedure PackName,NEAR
;	ASSUME	CS:DOSGroup,DS:NOTHING,ES:NOTHING,SS:DOSGroup
	MOV	CX,8			; Pack the name
	REP	MOVSB			; Move all of it
main_kill_tail:
	CMP	byte [es:DI-1]," "
	JNZ	find_check_dot
	DEC	DI			; Back up over trailing space
	INC	CX
	CMP	CX,8
	JB	main_kill_tail
find_check_dot:
	CMP	word [SI],(" " SHL 8) OR " "
	JNZ	got_ext 		; Some chars in extension
	CMP	byte [SI+2]," "
	JZ	find_done		; No extension
got_ext:
	MOV	AL,"."
	STOSB
	MOV	CX,3
	REP	MOVSB
ext_kill_tail:
	CMP	byte [es:DI-1]," "
	JNZ	find_done
	DEC	DI			; Back up over trailing space
	JMP	ext_kill_tail
find_done:
	XOR	AX,AX
	STOSB				; NUL terminate
	return
EndProc PackName

	procedure   GET_FAST_SEARCH,NEAR
;	ASSUME	DS:NOTHING,ES:NOTHING

	OR	word [ss:DOS34_FLAG],SEARCH_FASTOPEN  ;FO.trigger fastopen		;AN000;
	invoke	DOS_SEARCH_FIRST
	return

EndProc GET_FAST_SEARCH
end if
;END
