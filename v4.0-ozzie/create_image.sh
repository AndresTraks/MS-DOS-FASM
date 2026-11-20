#!/bin/sh
# Make a diskette this system can be started from, with our own BIOS on it.
#
# Every other tree here lays its disk down from nothing: mformat writes the
# file system and the boot sector comes from the converted MSBOOT.  Neither is
# possible in this one.  The boot sector of this release is a DOS 2.0 one that
# BOOTPACH.EXE patched to read a BIOS of 12363 bytes rather than the 1920 the
# IBM 2.0 sector was written for, its source is not in the release, and
# FORMAT, SYS and COMMAND.COM belong to the DOS whose sources are not here
# either.  What the release does give is a bootable disk: bin/DRDOS1_IMD.img,
# the first of the two diskettes, with IBMBIO.COM, IBMDOS.COM, COMMAND.COM and
# the session manager on it.
#
# So the disk is that one with our IBMBIO.COM in the place of Microsoft's.
# This is exactly what SYS does, and it can be done by writing the bytes
# where the old ones were because the two files are the same length: 12363,
# which src/BIOSLNK.ASM lays out paragraph for paragraph as LINK did.  Writing
# them in place also keeps the two things the boot sector depends on -- that
# IBMBIO.COM is the first entry of the root directory and that it runs from
# the first cluster of the data area without a break.
#
# The disk is ozzie.img unless another path is asked for, and the BIOS on it
# is bin/IBMBIOQ.COM -- the build with the two things QEMU's floppy controller
# wants, which is the one that starts.  bin/IBMBIO.COM, the release as it was
# written, goes on with
#
#	./create_image.sh ozzie.img bin/IBMBIO.COM
#
# and gets as far as the kernel's banner and the panic, which is where
# Microsoft's own build gets to on this machine.  See src/QEMULNK.ASM.
set -e
cd "$(dirname "$0")"
IMAGE=${1:-ozzie.img}
BIOS=${2:-bin/IBMBIOQ.COM}

./assemble.sh >/dev/null

cp bin/DRDOS1_IMD.img "$IMAGE"

# Our BIOS where the release's was, which is what SYS does -- see putbios.py.
python3 -I putbios.py "$IMAGE" "$BIOS" bin/DISK1/IBMBIO.COM
