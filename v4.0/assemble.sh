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

mkdir -p bin

# Every program in this release takes its text from MESSAGES/USA-MS.MSG, and
# BUILDMSG, which Microsoft shipped as a binary and not as source, is what
# turned a program's .SKL skeleton into the include file holding it.
# buildmsg.py is that step again -- see the file for the two shapes it has to
# write.
python3 buildmsg.py src/BOOT/BOOT.SKL src/BOOT/BOOT.CL1

# The boot sector.  The release also ships what MASM made of it, as the DB
# statements in INC/BOOT.INC -- FORMAT and SYS include that to write a boot
# sector onto a disk -- so this one can be held against Microsoft's byte for
# byte; tests/msboot.sh does that.
$FASM src/BOOT/MSBOOT.ASM bin/MSBOOT.BIN
