#!/bin/sh
# Paginate a file with our MORE and with Microsoft's, and compare.
#
# Both read the same 60 line file and write to a file rather than the screen,
# which is the only way to see all of it: MORE pages its data to standard
# output and takes the keystroke from standard error, so redirecting the
# output leaves the prompt still answerable from the keyboard.
#
# The two do not agree byte for byte, and should not.  MORE.ASM comes set as
# the IBM version -- IBMVER TRUE, MSVER FALSE -- which asks the ROM how wide
# the screen is and pauses when the cursor reaches row MAXROW, 25 on a 25 row
# display, so 24 lines of text then "-- More --" on the last one.  The
# MORE.COM in bin pauses after 23, MAXROW being left at 24 where the source
# puts it.  So this checks the part that must agree: with the prompts taken
# out, each output is the file that went in, every byte of it, and each pauses
# where its own MAXROW says.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/more.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
cp bin/MORE.COM "$OUT/MSMORE.COM"

rc=0
./runtest.sh -t 60 -K 18 -k "ret ret ret ret ret ret ret ret" \
             -f tests/lines.txt -f "$OUT/MSMORE.COM" \
             -g OURS.TXT -g THEIRS.TXT -e "DONE" tests/more.bat || rc=1

python3 - tests/lines.txt test-out/OURS.TXT test-out/THEIRS.TXT <<'PY' || rc=1
import re, sys
want, ours, theirs = (open(p, "rb").read() for p in sys.argv[1:4])
ok = True
def check(good, what):
    global ok
    print("%s %s" % ("ok     " if good else "MISSING", what))
    ok = ok and good

# Each build puts its prompt in the stream a little differently -- one of them
# lands between the CR and the LF that end the line -- so the data is what is
# compared, not the byte dance around the pause.
numbers = lambda t: [int(n) for n in re.findall(rb"line (\d+) of sixty", t)]
check(numbers(want) == list(range(1, 61)), "the file that went in has sixty lines")
for who, out, rows in (("ours", ours, 24), ("Microsoft's", theirs, 23)):
    check(numbers(out) == numbers(want),
          "%s output has every line, in order, and no others" % who)
    pauses = [len(numbers(part)) for part in out.split(b"\r-- More --")[:-1]]
    check(len(pauses) == 2, "%s pauses twice in sixty lines" % who)
    check(pauses and pauses[0] == rows,
          "%s pauses after %d lines, where its MAXROW puts it" % (who, rows))
sys.exit(0 if ok else 1)
PY
exit $rc
