SET FASM=..\fasmw17332\FASM.EXE

%FASM% source\IO.ASM bin\IO.SYS
%FASM% source\STDDOS.ASM bin\MSDOS.SYS
%FASM% source\COMMAND.ASM bin\COMMAND.COM
%FASM% source\ASM.ASM bin\ASM.COM
%FASM% source\HEX2BIN.ASM bin\HEX2BIN.COM

%FASM% bootsect.asm bin\bootsect.bin
