#!/bin/sh
set -e
cd "$(dirname "$0")"
# The image to write, msdos.img unless another is named: a test makes one of
# its own and puts its own files on it, which is how the tests under tests/
# are run side by side without treading on each other or on this one.
IMAGE=${1:-msdos.img}

./assemble.sh

rm -f "$IMAGE"
mformat -C -f 1440 -i "$IMAGE" ::

mcopy -i "$IMAGE" bin/IO.SYS ::
mcopy -i "$IMAGE" bin/MSDOS.SYS bin/COMMAND.COM bin/ASM.COM bin/HEX2BIN.COM bin/TRANS.COM ::

mcopy -i "$IMAGE" \
    bin/BASIC.COM bin/BASICA.COM bin/CHKDSK.COM bin/COMP.COM bin/DEBUG.COM \
    bin/DISKCOMP.COM bin/DISKCOPY.COM bin/EDLIN.COM bin/EXE2BIN.EXE \
    bin/FORMAT.COM bin/GWBASIC.COM bin/LINK.EXE bin/MODE.COM bin/SETCLOCK.COM \
    bin/SYS.COM ::

mcopy -i "$IMAGE" bin/*.BAS bin/HELLO.HEX ::

dd if=bin/bootsect.bin of="$IMAGE" bs=512 count=1 conv=notrunc status=none
