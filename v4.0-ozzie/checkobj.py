#!/usr/bin/env python3
"""Hold what FASM lays down against the object file MASM made of the same
source.

    python3 checkobj.py

bin/DISK2/BIOS holds three modules of assembler and five object files, and
BIOSOBJ.MAK makes IBMBIO.COM out of all five --

	link ibmbio ibmmtcon ibmdsk sysini sysimes,ibmbio,ibmbio/map;
	exe2bin ibmbio ibmbio.com

-- and the sources of SYSINI.OBJ and SYSIMES.OBJ were never published.  Beside
each module that does have one, though, is the object Microsoft shipped: the
same assembler text, assembled in 1984.  Held against that, byte by byte, a
conversion has nowhere to hide, which is what this does.

It was for a while the only check this tree had.  It is not any more:
sysinit.py resolves the two objects nobody has the source of, src/BIOSLNK.ASM
lays all five down where LINK put them, and tests/boot.sh starts a machine
from the result.  The two checks answer different questions -- this one asks
whether a module is what MASM made of it, the boot asks whether the whole
thing runs -- and this one is the sharper of them by far: it reads every
byte, where a boot only shows that nothing it happened to need was broken.

The bytes a FIXUPP record covers are compared differently, because MASM left
them zero: they are the bytes LINK was to fill in -- the externals, and every
reference to the module's own data, whose offset in the finished CODE depends
on how much of the other modules went in front of it.  They are a fifth of
each module, so they are far too many to pass over: a reference to the wrong
variable would be invisible.  What they are held against instead is the
FIXUPP record itself, which says which segment or external the value points
into and the offset inside it -- enough to work out what this build should
have written there, since this build knows where it put its segments and the
link file declares every external to be zero.  What is left over is said at
the end of each module, and it comes to three things: a paragraph LINK was to
assign, a pointer's segment word, and a word immediate the two assemblers
wrote at different widths.

What is allowed, and counted so that it cannot grow unnoticed: the encoding
choices the two assemblers make differently, which are the same instruction
either way.  MASM writes MOV AX,BX as 8B C3, reg <- rm, where FASM writes
89 D8, rm <- reg; it writes CMP AX,40H with the accumulator's own opcode,
3D 40 00, where FASM writes 83 F8 40; it gives a logical operation on a word
register the full word immediate, 81 /4 and four bytes, where FASM takes the
8086's sign extended byte form, 83 /4 and three; and it leaves a NOP where it
shortened a forward jump of its own, having reserved three bytes for it and
then found the target within reach of two.

The last two of those change the length, and the length changing is what
makes the rest of the walk hard: an instruction that came out shorter moves
everything after it, so the displacement of every branch across it differs
too.  Those are checked rather than passed over.  A relative branch counts
from the instruction after it, so the two displacements have to differ by
exactly the number of bytes the object has and ours has not between the
branch and where it lands -- which is arithmetic, and needs nothing said
about which instruction it is.  The earlier attempt to read the instruction
went wrong twice: a byte walk cannot tell an opcode from an operand, and
every E3 was read as a JCXZ where D1 E3 is SHL BX,1.

Anything else stops the walk and is printed with the bytes either side of it.
And whatever is allowed, the arithmetic has to come out: the object's own
segment lengths less what the allowances account for is what our binary must
weigh, and it is said so at the end of each module.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OBJ = os.path.join(HERE, "bin", "DISK2", "BIOS")

# Per module: the object MASM made, and the binary assemble.sh lays down.
MODULES = (("IBMBIO", "IBMBIO.OBJ", "IBMBIO.BIN"),
           ("IBMMTCON", "IBMMTCON.OBJ", "IBMMTCON.BIN"),
           ("IBMDSK", "IBMDSK.OBJ", "IBMDSK.BIN"))

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


def iterated(body, p, runs=None, at=0):
    """One iterated data block of a LIDATA record, flattened, and where the
    next one starts.

    A block is a repeat count, a count of the blocks inside it, and then
    either -- the inner count being zero -- a byte count and that many bytes,
    or that many blocks of the same shape again.  The whole of it is laid
    down as many times as the repeat count says.

    RUNS, if given, collects (where the bytes are in the record, where they
    land, how many) for each run of literal bytes, and AT is where this
    block's output begins.  A fixup in a LIDATA record is at an offset into
    the record and not into what the record lays down, so that is the only
    way to know which byte it means -- see records()."""
    count = int.from_bytes(body[p:p+2], "little")
    blocks = int.from_bytes(body[p+2:p+4], "little")
    p += 4
    if blocks == 0:
        n = body[p]
        p += 1
        if runs is not None:
            runs.append((p, at, n))
        out = bytes(body[p:p+n])
        p += n
    else:
        out = b""
        for _ in range(blocks):
            part, p = iterated(body, p, runs, at + len(out))
            out += part
    return out * count, p


def records(path):
    """The LNAMES, SEGDEF, LEDATA, LIDATA and FIXUPP of an OMF object file.

    A record is a type byte, a length word, that many bytes less the
    checksum, and the checksum.  Only the five that say what the module
    laid down are read."""
    d = open(path, "rb").read()
    i = 0
    names, segs, chunks, wild, fixups = [], [], [], set(), []
    cur, curmap = None, None
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
            p, frame = 1, None
            if (acbp >> 5) & 7 == 0:                    # absolute: frame and offset
                frame = int.from_bytes(body[1:3], "little")
                p += 3
            segs.append({"name": names[body[p+2]-1],
                         "length": int.from_bytes(body[p:p+2], "little"),
                         "absolute": (acbp >> 5) & 7 == 0,
                         "frame": frame})
        elif t in (0xa0, 0xa1):                         # LEDATA
            cur = (body[0], int.from_bytes(body[1:3], "little"), body[3:])
            curmap = None                               # the offsets are plain
            chunks.append(cur)
        elif t in (0xa2, 0xa3):                         # LIDATA
            # Repeated data, which MASM wrote for a structure instance:
            # IBMDSK declares six of them -- the two drivers' state and the
            # four per-drive tables -- and the defaults in the declaration
            # are laid down field by field, each field one block.  Read as
            # nothing at all the first 166 bytes of its CODE went uncompared.
            data, p, runs = b"", 3, []
            while p < len(body):
                part, p = iterated(body, p, runs, len(data))
                data += part
            # Where a fixup in this record would land.  Its offset counts the
            # bytes of the record, headers and all, not the bytes the record
            # lays down, so the two have to be matched up run by run.  None of
            # the three modules fixes up iterated data; SYSINI does, and
            # sysinit.py reads these same records.
            curmap = {}
            for raw, laid, length in runs:
                for k in range(length):
                    curmap[raw - 3 + k] = laid + k
            cur = (body[0], int.from_bytes(body[1:3], "little"), data)
            chunks.append(cur)
        elif t in (0x9c, 0x9d):                         # FIXUPP
            p = 0
            while p < len(body):
                if body[p] & 0x80:                      # a fixup, not a thread
                    w = (body[p] << 8) | body[p+1]
                    p += 2
                    off, loc = w & 0x3FF, (w >> 10) & 0xF
                    relative = (w >> 14) & 1            # or self relative
                    fixdat = body[p]
                    p += 1
                    if not (fixdat >> 7) & 1 and (fixdat >> 4) & 7 in (0, 1, 2):
                        p = after_index(body, p)        # frame datum
                    index = None
                    if not (fixdat >> 3) & 1:
                        index = body[p] & 0x7F if not body[p] & 0x80 else \
                            ((body[p] & 0x7F) << 8) | body[p+1]
                        p = after_index(body, p)        # target datum
                    disp = 0
                    if not (fixdat >> 2) & 1:
                        disp = int.from_bytes(body[p:p+2], "little")
                        p += 2                          # target displacement
                    width = {0: 1, 1: 2, 2: 2, 3: 4, 4: 1,
                             5: 2, 9: 2, 11: 4, 13: 2}.get(loc, 2)
                    if cur:
                        at = off if curmap is None else curmap[off]
                        for k in range(width):
                            wild.add((cur[0], cur[1] + at + k))
                        # What LINK was told to put there, which is more than
                        # enough to work out what this build should have.
                        fixups.append((cur[0], cur[1] + at, loc, relative,
                                       fixdat & 3, index, disp))
                else:                                   # a thread
                    method = (body[p] >> 2) & 7
                    p += 1
                    if method <= 2:
                        p = after_index(body, p)
        i += 3 + n
    return segs, chunks, wild, fixups


def swapped(modrm):
    """The same two registers the other way round, mod 11 only."""
    if modrm & 0xC0 != 0xC0:
        return None
    return 0xC0 | ((modrm & 7) << 3) | ((modrm >> 3) & 7)


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


def extras(blob, ours, seg, off, base, wild, drift):
    """Where the object has bytes ours has not, by offset in the object, and
    which of its bytes belong to an instruction the two assemblers encoded
    differently.

    There are two ways that happens and explain() knows both of them: a NOP
    MASM left where it shortened its own jump, and a word immediate FASM
    writes sign extended.  Found here in a walk of its own, ahead of the one
    that compares, because a jump reaches forward over them and the walk
    cannot know what it has not read yet.  Over the whole of a segment at
    once, chunk after chunk, because a branch reaches across the boundary
    between two of them as readily: one of IBMDSK's reaches 117 bytes back
    into the chunk before.  A difference that is not one of those is stepped
    over a byte at a time, which is what the comparing walk will have to
    account for: its value is that walk's business and its length is one byte
    either way.

    The re-encoded bytes are wanted for a different reason.  Where MASM wrote
    ADD AX,imm with the accumulator's own opcode and FASM wrote 83 /0, the
    immediate is a word in one and a sign extended byte in the other, so a
    fixup that lands in it has nothing in our copy to be held against."""
    found, recoded, i, j = {}, set(), 0, off + drift
    while i < len(blob):
        step = explain(blob, ours, seg, off, base, wild, i, j)
        if step is None:
            i, j = i + 1, j + 1
            continue
        if step != (1, 1):
            recoded.update(range(off + i, off + i + step[0]))
        if step[0] != step[1]:
            found[off + i] = step[0] - step[1]
        i += step[0]
        j += step[1]
    return found, recoded, j - off - i


def displaced(blob, ours, off, base, i, j, extra):
    """Whether the byte the walk has stopped on is a branch displacement that
    moved, and the width of it; None if the arithmetic does not come out.

    This is the one difference left once the encodings are allowed for, and
    it has to be, because a shortened instruction moves everything after it:
    a jump across one comes out that much shorter.  It is checked rather than
    guessed at.  A relative branch counts from the instruction after it, so
    the two displacements must differ by exactly the number of bytes the
    object has and ours has not between the branch and where it lands --
    which extras() has worked out.  A byte that differs for any other reason
    would have to agree with that sum by accident.

    The earlier attempt to read the instruction instead went wrong twice: a
    byte walk cannot say which byte is an opcode and which an operand, and
    every E3 was read as a JCXZ where D1 E3 is SHL BX,1.  This asks nothing
    about the instruction."""
    for width in (1, 2):
        if i + width > len(blob) or base + j + width > len(ours):
            continue
        a = int.from_bytes(blob[i:i+width], "little", signed=True)
        b = int.from_bytes(ours[base+j:base+j+width], "little", signed=True)
        here = off + i + width                  # the instruction after it
        lo, hi = (here, here + a) if a >= 0 else (here + a, here)
        gap = sum(n for at, n in extra.items() if lo <= at < hi)
        if gap and a - b == (gap if a >= 0 else -gap):
            return width
    return None


def walk(blob, ours, seg, off, base, wild, notes, drift, extra):
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
        width = displaced(blob, ours, off, base, i, j, extra)
        if width is not None:
            notes["a branch displacement, shorter by the bytes it jumps "
                  "over"] += 1
            i += width
            j += width
            continue
        return ("0x%04x\n    object %s\n    ours   %s"
                % (off + i, blob[max(0, i-10):i+12].hex(),
                   ours[base+j-10:base+j+12].hex())), j - off - i
    return None, j - off - i


def resolved(fixups, bases, extra, recoded, ours, segs):
    """The bytes LINK was to fill in, held against what FASM put there.

    These are the bytes the walk has to ignore, and they are a fifth of the
    module: MASM left a zero wherever the value was not its to know -- an
    external, or a reference to the module's own data, whose offset in the
    finished CODE depends on how much of IBMBIO and IBMMTCON went in front of
    it.  Ignored, a reference to the wrong variable would not show at all,
    which is the one hole left in the comparison.

    It need not be a hole, because the FIXUPP record says what LINK was to
    write: which segment or external the value points into and the offset
    inside it.  This build knows where it put that segment, and the externals
    are zero by declaration in the link file, so the value FASM should have
    written can be worked out and compared.  What is left out is only what
    nobody here can know: a segment's own paragraph, which is the base LINK
    would have assigned.

    An offset in the object is an offset in our copy less whatever came out
    shorter before it, which is what extra holds.

    An absolute segment is a window on somebody else's memory -- the ROM's
    data at 40H, the display buffers at B000H and B800H -- and its paragraph
    is in the source rather than LINK's to decide, so a reference into one is
    checked as well: the offset against the virtual block the conversion
    makes of it, which starts at nothing as the segment's own offsets do, and
    the paragraph against the number the SEGMENT AT gave."""
    def ourat(seg, off):
        return bases[seg] + off - sum(n for at, n in extra[seg].items()
                                      if at < off)
    import collections
    checked, left, complaints = 0, collections.Counter(), []
    for seg, off, loc, relative, method, index, disp in fixups:
        if seg not in bases:
            left["in a segment that lays nothing down"] += 2
            continue
        if any(off + k in recoded[seg] for k in range(2)):
            left["inside an instruction the two wrote differently"] += 2
            continue
        into = segs[index-1] if method == 0 else None
        if loc == 2:                        # a paragraph, not an offset
            if into is None or not into["absolute"]:
                left["a paragraph LINK was to assign"] += 2
                continue
            # A window on memory that is already there, and the SEGMENT AT
            # said where: RomData = 40H.
            target = into["frame"]
        elif loc not in (1, 3):
            left["a kind of fixup this does not read"] += 2
            continue
        elif method == 0 and index in bases:            # this module's own
            if disp > into["length"]:
                left["a target past the end of its segment"] += 2
                continue                    # which the one WORD without PTR
                                            #   is, and MASM meant no such
                                            #   thing
            target = ourat(index, disp)
        elif method == 0 and into["absolute"]:
            # An offset in the virtual block the conversion makes of it,
            # which starts at nothing as the segment's own offsets do.
            target = disp
        elif method == 2:                   # an external, which is zero here
            target = disp
        else:
            left["a target of a kind this does not read"] += 2
            continue
        if loc == 3:
            left["a pointer's segment word"] += 2
        at = ourat(seg, off)
        want = (target if relative else target - (at + 2)) & 0xFFFF
        got = int.from_bytes(ours[at:at+2], "little")
        checked += 1
        if got != want:
            complaints.append("0x%04x: LINK was to write 0x%04x, FASM wrote "
                              "0x%04x" % (off, want, got))
    return checked, left, complaints


def main():
    import collections
    bad = 0
    for name, objfile, binfile in MODULES:
        path = os.path.join(HERE, "bin", binfile)
        if not os.path.exists(path):
            print("%s: not built; run assemble.sh" % binfile)
            bad += 1
            continue
        segs, chunks, wild, fixups = records(os.path.join(OBJ, objfile))
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
            if not seg["absolute"]:
                continue
            # A window on memory that is already there, which the conversion
            # makes a virtual block of: our build lays nothing down there,
            # and the object mostly does not either.  Mostly: MASM gives a
            # DW ? a word of zero in the object where it gives n DUP (?)
            # nothing at all, so IBMMTCON's ROMDATA has 18 bytes in it --
            # bytes LINK would have written into the ROM's own data area.
            had = sum(len(b) for g, o, b in chunks if g == k)
            print("    %-10s %5d bytes, somewhere else: %s"
                  % (seg["name"], seg["length"],
                     "nothing laid down, as a virtual block lays nothing"
                     if not had else
                     "%d bytes the object lays down there and ours does not, "
                     "a virtual block laying nothing" % had))
        expected = base
        notes = collections.Counter()
        running = 0
        bases, extras_of, recoded_of = {}, {}, {}
        for k in sorted(where):
            bases[k] = where[k] + running
            # Where the object has bytes ours has not, over the whole of this
            # segment before any of it is compared: the walk that compares
            # needs them to hand, and a branch reaches forward.
            extra, mixed, drift = {}, set(), 0
            for seg, off, blob in chunks:
                if seg != k:
                    continue
                found, these, drift = extras(blob, ours, seg, off, bases[k],
                                             wild, drift)
                extra.update(found)
                mixed |= these
            extras_of[k], recoded_of[k] = extra, mixed
            drift = 0
            for seg, off, blob in chunks:
                if seg != k:
                    continue
                complaint, drift = walk(blob, ours, seg, off, bases[k],
                                        wild, notes, drift, extra)
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
        checked, left, complaints = resolved(
            fixups, bases, extras_of, recoded_of, ours, segs)
        print("    %5d  bytes left to LINK, held against what the FIXUPP "
              "record says LINK was to write" % (checked * 2))
        for what, n in sorted(left.items()):
            print("    %5d  and not held against anything: %s" % (n, what))
        for complaint in complaints:
            print("           %s" % complaint)
        bad += len(complaints)
    print("\n%s" % ("something differs" if bad else
                    "every module is the object's own bytes"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
