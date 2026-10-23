ECHO ON
COPY five.txt A.TXT
COPY five.txt B.TXT
EDLIN A.TXT < edcmds.txt > OURS.TXT
MSEDLIN B.TXT < edcmds.txt > THEIRS.TXT
TYPE A.TXT
ECHO DONE
