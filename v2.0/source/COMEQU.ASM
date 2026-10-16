;*************************************
; COMMAND EQUs which are not switch dependant

; "IFDEF IBM / INCLUDE IFEQU.ASM" was here.  IFEQU.ASM holds nothing but %OUT
; lines announcing which switches were set, for the assembler's listing.

SYM     EQU     ">"

LINPERPAG       EQU     23
NORMPERLIN      EQU     1
WIDEPERLIN      EQU     5
COMBUFLEN       EQU     128     ; Length of commmand buffer

DRVCHAR         EQU     ":"

FCB     EQU     5CH

STRUC VARSTRUC
{
.ISDIR  DB      ?
.SIZ    DB      ?
.TTAIL  DW      ?
.INFO   DB      ?
.BUF    DB      DIRSTRLEN + 20 DUP (?)
}
virtual at 0
  VARSTRUC VARSTRUC
  sizeof.VARSTRUC = $ - VARSTRUC
end virtual

WSWITCH EQU     1               ; Wide display during DIR
PSWITCH EQU     2               ; Pause (or Page) mode during DIR
ASWITCH EQU     4               ; ASCII mode during COPY
BSWITCH EQU     8               ; Binary mode during COPY
VSWITCH EQU     10H             ; Verify switch
GOTSWITCH EQU   8000H           ; Meta switch set if switch character encountered
