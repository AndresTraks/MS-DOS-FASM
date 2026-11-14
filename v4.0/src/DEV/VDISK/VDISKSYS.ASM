STRUC RHC RHC_1_=0, RHC_2_=0, RHC_CMD_=0, RHC_STA_=0
{
	DB	RHC_1_ ;length of Request Header (including data)
	DB	RHC_2_ ;unit code (subunit)
.RHC_CMD DB	RHC_CMD_ ;command code
.RHC_STA DW	RHC_STA_ ;status
	DQ	?			;reserved for DOS
;;;;;	DW	?			;reserved for BIOS message flag 	;an006; dms;
}
match =RHC_LAID_OUT, RHC_LAID_OUT
{
    RHC_LAID_OUT equ 1
    virtual at 0
      RHC RHC 0, 0, 0, 0
      sizeof.RHC = $ - RHC
    end virtual
}
STRUC RH0 RH0_NUN_=0, RH0_ENDO_=0, RH0_ENDS_=0, RH0_BPBO_=0, RH0_BPBS_=0, RH0_DRIV_=0, RH0_FLAG_=0
{
	rb      (sizeof.RHC)  ;common portion
.RH0_NUN DB	RH0_NUN_ ;number of units
					;set to 1 if installation succeeds,
					;set to 0 to cause installation failure
.RH0_ENDO DW	RH0_ENDO_ ;offset  of ending address
.RH0_ENDS DW	RH0_ENDS_ ;segment of ending address
.RH0_BPBO DW	RH0_BPBO_ ;offset  of BPB array address
.RH0_BPBS DW	RH0_BPBS_ ;segment of BPB array address
.RH0_DRIV DB	RH0_DRIV_ ;drive code (DOS 3 only)
.RH0_FLAG DW	RH0_FLAG_ ;initialized to no error		;an000; dms;
}
match =RH0_LAID_OUT, RH0_LAID_OUT
{
    RH0_LAID_OUT equ 1
    virtual at 0
      RH0 RH0 0, 0, 0, 0, 0, 0, 0
      sizeof.RH0 = $ - RH0
    end virtual
}
STRUC RH1 RH1_1_=0, RH1_RET_=0
{
	rb      (sizeof.RHC)  ;common portion
	DB	RH1_1_ ;media descriptor
.RH1_RET DB	RH1_RET_ ;return information
}
match =RH1_LAID_OUT, RH1_LAID_OUT
{
    RH1_LAID_OUT equ 1
    virtual at 0
      RH1 RH1 0, 0
      sizeof.RH1 = $ - RH1
    end virtual
}
STRUC RH2 RH2_1_=0, RH2_2_=0, RH2_3_=0, RH2_BPBO_=0, RH2_BPBS_=0
{
	rb      (sizeof.RHC)	;common portion
	DB	RH2_1_ ;media descriptor
	DW	RH2_2_ ;offset  of transfer address
	DW	RH2_3_ ;segment of transfer address
.RH2_BPBO DW	RH2_BPBO_ ;offset  of BPB table address
.RH2_BPBS DW	RH2_BPBS_ ;segment of BPB table address
}
match =RH2_LAID_OUT, RH2_LAID_OUT
{
    RH2_LAID_OUT equ 1
    virtual at 0
      RH2 RH2 0, 0, 0, 0, 0
      sizeof.RH2 = $ - RH2
    end virtual
}
STRUC RH4 RH4_1_=0, RH4_DTAO_=0, RH4_DTAS_=0, RH4_CNT_=0, RH4_SSN_=0
{
	rb      (sizeof.RHC)  ;common portion
	DB	RH4_1_ ;media descriptor
.RH4_DTAO DW	RH4_DTAO_ ;offset  of transfer address
.RH4_DTAS DW	RH4_DTAS_ ;segment of transfer address
.RH4_CNT DW	RH4_CNT_ ;sector count
.RH4_SSN DW	RH4_SSN_ ;starting sector number
}
match =RH4_LAID_OUT, RH4_LAID_OUT
{
    RH4_LAID_OUT equ 1
    virtual at 0
      RH4 RH4 0, 0, 0, 0, 0
      sizeof.RH4 = $ - RH4
    end virtual
}
STRUC DESC DESC_LMT_=0, DESC_BASEL_=0, DESC_BASEH_=0, DESC_4_=0, DESC_5_=0
{
.DESC_LMT DW	DESC_LMT_ ;segment limit (length)
.DESC_BASEL DW	DESC_BASEL_ ;bits 15-0 of physical address
.DESC_BASEH DB	DESC_BASEH_ ;bits 23-16 of physical address
	DB	DESC_4_ ;access rights byte
	DW	DESC_5_ ;reserved
}
match =DESC_LAID_OUT, DESC_LAID_OUT
{
    DESC_LAID_OUT equ 1
    virtual at 0
      DESC DESC 0, 0, 0, 0, 0
      sizeof.DESC = $ - DESC
    end virtual
}
STRUC SUBLIST SL_SIZE_=0, SL_RES_=0, SL_OFFSET_=0, SL_SEGMENT_=0, SL_ID_=0, SL_FLAG_=0, SL_MAXW_=0, SL_MINW_=0, SL_PAD_=0
{

.SL_SIZE DB	SL_SIZE_ ;AN000;SUBLIST SIZE
.SL_RES	DB	SL_RES_ ;AN000;RESERVED
.SL_OFFSET DW	SL_OFFSET_ ;AN000;PARM OFFSET
.SL_SEGMENT DW	SL_SEGMENT_ ;AN000;PARM SEGMENT
.SL_ID	DB	SL_ID_ ;AN000;NUMBER OF PARM
.SL_FLAG DB	SL_FLAG_ ;AN000;DISPLAY TYPE
.SL_MAXW DB	SL_MAXW_ ;AN000;MAXIMUM FIELD WIDTH
.SL_MINW DB	SL_MINW_ ;AN000;MINIMUM FIELD WIDTH
.SL_PAD	DB	SL_PAD_ ;AN000;PAD CHARACTER

}
match =SUBLIST_LAID_OUT, SUBLIST_LAID_OUT
{
    SUBLIST_LAID_OUT equ 1
    virtual at 0
      SUBLIST SUBLIST 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.SUBLIST = $ - SUBLIST
    end virtual
}
STRUC BIOS_SYSTEM_DESCRIPTOR bios_SD_leng_=0, bios_SD_modelbyte_=0, bios_SD_scnd_modelbyte_=0, BIOS_SYSTEM_DESCRIPTOR_4_=0, bios_SD_featurebyte1_=0
{

.bios_SD_leng dw bios_SD_leng_ ;AN000;VECTOR LENGTH
.bios_SD_modelbyte db bios_SD_modelbyte_ ;AN000;SYSTEM MODEL TYPE
.bios_SD_scnd_modelbyte db bios_SD_scnd_modelbyte_ ;AN000;
	db	BIOS_SYSTEM_DESCRIPTOR_4_ ;AN000;
.bios_SD_featurebyte1 db bios_SD_featurebyte1_ ;AN000;
	Rb	4

}
match =BIOS_SYSTEM_DESCRIPTOR_LAID_OUT, BIOS_SYSTEM_DESCRIPTOR_LAID_OUT
{
    BIOS_SYSTEM_DESCRIPTOR_LAID_OUT equ 1
    virtual at 0
      BIOS_SYSTEM_DESCRIPTOR BIOS_SYSTEM_DESCRIPTOR 0, 0, 0, 0, 0
      sizeof.BIOS_SYSTEM_DESCRIPTOR = $ - BIOS_SYSTEM_DESCRIPTOR
    end virtual
}
	PAGE	,132
	TITLE	VDISK - Virtual Disk Device Driver, Version 4.00

;VDISK simulates a disk drive, using Random Access Memory as the storage medium.

;(C) Copyright Microsoft Corporation, 1984 - 1988
;Licensed Material - Program Property of Microsoft Corp.

;Add the following statement to CONFIG.SYS
;	DEVICE=[d:][path]VDISK.SYS bbb sss ddd [/E:m]

;   where:  bbb is the desired buffer size (in kilobytes)
;		minimum 1KB, maximum is size of available memory,
;		default is 64KB.

;		VDISK will leave at least 64KB of available memory,
;		although subsequent device drivers (other than VDISK)
;		other programs that make themselves resident, and
;		COMMAND.COM will result in less than 64KB as shown
;		by CHKDSK.

;		Must be large enough for 1 boot sector + FAT sectors
;		+ 1 directory sector + at least 1 data cluster,
;		or the device driver won't be installed.

;	    sss is the desired sector size (in bytes)
;		128, 256, or 512, default is 128.
;		Will be adjusted if number of FAT entries > 0FE0H

;	    ddd is the desired number of directory entries
;		Minimum 2, maximum 512, default 64.
;		Will be rounded upward to sector size boundary.

;	    /E may only be used if extended memory above 1 megabyte
;	    is to be used.  INT 15H functions 87H and 88H are used
;	    to read and write this extended memory.
;	    The m parameter in the /E option specifies the maximum
;	    number of sectors that the VDISK will transfer at a time.
;	    Optional values are 1,2,3,4,5,6,7 or 8 sectors, the default
;	    is 8 sectors.

;	    Brackets indicate optional operands.


; Samples:
;	DEVICE=\path\VDISK.SYS 160 512 64
;	results in a 160KB VDISK, with 512 byte sectors, 64 directory entries

;	DEVICE=VDISK.SYS Buffersize 60 Sectorsize 128 Directory entries 32
;	(since only numbers are interpreted, you may comment the line with
;	non-numeric characters)
;
;=========================================================================
; Change List
;
;	AN000	- ver 4.0 specified changes
;	AN001	- DCR 377 Modify VDISK Extended Memory allocation technique
;			  The allocation technique have been modified to
;			  allocate EM from the top down.  To notify other
;			  users that EM has been used by VDISK, VDISK
;			  hooks function 88h, INT 15h.
;
;	AN002	- PTM3214 EMS VDISK needed to be modified for two errors.
;	AC002		  The first related to VDISK returning the
;			  "Insufficient Memory" message when in fact
;			  there was enough EMS memory to support the
;			  requested VDISK.
;			  The second related to an EMS VDISK hanging when
;			  a program was invoked from an EMS VDISK with a
;			  non-standard sector size, i.e.; 128 bytes/sector,
;			  etc.	This error was caused by the incorrect
;			  calculation of sectors per EMS page.
;
;	AN003	- PTM3276 EMS VDISK causes a "Divide Overflow" message.
;	AC003		  This is caused by a byte divide that should
;			  be performed as a word divide.
;
;	AN004	- PTM3301 EMS VDISK does not properly adjust the buffer
;			  size when too much EMS memory is requested.
;			  The code in UPDATE_AVAIL pertaining to EMS
;			  space allocation has been modified.
;
;	AN005	- DCR474  Convert VDISK to support /E for extended memory
;			  and /X for expanded memory.
;
;	AN006	- PTM4729 Enable VDISK for the INT 2F call to determine
;			  the reserved EMS page for VDISK and FASTOPEN
;
;=========================================================================

;Message text for VDISK is in module VDISKMSG.
.xlist
	include 'VDISKSYS.INC'
	include 'SYSMSG.INC'
	MSG_UTILNAME<VDISK>
.list
	SUBTTL	Structure Definitions
	PAGE
;-----------------------------------------------------------------------;
;	Request Header (Common portion) 				;
;-----------------------------------------------------------------------;
RH	equ	ds:BX	;addressability to Request Header structure


CMD_INPUT EQU	4			;RHC_CMD is INPUT request

;status values for RHC_STA

STAT_DONE EQU	01H			;function complete status (high order byte)
STAT_CMDERR EQU 8003H			;invalid command code error
STAT_CRC EQU	8004H			;CRC error
STAT_SNF EQU	8008H			;sector not found error
STAT_BUSY EQU	0200H			;busy bit (9) for Removable Media call
;-----------------------------------------------------------------------;
;	Request Header for INIT command 				;
;-----------------------------------------------------------------------;

label RH0_BPBA dword at RH0.RH0_BPBO	;offset/segment of BPB array address
;Note: RH0_BPBA at entry to INIT points to all after DEVICE= on CONFIG.SYS stmt

;-----------------------------------------------------------------------;
;	Request Header for MEDIA CHECK Command				;
;-----------------------------------------------------------------------;
;-----------------------------------------------------------------------;
;	Request Header for BUILD BPB Command				;
;-----------------------------------------------------------------------;
;-----------------------------------------------------------------------;
;	Request Header for INPUT, OUTPUT, and OUTPUT with verify	;
;-----------------------------------------------------------------------;

label RH4_DTAA dword at RH4.RH4_DTAO	;offset/segment of transfer address

;-----------------------------------------------------------------------;
;	Segment Descriptor (part of Global Descriptor Table)		;
;-----------------------------------------------------------------------;

	SUBTTL	Equates and Macro Definitions
	PAGE

MEM_SIZE EQU	12H			;BIOS memory size determination INT
					;returns system size in KB in AX

EM_INT	EQU	15H			;extended memory BIOS interrupt INT
EM_BLKMOVE EQU	87H			;block move function
EM_MEMSIZE EQU	8800H			;memory size determination in KB

DOS	EQU	21H			;DOS request INT
DOS_PCHR EQU	02H			;print character function
DOS_PSTR EQU	09H			;print string function
DOS_VERS EQU	30H			;get DOS version

TAB	EQU	09H			;ASCII tab
LF	EQU	0AH			;ASCII line feed
CR	EQU	0DH			;ASCII carriage return

PARA_SIZE EQU	16			;number of bytes in one 8088 paragraph
DIR_ENTRY_SIZE EQU 32			;number of bytes per directory entry
MAX_FATE EQU	0FE0H			;largest number of FAT entries allowed

;default values used if parameters are omitted

DFLT_BSIZE EQU	64			;default VDISK buffer size (KB)
DFLT_SSZ EQU	128			;default sector size
DFLT_DIRN EQU	64			;default number of directory entries
DFLT_ESS EQU	8			;default maximum sectors to transfer

MIN_DIRN EQU	2			;minimum number of directory entries
MAX_DIRN EQU	512			;maximum number of directory entries

STACK_SIZE EQU	512			;length of stack during initialization

	SUBTTL	Resident Data Area
	PAGE

;-----------------------------------------------------------------------;
;	Map INT 15H vector in low storage				;
;-----------------------------------------------------------------------;
virtual at 00H
	ORG	4*EM_INT
label EM_VEC dword
EM_VECO rw      1 ;offset
EM_VECS rw      1 ;segment
end virtual



;CSEG	SEGMENT PARA PUBLIC 'CODE'
;	ASSUME	CS:CSEG
;-----------------------------------------------------------------------;
;	Resident data area.						;
;									;
;	All variables and constants required after initialization	;
;	part one are defined here.					;
;-----------------------------------------------------------------------;

; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
START	=	$			;begin resident VDISK data & code

;DEVICE HEADER - must be at offset zero within device driver
	DD	-1			;becomes pointer to next device header
	DW	0800H			;attribute (IBM format block device)
					;supports OPEN/CLOSE/RM calls
	DW	STRATEGY         ;pointer to device "strategy" routine
	DW	IRPT         ;pointer to device "interrupt handler"
	DB	1			;number of block devices
	rb      7     ;7 byte filler (remainder of 8-byte name)
;END OF DEVICE HEADER

;This volume label is placed into the directory of the new VDISK
;This constant is also used to determine if a previous extended memory VDISK
;has been installed.

VOL_LABEL DB	'VDISK  V4.0'		;00-10 volume name (shows program level)
	DB	28H			;11-11 attribute (volume label)
	db	10 dup (0) ;12-21 reserved
	DW	6000H			;22-23 time=12:00 noon
	DW	0986H			;24-25 date=12/06/84
VOL_LABEL_LEN = ($-VOL_LABEL)	;length of volume label

;The following field, in the first extended memory VDISK device driver,
;is the 24-bit address of the first free byte of extended memory.
;This address is not in the common offset/segment format.
;The initial value, 10 0000H, is 1 megabyte.

AVAIL_LO DW	0			;address of first free byte of
AVAIL_HI DB	10H			;extended memory

label INTV15 dword
INTV15O rw      1 ;offset
INTV15S rw      1 ;segment


PARAS_PER_SECTOR rw      1 ;number of 16-byte paragraphs in one sector

START_BUFFER_PARA rw      1 ;segment address of start of VDISK buffer

EM_New_Size rw      1 ;an001; dms;new size for EM
EM_KSize rw      1 ;an001; dms;size of EM currently.

EM_SW	DB	0			;NON-ZERO IF EXTENDED MEMORY

EM_STAT DW	0			;AX from last unsuccessful extended memory I/O

START_EM_LO rw      1 ;24-bit address of start of VDISK buffer
START_EM_HI rb      1 ;(extended memory only)

WPARA_SIZE DW	PARA_SIZE		;number of bytes in one paragraph

MAX_CNT rw      1 ;(0FFFFH/BPB_SSZ) truncated, the maximum
					;number of sectors that can be transferred
					;without worrying about 64KB wrap

SECT_LEFT rw      1 ;sectors left to transfer

label IO_SRCA dword   ;offset/segment of source
IO_SRCO rw      1 ;offset
IO_SRCS rw      1 ;segment

label IO_TGTA dword   ;offset/segment of target
IO_TGTO rw      1 ;offset
IO_TGTS rw      1 ;segment

;-----------------------------------------------------------------------;
;	EMS Support							;
;-----------------------------------------------------------------------;

EM_SW2	DB	not EMS_INSTALLED_FLAG	;ac006;Default if EMS not installed
EMS_HANDLE rw      1 ;AN000; EMS handle for reference
EMS_FRAME_ADDR rw      1 ;AN000; EMS handle for reference
EMS_CURR_SECT rw      1 ;an000; Current EMS sector being addressed
CURR_EMS_PAGE rw      1 ;ac002; Current EMS page number
SECT_LEFT_IN_FRAME rw      1 ;AN000; Sectors left to transfer in this frame
SECT_PER_PAGE rw      1 ;AN000; Sectors per page
DOS_Page	rw      1 ;an006; EMS physical page for VDISK

EMS_SAVE_ARRAY DB 80h	  dup(0)	;an000; save current state of ems
EMS_SEG_ARRAY rd      1 ;an000; save segment array

CURR_DTA_OFF rw      1 ;AN000; DMS;CURRENT OFFSET OF DTA

PC_386	DB	FALSE			;AN000; DMS;386 machine flag




;-----------------------------------------------------------------------;
;	BIOS Parameter Block (BPB)					;
;-----------------------------------------------------------------------;
;This is where the characteristics of the virtual disk are established.
;A copy of this block is moved into the boot record of the virtual disk.
;DEBUG can be used to read sector zero of the virtual disk to examine the
;boot record copy of this block.

label BPB byte   ;BIOS Parameter Block (BPB)
BPB_SSZ DW	0			;number of bytes per disk sector
BPB_AUSZ DB	1			;sectors per allocation unit
BPB_RES DW	1			;number of reserved sectors (for boot record)
BPB_FATN DB	1			;number of File Allocation Table (FAT) copies
BPB_DIRN DW	0			;number of root directory entries
BPB_SECN DW	1			;total number of sectors
					;computed from buffer size and sector size
					;(this includes reserved, FAT, directory,
					;and data sectors)
BPB_MCB DB	0FEH			;media descriptor byte
BPB_FATSZ DW	1			;number of sectors occupied by a single FAT
					;computed from BPBSSZ and BPBSECN
BPB_LEN =	($-BPB)	;length of BIOS parameter block

BPB_PTR DW	BPB			;BIOS Parameter Block pointer array (1 entry)
;-----------------------------------------------------------------------;
;	Request Header (RH) address, saved here by "strategy" routine	;
;-----------------------------------------------------------------------;
label RH_PTRA dword
RH_PTRO rw      1 ;offset
RH_PTRS rw      1 ;segment
;-----------------------------------------------------------------------;
;	Global Descriptor Table (GDT), used for extended memory moves	;
;-----------------------------------------------------------------------;
;Access Rights Byte (93H) is
;	P=1	(segment is mapped into physical memory)
;	E=0	(data segment descriptor)
;	D=0	(grow up segment, offsets must be <= limit)
;	W=1	(data segment may be written into)
;	DPL=0	(privilege level 0)

label GDT byte   ;begin global descriptor table
	DESC$1 DESC  ;dummy descriptor
	DESC$2 DESC  ;descriptor for GDT itself
SRC	DESC ,,,93H,    ;source descriptor
TGT	DESC ,,,93H,    ;target descriptor
	DESC$3 DESC  ;BIOS CS descriptor
	DESC$4 DESC  ;stack segment descriptor

	SUBTTL	INT 15H (size) interrupt handler
	PAGE
;-----------------------------------------------------------------------;
;	INT 15H Interrupt Handler routine				;
;-----------------------------------------------------------------------;

;=========================================================================
; VDISK_INT15	: This routine traps the INT 15h requests to perform its
;		  own unique services.	This routine provides 1 INT 15h
;		  service; function 8800h.
;
;	Service - Function 8800h: Obtains the size of EM from the word
;				  value EM_KSize
;			Call With: AX - 8800h
;			Returns  : AX - Kbyte size of EM
;
;=========================================================================
VDISK_INT15:       ;an001; dms;

	cmp	ah,EM_Size_Get		;an001; dms;function 88h
;	if$	e			;an001; dms;get size
	JNE IF1$$
	    mov     ax,[cs:EM_KSize] ;an001; dms;return size
	    clc 			;an001; dms;clear CY
;	else$				;an001; dms;
	JMP SHORT EN1$$
IF1$$:
	    jmp     [cs:INTV15] ;an001; dms;jump to org. vector
;	endif$				;an001; dms;
EN1$$:

	iret				;an001; dms;

;VDISK_INT15 ENDP			;an001; dms;


;	ASSUME	DS:NOTHING

	SUBTTL	Device Strategy & interrupt entry points
	PAGE
;-----------------------------------------------------------------------;
;	Device "strategy" entry point					;
;									;
;	Retain the Request Header address for use by Interrupt routine	;
;-----------------------------------------------------------------------;
STRATEGY:
	MOV	[cs:RH_PTRO],BX ;offset
	MOV	[cs:RH_PTRS],ES ;segment
	RETF
;STRATEGY ENDP
;-----------------------------------------------------------------------;
;	Table of command processing routine entry points		;
;-----------------------------------------------------------------------;
label CMD_TABLE word
	DW	INIT_P1         ; 0 - Initialization
	DW	MEDIA_CHECK        ; 1 - Media check
	DW	BLD_BPB         ; 2 - Build BPB
	DW	INPUT_IOCTL        ; 3 - IOCTL input
	DW	INPUT         ; 4 - Input
	DW	INPUT_NOWAIT        ; 5 - Non destructive input no wait
	DW	INPUT_STATUS        ; 6 - Input status
	DW	INPUT_FLUSH        ; 7 - Input flush
	DW	OUTPUT         ; 8 - Output
	DW	OUTPUT_VERIFY        ; 9 - Output with verify
	DW	OUTPUT_STATUS        ;10 - Output status
	DW	OUTPUT_FLUSH        ;11 - Output flush
	DW	OUTPUT_IOCTL        ;12 - IOCTL output
	DW	DEVICE_OPEN        ;13 - Device OPEN
	DW	DEVICE_CLOSE        ;14 - Device CLOSE
MAX_CMD =	(($-CMD_TABLE)/2)	;highest valid command follows
	DW	REMOVABLE_MEDIA        ;15 - Removable media

;-----------------------------------------------------------------------;
;	Device "interrupt" entry point					;
;-----------------------------------------------------------------------;
IRPT:           ;device interrupt entry point
	PUSH	DS			;save all registers modified
	PUSH	ES
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	SI
					;BP isn't used, so it isn't saved
	CLD				;all moves forward

	LDS	BX,[cs:RH_PTRA] ;get RH address passed to "strategy" into DS:BX

	MOV	AL,byte [RH+RHC.RHC_CMD] ;command code from Request Header
	CBW				;zero AH (if AL > 7FH, next compare will
					;catch that error)

	CMP	AL,MAX_CMD		;if command code is too high
	JA	IRPT_CMD_HIGH		;jump to error routine

	MOV	DI,IRPT_CMD_EXIT        ;return addr from command processor
	PUSH	DI			;push return address onto stack
					;command routine issues "RET"

	ADD	AX,AX			;double command code for table offset
	MOV	DI,AX			;put into index register for JMP

	XOR	AX,AX			;initialize return to "no error"

;At entry to command processing routine:

;	DS:BX	= Request Header address
;	CS	= VDISK code segment address
;	AX	= 0

;	top of stack is return address, IRPT_CMD_EXIT

	JMP	[cs:CMD_TABLE+DI] ;call routine to handle the command


IRPT_CMD_ERROR: 			;CALLed for unsupported character mode commands

INPUT_IOCTL:				;IOCTL input
INPUT_NOWAIT:				;Non-destructive input no wait
INPUT_STATUS:				;Input status
INPUT_FLUSH:				;Input flush

OUTPUT_IOCTL:				;IOCTL output
OUTPUT_STATUS:				;Output status
OUTPUT_FLUSH:				;Output flush

	POP	AX			;pop return address off stack

IRPT_CMD_HIGH:				;JMPed to if RHC_CMD > MAX_CMD
	MOV	AX,STAT_CMDERR		;"invalid command" and error

IRPT_CMD_EXIT:				;return from command routine
					;AX = value to OR into status word
	LDS	BX,[cs:RH_PTRA] ;restore DS:BX as Request Header pointer
	OR	AH,STAT_DONE		;add "done" bit to status word
	MOV	word [RH+RHC.RHC_STA],AX ;store status into request header
	POP	SI			;restore registers
	POP	DI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	POP	ES
	POP	DS
	RETF
;IRPT	ENDP

	SUBTTL	Command Processing routines
	PAGE
;-----------------------------------------------------------------------;
;	Command Code 1 - Media Check					;
;	At entry, DS:BX point to request header, AX = 0 		;
;-----------------------------------------------------------------------;
MEDIA_CHECK:
	MOV	byte [RH+RH1.RH1_RET],1 ;indicate media not changed
	RET				;AX = zero, no error
;MEDIA_CHECK ENDP
;-----------------------------------------------------------------------;
;	Command Code 2 - Build BPB					;
;	At entry, DS:BX point to request header, AX = 0 		;
;-----------------------------------------------------------------------;
BLD_BPB:
	MOV	word [RH+RH2.RH2_BPBO],BPB ;return pointer to our BPB
	MOV	word [RH+RH2.RH2_BPBS],CS
	RET				;AX = zero, no error
;BLD_BPB ENDP
;-----------------------------------------------------------------------;
;	Command Code 13 - Device Open					;
;	Command Code 14 - Device Close					;
;	Command Code 15 - Removable media				;
;	At entry, DS:BX point to request header, AX = 0 		;
;-----------------------------------------------------------------------;
REMOVABLE_MEDIA:
	MOV	AX,STAT_BUSY		;set status bit 9 (busy)
					;indicating non-removable media
DEVICE_OPEN:				;NOP for device open
DEVICE_CLOSE:				;NOP for device close
	RET
;REMOVABLE_MEDIA ENDP			;fall thru to return
;-----------------------------------------------------------------------;
;	Command Code 4 - Input						;
;	Command Code 8 - Output 					;
;	Command Code 9 - Output with verify				;
;	At entry, DS:BX point to request header, AX = 0 		;
;-----------------------------------------------------------------------;
INOUT:
INPUT:
OUTPUT:
OUTPUT_VERIFY:
;;;;;	PUSH	DS			;ICE
;;;;;	push	bx			;ICE
;;;;;	push	ax			;ICE

;;;;;	mov	bx,0140H		;ICE
;;;;;	xor	ax,ax			;ICE
;;;;;	mov	ds,ax			;ICE
;;;;;	mov	ax,word ptr ds:[bx]	;ICE
;;;;;	mov	word ptr ds:[bx],ax	;ICE

;;;;;	pop	ax			;ICE
;;;;;	pop	bx			;ICE
;;;;;	POP	DS			;ICE

;Make sure I/O is entirely within the VDISK sector boundaries

	MOV	CX,[cs:BPB_SECN] ;get total sector count
	MOV	AX,word [RH+RH4.RH4_SSN] ;starting sector number
	CMP	AX,CX			;can't exceed total count
	JA	INOUT_E1		;jump if start > total

	ADD	AX,word [RH+RH4.RH4_CNT] ;start + sector count
	CMP	AX,CX			;can't exceed total count
	JNA	INOUT_A 		;jump if start + count <= total

INOUT_E1:				;I/O not within VDISK sector boundaries
	MOV	word [RH+RH4.RH4_CNT],0 ;set sectors transferred to zero
	MOV	AX,STAT_SNF		;indicate 'Sector not found' error
	RET				;return with error status in AX

INOUT_A:				;I/O within VDISK bounds
	MOV	AX,word [RH+RH4.RH4_CNT] ;get sector count
	MOV	[cs:SECT_LEFT],AX ;save as sectors left to process

	MOV	[cs:SECT_LEFT_IN_FRAME],AX ;AN000; Save as sectors left to process

	CMP	byte [cs:EM_SW],0 ;extended memory mode?
	JNE	INOUT_EM		;jump to extended memory I/O code

;Compute offset and segment of VDISK buffer for starting segment in CX:SI

	MOV	AX,word [RH+RH4.RH4_SSN] ;starting sector number
	MUL	[cs:PARAS_PER_SECTOR] ;* length of one sector in paragraphs
	ADD	AX,[cs:START_BUFFER_PARA] ;+ segment of VDISK buffer sector 0
	MOV	CX,AX			;segment address to CX
	XOR	SI,SI			;offset is zero

;Compute address of caller's Data Transfer Addr in DX:AX with smallest offset,
;so that there is no possibility of overflowing a 64KB boundary moving MAX_CNT
;sectors.

	MOV	AX,PARA_SIZE		;16
	MUL	word [RH+RH4.RH4_DTAS] ;* segment of caller's DTA in DX,AX
	ADD	AX,word [RH+RH4.RH4_DTAO] ;+ offset of caller's DTA
	ADC	DL,0			;carry in from addition
	DIV	[cs:WPARA_SIZE] ;AX is segment of caller's DTA
					;DX is smallest offset possible
					;AX:DX = DTA address

;AX:DX is caller's DTA segment:offset, CX:SI is VDISK buffer segment:offset

;If this is an OUTPUT request, exchange the source and target addresses

	CMP	byte [RH+RHC.RHC_CMD],CMD_INPUT ;INPUT operation?
	JE	INOUT_B 		;jump if INPUT operation

	XCHG	AX,CX			;swap source and target segment
	XCHG	DX,SI			;swap source and target offset

INOUT_B:				;CX:SI is source, AX:DX is target
	MOV	[cs:IO_SRCS],CX ;save source segment
	MOV	[cs:IO_SRCO],SI ;save source offset
	MOV	[cs:IO_TGTS],AX ;save target segment
	MOV	[cs:IO_TGTO],DX ;save target offset

	JMP	SHORT INOUT_E		;AX := SECT_LEFT, test for zero
INOUT_C:				;SECT_LEFT in AX, non-zero

;  Compute number of sectors to transfer in a single move,
;  AX = minimum of (SECT_LEFT, MAX_CNT)

;  MAX_CNT is the maximum number of sectors that can be moved without
;  spanning a 64KB boundary (0FFFFH / Sector size, remainder truncated)

	MOV	CX,[cs:MAX_CNT] ;MAX sectors with one move
	CMP	AX,CX			;if SECT_LEFT cannot span 64KB boundary
	JBE	INOUT_D 		;then move SECT_LEFT sectors

	MOV	AX,CX			;else move MAX_CNT sectors
INOUT_D:

	CALL	INOUT_D_LOW_MEM 	;AN000;LOW MEMORY TRANSFER

;Determine if more sectors need to be transferred

INOUT_E:				;do while SECT_LEFT <> zero
	MOV	AX,[cs:SECT_LEFT] ;get sectors left to transfer
	OR	AX,AX			;set flags
	JNZ	INOUT_C 		;go back to transfer some sectors
	RET				;AX = zero, all sectors transferred

	SUBTTL	Extended Memory I/O routine
	PAGE
;-----------------------------------------------------------------------;
;	Extended Memory I/O routine					;
;-----------------------------------------------------------------------;
INOUT_EM:				;Extended memory I/O routine
					;change to larger stack
	MOV	SI,SS			;save old SS in SI
	MOV	DX,SP			;save old SP in DX
	CLI				;disable interrupts
	MOV	AX,CS
	MOV	SS,AX			;set SS = CS
	MOV	SP,EM_STACK        ;point to new stack
	STI				;enable interrupts
	PUSH	SI			;save old SS at top of new stack
	PUSH	DX			;save old SP on new stack

	MOV	SI,word [RH+RH4.RH4_DTAO] ;caller's DTA offset


	CMP	byte [cs:EM_SW],EM_Mem ;AC005; Is EM requested?
	JE	INOUT_EM_A		;AN000;
	JMP	INOUT_EMS		;AN000; Yes, compute page

INOUT_EM_A:				;AN000; No, compute 24-bit address

;Compute 24-bit address of VDISK sector in CX (hi) and SI (low)

	MOV	AX,word [RH+RH4.RH4_SSN] ;starting sector number
	MUL	[cs:BPB_SSZ] ;* sector size = offset within buffer
	ADD	AX,[cs:START_EM_LO] ;+ base address of this VDISK buffer
	ADC	DL,[cs:START_EM_HI]
	MOV	CX,DX			;save high byte
	MOV	SI,AX			;save low word

;Compute 24-bit address of caller's DTA in DX (hi) and AX (low)

	MOV	AX,PARA_SIZE		;16
	MUL	word [RH+RH4.RH4_DTAS] ;* segment of caller's DTA
	ADD	AX,word [RH+RH4.RH4_DTAO] ;+ offset of caller's DTA
	ADC	DL,0			;carry in from addition

;Caller's DTA address is in CX,SI, VDISK buffer address is in DX,AX.

;If this is an OUTPUT request, exchange the source and target addresses

	CMP	byte [RH+RHC.RHC_CMD],CMD_INPUT ;INPUT operation?
	JE	INOUT_EM_B		;jump if INPUT operation

	XCHG	DX,CX			;swap source and target high byte
	XCHG	AX,SI			;swap source and target low word

INOUT_EM_B:				;CX,SI is source, DX,AX is target

	MOV	[cs:SRC.DESC_BASEL],SI ;low 16 bits of source address
	MOV	[cs:SRC.DESC_BASEH],CL ;high 8 bits of source address

	MOV	[cs:TGT.DESC_BASEL],AX ;low 16 bits of target address
	MOV	[cs:TGT.DESC_BASEH],DL ;high 8 bits of target address

	JMP	SHORT INOUT_EM_E	;AX := SECT_LEFT, test for zero
INOUT_EM_C:				;SECT_LEFT in AX, non-zero

;  Compute number of sectors to transfer in a single move,
;  AX = minimum of (SECT_LEFT, MAX_CNT)

;  MAX_CNT is the maximum number of sectors that can be moved without
;  spanning a 64KB boundary (0FFFFH / Sector size, remainder truncated)

	MOV	CX,[cs:MAX_CNT] ;MAX sectors with one move
	CMP	AX,CX			;if SECT_LEFT cannot span 64KB boundary
	JBE	INOUT_EM_D		;then move SECT_LEFT sectors

	MOV	AX,CX			;else move MAX_CNT sectors
INOUT_EM_D:
	SUB	[cs:SECT_LEFT],AX ;reduce number of sectors left to move

;Move AX sectors from source to target

	MUL	[cs:BPB_SSZ] ;sectors * sector size = byte count
					;(cannot overflow into DX)
	MOV	[cs:TGT.DESC_LMT],AX ;store segment limit (byte count)
	MOV	[cs:SRC.DESC_LMT],AX

	PUSH	AX			;preserve byte count on stack

	SHR	AX,1			;/2 = word count
	MOV	CX,AX			;word count to CX

	PUSH	CS
	POP	ES			;set ES = CS
	MOV	SI,GDT         ;ES:SI point to GDT

	MOV	AH,EM_BLKMOVE		;function is block move
	INT	EM_INT			;move an even number of words

	POP	CX			;get byte count back from stack

	OR	AH,AH			;get error code

	JZ	INOUT_UPDATE		;
	JMP	INOUT_EM_XE		;jump if I/O error encountered

INOUT_UPDATE:

;Update source and target addresses

	ADD	[cs:SRC.DESC_BASEL],CX ;add bytes moved to source
	ADC	[cs:SRC.DESC_BASEH],0 ;pick up any carry

	ADD	[cs:TGT.DESC_BASEL],CX ;add bytes moved to target
	ADC	[cs:TGT.DESC_BASEH],0 ;pick up any carry

;Determine if more sectors need to be transferred

INOUT_EM_E:				;do while SECT_LEFT <> zero
	MOV	AX,[cs:SECT_LEFT] ;get sectors left to transfer
	OR	AX,AX			;set flags
	JNZ	INOUT_EM_C		;go back to transfer some sectors

	JMP	INOUT_EM_X2		;AN000; All done . . . exit
;-----------------------------------------------------------------------;
;	EMS Support				  ;RPS; 		;
;-----------------------------------------------------------------------;

INOUT_EMS:				;AN000;

; Save EMS state in case anyone is using it
	PUSH	AX			;AN000; DMS;SAVE IT
	PUSH	BX			;AN000; DMS;SAVE IT
	PUSH	DX			;AN000; DMS;SAVE IT
	push	di			;an000; dms;save it
	push	si			;an000; dms;save it
	push	ds			;an000; dms;save it
	push	es			;an000; dms;save it
	mov	ax,cs			;an000; dms;transfer cs to ds/es
	mov	ds,ax			;an000; dms;
	mov	es,ax			;an000; dms;

	mov	di,EMS_SAVE_ARRAY        ;an000; point to save area
	mov	si,EMS_SEG_ARRAY        ;an000; point to segment area
	mov	word [cs:EMS_SEG_ARRAY],0001h   ;an000; 1 segment to save
	mov	ax,[cs:EMS_FRAME_ADDR] ;an000; get segment
	mov	word [cs:EMS_SEG_ARRAY+2],ax   ;an000; segment
	MOV	AX,EMS_SAVE_STATE	;AN000; Function code to save active handle state
	INT	EMS_INT 		;AN000;

	pop	es			;an000; dms;restore
	pop	ds			;an000; dms;restore
	pop	si			;an000; dms;restore
	pop	di			;an000; dms;restore
	POP	DX			;AN000; DMS;RESTORE
	POP	BX			;AN000; DMS;RESTORE
	POP	AX			;AN000; DMS;RESTORE

; Compute offset and segment of VDISK frame for starting segment in CX:SI
; and page containing VDISK starting sector

	push	ds			;an000; dms;save ds
	push	es			;an000; dms;save es

	mov	word [cs:CURR_DTA_OFF],0 ;an000; dms;current offset = 0
	mov	ax,word [RH+RH4.RH4_SSN] ;an000; dms;get 1st. sector
	mov	[cs:EMS_CURR_SECT],ax ;an000; dms;save it
	call	ems_page_off_calc	;an000; dms;calc page and off.
	call	ems_dta_calc		;an000; dms;calc DTA
	call	ems_src_tgt		;an000; dms;get src & tgt

;	do$				;an000; dms;while sectors left
DO4$$:
	    call    MAP_FRAME		;an000; dms;map a page
	    call    ems_trf		;an000; dms;transfer data
	    dec     word [cs:SECT_LEFT] ;an000; dms;sect_left - 1
	    cmp     word [cs:SECT_LEFT],0 ;an000; dms;continue?
;	leave$	e			;an000; dms;no - exit
	JE EN4$$
					;	    yes - continue
	    mov     ax,[cs:EMS_CURR_SECT] ;an000; dms;get current sector
	    call    ems_page_off_calc	;an000; dms;calc page and off.
	    call    ems_dta_adj 	;an000; dms;adjust DTA
	    call    ems_src_tgt 	;an000; dms;get src & tgt
;	enddo$				;an000; dms;end while
	JMP SHORT DO4$$
EN4$$:

	pop	es			;an000; dms;restore es
	pop	ds			;an000; dms;restore ds

; Restore EMS state in case anyone was using it
					;AN000; No,
	PUSH	AX			;AN000; DMS;SAVE IT
	PUSH	BX			;AN000; DMS;SAVE IT
	PUSH	DX			;AN000; DMS;SAVE IT
	PUSH	SI			;AN000; DMS;SAVE IT
	push	ds			;an000; dms;save it

	mov	ax,cs			;an000; dms;get cs
	mov	ds,ax			;an000; dms;put in ds
	MOV	AX,EMS_RESTORE_STATE	;AN000;   Function code to restore active handle state
	MOV	SI,EMS_SAVE_ARRAY        ;AN000; POINT TO SAVE ARRAY
	INT	EMS_INT 		;AN000;

	pop	ds			;an000; dms;restore
	POP	SI			;AN000; DMS;RESTORE
	POP	DX			;AN000; DMS;RESTORE
	POP	BX			;AN000; DMS;RESTORE
	POP	AX			;AN000; DMS;RESTORE

;-----------------------------------------------------------------------;

INOUT_EM_X2:				;revert to original stack
	POP	DI			;get old SP
	POP	SI			;get old SS
	CLI				;disable interrupts
	MOV	SS,SI			;restore old SS
	MOV	SP,DI			;restore old SP
	STI				;enable interrupts
	RET				;return to IRPT_EXIT

INOUT_EM_XE:				;some error with INT 15H
	MOV	[cs:EM_STAT],AX ;save error status for debugging
	MOV	word [RH+RH4.RH4_CNT],0 ;indicate no sectors transferred
	MOV	AX,STAT_CRC		;indicate CRC error
	JMP	INOUT_EM_X2		;fix stack and exit
;INOUT	ENDP


;=========================================================================
; EMS_PAGE_OFF_CALC	: Calculates the current ems page to use and
;			  the offset of the requested sector in that
;			  page.
;
;	Inputs: 	AX - Sector for input/output
;			SECT_PER_PAGE - # of sectors/ems page
;			BPB_SSZ - Size in bytes of a sector
;			EMS_FRAME_ADDR - Segment of ems page
;
;	Outputs:	CURR_EMS_PAGE - Currently active ems page
;			CX:SI - Segment:Offset of logical sector
;=========================================================================

ems_page_off_calc:           ;an000; dms;calc page/offset

	xor	dx,dx			;an002; dms;clear high word
	div	[cs:SECT_PER_PAGE] ;an000; dms;determine page
	mov	[cs:CURR_EMS_PAGE],ax ;an002; dms;save page
	mov	ax,dx			;an002; dms;offset calc
	mul	[cs:BPB_SSZ] ;an000; dms;calc offset
	mov	si,ax			;an000; dms;save sector offset
	mov	cx,[cs:EMS_FRAME_ADDR] ;an000; dms;obtain sector seg

	ret				;an000; dms;

;ems_page_off_calc endp			;an000; dms;


;=========================================================================
; EMS_DTA_CALC		: Calculate the DTA buffer to be used.
;
;	Inputs: 	PARA_SIZE - 16
;			RH4_DTAS  - Segment of DTA from request packet
;			RH4_DTA0  - Offset of DTA from request packet
;			WPARA_SIZE- 16
;
;	Outputs:	AX:DX - Segment:Offset of DTA buffer
;=========================================================================

ems_dta_calc:            ;an000; dms;calc DTA buffer

	xor	dx,dx			;an002; dms;clear high word
	mov	ax,PARA_SIZE		;an000; dms;get para size
	mul	word [RH+RH4.RH4_DTAS] ;an000; dms;times DTA segment
	add	ax,word [RH+RH4.RH4_DTAO] ;an000; dms;+ DTA offset
	adc	dx,0			;an002; dms;pick up carry
	div	[cs:WPARA_SIZE] ;an000; dms;/16

	ret				;an000; dms;

;ems_dta_calc endp			;an000; dms;


;=========================================================================
; EMS_DTA_ADJ		: Adjust DTA for the number of sectors having
;			  been transferred.
;
;	External Calls	: EMS_DTA_CALC
;
;	Inputs: 	CURR_DTA_OFF - Current offset value to be adjusted.
;
;	Outputs:	CURR_DTA_OFF - Adjusted offset value into DTA
;			DX - Adjusted offset value into DTA
;=========================================================================

ems_dta_adj:            ;an000; dms;adjust DTA

	call	ems_dta_calc		;an000; dms;
	push	ax			;an000; dms;save reg
	mov	ax,[cs:CURR_DTA_OFF] ;an000; dms;get current off.
	add	ax,[cs:BPB_SSZ] ;an000; dms;adjust up
	mov	[cs:CURR_DTA_OFF],ax ;an000; dms;save new off
	add	dx,ax			;an000; dms;set dx to new off
	pop	ax			;an000; dms;restore reg
	ret				;an000; dms;

;ems_dta_adj endp			;an000; dms;

;=========================================================================
; EMS_SRC_TGT		: Determine the source and target segments for
;			  data transfer.
;
;	Inputs: 	RHC_CMD - Request packet command identifier
;			AX:DX	- DTA
;			CX:SI	- EMS page/sector
;
;	Outputs:	IO_SRCS - Segment of source of trf
;			IO_SRCO - Offset of source of trf
;			IO_TGTS - Segment of target for trf
;			IO_TGTO - Offset of target for trf
;=========================================================================

ems_src_tgt:            ;an000; dms;src/tgt calc

	cmp	byte [RH+RHC.RHC_CMD],CMD_INPUT ;an000; dms;input/output?
;	if$	ne			;an000; dms;
	JE IF7$$
	    xchg    ax,cx		;an000; dms;swap src/tgt seg
	    xchg    dx,si		;an000; dms;swap src/tgt off
;	endif$				;an000; dms;
IF7$$:

	mov	[cs:IO_SRCS],cx ;an000; dms;save src seg
	mov	[cs:IO_SRCO],si ;an000; dms;save src off
	mov	[cs:IO_TGTS],ax ;an000; dms;save tgt seg
	mov	[cs:IO_TGTO],dx ;an000; dms;save tgt off
	ret				;an000; dms;

;ems_src_tgt endp			;an000; dms;


;=========================================================================
; EMS_TRF		: Perform the sector transfer of data.
;
;	Inputs: 	BPB_SSZ - Sector size
;			IO_SRCA - Source address
;			IO_TGTA - Target address
;
;	Outputs:	Transferred data
;			EMS_CURR_SECT - Incremented 1
;=========================================================================

ems_trf:            ;an000; dms;transfer data

	mov	ax,[cs:BPB_SSZ] ;an000; dms;set to sector size
	shr	ax,1			;an000; dms;make words
	mov	cx,ax			;an000; dms;set loop counter
	push	ds			;an000; dms;save regs
	push	es			;an000; dms;

	lds	si,[cs:IO_SRCA] ;an000; dms;get src address
	les	di,[cs:IO_TGTA] ;an000; dms;get tgt address

	CMP	byte [cs:PC_386],TRUE ;AN000; DO WE HAVE A 386 MACHINE?
;	IF$	E			;AN000; YES
	JNE IF9$$
	    SHR     CX,1		;AN000; /2 = DW COUNT
	    DB	    66H 		;AN000; SIMULATE A MOVSDW
;	ENDIF$				;AN000;
IF9$$:
	rep	movsw			;an000; dms;perform transfer

	pop	es			;an000; dms;restore regs
	pop	ds			;an000; dms;
	inc	word [cs:EMS_CURR_SECT] ;an000; dms;increment sector

	ret				;an000; dms;

;ems_trf endp				;an000; dms;



MAP_FRAME:            ;AN000;

	PUSH	BX			;AN000; DMS;
	mov	ax,[cs:DOS_Page] ;an000; get physical page
	MOV	AH,EMS_MAP_HANDLE	;AN000; EMS function to map page
	MOV	BX,[cs:CURR_EMS_PAGE] ;AN000; Page number
	MOV	DX,[cs:EMS_HANDLE] ;AN000; EMS handle
	INT	EMS_INT 		;AN000;
	POP	BX			;AN000; DMS;
	RET				;AN000;

;MAP_FRAME ENDP				;AN000;


INOUT_D_LOW_MEM:           ;AN000; LOW MEMORY TRANSFER

	SUB	[cs:SECT_LEFT],AX ;reduce number of sectors left to move

;Move AX sectors from source to target

	MUL	[cs:BPB_SSZ] ;sectors * sector size = byte count
					;(cannot overflow into DX)
	SHR	AX,1			;/2 = word count
	MOV	CX,AX			;word count to CX for \REP MOVSW

	LDS	SI,[cs:IO_SRCA] ;source segment/offset to DS:SI
	LES	DI,[cs:IO_TGTA] ;target segment/offset to ES:DI

	CMP	byte [cs:PC_386],TRUE ;AN000; DO WE HAVE A 386 MACHINE?
;	IF$	E			;AN000; YES
	JNE IF11$$
	    SHR     CX,1		;AN000; /2 = DW COUNT
	    DB	    66H 		;AN000; SIMULATE A MOVSDW
;	ENDIF$				;AN000;
IF11$$:
	REP	MOVSW			;AN000; PERFORM DOUBLE WORD MOVE

;Update source and target paragraph addresses
;AX has number of words moved

	SHR	AX,1			;words moved / 8 = paragraphs moved
	SHR	AX,1
	SHR	AX,1

	ADD	[cs:IO_SRCS],AX ;add paragraphs moved to source segment
	ADD	[cs:IO_TGTS],AX ;add paragraphs moved to target segment

	RET

;INOUT_D_LOW_MEM ENDP



	rw      40     ;stack for extended memory I/O
label EM_STACK word

	SUBTTL	Boot Record
	PAGE
;-----------------------------------------------------------------------;
;	Adjust the assembly-time instruction counter to a paragraph	;
;	boundary							;
;-----------------------------------------------------------------------;

	IF	($-START) MOD 16
	    times (($-START) + 16 - (($-START) MOD 16)) - $ db 0
	end if

VDISK	=	$			;start of virtual disk buffer
VDISKP	=	(($-START) / PARA_SIZE)	;length of program in paragraphs
;-----------------------------------------------------------------------;
;	If this VDISK is in extended memory, this address is passed	;
;	back to DOS as the end address that is to remain resident.	;
;									;
;	It this VDISK is not in extended memory, the VDISK buffer	;
;	begins at this address, and the address passed back to DOS	;
;	as the end address that is to remain resident is this address	;
;	plus the length of the VDISK buffer.				;
;-----------------------------------------------------------------------;

label BOOT_RECORD byte   ;Format of Boot Record documented in
					;DOS Technical Reference Manual
	DB	0,0,0			;3-byte jump to boot code (not bootable)
	DB	'VDISKx.x'		;8-byte vendor identification
label BOOT_BPB byte   ;boot record copy of BIOS parameter block
	DW	?			;number of bytes per disk sector
	DB	?			;sectors per allocation unit
	DW	?			;number of reserved sectors (for boot record)
	DB	?			;number of File Allocation Table (FAT) copies
	DW	?			;number of root directory entries
	DW	?			;total number of sectors
	DB	?			;media descriptor byte
	DW	?			;number of sectors occupied by a single FAT
;end of boot record BIOS Parameter block

;The following three words mean nothing to VDISK, they are placed here
;to conform to the DOS standard for boot records.
	DW	8			;sectors per track
	DW	1			;number of heads
	DW	0			;number of hidden sectors
;The following word is the 16-bit kilobyte address of the first byte in
;extended memory that is not occupied by a VDISK buffer
;It is placed into this location so that other users of extended memory
;may find where all the VDISKs end.

;This field may be accessed by moving the boot record of the First extended
;memory VDISK from absolute location 10 0000H.	Before assuming that the
;value below is valid, the vendor ID (constant VDISK) should be verified
;to make sure that SOME VDISK has been installed.

;For example, if two VDISKs are installed, one 320KB and one 64KB, the
;address calculations are as follows:

;Extended memory start address	= 100000H (1024KB)
;Start addr of 1st VDISK buffer = 100000H (1024KB)
;Length of 1st VDISK buffer	= 050000H ( 320KB)
;End addr of 1st VDISK buffer	= 14FFFFH
;Start addr of 2nd VDISK buffer = 150000H (1344KB)
;Length of 2nd VDISK buffer	= 010000H (  64KB)
;End addr of 2nd VDISK buffer	= 15FFFFH
;First byte after all VDISKs	= 160000H (1408KB)
;Divide by 1024 		=   0580H (1408D)

;-----------------------------------------------------------------------;
;	Part 2 of Initialization (executed last)			;
;-----------------------------------------------------------------------;
;Initialization is divided into two parts.

;INIT_P1 is overlaid by the virtual disk buffer

;INIT_P1 is executed first, then jumps to INIT_P2.  INIT_P2 returns to caller.

;Exercise caution if extending the initialization part 2 code.
;It overlays the area immediately following the boot sector.
;If this section of code must be expanded, make sure it fits into the minimum
;sector size of 128 bytes.
;Label TEST_LENGTH must equate to a non-negative value (TEST_LENGTH >= 0).
;If this code it must be extended beyond the 128 byte length of the boot sector,
;move all of INIT_P2 before label VDISK.

;Registers at entry to INIT_P2 (set up at end of INIT_P1):
;	BL = media control byte from BPB (for FAT)
;	CX = number of FAT copies
;	DX = number of bytes in one FAT - 3
;	SI = OFFSET of Volume Label field
;	ES:DI = VDISK buffer address of first FAT sector
;	CS = DS = VDISK code segment

INIT_P2:        ;second part of initialization
;	ASSUME	DS:CSEG 		;DS set in INIT_P1

;Initialize File Allocation Table(s) (FATs)

INIT_P2_FAT:				;set up one FAT, sector number in AX

	PUSH	CX			;save loop counter on stack
	MOV	AL,BL			;media control byte
	STOSB				;store media control byte, increment DI
	MOV	AX,0FFFFH		;bytes 2 and 3 of FAT are 0FFH
	STOSW

	MOV	CX,DX			;FAT size in bytes - 3
	XOR	AX,AX			;value to store in remainder of FAT
	REP	STOSB			;clear remainder of FAT

	POP	CX			;get loop counter off stack
	LOOP	INIT_P2_FAT		;loop for all copies of the FAT

;Put the volume label in the first directory entry

	MOV	CX,VOL_LABEL_LEN	;length of volume directory entry
	REP	MOVSB			;move volume id to directory

;Zero the remainder of the directory

	MOV	AX,DIR_ENTRY_SIZE	;length of 1 directory entry
	MUL	[BPB_DIRN] ;* number entries = bytes of directory
	SUB	AX,VOL_LABEL_LEN	;less length of volume label
	MOV	CX,AX			;length of rest of directory
	XOR	AX,AX
	REP	STOSB			;clear directory to nulls
	RET				;return with AX=0
;INIT_P2 ENDP

PATCH_AREA DB	5 DUP ('PATCH AREA ')
TEST_LENGTH = (128-($-VDISK))	;if negative, boot record has too much
					;data area, move some fields below VDISK
;-----------------------------------------------------------------------;
;	All fields that must remain resident after device driver	;
;	initialization must be defined before this point.		;
;-----------------------------------------------------------------------;
	DB	'                         '
	DB	'                            '
	DB	'                            '

MAXSEC_TRF DW	0			;maximum number of sectors to transfer when
					;in extended memory

BUFF_SIZE DW	0			;desired VDISK buffer size in kilobytes

MIN_MEMORY_LEFT DW 100			;minimum amount of system memory (kilobytes)
					;that must remain after VDISK is installed

PARA_PER_KB DW	1024/PARA_SIZE		;paragraphs in one kilobyte
C1024	DW	1024			;bytes in one kilobyte
DIRE_SIZE DW	DIR_ENTRY_SIZE		;bytes in one directory entry
DIR_SECTORS rw      1 ;number of sectors of directory

ERR_FLAG DB	0			;error indicators to condition messages
ERR_BSIZE EQU	80H			;buffer size adjusted
ERR_SSZ EQU	40H			;sector size adjusted
ERR_DIRN EQU	20H			;number of directory entries adjusted
ERR_PASS EQU	10H			;some adjustment made that requires
					;recomputation of values previously computed
ERR_SSZB equ	(ERR_SSZ+ERR_PASS)	;sector size altered this pass
ERR_SYSSZ EQU	08H			;system storage too small for VDISK
ERR_SWTCH EQU	04H			;invalid switch character
ERR_EXTSW EQU	02H			;extender card switches don't match memory size
ERR_ESIZE EQU	01H			;Transfer size adjusted

DOS_PG_SZ DB	DOS_PAGE_SZ		;AN000;
DOS_Page_Size_Word dw DOS_PAGE_SZ	;an000;

err_flag2 db	0
err_baddos equ	01h			; Invalid DOS Version

;-----------------------------------------------------------------------;
;	SUBLIST definitions and EQUATES for Message Retreiver		;
;-----------------------------------------------------------------------;
					;AN000; Message Number
INCORRECT_DOS EQU 1			;AN000;
SYS_TOO_SMALL EQU 2			;AN000;
VDISK_TITLE EQU 3			;AN000;
BUFFER_ADJUSTED EQU 4			;AN000;
SECTOR_ADJUSTED EQU 5			;AN000;
DIR_ADJUSTED EQU 6			;AN000;
INVALID_SW_CHAR EQU 7			;AN000;
TRANS_ADJUSTED EQU 8			;AN000;
BUF_SZ	EQU	9			;AN000;
SEC_SZ	EQU	10			;AN000;
DIR_ENTRIES EQU 11			;AN000;
TRANS_SZ EQU	12			;AN000;
VDISK_NOT_INST EQU 13			;AN000;
EXTEND_CARD_WRONG EQU 14		;AN000;

NO_REPLACE EQU	0			;AN000; CX = 0 -> No replacement
ONE_REPLACE EQU 1			;AN000; CX = 1 -> One replacement
UNLIMITED_MAX EQU 0			;AN000; MAX field - unlimited
SMALLEST_MIN EQU 1			;AN000; MIN field - 1 character long
PAD_BLANK EQU	20H			;AN000; PAD character is a blank


DRIVE_CODE rb      1 ;AN000;
	DB	":",NULL		;AN000; ASCIIZ string for drive code

; For the message: "VDISK Version 4.00 virtual disk %1",CR,LF

label TITLE_SUBLIST byte

TT_SIZE DB	11			;AN000; SUBLIST size  (PTR to next SUBLIST)
TT_RESV DB	0			;AN000; RESERVED
TT_VALUEO DW	DRIVE_CODE		;AN000; Offset to ASCIIZ string
TT_VALUES rw      1 ;AN000; SEGMENT TO ASCIIZ STRING
TT_ID	DB	1			;AN000; n of %n
TT_FLAG DB	Left_Align+Char_Field_ASCIIZ
TT_MAXW DB	UNLIMITED_MAX		;AN000; Maximum field width
TT_MINW DB	SMALLEST_MIN		;AN000; Minimum field width
TT_PAD	DB	PAD_BLANK		;AN000; Character for Pad field

; For the message: "Buffer size: %1 KB",CR,LF

label BUF_SZ_SUBLIST byte

B_SIZE	DB	11			;AN000; SUBLIST size  (PTR to next SUBLIST)
B_RESV	DB	0			;AN000; RESERVED
B_VALUEO DW	BUFF_SIZE		;AN000; Offset to binary number
B_VALUES rw      1 ;AN000; SEGMENT TO BINARY NUMBER
B_ID	DB	1			;AN000; n of %n
B_FLAG	DB	Left_Align+Unsgn_Bin_Word
B_MAXW	DB	UNLIMITED_MAX		;AN000; Maximum field width
B_MINW	DB	SMALLEST_MIN		;AN000; Minimum field width
B_PAD	DB	PAD_BLANK		;AN000; Character for Pad field

; For the message: "Sector size: %1",CR,LF

label SEC_SZ_SUBLIST byte

S_SIZE	DB	11			;AN000; SUBLIST size  (PTR to next SUBLIST)
S_RESV	DB	0			;AN000; RESERVED
S_VALUEO DW	BPB_SSZ 		;AN000; Offset to binary number
S_VALUES rw      1 ;AN000; SEGMENT TO BINARY NUMBER
S_ID	DB	1			;AN000; n of %n
S_FLAG	DB	Left_Align+Unsgn_Bin_Word
S_MAXW	DB	UNLIMITED_MAX		;AN000; Maximum field width
S_MINW	DB	SMALLEST_MIN		;AN000; Minimum field width
S_PAD	DB	PAD_BLANK		;AN000; Character for Pad field

; For the message: "Directory entries: %1",CR,LF

label DIR_ENT_SUBLIST byte

D_SIZE	DB	11			;AN000; SUBLIST size  (PTR to next SUBLIST)
D_RESV	DB	0			;AN000; RESERVED
D_VALUEO DW	BPB_DIRN		;AN000; Offset to binary number
D_VALUES rw      1 ;AN000; SEGMENT TO BINARY NUMBER
D_ID	DB	1			;AN000; n of %n
D_FLAG	DB	Left_Align+Unsgn_Bin_Word
D_MAXW	DB	UNLIMITED_MAX		;AN000; Maximum field width
D_MINW	DB	SMALLEST_MIN		;AN000; Minimum field width
D_PAD	DB	PAD_BLANK		;AN000; Character for Pad field

; For the message: "Transfer size: %1",CR,LF

label TRANS_SZ_SUBLIST byte

T_SIZE	DB	11			;AN000; SUBLIST size  (PTR to next SUBLIST)
T_RESV	DB	0			;AN000; RESERVED
T_VALUEO DW	MAXSEC_TRF		;AN000; Offset to binary number
T_VALUES rw      1 ;AN000; SEGMENT TO BINARY NUMBER
T_ID	DB	1			;AN000; n of %n
T_FLAG	DB	Left_Align+Unsgn_Bin_Word
T_MAXW	DB	UNLIMITED_MAX		;AN000; Maximum field width
T_MINW	DB	SMALLEST_MIN		;AN000; Minimum field width
T_PAD	DB	PAD_BLANK		;AN000; Character for Pad field

;-----------------------------------------------------------------------;
;	EMS Support							;
;-----------------------------------------------------------------------;

FRAME_BUFFER DB 10 DUP(0)		;AN000;
VDISK_Name db	"VDISK   "		;an000; dms;

four	DB	4


	SUBTTL	Initialization, Part one
	PAGE
;-----------------------------------------------------------------------;
;	Command Code 0 - Initialization 				;
;	At entry, DS:BX point to request header, AX = 0 		;
;-----------------------------------------------------------------------;
;Initialization is divided into two parts.
;This part, executed first, is later overlaid by the VDISK buffer.

INIT_P1:        ;first part of initialization

;;;;;	PUSH	DS			;ICE
;;;;;	push	bx			;ICE
;;;;;	push	ax			;ICE

;;;;;	mov	bx,0140H		;ICE
;;;;;	xor	ax,ax			;ICE
;;;;;	mov	ds,ax			;ICE
;;;;;	mov	ax,word ptr ds:[bx]	;ICE
;;;;;	mov	word ptr ds:[bx],ax	;ICE

;;;;;	pop	ax			;ICE
;;;;;	pop	bx			;ICE
;;;;;	POP	DS			;ICE

	MOV	DX,SS			;save stack segment register
	MOV	CX,SP			;save stack pointer register
	CLI				;inhibit interrupts while changing SS:SP
	MOV	AX,CS			;move CS to SS through AX
	MOV	SS,AX
	MOV	SP,MSGEND        ;end of VDISKMSG
	ADD	SP,STACK_SIZE		;+ length of our stack

	STI				;allow interrupts

	PUSH	DX			;save old SS register on new stack
	PUSH	CX			;SAVE OLD SP REGISTER ON NEW STACK



	PUSH	DS			;AN000;SAVE REGS
	PUSH	ES			;AN000;

	PUSH	CS			;AN000;TRANSFER TO DS
	POP	DS			;AN000;
	PUSH	CS			;AN000;
	POP	ES			;AN000;

;	ASSUME	DS:CSEG,ES:CSEG 	;AN000;

	CALL	SYSLOADMSG		;AN000; LOAD messages and do DOS version check
	JNC	VDISK_CONTINUE_1	;AN000; Did we load OK?
	or	byte [cs:err_flag2],err_baddos

	push	ds			;an006; dms;save ds
	push	bx			;an006; dms;save bx
	lds	bx,[cs:RH_PTRA] ;an006; dms;point to request header
	mov	word [RH+RH0.RH0_FLAG],-1 ;an006; dms;signal BIO and error occurred
	pop	bx			;an006; dms;restore bx
	pop	ds			;an006; dms;restore ds

	MOV	AX,VDISK_NOT_INST	;AN000;VDISK UNABLE TO BE INSTALLED
	MOV	BX,NO_HANDLE		;AN000;NO DISPLAY HANDLE
	CALL	SYSDISPMSG		;AN000;DISPLAY THE MESSAGE
	MOV	AX,INCORRECT_DOS	;AN000;BAD DOS VERSION
	MOV	BX,NO_HANDLE		;AN000;NO DISPLAY HANDLE
	CALL	SYSDISPMSG		;AN000;DISPLAY THE MESSAGE

VDISK_CONTINUE_1:			;AN000;

	POP	ES			;AN000;RESTORE REGS
	POP	DS			;AN000;
;	ASSUME	DS:NOTHING,ES:NOTHING	;AN000;

	CALL	PC_386_CHK		;AN000;SEE IF WE HAVE A 386 PC
					; Yes, continue
	CALL	GET_PARMS		;get parameters from CONFIG.SYS line

	PUSH	CS
	POP	DS			;set DS = CS
;	ASSUME	DS:CSEG,ES:CSEG

	CALL	APPLY_DEFAULTS		;supply any values not specified
	CALL	DETERMINE_START 	;compute start address of VDISK buffer
	CALL	VALIDATE		;validate parameters
	CALL	COPY_BPB		;Copy BIOS Parameter Block to boot record

	CALL	VERIFY_EXTENDER 	;Verify that extender card switches are right

	TEST	byte [ERR_FLAG],ERR_EXTSW ;are switches wrong?
	JNZ	INIT_P1_A		;if so, exit with messages

	test	byte [cs:err_flag2],err_baddos
	jnz	INIT_P1_A

	CMP	byte [EM_SW],0 ;EXTENDED MEMORY REQUEST?
	JE	INIT_P1_A		;jump if not

	TEST	byte [ERR_FLAG],ERR_SYSSZ ;is system too small for VDISK?
	JNZ	INIT_P1_A		;if so, don't do extended memory init

	CALL	UPDATE_AVAIL		;update AVAIL_HI and AVAIL_LO to reflect
					;addition of extended memory VDISK
	CALL	FORMAT_VDISK		;construct a boot record, FATs and
					;directory in storage immediately
					;following this device driver
	CALL	MOVE_VDISK		;move formatted boot record, FATs,
					;and directory to extended memory

INIT_P1_A:
	CALL	FILL_RH 		;fill in INIT request header
	CALL	WRITE_MESSAGES		;display all messages
	POP	CX			;get old SP from stack
	POP	DX			;get old SS from stack
	CLI				;disable interrupts while changing SS:SP
	MOV	SS,DX			;restore stack segment register
	MOV	SP,CX			;restore stack pointer register
	STI				;enable interrupts
;-----------------------------------------------------------------------;
;	INIT_P2 must be short enough to fit into the boot sector	;
;	(minimum size of boot sector is 128 bytes), so we set up	;
;	as many pointers as we can to help keep INIT_P2 short.		;
;									;
;	ES:DI = storage address of first FAT sector			;
;	BL = media control byte 					;
;	CX = number of FAT copies					;
;	DX = number of bytes in one FAT, less 3 			;
;	SI = offset of VOL label field					;
;-----------------------------------------------------------------------;
	MOV	ES,[START_BUFFER_PARA] ;start paragraph of VDISK buffer

	MOV	AX,[BPB_RES] ;number of reserved sectors
	MUL	[BPB_SSZ] ;* sector size
	MOV	DI,AX			;ES:DI point to FAT start

	MOV	BL,[BPB_MCB] ;media control byte

	MOV	CL,[BPB_FATN] ;number of FAT copies
	XOR	CH,CH

	MOV	AX,[BPB_FATSZ] ;FAT size in sectors
	MUL	[BPB_SSZ] ;* sector size = total FAT bytes

	SUB	AX,3			;-3 (FEFFFF stored by code)
	MOV	DX,AX

	MOV	SI,VOL_LABEL        ;point to VOL label directory entry
	JMP	INIT_P2 		;jump to second part of initialization
					;this is redundant if the VDISK is in
					;extended memory, but is executed anyway



	SUBTTL	PC_386_CHK
	PAGE
;=========================================================================
; PC_386_CHK		: QUERIES THE BIOS TO DETERMINE WHAT TYPE OF
;			  MACHINE WE ARE ON.  WE ARE LOOKING FOR A 386.
;			  THIS WILL BE USED TO DETERMINE IF A DW MOVE
;			  IS TO BE PERFORMED.
;
;	INPUTS		: NONE
;
;	OUTPUTS 	: PC_386 - FLAG SIGNALS IF WE ARE ON A 386 MACHINE.
;=========================================================================

PC_386_CHK:            ;AN000;DETERMINE MACHINE TYPE

	PUSH	AX			;AN000;SAVE AFFECTED REGS
	PUSH	BX			;AN000;
	PUSH	ES			;AN000;

	MOV	byte [cs:PC_386],FALSE ;AN000;INITIALIZE TO FALSE

	MOV	AH,0C0H 		;AN000;RETURN SYSTEM CONFIGURATION
	INT	15H			;AN000;

;	IF$	NC			;AN000;IF A GOOD RETURN
	JC IF13$$
	    CMP     AH,0		;AN000;IS IT NEW FORMAT FOR CONFIG.
;	    IF$     E			;AN000;YES
	    JNE IF14$$
		MOV	AL,[es:BX+BIOS_SYSTEM_DESCRIPTOR.bios_SD_modelbyte] ;AN000;CHECK MODEL
		CMP	AL,0F8H 	;AN000;IS IT A 386 MACHINE?
;		IF$	E		;AN000;YES
		JNE IF15$$
		    MOV     byte [cs:PC_386],TRUE ;AN000;SIGNAL A 386
;		ENDIF$			;AN000;
IF15$$:
;	    ENDIF$			;AN000;
IF14$$:
;	ENDIF$				;AN000;
IF13$$:

	POP	ES			;AN000;RESTORE REGS.
	POP	BX			;AN000;
	POP	AX			;AN000;

	RET				;AN000;

;PC_386_CHK ENDP 			;AN000;


	SUBTTL	GET_PARMS Parameter Line Scan
	PAGE
;-----------------------------------------------------------------------;
;GET_PARMS gets the parameters from the CONFIG.SYS statement		;
;									;
;Register usage:							;
;	DS:SI indexes parameter string					;
;	AL contains character from parameter string			;
;	CX value from GET_NUMBER					;
;-----------------------------------------------------------------------;
;	ASSUME	DS:NOTHING		;DS:BX point to Request Header
GET_PARMS:        ;get parameters from CONFIG.SYS line
	PUSH	DS			;save DS
	LDS	SI,[RH+RH0_BPBA] ;DS:SI point to all after DEVICE=
					;in CONFIG.SYS line
	XOR	AL,AL			;not at end of line

;Skip until first delimiter is found.  There may be digits in the path string.

;DS:SI points to  \pathstring\VDISK.SYS nn nn nn
;The character following VDISK.SYS may have been changed to a null (00H).
;All letters have been changed to uppercase.

GET_PARMS_A:				;skip to DOS delimiter character
	CALL	GET_PCHAR		;get parameter character into AL
	JZ	Get_Parms_X_Exit	;get out if end of line encountered
	OR	AL,AL			;test for null
	JZ	GET_PARMS_C		;
	CMP	AL,' '
	JE	GET_PARMS_C		;
	CMP	AL,','
	JE	GET_PARMS_C		;
	CMP	AL,';'
	JE	GET_PARMS_C		;
	CMP	AL,'+'
	JE	GET_PARMS_C		;
	CMP	AL,'='
	JE	GET_PARMS_C		;
	CMP	AL,TAB
	JNE	GET_PARMS_A		;skip until delimiter or CR



GET_PARMS_C:
	PUSH	SI			;save to rescan
	MOV	byte [cs:EM_SW],0 ;INDICATE NO /E FOUND
	JMP	GET_SLASH		;see if current character is an slash

GET_PARMS_D:				;scan for /
	CALL	GET_PCHAR
	JZ	GET_PARMS_B		;exit if end of line

GET_SLASH:			;check for slash
	CMP	AL,'/'		;found slash?
	JNE	GET_PARMS_D	;no, continue scan

	CALL	GET_PCHAR	;get char following slash
	CMP	AL,'E'		;don't have to test for lower case E,
				;letters have been changed to upper case
	JNE	CHECK_FOR_X	;not 'E'				 ;AN005;
	CMP	byte [cs:EM_SW],'X' ;Was /X already defined?		 ;AN005;
	JE	GET_PARMS_E	;indicate invalid switch		 ;AN005;
	MOV	[cs:EM_SW],AL ;indicate /E found			 ;AN005;
	JMP	SHORT GOT_E_OR_X					 ;AN005;
									 ;AN005;
CHECK_FOR_X:								 ;AN005;
	CMP	AL,'X'		;don't have to test for lower case X,    ;AN005;
				;letters have been changed to upper case ;AN005;
	JNE	GET_PARMS_E	;not 'X'				 ;AN005;
	CMP	byte [cs:EM_SW],'E' ;Was /E already defined?		 ;AN005;
	JE	GET_PARMS_E	;indicate invalid switch		 ;AN005;
	MOV	byte [cs:EM_SW],'X' ;indicate /X found			 ;AN005;
									 ;AN005;
GOT_E_OR_X:								 ;AN005;
	CALL	GET_PCHAR	;get char following E or X		 ;AN005;
	CMP	AL,':'		;is it a delimeter ?
	JNE	GET_PARMS_D	;not a ':'


	CALL	GET_MAXSIZE	;get maximum sector size


	JMP	GET_PARMS_D	;continue forward scan

GET_PARMS_E:			;/ found, not 'E'
	OR	byte [cs:ERR_FLAG],ERR_SWTCH ;indicate invalid switch character
	JMP	GET_PARMS_D		;continue scan



GET_PARMS_B:				;now pointing to first delimiter
	POP	SI			;get pointer, used to rescan for /E
	XOR	AL,AL			;not at EOL now
	CALL	GET_PCHAR		;get first character
	CALL	SKIP_TO_DIGIT		;skip to first digit

Get_Parms_X_Exit:

	JZ	GET_PARMS_X		;found EOL, no digits remain

	CALL	GET_NUMBER		;extract digits, convert to binary
	MOV	[cs:BUFF_SIZE],CX ;store buffer size

	CALL	SKIP_TO_DIGIT		;skip to next digit
	JZ	GET_PARMS_X		;found EOL, no digits remain

	CALL	GET_NUMBER		;extract digits, convert to binary
	MOV	[cs:BPB_SSZ],CX ;store sector size

	CALL	SKIP_TO_DIGIT		;skip to next digit
	JZ	GET_PARMS_X		;found EOL, no digits remain

	CALL	GET_NUMBER		;extract digits, convert to binary
	MOV	[cs:BPB_DIRN],CX ;store number of directory entries



GET_PARMS_X:				;premature end of line
	TEST	byte [cs:ERR_FLAG],ERR_SWTCH ;was an invalid switch character found?
;	if$	nz			;yes - set flag to regular VDISK	;an000; dms;
	JZ IF19$$
					;  this is consistent with DOS 3.3
		mov	byte [cs:EM_SW],0 ;set flag to regular VDISK		;an000; dms;
;	endif$				;					;an000; dms;
IF19$$:
	POP	DS			;restore DS
	RET


GET_MAXSIZE:       ;get maximum sector size

	CALL	GET_PCHAR		;get next character
	CALL	CHECK_NUM		;is it a number ?
	JZ	GET_NEXTNUM		;yes, go get next number
	OR	byte [cs:ERR_FLAG],ERR_ESIZE ;indicate invalid sector size
	RET				;
GET_NEXTNUM:				;get next number
	CALL	GET_NUMBER		;extract digits and convert to binary
	MOV	[cs:MAXSEC_TRF],CX ;save maximum sector size to transfer
	RET
;GET_MAXSIZE ENDP



GET_PCHAR:        ;internal proc to get next character into AL
	CMP	AL,CR			;carriage return already encountered?
	JE	GET_PCHAR_X		;don't read past end of line
	CMP	AL,LF			;line feed already encountered?
	JE	GET_PCHAR_X		;don't read past end of line
	LODSB				;get char from DS:SI, increment SI
	CMP	AL,CR			;is the char a carriage return?
	JE	GET_PCHAR_X		;yes, set Z flag at end of line
	CMP	AL,LF			;no, is it a line feed?
GET_PCHAR_X:				;attempted read past end of line
	RET
;GET_PCHAR ENDP				;returns char in AL


CHECK_NUM:        ;check AL for ASCII digit
	CMP	AL,'0'			;< '0'?
	JB	CHECK_NUM_X		;exit if it is

	CMP	AL,'9'			;> '9'?
	JA	CHECK_NUM_X		;exit if it is

	CMP	AL,AL			;set Z flag to indicate numeric
CHECK_NUM_X:
	RET				;Z set if numeric, NZ if not numeric
;CHECK_NUM ENDP


SKIP_TO_DIGIT:       ;skip to first numeric character
	CALL	CHECK_NUM		;is current char a digit?
	JZ	SKIP_TO_DIGIT_X 	;if so, skip is complete

	CALL	GET_PCHAR		;get next character from line
	JNZ	SKIP_TO_DIGIT		;loop until first digit or CR or LF
	RET				;character is CR or LF

SKIP_TO_DIGIT_X:
	CMP	AL,0			;digit found, force NZ
	RET
;SKIP_TO_DIGIT ENDP

C10	DW	10
GN_ERR	rb      1 ;zero if no overflow in accumulation

GET_NUMBER:        ;convert string of digits to binary value
	XOR	CX,CX			;accumulate number in CX
	MOV	[cs:GN_ERR],CL ;no overflow yet
GET_NUMBER_A:				;accumulate next digit
	SUB	AL,'0'			;convert ASCII to binary
	CBW				;clear AH
	XCHG	AX,CX			;previous accumulation in AX, new digit in CL
	MUL	[cs:C10] ;DX:AX := AX*10
	OR	[cs:GN_ERR],DL ;set GN_ERR <> 0 if overflow
	ADD	AX,CX			;add new digit from
	XCHG	AX,CX			;number now in CX
	DEC	SI			;back up to prior entry
	MOV	AL,' '			;blank out prior entry
	MOV	[SI],AL 		;
	INC	SI			;set to current entry
	CALL	GET_PCHAR		;get next character
	CALL	CHECK_NUM		;see if it was numeric
	JZ	GET_NUMBER_A		;continue accumulating
	CMP	byte [cs:GN_ERR],0 ;did we overflow?
	JE	GET_NUMBER_B		;if not, we're done
	XOR	CX,CX			;return zero (always invalid) if overflow
GET_NUMBER_B:
	RET				;number in CX, next char in AL
;GET_NUMBER ENDP

;GET_PARMS ENDP

	SUBTTL	APPLY_DEFAULTS
	PAGE
;-----------------------------------------------------------------------;
;	APPLY_DEFAULTS supplies any parameter values that the user	;
;	failed to specify						;
;-----------------------------------------------------------------------;
;	ASSUME	DS:CSEG
APPLY_DEFAULTS:
	XOR	AX,AX
	CMP	[BUFF_SIZE],AX ;is buffer size zero?
	JNE	APPLY_DEFAULTS_A	;no, user specified something

	MOV	word [BUFF_SIZE],DFLT_BSIZE ;supply default buffer size
	OR	byte [ERR_FLAG],ERR_BSIZE ;indicate buffersize adjusted

APPLY_DEFAULTS_A:
	CMP	[BPB_SSZ],AX ;is sector size zero?
	JNE	APPLY_DEFAULTS_B	;no, user specified something

	MOV	word [BPB_SSZ],DFLT_SSZ ;supply default sector size
	OR	byte [ERR_FLAG],ERR_SSZ ;indicate sector size adjusted

APPLY_DEFAULTS_B:
	CMP	[BPB_DIRN],AX ;are directory entries zero?
	JNE	APPLY_DEFAULTS_C	;no, user specified something

	MOV	word [BPB_DIRN],DFLT_DIRN ;supply default directory entries
	OR	byte [ERR_FLAG],ERR_DIRN ;indicate directory entries adjusted

APPLY_DEFAULTS_C:			;
	CMP	byte [EM_SW],0 ;EXTENDED MEMORY
	JE	APPLY_DEFAULTS_D	;no, jump around
	CMP	[MAXSEC_TRF],AX ;is maximum sectors zero?
	JNE	APPLY_DEFAULTS_D	;no, user specified something

	MOV	word [MAXSEC_TRF],DFLT_ESS ;supply default maximum number of
					;sector to transfer
	OR	byte [ERR_FLAG],ERR_ESIZE ;indicate transfer size adjusted
APPLY_DEFAULTS_D:
	RET
;APPLY_DEFAULTS ENDP

	SUBTTL	DETERMINE_START address of VDISK buffer
	PAGE
;-----------------------------------------------------------------------;
;	DETERMINE_START figures out the starting address of the VDISK	;
;	buffer								;
;-----------------------------------------------------------------------;
;	ASSUME	DS:CSEG
DETERMINE_START:

;If extended memory is NOT being used, the VDISK buffer immediately
;follows the resident code.

;If extended memory IS being used, START_BUFFER_PARA becomes the
;end of device driver address passed back to DOS.

	MOV	AX,CS			;start para of VDISK code
	ADD	AX,VDISKP		;+ length of resident code
	MOV	[START_BUFFER_PARA],AX ;save as buffer start para

	CMP	byte [EM_SW],0 ;IS EXTENDED MEMORY REQUESTED?
	JE	DETERMINE_START_X	;if not, we're done here

;-----------------------------------------------------------------------;AN000;
;If EMS is not installed, the calculation to determine the starting address
;of the VDISK will remain the same.

;If EMS is installed we really don't need this calculation, the EMM will
;manage the expanded memory insuring mutiple VDISKs may reside concurrently.
;-----------------------------------------------------------------------;AN000;

	cmp	byte [EM_SW],EMS_Mem ;EMS requested? 			;an005; dms;
	je	DETERMINE_START_X	;yes - leave routine			;an005; dms;
					;no  - continue routine

	clc				;an001; dms;clear carry for INT
	MOV	AX,EM_MEMSIZE		;an001; dms; get EM memory size
	INT	EM_INT			;an001; dms; INT 15h
	JC	DETERMINE_START_X	;an001; dms; no extended memory installed
	or	ax,ax			;an001; dms;see if memory returned
	jz	DETERMINE_START_X	;an001; dms;signal no memory

	xor	dx,dx			;an001; dms;clear dx
	sub	ax,[cs:BUFF_SIZE] ;an001; dms;get starting KB location
	jc	DETERMINE_START_X	;an001; dms;buffer too large

	mov	[cs:EM_New_Size],ax ;an001; dms;save new size of EM for later use
	mul	[C1024] ;an001; dms;get total byte count
	add	ax,[cs:AVAIL_LO] ;an001; dms;add in low word of EM start
	adc	dl,[cs:AVAIL_HI] ;an001; dms;add in high word of EM start

	mov	[cs:AVAIL_LO],ax ;an001; dms;save new low beginning word
	mov	[cs:AVAIL_HI],dl ;an001; dms;save new high beginning word

	mov	[cs:START_EM_LO],ax ;an001; dms;load in new beginning word
	mov	[cs:START_EM_HI],dl ;an001; dms;load in new beginning byte

DETERMINE_START_X:

	RET
;DETERMINE_START ENDP

	SUBTTL	VALIDATE parameters
	PAGE
;-----------------------------------------------------------------------;
;	VALIDATE adjusts parameters as necessary			;
;-----------------------------------------------------------------------;
label VAL_SSZ_TBL word   ;table of valid sector sizes
VAL_SSZ_S DW	128			;smallest valid sector size
	DW	256
VAL_SSZ_L DW	512			;largest valid sector size
VAL_SSZ_N =	(($-VAL_SSZ_TBL)/2)	;number of table entries

;	ASSUME	DS:CSEG
VALIDATE:        ;validate parameters
;;ice	PUSH	DS			;ICE
;;ice	push	bx			;ICE
;;ice	push	ax			;ICE

;;ice	mov	bx,0140H		;ICE
;;ice	xor	ax,ax			;ICE
;;ice	mov	ds,ax			;ICE
;;ice	mov	ax,word ptr ds:[bx]	;ICE
;;ice	mov	word ptr ds:[bx],ax	;ICE

;;ice	pop	ax			;ICE
;;ice	pop	bx			;ICE
;;ice	POP	DS			;ICE
	MOV	byte [BPB_AUSZ],1 ;initial allocation unit is 1 sector

	CALL	VAL_BSIZE		;validate buffer size

	CALL	VAL_SSZ 		;validate (adjust if necessary) BPB_SSZ

VALIDATE_A:
	AND	byte [ERR_FLAG],255-ERR_PASS ;indicate nothing changed this pass

	MOV	AX,[BPB_SSZ] ;sector size
	CWD				;clear DX for division
	DIV	[WPARA_SIZE] ;sector size/para size
	MOV	[PARAS_PER_SECTOR],AX ;number of paragraphs/sector

	mov	ax,EMS_Page_Size	;an002; dms;EMS page size
	xor	dx,dx			;an002; dms;clear high word
	div	[BPB_SSZ] ;an002; dms;get sectors/page
	mov	[SECT_PER_PAGE],ax ;an002; dms;save sectors/page

;;;;;	MOV	AX,BPB_SSZ		;AN000; Sector size
;;;;;	xor	dx,dx			;an001; clear high word
;;;;;	DIV	DOS_Page_Size_Word	;an001; Sector size/page size
;;;;;	MOV	SECT_PER_PAGE,AX	;an001; Number of sectors/page

	MOV	AX,[BUFF_SIZE] ;requested buffersize in KB
	MUL	[C1024] ;DX:AX = buffer size in bytes
	DIV	[BPB_SSZ] ;/sector size = # sectors
	MOV	[BPB_SECN],AX ;store number of sectors

	CALL	VAL_DIRN		;validate number of directory entries

	TEST	byte [ERR_FLAG],ERR_PASS ;may have reset sector size
	JNZ	VALIDATE_A		;recompute directory & FAT sizes

	CALL	VAL_FAT 		;compute FAT entries, validity test

	TEST	byte [ERR_FLAG],ERR_PASS ;if cluster size altered this pass
	JNZ	VALIDATE_A		;recompute directory & FAT sizes

;Make certain buffer size is large enough to contain:
;	boot sector(s)
;	FAT sector(s)
;	directory sector(s)
;	at least 1 data cluster

	MOV	AL,[BPB_FATN] ;number of FAT copies
	CBW				;clear AH
	MUL	[BPB_FATSZ] ;* sectors for 1 FAT = FAT sectors
	ADD	AX,[BPB_RES] ;+ reserved sectors
	ADD	AX,[DIR_SECTORS] ;+ directory sectors
	MOV	CL,[BPB_AUSZ] ;get sectors/cluster
	XOR	CH,CH			;CX = sectors in one cluster
	ADD	AX,CX			;+ one data cluster
	CMP	[BPB_SECN],AX ;compare with sectors available
	JAE	VALIDATE_X		;jump if enough sectors

	CMP	word [DIR_SECTORS],1 ;down to 1 directory sector?
	JBE	VALIDATE_C		;can't let it go below 1

	MOV	AX,[BPB_SSZ] ;sector size
	CWD				;clear DX for division
	DIV	[DIRE_SIZE] ;sectorsize/dir entry size = entries/sector
	SUB	[BPB_DIRN],AX ;reduce directory entries by 1 sector

	OR	byte [ERR_FLAG],ERR_DIRN ;indicate directory entries adjusted
	JMP	VALIDATE_A		;retry with new directory entries number

VALIDATE_C:				;not enough space for any VDISK
	OR	byte [ERR_FLAG],ERR_SYSSZ
VALIDATE_X:
	RET

	SUBTTL	VAL_BSIZE Validate buffer size
	PAGE
;-----------------------------------------------------------------------;
;	VAL_BSIZE adjusts the buffer size as necessary			;
;-----------------------------------------------------------------------;
VAL_BSIZE:
	CALL	GET_MSIZE		;determine memory available to VDISK
					;returns available KB in AX
	OR	AX,AX			;is any memory available at all?
	JNZ	VAL_BSIZE_B		;yes, continue

	OR	byte [ERR_FLAG],ERR_SYSSZ ;indicate system too small for VDISK
	MOV	word [BUFF_SIZE],1 ;set up minimal values to continue init
	MOV	AX,[VAL_SSZ_S] ;smallest possible sector size
	MOV	[BPB_SSZ],AX
	MOV	word [BPB_DIRN],4 ;4 directory entries
	RET

VAL_BSIZE_B:				;some memory is available
	CMP	AX,[BUFF_SIZE] ;is available memory >= requested?
	JAE	VAL_BSIZE_C		;if so, we're done

	MOV	[BUFF_SIZE],AX ;give all available memory
	mov	word [cs:EM_New_Size],0 ;an001; dms;save new size of EM for later use
	mov	ax,[cs:AVAIL_LO] ;an001; dms;get low word of EM start
	mov	dl,[cs:AVAIL_HI] ;an001; dms;get high byte of EM start

	mov	[cs:START_EM_LO],ax ;an001; dms;load in new beginning word
	mov	[cs:START_EM_HI],dl ;an001; dms;load in new beginning byte
	OR	byte [ERR_FLAG],ERR_BSIZE ;indicate buffersize adjusted
VAL_BSIZE_C:


	RET


GET_MSIZE:        ;determine memory available to VDISK
					;returns KB available in AX
	CMP	byte [EM_SW],0 ;EXTENDED MEMORY?
	JE	GET_MSIZE_2		;use non-extended memory routine

	cmp	byte [EM_SW],EM_Mem ;Extended memory requested?		;an005; dms;
	je	USE_EXTENDED_SUPPORT	;yes					;an005; dms;
					;no - check for EMS availability


	CALL	EMS_CHECK		;AN000; Check if EMS is installed
	JC	GET_MSIZE_Z		;AN000; Yes, it is installed but in error
					;	 then notify caller by setting AX to zero
	CMP	AH,NOT EMS_INSTALLED_FLAG ;AN000;
	JE	GET_MSIZE_Z		;ac005; flag an error occurred
	MOV	[EM_SW2],AH ;AN000;   Set EMS flag
	CALL	EMS_GET_PAGES		;AN000;   Get count of total number of pages
	xor	dx,dx			;an002;   clear high word
	MUL	[DOS_Page_Size_Word] ;ac002;   Number of pages * KB per page
	RET				;AN000;   Return with AX = number of whole free kilobytes
					;
USE_EXTENDED_SUPPORT:			;AN000; No, EMS is not installed

	MOV	AX,EM_MEMSIZE		;function code to AH
	INT	EM_INT			;get extended memory size in AX
	JC	GET_MSIZE_Z		;if error, no extended memory installed
	or	ax,ax			;an000; dms;see if memory returned
	jz	GET_MSIZE_Z		;an000; dms;signal no memory

	RET

GET_MSIZE_2:				;non-extended memory size determination

;Compute AX = total system size, - (VDISK end address + 64KB)

	MOV	AX,[START_BUFFER_PARA] ;paragraph end of VDISK code
	XOR	DX,DX			;clear for division
	DIV	[PARA_PER_KB] ;KB address of load point
	ADD	DX,0FFFFH		;round upward to KB boundary
	ADC	AX,[MIN_MEMORY_LEFT] ;pick up CY and the 64KB we should leave
	PUSH	AX			;save across interrupt
	INT	MEM_SIZE		;get total system size
	POP	DX			;amount of total that we can't use
	SUB	AX,DX			;available space to VDISK
	JNC	GET_MSIZE_X		;exit if positive

GET_MSIZE_Z:
	XOR	AX,AX			;indicate no memory available
GET_MSIZE_X:				;exit from memory size determination
	RET
;GET_MSIZE ENDP

;VAL_BSIZE ENDP



EMS_CHECK:            ;AN000;

	CALL	EMS_CHECK1		;AN000; SEE IF EMS INSTALLED
	JNC	EMS_INSTALLED		;AN000; No,
	MOV	AH,NOT EMS_INSTALLED_FLAG ;AN000;  Flag EMS not installed
	CLC				;AN000;  Make sure carry is Clear
	JMP	SHORT EMS_Check_Exit	;AN000;  Leave check routine

EMS_INSTALLED:				;AN000; Yes,

	push	es				;an000; save es - call destroys it
	push	di				;an006; save di

	mov	ah,EMS_2F_Handler		;an006;see if our 2Fh is there
	xor	al,al				;an006;
	int	2Fh				;an006;
	cmp	al,0ffh 			;an006;2Fh handler there?
;	if$	e				;an006;yes
	JNE IF21$$
		mov	ah,EMS_2F_Handler	;an006;get EMS page for VDISK
		mov	al,0FFh 		;an006;
		mov	di,0FEh 		;an006;
		int	2Fh			;ac006;

		or	ah,ah			;an006;page available?
;		if$	z			;an006;yes
		JNZ IF22$$
			mov	[cs:EMS_FRAME_ADDR],es ;an006;save segment value
			mov	[cs:DOS_Page],di ;an006;save physical page #
			clc			;an006;flag memory available
			mov	ah,EMS_INSTALLED_FLAG ;an000;signal EMS here
;		else$				;an006;no memory avail.
		JMP SHORT EN22$$
IF22$$:
			mov	ah,not EMS_INSTALLED_FLAG ;an000;signal no EMS
			stc			;an006;flag it
;		endif$				;an006;
EN22$$:
;	else$
	JMP SHORT EN21$$
IF21$$:
		mov	ah,not EMS_INSTALLED_FLAG ;AN000;signal no EMS
		stc				;an006;signal not there
;	endif$
EN21$$:

	pop	di				;an006;restore di
	pop	es				;an000;restore es

EMS_Check_Exit:

	RET				;AN000;    Return

;EMS_CHECK ENDP				;AN000;



;=========================================================================
; EMS_CHECK1		: THIS MODULE DETERMINES WHETHER OR NOT EMS IS
;			  INSTALLED FOR THIS SESSION.
;
;	INPUTS		: NONE
;
;	OUTPUTS 	: ES:BX - FRAME ARRAY
;			  CY	- EMS NOT AVAILABLE
;			  NC	- EMS AVAILABLE
;=========================================================================

EMS_CHECK1:            ;AN000;EMS INSTALL CHECK

	push	ds			;an000;save ds - we stomp it
	mov	ax,00h			;an000;set ax to 0
	mov	ds,ax			;an000;set ds to 0
	cmp	word [ds:067h*4+0],0    ;an000;see if int 67h is there
	pop	ds			;an000;restore ds
;	IF$	NE			;AN000;EMS VECTOR CONTAINS DATA
	JE IF27$$
	    MOV     AH,EMS_STATUS	;AN000;see if EMS installed
	    XOR     AL,AL		;AN000;CLEAR AL
	    INT     EMS_INT		;AN000;
	    OR	    AH,AH		;AN000;EMS INSTALLED?
;	    IF$     Z			;AN000;YES
	    JNZ IF28$$
		MOV	AH,EMS_VERSION	;AN000;GET VERSION NUMBER
		XOR	AL,AL		;AN000;CLEAR AL
		INT	EMS_INT 	;AN000;
		CMP	AL,EMS_VERSION_LEVEL ;AN000;CORRECT VERSION?
;		IF$	AE		;AN000;YES
		JNAE IF29$$
		    CLC 		;AN000;FLAG IT AS GOOD EMS
;		ELSE$			;AN000;
		JMP SHORT EN29$$
IF29$$:
		    STC 		;AN000;BAD EMS
;		ENDIF$			;AN000;
EN29$$:
;	    ELSE$			;AN000;
	    JMP SHORT EN28$$
IF28$$:
		STC			;AN000;EMS NOT INSTALLED
;	    ENDIF$			;AN000;
EN28$$:
;	ELSE$				;AN000;
	JMP SHORT EN27$$
IF27$$:
	    STC 			;AN000;EMS VECTOR NOT THERE
;	ENDIF$				;AN000;
EN27$$:

	RET				;AN000;RETURN TO CALLER

;EMS_CHECK1 ENDP 			;AN000;


EMS_GET_PAGES:            ;AN000;

	MOV	AH,EMS_GET_NUM_PAGES	;AN000; Query EMS for page count
	INT	EMS_INT 		;AN000;
	OR	AH,AH			;AN000; Has EMS returned page count?
	JNZ	EMS_GET_ERROR		;AN000; Yes,
	MOV	AX,BX			;AN000;   Get number of pages
	RET				;AN000;

EMS_GET_ERROR:				;AN000;
	STC				;AN000;
	RET				;AN000;

;EMS_GET_PAGES ENDP

	SUBTTL	VAL_SSZ Validate Sector Size
	PAGE
;-----------------------------------------------------------------------;
;	VAL_SSZ validates sector size, adjusting if necessary		;
;-----------------------------------------------------------------------;
VAL_SSZ:        ;validate sector size
	CMP	byte [cs:EM_SW],0 ;EXTENDED MEMORY?
	JE	VAL_SSZ_ST		;no,go check sector size
	MOV	BX,[MAXSEC_TRF] ;move number of sectors to transfer
	CMP	BX,1			;> or equal to 1 ?
	JB	DFLT_TRF		;set default if it is
	CMP	BX,8			;> than 8 ?
	JA	DFLT_TRF		;set default if it is
	JMP	VAL_SSZ_ST		;continue processing

DFLT_TRF:				;set default
	MOV	word [MAXSEC_TRF],DFLT_ESS ;
	MOV	BX,[MAXSEC_TRF] ;
	OR	byte [cs:ERR_FLAG],ERR_ESIZE ;indicate transfer size adjusted

VAL_SSZ_ST:				;validate sector size
	MOV	[MAX_CNT],BX ;initialize maximum number of sectors
					;to transfer for extended memory case
	MOV	BX,[BPB_SSZ] ;requested sector size
	MOV	CX,VAL_SSZ_N		;number of table entries
	MOV	SI,VAL_SSZ_TBL        ;DS:SI point to table start
VAL_SSZ_A:
	LODSW				;get table entry, step table pointer
	CMP	AX,BX			;is value in table?
	JE	VAL_SSZ_X		;exit if value found
	LOOP	VAL_SSZ_A		;loop until table end

	MOV	BX,DFLT_SSZ		;get default sector size
	MOV	[BPB_SSZ],BX ;set sector size to default value
	OR	byte [ERR_FLAG],ERR_SSZ ;indicate sector size adjusted
VAL_SSZ_X:

;Compute the maximum number of sectors that can be moved in 64KB (less one)
;Restricting moves to this amount avoids 64KB boundary problems.

	CMP	byte [cs:EM_SW],0 ;EXTENDED MEMORY?
	JNE	SIZE_DONE		;yes, we are done
	XOR	DX,DX
	MOV	AX,0FFFFH		;64KB - 1
	DIV	BX			;/sector size
	MOV	[MAX_CNT],AX ;max sectors in one move
SIZE_DONE:
	RET
;VAL_SSZ ENDP

	SUBTTL	VAL_DIRN Validate number of directory entries
	PAGE
;-----------------------------------------------------------------------;
;	VAL_DIRN validates and adjusts the number of directory entries. ;
;									;
;	Minimum is MIN_DIRN, maximum is MAX_DIRN.  If outside these	;
;	limits, DFLT_DIRN is used.					;
;									;
;	The number of directory entries is rounded upward to fill	;
;	a sector							;
;-----------------------------------------------------------------------;
VAL_DIRN:
	MOV	AX,[BPB_DIRN] ;requested directory entries
	CMP	AX,MIN_DIRN		;if less than minimum
	JB	VAL_DIRN_A		;use default instead

	CMP	AX,MAX_DIRN		;if <= maximum
	JBE	VAL_DIRN_B		;accept value as provided

VAL_DIRN_A:
	MOV	AX,DFLT_DIRN		;use default directory entries
	OR	byte [ERR_FLAG],ERR_DIRN ;indicate directory entries adjusted
VAL_DIRN_B:				;AX is number of directory entries
	MUL	[DIRE_SIZE] ;* 32 = bytes of directory requested
	DIV	[BPB_SSZ] ;/ sector size = # of directory sectors
	OR	DX,DX			;test remainder for zero
	JZ	VAL_DIRN_C		;jump if exact fit

	INC	AX			;increment directory sectors
	OR	byte [ERR_FLAG],ERR_DIRN ;indicate directory entries adjusted
VAL_DIRN_C:				;make sure enough sectors available
	MOV	DX,[BPB_SECN] ;total sectors on media
	SUB	DX,[BPB_RES] ;less reserved sectors
	SUB	DX,2			;less minimum FAT and 1 data sector
	CMP	AX,DX			;if directory sectors <= available
	JLE	VAL_DIRN_D		;use requested amount

	MOV	AX,1			;use only one directory sector
	OR	byte [ERR_FLAG],ERR_DIRN ;indicate directory entries adjusted
VAL_DIRN_D:
	MOV	[DIR_SECTORS],AX ;save number of directory sectors
	MUL	[BPB_SSZ] ;dir sectors * sector size = dir bytes
	DIV	[DIRE_SIZE] ;dir bytes / entry size = entries
	MOV	[BPB_DIRN],AX ;store adjusted directory entries
	RET
;VAL_DIRN ENDP

	SUBTTL	VAL_FAT Validate File Allocation Table (FAT)
	PAGE
;-----------------------------------------------------------------------;
;VAL_FAT computes:							;
;BPB_FATSZ, the number of sectors required per FAT copy 		;
;									;
;Each FAT entry is 12 bits long, for a maximum of 4095 FAT entries.	;
;(A few FAT entries are reserved, so the highest number of FAT entries	;
;we permit is 0FE0H.)  With large buffer sizes and small sector sizes,	;
;we have more allocation units to describe than a 12-bit entry will	;
;describe.  If the number of FAT entries is too large, the sector size	;
;is increased (up to a maximum of 512 bytes), and then the allocation	;
;unit (cluster) size is doubled, until we have few enough allocation	;
;units to be properly described in 12 bits.				;
;									;
;This computation is slightly conservative in that the FAT entries	;
;necessary to describe the FAT sectors are included in the computation. ;
;-----------------------------------------------------------------------;
VAL_FAT:
	MOV	AX,[BPB_SECN] ;total number of sectors
	SUB	AX,[BPB_RES] ;don't count boot sector(s)
	SUB	AX,[DIR_SECTORS] ;don't count directory sectors

	CMP	AX,0000h		;an000; dms; fix ptm 112; any left?
	JA	VAL_FAT_A		;an000; dms; fix ptm 112; yes

;;;;;	JG	VAL_FAT_A		;jump if some remaining
	MOV	word [BPB_SSZ],DFLT_SSZ ;force default sector size
	OR	byte [ERR_FLAG],ERR_SSZ+ERR_PASS ;indicate sector size adjusted
	JMP	SHORT VAL_FAT_X 	;recompute all values
VAL_FAT_A:
	XOR	DX,DX			;clear DX for division
	MOV	CL,[BPB_AUSZ] ;CX = sectors/cluster
	XOR	CH,CH
	DIV	CX			;whole number of clusters in AX
	ADD	DX,0FFFFH		;set carry if remainder
	ADC	AX,0			;increment AX if remainder
	CMP	AX,MAX_FATE		;number of FAT entries too large?
	JBE	VAL_FAT_C		;no, continue

	MOV	AX,[BPB_SSZ] ;pick up current sector size
	CMP	AX,[VAL_SSZ_L] ;already at largest permitted?
	JE	VAL_FAT_B		;yes, can't make it any larger

	SHL	[BPB_SSZ],1 ;double sector size
	OR	byte [ERR_FLAG],ERR_SSZB ;indicate sector size adjusted
	JMP	SHORT VAL_FAT_X 	;recompute all sizes with new BPBSSZ

VAL_FAT_B:				;sector size is at maximum
	SHL	[BPB_AUSZ],1 ;double allocation unit size
	OR	byte [ERR_FLAG],ERR_PASS ;indicate another pass required
	JMP	SHORT VAL_FAT_X 	;recompute values

VAL_FAT_C:				;FAT size =  1.5 * number of clusters
	MOV	CX,AX			;number of clusters
	SHL	AX,1			;* 2
	ADD	AX,CX			;* 3
	SHR	AX,1			;* 1.5
	ADC	AX,3			;add 3 bytes for first 2 FAT entries
					;(media descriptor and FFFFH), and CY
	XOR	DX,DX			;clear DX for division
	DIV	[BPB_SSZ] ;FAT size/sector size
	ADD	DX,0FFFFH		;set carry if remainder
	ADC	AX,0			;round upward
	MOV	[BPB_FATSZ],AX ;number of sectors for 1 FAT copy
VAL_FAT_X:
	RET
;VAL_FAT ENDP


;VALIDATE ENDP

	SUBTTL	COPY_BPB Copy BPB to Boot Record
	PAGE
;-----------------------------------------------------------------------;
;	COPY_BPB copies the BIOS Parameter Block (BPB)			;
;	to the VDISK Boot Record					;
;-----------------------------------------------------------------------;
;	ASSUME	DS:CSEG
COPY_BPB:        ;Copy BBP to Boot Record
	PUSH	DS
	POP	ES			;set ES = DS

	MOV	CX,BPB_LEN		;length of BPB
	MOV	SI,BPB         ;source offset
	MOV	DI,BOOT_BPB        ;target offset
	REP	MOVSB			;copy BPB to boot record
	RET
;COPY_BPB ENDP

	SUBTTL	VERIFY_EXTENDER
	PAGE
;-----------------------------------------------------------------------;
;	VERIFY_EXTENDER makes sure that if an Expansion Unit is 	;
;	installed, the memory size switches on the Extender Card	;
;	are correctly set.						;
;-----------------------------------------------------------------------;


;	ASSUME	DS:CSEG
EXT_P210 EQU	0210H			;write to latch expansion bus data
					;read to verify expansion bus data
EXT_P213 EQU	0213H			;Expansion Unit status

VERIFY_EXTENDER:

	NOP

	MOV	DX,EXT_P210		;Expansion bus data port address

	MOV	AX,5555H		;set data pattern
	OUT	DX,AL			;write 55H to control port
	PUSH	DX
	POP	DX

	JMP	SHORT $+2		;Let the I/O circuits catch up
	IN	AL,020h 		;Clear the CMOS bus drivers!

	IN	AL,DX			;recover data
	CMP	AH,AL			;did we recover the same data?
	JNE	VERIFY_EXTENDER_X	;if not, no extender card

	NOT	AX			;set AX = 0AAAAH
	OUT	DX,AL			;write 0AAH to control port
	PUSH	DX			;load data line
	POP	DX			;load data line

	JMP	SHORT $+2		;Let the I/O circuits catch up
	IN	AL,020h 		;Clear the CMOS bus drivers!

	IN	AL,DX			;recover data
	CMP	AH,AL			;did we recover the same data?
	JNE	VERIFY_EXTENDER_X	;if not, no extender card

;Expansion Unit is present.

;Determine what the switch settings should be on the Extender Card

	INT	MEM_SIZE		;get system memory size in KB in AX
	ADD	AX,63D			;memory size + 63K
	MOV	CL,6			;2^6 = 64
	SHR	AX,CL			;divide by 64
					;AX is highest segment address
	MOV	AH,AL			;save number of segments

;Read Expander card switch settings

	MOV	DX,EXT_P213		;expansion unit status
	IN	AL,DX			;read status
					;bits 7-4 (hi nibble) are switches
	MOV	CL,4			;shift count
	SHR	AL,CL			;shift switches to bits 3-0 of AL

	CMP	AH,AL			;do switches match memory size?
	JE	VERIFY_EXTENDER_X	;yes, exit normally

	OR	byte [ERR_FLAG],ERR_EXTSW ;indicate switch settings are wrong

VERIFY_EXTENDER_X:
	RET
;VERIFY_EXTENDER ENDP

	SUBTTL	UPDATE_AVAIL
	PAGE
;-----------------------------------------------------------------------;
;	UPDATE_AVAIL updates the address of the first byte in extended	;
;	memory not used by any VDISK buffer				;
;-----------------------------------------------------------------------;
;If EMS is installed, we must allocate memory here and obtain the	;
;handle which we will use throughout our existance. AVAIL_LO and _HI	;
;really mean nothing to us.						;
;-----------------------------------------------------------------------;

UPDATE_AVAIL:
	MOV	AX,[BUFF_SIZE] ;number of KB of VDISK buffer

	CMP	byte [EM_SW2],EMS_INSTALLED_FLAG ;AN000; Is EMS installed?
	JNE	USE_INT15_LOGIC 	;ac006; Yes,
	xor	dx,dx			;an003; clear high word
	div	[DOS_Page_Size_Word] ;ac003;   Calculate number of pages needed
	or	dx,dx			;an004; remainder?
;	if$	nz			;an004; yes
	JZ IF36$$
	    inc     ax			;an004; need 1 extra page
;	endif$				;an004;
IF36$$:
	MOV	BX,AX			;AN000;   Prepare for EMS call

	MOV	AH,EMS_ALLOC_PAGES	;AN000;   Allocate requested pages
	INT	EMS_INT 		;AN000;
	OR	AH,AH			;AN000;   Was there an error allocating?
	JNZ	ALLOC_ERROR		;AN000;   No,
	MOV	[EMS_HANDLE],DX ;AN000;     Save EMS handle for this VDISK
	call	EMS_Build_Handle_Name	;an000; dms;

	RET				;AN000;
					;AN000;
ALLOC_ERROR:				;AN000;
	MOV	byte [ERR_FLAG],EMS_ALLOC_ERROR ;AN000;    ??????    *RPS
	RET				;AN000;
					;AN000;
USE_INT15_LOGIC:			;AN000;

	call	Modify_CMOS_EM		;an001; dms;adjust EM for new size

	RET
;UPDATE_AVAIL ENDP


;=========================================================================
; Modify_CMOS_EM	: This routine modifies the size of extended
;			  memory.  By modifying the size of extended
;			  memory other users will not have the potential
;			  to overlay a VDISK residing in EM.
;
;	Inputs	: EM_New_Size	- The new size that EM will be after
;				  creation of this VDISK.
;	Outputs : Modified data in CMOS for EM.  Bytes 17h & 18h at
;						 port 71h.
;=========================================================================

Modify_CMOS_EM:           ;an001; dms;

	push	ax			;an001; dms;save ax
	call	STEAL_INT15		;an001; dms;get INT 15h vector

	mov	ax,word [cs:EM_New_Size]   ;an001; dms;transfer new size
	mov	word [cs:EM_KSize],ax   ;an001; dms;set EM size to new size
	pop	ax			;an001; dms;restore ax

	ret				;an001; dms;

;Modify_CMOS_EM endp			;an001; dms;

;=========================================================================
; EMS_Build_Handle_Name 	- This routine will build an EMS handle's
;				  name as follows:
;					VDISK D:
;
;	Inputs	: DX	- Handle to have associated name
;
;	Outputs : Handle name
;=========================================================================

EMS_Build_Handle_Name:           ;an000; dms;

	push	si			;an000; dms;save si
	push	cx			;an000; dms;save cx

	push	ds			;an000; dms;save ds
	push	bx			;an000; dms;save bx
	lds	bx,[RH_PTRA] ;an000; dms;point to request header
	mov	ch,byte [RH+RH0.RH0_DRIV] ;an000; dms;get drive number
	add	ch,'A'			;an000; dms;convert to drive letter
	pop	bx			;an000; dms;restore bx
	pop	ds			;an000; dms;restore ds

	mov	si,VDISK_Name           ;an000; dms;point to "VDISK " literal
	mov	byte [si+6],ch     ;an000; dms;put drive letter in string
	mov	byte [si+7],":"     ;an000; dms;colon terminate it

	mov	ax,EMS_SET_HANDLE_NAME	;an000; dms;set the handle's name
	int	EMS_INT 		;an000; dms;

	pop	cx			;an000; dms;restore cx
	pop	si			;an000; dms;restore si

	ret				;an000; dms;

;EMS_Build_Handle_Name endp		;an000; dms;

	SUBTTL	FORMAT_VDISK
	PAGE
;-----------------------------------------------------------------------;
;	This Request Header is used by MOVE_VDISK to move the		;
;	first few sectors of the virtual disk (boot, FAT, and		;
;	Directory) into extended memory.				;
;-----------------------------------------------------------------------;

MOVE_RH DB	MOVE_RH_L		;length of request header
	DB	0			;sub unit
	DB	8			;output operation
	DW	0			;status
	DQ	?			;reserved for DOS
	DB	?			;media descriptor byte
MOVE_RHO rw      1 ;offset of data transfer address
MOVE_RHS rw      1 ;segment of data transfer address
MOVE_RHCNT rw      1 ;count of sectors to transfer
	DW	0			;starting sector number
MOVE_RH_L =	($-MOVE_RH)	;length of request header

;-----------------------------------------------------------------------;
;	FORMAT_VDISK formats the boot sector, FAT, and directory of an	;
;	extended memory VDISK in storage immediately following		;
;	VDISK code, in preparation for moving to extended memory.	;
;-----------------------------------------------------------------------;
FORMAT_VDISK:       ;format boot record, FATs and directory

	MOV	AX,CS			;compute 20-bit address
	MUL	[WPARA_SIZE] ;16 * segment
	ADD	AX,MSGEND        ;+ offset
	ADC	DL,0			;pick up carry
	ADD	AX,STACK_SIZE		;plus stack size
	ADC	DL,0			;pick up carry

	DIV	[WPARA_SIZE] ;split into segment(AX)&offset(DX)
	MOV	[MOVE_RHS],AX ;save in Request Header for move
	MOV	[MOVE_RHO],DX

	MOV	DI,DX			;offset to DI
	MOV	ES,AX			;segment to ES

;copy the boot record

	MOV	SI,BOOT_RECORD        ;point to source field
	MOV	AX,[BPB_RES] ;number of reserved sectors
	MUL	[BPB_SSZ] ;* sector size = length of boot records
	MOV	CX,AX			;length to CX for move
	REP	MOVSB			;move boot record(s)

;format the FAT(s)

	MOV	CL,[BPB_FATN] ;number of FATs
	XOR	CH,CH
FORMAT_VDISK_A: 			;set up one FAT
	PUSH	CX			;save loop counter on stack
	MOV	AL,[BPB_MCB] ;media control byte
	STOSB				;store media control byte, increment DI
	MOV	AX,0FFFFH		;bytes 2 and 3 of FAT are 0FFH
	STOSW
	MOV	AX,[BPB_FATSZ] ;number of sectors per FAT
	MUL	[BPB_SSZ] ;* sector size = length of FAT in bytes
	SUB	AX,3			;less the 3 bytes we've stored
	MOV	CX,AX			;count to CX
	XOR	AX,AX
	REP	STOSB			;clear remainder of FAT
	POP	CX			;get loop counter off stack
	LOOP	FORMAT_VDISK_A		;loop for all copies of the FAT

;Format the directory

	MOV	SI,VOL_LABEL        ;point to volume label
	MOV	CX,VOL_LABEL_LEN	;length of volume directory entry
	REP	MOVSB			;move volume id to directory
	MOV	AX,DIR_ENTRY_SIZE	;length of 1 directory entry
	MUL	[BPB_DIRN] ;* number entries = bytes of directory
	SUB	AX,VOL_LABEL_LEN	;less length of volume label
	MOV	CX,AX			;CX = length of rest of directory
	XOR	AX,AX
	REP	STOSB			;clear directory to nulls
	RET
;FORMAT_VDISK ENDP

	SUBTTL	STEAL_INT15
	PAGE
;-----------------------------------------------------------------------;
;	STEAL_INT15 changes the INT 15H vector to point to this VDISK	;
;	so that subsequent calls to INT15H may determine the actual	;
;	size of EM after VDISK's allocation of it.                      ;
;-----------------------------------------------------------------------;
STEAL_INT15:
	PUSH	DS
	XOR	AX,AX
	MOV	DS,AX			;set DS = 0
;	ASSUME	DS:INT_VEC
	CLI				;disable interrupts
	LES	DI,[ds:EM_VEC] ;get original vector's content
	MOV	[cs:INTV15O],DI ;save original vector
	MOV	[cs:INTV15S],ES
	MOV	word [ds:EM_VECO],VDISK_INT15 ;offset of new INT routine
	MOV	[ds:EM_VECS],CS ;segment of new INT routine
	STI				;enable interrupts again
	POP	DS			;restore DS
	RET
;STEAL_INT15 ENDP



	SUBTTL	MOVE_VDISK
	PAGE
;-----------------------------------------------------------------------;
;	MOVE_VDISK moves the formatted boot sector, FAT, and directory	;
;	into extended memory.						;
;-----------------------------------------------------------------------;

MOVE_VDISK:
	MOV	AL,[cs:BPB_FATN] ;number of FAT copies
	CBW				;clear AH
	MUL	[cs:BPB_FATSZ] ;number of FAT sectors
	ADD	AX,[cs:BPB_RES] ;+ reserved sectors
	ADD	AX,[cs:DIR_SECTORS] ;+ directory sectors
	MOV	[cs:MOVE_RHCNT],AX ;store as I/O length

	MOV	BX,MOVE_RH        ;DS:BX point to request header
	PUSH	DS			;make sure DS gets preserved
	CALL	INOUT			;move to extended memory
	POP	DS
	RET
;MOVE_VDISK ENDP

	SUBTTL	FILL_RH Fill in Request Header
	PAGE
;-----------------------------------------------------------------------;
;	FILL_RH fills in the Request Header returned to DOS		;
;-----------------------------------------------------------------------;
;	ASSUME	DS:CSEG
FILL_RH:        ;fill in INIT Request Header fields
	MOV	CX,[START_BUFFER_PARA] ;segment end of VDISK resident code
	MOV	AX,[PARAS_PER_SECTOR] ;paragraphs per sector
	MUL	[BPB_SECN] ;* number of sectors
	ADD	AX,CX			;+ starting segment
	MOV	DX,AX			;DX is segment of end VDISK buffer
	CMP	byte [EM_SW],0 ;AC000; DMS; IF EM NOT REQUESTED
;	IF$	NE			;AN000; DMS; EM REQUESTED
	JE IF38$$
	    MOV     DX,CX		;AN000; DMS;END OF CODE SEGMENT ADDR
;	ENDIF$				;AN000; DMS;
IF38$$:

FILL_RH_A:				;DX is proper ending segment address
	MOV	AL,1			;number of units
	test	byte [cs:err_flag2],err_baddos
	jnz	dont_install

	TEST	byte [ERR_FLAG],ERR_SYSSZ+ERR_EXTSW ;if bypassing install
	JZ	FILL_RH_B		;jump if installing driver

dont_install:
	MOV	DX,CS			;segment of end address
	XOR	AL,AL			;number of units is zero
FILL_RH_B:
	PUSH	DS			;preserve DS
	LDS	BX,[RH_PTRA] ;get Request Header addr in DS:BX
	MOV	byte [RH+RH0.RH0_NUN],AL ;store number of units (0 or 1)
	MOV	word [RH+RH0.RH0_ENDO],0 ;end offset is always zero
	MOV	word [RH+RH0.RH0_ENDS],DX ;end of VDISK or end of buffer
	MOV	word [RH+RH0.RH0_BPBO],BPB_PTR
	MOV	word [RH+RH0.RH0_BPBS],CS ;BPB array address
	POP	DS			;restore DS
	RET
;FILL_RH ENDP

	SUBTTL	WRITE_MESSAGES and associated routines
	PAGE
;-----------------------------------------------------------------------;
;	WRITE_MESSAGE writes a series of messages to the standard	;
;	output device showing the VDISK parameter values actually used. ;
;-----------------------------------------------------------------------;

;	ASSUME	DS:CSEG
WRITE_MESSAGES:       ;display all messages


	test	byte [cs:err_flag2],err_baddos ;AN000;
	JZ	DISPLAY_ALL_MESSAGES	;AN000;
	RET

DISPLAY_ALL_MESSAGES:			;AN000; No, then display messages

	PUSH	DS			;preserve DS
	LDS	BX,[RH_PTRA] ;get Request Header Address
	MOV	CL,byte [RH+RH0.RH0_DRIV] ;get drive code
	ADD	CL,'A'			;convert to drive letter
	POP	DS			;restore DS

	MOV	AX,VDISK_TITLE		;AN000; 'VDISK Version 3.3 virtual disk $'
	LEA	SI,[TITLE_SUBLIST] ;AN000; Specify SUBLIST to use for replacement
	MOV	[DRIVE_CODE],CL ;AN000; Save drive code
	MOV	CX,ONE_REPLACE		;AN000; Notify SYSDISPMSG of 1 replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JNC	WRITE_MESSAGES_A	;AN000; Was there an error?
	JMP	SYSDISP_ERROR		;AN000; YES, display the extended error

;If any of the user specified values has been adjusted, issue an
;appropriate message

WRITE_MESSAGES_A:			;AN000; NO,
	TEST	byte [ERR_FLAG],ERR_BSIZE ;was buffersize adjusted?
	JZ	WRITE_MESSAGES_B	;if not, skip message

	MOV	AX,BUFFER_ADJUSTED	;AN000; "Buffer size adjusted",CR,LF
	MOV	CX,NO_REPLACE		;AN000; Notify SYSDISPMSG of no replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message

WRITE_MESSAGES_B:			;AN000; NO,
	TEST	byte [ERR_FLAG],ERR_SSZ ;was sector size adjusted?
	JZ	WRITE_MESSAGES_C	;if not, skip message

	MOV	AX,SECTOR_ADJUSTED	;AN000; "Sector size adjusted",CR,LF
	MOV	CX,NO_REPLACE		;AN000; Notify SYSDISPMSG of no replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JNC	WRITE_MESSAGES_C	;AN000; Was there an error?
	JMP	SYSDISP_ERROR		;AN000; YES, display the extended error

WRITE_MESSAGES_C:
	TEST	byte [ERR_FLAG],ERR_DIRN ;were directory entries adjusted?
	JZ	WRITE_MESSAGES_D0	;if not, skip message

	MOV	AX,DIR_ADJUSTED 	;AN000; "Directory entries adjusted",CR,LF
	MOV	CX,NO_REPLACE		;AN000; Notify SYSDISPMSG of no replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JNC	WRITE_MESSAGES_D0	;AN000; Was there an error?
	JMP	SYSDISP_ERROR		;AN000; YES, display the extended error

WRITE_MESSAGES_D0:
	TEST	byte [ERR_FLAG],ERR_ESIZE ;was transfer size adjusted?
	JZ	WRITE_MESSAGES_D	;if not, skip message

	MOV	AX,TRANS_ADJUSTED	;AN000; "Transfer size adjusted",CR,LF
	MOV	CX,NO_REPLACE		;AN000; Notify SYSDISPMSG of no replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JNC	WRITE_MESSAGES_D	;AN000; Was there an error?
	JMP	SYSDISP_ERROR		;AN000; YES, display the extended error

WRITE_MESSAGES_D:
	TEST	byte [ERR_FLAG],ERR_SWTCH ;was an invalid switch character found?
	JZ	WRITE_MESSAGES_E	;if not, skip message

	MOV	AX,INVALID_SW_CHAR	;AN000; "Invalid switch character",CR,LF
	MOV	CX,NO_REPLACE		;AN000; Notify SYSDISPMSG of no replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JNC	WRITE_MESSAGES_E	;AN000; Was there an error?
	JMP	SYSDISP_ERROR		;AN000; YES, display the extended error

WRITE_MESSAGES_E:
	TEST	byte [ERR_FLAG],ERR_SYSSZ ;is system size too small to install?
	JZ	WRITE_MESSAGES_F	;if not, bypass error message

	MOV	AX,VDISK_NOT_INST	;AN000; "VDISK not installed - "
	MOV	CX,NO_REPLACE		;AN000; Notify SYSDISPMSG of no replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	MOV	AX,SYS_TOO_SMALL	;AN000; "Insufficient memory",CR,LF
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JNC	WRITE_MESSAGES_RET	;AN000; Was there an error?
	JMP	SYSDISP_ERROR		;AN000; YES, display the extended error
WRITE_MESSAGES_RET:
	RET				;skip messages showing adjusted sizes

WRITE_MESSAGES_F:
	TEST	byte [ERR_FLAG],ERR_EXTSW ;extender card switches wrong?
	JZ	WRITE_MESSAGES_G	;if not, bypass error message

	MOV	AX,VDISK_NOT_INST	;AN000; "VDISK not installed - "
	MOV	CX,NO_REPLACE		;AN000; Notify SYSDISPMSG of no replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	MOV	AX,EXTEND_CARD_WRONG	;AN000; "Extender Card switches",CR,LF,"do not match system memory size",CR,LF,CR,LF
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JNC	WRITE_MESSAGES_RET	;AN000; Was there an error?
	JMP	SYSDISP_ERROR		;AN000; YES, display the extended error

WRITE_MESSAGES_G:			;display adjusted size messages
	MOV	AX,BUF_SZ		;AN000; "Buffer size: %1 KB",CR,LF
	LEA	SI,[BUF_SZ_SUBLIST] ;AN000; Specify SUBLIST to use for replacement
	MOV	CX,ONE_REPLACE		;AN000; Notify SYSDISPMSG of 1 replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JC	SYSDISP_ERROR		;AN000;

	MOV	AX,SEC_SZ		;AN000; "Sector size: %1",CR,LF
	LEA	SI,[SEC_SZ_SUBLIST] ;AN000; Specify SUBLIST to use for replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JC	SYSDISP_ERROR		;AN000;

	MOV	AX,DIR_ENTRIES		;AN000; "Directory entries: %1",CR,LF
	LEA	SI,[DIR_ENT_SUBLIST] ;AN000; Specify SUBLIST to use for replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JC	SYSDISP_ERROR		;AN000;

	CMP	byte [cs:EM_SW],0 ;extended memory ?
	JE	END_LINE		;
	MOV	AX,TRANS_SZ		;AN000; "Transfer size: %1",CR,LF,CR,LF
	LEA	SI,[TRANS_SZ_SUBLIST] ;AN000; Specify SUBLIST to use for replacement
	CALL	DISPLAY_MESSAGE 	;AN000; Display the message
	JC	SYSDISP_ERROR		;AN000;


END_LINE:
	RET				;return to INIT_P1

SYSDISP_ERROR:

	push	ds			;an006; dms;save ds
	push	bx			;an006; dms;save bx
	lds	bx,[cs:RH_PTRA] ;an006; dms;point to request header
	mov	word [RH+RH0.RH0_FLAG],-1 ;an006; dms;signal BIO and error occurred
	pop	bx			;an006; dms;restore bx
	pop	ds			;an006; dms;restore ds

					;AN000; Set error conditions
	MOV	BX,NO_HANDLE		;AN000; Write to NO_HANDLE
	MOV	CX,NO_REPLACE		;AN000;
	MOV	DH,EXT_ERR_CLASS	;AN000;
	MOV	DL,NO_INPUT		;AN000;

	PUSH	DS			;AN000;SET UP ADDRESSIBILITY TO MSG
	PUSH	ES			;AN000;

	PUSH	CS			;AN000;TRANSFER CS
	POP	DS			;AN000;  TO DS
	PUSH	CX			;AN000;TRANSFER CS
	POP	ES			;AN000;  TO ES

;	ASSUME	DS:CSEG,ES:CSEG 	;AN000;
	CALL	GET_PARM_SEGMENT	;AN000;OBTAIN PARM SEGMENT

	CALL	SYSDISPMSG		;AN000;

	POP	ES			;AN000;RESTORE REG
	POP	DS			;AN000;RESTORE REG
;	ASSUME	DS:NOTHING,ES:NOTHING	;AN000;

	RET				;AN000;

;WRITE_MESSAGES ENDP


DISPLAY_MESSAGE:
					;AN000; Set default values
	MOV	BX,NO_HANDLE		;AN000; Output handle is NO_HANDLE
	MOV	DH,UTILITY_MSG_CLASS	;AN000; Utility class message
	MOV	DL,NO_INPUT		;AN000; No input is requested
	PUSH	DS			;AN000;SET UP ADDRESSIBILITY TO MSG
	PUSH	ES			;AN000;

	PUSH	CS			;AN000;TRANSFER CS
	POP	DS			;AN000;  TO DS
	PUSH	CS			;AN000;TRANSFER CS
	POP	ES			;AN000;  TO ES

;	ASSUME	DS:CSEG,ES:CSEG 	;AN000;
	CALL	GET_PARM_SEGMENT	;AN000;OBTAIN PARM SEGMENT

	CALL	SYSDISPMSG		;AN000;

	POP	ES			;AN000;RESTORE REG
	POP	DS			;AN000;RESTORE REG
;	ASSUME	DS:NOTHING,ES:NOTHING	;AN000;

	RET				;AN000;

;DISPLAY_MESSAGE ENDP

GET_PARM_SEGMENT:       ;AN000;OBTAIN PARM SEGMENT

	PUSH	CX			;AN000;SAVE CX - WE STOMP IT
	PUSH	SI			;AN000;SAVE SI - WE STOMP IT

	CMP	CX,00H			;AN000;SEE IF REPLACEMENT IS REQUIRED
	JE	GPS_END 		;AN000;END IF ZERO

	GPS_CONTINUE:			;AN000;LOOP CONTINUE

	MOV	[SI+SUBLIST.SL_SEGMENT],DS ;AN000;SET UP SEGMENT
	ADD	SI,11			;AN000;INCREASE SI BY TABLE SZ

	LOOP	GPS_CONTINUE		;AN000;CONTINUE LOOP IF CX NOT ZERO

	GPS_END:			;AN000;EXIT POINT

	POP	SI			;AN000;RESTORE SI
	POP	CX			;AN000;RESTORE CX

	RET				;AN000;RETURN TO CALLER

;GET_PARM_SEGMENT ENDP			;AN000;




;INIT_P1 ENDP				;end of INIT part one
.xlist
MSG_SERVICES <MSGDATA>			;AN000:
MSG_SERVICES <LOADmsg>			;AN000;
MSG_SERVICES <DISPLAYmsg,CHARmsg,NUMmsg> ;AN000;
MSG_SERVICES <VDISK.CL1,VDISK.CL2,VDISK.CLA> ;AN000;
.list
label MSGEND byte   ;AN000;

;CSEG	ENDS
;	END
