#!/bin/sh
# Copy the system disk to a second floppy with our DISKCOPY, and check the
# copy sector by sector from this end.
#
# DISKCOPY works a track at a time through INT 25H and INT 26H, so this is as
# much a test of the driver in IO.ASM as of DISKCOPY: 2880 sectors read and
# 2880 written, where the rest of the tests move a few hundred.
#
# It asks twice -- "Strike any key when ready", then "Copy another (Y/N)?" --
# and both reads go through DOS, function 0CH, so crn.txt answers them: a bare
# CRLF for the first and N for the second.  Keystrokes would not do, runtest
# sending them one a second from a fixed start while these two prompts are
# half a minute apart, the whole disk going by in between.
#
# The target starts as a formatted 1440K disk.  What is checked is that it
# comes back byte for byte identical to the image the system booted from,
# which is what a sector copy means.  The whole run takes about a minute.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/diskcopy.$$
BIMG=$OUT/target.img
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

mformat -C -f 1440 -i "$BIMG" ::

rc=0
./runtest.sh -t 60 -b "$BIMG" -f tests/crn.txt \
             -e "Copying" -e "Copy complete" -e "DONE" tests/diskcopy.bat || rc=1

if cmp -s test.img "$BIMG"
then echo "ok      the copy is the system disk, all 1474560 bytes of it"
else echo "MISSING the copy differs from the disk it was made from"
     cmp test.img "$BIMG" | head -3
     rc=1
fi
exit $rc
