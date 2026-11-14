#!/bin/sh
# Run SHARE.EXE on the system this builds, and see that the kernel calls
# into it once it is installed.
#
# SHARE is the one utility that runs inside the kernel.  It installs itself
# by writing fourteen far pointers of its own over JShare, the jump table
# MSCONST.ASM lays down in the kernel's CONSTANTS, by patching the two
# critical sections CONST2's CritPatch names to a PUSH AX, and by setting
# fShare -- after which every open, close and lock the kernel does is a far
# call into the sharer.  That is why the release linked four of the kernel's
# own modules in beside its own: what it reads of the kernel's data it reads
# through SS at the offset its own assembly gives the name, so the copy of
# DOSGROUP in SHARE.EXE has to come out the way the one in MSDOS.SYS does.
# One wrong offset and the sharer writes over the kernel instead of into it.
#
# So the test is a record lock, which is the one call DOS answers only when
# the sharer is there: LOCK.ASM's CheckShare reads fShare and the call
# returns "invalid function" with it at nought.  DEBUG types the call in and
# runs it twice, once before SHARE and once after, and the two register
# dumps come out on the printer:
#
#   DEBUG < LOCK.TXT > PRN    INT 21H AH=5CH on a file: CY and AX=0001
#   SHARE /F:2048 /L:40       installs, with room for 2048 bytes of names
#   SHARE                     says it is there already, through interrupt 2FH
#   DEBUG < LOCK.TXT > PRN    the same lock again: NC, the sharer answering
#   TYPE, COPY, DIR           and the file calls still work, every open and
#                             close of them now a far call into the sharer
#
# What is not here is a switch the parse table does not have, which ought to
# answer "Invalid switch".  SHARE parses its own switches properly -- /F and
# /L above are read, and InitSpace and InitLocks take them where they ask
# for more than the default -- but the message
# for a parse error goes out through the implied substitution in
# INC/MSGSERV.ASM, and that path is broken for every utility, not just this
# one: FASTOPEN /Z answers "Invalid swit -  /Zch", the insert spliced in two
# characters early.  SHARE asks for the substitution where FASTOPEN does
# not, and for SHARE the same defect hangs the machine -- the retriever
# far-calls COMMAND.COM's READ_DISK_PROC and never comes back.  It is older
# than this conversion and wants a fix of its own.
#
# The second DEBUG run is what says the installation took: the lock goes
# through CheckShare, into the sharer's own Set_Block, and comes back with
# the carry clear.  The TYPE and the COPY after it are the kernel calling
# MFT_Enter and MFTClose for each of four opens through the table SHARE
# wrote -- a far call through a segment the loader relocated, which is what
# fourteen of the fifteen fixups in SHARE.EXE's header are for; the
# fifteenth is the sharer's own 2FH address.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/share.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/SHARE.EXE ::SHARE.EXE
mcopy -o -i "$IMG" bin/DEBUG.COM ::DEBUG.COM
printf 'the file the lock is taken on\r\n' > "$OUT/HELLO.TXT"
mcopy -o -i "$IMG" "$OUT/HELLO.TXT" ::HELLO.TXT

# E lays the name down as bytes rather than a string, so that nothing here
# depends on how DEBUG reads a quote; A types in the open and the lock, the
# empty line ends the assembly, and the INT 3 at the end is where DEBUG
# takes the machine back and prints the registers.  Handle in BX, the region
# in CX:DX and SI:DI -- the first sixteen bytes of the file.
{
    printf 'E 200 48 45 4C 4C 4F 2E 54 58 54 00\r\n'
    printf 'A 100\r\n'
    printf 'MOV AX,3D02\r\n'          # open HELLO.TXT for read and write
    printf 'MOV DX,200\r\n'
    printf 'INT 21\r\n'
    printf 'MOV BX,AX\r\n'            # the handle it came back with
    printf 'MOV AX,5C00\r\n'          # lock a region of it
    printf 'MOV CX,0\r\n'
    printf 'MOV DX,0\r\n'
    printf 'MOV SI,0\r\n'
    printf 'MOV DI,10\r\n'
    printf 'INT 21\r\n'
    printf 'INT 3\r\n'
    printf '\r\n'
    printf 'G=100\r\n'
    printf 'Q\r\n'
} > "$OUT/LOCK.TXT"
mcopy -o -i "$IMG" "$OUT/LOCK.TXT" ::LOCK.TXT

{
    printf 'ECHO OFF\r\n'
    printf 'DEBUG < LOCK.TXT > PRN\r\n'
    printf 'SHARE /F:2048 /L:40\r\n'
    printf 'SHARE\r\n'
    printf 'DEBUG < LOCK.TXT > PRN\r\n'
    printf 'TYPE HELLO.TXT\r\n'
    printf 'COPY HELLO.TXT COPY.TXT\r\n'
    printf 'TYPE COPY.TXT\r\n'
    printf 'DIR COPY.TXT\r\n'
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
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/prn.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }
[ -s "$OUT/prn.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }

python3 - "$OUT/screen.bin" "$OUT/prn.txt" <<'PY' || exit 1
import re
import subprocess
import sys

screen = subprocess.run([sys.executable, "tests/screen.py", sys.argv[1]],
                        capture_output=True, text=True).stdout
said = open(sys.argv[2], "rb").read().decode("cp437").replace("\r", "")

print("--- what the screen said")
for line in screen.split("\n"):
    if line.strip():
        print("   %s" % line.rstrip())
print("--- what the printer said")
for line in said.split("\n"):
    if line.strip():
        print("   %s" % line.rstrip().expandtabs(8))

rc = 0
print("--- checks")


def ok(yes, why, missing=None):
    global rc
    if yes:
        print("ok      %s" % why)
    else:
        print("WRONG   %s" % (missing or why))
        rc = 1


# The two register dumps the INT 3 printed, in the order the batch ran them.
dumps = re.findall(r"^AX=([0-9A-F]{4}).*?\n.*?IP=0[0-9A-F]{3}\s+(.*)$",
                   said, re.M)
ok(len(dumps) == 2,
   "DEBUG ran the lock twice and printed the registers each time",
   "the printer carries %d register dumps, not two" % len(dumps))
if len(dumps) == 2:
    (ax1, fl1), (ax2, fl2) = dumps
    ok(ax1 == "0001" and "CY" in fl1,
       "with no sharer the lock is refused: AX=0001, which is "
       "error_invalid_function, and the carry set",
       "the first lock came back AX=%s %s" % (ax1, fl1))
    ok("NC" in fl2 and ax2 != "0001",
       "and once SHARE is installed the same lock is taken: the carry "
       "clear, the kernel having far-called into the sharer through the "
       "table it wrote over JShare",
       "the second lock came back AX=%s %s" % (ax2, fl2))

ok("SHARE already installed" in screen,
   "a second run says it is there already, which is the sharer's own "
   "interrupt 2FH handler answering -- reached through the segment value "
   "the loader relocated")
ok(screen.count("the file the lock is taken on") == 2,
   "TYPE read the file and then the copy of it, four opens and four "
   "closes with the kernel calling MFT_Enter and MFTClose for each",
   "the file came back %d times, not twice"
   % screen.count("the file the lock is taken on"))
ok("1 File(s) copied" in screen,
   "COPY wrote the second file with the sharer in the way of it")
ok("COPY     TXT" in screen,
   "and DIR lists it")
ok(screen.rstrip().endswith("A>"),
   "and the machine is back at the prompt with the sharer resident")
sys.exit(rc)
PY
