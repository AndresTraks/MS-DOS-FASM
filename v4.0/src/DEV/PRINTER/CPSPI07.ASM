
	PAGE	,132

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  FILENAME:		CPS Printer Device Driver INIT module (CPSPInn)
;;  MODULE NAME:
;;  TYPE:		Assemble file  (non-resident code)
;;  LINK PROCEDURE:	Link CPSPMnn+CPSFONT+CPSPInn into .EXE format. CPSPM01
;;			must be first.	CPSPInn must be last.  Everything
;;			before CPSPInn will be resident.
;;  INCLUDE FILES:
;;			CPSPEQU.INC
;;
;;  LAYOUT :		This file is divided into two main section :
;;			  ++++++++++++++++++++++++
;;			  ++	DEVICE Parser	++
;;			  ++++++++++++++++++++++++
;;
;;			  ++++++++++++++++++++++++
;;			  ++	INIT Command	++
;;			  ++++++++++++++++++++++++
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
include 'CPSPEQU.INC' ;;
INT2F_LOW	equ	((4*2FH))	;; WGR interrupt 2F vector location	    ;AN000;
INT2F_HI	equ	((4*2FH)+2)	;; WGR					    ;AN000;
					;;
.XLIST					;;
include 'SYSMSG.INC' ;; WGR					    ;AN000;
.LIST					;;
					;;
MSG_UTILNAME <PRINTER>			;; WGR					    ;AN000;
					;;
;PUBLIC	INIT				;;
;PUBLIC	CODE_END			;; for MAP listing only
;PUBLIC	RESIDENT_END			;;
;PUBLIC	STACK_ALLOCATED 		;;
					;;
					;;
;EXTRN	PRINTER_DESC_NUM:WORD		;;
;EXTRN	PRINTER_DESC_TBL:WORD		;;
;EXTRN	INIT_CHK:WORD,TABLE:WORD	;;
;EXTRN	HARD_SL1:BYTE,RAM_SL1:BYTE	;;
;EXTRN	HARD_SL2:BYTE,RAM_SL2:BYTE	;;
;EXTRN	HARD_SL3:BYTE,RAM_SL3:BYTE	;;
;EXTRN	HARD_SL4:BYTE,RAM_SL4:BYTE	;;
;EXTRN	RESERVED1:WORD,RESERVED2:WORD	;;
					;;
					;;
					;;
;CSEG	SEGMENT PARA PUBLIC 'CODE'      ;;
;	ASSUME	CS:CSEG 		;;
					;;
					;;
;EXTRN	PARSER:NEAR			;; WGR					    ;AN000;
;EXTRN	ROM_INT2F:WORD			;; WGR					    ;AN000;
;EXTRN	INT2F_COM:NEAR			;; WGR					    ;AN000;
;EXTRN	ABORT:BYTE			;; WGR					    ;AN000;

; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
CODE_END     = $			;; end of resident code
					;;
	     DW  0			;; -- there are 16 bytes kept,
					;;    including this word
					;;
RESIDENT_END DW  0FFFH			;; end of extended resident area
STACK_ALLOCATED  DW -1			;; end of extended resident area
					;;
	     DW  150 DUP(0)		;; need some space here.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	End of resident code
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;			  ++++++++++++++++++++++++
;;			  ++	INIT Command	++
;;			  ++++++++++++++++++++++++
;;
;;====	Command Code 0 - Initialization  ======
;;
;; messages returned :
;;
;; msg_bad_syntax  -- syntax error from parser, no driver installation
;; msg_no_init	   -- device cannot be initialised
;; msg_insuff_mem  -- insufficient memory
;;
;; layout :	the initialization is done in two stages :
;;
;;		  ++++++++++++++++++++++++
;;		  ++   INIT Stage 1	++	to examine and extract the
;;		  ++++++++++++++++++++++++	parameters defined for the
;;						device_id in DEVICE command,
;;						according to the printer
;;						description table for the
;;						device_id.
;;
;;		  ++++++++++++++++++++++++
;;		  ++   INIT Stage 2	++	to set the BUFfer for the LPTn
;;		  ++++++++++++++++++++++++	or PRN according to device_id's
;;						parameters
;;
;;
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
					;;
DEV_NUM rw      1 ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;     Tables for the deivce_id parameters in the order of device_id in the
;     PARSE table
;     === the tables serves as the link between LPTn to be defined in the 2nd
;	  stage, and the device_id that is processed in the first stage.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; device ID indicators :
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DID_MAX EQU	4			;; device entris exepcted in PARSE
;; not more than 16.			;; table
					;;
DID_STATUS DW	0			;; status of parsing device id
					;;  =  0 : all Device-ID bad
					;;  -- see DID_BIT
					;;
DID_MATCH  DW	0			;; this DID has device_name matched
					;;
DID_FAIL   DW	0			;; to fail the good DID_STATUS and
					;; the matched name. (due to
					;; inconsistency among the same LPTn
					;; or between PRN and LPT1.)
					;;
;; (DID_STATUS) AND (DID_MATCH) XOR (DID_FAIL) determines the success of DID
					;;		       initialization
					;;
DID_ONE EQU	00001H			;; first device-ID
DID_TWO EQU	00002H			;; second "
DID_THREE EQU	  00004H		;; third  "
DID_FOUR  EQU	  00008H		;; fourth "
;;maximun number of device_id = 16	;;
					;;
label DID_BIT word   ;;
	DW	DID_ONE 		;;
	DW	DID_TWO 		;;
	DW	DID_THREE		;;
	DW	DID_FOUR		;;
;;maximun number of device_id = 16	;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; device paramters according to the
					;; device_id defined in DEVICE and the
					;; parameters defined for the device_id
					;; in the printer description table.
					;;
label HRMAX word   ;; number of hwcp+cart slots supported
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
label CTMAX word   ;; number of cart slots supported
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
label RMMAX word   ;; number of ram-slots supported
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
label RBUMAX word   ;; number of ram-designate slots
	DW	0			;;  did = 1
	DW	0			;;  did = 2
	DW	0			;;  did = 3
	DW	0			;;  did = 4
;upto max  DID_MAX			;;
					;;
label DESCO word   ;; offset to the description table
					;; where the device_id is defined.
	DW	-1			;;  did = 1
	DW	-1			;;  did = 2
	DW	-1			;;  did = 3
	DW	-1			;;  did = 4
;upto max  DID_MAX			;;
					;;
label FSIZE word   ;; font size of the device
	DW	 0			;;  did = 1
	DW	 0			;;  did = 2
	DW	 0			;;  did = 3
	DW	 0			;;  did = 4
;upto max  DID_MAX			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Hard/RAM slots table in the order of DEVICE parameters
;
;   number of entries in all HARD_SLn is determined by the max. {HSLOTS}, and
;   number of entries in all RAM_SLn  is determined by the max. {RSLOTS}
;
;   -- they are initialized according to the device_id defined in the DEVICE.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
label HARD_SLA word   ;; index in the order of device in
	DW	HARD_SL1        ;; the PARSE-talbes
	DW	HARD_SL2        ;;
	DW	HARD_SL3        ;;
	DW	HARD_SL4        ;;
; up to DID_MAX 			;;
					;;
label RAM_SLA word   ;;
	DW	RAM_SL1        ;;
	DW	RAM_SL2        ;;
	DW	RAM_SL3        ;;
	DW	RAM_SL4        ;;
; up to DID_MAX 			;;
					;;
SUB_SIZE	EQU	11		;; WGR sublist size			    ;AN000;
LEFT_ASCIIZ	EQU	00010000B	;; WGR left-aligned asciiz string	    ;AN000;
UNLIMITED	EQU	0		;; WGR unlimited message size.		    ;AN000;
					;; WGR					    ;AN000;
label SUBLIST dword   ;; WGR					    ;AN000;
	DB	SUB_SIZE		;; WGR					    ;AN000;
	DB	0			;; WGR					    ;AN000;
MSG_PTR rw      1 ;; WGR					    ;AN000;
MSG_SEG DW	CSEG		;; WGR					    ;AN000;
	DB	1			;; WGR					    ;AN000;
	DB	LEFT_ASCIIZ		;; WGR					    ;AN000;
	DB	UNLIMITED		;; WGR					    ;AN000;
	DB	1			;; WGR					    ;AN000;
	DB	" "                     ;; WGR                                      ;AN000;
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	 ++++++++++++++++++++++++
;;	 ++    INIT Command    ++
;;	 ++++++++++++++++++++++++
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
INIT:            ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; parse the initialization parameters in DEVICE command
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
	PUSH	BX			;; WGR					    ;AN000;
	CALL	SYSLOADMSG		;; WGR load messages			    ;AN000;
	JNC	CONT_1			;; WGR if no error then continue	    ;AN000;
	CALL	SYSDISPMSG		;; WGR error (DOS version)..display	    ;AN000;
	POP	BX			;; WGR message....			    ;AN000;
	JMP	SYNTAX_ERROR		;; WGR ...and exit with error code.	    ;AN000;
					;; WGR					    ;AN000;
CONT_1: 				;; WGR					    ;AN000;
	POP	BX			;; WGR					    ;AN000;
	CMP	word [BUF+BUF_DATA.BFLAG],BF_PRN ;; since PRN is the FIRST device header
	JNE	NOT_PRN 		;;
					;;
					;;
	MOV	AX,CODE_END        ;; defined only once for each DEVICE
	XOR	CX,CX			;;
	MOV	CL,4			;;
	SHR	AX,CL			;;
	PUSH	CS			;;
	POP	CX			;;
	ADD	AX,CX			;;
	INC	AX			;; leave 16 bytes,room for resident_end
	MOV	[cs:RESIDENT_END],AX ;;
					;;
	CALL	PARSER			;; call only once, for PRM
					;;
	JMP	PROCESS_TABLE		;;
					;;
NOT_PRN :				;;
	CMP	word [cs:DEV_NUM],1 ;;
					;;
	JNB	PROCESS_TABLE		;;
					;;
	JMP	SYNTAX_ERROR		;;
					;;
					;;
					;;
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;	 ++++++++++++++++++++++++
;;	 ++   INIT Stage 1     ++
;;	 ++++++++++++++++++++++++
;;
;;  INIT - FIRST STAGE :
;;
;;    == test and extract if the parameters on device-id is valid
;;    == determine the DID_STATUS according to the validity of the parameters
;;    == procedure(s) called -- DID_EXTRACT
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
					;;
PROCESS_TABLE : 			;;
					;;
	PUSH	CS			;;
	POP	ES			;; PSE points to Device offsets
	MOV	DI,TABLE        ;; ES:[DI]
	MOV	DX,word [PSE+PAR_OT.PAR_DEV_NUM] ;;
	MOV	[cs:DEV_NUM],DX ;;
					;;
	CMP	word [cs:DEV_NUM],0 ;;
	JNZ	NO_SYNTAX_ERR		;;
					;;
					;; WGR					    ;AN000;
	PUSH	BX			;; WGR					    ;AN000;
	MOV	AX,BAD_SYNTAX_MSG	;; WGR 'bad syntax' message                 ;AN000;
	MOV	BX,STDERR		;; WGR	to standard error		    ;AN000;
	XOR	CX,CX			;; WGR					    ;AN000;
	XOR	DL,DL			;; WGR					    ;AN000;
	MOV	DH,UTILITY_MSG_CLASS	;; WGR class = parse error		    ;AN000;
	CALL	SYSDISPMSG		;; WGR display message. 		    ;AN000;
	POP	BX			;; WGR					    ;AN000;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SYNTAX_ERROR :				;; set the request header status
					;; according to the STATE
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	AX, [cs:RESIDENT_END] ;;
	PUSH	CS			;;
	POP	CX			;; CX=CS
	SUB	AX,Cx			;; additional segment required.
CS_LOOP1:				;;
	CMP	AX,1000H		;;
	JB	CS_LPEND1		;;
	ADD	CX,1000H		;;
	SUB	AX,1000H		;;
	JMP	CS_LOOP1		;;
					;;
CS_LPEND1:				;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
					;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;; get Request Header address
;	MOV	RH.RH0_ENDO,AX		;;
	MOV	word [RH+RH0.RH0_ENDO],0 ;;
	MOV	word [RH+RH0.RH0_ENDS],CX ;;
	mov	word [RH+RH0.RH0_CONFIG_ERRMSG], -1 ;DCR D493 2/25/88 "Error in CONFIG.SYS..." msg flag.
	MOV	word [RH+RHC.RHC_STA],STAT_CMDERR ;; set status in request header
					;;
	JMP	INIT_RETURN		;;
					;;
					;;
NO_SYNTAX_ERR : 			;;
					;;
	CMP	DX,DID_MAX		;;
	JNA	NEXT_DID		;;
					;;
	MOV	word [cs:INIT_CHK],0001H ;; ERROR 0001
	JMP	BAD_DID 		;; more than supported no. of device
					;;
NEXT_DID:				;;
	PUSH	DI			;; pointer to PAR_OT (table 1)
	AND	DX,DX			;;
	JNZ	SCAN_DESC		;;
	JMP	END_DID 		;; DI = offset to the 1st PARSE table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCAN_DESC:				;;
	MOV	DI,word [PSE+PAR_OT.PAR_OFF] ;; points to the nth device
					;;
					;; find the description for the
					;;device-id
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	CX,[cs:PRINTER_DESC_NUM] ;;
	MOV	SI, PRINTER_DESC_TBL       ; offset to the description table
	PUSH	CS			;;
	POP	DS			;;
;	SEARCH$ 			;;
DO1$$:
	    PUSH    CX			;; save device count
	    PUSH    SI			;; pointer to printer-descn's offset
	    MOV     SI,word [cs:SI]    ;;
	    AND     CX,CX		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	LEAVE$	Z			;; LEAVE if no more device description
	JZ EN1$$
	    PUSH    DI			;; save offset to PAR_DEVOT
	    MOV     DI,word [PSE+PAR_DEVOT.PAR_DIDO] ;;
	    MOV     CX,word [PSE+PAR_DIDT.PAR_DIDL] ;; length of parsed device name
	    LEA     DI,[PSE+PAR_DIDT.PAR_DID] ;; pointer to parse device name
					;;
	    PUSH    SI			;;
	    LEA     SI,[SI+PDSH.TYPEID] ;; offset to name of device-id
	    REPE    CMPSB		;;
	    POP     SI			;;
	    POP     DI			;; get back offset to PAR_DEVOT
					;;;;;;;;;;;;;;;;;;;;;;;;
;	EXITIF$ Z			;; EXIT if name matched
	JNZ IF1$$
					;;
	    CALL    DID_EXTRACT 	;; get the parameters
					;;
	    POP     SI			;; balance push-pop
	    POP     CX			;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	ORELSE$ 			;; try next description :
	JMP SHORT SR1$$
IF1$$:
					;;
	    POP     SI			;; of printer_descn offset table
	    INC     SI			;;
	    INC     SI			;; next offset to PRINTER_DESCn
					;;
	    POP     CX			;; one description less
	    DEC     CX			;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	ENDLOOP$			;; DEVICE-ID not defined in
	JMP SHORT DO1$$
EN1$$:
					;; printer_desc;
					;;
	    MOV     AX,[cs:INIT_CHK] ;;
	    AND     AX,AX		;;
	    JNZ     UNCHANGED		;;
	    MOV     word [cs:INIT_CHK],0004H ;; ERROR 0004
UNCHANGED:				;;
	    POP     SI			;; balance push-pop
	    POP     CX			;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	ENDSRCH$			;; End of scanning printer_desc
SR1$$:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	POP	DI			;;
	INC	DI			;;
	INC	DI			;; points to next device in PART_OT
	DEC	DX			;;
					;;
	JMP	NEXT_DID		;;
					;;
END_DID :				;;
	POP	DI			;;
BAD_DID :				;;
					;;
	MOV	AX,[cs:DID_STATUS] ;;
	AND	AX,AX			;;
	JNZ	DEF_BUFFER		;;
					;;
	JMP	END_LPT 		;;
					;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;	++++++++++++++++++++++++
;;	++   INIT Stage 2     ++
;;	++++++++++++++++++++++++
;;
;; INIT -- SECOND STAGE :
;;
;;	== match the device_name extracted in stage 1 with the name of PRN or
;;	   LPTn
;;
;;	== if the PRN/LPTn has never been defined before, then set up the BUF
;;	   for the PRN/LPTn if the DID_STATUS is good; otherwise message will
;;	   be generated indicating it cannot be initilized.
;;
;;	== if there is PRN, LPT1 is also setup, and vice vera. IF both PRN and
;;	   LPT1 are on the DEVICE command, or there are multiple entries for
;;	   the same LPTn, the consistency is checked. It they are inconsistent
;;	   the associated LPTn or PRN is forced to fail by : DID_FAIL.
;;
;;	== if the device_name on the DEVICE command is not one of the supported
;;	   PRN or LPTn, then DID_MATCH bit will not be set. An error message
;;	   will be generated for the device_name indicating it cannot be
;;	   initialized.
;;
;;	== procedure(s) called : CHK_DID   .. check DID parameters for device
;;					      whose name matched.
;;				 DEV_CHECK .. if device-name duplicated, or
;;					      there are both PRN/LPT1 : check
;;					      for consistent parameters.
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DEF_BUFFER :				;;
	PUSH	CS			;;
	POP	ES			;; PSE points to Device offsets
	MOV	DI,TABLE        ;; ES:[DI]
	xor	cx,cx			;; device order in parse table
;SEARCH 				;;
DO7$$:
	    PUSH    DI			;; pointer to PAR_OT
	    PUSH    CX			;; save device count
	    MOV     DI,word [PSE+PAR_OT.PAR_OFF] ;;   "     "  PAR_DEVOT
	    cmp     cx,[cs:DEV_NUM] ;;
					;;
;LEAVE NB				;; LEAVE if no more device entry
	   jb	    MORE_DEVICE 	;;
	   JMP	    EN7$$
MORE_DEVICE :				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; more parsed_device to be checked
	    PUSH    DI			;; save offset to PAR_DEVOT
	    MOV     DI,word [PSE+PAR_DEVOT.PAR_DNMO] ;;
	    MOV     CX,word [PSE+PAR_DNMT.PAR_DNML] ;; length of parsed device name
	    LEA     DI,[PSE+PAR_DNMT.PAR_DNM] ;; pointer to parse device name
					;;
	    LDS     SI,dword [BUF+BUF_DATA.DEV_HDRO] ; get the offset to device-n header
	    LEA     SI,[HP+DHS.DH_NAME] ;; "       offset to name of device-n
	    REPE    CMPSB		;;
	    POP     DI			;; get back offset to PAR_DEVOT
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;
;EXITIF Z				;; EXIT if name matched
	JZ  NAME_MATCHED		;;
					;;
	JMP MORE_PARSED_DEVICE		;;
					;;
NAME_MATCHED :				;;
					;;
	    POP     CX			;; the DID order
	    PUSH    BX			;;
	    MOV     BX,CX		;;
	    ADD     BX,BX		;;
	    MOV     AX,[cs:BX+DID_BIT] ;;
	    OR	    [cs:DID_MATCH],AX ;; this DID matched
	    POP     BX			;;
	    PUSH    CX			;;
					;;
	    LEA     SI,[BUF+BUF_DATA.PAR_EXTRACTO] ;; was the LPT1/PRN defined before ?
	    MOV     AX,[cs:SI+PAR_DEVOT.PAR_DNMO] ;;
	    CMP     AX,0FFFFH		;;
					;;
	    JNE     DEV_COMPARE 	;; DI = PAR_DEVOT
					;;-----------------------------------
					;;
					;; no device previousely defined
	    MOV     AX,word [PSE+PAR_DEVOT.PAR_DNMO] ;;
	    MOV     [cs:SI+PAR_DEVOT.PAR_DNMO],AX ;; define device parameters for LPTn
					;;
	    MOV     AX,word [PSE+PAR_DEVOT.PAR_DIDO] ;;
	    MOV     [cs:SI+PAR_DEVOT.PAR_DIDO],AX ;;
					;;
	    MOV     AX,word [PSE+PAR_DEVOT.PAR_HWCPO] ;;
	    MOV     [cs:SI+PAR_DEVOT.PAR_HWCPO],AX ;;
					;;
	    MOV     AX,word [PSE+PAR_DEVOT.PAR_DESGO] ;;
	    MOV     [cs:SI+PAR_DEVOT.PAR_DESGO],AX ;;
					;;
	    MOV     AX,word [PSE+PAR_DEVOT.PAR_PARMO] ;;
	    MOV     [cs:SI+PAR_DEVOT.PAR_PARMO],AX ;;
					;;
					;;---------------------------------
	    CALL    CHK_DID		;; define the STATE according to
					;; DID_STATUS
	    JMP     MORE_PARSED_DEVICE	;;
					;;
DEV_COMPARE :				;;-------------------------------
					;; e.g. LPT1 and PRN shares one BUF.
					;;	or duplicated device name
	    CALL    DEV_CHECK		;;
					;;
	    CMP     word [BUF+BUF_DATA.STATE],CPSW ;;
	    JNE     DEV_COMPARE_FAIL	;;
					;;
	    JMP     MORE_PARSED_DEVICE	;;
					;;
DEV_COMPARE_FAIL :			;;
					;;
	    POP     CX			;;
	    POP     DI			;; balance push-pop
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ORELSE$				;;
	JMP	  END_LPT
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MORE_PARSED_DEVICE :			;; name does not match
					;;
	    POP     CX			;;
	    INC     CX			;;
	    POP     DI			;;
	    INC     DI			;;
	    INC     DI			;; points to next device in PART_OT
					;;
	    jmp     DO7$$		;;
;ENDLOOP$				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EN7$$:					;; no device found for LPTn
					;;
	    POP     CX			;;
	    POP     DI			;; balance push-pop
					;;
	    CMP     word [BUF+BUF_DATA.STATE],CPSW ;;
	    JE	    END_LPT		;; for LPT1/PRN pair
					;;
	    MOV     word [BUF+BUF_DATA.STATE],NORMAL ;; no device defined for the LPTn
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; End of defining LPTn Buffer
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ENDSRCH$				;;
END_LPT :				;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; set the request header status
					;; according to the STATE
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	AX, [cs:RESIDENT_END] ;;
	PUSH	CS			;;
	POP	CX			;; CX=CS
	SUB	AX,Cx			;; additional segment required.
CS_LOOP2:				;;
	CMP	AX,1000H		;;
	JB	CS_LPEND2		;;
	ADD	CX,1000H		;;
	SUB	AX,1000H		;;
	JMP	CS_LOOP2		;;
					;;
CS_LPEND2:				;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
					;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;; get Request Header address
	MOV	word [RH+RH0.RH0_ENDO],AX ;;
	MOV	word [RH+RH0.RH0_ENDS],CX ;;
	XOR	AX,AX			;; clear error code to be returned
	MOV	CX,word [BUF+BUF_DATA.STATE] ;;
	CMP	CX,CPSW 		;;
	JE	MATCH_GOOD		;;
	MOV	AX,STAT_CMDERR		;;
					;;
MATCH_GOOD :				;;
	MOV	word [RH+RHC.RHC_STA],AX ;; set status in request header
	CALL	LOAD_INT2F		;; WGR load INT2f handler		    ;AN000;
					;;
BUF_END :				;;
					;;
	CMP	word [BUF+BUF_DATA.BFLAG],BF_LPT1 ;;
	JNE	BUF_MESSAGES		;;
					;;
	CMP	word [BUF+BUF_DATA.STATE],CPSW ;;
	JNE	BUF_MESSAGES		;;
					;; set PRN to the same setting as LPT1
	PUSH	BX			;;
					;;
	LEA	SI,[BUF+BUF_DATA.RNORMO] ;;
	LEA	CX,[BUF+BUF_DATA.BUFEND] ;;
	SUB	CX,SI			;;
	MOV	BX,word [BUF+BUF_DATA.prn_bufo] ;; where PRN buffer is
	LEA	DI,[BUF+BUF_DATA.RNORMO] ;;
	PUSH	CS			;;
	POP	ES			;;
	PUSH	CS			;;
	POP	DS			;;
	REP	MOVSB			;;
					;;
	POP	BX			;;
					;;
BUF_MESSAGES :				;;
	CMP	word [BUF+BUF_DATA.BFLAG],BF_LPT3 ;; generate error message is this is
	je	last_round		;; the last LPTn
	Jmp	INIT_RETURN		;;
					;; ERROR messages will be generated
					;; at the end of initialization of all
					;; the LPT devices
last_round :				;;
	MOV	AX,[cs:RESIDENT_END] ;;
	ADD	AX,STACK_SIZE		;;
	MOV	[cs:RESIDENT_END],AX ;;
	PUSH	CS			;;
	POP	CX			;; CX=CS
	SUB	AX,Cx			;; additional segment required.
CS_LOOP3:				;;
	CMP	AX,1000H		;;
	JB	CS_LPENd3		;;
	ADD	CX,1000H		;;
	SUB	AX,1000H		;;
	JMP	CS_LOOP3		;;
					;;
CS_LPENd3:				;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
	SHL	AX,1			;;
					;;
	MOV	word [RH+RH0.RH0_ENDO],AX ;; STACK !!!!!
	MOV	word [cs:STACK_ALLOCATED],0 ;; from now on, internal stack is used
					;;
	MOV	AX,[cs:DID_STATUS] ;; what is the DID combination ?
	AND	AX,[cs:DID_MATCH] ;;
	XOR	AX,[cs:DID_FAIL] ;;
					;;
	AND	AX,AX			;;
	JNZ	CODE_STAYED		;;
;	MOV	RH.RH0_ENDO,0		;; none of the devices are good
					;;
					;;
CODE_STAYED :				;;
	MOV	DI,TABLE         ;;
	push	CS			;;
	POP	ES			;;
					;;
	XOR	CX,CX			;;
MSG_LOOP :				;;
	CMP	CX,[cs:DEV_NUM] ;;
	JNB	INIT_RETURN		;;
	SHR	AX,1			;;
	JC	MSG_NEXT		;;
					;; this device in parse table is bad
	PUSH	DI			;;
	PUSH	CX			;;
	PUSH	AX			;;
	PUSH	BX			;; WGR					    ;AN000;
	PUSH	DX			;; WGR					    ;AN000;
					;;
	MOV	DI,word [PSE+PAR_OT.PAR_OFF] ;;
	MOV	SI,word [PSE+PAR_DEVOT.PAR_DNMO] ;;
					;;
	PUSH	CS			;;
	POP	ES			;;
	PUSH	CS			;;
	POP	DS			;;
					;;
	MOV	CX,8			;;
	LEA	SI,[SI+PAR_DNMT.PAR_DNM] ;;
	MOV	DI,SI			;;
	MOV	AL,' '                  ;; WGR                                      ;AN000;
	CLD				;; WGR					    ;AN000;
	REPNE	SCASB			;; WGR					    ;AN000;
	DEC	DI			;; WGR					    ;AN000;
	MOV	byte [es:DI],ZERO     ;; WGR					    ;AN000;
					;; WGR					    ;AN000;
	MOV	[cs:MSG_SEG],CS ;; WGR					    ;AN000;
	MOV	[cs:MSG_PTR],SI ;; WGR					    ;AN000;
	MOV	AX,BAD_DEVICE_MSG	;; WGR					    ;AN000;
	MOV	BX,STDERR		;; WGR					    ;AN000;
	LEA	SI,[SUBLIST];; WGR					    ;AN000;
	MOV	CX,ONE			;; WGR					    ;AN000;
	XOR	DL,DL			;; WGR					    ;AN000;
	MOV	DH,UTILITY_MSG_CLASS	;; WGR					    ;AN000;
	CALL	SYSDISPMSG		;; WGR					    ;AN000;
					;;					    ;AN000;
	POP	DX			;; WGR					    ;AN000;
	POP	BX			;; WGR					    ;AN000;
	POP	AX			;;
	POP	CX			;;
	POP	DI			;;
					;;
MSG_NEXT :				;;
	INC	CX			;;
	INC	DI			;;
	INC	DI			;;
	JMP	MSG_LOOP		;;
					;;
					;;
INIT_RETURN :				;;
					;;
					;;
	RET				;;
					;;
;INIT	ENDP				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Call by INIT to extract parameters for the deivce_id
;;
;; on rntry :
;;	ES:[DI]  PARSE Table 2, offsets of all parameters
;;	DS:[SI]  Printer Description table whose TYPEID matched
;;	DX	 "inverse" order of devices in the PARSE tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
DID_EXTRACT:       ;;
					;;
	PUSH	DX			;;
					;;-----------------------------
					;; define the DID_parameters
	PUSH	BX			;;
					;;
	MOV	BX,[cs:DEV_NUM] ;;
	SUB	BX,DX			;; order in the Parse table
	add	bx,bx			;; double to index [bx]
	MOV	DX,BX			;;
					;;
	MOV	AX,[ds:SI+PDSH.FONTSZ] ;;
	MOV	[cs:BX+FSIZE],AX ;; size of font buffer to be created
					;;
	MOV	AX,[ds:SI+PDSH.HSLOTS] ;;
	CMP	AX,HARDSL_MAX		;;
	JNA	LESS_HARDSL		;;
	MOV	word [cs:INIT_CHK], 0010H ;; ERROR 0010H
	POP	BX			;;
	JMP	END_MATCH_BAD		;;
LESS_HARDSL :				;;
	CMP	AX,[ds:SI+PDSH.HWCPMIN] ;;
	JNB	VALID_HARDSL		;;
	MOV	word [cs:INIT_CHK], 0012H ;; ERROR 0012H
	POP	BX			;;
	JMP	END_MATCH_BAD		;;
VALID_HARDSL :				;;
	MOV	[cs:BX+HRMAX],AX ;;
	MOV	[cs:BX+CTMAX],AX ;; will be reduced by the no. of hwcp
					;;
	MOV	AX,[ds:SI+PDSH.RSLOTS] ;;
	CMP	AX,RAMSL_MAX		;;
	JNA	LESS_RAMSL		;;
	MOV	word [cs:INIT_CHK], 0011H ;; ERROR 0011H
	POP	BX			;;
	JMP	END_MATCH_BAD		;;
LESS_RAMSL :				;;
	MOV	[cs:BX+RMMAX],AX ;;	see also designate
					;;
	MOV	[cs:BX+DESCO],SI ;;
					;;
	POP	BX			;;
					;;----------------------------------
					;;
	PUSH	CX			;;
					;;
HWCPgt: PUSH	DI			;; get the hwcp
					;;
	MOV	DI,word [PSE+PAR_DEVOT.PAR_HWCPO] ;;
	MOV	CX,word [PSE+PAR_HWCPT.PAR_HWCPL] ;; no. of hwcp
	AND	CX,CX			;;
	JNZ	chk_hwcp		;;
	push	bx			;;
	mov	bx,dx			;;
	MOV	[cs:BX+HRMAX],CX ;;
	MOV	CX,[ds:SI+PDSH.HWCPMIN] ;;
	SUB	[cs:BX+CTMAX],CX ;; what is left becomes cartridge slot
	pop	bx			;;
	JMP	DESIGN			;;
					;; hwcp to be defined
chk_hwcp: MOV	AX,[ds:SI+PDSH.HSLOTS] ;; defined in printer_desc
	CMP	CX,AX			;;
	JA	BAD_MATCH2		;;
	CMP	CX,HARDSL_MAX		;;
	JNA	HWCP_GOOD		;; jump if system error
	MOV	word [cs:INIT_CHK],0003H ;; ERROR 0003
	JMP	END_MATCH		;;
BAD_MATCH2:				;;
	MOV	word [cs:INIT_CHK],0002H ;; ERROR 0002
	JMP	END_MATCH		;;
					;;
HWCP_GOOD:				;; there are sufficient hard-slot for
					;; HWCP
	PUSH	SI			;; printer description table of TYPEID
	PUSH	BX			;;
					;;
	MOV	BX,DX			;;
	MOV	AX,[cs:BX+CTMAX] ;;
					;;
	PUSH	CX			;; calculate what is left for cart_slot
	CMP	CX,[ds:SI+PDSH.HWCPMIN] ;;
	JNB	MORE_THAN_HWCPMIN	;;
	MOV	CX,[ds:SI+PDSH.HWCPMIN] ;;
MORE_THAN_HWCPMIN :			;;
	SUB	AX,CX			;;
	POP	CX			;;
	mov	[cs:BX+HRMAX],CX ;;
					;;
	MOV	[cs:BX+CTMAX],AX ;; no of cart-slot for designate
	MOV	SI,[cs:BX+HARD_SLA] ;; get the corresponding hard-slots
					;;
	POP	BX			;;
					;;
	push	bx			;;
	push	dx			;;
	mov	bx,si			;;
	mov	dx,cx			;;
	mov	[cs:reserved1],dx ;; IF THERE IS ANY REPETITIVE HWCP
	mov	[cs:reserved2],bx ;; IF THERE IS ANY REPETITIVE HWCP
					;;
FILL_HWCP:				;;
	AND	CX,CX			;;
	JZ	DESIGN_P		;;
	INC	DI			;; next code page in PARSE table
	INC	DI			;;
	MOV	AX,[es:DI]		;; get code page value
					;;
					;; IF THERE IS ANY REPETITIVE HWCP
	push	dx			;;
	push	bx			;;
hwcp_norep :				;;
	cmp	ax,[cs:bx+SLTS.SLT_CP] ;;
	jne	hwcp_repnext		;;
	pop	bx			;;
	pop	dx			;;
	pop	dx			;;
	pop	bx			;;
	pop	si			;;
	jmp	END_MATCH		;;
					;;
hwcp_repnext:				;;
	inc	bx			;;
	inc	bx			;;
	inc	bx			;;
	inc	bx			;;
	dec	dx			;;
	jnz	hwcp_norep		;;
	pop	bx			;;
	pop	dx			;;
					;;
	MOV	[cs:SI+SLTS.SLT_CP],AX ;;
	MOV	AX,[cs:SI+SLTS.SLT_AT] ;; get the attributes
	OR	AX,AT_OCC		;; occupied
	OR	AX,AT_HWCP		;; hwcp slot
	MOV	[cs:SI+SLTS.SLT_AT],AX ;;
	INC	SI			;;
	INC	SI			;; next slot
	INC	SI			;; next slot
	INC	SI			;; next slot
	DEC	CX			;;
	JMP	FILL_HWCP		;;
DESIGN_P:				;;
	pop	dx			;;
	pop	bx			;;
	POP	SI			;;
					;;---------------------
DESIGN: POP	DI			;; get the designate no.
	PUSH	DI			;;
					;;
	MOV	DI,word [PSE+PAR_DEVOT.PAR_DESGO] ;;
	MOV	AX,word [PSE+PAR_DESGT.PAR_DESGL] ;;
	CMP	AX,1			;;
	JA	END_MATCH		;; there should have no font entry
	AND	AX,AX			;;
	JZ	DEF_RBUFMAX		;;
					;;
	MOV	AX,word [PSE+PAR_DESGT.PAR_DESG] ;;
	AND	AX,AX			;;
	JZ	DEF_RBUFMAX		;;
					;;
	CMP	[cs:SI+PDSH.CLASS],1 ;;
	JNE	DESIG_NOT_CLASS1	;;
					;;
	PUSH	BX			;; if there is any cartridge slot ?
	PUSH	AX			;;
	MOV	BX,DX			;;
	MOV	AX,[cs:BX+CTMAX] ;;
	AND	AX,AX			;;
	POP	AX			;;
	POP	BX			;;
	JZ	END_MATCH		;; fail, as there is no physical RAM.
					;;
	CMP	AX,HARDSL_MAX		;; is the designate more than max ?
	JA	END_MATCH		;;
					;;
					;;
	JMP	DEF_RBUFMAX		;;
					;;
					;;
					;;
DESIG_NOT_CLASS1 :			;;
	PUSH	BX			;; if there is any physical RAM slot ?
	PUSH	AX			;;
	MOV	BX,DX			;;
	MOV	AX,[cs:BX+RMMAX] ;;
	AND	AX,AX			;;
	POP	AX			;;
	POP	BX			;;
	JZ	END_MATCH		;; fail, as there is no physical RAM.
					;;
					;;
	CMP	AX,RAMSL_MAX		;; is the designate more than max ?
	JA	END_MATCH		;;
					;;
DEF_RBUFMAX :				;;
	PUSH	BX			;;
	MOV	BX,DX			;;
	MOV	[cs:BX+RBUMAX],AX ;;
	POP	BX			;;
					;;
					;;
PARAM : 				;;
;PARM:	    POP     DI			;;
;	    PUSH    DI			;;
;;	    MOV     DI,PSE.PAR_PARMO	;;
					;;
					;,--------------------------
					;; GOOD device_id parameters
	shr	dx,1			;;
	MOV	AX,DID_ONE		;;
	MOV	CX,DX			;;
	AND	CX,CX			;;
	JZ	NO_SHL			;;
	SHL	AX,CL			;;
NO_SHL: OR	[cs:DID_STATUS],AX ;; is defined
					;;-------------------------
END_MATCH: POP	DI			;; end of extract
	POP	CX			;;
END_MATCH_BAD : 			;;
	POP	DX			;;
					;;
	RET				;;
					;;
;DID_EXTRACT ENDP			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Called by INIT to define the STATE and BUF for the LPTn according to
;; the DID_STATUS. Create font buffer if requested through the "desi*nate"
;;
;; at entry :  CX = device order in parse table
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHK_DID:        ;;
					;;
	push	cx			;;
	push	di			;;
	push	dx			;;
					;;
	MOV	AX,[cs:DID_STATUS] ;;
					;;
	PUSH	CX			;; order 0 to m
	POP	DI			;;
	ADD	DI,DI			;; indexing : [DI]
					;;
	INC	CX			;;
	SHR	AX,CL			;; is the device parameter valid ?
					;;
	JC	DEFINE_BUFFER		;;
	JMP	LPT_FAIL		;;--------------------------
					;;
DEFINE_BUFFER : 			;;
					;; good device parameters as determined
	MOV	AX,[cs:DI+DESCO] ;;
	MOV	word [BUF+BUF_DATA.PDESCO],AX ;;
					;;
	PUSH	DI			;;
	MOV	DI,AX			;;
	MOV	AX,[cs:DI+PDSH.CLASS] ;;
	MOV	word [BUF+BUF_DATA.PCLASS],AX ;;
	POP	DI			;;
					;;
	MOV	AX,[cs:DI+HARD_SLA] ;;  in the DID_EXTRACT
	MOV	word [BUF+BUF_DATA.HARDSO],AX ;;
					;;
	MOV	AX,[cs:DI+RAM_SLA] ;;
	MOV	word [BUF+BUF_DATA.RAMSO],AX ;;
					;;
	MOV	AX,[cs:DI+HRMAX] ;;
	MOV	word [BUF+BUF_DATA.HARDMX],AX ;;
					;;
	MOV	AX,[cs:DI+CTMAX] ;;
	MOV	word [BUF+BUF_DATA.HCARMX],AX ;;
					;;
	ADD	AX,[cs:DI+HRMAX] ;; defore "designate"
	MOV	word [BUF+BUF_DATA.HSLMX],AX ;;
					;;
					;;
	MOV	AX,[cs:DI+RMMAX] ;;
	MOV	word [BUF+BUF_DATA.RAMMX],AX ;;
					;;
	XOR	AX,AX			;;
	PUSH	CX			;; calculate the max. length of control
	MOV	CX,2			;; sequence that is allowed for the
	CMP	word [BUF+BUF_DATA.PCLASS],1 ;; room reserved for physical slots.
	JNE	CTL_LOOP		;;
	MOV	CX,1			;; class 1 printer has one control seq.
CTL_LOOP :				;;
	ADD	AX,CTL_MAX		;;
	DEC	AX			;; leave one byte for the length
	DEC	CX			;;
	JNZ	CTL_LOOP		;;
	MOV	word [BUF+BUF_DATA.FSELMAX],AX ;;
	POP	CX			;;
					;;
	MOV	AX,[cs:DI+FSIZE] ;;
	MOV	word [BUF+BUF_DATA.FTSZPA],AX ;; FTSIZE in paragraph
					;;
	PUSH	AX			;;
					;;
	MOV	DX,4			;;
FT_PARA:				;;
	ADD	AX,AX			;;
	DEC	DX			;;
	JNZ	FT_PARA 		;; font size
	MOV	word [BUF+BUF_DATA.FTSIZE],AX ;; font size in bytes (used with.RBUFMX)
					;;
	POP	DX			;; FTSIZE in paragraph
					;;
	MOV	CX,[cs:DI+RBUMAX] ;; create font buffer per .RBUFMX and
	MOV	word [BUF+BUF_DATA.RBUFMX],CX ;; assume sufficient memory for all the
					;; "designate request"
	PUSH	CX			;;
					;;
	CMP	word [BUF+BUF_DATA.PCLASS],1 ;; always create font buffer for class1
	JNE	CLASS_NOT_1		;;
					;;
	AND	CX,CX			;;
	JZ	CLASS1_NOCX		;;
	ADD	CX,word [BUF+BUF_DATA.HARDMX] ;;
	MOV	word [BUF+BUF_DATA.HSLMX],CX ;;
	JMP	CLASS_NOT_1		;;
					;;
CLASS1_NOCX:				;;
	MOV	CX,word [BUF+BUF_DATA.HSLMX] ;;
					;;
CLASS_NOT_1 :				;;
	AND	CX,CX			;;
	JZ	MULTIPLE_DONE		;;
	MOV	AX,[cs:RESIDENT_END] ;;
MULTIPLE_FT :				;;
	ADD	AX,DX			;; allocate the font buffers at the end
	DEC	CX			;; of the resident codes
	JNZ	MULTIPLE_FT		;;
					;;
					;;
	MOV	CX,[cs:RESIDENT_END] ;;
	MOV	word [BUF+BUF_DATA.FTSTART],CX ;;
	MOV	[cs:RESIDENT_END],AX ;;
					;;
					;;
MULTIPLE_DONE : 			;;
	POP	CX			;; designate requested
					;;
	CMP	word [BUF+BUF_DATA.PCLASS],1 ;;
	JNE	DEF_RBUF		;;
					;; CLASS 1
	CMP	word [BUF+BUF_DATA.HARDMX],0 ;;
	JE	DEFBUF_DONE		;;
					;;
	PUSH	CX			;; STACKS...
	PUSH	SI			;;
	PUSH	DS			;;
	PUSH	ES			;;
	PUSH	DI			;;
	PUSH	DX			;;
					;;
	MOV	DX,word [BUF+BUF_DATA.HARDMX] ;;
	PUSH	DX			;; STACK +1 -- # of HWCP
					;;
	PUSH	CS			;;
	POP	DS			;;
	MOV	word [BUF+BUF_DATA.RBUFMX],0 ;;
	MOV	SI,word [BUF+BUF_DATA.PDESCO] ;;
	MOV	SI,[cs:SI+PDS.SELH_O] ;;
	XOR	CX,CX			;;
	MOV	CL,byte [cs:SI]     ;;
	INC	CX			;; including the length byte
					;;
	MOV	DI,word [BUF+BUF_DATA.FTSTART] ;; control template
DEF_FTBUF:				;; fill the  font buffer with the
	PUSH	DI			;;
	POP	ES			;;
	XOR	DI,DI			;;
					;;
	PUSH	CX			;;
	PUSH	SI			;;
	REP	MOVSB			;;
	POP	SI			;;
	POP	CX			;;
					;;
	PUSH	ES			;;
	POP	DI			;;
	ADD	DI,word [BUF+BUF_DATA.FTSZPA] ;;
	DEC	DX			;;
	JNZ	DEF_FTBUF		;;
					;;
	POP	DX			;; STACK -1
					;;
	MOV	SI,word [BUF+BUF_DATA.HARDSO] ;;
	MOV	DI,word [BUF+BUF_DATA.FTSTART] ;; define the HWCP values
DEF_FThwcp :				;;
	PUSH	DI			;;
	POP	ES			;;
	MOV	DI,CTL5202_OFFS 	;; offset to the HWCP words
					;;
	MOV	AX,[cs:SI+SLTS.SLT_CP] ;;
	MOV	word [es:DI],AX     ;;
					;;
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
					;;
	PUSH	ES			;;
	POP	DI			;;
	ADD	DI,word [BUF+BUF_DATA.FTSZPA] ;;
	DEC	DX			;;
	JNZ	DEF_FThwcp		;;
					;;
	POP	DX			;;
	POP	DI			;;
	POP	ES			;;
	POP	DS			;;
	POP	SI			;;
	POP	CX			;;
					;;
	JMP	DEFBUF_DONE		;;
					;;
					;;
DEF_RBUF :				;;
	MOV	word [BUF+BUF_DATA.RSLMX],CX ;; the no. of ram slots supported
	CMP	CX,[cs:DI+RMMAX] ;;
	JNB	DEFBUF_DONE		;;
	MOV	AX,[cs:DI+RMMAX] ;;
	MOV	word [BUF+BUF_DATA.RSLMX],AX ;; the max. of .RAMMX and .RBUFMX
					;;
DEFBUF_DONE :				;;
	MOV	word [BUF+BUF_DATA.STATE],CPSW ;; the LPTn is CPSW ----- STATE
					;;
	CMP	word [BUF+BUF_DATA.BFLAG],BF_PRN ;;
	JNE	RET_CHK_DID		;;
	MOV	AX,[cs:DI+DID_BIT] ;;
	MOV	word [BUF+BUF_DATA.did_prn],AX ;;
					;;
					;;
	JMP	RET_CHK_DID		;;
					;;
LPT_FAIL:				;;
					;;
	MOV	word [BUF+BUF_DATA.STATE],NORMAL ;; the LPTn is NORMAL --- STATE
					;;
					;;
RET_CHK_DID:				;;
					;;
	pop	dx			;;
	pop	di			;;
	pop	cx			;;
					;;
	RET				;;
					;;
;CHK_DID ENDP				;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Called by INIT to check for consistency between duplicated device name and
;;	between PRN and LPT1
;;
;; at entry :  DI = pointer to PAR_DEVOT
;;	       BUF.STATE = any state
;;	       CX = DID order
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
DEV_CHECK:        ;;
					;;
	LEA	SI,[BUF+BUF_DATA.PAR_EXTRACTO] ;;
					;;
	PUSH	CX			;;
					;;
	PUSH	SI			;; compare device id
	PUSH	DI			;;
	mov	SI,[SI+PAR_DEVOT.PAR_DIDO] ;;
	MOV	DI,word [PSE+PAR_DEVOT.PAR_DIDO] ;;
	MOV	CX,word [PSE+PAR_DNMT.PAR_DNML] ;;
	INC	CX			;; including length
	INC	CX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	Jz	hwcp_check		;;
	mov	word [cs:INIT_CHK],0021h ;; error 0021h
	Jmp	FORCE_LPT_BAD		;;
					;;
hwcp_check :				;;
	PUSH	SI			;; compare HWCP
	PUSH	DI			;;
	mov	SI,[SI+PAR_DEVOT.PAR_HWCPO] ;;
	MOV	DI,word [PSE+PAR_DEVOT.PAR_HWCPO] ;;
	MOV	AX,word [PSE+PAR_HWCPT.PAR_HWCPL] ;;
	MOV	CX,2			;;
	SHL	AX,CL			;; multiply by two
	INC	AX			;; including length
	INC	AX			;;
	MOV	CX,AX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	Jz	desig_check		;;
	mov	word [cs:INIT_CHK],0022h ;; error 0022h
	Jmp	FORCE_LPT_BAD		;;
					;;
desig_check :				;;
	PUSH	SI			;; compare DESIGNATE
	PUSH	DI			;;
	mov	SI,[SI+PAR_DEVOT.PAR_DESGO] ;;
	MOV	DI,word [PSE+PAR_DEVOT.PAR_DESGO] ;;
	MOV	AX,word [PSE+PAR_DESGT.PAR_DESGL] ;;
	MOV	CX,2			;;
	SHL	AX,CL			;; multiply by two
	INC	AX			;; including length
	INC	AX			;;
	MOV	CX,AX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	Jz	param_check		;;
	mov	word [cs:INIT_CHK],0023h ;; error 0023h
	Jmp	FORCE_LPT_BAD		;;
					;;
param_check :				;;
	PUSH	SI			;; compare parameters
	PUSH	DI			;;
	mov	SI,[SI+PAR_DEVOT.PAR_PARMO] ;;
	MOV	DI,word [PSE+PAR_DEVOT.PAR_PARMO] ;;
	MOV	CX,word [PSE+PAR_PARMT.PAR_PARML] ;;
	INC	CX			;; including length
	INC	CX			;;
	REPE	CMPSB			;;
	POP	DI			;;
	POP	SI			;;
	JZ	M_END			;;
	mov	word [cs:INIT_CHK],0024h ;; error 0024h
					;;
FORCE_LPT_BAD : 			;; the second set of parameters is
	MOV	word [BUF+BUF_DATA.STATE],NORMAL ;; bad
					;;
	CMP	word [BUF+BUF_DATA.BFLAG],BF_LPT1 ;;
	JNE	M_END			;;
					;;
					;; since LPT1 is bad, force PRN to bad
	push	bx			;; force prn to be bad too
	mov	bx,word [BUF+BUF_DATA.prn_bufo] ;;
	MOV	word [BUF+BUF_DATA.STATE],NORMAL ;;
	pop	bx			;;
					;;
	mov	AX,word [BUF+BUF_DATA.did_prn] ;; if PRN was not good, DID_PRN = 0
	OR	[cs:DID_FAIL],AX ;;
					;;
					;;
M_END:					;; force the good did_status to fail if
					;; STATE is bad
	POP	CX			;;
	PUSH	CX			;; order 0 to m
	MOV	AX,[cs:DID_STATUS] ;;
					;;
	INC	CX			;;
	SHR	AX,CL			;;
	POP	CX			;;
	JNC	DEV_CHECK_RET		;; already failed
					;;
	CMP	word [BUF+BUF_DATA.STATE],CPSW ;;
	JE	DEV_CHECK_RET		;;
					;;
	    PUSH    BX			;;
	    MOV     BX,CX		;;
	    ADD     BX,BX		;;
	    MOV     AX,[cs:BX+DID_BIT] ;;
	    OR	    [cs:DID_FAIL],AX ;; force DID to fail
	    POP     BX			;;
					;;
					;;
DEV_CHECK_RET : 			;;
					;;
	RET				;;
					;;
					;;
;DEV_CHECK ENDP				;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PROCEDURE_NAME: LOAD_INT2F
;
; FUNCTION:
; THIS PROCEDURE LOADS THE INTERRUPT HANDLER FOR INT2FH
;
; AT ENTRY:
;
; AT EXIT:
;    NORMAL: INTERRUPT 2FH VECTOR POINTS TO INT2F_COM. OLD INT 2FH
;	     VECTOR STORED.
;
;    ERROR:  N/A
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SEMAPHORE  DB	  0								    ;AN000;
										    ;AN000;
LOAD_INT2F:                       ;AN000;
	   CMP	  byte [cs:SEMAPHORE],0 ; already loaded?		    ;AN000;
	   JNE	  LI_1				   ; yes.....exit		    ;AN000;
	   PUSH   ES				   ; no...load. 		    ;AN000;
	   PUSH   CX				   ;				    ;AN000;
	   PUSH   AX				   ;				    ;AN000;
	   XOR	  AX,AX 			   ; point ES to low..		    ;AN000;
	   MOV	  ES,AX 			   ; memory.			    ;AN000;
	   MOV	  AX,word [es:INT2F_LOW]      ; store original..		    ;AN000;
	   MOV	  [cs:ROM_INT2F],AX   ; interrupt 2Fh..		    ;AN000;
	   MOV	  CX,word [es:INT2F_HI]      ; location.. 		    ;AN000;
	   MOV	  [cs:ROM_INT2F+2],CX   ;				    ;AN000;
	   OR	  AX,CX 			   ; check if old int2F..	    ;AN000;
	   JNZ	  LI_0				   ; is 0.			    ;AN000;
	   MOV	  AX,ABORT            ; yes....point to..		    ;AN000;
	   MOV	  [cs:ROM_INT2F],AX   ; IRET.			    ;AN000;
	   MOV	  AX,CS 			   ;				    ;AN000;
	   MOV	  [cs:ROM_INT2F+2],AX   ;				    ;AN000;
LI_0:						   ;				    ;AN000;
	   CLI					   ;				    ;AN000;
	   MOV	  word [es:INT2F_LOW],INT2F_COM          ; replace vector..	    ;AN000;
	   MOV	  word [es:INT2F_HI],CS      ; with our own..		    ;AN000;
	   STI					   ;				    ;AN000;
	   POP	  AX				   ;				    ;AN000;
	   POP	  CX				   ;				    ;AN000;
	   POP	  ES				   ;				    ;AN000;
	   MOV	  byte [cs:SEMAPHORE],1 ; now loaded.		    ;AN000;
LI_1:	   RET					   ;				    ;AN000;
;LOAD_INT2F ENDP

.XLIST
MSG_SERVICES <MSGDATA>			  ; WGR 				    ;AN000;
MSG_SERVICES <DISPLAYmsg,LOADmsg,CHARmsg> ; WGR 				    ;AN000;
MSG_SERVICES <PRINTER.CL1>		  ; WGR 				    ;AN000;
MSG_SERVICES <PRINTER.CL2>		  ; WGR 				    ;AN000;
MSG_SERVICES <PRINTER.CLA>		  ; WGR 				    ;AN000;
.LIST

include 'MSGDCL.INC'

;CSEG	ENDS
;	END
