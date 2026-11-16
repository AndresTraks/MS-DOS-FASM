; MKCNTRY.EXE, from the one module the release's makefile assembles.
;
; This is not a driver: COUNTRY.SYS is a file of tables rather than a
; program, and MKCNTRY is what writes it -- the release's build runs
; MKCNTRY.EXE in the directory and keeps what it lays down.  So this is an
; .EXE in its own right, and the only thing under src/DEV that is not a
; driver.
;
; Three segments and no group: cseg for the program, dseg for the tables it
; writes the file out of, and sseg for a stack of a hundred and twenty-eight
; bytes.  An offset is counted from the segment it is in, which is what
; three fasm segments give, and the walk below is the kernel's -- read the
; module once per segment.

format MZ


; MASM's listing directives, in the spellings the module uses.
macro page [x] {
}
macro PAGE [x] {
}
macro title [x] {
}
macro TITLE [x] {
}
macro subttl [x] {
}
macro SUBTTL [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}


S_CSEG = 1
S_DSEG = 2
S_SSEG = 3

macro walk
{
	include 'MKCNTRY.ASM'
}

segment cseg_
SEGSEL = S_CSEG
	walk

segment dseg_
SEGSEL = S_DSEG
	walk

segment sseg_
SEGSEL = S_SSEG
	walk

; The stack the source declares is 128 bytes, so its top is the end of it.
stack sseg_:128

entry cseg_:mkcdif		; the source ends with END MKCDIF
