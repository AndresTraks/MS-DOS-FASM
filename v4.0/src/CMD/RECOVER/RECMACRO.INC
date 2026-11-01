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
	mov	dx,Message_Name            ; 			      ;AN000;
	call	Display_Interface		;				;AN000;
} ;				;AN000;

;-----------------------------------------------------------------------------

macro Parse_Message 
{

						;
	push	ds				;				;AN000;bgb
	mov	dx,DG_				;				;AN000;bgb
	mov	ds,dx				;				;AN000;bgb
	mov	word [Parse_Error_Msg],ax   ;				;AN000;
	mov	dx,Parse_Error_Msg           ;				   ;AN000;
	call	Display_Interface		;				;AN000;
	pop	ds				;				;AN000;bgb
} ;				;AN000;

;-----------------------------------------------------------------------------

macro Extended_Message 
{
						;

	push	ds				;				;AN000;bgb
	mov	dx,DG_				;				;AN000;bgb
	mov	ds,dx				;				;AN000;bgb
	mov	word [Ext_Error_Msg],ax   ;				;AN000;
	mov	dx,Ext_Error_Msg           ; 			      ;AN000;
	call	Display_Interface		;				;AN000;
	pop	ds				;				;AN000;bgb
} ;				;AN000;

;
;*****************************************************************************
; General Macro's
;*****************************************************************************
;

macro Procedure Proc_Name
{
						;
;Public	Proc_Name				;				;AN000;
Proc_Name:           ;				;AN000;
						;
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

	jmp	$+3
	iret
	push	cs
	call	$-2

}


;-----------------------------------------------------------------------------

macro Set_Data_Segment 
{

	push	ax
	mov	ax,DG_				;Point to data segment
	mov	ds,ax				;
;assume	ds:DG_,es:DG_
	push	ds
	pop	es
	pop	ax


}



