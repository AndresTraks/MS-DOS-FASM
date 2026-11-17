#!/bin/sh
# Start a machine from the disk create_image.sh makes, with our BIOS on it.
#
# How far it gets is not far, and it is as far as the release itself gets: the
# BIOS says what it is, the kernel says what it is, and then the kernel stops
# with "Internal Error 4560 / HardErr: no handler" -- a hard error raised
# before any process owns INT 24H to be asked about it.  Microsoft's own
# IBMBIO.COM on Microsoft's own diskette stops at the same line on this
# machine, which is what tests/boot.sh holds the two against each other for.
#
# Multi-tasking MS-DOS was written for the IBM PC of 1984 and this release
# says in its README that it had to "hook out the entire disk (both floppy and
# hard disk) ROM code" because the IBM ROM waits for the interrupt in a loop;
# so the drivers in src/IBMDSK.ASM drive the controller and the DMA chip
# themselves, against a ROM whose innards they name.  A machine with the IBM
# ROM in it -- 86Box or PCem -- is the place to see it go further.
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
