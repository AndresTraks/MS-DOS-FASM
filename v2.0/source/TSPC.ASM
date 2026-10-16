

; Uninitialized transient data

if SEGSEL = S_TRANSPACE


        IF  IBM
        END IF

        IF      KANJI
        END IF

ZERO    =       $
UCOMBUF DB      COMBUFLEN+3 DUP(?)      ; Raw console buffer
COMBUF  DB      COMBUFLEN+3 DUP(?)      ; Cooked console buffer
USERDIR1 DB     DIRSTRLEN+3 DUP(?)      ; Storage for users current directory
EXECPATH DB     DIRSTRLEN+15 DUP(?)     ; Path for external command

; Variables passed up from resident
label HEADCALL dword
        DW      ?
RESSEG  DW      ?
TPA     DW      ?
SWITCHAR DB     ?
DIRCHAR DB      ?
EXEC_ADDR DD    ?
RCH_ADDR DD     ?

CHKDRV  DB      ?
label RDEOF byte                    ; Misc flags
label IFNOTFLAG byte
FILTYP  DB      ?
CURDRV  DB      ?
label CONCAT byte
PARM1   DB      ?
label ARGC byte
PARM2   DB      ?
COMSW   DW      ?               ; Switches between command and 1st arg
ARG1S   DW      ?               ; Switches between 1st and 2nd arg
label DESTSWITCH word
ARG2S   DW      ?               ; Switches after 2nd arg
label ALLSWITCH word
ARGTS   DW      ?               ; ALL switches except for COMSW
CFLAG   DB      ?
label DESTCLOSED byte
SPECDRV DB      ?
BYTCNT  DW      ?               ; Size of buffer between RES and TRANS
NXTADD  DW      ?
FRSTSRCH DB     ?
LINCNT  DB      ?
LINLEN  DB      ?
FILECNT DW      ?
CHARBUF DB      80 DUP (?)      ;line byte character buffer for xenix write
label DESTFCB2 byte
IDLEN   DB      ?
ID      DB      8 DUP(?)
COM     DB      3 DUP(?)
DEST    DB      37 DUP(?)
DESTNAME DB     11 DUP(?)
label DESTFCB byte
DESTDIR DB      DIRSTRLEN DUP(?)        ; Directory for PATH searches
label GOTOLEN word
label PWDBUF byte
label EXEFCB word
DIRBUF  DB      DIRSTRLEN+3 DUP(?)
SDIRBUF DB      12 DUP(?)
BITS    DW      ?
PATHCNT DW      ?
PATHPOS DW      ?
PATHSW  DW      ?
FULLSCR DW      ?

IF  IBM
ROM_CALL    DB  ?                       ; flag for rom function
ROM_IP  DW  ?
ROM_CS  DW  ?
END IF

label DESTVARS byte
DESTISDIR DB    ?
DESTSIZ DB      ?
DESTTAIL DW     ?
DESTINFO DB     ?
DESTBUF DB      DIRSTRLEN + 20 DUP (?)

DESTHAND DW     ?
DESTISDEV DB    ?
FIRSTDEST DB    ?
MELCOPY DB      ?
MELSTART DW     ?

label SRCVARS byte
SRCISDIR DB     ?
SRCSIZ DB       ?
SRCTAIL DW      ?
SRCINFO DB      ?
SRCBUF  DB      DIRSTRLEN + 20 DUP (?)

SRCHAND DW      ?
SRCISDEV DB     ?

SCANBUF DB      DIRSTRLEN + 20 DUP (?)

SRCPT   DW      ?
INEXACT DB      ?
APPEND  DB      ?
NOWRITE DB      ?
BINARY  DB      ?
WRITTEN DB      ?
TERMREAD DB     ?
ASCII   DB      ?
PLUS    DB      ?
CPDATE  DW      ?
CPTIME  DW      ?
BATHAND DW      ?               ; Batch handle
STARTEL DW      ?
ELCNT   DB      ?
ELPOS   DB      ?
SKPDEL  DB      ?
SOURCE  DB      11 DUP(?)

        IF      KANJI
KPARSE  DB      ?
        END IF

INTERNATVARS internat_block ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?
                DB      (internat_block_max - ($ - INTERNATVARS)) DUP (?)


        DB      80H DUP(0)      ; Init to 0 to make sure the linker is not fooled
label STACK_ word

label TRANSPACEEND byte

end if
