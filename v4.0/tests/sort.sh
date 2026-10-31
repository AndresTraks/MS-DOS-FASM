#!/bin/sh
# Run SORT.EXE on the system this builds, and see whether it sorts.
#
# SORT is the first of the utilities to be built as an .EXE -- CODE, CONST
# and CSTACK in one group, which SORTLNK.ASM lays down as one segment -- and
# the first to use the parser in INC/PARSE.ASM and the collating table in
# SORTMES.ASM.  So this gives it four lines in the wrong order, in mixed case,
# and checks that what comes back is in the order the table says: the table
# folds case, so Cherry sorts between banana and pear.
#
# COMMAND.COM runs it, from an AUTOEXEC.BAT that puts the file on its input,
# so the handle SORT reads is one the interpreter redirected for it and the
# prompt at the end is the interpreter having it back.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/sort.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

./create_image.sh >/dev/null
mcopy -o -i msdos.img bin/SORT.EXE ::SORT.EXE

# An AUTOEXEC.BAT, which is also what keeps the interpreter from asking for
# the date and the time.
printf 'ECHO OFF\r\nSORT < WORDS.TXT\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i msdos.img "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

printf 'pear\r\napple\r\nCherry\r\nbanana\r\n' > "$OUT/WORDS.TXT"
mcopy -o -i msdos.img "$OUT/WORDS.TXT" ::WORDS.TXT

{
    sleep 28
    echo "pmemsave 0xb8000 4000 \"$OUT/screen.bin\""
    sleep 2
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file=msdos.img,format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

python3 - "$OUT/screen.bin" <<'PY' || exit 1
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

rc = 0
print("--- checks")
where = {}
for n, r in enumerate(rows):
    for word in ("apple", "banana", "Cherry", "pear"):
        if r.strip() == word:
            where[word] = n
for word in ("apple", "banana", "Cherry", "pear"):
    if word in where:
        print("ok      %s came back on its own line" % word)
    else:
        print("MISSING %s" % word)
        rc = 1
if len(where) == 4:
    order = [where[w] for w in ("apple", "banana", "Cherry", "pear")]
    if order == sorted(order):
        print("ok      the four lines are in the order the collating table "
              "puts them, case folded")
    else:
        print("WRONG   the lines came back in the order %s" % order)
        rc = 1

last = [r for r in rows if r.strip()][-1]
if last.startswith("A>"):
    print("ok      the prompt is back: SORT ended and COMMAND.COM has it again")
else:
    print("MISSING the prompt; the last line is %r" % last)
    rc = 1
sys.exit(rc)
PY
