#!/bin/sh
# Run MKCNTRY on the system this builds, and start the system again on the
# COUNTRY.SYS it wrote.
#
# COUNTRY.SYS is not a program but a file of tables: the date and time
# formats, the currency and the separators for every country DOS 4 knew, and
# the collating and case tables with them.  MKCNTRY is what writes it -- the
# release's build runs MKCNTRY.EXE in src/DEV/COUNTRY and keeps what it
# lays down -- so the way to test the program is to run it and then make
# the system read what came out.
#
#   MKCNTRY          writes COUNTRY.SYS onto the disk
#   COUNTRY=044,437,\COUNTRY.SYS    and the system is started again on it
#
# The second machine has no AUTOEXEC.BAT, so COMMAND.COM asks for the date
# -- and the format it asks in comes from the country table SYSINIT read out
# of that file.  Country 1 is the United States and its date format is
# mm-dd-yy; country 44 is the United Kingdom and its is dd-mm-yy.  So the
# prompt is the assertion: the file MKCNTRY made has to be a file DOS can
# read, the entry for 44 has to be in it where the header says, and the
# format in it has to be the one the table gives that country.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/country.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/MKCNTRY.EXE ::MKCNTRY.EXE

{
    printf 'ECHO OFF\r\n'
    printf 'MKCNTRY\r\n'
    printf 'DIR COUNTRY.SYS\r\n'
    printf 'ECHO THAT IS ALL\r\n'
} > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT
# the entries mtools wrote get the tidying create_image.sh gives the rest
python3 dosdir.py "$IMG"

{
    await "THAT IS ALL" 1
    awaitprompt
    snap
    cp "$SHOT" "$OUT/made.bin"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/made.bin" ] || { echo "$0: the screen never came back" >&2; exit 1; }

# What the first machine wrote, read back from the image with mtools: the
# file has to be there before the second machine can be told to read it.
mcopy -n -i "$IMG" ::COUNTRY.SYS "$OUT/COUNTRY.SYS" 2>/dev/null || true

# Now the same disk with a CONFIG.SYS that names it and no AUTOEXEC.BAT, so
# that COMMAND.COM asks for the date in the format the table gives country
# 44.
printf 'COUNTRY=044,437,\\COUNTRY.SYS\r\n' > "$OUT/CONFIG.SYS"
mcopy -o -i "$IMG" "$OUT/CONFIG.SYS" ::CONFIG.SYS
mdel -i "$IMG" ::AUTOEXEC.BAT 2>/dev/null || true
python3 dosdir.py "$IMG"

{
    await "Enter new date"
    snap
    cp "$SHOT" "$OUT/read.bin"
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/read.bin" ] || { echo "$0: the second screen never came back" >&2; exit 1; }

python3 - "$OUT/made.bin" "$OUT/read.bin" "$OUT/COUNTRY.SYS" <<'PY' || exit 1
import os
import subprocess
import sys


def screen(path):
    return subprocess.run([sys.executable, "tests/screen.py", path],
                          capture_output=True, text=True).stdout


made, read = screen(sys.argv[1]), screen(sys.argv[2])
for name, text in (("the machine that ran MKCNTRY", made),
                   ("the machine that read COUNTRY.SYS", read)):
    print("--- %s" % name)
    for line in text.split("\n"):
        if line.strip():
            print("   %s" % line.rstrip())

rc = 0
print("--- checks")


def ok(yes, why, missing=None):
    global rc
    if yes:
        print("ok      %s" % why)
    else:
        print("WRONG   %s" % (missing or why))
        rc = 1


ok("COUNTRY.SYS created" in made,
   "MKCNTRY wrote the file and said so, which is the last thing it does")
ok("COUNTRY  SYS" in made,
   "and DIR found it on the disk")
size = os.path.getsize(sys.argv[3]) if os.path.exists(sys.argv[3]) else 0
ok(size > 10000,
   "and what came off the disk is %d bytes, which is the forty-six "
   "entries of the table -- twenty-three countries, each with the code "
   "pages it can be had in" % size,
   "the file off the disk is %d bytes" % size)
head = open(sys.argv[3], "rb").read(8) if size else b""
ok(head[:1] == b"\xff" and head[1:8] == b"COUNTRY",
   "and it begins with the signature DOS looks for, 0FFh and COUNTRY")
ok("Enter new date" in read,
   "the second machine started on it and COMMAND.COM asked for the date")
ok("(dd-mm-yy)" in read,
   "in the format the table gives country 44, which is the United "
   "Kingdom's: the system read the entry out of the file MKCNTRY made",
   "the date prompt reads %r, which is not the United Kingdom's"
   % next((l.strip() for l in read.split("\n") if "Enter new date" in l), ""))
ok("Unrecognized command" not in read and "Invalid country" not in read,
   "and SYSINIT took the COUNTRY= line without a complaint")
sys.exit(rc)
PY
