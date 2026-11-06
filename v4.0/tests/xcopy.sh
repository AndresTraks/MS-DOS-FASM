#!/bin/sh
# Run XCOPY.EXE on the system this builds, over a tree with a subdirectory.
#
# XCOPY reads as many files as it can into one buffer and then writes them
# all out, which is why it says "Reading source file(s)..." before it names
# anything: the buffer is the memory above the program, and each file in it
# is preceded by a header the program keeps its name and length in.  With /S
# it walks the source tree, keeping a stack of DTAs -- one for each
# directory it is inside -- and makes the directories it needs on the target
# as it goes.
#
# It cannot tell a target directory from a target file by the name alone, so
# it asks, through the message retriever; the answer is typed in.
#
# The last command gives it a source that matches nothing.  The wording of
# that refusal comes from COMMAND.COM's extended-error table rather than from
# XCOPY, and comes back broken; see the note by the check at the end.
#
# What the copy produced is read back from outside afterwards, so the test
# sees the files and not only what XCOPY said about them.
set -e
cd "$(dirname "$0")/.."

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }
command -v mcopy >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }
command -v mmd >/dev/null 2>&1 || { echo "$0: mtools not found" >&2; exit 2; }

OUT=${TMPDIR:-/tmp}/xcopy.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

IMG="$OUT/a.img"
./create_image.sh "$IMG" >/dev/null
mcopy -o -i "$IMG" bin/XCOPY.EXE ::XCOPY.EXE

# A source tree: two files in SRC and one in SRC\DEEP, so the walk has
# somewhere to go and a directory to make on the target.
printf 'one\r\n' > "$OUT/ONE.TXT"
printf 'two two\r\n' > "$OUT/TWO.TXT"
printf 'three three three\r\n' > "$OUT/THREE.TXT"
mmd -i "$IMG" ::SRC
mmd -i "$IMG" ::SRC/DEEP
mcopy -o -i "$IMG" "$OUT/ONE.TXT" ::SRC/ONE.TXT
mcopy -o -i "$IMG" "$OUT/TWO.TXT" ::SRC/TWO.TXT
mcopy -o -i "$IMG" "$OUT/THREE.TXT" ::SRC/DEEP/THREE.TXT

printf 'ECHO OFF\r\nXCOPY SRC DEST /S > PRN\r\nDIR DEST > PRN\r\nDIR DEST\\DEEP > PRN\r\nXCOPY NOSUCH.ZZZ DEST > PRN\r\n' \
    > "$OUT/AUTOEXEC.BAT"
mcopy -o -i "$IMG" "$OUT/AUTOEXEC.BAT" ::AUTOEXEC.BAT

# D for directory, at the question XCOPY asks before it starts.
{
    sleep 42
    echo "sendkey d"
    sleep 1
    echo "sendkey ret"
    sleep 20
    echo "pmemsave 0xb8000 4000 \"$OUT/screen.bin\""
    sleep 2
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMG",format=raw,if=floppy,index=0 \
            -parallel "file:$OUT/prn.txt" \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/prn.txt" ] || { echo "$0: the printer stayed empty" >&2; exit 1; }

# What came out, read back through mtools rather than through XCOPY.
for f in ONE.TXT TWO.TXT; do
    mcopy -n -i "$IMG" "::DEST/$f" "$OUT/got-$f" 2>/dev/null || true
done
mcopy -n -i "$IMG" ::DEST/DEEP/THREE.TXT "$OUT/got-THREE.TXT" 2>/dev/null || true

python3 - "$OUT/prn.txt" "$OUT/screen.bin" "$OUT" <<'PY' || exit 1
import os
import sys

said = open(sys.argv[1], "rb").read().decode("cp437").replace("\r", "")
d = open(sys.argv[2], "rb").read()
rows = []
for row in range(25):
    cell = lambda c: d[(row * 80 + c) * 2]
    rows.append("".join(chr(cell(c)) if 32 <= cell(c) < 127 else " "
                        for c in range(80)).rstrip())
screen = "\n".join(rows)
out = sys.argv[3]

print("--- what it printed")
for line in said.split("\n"):
    if line.strip():
        print("   %s" % line)
print("--- what was on the screen")
for r in rows:
    if r.strip():
        print("   %s" % r)

rc = 0
print("--- checks")
want = [("(F = file, D = directory)?",
         "it asked what the target name means, through the retriever"),
        ("Reading source file(s)...",
         "and read as much as the buffer would hold before writing any"),
        ("SRC\\ONE.TXT", "the first file of the source directory"),
        ("SRC\\TWO.TXT", "and the second"),
        ("SRC\\DEEP\\THREE.TXT",
         "and /S took the walk down into the subdirectory"),
        ("3 File(s) copied", "and it counted all three"),
        ("Directory of  A:\\DEST", "the target directory was made"),
        ("DEEP         <DIR>", "and the subdirectory under it"),
        ("THREE    TXT", "with the file from the walk in it")]
for text, why in want:
    if text in said:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1

# The copies themselves, byte for byte.
for name, body in (("ONE.TXT", b"one\r\n"),
                   ("TWO.TXT", b"two two\r\n"),
                   ("THREE.TXT", b"three three three\r\n")):
    path = os.path.join(out, "got-" + name)
    if not os.path.exists(path):
        print("MISSING %s from the target" % name)
        rc = 1
    elif open(path, "rb").read() == body:
        print("ok      %s came through byte for byte" % name)
    else:
        print("WRONG   %s is %r" % (name, open(path, "rb").read()[:40]))
        rc = 1

# A source that matches nothing.  XCOPY names it and counts no files, both
# of which are its own messages; the wording of the refusal is not -- the
# .SKL says ":use 23 EXTEND2", so the text comes from COMMAND.COM's
# extended-error table at run time, and it arrives split around the name
# ("File not fou-  NOSUCH.ZZZnd").  That is the class 2 and 3 retrieval
# being left alone, not XCOPY, so only XCOPY's own part is checked.
for text, why in (("NOSUCH.ZZZ", "it named the source that matched nothing"),
                  ("0 File(s) copied", "and copied none")):
    if text in said:
        print("ok      %s: %s" % (text, why))
    else:
        print("MISSING %s" % text)
        rc = 1
sys.exit(rc)
PY
