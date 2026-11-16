#!/bin/sh
# Load XMAEM.SYS from CONFIG.SYS on the system this builds, and read the two
# jump tables out of the image it was built from.
#
# XMAEM is the 80386 XMA emulator: on a PS/2 Model 80 it puts the processor
# into protected mode, keeps a descriptor table and an interrupt table of its
# own, runs what was there as a virtual 8086 task, and answers the interface
# of the XMA memory card of a 3270 PC out of page tables -- so that software
# written for the card runs on a machine that has none.  It installs on that
# machine and no other: the first thing it does is read the model byte at
# FFFF:000E and look for 0F8H, and QEMU's BIOS reports 0FCH, so what the
# driver does here is print its banner, say the system unit is not supported,
# leave nothing resident and let the machine boot on.  That is the whole of
# what a run can show, and it is worth showing: it means the ten modules
# loaded, the messages the skeleton built are where the code looks for them,
# and the driver's own INIT ran and returned a status DOS was happy with.
#
# The emulator proper is behind that check, so the run cannot reach it.  What
# it turns on is a table of 256 three-byte jumps indexed by the op-code that
# faulted, and another of 32 indexed by the DMA port, and both are built the
# way MASM let a program build one: a REPT lays every entry down jumping to
# the routine that passes the thing through, and then an ORG and a JMP for
# each one the emulator handles itself, written over the entry it lands on.
# Neither thing survives a careless conversion -- fasm writes a short jump
# wherever one reaches, which makes an entry two bytes instead of three, and
# an ORG there moves the address and not the place the output goes, so the
# jumps are appended to the table instead of written into it.  Either way the
# table assembles and the emulator jumps into the middle of an entry.  So the
# image is read here as well: every entry a three-byte near jump, 256 and 32
# of them, and as many pointing away from the default as the source writes
# ORGs.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/xmaem.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/XMAEM.SYS ::XMAEM.SYS

printf 'DEVICE=\\XMAEM.SYS\r\n' > "$OUT/CONFIG.SYS"
mcopy -o -i "$IMG" "$OUT/CONFIG.SYS" ::CONFIG.SYS

{
    printf 'ECHO OFF\r\n'
    printf 'VER\r\n'
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
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

python3 - "$OUT/screen.bin" <<'PY' || exit 1
import collections
import re
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


ok("80386 XMA Emulator Version 1.10" in screen,
   "the driver loaded and printed its banner, which is the message "
   "XMAEM.SKL names first")
ok("(C) Copyright IBM Corporation 1987, 1988" in screen,
   "and the second line of it, so the message is laid down whole and the "
   "code has the address of its first byte")
ok("80386 XMA Emulator not installed. This system unit" in screen
   and "is not supported." in screen,
   "and then said the system unit is not supported, which is the message "
   "for a model byte that is not 0F8H -- it read FFFF:000E and QEMU's BIOS "
   "says 0FCH")
ok("MS-DOS Version 4.00" in screen,
   "and the machine booted on with nothing of the driver resident, the INIT "
   "having returned an end address of nought")
ok(screen.rstrip().endswith("A>"),
   "and it is back at the prompt")

# The image, and the two tables in it.  The MZ header says how far in the
# load image begins; a driver is read from the front of that image, where
# the device header stands.
image = open("bin/XMAEM.SYS", "rb").read()
ok(image[:2] == b"MZ",
   "the file is an .EXE, which is what the release's LINK wrote and what no "
   "other driver here is: SYSCONF loads a driver with EXEC's load-overlay "
   "call, and that relocates one")
header = int.from_bytes(image[8:10], "little") * 16
relocs = int.from_bytes(image[6:8], "little")
img = image[header:]
ok(relocs == 4,
   "with four relocations in it, which are the four words the INIT writes "
   "its own segment into -- the task state segment the virtual 8086 task "
   "runs under, whose GS, FS, DS and ES are the driver's own code segment",
   "the header says %d relocations, not four" % relocs)
ok(img[:4] == b"\xff\xff\xff\xff" and img[10:18] == b"386XMAEM",
   "and the device header at the front of the image, with the name DOS "
   "reads the driver by")

# Every run of at least sixteen three-byte near jumps, which is what a table
# of them looks like and what nothing else in the image does.
runs = []
i = 0
while i < len(img) - 2:
    if img[i] != 0xE9:
        i += 1
        continue
    n = 0
    while i + 3 * n + 2 < len(img) and img[i + 3 * n] == 0xE9:
        n += 1
    if n >= 16:
        where = []
        for k in range(n):
            off = i + 3 * k
            rel = int.from_bytes(img[off + 1:off + 3], "little", signed=True)
            where.append((off + 3 + rel) & 0xFFFF)
        common = collections.Counter(where).most_common(1)[0][1]
        runs.append((i, n, n - common))
    i += 3 * max(n, 1)

sizes = [n for _, n, _ in runs]
ok(sizes == [256, 32],
   "the image holds two tables of three-byte near jumps, of 256 entries and "
   "of 32: one entry per op-code the emulator may be handed and one per DMA "
   "port.  An entry of two bytes would put every entry after it at the wrong "
   "offset, and the emulator indexes the table by the op-code times three",
   "the runs of three-byte jumps are %s, not 256 and 32" % sizes)

# As many entries point away from the default as the source writes ORGs over
# the table: eighteen in INDEEMU and seven in INDEDMA.
wrote = []
for stem in ("INDEEMU.ASM", "INDEDMA.ASM"):
    text = open("src/DEV/XMAEM/%s" % stem, encoding="cp437").read()
    wrote.append(len(re.findall(r"(?m)^\s*jmpover\$", text)))
ok([p for _, _, p in runs] == wrote,
   "and %d entries of the one and %d of the other point away from the "
   "routine the rest jump to, which is one for each ORG the two modules "
   "write back over their table" % tuple(wrote),
   "%s entries point away from the default, where the modules write %s ORGs"
   % ([p for _, _, p in runs], wrote))
sys.exit(rc)
PY
