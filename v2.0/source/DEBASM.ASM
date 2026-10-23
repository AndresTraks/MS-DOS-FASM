
; Code for the ASSEMble command in the debugger

        INCLUDE 'DEBEQU.ASM'


if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST


end if

if SEGSEL = S_DATA


end if



if SEGSEL = S_CODE
ASSUME  CS:DG,DS:DG,ES:DG,SS:DG



;
;       Line by line assembler
;

ASSEM:
        MOV     BP,[CSSAVE]             ; Default code segment
        MOV     DI,ASMADD     ; Default address
        CALL    DEFAULT
        MOV     word [ASMADD],DX    ; Displacement of disassembly
        MOV     word [ASMADD+2],AX  ; Segment
        MOV     [ASMSP],SP              ; Save sp in case of error

ASSEMLOOP:
        MOV     SP,[ASMSP]              ; Restore sp in case of error
        LES     DI,dword [ASMADD]     ; GET PC
        CALL    OUTDI                   ; OUTPUT ADDRESS
        CALL    BLANK                   ; SKIP A SPACE
        PUSH    CS
        POP     ES
        CALL    INBUF                   ; GET A BUFFER
        CALL    SCANB
        JNZ     OPLOOK
        RET                             ; IF EMPTY JUST RETURN
;
;  At this point ds:si points to the opcode mnemonic...
;
OPLOOK: XOR     CX,CX                   ; OP-CODE COUNT = 0
        MOV     DI,DBMN
OPSCAN: XOR     BX,BX
OPLOOP: MOV     AL,[DI+BX]
        AND     AL,7FH
        CMP     AL,[SI+BX]
        JZ      OPMATCH
        INC     CX                      ; INCREMENT OP-CODE COUNT
        CMP     CX,MAXOP                ; CHECK FOR END OF LIST
        JB      OP1
        JMP     ASMERR
OP1:    INC     DI                      ; SCAN FOR NEXT OP-CODE...
        TEST    byte [DI-1],80H
        JZ      OP1
        JMP     OPSCAN

OPMATCH:INC     BX                      ; COMPARE NEXT CHAR
        TEST    byte [DI+BX-1],80H  ; ARE WE DONE?
        JZ      OPLOOP                  ; ..IF NOT KEEP COMPARING
        XCHG    BX,CX
        MOV     AX,BX
        SHL     AX,1
        ADD     AX,BX
        ADD     AX,OPTAB
        MOV     BX,AX
;
; CX = COUNT OF CHARS IN OPCODE
; BX = POINTER INTO OPCODE TABLE
;
        XOR     AX,AX
        MOV     byte [AWORD],AL
        MOV     word [MOVFLG],AX    ; MOVFLG + TSTFLG
        MOV     byte [SEGFLG],AL    ; ZERO SEGMENT REGISTER FLAG
        MOV     AH,00001010B            ; SET UP FOR AA_OPER
        MOV     AL,byte [BX]
        MOV     word [ASSEM1],AX
        MOV     byte [ASSEM_CNT],1

        ADD     SI,CX                   ; SI POINTS TO OPERAND
        JMP     word [BX+1]
;
; 8087 INSTRUCTIONS WITH NO OPERANDS
;
FDE_OPER:
        MOV     AH,0DEH
        JMP     SHORT FDX_OPER
FDB_OPER:
        MOV     AH,0DBH
        JMP     SHORT FDX_OPER
FD9_OPER:
        MOV     AH,0D9H
FDX_OPER:
        XCHG    AL,AH
        MOV     word [ASSEM1],AX
;
;  aad and aam instrucions
;
AA_OPER:INC     byte [ASSEM_CNT]
;
;  instructions with no operands
;
NO_OPER:
        CALL    STUFF_BYTES
        CALL    SCANP
        PUSH    CS
        POP     ES
        JNZ     OPLOOK
        JMP     ASSEMLOOP
;
;  push instruction
;
PUSH_OPER:
        MOV     AH,11111111B
        JMP     SHORT POP1
;
;  pop instruction
;
POP_OPER:
        MOV     AH,10001111B
POP1:   MOV     [ASSEM1],AH
        MOV     [MIDFLD],AL
        INC     byte [MOVFLG]       ; ALLOW SEGMENT REGISTERS
        MOV     byte [AWORD],2      ; MUST BE 16 BITS
        CALL    GETREGMEM
        CALL    BUILDIT
        MOV     AL,[DI+2]
        CMP     AL,11000000B
        JB      DATRET
        MOV     byte [DI],1
        CMP     byte [MOVFLG],2
        JNZ     POP2
        AND     AL,00011000B
        OR      AL,00000110B
        CMP     byte [MIDFLD],0
        JNZ     POP3
        OR      AL,00000001B
        JMP     SHORT POP3

POP2:   AND     AL,111B
        OR      AL,01010000B
        CMP     byte [MIDFLD],0
        JNZ     POP3
        OR      AL,01011000B
POP3:   MOV     byte [DI+1],AL
        JMP     ASSEM_EXIT
;
; ret and retf instructions
;
GET_DATA16:
        CALL    SCANB
        MOV     CX,4
        CALL    GETHX
        JC      DATRET
        DEC     byte [ASSEM1]       ; CHANGE OP-CODE
        ADD     byte [ASSEM_CNT],2  ; UPDATE LENGTH
        MOV     word [ASSEM2],DX    ; SAVE OFFSET
DATRET: JMP     ASSEM_EXIT
;
;  int instruction
;
INT_OPER:
        CALL    SCANB
        MOV     CX,2
        CALL    GETHX
        JC      ERRV1
        MOV     AL,DL
        CMP     AL,3
        JZ      DATRET
        INC     byte [ASSEM1]
        JMP     DISPX
;
;  in instruction
;
IN_OPER:
        CALL    SCANB
        LODSW
        CMP     AX,"A"+4C00H            ; "AL"
        JZ      IN_1
        CMP     AX,"A"+5800H            ; "AX"
        JZ      IN_0
ERRV1:  JMP     ASMERR
IN_0:   INC     byte [ASSEM1]
IN_1:   CALL    SCANP
        CMP     word [SI],"D"+5800H ; "DX"
        JZ      DATRET
        MOV     CX,2
        CALL    GETHX
        JC      ERRV1
        AND     byte [ASSEM1],11110111B
        MOV     AL,DL
        JMP     DISPX
;
;  out instruction
;
OUT_OPER:
        CALL    SCANB
        CMP     word [SI],"D"+5800H ; "DX"
        JNZ     OUT_0
        INC     SI
        INC     SI
        JMP     SHORT OUT_1
OUT_0:  AND     byte [ASSEM1],11110111B
        MOV     CX,2
        CALL    GETHX
        JC      ERRV1
        INC     byte [ASSEM_CNT]
        MOV     byte [ASSEM2],DL
OUT_1:  CALL    SCANP
        LODSW
        CMP     AX,"A"+4C00H            ; "AL"
        JZ      DATRET
        CMP     AX,"A"+5800H            ; "AX"
        JNZ     ERRV1
        INC     byte [ASSEM1]
        JMP     DATRET

;
;  jump instruction
;
JMP_OPER:
        INC     byte [TSTFLG]
;
;  call instruction
;
CALL_OPER:
        MOV     byte [ASSEM1],11111111B
        MOV     byte [MIDFLD],AL
        CALL    GETREGMEM
        CALL    BUILD3
        CMP     byte [MEMFLG],0
        JNZ     CALLJ1
        CMP     byte [REGMEM],-1
        JZ      CALLJ2
;
;  INDIRECT JUMPS OR CALLS
;
CALLJ1: CMP     byte [AWORD],1
ERRZ4:  JZ      ERRV1
        CMP     byte [AWORD],4
        JNZ     ASMEX4
        OR      byte [DI+2],1000B
        JMP     SHORT ASMEX4
;
;   DIRECT JUMPS OR CALLS
;
CALLJ2: MOV     AX,[LOWNUM]
        MOV     DX,[HINUM]
        MOV     BL,[AWORD]
        CMP     byte [NUMFLG],0
        JZ      ERRZ4

;  BL = NUMBER OF BYTES IN JUMP
;  DX = OFFSET
;  AX = SEGMENT

CALLJ3:
        MOV     byte [DI],5
        MOV     [DI+2],AX
        MOV     [DI+4],DX

        MOV     AL,10011010B            ; SET UP INTER SEGMENT CALL
        CMP     byte [TSTFLG],0
        JZ      CALLJ5
        MOV     AL,11101010B            ; FIX UP FOR JUMP
CALLJ5: MOV     byte [DI+1],AL
        CMP     BL,4                    ; FAR SPECIFIED?
        JZ      ASMEX4
        OR      BL,BL
        JNZ     CALLJ6
        CMP     DX,word [ASMADD+2]  ; DIFFERENT SEGMENT?
        JNZ     ASMEX4

CALLJ6: MOV     byte [DI],3
        MOV     AL,11101000B            ; SET UP FOR INTRASEGMENT
        OR      AL,[TSTFLG]
        MOV     byte [DI+1],AL

        MOV     AX,[LOWNUM]
        SUB     AX,word [ASMADD]
        SUB     AX,3
        MOV     [DI+2],AX
        CMP     byte [TSTFLG],0
        JZ      ASMEX4
        CMP     BL,2
        JZ      ASMEX4

        INC     AX
        MOV     CX,AX
        CBW
        CMP     AX,CX
        JNZ     ASMEX3
        MOV     byte [DI+1],11101011B
        MOV     [DI+2],AX
        DEC     byte [DI]
ASMEX4: JMP     ASSEM_EXIT
;
;  conditional jumps and loop instructions
;
DISP8_OPER:
        MOV     BP,word [ASMADD+2]  ; GET DEFAULT DISPLACEMENT
        CALL    GET_ADDRESS
        SUB     DX,word [ASMADD]
        DEC     DX
        DEC     DX
        CALL    CHKSIZ
        CMP     CL,1
        JNZ     ERRV2
DISPX:  INC     [ASSEM_CNT]
        MOV     byte [ASSEM2],AL
ASMEX3: JMP     ASSEM_EXIT
;
;  lds, les, and lea instructions
;
L_OPER:
        CALL    SCANB
        LODSW
        MOV     CX,8
        MOV     DI,REG16
        CALL    CHKREG
        JZ      ERRV2                   ; CX = 0 MEANS NO REGISTER
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        MOV     byte [MIDFLD],AL
        CALL    SCANP
        CALL    GETREGMEM
        CMP     byte [AWORD],0
        JNZ     ERRV2
        CALL    BUILD2
        JMP     SHORT ASEXV
;
;  dec and inc instructions
;
DCINC_OPER:
        MOV     byte [ASSEM1],11111110B
        MOV     byte [MIDFLD],AL
        CALL    GETREGMEM
        CALL    BUILDIT
        TEST    byte [DI+1],1
        JZ      ASEXV
        MOV     AL,[DI+2]
        CMP     AL,11000000B
        JB      ASEXV
        AND     AL,1111B
        OR      AL,01000000B
        MOV     [DI+1],AL
        DEC     byte [DI]
ASEXV:  JMP     ASSEM_EXIT

ERRV2:  JMP     ASMERR
;
; esc instruction
;
ESC_OPER:
        INC     byte [AWORD]
        CALL    SCANB
        MOV     CX,2
        CALL    GETHX
        CMP     DX,64
        JAE     ERRV2
        CALL    SCANP
        MOV     AX,DX
        MOV     CL,3
        SHR     DX,CL
        OR      [ASSEM1],DL
        AND     AL,111B
        SHL     AL,CL
        JMP     GROUPE
;
; 8087 arithmetic instuctions
;

;
;  OPERANDS THAT ALLOW THE REVERSE BIT
;
FGROUPDS:
        CALL    SETMID
        CALL    GETREGMEM2
        CALL    BUILD3
        CMP     byte [MODE],11000000B
        JNZ     FGROUP1
        MOV     AL,[DIRFLG]
        OR      AL,AL
        JZ      FEXIT
        OR      [DI+1],AL               ; IF D=1...
        XOR     byte [DI+2],00001000B   ; ...REVERSE THE SENSE OF R
        JMP     SHORT FEXIT

;
;  Here when instruction could have memory or register operand
;
FGROUPX:
        CALL    SETMID                  ; THIS ENTRY POINT FOR 1 MEM OPER
        MOV     byte [DIRFLG],0
        JMP     SHORT FGRP2
FGROUP:
        CALL    SETMID
FGRP2:
        CALL    GETREGMEM2
        CALL    BUILD3
        CMP     byte [MODE],11000000B
        JNZ     FGROUP1
        MOV     AL,[DIRFLG]
        OR      [DI+1],AL
        JMP     SHORT FEXIT
FGROUP1:CALL    SETMF
FEXIT:  JMP     ASSEM_EXIT
;
; These 8087 instructions require a memory operand
;
FGROUPB:
        MOV     AH,5                    ; MUST BE TBYTE
        JMP     SHORT FGROUP3E
FGROUP3W:
        MOV     AH,2                    ; MUST BE WORD
        JMP     SHORT FGROUP3E
FGROUP3:
        MOV     AH,-1                   ; SIZE CANNOT BE SPECIFIED
FGROUP3E:
        MOV     [AWORD],AH
        CALL    SETMID
        CALL    GETREGMEM
        CMP     byte [MODE],11000000B
        JZ      FGRPERR
FGRP:
        CALL    BUILD3
        JMP     FEXIT
;
; These 8087 instructions require a register operand
;
FGROUPP:                                ; 8087 POP OPERANDS
        MOV     byte [AWORD],-1
        CALL    SETMID
        CALL    GETREGMEM2
        CMP     byte [DIRFLG],0
        JNZ     FGRP
FGRPERR:JMP     ASMERR

FGROUPZ:                                ; ENTRY POINT WHERE ARG MUST BE MEM
        CALL    SETMID
        MOV     byte [DIRFLG],0
        CALL    GETREGMEM
        CMP     byte [MODE],11000000B
        JZ      FGRPERR
        CALL    BUILD3
        CALL    SETMF
        JMP     FEXIT
;
; not, neg, mul, imul, div, and idiv instructions
;
GROUP1:
        MOV     [ASSEM1],11110110B
GROUPE:
        MOV     byte [MIDFLD],AL
        CALL    GETREGMEM
        CALL    BUILDIT
        JMP     FEXIT
;
;  shift and rotate instructions
;
ROTOP:
        MOV     [ASSEM1],11010000B
        MOV     byte [MIDFLD],AL
        CALL    GETREGMEM
        CALL    BUILDIT
        CALL    SCANP
        CMP     byte [SI],"1"
        JZ      ASMEXV1
        CMP     word [SI],"LC"      ; CL
        JZ      ROTOP1
ROTERR: JMP     ASMERR
ROTOP1: OR      byte [ASSEM1],10B
ASMEXV1:JMP     ASSEM_EXIT
;
;  xchg instruction
;
EX_OPER:
        INC     byte [TSTFLG]
;
;   test instruction
;
TST_OPER:
        INC     byte [TSTFLG]
        JMP     SHORT MOVOP
;
;    mov instruction
;
MOV_OPER:
        INC     byte [MOVFLG]
MOVOP:  XOR     AX,AX
        JMP     SHORT GROUPM
;
;   add, adc, sub, sbb, cmp, and, or, xor instructions
;
GROUP2:
        MOV     byte [ASSEM1],10000000B
GROUPM:
        MOV     byte [MIDFLD],AL

        PUSH    AX
        CALL    GETREGMEM
        CALL    BUILD2
        CALL    SCANP                   ; POINT TO NEXT OPERAND
        MOV     AL,byte [ASSEM_CNT]
        PUSH    AX
        CALL    GETREGMEM
        POP     AX
        MOV     byte [DI],AL
        POP     AX
        MOV     BL,byte [AWORD]
        OR      BL,BL
        JZ      ERRV5
        DEC     BL
        AND     BL,1
        OR      byte [DI+1],BL

        CMP     byte [MEMFLG],0
        JNZ     G21V
        CMP     byte [NUMFLG],0     ; TEST FOR IMMEDIATE DATA
        JZ      G21V
        CMP     byte [SEGFLG],0
        JNZ     ERRV5
        CMP     byte [TSTFLG],2     ; XCHG?
        JNZ     IMMED1
ERRV5:  JMP     ASMERR
G21V:   JMP     GRP21
;
;  SECOND OPERAND WAS IMMEDIATE
;
IMMED1: MOV     AL,byte [DI+2]
        CMP     byte [MOVFLG],0
        JZ      NOTMOV1
        AND     AL,11000000B
        CMP     AL,11000000B
        JNZ     GRP23                   ; not to a register
                                        ; MOVE IMMEDIATE TO REGISTER
        MOV     AL,byte [DI+1]
        AND     AL,1                    ; SET SIZE
        PUSHF
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        OR      AL,byte [DI+2]      ; SET REGISTER
        AND     AL,00001111B
        OR      AL,10110000B
        MOV     byte [DI+1],AL
        MOV     AX,word [LOWNUM]
        MOV     word [DI+2],AX
        POPF
        JZ      EXVEC
        INC     byte [DI]
EXVEC:  JMP     GRPEX

NOTMOV1:AND     AL,11000111B
        CMP     AL,11000000B
        JZ      IMMACC                  ; IMMEDIATE TO ACC

        CMP     byte [TSTFLG],0
        JNZ     GRP23
        CMP     byte [MIDFLD],1*8   ; OR?
        JZ      GRP23
        CMP     byte [MIDFLD],4*8   ; AND?
        JZ      GRP23
        CMP     byte [MIDFLD],6*8   ; XOR?
        JZ      GRP23
        TEST    byte [DI+1],1       ; TEST IF BYTE OPCODE
        JZ      GRP23

        MOV     AX,[LOWNUM]
        MOV     BX,AX
        CBW
        CMP     AX,BX
        JNZ     GRP23                   ; SMALL ENOUGH?

        MOV     BL,[DI]
        DEC     byte [DI]
        OR      byte [DI+1],10B
        JMP     SHORT GRP23X

IMMACC: MOV     AL,byte [DI+1]
        AND     AL,1
        CMP     byte [TSTFLG],0
        JZ      NOTTST
        OR      AL,10101000B
        JMP     SHORT TEST1
NOTTST: OR      AL,byte [MIDFLD]
        OR      AL,100B
TEST1:  MOV     byte [DI+1],AL
        DEC     byte [DI]

GRP23:  MOV     BL,byte [DI]
GRP23X: XOR     BH,BH
        ADD     BX,DI
        INC     BX
        MOV     AX,word [LOWNUM]
        MOV     word [BX],AX
        INC     byte [DI]
        TEST    byte [DI+1],1
        JZ      GRPEX1
        INC     byte [DI]
GRPEX1: JMP     GRPEX
;
;       SECOND OPERAND WAS MEMORY OR REGISTER
;
GRP21:
        CMP     byte [SEGFLG],0
        JZ      GRP28                   ; FIRST OPERAND WAS A SEGMENT REG
        MOV     AL,byte [REGMEM]
        TEST    AL,10000B
        JZ      NOTSEG1
ERRV3:  JMP     ASMERR
NOTSEG1:AND     AL,111B
        OR      byte [DI+2],AL
        AND     byte [DI+1],11111110B
        CMP     byte [MEMFLG],0
        JNZ     G22V
        JMP     GRPEX

GRP28:  AND     byte [DI+2],11000111B
        MOV     AL,byte [DI+1]      ; GET FIRST OPCODE
        AND     AL,1B
        CMP     byte [MOVFLG],0
        JZ      NOTMOV2
        OR      AL,10001000B
        JMP     SHORT MOV1
NOTMOV2:CMP     byte [TSTFLG],0
        JZ      NOTTST2
        OR      AL,10000100B
        CMP     byte [TSTFLG],2
        JNZ     NOTTST2
        OR      AL,10B
NOTTST2:OR      AL,byte [MIDFLD]    ; MIDFLD IS ZERO FOR TST
MOV1:   MOV     byte [DI+1],AL
        CMP     byte [MEMFLG],0
G22V:   JNZ     GRP22
;
;       SECOND OPERAND WAS A REGISTER
;
        MOV     AL,byte [REGMEM]
        TEST    AL,10000B               ; SEGMENT REGISTER?
        JZ      NOTSEG
        CMP     byte [MOVFLG],0
        JZ      ERRV3
        MOV     byte [DI+1],10001100B

NOTSEG: AND     AL,111B
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        OR      byte [DI+2],AL
;
; SPECIAL FORM OF THE EXCHANGE COMMAND
;
        CMP     byte [TSTFLG],2
        JNZ     GRPEX
        TEST    byte [DI+1],1
        JZ      GRPEX
        PUSH    AX
        MOV     AL,byte [DI+2]
        AND     AL,11000000B
        CMP     AL,11000000B            ; MUST BE REGISTER TO REGISTER
        POP     AX
        JB      GRPEX
        OR      AL,AL
        JZ      SPECX
        MOV     AL,[DI+2]
        AND     AL,00000111B
        JNZ     GRPEX
        MOV     CL,3
        SHR     byte [DI+2],CL
SPECX:  MOV     AL,[DI+2]
        AND     AL,00000111B
        OR      AL,10010000B
        MOV     byte [DI+1],AL
        DEC     byte [DI]
        JMP     SHORT GRPEX
;
;  SECOND OPERAND WAS A MEMORY REFERENCE
;
GRP22:  CMP     byte [TSTFLG],0
        JNZ     TST2
        OR      byte [DI+1],10B
TST2:   MOV     AL,byte [DI+2]
        CMP     AL,11000000B            ; MUST BE A REGISTER
        JB      ASMERR
        CMP     byte [SEGFLG],0
        JZ      GRP223
        AND     AL,00011000B
        JMP     SHORT GRP222
GRP223: AND     AL,111B
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
GRP222: OR      AL,byte [MODE]
        OR      AL,byte [REGMEM]
        MOV     byte [DI+2],AL
        MOV     AX,word [LOWNUM]
        MOV     word [DI+3],AX
GRPSIZ: MOV     byte [DI],2
        MOV     AL,byte [DI+2]
        AND     AL,11000111B
        CMP     AL,00000110B
        JZ      GRP24
        AND     AL,11000000B
        CMP     AL,01000000B
        JZ      GRP25
        CMP     AL,10000000B
        JNZ     GRPEX
GRP24:  INC     byte [DI]
GRP25:  INC     byte [DI]

GRPEX:  CMP     byte [MOVFLG],0
        JZ      ASSEM_EXIT
;
;       TEST FOR SPECIAL FORM OF MOV AX,[MEM] OR MOV [MEM],AX
;
        MOV     AL,[DI+1]               ; GET OP-CODE
        AND     AL,11111100B
        CMP     AL,10001000B
        JNZ     ASSEM_EXIT
        CMP     byte [DI+2],00000110B   ; MEM TO AX OR AX TO MEM
        JNZ     ASSEM_EXIT
        MOV     AL,byte [DI+1]
        AND     AL,11B
        XOR     AL,10B
        OR      AL,10100000B
        MOV     byte [DI+1],AL
        DEC     byte [DI]
        MOV     AX,[DI+3]
        MOV     word [DI+2],AX

ASSEM_EXIT:
        CALL    STUFF_BYTES
        JMP     ASSEMLOOP

; Assem error. SI points to character in the input buffer
; which caused error. By subtracting from start of buffer,
; we will know how far to tab over to appear directly below
; it on the terminal. Then print "^ Error".

ASMERR:
        SUB     SI,(BYTEBUF-10)   ; How many char processed so far?
        MOV     CX,SI                   ; Parameter for TAB in CX
        CALL    TAB                     ; Directly below bad char
        MOV     SI,SYNERR     ; Error message
        CALL    PRINTMES
        JMP     ASSEMLOOP
;
;  assemble the different parts into an instruction
;
BUILDIT:
        MOV     AL,byte [AWORD]
        OR      AL,AL
        JNZ     BUILD1
BLDERR: JMP     ASMERR

BUILD1: DEC     AL
        OR      byte [DI+1],AL      ; SET THE SIZE

BUILD2: CMP     byte [NUMFLG],0     ; TEST FOR IMMEDIATE DATA
        JZ      BUILD3
        CMP     byte [MEMFLG],0
        JZ      BLDERR

BUILD3: MOV     AL,byte [REGMEM]
        CMP     AL,-1
        JZ      BLD1
        TEST    AL,10000B               ; TEST IF SEGMENT REGISTER
        JZ      BLD1
        CMP     byte [MOVFLG],0
        JZ      BLDERR
        MOV     word [DI+1],10001110B
        INC     byte [MOVFLG]
        INC     byte [SEGFLG]
        AND     AL,00000011B
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        OR      AL,byte 11000000B
        MOV     byte [DI+2],AL
        RET

BLD1:   AND     AL,00000111B
BLD4:   OR      AL,byte [MODE]
        OR      AL,byte [MIDFLD]
        MOV     byte [DI+2],AL
        MOV     AX,word [LOWNUM]
        MOV     word [DI+3],AX
        RET

GETREGMEM:
        MOV     byte [F8087],0
GETREGMEM2:
        CALL    SCANP
        XOR     AX,AX
        MOV     word [LOWNUM],AX    ; OFFSET
        MOV     word [DIFLG],AX     ; DIFLG+SIFLG
        MOV     word [BXFLG],AX     ; BXFLG+BPFLG
        MOV     word [NEGFLG],AX    ; NEGFLG+NUMFLG
        MOV     word [MEMFLG],AX    ; MEMFLG+REGFLG
        DEC     AL
        CMP     byte [F8087],0
        JZ      PUTREG
        MOV     AL,1                    ; DEFAULT 8087 REG IS 1
PUTREG: MOV     byte [REGMEM],AL

GETLOOP:MOV     byte [NEGFLG],0
GETLOOP1:
        MOV     AX,word [SI]
        CMP     AL,','
        JZ      GOMODE
        CMP     AL,13
        JZ      GOMODE
        CMP     AL,';'
        JZ      GOMODE
        CMP     AL,9
        JZ      GETTB
        CMP     AL,' '
        JNZ     GOGET
GETTB:  INC     SI
        JMP     GETLOOP1
GOGET:  JMP     GETINFO
;
;  DETERMINE THE MODE BITS
;
GOMODE: MOV     DI,ASSEM_CNT
        MOV     byte [MODE],11000000B
        MOV     byte [ASSEM_CNT],2
        CMP     byte [MEMFLG],0
        JNZ     GOMODE1
        MOV     AL,[NUMFLG]
        OR      AL,[REGFLG]
        JNZ     MORET
        OR      AL,[F8087]
        JZ      ERRET
        MOV     AL,[DI+1]
        OR      AL,[DIRFLG]
        CMP     AL,0DCH                 ; ARITHMETIC?
        JNZ     MORET
        MOV     byte [DI+1],0DEH    ; ADD POP TO NULL ARG 8087
MORET:  RET
ERRET:  JMP     ASMERR

GOMODE1:MOV     byte [MODE],0
        CMP     byte [NUMFLG],0
        JZ      GOREGMEM

        MOV     byte [DI],4
        MOV     AX,word [DIFLG]
        OR      AX,word [BXFLG]
        JNZ     GOMODE2
        MOV     byte [REGMEM],00000110B
        RET

GOMODE2:MOV     byte [MODE],10000000B
        CALL    CHKSIZ1
        CMP     CL,2
        JZ      GOREGMEM
        DEC     byte [DI]
        MOV     byte [MODE],01000000B
;
;  DETERMINE THE REG-MEM BITS
;
GOREGMEM:
        MOV     BX,word [BXFLG]
        MOV     CX,word [DIFLG]
        XOR     DX,DX
GOREG0:
        MOV     AL,BL                   ; BX
        ADD     AL,CH                   ; SI
        CMP     AL,2
        JZ      GOGO
        INC     DL
        MOV     AL,BL
        ADD     AL,CL
        CMP     AL,2
        JZ      GOGO
        INC     DL
        MOV     AL,BH
        ADD     AL,CH
        CMP     AL,2
        JZ      GOGO
        INC     DL
        MOV     AL,BH
        ADD     AL,CL
        CMP     AL,2
        JZ      GOGO
        INC     DL
        OR      CH,CH
        JNZ     GOGO
        INC     DL
        OR      CL,CL
        JNZ     GOGO
        INC     DL                      ; BP+DISP
        OR      BH,BH
        JZ      GOREG1
        CMP     byte [MODE],0
        JNZ     GOGO
        MOV     byte [MODE],01000000B
        INC     byte [DI]
        DEC     DL
GOREG1: INC     DL                      ; BX+DISP
GOGO:   MOV     byte [REGMEM],DL
        RET

GETINFO:CMP     AX,'EN'                 ; NEAR
        JNZ     GETREG3
GETREG0:MOV     DL,2
GETRG01:CALL    SETSIZ1
GETREG1:CALL    SCANS
        MOV     AX,word [SI]
        CMP     AX,"TP"                 ; PTR
        JZ      GETREG1
        JMP     GETLOOP

GETREG3:MOV     CX,5
        MOV     DI,SIZ8
        CALL    CHKREG                  ; LOOK FOR BYTE, WORD, DWORD, ETC.
        JZ      GETREG41
        INC     AL
        MOV     DL,AL
        JMP     GETRG01

GETREG41:
        MOV     AX,[SI]
        CMP     byte [F8087],0
        JZ      GETREG5
        CMP     AX,"TS"                 ; 8087 STACK OPERAND
        JNZ     GETREG5
        CMP     byte [SI+2],","
        JNZ     GETREG5
        MOV     byte [DIRFLG],0
        ADD     SI,3
        JMP     GETLOOP

GETREG5:CMP     AX,"HS"                 ; SHORT
        JZ      GETREG1

        CMP     AX,"AF"                 ; FAR
        JNZ     GETRG51
        CMP     byte [SI+2],"R"
        JNZ     GETRG51
        ADD     SI,3
        MOV     DL,4
        JMP     GETRG01

GETRG51:CMP     AL,'['
        JNZ     GETREG7
GETREG6:INC     byte [MEMFLG]
        INC     SI
        JMP     GETLOOP

GETREG7:CMP     AL,']'
        JZ      GETREG6
        CMP     AL,'.'
        JZ      GETREG6
        CMP     AL,'+'
        JZ      GETREG6
        CMP     AL,'-'
        JNZ     GETREG8
        INC     byte [NEGFLG]
        INC     SI
        JMP     GETLOOP1

GETREG8:                                ; LOOK FOR A REGISTER
        CMP     byte [F8087],0
        JZ      GETREGREG
        CMP     AX,"TS"
        JNZ     GETREGREG
        CMP     byte [SI+2],"("
        JNZ     GETREGREG
        CMP     byte [SI+4],")"
        JNZ     ASMPOP
        MOV     AL,[SI+3]
        SUB     AL,"0"
        JB      ASMPOP
        CMP     AL,7
        JA      ASMPOP
        MOV     [REGMEM],AL
        INC     byte [REGFLG]
        ADD     SI,5
        CMP     word [SI],"S,"
        JNZ     ZLOOP
        CMP     byte [SI+2],"T"
        JNZ     ZLOOP
        ADD     SI,3
ZLOOP:  JMP     GETLOOP

GETREGREG:
        MOV     CX,20
        MOV     DI,REG8
        CALL    CHKREG
        JZ      GETREG12                ; CX = 0 MEANS NO REGISTER
        MOV     byte [REGMEM],AL
        INC     byte [REGFLG]       ; TELL EVERYONE WE FOUND A REG
        CMP     byte [MEMFLG],0
        JNZ     NOSIZE
        CALL    SETSIZ
INCSI2: ADD     SI,2
        JMP     GETLOOP

NOSIZE: CMP     AL,11                   ; BX REGISTER?
        JNZ     GETREG9
        CMP     word [BXFLG],0
        JZ      GETOK
ASMPOP: JMP     ASMERR

GETOK:  INC     byte [BXFLG]
        JMP     INCSI2
GETREG9:
        CMP     AL,13                   ; BP REGISTER?
        JNZ     GETREG10
        CMP     word [BXFLG],0
        JNZ     ASMPOP
        INC     byte [BPFLG]
        JMP     INCSI2
GETREG10:
        CMP     AL,14                   ; SI REGISTER?
        JNZ     GETREG11
        CMP     word [DIFLG],0
        JNZ     ASMPOP
        INC     byte [SIFLG]
        JMP     INCSI2
GETREG11:
        CMP     AL,15                   ; DI REGISTER?
        JNZ     ASMPOP                  ; *** error
        CMP     word [DIFLG],0
        JNZ     ASMPOP
        INC     byte [DIFLG]
        JMP     INCSI2

GETREG12:                               ; BETTER BE A NUMBER!
        MOV     BP,word [ASMADD+2]
        CMP     byte [MEMFLG],0
        JZ      GTRG121
GTRG119:MOV     CX,4
GTRG120:CALL    GETHX
        JMP     SHORT GTRG122
GTRG121:MOV     CX,2
        CMP     byte [AWORD],1
        JZ      GTRG120
        CMP     byte [AWORD],CL
        JZ      GTRG119
        CALL    GET_ADDRESS
GTRG122:JC      ASMPOP
        MOV     [HINUM],AX
        CMP     byte [NEGFLG],0
        JZ      GETREG13
        NEG     DX
GETREG13:
        ADD     word [LOWNUM],DX
        INC     byte [NUMFLG]
GETLOOPV:
        JMP     GETLOOP

CHKREG: PUSH    CX
        INC     CX
        REPNZ   SCASW
        POP     AX
        SUB     AX,CX
        OR      CX,CX
        RET

STUFF_BYTES:
        PUSH    SI
        LES     DI,dword [ASMADD]
        MOV     SI,ASSEM_CNT
        XOR     AX,AX
        LODSB
        MOV     CX,AX
        JCXZ    STUFFRET
        REP     MOVSB
        MOV     word [ASMADD],DI
STUFFRET:
        POP     SI
        RET

SETSIZ:
        MOV     DL,1
        TEST    AL,11000B               ; 16 BIT OR SEGMENT REGISTER?
        JZ      SETSIZ1
        INC     DL
SETSIZ1:
        CMP     byte [AWORD],0
        JZ      SETSIZ2
        CMP     byte [AWORD],DL
        JZ      SETSIZ2
SETERR: POP     DX
        JMP     ASMPOP
SETSIZ2:MOV     byte [AWORD],DL
        RET
;
;  DETERMINE IF NUMBER IN AX:DX IS 8 BITS, 16 BITS, OR 32 BITS
;
CHKSIZ: MOV     CL,4
        CMP     AX,BP
        JNZ     RETCHK
CHKSIZ1:MOV     CL,2
        MOV     AX,DX
        CBW
        CMP     AX,DX
        JNZ     RETCHK
        DEC     CL
RETCHK: RET
;
;  get first character after first space
;
SCANS:  CMP     byte [SI],13
        JZ      RETCHK
        CMP     byte [SI],"["
        JZ      RETCHK
        LODSB
        CMP     AL," "
        JZ      SCANBV
        CMP     AL,9
        JNZ     SCANS
SCANBV: JMP     SCANB
;
; Set up for 8087 op-codes
;
SETMID:
        MOV     byte [ASSEM1],0D8H
        MOV     AH,AL
        AND     AL,111B                 ; SET MIDDLE BITS OF SECOND BYTE
        SHL     AL,1
        SHL     AL,1
        SHL     AL,1
        MOV     [MIDFLD],AL
        MOV     AL,AH                   ; SET LOWER BITS OF FIRST BYTE
        SHR     AL,1
        SHR     AL,1
        SHR     AL,1
        OR      [ASSEM1],AL
        MOV     byte [F8087],1      ; INDICATE 8087 OPERAND
        MOV     byte [DIRFLG],100B
        RET
;
; Set MF bits for 8087 op-codes
;
SETMF:  MOV     AL,[AWORD]
        TEST    byte [DI+1],10B
        JNZ     SETMFI
        AND     byte [DI+1],11111001B   ; CLEAR MF BITS
        CMP     AL,3                    ; DWORD?
        JZ      SETMFRET
        CMP     AL,4                    ; QWORD?
        JZ      SETMFRET2
        TEST    byte [DI+1],1
        JZ      SETMFERR
        CMP     AL,5                    ; TBYTE?
        JZ      SETMFRET3
        JMP     SHORT SETMFERR

SETMFI: CMP     AL,3                    ; DWORD?
        JZ      SETMFRET
        CMP     AL,2                    ; WORD?
        JZ      SETMFRET2
        TEST    byte [DI+1],1
        JZ      SETMFERR
        CMP     AL,4                    ; QWORD?
        JNZ     SETMFERR
        OR      byte [DI+1],111B
SETMFRET3:
        OR      byte [DI+1],011B
        OR      byte [DI+2],101000B
        JMP     SHORT SETMFRET
SETMFRET2:
        OR      byte [DI+1],100B
SETMFRET:
        RET

SETMFERR:
        JMP     ASMPOP


DW_OPER:
        MOV     BP,1
        JMP     SHORT DBEN

DB_OPER:
        XOR     BP,BP
DBEN:   MOV     DI,ASSEM_CNT
        DEC     byte [DI]
        INC     DI
DB0:    XOR     BL,BL
        CALL    SCANP
        JNZ     DB1
DBEX:   JMP     ASSEM_EXIT
DB1:    OR      BL,BL
        JNZ     DB3
        MOV     BH,byte [SI]
        CMP     BH,"'"
        JZ      DB2
        CMP     BH,'"'
        JNZ     DB4
DB2:    INC     SI
        INC     BL
DB3:    LODSB
        CMP     AL,13
        JZ      DBEX
        CMP     AL,BH
        JZ      DB0
        STOSB
        INC     byte [ASSEM_CNT]
        JMP     DB3
DB4:    MOV     CX,2
        CMP     BP,0
        JZ      DB41
        MOV     CL,4
DB41:   PUSH    BX
        CALL    GETHX
        POP     BX
        JNC     DB5
        JMP     ASMERR
DB5:    MOV     AX,DX
        CMP     BP,0
        JZ      DB6
        STOSW
        INC     byte [ASSEM_CNT]
        JMP     SHORT DB7
DB6:    STOSB
DB7:    INC     byte [ASSEM_CNT]
        JMP     DB0

end if
