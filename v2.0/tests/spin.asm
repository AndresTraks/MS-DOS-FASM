; A program for the profiler to profile.
;
; PROFIL loads the program itself and gives it a program header it builds with
; function 26h, which does not make that header current, so a program that
; exits with function 4Ch goes back to COMMAND instead of to PROFIL: _EXIT in
; source/PROC.ASM takes the terminate address from CurrentPDB, which is still
; PROFIL's.  FIND, SORT and the other 2.0 utilities all exit that way, and
; profiling one of them leaves an empty .PRF.  That is PROFIL's own limitation
; and this program works within it, terminating the 1.x way through INT 20H.
;
; It also does no file I/O, and that matters more.  While a profile is running
; the clock module has counter 0 interrupting every few hundred microseconds
; instead of 18.2 times a second, and the ROM's INT 8, which counts the time
; of day and turns the floppy motor off, is not being called at all.  A
; program that reads a disk under that gets through it in the end but takes
; minutes about it, which is what this test used to spend on EXE2BIN; one that
; only uses the processor is done in a moment and gives the profiler the same
; thing to count.
;
; It spins in two places 256 bytes apart, which at the 16 paragraphs a bucket
; that tests/profila.txt asks for is one bucket apart.  So the .PRF has to
; come back with counts in two buckets and not one, and that is as much of
; CLK_INTER as there is to exercise: the sample window, the subtraction from
; PROG_LOW_PA, the divide by the bucket size and the index it makes of it.

        org     100H

        MOV     AH,9
        MOV     DX,RUNNING
        INT     21H

; The first bucket.  Each turn of the outer loop is a 65536 count, and the
; number of them is a guess at something a profile can see: a few dozen
; samples on the machine this was written on, more on a slower one, and the
; test asks for fewer than any of that.
        MOV     BX,128
FIRST:
        XOR     CX,CX
COUNT1:
        LOOP    COUNT1
        DEC     BX
        JNZ     FIRST
        JMP     SECOND

        times 256 - ($ - FIRST) DB 0    ; one bucket's worth of nothing

; The second bucket, the same again.
SECOND:
        MOV     BX,128
AGAIN:
        XOR     CX,CX
COUNT2:
        LOOP    COUNT2
        DEC     BX
        JNZ     AGAIN

        MOV     AH,9
        MOV     DX,FINISHED
        INT     21H
        INT     20H                     ;the 1.x exit, back into PROFIL

RUNNING   DB    "SPIN running",13,10,"$"
FINISHED  DB    "SPIN done",13,10,"$"
