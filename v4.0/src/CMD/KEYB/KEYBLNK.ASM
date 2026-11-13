; KEYB.COM, from the ten modules in the order KEYB.LNK names them.
;
; One segment, CODE, and no group, so the modules are read once rather than
; once per segment -- the shape TREE, COMP, GRAFTABL and ASSIGN have.  CODE
; begins where the load module does, which for a .COM is the program's own
; prefix: KEYB.ASM's org 100H is where DOS enters, and the JMP there is the
; whole of that module.  The release links the ten and runs EXE2BIN over the
; result, which is the flat image fasm writes here.
;
; KEYB reads a keyboard layout -- its own tables, or a KEYBOARD.SYS written
; by a later DOS -- and keeps a handler on interrupt 9 that turns a scan
; code into the character that layout asks for, with interrupt 2FH so that
; a second copy finds the first and 48H for the 101-key enhancements.
; Everything up to the end of KEYBCPSD stays resident; the parser and the
; command processing above it are let go.
;
; Three of the segments the modules declare are places the program does not
; lay down and are read in a pass of their own, as a VIRTUAL block: ROM at
; 0F000H, which COMMSUBS reads the machine's model byte out of, ROMEXT at 0,
; and DIAGS at 0FFFFH, where the model byte of the oldest machines is.

format binary as 'COM'

; MASM's listing directives, in the spellings the modules use.
macro TITLE [x] {
}
macro title [x] {
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
macro .lall [x] {
}
macro .sall [x] {
}
macro .xall [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}
macro .XCREF [x] {
}
macro .CREF [x] {
}
macro .LALL [x] {
}
macro .SALL [x] {
}
macro .XALL [x] {
}
macro NAME [x] {
}
macro name [x] {
}

; The page heading, which the shared headers ask for in three spellings.
macro BREAK [x] {
}
macro Break [x] {
}
macro break [x] {
}

use16
org 0

	include 'KEYB.ASM'
	include 'KEYBI9.ASM'
	include 'KEYBI9C.ASM'
	include 'KEYBI2F.ASM'
	include 'KEYBI48.ASM'
	include 'KEYBCPSD.ASM'
	include 'COMMSUBS.ASM'
	include 'KEYBTBBL.ASM'
	include 'PARSER.ASM'
	include 'KEYBCMD.ASM'
