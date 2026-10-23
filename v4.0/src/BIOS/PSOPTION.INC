;*******************************************************************
; Parser Options set for IBMBIO SYSCONF module
;*******************************************************************
;
;**** Default assemble swiches definition **************************

match =FarSW, FarSW { FarSW	equ	0 }; Near call expected

match =DateSW, DateSW { DateSW	equ	0 }; Check date format

match =TimeSW, TimeSW { TimeSW	equ	0 }; Check time format

match =FileSW, FileSW { FileSW	equ	1 }; Check file specification

match =CAPSW, CAPSW { CAPSW	equ	0 }; Perform CAPS if specified

match =CmpxSW, CmpxSW { CmpxSW	equ	0 }; Check complex list

match =NumSW, NumSW { NumSW	equ	1 }; Check numeric value

match =KeySW, KeySW { KeySW	equ	0 }; Support keywords

match =SwSW, SwSW { SwSW	equ	1 }; Support switches

match =Val1SW, Val1SW { Val1SW	equ	1 }; Support value definition 1

match =Val2SW, Val2SW { Val2SW	equ	0 }; Support value definition 2

match =Val3SW, Val3SW { Val3SW	equ	1 }; Support value definition 3

match =DrvSW, DrvSW { DrvSW	equ	1 }; Support drive only format

match =QusSW, QusSW { QusSW	equ	0 }; Support quoted string format

