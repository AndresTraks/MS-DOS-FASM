#!/bin/sh
# Load VDISK.SYS from CONFIG.SYS on the system this builds, and use the disk
# it makes in memory.
#
# VDISK is a block driver like DRIVER.SYS, but where DRIVER hands every
# request back to the BIOS, this one answers them itself: the disk is a
# stretch of memory it has taken, and a read or a write is a move.  What it
# has to get right before DOS will look at it at all is the layout -- the
# initialisation writes the boot record, both copies of the FAT and the
# directory, with the volume label in the first entry -- so a drive it has
# made is one DOS reads without FORMAT ever having run.
#
#   DEVICE=\VDISK.SYS 64 512 16   64K, 512-byte sectors, 16 directory entries
#   DIR C:                        the disk it made, with its label
#   COPY, TYPE, DIR C:            and the file calls go through it
#
# The label is the proof of the layout: DIR reads it out of the directory
# the driver wrote, and the driver also reads it back itself to tell whether
# one of its disks is there already.  The three numbers are the proof of the
# parser: they are positional, not switches, and the messages the driver
# prints say what it made of them.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/vdisk.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/VDISK.SYS ::VDISK.SYS
printf 'the file copied into memory\r\n' > "$OUT/HELLO.TXT"
mcopy -o -i "$IMG" "$OUT/HELLO.TXT" ::HELLO.TXT

printf 'DEVICE=\\VDISK.SYS 64 512 16\r\n' > "$OUT/CONFIG.SYS"
mcopy -o -i "$IMG" "$OUT/CONFIG.SYS" ::CONFIG.SYS

{
    printf 'ECHO OFF\r\n'
    printf 'DIR C:\r\n'
    printf 'COPY HELLO.TXT C:\r\n'
    printf 'TYPE C:HELLO.TXT\r\n'
    printf 'DIR C:\r\n'
    printf 'ECHO THAT IS ALL\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT
# the entries mtools wrote get the tidying create_image.sh gives the rest
python3 dosdir.py "$IMG"

{
    await "THAT IS ALL" 1
    awaitprompt
    snap
    cp "$SHOT" "$OUT/screen.bin"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

python3 - "$OUT/screen.bin" <<'PY' || exit 1
import subprocess
import sys

screen = subprocess.run([sys.executable, "tests/screen.py", sys.argv[1]],
                        capture_output=True, text=True).stdout

print("--- what it said")
for line in screen.split("\n"):
    if line.strip():
        print("   %s" % line.rstrip())

rc = 0
print("--- checks")


def ok(yes, why, missing=None):
    global rc
    if yes:
        print("ok      %s" % why)
    else:
        print("WRONG   %s" % (missing or why))
        rc = 1


ok("MS-DOS Version 4.00, VDISK virtual disk C" in screen,
   "the driver installed and says which letter DOS gave it, which is its "
   "message 3 with the letter substituted into it -- in the wording of "
   "MESSAGES/USA-MS.MSG, which is where the text comes from, and not the "
   "skeleton's own")
ok("Buffer size:" in screen and "Sector size:" in screen
   and "Directory entries: 16" in screen,
   "and says what it made of the three numbers on the line, which are "
   "positional and not switches")
ok("VDISK  V4.0" in screen,
   "and DIR read the volume label out of the directory the initialisation "
   "wrote, which is the whole layout proved: boot record, FAT and directory")
ok("1 File(s) copied" in screen,
   "COPY wrote a file into it, the driver answering the write itself")
ok("the file copied into memory" in screen,
   "and TYPE read it back out again")
ok("HELLO    TXT" in screen,
   "and the second DIR lists it in the directory the driver keeps")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt")
sys.exit(rc)
PY
