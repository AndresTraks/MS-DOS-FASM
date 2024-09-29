@ECHO off
SET QEMU=C:\Progra~1\qemu\qemu-system-i386.exe

CALL create_image.bat

IF NOT EXIST %QEMU% (
    ECHO %QEMU% not found. Please install QEMU.
) ELSE (
    %QEMU% -drive file=msdos.img,format=raw,if=floppy
)
