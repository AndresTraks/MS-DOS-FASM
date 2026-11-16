#!/bin/sh
# Load XMA2EMS.SYS from CONFIG.SYS on the system this builds, three times
# over: with no parameter, with a /X value the parser must refuse, and with
# one it must take.
#
# XMA2EMS is the expanded memory manager, and the LIM 4.0 side of the pair
# XMAEM begins: XMAEM makes a 386 look like the XMA memory card of a 3270
# PC, and this hands the card's pages out through INT 67H, which is what the
# device called EMMXXXX0 answers.  It installs only where there is a card to
# hand out -- it looks for the adapter by reading its ports, and QEMU has
# none -- so what it does here is print its banner, say it cannot find the
# adapter, say the manager has not been installed, and let DOS report the
# CONFIG.SYS line and boot on.
#
# That much shows the one module and its ten headers loaded, the messages
# the skeleton built are where the code looks for them, and the driver's own
# INIT ran and returned a status DOS was happy with.  The parameter is what
# shows the rest: the DEVICE= line is read with the kernel's own parser out
# of src/INC/PARSE.ASM, against control blocks XMA2EMSP lays down by hand,
# and the answer comes back in a result block the code reads field by field
# -- X_Switch+P_Control_Blk.P_KeyorSW for the switch it was given and
# X_Result.P_Picked_Val for the number after it.  /X:1 is below the range
# those blocks declare (4 to 512, which is 64KB to 8MB) and has to come back
# "Parameter syntax or value error"; /X:64 is inside it, and the driver has
# to get past the parser to the adapter search.  Neither answer is reachable
# at all if the parser's blocks or the result's fields came out wrong.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/xma2ems.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

# One machine per DEVICE= line, each on a disk of its own.
boot() {
    name=$1
    line=$2
    img="$OUT/$name.img"
    ./create_image.sh "$img" >/dev/null
    mcopy -o -i "$img" bin/XMA2EMS.SYS ::XMA2EMS.SYS
    printf '%s\r\n' "$line" > "$OUT/CONFIG.SYS"
    mcopy -o -i "$img" "$OUT/CONFIG.SYS" ::CONFIG.SYS
    {
        printf 'ECHO OFF\r\n'
        printf 'ECHO THAT IS ALL\r\n'
    } > "$OUT/AUTOEXEC.BAT"
    mcopy -o -i "$img" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT
    # the entries mtools wrote get the tidying create_image.sh gives the rest
    python3 dosdir.py "$img"
    {
        await "THAT IS ALL" 1
        awaitprompt
        snap
        cp "$SHOT" "$OUT/$name.bin"
        echo quit
    } | "$QEMU" -rtc base=localtime -boot order=a \
                -drive file="$img",format=raw,if=floppy,index=0 \
                -display none -monitor stdio >/dev/null 2>&1 || true
    [ -s "$OUT/$name.bin" ] \
        || { echo "$0: the screen never came back from $name" >&2; exit 1; }
}

boot plain 'DEVICE=\XMA2EMS.SYS'
boot small 'DEVICE=\XMA2EMS.SYS /X:1'
boot good  'DEVICE=\XMA2EMS.SYS /X:64'

python3 - "$OUT/plain.bin" "$OUT/small.bin" "$OUT/good.bin" <<'PY' || exit 1
import subprocess
import sys


def screen(path):
    return subprocess.run([sys.executable, "tests/screen.py", path],
                          capture_output=True, text=True).stdout


plain, small, good = (screen(p) for p in sys.argv[1:4])

for title, text in (("with no parameter", plain),
                    ("with /X:1", small),
                    ("with /X:64", good)):
    print("--- what it said %s" % title)
    for line in text.split("\n"):
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


ok(all("XMA2EMS: Expanded Memory Manager" in t
       for t in (plain, small, good)),
   "all three loaded the driver and printed its banner, which is the "
   "message XMA2EMS.SKL names second")
ok("(c)Copyright Microsoft Corporation 1988" in plain,
   "and the second line of it, so the message is laid down whole and the "
   "code has the address of its first byte")
ok("Cannot find adapter" in plain,
   "with no parameter it looked for the XMA adapter and did not find one, "
   "QEMU having none to find")
ok("Parameter syntax or value error" in small,
   "with /X:1 the parser refused the value: the blocks XMA2EMSP lays down "
   "declare 4 to 512, so one page is outside the range")
ok("Cannot find adapter" not in small,
   "and it stopped there rather than going on to the adapter",
   "with /X:1 it went on to look for the adapter, so the parser took the "
   "value")
ok("Parameter syntax or value error" not in good
   and "Cannot find adapter" in good,
   "with /X:64 the parser took the value and the driver went on to the "
   "adapter search, which is the far side of the parser")
ok(all("Expanded Memory Manager has NOT been installed" in t
       for t in (plain, small, good)),
   "all three said the manager is not installed, which is the message the "
   "INIT prints when it leaves nothing resident")
ok(all("Error in CONFIG.SYS line 1" in t for t in (plain, small, good)),
   "and DOS reported the line, so the INIT came back with the error status "
   "in the request header and an end address of nought")
ok(all(t.rstrip().endswith("A>") for t in (plain, small, good)),
   "and all three machines booted on to the prompt")

# The image a driver is read from: DOS reads the device header at its front.
image = open("bin/XMA2EMS.SYS", "rb").read()
ok(image[:4] == b"\xff\xff\xff\xff",
   "the image begins with the device header's pointer to the next driver, "
   "which is -1 until DOS chains it: this is a flat image with no header "
   "of its own, which is what LINK and then EXE2BIN made of it")
ok(image[4:6] == b"\x40\xc0",
   "the attribute word is 0C040H -- a character device that answers the "
   "generic IOCTL call -- which is how DOS tells it from a block driver",
   "the attribute word is %04Xh" % int.from_bytes(image[4:6], "little"))
ok(image[10:18] == b"EMMXXXX0",
   "and the name is EMMXXXX0, the name every program that wants expanded "
   "memory opens to find out whether a manager is there")
sys.exit(rc)
PY
