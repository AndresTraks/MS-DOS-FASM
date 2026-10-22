#!/usr/bin/env python3
"""Convert one of the release's utilities from MASM to FASM, in place.

    python3 convert_utility.py FORMAT
    python3 convert_utility.py SYS

FORMAT is the one utility in the release with no binary beside it: there is no
FORMAT.COM in bin, so the only way to have a formatter on this system is to
assemble the source.  SYS and CHKDSK do have binaries, but they were built for
2.00 and refuse to run on 2.11, which is what this DOS reports; built from the
source in this directory they accept it, the source itself saying 1.54 to 2.11.

These are far smaller jobs than COMMAND was, so this works in passes rather
than modelling groups and ASSUMEs:

  * PUBLIC, EXTRN, SEGMENT, ENDS, GROUP and the final END go: the link file
    assembles every module of a program together, so there is nothing left to
    resolve between them.
  * WORD PTR and BYTE PTR become word and byte, OFFSET goes, NAME LABEL SIZE
    becomes label NAME size, and ENDIF becomes end if.
  * EQU becomes =.  In FASM, EQU is a preprocessor directive, so a name
    defined with it inside an IF is defined either way; these are all plain
    numbers, and = is what they mean.  TRUE EQU NOT FALSE becomes TRUE = -1,
    as FASM's NOT is bitwise and an OR of switches against -65536 is not what
    a switch test expects.
  * DW ? and DB n DUP (?) become zeros, which is what MASM reserved anyway.
  * A bare variable name gets the brackets MASM did not need.  That pass runs
    before OFFSET is taken off, so MOV AX,OFFSET FOO stays an address instead
    of turning into a load from FOO.
  * MASM makes a STRUC's field names offsets in their own right, so a field is
    rewritten to hang off its structure as the converted DOSSYM.ASM has it.

A program whose segments are listed below is wrapped segment by segment in
"if SEGSEL = S_<name>", the way COMMAND's modules are, and its link file sets
SEGSEL and reads every module once per segment to lay them out in load order.

It refuses a file it has already converted.
"""
import os
import re
import sys

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "source")
# In the order FORLINK.ASM assembles them.
# Per program: the modules in the order the link file assembles them, the
# segments to wrap if there is more than one, the names FASM will not take as
# labels, and locals that only stopped clashing because the modules used to be
# assembled apart.
PROGRAMS = {
    "FORMAT": {
        "dossym": "DOSSYM.ASM",
        "modules": ("FORMAT.ASM", "FORMES.ASM", "GENFOR.ASM"),
        "segments": (),
        "group": "",
        "reserved": ("STACK",),
        "macros": {},
        "renames": {"GENFOR.ASM": {"START": "GENSTART"}},
    },
    "FC": {
        # Lays out like SORT: code, const and data in the group dg, with a
        # stack segment of its own outside it.  It does include DOSSYM, in
        # lower case -- "include dossym.asm" -- which is easy to miss.
        "dossym": "DOSSYM.ASM",
        "modules": ("FC.ASM", "FCMES.ASM"),
        "segments": ("CODE", "CONST", "DATA", "STACK"),
        "group": "DG",
        "reserved": ("CODE", "DATA", "STACK"),
        "renames": {},
        "macros": {},
    },
    "SORT": {
        "dossym": "DOSSYM.ASM",
        "modules": ("SORT.ASM", "SORTMES.ASM"),
        # Three macros of its own, none of which defines storage, so they are
        # named here only to mark their calls as not being instructions.
        "macros": {"sys": (), "save": (), "restore": ()},
        # CODE, CONST and CSTACK in one group, as CHKDSK's three are, so the
        # walk lays them out in one FASM segment and the offsets come out
        # group relative by themselves.  An .EXE all the same, for the stack.
        "segments": ("CODE", "CONST", "CSTACK"),
        "group": "DG",
        # FASM's restore directive, which SORT.ASM uses as a macro name: a
        # collision in the macros rather than the labels, where the others
        # have been.
        "reserved": ("restore",),
        "renames": {},
    },
    "FIND": {
        # The one program here that includes no DOSSYM: its equates are its
        # own.  Two segments, code and a stack, so it is an .EXE as well.
        "dossym": "",
        "modules": ("FIND.ASM", "FINDMES.ASM"),
        "segments": ("CODE", "STACK"),
        "group": "",
        "reserved": ("CODE", "STACK"),
        "renames": {},
        "macros": {},
    },
    "EXE2BIN": {
        "dossym": "DOSSYM.ASM",
        "modules": ("EXE2BIN.ASM", "EXEMES.ASM"),
        # The only .EXE here, so the only one with segments of its own rather
        # than one address space: FASM takes CODE, DATA and STACK for itself,
        # hence the renaming, and the link file turns each into a real segment.
        "segments": ("CODE", "DATA", "STACK", "ZLOAD"),
        "group": "",
        "reserved": ("CODE", "DATA", "STACK", "LOAD", "STORE"),
        "renames": {},
        "macros": {},
    },
    "MORE": {
        "dossym": "DOSSYM.ASM",
        "modules": ("MORE.ASM", "MOREMES.ASM"),
        "segments": (),
        "group": "",
        "reserved": (),
        "renames": {},
        "macros": {},
    },
    "CHKDSK": {
        "dossym": "DOSSYM_v211.ASM",
        "modules": ("CHKDSK.ASM", "CHKPROC.ASM", "CHKMES.ASM"),
        "segments": ("CODE", "CONST", "DATA"),
        "group": "DG",
        "reserved": (),
        "renames": {},
        "macros": {},
    },
    "SYS": {
        "dossym": "DOSSYM.ASM",
        "modules": ("SYS.ASM", "SYSMES.ASM"),
        "segments": ("CODE", "CONST", "DATA"),
        "group": "DG",
        "reserved": (),
        # "label" is a FASM directive, so the macro's parameter needs another
        # name; the macro itself defines both NAME and NAMELen.
        "renames": {"SYSMES.ASM": {"label": "mname"}},
        "macros": {"MESSAGE": ("", "Len")},
    },
}
STRINGS = re.compile(r"'[^']*'|\"[^\"]*\"")

DROP = re.compile(r"""^\s*(
      \.(xlist|list|radix|xcref|cref
         |sall|lall|xall|sfcond|lfcond|tfcond)\b
    | (PAGE|SUBTTL|TITLE)\b
    | %OUT\b
    | PUBLIC\b
    | EXTRN\b
    | \w+\s+SEGMENT\b
    | \w+\s+ENDS\s*$
    | \w+\s+GROUP\b
    | END(\s+(?!if\b|virtual\b|while\b|repeat\b|macro\b)\w+)?\s*$
    | INCLUDE\s+DOST:
)""", re.I | re.X)

# Names FASM will not take as labels.  Renamed outside string literals only:
# COMMAND's command table holds its command names as text, and renaming one of
# those along with the label broke the table.
RESERVED = ()
RENAMES = {}
GROUP = ""
MACROS = {}
CANON = {}
CANON_RE = None
STRUCS = {}
STRUC_PARAMS = {}
DOSSYM = "DOSSYM.ASM"
MODULES = ()
SEGMENTS = ()

FIELDS = {}
LABELS = set()
SIZES = {}
DOSFIELDS = {}
DOSFIELD_RE = None


def dossym_fields():
    """MASM makes a STRUC's field names offsets in their own right, so FORMAT
    writes fcb_RECSIZ+7 where the converted DOSSYM.ASM has the field hanging
    off an instance as sys_fcb.fcb_RECSIZ."""
    if not DOSSYM:
        return {}               # FIND includes nothing: its equates are its own
    text = open(os.path.join(SRC, DOSSYM), newline="").read()
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


# MASM's way of writing a macro that takes a list: the macro takes one
# parameter and an IRP inside it walks the list, with an ENDM of its own
# before the macro's.  SORT.ASM has two, save and restore.  FASM says the
# same thing with a variadic parameter and forward, so the shape is rewritten
# whole rather than line by line -- the two ENDMs would otherwise both become
# a closing brace and leave the IRP standing in the body.
# The CR of a CRLF file counts as neither space nor tab, so every line end
# here has to allow for it: these sources are not all one or the other.
IRPMACRO = re.compile(r"^(\w+)[ \t]+MACRO[ \t]+(\w+)[ \t]*(;[^\n]*?)?\r?\n"
                      r"[ \t]*IRP[ \t]+(\w+)[ \t]*,[ \t]*<[ \t]*\2[ \t]*>[^\n]*\n"
                      r"(.*?)"
                      r"^[ \t]*ENDM[^\n]*\n"
                      r"^[ \t]*ENDM[ \t\r]*$", re.M | re.S | re.I)


def irp_macros(text):
    """Turn MASM's MACRO-around-an-IRP into FASM's variadic macro."""
    nl = "\r\n" if "\r\n" in text else "\n"
    return IRPMACRO.sub(lambda m: "macro %s [%s]%s%s{%sforward%s%s}"
                        % (m.group(1), m.group(4),
                           " " + m.group(3).strip() if m.group(3) else "",
                           nl, nl, nl, m.group(5)), text)


def struc(text):
    """Turn the MASM STRUC into a FASM one, and remember its fields."""
    while True:
        text, done = one_struc(text)
        if done:
            return text


def one_struc(text):
    m = re.search(r"^(\w+)\s+STRUC\s*$(.*?)^\1\s+ENDS\s*$", text, re.M | re.S | re.I)
    if not m:
        return text, True
    name, body = m.group(1), m.group(2)
    STRUCS[name.upper()] = name
    lines = []
    for line in body.splitlines():
        f = re.match(r"\s*(\w+)\s+(DB|DW|DD)\b(.*)$", line, re.I)
        if f:
            FIELDS[f.group(1).upper()] = "%s.%s" % (name, f.group(1))
            # A field reserving several bytes keeps its count: dropping it for
            # a plain 0 would shift every field after it.
            init = f.group(3)
            if re.search(r"\bDUP\b", init, re.I):
                init = re.sub(r"\bDUP\s*\(\s*\?\s*\)", "dup (0)", init,
                              flags=re.I).strip()
            else:
                init = "0" if "?" in init else init.strip()
            lines.append(".%-14s %s %s" % (f.group(1), f.group(2).lower(), init))
        elif line.strip():
            lines.append(line.rstrip())
    new = ["STRUC %s" % name, "{"] + ["        " + l for l in lines] + ["}", "",
           "virtual at 0", "  %s %s" % (name, name),
           "  sizeof.%s = $ - %s" % (name, name), "end virtual"]
    return text[:m.start()] + "\n".join(new) + text[m.end():], False


# A label may sit in front of the instruction, as in "FDPB:   MOV DL,DRIVE".
MNEMONIC = re.compile(r"^((?:\w+:)?\s+)([A-Za-z][\w]*)(\s+)(\S.*)$")
NOTCODE = {"DB", "DW", "DD", "LABEL", "INCLUDE", "IF", "ELSE", "END", "STRUC",
           "VIRTUAL", "ORG", "MACRO", "ASSUME", "EQU", "REPT", "IRP", "ENDM",
           "REPEAT", "DISPLAY", "ERR", "WHILE",
           # A macro's LOCAL names are names, not memory: FC's m_bname
           # declares b1 and b2 local and defines them in the same breath, and
           # bracketing them in the declaration is not what it meant.
           "LOCAL"}


def dossym_spellings(canon):
    """DOSSYM.ASM's own names, which the utilities write in whatever case they
    felt like: SYS.ASM asks for Write and DOSSYM defines WRITE."""
    if not DOSSYM:
        return          # FIND includes nothing, so it spells nothing two ways
    text = open(os.path.join(SRC, DOSSYM), newline="").read()
    for raw in text.splitlines():
        code = raw.split(";")[0]
        for m in (re.match(r"^(\w+)\s+EQU\b", code, re.I),
                  re.match(r"^(\w+)\s*=", code),
                  re.match(r"^(\w+)\s+(?:DB|DW|DD)\b", code, re.I),
                  re.match(r"^STRUC\s+(\w+)", code, re.I),
                  re.match(r"^\s*label\s+(\w+)\s", code, re.I)):
            if m:
                canon.setdefault(m.group(1).upper(), m.group(1))
        m = re.match(r"^STRUC\s+(\w+)(.*)$", code, re.I)
        if m:
            STRUCS.setdefault(m.group(1).upper(), m.group(1))
            # A parameterised STRUC, as DOSSYM_v211.ASM writes internat_block:
            # an instance of it has to be given a value for each parameter.
            params = [x for x in m.group(2).split(",") if x.strip()]
            if params:
                STRUC_PARAMS[m.group(1).upper()] = len(params)
    return canon


def spellings(text, canon):
    """MASM did not care about case and FASM does, so every name has to be
    spelt the way it is defined: SYSMES.ASM's macro defines BadParm and
    SYS.ASM asks for BADPARM.

    Equates as well as storage, which they were left out of at first.  Two
    modules of one program can define the same name in different cases --
    SORT.ASM writes TRUE and SORTMES.ASM writes true -- and whichever of them
    is read last decides, so that the uses and the definition agree."""
    for raw in text.splitlines():
        code = raw.split(";")[0]
        for m in (re.match(r"^(\w+)\s+(?:DB|DW|DD)\b", code, re.I),
                  re.match(r"^(\w+)\s+EQU\b", code, re.I),
                  re.match(r"^(\w+)\s*=", code),
                  re.match(r"^\s*label\s+(\w+)\s", code, re.I),
                  re.match(r"^(\w+):", code)):
            if m:
                canon[m.group(1).upper()] = m.group(1)
        for name, suffixes in MACROS.items():
            m = re.match(r"^\s*%s\s+(\w+)\s*," % name, code, re.I)
            if m:
                for suffix in suffixes:
                    canon[(m.group(1) + suffix).upper()] = m.group(1) + suffix
    return canon


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
            d = re.match(r"^\s*\w+\s+(DB|DW|DD)\b", code, re.I)
            if d:
                SIZES[m.group(1).upper()] = {"DB": "byte", "DW": "word",
                                             "DD": "dword"}[d.group(1).upper()]
            continue
        # A macro that defines storage, as SYSMES.ASM's Message defines both
        # the text and a word holding its length.
        for name, suffixes in MACROS.items():
            m = re.match(r"^\s*%s\s+(\w+)\s*," % name, code, re.I)
            if m:
                for suffix in suffixes:
                    labels.add((m.group(1) + suffix).upper())
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
        mp = re.match(r"^\((.*)\)$", core)          # DS:(BYTE PTR 5DH)
        if mp:
            core, again = mp.group(1).strip(), True

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

    # PUSH and POP of memory: MASM took a word, FASM wants it said.
    if m.group(2).upper() in ("PUSH", "POP"):
        for i, op in enumerate(ops):
            if re.fullmatch(r"\s*\[[^\]]+\]\s*", op):
                ops[i] = op.replace("[", "word [", 1)

    # MASM let a byte register meet a word variable and took the low byte of
    # it -- CHKDSK does XCHG AL,ERRSUB where ERRSUB is a DW.  FASM wants the
    # size said, so say it.
    if any(re.fullmatch(r"\s*[ABCD][LH]\s*", op, re.I) for op in ops):
        for i, op in enumerate(ops):
            b = re.fullmatch(r"(\s*)\[(\w+)([^\]]*)\](\s*)", op)
            if b and SIZES.get(b.group(2).upper(), "byte") != "byte":
                ops[i] = "%sbyte [%s%s]%s" % (b.group(1), b.group(2),
                                              b.group(3), b.group(4))
    return "%s%s%s%s" % (m.group(1), m.group(2), m.group(3), ",".join(ops))


def line(code):
    def words(t):
        t = re.sub(r"\b(BYTE|WORD|DWORD)\s+PTR\b", lambda m: m.group(1).lower(), t, flags=re.I)
        t = re.sub(r"\bOFFSET\s+", "", t, flags=re.I)
        # MASM's SIZE operator on a structure, which the converted form of it
        # states as sizeof.NAME beside the instance.
        t = re.sub(r"\bSIZE\s+(\w+)\b",
                   lambda m: ("sizeof.%s" % STRUCS[m.group(1).upper()]
                              if m.group(1).upper() in STRUCS else m.group(0)), t,
                   flags=re.I)
        # The group qualifier, as in OFFSET DG:BADVER.  Every segment of these
        # programs is in the one group and the link file lays them out from a
        # single origin, so a group-relative offset is what the label already
        # is and the qualifier has nothing left to say.
        if GROUP:
            t = re.sub(r"\b%s:" % GROUP, "", t, flags=re.I)
            # The group's first segment shares its base, so a qualifier
            # naming it says nothing either: FC writes "offset code:b2" and
            # code is the first of dg.  Only the first, deliberately -- a
            # qualifier naming any of the others would mean an offset counted
            # from somewhere else, and it is better that FASM refuse the line
            # than that this quietly drop the difference.
            if SEGMENTS:
                t = re.sub(r"\b%s_?:" % SEGMENTS[0], "", t, flags=re.I)
        t = re.sub(r"\bENDIF\b", "end if", t, flags=re.I)
        # BP.FIELD, the way FORMAT addresses a structure, and [BX].FIELD,
        # the way FC does it throughout: "mov word [bx].buf,b1" means
        # [bx+buf], buf being an equate rather than a structure field -- FC
        # declares no structure at all and counts its offsets out by hand.
        t = re.sub(r"\b(BP|BX|SI|DI)\.(\w+)\b",
                   lambda m: "%s+%s" % (m.group(1), FIELDS.get(m.group(2).upper(), m.group(2))), t)
        t = re.sub(r"\[\s*(BP|BX|SI|DI)\s*\]\s*\.(\w+)\b",
                   lambda m: "[%s+%s]" % (m.group(1),
                                          FIELDS.get(m.group(2).upper(), m.group(2))),
                   t, flags=re.I)
        if CANON_RE:
            t = CANON_RE.sub(lambda m: CANON[m.group(1).upper()], t)
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
    out, inmacro, infar = [], [], []
    for raw in text.splitlines():
        # Before anything else, so that a renamed macro parameter is renamed
        # in the MACRO line too and not only in the body.
        for was, now in renames.items():
            raw = outside_strings(raw, lambda t, w=was, n=now:
                                  re.sub(r"\b%s\b" % w, n, t))
        if SEGMENTS:
            m = re.match(r"^\s*(\w+)\s+SEGMENT\b", raw, re.I)
            if m and m.group(1).upper() in SEGMENTS:
                out.append("if SEGSEL = S_%s" % m.group(1).upper())
                continue
            m = re.match(r"^\s*(\w+)\s+ENDS\s*$", raw, re.I)
            if m and m.group(1).upper() in SEGMENTS:
                out.append("end if")
                continue
        # FASM's macro names are case sensitive, and the ASSUME the conversion
        # leans on -- a macro that does nothing, MASM's being a directive --
        # is spelled in capitals.  The sources are not consistent about it:
        # EXE2BIN.ASM writes "assume es:data" half the time.
        m = re.match(r"^(\s*)ASSUME\b(.*)$", raw, re.I)
        if m:
            raw = "%sASSUME%s" % (m.group(1), m.group(2))
        # A PROC is just a label, except that MASM assembles the RET of a FAR
        # one as a far return.  CHKPROC's INT_24 depends on it: it pushes a
        # frame and the far address of the handler and returns to that.
        # The comment after it is not decoration in every source: FIND has
        # "badfart proc far ;(what a hack!!)", and without the comment allowed
        # for here the line went through as an instruction and FASM refused it.
        m = re.match(r"^(\s*)(\w+)\s+PROC\s*(NEAR|FAR)?\s*(;.*)?$", raw, re.I)
        if m:
            out.append("%s%s:%s" % (m.group(1), m.group(2), m.group(4) or ""))
            infar.append((m.group(3) or "NEAR").upper() == "FAR")
            continue
        if re.match(r"^\s*\w+\s+ENDP\s*(;.*)?$", raw, re.I):
            if infar:
                infar.pop()
            continue
        if infar and infar[-1]:
            raw = re.sub(r"^(\s*)RET(\s*(;.*)?)$", r"\1RETF\2", raw, flags=re.I)
        m = re.match(r"^\s*(\w+)\s+MACRO\s*(.*?)\s*$", raw, re.I)
        if m:
            out.append("macro %s %s" % (m.group(1), m.group(2)))
            out.append("{")
            inmacro.append(True)
            continue
        if re.match(r"^\s*ENDM\s*$", raw, re.I):
            out.append("}")
            if inmacro:
                inmacro.pop()
            continue
        if inmacro:
            raw = raw.replace("&", "#")         # MASM pastes with &, FASM with #
        raw = re.sub(r'<(\s*"[^"]*"\s*)>', r"\1", raw)    # <"text"> in a call
        # MASM hands a macro its list in angle brackets, FASM plainly:
        # SORT.ASM writes save <SI,DI> and restore <DI,SI>.
        m = re.match(r"^(\s*)(\w+)(\s+)<([^>\"]*)>(\s*(?:;.*)?)$", raw)
        if m and m.group(2).upper() in {k.upper() for k in MACROS}:
            raw = "".join((m.group(1), m.group(2), m.group(3),
                           m.group(4).strip(), m.group(5)))
        # A structure instance: MASM takes the default values as <>, and FASM
        # declares the instance as NAME STRUC and names its fields NAME.field.
        m = re.match(r"^(\s*\w+\s+)(\w+)\s*<\s*>\s*$", raw)
        if m:
            n = STRUC_PARAMS.get(m.group(2).upper(), 0)
            raw = m.group(1) + m.group(2) + (" " + ",".join("?" * n) if n else "")
        if DROP.match(raw):
            continue
        # A segmented program has its modules read once per segment, so the
        # link file brings DOSSYM in and none of the modules may.
        if (SEGMENTS or not first) and re.match(r"\s*INCLUDE\s+DOSSYM", raw, re.I):
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
        body = bracket(body, LABELS)
        body = line(body)
        out.append(body + sep + comment if sep else body)
    return "\n".join(out) + "\n"


def main(program):
    # The structures and the storage first, across every module at once: one
    # module names variables another defines, so the set of things that need
    # brackets is only complete once all of them have been read.
    global LABELS, DOSFIELDS, DOSFIELD_RE, MODULES, SEGMENTS, RESERVED, RENAMES
    if program not in PROGRAMS:
        sys.exit("usage: convert_utility.py %s" % " | ".join(sorted(PROGRAMS)))
    spec = PROGRAMS[program]
    MODULES, SEGMENTS = spec["modules"], tuple(spec["segments"])
    RESERVED, RENAMES = spec["reserved"], spec["renames"]
    global GROUP
    GROUP = spec["group"]
    global DOSSYM
    DOSSYM = spec["dossym"]
    global MACROS
    MACROS = spec["macros"]
    # A macro call is not an instruction, and its arguments are names rather
    # than memory: bracketing them would pass [BadDrv] where BadDrv was meant.
    NOTCODE.update(MACROS)
    DOSFIELDS = dossym_fields()
    texts = {}
    for name in MODULES:
        path = os.path.join(SRC, name)
        text = open(path, newline="").read()
        if "end if" in text or "virtual at" in text:
            sys.exit("%s looks converted already; nothing done." % name)
        texts[name] = struc(irp_macros(text))
    # The program's own structures are read by now, and MASM makes their field
    # names offsets in their own right as well, so they go in the same map.
    DOSFIELDS.update(FIELDS)
    # None rather than a pattern of nothing, which would match everywhere:
    # FIND includes no DOSSYM and so has no fields to rewrite.
    DOSFIELD_RE = re.compile(r"(?<![.\w])(%s)\b"
                             % "|".join(sorted(DOSFIELDS, key=len, reverse=True)),
                             re.I) if DOSFIELDS else None

    global CANON, CANON_RE
    CANON = {}
    dossym_spellings(CANON)
    for text in texts.values():
        spellings(text, CANON)
    # Only the names that are written more than one way need rewriting, and
    # leaving the rest alone keeps the diff to what actually changed.
    CANON_RE = re.compile(r"(?<![.\w])(%s)\b"
                          % "|".join(sorted(CANON, key=len, reverse=True)),
                          re.I) if CANON else None
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
    main(sys.argv[1].upper() if len(sys.argv) > 1 else "")
