; TITLE MSINIT.ASM -- MS-DOS INITIALIZATION CODE

; Init code below overlaps with data area

INITBLOCK DB    110H DUP(0)     ; Allow for segment round up

INITSP  DW      ?
INITSS  DW      ?
BUFFSTRT DW     ?

ASSUME  CS:DOSGROUP,DS:DOSGROUP,ES:DOSGROUP,SS:NOTHING

MOVDPB:
; This section of code is safe from being overwritten by block move
        MOV     SP,[CS:INITSP]
        MOV     SS,[CS:INITSS]
        REP     MOVS    BYTE [DI],[SI]
        CLD
        MOV     WORD [ES:DMAADD+2],DX
        MOV     SI,WORD [DPBHEAD]   ; Address of first DPB
        MOV     WORD [ES:DPBHEAD+2],ES
        MOV     WORD [ES:sft_addr+2],ES
        MOV     CL,[NUMIO]      ; Number of DPBs
        XOR     CH,CH
SETFINDPB:
        MOV     WORD [ES:SI+dpb.dpb_next_dpb+2],ES
        MOV     [ES:SI+dpb.dpb_first_access],-1      ; Never accessed before
        ADD     SI,DPBSIZ       ; Point to next DPB
        LOOP    SETFINDPB
        SUB     SI,DPBSIZ
        MOV     WORD [ES:SI+dpb.dpb_next_dpb+2],-1
        MOV     DI,[BUFFSTRT]                   ; Set up one default buffer
        MOV     WORD [ES:BUFFHEAD+2],ES
        MOV     WORD [ES:BUFFHEAD],DI
        MOV     WORD [ES:DI+BUFFINFO.BUFDRV],00FFH
        MOV     [ES:DI+BUFFINFO.BUFPRI],FREEPRI
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF],-1
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF+2],-1
        PUSH    ES
        INC     DX                          ; Leave enough room for the ARENA
        MOV     BYTE [CreatePDB],0FFh   ; create jfns and set CurrentPDB
        invoke  _CREATE_PROCESS_DATA_BLOCK     ; Set up segment
ASSUME  DS:NOTHING,ES:NOTHING
        POP     ES
ASSUME  ES:DOSGROUP

;
; set up memory arena
;SPECIAL NOTE FOR HIGHMEM VERSION
; At this point a process header has been built where the start of the 
; CONSTANTS segment as refed by CS is. From this point until the return 
; below be careful about references off of CS.
;
        PUSH    AX
        MOV     AX,[CS:CurrentPDB]
        MOV     [ES:CurrentPDB],AX         ; Put it in the REAL location
        MOV     BYTE [ES:CreatePDB],0h ; reset flag in REAL location
        DEC     AX
        MOV     [ES:arena_head],AX
        PUSH    DS
        MOV     DS,AX
        MOV     [DS:arena.arena_signature],arena_signature_end
        MOV     [DS:arena.arena_owner],arena_owner_system
        SUB     AX,[ES:ENDMEM]
        NEG     AX
        DEC     AX
        MOV     [DS:arena.arena_size],AX
        POP     DS
        POP     AX

        MOV     DI,sftabl + sft.sft_table   ; Point to sft 0
        MOV     AL,3
        STOSB           ; Adjust Refcount
        MOV     DI,SYSINITVAR

        RETF
