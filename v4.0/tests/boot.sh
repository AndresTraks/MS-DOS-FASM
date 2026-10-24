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
# installs the switchable hardware stacks, and EXECs the command interpreter.
#
# There is no COMMAND.COM yet -- the utilities under src/CMD are not converted
# -- so tests/shell.asm stands in for it, and what it prints is the proof:
# the message only appears if the kernel dispatches, the console driver writes,
# and EXEC loaded a program.  Then a few keystrokes are sent and echoed back,
# which is the input side, and ESC makes the shell exit, after which DOS says
# what it always says when the interpreter goes away.
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
# the adapter is showing.
{
    sleep 22
    for k in h e l l o ret esc; do echo "sendkey $k"; sleep 1; done
    sleep 2
    echo "pmemsave 0xb8000 4000 \"$OUT/screen.bin\""
    sleep 2
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file=msdos.img,format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

python3 - "$OUT/screen.bin" <<'PY' || exit 1
import sys
d = open(sys.argv[1], "rb").read()
rows = []
for row in range(25):
    cell = lambda c: d[(row * 80 + c) * 2]
    rows.append("".join(chr(cell(c)) if 32 <= cell(c) < 127 else " "
                        for c in range(80)).rstrip())
screen = "\n".join(rows)
print("--- screen")
for r in rows:
    if r.strip():
        print("   %s" % r)

want = [("MS-DOS 4.00 built by fasm is running",
         "the kernel dispatches, the console driver writes and EXEC ran a program"),
        ("Type anything", "the interpreter got as far as reading the keyboard"),
        ("ello", "what was typed came back, so console input works"),
        ("ESC seen", "the shell saw ESC and said so"),
        ("Bad or missing Command Interpreter",
         "DOS noticed the interpreter had gone, and found the message to say it")]
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
