STRUC Message_Table Entry1_=0, Entry2_=0, Entry3_=0, Entry4_=0, Entry5_=0, Entry6_=0, Entry7_=0
{
.Entry1	dw	Entry1_ ;				;an000;bgb;AN000;
.Entry2	dw	Entry2_ ;				;an000;bgb;AN000;
.Entry3	dw	Entry3_ ;				;an000;bgb;AN000;
.Entry4	dw	Entry4_ ;				;an000;bgb;AN000;
.Entry5	db	Entry5_ ;				;an000;bgb;AN000;
.Entry6	db	Entry6_ ;				;an000;bgb;AN000;
.Entry7	dw	Entry7_ ;				;an000;bgb;AN000;
}
match =Message_Table_LAID_OUT, Message_Table_LAID_OUT
{
    Message_Table_LAID_OUT equ 1
    virtual at 0
      Message_Table Message_Table
      sizeof.Message_Table = $ - Message_Table
    end virtual
}
page	,132	;								;an000;bgb
;*****************************************************************************	;an000;bgb
;*****************************************************************************	;an000;bgb
;UTILITY NAME: FORMAT.COM							;an000;bgb
;										;an000;bgb
;MODULE NAME: DISPLAY.ASM							;an000;bgb
;										;an000;bgb
;										;an000;bgb
; Designed:  Mark T.	 							;an000;bgb
;										;an000;bgb
; Change List: AN000 - New code DOS 3.3 spec additions				;an000;bgb
;	       AC000 - Changed code DOS 3.3 spec additions			;an000;bgb
;*****************************************************************************	;an000;bgb
										;an000;bgb
;	EXTRN	command_line_buffer:byte					;an000;bgb;an005;bgb
;*****************************************************************************	;an000;bgb
; Include Files 								;an000;bgb
;*****************************************************************************	;an000;bgb
.xlist										;an000;bgb
include 'PATHMAC.INC'      ;an040;bgb
include 'CHKSEG.INC'      ;an000;bgb
include 'CPMFCB.INC'      ;an000;bgb
include 'CHKEQU.INC'      ;an000;bgb
.list										;an000;bgb
include 'CHKMSG.INC'      ;an000;bgb
.xlist										;an000;bgb
include 'SYSMSG.INC'      ;an000;bgb
.list										;an000;bgb
      ; 									;an000;bgb
if SEGSEL = S_CSTACK;an000;bgb
	db	62 dup ("-Stack!-")      ; (362-80h) is the additional IBM ROM  ;an000;bgb
end if ;an000;bgb
										;an000;bgb
										;an000;bgb
;*****************************************************************************	;an000;bgb
; Message Services								;an000;bgb
;*****************************************************************************	;an000;bgb
MSG_UTILNAME  <CHKDSK>								;an000;bgb
										;an000;bgb
;.xlist 									 ;an000;bgb
if SEGSEL = S_DATA;an000;bgb
MSG_SERVICES	<MSGDATA>							;an000;bgb
end if ;an000;bgb
										;an000;bgb
if SEGSEL = S_CODE;an000;bgb
pathlabl	msgret								;an040;bgb
MSG_SERVICES	<NEARmsg>							;an000;bgb
MSG_SERVICES	<LOADmsg>							;an000;bgb
MSG_SERVICES	<DISPLAYmsg,CHARmsg,NUMmsg,TIMEmsg,DATEmsg>			;an000;bgb
pathlabl	msgret								;an040;bgb
MSG_SERVICES	<CHKDSK.CLA,CHKDSK.CLB,CHKDSK.CLC,CHKDSK.CLD,CHKDSK.CL1,CHKDSK.CL2,CHKDSK.CTL> ;an037;bgb
end if ;an000;bgb
.list										;an000;bgb
										;an000;bgb
;										;an000;bgb
;*****************************************************************************	;an000;bgb
; Public Declarations								;an000;bgb
;*****************************************************************************	;an000;bgb
;	Public	SysLoadMsg							;an000;bgb
;	Public	SysDispMsg							;an000;bgb
										;an000;bgb
										;an000;bgb
;										;an000;bgb
;***************************************************************************	;an000;bgb
; Message Structures								;an000;bgb
;***************************************************************************	;an000;bgb
										;an000;bgb
if SEGSEL = S_CODE;                               ;an000;bgb;AN000;
;*****************************************************************************	;an000;bgb
;Routine name&gml Display_Interface						;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
;DescriptioN&gml Save all registers, set up registers required for SysDispMsg	;an000;bgb
;	      routine. This information is contained in a message description	;an000;bgb
;	      table pointed to by the DX register. Call SysDispMsg, then	;an000;bgb
;	      restore registers. This routine assumes that the only time an	;an000;bgb
;	      error will be returned is if an extended error message was	;an000;bgb
;	      requested, so it will ignore error returns			;an000;bgb
;										;an000;bgb
;Called Procedures: Message (macro)						;an000;bgb
;										;an000;bgb
;Change History&gml Created	   4/22/87	   MT				;an000;bgb
;										;an000;bgb
;Input&gml ES&gmlDX = pointer to message description				;an000;bgb
;										;an000;bgb
;Output&gml None								;an000;bgb
;										;an000;bgb
;Psuedocode									;an000;bgb
;----------									;an000;bgb
;										;an000;bgb
;	Save all registers							;an000;bgb
;	Setup registers for SysDispMsg from Message Description Tables		;an000;bgb
;	CALL SysDispMsg 							;an000;bgb
;	Restore registers							;an000;bgb
;	ret									;an000;bgb
;*****************************************************************************	;an000;bgb
;Public	Display_Interface							;an000;bgb
Display_Interface:         ;				;an000;bgb;AN000;
	push	ds								;an000;bgb
	push	ax								;an000;bgb
	push	bx								;an000;bgb
	push	cx								;an000;bgb
	push	dx								;an000;bgb
	push	si								;an000;bgb
	push	di								;an000;bgb
	mov	di,dx				;Change pointer to table	;an000;bgb;AN000;
	mov	dx,DG_				;Point to group 		;an000;bgb
	mov	ds,dx				;				;an000;bgb
	mov	ax,[di+Message_Table+Message_Table.Entry1] ;Message number 		;an000;bgb;AN000;
	mov	bx,[di+Message_Table+Message_Table.Entry2] ;Handle 			;an000;bgb;AN000;
	mov	si,[di+Message_Table+Message_Table.Entry3] ;Sublist			;an000;bgb;AN000;
	mov	cx,[di+Message_Table+Message_Table.Entry4] ;Count				;an000;bgb;AN000;
	mov	dh,[di+Message_Table+Message_Table.Entry5] ;Class				;an000;bgb;AN000;
	mov	dl,[di+Message_Table+Message_Table.Entry6] ;Function			;an000;bgb;AN000;
	mov	di,[di+Message_Table+Message_Table.Entry7] ;Input				;an000;bgb;AN000;
	call	SYSDISPMSG			;Display the message		;an000;bgb;AN000;
	pop	di								;an000;bgb
	pop	si								;an000;bgb
	pop	dx								;an000;bgb
	pop	cx								;an000;bgb
	pop	bx								;an000;bgb
	pop	ax								;an000;bgb
	pop	ds								;an000;bgb
	ret					;All done			;an000;bgb;AN000;
;Display_Interface      endp			;				;an000;bgb;AN000;
										;an000;bgb
include 'MSGDCL.INC'

end if ;an000;bgb
;	end									;an000;bgb
