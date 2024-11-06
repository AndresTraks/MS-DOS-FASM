;
; buffer management for MSDOS
;


        ASSUME  SS:DOSGROUP,CS:DOSGROUP

        i_need  BuffHead,DWORD
        i_need  PreRead,WORD
        i_need  LastBuffer,DWORD
        i_need  CurBuf,DWORD
        i_need  WPErr,BYTE

;SUBTTL SETVISIT,SKIPVISIT -- MANAGE BUFFER SCANS
PAGE
        procedure   SETVISIT,near
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       None
; Function:
;       Set up a scan of I/O buffers
; Outputs:
;       All visit flags = 0
;               NOTE: This pre-scan is needed because a hard disk error
;                     may cause a scan to stop in the middle leaving some
;                     visit flags set, and some not set.
;       DS:DI Points to [BUFFHEAD]
; No other registers altered

        LDS     DI,[SS:BUFFHEAD]
        PUSH    AX
        XOR     AX,AX
SETLOOP:
        MOV     [DI+BUFFINFO.VISIT],AL
        LDS     DI,[DI+BUFFINFO.NEXTBUF]
        CMP     DI,-1
        JNZ     SETLOOP
        LDS     DI,[SS:BUFFHEAD]
        POP     AX
SETLOOP_ret:
        return

        entry   SKIPVISIT
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DI Points to a buffer
; Function:
;       Skip visited buffers
; Outputs:
;       DS:DI Points to next unvisited buffer
;       Zero is set if skip to LAST buffer
; No other registers altered

        CMP     DI,-1
        jz SETLOOP_ret
        CMP     [DI+BUFFINFO.VISIT],1
        jnz SETLOOP_ret
        LDS     DI,[DI+BUFFINFO.NEXTBUF]
        JMP     SHORT SKIPVISIT
        return


;SUBTTL SCANPLACE, PLACEBUF -- PUT A BUFFER BACK IN THE POOL
PAGE
        procedure   SCANPLACE,near
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       Same as PLACEBUF
; Function:
;       Save scan location and call PLACEBUF
; Outputs:
;       DS:DI Points to saved scan location
; SI destroyed, other registers unchanged

        PUSH    ES
        LES     SI,[DI+BUFFINFO.NEXTBUF]         ; Save scan location
        CALL    PLACEBUF
        PUSH    ES
        POP     DS                      ; Restore scan location
        MOV     DI,SI
        POP     ES
        return

NRETJ:  JMP     SHORT NRET

        procedure   PLACEBUF,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Input:
;       DS:DI points to buffer
; Function:
;       Remove buffer from queue and re-insert it in proper place.
;       If buffer doesn't go at end, and isn't free, decrement
;       priorities.
; NO registers altered
;
; DS:SI -- Curbuf, current buffer in list
; ES:DI -- Buf, buffer passed as argument
; BP:CX -- Pointsave, saved Buf.nextbuf
; DX:BX -- Lastbuf, previous buffer in list
; AL    -- Inserted, Buf has been inserted
; AH    -- Removed, Buf has been removed

        IF      IBM
        IF      IBM = 0
        invoke  save_world
        XOR     AX,AX           ; Inserted = Removed = FALSE
        LES     CX,[DI+BUFFINFO.NEXTBUF]
        MOV     BP,ES           ; Pointsave = Buf.nextbuf
        MOV     SI,DS
        MOV     ES,SI           ; Buf is ES:DI
        LDS     SI,[SS:BUFFHEAD]   ; Curbuf = HEAD
        CALL    POINTCOMP       ; Buf == HEAD?
        JNZ     TNEWHEAD
        CMP     CX,-1           ; Buf is LAST?
        JZ      NRETJ           ; Only one buffer, nothing to do
        MOV     WORD [SS:BUFFHEAD],CX
        MOV     WORD [SS:BUFFHEAD+2],BP        ; HEAD = Pointsave
        INC     AH              ; Removed = TRUE
        MOV     DS,BP
        MOV     SI,CX           ; Curbuf = HEAD
TNEWHEAD:
        MOV     BL,[ES:DI.BUFPRI]
        CMP     BL,[SI.BUFPRI]
        JGE     BUFLOOP
NEWHEAD:                        ; If Buf.pri < HEAD.pri
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF],SI
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF+2],DS   ; Buf.nextbuf = HEAD
        MOV     WORD [SS:BUFFHEAD],DI
        MOV     WORD [SS:BUFFHEAD+2],ES        ; HEAD = Buf
        INC     AL                              ; Inserted = TRUE
        OR      AH,AH
        JNZ     NRET            ; If Removed == TRUE
BUFLOOP:
        PUSH    DS
        PUSH    SI
        LDS     SI,[SI+BUFFINFO.NEXTBUF]
        CALL    POINTCOMP
        POP     SI
        POP     DS
        JNZ     TESTINS
        MOV     WORD [SI+BUFFINFO.NEXTBUF],CX        ; If Curbuf.nextbuf == buf
        MOV     WORD [SI+BUFFINFO.NEXTBUF+2],BP      ; Curbuf.nextbuf = Pointsave
        INC     AH              ; Removed = TRUE
        OR      AL,AL
        JNZ     SHUFFLE         ; If Inserted == TRUE
TESTINS:
        OR      AL,AL
        JNZ     LOOKBUF
        PUSH    CX              ; If NOT Inserted
        MOV     CL,[ES:DI.BUFPRI]
        CMP     CL,[SI.BUFPRI]
        POP     CX
        JGE     LOOKBUF
        PUSH    DS              ; If Buf.pri < Curbuf.pri
        MOV     DS,DX
        MOV     WORD [BX.NEXTBUF],DI
        MOV     WORD [BX.NEXTBUF+2],ES      ; Lastbuf.nextbuf = Buf
        POP     DS
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF],SI
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF+2],DS   ; Buf.nextbuf = Curbuf
        INC     AL              ; Inserted = TRUE
        OR      AH,AH
        JNZ     SHUFFLE         ; If Removed == TRUE
LOOKBUF:
        MOV     BX,SI
        MOV     DX,DS           ; Lastbuf = Curbuf
        CMP     WORD [SI+BUFFINFO.NEXTBUF],-1
        JZ      ISLAST
        LDS     SI,[SI+BUFFINFO.NEXTBUF] ; Curbuf = Curbuf.nextbuf
        JMP     SHORT BUFLOOP
ISLAST:                 ; If Curbuf is LAST
        MOV     WORD [SI+BUFFINFO.NEXTBUF],DI
        MOV     WORD [SI+BUFFINFO.NEXTBUF+2],ES      ; Curbuf.nextbuf = Buf
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF],-1
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF+2],-1      ; Buf is LAST
NRET:
        invoke  restore_world
        return

SHUFFLE:
        LDS     DI,[SS:BUFFHEAD]
DECLOOP:
        CMP     [DI.BUFPRI],FREEPRI
        JZ      NODEC
        DEC     [DI.BUFPRI]
NODEC:
        LDS     DI,[DI+BUFFINFO.NEXTBUF]
        CMP     DI,-1
        JNZ     DECLOOP
        JMP     SHORT NRET
        END     IF
        END     IF

        invoke  save_world
        LES     CX,[DI+BUFFINFO.NEXTBUF]
        CMP     CX,-1           ; Buf is LAST?
        JZ      NRET            ; Buffer already last
        MOV     BP,ES           ; Pointsave = Buf.nextbuf
        PUSH    DS
        POP     ES              ; Buf is ES:DI
        LDS     SI,[SS:BUFFHEAD]   ; Curbuf = HEAD
        CALL    POINTCOMP       ; Buf == HEAD?
        JNZ     BUFLOOP2
        MOV     WORD [SS:BUFFHEAD],CX
        MOV     WORD [SS:BUFFHEAD+2],BP        ; HEAD = Pointsave
        JMP     SHORT LOOKEND

BUFLOOP2:
        PUSH    DS
        PUSH    SI
        LDS     SI,[SI+BUFFINFO.NEXTBUF]
        CALL    POINTCOMP
        JZ      GOTTHEBUF
        POP     AX
        POP     AX
        JMP     SHORT BUFLOOP2

GOTTHEBUF:
        POP     SI
        POP     DS
        MOV     WORD [SI+BUFFINFO.NEXTBUF],CX        ; If Curbuf.nextbuf == buf
        MOV     WORD [SI+BUFFINFO.NEXTBUF+2],BP      ; Curbuf.nextbuf = Pointsave
LOOKEND:
        PUSH    DS
        PUSH    SI
        LDS     SI,[SI+BUFFINFO.NEXTBUF]
        CMP     SI,-1
        JZ      GOTHEEND
        POP     AX
        POP     AX
        JMP     SHORT LOOKEND

GOTHEEND:
        POP     SI
        POP     DS
        MOV     WORD [SI+BUFFINFO.NEXTBUF],DI
        MOV     WORD [SI+BUFFINFO.NEXTBUF+2],ES      ; Curbuf.nextbuf = Buf
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF],-1
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF+2],-1      ; Buf is LAST
NRET:
        invoke  restore_world
NRET_ret:
        return

        procedure   PLACEHEAD,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; SAME AS PLACEBUF except places buffer at head

        invoke  save_world
        PUSH    DS
        POP     ES
        LDS     SI,[SS:BUFFHEAD]
        MOV     WORD [SS:BUFFHEAD],DI
        MOV     WORD [SS:BUFFHEAD+2],ES
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF],SI
        MOV     WORD [ES:DI+BUFFINFO.NEXTBUF+2],DS
LOOKEND2:
        PUSH    DS
        PUSH    SI
        LDS     SI,[SI+BUFFINFO.NEXTBUF]
        CALL    POINTCOMP
        JZ      GOTHEEND2
        POP     AX
        POP     AX
        JMP     SHORT LOOKEND2

GOTHEEND2:
        POP     SI
        POP     DS
        MOV     WORD [SI+BUFFINFO.NEXTBUF],-1
        MOV     WORD [SI+BUFFINFO.NEXTBUF+2],-1      ; Buf is LAST
        JMP     SHORT NRET

;SUBTTL POINTCOMP -- 20 BIT POINTER COMPARE
PAGE
        procedure   POINTCOMP,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Compare DS:SI to ES:DI (or DS:DI to ES:SI) for equality
; DO NOT USE FOR < or >
; No Registers altered

        CMP     SI,DI
        jnz NRET_ret
        PUSH    CX
        PUSH    DX
        MOV     CX,DS
        MOV     DX,ES
        CMP     CX,DX
        POP     DX
        POP     CX
        return

;SUBTTL GETBUFFR -- GET A SECTOR INTO A BUFFER
PAGE
        procedure   GETBUFFR,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Input:
;       AH = Priority buffer is to have
;       AL = 0 means sector must be pre-read
;          ELSE no pre-read
;       DX = Desired physical sector number
;       ES:BP = Pointer to drive parameters
; Function:
;       Get the specified sector into one of the I/O buffers
;       And shuffle the queue
; Output:
;       [CURBUF] Points to the Buffer for the sector
; DX,ES:BP unchanged, all other registers destroyed

        XOR     SI,SI
        entry   GETBUFFRB
        MOV     [PREREAD],AX
        MOV     AL,[ES:BP+dpb.dpb_drive]
        LDS     DI,[LASTBUFFER]
ASSUME  DS:NOTHING
        CMP     DI,-1                           ; Recency pointer valid?
        JZ      SKBUF                           ; No
        CMP     DX,[DI+BUFFINFO.BUFSECNO]
        JNZ     SKBUF                           ; Wrong sector
        CMP     AL,[DI+BUFFINFO.BUFDRV]
        JNZ     SKBUF                           ; Wrong Drive
        JMP     SHORT JUSTBUF                   ; Just asked for same buffer
SKBUF:
        LDS     DI,[SS:BUFFHEAD]
NXTBFF:
        CMP     DX,[DI+BUFFINFO.BUFSECNO]
        JNZ     BUMP
        CMP     AL,[DI+BUFFINFO.BUFDRV]
        JNZ     BUMP
        JMP     SHORT SETINF
BUMP:
        LDS     DI,[DI+BUFFINFO.NEXTBUF]
        CMP     DI,-1
        JNZ     NXTBFF
        LDS     DI,[SS:BUFFHEAD]
        PUSH    SI
        PUSH    DX
        PUSH    BP
        PUSH    ES
        CALL    BUFWRITE        ; Write out the dirty buffer
        POP     ES
        POP     BP
        POP     DX
        POP     SI
RDSEC:                          ; Read in the new sector
        TEST    BYTE [SS:PREREAD],-1
        JNZ     SETBUF
        LEA     BX,[DI+BUFINSIZ]        ; Point at buffer
        MOV     CX,1
        PUSH    SI
        PUSH    DI
        PUSH    DX
        OR      SI,SI
        JZ      NORMSEC
        invoke  FATSECRD
        JMP     SHORT GOTTHESEC         ; Buffer is marked free if read barfs
NORMSEC:
        invoke  DREAD                   ; Buffer is marked free if read barfs
GOTTHESEC:
        POP     DX
        POP     DI
        POP     SI
SETBUF:
        MOV     [DI+BUFFINFO.BUFSECNO],DX
        MOV     WORD [DI+BUFFINFO.BUFDRVDP],BP
        MOV     WORD [DI+BUFFINFO.BUFDRVDP+2],ES
        XOR     AH,AH
        MOV     AL,[ES:BP+dpb.dpb_drive]
        MOV     WORD [DI+BUFFINFO.BUFDRV],AX
SETINF:
        MOV     AX,1                            ; Default to not a FAT sector
        OR      SI,SI
        JZ      SETSTUFFOK
        MOV     AL,[ES:BP+dpb.dpb_FAT_count]
        MOV     AH,[ES:BP+dpb.dpb_FAT_size]
SETSTUFFOK:
        MOV     WORD [DI+BUFFINFO.BUFWRTCNT],AX
        CALL    PLACEBUF
JUSTBUF:
        MOV     WORD [SS:CURBUF+2],DS
        MOV     WORD [SS:LASTBUFFER+2],DS
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     WORD [CURBUF],DI
        MOV     WORD [LASTBUFFER],DI
        return


;SUBTTL FLUSHBUF -- WRITE OUT DIRTY BUFFERS
PAGE
        procedure   FLUSHBUF,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Input:
;       DS = DOSGROUP
;       AL = Physical unit number
;          = -1 for all units
; Function:
;       Write out all dirty buffers for unit, and flag them as clean
; DS Preserved, all others destroyed (ES too)

        LDS     DI,[BUFFHEAD]
ASSUME  DS:NOTHING
        MOV     AH,-1
NXTBUFF:
        CMP     [DI+BUFFINFO.BUFDRV],AH
        JZ      SKIPBFF                 ; Skip free buffers
        CMP     AH,AL
        JZ      DOBUFFER                ; Do all dirty buffers
        CMP     AL,[DI+BUFFINFO.BUFDRV]
        JNZ     SKIPBFF                 ; Buffer not for this unit
DOBUFFER:
        CMP     BYTE [DI+BUFFINFO.BUFDIRTY],0
        JZ      SKIPBFF                 ; Buffer not dirty
        PUSH    AX
        PUSH    WORD [DI+BUFFINFO.BUFDRV]
        CALL    BUFWRITE
        POP     AX
        XOR     AH,AH                   ; Buffer is clean
        CMP     AL,BYTE [SS:WPERR]
        JNZ     NOZAP
        MOV     AL,0FFH                 ; Invalidate buffer, it is inconsistent
NOZAP:
        MOV     WORD [DI+BUFFINFO.BUFDRV],AX
        POP     AX                      ; Search info
SKIPBFF:
        LDS     DI,[DI+BUFFINFO.NEXTBUF]
        CMP     DI,-1
        JNZ     NXTBUFF
        PUSH    SS
        POP     DS
SKIPBFF_ret:
        return


;SUBTTL BUFWRITE -- WRITE OUT A BUFFER IF DIRTY
PAGE
        procedure   BUFWRITE,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Input:
;       DS:DI Points to the buffer
; Function:
;       Write out all the buffer if dirty.
; Output:
;       Buffer marked free
; DS:DI Preserved, ALL others destroyed (ES too)

        MOV     AX,00FFH
        XCHG    AX,WORD [DI+BUFFINFO.BUFDRV] ; Free, in case write barfs
        CMP     AL,0FFH
        jz SKIPBFF_ret                  ; Buffer is free.
        OR      AH,AH
        jz SKIPBFF_ret                  ; Buffer is clean.
        CMP     AL,BYTE [SS:WPERR]
        jz SKIPBFF_ret                  ; If in WP error zap buffer
        LES     BP,[DI+BUFFINFO.BUFDRVDP]
        LEA     BX,[DI+BUFINSIZ]        ; Point at buffer
        MOV     DX,[DI+BUFFINFO.BUFSECNO]
        MOV     CX,WORD [DI+BUFFINFO.BUFWRTCNT]
        MOV     AL,CH                   ; [DI.BUFWRTINC]
        XOR     CH,CH
        MOV     AH,CH
        PUSH    DI
WRTAGAIN:
        PUSH    CX
        PUSH    AX
        MOV     CX,1
        PUSH    BX
        PUSH    DX
        invoke  DWRITE          ; Write out the dirty buffer
        POP     DX
        POP     BX
        POP     AX
        POP     CX
        ADD     DX,AX
        LOOP    WRTAGAIN
        POP     DI
        return

do_ext
