;**	DEFDBUG.ASM - Debugging Macro Definitions
;
; Every macro this file defines is inside IFDEF DEBUGFLG, and none of the
; three modules defines DEBUGFLG: each of them has the line that would,
; commented out, at the top.  So with the sources as they were shipped all of
; this lays nothing down, and convert.py comments the calls out rather than
; define macros that do nothing -- a macro that expands to nothing still has
; to be able to read its arguments, and DEBUG's are format strings full of $
; and backslashes and lists of lists:
;
;	debug	8,4,<HD error: sense $b$b$b$b code $x\n>,<<[di]>,...>
;
; DBBEG could not be written here at all.  Its body opens an IFDEF and never
; closes it, so the ENDIF at the call site is what closes it and everything
; between the two disappears; FASM has no way to say that, and convert.py
; comments the one such region out instead.
;
; What is left is the one macro that is not a debugging macro:

;**	ERRNZ - generate assembly error if arg != 0
;
; MASM says it with .RADIX 0, which is not a radix, so the assembly stops on
; the line.  FASM has err for that.

macro ERRNZ expr
{
    if (expr) <> 0
	err
    end if
}

; The count DBEND and DBLAB made their labels out of.  Nothing reads it now.
  DBCNT = 1
