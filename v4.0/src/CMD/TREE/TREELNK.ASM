; TREE.COM, from the four modules in the order TREE.LNK names them.
;
; One segment, CSEG, holding the program, its data and its stack alike, and
; no group -- so there is one address space and the modules are read once,
; not once per segment the way the programs with two of them are.  The org
; 80H at the top of TREE.ASM names the command line in the program's own PSP
; and writes nothing; the image is what follows the org 100H after it, which
; is where DOS enters a .COM.  That is what LINK and EXE2BIN made of it.

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

; TREE.ASM asks for a page heading at line 185 and declares the HEADER macro
; that writes one at 194, so the name has to mean something already -- the
; same nothing it means once the module's own declaration replaces this.
macro HEADER [TEXT]
{
}

; The labels Microsoft's SALUT preprocessor left behind are named $$IF9 and
; the like, and the leading dollars go to the end -- $$ is fasm's name for
; where the output starts.  MASM assembled the modules apart, so each could
; have its own $$IF9, and four of them are in both TREE.ASM and TREEPAR.ASM;
; TREEPAR's carry the module's mark after the dollars.
	include 'TREE.ASM'
	include 'TREEPAR.ASM'
	include 'TREESYSP.ASM'
	include 'TREESYSM.ASM'
