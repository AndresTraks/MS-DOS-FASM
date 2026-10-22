#!/bin/sh
# Sort a file with our SORT and with Microsoft's, three ways, and compare.
#
# SORT reads standard input and writes standard output, so each run is a pair
# of redirections: plain, /R for descending, and /+6 to sort on column 6.  The
# file is the sixty numbered lines the FIND and MORE tests use, which sort
# lexicographically rather than numerically -- line 1, line 10, line 11 and so
# on -- and that is what makes the comparison worth something: the order is
# the sort's, not the file's.
#
# The two do not agree byte for byte, and the difference is one byte pair per
# run: ours ends its output with a CRLF and the SORT.EXE in bin does not, so
# its three runs run into each other.  SORT.ASM's own modification history has
# "3-18-83 MZ Fix CR-LF at end of buffer" against it, and the shipped binary
# behaves as though it were built before that.  So the lines are what is
# compared between the two, and the trailing CRLF is checked for separately:
# three of them, six bytes, and nothing else between the two outputs.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/sort.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
cp bin/SORT.EXE "$OUT/MSSORT.EXE"

rc=0
./runtest.sh -t 60 -f tests/lines.txt -f "$OUT/MSSORT.EXE" \
             -g OURS.TXT -g THEIRS.TXT -e "DONE" tests/sort.bat || rc=1

python3 - tests/lines.txt test-out/OURS.TXT test-out/THEIRS.TXT <<'PY' || rc=1
import re, sys
want, ours, theirs = (open(p, "rb").read() for p in sys.argv[1:4])
ok = True
def check(good, what):
    global ok
    print("%s %s" % ("ok     " if good else "MISSING", what))
    ok = ok and good

lines = lambda t: re.findall(rb"line \d+ of sixty", t)
nums = lambda ls: [int(l.split()[1]) for l in ls]
mine, theirs_lines = lines(ours), lines(theirs)

check(mine == theirs_lines, "ours and Microsoft's sorted the same, line for line")
check(len(ours) - len(theirs) == 6 and ours.replace(b"\r\n", b"") ==
      theirs.replace(b"\r\n", b""),
      "and differ only by the CRLF ours puts at the end of each run")
check(len(mine) == 180, "three runs of sixty lines came back (%d)" % len(mine))

plain, rev, col = mine[:60], mine[60:120], mine[120:]
check(plain == sorted(plain), "the plain run is in ascending order")
check(nums(plain)[:4] == [1, 10, 11, 12],
      "and sorted as text, not as numbers: 1, 10, 11, 12")
check(rev == sorted(rev, reverse=True), "/R is in descending order")
check(nums(rev)[0] == 9, "/R starts at line 9, the highest as text")
# Column 6 is the first digit of the number: "line 23 of sixty"[5:] is "23 of
# sixty", so /+6 sorts on the number and what follows it, as text.
keys = [l[5:] for l in col]
check(keys == sorted(keys), "/+6 sorted on column 6 and what follows it")
check(sorted(nums(plain)) == list(range(1, 61)), "every line is present once")
sys.exit(0 if ok else 1)
PY
exit $rc
