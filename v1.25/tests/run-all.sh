#!/bin/sh
# Everything this tree can say about itself, in one run: about five minutes.
#
# The two checkers first, because they are seconds and they read the
# conversion against the release's own text rather than running anything:
#
#   * checkscp.py, the four spellings the SCP assembler's dialect means and
#     fasm does not -- JP for an unconditional jump, DS for storage, DM for a
#     message with its last byte marked, and a JMP that is always three bytes.
#   * checkassume.py, the override MASM wrote out of an ASSUME and the offset
#     of every structure field, in the two files that are MASM.
#
# Then the three tests, each of which boots a machine:
#
#   * asm.sh assembles a program with ASM.COM, the Seattle Computer Products
#     assembler this release ships, converts the hex with HEX2BIN.COM and runs
#     what comes out.
#   * trans.sh translates a Z80 program with TRANS.COM and sends it through
#     the same two, so all three of the release's tools run in one chain.
#   * dos.sh takes a file round the system -- copy, type, rename, list, copy,
#     erase -- which is the kernel's FCB calls and COMMAND.COM's own commands.
set -e
cd "$(dirname "$0")/.."

fail=0

printf '\n======== the build\n'
./assemble.sh

printf '\n======== checkscp.py\n'
python3 -I checkscp.py || fail=1

printf '\n======== checkassume.py\n'
python3 -I checkassume.py || fail=1

for t in asm trans dos; do
    printf '\n======== tests/%s.sh\n' "$t"
    ./tests/$t.sh || fail=1
done

if [ $fail -eq 0 ]; then
    printf '\n======== all passed\n'
else
    printf '\n======== something failed\n' >&2
fi
exit $fail
