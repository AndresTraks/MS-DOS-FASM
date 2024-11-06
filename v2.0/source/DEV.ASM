;
; Device call routines for MSDOS
;

        ASSUME  SS:DOSGROUP,CS:DOSGROUP

;TITLE   DEV - Device call routines

        i_need  IOXAD,DWORD
        i_need  IOSCNT,WORD
        i_need  DEVIOBUF,4
        i_need  IOCALL,BYTE
        i_need  IOMED,BYTE
        i_need  IORCHR,BYTE
        i_need  CALLSCNT,WORD
        i_need  DMAAdd,DWORD
        i_need  NullDevPt,DWORD
        i_need  CallDevAd,DWORD
        i_need  Attrib,BYTE
        i_need  NULDEV,DWORD
        i_need  Name1,BYTE
        i_need  DevPt,DWORD
        i_need  DPBHead,DWORD
        i_need  NumIO,BYTE
        i_need  ThisDPB,DWORD
        i_need  DevCall,DWORD
        i_need  VerFlg,BYTE

;SUBTTL IOFUNC -- DO FUNCTION 1-12 I/O
PAGE
IOFUNC_RETRY:
ASSUME  DS:NOTHING,ES:NOTHING
        invoke  restore_world

        procedure   IOFUNC,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:SI Points to FCB
;       AH is function code
;               = 0 Input
;               = 1 Input Status
;               = 2 Output
;               = 3 Output Status
;               = 4 Flush
;       AL = character if output
; Function:
;       Perform indicated I/O to device or file
; Outputs:
;       AL is character if input
;       If a status call
;               zero set if not ready
;               zero reset if ready (character in AL for input status)
; For regular files:
;       Input Status
;               Gets character but restores fcb_RR field
;               Zero set on EOF
;       Input
;               Gets character advances fcb_RR field
;               Returns ^Z on EOF
;       Output Status
;               Always ready
; AX altered, all other registers preserved

        MOV     WORD [SS:IOXAD+2],SS
        MOV     WORD [SS:IOXAD],DEVIOBUF
        MOV     WORD [SS:IOSCNT],1
        MOV     WORD [SS:DEVIOBUF],AX

IOFUNC2:
        TEST    [SI+sys_fcb.fcb_DEVID],080H
        JNZ     IOTODEV
        JMP     IOTOFILE

IOTODEV:
        invoke  save_world
        PUSH    DS
        PUSH    SS
        POP     ES
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        XOR     BX,BX
        MOV     [IOCALL.REQSTAT],BX
        MOV     BYTE [IOMED],BL

        MOV     BX,IOCALL

        MOV     CX,(DEVRD SHL 8) OR DRDWRHL
        OR      AH,AH
        JZ      DCALLR
        MOV     CX,(DEVRDND SHL 8) OR DRDNDHL
        DEC     AH
        JZ      DCALLR
        MOV     CX,(DEVWRT SHL 8) OR DRDWRHL
        DEC     AH
        JZ      DCALLO
        MOV     CX,(DEVOST SHL 8) OR DSTATHL
        DEC     AH
        JZ      DCALLO
DFLUSH:
        MOV     CX,(DEVIFL SHL 8) OR DFLSHL
DCALLR:
        MOV     AH,86H
DCALL:
        MOV     [IOCALL.REQLEN],CL
        MOV     [IOCALL.REQFUNC],CH
        MOV     CL,AH
        POP     DS
ASSUME  DS:NOTHING
        CALL    DEVIOCALL
        MOV     DI,[SS:IOCALL.REQSTAT]
        TEST    DI,STERR
        JZ      OKDEVIO
        MOV     AH,CL
        invoke  CHARHARD
        CMP     AL,1
        JZ      IOFUNC_RETRY
;Know user must have wanted ignore. Make sure device shows ready so
;that DOS doesn't get caught in a status loop when user simply wants
;to ignore the error.
        AND     BYTE [SS:IOCALL.REQSTAT+1], NOT (STBUI SHR 8)
OKDEVIO:
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        CMP     CH,DEVRDND
        JNZ     DNODRD
        MOV     AL,BYTE [IORCHR]
        MOV     [DEVIOBUF],AL

DNODRD: MOV     AH,BYTE [IOCALL.REQSTAT+1]
        NOT     AH                      ; Zero = busy, not zero = ready
        AND     AH,STBUI SHR 8

        invoke  restore_world
ASSUME  DS:NOTHING
        MOV     AX,WORD [SS:DEVIOBUF]
        return

DCALLO:
        MOV     AH,87H
        JMP     SHORT DCALL

IOTOFILE:
ASSUME  DS:NOTHING
        OR      AH,AH
        JZ      IOIN
        DEC     AH
        JZ      IOIST
        DEC     AH
        JZ      IOUT
        return                  ; NON ZERO FLAG FOR OUTPUT STATUS

IOIST:
        PUSH    WORD [SI+sys_fcb.fcb_RR]        ; Save position
        PUSH    WORD [SI+sys_fcb.fcb_RR+2]
        CALL    IOIN
        POP     WORD [SI+sys_fcb.fcb_RR+2]      ; Restore position
        POP     WORD [SI+sys_fcb.fcb_RR]
        return

IOUT:
        CALL    SETXADDR
        invoke  _STORE
        invoke  FINNOSAV
        CALL    RESTXADDR       ; If you change this into a jmp don't come
IOUT_ret:
        return                  ; crying to me when things don't work ARR

IOIN:
        CALL    SETXADDR
        invoke  _LOAD
        PUSH    CX
        invoke  FINNOSAV
        POP     CX
        OR      CX,CX           ; Check EOF
        CALL    RESTXADDR
        MOV     AL,[SS:DEVIOBUF]   ; Get byte from trans addr
        jnz IOUT_ret
        MOV     AL,1AH          ; ^Z if EOF
        return

SETXADDR:
        POP     WORD [SS:CALLSCNT]     ; Return address
        invoke  save_world
        PUSH    WORD [SS:DMAADD]       ; Save Disk trans addr
        PUSH    WORD [SS:DMAADD+2]
        PUSH    DS
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     CX,WORD [IOXAD+2]
        MOV     WORD [DMAADD+2],CX
        MOV     CX,WORD [IOXAD]
        MOV     WORD [DMAADD],CX    ; Set byte trans addr
        MOV     CX,[IOSCNT]             ; ioscnt specifies length of buffer
        POP     DS
ASSUME  DS:NOTHING
        MOV     [SI+sys_fcb.fcb_RECSIZ],1           ; One byte per record
        MOV     DX,SI                   ; FCB to DS:DX
        invoke  GETRRPOS
        JMP     SHORT RESTRET           ; RETURN ADDRESS

RESTXADDR:
        POP     WORD [SS:CALLSCNT]     ; Return address
        POP     WORD [SS:DMAADD+2]     ; Restore Disk trans addr
        POP     WORD [SS:DMAADD]
        invoke  restore_world
RESTRET:JMP     WORD [SS:CALLSCNT]      ; Return address

;SUBTTL DEVIOCALL, DEVIOCALL2 - CALL A DEVICE
PAGE
        procedure   DEVIOCALL,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:SI Points to device FCB
;       ES:BX Points to request data
; Function:
;       Call the device
; Outputs:
;       None
; DS:SI,AX destroyed, others preserved

        LDS     SI,DWORD [SI+sys_fcb.fcb_FIRCLUS]

       entry   DEVIOCALL2
; As above only DS:SI points to device header on entry, and DS:SI is preserved
        MOV     AX,[SI+SYSDEV.SDEVSTRAT]
        MOV     WORD [SS:CALLDEVAD],AX
        MOV     WORD [SS:CALLDEVAD+2],DS
        CALL    DWORD [SS:CALLDEVAD]
        MOV     AX,[SI+SYSDEV.SDEVINT]
        MOV     WORD [SS:CALLDEVAD],AX
        CALL    DWORD [SS:CALLDEVAD]
        return

;SUBTTL DEVNAME - LOOK FOR NAME OF DEVICE
PAGE
        procedure   DEVNAME,NEAR
ASSUME  DS:DOSGROUP,ES:DOSGROUP

; Inputs:
;       DS,ES:DOSGROUP
;       Filename in NAME1
; Function:
;       Determine if file is in list of I/O drivers
; Outputs:
;       Carry set if name not found
;       ELSE
;       Zero flag set
;       BH = Bit 7,6 = 1, bit 5 = 0 (cooked mode)
;            bits 0-4 set from low byte of attribute word
;       DEVPT = DWORD pointer to Device header of device
; Registers BX destroyed

        PUSH    SI
        PUSH    DI
        PUSH    CX

        IF      KANJI
        PUSH    WORD [NAME1]
        CMP     [NAME1],5
        JNZ     NOKTR
        MOV     [NAME1],0E5H
NOKTR:
        END IF

        TEST    BYTE [ATTRIB],attr_volume_id ; If looking for VOL id don't find devs
        JNZ     RET31
        MOV     SI,NULDEV
LOOKIO:
ASSUME  DS:NOTHING
        TEST    [SI+SYSDEV.SDEVATT],DEVTYP
        JZ      SKIPDEV                 ; Skip block devices
        PUSH    SI
        ADD     SI,SYSDEV.SDEVNAME
        MOV     DI,NAME1
        MOV     CX,4                    ; All devices are 8 letters
        REPE    CMPSW                   ; Check for name in list
        POP     SI
        JZ      IOCHK                   ; Found it?
SKIPDEV:
        LDS     SI,DWORD [SI]       ; Get address of next device
        CMP     SI,-1                   ; At end of list?
        JNZ     LOOKIO
RET31:  STC                             ; Not found
RETNV:  PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP

        IF      KANJI
        POP     WORD [NAME1]
        END IF

        POP     CX
        POP     DI
        POP     SI
        RET

IOCHK:
ASSUME  DS:NOTHING
        MOV     WORD [SS:DEVPT+2],DS         ; Save pointer to device
        MOV     BH,BYTE [SI+SYSDEV.SDEVATT]
        OR      BH,0C0H
        AND     BH,NOT 020H             ;Clears Carry
        MOV     WORD [SS:DEVPT],SI
        JMP     RETNV

        procedure   GETBP,NEAR
ASSUME  DS:DOSGROUP,ES:NOTHING

; Inputs:
;       AL = Logical unit number (A = 0)
; Function:
;       Find Drive Parameter Block
; Outputs:
;       ES:BP points to DPB
;       [THISDPB] = ES:BP
;       Carry set if unit number bad
; No other registers altered

        LES     BP,[DPBHEAD]    ; Just in case drive isn't valid
        AND     AL,3FH          ; Mask out dirty and device bits
        CMP     AL,BYTE [NUMIO]
        CMC
        JC      GOTDPB          ; Get drive A
FNDDPB:
        CMP     AL,[ES:BP+dpb.dpb_drive]
        JZ      GOTDPB          ; Carry is clear if jump executed
        LES     BP,[ES:BP+dpb.dpb_next_dpb]
        JMP     SHORT FNDDPB
GOTDPB:
        MOV     WORD [THISDPB],BP
        MOV     WORD [THISDPB+2],ES
        RET

;SUBTTL SETREAD, SETWRITE -- SET UP HEADER BLOCK
PAGE
        procedure   SETREAD,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:BX = Transfer Address
;       CX = Record Count
;       DX = Starting Record
;       AH = Media Byte
;       AL = Unit Code
; Function:
;       Set up the device call header at DEVCALL
; Output:
;       ES:BX Points to DEVCALL
; No other registers effected

        PUSH    DI
        PUSH    CX
        PUSH    AX
        MOV     CL,DEVRD
SETCALLHEAD:
        MOV     AL,DRDWRHL
        PUSH    SS
        POP     ES
        MOV     DI,DEVCALL
        STOSB                   ; length
        POP     AX
        STOSB                   ; Unit
        PUSH    AX
        MOV     AL,CL
        STOSB                   ; Command code
        XOR     AX,AX
        STOSW                   ; Status
        ADD     DI,8            ; Skip link fields
        POP     AX
        XCHG    AH,AL
        STOSB                   ; Media byte
        XCHG    AL,AH
        PUSH    AX
        MOV     AX,BX
        STOSW
        MOV     AX,DS
        STOSW                   ; Transfer addr
        POP     CX              ; Real AX
        POP     AX              ; Real CX
        STOSW                   ; Count
        XCHG    AX,DX           ; AX=Real DX, DX=real CX, CX=real AX
        STOSW                   ; Start
        XCHG    AX,CX
        XCHG    DX,CX
        POP     DI
        MOV     BX,DEVCALL
        RET

        entry   SETWRITE
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:BX = Transfer Address
;       CX = Record Count
;       DX = Starting Record
;       AH = Media Byte
;       AL = Unit Code
; Function:
;       Set up the device call header at DEVCALL
; Output:
;       ES:BX Points to DEVCALL
; No other registers effected

        PUSH    DI
        PUSH    CX
        PUSH    AX
        MOV     CL,DEVWRT
        ADD     CL,[SS:VERFLG]
        JMP     SHORT SETCALLHEAD

do_ext
