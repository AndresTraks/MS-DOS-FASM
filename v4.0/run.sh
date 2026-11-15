#!/bin/sh
set -e
cd "$(dirname "$0")"
QEMU=${QEMU:-qemu-system-i386}

./create_image.sh

# create_image.sh makes the system disk and nothing else, which is what the
# tests want of it -- two of them count what is on the disk.  A machine driven
# by hand wants the programs as well, so they go on here: the utilities under
# src/CMD and the drivers under src/DEV that are converted, in the order
# assemble.sh builds them.  A driver is loaded by a DEVICE= line in
# CONFIG.SYS, which this disk has none of; it is here to be named by one.
for util in MORE.COM SORT.EXE FIND.EXE LABEL.COM TREE.COM COMP.COM EXE2BIN.EXE \
            RECOVER.COM DISKCOMP.COM DISKCOPY.COM EDLIN.COM SYS.COM \
            CHKDSK.COM XCOPY.EXE FORMAT.COM DEBUG.COM GRAFTABL.COM \
            MODE.COM ASSIGN.COM NLSFUNC.EXE APPEND.EXE PRINT.COM \
            FASTOPEN.EXE KEYB.COM GRAPHICS.COM SHARE.EXE IFSFUNC.EXE \
            DRIVER.SYS ANSI.SYS VDISK.SYS DISPLAY.SYS PRINTER.SYS; do
    mcopy -o -i msdos.img "bin/$util" "::$util"
done

# and the entries those left get the same tidying create_image.sh gives the
# system's, so that the disk is one DOS 4 could have written.
python3 dosdir.py msdos.img

if ! command -v "$QEMU" >/dev/null 2>&1; then
    echo "$QEMU not found. Please install QEMU." >&2
    exit 1
fi

exec "$QEMU" -rtc base=localtime -drive file=msdos.img,format=raw,if=floppy,index=0
