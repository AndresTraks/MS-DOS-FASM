; FORMAT.COM, from FORMAT.ASM and the OEM module beside it.
;
; The release shipped no FORMAT.COM -- it is the one utility with source but
; no binary -- so this is the only way to have a formatter on this system.
;
; FORMAT.ASM is the DOS end of it: the switches, the prompts, the volume
; label, writing the boot sector and transferring the system.  Everything that
; touches the disk itself it leaves to an OEM module, and GENFOR.ASM is the
; generic one Microsoft shipped for "any ms-dos disk": it takes the geometry
; from the drive's DPB, zeros the FAT and the directory, and looks for bad
; sectors by reading every allocation unit.  Its DISKFORMAT does nothing,
; there being no track to lay down that DOS knows about -- which suits a
; diskette image exactly, as the sectors are all there whether anyone has
; written them or not.
;
; Assembled as one file, so the PUBLIC and EXTRN pairs the two modules used to
; resolve between them are gone.

include 'DOSMAC_v211.ASM'       ; ASSUME, and the macros DOSSYM expects

; GENFOR.ASM goes last and not second, because the label at the end of it is
; where the scratch space starts: BUFFER, FREESPACE and FATSPACE all point at
; ENDLOC, and FORMAT builds the FAT and the directory it is about to write
; from there on.  With the messages after it they were inside that buffer, so
; the prompt before the format read correctly and every message after it came
; out as a screenful of FAT.

include 'FORMAT.ASM'            ; brings in DOSSYM and sets ORG 100H
include 'FORMES.ASM'            ; the messages, which FORMAT.ASM refers to
include 'GENFOR.ASM'            ; the OEM module, and the end of the program
