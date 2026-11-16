; the layouts below read these, and an EQU is read where it stands
CINFOSIZE       EQU     sizeof.CINFO    ; SIZE OF COUNTRY INFO TABLE

STRUC CTRYSTR ESIZE_=0, CNTRYID_=0, CODPAGE_=0, RESV1_=0, RESV2_=0, CDPOINT_=0, CTRYSTR_7_=0
{
.ESIZE   DW      ESIZE_ ; SIZE OF ENTRY
.CNTRYID DW      CNTRYID_ ; COUNTRY ID
.CODPAGE DW      CODPAGE_ ; CODE PAGE ID
.RESV1   DW      RESV1_ ; RESERVED
.RESV2   DW      RESV2_ ; RESERVED
.CDPOINT DW      CDPOINT_ ; POINTER TO COUNTRY DATA
        DW      CTRYSTR_7_
}
match =CTRYSTR_LAID_OUT, CTRYSTR_LAID_OUT
{
    CTRYSTR_LAID_OUT equ 1
    virtual at 0
      CTRYSTR CTRYSTR 0, 0, 0, 0, 0, 0, 0
      sizeof.CTRYSTR = $ - CTRYSTR
    end virtual
}
STRUC CTRYDAT CTRYDAT_1_=0, CTRYDAT_2_=0, CTRYDAT_3_=0, CTRYDAT_4_=0, CTRYDAT_5_=0
{
        DW      CTRYDAT_1_
        DB      CTRYDAT_2_
        DB      CTRYDAT_3_
        DW      CTRYDAT_4_
        DW      CTRYDAT_5_
}
match =CTRYDAT_LAID_OUT, CTRYDAT_LAID_OUT
{
    CTRYDAT_LAID_OUT equ 1
    virtual at 0
      CTRYDAT CTRYDAT 0, 0, 0, 0, 0
      sizeof.CTRYDAT = $ - CTRYDAT
    end virtual
}
STRUC CINFO CINFO_1_=0, CINFO_2_=0, CINFO_3_=0, CINFO_4_=0, CINFO_5_=0, CINFO_6_=0, CINFO_7_=0, CINFO_8_=0, CINFO_9_=0, CINFO_10_=0, CINFO_11_=0, CINFO_12_=0, CINFO_13_=0, CINFO_14_=0, CINFO_15_=0, CINFO_16_=0, CINFO_17_=0, CINFO_18_=0, CINFO_19_=0, CINFO_20_=0, CINFO_21_=0, CINFO_22_=0
{
        DW      CINFO_1_ ; COUNTRY ID
        DW      CINFO_2_ ; CODE PAGE
        DW      CINFO_3_ ; DATE FORMAT
        DB      CINFO_4_ ; CURRENCY SYMBOL (5 BYTES)
        DB      CINFO_5_
        DB      CINFO_6_
        DB      CINFO_7_
        DB      CINFO_8_
        DB      CINFO_9_ ; 1000 SEPARATOR
        DB      CINFO_10_
        DB      CINFO_11_ ; DECIMAL SEPARATOR
        DB      CINFO_12_
        DB      CINFO_13_ ; DATE SEPARATOR
        DB      CINFO_14_
        DB      CINFO_15_ ; TIME SEPARATOR
        DB      CINFO_16_
        DB      CINFO_17_ ; CURRENCY FORMAT FLAGS
        DB      CINFO_18_ ; DIGITS IN CURRENCY
        DB      CINFO_19_ ; TIME FORMAT
        DD      CINFO_20_ ; RESERVED
        DB      CINFO_21_ ; DATA LIST SEPARATOR
        DB      CINFO_22_
        DW      5 DUP (0)               ; RESERVED
}
match =CINFO_LAID_OUT, CINFO_LAID_OUT
{
    CINFO_LAID_OUT equ 1
    virtual at 0
      CINFO CINFO 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.CINFO = $ - CINFO
    end virtual
}
STRUC CTABLE CTABLE_1_=0FFh, CTABLE_2_='CTYINFO', CTABLE_3_=CINFOSIZE
{
        DB      CTABLE_1_
        DB      CTABLE_2_
        DW      CTABLE_3_
}
match =CTABLE_LAID_OUT, CTABLE_LAID_OUT
{
    CTABLE_LAID_OUT equ 1
    virtual at 0
      CTABLE CTABLE 0, 'CTYINFO', 0
      sizeof.CTABLE = $ - CTABLE
    end virtual
}
;
;       include file for create cdi file
;
PTRCNT          EQU     1               ; NUMBER OF POINTERS
CIPTYPE         EQU     1               ; TYPE FOR COUNTRY INFO POINTER
; CNTRYCNT        EQU     18              ; NUMBER OF COUNTRIES SUPPORTED
CENTRYSIZE      equ     ((sizeof.CTRYSTR)-2) ; SIZE OF COUNTRY ENTRY
CDATASIZE       equ     ((sizeof.CTRYDAT)-2) ; SIZE OF COUNTRY DATA
HR12            EQU     0               ; 12 HOUR TIME FORMAT
HR24            EQU     1               ; 24 HOUR TIME FORMAT
;
; entry type symbols
;
SETCOUNTRYINFO  EQU     1
SETUCASE        EQU     2
SETLCASE        EQU     3
SETUCASEFILE    EQU     4
SETFILELIST     EQU     5
SETCOLLATE      EQU     6
SETDBCS         EQU     7

CDATAITEMS      equ     (SETDBCS - 1)	; NUMBER OF ENTRIES IN COUNTRY DATA

;
; country id's
;
CID_UK          EQU     044             ; United Kingdom
CID_FR          EQU     033             ; France
CID_GR          EQU     049             ; Germany
CID_SP          EQU     034             ; Spain
CID_IT          EQU     039             ; Italy
CID_SV          EQU     046             ; Sweden
CID_AFE         EQU     061             ; International English
CID_DK          EQU     045             ; Denmark
CID_SW          EQU     041             ; Switzerland
CID_NO          EQU     047             ; Norway
CID_NL          EQU     031             ; Netherlands
CID_BE          EQU     032             ; Belgium
CID_FI          EQU     358             ; Finland
CID_US          EQU     001             ; United States
CID_IS          EQU     972             ; Israel
CID_CA          EQU     002             ; Canadian French
CID_AS          EQU     785             ; Area South (Saudi Arabia)
CID_PO          EQU     351             ; Portugal
CID_LA          EQU     003             ; Latin America
CID_JP          EQU     081             ; Japan         2/17/KK
CID_KO          EQU     082             ; Korea         2/17/KK
CID_PR          EQU     086             ; PRC           2/17/KK
CID_TA          EQU     088             ; Taiwan        2/17/KK
CID_XX          EQU     000             ; Dummy entry
;
; country code pages
;
CP_UK           EQU     437
CP_FR           EQU     437
CP_GR           EQU     437
CP_SP           EQU     437
CP_IT           EQU     437
CP_SV           EQU     437
CP_AFE          EQU     437
CP_DA           EQU     865
CP_SW           EQU     437
CP_NO           EQU     865
CP_NL           EQU     437
CP_BE           EQU     437
CP_FI           EQU     437
CP_US           EQU     437
CP_IS           EQU     862
CP_CA           EQU     863
CP_AS           EQU     864
CP_PO           EQU     860
CP_JP           EQU     932             ; Japan         2/17/KK
CP_KO           EQU     934             ; Korea         2/17/KK
CP_PR           EQU     936             ; PRC           2/17/KK
CP_TA           EQU     938             ; Taiwan        2/17/KK
;
;       date formats
;
DATE_MDY        EQU     0
DATE_DMY        EQU     1
DATE_YMD        EQU     2
;

macro CTRYENT PARMS
{
          local anon$
          anon$ CTRYSTR PARMS
CNTRYCNT = CNTRYCNT+1
}
;
;
;
CINFOSIZE       EQU     sizeof.CINFO    ; SIZE OF COUNTRY INFO TABLE
;
;

