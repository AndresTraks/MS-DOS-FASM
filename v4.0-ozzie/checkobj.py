#!/usr/bin/env python3
"""Hold what FASM lays down against the object file MASM made of the same
source.

    python3 checkobj.py

This is the only check there is in this tree, and it has to be, because
nothing here can be run.  bin/DISK2/BIOS holds three modules of assembler and
five object files, and BIOSOBJ.MAK makes IBMBIO.COM out of all five --

	link ibmbio ibmmtcon ibmdsk sysini sysimes,ibmbio,ibmbio/map;
	exe2bin ibmbio ibmbio.com

-- but the sources of SYSINI.OBJ and SYSIMES.OBJ were never published, and
sysini.asm would have wanted dossym.inc, devsym.inc and syscalls.inc, which
are not there either.  So there is no bootable binary to make and no machine
to boot it on.  What there is, for each module that does have a source, is the
object Microsoft shipped beside it: the same assembler text, assembled in
1984.  Held against that, byte by byte, a conversion has nowhere to hide.

What is ignored, and why that is sound:

  * every byte a FIXUPP record covers.  Those are the bytes LINK was to fill
    in -- the externals, and every reference to the second segment of the
    group, whose base only LINK knew.  MASM left them zero and they say
    nothing about the conversion.  They are 272 of IBMBIO's CODE and 244 of
    its BIOSINIT, so this is not a small allowance; what makes it safe is
    that the bytes around them are not ignored, so an instruction that moved
    or changed length still shows.

What is allowed, and counted so that it cannot grow unnoticed: the encoding
choices the two assemblers make differently, which are the same instruction
either way.  MASM writes MOV AX,BX as 8B C3, reg <- rm, where FASM writes
89 D8, rm <- reg; it writes CMP AX,40H with the accumulator's own opcode,
3D 40 00, where FASM writes 83 F8 40; and it gives a logical operation on a
word register the full word immediate, 81 /4 and four bytes, where FASM takes
the 8086's sign extended byte form, 83 /4 and three.  Only the last of those
changes the length, and there are none of it here.

Anything else stops the walk and is printed with the bytes either side of it.
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OBJ = os.path.join(HERE, "bin", "DISK2", "BIOS")

# Per module: the object MASM made, and the binary assemble.sh lays down.
MODULES = (("IBMBIO", "IBMBIO.OBJ", "IBMBIO.BIN"),)

# rm <- reg forms, whose reg <- rm twin is the opcode with bit 1 set
SWAPPABLE = {0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x88,
             0x01, 0x09, 0x11, 0x19, 0x21, 0x29, 0x31, 0x39, 0x89}
# and the accumulator's own immediate opcodes, by the /r FASM writes instead
ACCUMULATOR = {0x05: 0, 0x0d: 1, 0x15: 2, 0x1d: 3,
               0x25: 4, 0x2d: 5, 0x35: 6, 0x3d: 7}


def records(path):
    """The LNAMES, SEGDEF, LEDATA and FIXUPP of an OMF object file.

    A record is a type byte, a length word, that many bytes less the
    checksum, and the checksum.  Only the four that say what the module
    laid down are read."""
    d = open(path, "rb").read()
    i = 0
    names, segs, chunks, wild = [], [], [], set()
    cur = None
    while i < len(d):
        t = d[i]
        n = int.from_bytes(d[i+1:i+3], "little")
        body = d[i+3:i+3+n-1]
        if t == 0x96:                                   # LNAMES
            p = 0
            while p < len(body):
                l = body[p]
                names.append(body[p+1:p+1+l].decode("ascii", "replace"))
                p += 1 + l
        elif t in (0x98, 0x99):                         # SEGDEF
            acbp = body[0]
            p = 1
            if (acbp >> 5) & 7 == 0:                    # absolute: frame and offset
                p += 3
            segs.append({"name": names[body[p+2]-1],
                         "length": int.from_bytes(body[p:p+2], "little"),
                         "absolute": (acbp >> 5) & 7 == 0})
        elif t in (0xa0, 0xa1):                         # LEDATA
            cur = (body[0], int.from_bytes(body[1:3], "little"), body[3:])
            chunks.append(cur)
        elif t in (0x9c, 0x9d):                         # FIXUPP
            p = 0
            while p < len(body):
                if body[p] & 0x80:                      # a fixup, not a thread
                    w = (body[p] << 8) | body[p+1]
                    p += 2
                    off, loc = w & 0x3FF, (w >> 10) & 0xF
                    fixdat = body[p]
                    p += 1
                    if not (fixdat >> 7) & 1 and (fixdat >> 4) & 7 in (0, 1, 2):
                        p += 1                          # frame datum
                    if not (fixdat >> 3) & 1:
                        p += 1                          # target datum
                    if not (fixdat >> 2) & 1:
                        p += 2                          # target displacement
                    width = {0: 1, 1: 2, 2: 2, 3: 4, 4: 1,
                             5: 2, 9: 2, 11: 4, 13: 2}.get(loc, 2)
                    if cur:
                        for k in range(width):
                            wild.add((cur[0], cur[1] + off + k))
                else:
                    p += 2                              # a thread
        i += 3 + n
    return segs, chunks, wild


def swapped(modrm):
    """The same two registers the other way round, mod 11 only."""
    if modrm & 0xC0 != 0xC0:
        return None
    return 0xC0 | ((modrm & 7) << 3) | ((modrm >> 3) & 7)


def walk(blob, ours, seg, off, base, wild, notes):
    """Two cursors, so that an instruction FASM writes shorter does not throw
    the rest of the stream out of step.  Returns a complaint or None."""
    i, j = 0, off
    while i < len(blob):
        if (seg, off + i) in wild:
            i += 1
            j += 1
            continue
        if base + j >= len(ours):
            return "ours stops at the object's 0x%x" % (off + i)
        a, b = blob[i], ours[base + j]
        if a == b:
            i += 1
            j += 1
            continue
        if (a ^ 2) == b and b in SWAPPABLE and i + 1 < len(blob) \
                and swapped(blob[i+1]) == ours[base+j+1]:
            notes["reg <- rm, which FASM writes rm <- reg"] += 1
            i += 2
            j += 2
            continue
        if a in ACCUMULATOR and b == 0x83 and i + 2 < len(blob) \
                and ours[base+j+1] == 0xC0 + ACCUMULATOR[a] * 8 \
                and blob[i+1] == ours[base+j+2] and blob[i+2] == 0:
            notes["the accumulator's own opcode, which FASM writes 83 /r"] += 1
            i += 3
            j += 3
            continue
        if a == 0x81 and b == 0x83 and i + 3 < len(blob) \
                and blob[i+1] == ours[base+j+1] \
                and blob[i+2] == ours[base+j+2] and blob[i+3] == 0:
            notes["a word immediate, which FASM writes sign extended"] += 1
            i += 4
            j += 3
            continue
        return ("0x%04x\n    object %s\n    ours   %s"
                % (off + i, blob[max(0, i-10):i+12].hex(),
                   ours[base+j-10:base+j+12].hex()))
    return None


def main():
    import collections
    bad = 0
    for name, objfile, binfile in MODULES:
        path = os.path.join(HERE, "bin", binfile)
        if not os.path.exists(path):
            print("%s: not built; run assemble.sh" % binfile)
            bad += 1
            continue
        segs, chunks, wild = records(os.path.join(OBJ, objfile))
        ours = open(path, "rb").read()
        # The link file lays the group's segments out in the order the object
        # declares them, from one origin, which is what a group is.  An
        # absolute segment is somewhere else and lays nothing down.
        base, where = 0, {}
        for k, seg in enumerate(segs, 1):
            if seg["absolute"]:
                continue
            where[k] = base
            base += seg["length"]
        print("=== %s, against %s" % (name, objfile))
        for k, seg in enumerate(segs, 1):
            if seg["absolute"]:
                print("    %-10s %5d bytes, somewhere else: %s"
                      % (seg["name"], seg["length"],
                         "nothing laid down, as a virtual block lays nothing"))
        if len(ours) != base:
            print("    the object's segments come to %d bytes and ours to %d"
                  % (base, len(ours)))
            bad += 1
        notes = collections.Counter()
        for seg, off, blob in chunks:
            if seg not in where:
                continue
            complaint = walk(blob, ours, seg, off, where[seg], wild, notes)
            print("    %-10s 0x%04x %5d bytes  %s"
                  % (segs[seg-1]["name"], off, len(blob),
                     "the same" if complaint is None else "DIFFERS at " + complaint))
            if complaint is not None:
                bad += 1
        for what, n in sorted(notes.items()):
            print("    %5d  %s" % (n, what))
        print("    %5d  bytes left to LINK and not compared"
              % len([w for w in wild if w[0] in where]))
    print("\n%s" % ("something differs" if bad else
                    "every module is the object's own bytes"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
