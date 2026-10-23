;	SCCSID = @(#)intnat.asm	1.1 85/04/10
BREAK <International data structure format>

;
; Current structure of the data returned by the international call
;
STRUC internat_block
{
.Date_tim_format DW	0		; 0-USA, 1-EUR, 2-JAP
.Currency_sym	DB	0		; Currency Symbol 5 bytes
		DB	0
		DB	0
		DB	0
		DB	0
.Thous_sep	DB	0		; Thousands separator 2 bytes
		DB	0
.Decimal_sep	DB	0		; Decimal separator 2 bytes
		DB	0
.Date_sep	DB	0		; Date separator 2 bytes
		DB	0
.Time_sep	DB	0		; Decimal separator 2 bytes
		DB	0
.Bit_field	DB	0		; Bit values
					;   Bit 0 = 0 if currency symbol first
					;	  = 1 if currency symbol last
					;   Bit 1 = 0 if No space after currency symbol
					;	  = 1 if space after currency symbol
.Currency_cents	DB	0		; Number of places after currency dec point
.Time_24 	DB	0		; 1 if 24 hour time, 0 if 12 hour time
.Map_call	DW	0		; Address of case mapping call (DWORD)
		DW	0		; THIS IS TWO WORDS SO IT CAN BE INITIALIZED
					;  in pieces.
.Data_sep	DB	0		; Data list separator character
		DB	0
}
match =internat_block_LAID_OUT, internat_block_LAID_OUT
{
    internat_block_LAID_OUT equ 1
    virtual at 0
      internat_block internat_block
      sizeof.internat_block = $ - internat_block
    end virtual
}

;
; Max size of the block returned by the INTERNATIONAL call
;
internat_block_max	EQU	32
