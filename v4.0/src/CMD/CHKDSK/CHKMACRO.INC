
macro BREAK subtitle
{
	SUBTTL	subtitle
	PAGE
}


;
;******************************************************************************
; Message Macro Definitions
;******************************************************************************
;

;      EXTRN Display_Interface:near


;-----------------------------------------------------------------------------

macro Message Message_Name
{
						;
	mov	dx,Message_Name        ;				;AN000;
	call	Display_Interface		;				;AN000;
						;
} ;				;AN000;

;-----------------------------------------------------------------------------

macro Parse_Message 
{

						;
	push	ds
	mov	dx,DG_
	mov	ds,dx
	mov	word [Parse_Error_Msg],ax   ;				;AN000;
	mov	dx,Parse_Error_Msg        ;				;AN000;
	call	Display_Interface		;				;AN000;
	pop	ds				;
} ;				;AN000;

;-----------------------------------------------------------------------------

macro Extended_Message 
{
						;

	push	ds
	mov	dx,DG_
	mov	ds,dx
	mov	word [Extended_Error_Msg],ax     ;				  ;AN000;
	mov	dx,Extended_Error_Msg           ;				   ;AN000;
	call	Display_Interface		;				;AN000;
	pop	ds
} ;				;AN000;
;
;*****************************************************************************
; General Macro's
;*****************************************************************************
;

macro Procedure Proc_Name,Seg_Name
{
						;
;Public	Proc_Name				;				;AN000;
Proc_Name:           ;				;AN000;

} ;				;AN000;
;-----------------------------------------------------------------------------

macro DOS_Call Function
{
						;
	mov	ah,Function			;				;AN000;
	int	21h				;				;AN000;
						;
} ;				;AN000;

;-----------------------------------------------------------------------------

macro Popff 
{

;Assume	cs:DG_

	jmp	$+3
	iret
	push	cs
	call	$-2

;Assume	cs:code

}

;-----------------------------------------------------------------------------

macro Set_Data_Segment 
{

	push	ax
	mov	ax,DG_				;Point to data segment
	mov	ds,ax				;
	push	ds
	pop	es
	pop	ax

	.LALL
;	assume	ds:DG_,es:DG_
	.XALL
}

