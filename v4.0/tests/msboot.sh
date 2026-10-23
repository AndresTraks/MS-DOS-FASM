#!/bin/sh
# Hold the boot sector fasm builds against the one MASM built.
#
# This is the one place in the release where Microsoft shipped what the
# assembler made of a source file: the build ran MSBOOT.ASM through MASM,
# LINK and EXE2BIN and then through DBOF, which writes a binary out as DB
# statements, and the result is INC/BOOT.INC, included by FORMAT and SYS so
# that they can write a boot sector onto a disk.  So the conversion can be
# checked the strongest way there is -- against Microsoft's own bytes.
#
# They are not quite the same bytes.  Fourteen differ, in seven instructions,
# and every one is a register-to-register operation that the two assemblers
# encode from opposite ends: MOV CX,DX is 8B CA to MASM and 89 D1 to fasm,
# XOR AX,AX is 33 C0 against 31 C0, and so on.  Both encodings are the same
# instruction and the same length, so nothing moves, which is why the second
# check below is the one that matters: disassembled, the two sectors are the
# same program.
set -e
cd "$(dirname "$0")/.."

./assemble.sh >/dev/null

OUT=${TMPDIR:-/tmp}/msboot.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

# INC/BOOT.INC, back from DB statements into the 512 bytes it came from.
python3 - src/INC/BOOT.INC "$OUT/masm.bin" <<'PY'
import re
import sys
out = bytearray()
for line in open(sys.argv[1]):
    for byte in re.findall(r"\b0?([0-9A-Fa-f]{2})H\b", line):
        out.append(int(byte, 16))
open(sys.argv[2], "wb").write(bytes(out))
PY

rc=0

python3 - bin/MSBOOT.BIN "$OUT/masm.bin" <<'PY' || rc=1
import sys
ours, theirs = (open(p, "rb").read() for p in sys.argv[1:3])
if len(ours) != 512 or len(theirs) != 512:
    print("MISSING a boot sector is 512 bytes, these are %d and %d"
          % (len(ours), len(theirs)))
    sys.exit(1)
differ = [i for i in range(512) if ours[i] != theirs[i]]
print("ok      the sector is 512 bytes, as it has to be")
print("ok      %d of its 512 bytes are Microsoft's, byte for byte"
      % (512 - len(differ)))
if differ:
    print("        the %d that differ:" % len(differ))
    for i in differ:
        print("          %04X  ours %02X  MASM %02X"
              % (0x7C00 + i, ours[i], theirs[i]))
PY

# Both sectors through the same disassembler, with the raw bytes stripped off
# so that only the instructions are compared.
dis() {
    objdump -D -b binary -m i8086 --adjust-vma=0x7c00 "$1" |
        sed -n 's/^ *\([0-9a-f]*\):\t[0-9a-f ]*\t/\1\t/p'
}
dis bin/MSBOOT.BIN > "$OUT/ours.dis"
dis "$OUT/masm.bin" > "$OUT/masm.dis"

if cmp -s "$OUT/ours.dis" "$OUT/masm.dis"; then
    echo "ok      disassembled, the two sectors are the same $(wc -l < "$OUT/ours.dis" | tr -d ' ') instructions"
else
    echo "MISSING the two sectors are not the same program"
    diff "$OUT/masm.dis" "$OUT/ours.dis" | head -20
    rc=1
fi

exit $rc
