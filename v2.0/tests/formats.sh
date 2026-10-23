#!/bin/sh
# Make a bootable disk with FORMAT /S alone, and boot a machine from it.
#
# tests/bootable.sh does this the long way -- FORMAT, then SYS, then COPY --
# and this does it in the one command FORMAT /S was meant to be: it formats
# the disk, writes the boot sector, and transfers IO.SYS, MSDOS.SYS and
# COMMAND.COM itself.  Two faults in FORMAT.ASM stood in the way, both of
# them on the /S path only, which is why the plain format worked throughout:
#
#   * CLEAR zeroes the FAT image with REP STOSB, through ES.  The ASSUME at
#     the top of FORMAT.ASM says ES belongs to the program and nothing puts
#     it back after READDOS, which /S runs and which ends on
#     LES SI,[COMSIZB] -- leaving the high word of a file size, zero, in ES.
#     So it cleared 4271 bytes at 0000:16E4 instead of CS:16E4, which is the
#     middle of the DOS kernel, and the INT 21H after it never returned.
#   * the SETBLOCK that gives the memory above the program to the system
#     files ran before the OEM module's INIT, which is what moves FREESPACE
#     up past the FAT image and the temp buffer.  So the FAT image landed on
#     the memory control block of the block FORMAT had just allocated, and
#     DOS said "Memory allocation error" and could not load COMMAND again.
#
# The bad sector scan reads every allocation unit on the disk, so the format
# takes about four minutes; that is why this is not in run-all.sh.
#
# The read-back is done here rather than with mtools, which refuses the disk:
# FORMAT forces the FAT ID up with OR AL,0F8H, F8 to FF being the only media
# bytes there were in 1983, so the FAT says F8 while the BPB in the boot
# sector says F0, the byte a 1440K diskette got three years later.  DOS takes
# its geometry from the driver and never looks; mtools compares the two and
# gives up.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/formats.$$
BIMG=$OUT/blank.img
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

dd if=/dev/zero of="$BIMG" bs=512 count=2880 status=none

fail=0
printf '\n======== FORMAT B:/S onto a blank disk\n'
# /S reads the three system files in before it prompts, so the keystroke that
# answers the prompt has to come later than the plain format needs it.
if ./runtest.sh -t 330 -K 20 -k "ret" -b "$BIMG" \
                -e "System transferred" \
                -e "1457664 bytes total disk space" \
                -e "1418240 bytes available on disk" \
                -e "DONE" tests/formats.bat
then :; else fail=1; fi

printf '\n======== what FORMAT /S put on it\n'
python3 - "$BIMG" bin/bootsect.bin bin/IO.SYS bin/MSDOS.SYS bin/COMMANDF.COM <<'PY' || fail=1
import struct, sys
img, boot = (open(p, "rb").read() for p in sys.argv[1:3])
sources = dict(zip(("IO.SYS", "MSDOS.SYS", "COMMAND.COM"), sys.argv[3:6]))
ok = True
def check(good, what):
    global ok
    print("%s %s" % ("ok     " if good else "MISSING", what))
    ok = ok and good

check(img[:512] == boot, "sector 0 is the boot sector bootsect.asm builds")
check(img[512] == 0xF8 and img[513:515] == b"\xff\xff",
      "the FAT starts with the ID FORMAT wrote, F8 FF FF")

res  = struct.unpack_from("<H", img, 0x0e)[0]      # reserved sectors
nfat = img[0x10]
spf  = struct.unpack_from("<H", img, 0x16)[0]      # sectors per FAT
root = struct.unpack_from("<H", img, 0x11)[0]      # root entries
spc  = img[0x0d]                                   # sectors per cluster
rootsec = res + nfat * spf
datasec = rootsec + (root * 32 + 511) // 512

def chain(c):
    while 2 <= c < 0xFF0:
        yield c
        v = struct.unpack_from("<H", img, res * 512 + c + c // 2)[0]
        c = (v >> 4) if (c & 1) else (v & 0xFFF)

def contents(c, size):
    data = b""
    for cl in chain(c):
        start = (datasec + (cl - 2) * spc) * 512
        data += img[start: start + spc * 512]
    return data[:size]

found = {}
for i in range(root):
    e = img[rootsec * 512 + i * 32: rootsec * 512 + (i + 1) * 32]
    if e[0] in (0x00, 0xE5):
        continue
    name = e[:8].decode("latin-1").strip() + "." + e[8:11].decode("latin-1").strip()
    found[name] = (struct.unpack_from("<H", e, 26)[0],
                   struct.unpack_from("<I", e, 28)[0], e[11])

check(list(found) == ["IO.SYS", "MSDOS.SYS", "COMMAND.COM"],
      "the root directory holds the three system files, in that order (%s)"
      % (", ".join(found) or "it is empty"))
for name, src in sources.items():
    if name not in found:
        check(False, "%s is on the disk" % name)
        continue
    clus, size, attr = found[name]
    want = open(src, "rb").read()
    hidden = attr & 0x06 == 0x06
    if name == "IO.SYS":
        check(clus == 2, "IO.SYS starts at cluster 2, where the loader looks")
        check(hidden, "and is hidden and system, as the loader needs")
    check(size == len(want) and contents(clus, size) == want,
          "%s is the %d bytes of %s, byte for byte" % (name, len(want), src))
sys.exit(0 if ok else 1)
PY

printf '\n======== booting the disk FORMAT /S made\n'
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
then echo "ok      the disk FORMAT /S made boots on its own"
else echo "MISSING the disk did not boot to a command prompt"; fail=1
fi

exit $fail
