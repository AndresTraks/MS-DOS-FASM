        PAGE    ,132                            ; 
;       SCCSID = @(#)SHARELNK.asm 1.0 87/05/11
TITLE   SHARELNK LINK FIX ROUTINES - Routines to resolve SHARE externals
name    SHARELNK

.xlist
.xcref
include 'DOSSYM.INC'
include 'DEVSYM.INC'
.cref
.list

if SEGSEL = S_CODE
end if

include 'DOSSEG.ASM'


if SEGSEL = S_CODE
;        ASSUME  CS:dosgroup

;        PUBLIC  IRETT, SWAP_AREA_LEN, Hash_Temp
IRETT   DW      0
SWAP_AREA_LEN  DW  0
Hash_Temp   DW  0

procedure   LcritDevice
        NOP
EndProc LcritDevice,FAR

procedure   SETMEM
        NOP
EndProc SETMEM,FAR

procedure   SKIPONE
        NOP
EndProc SKIPONE,FAR

procedure   TwoEsc
        NOP
EndProc TwoEsc,FAR

procedure   STD_CON_STRING_INPUT_NO_ECHO$
        NOP
EndProc STD_CON_STRING_INPUT_NO_ECHO$,FAR

procedure   STD_CON_INPUT_NO_ECHO$
        NOP
EndProc STD_CON_INPUT_NO_ECHO$,FAR

procedure   INT2F
        NOP
EndProc   INT2F,FAR

procedure   Dup_PDB$
        NOP
EndProc   Dup_PDB$,FAR

procedure   LEAVEDOS
        NOP
EndProc   LEAVEDOS,FAR

procedure   GETCH
        NOP
EndProc   GETCH,FAR

procedure   COPYONE
        NOP
EndProc   COPYONE,FAR

procedure   SETDPB$
        NOP
EndProc     SETDPB$,FAR

procedure   CALL_ENTRY
        NOP
EndProc     CALL_ENTRY,FAR

procedure   EcritDisk
        NOP
EndProc     EcritDisk,FAR

procedure   COPYLIN
        NOP
EndProc     COPYLIN,FAR

procedure   LcritDisk
        NOP
EndProc     LcritDisk,FAR

procedure   QUIT
        NOP
EndProc     QUIT,FAR

procedure   BackSp
        NOP
EndProc     BackSp,FAR

procedure   DIVOV
        NOP
EndProc     DIVOV,FAR

procedure   Stay_resident
        NOP
EndProc     Stay_resident,FAR

procedure   CTRLZ
        NOP
EndProc     CTRLZ,FAR

procedure   EXITINS
        NOP
EndProc     EXITINS,FAR

procedure   OKCall
        NOP
EndProc     OKCall,FAR

procedure   SKIPSTR
        NOP
EndProc     SKIPSTR,FAR

procedure   ABSDWRT
        NOP
EndProc     ABSDWRT,FAR

procedure   BadCall
        NOP
EndProc     BadCall,FAR

procedure   REEDIT
        NOP
EndProc     REEDIT,FAR


procedure   INULDEV
        NOP
EndProc     INULDEV,FAR

procedure   ABSDRD
        NOP
EndProc     ABSDRD,FAR

procedure   SNULDEV
        NOP
EndProc     SNULDEV,FAR

procedure   CopyStr
        NOP
EndProc     CopyStr,FAR

procedure   EcritDevice
        NOP
EndProc     EcritDevice,FAR

procedure   COMMAND
        NOP
EndProc     COMMAND,FAR

procedure   ENTERINS
        NOP
EndProc     ENTERINS,FAR

procedure   DEVIOCALL2
        NOP
EndProc     DEVIOCALL2,FAR

procedure   FastOpenTable
        NOP
EndProc     FastOpenTable,FAR

procedure   Header
        NOP
EndProc     Header,FAR

procedure   SysInitTable
        NOP
EndProc     SysInitTable,FAR

procedure   FETCHI_TAG
        NOP
EndProc     FETCHI_TAG,FAR

procedure   IFS_DOSCALL
        NOP
EndProc     IFS_DOSCALL,FAR

procedure   KILNEW
        NOP
EndProc     KILNEW,FAR

procedure   Packet_Temp
        NOP
EndProc     Packet_Temp,FAR

procedure   SWAP_IN_DOS_LEN
        NOP
EndProc     SWAP_IN_DOS_LEN,FAR

procedure   SWAP_ALWAYS_AREA
        NOP
EndProc     SWAP_ALWAYS_AREA,FAR

procedure   SWAP_ALWAYS_AREA_LEN
        NOP
EndProc     SWAP_ALWAYS_AREA_LEN,FAR

procedure   SWAP_IN_DOS
        NOP
EndProc     SWAP_IN_DOS,FAR

end if
;    END
