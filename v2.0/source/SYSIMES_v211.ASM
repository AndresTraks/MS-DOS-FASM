; SYSINIT messages.
;
; SYSIMES.ASM in this directory is the 2.0 version: it publishes BADSIZ and
; BADLD whole.  SYSINIT.ASM is a later file and asks for each of them in two
; halves, because PRNERR prints DX, then a zero terminated file name from
; ES:SI, then BX:
;
;       PRNERR: PUSH CS / POP DS
;               MOV AH,STD_CON_STRING_OUTPUT / INT 21H     ; DX, the PRE half
;       PRN1:   MOV DL,ES:[SI] ... MOV AH,STD_CON_OUTPUT   ; the name
;       PRN2:   MOV DX,BX
;       PRINT:  MOV AH,STD_CON_STRING_OUTPUT / INT 21H     ; the POST half
;
; so the PRE halves are the 2.0 strings up to their "$", and the POST halves
; are the trailing CRLF that the 2.0 code printed separately through CRLFM.
;
; BADOPM is printed with PRINT rather than PRNERR and has no "$" of its own,
; exactly as in the 2.0 file: it runs straight into CRLFM, so the two must
; stay adjacent and in this order.
;
; BADCOUNTRY is the one string here that the code does not pin down.  It is
; only ever loaded into DX and printed, so nothing constrains its wording,
; and the 2.0 file has nothing to carry over.  The text below is a
; reconstruction, not a recovered original.

BADOPM  DB      13,10,"Unrecognized command in CONFIG.SYS"
CRLFM   DB      13,10,'$'

BADSIZ_PRE      DB      13,10,"Sector size too large in file $"
BADSIZ_POST     DB      13,10,'$'

BADLD_PRE       DB      13,10,"Bad or missing $"
BADLD_POST      DB      13,10,'$'

BADCOUNTRY      DB      13,10,"Invalid country code",13,10,'$'

BADCOM  DB      "Command Interpreter",0

label SYSSIZE byte
