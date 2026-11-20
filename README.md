<img width="110" height="110" align="left" style="float: left; margin: 0 10px 0 0;" alt="MS-DOS logo" src="https://github.com/Microsoft/MS-DOS/blob/main/.readmes/msdos-logo.png">   

# MS-DOS v1.25, v2.0, v4.0 Source Code for FASM
This repo contains the source code for MS-DOS v1.25, v2.0 and v4.00, modified to be assembled with [flat assembler](https://flatassembler.net/) and with optional changes for running on modern hardware.

# Assembly
To assemble the source code, create a floppy disk image and run using [QEMU](https://www.qemu.org/), switch to a version folder and run run.bat/run.sh:
```
cd v1.25
.\run.bat
```

To build v1.25 with IBM hardware support (configured by default in this repo):
* set `IBM = 1` in IO.ASM instead of `SCP`,
* set `IBM = TRUE` in STDDOS.ASM instead of `MSVER`,
* set `IBMVER = TRUE` in COMMAND.ASM instead of `MSVER`.

# Changes
v1.25
* Added FASM build scripts.
* Added [boot sector](v1.25/bootsect.asm) that loads IO.SYS and MSDOS.SYS and passes control to IO.SYS.
* Added IBM hardware support in IO.ASM: disk I/O via interrupt 13h, keyboard handling via interrupt 9h, time handling via interrupt 1Ah, text output via interrupt 10h.
* Added [GW-BASIC-FASM](https://github.com/AndresTraks/GW-BASIC-FASM), Microsoft's GW-BASIC source release converted for FASM. `GWBASIC SAMPLES` brings up IBM's samples menu. ESC leaves the menu for BASIC, and `SYSTEM` returns to DOS. The release's own BASIC.COM and BASICA.COM are included, but without the ROM BASIC that's required to run the.

v2.0
* Added FASM build scripts and a [boot sector](v2.0/bootsect.asm).
* Added IBM hardware support in [IO.ASM](v2.0/source/IO.ASM): disk I/O via interrupt 13h, keyboard, clock and screen via the ROM BIOS. Added [DOSIO.ASM](v2.0/source/DOSIO.ASM), the character I/O module FOR IBM.
* Added [PCLOCK_IBM.ASM](v2.0/source/PCLOCK_IBM.ASM), the clock module the PROFIL profiler needs on a PC.

v4.0
* Added FASM build scripts. [assemble.sh](v4.0/assemble.sh) builds everything the release makes from assembler alone: the boot sector, MSLOAD, the BIOS, the kernel, twenty-eight utilities under src/CMD, eleven drivers and data files under src/DEV, EGA.CPI and LCD.CPI, and EMM386.COM under src/MEMM -- that last one being a program the release's own makefile has the rule for commented out.
* What is left in src cannot be built with an assembler alone: src/MAPPER is a library for six C programs (JOIN, SUBST, FDISK, REPLACE, BACKUP and RESTORE) and fasm has no librarian; EMM386.EXE links emmlib.lib, which is built from C; src/SELECT wants a C compiler and SERVICES.LIB, which Microsoft never published; ATTRIB and FC are C as well.
* The kernel still keeps the CP/M-compatible call at offset 5 of a program's base, and it needs the A20 line masked -- the long call it writes there is a megabyte above the long jump it points at. This tree deliberately leaves the line alone, DOS 4's own drivers reaching above the first megabyte on purpose.

v4.0-ozzie (Multitasking MS-DOS 4.0)
* [v4.0-ozzie/bin](v4.0-ozzie/bin) holds the two diskettes of the Multitasking MS-DOS 4.0 beta. The only source on them is DISK2/BIOS -- three modules, each with the object MASM made of it shipped beside it.
* All three are converted and held byte for byte against those objects by [checkobj.py](v4.0-ozzie/checkobj.py), and IBMBIO.COM is built from them: [sysinit.py](v4.0-ozzie/sysinit.py) resolves the two objects that have no source, and [src/BIOSIMG.ASM](v4.0-ozzie/src/BIOSIMG.ASM) lays all five down where LINK put them. 12363 bytes, the shipped length.
* Three changes this machine wants are kept behind switches, so the faithful build is byte for byte what it was: four Sense Interrupt Status commands and 300 kbps for QEMU's floppy controller, and the A20 gate closed for the kernel's CP/M entry. [src/QEMULNK.ASM](v4.0-ozzie/src/QEMULNK.ASM) builds the one that runs -- COMMAND.COM, AUTOEXEC.BAT, DIR through the converted disk driver, and SM.EXE, the session manager this release exists for.

## Running PROFIL (v2.0)
Build the profiler on the system itself and run it on a program:
```
MASM PCLOCKPC,PCLOCK,,;
LINK PROFIL+PCLOCK,PROFIL,,;
EXE2BIN PROFIL PROFIL.COM
PROFIL EXE2BIN.EXE
```

# License
All files within this repo are released under the [MIT License](https://en.wikipedia.org/wiki/MIT_License) as per the [LICENSE](LICENSE) file stored in the root of this repo.

# Trademarks
This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
