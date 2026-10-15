SET FASM=..\fasmw17332\FASM.EXE

%FASM% source\MSDOS.ASM bin\MSDOS.SYS

%FASM% source\IO.ASM bin\IO.SYS

%FASM% bootsect.asm bin\bootsect.bin
