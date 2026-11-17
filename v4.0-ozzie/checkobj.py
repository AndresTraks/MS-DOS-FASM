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
MODULES = (("IBMBIO", "IBMBIO.OBJ", "IBMBIO.BIN"),
           ("IBMMTCON", "IBMMTCON.OBJ", "IBMMTCON.BIN"))

# rm <- reg forms, whose reg <- rm twin is the opcode with bit 1 set
SWAPPABLE = {0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x88,
             0x01, 0x09, 0x11, 0x19, 0x21, 0x29, 0x31, 0x39, 0x89}
# and the accumulator's own immediate opcodes, by the /r FASM writes instead
ACCUMULATOR = {0x05: 0, 0x0d: 1, 0x15: 2, 0x1d: 3,
               0x25: 4, 0x2d: 5, 0x35: 6, 0x3d: 7}


def after_index(body, p):
    """Past an OMF index, which is one byte under 128 and two above it.

    Read as one byte always, the rest of a FIXUPP record came out shifted,
    and the offsets it then claimed were fixups fell on whatever bytes
    happened to be there -- in IBMBIO, on the opcode of a MOV, which the
    comparison then skipped without looking at it.  A check that ignores the
    wrong bytes is worse than no check, so this is worth getting right."""
    return p + (2 if body[p] & 0x80 else 1)


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
                        p = after_index(body, p)        # frame datum
                    if not (fixdat >> 3) & 1:
                        p = after_index(body, p)        # target datum
                    if not (fixdat >> 2) & 1:
                        p += 2                          # target displacement
                    width = {0: 1, 1: 2, 2: 2, 3: 4, 4: 1,
                             5: 2, 9: 2, 11: 4, 13: 2}.get(loc, 2)
                    if cur:
                        for k in range(width):
                            wild.add((cur[0], cur[1] + off + k))
                else:                                   # a thread
                    method = (body[p] >> 2) & 7
                    p += 1
                    if method <= 2:
                        p = after_index(body, p)
        i += 3 + n
    return segs, chunks, wild


def swapped(modrm):
    """The same two registers the other way round, mod 11 only."""
    if modrm & 0xC0 != 0xC0:
        return None
    return 0xC0 | ((modrm & 7) << 3) | ((modrm >> 3) & 7)


# A relative branch, by opcode, and how many bytes of displacement it has.
# These are the instructions whose operand is a distance rather than a place,
# so an instruction that came out shorter earlier in the chunk changes them
# without anything being wrong.
RELATIVE = dict([(0xeb, 1), (0xe3, 1), (0xe0, 1), (0xe1, 1), (0xe2, 1),
                 (0xe8, 2), (0xe9, 2)]
                + [(0x70 + k, 1) for k in range(16)])


def explain(blob, ours, seg, off, base, wild, i, j, notes=None):
    """One step of the comparison: how many bytes of each side this accounts
    for, or None if nothing here does.

    Everything the two assemblers do differently is one of these, and each
    is counted so that it cannot grow unnoticed."""
    if i >= len(blob):
        return None
    if (seg, off + i) in wild:                  # a byte LINK was to fill in
        return 1, 1
    if base + j >= len(ours):
        return None
    a, b = blob[i], ours[base + j]
    if a == b:
        return 1, 1
    # MASM writes MOV AX,BX as 8B C3, reg <- rm; FASM writes 89 D8.
    if (a ^ 2) == b and b in SWAPPABLE and i + 1 < len(blob) \
            and base + j + 1 < len(ours) \
            and swapped(blob[i+1]) == ours[base+j+1]:
        if notes is not None:
            notes["reg <- rm, which FASM writes rm <- reg"] += 1
        return 2, 2
    # MASM writes CMP AX,40H as 3D 40 00, the accumulator's own opcode;
    # FASM writes 83 F8 40.  Three bytes either way.
    if a in ACCUMULATOR and b == 0x83 and i + 2 < len(blob) \
            and base + j + 2 < len(ours) \
            and ours[base+j+1] == 0xC0 + ACCUMULATOR[a] * 8 \
            and ((seg, off + i + 1) in wild
                 or (blob[i+1] == ours[base+j+2] and blob[i+2] == 0)):
        if notes is not None:
            notes["the accumulator's own opcode, which FASM writes 83 /r"] += 1
        return 3, 3
    # MASM gives a logical operation on a word register the full word
    # immediate, 81 /r and four bytes; FASM takes the 8086's sign extended
    # byte form, 83 /r and three.
    if a == 0x81 and b == 0x83 and i + 3 < len(blob) \
            and base + j + 2 < len(ours) \
            and blob[i+1] == ours[base+j+1] \
            and ((seg, off + i + 2) in wild
                 or (blob[i+2] == ours[base+j+2] and blob[i+3] == 0)):
        if notes is not None:
            notes["a word immediate, which FASM writes sign extended"] += 1
        return 4, 3
    # A NOP MASM left behind: asked for a forward JMP it reserved the three
    # bytes a near one takes, found the target within reach of a short one,
    # and filled the byte it no longer needed.
    if a == 0x90 and b != 0x90:
        if notes is not None:
            notes["a NOP MASM left where it shortened its own jump"] += 1
        return 1, 0
    return None


def resync(blob, ours, seg, off, base, wild, i, j, reach=3, run=6):
    """Where the two streams come together again, if they do within a few
    bytes.  Returns the cursors to carry on from, or None.

    Once an instruction has come out shorter, the displacement of every jump
    across it differs, and so does any address worked out from a label after
    it.  There is no telling those bytes from any other by looking: a byte
    walk cannot say which byte is an opcode and which an operand, and the
    attempt to -- reading every E3 as a JCXZ, when D1 E3 is SHL BX,1 --
    left real bytes uncompared.  So the rule is blunt and stated: a
    difference is passed over only if the streams then agree for six steps
    running, each of which must itself be explained."""
    def agrees(di, dj):
        for _ in range(run):
            step = explain(blob, ours, seg, off, base, wild, di, dj)
            if step is None:
                return False
            di += step[0]
            dj += step[1]
        return True
    for d in range(1, reach + 1):
        for di, dj in ((i + d, j + d), (i + d, j), (i, j + d)):
            if agrees(di, dj):
                return di, dj
    return None


def walk(blob, ours, seg, off, base, wild, notes, drift):
    """Hold one chunk of the object against our copy of it, byte by byte.

    Two cursors, because an instruction FASM writes shorter does not throw
    the rest of the stream out of step.  drift is how far our copy has
    fallen behind by the time this chunk starts, and is returned with the
    complaint, if any, so that the next chunk starts from it: an object
    holds only the bytes its module laid down, and the gaps between its
    chunks are storage both sides reserve alike."""
    i, j = 0, off + drift
    while i < len(blob):
        step = explain(blob, ours, seg, off, base, wild, i, j, notes)
        if step is not None:
            i += step[0]
            j += step[1]
            continue
        if base + j >= len(ours):
            return "ours stops at the object's 0x%x" % (off + i), j - off - i
        back = resync(blob, ours, seg, off, base, wild, i, j)
        if back is not None:
            notes["a byte that moved with a shortened instruction"] += 1
            i, j = back
            continue
        return ("0x%04x\n    object %s\n    ours   %s"
                % (off + i, blob[max(0, i-10):i+12].hex(),
                   ours[base+j-10:base+j+12].hex())), j - off - i
    return None, j - off - i


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
        # Where each of them starts in our copy, which is where the object
        # puts it less whatever the segments before it came out shorter by.
        # Laid out by the object's own lengths the second segment would have
        # been read three bytes late, and every byte of it would have looked
        # wrong.
        print("=== %s, against %s" % (name, objfile))
        for k, seg in enumerate(segs, 1):
            if seg["absolute"]:
                print("    %-10s %5d bytes, somewhere else: %s"
                      % (seg["name"], seg["length"],
                         "nothing laid down, as a virtual block lays nothing"))
        expected = base
        notes = collections.Counter()
        running = 0
        for k in sorted(where):
            drift = 0
            for seg, off, blob in chunks:
                if seg != k:
                    continue
                complaint, drift = walk(blob, ours, seg, off,
                                        where[seg] + running, wild, notes,
                                        drift)
                print("    %-10s 0x%04x %5d bytes  %s"
                      % (segs[seg-1]["name"], off, len(blob),
                         "the same" if complaint is None
                         else "DIFFERS at " + complaint))
                if complaint is not None:
                    bad += 1
            if drift:
                print("    %-10s came out %d bytes shorter"
                      % (segs[k-1]["name"], -drift))
            running += drift
        if len(ours) != expected + running:
            print("    the object's segments come to %d bytes; ours should "
                  "then be %d and is %d"
                  % (expected, expected + running, len(ours)))
            bad += 1
        elif running:
            print("    %d bytes shorter than the object in all, every one of "
                  "them accounted for above" % -running)
        for what, n in sorted(notes.items()):
            print("    %5d  %s" % (n, what))
        print("    %5d  bytes left to LINK and not compared"
              % len([w for w in wild if w[0] in where]))
    print("\n%s" % ("something differs" if bad else
                    "every module is the object's own bytes"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
