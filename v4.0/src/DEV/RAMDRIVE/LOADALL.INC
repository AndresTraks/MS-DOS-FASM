; the layouts below read these, and an EQU is read where it stands
DEF_ACCESS	EQU	92H
DEF_LIMIT	EQU	0FFFFH

STRUC SEGREG_DESCRIPTOR SEG_BASE_=0, SEGREG_DESCRIPTOR_2_=0, SEG_ACCESS_=DEF_ACCESS, SEG_LIMIT_=DEF_LIMIT
{
.SEG_BASE	DW	SEG_BASE_
		DB	SEGREG_DESCRIPTOR_2_
.SEG_ACCESS	DB	SEG_ACCESS_
.SEG_LIMIT	DW	SEG_LIMIT_
}
match =SEGREG_DESCRIPTOR_LAID_OUT, SEGREG_DESCRIPTOR_LAID_OUT
{
    SEGREG_DESCRIPTOR_LAID_OUT equ 1
    virtual at 0
      SEGREG_DESCRIPTOR SEGREG_DESCRIPTOR 0, 0, 0, 0
      sizeof.SEGREG_DESCRIPTOR = $ - SEGREG_DESCRIPTOR
    end virtual
}
STRUC DTR_DESCRIPTOR DTR_BASE_=0, DTR_DESCRIPTOR_2_=0, DTR_DESCRIPTOR_3_=0, DTR_LIMIT_=0
{
.DTR_BASE	DW	DTR_BASE_
		DB	DTR_DESCRIPTOR_2_
		DB	DTR_DESCRIPTOR_3_
.DTR_LIMIT	DW	DTR_LIMIT_
}
match =DTR_DESCRIPTOR_LAID_OUT, DTR_DESCRIPTOR_LAID_OUT
{
    DTR_DESCRIPTOR_LAID_OUT equ 1
    virtual at 0
      DTR_DESCRIPTOR DTR_DESCRIPTOR 0, 0, 0, 0
      sizeof.DTR_DESCRIPTOR = $ - DTR_DESCRIPTOR
    end virtual
}
STRUC desc lim_0_15_=0, bas_0_15_=0, bas_16_23_=0, access_=0, gran_=0, bas_24_31_=0
{
.lim_0_15	dw	lim_0_15_ ; limit bits (0..15)
.bas_0_15	dw	bas_0_15_ ; base bits (0..15)
.bas_16_23	db	bas_16_23_ ; base bits (16..23)
.access		db	access_ ; access byte
.gran		db	gran_ ; granularity byte
.bas_24_31	db	bas_24_31_ ; base bits (24..31)
}
match =desc_LAID_OUT, desc_LAID_OUT
{
    desc_LAID_OUT equ 1
    virtual at 0
      desc desc 0, 0, 0, 0, 0, 0
      sizeof.desc = $ - desc
    end virtual
}
STRUC gdt_descriptor gdt_limit_=0, gdt_base_0_=0, gdt_base_2_=0
{
.gdt_limit	dw	gdt_limit_
.gdt_base_0	dw	gdt_base_0_
.gdt_base_2	dw	gdt_base_2_
}
match =gdt_descriptor_LAID_OUT, gdt_descriptor_LAID_OUT
{
    gdt_descriptor_LAID_OUT equ 1
    virtual at 0
      gdt_descriptor gdt_descriptor 0, 0, 0
      sizeof.gdt_descriptor = $ - gdt_descriptor
    end virtual
}
BREAK	<LOADALL descriptor caches>

DEF_ACCESS	EQU	92H
DEF_LIMIT	EQU	0FFFFH


;
; 386 Descriptor template
;

