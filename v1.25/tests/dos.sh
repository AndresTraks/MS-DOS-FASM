#!/bin/sh
# Take a file round the system: copy it, type it, rename it, list it, copy it
# again and erase it -- and then read the disk from this end and see that it
# says the same thing.
#
# This is the tree's first test of the kernel and the command interpreter.
# tests/asm.sh and tests/trans.sh run the release's own tools, which is a
# harder thing to get working but a narrow path through the system: they open
# a file, read it a record at a time and write another.  What this walks is
# the rest of what a disk operating system is -- COMMAND.COM's parsing of a
# command line and its two-argument commands, and underneath them the
# kernel's FCB calls (create, open, read, write, close, rename, delete) and
# the directory and FAT they work on.
#
# Every check is on something that had to go right for the next one to be
# possible, and the last two are off the disk rather than off the screen: the
# file the system copied is held byte for byte against the file that went in,
# and the names it erased are gone from the directory.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/v125dos.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG=$OUT/dos.img
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" tests/SOURCE.TXT ::SOURCE.TXT

{
    printf 'COPY SOURCE.TXT COPIED.TXT\r\n'
    printf 'TYPE COPIED.TXT\r\n'
    printf 'REN COPIED.TXT RENAMED.TXT\r\n'
    printf 'DIR RENAMED.TXT\r\n'
    printf 'COPY RENAMED.TXT KEPT.TXT\r\n'
    printf 'ERASE RENAMED.TXT\r\n'
    printf 'DIR RENAMED.TXT\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    # "File not found" is the last thing the batch file asks for, and the
    # prompt after it is the end of the run.
    await "File not found"
    cp "$SHOT" "$OUT/screen.bin"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true
[ -s "$OUT/screen.bin" ] \
    || { echo "$0: the screen never came back" >&2; exit 1; }

# What the disk holds now, read from this end.
mcopy -o -i "$IMG" ::KEPT.TXT "$OUT/KEPT.TXT" 2>/dev/null || true
mdir -i "$IMG" > "$OUT/dir.txt" 2>&1 || true

python3 - "$OUT/screen.bin" "$OUT/KEPT.TXT" tests/SOURCE.TXT "$OUT/dir.txt" \
    <<'PY' || exit 1
import os
import subprocess
import sys

screen = subprocess.run([sys.executable, "tests/screen.py", sys.argv[1]],
                        capture_output=True, text=True).stdout
lines = [l.rstrip() for l in screen.split("\n") if l.strip()]
print("--- the screen")
for line in lines:
    print("   %s" % line)
listing = open(sys.argv[4], errors="replace").read()
print("--- and the disk afterwards")
for line in listing.split("\n"):
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


def said(text):
    return any(text in l for l in lines)


source = open(sys.argv[3], "rb").read()
kept = open(sys.argv[2], "rb").read() if os.path.exists(sys.argv[2]) else b""

ok(said("1 File(s) copied"),
   "COPY made a second file of the first: a create, a read, a write and two "
   "closes through the kernel's FCB calls")
ok(said("This file is copied, typed, renamed and erased")
   and said("Second line, so that TYPE has two of them"),
   "TYPE read both lines of the copy back off the disk")
ok(any("RENAMED  TXT" in l and "110" in l for l in lines),
   "REN moved the directory entry to the new name, and DIR found it there "
   "with the size it had",
   "DIR did not show RENAMED TXT at 110 bytes")
ok(said("File not found"),
   "and after ERASE the same DIR found nothing, so the entry is gone")

ok(kept == source,
   "the file the system copied twice is byte for byte the file that went "
   "in, all %d of them" % len(source),
   "the copy is %d bytes and the original %d" % (len(kept), len(source)))
ok("SOURCE   TXT" in listing and "KEPT     TXT" in listing,
   "and the disk read from this end holds both the original and the copy")
ok("RENAMED" not in listing and "COPIED" not in listing,
   "with no trace of the two names it renamed and erased: the directory and "
   "the FAT agree with what the screen said",
   "the disk still holds a name the system should have erased")
sys.exit(rc)
PY
