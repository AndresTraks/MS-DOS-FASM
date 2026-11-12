STRUC PACKET PACKLEN_=0, PACKCPID_=0
{
.PACKLEN 	DW   PACKLEN_ ;LENGTH OF PACKET IN BYTES =E	  2/16/KK
.PACKCPID	DW   PACKCPID_ ;CODE PAGE ID	      =E
.DBCS_EV 	DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
}
match =PACKET_LAID_OUT, PACKET_LAID_OUT
{
    PACKET_LAID_OUT equ 1
    virtual at 0
      PACKET PACKET 0, 0
      sizeof.PACKET = $ - PACKET
    end virtual
}
;; generic ioctl call data "packet" pointed to by DS:DX    =E


STD_CPLENGTH  equ	2
PK	      PACKET     ;CNS
