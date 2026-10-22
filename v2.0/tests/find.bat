ECHO ON
FIND "line 2 of" lines.txt > OURS.TXT
MSFIND "line 2 of" lines.txt > THEIRS.TXT
FIND /C "of sixty" lines.txt >> OURS.TXT
MSFIND /C "of sixty" lines.txt >> THEIRS.TXT
FIND /N "line 59" lines.txt >> OURS.TXT
MSFIND /N "line 59" lines.txt >> THEIRS.TXT
FIND /V "line" lines.txt >> OURS.TXT
MSFIND /V "line" lines.txt >> THEIRS.TXT
FIND "needle" nosuch.txt >> OURS.TXT
MSFIND "needle" nosuch.txt >> THEIRS.TXT
TYPE OURS.TXT
ECHO DONE
