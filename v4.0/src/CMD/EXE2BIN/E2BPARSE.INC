


if SEGSEL = S_DATA



;
;***************************************************************************
; Equates
;***************************************************************************
;

;Match Flags

Numeric_Value           equ     8000h           ;                               ;AN000;
Signed_Numeric_Value    equ     4000h           ;                               ;AN000;
Simple_String           equ     2000h           ;                               ;AN000;
Date_String             equ     1000h           ;                               ;AN000;
Time_String             equ     0800h           ;                               ;AN000;
Complex_List            equ     0400h           ;                               ;AN000;
Filespec                equ     0200h           ;                               ;AN000;
Drive_Only              equ     0100h           ;                               ;AN000;
Quoted_String           equ     0080h           ;                               ;AN000;
Ignore_Colon            equ     0010h           ;                               ;AN000;
Repeats_Allowed         equ     0002h           ;                               ;AN000;
Optional                equ     0001h           ;                               ;AN000;

;Function_Flags

File_Table_Capitalize   equ     1               ;                               ;AN000;

;Result buffer type returned
rb_Number               equ     1
rb_List_Index           equ     2
rb_String               equ     3
rb_Complex              equ     4
rb_Filespec             equ     5
rb_Drive                equ     6
rb_Date                 equ     7
rb_Time                 equ     8
rb_Quoted_String        equ     9


;Extra delimeters and EOL

Delimiters_Only         equ     1               ;                               ;AN000;
EOL_Or_Delimiters       equ     2               ;                               ;AN000;

Semi_Colon              equ     ";"             ;                               ;AN000;
Tab                     equ     09h             ;                               ;AN000;
Colon1                  equ     ":"             ;                               ;AN000;
NUL                     equ     "0"

;Parse Errors

No_Error                equ     0               ;                               ;AN000;
Too_Many_Operands       equ     1               ;                               ;AN000;
Operand_Missing         equ     2               ;                               ;AN000;
Not_In_Switch_List      equ     3               ;                               ;AN000;
Not_In_Keyword_List     equ     4               ;                               ;AN000;
Out_Of_Range            equ     6               ;                               ;AN000;
Not_In_Value_List       equ     7               ;                               ;AN000;
Not_In_String_List      equ     8               ;                               ;AN000;
Syntax_Error            equ     9               ;                               ;AN000;
End_Of_Parse            equ     -1              ;                               ;AN000;

;Other

None                    equ     0               ;                               ;AN000;
No_Error                equ     0               ;                               ;AN000;
Switch_Found            equ     0FFFFh          ;                               ;AN000;
Range_Ok                equ     1               ;                               ;AN000;
Command_Line_Parms      equ     81h             ;                               ;AN000;

;
;*****************************************************************************
; Parse Structures
;*****************************************************************************
;

STRUC Control Match_Flags_=0, Function_Flags_=0, Result_=0, Values_=0, Num_Keywords_=0, Keyword_=0
{

.Match_Flags     dw      Match_Flags_
.Function_Flags  dw      Function_Flags_
.Result          dw      Result_
.Values          dw      Values_
.Num_Keywords    db      Num_Keywords_
.Keyword         db      Keyword_

}
match =Control_LAID_OUT, Control_LAID_OUT
{
    Control_LAID_OUT equ 1
    virtual at 0
      Control Control
      sizeof.Control = $ - Control
    end virtual
}

STRUC File_Name_Return Drive_Type_=0, Drive_Item_Tag_=0, Synonym_=0, String_Value_ptr_=0
{

.Drive_Type      db      Drive_Type_ ;                               ;AN000;
.Drive_Item_Tag  db      Drive_Item_Tag_ ;                               ;AN000;
.Synonym         dw      Synonym_ ;                               ;AN000;
.String_Value_ptr db     String_Value_ptr_ ;File Name                      ;AN000;

}
match =File_Name_Return_LAID_OUT, File_Name_Return_LAID_OUT
{
    File_Name_Return_LAID_OUT equ 1
    virtual at 0
      File_Name_Return File_Name_Return
      sizeof.File_Name_Return = $ - File_Name_Return
    end virtual
}


;
;**************************************************************************
; Parse tables
;**************************************************************************
;

label Command_Line_Table byte                      ;                               ;AN000;

        dw      Command_Control                 ;Point to next level            ;AN000;
        db      Delimiters_Only                 ;                               ;AN000;
        db      1                               ;                               ;AN000;
        db      Semi_Colon                      ;                               ;AN000;


;
;**************************************************************************
; Define Positionals, Switches and Keywords
;**************************************************************************
;

label Command_Control byte                      ;                               ;AN000;

        db      1,2                             ;File names Positional (1 required) ;AN000;
        dw      Positional_Control1             ;Pointer to control table       ;AN000;
        dw      Positional_Control2             ;Pointer to control table       ;AN000;
        db      None                            ;no switches                    ;AN000;
        db      None                            ;No Keywords (maxk)             ;AN000;

;
;**************************************************************************
;Control Tables
;**************************************************************************
;

label Positional_Control1 byte                  ;                               ;AN000;

        dw      Filespec                        ;Match_Flag                     ;AN000;
        dw      File_Table_Capitalize           ;No function flags              ;AN000;
        dw      File_name_Buffer1               ;Where it will be returned      ;AN000;
        dw      No_Value                        ;No value ranges defined        ;AN000;
        db      None                            ;No defined switches/keywords   ;AN000;

label Positional_Control2 byte                  ;                               ;AN000;

        dw      Filespec+Optional               ;Match_Flag                     ;AN000;

        dw      File_Table_Capitalize           ;No function flags              ;AN000;
        dw      File_name_Buffer2               ;Where it will be returned      ;AN000;
        dw      No_Value                        ;No value ranges defined        ;AN000;
        db      None                            ;No defined switches/keywords   ;AN000;

label No_Value byte                             ;                               ;AN000;
        db      0                               ;                               ;AN000;

;
;************************************************************************
; PARSE Return Buffers
;************************************************************************
;
label File_name_Buffer1 byte                    ;                               ;AN000;

rb_type1       db      0                        ;type returned                  ;AN000;
rb_item_tag1   db      0                        ;matched item tag               ;AN000;
rb_synonym1    dw      0                        ;found synonyms                 ;AN000;
rb_string1_off dw      0                        ;Offset of string               ;AN000;
rb_string1_seg dw      0                        ;Offset of string               ;AN000;

label File_name_Buffer2 byte                    ;                               ;AN000;

rb_type2       db      0                        ;type returned                  ;AN000;
rb_item_tag2   db      0                        ;matched item tag               ;AN000;
rb_synonym2    dw      0                        ;found synonyms                 ;AN000;
rb_string2_off dw      0                        ;Offset of string               ;AN000;
rb_string2_seg dw      0                        ;Offset of string               ;AN000;

end if

