;	SCCSID = @(#)finfo.asm	1.1 85/04/11
TITLE	FILE_INFO - Internal Get/Set File Info routines
NAME	FILE_INFO
; Low level routines for returning file information and setting file
;   attributes
;
;   GET_FILE_INFO
;   SET_FILE_ATTRIBUTE
;
;   Modification history:
;
;	Created: ARR 30 March 1983
;

;
; get the appropriate segment definitions
;
;.xlist
INCLUDE '../INC/DOSSEG.ASM'

if SEGSEL = S_CODE
;	ASSUME	SS:DOSGROUP,CS:DOSGROUP

;.xcref
INCLUDE '../INC/DOSSYM.INC'
INCLUDE '../INC/DEVSYM.INC'
INCLUDE '../INC/FASTXXXX.INC'
INCLUDE '../INC/FASTOPEN.INC'
;.cref
;.list

Installed = TRUE

	i_need	THISCDS,DWORD
	i_need	CURBUF,DWORD
	i_need	NoSetDir,BYTE
	i_need	THISDRV,BYTE
	I_need	EXTERR_CLASS,BYTE
	I_need	EXTERR_ACTION Set
	I_need	EXTERR_LOCUS,BYTE
	i_need	DMAADD,DWORD
	i_need	FastOpenFlg,BYTE

SUBTTL GET_FILE_INFO -- Get File Information
PAGE

; Inputs:
;	[WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL
;		terminated)
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used
;		(Low word = -1 if NUL CDS (Net direct request))
;	[SATTRIB] Is attribute of search, determines what files can be found
; Function:
;	Get Information about a file
; Returns:
;	CARRY CLEAR
;	    AX = Attribute of file
;	    CX = Time stamp of file
;	    DX = Date stamp of file
;	    BX:DI = Size of file (32 bit)
;	CARRY SET
;	    AX is error code
;		error_file_not_found
;			Last element of path not found
;		error_path_not_found
;			Bad path (not in curr dir part if present)
;		error_bad_curr_dir
;			Bad path in current directory part of path
; DS preserved, others destroyed

	procedure   GET_FILE_INFO,NEAR
	DOSAssume   CS,<DS>,"Get_File_Info"
;	ASSUME	ES:NOTHING

	Invoke	TestNet
	JNC	LOCAL_INFO_FINFO
;	invoke	OWN_SHARE2		       ;IFS. IFS owns share ?		;AN000;
;	JZ	ifsshare_FINFO		       ;IFS. yes			;AN000;
;	PUSH	WORD PTR [DMAADD+2]	       ;IFS. save DMAADD		;AN000;
;	PUSH	WORD PTR [DMAADD]	       ;IFS.				;AN000;
;	invoke	IFS_SEARCH_FIRST	       ;IFS. do search first		;AN000;
;	JC	nofiles_FINFO 		       ;IFS. file not existing		;AN000;
delete_next_file_FINFO:			       ;IFS.				;AN000;
;	invoke	IFS_REN_DEL_CHECK	       ;IFS. do REN_DEL_CHECK		;AN000;
;	JNC	share_okok_FINFO		       ;IFS. share ok			;AN000;
;	MOV	AX,error_sharing_violation     ;IFS. share violation		;AN000;
;	JMP	SHORT nofiles_FINFO		       ;IFS.				;AN000;
share_okok_FINFO:
;	POP	WORD PTR [DMAADD]	       ;IFS. retor DMAADD		;AN000;
;	POP	WORD PTR [DMAADD+2]	       ;IFS.				;AN000;
ifsshare_FINFO:
if NOT Installed
	transfer NET_GET_FILE_INFO
else
	MOV	AX,(MultNET SHL 8) OR 15
	INT	2FH
	return
end if
nofiles_FINFO:
;	POP	WORD PTR [DMAADD]	       ;IFS. retor DMAADD		;AN000;
;	POP	WORD PTR [DMAADD+2]	       ;IFS.				;AN000;
;	ret				       ;IFS. return

LOCAL_INFO_FINFO:
	EnterCrit   critDisk
	MOV	byte [NoSetDir],1		; if we find a dir, don't change to it
	invoke	GET_FAST_PATH
info_check:
	JNC	info_check_dev

NO_PATH:
	DOSAssume   CS,<DS>,"FINFO/No_Path"
;	ASSUME	ES:NOTHING

	JNZ	bad_path_FINFO
	OR	CL,CL
	JZ	bad_path_FINFO
info_no_file:
	MOV	AX,error_file_not_found
BadRet_FINFO:
	STC
justRet:
	LeaveCrit   critDisk
	return

bad_path_FINFO:
	MOV	AX,error_path_not_found
	jmp	BadRet_FINFO

info_check_dev:
	OR	AH,AH
	JS	info_no_file		; device
	PUSH	DS
	MOV	DS,word [CURBUF+2]
;ASSUME	DS:NOTHING
	MOV	SI,BX
	XOR	BX,BX			; Assume size=0 (dir)
	MOV	DI,BX
	MOV	CX,[SI+dir_entry.dir_time]
	MOV	DX,[SI+dir_entry.dir_date]
	XOR	AH,AH
	MOV	AL,[SI+dir_entry.dir_attr]
	TEST	AL,attr_directory
	JNZ	NO_SIZE
	MOV	DI,[SI+dir_entry.dir_size_l]
	MOV	BX,[SI+dir_entry.dir_size_h]
NO_SIZE:
	POP	DS
	CLC
	jmp	justRet
EndProc GET_FILE_INFO

Break	<SET_FILE_ATTRIBUTE -- Set File Attribute>

; Inputs:
;	[WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL
;		terminated)
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used
;		(Low word = -1 if NUL CDS (Net direct request))
;	[SATTRIB] is attribute of search (determines what files may be found)
;	AX is new attributes to give to file
; Function:
;	Set File Attributes
; Returns:
;	CARRY CLEAR
;	    No error
;	CARRY SET
;	    AX is error code
;		error_file_not_found
;			Last element of path not found
;		error_path_not_found
;			Bad path (not in curr dir part if present)
;		error_bad_curr_dir
;			Bad path in current directory part of path
;		error_access_denied
;			Attempt to set an attribute which cannot be set
;			(attr_directory, attr_volume_ID)
;		error_sharing_violation
;			Sharing mode of file did not allow the change
;			(this request requires exclusive write/read access)
;			(INT 24H generated)
; DS preserved, others destroyed

	procedure   SET_FILE_ATTRIBUTE,NEAR
	DOSAssume   CS,<DS>,"Set_File_Attribute"
;	ASSUME	ES:NOTHING

	TEST	AX,NOT attr_changeable
	JZ	set_look
BAD_ACC_FINFO:
	MOV	byte [EXTERR_LOCUS],errLOC_Unk
	MOV	byte [EXTERR_CLASS],errCLASS_Apperr
	MOV	byte [EXTERR_ACTION],errACT_Abort
	MOV	AX,error_access_denied
	STC
	return

set_look:
	Invoke	TestNet
	JNC	LOCAL_SET

if NOT Installed
	transfer NET_SEQ_SET_FILE_ATTRIBUTE
else
	PUSH	AX
	MOV	AX,(MultNET SHL 8) OR 14
	INT	2FH
	POP	BX			; clean stack
	return
end if

LOCAL_SET:
	EnterCrit   critDisk
	PUSH	AX			; Save new attributes
	MOV	byte [NoSetDir],1		; if we find a dir, don't change to it
	invoke	GETPATH 		; get path through fastopen if there	 ;AC000;
	JNC	set_check_device
	POP	BX			; Clean stack (don't zap AX)
	JMP	NO_PATH

set_check_device:
	OR	AH,AH
	JNS	set_check_share
	POP	AX
	LeaveCrit   critDisk
	JMP	BAD_ACC_FINFO 		; device

set_check_share:
	POP	AX			; Get new attributes
	invoke	REN_DEL_Check
	JNC	set_do
	MOV	AX,error_sharing_violation
	jmp	short	OK_BYE

set_do:
	LES	DI,[CURBUF]
	AND	byte [es:BX+dir_entry.dir_attr],NOT attr_changeable
	OR	byte [es:BX+dir_entry.dir_attr],AL

	TEST	[es:DI+BUFFINFO.buf_flags],buf_dirty  ;LB. if already dirty		;AN000;
	JNZ	yesdirty_FINFO		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	[es:DI+BUFFINFO.buf_flags],buf_dirty
yesdirty_FINFO:
	MOV	AL,[THISDRV]
;;;; 10/1/86 F.C update fastopen cache
	PUSH	DX
	PUSH	DI
	MOV	AH,0		  ; dir entry update
	MOV	DL,AL		  ; drive number A=0,B=1,,
	MOV	DI,BX		  ; ES:DI -> dir entry
	invoke	FastOpen_Update
	POP	DI
	POP	DX
;;;; 9/11/86 F.C update fastopen cache
	invoke	FlushBuf
	JNC	OK_BYE
	MOV	AX,error_file_not_found
OK_BYE:
	LeaveCrit   critDisk
	return

EndProc SET_FILE_ATTRIBUTE



	procedure   GET_FAST_PATH,NEAR
;	ASSUME	DS:NOTHING,ES:NOTHING

	OR	byte [FastOpenFlg],FastOpen_Set ;FO. trigger fastopen		;AN000;
	invoke	GETPATH
	PUSHF			       ;FO.					;AN000;
	AND    byte [FastOpenFlg],Fast_yes  ;FO. clear all fastopen flags		;AN000;
	POPF			       ;FO.					;AN000;
	return

EndProc GET_FAST_PATH

end if
;    END
