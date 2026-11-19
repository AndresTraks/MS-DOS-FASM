; IBMBIO.COM as the release was written, which is the one to hold against the
; file Microsoft shipped.
;
; It does not start on QEMU, and neither does Microsoft's own: the floppy
; controller QEMU models is not the one these drivers were written for, so the
; system reaches the kernel's banner and panics.  src/QEMULNK.ASM is the same
; build with those two and a third for the A20 gate, and that one runs.
;
; Everything else is in src/BIOSIMG.ASM, which this and QEMULNK.ASM share.

QEMUFDC = 0
QEMUA20 = 0

include 'BIOSIMG.ASM'
