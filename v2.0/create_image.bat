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

REM The rest of the executables.  Most are Microsoft's, the ones built from
REM source here saying so, and they are what there is to run on the system;
REM all of them together take a sixth of the disk.
REM CHKDSK is ours.  The one Microsoft shipped was built for 2.00 and
REM answers "Incorrect DOS version" to the 2.11 this DOS reports, the same
REM as its SYS -- see source\CHKLINK.ASM.
COPY bin\CHKDSKF.COM CHKDSK.COM > NUL
%IMGEN% -m -i CHKDSK.COM -f %IMAGE%
DEL CHKDSK.COM
%IMGEN% -m -i bin\CREF.EXE -f %IMAGE%
%IMGEN% -m -i bin\DEBUG.COM -f %IMAGE%
REM DISKCOPY is ours, Microsoft's staying in bin to compare against.
COPY bin\DISKCOPF.COM DISKCOPY.COM > NUL
%IMGEN% -m -i DISKCOPY.COM -f %IMAGE%
DEL DISKCOPY.COM
REM EDLIN is ours, Microsoft's staying in bin to compare against.
COPY bin\EDLINF.COM EDLIN.COM > NUL
%IMGEN% -m -i EDLIN.COM -f %IMAGE%
DEL EDLIN.COM
REM EXE2BIN is ours, Microsoft's staying in bin to compare against.
COPY bin\EXE2BINF.EXE EXE2BIN.EXE > NUL
%IMGEN% -m -i EXE2BIN.EXE -f %IMAGE%
DEL EXE2BIN.EXE
REM FC is ours, Microsoft's staying in bin to compare against.
COPY bin\FCF.EXE FC.EXE > NUL
%IMGEN% -m -i FC.EXE -f %IMAGE%
DEL FC.EXE
REM FIND is ours, Microsoft's staying in bin to compare against.
COPY bin\FINDF.EXE FIND.EXE > NUL
%IMGEN% -m -i FIND.EXE -f %IMAGE%
DEL FIND.EXE
%IMGEN% -m -i bin\LINK.EXE -f %IMAGE%
%IMGEN% -m -i bin\MASM.EXE -f %IMAGE%
REM MORE is ours too, Microsoft's staying in bin to compare against.
COPY bin\MOREF.COM MORE.COM > NUL
%IMGEN% -m -i MORE.COM -f %IMAGE%
DEL MORE.COM
REM PRINT is Microsoft's, which refuses this version; ours installs but
REM is not fit to use yet -- see source\PRTLINK.ASM.
%IMGEN% -m -i bin\PRINT.COM -f %IMAGE%
%IMGEN% -m -i bin\PROHST.EXE -f %IMAGE%
REM RECOVER is ours, Microsoft's staying in bin to compare against.
COPY bin\RECOVEF.COM RECOVER.COM > NUL
%IMGEN% -m -i RECOVER.COM -f %IMAGE%
DEL RECOVER.COM
REM SORT is ours, Microsoft's staying in bin to compare against.
COPY bin\SORTF.EXE SORT.EXE > NUL
%IMGEN% -m -i SORT.EXE -f %IMAGE%
DEL SORT.EXE
REM SYS is ours as well, the shipped one refusing this version.
COPY bin\SYSF.COM SYS.COM > NUL
%IMGEN% -m -i SYS.COM -f %IMAGE%
DEL SYS.COM

REM FORMAT is ours and nobody else's: the release has the source but no
REM FORMAT.COM to go with it.
%IMGEN% -m -i bin\FORMAT.COM -f %IMAGE%

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
