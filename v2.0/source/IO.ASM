; I/O system for MS-DOS 2.0 on the IBM PC.
;
; SKELIO.ASM in this directory is the Microsoft skeleton, but it drives an
; Altos ACS-86C through that machine's ROM, so it is of no use here.  The
; device driver shape below is taken from it -- the headers, the strategy and
; interrupt pair, the dispatch tables and the request packet -- and the
; hardware underneath is the PC BIOS, as in the v1.25 IO.ASM.
;
; SYSINIT.ASM is assembled in behind this file, which is what the original
; build did by linking SYSINIT.OBJ after the BIOS.  SYSINIT.txt states what
; has to be handed to it, and HWINIT at the end of this file does so.

use16
org 0

BIOSSEG         equ 60h         ; where the boot sector puts this file
BIOSIZS         equ 200h        ; paragraphs reserved for it, so that the
                                ;  boot sector knows where MSDOS.SYS goes

; The disk geometry of the image create_image.sh builds.
SECTORS_PER_TRACK  equ 18
HEADS              equ 2
BYTES_PER_SECTOR   equ 512


INIT:   JMP     HWINIT

; ---------------------------------------------------------------------------
; Device headers.  The list order is the order DOS sees them in, and CON has
; to come first so that it can be found as the console.

label DEVSTART word
HDR_CON: DW      HDR_AUX,BIOSSEG
        DW      8003h                   ; character, console in and out
        DW      STRATEGY
        DW      CON_INT
        DB      "CON     "

HDR_AUX: DW      HDR_PRN,BIOSSEG
        DW      8000h
        DW      STRATEGY
        DW      AUX_INT
        DB      "AUX     "

HDR_PRN: DW      HDR_TIM,BIOSSEG
        DW      8000h
        DW      STRATEGY
        DW      PRN_INT
        DB      "PRN     "

HDR_TIM: DW      HDR_DSK,BIOSSEG
        DW      8008h                   ; character, and the CLOCK device
        DW      STRATEGY
        DW      TIM_INT
        DB      "CLOCK   "

HDR_DSK: DW      -1,-1                   ; last in the list
        DW      2000h                   ; block device
        DW      STRATEGY
        DW      DSK_INT
DRVMAX  DB      1                       ; one unit, drive A
        DB      7 dup (0)

; ---------------------------------------------------------------------------
; Dispatch tables, indexed by the command byte of the request packet.

DSKTBL: DW      DSK_INIT, MEDIAC, GET_BPB, CMDERR
        DW      DSK_RED, BUS_EXIT, EXIT, EXIT
        DW      DSK_WRT, DSK_WRV, EXIT, EXIT, EXIT

CONTBL: DW      EXIT, EXIT, EXIT, CMDERR
        DW      CON_READ, CON_RDND, EXIT, CON_FLSH
        DW      CON_WRIT, CON_WRIT, CON_WRST, EXIT, EXIT

AUXTBL: DW      EXIT, EXIT, EXIT, CMDERR
        DW      AUX_READ, AUX_RDND, EXIT, EXIT
        DW      AUX_WRIT, AUX_WRIT, AUX_WRST, EXIT, EXIT

TIMTBL: DW      EXIT, EXIT, EXIT, CMDERR
        DW      TIM_RED, BUS_EXIT, EXIT, EXIT
        DW      TIM_WRT, TIM_WRT, EXIT, EXIT, EXIT

PRNTBL: DW      EXIT, EXIT, EXIT, CMDERR
        DW      EXIT, BUS_EXIT, EXIT, EXIT
        DW      PRN_WRT, PRN_WRT, PRN_STA, EXIT, EXIT

; The request packet, as DEVSYM.ASM and SYSINIT's own PACKET lay it out.
P_CMDLEN  equ     0
P_UNIT    equ     1
P_CMD     equ     2
P_STATUS  equ     3
P_MEDIA   equ     13
P_TRANS   equ     14
P_COUNT   equ     18
P_START   equ     20
; and, for the init call only
P_UNITS equ     13
P_BREAK equ     14
P_BPB   equ     18

PTRSAV  DD      0


; ---------------------------------------------------------------------------
; Strategy and interrupt.  Nothing here is re-entrant, so the strategy call
; only records where the packet is and the interrupt call does the work.

STRATEGY:
        MOV     word [CS:PTRSAV],BX
        MOV     word [CS:PTRSAV+2],ES
        RETF

CON_INT:
        PUSH    SI
        MOV     SI,CONTBL
        JMP     DEV_ENTRY
AUX_INT:
        PUSH    SI
        MOV     SI,AUXTBL
        JMP     DEV_ENTRY
PRN_INT:
        PUSH    SI
        MOV     SI,PRNTBL
        JMP     DEV_ENTRY
TIM_INT:
        PUSH    SI
        MOV     SI,TIMTBL
        JMP     DEV_ENTRY
DSK_INT:
        PUSH    SI
        MOV     SI,DSKTBL

DEV_ENTRY:
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    BP
        PUSH    DS
        PUSH    ES
        PUSH    BX

        LDS     BX,[CS:PTRSAV]
        MOV     AL,[BX+P_UNIT]
        MOV     AH,[BX+P_MEDIA]
        MOV     CX,[BX+P_COUNT]
        MOV     DX,[BX+P_START]
        XCHG    DI,AX
        MOV     AL,[BX+P_CMD]
        XOR     AH,AH
        ADD     SI,AX
        ADD     SI,AX
        CMP     AL,12
        JA      CMDERR
        XCHG    AX,DI
        LES     DI,[BX+P_TRANS]
        PUSH    CS
        POP     DS
        JMP     word [SI]

BUS_EXIT:
        MOV     AH,00000011b            ; busy, and done
        JMP     SHORT EXIT1
CMDERR: MOV     AL,3                    ; unknown command
ERR_EXIT:
        MOV     AH,10000001b            ; error, and done
        JMP     SHORT EXIT1
EXIT:        MOV     AH,00000001b            ; done
EXIT1:  LDS     BX,[CS:PTRSAV]
        MOV     [BX+P_STATUS],AX
        POP     BX
        POP     ES
        POP     DS
        POP     BP
        POP     DI
        POP     DX
        POP     CX
        POP     AX
        POP     SI
        RETF

; ---------------------------------------------------------------------------
; Console, through the ROM BIOS.  Unlike the v1.25 I/O system this one does
; not take over INT 9: nothing here needs the scan codes before the ROM has
; them, and INT 16h already queues what is typed.

CON_READ:                               ; ES:DI = where to put CX characters
        JCXZ    CON_RDX
CON_RD1:
        CALL    CON_GET
        STOSB
        LOOP    CON_RD1
CON_RDX:
        JMP     EXIT

; One character.  A key with no ASCII arrives from the ROM as a zero and a
; scan code, which DOS reads as an escape sequence, so both bytes are passed
; on -- the second out of CON_PEND on the next call.
CON_GET:
        MOV     AL,[CS:CON_PEND]
        OR      AL,AL
        JZ      CON_GET1
        MOV     byte [CS:CON_PEND],0
        RET
CON_GET1:
        XOR     AH,AH
        INT     16h
        OR      AL,AL
        JNZ     CON_GET2
        MOV     [CS:CON_PEND],AH        ; hold the scan code for next time
CON_GET2:
        RET

CON_PEND DB     0

CON_RDND:                               ; look, without taking
        MOV     AL,[CS:CON_PEND]
        OR      AL,AL
        JNZ     CON_RDN2
        MOV     AH,1
        INT     16h
        JZ      BUS_EXIT                ; nothing there
        OR      AL,AL
        JNZ     CON_RDN2
        MOV     AL,0                    ; a zero comes first for an extended key
CON_RDN2:
        LDS     BX,[CS:PTRSAV]
        MOV     [BX+P_MEDIA],AL           ; the byte goes back in the packet
        PUSH    CS
        POP     DS
        JMP     EXIT

CON_FLSH:
        MOV     byte [CS:CON_PEND],0
CON_FL1:
        MOV     AH,1
        INT     16h
        JZ      CON_FL2
        XOR     AH,AH
        INT     16h
        JMP     SHORT CON_FL1
CON_FL2:
        JMP     EXIT

CON_WRIT:                               ; ES:DI = CX characters to show
        JCXZ    CON_WRX
CON_WR1:
        MOV     AL,[ES:DI]
        INC     DI
        CALL    CON_PUT
        LOOP    CON_WR1
CON_WRX:
        JMP     EXIT

CON_PUT:
        PUSH    BX
        MOV     AH,0Eh                  ; teletype output
        MOV     BX,7
        INT     10h
        POP     BX
        RET

CON_WRST:
        JMP     EXIT                    ; the screen is always ready

; ---------------------------------------------------------------------------
; Serial and printer, through the ROM as well.

AUX_READ:
        JCXZ    AUX_RDX
AUX_RD1:
        PUSH    DX
        XOR     DX,DX
        MOV     AH,2
        INT     14h
        POP     DX
        STOSB
        LOOP    AUX_RD1
AUX_RDX:
        JMP     EXIT

AUX_RDND:
        PUSH    DX
        XOR     DX,DX
        MOV     AH,3                    ; status
        INT     14h
        POP     DX
        TEST    AH,1                    ; data ready?
        JZ      BUS_EXIT
        PUSH    DX
        XOR     DX,DX
        MOV     AH,2
        INT     14h
        POP     DX
        JMP     CON_RDN2

AUX_CLR:
AUX_WRST:
        JMP     EXIT

AUX_WRIT:
        JCXZ    AUX_WRX
AUX_WR1:
        MOV     AL,[ES:DI]
        INC     DI
        PUSH    DX
        XOR     DX,DX
        MOV     AH,1
        INT     14h
        POP     DX
        LOOP    AUX_WR1
AUX_WRX:
        JMP     EXIT

PRN_WRT:
        JCXZ    PRN_WRX
PRN_WR1:
        MOV     AL,[ES:DI]
        INC     DI
        PUSH    DX
        XOR     DX,DX
        XOR     AH,AH
        INT     17h
        POP     DX
        TEST    AH,8                    ; I/O error?
        JNZ     PRN_ERR
        LOOP    PRN_WR1
PRN_WRX:
        JMP     EXIT
PRN_ERR:
        LDS     BX,[CS:PTRSAV]
        SUB     [BX+P_COUNT],CX           ; report what did go out
        PUSH    CS
        POP     DS
        MOV     AL,9                    ; out of paper
        JMP     ERR_EXIT

PRN_STA:
        JMP     EXIT

; ---------------------------------------------------------------------------
; The clock.  DOS reads and writes six bytes: days since 1-1-1980 as a word,
; then minutes, hours, hundredths and seconds.  The ROM counts ticks since
; midnight at 18.2 a second, and hands back a day-rollover flag.

TIM_RED:
        CALL    TIM_FETCH
        MOV     SI,TIM_DAYS
        MOV     CX,6
        PUSH    DS
        PUSH    CS
        POP     DS
        REP     MOVSB
        POP     DS
        JMP     EXIT

TIM_WRT:
        PUSH    ES
        PUSH    DI
        POP     SI
        POP     DS                      ; DS:SI = the six bytes from DOS
        MOV     DI,TIM_DAYS
        PUSH    ES
        PUSH    CS
        POP     ES
        MOV     CX,6
        REP     MOVSB
        POP     ES
        PUSH    CS
        POP     DS
        CALL    TIM_STORE
        JMP     EXIT

; Read the ROM tick count into TIM_DAYS..TIM_SECS.
TIM_FETCH:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        XOR     AH,AH
        INT     1Ah                     ; CX:DX = ticks, AL = day rollover
        OR      AL,AL
        JZ      TIM_F1
        XOR     AH,AH
        ADD     [CS:TIM_DAYS],AX        ; past midnight since we last looked
TIM_F1:
        MOV     AX,DX
        MOV     DX,CX                   ; DX:AX = ticks
        ; seconds = ticks * 10 / 182
        MOV     BX,10
        CALL    TIM_MUL32
        MOV     BX,182
        CALL    TIM_DIV32               ; DX:AX = seconds, BX = remainder
        MOV     CX,AX                   ; low word is enough: 86400 fits
        MOV     AX,CX
        XOR     DX,DX
        MOV     BX,60
        DIV     BX
        MOV     [CS:TIM_SECS],DL        ; seconds
        XOR     DX,DX
        DIV     BX
        MOV     [CS:TIM_MINS],DL        ; minutes
        MOV     [CS:TIM_HOUR],AL        ; hours
        MOV     byte [CS:TIM_HUND],0
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET

; Set the ROM tick count from TIM_DAYS..TIM_SECS.
TIM_STORE:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     AL,[CS:TIM_HOUR]
        XOR     AH,AH
        MOV     BX,60
        MUL     BX
        MOV     BL,[CS:TIM_MINS]
        XOR     BH,BH
        ADD     AX,BX
        MOV     BX,60
        MUL     BX                      ; DX:AX = seconds so far
        MOV     BL,[CS:TIM_SECS]
        XOR     BH,BH
        ADD     AX,BX
        ADC     DX,0
        MOV     BX,182
        CALL    TIM_MUL32
        MOV     BX,10
        CALL    TIM_DIV32               ; DX:AX = ticks
        MOV     CX,DX
        MOV     DX,AX
        MOV     AH,1
        INT     1Ah
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET

; DX:AX = DX:AX * BX, 8086 has no 32-bit multiply.
TIM_MUL32:
        PUSH    SI
        PUSH    AX
        MOV     AX,DX
        MUL     BX
        MOV     SI,AX                   ; high half, overflow discarded
        POP     AX
        MUL     BX
        ADD     DX,SI
        POP     SI
        RET

; DX:AX = DX:AX / BX, remainder in BX.
TIM_DIV32:
        PUSH    CX
        MOV     CX,AX
        MOV     AX,DX
        XOR     DX,DX
        DIV     BX                      ; high half
        PUSH    AX
        MOV     AX,CX
        DIV     BX                      ; low half, DX carried in
        MOV     BX,DX
        POP     DX
        POP     CX
        RET

TIM_DAYS DW     0
TIM_MINS DB     0
TIM_HOUR DB     0
TIM_HUND DB     0
TIM_SECS DB     0

; ---------------------------------------------------------------------------
; The disk, through INT 13h.

; Media check.  The packet wants -1 changed, 0 don't know, 1 not changed.
; There is no change line to read on this machine, so the honest answer is
; that we do not know, which makes DOS re-read the boot record.
MEDIAC:
        LDS     BX,[CS:PTRSAV]
        MOV     byte [BX+P_MEDIA+1],0
        PUSH    CS
        POP     DS
        JMP     EXIT

GET_BPB:
        LDS     BX,[CS:PTRSAV]
        MOV     word [BX+P_BPB],BPB
        MOV     [BX+P_BPB+2],CS
        PUSH    CS
        POP     DS
        JMP     EXIT

; The BIOS parameter block for the image create_image.sh builds.
BPB:    DW      BYTES_PER_SECTOR
        DB      1                       ; sectors per cluster
        DW      1                       ; reserved sectors
        DB      2                       ; FATs
        DW      224                     ; root directory entries
        DW      80*HEADS*SECTORS_PER_TRACK
        DB      0F0h                    ; media descriptor
        DW      9                       ; sectors per FAT

BPBTAB: DW      BPB                     ; one per unit

DSK_WRV:
DSK_WRT:
        MOV     byte [CS:DSKOP],3       ; INT 13h write
        JMP     SHORT DSK_GO
DSK_RED:
        MOV     byte [CS:DSKOP],2       ; INT 13h read
DSK_GO:
        ; AL = unit, CX = sectors, DX = first logical sector, ES:DI = buffer
        OR      AL,AL
        JNZ     DSK_UNIT
        JCXZ    DSK_DONE
        MOV     [CS:DSKCNT],CX
        MOV     [CS:DSKSEC],DX
        MOV     word [CS:DSKBUF],DI
        MOV     word [CS:DSKBUF+2],ES
DSK_NEXT:
        CMP     word [CS:DSKCNT],0
        JZ      DSK_DONE
        CALL    DSK_ONE
        JC      DSK_FAIL
        DEC     word [CS:DSKCNT]
        INC     word [CS:DSKSEC]
        ADD     word [CS:DSKBUF],BYTES_PER_SECTOR
        JMP     SHORT DSK_NEXT
DSK_DONE:
        JMP     EXIT
DSK_UNIT:
        MOV     AL,1                    ; unknown unit
        JMP     ERR_EXIT
DSK_FAIL:
        ; AH holds the ROM status; report what was transferred before it
        LDS     BX,[CS:PTRSAV]
        MOV     CX,[CS:DSKCNT]
        SUB     [BX+P_COUNT],CX
        PUSH    CS
        POP     DS
        MOV     AL,[CS:DSKERR]
        JMP     ERR_EXIT

; One sector, with the retries the ROM needs after a seek error.
DSK_ONE:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    ES
        MOV     AX,[CS:DSKSEC]
        XOR     DX,DX
        MOV     BX,SECTORS_PER_TRACK
        DIV     BX                      ; AX = track*heads + head, DX = sector-1
        MOV     CL,DL
        INC     CL                      ; sectors count from one
        XOR     DX,DX
        MOV     BX,HEADS
        DIV     BX                      ; AX = cylinder, DX = head
        MOV     CH,AL
        MOV     DH,DL
        MOV     DL,0                    ; drive A
        LES     BX,[CS:DSKBUF]
        MOV     AL,1                    ; one sector at a time, so a transfer
                                        ;  can never straddle a DMA page
        MOV     AH,[CS:DSKOP]
        MOV     SI,3                    ; the ROM wants three tries
DSK_TRY:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        INT     13h
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        JNC     DSK_OK
        MOV     [CS:DSKERR],AH
        PUSH    AX
        XOR     AX,AX
        INT     13h                     ; recalibrate and try again
        POP     AX
        DEC     SI
        JNZ     DSK_TRY
        STC
DSK_OK:
        POP     ES
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET

DSKOP   DB      2
DSKCNT  DW      0
DSKSEC  DW      0
DSKBUF  DD      0
DSKERR  DB      0

; Initialise.  The packet wants the unit count, the address this driver ends
; at -- everything above it is free for DOS -- and a pointer to an array of
; BPB pointers, one per unit.
DSK_INIT:
        LDS     BX,[CS:PTRSAV]
        MOV     byte [BX+P_UNITS],1
        MOV     word [BX+P_BREAK],BIOSEND
        MOV     [BX+P_BREAK+2],CS
        MOV     word [BX+P_BPB],BPBTAB
        MOV     [BX+P_BPB+2],CS
        PUSH    CS
        POP     DS
        JMP     EXIT

label BIOSEND byte

; ---------------------------------------------------------------------------
; Initialisation.  Everything from here on is overlaid once SYSINIT has moved
; the DOS down over it, so nothing below may be called afterwards.
;
; SYSINIT.txt: "The OEM has the following variables declared external:
; CURRENT_DOS_LOCATION ... the segment number of the DOS before it is
; relocated ... FINAL_DOS_LOCATION ... after SYSINIT moves it ... DEVICE_LIST
; ... points to the linked list of character and block device drivers ...
; MEMORY_SIZE ... the number of RAM paragraphs."

HWINIT:
        CLI
        XOR     BP,BP
        MOV     SS,BP
        MOV     SP,BIOSSEG*16           ; below this file, above the vectors
        STI
        PUSH    CS
        POP     DS
        PUSH    CS
        POP     ES

        MOV     AX,CS
        ADD     AX,BIOSIZS
        MOV     [CURRENT_DOS_LOCATION],AX   ; where the boot sector put the DOS

        MOV     AX,CS
        MOV     word [DEVICE_LIST+2],AX
        MOV     word [DEVICE_LIST],DEVSTART

        MOV     AX,CS
        ADD     AX,(BIOSEND+15)/16
        MOV     [FINAL_DOS_LOCATION],AX     ; the DOS lands on the init code

        INT     12h                     ; the ROM reports memory in KB
        MOV     CL,6
        SHL     AX,CL                   ; ... which is 64 paragraphs each
        MOV     [MEMORY_SIZE],AX

        CALL    TIM_FETCH               ; start the clock from the ROM's

        JMP     SYSINIT

        INCLUDE 'SYSINIT.ASM'
