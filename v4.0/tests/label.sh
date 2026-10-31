#!/bin/sh
# Run LABEL.COM on the system this builds, and see what it writes on the disk.
#
# LABEL is the first of the utilities whose work is a change to the disk
# rather than something printed: it creates, replaces and deletes the volume
# label, which is a directory entry with the volume_id attribute and nothing
# else in it.  So this drives it both ways -- with the name on the command
# line, and with no name at all, where it prints the label it found and asks
# for a new one through the message retriever's input side -- and then reads
# the disk back from outside the machine to see that the label really is on
# it.
#
# COMMAND.COM runs it, from an AUTOEXEC.BAT which also asks VOL for the label
# before and after, so what LABEL wrote is read back by the interpreter as
# well.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/label.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

# A disk of this test's own: it is read back here after the machine
# has written to it, so nothing else may lay a fresh one down under it.
IMG="$OUT/disk.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/LABEL.COM ::LABEL.COM

# The disk comes out of create_image.sh without a label, which is the first
# thing VOL is asked about.
printf 'ECHO OFF\r\nVOL\r\nLABEL MYDISK\r\nVOL\r\nLABEL\r\nVOL\r\n' \
    > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# The second LABEL has no name on its line, so it waits for one.  It is typed
# in lower case: LABEL upper cases it on the way to the directory.
{
    sleep 36
    for k in t h i r d ret; do echo "sendkey $k"; sleep 1; done
    sleep 10
    echo "pmemsave 0xb8000 4000 \"$OUT/screen.bin\""
    sleep 2
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

# The disk as it stands now, read without the machine's help.
mdir -i "$IMG" :: > "$OUT/dir.txt" 2>/dev/null || true

python3 - "$OUT/screen.bin" "$OUT/dir.txt" <<'PY' || exit 1
import sys
d = open(sys.argv[1], "rb").read()
rows = []
for row in range(25):
    cell = lambda c: d[(row * 80 + c) * 2]
    rows.append("".join(chr(cell(c)) if 32 <= cell(c) < 127 else " "
                        for c in range(80)).rstrip())
print("--- screen")
for r in rows:
    if r.strip():
        print("   %s" % r)
screen = "\n".join(rows)

rc = 0
print("--- checks")
want = [("Volume in drive A has no label",
         "the disk started without one, and VOL said so"),
        ("Volume in drive A is MYDISK",
         "LABEL took the name off its command line and wrote it"),
        ("Volume label (11 characters, ENTER for none)?",
         "LABEL with no name asked for one, through the retriever"),
        ("Volume in drive A is THIRD",
         "the name typed in lower case went in upper, over the old one"),
        ("Volume Serial Number is",
         "the serial number came back from GET_MEDIA_ID, four hex digits "
         "each half")]
for text, why in want:
    if text in screen:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1

head = open(sys.argv[2]).read()
if "is THIRD" in head:
    print("ok      the label is on the disk, read from outside the machine")
else:
    print("WRONG   the disk says %r" % head.split("\n")[0])
    rc = 1

last = [r for r in rows if r.strip()][-1]
if last.startswith("A>"):
    print("ok      the prompt is back: LABEL ended and COMMAND.COM has it "
          "again")
else:
    print("MISSING the prompt; the last line is %r" % last)
    rc = 1
sys.exit(rc)
PY
