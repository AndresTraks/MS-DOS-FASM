;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; *** MACROS **** MACROS **** MACROS ****
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IF1                                     ;
;        %OUT .               ®MACROS  .INC¯
;ENDIF                                   ;
                                        ;
macro JUMP LBL
{
        local   A                       ;
.XCREF                                  ;
      if ~ defined LBL#_J               ; IS THIS FIRST INVOKATION
A:       JMP     LBL                    ;
      ELSE                              ;
         IF (LBL#_J >= $) | ($-LBL#_J > 126)
A:          JMP     LBL                 ; IS THE JUMP TOO FAR AWAY?
         ELSE                           ;
A:          JMP     LBL#_J              ; PERFORM SHORT JUMP
         end if ;
      end if ;
LBL#_J=A                                ;
.CREF                                   ;
} ;
.XCREF JUMP                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; *** MACROS **** MACROS **** MACROS ****
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
