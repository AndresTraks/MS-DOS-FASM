#!/bin/sh
# Run EMM386.COM on the system this builds, twice over: once with nothing
# installed and then with a stand-in for the driver, and once with a
# stand-in that refuses every change.
#
# EMM386.COM is the utility that reads and sets the mode of the EMM386
# driver -- EMM386 by itself for the mode it is in, EMM386 ON, OFF or AUTO
# to put it in one -- and it is the one program in the release made of
# assembler alone that the release's own build does not build: the rule is
# commented out of src/MEMM/MEMM/MAKEFILE along with the two that would
# assemble its modules.  So there is nothing of Microsoft's to compare the
# image with, and what it does is the only test there is.
#
# The driver it asks is not here either: EMM386.EXE links emmlib.lib, which
# is C.  With nothing installed the utility reaches one of its nine messages
# and stops, so tests/emmstub.asm stands in for the driver -- the two fields
# Inst_chk reads of one and a mode byte to keep, and no EMM function at all.
# That is enough to reach the whole program: the signature compare, the far
# call through the entry point in the header, the parse of the command tail,
# and all nine messages.
#
# What each of the checks below shows is named with it.  Between them they
# are the program: the three EQUs that are a length taken from the address
# counter (the signature's, each argument's), the two tables indexed by what
# the parse returned (arg_tbl and arg_len), the message table indexed the
# same way, the struc that is read for two offsets and never laid down, and
# the far call through a dword of the program's own data.
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

OUT=${TMPDIR:-/tmp}/emm386.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

# The stand-in is a test of this test and not part of the release, so it is
# built here rather than in assemble.sh.
$FASM tests/emmstub.asm "$OUT/EMMSTUB.COM" >/dev/null

# One machine per batch file, each on a disk of its own.
boot() {
    name=$1
    img="$OUT/$name.img"
    ./create_image.sh "$img" >/dev/null
    mcopy -o -i "$img" bin/EMM386.COM ::EMM386.COM
    mcopy -o -i "$img" "$OUT/EMMSTUB.COM" ::EMMSTUB.COM
    mcopy -o -i "$img" "$OUT/$name.bat" ::AUTOEXEC.BAT
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

# With nothing installed, and then with the stand-in: the mode it starts in,
# a change, the mode again to show the change stuck, auto, back on, and a
# word that is none of the three.
{
    printf 'ECHO OFF\r\n'
    printf 'EMM386\r\n'
    printf 'EMMSTUB\r\n'
    printf 'EMM386\r\n'
    printf 'EMM386 OFF\r\n'
    printf 'EMM386\r\n'
    printf 'EMM386 AUTO\r\n'
    printf 'EMM386 ON\r\n'
    printf 'EMM386 ZZZ\r\n'
    printf 'ECHO THAT IS ALL\r\n'
} > "$OUT/plain.bat"

# And with a stand-in that refuses every change, which is the arm of the
# utility that turns the parse's answer into one of the three messages for a
# change the driver would not make.
{
    printf 'ECHO OFF\r\n'
    printf 'EMMSTUB /R\r\n'
    printf 'EMM386 ON\r\n'
    printf 'EMM386 OFF\r\n'
    printf 'EMM386 AUTO\r\n'
    printf 'EMM386\r\n'
    printf 'ECHO THAT IS ALL\r\n'
} > "$OUT/refuse.bat"

boot plain
boot refuse

python3 - "$OUT/plain.bin" "$OUT/refuse.bin" <<'PY' || exit 1
import re
import subprocess
import sys


def screen(path):
    text = subprocess.run([sys.executable, "tests/screen.py", path],
                          capture_output=True, text=True).stdout
    return [l.rstrip() for l in text.split("\n") if l.strip()]


plain, refuse = screen(sys.argv[1]), screen(sys.argv[2])

for title, lines in (("with the stand-in loaded half way through", plain),
                     ("with a stand-in that refuses", refuse)):
    print("--- what it said %s" % title)
    for line in lines:
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


def after(lines, text):
    """The lines from the one holding TEXT on, or nothing."""
    for n, line in enumerate(lines):
        if text in line:
            return lines[n:]
    return []


ok("EMM386 driver not installed." in plain,
   "with nothing installed it said so: Inst_chk read the segment out of the "
   "vector of INT 67H, compared the signature and did not find it")
ok("EMM386 driver stand-in resident." in plain,
   "and the stand-in loaded")

# What the utility said after the stand-in was there, in order.
said = after(plain, "stand-in resident.")
ok(said[1:2] == ["EMM386 Active."],
   "then the bare EMM386 read the mode as active: the signature matched, "
   "which is 37 bytes counted by an EQU off the address counter, and the "
   "mode came back through a far call to the entry point at 12h of the "
   "header -- the offset of a struc field in a struc nothing lays down",
   "after the stand-in loaded the bare EMM386 said %r" % (said[1:2],))
ok(said[2:3] == ["EMM386 Inactive."],
   "EMM386 OFF set it inactive: the parse matched the second of its three "
   "arguments, AH=1 and AL=1 went in through the same far call, and the "
   "read that follows a set printed what came back",
   "EMM386 OFF said %r" % (said[2:3],))
ok(said[3:4] == ["EMM386 Inactive."],
   "and the bare EMM386 after it said inactive as well, so the set reached "
   "the driver and was not the utility's own idea of the mode",
   "the bare EMM386 after the set said %r" % (said[3:4],))
ok(said[4:6] == ["EMM386 in Auto mode.", "EMM386 Active."],
   "EMM386 AUTO printed two messages in that order: a mode of 2 or more is "
   "auto, and the utility prints that and then takes 2 off to print which "
   "of the two the driver is in",
   "EMM386 AUTO said %r" % (said[4:6],))
ok(said[6:7] == ["EMM386 Active."],
   "EMM386 ON put it back: the first of the three arguments, and the third "
   "message of the three a mode of 0, 1 or 2 reaches",
   "EMM386 ON said %r" % (said[6:7],))
ok(said[7:8] == ["Usage: EMM386 [ ON | OFF | AUTO]"],
   "and EMM386 ZZZ printed the usage: the parse ran out of its table, "
   "which it measures with max_args -- another EQU off the address counter "
   "-- and came back with the carry set",
   "EMM386 ZZZ said %r" % (said[7:8],))

told = after(refuse, "stand-in resident.")
ok(told[1:4] == ["Unable to activate EMM386.",
                 "Unable to inactivate EMM386.",
                 "Unable to place EMM386 in Auto mode."],
   "the stand-in that refuses got all three of the messages for a change "
   "the driver would not make, each the right one: the utility adds "
   "max_args/2+1 to what the parse returned and indexes the same table "
   "with it",
   "the three refusals said %r" % (told[1:4],))
ok(told[4:5] == ["EMM386 Active."],
   "and the mode was still what it was, none of the three having taken",
   "after the three refusals the mode read %r" % (told[4:5],))

ok(plain[-1].endswith("A>") and refuse[-1].endswith("A>"),
   "both machines came back to the prompt, so every run of it ended at the "
   "exit call rather than anywhere else")

# The image itself: what LINK and EXE2BIN would have left.
image = open("bin/EMM386.COM", "rb").read()
ok(image[:2] != b"MZ" and image[0] == 0xEB,
   "the image is a flat .COM and begins with the jump over the data that "
   "EMM386 proc's first line is, with no .EXE header on it: that is what "
   "the release's own rule would have made of it, LINK and then EXE2BIN")
ok(b"MICROSOFT EXPANDED MEMORY MANAGER 386" in image,
   "and the signature it compares the driver's with is in it whole")
ok(image[0x40:0x45] == b"\xff\x1e\x27\x01\xc3",
   "ELIM_link is a far call through the dword at 127h and a near return: "
   "MASM's CALL of a DWORD variable is an indirect far call, and a near "
   "one there would have gone to the offset and left the segment on the "
   "stack",
   "ELIM_link assembles to %s" % image[0x40:0x45].hex())
sys.exit(rc)
PY
