#!/bin/sh
# Run FIND.EXE on the system this builds, and see what it matches.
#
# FIND is the first of the utilities whose segments are laid down without a
# group -- CODE for the program and all its data, STACK for nothing but the
# stack, which FINDLNK.ASM writes in turn -- and the first to be given a
# command line, so this hands it a switch and a quoted string and checks
# that both came through the parser: /N asks for the line number, and only
# the one line that holds the string comes back, with its number in front.
#
# COMMAND.COM runs it, from an AUTOEXEC.BAT that puts the file on its input,
# so the tail FIND parses is the one the interpreter built in its PSP, with
# the redirection taken out of it, and the prompt at the end is the
# interpreter having it back.  It is run a second time with the file named
# instead, which is the other way in: FIND opens it itself, and writes the
# name above what it found.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/find.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

./create_image.sh >/dev/null
mcopy -o -i msdos.img bin/FIND.EXE ::FIND.EXE

# An AUTOEXEC.BAT, which is also what keeps the interpreter from asking for
# the date and the time.
printf 'ECHO OFF\r\nFIND /N "line 07" < LINES.TXT\r\nFIND "line 03" LINES.TXT\r\n' \
    > "$OUT/AUTOEXEC.BAT"
mcopy -o -i msdos.img "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# Twelve numbered lines, one of which FIND is to come back with.
python3 - "$OUT/LINES.TXT" <<'PY'
import sys
with open(sys.argv[1], "w", newline="\r\n") as f:
    for n in range(1, 13):
        f.write("line %02d of the file FIND is reading\n" % n)
PY
mcopy -o -i msdos.img "$OUT/LINES.TXT" ::LINES.TXT

{
    sleep 36
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
screen = "\n".join(rows)

rc = 0
print("--- checks")
if "[7]line 07 of the file FIND is reading" in screen:
    print("ok      the line that holds the string came back, numbered by /N")
else:
    print("MISSING [7]line 07 of the file FIND is reading")
    rc = 1
others = [n for n in range(1, 13)
          if n not in (3, 7) and "line %02d of the file FIND" % n in screen]
if others:
    print("WRONG   these lines came back as well: %s" % others)
    rc = 1
else:
    print("ok      no other line came back")

if "LINES.TXT" in screen and "line 03 of the file FIND is reading" in screen:
    print("ok      FIND opened the file it was named, and wrote the name "
          "above the line it matched")
else:
    print("MISSING the named file's own run")
    rc = 1

last = [r for r in rows if r.strip()][-1]
if last.startswith("A>"):
    print("ok      the prompt is back: FIND ended and COMMAND.COM has it again")
else:
    print("MISSING the prompt; the last line is %r" % last)
    rc = 1
sys.exit(rc)
PY
