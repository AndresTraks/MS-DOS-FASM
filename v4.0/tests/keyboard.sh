#!/bin/sh
# Read KEYBOARD.SYS as KEYB reads it, and then have KEYB read it.
#
# KEYBOARD.SYS is neither a driver nor a program: it is the file of keyboard
# layouts KEYB builds its translate tables from, and the .SYS on the end of
# it is the release's own naming.  There is not an instruction in the whole
# of it.  So half of this test is the file itself -- walked here the way KEYB
# walks it, which is the only way to see that the twenty modules came out in
# the right order and that the pointers between them still point where they
# did -- and half is KEYB, which is the reader the release wrote.
#
#   KEYB GR,,A:\KEYBOARD.SYS    reads the German layout out of it
#   KEYB                        says which code is current
#   KEYB SV,437,A:\KEYBOARD.SYS switches the resident copy to Swedish
#   KEYB ZZ,,A:\KEYBOARD.SYS    a code the file does not hold
#
# The last of those is what shows the language table was searched rather
# than the file merely opened: KEYB answers "Invalid keyboard code
# specified", which it can only say after reading the table through.
#
# The pointers are the thing to watch.  Each language's state logic and its
# two code page tables live in a module of their own and are named PUBLIC
# there; KDFNOW, which is the file header and the two tables of pointers,
# takes all fifty-four of them with an EXTRN.  Everything else the twenty
# modules declare they keep to themselves -- a hundred and ninety-two names
# are declared in more than one of them -- so the conversion marks each
# module's own names with the module's name, and a name marked that should
# not have been, or not marked that should, moves a pointer.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/keyboard.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/KEYB.COM ::KEYB.COM
mcopy -o -i "$IMG" bin/KEYBOARD.SYS ::KEYBOARD.SYS

{
    printf 'ECHO OFF\r\n'
    printf 'KEYB GR,,A:\\KEYBOARD.SYS\r\n'
    printf 'KEYB\r\n'
    printf 'KEYB SV,437,A:\\KEYBOARD.SYS\r\n'
    printf 'KEYB\r\n'
    printf 'KEYB ZZ,,A:\\KEYBOARD.SYS\r\n'
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
} | "$QEMU" -rtc base=localtime -boot order=a \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

python3 - "$OUT/screen.bin" <<'PY' || exit 1
import struct
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


f = open("bin/KEYBOARD.SYS", "rb").read()
word = lambda at: struct.unpack("<H", f[at:at + 2])[0]

ok(f[0] == 0xFF and f[1:8] == b"KEYB   ",
   "the file begins with the signature KEYB looks for, 0FFH and KEYB with "
   "four spaces after it, which is the first eight bytes KDFNOW lays down")
ok(f[8:16] == bytes(8),
   "and the eight reserved bytes after it are zero")
maxcom, maxspec, maxlogic = word(16), word(18), word(20)
ok((maxcom, maxspec, maxlogic) == (650, 350, 400),
   "the three maxima are 650, 350 and 400 -- the room KEYB sets aside for "
   "the common section, a specific section and the state logic",
   "the maxima are %d, %d and %d" % (maxcom, maxspec, maxlogic))
nids, nlangs = word(24), word(26)
ok((nids, nlangs) == (19, 17),
   "and there are 19 keyboard IDs and 17 language codes",
   "the counts are %d IDs and %d languages" % (nids, nlangs))
ok(f[-1] == 0x1A,
   "the last byte is the 1AH KDFEOF ends the file with, so every one of the "
   "twenty modules was read and in the order the link file names them")

# The language table, and the entry each code points at.  KEYB finds a
# layout this way: match the two letters, follow the word after them.
at = 28
langs = []
for i in range(nlangs):
    langs.append((f[at:at + 2].decode("latin-1"), word(at + 2)))
    at += 6
codes = [c for c, _ in langs]
ok(codes == ["GR", "SP", "PO", "FR", "DK", "SG", "IT", "UK", "SF", "BE",
             "NL", "NO", "CF", "SV", "SU", "LA", "US"],
   "the seventeen language codes are the ones KDFNOW writes, in its order",
   "the codes are %s" % " ".join(codes))

bad = []
for code, off in langs:
    if not 0 < off < len(f):
        bad.append("%s: the entry is at %#x, outside the file" % (code, off))
        continue
    # A language entry: the two letters again, the keyboard ID, a pointer to
    # the state logic, then a code page and a pointer for each page it has.
    # The US entry is the release's own dummy and calls itself XX.
    name = f[off:off + 2].decode("latin-1")
    logic = word(off + 4)
    pages = [(word(off + 10 + 6 * j), word(off + 12 + 6 * j))
             for j in range(f[off + 9])]
    if name != code and code != "US":
        bad.append("%s: the entry calls itself %r" % (code, name))
    if not 0 < logic < len(f):
        bad.append("%s: the state logic is at %#x" % (code, logic))
        continue
    length = word(logic)
    if not 0 < length <= maxlogic or logic + length > len(f):
        bad.append("%s: the state logic says it is %d bytes long"
                   % (code, length))
    if not pages:
        bad.append("%s: no code page tables" % code)
    for cp, tab in pages:
        if not 0 < tab < len(f):
            bad.append("%s: the table for code page %d is at %#x"
                       % (code, cp, tab))
        elif not 0 < word(tab) <= maxcom or tab + word(tab) > len(f):
            bad.append("%s: the table for code page %d says it is %d bytes"
                       % (code, cp, word(tab)))
        elif word(tab + 2) != cp:
            bad.append("%s: the table for code page %d says it is for %d"
                       % (code, cp, word(tab + 2)))
ok(not bad,
   "and every one of the seventeen walks: the entry names itself, its state "
   "logic is inside the file and no longer than the header allows, and each "
   "of its code page tables is inside the file and says which page it is "
   "for.  Those are the fifty-four names the modules pass between them",
   "the file does not walk: %s" % "; ".join(bad[:4]))

# And what KEYB made of it.
ok("Current keyboard code: GR  code page: 437" in screen,
   "KEYB read the German layout out of the file, built its tables from it "
   "and went resident: asked again, it says GR")
ok("Current keyboard code: SV  code page: 437" in screen,
   "and then the Swedish one, which is a different module of the twenty -- "
   "the resident copy rebuilt its tables from the same file")
ok("Invalid keyboard code specified" in screen,
   "and ZZ is refused, which KEYB can only say after reading the whole of "
   "the language table: the file was searched and not merely opened")
ok("File not found" not in screen and "Invalid" in screen,
   "with no complaint about the file itself")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt")
sys.exit(rc)
PY
