@ECHO OFF
REM Build everything in this tree that is made of assembler alone: the boot
REM sector, MSLOAD, the BIOS, the kernel, the utilities under src\CMD, the
REM drivers and data files under src\DEV, the two code page files, and
REM EMM386.COM under src\MEMM.  This is assemble.sh step for step, and that is
REM the one with the prose in it: what each program is, how many modules and
REM segments it has, and what the release's own build did to it after LINK.
REM
REM FASM is fasm.exe and PYTHON is the Python that runs buildmsg.py, which
REM does what BUILDMSG did -- Microsoft shipped that tool as a binary, and
REM every program in the release takes its text from MESSAGES\USA-MS.MSG
REM through a .SKL skeleton, so nothing is built without it.  Either can be
REM set before this is called.
CD /D "%~dp0"
IF NOT DEFINED FASM SET FASM=..\fasmw17332\FASM.EXE
IF NOT DEFINED PYTHON SET PYTHON=python
SET FAILED=

IF NOT EXIST bin MKDIR bin

REM The boot sector, which the release also ships as the DB statements in
REM INC\BOOT.INC, so this one can be held against Microsoft's byte for byte.
CALL :msg src\BOOT\BOOT.SKL
CALL :fasm src\BOOT\MSBOOT.ASM bin\MSBOOT.BIN

REM MSLOAD, the first three sectors of IO.SYS, and the BIOS proper after it.
CALL :msg src\BIOS\MSBIO.SKL
CALL :fasm src\BIOS\MSLOAD.ASM bin\MSLOAD.COM
CALL :fasm src\BIOS\MSBIOLNK.ASM bin\MSBIO.BIN

REM IO.SYS is the two of them one after the other, which is what the original
REM build did with "copy /b msload.com+msbio.bin io.sys".
COPY /B bin\MSLOAD.COM+bin\MSBIO.BIN bin\IO.SYS > NUL

REM MSDOS.SYS: fifty-five modules and six segments in one group.  Microsoft's
REM own EndProc check prints a line for each of the twelve procedures whose
REM SaveReg and RestoreReg do not pair up inside the procedure, so those lines
REM are expected.
CALL :msg src\DOS\MSDOS.SKL
CALL :fasm src\DOS\MSDOSLNK.ASM bin\MSDOS.SYS

REM The utilities under src\CMD.  Each is built from its own directory, so the
REM include path has the shared headers in src\INC first and the utility's own
REM directory after it, which is where its messages are written -- and that is
REM how MASM found them as well.
CALL :utility MORE MORE MORE.COM
CALL :utility SORT SORTLNK SORT.EXE
CALL :utility FIND FINDLNK FIND.EXE
CALL :utility COMMAND COMLNK COMMAND.COM
CALL :utility LABEL LABELLNK LABEL.COM LABL
CALL :utility TREE TREELNK TREE.COM
CALL :utility COMP COMPLNK COMP.COM
CALL :utility EXE2BIN E2BLNK EXE2BIN.EXE
CALL :utility RECOVER RECLNK RECOVER.COM
CALL :utility DISKCOMP DCMPLNK DISKCOMP.COM
CALL :utility DISKCOPY DCPYLNK DISKCOPY.COM
CALL :utility EDLIN EDLLNK EDLIN.COM
CALL :utility SYS SYSLNK SYS.COM
CALL :utility CHKDSK CHKLNK CHKDSK.COM
CALL :utility XCOPY XCPYLNK XCOPY.EXE
CALL :utility FORMAT FORLNK FORMAT.COM FORMAT src\BOOT
CALL :utility DEBUG DEBLNK DEBUG.COM
CALL :utility GRAFTABL GRTABLNK GRAFTABL.COM
CALL :utility MODE MODELNK MODE.COM
CALL :utility ASSIGN ASSGLNK ASSIGN.COM
CALL :utility NLSFUNC NLSLNK NLSFUNC.EXE
CALL :utility APPEND APPENDLNK APPEND.EXE
CALL :utility PRINT PRILNK PRINT.COM
CALL :utility FASTOPEN FOPLNK FASTOPEN.EXE
CALL :utility KEYB KEYBLNK KEYB.COM
CALL :utility GRAPHICS GRAPHLNK GRAPHICS.COM
CALL :utility SHARE SHRLNK SHARE.EXE
CALL :utility IFSFUNC IFSLNK IFSFUNC.EXE

REM The drivers and data files under src\DEV.
CALL :device DRIVER DRVLNK DRIVER.SYS
CALL :device ANSI ANSLNK ANSI.SYS
CALL :device VDISK VDSKLNK VDISK.SYS
CALL :device DISPLAY DISPLNK DISPLAY.SYS
CALL :device PRINTER PRTLNK PRINTER.SYS
CALL :device RAMDRIVE RAMLNK RAMDRIVE.SYS
CALL :device SMARTDRV SMRTLNK SMARTDRV.SYS
CALL :device COUNTRY MKCLNK MKCNTRY.EXE
CALL :device XMAEM XMAELNK XMAEM.SYS
CALL :device XMA2EMS XMA2LNK XMA2EMS.SYS
CALL :device KEYBOARD KBDLNK KEYBOARD.SYS

REM The two code page files, under src\DEV\DISPLAY.
CALL :fonts EGA EGALNK EGA.CPI
CALL :fonts LCD LCDLNK LCD.CPI

REM EMM386.COM, under src\MEMM, the one program in the release made of
REM assembler alone that the release's own build does not build: MAKEFILE
REM there declares the target and comments out the rule that would link it.
REM Neither module reads anything from src\INC, so there is no include path
REM to set and nothing of the message retriever in it.
CALL :fasm src\MEMM\MEMM\ECOMLNK.ASM bin\EMM386.COM
IF DEFINED FAILED (
    ECHO assemble.bat: something above did not build
    EXIT /B 1
)
GOTO :EOF

REM fasm <source> <output>, and the one place a failure is counted: a batch
REM file has nothing like the set -e that stops assemble.sh at the first, so
REM what this does instead is remember and say so at the end.
:fasm
%FASM% %1 %2
IF ERRORLEVEL 1 SET FAILED=1
GOTO :EOF

REM msg <skeleton>: the include file holding a program's text.  Each skeleton
REM writes one file per class it declares, beside the skeleton and named after
REM it: BOOT.SKL writes BOOT.CL1.
:msg
%PYTHON% buildmsg.py %1 > NUL
IF ERRORLEVEL 1 SET FAILED=1
GOTO :EOF

REM utility <directory> <source> <output> [<skeleton>] [<include directory>]
REM The skeleton is named after the message class the utility declares, which
REM is usually the directory's own name but not always -- LABEL's is LABL.SKL.
REM A fifth argument is another directory to read includes from, which FORMAT
REM wants for the boot sector's messages.
:utility
SET SKL=%4
IF "%SKL%"=="" SET SKL=%1
CALL :msg src\CMD\%1\%SKL%.SKL
SET INCLUDE=%CD%\src\INC;%CD%\src\CMD\%1
IF NOT "%5"=="" SET INCLUDE=%INCLUDE%;%CD%\%5
CALL :fasm src\CMD\%1\%2.ASM bin\%3
SET INCLUDE=
GOTO :EOF

REM device <directory> <source> <output> [<skeleton>]: a driver is built the
REM way a utility is, and the only difference is where it is read from.  A
REM driver with no messages of its own has no skeleton either -- RAMDRIVE
REM holds its text in a module, as the drivers did before the retriever took
REM that over.
:device
SET SKL=%4
IF "%SKL%"=="" SET SKL=%1
IF EXIST src\DEV\%1\%SKL%.SKL CALL :msg src\DEV\%1\%SKL%.SKL
SET INCLUDE=%CD%\src\INC;%CD%\src\DEV\%1
CALL :fasm src\DEV\%1\%2.ASM bin\%3
SET INCLUDE=
GOTO :EOF

REM fonts <directory> <source> <output>: EGA.CPI and LCD.CPI, the code page
REM files DISPLAY.SYS and MODE load the screen's fonts out of, which live
REM under src\DEV\DISPLAY and have no messages of their own.
:fonts
SET INCLUDE=%CD%\src\INC;%CD%\src\DEV\DISPLAY\%1
CALL :fasm src\DEV\DISPLAY\%1\%2.ASM bin\%3
SET INCLUDE=
GOTO :EOF
