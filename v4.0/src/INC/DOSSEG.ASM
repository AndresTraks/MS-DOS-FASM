;	SCCSID = @(#)dosseg.asm	1.1 85/04/10
;	SCCSID = @(#)dosseg.asm	1.1 85/04/10
;
; segment ordering for MSDOS
;
; Every module included this to fix the order the linker laid the six
; segments down in, and then opened whichever of them it had something to
; put in.  The link file names them instead -- see MSDOSLNK.ASM -- and reads
; each module once per segment, so what a module used to open with
; "CODE SEGMENT" it now opens with "if SEGSEL = S_CODE".  They are all one
; group, as DOSGROUP below says, which means one address space: an offset is
; an offset whichever of the six it is in, and the flat layout the link file
; builds is exactly what the linker built.
;
;START		SEGMENT BYTE PUBLIC 'START'
;START		ENDS
;
;CONSTANTS	SEGMENT WORD PUBLIC 'CONST'
;CONSTANTS	ENDS
;
;DATA		SEGMENT WORD PUBLIC 'DATA'
;DATA		ENDS
;
;TABLE		SEGMENT BYTE PUBLIC 'TABLE'
;TABLE		ENDS
;
;CODE		SEGMENT BYTE PUBLIC 'CODE'
;CODE		ENDS
;
;LAST		SEGMENT PARA PUBLIC 'LAST'
;LAST		ENDS
;
;DOSGROUP    GROUP   START,CONSTANTS,DATA,TABLE,CODE,LAST
