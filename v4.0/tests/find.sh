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
# COMMAND.COM cannot do the redirection yet, so tests/runsh.asm stands in for
# it: it puts the file on handle 0, puts the tail in the PSP and EXECs FIND.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/find.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

./create_image.sh >/dev/null

if command -v fasm >/dev/null 2>&1; then
    FASM=fasm
else
    FASM="wine ../fasmw17332/FASM.EXE"
    WINEDEBUG=${WINEDEBUG:--all}
    export WINEDEBUG
fi

# Which program the stand-in interpreter is to run, on what, and with what
# on the command line.
cat > "$OUT/RUN.INC" <<'INC'
prog	db	"FIND.EXE",0
txtfile	db	"LINES.TXT",0
macro cmdtail {
	db	' /N "line 07"'
}
INC
INCLUDE="$OUT" ; export INCLUDE
$FASM tests/runsh.asm "$OUT/RUNSH.COM" >/dev/null
unset INCLUDE
mcopy -o -i msdos.img "$OUT/RUNSH.COM" ::COMMAND.COM
mcopy -o -i msdos.img bin/FIND.EXE ::FIND.EXE

# Twelve numbered lines, one of which FIND is to come back with.
python3 - "$OUT/LINES.TXT" <<'PY'
import sys
with open(sys.argv[1], "w", newline="\r\n") as f:
    for n in range(1, 13):
        f.write("line %02d of the file FIND is reading\n" % n)
PY
mcopy -o -i msdos.img "$OUT/LINES.TXT" ::LINES.TXT

{
    sleep 26
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
want = [("[7]line 07 of the file FIND is reading",
         "the line that holds the string came back, numbered by /N"),
        ("The program returned", "FIND ended and EXEC came back")]
for text, why in want:
    if text in screen:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1
others = [n for n in range(1, 13)
          if n != 7 and "line %02d of the file FIND" % n in screen]
if others:
    print("WRONG   these lines came back as well: %s" % others)
    rc = 1
else:
    print("ok      no other line came back")
sys.exit(rc)
PY
