EVBOUND = 1  ;THIS VALUE BEING 0 DOES NO BOUNDARY ALLIGNMENT, VALUE 1	  ;3.30
	     ; ALIGNS TO EVEN						  ;3.30

; A macro is made by fasm's preprocessor as it reads the line, whether or not
; the IF around it would have held, so a switch cannot pick between two
; definitions of the same name.  EVBOUND is 1 in the release, and these are
; the definitions that go with it; the byte-aligned pair the ELSE held are
; left below, commented out, so that the choice is still on the page.
							; IF EVBOUND	  ;3.30
macro EVENB					; EVENB MACRO	  ;3.30
{							; EVEN		  ;3.30
	align	2			;;ADJUST TO EVEN BOUNDARY	  ;3.30
}
macro ODD					; ODD	MACRO	  ;3.30
{
;;GENERATE BOUNDARY PADDING TO FORCE ODD OFFSET 			  ;3.30
	if (($-$$) mod 2) = 0		;;MASM counted from the segment	  ;3.30
	  db	?			;; base, which is where this	  ;3.30
	end if				;; address space begins 	  ;3.30
}
; : : : : : : : : : : : : : :						  ;3.30
;	ELSE	;;SINCE EVEN ALLIGNMENT IS NOT DESIRED, JUST USE BYTE ALLI;3.30 GNMENT
; : : : : : : : : : : : : : :						  ;3.30
;									  ;3.30
;EVENB	MACRO								  ;3.30
;;;REQUEST FOR WORD ALLIGNMENT DOES NOTHING				  ;3.30
;	ENDM								  ;3.30
;									  ;3.30
;ODD	MACRO								  ;3.30
;;;REQUEST FOR ODD ALLIGNMENT DOES NOTHING				  ;3.30
;	ENDM								  ;3.30
;	ENDIF								  ;3.30

; The one code segment this BIOS has is opened by the link file, which lays
; the modules down in the order the linker had them, so there is nothing for
; a module to open and nothing for an ASSUME to say.
;CODE_SEGMENT MACRO							  ;3.30
;;;ALLIGN THE SEGMENT ON WORD BOUNDARY TO ALLOW FOR EVEN ALLIGNMENT OF DATA;3.30
;CODE	SEGMENT WORD PUBLIC 'CODE'                                        ;3.30
;	ENDM								  ;3.30
;	CODE_SEGMENT							  ;3.30
;	ASSUME	CS:CODE 						  ;3.30
