	page	60,132
;			SALUT$ (4,25,30,41)

			include 'PRIDEFS.INC'

BREAK			<TRANSIENT Messages>

;
;	DOS PRINT
;
;	Transient Service code
;
;	02/13/84	MAU	Fixed bug with BadCanMes
;
;	05/20/87	FJG	Change format to new Message Service
;				Routines/Parse code
;


macro addr sym,name
{
;			public name
			match , name \{

			    dw	 sym
			else

name			    dw	 sym
			\}
}


if SEGSEL = S_CODE

;			PUBLIC SYSGETMSG, SYSLOADMSG, SYSDISPMSG

;			ASSUME CS:DG,DS:nothing,ES:nothing,SS:Stack

; include msgserv.asm

			.xlist
			.xcref
			MSG_SERVICES <MSGDATA>
			MSG_SERVICES <NEARmsg,LOADmsg,GETmsg,DISPLAYmsg,INPUTmsg,CHARmsg>
			.cref
			.list

; include message class 1, 2, A, B, C, and D

			.xlist
			.xcref
			MSG_SERVICES <NEARmsg,PRINT.CL1,PRINT.CL2>
			MSG_SERVICES <NEARmsg,PRINT.CLA,PRINT.CLB,PRINT.CLC,PRINT.CLD>
			.cref
			.list
;  SALUT$ (4,4,9,41)


;			SALUT$ (4,25,30,41)
;false			=    0

DateSW			equ  FALSE
TimeSW			equ  FALSE
CmpxSW			equ  FALSE
KeySW			equ  FALSE
QusSW			equ  FALSE
Val2SW			equ  FALSE
Val3SW			equ  FALSE

;  SALUT$ (4,4,9,41)

;   PUBLIC SYSPARSE

					; include parse.asm

					;xlist
					;xcref
   include 'PARSE.ASM'
					;cref
					;list

end if

;   end
