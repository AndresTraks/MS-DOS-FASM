#!/bin/sh
# Load DISPLAY.SYS from CONFIG.SYS on the system this builds, and ask it
# what it is holding with the utility that talks to it.
#
# DISPLAY.SYS takes the console over the way ANSI.SYS does -- DOS gives CON
# to the last driver that claims the name -- and what it adds is the code
# pages: the DEVICE= line says which adapter is there, which code page the
# hardware has, and how many more to make room for.  MODE CON CP /STATUS
# asks the driver through the generic IOCTL call, which is the one interface
# between the two, so a machine that answers it has the driver installed,
# the switches parsed and the IOCTL side of DISPLAY working.
#
#   DEVICE=\DISPLAY.SYS CON:=(EGA,437,1)   the adapter, its page, room for 1
#   MODE CON CP /STATUS                    what the driver says it holds
#
# Loading a prepared code page is not driven here: that wants EGA.CPI, which
# the release's build makes out of the EGA directory with a tool of its own
# and this project does not build yet.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/display.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/DISPLAY.SYS ::DISPLAY.SYS
mcopy -o -i "$IMG" bin/MODE.COM ::MODE.COM

printf 'DEVICE=\\DISPLAY.SYS CON:=(EGA,437,1)\r\n' > "$OUT/CONFIG.SYS"
mcopy -o -i "$IMG" "$OUT/CONFIG.SYS" ::CONFIG.SYS

{
    printf 'ECHO OFF\r\n'
    printf 'MODE CON CP /STATUS\r\n'
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


ok("cannot be initialized" not in screen,
   "the driver took the DEVICE= line, which is its own message 2 for when "
   "it does not")
ok("Invalid syntax" not in screen,
   "and the parser took the three things in brackets after CON:=, which is "
   "its message 12 for when it does not")
ok("Hardware code pages:" in screen and "code page 437" in screen,
   "and MODE CON CP /STATUS came back with the hardware code page the line "
   "gave it, which it asked the driver for through the generic IOCTL call")
ok("Prepared code pages:" in screen and "code page not prepared" in screen,
   "and with the one prepared page the line made room for, which nothing "
   "has filled in")
ok("MODE status code page function completed" in screen,
   "and MODE says the call came back without an error")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt, the console still being written "
   "through the driver")
sys.exit(rc)
PY
