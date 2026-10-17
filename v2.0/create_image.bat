SET IMGEN=..\fat_imgen-2.2.4\fat_imgen.exe
SET IMAGE=msdos.img

CALL assemble.bat

REM IO.SYS and MSDOS.SYS go on first and in this order: the boot sector reads
REM each from its first cluster onwards and assumes it is contiguous.
%IMGEN% -c -s bin\bootsect.bin -i bin\IO.SYS -f %IMAGE% -F
%IMGEN% -m -i bin\MSDOS.SYS -f %IMAGE%

REM COMMAND.COM is ours, from the sixteen modules COMLINK lists.  Microsoft's
REM is kept in bin to compare against.  fat_imgen copies a file under the name
REM it already has, so it is copied aside first.
COPY bin\COMMANDF.COM COMMAND.COM > NUL
%IMGEN% -m -i COMMAND.COM -f %IMAGE%
DEL COMMAND.COM

REM The rest of the release's executables.  They are Microsoft's -- nothing
REM here is built from source yet -- but they are what there is to run on the
REM system, and all of them together take a sixth of the disk.
%IMGEN% -m -i bin\CHKDSK.COM -f %IMAGE%
%IMGEN% -m -i bin\CREF.EXE -f %IMAGE%
%IMGEN% -m -i bin\DEBUG.COM -f %IMAGE%
%IMGEN% -m -i bin\DISKCOPY.COM -f %IMAGE%
%IMGEN% -m -i bin\EDLIN.COM -f %IMAGE%
%IMGEN% -m -i bin\EXE2BIN.EXE -f %IMAGE%
%IMGEN% -m -i bin\FC.EXE -f %IMAGE%
%IMGEN% -m -i bin\FIND.EXE -f %IMAGE%
%IMGEN% -m -i bin\LINK.EXE -f %IMAGE%
%IMGEN% -m -i bin\MASM.EXE -f %IMAGE%
%IMGEN% -m -i bin\MORE.COM -f %IMAGE%
%IMGEN% -m -i bin\PRINT.COM -f %IMAGE%
%IMGEN% -m -i bin\PROHST.EXE -f %IMAGE%
%IMGEN% -m -i bin\RECOVER.COM -f %IMAGE%
%IMGEN% -m -i bin\SORT.EXE -f %IMAGE%
%IMGEN% -m -i bin\SYS.COM -f %IMAGE%

REM The profiler, which is in pieces: PROFIL.OBJ is Microsoft's, assembled,
REM and the clock module it wants is ours.  PCLOCK_IBM.ASM goes on as
REM PCLOCKPC.ASM because PCLOCK.ASM is taken, by Microsoft's for the Seattle
REM Computer Products machine, and because the name has to fit 8.3 for DOS to
REM see it; fat_imgen copies a file under the name it already has, so it is
REM copied aside first.  tests\profil.bat builds and runs it on the system.
%IMGEN% -m -i bin\PROFIL.OBJ -f %IMAGE%
COPY source\PCLOCK_IBM.ASM PCLOCKPC.ASM > NUL
%IMGEN% -m -i PCLOCKPC.ASM -f %IMAGE%
DEL PCLOCKPC.ASM
