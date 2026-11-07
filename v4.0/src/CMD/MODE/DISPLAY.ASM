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
						;
}
match =Message_Table_LAID_OUT, Message_Table_LAID_OUT
{
    Message_Table_LAID_OUT equ 1
    virtual at 0
      Message_Table Message_Table 0, 0, 0, 0, 0, 0, 0
      sizeof.Message_Table = $ - Message_Table
    end virtual
}
;m
if SEGSEL = S_PRINTF_CODE

;ASSUME CS:PRINTF_CODE, DS:PRINTF_CODE, ES:PRINTF_CODE, SS:PRINTF_CODE


;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  P U B L I C S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;º											  º

;PUBLIC	 initialize_sublists

;º											  º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ  P U B L I C S  ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

;*****************************************************************************
; External Declarations
;*****************************************************************************
;

;EXTRN	 first_sublist:BYTE
;EXTRN	 number_of_sublists:ABS
;EXTRN	 SysDispMsg:Near






;
;***************************************************************************
; Message Structures
;***************************************************************************
;



include 'COMMON.STC'     ;contains the following structure

;sublist_def  STRUC

;	      db  ?  ;Sublist Length, fixed
;	      db  ?  ;Reserved, not used yet		       ;AN000;
;	      dw  ?  ;offset
;sublist_seg  dw  ?  ;segment part of pointer to piece of message
;	      db  ?  ;ID, special end of message format ;AN000;
;	      db  ?  ;flags
;	      db  ?
;	      db  ?
;	      db  ?

;sublist_def  ENDS

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³
;³ INITIALIZE_SUBLISTS
;³ -------------------
;³ A .COM file cannot have references to segments in it at EXE2BIN time so
;³ the segment part of pointers to pieces of messages in sublist blocks must
;³ be done at execution time.  This routine does that for all sublists.
;³
;³
;³ INPUT:
;³
;³
;³
;³
;³
;³
;³
;³ RETURN:
;³
;³
;³  MESSAGES:	 none
;³
;³
;³
;³  REGISTER
;³  USAGE AND
;³  COMVENTIONS:
;³
;³
;³
;³  ASSUMPTIONS:
;³
;³
;³  SIDE EFFECT:
;³
;³
;³   ùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùùù
;³
;³ BEGIN
;³										³
;³ END										³
;³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

initialize_sublists:                       ;AN000;

MOV   CX,Number_of_sublists											 ;AN000;
MOV   SI,first_sublist               ;address first sublist							 ;AN000;
REPEAT_: 													 ;AN000;
   MOV	 [SI+sublist_def.sublist_seg],DS ;set up the segment part of the pointer field in the sublist block	 ;AN000;
   ADD	 SI,sizeof.sublist_def      ;point to next sublist block						 ;AN000;
LOOPNZ	REPEAT_													 ;AN000;
														 ;AN000;
RET
														 ;AN000;
;initialize_sublists  ENDP

;*****************************************************************************
;PRINTF
;*****************************************************************************
;
;Description: Save all registers, set up registers required for SysDispMsg
;	      routine. This information is contained in a message description
;	      table pointed to by the DX register. Call SysDispMsg, then
;	      restore registers. This routine assumes that the only time an
;	      error will be returned is if an extended error message was
;	      requested, so it will ignore error returns
;
;Called Procedures: sysdispmsg
;
;Change History:    Created	   4/22/87	   MT
;
;Input:    ES:DX = pointer to message description
;
;Output:   None
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

;Public	PRINTF
PRINTF:                  ;				     ;AN000;

;	push	ax
						;Save registers 		;AN000;
	push	bx				; "  "    "  "                  ;AN000;
	push	cx				; "  "    "  "                  ;AN000;
	push	dx				; "  "    "  "                  ;AN000;
	push	si				; "  "    "  "                  ;AN000;
	push	di				; "  "    "  "                  ;AN000;
	mov	di,dx				;Change pointer to table	;AN000;
	mov	ax,[di+Message_Table.Entry1] ;Message number		  ;AN000;
	mov	bx,[di+Message_Table.Entry2] ;Handle			  ;AN000;
	mov	si,[di+Message_Table.Entry3] ;Sublist			  ;AN000;
	mov	cx,[di+Message_Table.Entry4] ;Count			  ;AN000;
	mov	dh,[di+Message_Table.Entry5] ;Class			  ;AN000;
	mov	dl,[di+Message_Table.Entry6] ;Function			  ;AN000;
	mov	di,[di+Message_Table.Entry7] ;Input			  ;AN000;
	call	SYSDISPMSG			;Display the message		;AN000;
	pop	di				;Restore registers		;AN000;
	pop	si				; "  "    "  "                  ;AN000;
	pop	dx				; "  "    "  "                  ;AN000;
	pop	cx				; "  "    "  "                  ;AN000;
	pop	bx				; "  "    "  "                  ;AN000;
;	pop	ax				; "  "    "  "                  ;AN000;
	ret					;All done			;AN000;

;PRINTF	ENDP			 ;				 ;AN000;

end if

;	end
