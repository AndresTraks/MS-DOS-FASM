#!/usr/bin/env python3
#
# Make a diskette's root directory what DOS 4 would have written.
#
# A directory entry has ten bytes after the attribute that DOS 4 left alone
# and zero -- the release's own FORMAT and its file creation both write
# zeros there.  mtools fills them in the way the assemblers of long file
# names later did, with the time and date the file was created and the date
# it was last read, and those bytes reach further than the directory: the
# boot sector reads the first sector of the root directory to 0:0500 and
# leaves it there, and 0:0530 -- which lands in the middle of the second
# entry, the one for MSDOS.SYS -- is where MODE keeps the far pointer to its
# own resident part.  With mtools's dates in those bytes MODE finds a
# pointer that was never written and takes itself for loaded already.
#
# Two of those ten are DOS 4's own: a directory entry has dir_codepg at 0CH
# and dir_extcluster at 0EH, the cluster a file's extended attributes begin
# at.  mtools writes the creation time there, so DOS reads a file on a disk
# it wrote as having extended attributes somewhere off the end of the disk
# -- 8E83H on the one tests/mkhd.py lays down -- and DIR does not list it.
#
# So the ten bytes go back to zero, for every entry of the root directory.
#
#   python3 dosdir.py <image> [<offset of the volume in it>]
#
# The offset is for a hard disk, whose first sector is a partition table and
# whose volume begins further in; tests/mkhd.py says where.
import sys

RESERVED = slice(0x0C, 0x16)


def main(image, base=0):
    with open(image, 'r+b') as f:
        f.seek(base)
        boot = f.read(512)
        sector = boot[0x0B] | (boot[0x0C] << 8)
        reserved = boot[0x0E] | (boot[0x0F] << 8)
        fats = boot[0x10]
        fatsize = boot[0x16] | (boot[0x17] << 8)
        entries = boot[0x11] | (boot[0x12] << 8)
        at = base + (reserved + fats * fatsize) * sector
        f.seek(at)
        root = bytearray(f.read(entries * 32))
        for i in range(entries):
            entry = root[i * 32:(i + 1) * 32]
            if entry[0] in (0, 0xE5):   # never used, or erased
                continue
            entry[RESERVED] = bytes(10)
            root[i * 32:(i + 1) * 32] = entry
        f.seek(at)
        f.write(root)


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'msdos.img',
         int(sys.argv[2]) if len(sys.argv) > 2 else 0)
