; Fastxxx equates
FastOpen_ID	   equ	   1
FastSeek_ID	   equ	   2
Fast_yes	   equ	   10000000B	 ; fastxxx flag

;Structure definitions
;
STRUC Fasttable_Entry
{
.Fast_Entry_Num	    dw	    2		 ; number of entries
.FastOpen_Seek	    dd	    0		 ; fastopen & fastseek entry address
}
match =Fasttable_Entry_LAID_OUT, Fasttable_Entry_LAID_OUT
{
    Fasttable_Entry_LAID_OUT equ 1
    virtual at 0
      Fasttable_Entry Fasttable_Entry
      sizeof.Fasttable_Entry = $ - Fasttable_Entry
    end virtual
}
;
