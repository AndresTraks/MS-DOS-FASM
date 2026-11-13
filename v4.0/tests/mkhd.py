#!/usr/bin/env python3
"""A hard disk with one DOS partition on it, for the tests that want a C:.

create_image.sh makes diskettes, which is all any test wanted until
FASTOPEN: that one caches directory entries and cluster chains, and it
refuses any drive the IOCTL removable-media call does not call fixed.  So
this lays down a small fixed disk instead.

DOS reads the partition table out of the first sector and takes the
partition's geometry from the CHS fields in it, so the two have to agree
with what the machine's BIOS reports.  QEMU is told the same geometry on
the command line -- see tests/fastopen.sh -- because a raw image carries
none of its own.  The numbers are the smallest that make a disk DOS 4 will
mount: 4 heads, 17 sectors, 61 cylinders, which is just over 2MB, with the
partition starting on the second track so that the table has the first to
itself.

The file system has to be laid out the way the BIOS expects rather than the
way it pleases, because this BIOS does not read the partition's own boot
record for it.  Asked for drive C's parameter block with INT 21H AH=32H,
DOS answers with eight sectors to a cluster, 512 directory entries, two
sectors to a FAT and the root directory at logical sector 5 -- none of
which is what mformat writes by default, and all of which comes from a
table built into the BIOS.  A disk formatted any other way still mounts,
and DOS reads and writes it quite happily, but it puts the root directory
where the BIOS says rather than where the boot record says, so a file
mtools wrote sits in a directory DOS never looks at.  Hence -c 8 and -r 32
below: eight sectors to a cluster and 32 sectors of root directory, which
is those 512 entries.  That puts the root directory at logical 5 and the
first data sector at 37, which is what the parameter block asks for.

What it prints is the image and the offset the volume begins at, which
mtools takes with two at signs and dosdir.py as a number of its own.

    python3 tests/mkhd.py <image>
"""
import struct
import subprocess
import sys

HEADS, SECTORS, CYLINDERS = 4, 17, 61


def main(out):
    total = HEADS * SECTORS * CYLINDERS
    start = SECTORS                   # the track the partition table is on
    size = total - start
    with open(out, 'wb') as f:
        f.truncate(total * 512)

    def chs(lba):
        """The cylinder, head and sector a sector number is at, packed the
        way a partition table entry wants them: the cylinder's top two bits
        ride in the sector byte."""
        cylinder, rest = divmod(lba, HEADS * SECTORS)
        head, sector = divmod(rest, SECTORS)
        return head, ((cylinder >> 2) & 0xC0) | (sector + 1), cylinder & 0xFF

    first = chs(start)
    last = chs(start + size - 1)
    sector = bytearray(512)
    # One entry, bootable, type 1: a FAT12 partition of under 32MB.  The
    # rest of the sector is left at nought -- nothing boots from this disk,
    # so it carries no boot code, and the test tells QEMU to boot the
    # diskette.
    struct.pack_into('<B3B B3B II', sector, 446, 0x80, *first, 0x01, *last,
                     start, size)
    sector[510:512] = b'\x55\xaa'
    with open(out, 'r+b') as f:
        f.write(sector)

    subprocess.run(['mformat', '-i', '%s@@%d' % (out, start * 512),
                    '-t', str(CYLINDERS), '-h', str(HEADS),
                    '-s', str(SECTORS), '-H', str(start),
                    '-c', '8', '-r', '32', '::'], check=True)
    return '%s@@%d' % (out, start * 512)


if __name__ == '__main__':
    print(main(sys.argv[1]))
