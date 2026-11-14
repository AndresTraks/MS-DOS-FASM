#!/bin/sh
# Run IFSFUNC.EXE on the system this builds, and see that it installs and
# answers for itself afterwards.
#
# IFSFUNC is the installable file system support: it answers for a drive the
# kernel cannot read itself -- a network redirector, or any other file
# system that installs itself on the interface INC/IFSSYM.INC describes --
# and like SHARE it runs inside the kernel.  That is why IFSFUNC.LNK links
# seven of the kernel's own modules in beside its own nine and the stub:
# what it reads of the kernel's data it reads through SS at the offset its
# own assembly gives the name, so the copy of DOSGROUP in IFSFUNC.EXE has to
# come out with the offsets the one in MSDOS.SYS has.  All seventeen that
# were held against each other agree to the byte.
#
# There is no file system to attach here -- this disk has no CONFIG.SYS, let
# alone an IFS= line -- so what the first run has to say is "Invalid
# configuration", which is its own message 4.  Getting that far is most of
# what there is to see: the initialisation has read the kernel's current
# directory table through SS, found no drive to answer for, and said so.
#
#   IFSFUNC        reads the kernel's tables, finds nothing to attach
#   IFSFUNC        says it is there already, through interrupt 2FH
#   IFSFUNC /Z     the install check comes before the parse, so the same
#   TYPE, COPY, DIR   and the file calls go on working
#
# The second run is what says the first one stayed: the check is
# INT 2FH AX=MultIFS*256, which the kernel answers for nobody -- its own
# handler lets an unknown channel fall through to an IRET with AL as it came
# -- so AL comes back 0FFH only if IFSFUNC's own handler is on the chain.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/ifsfunc.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/IFSFUNC.EXE ::IFSFUNC.EXE
printf 'the file after the file system is in\r\n' > "$OUT/HELLO.TXT"
mcopy -o -i "$IMG" "$OUT/HELLO.TXT" ::HELLO.TXT

{
    printf 'ECHO OFF\r\n'
    printf 'IFSFUNC\r\n'
    printf 'IFSFUNC\r\n'
    printf 'IFSFUNC /Z\r\n'
    printf 'TYPE HELLO.TXT\r\n'
    printf 'COPY HELLO.TXT COPY.TXT\r\n'
    printf 'DIR COPY.TXT\r\n'
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


ok("Invalid configuration" in screen,
   "the first run read the kernel's tables and found no file system to "
   "answer for, which is its own message 4")
ok(screen.count("IFSFUNC already installed") == 2,
   "and both runs after it say it is there already, which is IFSFUNC's own "
   "interrupt 2FH handler answering -- the kernel answers for nobody on "
   "that channel",
   "it said so %d times, not twice"
   % screen.count("IFSFUNC already installed"))
ok("the file after the file system is in" in screen,
   "TYPE read a file with the file system resident")
ok("1 File(s) copied" in screen,
   "COPY wrote another")
ok("COPY     TXT" in screen,
   "and DIR lists it")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt")
sys.exit(rc)
PY
