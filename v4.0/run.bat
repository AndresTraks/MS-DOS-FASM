@ECHO OFF
REM Start a machine from the disk create_image.bat makes, with the programs on
REM it -- run.sh is the one with the prose in it.
REM
REM create_image.bat makes the system disk and nothing else, which is what the
REM tests want of it.  A machine driven by hand wants the programs as well, so
REM they go on here: the utilities under src\CMD, the drivers under src\DEV and
REM EMM386.COM under src\MEMM, in the order assemble.bat builds them.  A driver
REM is loaded by a DEVICE= line in CONFIG.SYS, which this disk has none of; it
REM is here to be named by one.  EMM386.COM has nothing to talk to on this
REM disk -- the driver it asks is one of the things here that cannot be built,
REM being C -- so what it says is that the driver is not installed.
CD /D "%~dp0"
IF NOT DEFINED QEMU SET QEMU=C:\Progra~1\qemu\qemu-system-i386.exe
IF NOT DEFINED IMGEN SET IMGEN=..\fat_imgen-2.2.4\fat_imgen.exe
IF NOT DEFINED PYTHON SET PYTHON=python

CALL create_image.bat
IF ERRORLEVEL 1 EXIT /B 1

%IMGEN% -m -i bin\MORE.COM -f msdos.img
%IMGEN% -m -i bin\SORT.EXE -f msdos.img
%IMGEN% -m -i bin\FIND.EXE -f msdos.img
%IMGEN% -m -i bin\LABEL.COM -f msdos.img
%IMGEN% -m -i bin\TREE.COM -f msdos.img
%IMGEN% -m -i bin\COMP.COM -f msdos.img
%IMGEN% -m -i bin\EXE2BIN.EXE -f msdos.img
%IMGEN% -m -i bin\RECOVER.COM -f msdos.img
%IMGEN% -m -i bin\DISKCOMP.COM -f msdos.img
%IMGEN% -m -i bin\DISKCOPY.COM -f msdos.img
%IMGEN% -m -i bin\EDLIN.COM -f msdos.img
%IMGEN% -m -i bin\SYS.COM -f msdos.img
%IMGEN% -m -i bin\CHKDSK.COM -f msdos.img
%IMGEN% -m -i bin\XCOPY.EXE -f msdos.img
%IMGEN% -m -i bin\FORMAT.COM -f msdos.img
%IMGEN% -m -i bin\DEBUG.COM -f msdos.img
%IMGEN% -m -i bin\GRAFTABL.COM -f msdos.img
%IMGEN% -m -i bin\MODE.COM -f msdos.img
%IMGEN% -m -i bin\ASSIGN.COM -f msdos.img
%IMGEN% -m -i bin\NLSFUNC.EXE -f msdos.img
%IMGEN% -m -i bin\APPEND.EXE -f msdos.img
%IMGEN% -m -i bin\PRINT.COM -f msdos.img
%IMGEN% -m -i bin\FASTOPEN.EXE -f msdos.img
%IMGEN% -m -i bin\KEYB.COM -f msdos.img
%IMGEN% -m -i bin\GRAPHICS.COM -f msdos.img
%IMGEN% -m -i bin\SHARE.EXE -f msdos.img
%IMGEN% -m -i bin\IFSFUNC.EXE -f msdos.img
%IMGEN% -m -i bin\DRIVER.SYS -f msdos.img
%IMGEN% -m -i bin\ANSI.SYS -f msdos.img
%IMGEN% -m -i bin\VDISK.SYS -f msdos.img
%IMGEN% -m -i bin\DISPLAY.SYS -f msdos.img
%IMGEN% -m -i bin\PRINTER.SYS -f msdos.img
%IMGEN% -m -i bin\RAMDRIVE.SYS -f msdos.img
%IMGEN% -m -i bin\SMARTDRV.SYS -f msdos.img
%IMGEN% -m -i bin\MKCNTRY.EXE -f msdos.img
%IMGEN% -m -i bin\XMAEM.SYS -f msdos.img
%IMGEN% -m -i bin\XMA2EMS.SYS -f msdos.img
%IMGEN% -m -i bin\KEYBOARD.SYS -f msdos.img
%IMGEN% -m -i bin\EGA.CPI -f msdos.img
%IMGEN% -m -i bin\LCD.CPI -f msdos.img
%IMGEN% -m -i bin\EMM386.COM -f msdos.img

REM and the entries those left get the same tidying create_image.bat gives the
REM system's, so that the disk is one DOS 4 could have written.
%PYTHON% dosdir.py msdos.img

IF NOT EXIST %QEMU% (
    ECHO %QEMU% not found. Please install QEMU.
) ELSE (
    %QEMU% -rtc base=localtime -drive file=msdos.img,format=raw,if=floppy,index=0
)
