#!/usr/bin/env python3
"""Check that every converted STRUC still has the field offsets MASM gave it.

MASM's STRUC is a list of fields, and each field's name is its offset in the
structure.  FASM's is the same idea, so the conversion is mostly mechanical --
and mostly invisible when it goes wrong.  A field that reserves the wrong
number of bytes moves every field after it, the assembler has nothing to
complain about, and the program reads the right structure at the wrong place.

That is what happened to the directory entry CHKDSK reads.  The original says

        DIRENT  STRUC
                DB      7 DUP (?)       ;Ext FCB junk
                DB      ?               ;Drive
        DIRNAM  DB      11 DUP (?)
        DIRATT  DB      ?
                ...

and convert_utility.py turned any field whose operand held a "?" into a plain
0, so DIRNAM reserved one byte instead of eleven and carried DIRATT, DIRTIM,
DIRDAT, DIRCLUS and DIRESIZ ten bytes down with it.  CHKDSK then read each
file's first cluster out of the middle of its name, decided every file on the
disk was invalid, and reported all of their clusters as lost chains: 547 lost
clusters in 24 chains on a disk of 24 files, every one of them sized 0.  It
assembled without a word, and the report it printed looked like a report.

So: read each structure as the release wrote it, read it as it stands here,
and compare the fields one for one.  Sizes are compared as expressions rather
than numbers -- "DIRSTRLEN DUP (?)" against "DIRSTRLEN dup (0)" -- so nothing
here has to know what the equates are worth; a field that reserved 11 bytes
and now reserves 1 reads as 11*1 against 1*1 either way.

The original comes out of the commit that added the file, so this works for
any version in the repository and needs no list of its own.  Files that have
not been converted yet are named and skipped: there both sides are the same
text, and comparing them would prove nothing.

Clean on v2.0's forty structures and v1.25's three as they stand, and it
reads a tree as well as a flat directory, so v4.0's sources -- where most of
the structures are in the .INC files under src/INC -- are compared too.  Checked
against the defect above and two more like it: put DIRNAM back to one byte
and it says "reserves 1*1, the original 11*1"; make DIRTIM a DB and it says
"reserves 1*1, the original 1*2"; misspell DIRDAT and it says which field is
only in the conversion.  It reports the first field of a structure that moved
and stops there, everything after it having moved by the same amount.

    python3 checkstruc.py [source-directory]
"""
import os, re, subprocess, sys

SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "src")
REPO = subprocess.run(["git", "-C", SRC, "rev-parse", "--show-toplevel"],
                      capture_output=True, text=True).stdout.strip()

UNIT = {"DB": 1, "DW": 2, "DD": 4, "DQ": 8, "DT": 10, "DF": 6}
# MASM's form, "NAME DB 11 DUP (?)", and FASM's, ".NAME db 11 dup (0)".
MASM = re.compile(r"^\s*(?:(\w+)\s+)?(D[BWDQTF])\s+(.*)$", re.I)
FASM = re.compile(r"^\s*(?:(\.\w+)\s+)?(D[BWDQTF])\s+(.*)$", re.I)
# One structure inside another.  MASM had no such thing and wrote the room for
# it by hand -- "EXT_BOOT_BPB DB type EXT_BPB_INFO dup (?)" -- where fasm can
# name the structure and get its fields with it, so the two read differently
# and reserve the same.
NESTED = re.compile(r"^\s*(\.\w+)\s+(\w+)\s*$")


def git(*args):
    out = subprocess.run(["git", "-C", REPO] + list(args), capture_output=True)
    return out.stdout.decode("latin-1")


def origin(path):
    """The file as the release wrote it: the commit that added it."""
    rel = os.path.relpath(os.path.abspath(path), REPO)
    adds = git("log", "--diff-filter=A", "--format=%H", "--", rel).split()
    return git("show", "%s:%s" % (adds[-1], rel)).replace("\r", "") if adds else None


def items(operand):
    """The operand's top level items, strings and parentheses kept whole."""
    out, depth, cur, quote = [], 0, "", None
    for c in operand:
        if quote:
            cur += c
            if c == quote:
                quote = None
        elif c in "\"'":
            quote, cur = c, cur + c
        elif c == "(":
            depth, cur = depth + 1, cur + c
        elif c == ")":
            depth, cur = depth - 1, cur + c
        elif c == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += c
    out.append(cur)
    return [i.strip() for i in out if i.strip()]


def size(unit, operand):
    """What a field reserves, as a count of units: 11 for 11 DUP (?)."""
    terms = []
    for item in items(operand):
        m = re.match(r"^(.*?)\bDUP\b\s*\(.*\)$", item, re.I | re.S)
        if m:
            terms.append(norm(m.group(1)))
        elif re.match(r"^[\"'].*[\"']$", item, re.S):
            terms.append(str(len(item[1:-1])))
        else:
            terms.append("1")
    return "%s*%d" % ("+".join(terms) or "1", UNIT[unit.upper()])


def norm(expr):
    """One spelling for an expression, so the two sides can be compared."""
    expr = re.sub(r"\s+", "", expr).upper()
    # MASM's SIZE operator against the converted sizeof., without turning
    # an already converted SIZEOF.X into SIZEOF.OF.X.
    expr = re.sub(r"\bSIZE(?!OF\.)([A-Z_]\w*)", r"SIZEOF.\1", expr)
    return expr.strip("()") or "1"


def fields(body, pattern):
    """The fields of one structure body, in order."""
    out = []
    for line in body.splitlines():
        code = line.split(";")[0].rstrip()
        if not code.strip():
            continue
        m = pattern.match(code)
        if m:
            name = (m.group(1) or "").lstrip(".").upper()
            out.append((name, size(m.group(2), m.group(3))))
            continue
        m = NESTED.match(code) if pattern is FASM else None
        if m:
            out.append((m.group(1).lstrip(".").upper(),
                        "TYPE%s*1" % m.group(2).upper()))
    return out


def masm_strucs(text):
    found = {}
    for m in re.finditer(r"^(\w+)\s+STRUC\s*$(.*?)^\1\s+ENDS\s*$", text, re.M | re.S | re.I):
        found[m.group(1).upper()] = fields(m.group(2), MASM)
    return found


def fasm_strucs(text):
    found = {}
    for m in re.finditer(r"^\s*STRUC\s+(\w+)[^\n]*\n\s*\{(.*?)^\s*\}", text, re.M | re.S | re.I):
        found[m.group(1).upper()] = fields(m.group(2), FASM)
    return found


def compare(was, now):
    """What the conversion changed: findings first, then renames.

    A field renamed but left the same size moves nothing, and the conversion
    has to rename the ones MASM allowed and FASM does not -- v1.25's STKPTRS
    has a field called FSAVE, which is an x87 instruction here.  Those are
    reported as notes, the uses having been renamed with them, and do not
    count as findings."""
    findings, notes = [], []
    for i in range(max(len(was), len(now))):
        a = was[i] if i < len(was) else None
        b = now[i] if i < len(now) else None
        if a is None or b is None:
            findings.append(((a or b)[0] or "(unnamed)", "field %d is only in the %s"
                             % (i, "original" if b is None else "conversion")))
            break               # the fields after it cannot be lined up
        if a[1] != b[1]:
            findings.append((b[0] or "(unnamed)", "reserves %s, the original %s"
                             % (b[1], a[1])))
            break               # everything after it has moved; say it once
        if a[0] != b[0]:
            notes.append((b[0] or "(unnamed)", "was %s" % (a[0] or "(unnamed)")))
    return findings, notes


def main():
    if not REPO:
        sys.exit("%s is not in a git repository, and the originals are read "
                 "from the commit that added each file." % SRC)
    names = []
    for here, dirs, files in os.walk(SRC):
        dirs.sort()
        for n in sorted(files):
            if n.upper().endswith((".ASM", ".INC")):
                names.append(os.path.relpath(os.path.join(here, n), SRC))
    checked, skipped, total, renamed = 0, [], 0, []
    every = {}
    for name in names:
        with open(os.path.join(SRC, name), encoding="cp437", newline="") as f:
            every[name] = fasm_strucs(f.read())
    for name in names:
        path = os.path.join(SRC, name)
        now = every[name]
        was = masm_strucs(origin(path) or "")
        if not was:
            continue
        if not now:
            skipped.append(name)
            continue
        for struc in sorted(was):
            if struc not in now:
                # MASM gave every module that used a structure its own copy of
                # the declaration; one assembly needs one, so the conversion
                # keeps whichever file declared it first and comments the rest
                # out.  Compare against that one.
                elsewhere = [(f, s[struc]) for f, s in every.items()
                             if struc in s and f != name]
                if elsewhere:
                    where, theirs = elsewhere[0]
                    findings, notes = compare(was[struc], theirs)
                    for field, why in findings:
                        print("%-16s %-18s %-14s %s (declared in %s)"
                              % (name, struc, field, why, where))
                        total += 1
                    if not findings:
                        checked += 1
                    continue
                print("%s: %s is in the original and not here" % (name, struc))
                total += 1
                continue
            checked += 1
            findings, notes = compare(was[struc], now[struc])
            for field, why in findings:
                print("%-16s %-18s %-14s %s" % (name, struc, field, why))
                total += 1
            renamed.extend((name, struc, field, why) for field, why in notes)
    if skipped:
        print("not converted yet, so not compared: %s" % ", ".join(skipped))
    if renamed:
        print("renamed, and the same size, so nothing moved:")
        for name, struc, field, why in renamed:
            print("  %-14s %-18s %-14s %s" % (name, struc, field, why))
    print("%d structure%s compared, %d field%s changed"
          % (checked, "" if checked == 1 else "s", total, "" if total == 1 else "s"))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
