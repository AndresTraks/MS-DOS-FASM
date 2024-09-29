<img width="110" height="110" align="left" style="float: left; margin: 0 10px 0 0;" alt="MS-DOS logo" src="https://github.com/Microsoft/MS-DOS/blob/main/.readmes/msdos-logo.png">   

# MS-DOS v1.25, v2.0, v4.0 Source Code for FASM
This repo contains the source code for MS-DOS v1.25, v2.0 and v4.00, modified to be assembled with [flat assembler](https://flatassembler.net/) and with optional changes for running on modern hardware.

# Assembly
To assemble the source code, create a floppy disk image and run using [QEMU](https://www.qemu.org/):
```
cd v1.25
.\run.bat
```

To build v1.25 with IBM hardware support (configured by default in this repo):
* set `IBM = 1` in IO.ASM instead of `SCP`,
* set `IBM = TRUE` in STDDOS.ASM instead of `MSVER`,
* set `IBMVER = TRUE` in COMMAND.ASM instead of `MSVER`,
* set `HIGHMEM EQU FALSE` in COMMAND.ASM.

# Changes
v1.25
* Added FASM build scripts.
* Added [boot sector](v1.25/bootsect.asm) that loads IO.SYS and MSDOS.SYS and passes control to IO.SYS.
* Added IBM hardware support in IO.ASM: disk I/O via interrupt 13h, keyboard handling via interrupt 9h, time handling via interrupt 1Ah, text output via interrupt 10h.

# License
All files within this repo are released under the [MIT License](https://en.wikipedia.org/wiki/MIT_License) as per the [LICENSE](LICENSE) file stored in the root of this repo.

# Trademarks
This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
