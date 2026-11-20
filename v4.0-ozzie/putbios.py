#!/usr/bin/env python3
#
# Write our IBMBIO.COM over the one on the release's diskette.
#
# This is what SYS does, and it can be done by writing the bytes where the old
# ones were because the two files are the same length: 12363, which
# src/BIOSLNK.ASM lays out paragraph for paragraph as LINK did.  Writing them
# in place also keeps the two things the boot sector depends on -- that
# IBMBIO.COM is the first entry of the root directory and that it runs from the
# first cluster of the data area without a break.
#
#   python3 putbios.py <image> <our BIOS> <the release's BIOS>
#
# The third file is the one that is expected to be there, bin/DISK1/IBMBIO.COM,
# and it is read for two reasons: to see that ours is the same length, and to
# see that what is at the front of the data area really is it.  Neither holds
# and nothing is written -- a disk whose BIOS has moved is not one this can
# write in place.  See create_image.sh for the disk itself.
import struct
import sys


def main(image, ours, theirs):
    new = open(ours, 'rb').read()
    old = open(theirs, 'rb').read()
    if len(new) != len(old):
        sys.exit("putbios.py: our BIOS is %d bytes and the release's is %d; "
                 "it cannot be written in place" % (len(new), len(old)))

    with open(image, 'r+b') as f:
        disk = bytearray(f.read())
        # The data area: the boot sector, both copies of the FAT, and the root
        # directory, all of which this leaves exactly as the release wrote
        # them.
        bps, spc, res, fats, rootent = struct.unpack('<HBHBH', disk[11:19])
        spf = struct.unpack('<H', disk[22:24])[0]
        at = (res + fats * spf) * bps + rootent * 32
        if disk[at:at + len(old)] != old:
            sys.exit("putbios.py: IBMBIO.COM is not at the front of the data "
                     "area; %s is not the image this expects" % image)
        disk[at:at + len(new)] = new
        f.seek(0)
        f.write(disk)


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit("usage: python3 putbios.py <image> <our BIOS> "
                 "<the release's BIOS>")
    main(sys.argv[1], sys.argv[2], sys.argv[3])
