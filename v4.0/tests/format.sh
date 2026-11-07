#!/bin/sh
# Run FORMAT.COM on the system this builds, over a blank diskette in B:.
#
# FORMAT is the utility this whole disk image has been standing in for:
# create_image.sh lays the boot sector down with mformat and python because
# FORMAT was not converted.  What it does here is the real thing -- it asks
# the driver for the medium's parameters, formats every track through the
# generic IOCTL, writes the two FATs and the root directory, writes the boot
# sector, and asks the driver to keep the volume label and the serial number
# it made from the clock.
#
# The boot sector it writes is the release's own: INC/BOOT.INC is what MASM
# made of MSBOOT.ASM, as DB statements, and FORMAT includes that and fills in
# the BPB from the medium.  So what lands on the disk can be held against
# those DB statements, and the only bytes that may differ are the ones FORMAT
# is there to fill in -- the BPB, from the sector size at 0Bh to the end of
# the extended BPB at 3Dh.
#
# The prompts and the count of percent complete go through the message
# retriever, three classes of its own where every utility converted before
# this had one; the volume label is typed in at the question FORMAT asks.
#
# What it made is read back from outside afterwards, so the test sees the
# disk and not only what FORMAT said about it.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }
command -v mdir >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/format.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/FORMAT.COM ::FORMAT.COM

# The target: a diskette with nothing on it at all, not even a format.
dd if=/dev/zero of="$OUT/b.img" bs=512 count=2880 status=none

printf 'ECHO OFF\r\nFORMAT B: > PRN\r\nDIR B: > PRN\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    awaitprint "$OUT/prn.txt" "press ENTER when ready"
    echo "sendkey ret"
    awaitprint "$OUT/prn.txt" "Volume label (11 characters, ENTER for none)?"
    for k in t e s t d i s k; do echo "sendkey $k"; sleep 0.1; done
    echo "sendkey ret"
    awaitprint "$OUT/prn.txt" "Format another (Y/N)?"
    echo "sendkey n"
    sleep 0.1
    echo "sendkey ret"
    awaitprompt
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -drive file="$OUT/b.img",format=raw,if=floppy,index=1 \
            -parallel "file:$OUT/prn.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/prn.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }

# The disk as FORMAT left it, read without the machine's help.
mdir -i "$OUT/b.img" :: > "$OUT/dir.txt" 2>/dev/null || true

python3 - "$OUT/prn.txt" "$OUT/b.img" "$OUT/dir.txt" src/INC/BOOT.INC <<'PY' || exit 1
import re
import sys

said = open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
disk = open(sys.argv[2], "rb").read()
listing = open(sys.argv[3]).read()

# INC/BOOT.INC, back from DB statements into the 512 bytes it came from.
theirs = bytearray()
for line in open(sys.argv[4], encoding="cp437"):
    m = re.match(r"(?i)\s*db\s+(.*)", line.split(";")[0])
    if m:
        for byte in m.group(1).split(","):
            byte = byte.strip()
            if byte:
                theirs.append(int(byte.rstrip("Hh"), 16))

print("--- what it said")
for line in said.split("\n"):
    # the hundred and one lines of percent complete are one line of screen
    if line.strip() and not line.endswith("percent of disk formatted"):
        print("   %s" % line.rstrip())

rc = 0
print("--- checks")
want = [("press ENTER when ready",
         "it asked for the diskette, through the retriever"),
        ("  0 percent of disk formatted",
         "and counted the tracks up from nothing as it formatted them"),
        ("100 percent of disk formatted", "to the end of the disk"),
        ("Format complete", "and said so"),
        ("Volume label (11 characters, ENTER for none)?",
         "then asked for a label, which is typed in"),
        ("1457664 bytes total disk space",
         "the size it reports is the whole of a 1440K diskette"),
        ("512 bytes in each allocation unit",
         "with one sector to an allocation unit"),
        ("2847 allocation units available on disk",
         "and the count of them the BPB it wrote implies"),
        ("Volume Serial Number is",
         "and the serial number it made from the clock")]
for text, why in want:
    if text in said:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1

# The boot sector, against the DB statements the release carries.
BPB = range(0x0B, 0x3E)
differ = [i for i in range(512) if disk[i] != theirs[i]]
outside = [i for i in differ if i not in BPB]
if not outside:
    print("ok      the boot sector is the release's own, with %d bytes of BPB "
          "filled in and nothing else touched" % len(differ))
else:
    print("WRONG   %d bytes outside the BPB differ: %s"
          % (len(outside), outside[:12]))
    rc = 1

# And the BPB it filled in, field by field.
fields = [(0x0B, 2, 512, "bytes a sector"),
          (0x0D, 1, 1, "sectors an allocation unit"),
          (0x0E, 2, 1, "reserved sectors"),
          (0x10, 1, 2, "FATs"),
          (0x11, 2, 224, "root directory entries"),
          (0x13, 2, 2880, "sectors"),
          (0x15, 1, 0xF0, "the media descriptor"),
          (0x16, 2, 9, "sectors a FAT"),
          (0x18, 2, 18, "sectors a track"),
          (0x1A, 2, 2, "heads")]
for at, width, value, what in fields:
    got = disk[at] if width == 1 else disk[at] | (disk[at + 1] << 8)
    if got == value:
        print("ok      %s: %d" % (what, got))
    else:
        print("WRONG   %s is %d and not %d" % (what, got, value))
        rc = 1
if disk[0x1FE:0x200] == b"\x55\xAA":
    print("ok      and the signature a boot sector ends with")
else:
    print("MISSING the 55AA signature")
    rc = 1

# The first FAT, which holds the media descriptor and nothing else.
if disk[0x200:0x203] == b"\xF0\xFF\xFF":
    print("ok      the FAT starts with the media descriptor and no chains")
else:
    print("WRONG   the FAT starts %r" % disk[0x200:0x206])
    rc = 1

# What DOS made of the disk, and what mtools makes of it from outside.  The
# directory is empty, and DOS says so on the handle a batch file does not
# redirect, so the proof that it read the disk is the heading and the label.
for text, why in (("Volume in drive B is TESTDISK",
                   "the machine read the label back off the disk it made"),
                  ("Directory of  B:\\",
                   "and read the root directory it wrote")):
    if text in said:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1
if "TESTDISK" in listing:
    print("ok      and the label is there read from outside the machine")
else:
    print("MISSING the label from outside; mtools says %r"
          % listing.split("\n")[:4])
    rc = 1
sys.exit(rc)
PY
