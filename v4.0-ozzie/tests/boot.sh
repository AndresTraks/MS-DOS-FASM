#!/bin/sh
# Start a machine from our BIOS, and from Microsoft's, and hold the one
# against the other.
#
# checkobj.py says our three modules are the bytes MASM made of them, which is
# the strongest thing a comparison can say and still says nothing about
# whether the result runs.  This is the other kind of test: both diskettes are
# started, and what reaches the screen has to be the same text.
#
# What reaches the screen is three lines of the system saying what it is and
# then a kernel panic:
#
#	Internal Work #2.06 - May 25, 1984
#	MS-DOS version 4.00
#	Copyright 1981,82,83,84 Microsoft Corp.
#	*  Internal Error 4560  *
#	HardErr: no handler
#
# which is as far as the release goes on a machine with this ROM in it -- see
# run.sh.  Little of it is ours: all five lines are IBMDOS.COM's, the kernel
# we have no source for.  What is ours is everything that had to work for them
# to be printed at all.  The boot sector reads IBMBIO.COM and jumps into it;
# the BIOS sizes memory, installs its interrupts, initialises the console
# driver and the disk drivers and asks the disk driver for IBMDOS.COM, which
# is read through src/IBMDSK.ASM a sector at a time; the kernel's banner and
# the panic go to the screen through src/IBMMTCON.ASM.  So the four lines are
# proof that two of the three converted modules do their work, and the fifth
# is proof that the third gets the same answer out of the hardware as
# Microsoft's own build of it did.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/ozzieboot.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

./create_image.sh "$OUT/ours.img" >/dev/null
cp bin/DRDOS1_IMD.img "$OUT/theirs.img"

# boot DISK NAME: start the machine, wait for the last line the system
# prints, and leave the screen in $OUT/NAME.txt.  The wait is on the text
# rather than on a length of time, as v4.0's tests are: nothing is paid for
# it when the guest answers.
boot() {
    _shot=$OUT/$2.bin
    rm -f "$_shot"
    {
        _i=0
        while [ "$_i" -lt 200 ]; do
            rm -f "$_shot"
            echo "pmemsave 0xb8000 4000 \"$_shot\""
            sleep 0.2
            [ "$(wc -c < "$_shot" 2>/dev/null || echo 0)" -eq 4000 ] &&
                grep -qa "HardErr" "$_shot" && break
            _i=$((_i + 1))
        done
        echo quit
    } | "$QEMU" -rtc base=localtime -m 640 \
                -drive file="$OUT/$1",format=raw,if=floppy,index=0 \
                -display none -monitor stdio >/dev/null 2>&1 || true
    [ -s "$_shot" ] || { echo "$0: the screen never came back" >&2; exit 1; }
    python3 -I - "$_shot" > "$OUT/$2.txt" <<'PY'
import sys

d = open(sys.argv[1], "rb").read()
# The adapter's text page: a character and an attribute per cell.  The lines
# the firmware wrote before the system started are left out -- SeaBIOS and
# iPXE print addresses that are not the same twice -- by beginning at the
# BIOS's own first line.
rows = []
for row in range(25):
    cells = (d[(row * 80 + c) * 2] for c in range(80))
    rows.append("".join(chr(c) if 32 <= c < 127 else " " for c in cells).rstrip())
while rows and "Internal Work" not in rows[0]:
    rows.pop(0)
print("\n".join(r for r in rows if r.strip()))
PY
}

boot ours.img ours
boot theirs.img theirs

echo "--- Microsoft's IBMBIO.COM"
sed 's/^/   /' "$OUT/theirs.txt"
echo "--- ours"
sed 's/^/   /' "$OUT/ours.txt"

rc=0
echo "--- checks"
for text in "Internal Work #2.06 - May 25, 1984" "MS-DOS version 4.00" \
            "Copyright 1981,82,83,84 Microsoft Corp."; do
    if grep -qF "$text" "$OUT/ours.txt"; then
        echo "ok      $text"
    else
        echo "MISSING $text"
        rc=1
    fi
done

if [ ! -s "$OUT/theirs.txt" ]; then
    echo "WRONG   the release's own diskette printed nothing to compare with"
    rc=1
elif cmp -s "$OUT/ours.txt" "$OUT/theirs.txt"; then
    echo "ok      our BIOS leaves the same screen as Microsoft's own"
else
    echo "WRONG   the two screens are not the same:"
    diff "$OUT/theirs.txt" "$OUT/ours.txt" | sed 's/^/        /'
    rc=1
fi

exit $rc
