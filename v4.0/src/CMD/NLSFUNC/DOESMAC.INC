macro CallInstall name,mpx,fn,save,restore
{
macro BREAK subtitle
\{
	SUBTTL	subtitle
	PAGE
\}
.xcref	BREAK
IF INSTALLED
    match any$, save \{
	SaveReg <save>
    \}
	MOV	AX,(mpx SHL 8) + fn
	INT	2Fh
    match any$, restore \{
	RestoreReg  <restore>
    \}
ELSE
	invoke	name
end if
}

BREAK <SaveReg - save a set of registers>

macro SaveReg reglist
{
irp reg, reglist \{
	?stackdepth = ?stackdepth + 1
	PUSH	reg
\}
}
.xcref	SaveReg

BREAK <RestoreReg - unsave some registers>

macro RestoreReg reglist
{
irp reg, reglist \{
	?stackdepth = ?stackdepth - 1
	POP	reg
\}
}
.xcref	RestoreReg
