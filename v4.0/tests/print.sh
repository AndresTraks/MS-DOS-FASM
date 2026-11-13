#!/bin/sh
# Run PRINT.COM on the system this builds, and see that a file queued with it
# comes out of the printer while the machine goes on without it.
#
# PRINT is two programs in one file.  The transient part reads the command
# line, installs the resident part the first time it is run, and after that
# talks to it through the multiplex interrupt; the resident part holds the
# queue of files to print, takes a share of the timer interrupt, and writes
# the files out to the list device a few characters at a time between the
# ticks.  So the test is whether a file handed to PRINT at the prompt turns
# up on the printer by itself, with nothing driving it.
#
#   PRINT /D:PRN      the first run, which installs it on the printer
#   PRINT HELLO.TXT   queues the file and says it is being printed
#   PRINT             says what is in the queue
#
# QEMU writes the parallel port through to a file as the guest writes it, so
# what the resident part sends to PRN while COMMAND.COM is back at the prompt
# is what the test waits for.  HELLO.TXT ends with the marker, so the marker
# arriving is the whole of the file having been printed.
#
# Then the machine's memory is read from outside: the four BIOS interrupts
# PRINT takes over -- 13H, 14H, 15H and 17H -- must all point into the one
# segment it was loaded at, and the bytes at the 17H handler must be the
# bytes of the file, the resident part being the start of the image and
# staying where it was loaded.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/print.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/PRINT.COM ::PRINT.COM

# The file to print.  It ends with the marker the test waits for, so that
# the wait is over the whole of the file having gone out.
{
    printf 'THE FIRST LINE OF THE FILE\r\n'
    printf 'THE SECOND LINE OF THE FILE\r\n'
    printf 'THE THIRD LINE OF THE FILE\r\n'
    printf 'THAT IS ALL\r\n'
} > "$OUT/HELLO.TXT"
mcopy -o -i "$IMG" "$OUT/HELLO.TXT" ::HELLO.TXT

{
    printf 'ECHO OFF\r\n'
    printf 'PRINT /D:PRN\r\n'
    printf 'PRINT HELLO.TXT\r\n'
    printf 'PRINT\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT
# the entries mtools wrote get the tidying create_image.sh gives the rest
python3 dosdir.py "$IMG"

{
    awaitprint "$OUT/prn.txt" "THAT IS ALL"
    awaitprompt
    snap
    cp "$SHOT" "$OUT/screen.bin"
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

[ -s "$OUT/mem.bin" ] || { echo "$0: the memory never came back" >&2; exit 1; }

python3 - "$OUT/prn.txt" "$OUT/screen.bin" "$OUT/mem.bin" bin/PRINT.COM <<'PY' || exit 1
import os
import struct
import subprocess
import sys

printed = (open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
           if os.path.exists(sys.argv[1]) else "")
screen = subprocess.run([sys.executable, "tests/screen.py", sys.argv[2]],
                        capture_output=True, text=True).stdout
mem = open(sys.argv[3], "rb").read()
exe = open(sys.argv[4], "rb").read()

print("--- what it said")
for line in screen.split("\n"):
    if line.strip():
        print("   %s" % line.rstrip())
print("--- what it printed")
for line in printed.split("\n"):
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


ok("Resident part of PRINT installed" in screen,
   "the first run installed the resident part, on the device /D named")
ok("HELLO.TXT is currently being printed" in screen,
   "the second queued the file, and the resident part took it straight up")
ok("THE FIRST LINE OF THE FILE" in printed,
   "the file came out of the printer")
ok("THAT IS ALL" in printed,
   "all of it, down to the last line")
ok(printed.count("THE SECOND LINE OF THE FILE") == 1,
   "once and once only",
   "the second line was printed %d times"
   % printed.count("THE SECOND LINE OF THE FILE"))
ok(screen.rstrip().endswith("A>"),
   "and COMMAND.COM was back at the prompt while it printed, the resident "
   "part working off the timer interrupt")


def vector(n):
    off, seg = struct.unpack_from("<HH", mem, n * 4)
    return seg, off


took = {n: vector(n) for n in (0x13, 0x14, 0x15, 0x17)}
segs = {seg for seg, off in took.values()}
ok(len(segs) == 1,
   "interrupts 13H, 14H, 15H and 17H all point into the one segment PRINT "
   "was loaded at",
   "they point at " + ", ".join("%02X:%04X:%04X" % (n, s, o)
                                for n, (s, o) in sorted(took.items())))

# The handler's own bytes, against the file's.  The resident part is the
# start of the image, and it stays where it was loaded, so an offset in it
# is an offset in the file past the header.  The words the loader fixed up
# are left out.  The handler itself is 40 bytes; what follows it is the
# far pointer to the previous owner of interrupt 14H, which installation
# fills in, so the window stops short of that.
SPAN = 40
seg17, off17 = took[0x17]
hdr = struct.unpack_from("<H", exe, 8)[0] * 16
nrel = struct.unpack_from("<H", exe, 6)[0]
relo = struct.unpack_from("<H", exe, 24)[0]
fixed = []
for i in range(nrel):
    roff, rseg = struct.unpack_from("<HH", exe, relo + 4 * i)
    where = rseg * 16 + roff
    if off17 <= where < off17 + SPAN:
        fixed.append(where)
there = seg17 * 16 + off17
window = [i for i in range(off17, off17 + SPAN)
          if i not in fixed and i - 1 not in fixed]
wrong = [i for i in window if mem[there + i - off17] != exe[hdr + i]]
ok(not wrong,
   "and the %d bytes of the interrupt 17H handler are the bytes of the "
   "file, but for the %d word the loader fixed up" % (SPAN, len(fixed)),
   "the bytes at %04X:%04X are not the file's: %s against %s, first at +%d"
   % (seg17, off17, mem[there:there + SPAN].hex(),
      exe[hdr + off17:hdr + off17 + SPAN].hex(),
      wrong[0] - off17 if wrong else -1))
sys.exit(rc)
PY
