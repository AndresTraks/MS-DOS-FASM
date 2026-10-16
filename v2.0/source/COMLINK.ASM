; COMMAND.COM.  The file to assemble; COMLINK is what it replaces.
;
; COMLINK reads
;
;       command rucode rdata init uinit tcode tcode2 tcode3 +
;       tcode4 tcode5 tucode copy copyproc cparse tdata tspc;
;
; and the linker walked those sixteen modules once for each segment, gathering
; that segment's pieces, then laid the segments out in group order.  A module
; contributes to several -- TCODE4 alone puts code in TRANCODE, data in
; TRANDATA and in DATARES, and space in TRANSPACE -- so what came out is in
; nothing like module order.  Each module's segment bodies are now wrapped in
; "if SEGSEL = S_<name>", and the walk below sets SEGSEL and reads all sixteen
; again, which is the same thing said in the assembler instead of the linker.
;
; Where the two groups sit, the shipped COMMAND.COM says exactly:
;
;       file 00000: e9 6d 0a ...    PROGSTART, so the file starts at
;                                   RESGROUP:0100, as any .COM does
;       file 00e70: 100h zero bytes TRANSTART, and TRANGROUP:0000 with it
;       file 00f70: b4 0e cd 21     SETDRV, the transient's first
;                                   instruction, at TRANGROUP:0100
;       file 03c78                  the end, TRANGROUP:2E08, TRANSPACEEND
;
; so a file offset is 100h less than its RESGROUP offset, and TRANGROUP's own
; 100h parameter area is in the file as zeros.  That is what lets LOADCOM seek
; to the plain value of TRANSTART and land on TRANGROUP:0100: the 100h of the
; program header and the 100h of the parameter area cancel.

use16

        INCLUDE 'COMSW.ASM'             ; MSVER, not IBMVER; COMSW.ASM says why
        INCLUDE 'DOSMAC_v211.ASM'       ; ASSUME as a no-op, procedure, return
        INCLUDE 'DOSSYM_v211.ASM'       ; not DOSSYM.ASM: these sources say
                                        ;  Rev 2.11 and want internat_block,
                                        ;  which only the 2.11 one defines.
                                        ;  The kernel is built on it too.
        INCLUDE 'DEVSYM.ASM'
        INCLUDE 'COMEQU.ASM'

S_CODERES       = 1
S_DATARES       = 2
S_ENVIRONMENT   = 3
S_INIT          = 4
S_TAIL          = 5
S_TRANCODE      = 6
S_TRANDATA      = 7
S_TRANSPACE     = 8
S_TRANTAIL      = 9

macro walk
{
        INCLUDE 'COMMAND.ASM'
        INCLUDE 'RUCODE.ASM'
        INCLUDE 'RDATA.ASM'
        INCLUDE 'INIT.ASM'
        INCLUDE 'UINIT.ASM'
        INCLUDE 'TCODE.ASM'
        INCLUDE 'TCODE2.ASM'
        INCLUDE 'TCODE3.ASM'
        INCLUDE 'TCODE4.ASM'
        INCLUDE 'TCODE5.ASM'
        INCLUDE 'TUCODE.ASM'
        INCLUDE 'COPY.ASM'
        INCLUDE 'COPYPROC.ASM'
        INCLUDE 'CPARSE.ASM'
        INCLUDE 'TDATA.ASM'
        INCLUDE 'TSPC.ASM'
}

; ---------------------------------------------------------------------------
; RESGROUP: CODERES, DATARES, ENVIRONMENT, INIT, TAIL.  CODERES leaves the
; first 100h for the program header, so the file begins at PROGSTART.
org 100h
SEGBASE_CODERES = $
SEGSEL = S_CODERES
        walk
SEGBASE_DATARES = $
SEGSEL = S_DATARES                      ; DATARES is byte aligned
        walk
        align 16
SEGBASE_ENVIRONMENT = $
SEGSEL = S_ENVIRONMENT
        walk
        align 16
SEGBASE_INIT = $
SEGSEL = S_INIT
        walk
        align 16
SEGBASE_TAIL = $
SEGSEL = S_TAIL                         ; TRANSTART, and TRANGROUP:0000
        walk

; INIT.ASM stated these two and CPARSE.ASM stated SWCOUNT, each with a
; comment that the figure must agree with the segment it describes.  They
; had to, with the modules assembled apart.  Here they are measured where
; they are defined, and this is the agreement those comments asked for.
if ENVIRONSIZ <> 0A0h | ENVIRONSIZ2 <> 092h
        display 'ENVIRONSIZ or ENVIRONSIZ2 no longer agrees with INIT.ASM', 13, 10
        err
end if

; ---------------------------------------------------------------------------
; TRANGROUP: TRANCODE, TRANDATA, TRANSPACE, TRANTAIL.  The parameter area goes
; into the file, as it does in Microsoft's, and then the addresses start again
; from TRANSTART, which is what OFFSET TRANGROUP:x counts from.
        db      100h dup (0)
org 100h
SEGBASE_TRANCODE = $
SEGSEL = S_TRANCODE
        walk
if SWCOUNT <> 5
        display 'SWCOUNT no longer agrees with what CPARSE.ASM stated', 13, 10
        err
end if
SEGBASE_TRANDATA = $
SEGSEL = S_TRANDATA                     ; TRANDATA and TRANSPACE are byte
        walk                            ;  aligned, and TRANSPACEEND ends
SEGBASE_TRANSPACE = $
SEGSEL = S_TRANSPACE                    ;  the file
        walk
SEGBASE_TRANTAIL = $
SEGSEL = S_TRANTAIL                     ; EXECSTART, which only the IBM build
        walk                            ;  reads, so it is not padded out
