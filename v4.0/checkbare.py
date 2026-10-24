#!/usr/bin/env python3
"""Find variables the conversion reads as a number where MASM read memory.

MASM takes a bare variable name as a reference to its contents:

	MOV	BP,NextEntry

loads the word NextEntry holds.  fasm takes the same line as the variable's
address and loads that instead, and there is nothing for either assembler to
complain about: one of them is a load and the other an immediate, and both
assemble.  The conversion therefore has to bracket every such operand, and
where it is an offset the source asked for -- MOV SI,OFFSET BUF -- it has to
leave it alone.  Which of the two a line wanted is in the release's own text,
so this reads that: every operand that names something the release gives
storage to, written without OFFSET and without brackets, has to be bracketed
here.

A name that is also a label is left out: MASM reads CALL PAD as a call to the
procedure, not as a call through a variable of the same name.  Structure
fields are left out too -- ADD SI,SDEVNAME adds the field's offset, which is
a number in both assemblers -- as are the names inside a string.

It reads the release out of the commit that added each file, so it needs no
list of its own, and it compares only the files that still have the same
number of lines, which is all of the kernel's modules but the ones the
conversion restructured.

Checked against the defect it was written for: take the CS: off MSSTACK.INC's
"mov bp,[cs:NextEntry]" and it names that line, and the same for a reference
in a module that still has its original number of lines.  Clean on the kernel,
the BIOS and the boot sector as they stand.

    python3 checkbare.py
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = subprocess.run(["git", "-C", HERE, "rev-parse", "--show-toplevel"],
                      capture_output=True, text=True).stdout.strip()

N = r"[A-Za-z_@?$][A-Za-z0-9_@?$]*"
STORAGE = [re.compile(r"^\s*(" + N + r")\s+(?:DB|DW|DD|DQ|DT)\s", re.I),
           re.compile(r"(?i)^\s*I_am\s+(" + N + r")\s*,")]
LABEL = [re.compile(r"^(" + N + r"):"),
         re.compile(r"(?i)^\s*(" + N + r")\s+(?:PROC|LABEL)\b"),
         re.compile(r"(?i)^\s*(?:procedure|entry)\s+(" + N + r")\b")]
# The instructions whose operand MASM would have read from memory.  CALL and
# JMP are in: a CALL through a DWORD variable is how the BIOS chains INT 13H.
OPS = re.compile(r"(?i)^\s*(MOV|ADD|SUB|CMP|AND|OR|XOR|TEST|ADC|SBB|INC|DEC|"
                 r"XCHG|PUSH|POP|MUL|IMUL|DIV|IDIV|NEG|NOT|SHL|SHR|SAR|RCL|"
                 r"RCR|ROL|ROR|CALL|JMP)\b")
STRINGS = re.compile(r"'[^']*'|\"[^\"]*\"")
WORDS = re.compile(r"(?<![A-Za-z0-9_@?$.])(" + N + r")")
# What a bare name means in these is not a variable's contents.
NOTAVAR = re.compile(r"(?i)\b(OFFSET|SEG|PTR|SHORT|NEAR|FAR|DUP|LENGTH|SIZE|"
                     r"TYPE|THIS|WIDTH|MASK)\b")


def origin(rel):
    adds = subprocess.run(["git", "-C", REPO, "log", "--diff-filter=A",
                           "--format=%H", "--", rel],
                          capture_output=True, text=True).stdout.split()
    if not adds:
        return None
    return subprocess.run(["git", "-C", REPO, "show", "%s:%s" % (adds[-1], rel)],
                          capture_output=True).stdout.decode("cp437")


def declarations(text):
    """What the release gives storage to, and what it makes a label of.

    A structure's fields come back separately: they are storage inside the
    STRUC and a number everywhere else, so a line that names one is adding an
    offset and needs no brackets."""
    storage, labels, fields = set(), set(), set()
    instruc = None
    for line in text.replace("\r\n", "\n").split("\n"):
        code = line.split(";")[0]
        m = re.match(r"(?i)^(" + N + r")\s+STRUC\b", code)
        if m:
            instruc = m.group(1)
            continue
        if instruc:
            if re.match(r"(?i)^" + re.escape(instruc) + r"\s+ENDS\b", code):
                instruc = None
            for p in STORAGE:
                m = p.match(code)
                if m:
                    fields.add(m.group(1).upper())
            continue
        for p in STORAGE:
            m = p.match(code)
            if m:
                storage.add(m.group(1).upper())
        for p in LABEL:
            m = p.match(code)
            if m:
                labels.add(m.group(1).upper())
    return storage, labels, fields


def instructions(lines):
    """The lines that carry one of the instructions above, with its name."""
    out = []
    for n, line in enumerate(lines, 1):
        code = line.split(";")[0]
        m = OPS.match(code)
        if m:
            out.append((n, m.group(1).upper(), code))
    return out


def constants(text):
    """The numbers a module defines for itself.

    A name may be a variable in one module and a constant in another -- the
    kernel keeps a word called MYNUM and MSBIO2 has MYNUM EQU 8 -- and a
    constant is a number in both assemblers, so those lines are not findings."""
    out = set()
    for line in text.replace("\r\n", "\n").split("\n"):
        m = re.match(r"^\s*(" + N + r")\s*(?:=[^=]|[Ee][Qq][Uu]\s)",
                     line.split(";")[0])
        if m:
            out.add(m.group(1).upper())
    return out


def judge(rel, n, ca, cb, storage, out):
    ca = STRINGS.sub(" ", ca)
    if "[" in ca or NOTAVAR.search(ca):
        return
    for m in WORDS.finditer(ca):
        name = m.group(1)
        if name.upper() not in storage:
            continue
        # fasm keeps every name beginning with $ for itself, so the
        # conversion moved the $ to the end, and a name may have been
        # renamed as well -- two modules each had a private COUNT, and one
        # is COUNT_SYSINIT now.  Either spelling counts as bracketed.
        spellings = {name}
        if name.startswith("$"):
            spellings |= {name[1:] + "$", name[1:]}
        if any(re.search(r"\[[^\]]*\b" + re.escape(s) +
                         r"[A-Za-z0-9_@?$]*\b[^\]]*\]", cb, re.I)
               for s in spellings):
            continue
        out.append("%-26s %5d  %-20s was: %-28s now: %s"
                   % (rel, n, name, ca.strip()[:28], cb.strip()[:32]))


def compare_aligned(rel, was, now, storage, out):
    """Line the two instruction streams up, for a file that changed length.

    Most of the ones that did are headers and the modules the conversion
    restructured, and the instructions in them are still in the same order --
    which is enough to say which line in one answers to which in the other."""
    import difflib
    a, b = instructions(was), instructions(now)
    sm = difflib.SequenceMatcher(None, [x[1] for x in a], [x[1] for x in b],
                                 autojunk=False)
    for i, j, size in sm.get_matching_blocks():
        for k in range(size):
            judge(rel, b[j + k][0], a[i + k][2], b[j + k][2], storage, out)


def main():
    if not REPO:
        sys.exit("%s is not in a git repository" % HERE)
    names = []
    for here, dirs, files in os.walk(os.path.join(HERE, "src")):
        dirs.sort()
        for n in sorted(files):
            if n.upper().endswith((".ASM", ".INC")):
                rel = os.path.relpath(os.path.join(here, n), HERE)
                if rel.startswith(("src/DOS", "src/BIOS", "src/BOOT", "src/INC")):
                    names.append(rel)
    # Storage is collected from every module, because a module reads
    # variables other modules declare.  What shadows a name is local: a
    # label or a constant of the module's own, which is why MSBIO2's
    # MYNUM EQU 8 does not make the kernel's word called MYNUM a finding,
    # and DIR.ASM's procedure called NextEntry does not stop MSSTACK's
    # variable of that name being one.
    originals = {}
    storage, fields = set(), set()
    shadows = {}
    for rel in names:
        o = origin(os.path.join("v4.0", rel))
        if o is None:
            continue
        originals[rel] = o
        s, l, f = declarations(o)
        storage |= s
        fields |= f
        shadows[rel] = l | constants(o)
    # A structure's field is a number wherever it is named, so it is never a
    # variable; a code label only shadows inside its own module.
    storage -= fields
    total = lengths = 0
    for rel, o in originals.items():
        was = o.replace("\r\n", "\n").split("\n")
        now = open(os.path.join(HERE, rel), encoding="cp437").read().split("\n")
        found = []
        if len(was) != len(now):
            lengths += 1
            compare_aligned(rel, was, now, storage - shadows[rel], found)
        else:
            mine = storage - shadows[rel]
            for n, (a, b) in enumerate(zip(was, now), 1):
                if OPS.match(a.split(";")[0]):
                    judge(rel, n, a.split(";")[0], b.split(";")[0], mine, found)
        for line in found:
            print(line)
        total += len(found)
    print("\n%d operands name a variable and do not read it; %d files are a "
          "different length and were lined up by their instructions instead"
          % (total, lengths))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
