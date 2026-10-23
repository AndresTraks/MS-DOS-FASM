; The following structure defines the disk parameter table
; pointed to by Interrupt vector 1EH (location 0:78H)

; MASM made each field name a name for its offset in the structure, which
; is how the table at 0:0522h, which is no instance of one, can be read
; field by field; in fasm the fields belong to the structure, so a reference
; names it too.
STRUC DISK_PARMS
{
.DISK_SPECIFY_1	DB	0
.DISK_SPECIFY_2	DB	0
.DISK_MOTOR_WAIT DB	0	; Wait till motor off
.DISK_SECTOR_SIZ DB	0	; Bytes/Sector (2 = 512)
.DISK_EOT	DB	0	; Sectors per track (MAX)
.DISK_RW_GAP	DB	0	; Read Write Gap
.DISK_DTL	DB	0
.DISK_FORMT_GAP	DB	0	; Format Gap Length
.DISK_FILL	DB	0	; Format Fill Byte
.DISK_HEAD_STTL	DB	0	; Head Settle Time (MSec)
.DISK_MOTOR_STRT DB	0	; Motor start delay
}
match =DISK_PARMS_LAID_OUT, DISK_PARMS_LAID_OUT
{
    DISK_PARMS_LAID_OUT equ 1
    virtual at 0
      DISK_PARMS DISK_PARMS
      sizeof.DISK_PARMS = $ - DISK_PARMS
    end virtual
}

ROMStatus	equ	1
ROMRead 	equ	2
ROMWrite	equ	3
ROMVerify	equ	4
ROMFormat	equ	5
