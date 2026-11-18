#!/bin/sh
# Assemble a program with ASM.COM on the system this builds, convert the
# Intel hex with HEX2BIN.COM, and run what comes out.
#
# ASM.COM is the Seattle Computer Products 8086 Assembler 2.44, which is what
# Tim Paterson wrote 86-DOS with, and the release ships its source.  So does
# HEX2BIN.COM, which turns the hex ASM writes into a .COM.  Between them they
# are the toolchain this system was built with, and until this test there was
# nothing in the tree that ran either of them: this tree has no other test,
# and both programs were converted and never started.
#
# They had never worked.  Four things were wrong, each of them a silent
# difference between the dialect of the release's own text and what fasm
# reads of the same words -- see the commit that added this file.  What the
# checks below hold onto is the far side of all four:
#
#   * "Error Count =    0" is one message, printed whole.  SCP ASM ends a
#     message with the high bit set on its last character, which is what DM
#     writes and PRINT stops at; written as a plain DB every message ran
#     into the next, and this line came out as "Error Count = Symbol Table
#     size = Free space =" with no numbers at all.
#   * the error the bad source gets is its own message and nothing more,
#     which is the same thing said from the other side.
#   * the program runs and prints, which needs the whole of the assembler:
#     the data area it keeps its variables, buffers and FCBs in (the 52
#     reservations that had been collapsed to one word each), the number
#     parser (which the thirteen Jcc $+5 skips had been landing inside), and
#     the 33 jumps that had been assembled as "jump if parity even".
#   * and the bytes it wrote are the bytes fasm writes of the same program,
#     which is the one check here that does not go through the screen.
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

OUT=${TMPDIR:-/tmp}/v125asm.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG=$OUT/asm.img
./create_image.sh "$IMG" >/dev/null

# A source with one undefined label, for the error path.  CRLF and the 1AH
# at the end are what ASM reads: it looks for a carriage return at the end of
# a line and for that byte at the end of the file.
printf '\tMOV\tDX,NOSUCH\r\n\tEND\r\n\032' > "$OUT/BADTEST.ASM"

# ASM takes the drive letters in the extension: source, hex, then the listing
# -- A, A and Z for "read A:, write the hex to A:, no listing file".
# A PAUSE after each step, so that the screen the test reads is a screen
# that has stopped moving: the whole run takes a second or two and a
# snapshot of it in flight is a snapshot of whatever came next.
{
    printf 'ASM ASMTEST.AAZ\r\n'
    printf 'PAUSE\r\n'
    printf 'HEX2BIN ASMTEST\r\n'
    printf 'ASMTEST\r\n'
    printf 'PAUSE\r\n'
    printf 'ASM BADTEST.AAZ\r\n'
} > "$OUT/AUTOEXEC.BAT"

mcopy -o -i "$IMG" tests/ASMTEST.ASM ::ASMTEST.ASM
mcopy -o -i "$IMG" "$OUT/BADTEST.ASM" ::BADTEST.ASM
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# Three screens, because each is gone by the time the next is there: the
# good assembly, the program it produced running, and the error the bad
# source gets.
# The dump await matched on is the screen to keep -- taking another is
# taking the screen as it is by then, which is a screen further on.
{
    await "Error Count"
    cp "$SHOT" "$OUT/good.bin"
    echo "sendkey ret"
    await "Hello from SCP ASM"
    cp "$SHOT" "$OUT/ran.bin"
    echo "sendkey ret"
    await "Undefined label"
    cp "$SHOT" "$OUT/bad.bin"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true
for what in good ran bad; do
    [ -s "$OUT/$what.bin" ] \
        || { echo "$0: the screen never came back from $what" >&2; exit 1; }
done

# What the assembler wrote, off the disk it wrote it to.
mcopy -o -i "$IMG" ::ASMTEST.HEX "$OUT/ASMTEST.HEX" 2>/dev/null || true
mcopy -o -i "$IMG" ::ASMTEST.COM "$OUT/ASMTEST.COM" 2>/dev/null || true

# And the same program as fasm assembles it, to hold the bytes against.
cat > "$OUT/want.asm" <<'WANT'
use16
org 100h
	mov	dx,MSG
	mov	ah,9
	int	21h
	int	20h
MSG:	db	'Hello from SCP ASM 2.44',13,10,'$'
WANT
$FASM "$OUT/want.asm" "$OUT/want.bin" >/dev/null

python3 - "$OUT/good.bin" "$OUT/ran.bin" "$OUT/bad.bin" \
         "$OUT/ASMTEST.HEX" "$OUT/ASMTEST.COM" "$OUT/want.bin" <<'PY' || exit 1
import os
import subprocess
import sys


def screen(path):
    text = subprocess.run([sys.executable, "tests/screen.py", path],
                          capture_output=True, text=True).stdout
    return [l.rstrip() for l in text.split("\n") if l.strip()]


good, ran, bad = (screen(p) for p in sys.argv[1:4])
for title, shot in (("the assembly", good), ("the program it made", ran),
                    ("the source with an error in it", bad)):
    print("--- the screen at %s" % title)
    for line in shot:
        print("   %s" % line)
lines = good

rc = 0
print("--- checks")


def ok(yes, why, missing=None):
    global rc
    if yes:
        print("ok      %s" % why)
    else:
        print("WRONG   %s" % (missing or why))
        rc = 1


def read(path):
    return open(path, "rb").read() if os.path.exists(path) else b""


ok(any("Seattle Computer Products 8086 Assembler Version 2.44" in l
       for l in lines),
   "ASM.COM started and printed its banner")
ok(any(l.startswith("Error Count =") and l.split("=")[1].strip() == "0"
       for l in lines),
   "it assembled the program with no errors, and said so in one message of "
   "its own: a DM written as a DB runs this line into the two below it")
ok(any("Symbol Table size =" in l for l in lines),
   "and printed the symbol table size, which is the message after it")
ok(any("Hello from SCP ASM 2.44" in l for l in ran),
   "HEX2BIN turned the hex into a .COM and the program ran and printed: the "
   "whole toolchain, end to end")
ok(any("***** ERROR:  Undefined label" in l for l in bad),
   "the source with an undefined label got that message, whole and alone")
ok(any(l.startswith("Error Count =") and l.split("=")[1].strip() == "1"
       for l in bad),
   "and one error counted for it")

# The hex file, decoded: 26 data bytes per record, which is the record
# length HEXBUFSIZ is sized for.
hexfile = read(sys.argv[4]).decode("ascii", "replace")
records, data, where = 0, b"", None
for line in hexfile.split("\n"):
    line = line.strip().rstrip("\x1a")
    if not line.startswith(":"):
        continue
    raw = bytes.fromhex(line[1:])
    if raw[0] == 0:
        break
    if where is None:
        where = int.from_bytes(raw[1:3], "big")
    records += 1
    data += raw[4:4 + raw[0]]
ok(records == 2 and where == 0x100,
   "the hex file holds the program in two records, the first at 0100H: "
   "ASM writes 26 bytes to a record",
   "the hex file holds %d records, the first at %s" % (records, where))
ok(":0000000000" in hexfile,
   "and ends with the Intel hex end record")

made, want = read(sys.argv[5]), read(sys.argv[6])
ok(data == want,
   "and what the records hold is the program itself")
ok(made == want,
   "and the %d bytes ASM.COM assembled are the bytes fasm assembles of the "
   "same program, which is the one check here the screen is not in"
   % len(want),
   "ASM.COM wrote %d bytes, fasm %d: %s vs %s"
   % (len(made), len(want), made[:16].hex(), want[:16].hex()))
sys.exit(rc)
PY
