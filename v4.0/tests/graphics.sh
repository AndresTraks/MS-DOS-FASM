#!/bin/sh
# Run GRAPHICS.COM on the system this builds, and see that it reads its
# profile and leaves its print-screen handler behind.
#
# GRAPHICS hooks interrupt 5, which is where the ROM BIOS sends the
# print-screen key, and prints the screen through whichever printer it was
# told about: text or graphics, black and white or colour, in whichever of
# the screen modes the machine is in.  What it can print is described by
# GRAPHICS.PRO, a text file it reads at installation and keeps the tables
# of; GRCOMMON's routines, which go into both printer modules, do the work
# of reading a dot and sending a byte.
#
#   GRAPHICS NOSUCH         a printer the profile does not describe
#   GRAPHICS GRAPHICS /B    /B asks for a colour background on a printer
#                           that has no colour
#   GRAPHICS GRAPHICS       installs, and says nothing
#
# Then the machine's memory is read from outside: interrupt 5 must point
# into the segment GRAPHICS was loaded at, and the bytes there must be the
# bytes of the file.
#
# The profile is written to the disk with the line endings DOS reads.  Every
# file in this release arrives with bare newlines -- the whole publication
# was normalised that way -- which costs the assembler nothing but leaves a
# file a program reads at run time unreadable: GRAPHICS answered "Required
# profile statement missing before line 1" and printed pieces of its own
# profile back until the returns went in.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/graphics.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/GRAPHICS.COM ::GRAPHICS.COM

python3 -I -c "
import sys
d = open(sys.argv[1], 'rb').read().replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
open(sys.argv[2], 'wb').write(d)
" src/CMD/GRAPHICS/GRAPHICS.PRO "$OUT/GRAPHICS.PRO"
mcopy -o -i "$IMG" "$OUT/GRAPHICS.PRO" ::GRAPHICS.PRO

{
    printf 'ECHO OFF\r\n'
    printf 'GRAPHICS NOSUCH\r\n'
    printf 'GRAPHICS GRAPHICS /B\r\n'
    printf 'GRAPHICS GRAPHICS\r\n'
    printf 'ECHO THAT IS ALL\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT
# the entries mtools wrote get the tidying create_image.sh gives the rest
python3 dosdir.py "$IMG"

{
    await "THAT IS ALL" 1
    awaitprompt
    snap
    cp "$SHOT" "$OUT/screen.bin"
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
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/mem.bin" ] || { echo "$0: the memory never came back" >&2; exit 1; }

python3 - "$OUT/screen.bin" "$OUT/mem.bin" bin/GRAPHICS.COM <<'PY' || exit 1
import struct
import subprocess
import sys

screen = subprocess.run([sys.executable, "tests/screen.py", sys.argv[1]],
                        capture_output=True, text=True).stdout
mem = open(sys.argv[2], "rb").read()
com = open(sys.argv[3], "rb").read()

print("--- what it said")
for line in screen.split("\n"):
    if line.strip():
        print("   %s" % line.rstrip())

rc = 0
print("--- checks")


def ok(yes, why, missing=None):
    global rc
    if yes:
        print("ok      %s" % why)
    else:
        print("WRONG   %s" % (missing or why))
        rc = 1


ok("Printer type not in GRAPHICS profile" in screen,
   "a printer the profile does not describe is refused, which is the "
   "profile read and its printers looked through")
ok("/B invalid with a black and white printer" in screen,
   "and /B is refused on a printer the profile gives no colour, which is "
   "the command line read against what the profile said")
ok("Required profile statement missing" not in screen
   and "Syntax errors in GRAPHICS profile" not in screen,
   "the profile itself parsed without complaint")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt with the handler resident")

# Interrupt 5 is where the ROM BIOS sends the print-screen key.  GRAPHICS is
# a .COM, so the byte at the start of the file sits at 100H in the segment
# it was loaded at, and an offset in the segment is that much further into
# the file.
off, seg = struct.unpack_from("<HH", mem, 5 * 4)
there = seg * 16 + off
ok(0x100 <= off < 0x100 + len(com),
   "interrupt 5 points into the image GRAPHICS was loaded from",
   "interrupt 5 points at %04X:%04X, and the image is %d bytes from 100H"
   % (seg, off, len(com)))
if 0x100 <= off < 0x100 + len(com):
    # What interrupt 5 points at is a JMP and then the far pointer to the
    # BIOS's own handler, which installation fills in -- so the jump is
    # followed to the handler's own code, which nothing writes over, and
    # that is what is held against the file.
    ok(mem[there] == 0xE9,
       "and what it points at is the jump into the handler",
       "the byte there is %02X and not a JMP" % mem[there])
    target = off + 3 + struct.unpack_from("<h", mem, there + 1)[0]
    at = target - 0x100
    span = 48
    ok(0 <= at and at + span <= len(com),
       "which lands inside the image",
       "the jump goes to %04X, and the image ends at %04X"
       % (target, 0x100 + len(com)))
    if 0 <= at and at + span <= len(com):
        here = seg * 16 + target
        ok(mem[here:here + span] == com[at:at + span],
           "and the %d bytes of the handler there are the bytes of the file"
           % span,
           "the bytes at %04X:%04X are not the file's: %s against %s"
           % (seg, target, mem[here:here + span].hex(),
              com[at:at + span].hex()))
sys.exit(rc)
PY
