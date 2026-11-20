@ECHO OFF
REM Make a 1440K diskette this system can be started from -- create_image.sh
REM is the one with the prose in it.
REM
REM FORMAT is what would normally lay the boot sector down, and it is one of
REM the programs here that wants a disk to be on already, so the disk is made
REM from this end: fat_imgen writes the file system and bootsect.py puts our
REM own sector over the one it wrote.
REM
REM IO.SYS goes on first and MSDOS.SYS second: the boot sector reads the first
REM two entries of the root directory and expects to find them there, by name.
REM There is no volume label, which would take the first entry.
REM
REM IMGEN, PYTHON and IMAGE can each be set before this is called.
CD /D "%~dp0"
IF NOT DEFINED IMGEN SET IMGEN=..\fat_imgen-2.2.4\fat_imgen.exe
IF NOT DEFINED PYTHON SET PYTHON=python
IF NOT DEFINED IMAGE SET IMAGE=msdos.img

CALL assemble.bat
IF ERRORLEVEL 1 EXIT /B 1

IF EXIST %IMAGE% DEL %IMAGE%
%IMGEN% -c -i bin\IO.SYS -f %IMAGE% -F
%IMGEN% -m -i bin\MSDOS.SYS -f %IMAGE%

REM COMMAND.COM, which SYSINIT EXECs to finish starting the system.
%IMGEN% -m -i bin\COMMAND.COM -f %IMAGE%

REM Our boot sector, which goes on after the format rather than with
REM fat_imgen's -s: what MSBOOT.ASM assembles carries the table the release
REM leaves in the source, for a hard file, and the table on a disk has to be
REM the one the disk was formatted with.  bootsect.py writes the code and
REM keeps the table, which is what FORMAT and SYS do.
%PYTHON% -I bootsect.py %IMAGE% bin\MSBOOT.BIN
IF ERRORLEVEL 1 EXIT /B 1

REM The ten bytes mtools and fat_imgen write after each entry's attribute,
REM which DOS 4 left zero -- see dosdir.py for what reads them.
%PYTHON% dosdir.py %IMAGE%
