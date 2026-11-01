STRUC Exec_Block_Parms Segment_Env_=0, Offset_Command_=0, Segment_Command_=0, Offset_FCB1_=0, Segment_FCB1_=0, Offset_FCB2_=0, Segment_FCB2_=0
{
.Segment_Env	dw  Segment_Env_
.Offset_Command	dw  Offset_Command_
.Segment_Command dw  Segment_Command_
.Offset_FCB1	dw  Offset_FCB1_
.Segment_FCB1	dw  Segment_FCB1_
.Offset_FCB2	dw  Offset_FCB2_
.Segment_FCB2	dw  Segment_FCB2_

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
STRUC A_DeviceParameters SpecialFunctions_=0, DeviceType_=0, DeviceAttributes_=0, NumberOfCylinders_=0, MediaType_=0, BytePerSector_=0, SectorsPerCluster_=0, ReservedSectors_=0, NumberOfFATs_=0, RootEntries_=0, TotalSectors_=0, MediaDescriptor_=0, SectorsPerFAT_=0, SectorsPerTrack_=0, Heads_=0, HiddenSectors_=0, Ext_Total_Sectors_=0
{

.SpecialFunctions	db	SpecialFunctions_
.DeviceType		db	DeviceType_
.DeviceAttributes	dw	DeviceAttributes_
.NumberOfCylinders	dw	NumberOfCylinders_
.MediaType		db	MediaType_
.BytePerSector		dw	BytePerSector_
.SectorsPerCluster	db	SectorsPerCluster_
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
.Reserved_Area		rb      6

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
;fsexec equ true
if SEGSEL = S_CONST;AC000;bgb
Len_FS_ID_String equ 8			; length of fat_12 and fat_16 strings ;AN000;bgb
Command_Line_Length equ 128		; length of command line area  ;AN000;bgb
Len_FS_String_End equ 8 		; length of rec.exe + 0H   ;AN000;bgb
FALSE	EQU	0
;TRUE	 EQU	 -1

bdos	equ	21h
boot	equ	20h
aread	equ	25h
awrite	equ	26h


;IBMVER	EQU	false ; not for single drive system ;AC000;bgb
;KANJI	EQU	true  ; set this to true for assembling jap version ;AC000;bgb
tab	equ	09h
aread	equ	25h
awrite	equ	26h
fcb	equ	5ch
FCB1	equ	5Ch
FCB2	equ	6Ch
FCB_Filename_Length	equ	11

NO			equ	0						;AN000;
YES			equ	not NO						;AN000;


Not_Include		equ	0
Do_Include		equ	1

No_Ext_Attrib		equ	0						;AN000;
No_Entry		equ	0


FAT12_File_System	equ 01h 						;AN000;
FAT16_File_System	equ 04h 						;AN000;
New_File_System 	equ 06h 						;AN000;

Bad_Exit		equ	0FFh			;Errorlevel = 0FFh	;AN000;

Net_Check		equ   1200h						;AN000;
Assign_Check		equ 8000h						;AN000;

DBCS_Lead		equ	81h
DBCS_Blank		equ  40h
DBCS_Vector_Size	equ 2
End_Of_Vector		equ 0
Blank			equ	" "                                             ;AN000;

Found_Yes		equ   1 						;AN000;
Found_No		equ    0						;AN000;

Asciiz_End		equ  0							;AN000;

Dir_Attribute		equ	10h
Vol_Attribute		equ	08h

Dir_Entries_Per_Sector	equ	512/32


Critical_Error_Fail	equ	3
Write_Protect		equ	0
Drive_Not_Ready 	equ	2


Len_FS_String_Buffer	equ	13

;Limits
BIG_FAT_THRESHOLD	equ 4086						;AN000;

; equates from recinit
;***********************************************
Multiplex		equ   2Fh			      ; 		;AN000;
Set_Append_X		equ 0B707h			   ;			;AN000;;
Append_X		equ    0B706h			       ;		;AN000;;
Append_X_Set		equ 1				   ;			;AN000;
Append_Off		equ  0				     ;			;AN000;
Append_ON		equ   1 			      ; 		;AN000;
FCB1			equ	05ch		;				;AN000;bgb

String_Done equ 0
No_Error equ	0
rec_error   equ     1
Stderr	equ	2
Len_FS_String_Buffer equ 13



;-------------------------------------------------------------------------------
; DATA STRUCTURES
;-------------------------------------------------------------------------------




;-------------------------------------------------------------------------------
; media id
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; device parameters
;-------------------------------------------------------------------------------




;-------------------------------------------------------------------------------
; relative sector buffer
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; xal ????
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
end if
