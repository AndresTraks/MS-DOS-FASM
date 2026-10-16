




if SEGSEL = S_CODERES

        IF      IBMVER
        END IF

end if



if SEGSEL = S_DATARES
end if


if SEGSEL = S_TRANDATA
end if


if SEGSEL = S_TRANSPACE


        IF      KANJI
        END IF

end if



if SEGSEL = S_TRANCODE
ASSUME  CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

        IF      KANJI
        END IF

 


FREE_TPA:
ASSUME  DS:TRANGROUP,ES:NOTHING
        PUSH    ES
        MOV     ES,[TPA]
        MOV     AH,Dealloc
        INT     int_command             ; Make lots of free memory
        POP     ES
        return

ALLOC_TPA:
ASSUME DS:TRANGROUP,ES:RESGROUP
        MOV     BX,0FFFFH       ; Re-allocate the transient
        MOV     AH,Alloc
        INT     int_command
        MOV     AH,Alloc
        INT     int_command
        MOV     [LTPA],AX       ; Re-compute evrything
        MOV     [TPA],AX
        MOV     BX,AX
        MOV     AX,CS
        SUB     AX,BX
        MOV     DX,16
        MUL     DX
        OR      DX,DX
        JZ      SAVSIZ2
        MOV     AX,-1
SAVSIZ2:
        MOV     [BYTCNT],AX
        return


PRESCAN:                        ; Cook the input buffer
ASSUME  DS:TRANGROUP,ES:TRANGROUP
        XOR     CX,CX
        MOV     ES,[RESSEG]
ASSUME  ES:RESGROUP
        MOV     SI,COMBUF+2
        MOV     DI,SI

CountQuotes:
        LODSB                           ; get a byte
        CMP     AL,22h                  ; is it a quote?
        JNZ     CountEnd                ; no, try for end of road
        INC     CH                      ; bump count
        JMP     CountQuotes             ; go get next char
CountEnd:
        CMP     AL,13                   ; end of road?
        JNZ     CountQuotes             ; no, go back for next char

        IF      KANJI
        PUSH    CX                      ; save count
        MOV     SI,DI                   ; get back beginning of buffer
KanjiScan:
        LODSB                           ; get a byte
        CALL    TESTKANJ                ; is it a leadin byte
        JZ      KanjiQuote              ; no, check for quotes
        MOV     AH,AL                   ; save leadin
        LODSB                           ; get trailing byte
        CMP     AX,8140h                ; is it Kanji space
        JNZ     KanjiScan               ; no, go get next
        MOV     [SI-2],2020h            ; replace with spaces
        JMP     KanjiScan               ; go get next char
KanjiQuote:
        CMP     AL,22h                  ; beginning of quoted string
        JNZ     KanjiEnd                ; no, check for end
        DEC     CH                      ; drop count
        JZ      KanjiScan               ; if count is zero, no quoting
KanjiQuoteLoop:
        LODSB                           ; get next byte
        CMP     AL,22h                  ; is it another quote
        JNZ     KanjiQuoteLoop          ; no, get another
        DEC     CH                      ; yes, drop count
        JMP     KanjiScan               ; go get next char
KanjiEnd:
        CMP     AL,13                   ; end of line character?
        JNZ     KanjiScan               ; go back to beginning
        POP     CX                      ; get back original count
        END IF

        MOV     SI,DI                   ; restore pointer to begining
PRESCANLP:
        LODSB

        IF      KANJI
        CALL    TESTKANJ
        JZ      NOTKANJ6
        MOV     [DI],AL
        INC     DI                      ; fake STOSB into DS
        LODSB                           ; grab second byte
        MOV     [DI],AL                 ; fake stosb into DS
        INC     DI
        INC     CL
        INC     CL
        JMP     PRESCANLP
NOTKANJ6:
        END IF

        CMP     AL,22H          ; " character
        JNZ     TRYGREATER
        DEC     CH
        JZ      TRYGREATER
QLOOP:
        MOV     [DI],AL
        INC     DI
        INC     CL
        LODSB
        CMP     AL,22H          ; " character
        JNZ     QLOOP
        DEC     CH

TRYGREATER:
        CMP     AL,'>'
        JNZ     NOOUT
        CMP     byte [SI],'>'
        JNZ     NOAPPND
        LODSB
        INC     [RE_OUT_APP]            ; Flag >>
NOAPPND:
        CALL    SCANOFF
        CMP     AL,0DH
        JNZ     GOTREOFIL
        MOV     word [RE_OUTSTR],09H     ; Cause an error later
        JMP     SHORT PRESCANEND
GOTREOFIL:
        PUSH    DI
        MOV     DI,RE_OUTSTR
SETREOUTSTR:                            ; Get the output redirection name
        LODSB
        CMP     AL,0DH
        JZ      GOTRESTR
        CALL    DELIM
        JZ      GOTRESTR
        CMP     AL,[SWITCHAR]
        JZ      GOTRESTR
        STOSB                           ; store it into resgroup
        JMP     SHORT SETREOUTSTR

NOOUT:
        CMP     AL,'<'
        JNZ     CHKPIPE
        CALL    SCANOFF
        CMP     AL,0DH
        JNZ     GOTREIFIL
        MOV     word [RE_INSTR],09H ; Cause an error later
        JMP     SHORT PRESCANEND
GOTREIFIL:
        PUSH    DI
        MOV     DI,RE_INSTR
        JMP     SHORT SETREOUTSTR       ; Get the input redirection name

CHKPIPE:
        MOV     AH,AL
        CMP     AH,'|'
        JNZ     CONTPRESCAN
        INC     [PIPEFLAG]
        CALL    SCANOFF
        CMP     AL,0DH
        JZ      PIPEERRSYNJ5
        CMP     AL,'|'          ; Double '|'?
        JNZ     CONTPRESCAN
PIPEERRSYNJ5:
        PUSH    ES
        POP     DS              ; DS->RESGROUP
        JMP     PIPEERRSYN

GOTRESTR:
        XCHG    AH,AL
        CMP     byte [ES:DI-1],':'  ; Trailing ':' OK on devices
        JNZ     NOTTRAILCOL
        DEC     DI              ; Back up over trailing ':'
NOTTRAILCOL:
        XOR     AL,AL
        STOSB                   ; NUL terminate the string
        POP     DI              ; Remember the start
CONTPRESCAN:
        MOV     [DI],AH         ; "delete" the redirection string
        INC     DI
        CMP     AH,0DH
        JZ      PRESCANEND
        INC     CL
        JMP     PRESCANLP
PRESCANEND:
        CMP     [PIPEFLAG],0
        JZ      ISNOPIPE
        MOV     DI,PIPESTR
        MOV     [PIPEPTR],DI
        MOV     SI,COMBUF+2
        CALL    SCANOFF
PIPESETLP:                      ; Transfer the pipe into the resident pipe buffer
        LODSB
        STOSB
        CMP     AL,0DH
        JNZ     PIPESETLP
ISNOPIPE:
        MOV     [COMBUF+1],CL
        CMP     [PIPEFLAG],0
        PUSH    CS
        POP     ES
        return

ASSUME  DS:TRANGROUP,ES:TRANGROUP

PATHCHRCMP:
        CMP     [SWITCHAR],'/'
        JZ      NOSLASHT
        CMP     AL,'/'
        retz
NOSLASHT:
        CMP     AL,'\'
        return

PATHCRUNCH:
; Drive taken from FCB
; DI = Dirsave pointer
;
; Zero set if path dir, CHDIR to this dir, FCB filled with ?
; NZ set if path/file, CHDIR to file, FCB has file (parsed fill ' ')
;       [DESTTAIL] points to parse point
; Carry set if no CHDIRs worked, FCB not altered.
; DESTISDIR set non zero if PATHCHRs in path (via SETPATH)

        MOV     DL,[DS:FCB]
        CALL    SAVUDIR
        CALL    SETPATH
        TEST    [DESTINFO],2
        JNZ     TRYPEEL         ; If ? or * cannot be pure dir
        MOV     AH,CHDir
        INT     int_command
        JC      TRYPEEL
        CALL    SETREST1
        MOV     AL,"?"          ; *.* is default file spec if pure dir
        MOV     DI,5DH
        MOV     CX,11
        REP     STOSB
        XOR     AL,AL           ; Set zero
        return

TRYPEEL:
        MOV     SI,[PATHPOS]
        DEC     SI              ; Point at NUL
        MOV     AL,[SI-1]

        IF      KANJI
        CMP     [KPARSE],0
        JNZ     DELSTRT         ; Last char is second KANJI byte, might be '\'
        END IF

        CALL    PATHCHRCMP
        JZ      PEELFAIL                ; Trailing '/'

        IF      KANJI
DELSTRT:
        MOV     CX,SI
        MOV     SI,DX
        PUSH    DX
DELLOOP:
        CMP     SI,CX
        JZ      GOTDELE
        LODSB
        CALL    TESTKANJ
        JZ      NOTKANJ8
        INC     SI
        JMP     DELLOOP

NOTKANJ8:
        CALL    PATHCHRCMP
        JNZ     DELLOOP
        MOV     DX,SI
        DEC     DX
        JMP     DELLOOP

GOTDELE:
        MOV     SI,DX
        POP     DX
        CMP     SI,DX
        JZ      BADRET
        MOV     CX,SI
        MOV     SI,DX
DELLOOP2:                       ; Set value of KPARSE
        CMP     SI,CX
        JZ      KSET
        MOV     [KPARSE],0
        LODSB
        CALL    TESTKANJ
        JZ      DELLOOP2
        INC     SI
        INC     [KPARSE]
        JMP     DELLOOP2

KSET:
        ELSE
DELLOOP:
        CMP     SI,DX
        JZ      BADRET
        MOV     AL,[SI]
        CALL    PATHCHRCMP
        JZ      TRYCD
        DEC     SI
        JMP     SHORT DELLOOP
        END IF

TRYCD:
        CMP     byte [SI+1],'.'
        JZ      PEELFAIL                ; If . or .., pure cd should have worked
        mov     al,[si-1]
        CMP     al,DRVCHAR                  ; Special case dDRVCHAR,DIRCHARfile
        JZ      BADRET

        IF      KANJI
        CMP     [KPARSE],0
        JNZ     NOTDOUBLESL     ; Last char is second KANJI byte, might be '\'
        END IF

        CALL    PATHCHRCMP
        JNZ     NOTDOUBLESL
PEELFAIL:
        STC                                 ; //
        return
NOTDOUBLESL:
        MOV     byte [SI],0
        MOV     AH,CHDir
        INT     int_command
        JNC     CDSUCC
        return

BADRET:
        MOV     AL,[SI]
        CALL    PATHCHRCMP              ; Special case 'DIRCHAR'file
        STC
        retnz
        XOR     BL,BL
        XCHG    BL,[SI+1]
        MOV     AH,CHDir
        INT     int_command
        retc
        MOV     [SI+1],BL
CDSUCC:
        CALL    SETREST1
        INC     SI                      ; Reset zero
        MOV     [DESTTAIL],SI
        MOV     DI,FCB
        MOV     AX,(Parse_File_Descriptor SHL 8) OR 02H   ; Parse with default drive
        INT     int_command
        return


DISPSIZE:
        MOV     SI,word[DIRBUF+29+7]
        MOV     DI,word[DIRBUF+31+7]

DISP32BITS:
; Prints the 32-bit number DI:SI on the console in decimal. Uses a total
; of 9 digit positions with leading blanks.
        XOR     AX,AX
        MOV     BX,AX
        MOV     BP,AX
        MOV     CX,32
CONVLP:
        SHL     SI,1
        RCL     DI,1
        XCHG    AX,BP
        CALL    CONVWRD
        XCHG    AX,BP
        XCHG    AX,BX
        CALL    CONVWRD
        XCHG    AX,BX
        ADC     AL,0
        LOOP    CONVLP

; Conversion complete. Print 9-digit number.

        MOV     DI,CHARBUF
        MOV     CX,1810H        ; Allow leading zero blanking for 8 digits
        XCHG    DX,AX
        CALL    DIGIT
        XCHG    AX,BX
        CALL    OUTWORD
        XCHG    AX,BP
        CALL    OUTWORD
        XOR     AX,AX
        STOSB
        MOV     DX,CHARBUF
        JMP     ZPRINT

OUTWORD:
        PUSH    AX
        MOV     DL,AH
        CALL    OUTBYTE
        POP     DX
OUTBYTE:
        MOV     DH,DL
        SHR     DL,1
        SHR     DL,1
        SHR     DL,1
        SHR     DL,1
        CALL    DIGIT
        MOV     DL,DH
DIGIT:
        AND     DL,0FH
        JZ      BLANKZER
        MOV     CL,0
BLANKZER:
        DEC     CH
        AND     CL,CH
        OR      DL,30H
        SUB     DL,CL
        MOV     AL,DL
        STOSB
        return

CONVWRD:
        ADC     AL,AL
        DAA
        XCHG    AL,AH
        ADC     AL,AL
        DAA
        XCHG    AL,AH
        return


GETBATBYT:
; Get one byte from the batch file and return it in AL. End-of-file
; returns <CR> and ends batch mode. DS must be set to resident segment.
; AH, CX, DX destroyed.
ASSUME  DS:RESGROUP
        ADD     word [BATLOC],1     ; Add one to file location
        ADC     word [BATLOC+2],0
        PUSH    BX
        MOV     DX,BATBYT
        MOV     BX,[BATHAND]
        MOV     AH,Read
        MOV     CX,1
        INT     int_command              ; Get one more byte from batch file
        POP     BX
        MOV     CX,AX
        JC      BATEOF
        JCXZ    BATEOF
        MOV     AL,[BATBYT]
        CMP     AL,1AH
        retnz
BATEOF:
        PUSH    ES
        MOV     ES,[BATCH]      ; Turn off batch
        MOV     AH,Dealloc
        INT     int_command             ; free up the batch piece
        POP     ES
        MOV     [BATCH],0       ; AFTER DEALLOC in case of ^C
        CALL    BATCLOSE
        MOV     AL,0DH          ; If end-of-file, then end of line
        CMP     [SINGLECOM],0FFF0H      ; See if we need to set SINGLECOM
        JNZ     NOSETSING2
        MOV     [SINGLECOM],-1  ; Cause termination
NOSETSING2:
        MOV     [ECHOFLAG],1
        return
ASSUME  DS:TRANGROUP

SCANOFF:
        LODSB
        CALL    DELIM
        JZ      SCANOFF
        DEC     SI              ; Point to first non-delimiter
        return

DELIM:
        CMP     AL," "
        retz
        CMP     AL,"="
        retz
        CMP     AL,","
        retz
        CMP     AL,";"
        retz
        CMP     AL,9            ; Check for TAB character
        return


PRINT_PROMPT:
        PUSH    DS
        PUSH    CS
        POP     DS              ; MAKE SURE DS IS IN TRANGROUP

        PUSH    ES
        CALL    FIND_PROMPT     ; LOOK FOR PROMPT STRING
        JC      PP0             ; CAN'T FIND ONE
        CMP     byte [ES:DI],0
        JNZ     PP1
PP0:
        CALL    PRINT_DRIVE     ; USE DEFAULT PROMPT
        MOV     AL,SYM
        CALL    OUT_
        JMP     SHORT PP5

PP1:
        MOV     AL,[ES:DI]      ; GET A CHAR
        INC     DI
        OR      AL,AL
        JZ      PP5             ; NUL TERMINATED
        CMP     AL,"$"          ; META CHARACTER?
        JZ      PP2             ; NOPE
PPP1:
        CALL    OUT_
        JMP     PP1

PP2:
        MOV     AL,[ES:DI]
        INC     DI
        MOV     BX,PROMPT_TABLE-3
        OR      AL,AL
        JZ      PP5

PP3:
        ADD     BX,3
        CALL    UPCONV
        CMP     AL,[BX]
        JZ      PP4
        CMP     byte [BX],0
        JNZ     PP3
        JMP     PP1

PP4:
        PUSH    ES
        PUSH    DI
        PUSH    CS
        POP     ES
        CALL    word [BX+1]
        POP     DI
        POP     ES
        JMP     PP1

PP5:
        POP     ES              ; RESTORE SEGMENTS
        POP     DS
        return

PRINT_BACK:
        MOV     DX,DBACK
        JMP     ZPRINT

PRINT_EQ:
        MOV     AL,"="
        JMP     SHORT OUTV
PRINT_ESC:
        MOV     AL,1BH
        JMP     SHORT OUTV
PRINT_G:
        MOV     AL,">"
        JMP     SHORT OUTV
PRINT_L:
        MOV     AL,"<"
        JMP     SHORT OUTV
PRINT_B:
        MOV     AL,"|"
OUTV:
        JMP     OUT_

SETPATH:
; Get an ASCIZ argument from the unformatted parms
; DESTISDIR set if pathchars in string
; DESTINFO  set if ? or * in string
        MOV     SI,80H
        LODSB
        XOR     AH,AH
        MOV     [PATHCNT],AX
        MOV     [PATHPOS],SI
GETPATH:
        MOV     [DESTINFO],0
        MOV     [DESTISDIR],0
        MOV     SI,[PATHPOS]
        MOV     CX,[PATHCNT]
        MOV     DX,SI
        JCXZ    PATHDONE
        PUSH    CX
        PUSH    SI
        CALL    SWITCH
        MOV     [PATHSW],AX
        POP     BX
        SUB     BX,SI
        POP     CX
        ADD     CX,BX
        MOV     DX,SI
SKIPPATH:

        IF      KANJI
        MOV     [KPARSE],0
SKIPPATH2:
        END IF

        JCXZ    PATHDONE
        DEC     CX
        LODSB

        IF      KANJI
        CALL    TESTKANJ
        JZ      TESTPPSEP
        DEC     CX
        INC     SI
        INC     [KPARSE]
        JMP     SKIPPATH2

TESTPPSEP:
        END IF

        CALL    PATHCHRCMP
        JNZ     TESTPMETA
        INC     [DESTISDIR]
TESTPMETA:
        CMP     AL,'?'
        JNZ     TESTPSTAR
        OR      [DESTINFO],2
TESTPSTAR:
        CMP     AL,'*'
        JNZ     TESTPDELIM
        OR      [DESTINFO],2
TESTPDELIM:
        CALL    DELIM
        JZ      PATHDONEDEC
        CMP     AL,[SWITCHAR]
        JNZ     SKIPPATH
PATHDONEDEC:
        DEC     SI
PATHDONE:
        XOR     AL,AL
        XCHG    AL,[SI]
        INC     SI
        CMP     AL,0DH
        JNZ     NOPSTORE
        MOV     [SI],AL       ;Don't loose the CR
NOPSTORE:
        MOV     [PATHPOS],SI
        MOV     [PATHCNT],CX
        return

PGETARG:
        MOV     SI,80H
        LODSB
        OR      AL,AL
        retz
        CALL    PSCANOFF
        CMP     AL,13
        return

PSCANOFF:
        LODSB
        CALL    DELIM
        JNZ     PSCANOFFD
        CMP     AL,';'
        JNZ     PSCANOFF        ; ';' is not a delimiter
PSCANOFFD:
        DEC     SI              ; Point to first non-delimiter
        return

PATH:
        CALL    FIND_PATH
        CALL    PGETARG         ; Pre scan for arguments
        JZ      DISPPATH        ; Print the current path
        CALL    DELETE_PATH     ; DELETE ANY OFFENDING NAME
        CALL    SCAN_DOUBLE_NULL
        CALL    MOVE_NAME       ; MOVE IN PATH=
        CALL    PGETARG
        CMP     AL,';'          ; NUL path argument?
        JZ      GOTPATHS
PATHSLP:                        ; Get the user specified path
        LODSB
        CMP     AL,0DH
        JZ      GOTPATHS

        IF      KANJI
        CALL    TESTKANJ
        JZ      NOTKANJ2
        CALL    STORE_CHAR
        LODSB
        CALL    STORE_CHAR
        JMP     SHORT PATHSLP

NOTKANJ2:
        END IF

        CALL    UPCONV
        CMP     AL,';'          ; ';' not a delimiter on PATH
        JZ      NOTDELIM
        CALL    DELIM
        JZ      GOTPATHS
NOTDELIM:
        CALL    STORE_CHAR
        JMP     SHORT PATHSLP

GOTPATHS:
        XOR     AX,AX
        STOSW
        return

DISPPATH:
        CALL    PRINT_PATH
        CALL    CRLF2
        return

PRINT_PATH:
        CMP     byte [ES:DI],0
        JNZ     PATH1
PATH0:
        MOV     DX,NULPATH
        PUSH    CS
        POP     DS
        JMP     PRINT
PATH1:
        PUSH    ES
        POP     DS
        SUB     DI,5
        MOV     DX,DI
ASSUME  DS:RESGROUP
        CALL    SCASB2                  ; LOOK FOR NUL
        CMP     CX,0FFH
        JZ      PATH0
        JMP     ZPRINT

FCB_TO_ASCZ:                            ; Convert DS:SI to ASCIZ ES:DI
        MOV     CX,8
MAINNAME:
        LODSB
        CMP     AL,' '
        JZ      SKIPSPC
        STOSB
SKIPSPC:
        LOOP    MAINNAME
        LODSB
        CMP     AL,' '
        JZ      GOTNAME
        MOV     AH,AL
        MOV     AL,'.'
        STOSB
        XCHG    AL,AH
        STOSB
        MOV     CL,2
EXTNAME:
        LODSB
        CMP     AL,' '
        JZ      GOTNAME
        STOSB
        LOOP    EXTNAME

GOTNAME:
        XOR     AL,AL
        STOSB
        return

GETNUM:
        CALL    INDIG
        retc
        MOV     AH,AL           ; Save first digit
        CALL    INDIG           ; Another digit?
        JC      OKRET
        AAD                     ; Convert unpacked BCD to decimal
        MOV     AH,AL
OKRET:
        OR      AL,1
        return

INDIG:
        MOV     AL,byte[SI]
        SUB     AL,"0"
        retc
        CMP     AL,10
        CMC
        retc
        INC     SI
        return


OUT2:   ; Output binary number as two ASCII digits
        AAM                     ; Convert binary to unpacked BCD
        XCHG    AL,AH
        OR      AX,3030H        ; Add "0" bias to both digits
        CMP     AL,"0"          ; Is MSD zero?
        JNZ     NOSUP
        SUB     AL,BH           ; Suppress leading zero if enabled
NOSUP:
        MOV     BH,0            ; Disable zero suppression
        STOSW
        return

OUT_:
; Print char in AL without affecting registers
        XCHG    AX,DX
        PUSH    AX
        CALL    OUT_CHAR
        POP     AX
        XCHG    AX,DX
        return

OUT_CHAR:
        PUSH    DS
        PUSH    DX
        PUSH    CX
        PUSH    BX
        PUSH    AX
        PUSH    CS
        POP     DS
        MOV     BX,CHARBUF
        MOV     [BX],DL
        MOV     DX,BX
        MOV     BX,1
        MOV     CX,BX
        MOV     AH,Write
        INT     int_command
        POP     AX
        POP     BX
        POP     CX
        POP     DX
        POP     DS
        return


ERROR_PRINT:
        PUSH    AX
        PUSH    BX
        MOV     AL,"$"
        MOV     BX,2            ;STD ERROR
        JMP     SHORT STRING_OUT

CRPRINT:
        PUSH    AX
        MOV     AL,13
        JMP     SHORT Z_PRINT
PRINT:                          ;$ TERMINATED STRING
        PUSH    AX
        MOV     AL,"$"
        JMP     SHORT Z_PRINT
ZPRINT:
        PUSH    AX
        XOR     AX,AX           ;NUL TERMINATED STRING
Z_PRINT:
        PUSH    BX
        MOV     BX,1            ;STD CON OUT
;
; output string terminated by AL to handle BX, DS:DX points to string
;
STRING_OUT:
        PUSH    CX
        PUSH    DI
        MOV     DI,DX
        MOV     CX,-1
        PUSH    ES
        PUSH    DS
        POP     ES
        REPNZ   SCASB           ; LOOK FOR TERMINATOR
        POP     ES
        NEG     CX
        DEC     CX
        DEC     CX
;
; WRITE CHARS AT DS:DX TO HANDLE IN BX, COUNT IN CX
;
        MOV     AH,Write
        INT     int_command
        JC      ERROR_OUTPUT
        CMP     AX,CX
        JNZ     ERROR_OUTPUT
        POP     DI
        POP     CX
        POP     BX
        POP     AX
        return

ERROR_OUTPUT:
        PUSH    CS
        POP     DS
ASSUME  DS:TRANGROUP
        MOV     ES,[RESSEG]
ASSUME  ES:RESGROUP
        MOV     DX,NOSPACE
        CMP     [PIPEFLAG],0
        JZ      GO_TO_ERROR
        MOV     [PIPEFLAG],0
        MOV     DX,PIPEEMES
GO_TO_ERROR:
        JMP     CERROR


end if
