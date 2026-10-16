#!/bin/sh
# Build the profiler on the system under test and profile a program with it.
#
# This is the end to end test of source/PCLOCK_IBM.ASM, the clock module for
# this machine.  It assembles that module with MASM, links it to the released
# PROFIL.OBJ, converts the result to a .COM with EXE2BIN and runs it on
# EXE2BIN.EXE, then decodes the .PRF that comes out.  Everything but the
# decoding happens on MS-DOS 2.0 itself.
#
# EXE2BIN is handed a file it will refuse ("File cannot be converted").  That
# is deliberate and it does not matter: the point is that the profiled program
# runs, makes its DOS calls and terminates, and that PROFIL survives all of it
# and writes its data.  The counts in the .PRF are the evidence, and they
# exist only if the clock interrupt fired, CLK_INTER classified CS:IP and
# LEAVE_INT's EOI let the next interrupt through -- and PROFIL could only
# write the file at all because CLOCKOFF put the clock back first.
#
# The target has to be a program that terminates the 1.x way, through INT 20h
# or a far return to PSP:0, as EXE2BIN does.  PROFIL loads the program itself
# and gives it a program header built with function 26h, which does not make
# that header current, so a program that exits with function 4Ch goes back to
# COMMAND instead of to PROFIL -- _EXIT in PROC.ASM takes the terminate
# address from CurrentPDB, which is still PROFIL's.  FIND, SORT and the other
# 2.0 utilities do that, and profiling one of them leaves an empty .PRF.  That
# is PROFIL's own limitation, not this system's.
#
# MASM on a floppy is slow, so this takes about nine minutes -- which is why
# it is not in run-all.sh.
set -e
cd "$(dirname "$0")/.."

./runtest.sh -t 520 -f tests/profila.txt -g EXE2BIN.PRF \
             -e "Program terminated normally" -e "DONE" tests/profil.bat

# The answers in tests/profila.txt ask for a 100 microsecond sample interval
# and 16 paragraph buckets, so finding them in the header is also how we know
# the answers reached PROFIL through the redirected input.
echo "--- EXE2BIN.PRF"
exec python3 tests/readprf.py --grain 100 --bucket 16 test-out/EXE2BIN.PRF
