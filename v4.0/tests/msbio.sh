#!/bin/sh
# Walk the BIOS the way DOS will.
#
# IO.SYS is MSLOAD.COM and then MSBIO.BIN: the boot sector reads the first
# three sectors, which are MSLOAD, and MSLOAD walks the FAT to read the rest
# in at 70h:0.  What that leaves is the thirteen modules of the BIOS in the
# two segments the linker gave them, CODE and then SYSINITSEG.
#
# There is no 4.00 kernel here yet, so this cannot be booted.  What can be
# checked is the thing the conversion was most likely to get wrong: the
# device chain.  MASM wrote each link in it as "DD <label>", which is a far
# pointer -- the offset and the segment the linker filled in -- and in fasm
# that is "DW <label>, CODE", one change repeated a dozen times in
# MSBDATA.INC.  If any of them went wrong the chain breaks, and DOS would
# find one device and no more.
#
# So: assemble the BIOS with the addresses of the headers appended, then walk
# the chain from the first header to the end and check every link, name and
# attribute against what the source declares.
set -e
cd "$(dirname "$0")/.."

./assemble.sh >/dev/null

OUT=${TMPDIR:-/tmp}/msbio.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

if command -v fasm >/dev/null 2>&1; then
    FASM=fasm
else
    FASM="wine ../fasmw17332/FASM.EXE"
    WINEDEBUG=${WINEDEBUG:--all}
    export WINEDEBUG
fi

HERE=$(pwd)

# The BIOS again, with the addresses the walk starts from after it.
cat > "$OUT/probe.asm" <<EOF
include '$HERE/src/BIOS/MSBIOLNK.ASM'
PROBE:
dw CONHEADER, START_BDS, DRVMAX, CODE_SIZE, SYSINITSEG, PROBE
EOF
$FASM "$OUT/probe.asm" "$OUT/probe.bin" >/dev/null

python3 - "$OUT/probe.bin" bin/MSBIO.BIN bin/MSLOAD.COM bin/IO.SYS <<'PY' || exit 1
import struct
import sys

probe, bios, msload, iosys = (open(p, "rb").read() for p in sys.argv[1:5])
(conheader, start_bds, drvmax, code_size, sysinitseg,
 probe_at) = struct.unpack("<6H", probe[-12:])

rc = 0


def ok(what):
    print("ok      %s" % what)


def bad(what):
    global rc
    print("MISSING %s" % what)
    rc = 1


if iosys == msload + bios:
    ok("IO.SYS is MSLOAD and then the BIOS, %d bytes of it" % len(iosys))
else:
    bad("IO.SYS is not MSLOAD followed by the BIOS")

if sysinitseg == 0x70 + (code_size + 15) // 16:
    ok("SYSINITSEG starts at the paragraph after the %d bytes of CODE"
       % code_size)
else:
    bad("SYSINITSEG is not where the code segment ends")

# The device chain.  Each header is a far pointer to the next, the
# attributes, the strategy and interrupt entries, and eight bytes of name.
wanted = [
    ("CON     ", 0b1000000000010011),
    ("AUX     ", 0b1000000000000000),
    ("PRN     ", 0x8000 + 0x2000 + 0x0040),
    ("CLOCK$  ", 0b1000000000001000),
    (None,       0b0000100001000010),       # the disk device, name is a count
    ("COM1    ", 0b1000000000000000),
    ("LPT1    ", 0x8000 + 0x2000 + 0x0040),
    ("LPT2    ", 0x8000 + 0x2000 + 0x0040),
    ("LPT3    ", 0x8000 + 0x2000 + 0x0040),
    ("COM2    ", 0b1000000000000000),
    ("COM3    ", 0b1000000000000000),
    ("COM4    ", 0b1000000000000000),
]

at = conheader
walked = []
for i in range(len(wanted) + 2):
    if at + 18 > len(bios):
        bad("a device header at %04X is outside the BIOS" % at)
        break
    offset, segment, attribute, strategy, interrupt = struct.unpack_from(
        "<5H", bios, at)
    name = bios[at + 10:at + 18].decode("cp437")
    walked.append((name, attribute, strategy, interrupt))
    if offset == 0xFFFF:
        break
    if segment != 0x70:
        bad("the link out of %s points at segment %04X, not 70h"
            % (name.strip(), segment))
        break
    at = offset

if len(walked) != len(wanted):
    bad("the chain has %d devices, not %d" % (len(walked), len(wanted)))
else:
    ok("the chain runs through all %d devices and ends -1" % len(walked))

for (name, attribute, strategy, interrupt), (want_name, want_att) in zip(
        walked, wanted):
    what = want_name.strip() if want_name else "the disk device"
    if want_name is not None and name != want_name:
        bad("%s is named %r" % (what, name))
        continue
    if attribute != want_att:
        bad("%s has the attributes %04X, not %04X"
            % (what, attribute, want_att))
        continue
    if not 0 < strategy < len(bios) or not 0 < interrupt < len(bios):
        bad("%s points its entries outside the BIOS" % what)
        continue
    ok("%-14s attributes %04X, strategy %04X, interrupt %04X"
       % (what, attribute, strategy, interrupt))

# Every device shares one strategy entry, which is what saves the packet.
entries = set(s for _, _, s, _ in walked)
if len(entries) == 1:
    ok("all of them share the one strategy entry")
else:
    bad("the devices have %d different strategy entries" % len(entries))

# The disk device's header carries the number of units where the other
# devices carry a name.
units = struct.unpack_from("<B", bios, drvmax)[0]
if units == 4:
    ok("the disk device has %d units, as DRVMAX says" % units)
else:
    bad("DRVMAX says %d units" % units)

# The BDS chain: one per drive, the last one ending -1.
at = struct.unpack_from("<H", bios, start_bds)[0]
count = 0
while count < 8:
    offset, segment = struct.unpack_from("<2H", bios, at)
    count += 1
    if offset == 0xFFFF:
        break
    if segment != 0x70:
        bad("a BDS link points at segment %04X" % segment)
        break
    at = offset
if count == 4:
    ok("the BDS chain is four drives long and ends -1")
else:
    bad("the BDS chain is %d drives long" % count)

sys.exit(rc)
PY
