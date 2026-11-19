#!/bin/sh
# Check the two doors into the kernel: INT 21H, and the CP/M CALL 5.
#
# Every MS-DOS program asks through INT 21H with the function in AH.  A
# program carried over from CP/M asks with a CALL 5 and the function in CL,
# and 4.00 still keeps that entry: src/DOS/MISC.ASM writes a long call at
# offset 5 of the program's base, pointing at (0CH-n):(n*16), and DISP.ASM
# takes it in at the other end, re-ordering the stack as if an interrupt had
# been used.  The first of those addresses is a megabyte above 0:00C0, where
# the kernel leaves a long jump to its dispatcher, so what joins them is the
# wrap at the top of an 8088's twenty address lines.
#
# Nothing else in the release uses that door, so nothing here had ever opened
# it.  It does not work on this machine as it stands, and the kernel is not
# why: a modern BIOS leaves the A20 gate open -- QEMU's does -- the call
# lands a megabyte up in nothing, and the machine is gone.
#
# So this runs the same program twice.  Without an argument it asks both ways
# with the gate as the BIOS left it, and the CP/M line does not come: that is
# the machine, named.  With a C it closes the gate first and the same call
# answers, which is the kernel's end of it working.
#
# The system does not close the gate for itself here, and must not: by 4.00
# RAMDRIVE, SMARTDRV and XMA2EMS reach above the first megabyte themselves,
# so the gate is state software owns.  v1.25 and v2.0 are 8088-era systems
# with nothing above a megabyte, and their BIOSes close it at init.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

if command -v fasm >/dev/null 2>&1; then
    FASM=fasm
elif command -v wine >/dev/null 2>&1; then
    FASM="wine ../fasmw17332/FASM.EXE"
    WINEDEBUG=${WINEDEBUG:--all}
    export WINEDEBUG
else
    echo "$0: neither fasm nor wine found" >&2
    exit 2
fi

OUT=${TMPDIR:-/tmp}/v40call5.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

$FASM tests/call5.asm "$OUT/CALL5.COM" >/dev/null

# One machine per way round, each on a disk of its own.
boot() {
    name=$1
    tail=$2
    img="$OUT/$name.img"
    ./create_image.sh "$img" >/dev/null
    mcopy -o -i "$img" "$OUT/CALL5.COM" ::CALL5.COM
    {
        printf 'CALL5%s\r\n' "$tail"
        printf 'ECHO THAT IS ALL\r\n'
    } > "$OUT/AUTOEXEC.BAT"
    mcopy -o -i "$img" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT
    python3 dosdir.py "$img"
    {
        # The machine that runs off never reaches the echo, so this waits for
        # whichever comes first and then takes the screen.
        _i=0
        while [ "$_i" -lt 60 ]; do
            snap
            grep -qF -e "THAT IS ALL" -e "and back from it" "$SEEN" && break
            _i=$((_i + 1))
            sleep 0.5
        done
        cp "$SHOT" "$OUT/$name.bin"
        echo quit
    } | "$QEMU" -rtc base=localtime -boot order=a \
                -drive file="$img",format=raw,if=floppy,index=0 \
                -display none -monitor stdio >/dev/null 2>&1 || true
    [ -s "$OUT/$name.bin" ] \
        || { echo "$0: the screen never came back from $name" >&2; exit 1; }
}

boot open ''
boot closed ' C'

python3 - "$OUT/open.bin" "$OUT/closed.bin" <<'PY' || exit 1
import subprocess
import sys


def screen(path):
    text = subprocess.run([sys.executable, "tests/screen.py", path],
                          capture_output=True, text=True).stdout
    return [l.rstrip() for l in text.split("\n") if l.strip()]


opened, closed = (screen(p) for p in sys.argv[1:3])
for title, shot in (("the gate as the BIOS left it", opened),
                    ("the gate closed by the program", closed)):
    print("--- what it said with %s" % title)
    for line in shot:
        print("   %s" % line)

rc = 0
print("--- checks")


def ok(yes, why, missing=None):
    global rc
    if yes:
        print("ok      %s" % why)
    else:
        print("WRONG   %s" % (missing or why))
        rc = 1


def said(shot, text):
    return any(text in l for l in shot)


ok(said(opened, "INT 21H: yes"),
   "with the gate open the program ran and asked through INT 21H")
ok(not said(opened, "CALL 5: yes"),
   "and the CALL 5 did not answer: the long call the kernel wrote is a "
   "megabyte above the long jump it points at, and nothing wraps it back",
   "the CALL 5 answered with the gate open, which it cannot do unless "
   "something closed the gate")
ok(not said(opened, "THAT IS ALL"),
   "and the machine never reached the end of the batch file, which is what "
   "a call into nothing does",
   "the machine carried on after the CALL 5, so it did not go where this "
   "test says it goes")
ok(said(closed, "A20 closed") and said(closed, "INT 21H: yes"),
   "with the gate closed by the program, the same program ran")
ok(said(closed, "CALL 5: yes"),
   "and the CALL 5 answered: the kernel's end of the CP/M entry is right, "
   "and the machine was all that was wrong with it")
ok(said(closed, "and back from it"),
   "and came back, so DISP.ASM re-ordered the stack as it says it does")
ok(said(closed, "THAT IS ALL"),
   "and the batch file ran to the end")
sys.exit(rc)
PY
