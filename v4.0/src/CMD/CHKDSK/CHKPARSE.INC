STRUC Control Match_Flags_=0, Function_Flags_=0, Result_=0, Values_=0, Num_Keywords_=0, Keyword_=0
{
										;an000;bgb
.Match_Flags	dw	Match_Flags_ ;an000;bgb
.Function_Flags	dw	Function_Flags_ ;an000;bgb
.Result		dw	Result_ ;an000;bgb
.Values		dw	Values_ ;an000;bgb
.Num_Keywords	db	Num_Keywords_ ;an000;bgb
.Keyword 	db	Keyword_ ;an000;bgb
										;an000;bgb
}
match =Control_LAID_OUT, Control_LAID_OUT
{
    Control_LAID_OUT equ 1
    virtual at 0
      Control Control
      sizeof.Control = $ - Control
    end virtual
}
STRUC single_Return dftype_=0, Item_=0, Pointer_=0, drnum_stroff_=0, return_strseg_=0
{
.dftype		  db	  dftype_ ;AN000;SM				;an000;bgb
.Item		  db	  Item_ ;AN000;SM				;an000;bgb
.Pointer 	  dw	  Pointer_ ;AN000;SM				;an000;bgb
.drnum_stroff	  dw	  drnum_stroff_ ;AN000;SM				;an000;bgb
.return_strseg		 dw	 return_strseg_ ;an000;bgb
}
match =single_Return_LAID_OUT, single_Return_LAID_OUT
{
    single_Return_LAID_OUT equ 1
    virtual at 0
      single_Return single_Return
      sizeof.single_Return = $ - single_Return
    end virtual
}
STRUC Switch_Return Switch_Type_=0, Switch_Item_Tag_=0, Switch_Pointer_=0
{
.Switch_Type	db	Switch_Type_ ;				;an000;bgb;AN000;
.Switch_Item_Tag db	Switch_Item_Tag_ ;				;an000;bgb;AN000;
.Switch_Pointer	dw	Switch_Pointer_ ;				;an000;bgb;AN000;
.Switch_Debug	db	4 dup(0)						;an000;bgb
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
.Switch_Num_Type     db	    Switch_Num_Type_ ;				;an000;bgb    ;AN000;
.Switch_Num_Item_Tag db	    Switch_Num_Item_Tag_ ;				;an000;bgb    ;AN000;
.Switch_Num_Pointer  dw	    Switch_Num_Pointer_ ;				;an000;bgb    ;AN000;
.Switch_Number_Low   dw	    Switch_Number_Low_ ;				    ;AN0;an000;bgb00;
.Switch_Number_High  dw	    Switch_Number_High_ ;				    ;AN0;an000;bgb00;
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
.Switch_String_Type     db      Switch_String_Type_ ;			;an000;bgb	 ;AN000;
.Switch_String_Item_Tag db      Switch_String_Item_Tag_ ;			;an000;bgb	 ;AN000;
.Switch_String_Pointer  dw      Switch_String_Pointer_ ;			;an000;bgb	 ;AN000;
.Switch_String_Off	dw	Switch_String_Off_ ;				;an000;bgb;AN000;
.Switch_String_Seg	dw	Switch_String_Seg_ ;				;an000;bgb;AN000;
}
match =Switch_String_Return_LAID_OUT, Switch_String_Return_LAID_OUT
{
    Switch_String_Return_LAID_OUT equ 1
    virtual at 0
      Switch_String_Return Switch_String_Return
      sizeof.Switch_String_Return = $ - Switch_String_Return
    end virtual
}
										;an000;bgb
										;an000;bgb
										;an000;bgb
										;an000;bgb
if SEGSEL = S_DATA;an000;bgb     ;AN000;
										;an000;bgb
										;an000;bgb
;										;an000;bgb
;*****************************************************************************	;an000;bgb
; Publics									;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
;	Public	Drive_Letter_Buffer						;an000;bgb
;	Public	SwBuffer							;an000;bgb
;	Public	Switch_F_Buffer 						;an000;bgb
;	Public	FileSpec_Buffer 						;an000;bgb
;	public	buffer								;an000;bgb
;	public	sw_v, sw_f							;an000;bgb;an020;bgb
										;an000;bgb
;										;an000;bgb
;***************************************************************************	;an000;bgb
; Equates									;an000;bgb
;***************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
;Match Flags									;an000;bgb
										;an000;bgb
Numeric_Value		equ	8000h		;				;an000;bgb;AN000;
Signed_Numeric_Value	equ	4000h		;				;an000;bgb;AN000;
Simple_String		equ	2000h		;				;an000;bgb;AN000;
Date_String		equ	1000h		;				;an000;bgb;AN000;
Time_String		equ	0800h		;				;an000;bgb;AN000;
Complex_List		equ	0400h		;				;an000;bgb;AN000;
Quoted_String		equ	0080h		;				;an000;bgb;AN000;
Ignore_Colon		equ	0010h		;				;an000;bgb;AN000;
Repeats_Allowed 	equ	0002h		;				;an000;bgb;AN000;
Optional		equ	0001h		;				;an000;bgb;AN000;
Filespec		equ	0200h		;				;an000;bgb;AN000;
Drive_Only		equ	0100h		;				;an000;bgb;AN000;
										;an000;bgb
;Function_Flags 								;an000;bgb
										;an000;bgb
File_Table_Capitalize	equ	1		;				;an000;bgb;AN000;
Char_Table_Capitalize	equ	2		;				;an000;bgb;AN000;
Remove_Colon		equ	10h		;				;an000;bgb;AN000;
										;an000;bgb
;Extra delimeters and EOL							;an000;bgb
										;an000;bgb
Delimiters_Only 	equ	1		;				;an000;bgb;AN000;
EOL_Or_Delimiters	equ	2		;				;an000;bgb;AN000;
										;an000;bgb
Semi_Colon		equ	";"             ;                               ;an000;bgb;AN000;
Tab			equ	09h		;				;an000;bgb;AN000;
Colon			equ	":"             ;                               ;an000;bgb;AN000;
										;an000;bgb
										;an000;bgb
;Parse Errors									;an000;bgb
										;an000;bgb
No_Error		equ	0		;				;an000;bgb;AN000;
Too_Many_Operands	equ	1		;				;an000;bgb;AN000;
Operand_Missing 	equ	2		;				;an000;bgb;AN000;
Not_In_Switch_List	equ	3		;				;an000;bgb;AN000;
Not_In_Keyword_List	equ	4		;				;an000;bgb;AN000;
Out_Of_Range		equ	6		;				;an000;bgb;AN000;
Not_In_Value_List	equ	7		;				;an000;bgb;AN000;
Not_In_String_List	equ	8		;				;an000;bgb;AN000;
Syntax_Error		equ	9		;				;an000;bgb;AN000;
End_Of_Parse		equ	-1		;				;an000;bgb;AN000;
										;an000;bgb
;Return types									;an000;bgb
										;an000;bgb
Type_Reserved		equ	0		;				;an000;bgb;AN000;
Type_Number		equ	1		;				;an000;bgb;AN000;
Type_List_Index 	equ	2		;				;an000;bgb;AN000;
Type_String		equ	3		;				;an000;bgb;AN000;
Type_Complex		equ	4		;				;an000;bgb;AN000;
Type_Filespec		equ	5		;				;an000;bgb;AN000;
Type_Drive		equ	6		;				;an000;bgb;AN000;
Type_Date		equ	7		;				;an000;bgb;AN000;
Type_Time		equ	8		;				;an000;bgb;AN000;
Type_Quoted_String	equ	9		;				;an000;bgb;AN000;
										;an000;bgb
;Other										;an000;bgb
										;an000;bgb
None			equ	0		;				;an000;bgb;AN000;
No_Error		equ	0		;				;an000;bgb;AN000;
Switch_Found		equ	0FFFFh		;				;an000;bgb;AN000;
Range_Ok		equ	1		;				;an000;bgb;AN000;
Command_Line_Parms	equ	81h		;				;an000;bgb;AN000;
										;an000;bgb
;										;an000;bgb
;*****************************************************************************	;an000;bgb
; Parse Structures								;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
										;an000;bgb
;Drive_Letter_Return	 struc			 ;				;an000;bgb ;AN000;
;Drive_Type		 db	 0			 ;			;an000;bgb	   ;AN000;
;Drive_Item_Tag 	 db	 0			 ;			;an000;bgb	   ;AN000;
;Drive_Pointer		 dw	 0			 ;			;an000;bgb	   ;AN000;
;Drive_Number		 db	 0			 ;A=1, B=2, C=3 	;an000;bgb	   ;AN000;
;Drive_debug		 db	 8 dup(0)					;an000;bgb
;Drive_Letter_Return	 ends			 ;				;an000;bgb ;AN000;
;										;an000;bgb
;Filespec_Return struc				 ;AN000;SM			;an000;bgb
;Filespec_Type		 db	 0		 ;AN000;SM			;an000;bgb
;FileSpec_Item		 db	 0		 ;AN000;SM			;an000;bgb
;FileSpec_Pointer	 dw	 0		 ;AN000;SM			;an000;bgb
;Filespec_String_Off	 dw	 0		 ;AN000;SM			;an000;bgb
;FileSpec_String_Seg	 dw	 0						;an000;bgb
;FileSpec_Return ends								;an000;bgb
										;an000;bgb
										;an000;bgb
										;an000;bgb
										;an000;bgb
										;an000;bgb
										;an000;bgb
										;an000;bgb
;										;an000;bgb
;**************************************************************************	;an000;bgb
; Parse tables									;an000;bgb
;**************************************************************************	;an000;bgb
;										;an000;bgb
;Public	input_Table								;an000;bgb
label input_Table byte     ;				 ;AN000;;an000;bgb
										;an000;bgb
	dw	ext_table         ;Point to next level	      ;A;an000;bgbN000;
	db	Delimiters_Only 		;				;an000;bgb;AN000;
	db	1				;				;an000;bgb;AN000;
	db	Semi_Colon			;				;an000;bgb;AN000;
										;an000;bgb
label Drive_Table byte       ;an000;bgb;AN000;
						;				;an000;bgb
	dw	Drive_Control_Definition        ;Point to next level 	;an000;bgb   ;AN000;
	db	Delimiters_Only 		;				;an000;bgb;AN000;
	db	1				;				;an000;bgb;AN000;
	db	Semi_Colon			;				;an000;bgb;AN000;
										;an000;bgb
;										;an000;bgb
;**************************************************************************	;an000;bgb
;Define Positionals, Switches and Keywords					;an000;bgb
;**************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
;Public	ext_table								;an000;bgb
label ext_table byte        ;				;an000;bgb;AN000;
						;				;an000;bgb
	db	0,1			;up to one parm, either drive or file	;an000;bgb;an026;bgb
	dw	dfControl			     ;Pointer to control table	;an000;bgb     ;AN000;
	db	1				;1 switch  def			;an000;bgb;AN020;bgb
	dw	SwControl		;switch control block			;an000;bgb;AN020;bgb
	db	None				;No Keywords (maxk)		;an000;bgb;AN000;
						;				;an000;bgb
label Drive_Control_Definition byte     ;				;an000;bgb;AN000;
						;				;an000;bgb
	db	0,1				;Only drive letter positional	;an000;bgb;AN000;
	dw	dfControl		    ;Pointer to control table	    ;AN0;an000;bgb00;
	db	None				;0 switches			;an000;bgb;AN000;
	db	None				;No Keywords (maxk)		;an000;bgb;AN000;
						;				;an000;bgb
										;an000;bgb
										;an000;bgb
;										;an000;bgb
;**************************************************************************	;an000;bgb
; Define Positionals, Switches and Keywords					;an000;bgb
;**************************************************************************	;an000;bgb
;										;an000;bgb
;this is the new control block for both drive letters and filespecs		;an000;bgb
;Public	dfControl								;an000;bgb
label dfControl byte     ;				 ;AN000;;an000;bgb
	dw	Drive_Only+Filespec+Optional		   ;			;an000;bgb	     ;AN000;
	dw	None				;				;an000;bgb;AN000;
	dw	buffer	       ;			       ;AN000;	;an000;bgb
	dw	No_Value			;				;an000;bgb;AN000;
	db	None				;				;an000;bgb;AN000;
										;an000;bgb
;Public	SwControl							   ;an02;an000;bgb0;bgb
label SwControl byte     ;				 ;AN020;;an000;bgbbgb
	dw	None				;				;an000;bgb;AN000;
	dw	None				;				;an000;bgb;AN000;
	dw	SwBuffer		 ;				 ;AN000;;an000;bgb
	dw	No_Value							;an000;bgb   ;AN000;
	db	2				;				;an000;bgb;AN020;bgb
sw_v	db	"/V",0                          ;                               ;an000;bgb;AN020;bgb
sw_f	db	"/F",0                          ;                               ;an000;bgb;AN020;bgb
						;				;an000;bgb
										;an000;bgb
;										;an000;bgb
;*****************************************************************************	;an000;bgb
; Value lists									;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
No_Value	db	0			 ;				;an000;bgb;AN000;
										;an000;bgb
										;an000;bgb
;										;an000;bgb
;************************************************************************	;an000;bgb
; PARSE Return Buffers								;an000;bgb
;************************************************************************	;an000;bgb
;										;an000;bgb
; these buffers were replaced by a single buffer due to the parser bug		;an000;bgb
;Drive_Letter_Buffer	 Drive_Letter_Return	 <>  ;Example of structure	;an000;bgb ;AN000;
;FileSpec_Buffer	 FileSpec_Return	 <>  ;				;an000;bgb
SwBuffer		Switch_Return      ;				;an000;bgb;AN000;
Switch_F_Buffer 	Switch_Return      ;				;an000;bgb;AN000;
buffer			single_Return      ; new results buffer	;an000;bgb
end if ;				;an000;bgb;AN000;
										;an000;bgb
;										;an000;bgb
;*****************************************************************************	;an000;bgb
; SysParse Routines								;an000;bgb
;*****************************************************************************	;an000;bgb
;										;an000;bgb
										;an000;bgb
										;an000;bgb
if SEGSEL = S_CODE;an000;bgb
										;an000;bgb
FarSW	equ	Not_Include			;				;an000;bgb;AN000; ;AN000;
DateSW	equ	Not_Include			;				;an000;bgb;AN000;
TimeSW	equ	Not_Include			;				;an000;bgb;AN000;
FileSW	equ	Do_Include			;				;an000;bgb;AN000;
CAPSW	equ	Not_Include			;				;an000;bgb;AN000;
CmpxSW	equ	Not_Include			;				;an000;bgb;AN000;
NumSW	equ	Not_Include			;				;an000;bgb;AN000;
KeySW	equ	Not_Include			;				;an000;bgb;AN000;
SwSW	equ	Do_Include			;				;an000;bgb;AN000;
Val1SW	equ	Not_Include			;				;an000;bgb;AN000;
Val2SW	equ	Not_Include			;				;an000;bgb;AN000;
Val3SW	equ	Not_Include			;				;an000;bgb;AN000;
DrvSW	equ	Do_Include			;				;an000;bgb;AN000;
QusSW	equ	Not_Include			;				;an000;bgb;AN000;
BaseSW	equ	1 ;use ds as the default register				;an025;bgb
IncSW	equ	0 ;include psdata myself					;an028;bgb
end if ;an028;bgb


if SEGSEL = S_DATA;an028;bgb
include 'PSDATA.INC'      ;an028;bgb
end if ;an028;bgb

if SEGSEL = S_CODE;an028;bgb
pathlabl parser 								;an028;bgb
include 'PARSE.ASM'  ;AN000; 			;an028;bgb
pathlabl parser 								;an028;bgb
end if ;an000;bgb
