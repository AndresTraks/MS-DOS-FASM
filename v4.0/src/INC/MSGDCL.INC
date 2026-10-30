; This Macro was removed from sysmsg.inc. We had to remove this
; macro and put it into it's own include file in order to clear up
; some assembly errors. MS MASM will not allow a public declaration
; during the second pass of the assembler. IBM MASM will allow this.
;
; Nothing is left of it.  Every macro in here declared a class of messages,
; or one of the retriever's routines, EXTRN where the assembly did not hold
; it and PUBLIC where it did; one assembly reads the whole of a program now,
; so there is nothing to declare either way.
