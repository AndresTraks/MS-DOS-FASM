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

# Each module alone first, laid down the way MASM did, so that checkobj.py
# can hold it against the object MASM made of it.
#
# IBMBIO, the BIOS proper -- see src/BIOLNK.ASM.
$FASM src/BIOLNK.ASM bin/IBMBIO.BIN

# IBMMTCON, the console driver: the screen, the keyboard, eight virtual
# screens and an ANSI interpreter -- see src/MTCLNK.ASM.
$FASM src/MTCLNK.ASM bin/IBMMTCON.BIN

# IBMDSK, the disk drivers: the floppy and the fixed disk, a state machine
# apiece, and the Int 13 handler the rest of the system makes its requests
# through -- see src/DSKLNK.ASM.
$FASM src/DSKLNK.ASM bin/IBMDSK.BIN

# And the whole BIOS: the three modules laid out where LINK put them, with
# SYSINITSEG -- the SYSINIT program, whose source was never published --
# resolved out of SYSINI.OBJ and SYSIMES.OBJ.  This one is bootable, and
# 12363 bytes is the length of the IBMBIO.COM Microsoft shipped.  See
# src/BIOSLNK.ASM, and create_image.sh for the disk to start it from.
python3 -I sysinit.py
$FASM src/BIOSLNK.ASM bin/IBMBIO.COM
