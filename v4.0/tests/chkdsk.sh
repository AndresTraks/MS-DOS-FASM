#!/bin/sh
# Run CHKDSK.COM on the system this builds, over a good disk and a broken one.
#
# CHKDSK reads the FAT into memory, walks the directory tree, follows every
# file's chain of clusters through it and marks each one off; what is left
# marked in the FAT and owned by nothing is a lost chain.  The report at the
# end is arithmetic over what it found, so the numbers check each other:
# the bytes in files plus the bytes free come to the size of the disk.
#
# The first machine is given a disk with nothing wrong with it and runs
# CHKDSK /V, which names every file as it goes -- that is the directory walk
# saying out loud where it has been.
#
# The second is given the same disk with one free cluster marked as the end
# of a chain in both copies of the FAT, which is a lost cluster and nothing
# else, and runs CHKDSK /F.  Answering Y writes the chain out as FILE0000.CHK
# and frees nothing; the file is there to be read from outside afterwards,
# the two FATs still agree, and the report's arithmetic has moved by exactly
# the one cluster.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/chkdsk.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/CHKDSK.COM ::CHKDSK.COM
printf 'a file to count\r\n' > "$OUT/HELLO.TXT"
mcopy -o -i "$IMG" "$OUT/HELLO.TXT" ::HELLO.TXT
printf 'ECHO OFF\r\nCHKDSK /V > PRN\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    awaitprompt
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/good.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

# The same disk with one lost cluster on it.  A 1440K diskette keeps the
# boot sector first and two FATs of nine sectors each after it; the entry
# for a cluster is twelve bits, so two of them share a byte.
cp "$IMG" "$OUT/lost.img"
python3 - "$OUT/lost.img" <<'PY'
import sys

d = bytearray(open(sys.argv[1], "rb").read())
FAT1, FAT2 = 512, 512 + 9 * 512


def get(fat, c):
    off = fat + c * 3 // 2
    v = d[off] | (d[off + 1] << 8)
    return (v >> 4) if c & 1 else (v & 0xFFF)


def put(fat, c, val):
    off = fat + c * 3 // 2
    v = d[off] | (d[off + 1] << 8)
    v = ((val << 4) | (v & 0x000F)) if c & 1 else ((v & 0xF000) | val)
    d[off], d[off + 1] = v & 0xFF, v >> 8


lost = next(c for c in range(2, 400) if get(FAT1, c) == 0)
for fat in (FAT1, FAT2):
    put(fat, lost, 0xFFF)
open(sys.argv[1], "wb").write(d)
PY
printf 'ECHO OFF\r\nCHKDSK /F > PRN\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$OUT/lost.img" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    awaitprint "$OUT/fixed.txt" "Convert lost chains to files (Y/N)?"
    echo "sendkey y"
    sleep 0.1
    echo "sendkey ret"
    awaitprompt
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$OUT/lost.img",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/fixed.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/good.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }
mdir -i "$OUT/lost.img" :: > "$OUT/dir.txt" 2>/dev/null || true

python3 - "$OUT/good.txt" "$OUT/fixed.txt" "$OUT/dir.txt" "$OUT/lost.img" \
<<'PY' || exit 1
import re
import sys

good = open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
fixed = open(sys.argv[2], "rb").read().decode("cp437").replace("\r", "")
listing = open(sys.argv[3]).read()
image = open(sys.argv[4], "rb").read()

for name, said in (("the good disk", good), ("the broken disk", fixed)):
    print("--- what it said about %s" % name)
    for line in said.split("\n"):
        if line.strip():
            print("   %s" % line)

rc = 0
print("--- checks")


def want(said, needle, why, where):
    global rc
    if needle in said:
        print("ok      %s: %s" % (needle, why))
    else:
        print("MISSING %s from %s" % (needle, where))
        rc = 1


want(good, "Volume Serial Number is", "it read the boot record", "the report")
want(good, "Directory A:\\", "/V named the directory it was walking",
     "the report")
for name in ("IO.SYS", "MSDOS.SYS", "COMMAND.COM", "CHKDSK.COM", "HELLO.TXT",
             "AUTOEXEC.BAT"):
    want(good, "A:\\" + name, "the walk reached it", "the listing")
want(good, "bytes in each allocation unit", "and it read the BPB",
     "the report")


def numbers(said):
    """The report's figures, by the words that follow them."""
    out = {}
    for line in said.split("\n"):
        m = re.match(r"\s*(\d+)\s+(.*?)\s*$", line)
        if m:
            out[re.sub(r"\d+", "#", m.group(2))] = int(m.group(1))
    return out


n = numbers(good)
total = n.get("bytes total disk space")
inuse = n.get("bytes in # user files")
free = n.get("bytes available on disk")
unit = n.get("bytes in each allocation unit")
units = n.get("total allocation units on disk")
spare = n.get("available allocation units on disk")
if None in (total, inuse, free, unit, units, spare):
    print("MISSING one of the report's figures: %s" % sorted(n))
    rc = 1
elif total != inuse + free:
    print("WRONG   %d bytes in files and %d free do not come to %d"
          % (inuse, free, total))
    rc = 1
elif units * unit != total or spare * unit != free:
    print("WRONG   the allocation units do not match the bytes")
    rc = 1
else:
    print("ok      the figures add up: %d in files and %d free make %d, "
          "in units of %d" % (inuse, free, total, unit))

want(fixed, "Convert lost chains to files (Y/N)?",
     "the lost cluster was found and it asked what to do", "the second run")
want(fixed, "512 bytes in 1 recovered files",
     "answering Y wrote the chain out as a file", "the second run")
want(listing, "FILE0000 CHK",
     "which is on the disk and readable from outside", "the directory")
if "FILE0000 CHK       512" in listing:
    print("ok      and it is the one cluster, 512 bytes")
else:
    print("WRONG   FILE0000.CHK is not 512 bytes")
    rc = 1

# The two FATs are nine sectors each, and CHKDSK writes both.
if image[512:512 + 9 * 512] == image[512 + 9 * 512:512 + 18 * 512]:
    print("ok      the two copies of the FAT still agree")
else:
    print("WRONG   CHKDSK left the two FATs saying different things")
    rc = 1

m = numbers(fixed)
if m.get("bytes in # recovered files") == 512 and \
        m.get("bytes total disk space") == total and \
        m.get("bytes available on disk") == free - 512:
    print("ok      and the report moved by exactly the one cluster")
else:
    print("WRONG   the second report does not account for the cluster")
    rc = 1
sys.exit(rc)
PY
