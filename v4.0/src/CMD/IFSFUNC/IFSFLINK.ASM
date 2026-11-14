	PAGE	,132				; 
;	SCCSID = @(#)ifsflink.asm 1.0 87/05/11
TITLE	IFSFUNC LINK FIX ROUTINES - Routines to resolve ifsfunc externals
name	IFSFLINK

.xlist
.xcref
include 'DOSSYM.INC'
include 'DEVSYM.INC'
.cref
.list

if SEGSEL = S_CODE
end if

include 'DOSSEG.ASM'

if SEGSEL = S_CODE
;	ASSUME	CS:dosgroup

	procedure OUTT,FAR
	entry	DUP$
	entry	MSG_RETRIEVAL
	entry	ECS_call$
	entry	Extended_Open$
	entry	FastInit
	entry	IFS_IOCTL$
	entry	IFS_DOSCALL
	entry	QUERY_DOS_VALUE$
	entry	STD_AUX_INPUT$,FAR
	entry	LcritDevice,FAR
	entry	ABORT$,FAR
	entry	SET_TIME$,FAR
	entry	ALLOC$,FAR
	entry	SETMEM,FAR
	entry	SKIPONE,FAR
	entry	SET_DMA$,FAR
	entry	PARSE_FILE_DESCRIPTOR$,FAR
	entry	CreateTempFile$,FAR
	entry	SLEAZEFUNCDL$,FAR
	entry	CHDIR$,FAR
	entry	TwoEsc,FAR
	entry	GET_INTERRUPT_VECTOR$,FAR
	entry	FCB_Seq_Write$,FAR
	entry	DEVNAME,FAR
	entry	GET_DEFAULT_DRIVE$,FAR
	entry	STD_CON_STRING_INPUT$,FAR
	entry	Close$,FAR
	entry	RAW_CON_IO$,FAR
	entry	INTERNATIONAL$,FAR
	entry	Idle,FAR
	entry	STD_CON_INPUT_NO_ECHO$,FAR
	entry	AssignOper$,FAR
	entry	LockOper$,FAR
	entry	FCB_Close$,FAR
	entry	STD_CON_STRING_OUTPUT$,FAR
	entry	Dup_PDB$,FAR
	entry	GETCH,FAR
	entry	StrLen,FAR
	entry	InitCDS,FAR
	entry	COPYONE,FAR
	entry	pJFNFromHandle,FAR
	entry	GET_VERIFY_ON_WRITE$,FAR
	entry	Keep_process$,FAR
	entry	StrCmp,FAR
	entry	SET_INTERRUPT_VECTOR$,FAR
	entry	FCB_Delete$,FAR
	entry	RAW_CON_INPUT$,FAR
	entry	RENAME$,FAR
	entry	FIND_FIRST$,FAR
	entry	FCB_Random_Write$,FAR
	entry	SET_DEFAULT_DRIVE$,FAR
	entry	SETDPB$,FAR
	entry	STD_PRINTER_OUTPUT$,FAR
	entry	MKDIR$,FAR
	entry	Dup2$,FAR
	entry	SET_SFT_MODE,FAR
	entry	GET_DATE$,FAR
	entry	FCB_Rename$,FAR
	entry	CREATE_PROCESS_DATA_BLOCK$,FAR
	entry	Creat$,FAR
	entry	EcritDisk,FAR
	entry	PLACEBUF,FAR
	entry	IOCTL$,FAR
	entry	READ$,FAR
	entry	PATHCHRCMP,FAR
	entry	GET_VERSION$,FAR
	entry	COPYLIN,FAR
	entry	LcritDisk,FAR
	entry	LSEEK$,FAR
	entry	StrCpy,FAR
	entry	File_Times$,FAR
	entry	BackSp,FAR
	entry	SET_VERIFY_ON_WRITE$,FAR
	entry	SETYEAR,FAR
	entry	FastRet,FAR
	entry	RMDIR$,FAR
	entry	DIVOV,FAR
	entry	Get_FCB_Position$,FAR
	entry	DISK_RESET$,FAR
	entry	DIR_SEARCH_FIRST$,FAR
	entry	WAIT$,FAR
	entry	FASTOPENCOM,FAR
	entry	Stay_resident,FAR
	entry	AllocOper$,FAR
	entry	GET_DEFAULT_DPB$,FAR
	entry	DStrLen,FAR
	entry	CTRLZ,FAR
	entry	UserOper$,FAR
	entry	SET_DATE$,FAR
	entry	FCB_Random_Write_Block$,FAR
	entry	EXITINS,FAR
	entry	GET_IN_VARS$,FAR
	entry	GetDevList,FAR
	entry	DATE16,FAR
	entry	PointComp,FAR
	entry	SFFromSFN,FAR
	entry	SKIPSTR,FAR
	entry	FREE_SFT,FAR
	entry	SHARE_ERROR,FAR
	entry	NLS_IOCTL,FAR
	entry	CURRENT_DIR$,FAR
	entry	FCB_Create$,FAR
	entry	WRITE$,FAR
	entry	GET_INDOS_FLAG$,FAR
	entry	RECSET,FAR
	entry	CreateNewFile$,FAR
	entry	STD_CON_INPUT_STATUS$,FAR
	entry	REEDIT,FAR
	entry	GetThisDrv,FAR
	entry	DSUM,FAR
	entry	GetExtendedError$,FAR
	entry	ExtHandle$,FAR
	entry	NameTrans$,FAR
	entry	NLS_LSEEK,FAR
	entry	ScanPlace,FAR
	entry	GetCDSFromDrv,FAR
	entry	DSLIDE,FAR
	entry	uCase,FAR
	entry	STD_CON_OUTPUT$,FAR
	entry	FCB_Random_Read_Block$,FAR
	entry	CHECKFLUSH,FAR
	entry	CopyStr,FAR
	entry	GetSetCdPg$,FAR
	entry	DIR_SEARCH_NEXT$,FAR
	entry	Open$,FAR
	entry	SKIPVISIT,FAR
	entry	Exec$,FAR
	entry	DEALLOC$,FAR
	entry	DOS_CLOSE,FAR
	entry	STD_CON_INPUT$,FAR
	entry	NLS_GETEXT,FAR
	entry	BufWrite,FAR
	entry	GET_TIME$,FAR
	entry	SLEAZEFUNC$,FAR
	entry	CHAR_OPER$,FAR
	entry	NET_I24_ENTRY,FAR
	entry	Commit$,FAR
	entry	SETBLOCK$,FAR
	entry	FCB_Open$,FAR
	entry	NLS_OPEN,FAR
	entry	GET_DMA$,FAR
	entry	UNLINK$,FAR
	entry	FCB_Seq_Read$,FAR
	entry	STD_CON_INPUT_FLUSH$,FAR
	entry	GET_DRIVE_FREESPACE$,FAR
	entry	DriveFromText,FAR
	entry	GetExtCntry$,FAR
	entry	SETVISIT,FAR
	entry	EXIT$,FAR
	entry	STD_AUX_OUTPUT$,FAR
	entry	KILNEW,FAR
	entry	CHMOD$,FAR
	entry	FCB_Random_Read$,FAR
	entry	SHARE_VIOLATION,FAR
	entry	EcritDevice,FAR
	entry	GET_DPB$,FAR
	entry	FIND_NEXT$,FAR
	entry	Get_FCB_File_Length$,FAR
	entry	ENTERINS,FAR
	entry	DEVIOCALL2,FAR
	entry	ServerCall$,FAR
	entry	GSetMediaID$,FAR
	entry	FETCHI_CHECK,FAR
	entry	TableDispatch,FAR
	entry	DSKSTATCHK,FAR
	entry	SET_RQ_SC_PARMS,FAR
	entry	SAVE_MAP,FAR
	entry	RESTORE_MAP,FAR
	entry	DskRead,FAR
	entry	Fast_Dispatch,FAR
	entry	DSKWRITE,FAR
	entry	intCNE0,FAR
	entry	SHARE_INSTALL,FAR							 ;P3568
	entry	Fake_version,FAR							 ;D503
	NOP
EndProc OUTT

end if
;    END


