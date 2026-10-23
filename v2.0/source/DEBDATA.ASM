INCLUDE 'debequ.asm'

if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_DATA
end if


if SEGSEL = S_DATA




ParityFlag  DB  0
XNXOPT  DB      0; AL OPTION FOR DOS COMMAND
XNXCMD  DB      0; DOS COMMAND FOR OPEN_A_FILE TO PERFORM
SWITCHAR DB      0; CURRENT SWITCH CHARACTER
EXTPTR  DW      0; POINTER TO FILE EXTENSION
HANDLE  DW      0; CURRENT HANDLE
TRANSADD DD      0; TRANSFER ADDRESS

PARSERR DB      0
ASMADD  DB      4 dup (0)
DISADD  DB      4 dup (0)
DISCNT  DW      0
ASMSP   DW      0; SP AT ENTRY TO ASM
INDEX   DW      0
DEFDUMP DB      4 dup (0)
DEFLEN  DW      0
REGSAVE DW      0
SEGSAVE DW      0
OFFSAVE DW      0

; The following data areas are destroyed during hex file read
TEMP    DB      4 dup (0)
label BUFFER byte
BYTCNT  DB      0
OPCODE  DW      0
AWORD   DB      0
REGMEM  DB      0
MIDFLD  DB      0
MODE    DB      0
NSEG    DW      0
OPBUF   DB      OPBUFLEN dup (0)
BRKCNT  DW      0; Number of breakpoints
TCOUNT  DW      0; Number of steps to trace
ASSEM_CNT       DB      0; preserve order of assem_cnt and assem1
ASSEM1          DB      0
ASSEM2          DB      0
ASSEM3          DB      0
ASSEM4          DB      0
ASSEM5          DB      0
ASSEM6          DB      0; preserve order of assemx and bytebuf
BYTEBUF DB      BUFLEN  dup (0)         ; Table used by LIST
BPTAB   DB      BPLEN   dup (0)         ; Breakpoint table
DIFLG   DB      0
SIFLG   DB      0
BXFLG   DB      0
BPFLG   DB      0
NEGFLG  DB      0
NUMFLG  DB      0; ZERO MEANS NO NUMBER SEEN
MEMFLG  DB      0
REGFLG  DB      0
MOVFLG  DB      0
TSTFLG  DB      0
SEGFLG  DB      0
LOWNUM  DW      0
HINUM   DW      0
F8087   DB      0
DIRFLG  DB      0
        DB      BUFFER+BUFSIZ-$ dup (0)

label DATAEND word

end if
