

	PAGE	,132
	TITLE	DOS - Keyboard Definition File

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - - NLS Support - Keyboard Definition File
;; (c) Copyright 1988 Microsoft
;;
;; This the file header and table pointers ONLY.
;; The actual tables are contained in seperate source files.
;; These are:
;;	     KDFSP.ASM	- Spanish
;;	     KDFPO.ASM	- Portuguese
;;	     KDFGR.ASM	- German
;;	     KDFIT142.ASM  - Italian
;;	     KDFIT.ASM	- Italian
;;	     KDFFR189.ASM  - French
;;	     KDFFR.ASM	- French
;;	     KDFSG.ASM	- Swiss German
;;	     KDFSF.ASM	- Swiss French
;;	     KDFDK.ASM	- Danish
;;	     KDFUK168.ASM  - English
;;	     KDFUK.ASM	- English
;;	     KDFBE.ASM	- Belgium
;;	     KDFNL.ASM	- Netherlands
;;	     KDFNO.ASM	- Norway
;;	     KDFLA.ASM	- Latin American
;;	     KDFSV.ASM	- SWEDEN   -----> This moddule is used for both Sweden
;;					  and Finland - exact same template
;;	     KDFSU.ASM	- Finland  -----> Same module as Sweden eliminated
;;	     Dummy US	- US
;; Linkage Instructions:
;;	The following instructions are contained in KDFLINK.BAT:
;;
;;	LINK KDF+KDFSP+KDFGE+KDFFR+KDFIT+KDFPO+KDFUK+KDFSG+KDFDK+KDFEOF;
;;	EXE2BIN KDF.EXE KEYBOARD.SYS
;;
;; DCL, March 8, 1988 - swapped 437/850 to 850/437 for SG & SF
;; DCL, March 8, 1988 - uncommented SU(finland)& swapped 437/850 to 850/437
;;			   as the Finnish want 850/437 vs. 437/850 for Sweden
;;			   did not alter the pointer to kbid 153 to Sweden
;; CNS	   April 14 1988 - swapped 437/850 to 850/437 for SP & LA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
;CODE	SEGMENT PUBLIC 'CODE'          ;;
;	ASSUME CS:CODE,DS:CODE	       ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; File Header
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				     ;;
DB   0FFh,'KEYB   '                  ;; signature
DB   8 DUP(0)			     ;; reserved
DW   650			     ;; maximum size of Common Xlat Sect
DW   350			     ;; max size of Specific Xlat Sect
DW   400			     ;; max size of State Logic
DW   0				     ;;AC000;reserved
DW   19 			     ;;AC000 number of IDs
DW   17 			     ;;AC000 number of languages
DB   'GR'                            ;; LANGUAGE CODE TABLE
DW   GE_LANG_ENT_kdfnow,0             ;;
DB   'SP'                            ;;
DW   SP_LANG_ENT_kdfnow,0             ;;
DB   'PO'                            ;;
DW   PO_LANG_ENT_kdfnow,0             ;;
DB   'FR'                            ;;
DW   FR2_LANG_ENT_kdfnow,0             ;;
DB   'DK'                            ;;
DW   DK_LANG_ENT_kdfnow,0             ;;
DB   'SG'                            ;;
DW   SG_LANG_ENT_kdfnow,0             ;;
DB   'IT'                            ;;
DW   IT2_LANG_ENT_kdfnow,0             ;;
DB   'UK'                            ;;
DW   UK2_LANG_ENT_kdfnow,0             ;;
DB   'SF'                            ;;
DW   SF_LANG_ENT_kdfnow,0             ;;
DB   'BE'                            ;;
DW   BE_LANG_ENT_kdfnow,0             ;;
DB   'NL'                            ;;
DW   NL_LANG_ENT_kdfnow,0             ;;
DB   'NO'                            ;;
DW   NO_LANG_ENT_kdfnow,0             ;;
DB   'CF'                            ;;
DW   CF_LANG_ENT_kdfnow,0             ;;
DB   'SV'                            ;;
DW   SV_LANG_ENT_kdfnow,0             ;;
DB   'SU'                            ;;
DW   SU_LANG_ENT_kdfnow,0             ;;
DB   'LA'                            ;;
DW   LA_LANG_ENT_kdfnow,0             ;;
DB   'US'                            ;;
DW   DUMMY_ENT_kdfnow,0              ;;
DW    172			     ;;AN000;ID CODE TABLE ***************************
DW   SP_LANG_ENT_kdfnow,0             ;;AN000;
DW    163			     ;;AN000;
DW   PO_LANG_ENT_kdfnow,0             ;;AN000;
DW    120			     ;;AN000;
DW   FR1_LANG_ENT_kdfnow,0             ;;AN000;
DW    189			     ;;AN000;
DW   FR2_LANG_ENT_kdfnow,0             ;;AN000;
DW    159			     ;;AN000;
DW   DK_LANG_ENT_kdfnow,0             ;;AN000;
DW    000			     ;;AN000;
DW   SG_LANG_ENT_kdfnow,0             ;;AN000;
DW    129			     ;;AN000;
DW   GE_LANG_ENT_kdfnow,0             ;;AN000;
DW    142			     ;;AN000;
DW   IT1_LANG_ENT_kdfnow,0             ;;AN000;
DW    141			     ;;AN000;
DW   IT2_LANG_ENT_kdfnow,0             ;;AN000;
DW    168			     ;;AN000;
DW   UK1_LANG_ENT_kdfnow,0             ;;AN000;
DW    166			     ;;AN000;
DW   UK2_LANG_ENT_kdfnow,0             ;;AN000;
DW    150			     ;;AN000;
DW   SF_LANG_ENT_kdfnow,0             ;;AN000;
DW    120			     ;;AN000;
DW   BE_LANG_ENT_kdfnow,0             ;;AN000;
DW    143			     ;;AN000;
DW   NL_LANG_ENT_kdfnow,0             ;;AN000;
DW    155			     ;;AN000;
DW   NO_LANG_ENT_kdfnow,0             ;;AN000;
DW    058			     ;;AN000;
DW   CF_LANG_ENT_kdfnow,0             ;;AN000;
DW    153			     ;;AN000;
DW   SV_LANG_ENT_kdfnow,0             ;;AN000;
DW    171			     ;;AN000;
DW   LA_LANG_ENT_kdfnow,0             ;;AN000;
DW    103			     ;;AN000;
DW   DUMMY_ENT_kdfnow,0              ;;AN000;
;				     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;***************************************
;; Language Entries
;;***************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;   EXTRN SP_LOGIC:NEAR		       ;;
;   EXTRN SP_437_XLAT:NEAR	       ;;
;   EXTRN SP_850_XLAT:NEAR	       ;;
				       ;;
SP_LANG_ENT_kdfnow:			       ;; language entry for SPANISH
  DB   'SP'                            ;;
  DW   172			       ;; AN000;ID entry  (ID CODE)
  DW   SP_LOGIC,0               ;; pointer to LANG kb table
  DB   1			       ;; AN000;number of IDs
  DB   2			       ;; number of code pages
  DW   850			       ;; code page
  DW   SP_850_XLAT,0               ;; table pointer
  DW   437			       ;; code page
  DW   SP_437_XLAT,0               ;; table pointer
				       ;;
;*****************************************************************************
;    EXTRN FR1_LOGIC:NEAR		 ;;AN000;
;    EXTRN FR1_437_XLAT:NEAR		 ;;AN000;
;    EXTRN FR1_850_XLAT:NEAR		 ;;AN000;
					 ;;
 FR1_LANG_ENT_kdfnow:				 ;;AN000; language entry for FRANCE
   DB	'FR'                             ;;AN000; SECONDARY KEYBOARD ID VALUE
   DW	120				 ;;AN000; ID entry
   DW	FR1_LOGIC,0          ;;AN000; pointer to LANG kb table
   DB	2				 ;;AN000; number of code pages
   DB	2				 ;;AN000; number of ids
   DW	437				 ;;AN000; code page
   DW	FR1_437_XLAT,0          ;;AN000; table pointer
   DW	850				 ;;AN000; code page
   DW	FR1_850_XLAT,0          ;;AN000; table pointer
					 ;;AN000;
;*****************************************************************************
;    EXTRN FR2_LOGIC:NEAR		 ;;AC000;
;    EXTRN FR2_437_XLAT:NEAR		 ;;AC000;
;    EXTRN FR2_850_XLAT:NEAR		 ;;AC000;
					 ;;
 FR2_LANG_ENT_kdfnow:				 ;; language entry for FRANCE
   DB	'FR'                             ;; PRIMARY  KEYBOARD ID VALUE
   DW	189				 ;;AC000; ID entry
   DW	FR2_LOGIC,0          ;;AC000; pointer to LANG kb table
   DB	1				 ;;AC000; number of ids
   DB	2				 ;;AC000; number of code pages
   DW	437				 ;;AC000; code page
   DW	FR2_437_XLAT,0          ;;AC000; table pointer
   DW	850				 ;;AC000; code page
   DW	FR2_850_XLAT,0          ;;AC000; table pointer
					 ;;
;****************************************************************************
;   EXTRN PO_LOGIC:NEAR			 ;;AC000;
;   EXTRN PO_850_XLAT:NEAR		 ;;AC000;
;   EXTRN PO_860_XLAT:NEAR		 ;;AC000;
					 ;;
PO_LANG_ENT_kdfnow:				 ;; language entry for PORTUGAL
  DB   'PO'                              ;;
  DW   163				 ;;AN000; ID entry
  DW   PO_LOGIC,0          ;; pointer to LANG kb table
  DB   1				 ;;AC000; number of ids
  DB   2				 ;;AC000; number of code pages
  DW   850				 ;;AC000; code page
  DW   PO_850_XLAT,0          ;;AC000; table pointer
  DW   860				 ;;AC000; code page
  DW   PO_860_XLAT,0          ;;AC000; table pointer
					 ;;
;*****************************************************************************
;   EXTRN DK_LOGIC:NEAR			 ;;
;   EXTRN DK_850_XLAT:NEAR		 ;;AC000;
;   EXTRN DK_865_XLAT:NEAR		 ;;AC000;
					 ;;
 DK_LANG_ENT_kdfnow:				 ;; language entry for DENMARK
   DB	'DK'                             ;;
   DW	159				 ;;AN000; ID entry
   DW	DK_LOGIC,0          ;; pointer to LANG kb table
   DB	1				 ;;AN000;number of ids
   DB	2				 ;;AC000; number of code pages
   DW	850				 ;;AC000; code page
   DW	DK_850_XLAT,0          ;;AC000; table pointer
   DW	865				 ;;AC000; code page
   DW	DK_865_XLAT,0          ;;AC000; table pointer
					 ;;
;*****************************************************************************
;   EXTRN SG_LOGIC:NEAR			 ;;
;   EXTRN SG_850_XLAT:NEAR		 ;;
;   EXTRN SG_437_XLAT:NEAR		 ;;
					 ;;
SG_LANG_ENT_kdfnow:				 ;; language entry for SWISS GERMAN
  DB   'SG'                              ;;
  DW   000				 ;;AN001; ID entry
  DW   SG_LOGIC,0          ;; pointer to LANG kb table
  DB   1				 ;;AN000; number of ids
  DB   2				 ;;AC000; number of code pages
  DW   850				 ;; code page ;;;dcl 850 now default March 8, 1988
  DW   SG_850_XLAT,0          ;; table pointer
  DW   437				 ;; code page
  DW   SG_437_XLAT,0          ;; table pointer
					 ;;
;*****************************************************************************
;   EXTRN SF_LOGIC:NEAR			 ;;
;   EXTRN SF_850_XLAT:NEAR		 ;;
;   EXTRN SF_437_XLAT:NEAR		 ;;
					 ;;
SF_LANG_ENT_kdfnow:				 ;; language entry for SWISS FRENCH
  DB   'SF'                              ;;
  DW   150				 ;;AN000; ID entry
  DW   SF_LOGIC,0          ;; pointer to LANG kb table
  DB   1			       ;;AN000; number of ids
  DB   2				 ;;AC000; number of code pages
  DW   850				 ;; code page ;;;dcl 850 now default March 8, 1988
  DW   SF_850_XLAT,0          ;; table pointer
  DW   437				 ;; code page
  DW   SF_437_XLAT,0          ;; table pointer
					 ;;
;*****************************************************************************
;   EXTRN GE_LOGIC:NEAR			 ;;
;   EXTRN GE_437_XLAT:NEAR		 ;;
;   EXTRN GE_850_XLAT:NEAR		 ;;
					 ;;
GE_LANG_ENT_kdfnow:				 ;; language entry for GERMANY
  DB   'GR'                              ;;
  DW   129				 ;;AN000; ID entry
  DW   GE_LOGIC,0          ;; pointer to LANG kb table
  DB   1			       ;;AN000; number of ids
  DB   2				 ;;AC000; number of code pages
  DW   437				 ;; code page
  DW   GE_437_XLAT,0          ;; table pointer
  DW   850				 ;; code page
  DW   GE_850_XLAT,0          ;; table pointer
					 ;;
;*****************************************************************************
;    EXTRN IT1_LOGIC:NEAR		 ;;AN000;
;    EXTRN IT1_437_XLAT:NEAR		 ;;AN000;
;    EXTRN IT1_850_XLAT:NEAR		 ;;AN000;
					 ;;
 IT1_LANG_ENT_kdfnow:				 ;;AN000; language entry for ITALY
   DB	'IT'                             ;;AN000; SECONDARY KEYBOARD ID VALUE
   DW	142				 ;;AN000; ID entry
   DW	IT1_LOGIC,0          ;;AN000; pointer to LANG kb table
   DB	2				 ;;AN000;number of ids
   DB	2				 ;;AN000; number of code pages
   DW	437				 ;;AN000; code page
   DW	IT1_437_XLAT,0          ;;AN000; table pointer
   DW	850				 ;;AN000; code page
   DW	IT1_850_XLAT,0          ;;AN000; table pointer
					 ;;
;*****************************************************************************
;    EXTRN IT2_LOGIC:NEAR		 ;;
;    EXTRN IT2_437_XLAT:NEAR		 ;;
;    EXTRN IT2_850_XLAT:NEAR		 ;;
					 ;;
 IT2_LANG_ENT_kdfnow:				 ;;AC000; language entry for ITALY
   DB	'IT'                             ;;AC000;  PRIMARY KEYBOARD ID VALUE
   DW	141				 ;;AN000; ID entry
   DW	IT2_LOGIC,0          ;;AN000; pointer to LANG kb table
   DB	1				;;AC000; number of ids
   DB	2				 ;;AC000; number of code pages
   DW	437				 ;;AC000; code page
   DW	IT2_437_XLAT,0          ;;AC000; table pointer
   DW	850				 ;;AC000; code page
   DW	IT2_850_XLAT,0          ;;AC000; table pointer
					 ;;
;*****************************************************************************
;    EXTRN UK1_LOGIC:FAR 		 ;;AN000;
;    EXTRN UK1_437_XLAT:FAR		 ;;AN000;
;    EXTRN UK1_850_XLAT:FAR		 ;;AN000;
					 ;;
 UK1_LANG_ENT_kdfnow:				 ;;AN000; language entry for UNITED KINGDOM
   DB	'UK'                             ;;AN000; SECONDARY KEYBOARD ID VALUE
   DW	168				 ;;AN000; ID entry
   DW	UK1_LOGIC,0          ;;AN000; pointer to LANG kb table
   DB	2				;;AN000; number of ids
   DB	2				 ;;AN000; number of code pages
   DW	437				 ;;AN000; code page
   DW	UK1_437_XLAT,0          ;;AN000; table pointer
   DW	850				 ;;AN000; code page
   DW	UK1_850_XLAT,0          ;;AN000; table pointer
					 ;;
;*****************************************************************************
;    EXTRN UK2_LOGIC:FAR 		 ;;AC000;
;    EXTRN UK2_437_XLAT:FAR		 ;;AC000;
;    EXTRN UK2_850_XLAT:FAR		 ;;AC000;
					 ;;
 UK2_LANG_ENT_kdfnow:				 ;;AN000; language entry for UNITED KINGDOM
   DB	'UK'                             ;;AC000; PRIMARY KEYBOARD ID VALUE
   DW	166				 ;;AC000; ID entry
   DW	UK2_LOGIC,0          ;;AC000; pointer to LANG kb table
   DB	1				;; AN000;number of ids
   DB	2				 ;;AN000; number of code pages
   DW	437				 ;;AC000; code page
   DW	UK2_437_XLAT,0          ;;AC000; table pointer
   DW	850				 ;;AC000; code page
   DW	UK2_850_XLAT,0          ;;AC000; table pointer
					 ;;
;*****************************************************************************
;   EXTRN BE_LOGIC:NEAR			 ;;
;   EXTRN BE_437_XLAT:NEAR		 ;;
;   EXTRN BE_850_XLAT:NEAR		 ;;
					 ;;
BE_LANG_ENT_kdfnow:				 ;; language entry for BELGIUM
  DB   'BE'                              ;;
  DW   120				 ;;AN000; ID entry
  DW   BE_LOGIC,0          ;; pointer to LANG kb table
  DB   1				 ;;AN000; number of ids
  DB   2				 ;;AN000; number of code pages
  DW   850				 ;; code page ;; default to 850 - same as country.sys
  DW   BE_850_XLAT,0          ;; table pointer
  DW   437				 ;; code page
  DW   BE_437_XLAT,0          ;; table pointer
					 ;;
;*****************************************************************************
;*****************************************************************************
;     EXTRN NL_LOGIC:NEAR		 ;;
;     EXTRN NL_437_XLAT:NEAR		 ;;
;     EXTRN NL_850_XLAT:NEAR		 ;;
					 ;;
  NL_LANG_ENT_kdfnow:				 ;; language entry for NETHERLANDS
    DB	 'NL'                            ;;
    DW	 143				 ;;AN000; ID entry
    DW	 NL_LOGIC,0          ;; pointer to LANG kb table
    DB	 1				 ;;AN000; number of ids
    DB	 2				 ;;AN000; number of code pages
    DW	 437				 ;; code page
    DW	 NL_437_XLAT,0          ;; table pointer
    DW	 850				 ;; code page
    DW	 NL_850_XLAT,0          ;; table pointer
					 ;;
;*****************************************************************************
;*****************************************************************************
;     EXTRN NO_LOGIC:NEAR		 ;;
;     EXTRN NO_850_XLAT:NEAR		 ;;AC000;
;     EXTRN NO_865_XLAT:NEAR		 ;;AC000;
					 ;;
  NO_LANG_ENT_kdfnow:				 ;; language entry for NORWAY
    DB	 'NO'                            ;;
    DW	 155				 ;;AN000; ID entry
    DW	 NO_LOGIC,0          ;; pointer to LANG kb table
    DB	 1				 ;;AN000; number of ids
    DB	 2				 ;;AN000; number of code pages
    DW	 850				 ;;AC000; code page
    DW	 NO_850_XLAT,0          ;;AC000; table pointer
    DW	 865				 ;;AC000; code page
    DW	 NO_865_XLAT,0          ;;AC000; table pointer
					 ;;
;*****************************************************************************
;*****************************************************************************
;     EXTRN SV_LOGIC:NEAR		 ;;
;     EXTRN SV_437_XLAT:NEAR		 ;;
;     EXTRN SV_850_XLAT:NEAR		 ;;
					 ;;
  SV_LANG_ENT_kdfnow:				 ;; language entry for SWEDEN
    DB	 'SV'                            ;;
    DW	 153				 ;;AN000; ID entry
    DW	 SV_LOGIC,0          ;; pointer to LANG kb table
    DB	 1				 ;;AN000; number of ids
    DB	 2				 ;;AN000; number of code pages
    DW	 437				 ;; code page
    DW	 SV_437_XLAT,0          ;; table pointer
    DW	 850				 ;; code page
    DW	 SV_850_XLAT,0          ;; table pointer
					 ;;
;*****************************************************************************
;*****************************************************************************
;;  Already declared external above
;;  EXTRN Sv_LOGIC:NEAR 		;; Finland & Sweden have same layout,
;;  EXTRN Sv_437_XLAT:NEAR		;; but different code page defaults,
;;  EXTRN Sv_850_XLAT:NEAR		;; use Sweden data for Finland
					;;
 SU_LANG_ENT_kdfnow:				;; language entry for FINLAND
   DB	'SU'                            ;;
   DW	153				;; ID entry
   DW	SV_LOGIC,0         ;; pointer to LANG kb table
   DB	1				;; number of ids
   DB	2				;; number of code pages
   DW	850				;; code page  ;;;dcl 850 now default, March 8, 1988
   DW	SV_850_XLAT,0         ;; table pointer
   DW	437				;; code page
   DW	SV_437_XLAT,0         ;; table pointer
					;;
;*****************************************************************************
;*****************************************************************************
;     EXTRN CF_LOGIC:NEAR		 ;;
;     EXTRN CF_863_XLAT:NEAR		 ;;
;     EXTRN CF_850_XLAT:NEAR		 ;;
					 ;;
  CF_LANG_ENT_kdfnow:				 ;; language entry for Canadian-French
    DB	 'CF'                            ;;
    DW	 058				 ;; ID entry
    DW	 CF_LOGIC,0          ;; pointer to LANG kb table
    DB	 1				 ;; number of ids
    DB	 2				 ;; number of code pages
    DW	 863				 ;; code page
    DW	 CF_863_XLAT,0          ;; table pointer
    DW	 850				 ;; code page
    DW	 CF_850_XLAT,0          ;; table pointer
					 ;;
;*****************************************************************************
;     EXTRN LA_LOGIC:NEAR		 ;;
;     EXTRN LA_850_XLAT:NEAR		 ;;
;     EXTRN LA_437_XLAT:NEAR		 ;;
					 ;;
  LA_LANG_ENT_kdfnow:				 ;; language entry for LATIN AMERICAN
    DB	 'LA'                            ;;
    DW	 171				 ;;AN000; ID entry
    DW	 LA_LOGIC,0          ;; pointer to LANG kb table
    DB	 1				 ;;AN000; number of ids
    DB	 2				 ;;AN000; number of code pages
    DW	 850				 ;; code page
    DW	 LA_850_XLAT,0          ;; table pointer
    DW	 437				 ;; code page  ; default to 437 -same as country.sys
    DW	 LA_437_XLAT,0          ;; table pointer
					 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
DUMMY_ENT_kdfnow:			       ;; language entry
  DB   'XX'                            ;;
  DW   103			       ;;AC000; ID entry
  DW   DUMMY_LOGIC_kdfnow,0               ;; pointer to LANG kb table
  DB   1			       ;;AC000; number of ids
  DB   5			       ;;AC000; number of code pages
  DW   437			       ;; code page
  DW   DUMMY_XLAT_437_kdfnow,0               ;; table pointer
  DW   850			       ;; code page
  DW   DUMMY_XLAT_850_kdfnow,0               ;; table pointer
  DW   860			       ;; code page
  DW   DUMMY_XLAT_860_kdfnow,0               ;; table pointer
  DW   863			       ;; code page
  DW   DUMMY_XLAT_863_kdfnow,0               ;; table pointer
  DW   865			       ;; code page
  DW   DUMMY_XLAT_865_kdfnow,0               ;; table pointer
				       ;;
DUMMY_LOGIC_kdfnow:			       ;;
   DW  LOGIC_END_kdfnow-$		       ;; length
   DW  0			       ;; special features
   DB  92H,0,0			       ;; EXIT_STATE_LOGIC_COMMAND
LOGIC_END_kdfnow:			       ;;
				       ;;
DUMMY_XLAT_437_kdfnow: 		       ;;
   DW	  6			       ;; length of section
   DW	  437			       ;; code page
   DW	  0			       ;; LAST STATE
				       ;;
DUMMY_XLAT_850_kdfnow: 		       ;;
   DW	  6			       ;; length of section
   DW	  850			       ;; code page
   DW	  0			       ;; LAST STATE
				       ;;
DUMMY_XLAT_860_kdfnow: 		       ;;
   DW	  6			       ;; length of section
   DW	  860			       ;; code page
   DW	  0			       ;; LAST STATE
				       ;;
DUMMY_XLAT_865_kdfnow: 		       ;;
   DW	  6			       ;; length of section
   DW	  865			       ;; code page
   DW	  0			       ;; LAST STATE
				       ;;
DUMMY_XLAT_863_kdfnow: 		       ;;
   DW	  6			       ;; length of section
   DW	  863			       ;; code page
   DW	  0			       ;; LAST STATE
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*****************************************************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
;CODE	 ENDS			       ;;
;	 END			       ;;
