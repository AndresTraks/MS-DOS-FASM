; Some modules really want TRUE to be 0FFH.  Best to let them have their way.
; fasm's EQU is a preprocessor definition, so an IF around one would not
; stop it being made; MATCH asks the same question where it counts -- the
; name stands for itself only while nothing else has defined it.
match =TRUE, TRUE { TRUE EQU 0FFFFh }
match =TRUEBYTE, TRUEBYTE { TRUEBYTE EQU 0FFh }
match =FALSE, FALSE { FALSE EQU 0 }

;
; Use the following switches to control cmacros.inc
;
?PLM       =       0
?WIN       =       0

memS       EQU     1			; Small model
;
; Use the switches below to produce the standard Microsoft version or the IBM
; version of the operating system
;
; The below chart will indicate how to set the switches to build the various
; versions
;
;                     IBMVER          IBMCOPYRIGHT
; --------------------------------------------------------
;  IBM Version   |     TRUE              TRUE
; --------------------------------------------------------
;  MS Version    |     FALSE             FALSE
; --------------------------------------------------------
;  Clone Version |     TRUE              FALSE
;
IBMVER     EQU     TRUE
IBMCOPYRIGHT EQU   FALSE

BUFFERFLAG	EQU	NOT IBMCOPYRIGHT

match =MSVER, MSVER { MSVER EQU NOT IBMVER }
IBM	   EQU	   IBMVER
;
;
;  IF1
;	IF IBMVER
;	    IF IBMCOPYRIGHT
;              %OUT ... IBM version build switch on ...
;	    ELSE
;	      %OUT ... CLONE version build switch on ...
;	    ENDIF
;	ELSE
;	    IF NOT IBMCOPYRIGHT
;	      %OUT ... MS version build switch on ...
;	    ELSE
;	      %OUT !!!!!!!!!  VERSION SWITCHES SET INCORECTLY  !!!!!!!!!
;	      %OUT !!!!!!!!! CHECK SETTINGS IN INC\VERSION.INC !!!!!!!!!
;	    ENDIF
;	ENDIF   
;  ENDIF
;
;
;***************************************************************************
;*          The following switches are for DBCS or SBCS support            *
;*                                                                         *
;*                     Set INTERNAT EQU TRUE FOR DBCS                      *
;*                     Set INTERNAT EQU FALSE FOR SBCS                     *
;*                                                                         *
;***************************************************************************
;
IBMJAPVER  EQU	   FALSE		;If TRUE set KANJI true also

;
; Switch INTERNAT for DBCS support
;
INTERNAT   EQU	   FALSE
;
; An EQU is a definition fasm's preprocessor makes as it reads the line,
; whether or not the IF around it would have held, so a switch cannot pick
; between two of them.  Both of these follow INTERNAT exactly, so they are
; written as INTERNAT rather than branched on it.
KANJI	   EQU	   INTERNAT
IBMJAPAN   EQU	   INTERNAT

; avoid jerking off vector.inc
match =ALTVECT, ALTVECT { ALTVECT EQU FALSE }	;Switch to build ALTVECT version

;
; Country code switches
; The default contry code is assumed as USA.
;
 KOREA	   EQU	   INTERNAT
 JAPAN	   EQU	   FALSE
;
;	IF1
;		IF INTERNAT
;%OUT	Internat(ECS) version build switch on
;		ENDIF
;	ENDIF
