; MODE.COM, from the sixteen modules in the order MODE.LNK names them.
;
; One address space, which is the group DGROUP: PRINTF_CODE holds the program
; and ZSEG the 512-byte buffer MODECP works the code pages through, and the
; buffer comes last because the program grows it into whatever memory is
; past the end of itself.  So the modules are read once per segment, the way
; the kernel's are, and the two segments are laid down in that order.
;
; PRINTF_CODE starts where the load module does, which for a .COM is the
; program's own prefix: RESCODE describes what DOS leaves in it -- the
; environment's segment at 2CH, the command line at 80H, and at 60H the
; place the resident serial and printer code is moved to -- and the org 100H
; after that is where DOS enters.  Nothing before it is laid down, so the
; image begins there.  That is what LINK and EXE2BIN made of it.
;
; Five more segments are ROM, VECT, ROM_BIOS and SIGNITURE, which name what
; the ROM BIOS, the interrupt vectors and the EGA hold rather than anything
; the program lays down.  They are read in a pass of their own, S_ABSOLUTE,
; because a name in them would otherwise be declared once for every pass.

use16






; MASM's listing directives, in the spellings the modules use.

macro title [x] {

}

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

macro .xlist [x] {

}

macro .list [x] {

}

macro .xcref [x] {

}

macro .cref [x] {

}



macro .SALL [x] {
}
macro .sall [x] {
}

; MODEQUAT.INC's numbers, read before the modules.  COMMON.STC gives the
; fields of parm_list_entry the values this file's bogus and 0FFH stand for,
; and fasm takes an EQU's value where the EQU is written, so the structure
; would be laid out over names it has no values for: MODEECHO reads it two
; modules before the first module to read them.
	include 'MODEQUAT.INC'

S_ABSOLUTE    = 1
S_PRINTF_CODE = 2
S_ZSEG	      = 3

macro walk
{
	include 'RESCODE.ASM'
	include 'MODEECHO.ASM'
	include 'MODELENG.ASM'
	include 'MODEMES.ASM'
	include 'MODESCRN.ASM'
	include 'MAIN.ASM'
	include 'MODEVID.ASM'
	include 'MODEPRIN.ASM'
	include 'MODECOM.ASM'
	include 'SCRNTAB.ASM'
	include 'MODECP.ASM'
	include 'DISPLAY.ASM'
	include 'TYPAMAT.ASM'
	include 'INVOKE.ASM'
	include 'PARSHELL.ASM'
	include 'MODEPARS.ASM'
}

; What the program does not lay down: read first, so that the names in it
; are there for the passes that do.
	SEGSEL = S_ABSOLUTE
	walk

	SEGSEL = S_PRINTF_CODE
	walk

; ZSEG asks for PARA.
	times (16 - $ mod 16) mod 16 db 0
	SEGSEL = S_ZSEG
	walk
