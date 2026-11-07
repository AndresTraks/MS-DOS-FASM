;

;
;*****************************************************************************
; Macro's
;*****************************************************************************
;


macro Define_Msg Message_Name
{
						;
Create_Msg Message_Name,Message_Number,Handle,Sublist,Count,Class,Function,Input;AN000;
						;
} ;				;AN000;

;-----------------------------------------------------------------------------

macro Create_Msg Parm1,Parm2,Parm3,Parm4,Parm5,Parm6,Parm7,Parm8
{

;Public	Parm1
label Parm1 word    ;				;AN000;
	dw	Parm2				;				;AN000;
	dw	Parm3				;				;AN000;
	dw	Parm4				;				;AN000;
	dw	Parm5				;				;AN000;
	db	Parm6				;				;AN000;
	db	Parm7				;				;AN000;
	dw	Parm8				;				;AN000;
} ;				;AN000;


;
;*****************************************************************************
; External data declarations
;*****************************************************************************
;

;	Extrn	DriveLetter:Byte
;	Extrn	SystemDriveLetter:Byte
;	Extrn	CurrentHead:Byte
;	Extrn	CurrentCylinder:Word
;	Extrn	FdskSiz:Word
;	Extrn	SysSiz:Word
;	Extrn	BadSiz:Word
;	Extrn	DataSiz:Word
;	Extrn	Drive_Letter_Msg:Byte
;	Extrn	PercentComplete:Byte
;	Extrn	AllocSize:Dword
;	Extrn	AllocNum:Word
;	Extrn	Serial_Num_Low:Word
;	Extrn	Serial_Num_High:Word
;	Extrn	Command_Old_Ptr:Word
;	Extrn	Msg_Allocation_Unit_Val:Dword

;
;*****************************************************************************
; Publics
;*****************************************************************************
;



;
;*****************************************************************************
; Message Retriever equates
;*****************************************************************************
;

Format_Msg		equ	'C'

N_A			equ	0
Sublist_Length		equ	11
None			equ	0

Blank			equ	" "
No_Function		equ	0
No_Replace		equ	0

Msg_Ser_Class		equ	0
Ext_Err_Class		equ	1
Parse_Err_Class 	equ	2
Utility_Msg_Class	equ	0FFh

Reserved		equ	0




if SEGSEL = S_DATA
;	assume	ds:data


;
;*****************************************************************************
; Message Sublist Tables
;*****************************************************************************
;
;The  following  control  blocks  are	used   for   messages  with
;replaceable  paramaters.  These  control  blocks  are	used by  the
;SysDispMsg routine.
;

;---------------------------			;
label Sublist_msgCurrentTrack dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		PercentComplete        ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Unsgn_Bin_Word ;				 ;AN000;
	db		3			;Max % is 100			;AN000;
	db		3			;Min % is 0			;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgInsertDisk dword  ;				;AN000;
label Sublist_msgReInsertDisk dword  ;				;AN000;
label Sublist_MsgHardDiskWarning dword  ;
label Sublist_msgFormatNotSupported dword ;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		driveLetter        ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_Char ;			   ;AN000;
	db		1			;				;AN000;
	db		1			;				;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgInsertDOSDisk dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		systemDriveLetter       ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_Char ;				;AN000;
	db		1			;				;AN000;
	db		1			;				;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgTotalDiskSpace dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		fdsksiz         ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Unsgn_Bin_DWord ;				 ;AN000;
	db		10			;				;AN000;
	db		10			;4,000,000,000 limit		;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgSystemSpace dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		syssiz         ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Unsgn_Bin_DWord ;			   ;AN000;
	db		10			;				;AN000;
	db		10			;64k*3 max			;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgBadSpace dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		badsiz         ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Unsgn_Bin_DWord ;			   ;AN000;
	db		10			;				;AN000;
	db		10			;4,000,000,000 max		;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgDataSpace dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		datasiz         ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Unsgn_Bin_DWord ;			   ;AN000;
	db		10			;				;AN000;
	db		10			;4,000,000,000 max		;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgWhatIsVolumeId? dword   ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		driveLetter        ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_Char ;				;AN000;
	db		1			;				;AN000;
	db		1			;				;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgEXECFailure dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		Drive_Letter_Msg	;						;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;				;AN000;
	db		2			;				;AN000;
	db		2			;				;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgAllocNum dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		AllocNum         ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Unsgn_Bin_Word ;				;AN000;
	db		10			;				;AN000;
	db		10			;				;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgAllocSize dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		AllocSize        ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Unsgn_Bin_DWord ;				  ;AN000;
	db		10			;				;AN000;
	db		10			;				;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_msgSerialNumber dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		Serial_Num_Low        ;				;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Bin_Hex_Word ;				;AN000;
	db		4			;				;AN000;
	db		4			;				;AN000;
	db		'0'                     ;Display leading 0's            ;AN000;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		Serial_Num_High        ;				;AN000;
	dw		data_			;				;AN000;
	db		2			;				;AN000;
	db		Right_Align+Bin_Hex_Word ;				;AN000;
	db		4			;				;AN000;
	db		4			;				;AN000;
	db		'0'                     ;                               ;AN000;

;Public	Sublist_MsgParse_Error
label Sublist_msgParse_Error dword       ;				;AN000;

	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		0			;				;AN000;
	dw		data_			;				;AN000;
	db		0			;				;AN000;
	db		Left_Align+Char_Field_ASCIIZ ;			   ;AN000;
	db		20			;				;AN000;
	db		01			;				;AN000;
	db		Blank			;				;AN000;
;---------------------------			;
label Sublist_MsgVerify dword  ;				;AN000;
						;
	db		Sublist_Length		;				;AN000;
	db		Reserved		;				;AN000;
	dw		Msg_Allocation_Unit_Val       ; 			;AN000;
	dw		data_			;				;AN000;
	db		1			;				;AN000;
	db		Right_Align+Unsgn_Bin_DWord;				;AN000;
	db		8			;				;AN000;
	db		8			;				;AN000;
	db		Blank
;
;*****************************************************************************
; Message Description Tables
;*****************************************************************************
;

;---------------------- 			;
Message_Number	= 1				;				;AN000;
Handle		= NO_HANDLE			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= NO_INPUT			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgBadDOSVersion	;				;AN000;
;---------------------- 			;
Message_Number	= 2				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgCurrentTrack	;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= NO_INPUT			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgCurrentTrack 	;				;AN000;
;---------------------- 			;
Message_Number	= 3				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgDataSpace		;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgDataSpace		;				;AN000;
;---------------------- 			;
Message_Number	= 4				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= NO_INPUT			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgFormatComplete	;				;AN000;
;---------------------- 			;
Message_Number	= 5				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgBadSpace		;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgBadSpace		;				;AN000;
;---------------------- 			;
Message_Number	= 6				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgTotalDiskSpace	;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgTotalDiskSpace	;				;AN000;
;---------------------- 			;
Message_Number	= 7				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgInsertDisk 	;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgInsertDisk		;				;AN000;
;---------------------- 			;
Message_Number	= 8				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgSystemSpace	;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgSystemSpace		;				;AN000;
;---------------------- 			;
Message_Number	= 9				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgReInsertDisk	;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg   msgReInsertDisk		;				;AN000;
;---------------------- 			;
Message_Number	= 10				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgLabelPrompt		;				;AN000;
;---------------------- 			;
Message_Number	= 11				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgFormatNotSupported ;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgFormatNotSupported	;				;AN000;
;---------------------- 			;
Message_Number	= 12				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgInvalidDeviceParameters;				;AN000;
;---------------------- 			;
Message_Number	= 13				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgErrorInIOCTL 	;				;AN000;
;---------------------- 			;
Message_Number	= 14				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgNotBlockDevice	;				;AN000;
;---------------------- 			;
Message_Number	= 15				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgFATwriteError	;				;AN000;
;---------------------- 			;
Message_Number	= 16				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgDirectoryWriteError	;				;AN000;
;---------------------- 			;
Message_Number	= 17				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgAssignedDrive	;				;AN000;
;---------------------- 			;
Message_Number	= 18				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgNoSystemFiles	;				;AN000;
;---------------------- 			;
Message_Number	= 19				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgNetDrive		;				;AN000;
;---------------------- 			;
Message_Number	= 20				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgBadCharacters	;				;AN000;
;---------------------- 			;
Message_Number	= 21				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgParametersNotSupported ;				;AN000;
;---------------------- 			;
Message_Number	= 22				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgFormatFailure	;				;AN000;
;---------------------- 			;
Message_Number	= 23				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgNotSystemDisk	;				;AN000;
;---------------------- 			;
Message_Number	= 24				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgDiskUnusable 	;				;AN000;
;---------------------- 			;
Message_Number	= 25				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgBootWriteError	;				;AN000;
;---------------------- 			;
Message_Number	= 26				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgDirectoryReadError	;				;AN000;
;---------------------- 			;
Message_Number	= 27				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgNeedDrive		;				;AN000;
;---------------------- 			;
Message_Number	= 28				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	ContinueMsg		;				;AN000;
;---------------------- 			;
Message_Number	= 29				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgBadVolumeId		;				;AN000;
;---------------------- 			;
Message_Number	= 30				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= NO_INPUT			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgSystemTransfered	;				;AN000;
;---------------------- 			;
Message_Number	= 31				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgWhatIsVolumeId?	;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgWhatIsVolumeId?	;				;AN000;
;---------------------- 			;
Message_Number	= 32				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgIncompatibleParametersForHardDisk ;			;AN000;
;---------------------- 			;

Message_Number	= 33				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgWriteProtected	;				;AN000;
;---------------------- 			;
Message_Number	= 34				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgNotReady		;				;AN000;
;---------------------- 			;

Message_Number	= 35				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgPartitionTableReadErr ;				;AN000;
;---------------------- 			;
Message_Number	= 36				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgSerialNumber	;				;AN000;
Count		= 2				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgSerialNumber 	;			      ;AN000;
;---------------------- 			;
Message_Number	= 37				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgFormatBroken 	;				;AN000;
;---------------------- 			;
Message_Number	= 38				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgEXECFailure	;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgEXECFailure		;				;AN000;
;---------------------- 			;
Message_Number	= 39				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	NO_SYS_MESS		;				;AN000;
;---------------------- 			;
Message_Number	= 40				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgbadpartitiontable	;				;AN000;
;---------------------- 			;
Message_Number	= 41				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgParametersNotSupportedByDrive ;			;AN000;
;---------------------- 			;
Message_Number	= 42				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgCRLF 		;				;AN000;
;---------------------- 			;
Message_Number	= 43				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgInterrupt		;				;AN000;
;---------------------- 			;
Message_Number	= 44				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgInsertDOSDisk	;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgInsertDOSDisk	;				;AN000;
;---------------------- 			;
Message_Number	= 45				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_MsgHardDiskWarning	;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgHardDiskWarning	;				;AN000;
;---------------------- 			;
Message_Number	= 46				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgFormatAnother?	;				;AN000;
;---------------------- 			;
Message_Number	= 47				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgPartitionTableReadError ;				;AN000;
;---------------------- 			;
Message_Number	= 48				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgPartitionTableWriteError ;				;AN000;
;---------------------- 			;
Message_Number	= 49				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgIncompatibleParameters ;				;AN000;
;---------------------- 			;
Message_Number	= 50				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgAllocNum		;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgAllocNum		;				;AN000;
;---------------------- 			;
Message_Number	= 51				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= Sublist_msgAllocSize		;				;AN000;
Count		= 1				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgAllocSize		;				;AN000;
;---------------------- 			;
Message_Number	= 52				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgPartitionTableWriteErr ;				;AN000;
;---------------------- 			;
Message_Number	= 53				;				;AN002;
Handle		= StdOut			;				;AN002;
Sublist 	= No_Replace			;				;AN002;
Count		= N_A				;				;AN002;
Class		= Utility_Msg_Class		;				;AN002;
Function	= No_Function			;				;AN002;
Input		= N_A				;				;AN002;
	Define_Msg	msgSameSwitch		;				;AN002;
;---------------------- 			;
Message_Number	= 54				;				;AN009;
Handle		= StdOut			;				;AN009;
Sublist 	= No_Replace			;				;AN009;
Count		= N_A				;				;AN009;
Class		= Utility_Msg_Class		;				;AN009;
Function	= No_Function			;				;AN009;
Input		= N_A				;				;AN009;
	Define_Msg	msgBad_T_N		;				;AN009;
;---------------------- 			;
Message_Number	= 55				;				;an019; dms;
Handle		= StdOut			;				;an019; dms;
Sublist 	= Sublist_MsgVerify		;				;an019; dms;
Count		= 1				;				;an019; dms;
Class		= Utility_Msg_Class		;				;an019; dms;
Function	= No_Function			;				;an019; dms;
Input		= N_A				;				;an019; dms;
	Define_Msg	MsgVerify		;				;an019; dms;
;---------------------- 			;
Message_Number	= 0				;				;AN000;
Handle		= StdErr			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Ext_Err_Class 		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	Extended_Error_Msg	;				;AN000;
;----------------------
Message_Number	= 0				;				;AN000;
Handle		= StdErr			;				;AN000;
Sublist 	= Sublist_msgParse_Error	;				;AN000;
Count		= 1				;				;AN000;
Class		= Parse_Err_Class		;				;AN000;
Function	= No_Function			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	Parse_Error_Msg 	;				;AN000;
;-----------------------



;
;These need to be coded as extended an parse errors, but left here to link.
;



Message_Number	= 70				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= NO_INPUT			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgOutOfMemory		;				;AN000;
;---------------------- 			;
Message_Number	= 71				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= NO_INPUT			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgBadDrive		;				;AN000;
;---------------------- 			;
Message_Number	= 10				;				;AN000;
Handle		= StdErr			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Parse_Err_Class		;				;AN000;
Function	= NO_INPUT			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgInvalidParameter	;				;AN000;
;---------------------- 			;
Message_Number	= 73				;				;AN000;
Handle		= StdOut			;				;AN000;
Sublist 	= No_Replace			;				;AN000;
Count		= N_A				;				;AN000;
Class		= Utility_Msg_Class		;				;AN000;
Function	= NO_INPUT			;				;AN000;
Input		= N_A				;				;AN000;
	Define_Msg	msgLoadFailure		;				;AN000;









end if


