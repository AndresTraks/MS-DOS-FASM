#!/bin/sh
# Hold the kernel against what MS-DOS 4.00 is known to be.
#
# MSDOS.SYS is fifty-five modules and six segments in one group, gathered by
# MSDOSLNK.ASM: the link file reads every module once per segment class, and
# if one of those passes put a module's bytes in the wrong segment, or missed
# them, nothing says so -- the file still assembles, at a different size.
#
# What can be checked without booting is the shape of the result.  Two kinds
# of thing are worth asking about:
#
#   The layout.  DOSSEG.ASM gives the order of the six and the boundary each
#   starts on; the data segment is overlaid by the initialisation code and
#   has to come out exactly as long as its declarations; and the first three
#   bytes are a jump that has to land on DOSINIT, which the linker put last.
#
#   The structures.  Every field offset in the kernel comes from a STRUC that
#   was rewritten by hand, and a field that moved would still assemble.  The
#   sizes below are the ones MS-DOS 4.00 is documented to have, and they are
#   what a program reading an SFT entry or a DPB through INT 21H/52H relies
#   on, so they are worth more than a self-consistency check.
#
# The dispatcher is the third thing: INT 21H reaches a function through the
# table in MS_TABLE.ASM, and 4.00's last function is 6CH.  Every entry in it
# must point into the code segment.
set -e
cd "$(dirname "$0")/.."

./assemble.sh >/dev/null 2>&1

OUT=${TMPDIR:-/tmp}/msdos.$$
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

# The kernel again, with the numbers the test wants after it.
cat > "$OUT/probe.asm" <<EOF
include '$HERE/src/DOS/MSDOSLNK.ASM'
PROBE:
	dw	START_AT, CONSTANTS_AT, DATA_AT, TABLE_AT, CODE_AT, LAST_AT
	dw	MS_DATA_SIZE, PROBE
	dw	DOSINIT, DISPATCH, VAL1, VAL2
	dw	sizeof.sf_entry, sizeof.dpb, sizeof.dir_entry, sizeof.arena
	dw	sizeof.curdir_list, sizeof.BUFFINFO, sizeof.find_buf
	dw	sizeof.sys_fcb, sizeof.SF
EOF
$FASM "$OUT/probe.asm" "$OUT/probe.bin" 2>&1 | grep -v "stack size error" || true
test -s "$OUT/probe.bin"

python3 - "$OUT/probe.bin" bin/MSDOS.SYS <<'PY' || exit 1
import struct
import sys

probe, kernel = (open(p, "rb").read() for p in sys.argv[1:3])
n = 19
(start_at, constants_at, data_at, table_at, code_at, last_at,
 ms_data_size, probe_at, dosinit, dispatch, val1, val2,
 sf_entry, dpb, dir_entry, arena, curdir_list, buffinfo, find_buf,
 sys_fcb, sf) = struct.unpack_from("<21H", probe, len(probe) - 42)

rc = 0


def ok(what):
    print("ok      %s" % what)


def bad(what):
    global rc
    print("FAIL    %s" % what)
    rc = 1


def says(what, got, want):
    if got == want:
        ok("%s: %s" % (what, want))
    else:
        bad("%s: %s, expected %s" % (what, got, want))


# The probe is the kernel with a trailer, so the kernel proper ends where the
# trailer begins.
says("the kernel ends where the probe begins", len(kernel), probe_at)

# ---- the six segments, in DOSSEG.ASM's order and on its boundaries

order = [("START", start_at), ("CONSTANTS", constants_at), ("DATA", data_at),
         ("TABLE", table_at), ("CODE", code_at), ("LAST", last_at)]
if all(a[1] < b[1] for a, b in zip(order, order[1:])):
    ok("the six segments are laid down in DOSSEG's order: " +
       ", ".join("%s at %04X" % (n, a) for n, a in order))
else:
    bad("the segments are out of order: %s" % order)

for name, at, boundary in (("CONSTANTS", constants_at, 2), ("DATA", data_at, 2),
                           ("LAST", last_at, 16)):
    if at % boundary == 0:
        ok("%s starts on a %d-byte boundary, at %04X" % (name, boundary, at))
    else:
        bad("%s starts at %04X, which is not a multiple of %d"
            % (name, at, boundary))

# ---- the data segment, which the initialisation code is laid on top of

says("the data segment is as long as its declarations",
     table_at - data_at, ms_data_size)

# ---- the three bytes at the front

if kernel[0] == 0xE9:
    # a near jump's displacement is added within the segment, so it wraps
    target = (3 + struct.unpack_from("<H", kernel, 1)[0]) & 0xFFFF
    says("the jump at the front goes to DOSINIT", target, dosinit)
    if last_at <= dosinit < probe_at:
        ok("DOSINIT is in the last segment, where the linker put it")
    else:
        bad("DOSINIT is at %04X, outside the last segment (%04X..%04X)"
            % (dosinit, last_at, probe_at))
else:
    bad("the kernel does not begin with a near jump: %02X" % kernel[0])

# ---- the INT 21H dispatcher

says("the last function in the dispatch table", val2, 0x6C)
says("the last of the CP/M-style calls", val1, 36)
if table_at <= dispatch < code_at:
    ok("the dispatch table is in the table segment, at %04X" % dispatch)
else:
    bad("the dispatch table is at %04X, outside the table segment" % dispatch)

entries = struct.unpack_from("<%dH" % (val2 + 1), kernel, dispatch)
astray = [(i, e) for i, e in enumerate(entries) if not code_at <= e < last_at]
if astray:
    bad("%d dispatch entries do not point into the code segment: %s"
        % (len(astray), astray[:8]))
else:
    ok("all %d dispatch entries point into the code segment" % len(entries))

# ---- the structures, at the sizes 4.00 is documented to have

for what, got, want in (("an SFT entry", sf_entry, 59),
                        ("a drive parameter block", dpb, 33),
                        ("a directory entry", dir_entry, 32),
                        ("a memory arena header", arena, 16),
                        ("a current directory structure", curdir_list, 88),
                        ("a disk buffer header", buffinfo, 20),
                        ("a find-first block", find_buf, 43),
                        ("an internal FCB", sys_fcb, 37),
                        ("an SFT header", sf, 8)):
    says("%s is %d bytes" % (what, want), got, want)

sys.exit(rc)
PY
