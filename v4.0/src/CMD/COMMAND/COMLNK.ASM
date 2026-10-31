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

; MASM's listing directives, in every spelling the modules use, fasm
; telling one from another where MASM did not.
macro TITLE [x] {
}
macro Title [x] {
}
macro PAGE [x] {
}
macro page [x] {
}
macro SUBTTL [x] {
}
macro .XLIST [x] {
}
macro .xlist [x] {
}
macro .LIST [x] {
}
macro .list [x] {
}
macro .XCREF [x] {
}
macro .xcref [x] {
}
macro .CREF [x] {
}
macro .cref [x] {
}
macro .sall [x] {
}
macro BREAK [x] {
}
macro Break [x] {
}
macro break [x] {
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

; The message retriever goes into COMMAND.COM twice: the resident must still
; be able to speak when a program has overwritten the transient, so RUCODE and
; INIT ask for it as COMR and TPRINTF as COMT.  MASM assembled the modules
; apart and gave each copy its own private labels; one assembly reads the whole
; program, so the two copies would be laying down the same names.  Each group's
; modules are therefore read with the retriever's own names standing for that
; group's copy -- MSGSERV.ASM's COMR switch does the same thing by hand for the
; data table, moving M_RT$ to M_RT2$.
macro rename$ tag, [name]
{
	forward
	define name name#_#tag
}

; Every label MSGSERV.ASM lays down, which is every name the two copies would
; otherwise share.
macro retriever$ tag
{
	rename$ tag, \
	  M_RT$, M_RT2$, READ_DISK_PROC, MXL1$, \
	  MDO3$, MIF4$, MDO7$, MIF7$, \
	  MEN7$, MSR7$, MIF6$, MEN6$, \
	  MIF16$, MIF2$, MIF1$, SETSTDINON, \
	  SETSTDINOFF, SETSTDOUTON, SETSTDOUTOFF, SYSLOADMSG, \
	  MIF20$, MEN20$, M_GET_DBCS_VEC$, MIF23$, \
	  M_CHECKSTDIN$, M_CHECKSTDOUT$, M_VERSION_CHECK$, MIF25$, \
	  MIF27$, MEN27$, MEN25$, SYSGETMSG, \
	  MIF32$, MEN32$, MIF31$, M_GET_MSG_ADDRESS$, \
	  MDO36$, MIF37$, MIF39$, MIF41$, \
	  MEN41$, MEN39$, MEN37$, MIF47$, \
	  MEN47$, MIF46$, MIF51$, MEN46$, \
	  MXL2$, MEN36$, MIF57$, MEN57$, \
	  MIF60$, MEN60$, MIF56$, M_SET_LEN_IN_CX$, \
	  M_FIND_SPECIFIED_MSG$, MIF65$, MEN65$, MIF64$, \
	  MIF69$, MIF71$, MEN69$, MEN64$, \
	  MDO76$, MIF78$, MEN78$, MIF76$, \
	  MEN76$, MSR76$, MIF87$, MIF86$, \
	  MIF75$, MIF91$, SYSDISPMSG, MIF94$, \
	  MEN94$, MIF98$, MIF97$, MEN97$, \
	  MIF93$, MEN93$, MIF104$, MEN104$, \
	  M_DISPLAY_STRING$, MIF107$, MEN107$, MIF110$, \
	  MIF113$, MIF112$, MEN110$, MIF117$, \
	  M_DISPLAY_$_STRING$, MIF120$, MIF119$, MDO123$, \
	  MEN123$, MEN119$, M_DISPLAY_H_STRING$, MIF129$, \
	  MIF128$, MEN128$, MIF127$, M_GET_EXT_ERR_39$, \
	  M_ADD_CRLF$, MIF135$, MIF134$, M_IS_IT_DBCS$, \
	  MDO139$, MIF141$, MEN139$, MIF138$, \
	  M_CONVERT2ASC$, MDO145$, MIF146$, MEN146$, \
	  MLL149$, MIF151$, MIF150$, MIF155$, \
	  MIF154$, MIF159$, MIF158$, MEN154$, \
	  MEN150$, MEN145$, M_DISPLAY_MESSAGE$, MDO165$, \
	  MDO167$, MLL168$, MIF169$, MEN167$, \
	  MIF166$, MDO175$, MIF175$, MLL178$, \
	  MEN175$, MIF180$, MEN180$, MSR175$, \
	  MIF174$, MIF173$, MXL3$, MIF188$, \
	  MEN188$, MIF187$, MIF192$, MIF194$, \
	  MEN192$, MEN187$, MIF200$, MLL202$, \
	  MIF202$, MIF204$, MEN204$, MEN202$, \
	  MEN200$, MIF199$, MEN199$, MIF211$, \
	  MEN211$, MXL4$, MLL214$, MEN165$, \
	  M_EXT_PAR_REPLACE$, MDO215$, MIF216$, MDO219$, \
	  MIF220$, MIF222$, MIF224$, MEN224$, \
	  MEN222$, MEN220$, MIF230$, MEN230$, \
	  MIF229$, MIF234$, MEN229$, MXL5$, \
	  MEN219$, MIF240$, MEN240$, MIF243$, \
	  MEN243$, MIF239$, MIF248$, MEN248$, \
	  MIF247$, MIF252$, MIF254$, MEN252$, \
	  MEN247$, MDO259$, MIF261$, MEN261$, \
	  MIF259$, MEN259$, MSR259$, MIF270$, \
	  MIF269$, MIF258$, MIF274$, M_DISPLAY_REPLACE$, \
	  MIF276$, MDO280$, MIF281$, MIF279$, \
	  MIF278$, MIF287$, MIF286$, MDO291$, \
	  MIF292$, MEN292$, MIF295$, MIF290$, \
	  MDO301$, MIF302$, MIF300$, MIF299$, \
	  MIF307$, MDO310$, MIF309$, MEN307$, \
	  M_FLUSH_BUF$, MIF314$, MEN314$, M_CHAR_REPLACE$, \
	  MIF318$, MIF317$, MDO321$, MEN321$, \
	  MEN317$, M_BIN2ASC_REPLACE$, MIF327$, MIF326$, \
	  MIF330$, MIF325$, MIF335$, MIF334$, \
	  MIF338$, MIF333$, MIF342$, MIF341$, \
	  MIF345$, MEN333$, MEN325$, MIF349$, \
	  M_DATE_REPLACE$, MIF351$, MIF353$, MIF355$, \
	  M_GET_DATE$, MIF357$, M_YEAR$, MIF360$, \
	  MIF359$, M_CONVERTDATE$, MIF363$, M_TIME_REPLACE$, \
	  MLL367$, MIF367$, MEN367$, MIF366$, \
	  MIF365$, MIF372$, MLL374$, MIF374$, \
	  MIF378$, MIF380$, MIF377$, MIF376$, \
	  M_GET_TIME$, MIF384$, M_CONVERTTIME$, MIF386$, \
	  M_WAIT_FOR_INPUT$, MIF388$, MEN388$, MIF392$, \
	  MEN392$, MIF391$, MIF396$, MEN396$
}

; The modules in the order COMMAND.LNK names them: the resident group's
; first, the transient group's from TCODE on.
macro walk
{
	retriever$ R
	include 'COMMAND1.ASM'
	include 'COMMAND2.ASM'
	include 'RUCODE.ASM'
	include 'RDATA.ASM'
	include 'INIT.ASM'
	include 'IPARSE.ASM'
	include 'UINIT.ASM'
	retriever$ T
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
