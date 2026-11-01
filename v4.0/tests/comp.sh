#!/bin/sh
# Run COMP.COM on the system this builds, and see what it makes of two files.
#
# COMP is the first of the utilities to read two files at once: it opens both,
# fills a large buffer from one and a small one from the other, and walks the
# pair reporting where they differ.  So this gives it two files that are the
# same and two that differ in a single byte, and checks that it says so and
# says where -- the offset and the two bytes it found there.
#
# It asks whether to compare more files when it has finished, so the answer
# is typed in; the prompt at the end is COMMAND.COM having it back.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/comp.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

./create_image.sh >/dev/null
mcopy -o -i msdos.img bin/COMP.COM ::COMP.COM

# A.TXT and B.TXT are the same; C.TXT has one letter of A.TXT in the other
# case, at offset 11h -- "n" is 6Eh and "N" is 4Eh.
printf 'hello world\r\nsecond line\r\n' > "$OUT/A.TXT"
printf 'hello world\r\nsecond line\r\n' > "$OUT/B.TXT"
printf 'hello world\r\nsecoNd line\r\n' > "$OUT/C.TXT"
for f in A.TXT B.TXT C.TXT; do
    mcopy -o -i msdos.img "$OUT/$f" "::$f"
done

printf 'ECHO OFF\r\nCOMP A.TXT B.TXT\r\nCOMP A.TXT C.TXT\r\nECHO done\r\n' \
    > "$OUT/AUTOEXEC.BAT"
mcopy -o -i msdos.img "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# "Compare more files (Y/N) ?" is answered no, twice.
{
    sleep 34
    for k in n ret; do echo "sendkey $k"; sleep 1; done
    sleep 8
    for k in n ret; do echo "sendkey $k"; sleep 1; done
    sleep 6
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
    raw = bytes(d[(row * 80 + c) * 2] for c in range(80))
    rows.append(raw.decode("cp437").rstrip())
print("--- screen")
for r in rows:
    if r.strip():
        print("   %s" % r)
screen = "\n".join(rows)

rc = 0
print("--- checks")
want = [("A:A.TXT and A:B.TXT",
         "COMP named the pair it was given, both opened"),
        ("Files compare OK", "the two that are the same came back equal"),
        ("A:A.TXT and A:C.TXT", "and the second pair as well"),
        ("Compare error at OFFSET 11",
         "the one byte that differs was found, at its offset"),
        ("File 1 = 6E", "and the byte from the first file reported"),
        ("File 2 = 4E", "and the byte from the second"),
        ("Compare more files (Y/N) ?",
         "it asked whether to go on, which is the retriever's text with "
         "input on the end of it")]
for text, why in want:
    if text in screen:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1

last = [r for r in rows if r.strip()][-1]
if last.startswith("A>"):
    print("ok      the prompt is back: COMP ended and COMMAND.COM has it again")
else:
    print("MISSING the prompt; the last line is %r" % last)
    rc = 1
sys.exit(rc)
PY
