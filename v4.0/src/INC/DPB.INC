;	SCCSID = @(#)dpb.asm	1.1 85/04/10
;	SCCSID = @(#)dpb.asm	1.1 85/04/10
BREAK <dpb structure>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
STRUC dpb
{
.dpb_drive	    DB	    0		; Logical drive # assoc with DPB (A=0,B=1,...)
.dpb_UNIT	    DB	    0		; Driver unit number of DPB
.dpb_sector_size     DW	    0		; Size of physical sector in bytes
.dpb_cluster_mask    DB	    0		; Sectors/cluster - 1
.dpb_cluster_shift   DB	    0		; Log2 of sectors/cluster
.dpb_first_FAT	    DW	    0		; Starting record of FATs
.dpb_FAT_count	    DB	    0		; Number of FATs for this drive
.dpb_root_entries    DW	    0		; Number of directory entries
.dpb_first_sector    DW	    0		; First sector of first cluster
.dpb_max_cluster     DW	    0		; Number of clusters on drive + 1
.dpb_FAT_size	    DW	    0		;;Number of records occupied by FAT
.dpb_dir_sector	    DW	    0		; Starting record of directory
.dpb_driver_addr     DD	    0		; Pointer to driver
.dpb_media	    DB	    0		; Media byte
.dpb_first_access    DB	    0		; This is initialized to -1 to force a media
					; check the first time this DPB is used
.dpb_next_dpb	    DD	    0		; Pointer to next Drive parameter block
.dpb_next_free	    DW	    0		; Cluster # of last allocated cluster
.dpb_free_cnt	    DW	    0		; Count of free clusters, -1 if unknown
}
match =dpb_LAID_OUT, dpb_LAID_OUT
{
    dpb_LAID_OUT equ 1
    virtual at 0
      dpb dpb
      sizeof.dpb = $ - dpb
    end virtual
}

DPBSIZ	EQU	sizeof.dpb		; Size of the structure in bytes

DSKSIZ	=	dpb.dpb_max_cluster 	; Size of disk (temp used during init only)
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
