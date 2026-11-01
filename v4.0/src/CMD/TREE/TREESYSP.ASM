	PAGE	90,132			;AN000;A2
	TITLE	TREESYSP.SAL - INCLUDES THE COMMON SYSTEM PARSER ;AN000;
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: TREESYSP.SAL
;
; DESCRIPTIVE NAME: Include the DOS system PARSER
;
;FUNCTION: The common code of the DOS command line PARSER is optimized by
;	   the setting of certain switches that cause the conditional
;	   assembly of only the required portions of the common PARSER.
;	   The segment registers are ASSUMED according to the type .COM.
;	   The Common PARSER is then INCLUDEd.
;
; ENTRY POINT: SYSPARSE, near
;
; INPUT:
;	ES - has seg id of the SEGMENT
;	     that contains the input control blocks,
;	     defined below.
;
;	DI - offset into ES of the PARMS INPUT BLOCK
;
;	DS - has seg id of the SEGMENT
;	     that contains the DOS input COMMAND
;	     string, which is originally presented at 81h
;	     in the PSP.
;
;	SI - offset into DS of the text of the DOS input COMMAND string
;	     as originally presented at 81H in the PSP.
;
;	DX - zero
;
;	CX - ordinal value, intially zero, updated on each subsequent call
;	     to the value returned in CX on the previous call.
;
;	CS - points to the segment containing the
;	     INCLUDE PARSE.ASM statement
;
;	DS - also points to the segment containing the INCLUDE
;	     PARSE.ASM statement.
;
; EXIT-NORMAL:	Output registers:
;	 AX - return code:
;	    RC_No_Error     equ     0	 ; No error
;	    RC_EOL	    equ     -1	 ; End of command line
;
;	 DX - Offset into ES of the selected RESULT BLOCK.
;	 BL - terminated delimiter code
;	 CX - new operand ordinal
;	 SI - set past scanned operand
;
; EXIT-ERROR: Output registers:
;	 AX - return code:
;	    RC_Too_Many     equ     1	 ; Too many operands
;	    RC_Op_Missing   equ     2	 ; Required operand missing
;	    RC_Not_In_SW    equ     3	 ; Not in switch list provided
;	    RC_Not_In_Key   equ     4	 ; Not in keyword list provided
;	    RC_Out_Of_Range equ     6	 ; Out of range specified
;	    RC_Not_In_Val   equ     7	 ; Not in value list provided
;	    RC_Not_In_Str   equ     8	 ; Not in string list provided
;	    RC_Syntax	    equ     9	 ; Syntax error
;
; INCLUDED FILES: PARSE.ASM - System Parser
;		  PSDATA.INC - Equates and workareas used by PARSE.ASM
;		  PATHMAC.INC - PATHGEN MACRO
;
; INTERNAL REFERENCES:
;    ROUTINES: SYSPARSE:near (INCLUDEd in PARSE.ASM)
;
;    DATA AREAS: none
;
; EXTERNAL REFERENCES:
;    ROUTINES: none
;
;    DATA AREAS: control blocks pointed to by input registers.
;
; NOTES:
;	 This module should be processed with the SALUT preprocessor
;	 with the re-alignment not requested, as:
;
;		SALUT TREESYSP,NUL,;
;
;	 To assemble these modules, the alphabetical or sequential
;	 ordering of segments may be used.
;
;	 For LINK instructions, refer to the PROLOG of the main module,
;	 TREE.SAL.
;
;****************** END OF SPECIFICATIONS *****************************
;	IF1				;AN000;
;	    %OUT    COMPONENT=TREE, MODULE=TREESYSP.SAL... ;AN000;
;	ENDIF				;AN000;

	include 'PATHMAC.INC';AN013;

;CSEG	SEGMENT PARA PUBLIC 'CODE'	;AN000;
;	ASSUME	CS:CSEG 		;AN000;ESTABLISHED BY CALLER
;	ASSUME	SS:CSEG 		;AN000;ESTABLISHED BY CALLER
;	ASSUME	DS:CSEG 		;AN000;ESTABLISHED BY CALLER
;	ASSUME	ES:CSEG 		;AN000;ESTABLISHED BY CALLER

;	PUBLIC	SYSPARSE		;AN000;SUBROUTINE ENTRY POINT

DateSW	equ	0			;AN000;SUPPRESS DATE CHECKING
TimeSW	equ	0			;AN000;SUPPRESS TIME CHECKING
CmpxSW	equ	0			;AN000;SUPPRESS CHECKING COMPLEX LIST
NumSW	equ	0			;AN000;SUPPRESS CHECKING NUMERIC VALUE
KeySW	equ	0			;AN000;SUPPRESS KEYWORD SUPPORT
Val1SW	equ	0			;AN000;SUPPRESS SUPPORT OF VALUE DEFINITION 1
Val2SW	equ	0			;AN000;SUPPRESS SUPPORT OF VALUE DEFINITION 2
Val3SW	equ	0			;AN000;SUPPRESS SUPPORT OF VALUE DEFINITION 3
DrvSW	equ	0			;AN000;SUPPRESS SUPPORT OF DRIVE ONLY FORMAT
QusSW	equ	0			;AN000;SUPPRESS SUPPORT OF QUOTED STRING FORMAT
BaseSW	equ	1			;AN012;SPECIFY, PSDATA POINTED TO BY "DS"
IncSW	equ	0			;AN013;PSDATA.INC IS ALREADY INCLUDED
	include 'PSDATA.INC'
	PATHLABL TREESYSP		;AN013;
;	INCLUDE PARSE.ASM		 ;GENERATED CODE SUPPRESSED FROM LISTING
.XLIST					;AN000;
.XCREF					;AN000;
	include 'PARSE.ASM';AN000;
.LIST					;AN000;
.CREF					;AN000;
	PATHLABL TREESYSP		;AN013;
;CSEG	ENDS				;AN000;
;	END				;AN000;
