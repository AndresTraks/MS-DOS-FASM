#!/bin/sh
# Run EXE2BIN.EXE on the system this builds, and see what it makes of a .EXE.
#
# EXE2BIN is the step the release's own build ran over a linked .EXE to turn
# it into a .COM: it reads the header, works out how long the image is from
# the page count and the length of the last page, and writes the image out
# without it.  A program whose header says CS:IP is 0000:0100 is a .COM, so
# the first 100H bytes of the image -- the space the PSP takes at run time --
# are dropped as well, and nothing else is changed; a file that needs its
# segments fixed up cannot become a .COM and EXE2BIN says so instead.
#
# So the .EXE given here is one of those: no relocations, CS:IP = 0000:0100,
# and an image of 100H zero bytes followed by 38 bytes of program.  It is
# written out below byte by byte rather than assembled, so that the 38 bytes
# EXE2BIN should write are known here exactly and the file it wrote can be
# held against them.  The program prints a line and exits, which is how the
# machine shows the .COM is a working one.
#
# The second run names a file that is not there, which is the way out through
# the message retriever: the error is one of DOS's extended error messages and
# not text of EXE2BIN's own, and the name of the file is put in it from a
# sublist.  The name is what this looks for, because the text in front of it
# is lost: E2BINIT.ASM asks "have I fetched the DBCS vectors yet" of
# DBCS_VECTOR, which E2BEQU.INC makes an equate of the value NO, so the
# answer is kept at offset 0 of the data segment -- over the first of the
# retriever's class addresses.  The release is written that way and this is
# the conversion of it; the comment at dbcs_check says the same.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/exe2bin.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

# A disk of this test's own: the file EXE2BIN writes is read back here after
# the machine has written it, so nothing else may lay a fresh one down under
# it.
IMG="$OUT/disk.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/EXE2BIN.EXE ::EXE2BIN.EXE

python3 - "$OUT" <<'PY'
import os, struct, sys

out = sys.argv[1]
# The program, as it will stand in the .COM: print the line at 109H and exit.
# DX is the offset the line has once the file is loaded at 100H.
code = bytes([0xBA, 0x09, 0x01,         # mov  dx,109h
              0xB4, 0x09,               # mov  ah,9     (print string)
              0xCD, 0x21,               # int  21h
              0xCD, 0x20])              # int  20h      (exit)
text = b"EXE2BIN MADE THIS COM FILE\r\n$"
want = code + text
open(os.path.join(out, "want.bin"), "wb").write(want)

# The image is what the loader would put at the start of the segment: 100H
# bytes for the PSP and the program after them.
image = bytes(0x100) + want
header = 512                            # 20H paragraphs, which is a header
pages = -(-(header + len(image)) // 512)  # rounded up
last = (header + len(image)) % 512
mz = struct.pack("<2sHHHHHHHHHHHH", b"MZ",
                 last, pages,
                 0,                     # no relocations to fix up
                 header // 16,
                 0, 0xFFFF,             # least and most memory wanted
                 0, 0,                  # SS:SP
                 0,                     # checksum
                 0x0100, 0x0000,        # IP and CS: a .COM
                 0x001C)                # where the relocations would start
open(os.path.join(out, "HELLO.EXE"), "wb").write(
    mz + bytes(header - len(mz)) + image)
PY

mcopy -o -i "$IMG" "$OUT/HELLO.EXE" ::HELLO.EXE

printf 'ECHO OFF\r\nEXE2BIN HELLO.EXE OURS.COM\r\nOURS\r\nEXE2BIN NOSUCH.EXE X.COM\r\nECHO done\r\n' \
    > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    awaitprompt
    cp "$SHOT" "$OUT/screen.bin"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

# The file EXE2BIN wrote, read without the machine's help.
mcopy -n -i "$IMG" ::OURS.COM "$OUT/OURS.COM" 2>/dev/null || true

python3 - "$OUT/screen.bin" "$OUT/want.bin" "$OUT/OURS.COM" <<'PY' || exit 1
import os, sys

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
if "EXE2BIN MADE THIS COM FILE" in screen:
    print("ok      the .COM EXE2BIN wrote was run by COMMAND.COM and printed "
          "its line")
else:
    print("MISSING the line the converted program prints")
    rc = 1

if " - NOSUCH.EXE" in screen:
    print("ok      the second run named a file that is not there, and the "
          "name came back in the error from the retriever's sublist, after "
          "the \" - \" the retriever puts in front of a %0")
else:
    print("MISSING the name of the file in the error message")
    rc = 1

want = open(sys.argv[2], "rb").read()
if os.path.exists(sys.argv[3]):
    got = open(sys.argv[3], "rb").read()
    if got == want:
        print("ok      the %d bytes on the disk are the image without its "
              "header and without the 100H before the program" % len(want))
    else:
        print("WRONG   %d bytes written, wanted %d: %r" %
              (len(got), len(want), got[:16]))
        rc = 1
else:
    print("MISSING OURS.COM: EXE2BIN wrote nothing")
    rc = 1

last = [r for r in rows if r.strip()][-1]
if last.startswith("A>"):
    print("ok      the prompt is back: EXE2BIN ended and COMMAND.COM has it "
          "again")
else:
    print("MISSING the prompt; the last line is %r" % last)
    rc = 1
sys.exit(rc)
PY
