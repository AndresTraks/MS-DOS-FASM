ECHO ON
FC lines.txt lines.txt > OURS.TXT
MSFC lines.txt lines.txt > THEIRS.TXT
FC lines.txt other.txt >> OURS.TXT
MSFC lines.txt other.txt >> THEIRS.TXT
FC /B lines.txt other.txt >> OURS.TXT
MSFC /B lines.txt other.txt >> THEIRS.TXT
FC nosuch.txt lines.txt >> OURS.TXT
MSFC nosuch.txt lines.txt >> THEIRS.TXT
ECHO DONE
