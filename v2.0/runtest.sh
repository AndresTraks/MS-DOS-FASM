#!/bin/sh
# Boot the system with a batch file and say what happened.
#
# Checking anything by hand means building an image, starting QEMU, waiting,
# scraping the characters out of video memory and reading the directory back
# with mtools.  That is slow, and it is easy to misread: a listing on the
# screen can be the output of the command before it, and a file DIR reports
# as empty may simply not have been closed yet.  So:
#
#       ./runtest.sh -e "1 File(s) copied" tests/copy.bat
#
# assembles the sources, builds an image with that batch file as AUTOEXEC.BAT,
# boots it, prints the screen and the directory, and fails if the text given
# with -e is not on the screen.  The image is left as test.img to look at,
# and anything asked for with -g is dropped in test-out/.
#
# How long to wait is a guess, so end the batch file with ECHO DONE and ask
# for -e DONE.  Then a guess that was too short fails for a plain reason
# instead of passing on a screen that had not finished filling.
#
# Only the last 25 lines of a run survive, the rest having scrolled away, so
# a batch that says much should send it to a file -- redirection works -- and
# fetch that with -g.  What -e looks through is the screen and every fetched
# file together, so either will do.
set -e
cd "$(dirname "$0")"

RUN=45                  # seconds to let it run before taking the screen
KEYSAT=30               # when to start sending keystrokes
KEYS=                   # QEMU sendkey names, one a second
EXTRA=                  # files to put on the image
BIMAGE=                 # a second floppy, as drive B
FETCH=                  # files to take off it afterwards
EXPECT=                 # text that has to appear on the screen
IMAGE=test.img
OUT=${TMPDIR:-/tmp}/runtest.$$

usage() {
    cat >&2 <<USAGE
usage: $0 [-t seconds] [-k "keys"] [-K seconds] [-f file] [-g name]
          [-b image] [-e text] batchfile

  -t  how long to let it run, default $RUN; a MASM run wants 400
  -k  keystrokes to send, QEMU sendkey names: -k "ret ret ret"
  -K  when to start sending them, default $KEYSAT
  -f  a file to put on the image, repeatable
  -g  a file to take off the image into test-out/, repeatable
  -b  an image to attach as the second floppy, which DOS sees as B:
  -e  text that must appear on the screen or in a file fetched with -g,
      repeatable; absent means fail
USAGE
    exit 2
}

while getopts t:k:K:f:g:b:e: opt; do
    case $opt in
        t) RUN=$OPTARG ;;
        k) KEYS=$OPTARG ;;
        K) KEYSAT=$OPTARG ;;
        f) EXTRA="$EXTRA $OPTARG" ;;
        g) FETCH="$FETCH $OPTARG" ;;
        b) BIMAGE=$OPTARG ;;
        e) EXPECT="$EXPECT
$OPTARG" ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
[ $# -eq 1 ] || usage
BATCH=$1
[ -f "$BATCH" ] || { echo "$0: no such batch file: $BATCH" >&2; exit 2; }

QEMU=${QEMU:-qemu-system-i386}
command -v "$QEMU" >/dev/null 2>&1 || { echo "$0: $QEMU not found" >&2; exit 2; }

# Always test what the sources build, never a stale image.  mtools says
# "init: allocate buffer: Cannot allocate memory" on every call and copies the
# file regardless; nothing here filters it, because hiding it in POSIX sh
# means either losing the exit status of what it came from or a temporary file.
./create_image.sh >/dev/null

cp msdos.img "$IMAGE"
mcopy -o -i "$IMAGE" "$BATCH" ::AUTOEXEC.BAT
for f in $EXTRA; do mcopy -o -i "$IMAGE" "$f" ::; done

# Unquoted on purpose, as it is either two words or none.
BOPT=
if [ -n "$BIMAGE" ]; then
    [ -f "$BIMAGE" ] || { echo "$0: no such image: $BIMAGE" >&2; exit 2; }
    BOPT="-drive file=$BIMAGE,format=raw,if=floppy,index=1"
fi

mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

# The monitor is on stdin, so the replies are of no interest -- the screen
# comes back through pmemsave instead, as the text the adapter is showing.
{
    if [ -n "$KEYS" ]; then
        sleep "$KEYSAT"
        for k in $KEYS; do echo "sendkey $k"; sleep 1; done
        sleep $((RUN > KEYSAT ? RUN - KEYSAT : 1))
    else
        sleep "$RUN"
    fi
    echo "pmemsave 0xb8000 4000 \"$OUT/screen.bin\""
    sleep 2
    echo quit
} | "$QEMU" -rtc base=localtime \
            -drive file="$IMAGE",format=raw,if=floppy,index=0 $BOPT \
            -display none -monitor stdio >/dev/null 2>&1 || true

[ -s "$OUT/screen.bin" ] || { echo "$0: the screen never came back; QEMU or the monitor failed" >&2; exit 1; }

python3 - "$OUT/screen.bin" > "$OUT/screen.txt" <<'PY'
import sys
d = open(sys.argv[1], 'rb').read()
for row in range(25):
    cell = lambda c: d[(row * 80 + c) * 2]
    print(''.join(chr(cell(c)) if 32 <= cell(c) < 127 else ' '
                  for c in range(80)).rstrip())
PY

echo "--- screen"
sed '/^$/d' "$OUT/screen.txt"
echo "--- directory"
mdir -i "$IMAGE" :: 2>/dev/null | sed '1,2d;/^$/d'

if [ -n "$FETCH" ]; then mkdir -p test-out; fi
cp "$OUT/screen.txt" "$OUT/haystack"
for name in $FETCH; do
    if mcopy -o -i "$IMAGE" "::$name" "test-out/$name" 2>/dev/null; then
        echo "--- fetched test-out/$name ($(wc -c < "test-out/$name") bytes)"
        cat "test-out/$name" >> "$OUT/haystack"
    else
        echo "--- $name is not on the image" >&2
    fi
done

# Read the wanted text from a file rather than a pipe, so the loop runs in
# this shell and can report every miss instead of stopping at the first.
printf '%s\n' "$EXPECT" > "$OUT/expect"
rc=0
while read -r want; do
    [ -n "$want" ] || continue
    if grep -qaF -- "$want" "$OUT/haystack"; then
        echo "ok      $want"
    else
        echo "MISSING $want"
        rc=1
    fi
done < "$OUT/expect"
exit $rc
