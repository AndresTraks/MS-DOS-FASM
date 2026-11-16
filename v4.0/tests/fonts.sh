#!/bin/sh
# Read EGA.CPI and LCD.CPI as DISPLAY.SYS reads them, and then prepare a code
# page out of EGA.CPI and select it.
#
# A .CPI is the file the screen's fonts come out of, and it is the last thing
# in this release built from assembler alone: seven modules apiece, all data.
# CPI-HEAD (FONT-R3 for the LCD) is the file's tag and the pointer to the
# table of entries, five modules are a code page each, and COPYRIGH is the
# notice and the 1AH that ends the file.  A code page's header points at the
# next one with the end of its own module, so the chain is built out of each
# module's last address -- which is what this walks.
#
# Then the machine:
#
#   DEVICE=\DISPLAY.SYS CON=(EGA,437,2)   the code page driver, two to prepare
#   MODE CON CP PREP=((850) A:\EGA.CPI)   read 850's fonts out of the file
#   MODE CON CP SEL=850                   and put the screen on them
#   MODE CON CP                           which it then says it is on
#   KEYB GR,,A:\KEYBOARD.SYS              and the keyboard follows it
#
# That last line is the point of the whole chain.  With no code page prepared
# KEYB says "Active code page not available from CON device" and falls back
# on 437; with 850 selected it says nothing, having found the code page and
# the 850 section of the German layout to go with it.  Nothing in this
# project could reach any of that until there was a .CPI to read.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/fonts.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
for f in DISPLAY.SYS MODE.COM KEYB.COM EGA.CPI KEYBOARD.SYS; do
    mcopy -o -i "$IMG" "bin/$f" "::$f"
done

printf 'DEVICE=\\DISPLAY.SYS CON=(EGA,437,2)\r\n' > "$OUT/CONFIG.SYS"
mcopy -o -i "$IMG" "$OUT/CONFIG.SYS" ::CONFIG.SYS

{
    printf 'ECHO OFF\r\n'
    printf 'MODE CON CP PREP=((850) A:\\EGA.CPI)\r\n'
    printf 'MODE CON CP SEL=850\r\n'
    printf 'MODE CON CP\r\n'
    printf 'KEYB GR,,A:\\KEYBOARD.SYS\r\n'
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


def pages(path, device, fonts):
    """The code pages a .CPI holds, walked as DISPLAY.SYS walks it: the tag,
    the one pointer in the header, the count of entries, and then each
    entry's own pointer to the next.  Returns the trouble found, if any, and
    what was read."""
    d = open(path, "rb").read()
    word = lambda at: struct.unpack("<H", d[at:at + 2])[0]
    long = lambda at: struct.unpack("<I", d[at:at + 4])[0]
    bad, found = [], []
    if d[0:8] != b"\xffFONT   ":
        bad.append("the tag is %r" % d[0:8])
        return bad, found
    if d[8:16] != bytes(8):
        bad.append("the eight reserved bytes are %r" % d[8:16])
    if (word(16), d[18]) != (1, 1):
        bad.append("the header says %d pointers of type %d"
                   % (word(16), d[18]))
    info = long(19)
    at = info + 2
    for i in range(word(info)):
        nxt, dev, sub, cp = long(at + 2), word(at + 6), d[at + 8:at + 16], \
            word(at + 16)
        box, p = [], long(at + 24) + 6
        nf = word(long(at + 24) + 2)
        for j in range(nf):
            box.append("%dx%d" % (d[p + 1], d[p]))
            if word(p + 4) != 256:
                bad.append("code page %d's font %d has %d characters"
                           % (cp, j, word(p + 4)))
            p += 6 + 256 * d[p]
        found.append((cp, sub.rstrip(b" ").decode("latin-1"), box))
        if dev != 1:
            bad.append("code page %d says device type %d" % (cp, dev))
        if box != fonts:
            bad.append("code page %d has fonts %s" % (cp, " ".join(box)))
        # Every entry but the last points at the end of its own module,
        # which is where the next begins; the LCD's last says -1 and the
        # EGA's points past itself at the notice.
        if i + 1 < word(info) and nxt != p:
            bad.append("code page %d's next pointer is %#x, its data ends "
                       "at %#x" % (cp, nxt, p))
        if i + 1 < word(info):
            at = nxt
    if d[-1] != 0x1A:
        bad.append("the last byte is %#x" % d[-1])
    if b"Microsoft MS-DOS (R)" not in d[-200:]:
        bad.append("the notice is not at the end of it")
    return bad, found


for name, device, fonts, size in (("EGA.CPI", "EGA", ["8x16", "8x14", "8x8"],
                                   49068),
                                  ("LCD.CPI", "LCD", ["8x8"], 10703)):
    bad, found = pages("bin/%s" % name, device, fonts)
    ok(not bad,
       "%s walks: the tag, one pointer of type 1, and five code pages -- "
       "%s -- each for device type 1 %r with %d font%s of 256 characters, "
       "chained by the end of each module and ended with the notice and a "
       "1AH"
       % (name, ", ".join(str(cp) for cp, _, _ in found), device, len(fonts),
          "" if len(fonts) == 1 else "s"),
       "%s: %s" % (name, "; ".join(bad[:3])))
    ok([cp for cp, _, _ in found] == [437, 850, 860, 863, 865],
       "and the five are 437, 850, 860, 863 and 865, in the order the link "
       "file names the modules",
       "%s holds %s" % (name, [cp for cp, _, _ in found]))
    ok(len(open("bin/%s" % name, "rb").read()) == size,
       "and it is %d bytes, which is what its fonts and headers come to"
       % size,
       "%s is %d bytes, not %d"
       % (name, len(open("bin/%s" % name, "rb").read()), size))

ok("MODE prepare code page function completed" in screen,
   "MODE read code page 850's fonts out of EGA.CPI and prepared them for "
   "the console, which is DISPLAY.SYS's generic IOCTL doing the work")
ok("MODE select code page function completed" in screen,
   "and then selected it, which is what puts the screen on those fonts")
ok("Active code page for device CON is 850" in screen,
   "and MODE says the console is on 850, where the hardware page is 437")
ok("Hardware code pages:" in screen and "code page 437" in screen,
   "with 437 as the hardware page, which is what the DEVICE= line gave it")
ok("Prepared code pages:" in screen and "code page 850" in screen,
   "and 850 prepared in the first of the two slots the DEVICE= line asked "
   "for, the second still empty")
ok("Active code page not available from CON device" not in screen,
   "and KEYB installed the German layout without that complaint, which is "
   "what it says when there is no active code page to ask CON for: it "
   "found 850 and took the 850 section of the layout",
   "KEYB still says the active code page is not available")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt")
sys.exit(rc)
PY
