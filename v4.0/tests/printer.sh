#!/bin/sh
# Load PRINTER.SYS from CONFIG.SYS on the system this builds, and ask it
# what it is holding with the utility that talks to it.
#
# PRINTER.SYS is DISPLAY.SYS's other half: it takes PRN and LPT1 to LPT3
# over -- the device header at the front of the file is four headers chained
# inside the one image, one for each -- and what it adds is the code pages.
# The DEVICE= line says which printer is on which port, which code page the
# printer itself has, and how many prepared ones to make room for; MODE CP
# PREPARE then hands it a .CPI file through the generic IOCTL call, after
# which a character the printer has no glyph of its own for is sent as the
# prepared font's.
#
#   DEVICE=\PRINTER.SYS LPT1=(4201,437,1)   the printer, its page, room for 1
#   MODE LPT1 CP /STATUS                    what the driver says it holds
#
# Preparing a page is not driven here: that wants a .CPI file, which the
# release's build makes out of the 4201, 4208 and 5202 directories with a
# tool this project does not build yet.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/printer.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/PRINTER.SYS ::PRINTER.SYS
mcopy -o -i "$IMG" bin/MODE.COM ::MODE.COM

printf 'DEVICE=\\PRINTER.SYS LPT1=(4201,437,1)\r\n' > "$OUT/CONFIG.SYS"
mcopy -o -i "$IMG" "$OUT/CONFIG.SYS" ::CONFIG.SYS

{
    printf 'ECHO OFF\r\n'
    printf 'MODE LPT1 CP /STATUS\r\n'
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
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
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


ok("Invalid syntax" not in screen,
   "the parser took the port, the printer and the two numbers after it")
ok("Hardware code pages:" in screen and "code page 437" in screen,
   "and MODE LPT1 CP /STATUS came back with the hardware code page the "
   "line gave it, which it asked the driver for through the generic IOCTL "
   "call")
ok("Prepared code pages:" in screen and "code page not prepared" in screen,
   "and with the one prepared page the line made room for, which nothing "
   "has filled in")
ok("MODE status code page function completed" in screen,
   "and MODE says the call came back without an error")
ok("code page driver cannot be initialized" not in screen,
   "and the driver did not call the port bad, which is what it says of one "
   "it has not brought up")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt")
sys.exit(rc)
PY
