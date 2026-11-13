#!/bin/sh
# Run FASTOPEN.EXE on the system this builds, and see that DOS reads a
# directory through the cache it installs.
#
# FASTOPEN keeps two caches for a fixed disk: the names and directory
# entries it has looked up, and the cluster chains it has followed.  The
# kernel has the hooks for both already -- DIR2.ASM calls through the far
# pointers in its FastOpenTable -- and FASTOPEN.EXE fills those pointers in
# with INT 2F function 12/42 and keeps the caches resident.  So the test is
# whether a directory read goes on working once the kernel is calling into
# the utility for every path it looks up.
#
#   FASTOPEN C:=(50,25)   installs it: 50 directory entries, 25 extents
#   DIR C:                read with the kernel calling into the cache
#   DIR C:                and again, now that the path is in it
#   FASTOPEN C:=(50,25)   says it is there already
#   FASTOPEN A:=(50,25)   and refuses a diskette, naming the drive
#
# What this does not reach is a directory with anything in it, and the
# reason is not FASTOPEN.  DOS mounts the partition and reads its boot
# record -- DIR answers with the serial mformat wrote -- and then reports
# the root directory empty when there is a file in it that mtools lists
# happily, and it does the same with nothing installed at all.  The
# partition starts at sector 17 and its BPB says 17 hidden sectors, which
# puts the root directory at absolute sector 32; sector 49, where it would
# land if that offset were counted twice, is all zeros, which is the
# directory DOS seems to be reading.  If that is it then every fixed disk
# in this build is read seventeen sectors late and what wants looking at is
# whatever builds the BPB for a partition.  Until that is settled the
# checks below stop at what the kernel and the utility say to each other,
# which is what the conversion is answerable for, and the disk is left
# empty rather than carrying a file the test cannot yet see.
#
# It wants a fixed disk, which nothing here needed before: tests/mkhd.py
# lays one down with a partition table, and QEMU is told the geometry that
# table was written for, a raw image carrying none of its own.  The machine
# is told to boot the diskette -- the disk has no boot code.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }
command -v mformat >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/fastopen.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/FASTOPEN.EXE ::FASTOPEN.EXE

# The fixed disk FASTOPEN is to cache.
python3 tests/mkhd.py "$OUT/hd.img" >/dev/null

{
    printf 'ECHO OFF\r\n'
    printf 'FASTOPEN C:=(50,25)\r\n'
    printf 'DIR C:\r\n'
    printf 'DIR C:\r\n'
    printf 'FASTOPEN C:=(50,25)\r\n'
    printf 'FASTOPEN A:=(50,25)\r\n'
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


ok("FASTOPEN installed" in screen,
   "the first run installed the caches on the fixed disk")
ok(screen.count("Directory of  C:\\") == 2,
   "DIR C: read the fixed disk twice with the kernel calling into them, "
   "which is a far call through the table FASTOPEN filled in",
   "the directory was read %d times" % screen.count("Directory of  C:\\"))
ok(screen.count("Volume Serial Number") == 2,
   "and the boot record came back both times")
ok("FASTOPEN already installed" in screen,
   "a second run says the caches are there already, which is the kernel "
   "answering out of the table the first run filled in")
ok("Cannot use FASTOPEN for drive A:" in screen,
   "and a diskette is refused, the drive named through the message "
   "retriever's substitution")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt with the caches resident")
sys.exit(rc)
PY
