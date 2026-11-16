
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
; puts it back, both the divisor and the INT 8 vector, so the ROM stops
; counting ticks for as long as a profile runs, so anything reading INT 1Ah
; function 0 sees time stand still, and stay that far behind afterwards.
;
; This file was MASM until PROFIL.ASM was converted, and had to be: it is
; joined to PROFIL, which was only ever an object file, and LINK takes OMF
; objects, which FASM does not produce.  So the profiler was built on the
; system under test --
;
;       MASM PCLOCK,PCLOCK,,;
;       LINK PROFIL+PCLOCK,PROFIL,,;
;       EXE2BIN PROFIL PROFIL.COM
;
; -- nine minutes of MASM and LINK on a floppy, which is what tests/profil.sh
; used to spend before it could run anything.  With both modules in FASM there
; is nothing left to link and assemble.sh builds the .COM; source/PROLINK.ASM
; lays the segments out and says what the result was held against.
;
; The EXE2BIN step was not optional, and the reason it was not is still the
; reason this is a .COM.  PROFIL is assembled ORG 100H with DS the same as CS
; and reads its argument from the default FCB at 5CH, so it only works when DS
; is its own program header.  Run as an .EXE it is loaded 16 paragraphs above
; the header, DS:5CH lands in the 256 byte hole at the front of its own image,
; and it opens whatever garbage it finds there -- "File not found" every time.
; Worse, it then quits through INT 20h, and _ABORT takes the terminate
; addresses from CS:0A, which is that same hole, so it fills vectors 22h, 23h
; and 24h with zeros and jumps to 0000:0000.
;
; tests/profil.sh runs the profiler on EXE2BIN.EXE at a 100 microsecond sample
; interval and reads the EXE2BIN.PRF that comes out.  How many samples it holds
; depends on how fast the host emulating this machine is; one run held 922 --
; 56 in the I/O system, 842 in the DOS, 13 above the program and 11 in buckets
; 0 and 1.  So the counter runs at the rate asked for, the interrupt arrives,
; LEAVE_INT's EOI lets the next one through, and CLOCKOFF puts the clock back
; well enough that DOS carries on afterwards.
;
; PROFILE.DOC describes what the profiler does, and PROHST reads the PRF
; file it writes.

if SEGSEL = S_CODE
virtual at 0
        ORG     8*4                     ;IRQ0, the counter 0 interrupt
label INTVECTOR word
end virtual
end if

if SEGSEL = S_CODE



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
CLOCKON:
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
        MOV     AX,[INTVECTOR]
        MOV     [CS:OLDOFF],AX
        MOV     AX,[INTVECTOR+2]
        MOV     [CS:OLDSEG],AX
        MOV     [INTVECTOR],CLK_INTER
        MOV     [INTVECTOR+2],CS
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

;************************************************
;Disable clock and clock interrupt
CLOCKOFF:
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
        MOV     AX,[CS:OLDOFF]
        MOV     [INTVECTOR],AX
        MOV     AX,[CS:OLDSEG]
        MOV     [INTVECTOR+2],AX
        ASSUME  DS:CODE
        POP     DS
        RET

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

OLDOFF  DW      0;the ROM's counter 0 interrupt
OLDSEG  DW      0

end if
