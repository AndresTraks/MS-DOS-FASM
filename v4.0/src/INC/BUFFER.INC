;	SCCSID = @(#)buffer.asm 1.1 85/04/09
BREAK <DISK I/O BUFFER Header>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;

; Field definition for I/O buffer information

STRUC BUFFINFO
{
.buf_next	DW	0		; Pointer to next buffer in list
.buf_prev	DW	0		; Pointer to prev buffer in list
.buf_ID		DB	0		; Drive of buffer (bit 7 = 0)
					; SFT table index (bit 7 = 1)
					; = FFH if buffer free
.buf_flags	DB	0		; Bit 7 = 1 if Remote file buffer
					;	= 0 if Local device buffer
					; Bit 6 = 1 if buffer dirty
					; Bit 5 = Reserved
					; Bit 4 = Search bit (bit 7 = 1)
					; Bit 3 = 1 if buffer is DATA
					; Bit 2 = 1 if buffer is DIR
					; Bit 1 = 1 if buffer is FAT
					; Bit 0 = Reserved
.buf_sector	DD	0		; Sector number of buffer (bit 7 = 0)
; The next two items are often refed as a word (bit 7 = 0)
.buf_wrtcnt	DB	0		; For FAT sectors, # times sector written out
.buf_wrtcntinc	DW	0		; "   "     "   , # sectors between each write
.buf_DPB 	DD	0		; Pointer to drive parameters
.buf_fill	DW	0		; How full buffer is (bit 7 = 1)
.buf_reserved	DB	0		; make DWORD boundary for 386
}
match =BUFFINFO_LAID_OUT, BUFFINFO_LAID_OUT
{
    BUFFINFO_LAID_OUT equ 1
    virtual at 0
      BUFFINFO BUFFINFO
      sizeof.BUFFINFO = $ - BUFFINFO
    end virtual
}

buf_offset	EQU	DWORD PTR buf_sector
					;For bit 7 = 1, this is the byte
					;offset of the start of the buffer in
					;the file pointed to by buf_ID.  Thus
					;the buffer starts at location
					;buf_offset in the file and contains
					;buf_fill bytes.

BUFINSIZ	EQU	sizeof.BUFFINFO
					; Size of structure in bytes

buf_Free	EQU	0FFh		; buf_id of free buffer

;Flag byte masks
buf_isnet	EQU	10000000B
buf_dirty	EQU	01000000B
;***
buf_visit	EQU	00100000B
;***
buf_snbuf	EQU	00010000B

buf_isDATA	EQU	00001000B
buf_isDIR	EQU	00000100B
buf_isFAT	EQU	00000010B
buf_type_0	EQU	11110001B	; AND sets type to "none"

buf_NetID	EQU	BUFINSIZ

;
; Buffer Hash Entry Structure

STRUC BUFFER_HASH_ENTRY
{
.EMS_PAGE_NUM	DW	-1		; logical page number for EMS handle
.BUFFER_BUCKET	DD	 0		; pointer to buffers
.DIRTY_COUNT	DB	 0		; number of dirty buffers
.BUFFER_RESERVED DB	 0		; reserved
}
match =BUFFER_HASH_ENTRY_LAID_OUT, BUFFER_HASH_ENTRY_LAID_OUT
{
    BUFFER_HASH_ENTRY_LAID_OUT equ 1
    virtual at 0
      BUFFER_HASH_ENTRY BUFFER_HASH_ENTRY
      sizeof.BUFFER_HASH_ENTRY = $ - BUFFER_HASH_ENTRY
    end virtual
}

MaxBuffinBucket EQU	15		; Max number of buffers per bucket
MaxBucketinPage EQU	 2		; Max number of buckets per 16kb page


;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
