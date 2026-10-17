#!/bin/sh
# Transfer the system to another disk with our own SYS.
#
# The release ships a SYS.COM, but it was built for 2.00 and answers
# "Incorrect DOS version" to the 2.11 this DOS reports.  The source accepts
# 1.54 to 2.11, so the one built here runs -- see source/SYSLINK.ASM.
#
# DIR B: afterwards says "File not found", which is right: SYS writes the two
# files hidden and system, as DOS expects to find them, so nothing shows.
# What proves it worked is this end of it -- both files on the disk, as the
# first two entries, byte for byte what went in.
#
# It does not make the disk bootable.  Nothing on this system writes a boot
# sector: SYS in 2.0 does not, and the generic FORMAT module has nothing to
# say about one either.  The image this repo boots gets its boot sector from
# create_image.sh, with dd.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/sys.$$
BIMG=$OUT/target.img
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

mformat -C -f 1440 -i "$BIMG" ::

if ./runtest.sh -t 60 -b "$BIMG" -e "System transferred" -e "DONE" tests/sys.bat
then rc=0; else rc=$?; fi

echo "--- what reached the disk"
mdir -a -i "$BIMG" :: 2>/dev/null | sed '1,2d;/^$/d'
for f in IO.SYS MSDOS.SYS; do
    if mcopy -n -i "$BIMG" "::$f" "$OUT/$f" 2>/dev/null && cmp -s "bin/$f" "$OUT/$f"
    then echo "ok      $f went across byte for byte"
    else echo "MISSING $f is not on the disk, or differs"; rc=1
    fi
done
exit $rc
