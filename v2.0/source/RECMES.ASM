FALSE   =     0
TRUE    =     -1


bdos    =     21h
boot    =     20h
aread   =     25h
awrite  =     26h


;The DOST: prefix is a DEC TOPS/20 directory prefix. Remove it for
;   assembly in MS-DOS assembly environments using MASM. The DOSSYM.ASM
;   file must exist though, it is included with OEM distribution.

if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_DATA
end if



cr      =     0dh
lf      =     0ah

if SEGSEL = S_CODE
        ASSUME  cs:dg,ds:dg,es:dg,ss:dg


hecode  db      0

dskwrt: push    ax
        push    bx
        push    cx
        push    dx
        int     awrite
        mov     [hecode],al
        inc     sp
        inc     sp      ;clean up stack
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        jnc     mespret
        mov     si, WRITING
        call    DSKERR
        jz      dskwrt
        clc
mespret:   ret

dskrd:  push    ax
        push    bx
        push    cx
        push    dx
        int     aread
        mov     [hecode],al
        inc     sp
        inc     sp      ;clean up stack
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        jnc     mespret
        mov     si, READING
        call    DSKERR
        jz      dskrd
        clc
        ret

DSKERR:
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    ES
        CALL    pcrlf
        MOV     AL,[hecode]
        CMP     AL,12
        JBE     HAVCOD
        MOV     AL,12
HAVCOD:
        XOR     AH,AH
        MOV     DI,AX
        SHL     DI,1
        MOV     DX,word [DI+MESBAS] ; Get pointer to error message
        CALL    print          ; Print error type
        MOV     DX,ERRMES
        CALL    print
        MOV     DX,SI
        CALL    print
        MOV     DX,DRVMES
        CALL    print
ASK:
        MOV     DX,REQUEST
        CALL    print
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8)+STD_CON_INPUT
        INT     21H             ; Get response
        PUSH    AX
        CALL    pcrlf
        POP     AX
        OR      AL,20H          ; Convert to lower case
        CMP     AL,"i"          ; Ignore?
        JZ      EEXITNZ
        CMP     AL,"r"          ; Retry?
        JZ      EEXIT
        CMP     AL,"a"          ; Abort?
        JNZ     ASK
        JMP     int_23

EEXITNZ:
        OR      AL,AL           ; Resets zero flag
EEXIT:
        POP     ES
        POP     DI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET

;******************************************
; Prints the XXX of YYY bytes recovered message.
; The XXX value is a dword at di+16 on entry.
; The YYY value is a dword (declared as a word) at filsiz.
; Note:
;       If it is desired to print a message before the first number,
;          point at the message with DX and call PRINT.

report:
        mov     si,[di+16]      ;Get the XXX value
        mov     di,[di+18]
        mov     bx, ofmsg
        call    convert         ;Print "XXX of "  (DI:SI followed by message
                                ;                  pointed to by BX)
        mov     si,[filsiz]       ;Get the YYY value
        mov     di,[filsiz+2]
        mov     bx, endmsg
        call    convert         ;Print "YYY bytes recovered CR LF"
        ret

end if

if SEGSEL = S_CONST


MESBAS  DW      ERR0
        DW      ERR1
        DW      ERR2
        DW      ERR3
        DW      ERR4
        DW      ERR5
        DW      ERR6
        DW      ERR7
        DW      ERR8
        DW      ERR9
        DW      ERR10
        DW      ERR11
        DW      ERR12

READING DB      "read$"
WRITING DB      "writ$"
ERRMES  DB      " error $"
DRVMES  DB      "ing drive "
DRVLET1 DB      "A",13,10,"$"
REQUEST DB      "Abort, Retry, Ignore? $"

ERR0    DB      "Write protect$"
ERR1    DB      "Bad unit$"
ERR2    DB      "Not ready$"
ERR3    DB      "Bad command$"
ERR4    DB      "Data$"
ERR5    DB      "Bad call format$"
ERR6    DB      "Seek$"
ERR7    DB      "Non-DOS disk$"
ERR8    DB      "Sector not found$"
ERR9    DB      "No paper$"
ERR10   DB      "Write fault$"
ERR11   DB      "Read fault$"
ERR12   DB      "Disk$"

;-----------------------------------------------------------------------;

BADVER  DB      "Incorrect DOS version"
crlf    db      cr,lf,'$'
askmsg  db      cr,lf,'Press any key to begin recovery of the'
        db      cr,lf,'file(s) on drive '
drvlet  db      'A: ',cr,lf,cr,lf,'$'
dirmsg  db      cr,lf,'Warning - directory full',cr,lf,'$'

;"recmsg_pre<number of files recovered>recmsg_post"
recmsg_post     db      ' file(s) recovered',cr,lf
recmsg_pre      db      '$'

ofmsg   db      ' of $'
endmsg  db      ' bytes recovered',13,10,"$"

drverr  db      'Invalid number of parameters$'
baddrv  db      'Invalid drive or file name$'
opnerr  db      'File not found$'


end if
