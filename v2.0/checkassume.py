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


# COMMAND.COM is laid out in three groups rather than one segment, so the
# question is not whether DS points at the data but which group it points at.
# COMSEG.ASM says which group each segment belongs to, COMLINK.ASM says which
# modules there are, and in the converted modules each segment's contribution
# is wrapped in "if SEGSEL = S_<name>", so where a label is defined says which
# group it is addressed in.
#
# MASM's rule is to use whichever assumed register reaches the label, DS for
# preference, and to refuse the line if none does.  So a reference with no
# override is right only when DS is assumed to the label's own group; if some
# other register reaches it, that is where MASM put an override and the
# conversion did not, and the report says which register it would have used.

DEFINES = re.compile(r"^\s*([A-Za-z_]\w*)\s+(?:DB|DW|DD|LABEL)\b", re.I)
DEFLABEL = re.compile(r"^([A-Za-z_]\w*):")
# FASM's own form, which the conversion emits for MASM's NAME LABEL SIZE and
# which has the name second.  Missing it is not harmless: HEADCALL is declared
# this way, it went unlisted, and the far call through it in TCOMMAND kept its
# missing override until this pattern was added.
DEFFASM = re.compile(r"^\s*label\s+([A-Za-z_]\w*)\s", re.I)
REFERENCE = re.compile(r"\[(?:(CS|DS|ES|SS):)?\s*([A-Za-z_]\w*)(?:[+-][^\]]*)?\]", re.I)


def command_groups(src):
    """Which group each of COMMAND's segments is in, from COMSEG.ASM."""
    where = {}
    text = read(os.path.join(src, "COMSEG.ASM"))
    for m in re.finditer(r"^[ \t]*(\w+)[ \t]+GROUP[ \t]+([\w,\t ]+)$", text, re.M | re.I):
        for seg in m.group(2).split(","):
            where[seg.strip().upper()] = m.group(1).upper()
    return where


def command_modules(src):
    """The modules COMLINK walks, in that order."""
    text = read(os.path.join(src, "COMLINK.ASM"))
    body = re.search(r"macro\s+walk\b[^{]*\{(.*?)^\}", text, re.S | re.M | re.I)
    names = re.findall(r"INCLUDE\s+'([^']+)'", body.group(1), re.I) if body else []
    return [n for n in names if os.path.exists(os.path.join(src, n))]


def segment_of(line, stack):
    """Follow the conditionals, so a nested IF does not end a segment block."""
    code = line.split(";")[0]
    if re.match(r"\s*if\b", code, re.I):
        m = re.match(r"\s*if\s+SEGSEL\s*=\s*S_(\w+)", code, re.I)
        stack.append(m.group(1).upper() if m else None)
        return True
    if re.match(r"\s*end\s+if\b", code, re.I):
        if stack:
            stack.pop()
        return True
    return False


def command_labels(src, mods, groups):
    """Every label COMMAND defines, and the group it is addressed in."""
    where = {}
    for name in mods:
        stack = []
        for line in read(os.path.join(src, name)).splitlines():
            if segment_of(line, stack):
                continue
            seg = next((s for s in reversed(stack) if s), None)
            if seg is None:
                continue
            code = line.split(";")[0]
            m = DEFINES.match(code) or DEFFASM.match(code) or DEFLABEL.match(line)
            if m:
                where[m.group(1).upper()] = (seg, groups.get(seg, seg))
    return where


def command_scan(path, where):
    assume = {"CS": None, "DS": None, "ES": None, "SS": None}
    findings = []
    lines = read(path).splitlines()
    if len(lines) < 2:
        sys.exit("%s came back as %d line(s): the line endings are not what "
                 "this expected." % (os.path.basename(path), len(lines)))
    for n, line in enumerate(lines, 1):
        code = line.split(";")[0]
        m = re.match(r"\s*;?ASSUME\s+(.*)", line, re.I)
        if m:
            for reg, grp in re.findall(r"(CS|DS|ES|SS):\s*(\w+)", m.group(1), re.I):
                assume[reg.upper()] = None if grp.upper() == "NOTHING" else grp.upper()
            continue
        for ref in REFERENCE.finditer(code):
            prefix = ref.group(1).upper() if ref.group(1) else None
            label = ref.group(2).upper()
            if label not in where:
                continue
            seg, want = where[label]
            reaches = lambda r: assume[r] in (want, seg)
            if prefix:
                if not reaches(prefix):
                    findings.append((n, label, want, "%s: is %s" %
                                     (prefix, assume[prefix] or "NOTHING"), line))
            elif not reaches("DS"):
                reach = [r for r in ("DS", "SS", "ES", "CS") if reaches(r)]
                findings.append((n, label, want,
                                 "MASM would use %s:" % reach[0] if reach
                                 else "nothing reaches it", line))
    return findings


def report(title, mods, found, labels, what):
    total = sum(len(f) for f in found.values())
    print("=== %s" % title)
    for name in mods:
        if found.get(name):
            print("%s:" % name)
            for finding in found[name]:
                n, label, want, why = finding[0], finding[1], finding[2], finding[3]
                print("  %5d  %-16s %-10s %-22s %s"
                      % (n, label, want, why, finding[4].strip()))
    print("%d module%s, %d %s, %d reference%s missing a segment override\n"
          % (len(mods), "" if len(mods) == 1 else "s", labels, what,
             total, "" if total == 1 else "s"))
    return total


def main():
    labels = data_labels(SRC)
    mods = modules(SRC)
    found = {n: scan(os.path.join(SRC, n), labels) for n in mods}
    total = report("the kernel, against the data segment", mods,
                   {n: [(a, b, "DOSGROUP", "DS is NOTHING", c)
                        for a, b, c in f] for n, f in found.items()},
                   len(labels), "data labels")

    groups = command_groups(SRC)
    mods = command_modules(SRC)
    where = command_labels(SRC, mods, groups)
    found = {n: command_scan(os.path.join(SRC, n), where) for n in mods}
    total += report("COMMAND.COM, against its three groups", mods, found,
                    len(where), "labels")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
