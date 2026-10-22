#!/bin/sh
# Search a file with our FIND and with Microsoft's, and compare.
#
# FIND has four switches and a handful of ways to fail, so rather than check a
# line or two of output this runs both of them over the same file five times
# -- plain, /C for a count, /N for line numbers, /V for the lines that do not
# match, and a file that does not exist -- and compares the two transcripts
# byte for byte.  Anything the conversion changed about the searching, the
# counting, the heading it prints per file or the message it gives for a
# missing file shows up as a difference.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/find.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
cp bin/FIND.EXE "$OUT/MSFIND.EXE"

rc=0
./runtest.sh -t 60 -f tests/lines.txt -f "$OUT/MSFIND.EXE" \
             -g OURS.TXT -g THEIRS.TXT \
             -e "line 2 of sixty" -e "FIND: File not found" \
             -e "DONE" tests/find.bat || rc=1

if cmp -s test-out/OURS.TXT test-out/THEIRS.TXT
then echo "ok      ours and Microsoft's agree byte for byte, over all five runs"
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

runs = out.split(b"---------- ")[1:]       # FIND heads each file it reads
check(len(runs) == 4, "four of the five runs reached the file and headed it")
# "line 2 of" is in line 2 and in no other: lines 20 to 29 read "line 2x of".
check(runs[0] == b"lines.txt\nline 2 of sixty\n\n",
      "the plain search found line 2 and nothing else")
check(runs[1] == b"lines.txt: 60\n\n", "/C counted all sixty lines")
check(runs[2] == b"lines.txt\n[59]line 59 of sixty\n\n",
      "/N numbered the line it found")
check(runs[3] == b"lines.txt\n", "/V \"line\" found nothing, every line having one")
sys.exit(0 if ok else 1)
PY
exit $rc
