;	SCCSID = @(#)sysvar.asm 1.1 85/04/10
INCLUDE		'VERSION.INC'

STRUC SysInitVars
{
.SYSI_DPB	    DD	    0		; DPB chain
.SYSI_SFT	    DD	    0		; SFT chain
.SYSI_CLOCK	    DD	    0		; CLOCK device
.SYSI_CON	    DD	    0		; CON device
.SYSI_MAXSEC	    DW	    0		; maximum sector size
.SYSI_BUF	    DD	    0		; points to Hashinitvar
.SYSI_CDS	    DD	    0		; CDS list
.SYSI_FCB	    DD	    0		; FCB chain
.SYSI_Keep	    DW	    0		; keep count
.SYSI_NUMIO	    DB	    0		; Number of block devices
.SYSI_NCDS	    DB	    0		; number of CDS's
.SYSI_DEV	    DD	    0		; device list
.SYSI_ATTR	    DW	    0		; null device attribute word
.SYSI_STRAT	    DW	    0		; null device strategy entry point
.SYSI_INTER	    DW	    0		; null device interrupt entry point
.SYSI_NAME	    DB	 8 dup(0)	; null device name
.SYSI_SPLICE	    DB	    0		; TRUE -> splicees being done
.SYSI_IBMDOS_SIZE    DW	    0		; DOS size in paragraphs
SYSI_IFS_DOSCALL@   DD	    0		; IFS DOS service rountine entry
.SYSI_IFS	    DD	    0		; IFS header chain
.SYSI_BUFFERS	    DW	    0,0 	; BUFFERS= values (m,n)
.SYSI_BOOT_DRIVE     DB	    0		; boot drive A=1 B=2,..
.SYSI_DWMOVE	    DB	    0		; 1 if 386 machine
.SYSI_EXT_MEM	    DW	    0		; Extended memory size in KB.
}
match =SysInitVars_LAID_OUT, SysInitVars_LAID_OUT
{
    SysInitVars_LAID_OUT equ 1
    virtual at 0
      SysInitVars SysInitVars
      sizeof.SysInitVars = $ - SysInitVars
    end virtual
}

;This is added for more information exchage between DOS, BIOS.
;DOS will give the pointer to SysInitTable in ES:DI. - J.K. 5/29/86
STRUC SysInitVars_Ext
{
.SYSI_InitVars		DD	0	; Points to the above structure.
.SYSI_Country_Tab	DD	0	; DOS_Country_cdpg_info
}
match =SysInitVars_Ext_LAID_OUT, SysInitVars_Ext_LAID_OUT
{
    SysInitVars_Ext_LAID_OUT equ 1
    virtual at 0
      SysInitVars_Ext SysInitVars_Ext
      sizeof.SysInitVars_Ext = $ - SysInitVars_Ext
    end virtual
}

;The SYSI_BUF of SysInitVars points to the follwong structure
EMS_MAP_BUFF_SIZE      EQU	12	; EMS map buffer size

STRUC Buffinfo
{
.Hash_ptr	 DD	 0		     ; pointer to Hash table
.Hash_count	 DW	 0		     ; number of Hash entries
.Cache_ptr	 DD	 0		     ; pointer to secondary cache
.Cache_count	 DW	 0		     ; number of secondary cache entries

	if	BUFFERFLAG

.EMS_SAFE_FLAG	DB	1
.EMS_LAST_PAGE	DW	0, 0
.EMS_FIRST_PAGE	DW	0, 0
.EMS_NPA640	DW	0

	end if

.EMS_mode	 DB	 -1		     ; no EMS = -1
.EMS_handle	 DW	 0		     ; EMS handle for buffers
.EMS_PageFrame_Number	DW   -1 	     ; EMS page frame number
.EMS_Seg_Cnt	 DW	 1		     ; EMS segment count
.EMS_Page_Frame	 DW	 -1		     ; EMS page frame segment address
.EMS_reserved	 DW	 0		     ; EMS segment count

	if	BUFFERFLAG
.EMS_Map_Buff	 DB	 0  ; map buffer
	else
.EMS_Map_Buff	DB	12 dup(0)
	end if

}
match =Buffinfo_LAID_OUT, Buffinfo_LAID_OUT
{
    Buffinfo_LAID_OUT equ 1
    virtual at 0
      Buffinfo Buffinfo
      sizeof.Buffinfo = $ - Buffinfo
    end virtual
}







