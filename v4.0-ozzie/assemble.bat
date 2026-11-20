@ECHO OFF
REM Build the BIOS of the Multitasking MS-DOS 4.0 beta -- assemble.sh is the
REM one with the prose in it.
REM
REM FASM is fasm.exe and PYTHON the Python that runs sysinit.py.  Either can
REM be set before this is called.
CD /D "%~dp0"
IF NOT DEFINED FASM SET FASM=..\fasmw17332\FASM.EXE
IF NOT DEFINED PYTHON SET PYTHON=python

REM Each module alone first, laid down the way MASM did, so that checkobj.py
REM can hold it against the object MASM made of it: IBMBIO, the BIOS proper;
REM IBMMTCON, the console driver with the eight virtual screens in it; and
REM IBMDSK, the floppy and fixed disk drivers.
%FASM% src\BIOLNK.ASM bin\IBMBIO.BIN
%FASM% src\MTCLNK.ASM bin\IBMMTCON.BIN
%FASM% src\DSKLNK.ASM bin\IBMDSK.BIN

REM And the whole BIOS: the three modules laid out where LINK put them, with
REM SYSINITSEG -- the SYSINIT program, whose source was never published --
REM resolved out of SYSINI.OBJ and SYSIMES.OBJ.  This one is bootable, and
REM 12363 bytes is the length of the IBMBIO.COM Microsoft shipped.
%PYTHON% -I sysinit.py
%FASM% src\BIOSLNK.ASM bin\IBMBIO.COM

REM And the same again with the three things this machine wants, which is the
REM build that starts -- see src\QEMULNK.ASM.
%FASM% src\QEMULNK.ASM bin\IBMBIOQ.COM
