"""SYSINITSEG: the part of the BIOS that was shipped without its source.

BIOSOBJ.MAK links five objects and bin/DISK2/BIOS has sources for three.  The
other two, SYSINI.OBJ and SYSIMES.OBJ, are the SYSINIT program -- the code
that runs once at the end of the boot, sizes memory, reads CONFIG.SYS, loads
MSDOS.SYS and starts COMMAND.COM -- and the READ_ME says plainly that no
source is supplied.  Nothing can be converted here, so the object file has to
serve as the source.

That it can serve is the useful discovery.  The two objects are closed: the
only names SYSINI imports are the seven messages SYSIMES exports, and the only
names they export are the eight that IBMBIO imports.  So SYSINITSEG can be
laid down without knowing anything about the three converted modules, and the
one thing it does need from them -- the paragraph its own segment ends up at --
is a number this writes in wherever LINK was told to.

What LINK did with the objects is what this does:

  * SYSINITSEG is 2404 bytes of SYSINI and then 135 of SYSIMES, which is where
    the seven messages land, and the 256 bytes SYSINI leaves unwritten at the
    front of it stay zero.
  * Every FIXUPP record is resolved.  A self relative one becomes the
    displacement from the end of its own field; a segment relative one becomes
    an offset in whichever segment its frame names; and the three pointers
    become an offset and the segment's paragraph.
  * The seven EXTDEF names are looked up in SYSIMES's PUBDEF records, so a
    reference to a message resolves to where the message actually is.

DOSFRAME is the one thing LINK dropped.  SYSINI declares it SEGMENT AT 0 --
the bottom of memory, where the interrupt vectors are -- and writes seven
small pieces of data into it, which is 31 bytes at absolute 0:0.  That is
below the image, so none of it is in IBMBIO.COM and none of it is here.
Nothing was lost with it: all 31 of those bytes are zero, MASM having laid
the vector table's own shape down to name the words SYSINIT writes through,
and the names survive as fixups, which this does resolve.

Run it to check the result rather than write it: with no arguments it resolves
the two objects at the paragraph the shipped build used and holds what comes
out against bin/DISK1/IBMBIO.COM, the one place the answer is known.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OBJ = os.path.join(HERE, "bin", "DISK2", "BIOS")

sys.path.insert(0, HERE)        # so that -I finds the one next to this
import checkobj                 # noqa: E402

SEGSIZE = 0x964                 # SYSINITSEG, as SYSINI's SEGDEF declares it
SHIPPED = 0x2660                # where LINK put it, and what IBMBIO.COM shows
PARAGRAPH = 0x2D6               # 70h + 2660h/16: the segment it was bound to


def index(body, p):
    """An OMF index and where it ends: one byte under 128 and two above it."""
    if body[p] & 0x80:
        return ((body[p] & 0x7F) << 8) | body[p+1], p + 2
    return body[p], p + 1


def publics(path):
    """The PUBDEF records of an object: a name and its offset."""
    d = open(path, "rb").read()
    out, i = {}, 0
    while i < len(d):
        t, n = d[i], int.from_bytes(d[i+1:i+3], "little")
        body = d[i+3:i+3+n-1]
        if t in (0x90, 0x91):
            p = 0
            g, p = index(body, p)
            s, p = index(body, p)
            if g and not s:
                p += 2                          # a frame number, for an
            while p < len(body):                #  absolute group
                l = body[p]
                name = body[p+1:p+1+l].decode("ascii", "replace")
                p += 1 + l
                out[name] = int.from_bytes(body[p:p+2], "little")
                p += 2
                _, p = index(body, p)           # the type index
        i += 3 + n
    return out


def externals(path):
    """The EXTDEF names of an object, in the order that numbers them."""
    d = open(path, "rb").read()
    out, i = [], 0
    while i < len(d):
        t, n = d[i], int.from_bytes(d[i+1:i+3], "little")
        body = d[i+3:i+3+n-1]
        if t == 0x8C:
            p = 0
            while p < len(body):
                l = body[p]
                out.append(body[p+1:p+1+l].decode("ascii", "replace"))
                p += 1 + l + 1                  # and the type index
        i += 3 + n
    return out


def segment(paragraph=PARAGRAPH):
    """SYSINITSEG, resolved, as LINK and EXE2BIN left it in IBMBIO.COM."""
    image = bytearray(SEGSIZE)
    base = {}                                   # a module's start in the segment

    for mod in ("SYSINI", "SYSIMES"):
        segs, chunks, wild, fixups = checkobj.records(os.path.join(OBJ, mod + ".OBJ"))
        at = base[mod] = SEGSIZE if mod == "SYSIMES" else 0
        for seg, off, data in chunks:
            if segs[seg-1]["absolute"]:
                continue                        # DOSFRAME, which is not here
            end = at + off + len(data)
            if end > len(image):
                image.extend(bytes(end - len(image)))
            image[at+off:end] = data

    # SYSIMES is the messages, and nothing in it needs resolving: its object
    # has no FIXUPP record at all.  SYSINI's are resolved against where the
    # messages landed.
    segs, chunks, wild, fixups = checkobj.records(os.path.join(OBJ, "SYSINI.OBJ"))
    where = publics(os.path.join(OBJ, "SYSIMES.OBJ"))
    names = externals(os.path.join(OBJ, "SYSINI.OBJ"))

    for seg, off, loc, segrel, method, index, disp in fixups:
        if segs[seg-1]["absolute"]:
            continue
        if method == 2:                         # a name SYSIMES exports
            target = base["SYSIMES"] + where[names[index-1]] + disp
            frame = paragraph
        elif segs[index-1]["absolute"]:         # DOSFRAME: an address at 0:0
            target, frame = disp, segs[index-1]["frame"]
        else:                                   # somewhere in SYSINITSEG
            target, frame = base["SYSINI"] + disp, paragraph
        at = off
        if loc == 1:                            # a 16 bit offset
            value = target if segrel else (target - (at + 2)) & 0xFFFF
            image[at:at+2] = (value & 0xFFFF).to_bytes(2, "little")
        elif loc == 3:                          # an offset and a paragraph
            image[at:at+2] = (target & 0xFFFF).to_bytes(2, "little")
            image[at+2:at+4] = frame.to_bytes(2, "little")
        else:
            raise SystemExit("sysinit.py: a fixup at %04x is %d wide, which "
                             "nothing here writes" % (at, loc))
    return bytes(image)


def main():
    """Write SYSINITSEG where src/BIOSLNK.ASM reads it, and check it.

    There is only one answer this can give, and IBMBIO.COM holds it, so the
    writing and the checking are the same run: a build that cannot produce
    the shipped bytes should not produce a file either."""
    ours = segment()
    com = open(os.path.join(HERE, "bin", "DISK1", "IBMBIO.COM"), "rb").read()
    theirs = com[SHIPPED:SHIPPED+len(ours)]
    if ours != theirs:
        bad = [i for i in range(len(ours)) if ours[i] != theirs[i]]
        print("sysinit.py: %d of %d bytes differ from IBMBIO.COM:"
              % (len(bad), len(ours)))
        for i in bad[:40]:
            print("    %04x: ours %02x, theirs %02x" % (i, ours[i], theirs[i]))
        return 1

    open(os.path.join(HERE, "bin", "SYSINIT.BIN"), "wb").write(ours)
    print("SYSINITSEG: %d bytes resolved at paragraph %04x, and they are "
          "IBMBIO.COM's own" % (len(ours), PARAGRAPH))
    return 0


if __name__ == "__main__":
    sys.exit(main())
