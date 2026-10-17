
FALSE   =     0
TRUE    =     -1


macro Message mname,text
{
mname       DB  text
mname#Len   DW  $-mname
}


IBMJAPVER =   FALSE

if SEGSEL = S_CONST

; only this message must be terminated with a $
BADVER  DB      "Incorrect DOS version",13,10,"$"

        IF      IBMJAPVER
        Message BadDisk,"Destination disk cannot be booted"
        end if

        Message BadDrv,"Invalid drive specification"
        Message BadParm,"Invalid parameter"
        Message NoDest,"No room for system on destination disk"
        Message BadSiz,"Incompatible system size"
        Message Done,"System transferred"

GETSYS      DB      "Insert system disk in drive "
SYSDRV      DB      "A",13,10
            DB      "and strike any key when ready",13,10
GetSysLen   DW  GetSysLen-GETSYS

end if

if SEGSEL = S_DATA
end if

if SEGSEL = S_CODE
        ASSUME  CS:DG,DS:DG,ES:DG,SS:DG

end if
