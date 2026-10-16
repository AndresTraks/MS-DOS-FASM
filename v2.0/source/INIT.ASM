



; ENVIRONSIZ EQU  0A0H            ;Must agree with values in EVIRONMENT segment   [dropped: measured where it is defined with $]
; ENVIRONSIZ2 EQU 092H   [dropped: measured where it is defined with $]


if SEGSEL = S_CODERES

        IF      IBMVER
        END IF

end if


if SEGSEL = S_DATARES

        IF      IBMVER
        END IF

end if


if SEGSEL = S_ENVIRONMENT
end if


if SEGSEL = S_TRANCODE
end if


if SEGSEL = S_TRANSPACE
end if


; *******************************************************************
; START OF INIT PORTION
; This code is overlayed the first time the TPA is used.


if SEGSEL = S_INIT



ASSUME  CS:RESGROUP,DS:RESGROUP,ES:RESGROUP,SS:RESGROUP

ZERO    =       $

CONPROC:
        MOV     SP,RSTACK

        IF      HIGHMEM
        MOV     BX,word [DS:Process_data_block.PDB_block_len]
        MOV     AX,ENVIREND + 15
        MOV     CL,4
        SHR     AX,CL
        PUSH    AX                         ; Save size to alloc
        INC     AX                         ; Plus one for arena
        SUB     BX,AX                      ; Subtract size of resident
        MOV     word [DS:Process_data_block.PDB_block_len],BX
        MOV     AX,CS
        SUB     BX,AX
        MOV     AH,Setblock
        INT     21H
        POP     BX                          ; Get back size to alloc
        MOV     AH,Alloc
        INT     21H
        MOV     [REALRES],AX
        MOV     ES,AX
        XOR     SI,SI
        MOV     DI,SI
        MOV     CX,ENVIREND
        SHR     CX,1          ; Length of resident and environment in words
                              ; Last byte doesn't matter
        REP     MOVSW                   ; Move to end of memory
        MOV     DS,AX
        MOV     BX,AX
        MOV     AH,SET_CURRENT_PDB
        INT     21H
        MOV     AX,BX
        MOV     BX,DATARESEND + 15
        MOV     CL,4
        SHR     BX,CL           ; BX is size for SETBLOCK
        MOV     word [DS:Process_data_block.PDB_block_len],BX
        ADD     word [DS:Process_data_block.PDB_block_len],AX
        MOV     [LTPA],CS
        MOV     AH,Setblock
        INT     21H             ;Shrink to not include environment
        MOV     BX,(ENVIRONSIZ + 15) / 16
        MOV     AH,Alloc
        INT     21H             ;Allocate the environment
        MOV     [ENVIRSEG],AX
        MOV     [CS:ENVIRSEGSAV],AX
        MOV     ES,AX
ASSUME  ES:ENVIRONMENT
        XOR     DI,DI
        MOV     SI,PATHSTRING
        MOV     CX,ENVIRONSIZ
        REP     MOVSB
        MOV     AX,word [CS:Process_data_block.PDB_block_len]
        END IF

        IF HIGHMEM = 0
        MOV     AX,ENVIREND + 15
        MOV     CL,4
        SHR     AX,CL
        MOV     CX,CS
        ADD     AX,CX                         ; Compute segment of TPA
        MOV     [LTPA],AX                     ; Good enough for the moment
        MOV     AX,word [DS:Process_data_block.PDB_block_len]
        END IF

        MOV     [MYSEG1],DS
        MOV     [MYSEG2],DS
        MOV     [MYSEG],DS
        MOV     [MEMSIZ],AX

        MOV     DX,TRANSPACEEND + 15
        MOV     CL,4
        SHR     DX,CL

        IF      IBM
        PUSH    DX
        MOV     DX,ZEXECDATAEND + 15
        MOV     CL,4
        SHR     DX,CL
        POP     CX
        ADD     DX,CX
        END IF

        SUB     AX,DX
        MOV     [TRNSEG],AX                     ; Read it in here
        MOV     AX,[DS:Process_data_block.PDB_environ]
        OR      AX,AX
        JZ      BUILDENV                        ; Need to make an environment

        IF      HIGHMEM
        INC     byte [CS:CHUCKENV]          ; Flag no ENVIRONSEG
        ELSE
        INC     byte [CHUCKENV]             ; Flag no ENVIRONSEG
        END IF

        JMP     SHORT ENVIRONPASSED

BUILDENV:

        IF HIGHMEM = 0
        MOV     AX,PATHSTRING   ; Figure environment pointer
        MOV     CL,4
        SHR     AX,CL
        MOV     DX,DS
        ADD     AX,DX
        ELSE
        JMP     SHORT GOTTHEENVIR
        END IF

ENVIRONPASSED:
        MOV     [ENVIRSEG],AX

        IF      HIGHMEM
        DEC     AX
        MOV     ES,AX
        INC     AX
        MOV     [ES:arena.arena_owner],DS             ; Adjust owner of passed envir
        END IF

        MOV     ES,AX
ASSUME  ES:ENVIRONMENT

GOTTHEENVIR:
        MOV     AX,Char_Oper SHL 8
        INT     int_command
        MOV     [RSWITCHAR],DL

        CMP     DL,'/'
        JNZ     IUSESLASH

        IF      HIGHMEM
        MOV     [CS:COMSPECT],'\'
        ELSE
        MOV     [COMSPECT],'\'
        END IF

        IF      HIGHMEM
        CMP     byte [CS:CHUCKENV],0
        ELSE
        CMP     byte [CHUCKENV],0
        END IF

        JNZ     IUSESLASH

        MOV     [ES:ECOMSPEC-10H],'\'
IUSESLASH:

IF IBMVER
        PUSH    ES
        MOV     AX,(Get_Interrupt_Vector SHL 8) + int_command
        INT     int_command
        MOV     word [SYS_CALL],BX
        MOV     word [SYS_CALL+2],ES
        MOV     DX,SYSCALL_
        MOV     AX,(Set_Interrupt_Vector SHL 8) + int_command
        INT     int_command
        POP     ES
END IF

        MOV     AL,byte [DS:FCB]         ; get drive spec for default
        MOV     AH,DRVCHAR
        MOV     [COMDRV],AL
        ADD     AL,40H                  ; Convert to letter
        CMP     AL,40H
        JZ      NOCOMDRV
        STD
        IF      HIGHMEM
        CMP     byte [CS:CHUCKENV],0
        ELSE
        CMP     byte [CHUCKENV],0
        END IF

        JNZ     NOTWIDENV

        PUSH    DS
        PUSH    ES
        POP     DS
        MOV     DI,(ECOMSPEC - SEGBASE_ENVIRONMENT) + ENVIRONSIZ2 - 1 - 10H
        MOV     SI,(ECOMSPEC - SEGBASE_ENVIRONMENT) + ENVIRONSIZ2 - 3 - 10H
        MOV     CX,ENVIRONSIZ2 - 2
        REP     MOVSB

        POP     DS
        MOV     word [ES:ECOMSPEC-10H],AX

NOTWIDENV:
        CLD
        IF      HIGHMEM
        MOV     word [CS:AUTOBAT],AX
        ELSE
        MOV     word [AUTOBAT],AX
        END IF

        MOV     [COMLET],AL
NOCOMDRV:
        CALL    SETVECT         ; Set the vectors

        MOV     SI,80H
        LODSB
        MOV     CL,AL
        XOR     CH,CH
        JCXZ    COMRETURNSJ     ; No parameters
        MOV     SI,81H          ; Start of parms
CHKARG:
        LODSB
        CMP     AL,' '
        JZ      NEXTCH
        CMP     AL,9            ; Tab only other delimiter
        JZ      NEXTCH
        CMP     AL,[RSWITCHAR]   ; Switch?
        JNZ     CHKOTHERARGS    ; No
        DEC     CX
        JCXZ    ARGSDONEJ       ; oops
        LODSB
        OR      AL,20H          ; Lower case
        CMP     AL,'p'          ; PERMCOM switch
        JNZ     NEXTCH
        JMP     SETPERM

NEXTCH:
        CMP     AL,'d'
        JNZ     NEXTCH3

        IF      HIGHMEM
        MOV     byte [CS:PRDATTM],1  ; User explicitly says no date time
        ELSE
        MOV     byte [PRDATTM],1     ; User explicitly says no date time
        END IF

        LOOP    CHKARG
        JMP     SHORT ARGSDONEJ
NEXTCH3:
        CMP     AL,'c'
        JNZ     NEXTCH2         ; SINGLECOM switch 2
        MOV     [SINGLECOM],SI  ; Point to the rest of the command line
        MOV     [PERMCOM],0     ; A SINGLECOM must not be a PERMCOM

        IF      HIGHMEM
        MOV     byte [CS:PRDATTM],1  ; No date or time either, explicit
        ELSE
        MOV     byte [PRDATTM],1     ; No date or time either, explicit
        END IF

ARGSDONEJ:
        JMP  ARGSDONE

NEXTCH2:
        LOOP    CHKARG

COMRETURNSJ:
        JMP COMRETURNS

CHKOTHERARGS:
        DEC     SI
        MOV     DX,SI
        PUSH    CX
        PUSH    SI
CONTRLOOP:
        LODSB
        DEC     CX
        CMP     AL,' '
        JZ      SETCDEV
        CMP     AL,9
        JZ      SETCDEV
        JCXZ    SETCDEVA
        JMP     SHORT CONTRLOOP

SETCDEVA:
        INC     SI
SETCDEV:
        MOV     byte [SI-1],0
        MOV     AX,(Open SHL 8) OR 2    ; Read and write
        INT     int_command
        JC      CHKSRCHSPEC             ; Wasn't a file
        MOV     BX,AX
        MOV     AX,IOCtl SHL 8
        INT     int_command
        TEST    DL,80H
        JNZ     ISADEVICE
        MOV     AH,Close       ; Close initial handle, wasn't a device
        INT     int_command
        JMP     CHKSRCHSPEC

ISADEVICE:
        XOR     DH,DH
        OR      DL,3            ; Make sure has CON attributes
        MOV     AX,(IOCtl SHL 8) OR 1
        INT     int_command
        MOV     DX,BX           ; Save new handle
        POP     BX              ; Throw away saved SI
        POP     BX              ; Throw away saved CX
        PUSH    CX
        MOV     CX,3
        XOR     BX,BX
RCCLLOOP:                                ; Close 0,1 and 2
        MOV     AH,Close
        INT     int_command
        INC     BX
        LOOP    RCCLLOOP
        MOV     BX,DX           ; New device handle
        MOV     AH,XDup
        INT     int_command             ; Dup to 0
        MOV     AH,XDup
        INT     int_command             ; Dup to 1
        MOV     AH,XDup
        INT     int_command             ; Dup to 2
        MOV     AH,Close
        INT     int_command             ; Close initial handle
        POP     CX
        JCXZ    ARGSDONEJ2
        JMP     CHKARG

CHKSRCHSPEC:                    ; Not a device, so must be directory spec

        IF      HIGHMEM
        MOV     byte [CS:CHUCKENV],0    ; If search specified -- no inheritance
        MOV     AX,[CS:ENVIRSEGSAV]
        MOV     [ENVIRSEG],AX
        ELSE
        MOV     byte [CHUCKENV],0    ; If search specified -- no inheritance
        MOV     AX,PATHSTRING   ; Figure environment pointer
        MOV     CL,4
        SHR     AX,CL
        MOV     DX,DS
        ADD     AX,DX
        MOV     [ENVIRSEG],AX
        END IF

        MOV     ES,AX
        MOV     byte [SI-1],' '
        POP     SI                      ; Remember location
        POP     CX                      ; and count

        IF      HIGHMEM
        MOV     DI,[CS:ECOMLOC]
        ELSE
        MOV     DI,[ECOMLOC]
        END IF

COMTRLOOP:
        LODSB
        DEC     CX
        CMP     AL,' '
        JZ      SETCOMSR
        CMP     AL,9
        JZ      SETCOMSR
        STOSB

        IF      KANJI
        XOR     AH,AH
        END IF

        JCXZ    SETCOMSR

        IF      KANJI
        CALL    ITESTKANJ
        JZ      COMTRLOOP
        DEC     CX
        MOVSB
        INC     AH
        JCXZ    SETCOMSR
        END IF

        JMP     SHORT COMTRLOOP

SETCOMSR:
        PUSH    SI
        PUSH    CX

        PUSH    DS

        IF      HIGHMEM
        PUSH    CS
        POP     DS
        END IF

        MOV     SI,COMSPECT
        MOV     CX,14

        MOV     AL,[ES:DI-1]

        IF      KANJI
        OR      AH,AH
        JNZ     INOTROOT        ; Last char was KANJI second byte, might be '\'
        END IF

        CALL    PATHCHRCMPR
        JNZ     INOTROOT
        INC     SI              ; Don't make a double /
        DEC     CX
INOTROOT:
        REP     MOVSB

        MOV     DX,[ECOMLOC]    ; Now lets make sure its good!
        PUSH    ES
        POP     DS

        MOV     AX,Open SHL 8
        INT     int_command             ; Open COMMAND.COM
        POP     DS
        JC      SETCOMSRBAD     ; No COMMAND.COM here
        MOV     BX,AX           ; Handle
        MOV     AH,Close
        INT     int_command             ; Close COMMAND.COM
SETCOMSRRET:
        POP     CX
        POP     SI
ARGSDONEJ2:
        JCXZ    ARGSDONE
        JMP     CHKARG

SETCOMSRBAD:

        IF      HIGHMEM
        PUSH    DS
        PUSH    CS
        POP     DS
        END IF

        MOV     DX,BADCOMLKMES
        MOV     AH,Std_Con_String_Output
        INT     int_command
        MOV     SI,COMSPECT
        MOV     DI,[ECOMLOC]
        MOV     CX,14
        REP     MOVSB           ; Get my default back

        IF      HIGHMEM
        POP     DS
        END IF

        JMP     SHORT SETCOMSRRET

CHKARGJ:
        JMP    CHKARG

SETPERM:
        INC     [PERMCOM]

        IF      HIGHMEM
        CMP     byte [CS:PRDATTM],-1
        ELSE
        CMP     byte [PRDATTM],-1
        END IF

        JNZ     LOOPIT

        IF      HIGHMEM
        MOV     byte [CS:PRDATTM],0          ; If not set explicit, set to prompt
        ELSE
        MOV     byte [PRDATTM],0             ; If not set explicit, set to prompt
        END IF

LOOPIT:
        LOOP    CHKARGJ
ARGSDONE:
        CMP     [PERMCOM],0
        JZ      COMRETURNS
        PUSH    ES                      ; Save environment pointer
        MOV     AH,SET_CURRENT_PDB
        MOV     BX,DS
        MOV     ES,BX
        INT     int_command                     ; Current process is me
        MOV     DI,Process_data_block.PDB_Exit             ; Diddle the addresses in my header
        MOV     AX,LODCOM
        STOSW
        MOV     AX,DS
        STOSW
        MOV     AX,CONTC
        STOSW
        MOV     AX,DS
        STOSW
        MOV     word [DS:Process_data_block.PDB_Parent_PID],DS ; Parent is me forever
        MOV     DX,INT_2E
        MOV     AX,(Set_Interrupt_Vector SHL 8) OR 02EH
        INT     int_command                     ;Set magic interrupt
        POP     ES                              ;Remember environment
COMRETURNS:
        MOV     AX,word [DS:Process_data_block.PDB_Parent_PID]
        MOV     [PARENT],AX                     ; Save parent
        MOV     word [DS:Process_data_block.PDB_Parent_PID],DS ; Parent is me
        MOV     AX,word [DS:Process_data_block.PDB_JFN_Table]
        MOV     [IO_SAVE],AX                    ; Get the default stdin and out
        MOV     word [COM_PTR+2],DS         ; Set all these to resident
        MOV     word [COM_FCB1+2],DS
        MOV     word [COM_FCB2+2],DS
        MOV     DI,COMSPEC

        IF      HIGHMEM
        MOV     SI,[CS:ECOMLOC]
        CMP     byte [CS:CHUCKENV],0
        ELSE
        MOV     SI,[ECOMLOC]
        CMP     byte [CHUCKENV],0
        END IF

        MOV     AX,DS                   ; XCHG ES,DS
        PUSH    ES
        POP     DS
        MOV     ES,AX

        JZ      COPYCOMSP               ; All set up for copy

        PUSH    CS
        POP     DS

        MOV     SI,COMSPSTRING
        PUSH    ES
        PUSH    DI
        CALL    IFINDE
        MOV     SI,DI
        PUSH    ES
        POP     DS
        POP     DI
        POP     ES
        JNC     COPYCOMSP
COMSPECNOFND:

        IF      HIGHMEM
        MOV     DS,[CS:ENVIRSEG]
        MOV     SI,[CS:ECOMLOC]
        ELSE
        MOV     SI,[ECOMLOC]
        ADD     SI,PATHSTRING
        PUSH    CS
        POP     DS
        END IF

COPYCOMSP:
        LODSB
        STOSB
        OR      AL,AL
        JNZ     COPYCOMSP

        IF      HIGHMEM
        MOV     DS,[CS:REALRES]
        PUSH    CS
        POP     ES
        MOV     AH,Dealloc
        INT     21H
        CMP     byte [CS:CHUCKENV],0
        JZ      GOTENVIR                ; Environment is ok
        MOV     ES,[CS:ENVIRSEGSAV]
        MOV     AH,Dealloc
        INT     21H
        ELSE
        PUSH    CS
        POP     DS
        MOV     BX,DATARESEND + 15
        MOV     CL,4
        SHR     BX,CL
        MOV     AH,Setblock
        INT     int_command                     ; Shrink me to the resident only
        CMP     byte [CHUCKENV],0
        JNZ     GOTENVIR                ; Environment was passed
        MOV     BX,(ENVIRONSIZ + 15) /16
        MOV     AH,Alloc
        INT     int_command                     ; "ALLOCATE" the environment
        MOV     DS,[ENVIRSEG]
        MOV     [ENVIRSEG],AX
        MOV     ES,AX
        XOR     SI,SI
        MOV     DI,SI
        MOV     CX,ENVIRONSIZ
        REP     MOVSB
        PUSH    CS
        POP     DS
        END IF

GOTENVIR:
        CALL    LOADCOM                 ; Load the transient in the right place
        CALL    CHKSUM                  ; Compute the checksum
        MOV     [SUM],DX                ; Save it
IF IBM
        MOV     AX,[MEMSIZ]
        MOV     DX,ZEXECDATAEND + 15
        MOV     CL,4
        SHR     DX,CL
        SUB     AX,DX
        MOV     [EXESEG],AX
        CALL    EXECHK
        MOV     [EXESUM],DX
END IF
        IF MSVER
        CMP     [SINGLECOM],0
        JNZ     NOPHEAD                 ; Don't print header if SINGLECOM
        IF      HIGHMEM
        PUSH    DS
        PUSH    CS
        POP     DS
        END IF
        MOV     DX,HEADER
        MOV     AH,Std_Con_String_Output
        INT     int_command
        IF      HIGHMEM
        POP     DS
        END IF
NOPHEAD:
        END IF

        IF      HIGHMEM
        CMP     byte [CS:PRDATTM],0
        ELSE
        CMP     byte [PRDATTM],0
        END IF

        JNZ     NODTTM                  ; Don't do AUTOEXEC or date time
        MOV     BX,3                    ; 48 BYTES ENOUGH
        MOV     AH,Alloc
        INT     int_command
        JC      DODTTM                  ; PRETEND NO BATCH
        MOV     [BATCH],AX
        MOV     ES,AX
        XOR     DI,DI

        IF      HIGHMEM
        CMP     byte [CS:AUTOBAT],0
        ELSE
        CMP     byte [AUTOBAT],0
        END IF

        JNZ     NOAUTSET
        MOV     AH,Get_Default_Drive
        INT     int_command
        ADD     AL,'A'

        IF      HIGHMEM
        MOV     [CS:AUTOBAT],AL
        ELSE
        MOV     [AUTOBAT],AL
        END IF

NOAUTSET:

        IF      HIGHMEM
        PUSH    DS
        PUSH    CS
        POP     DS
        END IF

        MOV     SI,AUTOBAT
        MOV     CX,8
        REP     MOVSW   ; NAME
        MOV     AX,-1
        MOV     CL,10
        REP     STOSW   ; PARMS
        MOV     DX,AUTOBAT
        MOV     AX,Open SHL 8
        INT     int_command                      ; See if AUTOEXEC.BAT exists
        JC      NOABAT
        MOV     BX,AX
        MOV     AH,Close
        INT     int_command

        IF      HIGHMEM
        POP     DS
        END IF

        JMP     SHORT DRV0

NOABAT:

        IF      HIGHMEM
        POP     DS
        END IF

        MOV     ES,[BATCH]      ; Not found--turn off batch job
        MOV     AH,Dealloc
        INT     int_command
        MOV     [BATCH],0       ; AFTER DEALLOC in case of ^C
DODTTM:

        IF      HIGHMEM
        MOV     AX,DATINIT
        MOV     word [CS:INITADD],AX
        MOV     AX,[TRNSEG]
        MOV     word [CS:INITADD+2],AX
        CALL    dword [CS:INITADD]
        ELSE
        MOV     AX,DATINIT
        MOV     word[INITADD],AX
        MOV     AX,[TRNSEG]
        MOV     word[INITADD+2],AX
        CALL    dword [INITADD]
        END IF

NODTTM:

        IF IBMVER
        CMP     [SINGLECOM],0
        JNZ     DRV0                    ; Don't print header if SINGLECOM
        MOV     DX,HEADER
        MOV     AH,Std_Con_String_Output
        INT     int_command
        END IF

DRV0:
        IF      HIGHMEM
        PUSH    DS
        MOV     AX,LODCOM
        PUSH    AX
        procedure   MQQ,FAR
        RETF
        ELSE
        JMP     LODCOM                  ; Allocate the transient
        END IF

PATHCHRCMPR:
        CMP     [RSWITCHAR],'/'
        JZ      RNOSLASHT
        CMP     AL,'/'
        JZ      RET41
RNOSLASHT:
        CMP     AL,'\'
RET41:
        RET


IFINDE:
        CALL    IFIND                    ; FIND THE NAME
        JC      IFIND2                   ; CARRY MEANS NOT FOUND
        JMP     ISCASB1                  ; SCAN FOR = SIGN
;
; On return of FIND1, ES:DI points to beginning of name
;
IFIND:
        CLD

        CALL    ICOUNT0                  ; CX = LENGTH OF NAME

        IF      HIGHMEM
        MOV     ES,[CS:REALRES]
ASSUME  ES:RESGROUP
        MOV     ES,[ES:ENVIRSEG]
ASSUME  ES:NOTHING
        ELSE
        MOV     ES,[ENVIRSEG]
        END IF

        XOR     DI,DI
IFIND1:
        PUSH    CX
        PUSH    SI
        PUSH    DI
IFIND11:
        LODSB

        IF      KANJI
        CALL    ITESTKANJ
        JZ      NOTKANJ4
        DEC     SI
        LODSW
        INC     DI
        INC     DI
        CMP     AX,[ES:DI-2]
        JNZ     IFIND12
        DEC     CX
        LOOP    IFIND11
        JMP     SHORT IFIND12

NOTKANJ4:
        END IF

        CALL    IUPCONV
        INC     DI
        CMP     AL,[ES:DI-1]
        JNZ     IFIND12
        LOOP    IFIND11
IFIND12:
        POP     DI
        POP     SI
        POP     CX
        JZ      IFIND2
        PUSH    CX
        CALL    ISCASB2                  ; SCAN FOR A NUL
        POP     CX
        CMP     byte [ES:DI],0
        JNZ     IFIND1
        STC                             ; INDICATE NOT FOUND
IFIND2:
        RET

ICOUNT0:
        PUSH    DS
        POP     ES
        MOV     DI,SI

        PUSH    DI                      ; COUNT NUMBER OF CHARS UNTIL "="
        CALL    ISCASB1
        JMP     SHORT ICOUNTX
        PUSH    DI                      ; COUNT NUMBER OF CHARS UNTIL NUL
        CALL    ISCASB2
ICOUNTX:
        POP     CX
        SUB     DI,CX
        XCHG    DI,CX
        RET

ISCASB1:
        MOV     AL,"="                  ; SCAN FOR AN =
        JMP     SHORT ISCASBX
ISCASB2:
        XOR     AL,AL                   ; SCAN FOR A NUL
ISCASBX:
        MOV     CX,100H
        REPNZ   SCASB
        RET

        IF      KANJI
ITESTKANJ:
        CMP     AL,81H
        JB      NOTLEAD
        CMP     AL,9FH
        JBE     ISLEAD
        CMP     AL,0E0H
        JB      NOTLEAD
        CMP     AL,0FCH
        JBE     ISLEAD
NOTLEAD:
        PUSH    AX
        XOR     AX,AX           ;Set zero
        POP     AX
        RET

ISLEAD:
        PUSH    AX
        XOR     AX,AX           ;Set zero
        INC     AX              ;Reset zero
        POP     AX
        RET
        END IF

IUPCONV:
        CMP     AL,"a"
        JB      IRET22
        CMP     AL,"z"
        JA      IRET22
        SUB     AL,20H          ; Lower-case changed to upper-case
IRET22:
        RET

label ICONDEV byte
        DB      "/DEV/"
        DB      "CON",0,0,0,0,0,0          ; Room for 8 char device
BADCSPFL DB     0
COMSPECT DB     "/COMMAND.COM",0,0
AUTOBAT DB      0,":\AUTOEXEC.BAT",0

PRDATTM DB      -1                      ;Init not to prompt for date time
INITADD DD      ?
CHUCKENV DB     0
ECOMLOC DW      (ECOMSPEC - SEGBASE_ENVIRONMENT)-10H

        IF      HIGHMEM
REALRES DW      ?
ENVIRSEGSAV DW  ?
        END IF

COMSPSTRING DB  "COMSPEC="


end if

