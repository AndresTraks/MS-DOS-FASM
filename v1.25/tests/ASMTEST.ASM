; A program for ASM.COM, the Seattle Computer Products assembler this
; release ships, written in the dialect its own source is written in: a
; label is its address and brackets are its contents, INT 33 is INT 21H in
; decimal, and DB takes a string.  tests/asm.sh assembles it with ASM.COM,
; converts the Intel hex with HEX2BIN.COM and runs what comes out.
;
; The 1AH at the end is the end of the file: ASM reads records and stops at
; that byte, the way CP/M did.
	ORG	100H
	MOV	DX,MSG
	MOV	AH,9
	INT	33
	INT	32
MSG:	DB	"Hello from SCP ASM 2.44",13,10,"$"
	END
