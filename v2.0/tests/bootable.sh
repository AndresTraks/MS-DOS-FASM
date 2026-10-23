#!/bin/sh
# Make a bootable disk on this system, and boot a machine from it.
#
# Three steps, which between them need everything this repository builds:
# FORMAT lays down the boot sector, the FATs and the directory, SYS transfers
# IO.SYS and MSDOS.SYS, and COPY puts COMMAND.COM beside them.  Then a machine
# with that disk as its only floppy is booted from it.
#
# The boot sector is the new part.  Microsoft's generic OEM module wrote none
# -- FORMAT.txt leaves the bootstrap to the OEM's DISKFORMAT, and the generic
# one has no machine to write it for -- so until now nothing on this system
# ever wrote sector 0, and a disk made here could only be read by it, never
# started from.  GENFOR.ASM now writes the image bootsect.asm builds, the same
# one create_image.sh puts on the system disk.
#
# FORMAT /S does all three steps itself, and tests/formats.sh is that: two
# faults in FORMAT.ASM used to stop it, and they are fixed.  This stays as the
# long way round, which is the only thing that exercises SYS.
#
# The format run is slow, the bad sector scan reading every allocation unit on
# the disk, so this is not in run-all.sh.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/bootable.$$
BIMG=$OUT/blank.img
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

dd if=/dev/zero of="$BIMG" bs=512 count=2880 status=none

fail=0
printf '\n======== FORMAT, SYS and COPY onto a blank disk in B\n'
if ./runtest.sh -t 260 -K 16 -k "ret" -b "$BIMG" \
                -e "bytes total disk space" \
                -e "System transferred" \
                -e "DONE" tests/bootable.bat
then :; else fail=1; fi

printf '\n======== what landed on it\n'
# Read the disk here rather than with mtools, which refuses it: FORMAT.ASM
# forces the FAT ID up with OR AL,0F8H, F8 to FF being the only media bytes
# there were in 1983, so a disk it makes says F8 in the FAT while the BPB in
# the boot sector says F0, the byte a 1440K diskette got three years later.
# DOS takes its geometry from the driver and never looks; mtools compares the
# two and gives up.
python3 - "$BIMG" bin/bootsect.bin <<'PY' || fail=1
import sys
img, boot = (open(p, "rb").read() for p in sys.argv[1:3])
ok = True
def check(good, what):
    global ok
    print("%s %s" % ("ok     " if good else "MISSING", what))
    ok = ok and good

check(img[:512] == boot, "sector 0 is the boot sector bootsect.asm builds")
check(img[510:512] == b"\x55\xaa", "it ends in the boot signature")
check(img[512] == 0xF8 and img[513:515] == b"\xff\xff",
      "the FAT starts with the ID FORMAT wrote, F8 FF FF")
want = [b"IO      SYS", b"MSDOS   SYS", b"COMMAND COM"]
for n, name in enumerate(want):
    e = img[19 * 512 + n * 32:19 * 512 + (n + 1) * 32]
    clus, size = int.from_bytes(e[26:28], "little"), int.from_bytes(e[28:32], "little")
    check(e[:11] == name, "directory entry %d is %s, %d bytes from cluster %d"
          % (n, name.decode().strip(), size, clus))
sys.exit(0 if ok else 1)
PY

printf '\n======== booting the disk it made\n'
SCR=$OUT/screen.bin
{ sleep 30; echo "pmemsave 0xb8000 4000 \"$SCR\""; sleep 2; echo quit; } |
    timeout 90 qemu-system-i386 -rtc base=localtime \
        -drive file="$BIMG",format=raw,if=floppy,index=0 \
        -display none -monitor stdio > /dev/null 2>&1 || true
python3 -c "
import sys
d = open(sys.argv[1], 'rb').read()
rows = [''.join(chr(d[(r*80+c)*2]) if 32 <= d[(r*80+c)*2] < 127 else '.'
                for c in range(80)).rstrip() for r in range(25)]
print('\n'.join(r for r in rows if r))
" "$SCR"
if python3 -c "
import sys
d = open(sys.argv[1], 'rb').read()
screen = ''.join(chr(d[i]) if 32 <= d[i] < 127 else ' ' for i in range(0, 4000, 2))
sys.exit(0 if 'Command v. 2.11' in screen else 1)
" "$SCR"
then echo "ok      the disk this system made boots"
else echo "MISSING the disk did not boot to a command prompt"; fail=1
fi

exit $fail
