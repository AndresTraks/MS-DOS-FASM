






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
        mov     dx,Message_Name            ;                               ;AN000;
        call    Display_Interface               ;                               ;AN000;
} ;                               ;AN000;

;-----------------------------------------------------------------------------

macro Parse_Message 
{

                                                ;
        push    ds
        mov     dx,data_
        mov     ds,dx
        mov     word [Parse_Error_Msg],ax       ;                               ;AN000;
        mov     dx,Parse_Error_Msg              ;                               ;AN000;
        call    Display_Interface               ;                               ;AN000;
        pop     ds                              ;
} ;                               ;AN000;

;-----------------------------------------------------------------------------

macro Extended_Message 
{
                                                ;

        push    ds
        mov     dx,data_
        mov     ds,dx
        mov     word [Extended_Error_Msg],ax         ;                               ;AN000;
        mov     dx,Extended_Error_Msg           ;                               ;AN000;
        call    Display_Interface               ;                               ;AN000;
        pop     ds
} ;                               ;AN000;

;
;*****************************************************************************
; General Macro's
;*****************************************************************************
;

macro Procedure Proc_Name
{

;Public  Proc_Name
Proc_Name:

}
;-----------------------------------------------------------------------------

macro DOS_Call Function
{

        mov     ah,Function
        int     21h

}
;-----------------------------------------------------------------------------

macro Popff 
{

        jmp     $+3
        iret
        push    cs
        call    $-2

}


;-----------------------------------------------------------------------------

macro Set_Data_Segment 
{

        push    ax
        mov     ax,data_                         ;Point to data segment
        mov     ds,ax                           ;
        push    ds
        pop     es
        pop     ax

;assume  ds:data,es:data

}



