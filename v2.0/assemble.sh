#!/bin/sh
set -e
cd "$(dirname "$0")"

if command -v fasm >/dev/null 2>&1; then
    FASM=fasm
elif command -v wine >/dev/null 2>&1; then
    FASM="wine ../fasmw17332/FASM.EXE"
    WINEDEBUG=${WINEDEBUG:--all}
    export WINEDEBUG
else
    echo "Neither fasm nor wine found. Please install one of them." >&2
    exit 1
fi

# MSDOS.ASM includes the modules DOSLINK used to hand to the linker, in that
# order.
$FASM source/MSDOS.ASM bin/MSDOS.SYS

# IO.ASM is the IBM BIOS, and it assembles SYSINIT.ASM in behind itself, which
# is what the original build did by linking SYSINIT.OBJ after the BIOS.
# SKELIO.ASM, the skeleton Microsoft shipped, drives an Altos ACS-86C instead.
$FASM source/IO.ASM bin/IO.SYS

$FASM bootsect.asm bin/bootsect.bin

# An installable character device driver, to have something to put on a
# DEVICE= line.  Not on the image: tests/config.sh is what loads it.
$FASM source/TESTDEV.ASM bin/TESTDEV.SYS

# FORMAT.COM, from FORMAT.ASM, the generic OEM module GENFOR.ASM and the
# messages.  The release shipped no FORMAT.COM, so this is the only one
# there is -- see FORLINK.ASM.
$FASM source/FORLINK.ASM bin/FORMAT.COM

# COMMAND.COM, from the sixteen modules COMLINK lists.  Built under another
# name so that Microsoft's, which the release shipped and which is useful to
# compare against, stays where it is; create_image.sh puts this one on the
# image as COMMAND.COM.
$FASM source/COMLINK.ASM bin/COMMANDF.COM
