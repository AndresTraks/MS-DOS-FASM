;	SCCSID = @(#)dosmac.asm	1.1 85/04/10
;	SCCSID = @(#)dosmac.asm	1.1 85/04/10
;
; Macro file for MSDOS.
;
; MASM's macros and fasm's are written differently -- the body goes in braces
; and # joins a name together where MASM wrote & -- so each of these is
; rewritten rather than patched, with the MASM text kept beside the ones
; where it says something the fasm version does not.
;
; Two differences run through the file.  The first is that nothing here is
; external any more: one assembly reads every module, so I_NEED has nothing
; to import and the IFNDEF/EXTRN pairs inside INVOKE and TRANSFER have
; nothing to declare.  The second is that an EQU or a MACRO is made by fasm's
; preprocessor as it reads the line, whether or not the IF around it would
; have held -- so where MASM chose between two definitions of a name by a
; switch, there is one definition here with the switch inside it.
;

; MASM worked an expression out sixteen bits wide, so NOT TRUE was zero and a
; switch written "if NOT IBM" asked the right question.  fasm's arithmetic is
; wider than that, and NOT 0FFFFh is not zero; TRUE is therefore -1 here,
; which writes the same 0FFFFh into a word and leaves NOT TRUE zero.
TRUE    EQU -1
FALSE   EQU 0

;SUBTTL BREAK a listing into pages and give new subtitles
;PAGE
macro BREAK   subtitle
{
;	SUBTTL  subtitle
;	PAGE
}

; The files call it BREAK, Break and break, one name to MASM.
macro Break subtitle
{
}
macro break subtitle
{
}

BREAK   <ASMVAR - handle assembly variables once and for all>

; These gave a name FALSE if nothing had given it a value yet.  They cannot
; be written as macros here: fasm's preprocessor puts the value in place of
; a name it already knows, so by the time the macro is called its argument
; is a 0 or a -1 and the name is gone.  MATCH asks the same question where
; the name is still written out -- it holds only while the name stands for
; itself -- so the defaults are set that way, one line each, below and
; wherever else the release called AsmVar.
macro AsmVars varlist
{
}

macro AsmVar var
{
}

BREAK <I_NEED: declare a variable external, if necessary, and ALLOCATE a size>

;
; declare a variable external and allocate a size
;
match =InstalledData, InstalledData { InstalledData = FALSE }
macro I_NEED  sym,len
{
; Nothing to import: one binary.
}

; The modules spell these in every case there is, one name to MASM.
macro i_need  sym,len
{
}
macro I_need  sym,len
{
}
macro I_Need  sym,len
{
}

;
; call a procedure that may be external.  The call will be short.
;
macro invoke  name
{
	CALL    name
}

; INVOKE, Invoke and invoke, one name to MASM.
macro INVOKE  name
{
	invoke  name
}
macro Invoke  name
{
	invoke  name
}

;
; jump to a label that may be external.  The jump will be near.
;
macro transfer    name
{
	jump    name
}

;
; get a short address in a word
;
macro short_addr  name
{
    match =?, name \{ DW ? \}
    match any, name \{ DW name \}
}

;
; get a long address in a dword
;
macro long_addr   name
{
	DD  name
}

;
; declare a PROC near or far but PUBLIC nonetheless
;
?frame        =   0                     ; initial
?aframe       =   0                     ; initial
?stackdepth   =   0                     ; initial stack size
?initstack    =   0                     ; initial stack size

; The distance is not the macro's business in fasm: a procedure's RET is
; written RETF where MASM declared it FAR, MASM having assembled it as a far
; return.
macro procedure   name,distance
{
	?frame =    0
	?aframe =   2                   ;; remember the pushed BP
name:
	?initstack    = ?stackdepth     ;; beginning of procedure
}

;
; end a procedure and check that stack depth is preserved
;
macro EndProc name, chk
{
    match , chk \{
	if ?initstack <> ?stackdepth	;; is it different?
	display "***** Possible stack size error *****",13,10
	end if
	\}
}

;
; define a data item to be public and of an appropriate size/type
;
; SIZE is WORD, DWORD, BYTE or a count of bytes, and INIT either a list of
; values or nothing at all, in which case the space is reserved.
;
; One value of the initialiser, as wide as the size said.  It is a macro of
; its own because a MATCH inside a MACRO is as deep as fasm's braces go
; without being escaped twice over.
macro I_AM_VALUES [itm]
{
  forward
    if I_AM_LEN = 1
	DB  itm
    else
	DW  itm
    end if
    I_AM_SIZE = I_AM_SIZE - 1
}

macro I_AM    name,size,init
{
    ; what the size says: WORD and DWORD are one or two words, BYTE and a
    ; bare count are that many bytes
    I_AM_SIZE = 1
    I_AM_LEN  = 1
    I_AM_COUNTED = 0
    ; fasm's MATCH is case-sensitive and the modules write the size in
    ; either case
    match =WORD, size \{
	I_AM_LEN = 2
	I_AM_COUNTED = 1 \}
    match =word, size \{
	I_AM_LEN = 2
	I_AM_COUNTED = 1 \}
    match =DWORD, size \{
	I_AM_SIZE = 2
	I_AM_LEN = 2
	I_AM_COUNTED = 1 \}
    match =dword, size \{
	I_AM_SIZE = 2
	I_AM_LEN = 2
	I_AM_COUNTED = 1 \}
    match =BYTE, size \{
	I_AM_COUNTED = 1 \}
    match =byte, size \{
	I_AM_COUNTED = 1 \}
    if I_AM_COUNTED = 0
	I_AM_SIZE = size
    end if
name:
    ; InstalledData is FALSE in this build, which is the branch that writes
    ; the values out; the other reserved the space and left them to whatever
    ; had installed the data elsewhere.
    match , init \{
	DB  I_AM_SIZE*I_AM_LEN dup (?) \}
    match any, init \{
	I_AM_VALUES init
	if I_AM_SIZE <> 0
	    display "***** initialization not complete *****",13,10
	end if \}
}
I_AM_SIZE   = 0
I_AM_LEN    = 0

macro I_am    name,size,init
{
	I_AM    name,size,<init>
}
macro i_am    name,size,init
{
	I_AM    name,size,<init>
}

;
; define an entry in a procedure
;
macro entry name
{
name:
}

BREAK <ERROR - store an error code then jump to a label>

macro error code
{
	MOV AL,code
	transfer    SYS_RET_ERR
}

BREAK <JUMP - real jump that links up shortwise>
;
; given a label <lbl> either 2 byte jump to another label <lbl>_J
; if it is near enough or 3 byte jump to <lbl>
;
; fasm picks the shortest jump that reaches by itself, so the <lbl>_J copies
; MASM kept to jump to are not needed.
;
macro jump lbl
{
	JMP lbl
}
macro JUMP lbl
{
	jump lbl
}
macro Jump lbl
{
	jump lbl
}

BREAK <RETURN - return from a function>

macro return  x
{
	RET
}

BREAK <CONDRET - conditional return>

; MASM linked these up to the nearest RET it had already laid down; fasm
; writes the jump round a RET of its own, which comes to the same thing.
macro condret cc,ncc
{
    local skip
    j#ncc   skip
	ret
  skip:
}

BREAK <RETZ - return if Zero, links up shortwise if necessary>

macro retz
{
    condret z,nz
}

BREAK <RETNZ - return if not Zero, links up shortwise if necessary>

macro retnz
{
    condret nz,z
}

BREAK <RETC - return if carry Set, links up shortwise if necessary>

macro retc
{
    condret c,nc
}

BREAK <RETNC - return if not carry, links up shortwise if necessary>

macro retnc
{
    condret nc,c
}

; The upper-case spellings the modules also use, one name to MASM.
macro RETZ
{
    retz
}
macro RETNZ
{
    retnz
}
macro RETC
{
    retc
}
macro RETNC
{
    retnc
}

BREAK <CONTEXT - Set the DOS context to a particular register>

macro context   r
{
	PUSH    SS
	POP     r
;	ASSUME  r:DOSGROUP
}

BREAK <SaveReg - save a Set of registers>

macro SaveReg reglist			;; push those registers
{
    irp reg, reglist \{
	?stackdepth = ?stackdepth + 1
	PUSH    reg \}
}

BREAK <RestoreReg - unsave some registers>

macro RestoreReg  reglist		;; pop those registers
{
    irp reg, reglist \{
	?stackdepth = ?stackdepth - 1
	POP     reg \}
}

BREAK <Critical section macros>

macro EnterCrit section
{
	Invoke  E#section
}

macro LeaveCrit section
{
	Invoke  L#section
}

Break   <message - display a message>

match =ShareF, ShareF { ShareF = FALSE }
match =Cargs, Cargs { Cargs = FALSE }
match =Redirector, Redirector { Redirector = FALSE }
match =debug, debug { debug = FALSE }

; The debugging aids.  DEBUG is FALSE in the release, which is the ELSE of
; each of the three IFs these stood under, so each of them is the empty one.
macro fmt     typ,lev,fmts,args
{
}

Break   <DOSAssume - validate assumes>

macro DOSAssume   reg,reglist,message
{
}

BREAK   <ASSERT - make assertions about registers>

macro Assert  kind, objs, message
{
}

Break   <CallInstall - hook to installable pieces>

; Installed is TRUE, so this is the INT 2FH call to whatever has hooked the
; multiplex number; the ELSE called the routine in the kernel directly.
macro CallInstall   name,mpx,fn,save,restore
{
    if Installed
    match any, save \{ SaveReg <save> \}
	MOV     AX,(mpx shl 8) + fn
	INT     2Fh
    match any, restore \{ RestoreReg  <restore> \}
    else
	Invoke  name
    end if
}

;
; MASM's EVEN, and the alignment the linker gave a segment, fill with zeros.
; fasm's own ALIGN writes NOPs, which is what MASM did in code and not what
; it did in data -- and every place this stands for here is data.
;
macro align_zero   boundary
{
	times ((boundary - ($ mod boundary)) mod boundary) db 0
}

Break   <Stack frame manipulators>

; A local variable is a name for a place below BP and an argument a name for
; one above it; both are memory operands, so in fasm the size goes in front
; of the brackets.  ?frame and ?aframe count the bytes as the names are
; declared, which is why a procedure's declarations have to be read in order.
;
; The count cannot go into the name's definition itself: EQU keeps the text
; it is given, and ?frame in that text would be read where the name is used
; -- by then the procedure has declared its other variables and the count has
; moved on.  So each name takes a constant of its own, name__frame, fixed at
; the count it was declared at, and the name stands for a place relative to
; that.  A second procedure declaring the same name gives that constant a new
; value, and a use takes the value standing before it, which is what MASM's
; own redefinition did.
; A length that is not one of the three size words is a count of bytes, and
; the name then stands for the first of them.  fasm's match has no "anything
; else" case, so the byte count is worked out first and the name defined at
; byte width; WORD and DWORD say so again afterwards, and the later
; definition is the one a use finds.
macro localvar    name,length
{
	LV_BYTES equ length
	match =BYTE, length \{ restore LV_BYTES
	    LV_BYTES equ 1 \}
	match =WORD, length \{ restore LV_BYTES
	    LV_BYTES equ 2 \}
	match =DWORD, length \{ restore LV_BYTES
	    LV_BYTES equ 4 \}
	?frame =  ?frame + LV_BYTES
	restore LV_BYTES
	name#__frame = ?frame
	name EQU  byte [BP-name#__frame]
	match =WORD, length \{
	    name EQU  word [BP-name#__frame] \}
	match =DWORD, length \{
	    name EQU  dword [BP-name#__frame]
	    ; the two halves, in either case: MASM read NAMEL and NAMEl as one
	    name#l EQU  word [BP-name#__frame]
	    name#L EQU  word [BP-name#__frame]
	    name#h EQU  word [BP-name#__frame+2]
	    name#H EQU  word [BP-name#__frame+2] \}
}

; ENTER and LEAVE are instructions of the 286 as well; a macro of the same
; name stands in front of one, which is what this did to MASM too.
macro enter
{
	push    bp
	mov     bp,sp
	sub     sp,?frame
}

macro leave
{
	mov     sp,bp
	pop     bp
}

macro Argvar  name,length
{
	LV_BYTES equ length
	match =BYTE, length \{ restore LV_BYTES
	    LV_BYTES equ 1 \}
	match =WORD, length \{ restore LV_BYTES
	    LV_BYTES equ 2 \}
	match =DWORD, length \{ restore LV_BYTES
	    LV_BYTES equ 4 \}
	name#__frame = ?aframe
	?aframe =  ?aframe + LV_BYTES
	restore LV_BYTES
	name EQU  byte [BP+name#__frame]
	match =WORD, length \{
	    name EQU  word [BP+name#__frame] \}
	match =DWORD, length \{
	    name EQU  dword [BP+name#__frame]
	    name#l EQU  word [BP+name#__frame]
	    name#L EQU  word [BP+name#__frame]
	    name#h EQU  word [BP+name#__frame+2]
	    name#H EQU  word [BP+name#__frame+2] \}
}

BREAK   <errnz - generate compilation errors>

macro errnz   x
{
    if (x) <> 0
	display "***** FATAL error: expression <> 0",13,10
	err
    end if
}

; MASM read a name in any case; fasm does not, and the modules spell
; these macros every way there is.  Each other spelling is a name for
; the same macro, its arguments passed through as they came.

macro asmvar [args]
{
  common
	AsmVar args
}
macro Callinstall [args]
{
  common
	CallInstall args
}
macro ENDPROC [args]
{
  common
	EndProc args
}
macro Endproc [args]
{
  common
	EndProc args
}
macro Context [args]
{
  common
	context args
}
macro Enter [args]
{
  common
	enter args
}
macro Entry [args]
{
  common
	entry args
}
macro Leave [args]
{
  common
	leave args
}
macro LocalVar [args]
{
  common
	localvar args
}
macro PROCEDURE [args]
{
  common
	procedure args
}
macro Procedure [args]
{
  common
	procedure args
}
macro RETURN [args]
{
  common
	return args
}
macro Return [args]
{
  common
	return args
}
macro Short_Addr [args]
{
  common
	short_addr args
}
macro Short_addr [args]
{
  common
	short_addr args
}
macro TRANSFER [args]
{
  common
	transfer args
}
macro Transfer [args]
{
  common
	transfer args
}
