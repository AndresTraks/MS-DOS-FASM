;	SCCSID = @(#)segcheck.asm	1.2 85/07/24
TITLE   SegCheck - internal consistency check
NAME    SegCheck

;.xlist
INCLUDE '../INC/DOSSYM.INC'
INCLUDE '../INC/DEVSYM.INC'

ShareF  = FALSE

if NOT SHAREF
INCLUDE '../INC/DOSSEG.ASM'
end if
;.list

AsmVars <NET, DEBUG>

DEBUG   = FALSE

if NOT SHAREF
if SEGSEL = S_CODE
;ASSUME  CS:DOSGroup
else
if SEGSEL = S_SHARE
;ASSUME  CS:SHARE
end if

DEBUG   = FALSE

BREAK   <SegCheck - validate segments in MSDOS>

Off Macro   reg,var
if SHAREF
	mov     reg,var
else
	mov     reg,var
end if
endm

zfmt    MACRO   fmts,args
local   a,b
	PUSHF
	PUSH    AX
	PUSH    BP
	MOV     BP,SP
if (not sharef) and (not redirector)
if SEGSEL = S_TABLE
a       db      fmts,0
end if
	MOV     AX,a
else
	jmp     short b
a       db      fmts,0
if sharef
b:      mov     ax,share:a
else
b:      mov     ax,netwrk:a
end if
end if
	PUSH    AX
cargs = 2
IRP item,<args>
IFIDN   <AX>,<item>
	MOV     AX,[BP+2]
else
	MOV     AX,item
end if
	PUSH    AX
cargs = cargs + 2
ENDM
	invoke  PFMT
	ADD     SP,Cargs
	POP     BP
	POP     AX
	POPF
ENDM

segFrame    Struc
segbp       DW  ?
segip       DW  ?
segmes      dw  ?
segtemp     DW  ?
;segFrame    ENDS
;
;   SegCheck - assure that segments are correctly set up
;
;   Inputs:     top of stack points to:
;               2-byte jump
;               byte flags 04h is ES 02h is DS 01 is CS/SS
;               offset asciz message
;
;   Outputs:    message to screen (via INT 29h)
;   Nothing modified (flags too)

Procedure   SegCheck,NEAR
;	ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
	SaveReg <BP>
	MOV     BP,SP                   ; set up addressing
	PUSHF
	SaveReg <AX,BX,CX,DX>
	MOV     AL,byte [BP].[segtemp]; get flags
	MOV     CX,SS
	TEST    AL,1                    ; shall we use CS or SS?
	JZ      SegUseSS                ; use SS
	MOV     CX,CS                   ; use CS instead
SegUseSS:
	TEST    AL,2                    ; do we check DS?
	JZ      SegTestES               ; no, go check ES
	MOV     DX,DS
	CMP     CX,DX
	JZ      SegTestES               ; DS is valid, go check ES
	MOV     AX,[BP].[segmes]
	zfmt    <"Assumed DS invalid s$\n">,<AX>
SegTestES:
	TEST    AL,4                    ; do we check ES?
	JZ      SegTestDone             ; no, all done
	MOV     DX,ES
	CMP     CX,DX
	JZ      SegTestDone             ; ES is valid, all done
	MOV     AX,[BP].[segmes]
	zfmt    <"Assumed ES invalid s$\n">,<AX>
SegTestDone:
	RestoreReg  <DX,CX,BX,AX>
	POPF
	RestoreReg  <BP>
	ret     4                       ; release message, temp
EndProc SegCheck


if NOT SHAREF
I_need  DPBHead,DWORD
I_need  BuffHead,DWORD
I_need  sftFCB,DWORD
I_need  AuxStack,BYTE
I_need  IOStack,BYTE
I_need  renbuf,byte
I_need  CurrentPDB,WORD
I_need  User_In_AX,WORD

;extrn   ECritDisk:NEAR

CritNOP:
	RET

AstFrame    STRUC
Astbp       dw  ?
Astip       dw  ?
Astmes      dw  ?
Astarg      dd  ?
;AstFrame    ENDS

;Public SGCHK001S,SGCHK001E
SGCHK001S:
DPBMes  DB  "DPB assertion failed: ",0
BUFMes  DB  "BUF assertion failed: ",0
SFTMes  DB  "SFT assertion failed: ",0
BlankSp DB  " ",0
Colon   DB  ":",0

Msg     DW  ?

SGCHK001E:

if SEGSEL = S_TABLE
;    Extrn SectPDB:WORD, SectRef:WORD
end if

;   DPBCheck - validate a supposed DPB pointer
;   Inputs:     Pushed arguments
;   Outputs:    Message to screen
;   Registers modified: none

Procedure   DPBCheck,NEAR
	MOV     [Msg],DPBMes
	SaveReg <BP>
	MOV     BP,SP
	PUSHF
	SaveReg <AX,BX,DS,SI,ES,DI>
	LES     DI,[DPBHead]
	LDS     SI,[BP].[Astarg]
DPBLoop:CMP     DI,-1
	JZ      DPBNotFound
	invoke  PointComp
	JZ      DPBRet
	LES     DI,[es:DI+dpb_next_dpb]
	JMP     DPBLoop
DPBNotFound:
	MOV     AX,[BP].[Astmes]
	zfmt    <"s$x$:x$ s$\n">,<msg,ds,si,AX>
	CLI
a:      JMP     [a]                       ; slam the door.
DPBRet: RestoreReg  <DI,ES,SI,DS,BX,AX> ;   Done:
	POPF
	RestoreReg  <BP>
	RET     6
EndProc DPBCheck

;   SFTCheck - validate a supposed SFT pointer
;   Inputs:     Pushed arguments
;   Outputs:    Message to screen
;   Registers modified: none

Procedure   SFTCheck,NEAR
	MOV     [Msg],SFTMes
	SaveReg <BP>
	MOV     BP,SP
	PUSHF
	SaveReg <AX,BX,DS,SI,ES,DI>
	LDS     SI,[BP].[Astarg]
	XOR     BX,BX                   ;   i = 0;
SFTLoop:
	SaveReg <BX>
	invoke  SFFromSFN               ;   while ((d=SF(i)) != NULL)
	RestoreReg  <BX>
	JC      Sft1
	invoke  PointComp
	JZ      DPBRet                  ;               goto Done;
SFTNext:INC     BX                      ;           else
	JMP     SFTLoop                 ;               i++;
SFT1:   LES     DI,[sftFCB]
	MOV     BX,[es:DI+sfCount]
	LEA     DI,[DI+sfTable]
SFT2:
	invoke  PointComp
DPBRETJ:JZ      DPBRet
	ADD     DI,sizeof.sf_entry
	DEC     BX
	JNZ     SFT2
;
; The SFT is not in the allocated tables.  See if it is one of the static
; areas.
;
	Context ES
	MOV     DI,[AUXStack-sizeof].SF_ENTRY
	Invoke  PointComp
	JZ      DPBRet
	MOV     DI,renbuf
	Invoke  PointComp
	JZ      DPBRetj
DPBNotFoundJ:
	JMP     DPBNotFound
EndProc SFTCheck

;   BUFCheck - validate a supposed BUF pointer
;   Inputs:     Pushed arguments
;   Outputs:    Message to screen
;   Registers modified: none

Procedure   BUFCheck,NEAR
	MOV     [Msg],BUFMes
	SaveReg <BP>
	MOV     BP,SP
	PUSHF
	SaveReg <AX,BX,DS,SI,ES,DI>
;
; CheckDisk - make sure that we are in the disk critical section...
;
	MOV     byte AL,ECritDisk
	CMP     AL,[CritNOP]
	JZ      CheckDone
	MOV     AX,[CURRENTPDB]
	CMP     [SectPDB+2] * critDisk,AX
	MOV     AX,[BP].[Astmes]
	JZ      CheckRef
	zfmt    <"p$: x$ s$ critDisk owned by x$\n">,<User_In_AX,AX,SectPDB+2*critDisk>
CheckRef:
	CMP     [SectRef+2] * critDisk,0
	JNZ     CheckDone
	zfmt    <"p$: x$ s$ critDisk ref count is 0\n">,<User_In_AX,AX>
CheckDone:

	LDS     SI,[BP].[Astarg]
	LES     DI,[BUFFHEAD]
BUFLoop:CMP     DI,-1
	JZ      DPBNotFoundJ
	invoke  PointComp
	JNZ     BufNext
	JMP     DPBRet
BufNext:
	LES     DI,[es:DI+buf_link]
	JMP     BUFLoop
EndProc BUFCheck

;CODE    ENDS
else
end if
end if
;END
