; MORE.COM, from MORE.ASM and the messages in MOREMES.ASM.
;
; The release ships a MORE.COM and it runs here, MORE asking only for 2.00 or
; better, but this builds it from the source like the rest: bin/MORE.COM is
; Microsoft's, kept to compare against.
;
; Built as the IBM version, which is how the source comes: IBMVER asks the
; ROM for the width of the screen rather than assuming 80 columns, and prints
; every control character but the bell instead of swallowing them.
;
; One segment, so the modules are read in order and MORE.ASM brings in DOSSYM
; and sets the ORG itself.  MOREMES.ASM has to come last: BUFFER is 4098 bytes
; of it and the source says so in capitals.

include 'DOSMAC_v211.ASM'       ; ASSUME, and the macros DOSSYM expects

include 'MORE.ASM'              ; brings in DOSSYM and sets ORG 100H
include 'MOREMES.ASM'           ; the messages, and the buffer, last of all
