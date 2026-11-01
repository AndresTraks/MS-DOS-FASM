






;
;******************************************************************************
; Message Macro Definitions
;******************************************************************************
;

;      EXTRN Display_Interface:near


;-----------------------------------------------------------------------------

macro MESSAGE Message_Name
{
                                                ;
        mov     dx,Message_Name                 ;                               ;AN000;
        call    Display_Interface               ;                               ;AN000;
                                                ;
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

macro Parse_Message 
{


        push    ds                                                              ;AN000;
        mov     dx,DATA_                                                ;AN000;
        mov     ds,dx                                                           ;AN000;
;        ASSUME  DS:DATA                                                         ;AN000;
;        ASSUME  ES:DATA                                                         ;AN000;
        mov     word [parse_error_msg],ax                                       ;AN000;
        mov     dx,parse_error_msg              ;                               ;AN000;
        call    Display_Interface               ;                               ;AN000;
        pop     ds
} ;                               ;AN000;

;-----------------------------------------------------------------------------

macro Extend_Message 
{

                                                ;
        push    ds                                                              ;AN001;
        mov     dx,DATA_                                                ;AN001;
        mov     ds,dx                                                           ;AN001;
;        ASSUME  DS:DATA                                                         ;AN001;
;        ASSUME  ES:DATA                                                         ;AN001;
        mov     word [extend_error_msg],ax       ;                              ;AN001;
        mov     dx,extend_error_msg              ;                              ;AN001;
        call    Display_Interface               ;                               ;AN001;
        pop     ds                                                              ;AN001;
} ;                               ;AN001;

;-----------------------------------------------------------------------------

