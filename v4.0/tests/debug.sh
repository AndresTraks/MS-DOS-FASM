#!/bin/sh
# Run DEBUG.COM on the system this builds, over a program typed into it.
#
# DEBUG is two programs in one: an assembler and a disassembler, with a
# monitor around them.  So the test has it assemble four instructions with A,
# read the bytes back with D, disassemble them again with U, and single-step
# them with T -- which is the other half of what it is, the INT 1 and INT 3
# handlers and the registers it keeps for the program it is debugging.
#
# The commands come in on the standard input, which is how DEBUG was always
# scripted: COMMAND.COM redirects CMDS.TXT into it and PRN out of it.  So
# nothing is typed at the keyboard here.
#
# What it writes is held against itself: the bytes A laid down are the bytes
# D reads back, and U turns them into the mnemonics A was given.  Those three
# agreeing is the assembler and the disassembler agreeing, each written from
# its own table.
#
# Then three more instructions, for the operands DEBUG reads as a pair of
# characters in a word -- CL, SHORT and PTR -- and two bytes typed in with E
# and read back with U, for the 8087 mnemonics it writes the same way.  Those
# are the places where MASM's literal, whose first character went in the high
# byte, says the opposite of what fasm's does: "LC" is the text CL, and
# MOV AX,"ON" is how FNOP's last three letters are stored.
#
# U prints a memory operand that carries its size as "byte [TBYTE[0200]" and
# runs the 8087's memory form two bytes long -- both of them the conversion's
# and neither looked into yet, so nothing below asserts them.  They are in
# what the test prints.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/debug.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT
. ./tests/await.sh

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/DEBUG.COM ::DEBUG.COM

# R for the registers it starts the program with, A to assemble, the empty
# line to end the assembly, U and D to read it back, three T's to run it an
# instruction at a time.  Then a second A for the three operands read as a
# word of two characters, a U to read those back, an E to type two 8087
# instructions and a size-carrying MOV in as bytes, a U to disassemble
# them, and Q to leave.
{
    printf 'R\r\n'
    printf 'A 100\r\nMOV AX,1234\r\nMOV BX,AX\r\nINC BX\r\nINT 20\r\n\r\n'
    printf 'U 100 L 8\r\nD 100 L 10\r\nT\r\nT\r\nT\r\n'
    printf 'A 120\r\nROR AX,CL\r\nJMP SHORT 130\r\nMOV BYTE PTR [200],5\r\n\r\n'
    printf 'U 120 L 9\r\n'
    printf 'E 140 D9 C9 D9 D0 C6 06 00 02 05\r\n'
    printf 'U 140 L A\r\n'
    printf 'Q\r\n'
} > "$OUT/CMDS.TXT"
mcopy -o -i "$IMG" "$OUT/CMDS.TXT" ::CMDS.TXT

printf 'ECHO OFF\r\nDEBUG < CMDS.TXT > PRN\r\n' > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

{
    awaitprompt
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/prn.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/prn.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }

python3 - "$OUT/prn.txt" <<'PY' || exit 1
import re
import sys

said = open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
print("--- what it said")
for line in said.split("\n"):
    if line.strip():
        print("   %s" % line.rstrip().expandtabs(8))

rc = 0
print("--- checks")
# The segment DOS loaded it at is whatever it is, so every address is checked
# from the colon on.
want = [(r"AX=0000  BX=0000  CX=0000  DX=0000",
         "R showed the registers the program starts with"),
        (r"DS=[0-9A-F]{4}  ES=[0-9A-F]{4}  SS=[0-9A-F]{4}  CS=[0-9A-F]{4}  "
         r"IP=0100   NV UP EI PL NZ NA PO NC",
         "and the segments, the instruction pointer and the flags by name"),
        (r":0100 MOV AX,1234", "A took the first instruction at 100"),
        (r":0103 MOV BX,AX", "and the second where the first ended"),
        (r":0104 INC BX|:0105 INC BX", "and the third"),
        (r":0106 INT 20", "and the fourth"),
        (r":0100 B83412 +MOV\tAX,1234",
         "U read B8 34 12 back as the instruction it was assembled from"),
        (r":0103 89C3 +MOV\tBX,AX", "and 89 C3 as the second"),
        (r":0105 43 +INC\tBX", "and 43 as the third"),
        (r":0106 CD20 +INT\t20", "and CD 20 as the fourth"),
        (r":0100  B8 34 12 89 C3 43 CD 20",
         "D read the same eight bytes out of memory"),
        (r"AX=1234  BX=0000.*\n.*IP=0103", "T ran the first and AX took 1234"),
        (r"AX=1234  BX=1234.*\n.*IP=0105", "the second and BX took it too"),
        (r"AX=1234  BX=1235.*\n.*IP=0106", "and the third counted BX up"),
        (r"IP=0106   NV UP EI PL NZ NA PE NC",
         "with the parity flag following the count"),
        # The operands read as a word of two characters.  Before these were
        # turned round the assembler stopped at the first of them.
        (r":0120 D3C8 +ROR\tAX,CL",
         "A took ROR AX,CL, whose CL the assembler reads as a word, and U "
         "read D3 C8 back as it"),
        (r":0122 EB0C", "and JMP SHORT, whose SHORT it reads the same way"),
        (r":0124 C606000205",
         "and BYTE PTR, whose PTR it reads the same way, laying down the "
         "five bytes of MOV BYTE PTR [200],5"),
        # and the 8087 mnemonics the disassembler builds a word at a time
        (r"D9C9 +\tFXCH\tST\(1\)",
         "U reads D9 C9 as FXCH ST(1), three of whose letters are one such "
         "word"),
        (r"D9D0 +\tFNOP",
         "and D9 D0 as FNOP, which came out FONP while the word was the "
         "other way round")]
for pattern, why in want:
    if re.search(pattern, said):
        print("ok      %s" % why)
    else:
        print("MISSING %s" % pattern.replace("\\t", " "))
        rc = 1

# A and U are written from separate tables, so the two agreeing is the check
# that neither lost an entry.
for byte, mnemonic in (("B83412", "MOV\tAX,1234"), ("89C3", "MOV\tBX,AX"),
                       ("43", "INC\tBX"), ("CD20", "INT\t20")):
    if re.search(re.escape(byte) + r" +" + re.escape(mnemonic), said):
        print("ok      %s is %s both ways" % (byte, mnemonic.expandtabs(1)))
    else:
        print("MISSING %s as %s" % (byte, mnemonic.expandtabs(1)))
        rc = 1
sys.exit(rc)
PY
