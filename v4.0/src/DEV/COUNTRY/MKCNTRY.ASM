	page	84,132
; July 8, 1986 - updated Finland for 437 dcl.
; July 8, 1986 - updated Netherland for 437 dcl.
; July 8, 1986 - updated Italy for 437 dcl.
; July 8, 1986 - updated Canada for 863 dcl.
; July 8, 1986 - updated Belgium for 437 dcl. (except Collate)
; July 8, 1986 - updated AreaSouth for 437 dcl.
; July 8, 1986 - updated Switzerland for 437 dcl.
; July 8, 1986 - updated Norway for 865 dcl.
; July 8, 1986 - updated Denmark for 865 dcl.
; July 14, 1986 - updated Sweden for 437 dcl.
; July 8, 1986 - updated AFE for 850 dcl.
; July 8, 1986 - updated Finland for 850 dcl.
; July 8, 1986 - updated Netherland for 850 dcl.
; July 8, 1986 - updated Canada for 850 dcl.
; July 8, 1986 - updated Italy for 850 dcl.
; July 8, 1986 - updated UK for 850 dcl.
; July 8, 1986 - updated Norway for 850 dcl.
; July 8, 1986 - updated Denmark for 850 dcl.
; July 8, 1986 - updated US for 850 dcl.
; July 8, 1986 - updated Switzerland for 850 dcl.
; July 14, 1986 - updated Sweden for 850 dcl.
; July 14, 1986 - updated Belgium for 850 dcl. (except Collate)
; August 26,1986 - updated Belgium for 437 collate EMG
; August 27,1986 - updated Belgium for 850 collate EMG
; August 27,1986 - updated Area South for 437  EMG
; August 27,1986 - updated Area South for 864  EMG
; August 27,1986 - make all collates 256 bytes	EMG
; August 27,1986 - updated Germany for 850  EMG
; August 27,1986 - updated Spain for 850  EMG
; August 28,1986 - updated Latin America for 850  EMG
; September 12, 1986 - updated SP,IS,CF,AS,PO,LA  EMG
; October 2, 1986 - updated AS and IS  EMG
; July 23,1987	  - DCR to alter Germany collate table to match US 850 DCR037
;		    CNS
; July 23,1987	  - DCR to alter SWISS collate info and ucase table 850 & 437
;		    DCR059--- CNS ***
; July 23,1987	  - DCR to alter Denmark's primary codepage to 850 instead of
;		    865 --- CNS ***
; NOvember 12,1987 - PTM2390 DBCS length of terminating value included for
;		     for DBCS countries
;		   - FILEUPCASE & UCASE swapped for 437 & 850 mapping incorrect
;		   - -ly for DOS 3.3
;		   - Make the FUCASE & UCASE tables equivalent for 850 & 437
; March 9, p3811, Finland to default to 850 now, w/437 as alternate code page
;
; March 30, p4072, LA wants to be same as Spain
; ***CNS
; April 14,1988    Re-adjust LA to match SPAIN which should have 850 as a
;PTM 4389	   default instead of 437 for both countries
;
;	create country.sys file
;
;
	include 'MKCNTRY.INC'
;
if SEGSEL = S_CSEG
;	assume	cs:cseg,ds:dseg
mkcdif:
	mov	ax,dseg_ 		; establish addressability
	mov	ds,ax			;  for ds
	mov	es,ax			;  and es
	lea	dx,[cdifname]; address of file name to create
	xor	cx,cx			; attrib = normal file
	mov	ah,3ch			; create function
	int	21h			; create file
	jnc	create_ok		; jump if create successful
	lea	dx,[crmsg]
	mov	cx,crmlen
	jmp	wrt_msg
create_ok:
	mov	bx,ax			; save handle
	mov	ah,40h			; write function
	mov	cx,cdiend-cdinfo	; length of cdi
	lea	dx,[cdinfo]; address of cdi
	int	21h			; write cdi file
	cmp	ax,cx			; compare bytes written
	jz	write_ok		; jump if write was successful
	lea	dx,[iomsg]
	mov	cx,iomlen
	jmp	wrt_msg
write_ok:
	mov	ah,3eh			; close function
	int	21h			; close cdi file
	lea	dx,[succmsg]
	mov	cx,smlen
wrt_msg:
	mov	bx,1
	mov	ah,40h
	int	21h
	xor	al,al
	mov	ah,4ch			; exit function
	int	21h			; return to exec'ing program
;mkcdif	endp
end if
;
	page
; -----------------------------------------------------------
;
;	Data for COUNTRY.SYS file
;
; -----------------------------------------------------------
if SEGSEL = S_DSEG
label cdinfo word
	db	0ffh,'COUNTRY'          ; signature
	db	8 dup (0)		; reserved
	dw	PTRCNT			; number of pointers in header
	db	CIPTYPE 		; type = country info pointer
	dd	cntryinfo        ; pointer to country information
;
label cntryinfo word
CNTRYCNT=0
	dw	finalCNT		; number of countries
	CTRYENT <CENTRYSIZE,CID_US,437,,,us437_data>	    ; United States
	CTRYENT <CENTRYSIZE,CID_US,850,,,us850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_UK,437,,,uk437_data>	    ; United Kingdom
	CTRYENT <CENTRYSIZE,CID_UK,850,,,uk850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_FR,437,,,fr437_data>	    ; France
	CTRYENT <CENTRYSIZE,CID_FR,850,,,fr850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_GR,437,,,gr437_data>	    ; Germany
	CTRYENT <CENTRYSIZE,CID_GR,850,,,gr850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_SP,850,,,sp850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_SP,437,,,sp437_data>	    ; Spain
	CTRYENT <CENTRYSIZE,CID_IT,437,,,it437_data>	    ; Italy
	CTRYENT <CENTRYSIZE,CID_IT,850,,,it850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_SV,437,,,sv437_data>	    ; Sweden
	CTRYENT <CENTRYSIZE,CID_SV,850,,,sv850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_DK,850,,,dk850_data>	    ; Denmark
	CTRYENT <CENTRYSIZE,CID_DK,865,,,dk865_data>	    ; DCR060 CNS ***** ;AN000;
	CTRYENT <CENTRYSIZE,CID_SW,850,,,sw850_data>	    ; Switzerland
	CTRYENT <CENTRYSIZE,CID_SW,437,,,sw437_data>	    ;
	CTRYENT <CENTRYSIZE,CID_NO,850,,,no850_data>	    ; Norway
	CTRYENT <CENTRYSIZE,CID_NO,865,,,no865_data>	    ;
	CTRYENT <CENTRYSIZE,CID_NL,437,,,nl437_data>	    ; Netherlands
	CTRYENT <CENTRYSIZE,CID_NL,850,,,nl850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_BE,850,,,be850_data>	    ; Belgium
	CTRYENT <CENTRYSIZE,CID_BE,437,,,be437_data>	    ;
	CTRYENT <CENTRYSIZE,CID_FI,850,,,fi850_data>	    ; Finland p3811, requested 850 default
	CTRYENT <CENTRYSIZE,CID_FI,437,,,fi437_data>	    ; Finland
	CTRYENT <CENTRYSIZE,CID_IS,862,,,is862_data>	    ; Israel
	CTRYENT <CENTRYSIZE,CID_IS,850,,,is850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_CA,863,,,ca863_data>	    ; Canada French
	CTRYENT <CENTRYSIZE,CID_CA,850,,,ca850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_AS,864,,,as864_data>	    ; Area South (Arab States)
	CTRYENT <CENTRYSIZE,CID_AS,850,,,as850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_PO,850,,,po850_data>	    ; Portugal
	CTRYENT <CENTRYSIZE,CID_PO,860,,,po860_data>	    ;
	CTRYENT <CENTRYSIZE,CID_LA,850,,,la850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_LA,437,,,la437_data>	    ; Latin America
	CTRYENT <CENTRYSIZE,CID_AFE,437,,,afe437_data>	    ; International English
	CTRYENT <CENTRYSIZE,CID_AFE,850,,,afe850_data>	    ;
	CTRYENT <CENTRYSIZE,CID_JP,932,,,jp932_data>	    ; Japan
	CTRYENT <CENTRYSIZE,CID_JP,437,,,jp437_data>	    ;
	CTRYENT <CENTRYSIZE,CID_KO,934,,,ko934_data>	    ; Korea
	CTRYENT <CENTRYSIZE,CID_KO,437,,,ko437_data>	    ;
	CTRYENT <CENTRYSIZE,CID_PR,936,,,pr936_data>	    ; PRC
	CTRYENT <CENTRYSIZE,CID_PR,437,,,pr437_data>	    ;
	CTRYENT <CENTRYSIZE,CID_TA,938,,,ta938_data>	    ; Taiwan
	CTRYENT <CENTRYSIZE,CID_TA,437,,,ta437_data>	    ;


;dummy	macro	p
;finalCNT	equ	p
;	endm
finalCNT = CNTRYCNT	; what the macro's % made of it
;
label uk437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$1 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,uk437_info
	ctrydat$2 CTRYDAT CDATASIZE,SETCOLLATE,,uk_collate
	ctrydat$3 CTRYDAT CDATASIZE,SETUCASE,,uk_ucase
	ctrydat$4 CTRYDAT CDATASIZE,SETUCASEFILE,,uk_ucase
	ctrydat$5 CTRYDAT CDATASIZE,SETFILELIST,,uk_flist
	ctrydat$6 CTRYDAT CDATASIZE,SETDBCS,,uk_dbcs
;
label uk850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$7 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,uk437_info
	ctrydat$8 CTRYDAT CDATASIZE,SETCOLLATE,,uk850_collate
	ctrydat$9 CTRYDAT CDATASIZE,SETUCASE,,uk850_ucase
	ctrydat$10 CTRYDAT CDATASIZE,SETUCASEFILE,,uk850_ucase
	ctrydat$11 CTRYDAT CDATASIZE,SETFILELIST,,uk_flist
	ctrydat$12 CTRYDAT CDATASIZE,SETDBCS,,uk_dbcs
;
label fr437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$13 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,fr437_info
	ctrydat$14 CTRYDAT CDATASIZE,SETCOLLATE,,fr_collate
	ctrydat$15 CTRYDAT CDATASIZE,SETUCASE,,fr_ucase
	ctrydat$16 CTRYDAT CDATASIZE,SETUCASEFILE,,fr_ucase
	ctrydat$17 CTRYDAT CDATASIZE,SETFILELIST,,fr_flist
	ctrydat$18 CTRYDAT CDATASIZE,SETDBCS,,fr_dbcs
;
label fr850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$19 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,fr437_info
	ctrydat$20 CTRYDAT CDATASIZE,SETCOLLATE,,fr850_collate
	ctrydat$21 CTRYDAT CDATASIZE,SETUCASE,,fr850_ucase
	ctrydat$22 CTRYDAT CDATASIZE,SETUCASEFILE,,fr850_ucase
	ctrydat$23 CTRYDAT CDATASIZE,SETFILELIST,,fr_flist
	ctrydat$24 CTRYDAT CDATASIZE,SETDBCS,,fr_dbcs
;
label gr437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$25 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,gr437_info
	ctrydat$26 CTRYDAT CDATASIZE,SETCOLLATE,,gr_collate
	ctrydat$27 CTRYDAT CDATASIZE,SETUCASE,,gr_ucase
	ctrydat$28 CTRYDAT CDATASIZE,SETUCASEFILE,,gr_ucase
	ctrydat$29 CTRYDAT CDATASIZE,SETFILELIST,,gr_flist
	ctrydat$30 CTRYDAT CDATASIZE,SETDBCS,,gr_dbcs
;
label gr850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$31 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,gr437_info
	ctrydat$32 CTRYDAT CDATASIZE,SETCOLLATE,,gr850_collate
	ctrydat$33 CTRYDAT CDATASIZE,SETUCASE,,gr850_ucase
	ctrydat$34 CTRYDAT CDATASIZE,SETUCASEFILE,,gr850_ucase
	ctrydat$35 CTRYDAT CDATASIZE,SETFILELIST,,gr_flist
	ctrydat$36 CTRYDAT CDATASIZE,SETDBCS,,gr_dbcs
;
label sp437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$37 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,sp437_info
	ctrydat$38 CTRYDAT CDATASIZE,SETCOLLATE,,sp_collate
	ctrydat$39 CTRYDAT CDATASIZE,SETUCASE,,sp_ucase
	ctrydat$40 CTRYDAT CDATASIZE,SETUCASEFILE,,sp_ucase
	ctrydat$41 CTRYDAT CDATASIZE,SETFILELIST,,sp_flist
	ctrydat$42 CTRYDAT CDATASIZE,SETDBCS,,sp_dbcs
;
label sp850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$43 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,sp850_info
	ctrydat$44 CTRYDAT CDATASIZE,SETCOLLATE,,sp850_collate
	ctrydat$45 CTRYDAT CDATASIZE,SETUCASE,,sp850_ucase
	ctrydat$46 CTRYDAT CDATASIZE,SETUCASEFILE,,sp850_ucase
	ctrydat$47 CTRYDAT CDATASIZE,SETFILELIST,,sp_flist
	ctrydat$48 CTRYDAT CDATASIZE,SETDBCS,,sp_dbcs
;
label it437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$49 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,it437_info
	ctrydat$50 CTRYDAT CDATASIZE,SETCOLLATE,,it_collate
	ctrydat$51 CTRYDAT CDATASIZE,SETUCASE,,it_ucase
	ctrydat$52 CTRYDAT CDATASIZE,SETUCASEFILE,,it_ucase
	ctrydat$53 CTRYDAT CDATASIZE,SETFILELIST,,it_flist
	ctrydat$54 CTRYDAT CDATASIZE,SETDBCS,,it_dbcs
;
label it850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$55 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,it437_info
	ctrydat$56 CTRYDAT CDATASIZE,SETCOLLATE,,it850_collate
	ctrydat$57 CTRYDAT CDATASIZE,SETUCASE,,it850_ucase
	ctrydat$58 CTRYDAT CDATASIZE,SETUCASEFILE,,it850_ucase
	ctrydat$59 CTRYDAT CDATASIZE,SETFILELIST,,it_flist
	ctrydat$60 CTRYDAT CDATASIZE,SETDBCS,,it_dbcs
;
label sv437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$61 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,sv437_info
	ctrydat$62 CTRYDAT CDATASIZE,SETCOLLATE,,sv_collate
	ctrydat$63 CTRYDAT CDATASIZE,SETUCASE,,sv_ucase
	ctrydat$64 CTRYDAT CDATASIZE,SETUCASEFILE,,sv_ucase
	ctrydat$65 CTRYDAT CDATASIZE,SETFILELIST,,sv_flist
	ctrydat$66 CTRYDAT CDATASIZE,SETDBCS,,sv_dbcs
;
label sv850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$67 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,sv437_info
	ctrydat$68 CTRYDAT CDATASIZE,SETCOLLATE,,sv850_collate
	ctrydat$69 CTRYDAT CDATASIZE,SETUCASE,,sv850_ucase
	ctrydat$70 CTRYDAT CDATASIZE,SETUCASEFILE,,sv850_ucase
	ctrydat$71 CTRYDAT CDATASIZE,SETFILELIST,,sv_flist
	ctrydat$72 CTRYDAT CDATASIZE,SETDBCS,,sv_dbcs
;
label dk850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$73 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,dk865_info
	ctrydat$74 CTRYDAT CDATASIZE,SETCOLLATE,,dk850_collate
	ctrydat$75 CTRYDAT CDATASIZE,SETUCASE,,dk850_ucase
	ctrydat$76 CTRYDAT CDATASIZE,SETUCASEFILE,,dk850_ucase
	ctrydat$77 CTRYDAT CDATASIZE,SETFILELIST,,dk_flist
	ctrydat$78 CTRYDAT CDATASIZE,SETDBCS,,dk_dbcs
;
label dk865_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$79 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,dk865_info
	ctrydat$80 CTRYDAT CDATASIZE,SETCOLLATE,,dk_collate
	ctrydat$81 CTRYDAT CDATASIZE,SETUCASE,,dk_ucase
	ctrydat$82 CTRYDAT CDATASIZE,SETUCASEFILE,,dk_ucase
	ctrydat$83 CTRYDAT CDATASIZE,SETFILELIST,,dk_flist
	ctrydat$84 CTRYDAT CDATASIZE,SETDBCS,,dk_dbcs
;
label sw437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$85 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,sw437_info
	ctrydat$86 CTRYDAT CDATASIZE,SETCOLLATE,,sw_collate
	ctrydat$87 CTRYDAT CDATASIZE,SETUCASE,,sw_ucase
	ctrydat$88 CTRYDAT CDATASIZE,SETUCASEFILE,,sw_ucase
	ctrydat$89 CTRYDAT CDATASIZE,SETFILELIST,,sw_flist
	ctrydat$90 CTRYDAT CDATASIZE,SETDBCS,,sw_dbcs
;
label sw850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$91 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,sw437_info
	ctrydat$92 CTRYDAT CDATASIZE,SETCOLLATE,,sw850_collate
	ctrydat$93 CTRYDAT CDATASIZE,SETUCASE,,sw850_ucase
	ctrydat$94 CTRYDAT CDATASIZE,SETUCASEFILE,,sw850_ucase
	ctrydat$95 CTRYDAT CDATASIZE,SETFILELIST,,sw_flist
	ctrydat$96 CTRYDAT CDATASIZE,SETDBCS,,sw_dbcs
;
label no865_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$97 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,no865_info
	ctrydat$98 CTRYDAT CDATASIZE,SETCOLLATE,,no_collate
	ctrydat$99 CTRYDAT CDATASIZE,SETUCASE,,no_ucase
	ctrydat$100 CTRYDAT CDATASIZE,SETUCASEFILE,,no_ucase
	ctrydat$101 CTRYDAT CDATASIZE,SETFILELIST,,no_flist
	ctrydat$102 CTRYDAT CDATASIZE,SETDBCS,,no_dbcs
;
label no850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$103 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,no865_info
	ctrydat$104 CTRYDAT CDATASIZE,SETCOLLATE,,no850_collate
	ctrydat$105 CTRYDAT CDATASIZE,SETUCASE,,no850_ucase
	ctrydat$106 CTRYDAT CDATASIZE,SETUCASEFILE,,no850_ucase
	ctrydat$107 CTRYDAT CDATASIZE,SETFILELIST,,no_flist
	ctrydat$108 CTRYDAT CDATASIZE,SETDBCS,,no_dbcs
;
label nl437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$109 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,nl437_info
	ctrydat$110 CTRYDAT CDATASIZE,SETCOLLATE,,nl_collate
	ctrydat$111 CTRYDAT CDATASIZE,SETUCASE,,nl_ucase
	ctrydat$112 CTRYDAT CDATASIZE,SETUCASEFILE,,nl_ucase
	ctrydat$113 CTRYDAT CDATASIZE,SETFILELIST,,nl_flist
	ctrydat$114 CTRYDAT CDATASIZE,SETDBCS,,nl_dbcs
;
label nl850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$115 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,nl437_info
	ctrydat$116 CTRYDAT CDATASIZE,SETCOLLATE,,nl850_collate
	ctrydat$117 CTRYDAT CDATASIZE,SETUCASE,,nl850_ucase
	ctrydat$118 CTRYDAT CDATASIZE,SETUCASEFILE,,nl850_ucase
	ctrydat$119 CTRYDAT CDATASIZE,SETFILELIST,,nl_flist
	ctrydat$120 CTRYDAT CDATASIZE,SETDBCS,,nl_dbcs
;
label be437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$121 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,be437_info
	ctrydat$122 CTRYDAT CDATASIZE,SETCOLLATE,,be_collate
	ctrydat$123 CTRYDAT CDATASIZE,SETUCASE,,be_ucase
	ctrydat$124 CTRYDAT CDATASIZE,SETUCASEFILE,,be_ucase
	ctrydat$125 CTRYDAT CDATASIZE,SETFILELIST,,be_flist
	ctrydat$126 CTRYDAT CDATASIZE,SETDBCS,,be_dbcs
;
label be850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$127 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,be437_info
	ctrydat$128 CTRYDAT CDATASIZE,SETCOLLATE,,be850_collate
	ctrydat$129 CTRYDAT CDATASIZE,SETUCASE,,be850_ucase
	ctrydat$130 CTRYDAT CDATASIZE,SETUCASEFILE,,be850_ucase
	ctrydat$131 CTRYDAT CDATASIZE,SETFILELIST,,be_flist
	ctrydat$132 CTRYDAT CDATASIZE,SETDBCS,,be_dbcs
;
label fi437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$133 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,fi437_info
	ctrydat$134 CTRYDAT CDATASIZE,SETCOLLATE,,fi_collate
	ctrydat$135 CTRYDAT CDATASIZE,SETUCASE,,fi_ucase
	ctrydat$136 CTRYDAT CDATASIZE,SETUCASEFILE,,fi_ucase
	ctrydat$137 CTRYDAT CDATASIZE,SETFILELIST,,fi_flist
	ctrydat$138 CTRYDAT CDATASIZE,SETDBCS,,fi_dbcs
;
label fi850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$139 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,fi437_info
	ctrydat$140 CTRYDAT CDATASIZE,SETCOLLATE,,fi850_collate
	ctrydat$141 CTRYDAT CDATASIZE,SETUCASE,,fi850_ucase
	ctrydat$142 CTRYDAT CDATASIZE,SETUCASEFILE,,fi850_ucase
	ctrydat$143 CTRYDAT CDATASIZE,SETFILELIST,,fi_flist
	ctrydat$144 CTRYDAT CDATASIZE,SETDBCS,,fi_dbcs
;
label us437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$145 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,us437_info
	ctrydat$146 CTRYDAT CDATASIZE,SETCOLLATE,,us_collate
	ctrydat$147 CTRYDAT CDATASIZE,SETUCASE,,us_ucase
	ctrydat$148 CTRYDAT CDATASIZE,SETUCASEFILE,,us_ucase
	ctrydat$149 CTRYDAT CDATASIZE,SETFILELIST,,us_flist
	ctrydat$150 CTRYDAT CDATASIZE,SETDBCS,,us_dbcs
;
label us850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$151 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,us437_info
	ctrydat$152 CTRYDAT CDATASIZE,SETCOLLATE,,us850_collate
	ctrydat$153 CTRYDAT CDATASIZE,SETUCASE,,us850_ucase
	ctrydat$154 CTRYDAT CDATASIZE,SETUCASEFILE,,us850_ucase
	ctrydat$155 CTRYDAT CDATASIZE,SETFILELIST,,us_flist
	ctrydat$156 CTRYDAT CDATASIZE,SETDBCS,,us_dbcs
;
label is862_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$157 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,is862_info
	ctrydat$158 CTRYDAT CDATASIZE,SETCOLLATE,,is_collate
	ctrydat$159 CTRYDAT CDATASIZE,SETUCASE,,is_ucase
	ctrydat$160 CTRYDAT CDATASIZE,SETUCASEFILE,,is_ucase
	ctrydat$161 CTRYDAT CDATASIZE,SETFILELIST,,is_flist
	ctrydat$162 CTRYDAT CDATASIZE,SETDBCS,,is_dbcs
;
label is850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$163 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,is862_info
	ctrydat$164 CTRYDAT CDATASIZE,SETCOLLATE,,is850_collate
	ctrydat$165 CTRYDAT CDATASIZE,SETUCASE,,is850_ucase
	ctrydat$166 CTRYDAT CDATASIZE,SETUCASEFILE,,is850_ucase
	ctrydat$167 CTRYDAT CDATASIZE,SETFILELIST,,is_flist
	ctrydat$168 CTRYDAT CDATASIZE,SETDBCS,,is_dbcs
;
label ca863_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$169 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,ca863_info
	ctrydat$170 CTRYDAT CDATASIZE,SETCOLLATE,,ca_collate
	ctrydat$171 CTRYDAT CDATASIZE,SETUCASE,,ca_ucase
	ctrydat$172 CTRYDAT CDATASIZE,SETUCASEFILE,,ca_ucase
	ctrydat$173 CTRYDAT CDATASIZE,SETFILELIST,,ca_flist
	ctrydat$174 CTRYDAT CDATASIZE,SETDBCS,,ca_dbcs
;
label ca850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$175 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,ca863_info
	ctrydat$176 CTRYDAT CDATASIZE,SETCOLLATE,,ca850_collate
	ctrydat$177 CTRYDAT CDATASIZE,SETUCASE,,ca850_ucase
	ctrydat$178 CTRYDAT CDATASIZE,SETUCASEFILE,,ca850_ucase
	ctrydat$179 CTRYDAT CDATASIZE,SETFILELIST,,ca_flist
	ctrydat$180 CTRYDAT CDATASIZE,SETDBCS,,ca_dbcs
;
label as864_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$181 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,as864_info
	ctrydat$182 CTRYDAT CDATASIZE,SETCOLLATE,,as_collate
	ctrydat$183 CTRYDAT CDATASIZE,SETUCASE,,as_ucase
	ctrydat$184 CTRYDAT CDATASIZE,SETUCASEFILE,,as_ucase
	ctrydat$185 CTRYDAT CDATASIZE,SETFILELIST,,as_flist
	ctrydat$186 CTRYDAT CDATASIZE,SETDBCS,,as_dbcs
;
label as850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$187 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,as850_info
	ctrydat$188 CTRYDAT CDATASIZE,SETCOLLATE,,as850_collate
	ctrydat$189 CTRYDAT CDATASIZE,SETUCASE,,as850_ucase
	ctrydat$190 CTRYDAT CDATASIZE,SETUCASEFILE,,as850_ucase
	ctrydat$191 CTRYDAT CDATASIZE,SETFILELIST,,as_flist
	ctrydat$192 CTRYDAT CDATASIZE,SETDBCS,,as_dbcs
;
label po860_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$193 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,po860_info
	ctrydat$194 CTRYDAT CDATASIZE,SETCOLLATE,,po_collate
	ctrydat$195 CTRYDAT CDATASIZE,SETUCASE,,po_ucase
	ctrydat$196 CTRYDAT CDATASIZE,SETUCASEFILE,,po_ucase
	ctrydat$197 CTRYDAT CDATASIZE,SETFILELIST,,po_flist
	ctrydat$198 CTRYDAT CDATASIZE,SETDBCS,,po_dbcs
;
label po850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$199 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,po860_info
	ctrydat$200 CTRYDAT CDATASIZE,SETCOLLATE,,po850_collate
	ctrydat$201 CTRYDAT CDATASIZE,SETUCASE,,po850_ucase
	ctrydat$202 CTRYDAT CDATASIZE,SETUCASEFILE,,po850_ucase
	ctrydat$203 CTRYDAT CDATASIZE,SETFILELIST,,po_flist
	ctrydat$204 CTRYDAT CDATASIZE,SETDBCS,,po_dbcs
;
label la437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$205 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,la437_info
	ctrydat$206 CTRYDAT CDATASIZE,SETCOLLATE,,la_collate
	ctrydat$207 CTRYDAT CDATASIZE,SETUCASE,,la_ucase
	ctrydat$208 CTRYDAT CDATASIZE,SETUCASEFILE,,la_ucase
	ctrydat$209 CTRYDAT CDATASIZE,SETFILELIST,,la_flist
	ctrydat$210 CTRYDAT CDATASIZE,SETDBCS,,la_dbcs
;
label la850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$211 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,la437_info
	ctrydat$212 CTRYDAT CDATASIZE,SETCOLLATE,,la850_collate
	ctrydat$213 CTRYDAT CDATASIZE,SETUCASE,,la850_ucase
	ctrydat$214 CTRYDAT CDATASIZE,SETUCASEFILE,,la850_ucase
	ctrydat$215 CTRYDAT CDATASIZE,SETFILELIST,,la_flist
	ctrydat$216 CTRYDAT CDATASIZE,SETDBCS,,la_dbcs
;
label jp932_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$217 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,jp932_info
	ctrydat$218 CTRYDAT CDATASIZE,SETCOLLATE,,jp932_collate
	ctrydat$219 CTRYDAT CDATASIZE,SETUCASE,,jp932_ucase
	ctrydat$220 CTRYDAT CDATASIZE,SETUCASEFILE,,jp932_ucase
	ctrydat$221 CTRYDAT CDATASIZE,SETFILELIST,,jp932_flist
	ctrydat$222 CTRYDAT CDATASIZE,SETDBCS,,jp932_dbcs
;
label jp437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$223 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,jp437_info
	ctrydat$224 CTRYDAT CDATASIZE,SETCOLLATE,,jp437_collate
	ctrydat$225 CTRYDAT CDATASIZE,SETUCASE,,jp437_ucase
	ctrydat$226 CTRYDAT CDATASIZE,SETUCASEFILE,,jp437_ucase
	ctrydat$227 CTRYDAT CDATASIZE,SETFILELIST,,jp437_flist
	ctrydat$228 CTRYDAT CDATASIZE,SETDBCS,,jp437_dbcs
;
label ko934_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$229 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,ko934_info
	ctrydat$230 CTRYDAT CDATASIZE,SETCOLLATE,,ko934_collate
	ctrydat$231 CTRYDAT CDATASIZE,SETUCASE,,ko934_ucase
	ctrydat$232 CTRYDAT CDATASIZE,SETUCASEFILE,,ko934_ucase
	ctrydat$233 CTRYDAT CDATASIZE,SETFILELIST,,ko934_flist
	ctrydat$234 CTRYDAT CDATASIZE,SETDBCS,,ko934_dbcs
;
label ko437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$235 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,ko437_info
	ctrydat$236 CTRYDAT CDATASIZE,SETCOLLATE,,ko437_collate
	ctrydat$237 CTRYDAT CDATASIZE,SETUCASE,,ko437_ucase
	ctrydat$238 CTRYDAT CDATASIZE,SETUCASEFILE,,ko437_ucase
	ctrydat$239 CTRYDAT CDATASIZE,SETFILELIST,,ko437_flist
	ctrydat$240 CTRYDAT CDATASIZE,SETDBCS,,ko437_dbcs
;
label pr936_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$241 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,pr936_info
	ctrydat$242 CTRYDAT CDATASIZE,SETCOLLATE,,pr936_collate
	ctrydat$243 CTRYDAT CDATASIZE,SETUCASE,,pr936_ucase
	ctrydat$244 CTRYDAT CDATASIZE,SETUCASEFILE,,pr936_ucase
	ctrydat$245 CTRYDAT CDATASIZE,SETFILELIST,,pr936_flist
	ctrydat$246 CTRYDAT CDATASIZE,SETDBCS,,pr936_dbcs
;
label pr437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$247 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,pr437_info
	ctrydat$248 CTRYDAT CDATASIZE,SETCOLLATE,,pr437_collate
	ctrydat$249 CTRYDAT CDATASIZE,SETUCASE,,pr437_ucase
	ctrydat$250 CTRYDAT CDATASIZE,SETUCASEFILE,,pr437_ucase
	ctrydat$251 CTRYDAT CDATASIZE,SETFILELIST,,pr437_flist
	ctrydat$252 CTRYDAT CDATASIZE,SETDBCS,,pr437_dbcs
;
label ta938_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$253 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,ta938_info
	ctrydat$254 CTRYDAT CDATASIZE,SETCOLLATE,,ta938_collate
	ctrydat$255 CTRYDAT CDATASIZE,SETUCASE,,ta938_ucase
	ctrydat$256 CTRYDAT CDATASIZE,SETUCASEFILE,,ta938_ucase
	ctrydat$257 CTRYDAT CDATASIZE,SETFILELIST,,ta938_flist
	ctrydat$258 CTRYDAT CDATASIZE,SETDBCS,,ta938_dbcs
;
label ta437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$259 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,ta437_info
	ctrydat$260 CTRYDAT CDATASIZE,SETCOLLATE,,ta437_collate
	ctrydat$261 CTRYDAT CDATASIZE,SETUCASE,,ta437_ucase
	ctrydat$262 CTRYDAT CDATASIZE,SETUCASEFILE,,ta437_ucase
	ctrydat$263 CTRYDAT CDATASIZE,SETFILELIST,,ta437_flist
	ctrydat$264 CTRYDAT CDATASIZE,SETDBCS,,ta437_dbcs
;
label afe437_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$265 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,afe437_info
	ctrydat$266 CTRYDAT CDATASIZE,SETCOLLATE,,afe_collate
	ctrydat$267 CTRYDAT CDATASIZE,SETUCASE,,afe_ucase
	ctrydat$268 CTRYDAT CDATASIZE,SETUCASEFILE,,afe_ucase
	ctrydat$269 CTRYDAT CDATASIZE,SETFILELIST,,afe_flist
	ctrydat$270 CTRYDAT CDATASIZE,SETDBCS,,afe_dbcs
;
label afe850_data word
	dw	CDATAITEMS				; number of entries
	ctrydat$271 CTRYDAT CDATASIZE,SETCOUNTRYINFO,,afe437_info
	ctrydat$272 CTRYDAT CDATASIZE,SETCOLLATE,,afe850_collate
	ctrydat$273 CTRYDAT CDATASIZE,SETUCASE,,afe850_ucase
	ctrydat$274 CTRYDAT CDATASIZE,SETUCASEFILE,,afe850_ucase
	ctrydat$275 CTRYDAT CDATASIZE,SETFILELIST,,afe_flist
	ctrydat$276 CTRYDAT CDATASIZE,SETDBCS,,afe_dbcs
	page
; ----------------------------------------
;
;	World Trade Country Info Tables
;
; ----------------------------------------
label uk437_info word
		ctable$1 CTABLE 
		cinfo$1 CINFO CID_UK,437,DATE_DMY,156,,,,,',',,'.',,'-',,':',,,2,HR12,,','
;
label fr437_info word
		ctable$2 CTABLE 
		cinfo$2 CINFO CID_FR,437,DATE_DMY,'F',,,,,' ',,',',,'/',,':',,3,2,HR24,,';'
;
label gr437_info word
		ctable$3 CTABLE 
		cinfo$3 CINFO CID_GR,437,DATE_DMY,'D','M',,,,'.',,',',,'.',,'.',,2,2,HR24,,';'
;
label sp437_info word
		ctable$4 CTABLE 
		cinfo$4 CINFO CID_SP,437,DATE_DMY,158,,,,,'.',,',',,'/',,':',,3,2,HR24,,';'
;
label sp850_info word
		ctable$5 CTABLE 
		cinfo$5 CINFO CID_SP,437,DATE_DMY,'P','t','s',,,'.',,',',,'/',,':',,3,2,HR24,,';'
;
label it437_info word
		ctable$6 CTABLE 
		cinfo$6 CINFO CID_IT,437,DATE_DMY,'L','.',,,,'.',,',',,'/',,':',,,,HR24,,';'
;
label sv437_info word
		ctable$7 CTABLE 
		cinfo$7 CINFO CID_SV,437,DATE_YMD,'S','E','K',,,'.',,',',,'-',,'.',,2,2,HR24,,';'
;
label dk865_info word
		ctable$8 CTABLE 
		cinfo$8 CINFO CID_DK,865,DATE_DMY,'k','r',,,,'.',,',',,'-',,'.',,2,2,HR24,,';'
;
label sw437_info word
		ctable$9 CTABLE 
		cinfo$9 CINFO CID_SW,437,DATE_DMY,'F','r',,,,"'",,'.',,'.',,'.',,2,2,HR24,,','
;
;*** CNS Change date separator from slash to period - DCR 357
label no865_info word
		ctable$10 CTABLE 
		cinfo$10 CINFO CID_NO,865,DATE_DMY,'K','r',,,,'.',,',',,'.',,'.',,2,2,HR24,,';' ;AN000;
;*** CNS Change date separator from slash to period - DCR 357
;*** Field #14
;
label nl437_info word
		ctable$11 CTABLE 
		cinfo$11 CINFO CID_NL,437,DATE_DMY,159,,,,,'.',,',',,'-',,':',,2,2,HR24,,';'
;
label be437_info word
		ctable$12 CTABLE 
		cinfo$12 CINFO CID_BE,437,DATE_DMY,'B','E','F',,,'.',,',',,'/',,':',,2,2,HR24,,';'
;
label fi437_info word
		ctable$13 CTABLE 
		cinfo$13 CINFO CID_FI,437,DATE_DMY,'m','k',,,,' ',,',',,'.',,'.',,3,2,HR24,,';'
;
label jp437_info word
label ko437_info word
label pr437_info word
label ta437_info word
label us437_info word
		ctable$14 CTABLE 
		cinfo$14 CINFO CID_US,437,DATE_MDY,'$',,,,,',',,'.',,'-',,':',,,2,HR12,,','
;
label is862_info word
		ctable$15 CTABLE 
		cinfo$15 CINFO CID_IS,862,DATE_DMY,153,,,,,',',,'.',,' ',,':',,2,2,HR24,,','
;
label ca863_info word
		ctable$16 CTABLE 
		cinfo$16 CINFO CID_CA,863,DATE_YMD,'$',,,,,' ',,',',,'-',,':',,3,2,HR24,,';'
;
label as864_info word
		ctable$17 CTABLE 
		cinfo$17 CINFO CID_AS,864,DATE_DMY,164,,,,,'.',,',',,'/',,':',,3,3,HR12,,';'
;
label as850_info word
		ctable$18 CTABLE 
		cinfo$18 CINFO CID_AS,864,DATE_DMY,207,,,,,'.',,',',,'/',,':',,3,3,HR12,,';'
;
label po860_info word
		ctable$19 CTABLE 
		cinfo$19 CINFO CID_PO,860,DATE_DMY,'$',,,,,'.',,',',,'/',,':',,4,2,HR24,,';'
;
label la437_info word
		ctable$20 CTABLE 
		cinfo$20 CINFO CID_LA,437,DATE_DMY,'$',,,,,',',,'.',,'/',,':',,3,2,HR24,,';'
;
label afe437_info word
		ctable$21 CTABLE 
		cinfo$21 CINFO CID_AFE,437,DATE_DMY,'$',,,,,',',,'.',,'-',,':',,,2,HR12,,','
;
label jp932_info word
		ctable$22 CTABLE 
		cinfo$22 CINFO CID_JP,932,DATE_YMD,'\',,,,,',',,'.',,'-',,':',,,0,HR24,,','
;
label ko934_info word
		ctable$23 CTABLE 
		cinfo$23 CINFO CID_KO,934,DATE_YMD,'\',,,,,',',,'.',,'-',,':',,,0,HR24,,','
;
label pr936_info word
		ctable$24 CTABLE 
		cinfo$24 CINFO CID_PR,936,DATE_YMD,'\',,,,,',',,'.',,'-',,':',,,2,HR24,,','
;
label ta938_info word
		ctable$25 CTABLE 
		cinfo$25 CINFO CID_TA,938,DATE_MDY,'N','T','$',,,',',,'.',,'-',,':',,,2,HR24,,','
;
	page
; ------------------------------------------------
;
;	World Trade Collating sequence tables
;
; ------------------------------------------------
;
; --------------------------------------------------------------------------
;
;	Collating Table Same for United States, United Kingdom, France, Germany,
;			Italy, and International English
; --------------------------------------------------------------------------
;
label us_collate word
;
label uk_collate word
;
label fr_collate word
;
label gr_collate word
;
label it_collate word
;
label jp437_collate word
;
label ko437_collate word
;
label pr437_collate word
;
label ta437_collate word
;
label afe_collate word
		ctable$26 CTABLE ,'COLLATE',256
		db	0,1,2,3,4,5,6,7
		db	8,9,10,11,12,13,14,15
		db	16,17,18,19,20,21,22,23
		db	24,25,26,27,28,29,30,31
		db	" ","!",'"',"#","$","%","&","'"
		db	"(",")","*","+",",","-",".","/"
		db	"0","1","2","3","4","5","6","7"
		db	"8","9",":",";","<","=",">","?"
		db	"@","A","B","C","D","E","F","G"
		db	"H","I","J","K","L","M","N","O"
		db	"P","Q","R","S","T","U","V","W"
		db	"X","Y","Z","[","\","]","^","_"
		db	"`","A","B","C","D","E","F","G"
		db	"H","I","J","K","L","M","N","O"
		db	"P","Q","R","S","T","U","V","W"
		db	"X","Y","Z","{","|","}","~",127
		db	"C","U","E","A","A","A","A","C"
		db	"E","E","E","I","I","I","A","A"
		db	"E","A","A","O","O","O","U","U"
		db	"Y","O","U","$","$","$","$","$"
		db	"A","I","O","U","N","N",166,167
		db	"?",169,170,171,172,"!",'"','"'
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,"S"
		db	226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
	;
; Netherland 437 Collate
;
label nl_collate word
		ctable$27 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	128,154,144,065,142,065,143,128
		db	069,069,069,073,073,073,142,143
		db	144,146,146,079,079,079,085,085
		db	152,079,085,155,156,157,158,159
		db	065,073,079,085,165,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
;la_collate	 label	 word
;		 ctable  <,'COLLATE',256>
;		 db	 000,001,002,003,004,005,006,007
;		 db	 008,009,010,011,012,013,014,015
;		 db	 016,017,018,019,020,021,022,023
;		 db	 024,025,026,027,028,029,030,031
;		 db	 032,033,034,035,036,037,038,039
;		 db	 040,041,042,043,044,045,046,047
;		 db	 048,049,050,051,052,053,054,055
;		 db	 056,057,058,059,060,061,062,063
;		 db	 064,065,066,067,068,069,070,071
;		 db	 072,073,074,075,076,077,078,079
;		 db	 080,081,082,083,084,085,086,087
;		 db	 088,089,090,091,092,093,094,095
;		 db	 096,065,066,067,068,069,070,071
;		 db	 072,073,074,075,076,077,078,079
;		 db	 080,081,082,083,084,085,086,087
;		 db	 088,089,090,123,124,125,126,127
;		 db	 128,"U","E","A","A","A","A",128
;		 db	 "E","E","E","I","I","I","A","A"
;		 db	 "E","A","A","O","O","O","U","U"
;		 db	 "Y","O","U","$","$","$","$","$"
;		 db	 "A","I","O","U",165,165,166,167
;		 db	 "?",169,170,171,172,"!",'"','"'
;		 db	 176,177,178,179,180,181,182,183
;		 db	 184,185,186,187,188,189,190,191
;		 db	 192,193,194,195,196,197,198,199
;		 db	 200,201,202,203,204,205,206,207
;		 db	 208,209,210,211,212,213,214,215
;		 db	 216,217,218,219,220,221,222,223
;		 db	 224,"S"
;		 db	 226,227,228,229,230,231
;		 db	 232,233,234,235,236,237,238,239
;		 db	 240,241,242,243,244,245,246,247
;		 db	 248,249,250,251,252,253,254,255
	page
label la_collate word     ; new for DOS 4.0, wants same as spain
;
label sp_collate word      ; new for DOS 4.0
		ctable$28 CTABLE ,'COLLATE',256
		db 000,150,151,152,153,154,155,156 ;7
		db 157,158,159,160,161,162,163,164 ;15
		db 165,166,167,168,169,170,171,172 ;23
		db 173,174,175,176,177,178,179,180 ;31
		db 000,060,061,062,063,064,065,000 ;39
		db 066,067,068,069,070,000,071,072 ;47
		db 034,035,036,037,038,039,040,041 ;55
		db 042,043,073,074,075,076,077,078 ;63
		db 079,001,002,003,006,008,009,010 ;71
		db 011,012,013,014,015,017,018,020 ;79
		db 021,022,023,024,026,028,029,030 ;87
		db 031,032,033,080,081,082,083,084 ;95
		db 085,001,002,003,006,008,009,010 ;103
		db 011,012,013,014,015,017,018,020 ;111
		db 021,022,023,024,026,028,029,030 ;119
		db 031,032,033,086,087,088,089,090 ;127
		db 004,028,008,001,001,001,001,004 ;135
		db 008,008,008,012,012,012,001,001 ;143
		db 008,001,001,020,020,020,028,028 ;151
		db 032,020,028,091,092,093,094,095 ;159
		db 001,012,020,028,019,019,001,020 ;167
		db 096,097,098,099,100,101,102,103 ;175
		db 104,105,106,107,108,181,182,183 ;183
		db 184,109,110,111,112,185,186,113 ;191
		db 114,115,116,117,118,119,187,188 ;199
		db 120,121,122,123,124,125,126,189 ;207
		db 190,191,192,193,194,195,196,197 ;215
		db 198,127,128,129,130,199,200,131 ;223
		db 201,025,202,203,204,205,132,206 ;231
		db 207,208,209,210,211,212,213,214 ;239
		db 215,133,216,217,218,219,134,220 ;247
		db 221,222,000,223,224,135,136,225 ;255
	page
;
label dk_collate word  ; Denmark (dk) 865
		ctable$29 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,040,047,041,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,040,047,041,126,127
		db	067,089,069,065,091,065,093,067
		db	069,069,069,073,073,073,091,093
		db	069,091,091,079,092,079,085,085
		db	089,092,089,092,036,092,036,036
		db	065,073,079,085,078,078,065,079
		db	063,169,170,171,172,033,034,036
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,083,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
label no_collate word  ; Norway (no) 865
		ctable$30 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,089,069,065,091,065,093,067
		db	069,069,069,073,073,073,091,093
		db	069,091,091,079,092,079,085,085
		db	089,092,089,092,036,092,036,036
		db	065,073,079,085,078,078,065,079
		db	063,169,170,171,172,033,034,036
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,083,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
; Finland 437 Collate (same as Sweden)
;
label fi_collate word
;
label sv_collate word
		ctable$31 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,089,069,065,092,065,091,067
		db	069,069,069,073,073,073,092,091
		db	069,092,092,079,093,079,085,085
		db	089,093,089,036,036,036,036,036
		db	065,073,079,085,078,078,166,167
		db	063,169,170,171,172,033,034,034
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,083,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
;  Israel 862 collate
;
label is_collate word
		ctable$32 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	128,129,130,131,132,133,134,135
		db	136,137,138,139,140,141,142,143
		db	144,145,146,147,148,149,150,151
		db	152,153,154,036,036,036,036,036
		db	065,073,079,085,078,078,166,167
		db	063,169,170,171,172,033,034,034
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,083,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
; Canada 863 Collate
;
label ca_collate word
		ctable$33 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,085,069,065,065,065,134,067
		db	069,069,069,073,073,141,065,143
		db	069,069,069,079,069,073,085,085
		db	152,079,085,155,156,085,085,159
		db	160,161,079,085,164,165,166,167
		db	073,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
; Portugal 860 collating
;
label po_collate word
		ctable$34 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,085,069,065,065,065,065,067
		db	069,069,069,073,079,073,065,065
		db	069,065,069,079,079,079,085,085
		db	073,079,085,036,036,085,036,079
		db	065,073,079,085,078,078,166,167
		db	063,079,170,171,172,033,034,034
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,083,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
label sw_collate word
		ctable$35 CTABLE ,'COLLATE',256
		db	001,200,201,202,203,204,205,206
		db	207,208,209,210,211,212,213,214
		db	215,216,217,218,140,141,219,220
		db	221,222,223,224,225,226,227,228
		db	001,060,061,062,063,064,065,066  ;DCR059 CNS ******  ;AN000;
		db	067,068,069,070,071,072,073,074
		db	032,033,034,035,036,037,038,039
		db	040,041,075,076,077,078,079,080
		db	081,002,003,004,005,007,008,009
		db	010,011,012,013,014,015,016,018
		db	019,020,021,022,024,026,027,028
		db	029,030,031,082,083,084,052,085
		db	051,002,003,004,005,007,008,009
		db	010,011,012,013,014,015,016,018
		db	019,020,021,022,024,026,027,028
		db	029,030,031,086,087,088,054,089
		db	004,026,007,002,002,002,002,004
		db	007,007,007,011,011,011,002,002
		db	007,002,002,018,018,018,026,026
		db	030,018,026,111,090,112,150,092
		db	002,011,018,026,017,017,002,018
		db	093,151,095,096,097,098,099,100
		db	101,102,103,104,105,152,153,154
		db	155,107,108,109,110,156,157,113
		db	114,115,116,117,118,119,158,159
		db	120,121,122,123,124,125,126,160
		db	161,162,163,164,165,166,167,168
		db	169,128,129,130,131,170,171,133
		db	172,023,173,174,175,176,134,177
		db	178,179,180,181,182,183,184,185
		db	186,137,187,188,189,190,142,191
		db	143,192,144,193,194,147,148,001
	page
;
label be_collate word
		ctable$36 CTABLE ,'COLLATE',256
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	255,033,034,035,036,037,038,255
		db	040,041,042,043,044,255,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,085,069,065,065,065,065,067
		db	069,069,069,073,073,073,065,065
		db	069,065,065,079,079,079,085,085
		db	089,079,085,155,156,157,158,159
		db	065,073,079,085,078,078,166,167
		db	168,169,170,171,172,173,174,175
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	224,083,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,255,255
	page
;
; Area South 864 Collate
;
label as_collate word
		ctable$37 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	128,129,130,131,132,133,134,135
		db	136,137,138,139,140,141,142,143
		db	144,145,146,147,148,149,150,151
		db	152,233,234,251,255,235,236,179
		db	153,154,182,155,156,184,253,254
		db	188,189,192,194,163,196,198,200
		db	164,165,166,167,168,169,170,171
		db	172,173,224,174,206,208,210,175
		db	157,180,181,183,185,217,186,187
		db	190,191,193,195,197,199,201,202
		db	203,204,205,207,209,211,213,214
		db	215,218,222,158,159,160,161,216
		db	178,225,227,229,237,239,241,243
		db	245,246,250,212,219,221,220,238
		db	177,176,240,242,244,247,249,223
		db	226,231,232,230,228,248,162,255


	page
;
; -----------------------------------------
;
;     Collating Tables for Code Page 850
;
; -----------------------------------------
;
label fr850_collate word
;
label ca850_collate word
;
label us850_collate word
;
label uk850_collate word
;
label it850_collate word
;
;;sp850_collate      label   word  ; spain now has there own
;
label is850_collate word
;
label po850_collate word
;
;;la850_collate      label   word   ; wants same as spain
;
label as850_collate word
;
label gr850_collate word        ;omitted tobe consistent with US DCR
;
label afe850_collate word
		ctable$38 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,085,069,065,065,065,065,067
		db	069,069,069,073,073,073,065,065
		db	069,065,065,079,079,079,085,085
		db	089,079,085,079,036,079,158,036
		db	065,073,079,085,078,078,166,167
		db	063,169,170,171,172,033,034,034
		db	176,177,178,179,180,065,065,065
		db	184,185,186,187,188,036,036,191
		db	192,193,194,195,196,197,065,065
		db	200,201,202,203,204,205,206,036
		db	068,068,069,069,069,073,073,073
		db	073,217,218,219,220,221,073,223
		db	079,083,079,079,079,079,230,232
		db	232,085,085,085,089,089,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page

;formerly GERMAN COLLATE TABLE DCR0037
;		ctable	<,'COLLATE',256>
;		db	000,001,002,003,004,005,006,007
;		db	008,009,010,011,012,013,014,015
;		db	016,017,018,019,020,021,022,023
;		db	024,025,026,027,028,029,030,031
;		db	032,033,034,035,036,037,038,039
;		db	040,041,042,043,044,045,046,047
;		db	048,049,050,051,052,053,054,055
;		db	056,057,058,059,060,061,062,063
;		db	064,065,066,067,068,069,070,071
;		db	072,073,074,075,076,077,078,079
;		db	080,081,082,083,084,085,086,087
;		db	088,089,090,091,092,093,094,095
;		db	096,065,066,067,068,069,070,071
;		db	072,073,074,075,076,077,078,079
;		db	080,081,082,083,084,085,086,087
;		db	088,089,090,123,124,125,126,127
;		db	067,117,069,065,097,065,065,067
;		db	069,069,069,073,073,073,065,065
;		db	069,065,065,079,111,079,085,085
;		db	089,079,085,079,036,079,158,036
;		db	065,073,079,085,078,078,166,167
;		db	063,169,170,171,172,033,034,034
;		db	176,177,178,179,180,065,065,065
;		db	184,185,186,187,188,036,036,191
;		db	192,193,194,195,196,197,065,065
;		db	200,201,202,203,204,205,206,036
;		db	068,068,069,069,069,073,073,073
;		db	073,217,218,219,220,221,073,223
;		db	079,115,079,079,079,079,230,232
;		db	232,085,085,085,089,089,238,239
;		db	240,241,242,243,244,245,246,247
;		db	248,249,250,251,252,253,254,255
	page
;
label nl850_collate word
		ctable$39 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,085,069,065,065,065,143,067
		db	069,069,069,073,073,073,065,143
		db	069,146,146,079,079,079,085,085
		db	152,079,085,079,156,079,158,159
		db	065,073,079,085,165,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,065,065,065
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,065,065
		db	200,201,202,203,204,205,206,207
		db	209,209,069,069,069,073,073,073
		db	073,217,218,219,220,221,073,223
		db	079,225,079,079,079,079,230,232
		db	232,085,085,085,089,089,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
label dk850_collate word
		ctable$40 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,040,047,041,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,040,047,041,126,127
		db	067,089,069,065,091,065,093,067
		db	069,069,069,073,073,073,091,093
		db	069,091,091,079,092,079,085,085
		db	089,092,089,092,036,092,158,036
		db	065,073,079,085,078,078,065,079
		db	063,169,170,171,172,033,034,034
		db	176,177,178,179,180,065,065,065
		db	184,185,186,187,188,036,036,191
		db	192,193,194,195,196,197,065,065
		db	200,201,202,203,204,205,206,036
		db	068,068,069,069,069,073,073,073
		db	073,217,218,219,220,221,073,223
		db	079,083,079,079,079,079,230,080
		db	080,085,085,085,089,089,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
label no850_collate word
		ctable$41 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,085,069,065,091,065,093,067
		db	069,069,069,073,073,073,091,093
		db	069,091,091,079,092,079,085,085
		db	089,092,089,092,036,092,158,036
		db	065,073,079,085,078,078,065,079
		db	063,169,170,171,172,033,034,034
		db	176,177,178,179,180,065,065,065
		db	184,185,186,187,188,036,036,191
		db	192,193,194,195,196,197,065,065
		db	200,201,202,203,204,205,206,036
		db	068,068,069,069,069,073,073,073
		db	073,217,218,219,220,221,073,223
		db	079,083,079,079,079,079,230,080
		db	080,085,085,085,089,089,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
label sv850_collate word
		ctable$42 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,089,069,065,092,065,091,067
		db	069,069,069,073,073,073,092,091
		db	069,092,092,079,093,079,085,085
		db	089,093,089,093,036,093,158,036
		db	065,073,079,085,078,078,166,167
		db	063,169,170,171,172,033,034,034
		db	176,177,178,179,180,065,065,065
		db	184,185,186,187,188,036,036,191
		db	192,193,194,195,196,197,065,065
		db	200,201,202,203,204,205,206,036
		db	068,068,069,069,069,073,073,073
		db	073,217,218,219,220,221,073,223
		db	079,083,079,079,093,093,230,232
		db	232,085,085,085,089,089,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
label fi850_collate word
		ctable$43 CTABLE ,'COLLATE',256
		db	000,001,002,003,004,005,006,007
		db	008,009,010,011,012,013,014,015
		db	016,017,018,019,020,021,022,023
		db	024,025,026,027,028,029,030,031
		db	032,033,034,035,036,037,038,039
		db	040,041,042,043,044,045,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,089,069,065,092,065,091,067
		db	069,069,069,073,073,073,092,091
		db	069,092,092,079,093,079,085,085
		db	089,093,089,093,036,093,158,036
		db	065,073,079,085,078,078,166,167
		db	063,169,170,171,172,033,034,034
		db	176,177,178,179,180,065,065,065
		db	184,185,186,187,188,036,036,191
		db	192,193,194,195,196,197,065,065
		db	200,201,202,203,204,205,206,036
		db	068,068,069,069,069,073,073,073
		db	073,217,218,219,220,221,073,223
		db	079,083,079,079,079,079,230,232
		db	232,085,085,085,089,089,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
label sw850_collate word
		ctable$44 CTABLE ,'COLLATE',256

		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
		db	000,165,168,133,185,134,135,169
		db	170,171,136,158,172,174,175,176
		db	117,118,120,122,124,125,126,127
		db	128,129,177,178,160,161,162,179
		db	137,002,018,020,024,028,038,040
		db	042,044,055,057,059,061,063,067
		db	081,083,085,087,090,094,104,106
		db	108,110,115,138,139,140,191,173
		db	190,003,019,021,025,029,039,041
		db	043,056,045,058,060,062,064,068
		db	082,084,086,088,091,095,105,107
		db	109,111,116,142,143,144,193,157
		db	022,103,031,009,011,007,015,023
		db	035,037,033,053,051,049,010,014
		db	030,017,016,074,076,072,101,099
		db	114,075,102,080,184,079,164,188
		db	005,047,070,097,066,065,149,148
		db	180,154,156,131,130,166,181,182
		db	207,208,209,206,204,004,008,006
		db	153,210,211,212,213,186,187,198
		db	197,202,201,203,205,200,013,012
		db	214,215,216,217,218,219,220,183
		db	027,026,034,036,032,054,046,050
		db	052,199,196,223,221,155,048,222
		db	069,089,073,071,078,077,146,092
		db	093,096,100,098,113,112,145,189
		db	167,159,141,132,151,150,163,194
		db	147,192,195,119,123,121,152,001

;		db	001,200,201,202,203,204,205,206
;		db	207,208,209,210,211,212,213,214
;		db	215,216,217,218,140,141,219,220
;		db	221,222,223,224,225,226,227,228
;		db	001,060,061,062,063,064,065,066
;		db	067,068,069,070,071,072,073,074
;		db	032,033,034,035,036,037,038,039
;		db	040,041,075,076,077,078,079,080
;		db	081,002,003,004,005,007,008,009
;		db	010,011,012,013,014,015,016,018
;		db	019,020,021,022,024,026,027,028
;		db	029,030,031,082,083,084,052,085
;		db	051,002,003,004,005,007,008,009
;		db	010,011,012,013,014,015,016,018
;		db	019,020,021,022,024,026,027,028
;		db	029,030,031,086,087,088,054,089
;		db	004,026,007,002,002,002,002,004
;		db	007,007,007,011,011,011,002,002
;		db	007,002,002,018,018,018,026,026
;		db	030,018,026,018,090,018,091,092
;		db	002,011,018,026,017,017,002,018
;		db	093,094,095,096,097,098,099,100
;		db	101,102,103,104,105,002,002,002
;		db	106,107,108,109,110,111,112,113
;		db	114,115,116,117,118,119,002,002
;		db	120,121,122,123,124,125,126,127
;		db	006,006,007,007,007,011,011,011
;		db	011,128,129,130,131,132,011,133
;		db	018,023,018,018,018,018,134,025
;		db	025,026,026,026,030,030,135,050
;		db	136,137,138,139,140,141,142,055
;		db	143,053,144,145,146,147,148,001
	page
;
label be850_collate word
		ctable$45 CTABLE ,'COLLATE',256
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	255,255,255,255,255,255,255,255
		db	255,033,034,035,036,037,038,255
		db	040,041,042,043,044,255,046,047
		db	048,049,050,051,052,053,054,055
		db	056,057,058,059,060,061,062,063
		db	064,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,091,092,093,094,095
		db	096,065,066,067,068,069,070,071
		db	072,073,074,075,076,077,078,079
		db	080,081,082,083,084,085,086,087
		db	088,089,090,123,124,125,126,127
		db	067,085,069,065,065,065,065,067
		db	069,069,069,073,073,073,065,065
		db	069,065,065,079,079,079,085,085
		db	089,079,085,079,156,079,158,159
		db	065,073,079,085,078,164,166,167
		db	168,169,170,171,172,173,174,175
		db	255,255,255,255,255,065,065,065
		db	184,255,255,255,255,189,190,255
		db	255,255,255,255,255,255,065,065
		db	255,255,255,255,255,255,255,207
		db	068,068,069,069,069,073,073,073
		db	073,255,255,255,255,221,073,255
		db	079,083,079,079,079,079,230,084
		db	084,085,085,085,089,089,238,239
		db	255,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,255,255
	page

label la850_collate word           ; wants same as spain
;
label sp850_collate word           ; new for DOS 4.0
		ctable$46 CTABLE ,'COLLATE',256
		db 000,150,151,152,153,154,155,156 ;7
		db 157,158,159,160,161,162,163,164 ;15
		db 165,166,167,168,169,170,171,172 ;23
		db 173,174,175,176,177,178,179,180 ;31
		db 000,060,061,062,063,064,065,000 ;39
		db 066,067,068,069,070,000,071,072 ;47
		db 034,035,036,037,038,039,040,041 ;55
		db 042,043,073,074,075,076,077,078 ;63
		db 079,001,002,003,006,008,009,010 ;71
		db 011,012,013,014,015,017,018,020 ;79
		db 021,022,023,024,026,028,029,030 ;87
		db 031,032,033,080,081,082,083,084 ;95
		db 085,001,002,003,006,008,009,010 ;103
		db 011,012,013,014,015,017,018,020 ;111
		db 021,022,023,024,026,028,029,030 ;119
		db 031,032,033,086,087,088,089,090 ;127
		db 004,028,008,001,001,001,001,004 ;135
		db 008,008,008,012,012,012,001,001 ;143
		db 008,001,001,020,020,020,028,028 ;151
		db 032,020,028,020,092,020,094,095 ;159
		db 001,012,020,028,019,019,001,020 ;167
		db 096,097,098,099,100,101,102,103 ;175
		db 104,105,106,107,108,001,001,001 ;183
		db 184,109,110,001,001,091,093,113 ;191
		db 114,115,116,117,118,119,187,188 ;199
		db 120,121,122,123,124,125,126,189 ;207
		db 007,007,008,008,008,012,012,012 ;215
		db 012,127,128,129,130,199,012,131 ;223
		db 020,025,020,020,020,020,132,027 ;231
		db 027,028,028,028,032,032,213,214 ;239
		db 000,133,216,217,218,219,134,220 ;247
		db 221,222,000,223,224,135,136,225 ;255

	page
;
label jp932_collate word
		ctable$47 CTABLE ,'COLLATE',256
		db	0,1,2,3,4,5,6,7
		db	8,9,10,11,12,13,14,15
		db	16,17,18,19,20,21,22,23
		db	24,25,26,27,28,29,30,31
		db	" ","!",'"',"#","$","%","&","'"
		db	"(",")","*","+",",","-",".","/"
		db	"0","1","2","3","4","5","6","7"
		db	"8","9",":",";","<","=",">","?"
		db	"@","A","B","C","D","E","F","G"
		db	"H","I","J","K","L","M","N","O"
		db	"P","Q","R","S","T","U","V","W"
		db	"X","Y","Z","[","\","]","^","_"
		db	"`","A","B","C","D","E","F","G"
		db	"H","I","J","K","L","M","N","O"
		db	"P","Q","R","S","T","U","V","W"
		db	"X","Y","Z","{","|","}","~",127
		db	128,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	129,130,131,132,133,189,134,135
		db	136,137,138,139,140,141,142,143
		db	144,145,146,147,148,149,150,151
		db	152,153,154,155,156,157,158,159
		db	160,161,162,163,164,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,190,191,192
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
;
label ko934_collate word
		ctable$48 CTABLE ,'COLLATE',256
		db	0,1,2,3,4,5,6,7
		db	8,9,10,11,12,13,14,15
		db	16,17,18,19,20,21,22,23
		db	24,25,26,27,28,29,30,31
		db	" ","!",'"',"#","$","%","&","'"
		db	"(",")","*","+",",","-",".","/"
		db	"0","1","2","3","4","5","6","7"
		db	"8","9",":",";","<","=",">","?"
		db	"@","A","B","C","D","E","F","G"
		db	"H","I","J","K","L","M","N","O"
		db	"P","Q","R","S","T","U","V","W"
		db	"X","Y","Z","[","\","]","^","_"
		db	"`","A","B","C","D","E","F","G"
		db	"H","I","J","K","L","M","N","O"
		db	"P","Q","R","S","T","U","V","W"
		db	"X","Y","Z","{","|","}","~",127
		db	128,190,191,192,193,194,195,196
		db	197,198,199,200,201,202,203,204
		db	205,206,207,208,209,210,211,212
		db	213,214,215,216,217,218,219,220
		db	221,222,223,224,225,226,227,228
		db	229,230,231,232,233,234,235,236
		db	237,238,239,240,241,242,243,244
		db	245,246,247,248,249,250,251,252
		db	129,130,131,132,133,134,135,136
		db	137,138,139,140,141,142,143,144
		db	145,146,147,148,149,150,151,152
		db	153,154,155,156,157,158,159,160
		db	161,162,163,164,165,166,167,168
		db	169,170,171,172,173,174,175,176
		db	177,178,179,180,181,182,183,184
		db	185,186,187,188,189,253,254,255

	page
;
label pr936_collate word
;
label ta938_collate word
		ctable$49 CTABLE ,'COLLATE',256
		db	0,1,2,3,4,5,6,7
		db	8,9,10,11,12,13,14,15
		db	16,17,18,19,20,21,22,23
		db	24,25,26,27,28,29,30,31
		db	" ","!",'"',"#","$","%","&","'"
		db	"(",")","*","+",",","-",".","/"
		db	"0","1","2","3","4","5","6","7"
		db	"8","9",":",";","<","=",">","?"
		db	"@","A","B","C","D","E","F","G"
		db	"H","I","J","K","L","M","N","O"
		db	"P","Q","R","S","T","U","V","W"
		db	"X","Y","Z","[","\","]","^","_"
		db	"`","A","B","C","D","E","F","G"
		db	"H","I","J","K","L","M","N","O"
		db	"P","Q","R","S","T","U","V","W"
		db	"X","Y","Z","{","|","}","~",127
		db	128,129,130,131,132,133,134,135
		db	136,137,138,139,140,141,142,143
		db	144,145,146,147,148,149,150,151
		db	152,153,154,155,156,157,158,159
		db	160,161,162,163,164,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255

	page
;
; ---------------------------------------------------------------
;
;	World Trade Case Mappings
;
; ---------------------------------------------------------------
;
label us_ucase word
;
label uk_ucase word
;
label fr_ucase word
;
label gr_ucase word
;
label sp_ucase word
;
label la_ucase word
;
label it_ucase word
;
label afe_ucase word
;
label as_ucase word
;
label jp437_ucase word
;
label ko437_ucase word
;
label pr437_ucase word
;
label ta437_ucase word
		ctable$50 CTABLE ,'UCASE  ',128
;***CNS PTM2390 table omitted	;AN000;
;***CNS restored for PTM 2575 to establish consistent and maintain 3.3 &
;under compatibility
	       db      128,154,069,065,142,065,143,128
	       db      069,069,069,073,073,073,142,143
	       db      144,146,146,079,153,079,085,085
	       db      089,153,154,155,156,157,158,159
	       db      065,073,079,085,165,165,166,167
	       db      168,169,170,171,172,173,174,175
	       db      176,177,178,179,180,181,182,183
	       db      184,185,186,187,188,189,190,191
	       db      192,193,194,195,196,197,198,199
	       db      200,201,202,203,204,205,206,207
	       db      208,209,210,211,212,213,214,215
	       db      216,217,218,219,220,221,222,223
	       db      224,225,226,227,228,229,230,231
	       db      232,233,234,235,236,237,238,239
	       db      240,241,242,243,244,245,246,247
	       db      248,249,250,251,252,253,254,255
;***CNS PTM2390 table omitted
;**CNS	replacement
;		 db	 067,085,069,065,065,065,065,067  ;AD000;
;		 db	 069,069,069,073,073,073,065,065  ;AD000;
;		 db	 069,146,146,079,079,079,085,085  ;AD000;
;		 db	 089,079,085,079,156,079,158,159  ;AD000;
;		 db	 065,073,079,085,165,165,166,167  ;AD000;
;		 db	 168,169,170,171,172,173,174,175  ;AD000;
;		 db	 176,177,178,179,180,065,065,065  ;AD000;
;		 db	 184,185,186,187,188,189,190,191  ;AD000;
;		 db	 192,193,194,195,196,197,065,065  ;AD000;
;		 db	 200,201,202,203,204,205,206,207  ;AD000;
;		 db	 209,209,069,069,069,073,073,073  ;AD000;
;		 db	 073,217,218,219,220,221,073,223  ;AD000;
;		 db	 079,225,079,079,079,079,230,232  ;AD000;
;		 db	 232,085,085,085,089,089,238,239  ;AD000;
;		 db	 240,241,242,243,244,245,246,247  ;AD000;
;		 db	 248,249,250,251,252,253,254,255  ;AD000;
;
page
;	Canadian French Code Page 863
;
label ca_ucase word
		ctable$51 CTABLE ,'UCASE  ',128
		db	067,085,069,065,065,065,134,067
		db	069,069,069,073,073,141,065,143
		db	069,069,069,079,069,073,085,085
		db	152,079,085,155,156,085,085,159
		db	160,161,079,085,164,165,166,167
		db	073,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
;	Denmark (Da) case mapping for 865
;
label dk_ucase word
;
;	Norway (No) case mapping for 865
;
label no_ucase word
		ctable$52 CTABLE ,'UCASE  ',128
		db	128,154,144,065,142,065,143,128
		db	069,069,069,073,073,073,142,143
		db	144,146,146,079,153,079,085,085
		db	089,153,154,157,156,157,158,159
		db	065,073,079,085,165,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
;	Belgium (Be) case mapping for 437
;
label be_ucase word
;
;	Finland (Fi) case mapping for 437
;
label fi_ucase word
;
;	Sweden (Sv) case mapping
;
label sv_ucase word
		ctable$53 CTABLE ,'UCASE  ',128
		db	128,154,144,065,142,065,143,128
		db	069,069,069,073,073,073,142,143
		db	144,146,146,079,153,079,085,085
		db	089,153,154,155,156,157,158,159
		db	065,073,079,085,165,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
;	Switzerland case mapping for 437
;
label sw_ucase word
		ctable$54 CTABLE ,'UCASE  ',128
		db	128,154,144,065,142,065,143,128
		db	069,069,069,073,073,073,142,143
		db	144,146,146,079,153,079,085,085
		db	089,153,154,155,156,157,158,159
		db	065,073,079,085,165,165,166,167    ;AN000;;DCR 059 CNS ***
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
;
;	Netherlands case mapping for 437
;
label nl_ucase word
		ctable$55 CTABLE ,'UCASE  ',128
		db	128,085,069,065,065,065,143,128
		db	069,069,069,073,073,073,065,143
		db	069,146,146,079,079,079,085,085
		db	152,079,085,155,156,157,158,159
		db	065,073,079,085,165,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
;
;	Portuguese (Po) case mapping
;
label po_ucase word
		ctable$56 CTABLE ,'UCASE  ',128
		db	128,154,144,143,142,145,134,128
		db	137,137,146,139,140,152,142,143
		db	144,145,146,140,153,169,150,157
		db	152,153,154,155,156,157,158,159
		db	134,139,159,150,165,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
;
;	Is case mapping
;
label is_ucase word
		ctable$57 CTABLE ,'UCASE  ',128
		db	128,129,130,131,132,133,134,135
		db	136,137,138,139,140,141,142,143
		db	144,145,146,147,148,149,150,151
		db	152,153,154,155,156,157,158,159
		db	065,073,079,085,165,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
;
label us850_ucase word
;
label afe850_ucase word
;
label uk850_ucase word
;
label fr850_ucase word
;
label it850_ucase word
;
label is850_ucase word
;
label as850_ucase word
;
label po850_ucase word
;
label ca850_ucase word
		ctable$58 CTABLE ,'UCASE  ',128
;**CNS replacement
	       db      067,085,069,065,065,065,065,067
	       db      069,069,069,073,073,073,065,065
	       db      069,146,146,079,079,079,085,085
	       db      089,079,085,079,156,079,158,159
	       db      065,073,079,085,165,165,166,167
	       db      168,169,170,171,172,173,174,175
	       db      176,177,178,179,180,065,065,065
	       db      184,185,186,187,188,189,190,191
	       db      192,193,194,195,196,197,065,065
	       db      200,201,202,203,204,205,206,207
	       db      209,209,069,069,069,073,073,073
	       db      073,217,218,219,220,221,073,223
	       db      079,225,079,079,079,079,230,232
	       db      232,085,085,085,089,089,238,239
	       db      240,241,242,243,244,245,246,247
	       db      248,249,250,251,252,253,254,255
;
;***CNS PTM2390 table omitted
;		 db	 128,154,069,065,142,065,143,128    ;AN000;
;		 db	 069,069,069,073,073,073,142,143    ;AN000;
;		 db	 144,146,146,079,153,079,085,085    ;AN000;
;		 db	 089,153,154,155,156,157,158,159    ;AN000;
;		 db	 065,073,079,085,165,165,166,167    ;AN000;
;		 db	 168,169,170,171,172,173,174,175    ;AN000;
;		 db	 176,177,178,179,180,181,182,183    ;AN000;
;		 db	 184,185,186,187,188,189,190,191    ;AN000;
;		 db	 192,193,194,195,196,197,198,199    ;AN000;
;		 db	 200,201,202,203,204,205,206,207    ;AN000;
;		 db	 208,209,210,211,212,213,214,215    ;AN000;
;		 db	 216,217,218,219,220,221,222,223    ;AN000;
;		 db	 224,225,226,227,228,229,230,231    ;AN000;
;		 db	 232,233,234,235,236,237,238,239    ;AN000;
;		 db	 240,241,242,243,244,245,246,247    ;AN000;
;		 db	 248,249,250,251,252,253,254,255    ;AN000;
;***CNS PTM2390 table omitted
;
;;la850_ucase	  label   word	- LA wants same as spain
;
;; sp850_ucase	   label   word - changed for 4.0
;		ctable	<,'UCASE  ',128>
;		db	128,085,069,065,065,065,065,128
;		db	069,069,069,073,073,073,065,065
;		db	069,146,146,079,079,079,085,085
;		db	089,079,085,079,156,079,158,159
;		db	065,073,079,085,165,165,166,167
;		db	168,169,170,171,172,173,174,175
;		db	176,177,178,179,180,065,065,065
;		db	184,185,186,187,188,189,190,191
;		db	192,193,194,195,196,197,065,065
;		db	200,201,202,203,204,205,206,207
;		db	209,209,069,069,069,073,073,073
;		db	073,217,218,219,220,221,073,223
;		db	079,225,079,079,079,079,230,232
;		db	232,085,085,085,089,089,238,239
;		db	240,241,242,243,244,245,246,247
;		db	248,249,250,251,252,253,254,255
;
label gr850_ucase word
		ctable$59 CTABLE ,'UCASE  ',128
		db	067,154,069,065,142,065,065,067
		db	069,069,069,073,073,073,142,065
		db	069,146,146,079,153,079,085,085
		db	089,153,154,079,156,079,158,159
		db	065,073,079,085,165,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,065,065,065
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,065,065
		db	200,201,202,203,204,205,206,207
		db	209,209,069,069,069,073,073,073
		db	073,217,218,219,220,221,073,223
		db	079,225,079,079,079,079,230,232
		db	232,085,085,085,089,089,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
;
;	LA case mapping for 850, new for DOS 4.0 to be same as Spain
;
label la850_ucase word
;
;	Spain (sp) case mapping for 850, new for DOS 4.0
;
label sp850_ucase word
;
;	Belgium (Be) case mapping for 850
;
label be850_ucase word
;
;	Finland (Fi) case mapping for 850
;
label fi850_ucase word
;
;	Sweden (Sv) case mapping for 850
;
label sv850_ucase word
;
;	Denmark (Da) case mapping for 850
;
label dk850_ucase word
;
;	Norway (No) case mapping for 850
;
label no850_ucase word
		ctable$60 CTABLE ,'UCASE  ',128
		db	128,154,144,182,142,183,143,128
		db	210,211,212,216,215,222,142,143
		db	144,146,146,226,153,227,234,235
		db	089,153,154,157,156,157,158,159
		db	181,214,224,233,165,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,199,199
		db	200,201,202,203,204,205,206,207
		db	209,209,210,211,212,073,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,229,229,230,232
		db	232,233,234,235,237,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
;	Switzerland (Sw) Case mapping (850)
;
label sw850_ucase word
		ctable$61 CTABLE ,'UCASE  ',128
		db	128,154,144,182,142,183,143,128
		db	210,211,212,216,215,222,142,143
		db	144,146,146,226,153,227,234,235
		db	089,153,154,157,156,157,158,159
		db	181,214,224,233,165,165,166,167 ;DCR059 CNS ** ;AN000;
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,199,199
		db	200,201,202,203,204,205,206,207
		db	209,209,210,211,212,073,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,229,229,230,232
		db	232,233,234,235,237,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
;
;	Netherlands (Nl) case mapping 850
;
label nl850_ucase word
		ctable$62 CTABLE ,'UCASE  ',128
		db	128,085,069,065,065,065,143,128
		db	069,069,069,073,073,073,065,143
		db	069,146,146,079,079,079,085,085
		db	152,079,085,079,156,079,158,159
		db	065,073,079,085,165,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,065,065,065
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,065,065
		db	200,201,202,203,204,205,206,207
		db	209,209,069,069,069,073,073,073
		db	073,217,218,219,220,221,073,223
		db	079,225,079,079,079,079,230,232
		db	232,085,085,085,089,089,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
;
;	Japan case mapping 932
;
label jp932_ucase word
;
label ko934_ucase word
;
label pr936_ucase word
;
label ta938_ucase word
		ctable$63 CTABLE ,'UCASE  ',128
		db	128,129,130,131,132,133,134,135
		db	136,137,138,139,140,141,142,143
		db	144,145,146,147,148,149,150,151
		db	152,153,154,155,156,157,158,159
		db	160,161,162,163,164,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
page
; ----------------------------------------------------------------------------
;
;	World Trade Mono Case Filename Character Tables
;
;		Currently all countries have same (4/14/86)
;
;
; ----------------------------------------------------------------------------
label uk_ucfile word
label fr_ucfile word
label gr_ucfile word
label sp_ucfile word
label it_ucfile word
label sv_ucfile word
label dk_ucfile word
label sw_ucfile word
label no_ucfile word
label nl_ucfile word
label be_ucfile word
label fi_ucfile word
label is_ucfile word
label ca_ucfile word
label as_ucfile word
label po_ucfile word
label us_ucfile word
label la_ucfile word
label afe_ucfile word
		ctable$64 CTABLE ,'FUCASE ',128
		db	128,129,130,131,132,133,134,135
		db	136,137,138,139,140,141,142,143
		db	144,145,146,147,148,149,150,151
		db	152,153,154,155,156,157,158,159
		db	160,161,162,163,164,165,166,167
		db	168,169,170,171,172,173,174,175
		db	176,177,178,179,180,181,182,183
		db	184,185,186,187,188,189,190,191
		db	192,193,194,195,196,197,198,199
		db	200,201,202,203,204,205,206,207
		db	208,209,210,211,212,213,214,215
		db	216,217,218,219,220,221,222,223
		db	224,225,226,227,228,229,230,231
		db	232,233,234,235,236,237,238,239
		db	240,241,242,243,244,245,246,247
		db	248,249,250,251,252,253,254,255
	page
; ----------------------------------------------------------------------------
;
;	World Trade Valid Filename Character Tables
;
;		Currently all countries have same (4/14/86)
;
;
; ----------------------------------------------------------------------------
label uk_flist word
label fr_flist word
label gr_flist word
label sp_flist word
label it_flist word
label sv_flist word
label dk_flist word
label sw_flist word
label no_flist word
label nl_flist word
label be_flist word
label fi_flist word
label is_flist word
label ca_flist word
label as_flist word
label po_flist word
label us_flist word
label la_flist word
label afe_flist word
label jp437_flist word
label jp932_flist word
label ko437_flist word
label ko934_flist word
label pr437_flist word
label pr936_flist word
label ta437_flist word
label ta938_flist word
		ctable$65 CTABLE ,'FCHAR  ',fclend-fclbegin
label fclbegin word
		db	1,0,255 			; include all
		db	0,0,20h 			; exclude 0 - 20h
		db	2,14,'."/\[]:|<>+=;,'           ; exclude 14 special chars
label fclend word
	page
; ----------------------------------------------------------------------------
;
;	World Trade DBCS Tables
;
;	    Currently all countries have same (4/14/86)
;
;
; ----------------------------------------------------------------------------
;					;***CNS
label uk_dbcs word   ;AN000;
label fr_dbcs word   ;AN000;
label gr_dbcs word   ;AN000;
label sp_dbcs word   ;AN000;
label it_dbcs word   ;AN000;
label sv_dbcs word   ;AN000;
label dk_dbcs word   ;AN000;
label sw_dbcs word   ;AN000;
label no_dbcs word   ;AN000;
label nl_dbcs word   ;AN000;
label be_dbcs word   ;AN000;
label fi_dbcs word   ;AN000;
label is_dbcs word   ;AN000;
label ca_dbcs word   ;AN000;
label as_dbcs word   ;AN000;
label po_dbcs word   ;AN000;
label us_dbcs word   ;AN000;
label la_dbcs word   ;AN000;
label afe_dbcs word  ;AN000;
label jp437_dbcs word  ;AN000;
label ko437_dbcs word  ;AN000;
label pr437_dbcs word  ;AN000;
label ta437_dbcs word  ;AN000;
		ctable$66 CTABLE ,'DBCS   ',dbcsterm-dbcsbegin ;AN000;
label dbcsbegin word     ;AN000;
dbcsterm	db	0,0					;AN000;
label dbcsend word      ;AN000;
;
;    Japan DBCS lead byte table
;
label jp932_dbcs word     ;AN000;
		ctable$67 CTABLE ,'DBCS   ',db932end-db932bgn  ;AN000;
label db932bgn word     ;AN000;
		db	081h,09Fh				;AN000;
		db	0E0h,0FCh				;AN000;
db932term	db	000h,000h				;AN000;
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
db932end	=	$					;AN000;
;
;    Korea DBCS lead byte table
;
label ko934_dbcs word     ;AN000;
		ctable$68 CTABLE ,'DBCS   ',db934end-db934bgn  ;AN000;
label db934bgn word     ;AN000;
		db	081h,0BFh				;AN000;
db934term	db	000h,000h				;AN000;
db934end	=	$					;AN000;
;
;    PRC and Taiwan DBCS lead byte table
;
label pr936_dbcs word     ;AN000;
label ta938_dbcs word     ;AN000;
		ctable$69 CTABLE ,'DBCS   ',db936end-db936bgn  ;AN000;
label db936bgn word     ;AN000;
		db	081h,0FCh				;AN000;
db936term	db	000h,000h				;AN000;
db936end	=	$					;AN000;

page
; ---------------------------------------------------------------
;
;		END OF CDI SEGMENT
;
; ---------------------------------------------------------------


include 'COPYRIGH.INC'

label cdiend word
;
cdifname =	$
	db	'COUNTRY.SYS',0
;
crmsg	=	$
	db	'Create failed',13,10
crmlen	=	($-crmsg)
;
succmsg =	$
	db	'COUNTRY.SYS created',13,10
smlen	=	($-succmsg)
;
iomsg	=	$
	db	'I/O error writing COUNTRY.SYS',13,10
iomlen	=	($-iomsg)
end if
;
if SEGSEL = S_SSEG
	db	128 dup(0)
end if
;	end	mkcdif
