#!/usr/bin/env python3
"""Convert FORMAT.ASM and GENFOR.ASM from MASM to FASM, in place.

FORMAT is the one utility in the release with no binary beside it: there is no
FORMAT.COM in bin, so the only way to have a formatter on this system is to
assemble the source.  It is a far smaller job than COMMAND was -- one segment,
ORG 100H, DS and ES the same as CS throughout -- so this does the whole thing
in a handful of passes rather than modelling groups and ASSUMEs.

What it changes, and why FASM needs it:

  * PUBLIC, EXTRN, SEGMENT, ENDS and the final END go: FORLINK.ASM assembles
    both modules together, so there is nothing left to resolve between them.
  * WORD PTR and BYTE PTR become word and byte, OFFSET goes, NAME LABEL SIZE
    becomes label NAME size, and ENDIF becomes end if.
  * EQU becomes =.  In FASM, EQU is a preprocessor directive, so a name
    defined with it inside an IF is defined either way; every one of FORMAT's
    is a plain number, and = is what it means.  TRUE EQU NOT FALSE becomes
    TRUE = -1, as FASM's NOT is bitwise and an OR of switches against -65536
    is not what the switch tests expect.
  * DW ? and DB n DUP (?) become zeros, which is what MASM reserved anyway.
  * [BP.FILE_START] becomes [BP+FILESTRUC.FILE_START], and the STRUC itself
    becomes a FASM struc with a virtual instance so the field names resolve.

Run from the v2.0 directory.  It refuses a file it has already converted.

    python3 convert_format.py
"""
import os
import re
import sys

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "source")
# In the order FORLINK.ASM assembles them.
MODULES = ("FORMAT.ASM", "FORMES.ASM", "GENFOR.ASM")
STRINGS = re.compile(r"'[^']*'|\"[^\"]*\"")

DROP = re.compile(r"""^\s*(
      \.(xlist|list|radix|xcref|cref)\b
    | (PAGE|SUBTTL|TITLE)\b
    | %OUT\b
    | PUBLIC\b
    | EXTRN\b
    | \w+\s+SEGMENT\b
    | \w+\s+ENDS\s*$
    | END(\s+(?!if\b|virtual\b|while\b|repeat\b|macro\b)\w+)?\s*$
    | INCLUDE\s+DOST:
)""", re.I | re.X)

# Names FASM will not take as labels.  Renamed outside string literals only:
# COMMAND's command table holds its command names as text, and renaming one of
# those along with the label broke the table.
RESERVED = ("STACK",)

# Locals that only stopped clashing because the modules were assembled apart:
# FORMAT's entry point is START and GENFOR keeps its current test sector in a
# word of the same name.
RENAMES = {"GENFOR.ASM": {"START": "GENSTART"}}

FIELDS = {}
LABELS = set()
DOSFIELDS = {}
DOSFIELD_RE = None


def dossym_fields():
    """MASM makes a STRUC's field names offsets in their own right, so FORMAT
    writes fcb_RECSIZ+7 where the converted DOSSYM.ASM has the field hanging
    off an instance as sys_fcb.fcb_RECSIZ."""
    text = open(os.path.join(SRC, "DOSSYM.ASM"), newline="").read()
    fields = {}
    for m in re.finditer(r"^STRUC\s+(\w+)\s*$(.*?)^\}", text, re.M | re.S | re.I):
        for f in re.finditer(r"^\.(\w+)\s", m.group(2), re.M):
            fields[f.group(1).upper()] = "%s.%s" % (m.group(1), f.group(1))
    return fields


def outside_strings(code, fn):
    out, pos = [], 0
    for s in STRINGS.finditer(code):
        out.append(fn(code[pos:s.start()]))
        out.append(s.group(0))
        pos = s.end()
    out.append(fn(code[pos:]))
    return "".join(out)


def struc(text):
    """Turn the MASM STRUC into a FASM one, and remember its fields."""
    m = re.search(r"^(\w+)\s+STRUC\s*$(.*?)^\1\s+ENDS\s*$", text, re.M | re.S | re.I)
    if not m:
        return text
    name, body = m.group(1), m.group(2)
    lines = []
    for line in body.splitlines():
        f = re.match(r"\s*(\w+)\s+(DB|DW|DD)\b(.*)$", line, re.I)
        if f:
            FIELDS[f.group(1).upper()] = "%s.%s" % (name, f.group(1))
            lines.append(".%-14s %s %s" % (f.group(1), f.group(2).lower(),
                                           "0" if "?" in f.group(3) else f.group(3).strip()))
        elif line.strip():
            lines.append(line.rstrip())
    new = ["STRUC %s" % name, "{"] + ["        " + l for l in lines] + ["}", "",
           "virtual at 0", "  %s %s" % (name, name),
           "  sizeof.%s = $ - %s" % (name, name), "end virtual"]
    return text[:m.start()] + "\n".join(new) + text[m.end():]


# A label may sit in front of the instruction, as in "FDPB:   MOV DL,DRIVE".
MNEMONIC = re.compile(r"^((?:\w+:)?\s+)([A-Za-z][\w]*)(\s+)(\S.*)$")
NOTCODE = {"DB", "DW", "DD", "LABEL", "INCLUDE", "IF", "ELSE", "END", "STRUC",
           "VIRTUAL", "ORG", "MACRO", "ASSUME", "EQU", "REPT", "IRP", "ENDM",
           "REPEAT", "DISPLAY", "ERR", "WHILE"}


def data_labels(text):
    """Everything the two modules reserve storage for.  MASM lets an
    instruction name one of these without brackets and resolves it to a memory
    reference; FASM reads the bare name as the address instead."""
    labels = set()
    for raw in text.splitlines():
        code = raw.split(";")[0]
        m = (re.match(r"^(\w+)\s+(?:DB|DW|DD)\b", code, re.I)
             or re.match(r"^\s*label\s+(\w+)\s", code, re.I))
        if m:
            labels.add(m.group(1).upper())
    return labels


def split_operands(text):
    """On commas outside brackets, so [BX+SI] survives."""
    out, depth, cur = [], 0, ""
    for ch in text:
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    out.append(cur)
    return out


def one_operand(op, labels):
    """Give a memory operand its brackets.  MASM writes the size and the
    segment outside them and in either order -- BYTE PTR DS:FOO and
    DS:BYTE PTR FOO both occur -- and FASM wants the size in front of the
    brackets and the segment inside."""
    m = re.match(r"^(\s*)(.*?)(\s*)$", op, re.S)
    lead, core, tail = m.group(1), m.group(2), m.group(3)
    size, seg = "", ""
    again = True
    while again:
        again = False
        ms = re.match(r"^(BYTE|WORD|DWORD)\s+PTR\s*(.*)$", core, re.I)
        if ms:
            size, core, again = ms.group(1).lower() + " ", ms.group(2).strip(), True
        mg = re.match(r"^(CS|DS|ES|SS):\s*(.*)$", core, re.I)
        if mg:
            seg, core, again = mg.group(1).upper() + ":", mg.group(2).strip(), True

    inner = None
    if core.startswith("[") and core.endswith("]"):
        inner = core[1:-1]
    elif seg:
        inner = core
    else:
        bare = re.match(r"^(\w+)((?:\s*[+-]\s*\w+)?)$", core)
        if bare and bare.group(1).upper() in labels:
            inner = bare.group(1) + bare.group(2).replace(" ", "")
    if inner is None:
        return op                       # a register or a number, left alone
    return "%s%s[%s%s]%s" % (lead, size, seg, inner, tail)


def bracket(body, labels):
    """MASM resolves a bare variable name to a memory reference; FASM reads it
    as the address.  Runs before OFFSET is taken off, so that MOV AX,OFFSET FOO
    stays an address and is not turned into a load from FOO."""
    m = MNEMONIC.match(body)
    if not m or m.group(2).upper() in NOTCODE:
        return body
    ops = [one_operand(op, labels) for op in split_operands(m.group(4))]
    return "%s%s%s%s" % (m.group(1), m.group(2), m.group(3), ",".join(ops))


def line(code):
    def words(t):
        t = re.sub(r"\b(BYTE|WORD|DWORD)\s+PTR\b", lambda m: m.group(1).lower(), t, flags=re.I)
        t = re.sub(r"\bOFFSET\s+", "", t, flags=re.I)
        t = re.sub(r"\bENDIF\b", "end if", t, flags=re.I)
        # BP.FIELD, the only structure FORMAT addresses that way
        t = re.sub(r"\b(BP|BX|SI|DI)\.(\w+)\b",
                   lambda m: "%s+%s" % (m.group(1), FIELDS.get(m.group(2).upper(), m.group(2))), t)
        if DOSFIELD_RE:
            t = DOSFIELD_RE.sub(lambda m: DOSFIELDS[m.group(1).upper()], t)
        t = re.sub(r"\bDUP\s*\(\s*\?\s*\)", "dup (0)", t, flags=re.I)
        t = re.sub(r"\b(DB|DW|DD)\s+\?\s*$", lambda m: m.group(1) + "      0", t, flags=re.I)
        for name in RESERVED:
            t = re.sub(r"\b%s\b" % name, name + "_", t, flags=re.I)
        return t
    return outside_strings(code, words)


def convert(text, renames, first=False):
    """first says this is the module that brings DOSSYM in: every module had
    its own INCLUDE of it, and including it twice redefines every structure."""
    out = []
    for raw in text.splitlines():
        if DROP.match(raw):
            continue
        if not first and re.match(r"\s*INCLUDE\s+DOSSYM", raw, re.I):
            continue
        body, sep, comment = raw.partition(";")
        if not body.strip():
            out.append(raw)
            continue
        m = re.match(r"^(\s*\w+\s+)LABEL\s+(BYTE|WORD|DWORD)\s*$", body, re.I)
        if m:
            body = "label %s %s" % (m.group(1).strip(), m.group(2).lower())
        m = re.match(r"^(\s*)(\w+)(\s+)EQU(\s+)(.*)$", body, re.I)
        if m:
            value, pad = m.group(5).rstrip(), ""
            pad = m.group(5)[len(value):]          # keep the comment lined up
            if re.fullmatch(r"NOT\s+FALSE", value, re.I):
                value = "-1"
            body = "%s%s%s=%s%s%s" % (m.group(1), m.group(2), m.group(3),
                                      m.group(4), value, pad)
        # FASM wants the file name quoted
        body = re.sub(r"^(\s*)INCLUDE\s+([\w.]+)\s*$", r"\1INCLUDE '\2'", body, flags=re.I)
        for was, now in renames.items():
            body = outside_strings(body, lambda t, w=was, n=now:
                                   re.sub(r"\b%s\b" % w, n, t))
        body = bracket(body, LABELS)
        body = line(body)
        out.append(body + sep + comment if sep else body)
    return "\n".join(out) + "\n"


def main():
    # The structures and the storage first, across all three modules at once:
    # FORMAT names variables that FORMES defines, so the set of things that
    # need brackets is only complete once every module has been read.
    global LABELS, DOSFIELDS, DOSFIELD_RE
    DOSFIELDS = dossym_fields()
    DOSFIELD_RE = re.compile(r"(?<![.\w])(%s)\b"
                             % "|".join(sorted(DOSFIELDS, key=len, reverse=True)),
                             re.I)
    texts = {}
    for name in MODULES:
        path = os.path.join(SRC, name)
        text = open(path, newline="").read()
        if "end if" in text or "virtual at" in text:
            sys.exit("%s looks converted already; nothing done." % name)
        texts[name] = struc(text)
    LABELS = set()
    for name, text in texts.items():
        found = data_labels(text)
        for was, now in RENAMES.get(name, {}).items():
            if was in found:
                found.discard(was)
                found.add(now.upper())
        LABELS |= found
    for name, text in texts.items():
        open(os.path.join(SRC, name), "w", newline="").write(
            convert(text, RENAMES.get(name, {}), name == MODULES[0]))
        print("converted %s" % name)
    print("%d labels that MASM would have resolved for itself" % len(LABELS))


if __name__ == "__main__":
    main()
