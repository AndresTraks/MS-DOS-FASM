;
; MSCODE.ASM -- MSDOS code
;

ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

        i_need  USER_SP,WORD
        i_need  USER_SS,WORD
        i_need  SAVEDS,WORD
        i_need  SAVEBX,WORD
        i_need  INDOS,BYTE
        i_need  NSP,WORD
        i_need  NSS,WORD
        i_need  CURRENTPDB,WORD
        i_need  AUXSTACK,BYTE
        i_need  CONSWAP,BYTE
        i_need  IDLEINT,BYTE
        i_need  NOSETDIR,BYTE
        i_need  ERRORMODE,BYTE
        i_need  IOSTACK,BYTE
        i_need  WPERR,BYTE
        i_need  DSKSTACK,BYTE
        i_need  CNTCFLAG,BYTE
        i_need  LEAVEADDR,WORD
        i_need  NULLDEVPT,DWORD

        IF IBM = 0
        i_need  OEM_HANDLER,DWORD
        END IF

;BREAK   <Copyright notice and version>

CODSTRT =     $

        IF      IBM = 0
        IF      KANJI = 0
HEADER  DB      13,10,"Microsoft MS-DOS version "
        DB      DOS_MAJOR_VERSION + "0"
        DB      "."
        DB      (DOS_MINOR_VERSION / 10) + "0"
        DB      (DOS_MINOR_VERSION MOD 10) + "0"
        IF      HIGHMEM
        DB      "H"
        END IF
        END IF
        IF      KANJI = 1
HEADER  DB      13,10,82h,"M"+1fh,82h,"i"+20h,82h,"c"+20h,82h,"r"+20h,82h,"o"+20h
        DB      82h,"s"+20h,82h,"o"+20h,82h,"f"+20h,82h,"t"+20h
        DB      81h,40h,82h,"M"+1fh,82h,"S"+1fh,81h,5dh+1fh
        DB      82h,"D"+1fh,82h,"O"+1fh,82h,"S"+1fh,81h,40h
        DB      82h,DOS_MAJOR_VERSION+"0"+1fh
        DB      81h,25h+1fh
        DB      82h,(DOS_MINOR_VERSION / 10)+"0"+1fh
        DB      82h,(DOS_MINOR_VERSION MOD 10)+"0"+1fh
        DB      94h,0c5h
        END IF
        DB      13,10
        DB      "Copyright 1981,82,83 Microsoft Corp.",13,10,"$"
        END IF
;BREAK   <System call entry points and dispatcher>
ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

        procedure   SYSTEM_CALL,NEAR
entry   QUIT                                   ; INT 20H entry point
        MOV     AH,0
        JMP     SHORT SAVREGS

entry   COMMAND                         ; Interrupt call entry point (INT 21H)

        IF      IBM = 0
        CMP     AH,SET_OEM_HANDLER
        JB      NOTOEM
        JMP     _SET_OEM_HANDLER
NOTOEM:
        END IF

        CMP     AH,MAXCOM
        JBE     SAVREGS
BADCALL:
        MOV     AL,0
entry   _IRET
        IRET

entry   CALL_ENTRY                      ; System call entry point and dispatcher
        POP     AX                      ; IP from the long call at 5
        POP     AX                      ; Segment from the long call at 5
        POP     [CS:user_SP]               ; IP from the CALL 5
        PUSHF                           ; Start re-ordering the stack
        CLI
        PUSH    AX                      ; Save segment
        PUSH    [CS:user_SP]               ; Stack now ordered as if INT had been used
        CMP     CL,MAXCALL              ; This entry point doesn't get as many calls
        JA      BADCALL
        MOV     AH,CL
SAVREGS:
        CALL    save_world
        MOV     [CS:SaveDS],DS
        MOV     [CS:SaveBX],BX
        MOV     BX,CS
        MOV     DS,BX
ASSUME  DS:DOSGROUP
        INC     [INDOS]                 ; Flag that we're in the DOS
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
; Here comes multitasking!!!
;
        MOV     DS,[CurrentPDB]
        MOV     WORD [DS:Process_data_block.PDB_User_stack],SP
        MOV     WORD [DS:Process_data_block.PDB_User_stack+2],SS

        MOV     BX,CS                   ; no holes here.
        MOV     SS,BX
ASSUME  SS:DOSGROUP

    entry   REDISP
        MOV     SP,AuxStack     ; Enough stack for interrupts
        STI                             ; Stack OK now
        PUSH    CS
        POP     DS
        XOR     BH,BH
        MOV     [CONSWAP],BH
        MOV     [IDLEINT],1
        MOV     BYTE [NoSetDir],0   ; set directories on search
        MOV     BL,AH
        SHL     BX,1
        CLD
        OR      AH,AH
        JZ      DSKROUT                 ; ABORT
        CMP     AH,12
        JBE     IOROUT                  ; Character I/O
        CMP     AH,GET_CURRENT_PDB      ; INT 24 needs GET,SET PDB
        JZ      IOROUT
        CMP     AH,SET_CURRENT_PDB
        JNZ     DSKROUT
IOROUT:
        CMP     [ERRORMODE],0
        JNZ     DISPCALL                ; Stay on AUXSTACK if INT 24
        MOV     SP,IOSTACK
        JMP     SHORT DISPCALL

DSKROUT:
        MOV     [ERRORMODE],0           ; Cannot make non 1-12 calls in
        MOV     [WPERR],-1              ; error mode, so good place to
                                        ; make sure flags are reset
        MOV     SP,DSKSTACK
        TEST    [CNTCFLAG],-1
        JZ      DISPCALL
        PUSH    AX
        invoke  DSKSTATCHK
        POP     AX
DISPCALL:
        PUSH    [LEAVEADDR]
        PUSH    WORD[CS:BX+DISPATCH]
        MOV     BX,[SaveBX]
        MOV     DS,[SaveDS]
ASSUME  DS:NOTHING
        return

        entry _LEAVE
ASSUME  SS:NOTHING                      ; User routines may misbehave
        CLI
        DEC     [CS:INDOS]
        MOV     SP,[CS:user_SP]
        MOV     SS,[CS:user_SS]
        MOV     BP,SP
        MOV     BYTE [BP+user_environ.user_AX],AL
        MOV     AX,[CS:NSP]
        MOV     [CS:user_SP],AX
        MOV     AX,[CS:NSS]
        MOV     [CS:user_SS],AX
        CALL    restore_world

        IRET

;
; restore_world restores all registers ('cept SS:SP, CS:IP, flags) from
; the stack prior to giving the user control
;
        ASSUME  DS:NOTHING,ES:NOTHING
restore_tmp DW  ?
        procedure   restore_world,NEAR
        POP     [CS:restore_tmp]   ; POP     restore_tmp
        POP     AX              ; PUSH    ES
        POP     BX              ; PUSH    DS
        POP     CX              ; PUSH    BP
        POP     DX              ; PUSH    DI
        POP     SI              ; PUSH    SI
        POP     DI              ; PUSH    DX
        POP     BP              ; PUSH    CX
        POP     DS              ; PUSH    BX
        POP     ES              ; PUSH    AX
world_ret:
        PUSH    [CS:restore_tmp]   ; PUSH    restore_tmp
        return

;
; save_world saves complete registers on the stack
;
        procedure   save_world,NEAR
        POP     [CS:restore_tmp]
        PUSH    ES
        PUSH    DS
        PUSH    BP
        PUSH    DI
        PUSH    SI
        PUSH    DX
        PUSH    CX
        PUSH    BX
        PUSH    AX
        JMP     SHORT world_ret

;
; get_user_stack returns the user's stack (and hence registers) in DS:SI
;
        procedure   get_user_stack,NEAR
        LDS     SI, dword[CS:user_SP]
        return

; Standard Functions
DISPATCH:
        short_addr  _ABORT                          ;  0      0
        short_addr  _STD_CON_INPUT                  ;  1      1
        short_addr  _STD_CON_OUTPUT                 ;  2      2
        short_addr  _STD_AUX_INPUT                  ;  3      3
        short_addr  _STD_AUX_OUTPUT                 ;  4      4
        short_addr  _STD_PRINTER_OUTPUT             ;  5      5
        short_addr  _RAW_CON_IO                     ;  6      6
        short_addr  _RAW_CON_INPUT                  ;  7      7
        short_addr  _STD_CON_INPUT_NO_ECHO          ;  8      8
        short_addr  _STD_CON_STRING_OUTPUT          ;  9      9
        short_addr  _STD_CON_STRING_INPUT           ; 10      A
        short_addr  _STD_CON_INPUT_STATUS           ; 11      B
        short_addr  _STD_CON_INPUT_FLUSH            ; 12      C
        short_addr  _DISK_RESET                     ; 13      D
        short_addr  _SET_DEFAULT_DRIVE              ; 14      E
        short_addr  _FCB_OPEN                       ; 15      F
        short_addr  _FCB_CLOSE                      ; 16     10
        short_addr  _DIR_SEARCH_FIRST               ; 17     11
        short_addr  _DIR_SEARCH_NEXT                ; 18     12
        short_addr  _FCB_DELETE                     ; 19     13
        short_addr  _FCB_SEQ_READ                   ; 20     14
        short_addr  _FCB_SEQ_WRITE                  ; 21     15
        short_addr  _FCB_CREATE                     ; 22     16
        short_addr  _FCB_RENAME                     ; 23     17
        short_addr  CPMFUNC                         ; 24     18
        short_addr  _GET_DEFAULT_DRIVE              ; 25     19
        short_addr  _SET_DMA                        ; 26     1A

;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  _SLEAZEFUNC                     ; 27     1B
        short_addr  _SLEAZEFUNCDL                   ; 28     1C
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

        short_addr  CPMFUNC                         ; 29     1D
        short_addr  CPMFUNC                         ; 30     1E
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  _GET_DEFAULT_DPB                ; 31     1F
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  CPMFUNC                         ; 32     20
        short_addr  _FCB_RANDOM_READ                ; 33     21
        short_addr  _FCB_RANDOM_WRITE               ; 34     22
        short_addr  _GET_FCB_FILE_LENGTH            ; 35     23
        short_addr  _GET_FCB_POSITION               ; 36     24
MAXCALL =       ($-DISPATCH)/2 - 1

; Extended Functions
        short_addr  _SET_INTERRUPT_VECTOR           ; 37     25
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  _CREATE_PROCESS_DATA_BLOCK      ; 38     26
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  _FCB_RANDOM_READ_BLOCK          ; 39     27
        short_addr  _FCB_RANDOM_WRITE_BLOCK         ; 40     28
        short_addr  _PARSE_FILE_DESCRIPTOR          ; 41     29
        short_addr  _GET_DATE                       ; 42     2A
        short_addr  _SET_DATE                       ; 43     2B
        short_addr  _GET_TIME                       ; 44     2C
        short_addr  _SET_TIME                       ; 45     2D
        short_addr  _SET_VERIFY_ON_WRITE            ; 46     2E

; Extended functionality group
        short_addr  _GET_DMA                        ; 47     2F
        short_addr  _GET_VERSION                    ; 48     30
        short_addr  _Keep_Process                   ; 49     31
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  _GET_DPB                        ; 50     32
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  _SET_CTRL_C_TRAPPING            ; 51     33
        short_addr  _GET_INDOS_FLAG                 ; 52     34
        short_addr  _GET_INTERRUPT_VECTOR           ; 53     35
        short_addr  _GET_DRIVE_FREESPACE            ; 54     36
        short_addr  _CHAR_OPER                      ; 55     37
        short_addr  _INTERNATIONAL                  ; 56     38
; XENIX CALLS
;   Directory Group
        short_addr  _MKDIR                          ; 57     39
        short_addr  _RMDIR                          ; 58     3A
        short_addr  _CHDIR                          ; 59     3B
;   File Group
        short_addr  _CREAT                          ; 60     3C
        short_addr  _OPEN                           ; 61     3D
        short_addr  _CLOSE                          ; 62     3E
        short_addr  _READ                           ; 63     3F
        short_addr  _WRITE                          ; 64     40
        short_addr  _UNLINK                         ; 65     41
        short_addr  _LSEEK                          ; 66     42
        short_addr  _CHMOD                          ; 67     43
        short_addr  _IOCTL                          ; 68     44
        short_addr  _DUP                            ; 69     45
        short_addr  _DUP2                           ; 70     46
        short_addr  _CURRENT_DIR                    ; 71     47
;    Memory Group
        short_addr  _ALLOC                          ; 72     48
        short_addr  _DEALLOC                        ; 73     49
        short_addr  _SETBLOCK                       ; 74     4A
;    Process Group
        short_addr  _EXEC                           ; 75     4B
        short_addr  _EXIT                           ; 76     4C
        short_addr  _WAIT                           ; 77     4D
        short_addr  _FIND_FIRST                     ; 78     4E
;   Special Group
        short_addr  _FIND_NEXT                      ; 79     4F
; SPECIAL SYSTEM GROUP
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  _SET_CURRENT_PDB                ; 80     50
        short_addr  _GET_CURRENT_PDB                ; 81     51
        short_addr  _GET_IN_VARS                    ; 82     52
        short_addr  _SETDPB                         ; 83     53
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  _GET_VERIFY_ON_WRITE            ; 84     54
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        short_addr  _Dup_PDB                        ; 85     55
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
        short_addr  _RENAME                         ; 86     56
        short_addr  _FILE_TIMES                     ; 87     57
        short_addr  _AllocOper                      ; 88     58

MAXCOM  =       ($-DISPATCH)/2 - 1

CPMFUNC:
        XOR     AL,AL
        return

        IF      IBM = 0
;BREAK <Set_OEM_Handler -- Set OEM sys call address and handle OEM Calls>

_SET_OEM_HANDLER:
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       User registers, User Stack, INTS disabled
;       If CALL F8, DS:DX is new handler address
; Function:
;       Process OEM INT 21 extensions
; Outputs:
;       Jumps to OEM_HANDLER if appropriate

        JNE     DO_OEM_FUNC             ; If above F8 try to jump to handler
        MOV     WORD [CS:OEM_HANDLER],DX       ; Set Handler
        MOV     WORD [CS:OEM_HANDLER+2],DS
        IRET                            ; Quick return, Have altered no registers

DO_OEM_FUNC:
        CMP     WORD [CS:OEM_HANDLER],-1
        JNZ     OEM_JMP
        JMP     BADCALL                 ; Handler not initialized

OEM_JMP:
        JMP     [CS:OEM_HANDLER]

        END IF


ASSUME  SS:DOSGROUP

;
; $Set_current_PDB takes BX and sets it to be the current process
;   *** THIS FUNCTION CALL IS SUBJECT TO CHANGE!!! ***
;
        procedure   _SET_CURRENT_PDB,NEAR
        ASSUME  DS:NOTHING,SS:NOTHING
        MOV     [CurrentPDB],BX
        return

;
; $get_current_PDB returns in BX the current process
;   *** THIS FUNCTION CALL IS SUBJECT TO CHANGE!!! ***
;
        procedure   _GET_CURRENT_PDB,NEAR
        ASSUME  DS:NOTHING,SS:NOTHING
        invoke    get_user_stack
        PUSH    [CS:CurrentPDB]
        POP     [SI+user_environ.user_BX]
        return
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

; BREAK <NullDev -- Driver for null device>
        procedure   SNULDEV,FAR
ASSUME DS:NOTHING,ES:NOTHING,SS:NOTHING
        MOV     WORD [CS:NULLDEVPT],BX
        MOV     WORD [CS:NULLDEVPT+2],ES
        retf

        procedure   INULDEV,FAR
        PUSH    ES
        PUSH    BX
        LES     BX,[CS:NULLDEVPT]
        OR      [ES:BX+SRHEAD.REQSTAT],STDON           ; Set done bit
        POP     BX
        POP     ES
        retf


;BREAK <AbsDRD, AbsDWRT -- INT int_disk_read, int_disk_write handlers>>


        IF      IBM
ERRIN:                                  ; Codes returned by BIOS
        DB      2                       ; NO RESPONSE
        DB      6                       ; SEEK FAILURE
        DB      12                      ; GENERAL ERROR
        DB      4                       ; BAD CRC
        DB      8                       ; SECTOR NOT FOUND
        DB      0                       ; WRITE ATTEMPT ON WRITE-PROTECT DISK
ERROUT:                                 ; DISK ERRORS RETURNED FROM INT 25 and 26
        DB      80H                     ; NO RESPONSE
        DB      40H                     ; Seek failure
        DB      2                       ; Address Mark not found
        DB      8                       ; DMA OVERRUN
        DB      4                       ; SECTOR NOT FOUND
        DB      3                       ; WRITE ATTEMPT TO WRITE-PROTECT DISK

NUMERR  =     $-ERROUT
        END IF

        procedure   ABSDRD,FAR
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING

        CLI
        MOV     [CS:user_SS],SS
        MOV     [CS:user_SP],SP
        PUSH    CS
        POP     SS
ASSUME  SS:DOSGROUP
        MOV     SP,DSKSTACK
        INC     BYTE [SS:INDOS]
        STI
        CLD
        PUSH    ES
        PUSH    DS
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        invoke  GETBP
        POP     DS
ASSUME  DS:NOTHING
        JC      ILEAVE
        invoke  DSKREAD
TLEAVE:
        JZ      ILEAVE

        IF      IBM
; Translate the error code to ancient 1.1 codes
        PUSH    ES
        PUSH    CS
        POP     ES
        XOR     AH,AH                   ; Nul error code
        MOV     CX,NUMERR               ; Number of possible error conditions
        MOV     DI,ERRIN   ; Point to error conditions
        REPNE   SCASB
        JNZ     LEAVECODE               ; Not found
        MOV     AH,[ES:DI+NUMERR-1]     ; Get translation
LEAVECODE:
        POP     ES
        END IF

        STC
ILEAVE:
        POP     ES
        CLI
        DEC     BYTE [SS:INDOS]
        MOV     SP,[SS:user_SP]
        MOV     SS,[SS:user_SS]
ASSUME  SS:NOTHING
        STI
        retf

        procedure   ABSDWRT,FAR
ASSUME  DS:NOTHING,ES:NOTHING,SS:NOTHING

        CLI
        MOV     [CS:user_SS],SS
        MOV     [CS:user_SP],SP
        PUSH    CS
        POP     SS
ASSUME  SS:DOSGROUP
        MOV     SP,DSKSTACK
        INC     BYTE [SS:INDOS]
        STI
        CLD
        PUSH    ES
        PUSH    DS
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        invoke    GETBP
        POP     DS
ASSUME  DS:NOTHING
        JC      ILEAVE
        invoke    DSKWRITE
        JMP     TLEAVE



        procedure   SYS_RETURN,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        entry   SYS_RET_OK
        call    get_user_stack
        PUSH    [SI+user_environ.user_F]
        POPF
        CLC
        JMP     SHORT DO_RET

        entry   SYS_RET_ERR
        XOR     AH,AH                   ; hack to allow for smaller error rets
        call    get_user_stack
        PUSH    [SI+user_environ.user_F]
        POPF
        STC
DO_RET:
        MOV     [SI+user_environ.user_AX],AX         ; Really only sets AH
        PUSHF
        POP     [SI+user_environ.user_F]             ; dump on his flags
        return

do_ext
