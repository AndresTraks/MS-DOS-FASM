#!/bin/sh
# Hold the code INC/STRUC.INC generates against what it ought to be.
#
# The structured statements are a macro library, not a program, so there is
# nothing to boot and nothing of Microsoft's to compare with: struc.asm
# writes one of each statement and this holds the result against the jumps
# the library is supposed to make.  The run of NOPs is there to put a body
# out of a short jump's reach, and is collapsed to one line below.
set -e
cd "$(dirname "$0")/.."

if command -v fasm >/dev/null 2>&1; then
    FASM=fasm
elif command -v wine >/dev/null 2>&1; then
    FASM="wine ../fasmw17332/FASM.EXE"
    WINEDEBUG=${WINEDEBUG:--all}
    export WINEDEBUG
else
    echo "Neither fasm nor wine found. Please install one of them." >&2
    exit 1
fi

OUT=${TMPDIR:-/tmp}/struc.$$
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

$FASM tests/struc.asm "$OUT/struc.bin" >/dev/null

objdump -D -b binary -m i8086 -M intel --adjust-vma=0x100 "$OUT/struc.bin" |
    sed -n 's/^ *[0-9a-f]*:\t[0-9a-f ]*\t//p' |
    sed 's/  */ /g; s/ *$//' |
    awk '$0 == "nop" { n++; next } { if (n) { print "nop x" n; n = 0 } print }' \
    > "$OUT/ours.dis"

cat > "$OUT/want.dis" <<'WANT'
jae 0x103
inc ax
cmp ax,0x0
jne 0x10b
inc bx
jmp 0x10c
dec bx
cmp ax,0xffff
je 0x118
cmp bl,0x3
jne 0x117
nop x1
dec cx
cmp ax,0x1
jne 0x123
cmp bx,0x2
jne 0x123
inc dx
cmp ax,0x1
je 0x12d
cmp bx,0x2
jne 0x12e
inc si
test al,0x3
je 0x133
inc di
or ax,ax
jne 0x138
inc bp
cmp ax,0x0
je 0x140
jmp 0x1c2
nop x130
cmp ax,0x1
jne 0x1cb
mov al,0x1
jmp 0x1d6
cmp ax,0x2
jne 0x1d4
mov al,0x2
jmp 0x1d6
mov al,0x3
cmp ax,0x1
jne 0x1df
mov cl,0x1
jmp 0x1ea
cmp ax,0x2
jne 0x1e8
mov cl,0x2
jmp 0x1ea
mov cl,0x3
cmp cx,0x0
je 0x1f9
dec cx
cmp cx,0x5
jne 0x1f7
jmp 0x1f9
jmp 0x1ea
inc ax
cmp ax,0xa
jne 0x1f9
inc bx
loop 0x1ff
ret
WANT

if diff -u "$OUT/want.dis" "$OUT/ours.dis" > "$OUT/diff"; then
    echo "ok      the structured statements generate the code they should"
    exit 0
fi
echo "FAIL    the structured statements generate different code"
cat "$OUT/diff"
exit 1
