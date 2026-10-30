;;STRUC--Stucture Macro Library
;;Optimizing Version 2.30  03/31/87
;
; The structured statements the utilities are written in: .IF, .WHILE,
; .REPEAT, .SELECT and the rest.  MASM's library measures every jump over two
; passes and pads the short ones with NOPs, so this is a rewrite of the same
; interface rather than a translation of its workings -- fasm sizes an
; unconditional jump itself.
;
; A statement reads
;
;	.IF	<AX EQ 0>		; a comparison, in angle brackets
;	.IF	C			; or a flag, which needs none
;	.IF	<BIT FLAGS AND MASK>	; or a bit test
;	.IF	<ZERO AX>		; or a register against itself
;
; with a conjunction or a jump distance after it:
;
;	.IF	<AX EQ 0>, AND		; the next .IF continues the condition
;	.IF	<AX EQ 0>, OR
;	.IF	<AX EQ 0>, NEAR		; a body too long for a short jump
;
; Three things differ from MASM.  A conjunction or a distance needs a comma
; in front of it, because fasm's angle brackets close the argument they
; enclose.  An operand that MASM gave brackets of its own, <<WORD PTR
; ES:[SI]> NE 0>, is written in fasm's own syntax instead: <word [ES:SI] NE
; 0>.  And .THEN, which MASM only checked, is nothing at all here.
;
; .FOR and .NEXT are not written, because nothing in this release uses them,
; and neither is a conjunction after .LEAVE, for the same reason.
;
; The statements nest, so each one that is still open has an entry on a
; stack: what kind of statement it is and the labels its closing statement
; has to lay down, with "none" where it needs fewer than three.  The labels
; are fasm's local ones, a fresh name every time the macro declaring them
; runs, and they travel from the statement that opens a structure to the one
; that closes it through the stack.

; ----------------------------------------------------------------------------
; A label where the line stands.
;
; It goes the long way round because of two things fasm's preprocessor does.
; A macro is given its arguments as they were written, not as they stand for,
; so a name DEFINE holds has to be put through MATCH, which does look it up;
; and the first name on a line with a colon after it is a label being named,
; which is the one place the preprocessor leaves a name alone -- so the
; lookup cannot happen there either.
macro place$ name
{
	match n, name \{ n: \}
}

; ----------------------------------------------------------------------------
; The jumps.
;
; A condition is named the way MASM named it -- EQ, NE, NAND and the rest --
; and the mnemonic to jump on it is j written in front of the name, or jn to
; jump when it does not hold.  The processor answers to most of those already,
; in either spelling, since fasm reads a mnemonic whichever way it is
; written; these are the ones it does not, each in the two spellings the
; sources use.

macro buildjump$ name, real
{
	macro name target \{ real target \}
}

irp c, EQ,eq
{
	buildjump$ j#c, je
	buildjump$ jn#c, jne
}
irp c, LT,lt
{
	buildjump$ j#c, jl
	buildjump$ jn#c, jnl
}
irp c, GT,gt
{
	buildjump$ j#c, jg
	buildjump$ jn#c, jng
}
irp c, NLT,nlt
{
	buildjump$ j#c, jnl
	buildjump$ jn#c, jl
}
irp c, NGT,ngt
{
	buildjump$ j#c, jng
	buildjump$ jn#c, jg
}
irp c, ZERO,zero
{
	buildjump$ j#c, jz
	buildjump$ jn#c, jnz
}
irp c, NONZERO,nonzero
{
	buildjump$ j#c, jnz
	buildjump$ jn#c, jz
}
; A bit test leaves the answer in the zero flag the other way round: the bits
; asked for are there when the result is not zero.
irp c, AND,and
{
	buildjump$ j#c, jnz
	buildjump$ jn#c, jz
}
irp c, NAND,nand
{
	buildjump$ j#c, jz
	buildjump$ jn#c, jnz
}
; A flag the processor names with an N of its own: jn and the name would make
; two of them, so each of those is written out.
buildjump$ jnNA, ja
buildjump$ jnna, ja
buildjump$ jnNAE, jae
buildjump$ jnnae, jae
buildjump$ jnNB, jb
buildjump$ jnnb, jb
buildjump$ jnNBE, jbe
buildjump$ jnnbe, jbe
buildjump$ jnNC, jc
buildjump$ jnnc, jc
buildjump$ jnNE, je
buildjump$ jnne, je
buildjump$ jnNG, jg
buildjump$ jnng, jg
buildjump$ jnNGE, jge
buildjump$ jnnge, jge
buildjump$ jnNL, jl
buildjump$ jnnl, jl
buildjump$ jnNLE, jle
buildjump$ jnnle, jle
buildjump$ jnNO, jo
buildjump$ jnno, jo
buildjump$ jnNP, jp
buildjump$ jnnp, jp
buildjump$ jnNS, js
buildjump$ jnns, js
buildjump$ jnNZ, jz
buildjump$ jnnz, jz
irp c, PE,pe
{
	buildjump$ jn#c, jpo
}
irp c, PO,po
{
	buildjump$ jn#c, jpe
}
; CX is zero or it is not, and the processor only asks the one way round.
macro jncxz$ target
{
	local over
	jcxz over
	jmp target
	place$ over
}
irp c, CXZ,cxz
{
	buildjump$ jn#c, jncxz$
}

purge buildjump$

; The two mnemonics a condition's name makes, and the jump.  The name is a
; macro's own argument here because that is what fasm joins with #: a name
; MATCH took out of a condition is still text at that point, and jn#op would
; come out as jnop.
macro jumpon$ op, label, sense
{
	go$ j#op, jn#op, label, sense
}

; Where to go, and whether to go there when the condition holds or when it
; does not.  A conditional jump reaches 127 bytes, which is why a site whose
; body is longer says NEAR: then the jump goes the other way, over an
; unconditional jump that has the whole segment to aim at.
macro go$ yes, no, label, sense
{
	local over
	match =t =short, sense DIST$ \{ yes label \}
	match =f =short, sense DIST$ \{ no label \}
	match =t =near, sense DIST$ \{ no over
	    jmp label
	    place$ over \}
	match =f =near, sense DIST$ \{ yes over
	    jmp label
	    place$ over \}
}

; ----------------------------------------------------------------------------
; The conditions.
;
; Five shapes, told apart by how many words they are written in: a bit test
; is BIT and three more, a comparison is three, a register against itself is
; two and a flag is one.  A shape is tried only if nothing longer has already
; answered, since fasm's MATCH lets the last name in a pattern stand for the
; rest of the line.
;
; The fifth is a comparison whose first operand is more than one word, which
; the sources write inside angle brackets of its own -- <<byte [SI]> EQ 0> --
; because MASM read a condition as a list of words as well.  fasm takes the
; outer brackets off an argument and leaves the inner ones, so the brackets
; are what this matches on.

macro cond$ cond, label, sense
{
	define HIT$ no
	bit$ <cond>, label, sense
	group$ <cond>, label, sense
	three$ <cond>, label, sense
	two$ <cond>, label, sense
	one$ <cond>, label, sense
	lost$ <cond>
}

macro bit$ cond, label, sense
{
	match =BIT l op r, cond \{ test l, r
	    jumpon$ op, label, sense
	    define HIT$ yes \}
	match =bit l op r, cond \{ test l, r
	    jumpon$ op, label, sense
	    define HIT$ yes \}
}

macro group$ cond, label, sense
{
	match =no, HIT$ \{ grouped$ <cond>, label, sense \}
}
macro grouped$ cond, label, sense
{
	match =< l => op r, cond \{ cmp l, r
	    jumpon$ op, label, sense
	    define HIT$ yes \}
}

macro three$ cond, label, sense
{
	match =no, HIT$ \{ compare$ <cond>, label, sense \}
}
macro compare$ cond, label, sense
{
	match l op r, cond \{ cmp l, r
	    jumpon$ op, label, sense
	    define HIT$ yes \}
}

macro two$ cond, label, sense
{
	match =no, HIT$ \{ against$ <cond>, label, sense \}
}
macro against$ cond, label, sense
{
	match op l, cond \{ or l, l
	    jumpon$ op, label, sense
	    define HIT$ yes \}
}

macro one$ cond, label, sense
{
	match =no, HIT$ \{ flag$ <cond>, label, sense \}
}
macro flag$ cond, label, sense
{
	match op, cond \{ jumpon$ op, label, sense
	    define HIT$ yes \}
}

macro lost$ cond
{
	match =no, HIT$ \{ err$ "condition not understood" \}
}

; A conjunction and a jump distance, in whichever order the site wrote them.
macro parse$ p2, p3
{
	define CONJ$ none
	define DIST$ short
	look$ p2
	look$ p3
}
macro look$ p
{
	match =AND, p \{ define CONJ$ and \}
	match =and, p \{ define CONJ$ and \}
	match =OR, p \{ define CONJ$ or \}
	match =or, p \{ define CONJ$ or \}
	match =NEAR, p \{ define DIST$ near \}
	match =near, p \{ define DIST$ near \}
	match =SHORT, p \{ define DIST$ short \}
	match =short, p \{ define DIST$ short \}
}

macro err$ text
{
	display "struc: ", text, 13, 10
	err
}

; ----------------------------------------------------------------------------
; The stack of open structures, innermost first, and the stack of the loops
; among them, which is what .LEAVE leaves.

define S$ bottom none none none end$
define L$ none end$

; One match looks up the labels and the stack together, since an argument
; reaches a macro as the name it was written as and not as what it stands for.
macro s$push type, l1, l2, l3
{
	match a b c cur, l1 l2 l3 S$ \{ define S$ type a b c cur \}
}
macro s$pop
{
	match t a b c rest, S$ \{ define S$ rest
	    define S$TYPE t
	    define S$L1 a
	    define S$L2 b
	    define S$L3 c \}
}
macro s$peek
{
	match t a b c rest, S$ \{ define S$TYPE t
	    define S$L1 a
	    define S$L2 b
	    define S$L3 c \}
}
macro l$push label
{
	match a cur, label L$ \{ define L$ a cur \}
}
macro l$pop
{
	match a rest, L$ \{ define L$ rest
	    define L$NOW a \}
}
macro l$peek
{
	match a rest, L$ \{ define L$NOW a \}
}

; ----------------------------------------------------------------------------
; .IF, and what goes with it.
;
; A chain of conditions joined by AND or OR is one statement written over
; several .IF lines: every line but the last leaves its labels on the stack
; under conjif for the next one to carry on with.  An AND sends a condition
; that fails to the end of the statement and an OR sends one that holds to
; the body, so the body needs a label of its own; the statement needs another
; for where it ends, which is what .ELSE jumps to and .ENDIF lays down.
;
; A closing statement looks at what kind of structure it has taken off the
; stack before it does anything, because taking the next one off would answer
; the question differently.

macro .if cond, p2, p3
{
	parse$ p2, p3
	s$peek
	define CHAIN$ no
	match =conjif, S$TYPE \{ define CHAIN$ yes \}
	match =yes, CHAIN$ \{ s$pop \}
	match =no, CHAIN$ \{ newif$ \}
	ifpart$ <cond>
}

macro newif$
{
	local miss, body, done
	define S$L1 miss
	define S$L2 body
	define S$L3 done
}

macro ifpart$ cond
{
	match =or, CONJ$ \{ cond$ <cond>, S$L2, t
	    s$push conjif, S$L1, S$L2, S$L3 \}
	match =and, CONJ$ \{ cond$ <cond>, S$L1, f
	    s$push conjif, S$L1, S$L2, S$L3 \}
	match =none, CONJ$ \{ cond$ <cond>, S$L1, f
	    place$ S$L2
	    s$push if, S$L1, none, S$L3 \}
}

macro .then
{
}

macro .else dist
{
	s$pop
	define WHAT$ other
	match =if, S$TYPE \{ define WHAT$ if \}
	match =when, S$TYPE \{ define WHAT$ when \}
	match =if, WHAT$ \{ jmp S$L3
	    place$ S$L1
	    s$push else, S$L3, none, none \}
	match =when, WHAT$ \{ jmp S$L3
	    place$ S$L1
	    s$push otherwise, S$L3, none, none \}
	match =other, WHAT$ \{ err$ "else without if" \}
}

macro .elseif cond, p2, p3
{
	parse$ p2, p3
	s$pop
	define WHAT$ other
	match =if, S$TYPE \{ define WHAT$ if \}
	match =if, WHAT$ \{ jmp S$L3
	    place$ S$L1
	    elseif$ <cond> \}
	match =other, WHAT$ \{ err$ "elseif without if" \}
}

; The same statement goes on, so the end stays what it was and only the
; condition's own labels are new.
macro elseif$ cond
{
	local miss, body
	define S$L1 miss
	define S$L2 body
	ifpart$ <cond>
}

macro .endif
{
	s$pop
	define WHAT$ other
	match =if, S$TYPE \{ define WHAT$ if \}
	match =else, S$TYPE \{ define WHAT$ else \}
	match =if, WHAT$ \{ place$ S$L1
	    place$ S$L3 \}
	match =else, WHAT$ \{ place$ S$L1 \}
	match =other, WHAT$ \{ err$ "endif without if" \}
}

; ----------------------------------------------------------------------------
; .SELECT, whose .WHENs are a row of conditions with one end between them.
; The select's own entry stays underneath them, holding that end, until
; .ENDSELECT lays it down.

macro .select x
{
	local done
	s$push select, done, none, none
}

macro .when cond, p2, p3
{
	parse$ p2, p3
	s$peek
	define WHAT$ other
	match =conjwhen, S$TYPE \{ define WHAT$ chain \}
	match =when, S$TYPE \{ define WHAT$ again \}
	match =select, S$TYPE \{ define WHAT$ first \}
	match =chain, WHAT$ \{ s$pop \}
	match =again, WHAT$ \{ s$pop
	    jmp S$L3
	    place$ S$L1
	    newwhen$ S$L3 \}
	match =first, WHAT$ \{ newwhen$ S$L1 \}
	match =other, WHAT$ \{ err$ "when without select" \}
	whenpart$ <cond>
}

; Where the select ends comes in as the name it is held under, so it is
; looked up before that name is given to anything else.
macro newwhen$ done
{
	local miss, body
	match d, done \{ define S$L3 d \}
	define S$L1 miss
	define S$L2 body
}

macro whenpart$ cond
{
	match =or, CONJ$ \{ cond$ <cond>, S$L2, t
	    s$push conjwhen, S$L1, S$L2, S$L3 \}
	match =and, CONJ$ \{ cond$ <cond>, S$L1, f
	    s$push conjwhen, S$L1, S$L2, S$L3 \}
	match =none, CONJ$ \{ cond$ <cond>, S$L1, f
	    place$ S$L2
	    s$push when, S$L1, none, S$L3 \}
}

macro .otherwise dist
{
	s$pop
	define WHAT$ other
	match =when, S$TYPE \{ define WHAT$ when \}
	match =select, S$TYPE \{ define WHAT$ select \}
	match =when, WHAT$ \{ jmp S$L3
	    place$ S$L1
	    s$push otherwise, S$L3, none, none \}
	match =select, WHAT$ \{ s$push otherwise, S$L1, none, none \}
	match =other, WHAT$ \{ err$ "otherwise without select" \}
}

macro .endselect
{
	s$pop
	define WHAT$ other
	match =when, S$TYPE \{ define WHAT$ when \}
	match =otherwise, S$TYPE \{ define WHAT$ otherwise \}
	match =select, S$TYPE \{ define WHAT$ select \}
	match =when, WHAT$ \{ place$ S$L1
	    s$pop
	    place$ S$L1 \}
	match =otherwise, WHAT$ \{ s$pop
	    place$ S$L1 \}
	match =select, WHAT$ \{ place$ S$L1 \}
	match =other, WHAT$ \{ err$ "endselect without select" \}
}

; ----------------------------------------------------------------------------
; The loops.  Each one puts where it breaks to on the loop stack, so that a
; .LEAVE anywhere inside knows where to go.

macro .while cond, p2, p3
{
	parse$ p2, p3
	s$peek
	define CHAIN$ no
	match =conjwhile, S$TYPE \{ define CHAIN$ yes \}
	match =yes, CHAIN$ \{ s$pop \}
	match =no, CHAIN$ \{ newwhile$ \}
	whilepart$ <cond>
}

macro newwhile$
{
	local top, out, body
	place$ top
	define S$L1 top
	define S$L2 out
	define S$L3 body
	l$push out
}

macro whilepart$ cond
{
	match =or, CONJ$ \{ cond$ <cond>, S$L3, t
	    s$push conjwhile, S$L1, S$L2, S$L3 \}
	match =and, CONJ$ \{ cond$ <cond>, S$L2, f
	    s$push conjwhile, S$L1, S$L2, S$L3 \}
	match =none, CONJ$ \{ cond$ <cond>, S$L2, f
	    place$ S$L3
	    s$push while, S$L1, S$L2, none \}
}

macro .endwhile p1
{
	s$pop
	define WHAT$ other
	match =while, S$TYPE \{ define WHAT$ while \}
	match =while, WHAT$ \{ jmp S$L1
	    place$ S$L2
	    l$pop \}
	match =other, WHAT$ \{ err$ "endwhile without while" \}
}

macro .repeat
{
	local top, out
	place$ top
	s$push repeat, top, out, none
	l$push out
}

macro .until cond, p2, p3
{
	parse$ p2, p3
	s$pop
	define WHAT$ other
	match =repeat, S$TYPE \{ define WHAT$ repeat \}
	match =conjuntil, S$TYPE \{ define WHAT$ repeat \}
	match =repeat, WHAT$ \{ untilpart$ <cond> \}
	match =other, WHAT$ \{ err$ "until without repeat" \}
}

; The loop goes round again while the condition does not hold, so a plain
; .UNTIL jumps back when it fails; an AND sends a failure back as well, and
; an OR lets a condition that holds out of the loop at once.
macro untilpart$ cond
{
	define BARE$ no
	match , cond \{ define BARE$ yes \}
	match =yes, BARE$ \{ jmp S$L1
	    place$ S$L2
	    l$pop \}
	match =no, BARE$ \{ untilcond$ <cond> \}
}

macro untilcond$ cond
{
	match =or, CONJ$ \{ cond$ <cond>, S$L2, t
	    s$push conjuntil, S$L1, S$L2, none \}
	match =and, CONJ$ \{ cond$ <cond>, S$L1, f
	    s$push conjuntil, S$L1, S$L2, none \}
	match =none, CONJ$ \{ cond$ <cond>, S$L1, f
	    place$ S$L2
	    l$pop \}
}

macro .loop cc
{
	s$pop
	define WHAT$ other
	match =repeat, S$TYPE \{ define WHAT$ repeat \}
	match =repeat, WHAT$ \{ turn$ cc
	    place$ S$L2
	    l$pop \}
	match =other, WHAT$ \{ err$ "loop without repeat" \}
}

macro turn$ cc
{
	match , cc \{ loop S$L1 \}
	match c, cc \{ loop#c S$L1 \}
}

macro .leave cond, p2, p3
{
	parse$ p2, p3
	l$peek
	define BARE$ no
	match , cond \{ define BARE$ yes \}
	match =yes, BARE$ \{ jmp L$NOW \}
	match =no, BARE$ \{ cond$ <cond>, L$NOW, t \}
}

; ----------------------------------------------------------------------------
; The files write the statements in capitals and in small letters, which were
; one name to MASM.  A condition goes on in brackets of its own, because the
; brackets it arrived in have been taken off and it may have brackets inside
; it -- <<byte [SI]> EQ 0> -- which would otherwise be read as the argument
; and the rest as something after it.

macro .IF cond, p2, p3
{
	.if <cond>, p2, p3
}
macro .THEN
{
}
macro .ELSE dist
{
	.else dist
}
macro .ELSEIF cond, p2, p3
{
	.elseif <cond>, p2, p3
}
macro .ENDIF
{
	.endif
}
macro .SELECT x
{
	.select x
}
macro .WHEN cond, p2, p3
{
	.when <cond>, p2, p3
}
macro .OTHERWISE dist
{
	.otherwise dist
}
macro .ENDSELECT
{
	.endselect
}
macro .WHILE cond, p2, p3
{
	.while <cond>, p2, p3
}
macro .ENDWHILE p1
{
	.endwhile p1
}
macro .REPEAT
{
	.repeat
}
macro .UNTIL cond, p2, p3
{
	.until <cond>, p2, p3
}
macro .LOOP cc
{
	.loop cc
}
macro .LEAVE cond, p2, p3
{
	.leave <cond>, p2, p3
}
