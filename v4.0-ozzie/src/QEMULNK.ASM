; IBMBIO.COM again, with the two things QEMU's floppy controller wants.
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
;     diskette in.
;
; They are twelve bytes and one, and CODE still ends on the paragraph LINK
; ended it on, so this comes out 12363 bytes with the same layout as the
; shipped file -- and create_image.sh can write either one over Microsoft's in
; place.  With it the system starts: COMMAND.COM, AUTOEXEC.BAT, DIR read
; through the converted disk driver, and SM.EXE with a shell in a session.

QEMUFDC = 1

include 'BIOSIMG.ASM'
