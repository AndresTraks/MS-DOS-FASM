#!/bin/sh
# Read KEYBOARD.SYS as KEYB reads it, give it to KEYB, and then type on it.
#
# KEYBOARD.SYS is neither a driver nor a program: it is the file of keyboard
# layouts KEYB builds its translate tables from, and the .SYS on the end of
# it is the release's own naming.  There is not an instruction in the whole
# of it.  So this test has three parts: the file, walked here the way KEYB
# walks it; KEYB, which is the reader the release wrote; and a key pressed,
# which is the only thing that shows the tables mean what they say.
#
#   KEYB GR,,A:\KEYBOARD.SYS    reads the German layout out of it
#   KEYB                        says which code is current
#   KEYB SV,437,A:\KEYBOARD.SYS switches the resident copy to Swedish
#   KEYB ZZ,,A:\KEYBOARD.SYS    a code the file does not hold
#
# and then, on a machine of its own with the German layout resident, the five
# keys a German keyboard moves: the two the US layout calls y and z, which
# are swapped, and the three to the right of L and P, which are o, u and a
# with a diaresis.  Nothing short of that shows the layout is right -- the
# state logic can be half of what the release wrote and KEYB will still
# install it and report the code.  Which is what happened: the IFF and ANDF
# commands laid down nothing until INC/POSTEQU.INC's flag masks were written
# with = rather than EQU, because fasm substitutes an EQU on a macro's call
# line and KEYBMAC's FIND_FLAG compares the name.  The German state logic was
# 246 bytes where it should be 360, and the whole file 20809 where it should
# be 23119 -- and every check short of a keystroke passed.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/keyboard.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

# One machine per run, each on a disk of its own.  AFTER is what to send once
# the batch file has run out: the keys, for the second.
boot() {
    name=$1
    img="$OUT/$name.img"
    ./create_image.sh "$img" >/dev/null
    mcopy -o -i "$img" bin/KEYB.COM ::KEYB.COM
    mcopy -o -i "$img" bin/KEYBOARD.SYS ::KEYBOARD.SYS
    mcopy -o -i "$img" "$OUT/$name.bat" ::AUTOEXEC.BAT
    # the entries mtools wrote get the tidying create_image.sh gives the rest
    python3 dosdir.py "$img"
    {
        await "THAT IS ALL" 1
        awaitprompt
        for k in $AFTER; do
            echo "sendkey $k"
            sleep 0.3
        done
        [ -n "$AFTER" ] && sleep 1
        snap
        cp "$SHOT" "$OUT/$name.bin"
        echo quit
    } | "$QEMU" -rtc base=localtime -boot order=a \
                -drive file="$img",format=raw,if=floppy,index=0 \
                -display none -monitor stdio >/dev/null 2>&1 || true
    [ -s "$OUT/$name.bin" ] \
        || { echo "$0: the screen never came back from $name" >&2; exit 1; }
}

{
    printf 'ECHO OFF\r\n'
    printf 'KEYB GR,,A:\\KEYBOARD.SYS\r\n'
    printf 'KEYB\r\n'
    printf 'KEYB SV,437,A:\\KEYBOARD.SYS\r\n'
    printf 'KEYB\r\n'
    printf 'KEYB ZZ,,A:\\KEYBOARD.SYS\r\n'
    printf 'ECHO THAT IS ALL\r\n'
} > "$OUT/reports.bat"
AFTER= boot reports

{
    printf 'ECHO OFF\r\n'
    printf 'KEYB GR,,A:\\KEYBOARD.SYS\r\n'
    printf 'ECHO THAT IS ALL\r\n'
} > "$OUT/typed.bat"
AFTER='y z semicolon bracket_left apostrophe' boot typed

python3 - "$OUT/reports.bin" "$OUT/typed.bin" <<'PY' || exit 1
import struct
import subprocess
import sys


def text(path):
    return subprocess.run([sys.executable, "tests/screen.py", path],
                          capture_output=True, text=True).stdout


def rows(path):
    """The screen's own bytes, a row at a time: screen.py writes a space for
    anything outside ASCII, and the characters a German layout gives are all
    outside it."""
    d = open(path, "rb").read()
    return [bytes(d[(r * 80 + c) * 2] for c in range(80)).rstrip(b" \0")
            for r in range(25)]


reports, typed = text(sys.argv[1]), text(sys.argv[2])

print("--- what it said")
for line in reports.split("\n"):
    if line.strip():
        print("   %s" % line.rstrip())
print("--- and what was typed on it")
for line in rows(sys.argv[2]):
    if line.strip():
        print("   %r" % line)

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
ok(f[8:16] == bytes(8), "and the eight reserved bytes after it are zero")
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

# The language table, and the entry each code points at.
at, langs = 28, []
for i in range(nlangs):
    langs.append((f[at:at + 2].decode("latin-1"), word(at + 2)))
    at += 6
codes = [c for c, _ in langs]
ok(codes == ["GR", "SP", "PO", "FR", "DK", "SG", "IT", "UK", "SF", "BE",
             "NL", "NO", "CF", "SV", "SU", "LA", "US"],
   "the seventeen language codes are the ones KDFNOW writes, in its order",
   "the codes are %s" % " ".join(codes))

# What a state logic holds: the commands, whose code is the top nibble of
# each byte and whose length KEYBMAC's macros give.  A logic with no IFF and
# no ANDF in it is the defect this test was written for.
SIZE = {0x0: 2, 0x1: 2, 0x2: 1, 0x3: 1, 0x4: 2, 0x5: 2, 0x6: 2, 0x7: 2,
        0x8: 3, 0x9: 3, 0xA: 1, 0xB: 1, 0xC: 1}


def commands(at):
    end, i, found = at + word(at), at + 4, []
    while i < end:
        code = f[i] >> 4
        if code not in SIZE:
            return None
        found.append(code)
        i += SIZE[code]
    return found if i == end else None


bad, over, counts = [], [], {}
for code, off in langs:
    if not 0 < off < len(f):
        bad.append("%s: the entry is at %#x, outside the file" % (code, off))
        continue
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
    if not 0 < length or logic + length > len(f):
        bad.append("%s: the state logic says it is %d bytes" % (code, length))
        continue
    if length > maxlogic:
        # Three of the release's own are longer than the maximum its own
        # header declares, and KEYB loads them anyway: Portuguese 405,
        # Belgian 419 and Dutch 409 against KDFNOW's 400.  Counted off the
        # macro calls in their sources, those are the lengths the release
        # wrote; the number in the header is simply too small.
        over.append("%s %d" % (code, length))
    cmds = commands(logic)
    if cmds is None:
        bad.append("%s: the state logic does not decode as commands" % code)
    else:
        counts[code] = (cmds.count(0), cmds.count(1), len(cmds))
        # The US entry is the release's dummy -- seven bytes and no
        # conditions in it at all.
        if code != "US" and (not cmds.count(0) or not cmds.count(1)):
            bad.append("%s: %d IFF and %d ANDF commands in its state logic"
                       % (code, cmds.count(0), cmds.count(1)))
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
   "logic decodes command by command and has IFF and ANDF commands in it, "
   "and each of its code page tables is inside the file and says which page "
   "it is for",
   "the file does not walk: %s" % "; ".join(bad[:4]))
if counts:
    print("        (German: %d commands, %d IFF and %d ANDF, which is what "
          "KDFGE's" % (counts["GR"][2], counts["GR"][0], counts["GR"][1]))
    print("        macro calls come to)")
ok(sorted(over) == ["BE 419", "NL 409", "PO 405"],
   "three of them are longer than the 400 bytes the file's own header "
   "declares for a state logic -- Portuguese, Belgian and Dutch -- which is "
   "what the release's own macro calls come to, and KEYB loads all three",
   "the ones over the declared maximum are %s, not BE 419, NL 409, PO 405"
   % (", ".join(sorted(over)) or "none"))

# And what KEYB made of it.
ok("Current keyboard code: GR  code page: 437" in reports,
   "KEYB read the German layout out of the file, built its tables from it "
   "and went resident: asked again, it says GR")
ok("Current keyboard code: SV  code page: 437" in reports,
   "and then the Swedish one, which is a different module of the twenty -- "
   "the resident copy rebuilt its tables from the same file")
ok("Invalid keyboard code specified" in reports,
   "and ZZ is refused, which KEYB can only say after reading the whole of "
   "the language table: the file was searched and not merely opened")

# The five keys.  The prompt line holds what the resident handler put in the
# keyboard buffer, which is what the layout says and not what the BIOS would
# have said: in code page 437, z y and then o, u and a with a diaresis.
line = [r for r in rows(sys.argv[2]) if r.startswith(b"A>")][-1]
ok(line == b"A>zy\x94\x81\x84",
   "and with the German layout resident, the keys the US layout calls "
   "y z ; [ ' come back as z y and o, u, a with a diaresis -- which is what "
   "KDFGE's Alpha Lower Case table says (scan 44 is y, 21 is z, 39 is 094h, "
   "26 is 081h, 40 is 084h), and not what the BIOS would have given",
   "the prompt line reads %r, not %r" % (line, b"A>zy\x94\x81\x84"))
sys.exit(rc)
PY
