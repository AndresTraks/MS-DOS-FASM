



if SEGSEL = S_INIT


        IF IBM = 0
HEADER  DB      13,10,"Command v. 2.11"
        IF      HIGHMEM
        DB      "H"
        END IF
        DB      13,10,"$"
        END IF
        IF IBM
HEADER  DB      13,10,13,10,"TeleVideo Personal Computer DOS Vers. 2.11",13,10
        DB      "(C) Copyright TeleVideo Systems, Inc. 1983",13,10
	DB	"(C) Copyright Microsoft Corp. 1981, 1982, 1983",13,10,"$"
        END IF

BADCOMLKMES DB  "Specified COMMAND search directory bad",13,10,"$"

end if

