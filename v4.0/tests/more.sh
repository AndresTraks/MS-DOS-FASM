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
# COMMAND.COM cannot do the redirection yet, so tests/runsh.asm stands in
# for it: it puts TEST.TXT on handle 0 and EXECs MORE.
#
# This fails as it stands, and what is known about it is worth writing down.
# MORE runs and pages when its image is an even number of bytes long and
# hangs when it is odd: 2136 bytes and 2138 pass, 2137 fails, and the only
# difference between the two assemblies is one segment prefix and the byte of
# shift it puts on everything after it.  When it hangs it has printed the
# whole file without stopping, the message it should have stopped at does not
# appear, MAXROW and CURROW are still 25 and 1, and the machine is in the
# kernel's idle loop with keystrokes going nowhere.
#
# Later than that, the memory MORE was loaded into holds something else --
# the PSP is no longer a PSP -- so MORE does end, and whatever hangs happens
# after it: the interpreter's own way back from EXEC is the next place to
# look, and a debugger with a breakpoint on the return from function 4BH
# would settle it faster than another screen capture.
#
# What has been ruled out, each by a program written for the purpose: the
# loader reads the last partial cluster of a 2137-byte .COM (it prints the
# eight bytes at its own end); a read into a buffer at an odd offset lands
# where it was asked to and leaves the bytes below it alone; the same read
# through a duplicated handle behaves the same; and the file's clusters are
# one contiguous run, with the failure following MORE rather than the place
# on the disk.  MORE's own conversion was held against the release line by
# line -- every memory reference, the structure's field offsets and the
# instruction stream all agree.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/more.$$
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
# Which program the stand-in interpreter is to run, and on what.
cat > "$OUT/RUN.INC" <<'INC'
prog	db	"MORE.COM",0
txtfile	db	"TEST.TXT",0
INC
INCLUDE="$OUT" ; export INCLUDE
$FASM tests/runsh.asm "$OUT/RUNSH.COM" >/dev/null
unset INCLUDE
mcopy -o -i msdos.img "$OUT/RUNSH.COM" ::COMMAND.COM
mcopy -o -i msdos.img bin/MORE.COM ::MORE.COM

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
    sleep 24
    echo "pmemsave 0xb8000 4000 \"$OUT/paged.bin\""
    sleep 2
    echo "sendkey spc"
    sleep 4
    echo "pmemsave 0xb8000 4000 \"$OUT/rest.bin\""
    sleep 2
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
        (rest, "line 40 of the file", "a key let the rest of the file through"),
        (rest, "The program returned", "MORE ended and EXEC came back")]
for screen, text, why in want:
    if text in screen:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1
sys.exit(rc)
PY
