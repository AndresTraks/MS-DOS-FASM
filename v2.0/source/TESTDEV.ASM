; TITLE TESTDEV - an installable character device driver

; Nothing in the release is an installable device driver, so nothing here
; exercised the DEVICE= line in CONFIG.SYS or the device list DOS links a
; driver into.  This is the smallest driver that proves the whole path: it is
; a character device called TESTDEV whose write entry puts the bytes on the
; screen through the ROM, so
;
;       DEVICE=TESTDEV.SYS      in CONFIG.SYS
;       ECHO HELLO > TESTDEV    at the prompt
;
; printing HELLO says that SYSINIT found the line, loaded the file, called
; the driver's init, took its break address, linked the header into the
; device list, and that DOS then resolved the name and passed a write down to
; it.  tests/config.sh does exactly that.
;
; It writes through INT 10h rather than DOS because a driver cannot call DOS
; to do its own work, and at init time only a handful of calls are allowed.

        org     0

include 'DEVSYM.ASM'

        dd      -1                      ; the only driver in this file
        dw      DEVTYP                  ; a character device, nothing special
        dw      STRATEGY
        dw      INTERRUPT
        db      'TESTDEV '              ; eight characters, blank padded

PACKET  dd      0                       ; the request header STRATEGY is given

; DOS calls STRATEGY first and expects it only to remember the header.
STRATEGY:
        MOV     word [CS:PACKET],BX
        MOV     word [CS:PACKET+2],ES
        RETF

; Then it calls INTERRUPT, which does the work.  Everything is saved: DOS
; hands a driver no guarantees and wants none broken.
INTERRUPT:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        PUSH    BP
        PUSH    DS
        PUSH    ES
        CLD
        LES     BX,[CS:PACKET]
        MOV     AL,[ES:BX+SRHEAD.REQFUNC]
        CMP     AL,DEVINIT
        JZ      DO_INIT
        CMP     AL,DEVWRT
        JZ      DO_WRITE
        CMP     AL,DEVWRTV
        JZ      DO_WRITE
        CMP     AL,DEVRD
        JZ      DO_READ
        JMP     DONE                    ; the rest want nothing done

; Write: the count is at 18 and the address at 14, as in IO.ASM.
DO_WRITE:
        MOV     CX,[ES:BX+18]
        JCXZ    DONE
        LDS     SI,[ES:BX+14]
WRLOOP:
        LODSB
        CALL    PUTCH
        LOOP    WRLOOP
        JMP     DONE

; Read: there is nothing to read from this device, so no bytes come back.
DO_READ:
        MOV     word [ES:BX+18],0
        JMP     DONE

; Init: say so, claim no units, and tell DOS where the driver ends.
DO_INIT:
        MOV     SI,BANNER
        CALL    PUTSTR
        LES     BX,[CS:PACKET]
        MOV     byte [ES:BX+13],0
        MOV     word [ES:BX+14],ENDDRV
        MOV     word [ES:BX+16],CS
        JMP     DONE

DONE:
        LES     BX,[CS:PACKET]
        MOV     word [ES:BX+SRHEAD.REQSTAT],STDON
        POP     ES
        POP     DS
        POP     BP
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RETF

; CS:SI to the screen, to the first zero.
PUTSTR:
        MOV     AL,[CS:SI]
        INC     SI
        OR      AL,AL
        JZ      PUTSTR9
        CALL    PUTCH
        JMP     PUTSTR
PUTSTR9:
        RET

; AL to the screen.  The ROM is entitled to any register it likes.
PUTCH:
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    SI
        PUSH    DI
        PUSH    BP
        MOV     AH,0Eh                  ; teletype output
        MOV     BX,7                    ; page zero, the usual grey
        INT     10h
        POP     BP
        POP     DI
        POP     SI
        POP     DX
        POP     CX
        POP     BX
        RET

BANNER  db      13,10,'TESTDEV loaded',13,10,0
ENDDRV:
