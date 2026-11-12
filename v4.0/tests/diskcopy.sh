#!/bin/sh
# Run DISKCOPY.COM on the system this builds, from one drive to another.
#
# DISKCOPY makes a copy of a whole diskette, track by track, through the same
# generic IOCTL calls DISKCOMP reads with -- get device parameters, set them,
# read a track, write a track, format a track.  The target here is 2880
# sectors of nothing, so it has no format at all and DISKCOPY has to lay one
# down as it goes, which is what "Formatting while copying" says.
#
# What comes out should be the source byte for byte with one exception: the
# copy is given a volume serial number of its own, four bytes in the boot
# record, and the number it prints is the number it wrote.  That is the
# reason DISKCOMP copies the serial from one buffer to the other before it
# compares, and this test holds the two disks against each other to see that
# those four bytes are the only difference.
#
# The machine is given two floppy drives, and the output goes to the printer
# -- QEMU writes it to a file -- so the whole of it is here however much
# scrolled off the screen.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }
command -v mdir >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/diskcopy.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/DISKCOPY.COM ::DISKCOPY.COM
printf 'a file to copy\r\n' > "$OUT/HELLO.TXT"
mcopy -o -i "$IMG" "$OUT/HELLO.TXT" ::HELLO.TXT
printf 'ECHO OFF\r\nDISKCOPY A: B: > PRN\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# The target: a diskette with nothing on it, not even a format.
dd if=/dev/zero of="$OUT/b.img" bs=512 count=2880 status=none

{
    awaitprint "$OUT/prn.txt" "Press any key to continue"
    echo "sendkey a"
    awaitprint "$OUT/prn.txt" "Copy another diskette (Y/N)?"
    echo "sendkey n"
    sleep 0.1
    echo "sendkey ret"
    awaitprompt
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -drive file="$OUT/b.img",format=raw,if=floppy,index=1 \
            -parallel "file:$OUT/prn.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/prn.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }
mdir -i "$OUT/b.img" :: > "$OUT/dir.txt" 2>/dev/null || true

python3 - "$OUT/prn.txt" "$IMG" "$OUT/b.img" "$OUT/dir.txt" <<'PY' || exit 1
import re
import sys

said = open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
src = open(sys.argv[2], "rb").read()
copy = open(sys.argv[3], "rb").read()
listing = open(sys.argv[4]).read()

print("--- what it said")
for line in said.split("\n"):
    if line.strip():
        print("   %s" % line)

rc = 0
print("--- checks")
want = [("Insert SOURCE diskette in drive A:",
         "it asked for the source, with the drive letter put in"),
        ("Insert TARGET diskette in drive B:",
         "and the target, so it knows there are two drives"),
        ("Copying 80 tracks",
         "the number of tracks came from the drive's parameters"),
        ("18 Sectors/Track, 2 Side(s)",
         "and the sectors and sides from the medium"),
        ("Formatting while copying",
         "the target had no format on it, so one was laid down as it went"),
        ("Copy another diskette (Y/N)?",
         "and it asked whether to go round again")]
for needle, why in want:
    if needle in said:
        print("ok      %s: %s" % (needle, why))
    else:
        print("MISSING %s" % needle)
        rc = 1

# The copy should be the source byte for byte but for the serial number,
# which lives in the boot record at 27H and is four bytes long.  DISKCOPY
# makes a new one out of the clock, so how many of the four come out
# different is chance: all that is asked is that the serial is the only
# thing that moved, and that it did move.
serial = set(range(39, 43))
differ = [i for i in range(len(src)) if src[i] != copy[i]]
if differ and set(differ) <= serial:
    print("ok      the copy is the source byte for byte but for %d of the "
          "four bytes of the volume serial number, which DISKCOPY writes "
          "afresh" % len(differ))
else:
    print("WRONG   %d bytes differ: %s" % (len(differ), differ[:12]))
    rc = 1

m = re.search(r"Volume Serial Number is ([0-9A-F]{4})-([0-9A-F]{4})", said)
if not m:
    print("MISSING the serial number it wrote")
    rc = 1
else:
    wrote = bytes([int(m.group(2)[2:], 16), int(m.group(2)[:2], 16),
                   int(m.group(1)[2:], 16), int(m.group(1)[:2], 16)])
    if copy[39:43] == wrote:
        print("ok      the number it printed, %s-%s, is the one in the copy's "
              "boot record" % m.groups())
    else:
        print("WRONG   it printed %s-%s and wrote %s"
              % (m.group(1), m.group(2), copy[39:43].hex(" ")))
        rc = 1

for name in ("DISKCOPY COM", "HELLO    TXT", "COMMAND  COM"):
    if name in listing:
        print("ok      %s is on the copy and readable from outside" % name)
    else:
        print("MISSING %s from the copy" % name)
        rc = 1
sys.exit(rc)
PY
