#!/bin/sh
set -e
cd "$(dirname "$0")"
IMAGE=msdos.img

./assemble.sh

rm -f "$IMAGE"
mformat -C -f 1440 -i "$IMAGE" ::

mcopy -i "$IMAGE" bin/IO.SYS ::
mcopy -i "$IMAGE" bin/MSDOS.SYS bin/COMMAND.COM bin/ASM.COM bin/HEX2BIN.COM ::

mcopy -i "$IMAGE" \
    bin/BASIC.COM bin/BASICA.COM bin/CHKDSK.COM bin/COMP.COM bin/DEBUG.COM \
    bin/DISKCOMP.COM bin/DISKCOPY.COM bin/EDLIN.COM bin/EXE2BIN.EXE \
    bin/FORMAT.COM bin/GWBASIC.COM bin/LINK.EXE bin/MODE.COM bin/SETCLOCK.COM \
    bin/SYS.COM ::

mcopy -i "$IMAGE" bin/*.BAS bin/HELLO.HEX ::

dd if=bin/bootsect.bin of="$IMAGE" bs=512 count=1 conv=notrunc status=none
