#!/bin/sh
# Translate a Z80 program with TRANS.COM on the system this builds, assemble
# what it wrote with ASM.COM, convert that with HEX2BIN.COM, and run it.
#
# TRANS.COM is the Z80-to-8086 translator Tim Paterson wrote to carry CP/M
# programs over to 86-DOS, and the release ships its source.  It was the last
# file in this tree that had never been converted -- nothing built it, and
# checkscp.py reported it as the release's own text.
#
# All three of the release's tools are in this chain, each one reading what
# the one before it wrote: a Z80 source goes in and a running .COM comes out.
# Every system call TRANS.COM makes goes through the CP/M-compatible call at
# offset 5 of its program base, which is the one entry in the kernel that
# nothing else in the release uses -- and the one that needs the A20 line
# masked, because the long call the kernel writes there is a megabyte above
# the long jump it points at.  IO.ASM closes the gate at INIT; without that
# the first thing TRANS prints is the last thing it does.
#
# What the checks look at is the translation itself, not just that something
# ran: B became CH and BC became CX, DE became DX and C became CL, and DJNZ
# -- which the 8086 has no instruction for -- became a DEC and a JNZ with the
# warning TRANS prints about the flags it does not set the same way.
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

OUT=${TMPDIR:-/tmp}/v125trans.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG=$OUT/trans.img
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" tests/TWICE.Z80 ::TWICE.Z80

# A PAUSE after the translation and after the listing, so that each screen
# the test reads is one that has stopped moving.
{
    printf 'TRANS TWICE.Z80\r\n'
    printf 'PAUSE\r\n'
    printf 'TYPE TWICE.ASM\r\n'
    printf 'PAUSE\r\n'
    printf 'ASM TWICE.AAZ\r\n'
    printf 'HEX2BIN TWICE\r\n'
    printf 'TWICE\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    await "Translation complete"
    cp "$SHOT" "$OUT/trans.bin"
    echo "sendkey ret"
    await "JNZ"
    cp "$SHOT" "$OUT/listing.bin"
    echo "sendkey ret"
    await "Error Count"
    cp "$SHOT" "$OUT/asm.bin"
    await "FROM THE Z80" 2
    cp "$SHOT" "$OUT/ran.bin"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true
for what in trans listing asm ran; do
    [ -s "$OUT/$what.bin" ] \
        || { echo "$0: the screen never came back from $what" >&2; exit 1; }
done

mcopy -o -i "$IMG" ::TWICE.ASM "$OUT/TWICE.ASM" 2>/dev/null || true
mcopy -o -i "$IMG" ::TWICE.COM "$OUT/TWICE.COM" 2>/dev/null || true

# The same program as fasm assembles it, to hold the bytes against: this is
# what the translation came to, written out in fasm's own spelling.
cat > "$OUT/want.asm" <<'WANT'
use16
org 100h
	mov	ch,2
AGAIN:	push	cx
	mov	dx,MSG
	mov	cl,9
	call	5
	pop	cx
	dec	ch
	jnz	AGAIN
	ret
MSG:	db	'TWICE,FROM THE Z80',13,10,'$'
WANT
$FASM "$OUT/want.asm" "$OUT/want.bin" >/dev/null

python3 - "$OUT/trans.bin" "$OUT/listing.bin" "$OUT/asm.bin" "$OUT/ran.bin" \
         "$OUT/TWICE.ASM" "$OUT/TWICE.COM" "$OUT/want.bin" <<'PY' || exit 1
import os
import subprocess
import sys


def screen(path):
    text = subprocess.run([sys.executable, "tests/screen.py", path],
                          capture_output=True, text=True).stdout
    return [l.rstrip() for l in text.split("\n") if l.strip()]


trans, listing, asm, ran = (screen(p) for p in sys.argv[1:5])
for title, shot in (("the translation", trans), ("what it wrote", listing),
                    ("the assembly", asm), ("the program", ran)):
    print("--- the screen at %s" % title)
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


def read(path):
    return open(path, "rb").read() if os.path.exists(path) else b""


ok(any("Z80 to 8086 Translator  version 2.21" in l for l in trans),
   "TRANS.COM started and printed its banner, which is its first message "
   "through the CP/M call at 5 -- the entry the A20 line decides")
ok(any("Translation complete" in l for l in trans),
   "and read the Z80 source to the end")

# The translation, off the disk rather than off the screen.  What it is
# spaced with is the translator's business, so the lines are read with their
# white space squeezed out.
wrote = " ".join(read(sys.argv[5]).decode("cp437", "replace").upper().split())
for z80, x86, why in (
        ("LD B,2", "MOV CH,2", "B is CH"),
        ("PUSH BC", "PUSH CX", "BC is CX"),
        ("LD DE,MSG", "MOV DX,MSG", "DE is DX"),
        ("LD C,9", "MOV CL,9", "C is CL"),
        ("POP BC", "POP CX", "BC is CX on the way back")):
    ok(x86 in wrote, "%s became %s: %s" % (z80, x86, why),
       "%s did not become %s" % (z80, x86))
ok("DEC CH" in wrote and "JNZ AGAIN" in wrote,
   "DJNZ AGAIN became DEC CH and JNZ AGAIN, the 8086 having no instruction "
   "that does both")
ok("DJNZ DOES NOT AFFECT FLAGS" in wrote,
   "and TRANS left the warning it prints for that one: DEC sets flags DJNZ "
   "does not")
ok(any(l.startswith("Error Count =") and l.split("=")[1].strip() == "0"
       for l in asm),
   "ASM.COM assembled what the translator wrote, with no errors")
ok(sum(1 for l in ran if "FROM THE Z80" in l) >= 2,
   "and the program ran and printed twice, so the loop the DJNZ became "
   "counted down through the CP/M call and back")

made, want = read(sys.argv[6]), read(sys.argv[7])
ok(made == want,
   "and the %d bytes that came out of the three of them are the bytes fasm "
   "assembles of the same program" % len(want),
   "the chain wrote %d bytes, fasm %d: %s vs %s"
   % (len(made), len(want), made[:20].hex(), want[:20].hex()))
sys.exit(rc)
PY
