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
        CLD                             ; DOS does not promise it clear
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
; then minutes, hours, hundredths and seconds.  The ROM's clock chip holds
; the date and the time of day, to the second, as packed BCD.

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

; Read the date and time out of the ROM's clock, as v1.25 reads it: function
; 4 for the date and function 2 for the time, packed BCD both, and carry set
; if it cannot be read, in which case leave what we had.  The chip keeps the
; time to the second and DOS wants hundredths as well, so those stay zero.
;
; DOS dates 1980 to 2099, and in that range a leap year is exactly one
; divisible by four.
TIM_FETCH:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        MOV     AH,4
        INT     1Ah
        JC      TIM_F9                  ; no clock to ask
        MOV     AL,DH
        CALL    TIM_BCD
        MOV     BL,AL                   ; the month
        MOV     AL,DL
        CALL    TIM_BCD
        MOV     BH,AL                   ; the day of the month
        MOV     AL,CH
        CALL    TIM_BCD
        MOV     DX,100
        MUL     DX                      ; the century, as a year
        MOV     SI,AX
        MOV     AL,CL
        CALL    TIM_BCD
        ADD     SI,AX                   ; SI = the year in full
        MOV     DX,BX                   ; DL = month, DH = day
        CMP     SI,1980
        JB      TIM_F9                  ; before the epoch, nothing to say
        CMP     DL,1
        JB      TIM_F9
        CMP     DL,12
        JA      TIM_F9                  ; a clock talking nonsense
        XOR     DI,DI
        MOV     AX,1980
TIM_F1:
        CMP     AX,SI
        JNB     TIM_F2
        ADD     DI,365
        TEST    AL,3                    ; every fourth year in this range
        JNZ     TIM_F1A
        INC     DI
TIM_F1A:
        INC     AX
        JMP     SHORT TIM_F1
TIM_F2:
        MOV     BL,DL
        XOR     BH,BH
        DEC     BX
        SHL     BX,1
        ADD     DI,[CS:TIM_MTAB+BX]     ; the months gone by this year
        CMP     DL,2
        JBE     TIM_F3
        TEST    SI,3
        JNZ     TIM_F3
        INC     DI                      ; February had 29 days this year
TIM_F3:
        MOV     AL,DH                   ; the day of the month, counting from 1
        XOR     AH,AH
        DEC     AX
        ADD     DI,AX
        MOV     [CS:TIM_DAYS],DI
        MOV     AH,2
        INT     1Ah
        JC      TIM_F9
        MOV     AL,CH
        CALL    TIM_BCD
        MOV     [CS:TIM_HOUR],AL
        MOV     AL,CL
        CALL    TIM_BCD
        MOV     [CS:TIM_MINS],AL
        MOV     AL,DH
        CALL    TIM_BCD
        MOV     [CS:TIM_SECS],AL
        MOV     byte [CS:TIM_HUND],0
TIM_F9:
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET

; Hand the date and time DOS has given us to the ROM's clock, so that reading
; it back says the same thing and it survives into the next boot.
TIM_STORE:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        MOV     AL,[CS:TIM_HOUR]
        CALL    TIM_BIN
        MOV     BH,AL
        MOV     AL,[CS:TIM_MINS]
        CALL    TIM_BIN
        MOV     BL,AL
        MOV     AL,[CS:TIM_SECS]
        CALL    TIM_BIN
        MOV     DH,AL
        MOV     CX,BX                   ; CH = hours, CL = minutes
        XOR     DL,DL                   ; standard time, not daylight saving
        MOV     AH,3
        INT     1Ah
;
; The date goes back the way it came in: count off the whole years, then the
; whole months, and what is left over is the day.
;
        MOV     DI,[CS:TIM_DAYS]
        XOR     SI,SI                   ; SI = years since 1980
TIM_S1:
        MOV     AX,365
        TEST    SI,3
        JNZ     TIM_S1A
        INC     AX
TIM_S1A:
        CMP     DI,AX
        JB      TIM_S2
        SUB     DI,AX
        INC     SI
        JMP     SHORT TIM_S1
TIM_S2:
        MOV     BX,11*2                 ; the last month that starts this early
TIM_S3:
        MOV     AX,[CS:TIM_MTAB+BX]
        CMP     BX,2*2
        JB      TIM_S4                  ; January and February are before it
        TEST    SI,3
        JNZ     TIM_S4
        INC     AX                      ; February had 29 days this year
TIM_S4:
        CMP     DI,AX
        JNB     TIM_S5
        SUB     BX,2
        JMP     SHORT TIM_S3
TIM_S5:
        SUB     DI,AX                   ; DI = the day, counting from zero
        SHR     BX,1
        INC     BX                      ; BX = the month, counting from one
        MOV     AX,SI
        ADD     AX,1980
        MOV     CL,100
        DIV     CL                      ; AL = century, AH = year within it
        PUSH    AX
        CALL    TIM_BIN
        MOV     CH,AL
        POP     AX
        MOV     AL,AH
        CALL    TIM_BIN
        MOV     CL,AL
        MOV     AL,BL
        CALL    TIM_BIN
        MOV     DH,AL                   ; the month
        MOV     AX,DI
        INC     AL
        CALL    TIM_BIN
        MOV     DL,AL                   ; the day
        MOV     AH,5
        INT     1Ah
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET

; AL = two packed BCD digits, back as AL = 0 to 99 with AH zero.  The shift
; goes through CL because an 8086 cannot shift by an immediate count.
TIM_BCD:
        PUSH    BX
        PUSH    CX
        MOV     BL,AL
        AND     BL,0Fh
        MOV     CL,4
        SHR     AL,CL
        MOV     CL,10
        MUL     CL
        ADD     AL,BL
        POP     CX
        POP     BX
        RET

; AL = 0 to 99, back as the two packed BCD digits the clock wants.
TIM_BIN:
        PUSH    CX
        AAM                             ; AH = tens, AL = ones
        MOV     CL,4
        SHL     AH,CL
        OR      AL,AH
        XOR     AH,AH
        POP     CX
        RET

; Days before the first of each month, in a year that is not a leap year.
TIM_MTAB DW     0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334
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
        ; Normalise the buffer address, because the walk below moves it a
        ; paragraph at a time rather than an offset at a time: DOS asks for
        ; a whole run of contiguous clusters in one request, which can span
        ; more than 64K, and adding 512 to the offset wraps it and reads
        ; back over the start of the buffer.
        MOV     AX,DI
        MOV     CL,4
        SHR     AX,CL
        AND     DI,000Fh
        MOV     word [CS:DSKBUF],DI
        MOV     CX,ES
        ADD     AX,CX
        MOV     word [CS:DSKBUF+2],AX
DSK_NEXT:
        CMP     word [CS:DSKCNT],0
        JZ      DSK_DONE
        CALL    DSK_ONE
        JC      DSK_FAIL
        DEC     word [CS:DSKCNT]
        INC     word [CS:DSKSEC]
        ADD     word [CS:DSKBUF+2],BYTES_PER_SECTOR/16
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
        PUSH    SI
        PUSH    DI
        PUSH    DS
        PUSH    ES
        ; Would this sector cross a 64K physical boundary?  The DMA
        ; controller cannot carry into its page register, so the ROM will
        ; not do such a transfer.  Going a sector at a time is not enough on
        ; its own: the caller's buffer need not sit on a 512-byte boundary
        ; within the page, and DOS hands over whatever address its buffer or
        ; the program being loaded happens to be at.  Those sectors go
        ; through DSKSBUF, which is low enough to be safe, and are copied.
        LES     BX,[CS:DSKBUF]
        MOV     AX,ES
        MOV     CL,4
        SHL     AX,CL                   ; low 16 bits of the physical address
        ADD     AX,BX
        MOV     byte [CS:DSKBNC],0
        CMP     AX,10000h-BYTES_PER_SECTOR
        JBE     DSK_ONE0
        MOV     byte [CS:DSKBNC],1
        CMP     byte [CS:DSKOP],3       ; a write has to be staged first
        JNZ     DSK_ONE0
        PUSH    CS
        POP     ES
        MOV     DI,DSKSBUF
        LDS     SI,[CS:DSKBUF]
        MOV     CX,BYTES_PER_SECTOR/2
        CLD
        REP     MOVSW
DSK_ONE0:
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
        CMP     byte [CS:DSKBNC],0
        JZ      DSK_ONE1
        PUSH    CS
        POP     ES
        MOV     BX,DSKSBUF
DSK_ONE1:
        MOV     AL,1                    ; one sector at a time, so that a
                                        ;  short transfer leaves the rest of
                                        ;  the request still to do
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
        JNC     DSK_GOOD
        MOV     [CS:DSKERR],AH
        PUSH    AX
        XOR     AX,AX
        INT     13h                     ; recalibrate and try again
        POP     AX
        DEC     SI
        JNZ     DSK_TRY
        STC
        JMP     SHORT DSK_OK
DSK_GOOD:
        CMP     byte [CS:DSKBNC],0      ; hand a bounced read on
        JZ      DSK_CLR
        CMP     byte [CS:DSKOP],3
        JZ      DSK_CLR
        PUSH    CS
        POP     DS
        MOV     SI,DSKSBUF
        LES     DI,[CS:DSKBUF]
        MOV     CX,BYTES_PER_SECTOR/2
        CLD
        REP     MOVSW
DSK_CLR:
        CLC                             ; the copy above dirties the flags
DSK_OK:
        POP     ES
        POP     DS
        POP     DI
        POP     SI
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
DSKBNC  DB      0                       ; this sector goes through DSKSBUF
DSKSBUF DB      BYTES_PER_SECTOR dup (0)

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
