;	SCCSID = @(#)rename.asm 1.1 85/04/10
TITLE	DOS_RENAME - Internal Rename call for MS-DOS
NAME	DOS_RENAME
; Low level routine for renaming files
;
;   DOS_RENAME
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
;.cref
;.list

Installed = TRUE

	i_need	RENAMEDMA,BYTE
	i_need	AuxStack,BYTE
	i_need	DESTSTART,WORD
	i_need	DIRSTART,WORD
	i_need	CURBUF,DWORD
	I_need	NAME1,BYTE
	i_need	NAME2,BYTE
	i_need	WFP_START,WORD
	i_need	REN_WFP,WORD
	i_need	CURR_DIR_END,WORD
	i_need	DMAADD,DWORD
	i_need	THISCDS,DWORD
	i_need	THISDPB,DWORD
	i_need	THISSFT,DWORD
	i_need	CREATING,BYTE
	i_need	THISDRV,BYTE
	i_need	ATTRIB,BYTE
	i_need	Found_dev,BYTE
	i_need	FAILERR,BYTE
	i_need	EXTERR_LOCUS,BYTE
	i_need	SAVE_BX,WORD

; Inputs:
;	[WFP_START] Points to SOURCE WFP string ("d:/" must be first 3
;		chars, NUL terminated)
;	[CURR_DIR_END] Points to end of Current dir part of string [SOURCE]
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[REN_WFP] Points to DEST WFP string ("d:/" must be first 3
;		chars, NUL terminated)
;	[THISCDS] Points to CDS being used
;		(Low word = -1 if NUL CDS (Net direct request))
;	[SATTRIB] Is attribute of search, determines what files can be found
; Function:
;	Rename the specified file(s)
;	NOTE: This routine uses most of AUXSTACK as a temp buffer.
; Outputs:
;	CARRY CLEAR
;	    OK
;	CARRY SET
;	    AX is error code
;		error_file_not_found
;			No match for source, or dest path invalid
;		error_not_same_device
;			Source and dest are on different devices
;		error_access_denied
;			Directory specified (not simple rename),
;			Device name given, Destination exists.
;			NOTE: In third case some renames may have
;			 been done if metas.
;		error_path_not_found
;			Bad path (not in curr dir part if present)
;			SOURCE ONLY
;		error_bad_curr_dir
;			Bad path in current directory part of path
;			SOURCE ONLY
;		error_sharing_violation
;			Deny both access required, generates an INT 24.
; DS preserved, others destroyed

	procedure   DOS_RENAME,NEAR
	DOSAssume   CS,<DS>,"DOS_Rename"
;	ASSUME	ES:NOTHING

	Invoke	TestNet
	JNC	LOCAL_RENAME
;	invoke	OWN_SHARE2		       ;IFS.  IFS owns share ?		;AN000;
;	JZ	ifsshare_RENAME		       ;IFS.  yes			;AN000;
;	PUSH	WORD PTR [DMAADD+2]	       ;IFS.  save DMAADD		;AN000;
;	PUSH	WORD PTR [DMAADD]	       ;IFS.				;AN000;
;
;	invoke	IFS_SEARCH_FIRST	       ;IFS.  search source name	;AN000;
;	JC	nofiles_RENAME 		       ;IFS.  not found 		;AN000;
rename_next_file:
;	invoke	IFS_REN_DEL_CHECK	       ;IFS.  do share check		;AN000;
;	JNC	share_okok_RENAME		       ;IFS.  share ok			;AN000;
;	MOV	AX,error_sharing_violation     ;IFS.  share error		;AN000;
;	JMP	SHORT nofiles_RENAME		       ;IFS.				;AN000;
share_okok_RENAME:
;	PUSH	CS			       ;IFS.				;AN000;
;	POP	ES			       ;IFS.				;AN000;
;	MOV	SI,[REN_WFP]		       ;IFS. ds:si -> destination name	;AN000;
;	MOV	BX,SI			       ;IFS.				;AN000;
fndnxt: 				       ;IFS.				;AN000;
;	LODSB				       ;IFS.				;AN000;
;	CMP	AL,0			       ;IFS.				;AN000;
;	JNZ	fndnxt			       ;IFS.				;AN000;
;	MOV	DI,SI			       ;IFS. es:di -> end of destinatio ;AN000;
;	ADD	BX,2			       ;IFS.				;AN000;
;	invoke	SkipBack		       ;IFS.				;AN000;
;	INC	DI			       ;IFS. es:di -> last component of ;AN000;
;	MOV	SI,DI			       ;IFS.	      dstination	;AN000;
;	MOV	BX,[SAVE_BX]		       ;IFS. ds:bx -> last component of ;AN000;
;	CALL	NEW_RENAME		       ;IFS.	      source		;AN000;
;	MOV	AX,(multNET SHL 8) OR 17       ;IFS.  replace ? chars with	;AN000;
;	INT	2FH			       ;IFS.  source and issue RENAME	;AN000;
;	JC	nofiles_RENAME 		       ;IFS.  error			;AN000;
;	invoke	DOS_SEARCH_NEXT 	       ;IFS.  serch next source 	;AN000;
;	JNC	rename_next_file	       ;IFS.  rename next		;AN000;
;	CLC				       ;IFS.  no more files		;AN000;
nofiles_RENAME:
;	POP	WORD PTR [DMAADD]	       ;IFS. restore DMAADD		;AN000;
;	POP	WORD PTR [DMAADD+2]	       ;IFS.				;AN000;
;	ret				       ;IFS. return			;AN000;
ifsshare_RENAME:

if NOT Installed
	transfer NET_RENAME
else
	MOV	AX,(MultNET SHL 8) OR 17
	INT	2FH
	return
end if

LOCAL_RENAME:
	MOV	byte [ss:EXTERR_LOCUS],errLOC_Disk
	MOV	SI,[ss:WFP_START]
	MOV	DI,[ss:REN_WFP]
	MOV	AL,byte [SI]
	MOV	AH,byte [DI]
	OR	AX,2020H		; Lower case
	CMP	AL,AH
	JZ	SAMEDRV
	MOV	AX,error_not_same_device
	STC
	return

SAMEDRV:
	PUSH	word [ss:DMAADD+2]
	PUSH	word [ss:DMAADD]
	MOV	word [ss:DMAADD+2],DS
	MOV	word [ss:DMAADD],RENAMEDMA
	MOV	byte [ss:Found_dev],0		; Rename fails on DEVS, assume not a dev
	EnterCrit   critDisk
	invoke	DOS_SEARCH_FIRST	; Sets [NoSetDir] to 1, [CURBUF+2]:BX
					;    points to entry
	JNC	Check_dev
	CMP	AX,error_no_more_files
	JNZ	GOTERR
	MOV	AX,error_file_not_found
GOTERR:
	STC
RENAME_POP:
	POP	word [ss:DMAADD]
	POP	word [ss:DMAADD+2]
	LeaveCrit   critDisk
	return

Check_dev:
	MOV	AX,error_access_denied	; Assume error

	PUSH	DS			      ;PTM.				;AN000;
	LDS	SI,[ss:DMAADD]		      ;PTM.  chek if source a dir	;AN000;
	ADD	SI,find_buf.find_buf_attr	      ;PTM.				;AN000;
	TEST	[SI+dir_entry.dir_attr],attr_directory  ;PTM.				;AN000;
	JZ	notdir			      ;PTM.				;AN000;
	MOV	SI,[ss:REN_WFP]		      ;PTM.  if yes, make sure path	;AN000;
	invoke	Check_PathLen2		      ;PTM.   length < 67		;AN000;
notdir:
	POP	DS			      ;PTM.				;AN000;
	JA	GOTERR			      ;PTM.				;AN000;

	CMP	byte [ss:Found_dev],0
	JNZ	GOTERR
; At this point a source has been found.  There is search continuation info (a
; la DOS_SEARCH_NEXT) for the source at RENAMEDMA, together with the first
; directory entry found.
; [THISCDS], [THISDPB], and [THISDRV] are set and will remain correct
; throughout the RENAME since it is known at this point that the source and
; destination are both on the same device.
; [SATTRIB] is also set.
	MOV	SI,BX
	ADD	SI,dir_entry.dir_first
	invoke	REN_DEL_Check
	JNC	REN_OK1
	MOV	AX,error_sharing_violation
	JMP	RENAME_POP

REN_OK1:				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke	FastOpen_Delete 	; delete dir info in fastopen DOS 3.3
	MOV	SI,[ss:REN_WFP]		; Swap source and destination
	MOV	[ss:WFP_START],SI
	MOV	word [ss:CURR_DIR_END],-1	; No current dir on dest
	MOV	word [ss:CREATING],0E5FFH  ; Creating, not DEL *.*
					; A rename is like a CREATE_NEW as far
					; as the destination is concerned.
	invoke	GetPathNoSet
;   If this Getpath fails due to file not found, we know all renames will work
;   since no files match the destination name.	If it fails for any other
;   reason, the rename fails on a path not found, or whatever (also fails if
;   we find a device or directory).  If the Getpath succeeds, we aren't sure
;   if the rename should fail because we haven't built an explicit name by
;   substituting for the meta chars in it.  In this case the destination file
;   spec with metas is in [NAME1] and the explicit source name is at RENAMEDMA
;   in the directory entry part.
	JC	NODEST
;;	JZ	BAD_ACC_RENAME 		; Dest string is a directory		;AC000;
	OR	AH,AH			; Device?
	JNS	SAVEDEST		; No, continue
BAD_ACC_RENAME:
	MOV	AX,error_access_denied
	STC
RENAME_CLEAN:
	PUSHF				; Save carry state
	PUSH	AX			; and error code (if carry set)
	MOV	AL,[ss:THISDRV]
	invoke	FlushBuf
	POP	AX
	CMP	byte [ss:FAILERR],0
	JNZ	BAD_ERR 		; User FAILed to I 24
	POPF
	JMP	RENAME_POP

BAD_ERR:
	POP	AX			; Saved flags
	MOV	AX,error_path_not_found
	JMP	GOTERR

NODEST:
	JNZ	BAD_PATH
	CMP	byte [ss:FAILERR],0
	JNZ	BAD_PATH	; Search for dest failed because user FAILed on
				;	I 24
	OR	CL,CL
	JNZ	SAVEDEST
BAD_PATH:
	MOV	AX,error_path_not_found
	STC
	JMP	RENAME_POP

SAVEDEST:
	Context ES
	MOV	DI,NAME2
	MOV	SI,NAME1
	MOV	CX,11
	REP	MOVSB			; Save dest with metas at NAME2
	MOV	AX,[ss:DIRSTART]
	MOV	[ss:DESTSTART],AX
BUILDDEST:
	Context ES			; needed due to JMP BUILDDEST below
	MOV	BX,RENAMEDMA+21   ; Source of replace chars
	MOV	DI,NAME1    ; Real dest name goes here
	MOV	SI,NAME2    ; Raw dest
	MOV	CX,11
	CALL	NEW_RENAME		    ;IFS. replace ? chars		;AN000;

	MOV	byte [ss:ATTRIB],attr_all	; Stop duplicates with any attributes
	MOV	byte [ss:CREATING],0FFH
	invoke	DEVNAME 		; Check if we built a device name
;	ASSUME	ES:NOTHING
	JNC	BAD_ACC_RENAME
	MOV	BX,[ss:DESTSTART]
	LES	BP,[ss:THISDPB]
	invoke	SETDIRSRCH		; Reset search to start of dir
	JC	BAD_ACC_RENAME 		; Screw up
	invoke	FindEntry		; See if new name already exists
	JNC	BAD_ACC_RENAME 		; Error if found
	CMP	byte [ss:FAILERR],0
	JNZ	BAD_ACCJ		; Find failed because user FAILed to I 24
	MOV	AX,[ss:DESTSTART]		; DIRSTART of dest
	CMP	AX,word [RENAMEDMA + 15]	; DIRSTART of source
	JZ	SIMPLE_RENAME		; If =, just give new name

	MOV	AL,[RENAMEDMA + 21 + dir_entry.dir_attr]
	TEST	AL,attr_directory
	JNZ	BAD_ACCJ		; Can only do a simple rename on dirs,
					; otherwise the .  and ..  entries get
					; wiped.
	MOV	[ss:ATTRIB],AL
	MOV	word [ss:THISSFT+2],DS
	MOV	SI,AuxStack - sizeof.sf_entry
	MOV	word [ss:THISSFT],SI
	MOV	[SI+sf_entry.sf_mode],sharing_compat+open_for_both
	XOR	CX,CX			; Set "device ID" for call into makenode
	invoke	RENAME_MAKE		; This is in mknode
	JNC	GOT_DEST
BAD_ACCJ:
	JMP	BAD_ACC_RENAME

GOT_DEST:
	SaveReg <BX>
	LES	DI,[ss:THISSFT]		; Rename_make entered this into sharing
	Invoke	ShareEnd		; we need to remove it.
	RestoreReg  <BX>
; A zero length entry with the correct new name has now been made at
;   [CURBUF+2]:BX.
	LES	DI,[ss:CURBUF]
	Assert	ISBUF,<ES,DI>,"Got_Dest"

	TEST	[es:DI+BUFFINFO.buf_flags],buf_dirty  ;LB. if already dirty		;AN000;
	JNZ	yesdirty_RENAME		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	[es:DI+BUFFINFO.buf_flags],buf_dirty
yesdirty_RENAME:
	MOV	DI,BX
	ADD	DI,dir_entry.dir_attr		; Skip name
	MOV	SI,RENAMEDMA+21 + dir_entry.dir_attr
	MOV	CX,(sizeof.dir_entry) - dir_entry.dir_attr
	REP	MOVSB
	CALL	GET_SOURCE
	JC	RENAME_OVER
	MOV	DI,BX
	MOV	ES,word [ss:CURBUF+2]
	MOV	AL,0E5H
	STOSB				; "free" the source
	JMP	SHORT DIRTY_IT

SIMPLE_RENAME:
	CALL	GET_SOURCE		; Get the source back
	JC	RENAME_OVER
	MOV	DI,BX
	MOV	ES,word [ss:CURBUF+2]
	MOV	SI,NAME1    ; New Name
	MOV	CX,11
	REP	MOVSB
DIRTY_IT:
	MOV	DI,word [ss:CURBUF]

	TEST	[es:DI+BUFFINFO.buf_flags],buf_dirty  ;LB. if already dirty		;AN000;
	JNZ	yesdirty2_RENAME		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	[es:DI+BUFFINFO.buf_flags],buf_dirty
yesdirty2_RENAME:
	Assert	ISBUF,<ES,DI>,"Dirty_it"
NEXT_SOURCE:
	MOV	SI,RENAMEDMA+1    ;Name
;
; WARNING!  Rename_Next leaves the disk critical section *ALWAYS*.  We need
; to enter it before going to RENAME_Next.
;
	EnterCrit   critDisk
	MOV	byte [ss:CREATING],0	; Correct setting for search (we changed it
				;   to FF when we made the prev new file).
	invoke	RENAME_NEXT
;
; Note, now, that we have exited the previous ENTER and so are back to where
; we were before.
;
	JC	RENAME_OVER
	LEA	SI,[BX+dir_entry.dir_first]
	invoke	REN_DEL_Check
	JNC	REN_OK2
	MOV	AX,error_sharing_violation
	JMP	RENAME_CLEAN

REN_OK2:				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	invoke	FastOpen_Delete 	; delete dir info in fastopen DOS 3.3
	JMP	BUILDDEST

RENAME_OVER:
	CLC
	JMP	RENAME_CLEAN

; Inputs:
;	RENAMEDMA has source info
; Function:
;	Re-find the source
; Output:
;	[CURBUF] set
;	[CURBUF+2]:BX points to entry
;	Carry set if error (currently user FAILed to I 24)
; DS preserved, others destroyed

GET_SOURCE:
	DOSAssume   CS,<DS>,"Get_Source"
;	ASSUME	ES:NOTHING

	MOV	BX,word [RENAMEDMA + 15]	; DirStart
	LES	BP,[ss:THISDPB]
	invoke	SETDIRSRCH
	retc
	invoke	StartSrch
	MOV	AX,word [RENAMEDMA + 13]	; Lastent
	invoke	GETENT
	return

EndProc DOS_RENAME

;Input: DS:SI -> raw string with ?
;	ES:DI -> destination string
;	DS:BX -> source string
;Function: replace ? chars of raw string with chars in source string and
;	   put in destination string
;Output: ES:DI-> new string



	procedure   NEW_RENAME,NEAR
	DOSAssume   CS,<DS>,"DOS_Rename"
;	ASSUME	ES:NOTHING
NEWNAM:
	LODSB
	CMP	AL,"?"
	JNZ	NOCHG
	MOV	AL,[BX] 		; Get replace char
NOCHG:
	STOSB
	INC	BX			; Next replace char
	LOOP	NEWNAM
	return

EndProc NEW_RENAME

end if
;    END
