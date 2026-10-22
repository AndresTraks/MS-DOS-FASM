ECHO ON
SORT < lines.txt > OURS.TXT
MSSORT < lines.txt > THEIRS.TXT
SORT /R < lines.txt >> OURS.TXT
MSSORT /R < lines.txt >> THEIRS.TXT
SORT /+6 < lines.txt >> OURS.TXT
MSSORT /+6 < lines.txt >> THEIRS.TXT
ECHO DONE
