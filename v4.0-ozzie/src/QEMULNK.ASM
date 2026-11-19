; IBMBIO.COM again, with the three things this machine wants.
;
; src/BIOSLNK.ASM builds the release as it was written, and on a machine with
; the IBM PC's ROM in it that is the one to use.  It does not run here: the
; controller QEMU models is not the one these drivers were written for, and
; the system gets as far as the kernel's banner and panics.  Microsoft's own
; IBMBIO.COM panics in the same line on the same machine, so the two changes
; below are the machine's doing; convert.py's table says what each is and what
; goes wrong without it.
;
;   * four Sense Interrupt Status commands after a reset of the 765, which the
;     IBM ROM does and this driver does not, and
;   * 300 kbps rather than 250, QEMU having no 360K drive to put a 360K
;     diskette in, and
;   * the A20 gate closed, which SeaBIOS leaves open and which the kernel's
;     CP/M call at offset 5 is built on: the long call it writes there is a
;     megabyte above the long jump it points at, and twenty address lines are
;     what close the gap.  That one is under QEMUA20 rather than QEMUFDC,
;     having nothing to do with the floppy controller, and the system comes
;     up without it -- nothing in the release uses that door.
;
; They are twelve bytes, one, and six.  CODE still ends on the paragraph LINK
; ended it on, so this comes out 12363 bytes with the same layout as the
; shipped file -- and create_image.sh can write either one over Microsoft's in
; place.  There is no room left in it: LINK left CODE eighteen bytes short of
; the paragraph and these take all eighteen, and BIOSINIT has none at all, so
; a fourth change would move a boundary and was() in BIOSIMG.ASM would stop
; the assembly.  With them the system starts: COMMAND.COM, AUTOEXEC.BAT, DIR
; read through the converted disk driver, and SM.EXE with a shell in a
; session.

QEMUFDC = 1
QEMUA20 = 1

include 'BIOSIMG.ASM'
