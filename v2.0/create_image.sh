#!/bin/sh
set -e
cd "$(dirname "$0")"
IMAGE=msdos.img

./assemble.sh

rm -f "$IMAGE"
mformat -C -f 1440 -i "$IMAGE" ::

# IO.SYS and MSDOS.SYS go on first and in this order: the boot sector reads
# each from its first cluster onwards and assumes it is contiguous.
mcopy -i "$IMAGE" bin/IO.SYS ::
mcopy -i "$IMAGE" bin/MSDOS.SYS ::

# COMMAND.COM is the one Microsoft shipped. The COMLINK sources for it are
# still MASM, so there is nothing of ours to put here yet.
mcopy -i "$IMAGE" bin/COMMAND.COM ::

dd if=bin/bootsect.bin of="$IMAGE" bs=512 count=1 conv=notrunc status=none
