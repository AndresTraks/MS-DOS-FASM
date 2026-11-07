	PAGE	60,132 ;
	TITLE	DEBEMS.SAL - EMS DEBUGGER COMMANDS   PC DOS
;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: DEBEMS.SAL
;
; DESCRIPTIVE NAME: DEBUGGING TOOL
;
; FUNCTION: PROVIDES USERS WITH ACCESS TO RUDIMENTARY EMS FACILITIES.
;
; ENTRY POINT: ANY CALLED ROUTINE
;
; INPUT: NA
;
; EXIT NORMAL: NA
;
; EXIT ERROR: NA
;
; INTERNAL REFERENCES:
;
; EXTERNAL REFERENCES:
;
;	ROUTINE: DEBCOM2 - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBCOM3 - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBASM  - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBUASM - CONTAINS ROUTINES CALLED BY DEBUG
;		 DEBMES  - CONTAINS ROUTINES CALLED BY DEBUG
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK DEBUG+DEBCOM1+DEBCOM2+DEBCOM3+DEBASM+DEBUASM+DEBERR+
;	      DEBCONST+DEBDATA+DEBMES
;
; REVISION HISTORY:
;
;	AN000	VERSION 4.00 - REVISIONS MADE RELATE TO THE FOLLOWING:
;
;				- IMPLEMENT EMS FUNCTIONS	DSM:6/24/87
;
; COPYRIGHT: "MS DOS DEBUG UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;	     "LICENSED MATERIAL - PROPERTY OF Microsoft  "
;
;======================= END OF SPECIFICATIONS ===========================

include 'DOSSYM.INC'
include 'DEBEQU.ASM'


if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_CSTACK
end if

if SEGSEL = S_DATA

;	extrn xm_page:byte			;an000;page count to allocate
;	extrn xm_log:byte			;an000;log. page to map
;	extrn xm_phy:byte			;an000;phy. page to map
;	extrn xm_handle:word			;an000;handle to map
;	extrn xm_handle_ret:word		;an000;handle created

;	extrn xm_page_cnt:word			;an000;page count
;	extrn xm_handle_pages_buf:byte		;an000;holds handles and pages
;	extrn xm_frame:word			;an000;EMS frame value
;	extrn xm_deall_han:word 		;an000;handle to deallocate
;	extrn xm_alloc_pg:word			;an000;pages allocated
;	extrn xm_total_pg:word			;an000;total pages possible
;	extrn xm_han_alloc:word 		;an000;handles allocated
;	extrn xm_han_total:word 		;an000;total handles possible

;	extrn	  xm_han_ret_ptr:word		;an000;prints handle created
;	extrn	  xm_mapped_ptr:word		;an000;prints log/phy pages
;	extrn	  xm_page_seg_ptr:word		;an000;Frame seg status
;	extrn	  xm_deall_ptr:word		;an000;Handle deallocation
;	extrn	  xm_unall_ptr:word		;an000;prints page status
;	extrn	  xm_han_alloc_ptr:word 	;an000;print handle status

;	extrn	  xm_err80_ptr:word		;an000;ems error message
;	extrn	  xm_err83_ptr:word		;an000;ems error message
;	extrn	  xm_err84_ptr:word		;an000;ems error message
;	extrn	  xm_err85_ptr:word		;an000;ems error message
;	extrn	  xm_err86_ptr:word		;an000;ems error message
;	extrn	  xm_err87_ptr:word		;an000;ems error message
;	extrn	  xm_err88_ptr:word		;an000;ems error message
;	extrn	  xm_err89_ptr:word		;an000;ems error message
;	extrn	  xm_err8a_ptr:word		;an000;ems error message
;	extrn	  xm_err8b_ptr:word		;an000;ems error message
;	extrn	  xm_err8d_ptr:word		;an000;ems error message
;	extrn	  xm_err8e_ptr:word		;an000;ems error message
;	extrn	  xm_errff_ptr:word		;an000;ems error message
;	extrn	  xm_err_gen_ptr:word		;an000;ems error message
;	extrn	  xm_parse_err_ptr:word 	;an000;input error message
;	extrn	  xm_status_ptr:word		;an000;prints status of EMS

end if

;DG	GROUP	CODE,CONST,CSTACK,DATA

if SEGSEL = S_CODE
;ASSUME	CS:DG,DS:DG,ES:DG,SS:DG

;	public	  debems			;an000;entry point
;	extrn	  std_printf:near		;an000;message retriever
;	extrn	  gethx:near			;an000;ASCII to bin conversion
;	extrn	  inbuf:near			;an000;input command line
;	extrn	  scanb:near			;an000;scan off blanks
;	extrn	  scanp:near			;an000;scan for parm
;	extrn	  perr:near			;an000;print ^ error
;	extrn	  geteol:near
;	extrn	  crlf:near			;an000;prints a cr,lf

	IF	SYSVER
	end if

DEBEMS: 					;an000;entry to module

	call SCANP				;an000;scan for M or S parm
;	if$  z					;an000;no parms found
	JNZ IF1$$M
	     call XM_PARSE_ERROR		;an000;tell user of error
;	else$					;an000;
	JMP SHORT EN1$$M
IF1$$M:
	     mov  al,[si]			;an000;grab parm
	     cmp  al,"M"			;an000;is it MAP?
;	     if$  e				;an000;yes
	     JNE IF3$$M
		  inc  si			;an000;point to next byte
		  call XM_EMS_MAP		;an000;
;	     else$				;an000;
	     JMP SHORT EN3$$M
IF3$$M:
		  cmp  al,"S"			;an000;is it a status check?
;		  if$  e			;an000;yes
		  JNE IF5$$M
		       inc  si			;an000;point to next byte
		       call XM_EMS_STATUS	;an000;
;		  else$ 			;an000;
		  JMP SHORT EN5$$M
IF5$$M:
		       cmp  al,"D"		;an000;Deallocate pages?
;		       if$  e			;an000;yes
		       JNE IF7$$M
			    inc   si		;an000;point to next byte
			    call  XM_EMS_DEALL	;an000;
;		       else$			;an000;
		       JMP SHORT EN7$$M
IF7$$M:
			    cmp  al,"A" 	;an000;Allocate pages?
;			    if$  e		;an000;yes
			    JNE IF9$$M
				 inc  si	;an000;point to next byte
				 call XM_EMS_ALLOC    ;an000;
;			    else$		;an000;
			    JMP SHORT EN9$$M
IF9$$M:
				call GETEOL	;an000;check out parm
;			    endif$		;an000;
EN9$$M:
;		       endif$			;an000;
EN7$$M:
;		  endif$			;an000;
EN5$$M:
;	    endif$				;an000;
EN3$$M:
;	endif$					;an000;
EN1$$M:

	ret					;an000;return to caller



;=========================================================================
; XM_EMS_ALLOC	  :    This function will provide the user the
;		       capability to set and change EMS logical and
;		       physical pages within page frame 0.
;
;	Inputs:   none
;
;	Outputs:  EMS page frames set or altered
;
;	Date:	  6/24/87
;=========================================================================

XM_EMS_ALLOC:            ;an000;XM functions

	call XM_GET_MAN_STATUS			;an000;see if EMS active
;	if$  nc 				;an000;EMS active
	JC IF16$$M
	     call XM_PAGE_PROMPT		;an000;get pages to allocate
	     call XM_GET_HAN_ALLOC		;an000;allocate pages
	     mov  [xm_handle_ret],dx ;an000;save handle returned
;	     if$  z				;an000;good return
	     JNZ IF17$$M
		  pushf 			;an000;save our flags
		  call XM_DISP1 		;an000;tell user results
		  popf				;an000;restore our flags
;	     else$				;an000;
	     JMP SHORT EN17$$M
IF17$$M:
		  call XM_ERROR 		;an000;print error message
;	     endif$				;an000;
EN17$$M:
;	else$					;an000;EMS not active
	JMP SHORT EN16$$M
IF16$$M:
	     call XM_ERROR			;an000;say why not active
;	endif$					;an000;
EN16$$M:

	ret					;an000;return to caller

;XM_EMS_ALLOC	  endp				;an000;


;=========================================================================
; XM_EMS_MAP	  :    This function will provide the user the
;		       capability to set and change EMS logical and
;		       physical pages within page frame 0.
;
;	Inputs:   none
;
;	Outputs:  EMS page frames set or altered
;
;	Date:	  6/24/87
;=========================================================================

XM_EMS_MAP:            ;an000;XM functions

	call XM_GET_MAN_STATUS			;an000;see if EMS active
;	if$  nc 				;an000;EMS active
	JC IF22$$M
	     call XM_LOG_PROMPT 		;an000;get logical page
	     call XM_PHY_PROMPT 		;an000;get physical page
	     call XM_HAN_PROMPT 		;an000;get handle
	     call XM_MAP_MEMORY 		;an000;map the page
;	     if$  z				;an000;good return
	     JNZ IF23$$M
		  pushf 			;an000;save our flags
		  call XM_DISP2 		;an000;tell user results
		  popf				;an000;restore our flags
;	     else$				;an000;
	     JMP SHORT EN23$$M
IF23$$M:
		   call XM_ERROR		;an000;tell error
;	     endif$				;an000;
EN23$$M:
;	else$					;an000;EMS not active
	JMP SHORT EN22$$M
IF22$$M:
	     call XM_ERROR			;an000;say why not active
;	endif$					;an000;
EN22$$M:

	ret					;an000;return to caller

;XM_EMS_MAP	  endp				;an000;

;=========================================================================
; XM_GET_MAN_STATUS :  This routine will determine if EMS is active for
;		       this session.
;
;	Called Procs:  none
;
;	Inputs:        none
;
;	Outputs:       Z  - no error
;		       NZ - error
;		       AH - error message number
;
;	Date:	       6/24/87
;=========================================================================

XM_GET_MAN_STATUS:            ;an000;see if EMS active

	push	ds				;an000;save ds - we stomp it
	mov	ax,00h				;an000;set ax to 0
	mov	ds,ax				;an000;set ds to 0
	cmp	word [ds:067h*4+0],0     ;an000;see if int 67h is there
	pop	ds				;an000;restore ds
;	if$	e				;an000;EMS not installed
	JNE IF28$$M
		stc				;an000;flag no ems
		mov	ah,XM_NOT_INST		;an000;signal EMS not installed
;	else$					;an000;
	JMP SHORT EN28$$M
IF28$$M:
		call	XM_INSTALL_CHECK	;an000;see if EMS installed
;		if$	z			;AN000;IS EMS INSTALLED
		JNZ IF30$$M
			clc			;AN000;EMS INSTALLED - FLAG IT
;		else$				;an000;
		JMP SHORT EN30$$M
IF30$$M:
			stc			;AN000;FLAG EMS NOT INSTALLED
			mov  ah,XM_NOT_INST	;an000;signal EMS not installed
;		endif$				;an000;
EN30$$M:
;	endif$					;an000;
EN28$$M:

	RET					;AN000;RETURN TO CALLER


;XM_GET_MAN_STATUS endp				;an000;



;=========================================================================
; XM_PAGE_PROMPT :     This routine prompts the user for the number of
;		       pages to be allocated, if he desires a new handle.
;		       This routine will determine whether or not the other
;		       prompt messages will be displayed.
;
;	Called Procs:  STD_PRINTF
;		       XM_PARSE
;
;	Inputs:        none
;
;	Outputs:       XM_PAGE_FLAG
;		       XM_PAGE_BUF
;		       XM_PAGE
;
;	Date:	       6/24/87
;=========================================================================

XM_PAGE_PROMPT:              ;an000;prompt user for number
						;      of pages to allocate
	call SCANB				;an000;see if parm entered
;	if$  nz 				;an000;if parm found
	JZ IF34$$M
	     mov  cx,02 			;an000;bytes to parse
	     call GETHX 			;an000;get hex value
;	     if$  c				;an000;no an error occurred
	     JNC IF35$$M
		  call PERR			;an000;display ^ error
;	     else$				;an000;
	     JMP SHORT EN35$$M
IF35$$M:
		  mov  [xm_page],dl ;an000;save page count
;	     endif$				;an000;
EN35$$M:
;	else$					;an000;
	JMP SHORT EN34$$M
IF34$$M:
	     call PERR				;an000;display ^ error
;	endif$					;an000;
EN34$$M:

	ret					;an000;return to caller

;XM_PAGE_PROMPT	  endp				;an000;


;=========================================================================
; XM_LOG_PROMPT :      This routine prompts the user for the number of the
;		       logical page that is to be mapped in EMS.  This
;		       routine will not be performed if a page count
;		       was specified.
;
;	Called Procs:  STD_PRINTF
;		       XM_PARSE
;
;	Inputs:        none
;
;	Outputs:       XM_LOG_BUF
;		       XM_LOG
;
;	Date:	       6/24/87
;=========================================================================


XM_LOG_PROMPT:              ;an000;prompt user for the
						;      logical page to be
						;      mapped
	call SCANB				;an000;see if parm entered
;	if$  nz 				;an000;parm entered
	JZ IF40$$M
	     mov  cx,02 			;an000;bytes to parse
	     call GETHX 			;an000;get hex value
;	     if$  c				;an000;no an error occurred
	     JNC IF41$$M
		  call PERR			;an000;display ^ error
;	     else$				;an000;
	     JMP SHORT EN41$$M
IF41$$M:
		  mov  [xm_log],dl ;an000;save logical page
;	     endif$				;an000;
EN41$$M:
;	else$					;an000;
	JMP SHORT EN40$$M
IF40$$M:
	     call PERR				;an000;display ^ error
;	endif$					;an000;
EN40$$M:

	ret					;an000;return to caller

;XM_LOG_PROMPT	  endp				;an000;


;=========================================================================
; XM_PHY_PROMPT :      This routine prompts the user for the number of the
;		       physical page that is to be mapped in EMS.  This
;		       routine will not be performed if a page count
;		       was specified.
;
;	Called Procs:  STD_PRINTF
;		       XM_PARSE
;
;	Inputs:        none
;
;	Outputs:       XM_PHY_BUF
;		       XM_PHY
;
;	Date:	       6/24/87
;=========================================================================


XM_PHY_PROMPT:              ;an000;prompt user for the
						;      physical page to be
						;      mapped
	call SCANB				;an000;see if parm entered
;	if$  nz 				;an000;parm found
	JZ IF46$$M
	     mov  cx,02 			;an000;bytes to parse
	     call GETHX 			;an000;get hex value
;	     if$  c				;an000;no an error occurred
	     JNC IF47$$M
		  call PERR			;an000;display ^ error
;	     else$				;an000;
	     JMP SHORT EN47$$M
IF47$$M:
		  mov  [xm_phy],dl ;an000;save logical page
;	     endif$				;an000;
EN47$$M:
;	else$					;an000;
	JMP SHORT EN46$$M
IF46$$M:
	     call PERR				;an000;
;	endif$					;an000;
EN46$$M:

	ret					;an000;return to caller

;XM_PHY_PROMPT	  endp				;an000;


;=========================================================================
; XM_HAN_PROMPT :      This routine prompts the user for the number of the
;		       handle that the mapping is to occur on. This
;		       routine will not be performed if a page count
;		       was specified.
;
;	Called Procs:  STD_PRINTF
;		       XM_PARSE
;
;	Inputs:        none
;
;	Outputs:       XM_HAN_BUF
;		       XM_HAN
;
;	Date:	       6/24/87
;=========================================================================


XM_HAN_PROMPT:              ;an000;prompt user for the
						;      handle to be mapped
	call SCANB				;an000;see if parm entered
;	if$  nz 				;an000;prompt found
	JZ IF52$$M
	     mov  cx,04 			;an000;bytes to parse
	     call GETHX 			;an000;get hex value
;	     if$  c				;an000;no an error occurred
	     JNC IF53$$M
		  call PERR			;an000;display ^ error
;	     else$				;an000;
	     JMP SHORT EN53$$M
IF53$$M:
		  mov  [xm_handle],dx ;an000;save logical page
;	     endif$				;an000;
EN53$$M:
;	else$					;an000;
	JMP SHORT EN52$$M
IF52$$M:
	     call PERR				;an000;display ^ error
;	endif$					;an000;
EN52$$M:

	ret					;an000;return to caller

;XM_HAN_PROMPT	  endp				;an000;



;=========================================================================
; XM_GET_HAN_ALLOC :   This routine will get a handle and allocate the
;		       requested number of pages to that handle.
;
;	Called Procs:  none
;
;	Inputs:        XM_PAGE - number of pages to allocate to handle
;
;	Outputs:       Z  - no error
;		       NZ - error
;		       DX - handle allocated
;
;	Date:	       6/24/87
;=========================================================================

XM_GET_HAN_ALLOC:             ;an000;create handle and alloc.
						;      requested pages.
	push bx 				;an000;save regs.
	mov  ah,EMS_HAN_ALLOC			;an000;function 43h
	xor  bh,bh				;an000;clear byte
	mov  bl,[xm_page] ;an000;number of pages to
						;      allocate
	int  67h				;an000;call EMS
	or   ah,ah				;an000;was there an error
	pop  bx 				;an000;restore regs.

	ret					;an000;return to caller

;XM_GET_HAN_ALLOC  endp				;an000;

;=========================================================================
; XM_MAP_MEMORY :      This routine will map the requested logical page
;		       to the requested physical page in EMS.
;
;	Called Procs:  none
;
;	Inputs:        XM_PHY - physical page to map to
;		       XM_HAN - logical page to map
;
;	Outputs:       Z  - no error
;		       NZ - error
;		       page mapped
;
;	Date:	       6/24/87
;=========================================================================

XM_MAP_MEMORY:              ;an000;map a logical page to
						;      a physical page in
						;      EMS
	push bx 				;an000;save regs.
	push dx 				;an000;
	mov  ah,EMS_MAP_MEMORY			;an000;function 44h
	mov  al,[xm_phy] ;an000;physical page to map
	xor  bh,bh				;an000;zero byte
	mov  bl,[xm_log] ;an000;logical page to map
	mov  dx,[xm_handle] ;an000;handle to map page to
	int  67h				;an000;call EMS
	or   ah,ah				;an000;was there an error
	pop  dx 				;an000;restore regs.
	pop  bx 				;an000;

	ret					;an000;return to caller

;XM_MAP_MEMORY	  endp				;an000;


;=========================================================================
; XM_DISP1 :	       This routine displays the current page frame and
;		       the handle created as a result of the allocate pages.
;
;	Called Procs:  STD_PRINTF
;
;	Inputs:        XM_FRAME_SEG	- page frame segment
;		       XM_HANDLE_RET	- created handle
;		       XM_PG_FRAME_PTR	- pointer to message
;		       XM_HAN_RET_PTR	- pointer to message
;
;	Outputs:       "Page Frame Segment : %1",0d,0a
;		       "Handle Created     : %1",0d,0a
;
;	Date:	       6/24/87
;=========================================================================

XM_DISP1:              ;an000;display messages

	mov  dx,xm_han_ret_ptr        ;an000;"Handle Created    : "
	call STD_PRINTF 			;an000;call message ret.

	ret					;an000;return to caller

;XM_DISP1	  endp				;an000;


;=========================================================================
; XM_DISP2 :	       This routine displays the logical page mapped and
;		       the physical page it was mapped to.
;
;	Called Procs:  STD_PRINTF
;
;	Inputs:        XM_MAPPED_PTR	- pointer to message
;		       XM_LOG		- logical page mapped
;		       XM_PHY		- physical page mapped
;
;	Outputs:       "Logical page %1 mapped to physical page %2",0d0a
;
;	Date:	       6/24/87
;=========================================================================

XM_DISP2:              ;an000;display messages

	mov  dx,xm_mapped_ptr         ;an000;"Logical page %1 mapped
						;	to physical page %2"
	call STD_PRINTF 			;an000;call message ret.

	ret					;an000;return to caller

;XM_DISP2	  endp				;an000;

;=========================================================================
; XM_ERROR:	  This routine will determine what error we have by
;		  querying the result in the AH register.  It will then
;		  report the error to the user through STD_PRINTF
;
;	Called Procs:  STD_PRINTF
;
;	Inputs:        AH - error code
;
;	Outputs:       error message
;
;	Date:	       6/24/87
;=========================================================================

XM_ERROR:              ;an000;error message printer

	cmp  ah,XM_ERR80			;an000;error message
;	if$  e					;an000;found message
	JNE IF58$$M
	     mov  dx,xm_err80_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF58$$M:

	cmp  ah,XM_ERR83			;an000;error message
;	if$  e					;an000;found message
	JNE IF60$$M
	     mov  dx,xm_err83_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF60$$M:

	cmp  ah,XM_ERR84			;an000;error message
;	if$  e					;an000;found message
	JNE IF62$$M
	     mov  dx,xm_err84_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF62$$M:

	cmp  ah,XM_ERR85			;an000;error message
;	if$  e					;an000;found message
	JNE IF64$$M
	     mov  dx,xm_err85_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF64$$M:


	cmp  ah,XM_ERR86			;an000;error message
;	if$  e					;an000;found message
	JNE IF66$$M
	     mov  dx,xm_err86_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF66$$M:

	cmp  ah,XM_ERR87			;an000;error message
;	if$  e					;an000;found message
	JNE IF68$$M
	     mov  dx,xm_err87_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF68$$M:

	cmp  ah,XM_ERR88			;an000;error message
;	if$  e					;an000;found message
	JNE IF70$$M
	     mov  dx,xm_err88_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF70$$M:

	cmp  ah,XM_ERR89			;an000;error message
;	if$  e					;an000;found message
	JNE IF72$$M
	     mov  dx,xm_err89_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF72$$M:

	cmp  ah,XM_ERR8A			;an000;error message
;	if$  e					;an000;found message
	JNE IF74$$M
	     mov  dx,xm_err8a_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF74$$M:

	cmp  ah,XM_ERR8B			;an000;error message
;	if$  e					;an000;found message
	JNE IF76$$M
	     mov  dx,xm_err8b_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF76$$M:

	cmp  ah,XM_ERR8D			;an000;error message
;	if$  e					;an000;found message
	JNE IF78$$M
	     mov  dx,xm_err8d_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF78$$M:

	cmp  ah,XM_ERR8E			;an000;error message
;	if$  e					;an000;found message
	JNE IF80$$M
	     mov  dx,xm_err8e_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$
IF80$$M:

	cmp  ah,XM_NOT_INST			;an000;EMS not installed
;	if$  e					;an000;found message
	JNE IF82$$M
	     mov  dx,xm_errff_ptr        ;an000;point to message
	     jmp  XM_ERROR_CONT 		;an000;print error
;	endif$					;an000;
IF82$$M:

	mov  dx,xm_err_gen_ptr        ;an000;general error message

XM_ERROR_CONT:

	call STD_PRINTF 			;an000;call message ret.

	ret					;an000;return to caller

;XM_ERROR	  endp				;an000;

;=========================================================================
; XM_PARSE_ERROR :     This routine will display that an error has occurred
;		       on the input of the requested data.
;
;	Called Procs:  STD_PRINTF
;
;	Inputs:        XM_PARSE_ERR_PTR - error message
;
;	Outputs:       "Invalid value for parameter",0d,0a
;
;	Date:	       6/24/87
;=========================================================================

XM_PARSE_ERROR:              ;an000;input error message

	mov  dx,xm_parse_err_ptr        ;an000;error message
	call STD_PRINTF 			;an000;call message ret.
	ret					;an000;return to caller

;XM_PARSE_ERROR	  endp				;an000;



;=========================================================================
; XM_EMS_STATUS   :    This function will provide the user with
;		       a report the the current status of EMS.
;
;	Inputs:   none
;
;	Outputs:  EMS page frames set or altered
;
;	Date:	  6/24/87
;=========================================================================

XM_EMS_STATUS:            ;an000;XM functions

	call XM_GET_MAN_STATUS			;an000;see if EMS active
;	if$  nc 				;an000;EMS active
	JC IF84$$M
	     call XM_CURR_STATUS		;an000;current status of EMS
;	else$					;an000;EMS not active
	JMP SHORT EN84$$M
IF84$$M:
	     call XM_ERROR			;an000;say why not active
;	endif$					;an000;
EN84$$M:

	ret					;an000;return to caller

;XM_EMS_STATUS	  endp				;an000;


;=========================================================================
; XM_CURR_STATUS :	This routine will display the current status of
;			all active EMS handles.
;
;	Inputs	 :	none
;
;	Outputs  :	Current status of all active EMS handles
;			"Handle %1 has %2 pages allocated"
;
;			Physical page with it associated frame segment
;			"Physical page %1 = Frame segment %2"
;
;	Date:	       8/05/86
;=========================================================================

XM_CURR_STATUS:            ;an000;current EMS status

	mov  ah,EMS_HANDLE_PAGES		;an000;get handle pages
	mov  di,xm_handle_pages_buf        ;an000;point to the buffer
	int  67h				;an000;

	or   ah,ah				;an000;see if an error occurred
;	if$  z					;an000;no error
	JNZ IF87$$M
;	     do$				;an000;do while data in buffer
DO88$$M:
		  cmp  bx,0			;an000;end of buffer?
;		  leave$  e			;an000;yes
		  JE EN88$$M
		       mov  ax,word [es:di]     ;an000;page handle
		       mov  [xm_handle_ret],ax ;an000;save in var
		       mov  ax,word [es:di+02]    ;an000;page count
		       mov  [xm_page_cnt],ax ;an000;save in var
		       mov  dx,xm_status_ptr        ;an000;point to message
		       call STD_PRINTF		;an000;print it
		       add  di,04h		;an000;next record
		       dec  bx			;an000;decrement counter
;	     enddo$				;an000;
	     JMP SHORT DO88$$M
EN88$$M:

	     call  CRLF 			;an000;place a blank line
						;      between reports

	     call  XM_FRAME_BUFFER		;an000;get frame buffer
						;ES:DI points to frame buffer
;	     do$				;an000;while cx not = 0
DO91$$M:
		  cmp  cx,00			;an000;at end?
;		  leave$ e			;an000;yes
		  JE EN91$$M
		       call  XM_GET_FRAME_SEG	;an000;obtain page and seg
		       mov   dx,xm_page_seg_ptr         ;an000;message
		       call  STD_PRINTF 	;an000;print it
		       dec   cx 		;an000;decrease counter
		       add   di,04		;an000;adjust pointer
;	     enddo$				;an000;
	     JMP SHORT DO91$$M
EN91$$M:

	     call  XM_UNALL_COUNT		;an000;display page status
	     call  XM_HANDLE_COUNT		;an000;display handle status

;	else$
	JMP SHORT EN87$$M
IF87$$M:
	     call  XM_ERROR			;an000;display the error
;	endif$					;an000;
EN87$$M:
	ret					;an000;

;XM_CURR_STATUS		endp			;an000;

;=========================================================================
; XM_UNALL_COUNT :	This routine generates a line of the status report
;			displaying the number of pages allocated out of
;			the total possible
;
;	Inputs	 :	none
;
;	Outputs  :	Current status of allocated pages
;			"%1 of a total %2 EMS pages have been allocated"
;
;	Date:	       8/05/86
;=========================================================================

XM_UNALL_COUNT:            ;an000;

	mov	ah,EMS_UNALL_PG_CNT		;an000;see how many pages
						;      remaining
	int	67h				;an000;
	or	ah,ah				;an000;see if error

;	if$	z				;an000;no error
	JNZ IF96$$M
		push	bx			;an000;save bx
		push	dx			;an000;save dx
		call	CRLF			;an000;
		pop	dx			;an000;restore dx
		pop	bx			;an000;restore bx
		mov	ax,dx			;an000;total page count
		sub	ax,bx			;an000;get pages allocated
		mov	[xm_alloc_pg],ax ;an000;save allocated pages
		mov	[xm_total_pg],dx ;an000;save total page count
		mov	dx,xm_unall_ptr        ;an000;"%1 of a total %2 EMS
						;      pages have been allocated",cr,lf
		call	STD_PRINTF		;an000;print it
;	endif$					;an000;
IF96$$M:

	ret					;an000;

;XM_UNALL_COUNT		endp			;an000;


;=========================================================================
; XM_HANDLE_COUNT:	This routine generates a line of the status report
;			displaying the number of handles allocated out of
;			the total possible.
;
;	Inputs	 :	none
;
;	Outputs  :	Current status of allocated pages
;			"%1 of a total %2 EMS handles have been allocated"
;
;	Date:	       8/05/86
;=========================================================================

XM_HANDLE_COUNT:            ;an000;

	mov	ah,EMS_HANDLE_CNT		;an000;see how many handles
						;      possible
	int	67h				;an000;
	or	ah,ah				;an000;see if error

;	if$	z				;an000;no error
	JNZ IF98$$M
		mov	ax,EMS_HANDLE_TOTAL	;an000;total possible handles
		mov	[xm_han_total],ax ;an000;save total page count
		mov	[xm_han_alloc],bx ;an000;save allocated pages
		mov	dx,xm_han_alloc_ptr
						;an000;"%1 of a total %2 EMS
						;      handles have been allocated",cr,lf
		call	STD_PRINTF		;an000;print it
;	endif$					;an000;
IF98$$M:

	ret					;an000;

;XM_HANDLE_COUNT 	endp			;an000;


;=========================================================================
; XM_FRAME_SEG	 :	This routine accesses the vector created by
;			function 58h, int 67h.	It obtains a physical
;			page of EMS and its segment from this vector
;
;	Inputs	 :	ES:DI - points to frame buffer
;
;	Outputs  :	XM_PHY - a physical page in EMS
;			XM_FRAME - segment corresponding to the physical page
;
;	Date:	       8/05/86
;=========================================================================


XM_GET_FRAME_SEG:           ;an000;find the frame segment

	mov	al,byte [es:di+2]      ;an000;get physical page
	mov	[xm_phy],al ;an000;place in print var
	mov	ax,word [es:di]      ;an000;get frame segment
	mov	[xm_frame],ax ;an000;place in print var

	ret					;an000;

;XM_GET_FRAME_SEG	endp			;an000;

;=========================================================================
; XM_INSTALL_CHECK:	This routine performs function 51h, int 67h to
;			determine if EMS is indeed active.
;
;	Inputs	 :	XM_FRAME_BUFFER - used to receive physical page
;					  and segment data for EMS.
;
;	Outputs  :	XM_FRAME_BUFFER - buffer holds physical page
;					  and segment data for EMS.
;
;	Date:	       8/05/86
;=========================================================================

XM_INSTALL_CHECK:           ;an000;see if EMS installed

	MOV	AH,EMS_GET_MAN_STAT		;AN000;GET EMS STATUS
	XOR	AL,AL				;an000;clear low byte
	INT	67h				;an000;
	OR	AH,AH				;an000;check for error
;	IF$	Z				;an000;no error
	JNZ IF100$$M
		MOV	AH,EMS_VERSION		;an000;get version number
		INT	67h			;an000;
		CMP	AL,EMS_LIM_40		;an000;LIM 4.0 ?
;		IF$	AE			;an000;4.0 or greater
		JNAE IF101$$M
			MOV	AH,00h		;an000;set up for flag pass
			OR	AH,AH		;an000;set flag to ZR
;		ELSE$				;an000;below 4.0
		JMP SHORT EN101$$M
IF101$$M:
			MOV	AH,01h		;an000;set up for flag pass
			OR	AH,AH		;an000;set flag to NZ
;		ENDIF$				;an000;
EN101$$M:
;	ENDIF$					;an000;
IF100$$M:

	ret					;an000;

;XM_INSTALL_CHECK	endp			;an000;




;=========================================================================
; XM_EMS_DEALL	:	This routine deallocates handles from EMS.
;
;	Inputs	 :	DX - Handle supplied by XM_DEALL_PROMPT
;
;	Outputs  :	Good return - "Handle %1 deallocated"
;			Bad return  - message describing error
;
;	Date:	       8/05/86
;=========================================================================

XM_EMS_DEALL:            ;an000;deallocate EMS pages

	call XM_GET_MAN_STATUS			;an000;see if EMS installed
;	if$  nc 				;an000;error?
	JC IF105$$M
	     call XM_DEALL_PROMPT		;an000;prompt user for handle
	     mov  ah,EMS_PAGE_DEALL		;an000;function 45h, int 67h
	     int  67h				;an000;

	     or   ah,ah 			;an000;error?
;	     if$  nz				;an000;yes
	     JZ IF106$$M
		  call XM_ERROR 		;an000;say why
;	     else$				;an000;
	     JMP SHORT EN106$$M
IF106$$M:
		  mov  dx,xm_deall_ptr       ;an000;"Handle %1 deallocated"
		  call STD_PRINTF		;an000;print message
;	     endif$				;an000;
EN106$$M:
;	else$					;an000;
	JMP SHORT EN105$$M
IF105$$M:
	     call XM_ERROR			;an000;print type of error
;	endif$					;an000;
EN105$$M:

	ret					;an000;

;XM_EMS_DEALL		endp			;an000;

;=========================================================================
; XM_DEALL_PROMPT :	This routine prompts the user for the handle to be
;			deallocated.  It converts the handle entered to
;			binary and passes it back to the caller in DX.
;
;	Inputs	 :	none
;
;	Outputs  :	DX - Handle to be deallocated.
;
;	Date:	       8/05/86
;=========================================================================

XM_DEALL_PROMPT:            ;an000;prompt user for handle
						;      to deallocate
	call SCANB				;an000;see if parm entered
;	if$  nz 				;an000;parm found
	JZ IF111$$M
	     mov  cx,04 			;an000;bytes to parse
	     call GETHX 			;an000;get hex value
;	     if$  c				;an000;no an error occurred
	     JNC IF112$$M
		  call PERR			;an000;display ^ error
;	     else$				;an000;
	     JMP SHORT EN112$$M
IF112$$M:
		  mov  [xm_deall_han],dx ;an000;save handle to deallocate
;	     endif$				;an000;
EN112$$M:
;	else$					;an000;
	JMP SHORT EN111$$M
IF111$$M:
	     call PERR				;an000;display ^ error
;	endif$					;an000;
EN111$$M:

	ret					;an000;return to caller

;XM_DEALL_PROMPT 	endp			;an000;


;=========================================================================
; XM_FRAME_BUFFER	:	This routine obtains the frame buffer
;				of EMS pages.
;
;	Inputs	:	none
;
;	Outputs :	ES:DI - Pointer to frame array
;			CX    - Number of elements in array
;=========================================================================

XM_FRAME_BUFFER:            ;an000;

	mov	ax,EMS_PG_FRAME 		;an000;get frame buffer
	int	67h				;an000;

	ret					;an000;

;XM_FRAME_BUFFER 	endp			;an000;


end if
;	END	DEBEMS
