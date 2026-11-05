; DISKCOPY.COM, from the five modules in the order DISKCOPY.LNK names them.
;
; One segment, CSEG, holding the program, its data and its stack alike, and
; no group -- so there is one address space and the modules are read once,
; which is DISKCOMP's shape as well.  DISKCOPY.ASM's ORG 100H is where DOS
; enters a .COM, and nothing stands before it but comments and the headers,
; so fasm's ORG, which moves the address counter and writes nothing, leaves
; the file beginning there.  The release links the five and runs EXE2BIN over
; the result.
;
; The labels Microsoft's SALUT preprocessor left behind are named $$IF1 and
; the like; the leading dollars go to the end, since $$ is fasm's name for
; where the output starts.  MASM assembled the modules apart, so each could
; have its own $$IF1, and four of the five share some names: DCOPYSM's carry
; an S after the dollars, DCOPYP's a P, DCOPYPAR's an R and COPYINIT's an I.

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
macro .xlist [x] {
}
macro .LIST [x] {
}
macro .list [x] {
}
macro .xcref [x] {
}
macro .cref [x] {
}

; MASM padded to the next even address, with a NOP in a code segment where
; fasm's align writes a zero.
macro EVEN
{
	align 2
}

; A page heading is asked for before the modules that write one declare it,
; so the name means this nothing until their own declaration replaces it.
macro HEADER [TEXT]
{
}

	include 'DISKCOPY.ASM'
	include 'DCOPYSM.ASM'
	include 'DCOPYP.ASM'
	include 'DCOPYPAR.ASM'
	include 'COPYINIT.ASM'
