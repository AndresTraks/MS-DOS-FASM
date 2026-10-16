#!/usr/bin/env python3
# Decode a .PRF file written by PROFIL and say whether it holds samples.
#
# The format is the profdata structure in source/PROFILE.txt: nine words of
# header, then one count per bucket.  A .PRF that decodes consistently and
# has a nonzero total is the proof that the clock module works -- the counts
# are only there because the interrupt fired, CLK_INTER classified CS:IP and
# LEAVE_INT's EOI let the next interrupt through.
#
#       ./readprf.py [--grain N] [--bucket N] file.PRF
#
# --grain and --bucket check the sample interval and the paragraphs per
# bucket that were asked for, which is how we know the answers PROFIL was
# fed actually reached it.

import struct
import sys

FIELDS = ("clock_grain", "bucket_num", "bucket_siz", "prog_low_pa",
          "prog_high_pa", "dos_pa", "hit_io", "hit_dos", "hit_high")
HEADER = 2 * len(FIELDS)


def main(argv):
    want = {}
    args = []
    while argv:
        a = argv.pop(0)
        if a in ("--grain", "--bucket"):
            if not argv:
                sys.exit("%s wants a number" % a)
            want["clock_grain" if a == "--grain" else "bucket_siz"] = int(argv.pop(0))
        else:
            args.append(a)
    if len(args) != 1:
        sys.exit("usage: readprf.py [--grain N] [--bucket N] file.PRF")

    d = open(args[0], "rb").read()
    if len(d) < HEADER:
        sys.exit("%s: %d bytes, too short for the %d byte header"
                 % (args[0], len(d), HEADER))
    h = dict(zip(FIELDS, struct.unpack_from("<%dH" % len(FIELDS), d)))
    for name in FIELDS:
        print("%-13s %6d" % (name, h[name]))

    expect = HEADER + 2 * h["bucket_num"]
    print("%-13s %6d bytes, %d buckets wants %d" % ("size", len(d),
                                                    h["bucket_num"], expect))
    counted = min(h["bucket_num"], (len(d) - HEADER) // 2)
    buckets = struct.unpack_from("<%dH" % counted, d, HEADER)
    total = h["hit_io"] + h["hit_dos"] + h["hit_high"] + sum(buckets)
    print("%-13s %6d  io %d, dos %d, high %d, buckets %d"
          % ("samples", total, h["hit_io"], h["hit_dos"], h["hit_high"],
             sum(buckets)))
    hot = sorted(((c, i) for i, c in enumerate(buckets) if c), reverse=True)
    if hot:
        print("busiest       %s"
              % ", ".join("bucket %d: %d" % (i, c) for c, i in hot[:8]))

    bad = []
    if len(d) != expect:
        bad.append("the file is %d bytes where the header calls for %d"
                   % (len(d), expect))
    if h["bucket_num"] == 0:
        bad.append("no buckets")
    if h["prog_low_pa"] >= h["prog_high_pa"]:
        bad.append("program bounds %d..%d are not a range"
                   % (h["prog_low_pa"], h["prog_high_pa"]))
    if total == 0:
        bad.append("no samples: the clock interrupt never reached CLK_INTER")
    for name, n in want.items():
        if h[name] != n:
            bad.append("%s is %d, asked for %d" % (name, h[name], n))
    if bad:
        sys.exit("FAIL: " + "; ".join(bad))
    print("ok")


main(sys.argv[1:])
