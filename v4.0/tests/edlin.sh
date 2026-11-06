#!/bin/sh
# Run EDLIN.COM on the system this builds, through a whole edit.
#
# EDLIN is the line editor, and the first of the utilities that is driven
# from the keyboard rather than by its command line: it reads the file into
# memory, prompts with an asterisk, and takes a command at a time until E
# writes the file back.  So this types a session at it -- list, delete the
# second line, list again, end -- and then reads the disk from outside the
# machine to see what it wrote.
#
# The listing comes back through the message retriever: every line is a
# message with two substitutions, the number and the text, and the sublist
# hands the retriever the address of each as an offset and a segment.  The
# asterisk against a number is the current line.
#
# E writes the file and keeps the old one as .BAK, and DOS's line editor ends
# a text file with a Ctrl-Z, so both of those are checked as well.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/edlin.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/disk.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/EDLIN.COM ::EDLIN.COM

printf 'first line\r\nsecond line\r\nthird line\r\n' > "$OUT/TEST.TXT"
mcopy -o -i "$IMG" "$OUT/TEST.TXT" ::TEST.TXT
printf 'ECHO OFF\r\nEDLIN TEST.TXT\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# l lists, 2d deletes the second line, l lists again, e writes and ends.
# The screen is taken twice: after the first listing and after the second.
{
    await "End of input file"
    for k in l ret; do echo "sendkey $k"; sleep 0.1; done
    await "3: third line"
    cp "$SHOT" "$OUT/first.bin"
    for k in 2 d ret l ret; do echo "sendkey $k"; sleep 0.1; done
    await "2:*third line"
    cp "$SHOT" "$OUT/second.bin"
    for k in e ret; do echo "sendkey $k"; sleep 0.1; done
    awaitprompt
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/second.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

mcopy -n -i "$IMG" ::TEST.TXT "$OUT/after.txt" 2>/dev/null || true
mcopy -n -i "$IMG" ::TEST.BAK "$OUT/after.bak" 2>/dev/null || true

python3 - "$OUT/first.bin" "$OUT/second.bin" "$OUT/after.txt" "$OUT/after.bak" \
    <<'PY' || exit 1
import os
import sys


def screen(path):
    d = open(path, "rb").read()
    rows = []
    for row in range(25):
        cell = lambda c: d[(row * 80 + c) * 2]
        rows.append("".join(chr(cell(c)) if 32 <= cell(c) < 127 else " "
                            for c in range(80)).rstrip())
    return [r for r in rows if r.strip()]


first, second = screen(sys.argv[1]), screen(sys.argv[2])
print("--- after the first listing")
for r in first[-6:]:
    print("   %s" % r)
print("--- after deleting the second line")
for r in second[-6:]:
    print("   %s" % r)

rc = 0
print("--- checks")
one, two = "\n".join(first), "\n".join(second)
want = [(one, "End of input file",
         "the whole file was read into memory"),
        (one, "1:*first line",
         "the first line is listed, numbered, and marked as the current one"),
        (one, "2: second line", "the second"),
        (one, "3: third line", "and the third"),
        (two, "2:*third line",
         "after 2D the third line is the second, and is current")]
for text, needle, why in want:
    if needle in text:
        print("ok      %s: %s" % (needle.strip(), why))
    else:
        print("MISSING %s" % needle)
        rc = 1
if "second line" in two.split("2d")[-1]:
    print("WRONG   the deleted line is still listed")
    rc = 1
else:
    print("ok      the deleted line is gone from the listing")

if not os.path.exists(sys.argv[3]):
    print("MISSING TEST.TXT: nothing was written back")
    rc = 1
else:
    after = open(sys.argv[3], "rb").read()
    if after == b"first line\r\nthird line\r\n\x1a":
        print("ok      the file on the disk is the two lines that were left, "
              "ended with the Ctrl-Z a text file gets")
    else:
        print("WRONG   the file holds %r" % after)
        rc = 1
if not os.path.exists(sys.argv[4]):
    print("MISSING TEST.BAK: the old file was not kept")
    rc = 1
else:
    bak = open(sys.argv[4], "rb").read()
    if bak == b"first line\r\nsecond line\r\nthird line\r\n":
        print("ok      TEST.BAK is the file as it was before the edit")
    else:
        print("WRONG   TEST.BAK holds %r" % bak)
        rc = 1
sys.exit(rc)
PY
