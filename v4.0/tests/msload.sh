#!/bin/sh
# Check MSLOAD, the second stage of the boot, and the boot record structure
# it reads the disk through.
#
# MSLOAD is the first three sectors of IO.SYS.  The boot sector reads exactly
# IBMLOADSIZE of them -- BOOTFORM.INC sets that to 3, and MSBOOT.ASM has its
# own copy of the number -- and jumps to the first, so the program has to fit
# in them, and nothing in the source says so: MASM would have assembled a
# fourth sector's worth without a word and the machine would have jumped into
# whatever followed.
#
# The rest of this is about BOOTFORM.INC.  It declares the boot record as a
# structure, and the conversion had to take the field names out of MASM's
# global namespace and into fasm's structure, where a field that reserves the
# wrong number of bytes carries every field after it along and nothing
# complains.  There is a way to catch that here: MSBOOT.ASM lays the same
# record out itself, field by field, and tests/msboot.sh has already held
# that against the bytes Microsoft's own build left in INC/BOOT.INC.  So each
# field offset is read out of the structure and used to read the boot sector,
# and what comes out has to be what the boot sector says is there.
set -e
cd "$(dirname "$0")/.."

./assemble.sh >/dev/null

OUT=${TMPDIR:-/tmp}/msload.$$
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

rc=0

# The size of MSLOAD against the number of sectors the boot sector reads.
python3 - "$HERE/bin/MSLOAD.COM" "$HERE/src/INC/BOOTFORM.INC" <<'PY' || rc=1
import re
import sys
size = len(open(sys.argv[1], "rb").read())
source = open(sys.argv[2]).read()
sectors = int(re.search(r"(?m)^IBMLOADSIZE\s+equ\s+(\d+)", source).group(1))
room = sectors * 512
print("ok      MSLOAD is %d bytes, and the boot sector reads %d" %
      (size, room) if size <= room else
      "MISSING MSLOAD is %d bytes and the boot sector reads only %d"
      % (size, room))
sys.exit(0 if size <= room else 1)
PY

# The boot record structure, field by field, against the boot sector.
cat > "$OUT/fields.asm" <<EOF
include '$HERE/src/INC/BOOTFORM.INC'
dw sizeof.EXT_IBMBOOT_HEADER, sizeof.EXT_BPB_INFO
dw EXT_IBMBOOT_HEADER.EXT_BOOT_JUMP
dw EXT_IBMBOOT_HEADER.EXT_BOOT_OEM
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_BYTESPERSECTOR
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_SECTORSPERCLUSTER
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_RESERVEDSECTORS
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_NUMBEROFFATS
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_ROOTENTRIES
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_TOTALSECTORS
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_MEDIADESCRIPTOR
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_SECTORSPERFAT
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_SECTORSPERTRACK
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_HEADS
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_HIDDENSECTOR
dw EXT_IBMBOOT_HEADER.EXT_BOOT_BPB.EBPB_BIGTOTALSECTORS
dw EXT_IBMBOOT_HEADER.EXT_PHYDRV
dw EXT_IBMBOOT_HEADER.EXT_CURHD
dw EXT_IBMBOOT_HEADER.EXT_BOOT_SIG
dw EXT_IBMBOOT_HEADER.EXT_BOOT_SERIAL
dw EXT_IBMBOOT_HEADER.EXT_BOOT_VOL_LABEL
dw EXT_IBMBOOT_HEADER.EXT_SYSTEM_ID
dw BOOT_SIZE, BOOT_SIGNATURE
EOF
$FASM "$OUT/fields.asm" "$OUT/fields.bin" >/dev/null

python3 - "$OUT/fields.bin" src/INC/BOOT.INC <<'PY' || rc=1
import re
import struct
import sys

offsets = struct.unpack("<24H", open(sys.argv[1], "rb").read())
(header_size, bpb_size, jump, oem, bytes_per_sector, sectors_per_cluster,
 reserved, number_of_fats, root_entries, total_sectors, media,
 sectors_per_fat, sectors_per_track, heads, hidden, big_total, phydrv,
 curhd, signature, serial, volume, system_id, boot_size,
 boot_signature) = offsets

sector = bytearray()
for line in open(sys.argv[2]):
    for byte in re.findall(r"\b0?([0-9A-Fa-f]{2})H\b", line):
        sector.append(int(byte, 16))

def word(at):
    return struct.unpack_from("<H", sector, at)[0]

def dword(at):
    return struct.unpack_from("<I", sector, at)[0]

# What MSBOOT.ASM declares at each of these, which tests/msboot.sh has
# already shown to be what Microsoft's build produced.
wanted = [
    ("the record is 62 bytes, ending with the system id", header_size, 62),
    ("the BPB inside it is 25", bpb_size, 25),
    ("the jump is the first three bytes", jump, 0),
    ("the OEM name is at 3", oem, 3),
    ('the OEM name is "MSDOS4.0"', bytes(sector[oem:oem + 8]), b"MSDOS4.0"),
    ("bytes per sector is 512", word(bytes_per_sector), 512),
    ("sectors per cluster is 8", sector[sectors_per_cluster], 8),
    ("reserved sectors is 1", word(reserved), 1),
    ("number of FATs is 2", sector[number_of_fats], 2),
    ("root entries is 512", word(root_entries), 512),
    ("total sectors is 4*17*305-1", word(total_sectors), 4 * 17 * 305 - 1),
    ("the media byte is F8", sector[media], 0xF8),
    ("sectors per FAT is 8", word(sectors_per_fat), 8),
    ("sectors per track is 17", word(sectors_per_track), 17),
    ("heads is 4", word(heads), 4),
    ("hidden sectors is the dword 1", dword(hidden), 1),
    ("the 32 bit sector count is 0", dword(big_total), 0),
    ("the physical drive is 80", sector[phydrv], 0x80),
    ("the current head is 0", sector[curhd], 0),
    ("the extended signature is 41", sector[signature], 41),
    ("the serial number is the dword 0", dword(serial), 0),
    ("the label is \"NO NAME    \"", bytes(sector[volume:volume + 11]),
     b"NO NAME    "),
    ("the system id is \"FAT12   \"",
     bytes(sector[system_id:system_id + 8]), b"FAT12   "),
    ("a sector is 512 bytes", boot_size, 512),
    ("55 AA closes it", bytes(sector[boot_signature:boot_signature + 2]),
     b"\x55\xaa"),
]

bad = 0
for what, got, want in wanted:
    if got != want:
        print("MISSING %s: got %r, wanted %r" % (what, got, want))
        bad += 1
if bad:
    sys.exit(1)
print("ok      every field of the boot record reads what MSBOOT.ASM put"
      " there (%d of them)" % len(wanted))
PY

exit $rc
