	PAGE	,132			;
	TITLE	NLSPARM.SAL - NLSFUNC  SYSTEM COMMAND LINE PARSER
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: NLSPARM.SAL
;
; DESCRIPTIVE NAME: Include the DOS system PARSER in the SEGMENT
;		    configuration expected by the modules of NLSFUNC.
;
;FUNCTION: The common code of the DOS command line PARSER is optimized by
;	   the setting of certain switches that cause the conditional
;	   assembly of only the required portions of the common PARSER.
;	   The segment registers are ASSUMED according to the type .EXE.
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
;	     INCLUDE PARSE.SAL statement
;
;	DS - also points to the segment containing the INCLUDE
;	     PARSE.SAL statement.
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
;    ROUTINES: SYSPARSE:near (INCLUDEd in PARSE.SAL)
;
;    DATA AREAS: none
;
; EXTERNAL REFERENCES:
;    ROUTINES: none
;
;    DATA AREAS: control blocks pointed to by input registers.
;
; NOTES:
;	 This module should be processed with the ASMUT preprocessor
;	 with the re-alignment not requested, as:
;
;		SALUT  NLSPARM,NUL;
;
;	 To assemble these modules, the sequential
;	 ordering of segments may be used.
;
;	 For LINK instructions, refer to the PROLOG of the main module,
;	 NLSFUNC.SAL
;
; REVISION HISTORY: A000 Version 4.00: add PARSER, System Message Handler,
;
; COPYRIGHT: "The DOS NLSFUNC Utility"
;	     "Version 4.00 (C)Copyright 1988 Microsoft
;	     "Licensed Material - Program Property of Microsoft "
;
;****************** END OF SPECIFICATIONS *****************************
;	IF1
;	    %OUT    COMPONENT=NLSFUNC, MODULE=NLSPARM.SAL...
;	ENDIF
; =  =	=  =  =  =  =  =  =  =	=  =
	HEADER	<MACRO DEFINITION>
; =  =	=  =  =  =  =  =  =  =	=  =

macro HEADER [TEXT]
{
.XLIST
	SUBTTL	TEXT
.LIST
	PAGE
}

; =  =	=  =  =  =  =  =  =  =	=  =
	HEADER	<SYSPARSE - SYSTEM COMMAND LINE PARSER>
if SEGSEL = S_NLS_DATA

  CAPSW   EQU	  1			  ;SUPPORT FILENAME TBL CAPS
 FarSW	 EQU	 0			 ;PARSER CALL FAR
 FileSW  EQU	 1			 ;CHECK FOR FILESPEC
SwSW	EQU	0			;SUPPRESS SUPPORT FOR SWITCHES
DateSW	EQU	0			;SUPPRESS DATE CHECKING
TimeSW	EQU	0			;SUPPRESS TIME CHECKING
CmpxSW	EQU	0			;SUPPRESS CHECKING COMPLEX LIST
NumSW	EQU	0			;SUPPRESS CHECKING NUMERIC VALUE
KeySW	EQU	0			;SUPPRESS KEYWORD SUPPORT
Val1SW	EQU	0			;SUPPRESS SUPPORT OF VALUE DEFINITION 1
Val2SW	EQU	0			;SUPPRESS SUPPORT OF VALUE DEFINITION 2
Val3SW	EQU	0			;SUPPRESS SUPPORT OF VALUE DEFINITION 3
DrvSW	EQU	0			;SUPPORT OF DRIVE ONLY FORMAT
QusSW	EQU	0			;SUPPRESS SUPPORT OF QUOTED STRING FORMAT

;	 INCLUDE PSDATA.INC		 ;PARSE WORK AREA & EQUATES

end if

if SEGSEL = S_NLS_INIT_CODE

;	 ASSUME  CS:NLS_INIT_CODE,DS:NLS_DATA
;	 ASSUME  CS:NLS_INIT_CODE,DS:nothing ; tsuneo

;	 mov	 ax,NLS_DATA
;	 mov	 ds,ax

;IncSW	 equ	 0




	include 'PARSE.ASM'
;       PUBLIC  SYSPARSE

end if
;NLS_DATA ENDS
;	END
