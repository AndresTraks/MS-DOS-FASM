;
; segment ordering for MSDOS
;

DIVMES  DB      13,10,"Divide overflow",13,10

DivMesLen   DB  $-DIVMES        ; Length of the above message in bytes


;
; The next variable points to the country table for the current country
;       ( the table returned by the AL=0 INTERNATIONAL call).
;
        IF KANJI
Current_Country DW      JAPTABLE
        ELSE
Current_Country DW      USTABLE
        END IF

;
; The international tabel(s).
; This is simply a sequence of tables of the following form:
;
;               BYTE  Size of this table excluding this byte and the next
;               BYTE  Country code represented by this table
;	                A sequence of n bytes, where n is the number specified
;                       by the first byte above and is not > internat_block_max,
;                       in the correct order for being returned by the
;                       INTERNATIONAL call as follows:
;		WORD	Date format 0=mdy, 1=dmy, 2=ymd
;		5 BYTE	Currency symbol null terminated
;		2 BYTE	thousands separator null terminated
;		2 BYTE	Decimal point null terminated
;		2 BYTE	Date separator null terminated
;		2 BYTE	Time separator null terminated
;		1 BYTE	Bit field.  Currency format.
;			Bit 0.  =0 $ before #  =1 $ after #
;			Bit 1.	no. of spaces between # and $ (0 or 1)
;		1 BYTE	No. of significant decimal digits in currency
;		1 BYTE	Bit field.  Time format.
;			Bit 0.  =0 12 hour clock  =1 24 hour
;		WORD	Segment offset for address of case conversion routine
;		WORD	RESERVED.  Filled in by DOS.  Segment value for above routine
;		2 BYTE	Data list separator null terminated.
;                  NOTE: The segment part of the DWORD Map_call is set
;                       by the INTERNATIONAL call. Do not try to initialize
;                       it to anything meaningful.
;
; The list of tables is terminated by putting a byte of -1 after the last
;       table (a table with length -1).

international_table:

        IF KANJI
                    DB  sizeof.internat_block   ; Size in bytes of this table
                    DB  81              ; Country code
JAPTABLE internat_block 2,'\',0,0,0,0,',',0,'.',0,'-',0,':',0,0,0,1,MAP_DCASE, 0,',',0
        END IF

                    DB  sizeof.internat_block   ; Size in bytes of this table
                    DB  1               ; Country code
USTABLE internat_block 0,'$',0,0,0,0,',',0,'.',0,'-',0,':',0,0,2,0,MAP_DCASE,0,',',0
;	Tables for the IBM PC character set follow.  The values
;	associated with some of the currency symbols may change with
;	other character sets.  You may wish to add or delete country
;	entries.  NOTE: It is not a mistake that the JAPANESE entry
;	has different currency symbols for the KANJI and
;	non-KANJI versions.

IF	KANJI = 0
IF	IBM
                    DB  sizeof.internat_block   ; Size in bytes of this table
                    DB  44              ; Country code
UKTABLE internat_block 1,9Ch,0,0,0,0,',',0,'.',0,'-',0,':',0,0,2,0,MAP_DCASE,0,',',0
                    DB  sizeof.internat_block   ; Size in bytes of this table
                    DB  49               ; Country code
GRMTABLE internat_block 1,'D','M',0,0,0,'.',0,',',0,'.',0,'.',0,3,2,1,MAP_DCASE,0,';',0
                    DB  sizeof.internat_block   ; Size in bytes of this table
                    DB  33               ; Country code
FRNTABLE internat_block 1,'F',0,0,0,0,' ',0,',',0,'/',0,':',0,3,2,1,MAP_DCASE,0,';',0
                    DB  sizeof.internat_block   ; Size in bytes of this table
                    DB  81              ; Country code
JAPTABLE internat_block 2,9DH,0,0,0,0,',',0,'.',0,'-',0,':',0,0,0,1,MAP_DCASE , 0,',',0
END IF
END IF
                    DB  -1              ; End of tables
