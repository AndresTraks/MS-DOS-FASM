#!/bin/sh
# Start a machine from the disk this builds, and see how far it gets.
#
# Everything else here is held against the sources or against what MS-DOS 4.00
# is documented to be.  This is the other kind of test: it runs the thing.
#
# A boot of 4.00 is a long chain, and each link is something the conversion
# could have broken without the assembler noticing.  The boot sector reads
# MSLOAD; MSLOAD walks the FAT and reads the rest of IO.SYS to 70h:0; the BIOS
# initialises the drivers, loads MSDOS.SYS and jumps to SYSINIT; SYSINIT moves
# the kernel to its final home and calls DOSINIT, which builds the DOS's data
# and takes over the interrupts; SYSINIT reads CONFIG.SYS through INT 21H,
# installs the switchable hardware stacks, and EXECs COMMAND.COM.
#
# What COMMAND.COM then prints is the proof.  It asks for the date and the
# time, because there is no AUTOEXEC.BAT on the disk, and both lines are
# messages the retriever looked up by number and the console driver wrote; the
# answers go back through the driver's input side and the parser; then the
# version banner, then the prompt.  VER is answered from the resident, and DIR
# reads the directory through the kernel and writes it a line at a time -- the
# first entry comes back from one call and the rest from a second, so the whole
# listing has to be there, down to the count of files it ends with.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/boot.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

./create_image.sh >/dev/null

# A CONFIG.SYS with one setting in it, so that the file is read and parsed as
# well as found.
printf 'FILES=20\r\n' > "$OUT/CONFIG.SYS"
mcopy -o -i msdos.img "$OUT/CONFIG.SYS" ::CONFIG.SYS

# The monitor is on stdin; the screen comes back through pmemsave as the text
# the adapter is showing.  It is read twice: the directory listing is long
# enough to scroll the date and the time off the top.
{
    sleep 24
    for k in ret ret; do echo "sendkey $k"; sleep 2; done
    for k in v e r ret; do echo "sendkey $k"; sleep 1; done
    sleep 2
    echo "pmemsave 0xb8000 4000 \"$OUT/early.bin\""
    sleep 2
    for k in d i r ret; do echo "sendkey $k"; sleep 1; done
    sleep 3
    echo "pmemsave 0xb8000 4000 \"$OUT/screen.bin\""
    sleep 2
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file=msdos.img,format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/early.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }
[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

python3 - "$OUT/early.bin" "$OUT/screen.bin" <<'PY' || exit 1
import sys


def read(path):
    d = open(path, "rb").read()
    rows = []
    for row in range(25):
        cell = lambda c: d[(row * 80 + c) * 2]
        rows.append("".join(chr(cell(c)) if 32 <= cell(c) < 127 else " "
                            for c in range(80)).rstrip())
    return rows


early, late = read(sys.argv[1]), read(sys.argv[2])
for name, rows in (("screen, before DIR", early), ("screen, after DIR", late)):
    print("--- %s" % name)
    for r in rows:
        if r.strip():
            print("   %s" % r)
screen = "\n".join(early + late)

want = [("Current date is",
         "the kernel dispatches, the console driver writes and COMMAND.COM ran"),
        ("Enter new date", "the interpreter is asking, so the retriever found its text"),
        ("Current time is", "the date went in through the console and the parser took it"),
        ("Microsoft(R) MS-DOS(R) Version 4.00",
         "both answers were accepted and initialisation finished"),
        ("A>", "the prompt, from the transient part of the interpreter"),
        ("MS-DOS Version 4.00", "VER was read from the keyboard and answered"),
        ("IO       SYS", "DIR read the root directory through the kernel"),
        ("COMMAND  COM", "and went on past the first entry it found"),
        ("File(s)", "and ran to the end of the directory")]
rc = 0
print("--- checks")
for text, why in want:
    if text in screen:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1
sys.exit(rc)
PY
