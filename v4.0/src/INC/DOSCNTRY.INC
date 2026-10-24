;
;Equates for COUNTRY INFORMATION.
SetCountryInfo		EQU	1	;country info
SetUcase		EQU	2	;uppercase table
SetLcase		EQU	3	;lowercase table (Reserved)
SetUcaseFile		EQU	4	;uppercase file spec table
SetFileList		EQU	5	;valid file character list
SetCollate		EQU	6	;collating sequence
SetDBCS 		EQU	7	;double byte character set
SetALL			EQU	-1	;all the entries


;DOS country and code page information table structure.
;Internally, DOS gives a pointer to this table.
;IBMBIO, MODE and NLSFUNC modules communicate with DOS through
;this structure.
STRUC DOS_country_cdpg_info
{
.ccInfo_reserved 	db	8 dup (0) ;reserved for internal use
.ccPath_CountrySys	db	64 dup (0);path and filename for country info
.ccSysCodePage		dw	0	;system code page id
.ccNumber_of_entries	dw	6	; 6 entries
.ccSetUcase		db	SetUcase
.ccUcase_ptr		dd	0	;pointer to Ucase table

.ccSetUcaseFile		db	SetUcaseFile
.ccFileUcase_ptr 	dd	0	;pointer to File Ucase table

.ccSetFileList		db	SetFileList
.ccFileChar_ptr		dd	0	;pointer to File char list table

.ccSetCollate		db	SetCollate
.ccCollate_ptr		dd	0	;pointer to collate table

.ccSetDBCS		db	SetDBCS
.ccDBCS_ptr		dd	0	;pointer to DBCS  table

.ccSetCountryInfo	db	SetCountryInfo
.ccCountryInfoLen	dw	0	;length of country info
.ccDosCountry		dw	0	;active country code id
.ccDosCodePage		dw	0	;active code page id
.ccDFormat		dw	0	;date format
.ccCurSymbol		db	"    ",0;5 byte of (currency symbol+0)
.cc1000Sep		db	" ",0   ;2 byte of (1000 sep. + 0)
.ccDecSep		db	" ",0   ;2 byte of (Decimal sep. + 0)
.ccDateSep		db	" ",0   ;2 byte of (date sep. + 0)
.ccTimeSep		db	" ",0   ;2 byte of (time sep. + 0)
.ccCFormat		db	0	;currency format flags
.ccCSigDigits		db	0	;# of digits in currency
.ccTFormat		db	0	;time format
.ccMono_Ptr		dd	0	;monocase routine entry point
.ccListSep		db	" ",0   ;data list separator
.ccReserved_area 	dw	5 dup(0);reserved

}
match =DOS_country_cdpg_info_LAID_OUT, DOS_country_cdpg_info_LAID_OUT
{
    DOS_country_cdpg_info_LAID_OUT equ 1
    virtual at 0
      DOS_country_cdpg_info DOS_country_cdpg_info
      sizeof.DOS_country_cdpg_info = $ - DOS_country_cdpg_info
    end virtual
}

;Ucase table
STRUC CC_UCASE_TAB
{
.ccUcase_leng	       dw	128
.ccUcase_data	       db	128 dup (0)
}
match =CC_UCASE_TAB_LAID_OUT, CC_UCASE_TAB_LAID_OUT
{
    CC_UCASE_TAB_LAID_OUT equ 1
    virtual at 0
      CC_UCASE_TAB CC_UCASE_TAB
      sizeof.CC_UCASE_TAB = $ - CC_UCASE_TAB
    end virtual
}

;File Ucase table
STRUC CC_FILE_UCASE_TAB
{
.ccFileucase_leng	dw	128
.ccFileucase_data	db	128 dup (0)
}
match =CC_FILE_UCASE_TAB_LAID_OUT, CC_FILE_UCASE_TAB_LAID_OUT
{
    CC_FILE_UCASE_TAB_LAID_OUT equ 1
    virtual at 0
      CC_FILE_UCASE_TAB CC_FILE_UCASE_TAB
      sizeof.CC_FILE_UCASE_TAB = $ - CC_FILE_UCASE_TAB
    end virtual
}

;File char list
STRUC CC_FILE_CHAR_TAB
{
.ccFilechar_leng 	dw	0
.ccFilechar_data 	db	46 dup (0)
}
match =CC_FILE_CHAR_TAB_LAID_OUT, CC_FILE_CHAR_TAB_LAID_OUT
{
    CC_FILE_CHAR_TAB_LAID_OUT equ 1
    virtual at 0
      CC_FILE_CHAR_TAB CC_FILE_CHAR_TAB
      sizeof.CC_FILE_CHAR_TAB = $ - CC_FILE_CHAR_TAB
    end virtual
}

;collate table
STRUC CC_COLLATE_TAB
{
.ccCollate_leng		dw	256
.ccCollate_data		db	256 dup (0)
}
match =CC_COLLATE_TAB_LAID_OUT, CC_COLLATE_TAB_LAID_OUT
{
    CC_COLLATE_TAB_LAID_OUT equ 1
    virtual at 0
      CC_COLLATE_TAB CC_COLLATE_TAB
      sizeof.CC_COLLATE_TAB = $ - CC_COLLATE_TAB
    end virtual
}

;DBCS table -  for DOS 4.00
STRUC CC_DBCS_TAB
{
.ccDBCS_leng	       dw      6
.ccDBCS_data	       db      6 dup (0)
}
match =CC_DBCS_TAB_LAID_OUT, CC_DBCS_TAB_LAID_OUT
{
    CC_DBCS_TAB_LAID_OUT equ 1
    virtual at 0
      CC_DBCS_TAB CC_DBCS_TAB
      sizeof.CC_DBCS_TAB = $ - CC_DBCS_TAB
    end virtual
}

;						2/12/KK
; Define subfunctions of ECS_call ( 63H )	2/12/KK
;						2/12/KK
GetLeadBTBL	EQU	0	;		2/12/KK
SetInterimMode	EQU	1	;		2/12/KK
GetInterimMode	EQU	2	;		2/12/KK
				;		2/12/KK
NonInterimMode	EQU	0	;		2/12/KK
InterimMode	EQU	1	;		2/12/KK

OLD_COUNTRY_SIZE    equ     (sizeof.DOS_country_cdpg_info - DOS_country_cdpg_info.ccDFormat - 10)
NEW_COUNTRY_SIZE    equ     (sizeof.DOS_country_cdpg_info - DOS_country_cdpg_info.ccDosCountry)

;CAPITALIZATION equates
CAP_ONE_CHAR	    equ      20H
CAP_STRING	    equ      21H
CAP_ASCIIZ	    equ      22H
CHECK_YES_NO	    equ      23H
UPPER_TABLE	    equ      80H

;NLS_YES	     equ      59H
;NLS_yes2	     equ      79H
;NLS_NO 	     equ      4EH
;NLS_no2	     equ      6EH





