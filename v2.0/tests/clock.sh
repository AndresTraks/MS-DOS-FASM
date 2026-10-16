#!/bin/sh
# Check that the date and time the system keeps are the real ones.
#
# DATE and TIME both report and then prompt, so they are fed a blank line from
# ANS.TXT to leave the clock alone.  Two runs:
#
#   * clock.bat asks what the clock says, and it is compared against the clock
#     of the machine running QEMU, which is where it came from.  runtest.sh
#     passes -rtc base=localtime, so that is local time and not UTC.
#
#   * clockset.bat sets the clock to 1999-12-31 23:50:00 and reads it back, so
#     that the date and time go out through TIM_STORE and come back in through
#     TIM_FETCH.  That is the last day of a year five leap years from the
#     epoch, which is the arithmetic worth getting wrong.
#
# A run crossing midnight fails the first check on the date.  It takes half a
# minute, so that is one run in three thousand.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/clock.$$
trap 'rm -f "$OUT"' EXIT
fail=0

# $1 what we are checking, $2 the batch file, $3 "host" or the time it should
# be reporting
check() {
    printf '\n======== %s\n' "$1"
    start=$(date '+%s')
    if ./runtest.sh -t 30 -f tests/ans.txt -e "DONE" "$2" > "$OUT" 2>&1
    then rc=0; else rc=$?; fi
    end=$(date '+%s')
    sed -n '/--- screen/,/--- directory/p;/^ok\|^MISSING/p' "$OUT"
    [ "$rc" -eq 0 ] || { fail=1; return; }
    python3 - "$OUT" "$3" "$start" "$end" <<'PY' || fail=1
import datetime
import re
import sys

screen, base, start, end = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
text = open(screen, errors="replace").read()

# The last of each, so setting the clock first and asking afterwards works.
date = re.findall(r"Current date is (\w+) +(\d+)-(\d+)-(\d+)", text)
time = re.findall(r"Current time is +(\d+):(\d+):(\d+)", text)
if not date or not time:
    sys.exit("FAIL: DATE or TIME said nothing I could read")
weekday = date[-1][0]
month, day, year = (int(g) for g in date[-1][1:])
hour, minute, second = (int(g) for g in time[-1])
print("DOS says   %s %d-%02d-%04d %d:%02d:%02d"
      % (weekday, month, day, year, hour, minute, second))

# The clock is read somewhere inside the run, so allow all of it and a minute
# either side, the chip keeping the time only to the second.
if base == "host":
    lo = datetime.datetime.fromtimestamp(start - 60)
    hi = datetime.datetime.fromtimestamp(end + 60)
else:
    lo = datetime.datetime.fromisoformat(base)
    hi = lo + datetime.timedelta(seconds=end - start + 60)
print("should be  %s %s .. %s" % (lo.strftime("%a %-m-%d-%Y"),
                                  lo.strftime("%H:%M:%S"), hi.strftime("%H:%M:%S")))

bad = []
if (month, day, year) != (lo.month, lo.day, lo.year):
    bad.append("the date is %d-%02d-%04d, not %d-%02d-%04d"
               % (month, day, year, lo.month, lo.day, lo.year))
if weekday != lo.strftime("%a"):
    bad.append("the day of the week is %s, not %s" % (weekday, lo.strftime("%a")))
said = lo.replace(hour=hour, minute=minute, second=second, microsecond=0)
if not lo <= said <= hi:
    bad.append("the time of day is %s, outside %s to %s"
               % (said.strftime("%H:%M:%S"), lo.strftime("%H:%M:%S"),
                  hi.strftime("%H:%M:%S")))
if bad:
    sys.exit("FAIL: " + "; ".join(bad))
print("ok")
PY
}

check "the clock this machine starts with" tests/clock.bat host
check "a clock set and read back" tests/clockset.bat 1999-12-31T23:50:00

if [ $fail -eq 0 ]; then
    printf '\n======== the clock is right\n'
else
    printf '\n======== the clock is wrong\n' >&2
fi
exit $fail
