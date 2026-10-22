#!/bin/sh
# Run the quick tests.  Each line is one boot, so the lot takes a few minutes.
#
# BIGCOPY used to be left out, taking several minutes to copy 70K through a
# driver that went a sector at a time.  The driver now takes a whole track in
# one call and the copy is down to about ten seconds, so it runs with the
# rest; the file it copies is made here.
#
# Three tests are left out for taking too long.  tests/profil.sh assembles and
# links the profiler on the system before it can run it, about nine minutes,
# and checks the .PRF that comes out.  tests/format.sh formats a disk with our
# own FORMAT, about three, the bad sector scan reading every allocation unit
# on it, and then uses the disk it made.  tests/bootable.sh formats one too,
# then puts the system on it with SYS and boots a machine from it.
set -e
cd "$(dirname "$0")/.."

fail=0
run() {
    name=$1; shift
    printf '\n======== %s\n' "$name"
    ./runtest.sh "$@" "tests/$name" || fail=1
}

run boot.bat     -t 32 -e "MS-DOS Version" -e "DONE"
run internal.bat -t 45 -g LOG.TXT -e "1 File(s) copied" -e "<DIR>" -e "DONE"
run redirect.bat -t 45 -e "HELLO" -e "File not found" -e "DONE" -g D1.TXT
run exec.bat     -t 50 -e "File not found" -e "Invalid number of parameters" \
                       -e "File name must be specified" -e "DONE"

python3 -c "open('big.dat','wb').write(bytes((i*7)&0xff for i in range(70000)))"
run bigcopy.bat  -t 45 -f big.dat -g B.TMP -e "1 File(s) copied" -e "DONE"
if cmp -s big.dat test-out/B.TMP; then
    echo "ok      B.TMP came back byte for byte"
else
    echo "MISSING B.TMP does not match big.dat"
    fail=1
fi

# Two boots of its own, and it has to compare what DOS says against the clock
# of this machine, so it is a script rather than a line here.
./tests/clock.sh || fail=1

# Needs a driver built and two files on the image, and has a good deal to
# say about why, so it is a script as well.
./tests/config.sh || fail=1

# Makes a disk for the second drive first, so it is a script too.
./tests/twodrive.sh || fail=1

# Makes a disk for SYS to write to, and checks what landed on it.
./tests/sys.sh || fail=1

# Makes a disk for CHKDSK to report on, so its figures can be checked.
./tests/chkdsk.sh || fail=1

# Runs our MORE and Microsoft's over the same file and compares what came
# through, so it needs both on the image and a script of its own.
./tests/more.sh || fail=1

# Builds an .EXE for EXE2BIN to convert, runs the .COM that comes out, and
# compares it with what Microsoft's EXE2BIN makes of the same file.
./tests/exe2bin.sh || fail=1

# Searches one file five ways with our FIND and with Microsoft's, and compares
# the two transcripts.
./tests/find.sh || fail=1

# Sorts one file three ways with our SORT and with Microsoft's, and compares.
./tests/sort.sh || fail=1

# Compares files four ways with our FC and with Microsoft's, and compares what
# the two of them said.
./tests/fc.sh || fail=1

if [ $fail -eq 0 ]; then
    printf '\n======== all passed\n'
else
    printf '\n======== something failed\n' >&2
fi
exit $fail
