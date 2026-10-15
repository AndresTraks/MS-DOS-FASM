SET IMGEN=..\fat_imgen-2.2.4\fat_imgen.exe
SET IMAGE=msdos.img

CALL assemble.bat

REM IO.SYS and MSDOS.SYS go on first and in this order: the boot sector reads
REM each from its first cluster onwards and assumes it is contiguous.
%IMGEN% -c -s bin\bootsect.bin -i bin\IO.SYS -f %IMAGE% -F
%IMGEN% -m -i bin\MSDOS.SYS -f %IMAGE%

REM COMMAND.COM is the one Microsoft shipped. The COMLINK sources for it are
REM still MASM, so there is nothing of ours to put here yet.
%IMGEN% -m -i bin\COMMAND.COM -f %IMAGE%
