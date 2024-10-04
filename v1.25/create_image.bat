SET IMGEN=..\fat_imgen-2.2.4\fat_imgen.exe
SET IMAGE=msdos.img

CALL assemble.bat

%IMGEN% -c -s bin\bootsect.bin -i bin\IO.SYS -f %IMAGE% -F
%IMGEN% -m -i bin\MSDOS.SYS -f %IMAGE%
%IMGEN% -m -i bin\COMMAND.COM -f %IMAGE%
%IMGEN% -m -i bin\ASM.COM -f %IMAGE%
%IMGEN% -m -i bin\HEX2BIN.COM -f %IMAGE%

%IMGEN% -m -i bin\BASIC.COM -f %IMAGE%
%IMGEN% -m -i bin\BASICA.COM -f %IMAGE%
%IMGEN% -m -i bin\CHKDSK.COM -f %IMAGE%
%IMGEN% -m -i bin\COMP.COM -f %IMAGE%
%IMGEN% -m -i bin\DEBUG.COM -f %IMAGE%
%IMGEN% -m -i bin\DISKCOMP.COM -f %IMAGE%
%IMGEN% -m -i bin\DISKCOPY.COM -f %IMAGE%
%IMGEN% -m -i bin\EDLIN.COM -f %IMAGE%
%IMGEN% -m -i bin\EXE2BIN.EXE -f %IMAGE%
%IMGEN% -m -i bin\FORMAT.COM -f %IMAGE%
%IMGEN% -m -i bin\LINK.EXE -f %IMAGE%
%IMGEN% -m -i bin\MODE.COM -f %IMAGE%
%IMGEN% -m -i bin\SETCLOCK.COM -f %IMAGE%
%IMGEN% -m -i bin\SYS.COM -f %IMAGE%

%IMGEN% -m -i bin\*.bas -f %IMAGE%
