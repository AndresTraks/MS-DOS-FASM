#!/bin/sh
# Load SMARTDRV.SYS from CONFIG.SYS on the system this builds, and read a
# fixed disk through it.
#
# SMARTDRV is the disk cache, and it is the one driver here that sits under
# the system rather than beside it: it hooks INT 13H below the BIOS, so the
# kernel's own reads go through the cache without knowing it is there.  What
# it caches is a fixed disk only -- asked to work with nothing but a floppy
# it says "No hard drives on system" and takes itself out again -- so this
# test lays a fixed disk down with tests/mkhd.py, as the FASTOPEN test does,
# and gives the machine both.
#
#   DEVICE=\SMARTDRV.SYS 128     128K of cache, in low memory
#   DIR C:, TYPE, DIR C:         the second read of a sector comes from it
#
# There is nothing on the screen to say a read came out of the cache rather
# than off the disk -- that is the point of a cache -- so what this asserts
# is that the driver installed, said what it took, and that the file calls
# that go through it all answer.  FLUSH13.EXE, which would empty the cache
# and say so, is the C program beside the driver and is not built here.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/smartdrv.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/SMARTDRV.SYS ::SMARTDRV.SYS

# The fixed disk the cache is to work on, with a file on it to read twice.
HD=$(python3 tests/mkhd.py "$OUT/hd.img")
printf 'the file read through the cache\r\n' > "$OUT/HELLO.TXT"
mcopy -o -i "$HD" "$OUT/HELLO.TXT" ::HELLO.TXT
python3 dosdir.py "$OUT/hd.img" "${HD##*@@}"

printf 'DEVICE=\\SMARTDRV.SYS 128\r\n' > "$OUT/CONFIG.SYS"
mcopy -o -i "$IMG" "$OUT/CONFIG.SYS" ::CONFIG.SYS

{
    printf 'ECHO OFF\r\n'
    printf 'DIR C:\r\n'
    printf 'TYPE C:\\HELLO.TXT\r\n'
    printf 'TYPE C:\\HELLO.TXT\r\n'
    printf 'DIR C:\r\n'
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
    echo quit
} | "$QEMU" -rtc base=localtime -boot order=a \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -drive id=hd,file="$OUT/hd.img",format=raw,if=none \
            -device ide-hd,drive=hd,cyls=61,heads=4,secs=17 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

python3 - "$OUT/screen.bin" <<'PY' || exit 1
import subprocess
import sys

screen = subprocess.run([sys.executable, "tests/screen.py", sys.argv[1]],
                        capture_output=True, text=True).stdout

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


ok("SMARTDrive Disk Cache" in screen,
   "the driver installed and said so, which is its own banner and not the "
   "retriever's -- it carries its text in the module, as the drivers did "
   "before the retriever took that over")
ok("No hard drives on system" not in screen,
   "and it found the fixed disk, which is the only kind it will cache")
ok("the file read through the cache" in screen,
   "TYPE read a file off that disk through the cache")
ok(screen.count("the file read through the cache") == 2,
   "and the second read of it answered as well, which is the one the cache "
   "could serve without the disk",
   "the file came back %d times, not twice"
   % screen.count("the file read through the cache"))
ok("HELLO    TXT" in screen,
   "and DIR lists it, the directory having gone through the cache too")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt with the cache resident")
sys.exit(rc)
PY
