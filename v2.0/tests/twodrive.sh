#!/bin/sh
# Check that DOS has a second drive, can work both of them, and says the right
# thing when the one it is writing to is write protected.
#
# IO.ASM reported one unit and refused every other, so B: did not exist and
# nothing two-drive -- DISKCOPY, COPY A: to B: -- had ever run.  The driver
# now takes the count from the ROM's equipment word, which QEMU sets from the
# drives it was given, so this test hands it a second floppy and copies both
# ways across it.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/twodrive.$$
BIMG=$OUT/driveb.img
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

# A disk for drive B with one file on it, and room to copy one back.
mformat -C -f 1440 -i "$BIMG" ::
printf 'A FILE ON DRIVE B\r\n' > "$OUT/HELLOB.TXT"
mcopy -i "$BIMG" "$OUT/HELLOB.TXT" ::

# Not left to set -e, so that the state of drive B is reported either way.
if ./runtest.sh -t 45 -b "$BIMG" -g FROMB.TXT \
                -e "A FILE ON DRIVE B" \
                -e "1 File(s) copied" \
                -e "DONE" tests/twodrive.bat
then rc=0; else rc=$?; fi

# The last DIR B: on screen is one listing among several, so check the disk
# itself for what was copied back to it.
echo "--- drive B afterwards"
mdir -i "$BIMG" :: 2>/dev/null | sed '1,2d;/^$/d'
if mdir -i "$BIMG" ::BACK.TXT >/dev/null 2>&1; then
    echo "ok      BACK.TXT reached drive B"
else
    echo "MISSING BACK.TXT on drive B"
    rc=1
fi

# And with the tab on.  The driver used to hand the ROM's status byte back as
# the DOS error code, which is a different set of numbers: a write-protected
# disk returns 3 from the ROM, and 3 to the DOS is "Bad command", so that is
# what it used to say.  The keystroke answers Abort at the prompt.
printf '\n======== drive B write protected\n'
if ./runtest.sh -t 40 -K 22 -k "a" -b "$BIMG" -r \
                -e "Write protect error writing drive B" \
                -e "DONE" tests/writeprot.bat
then :; else rc=1; fi

exit $rc
