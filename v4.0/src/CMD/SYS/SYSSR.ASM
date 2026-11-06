	include 'SYSHDR.INC'

; include SYSMSG.INC

.xlist
.xcref

	include 'SYSMSG.INC' ;				       ;AN000;

.cref
.list

	MSG_UTILNAME <SYS>		;				       ;AN000;

if SEGSEL = S_CODE

;ASSUME	CS:CODE,DS:nothing,ES:nothing

;	PUBLIC	SYSDISPMSG, SYSLOADMSG, SYSPARSE
;	PUBLIC	Data_Space

;;dcl	MSG_SERVICES <MSGDATA>		;				      ;AN000;

;  MSG_SERVICES <SYS.CL1,SYS.CL2,SYS.CLA,SYS.CLB,SYS.CLC,SYS.CLD>		;AN000;

.xlist
.xcref

	MSG_SERVICES <SYS.CL1,SYS.CL2,SYS.CLA,SYS.CLB,SYS.CLC,SYS.CLD> ;       ;AN000;

.cref
.list

;  MSG_SERVICES <LOADmsg,DISPLAYmsg,INPUTmsg,CHARmsg,NOVERCHECKmsg>

.xlist
.xcref

	MSG_SERVICES <LOADmsg,DISPLAYmsg,INPUTmsg,CHARmsg,NOVERCHECKmsg> ;		     ;AN000;

.cref
.list


;false	=	0			;				       ;AN000;

DateSW	equ	FALSE			;				       ;AN000;
TimeSW	equ	FALSE			;				       ;AN000;
CmpxSW	equ	FALSE			;				       ;AN000;
KeySW	equ	FALSE			;				       ;AN000;
QusSW	equ	FALSE			;				       ;AN000;
Val1SW	equ	FALSE			;				       ;AN000;
Val2SW	equ	FALSE			;				       ;AN000;
Val3SW	equ	FALSE			;				       ;AN000;
SwSW	equ	FALSE			;				       ;AN000;
NumSW	equ	FALSE			;				       ;AN000;
CAPSW	equ	FALSE			; Perform CAPS if specified	       ;AN000;


;ASSUME	CS:CODE,DS:CODE,ES:nothing

; include parse.asm

;xlist
;xcref

include 'PARSE.ASM' ;				       ;AN000;

.cref
.list

label Data_Space byte   ;				       ;AN000;



end if

include 'MSGDCL.INC'

;	End

