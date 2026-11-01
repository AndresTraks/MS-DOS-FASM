STRUC Message_Table Entry1_=0, Entry2_=0, Entry3_=0, Entry4_=0, Entry5_=0, Entry6_=0, Entry7_=0
{
						;
.Entry1	dw	Entry1_ ;				;AN000;
.Entry2	dw	Entry2_ ;				;AN000;
.Entry3	dw	Entry3_ ;				;AN000;
.Entry4	dw	Entry4_ ;				;AN000;
.Entry5	db	Entry5_ ;				;AN000;
.Entry6	db	Entry6_ ;				;AN000;
.Entry7	dw	Entry7_ ;				;AN000;
}
match =Message_Table_LAID_OUT, Message_Table_LAID_OUT
{
    Message_Table_LAID_OUT equ 1
    virtual at 0
      Message_Table Message_Table
      sizeof.Message_Table = $ - Message_Table
    end virtual
}
;
page	,132				; ;AN000;bgb
;;*****************************************************************************
; Include files
;*****************************************************************************
;
.xlist
	include 'PATHMAC.INC'     ;an028;bgb
	include 'RECSEG.INC' ;AN000;bgb
	include 'DOSSYM.INC'
	include 'SYSMSG.INC'
	include 'RECEQU.INC'
	include 'RECMSG.INC'
.list
;
;*****************************************************************************
; external data
;*****************************************************************************
if SEGSEL = S_DATA;AC000;bgb
;	EXTRN	command_line_buffer:byte					;an031;bgb
;	extrn	DrvLet1:Byte		;AN000;bgb
;	extrn	DrvLet:Byte	       ;AN000;bgb
;	extrn	rec_num:word	       ;AN000;bgb
;	Extrn	Drive_Letter_Msg:Byte	;AN000;BGB
;	extrn	fname_buffer:byte	;AN000;BGB
;	EXTRN	x_value_lo:WORD 	;AN000;bgb	   ; AC000;SM
;	EXTRN	x_value_hi:WORD 	;AN000;bgb	   ; AC000;SM
;	EXTRN	y_value_lo:WORD 	;AN000;bgb	   ; AC000;SM
;	EXTRN	y_value_hi:WORD 	;AN000;bgb	   ; AC000;SM
;	extrn	DriveLetter:Byte

;*****************************************************************************
; Message Services
;*****************************************************************************
.xlist
MSG_UTILNAME  <RECOVER>
MSG_SERVICES	<MSGDATA>
end if


;
;***************************************************************************
; Message Structures
;***************************************************************************
;
if SEGSEL = S_CODE

pathlabl	msgret								;an028;bgb
MSG_SERVICES	<NEARmsg>
MSG_SERVICES	<LOADmsg>
MSG_SERVICES	<DISPLAYmsg,CHARmsg,NUMmsg>					;an029;bgb
pathlabl	msgret								;an028;bgb
MSG_SERVICES	<RECOVER.CLA,RECOVER.CL1,RECOVER.CL2,RECOVER.CTL>
.list
;
;*****************************************************************************
; Public Routines
;*****************************************************************************
;	Public	SysDispMsg
;	Public	SysLoadMsg
;	Public	Display_Interface

;*****************************************************************************
;Routine name&gml Display_Interface
;*****************************************************************************
;
;DescriptioN&gml Save all registers, set up registers required for SysDispMsg
;	      routine. This information is contained in a message description
;	      table pointed to by the DX register. Call SysDispMsg, then
;	      restore registers. This routine assumes that the only time an
;	      error will be returned is if an extended error message was
;	      requested, so it will ignore error returns
;
;Called Procedures: Message (macro)
;
;Change History&gml Created	   4/22/87	   MT
;
;Input&gml ES&gmlDX = pointer to message description
;
;Output&gml None
;
;Psuedocode
;----------
;
;	Save all registers
;	Setup registers for SysDispMsg from Message Description Tables
;	CALL SysDispMsg
;	Restore registers
;	ret
;*****************************************************************************

Display_Interface:         ;				;AN000;

	 push	 ds				 ;				 ;AN000;
	 push	 ax				 ;Save registers		 ;AN000;
	 push	 bx				 ; "  "    "  "                  ;AN000;
	 push	 cx				 ; "  "    "  "                  ;AN000;
	 push	 dx				 ; "  "    "  "                  ;AN000;
	 push	 si				 ; "  "    "  "                  ;AN000;
	 push	 di				 ; "  "    "  "                  ;AN000;
	 mov	 di,dx				 ;Change pointer to table	 ;AN000;
	 mov	 dx,DG_				 ;Point to data segment
	 mov	 ds,dx				 ;
	 mov	 ax,[di+Message_Table.Entry1] ;Message number		 ;AN000;
	 mov	 bx,[di+Message_Table.Entry2] ;Handle			 ;AN000;
	 mov	 si,[di+Message_Table.Entry3] ;Sublist			 ;AN000;
	 mov	 cx,[di+Message_Table.Entry4] ;Count 			 ;AN000;
	 mov	 dh,[di+Message_Table.Entry5] ;Class 			 ;AN000;
	 mov	 dl,[di+Message_Table.Entry6] ;Function			 ;AN000;
	 mov	 di,[di+Message_Table.Entry7] ;Input 			 ;AN000;
	 call	 SYSDISPMSG			 ;Display the message		 ;AN000;
	 pop	 di				 ;Restore registers		 ;AN000;
	 pop	 si				 ; "  "    "  "                  ;AN000;
	 pop	 dx				 ; "  "    "  "                  ;AN000;
	 pop	 cx				 ; "  "    "  "                  ;AN000;
	 pop	 bx				 ; "  "    "  "                  ;AN000;
	 pop	 ax				 ; "  "    "  "                  ;AN000;
	 pop	 ds				 ;				 ;AN000;
	 ret					 ;All done			 ;AN000;
;Display_Interface      endp			;				;AN000;

include 'MSGDCL.INC'

end if
;	end


;code	 segment public PARA 'CODE'      ;AC000;bgb
;code	 ends
;
;const	 segment public para		 ;AC000;bgb
;const	 ends
;
;cstack  segment stack word 'stack'
;cstack  ends
;
;
;data	 segment public para 'DATA'      ;AC000;bgb
;data	 ends
;
;DG_	 group	 code,const,data,cstack
;
;code	 segment public para 'code'      ;AC000;bgb
;code	 ends
;	 assume  cs:DG_,ds:DG_,es:DG_,ss:cstack
;
;
;;;;;;;;;;code	  segment PUBLIC para 'CODE'
;;;;;;;;;;;;;code    ends
