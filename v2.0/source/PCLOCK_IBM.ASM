        TITLE   CLOCK - Enable/disable clock interrupts

; "CLOCK" module for MS-DOS profile program. This implements the
;       PROFIL program on the IBM PC
;
; PCLOCK.ASM beside this file is Microsoft's own, for the Seattle Computer
; Products 8086: an Am9513 timer at I/O F0h, counter 4 off a 400 kHz source,
; and a master and slave 8259 pair.  None of that is a PC.  PROFILE.DOC says
; the OEM writes this module for their own hardware, so here it is for this
; machine.  PROFIL.OBJ in the bin directory is the rest of the profiler,
; already assembled, and wants exactly three entry points from here.
;
; The PC has one counter the profiler can use, 8253 counter 0, and the ROM is
; already using it for the time of day.  CLOCKON takes it over and CLOCKOFF
; puts it back, both the divisor and the INT 8 vector, so the clock does not
; keep time while a profile is running -- the time of day will be behind
; afterwards by however long the run took.
;
; This file is MASM, not FASM, unlike the rest of the sources here: it has to
; be joined to PROFIL.OBJ, and LINK takes OMF objects, which FASM does not
; produce.  To build the profiler, on this very system once MASM.EXE and
; LINK.EXE are on the disk beside it:
;
;       MASM PCLOCK,PCLOCK,,;
;       LINK PROFIL PCLOCK
;
; the second answering each prompt with the default, which leaves PROFIL.EXE.
; Both have been run, on this DOS: MASM reports no warnings and no severe
; errors and writes PCLOCK.OBJ with a full listing, and LINK joins that to
; PROFIL.OBJ as a 2566 byte PROFIL.EXE needing no relocations, with nothing
; left unresolved.
;
; LINK does say "Warning: No STACK segment" and counts it as its one error.
; That is expected and not about this module: PROFIL sets SS and SP itself,
; which is why the header carries an SS:SP of 0000:0000.
;
; Running PROFIL.EXE is untried.  The code below is good MASM and it
; resolves, but whether it drives the counter and the 8259 correctly, and
; so whether the PRF file comes out meaning anything, is not yet shown.
;
; PROFILE.DOC describes what the profiler does, and PROHST reads the PRF
; file it writes.

INTSEG  SEGMENT AT 0
        ORG     8*4                     ;IRQ0, the counter 0 interrupt
INTVECTOR LABEL WORD
INTSEG  ENDS

CODE    SEGMENT BYTE PUBLIC

        PUBLIC  CLOCKON,CLOCKOFF,LEAVE_INT

        EXTRN   CLK_INTER:NEAR

        ASSUME  CS:CODE, DS:CODE, ES:CODE

TIMER0  =       40H                     ;8253 counter 0
TIMERCMD=       43H                     ;8253 control word
PIC     =       20H                     ;8259 command port
EOICMD  =       20H                     ;end of interrupt
RATEGEN =       34H                     ;counter 0, low then high, mode 2
SQUARE  =       36H                     ;counter 0, low then high, mode 3,
                                        ; which is how the ROM leaves it

;The counter counts at 1.193182 MHz, so the longest interval a sixteen bit
;divisor reaches is 65536 of those, and anything above that is clamped.
MAXUS   =       54925

;************************************************
;Enable clock and start generating clock interrupt.
;       Clock interval in micro seconds passed in DX
CLOCKON PROC    NEAR
        PUSH    DS
;
;Divisor is the interval times 1.193182, taken as times 1193 over 1000.
;PROFIL will not offer an interval below 60, so this cannot come out zero.
;
        CMP     DX,MAXUS
        JBE     HAVEUS
        MOV     DX,MAXUS
HAVEUS:
        MOV     AX,DX
        MOV     DX,1193
        MUL     DX                      ;DX:AX = microseconds * 1193
        MOV     BX,1000
        DIV     BX                      ;AX = divisor
        MOV     BX,AX                   ;keep it over the vector work
;
;Point the counter 0 interrupt at the profiler, keeping what was there.
;PROFIL has already disabled interrupts.
;
        XOR     AX,AX
        MOV     DS,AX
        ASSUME  DS:INTSEG
        MOV     AX,INTVECTOR
        MOV     CS:OLDOFF,AX
        MOV     AX,INTVECTOR+2
        MOV     CS:OLDSEG,AX
        MOV     INTVECTOR,OFFSET CLK_INTER
        MOV     INTVECTOR+2,CS
        ASSUME  DS:CODE
;
;And set it running at the rate asked for.
;
        MOV     AL,RATEGEN
        OUT     TIMERCMD,AL
        MOV     AL,BL
        OUT     TIMER0,AL
        MOV     AL,BH
        OUT     TIMER0,AL
        POP     DS
        RET
CLOCKON ENDP

;************************************************
;Disable clock and clock interrupt
CLOCKOFF PROC   NEAR
        PUSH    DS
;
;Give the ROM back the counter the way it had it: mode 3, and a count of
;zero, which the 8253 reads as 65536 and gives the usual 18.2 ticks a second.
;
        MOV     AL,SQUARE
        OUT     TIMERCMD,AL
        XOR     AL,AL
        OUT     TIMER0,AL
        OUT     TIMER0,AL
;
;And its own interrupt back.
;
        XOR     AX,AX
        MOV     DS,AX
        ASSUME  DS:INTSEG
        MOV     AX,CS:OLDOFF
        MOV     INTVECTOR,AX
        MOV     AX,CS:OLDSEG
        MOV     INTVECTOR+2,AX
        ASSUME  DS:CODE
        POP     DS
        RET
CLOCKOFF ENDP

;************************************************
;This routine is jumped to from the CLK_INTER
;       routine to perform and steps to reset the interrupt
;
;Counter 0 in mode 2 reloads itself, so unlike the Am9513 there is nothing
;to arm again -- only the 8259 to let go of the interrupt.
LEAVE_INT:
        PUSH    AX
        MOV     AL,EOICMD
        OUT     PIC,AL
        POP     AX
        IRET

OLDOFF  DW      ?                       ;the ROM's counter 0 interrupt
OLDSEG  DW      ?

CODE    ENDS
        END
