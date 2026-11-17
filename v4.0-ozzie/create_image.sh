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
# The disk is ozzie.img unless another path is asked for.
set -e
cd "$(dirname "$0")"
IMAGE=${1:-ozzie.img}

./assemble.sh >/dev/null

cp bin/DRDOS1_IMD.img "$IMAGE"

python3 -I - "$IMAGE" bin/IBMBIO.COM bin/DISK1/IBMBIO.COM <<'PY'
import struct
import sys

image, ours, theirs = sys.argv[1], sys.argv[2], sys.argv[3]
new = open(ours, "rb").read()
old = open(theirs, "rb").read()
if len(new) != len(old):
    sys.exit("create_image.sh: our BIOS is %d bytes and the release's is %d; "
             "it cannot be written in place" % (len(new), len(old)))

with open(image, "r+b") as f:
    disk = bytearray(f.read())
    # The data area: the boot sector, both copies of the FAT, and the root
    # directory, all of which this leaves exactly as the release wrote them.
    bps, spc, res, fats, rootent = struct.unpack("<HBHBH", disk[11:19])
    spf = struct.unpack("<H", disk[22:24])[0]
    at = (res + fats * spf) * bps + rootent * 32
    if disk[at:at+len(old)] != old:
        sys.exit("create_image.sh: IBMBIO.COM is not at the front of the "
                 "data area; the image is not the one this expects")
    disk[at:at+len(new)] = new
    f.seek(0)
    f.write(disk)
PY
