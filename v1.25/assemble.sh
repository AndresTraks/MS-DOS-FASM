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

$FASM source/IO.ASM bin/IO.SYS
$FASM source/STDDOS.ASM bin/MSDOS.SYS
$FASM source/COMMAND.ASM bin/COMMAND.COM
$FASM source/ASM.ASM bin/ASM.COM
$FASM source/HEX2BIN.ASM bin/HEX2BIN.COM

$FASM bootsect.asm bin/bootsect.bin
