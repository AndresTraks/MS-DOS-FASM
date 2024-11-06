Rainbow EQU 0

;CASE MAPPER ROUTINE FOR 80H-FFH character range
;     ENTRY: AL = Character to map
;     EXIT:  AL = The converted character
; Alters no registers except AL and flags.
; The routine should do nothing to chars below 80H.
;
; Example:
       MAP_DCASE:
IF	KANJI = 0
IF	IBM
               CMP     AL,80H
               JB      L_RET           ;Map no chars below 80H ever
               CMP     AL,0A7H
               JA     L_RET             ;This routine maps chars between 80H and A7H
		SUB	AL,80H		;Turn into index value
		PUSH	DS
		PUSH	BX
		PUSH	CS		;Move to DS
		POP	DS
		MOV	BX,TABLE
		XLATB			;Get upper case character
		POP	BX
		POP	DS
END IF
END IF
       L_RET:  RETF

IF	KANJI = 0
IF	IBM
TABLE:	DB	80H,9AH,"E","A",8EH,"A",8FH,80H
	DB	"E","E","E","I","I","I",8EH,8FH
	DB	90H,92H,92H,"O",99H,"O","U","U"
	DB	"Y",99H,9AH,9BH,9CH,9DH,9EH,9FH
	DB	"A","I","O","U",0A5H,0A5H,0A6H,0A7H
END IF
END IF

;SUBTTL EDIT FUNCTION ASSIGNMENTS AND HEADERS
; The following two tables implement the current buffered input editing
; routines.  The tables are pairwise associated in reverse order for ease
; in indexing.  That is; The first entry in ESCTAB corresponds to the last
; entry in ESCFUNC, and the last entry in ESCTAB to the first entry in ESCFUNC.


ESCCHAR DB      ESCCH                   ;Lead-in character for escape sequences
        IF      Rainbow = 0
ESCTAB:
        IF      IBM = 0
        IF      WANG
        DB      0C0h                    ; ^Z inserter
        DB      0C1H                    ; Copy one char
        DB      0C7H                    ; Skip one char
        DB      08AH                    ; Copy to char
        DB      088H                    ; Skip to char
        DB      09AH                    ; Copy line
        DB      0CBH                    ; Kill line (no change in template)
        DB      08BH                    ; Reedit line (new template)
        DB      0C3H                    ; Backspace
        DB      0C6H                    ; Enter insert mode
        IF      NOT TOGLINS
        DB      0D6H                    ; Exit insert mode
        END IF
        DB      0C6H                    ; Escape character
        DB      0C6H                    ; End of table
        ELSE
                                        ; VT52 equivalences
        DB      "Z"                     ; ^Z inserter
        DB      "S"                     ; F1 Copy one char
        DB      "V"                     ; F4 Skip one char
        DB      "T"                     ; F2 Copy to char
        DB      "W"                     ; F5 Skip to char
        DB      "U"                     ; F3 Copy line
        DB      "E"                     ; SHIFT ERASE Kill line (no change in template)
        DB      "J"                     ; ERASE Reedit line (new template)
        DB      "D"                     ; LEFT Backspace
        DB      "P"                     ; BLUE Enter insert mode
        DB      "Q"                     ; RED Exit insert mode
        DB      "R"                     ; GRAY Escape character
        DB      "R"                     ; End of table
        END IF
        END IF
        IF      IBM
        DB      64                      ; Ctrl-Z - F6
        DB      77                      ; Copy one char - -->
        DB      59                      ; Copy one char - F1
        DB      83                      ; Skip one char - DEL
        DB      60                      ; Copy to char - F2
        DB      62                      ; Skip to char - F4
        DB      61                      ; Copy line - F3
        DB      61                      ; Kill line (no change to template ) - Not used
        DB      63                      ; Reedit line (new template) - F5
        DB      75                      ; Backspace - <--
        DB      82                      ; Enter insert mode - INS (toggle)
        DB      65                      ; Escape character - F7
        DB      65                      ; End of table
        END IF
ESCEND:
ESCTABLEN EQU   ESCEND-ESCTAB

ESCFUNC:
        short_addr  GETCH               ; Ignore the escape sequence
        short_addr  TWOESC
        IF      TOGLINS = 0
        short_addr  EXITINS
        END IF
        short_addr  ENTERINS
        short_addr  BACKSP
        short_addr  REEDIT
        short_addr  KILNEW
        short_addr  COPYLIN
        short_addr  SKIPSTR
        short_addr  COPYSTR
        short_addr  SKIPONE
        short_addr  COPYONE

        IF      IBM
        short_addr  COPYONE
        END IF
        short_addr  CTRLZ
        END IF

;
; OEMFunction key is expected to process a single function
;   key input from a device and dispatch to the proper
;   routines leaving all registers UNTOUCHED.
;
; Inputs:   CS, SS are DOSGROUP
; Outputs:  None. This function is expected to JMP to onw of
;           the following labels:
;
;           GetCh       - ignore the sequence
;           TwoEsc      - insert an ESCChar in the buffer
;           ExitIns     - toggle insert mode
;           EnterIns    - toggle insert mode
;           BackSp      - move backwards one space
;           ReEdit      - reedit the line with a new template
;           KilNew      - discard the current line and start from scratch
;           CopyLin     - copy the rest of the template into the line
;           SkipStr     - read the next character and skip to it in the template
;           CopyStr     - read next char and copy from template to line until char
;           SkipOne     - advance position in template one character
;           CopyOne     - copy next character in template into line
;           CtrlZ       - place a ^Z into the template
; Registers that are allowed to be modified by this function are:
;           AX, CX, BP

OEMFunctionKey:
        ASSUME  DS:NOTHING,ES:NOTHING,SS:DOSGROUP
        invoke  _STD_CON_INPUT_NO_ECHO  ; Get the second byte of the sequence

        IF Rainbow = 0
        MOV     CL,ESCTABLEN            ; length of table for scan
        PUSH    DI                      ; save DI (cannot change it!)
        MOV     DI,ESCTAB   ; offset of second byte table
        REPNE   SCASB                   ; Look it up in the table
        POP     DI                      ; restore DI
        SHL     CX,1                    ; convert byte offset to word
        MOV     BP,CX                   ; move to indexable register
        JMP     WORD[BP+ESCFUNC]    ; Go to the right routine
        END IF
        IF Rainbow

        CMP     AL,'['                  ; is it second lead char
        JZ      EatParm                 ; yes, go walk tree
GoGetCh:
        transfer    GETCH               ; no, ignore sequence
EatParm:
        invoke  _STD_CON_INPUT_NO_ECHO  ; get argument
        CMP     AL,'A'                  ; is it alphabetic arg?
        JAE     EatAlpha                ; yes, go snarf one up
        XOR     BP,BP                   ; init digit counter
        JMP     InDigit                 ; jump into internal eat digit routine
EatNum:
        invoke  _STD_CON_INPUT_NO_ECHO  ; get next digit
InDigit:
        CMP     AL,'9'                  ; still a digit?
        JA      CheckNumEnd             ; no, go check for end char
        SUB     AL,'0'                  ; turn into potential digit
        JB      GoGetCh                 ; oops, not a digit, ignore
        MOV     CX,BP                   ; save BP for 10 multiply
        CBW                             ; make AL into AX
        SHL     BP,1                    ; 2*BP
        SHL     BP,1                    ; 4*BP
        ADD     BP,CX                   ; 5*BP
        SHL     BP,1                    ; 10*BP
        ADD     BP,AX                   ; 10*BP + digit
        JMP     EatNum                  ; continue with number
CheckNumEnd:
        CMP     AL,7Eh                  ; is it end char ~
        JNZ     GoGetCh                 ; nope, ignore key sequence
        MOV     AX,BP
        CMP     AL,1
        JNZ     EnterIns_check
        transfer     SkipStr            ; FIND key
EnterIns_check:
        CMP     AL,2
        JNZ     SkipOne_check
        transfer     EnterIns           ; INSERT HERE key
SkipOne_check:
        CMP     AL,3
        JNZ     CopyStr_check
        transfer     SkipOne            ; REMOVE
CopyStr_check:
        CMP     AL,4
        JNZ     TwoEsc_check
        transfer     COPYSTR            ; SELECT
TwoEsc_check:
        CMP     AL,17
        JNZ     ReEdit_check
        transfer     TwoEsc             ; INTERRUPT
ReEdit_check:
        CMP     AL,18
        JNZ     KilNew_check
        transfer     TwoEsc             ; RESUME
KilNew_check:
        CMP     AL,19
        JNZ     CtrlZ_check
        transfer     KilNew             ; CANCEL
CtrlZ_check:
        CMP     AL,21
        JNZ     CopyLin_check
        transfer     CtrlZ              ; EXIT
CopyLin_check:
        CMP     AL,29
        JNZ     GoGetCh_jmp
        transfer     CopyLin            ; DO
GoGetCh_jmp:
        JMP     GoGetCh
EatAlpha:
        CMP     AL,'O'                  ; is it O?
        JA      GoGetCh                 ; no, after assume bogus
        JZ      EatPQRS                 ; eat the rest of the bogus key
        CMP     AL,'C'
        JNZ     BackSp_check
        transfer     CopyOne            ; RIGHT
BackSp_check:
        CMP     AL,'D'
        JNZ     GoGetCh_jmp
        transfer     CopyOne                 ; RIGHT
EatPQRS:
        invoke  _STD_CON_INPUT_NO_ECHO  ; eat char after O
        JMP     GoGetCh
        END IF

        do_ext
