;
; Macro file for MSDOS.
;

macro ASSUME [name]
{
}

macro PAGE
{
}

;SUBTTL BREAK a listing into pages and give new subtitles
MACRO BREAK subtitle
{
}

BREAK <I_NEED: declare a variable external, if necessary, and allocate a size>

;
; declare a variable external and allocate a size
;
macro i_need sym,len
{
}

;
; call a procedure that may be external. The call will be short.
;
macro invoke name
{
        CALL    name
}

;
; jump to a label that may be external. The jump will be near.
;
macro transfer name
{
        JMP     name
}

;
; get a short address in a word
;
macro short_addr name
{
        DW      name
}

;
; get a long address in a dword
;
macro long_addr name
{
        DD      name
}

;
; declare a PROC near or far but PUBLIC nonetheless
;
macro procedure name,distance
{
name:
}

;
; call the macro chain
;
macro do_ext
{
}

;
; define an entry in a procedure
;
macro entry name
{
name:
}

;BREAK <ERROR - print a message and then jump to a label>

macro error code
{
        MOV     AL,code
        JMP     SYS_RET_ERR
}

BREAK <JUMP - real jump that links up shortwise>
;
; given a label <lbl> either 2 byte jump to another label <lbl>_J
; if it is near enough or 3 byte jump to <lbl>
;

macro jump lbl
{
        JMP     lbl
}

BREAK <RETURN - return from a function>

macro return
{
        ret
}

BREAK <CONDRET - conditional return>

macro makelab l,cc,ncc
{
}

macro condret cc,ncc
{
    ret
}

BREAK <RETZ - return if zero, links up shortwise if necessary>

macro retz
{
    condret z,nz
}
 
BREAK <RETNZ - return if not zero, links up shortwise if necessary>

macro retnz
{
    condret nz,z
}

BREAK <RETC - return if carry set, links up shortwise if necessary>

macro retc
{
    condret c,nc
}

BREAK <RETNC - return if not carry, links up shortwise if necessary>

macro retnc
{
    condret nc,c
}

BREAK <CONTEXT - set the DOS context to a particular register>

macro context r
{
        PUSH    SS
        POP     r
}
