STRUC a_PartitionTableEntry BootInd_=0, BegHead_=0, BegSector_=0, BegCylinder_=0, SysInd_=0, EndHead_=0, EndSector_=0, EndCylinder_=0, RelSec_=0, CSec_=0
{
.BootInd db	BootInd_
.BegHead db	BegHead_
.BegSector db	BegSector_
.BegCylinder db	BegCylinder_
.SysInd	db	SysInd_
.EndHead db	EndHead_
.EndSector db	EndSector_
.EndCylinder db	EndCylinder_
.RelSec	dd	RelSec_
.CSec	dd	CSec_
}
match =a_PartitionTableEntry_LAID_OUT, a_PartitionTableEntry_LAID_OUT
{
    a_PartitionTableEntry_LAID_OUT equ 1
    virtual at 0
      a_PartitionTableEntry a_PartitionTableEntry 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.a_PartitionTableEntry = $ - a_PartitionTableEntry
    end virtual
}
STRUC IBMBoot Signature_=0
{
; MASM worked LENGTH out as the number of elements a variable was
; declared with and SIZE as the bytes they take up.  The arrays these
; ask about are all of bytes, so the two come to the same number.
	rb      512 - (4*sizeof.a_PartitionTableEntry + 2)
.PartitionTable rb      4*sizeof.a_PartitionTableEntry
.Signature dw	Signature_
}
match =IBMBoot_LAID_OUT, IBMBoot_LAID_OUT
{
    IBMBoot_LAID_OUT equ 1
    virtual at 0
      IBMBoot IBMBoot 0
      sizeof.IBMBoot = $ - IBMBoot
    end virtual
}
; e forproc.sal= @(#)ibmfor.asm 1.28 85/10/15
	name	OemFormatRoutines
;
;******************************************************************************
;AN001 - ???
;AN002 - D304 Modify Boot record structure for OS2		  11/09/87 J.K.
;******************************************************************************

include 'FORCHNG.INC'
debug	equ	0
;-------------------------------------------------------------------------------
; Public for debugging only

;	public	CheckSwitches
;	public	LastChanceToSaveIt
;	public	WriteBootSector
;	public	OemDone
;	public	WriteBogusDos
;	public	ConvertToOldDirectoryFormat
;	public	SetPartitionTable
;	public	ReadSector
;	public	WriteSector
;	public	SectorIO
;	public	GetVolumeId

;	public	customBPBs
;	public	NotSlashB
;	public	NotSingleSided
;	public	EndSwitchCheck
;	public	WeCanNotIgnoreThisError
;	public	HardDisk?
;	public	BogusDos
;	public	sys_mess_loop
;	public	end_sys_loop
;	public	DirectoryRead
;	public	wrtdir
;	public	DirectoryWritten
;	public	FCBforVolumeIdSearch
;	public	CopyVolumeId
;	public	CompareVolumeIds
;	public	BadVolumeId

;	public	boot2
;	public	boot
;	public	scratchBuffer
;	public	biosFilename
;	public	dosFilename
;	public	oldDrive
;	public	oldVolumeId
;	public	Read_Write_Relative
;	public	Serial_Num_Low
;	public	Serial_Num_High
;	public	SizeMap

;	public	ptr_msgWhatIsVolumeId?

;	public	trackReadWritePacket

;	public	BPB81
;	public	BPB82
;	public	BPB91
;	public	BPB92

;-------------------------------------------------------------------------------

if SEGSEL = S_DATA
end if

if SEGSEL = S_CODE
;	assume	cs:code,ds:data

;	Public	AccessDisk
;	public	CheckSwitches
;	public	LastChanceToSaveIt
;	public	OemDone
;	public	BiosFile
;	public	DosFile

end if
if SEGSEL = S_DATA
;	extrn	AddToSystemSize:near
;	extrn	currentCylinder:word
;	extrn	currentHead:word
;	extrn	deviceParameters:byte
;	extrn	drive:byte
;	extrn	driveLetter:byte
;	extrn	fBigFAT:byte
;	extrn	inbuff:byte
;	extrn	switchmap:word
;	extrn	Old_Dir:byte
;	extrn	fLastChance:byte
;	extrn	Fatal_Error:Byte
;	extrn	Bios:Byte
;	extrn	Dos:Byte
;	extrn	Command:Byte

;	extrn	msgBad_T_N:byte
;	extrn	msgBadVolumeId:byte
;	extrn	msgBadPartitionTable:byte
;	extrn	msgBootWriteError:byte
;	extrn	msgDirectoryReadError:byte
;	extrn	msgDirectoryWriteError:byte
;	extrn	msgInvalidParameter:byte
;	extrn	msgIncompatibleParameters:byte
;	extrn	msgIncompatibleParametersForHardDisk:byte
;	extrn	msgParametersNotSupportedByDrive:byte
;	extrn	msgPartitionTableReadError:byte
;	extrn	msgPartitionTableWriteError:byte
;	extrn	msgWhatIsVolumeId?:byte
;	extrn	NumSectors:word, TrackCnt:word

IF	debug
;	extrn	msgFormatBroken:byte
end if

end if
if SEGSEL = S_CODE

;	extrn	PrintString:near
;	extrn	std_printf:near
;	extrn	crlf:near
;	extrn	user_string:near
;	extrn	Read_Disk:near
;	extrn	Write_Disk:near


;-------------------------------------------------------------------------------
; Constants

.xlist
include 'DOSMAC.INC'
include 'FORMACRO.INC'
include 'FOREQU.INC'
include 'FORSWTCH.INC'

; This defines all the int 21H system calls
include 'SYSCALL.INC'

; Limits

include 'FILESIZE.INC'

;-------------------------------------------------------------------------------
; These are the data structures which we will need

include 'DIRENT.INC'
include 'IOCTL.INC'
include 'VERSION.INC'

.list

;-------------------------------------------------------------------------------
; And this is the actual data
end if
if SEGSEL = S_DATA

Read_Write_Relative Relative_Sector_Buffer    ;				;AN000;


	IF IBMCOPYRIGHT
BiosFile db	"x:\IBMBIO.COM", 0
DosFile db	"x:\IBMDOS.COM", 0
	ELSE
BiosFile db	"x:\IO.SYS", 0
DosFile db	"x:\MSDOS.SYS", 0
	end if

Dummy_Label db	"NO NAME    "
Dummy_Label_Size dw  11 			;AN028

Serial_Num_Low dw 0				;				;AN000;
Serial_Num_High dw 0				;				;AN000;

SizeMap db	0				;				;AN000;

trackReadWritePacket A_TRACKREADWRITEPACKET 


; BIOS parameter blocks for various media
label customBPBs byte
BPB92	A_BPB 512, 2, 1, 2, 112, 2*9*40, 0fdH, 2, 9, 2, 0, 0, 0, 0
BPB91	A_BPB 512, 1, 1, 2,	64, 1*9*40, 0fcH, 2, 9, 1, 0, 0, 0, 0
BPB82	A_BPB 512, 2, 1, 2, 112, 2*8*40, 0ffH, 1, 8, 2, 0, 0, 0, 0
BPB81	A_BPB 512, 1, 1, 2,	64, 1*8*40, 0feH, 1, 8, 1, 0, 0, 0, 0
BPB720	A_BPB 512, 2, 1, 2, 112, 2*9*80, 0F9h, 3, 9, 2, 0, 0, 0, 0



label boot2 byte
	include 'BOOT11.INC'
label REORG2 byte



include 'BOOTFORM.INC'


label BOOT byte
	include 'BOOT.INC'

scratchBuffer rb      512

ptr_msgWhatIsVolumeId? dw msgWhatIsVolumeId?
	dw	driveLetter


FAT12_String db "FAT12   "
FAT16_String db "FAT16   "

Media_ID_Buffer Media_ID 


end if
if SEGSEL = S_CODE
;-------------------------------------------------------------------------------
; AccessDisk:
;    Called whenever a different disk is about to be accessed
;
;    Input:
;	al - drive letter (0=A, 1=B, ...)
;
;    Output:
;	none
AccessDisk:

	push	ax				; save drive letter
	mov	bl,al				; Set up GENERIC IOCTL REQUEST preamble
	inc	bl
	mov	ax,(IOCtl SHL 8) + Set_Drv_Owner ; IOCTL function
	int	21h
	pop	ax
	return

;AccessDisk endp

;-------------------------------------------------------------------------------
;    CheckSwitches:
;	Check switches against device parameters
;	Use switches to modify device parameters
;
;    Input:
;	deviceParameters
;
;    Output:
;	deviceParameters may be modified
;	Carry set if error
;
;
;  /B <> /S
;  /B/8 <> /V
;  /1 or /8 <> /T/N
;


;Public	CHeckSwitches
CheckSwitches:


; Disallow /C
						;lea	 dx, msgInvalidParameter					 ;AC000;
	test	word [SWITCHMAP], SWITCH_C
	jz	CheckExcl
	Message msgInvalidParameter		;AC000;
SwitchError:
						;call	 PrintString							 ;AC000;
	stc
	ret

CheckExcl:

	test	word [SWITCHMAP],SWITCH_F ;Specify size?			;AN001;
;	IF$	NZ				;Yes				;AN001;
	JZ IF1$$M
	   test    word [SWITCHMAP],(SWITCH_1+SWITCH_8+SWITCH_4+SWITCH_N+SWITCH_T) ;AN001;
;	   IF$	   NZ				;/F replaces above switches	;AN001;
	   JZ IF2$$M
	      Message msgIncompatibleParameters ;Print error			;AN001;
	      mov     byte [Fatal_Error],YES ;Force exit			;AN001;
;	   ELSE$				;				;AN001;
	   JMP SHORT EN2$$M
IF2$$M:
	      call    Size_To_Switch		;Go set switches based		;AN001;
;	   ENDIF$				; on the size			;AN001;
EN2$$M:
;	ENDIF$					;				;AN001;
IF1$$M:
	cmp	byte [Fatal_Error],NO ;				;AN007;
;	IF$	E				;				;AN007;
	JNE IF6$$M
	   call    Check_Switch_8_B		;				;ac007
	   call    Check_T_N
;	ENDIF$					;				;AN009;
IF6$$M:
	cmp	byte [Fatal_Error],YES ;				;AN007;
	jne	ExclChkDone			;				;AN007;
	stc					;				;AN007;
	ret					;				;AN007;

ExclChkDone:
; Patch the boot sector so that the boot strap loader knows what disk to
; boot from
;	 mov	 Boot.Boot_PhyDrv, 00H		 ;AC000;
	mov	byte [BOOT+EXT_IBMBOOT_HEADER.EXT_PHYDRV], 00H ;AN00?;

	cmp	[deviceParameters.DP_DEVICETYPE], DEV_HARDDISK
	jne	CheckFor5InchDrives

; Formatting a hard disk so we must repatch the boot sector
;	 mov	 Boot.Boot_PhyDrv, 80H		 ;AC000;
	mov	byte [BOOT+EXT_IBMBOOT_HEADER.EXT_PHYDRV], 80H ;AN00?;
	test	word [SWITCHMAP], not (SWITCH_S or SWITCH_V or SWITCH_SELECT or SWITCH_AUTOTEST or SWITCH_B) ;AN007;
	jz	SwitchesOkForHardDisk

	Message msgIncompatibleParametersForHardDisk ;			     ;AC000;
	stc
	ret

; Before checking the Volume Id we need to verify that a valid one exists
; We assume that unless a valid boot sector exists on the target disk, no
; valid Volume Id can exist.

SwitchesOkForHardDisk:
	SaveReg <ax,bx,cx,dx,ds>
	mov	al,[drive]
	mov	cx,LOGBOOTSECT
	xor	dx,dx
	lea	bx,[scratchBuffer]; ScratchBuffer := Absolute_Read_Disk(
						;INT	 25h				 ;		      Logical_sec_1 )

						;Assume Dir for vol ID exists in 1st 32mb of partition

	mov	[Read_Write_Relative.Start_Sector_High],0
	call	Read_Disk			;				;AC000;
						;	on the stack. We throw them away

	jnc	CheckSignature
	stc
	RestoreReg <ds,dx,cx,bx,ax>
	ret

CheckSignature: 				; IF (Boot.Boot_Signature != aa55)

	mov	ax, word [scratchBuffer+BOOT_SIGNATURE]   ;AC000;
	cmp	ax, 0aa55h			;Find a valid boot record?
	RestoreReg <ds,dx,cx,bx,ax>
	clc					;No, so no need to check label
;	IF$	Z				;No further checking needed	;AC000;
	JNZ IF8$$M
	   test    word [SWITCHMAP],(SWITCH_SELECT or SWITCH_AUTOTEST) ;Should we prompt for vol label?;AN000;
;	   IF$	   Z				;Yes, if /Select not entered	;AN000;
	   JNZ IF9$$M
	      call    CheckVolumeId		;Go ask user for vol label	;     ;
;	   ELSE$				;/Select entered		;AN000;
	   JMP SHORT EN9$$M
IF9$$M:
	      clc				;CLC indicates passed label test;AN000;
;	   ENDIF$				; for the return		;AN000;
EN9$$M:
;	ENDIF$
IF8$$M:
	return

Incomp_Message: 				;an000; fix PTM 809

	Message msgIncompatibleParameters	;an000; print incompatible parms
	stc					;an000; signal error
	return					;an000; return to caller

Print_And_Return:
						;call	 PrintString			 ;				 ;AC000;
	stc
	return


CheckFor5InchDrives:

						;If drive type is anything other than 48 or 96, then only /V/S/H/N/T allowed
	cmp	byte [deviceParameters.DP_DEVICETYPE],DEV_5INCH96TPI
	je	Got96

	cmp	byte [deviceParameters.DP_DEVICETYPE],DEV_5INCH
	je	Got48

	xor	ax,ax								;an000; dms;clear reg
	or	ax,(SWITCH_V or SWITCH_S or SWITCH_N or SWITCH_T or SWITCH_B)	;an000; dms;set up switch mask
	or	ax,(SWITCH_BACKUP or SWITCH_SELECT or SWITCH_AUTOTEST)		;an000; dms;
IF ShipDisk
	or	ax,SWITCH_Z							;an000; dms;
end if
	not	ax								;an000; dms;
	test	[SWITCHMAP],ax     ;an000; dms;invalid switch?
	jz	Goto_Got_BPB1							;an000;dms;continue format
	Message msgParametersNotSupportedByDrive ;			 ;AC000;
	jmp	short Print_And_Return

Goto_Got_BPB1:
	jmp	Goto_Got_BPB
						; We have a 96tpi floppy drive
						; /4 allows just about all switches however, /1 requires /4
Got96:
;;;DMS;;test	switchmap, SWITCH_8		;an000; If /8 we have an error
;;;DMS;;jnz	Incomp_message			;an000; tell user error

	test	word [SWITCHMAP], SWITCH_4
	jnz	CheckForInterestingSwitches	;If /4 check /N/T/V/S

	test	word [SWITCHMAP], SWITCH_1 ;If /1 and /4 check others
	jz	Got48

						;If only /1 with no /4, see if /N/T
	test	word [SWITCHMAP],(SWITCH_N or SWITCH_T)
	jnz	CheckForInterestingSwitches

	jmp	Incomp_Message			;an000; tell user error occurred

Got48:
						;Ignore /4 for non-96tpi 5 1/4" drives
	and	word [SWITCHMAP], not SWITCH_4

						;Ignore /1 if drive has only one head and not /8
	cmp	word [deviceParameters.DP_BPB+A_BPB.BPB_HEADS], 1
	ja	CheckForInterestingSwitches
	test	word [SWITCHMAP], SWITCH_8
	jz	CheckForInterestingSwitches
	and	word [SWITCHMAP], not SWITCH_1

						;Are any interesting switches set?
CheckForInterestingSwitches:
	test	word [SWITCHMAP], not (SWITCH_V or SWITCH_S or SWITCH_BACKUP or SWITCH_SELECT or SWITCH_AUTOTEST or SWITCH_B)
	jz	Goto_EndSwitchCheck		;No, everything ok

						;At this point there are switches other than /v/s/h
	test	word [SWITCHMAP],(SWITCH_N or SWITCH_T)
	jz	Use_48tpi			;Not /n/t, so must be /b/1/8/4

						;We've got /N/T, see if there are others
	test	word [SWITCHMAP], not (SWITCH_N or SWITCH_T or SWITCH_V or SWITCH_S or SWITCH_BACKUP or SWITCH_SELECT or SWITCH_AUTOTEST)
	jz	NT_Compatible			;Nope, all is well

						;If 96tpi drive and /1 exists with /N/T, then okay, otherwise error
	cmp	byte [deviceParameters.DP_DEVICETYPE],DEV_5INCH96TPI
	jne	Bad_NT_Combo

	test	word [SWITCHMAP], not (SWITCH_1 or SWITCH_N or SWITCH_T or SWITCH_V)
	jnz	Bad_NT_Combo
	test	word [SWITCHMAP], not (SWITCH_S or SWITCH_BACKUP or SWITCH_SELECT or SWITCH_AUTOTEST)
	jz	Goto_Got_BPB

Bad_NT_Combo:
	Message msgIncompatibleParameters	;				;AC000;
	jmp	Print_And_Return

Goto_Got_BPB:
	jmp	Got_BPB_OK			;Sleazy, but je won't reach it

Goto_EndSwitchCheck:
	jmp	EndSwitchCheck
						;There is a problem with /N/T in that IBMBIO will default to a BPB with the
						;media byte set to F0 (other) if the /N/T combo is used for the format. This
						;will cause problems if we are creating a media that has an assigned media
						;byte, i.e. 160,180,320,360, or 720k media using /N/T. To avoid this problem,
						;if we detect a /N/T combo that would correspond to one of these medias, then
						; we will set things up using the /4/1/8 switches instead of the /N/T
						; MT - 7/17/86 PTR 33D0110

						; Combo's that we look for - 96tpi drive @ /T:40, /N:9
						;			     96tpi drive @ /T:40, /N:8
						;
						; Look for this combo after we set everything up with the /T/N routine
						;			     1.44 drive  @ /T:80, /N:9

NT_Compatible:
	cmp	byte [deviceParameters.DP_DEVICETYPE],DEV_5INCH96TPI
	jne	Goto_Got_BPB

	cmp	word [TrackCnt],40 ;Look for 40 tracks
	jne	Got_BPB_OK

	cmp	word [NumSectors],9 ;9 sectors?
	je	Found_48tpi_Type

	cmp	word [NumSectors],8 ;8 sectors?
	jne	Goto_Got_BPB			;Nope, different type, let it go thru

	or	word [SWITCHMAP],SWITCH_8 ;Yes, turn on /8 switch

Found_48tpi_Type:
	and	word [SWITCHMAP],not (SWITCH_N or SWITCH_T) ;Turn off /T/N

;******End PTR fix

; if we have a 96 tpi drive then we will be using it in 48 tpi mode
Use_48tpi:
	cmp	byte [deviceParameters.DP_DEVICETYPE], DEV_5INCH96TPI
	jne	Not96tpi

	mov	byte [deviceParameters.DP_MEDIATYPE], 1
	mov	word [deviceParameters.DP_CYLINDERS], 40
Not96tpi:

; Since we know we are formatting in 48 tpi mode turn on /4 switch
; (We use this info in LastChanceToSaveIt)
	or	word [SWITCHMAP], SWITCH_4

; At this point we know that we will require a special BPB
; It will be one of:
;    0) 9 track 2 sides - if no switches
;    1) 9 track 1 side	- if only /1 specified
;    2) 8 track 2 sides - if only /8 specified
;    3) 8 track 1 side	- if /8 and /1 specified
;
Get_BPBs:
; ax is used to keep track of which of the above BPB's we want
	xor	ax, ax

NotSlashB:

	test	word [SWITCHMAP], SWITCH_1
	jz	NotSingleSided
	add	ax, 1
NotSingleSided:

	test	word [SWITCHMAP], SWITCH_8
	jz	Not8SectorsPerTrack
	add	ax, 2
; /8 implies Old_Dir = TRUE
	mov	byte [Old_Dir],TRUE
Not8SectorsPerTrack:

; Ok now we know which BPB to use so lets move it to the device parameters

	mov	bx, sizeof.A_BPB
	mul	bx
	lea	si,[customBPBs]
	add	si, ax
	lea	di,[deviceParameters.DP_BPB]
	mov	cx, sizeof.A_BPB
	push	ds
	pop	es
	repnz	movsb

;*****************************************************************
;*  /N/T DCR stuff.  Possible flaw exists if we are dealing with a
;*  HardDisk. If they support the  "custom format" features for
;*  Harddisks too, then CheckForInterestingSwitches should
;*  consider /n/t UNinteresting, and instead of returning
;*  after setting up the custom BPB we fall through and do our
;*  Harddisk Check.
Got_BPB_OK:
	test	word [SWITCHMAP],SWITCH_N+SWITCH_T
	jnz	Setup_Stuff
	jmp	EndSwitchCheck
Setup_Stuff:
; Set up NumSectors and SectorsPerTrack entries correctly
	test	word [SWITCHMAP],SWITCH_N
	jz	No_Custom_Seclim
	mov	ax,word [NumSectors]
	mov	word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK],ax
	jmp	short Handle_Cyln
No_Custom_Seclim:
	mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERTRACK]
	mov	[NumSectors],ax

Handle_Cyln:
	test	word [SWITCHMAP],SWITCH_T
	jz	No_Custom_Cyln
; Set up TrackCnt and Cylinders entries correctly
	mov	ax,[TrackCnt]
	mov	[deviceParameters.DP_CYLINDERS],ax
	jmp	short Check_720
No_Custom_Cyln:
	mov	ax,[deviceParameters.DP_CYLINDERS]
	mov	[TrackCnt],ax

;****PTM P868  - Always making 3 1/2 media byte 0F0h. If 720, then set to
;		 0F9h and use the DOS 3.20 BPB. Should check all drives
;		 at this point (Make sure not 5 inch just for future
;		 protection)
;		 We will use the known BPB info for 720 3 1/2 diskettes for
;		 this special case. All other new diskette media will use the
;		 calculations that follow Calc_Total for BPB info.
; Fix MT  11/12/86

Check_720:

	cmp	byte [deviceParameters.DP_DEVICETYPE],DEV_5INCH96TPI
	je	Calc_Total

	cmp	byte [deviceParameters.DP_DEVICETYPE],DEV_5INCH
	je	Calc_Total

	cmp	word [TrackCnt],80
	jne	Calc_Total

	cmp	word [NumSectors],9
	jne	Calc_Total

; At this point we know we have a 3 1/2 720kb diskette to format. Use the
; built in BPB rather than the one handed to us by DOS, because the DOS one
; will be based on the default for that drive, and it can be different from
; what we used in DOS 3.20 for the 720's. Short sighted on our part to use
; 0F9h as the media byte, should have use 0F0h (OTHER) and then we wouldn't
; have this problem.

	SaveReg <ds,es,si,di,cx>


	mov	cx,data_			;Setup seg regs, just in case they ain't!
	mov	ds,cx
	mov	es,cx

	mov	si,BPB720         ;Copy the BPB!
	mov	di,deviceParameters.DP_BPB
	mov	cx,sizeof.A_BPB
	rep	movsb
	RestoreReg <cx,di,si,es,ds>
	jmp	EndSwitchCheck

;End PTM P868 fix ****************************************

Calc_Total:
	mov	ax,[NumSectors]
	mov	bx,word [deviceParameters.DP_BPB+A_BPB.BPB_HEADS]
	mul	bl				; AX = # of sectors * # of heads
	mul	[TrackCnt] ; DX:AX = Total Sectors
	or	dx,dx
	jnz	Got_BigTotalSectors
	mov	word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS],ax
	jmp	short Set_BPB
Got_BigTotalSectors:
	mov	word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS],ax
	mov	word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS+2],dx
	push	dx				; preserve dx for further use
	xor	dx,dx
	mov	word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS],dx
	pop	dx

Set_BPB:
; We calculate the number of sectors required in a FAT. This is done as:
; # of FAT Sectors = TotalSectors / SectorsPerCluster * # of bytes in FAT to
; represent one cluster (i.e. 3/2) / BytesPerSector (i.e. 512)
	xor	bx,bx
	mov	bl,byte [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERCLUSTER]
	div	bx				; DX:AX contains # of clusters
; now multiply by 3/2
	mov	bx,3
	mul	bx
	mov	bx,2
	div	bx
	xor	dx,dx				; throw away modulo
; now divide by 512
	mov	bx,512
	div	bx
; dx:ax contains number of FAT sectors necessary
	inc	ax				; Go one higher
	mov	word [deviceParameters.DP_BPB+A_BPB.BPB_SECTORSPERFAT],ax
	mov	[deviceParameters.DP_MEDIATYPE],0
	mov	byte [deviceParameters.DP_BPB+A_BPB.BPB_MEDIADESCRIPTOR],Custom_Media


EndSwitchCheck:
	clc
	return

;CheckSwitches endp

;*****************************************************************************
;Routine name: Size_To_Switch
;*****************************************************************************
;
;Description: Given the SizeMap field as input indicating the SIZE= value
;	      entered, validate that the specified size is valid for the
;	      drive, and if so, turn on the appropriate data fields and
;	      switches that would be turned on by the equivilent command line
;	      using only switchs. All defined DOS 4.00 sizes are hardcoded,
;	      in case a drive type of other is encountered that doesn't
;	      qualify as a DOS 4.00 defined drive. Exit with error message if
;	      unsupported drive. The switches will be setup for the CheckSwitches
;	      routine to sort out, using existing switch matrix logic.
;
;Called Procedures: Low_Density_Drive
;		    High_Capacity_Drive
;		    720k_Drives
;		    Other_Drives
;
;Change History: Created	8/1/87	       MT
;
;Input: SizeMap
;	Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;	 SwitchMap = appropriate Switch_?? values turned on
;	 TrackCnt, NumSectors set if Switch_T,Switch_N turned on
;*****************************************************************************


Procedure Size_To_Switch

	cmp	byte [SizeMap],0 ;Are there sizes entered?	 ;AN001;
;	IF$	NE				;Yes				;AN001;
	JE IF13$$M
	   cmp	   [deviceParameters.DP_DEVICETYPE],DEV_HARDDISK ;AN000;		;AN001;
;	   IF$	   E				;No size for fixed disk 	;AN001;
	   JNE IF14$$M
	      Message msgIncompatibleParametersForHardDisk ;			;AN001;
;	   ELSE$				;Diskette, see what type	;AN001;
	   JMP SHORT EN14$$M
IF14$$M:
	      cmp     byte [deviceParameters.DP_DEVICETYPE],DEV_5INCH   ;	;AN001;
;	      IF$     E 			;Found 180/360k drive		;AN001;
	      JNE IF16$$M
		 call	 Low_Density_Drive	;Go set switches		;AN001;
;	      ELSE$				;Check for 96TPI		;AN001;
	      JMP SHORT EN16$$M
IF16$$M:
		 cmp	 byte [deviceParameters.DP_DEVICETYPE],DEV_5INCH96TPI   ;AN001; ;
;		 IF$	 E			;Found it			;AN001;
		 JNE IF18$$M
		    call    High_Capacity_Drive ;				;AN001;
;		 ELSE$				;				;AN001;
		 JMP SHORT EN18$$M
IF18$$M:
		    cmp     byte [deviceParameters.DP_DEVICETYPE],DEV_3INCH720KB   ;AN0001;
;		    IF$     E			;Found 720k drive		;AN001;
		    JNE IF20$$M
		       call    Small_Drives	;				;AN001;
;		    ELSE$			;				;AN001;
		    JMP SHORT EN20$$M
IF20$$M:
		       cmp     byte [deviceParameters.DP_DEVICETYPE],DEV_OTHER   ;AN001;
;		       IF$     E		;Must be 1.44mb 		;AN001;
		       JNE IF22$$M
			  call	  Other_Drives	;				;AN001;
;		       ELSE$			;				;AN001;
		       JMP SHORT EN22$$M
IF22$$M:
			  Message msgParametersNotSupportedByDrive ;		;AN001;
			  mov	  byte [Fatal_Error],YES ;				;AN001;
;		       ENDIF$			;				;AN001;
EN22$$M:
;		    ENDIF$			;				;AN001;
EN20$$M:
;		 ENDIF$ 			;				;AN001;
EN18$$M:
;	      ENDIF$				;				;AN001;
EN16$$M:
;	   ENDIF$				;				;AN001;
EN14$$M:
;	ENDIF$					;				;AN001;
IF13$$M:
	cmp	byte [Fatal_Error],YES ;				;AN001;
;	IF$	E				;				;AN001;
	JNE IF30$$M
	   Message msgIncompatibleParameters	;				;AN001;
;	ENDIF$					;				;AN001;
IF30$$M:

	cmp	[deviceParameters.DP_DEVICETYPE],DEV_HARDDISK ;an001;
;	if$	e								;an001;
	JNE IF32$$M
		mov	byte [Fatal_Error],YES ;an001;
;	endif$									;an001;
IF32$$M:

	and	word [SWITCHMAP],not SWITCH_F ;Turn off /F so doesn't effect  ;AN001;
	ret					; following logic		;AN001;

;Size_To_Switch endp

;*****************************************************************************
;Routine name: High_Capacity_Drive
;*****************************************************************************
;
;Description: See if 1.2mb diskette, or one of the other 5 1/4 sizes. Turn
;	      on /4 if 360k or lower
;
;Called Procedures: Low_Density_Drive
;
;Change History: Created	8/1/87	       MT
;
;Input: SizeMap
;	Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;	 SwitchMap = Switch_4 if 360k or lowere
;*****************************************************************************

Procedure High_Capacity_Drive			;

	test	byte [SizeMap],Size_1200 ;1.2mb diskette?		 ;AN001;
;	IF$	Z				;Nope				;AN001;
	JNZ IF34$$M
	   call    Low_Density_Drive		;Check for /4 valid types	;AN001;
	   cmp	   byte [Fatal_Error], NO ;Find 160/180/320/360k? 	;AN001;
;	   IF$	   E				;Yes				;AN001;
	   JNE IF35$$M
	      or      word [SWITCHMAP],SWITCH_4 ;Turn on /4 switch		;AN001;
;	   ELSE$				;Did not find valid size	;AN001;
	   JMP SHORT EN35$$M
IF35$$M:
	      mov     byte [Fatal_Error],YES ;Indicate invalid device	;AN001;
;	   ENDIF$				;				;AN001;
EN35$$M:
;	ENDIF$					;				;AN001;
IF34$$M:
	ret					;				;AN001;

;High_Capacity_Drive endp

;*****************************************************************************
;Routine name: Low_Density_Drive
;*****************************************************************************
;
;Description: See if 360k diskete or one of the other 5 1/4 sizes. Turn
;	      on the /1/8 switch to match sizes
;
;Called Procedures: Low_Density_Drive
;
;Change History: Created	8/1/87	       MT
;
;Input: SizeMap
;	Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;	 SwitchMap = Switch_1, Switch_8 to define size
;
;	360k = No switch
;	320k = Switch_8
;	180k = Switch_1
;	160k = Switch_1 + Switch_8
;*****************************************************************************


Procedure Low_Density_Drive			;				;AN000;
						;
	test	byte [SizeMap],Size_160 ;				 ;AN001;
;	IF$	NZ				;				;AN001;
	JZ IF39$$M
	   or	   word [SWITCHMAP],SWITCH_1+SWITCH_8 ;				;AN001;
;	ELSE$					;				;AN001;
	JMP SHORT EN39$$M
IF39$$M:
	   test    byte [SizeMap],Size_180 ;				 ;AN001;
;	   IF$	   NZ				;				;AN001;
	   JZ IF41$$M
	      or      word [SWITCHMAP],SWITCH_1 ;				;AN001;
;	   ELSE$				;				;AN001;
	   JMP SHORT EN41$$M
IF41$$M:
	      test    byte [SizeMap],Size_320 ;				 ;AN001;
;	      IF$     NZ			;				;AN001;
	      JZ IF43$$M
		 or	 word [SWITCHMAP],SWITCH_8 ;				;AN001;
;	      ELSE$				;				;AN001;
	      JMP SHORT EN43$$M
IF43$$M:
		 test	 byte [SizeMap],Size_360 ;				 ;AN001;
;		 IF$	 Z			;None of the above, not valid	;AN001;
		 JNZ IF45$$M
		    mov     byte [Fatal_Error],YES ;				;AN001;
;		 ENDIF$ 			;				;AN001;
IF45$$M:
;	      ENDIF$				;				;AN001;
EN43$$M:
;	   ENDIF$				;				;AN001;
EN41$$M:
;	ENDIF$					;				;AN001;
EN39$$M:
	ret					;				;AN001;

;Low_Density_Drive endp

;*****************************************************************************
;Routine name: Small_Drives
;*****************************************************************************
;
;Description: See if 720k media in 720 drive, set up /T/N if so, otherwise
;	      error
;
;Called Procedures: None
;
;Change History: Created	8/1/87	       MT
;
;Input: SizeMap
;	Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;	 SwitchMap
;	 TrackCnt
;	 NumSectors
;	720k = /T:80 /N:9
;*****************************************************************************

Procedure Small_Drives				;				;AN000;

	test	byte [SizeMap],Size_720 ;Ask for 720k?			 ;AN001;
;	IF$	Z				;Nope, thats all drive can do	;AN001;
	JNZ IF50$$M
	   mov	   byte [Fatal_Error],YES ;Indicate error 		;AN001;
;	ENDIF$					;				;AN001;
IF50$$M:
	ret					;				;AN001;

;Small_Drives endp


;*****************************************************************************
;Routine name: Other_Drives
;*****************************************************************************
;
;Description: See if 1.44 media or 720k media, setup /t/n, otherwise error
;
;Called Procedures: Small_Drives
;
;Change History: Created	8/1/87	       MT
;
;Input: SizeMap
;	Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;	 SwitchMap
;	 TrackCnt
;	 NumSectors
;	720k = /T:80 /N:9
;*****************************************************************************

Procedure Other_Drives				;				;AN001;

	test	byte [SizeMap],Size_1440 ;Ask for 1.44mb diskette?	 ;AN001;
;	IF$	Z				;Nope				;AN001;
	JNZ IF52$$M
	   call    Small_Drives 		;See if 720k		       ;AN001;
	   cmp	   byte [Fatal_Error],NO ;Fatal_error=Yes if not 	;AN001;
;	   IF$	   E				;Got 720k			;AN001;
	   JNE IF53$$M
	      or      word [SWITCHMAP],SWITCH_T+SWITCH_N ;Turn on /T:80 /N:9		;AN001;
	      mov     word [TrackCnt],80 ;				;AN001;
	      mov     word [NumSectors],9 ;				;AN001;
;	   ENDIF$				;				;AN001;
IF53$$M:
;	ELSE$					;Asked for 1.44mb		;AN001;
	JMP SHORT EN52$$M
IF52$$M:
	   or	   word [SWITCHMAP],SWITCH_T+SWITCH_N ;Turn on /T:80 /N:18;		;AN001;
	   mov	   word [TrackCnt],80 ;This will protect SIZE=1440	;AN001;
	   mov	   word [NumSectors],18 ; from non-standard drives with ;AN001;
;	ENDIF$					; type of 'other'		;AN001;
EN52$$M:
	ret					;				;AN001;

;Other_Drives endp


;*****************************************************************************
;Routine name:Check_T_N
;*****************************************************************************
;
;Description: Make sure than if /T is entered, /N is also entered
;
;Called Procedures:  None
;
;Change History: Created	8/23/87  MT
;
;Input: SizeMap
;	Fatal_Error = NO
;
;Output: Fatal_Error = YES/NO
;*****************************************************************************

Procedure Check_T_N

	test	word [SWITCHMAP],SWITCH_N ;Make sure /T entered if /N	;AN009;
;	IF$	NZ,AND				;				;AN009;
	JZ IF57$$M
	test	word [SWITCHMAP],SWITCH_T ;				;AN009;
;	IF$	Z				;				;AN009;
	JNZ IF57$$M
	   Message msgBad_T_N			;It wasn't, so barf             ;AN009;
	   mov	   byte [Fatal_Error],YES ;Indicate error 		;AN009;
;	ELSE$					;				;AN009;
	JMP SHORT EN57$$M
IF57$$M:
	   test    word [SWITCHMAP],SWITCH_T ;Make sure /N entered if /T	;AN009;
;	   IF$	   NZ,AND			;				;AN009;
	   JZ IF59$$M
	   test    word [SWITCHMAP],SWITCH_N ;				;AN009;
;	   IF$	   Z				;It wasn't, so also barf        ;AN009;
	   JNZ IF59$$M
	      Message msgBad_T_N		;				;AN009;
	      mov     byte [Fatal_Error],YES ;Indicate error 		;AN009;
;	   ENDIF$				;				;AN009;
IF59$$M:
;	ENDIF$					;				;AN009;
EN57$$M:
	ret

;Check_T_N endp



;-------------------------------------------------------------------------------
;    LastChanceToSaveIt:
;	This routine is called when an error is detected in DiskFormat.
;	If it returns with carry not set then DiskFormat is restarted.
;	It gives the oem one last chance to try formatting differently.
;	fLastChance gets set Then to prevent multiple prompts from being
;	issued for the same diskette.
;
;	Algorithm:
;		IF (error_loc == Track_0_Head_1) &
;			  ( Device_type < 96TPI )
;		   THEN
;			fLastChance  := TRUE
;			try formatting 48TPI_Single_Sided
;		   ELSE return ERROR
;
LastChanceToSaveIt:

	cmp	word [currentCylinder], 0
	jne	WeCanNotIgnoreThisError
	cmp	word [currentHead], 1
	jne	WeCanNotIgnoreThisError

	cmp	[deviceParameters.DP_DEVICETYPE], DEV_5INCH
	ja	WeCanNotIgnoreThisError

	mov	byte [fLastChance], TRUE

	or	word [SWITCHMAP], SWITCH_1
	call	CheckSwitches
	clc
	ret

WeCanNotIgnoreThisError:
	stc
	ret

;LastChanceToSaveIt endp

;-------------------------------------------------------------------------------


;*****************************************************************************
;Routine name WriteBootSector
;*****************************************************************************
;
;DescriptioN: Copy EBPB information to boot record provided by Get recommended
;	      BPB, write out boot record, error
;	      if can write it, then fill in new fields (id, etc..). The volume
;	      label will not be added at this time, but will be set by the
;	      create volume label call later.
;
;Called Procedures: Message (macro)
;
;Change History: Created	4/20/87 	MT
;
;Input: DeviceParameters.DP_BPB
;
;Output: CY clear if ok
;	 CY set if error writing boot or media_id info
;
;Psuedocode
;----------
;
;	Copy recommended EBPB information to canned boot record
;	Write boot record out (INT 26h)
;	IF error
;	   Display boot error message
;	   stc
;	ELSE
;	   Compute serial id and put into field (CALL Create_Serial_ID)
;	   Point at 'FAT_12' string for file system type
;	   IF fBIGFat	 ;16 bit FAT
;	      Point at 'FAT_16' for file system type
;	   ENDIF
;	   Copy file system string into media_id field
;	   Write info to boot (INT 21h AX=440Dh, CX=0843h SET MEDIA_ID)
;	   IF error (CY set)
;	      Display boot error message
;	      stc
;	   ELSE
;	      clc
;	   ENDIF
;	ENDIF
;	ret
;*****************************************************************************

Procedure WriteBootSector			;				;AN000;

	lea	si,[deviceParameters.DP_BPB];Copy EBPB to the boot record	;
	lea	di, [BOOT+EXT_IBMBOOT_HEADER.EXT_BOOT_BPB] ;  "  " 	"  "		;AC000:
	mov	cx, sizeof.EXT_BPB_INFO ;  "  " 	"  "		;AC000:
	push	ds				;Set ES=DS (data segment)	;     ;
	pop	es				;  "  " 	"  "		;     ;
	repnz	movsb				;Do the copy			;     ;
						;Write out the boot record	;     ;
	mov	al, [drive] ;Get drive letter		;     ;
	mov	cx, 1				;Specify 1 sector		;     ;
	xor	dx, dx				;Logical sector 0		;     ;
	lea	bx,[BOOT]  ;Point at boot record		;     ;
;Boot record in 1st 32mb of partition
	mov	[Read_Write_Relative.Start_Sector_High],0 ;			;AN000;
	call	Write_Disk			;				;AC000;
;	IF$	C				;Error on write 		;AC000;
	JNC IF62$$M
	   Message msgBootWriteError		;Print error			;     ;
	   stc					;CY=1 means error		;     ;
;	ELSE$					;Good write of boot record!	;AN000;
	JMP SHORT EN62$$M
IF62$$M:
	   mov	   cx,[Dummy_Label_Size] ;Put in dummy volume label size ;ac026;ac028;
	   lea	   si,[Dummy_Label];  "  "       "  "		;AN000;
	   lea	   di,[Media_ID_Buffer.Media_ID_Volume_Label];	"  "	   "  " ;AN000;
	   rep	   movsb			;  "  "       "  "		;AN000;
	   call    Create_Serial_ID		;Go create unique ID number	;AN000;
	   lea	   si,[FAT12_String];Assume 12 bit FAT		;AN000;
	   cmp	   byte [fBigFat],TRUE ;Is it? 			;AN000;
;	   IF$	   E				;Not if fBigFat is set....	;AN000;
	   JNE IF64$$M
	      lea     si,[FAT16_String];Got 16 bit FAT 		;AN000;
;	   ENDIF$				;				;AN000;
IF64$$M:
						;Copy file system string	;     ;
	   mov	   cx,8 			; to buffer			;AN000;
	   lea	   di,[Media_ID_Buffer.Media_ID_File_System] ;	 "  "		;AN000;
	   repnz   movsb			;    "   "	  "  "		;AN000;
	   mov	   al,GENERIC_IOCTL		;Generic IOCtl call		;AN000;
	   mov	   bl,[drive] ;Get drive			;AN000;
	   inc	   bl				;Make it 1 based		;AN000;
	   xor	   bh,bh			;Set bh=0			;AN000;
	   mov	   ch,RAWIO			;Set Media ID call		;AN000;
	   mov	   cl,SET_MEDIA_ID
	   mov	   dx,Media_ID_Buffer        ;Point at buffer		;AN000;
	   DOS_Call IOCtl			;Do function call		;AN000;
;	   IF$	   C				;Error ? (Write or old boot rec);AN000;
	   JNC IF66$$M
	      Message msgBootWriteError 	;Indicate we couldn't write it  ;AN000;
	      stc				;CY=1 for error return		;AN000;
;	   ELSE$				;Set Media ID okay		;AN000;
	   JMP SHORT EN66$$M
IF66$$M:
	      clc				;CY=0 for good return		;AN000;
;	   ENDIF$				;				;AN000;
EN66$$M:
;	ENDIF$					;				;AN000;
EN62$$M:
	ret					;				;AN000;

;WriteBootSector endp				;				;AN000;


;*****************************************************************************
;Routine name Create_Serial_ID
;*****************************************************************************
;
;DescriptioN&gml Create unique 32 bit serial number by getting current date and
;	      time and then scrambling it around.
;
;Called Procedures: Message (macro)
;
;Change History&gml Created	   4/20/87	   MT
;
;Input&gml None
;
;Output&gml Media_ID_Buffer.Serial_Number = set
;	    AX,CX,DX destroyed
;	    Serial_Num_Low/High = Serial number generated
;
;Psuedocode
;----------
;
;	Get date (INT 21h, AH=2Bh)
;	Get time (INT 21h, AH=2Ch)
;	Serial_ID+0 = DX reg date + DX reg time
;	Serial_ID+2 = CX reg date + CX reg time
;	Serial_Num_Low = Serial_ID+2
;	Serial_Num_High = Serial_ID+0
;	ret
;*****************************************************************************

Procedure Create_Serial_ID			;				;AN000;

	DOS_Call Get_Date			;Get date from DOS		;AN000;
	push	cx				;Save results			;AN000;
	push	dx				;				;AN000;
	DOS_Call Get_Time			;Get_Time			;AN000;
	mov	ax,dx				;Scramble it			;AN000;
	pop	dx				;				;AN000;
	add	ax,dx				;				;AN000;
	mov	word [Media_ID_Buffer.Media_ID_Serial_Number+2],ax   ;		;AC004;
	mov	[Serial_Num_Low],ax ;				;AN000;
	mov	ax,cx				;				;AN000;
	pop	cx				;				;AN000;
	add	ax,cx				;				;AN000;
	mov	word [Media_ID_Buffer.Media_ID_Serial_Number],ax   ;		;AC004;
	mov	[Serial_Num_High],ax ;				;AN000;
	ret					;				;AN000;

;Create_Serial_ID endp				;				;AN000;

;-------------------------------------------------------------------------------

; OemDone:
;
OemDone:

; if /b write out a fake dos & bios
	test	word [SWITCHMAP], SWITCH_B
	jz	Switch8?
	call	WriteBogusDos
	retc

Switch8?:
	test	word [SWITCHMAP], SWITCH_8
	jz	HardDisk?
	call	ConvertToOldDirectoryFormat
	retc

HardDisk?:
	cmp	[deviceParameters.DP_DEVICETYPE], DEV_HARDDISK
	clc
	retnz
	call	SetPartitionTable

	return

;OemDone endp

;------------------------------------------------------------------------------

end if
if SEGSEL = S_DATA

	if IBMCOPYRIGHT
biosFilename db "x:\ibmbio.com",0
dosFilename db	"x:\ibmdos.com",0
	else
biosFilename db "x:\io.sys",0
dosFilename db	"x:\msdos.sys",0
	end if

end if
if SEGSEL = S_CODE

; simple code to stuff bogus dos in old-style diskette.

BogusDos:
	push	cs
	pop	ds
	mov	al,20h
	out	20h,al				; turn on the timer so the disk motor
	mov	si,mesofs			; shuts off
sys_mess_loop:
	lodsb
if IBMCOPYRIGHT
end_sys_loop:
end if
	or	al,al
	jz	end_sys_loop
	mov	ah,14
	mov	bx,7
	int	16
	jmp	sys_mess_loop
if not IBMCOPYRIGHT
end_sys_loop:
	xor	ah, ah				; get next char function
	int	16h				; call keyboard services
	int	19h				; reboot
end if

	include 'BOOT.CL1'
mesofs	equ	(SYSMSG - BogusDos)

WriteBogusDos:

	mov	al,[driveLetter]
	mov	[biosFilename],al
	mov	[dosFilename],al
	mov	cx, attr_hidden or attr_system
	lea	dx,[biosFilename]
	mov	ah,Creat
	int	21h
	mov	bx,ax
	mov	cx, BIOS_SIZE
	push	ds
	push	cs
	pop	ds
;	assume	ds:code
	lea	dx,[BogusDos]
	mov	ah,Write
	int	21h
	pop	ds
;	assume	ds:data
	mov	ah,Close
	int	21h
	mov	cx, attr_hidden or attr_system
	lea	dx,[dosFilename]
	mov	ah,Creat
	int	21h
	mov	bx,ax
	mov	cx, DOS_SIZE
	lea	dx,[BogusDos]
	mov	ah,Write
	int	21h
	mov	ah,Close
	int	21h
; Comunicate system size to the main format program
	mov	word [dos.fileSizeInBytes],DOS_SIZE      ;an000; dms;get size of DOS
	mov	word [dos.fileSizeInBytes+2],00h      ;an000; dms;

	xor	dx,dx
	mov	ax,DOS_SIZE
	call	AddToSystemSize

	mov	word [bios.fileSizeInBytes],BIOS_SIZE      ;an000; dms;get size of BIOS
	mov	word [bios.fileSizeInBytes+2],00h      ;an000; dms;

	xor	dx,dx
	mov	ax,BIOS_SIZE
	call	AddToSystemSize

	clc
	return

;WriteBogusDos endp

;-------------------------------------------------------------------------------

ConvertToOldDirectoryFormat:

;
; convert to 1.1 directory
;
	mov	al,[drive] ; Get 1st sector of directory
	mov	cx,1				; 1.1 directory always starts on
	mov	dx,3				; sector 3
	lea	bx,[scratchBuffer]
;Root Directory always in 1st 32mb of partition
	mov	[Read_Write_Relative.Start_Sector_High],0 ;		       ;AN000;
	call	Read_Disk			;				;AC000;
	jnc	DirectoryRead
	Message msgDirectoryReadError		;				;AC000;
	stc
	ret
DirectoryRead:

; fix attribute of ibmbio and ibmdos
	lea	bx,[scratchBuffer]
	mov	byte [bx+dir_entry.dir_attr], attr_hidden or attr_system
	add	bx, sizeof.dir_entry
	mov	byte [bx+dir_entry.dir_attr], attr_hidden or attr_system

wrtdir:
	mov	al,[drive]			; write out the directory
	cbw
	mov	cx,1
	mov	dx,3
	lea	bx,[scratchBuffer]
;Root Directory always in 1st 32mb of partition
	mov	[Read_Write_Relative.Start_Sector_High],0 ;		       ;AN000;
	call	Write_Disk			;				;AC000;
	jnc	DirectoryWritten
	Message msgDirectoryWriteError		;				;AC000;
	stc
	ret
DirectoryWritten:

	test	word [SWITCHMAP], SWITCH_S ; Was system requested?
	retnz					; yes, don't write old boot sector
	mov	al,[drive]
	cbw
	mov	bx,boot2          ; no,  write old boot sector
	cmp	word [deviceParameters.DP_BPB+A_BPB.BPB_HEADS], 1
	je	bootset8
	mov	word [bx+3],0103h      ; start address for double sided drives
bootset8:
	mov	cx,1
	xor	dx,dx
;Boot record in 1st 32mb of partition
	mov	[Read_Write_Relative.Start_Sector_High],0 ;		       ;AN000;
	call	Write_Disk			;				;AC000;
	retnc

	Message msgBootWriteError		;				;AC000;
	stc
	ret

;ConvertToOldDirectoryFormat endp

;-------------------------------------------------------------------------------


; structure of the IBM hard disk boot sector:


;*****************************************************************************
;Routine name: SetPartitionTable
;*****************************************************************************
;
;Description: Find location for DOS partition in partition table, get the
;	      correct system indicator byte, and write it out. If can not
;	      read/write boot record or can't find DOS partition, display
;	      error
;
;Called Procedures: Message (macro)
;		    Determine_Partition_Type
;		    ReadSector
;		    WriteSector
;
;Change History: Created	4/20/87 	MT
;
;Input: None
;
;Output: CY set if error
;
;Psuedocode
;----------
;
;	Read the partition table (Call ReadSector)
;	IF ok
;	   IF boot signature of 55AAh
;	       Point at system partition table
;	       SEARCH
;		  Assume DOS found
;		  IF System_Indicator <> 1,AND
;		  IF System_Indicator <> 4,AND
;		  IF System_Indicator <> 6
;		    STC   (DOS not found)
;		  ELSE
;		    CLC
;		  ENDIF
;	       EXITIF DOS found (CLC)
;		  CALL Determine_Partition_Type
;		  Write the partition table (CALL WriteSector)
;		  IF error
;		     Display boot write error message
;		     stc
;		  ELSE
;		     clc
;		  ENDIF
;	       ORELSE
;		  Point at next partition entry (add 16 to partition table ptr)
;	       ENDLOOP if checked all 4 partition entries
;		  Display Bad partition table message
;		  stc
;	       ENDSRCH
;	   ELSE invalid boot record
;	      Display Bad partition table message
;	      stc
;	   ENDIF
;	ELSE error
;	   Display Partition table error
;	   stc
;	ENDIF
;	ret
;*****************************************************************************

Procedure SetPartitionTable			;				;AN000;

	xor	ax, ax				;Head				;AC000;
	xor	bx, bx				;Cylinder			;AC000;
	xor	cx, cx				;Sector 			;AC000;
	lea	dx,[boot2]  ;Never use 1.x boot on hardfile,;     ;
	call	ReadSector			;this will use space as buffer	;     ;
;	IF$	NC				;If read okay			;AN000;
	JC IF70$$M
	   cmp	   word [boot2+BOOT_SIGNATURE],Boot_ID ;				;AC000;
;	   IF$	   E				;Does signature match?		;AN000;
	   JNE IF71$$M
	      lea     bx, [boot2+IBMBoot.PartitionTable] ;Yes, point at partition table	;AN000;
;	      SEARCH$				;Look for DOS partition 	;AN000;
DO72$$M:
		 cmp	 [bx+a_PartitionTableEntry.SysInd],FAT12_File_System ;			;AC000;
;		 IF$	 NE,AND 		;				;AN000;
		 JE IF73$$M
		 cmp	 [bx+a_PartitionTableEntry.SysInd],FAT16_File_System ;		     ;AC000;
;		 IF$	 NE,AND 		;				;AN000;
		 JE IF73$$M
		 cmp	 [bx+a_PartitionTableEntry.SysInd],New_File_System ;			  ;AC000;
;		 IF$	 NE			;				;AN000;
		 JE IF73$$M
		    stc 			;We didn't find partition       ;AN000;
;		 ELSE$				;				;AN000;
		 JMP SHORT EN73$$M
IF73$$M:
		    clc 			;Indicate found partition	;AN000;
;		 ENDIF$ 			;				;AN000;
EN73$$M:
;	      EXITIF$ NC			;Get correct id for it		;AN000;
	      JC IF72$$M
		 CALL	 Determine_Partition_Type ;				;AN000;
		 mov	 ax, 0			;Head				;     ;
		 mov	 bx, 0			;Cylinder			;     ;
		 mov	 cx, 0			;Sector 			;     ;
		 lea	 dx,[boot2] ;				;     ;
		 call	 WriteSector		;Write out partition table	;     ;
;		 IF$	 C			;Error writing boot record	;AN000;
		 JNC IF77$$M
		    Message msgPartitionTableWriteError ;			;AC000;
		    stc 			;Set CY to indicate error	;     ;
;		 ELSE$				;				;AN000;
		 JMP SHORT EN77$$M
IF77$$M:
		    clc 			;No error means no CY		;     ;
;		 ENDIF$ 			;				;AN000;
EN77$$M:
;	      ORELSE$				;				;AN000;
	      JMP SHORT SR72$$M
IF72$$M:
		 add	 bx,sizeof.a_PartitionTableEntry ;			;     ;
		 cmp	 bx,(boot2+IBMBoot.PartitionTable)+4*sizeof.a_PartitionTableEntry ;     ;
;	      ENDLOOP$				;Checked all 4 partition entries;AN000;
	      JMP SHORT DO72$$M
		 Message msgbadpartitiontable	;Tell user bad table		;AC000;
		 stc				;Set CY for exit		;     ;
;	      ENDSRCH$				;				;AN000;
SR72$$M:
;	   ELSE$				;Invalid boot record		;AN000;
	   JMP SHORT EN71$$M
IF71$$M:
	      Message msgbadpartitiontable	;				;AC000;
	      stc				;Set CY for error return	;     ;
;	   ENDIF$				;				;AN000;
EN71$$M:
;	ELSE$					;Couldn't read boot record      ;AN000;
	JMP SHORT EN70$$M
IF70$$M:
	   Message msgPartitionTableReadError	;				;AC000;
	   stc					;Set CY for error return	;     ;
;	ENDIF$					;				;AN000;
EN70$$M:
	ret					;				;     ;

;SetPartitionTable endp				;				;AN000;

;*****************************************************************************
;Routine name: Determine_Partition_Type
;*****************************************************************************
;
;DescriptioN: Set the system indicator field to its correct value as
;	      determined by the following rules:
;
;	     - Set SysInd = 01h if partition or logical drive size is < 10mb
;	       and completely contained within the first 32mb of DASD.
;	     - Set SysInd = 04h if partition or logical drive size is >10mb,
;	       <32mb, and completely contained within the first 32mb of DASD
;	     - Set SysInd to 06h if partition or logical drive size is > 32mb,
;
;Called Procedures: Message (macro)
;
;Change History: Created	3/18/87 	MT
;
;Input: BX has offset of partition table entry
;	fBigFAT = TRUE if 16bit FAT
;
;Output: BX.SysInd = correct partition system indicator value (1,4,6)
;
;Psuedocode
;----------
;	Add partition start location to length of partition
;	IF end > 32mb
;	   BX.SysInd = 6
;	ELSE
;	   IF fBigFat
;	      BX.SysInd = 4
;	   ELSE
;	      BX.SysInd = 1
;	   ENDIF
;	ret
;*****************************************************************************

Procedure Determine_Partition_Type						;AN000;

	mov	dx,word [bx+a_PartitionTableEntry.CSec+2] ;an000; dms;Get high word of sector count
	cmp	dx,0								;AN000;    ;> 32Mb?
;	IF$	NE								;AN000;    ;yes
	JE IF87$$M
		mov	[BX+a_PartitionTableEntry.SysInd],New_File_System ;AN000;    ;type 6
;	ELSE$									;AN000;
	JMP SHORT EN87$$M
IF87$$M:
		call	Calc_Total_Sectors_For_Partition			;an000; dms;returns DX:AX total sectors
		cmp	word [deviceParameters.DP_BPB+A_BPB.BPB_HIDDENSECTORS++2],0 ;an000; dms;> 32Mb?
;		if$	ne							;an000; dms;yes
		JE IF89$$M
			mov	[bx+a_PartitionTableEntry.SysInd],New_File_System ;an000; dms; type 6
;		else$								;an000; dms;
		JMP SHORT EN89$$M
IF89$$M:
			cmp	dx,0						;an000; dms; partition > 32 Mb?
;			if$	ne						;an000; dms; yes
			JE IF91$$M
				mov  [bx+a_PartitionTableEntry.SysInd],New_File_System ;an000; dms; type 6
;			else$							;an000; dms; < 32 Mb partition
			JMP SHORT EN91$$M
IF91$$M:
				cmp	byte [fBigFat],TRUE ;an000;    ;16 bit FAT
;				IF$	E					;AC000;    ;yes
				JNE IF93$$M
					mov	[BX+a_PartitionTableEntry.SysInd],FAT16_File_System ;an000;    ;type 4
;				ELSE$						;an000;    ;12 bit FAT
				JMP SHORT EN93$$M
IF93$$M:
					mov	[bx+a_PartitionTableEntry.SysInd],FAT12_File_System ;an000;    ;type 1
;				ENDIF$						;AN000;
EN93$$M:
;			ENDIF$							;an000;
EN91$$M:
;		ENDIF$								;an000;
EN89$$M:
;	endif$									;an000;
EN87$$M:
	ret									;an000;

;Determine_Partition_Type endp			;				;AN000;


;=========================================================================
; Calc_Total_Sectors_For_Partition	: This routine determines the
;					  total number of sectors within
;					  this partition.
;
;	Inputs	: DeviceParameters
;
;	Outputs : DX:AX - Double word partition size
;=========================================================================

Procedure Calc_Total_Sectors_For_Partition					;an000; dms;

	mov	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_HIDDENSECTORS++0] ;an000; dms; low word
	mov	dx,word [deviceParameters.DP_BPB+A_BPB.BPB_HIDDENSECTORS++2] ;an000; dms; high word
	cmp	word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS],0 ;an000; dms; extended BPB?
;	if$	e								;an000; dms; yes
	JNE IF99$$M
		add	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS++0] ;an000; dms; add in low word
		adc	dx,0							;an000; dms; pick up carry if any
		add	dx,word [deviceParameters.DP_BPB+A_BPB.BPB_BIGTOTALSECTORS++2] ;an000; dms; add in high word
;	else$									;an000; dms; standard BPB
	JMP SHORT EN99$$M
IF99$$M:
		add	ax,word [deviceParameters.DP_BPB+A_BPB.BPB_TOTALSECTORS] ;an000; dms; add in total sector count
		adc	dx,0							;an000; dms; pick up carry if any
;	endif$									;an000; dms;
EN99$$M:

	ret

;Calc_Total_Sectors_For_Partition	endp


;-------------------------------------------------------------------------------
; ReadSector:
;    Read one sector
;
;    Input:
;	ax - head
;	bx - cylinder
;	cx - sector
;	dx - transfer address

ReadSector:

	mov	[trackReadWritePacket.TRWP_FIRSTSECTOR], cx
	mov	cx,(RAWIO shl 8) or READ_TRACK
	call	SectorIO
	return

;ReadSector endp

;-------------------------------------------------------------------------------
; WriteSector:
;    Write one sector
;
;    Input:
;	ax - head
;	bx - cylinder
;	cx - sector
;	dx - transfer address

WriteSector:

	mov	[trackReadWritePacket.TRWP_FIRSTSECTOR], cx
	mov	cx,(RAWIO shl 8) or WRITE_TRACK
	call	SectorIO
	return

;WriteSector endp

;-------------------------------------------------------------------------------
; SectorIO:
;    Read/Write one sector
;
;    Input:
;	ax - head
;	bx - cylinder
;	cx - (RAWIO shl 8) or READ_TRACK
;	   - (RAWIO shl 8) or WRITE_TRACK
;	dx - transfer address

SectorIO:

	mov	[trackReadWritePacket.TRWP_HEAD], ax
	mov	[trackReadWritePacket.TRWP_CYLINDER], bx
	mov	word [trackReadWritePacket.TRWP_TRANSFERADDRESS], dx
	mov	word [trackReadWritePacket.TRWP_TRANSFERADDRESS+2], ds
	mov	[trackReadWritePacket.TRWP_SECTORSTOREADWRITE], 1

	mov	bl, [drive]
	inc	bl
	mov	ax, (IOCtl shl 8) or GENERIC_IOCTL
	lea	dx,[trackReadWritePacket]
	int	21H
	return

;SectorIO endp

;-------------------------------------------------------------------------------

end if
if SEGSEL = S_DATA

oldDrive rb      1

FCBforVolumeIdSearch db 0ffH
	db	5 dup(0)
	db	08H
	db	0
	db	"???????????"
	db	40 DUP(0)

end if
if SEGSEL = S_CODE

GetVolumeId:
; Input:
;    dl = drive
;    di = name buffer

; Save current drive
	mov	ah,19H
	int	21H
	mov	[oldDrive], al

; Change current drive to the drive that has the volume id we want
	mov	ah, 0eH
	int	21H

; Search for the volume id
	mov	ah, 11H
	lea	dx,[FCBforVolumeIdSearch]
	int	21H
	push	ax

; Restore current drive
	mov	ah, 0eH
	mov	dl,[oldDrive]
	int	21H

; Did the search succeed?
	pop	ax
	or	al,al
	jz	CopyVolumeId
	stc
	ret

CopyVolumeId:
; Find out where the FCB for the located volume id was put
	mov	ah,2fH
	int	21H

; Copy the Volume Id
	mov	si, bx
	add	si, 8
	push	es
	push	ds
	pop	es
	pop	ds
	mov	cx, 11
	rep	movsb
	push	es
	pop	ds

	clc
	ret

;GetVolumeId endp

end if
if SEGSEL = S_DATA
oldVolumeId db	11 dup(0)
end if
if SEGSEL = S_CODE

CheckVolumeId:

; Get the volume id that's on the disk
	lea	di,[oldVolumeId]
	mov	dl, [drive]
	call	GetVolumeId
	jnc	Ask_User			;Did we find one?
	clc					;No, return with no error
	ret

; Ask the user to enter the volume id that he/she thinks is on the disk
; (first blank out the input buffer)
Ask_User:

	Message msgWhatIsVolumeId?		;				;AC000;
						;lea	 dx, ptr_msgWhatIsVolumeId?
						;call	 std_printf
	call	USER_STRING
	call	crlf

; If the user just pressed ENTER, then there must be no label
	cmp	[INBUFF+1], 0
	jne	CompareVolumeIds
	cmp	byte [oldVolumeId], 0
	jne	BadVolumeId
	ret

CompareVolumeIds:
; pad the reponse with blanks
; The buffer is big enough so just add 11 blanks to what the user typed in
	push	ds
	pop	es
	mov	cx, Label_Length		;AC000;
	xor	bx,bx
	mov	bl, [INBUFF + 1]
	lea	di, [INBUFF + 2]
	add	di, bx
	mov	al, ' '
	rep	stosb
; Make the reply all uppercase
	mov	byte [INBUFF+2+Label_Length],Asciiz_End   ;Make string ASCIIZ	 ;AN000;
	mov	dx, INBUFF + 2         ;Start of buffer		;AC000;
	mov	al,22h				;Capitalize asciiz		;AC000;
	DOS_Call GetExtCntry			;Do it				;AC000;

; Now compare what the user specified with what is really out there
	mov	cx, Label_Length		;				;AC000;
	lea	si, [INBUFF + 2]
	lea	di,[oldVolumeId]
	repe	cmpsb
	jne	BadVolumeId
	ret

BadVolumeId:
	Message msgBadVolumeId			;				;AC000;
	stc
	ret

;CheckVolumeId endp


Check_Switch_8_B:

	   test    word [SWITCHMAP], SWITCH_B ;/8/B <> /V because		;AC007;
;	   IF$	   NZ,AND			; old directory type		;AC007;
	   JZ IF102$$M
	   test    word [SWITCHMAP], SWITCH_8 ; used which didn't support     ;AC007;
;	   IF$	   NZ,AND			; volume labels.		;AC007;
	   JZ IF102$$M
	   test    word [SWITCHMAP], SWITCH_V ;				;AC007;
;	   IF$	   NZ				;				;AC007;
	   JZ IF102$$M
	      Message msgIncompatibleParameters ;Tell user			;AC007;
	      mov     byte [Fatal_Error],YES ;Bad stuff			;AC007;
;	   ELSE$				;No problem so far		;AC007;
	   JMP SHORT EN102$$M
IF102$$M:
	      test    word [SWITCHMAP], SWITCH_B ;Can't reserve space and        ;AC007;
;	      IF$     NZ,AND			; install sys files at the	;AC007;
	      JZ IF104$$M
	      test    word [SWITCHMAP], SWITCH_S ; same time.			;AC007;
;	      IF$     NZ			; No /S/B			;AC007;
	      JZ IF104$$M
		 Message msgIncompatibleParameters ;Tell user			;AC007;
		 mov	 byte [Fatal_Error],YES ;Bad stuff			;AC007;
;	       ELSE$				 ;Still okay			 ;AC007;
	       JMP SHORT EN104$$M
IF104$$M:
		  test	  word [SWITCHMAP],SWITCH_1 ;/1/8/4 not okay with /N/T	 ;AC007;
;		  IF$	  NZ,OR 		 ;				 ;AC007;
		  JNZ LL106$$M
		  test	  word [SWITCHMAP],SWITCH_8 ;				 ;AC007;
;		  IF$	  NZ,OR 		 ;				 ;AC007;
		  JNZ LL106$$M
		  test	  word [SWITCHMAP],SWITCH_4 ;				 ;AC007;
;		  IF$	  NZ			 ;				 ;AC007;
		  JZ IF106$$M
LL106$$M:
		     test    word [SWITCHMAP],(SWITCH_T or SWITCH_N) ; 		 ;AC007;
;		     IF$     NZ 		 ;Found /T/N <> /1/8		 ;AC007;
		     JZ IF107$$M
			Message msgIncompatibleParameters ;Tell user		 ;AC007;
			mov	byte [Fatal_Error],YES ;Bad stuff			 ;AC007;
;		     ELSE$			 ;				 ;ac007;
		     JMP SHORT EN107$$M
IF107$$M:
			test	word [SWITCHMAP],SWITCH_V ;ac007;
;			IF$	NZ,AND						 ;ac007;
			JZ IF109$$M
			test	word [SWITCHMAP],SWITCH_8 ;ac007;
;			IF$	NZ						 ;ac007;
			JZ IF109$$M
				Message msgIncompatibleParameters		 ;ac007;
				mov	byte [Fatal_Error],YES ;ac007;
;			ENDIF$							 ;ac007;
IF109$$M:
;		     ENDIF$			 ;				 ;AC007;
EN107$$M:
;		  ENDIF$			 ;				 ;AC007;
IF106$$M:
;	       ENDIF$				 ;				 ;AC007;
EN104$$M:
;	    ENDIF$				 ;				 ;AC007;
EN102$$M:
	    ret

;Check_Switch_8_B	endp


end if
;	end
