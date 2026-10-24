;	SCCSID = @(#)curdir.asm 1.1 85/04/10
;	SCCSID = @(#)curdir.asm 1.1 85/04/10
BREAK <Current directory list structure>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
; CDS items are used bu the internal routines to store cluster numbers and ;
; network identifiers for each logical name.  The ID field is used dually, ;
; both as net ID and for a cluster number for local devices.  In the case  ;
; of local devices, the cluster number will be -1 if there is a potential  ;
; of the disk being changed or if the path must be recracked.  The END	   ;
; field is the location of the end of the definition.  No .. is allowed    ;
; past this point							   ;

DIRSTRLEN	EQU	(64+3)		; Max length in bytes of directory strings
TEMPLEN 	EQU	(DIRSTRLEN*2)

STRUC curdir_list
{
.curdir_text	DB	DIRSTRLEN dup (0)   ; text of assignment and curdir
.curdir_flags	DW	0		; various flags
.curdir_devptr	DD	0		; local pointer to DPB or net device
.curdir_ID	DW	0		; cluster of current dir (net ID)
		DW	0
.curdir_user_word DW	0
.curdir_end	DW	0		; end of assignment
.curdir_type	DB	0		; IFS drive (2=ifs, 4=netuse)
.curdir_ifs_hdr	DD	0		; Ptr to File System Header
.curdir_fsda	DB	2 dup (0)	; File System Dependent Data Area
}
match =curdir_list_LAID_OUT, curdir_list_LAID_OUT
{
    curdir_list_LAID_OUT equ 1
    virtual at 0
      curdir_list curdir_list
      sizeof.curdir_list = $ - curdir_list
    end virtual
}

curdirLen	EQU	sizeof.curdir_list	; Needed for screwed up
						; ASM87 which doesn't allow
						; Size directive as a macro
						; argument
; The ID field read as a dword rather than a word; in fasm the size goes
; on the instruction, so this is the field's offset and nothing more.
curdir_netID	EQU	curdir_list.curdir_ID

;Flag word masks
curdir_isnet	EQU	1000000000000000B
curdir_isifs	EQU	1000000000000000B	; DOS 4.00
curdir_inuse	EQU	0100000000000000B
curdir_splice	EQU	0010000000000000B
curdir_local	EQU	0001000000000000B
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
