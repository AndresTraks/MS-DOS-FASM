	PAGE	90,132			;AN000;A2
	TITLE	DCOMPP.SAL - DISKCOMP SYSTEM COMMAND LINE PARSER
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: DCOMPP.SAL
;
; DESCRIPTIVE NAME: Include the DOS system PARSER in the SEGMENT
;		    configuration expected by the modules of DISKCOMP.
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
;		SALUT DCOMPP,NUL,;
;
;	 To assemble these modules, the alphabetical or sequential
;	 ordering of segments may be used.
;
;	 For LINK instructions, refer to the PROLOG of the main module,
;	 DISKCOMP.SAL.
;
;****************** END OF SPECIFICATIONS *****************************
;	IF1				;AN000;
;	    %OUT    COMPONENT=DISKCOMP, MODULE=DCOMPP.SAL... ;AN000;
;	ENDIF				;AN000;
; =  =	=  =  =  =  =  =  =  =	=  =
	include 'PATHMAC.INC' ;AN013;
;CSEG	SEGMENT PARA PUBLIC 'CODE'	;AN000;
;	ASSUME	CS:CSEG,DS:CSEG,ES:CSEG,SS:CSEG ;AN000;

;	PUBLIC	SYSPARSE		;AN000;SUBROUTINE ENTRY POINT

IncSW	EQU	0			;AC013;DO NOT INCLUDE PSDATA.INC
FarSW	EQU	0			;AN000;CALL THE PARSER BY NEAR CALL
DateSW	EQU	0			;AN000;SUPPRESS DATE CHECKING
TimeSW	EQU	0			;AN000;SUPPRESS TIME CHECKING
FileSW	EQU	0			;AN000;SUPPRESS CHECK FILE SPECIFICATION
CAPSW	EQU	0			;AN000;SUPPRESS FILE TABLE CAPS
CmpxSW	EQU	0			;AN000;SUPPRESS CHECKING COMPLEX LIST
DrvSW	EQU	1			;AN000;DO SUPPORT DRIVE ONLY FORMAT
QusSW	EQU	0			;AN000;SUPPRESS SUPPORT OF QUOTED STRING FORMAT
NumSW	EQU	0			;AN000;SUPPRESS CHECKING NUMERIC VALUE
KeySW	EQU	0			;AN000;SUPPRESS KEYWORD SUPPORT
SwSW	EQU	1			;AN000;DO SUPPORT SWITCHES
Val1SW	EQU	0			;AN000;SUPPRESS SUPPORT OF VALUE DEFINITION 1
Val2SW	EQU	0			;AN000;SUPPRESS SUPPORT OF VALUE DEFINITION 2
Val3SW	EQU	0			;AN000;SUPPRESS SUPPORT OF VALUE DEFINITION 3
BaseSW	EQU	1			;AN012;SPECIFY, PSDATA POINTED TO BY "DS"
	include 'PSDATA.INC' ;AN013;PARSER DATA AREA
	PATHLABL DCOMPP 		;AN013;
;.XLIST 				 ;AN000;
;.XCREF 				 ;AN000;
	include 'PARSE.ASM' ;AN000;
.LIST					;AN000;
.CREF					;AN000;
	PATHLABL DCOMPP 		;AN013;
;CSEG	ENDS				;AN000;
;	END				;AN000;
