	   PAGE    60,132 ;
	   TITLE DEBDATA.SAL - PC DOS
;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: DEBDATA.SAL
;
; DESCRIPTIVE NAME: DATA SEGMENT VALUE DEFINITION
;
; FUNCTION: PROVIDES ALL DATA SEGMENT DEFINITIONS.
;
; ENTRY POINT: NA
;
; INPUT: ANY VALUE IN DATA SEGMENT
;
; EXIT NORMAL: NA
;
; EXIT ERROR: NA
;
; INTERNAL REFERENCES: NA
;
; EXTERNAL REFERENCES: NA
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK DEBUG+DEBCOM1+DEBCOM2+DEBCOM3+DEBASM+DEBUASM+DEBERR+
;	      DEBCONST+DEBDATA+DEBMES
;
; REVISION HISTORY:
;
;	AN000	VERSION 4.00 - REVISIONS MADE RELATE TO THE FOLLOWING:
;
;				- IMPLEMENT DBCS HANDLING	DMS:6/17/87
;				- IMPLEMENT MESSAGE RETRIEVER	DMS:6/17/87
;				- > 32 MB SUPPORT		DMS:6/17/87
;
; COPYRIGHT: "MS DOS DEBUG UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;	     "LICENSED MATERIAL - PROPERTY OF Microsoft  "
;
;======================= END OF SPECIFICATIONS ===========================

;	   IF1
;	       %OUT COMPONENT=DEBUG, MODULE=DEBDATA
;	   ENDIF
.XLIST
.XCREF
	   include 'DOSSYM.INC'
	   include 'DEBEQU.ASM'
	   include 'DPL.ASM'
.LIST
.CREF
if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_DATA
end if

if SEGSEL = S_CSTACK
end if

;DG	   GROUP CODE,CONST,CSTACK,DATA

if SEGSEL = S_DATA
;	   PUBLIC PARITYFLAG,XNXOPT,XNXCMD,SWITCHAR,EXTPTR,HANDLE,TRANSADD
;	   PUBLIC PARSERR,ASMADD,DISADD,DISCNT,ASMSP,INDEX,DEFDUMP,DEFLEN
;	   PUBLIC REGSAVE,SEGSAVE,OFFSAVE,TEMP,BUFFER,BYTCNT,OPCODE,AWORD
;	   PUBLIC REGMEM,MIDFLD,MODE,NSEG,BRKCNT,TCOUNT,ASSEM_CNT
;	   PUBLIC ASSEM1,ASSEM2,ASSEM3,ASSEM4,ASSEM5,ASSEM6,BYTEBUF,BPTAB
;	   PUBLIC DIFLG,SIFLG,BXFLG,BPFLG,NEGFLG,NUMFLG,MEMFLG,REGFLG
;	   PUBLIC MOVFLG,TSTFLG,SEGFLG,LOWNUM,HINUM,F8087,DIRFLG,DATAEND
;	   PUBLIC BEGSEG,CREATE_LONG,ARG_BUF_INDEX
;	   PUBLIC FILEEND,FILESTRT,SSINTSAV,BPINTSAV
;	   PUBLIC FZTRACE, PREV24, FIN24

;	   public rel_read_write_tab		;an000;relative read/write
						;      table
;	   public rel_low_sec			;an000;sector add. low word
;	   public rel_high_sec			;an000;sector add. high word
;	   public rel_sec_num			;an000;# of sectors to access
;	   public rel_rw_add			;an000;transfer address

;	   public lbtbl 			;an000;lead byte table pointer

;	public xm_page				;an000;
;	public xm_log				;an000;
;	public xm_phy				;an000;
;	public xm_handle			;an000;
;	public xm_handle_ret			;an000;
;	public xm_page_cnt			;an000;
;	public xm_handle_pages_buf		;an000;
;	public xm_frame 			;an000;
;	public xm_deall_han			;an000;
;	public xm_alloc_pg			;an000;
;	public xm_total_pg			;an000;
;	public xm_han_total			;an000;
;	public xm_han_alloc			;an000;

;=========================================================================
; REL_READ_WRITE_TAB : This table provides the new generic IOCTL primitive
;		       read/write with its values.
;
;	Date	  : 6/17/87
;=========================================================================

label REL_READ_WRITE_TAB dword  ;an000;relative read/write
						;      table
	rel_low_sec	dw	?		;an000;sector add. low word
	rel_high_sec	dw	?		;an000;sector add. high word
	rel_sec_num	dw	?		;an000;# of sectors to write
	rel_rw_add	dd	?		;an000;holds the segment
						;      & offset of the
						;      transfer address

;=========================================================================

lbtbl		rd      1 ;an000;lead byte table pointer

	xm_page        db   ?			;an000;page count to allocate
	xm_log	       db   ?			;an000;log. page to map
	xm_phy	       db   ?			;an000;phy. page to map
	xm_deall_han   dw   ?			;an000;handle to deallocate
	xm_handle      dw   ?			;an000;handle to map
	xm_handle_ret  dw   ?			;an000;handle created


	xm_page_cnt    dw   ?			;an000;current page count

	xm_handle_pages_buf db	 1024 dup(0)	;an000;hold handle pages

	xm_frame	dw  ?			;an000;holds frame segment

	xm_alloc_pg	dw  ?			;an000;active page count

	xm_total_pg	dw  ?			;an000;total possible page cnt.

	xm_han_total	dw  ?			;an000;total possible handles

	xm_han_alloc	dw  ?			;an000;handles allocated

	   IF	IBMVER
;	       PUBLIC OLD_MASK
OLD_MASK       rb      1
	   end if
PREV24	   rd      1 ; prevvious INT 24 handler
FIN24	   DB	0			; TRUE => in the process of cleaning up
FZTRACE    DB	0			; TRUE => in a Ztrace
FILEEND    rw      1 ; ARR 2.4
FILESTRT   rw      1 ; ARR 2.4
SSINTSAV   rd      1 ; ARR 2.4
BPINTSAV   rd      1 ; ARR 2.4

PARITYFLAG DB	0

;PUBLIC	   SAVESTATE
SAVESTATE  DPL      ; storage for extended error info

XNXOPT	   rb      1 ; AL OPTION FOR DOS COMMAND
XNXCMD	   rb      1 ; DOS COMMAND FOR OPEN_A_FILE TO PERFORM
SWITCHAR   rb      1 ; CURRENT SWITCH CHARACTER
EXTPTR	   rw      1 ; POINTER TO FILE EXTENSION
HANDLE	   rw      1 ; CURRENT HANDLE
TRANSADD   rd      1 ; TRANSFER ADDRESS

PARSERR    rb      1
ASMADD	   rb      4
DISADD	   rb      4
DISCNT	   rw      1
ASMSP	   rw      1 ; SP AT ENTRY TO ASM
INDEX	   rw      1
DEFDUMP    rb      4
DEFLEN	   rw      1
REGSAVE    rw      1
SEGSAVE    rw      1
OFFSAVE    rw      1

;Do NOT move this dword variable - it sets up a long call for
;a Create_process_data_block call issued in DEBUG
label CREATE_LONG dword
	   DW	100H
BEGSEG	   rw      1

; The following data areas are destroyed during hex file read
TEMP	   rb      4
label BUFFER byte
BYTCNT	   rb      1
ARG_BUF_INDEX rw      1
OPCODE	   rw      1
AWORD	   rb      1
REGMEM	   rb      1
MIDFLD	   rb      1
MODE	   rb      1
NSEG	   rw      1
BRKCNT	   rw      1 ; Number of breakpoints
TCOUNT	   rw      1 ; Number of steps to trace
ASSEM_CNT  rb      1 ; preserve order of assem_cnt and assem1
ASSEM1	   rb      1
ASSEM2	   rb      1
ASSEM3	   rb      1
ASSEM4	   rb      1
ASSEM5	   rb      1
ASSEM6	   rb      1 ; preserve order of assemx and bytebuf
BYTEBUF    rb      BUFLEN     ; Table used by LIST
BPTAB	   rb      BPLEN     ; Breakpoint table
DIFLG	   rb      1
SIFLG	   rb      1
BXFLG	   rb      1
BPFLG	   rb      1
NEGFLG	   rb      1
NUMFLG	   rb      1 ; ZERO MEANS NO NUMBER SEEN
MEMFLG	   rb      1
REGFLG	   rb      1
MOVFLG	   rb      1
TSTFLG	   rb      1
SEGFLG	   rb      1
LOWNUM	   rw      1
HINUM	   rw      1
F8087	   rb      1
DIRFLG	   rb      1
	   rb      BUFFER+BUFSIZ-$

label DATAEND word

end if
;	   END
