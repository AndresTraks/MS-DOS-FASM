#!/bin/sh
# Check that CONFIG.SYS is read and that an installable device driver works.
#
# DOS 2.0's own new feature, and nothing in the release exercises it: none of
# the utilities is a device driver, so the DEVICE= line and the device list a
# driver is linked into had never been used here.  source/TESTDEV.ASM is the
# smallest driver that shows the path works, and tests/CONFIG.SYS loads it
# along with BUFFERS, FILES, and a line that is not a command at all.
#
# What the screen has to show, in order:
#
#   * Unrecognized command in CONFIG.SYS, for the line that is not one.  The
#     rest of the file still has to be obeyed, which is the point of putting
#     it in the middle.
#   * TESTDEV loaded, printed by the driver's own init.  SYSINIT found the
#     line, loaded the file, called the driver and took its break address.
#   * HELLO FROM THE DRIVER, from ECHO redirected to TESTDEV.  DOS linked the
#     header into its device list, resolved the name, and sent a write down to
#     the driver, which put the bytes on the screen itself.
#
# BUFFERS and FILES leave no trace on the screen.  What they do is move the
# first free paragraph, and so everything loaded after them: with this file
# COMMAND's program header goes from 0583 to 07E7, which is the 9792 bytes
# that eighteen more buffers and seven more files come to.
set -e
cd "$(dirname "$0")/.."

./assemble.sh >/dev/null

exec ./runtest.sh -t 40 -f tests/CONFIG.SYS -f bin/TESTDEV.SYS \
     -e "Unrecognized command in CONFIG.SYS" \
     -e "TESTDEV loaded" \
     -e "HELLO FROM THE DRIVER" \
     -e "DONE" tests/config.bat
