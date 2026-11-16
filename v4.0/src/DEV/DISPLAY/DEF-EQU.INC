; the layouts below read these, and an EQU is read where it stands
NAME_LEN EQU    8                       ;

STRUC RHC RHC_1_=0, RHC_2_=0, RHC_CMD_=0, RHC_STA_=0, RHC_5_=0
{
         DB      RHC_1_ ; length of Request Header
         DB      RHC_2_ ; unit code (subunit)
.RHC_CMD  DB      RHC_CMD_ ; command code
.RHC_STA  DW      RHC_STA_ ; status
         DQ      RHC_5_ ; reserved for DOS
}
match =RHC_LAID_OUT, RHC_LAID_OUT
{
    RHC_LAID_OUT equ 1
    virtual at 0
      RHC RHC 0, 0, 0, 0, 0
      sizeof.RHC = $ - RHC
    end virtual
}
STRUC DHS DH_NEXTO_=0, DH_NEXTS_=0, DHS_3_=0, DH_STRAO_=0, DH_INTRO_=0, DH_NAME_=NAME_LEN DUP(0)
{
.DH_NEXTO DW     DH_NEXTO_ ; offset of pointer to next header
.DH_NEXTS DW     DH_NEXTS_ ; segment of pointer to next header
        DW      DHS_3_ ; attribute
.DH_STRAO DW     DH_STRAO_ ; offset to strategy routine
.DH_INTRO DW     DH_INTRO_ ; offset to interrupt routine
.DH_NAME DB      DH_NAME_ ; device name in this header
}
match =DHS_LAID_OUT, DHS_LAID_OUT
{
    DHS_LAID_OUT equ 1
    virtual at 0
      DHS DHS 0, 0, 0, 0, 0, NAME_LEN DUP(0)
      sizeof.DHS = $ - DHS
    end virtual
}
STRUC RH0 RH0_UNIT_=0, RH0_ENDO_=0, RH0_ENDS_=0, RH0_BPBA_=0, RH0_5_=0
{
        rb      (sizeof.RHC)            ;
                                        ;
.RH0_UNIT DB     RH0_UNIT_ ; not used for CHAR devices
.RH0_ENDO DW     RH0_ENDO_ ; offset  of ending address
.RH0_ENDS DW     RH0_ENDS_ ; segment of ending address
.RH0_BPBA DD     RH0_BPBA_ ; POINTER TO BPB FOR CHAR DEVICES
         db     RH0_5_ ;
}
match =RH0_LAID_OUT, RH0_LAID_OUT
{
    RH0_LAID_OUT equ 1
    virtual at 0
      RH0 RH0 0, 0, 0, 0, 0
      sizeof.RH0 = $ - RH0
    end virtual
}
STRUC RH3 RH3_1_=0, RH3_DTAO_=0, RH3_DTAS_=0, RH3_CNT_=0
{
        rb      (sizeof.RHC)            ; common portion
                                        ;
                                        ;
        DB      RH3_1_ ; media descriptor
.RH3_DTAO DW     RH3_DTAO_ ; offset  of transfer address
.RH3_DTAS DW     RH3_DTAS_ ; segment of transfer address
.RH3_CNT DW      RH3_CNT_ ; byte count
}
match =RH3_LAID_OUT, RH3_LAID_OUT
{
    RH3_LAID_OUT equ 1
    virtual at 0
      RH3 RH3 0, 0, 0, 0
      sizeof.RH3 = $ - RH3
    end virtual
}
STRUC RH_IOCTL MAJOR_F_=0, MINOR_F_=0, CONTENT_SI_=0, CONTENT_DI_=0, REQUEST_PACKET_=0
{
.STATIC_RH       rb      13              ; STANDARD STATIC REQUEST HEADER
.MAJOR_F         DB      MAJOR_F_ ; MAJOR FUNCTION CALL (SEE DOS 3.30)
.MINOR_F         DB      MINOR_F_ ; MINOR FUNCTION CALL (SEE DOS 3.30)
.CONTENT_SI      DW      CONTENT_SI_ ; CONTENTS OF SI
.CONTENT_DI      DW      CONTENT_DI_ ; CONTENTS OF DI
.REQUEST_PACKET  DD      REQUEST_PACKET_ ; POINTER TO GENERIC IOCTL REQ. PACKET
}
match =RH_IOCTL_LAID_OUT, RH_IOCTL_LAID_OUT
{
    RH_IOCTL_LAID_OUT equ 1
    virtual at 0
      RH_IOCTL RH_IOCTL 0, 0, 0, 0, 0
      sizeof.RH_IOCTL = $ - RH_IOCTL
    end virtual
}
STRUC DESG_BUFFER DESG_CARTRIDGE_=0, DESG_LENGTH_=0, DESG_N_=0, DESG_CP_=0
{
.DESG_CARTRIDGE  DW      DESG_CARTRIDGE_ ; 0=NO CARTRIDGE, 1=CARTRIDGE
.DESG_LENGTH     DW      DESG_LENGTH_ ; LENGTH OF REMAINING HEADER
.DESG_N          DW      DESG_N_ ; NUMBER OF CP's DESIGNATED
.DESG_CP         DW      DESG_CP_ ; FIRST CP DESIGNATED
}
match =DESG_BUFFER_LAID_OUT, DESG_BUFFER_LAID_OUT
{
    DESG_BUFFER_LAID_OUT equ 1
    virtual at 0
      DESG_BUFFER DESG_BUFFER 0, 0, 0, 0
      sizeof.DESG_BUFFER = $ - DESG_BUFFER
    end virtual
}
STRUC INVK_BUFFER INVK_LENGTH_=0, INVK_CP_=0
{
.INVK_LENGTH     DW      INVK_LENGTH_ ; LENGTH OF REMAINING HEADER
.INVK_CP         DW      INVK_CP_ ; CP TO INVOKE
}
match =INVK_BUFFER_LAID_OUT, INVK_BUFFER_LAID_OUT
{
    INVK_BUFFER_LAID_OUT equ 1
    virtual at 0
      INVK_BUFFER INVK_BUFFER 0, 0
      sizeof.INVK_BUFFER = $ - INVK_BUFFER
    end virtual
}
STRUC QLST_BUFFER QLST_LENGTH_=0, QLST_N_HDWR_=0, QLST_HDWR_CP_=0, QLST_N_DESG_=0, QLST_DESG_CP_=0
{
.QLST_LENGTH     DW      QLST_LENGTH_ ; LENGTH OF REMAINING HEADER
.QLST_N_HDWR     DW      QLST_N_HDWR_ ; NUMBER OF HARDWARE CP's
.QLST_HDWR_CP    DW      QLST_HDWR_CP_ ; FIRST HDWR CODE PAGE
.QLST_N_DESG     DW      QLST_N_DESG_ ; NUMBER OF DESIGNATED CP's
.QLST_DESG_CP    DW      QLST_DESG_CP_ ; DESINATED CODE PAGES
                                        ; ...there is more data to be
                                        ;    filled in by the DRIVER
}
match =QLST_BUFFER_LAID_OUT, QLST_BUFFER_LAID_OUT
{
    QLST_BUFFER_LAID_OUT equ 1
    virtual at 0
      QLST_BUFFER QLST_BUFFER 0, 0, 0, 0, 0
      sizeof.QLST_BUFFER = $ - QLST_BUFFER
    end virtual
}
STRUC PARSE_TABLE1 NUM_DEVICES_=0, DEVICE1_OFFSET_=0
{
.NUM_DEVICES     DW      NUM_DEVICES_ ; NUMBER OF DEVICES TO SUPPORT
.DEVICE1_OFFSET  DW      DEVICE1_OFFSET_ ; (hopefully) CON!!!
}
match =PARSE_TABLE1_LAID_OUT, PARSE_TABLE1_LAID_OUT
{
    PARSE_TABLE1_LAID_OUT equ 1
    virtual at 0
      PARSE_TABLE1 PARSE_TABLE1 0, 0
      sizeof.PARSE_TABLE1 = $ - PARSE_TABLE1
    end virtual
}
STRUC PARSE_TABLE2 NUM_ITEMS_=0, OFFSET_LIST_=0
{
.NUM_ITEMS       DW      NUM_ITEMS_ ; NUMBER OF ITEMS CREATED BY THE
.OFFSET_LIST     DW      OFFSET_LIST_ ; THE 1ST OFFSET OF [ TABLE 2 ]
}
match =PARSE_TABLE2_LAID_OUT, PARSE_TABLE2_LAID_OUT
{
    PARSE_TABLE2_LAID_OUT equ 1
    virtual at 0
      PARSE_TABLE2 PARSE_TABLE2 0, 0
      sizeof.PARSE_TABLE2 = $ - PARSE_TABLE2
    end virtual
}
STRUC CP_PNTER_STRUC HDWR_CP_STRUC_=0, DESG_CP_STRUC_=0, FONT_CP_STRUC_=0, WRITE_DATA_STRUC_=0, FONT_DATA_STRUC_=0
{
.HDWR_CP_STRUC   DW      HDWR_CP_STRUC_ ;
.DESG_CP_STRUC   DW      DESG_CP_STRUC_ ;
.FONT_CP_STRUC   DW      FONT_CP_STRUC_ ;
.WRITE_DATA_STRUC DW     WRITE_DATA_STRUC_ ;
.FONT_DATA_STRUC DW      FONT_DATA_STRUC_ ;
}
match =CP_PNTER_STRUC_LAID_OUT, CP_PNTER_STRUC_LAID_OUT
{
    CP_PNTER_STRUC_LAID_OUT equ 1
    virtual at 0
      CP_PNTER_STRUC CP_PNTER_STRUC 0, 0, 0, 0, 0
      sizeof.CP_PNTER_STRUC = $ - CP_PNTER_STRUC
    end virtual
}
STRUC BUF_DATA DEV_HDRO_=-1, DEV_HDRS_=-1, CON_STRAO_=-1, CON_STRAS_=-1, CON_INTRO_=-1, CON_INTRS_=-1, RH_PTRO_=-1, RH_PTRS_=-1, STATE_=0, STATUS_=0
{
.DEV_HDRO DW     DEV_HDRO_ ; device driver header offset
.DEV_HDRS DW     DEV_HDRS_ ;
.CON_STRAO DW    CON_STRAO_ ; dos CON strategy offset
.CON_STRAS DW    CON_STRAS_ ;
.CON_INTRO DW    CON_INTRO_ ; dos CON strategy offset
.CON_INTRS DW    CON_INTRS_ ;
.RH_PTRO DW      RH_PTRO_ ; request header offset
.RH_PTRS DW      RH_PTRS_ ; segment
.STATE   DW       STATE_ ;
.STATUS  DW       STATUS_ ;
}
match =BUF_DATA_LAID_OUT, BUF_DATA_LAID_OUT
{
    BUF_DATA_LAID_OUT equ 1
    virtual at 0
      BUF_DATA BUF_DATA 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.BUF_DATA = $ - BUF_DATA
    end virtual
}
STRUC DA_INFO_PACKET DA_INFO_LEVEL_=0, DA_SETMODE_FLAG_=0, DA_OPTION_L_STATE_=0
{
.DA_INFO_LEVEL       db      DA_INFO_LEVEL_ ; 0 for DA_SETMODE_FLAG,  1 for DA_OPTION_L_STATE query (for OS2 compat. box).
.DA_SETMODE_FLAG     db      DA_SETMODE_FLAG_ ; 1: DISPLAY.SYS is calling INT 10h call, SET MODE. 0= finished.
.DA_OPTION_L_STATE   db      DA_OPTION_L_STATE_ ; on return from ANSI, 1 = ANSI /L option active, 0 = inactive.
}
match =DA_INFO_PACKET_LAID_OUT, DA_INFO_PACKET_LAID_OUT
{
    DA_INFO_PACKET_LAID_OUT equ 1
    virtual at 0
      DA_INFO_PACKET DA_INFO_PACKET 0, 0, 0
      sizeof.DA_INFO_PACKET = $ - DA_INFO_PACKET
    end virtual
}
STRUC INFO_BLOCK STATIC_ADDRESS_=0, ACTIVE_DISPLAY_=0, ALT_DISPLAY_=0, CURRENT_SCANS_=0, MISC_INFO_=0
{
.STATIC_ADDRESS  DD   STATIC_ADDRESS_ ; address of static functionality table;AN000;
                Rb   33
.ACTIVE_DISPLAY  DB   ACTIVE_DISPLAY_ ; active display code                  ;AN000;
.ALT_DISPLAY     DB   ALT_DISPLAY_ ; alternate display code               ;AN000;
                Rb   3
.CURRENT_SCANS   DB   CURRENT_SCANS_ ; current number of scan lines         ;AN000;
                Rb   2
.MISC_INFO       DB   MISC_INFO_ ; miscellaneous state information      ;AN000;
                Rb   18
}
match =INFO_BLOCK_LAID_OUT, INFO_BLOCK_LAID_OUT
{
    INFO_BLOCK_LAID_OUT equ 1
    virtual at 0
      INFO_BLOCK INFO_BLOCK 0, 0, 0, 0, 0
      sizeof.INFO_BLOCK = $ - INFO_BLOCK
    end virtual
}
STRUC SYS_ID SYS_ID_1_=0, MODEL_BYTE_=0
{
                DW   SYS_ID_1_ ; don't care                           ;AN000;
.MODEL_BYTE      DB   MODEL_BYTE_ ; model byte                           ;AN000;
}
match =SYS_ID_LAID_OUT, SYS_ID_LAID_OUT
{
    SYS_ID_LAID_OUT equ 1
    virtual at 0
      SYS_ID SYS_ID 0, 0
      sizeof.SYS_ID = $ - SYS_ID
    end virtual
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; *** DEF-EQU *** DEF-EQU *** DEF-EQU ***
;
;       EQU's, STRUC's, and OTHER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Modification history *********************************************************
;AN001; D358  New device driver INIT function package             12/07/87 J.K.
;AN002; D493  Undo D358                                           02/24/88 J.K.
;AN003; D4934 Change ANSI 2F function number to 1Ah               05/20/88 F.G.
;******************************************************************************
;IF1                                     ;
;        %OUT .               ®DEF-EQU .INC¯
;ENDIF                                   ;
ZERO    EQU     0H                      ;
ONE     EQU     1H                      ;
TWO     EQU     2H                      ;
THREE   EQU     3H                      ;
FOUR    EQU     4H                      ;
FIVE    EQU     5H                      ;
SIX     EQU     6H                      ;
SEVEN   EQU     7H                      ;
EIGHT   EQU     8H                      ;
NINE    EQU     9H                      ;
TEN     EQU    0AH                      ;
ELEVEN  EQU    0BH                      ;
TWELVE  EQU    0CH                      ;
                                        ;
FAIL    EQU     8000H                   ; fail in designate
                                        ;
NOT_CY  EQU     0FFFEH                  ;
CY      EQU     ONE                     ;
                                        ;
ID_IOCTL       EQU     5                ; MAJOR FNCT # FOR 'other' DEVICE
                                        ;
RH      equ     es:DI	; addressability to Request Header
                                        ;
                                        ;
CMD_INPUT EQU   4                       ; RHC_CMD is INPUT request
                                        ;
                                        ; Status values for RHC_STA
STAT_DONE EQU   0001H                   ; function complete - high order byte
STAT_CMDERR EQU 8000H                   ; Error code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      DEVICE  Header     DS:[SI]      -- to locate the next CON header
;      NEXT device header ES:[DI]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HP      equ     ds:SI	;
NHD     equ     es:DI	;
                                        ;
NAME_LEN EQU    8                       ;
                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      Request Header for INIT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      Request Header for IOCTL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       IOCTL header format
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       DESIGNATE BUFFER FORMAT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       INVOKE BUFFER FORMAT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       QUERY LIST BUFFER FORMAT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       PARSER STRUC STATEMENTS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       CODE PAGE POINTER STRUCTURE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CON data structure  CS:[BX]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BUF     equ     cs:BX	;
                                        ; STATES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       General  Constants
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INT_2F_LOW EQU  (4*2FH)                 ; INTERRUPT 2FH CON/KEYB COMMUNICATION
INT_2F_HI equ    ((4*2FH)+2)	;
INT_43_LOW EQU  (4*43H)                 ; INTERRUPT 43H 0-255 CHARACTER VECTOR
INT_43_HI equ    ((4*43H)+2)	;
INT_44_LOW EQU  (4*44H)                 ; INTERRUPT 44H 0-255 CHARACTER VECTOR
INT_44_HI equ    ((4*44H)+2)	;
INT_1F_LOW EQU  (4*1FH)                 ; INTERRUPT 1FH EXTENDED CHARACTER SUPPORT
INT_1F_HI equ    ((4*1FH)+2)	;
INT_10_LOW EQU  (4*10H)                 ; INTERRUPT 10H fix FOR PALACE
INT_10_HI equ    ((4*10H)+2)	;
GET_MODE      EQU    0FH                ; WGR                                  ;AN000;
ON            EQU    1                  ; WGR                                  ;AN000;
OFF           EQU    0                  ; WGR                                  ;AN000;
RECALC_ON     EQU    0010H              ; WGR                                  ;AN000;
VIDEO_CTRL    EQU    487H               ; WGR                                  ;AN000;
ANSI_BUF_SIZE EQU    14                 ; WGR                                  ;AN000;
DEFAULT_LEN   EQU    25                 ; WGR                                  ;AN000;
NUMBER        EQU    1                  ; WGR                                  ;AN000;
STRING        EQU    3                  ; WGR                                  ;AN000;
COMPLEX       EQU    4                  ; WGR                                  ;AN000;
RC_EOL        equ    (-1)	; WGR                                  ;AN000;
RC_NO_ERROR   EQU    0                  ; WGR                                  ;AN000;
FUNC_CALL     EQU    1BH                ; WGR                                  ;AN000;
VGA_FOUND     EQU    00000001B          ; WGR                                  ;AN000;
EGA_FOUND     EQU    00000001B          ; WGR                                  ;AN000;
LCD_FOUND     EQU    00000010B          ; WGR                                  ;AN000;
CGA_FOUND     EQU    00000100B          ; WGR                                  ;AN000;
MONO_FOUND    EQU    00001000B          ; WGR                                  ;AN000;
ALT_SELECT    EQU    12H                ; WGR                                  ;AN000;
EGA_INFO_CALL EQU    10H                ; WGR                                  ;AN000;
GET_SYS_ID    EQU    0C0H               ; WGR                                  ;AN000;
GET_STATUS    EQU    43H                ; WGR                                  ;AN000;
LCD_MODEL     EQU    0F9H               ; WGR                                  ;AN000;
COLOR_ADDRESS EQU    0B800H             ; WGR                                  ;AN000;
MONO_ADDRESS  EQU    0B000H             ; WGR                                  ;AN000;
ERROR_1       EQU    2                  ; WGR                                  ;AN000;
ERROR_2       EQU    12                 ; WGR                                  ;AN000;
ERROR_3       EQU    8                  ; WGR                                  ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; *** INT 2Fh used
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ANSI_2F       EQU    1Ah                ; WGR Muliflex number for ANSI         ;AC003;
;Catagory code
IOCTL_2F      EQU     1h                ;
DA_INFO_2F    EQU     2h                ;J.K. Information passing to ANSI.
;Subfunction code for IOCTL_2F
GET_SUBFUNC   EQU    7FH                ; WGR Same structure as GET_IOCTL(ANSI);AN000;

;Info Struture for DA_INFO_2F. (DS:DX point to this packet)
;J.K. Note: For DOS 4.00, DA_INFO_PACKET is used to signal ANSI.SYS that
;DISPLAY.SYS is calling/finishing INT 10h SET MODE call.  ANSI.SYS needs this
;infomration since it also hooks INT 10h vector.
;For this DA_SETMODE_FLAG purpose, DA_INFO_LEVEL and DA_INFO_DIRECTION should always be
;set to 0.  This can be extended for another information passing scheme between
;DISPLAY.SYS and ANSI.SYS in the future version.
;For DA_SETMODE_FLAG, DISPLAY.SYS should be extremely careful that when it calls
;with DA_SETMODE_FLAG =1, then it should calls with DA_SETMODE_FLAG=0
;when it finished INT 10h function call. Otherwise, the system goes .....

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; *** DEF-EQU *** DEF-EQU *** DEF-EQU ***
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Information Block Structure
;    (for functionality call)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Structure of System ID call return block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
