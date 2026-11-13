; GRAPHICS.COM, from the thirteen modules in the order GRAPHICS.LNK names
; them.
;
; One segment, CODE, and no group, so the modules are read once rather than
; once per segment -- the shape KEYB, GRAFTABL and ASSIGN have.  CODE begins
; where the load module does, which for a .COM is the program's own prefix:
; GRAPHICS.ASM's org 100H is where DOS enters, and the JMP there is the
; whole of that module.  The release links the thirteen and runs EXE2BIN
; over the result, which is the flat image fasm writes here.
;
; GRAPHICS hooks interrupt 5, the print-screen key, and prints the screen --
; text or graphics, black and white or colour, through whichever printer the
; profile named.  GRLOAD and the two modules after it read that profile,
; GRAPHICS.PRO, and keep the tables it describes; everything from the
; resident handler to the end of GRCPSD stays behind.
;
; GRCOMMON.ASM goes in twice.  It holds the eleven routines the colour
; printer module and the black and white one both want -- finding the mode's
; print information, reading a dot, sending a setup string -- and each of
; them INCLUDEs it at the end of its own code rather than calling across.
; MASM assembled the two modules apart and gave each the copy inside it; one
; assembly reads the whole program, so the second copy would be laying down
; the same thirty-three names as the first.  Each copy is therefore read
; with names of its own, the way COMLNK.ASM reads the message retriever's
; two copies.  Nothing outside the two modules asks for any of them --
; GRCOMMON.EXT, which would be how, is read by nothing at all.

use16

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

; CODE begins where the load module does, which is the start of the
; program's own segment, so an offset counted from it is the offset itself.
CODE = 0

; A name given to one of GRCOMMON's two copies: the tag says which module
; the copy is in, and a DEFINE puts the name with the tag on the end
; wherever the name is written.  A DEFINE holds for the rest of the
; assembly, and seven of these thirty-three names are names a later module
; has one of as well -- GRLOAD declares a FOUND of its own -- so each copy's
; names are given back as soon as its module has been read.
macro rename$ tag, [name]
{
	forward
	define name name#_#tag
}
macro unname$ [name]
{
	forward
	restore name
}

; Every name GRCOMMON.ASM lays down, which is every name the two copies
; would otherwise share.
macro common$ tag
{
	rename$ tag, \
	  LOC_MODE_PRT_INFO, SCAN_1_DISPLAYMODE_RECORD, \
	  SCAN_LIST_OF_MODES, NEXT_RECORD, FOUND, NOT_FOUND, \
	  LOC_MODE_PRT_INFO_END, STORE_BOX, STORE_1_BYTE, STORE_BOX_END, \
	  PRINT_BUFFER, PRINT_1_BUF_COLUMN, PRINT_BUFFER_END, \
	  GET_SCREEN_INFO, DET_CUR_SCAN_LNE_LENGTH, CHECK_1_COLUMN, \
	  CHECK_1_PIXEL, DET_LENGTH_END, SETUP_PRT, SEND_1_SETUP_BYTE, \
	  SETUP_PRT_END, RESTORE_PRT, SEND_1_RESTORE_BYTE, \
	  RESTORE_PRT_END, NEW_PRT_LINE, SEND_1_GRAPHICS_BYTE, \
	  NEW_PRT_LINE_ENDP, PRINT_BYTE, PRINT_BYTE_ERROR, PRINT_BYTE_END, \
	  READ_DOT, MODE_11H?, READ_DOT_END
}

; and the same list given back
macro uncommon$
{
	unname$ \
	  LOC_MODE_PRT_INFO, SCAN_1_DISPLAYMODE_RECORD, \
	  SCAN_LIST_OF_MODES, NEXT_RECORD, FOUND, NOT_FOUND, \
	  LOC_MODE_PRT_INFO_END, STORE_BOX, STORE_1_BYTE, STORE_BOX_END, \
	  PRINT_BUFFER, PRINT_1_BUF_COLUMN, PRINT_BUFFER_END, \
	  GET_SCREEN_INFO, DET_CUR_SCAN_LNE_LENGTH, CHECK_1_COLUMN, \
	  CHECK_1_PIXEL, DET_LENGTH_END, SETUP_PRT, SEND_1_SETUP_BYTE, \
	  SETUP_PRT_END, RESTORE_PRT, SEND_1_RESTORE_BYTE, \
	  RESTORE_PRT_END, NEW_PRT_LINE, SEND_1_GRAPHICS_BYTE, \
	  NEW_PRT_LINE_ENDP, PRINT_BYTE, PRINT_BYTE_ERROR, PRINT_BYTE_END, \
	  READ_DOT, MODE_11H?, READ_DOT_END
}

	include 'GRAPHICS.ASM'
	include 'GRINT2FH.ASM'
	include 'GRPATTRN.ASM'
	include 'GRCTRL.ASM'
	include 'GRCPSD.ASM'
	common$ col
	include 'GRCOLPRT.ASM'
	uncommon$
	common$ bw
	include 'GRBWPRT.ASM'
	uncommon$
	include 'GRINST.ASM'
	include 'GRPARSE.ASM'
	include 'GRPARMS.ASM'
	include 'GRLOAD.ASM'
	include 'GRLOAD2.ASM'
	include 'GRLOAD3.ASM'
