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

# COMMAND.COM is ours, from the sixteen modules COMLINK lists.  Microsoft's
# is kept in bin to compare against: boot with it by copying bin/COMMAND.COM
# over the one on the image.
mcopy -i "$IMAGE" bin/COMMANDF.COM ::COMMAND.COM

# The rest of the release's executables.  They are Microsoft's -- nothing
# here is built from source yet -- but they are what there is to run on the
# system, and all of them together take a sixth of the disk.
mcopy -i "$IMAGE" bin/CHKDSK.COM ::
mcopy -i "$IMAGE" bin/CREF.EXE ::
mcopy -i "$IMAGE" bin/DEBUG.COM ::
mcopy -i "$IMAGE" bin/DISKCOPY.COM ::
mcopy -i "$IMAGE" bin/EDLIN.COM ::
mcopy -i "$IMAGE" bin/EXE2BIN.EXE ::
mcopy -i "$IMAGE" bin/FC.EXE ::
mcopy -i "$IMAGE" bin/FIND.EXE ::
mcopy -i "$IMAGE" bin/LINK.EXE ::
mcopy -i "$IMAGE" bin/MASM.EXE ::
mcopy -i "$IMAGE" bin/MORE.COM ::
mcopy -i "$IMAGE" bin/PRINT.COM ::
mcopy -i "$IMAGE" bin/PROHST.EXE ::
mcopy -i "$IMAGE" bin/RECOVER.COM ::
mcopy -i "$IMAGE" bin/SORT.EXE ::
mcopy -i "$IMAGE" bin/SYS.COM ::

# FORMAT is ours and nobody else's: the release has the source but no
# FORMAT.COM to go with it.
mcopy -i "$IMAGE" bin/FORMAT.COM ::

# The profiler, which is in pieces: PROFIL.OBJ is Microsoft's, assembled, and
# the clock module it wants is ours.  PCLOCK_IBM.ASM goes on as PCLOCKPC.ASM
# because PCLOCK.ASM is taken, by Microsoft's for the Seattle Computer
# Products machine, and because the name has to fit 8.3 for DOS to see it.
# tests/profil.bat builds and runs it on the system itself.
mcopy -i "$IMAGE" bin/PROFIL.OBJ ::
mcopy -i "$IMAGE" source/PCLOCK_IBM.ASM ::PCLOCKPC.ASM

dd if=bin/bootsect.bin of="$IMAGE" bs=512 count=1 conv=notrunc status=none
