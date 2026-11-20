@ECHO OFF
REM Make a diskette this system can be started from, with our own BIOS on it
REM -- create_image.sh is the one with the prose in it.
REM
REM Every other tree here lays its disk down from nothing.  Neither the boot
REM sector of this release nor its FORMAT, SYS and COMMAND.COM are in the
REM sources, so this disk is the one the release came on -- bin\DRDOS1_IMD.img,
REM the first of the two diskettes -- with our IBMBIO.COM written where
REM Microsoft's was.  That is what SYS does, and it can be done in place
REM because the two files are the same length.
REM
REM The BIOS on it is bin\IBMBIOQ.COM, the build with the three things QEMU
REM wants, which is the one that starts.  The release as it was written goes on
REM with
REM
REM     SET BIOS=bin\IBMBIO.COM
REM     create_image.bat
REM
REM and gets as far as the kernel's banner and the panic, which is where
REM Microsoft's own build gets to on this machine.  See src\QEMULNK.ASM.
CD /D "%~dp0"
IF NOT DEFINED PYTHON SET PYTHON=python
IF NOT DEFINED IMAGE SET IMAGE=ozzie.img
IF NOT DEFINED BIOS SET BIOS=bin\IBMBIOQ.COM

CALL assemble.bat

COPY bin\DRDOS1_IMD.img %IMAGE% > NUL

REM Our BIOS where the release's was, which is what SYS does -- see putbios.py.
%PYTHON% -I putbios.py %IMAGE% %BIOS% bin\DISK1\IBMBIO.COM
IF ERRORLEVEL 1 EXIT /B 1
