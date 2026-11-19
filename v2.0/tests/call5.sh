#!/bin/sh
# Check that a program can ask the system for something the CP/M way.
#
# There are two doors into the kernel.  INT 21H with the function in AH is the
# one every MS-DOS program uses; a CALL 5 with the function in CL is the one a
# program carried over from CP/M uses, and the kernel keeps it -- MISC.ASM
# writes a long call at offset 5 of the program's base and leaves a long jump
# to its dispatcher at 0:00C0.  The first of those addresses is a megabyte
# above the second, so the wrap at the top of an 8088's twenty address lines
# is the mechanism that joins them.
#
# Nothing else in this release goes through that door, which is why it could
# be dead for as long as it was: a modern BIOS leaves the A20 gate open, the
# call lands a megabyte up in nothing, and the machine is gone.  IO.ASM closes
# the gate at HWINIT, under A20OFF.
#
# tests/call5.asm asks for the same thing through each door in turn.  All
# three of its lines have to come out, and the batch file has to get to the
# end: a machine that has run off does not echo DONE.
set -e
cd "$(dirname "$0")/.."

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

OUT=${TMPDIR:-/tmp}/call5.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

$FASM tests/call5.asm "$OUT/CALL5.COM" >/dev/null

printf '\n======== both doors into the kernel\n'
./runtest.sh -t 30 -f "$OUT/CALL5.COM" -e DONE tests/call5.bat > "$OUT/log" 2>&1 \
    || { sed -n '/--- screen/,/--- directory/p;/^MISSING/p' "$OUT/log"; \
         echo "FAIL: the run did not reach the end of the batch file" >&2; \
         exit 1; }
sed -n '/--- screen/,/--- directory/p' "$OUT/log"

fail=0
for text in "INT 21H: yes" "CALL 5: yes" "and back from it"; do
    if grep -qF "$text" "$OUT/log"; then
        printf 'ok      %s\n' "$text"
    else
        printf 'MISSING %s\n' "$text"
        fail=1
    fi
done
if [ $fail -eq 0 ]; then
    printf '\n======== the CP/M entry answers and comes back\n'
else
    printf '\n======== the CP/M entry is not answering\n' >&2
fi
exit $fail
