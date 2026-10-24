#!/usr/bin/env python3
#
# The message compiler.
#
# Every program in this release gets its text from MESSAGES/USA-MS.MSG rather
# than from its own source: the source names a message, and BUILDMSG, which
# Microsoft shipped as a binary in src/TOOLS and not as source, wrote the
# include file that holds it.  Nothing here assembles without that step, so
# this is it again, in Python.
#
# A program declares what it needs in a skeleton file, <program>.SKL:
#
#   :class 1                           what follows belongs to class 1
#   :use 001 BOOT SYSMSG               message 001 of class BOOT, as SYSMSG
#   :def 20 SNGMSG DB 13,10,"Insert "  message 20 of this program's own class
#   :end
#
# and the message file holds a class per program, each message on a line of
# its own, continued on the next if it is long:
#
#   BOOT     58c1 0001                       class, offset, number of messages
#   0001 U 0000 13,10,"Non-System disk ..."   number, state, flags, the text
#        "Replace and press any key when ready",13,10,0
#
# A program's own class is the one named by :util, or the skeleton's own name
# when there is none.  The text in a :def line is not used: it is the English
# the message once had, and the message file is what the build reads -- which
# is why the boot sector says "press any key when ready" where BOOT.SKL still
# says "strike".  Only the label and the DB go with the declaration.
#
# Each class comes out as a file of its own, named after the skeleton with the
# class for an extension: MSBIO.SKL writes MSBIO.CL1 through MSBIO.CL5, which
# is what the five modules that hold those messages include.
#
# The text is already a list of assembler operands, so it comes out as it went
# in, bar the symbolic control characters -- CR, LF and the rest, which
# SYSMSG.INC defines and the programs that do not include it would not
# resolve.  Those are written as numbers.
#
# Two output shapes, because the programs come in two kinds.
#
# A :use or :def line that names a label, as above, is one declaration in the
# program's own address space, and that is all the boot sector, the BIOS and
# the kernel want of the message file.
#
# The utilities instead call the message retriever in INC/MSGSERV.ASM, which
# looks a message up by number while the program runs, and they want the
# tables it walks.  Their declarations name no label and carry the message's
# number on the end of the class instead:
#
#   :util MORE                   the utility's own class in the message file
#   :class A                     its own messages go in class A
#   :use 1 COMMON1               message 1 of class COMMON, as message 1 here
#   :def 2 "-- More --"          message 2 of MORE's class, as message 2 here
#
# so MORE asks for COMMON's first message, "Incorrect DOS version", and for
# its own second, and both are numbered as the first field says.
#
# A class comes out as the table MSGSERV walks -- a header of the class
# identifier, the version it was built for and the number of messages, then
# a number and a pointer for each, then the texts, each behind a length byte
# -- with a routine in front of it that answers with its address, because
# that is how MSGSERV collects them: SYSMSG.INC's M_BUILD_PTRS$ calls
# M_CLS_1$ for the first class, M_CLS_2$ for the second and so on as far as
# M_NUM_CLS$, which the .CTL file holds, and MSGSERV itself calls
# M_MSGSERV_1$ and M_MSGSERV_2$ for the two classes DOS numbers rather than
# letters: 1 the extended errors and 2 the parse errors.  Those two are asked
# for whether the skeleton declares them or not, so they are always written,
# empty if there is nothing in them.
#
# The pointer to a message is counted from the entry that holds it, not from
# the start of the class, because that is what MSGSERV adds it to; and the
# length byte is left to the assembler, which can see where the text ends.

import argparse
import os
import re
import sys

# SYSMSG.INC's control characters, which a message may name instead of
# writing the number.
CONTROLS = {
    "NULL": 0, "BELL": 7, "TAB": 9, "LF": 10, "HOME": 11,
    "FORMFD": 12, "CR": 13, "COLON": 0x3A,
}

CLASS_HEADER = re.compile(r"^([A-Z][A-Z0-9_]*) +([0-9a-fA-F]{4}) +(\d{4})\s*$")
MESSAGE = re.compile(r"^(\d{4}) +(\w) +(\d{4}) +(.*)$")
DECLARATION = re.compile(r"^:(use|def)\s+(?:(-?\d+)\s+)?(\S+)(?:\s+(\S+))?\s*(.*)$",
                         re.I)


def read_messages(path):
    """The message file, as {class: {number: [line of text, ...]}}."""
    classes = {}
    current = None
    message = None
    with open(path, "r", encoding="cp437") as f:
        lines = [l.rstrip("\r\n") for l in f]
    for line in lines[1:]:                   # line 1 is the file's own count
        if not line.strip():
            continue
        header = CLASS_HEADER.match(line)
        if header:
            current = {}
            classes[header.group(1).upper()] = current
            message = None
            continue
        if current is None:
            continue
        found = MESSAGE.match(line)
        if found:
            message = [found.group(4).rstrip()]
            current[int(found.group(1))] = message
        elif line[0] in " \t" and message is not None:
            message.append(line.strip())
        else:
            raise SystemExit("%s: cannot read line: %s" % (path, line))
    return classes


def plain_controls(text):
    """CR and LF and the rest as numbers, leaving the quoted text alone."""
    out = []
    for part in re.split(r'("[^"]*"|\'[^\']*\')', text):
        if part[:1] in "\"'":
            out.append(part)
        else:
            out.append(re.sub(r"\b[A-Z]+\b",
                              lambda m: str(CONTROLS.get(m.group(0),
                                                         m.group(0))),
                              part))
    return "".join(out)


# ":use 1 COMMON1" -- the class with the message's number on the end of it.
APPENDED = re.compile(r"^([A-Za-z][A-Za-z0-9_]*?)(\d+)$")


def read_skeleton(skeleton):
    """One .SKL file as its classes and what each of them asks for.

    Returns the utility's own class, the classes in the order they are
    declared, and for each a list of declarations.  A declaration is either
    labelled -- a name to give the text in the program's own address space --
    or a numbered entry for one of the retriever's tables, and a skeleton is
    all of one kind or all of the other."""
    base = os.path.basename(skeleton).rsplit(".", 1)[0].upper()
    with open(skeleton, "r", encoding="cp437") as f:
        source = [l.rstrip("\r\n") for l in f]

    own = base                        # the class this program's messages are in
    for line in source:
        named = re.match(r"^:util\s+(\S+)", line, re.I)
        if named:
            own = named.group(1).upper()

    classes = []                      # [(name, [declaration, ...]), ...]
    here = None
    for line in source:
        line = line.rstrip()
        # Anything that is not a directive is a comment, or a later line of
        # the declaration above it -- and a declaration's text comes from the
        # message file, however many lines the skeleton wrote it on.
        if not line.startswith(":"):
            continue
        # Trailing ";AN000;" change marks are the release's, not ours.
        body = re.sub(r"\s*;.*$", "", line[1:])
        word = body.split()
        if not word:
            continue
        directive = word[0].lower()

        if directive in ("end", "util"):
            continue
        if directive == "class":
            here = (word[1].upper(), [])
            classes.append(here)
            continue

        # Read the declaration from the line with its comment taken off: the
        # comment is where the skeleton says what the message used to be, and
        # a ";" in it would otherwise look like the field after the class.
        found = DECLARATION.match(":" + body)
        if not found or directive not in ("use", "def"):
            raise SystemExit("%s: cannot read line: %s" % (skeleton, line))
        if here is None:
            raise SystemExit("%s: no class before: %s" % (skeleton, line))

        local = found.group(2)
        third, fourth = found.group(3), found.group(4)
        local = int(local) if local is not None else None

        if directive == "use" and re.match(r"^[A-Za-z_][A-Za-z0-9_]*:?$", third
                                           or "") and fourth is not None:
            # ":use 001 BOOT SYSMSG" -- message 001 of class BOOT, declared
            # here under the name the program calls it by.
            if local is None:
                raise SystemExit("%s: no message number: %s" % (skeleton, line))
            here[1].append(("label", third.upper(), local, fourth, "db"))
        elif directive == "use":
            # ":use 1 COMMON1" -- message 1 of class COMMON, numbered 1 here;
            # and ":use EXTEND8" -- message 8 of class EXTEND, numbered 8,
            # which is how the classes DOS numbers are written, since there
            # the number is the error code and cannot be anything else.
            split = APPENDED.match(third)
            if not split:
                raise SystemExit("%s: no message number on the class: %s"
                                 % (skeleton, line))
            number = int(split.group(2))
            here[1].append(("table", local if local is not None else number,
                            split.group(1).upper(), number))
        elif (local is not None
              and re.match(r"^[A-Za-z_][A-Za-z0-9_]*:?$", third or "")
              and (fourth or "").lower() in ("db", "dw", "dd")):
            # ":def 20 SNGMSG DB 13,10,..." -- the label and the DB are the
            # program's, the text is the message file's.
            here[1].append(("label", own, local, third, fourth))
        elif local is not None:
            # ':def 2 "-- More --"' -- message 2 of the utility's own class.
            # The English in the line is what the message once said; the
            # message file is what the build reads.
            here[1].append(("table", local, own, local))
        else:
            raise SystemExit("%s: cannot read line: %s" % (skeleton, line))

    if not classes:
        raise SystemExit("%s: no classes" % skeleton)
    kinds = {d[0] for _, declared in classes for d in declared}
    if len(kinds) > 1:
        raise SystemExit("%s: labelled and numbered declarations together"
                         % skeleton)
    return base, own, classes, kinds.pop() if kinds else "label"


# Three messages the skeletons ask for are not in the message file the
# release shipped.  RESTORE's is nothing but a line break, which needs no
# translating; COMMAND's two are the generic entry MSGSERV falls back to when
# a numbered class has not got the message asked for -- it retries the search
# with message 0FFFFh and one replaceable parameter, which is the number --
# and the English here is what COMMAND.SKL records beside the declaration.
ABSENT = {
    ("RESTORE", 31): ["CR,LF"],
    ("EXTEND", 999): ['"Extended error %1"'],
    ("PARSE", 999): ['"Parse error %1"'],
}


def text_of(skeleton, messages, name, number):
    """What the message file says, as a list of lines of assembler operands."""
    if name not in messages:
        raise SystemExit("%s: no class %s" % (skeleton, name))
    if number not in messages[name]:
        if (name, number) in ABSENT:
            return [plain_controls(t) for t in ABSENT[(name, number)]]
        raise SystemExit("%s: no message %d in class %s"
                         % (skeleton, number, name))
    return [plain_controls(t) for t in messages[name][number]]


def labelled_class(skeleton, messages, declared):
    """A class as declarations in the program's own address space."""
    out = []
    for _, name, number, label, keyword in declared:
        text = text_of(skeleton, messages, name, number)
        for i, part in enumerate(text):
            out.append("%-16s %-7s %s" % (label if i == 0 else "",
                                          keyword, part))
    return out


def table_class(skeleton, messages, clsname, declared, routine, identifier):
    """A class as the table MSGSERV walks, and the routine that finds it."""
    tag = "M_CL%s" % clsname
    out = [
        "; MSGSERV.ASM collects the classes by calling a routine for each; this",
        "; one answers with the address of the table below.  Whether the call",
        "; was near or far is the FARmsg service's business, so the return is",
        "; written both ways and the switch picks one.",
        "%s:" % routine,
        "%-16s %-7s %s" % ("", "PUSH", "CS"),
        "%-16s %-7s %s" % ("", "POP", "ES"),
        "%-16s %-7s %s" % ("", "MOV", "DI,%s_TABLE" % tag),
        "    if FARmsg",
        "%-16s %-7s" % ("", "RETF"),
        "    else",
        "%-16s %-7s" % ("", "RET"),
        "    end if",
        "",
        "%s_TABLE:" % tag,
        "%-16s %-7s %-24s ; the class identifier" % ("", "DB", identifier),
        "%-16s %-7s %-24s ; the version it was built for"
        % ("", "DW", "EXPECTED_VERSION"),
        "%-16s %-7s %-24s ; messages in the class"
        % ("", "DB", len(declared)),
    ]
    # The entries are named by their place in the class rather than by the
    # message number, which may be anything the program likes -- COMMAND's
    # catch-all extended error is message -1.
    for i, (_, local, name, number) in enumerate(declared, 1):
        entry = "%s_%04d" % (tag, i)
        out.append("%s:" % entry)
        out.append("%-16s %-7s %s" % ("", "DW", local))
        out.append("%-16s %-7s %s" % ("", "DW", "%s_TEXT_%04d - %s"
                                      % (tag, i, entry)))
    for i, (_, local, name, number) in enumerate(declared, 1):
        text = text_of(skeleton, messages, name, number)
        start = "%s_TEXT_%04d" % (tag, i)
        out.append("")
        out.append("%s:" % start)
        out.append("%-16s %-7s %s_END - %s - 1" % ("", "DB", start, start))
        for part in text:
            out.append("%-16s %-7s %s" % ("", "DB", part))
        out.append("%s_END:" % start)
    return out


def compile_skeleton(skeleton, messages, outdir):
    """One .SKL file, as the include files the program expects."""
    base, own, classes, kind = read_skeleton(skeleton)
    head = ["; Generated from %s by buildmsg.py.  Do not edit."
            % os.path.basename(skeleton), ""]

    written = {}
    if kind == "label":
        for name, declared in classes:
            lines = written.setdefault(name, list(head))
            lines.extend(labelled_class(skeleton, messages, declared))
    else:
        # The classes DOS numbers are reached through routines of their own,
        # and are asked for whether the skeleton declares them or not.  The
        # rest are the utility's, counted in the order they are declared.
        NUMBERED = {"1": ("M_MSGSERV_1$", "EXT_ERR_CLASS"),
                    "2": ("M_MSGSERV_2$", "PARSE_ERR_CLASS")}
        mine = 0
        for name, declared in classes:
            if name in NUMBERED:
                routine, identifier = NUMBERED[name]
            else:
                mine += 1
                routine, identifier = "M_CLS_%d$" % mine, "UTILITY_MSG_CLASS"
            written[name] = list(head) + table_class(
                skeleton, messages, name, declared, routine, identifier)
        for name, (routine, identifier) in sorted(NUMBERED.items()):
            if name not in written:
                written[name] = list(head) + table_class(
                    skeleton, messages, name, [], routine, identifier)
        control = os.path.join(outdir, "%s.CTL" % base)
        with open(control, "w") as f:
            f.write("\n".join(head + [
                "; How many classes of its own this utility has, which is how",
                "; many times SYSMSG.INC's M_BUILD_PTRS$ asks for one.",
                "M_NUM_CLS$      =       %d" % mine, ""]))
        print(control)

    for name, lines in written.items():
        path = os.path.join(outdir, "%s.CL%s" % (base, name))
        with open(path, "w") as f:
            f.write("\n".join(lines) + "\n")
        print(path)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    parse = argparse.ArgumentParser(description="compile a message skeleton")
    parse.add_argument("skeleton")
    parse.add_argument("--outdir", default=None,
                       help="where the include files go (default: beside the"
                            " skeleton)")
    parse.add_argument("--messages",
                       default=os.path.join(here, "src", "MESSAGES",
                                            "USA-MS.MSG"))
    args = parse.parse_args()
    outdir = args.outdir or os.path.dirname(os.path.abspath(args.skeleton))
    compile_skeleton(args.skeleton, read_messages(args.messages), outdir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
