; the layouts below read these, and an EQU is read where it stands
GDT_LEN         equ     (512 * 8)	; 512 entries total

STRUC BPSTACK BP_ES_=0, BP_DI_=0, BPSTACK_3_=0, BP_SI_=0, BPSTACK_5_=0, BP_BP_=0, BPSTACK_7_=0, BP_PASP_=0, BP_PSP2_=0, BP_BX_=0, BPSTACK_11_=0, BP_DX_=0, BPSTACK_13_=0, BP_CX_=0, BPSTACK_15_=0, BP_AX_=0, BPSTACK_17_=0, BP_DS_=0, BP_EX_=0, BP_EC_=0, BPSTACK_21_=0, BP_IP_=0, BP_IP2_=0, BP_CS_=0, BP_CS2_=0, BP_FL_=0, BP_FL2_=0, BP_SP_=0, BP_SP2_=0, BP_SS_=0, BP_SS2_=0, BP_VMES_=0, BP_VME2_=0, BP_VMDS_=0, BPSTACK_35_=0, BP_VMFS_=0, BPSTACK_37_=0, BP_VMGS_=0, BPSTACK_39_=0, BP_STK_=0
{

.BP_ES   DW      BP_ES_ ; Interrptee's ES
.BP_DI   DW      BP_DI_ ; Interruptee's EDI (32 bit DI)
        DW      BPSTACK_3_ ;
.BP_SI   DW      BP_SI_ ; Interruptee's ESI (32 bit SI)
        DW      BPSTACK_5_ ;
.BP_BP   DW      BP_BP_ ; Interruptee's EBP (32 bit BP)
        DW      BPSTACK_7_ ;
.BP_PASP DW      BP_PASP_ ; Interruptee's ESP (32 bit SP)
.BP_PSP2 DW      BP_PSP2_ ;   (ESP as it was before the PUSHA)
.BP_BX   DW      BP_BX_ ; Interruptee's EBX (32 bit BX)
        DW      BPSTACK_11_ ;
.BP_DX   DW      BP_DX_ ; Interruptee's EDX (32 bit DX)
        DW      BPSTACK_13_ ;
.BP_CX   DW      BP_CX_ ; Interruptee's ECX (32 bit CX)
        DW      BPSTACK_15_ ;
.BP_AX   DW      BP_AX_ ; Interruptee's EAX (32 bit AX)
        DW      BPSTACK_17_ ;
.BP_DS   DW      BP_DS_ ; Interruptee's DS
.BP_EX   DW      BP_EX_ ; Exception ID
.BP_EC   DW      BP_EC_ ; Error Code
        DW      BPSTACK_21_

; The following values are placed on our stack by the 80386

.BP_IP   DW      BP_IP_ ; Interruptee's EIP (32 bit IP)
.BP_IP2  DW      BP_IP2_
.BP_CS   DW      BP_CS_ ; Interruptee's CS (16 bit CS plus 16 bit trash)
.BP_CS2  DW      BP_CS2_
.BP_FL   DW      BP_FL_ ; Interruptee's flags (32 bits)
.BP_FL2  DW      BP_FL2_
.BP_SP   DW      BP_SP_ ; Interruptee's ESP - saved on an inter-level
.BP_SP2  DW      BP_SP2_ ;   interrupt
.BP_SS   DW      BP_SS_ ; Interruptee's SSP - also saved on inter-level
.BP_SS2  DW      BP_SS2_ ;   interrupt
.BP_VMES DW      BP_VMES_ ; Virtual mode ES
.BP_VME2 DW      BP_VME2_
.BP_VMDS DW      BP_VMDS_ ; Virtual mode DS
        DW      BPSTACK_35_
.BP_VMFS DW      BP_VMFS_ ; Virtual mode FS
        DW      BPSTACK_37_
.BP_VMGS DW      BP_VMGS_ ; Virtual mode GS
        DW      BPSTACK_39_
.BP_STK  DW      BP_STK_ ; The rest of the stack

}
match =BPSTACK_LAID_OUT, BPSTACK_LAID_OUT
{
    BPSTACK_LAID_OUT equ 1
    virtual at 0
      BPSTACK BPSTACK 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.BPSTACK = $ - BPSTACK
    end virtual
}
STRUC TSS386 TSS386_1_=0, ETSS_BACK_LINK_=0, ETSS_SP0_=0, TSS386_4_=0, ETSS_SS0_=0, TSS386_6_=0, ETSS_SP1_=0, ETSS_SS1_=0, TSS386_9_=0, ETSS_SP2_=0, ETSS_SS2_=0, TSS386_12_=0, ETSS_CR3_=0, ETSS_IP_=0, TSS386_15_=0, ETSS_FL_=0, ETSS_FL2_=0, ETSS_AX_=0, ETSS_CX_=0, ETSS_DX_=0, ETSS_BX_=0, ETSS_SP_=0, TSS386_23_=0, ETSS_BP_=0, ETSS_SI_=0, ETSS_DI_=0, ETSS_ES_=0, TSS386_28_=0, ETSS_CS_=0, TSS386_30_=0, ETSS_SS_=0, TSS386_32_=0, ETSS_DS_=0, TSS386_34_=0, ETSS_FS_=0, TSS386_36_=0, ETSS_GS_=0, TSS386_38_=0, ETSS_LDT_=0, TSS386_40_=0, ETSS_TRAP_=0, ETSS_BM_OFFSET_=0, ETSS_AVL_=0
{
                DW      TSS386_1_ ; Intel reserved
.ETSS_BACK_LINK  DW      ETSS_BACK_LINK_ ; Back link to previous TSS
.ETSS_SP0        DW      ETSS_SP0_ ; ESP for privilege level 0
                DW      TSS386_4_
.ETSS_SS0        DW      ETSS_SS0_ ; SS for privilege level 0
                DW      TSS386_6_ ; Intel reserved
.ETSS_SP1        DD      ETSS_SP1_ ; ESP for privilege level 1
.ETSS_SS1        DW      ETSS_SS1_ ; SS for privilege level 1
                DW      TSS386_9_ ; Intel reserved
.ETSS_SP2        DD      ETSS_SP2_ ; ESP for privilege level 2
.ETSS_SS2        DW      ETSS_SS2_ ; SS for privilege level 2
                DW      TSS386_12_ ; Intel reserved
.ETSS_CR3        DD      ETSS_CR3_ ; CR3 - Page directory base register
.ETSS_IP         DW      ETSS_IP_ ; Task's EIP
                DW      TSS386_15_
.ETSS_FL         DW      ETSS_FL_ ; Task's Eflags
.ETSS_FL2        DW      ETSS_FL2_
.ETSS_AX         DD      ETSS_AX_ ; Task's EAX
.ETSS_CX         DD      ETSS_CX_ ; Task's ECX
.ETSS_DX         DD      ETSS_DX_ ; Task's EDX
.ETSS_BX         DD      ETSS_BX_ ; Task's EBX
.ETSS_SP         DW      ETSS_SP_ ; Task's ESP
                DW      TSS386_23_
.ETSS_BP         DD      ETSS_BP_ ; Task's EBP
.ETSS_SI         DD      ETSS_SI_ ; Task's ESI
.ETSS_DI         DD      ETSS_DI_ ; Task's EDI
.ETSS_ES         DW      ETSS_ES_ ; Task's ES
                DW      TSS386_28_ ; Intel reserved
.ETSS_CS         DW      ETSS_CS_ ; Task's CS
                DW      TSS386_30_ ; Intel reserved
.ETSS_SS         DW      ETSS_SS_ ; Task's SS
                DW      TSS386_32_ ; Intel reserved
.ETSS_DS         DW      ETSS_DS_ ; Task's DS
                DW      TSS386_34_ ; Intel reserved
.ETSS_FS         DW      ETSS_FS_ ; Task's FS
                DW      TSS386_36_ ; Intel reserved
.ETSS_GS         DW      ETSS_GS_ ; Task's GS
                DW      TSS386_38_ ; Intel reserved
.ETSS_LDT        DW      ETSS_LDT_ ; Selector for task's LDT
                DW      TSS386_40_ ; Intel reserved
.ETSS_TRAP       DW      ETSS_TRAP_ ; Trap bit - bit 0 (IBM bit 15)
.ETSS_BM_OFFSET  DW      ETSS_BM_OFFSET_ ; I/O bit map base
.ETSS_AVL        DD      ETSS_AVL_
}
match =TSS386_LAID_OUT, TSS386_LAID_OUT
{
    TSS386_LAID_OUT equ 1
    virtual at 0
      TSS386 TSS386 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.TSS386 = $ - TSS386
    end virtual
}
STRUC GDT_DEF UNUSED_ENTRY_=0, GDT_PTR_=0, MON_IDT_PTR_=0, RSDA_PTR_=0, HUGE_PTR_=0, LA_PTR_=0, C_BWCRT_PTR_=0, C_CCRT_PTR_=0, E_CCRT_PTR_=0, E_CCRT_PTR2_=0, SYS_ROM_CS_=0, SYS_ROM_DS_=0, SYS_PATCH_CS_=0, SYS_PATCH_DS_=0, V_ROM_CS_=0, V_ROM_DS_=0, V_PATCH_CS_=0, V_PATCH_DS_=0, ES_TEMP_=0, CS_TEMP_=0, SS_TEMP_=0, DS_TEMP_=0, MON_LDTR_=0, MON_DS_=0, MON_ES_=0, MON_SS_=0, MON_CS_=0, MON_TR_SS_=0, MON_TR_BP_=0, MON_TR_HWI_=0, MON_TR_OI_=0, KBD_OWNER_SDA_=0, VTIMER_VECTOR_=16*8 dup (0), SEX_TSS_=32*8 dup (0), HWI_TSS_=16*16 dup (0), DISPATCH_TASK_=0, GDT_DEF_37_=0, HWI_LDT_=0, BASICS_SEG_=0, BIOSS_SEG_=0, RSVD_GDT_=0, PM_VM_=32 DUP (0), USER_CS_=0, USER_SS_=0, USER_DS_=0, USER_ES_=0, USER_TSS_=0, USER_TSS_DAT_=0, USER_LDT_=0, USER_LDT_DAT_=0, USER_VMS_=14*32 dup (0), SCRUBBER_=32 DUP (0), last_gdt_byte_=0
{

.UNUSED_ENTRY    DQ      UNUSED_ENTRY_ ; Seg reg = 0 illegal - this entry is
                                      ; not accessible
.GDT_PTR         DQ      GDT_PTR_ ; This entry points to this GDT table
.MON_IDT_PTR     DQ      MON_IDT_PTR_ ; System interrupt descriptor table
.RSDA_PTR        DQ      RSDA_PTR_ ; The real system data area (as opposed
                                      ; to the virtual SDA's).  XMA pages
                                      ; start here
.HUGE_PTR        DQ      HUGE_PTR_ ; Used to address 0-1M as data

.LA_PTR          DQ      LA_PTR_ ; Pointer to the LOADALL area (000800H)

.C_BWCRT_PTR     DQ      C_BWCRT_PTR_ ; Compatible blanck and white display
.C_CCRT_PTR      DQ      C_CCRT_PTR_ ; Compatible color display
.E_CCRT_PTR      DQ      E_CCRT_PTR_ ; Enhanced color display (16 bytes)
.E_CCRT_PTR2     DQ      E_CCRT_PTR2_

.SYS_ROM_CS      DQ      SYS_ROM_CS_ ; CS for system IDT, ROM resident
.SYS_ROM_DS      DQ      SYS_ROM_DS_ ; DS selector to access above as data
.SYS_PATCH_CS    DQ      SYS_PATCH_CS_ ; CS for system IDT, RAM patch area
.SYS_PATCH_DS    DQ      SYS_PATCH_DS_ ; DS selector to access above as data

.V_ROM_CS        DQ      V_ROM_CS_ ; CS - virtual IDT, ROM resident
.V_ROM_DS        DQ      V_ROM_DS_ ; DS selector to access above as data
.V_PATCH_CS      DQ      V_PATCH_CS_ ; CS - virtual IDT, RAM patch area
.V_PATCH_DS      DQ      V_PATCH_DS_ ; DS selector to access above as data

.ES_TEMP         DQ      ES_TEMP_ ; Dynamic pointer for ES
.CS_TEMP         DQ      CS_TEMP_ ; Dynamic pointer for CS
.SS_TEMP         DQ      SS_TEMP_ ; Dynamic pointer for SS
.DS_TEMP         DQ      DS_TEMP_ ; Dynamic pointer for DS

;       Monitor descriptors

.MON_LDTR        DQ      MON_LDTR_
.MON_DS          DQ      MON_DS_
.MON_ES          DQ      MON_ES_
.MON_SS          DQ      MON_SS_
.MON_CS          DQ      MON_CS_
.MON_TR_SS       DQ      MON_TR_SS_ ; Task register value for single step
.MON_TR_BP       DQ      MON_TR_BP_ ;  "      "       "    "  breakpoint
.MON_TR_HWI      DQ      MON_TR_HWI_ ; Read/write (needs special hardware)
.MON_TR_OI       DQ      MON_TR_OI_ ;  "      "       "    "  control-break

.KBD_OWNER_SDA   DQ      KBD_OWNER_SDA_ ; Fast path to keyboard owner's SDA

.VTIMER_VECTOR   DB     VTIMER_VECTOR_ ; 16 VM timer-related descriptors

;       Below are the 32 system exception service routine descriptors.

.SEX_TSS         DB      SEX_TSS_

;       Below are the 16 hardware interrupt service routine TSS descriptor
;       pairs.  The first is suitable for TR loading (i.e. target selector
;       in the corresponding task gate) and the other is a TSS-as-data
;       descriptor.

.HWI_TSS         DB      HWI_TSS_

;       This is the descriptor pair for the dispatcher (same format as HWI).

.DISPATCH_TASK   DQ      DISPATCH_TASK_
                DQ      GDT_DEF_37_

.HWI_LDT         DQ      HWI_LDT_

.BASICS_SEG      DQ      BASICS_SEG_ ; BASIC's segment (F600)

.BIOSS_SEG       DQ      BIOSS_SEG_ ; BIOS's segment (F000)

;
;
;       Any other GDT things go here.  There are around 300 slots left.
;
;

.RSVD_GDT        DQ      RSVD_GDT_
                DB     (GDT_LEN - (GDT_DEF.RSVD_GDT + 8) - (18 * 32)) DUP (0)

                                      ; The above leaves space for the
                                      ; descriptors needed for 18 VMs

.PM_VM           DB     PM_VM_ ; Program Manager's virtual machine
                                      ; entries.  This will function as
                                      ; the highest priority machine.
.USER_CS         DQ      USER_CS_ ; Debugee's code segment
.USER_SS         DQ      USER_SS_ ; Debugee's stack segment
.USER_DS         DQ      USER_DS_ ; Debugee's data segment
.USER_ES         DQ      USER_ES_ ; Debugee's extra segment
.USER_TSS        DQ      USER_TSS_ ; Debugee's Task State Segment
.USER_TSS_DAT    DQ      USER_TSS_DAT_ ; Debugee's TSS as a data segment
.USER_LDT        DQ      USER_LDT_ ; Debugee's LDT definition
.USER_LDT_DAT    DQ      USER_LDT_DAT_ ; Debugee's LDT as a data segment

.USER_VMS        DB     USER_VMS_ ; 16 user VMs

.SCRUBBER        DB     SCRUBBER_ ; RAM scrubber - dispatched when no other
                                      ; machine has work to do
.last_gdt_byte   db     last_gdt_byte_ ; marker for last GDT byte + 1
}
match =GDT_DEF_LAID_OUT, GDT_DEF_LAID_OUT
{
    GDT_DEF_LAID_OUT equ 1
    virtual at 0
      GDT_DEF GDT_DEF 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16*8 dup (0), 32*8 dup (0), 16*16 dup (0), 0, 0, 0, 0, 0, 0, 32 DUP (0), 0, 0, 0, 0, 0, 0, 0, 0, 14*32 dup (0), 32 DUP (0), 0
      sizeof.GDT_DEF = $ - GDT_DEF
    end virtual
}
STRUC VM_GDT_ENTRY VM_TR_=0, TSS_PTR_=0, VM_LDTR_=0, LDT_PTR_=0
{

.VM_TR           DQ      VM_TR_ ; TR value for this machine's TSS
.TSS_PTR         DQ      TSS_PTR_ ; Data pointer to this machine's TSS
.VM_LDTR         DQ      VM_LDTR_ ; LDTR value for this machine's LDT
.LDT_PTR         DQ      LDT_PTR_ ; Data pointer to this machine's LDT

}
match =VM_GDT_ENTRY_LAID_OUT, VM_GDT_ENTRY_LAID_OUT
{
    VM_GDT_ENTRY_LAID_OUT equ 1
    virtual at 0
      VM_GDT_ENTRY VM_GDT_ENTRY 0, 0, 0, 0
      sizeof.VM_GDT_ENTRY = $ - VM_GDT_ENTRY
    end virtual
}
STRUC DATA_DESC SEG_LIMIT_=0, BASE_LO_WORD_=0, BASE_HI_BYTE_=0, DATA_ACC_RIGHTS_=0, DATA_RESERVED_=0
{

.SEG_LIMIT       DW      SEG_LIMIT_ ; Segment limit (1 - 65535 bytes)
.BASE_LO_WORD    DW      BASE_LO_WORD_ ; 24 bit segment physical address
.BASE_HI_BYTE    DB      BASE_HI_BYTE_ ;   (0 - (16M-1))
.DATA_ACC_RIGHTS DB      DATA_ACC_RIGHTS_ ; Access rights byte
.DATA_RESERVED   DW      DATA_RESERVED_ ; Intel reserved

}
match =DATA_DESC_LAID_OUT, DATA_DESC_LAID_OUT
{
    DATA_DESC_LAID_OUT equ 1
    virtual at 0
      DATA_DESC DATA_DESC 0, 0, 0, 0, 0
      sizeof.DATA_DESC = $ - DATA_DESC
    end virtual
}
STRUC GATE_DESC ENTRY_POINT_=0, CS_SELECTOR_=0, WORD_COUNT_=0, GATE_ACC_RIGHTS_=0, GATE_RESERVED_=0
{

.ENTRY_POINT     DW      ENTRY_POINT_ ; Destination routine entry point
                                      ;   within the target segment.
                                      ;   This is unused for task gates.
.CS_SELECTOR     DW      CS_SELECTOR_ ; Selector for destination segment.
                                      ;   For task gates, this must point
                                      ;   to a valid task state segment
                                      ;   descriptor.  For call, trap, and
                                      ;   interrupt gates, this must point
                                      ;   to a valid code segment descriptor.
                                      ;   The segment defined in that
                                      ;   descriptor plus the aforementioned
                                      ;   entry-point defines the actual
                                      ;   routine address.
.WORD_COUNT      DB      WORD_COUNT_ ; For call gates only - number of
                                      ;   words to copy from caller's
                                      ;   stack to callee's stack
.GATE_ACC_RIGHTS DB      GATE_ACC_RIGHTS_ ; Access rights byte
.GATE_RESERVED   DW      GATE_RESERVED_ ; Intel reserved

}
match =GATE_DESC_LAID_OUT, GATE_DESC_LAID_OUT
{
    GATE_DESC_LAID_OUT equ 1
    virtual at 0
      GATE_DESC GATE_DESC 0, 0, 0, 0, 0
      sizeof.GATE_DESC = $ - GATE_DESC
    end virtual
}
STRUC TASK_STATE_286 BACK_LINK_=0, VM_SP0_=0, VM_SS0_=0, VM_SP1_=0, VM_SS1_=0, VM_SP2_=0, VM_SS2_=0, VM_IP_=0, VM_FL_=0, VM_AX_=0, VM_CX_=0, VM_DX_=0, VM_BX_=0, VM_SP_=0, VM_BP_=0, VM_SI_=0, VM_DI_=0, VM_ES_=0, VM_CS_=0, VM_SS_=0, VM_DS_=0, VM_LDT_=0
{

.BACK_LINK       DW      BACK_LINK_ ; TSS selector from whence we came
.VM_SP0          DW      VM_SP0_ ; SS:SP for CPL 0
.VM_SS0          DW      VM_SS0_
.VM_SP1          DW      VM_SP1_ ; SS:SP for CPL 1
.VM_SS1          DW      VM_SS1_
.VM_SP2          DW      VM_SP2_ ; SS:SP for CPL 2
.VM_SS2          DW      VM_SS2_
.VM_IP           DW      VM_IP_ ; IP - next instruction to execute
.VM_FL           DW      VM_FL_ ; Flag word
.VM_AX           DW      VM_AX_ ;
.VM_CX           DW      VM_CX_ ; General
.VM_DX           DW      VM_DX_ ;
.VM_BX           DW      VM_BX_ ;
.VM_SP           DW      VM_SP_ ;         Purpose
.VM_BP           DW      VM_BP_ ;
.VM_SI           DW      VM_SI_ ;
.VM_DI           DW      VM_DI_ ;                 Registers
.VM_ES           DW      VM_ES_ ;
.VM_CS           DW      VM_CS_ ; Segment
.VM_SS           DW      VM_SS_ ;          Selectors
.VM_DS           DW      VM_DS_ ;
.VM_LDT          DW      VM_LDT_ ; Selector for this task's LDT

}
match =TASK_STATE_286_LAID_OUT, TASK_STATE_286_LAID_OUT
{
    TASK_STATE_286_LAID_OUT equ 1
    virtual at 0
      TASK_STATE_286 TASK_STATE_286 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      sizeof.TASK_STATE_286 = $ - TASK_STATE_286
    end virtual
}
;COMMENT #
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                                                                             *
;* MODULE NAME     : INDEDAT                                                   *
;*                                                                             *
;*                                                                             *
;*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corporation        *
;*                                                                             *
;* DESCRIPTIVE NAME: Sytem data structures and equates for 386 XMA emulator    *
;*                                                                             *
;* STATUS (LEVEL)  : Version (0) Level (1.0)                                   *
;*                                                                             *
;* FUNCTION        : This file defines the overlays and constants for most of  *
;*                   the system data.  The following structures are defined    *
;*                   here:                                                     *
;*                          The resister save area on our stack                *
;*                          80386 Task State Segment (TSS)                     *
;*                          The Global Descriptor Table (GDT)                  *
;*                          80286 Segment Descriptor                           *
;*                          80286 Gate Descriptor                              *
;*                          80286 Task State Segment (TSS)                     *
;*                                                                             *
;* MODULE TYPE     : INC                                                       *
;*                                                                             *
;* REGISTER USAGE  : 80386 Standard                                            *
;*                                                                             *
;* RESTRICTIONS    : None                                                      *
;*                                                                             *
;* DEPENDENCIES    : None                                                      *
;*                                                                             *
;* EXTERNAL                                                                    *
;* REFERENCES      : None                                                      *
;*                                                                             *
;* CHANGE ACTIVITY :                                                           *
;*                                                                             *
;* MAC$(INDEDAT) COMP(LOAD) PROD(3270PC) :                                     *
;*                                                                             *
;* D0$=D0004700 410 870529 D : NEW FOR WSP RELEASE 1.1                         *
;* P1$=P0000311 410 870804 D : RENAME MODULES'S LIBRARY FILE TYPE TO "INC"     *
;* P2$=P0000410 410 870918 D : RELOCATE DATA TO MAKE ROOM FOR I/O BIT MAP      *
;*                                                                             *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;#

; BPSTACK is an overlay for our stack when we receive control from an
; interrupt that we want to handle.  The entry points for these interrupts
; push a 32 but error  code and the interrupt number (16 bits) onto the stack.
; Then control goes to INDEEXC which saves the current register values on the
; stack.  BP is set to point to the beginning of the register save area.  This
; is the mapping of the resulting stack.


BP_START EQU    0             ; Offset from BP of the start of the stack info

SUBTTL   80386 TSS - Task State Segment
PAGE
;*************************************************
;                                                *
;         Start of Debugger's 386 TSS            *
;                                                *
;*************************************************

TSS_386_LEN     EQU     68H   ; Length of the TSS
TSS_BM_LEN      equ     (0FFFH-TSS_386_LEN)	; Length of the I/O bit map
                              ; The bit map is in the same segment as the TSS
                              ;   therefore the descriptor fot the TSS segment
                              ;   must have enough room to include the bit map.

SUBTTL  GDT - Global Descriptor Table
PAGE

SUBTTL  GDT - GLOBAL DESCRIPTOR TABLE

;       THE GLOBAL DESCRIPTOR TABLE DEFINITION
;       === ====== ========== ===== ==========
;

GDT_LEN         equ     (512 * 8)	; 512 entries total


SUBTTL  Virtual Machine Entry
PAGE
;       Virtual Machine Entry Definition - consists of 4 descriptors
;
;               - Pointer to TSS, loadable into the Task Register
;               - Pointer to TSS, loadable into a regular segment register
;               - Pointer to the LDT, loadable into the LDT Register
;               - Pointer to the LDT, loadable into a regular segment register
;
;       The first of each pair is for loading into the associated special
;       system registers,  TR and LDTR.  The second allows dynamic access
;       and modification of descriptors by the system.


SUBTTL  80286 Segment Descriptor
PAGE
;       DESCRIPTOR TABLE ENTRY STRUCTURES
;       ========== ===== ===== ==========
;
;       Segment Descriptor
;
;       The following type of descriptor applies to data segments, code
;       segments, local, global, and interrupt descriptor table segments,
;       and task state segments.


SHADOW_ID       EQU     DATA_DESC.DATA_RESERVED ; For garbage collection

SUBTTL  80286 Gate Descriptor
PAGE
;       80286 Gate Descriptor

;       The following type of descriptor applies to task gates, call gates,
;       interrupt gates, and trap gates.


;       Record for the fields in a selector

;SELECTOR	RECORD	INDEX:13,TI:1,RPL:2; Standard 286 selector format
; MASM packed those into 16 bits from the top down; the name of a field is
; the shift it stands for, and MASK of it the bits it covers.
INDEX = 3
TI = 2
RPL = 0

SUBTTL  TSS - Task State Segment
PAGE
;       TASK STATE SEGMENT
;       ==== ===== =======
;
;       There are currently two styles of task state segment (TSS) - one for
;       VMs and one for the hardware interrupt service routines.  There may
;       be more later, depending on the needs and/or whims of the Authors
;       of this and follow-on products.  They will all have one thing in
;       common - they begin with a 44 byte 286-required machine state data
;       area.  The first structure below is that area's definition.  All
;       subsequent colors of TSS will start with space for that data, defined
;       like so:
;
; first_field_name        DB      (TYPE TASK_STATE_286)   DUP     (0)
;
;       As a convenience, we use the highest part of the TSS for that
;       particular task's stack (or in some cases, stacks - for privilege
;       levels 0, 1, and 2).  The intermediate area is used for task-specific
;       data.



;       Note that the actual stacks for CPLs 2, 1, and 0 are part of the
;       task state segment.  CPL 3's stack is in its own address space.

SUBTTL  Length Equates
PAGE
;       Length equates

LA_LEN          EQU     GDT_LEN         ; For new monitor

SIDT_LEN        equ     (256*8)	; Length of the IDT -- 256 interrupt
                                        ;   entries, 8 bytes each

TSS_LEN         equ     (68H + 2000H)	; TSS structure length -- 68H for regs
                                        ;   2000H for I/O bit map  @P2C

LDT_LEN         EQU     00800H          ; LDT structure length (2K)

VM_ENTRY_LENGTH EQU     sizeof.VM_GDT_ENTRY ; Length of a VM entry

VM_ENTRY_WIDTH  EQU     5               ; Shift count for priority. Each
                                        ; VM entry = 32 bytes, and SHL 5
                                        ; is the same as MUL by 32.
NEXT_DESC       EQU     sizeof.DATA_DESC ; Length of a descriptor

DESC_LEN        EQU     sizeof.DATA_DESC ; Length of a descriptor

DESC_WIDTH      EQU     3               ; Shift count for desc len (8) is 3

PM_VM_SIZE      EQU     01000H          ; Virtual Manager's VM size

MCRT_SIZE       equ     (4*1024)	; Monochrome display size

CCRT_SIZE       equ     (16*1024)	; Compatible color display size

ECCRT_SIZE      EQU     0FFFFH          ; Size of each portion of the enhanced
                                        ;   color display buffer

MAX_SEG_LEN     EQU     0FFFFH          ; Maximum segment length = 64K

NULL_SEG_LEN    EQU     00000H          ; Null segment length = 0

THIRTY_TWO_K    EQU     08000H          ; Unit of virtual machine size


SUBTTL  Location Equates
PAGE


;       Location equates

;       These items are all pre-allocated, and have no SBDs.  After these,
;       storage structures are all obtained through the memory manager.

;-----------------------------------------------------------------------------

; From here to the end marker, these guys must stay in order as this is
;  how they are allocated.

GDT_LOC         EQU     0C100H          ; GDT location relative to CS       @P2C

SIDT_LOC        equ     ((GDT_LOC + GDT_LEN))	; The system IDT is next

DISPATCH_LOC     equ     ((SIDT_LOC + SIDT_LEN))

; End marker

;   Monitor equate used in m_state to tell the estep routine that we're
;    single stepping from within ego.
GO_MODE         EQU     1               ;
;   Monitor equate used in m_state to tell the hwi_int routine that we're
;    breaking on a memory read address that's executed
MEMX            EQU     2               ;
;   Monitor equate used in m_state to tell mon_go that a breakpoint has been
;    set so enable the breakpoint card
CARD_ENABL      EQU     4               ;
S_MODE          EQU     2000H           ; Selector or segment mode flag

BOOT_IP         EQU     07C00H          ; PC1 IP value for boot

BOOT_CS         EQU     00000H          ; PC1 CS value for boot

BOOT_SS         EQU     00030H          ; PC1 SS value for boot

BOOT_SP         EQU     07FFH           ; PC1 SP value for boot

BOOT_FL         EQU     00200H          ; Interrupts enabled

CS_LO_CACHE     EQU     00000H          ; Code segment

CS_HI_CACHE     EQU     000H            ;   compatible cache

SS_LO_CACHE     EQU     00300H          ; Stack segment

SS_HI_CACHE     EQU     000H            ;   compatible cache

OTHER_CACHE     EQU     00000H          ; GP zero cache

SUBTTL  DISPLAY_ Equates
PAGE

;       The next equates are system definitions for display buffer addresses.


MCRT@_LO        EQU     0000H           ;
                                        ; Monochrome display address
MCRT@_HI        EQU     0BH             ; (0B0000H)

CCRT@_LO        EQU     8000H           ;
                                        ; Compatible color display address
CCRT@_HI        EQU     0BH             ; (0B8000H)

ECCRT@_LO_LO    EQU     0000H           ;
                                        ; Enhanced color display address -
ECCRT@_LO_HI    EQU     0AH             ;   lower 64K (0A0000H)

ECCRT@_HI_LO    EQU     0000H           ;
                                        ; Enhanced color display address -
ECCRT@_HI_HI    EQU     0CH             ;   upper 64K (0C0000H)


;       Code segment addresses


CSEG@_LO        EQU     0000H           ;
                                        ; ROM code segment address
CSEG@_HI        EQU     0EH             ; (0E0000H)

NSEG@_LO        EQU     0000H           ;
                                        ; Null segment address
NSEG@_HI        EQU     00H             ;

VIRTUAL_ENABLE  EQU     0000000000000001B

SUBTTL
