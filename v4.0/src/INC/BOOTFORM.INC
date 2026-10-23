;	%OUT BOOTFORM.INC...
;****************************************************************************
;AN000; - Structure of the Extended IBMBOOT record for DOS -. J.K.
;AN001; - D304 Include PHYDRV, CURHD to the header structure	 11/09/87 J.K.
;****************************************************************************

BOOT_SIZE		 EQU	 512
EXT_BOOT_SIGNATURE	 EQU	 41		;Extended boot signature
;
; MASM made every field name a name for its offset in the structure, which
; is how a label that is no instance of one -- the boot record at 0:7C00h --
; can still be read field by field.  fasm's fields belong to the structure,
; so a reference names the structure too, and the VIRTUAL block below is
; what gives the fields their offsets and the structure its size.
STRUC EXT_BPB_INFO
{
.EBPB_BYTESPERSECTOR	 DW	 0
.EBPB_SECTORSPERCLUSTER	 DB	 0
.EBPB_RESERVEDSECTORS	 DW	 0
.EBPB_NUMBEROFFATS	 DB	 0
.EBPB_ROOTENTRIES	 DW	 0
.EBPB_TOTALSECTORS	 DW	 0
.EBPB_MEDIADESCRIPTOR	 DB	 0
.EBPB_SECTORSPERFAT	 DW	 0
.EBPB_SECTORSPERTRACK	 DW	 0
.EBPB_HEADS		 DW	 0
.EBPB_HIDDENSECTOR	 DD	 0
.EBPB_BIGTOTALSECTORS	 DD	 0
}
virtual at 0
  EXT_BPB_INFO EXT_BPB_INFO
  sizeof.EXT_BPB_INFO = $ - EXT_BPB_INFO
end virtual
;
;AN001; EXT_PHYDRV, EXT_CURHD included in the header for OS2.
STRUC EXT_IBMBOOT_HEADER
{
.EXT_BOOT_JUMP		DB	3 dup (0)
.EXT_BOOT_OEM		DB	8 dup (0)
.EXT_BOOT_BPB		EXT_BPB_INFO	; the BPB itself, field by field
.EXT_PHYDRV		DB	80h
.EXT_CURHD		DB	0
.EXT_BOOT_SIG		DB	EXT_BOOT_SIGNATURE
.EXT_BOOT_SERIAL 	DD	0
.EXT_BOOT_VOL_LABEL	DB	11 dup (0)
.EXT_SYSTEM_ID		DB	8  dup (0)
}
virtual at 0
  EXT_IBMBOOT_HEADER EXT_IBMBOOT_HEADER
  sizeof.EXT_IBMBOOT_HEADER = $ - EXT_IBMBOOT_HEADER
end virtual
;
BOOT_SIGNATURE	=     BOOT_SIZE-2	; a word, where it is read

;
;J.K. This is the number of sectors (of size 512 bytes) that will cover
;the size of IBMLOAD program.  IBMBOOT program has to at least read this
;many sectors, and these sectors should be the first cluster and consecutive.
;Make sure IBMBOOT program uses the same value as this.
IBMLOADSIZE	equ	3	;Number of sectors IBMBOOT program should read in.


