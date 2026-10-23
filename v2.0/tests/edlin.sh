#!/bin/sh
# Edit a file with our EDLIN and with Microsoft's, and compare both the files
# they left and what they said while doing it.
#
# EDLIN takes its commands on standard input, so a script drives it: "2d" to
# delete the second line and "e" to write the file back and quit.  Insert mode
# is out of reach this way -- it ends on a Ctrl-C, which DOS turns into an
# INT 23H only for input from the console, not from a file -- so the script
# stays with the line commands, which is enough to make EDLIN read a file in,
# change it and write it out with a .BAK beside it.
#
# Both run in the one boot, each on its own copy of the same five line file.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/edlin.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
cp bin/EDLIN.COM "$OUT/MSEDLIN.COM"

rc=0
./runtest.sh -t 60 -f tests/five.txt -f tests/edcmds.txt -f "$OUT/MSEDLIN.COM" \
             -g A.TXT -g B.TXT -g OURS.TXT -g THEIRS.TXT -g A.BAK \
             -e "line 1 of five" -e "DONE" tests/edlin.bat || rc=1

python3 - tests/five.txt <<'PY' || rc=1
import sys
want = open(sys.argv[1], "rb").read()
ours, theirs = (open("test-out/" + n, "rb").read() for n in ("A.TXT", "B.TXT"))
said = [open("test-out/" + n, "rb").read() for n in ("OURS.TXT", "THEIRS.TXT")]
bak = open("test-out/A.BAK", "rb").read()
ok = True
def check(good, what):
    global ok
    print("%s %s" % ("ok     " if good else "MISSING", what))
    ok = ok and good

lines = lambda t: [l for l in t.replace(b"\x1a", b"").split(b"\r\n") if l]
check(lines(ours) == [b"line %d of five" % n for n in (1, 3, 4, 5)],
      "our EDLIN deleted line 2 and kept the other four")
check(ours == theirs, "the file it left is the one Microsoft's left, byte for byte")
check(said[0] == said[1], "and it said the same things on the way")
check(lines(bak) == [b"line %d of five" % n for n in range(1, 6)],
      "the .BAK it left behind is the file that went in")
sys.exit(0 if ok else 1)
PY
exit $rc
