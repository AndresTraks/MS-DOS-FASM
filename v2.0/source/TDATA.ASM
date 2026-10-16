



if SEGSEL = S_TRANCODE


end if

; Data for transient portion


if SEGSEL = S_TRANDATA


ZERO    =       $
BADBAT  DB      13,10,"Batch file missing",13,10,"$"
NEEDBAT DB      13,10,"Insert disk with batch file"
        DB      13,10,"and press any key when ready",13,10,"$"
BADNAM  DB      "Bad command or file name",13,10,"$"
RENERR  DB      "Duplicate file name or "
NOTFND  DB      "File not found",13,10,"$"
NOSPACE DB      "Insufficient disk space",13,10,"$"
ENVERR  DB      "Out of environment space",13,10,"$"
FULDIR  DB      "File creation error",13,10,"$"
OVERWR  DB      "File cannot be copied onto itself",13,10,"$"
LOSTERR DB      "Content of destination lost before copy",13,10,"$"

;"COPIED_PRE<# files copied>COPIED_POST"
COPIED_POST  DB      " File(s) copied",13,10
COPIED_PRE   DB      "$"

;"DIRMES_PRE<# files in dir>DIRMES_POST"
DIRMES_POST  DB      " File(s) "
DIRMES_PRE   DB      "$"

;"BYTMES_PRE<# free bytes>BYTMES_POST"
BYTMES_POST  DB      " bytes free",13,10
BYTMES_PRE   DB      "$"

BADDRV  DB      "Invalid drive specification",13,10,"$"
PAUSEMES DB      "Strike a key when ready . . . $"
BADSWT  DB      "Invalid parameter",13,10,"$"
WEEKTAB DB      "SunMonTueWedThuFriSat"
BADDAT  DB      13,10,"Invalid date$"

;"CURDAT_PRE<day of week>CURDAT_MID<MO,DAY,YR>CURDAT_POST"
;Note: CURDAT_MID also appears in the date printed via PROMPT command
CURDAT_PRE   DB      "Current date is "
label CURDAT_MID byte
CURDAT_POST  DB      "$"

NEWDAT  DB      13,10,"Enter new date: $"
BADTIM  DB      13,10,"Invalid time$"

;"CURTIM_PRE<HR,MIN,SEC,HSEC>CURTIM_POST"
CURTIM_PRE   DB      "Current time is "
CURTIM_POST  DB      "$"

NEWTIM  DB      13,10,"Enter new time: $"
SUREMES DB      "Are you sure (Y/N)? $"
DMES    DB      " <DIR>   $"

;"VERMES_PRE<version #>VERMES_POST"
        IF      IBMVER
VERMES_PRE  DB      "TeleVideo Personal Computer DOS Version "
        END IF
        IF      MSVER
VERMES_PRE  DB      "MS-DOS Version "
        END IF
VERMES_POST DB      "$"

VOLMES  DB      " Volume in drive $"
GOTVOL  DB      " is $"
NOVOL   DB      " has no label$"

BADCD   DB      "Invalid directory",13,10,"$"
BADMKD  DB      "Unable to create directory",13,10,"$"
BADRMD  DB      "Invalid path, not directory,",13,10
        DB      "or directory not empty",13,10,"$"
BAD_ON_OFF DB   "Must specify ON or OFF"        ;Note Run over to next message

;"DIRHEAD_PRE<path of dir>DIRHEAD_POST"
DIRHEAD_POST DB      13,10,"$"
DIRHEAD_PRE  DB      " Directory of  $"

NULPATH DB      "No Path $"
PATH_TEXT    DB "PATH="
PROMPT_TEXT  DB "PROMPT="
BADPMES DB      "Invalid drive in search path",13,10,"$"
BADDEV  DB      "Invalid device",13,10,"$"
BADLAB  DB      "Label not found",13,10,"$"
SYNTMES DB      "Syntax error",13,10,"$"
FORNESTMES DB   13,"FOR cannot be nested",13,10,"$"
PIPEEMES DB     "Intermediate file error during pipe",13,10,"$"
INBDEV  DB      "Cannot do binary reads from a device",13,10,"$"
OFFMES  DB      "off",13,10,"$"
ONMES   DB      "on",13,10,"$"
CTRLCMES DB     "BREAK is $"
VERIMES DB      "VERIFY is $"
ECHOMES DB      "ECHO is $"
BADCPMES DB     "Invalid path or file name",13,10,"$"
BADARGS DB      "Invalid number of parameters",13,10,"$"
DEVWMES DB      "Error writing to device"
ACRLF   DB      13,10,"$"
DBACK   DB      8," ",8,0               ; DESTRUCTIVE BACK SPACE

CLSSTRING DB    4,01BH,"[2J"            ; ANSI Clear screen

label PROMPT_TABLE byte
        DB      "D"
        DW      PRINT_DATE
        DB      "T"
        DW      PRINT_TIME
        DB      "P"
        DW      PRINT_DEFAULT_DIRECTORY
        DB      "N"
        DW      PRINT_DRIVE
        DB      "V"
        DW      PRINT_VERSION
        DB      "G"
        DW      PRINT_G
        DB      "L"
        DW      PRINT_L
        DB      "B"
        DW      PRINT_B
        DB      "_"
        DW      CRLF2
        DB      "$"
        DW      OUT_
        DB      "E"
        DW      PRINT_ESC
        DB      "H"
        DW      PRINT_BACK
        DB      "Q"
        DW      PRINT_EQ
        DB      0                       ; NUL TERMINATED

label IFTAB byte                    ; Table of IF conditionals
        DB      3,"NOT"                 ; First byte is count
        DW      IFNOT
        DB      10,"ERRORLEVEL"
        DW      IFERLEV
        DB      5,"EXIST"
        DW      IFEXISTS
        DB      0

COMTAB  DB      4,"DIR",1               ; Table for internal command names
        DW      CATALOG
        DB      7,"RENAME",1
        DW      CRENAME
        DB      4,"REN",1
        DW      CRENAME
        DB      6,"ERASE",1
        DW      ERASE
        DB      4,"DEL",1
        DW      ERASE
        DB      5,"TYPE",1
        DW      TYPEFIL
        DB      4,"REM",0
        DW      TCOMMAND
        DB      5,"COPY",1
        DW      COPY
        DB      6,"PAUSE_",0
        DW      PAUSE_
        DB      5,"DATE",0
        DW      DATE
        DB      5,"TIME",0
        DW      CTIME
        DB      4,"VER",0
        DW      VERSION
        DB      4,"VOL",1
        DW      VOLUME
        DB      3,"CD",1
        DW      _CHDIR
        DB      6,"CHDIR",1
        DW      _CHDIR
        DB      3,"MD",1
        DW      _MKDIR
        DB      6,"MKDIR",1
        DW      _MKDIR
        DB      3,"RD",1
        DW      _RMDIR
        DB      6,"RMDIR",1
        DW      _RMDIR
        DB      6,"BREAK",0
        DW      CNTRLC
        DB      7,"VERIFY",0
        DW      VERIFY
        DB      4,"SET",0
        DW      ADD_NAME_TO_ENVIRONMENT
        DB      7,"PROMPT",0
        DW      ADD_PROMPT
        DB      5,"PATH",0
        DW      PATH
        DB      5,"EXIT",0
        DW      _EXIT
        DB      5,"CTTY",1
        DW      CTTY
        DB      5,"ECHO",0
        DW      ECHO
        DB      5,"GOTO",0
        DW      GOTO
        DB      6,"SHIFT",0
        DW      SHIFT
        DB      3,"IF",0
        DW      _IF
        DB      4,"FOR",0
        DW      _FOR
        DB      4,"CLS",0
        DW      CLS
        DB      0               ; Terminate command table

label TRANDATAEND byte

end if
