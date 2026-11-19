#!/bin/sh
# Everything this tree can say about itself, in one run: the build, the four
# checkers held against the findings they are known to have, and all
# forty-eight tests.  Most of an hour, nearly all of it QEMU boots.
#
# Until this file there was no way to run them together.  Each test was run in
# the commit that wrote it and never again, so a change anywhere was checked
# against whichever test its author thought of -- and the converter is shared
# by thirty programs.  This is the net under that.
#
# The checkers do not pass or fail: each reports what it finds, and what it
# finds is not nought.  Their docstrings say why each remaining line is not a
# finding -- a macro library rewritten rather than translated, a name the
# release pastes together, an override the release wrote against its own
# ASSUME -- so what this holds them to is the count.  A converter change that
# adds one fails the run and says which number moved.
set -e
cd "$(dirname "$0")/.."

OUT=${TMPDIR:-/tmp}/v40all.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
fail=0

printf '======== the build\n'
./assemble.sh > "$OUT/build.log" 2>&1 || { tail -20 "$OUT/build.log"; exit 1; }
tail -1 "$OUT/build.log"

# said <checker> <text that has to be in its output>
said() {
    printf '\n======== %s\n' "$1"
    python3 -I "$1" > "$OUT/$1.log" 2>&1 || true
    grep -v '^$' "$OUT/$1.log" | tail -1
    if grep -qF "$2" "$OUT/$1.log"; then
        printf 'ok      %s\n' "$2"
    else
        printf 'WRONG   expected: %s\n' "$2"
        fail=1
    fi
}

# 184 lines whose instruction changed and 293 files lined up by their
# instructions rather than their lines: DOSMAC's macros, SYSMSG's and
# STRUC.INC's, the names MASM pasted with & , and COMMAND.COM's seven.
said checkcode.py "184 lines carry a different instruction; 293 files are a different length"
# MODE's one call of a routine whose name the conversion had to change.
said checkbare.py "1 operands name a variable and do not read it"
# One program reports six, and only one: IFSFUNC's IFSSESS.ASM, where each of
# the six stands after a Context DS -- DOSMAC's macro for PUSH SS / POP DS --
# which leaves DS on DOSGROUP where the ASSUME still says IFSSEG.  So MASM
# wrote no override and the reference reads the kernel's data segment at the
# offset of a name in IFSSEG.  That is the release's own defect, and the
# conversion has it because the conversion is what MASM assembled; 2b22b1f
# says so, and the release writes CS: by hand on two lines beside them.  Every
# other program has to report nought: a reference that lost its override reads
# whatever DS happens to address, which is the one thing here that breaks a
# machine silently.  The other count each line carries is the release
# disagreeing with its own ASSUMEs, which is its own doing as well.
printf '\n======== checkassume.py\n'
python3 -I checkassume.py > "$OUT/checkassume.log" 2>&1 || true
grep -v '^$' "$OUT/checkassume.log" | tail -1
lost=$(grep -c "^[1-9][0-9]* references lost an override" "$OUT/checkassume.log" || true)
six=$(grep -c "^6 references lost an override" "$OUT/checkassume.log" || true)
if [ "$lost" = 1 ] && [ "$six" = 1 ]; then
    printf 'ok      the six in IFSSESS.ASM and nothing else lost an override\n'
else
    printf 'WRONG   expected one program reporting six, got:\n'
    grep "^[1-9][0-9]* references lost an override" "$OUT/checkassume.log" \
        || printf '        none at all\n'
    fail=1
fi
# 351 structures and the same eight fields: ANSI's one field a byte wider and
# EA.INC's two bytes where the original had one, with the rest renamed.
said checkstruc.py "351 structures compared, 8 fields changed"

# run <test> <what it is>
run() {
    printf '\n======== tests/%s.sh -- %s\n' "$1" "$2"
    ./tests/$1.sh || fail=1
}

# The boot chain, in the order a machine goes through it.
run msboot "the boot sector, against the one MASM built"
run msload "MSLOAD, the three sectors the boot sector reads"
run msbio "the BIOS, walked the way DOS walks it"
run msdos "the kernel, against what MS-DOS 4.00 is known to be"
run boot "a machine started from the disk this builds"
run sys "SYS.COM, and a machine started from what it made"
run call5 "both doors into the kernel, and the A20 line one of them needs"

# The structured statements, which are a macro library and not a program.
run struc "the code INC/STRUC.INC generates"

# The utilities under src/CMD.
run more "MORE.COM"
run sort "SORT.EXE"
run find "FIND.EXE"
run pipe "a pipeline, which is the kernel's doing and COMMAND.COM's"
run label "LABEL.COM"
run tree "TREE.COM"
run comp "COMP.COM"
run exe2bin "EXE2BIN.EXE"
run recover "RECOVER.COM, both ways round"
run diskcomp "DISKCOMP.COM, over two drives"
run diskcopy "DISKCOPY.COM, from one drive to another"
run edlin "EDLIN.COM, through a whole edit"
run chkdsk "CHKDSK.COM, over a good disk and a broken one"
run xcopy "XCOPY.EXE, over a tree with a subdirectory"
run format "FORMAT.COM, over a blank diskette in B:"
run debug "DEBUG.COM, over a program typed into it"
run graftabl "GRAFTABL.COM"
run mode "MODE.COM"
run assign "ASSIGN.COM"
run nlsfunc "NLSFUNC.EXE"
run append "APPEND.EXE"
run print "PRINT.COM"
run fastopen "FASTOPEN.EXE"
run keyb "KEYB.COM"
run graphics "GRAPHICS.COM"
run share "SHARE.EXE, which runs inside the kernel's own data"
run ifsfunc "IFSFUNC.EXE"
run emm386 "EMM386.COM, with a stand-in for the driver it asks"

# The drivers under src/DEV, each loaded by a DEVICE= line.
run driver "DRIVER.SYS"
run ansi "ANSI.SYS"
run vdisk "VDISK.SYS"
run display "DISPLAY.SYS"
run printer "PRINTER.SYS"
run ramdrive "RAMDRIVE.SYS"
run smartdrv "SMARTDRV.SYS"
run xmaem "XMAEM.SYS"
run xma2ems "XMA2EMS.SYS"

# And the three things that are files of data rather than programs.
run country "COUNTRY.SYS, written by MKCNTRY and read back by the system"
run keyboard "KEYBOARD.SYS, read as KEYB reads it and then typed on"
run fonts "EGA.CPI and LCD.CPI, read as DISPLAY.SYS reads them"

if [ $fail -eq 0 ]; then
    printf '\n======== all passed\n'
else
    printf '\n======== something failed\n' >&2
fi
exit $fail
