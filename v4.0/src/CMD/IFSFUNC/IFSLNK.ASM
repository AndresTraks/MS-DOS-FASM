; IFSFUNC.EXE, from the seventeen modules in the order IFSFUNC.LNK names
; them.
;
; Ten of them are IFSFUNC's own -- IFSSESS, IFSDIR, IFSFILE, IFSHAND,
; IFSDEV, IFSUTIL, IFSERROR, IFSFDOS and IFSINIT, which are the installable
; file system, and IFSFLINK, a stub for each of the hundred and seventy-four
; kernel names they call -- and seven are the kernel's: NIBDOS, CONST2,
; MSDATA and MSTABLE out of src/INC, MSDISP and MSCODE out of src/DOS, and
; MSDOSME, which is the same reading MSDOSLNK.ASM gives them.
;
; IFSFUNC answers for a drive the kernel does not know how to read itself: a
; network redirector or any other file system that installs itself on the
; interface INC/IFSSYM.INC describes.  It runs inside the kernel, entered
; through the jump table in the kernel's data, and so with the kernel's own
; SS: what it reads of the kernel's data it reads through that register, at
; the offset this assembly gives the name.  That is why the release linked
; the kernel's own modules in beside its own -- the same reason SHARE does,
; and four of the seven are the four SHARE takes.  The copy of DOSGROUP that
; comes out in IFSFUNC.EXE is there for its offsets and not for its bytes:
; tests/ifsfunc.sh holds them against the ones in MSDOS.SYS.
;
; Nine segments and three address spaces.  IFSSEG is the file system,
; outside the group and first because IFSSESS, which IFSFUNC.LNK links
; first, declares it first.  DOSGROUP is the kernel's six -- START,
; CONSTANTS, DATA, TABLE, CODE, LAST, in the order DOSSEG.ASM gives them --
; which the kernel's modules fill as they fill the kernel's own, with
; IFSFLINK's stubs in CODE.  STACK is the third and last, 406 bytes of it.
;
; So the walk is the kernel's: read all seventeen modules once per segment,
; with SEGSEL saying which pass it is, so that every module's contribution
; to a segment is laid down with the rest of it.  What a module opened with
; "IFSSEG SEGMENT" it now opens with "if SEGSEL = S_IFSSEG", and on the
; other seven passes that contribution is skipped.
;
; The release links the seventeen and runs LINK's /EXEPACK over the result,
; which is what the /EX on IFSFUNC.LNK's last line asks for.  Nothing here
; packs an .EXE and nothing needs to: DOS unpacks one as it loads it, and
; the unpacked image is the same program.

format MZ

; MASM's listing directives, in the spellings the modules use.
macro TITLE [x] {
}
macro title [x] {
}
macro NAME [x] {
}
macro name [x] {
}
macro PAGE [x] {
}
macro page [x] {
}
macro SUBTTL [x] {
}
macro subttl [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}
macro .sall [x] {
}
macro .lall [x] {
}
macro .xall [x] {
}

; The page heading.
macro BREAK [x] {
}
macro Break [x] {
}
macro break [x] {
}

S_IFSSEG    = 1
S_START     = 2
S_CONSTANTS = 3
S_DATA      = 4
S_TABLE     = 5
S_CODE      = 6
S_LAST      = 7
S_STACK     = 8

; The modules, in the order IFSFUNC.LNK gave the linker.
macro walk
{
	include 'IFSSESS.ASM'		; the session and the dispatcher
	include 'IFSDIR.ASM'		; the directory calls
	include 'IFSFILE.ASM'		; the file calls
	include 'IFSHAND.ASM'		; the handle calls
	include 'IFSDEV.ASM'		; the character devices
	include 'IFSUTIL.ASM'		; what the rest of it is built on
	include 'IFSERROR.ASM'		; the error mapping
	include 'IFSFDOS.ASM'		; the calls it makes of the kernel
	include 'IFSINIT.ASM'		; the installation, and the stack
	include '../../INC/NIBDOS.ASM'	; the kernel's switches and constants
	include '../../INC/CONST2.ASM'
	include '../../INC/MSDATA.ASM'	; the kernel's data segment
	include '../../INC/MSTABLE.ASM'	; the kernel's tables
	include '../../DOS/MSDISP.ASM'	; the INT 21H dispatcher
	include '../../DOS/MSCODE.ASM'
	include '../../INC/MSDOSME.ASM'
	include 'IFSFLINK.ASM'		; a stub for each kernel name
}

; The file system itself.
segment IFSSEG_
	SEGSEL = S_IFSSEG
	walk

; The kernel's group, which is one address space: DOSSEG.ASM says how the
; linker aligned each of the six -- START, TABLE and CODE on a byte,
; CONSTANTS and DATA on a word, LAST on a paragraph.
segment DOSGROUP_
	SEGSEL = S_START
	walk
	align	2
	SEGSEL = S_CONSTANTS
	walk
	align	2
	SEGSEL = S_DATA
	walk
; The data segment is as long as MS_DATA.ASM's declarations, which share
; their space with the kernel's initialisation code above and emit nothing
; of their own.  Nothing here ever runs that code or reads that data -- this
; is the copy whose offsets the file system measures from -- but the segment
; has to be the length the linker gave it, so that what follows it is where
; the kernel has it.
    if ($ - DATA_SEG_START) > MS_DATA_SIZE
	display "the init code is longer than the data it overlays",13,10
	err
    end if
	times	MS_DATA_SIZE - ($ - DATA_SEG_START) db 0
	SEGSEL = S_TABLE
	walk
	SEGSEL = S_CODE
	walk
	align	16
	SEGSEL = S_LAST
	walk

; The stack, which IFSINIT declares with the STACK combine type: LINK put SS
; on it and SP at the top, which is what the two lines at the end say here.
segment STACK_
	SEGSEL = S_STACK
	walk
stack_top$ = $

; INC/DOSMAC.INC declares a macro called entry, and the shared headers are
; read over eight readings apiece, so the name is given back to the
; assembler before the entry point can be named.  A purge of a name that
; holds no macro does nothing, so the count here only has to be large
; enough.
rept 256 { purge entry }

stack STACK_:stack_top$
entry IFSSEG_:IFSFUNCINIT	; the source ends with END IFSFUNCinit
