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

# MSDOS.ASM includes the modules DOSLINK used to hand to the linker, in that
# order.
$FASM source/MSDOS.ASM bin/MSDOS.SYS

# IO.ASM is the IBM BIOS, and it assembles SYSINIT.ASM in behind itself, which
# is what the original build did by linking SYSINIT.OBJ after the BIOS.
# SKELIO.ASM, the skeleton Microsoft shipped, drives an Altos ACS-86C instead.
$FASM source/IO.ASM bin/IO.SYS

$FASM bootsect.asm bin/bootsect.bin

# An installable character device driver, to have something to put on a
# DEVICE= line.  Not on the image: tests/config.sh is what loads it.
$FASM source/TESTDEV.ASM bin/TESTDEV.SYS

# FORMAT.COM, from FORMAT.ASM, the generic OEM module GENFOR.ASM and the
# messages.  The release shipped no FORMAT.COM, so this is the only one
# there is -- see FORLINK.ASM.
$FASM source/FORLINK.ASM bin/FORMAT.COM

# CHKDSK.COM, from CHKDSK.ASM, the procedures and the messages.  The release
# does ship one, but it was built for 2.00 and refuses the version this DOS
# reports, so create_image.sh uses this one -- see CHKLINK.ASM.
$FASM source/CHKLINK.ASM bin/CHKDSKF.COM

# PRINT.COM, from PRINT_v211.ASM.  Built so the conversion cannot quietly
# stop assembling; it is not on the image yet -- see PRTLINK.ASM.
$FASM source/PRTLINK.ASM bin/PRINTF.COM

# EDLIN.COM, from EDLIN.ASM, the procedures and the messages -- the biggest
# of the utilities, and the same shape as the rest; see EDLLINK.ASM.
$FASM source/EDLLINK.ASM bin/EDLINF.COM

# RECOVER.COM, from RECOVER.ASM and its messages.  The same shape again --
# see RECLINK.ASM.
$FASM source/RECLINK.ASM bin/RECOVEF.COM

# DISKCOPY.COM, from DISKCOPY.ASM and its messages.  CHKDSK's shape, three
# segments in a group and ORG 100H -- see DSKLINK.ASM.
$FASM source/DSKLINK.ASM bin/DISKCOPF.COM

# FC.EXE, laid out like SORT: a group of three segments and a stack outside
# it -- see FCLINK.ASM.
$FASM source/FCLINK.ASM bin/FCF.EXE

# SORT.EXE, an .EXE for the sake of its stack, but with its three segments in
# one group, so the walk lays them out flat -- see SORTLINK.ASM.
$FASM source/SORTLINK.ASM bin/SORTF.EXE

# FIND.EXE, an .EXE as well, but a plainer one: all the code in one segment
# and a stack segment after it -- see FINLINK.ASM.
$FASM source/FINLINK.ASM bin/FINDF.EXE

# EXE2BIN.EXE, the one program here with segments of its own rather than one
# address space to share -- see EXELINK.ASM.
$FASM source/EXELINK.ASM bin/EXE2BINF.EXE

# MORE.COM, from MORE.ASM and its messages.  The release ships one that runs
# here, so this is ours only for the sake of building it -- see MORLINK.ASM.
$FASM source/MORLINK.ASM bin/MOREF.COM

# SYS.COM, from SYS.ASM and its messages.  The release does ship one, but it
# refuses to run on the version this DOS reports; built under another name so
# that Microsoft's stays where it is -- see SYSLINK.ASM.
$FASM source/SYSLINK.ASM bin/SYSF.COM

# COMMAND.COM, from the sixteen modules COMLINK lists.  Built under another
# name so that Microsoft's, which the release shipped and which is useful to
# compare against, stays where it is; create_image.sh puts this one on the
# image as COMMAND.COM.
$FASM source/COMLINK.ASM bin/COMMANDF.COM
