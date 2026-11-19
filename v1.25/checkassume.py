#!/usr/bin/env python3
"""Find references that lost the segment override MASM wrote for them, and
structure fields that moved.

MASM resolved a variable's segment itself.  Under

        ASSUME  CS:RESGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:RESGROUP
        TEST    [BATCH],-1

it knows BATCH is in RESGROUP, sees that DS is not pointing there and that CS
is, and emits a CS: override.  fasm has no ASSUME: it takes the reference at
face value and goes through DS.  Nothing complains at assembly time, and the
result reads or writes whatever DS happens to address -- which is how a
machine runs off into its own data.  That class is what broke the BIOS in the
4.00 tree, and it is the one thing nothing else here would notice: the
assembler is happy, the instruction is the right instruction, and the operand
means something else.

Two of this tree's files are MASM and have segments, groups and ASSUMEs:

  * MSDOS.ASM, the kernel: CODE, CONSTANTS and DATA in one group, DOSGROUP,
    with one ASSUME at the top of the code putting all four registers on it.
    So every register reaches every label and MASM never had an override to
    write.  SEGBIOS is a SEGMENT AT and holds no storage of its own.
  * COMMAND.ASM: seven segments in two groups -- CODERES, DATARES, INIT and
    TAIL are RESGROUP, the resident part, and TRANCODE, TRANDATA and
    TRANSPACE are TRANGROUP, the transient part that is read back from the
    file whenever a program has overwritten it -- and thirteen ASSUMEs that
    move DS, ES and CS between the two as the code crosses from one to the
    other.  That is where an override can be needed and lost.

The other four files are written for the SCP assembler, have no segments and
no ASSUME at all, and are checkscp.py's business.

What this reads, and what it does not: a bare name as an operand is a memory
reference, and the name has a segment if the release declared it inside one.
A name the release declared outside every segment is a number -- FCB EQU 5CH,
RR EQU 33, the function numbers -- and carries no segment, so it is counted
and skipped; the count is printed, because a check that silently examined
nothing would look exactly like a check that passed.  OFFSET X is an address
and not a read, so it is skipped as well.  The two texts are lined up on
their instruction streams rather than their lines, the conversion having
dropped the directive lines and added its own.

The second pass reads the three structures the kernel declares and holds
every field against the offset the release gave it.  Three structures is too
few to be worth a file of their own, and the question is the same question:
whether a name still means the place it meant.

    python3 checkassume.py
"""
import difflib
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = subprocess.run(["git", "-C", HERE, "rev-parse", "--show-toplevel"],
                      capture_output=True, text=True).stdout.strip()
N = r"[A-Za-z_@?$][A-Za-z0-9_@?$]*"
# The files that are MASM.  The rest are the SCP assembler's.
MASM = ("MSDOS.ASM", "COMMAND.ASM")
REGISTERS = re.compile(r"(?i)^(ax|bx|cx|dx|si|di|bp|sp|al|bl|cl|dl|ah|bh|ch"
                       r"|dh|cs|ds|es|ss|byte|word|dword|ptr|offset|short"
                       r"|near|far|dup|and|or|xor|not|mod|shl|shr)$")
MEM = re.compile(r"(?i)^[ \t]*(?:" + N + r":[ \t]*)?"
                 r"(MOV|CMP|ADD|SUB|AND|OR|XOR|TEST|INC|DEC|LEA|XCHG|ADC"
                 r"|SBB|NOT|NEG|MUL|IMUL|DIV|IDIV|SHL|SHR|RCL|RCR|ROL|ROR)"
                 r"[ \t]+([^;]*)$")
INSTR = re.compile(r"(?i)^[ \t]*(?:" + N + r":[ \t]*)?([A-Za-z]{2,7})\b")
NOTCODE = {"SEGMENT", "ENDS", "GROUP", "ASSUME", "PUBLIC", "EXTRN", "STRUC",
           "ENDM", "MACRO", "IF", "IFE", "IFDEF", "IFNDEF", "ENDIF", "ELSE",
           "END", "EQU", "DB", "DW", "DD", "LABEL", "ORG", "RB", "RW", "RD",
           "INCLUDE", "TITLE", "PAGE", "SUBTTL", "DUP", "PUT", "VIRTUAL"}
WIDTH = {"DB": 1, "DW": 2, "DD": 4, "RB": 1, "RW": 2, "RD": 4}


def code(line):
    return line.split(";")[0].rstrip()


def release(name):
    """The release's own text of a file, from the commit that added it."""
    rel = os.path.relpath(os.path.join(HERE, "source", name), REPO)
    adds = subprocess.run(["git", "-C", REPO, "log", "--diff-filter=A",
                           "--format=%H", "--", rel],
                          capture_output=True, text=True).stdout.split()
    if not adds:
        return None
    out = subprocess.run(["git", "-C", REPO, "show",
                          "%s:%s" % (adds[-1], rel)], capture_output=True)
    return out.stdout.decode("cp437").replace("\r\n", "\n").split("\n")


def placed(lines):
    """Which group each label is in, by the segment the release declared it
    inside.  A label declared outside every segment is a number."""
    group, where, seg = {}, {}, None
    for line in lines:
        c = code(line)
        m = re.match(r"(?i)^(" + N + r")[ \t]+SEGMENT\b", c)
        if m:
            seg = m.group(1).upper()
            continue
        if re.match(r"(?i)^(" + N + r")[ \t]+ENDS\b", c):
            seg = None
            continue
        m = re.match(r"(?i)^(" + N + r")[ \t]+GROUP[ \t]+(.*)$", c)
        if m:
            for s in m.group(2).split(","):
                group[s.strip().upper()] = m.group(1).upper()
            continue
        if not seg:
            continue
        m = re.match(r"(?i)^(" + N + r"):?[ \t]+(D[BWD]|LABEL)\b", c) \
            or re.match(r"(?i)^(" + N + r"):", c)
        if m:
            where.setdefault(m.group(1).upper(), seg)
    return {k: group.get(v, v) for k, v in where.items()}, group


def stream(lines):
    """Each line's instruction, the directives and declarations aside."""
    out = []
    for n, line in enumerate(lines, 1):
        c = code(line)
        m = INSTR.match(c)
        if m and m.group(1).upper() not in NOTCODE:
            out.append((n, m.group(1).upper(), c.strip()))
    return out


def overrides(name, was, now):
    """Every reference MASM resolved through something other than DS, and
    what the conversion wrote on that line."""
    groups, _ = placed(was)
    assume, needs, read, numbers = {}, [], 0, {}
    for n, line in enumerate(was, 1):
        c = code(line)
        m = re.match(r"(?i)^[ \t]*ASSUME[ \t]+(.*)$", c)
        if m:
            for part in m.group(1).split(","):
                if ":" in part:
                    r, v = part.split(":", 1)
                    assume[r.strip().upper()] = v.strip().upper()
            continue
        m = MEM.match(c)
        if not m:
            continue
        args = m.group(2)
        for word in re.findall(r"(?<![\w:.$])(" + N + r")(?![\w(])", args):
            if REGISTERS.match(word):
                continue
            # OFFSET X is the address of X and reads nothing
            if re.search(r"(?i)\bOFFSET[ \t]+(" + N + r"[ \t]*:[ \t]*)?"
                         + re.escape(word) + r"\b", args):
                continue
            g = groups.get(word.upper())
            if g is None:
                numbers[word.upper()] = numbers.get(word.upper(), 0) + 1
                continue
            read += 1
            if assume.get("DS") == g:
                continue
            reach = [r for r in ("ES", "SS", "CS") if assume.get(r) == g]
            needs.append((n, word.upper(), g, assume.get("DS"), reach))
    a, b = stream(was), stream(now)
    sm = difflib.SequenceMatcher(None, [x[1] for x in a], [x[1] for x in b],
                                 autojunk=False)
    lined = {}
    for i, j, size in sm.get_matching_blocks():
        for d in range(size):
            lined[a[i + d][0]] = b[j + d]
    print("%-12s %d references through a label with a segment, %d names that "
          "are numbers; %d wanted an override"
          % (name, read, len(numbers), len(needs)))
    bad = 0
    for n, label, g, ds, reach in needs:
        got = lined.get(n)
        if got is None:
            print("  %5d  could not be lined up with the conversion: %s"
                  % (n, label))
            bad += 1
            continue
        if re.search(r"(?i)\b(cs|es|ss):", got[2]):
            continue
        print("  %5d -> %-5d %-10s is in %-10s with DS on %-10s and the "
              "conversion reads it through DS: %s"
              % (n, got[0], label, g, ds, got[2][:40]))
        bad += 1
    return bad


def structures(name, was, now):
    """Every structure field, against the offset the release gave it."""
    def fields(lines, fasm):
        out, held, at = {}, None, 0
        for line in lines:
            c = code(line)
            m = (re.match(r"(?i)^STRUC[ \t]+(" + N + r")", c) if fasm
                 else re.match(r"(?i)^(" + N + r")[ \t]+STRUC[ \t]*$", c))
            if m:
                held, at, out[m.group(1).upper()] = m.group(1).upper(), 0, {}
                continue
            if held is None:
                continue
            if re.match(r"(?i)^(" + N + r"[ \t]+ENDS|\})", c):
                held = None
                continue
            m = re.match(r"(?i)^[ \t.]*(" + N + r")?[ \t]*(D[BWD]|R[BWD])"
                         r"[ \t]+(.*)$", c)
            if not m:
                continue
            field, kind, val = m.group(1), m.group(2).upper(), m.group(3)
            n = 1
            mm = re.match(r"(?i)^(\S+)[ \t]+DUP[ \t]*\(", val.strip())
            if mm:
                n = int(mm.group(1).rstrip("Hh"),
                        16 if mm.group(1)[-1:] in "Hh" else 10)
            elif kind.startswith("R"):
                n = int(val.split()[0], 10)
            if field:
                out[held][field.upper()] = at
            at += n * WIDTH[kind]
        return out

    a, b = fields(was, False), fields(now, True)
    bad, count = 0, 0
    for s, f in a.items():
        for field, off in f.items():
            count += 1
            got = b.get(s, {}).get(field)
            if got == off:
                continue
            # A field named after an instruction cannot keep its name: the
            # kernel's STKPTRS has an FSAVE, which is the 8087's.
            under = b.get(s, {}).get("_" + field)
            if under == off:
                continue
            print("  %-10s %-10s is at %s in the release and %s here"
                  % (s, field, off, got))
            bad += 1
    print("%-12s %d structure fields compared in %d structures"
          % (name, count, len(a)))
    return bad


def main():
    total = 0
    for name in MASM:
        was = release(name)
        if was is None:
            print("%s: no release text to read" % name)
            continue
        now = open(os.path.join(HERE, "source", name),
                   encoding="cp437").read().split("\n")
        total += overrides(name, was, now)
        if any(re.match(r"(?i)^(" + N + r")[ \t]+STRUC[ \t]*$", code(l))
               for l in was):
            total += structures(name, was, now)
    print("\n%d references lost an override, and no structure field moved"
          % total if not total else "\n%d findings" % total)
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
