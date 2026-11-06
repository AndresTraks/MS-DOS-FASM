#!/bin/sh
# Run SYS.COM on the system this builds, and start a machine from what it made.
#
# SYS puts a system on a diskette that has none: it writes a boot record, and
# it copies IO.SYS and MSDOS.SYS into the first two entries of the root
# directory, where the boot record looks for them by name.  Both halves have
# to be right for anything to come of it, and neither shows in what it prints
# -- "System transferred" is all it says.
#
# So the proof is the second machine.  The first one runs SYS A: to B: and
# copies COMMAND.COM over after it, which is what the manual tells a user to
# do; the second is started from that diskette and nothing else, and what it
# prints is the whole chain: the boot record SYS wrote read MSLOAD, MSLOAD
# walked the FAT to the rest of IO.SYS, and the kernel came up far enough to
# run a batch file.
#
# The boot record is checked as well.  SYS keeps the BPB the diskette already
# has -- the table from offset 0Bh to the end of the extended fields, which
# describes this medium and not the one the canned record was built for -- and
# writes its own code around it.  Both of those are looked at here, against
# the sector mformat left.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }
command -v mformat >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/sys.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/SYS.COM ::SYS.COM
printf 'ECHO OFF\r\nSYS B:\r\nCOPY COMMAND.COM B:\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# The target: a diskette with a file system on it and nothing in it.  mformat
# writes a boot sector of its own, which is the one SYS has to replace.
mformat -C -f 1440 -i "$OUT/b.img" ::
dd if="$OUT/b.img" of="$OUT/before.bin" bs=512 count=1 status=none

# SYS says what it did on the screen, which comes back from the adapter's
# text buffer the way the boot test reads it.
{
    awaitprompt
    cp "$SHOT" "$OUT/screen.bin"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -drive file="$OUT/b.img",format=raw,if=floppy,index=1 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }
dd if="$OUT/b.img" of="$OUT/after.bin" bs=512 count=1 status=none
mdir -a -i "$OUT/b.img" :: > "$OUT/dir.txt" 2>/dev/null || true

# The diskette SYS made, started on its own.  A batch file on it keeps the
# machine from stopping at the date and the time, and sends the proof to the
# printer, which QEMU writes to a file.
printf 'ECHO OFF\r\nVER > PRN\r\nDIR > PRN\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$OUT/b.img" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    awaitprompt
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$OUT/b.img",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/prn.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

python3 - "$OUT/screen.bin" "$OUT/dir.txt" "$OUT/before.bin" "$OUT/after.bin" \
         "$OUT/b.img" "$OUT/prn.txt" <<'PY' || exit 1
import sys

d = open(sys.argv[1], "rb").read()
rows = []
for row in range(25):
    cell = lambda c: d[(row * 80 + c) * 2]
    rows.append("".join(chr(cell(c)) if 32 <= cell(c) < 127 else " "
                        for c in range(80)).rstrip())
screen = "\n".join(rows)
listing = open(sys.argv[2]).read()
before = open(sys.argv[3], "rb").read()
after = open(sys.argv[4], "rb").read()
image = open(sys.argv[5], "rb").read()
said = open(sys.argv[6], "rb").read().decode("cp437").replace("\r", "")

print("--- what the first machine showed")
for r in rows:
    if r.strip():
        print("   %s" % r)
print("--- what the second machine printed")
for line in said.split("\n"):
    if line.strip():
        print("   %s" % line)

rc = 0
print("--- checks")
if "System transferred" in screen:
    print("ok      System transferred: SYS wrote the record and both files")
else:
    print("MISSING System transferred")
    rc = 1

for name, why in (("IO       SYS", "the BIOS went over"),
                  ("MSDOS    SYS", "and the kernel with it"),
                  ("COMMAND  COM", "and COPY put the interpreter there after")):
    if name in listing:
        print("ok      %s is on the diskette: %s" % (name, why))
    else:
        print("MISSING %s from the diskette" % name)
        rc = 1

# The root directory of a 1440K diskette starts at sector 19.  The boot
# record reads the first two entries and expects the two system files there,
# in that order.
root = image[19 * 512:]
first = [root[n * 32:n * 32 + 11].decode("cp437") for n in range(2)]
if first == ["IO      SYS", "MSDOS   SYS"]:
    print("ok      they are the first two entries of the root directory, "
          "which is where the boot record looks")
else:
    print("WRONG   the root directory begins %s" % first)
    rc = 1

# 0Bh to 3Eh is the BPB, the physical drive and the extended fields: the
# table that describes this diskette, which SYS keeps.
if after[0x0B:0x3E] == before[0x0B:0x3E]:
    print("ok      the BPB of the diskette came through the new boot record "
          "unchanged")
else:
    print("WRONG   the BPB changed under SYS")
    rc = 1
if after[:0x0B] != before[:0x0B] and after[0x3E:] != before[0x3E:]:
    print("ok      and the code around it is SYS's own and not mformat's")
else:
    print("WRONG   the boot record is still the one mformat wrote")
    rc = 1

for text, why in (("MS-DOS Version 4.00",
                   "the diskette SYS made started a machine of its own"),
                  ("COMMAND  COM",
                   "and the interpreter it loaded is a file on that diskette"),
                  ("AUTOEXEC BAT", "and the batch file it ran is there too"),
                  ("File(s)", "and the listing ran to its end")):
    if text in said:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s from what the second machine printed" % text)
        rc = 1
sys.exit(rc)
PY
