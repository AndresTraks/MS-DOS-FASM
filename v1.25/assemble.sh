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

# TRANS.COM, the Z80-to-8086 translator: it reads a Z80 source and writes
# 8086 source for ASM.COM, which is how the programs 86-DOS was made of were
# carried over from CP/M.  The release ships it and its own build never built
# it; nothing in this tree did either until now.  Every system call it makes
# goes through the CP/M-compatible call at offset 5 of its program base,
# which is why IO.ASM masks the A20 line.
$FASM source/TRANS.ASM bin/TRANS.COM

$FASM bootsect.asm bin/bootsect.bin
