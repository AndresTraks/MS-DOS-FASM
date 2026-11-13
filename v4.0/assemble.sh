#!/bin/sh
set -e
cd "$(dirname "$0")"

if command -v fasm >/dev/null 2>&1; then
    FASM=fasm
elif command -v wine >/dev/null 2>&1; then
    FASM="wine ../fasmw17332/FASM.EXE"
    WINEDEBUG=${WINEDEBUG:--all}
    export WINEDEBUG
else
    echo "Neither fasm nor wine found. Please install one of them." >&2
    exit 1
fi

mkdir -p bin

# Every program in this release takes its text from MESSAGES/USA-MS.MSG, and
# BUILDMSG, which Microsoft shipped as a binary and not as source, is what
# turned a program's .SKL skeleton into the include file holding it.
# buildmsg.py is that step again -- see the file for the two shapes it has to
# write.  Each skeleton writes one include file per class it declares, beside
# the skeleton, named after it: BOOT.SKL writes BOOT.CL1.
python3 buildmsg.py src/BOOT/BOOT.SKL >/dev/null

# The boot sector.  The release also ships what MASM made of it, as the DB
# statements in INC/BOOT.INC -- FORMAT and SYS include that to write a boot
# sector onto a disk -- so this one can be held against Microsoft's byte for
# byte; tests/msboot.sh does that.
$FASM src/BOOT/MSBOOT.ASM bin/MSBOOT.BIN

# The BIOS's messages: five classes, for the five modules that hold them.
python3 buildmsg.py src/BIOS/MSBIO.SKL >/dev/null

# MSLOAD, the second stage of the boot and the first three sectors of IO.SYS.
# The boot sector reads those three and jumps to them; this walks the FAT to
# read the rest of the BIOS in, so IO.SYS need not be contiguous past its
# first cluster.  tests/msload.sh checks that it still fits in three.
$FASM src/BIOS/MSLOAD.ASM bin/MSLOAD.COM

# The BIOS proper: thirteen modules in two segments -- see MSBIOLNK.ASM.
$FASM src/BIOS/MSBIOLNK.ASM bin/MSBIO.BIN

# IO.SYS is the two of them, one after the other, which is what the original
# build did with "copy /b msload.com+msbio.bin io.sys".
cat bin/MSLOAD.COM bin/MSBIO.BIN > bin/IO.SYS

# The kernel's messages: MSDOS.SKL declares two classes, the divide-overflow
# message the kernel prints on INT 0 and the yes/no letters for INT 24H.
python3 buildmsg.py src/DOS/MSDOS.SKL >/dev/null

# MSDOS.SYS: fifty-five modules and six segments in one group, gathered by
# MSDOSLNK.ASM.  Microsoft's own EndProc check prints a line for each of the
# twelve procedures whose SaveReg and RestoreReg do not pair up inside the
# procedure -- the same twelve as in the release, which does its RestoreReg
# on a shared way out -- so those lines are expected.
$FASM src/DOS/MSDOSLNK.ASM bin/MSDOS.SYS

# The utilities under src/CMD.  Each one is built from its own directory, so
# the INCLUDE path has the shared headers in src/INC first and the utility's
# own directory after it -- which is where its messages are written.  That is
# how MASM found them as well: the build ran in the utility's directory with
# INCLUDE pointing at src/INC.
#
# MORE, the smallest of them: one module, the message retriever, and the
# structured statements in INC/STRUC.INC.
# The skeleton is named after the message class the utility declares, which
# is usually the directory's own name but not always -- LABEL's is LABL.SKL.
# utility <directory> <source> <output> [<skeleton>]
utility() {
    python3 buildmsg.py "src/CMD/$1/${4:-$1}.SKL" >/dev/null
    # A fifth argument is another directory to read includes from, which
    # FORMAT wants for the boot sector's messages.
    if [ "$FASM" = fasm ]; then
        INCLUDE="$PWD/src/INC:$PWD/src/CMD/$1${5:+:$PWD/$5}"
    else
        # fasm.exe reads the path the way Windows writes one.
        win() { printf 'Z:%s' "$(echo "$1" | sed 's|/|\\|g')"; }
        INCLUDE="$(win "$PWD/src/INC");$(win "$PWD/src/CMD/$1")${5:+;$(win "$PWD/$5")}"
    fi
    export INCLUDE
    $FASM "src/CMD/$1/$2.ASM" "bin/$3"
    unset INCLUDE
}

utility MORE MORE MORE.COM

# SORT, the first of them built as an .EXE: CODE, CONST and CSTACK in one
# group, which SORTLNK.ASM lays down as one segment.
utility SORT SORTLNK SORT.EXE

# FIND, an .EXE of two segments and no group, which FINDLNK.ASM lays down in
# turn.
utility FIND FINDLNK FIND.EXE

# COMMAND.COM: thirty-two modules in twelve segments and two groups, which
# COMLNK.ASM lays down as two address spaces over one stretch of output --
# the resident interpreter and the transient part that is read back from the
# file whenever a program has overwritten it.  The release linked the modules
# and ran EXE2BIN over the result; this assembles the whole of it at once, so
# the message retriever, which goes in twice, is read with its own names for
# each of the two copies.  Microsoft's EndProc check prints a line for
# ReadBat, whose SaveReg has no RestoreReg inside the procedure.
utility COMMAND COMLNK COMMAND.COM

# LABEL, a .COM of one segment holding the program, its data and its stack,
# which LABELLNK.ASM lays down in the order LABEL.LNK named the two modules.
utility LABEL LABELLNK LABEL.COM LABL

# TREE, four modules in one segment like LABEL's two, which TREELNK.ASM lays
# down in the order TREE.LNK named them.  It is the second program after
# COMMAND.COM to carry the parser, and the first to be written with the
# structured statements Microsoft's SALUT preprocessor left behind.
utility TREE TREELNK TREE.COM

# COMP, five modules in one segment like TREE's four, which COMPLNK.ASM lays
# down in the order COMP.LNK named them.  It carries the parser as well, and
# reads two files at once to say where they differ.
utility COMP COMPLNK COMP.COM

# EXE2BIN, the step the release's own build ran over a linked .EXE to make a
# .COM of it.  Four segments and no group -- CODE, DATA, STACK, and ZLOAD,
# one byte naming where the file being converted is read -- which E2BLNK.ASM
# lays down in turn.
utility EXE2BIN E2BLNK EXE2BIN.EXE

# RECOVER, four modules in five segments and one group -- DATA, CODE, CONST,
# CSTACK and LASTSEG -- which RECLNK.ASM lays down as one address space, the
# way the group was.  It is the first of the utilities to read and write the
# disk itself, with the kernel's absolute read and write, and the release
# ends its build by running TOOLS/CONVERT over the linked .EXE; DOS reads the
# signature and not the extension, so what comes out here is the MZ image
# under the name the release gives it.
utility RECOVER RECLNK RECOVER.COM

# DISKCOMP, five modules in one segment, CSEG, and no group, which
# DCMPLNK.ASM reads in the order DISKCOMP.LNK names them.  DISKCOMP.ASM's
# ORG 100H is where DOS enters a .COM and nothing but comments and the
# headers stands before it; the release links the five and runs EXE2BIN over
# the result, which is what this writes directly.
utility DISKCOMP DCMPLNK DISKCOMP.COM

# DISKCOPY, five modules in one segment like DISKCOMP's five, which
# DCPYLNK.ASM reads in the order DISKCOPY.LNK names them.  It writes and
# formats as well as reads, so a diskette with no format on it is one it can
# still copy onto.
utility DISKCOPY DCPYLNK DISKCOPY.COM

# EDLIN, five modules in four segments and one group -- CODE, CONST, cstack
# and DATA -- which EDLLNK.ASM lays down as one address space, the way the
# group was, with the stack a segment of its own because EDLIN points SS at
# it by name.  The release ends its build by running TOOLS/CONVERT over the
# linked .EXE, as RECOVER's does, and DOS reads the signature and not the
# extension, so what comes out here is the MZ image under the release's name.
utility EDLIN EDLLNK EDLIN.COM

# SYS, three modules in two segments and no group -- CODE and DATA -- which
# SYSLNK.ASM lays down as two address spaces over one stretch of output, the
# way COMMAND.COM's two groups are.  DATA is not reached through a fixed-up
# segment: BEGIN rounds the end of the code up to the next paragraph and adds
# the PSP, which is why the release could run EXE2BIN over the linked .EXE
# and ship a flat .COM.
utility SYS SYSLNK SYS.COM

# CHKDSK, nine modules in five segments and one group -- data, const, code,
# cstack and lastseg -- which CHKLNK.ASM lays down as one address space, the
# way EDLIN's group is.  The sixth segment, PSP, is outside the group and
# holds nothing: it names the two FCBs DOS leaves in the program's prefix,
# and the reading that gives them their offsets writes nothing.  The release
# ends its build by running TOOLS/CONVERT over the linked .EXE, as EDLIN's
# does, so what comes out here is the MZ image under the release's name.
utility CHKDSK CHKLNK CHKDSK.COM

# XCOPY, three modules in four segments, two of them in a group -- SSEG is
# the stack, DSEG and DSEG_INIT are DGROUP, and CSEG is the code, outside it
# -- which XCPYLNK.ASM lays down as two address spaces, the group and the
# code.  The release links the three and stops: this is an .EXE in its own
# right, with no CONVERT over it.
utility XCOPY XCPYLNK XCOPY.EXE

# FORMAT, seven modules in five segments and no group at all: PSP, data,
# stack, code and End_Of_Memory, in the order DISPLAY.ASM declares them --
# that module is nothing but .SEQ and the five empty declarations, which is
# how MASM was told the order to lay them down in.  FORLNK.ASM makes an
# address space of each.  MSFOR reads the boot sector's message out of
# BOOT.CL1, which the makefile copied from the boot directory, so that
# directory goes on the include path here.  The release ends by running
# TOOLS/CONVERT over the linked .EXE, as CHKDSK's does.
utility FORMAT FORLNK FORMAT.COM FORMAT src/BOOT

# DEBUG, eleven modules in four segments in one group -- code, const, cstack
# and data, in the order DEBUG.ASM declares them -- which DEBLNK.ASM lays
# down as one address space, the way CHKDSK's group is.  All four ask for
# BYTE, so nothing is padded between them.  A_CREATE_BLOCK is the fifth
# segment and the one outside the group: it holds the far routine that issues
# the 1.0 call to make a program prefix, which takes the prefix from CS, and
# DEBUG.ASM says not to move it.  The release ends by running TOOLS/CONVERT
# over the linked .EXE, as CHKDSK's does.
utility DEBUG DEBLNK DEBUG.COM

# GRAFTABL, ten modules in one segment, CSEG, and no group -- so the modules
# are read once, the way TREE's and COMP's are.  CSEG begins where the load
# module does, which for a .COM is the program's own prefix: GRTABHAN's
# org 60H names the place in it the resident handler and its 1K table are
# moved to, and the org 100H after that is where DOS enters.  The release
# links the ten and runs EXE2BIN over the result, which is the flat image
# fasm writes here.
utility GRAFTABL GRTABLNK GRAFTABL.COM

# MODE, sixteen modules in two segments in one group -- PRINTF_CODE, which
# holds the program, and ZSEG, the 512-byte buffer MODECP works the code
# pages through -- which MODELNK.ASM lays down as one address space, the way
# the group was.  The buffer comes last because the program grows it into
# whatever memory is past the end of itself.  Four more segments are ROM,
# VECT, ROM_BIOS and SIGNITURE, which name what the ROM BIOS, the interrupt
# vectors and the EGA hold rather than anything the program lays down: they
# are read in a pass of their own.  PRINTF_CODE begins where the load module
# does, which for a .COM is the program's own prefix: RESCODE describes what
# DOS leaves in it and names the place at 60H the resident serial and printer
# code is moved to, and the org 100H after that is where DOS enters.  The
# release links the sixteen and runs EXE2BIN over the result, which is the
# flat image fasm writes here.
utility MODE MODELNK MODE.COM

# ASSIGN, two modules in one segment, code, and no group -- so the modules
# are read once, the way GRAFTABL's are.  code begins where the load module
# does, which for a .COM is the program's own prefix: ASSGMAIN names that
# start ASSIGN_BASE, to measure from it what to keep, and the org 100H after
# it is where DOS enters.  It hooks interrupt 21H with a handler that maps a
# drive letter in whatever call is being made and hands the call on, and
# keeps the whole of itself resident.  The release links the two and runs
# EXE2BIN over the result, which is the flat image fasm writes here.
utility ASSIGN ASSGLNK ASSIGN.COM

# NLSFUNC, two modules in three segments and no group -- NLS_DATA for the
# buffers and the message text, NLS_INIT_CODE for the code, and STACK -- so
# the modules are read once per segment and each segment is an address space
# of its own, which NLSLNK.ASM lays down in turn.  It reads the country
# information COUNTRY.SYS holds and answers the multiplex interrupt with it,
# keeping the resident part of itself behind.  The release links the two and
# stops: this is an .EXE in its own right.
utility NLSFUNC NLSLNK NLSFUNC.EXE

# APPEND, one module in two segments and no group -- cseg for the program,
# its data and the message tables, and sseg for the stack -- which
# APPENDLNK.ASM lays down in turn.  It keeps the directories a program is to
# look in after its own, and the whole of itself up to end_address stays
# resident on interrupts 2FH and 21H.  The release links the one module and
# stops: this is an .EXE in its own right.
utility APPEND APPENDLNK APPEND.EXE

# PRINT, four modules in four segments, three of them in one group -- Code,
# Data and Stack are DG, and CodeR, the resident part, is outside it -- which
# PRILNK.ASM lays down as two address spaces, the way COMMAND.COM's two
# groups are.  CodeR goes first: PRINT keeps everything up to EndRes resident
# and frees the transient part in DG above it.  The release links the four
# and runs TOOLS/CONVERT over the result, which only renames the .EXE, so the
# MZ image is what comes out here under the release's name.
utility PRINT PRILNK PRINT.COM

# FASTOPEN, five modules in five segments and no group -- STACK, CSEG_MAIN,
# CSEG_OPEN, CSEG_SEEK and CSEG_INIT, in the order FASTSEGS.INC's .seq tells
# LINK to lay them down -- which FOPLNK.ASM lays down as five address spaces
# in turn.  They are separate segments so that the initialisation can write
# whichever cache was not asked for over the other's code and keep the rest
# resident.  The release links the five and stops: this is an .EXE in its own
# right.
utility FASTOPEN FOPLNK FASTOPEN.EXE

# KEYB, ten modules in one segment, CODE, and no group -- so the modules are
# read once, the way GRAFTABL's and ASSIGN's are.  CODE begins where the load
# module does, which for a .COM is the program's own prefix, and KEYB.ASM's
# org 100H is where DOS enters.  It reads a keyboard layout and keeps a
# handler on interrupt 9 that turns a scan code into the character that
# layout asks for, with 2FH so a second copy finds the first and 48H for the
# 101-key enhancements.  The release links the ten and runs EXE2BIN over the
# result, which is the flat image fasm writes here.
utility KEYB KEYBLNK KEYB.COM

# GRAPHICS, thirteen modules in one segment, CODE, and no group -- so the
# modules are read once, the way KEYB's and GRAFTABL's are.  CODE begins
# where the load module does and GRAPHICS.ASM's org 100H is where DOS
# enters.  It hooks interrupt 5, the print-screen key, and prints the screen
# through whichever printer GRAPHICS.PRO describes.  GRCOMMON.ASM, the
# routines both printer modules want, goes into each of them and so into the
# program twice; GRAPHLNK.ASM reads each copy under names of its own.  The
# release links the thirteen and runs EXE2BIN over the result.
utility GRAPHICS GRAPHLNK GRAPHICS.COM
