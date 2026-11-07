#!/bin/sh
# Run GRAFTABL.COM on the system this builds, and see what it leaves behind.
#
# GRAFTABL is the first resident program here.  It loads the 1K table of
# pixels that draws characters 128 to 255 in graphics mode, points interrupt
# 1FH at it -- which is where the ROM looks for them -- and hooks interrupt
# 2FH with a handler that answers "what is loaded?".  Then it moves the
# handler and the table down over its own program prefix, from 60H, and keeps
# just those paragraphs when it ends.
#
# So the test asks three things of it.  That it says what it loaded; that the
# machine lives afterwards, which the VER between the two runs shows; and
# that the second run finds the first, which it can only do by asking the
# resident copy through interrupt 2FH.
#
# Then the machine's memory is read from outside: the two vectors must point
# where GRAFTABL moved the table, and the 1024 bytes there must be the 1024
# bytes of the US table in the file.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/graftabl.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/GRAFTABL.COM ::GRAFTABL.COM

printf 'ECHO OFF\r\nGRAFTABL > PRN\r\nVER > PRN\r\nGRAFTABL /STATUS > PRN\r\n' \
    > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# The whole of the first megabyte, so that the vectors and what they point at
# can be read without asking the machine anything.
{
    awaitprompt
    rm -f "$OUT/mem.bin"
    echo "pmemsave 0 0x100000 \"$OUT/mem.bin\""
    n=0
    while [ "$(if [ -f "$OUT/mem.bin" ]; then wc -c < "$OUT/mem.bin"; else echo 0; fi)" -ne 1048576 ] && [ $n -lt 200 ]; do
        n=$((n + 1))
        sleep 0.05
    done
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/prn.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/prn.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }
[ -s "$OUT/mem.bin" ] || { echo "$0: the memory never came back" >&2; exit 1; }

python3 - "$OUT/prn.txt" "$OUT/mem.bin" bin/GRAFTABL.COM <<'PY' || exit 1
import sys

said = open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
mem = open(sys.argv[2], "rb").read()
com = open(sys.argv[3], "rb").read()

print("--- what it said")
for line in said.split("\n"):
    if line.strip():
        print("   %s" % line.rstrip())

rc = 0
print("--- checks")
want = [("Previous Code Page: None",
         "the first run found nothing of its own already there"),
        ("Active Code Page: 437",
         "and said which table it had loaded"),
        ("MS-DOS Version 4.00",
         "the machine lived through the handler being left resident"),
        ]
for text, why in want:
    if text in said:
        print("ok      %s: %s" % (text.split("\n")[0], why))
    else:
        print("MISSING %s" % text.replace("\n", " / "))
        rc = 1


if said.count("Active Code Page: 437") >= 2:
    print("ok      and the second run found the first, which it can only do "
          "by asking the resident copy through interrupt 2FH")
else:
    print("MISSING the second run's answer")
    rc = 1


def vector(n):
    at = n * 4
    return (mem[at] | (mem[at + 1] << 8),
            mem[at + 2] | (mem[at + 3] << 8))


# GRAFTABL addresses the moved handler through a segment ten paragraphs
# below the prefix, so that the offsets it was assembled with still reach it:
# the table sits at 130H of that segment, which is where it was in the file.
off2f, seg2f = vector(0x2F)
off1f, seg1f = vector(0x1F)
# The handler stands at 100H of that segment, after the jump DOS enters the
# program by and the one byte the multiplex number is kept in.  Its own
# bytes cannot be held against the file's: three places in it are patched as
# it is installed, with where the table went and who owned the vector before.
if 0x100 <= off2f < 0x130 and mem[seg2f * 16 + 0x103] == com[3] == 0xB0:
    print("ok      interrupt 2FH points into the handler, at %03XH, with the "
          "multiplex number GRAFTABL answers to in front of it" % off2f)
else:
    print("WRONG   interrupt 2FH points at %04X:%04X" % (seg2f, off2f))
    rc = 1
if seg1f * 16 + off1f == seg2f * 16 + 0x130:
    print("ok      and interrupt 1FH at the table, 130H past the same place")
else:
    print("WRONG   interrupt 1FH points at %04X:%04X, not %04X:0130"
          % (seg1f, off1f, seg2f))
    rc = 1

# The 1K table itself, against the one in the file.  TABLEUS is at 130H of
# the image, which is 30H into the file -- the file begins at 100H, where
# DOS enters a .COM.
there = seg2f * 16 + 0x130
if mem[there:there + 1024] == com[0x30:0x30 + 1024]:
    print("ok      and the 1024 bytes there are the US table out of the file")
else:
    print("WRONG   the table in memory is not the table in the file")
    print("        memory: %s" % mem[there:there + 16].hex())
    print("        file:   %s" % com[0x30:0x40].hex())
    rc = 1
sys.exit(rc)
PY
