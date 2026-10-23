#!/bin/sh
# Install our PRINT, queue a file, and read what came out of the printer.
#
# PRINT is the one resident program here.  It hooks INT 28H, the idle
# interrupt DOS raises while it waits for the console, and prints from there a
# sector at a time -- so the printing happens after the batch file has ended
# and COMMAND is sitting at the prompt, not while PRINT itself is running.
# The run therefore has to idle for a while before the screen is read.
#
# Built IBM, as the 2.11 source comes, so it writes to the card through INT
# 17H rather than through the DOS device.  QEMU's parallel port is pointed at
# a file with -P, and what lands there is compared with the file that went in.
#
# On its first run PRINT asks which device to print to, "Name of list device
# [PRN]:", and takes the answer with a buffered read, so ans.txt -- a bare
# CRLF -- accepts the default.
#
# The release ships a PRINT.COM built from the other source, which accepts up
# to 2.00 and refuses the 2.11 this DOS reports, so there is nothing to
# compare against: this is the only PRINT that runs here.
# It does not pass yet.  PRINT installs and then the machine stops; what is
# known about that, and what has been ruled out, is in source/PRTLINK.ASM.
# The image ships Microsoft's PRINT.COM until this one works, so the run below
# gets "Incorrect DOS version" from that one rather than reaching the printer.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/print.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

rc=0
./runtest.sh -t 45 -f tests/prtext.txt -f tests/ans.txt -P "$OUT/lpt.bin" \
             -e "Resident part of PRINT installed" -e "DONE" tests/print.bat || rc=1

if [ -s "$OUT/lpt.bin" ]; then
    printf '\n--- what reached the printer (%d bytes)\n' "$(stat -c%s "$OUT/lpt.bin")"
    sed -n '1,4p' "$OUT/lpt.bin" | tr -d '\r'
    python3 - tests/prtext.txt "$OUT/lpt.bin" <<'PY' || rc=1
import sys
want, got = (open(p, "rb").read() for p in sys.argv[1:3])
# PRINT pads its last sector with nulls and ends the job with a form feed.
got = got.rstrip(b"\x00\x0c")
if got.startswith(want.rstrip(b"\x1a\x00")):
    print("ok      every line of the file reached the printer, in order")
else:
    print("MISSING what reached the printer is not the file")
    print("        wanted %r" % want[:40])
    print("        got    %r" % got[:40])
    sys.exit(1)
PY
else
    echo "MISSING nothing reached the printer"
    rc=1
fi
exit $rc
