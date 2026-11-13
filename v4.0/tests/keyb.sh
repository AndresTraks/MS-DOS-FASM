#!/bin/sh
# Run KEYB.COM on the system this builds, and see that it reads its command
# line, asks the machine what is installed, and says what it finds.
#
# KEYB is two halves.  The command half parses the keyboard code, the ID and
# the code page, asks over interrupt 2FH whether a copy of itself and the
# console driver are already there, reads a keyboard layout out of
# KEYBOARD.SYS, builds the translation tables from it and keeps itself
# resident; the resident half is a handler on interrupt 9 that turns a scan
# code into whatever character those tables ask for, with 2FH so a second
# copy finds the first and 48H for the 101-key enhancements.
#
#   KEYB            with nothing installed, says so, and says what it found
#                   when it asked the console driver for its code page
#   KEYB UK         reads the layout, and there is none to read
#   KEYB ZZ         the same, the file being opened before the code is judged
#
# The resident half is out of reach here, and not for want of trying: KEYB
# will not install without a KEYBOARD.SYS to build its tables from, and that
# file is built from the twenty-nine modules of src/DEV/KEYBOARD, which are
# still the release's own text.  What this drives is the whole of the command
# half -- the parser, both install checks, the search for the file, and the
# message retriever that prints all three answers.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/keyb.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/KEYB.COM ::KEYB.COM

{
    printf 'ECHO OFF\r\n'
    printf 'KEYB\r\n'
    printf 'KEYB UK\r\n'
    printf 'KEYB ZZ\r\n'
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


ok("KEYB has not been installed" in screen,
   "asked with nothing after it, KEYB answers that none is installed, "
   "which is the interrupt 2FH install check and the retriever")
ok("Active code page not available from CON device" in screen,
   "and says what the console driver answered about its code page, which "
   "is the second of the two checks")
ok(screen.count("Bad or missing Keyboard Definition File") == 2,
   "KEYB UK and KEYB ZZ each parse their keyboard code, go looking for "
   "KEYBOARD.SYS and say it is not there",
   "the missing-file message came %d times"
   % screen.count("Bad or missing Keyboard Definition File"))
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt, KEYB having let go of "
   "everything it loaded")
sys.exit(rc)
PY
