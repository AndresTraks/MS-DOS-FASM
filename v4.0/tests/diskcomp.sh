#!/bin/sh
# Run DISKCOMP.COM on the system this builds, over two drives.
#
# DISKCOMP compares two diskettes track by track, and it is the first of the
# utilities to ask the driver for the shape of the medium and then read whole
# tracks of it: the generic IOCTL calls -- get device parameters with the
# media's BPB, set them as the drive's default, read a track -- are what
# carry it, so the geometry it prints is the kernel's answer and the data it
# compares came through INT 21H AX=440DH CL=61H.
#
# It fills all the memory it can with tracks of the first diskette, then
# reads the second a track at a time and compares, and goes round again for
# as many batches as the disk takes.  The volume serial number is copied from
# one buffer to the other before the first comparison, so that two disks
# formatted apart still compare equal.
#
# The machine is given two floppy drives, which is what makes it a two drive
# compare and not a swapping one.  Both runs send their output to the printer
# -- QEMU writes it to a file -- so nothing is written to either diskette
# while it is being compared, and the whole of it is read back here however
# much of it scrolled off the screen.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/diskcomp.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/DISKCOMP.COM ::DISKCOMP.COM
printf 'ECHO OFF\r\nDISKCOMP A: B: > PRN\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# run <second image> <printer file>: a key for "press any key", an N for
# "compare another diskette", and the Return that answers COMMAND.COM.
run() {
    : > "$2"
    {
        awaitprint "$2" "Press any key to continue"
        echo "sendkey a"
        awaitprint "$2" "Compare another diskette (Y/N) ?"
        echo "sendkey n"
        sleep 0.1
        echo "sendkey ret"
        awaitprompt
        echo quit
    } | "$QEMU" -rtc base=localtime \
                -drive file="$IMG",format=raw,if=floppy,index=0 \
                -drive file="$1",format=raw,if=floppy,index=1 \
                -parallel "file:$2" \
                -display none -monitor stdio >/dev/null 2>&1 || true
    [ -s "$2" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }
}

# The same disk twice.
cp "$IMG" "$OUT/same.img"
run "$OUT/same.img" "$OUT/same.txt"

# And a copy with one byte changed in two places.  Byte 40000 is sector 78,
# which is cylinder 2 side 0; byte 700000 is sector 1367, cylinder 37 side 1.
cp "$IMG" "$OUT/differs.img"
printf '\356' | dd of="$OUT/differs.img" bs=1 seek=40000 count=1 \
    conv=notrunc status=none
printf '\167' | dd of="$OUT/differs.img" bs=1 seek=700000 count=1 \
    conv=notrunc status=none
run "$OUT/differs.img" "$OUT/differs.txt"

python3 - "$OUT/same.txt" "$OUT/differs.txt" <<'PY' || exit 1
import sys

same = open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
differs = open(sys.argv[2], "rb").read().decode("cp437").replace("\r", "")
print("--- the same disk twice")
for line in same.split("\n"):
    if line.strip():
        print("   %s" % line)
print("--- one byte changed in two places")
for line in differs.split("\n"):
    if line.strip():
        print("   %s" % line)

rc = 0
print("--- checks")
want = [(same, "Insert FIRST diskette in drive A:",
         "it asked for the first disk, with the drive letter put in"),
        (same, "Insert SECOND diskette in drive B:",
         "and the second, so it knows there are two drives"),
        (same, "Comparing 80 tracks",
         "the number of tracks came from the drive's parameters"),
        (same, "18 sectors per track, 2 side(s)",
         "and the sectors and sides from the medium's BPB"),
        (same, "Compare OK",
         "the same disk twice compares equal, serial number and all"),
        (same, "Compare another diskette (Y/N) ?",
         "and it asked whether to go round again"),
        (differs, "side 0, track 2",
         "the byte changed at 40000 is on cylinder 2, side 0"),
        (differs, "side 1, track 37",
         "and the one at 700000 on cylinder 37, side 1")]
for text, needle, why in want:
    if needle in text:
        print("ok      %s: %s" % (needle, why))
    else:
        print("MISSING %s" % needle)
        rc = 1

if "Compare OK" not in differs:
    print("ok      the disk that differs is not called equal")
else:
    print("WRONG   it said Compare OK of two disks that differ")
    rc = 1
n = differs.count("Compare error on")
if n == 2:
    print("ok      two differences reported and no others")
else:
    print("WRONG   %d compare errors reported, wanted 2" % n)
    rc = 1
sys.exit(rc)
PY
