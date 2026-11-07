page   84,132
;
;	SCCSID = @(#)format.asm 1.26 85/10/20
;	SCCSID = @(#)format.asm 1.26 85/10/20
;***************************************************************
;
;	86-DOS FORMAT DISK UTILITY
;
;	This routine formats a new disk,clears the FAT and DIRECTORY then
;	optionally copies the SYSTEM and COMMAND.COM to this new disk
;
;	SYNTAX: FORMAT	[drive][/switch1][/switch2]...[/switch16]
;
;	Regardless of the drive designator , the user will be prompted to
;	insert the diskette to be formatted.
;
;***************************************************************

;	    5/12/82 ARR Mod to ask for volume ID
;	    5/19/82 ARR Fixed rounding bug in CLUSCAL:
;   REV 1.5
;	    Added rev number message
;	    Added dir attribute to DELALL FCB
;   REV 2.00
;	    Redone for 2.0
;   REV 2.10
;	    5/1/83 ARR Re-do to transfer system on small memory systems
;   REV 2.20
;	    6/17/83 system size re-initialization bug -- mjb001
;   Rev 2.25
;	    8/31/83 16-bit fat insertion
;   Rev 2.26
;	    11/2/83 MZ fix signed compare problems for bad sectors
;   Rev 2.27
;	    11/8/83 EE current directories are always saved and restored
;   Rev 2.28
;	    11/9/83 NP Printf and changed to an .EXE file
;   Rev 2.29
;	    11/11/83 ARR Fixed ASSIGN detection to use NameTrans call to see
;			if drive letter remapped. No longer IBM only
;   Rev 2.30
;	    11/13/83 ARR SS does NOT = CS, so all use of BP needs CS override
;   Rev 2.31
;	    12/27/83 ARR REP STOSB instruction at Clean: changed to be
;			sure ES = CS.




if SEGSEL = S_CODE
end if



if SEGSEL = S_DATA
end if

if SEGSEL = S_END_OF_MEMORY
end if


if SEGSEL = S_CODE

;	assume	cs:code,ds:nothing,es:nothing

;-------------------------------------------------------------------------------
; Define as public for debugging

; procedures
;	public	GetSize
;	public	AddToSystemSize
;	public	Phase1Initialisation
;	public	SetStartSector
;	public	SetfBigFat
;	public	Phase2Initialisation
;	public	DiskFormat
;	public	BadSector
;	public	DisplayCurrentTrack
;	public	WriteFileSystem
;	public	Done
;	public	CurrentLogicalSector
;	public	PrintErrorAbort
;	public	GetDeviceParameters
;	public	SetDeviceParameters
;	public	Multiply_32_Bits

;	public	START
;	public	FatAllocated
;	public	MEMERRJ
;	public	MEM_OK
;	public	RDFRST
;	public	NEEDSYS
;	public	INITCALL
;	public	SWITCHCHK
;	public	SYSLOOP
;	public	FRMTPROB
;	public	GETTRK
;	public	TRKFND
;	public	CLRTEST
;	public	CMPTRKS
;	public	BadClus
;	public	DoBig
;	public	DoSet
;	public	DRTFAT
;	public	CLEARED
;	public	LOUSE
;	public	LOUSEP
;	public	FATWRT
;	public	SYSOK
;	public	STATUS
;	public	REPORTC
;	public	ONCLUS
;	public	MORE
;	public	FEXIT
;	public	SYSPRM
;	public	fexitJ
;	public	DoPrompt
;	public	TARGPRM
;	public	IsRemovable
;	public	CheckRemove
;	public	IsRemove
;	public	NotRemove
;	public	DSKPRM
;	public	GOPRNIT
;	public	crlf
;	public	PrintString
;	public	std_printf
;	public	READDOS
;	public	RDFILS
;	public	FILESDONE
;	public	CLSALL
;	public	GOTBIOS
;	public	GOTDOS
;	public	CLSALLJ
;	public	GOTCOM
;	public	WRITEDOS
;	public	GOTALLBIO
;	public	BIOSDONE
;	public	GOTNDOS
;	public	PARTDOS
;	public	GOTALLDOS
;	public	DOSDONE
;	public	PARTCOM
;	public	GOTALLCOM
;	public	COMDONE
;	public	MAKEFIL
;	public	CheckMany
;	public	CLOSETARG
;	public	IOLOOP
;	public	GOTTARG
;	public	GSYS
;	public	TESTSYS
;	public	GETOFFS
;	public	TESTSYSDISK		; dcl 8/23/86
;	public	SETBIOS
;	public	BIOSCLS
;	public	SETBIOSSIZ
;	public	DOSOPNOK
;	public	DOSCLS
;	public	SETDOSSIZ
;	public	GotComHand
;	public	COMCLS
;	public	SETCOMSIZ
;	public	GETFSIZ
;	public	READFILE
;	public	WRITEFILE
;	public	FILIO
;	public	NORMIO
;	public	IORETP
;	public	IORET
;	public	NORMALIZE
;	public	GotDeviceParameters
;	public	LoadSectorTable
;	public	NotBigTotalSectors
;	public	NotBig
;	public	FormatLoop
;	public	FormatDone
;	public	ContinueFormat
;	public	ReportBadTrack
;	public	NoMoreTracks
;	public	WriteDIRloop
;	public	Main_Routine
;	public	ControlC_Handler

; bytes
;	public	fBigFat
;	public	formatError
;	public	ROOTSTR
;	public	DBLFLG
;	public	DRIVE
;	public	FILSTAT
;	public	USERDIRS
;	public	VOLFCB
;	public	VOLNAM
;	public	TRANSRC
;	public	TRANDST
;	public	INBUFF
;	public	driveLetter
;	public	systemDriveLetter
;	public	CommandFile
;	public	ExitStatus
;	public	VolDrive
;	public	DelFCB
;	public	DelDrive

; words
;	public	startSector
;	public	fatSpace
;	public	firstHead
;	public	firstCylinder
;	public	tracksLeft
;	public	tracksPerDisk
;	public	sectorsInRootDirectory
;	public	directorySector
;	public	printStringPointer
;	public	MSTART
;	public	MSIZE
;	public	TempHandle
;	public	BEGSEG
;	public	SWITCHMAP
;	public	SWITCHCOPY
;	public	FAT
;	public	CLUSSIZ
;	public	SECSIZ
;	public	SYSTRKS
;	public	SECTORS
;	public	currentHead
;	public	currentCylinder
;	public	PercentComplete
;	public	Formatted_Tracks_High
;	public	Formatted_Tracks_Low

; other
;	public	deviceParameters
;	public	Disk_Access
;	public	formatPacket
;-------------------------------------------------------------------------------

end if
if SEGSEL = S_DATA
;	extrn	msgAssignedDrive:byte
;	extrn	msgBadDosVersion:byte
;	extrn	msgDirectoryWriteError:byte
;	extrn	msgFormatComplete:byte
;	extrn	msgFormatNotSupported:byte
;	extrn	msgFATwriteError:byte
;	extrn	msgInvalidDeviceParameters:byte
;	extrn	msgLabelPrompt:byte
;	extrn	msgNeedDrive:byte
;	extrn	msgNoSystemFiles:byte
;	extrn	msgNetDrive:byte
;	extrn	msgInsertDisk:byte
;	extrn	msgHardDiskWarning:byte
;	extrn	msgSystemTransfered:byte
;	extrn	msgFormatAnother?:byte
;	extrn	msgBadCharacters:byte
;	extrn	msgBadDrive:byte
;	extrn	msgInvalidParameter:byte
;	extrn	msgParametersNotSupported:byte
;	extrn	msgReInsertDisk:byte
;	extrn	msgInsertDosDisk:byte
;	extrn	msgFormatFailure:byte
;	extrn	ContinueMsg:Byte
;	extrn	msgNotSystemDisk:byte
;	extrn	msgDiskUnusable:byte
;	extrn	msgOutOfMemory:byte
;	extrn	msgCurrentTrack:byte
;	extrn	msgWriteProtected:byte
;	extrn	msgInterrupt:byte
;	extrn	msgCRLF:byte
;	extrn	Fatal_Error:Byte
;	extrn	Read_Write_Relative:Byte
;	extrn	PSP_Segment:Word
;	extrn	Parse_Error_Msg:Byte
;	extrn	Extended_Error_Msg:Byte
;	extrn	MsgVerify:Byte

end if
if SEGSEL = S_CODE


debug	equ	0
	.xlist
	include 'VERSIONA.INC'
	include 'DOSMAC.INC'
	include 'SYSCALL.INC'
	include 'ERROR.INC'
	include 'DPB.INC'
	include 'CPMFCB.INC'
	include 'DIRENT.INC'
	include 'CURDIR.INC'
	include 'PDB.INC'
	include 'BPB.INC'
	include 'FOREQU.INC'
	include 'FORMACRO.INC'
	include 'IOCTL.INC'
	include 'FORSWTCH.INC'
	include 'SYSVAR.INC'
	.list


;-------------------------------------------------------------------------------
; And this is the actual data

end if
if SEGSEL = S_DATA
;	public	deviceParameters
;	public	bios
;	public	dos
;	public	command
;	public	FAT_Flag

validSavedDeviceParameters db 0
savedDeviceParameters A_DEVICEPARAMETERS 
deviceParameters A_DEVICEPARAMETERS 

Disk_Access	A_DISKACCESS_CONTROL         ;an000; dms;

formatPacket A_FORMATPACKET 
RWPacket     A_TRACKREADWRITEPACKET 
RW_TRF_Area	db    512     dup(0)

startSector rw      1
fatSpace rd      1
fBigFat db	FALSE

firstHead rw      1
firstCylinder rw      1
tracksLeft rw      1
tracksPerDisk rw      1

Formatted_Tracks_Low dw 0
Formatted_Tracks_High dw 0


;public	NumSectors ,TrackCnt
NumSectors dw	0FFFFh
TrackCnt dw	0FFFFh
PercentComplete dw 0FFFFh			;Init non-zero so msg will display first time

;public	Old_Dir
Old_Dir db	FALSE

;public	fLastChance
fLastChance db	FALSE				; Flags reinvocation from
						;   LastChanceToSaveIt. Used by DSKPRM

sectorsInRootDirectory rw      1

directorySector dd 0

formatError db	0

printStringPointer dw 0

; Exit status defines
ExitStatus		db	0
ExitOK			equ	0
ExitCtrlC		equ	3
ExitFatal		equ	4
ExitNo			equ	5
ExitDriveNotReady	equ	6						;an017; dms;drive not ready error
ExitWriteProtect	equ	7						;an017; dms;write protect error

ROOTSTR rb      1
	DB	":\",0
DBLFLG	DB	0				;Initialize flags to zero
IOCNT	rd      1
MSTART	rw      1 ; Start of sys file buffer (para#)
MSIZE	rw      1 ; Size of above in paragraphs
TempHandle rw      1
FILSTAT rb      1 ; In memory status of files
						; XXXXXX00B BIOS not in
						; XXXXXX01B BIOS partly in
						; XXXXXX10B BIOS all in
						; XXXX00XXB DOS not in
						; XXXX01XXB DOS partly in
						; XXXX10XXB DOS all in
						; XX00XXXXB COMMAND not in
						; XX01XXXXB COMMAND partly in
						; XX10XXXXB COMMAND all in

USERDIRS rb      DIRSTRLEN+3    ; Storage for users current directory

Paras_Per_Fat	dw	0000h			;an000;holds fat para count
Fat_Init_Value	dw	0000h			;an000;initializes the FAT

bios	a_FileStructure 
BiosAttributes equ (attr_hidden + attr_system + attr_read_only)

dos	a_FileStructure 
DosAttributes equ (attr_hidden + attr_system + attr_read_only)

command a_FileStructure 
CommandAttributes EQU 0
CommandFile DB	"X:\COMMAND.COM",0
CommandFile_Buffer	DB	127	dup(0)	;an000;allow room for copy

Command_Com		DB	"COMMAND.COM",0

VOLFCB	DB	-1,0,0,0,0,0,8
VOLDRIVE DB	0
VOLNAM	DB	"           "
	DB	8
	rb      26

DelFCB	DB	-1,0,0,0,0,0,8
DelDRIVE DB	0
DelNAM	DB	"???????????"
	DB	8
	rb      26

TRANSRC DB	"A:CON",0,0			; Device so we don't hit the drive
TRANDST DB	"A:\",0,0,0,0,0,0,0,0,0,0

BEGSEG	rw      1
SWITCHMAP rw      1
SWITCHCOPY rw      1
FAT	rw      1
	DW	?
CLUSSIZ rw      1
SECSIZ	rw      1
SYSTRKS rw      1
SECTORS rw      1
INBUFF	DB	80,0
	rb      80


drive	db	0
driveLetter db	"x"
systemDriveLetter db "x"

CTRL_BREAK_VECTOR	rd      1 ;ac010; dms;Holds CTRL-Break
						;	    vector

Command_Path	rd      1 ;an011; dms;hold pointer to
						;	    COMMAND's path

Comspec_ID	db	"COMSPEC=",00		;an011; dms;Comspec target


Environ_Segment rw      1 ;an011; dms;hold segment of
						;	    environ. vector
;======== Disk Table ========== 		;an012; dms;
;Used if NumberOfFATs in BPB
;is 0.

DiskTable	dw	0,	32680,	0803h,	512,	0
		dw	4h,	0000h,	0402h,	512,	Fbig
		dw	8h,	0000h,	0803h,	512,	Fbig
		dw	10h,	0000h,	1004h,	512,	Fbig
		dw	20h,	0000h,	2005h,	512,	Fbig

;public		Org_AX				;an000; dms;make it known
Org_AX		rw      1 ;an000; dms;AX on entry

Cluster_Boundary_Adj_Factor	rw      1 ;an000; dms;
Cluster_Boundary_SPT_Count	rw      1 ;an000; dms;
Cluster_Boundary_Flag		db	FALSE	;an000; dms;
Cluster_Boundary_Buffer_Seg	rw      1 ;an000; dms;

Relative_Sector_Low		rw      1 ;an000; dms;
Relative_Sector_High		rw      1 ;an000; dms;

FAT_Flag			rb      1 ;an000; dms;
Tracks_To_Format		rw      1 ;an015; dms;
Track_Count			rw      1 ;an015; dms;
Format_End			db	FALSE	;an015; dms;

;public Msg_Allocation_Unit_Val

Msg_Allocation_Unit_Val 	rd      1 ;an019; dms;


end if
if SEGSEL = S_CODE

;For FORPROC and FORMES modules

;	public	secsiz,clussiz,inbuff

;	PUBLIC	crlf,std_printf

;	public	switchmap,drive,driveLetter,fatSpace
;	public	fBigFat, PrintString,currentHead,currentCylinder
;	extrn	CheckSwitches:near,LastChanceToSaveIt:near
;	extrn	Volid:near
;	extrn	WriteBootSector:near,OemDone:near
;	extrn	AccessDisk:near
;	extrn	Main_Init:near
;	extrn	Read_Disk:near
;	extrn	Write_Disk:near

end if
if SEGSEL = S_DATA
;	extrn	BiosFile:byte,DosFile:byte
end if
if SEGSEL = S_CODE

;For FORPROC module

;	EXTRN	FormatAnother?:near,Yes?:near,REPORT:NEAR,USER_STRING:NEAR
end if
if SEGSEL = S_DATA
;	extrn	syssiz:dword,biosiz:dword
end if
if SEGSEL = S_CODE

DOSVER_LOW equ	(0300H+20)
DOSVER_HIGH equ (0300H+20)

RECLEN	equ	(sys_fcb.fcb_RECSIZ+7)
RR	equ	(sys_fcb.fcb_RR+7)

PSP_Environ	equ	2ch			;an011; dms;location of
						;	    environ. segment
						;	    in PSP

Fbig	equ	0ffh				;an000; dms;flag for big FAT

START:
	xor	bx,bx				;				;AN000;
	push	bx				;				;AN000;
	Set_Data_Segment			;				;AC000;
	mov	[Org_AX],ax ;an000; dms;save ax on entry
	jmp	Main_Init			;				;AC000;


Main_Routine:					;				;AN000;
; Set memory requirements
	mov	bx,[PSP_Segment] ;Shrink to free space for FAT	;AC000;
	mov	es,bx				;				;AC000;
	mov	bx,End_Of_Memory_		;				;AC000;
	sub	bx,[PSP_Segment] ;				;AC000;
	DOS_Call Setblock			;				;AC000;

	call	Get_Disk_Access 						;an014; dms;
	cmp	[Disk_Access.DAC_ACCESS_FLAG],0ffh  ;an014; dms;is access already allowed?
;	if$	ne								;an014; dms;no, don't change status
	JE IF1$$
		lea	dx,[Disk_Access]    ;an014; dms;point to parm block
		mov	[Disk_Access.DAC_ACCESS_FLAG],01h  ;an014; dms;signal disk access
		call	Set_Disk_Access_On_Off					;an014;dms;allow disk access
;	endif$									;an014; dms;
IF1$$:

	CALL	Phase1Initialisation
	jnc	FatAllocated

	Message msgFormatFailure		;				;AC000;
	jmp	FEXIT

MEMERR:
	mov	ax, data_
	mov	ds, ax
	Message msgOutOfMemory			;				;AC000;
						;call	 PrintString
	JMP	FEXIT

FatAllocated:

	TEST	word [SWITCHMAP],SWITCH_S
	JZ	INITCALL
	MOV	BX,0FFFFH
	MOV	AH,Alloc
	INT	21H
	OR	BX,BX
	JZ	MEMERRJ 			;No memory
	MOV	[MSIZE],BX
	MOV	AH,Alloc
	INT	21H
	JNC	MEM_OK
MEMERRJ:
	JMP	MEMERR				;No memory

MEM_OK:
	MOV	[MSTART],AX

RDFRST:
	mov	[bios.fileSizeInParagraphs],0 ;mjb001 initialize file size
	mov	[dos.fileSizeInParagraphs],0 ;mjb001 ...
	mov	[command.fileSizeInParagraphs],0 ;mjb001 ...
	CALL	READDOS 			;Read BIOS and DOS
	JNC	INITCALL			;OK -- read next file
NEEDSYS:
	CALL	SYSPRM				;Prompt for system disk
	JMP	RDFRST				;Try again

INITCALL:
	CALL	Phase2Initialisation

SWITCHCHK:
	MOV	DX,[SWITCHMAP]
	MOV	[SWITCHCOPY],DX

SYSLOOP:
	;Must intialize for each iteration

	MOV	word [syssiz],0
	MOV	word [syssiz+2],0
	MOV	byte [DBLFLG],0
	mov	byte [ExitStatus], ExitOK
	MOV	DX,[SWITCHCOPY]
	MOV	[SWITCHMAP],DX ;Restore original Switches
; DiskFormat will handle call for new disk
	CALL	DiskFormat			;Format the disk
	JNC	GETTRK
FRMTPROB:

	test	word [SWITCHMAP],SWITCH_SELECT ;an017; dms;SELECT option?
;	if$	z								;an017; dms;no - display message
	JNZ IF3$$
		Message msgFormatFailure		;			;AC000;
		mov	byte [ExitStatus], ExitFatal ;an017; dms;
;	endif$									;an017; dms;
IF3$$:
	CALL	MORE				;See if more disks to format
	JMP	SHORT SYSLOOP

;Mark any bad sectors in the FATs
;And keep track of how many bytes there are in bad sectors

GETTRK:
	CALL	BadSector			;Do bad track fix-up
	JC	FRMTPROB			;Had an error in Formatting - can't recover
	CMP	AX,0				;Are we finished?
	JNZ	TRKFND				;No - check error conditions
	JMP	DRTFAT				;Yes
TRKFND:
	mov	bx,word [Relative_Sector_Low]   ;get the low word of the sector ;an000; dms;
	CMP	BX,[startSector] ;Are any sectors in the system area bad?
	JAE	CLRTEST 			; MZ 2.26 unsigned compare
	Message msgDiskUnusable 		;				;AC000;
	JMP	FRMTPROB			;Bad disk -- try again
CLRTEST:
	MOV	[SECTORS],AX ;Save the number of sectors on the track
	TEST	word [SWITCHMAP],SWITCH_S ;If system requested calculate size
	JZ	BAD100
	CMP	byte [DBLFLG],0    ;Have we already calculated System space?
	JNZ	CMPTRKS 			;Yes -- all ready for the compare
	INC	byte [DBLFLG]     ;No -- set the flag
	CALL	GetBioSize			; Get the size of the BIOS
	MOV	DX,word [syssiz+2]
	MOV	AX,word [syssiz]
	MOV	word [biosiz+2],DX
	MOV	word [biosiz],AX
	CALL	GetDosSize
	CALL	GetCmdSize
	MOV	DX,word [biosiz+2]
	MOV	AX,word [biosiz]
	DIV	word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR]
	ADD	AX,[startSector]
	MOV	[SYSTRKS],AX ;Space FAT,Dir,and system files require
CMPTRKS:
	mov	bx,word [Relative_Sector_Low]   ;get the low word of the sector ;an000; dms;
	CMP	BX,[SYSTRKS]
	JA	BAD100				; MZ 2.26 unsigned compare
	mov	byte [ExitStatus], ExitFatal
	Message msgNotSystemDisk		;				;AC000;
	AND	word [SWITCHMAP],NOT SWITCH_S ;Turn off system transfer switch
	MOV	word [syssiz+2],0    ;No system to transfer
	MOV	word [syssiz],0    ;No system to transfer
BAD100:

	CMP	[deviceParameters.DP_DEVICETYPE], DEV_HARDDISK ;an000; dms;hard disk?
;	if$	e								;an000; dms; yes
	JNE IF5$$
		call	Get_Bad_Sector_Hard					;an000; dms;see if a sector is bad
;	else$									;an000; dms;floppy disk
	JMP SHORT EN5$$
IF5$$:
		call	Get_Bad_Sector_Floppy					;an000; dms;mark entire track bad
;	endif$									;an000; dms;
EN5$$:

	JMP	GETTRK

;   Inputs:	BX = Cluster number
;   Outputs:	The given cluster is marked as invalid
;		Zero flag is set if the cluster was already marked bad
;   Registers modified: DX,SI
;   No other registers affected

;=========================================================================
; BADCLUS	:	Marks off a bad cluster in the FAT
;			If a cluster has already been marked bad it
;			will return with ZR.
;
;	Inputs	:	DX:AX - Cluster Number
;
;	Outputs :	Cluster is marked invalid
;			ZR set if cluster already marked bad
;=========================================================================

BadClus:             ;an000; mark bad clusters

	push	di				;an000; save affected regs
	push	ax
	push	bx
	push	cx
	push	dx
	push	es

	mov	es, word [fatSpace+2]     ;an005; obtain seg of FAT
	CMP	byte [fBigFat],TRUE ;an005; 16 bit fat?
;	if$	ne				;an005; no - 12-bit fat
	JE IF8$$
		push	ax			;an000; save ax - contains low cluster number
		mov	si,dx			;an000; pick up high word of cluster
		mov	di,ax			;an000; pick up low word of cluster
		mov	cx,2			;an000; divide by 2
		call	Divide_32_Bits		;an000; 32 bit divide

		add	ax,di			;an000; add in low word of result
		adc	dx,si			;an000; pick up low word carry
						;cluster = cluster * 1.5
		add	ax,word [fatSpace]   ;an005; add 0
		adc	dx,0			;an000; pick up carry

		mov	bx,dx			;an000; get high word for adjust
		mov	cx,es			;an005; place seg in ax
		call	BadClus_Address_Adjust	;an000; adjust segment offset
		mov	es,cx			;an000; new segment
		mov	si,ax			;an000; new offset

		MOV	DX,0FF7h		;an005; bad cluster flag
		MOV	AX,0FFFh		;an005; mask value

		pop	cx			;an000; restore ax in cx - low cluster number
		test	cx,1			;an000; is old clus num odd?
;		if$	nz			;an005; yes
		JZ IF9$$
			mov	cl,4		;an005; set shift count
			SHL	AX,cl		;an005; get only 12 bits - fff0
			mov	cl,4		;an005; set shift count
			SHL	DX,cl		;an005; get 12 bits	 - ff70
;		endif$				;an005;
IF9$$:
;	else$					;an005; 16-bit fats here
	JMP SHORT EN8$$
IF8$$:
	       xor     si,si			;an005; clear si
	       mov     bx,dx			;an000; get high word for multiply
	       mov     cx,2			;an000; multiply by 2
	       call    Multiply_32_Bits 	;an000; 32 bit multiply
						;	due to 2 bytes per
						;	FAT cell.  This gives
						;	us an offset into the
						;	FAT.

	       mov     cx,es			;an005; place seg in cx
	       call    BadClus_Address_Adjust	;an000; adjust segment:offset
	       mov     es,cx			;an000; new segment
	       mov     si,ax			;an000; new offset

	       MOV     DX,0FFF7h		;an005; bad cluster value
	       MOV     AX,0FFFFh		;an005; mask value
;	endif$
EN8$$:

	MOV	CX,[es:SI]			;an005; get contents of fat cell
	AND	CX,AX				;an005; make it 12 or 16 bit
						;	depending on value in AX
	NOT	AX				;an005; set AX to 0
	AND	[es:SI],AX			;an005; clear FAT entry
	OR	[es:SI],DX			;an005; flag it a bad cluster
	CMP	DX,CX				;   return op == badval;

	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	di
	return

;badclus 	endp

DRTFAT:
	TEST	word [SWITCHMAP],SWITCH_S ;If system requested, calculate size
	JZ	CLEARED
	CMP	byte [DBLFLG],0    ;Have we already calculated System space?
	JNZ	CLEARED 			;Yes
	INC	byte [DBLFLG]     ;No -- set the flag
	CALL	GetSize 			;Calculate the system size
CLEARED:
	call	Ctrl_Break_Save 		;ac010; dms;save CTRL-Break
	call	Set_Ctrl_Break
	CALL	WriteFileSystem

	JNC	FATWRT


LOUSE:

	call	Reset_Ctrl_Break		;ac010; dms;restore CTRL-Break
	Message msgDiskUnusable 		;				;AC000;
	JMP	FRMTPROB

LOUSEP:
	POP	DS
	JMP	LOUSE

FATWRT:

	PUSH	DS
	MOV	DL,[drive]
	INC	DL
	MOV	AH,Get_DPB
	INT	21H
	CMP	AL,-1
	JZ	LOUSEP				;Something BAD has happened
	MOV	[BX+dpb.dpb_next_free],0 ; Reset allocation to start of disk
	MOV	[BX+dpb.dpb_free_cnt],-1 ; Force free space to be computed
	POP	DS
	TEST	word [SWITCHMAP],SWITCH_S ;System desired
	JZ	STATUS
	mov	al, [drive]
	call	AccessDisk			; note what is current logical drive
	CALL	WRITEDOS			;Write the BIOS & DOS
	JNC	SYSOK
	Message msgNotSystemDisk		;				;AC000;
	MOV	word [syssiz+2],0    ;No system transfered
	MOV	word [syssiz],0    ;No system transfered
	JMP	SHORT STATUS

SYSOK:


	test	word [SWITCHMAP],(SWITCH_SELECT or SWITCH_AUTOTEST) ;Don't display if EXEC'd by     ;AN000;
;	IF$	Z				; Select			;AN000;
	JNZ IF13$$
	   Message msgSystemTransfered		;				;AC000;
;	ENDIF$					;AN000;
IF13$$:
STATUS:

	call	Reset_Ctrl_Break		;ac010; dms;restore CTRL-Break

	CALL	crlf




	MOV	AH,Disk_Reset
	INT	21H
	CALL	Done				;Final call to OEM module
	JNC	REPORTC
	JMP	FRMTPROB			;Report an error

REPORTC:

;
;TEMP FIX for /AUTOTEST
;
	test	word [SWITCHMAP],(SWITCH_AUTOTEST or SWITCH_8) ;TEMP
;	IF$	Z
	JNZ IF15$$
	   CALL    Volid
;	ENDIF$
IF15$$:
	test	word [SWITCHMAP],(SWITCH_SELECT or SWITCH_AUTOTEST) ;Need to shut down the report? ;AN000;
;	IF$	Z				;If exec'd by Select, we do     ;AN000;
	JNZ IF17$$
	   CALL    REPORT			;Print report
;	ENDIF$					;				;AN000;
IF17$$:
	CALL	MORE				;See if more disks to format
	JMP	SYSLOOP 			;If we returned from MORE then continue

;******************************************
; Calculate the size in bytes of the system rounded up to sector and
;   cluster boundries, Answer in SYSSIZ

GetSize:
	call	GetBioSize
	call	GetDosSize
	call	GetCmdSize
	return
;GetSize endp

GetBioSize:
	MOV	AX,word [bios.fileSizeInBytes]
	MOV	DX,word [bios.fileSizeInBytes+2]
	CALL	AddToSystemSize
	return
;GetBioSize endp

GetDosSize:
	MOV	AX,word [dos.fileSizeInBytes]
	MOV	DX,word [dos.fileSizeInBytes+2]
	CALL	AddToSystemSize
	return
;GetDosSize endp

GetCmdSize:
	MOV	AX,word [command.fileSizeInBytes]
	MOV	DX,word [command.fileSizeInBytes+2]
	call	AddToSystemSize
	return
;GetCmdSize endp

;Calculate the number of sectors used for the system
;PUBLIC	AddToSystemSize
AddToSystemSize:
	push	bx
	DIV	word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR]
	OR	DX,DX
	JZ	FNDSIZ0
	INC	AX				; Round up to next sector
FNDSIZ0:
	PUSH	AX
	XOR	DX,DX
	xor	bx,bx
	mov	bl, byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER]
	div	bx
	POP	AX
	OR	DX,DX
	JZ	ONCLUS
	SUB	DX, bx
	NEG	DX
	ADD	AX,DX				; Round up sector count to cluster
						;	boundry
ONCLUS:
	MUL	word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR]
	ADD	word [syssiz],AX
	ADC	word [syssiz+2],DX
	pop	bx
	return
;AddToSystemSize endp

MORE:

	mov	word [Formatted_Tracks_Low],0 ;Reinit the track counter	;AN000;
	mov	word [Formatted_Tracks_High],0 ; in case of another format	;AN000;
	test	word [SWITCHMAP],(SWITCH_SELECT or SWITCH_AUTOTEST) ;Don't display if EXEC'd  by ;AN000;
	jnz	ExitProgram			; Select			;AN000;

	CMP	[deviceParameters.DP_DEVICETYPE], DEV_HARDDISK
	je	ExitProgram
	test	word [SWITCHMAP],(SWITCH_SELECT or SWITCH_AUTOTEST) ;If exec'd from select, then;AN000;
	jnz	ExitProgram			; don't give user choice        ;AN000;
	CALL	FormatAnother?			;Get yes or no response
	JC	ExitProgram
	CALL	crlf
	JMP	crlf


FEXIT:
	Set_Data_Segment			;Make sure have addressability	;AN000;
	mov	byte [ExitStatus],ExitFatal

ExitProgram:
	test	byte [validSavedDeviceParameters], 0ffH
	jz	DoNotRestoreDeviceParameters
	mov	[savedDeviceParameters.DP_SPECIALFUNCTIONS], TRACKLAYOUT_IS_GOOD
	lea	dx,[savedDeviceParameters]
	call	SetDeviceParameters
DoNotRestoreDeviceParameters:

	call	Format_Access_Wrap_Up		;determine access status	;an000; dms;determine access status
	mov	al,[ExitStatus] ;Get Errorlevel 		;AN000;
	DOS_Call Exit				;Exit program			;AN000;
	int	20h				;If other exit fails		;AN000;

; Prompt the user for a system diskette in the default drive
SYSPRM:
	MOV	AH,Get_Default_Drive		;Will find out the default drive
	INT	21H				;Default now in AL
	MOV	BL,AL
	INC	BL				; A = 1
	ADD	AL,41H				;Now in Ascii
	MOV	[systemDriveLetter],AL ;Text now ok
	CALL	IsRemovable
	JNC	DoPrompt
;
; Media is non-removable. Switch sys disk to drive A.  Check, though, to see
; if drive A is removable too.
;
	MOV	AL,"A"
	MOV	byte [systemDriveLetter],AL
	MOV	[BiosFile],AL
	MOV	[DosFile],AL
	MOV	[CommandFile],AL
	MOV	BX,1
	CALL	IsRemovable
	JNC	DoPrompt
	Message msgNoSystemFiles		;				;AC000;
fexitJ:
	JMP	FEXIT

DoPrompt:
	mov	al, [systemDriveLetter]
	sub	al, 'A'
	call	AccessDisk
	Message msgInsertDOSDisk		;				;AC000;
	Message ContinueMsg
						;lea	 dx, ptr_msgInsertDosDisk
						;CALL	 std_printf		 ;Print first line
	CALL	USER_STRING			;Wait for a key
	CALL	crlf
	call	crlf
	return

TARGPRM:
	mov	al, [drive]
	call	AccessDisk
	Message msgInsertDisk			;				;AC000;
	Message ContinueMsg			;
						;lea	 DX, ptr_msgInsertDisk
						;CALL	 std_printf		 ;Print first line
	CALL	USER_STRING			;Wait for a key
	CALL	crlf
	return

;
; Determine if the drive indicated in BX is removable or not.
;
;   Inputs:	BX has drive (0=def, 1=A)
;   Outputs:	Carry clear
;		    Removable
;		Carry set
;		    not removable
;   Registers modified: none

IsRemovable:
	SaveReg <AX>
	MOV	AX,(IOCtl SHL 8) OR 8		; Rem media check
	INT	21H
	JNC	CheckRemove
	MOV	AX,(IOCtl SHL 8) + 9		; Is it a NET drive?
	INT	21h
	JC	NotRemove			; Yipe, say non-removable
	TEST	DX,1000h
	JNZ	NotRemove			; Is NET drive, say non-removeable
	JMP	IsRemove			; Is local, say removable
CheckRemove:
	TEST	AX,1
	JNZ	NotRemove
IsRemove:
	CLC
	RestoreReg <AX>
	return
NotRemove:
	STC
	RestoreReg <AX>
	return


; DiSKPRoMpt:
;
;	This routine prompts for the insertion of the correct diskette
;  into the Target drive, UNLESS we are being re-entrantly invoked
;  from LastChanceToSaveIt.  If the target is a Hardisk we issue a
;  warning message.
;
;	INPUTS:
;		deviceParameters.DP_DeviceType
;		fLastChance
;
;	OUTPUTS:
;		Prompt string
;		fLastChance	:= FALSE
;
;	Registers affected:
;				Flags
;
DSKPRM:
	CMP	byte [fLastChance],TRUE
	JE	PrmptRet

	CMP	[deviceParameters.DP_DEVICETYPE], DEV_HARDDISK
	jne	GOPRNIT
	Message msgHardDiskWarning		;				;AC000;
						;lea	 dx, ptr_msgHardDiskWarning
						;call	 std_printf
	CALL	YES?
	jnc	OkToFormatHardDisk
	mov	byte [ExitStatus], ExitNo
	jmp	ExitProgram

OkToFormatHardDisk:
	CALL	crlf
	CALL	crlf
	return

GOPRNIT:
	mov	al, [drive]
	call	AccessDisk
	Message msgInsertDisk			;				;AC000;
	Message ContinueMsg			;
						;lea	 dx,ptr_msgInsertDisk
						;CALL	 std_printf
	CALL	USER_STRING			;Wait for any key
	CALL	crlf
	CALL	crlf

PrmptRet:
	mov	byte [fLastChance], FALSE
	return


;-------------------------------------------------------------------------------

ControlC_Handler:
	mov	ax, data_
	mov	ds, ax
	Message msgInterrupt			;				;AC000;
	mov	byte [ExitStatus], ExitCtrlC
	jmp	ExitProgram


crlf:
						;lea	 dx, msgCRLF
	mov	dx,msgCRLF         ;CR,LF added to message 	;AC000;
PrintString:
						;mov	 printStringPointer, dx
						;lea	 dx, PrintStringPointer

std_printf:
						;push	 dx
						;call	 printf
	call	Display_Interface		;				;AC000;
	return

;-------------------------------------------------------------------------------


;****************************************
;Copy IO.SYS, MSDOS.SYS and COMMAND.COM into data area.
; Carry set if problems

READDOS:
	push	ax				;save regs			;an025; dms;
	push	bx				;				;an025; dms;
	push	es				;				;an025; dms;

	mov	ah,Get_In_Vars			;Find out boot drive		;an025; dms;
	int	21h				;				;an025; dms;
	mov	al,byte [es:bx+SysInitVars.SYSI_BOOT_DRIVE] ;get 1 based drive ID	;an025; dms;
	add	al,40h				;Make it ASCII			;an025; dms;
	mov	[BiosFile],al			;Stuff it in file specs.	;an025; dms;
	mov	[DosFile],al			;				;an025; dms;
	mov	[CommandFile],al		;				;an025; dms;

	pop	es				;restore regs			;an025; dms;
	pop	bx				;				;an025; dms;
	pop	ax				;				;an025; dms;

	call	Get_BIOS			; dcl 8/23/86
	JNC	RDFILS
	return

RDFILS:
	MOV	byte [FILSTAT],0
	MOV	BX,[bios.fileHandle]
	MOV	AX,[MSTART]
	MOV	DX,AX
	ADD	DX,[MSIZE]			; CX first bad para
	MOV	[bios.fileStartSegment],AX
	MOV	CX,[bios.fileSizeInParagraphs]
	ADD	AX,CX
	CMP	AX,DX
	JBE	GOTBIOS
	MOV	byte [FILSTAT],00000001B     ; Got part of BIOS
	MOV	SI,[MSIZE]
	XOR	DI,DI
	CALL	DISIX4
	push	ds
	MOV	DS,[bios.fileStartSegment]
;	assume	ds:nothing
	CALL	READFILE
	pop	ds
;	assume	ds:data
	JC	CLSALL
	XOR	DX,DX
	MOV	CX,DX
	MOV	AX,(LSeek SHL 8) OR 1
	INT	21H
	MOV	word [bios.fileOffset],AX
	MOV	word [bios.fileOffset+2],DX
FILESDONE:
	CLC
CLSALL:
	PUSHF
;	CALL	COMCLS			; dcl 8/23/86
	call	FILE_CLS			; dcl 8/23/86
	POPF
	return

GOTBIOS:
	MOV	byte [FILSTAT],00000010B     ; Got all of BIOS
	push	es
	LES	SI,[bios.fileSizeInBytes]
	MOV	DI,ES
	pop	es
	push	ds
	MOV	DS,[bios.fileStartSegment]
;	assume	ds:nothing
	CALL	READFILE
	pop	ds
;	assume	ds:data
	JC	CLSALL

	push	ax				; dcl 8/23/86
	push	dx				; dcl 8/23/86
	call	FILE_CLS			; dcl 8/23/86
	call	Get_DOS 			; dcl 8/23/86
	pop	dx				; dcl 8/23/86
	pop	ax				; dcl 8/23/86

	JNC	Found_IBMDOS			;mt 12/8/86 P894
	return					;mt 12/8/86

Found_IBMDOS:					;mt 12/8/86

	MOV	BX,[dos.fileHandle]
	MOV	[dos.fileStartSegment],AX
	CMP	AX,DX				; No room left?
	JZ	CLSALL				; Yes
	MOV	CX,[dos.fileSizeInParagraphs]
	ADD	AX,CX
	CMP	AX,DX
	JBE	GOTDOS
	OR	byte [FILSTAT],00000100B     ; Got part of DOS
	SUB	DX,[dos.fileStartSegment]
	MOV	SI,DX
	XOR	DI,DI
	CALL	DISIX4
	push	ds
	MOV	DS,[dos.fileStartSegment]
;	assume	ds:nothing
	CALL	READFILE
	pop	ds
;	assume	ds:data
	JC	CLSALL
	XOR	DX,DX
	MOV	CX,DX
	MOV	AX,(LSeek SHL 8) OR 1
	INT	21H
	MOV	word [dos.fileOffset],AX
	MOV	word [dos.fileOffset+2],DX
	JMP	FILESDONE

GOTDOS:
	OR	byte [FILSTAT],00001000B     ; Got all of DOS
	push	es
	LES	SI,[dos.fileSizeInBytes]
	MOV	DI,ES
	pop	es
	push	ds
	MOV	DS,[dos.fileStartSegment]
;	assume	ds:nothing
	CALL	READFILE
	pop	ds
;	assume	ds:data

CLSALLJ: JNC	NotCLSALL			;PTM P894  mt 12/8/86
	jmp	CLSALL				;

NotCLSALL:
	push	ax				; dcl 8/23/86

	push	dx				; dcl 8/23/86
	call	FILE_CLS			; dcl 8/23/86
	call	Get_Command_Path		;ac011; dms; get path of
						;	     COMMAND.COM
	call	Get_COMMAND			;ac011; dms; Point to COMMAND
						;	     and read it
	pop	dx				; dcl 8/23/86
	pop	ax				; dcl 8/23/86

	JNC	Found_COMMAND			;mt 12/8/86 P894
	return					;mt 12/8/86

Found_COMMAND:					;mt 12/8/86
	MOV	BX,[command.fileHandle]
	MOV	[command.fileStartSegment],AX
	CMP	AX,DX				; No room left?
	JZ	CLSALLJ 			; Yes
	MOV	CX,[command.fileSizeInParagraphs]
	ADD	AX,CX
	CMP	AX,DX
	JBE	GOTCOM
	OR	byte [FILSTAT],00010000B     ; Got part of COMMAND
	SUB	DX,[command.fileStartSegment]
	MOV	SI,DX
	XOR	DI,DI
	CALL	DISIX4
	push	ds
	MOV	DS,[command.fileStartSegment]
;	assume	ds:nothing
	CALL	READFILE
	pop	ds
;	assume	ds:data
	JC	CLSALLJ
	XOR	DX,DX
	MOV	CX,DX
	MOV	AX,(LSeek SHL 8) OR 1
	INT	21H
	MOV	word [command.fileOffset],AX
	MOV	word [command.fileOffset+2],DX
	JMP	FILESDONE

GOTCOM:
	OR	byte [FILSTAT],00100000B     ; Got all of COMMAND
	push	es
	LES	SI,[command.fileSizeInBytes]
	MOV	DI,ES
	pop	es
	push	ds
	MOV	DS,[command.fileStartSegment]
;	assume	ds:nothing
	CALL	READFILE
	pop	ds
;	assume	ds:data
	JMP	CLSALL

;**************************************************
;Write BIOS DOS COMMAND to the newly formatted disk.

;ASSUME	DS:DATA
WRITEDOS:
	MOV	CX,BiosAttributes
	MOV	DX,BiosFile
	push	es
	LES	SI,[bios.fileSizeInBytes]
	MOV	DI,ES
	pop	es
	CALL	MAKEFIL
	retc

	MOV	[TempHandle],BX
	TEST	byte [FILSTAT],00000010B
	JNZ	GOTALLBIO
	call	Get_BIOS			; dcl 8/23/86
	jnc	Got_WBIOS			;mt 12/8/86  P894
	ret

Got_WBIOS:

	push	es
	LES	SI,[bios.fileOffset]
	MOV	DI,ES
	pop	es
	MOV	word [IOCNT],SI
	MOV	word [IOCNT+2],DI
	MOV	BP,bios
	CALL	GOTTARG
	retc
	JMP	SHORT BIOSDONE

GOTALLBIO:
	push	es
	LES	SI,[bios.fileSizeInBytes]
	MOV	DI,ES
	pop	es
	push	ds
	MOV	DS,[bios.fileStartSegment]
;	assume	ds:nothing
	CALL	WRITEFILE
	pop	ds
;	assume	ds:data
BIOSDONE:
	MOV	BX,[TempHandle]
	MOV	CX,[bios.fileTime]
	MOV	DX,[bios.fileDate]
	CALL	CLOSETARG
	MOV	CX,DosAttributes
	MOV	DX,DosFile
	push	es
	LES	SI,[dos.fileSizeInBytes]
	MOV	DI,ES
	pop	es
	CALL	MAKEFIL
	retc

GOTNDOS:
	MOV	[TempHandle],BX
	TEST	byte [FILSTAT],00001000B
	JNZ	GOTALLDOS
	call	Get_DOS 			; dcl 8/23/86
	jnc	Got_WDOS			;mt 12/8/86  P894
	ret

Got_WDOS:
	MOV	BP,dos
	TEST	byte [FILSTAT],00000100B
	JNZ	PARTDOS
	MOV	word [dos.fileOffset],0
	MOV	word [dos.fileOffset+2],0
	CALL	GETSYS3
	retc
	JMP	SHORT DOSDONE

PARTDOS:
	push	es
	LES	SI,[dos.fileOffset]
	MOV	DI,ES
	pop	es
	MOV	word [IOCNT],SI
	MOV	word [IOCNT+2],DI
	CALL	GOTTARG
	retc
	JMP	SHORT DOSDONE

GOTALLDOS:
	push	es
	LES	SI,[dos.fileSizeInBytes]
	MOV	DI,ES
	pop	es
	push	ds
	MOV	DS,[dos.fileStartSegment]
;	assume	ds:nothing
	CALL	WRITEFILE
	pop	ds
;	assume	ds:data
DOSDONE:
	MOV	BX,[TempHandle]
	MOV	CX,[dos.fileTime]
	MOV	DX,[dos.fileDate]
	CALL	CLOSETARG
	MOV	CX,CommandAttributes
	call	Command_Root			;an011; dms;adjust path for
						;COMMAND.COM creation
	MOV	DX,CommandFile
	push	es
	LES	SI,[command.fileSizeInBytes]
	MOV	DI,ES
	pop	es
	CALL	MAKEFIL
	retc

	MOV	[TempHandle],BX
	TEST	byte [FILSTAT],00100000B
	JNZ	GOTALLCOM
	call	Get_COMMAND			; dcl 8/23/86
	jnc	Got_WCOM			;mt 12/8/86  P894
	ret

Got_WCOM:
	MOV	BP,command
	TEST	byte [FILSTAT],00010000B
	JNZ	PARTCOM
	MOV	word [command.fileOffset],0
	MOV	word [command.fileOffset+2],0
	CALL	GETSYS3
	retc
	JMP	SHORT COMDONE

PARTCOM:
	push	es
	LES	SI,[command.fileOffset]
	MOV	DI,ES
	pop	es
	MOV	word [IOCNT],SI
	MOV	word [IOCNT+2],DI
	CALL	GOTTARG
	retc
	JMP	SHORT COMDONE

GOTALLCOM:
	push	es
	LES	SI,[command.fileSizeInBytes]
	MOV	DI,ES
	pop	es
	push	ds
	MOV	DS,[command.fileStartSegment]
;	assume	ds:nothing
	CALL	WRITEFILE
	pop	ds
;	assume	ds:data
COMDONE:
	MOV	BX,[TempHandle]
	MOV	CX,[command.fileTime]
	MOV	DX,[command.fileDate]
	CALL	CLOSETARG
;****************************************************************
; I don't see the need for the following code!! - RS 3.20
;	CMP	BYTE PTR [FILSTAT],00101010B
;	JZ	NOREDOS
;RDFRST2:
;	CALL	READDOS 		; Start back with BIOS
;	JNC	NOREDOS
;	CALL	SYSPRM			;Prompt for system disk
;	JMP	RDFRST2 		;Try again
;NOREDOS:
;****************************************************************
	CLC
	return

;*********************************************
; Create a file on target disk
; CX = attributes, DX points to name
; DI:SI is size file is to have
;
;   There is a bug in DOS 2.00 and 2.01 having to do with writes
;   from the end of memory. In order to circumvent it this routine
;   must create files with the length in DI:SI
;
; On return BX is handle, carry set if problem

MAKEFIL:
	MOV	BX,DX
	PUSH	word [BX]
	MOV	AL,[driveLetter]
	MOV	[BX],AL
	MOV	AH,Creat
	INT	21H
	POP	word [BX]
	MOV	BX,AX
	JC	CheckMany
	MOV	CX,DI
	MOV	DX,SI
	MOV	AX,LSeek SHL 8
	INT	21H				; Seek to eventual EOF
	XOR	CX,CX
	MOV	AH,Write
	INT	21H				; Set size of file to position
	XOR	CX,CX
	MOV	DX,CX
	MOV	AX,LSeek SHL 8
	INT	21H				; Seek back to start
	return

;
; Examine error code in AX to see if it is too-many-open-files.
; If it is, we abort right here. Otherwise we return.
;
CheckMany:
	CMP	AX,error_too_many_open_files
	retnz
	Extended_Message			;				;AC006;
	JMP	FEXIT

;*********************************************
; Close a file on the target disk
; CX/DX is time/date, BX is handle

CLOSETARG:
	MOV	AX,(File_Times SHL 8) OR 1
	INT	21H
	MOV	AH,Close
	INT	21H
	return

;****************************************
; Transfer system files
; BP points to data structure for file involved
; offset is set to current amount read in
; Start set to start of file in buffer
; TempHandle is handle to write to on target

IOLOOP:
	MOV	AL,[systemDriveLetter]
	CMP	AL,[driveLetter]
	JNZ	GOTTARG
	MOV	AH,Disk_Reset
	INT	21H
	CALL	TARGPRM 			;Get target disk

GOTTARG:
;ASSUME	DS:DATA
;Enter here if some of file is already in buffer, IOCNT must be set
; to size already in buffer.
	MOV	BX,[TempHandle]
	MOV	SI,word [IOCNT]
	MOV	DI,word [IOCNT+2]
	push	ds
	MOV	DS,[ds:BP+a_FileStructure.fileStartSegment]
;	assume	ds:nothing
	CALL	WRITEFILE			; Write next part
	pop	ds
;	assume	ds:data
	retc

	push	es
	LES	AX,[ds:BP+a_FileStructure.fileOffset]
	CMP	AX,word [ds:BP+a_FileStructure.fileSizeInBytes]
	JNZ	GETSYS3
	MOV	AX,ES
	CMP	AX,word [ds:BP+a_FileStructure.fileSizeInBytes+2]
	JNZ	GETSYS3
	pop	es
	return					; Carry clear from CMP

GETSYS3:
;Enter here if none of file is in buffer
	pop	es
	MOV	AH,Disk_Reset
	INT	21H
	MOV	AX,[MSTART]			;Furthur IO done starting here
	MOV	[ds:BP+a_FileStructure.fileStartSegment],AX ;point to start of buffer
	MOV	AL,[systemDriveLetter]		;see if we have system disk
	CMP	AL,[driveLetter]
	JNZ	TESTSYS
GSYS:
	MOV	AH,Disk_Reset
	INT	21H
	CALL	SYSPRM				;Prompt for system disk
TESTSYS:
;	CALL	TESTSYSDISK			; dcl 8/23/86
	JC	GSYS
	MOV	BX,word [ds:BP+a_FileStructure.fileHandle] ; CS over ARR 2.30
	push	es
	LES	DX,dword [ds:BP+a_FileStructure.fileOffset] ; CS over ARR 2.30
	MOV	CX,ES
	pop	es
	PUSH	DX
	MOV	AX,LSeek SHL 8
	INT	21H
	POP	DX
	push	es
	LES	SI,dword [ds:BP+a_FileStructure.fileSizeInBytes] ; CS over ARR 2.30
	MOV	DI,ES				;put high word in di
	pop	es
	SUB	SI,DX				;get low word value
	SBB	DI,CX				; DI:SI is #bytes to go
	PUSH	DI
	PUSH	SI
	ADD	SI,15				;round up 1 para
	ADC	DI,0				;pick up carry
	CALL	DISID4				;div 16 to get para count
	MOV	AX,SI				;put para count in ax
	POP	SI				;restore bytes remaining
	POP	DI				;restore bytes remaining
	CMP	AX,[MSIZE]			;enough memory to read remainder?
	JBE	GOTSIZ2 			;yes
	MOV	SI,[MSIZE]
	XOR	DI,DI
	CALL	DISIX4
GOTSIZ2:
	MOV	word [IOCNT],SI      ;save byte count for read
	MOV	word [IOCNT+2],DI
	push	ds
	MOV	DS,[MSTART]
;	assume	ds:nothing
	CALL	READFILE
	pop	ds
;	assume	ds:data
	JNC	GETOFFS
	CALL	CLSALL
	JMP	GSYS
GETOFFS:
	XOR	DX,DX				;clear dx
	MOV	CX,DX				;clear cx
	MOV	AX,(LSeek SHL 8) OR 1
	INT	21H
	MOV	word [ds:BP+a_FileStructure.fileOffset],AX ; CS over ARR 2.30
	MOV	word [ds:BP+a_FileStructure.fileOffset+2],DX ; CS over ARR 2.30
;;;;;;	CALL	CLSALL
	JMP	IOLOOP

;*************************************************
; Test to see if correct system disk. Open handles

CRET12:
	STC
	return

;TESTSYSDISK:					; dcl 8/23/86
Get_BIOS:					; dcl 8/23/86
	MOV	AX,Open SHL 8
	MOV	DX,BiosFile
	INT	21H
	JNC	SETBIOS
;	call	CheckMany			; dcl 8/23/86
	jmp	CheckMany			; dcl 8/23/86

SETBIOS:
	MOV	[bios.fileHandle],AX
	MOV	BX,AX
	CALL	GETFSIZ
	CMP	[bios.fileSizeInParagraphs],0
	JZ	SETBIOSSIZ
	CMP	[bios.fileSizeInParagraphs],AX
	JZ	SETBIOSSIZ
BIOSCLS:
	MOV	AH,Close
	MOV	BX,[bios.fileHandle]
	INT	21H
;	JMP	CRET12		       ; dcl 8/23/86
	ret

SETBIOSSIZ:
	MOV	[bios.fileSizeInParagraphs],AX
	MOV	word [bios.fileSizeInBytes],SI
	MOV	word [bios.fileSizeInBytes+2],DI
	MOV	[bios.fileDate],DX
	MOV	[bios.fileTime],CX
	clc
	ret					; dcl 8/23/86

Get_DOS:					; dcl 8/23/86
	MOV	AX,Open SHL 8
	MOV	DX,DosFile
	INT	21H
	JNC	DOSOPNOK
;	call	CheckMany			; dcl 8/23/86
;	JMP	BIOSCLS 			; dcl 8/23/86  Checkmany no ret.
	jmp	CheckMany			; dcl 8/23/86

DOSOPNOK:
	MOV	[dos.fileHandle],AX
	MOV	BX,AX
	CALL	GETFSIZ
	CMP	[dos.fileSizeInParagraphs],0
	JZ	SETDOSSIZ
	CMP	[dos.fileSizeInParagraphs],AX
	JZ	SETDOSSIZ

DOSCLS:
	MOV	AH,Close
	MOV	BX,[dos.fileHandle]
	INT	21H
;	JMP	BIOSCLS 		; dcl 8/23/86
	ret					; dcl 8/23/86

SETDOSSIZ:
	MOV	[dos.fileSizeInParagraphs],AX
	MOV	word [dos.fileSizeInBytes],SI
	MOV	word [dos.fileSizeInBytes+2],DI
	MOV	[dos.fileDate],DX
	MOV	[dos.fileTime],CX
	clc
	ret					; dcl 8/23/86



Get_COMMAND:
	MOV	AX,Open SHL 8
	MOV	DX,CommandFile
	INT	21H
	JNC	GotComHand
;	call	CheckMany		; dcl 8/23/86
;	JMP	DosCls			; dcl 8/23/86
	jmp	CheckMany			; dcl 8/23/86

GotComHand:
	MOV	[command.fileHandle],AX
	MOV	BX,AX
	CALL	GETFSIZ
	CMP	[command.fileSizeInParagraphs],0
	JZ	SETCOMSIZ
	CMP	[command.fileSizeInParagraphs],AX
	JZ	SETCOMSIZ
COMCLS:
	MOV	AH,Close
	MOV	BX,[command.fileHandle]
	INT	21H
;	JMP	DOSCLS			; dcl 8/23/86
	ret					; dcl 8/23/86

SETCOMSIZ:
	MOV	[command.fileSizeInParagraphs],AX
	MOV	word [command.fileSizeInBytes],SI
	MOV	word [command.fileSizeInBytes+2],DI
	MOV	[command.fileDate],DX
	MOV	[command.fileTime],CX
	CLC
	return

FILE_CLS:					; dcl 8/23/86
	MOV	AH,Close			; dcl 8/23/86
	INT	21H				; dcl 8/23/86
	ret					; dcl 8/23/86

;*******************************************
; Handle in BX, return file size in para in AX
; File size in bytes DI:SI, file date in DX, file
; time in CX.

GETFSIZ:
	MOV	AX,(LSeek SHL 8) OR 2
	XOR	CX,CX
	MOV	DX,CX
	INT	21H
	MOV	SI,AX
	MOV	DI,DX
	ADD	AX,15				; Para round up
	ADC	DX,0
	AND	DX,0FH				; If the file is larger than this it
						; is bigger than the 8086 address
						; space!
	MOV	CL,12
	SHL	DX,CL
	MOV	CL,4
	SHR	AX,CL
	OR	AX,DX
	PUSH	AX
	MOV	AX,LSeek SHL 8
	XOR	CX,CX
	MOV	DX,CX
	INT	21H
	MOV	AX,File_Times SHL 8
	INT	21H
	POP	AX
	return

;********************************************
; Read/Write file
;	DS:0 is Xaddr
;	DI:SI is byte count to I/O
;	BX is handle
; Carry set if screw up
;
; I/O SI bytes
; I/O 64K - 1 bytes DI times
; I/O DI bytes


READFILE:
; Must preserve AX,DX
	PUSH	AX
	PUSH	DX
	PUSH	BP
	MOV	BP,Read SHL 8
	CALL	FILIO
	POP	BP
	POP	DX
	POP	AX
	return

WRITEFILE:
	PUSH	BP
	MOV	BP,Write SHL 8
	CALL	FILIO
	POP	BP
	return

FILIO:
	XOR	DX,DX
	MOV	CX,SI
	JCXZ	K64IO
	MOV	AX,BP
	INT	21H
	retc
	ADD	DX,AX
	CMP	AX,CX				; If not =, AX<CX, carry set.
	retnz
	CALL	NORMALIZE
K64IO:
	CLC
	MOV	CX,DI
	JCXZ	IORET
	MOV	AX,BP
	INT	21H
	retc
	ADD	DX,AX
	CMP	AX,CX				; If not =, AX<CX, carry set.
	retnz
	CALL	NORMALIZE
	MOV	CX,DI
K64M1:
	PUSH	CX
	XOR	AX,AX
	OR	DX,DX
	JZ	NORMIO
	MOV	CX,10H
	SUB	CX,DX
	MOV	AX,BP
	INT	21H
	JC	IORETP
	ADD	DX,AX
	CMP	AX,CX				; If not =, AX<CX, carry set.
	JNZ	IORETP
	CALL	NORMALIZE
NORMIO:
	MOV	CX,0FFFFH
	SUB	CX,AX
	MOV	AX,BP
	INT	21H
	JC	IORETP
	ADD	DX,AX
	CMP	AX,CX				; If not =, AX<CX, carry set.
	JNZ	IORETP
	CALL	NORMALIZE			; Clears carry
	POP	CX
	LOOP	K64M1
	PUSH	CX
IORETP:
	POP	CX
IORET:
	return


;*********************************
; Shift DI:SI left 4 bits
DISIX4:
	MOV	CX,4
SH32:
	SHL	SI,1
	RCL	DI,1
	LOOP	SH32
	return

;*********************************
; Shift DI:SI right 4 bits
DISID4:
	MOV	CX,4
SH32B:
	SHR	DI,1
	RCR	SI,1
	LOOP	SH32B
	return

;********************************
; Normalize DS:DX

NORMALIZE:
	PUSH	DX
	PUSH	AX
	SHR	DX,1
	SHR	DX,1
	SHR	DX,1
	SHR	DX,1
	MOV	AX,DS
	ADD	AX,DX
	MOV	DS,AX
	POP	AX
	POP	DX
	AND	DX,0FH				; Clears carry
	return

;-------------------------------------------------------------------------------
; Phase1Initialisation:
;    This routine MUST set up fatSpace, and fBigFat
;    It also does most of the other initialisation
;
;    Algorithm:
;	Open a handle for accessing the drive
;	Get device parameters
;	save device parameters for exit
;	Check switches against parameters
;	Use switches to modify device parameters
;	directorySector = malloc( Bytes Per Sector )
;	fatSpace = malloc( Bytes Per Sector * Sectors Per Fat )
;	Calculate start sector (first sector not used by DOS)
;	fBigFat = (((Total Sectors - StartSector)/Sectors Per Cluster) >= 4086)
;
Phase1Initialisation:

; Get device parameters
	lea	dx,[deviceParameters]
	mov	[deviceParameters.DP_SPECIALFUNCTIONS], 0
	call	GetDeviceParameters
	jnc	GotDeviceParameters
	Message msgFormatNotSupported		;				;AC000;
						;lea	 dx, ptr_msgFormatNotSupported
						;call	 std_printf
	jmp	FEXIT
GotDeviceParameters:

; Save the device parameters for when we exit
	lea	si,[deviceParameters]
	lea	di,[savedDeviceParameters]
; MASM worked LENGTH out as the number of elements a variable was
; declared with and SIZE as the bytes they take up.  The arrays these
; ask about are all of bytes, so the two come to the same number.
	mov	cx, sizeof.A_DEVICEPARAMETERS
	push	ds
	pop	es
	rep	movsb

; Ensure that there is a valid number of sectors in the track table
	mov	[savedDeviceParameters.DP_TRACKTABLEENTRIES], 0
	mov	byte [validSavedDeviceParameters], 1

; Initialise this to zero to know if CheckSwitches defined the track layout
	mov	[deviceParameters.DP_TRACKTABLEENTRIES], 0

	call	Set_BPB_Info				;an000; dms; Check to see if we are on
							; FAT system.  If not set BPB to proper
							; values for format.
SetMTsupp:

; Check switches against parameters and use switches to modify device parameters
	call	CheckSwitches
	retc

IF ShipDisk

	test	word [SWITCHMAP],SWITCH_Z ;an000; dms;1 sector/cluster disk?
;	if$	nz								;an000; dms;yes
	JZ IF19$$
		mov	byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER],01h ;an000; dms;set BPB accordingly
		call	Calc_Small_FAT						;an000; dms;calc FAT size
;	endif$									;an000; dms;
IF19$$:

end if


	cmp	[deviceParameters.DP_TRACKTABLEENTRIES], 0
	jne	TrackLayoutSet			; There is a good track layout

; Store sector table info
	mov	cx, word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK]
	mov	[deviceParameters.DP_TRACKTABLEENTRIES], cx
	mov	ax, 1
	mov	bx, word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR]
	lea	di,[deviceParameters.DP_SECTORTABLE]
LoadSectorTable:
	stosw
	xchg	ax, bx
	stosw
	xchg	ax, bx
	inc	ax
	loop	LoadSectorTable
TrackLayoutSet:

;
; directorySector = malloc( Bytes Per Sector )
;
	mov	bx, word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR]
	add	bx, 0fH
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	mov	ah, Alloc
	int	21H
	retc
	mov	word [directorySector+2], ax
	xor	ax,ax
	mov	word [directorySector], ax

;
; fatSpace = malloc( Bytes Per Sector * Sectors Per FAT )
;
	mov	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR]
	add	ax, 0fH
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	mul	word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERFAT]
	mov	[Paras_Per_Fat],ax  ;AN005;128k FAT
	mov	bx,ax
	mov	ah,Alloc
	int	21H
	retc
	mov	word [fatSpace+2],ax
	xor	ax,ax
	mov	word [fatSpace],ax

	call	SetStartSector
	call	SetfBigFat

	clc
	return

;Phase1Initialisation endp

;-------------------------------------------------------------------------------

SetStartSector:

; startSector = number of reserved sectors
;	 + number of FAT Sectors	( Number of FATS * Sectors Per FAT )
;	 + number of directory sectors	( 32* Root Entries / bytes Per Sector )
;					( above is rounded up )

; Calculate the number of directory sectors
	mov	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_ROOTENTRIES]
	mov	bx, sizeof.dir_entry
	mul	bx
	add	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR]
	dec	ax
	xor	dx,dx
	div	word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR]
	mov	[sectorsInRootDirectory],ax
	mov	[startSector], ax

; Calculate the number of FAT sectors
	mov	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERFAT]
	mul	byte [deviceParameters.DP_BPB+A_BPB.BPB_NUMBEROFFATS]
; Add in the number of boot sectors
	add	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_RESERVEDSECTORS]
	add	[startSector], ax

	return

;SetStartSector endp

;-------------------------------------------------------------------------------

SetfBigFat:
;
; fBigFat = ( ( (Total Sectors - Start Sector) / Sectors Per Cluster) >= 4086 )
;
	cmp	word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS+2],0 ; > 32mb part?	;AN000;
;	IF$	NE				;Yes, big FAT	;AC000;
	JE IF21$$
	   mov	   byte [fBigFat], TRUE ;Set flag	;AN000;
;	ELSE$					;Nope, < 32,b	 ;AC000;
	JMP SHORT EN21$$
IF21$$:
	   mov	   ax,word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS] ;Assume this used ;AN000;
	   cmp	   ax,0 			;Was this field used?		 ;AN000;
;	   IF$	   E				;Nope, use the other sector field;AN000;
	   JNE IF23$$
	      mov     ax, word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS] ;		      ;AC000;
						;** Fix for PTM PCDOS P51
;	   ENDIF$				;				;AN000;
IF23$$:
	   sub	   ax,[startSector] ;Get sectors in data area
	   xor	   dx,dx
	   xor	   bx,bx
	   mov	   bl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER]
	   div	   bx				;Get total clusters
	   cmp	   ax,BIG_FAT_THRESHOLD 	;Is clusters >= 4086?
;	   IF$	   AE
	   JNAE IF25$$
	      mov     byte [fBigFat],TRUE ;16 bit FAT if >=4096
						;** END fix for PTM PCDOS P51
;	   ENDIF$
IF25$$:
;	ENDIF$
EN21$$:
	return

;SetfBigFat endp

;-------------------------------------------------------------------------------
;
;    Phase2Initialisation:
;	Use device parameters to build information that will be
;	required for each format
;
;    Algorithm:
;	Calculate first head/cylinder to format
;	Calculate number of tracks to format
;	Calculate the total bytes on the disk and save for later printout
;	First initialise the directory buffer
;
Phase2Initialisation:

; Calculate first track/head to format (round up - kludge)
	mov	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_HIDDENSECTORS]
	mov	dx, word [deviceParameters.DP_BPB+A_BPB.BPB_HIDDENSECTORS+2]
	add	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK]
	adc	dx, 0
	dec	ax
	sbb	dx, 0
	div	word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK]
	xor	dx,dx
	div	word [deviceParameters.DP_BPB+A_BPB.BPB_HEADS]
	mov	[firstCylinder], ax
	mov	[firstHead], dx

; Calculate the total number of tracks to be formatted (round down - kludge)
	mov	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS]
	xor	dx,dx
; if (TotalSectors == 0) then use BigTotalSectors
	or	ax,ax
	jnz	NotBigTotalSectors
	mov	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS]
	mov	dx, word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS+2]

NotBigTotalSectors:
	div	word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK]
	mov	[tracksPerDisk], ax

; Initialise the directory buffer
; Clear out the Directory Sector before any information is inserted.
	mov	cx, word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR]
	les	di, [directorySector]
	xor	ax,ax
	rep	stosb

	mov	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR]
	xor	dx, dx
	mov	bx, sizeof.dir_entry
	div	bx
	mov	cx, ax

	les	bx, [directorySector]
; If Old_Dir = TRUE then put the first letter of each directory entry must be 0E5H
	xor	al, al
	cmp	byte [Old_Dir], TRUE
	jne	StickE5
	mov	al, 0e5H
StickE5:
	mov	[es:bx], al
	add	bx, sizeof.dir_entry
	loop	StickE5

	ret

;Phase2Initialisation endp

;-------------------------------------------------------------------------------
;
;   SetDeviceParameters:
;      Set the device parameters
;
;   Input:
;      drive
;      dx - pointer to device parameters
;
SetDeviceParameters:

	mov	ax, (IOCtl shl 8) or GENERIC_IOCTL
	mov	bl, [drive]
	inc	bl
	mov	cx, (RAWIO shl 8) or SET_DEVICE_PARAMETERS
	int	21H
	return

;SetDeviceParameters endp

;-------------------------------------------------------------------------------
;
;   GetDeviceParameters:
;      Get the device parameters
;
;   Input:
;      drive
;      dx - pointer to device parameters
;
GetDeviceParameters:

	mov	ax, (IOCtl shl 8) or GENERIC_IOCTL
	mov	bl, [drive]
	inc	bl
	mov	cx, (RAWIO shl 8) or GET_DEVICE_PARAMETERS
	int	21H
	return

;GetDeviceParameters endp

;-------------------------------------------------------------------------------
;
;    DiskFormat:
;	Format the tracks on the disk
;	Since we do our SetDeviceParameters here, we also need to
;	detect the legality of /N /T if present and abort with errors
;	if not.
;	This routine stops as soon as it encounters a bad track
;	Then BadSector is called to report the bad track, and it continues
;	the format
;
;    Algorithm:
;	Initialise in memory FAT
;	current track = first
;	while not done
;	   if format track fails
;	      DiskFormatErrors = true
;	      return
;	   next track

DiskFormat:


;
; Initialise fatSpace
;


	push	es

	call	Fat_Init			;an000; initialize the FAT

	mov	di, word [fatSpace+2]    ;an000; get segment of FAT
	mov	es, di				;an000; place it in es
	mov	di, word [fatSpace]    ;Should be 0
	mov	al, byte [deviceParameters.DP_BPB+A_BPB.BPB_MEDIADESCRIPTOR]
	mov	ah, 0ffH
	stosw
	mov	ax, 00ffH
	test	byte [fBigFat], TRUE
	jz	NotBig
	mov	ax, 0ffffH
NotBig: stosw
	pop	es

; don't bother to do the formatting if /c was given
	test	word [SWITCHMAP], SWITCH_C
	jz	Keep_Going
	jmp	FormatDone			;FormatDone is to far away

Keep_Going:
foofoo	=	INSTALL_FAKE_BPB or TRACKLAYOUT_IS_GOOD
	mov	[deviceParameters.DP_SPECIALFUNCTIONS], foofoo
	lea	dx,[deviceParameters]

	call	SetDeviceParameters

	call	Cluster_Buffer_Allocate 					;an000; dms;get room for retry buffer

	call	Prompt_User_For_Disk						;an016; dms;

	test	word [SWITCHMAP],SWITCH_8 ; DCL 5/12/86 avoid Naples AH=18h
	jnz	StdBPB				; lackof support for 8 sectors/track

						; DCL 5/12/86
						; Always do the STATUS_FOR_FORMAT test, as we don't know if the machine
						; has this support.  For 3.2 /N: & /T: were not documented & therefore
						; not fully supported thru the ROM of Aquarius & Naples & Royal Palm

						;test	 SwitchMap, SWITCH_N or SWITCH_T	 ; IF ( /N or /T ) ;; DCL 5/12/86
						;jz	 StdBPB
						;   THEN check if
						;     supported
	mov	[formatPacket.FP_SPECIALFUNCTIONS], STATUS_FOR_FORMAT
	mov	ax, (IOCtl shl 8) or GENERIC_IOCTL
	mov	bl, [drive]
	inc	bl
	mov	cx, (RAWIO shl 8) or FORMAT_TRACK
	lea	dx,[formatPacket]
	int	21H
						; switch ( FormatStatusCall)

						;cmp	 FormatPacket.FP_SpecialFunctions, Format_No_ROM_Support
						;jb	 NTSupported			 ; 0 returned from IBMBIO
						;ja	 IllegalComb			 ; 2 returned - ROM Support
						;   Illegal Combination!
	cmp	[formatPacket.FP_SPECIALFUNCTIONS],0
	je	NTSupported
	cmp	[formatPacket.FP_SPECIALFUNCTIONS],2
;	IF$	E				;				;AC000;
	JNE IF28$$
	   Message msgInvalidParameter		;				;AC000;
	   mov	   byte [Fatal_Error],YES ;Indicate quittin'type err!     ;AN000;
;	ELSE$					;				;     ;
	JMP SHORT EN28$$
IF28$$:
	   cmp	   [formatPacket.FP_SPECIALFUNCTIONS],3 ; 			   ;	 ;
;	   IF$	   E				;				;AC000;
	   JNE IF30$$
		   mov	   ax,error_not_ready	;flag not ready 		;an000;dms;
		   call    CheckError		; set error level		;an017; dms;
		   jmp	   FRMTPROB		; exit program			;an017; dms;
;	   ELSE$				; DCL No ROM support is okay	;     ;
	   JMP SHORT EN30$$
IF30$$:
						; except for /N: & /T:		;     ;
	      test    word [SWITCHMAP], SWITCH_N or SWITCH_T ; DCL 5/12/86		      ;     ;
;	      IF$     NZ			;				;AC000;
	      JZ IF32$$
		 Message msgParametersNotSupported ;				   ;AC000;
		 mov	 byte [Fatal_Error],YES ;Indicate quittin'type err!     ;AN000;
;	      ENDIF$				;				;AN000;
IF32$$:
;	   ENDIF$				;				;AN000;
EN30$$:
;	ENDIF$					;				;AN000;
EN28$$:
	cmp	byte [Fatal_Error],YES ;				;AN000;
	jne	StdBPB				;				;AN000;
	jmp	FEXIT
;
; We have the support to carry out the FORMAT
;
NTSupported:
StdBPB:
						;call	 DSKPRM 		 ; prompt user for disk ;; DCL 5/12/86
	mov	[formatPacket.FP_SPECIALFUNCTIONS], 0
	mov	ax, [firstHead]
	mov	[formatPacket.FP_HEAD], ax
	mov	ax, [firstCylinder]
	mov	[formatPacket.FP_CYLINDER], ax
	mov	cx, [tracksPerDisk]
	mov	[tracksLeft], cx
	mov	byte [Format_End],FALSE ;an015; dms;flag not at end of format
	call	Calc_Max_Tracks_To_Format					;an015; dms;max track count for FormatTrack call
FormatLoop:
	call	Format_Loop							;an015; dms;Format until CY occurs

	cmp	byte [Format_End],TRUE ;an015; dms;End of Format?
;	if$	e								;an015; dms;yes
	JNE IF36$$
		mov	byte [formatError],0 ;an015; dms;signal good format
		clc								;an015; dms;clear CY
;	else$									;an015; dms;bad format
	JMP SHORT EN36$$
IF36$$:
		call	CheckError						;an015; dms;determine type of error
;		if$	nc							;an015; dms;
		JC IF38$$
			call	LastChanceToSaveIt				;an015; dms;acceptable error?
;			if$	c						;an015; dms;yes
			JNC IF39$$
				mov	byte [formatError],1 ;an015; dms;signal error type
				clc						;an015; dms;clear CY
;			else$							;an015; dms;not acceptable error
			JMP SHORT EN39$$
IF39$$:
				call	SetStartSector				;an015; dms;start from scratch
				call	SetfBigFat				;an015; dms;
				push	ax					;an015; dms;
				call	Phase2Initialisation			;an015; dms;
				clc						;an015; dms;
				pop	ax					;an015; dms;
				jmp	DiskFormat				;an015; dms;try again
;			endif$							;an015; dms;
EN39$$:
;		endif$								;an015; dms;
IF38$$:
;	endif$									;an015; dms;
EN36$$:
	return

FormatDone:
	mov	byte [formatError],0
	clc
	return

;DiskFormat endp


;-------------------------------------------------------------------------------
;
;    BadSector:
;	Reports the bad sectors.
;	Reports the track where DiskFormat stopped.
;	From then on it formats until it reaches a bad track, or end,
;	and reports that.
;
;    Output:
;	Carry: set --> fatal error
;	if Carry not set
;	   ax - The number of consecutive bad sectors encountered
;		ax == 0 --> no more bad sectors
;	   bx - The logical sector number of the first bad sector
;
;    Algorithm:
;	if DiskFormatErrors
;	   DiskFormatErrors = false
;	   return current track
;	else
;	   next track
;	   while not done
;	      if format track fails
;		 return current track
;	      next track
;	   return 0

BadSector:


; don't bother to do the formatting if /c was given
	test	word [SWITCHMAP], SWITCH_C
	jnz	NoMoreTracks

	test	byte [formatError], 0ffH
	jz	ContinueFormat
	mov	byte [formatError], 0
	jmp	ReportBadTrack

ContinueFormat:
	call	Adj_Track_Count 						;an015; dms;decrease track counter
	call	NextTrack							;an015; dms;adjust head and cylinder
	cmp	byte [Format_End],TRUE ;an015; dms;end of format?
;	if$	ne								;an015; dms;no
	JE IF44$$
		call	Format_Loop						;an015; dms;format until CY
		cmp	byte [Format_End],TRUE ;an015; dms;end of format?
;		if$	ne							;an015; dms;no
		JE IF45$$
			call	CheckError					;an015; dms;must be error - which error?
;			if$	nc						;an015; dms;non-fatal error?
			JC IF46$$
				call	CurrentLogicalSector			;an015; dms;yes - get position
				mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK] ;an015; dms; set track size
				clc						;an015; dms;signal O.K. to continue
;			endif$							;an015; dms;
IF46$$:
;		else$								;an015; dms;
		JMP SHORT EN45$$
IF45$$:
			jmp	NoMoreTracks					;an015; dms;end of format
;		endif$								;an015; dms;
EN45$$:
;	else$									;an015; dms;
	JMP SHORT EN44$$
IF44$$:
		jmp	NoMoreTracks						;an015; dms;end of format
;	endif$									;an015; dms;
EN44$$:
	return									;an015; dms;

ReportBadTrack:
	call	CurrentLogicalSector
	mov	ax, word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK]
	clc
	return

NoMoreTracks:
	test	word [SWITCHMAP],(SWITCH_SELECT or SWITCH_AUTOTEST) ;Don't display done msg;AN000;
;	IF$	Z				; if EXEC'd by SELECT           ;AN000;
	JNZ IF52$$
	   Message msgFormatComplete		;				;AC000;
;	ENDIF$					;				;AN000;
IF52$$:
	mov	ax, 0
	clc
	return

;BadSector endp



;-------------------------------------------------------------------------------

end if
if SEGSEL = S_DATA

;ptr_msgCurrentTrack dw offset msgCurrentTrack
currentHead dw	0
currentCylinder dw 0

end if
if SEGSEL = S_CODE

;=========================================================================
; Calc_Current_Head_Cyl : Obtain the current head and cylinder of the
;			  track being formatted.
;
;	Inputs: FP_Cylinder	- Cylinder of track being formatted
;		FP_Head 	- Head of track being formatted
;=========================================================================

Procedure Calc_Current_Head_Cyl 						;an000; dms;

	push	cx								;an000; dms;save cx
	mov	cx,[formatPacket.FP_CYLINDER]   ;an000; dms;get current cylinder
	mov	[currentCylinder],cx    ;an000; dms;put into variable
	mov	cx,[formatPacket.FP_HEAD]    ;an000; dms;get current head
	mov	[currentHead],cx     ;an000; dms;put into variable
	pop	cx								;an000; dms;restore cx
	ret									;an000; dms;

;Calc_Current_Head_Cyl	endp							;an000; dms;


DisplayCurrentTrack:

	push	dx				;				;AN000;
	push	cx				;				;AN000;
	push	ax				;an015; dms;

	mov	ax,[Tracks_To_Format] ;an015; dms;get track count

	add	[Formatted_Tracks_Low],ax ;Indicate formatted a track	;AN000;
	adc	[Formatted_Tracks_High],0 ;				;AN000;
	mov	ax,[Formatted_Tracks_Low] ;				;AN000;
	mov	bx,[Formatted_Tracks_High] ;				;AN000;
	mov	cx,100				;Make integer calc for div	;AN000;
	call	Multiply_32_Bits		; BX:AX = (Cyl * Head *100)	;AN000;
	mov	dx,bx				;Set up divide			;AN000;
	div	[tracksPerDisk] ;% = (Cyl * Head *100)/ # tracks;AN000;
	cmp	ax,[PercentComplete] ;Only print message when change ;AN000;
;	IF$	NE				;To avoid excess cursor splat	;AN000;
	JE IF54$$
	   mov	   [PercentComplete],ax ;Save it if changed		;AN000;
	   Message msgCurrentTrack		;				;AC000;
;	ENDIF$					;
IF54$$:
	pop	ax				;an015; dms;
	pop	cx				;Restore register		;AN000;
	pop	dx				;				;AN000;
	return

;DisplayCurrentTrack endp


;-------------------------------------------------------------------------------
;    CheckError:
;	Input:
;	   ax - extended error code
;	Ouput:
;	   carry set if error is fatal
;	   Message printed if Not Ready or Write Protect
;
CheckError:
	cmp	ax, error_write_protect
	je	WriteProtectError
	cmp	ax, error_not_ready
	je	NotReadyError
	cmp	word [currentCylinder], 0
	jne	CheckRealErrors
	cmp	word [currentHead], 0
	je	BadTrackZero

CheckRealErrors:
	cmp	ax, error_CRC
	je	JustABadTrack
	cmp	ax, error_sector_not_found
	je	JustABadTrack
	cmp	ax, error_write_fault
	je	JustABadTrack
	cmp	ax, error_read_fault
	je	JustABadTrack
	cmp	ax, error_gen_failure
	je	JustABadTrack

	stc
	ret

JustABadTrack:
	clc
	ret

WriteProtectError:

	test	word [SWITCHMAP],SWITCH_SELECT ;an017; dms;SELECT option?
;	if$	z								;an017; dms;no - display messages
	JNZ IF56$$
		Message  msgCRLF			;			;AC006;
		Message  msgCRLF			;			;AC006;
		Extended_Message			;			;AC006;
;	else$									;an017; dms;yes - set error level
	JMP SHORT EN56$$
IF56$$:
		mov	byte [ExitStatus],ExitWriteProtect ;an017; dms;signal write protect error
;	endif$									;an017; dms;
EN56$$:

	stc									;an017; dms;signal fatal error
	ret									;an017; dms;return to caller

NotReadyError:
	test	word [SWITCHMAP],SWITCH_SELECT ;an017; dms; SELECT option?
;	if$	z								;an017; dms; no - display messages
	JNZ IF59$$
		Message  msgCRLF			;			;AC006;
		Message  msgCRLF			;			;AC006;
		Extended_Message			;			;AC006;
;	else$									;an017; dms;yes - set error level
	JMP SHORT EN59$$
IF59$$:
		mov	byte [ExitStatus],ExitDriveNotReady ;an017; dms;signal drive not ready
;	endif$									;an017; dms;
EN59$$:
	stc
	ret


BadTrackZero:
	Message msgDiskUnusable 		;				;AC000;
	stc
	ret

;CheckError endp

;-------------------------------------------------------------------------------
;    WriteFileSystem:
;	Write the boot sector and FATs out to disk
;	Clear the directory sectors to zero
;

WriteFileSystem:


	call	WriteBootSector
	retc

	Set_Data_Segment			;Set DS,ES = DATA		;AN000;
; Write out each of the FATs
	push	ds				;ac005; dms;save ds
	xor	cx, cx
	mov	cl, byte [es:deviceParameters.DP_BPB+A_BPB.BPB_NUMBEROFFATS] ;		;AC000;
	mov	dx, word [es:deviceParameters.DP_BPB+A_BPB.BPB_RESERVEDSECTORS] ;		;AC000;
	mov	al, [es:drive] ;				;AC000;
	mov	bx,word [es:fatSpace+2]   ;Get segment of memory Fat	;AC000;
	mov	ds,bx				;				;AN000;
	mov	bx,word [es:fatSpace]    ;				;AN000;

	mov	si,bx				;ac005; dms;set up for add. calc
	call	seg_adj 			;ac005; dms;get adjusted seg:off
	mov	bx,si				;ac005; dms;get new off
;	assume	ds:nothing,es:data		;				;AN000;

;	do$					;ac005; dms;while FATS > 0
DO62$$:
		cmp	cx,00			;ac005; dms;FATS remaining?
;		leave$	e			;ac005; dms;no
		JE EN62$$
		push	bx			;ac005; dms;save FAT offset
		push	ds			;ac005; dms;save FAT segment
		push	cx			;ac005; dms;save FAT count
		push	dx			;ac005; dms;reserved FAT sector
		call	write_fat		;ac005; dms;write the FAT
		pop	dx			;ac005; dms;get 1st. FAT sector
		pop	cx			;ac005; dms;get FAT count
		pop	ds			;ac005; dms;restore FAT segment
		pop	bx			;ac005; dms;restore FAT offset
;		if$	c			;ac005; dms;an error occurred
		JNC IF64$$
			Message msgFATwriteError;ac005; dms;say why failed
			jmp	FEXIT		;ac005; dms;exit format
;		endif$				;ac005; dms;
IF64$$:
		add	dx, word [es:deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERFAT] ;		;AC000;
		dec	cx			;ac005; dms;decrease FAT count
;	enddo$					;ac005; dms;
	JMP SHORT DO62$$
EN62$$:

	pop	ds				;ac005; dms;restore ds
;	assume	ds:data 			;ac005; dms;


; Clear the directory

; Now write the initialised directory sectors out to disk
	mov	ax, word [es:deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERFAT] ;		;AC000;
	xor	dx,dx
	push	bx								;an000; dms;save bx
	xor	bx,bx								;an000; dms;clear bx
	mov	bl,byte [es:deviceParameters.DP_BPB+A_BPB.BPB_NUMBEROFFATS] ;an000; dms;get FAT count
	mul	bx								;an000; dms;get total FAT sectors
	pop	bx								;an000; dms;restore bx

	mov	dx, word [es:deviceParameters.DP_BPB+A_BPB.BPB_RESERVEDSECTORS] ;		;AC000;
	add	dx, ax
	mov	cx, [es:sectorsInRootDirectory] ;				  ;AC000;
WriteDIRloop:
	push	cx
	push	dx
	mov	al, [es:drive] ;				;AC000;
	mov	cx, 1
	lds	bx, [es:directorySector] ;				;AC000;

;	assume	ds:nothing,es:data		;				;AN000;

;Assume dir is alway contined in first 32mb of partition

	mov	[es:Read_Write_Relative.Start_Sector_High],0 ;			;AC000;
	Call	Write_Disk			;				;AN000;
	jnc	Dir_OK				;				;AC000;
	Message msgDirectoryWriteError		;				;AC000;
	jmp	FEXIT				;				;AN000;
Dir_OK: 					;				;AN000;
	pop	dx
	add	dx, 1
	pop	cx
	loop	WriteDIRloop

	Set_Data_Segment			;Set DS to DATA segment 	;AN000;
; Ok, we can tell the device driver that we are finished formatting
	mov	[es:savedDeviceParameters.DP_TRACKTABLEENTRIES], 0
	mov	[es:savedDeviceParameters.DP_SPECIALFUNCTIONS], TRACKLAYOUT_IS_GOOD
	lea	dx,[savedDeviceParameters]
	call	SetDeviceParameters

	MOV	AH,Disk_Reset			; Flush any directories in
	INT	21H				; buffers

	return


;WriteFileSystem endp

;=========================================================================
; WRITE_FAT	:	This routine writes the logical sector count requested.
;			It will write a maximum of 40h sectors.  If more
;			than 40h exists it will continue looping until
;			all sectors have been written.
;
;	Inputs	:	AL - Drive letter
;			DS:BX - Segment:offset of transfer address
;			CX - Sector count
;			DX - 1st. sector
;
;	Outputs :	Logical sectors written
;=========================================================================

;	assume	ds:data,es:nothing	; the routines from here on read
					; their data through DS

Procedure	write_fat

	mov	cx, word [es:deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERFAT] ;		;AC000;

;	do$					;an000;while sectors left
DO67$$:
		cmp	cx,00h			;an000;any sectors?
;		leave$	e			;an000;no
		JE EN67$$

		cmp	cx,40h
;		if$	a			;an000;yes
		JNA IF69$$
			push	cx		;an000;save cx
			mov	cx,40h
			push	ax		;an000;save ax
			call	Write_Disk	;an000;write it
			pop	ax		;an000;restore ax
			pop	cx		;an000;restore cx
			jc	Write_Exit	;an000;exit if fail
			mov	si,8000h
			call	seg_adj 	;an000;adjust segment
			mov	bx,si		;an000;new offset
			add	dx,40h
			sub	cx,40h
;		else$				;an000;< 64k
		JMP SHORT EN69$$
IF69$$:
			push	ax		;an000;save ax
			call	Write_Disk	;an000;write it
			pop	ax		;an000;restore ax
			xor	cx,cx		;an000;set cx to 0 - last read
;		endif$
EN69$$:
;	enddo$
	JMP SHORT DO67$$
EN67$$:

	Write_Exit:

	ret

;write_fat	endp

;=========================================================================
; SEG_ADJ	:	This routine adjusts the segment:offset to prevent
;			address wrap.
;
;	Inputs	:	SI - Offset to adjust segment with
;			DS - Segment to be adjusted
;
;	Outputs :	SI - New offset
;			DS - Adjusted segment
;=========================================================================

Procedure	seg_adj

	push	ax
	push	cx
	push	dx
	mov	ax,si				;an000;get offset
	mov	bx,0010h			;an000;16
	xor	dx,dx				;an000;clear dx
	div	bx				;an000;get para count
;	if$	c				;an000;overflow?
	JNC IF73$$
		adc	bx,0			;an000;pick it up
;	endif$					;an000;
IF73$$:
	mov	bx,ds				;an000;get seg
	add	bx,ax				;an000;adjust for paras
	mov	ds,bx				;an000;save new seg
	mov	si,dx				;an000;new offset
	pop	dx
	pop	cx
	pop	ax
	ret

;seg_adj 	endp

;-------------------------------------------------------------------------------
;	format is done... so clean up the disk!
;
Done:


	call	OemDone
	return

;Done	endp

;-------------------------------------------------------------------------------
;    CurrentLogicalSector:
;	Get the current logical sector number
;
;    Input:
;	current track = tracksPerDisk - tracksLeft
;	SectorsPerTrack
;
;    Output:
;	BX = logical sector number of the first sector in the track we
;	     just tried to format
;
CurrentLogicalSector:

	push	ax								;an000; dms;save regs
	push	bx								;an000; dms;
	push	dx								;an000; dms;

	mov	ax, [tracksPerDisk]
	sub	ax, [tracksLeft]
	xor	dx,dx								;an000; dms;clear dx
	mul	word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK]
	mov	word [Relative_Sector_High],dx      ;an000; dms;save high word of sector #
	mov	word [Relative_Sector_Low],ax       ;an000; dms;save low word of sector #

	pop	dx								;an000; dms;restore regs
	pop	bx								;an000; dms;
	pop	ax								;an000; dms;

	return

;CurrentLogicalSector endp

;-------------------------------------------------------------------------------
;    PrintErrorAbort:
;	Print an error message and abort
;
;    Input:
;	dx - Pointer to error message string
;
PrintErrorAbort:

	push	dx
	call	crlf
	pop	dx
	call	PrintString

	jmp	FEXIT

;PrintErrorAbort endp




;*****************************************************************************
;Routine name: Multiply_32_Bits
;*****************************************************************************
;
;Description: A real sleazy 32 bit x 16 bit multiply routine. Works by adding
;	      the 32 bit number to itself for each power of 2 contained in the
;	      16 bit number. Whenever a bit that is set in the multiplier (CX)
;	      gets shifted to the bit 0 spot, it means that that amount has
;	      been multiplied so far, and it should be added into the total
;	      value. Take the example CX = 12 (1100). Using the associative
;	      rule, this is the same as CX = 8+4 (1000 + 0100). The
;	      multiply is done on this principle - whenever a bit that is set
;	      is shifted down to the bit 0 location, the value in BX:AX is
;	      added to the running total in DI:SI. The multiply is continued
;	      until CX = 0. The routine will exit with CY set if overflow
;	      occurs.
;
;
;Called Procedures: None
;
;Change History: Created	7/23/87 	MT
;
;Input: BX:AX = 32 bit number to be multiplied
;	CX = 16 bit number to be multiplied. (Must be even number)
;
;Output: BX:AX = output.
;	 CY set if overflow
;
;Psuedocode
;----------
;
;	Point at ControlC_Handler routine
;	Set interrupt handler (INT 21h, AX=2523h)
;	ret
;*****************************************************************************

;Public Multiply_32_Bits
Multiply_32_Bits:        ;				;AN000;

	push	di				;				;AN000;
	push	si				;				;AN000;
	xor	di,di				;Init result to zero
	xor	si,si				;
	cmp	cx,0				;Multiply by 0? 		;AN000;
;	IF$	NE				;Keep going if not		;AN000;
	JE IF75$$
;	   DO$					;This works by adding the result;AN000;
DO76$$:
	      test    cx,1			;Need to add in sum of this bit?;AN000;
;	      IF$     NZ			;Yes				;AN000;
	      JZ IF77$$
		 add	 si,ax			;Add in the total so far for	;AN000;
		 adc	 di,bx			; this bit multiplier (CY oflow);AN000;
;	      ELSE$				;Don't split multiplier         ;AN000;
	      JMP SHORT EN77$$
IF77$$:
		 clc				;Force non exit 		;AN000;
;	      ENDIF$				;				;AN000;
EN77$$:
;	   LEAVE$  C				;Leave on overflow		;AN000;
	   JC EN76$$
	      shr     cx,1			;See if need to multiply value	;AN000;
	      cmp     cx,0			;by 2				;AN000;
;	   LEAVE$  E				;Done if cx shifted down to zero;AN000;
	   JE EN76$$
	      add     ax,ax			;Each time cx is shifted, add	;AN000;
	      adc     bx,bx			;value to itself (Multiply * 2) ;AN000;
;	   ENDDO$  C				;CY set on overflow		;AN000;
	   JNC DO76$$
EN76$$:
;	   IF$	   NC				;If no overflow, add in DI:SI	;AN000;
	   JC IF83$$
	      mov     ax,si			; which contains the original	;AN000;
	      mov     bx,di			; value if odd, 0 if even. This ;AN000;
	      clc				;Set no overflow flag		;AN000;
;	   ENDIF$				;				;AN000;
IF83$$:
;	ELSE$					;
	JMP SHORT EN75$$
IF75$$:
	   xor	   ax,ax			;
	   xor	   bx,bx			;
;	ENDIF$					;Multiply by 0			;AN000;
EN75$$:
	pop	si				;				;AN000;
	pop	di				;				;AN000;
	ret					;				;AN000;

;Multiply_32_Bits endp


;=========================================================================
; Divide_32_Bits	- This routine will perform 32bit division
;
;	Inputs	: SI:DI - value to be divided
;		  CX	- divisor
;
;	Outputs : SI:DI - result
;		  CX	- remainder
;=========================================================================

Procedure Divide_32_Bits							;an000; dms;

	push	ax								;an000; dms;save regs
	push	bx								;an000; dms;
	push	dx								;an000; dms;

	xor	dx,dx								;an000; dms;clear dx
	mov	ax,si								;an000; dms;get high word
	div	cx								;an000; dms;get high word result
	mov	si,ax								;an000; dms;save high word result

	mov	ax,di								;an000; dms;get low word
	div	cx								;an000; dms;get low word result
	mov	di,ax								;an000; dms;save low word result
	mov	cx,dx								;an000; dms;pick up remainder

	pop	dx								;an000; dms;restore regs
	pop	bx								;an000; dms;
	pop	ax								;an000; dms;

	ret									;an000; dms;

;Divide_32_Bits	endp								;an000; dms;




;=========================================================================
; FAT_INIT:		This routine initializes the FAT based on the
;			number of paragraphs.
;
;
; input - fatspace
;	  fatspace+2
;	  paras_per_fat
;	  fat_init_value
; output - fat space is initialized
;
;=========================================================================
;Public		Fat_Init
Fat_Init:

	push	es
	push	di
	push	ax
	push	bx
	push	cx
	mov	di, word [fatSpace+2]    ;Get segment of Fat space	;AC000;
	mov	es,di				;				;AN000;
	mov	di, word [fatSpace]    ;				;AN000;
	mov	bx,[Paras_Per_Fat] ;an000;get number of paras
	mov	ax,[Fat_Init_Value] ;an000;
	push	dx				;an000;save bx
	mov	dx,es				;an000;grab es into dx
;	do$
DO87$$:
		cmp	bx,0			;an000;do while bx not = 0
;		leave$	e			;an000;exit if 0
		JE EN87$$
		mov	cx,10h			;an000;word move of paragraph
		rep	stosb			;an000;move the data to FAT
		xor	di,di			;an000;offset always init to 0
		inc	dx			;an000;next paragraph
		mov	es,dx			;an000;put next para in es
		dec	bx			;an000;loop iteration counter
;	enddo$					;an000;
	JMP SHORT DO87$$
EN87$$:
	pop	dx				;an000;
	pop	cx				;an000;
	pop	bx				;an000;
	pop	ax				;an000;
	pop	di				;an000;
	pop	es				;an000;

	ret					;an000;

;Fat_Init	endp				;an000;


;=========================================================================
; Ctrl_Break_Write	: This routine takes the control break request
;			  an returns.  In essence, it disables the CTRL-BREAK.
;			  This routine is used during the writing of the
;			  FAT, DIR, and SYSTEM.
;=========================================================================

Ctrl_Break_Write:				;ac010; dms;

	iret					;ac010; dms;return to caller


;=========================================================================
; Ctrl_Break_Save	: This routine gets the current vector of
;			  INT 23h and saves it in CTRL_BREAK_VECTOR.
;
;	Inputs	: none
;
;	Outputs : CTRL_BREAK_VECTOR - holds address of INT 23h routine
;=========================================================================

Ctrl_Break_Save:            ;ac010; dms;

	push	es				;ac010; dms;save es
	push	bx				;ac010; dms;save bx
	push	ax				;ac010; dms;save ax

	mov	ax,3523h			;ac010; dms;get CTRL-BREAK
						;	    interrupt vector
	int	21h				;ac010; dms;

	mov	word [CTRL_BREAK_VECTOR],bx   ;ac010; dms;get vector offset
	mov	word [CTRL_BREAK_VECTOR+2],es   ;ac010; dms;get vector segment

	pop	ax				;ac010; dms;restore ax
	pop	bx				;ac010; dms;restore bx
	pop	es				;ac010; dms;restore es

	ret					;ac010; dms;


;Ctrl_Break_Save 	endp			;ac010; dms;


;=========================================================================
; Set_Ctrl_Break	: This routine sets the CTRL-Break vector to one
;			  defined by the user.
;
;	Inputs	: none
;
;	Outputs : CTRL_BREAK_VECTOR - holds address of INT 23h routine
;=========================================================================

Set_Ctrl_Break:            ;ac010; dms;

	push	ds				;ac010; dms;save ds
	push	ax				;ac010; dms;save ax
	push	bx				;ac010; dms;save bx
	push	dx				;ac010; dms;save dx

	push	cs				;ac010; dms;swap cs with ds
	pop	ds				;an000; dms;point to code seg

	mov	dx,Ctrl_Break_Write        ;ac010; dms;get interrupt vec.
	mov	ax,2523h			;ac010; dms;set CTRL-BREAK
						;	    interrupt vector
	int	21h				;ac010; dms;

	pop	dx				;ac010; dms;restore dx
	pop	bx				;ac010; dms;restore bx
	pop	ax				;ac010; dms;restore ax
	pop	ds				;ac010; dms;restore ds

	ret					;ac010; dms;


;Set_Ctrl_Break		endp			;ac010; dms;


;=========================================================================
; Reset_Ctrl_Break	: This routine resets the CTRL-Break vector to that
;			  originally defined.
;
;	Inputs	: CTRL_BREAK_VECTOR - holds address of INT 23h routine
;
;	Outputs : none
;=========================================================================

Reset_Ctrl_Break:           ;ac010; dms;

	push	ds				;ac010; dms;save ds
	push	ax				;ac010; dms;save ax
	push	bx				;ac010; dms;save bx
	push	dx				;ac010; dms;save ds

	mov	ax,word [CTRL_BREAK_VECTOR+2]   ;ac010; dms;get seg. of vector
	mov	bx,word [CTRL_BREAK_VECTOR]   ;ac010; dms;get off. of vector
	mov	ds,ax				;ac010; dms;get seg.
	mov	dx,bx				;ac010; dms;get off.
	mov	ax,2523h			;ac010; dms;set CTRL-BREAK
						;	    interrupt vector
	int	21h				;ac010; dms;

	pop	dx				;ac010; dms;restore dx
	pop	bx				;ac010; dms;restore bx
	pop	ax				;ac010; dms;restore ax
	pop	ds				;ac010; dms;restore ds

	ret					;ac010; dms;


;Reset_Ctrl_Break	endp			;ac010; dms;

;=========================================================================
; Get_Command_Path		: This routine finds the path where
;				  COMMAND.COM resides based on the
;				  environmental vector.  Once the
;				  path is found it is copied to
;				  CommandFile.
;
;	Inputs	: Exec_Block.Segment_Env - Segment of environmental vector
;		  Comspec_ID		 - "COMSPEC="
;
;	Outputs : CommandFile		 - Holds path to COMMAND.COM
;=========================================================================

Procedure	Get_Command_Path		;an011; dms;

	push	ds				;an011; dms;save ds
	push	es				;an011; dms;save es

	Set_Data_Segment			;an011; dms; DS,ES = Data
	call	Get_PSP_Parms			;an011; dms; gets PSP info.
	cld					;an011; dms; clear direction
	mov	ax,[es:Environ_Segment] ;an011; dms; get seg. of
						;	     environ. vector
	mov	ds,ax				;an011; dms; put it in DS
;	assume	ds:nothing			;an011; dms;
	xor	si,si				;an011; dms; clear si
	mov	bx,si				;an011; dms; save si
	mov	di,Comspec_ID         ;an011; dms; point to target
	mov	cx,127				;an011; dms; loop 127 times
;	do$					;an011; dms; while cx not 0
DO90$$:
						;	     and target not found
		cmp	cx,00h			;an011; dms; end of env.?
;		leave$	e			;an011; dms; yes
		JE EN90$$

		push	cx			;an011; dms; save cx
		mov	cx,0008h		;an011; dms; loop 8 times
		repe	cmpsb			;an011; dms; "COMSPEC=" ?
		pop	cx			;an011; dms; restore cx
;		if$	z			;an011; dms; yes
		JNZ IF92$$
			push	di		;an011; dms; save di
			mov	di,CommandFile          ;an011; dms
			lodsb			;an011; dms; priming read
			mov	dl,al		;an011; dms; prepare for capitalization
			call	Cap_Char	;an011; dms; capitalize character in DL
			cmp	dl,[es:CommandFile] ;an011; dms;COMSPEC same as default drive?
;			if$	e		;an000; dms; yes
			JNE IF93$$
;				do$		;an011; dms; while AL not = 0
DO94$$:
				    cmp  al,00h ;an011; dms; at end?
;				    leave$  e	;an011; dms; yes
				    JE EN94$$
				    stosb	;an011; dms; save it
				    lodsb	;an011; dms; get character
;				enddo$
				JMP SHORT DO94$$
EN94$$:
;			endif$			;an011; dms;
IF93$$:
			pop	di		;an011; dms; restore di
			mov	cx,0ffffh	;an011; dms; flag target found
;		endif$				;an011; dms;
IF92$$:

		cmp	cx,0ffffh		;an011; dms; target found?
;		leave$	e			;an011; dms; yes
		JE EN90$$

		mov	di,Comspec_ID        ;an011; dms; point to target
		mov	si,bx			;an011; dms; restore si
		inc	si			;an011; dms; point to next byte
		mov	bx,si			;an011; dms; save si

		dec	cx			;an011; dms; decrease counter
;	enddo$					;an011; dms;
	JMP SHORT DO90$$
EN90$$:

	pop	es				;an011; dms; restore es
	pop	ds				;an011; dms; restore ds

	ret					;an011; dms;

;Get_Command_Path	endp			;an011; dms;


;
;****************************************************************************
; Get_PSP_Parms
;****************************************************************************
;
;
;
;

Procedure Get_PSP_Parms 			;				;AC000;

	Set_Data_Segment
	mov	ax,[PSP_Segment] ;Get segment of PSP		;AN000;
	mov	ds,ax				;  "  "    "  " 		;AN000;
						;     ;
;	assume	ds:nothing
						;Setup segment of Environment string, get from PSP			    ;	  ;

	mov	ax,[ds:PSP_Environ] ;				;     ;
	mov	[es:Environ_Segment],ax ;				;     ;
	Set_Data_Segment
	ret					;				;     ;


;Get_PSP_Parms endp				;				;AN000;


;=========================================================================
; Command_Root	:	This routine sets up CommandFile so that the
;			COMMAND.COM will be written to the root.
;			It does this by copying at offset 3 of CommandFile
;			the literal COMMAND.COM.  This effectively
;			overrides the original path, but maintains the
;			drive letter that is to be written to.
;
;	Inputs	:	CommandFile - Holds full path to default COMMAND.COM
;	Outputs :	CommandFile - Holds modified path to new COMMAND.COM
;				      on target drive.
;=========================================================================

Procedure	Command_Root			;an011; dms;

	push	ds				;an011; dms; save ds
	push	es				;an011; dms; save es
	push	di				;an011; dms; save di
	push	si				;an011; dms; save si
	push	cx				;an011; dms; save cx
	Set_Data_Segment			;an011;

	mov	di,CommandFile+3         ;an011; dms; point to path
						;	     past drive spec
	mov	si,Command_Com         ;an011; dms; holds the literal
						;	     COMMAND.COM
	mov	cx,000ch			;an011; dms; len. of literal
	rep	movsb				;an011; dms; move it

	pop	cx				;an011; dms; restore cx
	pop	si				;an011; dms; restore si
	pop	di				;an011; dms; restore di
	pop	es				;an011; dms; restore es
	pop	ds				;an011; dms; restore ds

	ret					;an011; dms;

;Command_Root	endp				;an011; dms;


;=========================================================================
; Set_BPB_Info	:	When we have a FAT count of 0, we must calculate
;			certain parts of the BPB.  The following code
;			will do just that.
;
;	Inputs	: DeviceParameters
;
;	Outputs : BPB information
;=========================================================================

Procedure Set_BPB_Info								;an012; dms;calc new BPB

	Set_Data_Segment							;an012; dms;set up addressibility
	cmp	byte [deviceParameters.DP_BPB+A_BPB.BPB_NUMBEROFFATS],00h ;an012; dms;see if we have 0 FATS specified
;	if$	e								;an012; dms;yes, 0 FATS specified
	JNE IF101$$
		call	Scan_Disk_Table 					;an012; dms;access disk table
		mov	bl,byte [ds:si+8]         ;an012; dms;get FAT type
		mov	cx,word [ds:si+4]         ;an012; dms;get sectors/cluster
		mov	dx,word [ds:si+6]         ;an012; dms;number of entries for the root DIR

		mov	word [deviceParameters.DP_BPB+A_BPB.BPB_ROOTENTRIES],dx ;an012; dms;save root entries
		mov	byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER],ch ;an012; dms;save sectors/cluster
		mov	word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR],0200h ;an012; dms;save bytes/sector
		mov	word [deviceParameters.DP_BPB+A_BPB.BPB_RESERVEDSECTORS],0001h ;an012; dms;save reserved sectors
		mov	byte [deviceParameters.DP_BPB+A_BPB.BPB_NUMBEROFFATS],02h ;an012; dms;FAT count

		cmp	bl,Fbig 						;an012; dms;Big FAT?
;		if$	e							;an012; dms;yes
		JNE IF102$$
			call	Calc_Big_FAT					;an012; dms;calc big FAT info
;		else$								;an012; dms;
		JMP SHORT EN102$$
IF102$$:
			call	Calc_Small_FAT					;an012; dms;calc small FAT info
;		endif$								;an012; dms;
EN102$$:
;	endif$									;an012; dms;
IF101$$:

	ret									;an012; dms;

;Set_BPB_Info	endp								;an012; dms;



;=========================================================================
; Scan_Disk_Table	: Scans the table containing information on
;			  the disk's attributes.  When it finds the
;			  applicable data, it returns a pointer in
;			  DS:SI for reference by the calling proc.
;
;	Inputs	: DiskTable - Contains data about disk types
;
;	Outputs : DS:SI     - Points to applicable disk data
;=========================================================================

Procedure Scan_Disk_Table							;an012; dms;

	cmp	word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS],00h ;an012; dms;small disk?
;	if$	ne								;an012; dms;yes
	JE IF106$$
		mov	dx,00h							;an012; dms;set high to 0
		mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS] ;an012; dms;get sector count
;	else$									;an012; dms;
	JMP SHORT EN106$$
IF106$$:
		mov	dx,word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS++2] ;an012; dms;get high count
		mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS++0] ;an012; dms;get low count
;	endif$									;an012; dms;
EN106$$:

	mov	si,DiskTable             ;an012; dms;point to disk data
Scan:

	cmp	dx,word [ds:si]          ;an012; dms;below?
	jb	Scan_Disk_Table_Exit						;an012; dms;yes, exit
	ja	Scan_Next							;an012; dms;no, continue
	cmp	ax,word [ds:si+2]          ;an012; dms;below or equal?
	jbe	Scan_Disk_Table_Exit						;an012; dms;yes, exit

Scan_Next:

	add	si,5*2								;an012; dms;adjust pointer
	jmp	Scan								;an012; dms;continue scan

Scan_Disk_Table_Exit:

	ret									;an012; dms;

;Scan_Disk_Table endp								;an012; dms;



;=========================================================================
; Calc_Big_FAT	:	Calculates the sectors per FAT for a 16 bit FAT.
;
;	Inputs	: DeviceParameters.DP_BPB.BPB_BigTotalSectors	or
;		  DeviceParameters.DP_BPB.BPB_TotalSectors
;
;	Outputs : DeviceParameters.DP_BPB.BPB_SectorsPerFat
;=========================================================================

Procedure Calc_Big_FAT								;an012; dms;

	cmp	word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS],00h ;an012; dms;small disk?
;	if$	ne								;an012; dms;yes
	JE IF109$$
		mov	dx,00h							;an012; dms;set high to 0
		mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS] ;an012; dms;get sector count
;	else$									;an012; dms;
	JMP SHORT EN109$$
IF109$$:
		mov	dx,word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS++2] ;an012; dms;get high count
		mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS++0] ;an012; dms;get low count
;	endif$									;an012; dms;
EN109$$:

	mov	cl,04h								;an012; dms;16 DIR entries per sector
	push	dx								;an012; dms;save total sectors (high)
	mov	dx,word [deviceParameters.DP_BPB+A_BPB.BPB_ROOTENTRIES] ;an012; dms;get root entry count
	shr	dx,cl								;an012; dms;divide by 16
	sub	ax,dx								;an012; dms;
	pop	dx								;an012; dms;restore dx
	sbb	dx,0								;an012; dms;
	sub	ax,1								;an012; dms;AX = T - R - D
	sbb	dx,0								;an012; dms;
	mov	bl,02h								;an012; dms;
	mov	bh,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER] ;an012; dms;get sectors per cluster
	add	ax,bx								;an012; dms;AX = T-R-D+256*SPC+2
	adc	dx,0								;an012; dms;
	sub	ax,1								;an012; dms;AX = T-R-D+256*SPC+1
	sbb	dx,0								;an012; dms;
	div	bx								;an012; dms; sec/FAT = CEIL((TOTAL-DIR-RES)/
										;			    (256*SECPERCLUS+2)
	mov	word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERFAT],ax ;an012; dms;Sectors/cluster
	ret									;an012; dms;

;Calc_Big_FAT	endp								;an012; dms;


;=========================================================================
; Calc_Small_FAT:	Calculates the sectors per FAT for a 12 bit FAT.
;
;	Inputs	: DeviceParameters.DP_BPB.BPB_BigTotalSectors	or
;		  DeviceParameters.DP_BPB.BPB_TotalSectors
;
;	Outputs : DeviceParameters.DP_BPB.BPB_SectorsPerFat
;=========================================================================

Procedure Calc_Small_FAT							;an012; dms;

	cmp	word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS],00h ;an012; dms;small disk?
;	if$	ne								;an012; dms;yes
	JE IF112$$
		mov	dx,00h							;an012; dms;set high to 0
		mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS] ;an012; dms;get sector count
;	else$									;an012; dms;
	JMP SHORT EN112$$
IF112$$:
		mov	dx,word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS++2] ;an012; dms;get high count
		mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS++0] ;an012; dms;get low count
;	endif$									;an012; dms;
EN112$$:

	xor	bx,bx								;an012; dms;clear bx
	mov	bl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER] ;an012; dms;get sectors/cluster
	div	bx								;an012; dms;
; now multiply by 3/2
	mov	bx,3								;an012; dms;
	mul	bx								;an012; dms;div by log 2 of sectors/cluster
	mov	bx,2								;an012; dms;
	div	bx								;an012; dms;
	xor	dx,dx								;an012; dms;
; now divide by 512
	mov	bx,512								;an012; dms;
	div	bx								;an012; dms;
	inc	ax								;an012; dms;
; dx:ax contains number of FAT sectors necessary
	mov	word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERFAT],ax ;an012; dms;save sectors/FAT
	ret									;an012; dms;

;Calc_Small_FAT	endp								;an012; dms;

;=========================================================================
; Get_Bad_Sector_Hard	: Determine the bad sector.
;
;	Inputs	: Head of failing track
;		  Cylinder of failing track
;		  Relative_Sector_Low		- 1st. sector in track
;		  Relative_Sector_High
;
;		  Cluster_Boundary_Adj_Factor	- The number of sectors
;						  that are to be read
;						  at one time.
;		  Cluster_Boundary_SPT_Count	- Used by Calc_Cluster_Boundary
;						  to track how many sectors
;						  have been read.
;		  Cluster_Boundary_Flag 	- True (Use cluster buffer)
;						- False (Use internal buffer)
;		  Cluster_Boundary_Buffer_Seg	- Segment of buffer
;
;	Outputs : Marked cluster as bad
;=========================================================================

Procedure Get_Bad_Sector_Hard							;an000; dms;

	push	cx								;an000; dms;save cx
	mov	cx,0001h							;an000; dms;set counter to start at 1
	mov	word [Cluster_Boundary_SPT_Count],00h ;an000; dms;clear sector counter
	mov	word [Cluster_Boundary_Adj_Factor],01h ;an000; dms;default value
;	do$									;an000; dms;while sectors left
DO115$$:
		cmp	cx,word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK] ;an000; dms;at end?
;		leave$	a							;an000; dms;yes,exit
		JA EN115$$
		push	cx							;an000; dms;save cx

		cmp	byte [Cluster_Boundary_Flag],TRUE ;an000; dms;full buffer there?
;		if$	e							;an000; dms;yes
		JNE IF117$$
			call	Calc_Cluster_Boundary				;an000; dms;see if on boundary
			mov	ax,[Cluster_Boundary_Buffer_Seg]
			mov	word [RWPacket.TRWP_TRANSFERADDRESS+0],0    ;an000; dms;point to transfer area
			mov	word [RWPacket.TRWP_TRANSFERADDRESS+2],ax    ;an000; dms;
;		else$								;an000; dms;default to internal buffer
		JMP SHORT EN117$$
IF117$$:
			mov	word [RWPacket.TRWP_TRANSFERADDRESS+0],RW_TRF_Area            ;an000; dms;point to transfer area
			mov	word [RWPacket.TRWP_TRANSFERADDRESS+2],DS    ;an000; dms;
;		endif$								;an000; dms;
EN117$$:

		call	Verify_Structure_Set_Up 				;an019; dms; set up verify vars

		mov	ax,(IOCtl shl 8) or GENERIC_IOCTL			;an000; dms;
		xor	bx,bx							;an000; dms;clear bx
		mov	bl,[drive]    ;an000; dms;get drive
		inc	bl							;an000; dms;adjust it
		mov	cx,(IOC_DC shl 8) or READ_TRACK 			;an000; dms;read track
		lea	dx,[RWPacket]    ;an000; dms;point to parms
		int	21h							;an000; dms;

		pop	cx							;an000; dms;restore cx

		push	cx							;an000; dms;save cx

;		if$	c							;an000; dms;an error occurred
		JNC IF120$$
			call	Calc_Cluster_Position				;an000; dms;determine which cluster
			call	BadClus 					;an000; dms;mark the cluster as bad
;		endif$								;an000; dms;
IF120$$:

		pop	cx							;an000; dms;restore cx

		add	cx,[Cluster_Boundary_Adj_Factor]  ;an000; dms;adjust loop counter
		mov	ax,[Cluster_Boundary_Adj_Factor]  ;an000; dms;get adjustment factor
		xor	dx,dx							;an000; dms;clear dx
		add	ax,[Relative_Sector_Low]   ;an000; dms;add in low word
		adc	dx,[Relative_Sector_High]   ;an000; dms;pick up carry in high word
		mov	[Relative_Sector_Low],ax   ;an000; dms;save low word
		mov	[Relative_Sector_High],dx   ;an000; dms;save high word


;	enddo$									;an000; dms;
	JMP SHORT DO115$$
EN115$$:

	pop	cx								;an000; dms;restore cx

	ret									;an000; dms;

;Get_Bad_Sector_Hard	endp							;an000; dms;


;=========================================================================
; Verify_Structure_Set_Up	: Set up the fields for the Read IOCTL
;				  to verify the sectors in a failing
;				  track.  Also, it displays the
;				  message notifying the user of the
;				  sectors it is verifying.
;=========================================================================

Procedure	Verify_Structure_Set_Up 					;an019; dms;set up verify structure

	mov	[RWPacket.TRWP_SPECIALFUNCTIONS],00h  ;an000; dms;reset special functions

	mov	ax,[formatPacket.FP_HEAD]    ;an000; dms;get current head
	mov	[RWPacket.TRWP_HEAD],ax    ;an000; dms;get current head

	mov	ax,[formatPacket.FP_CYLINDER]   ;an000; dms;get current cylinder
	mov	[RWPacket.TRWP_CYLINDER],ax   ;an000; dms;get current cylinder

	dec	cx								;an000; dms;make sector 0 based
	mov	[RWPacket.TRWP_FIRSTSECTOR],cx   ;an000; dms;get sector to read

	mov	ax,[Cluster_Boundary_Adj_Factor]   ;an000; dms;get # of sectors to read
	mov	[RWPacket.TRWP_SECTORSTOREADWRITE],ax  ;an000; dms;read only # sector(s)

	call	Calc_Cluster_Position						;an019; dms;determine cluster number
	mov	word [Msg_Allocation_Unit_Val++2],dx       ;an019; dms;save high word of cluster
	mov	word [Msg_Allocation_Unit_Val++0],ax       ;an019; dms;save low word of cluster
	Message MsgVerify

	ret

;Verify_Structure_Set_Up endp							;an019; dms;


;=========================================================================
; Get_Bad_Sector_Floppy : This routine marks an entire track as bad
;			  since it is a floppy disk.
;
;	Inputs	: Relative_Sector_Low	- first sector
;
;	Outputs : FAT marked with bad sectors
;=========================================================================

Procedure Get_Bad_Sector_Floppy 						;an000; dms;

	push	bx								;an000; dms;save regs
	push	cx								;an000; dms;

	mov	cx,word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK] ;an000; dms;get sectors/track
;	do$									;an000; dms;while sectors left
DO123$$:
		cmp	cx,00							;an000; dms;at end
;		leave$	e							;an000; dms;yes
		JE EN123$$
		push	bx							;an000; dms;save bx we destroy it
		push	cx							;an000; dms;save cx we destroy it
		call	Calc_Cluster_Position					;an000; dms;get cluster position
		call	BadClus 						;an000; dms;mark it as bad
		pop	cx							;an000; dms;restore regs
		pop	bx							;an000; dms;
		dec	cx							;an000; dms;decrease loop counter
		inc	word [Relative_Sector_Low] ;an000; dms;next sector
;	enddo$									;an000; dms;
	JMP SHORT DO123$$
EN123$$:

	pop	cx								;an000; dms;restore regs
	pop	bx								;an000; dms;

	ret									;an000; dms;

;Get_Bad_Sector_Floppy	endp							;an000; dms;


;=========================================================================
; Calc_Cluster_Position : This routine calculates which cluster the
;			  failing sector falls in.
;
;	Inputs	: Relative_Sector_High	- high word of sector position
;		  Relative_Sector_Low	- low word of sector position
;
;	Outputs : DX:AX - Cluster position
;=========================================================================
Procedure Calc_Cluster_Position 						;an000; dms;

	push	cx								;an000; dms;save regs
	push	di								;an000; dms;
	push	si								;an000; dms;

	xor	dx,dx								;an000; dms;clear high word
	mov	dx,word [Relative_Sector_High]      ;an000; dms;get the high sector word
	mov	ax,word [Relative_Sector_Low]       ;an000; dms;get the low sector word
	sub	ax,[startSector]     ;an000; dms;get relative sector #
	sbb	dx,0								;an000; dms;pick up borrow

	mov	si,dx								;an000; dms;get high word
	mov	di,ax								;an000; dms;get low word
	xor	cx,cx								;an000; dms;clear cx
	mov	cl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER] ;an000; dms;get sectors/cluster
	call	Divide_32_Bits							;an000; dms;32 bit division

	mov	dx,si								;an000; dms;get high word of result
	mov	ax,di								;an000; dms;get low word of result
	add	ax,2								;an000; dms;adjust for cluster bias
	adc	dx,0								;an000; dms;pick up carry

	pop	si								;an000; dms;restore regs
	pop	di								;an000; dms;
	pop	cx								;an000; dms;

	ret									;an000 ;dms;

;Calc_Cluster_Position	endp							;an000; dms;


;=========================================================================
; Cap_Char	: This routine will capitalize the character passed in
;		  DL.
;
;	Inputs	: DL - Character to be capitalized
;
;	Outputs : DL - Capitalized character
;=========================================================================

Procedure Cap_Char								;an011; dms;

	push	ax								;an011; dms;save ax
	mov	ax,6520h							;an011; dms;capitalize character
	int	21h								;an011; dms;
	pop	ax								;an011; dms;restore ax
	ret									;an011; dms;

;Cap_Char	endp								;an011; dms;

;=========================================================================
; Set_Disk_Access_On_Off: This routine will either turn access on or off
;			  to a disk depending on the contents of the
;			  buffer passed in DX.
;
;	Inputs	: DX - pointer to buffer
;
;=========================================================================

Procedure Set_Disk_Access_On_Off						;an014; dms;

	push	ax								;an014; dms;save regs
	push	bx								;an014; dms;
	push	cx								;an014; dms;
	push	dx								;an014; dms;

	xor	bx,bx								;an014; dms;clear bx
	mov	bl,[drive]     ;an014; dms;get driver number
	inc	bl								;an014; dms;make it 1 based
	call	IsRemovable							;an014; dms;see if removable media
;	if$	c								;an014; dms;not removable
	JNC IF126$$
		mov	ax,(IOCtl shl 8) or GENERIC_IOCTL			;an014; dms;generic ioctl
		xor	bx,bx							;an014; dms;clear bx
		mov	bl,[drive]    ;an014; dms;get drive letter
		inc	bl							;an014; dms;make it 1 based
		mov	cx,(RAWIO shl 8) or SET_ACCESS_FLAG			;an014; dms;allow access to disk
		int	21h							;an014; dms;
;	endif$									;an014; dms;
IF126$$:

	pop	dx								;an014; dms;restore regs
	pop	cx								;an014; dms;
	pop	bx								;an014; dms;
	pop	ax								;an014; dms;

	ret									;an014; dms;

;Set_Disk_Access_On_Off	endp							;an014; dms;


;=========================================================================
; Get_Disk_Access	: This routine will determine the access state of
;			  the disk.
;
;	Inputs	: DX - pointer to buffer
;	Outputs : Disk_Access.DAC_Access_Flag - 0ffh signals access allowed
;						to the disk previously.
;
;=========================================================================

Procedure Get_Disk_Access							;an014; dms;

	push	ax								;an014; dms;save regs
	push	bx								;an014; dms;
	push	cx								;an014; dms;
	push	dx								;an014; dms;

	xor	bx,bx								;an014; dms;clear bx
	mov	bl,[drive]     ;an014; dms;get driver number
	inc	bl								;an014; dms;make it 1 based
	call	IsRemovable							;an014; dms;see if removable media
;	if$	c								;an014; dms;not removable
	JNC IF128$$
		mov	ax,(IOCtl shl 8) or GENERIC_IOCTL			;an014; dms;generic ioctl
		xor	bx,bx							;an014; dms;clear bx
		mov	bl,[drive]    ;an014; dms;get drive letter
		inc	bl							;an014; dms;make it 1 based
		mov	cx,(RAWIO shl 8) or GET_ACCESS_FLAG			;an014; dms;determine disk access
		lea	dx,[Disk_Access]    ;an014; dms;point to parm list
		int	21h							;an014; dms;
		cmp	[Disk_Access.DAC_ACCESS_FLAG],01h  ;an014; dms;access is currently allowed?
;		if$	e							;an014; dms;yes
		JNE IF129$$
			mov	[Disk_Access.DAC_ACCESS_FLAG],0ffh ;an014; dms;signal access is currently allowed
;		endif$								;an014; dms;
IF129$$:
;	endif$									;an014; dms;
IF128$$:

	pop	dx								;an014; dms;restore regs
	pop	cx								;an014; dms;
	pop	bx								;an014; dms;
	pop	ax								;an014; dms;

	ret									;an014; dms;

;Get_Disk_Access 	endp							;an014; dms;

;=========================================================================
; Calc_Cluster_Boundary : This routine will determine where, within a
;			  cluster, a sector resides.
;
;	Inputs	: Relative_Sector_Low		- Sector
;		  Relative_Sector_High
;
;	Outputs : Cluster_Boundary_Adj_Factor	- The number of sectors
;						  remaining in the cluster.
;		  Cluster_Boundary_SPT_Count	- The count of sectors
;						  having been accessed for
;						  a track.
;=========================================================================

Procedure Calc_Cluster_Boundary 						;an000; dms;

	push	ax								;an000; dms;save regs
	push	bx								;an000; dms;
	push	cx								;an000; dms;
	push	dx								;an000; dms;
	push	si								;an000; dms;
	push	di								;an000; dms;

	xor	dx,dx								;an000; dms;clear high word
	mov	dx,word [Relative_Sector_High]      ;an000; dms;get the high sector word
	mov	ax,word [Relative_Sector_Low]       ;an000; dms;get the low sector word
	sub	ax,[startSector]     ;an000; dms;get relative sector #
	sbb	dx,0								;an000; dms;pick up borrow

	mov	si,dx								;an000; dms;get high word
	mov	di,ax								;an000; dms;get low word
	xor	cx,cx								;an000; dms;clear cx
	mov	cl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER] ;an000; dms;get sectors/cluster
	call	Divide_32_Bits							;an000; dms;32 bit division

	or	cx,cx								;an000; dms;see if remainder exists
;	if$	nz								;an000; dms;remainder exists
	JZ IF132$$
		xor	bx,bx							;an021; dms;
		mov	bl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER] ;an021; dms;get sectors/cluster
		sub	bx,cx							;an021; dms;get number of sectors to read
		mov	[Cluster_Boundary_Adj_Factor],bx  ;ac021; dms;remainder = sector count
;	else$									;an000; dms;no remainder
	JMP SHORT EN132$$
IF132$$:
		xor	bx,bx							;an000; dms;clear bx
		mov	bl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER] ;an000; dms;get sectors/cluster
		mov	[Cluster_Boundary_Adj_Factor],bx  ;an000; dms;get sectors/cluster
;	endif$									;an000; dms;
EN132$$:

	mov	ax,[Cluster_Boundary_SPT_Count]   ;an000; dms;get current sector count
	xor	dx,dx								;an000; dms;clear high word
	add	ax,[Cluster_Boundary_Adj_Factor]   ;an000; dms;get next sector count
	cmp	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK] ;an000; dms;exceeded sectors/track?
;	if$	a								;an000; dms;yes
	JNA IF135$$
		mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK] ;an000; dms;only use difference
		sub	ax,[Cluster_Boundary_SPT_Count]  ;an000; dms;get next sector count
		mov	[Cluster_Boundary_Adj_Factor],ax  ;an000; dms;
;	endif$									;an000; dms;
IF135$$:

	mov	ax,[Cluster_Boundary_SPT_Count]   ;an000; dms;get sector count
	xor	dx,dx								;an000; dms;clear high word
	add	ax,[Cluster_Boundary_Adj_Factor]   ;an000; dms;get new sector count
	mov	[Cluster_Boundary_SPT_Count],ax   ;an000; dms;save it

	pop	di								;an000; dms;restore regs
	pop	si								;an000; dms;
	pop	dx								;an000; dms;restore regs
	pop	cx								;an000; dms;
	pop	bx								;an000; dms;
	pop	ax								;an000; dms;

	ret									;an000; dms;

;Calc_Cluster_Boundary	endp							;an000; dms;

;=========================================================================
; Cluster_Buffer_Allocate	: This routine will allocate a buffer
;				  based on a cluster's size.  If enough
;				  space does not exist, a cluster will
;				  be redefined to a smaller size for
;				  purposes of sector retries.
;
;	Inputs	: DeviceParameters.DP_BPB.BPB_BytesPerSector
;		  DeviceParameters.DP_BPB.BPB_SectorsPerCluster
;
;	Outputs : Cluster_Boundary_Flag 	- True (space available)
;						  False(not enough space)
;		  Cluster_Boundary_Buffer_Seg	- Pointer to buffer
;=========================================================================

Procedure Cluster_Buffer_Allocate						;an000; dms;

	push	ax								;an000; dms;save regs
	push	bx								;an000; dms;
	push	cx								;an000; dms;
	push	dx								;an000; dms;

	mov	ax,(Alloc shl 8)						;an000; dms;allocate memory
	mov	bx,0ffffh							;an000; dms;get available memory
	int	21h								;an000; dms;

	mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR] ;an000; dms;get bytes/sector
	xor	dx,dx								;an000; dms;clear high word
	xor	cx,cx								;an000; dms;clear cx
	mov	cl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER] ;an000; dms;get sector count
	mul	cx								;an000; dms;get total byte count
	mov	cl,4								;an000; dms;set up shift count
	shr	ax,cl								;an000; dms;divide by 16
	inc	ax								;an000; dms;round up

	cmp	bx,ax								;an000; dms;enough room
;	if$	a								;an000; dms;yes
	JNA IF137$$
		mov	bx,ax							;an000; dms;allocate needed memory
		mov	ax,(Alloc shl 8)					;an000; dms;
		int	21h							;an000; dms;
		mov	[Cluster_Boundary_Buffer_Seg],ax  ;an000; dms;save pointer to buffer
		mov	byte [Cluster_Boundary_Flag],TRUE ;an000; dms;signal space available
;	else$									;an000; dms;not enough room
	JMP SHORT EN137$$
IF137$$:
		mov	byte [Cluster_Boundary_Flag],FALSE ;an000; dms;signal not enough space
;	endif$									;an000; dms;
EN137$$:

	pop	dx								;an000; dms;restore regs
	pop	cx								;an000; dms;
	pop	bx								;an000; dms;
	pop	ax								;an000; dms;

	ret									;an000; dms;

;Cluster_Buffer_Allocate endp							;an000; dms;


;=========================================================================
; Set_CDS_Off			- This routine disallows access to a
;				  disk if a format fails on a non-FAT
;				  formatted disk.
;
;=========================================================================

Procedure Set_CDS_Off								;an000; dms;

	push	ax								;an000; dms;save regs
	push	dx								;an000; dms;

	mov	ax,5f08h							;an000; dms;reset CDS
	mov	dl,[drive]     ;an000; dms;drive to reset
	int	21h								;an000; dms;

	pop	dx								;an000; dms;restore regs
	pop	ax								;an000; dms;

	ret									;an000; dms;

;Set_CDS_Off	endp								;an000; dms;


;=========================================================================
; Format_Access_Wrap_Up 	- This routine determines whether or
;				  not access should be allowed to the
;				  disk based on the exit status of
;				  format.
;
;=========================================================================

Procedure Format_Access_Wrap_Up 						;an000; dms;

	cmp	[Disk_Access.DAC_ACCESS_FLAG],0ffh  ;an015; dms;access prev. allowed?
;	if$	ne								;an015; dms;no
	JE IF140$$
		cmp	byte [ExitStatus],ExitOK ;an015; dms;good exit?
;	       if$     ne							;an015; dms;no
	       JE IF141$$
		       lea     dx,[Disk_Access]   ;an015; dms;point to parm block
		       mov     [Disk_Access.DAC_ACCESS_FLAG],00h ;an015; dms;signal no disk access
		       call    Set_Disk_Access_On_Off				;an015; dms;don't allow disk access
;	       else$								;an015; dms;bad exit
	       JMP SHORT EN141$$
IF141$$:
		       lea     dx,[Disk_Access]   ;an015; dms;point to parm block
		       mov     [Disk_Access.DAC_ACCESS_FLAG],01h ;an015; dms;signal disk access
		       call    Set_Disk_Access_On_Off				;an015; dms;allow disk access
;	       endif$								;an015; dms;
EN141$$:
;	endif$									;an015; dms;
IF140$$:

	cmp	byte [FAT_Flag],NO ;an012; dms;non-FAT format?
;	if$	e								;an012; dms;yes
	JNE IF145$$
		cmp	byte [ExitStatus],ExitOK ;an012; dms;good exit?
;		if$	ne							;an012; dms;no
		JE IF146$$
			call	Set_CDS_Off					;an012; dms;disallow FAT access
;		endif$								;an012; dms;
IF146$$:
;	endif$									;an012; dms;
IF145$$:

	ret									;an000; dms;

;Format_Access_Wrap_Up	endp							;an000; dms;

;=========================================================================
; BadClus_Address_Adjust	- This routine adjusts the segment and
;				  offset to provide addressibility into
;				  the FAT table.
;
;	Inputs	: bx	- high word to adjust segment for
;		  ax	- low word to adjust segment for
;		  cx	- segment to be adjusted
;
;	Outputs : cx	- new segment value
;		  ax	- new offset value
;=========================================================================

Procedure BadClus_Address_Adjust						;an000; dms;

	push	bx								;an000; save regs
	push	dx								;an000;
	push	di								;an000;
	push	si								;an000;

	mov	dx,cx								;an000; save segment value
	mov	si,bx								;an000; get high word for divide
	mov	di,ax								;an000; get low word for divide
	xor	cx,cx								;an000; clear cx
	mov	cl,Paragraph_Size						;an000; divide by 16
	call	Divide_32_Bits							;an000; perform division

	add	dx,di								;an000; adjust segment for result
	mov	ax,cx								;an000; pick up the remainder
	mov	cx,dx								;an000; pass back new segment

	pop	si								;an000; restore regs
	pop	di								;an000;
	pop	dx								;an000;
	pop	bx								;an000;

	ret									;an000; dms;

;BadClus_Address_Adjust	endp							;an000; dms;



;=========================================================================
; NextTrack	: This routine determines the next track to be
;		  formatted.
;
;	Inputs	: TracksLeft		- # of tracks remaining
;		  Tracks_To_Format	- # of tracks to format in 1 call
;		  FP_Head		- disk head
;		  FP_Cylinder		- disk cylinder
;
;	Outputs : TracksLeft		- # of tracks remaining
;		  FP_Head		- disk head
;		  FP_Cylinder		- disk cylinder
;		  CY			- no tracks left to format
;		  NC			- tracks left to format
;=========================================================================

Procedure NextTrack								;an015; dms;


	cmp	word [tracksLeft],00 ;an015; dms;end of format?
;	if$	e								;an015; dms;yes
	JNE IF149$$
		stc								;an015; dms;signal end of format
		mov	byte [Format_End],TRUE
;	else$
	JMP SHORT EN149$$
IF149$$:
		mov	cx,[Tracks_To_Format]   ;an015; dms;get max track count for call
;		do$								;an015; dms;while tracks remain
DO151$$:
			cmp	word [tracksLeft],00 ;an015; dms;end of format?
;			leave$	e						;an015; dms;yes
			JE EN151$$
			cmp	cx,00						;an015; dms;end of head/cyl. adjustment?
;			leave$	e						;an015; dms;yes
			JE EN151$$
			inc	[formatPacket.FP_HEAD]  ;an015; dms;next head
			mov	ax,[formatPacket.FP_HEAD]  ;an015; dms;get head for comp
			cmp	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_HEADS] ;an015; dms;exceeded head count?
;			if$	e						;an015; dms;yes
			JNE IF154$$
				mov	[formatPacket.FP_HEAD],00 ;an015; dms;reinit. head
				inc	[formatPacket.FP_CYLINDER] ;an015; dms;next cylinder
;			endif$							;an015; dms;
IF154$$:

			dec	cx						;an015; dms;decrease counter
;		enddo$								;an015; dms;
		JMP SHORT DO151$$
EN151$$:

		clc								;an015; dms;clear CY
;	endif$									;an015; dms;
EN149$$:

	ret									;an015; dms;

;NextTrack	endp								;an015; dms;

;=========================================================================
; Determine_Format_Type : This routine determines the type of format
;			  that is to occur based on the media type.
;
;	Inputs	: Dev_HardDisk		- Media type (harddisk)
;		  Multi_Track_Format	- EQU 02h
;		  Single_Track_Format	- EQU 00h
;
;	Outputs : FP_SpecialFunctions	- Set appropriately for single
;					  or multi track format
;=========================================================================

Procedure Determine_Format_Type 						;an015; dms;

	cmp	[deviceParameters.DP_DEVICETYPE],DEV_HARDDISK ;an015; dms;harddisk?
;	if$	e								;an015; dms;yes
	JNE IF158$$
		mov	[formatPacket.FP_SPECIALFUNCTIONS],Multi_Track_Format ;an015; dms;set for multi track format
;	else$									;an015; dms;
	JMP SHORT EN158$$
IF158$$:
		mov	[formatPacket.FP_SPECIALFUNCTIONS],Single_Track_Format ;an015; dms;set for single track format
;	endif$									;an015; dms;
EN158$$:
	ret									;an015; dms;

;Determine_Format_Type	endp							;an015; dms;


;=========================================================================
; FormatTrack		: This routine performs multi track or single
;			  track formatting based on the state of the
;			  SpecialFunctions byte.
;
;	Inputs	: Tracks_To_Format	- # of tracks to format in 1 call
;		  FormatPacket		- Parms for IOCTL call
;
;	Outputs : NC			- formatted track(s)
;		  CY			- error in format
;		  AX			- extended error on CY
;=========================================================================

Procedure FormatTrack								;an015; dms;

	mov	ax,(IOCtl shl 8) or GENERIC_IOCTL				;an015; dms;Generic IOCTL
	mov	bl,[drive]     ;an015; dms;get drive number
	inc	bl								;an015; dms;make it 1 based
	mov	cx,(RAWIO shl 8) or FORMAT_TRACK				;an015; dms;Format track(s)
	mov	dx,[Tracks_To_Format]    ;an015; dms;get track count
	mov	[formatPacket.FP_TRACKCOUNT],dx   ;an015; dms;put count in parms list
	lea	dx,[formatPacket]     ;an015; dms;ptr to parms
	int	21h								;an015; dms;

;	if$	c								;an015; dms;error?
	JNC IF161$$
		mov	ah,59h							;an015; dms;get extended error
		xor	bx,bx							;an015; dms;clear bx
		int	21h							;an015; dms;
		stc								;an015; dms;flag an error
;	endif$									;an015; dms;
IF161$$:

	ret									;an015; dms;

;FormatTrack	endp								;an015; dms;


;=========================================================================
; Determine_Track_Count 	: This routine determines the number of
;				  tracks to be formatted, based on whether
;				  or not we have a hard disk.  If we have
;				  a hard disk we can use multi-track
;				  format/verify, otherwise we use the
;				  single track format/verify.
;
;	Inputs	: Device_Type			- Media type
;
;	Outputs : Tracks_To_Format		- Max. number of tracks
;						  to be formatted in one
;						  call
;=========================================================================

Procedure Determine_Track_Count 						;an015; dms;

	cmp	[deviceParameters.DP_DEVICETYPE],DEV_HARDDISK ;an015; dms;harddisk?
;	if$	e								;an015; dms;yes
	JNE IF163$$
		call	Calc_Track_Count					;an015; dms;calc Tracks_To_Format
;	else$									;an015; dms;removable media
	JMP SHORT EN163$$
IF163$$:
		mov	word [Tracks_To_Format],0001h ;an015; dms;default to 1 track
;	endif$									;an015; dms;
EN163$$:

	ret									;an015; dms;

;Determine_Track_Count	endp							;an015;dms;


;=========================================================================
; Calc_Track_Count	: This routine determines if we have enough tracks
;			  remaining to use the max. number of tracks
;			  in the FormatTrack call.  If the tracks remaining
;			  to be formatted is less that the max. number of
;			  allowable tracks for the call, the max. number
;			  of allowable tracks is set to the remaining track
;			  count.
;
;	Inputs	: Track_Count - Max. number of allowable tracks to be
;				formatted in 1 FormatTrack call.
;		  TracksLeft  - Track count of remaining tracks to be
;				formatted.
;
;	Outputs : Tracks_To_Format - Count of the tracks to be formatted
;				     in the next FormatTrack call.
;
;
;=========================================================================

Procedure Calc_Track_Count							;an015; dms;

	push	ax								;an015; dms;save regs
	mov	ax,[Track_Count]     ;an015; dms;max bytes to format
	cmp	ax,[tracksLeft]     ;an015; dms;too many tracks?
;	if$	a								;an015; dms;yes
	JNA IF166$$
		mov	ax,[tracksLeft]    ;an015; dms;format remaining tracks
;	endif$									;an015; dms;
IF166$$:
	mov	[Tracks_To_Format],ax    ;an015; dms;save track count

	pop	ax								;an015; dms;

	ret									;an015; dms;

;Calc_Track_Count	endp							;an015; dms;

;=========================================================================
; Calc_Max_Tracks_To_Format	: This routine determines the maximum
;				  number of tracks to format at 1 time.
;
;	Inputs	: DeviceParameters - SectorsPerTrack
;				     BytesPerSector
;
;	Outputs : Track_Count	   - Max. # of tracks to format in 1 call
;				     to FormatTrack
;=========================================================================

Procedure Calc_Max_Tracks_To_Format

	push	ax								;an015; dms;save regs
	push	bx								;an015; dms;
	push	dx								;an015; dms;

	mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK] ;an015; dms;get sectors per track
	mov	bx,word [deviceParameters.DP_BPB+A_BPB.BPB_BYTESPERSECTOR] ;an015; dms;get byte count
	xor	dx,dx								;an015; dms;clear dx
	mul	bx								;an015; dms;get total byte count
	mov	bx,ax								;an015; dms;put count in bx
	mov	ax,Max_Format_Size						;an015; dms;max bytes to format
	div	bx								;an015; dms;get track count
	mov	[Track_Count],ax

	pop	dx								;an015; dms;
	pop	bx								;an015; dms;
	pop	ax								;an015; dms;

	ret

;Calc_Max_Tracks_To_Format	endp





;=========================================================================
; Format_Track_Retry	: This routine performs the retry logic for
;			  the format multi-track.  It will retry each track
;			  until the failing track is encountered through
;			  a CY condition.
;
;	Inputs	: none
;
;	Outputs : CY - indicates either a failing track or end of format
;
;
;=========================================================================

Procedure Format_Track_Retry

	clc									;an022; dms; clear existing CY
	mov	word [Tracks_To_Format],1 ;an015; dms; only format 1 track
;	do$									;an015; dms; while we have good tracks
DO168$$:
;		leave$	c							;an015; dms; exit on bad track
		JC EN168$$
		call	FormatTrack						;an015; dms; format the track
;		if$	nc							;an015; dms;error?
		JC IF170$$
			call	DisplayCurrentTrack				;an022; dms;adjust percent counter
			call	Adj_Track_Count
			call	NextTrack					;an015; dms;calc next track
;		endif$								;an015; dms;
IF170$$:
;	enddo$									;an015; dms;
	JMP SHORT DO168$$
EN168$$:

	ret									;an015; dms;

;Format_Track_Retry	endp							;an015; dms;

;=========================================================================
; Format_Loop			: This routine provides the main template
;				  for the formatting of a disk.  A disk
;				  will be formatted as long as there are
;				  tracks remaining to be formatted.
;				  This routine can be exited on a carry
;				  condition; i.e., bad track, last track, etc.
;
;	Inputs	: none
;
;	Outputs : CY - Set on exit from this routine
;		  AX - Possible error condition code
;=========================================================================

Procedure Format_Loop								;an015; dms;

	clc									;an015; dms;initialize to NC
;	do$									;an015; dms;while NC
DO173$$:
;		leave$	c							;an015; dms;exit on CY
		JC EN173$$
		call	Calc_Current_Head_Cyl					;an015; dms;head and cylinder calc.
		call	Determine_Format_Type					;an015; dms;floppy/hard media?
		call	Determine_Track_Count					;an015; dms;how many tracks?
		call	FormatTrack						;an015; dms;format track(s)
;		if$	c							;an015; dms;formattrack failed
		JNC IF175$$
			pushf							;an015; dms;save flags
			cmp	[deviceParameters.DP_DEVICETYPE],DEV_HARDDISK ;an015; dms;harddisk?
;			if$	e						;an015; dms;yes
			JNE IF176$$
				popf						;an015; dms;restore flags
				call	Format_Track_Retry			;an015; dms;find failing track
;			else$							;an015; dms;
			JMP SHORT EN176$$
IF176$$:
				popf						;an015; dms;restore flags
;			endif$							;an015; dms;
EN176$$:
;		endif$								;an015; dms;
IF175$$:

;		if$	c							;an015; dms;format error?
		JNC IF180$$
			pushf							;an015; dms;yes - save flags
			push	ax						;an015; dms;save return code
			call	CheckRealErrors 				;an015; dms;check error type
;			if$	nc						;an015; dms;if non-fatal
			JC IF181$$
				call	DisplayCurrentTrack			;an015; dms;display % formatted
;			endif$							;an015; dms;
IF181$$:
			pop	ax						;an015; dms;restore regs
			popf							;an015; dms;
;		endif$								;an015; dms;
IF180$$:

;		leave$	c							;an015; dms;exit on CY
		JC EN173$$

		call	DisplayCurrentTrack					;an015; dms;tell how much formatted
		call	Adj_Track_Count 					;an015; dms;decrease track counter
		call	NextTrack						;an015; dms;adjust head and cylinder
;	enddo$									;an015; dms;
	JMP SHORT DO173$$
EN173$$:
	ret									;an015; dms;

;Format_Loop	endp								;an015; dms;

;=========================================================================
; Adj_Track_Count	: This routine adjusts the track count by the
;			  number of tracks that have been formatted
;			  in one FormatTrack call.
;
;	Inputs	: TracksLeft	- # of tracks remaining to be formatted
;		  Tracks_To_Format - Tracks formatted in 1 call
;
;	Outputs : TracksLeft	- # of tracks remaining to be formatted
;=========================================================================

Procedure Adj_Track_Count							;an015; dms;

	push	ax								;an015; dms; save regs
	mov	ax,[tracksLeft]     ;an015; dms; get tracks remaining
	sub	ax,[Tracks_To_Format]    ;an015; dms; subtract amount formatted
	mov	[tracksLeft],ax     ;an015; dms; save new tracks remaining value
	pop	ax								;an015; dms; restore regs
	ret									;an015; dms;

;Adj_Track_Count endp								;an015; dms;

;=========================================================================
; Prompt_User_For_Disk		: This routine prompts the user for the
;				  disk to be formatted.  An appropriate
;				  message is chosen based on the type
;				  of switch entered.  If the /SELECT
;				  switch is entered, the disk prompt is
;				  issued through the INT 2fh services
;				  provided by SELECT.
;
;	Inputs	: Switchmap	- Switches chosen for format
;
;	Outputs : Message printed as appropriate.
;=========================================================================

Procedure Prompt_User_For_Disk							;an016;dms;

	push	ax								;an016;dms;save ax
	test	word [SWITCHMAP], (SWITCH_BACKUP or SWITCH_SELECT or SWITCH_AUTOTEST) ;Suppress prompt?	       ;AC000;
;	IF$	Z				;					      ;AC000;
	JNZ IF186$$
	   call    DSKPRM			; prompt user for disk
;	ENDIF$					;					      ;AC000;
IF186$$:

	test	word [SWITCHMAP], (SWITCH_SELECT) ;an016;dms;/SELECT requested?
;	if$	nz								;an016;dms;yes
	JZ IF188$$
		mov	al, [drive]    ;an016;dms;get drive to access for format
		call	AccessDisk						;an016;dms;access the disk
		mov	ax,Select_Disk_Message					;an016;dms;display disk prompt
		int	2fh							;an016;dms;  through INT 2fh services
;	endif$									;an016;dms;
IF188$$:
	pop	ax								;an016;dms;restore ax

	ret									;an016;dms;

;Prompt_User_For_Disk	endp							;an016;dms;


end if
;	END	START
