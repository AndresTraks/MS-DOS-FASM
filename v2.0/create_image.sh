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

# The rest of the executables.  Most are Microsoft's, the ones built from
# source here saying so, and they are what there is to run on the system;
# all of them together take a sixth of the disk.
# CHKDSK is ours.  The one Microsoft shipped was built for 2.00 and answers
# "Incorrect DOS version" to the 2.11 this DOS reports, the same as its SYS
# -- see source/CHKLINK.ASM.
mcopy -i "$IMAGE" bin/CHKDSKF.COM ::CHKDSK.COM
mcopy -i "$IMAGE" bin/CREF.EXE ::
mcopy -i "$IMAGE" bin/DEBUG.COM ::
# DISKCOPY is ours, Microsoft's staying in bin to compare against.
mcopy -i "$IMAGE" bin/DISKCOPF.COM ::DISKCOPY.COM
# EDLIN is ours, Microsoft's staying in bin to compare against.
mcopy -i "$IMAGE" bin/EDLINF.COM ::EDLIN.COM
# EXE2BIN is ours, Microsoft's staying in bin to compare against.
mcopy -i "$IMAGE" bin/EXE2BINF.EXE ::EXE2BIN.EXE
# FC is ours, Microsoft's staying in bin to compare against.
mcopy -i "$IMAGE" bin/FCF.EXE ::FC.EXE
# FIND is ours, Microsoft's staying in bin to compare against.
mcopy -i "$IMAGE" bin/FINDF.EXE ::FIND.EXE
mcopy -i "$IMAGE" bin/LINK.EXE ::
mcopy -i "$IMAGE" bin/MASM.EXE ::
# MORE is ours too, Microsoft's staying in bin to compare against.
mcopy -i "$IMAGE" bin/MOREF.COM ::MORE.COM
# PRINT is the one Microsoft shipped, which answers "Incorrect DOS
# version" here -- it was built from the source that accepts up to 2.00.
# Ours is built from the 2.11 source and installs, but is not fit to use
# yet; see source/PRTLINK.ASM.
mcopy -i "$IMAGE" bin/PRINT.COM ::
mcopy -i "$IMAGE" bin/PROHST.EXE ::
# RECOVER is ours, Microsoft's staying in bin to compare against.
mcopy -i "$IMAGE" bin/RECOVEF.COM ::RECOVER.COM
# SORT is ours, Microsoft's staying in bin to compare against.
mcopy -i "$IMAGE" bin/SORTF.EXE ::SORT.EXE
# SYS is ours as well, the shipped one refusing this version.
mcopy -i "$IMAGE" bin/SYSF.COM ::SYS.COM

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
