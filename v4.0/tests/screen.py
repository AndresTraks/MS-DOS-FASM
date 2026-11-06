# The text screen as text, from a dump of the 4000 bytes at B8000: 25 rows of
# 80 cells, each a character and an attribute, with anything unprintable
# shown as a space.  Trailing blanks go; the rows themselves are all printed,
# so that the last line of the screen is the last line of this.
import sys

d = open(sys.argv[1], "rb").read()
for row in range(25):
    cell = lambda c: d[(row * 80 + c) * 2]
    print("".join(chr(cell(c)) if 32 <= cell(c) < 127 else " "
                  for c in range(80)).rstrip())
