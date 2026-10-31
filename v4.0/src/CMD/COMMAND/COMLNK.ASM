; COMMAND.COM, from the thirty-two modules COMMAND.LNK names.
;
; The release links them into COMMAND.EXE and runs EXE2BIN over it, and what
; comes out is one flat image with two address spaces in it, because the
; twelve segments are in two groups and an offset is counted from the group:
;
;   RESGROUP  CODERES, DATARES, BATARENA, BATSEG, ENVARENA, ENVIRONMENT,
;             INIT, TAIL -- the part that stays, loaded at 100h like any
;             .COM, so the file begins where the PSP ends.
;   TRANGROUP TRANCODE, TRANDATA, TRANSPACE, TRANTAIL -- the part that lives
;             at the top of memory and is read back from the file whenever a
;             program has overwritten it.
;
; TAIL is an empty PARA segment, so the offset of its one label is where the
; resident group ends and the transient group begins; the resident keeps that
; offset in TRANSTART and seeks to it to read the transient back.  It seeks to
; the offset rather than to the offset less 100h, so the transient's own
; parameter area is in the file: that is the gap LINK filled with zeroes for
; TRANCODE's ORG 100H, and the hundred and twenty-eight paragraphs of it are
; written out here.
;
; Two fasm segments cannot do this -- the output is one flat .COM -- so the
; two address spaces are two ORGs over one stretch of output, which is what
; the groups were.  The walk below is the kernel's: read the modules once per
; segment, in the order COMSEG.ASM calls the load order.

use16

; MASM's listing directives, in the spellings the modules use.
macro TITLE [x] {
}
macro PAGE [x] {
}
macro SUBTTL [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}
macro .XCREF [x] {
}
macro .CREF [x] {
}
macro .SALL [x] {
}
macro BREAK [x] {
}

S_CODERES     = 1
S_DATARES     = 2
S_BATARENA    = 3
S_BATSEG      = 4
S_ENVARENA    = 5
S_ENVIRONMENT = 6
S_INIT        = 7
S_TAIL        = 8
S_TRANCODE    = 9
S_TRANDATA    = 10
S_TRANSPACE   = 11
S_TRANTAIL    = 12

macro walk
{
	include 'COMMAND1.ASM'
	include 'COMMAND2.ASM'
	include 'RUCODE.ASM'
	include 'RDATA.ASM'
	include 'INIT.ASM'
	include 'IPARSE.ASM'
	include 'UINIT.ASM'
	include 'TCODE.ASM'
	include 'TBATCH.ASM'
	include 'TBATCH2.ASM'
	include 'TFOR.ASM'
	include 'TCMD1A.ASM'
	include 'TCMD1B.ASM'
	include 'TCMD2A.ASM'
	include 'TCMD2B.ASM'
	include 'TENV.ASM'
	include 'TENV2.ASM'
	include 'TMISC1.ASM'
	include 'TMISC2.ASM'
	include 'TPIPE.ASM'
	include 'PARSE2.ASM'
	include 'PATH1.ASM'
	include 'PATH2.ASM'
	include 'TUCODE.ASM'
	include 'COPY.ASM'
	include 'COPYPR1.ASM'
	include 'COPYPR2.ASM'
	include 'CPARSE.ASM'
	include 'TPARSE.ASM'
	include 'TPRINTF.ASM'
	include 'TDATA.ASM'
	include 'TSPC.ASM'
}

; A segment of the group, laid down with every module's contribution to it in
; the link order, and paragraph aligned where the segment asked for PARA.
macro group$ selector, para
{
    if para
	times (16 - $ mod 16) mod 16 db 0
    end if
	SEGSEL = selector
	walk
}

; The resident group.  CODERES begins with the PSP, which DOS builds and the
; file does not hold, so its ORG 100H moves the address without writing
; anything -- which is what fasm's ORG does.
	group$ S_CODERES,     0
	group$ S_DATARES,     0
	group$ S_BATARENA,    1
	group$ S_BATSEG,      1
	group$ S_ENVARENA,    1
	group$ S_ENVIRONMENT, 1
	group$ S_INIT,        1
	group$ S_TAIL,        1

; The transient group begins on the paragraph TAIL left off at, and its
; parameter area is in the file.
	times (16 - $ mod 16) mod 16 db 0
	org	0
	group$ S_TRANCODE,    0
	group$ S_TRANDATA,    0
	group$ S_TRANSPACE,   0
	group$ S_TRANTAIL,    1
