;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   WRITE ROUTINE FOR DESIGNATE WRITE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IF1                                            ;
;        %OUT .               ®WRITE   .INC¯
;ENDIF                                          ;
;        PUBLIC  REDUCED_SUPPORT                ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       WRITE DESIGNATE SUPPORT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DESG_WRITE:                             ;
        CMP     byte [cs:DESG_SEMAPHORE],ZERO ; TEST IF DESIGNATE IS ON...
        JNE     DW_2                    ; PASS ONTO DOS
        CLC                             ;
        RET                             ;
DW_2:   CMP     byte [cs:DESG_SEMAPHORE],ONE ; CHECK IF PROPER DESIGNATE
        JE      DW_4                    ;
        OR      word [BUF+BUF_DATA.STATUS],TEN ; IF NOT, THEN DEVICE ERROR
        STC                             ;
        RET                             ;
DW_4:   CALL    WRITE                   ;
        RET                             ;
;DESG_WRITE   ENDP                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
REDUCED_SUPPORT =     $               ; THIS IS A MARKER FOR REDUCED CPS
                                        ; SUPPORT WITH 0 DESGINATES (CGA,MONO)
WRITE:                                  ;
        PUSH    DS                      ;
                                        ;
        PUSH    CS                      ;
        POP     DS                      ;
                                        ;
        PUSH    SI                    ;S;
        CLI                           ;S;
        MOV     SI,SP                 ;S;
        MOV     [cs:OLD_STACK_O],SI   ;S;
        MOV     SI,SS                 ;S;
        MOV     [cs:OLD_STACK_S],SI   ;S;
        MOV     AX,STACK_START        ;S;
        MOV     SI,CS                 ;S;
        MOV     SS,SI                 ;S;
        MOV     SP,AX                 ;S;
        STI                           ;S;
                                        ;
        LES     DI,dword [BUF+BUF_DATA.RH_PTRO] ; RESTORE ES:DI AS REQUEST HEADER PTR
        LEA     SI,[FTABLE]             ; GET BASE ADDRESS OF PARSER TABLE
                                        ;
        MOV     [ds:SI+FBUFS.FLAG],0    ; NO RESTART
        MOV     AX,word [RH+RH3.RH3_CNT] ;
        MOV     [ds:SI+FBUFS.BUFFER_LEN],AX ; LENGTH OF REQUEST PACKET
                                        ;
        PUSH    SI                      ;
        LEA     SI,[SI+FBUFS.BUFFER_ADDR] ; PACKET ADDRESS
        MOV     AX,word [RH+RH3.RH3_DTAO] ;
        MOV     [ds:SI],AX              ;
        INC     SI                      ;
        INC     SI                      ;
        MOV     AX,word [RH+RH3.RH3_DTAS] ;
        MOV     [ds:SI],AX              ;
        POP     SI                      ;
                                        ;
        CALL    FONT_PARSER             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       FONT PARSER HAS BEEN CALLED, NOW CHECK ALL OF THE
;       APPROPRIATE TABLES FOR DATA INFORMATION, ERROR
;       CONDITIONS, etc....
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        LEA     SI,[FTABLE]             ; GET BASE ADDRESS OF PARSER TABLE
        MOV     CX,[SI+FBUFS.NUM_FTBLK] ; CX = NUMBER OF PARSING TABLES
        LEA     SI,[FTB1]               ; THEN SET SI = FIRST PARSING TABLE
                                        ;
W_1:    MOV     AX,[ds:SI+FTBLK.FTB_STATUS] ;
        CMP     AX,0FFF0H               ; CHECK THE PARSER STATUS
        JNB     W_3                     ;
                                        ;
        OR      word [BUF+BUF_DATA.STATUS],FAIL ; IF THE PARSER FAILED ON THE DATA
        MOV     word [RH+RHC.RHC_STA],AX ; FILE, THEN SET FLAG AND...
        CALL    HANDLE_WRITE_ERROR      ;
        JUMP    W_7                     ; ERROR HAS BEEN FOUND..DON'T CONTINUE
                                        ;
W_3:    CMP     AX,FSTAT_FONT           ;
        JNE     W_6                     ;
                                        ;
        MOV     AX,[ds:SI+FTBLK.FTB_DLEN] ;
        CALL    HANDLE_DATA_WRITE       ;
                                        ;
W_6:    ADD     SI,sizeof.FTBLK         ; ADVANCE SI POINTER TO NEXT TABLE
        LOOP    W_1                     ; CHECK OUT ALL PARSING TABLES
                                        ;
W_7:    CLI                           ;S;
        MOV     SI,[cs:OLD_STACK_S]   ;S;
        MOV     AX,[cs:OLD_STACK_O]   ;S;
        MOV     SS,SI                 ;S;
        MOV     SP,AX                 ;S;
        STI                           ;S;
        POP     SI                    ;S;
        POP     DS                      ;
        STC                             ; INDICATE NOT TO PASS ON DATA
        RET                             ;
;WRITE   ENDP                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       THIS IS USED TO SET THE CPS DRIVER IN THE CASE OF A
;       DESIGNATE ERROR.  IT WILL RESET THE DESIGNATED CP's
;       TO INVALID, AND IF THE ACTIVE_CP WAS A DESIGNATED CP,
;       THEN IT TOO BECOMES INVALID.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HANDLE_WRITE_ERROR:                     ;
        PUSH    DS                      ;
        PUSH    AX                      ;
        PUSH    CX                      ;
        PUSH    SI                      ;
                                        ;
        MOV     AX,-1                   ; ...SET DESGINATE LIST TO (-1)'S
        MOV     CX,[cs:CPD_REQ_DESG]    ; GET NUMBER AND
        MOV     SI,2                    ; +2
HWE_3:  CMP     [cs:SI+CPD_REQ_DESG],AX ; CHECK IF REQUESTED PREP WAS VALID
        JE      HWE_4                   ; IF REQUESTED WAS VALID, THEN THE ERROR
        MOV     [cs:SI+CPD_DESG_N],AX   ; SETS ACTUAL PREP LIST ENTRY TO INVALID
HWE_4:  INC     SI                      ;
        INC     SI                      ;
        LOOP    HWE_3                   ; REPEAT FOR #DESIGNATES
                                        ;
        MOV     CX,[cs:CPD_ACTIVE]      ;
        CALL    FIND_CP                 ; CHECK IF ACTIVE_CP=STILL VALID
        JNC     HWE_2                   ;
        MOV     CX,-1                   ;
        MOV     [cs:CPD_ACTIVE],CX      ;
                                        ;
HWE_2:  POP     SI                      ;
        POP     CX                      ;
        POP     AX                      ;
        POP     DS                      ;
        RET                             ;
;HANDLE_WRITE_ERROR      ENDP            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       THIS SUBROUTINE TAKES THE DATA INFORMATION ISOLATED
;       BY THE FONT PARSER AND MOVES INTO THE INTERNAL FONT
;       FONT BUFFERS.  IT COPIES THE DATA BASED ON THE SIZE
;       OF THE INTERNAL FONTS & THE REQUIRED FONT SIZES.
;
;
;       INPUT:
;               AX = LENGTH OF DATA
;               CX = TABLE # TO PARSE
;               DS:SI = POINTER TO 'FTBLK'
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NUM_DATA_FONTS  rw      1               ;
TABLE_INDEX     rw      1               ;
LEN_DATA        rw      1               ;
INDEX_WRITE_PNTER rw      1             ;
                                        ;
HANDLE_DATA_WRITE:                      ;
        PUSH    AX                      ;
        PUSH    BX                      ;
        PUSH    CX                      ;
        PUSH    SI                      ;
        PUSH    DI                      ;
        PUSH    DS                      ;
        PUSH    ES                      ;
                                        ;
        PUSH    CX                      ;
        MOV     CX,[ds:SI+FTBLK.FTB_FONTS] ; READ IN #FONTS FROM DATA FILE
        MOV     [cs:NUM_DATA_FONTS],CX  ;
        POP     CX                      ;
                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       ROUTINE TO FIND TABLE_INDEX FOR DATA WRITE'S
;       THIS WAS ADDED TO ACCOUNT FOR A REPLACEMENT
;       TECHNIQUE APPROACH.....(Sept 3/86)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        PUSH    AX                      ;
        PUSH    CX                      ;
        PUSH    ES                      ;
                                        ;
        PUSH    CS                      ;
        POP     ES                      ;
        MOV     AX,[ds:SI+FTBLK.FTB_CP] ; GET THE CODE PAGE OF THIS FONT BLOCK
        MOV     CX,[cs:CPD_DESG_N]      ; GET THE NUMBER OF CP's TO CHECK
        MOV     DI,TWO                  ;
BBB_0:  CMP     AX,[cs:DI+CPD_DESG_N]   ; LOOKING FOR A MATCHED CODE PAGE
        JE      BBB_1                   ;
        INC     DI                      ;
        INC     DI                      ;
        LOOP    BBB_0                   ;
                                        ;
;;;;;;INVALID???;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;
BBB_1:  MOV     DI,[cs:CPD_DESG_N]      ;
        SUB     DI,CX                   ;
        MOV     [cs:TABLE_INDEX],DI     ;
BBB_2:  POP     ES                      ;
        POP     CX                      ;
        POP     AX                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        PUSH    SI                      ;
        LEA     SI,[FTABLE]             ; GET BASE ADDRESS OF PARSER TABLE
        SHL     DI,1                    ;
        SHL     DI,1                    ; MULTIPLY INDEX BY FOUR..SEG:OFFSET
        CALL    GET_WRITE_PNTR          ; GET LOCATION OF 1ST FONT_WRITE PNTER
        ADD     DI,SI                   ; DI NOW IS THE POINTER TO WRITE_START
        POP     SI                      ;
                                        ;
        MOV     [cs:INDEX_WRITE_PNTER],DI ; SAVE ADDRESS OF INDEX WRITE PNTER
                                        ;
        MOV     ES,[cs:DI+2]            ; SET ES : DI WITH WRITE POINTER!
        MOV     DI,[cs:DI]              ;
                                        ;
        MOV     CX,[ds:SI+FTBLK.FTB_DAHI] ; GET SEGMENT OF DATA
        MOV     SI,[ds:SI+FTBLK.FTB_DALO] ; GET OFFSET OF DATA
        MOV     DS,CX                   ;
                                        ; <<SETUP DESTINATION INFO>>
        MOV     CX,AX                   ; SAVE LENGTH OF DATA TO COPY
        MOV     [cs:LEN_DATA],CX        ; SAVE THIS VALUE
        AND     CX,CX                   ; TEST LENGTH OF DATA
        JNZ     TEMP_0                  ;
        JUMP    HDW_8                   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NOW  DS : SI  POINTS TO SOURCE DATA INFORMATION,
;            ES : DI  POINTS TO THE DESTINATION BUFFER!
;            CX = NUMBER OF INFORMATION BYTES AVAILABLE
;       THE DATA MUST BE CHECKED FOR THE FONT RESOLUTIONS
;       AS THEY ARE TO FIT INTO THE INTERNAL BUFFERS.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TEMP_0: PUSH    AX                      ;
        PUSH    BX                      ;
        PUSH    CX                      ;
        PUSH    SI                      ;
        PUSH    DI                      ;
                                        ;
        LEA     BX,[CPD_FONT_DATA]      ; TEST IF THERE IS OUTSTANDING DATA
        ADD     BX,[cs:TABLE_INDEX]     ; FOR INFORMATION TO COPY or SKIP OVER.
        ADD     BX,[cs:TABLE_INDEX]     ; (ACCOUNT FOR WORD VALUE)
        MOV     AX,[cs:BX]              ;
        OR      AX,AX                   ;
        JE      HDW_00                  ; IF NOTHING TO CONSIDER, THEN MOVE ON
        TEST    AX,8000H ;;;;SKIP/COPY;;;;; TEST IF OUTSTANDING DATA TO COPY/SKIP
        JNZ     HDW_P0                  ;
        MOV     CX,AX                   ; SET VALUE IN CX....
        MOV     AX,[cs:NUM_DATA_FONTS]  ;
        PUSH    AX                      ;
        JUMP    HDW_3AA                 ;
HDW_P0: AND     AX,7FFFH                ; STRIP OFF FIRST BIT...
        MOV     CX,AX                   ;
        MOV     AX,[cs:NUM_DATA_FONTS]  ;
        PUSH    AX                      ;
        JUMP    HDW_5AA                 ;
                                        ;
HDW_00: MOV     CX,[cs:NUM_DATA_FONTS]  ;
HDW_0:  CMP     word [cs:LEN_DATA],0    ; TEST IF THERE IS ANY DATA LEFT?
        JNE     HDW_0A                  ;
        JUMP    HDW_6                   ; IF 0 LEFT...THEN END...
                                        ;
HDW_0A: MOV     AL,[SI]                 ; GET #ROWS FROM DATA
        PUSH    CX                      ; SAVE COUNT
        MOV     CX,NUM_FONT_PRIORITY    ;
        LEA     BX,[FONT_PRIORITY]      ; SET DI TO START OF TABLE
HDW_1:  CMP     AL,[cs:BX]              ;
        JE      HDW_3                   ; IF EQUAL, THEN ALREADY IN TABLE
        INC     BX                      ; OTHERWISE, TAKE THIS MODES FONT RES
        LOOP    HDW_1                   ; AND COMPARE AGAINST NEXT PRIOR.VALUE
        JUMP    HDW_5                   ; IF NO MATCH, THEN IGNORE THIS FONT!!!
                                        ;
HDW_3:  XOR     AH,AH                   ; FONT SIZE NEEDED...GET IT!
        MOV     CX,[SI+4]               ; GET THE #CHARACTERS IN TABLE
        PUSH    DX                      ;
        MUL     CX                      ;
        POP     DX                      ;
        ADD     AX,SIX                  ; ACCOUNT FOR DATA HEADER
        MOV     CX,AX                   ; SET COUNT INTO CX....
                                        ;
HDW_3AA:CMP     CX,[cs:LEN_DATA]        ; TEST IF SUPPLIED DATA>=NEEDED
        JBE     HDW_3A                  ;
        SUB     CX,[cs:LEN_DATA]        ; IF NOT ENOUGH DATA HERE, THEN FORWARD
        MOV     AX,CX                   ; VALUE TO NEXT DATA CALL.
        CALL    SET_CPD_FONT_DATA       ;
        MOV     CX,[cs:LEN_DATA]        ;
        JUMP    HDW_3B                  ;
                                        ;
HDW_3A: XOR     AX,AX                   ;
        CALL    SET_CPD_FONT_DATA       ;
HDW_3B: SUB     [cs:LEN_DATA],CX        ;
        CLD                             ;
        REP     MOVSB                   ; MOVE THAT RESOLUTION IN...
                                        ;
HDW_4:  POP     CX                      ; RESTORE #FONTS IN DATA
        LOOP    HDW_0                   ;
        JUMP    HDW_6                   ;
                                        ;
HDW_5:  XOR     AH,AH                   ; FONT SIZE NEEDED...GET IT!
        MOV     CX,[SI+4]               ; GET THE #CHARACTERS IN TABLE
        PUSH    DX                      ;
        MUL     CX                      ;
        POP     DX                      ;
        ADD     AX,SIX                  ; ACCOUNT FOR DATA HEADER
        MOV     CX,AX                   ; PUT IN CX FOR NOW
                                        ;
HDW_5AA:CMP     CX,[cs:LEN_DATA]        ; TEST IF SUPPLIED DATA>=NEEDED
        JBE     HDW_5A                  ;
        SUB     CX,[cs:LEN_DATA]        ; IF NOT ENOUGH DATA HERE, THEN FORWARD
        MOV     AX,CX                   ; VALUE TO NEXT DATA CALL.
        OR      AX,8000H                ; SET TO SKIP NEXT DATA....
        CALL    SET_CPD_FONT_DATA       ;
        MOV     CX,[cs:LEN_DATA]        ;
        JUMP    HDW_5B                  ;
                                        ;
HDW_5A: XOR     AX,AX                   ;
        CALL    SET_CPD_FONT_DATA       ;
HDW_5B: SUB     [cs:LEN_DATA],CX        ;
        ADD     SI,CX                   ; ADVANCE SOURCE POINTER OVER THIS FONT
        JUMP    HDW_4                   ;
                                        ;
HDW_6:  MOV     SI,[cs:INDEX_WRITE_PNTER] ;
        MOV     [cs:SI],DI              ;
        MOV     [cs:SI+2],ES            ;
                                        ;
        POP     DI                      ;
        POP     SI                      ;
        POP     CX                      ;
        POP     BX                      ;
        POP     AX                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HDW_8:  POP     ES                      ;
        POP     DS                      ;
        POP     DI                      ;
        POP     SI                      ;
        POP     CX                      ;
        POP     BX                      ;
        POP     AX                      ;
        RET                             ;
;HANDLE_DATA_WRITE       ENDP            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       SET_CPD_FONT_DATA
;
;       THIS ROUTINE IS USED TO SET THE COPY/SKIP VALUE
;       CONTAINED IN 'AX'.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET_CPD_FONT_DATA:                      ;
        PUSH    SI                      ;
        MOV     SI,[cs:TABLE_INDEX]     ;
        ADD     SI,SI                   ;
        MOV     [cs:CPD_FONT_DATA+SI],AX ;
        POP     SI                      ;
        RET                             ;
;SET_CPD_FONT_DATA       ENDP            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
