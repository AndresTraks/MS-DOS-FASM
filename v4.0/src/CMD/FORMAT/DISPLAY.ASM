STRUC Message_Table Entry1_=0, Entry2_=0, Entry3_=0, Entry4_=0, Entry5_=0, Entry6_=0, Entry7_=0
{
                                                ;
.Entry1  dw      Entry1_ ;                               ;AN000;
.Entry2  dw      Entry2_ ;                               ;AN000;
.Entry3  dw      Entry3_ ;                               ;AN000;
.Entry4  dw      Entry4_ ;                               ;AN000;
.Entry5  db      Entry5_ ;                               ;AN000;
.Entry6  db      Entry6_ ;                               ;AN000;
.Entry7  dw      Entry7_ ;                               ;AN000;
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
;

;*****************************************************************************
;*****************************************************************************
;UTILITY NAME: FORMAT.COM
;
;MODULE NAME: DISPLAY.ASM
;
;
; Change List: AN000 - New code DOS 3.3 spec additions
;              AC000 - Changed code DOS 3.3 spec additions
;*****************************************************************************
;*****************************************************************************


;
;*****************************************************************************
; Define Segment ordering
;*****************************************************************************
;


.SEQ                                            ;

if SEGSEL = S_PSP
end if

if SEGSEL = S_DATA;
;Public Test_Data_Start
label Test_Data_Start byte
end if ;

if SEGSEL = S_STACK
        db      62 dup ("-Stack!-")      ; (362-80h) is the additionsal IBM ROM
;        assume ss:stack
end if


if SEGSEL = S_CODE;
;        assume  cs:code,ds:data                 ;
end if

if SEGSEL = S_END_OF_MEMORY;
;Public  Test_End
label Test_End byte
end if ;


;
;*****************************************************************************
; INCLUDE FILES
;*****************************************************************************
;

.xlist
include 'FORCHNG.INC'
include 'FOREQU.INC'
include 'FORMSG.INC'
include 'SYSMSG.INC'
.list

;
;*****************************************************************************
; Message Services
;*****************************************************************************
;


MSG_UTILNAME  <FORMAT>


if SEGSEL = S_DATA
MSG_SERVICES    <MSGDATA>
end if

if SEGSEL = S_CODE
MSG_SERVICES    <NEARmsg>
MSG_SERVICES    <LOADmsg>
MSG_SERVICES    <DISPLAYmsg,CHARmsg,NUMmsg>
MSG_SERVICES    <FORMAT.CLA,FORMAT.CLB,FORMAT.CLC,FORMAT.CL1,FORMAT.CL2,FORMAT.CTL>
end if

;
;*****************************************************************************
; Public Declarations
;*****************************************************************************
;

;        Public  SysDispMsg
;        Public  SysLoadMsg


;
;***************************************************************************
; Message Structures
;***************************************************************************
;





if SEGSEL = S_CODE
;*****************************************************************************
;Routine name&gml Display_Interface
;*****************************************************************************
;
;DescriptioN&gml Save all registers, set up registers required for SysDispMsg
;             routine. This information is contained in a message description
;             table pointed to by the DX register. Call SysDispMsg, then
;             restore registers. This routine assumes that the only time an
;             error will be returned is if an extended error message was
;             requested, so it will ignore error returns
;
;Called Procedures: Message (macro)
;
;Change History&gml Created        4/22/87         MT
;
;Input&gml ES&gmlDX = pointer to message description
;
;Output&gml None
;
;Psuedocode
;----------
;
;       Save all registers
;       Setup registers for SysDispMsg from Message Description Tables
;       CALL SysDispMsg
;       Restore registers
;       ret
;*****************************************************************************

;Public  Display_Interface
Display_Interface:                              ;                               ;AN000;

        push    ds                              ;                               ;AN000;
        push    ax                              ;Save registers                 ;AN000;
        push    bx                              ; "  "    "  "                  ;AN000;
        push    cx                              ; "  "    "  "                  ;AN000;
        push    dx                              ; "  "    "  "                  ;AN000;
        push    si                              ; "  "    "  "                  ;AN000;
        push    di                              ; "  "    "  "                  ;AN000;
        mov     di,dx                           ;Change pointer to table        ;AN000;
        mov     dx,data_                         ;Point to data segment
        mov     ds,dx                           ;
        mov     ax,[di+Message_Table.Entry1]    ;Message number                 ;AN000;
        mov     bx,[di+Message_Table.Entry2]    ;Handle                         ;AN000;
        mov     si,[di+Message_Table.Entry3]    ;Sublist                        ;AN000;
        mov     cx,[di+Message_Table.Entry4]    ;Count                          ;AN000;
        mov     dh,[di+Message_Table.Entry5]    ;Class                          ;AN000;
        mov     dl,[di+Message_Table.Entry6]    ;Function                       ;AN000;
        mov     di,[di+Message_Table.Entry7]    ;Input                          ;AN000;
        call    SYSDISPMSG                      ;Display the message            ;AN000;
        pop     di                              ;Restore registers              ;AN000;
        pop     si                              ; "  "    "  "                  ;AN000;
        pop     dx                              ; "  "    "  "                  ;AN000;
        pop     cx                              ; "  "    "  "                  ;AN000;
        pop     bx                              ; "  "    "  "                  ;AN000;
        pop     ax                              ; "  "    "  "                  ;AN000;
        pop     ds                              ;                               ;AN000;
        ret                                     ;All done                       ;AN000;

;Display_Interface      endp                     ;                               ;AN000;
end if
;        end

