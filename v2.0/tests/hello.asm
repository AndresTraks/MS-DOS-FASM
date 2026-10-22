        org     100h
        mov     dx,msg
        mov     ah,9
        int     21h
        int     20h
msg     db      "EXE2BIN MADE THIS COM FILE",13,10,"$"
