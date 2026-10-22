#!/bin/sh
# Convert an .EXE to a .COM with our EXE2BIN and with Microsoft's, run what
# came out, and compare all three.
#
# EXE2BIN takes an .EXE whose header asks for nothing it cannot give -- no
# relocations, SS, SP and CS all zero -- and writes the image out on its own.
# With IP = 100h it chops the first 100h bytes off and the result is a .COM,
# which is the step the profiler needs: PROFIL links as an .EXE and only runs
# once EXE2BIN has made PROFIL.COM of it.
#
# The .EXE to feed it is built here.  tests/hello.asm is a .COM that prints a
# line, and the header wrapped around it is written by hand, because nothing
# in this repository produces an .EXE of the shape LINK did: the header has to
# be a whole 512-byte page, which is what LINK padded it to and what EXE2BIN
# assumes when it rounds the header size up and seeks there.  Get that wrong
# and EXE2BIN seeks past the start of the image: with a 32-byte header both
# EXE2BINs read 65062 bytes of whatever was after it and wrote that out, in
# perfect agreement with each other.
#
# So the three things checked are the three that matter: what our EXE2BIN
# wrote is the .COM that went in, byte for byte; it is what Microsoft's wrote,
# byte for byte; and the .COM it made runs and prints its line.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/exe2bin.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

# The same FASM assemble.sh uses, for the program inside the .EXE.
if command -v fasm >/dev/null 2>&1; then
    FASM=fasm
elif command -v wine >/dev/null 2>&1; then
    FASM="wine ../fasmw17332/FASM.EXE"
    WINEDEBUG=${WINEDEBUG:--all}
    export WINEDEBUG
else
    echo "$0: neither fasm nor wine found" >&2
    exit 2
fi
$FASM tests/hello.asm "$OUT/HELLO.COM" > /dev/null

python3 - "$OUT/HELLO.COM" "$OUT/HELLO.EXE" <<'PY'
import struct, sys
com = open(sys.argv[1], "rb").read()
image = b"\x00" * 0x100 + com            # the code sits at offset 100h
size = 512 + len(image)
hdr = struct.pack("<2sHHHHHHHHHHHHH", b"MZ",
                  size % 512,            # bytes used in the last page
                  (size + 511) // 512,   # pages in the whole file
                  0,                     # no relocations
                  32,                    # header: 32 paragraphs, one page
                  0, 0xFFFF,             # minalloc, maxalloc
                  0, 0,                  # SS, SP
                  0,                     # checksum
                  0x100, 0,              # IP, CS
                  0x1C, 0)               # relocation table, overlay
open(sys.argv[2], "wb").write(hdr + b"\x00" * (512 - len(hdr)) + image)
PY

cp bin/EXE2BIN.EXE "$OUT/MSE2BIN.EXE"

rc=0
./runtest.sh -t 55 -f "$OUT/HELLO.EXE" -f "$OUT/MSE2BIN.EXE" \
             -g OURS.COM -g THEIRS.COM \
             -e "EXE2BIN MADE THIS COM FILE" -e "DONE" tests/exe2bin.bat || rc=1

if cmp -s "$OUT/HELLO.COM" test-out/OURS.COM
then echo "ok      what ours wrote is the .COM that went in"
else echo "MISSING ours differs from the .COM that went in"; rc=1
fi
if cmp -s test-out/OURS.COM test-out/THEIRS.COM
then echo "ok      ours and Microsoft's agree byte for byte"
else echo "MISSING ours and Microsoft's disagree"; rc=1
fi
exit $rc
