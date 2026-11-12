;Parser INPUT PARM LIST Structure


label NLS_PARMS word
      dw	NLS_PARMSX
      db	0	  ;no extra delimiters

label NLS_PARMSX word
      db	0,1	  ;Min 0 - no path
			  ;Max 1 - path
      dw	NLS_POS1

label NLS_POS1 word
      dw	0201h	 ;File spec (optional)
      dw	0001h	 ;Cap result by file
      dw	RES_VALPTR   ;tbl
      dw	NOVAL	     ;no value list
      db	0	     ;no switch or
			     ;keyword synonyms


label NOVAL word
      db	0

label RES_VALPTR word

      RES_TYPE	 db	?	;Result_type
      RES_ITAG	 db	0	;Matched item tag
      RES_SYN	 dw	0	;synonym returned
      RES_POFF	 dw	0	;drive type or beginning of string
      RES_PSEG	 dw	0	;may be string

