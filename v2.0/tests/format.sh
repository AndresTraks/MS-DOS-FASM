#!/bin/sh
# Format a disk with our own FORMAT and then use it.
#
# FORMAT is the one utility the release left without a binary: FORMAT.ASM is
# in the sources and there is no FORMAT.COM beside it, so this is the only
# formatter this system has.  See source/FORLINK.ASM for how it is put
# together.
#
# Two runs over one disk, which starts out as 1440K of nothing:
#
#   * format.bat formats it and nothing else, so that the report FORMAT prints
#     at the end is still on the screen to be read.  1457664 bytes is what a
#     1440K diskette comes to once the boot sector, both FATs and the
#     directory are taken off it.
#   * formatuse.bat then copies a file onto the disk and reads it back, which
#     is the part that matters: a FAT and a directory DOS can actually use.
#
# The bad sector scan reads every allocation unit on the disk, so the first
# run takes about three minutes even with the driver taking a track at a time.
# That is why this is not in run-all.sh.
#
# Note what is not here: nothing checks the disk from this end with mtools.
# The generic OEM module writes no boot sector, so there is no BPB on the disk
# to describe it -- DOS gets the geometry from the driver instead and does not
# care, but mtools has to guess, and guesses 360K.  A disk formatted here is
# good for this system and carries nothing to identify it to another.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/format.$$
BIMG=$OUT/blank.img
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

dd if=/dev/zero of="$BIMG" bs=512 count=2880 status=none

fail=0
printf '\n======== formatting a blank disk in B\n'
if ./runtest.sh -t 200 -K 16 -k "ret" -b "$BIMG" \
                -e "bytes total disk space" \
                -e "1457664 bytes available on disk" \
                -e "DONE" tests/format.bat
then :; else fail=1; fi

printf '\n======== using what it formatted\n'
if ./runtest.sh -t 45 -b "$BIMG" -g T.TXT \
                -e "1 File(s) copied" \
                -e "DONE" tests/formatuse.bat
then :; else fail=1; fi

exit $fail
