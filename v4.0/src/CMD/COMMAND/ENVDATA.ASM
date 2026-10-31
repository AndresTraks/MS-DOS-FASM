;	SCCSID = @(#)envdata.asm	1.1 85/05/14
;	SCCSID = @(#)envdata.asm	1.1 85/05/14
; This file is included by command.asm and is used as the default command
; environment.

if SEGSEL = S_ENVARENA
;	ORG 0	; the flat layout is already here
	DB  10h  DUP (?)		 ;Pad for memory allocation addr mark
end if

if SEGSEL = S_ENVIRONMENT	; Default COMMAND environment

;	PUBLIC	ECOMSPEC,ENVIREND,PATHSTRING

;	ORG	0	; the flat layout is already here
; MASM counted an offset from the group, except where a segment register was
; assumed to this segment on its own -- COMMAND builds the environment at the
; paragraph PATHSTRING sits on and points ES there, and the offsets it uses
; inside it are counted from the segment.  The flat image has one address
; space, so those references take this away.
ENVIRONMENT$ = PATHSTRING
PATHSTRING DB	"PATH="
label USERPATH byte

	DB	0		; Null path
	DB	"COMSPEC="
ECOMSPEC DB	"\COMMAND.COM"      ;AC062
	DB	134 DUP (0)

label ENVIREND byte

ENVIRONSIZ EQU	$-PATHSTRING
ENVIRONSIZ2 EQU $-ECOMSPEC
end if
