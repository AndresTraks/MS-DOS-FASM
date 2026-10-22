#!/bin/sh
# Compare files with our FC and with Microsoft's, four ways, and compare.
#
# Four runs each: a file against itself, against a copy with one line altered,
# the same pair with /B for a byte by byte comparison, and a file that is not
# there.  The altered copy is made here from the sixty line file the FIND,
# MORE and SORT tests use, with line 30 changed, so what FC reports about it
# is known in advance.
#
# What this is really checking is that our FC and the FC.EXE in bin say the
# same thing, down to the byte, about all four: the line comparison, the
# binary one, the message for a missing file and the silence when two files
# agree.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/fc.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
cp bin/FC.EXE "$OUT/MSFC.EXE"
python3 - tests/lines.txt "$OUT/other.txt" <<'PY'
import sys
lines = open(sys.argv[1], "rb").read().split(b"\r\n")
lines[29] = b"line 30 is not what it was"
open(sys.argv[2], "wb").write(b"\r\n".join(lines))
PY

rc=0
./runtest.sh -t 60 -f tests/lines.txt -f "$OUT/other.txt" -f "$OUT/MSFC.EXE" \
             -g OURS.TXT -g THEIRS.TXT \
             -e "File not found:nosuch.txt" -e "DONE" tests/fc.bat || rc=1

if cmp -s test-out/OURS.TXT test-out/THEIRS.TXT
then echo "ok      ours and Microsoft's agree byte for byte, over all four runs"
else echo "MISSING ours and Microsoft's disagree"
     cmp test-out/OURS.TXT test-out/THEIRS.TXT || true
     rc=1
fi
python3 - test-out/OURS.TXT <<'PY' || rc=1
import re, sys
out = open(sys.argv[1], "rb").read().replace(b"\r\n", b"\n")
ok = True
def check(good, what):
    global ok
    print("%s %s" % ("ok     " if good else "MISSING", what))
    ok = ok and good

# FC heads each comparison with the two file names and reports what it found
# between them; the /B run prints every byte that differs, which is most of
# the file once the altered line has shifted it.
check(b"line 30 is not what it was" in out,
      "the line comparison showed the line that changed")
check(out.count(b"***") >= 2,
      "and marked its findings, %d marker lines in all" % out.count(b"***"))
check(re.search(rb"^\s*0000041[0-9A-F]\s+[0-9A-F]{2}\s+[0-9A-F]{2}", out, re.M)
      is not None, "/B reported differing bytes with their offsets")
sys.exit(0 if ok else 1)
PY
exit $rc
