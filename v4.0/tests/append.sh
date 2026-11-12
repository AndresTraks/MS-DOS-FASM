#!/bin/sh
# Run APPEND.EXE on the system this builds, and see that DOS finds a file
# through it.
#
# APPEND keeps a list of directories for DOS to look in after the working
# one, so that a program asking to open a file it cannot find is given the
# one in an appended directory instead.  It does that by hooking interrupt
# 21H in front of DOS and watching the calls that name a file, and interrupt
# 2FH so that a second copy can find the first; the whole of it up to
# end_address stays resident.
#
# So the test puts a file in a subdirectory, stays in the root, and asks
# COMMAND.COM to TYPE it -- which can only work through APPEND -- and then
# takes the directory away again and asks for the same file, which must now
# fail.  Between the two it asks APPEND what it is holding.
#
#   APPEND            the first run, which installs it and says nothing
#   APPEND \SUB       the directory to look in
#   APPEND            says what it is holding: APPEND=\SUB
#   TYPE HELLO.TXT    from the root, found in \SUB through APPEND
#   APPEND ;          gives up the list
#   APPEND            says No Append
#   TYPE HELLO.TXT    is not found any more
#
# Then the machine's memory is read from outside: interrupts 21H and 2FH
# must both point into the one segment APPEND was loaded at, and the bytes
# at the 21H handler must be the bytes of the file.
#
# APPEND writes on standard error, which a batch file cannot redirect, so
# what it says is read off the screen and the marker off the printer.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }
command -v mmd >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/append.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/APPEND.EXE ::APPEND.EXE

# The file APPEND is to find, in a directory the machine is never in.
mmd -i "$IMG" ::SUB
printf 'hello from the subdirectory\r\n' > "$OUT/HELLO.TXT"
mcopy -o -i "$IMG" "$OUT/HELLO.TXT" ::SUB/HELLO.TXT

{
    printf 'ECHO OFF\r\n'
    printf 'APPEND\r\n'
    printf 'APPEND \\SUB\r\n'
    printf 'APPEND\r\n'
    printf 'TYPE HELLO.TXT\r\n'
    printf 'APPEND ;\r\n'
    printf 'APPEND\r\n'
    printf 'TYPE HELLO.TXT\r\n'
    printf 'VER > PRN\r\n'
    printf 'ECHO THAT IS ALL > PRN\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT
# the entries mtools wrote get the tidying create_image.sh gives the rest
python3 dosdir.py "$IMG"

{
    awaitprint "$OUT/prn.txt" "THAT IS ALL"
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
            -parallel "file:$OUT/prn.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/prn.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }
[ -s "$OUT/mem.bin" ] || { echo "$0: the memory never came back" >&2; exit 1; }

python3 - "$OUT/prn.txt" "$OUT/screen.bin" "$OUT/mem.bin" bin/APPEND.EXE <<'PY' || exit 1
import struct
import subprocess
import sys

said = open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
screen = subprocess.run([sys.executable, "tests/screen.py", sys.argv[2]],
                        capture_output=True, text=True).stdout
mem = open(sys.argv[3], "rb").read()
exe = open(sys.argv[4], "rb").read()

print("--- what it said")
for line in (screen + said).split("\n"):
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


ok("APPEND=\\SUB" in screen,
   "APPEND with nothing after it says which directory it is holding, which "
   "the run before it gave")
ok("hello from the subdirectory" in screen,
   "and TYPE from the root read a file that is only in \\SUB, which it can "
   "do only through APPEND's hook on interrupt 21H")
ok("No Append" in screen,
   "APPEND ; gave the list up, and the run after it says so")
ok("File not found - HELLO.TXT" in screen,
   "and the same TYPE no longer finds the file")
ok(screen.count("hello from the subdirectory") == 1,
   "which it found once and once only",
   "the file was read %d times"
   % screen.count("hello from the subdirectory"))
ok("MS-DOS Version 4.00" in said,
   "and the machine lived through the hooks being left resident")


def vector(n):
    off, seg = struct.unpack_from("<HH", mem, n * 4)
    return seg, off


seg21, off21 = vector(0x21)
seg2f, off2f = vector(0x2F)
ok(seg21 == seg2f,
   "interrupts 21H and 2FH both point into the one segment APPEND was "
   "loaded at",
   "interrupt 21H points at %04X:%04X and 2FH at %04X:%04X"
   % (seg21, off21, seg2f, off2f))

# The handler's own bytes, against the file's.  The words the loader fixed
# up are left out and read as the segment they should have become.
hdr = struct.unpack_from("<H", exe, 8)[0] * 16
nrel = struct.unpack_from("<H", exe, 6)[0]
relo = struct.unpack_from("<H", exe, 24)[0]
fixed = []
for i in range(nrel):
    roff, rseg = struct.unpack_from("<HH", exe, relo + 4 * i)
    where = rseg * 16 + roff
    if off21 <= where < off21 + 64:
        fixed.append(where)
there = seg21 * 16 + off21
window = [i for i in range(off21, off21 + 64)
          if i not in fixed and i - 1 not in fixed]
ok(all(mem[there + i - off21] == exe[hdr + i] for i in window),
   "and the 64 bytes of the interrupt 21H handler are the bytes of the "
   "file, but for the %d word the loader fixed up" % len(fixed),
   "the bytes at %04X:%04X are not the file's: %s against %s"
   % (seg21, off21, mem[there:there + 16].hex(),
      exe[hdr + off21:hdr + off21 + 16].hex()))
sys.exit(rc)
PY
