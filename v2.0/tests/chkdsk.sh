#!/bin/sh
# Check both disks with our own CHKDSK.
#
# The release ships a CHKDSK.COM built for 2.00, which answers "Incorrect DOS
# version" to the 2.11 this DOS reports, so the one built here is the only one
# that runs -- see source/CHKLINK.ASM.
#
# Both disks are 1.44M and this CHKDSK knows no FAT ID below 0F8h, so it asks
# "Probable non-DOS disk.  Continue (Y/N)?" about each of them first.  The Y
# comes from YES.TXT: function 0Ah reads the console, and redirection makes
# that the file.
#
# Drive B is formatted here with one file of a known size on it, so the report
# for it can be checked to the byte.  A is the system disk, and what is
# checked there is that it comes back clean: a disk this DOS wrote, read back
# by this CHKDSK, with no lost chains and nothing to fix.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/chkdsk.$$
BIMG=$OUT/target.img
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

mformat -C -f 1440 -i "$BIMG" ::
printf 'one file, under a cluster\r\n' > "$OUT/ONE.TXT"
mcopy -i "$BIMG" "$OUT/ONE.TXT" ::

if ./runtest.sh -t 60 -b "$BIMG" -f tests/yes.txt \
       -e "1457664 bytes total disk space" \
       -e "512 bytes in 1 user files" \
       -e "1457152 bytes available on disk" \
       -e "DONE" tests/chkdsk.bat > "$OUT/log" 2>&1
then rc=0; else rc=$?; fi
cat "$OUT/log"

echo "--- and the system disk came back clean"
for bad in "Errors found" "lost clusters" "Probable non-DOS disk.  Continue (Y/N)? N"; do
    if grep -q "$bad" "$OUT/log"; then
        echo "MISSING CHKDSK said \"$bad\""; rc=1
    fi
done
[ $rc -eq 0 ] && echo "ok      no errors and no lost chains on either disk"
exit $rc
