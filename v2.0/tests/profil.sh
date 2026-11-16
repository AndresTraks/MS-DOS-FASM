#!/bin/sh
# Profile a program with the profiler and decode what it wrote.
#
# This is the end to end test of PROFIL.ASM and of source/PCLOCK_IBM.ASM, the
# clock module for this machine.  The profiler loads SPIN.COM, runs it, counts
# where the processor was every 400 microseconds and writes a SPIN.PRF; this
# reads that file back and checks it.  The counts are the evidence, and they
# exist only if the clock interrupt fired at the rate asked for, CLK_INTER
# classified CS:IP and LEAVE_INT's EOI let the next interrupt through -- and
# PROFIL could only write the file at all because CLOCKOFF put the clock back
# first.
#
# It used to build the profiler before it could run it, on the system under
# test: MASM on the clock module, LINK on it and the released PROFIL.OBJ,
# EXE2BIN on the .EXE that came out, about nine minutes of a floppy, which is
# why it was kept out of run-all.sh.  Both modules are FASM now and
# assemble.sh builds the .COM, so all that is left to do here is run it --
# see source/PROLINK.ASM.
#
# It also used to profile EXE2BIN.EXE, which reads a file, and tests/spin.asm
# says why that is a bad idea: with the clock taken over, a profiled program
# that touches a disk takes minutes to get through it.  SPIN.COM only uses the
# processor and is done in a moment.
set -e
cd "$(dirname "$0")/.."

./runtest.sh -t 45 -f tests/profila.txt -f bin/SPIN.COM -g SPIN.PRF \
             -e "SPIN done" -e "Program terminated normally" -e "DONE" \
             tests/profil.bat

# The answers in tests/profila.txt ask for a 400 microsecond sample interval
# and 16 paragraph buckets, so finding them in the header is also how we know
# the answers reached PROFIL through the redirected input.
echo "--- SPIN.PRF"
exec python3 tests/readprf.py --grain 400 --bucket 16 --inprog 8 --spread 2 \
                             test-out/SPIN.PRF
