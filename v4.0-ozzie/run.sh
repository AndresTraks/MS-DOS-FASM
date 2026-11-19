#!/bin/sh
# Start a machine from the disk create_image.sh makes, with our BIOS on it.
#
# The disk carries bin/IBMBIOQ.COM, the build with the three things this
# machine wants in it -- two for QEMU's floppy controller and one for the A20
# gate -- see src/QEMULNK.ASM.  Without the first two nothing starts,
# Microsoft's own IBMBIO.COM included; with them the system comes up:
# COMMAND.COM, AUTOEXEC.BAT, and SM.EXE if you type SM, which is the session
# manager this release is for.  F7 and F8 are the two shells SM.INI defines.
#
# The release as it was written goes on a disk with
#
#	./create_image.sh ozzie.img bin/IBMBIO.COM
#
# and that one stops where Microsoft's does: the kernel's banner and a panic.
# tests/boot.sh starts both and holds each against what it should do.
#
# Multi-tasking MS-DOS was written for the IBM PC of 1984 and this release
# says in its README that it had to "hook out the entire disk (both floppy and
# hard disk) ROM code" because the IBM ROM waits for the interrupt in a loop;
# so the drivers in src/IBMDSK.ASM drive the controller and the DMA chip
# themselves, against a ROM whose innards they name.  A machine with the IBM
# ROM in it -- 86Box or PCem -- is the place to run the unchanged build.
#
# QEMU is asked for a 640K machine with one diskette in it, which is what this
# system expects to find.  A second diskette can go in with
#
#	QEMUFLAGS="-drive file=bin/DRDOS2_IMD.img,format=raw,if=floppy,index=1"
#
# -- the second of the two the release came on, which carries the BIOS sources
# themselves.
set -e
cd "$(dirname "$0")"
QEMU=${QEMU:-qemu-system-i386}

./create_image.sh

if ! command -v "$QEMU" >/dev/null 2>&1; then
    echo "$QEMU not found. Please install QEMU." >&2
    exit 1
fi

exec "$QEMU" -rtc base=localtime -m 640 \
     -drive file=ozzie.img,format=raw,if=floppy,index=0 $QEMUFLAGS
