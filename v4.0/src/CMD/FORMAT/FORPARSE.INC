STRUC Control Match_Flags_=0, Function_Flags_=0, Result_=0, Values_=0, Num_Keywords_=0, Keyword_=0
{

.Match_Flags	dw	Match_Flags_
.Function_Flags	dw	Function_Flags_
.Result		dw	Result_
.Values		dw	Values_
.Num_Keywords	db	Num_Keywords_
.Keyword 	db	Keyword_

}
match =Control_LAID_OUT, Control_LAID_OUT
{
    Control_LAID_OUT equ 1
    virtual at 0
      Control Control
      sizeof.Control = $ - Control
    end virtual
}
STRUC Drive_Letter_Return Drive_Type_=0, Drive_Item_Tag_=0, Drive_Pointer_=0, Drive_Number_=0
{

.Drive_Type	db	Drive_Type_ ;				;AN000;
.Drive_Item_Tag	db	Drive_Item_Tag_ ;				;AN000;
.Drive_Pointer	dw	Drive_Pointer_ ;				;AN000;
.Drive_Number	db	Drive_Number_ ;A=1, B=2, C=3			;AN000;
.Drive_debug	db	8 dup(0)

}
match =Drive_Letter_Return_LAID_OUT, Drive_Letter_Return_LAID_OUT
{
    Drive_Letter_Return_LAID_OUT equ 1
    virtual at 0
      Drive_Letter_Return Drive_Letter_Return
      sizeof.Drive_Letter_Return = $ - Drive_Letter_Return
    end virtual
}
STRUC Switch_Return Switch_Type_=0, Switch_Item_Tag_=0, Switch_Pointer_=0
{

.Switch_Type	db	Switch_Type_ ;				;AN000;
.Switch_Item_Tag db	Switch_Item_Tag_ ;				;AN000;
.Switch_Pointer	dw	Switch_Pointer_ ;				;AN000;
.Switch_Debug	db	4 dup(0)

}
match =Switch_Return_LAID_OUT, Switch_Return_LAID_OUT
{
    Switch_Return_LAID_OUT equ 1
    virtual at 0
      Switch_Return Switch_Return
      sizeof.Switch_Return = $ - Switch_Return
    end virtual
}
STRUC Switch_Num_Return Switch_Num_Type_=0, Switch_Num_Item_Tag_=0, Switch_Num_Pointer_=0, Switch_Number_Low_=0, Switch_Number_High_=0
{

.Switch_Num_Type     db	    Switch_Num_Type_ ;				    ;AN000;
.Switch_Num_Item_Tag db	    Switch_Num_Item_Tag_ ;				    ;AN000;
.Switch_Num_Pointer  dw	    Switch_Num_Pointer_ ;				    ;AN000;
.Switch_Number_Low   dw	    Switch_Number_Low_ ;				    ;AN000;
.Switch_Number_High  dw	    Switch_Number_High_ ;				    ;AN000;

}
match =Switch_Num_Return_LAID_OUT, Switch_Num_Return_LAID_OUT
{
    Switch_Num_Return_LAID_OUT equ 1
    virtual at 0
      Switch_Num_Return Switch_Num_Return
      sizeof.Switch_Num_Return = $ - Switch_Num_Return
    end virtual
}
STRUC Switch_String_Return Switch_String_Type_=0, Switch_String_Item_Tag_=0, Switch_String_Pointer_=0, Switch_String_Off_=0, Switch_String_Seg_=0
{

.Switch_String_Type     db      Switch_String_Type_ ;			       ;AN000;
.Switch_String_Item_Tag db      Switch_String_Item_Tag_ ;			       ;AN000;
.Switch_String_Pointer  dw      Switch_String_Pointer_ ;			       ;AN000;
.Switch_String_Off	dw	Switch_String_Off_ ;				;AN000;
.Switch_String_Seg	dw	Switch_String_Seg_ ;				;AN000;

}
match =Switch_String_Return_LAID_OUT, Switch_String_Return_LAID_OUT
{
    Switch_String_Return_LAID_OUT equ 1
    virtual at 0
      Switch_String_Return Switch_String_Return
      sizeof.Switch_String_Return = $ - Switch_String_Return
    end virtual
}
;



if SEGSEL = S_DATA

;
;*****************************************************************************
; Publics
;*****************************************************************************
;

;	Public	Drive_Letter_Buffer
;	Public	Switch_Buffer
;	Public	Switch_Num_Buffer
;	Public	Switch_String_Buffer


;
;***************************************************************************
; Equates
;***************************************************************************
;

;Match Flags

Numeric_Value		equ	8000h		;				;AN000;
Signed_Numeric_Value	equ	4000h		;				;AN000;
Simple_String		equ	2000h		;				;AN000;
Date_String		equ	1000h		;				;AN000;
Time_String		equ	0800h		;				;AN000;
Complex_List		equ	0400h		;				;AN000;
Filespec		equ	0200h		;				;AN000;
Drive_Only		equ	0100h		;				;AN000;
Quoted_String		equ	0080h		;				;AN000;
Ignore_Colon		equ	0010h		;				;AN000;
Repeats_Allowed 	equ	0002h		;				;AN000;
Optional		equ	0001h		;				;AN000;

;Function_Flags

File_Table_Capitalize	equ	1		;				;AN000;
Char_Table_Capitalize	equ	2		;				;AN000;
Remove_Colon		equ	10h		;				;AN000;

;Extra delimeters and EOL

Delimiters_Only 	equ	1		;				;AN000;
EOL_Or_Delimiters	equ	2		;				;AN000;

Semi_Colon		equ	";"             ;                               ;AN000;
Tab			equ	09h		;				;AN000;
Colon			equ	":"             ;                               ;AN000;


;Parse Errors

No_Error		equ	0		;				;AN000;
Too_Many_Operands	equ	1		;				;AN000;
Operand_Missing 	equ	2		;				;AN000;
Not_In_Switch_List	equ	3		;				;AN000;
Not_In_Keyword_List	equ	4		;				;AN000;
Out_Of_Range		equ	6		;				;AN000;
Not_In_Value_List	equ	7		;				;AN000;
Not_In_String_List	equ	8		;				;AN000;
Syntax_Error		equ	9		;				;AN000;
End_Of_Parse		equ	-1		;				;AN000;

;Return types

Type_Reserved		equ	0		;				;AN000;
Type_Number		equ	1		;				;AN000;
Type_List_Index 	equ	2		;				;AN000;
Type_String		equ	3		;				;AN000;
Type_Complex		equ	4		;				;AN000;
Type_Filespec		equ	5		;				;AN000;
Type_Drive		equ	6		;				;AN000;
Type_Date		equ	7		;				;AN000;
Type_Time		equ	8		;				;AN000;
Type_Quoted_String	equ	9		;				;AN000;

;Other

None			equ	0		;				;AN000;
No_Error		equ	0		;				;AN000;
Switch_Found		equ	0FFFFh		;				;AN000;
Range_Ok		equ	1		;				;AN000;
Command_Line_Parms	equ	81h		;				;AN000;

;
;*****************************************************************************
; Parse Structures
;*****************************************************************************
;







;
;**************************************************************************
; Parse tables
;**************************************************************************
;

IF FSExec					;conditionally assemble /FS:	;an018; dms;

label Switch_FS_Table byte        ;				;AN000;

	dw	Drive_Control_Definition	;Point to next level		;AN000;
	db	0				;				;AN000;

end if ;end conditional assembly /FS:	;an018; dms;

label Command_Line_Table byte   ;				;AN000;

	dw	Command_Control 		;Point to next level		;AN000;
	db	0				;				;AN000;

;
;**************************************************************************
;Define Positionals, Switches and Keywords
;**************************************************************************
;


IF FSExec					;conditionally assemble /FS:	;an018; dms;

label Drive_Control_Definition byte  ;				;AN000;

	db	1,1				;Only drive letter posistional	;AN000;
	dw	Positional_Control		;Pointer to control table	;AN000;
	db	1				;1 switch			;AN000;
	dw	Switch_FS_Control		;				;AN000;
	db	None				;No Keywords (maxk)		;AN000;

end if ;end conditional assembly /FS:	;an018; dms;

label Command_Control byte   ;				;AN000;

	db	1,1				;Only drive letter posistional	;AN000;
	dw	Positional_Control		;Pointer to control table	;AN000;
IF ShipDisk
	db	13				;if /Z switch needed		;an000; dms;
ELSE
	db	12				;				;AC001;
end if
	dw	Switch_V_Control		;Without quotes 		AN000;
	dw	Switch_S_Control		;				;AN000;
	dw	Switch_4_Control		;				;AN000;
	dw	Switch_1_Control		;				;AN000;
	dw	Switch_8_Control		;				;AN000;
	dw	Switch_B_Control		;				;AN000;
	dw	Switch_T_Control		;				;AN000;
	dw	Switch_N_Control		;				;AN000;
	dw	Switch_Select_Control		;				;AN000;
	dw	Switch_Backup_Control		;				;AN000;
	dw	Switch_Autotest_Control 	;				;AN000;
	dw	Switch_F_Control		;				;AC001;
IF ShipDisk
	dw	Switch_Z_Control		;1 sector/cluster switch	;an000; dms;
end if
	db	None				;No Keywords (maxk)		;AN000;

;
;**************************************************************************
;Control Tables
;**************************************************************************
;

label Positional_Control byte   ;				;AN000;

	dw	Drive_Only			;Match_Flag			;AN000;
	dw	None				;No function flags		;AN000;
	dw	Drive_Letter_Buffer		;Where it will be returned	;AN000;
	dw	No_Value			;No value ranges defined	;AN000;
	db	None				;No defined switches/keywords	;AN000;

IF FSExec					;conditionally assemble /FS:	;an018; dms;

label Switch_FS_Control byte
	dw	Simple_String			;/FS:xxxxx			;AN000;
	dw	File_Table_Capitalize		;Make it uppercase		;AN000;
	dw	Switch_String_Buffer		;				;AN000;
	dw	No_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/FS",0                         ;                               ;AN000;

end if ;end conditional assembly /FS:	;an018; dms;

label Switch_V_Control byte   ;				;AN000;

	dw	Simple_String+Quoted_String+Optional ;/v:xxxxxxxx		;AN000;
	dw	File_Table_Capitalize		;				;AN000;
	dw	Switch_String_Buffer		;				;AN000;
	dw	No_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/V",0                          ;                               ;AN000;

label Switch_S_Control byte   ;				;AN000;

	dw	None				;				;AN000;
	dw	None				;				;AN000;
	dw	Switch_Buffer			;				;AN000;
	dw	No_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/S",0                          ;                               ;AN000;

label Switch_4_Control byte   ;				;AN000;

	dw	None				;				;AN000;
	dw	None				;				;AN000;
	dw	Switch_Buffer			;				;AN000;
	dw	No_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/4",0                          ;                               ;AN000;

label Switch_1_Control byte   ;				;AN000;

	dw	None				;				;AN000;
	dw	None				;				;AN000;
	dw	Switch_Buffer			;				;AN000;
	dw	No_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/1",0                          ;                               ;AN000;

label Switch_8_Control byte   ;				;AN000;

	dw	None				;				;AN000;
	dw	None				;				;AN000;
	dw	Switch_Buffer			;				;AN000;
	dw	No_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/8",0                          ;                               ;AN000;

label Switch_B_Control byte   ;				;AN000;

	dw	None				;				;AN000;
	dw	None				;				;AN000;
	dw	Switch_Buffer			;				;AN000;
	dw	No_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/B",0                          ;                               ;AN000;

label Switch_T_Control byte   ;				;AN000;

	dw	Numeric_Value			;				;AN000;
	dw	None				;				;AN000;
	dw	Switch_Num_Buffer		;				;AN000;
	dw	Switch_T_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/T",0                          ;                               ;AN000;

label Switch_N_Control byte   ;				;AN000;

	dw	Numeric_Value			;				;AN000;
	dw	None				;				;AN000;
	dw	Switch_Num_Buffer		;				;AN000;
	dw	Switch_N_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/N",0                          ;                               ;AN000;

label Switch_Select_Control byte  ;				;AN000;

	dw	None				;				;AN000;
	dw	None				;				;AN000;
	dw	Switch_Buffer			;				;AN000;
	dw	No_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/SELECT",0                     ;                               ;AN000;

label Switch_Backup_Control byte  ;				;AN000;

	dw	None				;				;AN000;
	dw	None				;				;AN000;
	dw	Switch_Buffer			;				;AN000;
	dw	No_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/BACKUP",0                     ;                               ;AN000;

label Switch_Autotest_Control byte  ;				;AN000;

	dw	None				;				;AN000;
	dw	None				;				;AN000;
	dw	Switch_Buffer			;				;AN000;
	dw	No_Value			;				;AN000;
	db	1				;				;AN000;
	db	"/AUTOTEST",0                   ;                               ;AN000;

label Switch_F_Control byte   ;				;AN001;
	dw	Simple_String			;/F:xxxxx			;AN001;
	dw	File_Table_Capitalize		;Make it uppercase		;AN001;
	dw	Switch_String_Buffer		;				;AN001;
	dw	Switch_Size_Value		;				;AN001;
	db	1				;				;AN001;
	db	"/F",0                          ;                               ;AN001;

IF ShipDisk

label Switch_Z_Control byte   ;control structure for /Z	;an000; dms;
	dw	None				;				;an000; dms;
	dw	None				;				;an000; dms;
	dw	Switch_Buffer			;				;an000; dms;
	dw	No_Value			;				;an000; dms;
	db	1				;				;an000; dms;
	db	"/Z",0                          ;                               ;an000; dms;

end if

;
;************************************************************************
; PARSE Value Lists
;************************************************************************
;

label Switch_T_Value byte   ;				;AN000;

	db	1				;Range only			;ANOOO;
	db	1				;1 range			;ANOOO;
	db	Range_Ok			;Item_Tag			;ANOOO;
	dd	1				;1 is low bound 		;ANOOO;
	dd	1024				;2**10 is max			;AN000;

label Switch_N_Value byte   ;				;AN000;

	db	1				;Range only			;ANOOO;
	db	1				;1 range			;ANOOO;
	db	Range_Ok			;Item_Tag			;ANOOO;
	dd	1				;1 is low bound 		;ANOOO;
	dd	64				;2**6  is max			;AN000;

label Switch_Size_Value byte  ;				;AN001;

	db	3				;Look for strings		;AN001;
	db	0				;No ranges			;AN001;
	db	0				;No numerics			;AN001;
	db	27				;16 possible strings		;AN001;
	db	Size_160			;				;AN001;
	dw	String_160k_1			;/F:160 			;AN001;
	db	Size_160			;				;AN001;
	dw	String_160k_2			;/F:160K			;AN001;
	db	Size_160			;				;AN001;
	dw	String_160k_3			;/F:160KB			;AN001;
	db	Size_180			;				;AN001;
	dw	String_180k_1			;/F:180 			;AN001;
	db	Size_180			;				;AN001;
	dw	String_180k_2			;/F:180K			;AN001;
	db	Size_180			;				;AN001;
	dw	String_180k_3			;/F:180KB			;AN001;
	db	Size_320			;				;AN001;
	dw	String_320k_1			;/F:320 			;AN001;
	db	Size_320			;				;AN001;
	dw	String_320k_2			;/F:320K			;AN001;
	db	Size_320			;				;AN001;
	dw	String_320k_3			;/F:320KB			;AN001;
	db	Size_360			;				;AN001;
	dw	String_360k_1			;/F:360 			;AN001;
	db	Size_360			;				;AN001;
	dw	String_360k_2			;/F:360K			;AN001;
	db	Size_360			;				;AN001;
	dw	String_360k_3			;/F:360KB			;AN001;
	db	Size_720			;				;AN001;
	dw	String_720k_1			;/F:720 			;AN001;
	db	Size_720			;				;AN001;
	dw	String_720k_2			;/F:720K			;AN001;
	db	Size_720			;				;AN001;
	dw	String_720k_3			;/F:720KB			;AN001;
	db	Size_1200			;				;AN001;
	dw	String_1200k_1			;/F:1200			;AN001;
	db	Size_1200			;				;AN001;
	dw	String_1200k_2			;/F:1200K			;AN001;
	db	Size_1200			;				;AN001;
	dw	String_1200k_3			;/F:1200KB			;AN001;
	db	Size_1200			;				;AN001;
	dw	String_1200k_4			;/F:1.2 			;AN001;
	db	Size_1200			;				;AN001;
	dw	String_1200k_5			;/F:1.2M			;AN001;
	db	Size_1200			;				;AN001;
	dw	String_1200k_6			;/F:1.2MB			;AN001;
	db	Size_1440			;				;AN001;
	dw	String_1440k_1			;/F:1440			;AN001;
	db	Size_1440			;				;AN001;
	dw	String_1440k_2			;/F:1440K			;AN001;
	db	Size_1440			;				;AN001;
	dw	String_1440k_3			;/F:1440KB			;AN001;
	db	Size_1440			;				;AN001;
	dw	String_1440k_4			;/F:1.44			;AN001;
	db	Size_1440			;				;AN001;
	dw	String_1440k_5			;/F:1.44M			;AN001;
	db	Size_1440			;				;AN001;
	dw	String_1440k_6			;/F:1.44MB			;AN001;


label No_Value byte   ;				;AN000;
	db	0				;				;AN000;

;
;*****************************************************************************
; Data Area for value lists
;*****************************************************************************
;

;
;The following are a list of the allowed strings for the /F:xxxxx switch.
;

String_160k_1	db	"160"  ,Asciiz_End      ;                               ;AN001;
String_160k_2	db	"160K" ,Asciiz_End      ;                               ;AN001;
String_160k_3	db	"160KB" ,Asciiz_End      ;                               ;AN001;
String_180k_1	db	"180"  ,Asciiz_End      ;                               ;AN001;
String_180k_2	db	"180K" ,Asciiz_End      ;                               ;AN001;
String_180k_3	db	"180KB" ,Asciiz_End      ;                               ;AN001;
String_320k_1	db	"320"  ,Asciiz_End      ;                               ;AN001;
String_320k_2	db	"320K" ,Asciiz_End      ;                               ;AN001;
String_320k_3	db	"320KB" ,Asciiz_End      ;                               ;AN001;
String_360k_1	db	"360"  ,Asciiz_End      ;                               ;AN001;
String_360k_2	db	"360K" ,Asciiz_End      ;                               ;AN001;
String_360k_3	db	"360KB" ,Asciiz_End      ;                               ;AN001;
String_720k_1	db	"720"  ,Asciiz_End      ;                               ;AN001;
String_720k_2	db	"720K" ,Asciiz_End      ;                               ;AN001;
String_720k_3	db	"720KB" ,Asciiz_End      ;                               ;AN001;
String_1200k_1	db	"1200" ,Asciiz_End      ;                               ;AN001;
String_1200k_2	db	"1200K",Asciiz_End      ;                               ;AN001;
String_1200k_3	db	"1200KB",Asciiz_End      ;                               ;AN001;
String_1200k_4	db	"1.2" ,Asciiz_End      ;                               ;AN001;
String_1200k_5	db	"1.2M" ,Asciiz_End      ;                               ;AN001;
String_1200k_6	db	"1.2MB" ,Asciiz_End      ;                               ;AN001;
String_1440k_1	db	"1440" ,Asciiz_End      ;                               ;AN001;
String_1440k_2	db	"1440K",Asciiz_End      ;                               ;AN001;
String_1440k_3	db	"1440KB",Asciiz_End      ;                               ;AN001;
String_1440k_4	db	"1.44",Asciiz_End      ;                               ;AN001;
String_1440k_5	db	"1.44M",Asciiz_End      ;                               ;AN001;
String_1440k_6	db	"1.44MB",Asciiz_End      ;                               ;AN001;

;
;************************************************************************
; PARSE Return Buffers
;************************************************************************
;

Drive_Letter_Buffer	Drive_Letter_Return    ;Example of structure	;AN000;
Switch_Buffer		Switch_Return     ;				;AN000;
Switch_Num_Buffer	Switch_Num_Return    ;				;AN000;
Switch_String_Buffer	Switch_String_Return    ;				;AN000;

end if

;
;*****************************************************************************
; SysParse Routines
;*****************************************************************************
;


if SEGSEL = S_CODE
;	assume cs:code,ds:Data

FarSW	equ	Not_Include							;AN000;
DateSW	equ	Not_Include			;				;AN000;
TimeSW	equ	Not_Include			;				;AN000;
FileSW	equ	Do_Include			;				;AN000;
CAPSW	equ	Do_Include			;				;AN000;
CmpxSW	equ	Not_Include			;				;AN000;
NumSW	equ	Do_Include			;				;AN000;
KeySW	equ	Not_Include			;				;AN000;
SwSW	equ	Do_Include			;				;AN000;
Val1SW	equ	Do_Include			;				;AN000;
Val2SW	equ	Not_Include			;				;AN000;
Val3SW	equ	Do_Include			;				;AN001;
DrvSW	equ	Do_Include			;				;AN000;
QusSW	equ	Do_Include			;				;AN000;

include 'PARSE.ASM'  ;				;AN000;


end if
