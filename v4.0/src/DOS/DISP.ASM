;       SCCSID = @(#)disp.asm   1.1 85/04/10
;       SCCSID = @(#)disp.asm   1.1 85/04/10
;
; Dispatcher code
;

;.xlist
;.xcref
INCLUDE '../INC/DOSSYM.INC'
INCLUDE '../INC/DOSSEG.ASM'
;.cref
;.list

AsmVars <KANJI, debug>

BREAK   <Copyright notice and version>
if SEGSEL = S_CODE


        I_need  CurrentPDB,WORD
        I_need  CNTCFLAG,BYTE
        I_need  user_SS,WORD
        I_need  user_SP,WORD
        I_need  NSS,WORD
        I_need  NSP,WORD
        I_need  MAXCALL,BYTE
        I_need  MAXCOM,BYTE
        I_need  SaveDS,WORD
        I_need  SaveBX,WORD
        I_need  INDOS,BYTE
        I_need  USER_ID,WORD
        I_need  PROC_ID,WORD
        I_need  AuxStack,BYTE
        I_need  IOStack,BYTE
        I_need  DskStack,BYTE
        I_need  fSharing,BYTE
        I_need  NoSetDir,BYTE
        I_need  FAILERR,BYTE
        I_need  ErrorMode,BYTE
        I_need  restore_tmp,WORD
        I_need  WPErr,BYTE
        I_need  DISPATCH,WORD
        I_need  CONSWAP,BYTE
        I_need  USER_IN_AX,WORD
        I_need  EXTERR_LOCUS,BYTE
        I_need  IDLEINT,BYTE
        I_need  PRINTER_FLAG,BYTE
        I_need  CPSWFLAG,BYTE              ;AN000;
        I_need  CPSWSAVE,BYTE              ;AN000;
        I_need  DISK_FULL,BYTE             ;AN000;
        I_need  InterCon,BYTE              ;AN000;
        I_need  BOOTDRIVE,BYTE             ;AN000;
        I_need  EXTOPEN_ON,BYTE            ;AN000;
        I_need  DOS34_FLAG,WORD            ;AN000;
        I_need  ACT_PAGE,WORD              ;AN000;

        if      NOT IBM
        I_need  OEM_HANDLER,DWORD
        end if

	if	BUFFERFLAG
	I_am	SETVECTFLAG,BYTE,<0>
	i_need	BUF_EMS_SEG_CNT,WORD	     ; DOS 4.00 EMS seg count		;AN000;
	i_need	BUF_EMS_MODE,BYTE	     ; DOS 4.00 EMS mode 		;AN000;
	i_am	BUF_EMS_MAP_USER,12,<0,0,0,0,0,0,0,0,0,0,0,0>
	end if

;ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

BREAK   <System call entry points and dispatcher>
;ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

BREAK <SET_CTRL_C_TRAPPING$ -- En/Disable ^C check in dispatcher>

; Inputs:
;       AL = 0 read ^C status
;       AL = 1 Set ^C status, DL = 0/1 for ^C off/on
;       AL = 2 Set ^C status to contents of DL.  Output is old state.
;       AL = 3 Get CPSW state to DL        DOS 3.4
;       AL = 4 Set CPSW state from DL      DOS 3.4
;       AL = 5 get DOS boot drive
; Function:
;       Enable disable ^C checking in dispatcher
; Outputs:
;       If AL = 0 then DL = 0/1 for ^C off/on

        procedure   SET_CTRL_C_TRAPPING$,NEAR
;ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        OR      AL,AL
        JNZ     Check1
        MOV     DL,[cs:CNTCFLAG]
        IRET
Check1:
        CMP     AL,2
        JA      CPSWchk                        ;AN000;
        JZ      SetAndRet
        PUSH    DX
        AND     DL,01h
        MOV     [cs:CNTCFLAG],DL
        POP     DX
        IRET
SetAndRet:
        AND     DL,01h
        XCHG    [cs:CNTCFLAG],DL
        IRET
BadVal:
        MOV     AL,0FFH
        IRET
;; DOS 4.00 File Tagging

CPSWchk:                                ;AN000;
;       PUSH    AX                      ;AN000;;FT.
;       MOV     AL,[CPSWSAVE]           ;AN000;;FT. DOS 3.4
;       MOV     [CPSWFLAG],AL           ;AN000;;FT. DOS 3.4 in case ABORT
;       POP     AX                      ;AN000;;FT.
        CMP     AL,3                    ;AN000;;FT get CPSW state ?
        JNZ     CPSWset                 ;AN000;;FT. no
;       MOV     DL,CPSWFLAG             ;AN000;;FT. return CPSW state
        IRET                            ;AN000;
CPSWset:                                ;AN000;
        CMP     AL,4                     ;AN000;;FT. set CPSW state ?
        JA      QueryDOSboot             ;AN000;;FT. check query dos boot drive
;       PUSH    AX                       ;AN000;;FT.
;       CallInstall NLSInstall,NLSFUNC,0 ;AN000;;FT. NLSFUNC installed ?
;       CMP     AL,0FFH                  ;AN000;;FT.
;       POP     AX                       ;AN000;;FT.
;       JNZ     BadVal                   ;AN000;;FT. not loaded, therefore ignore
;;;;    AND     DL,01H                   ;AN000;;FT. only 0 or 1
;;;;    MOV     [CPSWFLAG],DL            ;AN000;;FT. set the flag
;;;;    MOV     [CPSWSAVE],DL            ;AN000;;FT. save one copy
        IRET                             ;AN000;;FT.
QueryDOSboot:                            ;AN000;
        CMP     AL,5                ;AN000;MS.
        JA      BadVal              ;AN000;MS.
        MOV     DL,[cs:BOOTDRIVE]      ;AN000;;MS. put boot drive in DL
        IRET                        ;AN000;;MS.


;; DOS 4.00 File Tagging

EndProc SET_CTRL_C_TRAPPING$

BREAK <GET_CURRENT_PDB$ -- Set/Get PDB value>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
; The following two routines are dispatched to directly with ints disabled
; immediately after the int 21h entry.  no DIS state is set.
;
; $Set_current_PDB takes BX and sets it to be the current process
;   *** THIS FUNCTION CALL IS SUBJECT TO CHANGE!!! ***
;
        procedure   SET_CURRENT_PDB$,NEAR
;        ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        MOV     [cs:CurrentPDB],BX
        IRET
EndProc SET_CURRENT_PDB$

;
; $get_current_PDB returns in BX the current process
;   *** THIS FUNCTION CALL IS SUBJECT TO CHANGE!!! ***
;
procedure   GET_CURRENT_PDB$,NEAR
;        ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        MOV     BX,[cs:CurrentPDB]
        IRET
EndProc GET_CURRENT_PDB$
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

;
; Sets the Printer Flag to whatever is in AL.
; NOTE: THIS PROCEDURE IS SUBJECT TO CHANGE!!!
;
Procedure Set_Printer_Flag$
;ASSUME DS:NOTHING, ES:NOTHING, SS:NOTHING
        mov     [cs:PRINTER_FLAG],al
        IRET
EndProc Set_Printer_Flag$

        procedure   SYSTEM_CALL,NEAR
;
; The Quit entry point is where all INT 20h's come from.  These are old- style
; exit system calls.  The CS of the caller indicates which Process is dying.
; The error code is presumed to be 0.  We simulate an ABORT system call.
;
        entry   QUIT
        MOV     AH,0
        JMP     SHORT SAVREGS
;
; The system call in AH is out of the range that we know how to handle.  We
; arbitrarily set the contents of AL to 0 and IRET.  Note that we CANNOT set
; the carry flag to indicate an error as this may break some programs
; compatability.
;
BADCALL:
        MOV     AL,0
        entry   IRETT
        IRET
;
; An alternative method of entering the system is to perform a CALL 5 in the
; program segment prefix with the contents of CL indicating what system call
; the user would like.  A subset of the possible system calls is allowed here;
; only the CPM-compatible calls may get dispatched.
;
        entry   CALL_ENTRY              ; System call entry point and dispatcher
        POP     AX                      ; IP from the long call at 5
        POP     AX                      ; Segment from the long call at 5
        POP     word [cs:user_SP]               ; IP from the CALL 5
;
; Re order the stack to simulate an interrupt 21.
;
        PUSHF                           ; Start re-ordering the stack
        CLI
        PUSH    AX                      ; Save segment
        PUSH    word [cs:user_SP]               ; Stack now ordered as if INT had been used
        CMP     CL,[cs:MAXCALL]              ; This entry point doesn't get as many calls
        JA      BADCALL
        MOV     AH,CL
        JMP     SHORT SAVREGS
;
; This is the normal INT 21 entry point.  We first perform a quick test to see
; if we need to perform expensive DOS-entry functions.  Certain system calls
; are done without interrupts being enabled.
;

entry   COMMAND                         ; Interrupt call entry point (INT 21H)

        if      NOT IBM
        CMP     AH,Set_Oem_Handler
        JB      NOTOEM
        JMP     SET_OEM_HANDLER$
NOTOEM:
        end if

        CMP     AH,[cs:MAXCOM]
        JA      BADCALL

;
; The following set of calls are issued by the server at *arbitrary* times
; and, therefore, must be executed on the user's entry stack and executed with
; interrupts off.
;
SAVREGS:
        CMP     AH,Get_Current_PDB
        JZ      GET_CURRENT_PDB$
        CMP     AH,GetCurrentPSP
        JZ      GET_CURRENT_PDB$
        CMP     AH,Set_Current_PDB
        JZ      SET_CURRENT_PDB$
        CMP     AH,Set_CTRL_C_Trapping
        JNZ     chkprt
        JMP     SET_CTRL_C_TRAPPING$
chkprt:
        CMP     AH,Set_Printer_Flag
        JZ      Set_Printer_Flag$
;
; Preserve all user's registers on his own stack.
;
        CALL    save_world
        MOV     [cs:SaveDS],DS
        MOV     [cs:SaveBX],BX
        MOV     BX,CS
        MOV     DS,BX
;        ASSUME  DS:DOSGROUP
        INC     byte [INDOS]                 ; Flag that we're in the DOS
        XOR     AX,AX
        MOV     [USER_ID],AX
        MOV     AX,[CurrentPDB]           ; current process
        MOV     [PROC_ID],AX            ; Assume local machine for the moment
;
; Provide one level of reentrancy for INT 24 recallability.
;
        MOV     AX,[user_SP]
        MOV     [NSP],AX
        MOV     AX,[user_SS]
        MOV     [NSS],AX
        POP     AX
        PUSH    AX
        MOV     [user_SP],SP
        MOV     [user_SS],SS
;
; save user stack in his area for later returns (possibly from EXEC)
;
        MOV     DS,[CurrentPDB]
;ASSUME  DS:NOTHING
        MOV     word [Process_data_block.PDB_User_stack],SP
        MOV     word [Process_data_block.PDB_User_stack+2],SS

        MOV     byte [cs:fSharing],0              ; allow redirection

        MOV     BX,CS                   ; no holes here.
        MOV     SS,BX
;ASSUME  SS:DOSGROUP

entry   REDISP
        MOV     SP,AuxStack ; Enough stack for interrupts
        STI                             ; stack is in our space now...
 if  DBCS                                       ;AN000;
        MOV     BH, byte [PDB_InterCon]  ;AN000;; get interim mode  2/13/KK
        MOV     [ss:InterCon], BH               ;AN000;; 2/13/KK
 end if                                          ;AN000;
        MOV     BX,CS
        MOV     DS,BX
        DOSAssume   CS,<DS>,"MSCODE/ReDisp"
;; DOS 3.4 INIT
;       MOV     BL,[CPSWSAVE]           ;AN000;;FT. DOS 3.4
;       MOV     [CPSWFLAG],BL           ;AN000;;FT. DOS 3.4 in case ABORT
        MOV     byte [ss:DISK_FULL],0           ;AN000;;MS. no disk full
        MOV     byte [ss:EXTOPEN_ON],0          ;AN000;;EO. clear extended open flag
        MOV     word [ss:DOS34_FLAG],0          ;AN000;;MS. clear common flag
        MOV     word [ss:ACT_PAGE],-1           ;BN000;BL;AN000;;LB. invalidate active page
;; DOS 4.00 INIT
        XOR     BH,BH
        MOV     [ss:CONSWAP],BH            ; random clean up of possibly mis-set flags
        MOV     byte [ss:IDLEINT],1             ; presume that we can issue INT 28
        MOV     byte [ss:NoSetDir],BH  ; set directories on search
        MOV     byte [ss:FAILERR],BH   ; FAIL not in progress
        MOV     BL,AH
        SHL     BX,1                    ; 2 bytes per call in table
        CLD
;
; Since the DOS maintains mucho state information across system calls, we
; must be very careful about which stack we use.
;
; First, all abort operations must be on the disk stack.  THis is due to the
; fact that we may be hitting the disk (close operations, flushing) and may
; need to report an INT 24.
;
        OR      AH,AH
        JZ      DSKROUT                 ; ABORT
;
; Second, PRINT and PSPRINT and the server issue GetExtendedError calls at
; INT 28 and INT 24 time.  This call MUST, therefore, use the AUXSTACK.
;
        CMP     AH,GetExtendedError
        JZ      DISPCALL
;
; Old 1-12 system calls may be either on the IOSTACK (normal operation) or
; on the AUXSTACK (at INT 24 time).
;
        CMP     AH,12
        JA      DSKROUT
        CMP     byte [ss:ErrorMode],0           ; Are we in an INT 24?
        JNZ     DISPCALL                ; Stay on AUXSTACK if INT 24.
        MOV     SP,IOStack
        JMP     SHORT DISPCALL
;
; We are on a system call that is classified as "the rest".  We place
; ourselves onto the DSKSTACK and away we go.  We know at this point:
;
;   o   An INT 24 cannot be in progress.  Therefore we reset errormode and
;       wperr
;   o   That there can be no critical sections in effect.  We signal the
;       server to remove all the resources.
;
DSKROUT:
        MOV     [ss:USER_IN_AX],AX         ; Remember what user is doing
        MOV     byte [ss:EXTERR_LOCUS],errLOC_Unk ; Default
        MOV     byte [ss:ErrorMode],0           ; Cannot make non 1-12 calls in
        MOV     byte [ss:WPErr],-1              ; error mode, so good place to make
;
; Release all resource information
;
        PUSH    AX
        MOV     AH,82h
        INT     int_IBM
        POP     AX

;
; Since we are going to be running on the DSKStack and since INT 28 people
; will use the DSKStack, we must turn OFF the generation of INT 28's.
;
        MOV     byte [ss:IDLEINT],0
        MOV     SP,DskStack
        TEST    byte [ss:CNTCFLAG],-1
        JZ      DISPCALL                ; Extra ^C checking is disabled
        PUSH    AX
        invoke  DSKSTATCHK
        POP     AX
DISPCALL:
        MOV     BX,[cs:DISPATCH+BX]
        XCHG    BX,[ss:SaveBX]
        MOV     DS,[ss:SaveDS]

if	BUFFERFLAG
	mov	byte [cs:SETVECTFLAG], 0
	cmp	ah, 25h
	jne	saveuser
	cmp	ah, 35h
	jne	saveuser
	mov	byte [cs:SETVECTFLAG], 1
saveuser:
	invoke	SAVE_USER_MAP		    ;AN000;LB.	save EMS map
end if

;        ASSUME  DS:NOTHING
        CALL    word [ss:SaveBX]

if	BUFFERFLAG
      invoke  RESTORE_USER_MAP            ;AN000;LB.  retsore EMS map
end if

        entry   LEAVEDOS
;ASSUME  SS:NOTHING                      ; User routines may misbehave
        CLI
        DEC     byte [cs:INDOS]
        MOV     SS,[cs:user_SS]
        MOV     SP,[cs:user_SP]
        MOV     BP,SP
        MOV     byte [BP+user_environ.user_AX],AL
        MOV     AX,[cs:NSP]
        MOV     [cs:user_SP],AX
        MOV     AX,[cs:NSS]
        MOV     [cs:user_SS],AX
        CALL    restore_world
        IRET
EndProc SYSTEM_CALL

;
; restore_world restores all registers ('cept SS:SP, CS:IP, flags) from
; the stack prior to giving the user control
;
;        ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        procedure   restore_world,NEAR
        POP     word [cs:restore_tmp]             ; POP     restore_tmp
        POP     AX                      ; PUSH    ES
        POP     BX                      ; PUSH    DS
        POP     CX                      ; PUSH    BP
        POP     DX                      ; PUSH    DI
        POP     SI                      ; PUSH    SI
        POP     DI                      ; PUSH    DX
        POP     BP                      ; PUSH    CX
        POP     DS                      ; PUSH    BX
        POP     ES                      ; PUSH    AX
        JMP     word [cs:restore_tmp]             ; PUSH    restore_tmp
EndProc restore_world

;
; save_world saves complete registers on the stack
;
;        ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING
        procedure   save_world,NEAR
        POP     word [cs:restore_tmp]
        PUSH    ES
        PUSH    DS
        PUSH    BP
        PUSH    DI
        PUSH    SI
        PUSH    DX
        PUSH    CX
        PUSH    BX
        PUSH    AX
        JMP     word [cs:restore_tmp]             ; PUSH    restore_tmp
EndProc save_world

if BUFFERFLAG

Break	<SAVE_USER_MAP - save map >							;AN000;
; Inputs:									;AN000;
;	none									;AN000;
; Function:									;AN000;
;	save map								;AN000;
; Outputs:									;AN000;
;	none									;AN000;
; No other registers altered							;AN000;
										;AN000;
Procedure   SAVE_USER_MAP,NEAR							 ;AN000;
;	ASSUME	DS:NOTHING,ES:NOTHING						;AN000;
										;AN000;
	CMP	byte [cs:BUF_EMS_MODE],-1	  ;LB. EMS support			;AN000;
	JZ	No_user_save 		  ;LB. no				;AN000;
	CMP	byte [cs:SETVECTFLAG], 1
	jz	No_user_save
;	MOV	[ACT_PAGE],-1		  ;LB. invalidate active page		;AN000;
;	MOV	WORD PTR [LASTBUFFER],-1  ;LB.	and last buffer pointer 	;AN000;
	PUSH	AX			  ;LB. save regs			;AN000;
	PUSH	DS			  ;LB. save regs			;AN000;
	PUSH	ES			  ;LB.					;AN000;
	PUSH	SI			  ;LB.					;AN000;
	PUSH	DI			  ;LB.					;AN000;
	MOV	SI,BUF_EMS_SEG_CNT     ;LB.			;AN000;
	MOV	DI,BUF_EMS_MAP_USER     ;LB.			;AN000;

	PUSH	CS
	POP	ES
	PUSH	CS			  ;LB. ds:si -> ems seg cnt 		;AN000;
	POP	DS			  ;LB.					;AN000;

	MOV	AX,4F00H		  ;LB. save map 			;AN000;
	EnterCrit  critDisk		  ;LB. enter critical section		;AN000;
	INT	67H			  ;LB.					;AN000;
	LeaveCrit  critDisk		  ;LB. leave critical section		;AN000;
	POP	DI			  ;LB.					;AN000;
	POP	SI			  ;LB. restore regs			;AN000;
	POP	ES			  ;LB.					;AN000;
	POP	DS			  ;LB.					;AN000;
	POP	AX			  ;LB. restore				;AN000;
No_user_save:									 ;AN000;
	return									;AN000;
EndProc SAVE_USER_MAP								 ;AN000;
										;AN000;

Break	<RESTORE_USER_MAP- retore map >						;AN000;
; Inputs:									;AN000;
;	none									;AN000;
; Function:									;AN000;
;	restore_map								;AN000;
; Outputs:									;AN000;
;	none									;AN000;
; No other registers altered							;AN000;
										;AN000;
Procedure   RESTORE_USER_MAP,NEAR							 ;AN000;
;	ASSUME	DS:NOTHING,ES:NOTHING						;AN000;
	
	CMP	byte [cs:BUF_EMS_MODE],-1	  ;LB. EMS support			;AN000;
	JZ	No_user_restore		  ;LB. no				;AN000;
	CMP	byte [cs:SETVECTFLAG], 1
	jz	No_user_restore
	PUSH	AX			  ;LB. save regs			;AN000;
	PUSH	DS			  ;LB. save regs			;AN000;
	PUSH	SI			  ;LB.					;AN000;
	MOV	SI,BUF_EMS_MAP_USER     ;LB.			;AN000;

	PUSH	CS
	POP	DS

	MOV	AX,4F01H		  ;LB. restore map			;AN000;
	EnterCrit  critDisk		  ;LB. enter critical section		;AN000;
	INT	67H			  ;LB.					;AN000;
	LeaveCrit  critDisk		  ;LB. leave critical section		;AN000;
	POP	SI			  ;LB. restore regs			;AN000;
	POP	DS			  ;LB.					;AN000;
	POP	AX			  ;LB.					;AN000;
No_user_restore:									 ;AN000;
	return									;AN000;
EndProc RESTORE_USER_MAP

end if

;
; get_user_stack returns the user's stack (and hence registers) in DS:SI
;
        procedure   get_user_stack,NEAR
        LDS     SI,dword [cs:user_SP]
        return
EndProc get_user_stack

        if      NOT IBM
BREAK <Set_Oem_Handler -- Set OEM sys call address and handle OEM Calls>

SET_OEM_HANDLER$:
;ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING

; Inputs:
;       User registers, User Stack, INTS disabled
;       If CALL F8, DS:DX is new handler address
; Function:
;       Process OEM INT 21 extensions
; Outputs:
;       Jumps to OEM_HANDLER if appropriate

        JNE     DO_OEM_FUNC             ; If above F8 try to jump to handler
        MOV     word [cs:OEM_HANDLER],DX   ; Set Handler
        MOV     word [cs:OEM_HANDLER+2],DS
        IRET                            ; Quick return, Have altered no registers

DO_OEM_FUNC:
        CMP     word [cs:OEM_HANDLER],-1
        JNZ     OEM_JMP
        JMP     BADCALL                 ; Handler not initialized

OEM_JMP:
        JMP     [cs:OEM_HANDLER]
        end if


end if
