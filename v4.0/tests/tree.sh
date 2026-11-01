#!/bin/sh
# Run TREE.COM on the system this builds, and see the shape it draws.
#
# TREE walks the subdirectories from one of them downwards, and it is the
# first of the utilities to do that: it reads a directory with find first and
# find next, and for every subdirectory it finds it calls itself, keeping the
# state of the search it interrupted in a workarea on the stack.  So the kernel
# has to carry on a search that was left part way, which is what the drawing
# proves -- a subdirectory under its parent, and the parent's own list taken
# up again afterwards.
#
# The four characters it draws the shape with are a message of its own, number
# 7 of TREE's class: the tee, the elbow, the dash and the bar, which the
# retriever hands back like any other text.
#
# COMMAND.COM runs it, from an AUTOEXEC.BAT which also asks for the files with
# /F, and the prompt at the end is the interpreter having it back.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }
command -v mmd >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/tree.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

IMG="$OUT/disk.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/TREE.COM ::TREE.COM

# Two subdirectories at the top and one under the first, so that the drawing
# has to hold a level open while it goes down and come back to it.
mmd -i "$IMG" ::SUB1 ::SUB2
mmd -i "$IMG" ::SUB1/DEEP
printf 'a file\r\n' > "$OUT/F1.TXT"
mcopy -o -i "$IMG" "$OUT/F1.TXT" ::SUB1/F1.TXT

printf 'ECHO OFF\r\nTREE\r\nTREE /F\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    sleep 36
    echo "pmemsave 0xb8000 4000 \"$OUT/screen.bin\""
    sleep 2
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

python3 - "$OUT/screen.bin" <<'PY' || exit 1
import sys
d = open(sys.argv[1], "rb").read()
# The characters it draws with are code page 437's, so the screen is read as
# that and shown as the shape it is.
rows = []
for row in range(25):
    raw = bytes(d[(row * 80 + c) * 2] for c in range(80))
    rows.append(raw.decode("cp437").rstrip())
print("--- screen")
for r in rows:
    if r.strip():
        print("   %s" % r)
screen = "\n".join(rows)

TEE, ELBOW, BAR = "├", "└", "│"
rc = 0
print("--- checks")
if "Directory PATH listing" in screen:
    print("ok      the heading came back from the retriever")
else:
    print("MISSING Directory PATH listing")
    rc = 1

named = [n for n, r in enumerate(rows) if r.strip().endswith("SUB1")]
deep = [n for n, r in enumerate(rows) if r.strip().endswith("DEEP")]
two = [n for n, r in enumerate(rows) if r.strip().endswith("SUB2")]
if named and deep and two and named[0] < deep[0] < two[0]:
    print("ok      SUB1, then DEEP under it, then SUB2: the search carried on "
          "where it was left")
else:
    print("WRONG   the order is SUB1 %s, DEEP %s, SUB2 %s" % (named, deep, two))
    rc = 1

if deep and rows[deep[0]].lstrip().startswith(BAR):
    print("ok      DEEP is drawn inside SUB1, the level above held open with "
          "the bar")
elif deep and BAR in rows[deep[0]]:
    print("ok      DEEP is drawn inside SUB1, with the bar of the level above")
else:
    print("WRONG   DEEP's line is %r" % (rows[deep[0]] if deep else None))
    rc = 1

if named and TEE in rows[named[0]]:
    print("ok      SUB1 has the tee: another entry follows it")
else:
    print("MISSING the tee on SUB1's line")
    rc = 1
if two and ELBOW in rows[two[0]]:
    print("ok      SUB2 has the elbow: it is the last of its level")
else:
    print("MISSING the elbow on SUB2's line")
    rc = 1

if "F1.TXT" in screen or "F1" in screen:
    print("ok      /F asked for the files as well, and F1.TXT came back")
else:
    print("MISSING F1.TXT from the /F listing")
    rc = 1

last = [r for r in rows if r.strip()][-1]
if last.startswith("A>"):
    print("ok      the prompt is back: TREE ended and COMMAND.COM has it again")
else:
    print("MISSING the prompt; the last line is %r" % last)
    rc = 1
sys.exit(rc)
PY
