#!/bin/sh
# Run a pipeline on the system this builds, and see what comes out of it.
#
# A pipe in MS-DOS is two temporary files in the root of the default drive:
# TPIPE.ASM makes them, points the next element's input at the one the last
# element wrote, and hands the element back to COMMAND.COM to run as if it
# had been typed on its own.  So a pipeline is the interpreter running itself
# once per element, and what this checks is the whole of that -- the elements
# in order, the output of each reaching the next, and the two files gone
# again at the end, which is PIPEDEL unlinking them.
#
# AUTOEXEC.BAT is what runs it, and also what keeps the interpreter from
# asking for the date and the time.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/pipe.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

./create_image.sh >/dev/null
mcopy -o -i msdos.img bin/SORT.EXE ::SORT.EXE
mcopy -o -i msdos.img bin/FIND.EXE ::FIND.EXE

# One pipeline of two elements and one of three, so that the second element
# is both the end of a pipe and the middle of one.
printf 'ECHO OFF\r\nTYPE WORDS.TXT | SORT\r\nTYPE WORDS.TXT | FIND "an" | SORT\r\n' \
    > "$OUT/AUTOEXEC.BAT"
mcopy -o -i msdos.img "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

printf 'pear\r\napple\r\nmango\r\nCherry\r\nbanana\r\n' > "$OUT/WORDS.TXT"
mcopy -o -i msdos.img "$OUT/WORDS.TXT" ::WORDS.TXT

{
    sleep 44
    echo "pmemsave 0xb8000 4000 \"$OUT/screen.bin\""
    sleep 2
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file=msdos.img,format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

# What is left on the disk: the pipe files were made here and must be gone.
mdir -b -i msdos.img :: > "$OUT/dir.txt" 2>/dev/null || true

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

rc = 0
print("--- checks")
words = [r.strip() for r in rows]


def block(want, after=0):
    """Where the lines in WANT stand one under the next, at or after AFTER."""
    for i in range(after, len(words) - len(want) + 1):
        if words[i:i + len(want)] == want:
            return i
    return -1


sorted_all = ["apple", "banana", "Cherry", "mango", "pear"]
first = block(sorted_all)
if first >= 0:
    print("ok      TYPE | SORT: the five lines came out in the order the "
          "collating table puts them")
else:
    print("MISSING TYPE | SORT: %s one under the next" % sorted_all)
    rc = 1

second = block(["banana", "mango"], first + 5 if first >= 0 else 0)
if second >= 0:
    print("ok      TYPE | FIND | SORT: the two lines holding \"an\" came "
          "through FIND and out of SORT in order")
else:
    print("MISSING TYPE | FIND | SORT: banana and mango one under the next")
    rc = 1

last = [r for r in rows if r.strip()][-1]
if last.startswith("A>"):
    print("ok      the prompt is back: the pipeline ended and COMMAND.COM "
          "has it again")
else:
    print("MISSING the prompt; the last line is %r" % last)
    rc = 1

expect = {"IO.SYS", "MSDOS.SYS", "COMMAND.COM", "SORT.EXE", "FIND.EXE",
          "WORDS.TXT", "AUTOEXEC.BAT"}
left = set(line.strip().rsplit("/", 1)[-1] for line in open(sys.argv[2])
           if line.strip())
if left == expect:
    print("ok      the two pipe files are gone: PIPEDEL unlinked them")
else:
    print("WRONG   the disk holds %s, not %s"
          % (sorted(left), sorted(expect)))
    rc = 1
sys.exit(rc)
PY
