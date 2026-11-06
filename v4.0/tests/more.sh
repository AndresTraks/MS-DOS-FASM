#!/bin/sh
# Run MORE.COM on the system this builds, and see what it prints.
#
# MORE is the first of the utilities under src/CMD to be converted, and it
# exercises more than itself: INC/STRUC.INC's structured statements, which
# sixteen of the utilities are written in, and the message retriever in
# INC/MSGSERV.ASM, which every one of them asks for its text.  So what this
# checks is that a utility built with those runs on the kernel built here:
# the file it is given comes out a screen at a time, the -- More -- it stops
# at is a message the retriever looked up by number, and a keystroke lets the
# rest through.
#
# COMMAND.COM runs it, from an AUTOEXEC.BAT that puts the file on its input,
# so the handle MORE reads is one the interpreter redirected for it and the
# prompt at the end is the interpreter having it back.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/more.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

./create_image.sh >/dev/null
mcopy -o -i msdos.img bin/MORE.COM ::MORE.COM

# An AUTOEXEC.BAT, which is also what keeps the interpreter from asking for
# the date and the time.
printf 'ECHO OFF\r\nMORE < TEST.TXT\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i msdos.img "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# Forty numbered lines, so that MORE has to stop part way.
python3 - "$OUT/TEST.TXT" <<'PY'
import sys
with open(sys.argv[1], "w", newline="\r\n") as f:
    for n in range(1, 41):
        f.write("line %02d of the file MORE is paging\n" % n)
PY
mcopy -o -i msdos.img "$OUT/TEST.TXT" ::TEST.TXT

# The screen is read twice: once where MORE has stopped, and once after a key
# has let the rest of the file through.
{
    await "-- More --"
    cp "$SHOT" "$OUT/paged.bin"
    echo "sendkey spc"
    awaitprompt
    cp "$SHOT" "$OUT/rest.bin"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file=msdos.img,format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/paged.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

python3 - "$OUT/paged.bin" "$OUT/rest.bin" <<'PY' || exit 1
import sys


def read(path):
    d = open(path, "rb").read()
    rows = []
    for row in range(25):
        cell = lambda c: d[(row * 80 + c) * 2]
        rows.append("".join(chr(cell(c)) if 32 <= cell(c) < 127 else " "
                            for c in range(80)).rstrip())
    return "\n".join(rows), rows


paged, rows = read(sys.argv[1])
rest, after = read(sys.argv[2])
print("--- the screen where MORE stopped")
for r in rows:
    if r.strip():
        print("   %s" % r)
print("--- and after a key")
for r in after:
    if r.strip():
        print("   %s" % r)

rc = 0
print("--- checks")
want = [(paged, "line 01 of the file", "MORE read the file and wrote it out"),
        (paged, "-- More --",
         "MORE stopped, with the message the retriever found by number"),
        (rest, "line 40 of the file", "a key let the rest of the file through")]
for screen, text, why in want:
    if text in screen:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1

last = [r for r in after if r.strip()][-1]
if last.startswith("A>"):
    print("ok      the prompt is back: MORE ended and COMMAND.COM has it again")
else:
    print("MISSING the prompt; the last line is %r" % last)
    rc = 1
sys.exit(rc)
PY
