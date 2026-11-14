#!/bin/sh
# Load DRIVER.SYS from CONFIG.SYS on the system this builds, and read a disk
# through the letter it gives.
#
# DRIVER.SYS is the external block driver: CONFIG.SYS names it to give
# another letter to a drive the BIOS already has, with a BPB of its own if
# the switches say so.  It does almost none of the work itself -- the BIOS's
# own block driver answers INT 2FH multiplex 8, so function 1 hands it the
# BDS this driver has filled in, and from then on every request this driver
# is given it passes back through function 2 with the unit number changed.
# What is its own is the initialisation: the parser reads the switches, the
# BDS is filled in from the form factor and the ranges in the tables, and
# the retriever's message says which letter DOS gave it.
#
#   DEVICE=\DRIVER.SYS /D:0    a second letter for the one floppy
#   DEVICE=\DRIVER.SYS /T:9    no /D, so the parser's own refusal
#   DIR C:                     and the new letter reads the disk
#
# The second line is the parse side of it: /D is the one switch DRIVER.SYS
# requires, and without it the initialisation says so and fails, which is
# its message 2 and then SYSINIT's own complaint about the line -- ERR$EXIT
# sets the unit count to nought and the CONFIG_ERRMSG field to -1 to ask for
# that second message.
#
# DIR C: is the proof that the first line took: DOS asks for the diskette
# first, because A:, B: and C: are three logical drives on the one physical
# drive and the last one to use it was A:, and what comes back is this disk
# read through the driver.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/driver.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/DRIVER.SYS ::DRIVER.SYS
printf 'the file read through the driver\r\n' > "$OUT/HELLO.TXT"
mcopy -o -i "$IMG" "$OUT/HELLO.TXT" ::HELLO.TXT

printf 'DEVICE=\\DRIVER.SYS /D:0\r\nDEVICE=\\DRIVER.SYS /T:9\r\n' \
    > "$OUT/CONFIG.SYS"
mcopy -o -i "$IMG" "$OUT/CONFIG.SYS" ::CONFIG.SYS

{
    printf 'ECHO OFF\r\n'
    printf 'DIR C:\r\n'
    printf 'ECHO THAT IS ALL\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT
# the entries mtools wrote get the tidying create_image.sh gives the rest
python3 dosdir.py "$IMG"

{
    # DOS wants the diskette for the new drive before it will read it: the
    # disk is already in, so any key will do.
    await "Insert diskette for drive C"
    echo "sendkey ret"
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


ok("Loaded External Disk Driver for Drive C" in screen,
   "the first line installed the driver and DOS gave it C:, which is the "
   "retriever's message 3 with the letter substituted into it")
ok("No drive specified" in screen,
   "the second line had no /D, which is the parser's own refusal and the "
   "driver's message 2")
ok("Volume in drive C" in screen,
   "and DIR read the disk through the new letter, every request going out "
   "through INT 2FH multiplex 8 function 2 to the BIOS's own block driver")
ok("HELLO    TXT" in screen,
   "the directory came back with the file in it")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt")
sys.exit(rc)
PY
