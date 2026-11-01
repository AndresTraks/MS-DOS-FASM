if SEGSEL = S_DATA

;
;*****************************************************************************
; Macro's
;*****************************************************************************
;


macro Define_Msg Message_Name
{
                                                ;
Create_Msg Message_Name,Message_Number,Handle,Sublist,Count,Class,Function,Input;AN000;
                                                ;
} ;                               ;AN000;

;-----------------------------------------------------------------------------

macro Create_Msg Parm1,Parm2,Parm3,Parm4,Parm5,Parm6,Parm7,Parm8
{

label Parm1 word                                ;                               ;AN000;
        dw      Parm2                           ;                               ;AN000;
        dw      Parm3                           ;                               ;AN000;
        dw      Parm4                           ;                               ;AN000;
        dw      Parm5                           ;                               ;AN000;
        db      Parm6                           ;                               ;AN000;
        db      Parm7                           ;                               ;AN000;
        dw      Parm8                           ;                               ;AN000;
} ;                               ;AN000;


;---------------------------                    ;                               ;AN001;
label Sublist_msg_parserr dword                 ;                               ;AN001;
                                                                                ;AN001;
        db              Sublist_Length          ;11                             ;AN001;
        db              Reserved                ;0                              ;AN001;
parsoff rw      1                               ;off                            ;AN001;
parseg  rw      1                               ;                               ;AN001;
        db              0                       ;USE PERCENT ZERO               ;AN001;
        db              Left_Align+Char_Field_ASCIIZ ;type of data              ;AN001;
        db              128                     ;max width                      ;AN001;
        db              1                       ;min width                      ;AN001;
        db              Blank                   ;pad char                       ;AN001;
;---------------------------                    ;                               ;AN001;

label Sublist_msg_exterror word                                                 ;AN001;

        db              Sublist_Length                                          ;AN001;
        db              Reserved                                                ;AN001;
label FileNamePointer dword                                                     ;AN001;
FileNameOffset  rw      1                                                       ;AN001;
FileNameSegment rw      1                                                       ;AN001;
        db              0                              ; SPECIAL %0 - Extended Errors only ;AN001;
        db              Left_Align+Char_Field_ASCIIZ                            ;AN001;
        db              132                                                     ;AN001;
        db              0                                                       ;AN001;
        db              Blank                                                   ;AN001;
;-----------------------------------------------------------------------------
;
;*****************************************************************************
; Message Retriever equates
;*****************************************************************************
;

Format_Msg              equ     'C'

N_A                     equ     0

Blank                   equ     " "
No_Function             equ     0

No_Input                equ     0


;
;*****************************************************************************
; Message Description Tables
;*****************************************************************************
;

;----------------------                         ;
Message_Number  = 1                             ;                               ;AN000;
Handle          = NO_HANDLE                     ;                               ;AN000;
Sublist         = NO_REPLACE                    ;                               ;AN000;
Count           = N_A                           ;                               ;AN000;
Class           = UTILITY_MSG_CLASS             ;                               ;AN000;
Function        = No_Input                      ;                               ;AN000;
Input           = N_A                           ;                               ;AN000;
        Define_Msg      msgBadDOSVersion        ;                               ;AN000;
;----------------------                         ;
Message_Number  = 2                             ;                               ;AN000;
Handle          = STDOUT                        ;                               ;AN000;
Sublist         = NO_REPLACE                    ;                               ;AN000;
Count           = N_A                           ;                               ;AN000;
Class           = UTILITY_MSG_CLASS             ;                               ;AN000;
Function        = No_Input                      ;                               ;AN000;
Input           = N_A                           ;                               ;AN000;
        Define_Msg      msgOutOfMemory          ;                               ;AN000;
;----------------------                         ;
Message_Number  = 3                             ;                               ;AN000;
Handle          = STDOUT                        ;                               ;AN000;
Sublist         = NO_REPLACE                    ;                               ;AN000;
Count           = N_A                           ;                               ;AN000;
Class           = UTILITY_MSG_CLASS             ;                               ;AN000;
Function        = No_Input                      ;                               ;AN000;
Input           = N_A                           ;                               ;AN000;
        Define_Msg      msgLoadFailure          ;                               ;AN000;
;----------------------                         ;
Message_Number  = 4                             ;                               ;AN000;
Handle          = STDOUT                        ;                               ;AN000;
Sublist         = NO_REPLACE                    ;                               ;AN000;
Count           = N_A                           ;                               ;AN000;
Class           = UTILITY_MSG_CLASS             ;                               ;AN000;
Function        = No_Input                      ;                               ;AN000;
Input           = N_A                           ;                               ;AN000;
        Define_Msg      msgNoAccess             ;                               ;AN000;
;----------------------                         ;
Message_Number  = 5                             ;                               ;AN000;
Handle          = STDOUT                        ;                               ;AN000;
Sublist         = NO_REPLACE                    ;                               ;AN000;
Count           = N_A                           ;                               ;AN000;
Class           = UTILITY_MSG_CLASS             ;                               ;AN000;
Function        = No_Input                      ;                               ;AN000;
Input           = N_A                           ;                               ;AN000;
        Define_Msg      msgNoConvert            ;                               ;AN000;
;----------------------                         ;
Message_Number  = 6                             ;                               ;AN000;
Handle          = STDOUT                        ;                               ;AN000;
Sublist         = NO_REPLACE                    ;                               ;AN000;
Count           = N_A                           ;                               ;AN000;
Class           = UTILITY_MSG_CLASS             ;                               ;AN000;
Function        = No_Input                      ;                               ;AN000;
Input           = N_A                           ;                               ;AN000;
        Define_Msg      msgNoFile               ;                               ;AN000;
;----------------------                         ;
Message_Number  = 7                             ;                               ;AN000;
Handle          = STDOUT                        ;                               ;AN000;
Sublist         = NO_REPLACE                    ;                               ;AN000;
Count           = N_A                           ;                               ;AN000;
Class           = UTILITY_MSG_CLASS             ;                               ;AN000;
Function        = No_Input                      ;                               ;AN000;
Input           = N_A                           ;                               ;AN000;
        Define_Msg      msgFileCreateError      ;                               ;AN000;
;----------------------                         ;
Message_Number  = 8                             ;                               ;AN000;
Handle          = STDOUT                        ;                               ;AN000;
Sublist         = NO_REPLACE                    ;                               ;AN000;
Count           = N_A                           ;                               ;AN000;
Class           = UTILITY_MSG_CLASS             ;                               ;AN000;
Function        = DOS_BUF_KEYB_INP              ;                               ;AN000;
Input           = INBUF                         ;                               ;AN000;
        Define_Msg      msgFixUp                ;                               ;AN000;
;----------------------                         ;
Message_Number  = 0                             ;                               ;AN001;
Handle          = STDERR                        ;                               ;AN001;
Sublist         = Sublist_msg_parserr        ;                               ;AN001;
Count           = 1                             ;                               ;AN001;
Class           = PARSE_ERR_CLASS               ;                               ;AN001;
Function        = No_Input                      ;                               ;AN001;
Input           = N_A                           ;                               ;AN001;
        Define_Msg      parse_error_msg         ;                               ;AN001;
;----------------------                         ;
Message_Number  = 0                             ;                               ;AN001;
Handle          = STDERR                        ;                               ;AN001;
Sublist         = Sublist_msg_exterror       ;                               ;AN001;
Count           = 1                             ;                               ;AN001;
Class           = EXT_ERR_CLASS                 ;                               ;AN001;
Function        = No_Input                      ;                               ;AN001;
Input           = N_A                           ;                               ;AN001;
        Define_Msg      extend_error_msg        ;                               ;AN001;
;----------------------                         ;
Message_Number  = 10                            ;                               ;AN000;
Handle          = STDOUT                        ;                               ;AN000;
Sublist         = NO_REPLACE                    ;                               ;AN000;
Count           = N_A                           ;                               ;AN000;
Class           = UTILITY_MSG_CLASS             ;                               ;AN000;
Function        = No_Input                      ;                               ;AN000;
Input           = N_A                           ;                               ;AN000;
        Define_Msg      msgNoDiskSpace          ;                               ;AN000;
;----------------------                         ;
Message_Number  = 12                            ;                               ;AN000;
Handle          = STDOUT                        ;                               ;AN000;
Sublist         = NO_REPLACE                    ;                               ;AN000;
Count           = N_A                           ;                               ;AN000;
Class           = UTILITY_MSG_CLASS             ;                               ;AN000;
Function        = No_Input                      ;                               ;AN000;
Input           = N_A                           ;                               ;AN000;
        Define_Msg      msgNoFileName           ;                               ;AN000;
;----------------------                         ;
end if
