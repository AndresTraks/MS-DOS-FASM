PAGE	,132
TITLE	DOS - Code Page Switching - Printer Device Driver
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  FILENAME:		CPS Printer Device Driver Main Code
;;  MODULE NAME:
;;  TYPE:		Assemble file  (resident code)
;;  LINK PROCEDURE:	Link CPSPMnn+CPSFONT+CPSPInn into .EXE format. CPSPM01
;;			must be first.	CPSPInn must be last.  Everything
;;			before CPSPInn will be resident.
;;  INCLUDE FILES:
;;			CPSPEQU.INC
;;
;;
;;  This routine is structured as a DOS Device Driver.
;;  IE it is installed via the CONFIG.SYS command:
;;
;;  The following device commands are supported:
;;
;;  0 - INIT
;;  --------
;;
;;  8 - OUTPUT
;;  9 - OUTPUT
;;  --------
;;  Supported in between Designate-start and the Designate_end commands.
;;
;;
;;  12 - IOCTL OUTPUT
;;  -----------------
;;  CPS Function request :  Major function =	05	-- printer device
;;			    Minor functions =	4CH	-- designate start
;;						4DH	-- designate end
;;						4AH	-- invoke
;;						6AH	-- query-invoked
;;						6BH	-- query-list
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*Modification history ********************************************************
;AN001; p2685  Long delay on CHCP before failure message	   12/10/87 J.K.
;******************************************************************************
					;;
include 'CPSPEQU.INC' ;;
					;;
;PUBLIC	PRINTER_DESC_NUM		;;
;PUBLIC	PRINTER_DESC_TBL		;;
;PUBLIC	INIT_CHK,TABLE,DEVICE_NUM	;; WGR						 ;AN000;
;PUBLIC	INVOKE				;; WGR						 ;AN000;
;PUBLIC	BUF0,BUF1,BUF2,BUF3		;; WGR						 ;AN000;
;PUBLIC	HARD_SL1,RAM_SL1		;;
;PUBLIC	HARD_SL2,RAM_SL2		;;
;PUBLIC	HARD_SL3,RAM_SL3		;;
;PUBLIC	HARD_SL4,RAM_SL4		;;
;PUBLIC	RESERVED1,RESERVED2		;;
					;;
;EXTRN	RESIDENT_END:WORD		;;
;EXTRN	STACK_ALLOCATED:WORD		;;
;EXTRN	FONT_PARSER:NEAR,FTABLE:WORD	;;
;EXTRN	INIT:NEAR			;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
;CSEG	SEGMENT PARA PUBLIC 'CODE'      ;;
;	ASSUME	CS:CSEG 		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  ************************************
;;  **				      **
;;  **	     Resident Code	      **
;;  **				      **
;;  ************************************
;;
;;
;; DEVICE HEADER - must be at offset zero within device driver
;;		   (DHS is defined according to this structure)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
DEV_HDR0: DW	DEV_HDR1         ;; becomes pointer to next device header
	DW	0			;; must be zero for no link
	DW	0e040H			;; attribute (Char device)
					;; supports IOCTL calls
	DW	STRATEGY0        ;; pointer to device "strategy" routine
	DW	INTERRUPT0        ;; pointer to device "interrupt handler"
DEV_NAME0: DB	'PRN     '              ;; device name( length : NAME_LEN)
					;;
DEV_HDR1: DW	DEV_HDR2         ;; becomes pointer to next device header
	DW	0			;; must be zero for no link
	DW	0e040H			;; attribute (Char device)
					;; supports IOCTL calls
	DW	STRATEGY1        ;; pointer to device "strategy" routine
	DW	INTERRUPT1        ;; pointer to device "interrupt handler"
DEV_NAME1: DB	'LPT1    '              ;; device name( length : NAME_LEN)
					;;
DEV_HDR2: DW	DEV_HDR3         ;; becomes pointer to next device header
	DW	0			;; must be zero for no link
	DW	0e040H			;; attribute (Char device)
					;; supports IOCTL calls
	DW	STRATEGY2        ;; pointer to device "strategy" routine
	DW	INTERRUPT2        ;; pointer to device "interrupt handler"
DEV_NAME2: DB	'LPT2    '              ;; device name( length : NAME_LEN)
					;;
					;;
DEV_HDR3: DD	-1			;; becomes pointer to next device header
	DW	0e040H			;; attribute (Char device)
					;; supports IOCTL calls
	DW	STRATEGY3        ;; pointer to device "strategy" routine
	DW	INTERRUPT3        ;; pointer to device "interrupt handler"
DEV_NAME3: DB	'LPT3    '              ;; device name( length : NAME_LEN)
					;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; *****************************
;; **  Resident Data Areas    **
;; *****************************
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PRN/LPTn  printer data based on BUF
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
INIT_CHK DW	0			;; internal flag : error loc. in INIT
					;;
BUF0	 BUF_DATA               ;; PRN
					;;
BUF1	 BUF_DATA               ;; LPT1
					;;
BUF2	 BUF_DATA               ;; LPT2
					;;
BUF3	 BUF_DATA               ;; LPT3
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Hard/RAM slots table in the order of DEVICE parameters
;
;   number of entries in all HARD_SLn is determined by the max. {HSLOTS}
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
HARD_SL1	 SLTS       ;; 1st hardware slots
HARD_SL1B	 SLTS      ;;
HARD_SL1C	 SLTS      ;;
HARD_SL1D	 SLTS      ;;
HARD_SL1E	 SLTS      ;;
HARD_SL1F	 SLTS      ;;
HARD_SL1G	 SLTS      ;;
HARD_SL1H	 SLTS      ;;
HARD_SL1I	 SLTS      ;;
HARD_SL1J	 SLTS      ;;
HARD_SL1K	 SLTS      ;;
HARD_SL1L	 SLTS      ;;
HARD_SL1M	 SLTS      ;; -- max. no. of code pages allowed
;;upto	hardsl_max + 1			;;
					;;
HARD_SL2	 SLTS       ;; 2nd hardware slots
HARD_SL2B	 SLTS      ;;
HARD_SL2C	 SLTS      ;;
HARD_SL2D	 SLTS      ;;
HARD_SL2E	 SLTS      ;;
HARD_SL2F	 SLTS      ;;
HARD_SL2G	 SLTS      ;;
HARD_SL2H	 SLTS      ;;
HARD_SL2I	 SLTS      ;;
HARD_SL2J	 SLTS      ;;
HARD_SL2K	 SLTS      ;;
HARD_SL2L	 SLTS      ;;
HARD_SL2M	 SLTS      ;; -- max. no. of code pages allowed
;;upto	hardsl_max + 1			;;
					;;
HARD_SL3	 SLTS       ;; 3rd hardware slots
HARD_SL3B	 SLTS      ;;
HARD_SL3C	 SLTS      ;;
HARD_SL3D	 SLTS      ;;
HARD_SL3E	 SLTS      ;;
HARD_SL3F	 SLTS      ;;
HARD_SL3G	 SLTS      ;;
HARD_SL3H	 SLTS      ;;
HARD_SL3I	 SLTS      ;;
HARD_SL3J	 SLTS      ;;
HARD_SL3K	 SLTS      ;;
HARD_SL3L	 SLTS      ;;
HARD_SL3M	 SLTS      ;; -- max. no. of code pages allowed
;;upto	hardsl_max + 1			;;
					;;
HARD_SL4	 SLTS       ;; 4TH hardware slots
HARD_SL4B	 SLTS      ;;
HARD_SL4C	 SLTS      ;;
HARD_SL4D	 SLTS      ;;
HARD_SL4E	 SLTS      ;;
HARD_SL4F	 SLTS      ;;
HARD_SL4G	 SLTS      ;;
HARD_SL4H	 SLTS      ;;
HARD_SL4I	 SLTS      ;;
HARD_SL4J	 SLTS      ;;
HARD_SL4K	 SLTS      ;;
HARD_SL4L	 SLTS      ;;
HARD_SL4M	 SLTS      ;; -- max. no. of code pages allowed
;;upto	hardsl_max + 1			;;
					;;
					;;
RAM_SL1	 SLTS       ;; 1st ram slots
RAM_SL1B	 SLTS       ;; NOTE : must be only FOUR bytes for
RAM_SL1C	 SLTS       ;;	  codepage positioning
RAM_SL1D	 SLTS       ;;	  calculation as compared
RAM_SL1E	 SLTS       ;;	  with each entry in FTDL_OFF
RAM_SL1F	 SLTS       ;;
RAM_SL1G	 SLTS       ;;
RAM_SL1H	 SLTS       ;;
RAM_SL1I	 SLTS       ;;
RAM_SL1J	 SLTS       ;;
RAM_SL1K	 SLTS       ;;
RAM_SL1L	 SLTS       ;; -- max. no. of code pages allowed
;;upto	ramsl_max,			;;
					;;
RAM_SL2	 SLTS       ;; 2nd ram slots
RAM_SL2B	 SLTS       ;;
RAM_SL2C	 SLTS       ;;
RAM_SL2D	 SLTS       ;;
RAM_SL2E	 SLTS       ;;
RAM_SL2F	 SLTS       ;;
RAM_SL2G	 SLTS       ;;
RAM_SL2H	 SLTS       ;;
RAM_SL2I	 SLTS       ;;
RAM_SL2J	 SLTS       ;;
RAM_SL2K	 SLTS       ;;
RAM_SL2L	 SLTS       ;; -- max. no. of code pages allowed
;;upto	ramsl_max,			;;
					;;
RAM_SL3	 SLTS       ;; 3rd ram slots
RAM_SL3B	 SLTS       ;;
RAM_SL3C	 SLTS       ;;
RAM_SL3D	 SLTS       ;;
RAM_SL3E	 SLTS       ;;
RAM_SL3F	 SLTS       ;;
RAM_SL3G	 SLTS       ;;
RAM_SL3H	 SLTS       ;;
RAM_SL3I	 SLTS       ;;
RAM_SL3J	 SLTS       ;;
RAM_SL3K	 SLTS       ;;
RAM_SL3L	 SLTS       ;; -- max. no. of code pages allowed
;;upto	ramsl_max,			;;
					;;
RAM_SL4	 SLTS       ;; 4th ram slots
RAM_SL4B	 SLTS       ;;
RAM_SL4C	 SLTS       ;;
RAM_SL4D	 SLTS       ;;
RAM_SL4E	 SLTS       ;;
RAM_SL4F	 SLTS       ;;
RAM_SL4G	 SLTS       ;;
RAM_SL4H	 SLTS       ;;
RAM_SL4I	 SLTS       ;;
RAM_SL4J	 SLTS       ;;
RAM_SL4K	 SLTS       ;;
RAM_SL4L	 SLTS       ;; -- max. no. of code pages allowed
;;upto	ramsl_max,			;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; hard/RAM buffered slots on codepages
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
label HBUF_SL1 word   ;; hardware slots' buffer for LPT1/PRN
	DW	0FFFFH			;; ---- only for CART-SLOTS
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
;;upto	hardsl_max+1, there are as many HARD_SLn
					;;
label HBUF_SL2 word   ;; hardware slots' buffer for LPT2
	DW	0FFFFH			;; ---- only for CART-SLOTS
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
;;upto	hardsl_max+1, there are as many HARD_SLn
					;;
label HBUF_SL3 word   ;; hardware slots' buffer for LPT3
	DW	0FFFFH			;; ---- only for CART-SLOTS
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
;;upto	hardsl_max+1, there are as many HARD_SLn
					;;
					;;
label RBUF_SL1 word   ;; ram slots' buffer for LPT1/PRN
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
;;upto ramsl_max, there are as many RAM_SLn
					;;
label RBUF_SL2 word   ;; ram slots' buffer for LPT2
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
;;upto ramsl_max, there are as many RAM_SLn
					;;
label RBUF_SL3 word   ;; ram slots' buffer for LPT3
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
	DW	0FFFFH			;;
;;upto ramsl_max, there are as many RAM_SLn
					;;
label FTDL_OFF1 word   ;; offset of FTSTART for PRN/LPT1
	DW	0			;; NOTE : must be only two bytes for
	DW	0			;;	  codepage positioning
	DW	0			;;	  calculation as compared
	DW	0			;;	  with each entry in RAM_SLOT
	DW	0			;;	  or CART_SLOT
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
;;upto the max. of {ramsl_max,hardsl_max}
					;;
label FTDL_OFF2 word   ;; offset of FTSTART for LPT2
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
;;upto the max. of {ramsl_max,hardsl_max}
					;;
label FTDL_OFF3 word   ;; offset of FTSTART for LPT3
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
	DW	0			;;
;;upto the max. of {ramsl_max,hardsl_max}
					;;
					;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Printer Description Tables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
ESC_CHAR	EQU	27		;;
					;;
db	'PRINTER_DESC'                  ;;
					;;
PRINTER_DESC_NUM DW 3			;; number of PRINTER_DESCn
					;;
label PRINTER_DESC_TBL word  ;;
	DW	PRINTER_DESC1        ;;
	DW	PRINTER_DESC2        ;;
	DW	PRINTER_DESC3        ;;
	DW	PRINTER_DESC4        ;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Printer Description Table for Proprinter (4201)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINTER_DESC1 : 			;;
					;;
	PDSH$1 PDSH ,'4201    ',,,0,212,1,1,1 ;; followed by the rest in PDS
					;; CLASS  = 0
					;; FTSZPA = 212 ==> 212 x 16=3008 bytes
					;;		    of font buffer
					;; HSLOTS  = 1 (check CTL4201_B)
					;; HWCPMIN = 1
					;; RSLOTS  = 1 (check CTL4201_B)
					;;
	DW	CTL4201_H
	DW	CTL4201_R
	DW	CTL4201_B
					;; (CTL_MAX = 32)
					;; (32 bytes for each control)
					;; (MUST BE ADJACENT...no blanks bet.:)
CTL4201_H :	DB  5,ESC_CHAR,'I',0,ESC_CHAR,"6" ;;  selection control 1
CTL4201_R :	DB  5,ESC_CHAR,'I',4,ESC_CHAR,"6" ;;  selection control 2
		db  26	dup (0) 	;;  for CTL4201_H
		db  26	dup (0) 	;;  for CTL4201_R
					;;
CTL4201_B	DB  CTL_MAX	DUP (0) ;; max. two selection
		DB  CTL_MAX	DUP (0) ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Printer Description Table for 5202
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
PRINTER_DESC2 : 			;;
	PDSH$2 PDSH ,'5202    ',,,1,2,2,1,0 ;; followed by the rest in PDS
					;; CLASS  = 1 (font buffers allowed
					;;	       if there is cart-slot)
					;; FTSZPA = 2 ==> 2 x 16 = 32 bytes
					;;		    of font buffer
					;; HSLOTS  = 2 (check CTL5202_B)
					;; HWCPMIN = 1
					;; RSLOTS  = 0 (check CTL5202_B)
					;;
	DW	CTL5202_H
	DW	CTL5202_R
	DW	CTL5202_B
					;;
					;; (CTL_MAX = 32)
					;; (SEE CTL5202_OFFS)
					;; (32 bytes for each control)
CTL5202_H :	DB  12,ESC_CHAR,91,84,5,0,00,00,0FFH,0FFH,00   ;; selection control 1
		 dB  ESC_CHAR,"6"             ;;
		DB  12,ESC_CHAR,91,84,5,0,00,00,0FFH,0FFH,00   ;; selection control 2
		 dB  ESC_CHAR,"6"             ;;
		db  19 dup (0)		;;  for CTL5202_H selection 1
		db  19 dup (0)		;;  for CTL5202_H selection 2
CTL5202_R :	DB  0			;;
					;;
CTL5202_B	DB  CTL_MAX	DUP (0) ;; max. two selection
		DB  CTL_MAX	DUP (0) ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Printer Description Table for RESERVED PRINTER (res1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINTER_DESC3 : 			;;
					;;
	PDSH$3 PDSH ,'4208    ',,,1,2,2,1,0 ;; followed by the rest in PDS
					;; CLASS  = 1
					;; FTSZPA = 2
					;; HSLOTS  = 2
					;; HWCPMIN = 1
					;; RSLOTS  = 0
					;;
	DW	CTL4208_H
	DW	CTL4208_R
	DW	CTL4208_B
					;; (CTL_MAX = 32)
					;; (32 bytes for each control)
					;; (MUST BE ADJACENT...no blanks bet.:)
CTL4208_H :	DB  0Bh,ESC_CHAR,49h,0Ah    ;;	selection control 1
		DB  ESC_CHAR,49h,03
		DB  ESC_CHAR,49h,02
		DB  ESC_CHAR,36h
		db  20	dup (0)
CTL4208_R :	DB  0Bh,ESC_CHAR,49h,0Eh    ;;	selection control 2
		DB  ESC_CHAR,49h,7
		DB  ESC_CHAR,49h,6
		DB  ESC_CHAR,36h
		db  20	dup (0) 	;;  for CTLres1_H and CTRLres1_R
					;;
CTL4208_B	DB  CTL_MAX	DUP (0) ;; max. two selection
		DB  CTL_MAX	DUP (0) ;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Printer Description Table for RESERVED PRINTER (res2)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINTER_DESC4 : 			;;
					;;
	PDSH$4 PDSH ,'nnnnnnnn',,,0,0,1,1,1 ;; followed by the rest in PDS
					;; CLASS  = 0
					;; FTSZPA = 0
					;; HSLOTS  = 1
					;; HWCPMIN = 1
					;; RSLOTS  = 1
					;;
	DW	CTLres2_H
	DW	CTLres2_R
	DW	CTLres2_B
					;; (CTL_MAX = 32)
					;; (32 bytes for each control)
					;; (MUST BE ADJACENT...no blanks bet.:)
CTLres2_H :	DB  0			;;  selection control 1
CTLres2_R :	DB  32	dup (0) 	;;  selection control 2
		db  32	dup (0) 	;;  for CTLres2_H and CTRLres2_R
					;;
CTLres2_B	DB  CTL_MAX	DUP (0) ;; max. two selection
		DB  CTL_MAX	DUP (0) ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
TEMP_SI 	rw      1 ;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The request header for IOCTL call
;; to the Normal device driver
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
REQ_NORM1 GIH           ;; for LPT1/PRN
	  GB2S$1 GB2S , ;;
REQ_NORM2 GIH           ;; for LPT2
	  GB2S$2 GB2S , ;;
REQ_NORM3 GIH           ;; for LPT3
	  GB2S$3 GB2S , ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;
;;   PARSER'S TABLES
;;
;;	-- TABLE  is the first table of the results of the parsing.
;;	   The first word (number of devices) will be set to 0 if
;;	   syntax error is detected in the DEVICE command line.
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; TABLE STRUCTURE FOR RETURNING VALUES TO THE INIT MODULE	    WGR
;  (ADAPTED FROM VERSION 1.0 DISPLAY.SYS)			    WGR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

label TABLE word            ; table header				 ;AN000;
DEVICE_NUM     DW	ZERO		   ; initialized to zero devices		 ;AN000;
	       DW	TABLE1_1	   ; pointer to table 2 for device 1		 ;AN000;
	       DW	TABLE2_1	   ; pointer to table 2 for device 2		 ;AN000;
	       DW	TABLE3_1	   ; pointer to table 2 for device 3		 ;AN000;
	       DW	TABLE4_1	   ; pointer to table 2 for device 4		 ;AN000;
											 ;AN000;
label TABLE1_1 word               ;AN000;
	       DW	FOUR		   ; 4 pointer follow				 ;AN000;
	       DW	TABLE1_2	   ; pointer to table 3 (device name)		 ;AN000;
	       DW	TABLE1_3	   ; pointer to table 4 (device id)		 ;AN000;
	       DW	TABLE1_4	   ; pointer to table 5 (hwcp's)                 ;AN000;
	       DW	TABLE1_5	   ; pointer to table 6 (num desg's and fonts)   ;AN000;
	       DW	-1		   ; reserved					 ;AN000;
											 ;AN000;
label TABLE1_2 word           ; device name (ie. PRN)			 ;AN000;
	       DW	ZERO		   ; length					 ;AN000;
	       DB	"        "         ; value                                       ;AN000;
											 ;AN000;
label TABLE1_3 word           ; device id. (eg. 4201,5202..)		 ;AN000;
	       DW	ZERO		   ; length					 ;AN000;
	       DB	"        "         ; value                                       ;AN000;
											 ;AN000;
label TABLE1_4 word           ; hardware code pages (10 max.)		 ;AN000;
	       DW	ZERO		   ; number					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
											 ;AN000;
label TABLE1_5 word           ; Designates and fonts			 ;AN000;
	       DW	ZERO		   ; values given (0 - 2 valid) 		 ;AN000;
	       DW	-1		   ; n value					 ;AN000;
	       DW	-1		   ; m value					 ;AN000;
											 ;AN000;
label TABLE2_1 word               ;AN000;
	       DW	FOUR		   ; 4 pointer follow				 ;AN000;
	       DW	TABLE2_2	   ; pointer to table 3 (device name)		 ;AN000;
	       DW	TABLE2_3	   ; pointer to table 4 (device id)		 ;AN000;
	       DW	TABLE2_4	   ; pointer to table 5 (hwcp's)                 ;AN000;
	       DW	TABLE2_5	   ; pointer to table 6 (num desg's and fonts)   ;AN000;
	       DW	-1		   ; reserved					 ;AN000;
											 ;AN000;
label TABLE2_2 word           ; device name (ie. PRN)			 ;AN000;
	       DW	ZERO		   ; length					 ;AN000;
	       DB	"        "         ; value                                       ;AN000;
											 ;AN000;
label TABLE2_3 word           ; device id. (eg. 4201,5202..)		 ;AN000;
	       DW	ZERO		   ; length					 ;AN000;
	       DB	"        "         ; value                                       ;AN000;
											 ;AN000;
label TABLE2_4 word           ; hardware code pages (10 max.)		 ;AN000;
	       DW	ZERO		   ; number					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
											 ;AN000;
label TABLE2_5 word           ; Designates and fonts			 ;AN000;
	       DW	ZERO		   ; values given (0 - 2 valid) 		 ;AN000;
	       DW	-1		   ; n value					 ;AN000;
	       DW	-1		   ; m value					 ;AN000;
											 ;AN000;
label TABLE3_1 word               ;AN000;
	       DW	FOUR		   ; 4 pointer follow				 ;AN000;
	       DW	TABLE3_2	   ; pointer to table 3 (device name)		 ;AN000;
	       DW	TABLE3_3	   ; pointer to table 4 (device id)		 ;AN000;
	       DW	TABLE3_4	   ; pointer to table 5 (hwcp's)                 ;AN000;
	       DW	TABLE3_5	   ; pointer to table 6 (num desg's and fonts)   ;AN000;
	       DW	-1		   ; reserved					 ;AN000;
											 ;AN000;
label TABLE3_2 word           ; device name (ie. PRN)			 ;AN000;
	       DW	ZERO		   ; length					 ;AN000;
	       DB	"        "         ; value                                       ;AN000;
											 ;AN000;
label TABLE3_3 word           ; device id. (eg. 4201,5202..)		 ;AN000;
	       DW	ZERO		   ; length					 ;AN000;
	       DB	"        "         ; value                                       ;AN000;
											 ;AN000;
label TABLE3_4 word           ; hardware code pages (10 max.)		 ;AN000;
	       DW	ZERO		   ; number					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
											 ;AN000;
label TABLE3_5 word           ; Designates and fonts			 ;AN000;
	       DW	ZERO		   ; values given (0 - 2 valid) 		 ;AN000;
	       DW	0		   ; n value					 ;AN000;
	       DW	0		   ; m value					 ;AN000;
											 ;AN000;
label TABLE4_1 word               ;AN000;
	       DW	FOUR		   ; 4 pointer follow				 ;AN000;
	       DW	TABLE4_2	   ; pointer to table 3 (device name)		 ;AN000;
	       DW	TABLE4_3	   ; pointer to table 4 (device id)		 ;AN000;
	       DW	TABLE4_4	   ; pointer to table 5 (hwcp's)                 ;AN000;
	       DW	TABLE4_5	   ; pointer to table 6 (num desg's and fonts)   ;AN000;
	       DW	-1		   ; reserved					 ;AN000;
											 ;AN000;
label TABLE4_2 word           ; device name (ie. PRN)			 ;AN000;
	       DW	ZERO		   ; length					 ;AN000;
	       DB	"        "         ; value                                       ;AN000;
											 ;AN000;
label TABLE4_3 word           ; device id. (eg. 4201,5202..)		 ;AN000;
	       DW	ZERO		   ; length					 ;AN000;
	       DB	"        "         ; value                                       ;AN000;
											 ;AN000;
label TABLE4_4 word           ; hardware code pages (10 max.)		 ;AN000;
	       DW	ZERO		   ; number					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
	       DW	-1		   ; value					 ;AN000;
											 ;AN000;
label TABLE4_5 word           ; Designates and fonts			 ;AN000;
	       DW	ZERO		   ; values given (0 - 2 valid) 		 ;AN000;
	       DW	0		   ; n value					 ;AN000;
	       DW	0		   ; m value					 ;AN000;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
reserved1 rw      1 ;; reserved for debugging used
reserved2 rw      1 ;;
					;;
;;;;;;;;ASSUME	DS:NOTHING		;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	PRN  Device "strategy" entry point
;;
;;	Retain the Request Header address for use by Interrupt routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STRATEGY0:           ;;
	PUSH	BX			;;
	PUSH	BX			;;
	LEA	BX,[BUF0] ;; BUF = BUF0  CS:[BX]
	POP	word [BUF+BUF_DATA.RH_PTRO] ;; offset of request header
	MOV	word [BUF+BUF_DATA.RH_PTRS],ES ;; segment
	POP	BX			;;
	RETF   ;;
;STRATEGY0 ENDP				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	LPT1 Device "strategy" entry point
;;
;;	Retain the Request Header address for use by Interrupt routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STRATEGY1:           ;;
	PUSH	BX			;;
	PUSH	BX			;;
	LEA	BX,[BUF1] ;; BUF = BUF1  CS:[BX]
	POP	word [BUF+BUF_DATA.RH_PTRO] ;; offset of request header
	MOV	word [BUF+BUF_DATA.RH_PTRS],ES ;; segment
	POP	BX			;;
	RETF   ;;
;STRATEGY1 ENDP				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	LPT2 Device "strategy" entry point
;;
;;	Retain the Request Header address for use by Interrupt routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STRATEGY2:           ;;
	PUSH	BX			;;
	PUSH	BX			;;
	LEA	BX,[BUF2] ;; BUF = BUF2  CS:[BX]
	POP	word [BUF+BUF_DATA.RH_PTRO] ;; offset of request header
	MOV	word [BUF+BUF_DATA.RH_PTRS],ES ;; segment
	POP	BX			;;
	RETF   ;;
;STRATEGY2 ENDP				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	LPT3 Device "strategy" entry point
;;
;;	Retain the Request Header address for use by Interrupt routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STRATEGY3:           ;;
	PUSH	BX			;;
	PUSH	BX			;;
	LEA	BX,[BUF3] ;; BUF = BUF3  CS:[BX]
	POP	word [BUF+BUF_DATA.RH_PTRO] ;; offset of request header
	MOV	word [BUF+BUF_DATA.RH_PTRS],ES ;; segment
	POP	BX			;;
	RETF   ;;
;STRATEGY3 ENDP				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Table of command / functions supported by LPTn
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; CMD_CODES code supported by LPTn
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
label CMD_CODES byte   ;;
	DB	CMD_INI 		;;  Initialization
	DB	CMD_WRT 		;;  output
	DB	09			;;  output
	DB	12			;;  output
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
CMD_INDX =	(($-CMD_CODES))	;;  number of entries in CMD_CODES
					;;
					;;  Write (CMD_WRT) has exceptional
					;;  support by LPTn
					;;
					;;  Generic IOCTL (CMD_GIO) leads to
					;;  GIO_CODES
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; GIO_CODES code supported by LPTn
					;;   -- command = CMD_GIO and
					;;	major function = MAF_PTR
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
label GIO_CODES byte   ;; minor GIO functions supported :
	DB	MIF_DST 		;; - designate start
	DB	MIF_DEN 		;; - designate end
	DB	MIF_IVK 		;; - invoke
	DB	MIF_QIV 		;; - query-invoked
	DB	MIF_QLS 		;; - query-list
GIO_INDX =	(($-GIO_CODES))	;;  number of entries in GIO_CODES
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; Cases supported by LPTn
					;; -- first section matched with
					;;    CMD_CODES upto CMD_INDX
					;;
					;; -- 2nd section matched with
					;;    GIO_CODES for GIO_INDEX more
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
label CASES word   ;;  in CMD_CODES order
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
	DW	INIT         ;;  0 - Initialization
	DW	WRITE         ;;
	DW	WRITE         ;;
	DW	WRITE         ;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;  in GIO_CODES order
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
	DW	DESIGNATE_START        ;;
	DW	DESIGNATE_END        ;;
	DW	INVOKE         ;;
	DW	Q_INVOKED        ;;
	DW	Q_LIST         ;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Memory Allocation
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
					;;
MEM_REQUEST  DW    -1			;; flag used for first time memory
					;; allocation for each device
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; PRN	Device "interrupt" entry point
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
INTERRUPT0:           ;; device interrupt entry point
					;;
	PUSH	DS			;; save all registers Revised
	PUSH	ES			;;
	PUSH	AX			;;
	PUSH	BX			;;
	PUSH	CX			;;
	PUSH	DX			;;
	PUSH	DI			;;
	PUSH	SI			;;
					;; BP isn't used, so it isn't saved
	push	cs			;;
	pop	ds			;;
					;;
	CMP	word [cs:STACK_ALLOCATED],0AAH ;;
	JNE	PRN_NO_STACK		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	STACK RECODING SEPT 28/86
;
;	GORDON GIDDINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	AX,STACK_SIZE		;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	MOV	[cs:TEMP_SI],SI ;G;
	MOV	SI,[cs:RESIDENT_END] ;G;
	SUB	SI,STACK_SIZE		;G;
					;G;
	mov	[cs:reserved1],AX ;G;
	mov	[cs:reserved2],SI ;G;
					;G;
	CLI				;G;
	MOV	DX,SS			;G;
	MOV	CX,SP			;G;
	MOV	SS,SI			;G;
	MOV	SP,AX			;G;
	STI				;G;
	MOV	SI,[cs:TEMP_SI] ;G;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUSH	DX			;; SAVE OLD SS ONTO STACK
	PUSH	CX			;; "    "   SP "    "
					;;
PRN_NO_STACK :				;;
					;;
					;;
	MOV	DI,IRPT_CMD_EXIT        ;; return addr from command processor
					;;
	PUSH	DI			;; push return address onto stack
					;; command routine issues "RET"
					;;
	LEA	BX,[BUF0] ;; PRN	BUF = BUF0 , CS:BX
					;;
	MOV	word [cs:MEM_REQUEST],-1 ;; to be set to zero only once
					;;
	CMP	word [BUF+BUF_DATA.BFLAG],-1 ;;
	JNE	PRN_INITED		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	word [BUF+BUF_DATA.BFLAG],BF_PRN ;; INITIALIZE PRN BUFFER
					;;
	MOV	DI,DEV_HDR0        ;; PRN	Device header
	MOV	word [BUF+BUF_DATA.DEV_HDRO],DI ;;
	MOV	word [BUF+BUF_DATA.DEV_HDRS],CS ;; must be CS
					;;
	MOV	DI,HBUF_SL1        ;; PRN/LPT1 buffer for Hardware-slots
	MOV	word [BUF+BUF_DATA.HRBUFO],DI ;;
					;;
	MOV	DI,RBUF_SL1        ;; PRN/LPT1 buffer for RAM-slots
	MOV	word [BUF+BUF_DATA.RMBUFO],DI ;;
					;;
	MOV	DI,FTDL_OFF1        ;;
	MOV	word [BUF+BUF_DATA.FTDLO],DI ;;
					;;
	MOV	DI,REQ_NORM1        ;; PRN/LPT1 request header
	MOV	word [BUF+BUF_DATA.RNORMO],DI ;;
					;;
	MOV	word [BUF+BUF_DATA.FSELEN],0 ;; selection control length
					;;
	mov	word [BUF+BUF_DATA.prn_bufo],BUF0 ;;
					;;
	JMP	COMMON_INTR		;; common interrupt handler
					;;
PRN_INITED :				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; FONT BUFFER TO BE CREATED ?
	CMP	word [BUF+BUF_DATA.BFLAG],BF_PRN ;;
	JNE	PRN_MEM_DONE		;;
					;;
	OR	word [BUF+BUF_DATA.BFLAG],BF_MEM_DONE ;; do it only once.
					;;
	CMP	word [BUF+BUF_DATA.STATE],CPSW ;;
	JNE	PRN_MEM_DONE		;; create only if state is CPSW
					;;
PRN_MEM_CREATE :			;;
	XOR	AX,AX			;; THEN CREATE
	MOV	[cs:MEM_REQUEST],AX ;; to set to zero only once for each
					;; LPTn or PRN
PRN_MEM_DONE :				;;
	JMP	COMMON_INTR		;; common interrupt handler
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; LPT1 Device "interrupt" entry point
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INTERRUPT1:           ;; device interrupt entry point
					;;
	PUSH	DS			;; save all registers Revised
	PUSH	ES			;;
	PUSH	AX			;;
	PUSH	BX			;;
	PUSH	CX			;;
	PUSH	DX			;;
	PUSH	DI			;;
	PUSH	SI			;;
					;; BP isn't used, so it isn't saved
	push	cs			;;
	pop	ds			;;
					;;
	CMP	word [cs:STACK_ALLOCATED],0AAH ;;
	JNE	LPT1_NO_STACK		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	STACK RECODING SEPT 28/86
;
;	GORDON GIDDINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	AX,STACK_SIZE		;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	MOV	[cs:TEMP_SI],SI ;G;
	MOV	SI,[cs:RESIDENT_END] ;G;
	SUB	SI,STACK_SIZE		;G;
					;G;
	mov	[cs:reserved1],AX ;G;
	mov	[cs:reserved2],SI ;G;
					;G;
	CLI				;G;
	MOV	DX,SS			;G;
	MOV	CX,SP			;G;
	MOV	SS,SI			;G;
	MOV	SP,AX			;G;
	STI				;G;
	MOV	SI,[cs:TEMP_SI] ;G;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUSH	DX			;; SAVE OLD SS ONTO STACK
	PUSH	CX			;; "    "   SP "    "
					;;
LPT1_NO_STACK : 			;;
					;;
	MOV	DI,IRPT_CMD_EXIT        ;; return addr from command processor
					;;
	PUSH	DI			;; push return address onto stack
					;; command routine issues "RET"
	LEA	BX,[BUF1] ;; LPT1 BUF = BUF1 , CS:BX
					;;
	MOV	word [cs:MEM_REQUEST],-1 ;; to be set to zero only once
					;;
	CMP	word [BUF+BUF_DATA.BFLAG],-1 ;;
	JNE	LPT1_INITED		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	word [BUF+BUF_DATA.BFLAG],BF_LPT1 ;; INITIALIZE LPT1 BUFFER
					;;
	MOV	DI,DEV_HDR1        ;; LPT1 Device header
	MOV	word [BUF+BUF_DATA.DEV_HDRO],DI ;;
	MOV	word [BUF+BUF_DATA.DEV_HDRS],CS ;; must be CS
					;;....................................
	LEA	DI,[BUF+BUF_DATA.RNORMO] ;; duplicate common infor. between
	PUSH	CS			;; PRN and LPT1
	POP	ES			;;
	LEA	CX,[BUF+BUF_DATA.BUFEND] ;;
	SUB	CX,DI			;;
	LEA	SI,[BUF0] ;;
	LEA	SI,[SI+BUF_DATA.RNORMO] ;;
	REP	MOVS byte [es:DI],[cs:SI]
					;;
	JMP	COMMON_INTR		;; common interrupt handler
					;;
LPT1_INITED :				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; FONT MEMORY TO BE CREATED ?
	CMP	word [BUF+BUF_DATA.BFLAG],BF_LPT1 ;;
	JNE	LPT1_MEM_DONE		;;
					;;
	OR	word [BUF+BUF_DATA.BFLAG],BF_MEM_DONE ;; no more next time
					;;
	CMP	word [BUF+BUF_DATA.STATE],CPSW ;;
	JNE	LPT1_MEM_DONE		;; do it only if state is CPSW
					;;
LPT1_MEM_CREATE :			;;
	XOR	AX,AX			;; THEN CREATE MEMORY
	MOV	[cs:MEM_REQUEST],AX ;; to set to zero only once for each
					;;
LPT1_MEM_DONE : 			;;
					;;
	JMP	COMMON_INTR		;; common interrupt handler
					;;
;INTERRUPT1 ENDP 			;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; LPT2 Device "interrupt" entry point
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INTERRUPT2:           ;; device interrupt entry point
					;;
	PUSH	DS			;; save all registers Revised
	PUSH	ES			;;
	PUSH	AX			;;
	PUSH	BX			;;
	PUSH	CX			;;
	PUSH	DX			;;
	PUSH	DI			;;
	PUSH	SI			;;
					;; BP isn't used, so it isn't saved
	push	cs			;;
	pop	ds			;;
					;;
	CMP	word [cs:STACK_ALLOCATED],0AAH ;;
	JNE	LPT2_NO_STACK		;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	STACK RECODING SEPT 28/86
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	AX,STACK_SIZE		;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	MOV	[cs:TEMP_SI],SI ;G;
	MOV	SI,[cs:RESIDENT_END] ;G;
	SUB	SI,STACK_SIZE		;G;
					;G;
	mov	[cs:reserved1],AX ;G;
	mov	[cs:reserved2],SI ;G;
					;G;
	CLI				;G;
	MOV	DX,SS			;G;
	MOV	CX,SP			;G;
	MOV	SS,SI			;G;
	MOV	SP,AX			;G;
	STI				;G;
	MOV	SI,[cs:TEMP_SI] ;G;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUSH	DX			;; SAVE OLD SS ONTO STACK
	PUSH	CX			;; "    "   SP "    "
					;;
LPT2_NO_STACK : 			;;
					;;
	MOV	DI,IRPT_CMD_EXIT        ;; return addr from command processor
					;;
	PUSH	DI			;; push return address onto stack
					;; command routine issues "RET"
					;;
	LEA	BX,[BUF2] ;; LPT2 BUF = BUF2 , CS:BX
					;;
	MOV	word [cs:MEM_REQUEST],-1 ;; to be set to zero only once
					;;
	CMP	word [BUF+BUF_DATA.BFLAG],-1 ;;
	JNE	LPT2_INITED		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	word [BUF+BUF_DATA.BFLAG],BF_LPT2 ;; initialise LPT2 buffer
					;;
	MOV	DI,DEV_HDR2        ;; LPT2 Device header
	MOV	word [BUF+BUF_DATA.DEV_HDRO],DI ;;
	MOV	word [BUF+BUF_DATA.DEV_HDRS],CS ;; must be CS
					;;
	MOV	DI,HBUF_SL2        ;; LPT2 buffer for Hardware-slots
	MOV	word [BUF+BUF_DATA.HRBUFO],DI ;;
					;;
	MOV	DI,RBUF_SL2        ;; LPT2 buffer for RAM-slots
	MOV	word [BUF+BUF_DATA.RMBUFO],DI ;;
					;;
	MOV	DI,FTDL_OFF2        ;;
	MOV	word [BUF+BUF_DATA.FTDLO],DI ;;
					;;
					;;
	MOV	DI,REQ_NORM2        ;; LPT2 request header
	MOV	word [BUF+BUF_DATA.RNORMO],DI ;;
					;;
	MOV	word [BUF+BUF_DATA.FSELEN],0 ;; selection control length
					;;
	mov	word [BUF+BUF_DATA.prn_bufo],BUF2 ;;
					;;
	JMP	COMMON_INTR		;; common interrupt handler
					;;
LPT2_INITED :				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; FONT BUFFER TO BE CREATED ?
	CMP	word [BUF+BUF_DATA.BFLAG],BF_LPT2 ;;
	JNE	LPT2_MEM_DONE		;;
					;;
	OR	word [BUF+BUF_DATA.BFLAG],BF_MEM_DONE ;;
					;;
	CMP	word [BUF+BUF_DATA.STATE],CPSW ;;
	JNE	LPT2_MEM_DONE		;;
					;;
	XOR	AX,AX			;;
	MOV	[cs:MEM_REQUEST],AX ;; to set to zero only once for each
					;; LPTn or PRN
LPT2_MEM_DONE : 			;;
					;;
	JMP	COMMON_INTR		;; common interrupt handler
					;;
;INTERRUPT2 ENDP 			;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; LPT3 Device "interrupt" entry point
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INTERRUPT3:           ;; device interrupt entry point
					;;
	PUSH	DS			;; save all registers Revised
	PUSH	ES			;;
	PUSH	AX			;;
	PUSH	BX			;;
	PUSH	CX			;;
	PUSH	DX			;;
	PUSH	DI			;;
	PUSH	SI			;;
					;; BP isn't used, so it isn't saved
	push	cs			;;
	pop	ds			;;
					;;
	CMP	word [cs:STACK_ALLOCATED],0AAH ;;
	JNE	LPT3_NO_STACK		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	STACK RECODING SEPT 28/86
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	AX,STACK_SIZE		;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	SHL	AX,1			;G;
	MOV	[cs:TEMP_SI],SI ;G;
	MOV	SI,[cs:RESIDENT_END] ;G;
	SUB	SI,STACK_SIZE		;G;
					;G;
	mov	[cs:reserved1],AX ;G;
	mov	[cs:reserved2],SI ;G;
					;G;
	CLI				;G;
	MOV	DX,SS			;G;
	MOV	CX,SP			;G;
	MOV	SS,SI			;G;
	MOV	SP,AX			;G;
	STI				;G;
	MOV	SI,[cs:TEMP_SI] ;G;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PUSH	DX			;; SAVE OLD SS ONTO STACK
	PUSH	CX			;; "    "   SP "    "
					;;
LPT3_NO_STACK : 			;;
					;;
	MOV	DI,IRPT_CMD_EXIT        ;; return addr from command processor
					;;
	PUSH	DI			;; push return address onto stack
					;; command routine issues "RET"
					;;
	LEA	BX,[BUF3] ;; LPT3 BUF = BUF3 , CS:BX
					;;
	MOV	word [cs:MEM_REQUEST],-1 ;; to be set to zero only once
					;;
	CMP	word [BUF+BUF_DATA.BFLAG],-1 ;;
	JNE	LPT3_INITED		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV	word [BUF+BUF_DATA.BFLAG],BF_LPT3 ;; INITIALIZE LPT3 BUFFER
					;;
	MOV	DI,DEV_HDR3        ;; LPT3 Device header
	MOV	word [BUF+BUF_DATA.DEV_HDRO],DI ;;
	MOV	word [BUF+BUF_DATA.DEV_HDRS],CS ;; must be CS
					;;
	MOV	DI,HBUF_SL3        ;; LPT3 buffer for Hardware-slots
	MOV	word [BUF+BUF_DATA.HRBUFO],DI ;;
					;;
	MOV	DI,RBUF_SL3        ;; LPT3 buffer for RAM-slots
	MOV	word [BUF+BUF_DATA.RMBUFO],DI ;;
					;;
	MOV	DI,FTDL_OFF3        ;;
	MOV	word [BUF+BUF_DATA.FTDLO],DI ;;
					;;
					;;
	MOV	DI,REQ_NORM3        ;; LPT3 request header
	MOV	word [BUF+BUF_DATA.RNORMO],DI ;;
					;;
	MOV	word [BUF+BUF_DATA.FSELEN],0 ;; selection control length
					;;
	mov	word [BUF+BUF_DATA.prn_bufo],BUF3 ;;
					;;
	JMP	COMMON_INTR		;; common interrupt handler
					;;
LPT3_INITED :				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; FONT BUFFER TO BE CREATED ?
	CMP	word [BUF+BUF_DATA.BFLAG],BF_LPT3 ;;
	JNE	LPT3_MEM_DONE		;;
					;;
	OR	word [BUF+BUF_DATA.BFLAG],BF_MEM_DONE ;; no more next time
					;;
	CMP	word [BUF+BUF_DATA.STATE],CPSW ;;
	JNE	LPT3_MEM_DONE		;;
					;;
	XOR	AX,AX			;;
	MOV	[cs:MEM_REQUEST],AX ;; to set to zero only once for each
					;; LPTn or PRN
LPT3_MEM_DONE : 			;;
					;;
	JMP	COMMON_INTR		;; common interrupt handler
					;;
;INTERRUPT3 ENDP 			;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Common interrupt entry :
;     at entry, BUFn (CS:BX) of LPTn is defined
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COMMON_INTR :				;;
	CLD				;; all moves forward
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Check if header link has to be set
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDS	SI,dword [BUF+BUF_DATA.DEV_HDRO] ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;  device header :  DS:[SI]
	CMP	word [BUF+BUF_DATA.LPT_STRAO], -1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	JNE	DOSLPT_FOUND		;; has been linked to DOS LPTn
	CMP	word [BUF+BUF_DATA.LPT_STRAS], -1 ;;
	JNE	DOSLPT_FOUND		;; has been linked to DOS LPTn
	LDS	SI,dword [BUF+BUF_DATA.DEV_HDRO] ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;  next device header :  ES:[DI]
	LES	DI,dword [HP+DHS.DH_NEXTO] ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
	PUSH	ES			;;
	POP	AX			;;
	AND	AX,AX			;;
	JNZ	L1			;;
	JMP	DOSLPT_FOUND		;; link not yet set up
					;;
;SEARCH$ WHILE				 ;;  pointer to next device header is NOT
L1:
	PUSH	ES			;;  -1
	POP	AX			;;
	CMP	AX,-1			;;
;LEAVE$  E,	 AND			 ;; leave if both offset and segment are
	JNE	NOT0FFFF

	CMP	DI,-1			;;  0FFFFH
;LEAVE$  E				 ;;
	JE	L2

NOT0FFFF:				;;
	PUSH	DI			;;
	PUSH	SI			;;
	MOV	CX,NAME_LEN		;;
	LEA	DI,[NHD+DHS.DH_NAME] ;;
	LEA	SI,[HP+DHS.DH_NAME] ;;
	REPE	CMPSB			;;
	POP	SI			;;
	POP	DI			;;
	AND	CX,CX			;;

;EXITIF$ Z				 ;; exit if name is found in linked hd.
	JNZ	L3			;; name is not found
					;;
					;; name is found in the linked header
	MOV	AX,word [NHD+DHS.DH_STRAO] ;;  get the STRATEGY address
;	ADD	AX,DI			;;
	MOV	word [BUF+BUF_DATA.LPT_STRAO],AX ;;
	MOV	AX,ES			;;
;	JNC	X1			;;
;	ADD	AX,1000H		;;  carrier overflow
X1:	MOV	word [BUF+BUF_DATA.LPT_STRAS],AX ;;
					;;
	MOV	AX,word [NHD+DHS.DH_INTRO] ;;  get the INTERRUPT address
;	ADD	AX,DI			;;
	MOV	word [BUF+BUF_DATA.LPT_INTRO],AX ;;
	MOV	AX,ES			;;
;	JNC	X2			;;
;	ADD	AX,1000H		;;  carrier overflow
X2:	MOV	word [BUF+BUF_DATA.LPT_INTRS],AX ;;
					;;
					;;
;ORELSE$				;; find next header to have the same
					;; device name
	JMP	L4			;;
L3:					;;
	LES	DI,dword [NHD+DHS.DH_NEXTO] ;
					;;
;ENDLOOP$				;;
	JMP	L1			;;
L2:					;;
;ENDSRCH$				;;
L4:					;;
					;;
DOSLPT_FOUND :				;; device header link has been
					;; established
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; COMMAND REQUEST
;      ES:DI  Request Header , and
;
;	      CMD_CODES,  GIO_CODES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;; get RH address passed to
					;;
	MOV	AL,byte [RH+RHC.RHC_CMD] ;;
	CMP	AL,CMD_GIO		;;
	JE	GIO_COMMAND		;;
					;;
	PUSH	CS			;;  non-GIO command
	POP	ES			;;
	MOV	DI,CMD_CODES        ;;
	MOV	CX,CMD_INDX		;;
					;; find if command is in CMD_CODES ?
	REPNE	SCASB			;;
	JNE	UN_SUP			;;
	MOV	SI,CMD_INDX		;; the command is supported :
	SUB	SI,CX			;;
	DEC	SI			;; index to CASES
	JMP	SUPPORTED		;;
					;;
UN_SUP: JMP	NORM_DRIVER		;; to be handled by DOS normal driver
					;;
GIO_COMMAND :				;; Check if it is valid GIO
					;;
GIO_CASES :				;; supported GIO command
	MOV	AL,byte [RH+GIH.GIH_MIF] ;;
					;; use minor function to locate
	PUSH	CS			;;
	POP	ES			;;
	MOV	DI,GIO_CODES        ;;
	MOV	CX,GIO_INDX		;;
					;; find if command is in GIO_CODES ?
	REPNE	SCASB			;;
	JNE	NORM_DRIVER		;;
	MOV	SI,GIO_INDX		;; the command is supported :
	SUB	SI,CX			;;
	DEC	SI			;; index to CASES
	ADD	SI,CMD_INDX		;;
					;;
SUPPORTED :				;; command/functions supported by LPTn
					;;
	ADD	SI,SI			;; double to index to WORD-offset
					;;
	XOR	AX,AX			;; initialize return to "no error"
					;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;; get RH address again
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  At entry to command processing routine:
;
;      ES:DI   = Request Header address
;      CS:BX   = Buffer for lptn
;      CS      = code segment address
;      AX      = 0
;
;      top of stack is return address, IRPT_CMD_EXIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
	JMP	[cs:CASES+SI] ;; call routine to handle the command
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
IRPT_CMD_EXIT:				;; return from command routine
					;; AX = value to OR into status word
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;; restore ES:DI as Request Header ptr
	MOV	AX,word [RH+RHC.RHC_STA] ;;
	OR	AH,STAT_DONE		;; add "done" bit to status word
	MOV	word [RH+RHC.RHC_STA],AX ;; store status into request header
					;;
					;;
					;; *** USING INTERNATL STACK ? ***
					;;
	CMP	word [cs:STACK_ALLOCATED],-1 ;;
	JE	RET0_NO_STACK		;;
					;;
	CMP	word [cs:STACK_ALLOCATED],0 ;;
	JNE	RET0_IN_STACK		;;
					;;
	MOV	word [cs:STACK_ALLOCATED],0AAH ;; NEXT interrupt will start using
	JMP	RET0_NO_STACK		;; internal STACK
					;;
RET0_IN_STACK : 			;; use internal STACK !!!!
	POP	CX		;get old SP from stack
	POP	DX		;get old SS from stack
	CLI			;disable interrupts while changing SS:SP
	MOV	SS,DX		;restore stack segment register
	MOV	SP,CX		;restore stack pointer register
	STI			;enable interrupts
					;;
					;;
RET0_NO_STACK : 			;;
					;;
	POP	SI			;; restore registers
	POP	DI			;;
	POP	DX			;;
	POP	CX			;;
	POP	BX			;;
	POP	AX			;;
	POP	ES			;;
	POP	DS			;;
	RETF   ;;
					;;
;INTERRUPT0 ENDP 			;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;====	Command not supported by CPSW device driver
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
NORM_DRIVER:       ;; LPT OUTPUT to the DOS LPTn
					;;
	PUSH	BX			;; **** BUF. is changed ****
	PUSH	BX			;;
	POP	SI			;;
	LES	BX,dword [BUF+BUF_DATA.RH_PTRO] ;; pass the request header to the
	CALL	dword [cs:SI+BUF_DATA.LPT_STRAO] ;; LPTn strategy routine.
					;;
	POP	BX			;;
	CALL	dword [BUF+BUF_DATA.LPT_INTRO] ;; interrupt the DOS LPTn
	RET				;;
					;;
;NORM_DRIVER ENDP			;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;====	Command Code  - lpt_output  =======
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
WRITE:           ;; LPT OUTPUT to the DOS LPTn
					;;
					;;
					;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;; restore ES:DI as Request Header ptr
					;;
	MOV	AX,word [BUF+BUF_DATA.STATE] ;;
	CMP	AX,NORMAL		;;
	JNE	WRT_NOT_NORMAL		;;
	JMP	WRT_NORMAL		;;
					;;
WRT_NOT_NORMAL :			;;
	CMP	AX,DESG_END		;;
	JNE	WRT_FONT		;;
	JMP	NO_MORE_FTBLK		;; ignore the write
					;;
WRT_FONT :				;;
	CMP	AX,DESG_WR		;;
	JE	WRT_DESIGNATE		;;
	JMP	WRT_NORMAL		;;
					;;-------------------------
WRT_DESIGNATE : 			;; DESIGNATE WRITE
	MOV	AX,word [BUF+BUF_DATA.STATUS] ;;
	AND	AX,FAIL 		;;
	JZ	WRT_DESG_GOOD		;;
	JMP	WRT_ignore		;; already failed
					;;
WRT_DESG_GOOD : 			;;
	MOV	SI,FTABLE        ;;
	PUSH	CS			;;
	POP	DS			;;
					;;
	MOV	[ds:SI+FBUFS.FLAG],0 ;; no restart
	MOV	AX,word [RH+RH3.RH3_CNT] ;;
	MOV	[ds:SI+FBUFS.BUFFER_LEN],AX ;; length of request packet
					;;
	PUSH	SI			;;
	LEA	SI,[SI+FBUFS.BUFFER_ADDR] ;; packet address
	MOV	AX,word [RH+RH3.RH3_DTAO] ;;
	MOV	[ds:SI],AX		;;
	INC	SI			;;
	INC	SI			;;
	MOV	AX,word [RH+RH3.RH3_DTAS] ;;
	MOV	[ds:SI],AX		;;
	POP	SI			;;
					;;
FP_CALL :				;;   **************************
	CALL	FONT_PARSER		;;   ** Parse the Font File  **
FP_RETURN :				;;   **************************
					;;
					;; -- only for the RAM slot --
					;;
					;; PROCESS THE RETURNED FONT :
					;; SI = FTABLE
	MOV	ES,word [BUF+BUF_DATA.FTSTART] ;; ES = the start of the font buffer,
					;;	its entry corresponds to the
					;;	positioning of codepage in slot
	MOV	DI,word [BUF+BUF_DATA.FTSLOTO] ;; DI = start of the slot of codepages
					;; CX = slot size of the font downloaded
	MOV	CX,word [BUF+BUF_DATA.RBUFMX] ;;     --- if there is no designate
	MOV	AX,word [BUF+BUF_DATA.STATUS] ;;
	AND	AX,DSF_CARTCP		;;
	JZ	CHECK_RETURN		;;
	MOV	CX,word [BUF+BUF_DATA.HSLMX] ;;     -- with/without designate, <>0
					;;
CHECK_RETURN :				;;
					;;
	MOV	DX,[cs:SI+FBUFS.NUM_FTBLK] ;; DX = number fo code pages loaded
					;;
	ADD	SI,sizeof.FBUFS ;; SI = points to FTBLK
					;;...................................
PARSE_FTBLK :				;; **** LOOP ****
					;;
					;;
	AND	DX,DX			;;
	JNZ	SKIP_SLOT		;;
	JMP	NO_MORE_FTBLK		;; **** LOOP EXIT (FTBLK end) ****
					;;...................................
					;; **** LOOP (on each FTBLK)  ****
					;;
					;; skip on the slot until the codepage
SKIP_SLOT :				;; is one of the downloaded.
	AND	CX,CX			;;
	JNZ	LOCATE_SLOT		;;
	XOR	AX,AX			;;
	PUSH	AX			;;
	POP	ES			;; ES = 0, no font storage(less buffer)
	JMP	SLOT_FOUND		;;
					;;
LOCATE_SLOT:				;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;;
	AND	AX,AT_LOAD		;;
	Jnz	SLOT_FOUND		;;
	INC	DI			;;########   NEXT SLOT	 ############
	INC	DI			;;
	INC	DI			;;
	INC	DI			;; next slot
	PUSH	ES			;;
	POP	AX			;;
	ADD	AX,word [BUF+BUF_DATA.FTSZPA] ;;
	PUSH	AX			;;
	POP	ES			;; next buffer
	DEC	CX			;;####################################
	JMP	SKIP_SLOT		;;
					;;
SLOT_FOUND :				;;
	MOV	AX,[cs:SI+FTBLK.FTB_STATUS] ;;
	CMP	AX,0FFF0H		;;
	JNB	CHECK_FSTAT		;;
					;;
	OR	word [BUF+BUF_DATA.STATUS],FAIL ;;
					;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;;
	MOV	word [RH+RHC.RHC_STA],AX ;;
	JMP	WRITE_RET		;; **** LOOP EXIT (fail)  ****
					;;
CHECK_FSTAT :				;;
	CMP	AX,FSTAT_FONT		;;
	JNE	NEXT_FTBLK		;;
					;;
	MOV	AX,[cs:SI+FTBLK.FTB_DLEN] ;;
	AND	AX,AX			;;
	JNZ	FONT_RETURNED		;;
					;;
NEXT_FTBLK :				;; **** NEXT IN LOOP ****
					;;
	ADD	SI,sizeof.FTBLK ;;  SI = points to FTBLK
	DEC	DX			;;
	INC	DI			;;########   NEXT SLOT	 ############
	INC	DI			;;
	INC	DI			;;
	INC	DI			;; next slot
	PUSH	ES			;;
	POP	AX			;;
	ADD	AX,word [BUF+BUF_DATA.FTSZPA] ;;
	PUSH	AX			;;
	POP	ES			;; next buffer
	DEC	CX			;;####################################
	JMP	PARSE_FTBLK		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FONT_RETURNED : 			;;
					;;  *********************************
					;;  * ANY SELECTION CONTROL TO BE   *
					;;  * STORED ?			    *
					;;  *********************************
					;;
					;;
					;; SI = points to FTBLK
					;; ES = font buffer segment / 0
					;; BX = LPT buffer
					;; DI = SLOT pointer
	PUSH	CX			;;
					;;
					;;
	MOV	AX,[cs:SI+FTBLK.FTB_SELECT] ;;
	AND	AX,AX			;;
	JNZ	SELECT_NOT0		;;
	CMP	word [BUF+BUF_DATA.PCLASS],1 ;;
	JNE	SELECT_0		;;
	JMP	SELECT_BAD		;; CLASS 1 printer CANNOT have SELECT=0
					;;
SELECT_0:				;;
					;;
	POP	CX			;;
	JMP	STORE_FONT		;;
					;;
SELECT_NOT0 :				;;
					;;
	CMP	word [BUF+BUF_DATA.PCLASS],1 ;;
	JNE	not_class1		;;
	JMP	SELECT_CLASS1		;;
					;;
not_class1 :				;;
	MOV	AX,[cs:SI+FTBLK.FTB_SELLEN] ;; has this FTBLK already passed the
	AND	AX,AX			;; select ?
	JNZ	SELECT_NOT_PASSED	;;
					;;
	POP	CX			;;
	JMP	STORE_FONT		;;
					;;
SELECT_NOT_PASSED :			;;
	CMP	AX,word [BUF+BUF_DATA.FSELMAX] ;;
	JNA	SELECT_NOT_LONG 	;;
	JMP	SELECT_BAD		;; cannot be more than buffer size
					;;
					;;
SELECT_NOT_LONG :			;;
	MOV	AX,[cs:SI+FTBLK.FTB_SELECT] ;;
	CMP	AX,1			;;
	JE	SELECT_1		;;
	JMP	SELECT_BAD		;;
					;;
SELECT_1 :				;;
	MOV	CX,word [BUF+BUF_DATA.FSELEN] ;; +++ SELECT = 1 +++
	AND	CX,CX			;;
	JZ	CTL_NOT_COPIED		;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;; == copy control only from one FTBLK
	AND	AX,AT_SELECT		;;
	JNZ	CTL_NOT_COPIED		;;
	JMP	SKIP_SELECT		;;
					;;
CTL_NOT_COPIED :			;;
					;;
	OR	[cs:DI+SLTS.SLT_AT],AT_SELECT ;; the FTBLK where control is copied
					;; from
					;;
	MOV	CX,[cs:SI+FTBLK.FTB_SELLEN] ;;
	CMP	CX,[cs:SI+FTBLK.FTB_DLEN] ;;
	JNA	STORE_SELECT		;;
					;;
	MOV	CX,[cs:SI+FTBLK.FTB_DLEN] ;;
					;;
STORE_SELECT:				;;
	PUSH	CX			;; CX is the length to be copied.
					;;
	PUSH	ES			;;
	PUSH	DS			;;
	PUSH	SI			;;
	PUSH	DI			;;
					;;
	MOV	AX,[cs:SI+FTBLK.FTB_DAHI] ;;
	PUSH	AX			;;
	POP	DS			;;
	MOV	SI,[cs:SI+FTBLK.FTB_DALO] ;;
					;;
	PUSH	CS			;;
	POP	ES			;;
					;;
	MOV	DI,word [BUF+BUF_DATA.PDESCO] ;;
	MOV	DI,[cs:DI+PDS.SELB_O] ;;
	ADD	DI,word [BUF+BUF_DATA.FSELEN] ;;
					;;
	REP	MOVSB			;;
					;;
					;;
	POP	DI			;;
	POP	SI			;;
	POP	DS			;;
	POP	ES			;;
					;;
	POP	CX			;;
	SUB	[cs:SI+FTBLK.FTB_DLEN],CX ;;
	SUB	[cs:SI+FTBLK.FTB_SELLEN],CX ;; == less control bytes to be copied
	ADD	[cs:SI+FTBLK.FTB_DALO],CX ;;
	ADD	word [BUF+BUF_DATA.FSELEN],CX ;;
					;;
	POP	CX			;;
					;;
					;; any data left for font ?
	CMP	word [BUF+BUF_DATA.PCLASS],1 ;;
	JNE	MORE_FONT		;;
					;;
	JMP	NEXT_FTBLK		;; == CLASS 1 printer ingnores fonts
					;;
MORE_FONT :				;; more font data ?
					;;
	JMP	STORE_FONT		;;
					;;
SELECT_CLASS1:				;;  +++ PRINTER CLASS = 1
					;;
	MOV	AX,[cs:SI+FTBLK.FTB_SELECT] ;;
	CMP	AX,2			;;
	JE	GOOD_CLASS1		;;
	JMP	SELECT_BAD		;;
					;;  select type = 2 only
GOOD_CLASS1 :				;;
	POP	CX			;;
					;;
	PUSH	ES			;; STACKS...
	PUSH	DX			;;
	PUSH	DI			;;
	MOV	AX,DI			;;
	SUB	AX,word [BUF+BUF_DATA.FTSLOTO] ;;
	SHR	AX,1			;;
	PUSH	AX			;; stack 1 -- offest
	MOV	DI,word [BUF+BUF_DATA.FTDLO] ;;
	ADD	DI,AX			;;
					;;
	MOV	AX,word [cs:DI]     ;; length copied to font buffer
					;;
	POP	DX			;; stack -1
	SHR	DX,1			;;
	PUSH	DI			;; STACK +1 -- to font buffer length
	MOV	DI,word [BUF+BUF_DATA.FTSTART] ;;
CTL_ADDR :				;;
	AND	DX,DX			;;
	JZ	CTL_LOCATED		;;
	ADD	DI,word [BUF+BUF_DATA.FTSZPA] ;;
	DEC	DX			;;
	JNZ	CTL_ADDR		;;
					;;
CTL_LOCATED :				;;
	PUSH	DI			;;
	POP	ES			;;
	XOR	DI,DI			;; start of the font buffer
	MOV	CX,[cs:SI+FTBLK.FTB_SELLEN] ;;
	AND	AX,AX			;;
	JNZ	HASBEEN_COPIED		;;
	MOV	byte [es:DI],CL     ;; 1st byte is the length
	INC	AX			;;
					;;
HASBEEN_COPIED :			;;
					;;
	ADD	DI,AX			;;
	DEC	AX			;;
	CMP	AX,CX			;; all copied ?
	JB	COPY_SELECT		;;
					;;
	POP	DI			;; STACK -1
					;;
	POP	DI			;; STACKS...
	POP	DX			;;
	POP	ES			;;
	MOV	CX,[cs:SI+FTBLK.FTB_DLEN] ;; all font data for this code page is
	SUB	[cs:SI+FTBLK.FTB_DLEN],CX ;; discarded
	ADD	[cs:SI+FTBLK.FTB_DALO],CX ;;
					;;
	JMP	NEXT_FTBLK		;;
					;;
COPY_SELECT :				;;
					;;
	SUB	CX,AX			;;
	CMP	CX,[cs:SI+FTBLK.FTB_DLEN] ;;
	JNA	FONT_SELECT		;;
					;;
	MOV	CX,[cs:SI+FTBLK.FTB_DLEN] ;;
					;;
FONT_SELECT :				;;
					;;
	PUSH	CX			;;  STACK +2
					;;
	PUSH	DS			;;  STACK +3
	PUSH	SI			;;  STACK +4
					;;
	MOV	AX,[cs:SI+FTBLK.FTB_DAHI] ;;
	PUSH	AX			;;
	POP	DS			;;
	MOV	SI,[cs:SI+FTBLK.FTB_DALO] ;;
					;;
	PUSH	DI			;; STACK +5
					;;
	REP	MOVSB			;;
					;;
	POP	DI			;; STACK -5
	POP	SI			;; STACK -4
	POP	DS			;; STACK -3
					;;
	POP	CX			;; STACK -2
	ADD	CX,DI			;;
	POP	DI			;; STACK -1
	MOV	word [cs:DI],CX     ;;
					;;
	MOV	CX,[cs:SI+FTBLK.FTB_DLEN] ;; all font data for this code page is
	SUB	[cs:SI+FTBLK.FTB_DLEN],CX ;; discarded
	ADD	[cs:SI+FTBLK.FTB_DALO],CX ;;
					;;
	POP	DI			;;
	POP	DX			;;
	POP	ES			;;
					;;
	JMP	NEXT_FTBLK		;;
					;;
					;;
SKIP_SELECT :				;; ++ SKIP SELECT ++
					;;
	MOV	CX,[cs:SI+FTBLK.FTB_SELLEN] ;;
	CMP	CX,[cs:SI+FTBLK.FTB_DLEN] ;;
	JNA	SKIP_ALL_SELLEN 	;;
	MOV	CX,[cs:SI+FTBLK.FTB_DLEN] ;;
					;;
SKIP_ALL_SELLEN :			;;
	SUB	[cs:SI+FTBLK.FTB_DLEN],CX ;;
	SUB	[cs:SI+FTBLK.FTB_SELLEN],CX ;; == less control bytes to be skipped
	ADD	[cs:SI+FTBLK.FTB_DALO],CX ;;
					;;
	POP	CX			;;
	JMP	STORE_FONT		;;
					;;
SELECT_BAD :				;; ++ BAD SELECT ++
					;;
	POP	CX			;;
					;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;;
	MOV	word [RH+RHC.RHC_STA],STAT_BADATA ;;
					;;
	OR	word [BUF+BUF_DATA.STATUS],FAIL ;;
					;;
	JMP	WRITE_RET		;;
					;;
					;;
					;; *************************************
					;; * FONT TO BE STORED OR DOWNLOADED ? *
					;; *************************************
					;;
					;; SI = points to FTBLK
					;; ES = font buffer segment / 0
					;; BX = LPT buffer
					;; DI = SLOT pointer
STORE_FONT :				;;
					;;
	CMP	[cs:SI+FTBLK.FTB_DLEN],0 ;; any font data left ?
	JNZ	HAS_FONT_DATA		;;
	JMP	NEXT_FTBLK		;;
					;;
HAS_FONT_DATA : 			;;
	PUSH	ES			;;
	POP	AX			;;
	AND	AX,AX			;;
	JNZ	STORE_FONT_BUFFER	;;
	JMP	FONT_DOWNLOAD		;;
					;;
					;;
					;;
STORE_FONT_BUFFER :			;; *****************************
	PUSH	DI			;; **  STORE TO FONT BUFFER   **
					;; *****************************
	PUSH	CX			;;
	PUSH	DS			;;  ES = font buffer segment
					;;
					;; -- determine where is the infor :
	MOV	AX,DI			;;
	SUB	AX,word [BUF+BUF_DATA.FTSLOTO] ;; relative to the start of the slot
	SHR	AX,1			;; ''       ''  '' "     of FTDL_OFF
					;;
					;;
	ADD	AX,word [BUF+BUF_DATA.FTDLO] ;;
	MOV	DI,AX			;;
					;;
					;;...................................
	MOV	CX,[cs:SI+FTBLK.FTB_DLEN] ;; length of font data
					;;
	MOV	AX,word [cs:DI]     ;; current destination
					;;
	ADD	AX,CX			;;
	PUSH	AX			;; STACK A (next destination)
					;;
	ADD	AX,[cs:SI+FTBLK.FTB_DLEFT] ;; enough room in font buffer ?
	CMP	AX,word [BUF+BUF_DATA.FTSIZE] ;;
	JNA	ROOM_FOR_FONT		;;
					;;
	POP	AX			;; STACK A
	POP	DS			;;
	POP	CX			;; **** LOOP EXIT (no room) ****
	POP	DI			;;
					;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;;
	MOV	word [RH+RHC.RHC_STA],STAT_BADATA ;;
					;;
	OR	word [BUF+BUF_DATA.STATUS],FAIL ;;
					;;
	JMP	WRITE_RET		;;
					;;
ROOM_FOR_FONT : 			;;
					;;
	PUSH	DI			;; STACK B
					;;
	MOV	DI,word [cs:DI]     ;; current destination
					;;
	PUSH	SI			;; STACK C
	PUSH	DS			;; STACK D
					;;
	MOV	AX,[cs:SI+FTBLK.FTB_DAHI] ;;
	PUSH	AX			;;
	POP	DS			;; source : FTB_DA
	MOV	SI,[cs:SI+FTBLK.FTB_DALO] ;;
					;;
	REP	MOVSB			;;
					;;
	POP	DS			;; STACK D
	POP	SI			;; STACK C
	POP	DI			;; STACK B
	POP	AX			;; STACK A
	MOV	word [cs:DI],AX     ;; next detination/current length
					;;
	POP	DS			;;
	POP	CX			;;
	POP	DI			;;
					;;
	OR	[cs:DI+SLTS.SLT_AT],AT_FONT ;; font buffer has been overwritten
					;;
	JMP	NEXT_FTBLK		;;
					;;
FONT_DOWNLOAD : 			;; ***********************************
					;; *  DOWNLOAD FONT TO THE DEVICE :  *
	PUSH	ES			;; ***********************************
	PUSH	DI			;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;; -- the logic can only support one
					;;     physical device slot that can be
					;;     downloaded.)
	MOV	AX,[cs:SI+FTBLK.FTB_DLEN] ;;
	MOV	word [RH+RH3.RH3_CNT],AX ;;
	MOV	AX,[cs:SI+FTBLK.FTB_DALO] ;;
	MOV	word [RH+RH3.RH3_DTAO],AX ;;
	MOV	AX,[cs:SI+FTBLK.FTB_DAHI] ;;
	MOV	word [RH+RH3.RH3_DTAS],AX ;;
					;;
	MOV	byte [RH+RHC.RHC_CMD],CMD_WRT ;; 06/25 MODE.COM
					;;
	PUSH	SI			;;
	PUSH	ES			;;
	PUSH	BX			;; **** BUF. is changed ****
	PUSH	BX			;;
	POP	SI			;;
	LES	BX,dword [BUF+BUF_DATA.RH_PTRO] ;; pass the request header to the
					;;
FDL_CALL_STR :				;;
	CALL	dword [cs:SI+BUF_DATA.LPT_STRAO] ;; LPTn strategy routine.
	POP	BX			;;
	POP	ES			;;
	POP	SI			;;
					;;
FDL_CALL_ITR :				;;
	CALL	dword [BUF+BUF_DATA.LPT_INTRO] ;; interrupt the DOS LPTn
					;;
FDL_ITR_RETURN :			;;
	MOV	AX,word [RH+RHC.RHC_STA] ;;
					;;
	and	ax,STAT_ERROR		;;
	jz	fdl_good1		;;
	mov	ax,STAT_DEVERR		;;
	mov	word [RH+RHC.RHC_STA],ax ;;
					;;
fdl_good1 :				;;
	POP	DI			;;
	POP	ES			;;
					;;
	AND	AX,STAT_ERROR		;; any error returned by normal device?
	JNZ	FDL_BAD 		;;
	OR	[cs:DI+SLTS.SLT_AT],AT_RAM1 ;;
	JMP	NEXT_FTBLK		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
FDL_BAD :				;; **** LOOP EXIT (bad) ****
	OR	word [BUF+BUF_DATA.STATUS],FAIL ;;
					;;
	JMP	WRITE_RET		;;
					;;
WRT_NORMAL :				;;
					;;
	JMP	NORM_DRIVER		;;
					;;
WRT_ignore :				;;
					;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;;
	MOV	word [RH+RHC.RHC_STA],STAT_DEVERR ;;
	JMP	WRITE_RET		;;
					;;
NO_MORE_FTBLK : 			;;
					;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;;
	MOV	word [RH+RHC.RHC_STA],0 ;;
					;;
WRITE_RET :				;;
	RET				;;
					;;
;WRITE	    ENDP			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;====	Generic IOCTL Designate Start  ======
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DESIGNATE_START:       ;;
	MOV	AX,word [BUF+BUF_DATA.STATE] ;;
	CMP	AX,NORMAL		;;
	JNE	DS_00			;G; ALL OF THESE EXTRA JUMPS ARE
	JMP	DST_NORMAL		;;  DUE TO SIZE OF FOLLOWING CODE!!!!!
DS_00:	CMP	AX,CPSW 		;; WGR						 ;AN000;
	JE	DS_01			;G;
	CMP	AX,LOCKED		;; WGR						 ;AN000;
	JE	DS_03			;; WGR						 ;AN000;
	JMP	DST_CMDERR		;G;

DS_01:	CALL	CHECK_PRINT_ACTIVE	;G; THIS WILL FIND OUT IF THE
	JNC	DS_02			;G;
DS_03:					;; WGR						 ;AN000;
	JMP	DST_DEVERR		;G; PRINT.COM IS ACTIVE, CY=1 MEANS YES
					;G;
DS_02:	LDS	SI,dword [RH+GIH.GIH_GBA] ;; GIOB = DS:[SI]
	MOV	AX,word [GIOB+GB1S.GB1_FLAG] ;;
	AND	AX,DSF_CARTCP		;;
	JNZ	DST_DEVERR		;; DO NOT SUPPORT CARTRIDGE FLAG !!!!
					;;
					;; ******************************
					;; **  DESIGNATE / REFRESH  ?  **
					;; ******************************
					;; check the LENGTH in BUFFER1
					;;
	MOV	CX,word [GIOB+GB1S.GB1_LEN] ;;
	AND	CX,CX			;;
	JNZ	DST_NOT_NULL		;;
					;;
	mov  word [cs:INIT_CHK],0fefeh ;;
					;;
	JMP	DST_REFRESH		;; null lenght ==> refresh
					;;
DST_NOT_NULL :				;;
	MOV	AX,CX			;;
	SHR	AX,1			;; divide by 2
	MOV	CX,AX			;;
	MOV	AX,STAT_CMDERR		;; error if LEN < 2
	AND	CX,CX			;;
	JZ	DST_RET 		;;
	DEC	CX			;;
	JNZ	NO_REFRESH		;;
					;;
	MOV	AX,word [GIOB+GB1S.GB1_NUM] ;;
	AND	AX,AX			;;
	MOV	AX,STAT_BADATA		;;
	JNZ	DST_RET 		;; error, as no code pages followed
					;;
	mov  word [cs:INIT_CHK],0ffeeh ;;
					;;
					;;
	JMP	DST_REFRESH		;; null length => REFRESH font from
					;;		  font buffer to device
					;; *********************************
					;; **  DESIGNATE FOR CARTRIDGE ?  **
NO_REFRESH :				;; *********************************
					;; CX = number of codepages designated
	CMP	word [BUF+BUF_DATA.PCLASS],1 ;;  CLASS 1 Printer ?
	JNE	DST_RAM 		;;
	JMP	DST_CART		;;
					;;
DST_RAM :				;;
					;;
	MOV	AX,DSF_CARTCP		;; RAM-code pages
	NOT	AX			;;
	AND	word [BUF+BUF_DATA.STATUS],AX ;; not CARTCP
	MOV	DI,word [BUF+BUF_DATA.RMBUFO] ;; DI
	MOV	DX,word [BUF+BUF_DATA.RSLMX] ;; DX = number of designate allowed
					;;	(limited by available slots)
	MOV	AX,STAT_TOMANY		;;
	CMP	CX,DX			;; more codepages than supported ?
	JA	DST_RET 		;;
					;;
	JMP	DST_DESIGNATE		;;
					;;
DST_NORMAL :				;;
	push	cs			;;
	pop	ds			;;
	JMP	NORM_DRIVER		;;
					;;
DST_DEVERR :				;;
	MOV	AX,STAT_DEVERR		;;
	JMP	DST_RET 		;G;
					;;
DST_CMDERR :				;G;
	MOV	AX,STAT_CMDERR		;G;
DST_RET :				;;
	JMP	DST_RETURN		;;
					;;
DST_CART:				;;
	MOV	AX,DSF_CARTCP		;; Hardware code pages
	OR	word [BUF+BUF_DATA.STATUS],AX ;;
	MOV	DI,word [BUF+BUF_DATA.HRBUFO] ;; DI
	MOV	DX,word [BUF+BUF_DATA.HSLMX] ;; DX = number of slots available
	MOV	AX,DX			;;
	SUB	AX,word [BUF+BUF_DATA.HARDMX] ;; no. of designate allowed
					;;
	CMP	CX,AX			;; more codepages than supported ?
	MOV	AX,STAT_TOMANY		;;
	JA	DST_RET 		;;
;;---------------------------------------------------------------------------
					;; *************************************
DST_DESIGNATE : 			;; * any duplicated codepages in MODE ?*
					;; * define the slot-buffer	       *
					;; *************************************
					;;
					;; -- Use the buffer to hold the code
					;;    page value in the MODE with the
					;;    position correspondence :
					;; 1. reset the buffer to all 0FFFFH
					;; 2. if the code page in MODE does not
					;;    replicate with any in the buffer,
					;;    then store the code page value in
					;;    the buffer.
					;; 3. proceed to the next code page in
					;;    the MODE to check with what is
					;;    already copied to the buffer.
					;; 4. designate will fail if there is a
					;;    replication : i.e. a repetition
					;;    in the MODE command.
					;; 5. skip the buffer corresponding to
					;;    HWCP codepages
					;;-------------------------------------
					;;
	PUSH	DI			;; (the start of RAM/Hardware buffer)
	PUSH	DX			;; count of buffer size
	MOV	AX,0FFFFH		;;
RESET_BUF:				;;
	MOV	[cs:DI],AX		;; reset all buffer to 0FFFFH
	INC	DI			;;
	INC	DI			;;
	DEC	DX			;;
	JNZ	RESET_BUF		;;
	POP	DX			;;
	POP	DI			;;
					;;
	PUSH	BX			;;
	PUSH	DI			;; (the start of RAM/Hardware buffer)
	PUSH	DX			;; count of buffer size
	PUSH	SI			;; first code page in GB1
	PUSH	CX			;; number of codepages in GB1
					;;
	PUSH	SI			;;
					;;
	MOV	AX,word [BUF+BUF_DATA.STATUS] ;;
	AND	AX,DSF_CARTCP		;;
	JZ	FILL_BUFFER		;;
					;;  for cartridge designation
	MOV	SI,word [BUF+BUF_DATA.HARDSO] ;;
SKIP_HWCP:				;;
	MOV	AX,[cs:SI+SLTS.SLT_AT] ;;
	AND	AX,AT_HWCP		;;
	JZ	FILL_BUFFER		;;
	INC	SI			;; skip the hwcp slots, they cannot be
	INC	SI			;; designated
	INC	SI			;;
	INC	SI			;;
	INC	DI			;;
	INC	DI			;;
	JMP	SKIP_HWCP		;;
					;;
FILL_BUFFER :				;;
					;;
	POP	SI			;;
					;;
	PUSH	DI			;;
	POP	BX			;; BX = the positioned buffer
					;;
DST_BUFLP :				;; **** LOOP ****
	MOV	AX,word [GIOB+GB1S.GB1_CP] ;; (use GIOB only for codepages)
	CMP	AX,0FFFFH		;;
	JZ	DST_BUFNXT		;;
					;;
	PUSH	CX			;;
					;; compare code page with SLOT-BUFFER
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; SCAN THE BUFFER FOR DUPLICATION
	PUSH	DX			;;
	POP	CX			;; no. of buffer entries
					;;
	PUSH	ES			;;
	PUSH	DI			;;
	PUSH	CS			;;
	POP	ES			;;
	REPNE	SCASW			;; scan codepage vs. buffer
	POP	DI			;;
	POP	ES			;;
					;;
	POP	CX			;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
	JNE	BUF_DEFINE		;;
					;;
					;; **** EXIT FROM LOOP ****
					;;
	POP	CX			;; number of codepages in GB1
	POP	SI			;; first code page in GB1
	POP	DX			;; count of buffer size
	POP	DI			;; (the start of RAM/Hardware buffer)
	POP	BX			;;
					;;
	MOV	AX,STAT_DUPLCP		;; Duplicated code page
	JMP	DST_RETURN		;;
					;;
					;;
BUF_DEFINE :				;;
	MOV	[cs:BX],AX		;; no duplicated cp in MODE list
					;;
					;;
					;; **** NEXT IN LOOP ****
DST_BUFNXT:				;;
	INC	SI			;; (use GIOB only for codepages)
	INC	SI			;;
	INC	BX			;;
	INC	BX			;;
	XOR	AX,AX			;;
	DEC	CX			;;
	JNZ	DST_BUFLP		;;
					;;
					;;
	POP	CX			;; number of codepages in GB1
	POP	SI			;; first code page in GB1
	POP	DX			;; count of buffer size
	POP	DI			;; (the start of RAM/Hardware buffer)
	POP	BX			;;
					;;
					;;
;;-----------------------------------------------------------------------------
					;;*************************************
					;;* any duplicated codepages bet MODE *
					;;* and code pages in the slot ?      *
					;;*************************************
					;; -- for each code page in the slot,
					;;    check for any duplication to
					;;    code pages in buffer, if the code
					;;    page in the slot is not to be
					;;    replaced.
					;; -- the designate fails if there is
					;;    duplication.
					;; -- copy the codepage in the slot to
					;;    the buffer if is not to be
					;;    replaced. Mark the slot to be
					;;    AT_OLD.
					;; -- if the code page is tobe replaced
					;;    mark the STATUS with REPLX.
					;;-------------------------------------
					;;
	MOV	CX,DX			;; both slots & buffer of same size
					;; --exclude the hwcp which is not
					;;   designatable
	MOV	SI,word [BUF+BUF_DATA.HARDSO] ;; SI = hardware slot
					;;
	MOV	AX,word [BUF+BUF_DATA.STATUS] ;;
	AND	AX,DSF_CARTCP		;;
	JNZ	CMP_CP			;;
	MOV	SI,word [BUF+BUF_DATA.RAMSO] ;; SI = RAM slot
CMP_CP: 				;;
	MOV	word [BUF+BUF_DATA.FTSLOTO],SI ;;
					;;
	PUSH	DI			;; (the start of RAM/Hardware buffer)
	PUSH	DX			;; count of buffer size
	PUSH	SI			;; first entry in RAM/hardware slot
	PUSH	CX			;; slot size
	PUSH	BX			;;
					;;
	PUSH	DI			;;
	POP	BX			;; BX = the positioned buffer
DST_SLTLP :				;;
					;; **** LOOP ****
					;;
	MOV	AX,AT_OLD		;; =**=
	NOT	AX			;; assumed the codepage in slot is new,
	AND	[cs:SI+SLTS.SLT_AT],AX ;; to be downloaded if buffer <> 0FFFFH
					;;
	AND	[cs:SI+SLTS.SLT_AT],AT_NO_LOAD ; -- codepage not to be loaded
	AND	[cs:SI+SLTS.SLT_AT],AT_NO_FONT ; -- no font has been loaded
					;;
	MOV	AX,[cs:SI+SLTS.SLT_CP] ;;
	CMP	AX,0FFFFH		;;
	JZ	DST_SLTNXT		;;
					;;
	PUSH	CX			;;
	MOV	CX,[cs:BX]		;;
	CMP	CX,0FFFFH		;; if this slot to be replaced ?
	POP	CX			;;
	JNZ	DST_SLTREPLACED 	;; YES, the buffer is not empty
					;;
					;; compare code page with SLOT-BUFFER
	PUSH	CX			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; SCAN THE BUFFER FOR DUPLICATION
	PUSH	DX			;;
	POP	CX			;; no. of buffer entries
					;;
	PUSH	ES			;;
	PUSH	DI			;;
	PUSH	CS			;;
	POP	ES			;;
	REPNE	SCASW			;; scan codepage vs. buffer
	POP	DI			;;
	POP	ES			;;
					;;
	POP	CX			;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
	JNE	SLT_BUF_DEF		;;
					;;
					;; **** LOOP EXIT ****
					;;
	POP	BX			;;
	POP	CX			;; number of codepages in slots
	POP	SI			;; first entry in RAM/hardware slots
	POP	DX			;; count of buffer size
	POP	DI			;; (the start of RAM/Hardware buffer)
					;;
	MOV	AX,STAT_DUPLCP		;; Duplicated code page
	JMP	DST_RETURN		;;
					;;
					;;
SLT_BUF_DEF:				;;
	MOV	[cs:BX],AX		;; no duplicated cp, there was no cp in
					;; =**=
	OR	[cs:SI+SLTS.SLT_AT],AT_OLD ;; mark old so as no new font download
					;;
	JMP	DST_SLTNXT		;; the MODE command for this position
					;;
DST_SLTREPLACED :			;;
	PUSH	BX			;;
	POP	AX			;; save the buffer slot-position
	POP	BX			;;
	OR	word [BUF+BUF_DATA.STATUS],REPLX ;; there are codepage in slots replaced
	PUSH	BX			;;
	PUSH	AX			;;
	POP	BX			;; gets back the buffer position
					;;
					;; **** NEXT IN LOOP ****
					;;
DST_SLTNXT:				;;
	INC	SI			;; will take whatever is in buffer
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
	INC	BX			;; position slot in buffer
	INC	BX			;;
	XOR	AX,AX			;;
	DEC	CX			;;
	JNZ	DST_SLTLP		;;
					;;
					;;
	POP	BX			;;
	POP	CX			;; slot size
	POP	SI			;; first entry in RAM/hardware slots
	POP	DX			;; count of buffer size
	POP	DI			;; (the start of RAM/Hardware buffer)
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;************************************
					;;* prepare the FTABLE		     *
					;;************************************
					;;
					;; -- CX slot / buffer size
					;;    SI slot
					;;    DI buffer
					;;------------------------------------
	PUSH	BX			;; STACK +1
	PUSH	SI			;; STACK +2
					;; =**=
	MOV	AX,FAIL 		;;
	NOT	AX			;;
	AND	word [BUF+BUF_DATA.STATUS],AX ;; assume it is successful
					;;
					;;
PREPARE_FTB :				;; Prepare for Font Parser
	LEA	BX,[FTABLE];;
	MOV	[cs:BX+FBUFS.FLAG],FLAG_RESTART ;
	MOV	[cs:BX+FBUFS.BUFFER_LEN],0 ;; no data packet
	MOV	[cs:BX+FBUFS.NUM_FTBLK],0 ;;
					;;
	ADD	BX,sizeof.FBUFS ;; points to the first FTBLK.
	XOR	DX,DX			;; DX = FTBLK entries (no code page yet)
					;;
					;;
GET_CODEPAGE :				;; **** LOOP ****
	AND	CX,CX			;;
	JZ	NO_MORE_SLOT		;;
	MOV	AX,[cs:SI+SLTS.SLT_AT] ;;
	AND	AX,AT_OLD		;;
	JZ	NEW_CODEPAGE		;;
					;;
	MOV	AX,[cs:SI+SLTS.SLT_AT] ;;
	AND	AX,AT_HWCP		;;
	JZ	GET_NEXT		;; not NEW and not HWCP
	AND	[cs:SI+SLTS.SLT_AT], NOT AT_OLD ;; also load for HWCP
					;;
NEW_CODEPAGE :				;;
	MOV	AX,[cs:DI]		;; -- SLOT_AT is not old
					;; -- code page in buffer is not 0FFFFH
	CMP	AX,0FFFFH		;;
	JE	GET_NEXT		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	INC	DX			;; LOAD FONT as :
	MOV	AX,[cs:DI]		;; codepage in buffer is new code page
					;;
	OR	[cs:SI+SLTS.SLT_AT],AT_LOAD ;; set the attribute indicating load
					;;
	MOV	[cs:BX+FTBLK.FTB_CP],AX ;;
					;;
	ADD	BX,sizeof.FTBLK ;; next FTBLK
					;;
					;;
GET_NEXT :				;; **** NEXT IN LOOP ****
	INC	DI			;;
	INC	DI			;; next in buffer
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
	INC	SI			;; next in slot
	DEC	CX			;;
	JMP	GET_CODEPAGE		;;
					;;
NO_MORE_SLOT :				;; **** EXIT LOOP ****
	AND	DX,DX			;;
	JNZ	DEFINE_DID		;;
	JMP	NO_FONT_DOWNL		;;
					;;
					;; **********************************
					;; ** NEXT STATE = DESIGNATE_WRITE **
					;; **********************************
					;;
DEFINE_DID :				;;
	POP	SI			;; STACK -2
	POP	BX			;; STACK -1
					;;
	PUSH	BX			;; STACK +1
	PUSH	SI			;; STACK +2
					;;
	PUSH	DI			;; STACK +3
	PUSH	CX			;; STACK +4
	PUSH	ES			;; STACK +5
	PUSH	DS			;; STACK +6
					;;
	PUSH	CS			;;
	POP	ES			;;
	PUSH	CS			;;
	POP	DS			;;
					;;
	MOV	SI,BX			;; GET THE DEVICE_ID FROM LPTn BUFFER
	LEA	SI,[SI+BUF_DATA.PAR_EXTRACTO] ;;
	MOV	SI,[cs:SI+PAR_DEVOT.PAR_DIDO] ;;
	LEA	SI,[SI+PAR_DIDT.PAR_DID] ;;
					;;
	LEA	DI,[FTABLE];;
	MOV	[cs:DI+FBUFS.NUM_FTBLK],DX ;;
					;;
	ADD	DI,sizeof.FBUFS ;;
	LEA	DI,[DI+FTBLK.FTB_TID] ;;
					;;
SET_DID :				;;
	MOV	CX,8			;;
	PUSH	SI			;;
	PUSH	DI			;;
					;;
	REP	MOVSB			;;
					;;
	POP	DI			;;
	POP	SI			;;
					;;
	ADD	DI,sizeof.FTBLK ;; next DID
	DEC	DX			;;
	JNZ	SET_DID 		;;
					;;
	POP	DS			;; STACK -6
	POP	ES			;; STACK -5
	POP	CX			;; STACK -4
	POP	DI			;; STACK -3
					;;
	CALL	FONT_PARSER		;; restart font parser
					;;
	LEA	BX,[FTABLE];;
	ADD	BX,sizeof.FBUFS ;;
	CMP	[cs:BX+FTBLK.FTB_STATUS],FSTAT_SEARCH
					;;
	JE	FONT_DOWNL		;;
	MOV	AX,STAT_DEVERR		;;
	POP	SI			;; STACK -2
	POP	BX			;; STACK -1
	JMP	DST_RETURN		;; there is no designate_end if fails
					;;
FONT_DOWNL :				;;
	POP	SI			;; STACK -2
	POP	BX			;; STACK -1
	MOV	word [BUF+BUF_DATA.STATE],DESG_WR ;; enter DESIGNATE_WRITE state
	MOV	word [BUF+BUF_DATA.FSELEN],0 ;; for font selection control loading
					;;
	PUSH	CX			;; init the font buffer address of
	PUSH	DI			;; each codepage
	PUSH	SI			;;
	MOV	DI,word [BUF+BUF_DATA.FTDLO] ;;
					;;
	MOV	CX,word [BUF+BUF_DATA.RSLMX] ;;
	MOV	AX,word [BUF+BUF_DATA.STATUS] ;;
	AND	AX,DSF_CARTCP		;;
	JZ	FTDL_LOOP		;;
	MOV	CX,word [BUF+BUF_DATA.HSLMX] ;;
					;;
FTDL_LOOP :				;;
	AND	CX,CX			;;
	JZ	FTDL_DONE		;;
	mov	ax,[cs:si+SLTS.SLT_AT] ;;
	and	ax,AT_LOAD		;;
	jz	ftdl_next		;;
					;;
	MOV	word [cs:DI],0    ;; the font length in font buffer is 0
					;;
ftdl_next :				;;
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JMP	FTDL_LOOP		;;
FTDL_DONE :				;;
	POP	SI			;;
	POP	DI			;;
	POP	CX			;;
					;;
	JMP	CHECK_OTHER		;;
					;;
					;;  *******************************
					;;  ** NEXT STATE = DSIGNATE_END **
					;;  *******************************
NO_FONT_DOWNL : 			;;
	POP	SI			;; STACK -2
	POP	BX			;; STACK -1
	MOV	word [BUF+BUF_DATA.STATE],DESG_END ;; proper designate end, ignore write
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHECK_OTHER :				;;
					;;
	MOV	DX,word [BUF+BUF_DATA.STATUS] ;;
	MOV	AX,REPLX		;;
	NOT	AX			;;
	AND	AX,DX			;; reset the bit for "replaced"
	MOV	word [BUF+BUF_DATA.STATUS],AX ;;
					;;
	XOR	AX,AX			;;
	AND	DX,REPLX		;;
	JMP	DST_RETURN		;;
					;; only for the FIFO
	JMP	DST_RETURN		;;
					;;
					;;
DST_REFRESH:				;;  ******************************
					;;  **	REFRESH FONT TO DEVICE	**
					;;  ******************************
					;;  -- if there is RAM buffer on device
					;;  -- if there is font assumed to be
					;;     on the device, then
					;;  -- load the font to the device,
					;;     but no change in slot attributes
					;;
	OR	word [BUF+BUF_DATA.STATUS],REFRESH ;;  -- STATE = CPSW (for Designate_end)
					;;
	MOV	CX,word [BUF+BUF_DATA.RSLMX] ;;
	AND	CX,CX			;;
	JNZ	DST_CHECK_FBUFFER	;;
	JMP	DST_REF_INVK		;; invoke any active code page
					;;
DST_CHECK_FBUFFER:			;;
	MOV	DI,word [BUF+BUF_DATA.RAMSO] ;;
					;;
DST_RAMLP:				;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;;
	AND	AX,AT_RAM1		;;
	JNZ	DST_RAM_LOCATED 	;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JNZ	DST_RAMLP		;;
	JMP	DST_REF_INVK		;; there was no font loaded
					;;
DST_RAM_LOCATED:			;;
	CMP	word [BUF+BUF_DATA.RBUFMX],0 ;; ANY FONT BUFFER TO BE COPIED FROM ?
	JA	DST_HAS_BUFFER		;;
	MOV	AX,STAT_NOBUFF		;;
	mov  [cs:INIT_CHK],ax ;;
	JMP	DST_RETURN		;; ERROR !!!
					;;
DST_HAS_BUFFER :			;;
	SUB	DI,word [BUF+BUF_DATA.RAMSO] ;; relative to .RAMSO
	SHR	DI,1			;; relative to .FTLDO
	PUSH	DI			;;
					;;
	SHR	DI,1			;; the nth
	MOV	CX,DI			;;
	MOV	AX,word [BUF+BUF_DATA.FTSTART] ;;
					;;
DST_LOCATE_FT:				;;
	AND	CX,CX			;;
	JZ	DST_FT_LOCATED		;;
	ADD	AX,word [BUF+BUF_DATA.FTSZPA] ;;
	DEC	CX			;;
	JNZ	DST_LOCATE_FT		;;
					;;
DST_FT_LOCATED: 			;;
					;;
	POP	DI			;;
	ADD	DI,word [BUF+BUF_DATA.FTDLO] ;;
	MOV	CX,word [cs:DI]     ;;
					;;....................................
					;; DOWNLOAD THE FONT TO DEVICE
	MOV	SI,word [BUF+BUF_DATA.RNORMO] ;;
	MOV	[cs:SI+RHC.RHC_LEN],20 ;;
	MOV	[cs:SI+RHC.RHC_CMD],CMD_WRT ;;
	MOV	[cs:SI+RH3.RH3_CNT],CX ;;
	MOV	[cs:SI+RH3.RH3_DTAO],0 ;;
	MOV	[cs:SI+RH3.RH3_DTAS],AX ;;
					;;
	PUSH	BX			;;
					;;
	PUSH	BX			;;
	POP	DI			;; save BX in DI
	PUSH	CS			;;
	POP	ES			;;
	MOV	BX,SI			;; ES:BX = REQ_NORMn (CS:[SI])
					;;
	CALL	dword [cs:DI+BUF_DATA.LPT_STRAO]
					;;
	CALL	dword [cs:DI+BUF_DATA.LPT_INTRO]
					;;
	POP	BX			;;
					;;
	MOV	AX,[cs:SI+RHC.RHC_STA] ;;
					;;
	and	ax,STAT_ERROR		;;
	jz	fdl_good2		;;
	mov	ax,STAT_DEVERR		;;
					;;
fdl_good2 :				;;
	PUSH	AX			;;
	AND	AX,STAT_ERROR		;;
	POP	AX			;;
	JZ	DST_REF_INVK		;;
					;;
					;;
DST_RETURN :				;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;;
	MOV	word [RH+RHC.RHC_STA],AX ;;
					;;
	push	cs			;;
	pop	ds			;;
					;;
	RET				;;
					;;
					;;
DST_REF_INVK :				;; INVOKE FOR REFRESH
					;;
					;; ************************************
					;; * INVOKE HIERIECHY : RAM, HARDWARE *
					;; ************************************
					;;
	MOV	DI,word [BUF+BUF_DATA.RAMSO] ;; check with the ram-slots  (DI)
	MOV	CX,word [BUF+BUF_DATA.RSLMX] ;; CX = size
	AND	CX,CX			;;
	JZ	DST_HWCP_CHK		;;
					;;
DST_RAM_CMP:				;; there are RAM-slots
DST_RAM_LP:				;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;;
	AND	AX,AT_ACT		;;
	JNZ	DST_IVK_CP		;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JNZ	DST_RAM_LP		;;
					;;
DST_HWCP_CHK :				;;
	MOV	DI,word [BUF+BUF_DATA.HARDSO] ;; check with the HWCP-slots  (DI)
	MOV	CX,word [BUF+BUF_DATA.HSLMX] ;; CX = size
	AND	CX,CX			;;
	JNZ	DST_HWCP_CMP		;;
	JMP	DST_NO_IVK		;;
					;;
DST_HWCP_CMP :				;;
DST_HWCP_LP:				;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;;
	AND	AX,AT_ACT		;;
	JZ	DST_HWCP_NEXT		;;
	JMP	DST_IVK_CP		;;
					;;
DST_HWCP_NEXT : 			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JNZ	DST_HWCP_LP		;;
					;;
DST_NO_IVK:				;;
	XOR	AX,AX			;;
	JMP	DST_RETURN		;;
					;;
DST_IVK_CP :				;;
	PUSH	SI			;;
					;;
	MOV	SI,word [BUF+BUF_DATA.RNORMO] ;;
	MOV	AX,SI			;;
	ADD	AX,sizeof.GIH ;; points to buffer
					;;
	PUSH	AX			;;
	LEA	SI,[SI+GIH.GIH_GBA] ;;
	MOV	word [cs:SI],AX
	INC	SI			;;
	INC	SI			;;
	MOV	word [cs:SI],CS     ;;
	POP	SI			;;
	MOV	[cs:SI+GB2S.GB2_LEN],2 ;;
	MOV	AX,[cs:DI+SLTS.SLT_CP] ;;
	MOV	[cs:SI+GB2S.GB2_CP],AX ;;
					;;
	POP	SI			;;
	PUSH	CS			;; define RH = ES:[DI]
	POP	ES			;;
	MOV	DI,word [BUF+BUF_DATA.RNORMO] ;;
					;;
	push	cs			;;
	pop	ds			;;
					;;
	JMP	INVOKE			;;
					;;
;DESIGNATE_START ENDP			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;====	Generic IOCTL Designate End  ======
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DESIGNATE_END:       ;;
					;;
	MOV	AX,word [BUF+BUF_DATA.STATE] ;;
	CMP	AX,LOCKED		;; WGR						 ;AN000;
	JNE	DE_01			;; WGR						 ;AN000;
	MOV	AX,STAT_BADDEN		;; WGR						 ;AN000;
	JMP	DE_11			;; WGR						 ;AN000;
DE_01:					;; WGR						 ;AN000;
	CMP	AX,CPSW 		;;
	JNE	DEN_NOT_CPSW		;;
	MOV	AX,word [BUF+BUF_DATA.STATUS] ;; any refresh ?
	AND	AX,REFRESH		;;
	JNZ	DEN_REFRESH		;;
	MOV	AX,STAT_BADDEN		;;
	JMP	DEN_FAIL		;;
					;;
DEN_REFRESH :				;;
	AND	word [BUF+BUF_DATA.STATUS],NOT REFRESH ;;
	XOR	AX,AX			;;
	JMP	DEN_RET 		;;
					;;
DEN_NOT_CPSW :				;;
	CMP	AX,NORMAL		;;
	JNE	den_NOT_NORMAL		;;
	JMP	NORM_DRIVER		;; not in the code page switching stage
					;;
den_NOT_NORMAL :			;;
	CMP	AX,DESG_END		;;
	JNE	den_other		;;
	JMP	DEN_ENDED		;;  end with no error check
					;;
den_other :				;;
	CMP	AX,DESG_WR		;;
	JE	den_write		;;
	MOV	AX,STAT_BADDEN		;;
	JMP	DEN_FAIL		 ;; no designate start
					;;-------------------------
den_write :				;; DESIGNATE WRITE ended
					;;
	MOV	AX,word [BUF+BUF_DATA.STATUS] ;;
	AND	AX,FAIL 		;;
	JZ	DEN_FTABLE		;; failed in the middle of desig-write
	XOR	AX,AX			;;
	JMP	DEN_FAIL		 ;; ignore the DEN
					;;
DEN_FTABLE :				;;
					;;
	LEA	DI,[FTABLE];;
	ADD	DI,sizeof.FBUFS ;;
	MOV	AX,[cs:DI+FTBLK.FTB_STATUS] ;;
	CMP	AX,FSTAT_COMPLETE	;;
	JE	DEN_ENDED		;;
					;;
	CMP	AX,FSTAT_FONT		;;
	JE	DEN_FONT		;;
	MOV	AX,STAT_bffDEN		;; bad font file
	JMP	DEN_FAIL		 ;; the font data was not complete
					;;
DEN_FONT :				;;
	MOV	AX,[cs:DI+FTBLK.FTB_DLEFT] ;;
	AND	AX,AX			;;
	JZ	DEN_ENDED		;;
	MOV	AX,STAT_bffDEN		;;
	JMP	DEN_FAIL		 ;;
					;;
DEN_ENDED :				;; good designate-end
					;;
	MOV	DI,word [BUF+BUF_DATA.HARDSO] ;; to hardware slot
	MOV	SI,word [BUF+BUF_DATA.HRBUFO] ;; to hardware-buffer
HARD_HWCPE:				;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;; skip the HWCP
	AND	AX,AT_HWCP		;;
	JZ	HARD_CARTE		;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	SI			;;
	INC	SI			;;
	JMP	HARD_HWCPE		;;
HARD_CARTE:				;;
	MOV	CX,word [BUF+BUF_DATA.HSLMX] ;; size of both hardware slot/buffer
	SUB	CX,word [BUF+BUF_DATA.HARDMX] ;; slots that can be designated????????
	MOV	AX,word [BUF+BUF_DATA.STATUS] ;;
	AND	AX,DSF_CARTCP		;;
	JZ	ASSIGN_RAM		;;
					;;
					;;
	MOV	AX,STAT_TOMANY		;;
	AND	CX,CX			;; any cart-slot to be designated ?
	JNZ	ASSIGN_CP_CART		 ;;
	JMP	DEN_FAIL		 ;;
					;;
					;;
ASSIGN_CP_CART :			;;
	JMP	ASSIGN_CP		;;
					;;
ASSIGN_RAM:				;;
	MOV	DI,word [BUF+BUF_DATA.RAMSO] ;; to RAM slot
	MOV	SI,word [BUF+BUF_DATA.RMBUFO] ;; to RAM-buffer
	MOV	CX,word [BUF+BUF_DATA.RSLMX] ;; size of both RAM slot/buffer
					;;
	MOV	AX,STAT_TOMANY		;;
	AND	CX,CX			;; any cart-slot to be designated ?
	JNZ	ASSIGN_CP		 ;;
	JMP	DEN_FAIL		 ;;
					;;
ASSIGN_CP:				;;
	MOV	AX,AT_LOAD		;;
	OR	AX,AT_FONT		;;
	OR	AX,AT_SELECT		;;
	NOT	AX			;;
	AND	[cs:DI+SLTS.SLT_AT],AX ;; reset load, font, select attributes
					;;
	MOV	AX,[cs:SI]		;; code page assigned
	MOV	[cs:DI+SLTS.SLT_CP],AX ;;
					;;
	CMP	AX,0FFFFH		;;
	JNE	SLOT_OCC		;;
	MOV	AX,AT_OCC		;;
	NOT	AX			;; empty
	AND	[cs:DI+SLTS.SLT_AT],AX ;;
	JMP	ASSIGN_NEXT		;;
SLOT_OCC:				;;
	OR	[cs:DI+SLTS.SLT_AT],AT_OCC ;; occupied
					;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;;
	AND	AX,AT_OLD		;;
	JNZ	ASSIGN_NEXT		;;
					;;
NOT_ACTIVE:				;; this newly designated is not active
	MOV	AX,AT_ACT		;;
	NOT	AX			;;
	AND	[cs:DI+SLTS.SLT_AT],AX ;;    not active
	CMP	word [BUF+BUF_DATA.RBUFMX],0 ;;
	JE	ASSIGN_NEXT		;;
	AND	[cs:DI+SLTS.SLT_AT],NOT AT_RAM1 ;;  not loaded to physical RAM until
					;;    the code page is selected
ASSIGN_NEXT :				;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	SI			;;
	INC	SI			;;
	DEC	CX			;;
	AND	CX,CX			;;
	JNE	ASSIGN_CP		;;
					;;
	MOV	CX,word [BUF+BUF_DATA.FSELEN] ;; COPY SELECT-CONTROL for CLASS 0
	AND	CX,CX			;;
	JZ	DEN_NO_SELECT		;;
					;;
	PUSH	ES			;;
	PUSH	DS			;;
	PUSH	SI			;;
	PUSH	DI			;;
					;;
	PUSH	CS			;;
	POP	ES			;;
	PUSH	CS			;;
	POP	DS			;;
					;;
	PUSH	DX			;;
	MOV	DI,word [BUF+BUF_DATA.PDESCO] ;;
	MOV	SI,[cs:DI+PDS.SELB_O] ;;
	PUSH	DI			;;
	MOV	DI,[cs:DI+PDS.SELH_O] ;;
	XOR	DX,DX			;;
	MOV	DL,byte [cs:SI]     ;;
	ADD	DX,DI			;;
	INC	DX			;; of the length byte
					;;
	REP	MOVSB			;;
					;;
	POP	DI			;;
	MOV	[cs:DI+PDS.SELR_O],DX ;;
	POP	DX			;;
					;;
	POP	DI			;;
	POP	SI			;;
	POP	DS			;;
	POP	ES			;;
					;;
	MOV	word [BUF+BUF_DATA.FSELEN],0 ;;
					;;
DEN_NO_SELECT : 			;;
	XOR	AX,AX			;; clear status
	JMP	DEN_RET 		;;
					;;
DEN_FAIL :				;;------------------------------------
	PUSH	AX			;; ANY FONT BUFFER DESTROYED ?
					;;
	MOV	AX,word [BUF+BUF_DATA.STATUS] ;;
	AND	AX,DSF_CARTCP		;;
	JZ	DEN_RAM_FAIL		;;
					;;
	MOV	DI,word [BUF+BUF_DATA.FTSLOTO] ;;
	MOV	CX,word [BUF+BUF_DATA.HSLMX] ;;
	JMP	DEN_FAIL_LOOP		;;
					;;
DEN_RAM_FAIL :				;;
	MOV	DI,word [BUF+BUF_DATA.RAMSO] ;; to RAM slot
	MOV	CX,word [BUF+BUF_DATA.RSLMX] ;; size of both RAM slot/buffer
	MOV	DX,word [BUF+BUF_DATA.RBUFMX] ;;
					;;
	AND	DX,DX			;;
	JZ	DEN_FAIL_RET		;;
					;;
DEN_FAIL_LOOP : 			;;
	AND	CX,CX			;;
	JZ	DEN_FAIL_RET		;;
					;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;;
	AND	AX,AT_LOAD		;;
	JZ	DEN_FAIL_NEXT		;;
					;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;;
	AND	AX,AT_HWCP		;;
	JNZ	DEN_FAIL_NEXT		;;
					;;
	MOV	[cs:DI+SLTS.SLT_CP],0FFFFH ;; those slot whose font has been or
	MOV	[cs:DI+SLTS.SLT_AT],0 ;; to be loaded will be wiped out by
					;; a failing designate
DEN_FAIL_NEXT : 			;;
					;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JNE	DEN_FAIL_LOOP		;;
					;;
DEN_FAIL_RET :				;;
					;;
	POP	AX			;;
					;;
	MOV	word [BUF+BUF_DATA.FSELEN],0 ;;
					;;
					;;-------------------------------------
DEN_RET :				;;
	MOV	word [BUF+BUF_DATA.STATE],CPSW ;; end of designate cycle
					;;
DE_11:					;; WGR						 ;AN000;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;;
	MOV	word [RH+RHC.RHC_STA],AX ;;
					;;
	RET				;;
					;;
;DESIGNATE_END ENDP			;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;====	Generic IOCTL Invoke  ==========
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
INVOKE:        ;; ALSO JUMP FROM REFRESH
					;;
	MOV	AX,word [BUF+BUF_DATA.STATE] ;;
	CMP	AX,CPSW 		;;
	JE	IVK_PROCESS		;;
	CMP	AX,LOCKED		;; WGR						 ;AN000;
	JE	IVK_PROCESS		;; WGR						 ;AN000;
	JMP	IVK_CMDERR		;G;
IVK_PROCESS:				;;-------------------------
					;G;
	CALL	CHECK_PRINT_ACTIVE	;G; THIS WILL FIND OUT IF THE
	JNC	IVK_PROCESS_CONT	;G; PRINT.COM IS PRESENTLY ACTIVE!
	JMP	IVK_DEVERR		;G; If so, THEN DEVICE_ERROR
					;G;
IVK_PROCESS_CONT:			;G;
	push	ds			;;
	LDS	SI,dword [RH+GIH.GIH_GBA] ;;
	MOV	CX,word [GIOB+GB2S.GB2_LEN] ;;
	MOV	AX,STAT_CMDERR		;;
	CMP	CX,2			;;
	JE	IVK_GOODN		;;
	pop	ds			;;
	JMP	IVK_RET 		;;
IVK_GOODN:				;;
	MOV	DX,word [GIOB+GB2S.GB2_CP] ;; DX = the codepage to be invoked
	CMP	DX,0FFFFH		;;
	JNE	IVK_GOODCP		;;
	pop	ds			;;
	JMP	IVK_RET 		;;
IVK_GOODCP:				;;
					;; ************************************
					;; * INVOKE HIERIECHY : RAM, HARDWARE *
					;; ************************************
	pop	ds			;;
					;;
	MOV	DI,word [BUF+BUF_DATA.RAMSO] ;; check with the ram-slots  (DI)
	MOV	CX,word [BUF+BUF_DATA.RSLMX] ;; CX = size
	AND	CX,CX			;;
	JZ	HWCP_CHK		;;
					;;
RAM_CMP:				;; there are RAM-slots
	PUSH	CX			;; stack 1 = size
	PUSH	DI			;;
	POP	SI			;; start of the slot compared with (SI)
RAM_LP: 				;;
	MOV	AX,[cs:DI+SLTS.SLT_CP] ;;
	CMP	AX,DX			;;
	JE	IVK_RAMCP		;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JNZ	RAM_LP			;;
					;;
	POP	CX			;; stack -1
					;; code page not found in ram-slots
HWCP_CHK :				;;
	MOV	DI,word [BUF+BUF_DATA.HARDSO] ;; check with the HWCP-slots  (DI)
	MOV	CX,word [BUF+BUF_DATA.HSLMX] ;; CX = size
	AND	CX,CX			;;
	JNZ	HWCP_CMP		;;
	JMP	NO_INVOKE		;;
					;;
HWCP_CMP :				;;
	PUSH	CX			;; stack 1 = size of HWCP
	PUSH	DI			;;
	POP	SI			;; start of the slot compared with (SI)
HWCP_LP:				;;
	MOV	AX,[cs:DI+SLTS.SLT_CP] ;;
	CMP	AX,DX			;;
	JNE	HWCP_NEXT		;;
	JMP	IVK_HWCPCP		;;
					;;
HWCP_NEXT :				;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JNZ	HWCP_LP 		;;
	POP	CX			;; stack -1
					;;
	JMP	NO_INVOKE		;;
					;; **********************************
					;; **  RAM CODEPAGE TO BE INVOKED  **
					;; **********************************
					;; -- determine if any font to be
					;;    downloaded for the first time
					;;    select of the font.
					;; -- send selection control to invoke
					;;
					;; CX = inverse order of slot cp found
IVK_RAMCP :				;; code page found in RAM slots
					;; set up the pointer to first controls
					;; DI = where slot found
					;;
					;;-------------------------------------
					;; **** LOAD THE FONT FIRST  if ****
					;; -- there are font buffers created
					;; -- the slot's font has not been
					;;    loaded
	CMP	[cs:BX+BUF_DATA.STATE],LOCKED ;; WGR are we locked?				 ;AN000;
	JNE	IR_0			;; WGR no..continue				 ;AN000;
	MOV	[cs:BX+BUF_DATA.SAVED_CP],DX ;; WGR yes...save the code page 		 ;AN000;
	CMP	BX,BUF1         ;; WGR if this is lpt1..then			 ;AN000;
	JNE	NEXT_1			;; WGR						 ;AN000;
	LEA	SI,[BUF0] ;; WGR copy to PRN buffer.			 ;AN000;
	MOV	[cs:SI+BUF_DATA.SAVED_CP],DX ;; WGR						 ;AN000;
	JMP	ALL_RESET		;; WGR						 ;AN000;
NEXT_1: 				;; WGR						 ;AN000;
	CMP	BX,BUF0         ;; WGR if this is PRN..then..			 ;AN000;
	JNE	NEXT_2			;; WGR						 ;AN000;
	LEA	SI,[BUF1] ;; WGR copy to lpt1 buffer.			 ;AN000;
	MOV	[cs:SI+BUF_DATA.SAVED_CP],DX ;; WGR						 ;AN000;
NEXT_2: 				;; WGR						 ;AN000;
	JMP	ALL_RESET		;; WGR exit invoke with good status		 ;AN000;
IR_0:					;; WGR						 ;AN000;
;	 test	 cs:[di].SLT_AT, AT_ACT  ;AN001;If it is currently active, then do nothing
;	 jnz	 Next_2 		 ;AN001;
	CMP	word [BUF+BUF_DATA.RBUFMX],0 ;;
	JE	INVK_RAM_PHYSICAL	;;
					;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;;
	AND	AX,AT_RAM1		;; supports only ONE physical ram
	JNZ	INVK_RAM_PHYSICAL	;;
					;;
	OR	word [BUF+BUF_DATA.STATUS],LOADED ;; font has not been loaded
					;;
					;;
	POP	DX			;; stack -1
	PUSH	DX			;; stack  1  (size)
					;;
					;;
	PUSH	CX			;;
	PUSH	SI			;;
	PUSH	DI			;;
					;;
	SUB	DX,CX			;;
	MOV	AX,word [BUF+BUF_DATA.FTSTART] ;;
LOCATE_FONT :				;;
	AND	DX,DX			;;
	JZ	FONT_LOCATED		;;
	ADD	AX,word [BUF+BUF_DATA.FTSZPA] ;;
	DEC	DX			;;
	JMP	LOCATE_FONT		;;
					;;
FONT_LOCATED :				;;
					;; AX = FONT LOCATION (AX:0)
	SUB	DI,word [BUF+BUF_DATA.RAMSO] ;;
	SHR	DI,1			;; offset to the start of .FTDLEN
					;;
	add	DI,word [BUF+BUF_DATA.FTDLO] ;; length of font data
	mov	cx,word [cs:di]     ;;


;Before sending data, let's check the status of the printer
	call	Prt_Status_Check	;AN001;Check the printer status
	jz	Send_Ram_Data		;AN001;O.K.?
	pop	di			;AN001;Balance the stack
	pop	si			;AN001;
	pop	cx			;AN001;
	jmp	Ram_Prt_Status_err	;AN001;return with error.
Send_Ram_Data:
	MOV	SI,word [BUF+BUF_DATA.RNORMO] ;;
	MOV	[cs:SI+RHC.RHC_LEN],20 ;;
	MOV	[cs:SI+RHC.RHC_CMD],CMD_WRT ;;
	MOV	[cs:SI+RH3.RH3_CNT],CX ;;
	MOV	[cs:SI+RH3.RH3_DTAO],0 ;;
	MOV	[cs:SI+RH3.RH3_DTAS],AX ;;
					;;
	PUSH	BX			;;
					;;
	PUSH	BX			;;
	POP	DI			;; save BX in DI
	PUSH	CS			;;
	POP	ES			;;
	MOV	BX,SI			;; ES:BX = REQ_NORMn (CS:[SI])
					;;
	CALL	dword [cs:DI+BUF_DATA.LPT_STRAO]
					;;
	CALL	dword [cs:DI+BUF_DATA.LPT_INTRO]
					;;
	POP	BX			;;
					;;
	MOV	AX,[cs:SI+RHC.RHC_STA] ;;
					;;
	POP	DI			;;
	POP	SI			;;
	POP	CX			;;
					;;
	AND	AX,STAT_ERROR		;; any error returned by normal device?
	JZ	INVK_RAM_PHYSICAL	;;
					;;
Ram_Prt_Status_err:
	POP	CX			;; stack -1
	JMP	IVK_DEVERR		;;
					;;-------------------------------------
					;; **** SEND THE SELECTION CONTROL ****
					;;
INVK_RAM_PHYSICAL :			;;
					;;
	POP	DX			;; stack -1
	PUSH	DX			;; stack  1  (size)
					;;
	PUSH	DI			;; stack 2
	PUSH	SI			;; stack 3
	PUSH	ES			;; stack 4
					;;
					;;
					;; **** SUPPORT ONLY ONE PHYSICAL RAM
					;;
	MOV	DI,word [BUF+BUF_DATA.PDESCO] ;;
	MOV	DI,[cs:DI+PDS.SELR_O] ;; the RAM-select controls
	XOR	AX,AX			;;
	JMP	CTL_DEF 		;;
					;;
					;; *******************************
					;; ** INVOKE HARDWARE CODEPAGE	**
					;; *******************************
					;; -- check if it is CLASS 1 device,
					;;    If so then send slection control
					;;    from the font buffer at FTSTART
					;;
					;; CX=inverse order of slot cp found
IVK_HWCPCP:				;; code page found in HWCP slots
					;; set up the pointer to first controls
	CMP	[cs:BX+BUF_DATA.STATE],LOCKED ;; WGR are we locked?				 ;AN000;
	JNE	IR_1			;; WGR no..continue				 ;AN000;
	MOV	[cs:BX+BUF_DATA.SAVED_CP],DX ;; WGR yes...save the code page 		 ;AN000;
	CMP	BX,BUF1         ;; WGR if this is lpt1..then			 ;AN000;
	JNE	NEXT_3			;; WGR						 ;AN000;
	LEA	SI,[BUF0] ;; WGR copy to PRN buffer.			 ;AN000;
	MOV	[cs:SI+BUF_DATA.SAVED_CP],DX ;; WGR						 ;AN000;
	JMP	ALL_RESET		;; WGR						 ;AN000;
NEXT_3: 				;; WGR						 ;AN000;
	CMP	BX,BUF0         ;; WGR if this is PRN..then..			 ;AN000;
	JNE	NEXT_4			;; WGR						 ;AN000;
	LEA	SI,[BUF1] ;; WGR copy to lpt1 buffer.			 ;AN000;
	MOV	[cs:SI+BUF_DATA.SAVED_CP],DX ;; WGR						 ;AN000;
NEXT_4: 				;; WGR						 ;AN000;
	JMP	ALL_RESET		;; WGR exit invoke with good status		 ;AN000;
IR_1:					;; WGR						 ;AN000;
;	 test	 cs:[di].SLT_AT, AT_ACT  ;AN001;If it is currently active, then do nothing
;	 jnz	 Next_4 		 ;AN001;
	POP	DX			;; stack -1
	PUSH	DX			;; stack  1  (size)
					;;
	PUSH	DI			;; stack 2
	PUSH	SI			;; stack 3
	PUSH	ES			;; stack 4
					;;
	SUB	DX,CX			;; the slot's order in HWCP-slots(0-n)
					;;
	CMP	word [BUF+BUF_DATA.PCLASS],1 ;;
	JNE	SELECT_SLOT		;;
					;;
	MOV	AX,word [BUF+BUF_DATA.FTSTART] ;; ***** CLASS 1 CODEPAGE SELECT  ****
	AND	DX,DX			;;
	JZ	ADJUST_DI		;;
					;;
SELECTCP_LP :				;;
	ADD	AX,word [BUF+BUF_DATA.FTSZPA] ;;
					;;
	DEC	DX			;;
	JNZ	SELECTCP_LP		;;
					;;
ADJUST_DI :				;;
	mov	DI,AX			;;
	PUSH	CS			;;
	POP	AX			;;
	SUB	DI,AX			;;
	SHL	DI,1			;;
	SHL	DI,1			;;
	SHL	DI,1			;;
	SHL	DI,1			;;
	JMP	CTL_DEF 		;;
					;;
					;; ** SELECT HARDWARE PHYSICAL SLOT **
SELECT_SLOT :				;;
	MOV	DI,word [BUF+BUF_DATA.PDESCO] ;;
	MOV	DI,[cs:DI+PDS.SELH_O] ;; the HARDWARE-select controls
	XOR	AX,AX			;;
	JMP	RCTL_NXT		;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RCTL_NXT:				;; locate the right control sequence
	AND	DX,DX			;;
	JZ	CTL_DEF 		;;
	MOV	AL,[cs:DI]		;;
	ADD	DI,AX			;;
	DEC	DX			;;
	JMP	RCTL_NXT		;;
					;;
					;; ********************************
					;; ** SEND OUT SELECTION CONTROL **
					;; ********************************
					;;
					;; code page is to be invoked
CTL_DEF :				;; DI points to the control sequence
;Check the status of the printer before writing.
	call	Prt_Status_Check	;AN001;Check the printer status
	jz	Ctl_Def_Send		;AN001;O.K.?
	jmp	CTL_DEV_ERR		;AN001;Error.

Ctl_Def_Send:
	MOV	SI,word [BUF+BUF_DATA.RNORMO] ;;
	MOV	[cs:SI+RHC.RHC_LEN],20 ;;
	MOV	[cs:SI+RHC.RHC_CMD],CMD_WRT ;;
					;;
	XOR	CX,CX			;;
	MOV	CL,[cs:DI]		;;
					;;
CTL_NEXT_BYTE : 			;;
					;;
	CMP	word [BUF+BUF_DATA.PCLASS],1 ;;
	JE	CTL_CLASS1		;;
					;;
	MOV	[cs:SI+RH3.RH3_CNT],CX ;; send all at once
	MOV	CX,1			;; sent only once.
	JMP	CTL_COMMON		;;
					;;
CTL_CLASS1 :				;; sent byte by byte to overcome
	MOV	[cs:SI+RH3.RH3_CNT],1 ;; DOS timeout on kingman printer
CTL_COMMON :				;;
	INC	DI			;;
	MOV	[cs:SI+RH3.RH3_DTAO],DI ;;
	PUSH	CS			;;
	POP	AX			;;
	MOV	[cs:SI+RH3.RH3_DTAS],AX ;;
					;;
	PUSH	DI			;;
	PUSH	BX			;;
					;;
	PUSH	BX			;;
	POP	DI			;; save BX in DI
	PUSH	CS			;;
	POP	ES			;;
	MOV	BX,SI			;; ES:BX = REQ_NORMn (CS:[SI])
					;;
	CALL	dword [cs:DI+BUF_DATA.LPT_STRAO]
					;;
	CALL	dword [cs:DI+BUF_DATA.LPT_INTRO]
					;;
	POP	BX			;;
	POP	DI			;;
					;;
	MOV	AX,[cs:SI+RHC.RHC_STA] ;;
					;;
	AND	AX,STAT_ERROR		;; any error returned by normal device?
	JNZ	CTL_DEV_ERR		;;
	DEC	CX			;;
	JNZ	CTL_NEXT_BYTE		;;
					;;
	POP	ES			;; stack -4
	POP	SI			;; stack -3
	POP	DI			;; stack -2
	JMP	IVK_CP			;;
					;;
CTL_DEV_ERR :				;;
	POP	ES			;; stack -4
	POP	SI			;; stack -3
	POP	DI			;; stack -2
	POP	CX			;; stack -1
	JMP	IVK_DEVERR		;;
					;;
					;; **********************************
					;; ** ADJUST WHICH CODEPAGE TO BE  **
					;; ** ACTIVE			   **
					;; **********************************
					;;
					;; -- set the attribute bit of the
					;;    slot (SLT_AT) to active for
					;;    the code page just invoked.
					;; -- reset others to non-active.
					;;
					;;
IVK_CP: 				;; SI = start of the slots compared
					;; DI = where code page was found
	POP	CX			;; stack -1
	PUSH	SI			;; stack 1 = start of slots compared
	mov	AX,word [BUF+BUF_DATA.STATUS] ;;
	AND	AX,LOADED		;;
	MOV	AX,AT_ACT		;;
	JZ	NO_LOAD 		;;
	OR	AX,AT_RAM1		;; reset loaded to physical RAM #1,
					;; this is reset only when there is
					;; font loading in this round of invoke
NO_LOAD:				;; (for RAM codepages only)
	NOT	AX			;;
NXT_CP: 				;;
	AND	[cs:SI+SLTS.SLT_AT],AX ;; not active (and not loaded)
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
	INC	SI			;;
	DEC	CX			;;
	JNZ	NXT_CP			;;
	OR	[cs:DI+SLTS.SLT_AT],AT_ACT ;; the codepage found becomes active
	MOV	AX,word [BUF+BUF_DATA.STATUS] ;;
	AND	AX,LOADED		;;
	JZ	HWCP_RESET		;;
	OR	[cs:DI+SLTS.SLT_AT],AT_RAM1 ;; the font has just been loaded
	AND	word [BUF+BUF_DATA.STATUS],NOT LOADED ;;
					;;
HWCP_RESET :				;;
					;;
	POP	SI			;; stack -1 (slot : ATs adjusted )
	PUSH	SI			;; stack 1 = start of slots compared
					;;
	MOV	DI,word [BUF+BUF_DATA.HARDSO] ;;
	CMP	SI,DI			;;
	JE	RAM_RESET		;;
					;; HWCP's AT to be reset
	MOV	CX,word [BUF+BUF_DATA.HSLMX] ;;
	AND	CX,CX			;;
	JZ	RAM_RESET		;;
	MOV	AX,AT_ACT		;;
	NOT	AX			;;
RESET_HWCP :				;;
	AND	[cs:DI+SLTS.SLT_AT],AX ;; HWCP is not active
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JNZ	RESET_HWCP		;;
					;;
					;;
RAM_RESET:				;;
					;;
	POP	SI			;; stack -1 (slot : ATs adjusted )
	PUSH	SI			;; stack 1 = start of slots compared
					;;
	MOV	DI,word [BUF+BUF_DATA.RAMSO] ;;
	CMP	SI,DI			;;
	JE	ALL_RESET		;;
					;; HWCP's AT to be reset
	MOV	CX,word [BUF+BUF_DATA.RSLMX] ;;
	AND	CX,CX			;; HWCP's no.
	JZ	ALL_RESET		;;
	MOV	AX,AT_ACT		;;
	NOT	AX			;;
RESET_RAM :				;;
	AND	[cs:DI+SLTS.SLT_AT],AX ;; HWCP is not active
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JNZ	RESET_RAM		;;
					;;
ALL_RESET :				;;
	POP	SI			;; stack -1
					;;
	XOR	AX,AX			;;
	JMP	IVK_RET 		;;
					;;
NO_INVOKE :				;;
					;;
	MOV	AX,STAT_NOCPIV		;;
	JMP	IVK_RET 		;;
					;;
IVK_DEVERR :				;;
	MOV	AX,STAT_DEVERR		;;
	JMP	IVK_RET 		;G;
					;;
IVK_CMDERR :				;G;
	MOV	AX,STAT_CMDERR		;G;
					;;
IVK_RET :				;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;;
	MOV	word [RH+RHC.RHC_STA],AX ;;
					;;
	RET				;;
					;;
;INVOKE	ENDP				;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Prt_Status_Check:           ;AN001;
;Check the printer device status
;Out) if Zero flag set - Ok.
;     All registers saved.

	push	es				;AN001;
	push	si				;AN001;

	mov	si, word [BUF+BUF_DATA.RNORMO] ;AN001;
	mov	[cs:si+RHC.RHC_LEN], 13 ;AN001;
	mov	[cs:si+RHC.RHC_CMD], 10 ;AN001;device driver status check

	push	di				;AN001;
	push	bx				;AN001;

	push	bx				;AN001;
	pop	di				;AN001;
	push	cs				;AN001;
	pop	es				;AN001;ES:BX -> REQ_NORMn (was cs:si)
	mov	bx, si				;AN001;

	call	dword [cs:di+BUF_DATA.LPT_STRAO] ;AN001;Strategy
	call	dword [cs:di+BUF_DATA.LPT_INTRO] ;AN001;Intrrupt
	test	[cs:si+RHC.RHC_STA], STAT_ERROR ;AN001;
	pop	bx				;AN001;
	pop	di				;AN001;

	pop	si				;AN001;
	pop	es				;AN001;
	ret					;AN001;
;Prt_Status_Check	endp			;AN001;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;====	Generic IOCTL Query Invoked  =======
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
Q_INVOKED:        ;;
	push	ds			;;
					;;
	MOV	AX,word [BUF+BUF_DATA.STATE] ;; ???????????????
	CMP	AX,LOCKED		;; WGR						 ;AN000;
	JNE	QI_0			;; WGR						 ;AN000;
	MOV	AX,word [BUF+BUF_DATA.SAVED_CP] ;; WGR						 ;AN000;
	LDS	SI,dword [RH+GIH.GIH_GBA] ;; WGR						 ;AN000;
	CMP	AX,-1			;; WGR						 ;AN000;
	JE	QIV_NOACT		;; WGR						 ;AN000;
	JMP	QI_1			;; WGR						 ;AN000;
QI_0:					;; WGR						 ;AN000;
	CMP	AX,CPSW 		;; reject only in NORMAL !!!!
	JNE	QIV_CMDERR		;G;
					;;-------------------------
	LDS	SI,dword [RH+GIH.GIH_GBA] ;;
					;;
	MOV	DI,word [BUF+BUF_DATA.RAMSO] ;;
	MOV	CX,word [BUF+BUF_DATA.RSLMX] ;;
	AND	CX,CX			;;
	JZ	QIV_HARD		;;
					;;
QIV_RAMLP :				;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;; check the RAM slots
	AND	AX,AT_ACT		;;
	JNZ	QIV_FOUND		;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JNZ	QIV_RAMLP		;;
					;;
QIV_HARD :				;;
	MOV	DI,word [BUF+BUF_DATA.HARDSO] ;;
	MOV	CX,word [BUF+BUF_DATA.HSLMX] ;;
	AND	CX,CX			;;
	JZ	QIV_NOACT		;;
					;;
QIV_HARDLP :				;;
	MOV	AX,[cs:DI+SLTS.SLT_AT] ;; check the RAM slots
	AND	AX,AT_ACT		;;
	JNZ	QIV_FOUND		;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	DEC	CX			;;
	JNZ	QIV_HARDLP		;;
					;;
QIV_NOACT :				;;
					;;
	MOV	AX,STAT_NOCPIV		;;
	JMP	QIV_RET 		;;
					;;
					;;
QIV_FOUND :				;;
	MOV	AX,[cs:DI+SLTS.SLT_CP] ;;
QI_1:					;; WGR						 ;AN000;
	MOV	word [GIOB+GB2S.GB2_LEN],2 ;;
	MOV	word [GIOB+GB2S.GB2_CP],AX ;;
					;;
	XOR	AX,AX			;;
	JMP	QIV_RET 		;;
					;;
QIV_DEVERR :				;;
	MOV	AX,STAT_DEVERR		;;
	JMP	QIV_RET 		;G;
					;;
QIV_CMDERR :				;G;
	MOV	AX,STAT_CMDERR		;G;
					;;
QIV_RET :				;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;;
	MOV	word [RH+RHC.RHC_STA],AX ;;
					;;
	pop	ds			;;
					;;
	RET				;;
					;;
;Q_INVOKED ENDP				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;====	Generic IOCTL Query List  =======
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Q_LIST:        ;;
					;;
	push	ds			;;
					;;
	MOV	AX,word [BUF+BUF_DATA.STATE] ;;  ????????????????
	CMP	AX,CPSW 		;; reject only in NORMAL
	JE	QLS_CPSW		;;
	CMP	AX,LOCKED		;; WGR						 ;AN000;
	JE	QLS_CPSW		;; WGR						 ;AN000;
	JMP	QLS_CMDERR		;G;
QLS_CPSW :				;;-------------------------
	LDS	SI,dword [RH+GIH.GIH_GBA] ;;
	PUSH	SI			;; stack 1 -- GB3 (SI)
					;;
	MOV	DI,word [BUF+BUF_DATA.HARDSO] ;;
	MOV	CX,word [BUF+BUF_DATA.HARDMX] ;;
	MOV	DX,word [BUF+BUF_DATA.HSLMX] ;; DX = number of entries
	LEA	SI,[SI+GB3S.GB3_GBL] ;;
	MOV	word [GIOB+GBLS.GBL_LEN],CX ;;
					;;
QL_HARDLP:				;;
	AND	CX,CX			;;
	JZ	QL_PREPARE		;;
	MOV	AX,[cs:DI+SLTS.SLT_CP] ;;
	MOV	word [GIOB+GBLS.GBL_CP],AX ;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	SI			;;
	INC	SI			;;
	DEC	CX			;;
	JMP	QL_HARDLP		;;
					;;
QL_PREPARE:				;;
	MOV	CX,word [BUF+BUF_DATA.HSLMX] ;;
	SUB	CX,word [BUF+BUF_DATA.HARDMX] ;; less the no. of HWCP
	MOV	DX,word [BUF+BUF_DATA.RSLMX] ;;
	ADD	DX,CX			;; DX = total number of entries
	INC	SI			;;
	INC	SI			;;
	MOV	word [GIOB+GBLS.GBL_LEN],DX ;;
QL_CARTLP:				;;
	AND	CX,CX			;;
	JZ	QL_RAM_PREP		;;
	MOV	AX,[cs:DI+SLTS.SLT_CP] ;;
	MOV	word [GIOB+GBLS.GBL_CP],AX ;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	SI			;;
	INC	SI			;;
	DEC	CX			;;
	JMP	QL_CARTLP		;;
					;;
					;;
QL_RAM_PREP:				;;
	MOV	DI,word [BUF+BUF_DATA.RAMSO] ;;
	MOV	CX,word [BUF+BUF_DATA.RSLMX] ;;
					;;
QL_RAMLP :				;;
	AND	CX,CX			;;
	JZ	QL_DONE 		;;
	MOV	AX,[cs:DI+SLTS.SLT_CP] ;;
	MOV	word [GIOB+GBLS.GBL_CP],AX ;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	DI			;;
	INC	SI			;;
	INC	SI			;;
	DEC	CX			;;
	JMP	QL_RAMLP		;;
					;;
QL_DONE:				;;
	POP	SI			;; stack -1
	mov	dx,word [BUF+BUF_DATA.HSLMX] ;;
	add	DX,word [BUF+BUF_DATA.RSLMX] ;;
	INC	DX			;;
	INC	DX			;;
	MOV	CX,1			;;
	SHL	DX,CL			;;
	MOV	word [GIOB+GB3S.GB3_LEN],DX ;;
					;;
	XOR	AX,AX			;;
	CMP	DX,GB3_MINILEN		;; min. GBL length
	JA	QLS_RET 		;;
	MOV	AX,STAT_NOCP		;;
	JMP	QLS_RET 		;;
					;;
QLS_DEVERR :				;;
	MOV	AX,STAT_DEVERR		;;
	JMP	QLS_RET 		;G;
					;;
QLS_CMDERR :				;G;
	MOV	AX,STAT_CMDERR		;G;
					;;
QLS_RET :				;;
	LES	DI,dword [BUF+BUF_DATA.RH_PTRO] ;;
	MOV	word [RH+RHC.RHC_STA],AX ;;
					;;
	pop	ds			;;
	RET				;;
					;;
;Q_LIST	ENDP				;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	CHECK_PRINT_ACTIVE
;
;	THIS ROUTINE IS CALLED BEFORE THE INVOKE, DESIGNATE
;	COMMANDS ARE OPERATED ON.  THIS IS TO PREVENT CONFLICT
;	BETWEEN THE BACKGROUND PRINTING AND THE DOWNLOAD SEQUENCE.
;
;	INPUT:
;		CS:[BX].DEV_HDRO  OFFSET AND SEGMENT OF ACTIVE DEVICE
;		CS:[BX].DEV_HDRS
;
;	WARNING:  IF ANOTHER DEVICE DRIVER IS TO TAKE THE LPTx, THEN
;		  THIS WILL not FIND OUT THAT THE PRINTER.SYS IS ACTIVE.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHECK_PRINT_ACTIVE:      ;G;
	PUSH	AX			;G; SAVE THE REGISTERS............
	PUSH	SI			;G;
	PUSH	DI			;G;
	PUSH	DS			;G;
	PUSH	ES			;G;
					;G;
	MOV	DI,word [BUF+BUF_DATA.DEV_HDRS] ;G; SETUP ES: = ACTIVE DEVICE SEGMENT
	MOV	ES,DI			;G;		  &
	MOV	DI,word [BUF+BUF_DATA.DEV_HDRO] ;G; SETUP DI: = ACTIVE DEVICE OFFSET
					;G;
	MOV	AX,0106H		;G; PRINT (GET LIST DEVICE)
	CLC				;G;
	JNC	CPA_5			;G; CY=0 IF NOT LOADED/NOT ACTIVE
					;G;
	CMP	SI,DI			;G; ES:DI POINTS TO THE ACTIVE DEVICE
	JNE	CPA_5			;G;
	MOV	SI,DS			;G;
	MOV	DI,ES			;G;
	CMP	SI,DI			;G;
	JNE	CPA_5			;G;
	STC				;G; OTHERWISE, THIS DEVICE IS PRESENTLY
	JMP	CPA_6			;G; UNDER PRINT!!!  PREVENT DATASTREAM
					;G; CONFLICT IN THIS CASE.
					;G;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;G; PRINT.COM IS ASLEEP OR IS NOT
					;G; PRESENTLY LOADED.  THE PRINTER.SYS
CPA_5:	CLC				;G; CAN CONTINUE IT PROCESS!
CPA_6:	POP	ES			;G; RESTORE REGISTERS.....
	POP	DS			;G;
	POP	DI			;G;
	POP	SI			;G;
	POP	AX			;G;
	RET				;G;
;CHECK_PRINT_ACTIVE	ENDP		;G;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;CSEG	ENDS
;	END
