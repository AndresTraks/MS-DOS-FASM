#!/bin/sh
# Run ASSIGN.COM on the system this builds, and see what it leaves behind.
#
# ASSIGN routes one drive's work to another: it hooks interrupt 21H with a
# handler that maps the drive letter in whatever call is being made and hands
# the call on, and it keeps the whole of itself resident.  The map is the
# table of drive numbers at the head of the image -- 1 for A, 2 for B and so
# on -- and an assignment is one byte of it.
#
# So the test asks four things of it.  That it says what it has been told,
# which it can only do by reading the resident copy's table; that the
# machine lives with the handler on interrupt 21H, which the VER shows; that
# a directory of the assigned drive is the other drive's, which is the whole
# of what ASSIGN is for; and that it forgets the assignment when asked.
#
# Then the machine's memory is read from outside: the four vectors ASSIGN
# hooks must point into the one segment, the bytes there must be the bytes of
# the file, and the one byte that differs must be the drive it was told to
# map.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/assign.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/ASSIGN.COM ::ASSIGN.COM

# B to A, and not the other way about: this machine has the one drive, so
# sending A's work to B would have DOS asking for a diskette nobody can put
# in and the batch file would stop where it stands.
{
    printf 'ECHO OFF\r\n'
    printf 'ECHO ==NOTHING ASSIGNED== > PRN\r\nASSIGN /STATUS > PRN\r\n'
    printf 'ECHO ==B TO A== > PRN\r\nASSIGN B=A > PRN\r\n'
    printf 'ASSIGN /STATUS > PRN\r\n'
    printf 'DIR B:IO.SYS > PRN\r\n'
    printf 'VER > PRN\r\n'
    printf 'ECHO ==FORGET IT== > PRN\r\nASSIGN > PRN\r\n'
    printf 'ASSIGN /STATUS > PRN\r\n'
    printf 'ECHO ==THAT IS ALL== > PRN\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    awaitprint "$OUT/prn.txt" "==THAT IS ALL=="
    rm -f "$OUT/mem.bin"
    echo "pmemsave 0 0x100000 \"$OUT/mem.bin\""
    n=0
    while [ "$(if [ -f "$OUT/mem.bin" ]; then wc -c < "$OUT/mem.bin"; else echo 0; fi)" -ne 1048576 ] && [ $n -lt 200 ]; do
        n=$((n + 1))
        sleep 0.05
    done
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/prn.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/prn.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }
[ -s "$OUT/mem.bin" ] || { echo "$0: the memory never came back" >&2; exit 1; }

python3 - "$OUT/prn.txt" "$OUT/mem.bin" bin/ASSIGN.COM <<'PY' || exit 1
import sys

text = open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
mem = open(sys.argv[2], "rb").read()
com = open(sys.argv[3], "rb").read()

print("--- what it said")
for line in text.split("\n"):
    if line.strip():
        print("   %s" % line.rstrip())

rc = 0
print("--- checks")

# The two /STATUS runs with nothing assigned print nothing at all, which is
# what the release's prolog says they do: between the markers there is the
# marker's own newline and no more.
parts = text.split("==")
empty = [p for p in ("NOTHING ASSIGNED", "FORGET IT") if
         parts[parts.index(p) + 1].strip() == ""]
for p in empty:
    print("ok      %-40s %s"
          % ("/STATUS after " + p.lower(),
             "says nothing, there being nothing to say"))
for p in ("NOTHING ASSIGNED", "FORGET IT"):
    if p not in empty:
        print("MISSING the silence after %s" % p)
        rc = 1

want = [("Original B: set to A:",
         "ASSIGN B=A, read back from the resident copy's table"),
        ("Directory of  B:\\",
         "a directory of B: is taken"),
        ("IO       SYS",
         "and what it lists is the file on A:"),
        ("MS-DOS Version 4.00",
         "the machine lives with ASSIGN's handler on interrupt 21H"),
        ]
for line, why in want:
    if line in text:
        print("ok      %-40s %s" % (line, why))
    else:
        print("MISSING %s" % line)
        rc = 1


def vector(n):
    at = n * 4
    return (mem[at] | (mem[at + 1] << 8),
            mem[at + 2] | (mem[at + 3] << 8))


# The handler is left on interrupt 21H, the two absolute disk calls and the
# multiplex; all four are in the one segment, ASSIGN having kept the whole of
# itself.
segs = {n: vector(n)[1] for n in (0x21, 0x25, 0x26, 0x2F)}
here = segs[0x21]
if here and len(set(segs.values())) == 1:
    print("ok      %-40s %s"
          % ("interrupts 21H, 25H, 26H and 2FH",
             "all four are in ASSIGN's own segment, at %s"
             % ", ".join("%04X" % vector(n)[0]
                         for n in (0x21, 0x25, 0x26, 0x2F))))
else:
    print("WRONG   the vectors are in %s"
          % " ".join("%02X:%04X" % (n, s) for n, s in segs.items()))
    rc = 1

# The head of the image against the file it was loaded from: the jump DOS
# enters by and the twenty-six drive numbers the handler maps a letter
# through, which the last ASSIGN has put back the way the file has them.
# What follows them is the handler's own working storage and is filled in.
at = here * 16 + 0x100
there = mem[at:at + 29]
if there == com[:29]:
    print("ok      %-40s %s"
          % ("the table of drives in the resident copy",
             "is the file's again, so ASSIGN with nothing after it reached "
             "the copy and forgot the assignment"))
else:
    print("WRONG   the resident table is not the file's")
    print("        memory: %s" % there.hex())
    print("        file:   %s" % com[:29].hex())
    rc = 1
sys.exit(rc)
PY
