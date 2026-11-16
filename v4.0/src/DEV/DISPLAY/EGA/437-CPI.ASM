;CODE    SEGMENT BYTE PUBLIC 'CODE'
;        ASSUME CS:CODE,DS:CODE

;IF1
;        %OUT    EGA.CPI creation file
;        %OUT    .
;        %OUT    CP SRC files:
;        %OUT    .
;        %OUT    .       CODE PAGE:  437
;ENDIF

EGA437: DW     LEN_437                  ; SIZE OF ENTRY HEADER
        DW     POST_EGA437,0            ; POINTER TO NEXT HEADER
        DW     1                        ; DEVICE TYPE
        DB     "EGA     "               ; DEVICE SUBTYPE ID
        DW     437                      ; CODE PAGE ID
        DW     3 DUP(0)                 ; RESERVED
        DW     DATA437,0                ; POINTER TO FONTS
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
LEN_437 =    ($-EGA437)               ;
                                        ;
DATA437:DW     1                        ; CART/NON-CART
        DW     3                        ; # OF FONTS
        DW     LEN_D437                 ; LENGTH OF DATA
D437:                                   ;
        DB     16,8                     ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        include '437-8X16.ASM'          ;
                                        ;
        DB     14,8                     ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        include '437-8X14.ASM'          ;
                                        ;
        DB     8,8                      ; CHARACTER BOX SIZE
        DB     0,0                      ; ASPECT RATIO (UNUSED)
        DW     256                      ; NUMBER OF CHARACTERS
                                        ;
        include '437-8X8.ASM'           ;
                                        ;
LEN_D437        = ($-D437)            ;
                                        ;
POST_EGA437     =     $               ;
                                        ;
;CODE    ENDS                            ;
;        END                             ;
