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
# Two output shapes, because the programs come in two kinds.  A :use or :def
# line that names a label, as above, is one declaration in the program's own
# address space, and that is all the boot sector and the BIOS want of the
# message file.  The utilities instead call the message retriever in
# INC/MSGSERV.ASM, which looks a message up by number at run time, and they
# want the class tables it walks; that shape is not written yet.

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
DECLARATION = re.compile(r"^:(use|def)\s+(\d+)\s+(\S+)(?:\s+(\S+))?\s*(.*)$",
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


def compile_skeleton(skeleton, messages, outdir):
    """One .SKL file, as the include file per class the program expects."""
    base = os.path.basename(skeleton).rsplit(".", 1)[0].upper()
    with open(skeleton, "r", encoding="cp437") as f:
        source = [l.rstrip("\r\n") for l in f]

    own = base                        # the class this program's messages are in
    for line in source:
        named = re.match(r"^:util\s+(\S+)", line, re.I)
        if named:
            own = named.group(1).upper()

    written = {}
    out = None

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
            name = word[1].upper()
            out = written.setdefault(name, [
                "; Generated from %s by buildmsg.py.  Do not edit."
                % os.path.basename(skeleton), ""])
            continue

        found = DECLARATION.match(line)
        if not found or directive not in ("use", "def"):
            raise SystemExit("%s: cannot read line: %s" % (skeleton, line))
        if out is None:
            raise SystemExit("%s: no class before: %s" % (skeleton, line))

        number = int(found.group(2))
        if directive == "use":
            # ":use 001 BOOT SYSMSG" -- message 001 of class BOOT, declared
            # here under the name the program calls it by.
            name, label, keyword = found.group(3).upper(), found.group(4), "db"
            if label is None:
                raise SystemExit("%s: retriever classes not written yet: %s"
                                 % (skeleton, line))
        else:
            # ":def 20 SNGMSG DB 13,10,..." -- the label and the DB are the
            # program's, the text is the message file's.
            name, label = own, found.group(3)
            keyword = found.group(4) or "db"
            if label.startswith(("\"", "'")):
                raise SystemExit("%s: retriever classes not written yet: %s"
                                 % (skeleton, line))

        if name not in messages:
            raise SystemExit("%s: no class %s" % (skeleton, name))
        if number not in messages[name]:
            raise SystemExit("%s: no message %d in class %s"
                             % (skeleton, number, name))

        text = [plain_controls(t) for t in messages[name][number]]
        for i, part in enumerate(text):
            out.append("%-16s %-7s %s" % (label if i == 0 else "",
                                          keyword, part))

    if not written:
        raise SystemExit("%s: no classes" % skeleton)
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
