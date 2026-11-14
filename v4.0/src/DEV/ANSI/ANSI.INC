; the layouts below read these, and an EQU is read where it stands
NAME_LEN EQU    8                       ;                                      ;AN000;

STRUC DHS DH_NEXTO_=0, DH_NEXTS_=0, DHS_3_=0, DH_STRAO_=0, DH_INTRO_=0
{
.DH_NEXTO DW     DH_NEXTO_ ; offset of pointer to next header     ;AN000;
.DH_NEXTS DW     DH_NEXTS_ ; segment of pointer to next header    ;AN000;
        DW      DHS_3_ ; attribute                            ;AN000;
.DH_STRAO DW     DH_STRAO_ ; offset to strategy routine           ;AN000;
.DH_INTRO DW     DH_INTRO_ ; offset to interrupt routine          ;AN000;
.DH_NAME DB      NAME_LEN DUP(0)         ; device name in this header           ;AN000;
}
match =DHS_LAID_OUT, DHS_LAID_OUT
{
    DHS_LAID_OUT equ 1
    virtual at 0
      DHS DHS 0, 0, 0, 0, 0
      sizeof.DHS = $ - DHS
    end virtual
}
STRUC BUF_DATA DEV_HDRO_=-1, DEV_HDRS_=-1, CON_STRAO_=-1, CON_STRAS_=-1, CON_INTRO_=-1, CON_INTRS_=-1
{
.DEV_HDRO DW     DEV_HDRO_ ; device driver header offset          ;AN000;
.DEV_HDRS DW     DEV_HDRS_ ;                                      ;AN000;
.CON_STRAO DW    CON_STRAO_ ; dos CON strategy offset              ;AN000;
.CON_STRAS DW    CON_STRAS_ ;                                      ;AN000;
.CON_INTRO DW    CON_INTRO_ ; dos CON strategy offset              ;AN000;
.CON_INTRS DW    CON_INTRS_ ;                                      ;AN000;
}
match =BUF_DATA_LAID_OUT, BUF_DATA_LAID_OUT
{
    BUF_DATA_LAID_OUT equ 1
    virtual at 0
      BUF_DATA BUF_DATA 0, 0, 0, 0, 0, 0
      sizeof.BUF_DATA = $ - BUF_DATA
    end virtual
}
STRUC INIT_REQ_HDR NUM_UNITS_=0, END_ADDRESS_O_=0, END_ADDRESS_S_=0, ARG_PTR_=0, DRIVE_NUM_=0, CONFIG_ERRMSG_=0
{
                Rb   13
.NUM_UNITS       DB   NUM_UNITS_ ; number of units (N/A)                ;AN000;
.END_ADDRESS_O   DW   END_ADDRESS_O_ ; ending address of resident code      ;AN000;
.END_ADDRESS_S   DW   END_ADDRESS_S_ ;                                      ;AN000;
.ARG_PTR         DD   ARG_PTR_ ; ptr. to remaining arguments          ;AN000;
.DRIVE_NUM       DB   DRIVE_NUM_ ; drive number (N/A)                   ;AN000;
.CONFIG_ERRMSG   dw   CONFIG_ERRMSG_ ;Flag to control "Error in CONFIG.SYS.." msg.;AN002;
}
match =INIT_REQ_HDR_LAID_OUT, INIT_REQ_HDR_LAID_OUT
{
    INIT_REQ_HDR_LAID_OUT equ 1
    virtual at 0
      INIT_REQ_HDR INIT_REQ_HDR 0, 0, 0, 0, 0, 0
      sizeof.INIT_REQ_HDR = $ - INIT_REQ_HDR
    end virtual
}
STRUC INFO_BLOCK STATIC_ADDRESS_=0, ACTIVE_DISPLAY_=0, ALT_DISPLAY_=0, CURRENT_SCANS_=0, MISC_INFO_=0
{
.STATIC_ADDRESS  DD   STATIC_ADDRESS_ ; address of static functionality table      ;AN000;
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
STRUC MODE_TABLE V_MODE_=-1, D_MODE_=-1, RESERVED_BYTE_=0, COLORS_=-1, SCR_WIDTH_=-1, SCR_LENGTH_=-1, SCR_COLS_=-1, SCR_ROWS_=-1
{
.V_MODE          DB    V_MODE_ ; video mode                           ;AN000;
.D_MODE          DB    D_MODE_ ; display mode                         ;AN000;
.RESERVED_BYTE   DB    RESERVED_BYTE_ ; reserved                             ;AN000;
.COLORS          DW    COLORS_ ; colors                               ;AN000;
.SCR_WIDTH       DW    SCR_WIDTH_ ; screen width (pels)                  ;AN000;
.SCR_LENGTH      DW    SCR_LENGTH_ ; screen length (pels)                 ;AN000;
.SCR_COLS        DW    SCR_COLS_ ; number columns                       ;AN000;
.SCR_ROWS        DW    SCR_ROWS_ ; number rows                          ;AN000;
}
match =MODE_TABLE_LAID_OUT, MODE_TABLE_LAID_OUT
{
    MODE_TABLE_LAID_OUT equ 1
    virtual at 0
      MODE_TABLE MODE_TABLE 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.MODE_TABLE = $ - MODE_TABLE
    end virtual
}
STRUC STATIC_BLOCK SCAN_TEXT_=0
{
                Rb   7
.SCAN_TEXT       DB   SCAN_TEXT_ ; available scan lines in text modes   ;AN000;
}
match =STATIC_BLOCK_LAID_OUT, STATIC_BLOCK_LAID_OUT
{
    STATIC_BLOCK_LAID_OUT equ 1
    virtual at 0
      STATIC_BLOCK STATIC_BLOCK 0
      sizeof.STATIC_BLOCK = $ - STATIC_BLOCK
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
STRUC DA_INFO_PACKET DA_INFO_LEVEL_=0, DA_SETMODE_FLAG_=0, DA_OPTION_L_STATE_=0
{
.DA_INFO_LEVEL       db      DA_INFO_LEVEL_ ; 0=used for SET_MODE_FLAG 1=for OPTION_L_STATE
.DA_SETMODE_FLAG     db      DA_SETMODE_FLAG_ ; 1: DISPLAY.SYS is calling INT 10h call, SET MODE. 0=finished.
.DA_OPTION_L_STATE   db      DA_OPTION_L_STATE_ ; 1 = /L active, 0 = /L inactive
}
match =DA_INFO_PACKET_LAID_OUT, DA_INFO_PACKET_LAID_OUT
{
    DA_INFO_PACKET_LAID_OUT equ 1
    virtual at 0
      DA_INFO_PACKET DA_INFO_PACKET 0, 0, 0
      sizeof.DA_INFO_PACKET = $ - DA_INFO_PACKET
    end virtual
}
STRUC IOCTL_REQ_HDR MAJ_FUNC_=0, MIN_FUNC_=0, IOCTL_SI_=0, IOCTL_DI_=0, REQ_PCKT_PTR_=0
{
                Rb   13
.MAJ_FUNC        DB   MAJ_FUNC_ ; major function                       ;AN000;
.MIN_FUNC        DB   MIN_FUNC_ ; minor function                       ;AN000;
.IOCTL_SI        DW   IOCTL_SI_ ; contents of SI                       ;AN000;
.IOCTL_DI        DW   IOCTL_DI_ ; contents of DI                       ;AN000;
.REQ_PCKT_PTR    DD   REQ_PCKT_PTR_ ; pointer to request packet            ;AN000;
}
match =IOCTL_REQ_HDR_LAID_OUT, IOCTL_REQ_HDR_LAID_OUT
{
    IOCTL_REQ_HDR_LAID_OUT equ 1
    virtual at 0
      IOCTL_REQ_HDR IOCTL_REQ_HDR 0, 0, 0, 0, 0
      sizeof.IOCTL_REQ_HDR = $ - IOCTL_REQ_HDR
    end virtual
}
STRUC REQ_PCKT INFO_LEVEL_=0, REQ_PCKT_2_=0, DATA_LENGTH_=0, RP_FLAGS_=0, RP_MODE_=0, RESERVED2_=0, RP_COLORS_=0, RP_WIDTH_=0, RP_LENGTH_=0, RP_COLS_=0, RP_ROWS_=0
{
.INFO_LEVEL      DB   INFO_LEVEL_ ; information level (should be 0)      ;AN000;
                DB   REQ_PCKT_2_ ; reserved                             ;AN000;
.DATA_LENGTH     DW   DATA_LENGTH_ ; length of remaining data             ;AN000;
.RP_FLAGS        DW   RP_FLAGS_ ; control flags                        ;AN000;
.RP_MODE         DB   RP_MODE_ ; display mode                         ;AN000;
.RESERVED2       DB   RESERVED2_ ; reserved                             ;AN000;
.RP_COLORS       DW   RP_COLORS_ ; # of colors                          ;AN000;
.RP_WIDTH        DW   RP_WIDTH_ ; screen width                         ;AN000;
.RP_LENGTH       DW   RP_LENGTH_ ; screen length                        ;AN000;
.RP_COLS         DW   RP_COLS_ ; columns                              ;AN000;
.RP_ROWS         DW   RP_ROWS_ ; rows                                 ;AN000;
}
match =REQ_PCKT_LAID_OUT, REQ_PCKT_LAID_OUT
{
    REQ_PCKT_LAID_OUT equ 1
    virtual at 0
      REQ_PCKT REQ_PCKT 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.REQ_PCKT = $ - REQ_PCKT
    end virtual
}
STRUC SCAN_LINE_STR NUM_LINES_=0, REP_1BH_=0, REP_12H_=0
{
.NUM_LINES       DW   NUM_LINES_ ; number of scan lines                 ;AN000;
.REP_1BH         DB   REP_1BH_ ; representation in 1Bh call           ;AN000;
.REP_12H         DB   REP_12H_ ; representation in 12h call           ;AN000;
}
match =SCAN_LINE_STR_LAID_OUT, SCAN_LINE_STR_LAID_OUT
{
    SCAN_LINE_STR_LAID_OUT equ 1
    virtual at 0
      SCAN_LINE_STR SCAN_LINE_STR 0, 0, 0
      sizeof.SCAN_LINE_STR = $ - SCAN_LINE_STR
    end virtual
}
STRUC SUB_STRUC SUB_PTR_O_=0, SUB_PTR_S_=0
{
                Rb  2
.SUB_PTR_O       DW  SUB_PTR_O_ ;                                      ;AN000;
.SUB_PTR_S       DW  SUB_PTR_S_ ;                                      ;AN000;
}
match =SUB_STRUC_LAID_OUT, SUB_STRUC_LAID_OUT
{
    SUB_STRUC_LAID_OUT equ 1
    virtual at 0
      SUB_STRUC SUB_STRUC 0, 0
      sizeof.SUB_STRUC = $ - SUB_STRUC
    end virtual
}
STRUC RESULT_STRUC RESULT_TYPE_=0, RESULT_STRUC_2_=0, RES_SYN_PTR_=0, RES_PTR_=0
{
.RESULT_TYPE     DB  RESULT_TYPE_ ;                                      ;AN000;
                DB  RESULT_STRUC_2_ ;                                      ;AN000;
.RES_SYN_PTR     DW  RES_SYN_PTR_ ;                                      ;AN000;
.RES_PTR         DD  RES_PTR_ ;                                      ;AN000;
}
match =RESULT_STRUC_LAID_OUT, RESULT_STRUC_LAID_OUT
{
    RESULT_STRUC_LAID_OUT equ 1
    virtual at 0
      RESULT_STRUC RESULT_STRUC 0, 0, 0, 0
      sizeof.RESULT_STRUC = $ - RESULT_STRUC
    end virtual
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Equates and Strucs.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------------------------------------------------------------------------
;AN001; D425 For OS2 compatibiltiy box, /L option status query     01/14/88 J.K.
;AN002; D493 New INIT request structure for error message          02/25/88 J.K.
;AN003; P4934 Change ANSI 2F function number t0 1Ah                05/20/88 F.G.
;------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;      DEVICE  Header     DS:[SI]      -- to locate the next CON header
;      NEXT device header ES:[DI]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HP      equ     ds:SI	;                                      ;AN000;
NHD     equ     es:DI	;                                      ;AN000;
                                        ;
NAME_LEN EQU    8                       ;                                      ;AN000;
                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CON data structure  CS:[BX]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CONPTR  equ     cs:BX	;                                      ;AN000;
                                        ; STATES                               ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                                      ;AN000;
;
;  INIT Structures and equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ROM_BIOS        EQU     40h             ; Segment of ROM_BIOS data area        ;AN000;
EQUIP_FLAG      EQU     10h             ; equipment flag. (for LCD)            ;AN000;
KBD_FLAG_3      EQU     96h             ; offset of KBD_FLAG_3 in data area    ;AN000;
NUM_ROWS        EQU     84h             ; offset of number of rows in data area;AN000;
EXT16_FLAG      EQU     00010000b       ; mask for Extended INT16 bit          ;AN000;
INIT_VID_MASK   EQU     0FFCFh          ; mask for equipment list              ;AN000;
LCD_COLOR_MODE  EQU     20h             ; LCD as color                         ;AN000;
LCD_MONO_MODE   EQU     30h             ; LCD as MONOchrome                    ;AN000;
UNKNOWN_CMD     EQU     8103H           ; unknown command status byte          ;AN000;
RC_EOL          equ     (-1)	; parser return code for EOL           ;AN000;
RC_NO_ERROR     EQU     0               ; parser return code for not in switch list  ;AN000;
INVALID_PARM    EQU     10              ; PARSE Invalid parameter message number     ;AN000;
SSTRING         EQU     3               ; PARSE Too many parameters message    ;AN000;
FUNC_CALL       EQU     1BH             ; VGA functionality call               ;AN000;
ALT_SELECT      EQU     12H             ; EGA alternate select call            ;AN000;
EGA_INFO        EQU     10H             ; EGA return information subcall       ;AN000;
ALT_PRT_SC      EQU     20H             ; select alternate print screen subcall;AN000;
MONOCHROME      EQU     1               ; monochrome attached to EGA           ;AN000;
COLOR           EQU     0               ; some color attached to EGA           ;AN000;
PS2_MONO        EQU     7               ; display adapter types...             ;AN000;
PS2_COLOR       EQU     8               ;                                      ;AN000;
MOD30_MONO      EQU     0BH             ;                                      ;AN000;
MOD30_COLOR     EQU     0CH             ;                                      ;AN000;
LCD_MODEL       EQU     0F9H            ; Convertible model byte value         ;AN000;
GET_SYS_ID      EQU     0C0H            ; INT15H call for system identification;AN000;
GET_STATUS      EQU     43H             ; read system status (Convertible)     ;AN000;
MONO_ADDRESS    EQU     0B000H          ; base address for monochrome          ;AN000;
COLOR_ADDRESS   EQU     0B800H          ; base address for CGA                 ;AN000;
UNOCCUPIED      equ     (-1)	; value in VIDEO_MODE_TABLE if space unused  ;AN000;
LCD_ACTIVE      EQU     00000001B       ; LCD adapter is present               ;AN000;
MONO_ACTIVE     EQU     00000010B       ; monochrome adapter is present        ;AN000;
CGA_ACTIVE      EQU     00000100B       ; CGA adapter is present               ;AN000;
MCGA_ACTIVE     EQU     00001000B       ; MCGA is present                      ;AN000;
E5151_ACTIVE    EQU     00010000B       ; EGA with monochrome is present       ;AN000;
E5153_ACTIVE    EQU     00100000B       ; EGA with color display is present    ;AN000;
E5154_ACTIVE    EQU     01000000B       ; EGA with enhanced color display is present ;AN000;
VGA_ACTIVE      EQU     10000000B       ; VGA is present                       ;AN000;
INT10_LOW       equ     ((4*10H))	; interrupt 10 vector location         ;AN000;
INT10_HI        equ     ((4*10H)+2)	;                                      ;AN000;
INT2F_LOW       equ     ((4*2FH))	; interrupt 2F vector location         ;AN000;
INT2F_HI        equ     ((4*2FH)+2)	;                                      ;AN000;
ONE             EQU     1               ;                                      ;AN000;
THREE           EQU     3               ;                                      ;AN000;
EIGHT           EQU     8               ;                                      ;AN000;
NINE            EQU     9               ;                                      ;AN000;
FOURTEEN        EQU     14              ;                                      ;AN000;
REQ_CRSR_POS    EQU     3               ; function call to return cursor position    ;AN000;
MODE7           EQU     7               ;                                      ;AN000;
MODE13          EQU     13              ;                                      ;AN000;
MODE15          EQU     15              ;                                      ;AN000;
MODE19          EQU     19              ;                                      ;AN000;
                                        ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                                      ;AN000;
;
;  Request Header Structure (INIT)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Information Block Structure
;    (for functionality call)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Video table entry structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Structure of Static Block
;  (for functionality call
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Structure of System ID call return block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; INT2f Strucs and Equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MULT_ANSI       EQU     1Ah             ; ANSI multiplex number                ;AC003;
;Catagory code
INSTALL_CHECK   EQU     0               ; install check for ANSI               ;AN000;
IOCTL_2F        EQU     1               ; 2F interface to IOCTL                ;AN000;
DA_INFO_2F      EQU     2h              ;J.K. Information passing to ANSI.
;Subfunction code for IOCTL_2F
GET_SUBFUNC   EQU    7FH                ; WGR Same structure as GET_IOCTL(ANSI);AN000;

;Info Struture for DA_INFO_2F. (DS:DX point to this packet)
;J.K. Note: For DOS 4.00, DA_INFO_PACKET is used by DISPLAY.SYS to signal ANSI.SYS that
;DISPLAY.SYS is calling/finishing INT 10h SET MODE call.  ANSI.SYS needs this
;infomration since it also hooks INT 10h vector.
;For this DA_SETMODE_FLAG purpose, DA_INFO_LEVEL and DA_INFO_DIRECTION should always be
;set to 0.  This can be extended for another information passing scheme between
;DISPLAY.SYS and ANSI.SYS in the future version.
;For DA_SETMODE_FLAG, DISPLAY.SYS should be extremely careful that when it calls
;with DA_SETMODE_FLAG =1, then it should calls with DA_SETMODE_FLAG=0
;when it finished INT 10h function call. Otherwise, the system goes .....
;
;D425. At the request of OS2 compatibility box, when the user ask to ANSI
; with DA_INFO_LEVEL=1, then ANSI sets DA_OPTION_L_STATE based on /L option
; status.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GENERIC IOCTL Strucs and Equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                        ;                                      ;AN000;
DISPLAY_TYPE    EQU     3               ; MAJ_FUNC type for display            ;AN000;
GET_FUNC        EQU     7FH             ; MIN_FUNC for get subfunction         ;AN000;
SET_FUNC        EQU     5FH             ; MIN_FUNC for set subfunction         ;AN000;
REQ_VID_MODE    EQU     0FH             ; request video mode INT10h function call    ;AN000;
DONE            EQU     0100H           ; set done bit for IOCTL status        ;AN000;
CMD_ERROR       EQU     8000H           ; set error bit for IOCTL status       ;AN000;
INVALID_FUNC    EQU     1               ; invalid function                     ;AN000;
NOT_SUPPORTED   EQU     10              ; return code non-supported ioctl function   ;AN000;
NOT_AVAILABLE   EQU     12              ; return code for font not available   ;AN000;
TEXT_MODE       EQU     1               ; text mode = 1 in request packet      ;AN000;
GRAPHICS_MODE   EQU     2               ; graphics mode = 2                    ;AN000;
DEFAULT_LENGTH  EQU     25              ; normal screen length                 ;AN000;
OFF             EQU     0000H           ;                                      ;AN000;
ON              EQU     0001H           ;                                      ;AN000;
INT_BIT         EQU     00100000b       ; mask for int. bit from functionality call  ;AN000;
FOUND           EQU     1               ; flag value for FOUND                 ;AN000;
NOT_FOUND       EQU     0               ; flag value for not FOUND             ;AN000;
SET_MODE        EQU     0               ; set mode INT10H function number      ;AN000;
DISPLAY_CHECK   EQU     0AD00H          ; install check for DISPLAY.SYS        ;AN000;
CHECK_ACTIVE    EQU     0AD02H          ; active code page check for DISPLAY.SY;AN000;
INSTALLED       EQU     0FFH            ; present in AL if installed           ;AN000;
LOAD_8X8        EQU     1112H           ; register value for 8x8 ROM load      ;AN000;
SET_BLOCK_0     EQU     1103H           ; activate block = 0.                  ;AN000;
CHECK_FOR_FONT  EQU     0AD10H          ; check for 8x8 RAM font - DISPLAY.SYS ;AN000;
SELECT_SCAN     EQU     30H             ; subfunction to set scan lines (VGA)  ;AN000;
SET_INTENSIFY   EQU     0               ; value to enable intensify.           ;AN000;
SET_BLINK       EQU     1               ; value to enable blink.               ;AN000;
BLINK_TOGGLE    EQU     1003H           ; INT10 call to toggle int/blink bit.  ;AN000;
CURSOR_FLAG     EQU     87H             ; cursor flag byte in ROM_BIOS         ;AN000;
SET_CURSOR_CALL EQU     1               ; INT10 function call to set cursor typ;AN000;
VIDEO_MASK      EQU     7FH             ; turn of clear buffer bit of mode value     ;AN000;
MULT_ANSI       EQU     1Ah             ; ANSI multiplex number                ;AC003;
INSTALL_CHECK   EQU     0               ; install check for ANSI               ;AN000;
IOCTL_2F        EQU     1               ; 2F interface to IOCTL                ;AN000;
NOT_CY          EQU     0FFFEH          ; turn carry bit off                   ;AN000;
CY              EQU     1               ; turn carry bit off                   ;AN000;
INVALID_FLAGS   EQU     0FFFEH          ; test for invalid flags in control word     ;AN000;
TURN_OFF        EQU     0FEH            ; values to turn off and on cursor..   ;AN000;
TURN_ON         equ     (NOT TURN_OFF)	; emulation                            ;AN000;
SUB_SIZE        EQU     11              ; sublist size                         ;AN000;
LEFT_ASCIIZ     EQU     00010000B       ; left-aligned asciiz string           ;AN000;
UNLIMITED       EQU     0               ; unlimited message size.              ;AN000;
                                        ;                                      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Request Header Structure (Generic IOCTL)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; REQUEST PACKET STRUCTURE (Generic IOCTL)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Scan Lines available structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SUBLIST struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; RESULT BUFFER struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
