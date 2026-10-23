#!/bin/sh
# Drive our DEBUG and Microsoft's with the same script of commands and compare
# what the two of them said, line for line.
#
# DEBUG reads its commands from standard input, so tests/debcmds.txt is the
# whole test: it asks for the registers, sets one, does hex arithmetic, enters
# bytes and dumps them, fills, moves and compares a block, assembles three
# instructions with the line assembler and reads them back with the
# unassembler, traces two of them, runs into the INT 20H, searches for the
# byte that was left, and loads a file somewhere harmless to dump it.
#
# The transcripts come out identical except for one thing: the segment DEBUG
# hands the program it is debugging, which is the paragraph after DEBUG
# itself.  The DEBUG.COM the release ships was built from an earlier source --
# it says "Vers 2.10" where this one says "Vers 2.30" -- and is 385 bytes
# smaller, so every address in its transcript is 0018H paragraphs lower.  The
# comparison masks the segment and keeps everything else, offsets included.
#
# The script fills the memory it is going to look at first.  DEBUG hands the
# program it is debugging whatever the command before it left in that memory,
# and the two runs do not leave the same thing: without the fills the dump of
# 200H and the search through 100H both came back different.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/debug.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
cp bin/DEBUG.COM "$OUT/MSDEBUG.COM"

rc=0
./runtest.sh -t 60 -f tests/debcmds.txt -f "$OUT/MSDEBUG.COM" \
             -g OURS.TXT -g THEIRS.TXT \
             -e "DONE" tests/debug.bat || rc=1

python3 - <<'PY' || rc=1
import re, sys
ours, theirs = (open("test-out/" + n, "rb").read().decode("latin-1")
                for n in ("OURS.TXT", "THEIRS.TXT"))
# The load segment, in the register dump and at the head of every address.
mask = lambda t: re.sub(r"(?m)^[0-9A-F]{4}:", "SEG:",
                        re.sub(r"\b([DECS]S|CS)=[0-9A-F]{4}", r"\1=SEG", t))
ok = True
def check(good, what):
    global ok
    print("%s %s" % ("ok     " if good else "MISSING", what))
    ok = ok and good

check("AX=1234" in ours, "our DEBUG set AX and showed it")
check("MOV     AX,1234" in ours, "the unassembler read back what the assembler wrote")
check("Program terminated normally" in ours, "and the program it ran came back")
check(mask(ours) == mask(theirs),
      "every line is the line Microsoft's DEBUG printed, bar the load segment")
if not ok:
    a, b = mask(ours).split("\n"), mask(theirs).split("\n")
    for i in range(max(len(a), len(b))):
        x, y = a[i] if i < len(a) else "<none>", b[i] if i < len(b) else "<none>"
        if x != y:
            print("        line %d: ours   %r" % (i + 1, x))
            print("                 theirs %r" % y)
sys.exit(0 if ok else 1)
PY
exit $rc
