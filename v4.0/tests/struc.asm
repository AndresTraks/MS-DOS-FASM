; One of each structured statement, for tests/struc.sh to hold the generated
; code against.  INC/STRUC.INC is where they are written; the utilities are
; what uses them.
	use16
	org 100h
include '../src/INC/STRUC.INC'

; a flag
	.IF	C
	inc	ax
	.ENDIF
; a comparison, with an else
	.IF	<AX EQ 0>
	inc	bx
	.ELSE
	dec	bx
	.ENDIF
; one inside another
	.IF	<AX NE -1>
	  .IF	  <BL eq 3>
	  nop
	  .ENDIF
	dec	cx
	.ENDIF
; two conditions that both have to hold, and two where either will do
	.IF	<AX EQ 1>, AND
	.IF	<BX EQ 2>
	inc	dx
	.ENDIF
	.IF	<AX EQ 1>, OR
	.IF	<BX EQ 2>
	inc	si
	.ENDIF
; a bit test, and a register against itself
	.IF	<BIT AL AND 3>
	inc	di
	.ENDIF
	.IF	<ZERO AX>
	inc	bp
	.ENDIF
; a body too long for a short jump
	.IF	<AX EQ 0>, NEAR
	times	130 nop
	.ENDIF
; a chain of them
	.IF	<AX EQ 1>
	mov	al, 1
	.ELSEIF <AX EQ 2>
	mov	al, 2
	.ELSE
	mov	al, 3
	.ENDIF
; one of several
	.SELECT
	  .WHEN   <AX EQ 1>
	  mov	  cl, 1
	  .WHEN   <AX EQ 2>
	  mov	  cl, 2
	  .OTHERWISE
	  mov	  cl, 3
	.ENDSELECT
; a loop with a way out of the middle of it
	.WHILE	<CX NE 0>
	dec	cx
	  .IF	  <CX EQ 5>
	  .LEAVE
	  .ENDIF
	.ENDWHILE
; a loop that tests at the bottom, and one the processor counts
	.REPEAT
	inc	ax
	.UNTIL	<AX EQ 10>
	.REPEAT
	inc	bx
	.LOOP
	ret
