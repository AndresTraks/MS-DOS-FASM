; the next segment defines a new class that MUST appear last in the link map.
; This defines several important locations for the initialization process that
; must be the first available locations of free memory.

SYSBUF:
ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

DOSINIT:
        CLI
        CLD
        MOV     [CS:ENDMEM],DX
        MOV     [CS:INITSP],SP
        MOV     [CS:INITSS],SS
        MOV     SP,INITSTACK
        MOV     AX,CS
        MOV     SS,AX
ASSUME  SS:DOSGROUP
        MOV     WORD [SS:DEVHEAD+2],DS
        MOV     WORD [SS:DEVHEAD],SI   ; DS:SI Points to CONSOLE Device
        CALL    CHARINIT

        mov al, '0'
	MOV	AH,0EH
	MOV	BH,0
	INT	10H

        PUSH    SI
        ADD     SI,SYSDEV.SDEVNAME             ; Point to name
        PUSH    CS
        POP     ES
ASSUME  ES:DOSGROUP
        MOV     DI,sftabl + sft.sft_table   ; Point to sft 0
        MOV     AL,3
        STOSB           ; Refcount
        DEC     AL
        STOSB           ; Access rd/wr
        XOR     AL,AL
        STOSB           ; Drive byte
        STOSB           ; attribute
        MOV     CX,4
        REP     MOVSW   ; Name
        MOV     CL,3
        MOV     AL," "
        REP     STOSB   ; Extension
        ADD     DI,12   ; Skip
        MOV     AL,0C0H OR ISCIN OR ISCOUT
        STOSB
        POP     SI
        MOV     AX,SI
        STOSW                   ; Device pointer in FIRCLUS
        MOV     AX,DS
        STOSW
        OR      BYTE [SI+SYSDEV.SDEVATT],ISCIN OR ISCOUT
        MOV     WORD [BCON],SI
        MOV     WORD [BCON+2],DS
CHAR_INIT_LOOP:
        LDS     SI,DWORD [SI]               ; AUX device
        CALL    CHARINIT
        TEST    BYTE [SI+SYSDEV.SDEVATT],ISCLOCK
        JZ      CHAR_INIT_LOOP
        MOV     WORD [BCLOCK],SI
        MOV     WORD [BCLOCK+2],DS
        MOV     BP,MEMSTRT      ; ES:BP points to DPB
PERDRV:
        mov al, '4'
	MOV	AH,0EH
	MOV	BH,0
	INT	10H
        LDS     SI,DWORD [SI]               ; Next device
        CMP     SI,-1
        JZ      CONTINIT
        CALL    CHARINIT
        TEST    [SI+SYSDEV.SDEVATT],DEVTYP
        JNZ     PERDRV                          ; Skip any other character devs
        MOV     CL,[CALLUNIT]
        XOR     CH,CH
        MOV     [SI+SYSDEV.SDEVNAME],CL                ; Number of units in name field
        MOV     DL,[NUMIO]
        XOR     DH,DH
        ADD     [NUMIO],CL
        PUSH    DS
        PUSH    SI
        LDS     BX,[CALLBPB]
PERUNIT:
        MOV     SI,[BX]                 ; DS:SI Points to BPB
        INC     BX
        INC     BX                      ; On to next BPB
        MOV     [ES:BP+dpb.dpb_drive],DL
        MOV     [ES:BP+dpb.dpb_UNIT],DH
        PUSH    BX
        PUSH    CX
        PUSH    DX
        invoke  SETDPB
        MOV     AX,[ES:BP+dpb.dpb_sector_size]
        CMP     AX,[MAXSEC]
        JBE     NOTMAX
        MOV     [MAXSEC],AX
NOTMAX:
        POP     DX
        POP     CX
        POP     BX
        MOV     AX,DS                   ; Save DS
        POP     SI
        POP     DS
        MOV     WORD [ES:BP+dpb.dpb_driver_addr],SI
        MOV     WORD [ES:BP+dpb.dpb_driver_addr+2],DS
        PUSH    DS
        PUSH    SI
        INC     DH
        INC     DL
        MOV     DS,AX
        ADD     BP,DPBSIZ
        LOOP    PERUNIT
        POP     SI
        POP     DS
        JMP     PERDRV

CONTINIT:
        PUSH    CS
        POP     DS
ASSUME  DS:DOSGROUP
; Calculate true address of buffers, FATs, free space
        MOV     DI,BP           ; First byte after current DPBs
        MOV     BP,[MAXSEC]
        MOV     AX,SYSBUF
        MOV     [BUFFSTRT],AX
        ADD     AX,BP           ; One I/O buffer
        ADD     AX,BUFINSIZ
        MOV     WORD [DPBHEAD],AX      ; True start of DPBs
        MOV     DX,AX
        SUB     DX,SYSBUF
        MOV     BP,DX
        ADD     BP,DI           ; Allocate buffer space
        SUB     BP,ADJFAC       ; True address of free memory
        PUSH    BP
        MOV     DI,MEMSTRT    ; Current start of DPBs
        ADD     DI,dpb.dpb_next_dpb      ; Point at dpb_next_dpb field
        MOV     CL,[NUMIO]
        XOR     CH,CH
TRUEDPBAD:
        ADD     AX,DPBSIZ       ; Compute address of next DPB
        STOSW                   ; Set the link to next DPB
        ADD     DI,DPBSIZ-2     ; Point at next address
        LOOP    TRUEDPBAD
        SUB     DI,DPBSIZ       ; Point at last dpb_next_dpb field
        MOV     AX,-1
        STOSW                   ; End of list
        ADD     BP,15           ;True start of free space (round up to segment)
        MOV     CL,4
        SHR     BP,CL           ; Number of segments for DOS resources
        MOV     DX,CS
        ADD     DX,BP           ; First free segment
        MOV     BX,0FH
        MOV     CX,[ENDMEM]

        IF      HIGHMEM
        SUB     CX,BP
        MOV     BP,CX           ; Segment of DOS
        MOV     DX,CS           ; Program segment
        END     IF

        IF      NOT HIGHMEM
        MOV     BP,CS
        END     IF

; BP has segment of DOS (whether to load high or run in place)
; DX has program segment (whether after DOS or overlaying DOS)
; CX has size of memory in paragraphs (reduced by DOS size if HIGHMEM)
        MOV     [ENDMEM],CX
        MOV     ES,BP
ASSUME  ES:DOSGROUP

        IF      HIGHMEM
        XOR     SI,SI
        MOV     DI,SI
        MOV     CX,SYSBUF  ;# bytes to move
        SHR     CX,1            ;# words to move (carry set if odd)
        REP MOVSW               ; Move DOS to high memory
        JNC     NOTODD
        MOVSB
NOTODD:
        END     IF

        MOV     WORD [ES:DSKCHRET+3],ES
        XOR     AX,AX
        MOV     DS,AX
        MOV     ES,AX
ASSUME  DS:NOTHING,ES:NOTHING
        MOV     DI,INTBASE+2
        MOV     AX,BP
        MOV     BYTE [DS:ENTRYPOINT],mi_Long_JMP
        MOV     WORD [DS:ENTRYPOINT+1],CALL_ENTRY
        MOV     WORD [DS:ENTRYPOINT+3],AX
        MOV     WORD [DS:0],DIVOV   ; Set default divide 
							; trap address
        MOV     [DS:2],AX
        MOV     CX,17
        REP STOSW               ; Set 9 segments (skip 2 between each)

        IF      ALTVECT
        MOV     DI,ALTBASE+2
        MOV     CX,15
        REP     STOSW           ; Set 8 segments (skip 2 between each)
        END     IF

        MOV     WORD [DS:addr_int_abort],QUIT
        MOV     WORD [DS:addr_int_command],COMMAND
        MOV     WORD [DS:addr_int_terminate],100H
        MOV     WORD [DS:addr_int_terminate+2],DX
        MOV     WORD [DS:addr_int_ctrl_c],_IRET   
							; Ctrl-C exit
        MOV     WORD [DS:addr_int_fatal_abort],_IRET
							; Fatal error exit
        MOV     WORD [DS:addr_int_disk_read],ABSDRD
							; INT 25
        MOV     WORD [DS:addr_int_disk_write],ABSDWRT
							; INT 26
        MOV     WORD [DS:addr_int_keep_process],Stay_resident
        MOV     WORD [DS:addr_int_spooler],_IRET  ; Spooler

        IF      NOT ALTVECT
        MOV     CX,12
        XOR     AX,AX
        MOV     DI,2AH*4
        REP     STOSW           ;Zero interrupt locs for ints 2AH-2FH
        END     IF

        PUSH    CS
        POP     DS
        PUSH    CS
        POP     ES
ASSUME  DS:DOSGROUP,ES:DOSGROUP
        MOV     AX,INITBLOCK
        ADD     AX,0Fh                  ; round to a paragraph
        MOV     CL,4
        SHR     AX,CL
        MOV     DI,DS
        ADD     DI,AX
        INC     DI
        MOV     [CurrentPDB],DI
        PUSH    BP
        PUSH    DX              ; Save COMMAND address
        MOV     AX,[ENDMEM]
        MOV     DX,DI

ASSUME  DS:NOTHING,ES:NOTHING
        invoke    SETMEM          ; Basic Header
        PUSH    CS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     DI,Process_data_block.PDB_JFN_Table
        XOR     AX,AX
        STOSW
        STOSB                   ; 0,1 and 2 are CON device
        MOV     AL,0FFH
        MOV     CX,FilPerProc - 3
        REP     STOSB           ; Rest are unused
        PUSH    CS
        POP     ES
ASSUME  ES:DOSGROUP
        MOV     WORD [sft_addr+2],DS     ; Must be set to print messages

; After this points the char device functions for CON will work for
; printing messages

        IF      IBM = 0
        IF      ALTVECT = 0
        MOV     SI,HEADER
        invoke  OUTMES
        PUSH    CS                      ; Outmes stomps on segments
        POP     DS
        PUSH    CS
        POP     ES
        END     IF
        END     IF

; Move the FATs into position
        POP     DX                      ; Restore COMMAND address
        POP     BP
        POP     CX                      ; True address of free memory
        MOV     SI,MEMSTRT      ; Place to move DPBs from
        MOV     DI,WORD [DPBHEAD]   ; Place to move DPBs to
        SUB     CX,DI                   ; Total length of DPBs
        CMP     DI,SI
        JBE     MOVJMP                  ; Are we moving to higher or 
					; lower memory?
        DEC     CX                      ; Move backwards to higher memory
        ADD     DI,CX
        ADD     SI,CX
        INC     CX
        STD
MOVJMP:
        MOV     ES,BP
        JMP     MOVDPB

CHARINIT:
ASSUME  DS:NOTHING,ES:NOTHING
; DS:SI Points to device header
        MOV     [SS:DEVCALL.REQLEN],DINITHL
        MOV     [SS:DEVCALL.REQUNIT],0
        MOV     [SS:DEVCALL.REQFUNC],DEVINIT
        MOV     [SS:DEVCALL.REQSTAT],0
        PUSH    ES
        PUSH    BX
        PUSH    AX
        MOV     BX,DEVCALL
        PUSH    CS
        POP     ES
        invoke  DEVIOCALL2
        POP     AX
        POP     BX
        POP     ES
        RET

        DB      80H DUP(?)
INITSTACK:
        DW      ?

MEMSTRT:
ADJFAC  =     MEMSTRT-SYSBUF
