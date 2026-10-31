#!/usr/bin/env python3
"""Find memory references that lost their segment override in the conversion.

MASM resolves a variable's segment itself.  Under

        ASSUME  CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP
        MOV     BX,[sf_flags]

it knows sf_flags lives in DOSGROUP, sees that DS is not pointing there and
that SS is, and emits an SS: override.  fasm has no ASSUME: it takes the
reference at face value and goes through DS.  Nothing complains at assembly
time, and the result reads or writes whatever the current DS happens to
address.

That is what this found in the BIOS first.  MSINIT.ASM preserves the ROM's
INT 13H vector with DS pointing at the vector table:

        ASSUME  DS:NOTHING,ES:NOTHING
                MOV     AX,DS:[13H*4]
                MOV     WORD PTR ORIG13,AX

MASM put a CS: on the store, because CS was the only register reaching the
BIOS's own data; the conversion dropped the DS: from the load, which was
right, and did not add the CS: to the store, which was not.  ORIG13 therefore
kept the two characters MSBDATA.INC initialises it with -- "21", from the
joke serial number 598621 -- and the first disk read through the BIOS's INT
13H handler called 0000:3132 and the machine was gone.

So: walk every module, follow the ASSUME directives the conversion kept as
comments, and report each reference made through a register that is not
pointing where the label lives.  MASM's rule is to use whichever assumed
register reaches the label, DS for preference, and to refuse the line if none
does; a reference with no override is right only when DS reaches it.

Three passes, because the programs are laid out differently:

  * the kernel: six segments in one group, DOSGROUP, walked by MSDOSLNK.ASM.
    A label is reachable through any register assumed to its own segment or
    to the group, and what a module wraps in "if SEGSEL = S_CODE" is in the
    code segment.
  * the BIOS: two segments and no group, CODE and SYSINITSEG, the link file
    laying the modules of each down in turn.  So a label's segment is the
    half of MSBIOLNK.ASM its module is read in, and nothing but a register
    assumed to that segment reaches it.
  * the utilities under src/CMD, one program each, taken from the lines
    assemble.sh builds them with.  One of more than one segment has a link
    file of the kernel's shape and is read the same way; a .COM has none, and
    everything it defines is in the single segment its ASSUME puts CS on.
    What this does not see of them is the message retriever: SYSMSG.INC and
    MSGSERV.ASM reach their table through M_SEG$, which is a name rather than
    a register, so those references are not examined.

What it cannot see: a name the sources paste together.  MSSTACK.INC chains
each hardware interrupt on through "call dword [Old#AA]", where AA is the
vector's number, and no pass over the text can know that Old02 is a variable
of the stack code's own segment -- so that reference kept the DS the
interrupted program happened to have, and the machine followed it into the
interrupt vector table.  Those two lines name CS themselves now.

Three things that look like findings and are not:

  * "Context DS" is a macro, PUSH SS / POP DS, so it puts the data segment
    back into DS even though no ASSUME says so.  "Context ES" does the same
    for ES.

  * the sources habitually write

        ASSUME  DS:DOSGROUP
                LDS     DI,[THISCDS]
        ASSUME  DS:NOTHING

    where the second directive describes what DS has just become, not what it
    was during the load.  MASM believes the directives, and so does this.

  * an override the source wrote itself.  MASM emitted the prefix the line
    asked for and fasm emits the same one, so the conversion cannot have
    changed its meaning; where the ASSUME disagrees with it that is worth
    seeing, so those are listed as notes under the findings rather than as
    findings.

    python3 checkassume.py
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")

N = r"[A-Za-z_@?$][A-Za-z0-9_@?$]*"
DEFINES = re.compile(r"^\s*(" + N + r")\s+(?:DB|DW|DD|DQ|DT)\s", re.I)
DEFLABEL = re.compile(r"^(" + N + r"):")
DEFFASM = re.compile(r"^\s*label\s+(" + N + r")\s", re.I)
DECLARES = re.compile(r"(?i)^\s*I_am\s+(" + N + r")\s*,")
STRUCT = re.compile(r"(?i)^\s*(" + N + r")\s+(" + N + r")\s*$")
# The offset may be written with spaces round it -- [FOOSTRNG + 2] -- and a
# structure's field follows the name with a dot -- [DEVCALL.REQSTAT].  Missing
# either is not harmless: SYSINIT1 reads the second half of the CDS text the
# first way, and DskRead reads the device driver's status the second, and both
# of those references went unexamined.
REFERENCE = re.compile(r"\[(?:(cs|ds|es|ss):)?\s*(" + N + r")(?:\." + N + r")*"
                       r"(?:\s*[-+][^\]]*)?\]", re.I)
# A reference through a register says nothing about where a variable lives.
REGISTERS = {"AX", "BX", "CX", "DX", "SI", "DI", "BP", "SP",
             "AL", "BL", "CL", "DL", "AH", "BH", "CH", "DH"}


def read(path):
    with open(path, encoding="cp437", newline="") as f:
        return f.read()


def lines_of(path):
    text = read(path)
    lines = text.replace("\r\n", "\n").split("\n")
    if len(lines) < 2:
        sys.exit("%s came back as %d line(s): the line endings are not what "
                 "this expected, and the module would go unexamined."
                 % (os.path.basename(path), len(lines)))
    return lines


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


def kernel_modules():
    """The modules MSDOSLNK walks, in order, and the headers it reads itself."""
    text = read(os.path.join(SRC, "DOS", "MSDOSLNK.ASM"))
    body = re.search(r"macro\s+walk\b[^{]*\{(.*?)^\}", text, re.S | re.M | re.I)
    names = re.findall(r"include\s+'([^']+)'", body.group(1), re.I)
    out = []
    for n in names:
        p = os.path.normpath(os.path.join(SRC, "DOS", n))
        if os.path.exists(p):
            out.append(p)
    return out


# The headers every module reads: equates and structures, no ASSUME and no
# storage, so there is nothing in them for either pass.
SHARED = re.compile(r"(?i)(DOSSYM|DEVSYM|DOSSEG|DOSMAC|VERSION|BUGTYP|"
                    r"FASTOPEN|FASTSEEK|FASTXXXX|EA|IOCTL|IFSSYM|LOCK|"
                    r"DOSCNTRY|DPL|COPYRIGH|STRUC|SMDOSSYM|VERSIONA)\.")


# Where an include is looked for besides the including file's own directory.
# The kernel and the BIOS keep their modules together; a utility reads the
# shared headers out of src/INC, which fasm finds through INCLUDE.
SEARCH = []


def find(here, name):
    """The file an include names, or None."""
    for d in [here] + SEARCH:
        p = os.path.normpath(os.path.join(d, name))
        if os.path.exists(p):
            return p
    return None


def included(path, seen):
    """A module and whatever it includes of its own, the headers aside."""
    if path in seen:
        return []
    seen.add(path)
    out = [path]
    here = os.path.dirname(path)
    for m in re.finditer(r"(?i)^\s*include\s+'?([A-Za-z0-9_./\\]+)", read(path), re.M):
        name = m.group(1).replace("\\", "/")
        if SHARED.match(os.path.basename(name)) or name.upper().endswith((".SW", ".CL1", ".CL3")):
            continue
        p = find(here, name)
        if p:
            out += included(p, seen)
    return out


def kernel_labels(paths, default=None):
    """Every label a program defines, and the segment it is defined in.

    The segments are the ones the link file selects with SEGSEL, which is how
    the kernel and the .EXE utilities are laid out.  A one-segment .COM has no
    such blocks, and every label is in the segment named by default.

    The modules are read with their includes in place, because a module's
    SEGSEL block is what says which segment the header it reads inside it
    contributes to: FIND.ASM reads the parser inside its own.
    """
    where = {}
    for path in paths:
        stack = []
        for _, _, line in stream(path):
            if segment_of(line, stack):
                continue
            seg = next((s for s in reversed(stack) if s), None) or default
            if seg is None:
                continue
            code = line.split(";")[0]
            m = (DECLARES.match(code) or DEFINES.match(code)
                 or DEFFASM.match(code) or DEFLABEL.match(line))
            if not m:
                m = STRUCT.match(code)         # "DEVCALL SRHEAD", a structure
                if m and m.group(2).upper() in REGISTERS:
                    m = None
            if m:
                where.setdefault(m.group(1).upper(), seg)
    return where


def bios_segments():
    """Which of the BIOS's two segments each of its modules is read in."""
    text = read(os.path.join(SRC, "BIOS", "MSBIOLNK.ASM"))
    where = {}
    seg = None
    for line in text.replace("\r\n", "\n").split("\n"):
        code = line.split(";")[0]
        m = re.match(r"\s*(CODE|SYSINITSEG)\s*=", code, re.I)
        if m:
            seg = m.group(1).upper()
        m = re.match(r"(?i)\s*include\s+'([^']+)'", code)
        if m and seg:
            p = os.path.normpath(os.path.join(SRC, "BIOS", m.group(1)))
            if os.path.exists(p):
                where[p] = seg
    return where


def bios_labels(where):
    """Every label the BIOS defines, and which segment it is in."""
    out = {}
    for path, seg in where.items():
        for sub in included(path, set()):
            for line in lines_of(sub):
                code = line.split(";")[0]
                m = (DEFINES.match(code) or DEFFASM.match(code)
                     or DEFLABEL.match(line))
                if not m:
                    m = STRUCT.match(code)
                    if m and m.group(2).upper() in REGISTERS:
                        m = None
                if m:
                    out.setdefault(m.group(1).upper(), seg)
    return out


def stream(path, seen=None):
    """A module's lines with its own includes in place, as MASM read them.

    The ASSUMEs matter where they are read, and several of them are in
    MSGROUP.INC rather than in the module: each BIOS module gets its
    ASSUME CS:CODE from there, and STRIN.ASM, EXEC.ASM and the rest are read
    inside the module that includes them, under the ASSUMEs in force at that
    point.  Scanning each file on its own loses both.
    """
    if seen is None:
        seen = set()
    if path in seen:
        return []
    seen.add(path)
    out = []
    here = os.path.dirname(path)
    for n, line in enumerate(lines_of(path), 1):
        m = re.match(r"(?i)^\s*include\s+'?([A-Za-z0-9_./\\]+)", line.split(";")[0])
        if m:
            name = m.group(1).replace("\\", "/")
            sub = find(here, name)
            if not SHARED.match(os.path.basename(name)) and sub:
                out += stream(sub, seen)
                continue
        out.append((path, n, line))
    return out


def scan(path, labels, group):
    """Every reference in one module, judged against the ASSUMEs around it."""
    assume = {"CS": None, "DS": None, "ES": None, "SS": None}
    findings, notes = [], []
    for where, n, line in stream(path):
        code = line.split(";")[0]
        m = re.match(r"\s*;?\s*ASSUME\s+(.*)", line, re.I)
        if m:
            for reg, seg in re.findall(r"(CS|DS|ES|SS)\s*:\s*(\w+)", m.group(1), re.I):
                assume[reg.upper()] = None if seg.upper() == "NOTHING" else seg.upper()
            continue
        m = re.match(r"\s*Context\s+(DS|ES)\b", code, re.I)
        if m:
            # PUSH SS / POP reg: the data segment, whatever the ASSUMEs say.
            assume[m.group(1).upper()] = group or "CODE"
            continue
        for ref in REFERENCE.finditer(code):
            prefix = ref.group(1).upper() if ref.group(1) else None
            label = ref.group(2).upper()
            if label in REGISTERS or label not in labels:
                continue
            seg = labels[label]
            reaches = lambda r: assume[r] is not None and assume[r] in (seg, group)
            if prefix:
                if not reaches(prefix):
                    notes.append((where, n, label, seg, "%s: is %s" %
                                  (prefix, assume[prefix] or "NOTHING"), line))
            elif not reaches("DS"):
                reach = [r for r in ("DS", "SS", "ES", "CS") if reaches(r)]
                findings.append((where, n, label, seg,
                                 "MASM would use %s:" % reach[0] if reach
                                 else "nothing reaches it", line))
    return findings, notes


def report(title, paths, labels, group):
    print("======== %s" % title)
    print("%d labels, %d modules" % (len(labels), len(paths)))
    total = 0
    allnotes = 0
    for path in paths:
        findings, notes = scan(path, labels, group)
        total += len(findings)
        allnotes += len(notes)
        if findings:
            print("\n%s" % os.path.relpath(path, HERE))
            for where, n, label, seg, why, line in findings:
                print("  %-16s %5d  %-22s in %-10s %-22s %s"
                      % (os.path.basename(where), n, label, seg, why,
                         line.strip()[:52]))
    print("\n%d references lost an override, and %d the source wrote itself "
          "disagree with the ASSUMEs\n" % (total, allnotes))
    return total


def utilities():
    """The utilities assemble.sh builds, and the source it hands fasm."""
    text = read(os.path.join(HERE, "assemble.sh"))
    return re.findall(r"(?m)^utility\s+(\S+)\s+(\S+)\s+\S+", text)


def utility_program(where, source):
    """One utility's modules, the segment its labels are in, and its group.

    A utility of more than one segment has a link file of the kernel's shape:
    S_xxx equates name the segments, a walk macro names the modules, and the
    one fasm segment the file declares is the group MASM counted the offsets
    from.  A one-segment .COM is its own link file, and every label is in the
    segment its ASSUME puts CS on.
    """
    top = os.path.join(SRC, "CMD", where, source + ".ASM")
    if not os.path.exists(top):
        return None
    text = read(top)
    body = re.search(r"macro\s+walk\b[^{]*\{(.*?)^\}", text, re.S | re.M | re.I)
    if body:
        mods = []
        for n in re.findall(r"include\s+'([^']+)'", body.group(1), re.I):
            p = find(os.path.dirname(top), n)
            if p:
                mods.append(p)
        # One fasm segment holding the lot is the group MASM counted the
        # offsets from; more than one and there is no group, and a register
        # reaches only what it is assumed to.
        segs = re.findall(r"(?m)^segment\s+(\w+?)_?\s*$", text)
        return top, mods, None, segs[0].upper() if len(segs) == 1 else None
    m = re.search(r"(?i);?\s*ASSUME[^\n]*\bCS\s*:\s*(\w+)", text)
    return top, [top], m.group(1).upper() if m else None, None


def main():
    bios = bios_segments()
    paths = sorted(bios)
    everything = []
    for p in paths:
        everything += included(p, set())
    bad = report("the BIOS: CODE and SYSINITSEG, no group",
                 paths, bios_labels(bios), None)

    mods = kernel_modules()
    bad += report("the kernel: six segments in DOSGROUP",
                  mods, kernel_labels(mods), "DOSGROUP")

    # The utilities read the shared headers out of src/INC.
    SEARCH.append(os.path.join(SRC, "INC"))
    for where, source in utilities():
        program = utility_program(where, source)
        if program is None:
            continue
        top, mods, default, group = program
        if default:
            how = "%s, one segment" % default
        elif group:
            how = "the segments of the group %s" % group
        else:
            how = "segments of its own, with no group"
        bad += report("%s: %s" % (where, how),
                      mods, kernel_labels(mods, default), group)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
