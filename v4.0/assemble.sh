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
# write.  Each skeleton writes one include file per class it declares, beside
# the skeleton, named after it: BOOT.SKL writes BOOT.CL1.
python3 buildmsg.py src/BOOT/BOOT.SKL >/dev/null

# The boot sector.  The release also ships what MASM made of it, as the DB
# statements in INC/BOOT.INC -- FORMAT and SYS include that to write a boot
# sector onto a disk -- so this one can be held against Microsoft's byte for
# byte; tests/msboot.sh does that.
$FASM src/BOOT/MSBOOT.ASM bin/MSBOOT.BIN

# The BIOS's messages: five classes, for the five modules that hold them.
python3 buildmsg.py src/BIOS/MSBIO.SKL >/dev/null

# MSLOAD, the second stage of the boot and the first three sectors of IO.SYS.
# The boot sector reads those three and jumps to them; this walks the FAT to
# read the rest of the BIOS in, so IO.SYS need not be contiguous past its
# first cluster.  tests/msload.sh checks that it still fits in three.
$FASM src/BIOS/MSLOAD.ASM bin/MSLOAD.COM

# The BIOS proper: thirteen modules in two segments -- see MSBIOLNK.ASM.
$FASM src/BIOS/MSBIOLNK.ASM bin/MSBIO.BIN

# IO.SYS is the two of them, one after the other, which is what the original
# build did with "copy /b msload.com+msbio.bin io.sys".
cat bin/MSLOAD.COM bin/MSBIO.BIN > bin/IO.SYS
