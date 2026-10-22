
FALSE   =     0
TRUE    =     -1

if SEGSEL = S_DATA


bad_vers_err db "Incorrect DOS version$"
NOTFND  DB      "File not found$"
NOROOM  DB      "Insufficient memory$"
DIRFULL DB      "File creation error$"
FULL    DB      "Insufficient disk space$"
PROMPT  DB      "Fix-ups needed - base segment (hex): $"
CRLF    DB      13,10,"$"
CANTFIX DB      "File cannot be converted$"
RDBAD   DB      "WARNING - Read error on EXE file."
        DB      13,10,"          Amount read less than size in header.",13,10,"$"


end if
