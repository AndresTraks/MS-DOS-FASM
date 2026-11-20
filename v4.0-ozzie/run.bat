@ECHO OFF
REM Start a machine from the disk create_image.bat makes, with our BIOS on it
REM -- run.sh is the one with the prose in it.
REM
REM The disk carries bin\IBMBIOQ.COM, the build with the three things this
REM machine wants in it -- two for QEMU's floppy controller and one for the A20
REM gate.  Without the first two nothing starts, Microsoft's own IBMBIO.COM
REM included; with them the system comes up: COMMAND.COM, AUTOEXEC.BAT, and
REM SM.EXE if you type SM, which is the session manager this release is for.
REM F7 and F8 are the two shells SM.INI defines.
REM
REM Multi-tasking MS-DOS was written for the IBM PC of 1984 and this release
REM says in its README that it had to "hook out the entire disk (both floppy
REM and hard disk) ROM code", so the drivers drive the controller and the DMA
REM chip themselves, against a ROM whose innards they name.  A machine with the
REM IBM ROM in it -- 86Box or PCem -- is the place to run the unchanged build.
REM
REM QEMU is asked for a 640K machine with one diskette in it, which is what
REM this system expects to find.  A second diskette can go in with
REM
REM     SET QEMUFLAGS=-drive file=bin\DRDOS2_IMD.img,format=raw,if=floppy,index=1
REM
REM -- the second of the two the release came on, which carries the BIOS
REM sources themselves.
CD /D "%~dp0"
IF NOT DEFINED QEMU SET QEMU=C:\Progra~1\qemu\qemu-system-i386.exe

CALL create_image.bat
IF ERRORLEVEL 1 EXIT /B 1

IF NOT EXIST %QEMU% (
    ECHO %QEMU% not found. Please install QEMU.
) ELSE (
    %QEMU% -rtc base=localtime -m 640 -drive file=ozzie.img,format=raw,if=floppy,index=0 %QEMUFLAGS%
)
