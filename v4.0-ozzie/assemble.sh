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

# IBMBIO, the BIOS proper.  Not a bootable IBMBIO.COM and it cannot be: two
# of the five objects BIOSOBJ.MAK links were shipped without their sources.
# What this is for is to lay down the one module the way MASM did, so that
# checkobj.py can hold it against IBMBIO.OBJ -- see src/BIOLNK.ASM.
$FASM src/BIOLNK.ASM bin/IBMBIO.BIN

# IBMMTCON, the console driver: the screen, the keyboard, eight virtual
# screens and an ANSI interpreter -- see src/MTCLNK.ASM.
$FASM src/MTCLNK.ASM bin/IBMMTCON.BIN

# IBMDSK, the disk drivers: the floppy and the fixed disk, a state machine
# apiece, and the Int 13 handler the rest of the system makes its requests
# through -- see src/DSKLNK.ASM.
$FASM src/DSKLNK.ASM bin/IBMDSK.BIN
