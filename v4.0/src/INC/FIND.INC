;	SCCSID = @(#)find.asm	1.1 85/04/10
;	SCCSID = @(#)find.asm	1.1 85/04/10
Break	<find first/next buffer>

STRUC find_buf
{
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
.find_buf_drive	    DB	0		; drive of search
.find_buf_name	    DB	11 dup (0)	; formatted name
.find_buf_sattr	    DB	0		; attribute of search
.find_buf_LastEnt    DW	0		; LastEnt
.find_buf_DirStart   DW	0		; DirStart
.find_buf_NetID	    DB	4 dup (0)	; Reserved for NET
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

.find_buf_attr	    DB	0		; attribute found
.find_buf_time	    DW	0		; time
.find_buf_date	    DW	0		; date
.find_buf_size_l     DW	0		; low(size)
.find_buf_size_h     DW	0		; high(size)
.find_buf_pname	    DB	13 dup (0)	; packed name
}
match =find_buf_LAID_OUT, find_buf_LAID_OUT
{
    find_buf_LAID_OUT equ 1
    virtual at 0
      find_buf find_buf
      sizeof.find_buf = $ - find_buf
    end virtual
}
