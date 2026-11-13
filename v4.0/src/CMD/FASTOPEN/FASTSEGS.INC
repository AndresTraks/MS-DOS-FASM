


.seq
if SEGSEL = S_STACK; represents STACK                            ;AN000;
end if ;AN000;

if SEGSEL = S_CSEG_MAIN; represents MAIN
end if

if SEGSEL = S_CSEG_OPEN; represents  FASTOPEN                          ;AN000;
end if ;AN000;

if SEGSEL = S_CSEG_SEEK; represents FASTSEEK                           ;AN000;
end if ;AN000;

if SEGSEL = S_CSEG_INIT; represents INIT
end if

