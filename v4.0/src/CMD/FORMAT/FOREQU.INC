STRUC Media_ID Media_ID_Info_Level_=0, Media_ID_Serial_Number_=0
{
.Media_ID_Info_Level dw Media_ID_Info_Level_
.Media_ID_Serial_Number dd Media_ID_Serial_Number_
.Media_ID_Volume_Label db 11 dup(" ")
.Media_ID_File_System db 8  dup(" ")
}
match =Media_ID_LAID_OUT, Media_ID_LAID_OUT
{
    Media_ID_LAID_OUT equ 1
    virtual at 0
      Media_ID Media_ID 0, 0
      sizeof.Media_ID = $ - Media_ID
    end virtual
}
STRUC Relative_Sector_Buffer Start_Sector_Low_=0, Start_Sector_High_=0, Number_Sectors_=0, Buffer_Offset_=0, Buffer_Segment_=0
{

.Start_Sector_Low        dw      Start_Sector_Low_ ;Low word of RBA sector         ;AN000;
.Start_Sector_High       dw      Start_Sector_High_ ;High word of RBA sector        ;AN000;
.Number_Sectors          dw      Number_Sectors_ ;Number of sectors              ;AN000;
.Buffer_Offset           dw      Buffer_Offset_ ;Address of data buffer         ;AN000;
.Buffer_Segment          dw      Buffer_Segment_ ;                               ;AN000;

}
match =Relative_Sector_Buffer_LAID_OUT, Relative_Sector_Buffer_LAID_OUT
{
    Relative_Sector_Buffer_LAID_OUT equ 1
    virtual at 0
      Relative_Sector_Buffer Relative_Sector_Buffer 0, 0, 0, 0, 0
      sizeof.Relative_Sector_Buffer = $ - Relative_Sector_Buffer
    end virtual
}
STRUC a_FileStructure fileHandle_=0, fileSizeInParagraphs_=0, fileSizeInBytes_=0, fileOffset_=0, fileStartSegment_=0, fileDate_=0, fileTime_=0
{
.fileHandle DW   fileHandle_
.fileSizeInParagraphs DW fileSizeInParagraphs_
.fileSizeInBytes DD fileSizeInBytes_
.fileOffset DD   fileOffset_
.fileStartSegment DW fileStartSegment_
.fileDate DW     fileDate_
.fileTime DW     fileTime_
}
match =a_FileStructure_LAID_OUT, a_FileStructure_LAID_OUT
{
    a_FileStructure_LAID_OUT equ 1
    virtual at 0
      a_FileStructure a_FileStructure 0, 0, 0, 0, 0, 0, 0
      sizeof.a_FileStructure = $ - a_FileStructure
    end virtual
}
;                                              ;                               ;     ;

NO      equ     0
YES     equ     (not NO)
FSExec  equ     NO                              ;an018; dms;conditional assembly
ShipDisk equ    NO                              ;an000; dms;ship disk flag

Boot_ID equ   0AA55h
DOS_Found equ   0

Not_Include     equ     0
Do_Include         equ     1

INIT    equ     0

FAT12_File_System equ 01h
FAT16_File_System equ 04h
New_File_System equ 06h

FS_String_Max_Length    equ     5

Paragraph_Size  equ     16                      ;                               ;AN005;
Len_FS_String_Buffer    equ     13

Net_Check equ   1200h
Assign_Check equ 8000h

Found_Yes equ   1
Found_No equ    0

Asciiz_End equ  0
DBCS    equ     81h
DBCS_Blank equ  40h
DBCS_Vector_Size equ 2
End_Of_Vector equ 0


Blank   equ     " "

Label_Length equ 11
CR      equ     13

DBCS_VECTOR equ NO

;Limits
BIG_FAT_THRESHOLD equ 4086

;-------------------------------------------------------------------------------





DRNUM   EQU     5CH



; Exit status defines
ExitOK  equ     0
ExitCtrlC equ   3
ExitFatal equ   4
ExitNo  equ     5


;-------------------------------------------------------------------------------
; These are the data structures which we will need






;Per system file data structure


;-------------------------------------------------------------------------------

LOGBOOTSECT equ 1
Set_Drv_Owner equ 0Fh                           ; IOCTL subfunction
Custom_Media equ 0F0H                           ; Media byte for custom format
Dual_8_Media equ 0FFh                           ; Dual sided 8 sectored
Single_8_Media equ 0FEh                         ; Single sided 8 sectored
Dual_9_Media equ 0FDh                           ; Dual sided 9 sectored
Single_9_Media equ 0FCh                         ; Single sided 9 sectored
Dual_15_Media equ 0F9h                          ; Dual sided 15 sectored
Fixed_Disk equ  0F8h                            ; Fixed Disk
Invalid_Drive   equ     000Fh                   ; Extended error 15
Max_Format_Size equ     0FFFFh                  ; Max bytes to Format           ;an015; dms;
Multi_Track_Format      equ     02h             ; Multi-track format            ;an015; dms;
Single_Track_Format     equ     00h             ; Single track format           ;an015; dms;
Select_Disk_Message     equ     0ADC1h          ; an016; dms;
