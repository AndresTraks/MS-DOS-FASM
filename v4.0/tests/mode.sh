#!/bin/sh
# Run MODE.COM on the system this builds, and see what it makes of the machine.
#
# MODE is the largest of the utilities, and the one with the most ways in: it
# sets the screen's mode, the printer's line width and retry, a serial port's
# baud rate, parity, data and stop bits, the keyboard's typematic rate, and
# the code page of any of them, and it reroutes a parallel printer to a serial
# port, for which it leaves a resident handler behind on interrupts 14H and
# 17H.  So the test asks for one of each kind and holds what comes back
# against what the release's messages say.
#
# The first machine runs seven commands with their output on the printer:
#
#   MODE                       the status of every device
#   MODE CO80                  colour, 80 columns -- nothing to say
#   MODE MONO                  a monochrome adapter this machine has not got
#   MODE LPT1: COLS=80         the width, which also sends the printer a DC2
#   MODE LPT1: RETRY=NONE      the retry, whose message takes another for its
#                                %1 -- "No" -- through SYSGETMSG
#   MODE COM1: 1200,N,8,1      the serial port, which answers with its state
#   MODE CON: COLS=80 LINES=25 the screen's width and depth, which wants ANSI
#
# The second runs MODE LPT1:=COM1:, which moves the resident part of MODE
# down over its own program prefix and hooks the two interrupts on it, and
# then reads the machine's memory from outside: the far pointer MODE leaves at
# 0:0530 and the two vectors must all point into the block that was moved, and
# the bytes there must be the bytes of the file it was moved from.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/mode.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/MODE.COM ::MODE.COM

{
    printf 'ECHO OFF\r\n'
    printf 'MODE > PRN\r\n'
    printf 'MODE CO80 > PRN\r\n'
    printf 'MODE MONO > PRN\r\n'
    printf 'MODE LPT1: COLS=80 > PRN\r\n'
    printf 'MODE LPT1: RETRY=NONE > PRN\r\n'
    printf 'MODE COM1: 1200,N,8,1 > PRN\r\n'
    printf 'MODE CON: COLS=80 LINES=25 > PRN\r\n'
    printf 'ECHO THAT IS ALL > PRN\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    awaitprint "$OUT/prn.txt" "THAT IS ALL"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/prn.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/prn.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }

# The reroute, on a disk of its own: the machine is left with MODE's handler
# on two interrupts, and what the printer says afterwards goes to the serial
# port instead, so nothing is asked of it after the resident part is in.
IMG2="$OUT/b.img"
./create_image.sh "$IMG2" >/dev/null
mcopy -o -i "$IMG2" bin/MODE.COM ::MODE.COM
printf 'ECHO OFF\r\nMODE LPT1:=COM1: > PRN\r\n' > "$OUT/AUTOEXEC2.BAT"
mcopy -o -i "$IMG2" "$OUT/AUTOEXEC2.BAT" ::AUTOEXEC.BAT

{
    awaitprint "$OUT/res.txt" "Resident portion of MODE loaded"
    rm -f "$OUT/mem.bin"
    echo "pmemsave 0 0x100000 \"$OUT/mem.bin\""
    n=0
    while [ "$(if [ -f "$OUT/mem.bin" ]; then wc -c < "$OUT/mem.bin"; else echo 0; fi)" -ne 1048576 ] && [ $n -lt 200 ]; do
        n=$((n + 1))
        sleep 0.05
    done
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG2",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/res.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/mem.bin" ] || { echo "$0: the memory never came back" >&2; exit 1; }

python3 - "$OUT/prn.txt" "$OUT/res.txt" "$OUT/mem.bin" bin/MODE.COM <<'PY' || exit 1
import sys

said = open(sys.argv[1], "rb").read()
text = said.decode("cp437").replace("\r", "")
resident = open(sys.argv[2], "rb").read().decode("cp437").replace("\r", "")
mem = open(sys.argv[3], "rb").read()
com = open(sys.argv[4], "rb").read()

print("--- what it said")
for line in text.split("\n"):
    if line.strip():
        print("   %s" % line.rstrip())

rc = 0
print("--- checks")
want = [("Status for device LPT1:",
         "MODE with nothing after it gives the status of every device"),
        ("Status for device CON:",
         "the screen among them"),
        ("LPT1: not rerouted",
         "and reads the resident part's flags to say so"),
        ("Function not supported on this computer - MONO",
         "MODE MONO asks for an adapter this machine has not got, and the "
         "name of the parameter comes back in the message"),
        ("LPT1: set for 80",
         "MODE LPT1: COLS=80 sets the width"),
        ("No retry on parallel printer time-out",
         "and RETRY=NONE the retry, whose message takes the word No from "
         "another message through SYSGETMSG"),
        ("COM1: 1200,n,8,1,-",
         "MODE COM1: answers with the state it set the port to"),
        ("ANSI.SYS must be installed to perform requested function",
         "and COLS= with LINES= on the screen wants the driver this system "
         "is started without"),
        ]
for line, why in want:
    if line in text:
        print("ok      %-46s %s" % (line, why))
    else:
        print("MISSING %s" % line)
        rc = 1

# The width is set by sending the printer the character that cancels
# condensed print, which the machine's parallel port passes straight on.
if b"\x12" in said:
    print("ok      %-46s %s"
          % ("the DC2 in the printer's stream",
             "COLS=80 sends the printer the character that cancels "
             "condensed print"))
else:
    print("MISSING the DC2 that COLS=80 sends the printer")
    rc = 1

if "Resident portion of MODE loaded" in resident:
    print("ok      %-46s %s"
          % ("Resident portion of MODE loaded",
             "the reroute leaves MODE's handler behind"))
else:
    print("MISSING the resident part's own message")
    rc = 1


def vector(n):
    at = n * 4
    return (mem[at] | (mem[at + 1] << 8),
            mem[at + 2] | (mem[at + 3] << 8))


# MODE moves the resident part a whole number of paragraphs, so every offset
# in it is the offset it was assembled with: the two handlers are MODETO on
# interrupt 14H and MODEPTS on 17H, and the far pointer at 0:0530 is MODETO
# again, which is how the next MODE finds the part already there.
off14, seg14 = vector(0x14)
off17, seg17 = vector(0x17)
at530 = (mem[0x530] | (mem[0x531] << 8), mem[0x532] | (mem[0x533] << 8))
if seg14 and seg14 == seg17 and seg14 < 0xF000:
    print("ok      %-46s %s"
          % ("interrupts 14H and 17H in one segment",
             "both point into the block that was moved, at %04X:%04X and "
             "%04X:%04X" % (seg14, off14, seg17, off17)))
else:
    print("WRONG   interrupt 14H points at %04X:%04X and 17H at %04X:%04X"
          % (seg14, off14, seg17, off17))
    rc = 1
if at530 == (off14, seg14):
    print("ok      %-46s %s"
          % ("the far pointer at 0:0530",
             "is MODETO as well, which is how the next MODE finds this one"))
else:
    print("WRONG   0:0530 holds %04X:%04X, not %04X:%04X"
          % (at530[1], at530[0], seg14, off14))
    rc = 1

# The bytes of the handler, against the bytes of the file it was moved from:
# the image begins at 100H, where DOS enters a .COM, so MODETO's offset is
# that much further into the segment than into the file.
there = seg14 * 16 + off14
if mem[there:there + 32] == com[off14 - 0x100:off14 - 0x100 + 32]:
    print("ok      %-46s %s"
          % ("the handler's first 32 bytes",
             "are the bytes of MODE.COM at that offset, the move having "
             "kept every offset where it was"))
else:
    print("WRONG   the moved handler is not what the file holds")
    print("        memory: %s" % mem[there:there + 16].hex())
    print("        file:   %s" % com[off14 - 0x100:off14 - 0x100 + 16].hex())
    rc = 1
sys.exit(rc)
PY
