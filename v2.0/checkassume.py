#!/usr/bin/env python3
"""Find memory references that lost their segment override in the conversion.

MASM resolves a variable's segment itself.  Under

        ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
        MOV     WORD PTR [BCON],SI

it knows BCON lives in DOSGROUP, sees that DS is not pointing there and that
SS is, and emits an SS: override.  FASM has no ASSUME: it takes the reference
at face value and goes through DS.  Nothing complains at assembly time, and
the result reads or writes whatever the current DS happens to address.

That is what the two lines above did.  DS held the segment of the device being
initialised, so the far pointer meant for BCON landed at offset 00FCh of the
I/O system, in the middle of the interrupt stub for PRN.  It only showed as a
crash in builds where something live sat at that offset, which made the bug
look as though it depended on the size of the binary.

So: walk each module of the kernel, follow the ASSUME directives the
conversion kept as comments, and report every reference to a variable of the
data segment made while DS is assumed to be pointing elsewhere.  Each one is a
place where MASM put an override and the conversion did not.

Two things that look like findings and are not:

  * "context DS" is a macro, PUSH SS / POP DS, so it puts the data segment
    back into DS even though no ASSUME says so.

  * the sources habitually write

        ASSUME  DS:DOSGROUP
                LDS     DI,[CURBUF]
        ASSUME  DS:NOTHING

    where the second directive describes what DS has just become, not what it
    was during the load.  The load itself is fine.  Judging by the loads
    rather than by the directives turns 1 finding into 28, all but one of them
    imaginary; MASM believes the directives, and so does this.

One thing that was a finding and did not look like one: this split its input
on CRLF, and three of the modules -- MSCODE.ASM, EXEC.ASM, DOSIO.ASM -- have
LF endings.  Each collapsed into a single line, no ASSUME was ever recognised
in it, and the whole module went unexamined while the report said nothing was
wrong.  MSCODE.ASM had the SET_CURRENT_PDB defect in it the whole time.  Split
on any ending, and refuse a module that comes back as one line, so that a
silent skip cannot be mistaken for a clean module again.

Checked against the defect above: on the module as it stood before the fix it
reports exactly the ten references that were wrong, and none after.

    python3 checkassume.py [source-directory]
"""
import os, re, sys

SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "source")


def read(path):
    try:
        with open(path, newline="") as f:
            return f.read()
    except OSError as e:
        sys.exit("%s: %s\nThis reads a v2.0 style source directory, one holding "
                 "MSDOS.ASM and MSDATA.ASM." % (path, e.strerror))


def modules(src):
    """The kernel's modules, in the order MSDOS.ASM includes them."""
    names = re.findall(r"INCLUDE\s+'([^']+)'", read(os.path.join(src, "MSDOS.ASM")))
    return [n for n in names if os.path.exists(os.path.join(src, n))]


def data_labels(src):
    """Everything MSDATA.ASM defines storage for: the data segment's variables."""
    labels = set()
    for line in read(os.path.join(src, "MSDATA.ASM")).splitlines():
        code = line.split(";")[0]
        m = (re.match(r"^\s*([A-Za-z_]\w*)\s+(?:DB|DW|DD)\b", code)
             or re.match(r"^([A-Za-z_]\w*):", code))
        if m:
            labels.add(m.group(1))
    return labels


def scan(path, labels):
    ds_holds_data = True          # ASSUME at the top of each module says so
    findings = []
    lines = read(path).splitlines()
    if len(lines) < 2:
        sys.exit("%s came back as %d line(s): the line endings are not what "
                 "this expected, and the module would go unexamined."
                 % (os.path.basename(path), len(lines)))
    for n, line in enumerate(lines, 1):
        code = line.split(";")[0]
        assume = re.match(r"\s*;?ASSUME\s+(.*)", line, re.I)
        if assume:
            m = re.search(r"DS:\s*([A-Z_]\w*)", assume.group(1).upper())
            if m:
                ds_holds_data = m.group(1) != "NOTHING"
            continue
        if re.match(r"\s*context\s+DS\b", code, re.I):
            ds_holds_data = True
            continue
        if ds_holds_data:
            continue
        for m in re.finditer(r"\[([A-Za-z_]\w*)(?:[+-][^\]]*)?\]", code):
            if m.group(1) in labels:
                findings.append((n, m.group(1), line.rstrip()))
    return findings


def main():
    labels = data_labels(SRC)
    total = 0
    for name in modules(SRC):
        found = scan(os.path.join(SRC, name), labels)
        if found:
            total += len(found)
            print("%s:" % name)
            for n, label, line in found:
                print("  %5d  %-16s %s" % (n, label, line.strip()))
    print("%d module%s, %d data labels, %d reference%s missing a segment override"
          % (len(modules(SRC)), "" if len(modules(SRC)) == 1 else "s",
             len(labels), total, "" if total == 1 else "s"))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
