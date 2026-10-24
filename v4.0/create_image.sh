#!/bin/sh
# Make a 1440K diskette this system can be started from.
#
# FORMAT is what would normally lay the boot sector down, and FORMAT is one of
# the thirty-odd utilities not converted yet, so the disk is made here: mformat
# writes the file system, and sector 0 is replaced by the boot sector
# MSBOOT.ASM builds.
#
# The boot sector carries the BPB that describes the disk it is on, and
# MSBOOT.ASM declares one for a hard file -- media F8, seventeen sectors a
# track, four surfaces, the boot drive 80h -- because that is what the release
# leaves in the source for FORMAT to overwrite.  So the table is taken from
# what mformat wrote and put into our sector, from the sector size at offset
# 0Bh to the end of the extended BPB, which is exactly what FORMAT and SYS do.
#
# IO.SYS goes on first and MSDOS.SYS second: the boot sector reads the first
# two entries of the root directory and expects to find them there, by name.
set -e
cd "$(dirname "$0")"
IMAGE=msdos.img

./assemble.sh >/dev/null

rm -f "$IMAGE"
mformat -C -f 1440 -i "$IMAGE" ::

# No volume label: it would take the first directory entry, and the boot
# sector wants IO.SYS there.

python3 - "$IMAGE" bin/MSBOOT.BIN <<'PY'
import sys
image, boot = sys.argv[1], sys.argv[2]
with open(image, "r+b") as f:
    theirs = bytearray(f.read(512))
    ours = bytearray(open(boot, "rb").read())
    assert len(ours) == 512, "the boot sector is %d bytes" % len(ours)
    # 0Bh to 3Eh: the BPB, the physical drive and head, and the extended
    # fields -- the serial number, the volume label and "FAT12".
    ours[0x0B:0x3E] = theirs[0x0B:0x3E]
    f.seek(0)
    f.write(ours)
PY

# IO.SYS and MSDOS.SYS, in the order the boot sector looks for them.
mcopy -i "$IMAGE" bin/IO.SYS ::
mcopy -i "$IMAGE" bin/MSDOS.SYS ::

# COMMAND.COM, which cannot be built yet -- the thirty-odd utilities under
# src/CMD are not converted -- so tests/shell.asm stands in for it.  SYSINIT
# finishes by EXECing the interpreter, and this one says so and echoes what is
# typed, which is the end to end proof that the kernel dispatches, the console
# driver writes and reads, and EXEC loads a program.
if command -v fasm >/dev/null 2>&1; then
    fasm tests/shell.asm bin/SHELL.COM >/dev/null
else
    WINEDEBUG=${WINEDEBUG:--all} wine ../fasmw17332/FASM.EXE tests/shell.asm bin/SHELL.COM >/dev/null
fi
mcopy -i "$IMAGE" bin/SHELL.COM ::COMMAND.COM
