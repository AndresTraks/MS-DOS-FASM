; MSDOS.SYS, the kernel.
;
; Fifty-five modules and six segments, all of them in one group.  MSDOS.LNK
; gives the order the linker read the modules in, and DOSSEG.ASM the order it
; laid the segments down: START, CONSTANTS, DATA, TABLE, CODE, LAST.  A
; module contributes to whichever of the six it has something to put in --
; most of them to CODE, a dozen to TABLE, a few to CONSTANTS or DATA -- and
; the linker gathered each segment's contributions from every module in turn.
;
; So the walk below reads all fifty-five modules once per segment, with
; SEGSEL saying which pass it is; what a module opened with "CODE SEGMENT" it
; now opens with "if SEGSEL = S_CODE", and on the other five passes that
; contribution is skipped.  The result is the segments in order, each holding
; its modules' contributions in module order, which is what the linker built.
;
; One group means one address space: an offset is an offset whichever segment
; it falls in, so the flat binary this writes needs no relocation and EXE2BIN
; had none to do.
;
; DOSSYM.INC is read once, here, rather than once per module per pass: it is
; the same structures and numbers every time, and reading it inside the walk
; would mean laying its structures out six times over.

use16

; MASM's listing directives, in the spellings the modules use.
macro page [x] {
}
macro PAGE [x] {
}
macro subttl [x] {
}
macro SUBTTL [x] {
}
macro TITLE [x] {
}
macro NAME [x] {
}

include '../INC/DOSSYM.INC'	; the structures and the numbers
include '../INC/DEVSYM.INC'	; the device driver interface

; The rest of the headers, read here for the same reason, and for one more:
; a module's own INCLUDE of them stands inside the segment's IF, and fasm's
; preprocessor reads an INCLUDE inside a macro whichever way the IF went --
; so the guard that keeps a structure from being laid out twice was being set
; on a pass that laid it out not at all.  Read once here, outside the walk,
; each structure is laid out exactly once and every pass can see it.
include '../INC/VERSION.INC'	; the switches that say which release this is
include '../INC/DOSCNTRY.INC'	; the country and code page tables
include '../INC/FASTOPEN.INC'	; the fastopen cache
include '../INC/FASTSEEK.INC'
include '../INC/FASTXXXX.INC'
include '../INC/EA.INC'		; extended attributes
include '../INC/IOCTL.INC'	; the IOCTL subfunctions
include '../INC/IFSSYM.INC'	; the installable file system interface
include '../INC/LOCK.INC'	; the record locking calls
include '../INC/DPL.ASM'	; the server call parameter list

S_START     = 1
S_CONSTANTS = 2
S_DATA      = 3
S_TABLE     = 4
S_CODE      = 5
S_LAST      = 6

; The modules, in the order MSDOS.LNK gave the linker.
macro walk
{
	include '../INC/NIBDOS.ASM'	; the switches and the constants
	include '../INC/CONST2.ASM'
	include '../INC/MSDATA.ASM'	; the data segment
	include '../INC/MSTABLE.ASM'	; the table segment
	include 'MSDISP.ASM'		; the INT 21H dispatcher
	include 'MSCODE.ASM'
	include '../INC/MSDOSME.ASM'
	include 'TIME.ASM'
	include 'GETSET.ASM'
	include 'PARSE.ASM'
	include 'MISC.ASM'
	include 'MISC2.ASM'
	include 'CRIT.ASM'
	include 'CPMIO.ASM'
	include 'CPMIO2.ASM'
	include 'FCBIO.ASM'
	include 'FCBIO2.ASM'
	include 'SEARCH.ASM'
	include 'PATH.ASM'
	include 'IOCTL.ASM'
	include 'DELETE.ASM'
	include 'RENAME.ASM'
	include 'FINFO.ASM'
	include 'DUP.ASM'
	include 'CREATE.ASM'
	include 'OPEN.ASM'
	include 'DINFO.ASM'
	include 'ISEARCH.ASM'
	include 'ABORT.ASM'
	include 'CLOSE.ASM'
	include 'DIRCALL.ASM'
	include 'DISK.ASM'
	include 'DISK2.ASM'
	include 'DISK3.ASM'
	include 'DIR.ASM'
	include 'DIR2.ASM'
	include 'DEV.ASM'
	include 'MKNODE.ASM'
	include 'ROM.ASM'
	include 'FCB.ASM'
	include 'MSCTRLC.ASM'
	include 'FAT.ASM'
	include 'BUF.ASM'
	include 'PROC.ASM'
	include 'ALLOC.ASM'
	include 'SRVCALL.ASM'
	include 'UTIL.ASM'
	include 'HANDLE.ASM'
	include 'MACRO.ASM'
	include 'MACRO2.ASM'
	include 'FILE.ASM'
	include 'LOCK.ASM'
	include 'SHARE.ASM'
	include 'EXTATTR.ASM'
	include 'IFS.ASM'
}

; DOSSEG.ASM says how the linker aligned each of the six: START, TABLE and
; CODE on a byte, CONSTANTS and DATA on a word, LAST on a paragraph.
org 0

; Where each of the six begins, for anything that wants to know -- the test
; holds them against the alignments DOSSEG.ASM asked for.
SEGSEL = S_START
START_AT = $
	walk
	align	2
SEGSEL = S_CONSTANTS
CONSTANTS_AT = $
	walk
	align	2
SEGSEL = S_DATA
DATA_AT = $
	walk
; The data segment is as long as MS_DATA.ASM's declarations, which share
; their space with the initialisation code above and emit nothing of
; their own; what the init code did not fill is zeros, as the linker left
; it.
    if ($ - DATA_SEG_START) > MS_DATA_SIZE
	display "the init code is longer than the data it overlays",13,10
	err
    end if
	times	MS_DATA_SIZE - ($ - DATA_SEG_START) db 0
SEGSEL = S_TABLE
TABLE_AT = $
	walk
SEGSEL = S_CODE
CODE_AT = $
	walk
	align	16
SEGSEL = S_LAST
LAST_AT = $
	walk
