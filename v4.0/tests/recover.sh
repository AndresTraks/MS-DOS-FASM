#!/bin/sh
# Run RECOVER.COM on the system this builds, both ways round.
#
# RECOVER is the first of the utilities to read and write the disk itself:
# it reads the FAT with INT 25H and writes it back with INT 26H, so the
# kernel's absolute read and write are what carry it, and the file it is
# given is rebuilt from the cluster chain rather than read through a handle.
#
# It has two jobs.  Given a file, it walks that file's chain, reads every
# cluster, drops the ones that will not read, and sets the file's length to
# what it could get back -- "40 of 40 bytes recovered" when the file is whole.
# Given a drive, it gives up on the directory altogether: every chain in the
# FAT becomes a file of its own called FILEnnnn.REC in the root, which is why
# the second run below takes the disk apart and the batch file with it.
#
# Both ways it asks for a key before it starts, through the message
# retriever, with the drive letter put in the message; the key is typed in.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/recover.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

# A disk of this test's own: the second run writes all over it, and it is
# read back here afterwards.
IMG="$OUT/disk.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/RECOVER.COM ::RECOVER.COM

# Forty bytes, which is one cluster of this disk and the number RECOVER
# should say it got back.
printf 'hello there, this is a file to recover\r\n' > "$OUT/FOO.TXT"
mcopy -o -i "$IMG" "$OUT/FOO.TXT" ::FOO.TXT

printf 'ECHO OFF\r\nRECOVER FOO.TXT\r\nRECOVER A:\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# A key for each of the two "press any key" prompts.  The last thing on the
# screen is COMMAND.COM asking for the disk with the batch file on it, which
# RECOVER has just renamed out from under it.
{
    await "Press any key to begin recovery of the"
    echo "sendkey a"
    await "Press any key to begin recovery of the" 2
    echo "sendkey a"
    await "file(s) recovered"
    cp "$SHOT" "$OUT/screen.bin"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

# The disk as RECOVER left it, read without the machine's help.
mdir -i "$IMG" :: > "$OUT/dir.txt" 2>/dev/null || true

python3 - "$OUT/screen.bin" "$OUT/dir.txt" <<'PY' || exit 1
import re
import sys

d = open(sys.argv[1], "rb").read()
rows = []
for row in range(25):
    cell = lambda c: d[(row * 80 + c) * 2]
    rows.append("".join(chr(cell(c)) if 32 <= cell(c) < 127 else " "
                        for c in range(80)).rstrip())
print("--- screen")
for r in rows:
    if r.strip():
        print("   %s" % r)
screen = "\n".join(rows)

rc = 0
print("--- checks")
want = [("Press any key to begin recovery of the",
         "it asked before touching the disk, through the retriever"),
        ("file(s) on drive A:",
         "with the drive letter put in the message"),
        ("40 of 40 bytes recovered",
         "the file came back whole: its chain read and its length set"),
        ("file(s) recovered",
         "and the whole disk afterwards, every chain a file of its own")]
for text, why in want:
    if text in screen:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1

dir_ = open(sys.argv[2]).read()
found = sorted(re.findall(r"(?m)^(FILE\d{4})\s+REC", dir_))
if len(found) >= 5 and found[0] == "FILE0001":
    print("ok      the root holds %s: %s, and nothing else, which is what "
          "recovering a drive leaves" % (", ".join(found[:3]) + ", ...",
                                         "the chains the FAT had"))
else:
    print("MISSING the FILEnnnn.REC files; the disk says %r"
          % dir_.split("\n")[:6])
    rc = 1
if "FOO" in dir_ or "RECOVER" in dir_:
    print("WRONG   a name survived the drive recovery: %r" % dir_)
    rc = 1
else:
    print("ok      no name survived it, directory and all")
sys.exit(rc)
PY
