
FALSE   =     0
TRUE    =     -1



;
bdos    =     21h
boot    =     20h
aread   =     25h
awrite  =     26h

cr      =     0dh
lf      =     0ah
;

if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_DATA
end if


if SEGSEL = S_CODE
        ASSUME  cs:DG,ds:DG,es:DG,ss:DG


promptyn:
;Prompt message in DX
;Prompt user for Y or N answer. Zero set if Y
        CALL    print
PAGAIN:
        MOV     DX,YES_NO
        CALL    print
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8)+STD_CON_INPUT
        INT     21H
        PUSH    AX
        CALL    pcrlf
        POP     AX
        OR      AL,20H          ;Convert to lower case
        CMP     AL,'y'
        JZ      GOTANS
        CMP     AL,'n'
        JZ      GOTNANS
        JMP     PAGAIN
GOTNANS:
        OR      AL,AL           ;Reset zero
GOTANS:
        RET

hecode  db      0
tcount  dw      0

dskrd:
        mov     byte [CS:DRVLET],"A"
        add     [CS:DRVLET],al
        mov     [CS:tcount],cx
        push    ds
        push    cx
        push    dx
nxtrd:
        push    ax
        push    bx
        push    dx
        mov     cx,[CS:sec64k]
        cmp     cx,[CS:tcount]
        jbe     gotrcnt
        mov     cx,[CS:tcount]
gotrcnt:
        push    cx
        int     aread
        mov     [CS:hecode],al
        inc     sp
        inc     sp      ;clean up stack
        pop     cx
        pop     dx
        pop     bx
        pop     ax
        jnc     rdok
        mov     si, READING
        call    DSKERR
        jz      nxtrd   ;Repeat this 64K read
rdok:
        sub     [CS:tcount],cx
        jbe     dskret
        add     dx,cx
        push    dx
        push    ax
        mov     ax,[CS:secsiz]
        mul     cx          ;ax byte count of transfer (know transfer <= 64K)
        or      dl,dl
        jnz     exact64
        push    ax
        mov     cl,4
        shr     ax,cl
        mov     cx,ds
        add     cx,ax
        mov     ds,cx
        pop     cx
        and     cx,0FH
        add     bx,cx
        jnc     popgo
exact64:
        mov     cx,ds
        add     cx,1000H
        mov     ds,cx
popgo:
        pop     ax
        pop     dx
        jmp     nxtrd

dskret:
        pop     dx
        pop     cx
        pop     ds
        clc
        ret


dskwrt:
        mov     byte [CS:DRVLET],"A"
        add     [CS:DRVLET],al
        mov     [CS:tcount],cx
        push    ds
        push    cx
        push    dx
nxtwrt:
        push    ax
        push    bx
        push    dx
        mov     cx,[CS:sec64k]
        cmp     cx,[CS:tcount]
        jbe     gotwcnt
        mov     cx,[CS:tcount]
gotwcnt:
        push    cx
        int     awrite
        mov     [CS:hecode],al
        inc     sp
        inc     sp      ;clean up stack
        pop     cx
        pop     dx
        pop     bx
        pop     ax
        jnc     wrtok
        mov     si, WRITING
        call    DSKERR
        jz      nxtwrt  ;Repeat this 64K write
wrtok:
        sub     [CS:tcount],cx
        jbe     dskret
        add     dx,cx
        push    dx
        push    ax
        mov     ax,[CS:secsiz]
        mul     cx          ;ax byte count of transfer (know transfer <= 64K)
        or      dl,dl
        jnz     exact64w
        push    ax
        mov     cl,4
        shr     ax,cl
        mov     cx,ds
        add     cx,ax
        mov     ds,cx
        pop     cx
        and     cx,0FH
        add     bx,cx
        jnc     popgow
exact64w:
        mov     cx,ds
        add     cx,1000H
        mov     ds,cx
popgow:
        pop     ax
        pop     dx
        jmp     nxtwrt


DSKERR:
        PUSH    DS
        PUSH    CS
        POP     DS
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    ES
        CALL    pcrlf
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
        MOV     DX, ERRMES
        CALL    print
        MOV     DX,SI
        CALL    print
        MOV     DX, DRVMES
        CALL    print
ASK:
        MOV     DX, REQUEST
        CALL    print
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8)+STD_CON_INPUT
        INT     21H             ; Get response
        OR      AL,20H          ; Convert to lower case
        PUSH    AX
        CALL    pcrlf
        CALL    pcrlf
        POP     AX
        CMP     AL,"i"          ; Ignore?
        JZ      EEXITNZ
        CMP     AL,"r"          ; Retry?
        JZ      EEXIT
        CMP     AL,"a"          ; Abort?
        JNZ     ASK
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX
        CLI
        mov     ss,ax
        mov     sp,100h         ; Reset stack
        STI
        MOV     DX,ABMES
        JMP     ASKANOTHER

EEXITNZ:
        OR      AL,AL           ; Resets zero flag
EEXIT:
        POP     ES
        POP     DI
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        POP     DS
        RET


end if

if SEGSEL = S_CONST


MESBAS  DW       ERR0
        DW       ERR1
        DW       ERR2
        DW       ERR3
        DW       ERR4
        DW       ERR5
        DW       ERR6
        DW       ERR7
        DW       ERR8
        DW       ERR9
        DW       ERR10
        DW       ERR11
        DW       ERR12

READING DB      "read$"
WRITING DB      "writ$"
ERRMES  DB      " error $"
DRVMES  DB      "ing drive "
DRVLET  DB      "A$"
REQUEST DB      13,10,"Abort, Retry, Ignore? $"

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

YES_NO  DB      "(Y/N)? $"
anoprompt db    cr,lf,'Copy another $'
cpymsg  db      cr,lf,cr,lf,'Copying...$'
good1   db      cr,lf,cr,lf
goodmsg db      'Copy complete',cr,lf,'$'
ABMES   db      'Copy not completed',cr,lf,'$'
srcmsg  db      cr,lf,cr,lf,'Insert source diskette in drive '
srclet  db      'A:$'
fdstmsg db      cr,lf,'Insert formatted target diskette in drive '
fdstlet db      'A:$'
dstmsg  db      cr,lf,'Insert target diskette in drive '
dstlet  db      'A:$'
keymsg  db      cr,lf,'Strike any key when ready $'
drverr1 db      cr,lf,'Invalid drive specification',cr,lf,'$'
drverr3 db      cr,lf,cr,lf,'Source and target disks are not the'
        db      cr,lf,'  same format. Cannot do the copy.'
crlf    db      cr,lf,'$'

end if
