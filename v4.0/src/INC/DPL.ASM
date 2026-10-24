;	SCCSID = @(#)dpl.asm	1.1 85/04/10
;	SCCSID = @(#)dpl.asm	1.1 85/04/10
STRUC DPL
{
.DPL_AX	DW	0	; AX register
.DPL_BX	DW	0	; BX register
.DPL_CX	DW	0	; CX register
.DPL_DX	DW	0	; DX register
.DPL_SI	DW	0	; SI register
.DPL_DI	DW	0	; DI register
.DPL_DS	DW	0	; DS register
.DPL_ES	DW	0	; ES register
.DPL_reserved DW 0	; Reserved
.DPL_UID DW	0	; User (Machine) ID (0 = local macine)
.DPL_PID DW	0	; Process ID (0 = local user PID)
}
match =DPL_LAID_OUT, DPL_LAID_OUT
{
    DPL_LAID_OUT equ 1
    virtual at 0
      DPL DPL
      sizeof.DPL = $ - DPL
    end virtual
}
