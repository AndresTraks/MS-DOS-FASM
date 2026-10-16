#!/bin/sh
# Run the quick tests.  Each line is one boot, so the lot takes a few minutes.
#
# BIGCOPY is left out: it copies 70K through a driver that goes a sector at a
# time and takes several minutes on its own.  To run it:
#
#       python3 -c "open('big.dat','wb').write(bytes((i*7)&0xff for i in range(70000)))"
#       ./runtest.sh -t 420 -f big.dat -e "1 File(s) copied" tests/bigcopy.bat
#
# and compare test-out against big.dat with -g B.TMP.
#
# profil.bat is left out for the same reason: it assembles and links the
# profiler on the system before it can run it, which takes about nine
# minutes.  tests/profil.sh runs it and checks the .PRF that comes out.
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

# Two boots of its own, and it has to compare what DOS says against the clock
# of this machine, so it is a script rather than a line here.
./tests/clock.sh || fail=1

# Needs a driver built and two files on the image, and has a good deal to
# say about why, so it is a script as well.
./tests/config.sh || fail=1

if [ $fail -eq 0 ]; then
    printf '\n======== all passed\n'
else
    printf '\n======== something failed\n' >&2
fi
exit $fail
