#!/bin/sh
# Rebuild a disk's root directory with our RECOVER and with Microsoft's, and
# compare the two disks afterwards.
#
# RECOVER given a drive rather than a file throws the directory away and walks
# the FAT instead, writing a FILEnnnn.REC entry for every chain it finds.  It
# is the only way back from a directory that no longer reads, and what it
# leaves behind is exact enough to compare: two identical disks, one put
# through our RECOVER and one through the RECOVER.COM in bin, should come back
# identical to each other.
#
# Two boots, then, one for each.  The disks start with three files on them of
# known sizes, so the directory RECOVER rebuilds can be read back here and
# checked against what went in: three chains, three .REC files, and the sizes
# rounded up to whole allocation units, which is all the FAT can tell it.
#
# It asks for a keystroke first, through DOS, so crn.txt answers it.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/recover.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
cp bin/RECOVER.COM "$OUT/MSRECOV.COM"

mformat -C -f 1440 -i "$OUT/ours.img" ::
printf 'the first file, a few bytes long\r\n' > "$OUT/ONE.TXT"
python3 -c "open('$OUT/TWO.TXT','wb').write(b'two\r\n' * 300)"
python3 -c "open('$OUT/THREE.TXT','wb').write(bytes(1500))"
for f in ONE.TXT TWO.TXT THREE.TXT; do mcopy -i "$OUT/ours.img" "$OUT/$f" ::; done
cp "$OUT/ours.img" "$OUT/theirs.img"

rc=0
printf '\n======== our RECOVER\n'
./runtest.sh -t 60 -b "$OUT/ours.img" -f tests/crn.txt \
             -e "file(s) recovered" -e "DONE" tests/recover.bat || rc=1

printf '\n======== the RECOVER.COM in bin\n'
./runtest.sh -t 60 -b "$OUT/theirs.img" -f tests/crn.txt -f "$OUT/MSRECOV.COM" \
             -e "file(s) recovered" -e "DONE" tests/recover2.bat || rc=1

printf '\n======== what each left on the disk\n'
mdir -i "$OUT/ours.img" :: 2>/dev/null | sed '1,2d;/^$/d'
python3 - "$OUT/ours.img" "$OUT/theirs.img" <<'PY' || rc=1
import sys
ours, theirs = (bytearray(open(p, "rb").read()) for p in sys.argv[1:3])
# Every byte but the time and date each entry is stamped with.  The two runs
# are two boots a minute apart, and RECOVER dates what it writes, so those
# four bytes of each of the 224 root directory entries differ and nothing
# else may.  The root directory of a 1440K disk is sectors 19 to 32.
for img in (ours, theirs):
    for e in range(19 * 512, 33 * 512, 32):
        img[e + 22:e + 26] = b"\0\0\0\0"
if ours == theirs:
    print("ok      the two disks came back identical, stamps aside")
else:
    at = next(i for i, (a, b) in enumerate(zip(ours, theirs)) if a != b)
    print("MISSING our RECOVER left a different disk than Microsoft's, "
          "from byte %d (sector %d)" % (at, at // 512))
    sys.exit(1)
PY
recs=$(mdir -i "$OUT/ours.img" :: 2>/dev/null | grep -c "^FILE[0-9]* *REC" || true)
if [ "$recs" = 3 ]
then echo "ok      three chains became three .REC files"
else echo "MISSING expected three .REC files, found $recs"; rc=1
fi
exit $rc
