STRUC Exec_Block_Parms Segment_Env_=0, Offset_Command_=0, Segment_Command_=0, Offset_FCB1_=0, Segment_FCB1_=0, Offset_FCB2_=0, Segment_FCB2_=0
{
.Segment_Env dw	Segment_Env_ ;an038;bgb
.Offset_Command dw Offset_Command_ ;an038;bgb
.Segment_Command dw Segment_Command_ ;an038;bgb
.Offset_FCB1 dw	Offset_FCB1_ ;an038;bgb
.Segment_FCB1 dw Segment_FCB1_ ;an038;bgb
.Offset_FCB2 dw	Offset_FCB2_ ;an038;bgb
.Segment_FCB2 dw Segment_FCB2_ ;an038;bgb
}
match =Exec_Block_Parms_LAID_OUT, Exec_Block_Parms_LAID_OUT
{
    Exec_Block_Parms_LAID_OUT equ 1
    virtual at 0
      Exec_Block_Parms Exec_Block_Parms
      sizeof.Exec_Block_Parms = $ - Exec_Block_Parms
    end virtual
}
STRUC Media_ID Media_ID_Info_Level_=0, Media_ID_Serial_Number_=0
{
.Media_ID_Info_Level dw Media_ID_Info_Level_ ;AN000;
.Media_ID_Serial_Number dd Media_ID_Serial_Number_ ;AN000;
.Media_ID_Volume_Label db 11 dup(" ")                                            ;AN000;
.Media_ID_File_System db 8  dup(" ")                                             ;AN000;
}
match =Media_ID_LAID_OUT, Media_ID_LAID_OUT
{
    Media_ID_LAID_OUT equ 1
    virtual at 0
      Media_ID Media_ID
      sizeof.Media_ID = $ - Media_ID
    end virtual
}
STRUC Sublist_Struc Sublist_Size_=0, Sublist_Rsv_=0, Sublist_Offset_=0, Sublist_Segment_=0, Sublist_Number_=0, Sublist_Type_=0, Sublist_Max_=0, Sublist_Min_=0, Sublist_Char_=0
{
.Sublist_Size	db	Sublist_Size_ ;				;AN000;
.Sublist_Rsv	db	Sublist_Rsv_ ;				;AN000;
.Sublist_Offset	dw	Sublist_Offset_ ;				;AN000;
.Sublist_Segment dw	Sublist_Segment_ ;				;AN000;
.Sublist_Number	db	Sublist_Number_ ;				;AN000;
.Sublist_Type	db	Sublist_Type_ ;				;AN000;
.Sublist_Max	db	Sublist_Max_ ;				;AN000;
.Sublist_Min	db	Sublist_Min_ ;				;AN000;
.Sublist_Char	db	Sublist_Char_ ;				;AN000;
}
match =Sublist_Struc_LAID_OUT, Sublist_Struc_LAID_OUT
{
    Sublist_Struc_LAID_OUT equ 1
    virtual at 0
      Sublist_Struc Sublist_Struc
      sizeof.Sublist_Struc = $ - Sublist_Struc
    end virtual
}
STRUC A_DeviceParameters SpecialFunctions_=0, DeviceType_=0, DeviceAttributes_=0, NumberOfCylinders_=0, MediaType_=0, BytePerSector_=0, SectorsPerCluster_=0, ReservedSectors_=0, NumberOfFATs_=0, RootEntries_=0, TotalSectors_=0, MediaDescriptor_=0, SectorsPerFAT_=0, SectorsPerTrack_=0, Heads_=0, HiddenSectors_=0, Ext_Total_Sectors_=0
{

.SpecialFunctions	db	SpecialFunctions_ ;1  0
.DeviceType		db	DeviceType_ ;1  1
.DeviceAttributes	dw	DeviceAttributes_ ;2  2
.NumberOfCylinders	dw	NumberOfCylinders_ ;2  4
.MediaType		db	MediaType_ ;1  6
.BytePerSector		dw	BytePerSector_ ;2  7
.SectorsPerCluster	db	SectorsPerCluster_ ;
.ReservedSectors 	dw	ReservedSectors_
.NumberOfFATs		db	NumberOfFATs_
.RootEntries		dw	RootEntries_
.TotalSectors		dw	TotalSectors_
.MediaDescriptor 	db	MediaDescriptor_
.SectorsPerFAT		dw	SectorsPerFAT_
.SectorsPerTrack 	dw	SectorsPerTrack_
.Heads			dw	Heads_
.HiddenSectors		dd	HiddenSectors_
.Ext_Total_Sectors	dd	Ext_Total_Sectors_
.ReservedArea		rb      6

}
match =A_DeviceParameters_LAID_OUT, A_DeviceParameters_LAID_OUT
{
    A_DeviceParameters_LAID_OUT equ 1
    virtual at 0
      A_DeviceParameters A_DeviceParameters
      sizeof.A_DeviceParameters = $ - A_DeviceParameters
    end virtual
}
STRUC Relative_Sector_Buffer Start_Sector_Low_=0, Start_Sector_High_=0, Number_Sectors_=0, Buffer_Offset_=0, Buffer_Segment_=0
{

.Start_Sector_Low	dw	Start_Sector_Low_ ;Low word of RBA sector 	;AN000;
.Start_Sector_High	dw	Start_Sector_High_ ;High word of RBA sector	;AN000;
.Number_Sectors		dw	Number_Sectors_ ;Number of sectors		;AN000;
.Buffer_Offset		dw	Buffer_Offset_ ;Address of data buffer 	;AN000;
.Buffer_Segment		dw	Buffer_Segment_ ;				;AN000;

}
match =Relative_Sector_Buffer_LAID_OUT, Relative_Sector_Buffer_LAID_OUT
{
    Relative_Sector_Buffer_LAID_OUT equ 1
    virtual at 0
      Relative_Sector_Buffer Relative_Sector_Buffer
      sizeof.Relative_Sector_Buffer = $ - Relative_Sector_Buffer
    end virtual
}
STRUC XAL XAL_Tsize_=0, XAL_TCount_=0, XAL_LSize_=0, XAL_LCount_=0
{

.XAL_Tsize	dw	XAL_Tsize_ ;AN000;
.XAL_TCount	dw	XAL_TCount_ ;AN000;
.XAL_LSize	dw	XAL_LSize_ ;AN000;
.XAL_LCount	dw	XAL_LCount_ ;AN000;
.XAL_Data	rb      512-8        ;AN000;

}
match =XAL_LAID_OUT, XAL_LAID_OUT
{
    XAL_LAID_OUT equ 1
    virtual at 0
      XAL XAL
      sizeof.XAL = $ - XAL
    end virtual
}
STRUC DIRENT DIRATT_=0, DIRCP_=0, DIR_XA_=0, DIRATT2_=0, DIRTIM_=0, DIRDAT_=0, DIRCLUS_=0, DIRESIZ_=0
{
	Rb	7
	DB	?			;Drive
.DIRNAM	rb      11      ;
.DIRATT	DB	DIRATT_ ;
.DIRCP	DW	DIRCP_ ;				;AN000;
.DIR_XA	DW	DIR_XA_ ;				;AN000;
.DIRATT2 db	DIRATT2_ ;				;AN000;
.DIRRES	rb      5      ;				;AC000;
.DIRTIM	DW	DIRTIM_ ;
.DIRDAT	DW	DIRDAT_ ;
.DIRCLUS DW	DIRCLUS_ ;
.DIRESIZ DD	DIRESIZ_ ;
}
match =DIRENT_LAID_OUT, DIRENT_LAID_OUT
{
    DIRENT_LAID_OUT equ 1
    virtual at 0
      DIRENT DIRENT
      sizeof.DIRENT = $ - DIRENT
    end virtual
}
;fsexec  equ	 true			     ;				     ;	 ;an038;bgb  ;
FCB	EQU	5CH

String_Done equ 0
No_Error equ	0
chk_Error   equ     1
Stderr	equ	2

FALSE	EQU	0
TRUE	EQU	NOT FALSE

; NOTE WARNING DANGER.
; THIS EQU DEFINES AN OFFSET INTO THE SEARCH FCB OF THE LASTENT VALUE.
; ITS LOCATION MAY CHANGE FROM DOS VERSION TO DOS VERSION.
;2.0/2.1 value
;THISENT EQU	 17H			 ;Relative entry number of current entry
;3.0 value
THISENT EQU	14H				;Relative entry number of current entry


;Attribute bits

RDONLY	EQU	1
HIDDN	EQU	2
SYSTM	EQU	4
VOLIDA	EQU	8
ISDIR	EQU	10H
DRVCHAR EQU	":"
;
;*****************************************************************************
; Equates
;*****************************************************************************
;

Multiplex equ	2Fh				;				;AN000;
Set_Append_X equ 0B707h 			;				;AN000;;
Append_X equ	0B706h				;				;AN000;;
Append_X_Set equ 1				;				;AN000;
Append_Off equ	0				;				;AN000;
Append_ON equ	1				;				;AN000;


Disk_Error	equ	80h			;INT 24h bit clear if disk error;AN000;

NO	equ	0								;AN000;
YES	equ	not NO								;AN000;

Year_Mask	equ	0FE00h
Month_Mask	equ	01E0h
Day_Mask	equ	001Fh
Hour_Mask	equ	0F800h
Minute_Mask	equ	07E0h

Not_Include	equ	0
Do_Include	equ	1


YES_Found equ	1
NO_Found equ	0

ON	equ	1
OFF	equ	0

No_Ext_Attrib	equ	0							;AN000;
No_Entry	equ	0
XA_Chain	equ	84h			;Mark head of XA chain		;AN000;

if defined fsexec    ;an038;bgb
Len_FS_String_Buffer	equ	13						;an038;bgb
FAT12_File_System equ 01h							;an038;bgb;AN000;
FAT16_File_System equ 04h							;an038;bgb;AN000;
New_File_System equ 06h 							;an038;bgb;AN000;
end if

Bad_Exit	equ	0FFh			;Errorlevel = 0FFh		;AN000;

Net_Check equ	1200h								;AN000;
Assign_Check equ 8000h								;AN000;

Found_Yes equ	1								;AN000;
Found_No equ	0								;AN000;

Asciiz_End equ	0								;AN000;

Dir_Attribute	equ	10h
Vol_Attribute	equ	08h

Dir_Entries_Per_Sector	equ	512/32


Critical_Error_Fail	equ	3
Write_Protect	equ	0
Drive_Not_Ready equ	2

Blank	equ	" "                                                             ;AN000;

Head_Mask	equ	7Fh			;Mask to turn off head bit	;AN000;


;Limits
BIG_FAT_THRESHOLD equ 4086							;AN000;



;-------------------------------------------------------------------------------
; These are the data structures which we will need
;****************************************************************************
; Structures
;****************************************************************************
if defined fsexec    ;an038;bgb

end if ;an038;bgb









; MASM worked LENGTH out as the number of elements a variable was
; declared with and SIZE as the bytes they take up.  The arrays these
; ask about are all of bytes, so the two come to the same number.
ENTSIZ	EQU	sizeof.DIRENT

;-------------------------------------------------------------------------------

