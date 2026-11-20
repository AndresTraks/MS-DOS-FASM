#!/usr/bin/env python3
#
# Put our boot sector on a disk, carrying the BPB the disk already has.
#
# MSBOOT.ASM declares a BPB for a hard file -- media F8, seventeen sectors a
# track, four surfaces, the boot drive 80H -- because that is what the release
# leaves in the source for FORMAT to overwrite.  So the sector cannot go on a
# diskette as it is assembled: the table that describes the disk has to be the
# one the disk was formatted with.
#
# What FORMAT and SYS do is write the code and keep the table, and that is
# what this does.  Sector 0 of the image holds the table the formatter wrote;
# bytes 0BH to 3EH of it -- the BPB, the physical drive and head, and the
# extended fields, which are the serial number, the volume label and "FAT12"
# -- are moved into our sector, and the result is written back over sector 0.
#
#   python3 bootsect.py <image> <boot sector>
#
# The image must already hold a file system: whatever formatted it is where
# the table comes from.  A disk whose sector 0 does not describe a diskette
# is one the table cannot be taken from, and this says so rather than write
# a disk that cannot be read -- which is what a formatter handed our own
# sector to begin with would leave behind.
import sys

BPB = slice(0x0B, 0x3E)


def check(table, image):
    """Say whether the sector read from the image describes a diskette.

    The two fields read here are ones a formatter cannot leave out: the
    sector size and the media descriptor.  A sector still carrying MSBOOT's
    own table answers F8, and that is the case worth naming, because it
    means the formatter was handed our sector and wrote no table of its own
    into it.
    """
    size = table[0] | table[1] << 8
    media = table[0x15 - 0x0B]
    if size == 512 and media == 0xF0:
        return
    if media == 0xF8:
        sys.exit("bootsect.py: sector 0 of %s still carries MSBOOT's own "
                 "table -- the disk has to be formatted before this, and by "
                 "something that writes a boot sector of its own" % image)
    sys.exit("bootsect.py: sector 0 of %s says %d bytes a sector and media "
             "%02XH, which is not a formatted diskette" % (image, size, media))


def main(image, boot):
    ours = bytearray(open(boot, 'rb').read())
    if len(ours) != 512:
        sys.exit("bootsect.py: %s is %d bytes" % (boot, len(ours)))

    with open(image, 'r+b') as f:
        theirs = bytearray(f.read(512))
        check(theirs[BPB], image)
        ours[BPB] = theirs[BPB]
        f.seek(0)
        f.write(ours)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit("usage: python3 bootsect.py <image> <boot sector>")
    main(sys.argv[1], sys.argv[2])
