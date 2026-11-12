#!/bin/sh
# Run NLSFUNC.EXE on the system this builds, and see what it leaves behind.
#
# NLSFUNC is the national-language support the kernel has not got room for:
# it hooks the multiplex interrupt on function 14H and answers DOS's requests
# for country information and code pages out of COUNTRY.SYS, and it keeps the
# part of itself that does that resident.  It is the second resident program
# here after GRAFTABL and MODE, and the first .EXE among them -- its data
# segment and its code segment are two address spaces, and what stays behind
# is both of them.
#
# The first machine installs it with nothing after the name, which is how
# CONFIG.SYS's country file is taken, and then asks four things of it:
#
#   NLSFUNC              installs, says nothing, and leaves no error code
#   CHCP                 the code page COMMAND.COM reports, which says the
#                          machine's national-language state is still whole
#   NLSFUNC              finds the first run through its own interrupt 2FH
#                          handler and says so, with error code 80
#   NLSFUNC BOGUS.SYS    a file that is not there, error code 2
#
# Then the machine's memory is read from outside: interrupt 2FH must point at
# the handler, six bytes into the code segment, the bytes there must be the
# bytes of the file, and the data segment must be resident with it -- the
# handler puts DS back on it at every call, so the block DOS kept has to hold
# both.
#
# The second machine installs it with a path after the name and reads the
# memory again, for the path the parser built where the resident part looks
# for it.  The file named is COMMAND.COM: NLSFUNC only asks whether the file
# is there when it installs, and opens it when DOS first wants country
# information, so naming a file that is certainly on the disk tests the parse
# and the check without standing a made-up COUNTRY.SYS in for the real one,
# which this release builds from src/DEV/COUNTRY and which is not converted.
#
# NLSFUNC writes its own messages on standard error, which a batch file
# cannot redirect, so those are read off the screen and the rest off the
# printer.
#
# "File not fou - BOGUS.SYSnd" is what the release prints, not a conversion
# fault: the retriever's " - %0" trailer backs up two characters over the
# CR,LF a utility-class message ends with, and message 3 of NLSFUNC's own
# class is the extended-error text "File not found", which has none.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/nlsfunc.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/NLSFUNC.EXE ::NLSFUNC.EXE

{
    printf 'ECHO OFF\r\n'
    printf 'NLSFUNC\r\n'
    printf 'IF ERRORLEVEL 1 ECHO THE FIRST RUN GAVE AN ERROR CODE > PRN\r\n'
    printf 'CHCP > PRN\r\n'
    printf 'NLSFUNC\r\n'
    printf 'IF ERRORLEVEL 80 ECHO THE SECOND RUN GAVE 80 > PRN\r\n'
    printf 'NLSFUNC BOGUS.SYS\r\n'
    printf 'IF ERRORLEVEL 2 ECHO THE MISSING FILE GAVE 2 > PRN\r\n'
    printf 'VER > PRN\r\n'
    printf 'ECHO THAT IS ALL > PRN\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    awaitprint "$OUT/prn.txt" "THAT IS ALL"
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

[ -s "$OUT/prn.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }
[ -s "$OUT/mem.bin" ] || { echo "$0: the memory never came back" >&2; exit 1; }

# The path after the name, on a disk of its own, so that this install is the
# first one the machine has seen.
IMG2="$OUT/b.img"
./create_image.sh "$IMG2" >/dev/null
mcopy -o -i "$IMG2" bin/NLSFUNC.EXE ::NLSFUNC.EXE
printf 'ECHO OFF\r\nNLSFUNC \\COMMAND.COM\r\nIF ERRORLEVEL 1 ECHO THE PATH WAS REFUSED > PRN\r\nECHO THAT IS ALL > PRN\r\n' \
    > "$OUT/AUTOEXEC2.BAT"
mcopy -o -i "$IMG2" "$OUT/AUTOEXEC2.BAT" ::AUTOEXEC.BAT

{
    awaitprint "$OUT/path.txt" "THAT IS ALL"
    rm -f "$OUT/mem2.bin"
    echo "pmemsave 0 0x100000 \"$OUT/mem2.bin\""
    n=0
    while [ "$(if [ -f "$OUT/mem2.bin" ]; then wc -c < "$OUT/mem2.bin"; else echo 0; fi)" -ne 1048576 ] && [ $n -lt 200 ]; do
        n=$((n + 1))
        sleep 0.05
    done
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG2",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/path.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/mem2.bin" ] || { echo "$0: the second machine's memory never came back" >&2; exit 1; }

python3 - "$OUT/prn.txt" "$OUT/screen.bin" "$OUT/mem.bin" \
         "$OUT/path.txt" "$OUT/mem2.bin" bin/NLSFUNC.EXE <<'PY' || exit 1
import struct
import subprocess
import sys

said = open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
screen = subprocess.run([sys.executable, "tests/screen.py", sys.argv[2]],
                        capture_output=True, text=True).stdout
mem = open(sys.argv[3], "rb").read()
path_said = open(sys.argv[4], "rb").read().decode("cp437").replace("\r", "")
mem2 = open(sys.argv[5], "rb").read()
exe = open(sys.argv[6], "rb").read()

print("--- what it said")
for line in (said + screen).split("\n"):
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


ok("THE FIRST RUN GAVE AN ERROR CODE" not in said,
   "the install said nothing and left no error code behind",
   "the first run gave an error code")
ok("Active code page: 437" in said,
   "CHCP still reports the code page, so the machine's national-language "
   "state came through the install whole")
ok("NLSFUNC already installed" in screen,
   "the second run found the first, which it can only do by asking the "
   "resident copy through interrupt 2FH")
ok("THE SECOND RUN GAVE 80" in said,
   "and gave the error code 80 the release's own message block sets")
# The release's own garbling, which the prolog above explains.
ok("File not fou - BOGUS.SYSnd" in screen,
   "a file that is not there is reported with the path the parser built, "
   "two characters out of place as the release puts it")
ok("THE MISSING FILE GAVE 2" in said, "with error code 2")
ok("MS-DOS Version 4.00" in said,
   "and the machine lived through the handler being left resident")

# NLS_DATA is the first segment of the file and NLS_INIT_CODE the second, so
# the paragraphs between the start of the load module and the entry point's
# segment are the data segment's, and the handler stands six bytes into the
# code segment -- after the far pointer it chains through and the word it
# keeps the function in.
hdr = struct.unpack_from("<H", exe, 8)[0] * 16
datapara = struct.unpack_from("<H", exe, 22)[0]
code = exe[hdr + datapara * 16:]


def vector(image, n):
    off, seg = struct.unpack_from("<HH", image, n * 4)
    return seg, off


seg, off = vector(mem, 0x2F)
ok(off == 6, "interrupt 2FH points six bytes into the code segment, at the "
             "handler", "interrupt 2FH points at %04X:%04X, not an offset "
             "of 6" % (seg, off))
there = seg * 16 + off
# Every word the loader fixed up, which is a segment and not what the file
# holds: the handler's own "MOV AX,NLS_DATA" is one of them, so the bytes are
# held against the file's with those two left out and then read as the
# segment they should have become.
nrel, relo = struct.unpack_from("<H", exe, 6)[0], \
    struct.unpack_from("<H", exe, 24)[0]
fixed = []
for i in range(nrel):
    roff, rseg = struct.unpack_from("<HH", exe, relo + 4 * i)
    where = rseg * 16 + roff - datapara * 16
    if 6 <= where < 6 + 64:
        fixed.append(where)
window = [i for i in range(6, 6 + 64)
          if i not in fixed and i - 1 not in fixed]
ok(all(mem[there + i - 6] == code[i] for i in window),
   "and the 64 bytes there are the handler out of the file, but for the "
   "%d word the loader fixed up" % len(fixed),
   "the bytes at %04X:%04X are not the file's: %s against %s"
   % (seg, off, mem[there:there + 16].hex(), code[6:22].hex()))
ok(fixed and all(struct.unpack_from("<H", mem, there + w - 6)[0]
                 == seg - datapara for w in fixed),
   "and the word among them is the data segment the handler puts DS back on",
   "the fixed-up words are not the data segment")

# The data segment is datapara paragraphs below the code segment, and the
# handler reaches it at every call, so DOS must have kept it too.
data = (seg - datapara) * 16
ok(mem[data:data + 8] == b"NLSFUNC\0",
   "the data segment is resident below the handler, with the utility's own "
   "name where the message block's sublist points at it",
   "the data segment at %04X holds %r" % (seg - datapara, mem[data:data + 8]))

# The second machine: the path the parser built, where the resident part
# opens the country file from.
ok("THE PATH WAS REFUSED" not in path_said,
   "a path after the name is taken, and the file behind it found")
seg2, off2 = vector(mem2, 0x2F)
data2 = (seg2 - datapara) * 16
ok(b"\\COMMAND.COM\0" in mem2[data2:data2 + datapara * 16],
   "and the path is left in the resident data segment for it, built by the "
   "parser out of the command line",
   "the path is not in the resident data segment")
sys.exit(rc)
PY
