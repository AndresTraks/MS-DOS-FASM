
;%OUT IOCTL.INC...
; THESE ARE ALL THE IMPORTANT STRUCTURES AND EQUATES FOR IOCTL
;==============================================================================
;REVISION HISTORY:
;AN000 - New for DOS Version 4.00 - J.K.
;AC000 - Changed for DOS Version 4.00 - J.K.
;AN00x - PTM number for DOS Version 4.00 - J.K.
;==============================================================================
;AN001; D241 Provide support of Multi-track Format/Verify	   9/23/87 J.K.
;AN002; P1535 Unformatted hard file problem			  10/15/87 J.K.
;AN003; D490 IOCTL subfunction 63h,43h,64h,44h conflicts with OS2  2/26/88 J.K.
;==============================================================================

;*** J.K.
;General Guide -
;Category Code:
; 0... .... DOS Defined
; 1... .... User defined
; .xxx xxxx Code

;Function Code:
; 0... .... Return error if unsupported
; 1... .... Ignore if unsupported
; .0.. .... Intercepted by DOS
; .1.. .... Passed to driver
; ..0. .... Sends data/commands to device
; ..1. .... Quries data/info from device
; ...x .... Subfunction
;
; Note that "Sends/queries" data bit is intended only to regularize the
; function set.  It plays no critical role; some functions may contain both
; command and query elements. The convention is that such commands are
; defined as "sends data".

;*****************************;*
; BLOCK DRIVERS 	      ;*
;*****************************;*

; IOCTL SUB-FUNCTIONS
IOCTL_GET_DEVICE_INFO	EQU	0
IOCTL_SET_DEVICE_INFO	EQU	1
IOCTL_READ_HANDLE	EQU	2
IOCTL_WRITE_HANDLE	EQU	3
IOCTL_READ_DRIVE	EQU	4
IOCTL_WRITE_DRIVE	EQU	5
IOCTL_GET_INPUT_STATUS	EQU	6
IOCTL_GET_OUTPUT_STATUS EQU	7
IOCTL_CHANGEABLE?	EQU	8
IOCTL_DeviceLocOrRem?	EQU	9
IOCTL_HandleLocOrRem?	EQU	0Ah   ;10
IOCTL_SHARING_RETRY	EQU	0Bh   ;11
GENERIC_IOCTL_HANDLE	EQU	0Ch   ;12
GENERIC_IOCTL		EQU	0Dh   ;13

; GENERIC IOCTL CATEGORY CODES
IOC_OTHER		EQU	0	; Other device control J.K. 4/29/86
IOC_SE			EQU	1	; SERIAL DEVICE CONTROL
IOC_TC			EQU	2	; TERMINAL CONTROL
IOC_SC			EQU	3	; SCREEN CONTROL
IOC_KC			EQU	4	; KEYBOARD CONTROL
IOC_PC			EQU	5	; PRINTER CONTROL
IOC_DC			EQU	8	; DISK CONTROL (SAME AS RAWIO)

; GENERIC IOCTL SUB-FUNCTIONS
RAWIO			EQU	8

; RAWIO SUB-FUNCTIONS
GET_DEVICE_PARAMETERS	EQU	60H
SET_DEVICE_PARAMETERS	EQU	40H
READ_TRACK		EQU	61H
WRITE_TRACK		EQU	41H
VERIFY_TRACK		EQU	62H
FORMAT_TRACK		EQU	42H
GET_MEDIA_ID		EQU	66h		;AN000;AN003;changed from 63h
SET_MEDIA_ID		EQU	46h		;AN000;AN003;changed from 43h
GET_ACCESS_FLAG 	EQU	67h		;AN002;AN003;Unpublished function.Changed from 64h
SET_ACCESS_FLAG 	EQU	47h		;AN002;AN003;Unpublished function.Changed from 44h

; SPECIAL FUNCTION FOR GET DEVICE PARAMETERS
BUILD_DEVICE_BPB	EQU	000000001B

; SPECIAL FUNCTIONS FOR SET DEVICE PARAMETERS
INSTALL_FAKE_BPB	EQU	000000001B
ONLY_SET_TRACKLAYOUT	EQU	000000010B
TRACKLAYOUT_IS_GOOD	EQU	000000100B

; SPECIAL FUNCTION FOR FORMAT TRACK
STATUS_FOR_FORMAT		EQU	000000001B
DO_FAST_FORMAT			equ	000000010B	;AN001;
; CODES RETURNED FROM FORMAT STATUS CALL
FORMAT_NO_ROM_SUPPORT		EQU	000000001B
FORMAT_COMB_NOT_SUPPORTED	EQU	000000010B

; DEVICETYPE VALUES
MAX_SECTORS_IN_TRACK	EQU	63	; MAXIMUM SECTORS ON A DISK.(Was 40 in DOS 3.2)
DEV_5INCH		EQU	0
DEV_5INCH96TPI		EQU	1
DEV_3INCH720KB		EQU	2
DEV_8INCHSS		EQU	3
DEV_8INCHDS		EQU	4
DEV_HARDDISK		EQU	5
DEV_OTHER		EQU	7

MAX_DEV_TYPE		EQU	7	; MAXIMUM DEVICE TYPE THAT WE
					; CURRENTLY SUPPORT.

;J.K. Bug in MASM 3.  A_BPB will be defined in PASS1 and, in PASS2 the
;compiler does not include BPB.INC and it will be treated as undefined.
; That is what the IF1 below was for.  fasm reads an include once per
; sight of it and keeps what it found, and BPB.INC guards its own layout
; against being read twice, so the include is simply an include.
	INCLUDE 'BPB.INC'
;IF1
;	BPBINPASS1 = 0
;	IFNDEF A_BPB
;	    INCLUDE BPB.INC
;	    BPBINPASS1 = 1
;	ENDIF
;ELSE
;	IF BPBINPASS1
;	    INCLUDE BPB.INC
;	ENDIF
;ENDIF

STRUC A_SECTORTABLE
{
.ST_SECTORNUMBER 	DW	0
.ST_SECTORSIZE		DW	0
}
match =A_SECTORTABLE_LAID_OUT, A_SECTORTABLE_LAID_OUT
{
    A_SECTORTABLE_LAID_OUT equ 1
    virtual at 0
      A_SECTORTABLE A_SECTORTABLE
      sizeof.A_SECTORTABLE = $ - A_SECTORTABLE
    end virtual
}

; Filled in where it stands, so the fields are the macro's arguments,
; each defaulting to what the structure declares.
STRUC A_DEVICEPARAMETERS DP_SPECIALFUNCTIONS_=0,DP_DEVICETYPE_=0,DP_DEVICEATTRIBUTES_=0,DP_CYLINDERS_=0,DP_MEDIATYPE_=0,DP_TRACKTABLEENTRIES_=0
{
.DP_SPECIALFUNCTIONS	DB	DP_SPECIALFUNCTIONS_
.DP_DEVICETYPE		DB	DP_DEVICETYPE_
.DP_DEVICEATTRIBUTES	DW	DP_DEVICEATTRIBUTES_
.DP_CYLINDERS		DW	DP_CYLINDERS_
.DP_MEDIATYPE		DB	DP_MEDIATYPE_
.DP_BPB			DB	sizeof.A_BPB dup (0)
.DP_TRACKTABLEENTRIES	DW	DP_TRACKTABLEENTRIES_
.DP_SECTORTABLE		DB MAX_SECTORS_IN_TRACK * sizeof.A_SECTORTABLE dup (0)
}
match =A_DEVICEPARAMETERS_LAID_OUT, A_DEVICEPARAMETERS_LAID_OUT
{
    A_DEVICEPARAMETERS_LAID_OUT equ 1
    virtual at 0
      A_DEVICEPARAMETERS A_DEVICEPARAMETERS
      sizeof.A_DEVICEPARAMETERS = $ - A_DEVICEPARAMETERS
    end virtual
}

STRUC A_TRACKREADWRITEPACKET
{
.TRWP_SPECIALFUNCTIONS	DB	0
.TRWP_HEAD		DW	0
.TRWP_CYLINDER		DW	0
.TRWP_FIRSTSECTOR	DW	0
.TRWP_SECTORSTOREADWRITE DW	0
.TRWP_TRANSFERADDRESS	DD	0
}
match =A_TRACKREADWRITEPACKET_LAID_OUT, A_TRACKREADWRITEPACKET_LAID_OUT
{
    A_TRACKREADWRITEPACKET_LAID_OUT equ 1
    virtual at 0
      A_TRACKREADWRITEPACKET A_TRACKREADWRITEPACKET
      sizeof.A_TRACKREADWRITEPACKET = $ - A_TRACKREADWRITEPACKET
    end virtual
}

;AN001; - FP_TRACKCOUNT is only meaningful when FP_SPECIALFUNCTIONS bit 1 = 1.
STRUC A_FORMATPACKET
{
.FP_SPECIALFUNCTIONS	DB	0
.FP_HEAD 		DW	0
.FP_CYLINDER		DW	0
.FP_TRACKCOUNT		DW	1
}
match =A_FORMATPACKET_LAID_OUT, A_FORMATPACKET_LAID_OUT
{
    A_FORMATPACKET_LAID_OUT equ 1
    virtual at 0
      A_FORMATPACKET A_FORMATPACKET
      sizeof.A_FORMATPACKET = $ - A_FORMATPACKET
    end virtual
}

STRUC A_VERIFYPACKET
{
.VP_SPECIALFUNCTIONS	DB	0
.VP_HEAD 		DW	0
.VP_CYLINDER		DW	0
}
match =A_VERIFYPACKET_LAID_OUT, A_VERIFYPACKET_LAID_OUT
{
    A_VERIFYPACKET_LAID_OUT equ 1
    virtual at 0
      A_VERIFYPACKET A_VERIFYPACKET
      sizeof.A_VERIFYPACKET = $ - A_VERIFYPACKET
    end virtual
}

STRUC A_MEDIA_ID_INFO
{
.MI_LEVEL		DW	0		;J.K. 87 Info. level
.MI_SERIAL		DD	0		;J.K. 87 Serial #
.MI_LABEL		DB     11 dup (' ')     ;J.K. 87 volume label
.MI_SYSTEM		DB	8 dup (' ')     ;J.K. 87 File system type
}
match =A_MEDIA_ID_INFO_LAID_OUT, A_MEDIA_ID_INFO_LAID_OUT
{
    A_MEDIA_ID_INFO_LAID_OUT equ 1
    virtual at 0
      A_MEDIA_ID_INFO A_MEDIA_ID_INFO
      sizeof.A_MEDIA_ID_INFO = $ - A_MEDIA_ID_INFO
    end virtual
}

STRUC A_DISKACCESS_CONTROL
{
.DAC_SPECIALFUNCTIONS	DB	0		;AN002; Always 0
.DAC_ACCESS_FLAG 	DB	0		;AN002; Non Zero - allow disk I/O to unformatted hard file
}
match =A_DISKACCESS_CONTROL_LAID_OUT, A_DISKACCESS_CONTROL_LAID_OUT
{
    A_DISKACCESS_CONTROL_LAID_OUT equ 1
    virtual at 0
      A_DISKACCESS_CONTROL A_DISKACCESS_CONTROL
      sizeof.A_DISKACCESS_CONTROL = $ - A_DISKACCESS_CONTROL
    end virtual
}

;********************************;*
; CHARACTER DEVICES (PRINTERS)	 ;*
;********************************;*

;RAWIO SUB-FUNCTIONS
GET_RETRY_COUNT 	EQU	65H
SET_RETRY_COUNT 	EQU	45H

STRUC A_RETRYCOUNT
{
.RC_COUNT		DW	0
}
match =A_RETRYCOUNT_LAID_OUT, A_RETRYCOUNT_LAID_OUT
{
    A_RETRYCOUNT_LAID_OUT equ 1
    virtual at 0
      A_RETRYCOUNT A_RETRYCOUNT
      sizeof.A_RETRYCOUNT = $ - A_RETRYCOUNT
    end virtual
}

;********************************;*		;J.K. 4/29/86
; CHARACTER DEVICES (SCREEN)	 ;*
;********************************;*		;J.K. 4/29/86
;
;SC_MODE_INFO	 struc
;SC_INFO_LENGTH 	 DW	 9
;SC_MODE		 DB	 0
;SC_COLORS		 DW	 0
;SC_WIDTH		 DW	 0
;SC_LENGTH		 DW	 0
;SC_MODE_INFO	 ends
;
;SC_INFO_PACKET_LENGTH	 EQU	 9		 ;LENGTH OF THE INFO PACKET.

;SUBFUNCTIONS FOR CON$GENIOCTL
;GET_SC_MODE		 EQU	 60h
;SET_SC_MODE		 EQU	 40h
;The following subfunctions are reserved for installable CODE PAGE switch
;console devices. - J.K. 4/29/86
;Get_active_codepage	 equ	 6Ah
;Invoke_active_codepage  equ	 4Ah
;Start_designate_codepage equ	 4Ch
;End_designate_codepage  equ	 4Dh
;Get_list_of_designated_codepage equ 6Bh
;J.K. 4/29/86 *** End of Con$genioctl equates & structures


