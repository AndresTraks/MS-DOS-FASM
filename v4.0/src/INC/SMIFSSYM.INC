
	PAGE	60,132
;	SCCSID = @(#)smifssym.inc 1.0 87/05/11
;
;   Modification history:
;	Created: May 11 1987 
;
;	SMifssym is only for IBMBIO.  It will only has definitions
;	for IFSHEADER, IFSRH of INIT function.
;	When ifssym.inc is Revised, make sure that SMifssym.inc
;	is also correct. - JK.
;

;==================
;IFS drive header
;=================

    IFSDEVICE	EQU	8000H	;  Supports single device/file functions
    IFSDISK	EQU	4000H	;  Supports multi-file functions
    IFSUNC	EQU	2000H	;  Support UNC (nameless) connection
    IFSREMOTE	EQU	0800H	;  File system is remote
    IFSFILTER	EQU	0400H	;  FS will filter (if off, use DOS
				;    standard, cap & 8.3)
    IFSIOCTL	EQU	0002H	;  Supports IOCTL functions
    IFSUSESHARE EQU	0001H	;  Uses DOS share support (vs own share)

STRUC IFSHEADER
{
.IFS_NEXT	DD	-1	; Next header in list (-1=end)
.IFS_NAME	DB	"        " ; IFS name
.IFS_ATTRIBUTE	DW	0	; Attributes
.IFS_VERSION	DW	0	; Request level supported
IFS_DOSCALL@	DD	0	; DOS interface routine
				;   (set by TUPPER before the init call)
IFS_CALL@	DW	0	; Function entry point
}
match =IFSHEADER_LAID_OUT, IFSHEADER_LAID_OUT
{
    IFSHEADER_LAID_OUT equ 1
    virtual at 0
      IFSHEADER IFSHEADER
      sizeof.IFSHEADER = $ - IFSHEADER
    end virtual
}

;=====================
; IFS Request Header
;=====================

; Filled in where it stands, so the fields are the macro's arguments,
; each defaulting to what the structure declares.
STRUC IFSRH IFSR_LENGTH_=0,IFSR_FUNCTION_=0,IFSR_RETCODE_=0,IFSR_RETCLASS_=0
{
.IFSR_LENGTH	DW    IFSR_LENGTH_; Total length of request
.IFSR_FUNCTION	DB    IFSR_FUNCTION_; Requested function
.IFSR_RETCODE	DB    IFSR_RETCODE_; Explicit error
.IFSR_RETCLASS	DB    IFSR_RETCLASS_; Error class
.IFSR_RESV1	DB    17 dup(0) 	; DOS reserved
.IFSR_FCN_PARMS	DB    38 dup(0) 	; Additional parameters
}
match =IFSRH_LAID_OUT, IFSRH_LAID_OUT
{
    IFSRH_LAID_OUT equ 1
    virtual at 0
      IFSRH IFSRH
      sizeof.IFSRH = $ - IFSRH
    end virtual
}

; IFSR_FUNCTION codes
;	Control requests:
IFSINIT        EQU     1
IFSATTSTART    EQU     2
IFSATTEND      EQU     3
IFSEXECAPI     EQU     4
IFSCRITMSG     EQU     5
IFSCBUPDATE    EQU     6
; INIT function.
; Two more names for places inside the request packet, read as a dword and
; as a word; in fasm the size goes on the instruction, so these are the
; offsets alone.  The length below took the structure's own name for the
; start of it, which is 0.
IFSR_PARMS@	   =  IFSRH.IFSR_FCN_PARMS    ; command parameters
IFSR_RESSIZE	   =  IFSRH.IFSR_FCN_PARMS+4  ; driver total size
LENGTH_INIT	   EQU IFSR_RESSIZE+2

