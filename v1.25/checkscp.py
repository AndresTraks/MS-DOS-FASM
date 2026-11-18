#!/usr/bin/env python3
"""Find the four things the SCP assembler's dialect means that fasm does not.

`source/ASM.ASM`, `HEX2BIN.ASM` and `TRANS.ASM` are not MASM.  They are
written for the Seattle Computer Products 8086 Assembler, which is what Tim
Paterson wrote 86-DOS with and which this release ships the source of, and
four of its spellings mean something else to fasm -- or nothing at all.  Each
of the four assembles without a word of complaint and each one is fatal:

  * **JP is an unconditional jump.**  SCP ASM spells the three direct jumps
    JP (near), JMPS (short) and JMP; fasm reads JP as JPE, jump if parity
    even, and takes the branch only when the last result had an even number
    of bits set.  The same files use JPE where they do mean parity, with a
    comment saying so, so there is no guessing involved.  Forty of these
    went into the conversion, thirty-three of them live code in ASM.COM.

  * **DS reserves storage.**  DS 80 is eighty bytes with no value; DW 80 is
    one word holding the number 80.  Written as DW, the whole of the
    assembler's data area -- 52 reservations, among them two FCBs and the
    1024-byte buffers it reads a source file and writes a listing through --
    came to one word apiece, so every variable past the first overlapped the
    next and the first disk read wrote over the stack.

  * **DM is DB with the high bit set on the last byte.**  That bit is where
    a message ends: PRINT reads a byte, prints it and stops when the byte is
    negative, and the error table is walked by looking for the next byte
    with the bit set.  Written as plain DB, every message ran into the ones
    after it and the error table could not be walked at all.  ASM.ASM has a
    DM macro for this now, and 108 lines that use it.

  * **JMP is three bytes, always.**  The release writes "Jcc $+5" to skip
    over the JMP on the next line, which is two bytes of condition and three
    of jump.  fasm shortens a JMP in range to two bytes, so the skip landed
    on the last byte of the jump it was meant to clear and the processor ran
    off into the middle of an instruction.  Thirteen of these, and the fix
    is to say "JMP near" where the distance is counted on.

What this does not see: a fifth such spelling nobody has met yet, and the
instructions whose operands SCP ASM implies -- SHL BX for SHL BX,1, DIV BX
for DIV AX,BX, UP for CLD, LODB for LODSB, XLAT for XLATB -- which fasm
rejects outright rather than quietly reading as something else, so the
assembler itself is the check for those.

A file still word for word the release's own has not been converted, and
nothing here applies to it: TRANS.ASM, the 8080-to-8086 translator, is in
that state and is named rather than read.

    python3 checkscp.py
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = subprocess.run(["git", "-C", HERE, "rev-parse", "--show-toplevel"],
                      capture_output=True, text=True).stdout.strip()

# The files written for the SCP assembler.  The other three are MASM:
# MSDOS.ASM and COMMAND.ASM declare SEGMENTs, a GROUP and ASSUMEs, which SCP
# ASM has none of, and reserve storage with MASM's DB n DUP (?) rather than
# with DS; STDDOS.ASM is four lines that include MSDOS.ASM.  Nothing below
# is true of those, and their own storage is MASM's to answer for.
SCP = ("ASM.ASM", "HEX2BIN.ASM", "IO.ASM", "TRANS.ASM")

N = r"[A-Za-z_@?$][A-Za-z0-9_@?$]*"
DS = re.compile(r"(?i)^(" + N + r":?)?[ \t]+DS[ \t]+([^;\n]+?)[ \t]*$")
DM = re.compile(r"(?i)^(?!macro\b)(" + N + r":?)?[ \t]+DM[ \t]+[^;\n]")
JP = re.compile(r"(?i)^[ \t]*JP[ \t]+\S")
SKIP = re.compile(r"(?i)^[ \t]*J[A-Z]+[ \t]+\$\+5[ \t]*$")
NEAR = re.compile(r"(?i)^[ \t]*JMP[ \t]+near[ \t]+\S")
# A reservation, in any of the spellings this tree uses for one, and how
# many bytes it is: IO.ASM writes DB n DUP(?), ASM.ASM rb and rw.
RESERVE = re.compile(r"(?i)^(" + N + r":?)?[ \t]+(?:"
                     r"R([BWD])[ \t]+([^;\n]+?)"
                     r"|D([BWD])[ \t]+([^;\n]+?)[ \t]+DUP[ \t]*\([ \t]*\?[ \t]*\)"
                     r")[ \t]*$")
# MASM's own way of reserving one of something, which both texts write the
# same and fasm takes as it stands: DW ? is two bytes with no value.  A list
# of them -- DB ?,?,? -- is that many.
ONE = re.compile(r"(?i)^(" + N + r":?)?[ \t]+D([BWD])[ \t]+"
                 r"(\?(?:[ \t]*,[ \t]*\?)*)[ \t]*$")
WIDTH = {"B": 1, "W": 2, "D": 4}


def code(line):
    return line.split(";")[0].rstrip()


def release(rel):
    """The release's own text of a file, from the commit that added it."""
    adds = subprocess.run(["git", "-C", REPO, "log", "--diff-filter=A",
                           "--format=%H", "--", rel],
                          capture_output=True, text=True).stdout.split()
    if not adds:
        return None
    out = subprocess.run(["git", "-C", REPO, "show",
                          "%s:%s" % (adds[-1], rel)], capture_output=True)
    return out.stdout.decode("cp437").replace("\r\n", "\n").split("\n")


def reserved(lines):
    """Every reservation in a file, in any of the three spellings this tree
    holds, as the line it is on and the bytes it reserves.

    The release writes DS in the SCP-dialect files and DB n DUP(?) in the
    MASM ones; the conversion writes rb and rw as well.  All three are the
    same thing said three ways, and what is compared is how many bytes each
    one is -- by the number where the count is one, and by the name where
    the release wrote a name such as BUFSIZ.
    """
    out = []
    for n, line in enumerate(lines, 1):
        c = code(line)
        m = DS.match(c)
        if m:
            out.append((n, 'DS ' + m.group(2).strip(),
                        size(m.group(2).strip(), 1)))
            continue
        m = ONE.match(c)
        if m:
            kind = m.group(2).upper()
            count = m.group(3).count('?')
            out.append((n, 'd%s %s' % (kind.lower(), m.group(3)),
                        count * WIDTH[kind]))
            continue
        m = RESERVE.match(c)
        if not m:
            continue
        kind = (m.group(2) or m.group(4)).upper()
        count = (m.group(3) or m.group(5)).strip()
        out.append((n, '%s %s' % (kind.lower(), count),
                    size(count, WIDTH[kind])))
    return out


def size(count, width):
    """A reservation's size in bytes, when it can be worked out."""
    try:
        return int(count, 16 if count[-1:].upper() == "H" else 10) * width
    except ValueError:
        return "%s*%d" % (count.upper(), width) if width != 1 \
            else count.upper()


def main():
    names = sorted(n for n in os.listdir(os.path.join(HERE, "source"))
                   if n.upper().endswith((".ASM", ".INC")))
    total = 0
    counted = {"JP": 0, "DS": 0, "DM": 0, "$+5": 0}
    for name in names:
        if name.upper() not in SCP:
            continue
        path = os.path.join(HERE, "source", name)
        rel = os.path.relpath(path, REPO)
        was = release(rel)
        if was is None:
            continue
        now = open(path, encoding="cp437").read().split("\n")
        if [code(l) for l in was] == [code(l) for l in now]:
            if any(JP.match(code(l)) or DS.match(code(l)) or DM.match(code(l))
                   for l in was):
                print("%-14s is the release's own text, not converted; "
                      "the four below are not read of it" % name)
            continue

        # JP, which has to have become JMP
        for n, line in enumerate(now, 1):
            if JP.match(code(line)):
                print("%-14s %5d  JP is an unconditional jump here, and fasm "
                      "reads it as JPE: %s" % (name, n, code(line).strip()))
                total += 1
        counted["JP"] += sum(1 for l in was if JP.match(code(l)))

        # the reservations, which have to be the same storage said the
        # way fasm says it
        want = reserved(was)
        have = reserved(now)
        counted["DS"] += sum(1 for l in was if DS.match(code(l)))
        if len(want) != len(have):
            print("%-14s        the release reserves storage %d times and "
                  "the conversion %d: a DS written as a DW or a DB is one "
                  "word where it should be the whole of it"
                  % (name, len(want), len(have)))
            total += 1
        else:
            for (n, said, bytes_), (m, now_said, now_bytes) in zip(want, have):
                if bytes_ != now_bytes:
                    print("%-14s %5d  %s is %s in the conversion, which is "
                          "%s bytes and not %s"
                          % (name, m, said, now_said, now_bytes, bytes_))
                    total += 1

        # DM, which has to have stayed DM, with the macro that writes one
        wasdm = sum(1 for l in was if DM.match(code(l)))
        nowdm = sum(1 for l in now if DM.match(code(l)))
        counted["DM"] += wasdm
        if wasdm != nowdm:
            print("%-14s        the release writes %d messages with DM and "
                  "the conversion %d: a DM written as a DB has no end, and "
                  "every message runs into the next"
                  % (name, wasdm, nowdm))
            total += 1
        if nowdm and not re.search(r"(?mi)^[ \t]*macro[ \t]+DM\b",
                                   "\n".join(now)):
            print("%-14s        has DM lines and no macro to write one"
                  % name)
            total += 1

        # and the skips over a JMP, which have to be over three bytes
        for n, line in enumerate(now, 1):
            if not SKIP.match(code(line)):
                continue
            counted["$+5"] += 1
            after = code(now[n]) if n < len(now) else ""
            if not NEAR.match(after):
                print("%-14s %5d  the skip is over five bytes and the jump "
                      "under it is %s: fasm shortens a JMP in range to two"
                      % (name, n, after.strip() or "nothing"))
                total += 1

    print("\n%d findings in %s; %d JP, %d DS, %d DM and %d five-byte "
          "skips read" % (total, ", ".join(SCP), counted["JP"],
                          counted["DS"], counted["DM"], counted["$+5"]))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
