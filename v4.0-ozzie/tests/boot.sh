#!/bin/sh
# Start machines from our BIOS and see what the system does.
#
# checkobj.py says our three modules are the bytes MASM made of them, which is
# the strongest thing a comparison can say and still says nothing about
# whether the result runs.  This is the other kind of test, and it starts two
# machines, because there are two builds:
#
#   * bin/IBMBIO.COM, the release as it was written.  It does not start on
#     this machine and Microsoft's own IBMBIO.COM does not either: both reach
#     the kernel's banner and panic in the same line.  So the two diskettes
#     are started and the screens held against each other -- the conversion
#     has to fail exactly where the original fails.
#   * bin/IBMBIOQ.COM, the same with the three things this machine wants --
#     four Sense Interrupt Status commands after a reset of the 765, 300 kbps
#     rather than 250, and the A20 gate closed.  convert.py's table says what
#     goes wrong without each.  That one starts, so it is driven: the date and
#     the time AUTOEXEC.BAT asks for, a DIR, the kernel's CP/M call at offset
#     5 through tests/call5.asm, and SM, the session manager this release
#     exists for.
#
# Little of what reaches the screen is ours -- the banners and the panic are
# IBMDOS.COM's, the kernel we have no source for, and the listing is
# COMMAND.COM's -- but everything that had to work for them to be printed is.
# The boot sector reads IBMBIO.COM and jumps into it; the BIOS sizes memory,
# installs its interrupts and initialises the console and the disk drivers;
# the disk driver reads all 49324 bytes of IBMDOS.COM and then COMMAND.COM a
# sector at a time; every character goes out through src/IBMMTCON.ASM and
# every keystroke comes in through it.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

# For tests/call5.asm, which is this test's own and not the release's.
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

OUT=${TMPDIR:-/tmp}/ozzieboot.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

# Waiting for the guest, as v4.0's tests do it: the monitor is asked for the
# text screen, and what comes back is read.  A test that waited a length of
# time instead would have to wait the worst case every time.
TIMEOUT=${TIMEOUT:-90}
_shots=0
snap() {
    # A dump of its own each time: the monitor writes the file when it gets
    # round to it, and a name that is used twice is a file that can be read
    # while the last write is still in it.
    _shots=$((_shots + 1))
    _shot=$OUT/shot.$_shots
    echo "pmemsave 0xb8000 4000 \"$_shot\""
    _n=0
    while [ "$(wc -c < "$_shot" 2>/dev/null || echo 0)" -ne 4000 ]; do
        _n=$((_n + 1))
        [ "$_n" -gt 60 ] && return
        sleep 0.05
    done
    python3 -I tests/screen.py "$_shot" > "$SEEN"
    rm -f "$_shot"
}

# await TEXT: until TEXT is on the screen.  Giving up is not an error here --
# the checks below say what was missing, and they say it better.
await() {
    _i=0
    while [ "$_i" -lt $((TIMEOUT * 4)) ]; do
        snap
        grep -qF -e "$1" "$SEEN" && return
        _i=$((_i + 1))
        sleep 0.2
    done
    echo "$0: waited ${TIMEOUT}s for \"$1\" on the screen" >&2
}

# The release as it was written, and the diskette Microsoft shipped, which
# should leave the same screen.
./create_image.sh "$OUT/ours.img" bin/IBMBIO.COM >/dev/null
cp bin/DRDOS1_IMD.img "$OUT/theirs.img"

asitwas() {
    SEEN=$OUT/$2.txt
    {
        await "HardErr"
        echo quit
    } | "$QEMU" -rtc base=localtime -m 640 \
                -drive file="$OUT/$1",format=raw,if=floppy,index=0 \
                -display none -monitor stdio >/dev/null 2>&1 || true
    # The firmware's own lines go: SeaBIOS and iPXE print addresses that are
    # not the same twice.  The system's first line is the BIOS's.
    sed -n '/Internal Work/,$p' "$OUT/$2.txt" | sed '/^$/d' > "$OUT/$2.screen"
}

asitwas ours.img ours
asitwas theirs.img theirs

echo "--- Microsoft's IBMBIO.COM"
sed 's/^/   /' "$OUT/theirs.screen"
echo "--- ours, as the release was written"
sed 's/^/   /' "$OUT/ours.screen"

rc=0
echo "--- checks"
for text in "Internal Work #2.06 - May 25, 1984" "MS-DOS version 4.00" \
            "Copyright 1981,82,83,84 Microsoft Corp."; do
    if grep -qF "$text" "$OUT/ours.screen"; then
        echo "ok      $text"
    else
        echo "MISSING $text"
        rc=1
    fi
done
if [ ! -s "$OUT/theirs.screen" ]; then
    echo "WRONG   the release's own diskette printed nothing to compare with"
    rc=1
elif cmp -s "$OUT/ours.screen" "$OUT/theirs.screen"; then
    echo "ok      it stops where Microsoft's own build stops, to the line"
else
    echo "WRONG   the two screens are not the same:"
    diff "$OUT/theirs.screen" "$OUT/ours.screen" | sed 's/^/        /'
    rc=1
fi

# And the build that runs: driven through AUTOEXEC.BAT, a DIR and the session
# manager.
./create_image.sh "$OUT/qemu.img" bin/IBMBIOQ.COM >/dev/null
# tests/call5.asm goes on that disk: the kernel's other door, which only this
# build can reach.  It is copied after create_image.sh has written the BIOS,
# because that is done by offset and wants IBMBIO.COM at the front of the
# data area.
$FASM tests/call5.asm "$OUT/CALL5.COM" >/dev/null
mcopy -o -i "$OUT/qemu.img" "$OUT/CALL5.COM" ::CALL5.COM
SEEN=$OUT/q.txt
{
    await "Enter new date"
    echo "sendkey ret"
    await "Current time is"
    echo "sendkey ret"
    await "path a"
    # Before DIR scrolls them off the top: the interpreter's banner and the
    # two questions AUTOEXEC.BAT asked.
    cp "$SEEN" "$OUT/early.screen"
    for k in d i r ret; do echo "sendkey $k"; sleep 0.1; done
    await "File(s)"
    cp "$SEEN" "$OUT/dir.screen"
    for k in c a l l 5 ret; do echo "sendkey $k"; sleep 0.1; done
    await "and back from it"
    cp "$SEEN" "$OUT/call5.screen"
    for k in s m ret; do echo "sendkey $k"; sleep 0.1; done
    await "SESSION MANAGER"
    cp "$SEEN" "$OUT/sm.screen"
    echo "sendkey f7"
    await "Command v. 4.00"
    cp "$SEEN" "$OUT/session.screen"
    echo quit
} | "$QEMU" -rtc base=localtime -m 640 \
            -drive file="$OUT/qemu.img",format=raw,if=floppy,index=0 \
            -display none -monitor stdio >/dev/null 2>&1 || true

for what in early dir call5 sm session; do
    echo "--- the screen at $what"
    [ -s "$OUT/$what.screen" ] && sed '/^$/d;s/^/   /' "$OUT/$what.screen"
done

echo "--- checks"
check() {
    # printf, not echo: a name with a backslash in it is a name this shell's
    # echo reads as an escape, and a:\command.com cut the line short.
    if [ -s "$OUT/$1.screen" ] && grep -qF -e "$2" "$OUT/$1.screen"; then
        printf 'ok      %s: %s\n' "$2" "$3"
    else
        printf 'MISSING %s\n' "$2"
        rc=1
    fi
}
check early "Command v. 4.00" "COMMAND.COM was read off the disk and EXECed"
check early "Current date is" "the kernel dispatches and the console driver writes"
check dir "A:\\>dir" "the date and the time went in through the keyboard"
check dir "IBMBIO   COM    12363" "DIR read the root directory, our own BIOS in it"
check dir "File(s)" "and ran to the end of the listing"
check call5 "CALL 5: yes" "the kernel's other door answers: the CP/M call at 5, through the wrap at the top of twenty address lines"
check call5 "and back from it" "and came back, so the kernel re-ordered the stack as if an interrupt had been used"
check sm "Microsoft SESSION MANAGER Ver 1.00" "the session manager started"
check sm "a:\\command.com" "and found the programs SM.INI defines"
check session "A:\\>" "and F7 put a shell in a session of its own"

exit $rc
