#!/usr/bin/env python3
"""Compare the instruction on each line with the one the release wrote there.

The conversion is line for line: almost every module still has the same
number of lines as the file Microsoft shipped, and the instruction on a line
is still the instruction that was there.  So the two can be held against each
other mnemonic by mnemonic, and anything that changed has to be a change the
conversion meant to make.

The ones it meant to make are listed in SAME below -- MASM's LODS CS:BYTE PTR
[SI] is fasm's LODS byte [cs:SI], its JMP SHORT is a JMP, a FAR procedure's
RET is a RETF, EVEN is ALIGN, and so on.  Anything else is a line whose
meaning moved, which is the one thing a line-for-line conversion must not do
and the one thing nothing else here would notice: the assembler is happy, the
module is the right length, and the instruction does something else.

What it still reports, and why those are not findings: DOSMAC.INC's macros
were rewritten rather than translated, so its two streams do not line up at
all; JUMPMAC.INC and MSSTACK.INC build their instructions out of names that
MASM pasted together with & and fasm with #; MSBOOT.ASM has one NOP that MASM
generated and the conversion writes out; and MSEXTRN.INC asks IFNDEF about a
block whose body is commented out.

    python3 checkcode.py
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = subprocess.run(["git", "-C", HERE, "rev-parse", "--show-toplevel"],
                      capture_output=True, text=True).stdout.strip()

# What the conversion is allowed to have made of a mnemonic.
SAME = {
    "LODS": {"LODSB", "LODSW", "LODS"},
    "STOS": {"STOSB", "STOSW", "STOS"},
    "MOVS": {"MOVSB", "MOVSW", "MOVS"},
    "SCAS": {"SCASB", "SCASW", "SCAS"},
    "CMPS": {"CMPSB", "CMPSW", "CMPS"},
    "XLAT": {"XLAT", "XLATB"},
    "RET": {"RET", "RETF", "RETN"},
    "EVEN": {"ALIGN"},
    "ENDIF": {"END"},               # end if
    "IFDEF": {"MATCH"},
    "IFNDEF": {"MATCH"},
    "IF1": {"MATCH", "IF"},
    "IF2": {"MATCH", "IF"},
    "IFE": {"IF"},
    "IFIDN": {"MATCH"},
    "IFNB": {"MATCH"},
    "IFB": {"MATCH"},
    "ELSE": {"ELSE"},
    "ORG": {"ORG", "TIMES", "STORE", "VIRTUAL"},
    "DB": {"DB", "TIMES"},
    "DW": {"DW", "TIMES"},
    "DD": {"DD", "DW", "TIMES"},    # a far pointer becomes two words
    "PROC": {"PROC", None},         # NAME PROC became NAME:
    "ENDP": {None},
    "LABEL": {"LABEL", None},       # NAME LABEL BYTE became NAME:
    "RECORD": {"STRUC", None},
    "EQU": {"EQU", "="},
    "=": {"=", "EQU"},
    "MACRO": {"MACRO"},
    "ENDM": {"}"},
    "STRUC": {"STRUC"},
    "ENDS": {"}", "END", None},     # a segment's ENDS became "end if"
    "PUBLIC": {None},               # kept as comments
    "EXTRN": {None},
    "INCLUDE": {"INCLUDE"},
    "PAGE": {"PAGE"},
    "SUBTTL": {"SUBTTL"},
    "TITLE": {"TITLE"},
    "NAME": {"NAME"},
    "ASSUME": {None},
    "SEGMENT": {"IF", None},
    "GROUP": {None},
    "END": {None, "END"},
    ".XLIST": {None}, ".LIST": {None}, ".XCREF": {None}, ".CREF": {None},
    ".SALL": {None}, ".RADIX": {None}, "%OUT": {None},
}
WORD = re.compile(r"[A-Za-z_@?$.%][A-Za-z0-9_@?$.]*")


def mnemonic(code):
    """The directive or instruction a line carries, or None."""
    code = code.split(";")[0].rstrip()
    if not code.strip():
        return None
    # a label on its own, or a label and then the instruction
    code = re.sub(r"^\s*[A-Za-z_@?$][A-Za-z0-9_@?$]*\s*:", " ", code)
    m = WORD.search(code)
    if not m:
        return None
    first = m.group(0).upper()
    rest = code[m.end():]
    # "NAME DB 0", "NAME PROC NEAR", "NAME EQU x": the second word is the one
    m2 = WORD.match(rest.lstrip()) if rest.strip() else None
    second = m2.group(0).upper() if m2 else None
    if second in ("DB", "DW", "DD", "DQ", "DT", "PROC", "ENDP", "EQU", "LABEL",
                  "STRUC", "ENDS", "SEGMENT", "GROUP", "MACRO", "RECORD"):
        return second
    if first in ("REP", "REPE", "REPNE", "REPZ", "REPNZ", "LOCK") and second:
        return second
    if re.match(r"^\s*=", rest):
        return "="
    return first


def allowed(was, now):
    if was == now:
        return True
    # fasm keeps every name that begins with $ for itself, so the kernel's
    # leading $ moved to the end: $GET_DATE became GET_DATE$.
    if was and now and was.startswith("$") and now == was[1:] + "$":
        return True
    if was in SAME and now in SAME[was]:
        return True
    # a conditional's spelling: IFxx became IF or MATCH, ENDIF became END IF
    if was and now and was.rstrip("0123456789") == now.rstrip("0123456789"):
        return True
    return False


def origin(rel):
    adds = subprocess.run(["git", "-C", REPO, "log", "--diff-filter=A",
                           "--format=%H", "--", rel],
                          capture_output=True, text=True).stdout.split()
    if not adds:
        return None
    return subprocess.run(["git", "-C", REPO, "show", "%s:%s" % (adds[-1], rel)],
                          capture_output=True).stdout.decode("cp437")


CANON = {}
for was, nows in SAME.items():
    for now in nows:
        if now:
            CANON[now] = was


def canon(m):
    """One spelling for the pairs the conversion is allowed to have changed."""
    if m is None:
        return None
    if m.startswith("$"):
        m = m[1:] + "$"
    return CANON.get(m, m)


# Only the processor's own instructions are lined up: a line of prose inside
# one of MSBIO1's unterminated comment blocks, or a structure body that moved
# to another file, is not an instruction and says nothing about the code.
INSTRUCTIONS = set("""
AAA AAD AAM AAS ADC ADD AND CALL CBW CLC CLD CLI CMC CMP CMPS CMPSB CMPSW CWD
DAA DAS DEC DIV ESC HLT IDIV IMUL IN INC INT INTO IRET JA JAE JB JBE JC JCXZ
JE JG JGE JL JLE JMP JNA JNAE JNB JNBE JNC JNE JNG JNGE JNL JNLE JNO JNP JNS
JNZ JO JP JPE JPO JS JZ LAHF LDS LEA LES LOCK LODS LODSB LODSW LOOP LOOPE
LOOPNE LOOPNZ LOOPZ MOV MOVS MOVSB MOVSW MUL NEG NOP NOT OR OUT POP POPF PUSH
PUSHF RCL RCR REP REPE REPNE REPNZ REPZ RET RETF RETN ROL ROR SAHF SAL SAR SBB
SCAS SCASB SCASW SHL SHR STC STD STI STOS STOSB STOSW SUB TEST WAIT XCHG XLAT
XLATB XOR
BSWAP ENTER LEAVE BOUND INSB OUTSB PUSHA POPA IMUL SHLD SHRD
""".split())

DROPPED = {"PUBLIC", "EXTRN", "ASSUME", "PROC", "ENDP", "LABEL", "ENDS",
           "SEGMENT", "GROUP", "END", "ENDM", "ENDIF", "ELSE", "IF", "MATCH",
           ".LALL", ".XALL", ".SALL", ".XLIST", ".LIST", ".XCREF", ".CREF",
           ".RADIX", "%OUT", "PAGE", "SUBTTL", "TITLE", "NAME", "TIMES",
           "ORG", "VIRTUAL", "STORE", "ALIGN", "EVEN", "INCLUDE", "EQU", "=",
           "STRUC", "RECORD", "MACRO", "}", "{", "IRP", "REPT", "LOCAL",
           "PURGE", "COMMENT", "ERRNZ", "DISPLAY", "ERR", "RESTORE"}


def sequence(lines):
    """Each line's instruction, the directives and the declarations aside."""
    out = []
    for n, line in enumerate(lines, 1):
        m = canon(mnemonic(line))
        if m is None or m in DROPPED or m not in INSTRUCTIONS:
            continue
        out.append((n, m, line.split(";")[0].strip()))
    return out


def compare_aligned(rel, was, now):
    """Line up the two instruction streams and say where they disagree."""
    import difflib
    a, b = sequence(was), sequence(now)
    sm = difflib.SequenceMatcher(None, [x[1] for x in a], [x[1] for x in b],
                                 autojunk=False)
    bad = 0
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        for k in range(max(i2 - i1, j2 - j1)):
            x = a[i1 + k] if i1 + k < i2 else None
            y = b[j1 + k] if j1 + k < j2 else None
            print("%-26s %5s %-10s -> %-10s %s"
                  % (rel, y[0] if y else "-", x[1] if x else "-",
                     y[1] if y else "-", (y or x)[2][:40]))
            bad += 1
    return bad


def main():
    names = []
    for here, dirs, files in os.walk(os.path.join(HERE, "src")):
        dirs.sort()
        for n in sorted(files):
            if n.upper().endswith((".ASM", ".INC")):
                names.append(os.path.relpath(os.path.join(here, n), HERE))
    total = lengths = 0
    for rel in names:
        orig = origin(os.path.relpath(os.path.join(HERE, rel), REPO))
        if orig is None:
            continue
        was = orig.replace("\r\n", "\n").split("\n")
        now = open(os.path.join(HERE, rel), encoding="cp437").read().split("\n")
        if len(was) != len(now):
            lengths += 1
            total += compare_aligned(rel, was, now)
            continue
        for n, (a, b) in enumerate(zip(was, now), 1):
            ma, mb = mnemonic(a), mnemonic(b)
            if ma is None and mb is None:
                continue
            if not allowed(ma, mb):
                print("%-26s %5d  %-10s -> %-10s %s"
                      % (rel, n, ma, mb, b.split(";")[0].strip()[:40]))
                total += 1
    print("\n%d lines carry a different instruction; %d files are a different "
          "length and were lined up by their instructions instead"
          % (total, lengths))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
