#!/usr/bin/env python3
"""Convert COMMAND.COM's sources from MASM to FASM, in place.

Each of the sixteen modules COMLINK names keeps its own file, as the kernel's
do.  What changes inside them is the syntax, and what changes around them is
how the segments are selected.

COMLINK reads

    command rucode rdata init uinit tcode tcode2 tcode3 +
    tcode4 tcode5 tucode copy copyproc cparse tdata tspc;

and the linker walked those sixteen once per segment, gathering each
segment's pieces together, then laid the segments out in group order.  A
module contributes to several: TCODE4 alone puts code in TRANCODE, data in
TRANDATA and in DATARES, and space in TRANSPACE.  So the order the linker
emitted is nothing like module order, and an assembler with one address space
has to do the same walk.

Rather than flatten the modules into one file per segment, which would lose
the one-to-one with the originals, each segment's body is wrapped in

    if SEGSEL = S_TRANCODE
        ...
    end if

and COMLINK.ASM includes all sixteen modules once per segment with SEGSEL set
to say which.  That is the linker's walk, written out.

Two choices worth knowing about.

The IBM switch is off and MSVER on.  Every reference COMMAND makes to the
EGROUP segments -- ZEXEC_CODE, ZEXEC_DATA, ZEXECCODEEND, OFFSET
ZEXEC_CODE:$EXEC -- sits under IF IBM or IF IBMVER, and COMMAND.ASM ends with
"IF IBMVER / INCLUDE EXEC.ASM".  The IBM build therefore carries EXEC inside
COMMAND.COM as a third group, which is why PROC.ASM in the kernel stubs $EXEC
out.  This DOS has EXEC in the kernel, the near build out of EXEC.ASM, which
is what the Microsoft link does -- so MSVER is the half that matches, and
COMMAND asks for EXEC through INT 21h like any other program.

MATCH, OUT, STACK, PAUSE and SYSCALL are labels here and words FASM has its
own use for, so they come out with an underscore after them.  That list was
not guessed: every label was handed to FASM on a line of its own and the ones
it refused were collected, so it is the whole of the overlap for these
sources.

Two things these sources do not need help with.  They bracket every memory
reference and write OFFSET for every address, so none of MASM's implicit
"contents of" has to be guessed at: a scan for a bare data label used as a
value finds none in 8,500 lines.  And no EQU hides inside an IF, where FASM's
preprocessor would take both arms.

This runs once, on the MASM originals; afterwards they are the converted
files and git holds what they were.  It refuses a file that already looks
converted rather than convert it twice.
"""
import os, re, sys

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "source")

MODULES = """COMMAND RUCODE RDATA INIT UINIT TCODE TCODE2 TCODE3 TCODE4
             TCODE5 TUCODE COPY COPYPROC CPARSE TDATA TSPC""".split()

SEGMENTS = ["CODERES", "DATARES", "ENVIRONMENT", "INIT", "TAIL",
            "TRANCODE", "TRANDATA", "TRANSPACE", "TRANTAIL"]
SKIP     = {"ZEXEC_CODE", "ZEXEC_DATA"}          # IBM only; see above

# A name before a colon says what an offset is counted from, and the two
# kinds are not the same.  OFFSET RESGROUP:x is counted from the group, which
# is what every address here already is, so the qualifier simply comes off.
# OFFSET ENVIRONMENT:x is counted from that one segment -- INIT.ASM keeps
# ECOMLOC as OFFSET ENVIRONMENT:ECOMSPEC-10H, an offset into the environment
# block and nothing to do with the group -- so the segment's own start has to
# come off the value.  COMLINK.ASM marks each segment's start as SEGBASE_name
# for that.
GROUP_QUALIFIERS = ("RESGROUP", "TRANGROUP", "EGROUP",
                    "ZEXEC_CODE", "ZEXEC_DATA")
SEG_QUALIFIERS   = ("CODERES", "DATARES", "ENVIRONMENT", "INIT", "TAIL",
                    "TRANCODE", "TRANDATA", "TRANSPACE", "TRANTAIL")

RESERVED = ("MATCH", "OUT", "STACK", "PAUSE", "SYSCALL")

# Three constants are written twice: one module measures them with $, another
# states the figure, with a comment that the two must agree.  They had to,
# with the modules assembled apart.  Together they cannot both stand -- EQU is
# a preprocessor symbol in FASM, so the stated one would be substituted into
# the left hand side of the measured one -- and the measured one is the one
# that is right by construction.  So the stated ones go, and COMLINK.ASM
# checks the agreement their comments asked for.
#    module that states it, name, the figure it stated
STATED = (("INIT",   "ENVIRONSIZ",  "0A0h"),
          ("INIT",   "ENVIRONSIZ2", "092h"),
          ("CPARSE", "SWCOUNT",     "5"))

# Every module included DOSSYM, DEVSYM, COMSEG, COMSW, COMEQU and IFEQU for
# itself, because MASM assembled each of them on its own.  COMLINK.ASM does
# that once now, so the module-level includes go -- along with COMSEG.ASM and
# IFEQU.ASM, which nothing needs any more: COMSEG.ASM is the empty segment
# declarations and the GROUPs, and IFEQU.ASM is %OUT lines for the listing.
# MASM did not care about the case of a name; FASM does.  These sources were
# written against a DOSSYM that spelled the system call numbers in capitals,
# and DOSSYM_v211.ASM spells them in mixed case -- Close, Open, LSeek, Wait --
# so 224 references in 59 spellings would go unresolved.  The headers are read
# for the spelling they define and the modules are brought into line with it.
HEADERS = ("DOSSYM_v211.ASM", "DEVSYM.ASM", "COMEQU.ASM", "COMSW.ASM",
           "DOSMAC_v211.ASM")

DROP = re.compile(r"""^\s*(
      \w+\s+GROUP\b | EXTRN\b | PUBLIC\b | ORG\b
    | INCLUDE\b
    | END\b\s*\w*\s*$
    | TITLE\b | SUBTTL\b | PAGE\b | NAME\b | \.XLIST\b | \.LIST\b
    | \.CREF\b | \.XCREF\b | \.RADIX\b | %OUT\b | \.SALL\b
    )""", re.I | re.X)


def spelling():
    """What the headers call each name, by its name in capitals."""
    canon = {}
    for h in HEADERS:
        for line in open(os.path.join(SRC, h), errors="replace"):
            code = line.split(";")[0]
            for pat in (r"^\s*([A-Za-z_@][\w@.]*)\s+EQU\b",
                        r"^\s*([A-Za-z_@][\w@.]*)\s*=[^=]",
                        r"^\s*STRUC\s+([A-Za-z_@][\w@]*)",
                        r"^\s*macro\s+([A-Za-z_@][\w@]*)",
                        r"^\s*([A-Za-z_@][\w@]*)\s+(?:DB|DW|DD)\b"):
                m = re.match(pat, code, re.I)
                if m:
                    canon.setdefault(m.group(1).upper(), m.group(1))
                    break
    return canon


def defined_here():
    """How each name the modules define is spelled where it is defined.

    These sources write a label whichever way suits -- TCODE.ASM jumps to
    AskForBat and defines ASKFORBAT -- because MASM did not care.  FASM does,
    so every reference is brought to the spelling of the definition.
    """
    own, where = {}, {}
    for mod in MODULES:
        for n, line in enumerate(open(os.path.join(SRC, mod + ".ASM"),
                                      errors="replace"), 1):
            code = line.split(";")[0]
            m = (re.match(r"^([A-Za-z_@$][\w@$]*):", code)
                 or re.match(r"^([A-Za-z_@$][\w@$]*)\s+(?:DB|DW|DD|LABEL|EQU|STRUC)\b",
                             code, re.I))
            if not m:
                continue
            name = m.group(1)
            key = name.upper()
            if key in own and own[key] != name:
                print("  note: %s is defined as %s in %s and as %s in %s:%d; "
                      "taking the first" % (key, own[key], where[key], name, mod, n))
                continue
            own.setdefault(key, name)
            where.setdefault(key, "%s:%d" % (mod, n))
    return own


def data_sizes():
    """How wide each piece of the modules' data is, by its name in capitals.

    MASM took the width of an indirect CALL or JMP from the thing named --
    CALL [HEADCALL] is far because HEADCALL is a DWORD -- and FASM wants it
    said.  A bracketed expression that names nothing, like CALL [BX+1], is a
    near call, which is what MASM assumed too.
    """
    size = {}
    for mod in MODULES:
        for line in open(os.path.join(SRC, mod + ".ASM"), errors="replace"):
            code = line.split(";")[0]
            m = re.match(r"^([A-Za-z_@$][\w@$]*)\s+(DB|DW|DD)\b", code, re.I)
            if m:
                size.setdefault(m.group(1).upper(),
                                {"DB": "byte", "DW": "word", "DD": "dword"}[m.group(2).upper()])
                continue
            m = re.match(r"^([A-Za-z_@$][\w@$]*)\s+LABEL\s+(BYTE|WORD|DWORD)\b", code, re.I)
            if m:
                size.setdefault(m.group(1).upper(), m.group(2).lower())
    return size


def struc_instances():
    """The name each STRUC's field offsets actually hang off.

    FASM gives a STRUC's fields to its instances, so the headers lay one down
    in a "virtual at 0" to have the offsets.  Nearly all are named after the
    STRUC, but internat_block's is internat_block_sizeof, and it is that name
    the offsets answer to.
    """
    inst = {}
    for h in HEADERS:
        inside = False
        for line in open(os.path.join(SRC, h), errors="replace"):
            code = line.split(";")[0]
            if re.match(r"^\s*virtual\s+at\b", code, re.I):
                inside = True
                continue
            if re.match(r"^\s*end\s+virtual\b", code, re.I):
                inside = False
                continue
            if inside:
                m = re.match(r"^\s*([A-Za-z_@][\w@]*)\s+([A-Za-z_@][\w@]*)", code)
                if m and not re.match(r"^(sizeof|DB|DW|DD|EQU)$", m.group(1), re.I):
                    inst[m.group(2).upper()] = m.group(1)
    return inst


def struc_fields(inst):
    """Which name each field hangs off, by the field's name in capitals.

    MASM let a field name stand on its own for its offset, and let [BP.ISDIR]
    mean [BP + that offset].  FASM wants it qualified.
    """
    out = {}
    for h in HEADERS:
        cur = None
        for line in open(os.path.join(SRC, h), errors="replace"):
            code = line.split(";")[0]
            m = re.match(r"^\s*STRUC\s+([A-Za-z_@][\w@]*)", code, re.I)
            if m:
                cur = m.group(1)
                continue
            if cur and re.match(r"^\s*\}", code):
                cur = None
                continue
            if cur:
                m = re.match(r"^\s*\.([A-Za-z_@][\w@]*)", code)
                if m:
                    key = m.group(1).upper()
                    if key in out and out[key][0] != inst.get(cur.upper(), cur):
                        sys.exit("field %s is in both %s and %s; qualifying it "
                                 "would be a guess" % (m.group(1), out[key][0], cur))
                    out[key] = (inst.get(cur.upper(), cur), m.group(1))
    return out


def struc_params():
    """How many arguments each STRUC the headers declare takes."""
    counts = {}
    for h in HEADERS:
        for line in open(os.path.join(SRC, h), errors="replace"):
            m = re.match(r"^\s*STRUC\s+([A-Za-z_@][\w@]*)\s+(.+?)\s*$",
                         line.split(";")[0], re.I)
            if m:
                counts[m.group(1).upper()] = len(m.group(2).split(","))
    return counts


STRINGS = re.compile(r"'[^']*'|\"[^\"]*\"")


def respell(code, canon, own, fields):
    """Header names in the case they are defined, and fields with their STRUC,
    leaving string literals alone."""
    out, pos = [], 0
    for s in STRINGS.finditer(code):
        out.append(fix_words(code[pos:s.start()], canon, own, fields))
        out.append(s.group(0))
        pos = s.end()
    out.append(fix_words(code[pos:], canon, own, fields))
    return "".join(out)


def fix_words(text, canon, own, fields):
    # [BP.ISDIR] first, so the field it leaves behind is preceded by a dot
    # and the pass below leaves it alone.
    def bracket(m):
        base, field = m.group(1), m.group(2)
        hit = fields.get(field.upper())
        if hit is None or field.upper() in own:
            return m.group(0)
        return "[%s+%s.%s]" % (base, hit[0], hit[1])
    text = re.sub(r"\[([^\]]*?)\.([A-Za-z_@][\w@]*)\]", bracket, text)

    def one(m):
        tok = m.group(0)
        u = tok.upper()
        if u in own:
            return own[u]
        if u in fields:
            return "%s.%s" % fields[u]
        if u in canon:
            return canon[u]
        return tok
    return re.sub(r"(?<![.\w@$])[A-Za-z_@][\w@]*(?![\w@])", one, text)


def convert(line, state):
    """One line of MASM into one line of FASM, or None to drop it."""
    code, sep, comment = line.partition(";")

    if DROP.match(code):
        return None

    for mod, name, _figure in STATED:
        if state["module"] == mod and \
           re.match(r"^\s*%s\s+EQU\b" % name, code, re.I):
            return "; " + line.strip() + \
                   "   [dropped: measured where it is defined with $]"

    # A FAR procedure's RET is a far return, which MASM took from the PROC
    # and FASM cannot.
    m = re.match(r"^\s*([A-Za-z_@$][\w@$]*)\s+PROC\s+(NEAR|FAR)", code, re.I)
    if m:
        state["far"] = m.group(2).upper() == "FAR"
        return "        procedure   %s,%s" % (m.group(1), m.group(2).upper())
    # ENDP is dropped here rather than by DROP, because it has to clear the
    # flag on the way out.  Dropping it earlier left the flag set, and the
    # next plain RET in the file -- RET41 in INIT.ASM, which is nobody's FAR
    # procedure -- came out as RETF and unbalanced the stack.
    if re.match(r"^\s*[A-Za-z_@$][\w@$]*\s+ENDP", code, re.I):
        state["far"] = False
        return None
    if state["far"] and re.match(r"^\s*RET\s*$", code, re.I):
        code = re.sub(r"\bRET\b", "RETF", code, flags=re.I)

    # A structure laid down with MASM's <> for "all the defaults", of which
    # there is one: INTERNATVARS internat_block <>.  FASM wants a value per
    # field, so the field count comes from the STRUC and each gets a ?.
    m = re.match(r"^(\s*[A-Za-z_@$][\w@$]*)\s+([A-Za-z_]\w*)\s+<\s*(.*?)\s*>\s*$", code)
    if m:
        args = m.group(3)
        if not args:
            n = state["params"].get(m.group(2).upper())
            if n is None:
                sys.exit("%s: cannot tell how many fields %s has"
                         % (state["module"], m.group(2)))
            args = ",".join("?" * n) if n == 1 else ",".join(["?"] * n)
        code = "%s %s %s" % (m.group(1), m.group(2), args)

    m = re.match(r"^\s*([A-Za-z_@$][\w@$]*)\s+LABEL\s+(\w+)(.*)$", code, re.I)
    if m:
        code = "label %s %s%s" % (m.group(1), m.group(2).lower(), m.group(3))

    # OFFSET <segment>:name, counted from that segment's own start.
    def from_segment(m):
        return "(%s - SEGBASE_%s)" % (m.group(2), m.group(1).upper())
    code = re.sub(r"\bOFFSET\s+(%s)\s*:\s*([A-Za-z_@$][\w@$]*)" % "|".join(SEG_QUALIFIERS),
                  from_segment, code, flags=re.I)

    code = re.sub(r"\bOFFSET\s+(?:%s)\s*:\s*" % "|".join(GROUP_QUALIFIERS), "",
                  code, flags=re.I)
    code = re.sub(r"\bOFFSET\s+", "", code, flags=re.I)
    code = re.sub(r"\b(?:%s)\s*:\s*(?=[A-Za-z_@$])"
                  % "|".join(GROUP_QUALIFIERS + SEG_QUALIFIERS), "", code)

    # MASM puts the segment override before the brackets, FASM inside them.
    # The only other CS:/DS:/ES:/SS: in these sources are on ASSUME lines,
    # which have no brackets, and in comments, which are left alone.
    code = re.sub(r"\b(CS|DS|ES|SS)\s*:\s*\[([^\]]*)\]", r"[\1:\2]", code, flags=re.I)

    code = re.sub(r"\bWORD\s+PTR\b",  "word",  code, flags=re.I)
    code = re.sub(r"\bBYTE\s+PTR\b",  "byte",  code, flags=re.I)
    code = re.sub(r"\bDWORD\s+PTR\b", "dword", code, flags=re.I)

    # An indirect CALL or JMP needs its width said; see data_sizes().
    m = re.match(r"^(\s*)(CALL|JMP)(\s+)\[([^\]]*)\](\s*)$", code, re.I)
    if m:
        inner = m.group(4).strip()
        width = state["size"].get(inner.upper(), "word")
        code = "%s%s%s%s [%s]" % (m.group(1), m.group(2), m.group(3), width, m.group(4))

    code = re.sub(r"^(\s*)IFE\s+(.*)$",      r"\1IF \2 = 0", code, flags=re.I)
    code = re.sub(r"^(\s*)IF\s+NOT\s+(\w+)", r"\1IF \2 = 0", code, flags=re.I)
    code = re.sub(r"^(\s*)ENDIF\b",          r"\1END IF",    code, flags=re.I)

    code = re.sub(r"\$([A-Za-z_][\w]*)", r"_\1", code)

    # EQU is textual in FASM, so a value holding $ would be measured at each
    # use instead of here.
    m = re.match(r"^(\s*[A-Za-z_@][\w@]*)\s+EQU\s+(.*\$.*)$", code, re.I)
    if m:
        code = "%s = %s" % (m.group(1), m.group(2))

    for name in RESERVED:
        code = re.sub(r"\b%s\b" % name, name + "_", code)

    code = respell(code, state["canon"], state["own"], state["fields"])

    return code + sep + comment if sep else code


def main():
    canon, own = spelling(), defined_here()
    params, size = struc_params(), data_sizes()
    fields = struc_fields(struc_instances())
    for mod in MODULES:
        path = os.path.join(SRC, mod + ".ASM")
        text = open(path, errors="replace").read()
        if "SEGSEL" in text:
            sys.exit("%s.ASM is converted already; git has what it was." % mod)

        out, pos = [], 0
        state = {"module": mod, "far": False, "in_segment": False,
                 "canon": canon, "own": own, "params": params,
                 "fields": fields, "size": size}

        def emit(chunk, in_segment):
            state["in_segment"] = in_segment
            for line in chunk.splitlines():
                got = convert(line.rstrip("\r"), state)
                if got is not None:
                    out.append(got)

        for m in re.finditer(r"^(\w+)\s+SEGMENT\b[^\n]*\n(.*?)^\1\s+ENDS[^\n]*\n",
                             text, re.S | re.M | re.I):
            emit(text[pos:m.start()], False)
            pos = m.end()
            name, body = m.group(1).upper(), m.group(2)
            if name in SKIP or not body.strip():
                continue                        # IBM's, or an empty declaration
            if name not in SEGMENTS:
                sys.exit("%s puts something in %s, which has no home" % (mod, name))
            out.append("")
            out.append("if SEGSEL = S_%s" % name)
            state["far"] = False
            emit(body, True)
            out.append("end if")
        emit(text[pos:], False)

        with open(path, "w", newline="\r\n") as f:
            f.write("\n".join(out) + "\n")
        print("%-12s %5d lines" % (mod + ".ASM", len(out)))


if __name__ == "__main__":
    main()
