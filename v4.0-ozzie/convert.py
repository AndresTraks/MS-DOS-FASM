#!/usr/bin/env python3
"""Convert the Multitasking DOS BIOS from MASM to FASM.

    python3 convert.py IBMBIO

The sources are the ones Microsoft shipped on the beta's second disk, in
bin/DISK2/BIOS, and they are copied into src/ and converted there: the disk
stays as it was handed out.  So re-deriving a module is a copy and a run,
and there is no in-place history to pick apart.

This is v2.0/convert_utility.py with a table of its own.  The sources are of
the same age -- 1984, the same MASM, the same habits -- and want the same
passes, which are described in that file:

  * PUBLIC, EXTRN, SEGMENT, ENDS, GROUP and the final END go, the link file
    being what lays the segments down.
  * WORD PTR and BYTE PTR become word and byte, OFFSET goes, NAME LABEL SIZE
    becomes label NAME size, and ENDIF becomes end if.
  * EQU becomes =, DW ? and DB n DUP (?) become zeros, a bare variable name
    gets the brackets MASM did not need, a variable indexed by a register
    becomes [NAME+REG], and a STRUC's fields hang off their structure.
  * A SEGMENT AT becomes a virtual block: two of the three modules reach
    into the ROM's data at 40H that way, and one of them into the display
    buffers at B000H and B800H.

What this tree asks for on top of that:

  * The segment override MASM wrote for itself out of the ASSUME.  The whole
    of this BIOS runs with DS on nothing, so every reference it makes to its
    own data carries a CS -- and a conversion that drops one assembles, runs,
    and reads the caller's segment.  See overrides() and spaces().
  * The debugging macros in DEFDBUG.INC lay nothing down, DEBUGFLG being
    undefined, and there are 59 calls of DEBUG between the three modules
    whose arguments are format strings full of $ and \n and lists of lists.
    A macro that does nothing still has to be able to read its arguments, so
    the calls are commented out instead, which is what MASM made of them.
    DBBEG is worse: its body opens an IFDEF that the macro never closes, so
    the call behaves as IFDEF DEBUGFLG does and the caller's own ELSE or
    ENDIF is what closes it.  FASM has no way to say that, so the table
    names the macro and silenced() reads the region as the false conditional
    it is.
  * The assertions, which MASM wrote as a conditional whose false branch is
    .RADIX 0 -- an error on purpose.  FASM says that with err.
  * A segment written inside another, which MASM allowed and IBMDSK does
    with BiosInit: the outer one is suspended and resumed rather than ended.
    IBMMTCON goes one worse and moves from Code to BiosInit inside an IF,
    where the two conditionals would interleave; segment_guards() settles
    that one from the switches the module sets itself.
  * A macro whose body reaches the module's own data, which MASM expanded at
    the call site and under the ASSUME in force there.  The register is
    handed in as an argument, because the decision was the caller's.
  * The segment MASM wrote on a far pointer, which is the group's base: a DD
    of a label, or a CALL or JMP of one declared LABEL FAR.  See
    farpointer(); the link file says what the base came to.

There is no DOSSYM here: each module declares the equates it needs itself.

It refuses a file it has already converted.
"""
import os
import re
import sys

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "src")
# One entry per module, because MASM assembled each of them on its own --
# BIOSOBJ.MAK says "masm ibmbio;" and so on -- and each shipped with the
# object that came out.  So each is converted and held against its own object
# by itself, with the externals between them standing in as placeholders in
# its link file.  src/BIOSLNK.ASM then reads all three together to build the
# bootable IBMBIO.COM, where nothing is external any more -- which is what
# the renames below are for: two modules private to themselves could both
# call a routine Strategy, and in one name space they cannot.
#
# Per module: the files the link file reads, the segments to wrap, the group
# they are in, the names FASM will not take as labels, and the macro calls
# that lay nothing down and are commented out instead.
PROGRAMS = {
    "IBMBIO": {
        # The BIOS proper: the device headers, the character devices, the
        # interrupt entry and the initialisation.  Its object declares CODE
        # at 1009 bytes, ROMDATA at 65 and BIOSINIT at 1502.
        "dossym": "",
        # BUGCODE.INC is included by the module itself rather than by the
        # link file, and is converted with it.  All of it is inside IFDEF
        # DEBUGFLG, so none of it is assembled.
        "modules": ("IBMBIO.ASM", "BUGCODE.INC"),
        # Code and BiosInit are the group BiosSeg, in that order.  RomData is
        # a SEGMENT AT and lays nothing down, so it is not walked.
        "segments": ("CODE", "BIOSINIT"),
        "group": "BiosSeg",
        "reserved": (),
        # EXTRN FloppyTimer:FAR, which IBMDSK defines and this module calls.
        # MASM told the two apart by which file it was reading; FASM has one
        # name space for the link that reads both, and there the name belongs
        # to IBMDSK's label.  So the call site gets the spelling the EXTRN
        # has, and the link file says which segment and offset it comes to.
        "renames": {"IBMBIO.ASM": {"FloppyTimer": "FloppyTimer$FAR"}},
        "macros": {},
        # DEBUG lays nothing down with DEBUGFLG undefined.
        "silent": ("DEBUG",),
        "regions": (),
    },
    "IBMMTCON": {
        # The console driver: the screen, the keyboard, eight virtual
        # screens and an ANSI interpreter.  Its object declares ROMDATA at
        # 103 bytes, MONOSC and COLORSC at nothing, CODE at 2959 and
        # BIOSINIT at 47.  All four of its switches are on -- BLANK, INBIOS,
        # ANSI with LINE25, and EAGLE, which works around a ROM that botches
        # CRT_LEN -- so there is no dead code to speak of.
        "dossym": "",
        # ANSI.INC is included by the module, in the middle of its Code
        # segment, and converted with it.
        "modules": ("IBMMTCON.ASM", "ANSI.INC"),
        "segments": ("CODE", "BIOSINIT"),
        "group": "BiosSeg",
        # Entry is the far entry point of the driver and Break the handler
        # for a control break; both are FASM's own words -- entry names an
        # MZ file's entry point and break leaves a while block.
        "reserved": ("Entry", "Break"),
        # EXTRN AUXDEV:FAR, which IBMBIO defines as a device header and this
        # module's own header points at.  As with IBMBIO's FloppyTimer, the
        # link that reads both modules has one name space and the name
        # belongs to IBMBIO's label, so the reference gets the spelling the
        # EXTRN has and the link file says what it comes to.  IBMDSK's
        # Com1Dev needs no such thing: MASM was blind to the case of a name
        # and IBMBIO spells that one COM1DEV, so FASM sees two names already.
        #
        # Strategy is this module's own, and IBMBIO has one of that name too
        # -- the console driver here is the one IBMBIO leaves out when
        # CONSFLAG is off, so the two were written to look alike.  Each is
        # private to its own module and MASM never had to tell them apart;
        # the link that reads both does, so this one is marked for the module
        # it belongs to.
        "renames": {"IBMMTCON.ASM": {"AUXDEV": "AUXDEV$FAR",
                                     "Strategy": "Strategy$CON"}},
        "macros": {},
        "silent": ("DEBUG",),
        "regions": (),
        # ANSI.INC is read in the middle of the Code segment, under the
        # ASSUME in force there.
        "assume": {"ANSI.INC": "CS:BiosSeg,DS:NOTHING,ES:NOTHING"},
    },
    "IBMDSK": {
        # The disk drivers, floppy and fixed: two device headers, two
        # dispatch tables and a state machine apiece, and the Int 13 handler
        # the rest of the system makes its requests through.  Its object
        # declares CODE at 3925 bytes and BIOSINIT at 361.
        "dossym": "",
        # One module, DEFDBUG.INC apart, which the link file brings in.
        "modules": ("IBMDSK.ASM",),
        # Code and BiosInit again, except that this module writes BiosInit
        # inside Code rather than after it.  The object says so plainly: its
        # CODE chunks run to 0x334 and start again at 0x334 with the whole of
        # BIOSINIT laid down in between.
        "segments": ("CODE", "BIOSINIT"),
        "group": "BiosSeg",
        "reserved": (),
        # Eleven labels in Disk_Init, every one of them IBMBIO's as well:
        # this module's initialisation sets the drive tables up and IBMBIO's
        # does the same work for the boot, down to the names the two walk
        # their way through.  Private to a module apiece, and MASM assembled
        # the two apart; the link that reads both wants them told apart, so
        # these carry the module they belong to.
        "renames": {"IBMDSK.ASM": {"NOTSNGL": "NOTSNGL$DSK",
                                   "ENDDRV": "ENDDRV$DSK",
                                   "NOTOK": "NOTOK$DSK",
                                   "SETIT": "SETIT$DSK",
                                   "ITSOK": "ITSOK$DSK",
                                   "GETBOOT": "GETBOOT$DSK",
                                   "SETHRD": "SETHRD$DSK",
                                   "SET1": "SET1$DSK",
                                   "SETRET": "SETRET$DSK",
                                   "SET2": "SET2$DSK",
                                   "SET3": "SET3$DSK"}},
        "macros": {},
        "silent": ("DEBUG",),
        # This is the module that calls DBBEG, and it calls it three times.
        "regions": ("DBBEG",),
        # Its two semaphore macros reach the module's own data, and are
        # called from both kinds of place.
        "segmacros": {"SemWait": {"wchan": "byte"},
                      "SemSig": {"wchan": "byte"}},
    },
}
STRINGS = re.compile(r"'[^']*'|\"[^\"]*\"")
# A name as MASM spelt one.  Python's \w is not enough: $, ? and @ are name
# characters here, and IBMBIO declares its first data sector as BIOS$ DW 0.
# Read as \w+ the declaration went unseen, so the name was in no address
# space, and the one reference to it was the one reference in the whole
# module that did not get the override MASM wrote.
N = r"[A-Za-z_@?$][A-Za-z0-9_@?$]*"

DROP = re.compile(r"""^\s*(
      \.(xlist|list|radix|xcref|cref
         |sall|lall|xall|sfcond|lfcond|tfcond)\b
    | NAME\s+\w+\s*$                    # MASM's module name, which went in
                                       # the object's THEADR.  IBMDSK is the
                                       # one module here that writes one, and
                                       # the link file is what names this
                                       # build
    | (PAGE|SUBTTL|TITLE)\b(?!:)         # not a label of that name: EDLIN
                                       # has one called PAGE, and dropping
                                       # its definition left every reference
                                       # to it undefined
    | ORG\s+0\s*$                       # the data segment restating where it
                                       # starts, as PRINT's does.  Segment
                                       # offsets are the segment's own in
                                       # MASM; flattened into one address
                                       # space an ORG 0 would wind the
                                       # counter back over the code
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
SILENT = ()
REGIONS = ()
SEGMACROS = {}
# The ASSUME a module that has none of its own is read under.
ASSUMED = {}
EXTERNAL = {}
# Which address space each name the module declares lives in, and which group
# each segment belongs to.
SPACE = {}
GROUPOF = {}
# The names declared LABEL FAR, which a CALL or JMP of reaches with a far
# instruction even from inside the same segment.
FARLABEL = set()
# Every segment and group name the module declares.
SEGNAMES = set()
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
# What each structure field was declared as.
FIELDSIZE = {}
# And the fields that are reached through a second name, with the size of the
# field behind it.  FASM takes the size of a memory operand from a label in
# it, and the block that measures a structure gives every field a label of
# its own, so [Floppy+DeviceStruc.State] says how wide it is by itself.  An
# EQU of a field is a plain number and says nothing, so [Fixed+DCB] has to be
# told.
UNSIZED = {}
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


def page_breaks(text):
    """The form feeds, which MASM read as whitespace and a listing read as a
    new page.

    IBMBIO.ASM has nine of them, each at the front of a line, and two of
    those lines are a COMMENT: read as part of the line they hid the
    directive from every pass here, and the block of prose after it went
    through as code.  The listing directives are dropped with everything
    else that spoke only to the listing, so these go with them."""
    return re.sub(r"(?m)^\f+", "", text)


def commented(text):
    """MASM's COMMENT, which runs from its delimiter to the next one.

    FASM has no block comment, so every line of the block gets a semicolon
    of its own.  IBMBIO writes five of them, each a page of entry and exit
    conditions between a pair of asterisks."""
    lines = text.split("\n")
    out, i = [], 0
    while i < len(lines):
        m = re.match(r"(?i)^[ \t]*COMMENT[ \t]+(\S)(.*)$", lines[i])
        if not m:
            out.append(lines[i])
            i += 1
            continue
        delim, rest = m.group(1), m.group(2)
        out.append(";" + lines[i])
        i += 1
        if delim in rest:               # it opens and closes on one line
            continue
        while i < len(lines):
            out.append(";" + lines[i])
            closed = delim in lines[i]
            i += 1
            if closed:
                break
    return "\n".join(out)


# The directives a conditional opens and closes with, which the region a
# macro opened has to be counted out against: one of these inside it is not
# the one that closes it.
OPENSIF = re.compile(r"(?i)^[ \t]*IF(DEF|NDEF|E|B|NB|IDN|DIF|1|2)?\b")
CLOSESIF = re.compile(r"(?i)^[ \t]*ENDIF\b")
# The CR of a CRLF file counts as neither space nor tab, and these sources
# are not all one or the other.
ELSESIF = re.compile(r"(?i)^[ \t]*ELSE[ \t\r]*$")


def silenced(text):
    """The debugging macro calls, which lay nothing down, and the regions a
    macro opened a conditional over.

    DEBUG is called 59 times between the three modules and expands to
    nothing, DEBUGFLG being undefined; its arguments are format strings full
    of $ and backslashes and lists of lists, which a macro that did nothing
    would still have to be able to read.  So the calls are commented out.

    DBBEG is worse.  Its body opens an IFDEF and never closes it, so the
    call behaves exactly as IFDEF DEBUGFLG does: everything after it goes
    until the caller's own ELSE or ENDIF closes it.  IBMDSK calls it three
    times, and the three are not alike -- two are closed by an ENDIF and the
    whole region disappears, and one by an ELSE whose branch MASM did
    assemble, so FloppyInit's last instruction is in it.  A region is
    therefore read as the false conditional it is: the lines up to the ELSE
    or ENDIF that closes it are commented out, what an ELSE leaves is kept,
    and the ENDIF that would have closed a conditional FASM never opened is
    commented out with it."""
    out, state, depth = [], None, 0
    for line in text.split("\n"):
        code = line.split(";")[0]
        if state is not None:
            if OPENSIF.match(code):
                depth += 1
            elif CLOSESIF.match(code):
                if depth:
                    depth -= 1
                else:
                    out.append(";" + line)      # the one the macro opened
                    state = None
                    continue
            elif ELSESIF.match(code) and not depth and state == "skip":
                out.append(";" + line)
                state = "keep"
                continue
            out.append((";" if state == "skip" else "") + line)
            continue
        m = re.match(r"(?i)^[ \t]*(" + N + r":[ \t]*)?(\w+)\b", code)
        name = m.group(2).upper() if m else None
        opens = name in {s.upper() for s in REGIONS}
        if name in {s.upper() for s in SILENT} or opens:
            # The call may be carrying a label, and the label is not part of
            # what the macro lays down: IBMBIO writes
            # "GETFAT: debug 1,2,<GETFAT.>,<>" and the CALL GETFAT a page
            # above it has to still have something to reach.  IBMDSK does
            # the same with a DBBEG, "fxxe2: dbbeg 8,4", and there the label
            # is the target of a JMP SHORT a dozen lines above.  So the label
            # stays and the call after it becomes the comment.
            if m.group(1):
                out.append("%s;%s" % (m.group(1).rstrip(),
                                      line[m.start(2):]))
            else:
                out.append(";" + line)
            if opens:
                state, depth = "skip", 0
            continue
        out.append(line)
    if state is not None:
        sys.exit("a region a macro opened was never closed")
    return "\n".join(out)


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


def dollars(text):
    """A name that begins with a dollar, which FASM keeps for itself.

    $ alone is the address the assembler has reached, so a name cannot start
    with one; MASM allowed it and the console driver's entry points are all
    named that way -- $ConRead, $ConWrit, $GenIOCTL and a dozen more.  The
    dollar moves to the end, which is what v4.0's conversion did with the
    kernel's $GET_DATE.

    Only where the dollar starts the name: TIM$READ and CON$WRIT have one in
    the middle, which FASM is content with, and rewriting those would have
    made two names of one.  Strings are left alone, and so are comments,
    which is where the debugging format strings' own $b and $x live."""
    out = []
    for line in text.split("\n"):
        body, sep, comment = line.partition(";")
        out.append(outside_strings(
            body, lambda s: re.sub(r"(?<![\w@?$])\$([A-Za-z_@?][\w@?$]*)",
                                   r"\1$", s)) + sep + comment)
    return "\n".join(out)


def numbers(text):
    """The names the module defines as a plain number, which is as much
    arithmetic as anything here needs to do."""
    found = {}
    for raw in text.splitlines():
        m = re.match(r"(?i)^(" + N + r")\s+(?:EQU|=)\s+"
                     r"(\d+|[0-9][0-9A-Fa-f]*[hH])\s*(;.*)?$",
                     raw.split(";")[0] + (";" if ";" in raw else ""))
        if m:
            value = m.group(2)
            found[m.group(1).upper()] = (int(value[:-1], 16)
                                         if value[-1] in "hH"
                                         else int(value))
    return found


def struct_arrays(text):
    """An array of structures, which MASM wrote as a count and a DUP.

    IBMMTCON keeps its eight screen information blocks as
    SIB SIBst MaxSIB dup (<>), each of them carrying the defaults the
    structure declares -- a zero, a seven, the number of segments and the
    structure's own size.  FASM declares one instance at a time and hangs
    the field names on each, so the count is counted out here and each
    instance given a name made of the array's and its number.  Nothing
    refers to those names: the code reaches a block through a register and
    the structure's own field offsets, which is why MASM's instance needed
    no name either."""
    known = numbers(text)

    def one(m):
        name, struct, count = m.group(2), m.group(3), m.group(4)
        if struct.upper() not in STRUCS:
            return m.group(0)
        n = known.get(count.upper())
        if n is None and re.fullmatch(r"\d+", count):
            n = int(count)
        if n is None:
            sys.exit("%s %s %s dup: no number for %s"
                     % (name, struct, count, count))
        out = ["%slabel %s" % (m.group(1), name)]
        out += ["%s%s$%d\t%s" % (m.group(1), name, k, STRUCS[struct.upper()])
                for k in range(n)]
        return "\n".join(out) + (m.group(5) or "")
    return re.sub(r"(?im)^([ \t]*)(" + N + r")[ \t]+(" + N + r")[ \t]+"
                  r"(" + N + r"|\d+)[ \t]+dup[ \t]*\([ \t]*<>[ \t]*\)"
                  r"[ \t]*(;.*)?$", one, text)


def field_aliases(text):
    """A second name for a structure field, which MASM wrote as an EQU of it
    after the ENDS.

    IBMDSK lays the fixed disk's Device Control Block over the four bytes of
    floppy controller status the structure ends with -- DCB EQU ST0 -- and
    then writes Fixed.DCB seven times.  The EQU is a number either way, the
    field's own offset, so it needs nothing doing to it; what it needs is to
    be known as a field, or Fixed.DCB stays a name with a dot in it that
    nothing defines."""
    for raw in text.splitlines():
        m = re.match(r"(?i)^\s*(" + N + r")\s+EQU\s+(" + N + r")\s*$",
                     raw.split(";")[0])
        if m and m.group(2).upper() in FIELDS:
            FIELDS.setdefault(m.group(1).upper(), m.group(1))
            UNSIZED.setdefault(m.group(1).upper(),
                               FIELDSIZE[m.group(2).upper()])


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
            FIELDSIZE[f.group(1).upper()] = {"DB": "byte", "DW": "word",
                                             "DD": "dword"}[f.group(2).upper()]
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
    # The block that measures the structure declares an instance of it, and
    # a program whose modules are read once per segment would declare that
    # instance once per segment.  So it goes in the pass over the first of
    # them, as the virtual block of a SEGMENT AT does, and the size it works
    # out holds for the rest.
    new = ["STRUC %s" % name, "{"] + ["        " + l for l in lines] + ["}", ""]
    if SEGMENTS:
        new.append("if SEGSEL = S_%s" % SEGMENTS[0])
    new += ["virtual at 0", "  %s %s" % (name, name),
            "  sizeof.%s = $ - %s" % (name, name), "end virtual"]
    if SEGMENTS:
        new.append("end if")
    return text[:m.start()] + "\n".join(new) + text[m.end():], False


# A label may sit in front of the instruction, as in "FDPB:   MOV DL,DRIVE",
# and need not leave a space after the colon: RECOVER writes "recfil0:mov
# lastfat,1", which went unrecognised and so unbracketed while the same
# variable was bracketed everywhere else.  The name is the whole of what MASM
# allows in one and not just \w: a label with a dollar in it -- TIM$READ, or
# one of the names the table renames -- went the same unrecognised way.
MNEMONIC = re.compile(r"^((?:" + N + r":\s*|\s+))([A-Za-z][\w]*)(\s+)(\S.*)$")
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
        for m in (re.match(r"^(" + N + r")\s+(?:DB|DW|DD)\b", code, re.I),
                  re.match(r"^(" + N + r")\s+EQU\b", code, re.I),
                  re.match(r"^(" + N + r")\s*=", code),
                  # MASM's NAME LABEL SIZE as well as the converted form:
                  # EDLIN declares START LABEL WORD and then asks for
                  # "offset dg:start" in lower case half a dozen lines later.
                  re.match(r"^(\w+)\s+LABEL\b", code, re.I),
                  # A procedure's name is a label as surely as a colon
                  # makes one, and these sources declare most of theirs
                  # that way: IBMBIO defines CmdErr PROC NEAR and its
                  # dispatch tables say DW CMDERR.  Missed, every such
                  # reference was an undefined symbol -- or, worse, would
                  # have been a second label of a different case.
                  re.match(r"^(\w+)\s+PROC\b", code, re.I),
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


def spaces(text):
    """Which address space each name is declared in.

    A name declared in Code or BiosInit is in the group BiosSeg, those two
    segments sharing one address space; a name declared in a SEGMENT AT is
    in that segment, which is somewhere else entirely -- RomData is the
    ROM's own data at 40H.  This is what MASM held an ASSUME against to
    decide whether a reference needed an override and which one."""
    # A stack, because a SEGMENT AT stands inside the segment it is written
    # in: IBMBIO opens RomData three times in the middle of Code and of
    # BiosInit.  Read with one name, the first RomData ENDS left the rest of
    # Code with no segment at all, and every name declared after it lost the
    # address space it is in -- and with it the override MASM wrote.
    # A file with no segments of its own is an include that sits inside one,
    # and its names are in that segment: ANSI.INC is read in the middle of
    # IBMMTCON's Code and declares two dozen variables of its own, and with
    # no segment to put them in not one of them got the CS: override MASM
    # wrote.  The program's first segment is the one it lands in here, which
    # is where every include in this tree is read.
    stack = []
    if not re.search(r"(?im)^\s*\w+\s+SEGMENT\b", text) and SEGMENTS:
        stack.append(SEGMENTS[0])
    for raw in text.splitlines():
        code = raw.split(";")[0]
        m = re.match(r"(?i)^\s*(\w+)\s+SEGMENT\b", code)
        if m:
            stack.append(m.group(1).upper())
            SEGNAMES.add(m.group(1).upper())
            continue
        m = re.match(r"(?i)^\s*(\w+)\s+ENDS\s*$", code)
        if m and stack and stack[-1] == m.group(1).upper():
            stack.pop()
            continue
        segment = stack[-1] if stack else None
        m = re.match(r"(?i)^\s*(\w+)\s+GROUP\s+(.*)$", code)
        if m:
            SEGNAMES.add(m.group(1).upper())
            for seg in m.group(2).split(","):
                GROUPOF[seg.strip().upper()] = m.group(1).upper()
            continue
        if segment is None:
            continue
        # An EXTRN declared inside a segment belongs to that segment, and
        # that is how MASM knew which register reached it: IBMMTCON declares
        # EXTRN DosFunction:DWORD inside its Code segment, so DosFunction is
        # in BiosSeg and every reference to it carries the CS: that reaches
        # the group.  IBMBIO declares its own five externals above its first
        # SEGMENT, so they are in no segment, and MASM read them through DS
        # with no override at all -- which is the difference between the two
        # modules, and nothing in the EXTRN itself says it.
        m = re.match(r"(?i)^\s*EXTRN\b(.*)$", code)
        if m:
            for name in re.findall(r"(" + N + r")\s*:", m.group(1)):
                SPACE.setdefault(name.upper(),
                                 GROUPOF.get(segment, segment))
            continue
        m = (re.match(r"(?i)^(" + N + r")\s+(?:DB|DW|DD|DQ|DT|LABEL)\b", code)
             or re.match(r"(?i)^(" + N + r"):", code))
        # A structure instance reserves storage as surely as a DB does.
        if not m:
            i = re.match(r"(?i)^(" + N + r")\s+(" + N + r")\s*<\s*>\s*$",
                         code.rstrip())
            m = i if i and i.group(2).upper() in STRUCS else None
        if m:
            SPACE.setdefault(m.group(1).upper(),
                             GROUPOF.get(segment, segment))


def covered(cover, space):
    """The register MASM would have reached an address space through.

    DS first, because a reference through DS needs no override at all, which
    is the one MASM wrote nothing for.  Then the others in the order MASM
    looked at them."""
    if space is None:
        return None
    for reg in ("ds", "cs", "es", "ss"):
        if cover.get(reg) == space:
            return reg
    return None


def overrides(body, cover, through=None):
    """The segment override MASM wrote for itself, from the ASSUME in force.

    The whole of this BIOS runs with ASSUME CS:BiosSeg,DS:NOTHING, DS being
    whatever the caller of a device driver happened to hold, so MASM put a
    CS: in front of every reference the BIOS makes to its own data: 28 of
    them in IBMBIO's Code segment and 52 in its BiosInit.  Converted without
    them the instruction is a byte shorter and reads from the wrong segment,
    which is the one kind of change that assembles, runs, and is wrong.

    A name another module declares is in the segment its EXTRN was declared
    in, which is MASM's rule and spaces() reads it that way.  One declared
    outside every segment is in none, so nothing here reaches it and no
    override is written -- which is what MASM did with it too.

    through is the name of a macro parameter, for a line inside a macro that
    reaches the module's own data: MASM expanded the macro at the call site
    and wrote the override from the ASSUME in force there, which is not the
    one in force where the macro is written.
    """
    # LEA works out an address and reads no memory, so there is no segment in
    # it for an override to change and MASM wrote none however DS stood:
    # IBMDSK has four, LEA SI,FloppyFunction and the like, and each of them
    # is five bytes in the object where ours came out six with a 2E in front.
    m = MNEMONIC.match(body)
    if m and m.group(2).upper() == "LEA":
        return body

    def one(m):
        inner = m.group(1)
        if re.match(r"(?i)^\s*(?:cs|ds|es|ss)\s*:", inner):
            return m.group(0)                   # the source said it already
        name = re.match(r"\s*([A-Za-z_@?$][\w@?$]*)", inner)
        if not name:
            return m.group(0)
        space = SPACE.get(name.group(1).upper())
        if through and space and space == GROUP.upper():
            return "[%s:%s]" % (through, inner)
        reg = covered(cover, space)
        if reg in (None, "ds"):
            return m.group(0)
        return "[%s:%s]" % (reg.upper(), inner)
    return re.sub(r"\[([^\]]*)\]", one, body)


def far_labels(text):
    """The names declared LABEL FAR.

    MASM assembles a CALL or a JMP of one as a far instruction, five bytes
    with a segment in it, even where the label is in the same segment as the
    instruction: the declaration is what says so.  IBMMTCON gives its
    interrupt 16H handler a second name that way, DoInt16 LABEL FAR, and
    calls it from a page above; dropped, the call came out as a three byte
    near one and everything after it moved."""
    return {m.group(1).upper() for m in
            re.finditer(r"(?im)^(" + N + r")\s+LABEL\s+FAR\s*(;.*)?$", text)}


def extrn_labels(text):
    """The names another module defines, and what MASM was told they are.

    EXTRN says the type as well as the name -- CURRENT_DOS_LOCATION:WORD,
    DEVICE_LIST:DWORD, DEFAULT_DRIVE:BYTE -- and a reference to one of those
    is a reference to memory, exactly as if it had been declared here.  So
    they belong with the storage this module declares itself: without them
    the bare name went through as an address and MASM had read it as the
    word at that address.  A NEAR or FAR external is a label and is left
    out of this."""
    labels = set()
    for raw in text.splitlines():
        code = raw.split(";")[0]
        if not re.match(r"(?i)^\s*EXTRN\b", code):
            continue
        for m in re.finditer(r"(\w+)\s*:\s*(BYTE|WORD|DWORD|QWORD|TBYTE)\b",
                             code, re.I):
            size = {"BYTE": "byte", "WORD": "word", "DWORD": "dword",
                    "QWORD": "qword", "TBYTE": "tbyte"}[m.group(2).upper()]
            labels.add(m.group(1).upper())
            SIZES.setdefault(m.group(1).upper(), size)
            EXTERNAL[m.group(1).upper()] = size
    return labels


def data_labels(text):
    """Everything the two modules reserve storage for.  MASM lets an
    instruction name one of these without brackets and resolves it to a memory
    reference; FASM reads the bare name as the address instead."""
    labels = set()
    for raw in text.splitlines():
        code = raw.split(";")[0]
        m = (re.match(r"^(" + N + r")\s+(?:DB|DW|DD)\b", code, re.I)
             or re.match(r"^\s*label\s+(" + N + r")\s", code, re.I))
        if m:
            labels.add(m.group(1).upper())
            d = re.match(r"^\s*" + N + r"\s+(DB|DW|DD)\b", code, re.I)
            if d:
                SIZES[m.group(1).upper()] = {"DB": "byte", "DW": "word",
                                             "DD": "dword"}[d.group(1).upper()]
            continue
        # MASM's NAME LABEL SIZE names storage as surely as a DB does, and
        # says what size it is: PROFIL keeps its output FCB behind an
        # OUT_FCB LABEL WORD and writes [OUT_FCB+14] to set the record
        # length.  Only the three storage sizes, so that a LABEL NEAR or
        # LABEL FAR -- a code label -- is left out of this.
        m = re.match(r"^(" + N + r")\s+LABEL\s+(BYTE|WORD|DWORD)\s*$",
                     code, re.I)
        if m:
            labels.add(m.group(1).upper())
            SIZES[m.group(1).upper()] = m.group(2).lower()
            continue
        # An instance of a structure, which reserves as much storage as the
        # structure is long: IBMDSK keeps each driver's state in one, Floppy
        # and Fixed, and writes Floppy.State and Fixed.Flags throughout.  No
        # size, because the instance as a whole has none -- the field says
        # what size a reference is.
        m = re.match(r"^(" + N + r")\s+(" + N + r")\s*<\s*>\s*$",
                     code.rstrip(), re.I)
        if m and m.group(2).upper() in STRUCS:
            labels.add(m.group(1).upper())
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


def indexed_base(text):
    """The name an indexed reference is counted from, upper case, or "".

    A number rather than a name -- the 2 of DS:2[DI] -- has no name to look
    up, and only the segment override says it is memory at all."""
    m = re.match(r"^[A-Za-z_@?$][\w@?$]*", text)
    return m.group(0).upper() if m else ""


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
    # MASM's type names are numbers as well as casts, and without PTR a
    # number is all they are: WORD is 2, and MASM added it to what came
    # after.  IBMDSK writes "cmp word [SemDiskIO],0001h" once, and the
    # object settles what MASM made of it -- the fixup on that instruction
    # names SemDiskIO+2, which is not the semaphore but the first byte of
    # the code after the data, and the compare is a byte compare of
    # FloppyInit's PUSH DS against 1.  So the Int 13 case it guards never
    # runs.  It is converted as MASM assembled it, which is the whole point
    # of converting rather than correcting.
    typed = re.match(r"(?i)^(BYTE|WORD|DWORD)\s*\[([^\]]+)\]$", core)
    if typed:
        core = "[%s+%d]" % (typed.group(2).strip(),
                            {"BYTE": 1, "WORD": 2,
                             "DWORD": 4}[typed.group(1).upper()])
    # MASM indexes a variable by writing the register after its name: PROFIL
    # counts a sample with INC BUCKET[BX], which is [BUCKET+BX].
    # The name may carry an offset of its own before the bracket, or be a
    # number outright: IBMBIO translates an error code with
    # MOV AL,ES:NUMERR-1[DI] and reads a word with MOV CX,DS:2[DI].
    indexed = re.match(r"^((?:[A-Za-z_@?$][\w@?$]*|\d\w*)"
                       r"(?:\s*[-+]\s*\w+)*)\s*\[([^\]]+)\]$", core)
    # And it writes the segment in front of the brackets and the field after
    # them: these sources are full of DS:[BX].CMD, which is [ds:bx+CMD].
    # The field is left to the passes that know the structures; this only
    # gets it inside the brackets, where FASM wants it.
    # The field may have an offset of its own after it: IBMMTCON writes the
    # segment of a buffer to DS:[bx].DatBuf+2.
    dotted = re.match(r"^\[([^\]]+)\]\s*\.(\w+)((?:\s*[-+]\s*\w+)*)$", core)
    # And it writes a plain offset after the brackets as readily as inside
    # them: IBMDSK looks at the next request in a queue with
    # CMP WORD PTR [SI]+2,0.
    after = re.match(r"^\[([^\]]+)\]((?:\s*[-+]\s*\w+)+)$", core)
    if dotted:
        inner = "%s+%s%s" % (dotted.group(1).strip(), dotted.group(2),
                             dotted.group(3).replace(" ", ""))
    elif after:
        inner = after.group(1).strip() + after.group(2).replace(" ", "")
    elif core.startswith("[") and core.endswith("]"):
        inner = core[1:-1]
    elif indexed and (seg or indexed_base(indexed.group(1)) in labels):
        inner = "%s+%s" % (indexed.group(1).replace(" ", ""),
                           indexed.group(2).strip())
    elif seg:
        inner = core
    else:
        # A variable with a field on it and no brackets anywhere: MASM
        # resolved that to memory as surely as it resolved a bare name, and
        # IBMDSK writes it 124 times -- MOV Floppy.State,Start.  The field
        # is left to the pass that knows the structures, as it is for
        # DS:[BX].CMD; this only says that the operand is memory.
        field = re.match(r"^(" + N + r")\.(\w+)((?:\s*[-+]\s*\w+)?)$", core)
        bare = re.match(r"^(\w+)((?:\s*[+-]\s*\w+)?)$", core)
        if field and field.group(1).upper() in labels:
            inner = core.replace(" ", "")
        elif bare and bare.group(1).upper() in labels:
            inner = bare.group(1) + bare.group(2).replace(" ", "")
    if inner is None:
        return op                       # a register or a number, left alone
    return "%s%s[%s%s]%s" % (lead, size, seg, inner, tail)


# A memory operand that already says its own size.
SIZED = re.compile(r"(?i)^\s*(?:byte|word|dword|qword|tbyte)\s*\[")


def bracket(body, labels):
    """MASM resolves a bare variable name to a memory reference; FASM reads it
    as the address.  Runs before OFFSET is taken off, so that MOV AX,OFFSET FOO
    stays an address and is not turned into a load from FOO."""
    m = MNEMONIC.match(body)
    if not m or m.group(2).upper() in NOTCODE:
        return body
    ops = [one_operand(op, labels) for op in split_operands(m.group(4))]

    # An indirect JMP or CALL with no PTR on it, which MASM assembled as a
    # near one: ANSI.INC dispatches on its command table with JMP [SI].
    if m.group(2).upper() in ("JMP", "CALL"):
        for i, op in enumerate(ops):
            if not re.fullmatch(r"\s*\[[^\]]+\]\s*", op):
                continue
            # The width is what makes it near or far, and MASM took it from
            # the name's own declaration: the console driver reaches the DOS
            # through CALL DosFunction, declared EXTRN DosFunction:DWORD,
            # and the keyboard ROM through CALL [OldKbdHandler], a DD of its
            # own, and both of those are far calls.  Where there is no name
            # to ask -- ANSI.INC dispatches with JMP [SI] -- MASM assembled
            # a near one.
            # Past the override, if the line carries one: the console
            # driver's keyboard handler reaches the ROM's through
            # CALL CS:OldKeyInterrupt, and read as far as the CS the name
            # looked up was the register and the call came out near.
            b = re.fullmatch(r"\s*\[(?:(?:CS|DS|ES|SS):)?"
                             r"([A-Za-z_@?$][\w@?$]*)[^\]]*\]\s*", op, re.I)
            size = SIZES.get(b.group(1).upper(), "word") if b else "word"
            ops[i] = op.replace("[", size + " [", 1)

    # A CALL or JMP of a label declared LABEL FAR needs the segment written
    # on it, which farpointer() does once the rest of the line is settled.

    # PUSH and POP of memory: MASM took a word, FASM wants it said.
    if m.group(2).upper() in ("PUSH", "POP"):
        for i, op in enumerate(ops):
            if re.fullmatch(r"\s*\[[^\]]+\]\s*", op):
                ops[i] = op.replace("[", "word [", 1)

    # MASM let a byte register meet a word variable and took the low byte of
    # it -- CHKDSK does XCHG AL,ERRSUB where ERRSUB is a DW.  FASM wants the
    # size said, so say it.
    # A reference to another module's storage.  The link file stands a
    # number in for the name, because the module that defines it is
    # assembled apart -- and a number carries no size, where MASM had the
    # EXTRN to tell it.  So the size the EXTRN gave is written on the
    # reference: without it FASM asks for one, and on a line where the other
    # operand is a register it would have guessed from that instead.
    for i, op in enumerate(ops):
        if SIZED.match(op):
            continue
        b = re.fullmatch(r"(\s*)\[((?:(?:CS|DS|ES|SS):)?)"
                         r"([A-Za-z_@?$][\w@?$]*)([^\]]*)\](\s*)", op, re.I)
        if b and b.group(3).upper() in EXTERNAL:
            ops[i] = "%s%s [%s%s%s]%s" % (b.group(1),
                                          EXTERNAL[b.group(3).upper()],
                                          b.group(2), b.group(3), b.group(4),
                                          b.group(5))

    # The size of a field reached through a second name, which MASM read from
    # the field the name stands for and FASM has nothing to read: an EQU of a
    # field is a number.  MOV Fixed.DCB,HD_CREAD says nothing else about how
    # wide it is, where MOV Fixed.State,Start is told by the label the
    # structure's own field has.
    # Only where nothing else on the line says it.  A register operand does,
    # and where the two disagreed MASM took the register's size -- it let a
    # byte register meet a word field and read the low byte of it -- so a
    # line with a register on it is left alone.
    if UNSIZED and not any(
            re.fullmatch(r"\s*(?:[ABCD][XLH]|[SD]I|[BS]P|CS|DS|ES|SS)\s*",
                         op, re.I) for op in ops):
        for i, op in enumerate(ops):
            if SIZED.match(op):
                continue
            b = re.fullmatch(r"(\s*)\[([^\]]*)\](\s*)", op)
            if not b:
                continue
            for word in re.findall(r"[A-Za-z_@?$][\w@?$]*", b.group(2)):
                if word.upper() in UNSIZED:
                    ops[i] = "%s%s [%s]%s" % (b.group(1),
                                              UNSIZED[word.upper()],
                                              b.group(2), b.group(3))
                    break

    if any(re.fullmatch(r"\s*[ABCD][LH]\s*", op, re.I) for op in ops):
        for i, op in enumerate(ops):
            b = re.fullmatch(r"(\s*)\[(\w+)([^\]]*)\](\s*)", op)
            if b and SIZES.get(b.group(2).upper(), "byte") != "byte":
                ops[i] = "%sbyte [%s%s]%s" % (b.group(1), b.group(2),
                                              b.group(3), b.group(4))
    return "%s%s%s%s" % (m.group(1), m.group(2), m.group(3), ",".join(ops))


# A name FASM reserves can also be the mnemonic of the line it appears on:
# DEBUG defines labels called IN, OUT and TEST and uses all three
# instructions as well.  The mnemonic is the one place the name cannot be a
# reference, so it is held back while the rest of the line is rewritten.
# Leading whitespace is required, which is what tells an instruction from a
# definition: "STACK LABEL BYTE" starts in the first column.
MNEMONIC_POS = re.compile(r"^(\s+(?:" + N + r":\s*)?)([A-Za-z]\w*)(?=\s)")


def line(code):
    def words(t):
        t = re.sub(r"\b(BYTE|WORD|DWORD)\s+PTR\b", lambda m: m.group(1).lower(), t, flags=re.I)
        # OFFSET names an address, so where the source bracketed the name
        # inside it the brackets go with the OFFSET: RECOVER writes
        # "mov dx,offset dg: [dirchar]", and left bracketed that is a word
        # load from a byte.
        t = re.sub(r"\bOFFSET\s+((?:\w+\s*:\s*)?)\[\s*([^\]]+?)\s*\]",
                   lambda m: m.group(1) + m.group(2), t, flags=re.I)
        # MASM lets a segment register qualify the offset it is asked for:
        # IBMBIO writes "mov SI,offset CS:memsizmsg".  CS is assumed to the
        # group and the label's offset is its offset in the group, so the
        # qualifier has nothing to add -- and left in place it is a syntax
        # error here rather than a wrong number.
        t = re.sub(r"\bOFFSET\s+(?:CS|DS|ES|SS)\s*:\s*", "OFFSET ", t,
                   flags=re.I)
        # A segment of the module's own in front of the name, as in
        # "mov ax,offset RomData:KeyBuffer".  A label in a SEGMENT AT is
        # already the offset in that segment -- the conversion makes a
        # virtual block of it at the same address -- and a label in the
        # group is already a group offset, so either way the qualifier has
        # nothing left to say.
        t = re.sub(r"\bOFFSET\s+(" + N + r")\s*:\s*",
                   lambda m: ("OFFSET " if m.group(1).upper() in SEGNAMES
                              else m.group(0)), t, flags=re.I)
        # MASM's SEG, the paragraph a name lives in, which LINK filled in
        # and which this build cannot know: SYSINIT is in the module whose
        # source was never published, and BiosInit's own base is a fixup in
        # the object as well.  Each becomes a name the link file stands a
        # placeholder in for, so that it is plain in the source that this is
        # a number nobody here has.
        t = re.sub(r"\bSEG\s+([A-Za-z_@?$][\w@?$]*)", r"\1$SEG", t, flags=re.I)
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
        # MASM spells the comparisons in letters.  There are two in the
        # tree, both in an assertion: ANSI.INC checks that its terminal
        # state fits the room the SIB leaves for it, and IBMDSK that the
        # error table it indexes has not moved.
        for was, now in (("GE", ">="), ("LE", "<="), ("NE", "<>"),
                         ("GT", ">"), ("LT", "<"), ("EQ", "=")):
            t = re.sub(r"\b%s\b" % was, now, t, flags=re.I)
        # IFDEF and IFNDEF, which ask whether a name has been defined at
        # all.  FASM asks the same question with defined, and the switch
        # these sources ask about -- DEBUGFLG -- is never defined, each
        # module having the line that would, commented out.
        t = re.sub(r"\bIFDEF\s+(\w+)", r"if defined \1", t, flags=re.I)
        t = re.sub(r"\bIFNDEF\s+(\w+)", r"if ~ defined \1", t, flags=re.I)
        # BP.FIELD, the way FORMAT addresses a structure, and [BX].FIELD,
        # the way FC does it throughout: "mov word [bx].buf,b1" means
        # [bx+buf], buf being an equate rather than a structure field -- FC
        # declares no structure at all and counts its offsets out by hand.
        # In either case: FORMAT writes BP.FIELD and RECOVER writes
        # bx.dpb_current_dir, and without re.I the lower case one went
        # through as a symbol with a dot in the middle of it.
        t = re.sub(r"\b(BP|BX|SI|DI)\.(\w+)\b",
                   lambda m: "%s+%s" % (m.group(1), FIELDS.get(m.group(2).upper(), m.group(2))),
                   t, flags=re.I)
        # MASM adds two index registers by writing them as two brackets:
        # RECOVER has "mov bx,word [bx][si]", which is [bx+si].
        t = re.sub(r"\]\s*\[", "+", t)
        # A field applied to a variable rather than to a register: PRINT
        # writes LISTFCB.fcb_DEVID for the device bits of the FCB it keeps at
        # LISTFCB.  The field is an offset, so the two add -- but only where
        # the name is a variable and the field a known one, or this would
        # rewrite the sys_fcb.fcb_DEVID the field itself has become.
        def var_field(m, _f=None):
            name, field = m.group(1), m.group(2).upper()
            if name.upper() in STRUCS:
                return m.group(0)
            for table in (FIELDS, DOSFIELDS):
                if field in table:
                    return "%s+%s" % (name, table[field])
            return m.group(0)
        t = re.sub(r"\b([A-Za-z_]\w*)\.(\w+)\b", var_field, t)
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
    hold, m = None, MNEMONIC_POS.match(code) if RESERVED else None
    if m and m.group(2).upper() in {r.upper() for r in RESERVED}:
        hold = m.group(2)
        code = code[:m.start(2)] + "\0" + code[m.end(2):]
    out = outside_strings(code, words)
    return out.replace("\0", hold, 1) if hold else out


def switches(text):
    """The module's own switches, as numbers: NAME EQU TRUE and the like.

    Only what one of these files sets at the top of itself and tests with an
    IF -- a number, TRUE, FALSE, NOT of one of those, or another name that
    comes to one of them.  Anything else is left unresolved, and
    segment_guards() stops rather than guess at it."""
    said = {}
    for raw in text.splitlines():
        code = raw.split(";")[0]
        m = re.match(r"(?i)^\s*(" + N + r")\s*(?:=|\bEQU\b)\s*(.+?)\s*$", code)
        if m:
            said.setdefault(m.group(1).upper(), m.group(2))

    def value(word, seen=()):
        word = word.strip().upper()
        if re.fullmatch(r"-?\d+", word):
            return int(word)
        if re.fullmatch(r"[0-9A-F]+H", word):
            return int(word[:-1], 16)
        m = re.fullmatch(r"NOT\s+(.+)", word)
        if m:
            inner = value(m.group(1), seen)
            return None if inner is None else ~inner
        if word in seen or word not in said:
            return None
        return value(said[word], seen + (word,))

    return {name: value(said[name]) for name in said}


def segment_guards(text):
    """The lines of a conditional that moves from one segment to another.

    IBMMTCON ends its Code segment and opens BiosInit inside an IF:

	IF	INBIOS
	Code	ends
	BiosInit	segment	para public 'CODE'
	ENDIF

    and a conditional cannot straddle the one the walk is wrapped in.  Written
    through as they stand the two interleave: MASM's ENDIF closes the
    conditional the SEGMENT opened, the data after it falls inside the segment
    that was meant to have ended, and BiosInit comes out with nothing in it.
    It came out that way, and the single module's build hid it -- BiosInit
    holds one message, the message is the last thing in the file, and
    concatenated after Code's bytes it landed exactly where BIOSINIT's bytes
    belonged.  Only the link that lays all three modules out showed it, Code
    being 47 bytes longer than its object with IBMDSK's bytes after it.

    So a conditional that holds a SEGMENT or an ENDS of a walked segment is
    resolved here instead of being handed to FASM, from the switches the
    module sets itself, and only the branch MASM took is written.  Returns
    the lines to leave out.  A segment that opens and closes inside the one
    conditional is not one of these: IBMBIO declares RomData that way, the
    pair nests, and it is left alone."""
    drop, stack = set(), []
    said = switches(text)
    lines = text.splitlines()
    for i, raw in enumerate(lines):
        code = raw.split(";")[0]
        if OPENSIF.match(code):
            m = re.match(r"(?i)^\s*IF\s+(" + N + r")\s*$", code)
            stack.append({"if": i, "name": m.group(1) if m else None,
                          "else": None, "holds": False})
            continue
        if ELSESIF.match(raw) and stack:
            stack[-1]["else"] = i
            continue
        if CLOSESIF.match(code) and stack:
            top = stack.pop()
            if not top["holds"]:
                continue
            taken = said.get((top["name"] or "").upper())
            if taken is None:
                sys.exit("line %d: %s moves from one segment to another and "
                         "nothing here says whether it was taken"
                         % (top["if"] + 1, lines[top["if"]].strip()))
            drop.add(top["if"])
            drop.add(i)
            if top["else"] is None:
                dead = range(i, i) if taken else range(top["if"] + 1, i)
            else:
                drop.add(top["else"])
                dead = (range(top["else"] + 1, i) if taken
                        else range(top["if"] + 1, top["else"]))
            drop.update(dead)
            continue
        m = re.match(r"(?i)^\s*(\w+)\s+(SEGMENT|ENDS)\b", code)
        if m and m.group(1).upper() in SEGMENTS and stack:
            stack[-1]["holds"] = True
    return drop


def farpointer(code):
    """The segment MASM wrote on a far pointer, which is the group's base.

    Two lines in these modules hold a label's offset and the segment it is
    in, and in both MASM wrote the segment itself and left LINK to fill it:

      * a CALL or JMP of a label declared LABEL FAR, which is a far
        instruction because the declaration says so, and
      * a DD of a label, which is how a device header points at the next
        device in the chain -- IBMDSK's floppy at its fixed disk, its fixed
        disk at IBMBIO's COM1, IBMMTCON's console at IBMBIO's AUX.

    Both become the group's name and the label, and the link file says what
    the group's base came to: zero where a module is assembled by itself,
    those bytes being a fixup the object comparison ignores, and 70h in the
    link that builds the whole BIOS, where they have to be right.  Left as a
    bare label the DD came out an offset and a zero, and the device chain
    led to 0000:011Dh instead of 0070:011Dh.

    This runs after the rest of the line is settled, because line() strips a
    group qualifier off a label -- an offset counted from the group's base is
    what a label in the group already is -- and would strip this one too."""
    if not GROUP:
        return code
    m = re.match(r"(?i)^(\s*)(CALL|JMP)(\s+)(" + N + r")(\s*)$", code)
    if m and m.group(4).upper() in FARLABEL:
        return "%s%s%s%s:%s%s" % (m.group(1), m.group(2), m.group(3),
                                  GROUP, m.group(4), m.group(5))
    m = re.match(r"(?i)^(\s*(?:" + N + r"\s+)?)(DD)(\s+)(" + N + r")(\s*)$",
                 code)
    if m and m.group(4).upper() in LABELS:
        return "%s%s%s%s:%s%s" % (m.group(1), m.group(2), m.group(3),
                                  GROUP, m.group(4), m.group(5))
    return code


def seeded(text):
    """What the segment registers hold before the module's first line.

    MASM read a file as part of the one it is included in, so an include
    inherits the ASSUME in force where it is read: ANSI.INC has not one
    ASSUME of its own and is read in the middle of IBMMTCON's Code, under
    ASSUME CS:BiosSeg,DS:NOTHING,ES:NOTHING.  Converted with the registers
    on nothing, as MASM starts a module, not one of its two dozen variables
    got the override MASM wrote for it.  The table says which, because
    nothing in the file itself does."""
    cover = {"cs": None, "ds": None, "es": None, "ss": None}
    for reg, seg in re.findall(r"(?i)\b(cs|ds|es|ss)\s*:\s*(?:SEG\s+)?(\w+)",
                               text):
        name = seg.upper()
        cover[reg.lower()] = (None if name == "NOTHING"
                              else GROUPOF.get(name, name))
    return cover


def convert(text, renames, first=False, assume=""):
    """first says this is the module that brings DOSSYM in: every module had
    its own INCLUDE of it, and including it twice redefines every structure."""
    out, inmacro, infar, absolute, opened = [], [], [], [], []
    # What each segment register is assumed to hold, which MASM read every
    # reference against.  It starts as MASM started a module, on nothing,
    # unless the table says this one is read inside another.
    cover = seeded(assume)
    # A conditional that moves from one segment to another is settled before
    # the walk sees it, these being its lines.
    skip = segment_guards(text)
    for at, raw in enumerate(text.splitlines()):
        if at in skip:
            continue
        # Before anything else, so that a renamed macro parameter is renamed
        # in the MACRO line too and not only in the body.
        for was, now in renames.items():
            # In either case, MASM's names being case blind: EDLIN defines
            # RET$5 and jumps to ret$5, and renaming only what matched
            # exactly left the definition behind under its old name.
            raw = outside_strings(raw, lambda t, w=re.escape(was), n=now:
                                  re.sub(r"\b%s\b" % w, n, t, flags=re.I))
        # A SEGMENT AT lays nothing down: it names the fields of memory that
        # is already there, and MASM resolved a reference to one of them to
        # the address it said.  PCLOCK_IBM.ASM declares INTSEG AT 0 to reach
        # the counter 0 interrupt vector, which is FASM's virtual block.
        # The names it declares have to be declared once however many times
        # the walk reads the module, so in a segmented program the block goes
        # in the pass over the first segment and holds for the rest.
        m = re.match(r"^\s*(\w+)\s+SEGMENT\s+AT\s+(\S.*?)\s*$", raw, re.I)
        if m:
            if SEGMENTS:
                out.append("if SEGSEL = S_%s" % SEGMENTS[0])
            # The paragraph the segment sits at, which is what MASM gave
            # when the segment's name was used as a value: IBMMTCON loads
            # the ROM's data area with "mov ax,RomData" and the display
            # buffers with MonoSc and ColorSc.
            out.append("%s = %s" % (m.group(1), m.group(2)))
            # And the offsets inside it, which are the segment's own and
            # start at zero.  Not at the paragraph: every one of these
            # blocks happens to open with an ORG that would have covered the
            # difference, but a block without one would have had every label
            # in it out by the segment's address.
            out.append("virtual at 0")
            absolute.append(m.group(1).upper())
            continue
        if absolute:
            m = re.match(r"^\s*(\w+)\s+ENDS\s*$", raw, re.I)
            if m and m.group(1).upper() == absolute[-1]:
                absolute.pop()
                out.append("end virtual")
                if SEGMENTS:
                    out.append("end if")
                continue
        if SEGMENTS:
            # MASM lets one segment stand inside another, and IBMDSK writes
            # BiosInit in the middle of Code: the object says so, its CODE
            # chunks stopping at 0x334 and starting again there with the
            # whole of BIOSINIT in between.  The outer segment is suspended
            # rather than ended, so the pass over it is closed and the inner
            # one's opened -- written as a conditional inside a conditional,
            # the inner block would have stood inside one that is false in
            # its own pass, and BIOSINIT would have come out empty.
            m = re.match(r"^\s*(\w+)\s+SEGMENT\b", raw, re.I)
            if m and m.group(1).upper() in SEGMENTS:
                if opened:
                    out.append("end if")
                out.append("if SEGSEL = S_%s" % m.group(1).upper())
                opened.append(m.group(1).upper())
                continue
            m = re.match(r"^\s*(\w+)\s+ENDS\s*$", raw, re.I)
            if m and m.group(1).upper() in SEGMENTS:
                out.append("end if")
                if opened:
                    opened.pop()
                if opened:
                    out.append("if SEGSEL = S_%s" % opened[-1])
                continue
        # FASM's macro names are case sensitive, and the ASSUME the conversion
        # leans on -- a macro that does nothing, MASM's being a directive --
        # is spelled in capitals.  The sources are not consistent about it:
        # EXE2BIN.ASM writes "assume es:data" half the time.
        m = re.match(r"^(\s*)ASSUME\b(.*)$", raw, re.I)
        if m:
            raw = "%sASSUME%s" % (m.group(1), m.group(2))
            for reg, seg in re.findall(
                    r"(?i)\b(cs|ds|es|ss)\s*:\s*(?:SEG\s+)?(\w+)",
                    m.group(2).split(";")[0]):
                name = seg.upper()
                cover[reg.lower()] = (None if name == "NOTHING"
                                      else GROUPOF.get(name, name))
        # A PROC is just a label, except that MASM assembles the RET of a FAR
        # one as a far return.  CHKPROC's INT_24 depends on it: it pushes a
        # frame and the far address of the handler and returns to that.
        # The comment after it is not decoration in every source: FIND has
        # "badfart proc far ;(what a hack!!)", and without the comment allowed
        # for here the line went through as an instruction and FASM refused it.
        m = re.match(r"^(\s*)(" + N + r")\s+PROC\s*(NEAR|FAR)?\s*(;.*)?$",
                     raw, re.I)
        if m:
            # The name may be one FASM keeps, and this branch is the one
            # place a definition never reached the pass that renames those:
            # IBMMTCON declares Break PROC NEAR for its control break
            # handler, every reference to it came out Break_, and the
            # definition stayed behind under the old name.
            name = m.group(2)
            if name.upper() in {r.upper() for r in RESERVED}:
                name += "_"
            out.append("%s%s:%s" % (m.group(1), name, m.group(4) or ""))
            infar.append((m.group(3) or "NEAR").upper() == "FAR")
            continue
        if re.match(r"^\s*\w+\s+ENDP\s*(;.*)?$", raw, re.I):
            if infar:
                infar.pop()
            continue
        # RET with a count is as far as the plain one: PRINT's INT_13_BACK
        # ends "RET 2" to drop the flags word of the frame it was entered on,
        # and left near it returned into the middle of the stack.
        if infar and infar[-1]:
            raw = re.sub(r"^(\s*(?:" + N + r":\s*)?)RET\b(\s*(?:\d+\s*)?(?:;.*)?)$",
                         r"\1RETF\2", raw, flags=re.I)
        m = re.match(r"^\s*(\w+)\s+MACRO\s*(.*?)\s*$", raw, re.I)
        if m:
            # A macro whose body reaches the module's own data takes the
            # register that reaches it as its first argument, because the
            # ASSUME that decided it was the call site's and not this one's.
            seg = m.group(1).upper() in {k.upper() for k in SEGMACROS}
            out.append("macro %s %s%s" % (m.group(1), "seg," if seg else "",
                                          m.group(2)))
            out.append("{")
            inmacro.append(seg)
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
        # The comment after it is not decoration: IBMDSK says which drive
        # each of its four drive tables is for.
        m = re.match(r"^(\s*\w+\s+)(\w+)\s*<\s*>\s*(;.*)?$", raw.rstrip())
        if m:
            n = STRUC_PARAMS.get(m.group(2).upper(), 0)
            raw = (m.group(1) + m.group(2)
                   + (" " + ",".join("?" * n) if n else "")
                   + ("\t" + m.group(3) if m.group(3) else ""))
        # MASM's way of writing an assertion: a conditional whose false
        # branch is .RADIX 0, which is not a radix and stops the assembly.
        # ANSI.INC checks that its state table is big enough that way.
        m = re.match(r"(?i)^([ \t]*)\.RADIX[ \t]+0[ \t]*(;.*)?$", raw)
        if m:
            out.append("%serr%s" % (m.group(1), " " + m.group(2)
                                    if m.group(2) else ""))
            continue
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
        m = re.match(r"^(\s*" + N + r"\s+)LABEL\s+(BYTE|WORD|DWORD)\s*$",
                     body, re.I)
        if m:
            body = "label %s %s" % (m.group(1).strip(), m.group(2).lower())
        # A LABEL NEAR or FAR names a place in the code rather than storage,
        # and a colon is all that is: IBMMTCON gives its interrupt 16H entry
        # a second name that way, DoInt16 LABEL FAR.  What made the call to
        # it far was the FAR on the EXTRN in the module that calls it, which
        # the link file says instead.
        m = re.match(r"^(\s*)(" + N + r")\s+LABEL\s+(?:NEAR|FAR)\s*$",
                     body, re.I)
        if m:
            body = "%s%s:" % (m.group(1), m.group(2))
        # MASM's THIS names the place the counter has reached without
        # laying anything down, which is what LABEL does: PROFIL declares
        # PROG_ENTRY EQU THIS DWORD over the two words of the program's
        # entry point.  Turned into a plain = it would be the address as a
        # number and lose the size with it.
        m = re.match(r"^(\s*)(\w+)\s+EQU\s+THIS\s+(BYTE|WORD|DWORD)\s*$",
                     body, re.I)
        if m:
            body = "%slabel %s %s" % (m.group(1), m.group(2),
                                      m.group(3).lower())
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
        # And the call of one hands it in.  MASM expanded the macro here,
        # under the ASSUME in force here: IBMDSK calls SemWait and SemSig
        # from six places, four of them with DS on nothing, where the
        # override is CS, and two with DS on BiosSeg, where MASM wrote none.
        if SEGMACROS:
            m = re.match(r"^(\s*)(\w+)(\s+)(.*?)(\s*)$", body)
            if m and m.group(2).upper() in {k.upper() for k in SEGMACROS}:
                reg = covered(cover, GROUP.upper())
                if reg is None:
                    sys.exit("%s is called where nothing reaches %s"
                             % (m.group(2), GROUP))
                body = "%s%s%s%s,%s%s" % (m.group(1), m.group(2), m.group(3),
                                          reg.upper(), m.group(4), m.group(5))
        body = bracket(body, LABELS)
        body = overrides(body, cover,
                         "seg" if inmacro and inmacro[-1] else None)
        body = line(body)
        body = farpointer(body)
        out.append(body + sep + comment if sep else body)
    return "\n".join(out) + "\n"


def main(program):
    # The structures and the storage first, across every module at once: one
    # module names variables another defines, so the set of things that need
    # brackets is only complete once all of them have been read.
    global LABELS, DOSFIELDS, DOSFIELD_RE, MODULES, SEGMENTS, RESERVED, RENAMES
    if program not in PROGRAMS:
        sys.exit("usage: convert.py %s" % " | ".join(sorted(PROGRAMS)))
    spec = PROGRAMS[program]
    MODULES, SEGMENTS = spec["modules"], tuple(spec["segments"])
    RESERVED, RENAMES = spec["reserved"], spec["renames"]
    global SILENT, REGIONS, SEGMACROS
    SILENT, REGIONS = spec["silent"], spec["regions"]
    SEGMACROS = spec.get("segmacros", {})
    global ASSUMED
    ASSUMED = spec.get("assume", {})
    global GROUP
    GROUP = spec["group"]
    global DOSSYM
    DOSSYM = spec["dossym"]
    global MACROS
    MACROS = spec["macros"]
    # A macro call is not an instruction, and its arguments are names rather
    # than memory: bracketing them would pass [BadDrv] where BadDrv was meant.
    NOTCODE.update(MACROS)
    # The call of a macro that takes its caller's segment register is not an
    # instruction either, and the register is written on to it by hand.
    NOTCODE.update(k.upper() for k in SEGMACROS)
    DOSFIELDS = dossym_fields()
    texts = {}
    for name in MODULES:
        path = os.path.join(SRC, name)
        text = open(path, newline="").read()
        if "end if" in text or "virtual at" in text:
            sys.exit("%s looks converted already; nothing done." % name)
        texts[name] = struct_arrays(struc(irp_macros(
            dollars(silenced(commented(page_breaks(text)))))))
        field_aliases(texts[name])
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
    # A macro parameter that stands for a variable is memory, and FASM has no
    # declaration of it to read: the size the caller's variable has is in the
    # table, and the address space is the module's own, which is what says
    # the override goes on it.
    for params in SEGMACROS.values():
        for param, size in params.items():
            LABELS.add(param.upper())
            SIZES[param.upper()] = size
            EXTERNAL[param.upper()] = size
            SPACE[param.upper()] = GROUP.upper()
    for name, text in texts.items():
        spaces(text)
        FARLABEL.update(far_labels(text))
        found = data_labels(text) | extrn_labels(text)
        for was, now in RENAMES.get(name, {}).items():
            if was in found:
                found.discard(was)
                found.add(now.upper())
        LABELS |= found
    for name, text in texts.items():
        open(os.path.join(SRC, name), "w", newline="").write(
            convert(text, RENAMES.get(name, {}), name == MODULES[0],
                    ASSUMED.get(name, "")))
        print("converted %s" % name)
    print("%d labels that MASM would have resolved for itself" % len(LABELS))


if __name__ == "__main__":
    main(sys.argv[1].upper() if len(sys.argv) > 1 else "")
