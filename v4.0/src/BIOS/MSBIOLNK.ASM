; IO.SYS, the second half: the BIOS proper, which MSLOAD.COM reads in.
;
; Thirteen modules, which the linker put into two segments.  MSBIO.LNK gives
; the order -- msbio1, mscon, msaux, mslpt, msclock, msdisk, msbio2, mshard,
; msinit, sysinit1, sysconf, sysinit2, sysimes -- and the first nine of those
; contribute to CODE while the last four contribute to SYSINITSEG, so the
; layout is simply the one and then the other.  Each module is read once,
; here, in that order; nothing is external any more.
;
; The two segments matter because the code in them is addressed from
; different places.  CODE is where the BIOS lives for good: the device
; drivers, their headers, the interrupt handlers.  It is entered at 70h:0,
; which is where MSLOAD leaves it, and EXE2BIN bound its segment references
; to 70h at build time -- hence CODE = 70h below, which is what MSBDATA.INC's
; device chain and MSBIO2's INT 2FH tables are built of.  SYSINITSEG holds
; what runs once: the memory sizing, CONFIG.SYS, the drive tables, loading
; MSDOS.SYS and COMMAND.COM.  It begins at the next paragraph after CODE and
; gives its space back when it has finished, so its own segment value is
; worked out from the size of CODE.
;
; fasm's ORG moves the address without writing anything, so the gap between
; the two is laid down here rather than left to it.

use16

; MASM's listing directives, in the spellings the modules use.
macro page [x] {
}
macro PAGE [x] {
}
macro subttl [x] {
}
macro SUBTTL [x] {
}
macro TITLE [x] {
}

CODE		= 70h		; where MSLOAD puts the BIOS, and what EXE2BIN
				;  bound the segment references in it to

org 0

include 'MSBIO1.ASM'		; the device driver frame and the headers
include 'MSCON.ASM'		; the console
include 'MSAUX.ASM'		; the serial ports
include 'MSLPT.ASM'		; the printers
include 'MSCLOCK.ASM'		; the clock
include 'MSDISK.ASM'		; the disks
include 'MSBIO2.ASM'		; INT 19H, INT 2FH and the drive tables
include 'MSHARD.ASM'		; the AT ROM hard disk patch
include 'MSINIT.ASM'		; what runs at 70h:0 on the way in

CODE_SIZE = $ - $$

; SYSINITSEG begins at the next paragraph after the code segment.
times ((CODE_SIZE + 15) and (not 15)) - CODE_SIZE db 0
SYSINITSEG = CODE + ((CODE_SIZE + 15) shr 4)

org 0

include 'SYSINIT1.ASM'		; memory, the stacks, the system files
include 'SYSCONF.ASM'		; CONFIG.SYS, read through INC/PARSE.ASM
include 'SYSINIT2.ASM'		; the drive tables and the country file
include 'SYSIMES.ASM'		; the messages, and SYSSIZE at the end
