#!/usr/bin/env python3
#
# The message compiler.  Every program in this release gets its text from
# MESSAGES/USA-MS.MSG rather than from its own source: the source names a
# message, and BUILDMSG, which Microsoft shipped as a binary in src/TOOLS and
# not as source, wrote the include file that holds it.  Nothing can be
# assembled without that step, so this is it again, in Python.
#
# A program declares what it needs in a skeleton file, <program>.SKL:
#
#   :class 1                        the class the messages below belong to
#   :use 001 BOOT SYSMSG            message 001 of class BOOT, as SYSMSG
#   :def 20 SNGMSG DB 13,10,"..."   a message this program defines itself
#   :end
#
# and the message file holds a class per utility, each message on a line of
# its own:
#
#   BOOT     58c1 0001                       class, offset, number of messages
#   0001 U 0000 13,10,"Non-System disk ..."  number, state, flags, the text
#
# The text is already a list of assembler operands, so it comes out as it
# went in, bar the symbolic control characters -- CR, LF and the rest, which
# SYSMSG.INC defines and the programs that do not include it would not
# resolve.  Those are written as numbers.
#
# Two output shapes, because the programs come in two kinds.  A ":use" or
# ":def" line that names a label, as BOOT.SKL does above, is one declaration
# in the program's own address space, and that is all the boot sector and the
# BIOS want of the message file.  The utilities instead call the message
# retriever in INC/MSGSERV.ASM, which looks a message up by number at run
# time, and they want the class tables it walks; that shape is not written
# yet -- see MSBOOT.ASM, which is the only program converted so far.

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


def read_messages(path):
    """The message file, as {class: {number: [text line, ...]}}."""
    classes = {}
    current = None
    message = None
    with open(path, "r", encoding="cp437") as f:
        lines = [l.rstrip("\r\n") for l in f]
    for line in lines[1:]:                      # line 1 is the file's own count
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


def numbers_for_controls(text):
    """CR and LF and the rest as numbers, leaving the quoted text alone."""
    out = []
    for part in re.split(r'("[^"]*"|\'[^\']*\')', text):
        if part[:1] in '"\'':
            out.append(part)
        else:
            out.append(re.sub(r"\b[A-Z]+\b",
                              lambda m: str(CONTROLS[m.group(0)])
                              if m.group(0) in CONTROLS else m.group(0),
                              part))
    return "".join(out)


def declaration(label, directive, text):
    """One labelled message, as the program declares it."""
    lines = []
    for i, part in enumerate(text):
        if i == 0:
            lines.append("%-12s %-7s %s" % (label, directive, part))
        else:
            lines.append("%-12s %-7s %s" % ("", directive, part))
    return lines


def compile_skeleton(skeleton, messages, out):
    """A .SKL file, as the include file the program expects."""
    lines = ["; Generated from %s by buildmsg.py.  Do not edit."
             % os.path.basename(skeleton), ""]
    with open(skeleton, "r", encoding="cp437") as f:
        source = [l.rstrip("\r\n") for l in f]

    for line in source:
        line = line.rstrip()
        if not line.startswith(":"):
            continue
        # Trailing ";AN000;" change marks are the release's, not ours.
        body = re.sub(r"\s*;.*$", "", line[1:])
        word = body.split()
        if not word:
            continue
        directive = word[0].lower()

        if directive in ("end", "util", "class"):
            continue

        if directive == "use":
            if len(word) < 3:
                raise SystemExit("%s: no label on: %s" % (skeleton, line))
            number = int(word[1])
            if len(word) == 3:
                # COMMON1 and the like: class and number run together, which
                # is the retriever's shape, not a label.
                raise SystemExit("%s: retriever classes not written yet: %s"
                                 % (skeleton, line))
            name, label = word[2].upper(), word[3]
            if name not in messages:
                raise SystemExit("%s: no class %s" % (skeleton, name))
            if number not in messages[name]:
                raise SystemExit("%s: no message %d in class %s"
                                 % (skeleton, number, name))
            text = [numbers_for_controls(t) for t in messages[name][number]]
            lines += declaration(label, "db", text)
            continue

        if directive == "def":
            # The program writes the declaration itself; everything after the
            # number is assembler.
            lines.append(re.sub(r"^:def\s+\S+\s+", "", line))
            continue

        raise SystemExit("%s: unknown directive: %s" % (skeleton, line))

    with open(out, "w") as f:
        f.write("\n".join(lines) + "\n")


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    parse = argparse.ArgumentParser(description="compile a message skeleton")
    parse.add_argument("skeleton")
    parse.add_argument("output")
    parse.add_argument("--messages",
                       default=os.path.join(here, "src", "MESSAGES",
                                            "USA-MS.MSG"))
    args = parse.parse_args()
    compile_skeleton(args.skeleton, read_messages(args.messages), args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
