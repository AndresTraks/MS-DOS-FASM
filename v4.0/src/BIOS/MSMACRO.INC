;
; This file contains three macros used in debugging the system.  If the
; variable "itest" (in msbio.asm) is nonzero code is included in the
; modules to print debugging messages.	The level of debugging is controlled
; by the value of the variable fTestBits in msbio.asm.	Specific bits in
; the variable determine which messages to print.  The equ's below tell
; which bits control which funcitons.  For example the fifth bit
; cooresponds to disk activity (see fTestDisk equ below).
;
;   The macros in the file are:
;
;	message    Prints an ascii string on the screen.
;		   Example usage:
;
;		      message fTestDisk, <"Start Disk Write", CR, LF>
;		      message fTestINIT, <"Begin BDS initialization">
;
;
;	MNUM	   Print the value in a register or memory location on
;		   the screen. Value is displayed in hex.
;		   Usage:
;		      MNUM  bitpattern, valueLocation
;
;		   valueLocation is typically a regester:
;
;		      mnum  fTestCom, AX
;		      mnum  fTestDisk, DX
;
;		   ValueLocation can also be a memory location:
;
;		      mnum  fTestINIT, Final_Dos_Location
;
;		   If no valueLocation is given the macro defaults to
;		   the BX register.
;
;	ZWAIT	    Stops the program until any key is pressed.
;
;
;	The three macros preserve all register values.	If "test" is zero
;	defined during assembly then the  marco produce no code.
;
; MASM had two sets of these: the real ones under IF iTEST and a set of empty
; ones under the ELSE.  fasm's preprocessor makes a macro as it reads the
; line, whether or not the IF around it would have held, so there can only be
; one set -- and the IF goes inside the body instead, which comes to the same
; thing.  iTEST is 0 in the release, so none of this is assembled; it is
; converted all the same, and is the one part of the BIOS here that has never
; been through the assembler.
;

;	IF	iTEST							  ;3.30
;	   IFNDEF MSGOUT						  ;3.30
;		EXTRN	MSGOUT:NEAR,MSGNUM:NEAR 			  ;3.30
;	   ENDIF							  ;3.30
;	   IFNDEF NUMBUF						  ;3.30
;	    EXTRN   NUMBUF:BYTE,DIGITS:BYTE,FTESTBITS:WORD		  ;3.30
;	   ENDIF							  ;3.30
;	   IFNDEF DUMPBYTES						  ;3.30
;		EXTRN	DUMPBYTES:NEAR,OUTCHAR:NEAR,HEX_TO_ASCII:NEAR	  ;3.30
;	   ENDIF							  ;3.30



fTestALL    equ     1111111111111111b	; watch everything
fTestHARD   equ     0000000000000001b	; watch hard disk initialization
fTest96     equ     0000000000000010b	; watch 96 tpi activity
FTEST13     EQU     0000000000000100B	; WATCH INT 13 ACTIVITY 	  ;3.30
FTESTCOM    EQU     0000000000001000B	; WATCH PACKET ACTIVITY 	  ;3.30
FTESTINIT   EQU     0000000000010000B	; WATCH INITIALIZATION MESSAGES   ;3.30
FTESTDISK   EQU     0000000000100000B	; WATCH DISK DEVICE DRIVER CALLS  ;3.30
FTESTCON    EQU     0000000001000000B	; WATCH SYSTEM WAIT ACTIVITY IN CO;3.30 NSOLE
FtestClock  equ     0000000010000000b	; wathc clock device  5/2/86  ;3.30


;
; message macro -- see above for description
;

macro MESSAGE	Bits,msg
{
    if iTEST
	local	a,b
	jmp	SHORT b
a:	db	msg,0
b:	push	SI
	push	AX
	mov	AX,Bits
	mov	SI,a
	call	MSGOUT
	pop	AX
	pop	SI
    end if
}


;
; mnum macro -- see above for description
;

; The modules call these in whatever case they please -- MESSAGE, Message
; and message; MNUM and mnum -- all of them one name to MASM.  fasm tells
; them apart, so the other spellings stand as names for the same macro
; rather than being rewritten at a hundred and fifty call sites.
macro Message Bits,msg
{
	MESSAGE Bits,msg
}
macro message Bits,msg
{
	MESSAGE Bits,msg
}
macro MNUM	Bits,num
{
	MNum	Bits,num
}
macro mnum	Bits,num
{
	MNum	Bits,num
}

macro MNum	Bits,num
{
    if iTEST
	push	AX
	match , num \{
	mov	AX,Bits
	call	MSGNUM \}
	match any, num \{
	push	BX
	mov	BX,num
	mov	AX,Bits
	call	MSGNUM
	pop	BX \}
	pop	AX
    end if
}


;
; zwait macro -- see above for description
;

macro ZWAIT
{
    if iTEST
	MESSAGE fTestALL,<"? ">
	CALL	ZWAITrtn
    end if
}

if iTEST
ZWAITrtn:
	pushf				; save the flags
	push	AX			; preserve AX
	xor	AH, AH			; set command to get character ;3.30*
	int	16h			; call rom keyboard routine    ;3.30*
	pop	AX			; restore AX
	popf				; restore the flags
	ret
end if

;Dump_byte dumps the memory contents in hex. 				  ;3.30
;DUMPOFFLABEL should be a label or a variable defined in DUMPSEG.	  ;3.30
macro DUMP_BYTE 	DUMPSEG, DUMPOFFLABEL, BYTELENGTH		  ;3.30
{
    if iTEST
	push	es							  ;3.30
	PUSH	DS							  ;3.30
	PUSH	SI							  ;3.30
	PUSH	CX							  ;3.30
									  ;3.30
	MOV	CX, DUMPSEG						  ;3.30
	MOV	DS, CX							  ;3.30
	MOV	SI, DUMPOFFLABEL					  ;3.30
	MOV	CX, BYTELENGTH						  ;3.30
	call	DUMPBYTES						  ;3.30
									  ;3.30
	POP	CX							  ;3.30
	POP	SI							  ;3.30
	POP	DS							  ;3.30
	pop	es							  ;3.30
    end if
}
									  ;3.30
;Dump_Byte_Reg dumps the memory contents in hex. -  4/9/86		  ;3.30
;DUMPOFFREG should be a register contains the offset value in DUMPSEG.	  ;3.30
macro DUMP_BYTE_REG	DUMPSEG, DUMPOFFREG, BYTELENGTH 		  ;3.30
{
    if iTEST
	push	es							  ;3.30
	PUSH	DS							  ;3.30
	PUSH	SI							  ;3.30
	PUSH	CX							  ;3.30
									  ;3.30
	MOV	CX, DUMPSEG						  ;3.30
	MOV	DS, CX							  ;3.30
	MOV	SI, DUMPOFFREG						  ;3.30
	MOV	CX, BYTELENGTH						  ;3.30
	call	DUMPBYTES						  ;3.30
									  ;3.30
	POP	CX							  ;3.30
	POP	SI							  ;3.30
	POP	DS							  ;3.30
	pop	es							  ;3.30
    end if
}

; The PUBLIC is gone, there being one binary and nothing to export to, so
; what is left of these two is the label that marks where a message block
; starts and ends -- which the path tables are built from, and only when the
; module asked for them by defining PATHGEN.
macro PATHSTART INDEX,ABBR						  ;3.30
{
    if defined PATHGEN							  ;3.30
	ABBR#INDEX#S:							  ;3.30
    end if								  ;3.30
}									  ;3.30
									  ;3.30
macro PATHEND	INDEX,ABBR						  ;3.30
{
    if defined PATHGEN							  ;3.30
	ABBR#INDEX#E:							  ;3.30
    end if								  ;3.30
}
