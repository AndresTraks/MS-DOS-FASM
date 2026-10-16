




if SEGSEL = S_DATARES
end if


if SEGSEL = S_TRANDATA
end if


if SEGSEL = S_TRANSPACE
end if


; **************************************************
; COPY CODE
;


if SEGSEL = S_TRANCODE






ASSUME  CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

DOMELCOPY:
        cmp     [MELCOPY],0FFH
        jz      CONTMEL
        mov     SI,[SRCPT]
        mov     [MELSTART],si
        mov     [MELCOPY],0FFH
CONTMEL:
        xor     BP,BP
        mov     si,[SRCPT]
        mov     bl,'+'
SCANSRC2:
        mov     di,SCANBUF
        call    CPARSE
        test    bh,80H
        jz      NEXTMEL                 ; Go back to start
        test    bh,1                    ; Switch ?
        jnz     SCANSRC2                ; Yes
        call    SOURCEPROC
        call    RESTUDIR1
        mov     di,DESTFCB2
        mov     ax,Parse_File_Descriptor SHL 8
        INT     int_command
        mov     bx,SDIRBUF + 1
        mov     si,DESTFCB2 + 1
        mov     di,[SRCTAIL]
        call    BUILDNAME
        jmp     MELDO


NEXTMEL:
        call    CLOSEDEST
        xor     ax,ax
        mov     [CFLAG],al
        mov     [NXTADD],ax
        mov     [DESTCLOSED],al
        mov     si,[MELSTART]
        mov     [SRCPT],si
        call    SEARCHNEXT
        jz      SETNMELJ
        jmp     ENDCOPY2
SETNMELJ:
        jmp     SETNMEL

COPY:
; First order of buisness is to find out about the destination
ASSUME  DS:TRANGROUP,ES:TRANGROUP
        xor     ax,ax
        mov     [ALLSWITCH],AX          ; no switches
        mov     [ARGC],al               ; no arguments
        mov     [PLUS],al               ; no concatination
        mov     [BINARY],al             ; Binary not specifically specified
        mov     [ASCII],al              ; ASCII not specifically specified
        mov     [FILECNT],ax            ; No files yet
        mov     [WRITTEN],al            ; Nothing written yet
        mov     [CONCAT],al             ; No concatination
        mov     [MELCOPY],al            ; Not a Mel Hallerman copy
        mov     word [SCANBUF],ax   ; Init buffer
        mov     word [DESTBUF],ax   ; Init buffer
        mov     word [SRCBUF],ax    ; Init buffer
        mov     word [SDIRBUF],ax   ; Init buffer
        mov     word [DIRBUF],ax    ; Init buffer
        mov     word [DESTFCB],ax   ; Init buffer
        dec     ax
        mov     [FRSTSRCH],al           ; First search call
        mov     [FIRSTDEST],al          ; First time
        mov     [DESTISDIR],al          ; Don't know about dest
        mov     si,81H
        mov     bl,'+'                  ; include '+' as a delimiter
DESTSCAN:
        xor     bp,bp                   ; no switches
        mov     di,SCANBUF
        call    CPARSE
        PUSHF                           ; save flags
        test    bh,80H                  ; A '+' argument?
        jz      NOPLUS                  ; no
        mov     [PLUS],1                ; yes
NOPLUS:
        POPF                            ; get flags back
        jc      CHECKDONE               ; Hit CR?
        test    bh,1                    ; Switch?
        jz      TESTP2                  ; no
        or      [DESTSWITCH],BP         ; Yes, assume destination
        or      [ALLSWITCH],BP          ; keep tabs on all switches
        jmp     short DESTSCAN

TESTP2:
        test    bh,80H                  ; Plus?
        jnz     GOTPLUS                 ; Yes, not a separate arg
        inc     [ARGC]                  ; found a real arg
GOTPLUS:
        push    SI
        mov     ax,[STARTEL]
        mov     SI,SCANBUF ; Adjust to copy
        sub     ax,SI
        mov     DI,DESTBUF
        add     ax,DI
        mov     [DESTTAIL],AX
        mov     [DESTSIZ],cl            ; Save its size
        inc     cx                      ; Include the NUL
        rep     movsb                   ; Save potential destination
        mov     [DESTINFO],bh           ; Save info about it
        mov     [DESTSWITCH],0          ; reset switches
        pop     SI
        jmp     short DESTSCAN          ; keep going

CHECKDONE:
        mov     al,[PLUS]
        mov     [CONCAT],al             ; PLUS -> Concatination
        shl     al,1
        shl     al,1
        mov     [INEXACT],al            ; CONCAT -> inexact copy
        mov     dx,BADARGS
        mov     al,[ARGC]
        or      al,al                   ; Good number of args?
        jz      CERROR4J                ; no, not enough
        cmp     al,2
        jbe     ACOUNTOK
CERROR4J:
        jmp    CERROR                   ; no, too many
ACOUNTOK:
        mov     bp,DESTVARS
        cmp     al,1
        jnz     GOT2ARGS
        mov     al,[CURDRV]             ; Dest is default drive:*.*
        add     al,'A'
        mov     ah,':'
        mov     [bp+VARSTRUC.SIZ],2
        mov     di,DESTBUF
        stosw
        mov     [DESTSWITCH],0          ; no switches on dest
        mov     [bp+VARSTRUC.INFO],2             ; Flag dest is ambig
        mov     [bp+VARSTRUC.ISDIR],0            ; Know destination specs file
        call    SETSTARS
GOT2ARGS:
        cmp     [bp+VARSTRUC.SIZ],2
        jnz     NOTSHORTDEST
        cmp     [DESTBUF+1],':'
        jnz     NOTSHORTDEST            ; Two char file name
        or      [bp+VARSTRUC.INFO],2             ; Know dest is d:
        mov     di,DESTBUF + 2
        mov     [bp+VARSTRUC.ISDIR],0            ; Know destination specs file
        call    SETSTARS
NOTSHORTDEST:
        mov     di,[bp+VARSTRUC.TTAIL]
        cmp     byte [DI],0
        jnz     CHKSWTCHES
        mov     dx,BADCD
        cmp     byte [DI-2],':'
        jnz     CERROR4J               ; Trailing '/' error
        mov     [bp+VARSTRUC.ISDIR],2           ; Know destination is d:/
        or      [bp+VARSTRUC.INFO],6
        call    SETSTARS
CHKSWTCHES:
        mov     dx,BADSWT
        mov     ax,[ALLSWITCH]
        cmp     ax,GOTSWITCH
        jz      CERROR4J                ; Switch specified which is not known

; Now know most of the information needed about the destination

        TEST    AX,VSWITCH              ; Verify requested?
        JZ      NOVERIF                 ; No
        MOV     AH,Get_Verify_On_Write
        INT     int_command             ; Get current setting
        PUSH    DS
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        XOR     AH,AH
        MOV     [VERVAL],AX             ; Save current setting
        POP     DS
ASSUME  DS:TRANGROUP
        MOV     AX,(Set_Verify_On_Write SHL 8) OR 1 ; Set verify
        INT     int_command
NOVERIF:
        xor     bp,bp                   ; no switches
        mov     si,81H
        mov     bl,'+'                  ; include '+' as a delimiter
SCANFSRC:
        mov     di,SCANBUF
        call    CPARSE                  ; Parse first source name
        test    bh,1                    ; Switch?
        jnz     SCANFSRC                ; Yes, try again
        or      [DESTSWITCH],bp         ; Include copy wide switches on DEST
        test    bp,BSWITCH
        jnz     NOSETCASC               ; Binary explicit
        cmp     [CONCAT],0
        JZ      NOSETCASC               ; Not Concat
        mov     [ASCII],ASWITCH         ; Concat -> ASCII copy if no B switch
NOSETCASC:
        push    SI
        mov     ax,[STARTEL]
        mov     SI,SCANBUF ; Adjust to copy
        sub     ax,SI
        mov     DI,SRCBUF
        add     ax,DI
        mov     [SRCTAIL],AX
        mov     [SRCSIZ],cl             ; Save its size
        inc     cx                      ; Include the NUL
        rep     movsb                   ; Save this source
        mov     [SRCINFO],bh            ; Save info about it
        pop     SI
        mov     ax,bp                   ; Switches so far
        call    SETASC                  ; Set A,B switches accordingly
        call    SWITCH                  ; Get any more switches on this arg
        call    SETASC                  ; Set
        call    FRSTSRC
        jmp     FIRSTENT

ENDCOPY:
        CALL    CLOSEDEST
ENDCOPY2:
        MOV     DX,COPIED_PRE
        CALL    PRINT
        MOV     SI,[FILECNT]
        XOR     DI,DI
        CALL    DISP32BITS
        MOV     DX,COPIED_POST
        CALL    PRINT
        JMP     TCOMMAND                ; Stack could be messed up

SRCNONEXIST:
        cmp     [CONCAT],0
        jnz     NEXTSRC                 ; If in concat mode, ignore error
        mov     dx,SRCBUF
        call    ZPRINT
        CALL    ONESPC
        mov     dx,NOTFND
        jmp     COPERR

SOURCEPROC:
        push    SI
        mov     ax,[STARTEL]
        mov     SI,SCANBUF ; Adjust to copy
        sub     ax,SI
        mov     DI,SRCBUF
        add     ax,DI
        mov     [SRCTAIL],AX
        mov     [SRCSIZ],cl             ; Save its size
        inc     cx                      ; Include the NUL
        rep     movsb                   ; Save this sorce
        mov     [SRCINFO],bh            ; Save info about it
        pop     SI
        mov     ax,bp                   ; Switches so far
        call    SETASC                  ; Set A,B switches accordingly
        call    SWITCH                  ; Get any more switches on this arg
        call    SETASC                  ; Set
        cmp     [CONCAT],0
        jnz     LEAVECFLAG              ; Leave CFLAG if concatination
FRSTSRC:
        xor     ax,ax
        mov     [CFLAG],al              ; Flag destination not created
        mov     [NXTADD],ax             ; Zero out buffer
        mov     [DESTCLOSED],al         ; Not created -> not closed
LEAVECFLAG:
        mov     [SRCPT],SI              ; remember where we are
        mov     di,USERDIR1
        mov     bp,SRCVARS
        call    BUILDPATH               ; Figure out everything about the source
        mov     si,[SRCTAIL]            ; Create the search FCB
        return

NEXTSRC:
        cmp     [PLUS],0
        jnz     MORECP
ENDCOPYJ2:
        jmp     ENDCOPY                 ; Done
MORECP:
        xor     bp,bp                   ; no switches
        mov     si,[SRCPT]
        mov     bl,'+'                  ; include '+' as a delimiter
SCANSRC:
        mov     di,SCANBUF
        call    CPARSE                  ; Parse first source name
        JC      ENDCOPYJ2               ; if error, then end (trailing + case)
        test    bh,80H
        jz      ENDCOPYJ2               ; If no '+' we're done
        test    bh,1                    ; Switch?
        jnz     SCANSRC                 ; Yes, try again
        call    SOURCEPROC
FIRSTENT:
        mov     di,FCB
        mov     ax,Parse_File_Descriptor SHL 8
        INT     int_command
        mov     ax,word [SRCBUF]    ; Get drive
        cmp     ah,':'
        jz      DRVSPEC1
        mov     al,'@'
DRVSPEC1:
        sub     al,'@'
        mov     [ds:FCB],al
        mov     ah,Dir_Search_First
        call    SEARCH
        pushf                           ; Save result of search
        call    RESTUDIR1               ; Restore users dir
        popf
        jz      NEXTAMBIG0
        jmp     SRCNONEXIST             ; Failed
NEXTAMBIG0:
        xor     al,al
        xchg    al,[FRSTSRCH]
        or      al,al
        jz      NEXTAMBIG
SETNMEL:
        mov     cx,12
        mov     di,SDIRBUF
        mov     si,DIRBUF
        rep     movsb                   ; Save very first source name
NEXTAMBIG:
        xor     al,al
        mov     [NOWRITE],al            ; Turn off NOWRITE
        mov     di,[SRCTAIL]
        mov     si,DIRBUF + 1
        call    FCB_TO_ASCZ             ; SRCBUF has complete name
MELDO:
        cmp     [CONCAT],0
        jnz     SHOWCPNAM               ; Show name if concat
        test    [SRCINFO],2             ; Show name if multi
        jz      DOREAD
SHOWCPNAM:
        mov     dx,SRCBUF
        call    ZPRINT
        call    CRLF2
DOREAD:
        call    DOCOPY
        cmp     [CONCAT],0
        jnz     NODCLOSE                ; If concat, do not close
        call    CLOSEDEST               ; else close current destination
        jc      NODCLOSE                ; Concat flag got set, close didn't really happen
        mov     [CFLAG],0               ; Flag destination not created
NODCLOSE:
        cmp     [CONCAT],0              ; Check CONCAT again
        jz      NOFLUSH
        CALL    FLSHFIL                 ; Flush output between source files on CONCAT
                                        ;  so LOSTERR stuff works correctly
        TEST    [MELCOPY],0FFH
        jz      NOFLUSH
        jmp     DOMELCOPY

NOFLUSH:
        call    SEARCHNEXT              ; Try next match
        jnz     NEXTSRCJ                ; Finished with this source spec
        mov     [DESTCLOSED],0          ; Not created or concat -> not closed
        jmp     NEXTAMBIG               ; Do next ambig

NEXTSRCJ:
        jmp   NEXTSRC



BUILDPATH:
        test    [BP+VARSTRUC.INFO],2
        jnz     NOTPFILE                ; If ambig don't bother with open
        mov     dx,bp
        add     dx,VARSTRUC.BUF                  ; Set DX to spec
        mov     ax,Open SHL 8
        INT     int_command
        jc      NOTPFILE
        mov     bx,ax                   ; Is pure file
        mov     ax,IOCtl SHL 8
        INT     int_command
        mov     ah,Close
        INT     int_command
        test    dl,devid_ISDEV
        jnz     ISADEV                  ; If device, done
        test    [BP+VARSTRUC.INFO],4
        jz      ISSIMPFILE              ; If no path seps, done
NOTPFILE:
        mov     dx,word [BP+VARSTRUC.BUF]
        cmp     dh,':'
        jz      DRVSPEC5
        mov     dl,'@'
DRVSPEC5:
        sub     dl,'@'                  ; A = 1
        call    SAVUDIR1
        mov     dx,bp
        add     dx,VARSTRUC.BUF                  ; Set DX for upcomming CHDIRs
        mov     bh,[BP+VARSTRUC.INFO]
        and     bh,6
        cmp     bh,6                    ; Ambig and path ?
        jnz     CHECKAMB                ; jmp if no
        mov     si,[BP+VARSTRUC.TTAIL]
        cmp     byte [si-2],':'
        jnz     KNOWNOTSPEC
        mov     [BP+VARSTRUC.ISDIR],2            ; Know is d:/file
        jmp     short DOPCDJ

KNOWNOTSPEC:
        mov     [BP+VARSTRUC.ISDIR],1            ; Know is path/file
        dec     si                      ; Point to the /
DOPCDJ:
        jmp     short DOPCD

CHECKAMB:
        cmp     bh,2
        jnz     CHECKCD
ISSIMPFILE:
ISADEV:
        mov     [BP+VARSTRUC.ISDIR],0            ; Know is file since ambig but no path
        return

CHECKCD:
        call    SETREST1
        mov     ah,CHDir
        INT     int_command
        jc      NOTPDIR
        mov     di,dx
        xor     ax,ax
        mov     cx,ax
        dec     cx
        repne   scasb
        dec     di
        mov     al,[DIRCHAR]
        mov     [bp+VARSTRUC.ISDIR],2            ; assume d:/file
        cmp     al,[di-1]
        jz      GOTSRCSLSH
        stosb
        mov     [bp+VARSTRUC.ISDIR],1            ; know path/file
GOTSRCSLSH:
        or      [bp+VARSTRUC.INFO],6
        call    SETSTARS
        return


NOTPDIR:
        mov     [bp+VARSTRUC.ISDIR],0            ; assume pure file
        mov     bh,[bp+VARSTRUC.INFO]
        test    bh,4
        retz                            ; Know pure file, no path seps
        mov     [bp+VARSTRUC.ISDIR],2            ; assume d:/file
        mov     si,[bp+VARSTRUC.TTAIL]
        cmp     byte [si],0
        jz      BADCDERRJ2              ; Trailing '/'
        cmp     byte [si],'.'
        jz      BADCDERRJ2              ; If . or .. pure cd should have worked
        cmp     byte [si-2],':'
        jz      DOPCD                   ; Know d:/file
        mov     [bp+VARSTRUC.ISDIR],1            ; Know path/file
        dec     si                      ; Point at last '/'
DOPCD:
        xor     bl,bl
        xchg    bl,[SI]                 ; Stick in a NUL
        call    SETREST1
        mov     ah,CHDir
        INT     int_command
        xchg    bl,[SI]
        retnc
BADCDERRJ2:
        JMP     BADCDERR

SETSTARS:
        mov     [bp+VARSTRUC.TTAIL],DI
        add     [bp+VARSTRUC.SIZ],12
        mov     ax,('.' SHL 8) OR '?'
        mov     cx,8
        rep     stosb
        xchg    al,ah
        stosb
        xchg    al,ah
        mov     cl,3
        rep     stosb
        xor     al,al
        stosb
        return


COMPNAME:
        PUSH    CX
        PUSH    AX
        MOV     si,SRCBUF
        MOV     di,DESTBUF
        MOV     CL,[CURDRV]
        MOV     CH,CL
        CMP     byte [SI+1],':'
        JNZ     NOSRCDRV
        LODSW
        SUB     AL,'A'
        MOV     CL,AL
NOSRCDRV:
        CMP     byte [DI+1],':'
        JNZ     NODSTDRV
        MOV     AL,[DI]
        INC     DI
        INC     DI
        SUB     AL,'A'
        MOV     CH,AL
NODSTDRV:
        CMP     CH,CL
        jnz     RET81P
        call    STRCOMP
        jz      RET81P
        mov     ax,[si-1]
        mov     cx,[di-1]
        push    ax
        and     al,cl
        pop     ax
        jnz     RET81P                  ; Niether of the mismatch chars was a NUL
; Know one of the mismatch chars is a NUL
; Check for ".NUL" compared with NUL
        cmp     al,'.'
        jnz     CHECKCL
        or      ah,ah
        jmp     short RET81P            ; If NUL return match, else no match
CHECKCL:
        cmp     cl,'.'
        jnz     RET81P                  ; Mismatch
        or      ch,ch                   ; If NUL return match, else no match
RET81P:
        POP     AX
        POP     CX
        return

end if

