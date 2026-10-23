#!/bin/sh
# Install PRINT, queue a file, and read what came out of the printer.
#
# PRINT is the one resident program here.  It prints from two interrupt
# handlers: INT 1CH, the ROM's timer tick, and INT 28H, the idle interrupt DOS
# raises while it waits for the console.  The timer handler gives up whenever
# the INDOS flag is set, and DOS keeps it set for as long as it is inside a
# call -- which, at the prompt, is all the time, because the console driver
# waits for a key inside the ROM.  So the whole job is done by the INT 28H
# path, one character per interrupt, and DOS raises one INT 28H per console
# read.  Nothing is printed until a key is pressed, and each key moves the
# job on by two characters.
#
# Hence -k: eight returns at the prompt, which is more than the ten bytes of
# prtext.txt need, and why that file is as short as it is.  PRINT reads in
# 128-byte records and prints the nulls DOS pads the last one with, so the
# comparison below drops them.
#
# Built IBM, as the 2.11 source comes, so the characters reach the card
# through the PRN driver and from there INT 17H.  QEMU's parallel port is
# pointed at a file with -P, and what lands there is compared with the file
# that went in.
#
# On its first run PRINT asks which device to print to, "Name of list device
# [PRN]:", and takes the answer with a buffered read, so ans.txt -- a bare
# CRLF -- accepts the default.
#
# The returns pressed at the prompt scroll the screen, so the batch file sends
# what PRINT says to prtout.txt and -g fetches it instead.
#
# The release ships a PRINT.COM built from the other source, which accepts up
# to 2.00 and refuses the 2.11 this DOS reports, so there is nothing to
# compare against: this is the only PRINT that runs here.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/print.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

rc=0
./runtest.sh -t 45 -K 18 -k "ret ret ret ret ret ret ret ret" \
             -f tests/prtext.txt -f tests/ans.txt -P "$OUT/lpt.bin" \
             -g prtout.txt \
             -e "Resident part of PRINT installed" \
             -e "is currently being printed" -e "DONE" tests/print.bat || rc=1

if [ -s "$OUT/lpt.bin" ]; then
    printf '\n--- what reached the printer (%d bytes)\n' "$(stat -c%s "$OUT/lpt.bin")"
    cat -v "$OUT/lpt.bin"; echo
    python3 - tests/prtext.txt "$OUT/lpt.bin" <<'PY' || rc=1
import sys
want, got = (open(p, "rb").read() for p in sys.argv[1:3])
# PRINT pads its last record with nulls and ends the job with a form feed.
got = got.rstrip(b"\x00\x0c")
if got == want:
    print("ok      every line of the file reached the printer, in order")
else:
    print("MISSING what reached the printer is not the file")
    print("        wanted %r" % want)
    print("        got    %r" % got)
    sys.exit(1)
PY
else
    echo "MISSING nothing reached the printer"
    rc=1
fi
exit $rc
