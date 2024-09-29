SET FASM=..\fasmw17332\FASM.EXE

%FASM% source\IO.ASM bin\IO.SYS
%FASM% source\STDDOS.ASM bin\MSDOS.SYS
%FASM% source\COMMAND.ASM bin\COMMAND.COM

%FASM% bootsect.asm bin\bootsect.bin
