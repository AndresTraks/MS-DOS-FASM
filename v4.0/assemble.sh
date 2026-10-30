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

# The kernel's messages: MSDOS.SKL declares two classes, the divide-overflow
# message the kernel prints on INT 0 and the yes/no letters for INT 24H.
python3 buildmsg.py src/DOS/MSDOS.SKL >/dev/null

# MSDOS.SYS: fifty-five modules and six segments in one group, gathered by
# MSDOSLNK.ASM.  Microsoft's own EndProc check prints a line for each of the
# twelve procedures whose SaveReg and RestoreReg do not pair up inside the
# procedure -- the same twelve as in the release, which does its RestoreReg
# on a shared way out -- so those lines are expected.
$FASM src/DOS/MSDOSLNK.ASM bin/MSDOS.SYS

# The utilities under src/CMD.  Each one is built from its own directory, so
# the INCLUDE path has the shared headers in src/INC first and the utility's
# own directory after it -- which is where its messages are written.  That is
# how MASM found them as well: the build ran in the utility's directory with
# INCLUDE pointing at src/INC.
#
# MORE, the smallest of them: one module, the message retriever, and the
# structured statements in INC/STRUC.INC.
# utility <directory> <source> <output>
utility() {
    python3 buildmsg.py "src/CMD/$1/$1.SKL" >/dev/null
    if [ "$FASM" = fasm ]; then
        INCLUDE="$PWD/src/INC:$PWD/src/CMD/$1"
    else
        # fasm.exe reads the path the way Windows writes one.
        win() { printf 'Z:%s' "$(echo "$1" | sed 's|/|\\|g')"; }
        INCLUDE="$(win "$PWD/src/INC");$(win "$PWD/src/CMD/$1")"
    fi
    export INCLUDE
    $FASM "src/CMD/$1/$2.ASM" "bin/$3"
    unset INCLUDE
}

utility MORE MORE MORE.COM

# SORT, the first of them built as an .EXE: CODE, CONST and CSTACK in one
# group, which SORTLNK.ASM lays down as one segment.
utility SORT SORTLNK SORT.EXE
