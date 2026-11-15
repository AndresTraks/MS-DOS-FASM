PAGE	,132
TITLE	DOS - CONSOLE Code Page Switching Device Driver
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  FILENAME:	 DISPLAY.ASM
;  PROGRAM:	 DISPLAY.SYS (Main module)
;  LINK PROCEDURE:  Linkk
;  INSTALLATION:
;
;  This routine is structured as a DOS Device Driver.
;  IE it is installed via the CONFIG.SYS command:
;	 DEVICE=DISPLAY.SYS
;
;  The following device commands are supported:
;
;  00 hex - INIT
;  -------------
;  Install the CON device driver.  This is used for downloading of
;  the character sets (various Code Pages) according to the respective
;  display adapter.  The interface provided by the video BIOS is used
;  to download a block of 256 characters (in various resolutions - ie.
;  8x8, 8x14, and 8x16).  Also, the interrupt 2F hex is chained for
;  communication between the CON device driver and the keyboard routine.
;
;  Refer to INIT.ASM for code
;
;  13 hex - GENERIC IOCTL
;  ----------------------
;  INVOKE
;  ------
;  Invoke is use to activate the appropriate CP font.  The mechanism
;  is based soley on the code page value passed from the MODE & CHCP
;  commands.  Once a CP ahs benn INVOKED, it is loaded for ALL display
;  modes on the respective display adapter - ONLY IF the proper font
;  resolution can be accessed.
;
;  Refer to CPS-FUNC.INC for code
;
;  DESIGNATE START
;  ---------------
;  Designate start passes the list of designated code pages to load.
;  It is sent just prior to the IOCTL WRITE calls containing the 'CPI'
;  files.  The list of designated code pages is check for duplicates
;  and for invalids (-1).
;
;  Refer to CPS-FUNC.INC for code
;
;  DESIGNATE STOP
;  --------------
;  Once the data (for a DESIGNATION) has been routed to the CPS driver,
;  it is followed by a DESIGNATE STOP command.	This confirms the completion
;  of the DESIGNATE procedure.	If there was an error detected during the
;  DESIGNATE procedure, it must be followed by a DESIGNATE STOP.
;
;  Refer to CPS-FUNC.INC for code
;
;
;  0C hex - IOCTL OUTPUT
;  ---------------------
;  Following a DESIGNATE START, the contents of the specified data file
;  (expected .CPI format) is copied by DOS to the CPS driver.  This is
;  via the GENERIC IOCTL WRITE calls.  During these calls, the data is
;  parsed by the FONT-PARSER (F-PARSER.SRC) to select the CP and fonts
;  required.
;
;  Refer to CPS-FUNC.INC for code
;
;
;		 (C)Copyright 1988 Microsoft
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      Request Header (Common portion)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IF1					;
;	%OUT .Compiling:     DISPLAY.ASM
;	%OUT .		     ô CPS-CON driver
;	%OUT .		     õ Version 3.30
;	%OUT .Include Files:
;ENDIF					;
	include 'MACROS.INC' ;
	include 'DEF-EQU.INC' ;
					;
;	PUBLIC	EOF_MARKER		;
;	PUBLIC	CPD_ACTIVE		;
;	PUBLIC	CPD_CLASS		;
;	PUBLIC	CPD_HDWR_N_MAX		;
;	PUBLIC	CPD_DESG_N_MAX		;
;	PUBLIC	CPD_HDWR_N		;
;	PUBLIC	CPD_DESG_N		;
;	PUBLIC	CPD_FONTS_N		;
;	PUBLIC	CPD_FONT_PNTER		;
;	PUBLIC	IRPT_2			;
;	PUBLIC	IRPT_CMD_EXIT		;
;	PUBLIC	DEV_HDR 		;
;	EXTRN	INIT:NEAR		;
					;
;CODE	SEGMENT BYTE PUBLIC 'CODE'      ;
;	ASSUME	CS:CODE,DS:CODE 	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;****************************************
;**	    Resident Code	       **
;****************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
START	=	$			; begin resident data & code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DEVICE HEADER - must be at offset zero within device driver
;		  (DHS is defined according to this structure)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ORG	0000H			    ;
					    ;
DEV_HDR:DD    -1			    ; Pointer to next device header
	DW	0C053H			    ; Attribute (Char device)
	DW	STRATEGY             ; Pnter to device "strategy"
	DW	INTERRUPT            ; Pnter to device "interrupt"
	DB	'CON     '                  ; Device name
					    ; and of course a descriptive name
					    ; which can be viewed by a TYPE!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Console Description Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.XLIST					;
STACK_END	DW  1FFH+60H DUP(0)	; 200H + 'my' needs (re/ DOS 3.30 ref)
STACK_START	DW  0			;
OLD_STACK_S	rw      1 ;
OLD_STACK_O	rw      1 ;
.LIST					;
					;
BUF1	    BUF_DATA      ; exclude PAR_EXTRACTO
					;
CP_PNTER_TABLE	DW CPD_HDWR_N        ; TABLE OF POINTERS TO CP INFO
		DW CPD_DESG_N        ;
		DW CPD_FONT_PNTER       ;
		DW CPD_FONT_WRITE       ;
		DW CPD_FONT_DATA        ;
					;
label CPD_TABLE word  ; TABLE DATA INFO FOR CP's
CPD_ACTIVE	DW     -1		; TEMPORARY
CPD_CLASS	DB	'........'      ; THIS IS SET TO (EGA, LCD)
CPD_FONTS_N	DW     -1		;
CPD_HDWR_N	DW	0		;
		DW  12	DUP(-1) 	; (HDWR_CP's)    (MAX=12)
CPD_HDWR_N_MAX	= (($-CPD_HDWR_N)/2-1)	;
CPD_DESG_N	DW     -1		; # OF DESIG CP's
		DW  12	DUP(-1) 	; (DESG CP's)    (MAX=12)
CPD_DESG_N_MAX	= (($-CPD_DESG_N)/2-1)	;
CPD_FONT_PNTER	DW  12	DUP(0,0)	; SEG_OFFSET POINTER TO DATA BUFFERS
CPD_FONT_WRITE	DW  12	DUP(0,0)	; SEG_OFFSET OF FONTS BEING WRITTEN
CPD_FONT_DATA	DW  12	DUP(0)		; COUNT OF FONT DATA TO SKIP/COPY!
FONT_PRIORITY	DB  8	DUP(-1) 	; USED TO CLASSIFY FONT PRIORITY
NUM_FONT_PRIORITY = (($-FONT_PRIORITY))	; DURING A DESIGNATION
CPD_TEMP_DESG	DW	0		; # OF DESIG CP's TEMP BUFFER
		DW  12	DUP(-1) 	; (DESG CP's)    (MAX=12)
CPD_REQ_DESG	DW	0		; # OF DESIG CP's REQUESTED
		DW  12	DUP(-1) 	; (DESG CP's)    (MAX=12)
;;;;;;;

ANSI_DA_INFO	DA_INFO_PACKET    ;J.K. Information packet to ANSI used for MODE SET INT10 call.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      CON Device "strategy" entry point
;      Retain the Request Header address for use by Interrupt routine
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	ASSUME	DS:NOTHING		;
STRATEGY:            ;
	PUSH	BX			;
	PUSH	BX			;
	LEA	BX,[BUF1] ; BUF = BUF1  CS:[BX]
	POP	word [BUF+BUF_DATA.RH_PTRO] ; OFFSET OF REQUEST HEADER
	MOV	word [BUF+BUF_DATA.RH_PTRS],ES ; SEGMENT
	POP	BX			;
	RETF   ;
;STRATEGY  ENDP				;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      Table of command processing routine entry points
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
label CMD_TABLE word   ;
	DW	INIT         ;  0 - Initialization
	DW	NO_OPERATION        ;  1 - Media check
	DW	NO_OPERATION        ;  2 - Build BPB
	DW	NO_OPERATION        ;  3 - IOCTL input
	DW	NO_OPERATION        ;  4 - Input
	DW	NO_OPERATION        ;  5 - Non destructive input no wait
	DW	NO_OPERATION        ;  6 - Input status
	DW	NO_OPERATION        ;  7 - Input flush
	DW	NO_OPERATION        ;  8 - Write
	DW	NO_OPERATION        ;  9 - Output with verify
	DW	NO_OPERATION        ;  A - Output status
	DW	NO_OPERATION        ;  B - Output flush
	DW	DESG_WRITE        ;  C - IOCTL output
	DW	NO_OPERATION        ;  D - Device OPEN
	DW	NO_OPERATION        ;  E - Device CLOSE
	DW	NO_OPERATION        ;  F - Removable media
	DW	NO_OPERATION        ; 10 - Removable media
	DW	NO_OPERATION        ; 11 - Removable media
	DW	NO_OPERATION        ; 12 - Removable media
	DW	GENERIC_IOCTL        ; 13 - Removable media
MAX_CMD =	(($-CMD_TABLE)/2)	; highest valid command follows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CON Device "interrupt" entry point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INTERRUPT:            ; device interrupt entry point
	PUSH	AX			;
	PUSH	BX			;
	PUSH	CX			;
	PUSH	DI			;
	PUSH	SI			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Common interrupt entry :
; at entry, BUFn (CS:BX) of CON is defined
;
; Check if header link has to be set
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LEA	BX,[BUF1] ;
	MOV	DI,DEV_HDR        ; CON Device header
					;
	MOV	word [BUF+BUF_DATA.DEV_HDRO],DI ;
	MOV	word [BUF+BUF_DATA.DEV_HDRS],CS ;
	CLD				; all moves forward
					;
	CMP	word [BUF+BUF_DATA.CON_STRAO], -1 ;
	JNE	L4			; has been linked to DOS CON
	CMP	word [BUF+BUF_DATA.CON_STRAS], -1 ;
	JNE	L4			; has been linked to DOS CON
					;  next device header :  ES:[DI]
	LDS	SI,dword [BUF+BUF_DATA.DEV_HDRO] ;
	LES	DI,dword [HP+DHS.DH_NEXTO] ;
					;
;SEARCH$ WHILE				;  pointer to next device header is NOT
L1:					;
	PUSH	ES			;  -1
	POP	AX			;
	CMP	AX,-1			;
;LEAVE$  E,	 AND			; leave if both offset and segment are
	JNE	NOT0FFFF		;
					;
	CMP	DI,-1			;  0FFFFH
;LEAVE$  E				;
	JE	L4			;
NOT0FFFF:				;
	PUSH	DI			;
	PUSH	SI			;
	MOV	CX,NAME_LEN		;
	LEA	DI,[NHD+DHS.DH_NAME] ;
	LEA	SI,[HP+DHS.DH_NAME] ;
	REPE	CMPSB			;
	POP	SI			;
	POP	DI			;
	AND	CX,CX			;
;EXITIF$ Z				; Exit if name is found in linked hd.
	JNZ	L3			; Name is not found
					; Name is found in the linked header
	MOV	AX,word [NHD+DHS.DH_STRAO] ; Get the STRATEGY address
	MOV	word [BUF+BUF_DATA.CON_STRAO],AX ;
	MOV	AX,ES			;
X1:	MOV	word [BUF+BUF_DATA.CON_STRAS],AX ;
					;
	MOV	AX,word [NHD+DHS.DH_INTRO] ; Get the INTERRUPT address
	MOV	word [BUF+BUF_DATA.CON_INTRO],AX ;
	MOV	AX,ES			;
X2:	MOV	word [BUF+BUF_DATA.CON_INTRS],AX ;
					;
;ORELSE$				; FInd next header to have the same
	JMP	L4			; Device Name
L3:					;
	LES	DI,dword [NHD+DHS.DH_NEXTO] ;
;ENDLOOP$				;
	JMP	L1			;
L4:					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; COMMAND REQUEST
;      ES:DI  REQUEST HEADER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ; GET RH ADDRESS PASSED TO
					; "STRATEGY"  INTO ES:DI
	MOV	AL,byte [RH+RHC.RHC_CMD] ; COMMAND CODE FROM REQUEST HEADER
	CBW				; ZERO AH (IF AL > 7FH, NEXT COMPARE
					; WILL CATCH THAT ERROR)
	CMP	AL,MAX_CMD		; IF COMMAND CODE IS TOO HIGH
	JAE	L6			; JUMP TO ERROR ROUTINE
					;
	ADD	AX,AX			; DOUBLE COMMAND CODE FOR TABLE OFFSET
	MOV	SI,AX			; PUT INTO INDEX REGISTER FOR JMP
					;
	CALL	[cs:CMD_TABLE+SI] ; CALL ROUTINE TO HANDLE THE COMMAND
	JC	IRPT_CMD_EXIT		; CY=1 IF NO PASS_CONTROL REQ'D
	CALL	PASS_CONTROL		;
	JUMP	IRPT_2			;
					;
L6:	CALL	PASS_CONTROL		; CALL ROUTINE TO HANDLE THE COMMAND
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  At entry to command processing routine
;
;      ES:DI   = Request Header address
;      CS:BX   = Buffer for CON
;      CS      = code segment address
;      AX      = 0
;
;      top of stack is return address, IRPT_CMD_EXIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IRPT_CMD_EXIT:				; RETURN FROM COMMAND ROUTINE
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ; RESTORE ES:DI AS REQUEST HEADER PTR
	XOR	AX,AX			;
	OR	AX,word [BUF+BUF_DATA.STATUS] ;
	JE	IRPT_0			;
	XOR	word [BUF+BUF_DATA.STATUS],AX ; SET STATUS BACK TO OK!
	OR	AX,STAT_CMDERR		;
	JUMP	IRPT_1			;
IRPT_0: OR	AH,STAT_DONE		; ADD "DONE" BIT TO STATUS WORD
IRPT_1: MOV	word [RH+RHC.RHC_STA],AX ; STORE STATUS INTO REQUEST HEADER
IRPT_2: POP	SI			; RESTORE REGISTERS
	POP	DI			;
	POP	CX			;
	POP	BX			;
	POP	AX			;
	RETF   ;
;INTERRUPT  ENDP 			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	PASS CONTROL
;
;	This calls the attached device to perform any further
;	action on the call!
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PASS_CONTROL:       ;
	PUSH	BX			;
	PUSH	BX			;
	POP	SI			;
	LES	BX,dword [BUF+BUF_DATA.RH_PTRO] ; pass the request header to the
	CALL	dword [cs:SI+BUF_DATA.CON_STRAO] ; CON strategy routine.
	POP	BX			;
	CALL	dword [BUF+BUF_DATA.CON_INTRO] ; interrupt the CON
	RET				;
;PASS_CONTROL	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NO_OPERATION:       ;
	CLC				;
	RET				;
;NO_OPERATION	ENDP			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	PULL IN THE CODE PAGE FUNCTION CODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	include 'INT2FCOM.INC' ;
	include 'INT10COM.INC' ;
	include 'CPS-FUNC.INC' ;
	include 'WRITE.INC' ; SPECIAL MARKER IN WRITE.INC
	include 'F-PARSER.INC' ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      Adjust the assembly-time instruction counter to a paragraph
;      boundary
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	IF	($-START) MOD 16	;
	  times (($-START)+16-(($-START) MOD 16)) - $ db 0 ;
	end if ;
EOF_MARKER   = $			; end of resident code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	END-OF-CODE
;
;;;;;;;;;;;;;;;;;
;CODE	ENDS	;
;	END	;
;;;;;;;;;;;;;;;;;
