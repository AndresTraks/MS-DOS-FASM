; the layouts below read these, and an EQU is read where it stands
NAME_LEN EQU	8			;;
NORMAL	EQU	0			;; normal state
GOOD	EQU	0			;; STATUS :

STRUC RHC RHC_LEN_=0, RHC_2_=0, RHC_CMD_=0, RHC_STA_=0, RHC_5_=0
{
.RHC_LEN DB	RHC_LEN_ ;; length of Request Header
	DB	RHC_2_ ;; unit code (subunit)
.RHC_CMD DB	RHC_CMD_ ;; command code
.RHC_STA DW	RHC_STA_ ;; status
	DQ	RHC_5_ ;; reserved for DOS
}
match =RHC_LAID_OUT, RHC_LAID_OUT
{
    RHC_LAID_OUT equ 1
    virtual at 0
      RHC RHC 0, 0, 0, 0, 0
      sizeof.RHC = $ - RHC
    end virtual
}
STRUC RH0 RH0_1_=0, RH0_ENDO_=0, RH0_ENDS_=0, RH0_BPBA_=0, RH0_5_=0, RH0_CONFIG_ERRMSG_=0
{
	rb      (sizeof.RHC)  ;; common portion
					;;
	DB	RH0_1_ ;; not used for CHAR devices
.RH0_ENDO DW	RH0_ENDO_ ;; offset  of ending address
.RH0_ENDS DW	RH0_ENDS_ ;; segment of ending address
.RH0_BPBA DD	RH0_BPBA_ ;; pointer to BPBA
	db	RH0_5_
.RH0_CONFIG_ERRMSG dw RH0_CONFIG_ERRMSG_ ;DCR D493 "Error in CONFIG.SYS..." msg flag.
}
match =RH0_LAID_OUT, RH0_LAID_OUT
{
    RH0_LAID_OUT equ 1
    virtual at 0
      RH0 RH0 0, 0, 0, 0, 0, 0
      sizeof.RH0 = $ - RH0
    end virtual
}
STRUC RH3 RH3_1_=0, RH3_DTAO_=0, RH3_DTAS_=0, RH3_CNT_=0
{
	rb      (sizeof.RHC)  ;; common portion
					;;
					;;
	DB	RH3_1_ ;; media descriptor
.RH3_DTAO DW	RH3_DTAO_ ;; offset  of transfer address
.RH3_DTAS DW	RH3_DTAS_ ;; segment of transfer address
.RH3_CNT DW	RH3_CNT_ ;; byte count
}
match =RH3_LAID_OUT, RH3_LAID_OUT
{
    RH3_LAID_OUT equ 1
    virtual at 0
      RH3 RH3 0, 0, 0, 0
      sizeof.RH3 = $ - RH3
    end virtual
}
STRUC GIH GIH_MAF_=0, GIH_MIF_=0, GIH_SI_=0, GIH_DI_=0, GIH_GBA_=0
{
	rb      (sizeof.RHC)  ;; common portion
					;;
					;;
.GIH_MAF DB	GIH_MAF_ ;; major function
.GIH_MIF DB	GIH_MIF_ ;; minor function
.GIH_SI	DW	GIH_SI_ ;; content of SI
.GIH_DI	DW	GIH_DI_ ;; content of DI
.GIH_GBA DD	GIH_GBA_ ;; Address of Generic Buffer
}
match =GIH_LAID_OUT, GIH_LAID_OUT
{
    GIH_LAID_OUT equ 1
    virtual at 0
      GIH GIH 0, 0, 0, 0, 0
      sizeof.GIH = $ - GIH
    end virtual
}
STRUC GB1S GB1_FLAG_=0, GB1_LEN_=0, GB1_NUM_=0, GB1_CP_=0
{
.GB1_FLAG DW	GB1_FLAG_ ;; flag
.GB1_LEN DW	GB1_LEN_ ;; length
.GB1_NUM DW	GB1_NUM_ ;; length
.GB1_CP	DW	GB1_CP_ ;;
}
match =GB1S_LAID_OUT, GB1S_LAID_OUT
{
    GB1S_LAID_OUT equ 1
    virtual at 0
      GB1S GB1S 0, 0, 0, 0
      sizeof.GB1S = $ - GB1S
    end virtual
}
STRUC GB2S GB2_LEN_=0, GB2_CP_=0
{
.GB2_LEN DW	GB2_LEN_ ;; length
.GB2_CP	DW	GB2_CP_ ;;
}
match =GB2S_LAID_OUT, GB2S_LAID_OUT
{
    GB2S_LAID_OUT equ 1
    virtual at 0
      GB2S GB2S 0, 0
      sizeof.GB2S = $ - GB2S
    end virtual
}
STRUC GB3S GB3_LEN_=0, GB3_GBL_=0
{
.GB3_LEN DW	GB3_LEN_ ;; length
.GB3_GBL DW	GB3_GBL_ ;; hardware code page number
}
match =GB3S_LAID_OUT, GB3S_LAID_OUT
{
    GB3S_LAID_OUT equ 1
    virtual at 0
      GB3S GB3S 0, 0
      sizeof.GB3S = $ - GB3S
    end virtual
}
STRUC GBLS GBL_LEN_=0, GBL_CP_=0
{
.GBL_LEN DW	GBL_LEN_ ;; length
.GBL_CP	DW	GBL_CP_ ;; hardware code page number
}
match =GBLS_LAID_OUT, GBLS_LAID_OUT
{
    GBLS_LAID_OUT equ 1
    virtual at 0
      GBLS GBLS 0, 0
      sizeof.GBLS = $ - GBLS
    end virtual
}
STRUC DHS DH_NEXTO_=0, DH_NEXTS_=0, DHS_3_=0, DH_STRAO_=0, DH_INTRO_=0
{
.DH_NEXTO DW	DH_NEXTO_ ;; offset of pointer to next header
.DH_NEXTS DW	DH_NEXTS_ ;; segment of pointer to next header
	DW	DHS_3_ ;; attribute
.DH_STRAO DW	DH_STRAO_ ;; offset to strategy routine
.DH_INTRO DW	DH_INTRO_ ;; offset to interrupt routine
.DH_NAME DB	NAME_LEN DUP(0) 	;; device name in this header
}
match =DHS_LAID_OUT, DHS_LAID_OUT
{
    DHS_LAID_OUT equ 1
    virtual at 0
      DHS DHS 0, 0, 0, 0, 0
      sizeof.DHS = $ - DHS
    end virtual
}
STRUC FTBLK FTB_LENGTH_=sizeof.FTBLK, FTB_STATUS_=0FFFFH, FTB_TYPE_=0, FTB_CP_=0FFFFH, FTB_MOD_=0, FTB_FONTS_=0, FTB_ROWS_=0, FTB_COLS_=0, FTB_X_=0, FTB_Y_=0, FTB_COUNT_=0, FTB_SELECT_=0, FTB_SELLEN_=0, FTB_DLEFT_=0, FTB_DLEN_=0, FTB_DALO_=0, FTB_DAHI_=0, TARGET_LO_=0, TARGET_HI_=0
{
.FTB_LENGTH DW	FTB_LENGTH_ ;; (NOT TO BE CHANGED)
.FTB_STATUS DW	FTB_STATUS_ ;; (O) parsing compelte
.FTB_TYPE DW	FTB_TYPE_ ;; (O)
.FTB_TID rb      8      ;; (I)
.FTB_CP	DW	FTB_CP_ ;; (I)
.FTB_MOD DW	FTB_MOD_ ;; (O)
.FTB_FONTS DW	FTB_FONTS_ ;; (O)
.FTB_ROWS  DB	FTB_ROWS_ ;; (O) DISPLAY TYPE DEVICE
.FTB_COLS  DB	FTB_COLS_ ;; (O) DISPLAY TYPE DEVICE
.FTB_X	  DB	FTB_X_ ;; (O) DISPLAY TYPE DEVICE
.FTB_Y	  DB	FTB_Y_ ;; (O) DISPLAY TYPE DEVICE
.FTB_COUNT DW	FTB_COUNT_ ;; (O) DISPLAY TYPE DEVICE
.FTB_SELECT DW	FTB_SELECT_ ;; (O) PRINTER TYPE DEVICE
.FTB_SELLEN DW	FTB_SELLEN_ ;; (O) PRINTER TYPE DEVICE
.FTB_DLEFT DW	FTB_DLEFT_ ;; (O)	=0, none to come
.FTB_DLEN DW	FTB_DLEN_ ;; (O)	=0, not in this packet
.FTB_DALO DW	FTB_DALO_ ;; (O)	in the DOS "packet" buffer
.FTB_DAHI DW	FTB_DAHI_ ;; (O)	"  "   "    "       "
.TARGET_LO DW	TARGET_LO_ ;;  internal registers
.TARGET_HI DW	TARGET_HI_ ;;  internal registers
}
match =FTBLK_LAID_OUT, FTBLK_LAID_OUT
{
    FTBLK_LAID_OUT equ 1
    virtual at 0
      FTBLK FTBLK 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.FTBLK = $ - FTBLK
    end virtual
}
STRUC FBUFS FLAG_=0, BUFFER_LEN_=0, BUFFER_ADDR_=0, NUM_FTBLK_=0
{
.FLAG	DW	FLAG_ ;;
.BUFFER_LEN DW	BUFFER_LEN_ ;;
.BUFFER_ADDR DD	BUFFER_ADDR_ ;;
.NUM_FTBLK DW	NUM_FTBLK_ ;; no. of FTBKL entries
}
match =FBUFS_LAID_OUT, FBUFS_LAID_OUT
{
    FBUFS_LAID_OUT equ 1
    virtual at 0
      FBUFS FBUFS 0, 0, 0, 0
      sizeof.FBUFS = $ - FBUFS
    end virtual
}
STRUC PAR_OT PAR_DEV_NUM_=0, PAR_OFF_=0
{
.PAR_DEV_NUM DW	PAR_DEV_NUM_ ;;
.PAR_OFF DW	PAR_OFF_ ;;
}
match =PAR_OT_LAID_OUT, PAR_OT_LAID_OUT
{
    PAR_OT_LAID_OUT equ 1
    virtual at 0
      PAR_OT PAR_OT 0, 0
      sizeof.PAR_OT = $ - PAR_OT
    end virtual
}
STRUC PAR_DEVOT PAR_onum_=0, PAR_DNMO_=0, PAR_DIDO_=0, PAR_HWCPO_=0, PAR_DESGO_=0, PAR_PARMO_=0
{
.PAR_onum DW	PAR_onum_ ;; number of offsets in the table
.PAR_DNMO DW	PAR_DNMO_ ;; device-name table offset
.PAR_DIDO DW	PAR_DIDO_ ;; device-id table offset
.PAR_HWCPO DW	PAR_HWCPO_ ;; hwcp table offset
.PAR_DESGO DW	PAR_DESGO_ ;; designate table offset
.PAR_PARMO DW	PAR_PARMO_ ;; parameter table offset
}
match =PAR_DEVOT_LAID_OUT, PAR_DEVOT_LAID_OUT
{
    PAR_DEVOT_LAID_OUT equ 1
    virtual at 0
      PAR_DEVOT PAR_DEVOT 0, 0, 0, 0, 0, 0
      sizeof.PAR_DEVOT = $ - PAR_DEVOT
    end virtual
}
STRUC PAR_DNMT PAR_DNML_=0, PAR_DNM_=0
{
.PAR_DNML DW	PAR_DNML_ ;; length of device name
.PAR_DNM DB	PAR_DNM_ ;; device name
}
match =PAR_DNMT_LAID_OUT, PAR_DNMT_LAID_OUT
{
    PAR_DNMT_LAID_OUT equ 1
    virtual at 0
      PAR_DNMT PAR_DNMT 0, 0
      sizeof.PAR_DNMT = $ - PAR_DNMT
    end virtual
}
STRUC PAR_DIDT PAR_DIDL_=0, PAR_DID_=0
{
.PAR_DIDL DW	PAR_DIDL_ ;; device ID length
.PAR_DID DB	PAR_DID_ ;; device ID
}
match =PAR_DIDT_LAID_OUT, PAR_DIDT_LAID_OUT
{
    PAR_DIDT_LAID_OUT equ 1
    virtual at 0
      PAR_DIDT PAR_DIDT 0, 0
      sizeof.PAR_DIDT = $ - PAR_DIDT
    end virtual
}
STRUC PAR_HWCPT PAR_HWCPL_=0, PAR_HWCP_=0
{
.PAR_HWCPL DW	PAR_HWCPL_ ;; hwcp entry number
.PAR_HWCP DW	PAR_HWCP_ ;; hwcp
}
match =PAR_HWCPT_LAID_OUT, PAR_HWCPT_LAID_OUT
{
    PAR_HWCPT_LAID_OUT equ 1
    virtual at 0
      PAR_HWCPT PAR_HWCPT 0, 0
      sizeof.PAR_HWCPT = $ - PAR_HWCPT
    end virtual
}
STRUC PAR_DESGT PAR_DESGL_=0, PAR_DESG_=0, PAR_FONT_=0
{
.PAR_DESGL DW	PAR_DESGL_ ;; entry number
.PAR_DESG DW	PAR_DESG_ ;; designate
.PAR_FONT DW	PAR_FONT_ ;; fonts
}
match =PAR_DESGT_LAID_OUT, PAR_DESGT_LAID_OUT
{
    PAR_DESGT_LAID_OUT equ 1
    virtual at 0
      PAR_DESGT PAR_DESGT 0, 0, 0
      sizeof.PAR_DESGT = $ - PAR_DESGT
    end virtual
}
STRUC PAR_PARMT PAR_PARML_=0, PAR_PARM_=0
{
.PAR_PARML DW	PAR_PARML_ ;; length
.PAR_PARM DW	PAR_PARM_ ;;
}
match =PAR_PARMT_LAID_OUT, PAR_PARMT_LAID_OUT
{
    PAR_PARMT_LAID_OUT equ 1
    virtual at 0
      PAR_PARMT PAR_PARMT 0, 0
      sizeof.PAR_PARMT = $ - PAR_PARMT
    end virtual
}
STRUC BUF_DATA BFLAG_=-1, DEV_HDRO_=-1, DEV_HDRS_=-1, LPT_STRAO_=-1, LPT_STRAS_=-1, LPT_INTRO_=-1, LPT_INTRS_=-1, RH_PTRO_=-1, RH_PTRS_=-1, RNORMO_=-1, prn_bufo_=-1, did_prn_=0, PCLASS_=0, STATE_=NORMAL, STATUS_=GOOD, PDESCO_=-1, HSLMX_=0, HARDMX_=0, HARDSO_=-1, HCARMX_=0, HRBUFO_=-1, RSLMX_=0, RAMMX_=0, RAMSO_=-1, RBUFMX_=0, RMBUFO_=-1, FTSZPA_=-1, FTSIZE_=0, FTSTART_=-1, FTSLOTO_=-1, FTDLO_=-1, FSELEN_=0, FSELMAX_=0, SAVED_CP_=-1, BUFEND_=0
{
.BFLAG	 DW	BFLAG_ ;; buf flag for initialisation
					;; -1 = buf not yet initialised
					;; (see BF_PRN, BF_LPT's)
					;;
.DEV_HDRO DW	DEV_HDRO_ ;; device driver n header offset
.DEV_HDRS DW	DEV_HDRS_ ;;
.LPT_STRAO DW	LPT_STRAO_ ;; dos lptn strategy offset
.LPT_STRAS DW	LPT_STRAS_ ;;
.LPT_INTRO DW	LPT_INTRO_ ;; dos lptn strategy offset
.LPT_INTRS DW	LPT_INTRS_ ;;
.RH_PTRO DW	RH_PTRO_ ;; request header offset
.RH_PTRS DW	RH_PTRS_ ;; segment ....................(unique)
					;;
					;; (following is replicated for LPT1 )
					;;
.RNORMO	DW	RNORMO_ ;; request-normal driver header offset
.prn_bufo dw	prn_bufo_ ;; offset to prn buffer
.did_prn  dw	 did_prn_ ;; where PRN is in the DID order
.PCLASS	 DW	 PCLASS_ ;;
.STATE	DW	STATE_ ;;
.STATUS	DW	STATUS_ ;;
					;; (the followings should be used
					;;  IFF BUT.STATE <> NORMAL : )
					;;
.PDESCO	DW	PDESCO_ ;; offset to printer description table.
					;;
					;;===== hwcp and designated slots ====
.HSLMX	DW	HSLMX_ ;; HSLMX is the size of HARDslot (at
					;; HARDSO) and the buffer(at HRBUFO)
					;;
.HARDMX	DW	HARDMX_ ;; no. of HWCP+cart slots supported
					;; (less than or equal to .HSLOTS)
.HARDSO	DW	HARDSO_ ;; offset to hardware slots n
					;;
.HCARMX	DW	HCARMX_ ;; no. of cart slots supported
.HRBUFO	DW	HRBUFO_ ;; offset to cart slots' buffer
					;;
					;;===== physical and designated RAM ===
					;;
.RSLMX	DW	RSLMX_ ;; RSLMX is the size of RAMslot (at
					;; RAMSO) and the RAM buffer(at RMBUFO)
					;;
					;;
.RAMMX	DW	RAMMX_ ;; no. of physical RAM slots(max.=1)
.RAMSO	DW	RAMSO_ ;; offset to RAM slots(incl. designated
					;;
.RBUFMX	DW	RBUFMX_ ;; no. of designated RAM slots supported
.RMBUFO	DW	RMBUFO_ ;; offset to RAM slots's buffer
					;;
.FTSZPA	DW	FTSZPA_ ;; font buffer in paragraph = FONTSZ
.FTSIZE	DW	FTSIZE_ ;; font buffer size = FTSZPA x 16
.FTSTART DW	FTSTART_ ;; start of font buffer
.FTSLOTO DW	FTSLOTO_ ;; segment address of font buffer
					;; -- of the one to be designated to
.FTDLO	DW	FTDLO_ ;; offset to where the FTSTART:OFFSET
					;; (next destination = total length
					;;		       so far)
.FSELEN	DW	FSELEN_ ;; length of selection control copied
					;; to the selection buffer
					;; (USED BY SELECT TYPE = 1 ONLY)
					;; -- initialized to 0, if selection
					;;    is not 0, copied the selection
					;;    from the font file until the
					;;    length is reached. After copying
					;;    to selection buffer, reset to 0
.FSELMAX DW	FSELMAX_ ;; max. room reserved for selection
					;; controls.
					;;
.PAR_EXTRACTO DB (sizeof.PAR_DEVOT) DUP (-1) ;; Offset to parameter extracts
.SAVED_CP    DW	SAVED_CP_ ;; WGR saved code page during lock	    ;AN000;
.BUFEND	DW	BUFEND_ ;; END OF BUFFER, for LPT1 copy.
}
match =BUF_DATA_LAID_OUT, BUF_DATA_LAID_OUT
{
    BUF_DATA_LAID_OUT equ 1
    virtual at 0
      BUF_DATA BUF_DATA 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.BUF_DATA = $ - BUF_DATA
    end virtual
}
STRUC PDSH PD_LEN_=30, TYPEID_='        ', VMINOR_=0, VMAJOR_=1, CLASS_=0, FONTSZ_=0, HSLOTS_=0, HWCPMIN_=0, RSLOTS_=0
{
.PD_LEN	DW	PD_LEN_ ;; length of each entry
.TYPEID	DB	TYPEID_ ;; device name (id), length DEVN_LEN
.VMINOR	DB	VMINOR_ ;; version :  .00
.VMAJOR	DB	VMAJOR_ ;; version : 1.
.CLASS	DW	CLASS_ ;; reserved
.FONTSZ	DW	FONTSZ_ ;; font buffer size in paragraph (max)
.HSLOTS	DW	HSLOTS_ ;; hard-slots number (max # of Hslots)
.HWCPMIN DW	HWCPMIN_ ;; what left by min_hwcp can be cart.
.RSLOTS	DW	RSLOTS_ ;; ram-slots number  (max # of Rslots)
}
match =PDSH_LAID_OUT, PDSH_LAID_OUT
{
    PDSH_LAID_OUT equ 1
    virtual at 0
      PDSH PDSH 0, '        ', 0, 0, 0, 0, 0, 0, 0
      sizeof.PDSH = $ - PDSH
    end virtual
}
STRUC PDS SELH_O_=0, SELR_O_=0, SELB_O_=0
{
	rb      (sizeof.PDSH)  ;; common portion
.SELH_O	DW	SELH_O_ ;; offset to select controls on Hslots
.SELR_O	DW	SELR_O_ ;; offset to select controls on Rslots
.SELB_O	DW	SELB_O_ ;; offset to buffered select controls
}
match =PDS_LAID_OUT, PDS_LAID_OUT
{
    PDS_LAID_OUT equ 1
    virtual at 0
      PDS PDS 0, 0, 0
      sizeof.PDS = $ - PDS
    end virtual
}
STRUC SLTS SLT_CP_=-1, SLT_AT_=0
{
.SLT_CP	DW	SLT_CP_ ;; code page : no code page
.SLT_AT	DW	SLT_AT_ ;; attribute : empty
}
match =SLTS_LAID_OUT, SLTS_LAID_OUT
{
    SLTS_LAID_OUT equ 1
    virtual at 0
      SLTS SLTS 0, 0
      sizeof.SLTS = $ - SLTS
    end virtual
}
STRUC PARSE_NAME N_LENGTH_=0, FNAME_="        "
{
.N_LENGTH      DW    N_LENGTH_ ;;					    ;AN000;
.FNAME	      DB    FNAME_ ;;                                          ;AN000;
}
match =PARSE_NAME_LAID_OUT, PARSE_NAME_LAID_OUT
{
    PARSE_NAME_LAID_OUT equ 1
    virtual at 0
      PARSE_NAME PARSE_NAME 0, "        "
      sizeof.PARSE_NAME = $ - PARSE_NAME
    end virtual
}
STRUC PARSE_OFFSETS PARSE_OFFSETS_1_=0, DN_OFFSET_=0, DI_OFFSET_=0, DCP_OFFSET_=0, DD_OFFSET_=0, PARSE_OFFSETS_6_=0
{
	      DW    PARSE_OFFSETS_1_ ;;					    ;AN000;
.DN_OFFSET     DW    DN_OFFSET_ ;;					    ;AN000;
.DI_OFFSET     DW    DI_OFFSET_ ;;					    ;AN000;
.DCP_OFFSET    DW    DCP_OFFSET_ ;;					    ;AN000;
.DD_OFFSET     DW    DD_OFFSET_ ;;					    ;AN000;
	      DW    PARSE_OFFSETS_6_ ;;					    ;AN000;
}
match =PARSE_OFFSETS_LAID_OUT, PARSE_OFFSETS_LAID_OUT
{
    PARSE_OFFSETS_LAID_OUT equ 1
    virtual at 0
      PARSE_OFFSETS PARSE_OFFSETS 0, 0, 0, 0, 0, 0
      sizeof.PARSE_OFFSETS = $ - PARSE_OFFSETS
    end virtual
}
STRUC PARSE_HWCP NUM_HWCPS_=0, HWCP_1_=0, HWCP_2_=0, HWCP_3_=0, HWCP_4_=0, HWCP_5_=0, HWCP_6_=0, HWCP_7_=0, HWCP_8_=0, HWCP_9_=0, HWCP_10_=0
{
.NUM_HWCPS     DW    NUM_HWCPS_ ;;					    ;AN000;
.HWCP_1	      DW    HWCP_1_ ;;					    ;AN000;
.HWCP_2	      DW    HWCP_2_ ;;					    ;AN000;
.HWCP_3	      DW    HWCP_3_ ;;					    ;AN000;
.HWCP_4	      DW    HWCP_4_ ;;					    ;AN000;
.HWCP_5	      DW    HWCP_5_ ;;					    ;AN000;
.HWCP_6	      DW    HWCP_6_ ;;					    ;AN000;
.HWCP_7	      DW    HWCP_7_ ;;					    ;AN000;
.HWCP_8	      DW    HWCP_8_ ;;					    ;AN000;
.HWCP_9	      DW    HWCP_9_ ;;					    ;AN000;
.HWCP_10       DW    HWCP_10_ ;;					    ;AN000;
}
match =PARSE_HWCP_LAID_OUT, PARSE_HWCP_LAID_OUT
{
    PARSE_HWCP_LAID_OUT equ 1
    virtual at 0
      PARSE_HWCP PARSE_HWCP 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.PARSE_HWCP = $ - PARSE_HWCP
    end virtual
}
STRUC PARSE_DESG NUM_VALUES_=0, NUM_DESGS_=0, NUM_FONTS_=0
{
.NUM_VALUES    DW    NUM_VALUES_ ;;					    ;AN000;
.NUM_DESGS     DW    NUM_DESGS_ ;;					    ;AN000;
.NUM_FONTS     DW    NUM_FONTS_ ;;					    ;AN000;
}
match =PARSE_DESG_LAID_OUT, PARSE_DESG_LAID_OUT
{
    PARSE_DESG_LAID_OUT equ 1
    virtual at 0
      PARSE_DESG PARSE_DESG 0, 0, 0
      sizeof.PARSE_DESG = $ - PARSE_DESG
    end virtual
}

	PAGE	,132

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  FILENAME:	  CPS Printer Device Driver EQUAL Include
;;  MODULE NAME:  CPSEQU
;;  TYPE:	  Include File
;;
;;  LINK PROCEDURE:  See CPSPx.ASM
;;
;;  INCLUDE FILES:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Request Header (Common portion)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
RH	equ	es:DI	;; addressability to Request Header
					;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;; Command in the Request Header
					;; (see CMD_CODES table)
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
CMD_INI EQU	0			;; init  command
CMD_WRT EQU	8			;; write command
CMD_GIO EQU	19			;; generic IOCTL command
					;; (see major/minor GIO functions)
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;; status values for RHC_STA
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
STAT_DONE EQU	01H			;; function complete - high order byte
STAT_CMDERR EQU 8003H			;; invalid command code error
STAT_ERROR EQU	8000H			;; error returned by normal driver
					;;
;; see Generic IOCTL Request Header section
;; for more errorneous status.		;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Request Header for INIT
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Request Header for IOCTL
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Request Header for GENERIC IOCTL
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;; GIO major/minor functions
					;; (see GIO_CODES table)
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAF_CON EQU	03			;; major function for CON  device
MAF_PTR EQU	05			;; major function for LPTX device
					;;
MIF_DST EQU	4CH			;; minor function : designate start
MIF_DEN EQU	4DH			;;		    designate end
MIF_IVK EQU	4AH			;;		    invoke
MIF_QIV EQU	6AH			;;		    query-invoked
MIF_QLS EQU	6BH			;;		    query-list
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; Designate Start (MIF_DST)Flags
					;; see GBIS structure
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
DSF_FIFOCP EQU	08000H			;; Single code page FIFO command
DSF_CARTCP EQU	00001H			;; Code page for Cartridge/semi-
					;; hardware RAM
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; Generic IOCTL errorneous status
					;; upon return
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
STAT_DELETE EQU 08000H			;; previous degignate deleted (DST)
					;; STAT_DELETE : only for FIFO
STAT_NOFIND EQU 08008H			;; codepage,device not found  (DST)
STAT_DEVERR EQU 0800AH			;; Device error (DST,IVK,QIV,QLS,WRT)
STAT_BADATA EQU 0800CH			;; bad font file (DST)
STAT_NOBUFF EQU 0800CH			;; no font buffer for (REFRESH)
STAT_BADDEN EQU 0800CH			;; no DST (DEN)
STAT_bffDEN EQU 08000H			;; bad font file (DEN)
STAT_TOMANY EQU 0800aH			;; too manay codepages (DST)
STAT_DUPLCP EQU 0800aH			;; too manay codepages (DST)
STAT_NOCPIV EQU 08007H			;; no codepage designated/invoked
STAT_NOCP EQU	08007H			;; no codepage designated/invoked
					;; (IVK, QIV, QLS)
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Generic IOCTL Buffer   DS:[SI]
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GIOB	equ	ds:SI	;;
					;;
					;;
					;;
					;;
					;;
					;;
GB3_MINILEN EQU 4			;; minimium length of GB3
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	DEVICE	Header	   DS:[SI]	-- to locate the next LPTn header
;;	NEXT device header ES:[DI]
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HP	equ	ds:SI	;;
NHD	equ	es:DI	;;
					;;
NAME_LEN EQU	8			;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	FONT_PARSER data
;;
;;	-- Interface table : FTABLE
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
FPKT	equ	ds:SI	;;
					;;
FTP	equ	es:BX	;;
					;; ( I=Input  O=Output )
					;;
TYPE_DISPLAY EQU 01H			;; display type device
TYPE_PRINTER EQU 02H			;; printer type device
					;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; FLAGS :
FLAG_RESTART EQU 000001H		;; bit 1 = restart the parsing
					;;
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; STATUS : (in FTB_STATUS)
					;;
FSTAT_COMPLETE EQU 0FFFFH		;; parsing compeleted. (good status)
FSTAT_FONT  EQU 0FFFEH			;; font data is defined and returned
FSTAT_FOUND EQU 0FFFDH			;; informations including font-length
FSTAT_MATCH EQU 0FFFCH			;; font header matches	FTBLK
FSTAT_SEARCH EQU 0FFFBH 		;; seraching for header & font
FSTAT_BOTTOM EQU 0FFF0H 		;; below this are the DOS_STATUS.
					;;
;; the FSTAT with value lower than 0FFF0H is to be returned to the DOS
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	DEVICE Command Parser Table   ES:[DI]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
table_len	equ	290		;;
					;;
PSE	equ	es:DI	;;
					;;
					;;
					;;
					;;
					;;
					;;
					;;
					;;
					;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; LPTn	printer data structure	CS:[BX]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
BUF	equ	cs:BX	;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; STATES
					;;
NORMAL	EQU	0			;; normal state
CPSW	EQU	1			;;
DESG_WR EQU	2			;; designate write
DESG_END EQU	3			;; designate end
LOCKED	 EQU	4			;; WGR locked
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GOOD	EQU	0			;; STATUS :
REPLX	EQU	8000H			;; codepage replaced in DST
FAIL	EQU	4000H			;; fail in designate
LOADED	EQU	2000H			;; the font has just been loaded to
REFRESH EQU	0800H			;; there was a refresh via DST
					;;
					;; also
					;; -- DSF_CARTCP
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;; for BFLAG :
BF_PRN	EQU	0			;;  0 = PRN  initialized (interrupt)
BF_LPT1 EQU	1			;;  1 = LPT1 initialized (interrupt)
BF_LPT2 EQU	2			;;  2 = LPT2 initialized (interrupt)
BF_LPT3 EQU	3			;;  3 = LPT3 initialized (interrupt)
BF_MEM_DONE  EQU 08000H 		;;  memory done for this device
					;;
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; BUFFER DATA structure
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Printer Description Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
DEVN_LEN EQU	8			;; device name (type-id) length
					;;
					;; in the next two entries in PDS
					;;
					;;
					;;
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	HARD / RAM slots table structure/constants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; NOTE : must be only FOUR bytes for
					;;	  codepage positioning
					;;	  calculation as compared
					;;	  with each entry in FTDL_OFF
					;;
					;;
					;; ATTRIBUTES :
AT_RAM1 EQU	 00001H 		;; in the 1st physical RAM slot
AT_RAM2 EQU	 00002H 		;; in the 2nd physical RAM slot
AT_RAM3 EQU	 00004H 		;; in the 3rd physical RAM slot
AT_RAM4 EQU	 00008H 		;; in the 4th physical RAM slot
AT_RAMS EQU	 0000FH 		;;(note the current logic supports
					;; only ONE physical RAM slot)
					;;
AT_OCC	EQU	 01000H 		;; slot occupied
AT_ACT	EQU	 02000H 		;; slot active
AT_HWCP EQU	 04000H 		;; slot is hwcp
AT_OLD	EQU	 08000H 		;; codepage in buffer is not newly
					;; designated.
AT_LOAD EQU	 00100H 		;; slot with font to be loaded
AT_FONT EQU	 00200H 		;; font in this slot has been loaded
AT_NO_LOAD	equ	(NOT  AT_LOAD)	;; to reset the bit
AT_NO_FONT	equ	(NOT  AT_FONT)	;; to reset the bit
AT_SELECT EQU	 00400H 		;; for SELECT TYPE = 1
					;; -- mark the FTBLK where control is
					;;    copied from.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;; constants on SLOTS
HARDSL_MAX EQU	12			;;
					;;
RAMSL_MAX EQU	12			;;
					;;
CTL_MAX 	EQU	32		;; max.length of each selection control
CTL5202_OFFS	EQU	8		;; offset to CTL5202_H for codepage
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	General Constants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
STACK_SIZE	EQU	28H		;; in paragraph, total 200H bytes
					;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; STRUCS AND EQUATES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
					;;
					;;
					;;
					;;
ZERO	EQU	0H			;;					    ;AN000;
ONE	EQU	1H			;;					    ;AN000;
TWO	EQU	2H			;;					    ;AN000;
THREE	EQU	3H			;;					    ;AN000;
FOUR	EQU	4H			;;					    ;AN000;
FIVE	EQU	5H			;;					    ;AN000;
SIX	EQU	6H			;;					    ;AN000;
SEVEN	EQU	7H			;;					    ;AN000;
EIGHT	EQU	8H			;;					    ;AN000;
NINE	EQU	9H			;;					    ;AN000;
TEN	EQU    0AH			;;					    ;AN000;
NUMBER	      EQU    1			;;					    ;AN000;
STRING	      EQU    3			;;					    ;AN000;
COMPLEX       EQU    4			;;					    ;AN000;
RC_EOL	      equ    (-1)	;;					    ;AN000;
RC_NO_ERROR   EQU    0			;;					    ;AN000;
RC_OP_MISSING EQU    2			;;					    ;AN000;
ON	      EQU    1			;;					    ;AN000;
OFF	      EQU    0			;;					    ;AN000;
BAD_SYNTAX_MSG EQU   12 		;;					    ;AN000;
BAD_DEVICE_MSG EQU   2			;;					    ;AN000;
;

