; LCD.CPI, from the seven modules LCD.LNK names.
;
; This is neither a driver nor a program: it is the code page information
; file DISPLAY.SYS and MODE load the screen's fonts out of, and there is not
; an instruction in the whole of it.  FONT-R3 is the file's tag and the
; pointer to the table of entries, the five modules after it are a code page
; apiece -- 437, 850, 860, 863 and 865 -- and COPYRIGH is the notice and the
; 1AH that ends the file.
;
; Each code page module holds its one font inline rather than reading it
; out of a file of its own.
;
; No module names anything another module reads.  A code page's header points
; at the next one with the end of its own module, which is where the next
; begins, so the chain is built out of each module's own last address.
;
; One segment to lay down, CODE, which every module declares and every
; module's ASSUME puts CS and DS on.  There is no prefix and nothing is
; entered at: the release links the seven objects and runs EXE2BIN over the
; result, which is what this writes.

use16


; MASM's listing directives, in the spellings the modules use.
macro PAGE [x] {
}
macro TITLE [x] {
}
macro SUBTTL [x] {
}
macro page [x] {
}
macro title [x] {
}
macro subttl [x] {
}
macro .xlist [x] {
}
macro .list [x] {
}
macro .XLIST [x] {
}
macro .LIST [x] {
}


	include 'FONT-R3.ASM'
	include '437-CPI.ASM'
	include '850-CPI.ASM'
	include '860-CPI.ASM'
	include '863-CPI.ASM'
	include '865-CPI.ASM'
	include 'COPYRIGH.ASM'
