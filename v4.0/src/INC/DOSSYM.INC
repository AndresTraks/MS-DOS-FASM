;	SCCSID = @(#)dossym.asm 1.1 85/04/10
;	SCCSID = @(#)dossym.asm 1.1 85/04/10
	PAGE 80,132
; MASM worked an expression out sixteen bits wide, so NOT TRUE was zero and a
; switch written "if NOT IBM" asked the right question.  fasm's arithmetic is
; wider than that, and NOT 0FFFFh is not zero; TRUE is therefore -1 here,
; which writes the same 0FFFFh into a word and leaves NOT TRUE zero.
TRUE	    EQU -1
FALSE	    EQU 0

Installed   = TRUE
; fasm's = is an assembly-time constant and DEFINED looks forward as well
; as back, so the question is asked of the preprocessor instead.
match =debug, debug { debug	= FALSE }

include 'DBCS.SW'
include 'DOSMAC.INC'
include 'VERSIONA.INC'
;IF2
;    %OUT    DOSSYM in Pass 2
;end if

BREAK <Control character definitions>

c_DEL	    EQU     7Fh 		;    ASCII rubout or delete previous char
c_BS	    EQU     08h 		; ^H ASCII backspace
c_CR	    EQU     0Dh 		; ^M ASCII carriage return
c_LF	    EQU     0Ah 		; ^J ASCII linefeed
c_ETB	    EQU     17h 		; ^W ASCII end of transmission
c_NAK	    EQU     15h 		; ^U ASCII negative acknowledge
c_ETX	    EQU     03h 		; ^C ASCII end of text
c_HT	    EQU     09h 		; ^I ASCII tab

BREAK <Read This and Weep>

;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
; Certain structures, constants and system  calls  below  are  private	to ;
; the DOS  and	are  extremely	version-dependent.  They may change at any ;
; time at  the	implementors'  whim.   As  a  result,  they  must  not  be ;
; documented to  the  general  public.	 If  an  extreme case arises, they ;
; must be documented with this warning. 				   ;
;									   ;
; Those structures and constants that are subject to  the  above  will	be ;
; marked and bracketed with the flag:					   ;
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

include 'BPB.INC'
include 'BUFFER.INC'
BREAK <User stack inside of system call and SysVars>
; Location of user registers relative user stack pointer

STRUC user_environ
{
.user_AX     DW	    0
.user_BX     DW	    0
.user_CX     DW	    0
.user_DX     DW	    0
.user_SI     DW	    0
.user_DI     DW	    0
.user_BP     DW	    0
.user_DS     DW	    0
.user_ES     DW	    0
.user_IP     DW	    0
.user_CS     DW	    0
.user_F	    DW	    0
}
match =user_environ_LAID_OUT, user_environ_LAID_OUT
{
    user_environ_LAID_OUT equ 1
    virtual at 0
      user_environ user_environ
      sizeof.user_environ = $ - user_environ
    end virtual
}

include 'SYSVAR.INC'
include 'VECTOR.INC'
include 'MULT.INC'
BREAK <Disk map>
;  MSDOS partitions the disk into 4 sections:
;
;  phys sector 0:   +-------------------+
;	|	    | boot/reserved	|
;	|	    +-------------------+
;	|	    |  File allocation	|
;	v	    |	   table(s)	|
;		    |  (multiple copies |
;		    |	  are kept)	|
;		    +-------------------+
;		    |	  Directory	|
;		    +-------------------+
;		    |	  File space	|
;		    +-------------------+
;		    |	Unaddressable	|
;		    |  (to end of disk) |
;		    +-------------------+
;
; All partition boundaries are sector boundaries.  The size of the FAT is
; adjusted to maximize the file space addressable.

include 'DIRENT.INC'
BREAK <File allocation Table information>
;
; The File Allocation Table uses a 12-bit entry for each allocation unit on
; the disk.  These entries are packed, two for every three bytes.  The contents
; of entry number N is found by 1) multiplying N by 1.5; 2) adding the result
; to the base address of the Allocation Table; 3) fetching the 16-bit word
; at this address; 4) If N was odd (so that N*1.5 was not an integer), shift
; the word right four bits; 5) mask to 12 bits (AND with 0FFF hex).  Entry
; number zero is used as an end-of-file trap in the OS and is passed to the
; BIOS to help determine disk format.  Entry 1 is reserved for future use.
; The first available allocation unit is assigned entry number two, and even
; though it is the first, is called cluster 2.	Entries greater than 0FF8H
; (12-bit fats) or 0FFF8H (16-bit fats) are end of file marks; entries of zero
; are unallocated.  Otherwise, the contents of a FAT entry is the number of
; the next cluster in the file.
;
; Clusters with bad sectors are tagged with FF7H.  Any non-zero number would
; do because these clusters show as allocated, but are not part of any
; allocation chain and thus will never be allocated to a file.	A particular
; number is selected so that disk checking programs know what to do (ie.  a
; cluster with entry FF7H which is not in a chain is not an error).

include 'DPB.INC'
include 'CURDIR.INC'
include 'CPMFCB.INC'
include 'FIND.INC'
include 'PDB.INC'
include 'EXE.INC'
include 'SF.INC'
include 'ARENA.INC'
include 'INTNAT.INC'
include 'MI.INC'
fChk	equ 1
fDelim	equ 2
fSpChk	equ 4
fFCB	equ 8

include 'FILEMODE.INC'
include 'ERROR.INC'
include 'SYSCALL.INC'
SUBTTL
