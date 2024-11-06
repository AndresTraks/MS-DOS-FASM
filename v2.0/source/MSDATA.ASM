;SUBTTL Initialized data and data used at DOS initialization
; DATA AREA for MS-DOS

;IF      ~DEFINED  KANJI
KANJI   =     0       ;FALSE
;END     IF

CONSTANTS:


CONSTRT =     $               ; Start of constants segment

DEVSTRLEN DB    3              ; Size of below
DEVSTRING DB    "DEV"          ; Dummy device directory

;
; Table of routines for assignable devices
;
; MSDOS allows assignment if the following standard devices:
;   stdin  (usually CON input)
;   stdout (usually CON output)
;   auxin  (usually AUX input)
;   auxout (usually AUX output)
;   stdlpt (usually PRN output)
;
; SPECIAL NOTE:
;   Status of a file is a strange idea.  We choose to handle it in this manner:
;   If we're not at end-of-file, then we always say that we have a character.
;   Otherwise, we return ^Z as the character and set the ZERO flag.  In this
;   manner we can support program written under the old DOS (they use ^Z as EOF
;   on devices) and programs written under the new DOS (they use the ZERO flag
;   as EOF).

; Default FCBs for boot up

sftabl:                              ; file table
            DW      -1
            DW      -1
            DW      sf_default_number  ; Number of entries in table
            DB      sf_default_number * sizeof.sf_entry DUP 0

        NoSetDir     DB ?          ; true -> do not set directory
        DidCTRLC     DB ?          ; true -> we did a ^C exit
        SpaceFlag    DB ?          ; true -> embedded spaces are allowed
                                        ; in FCB
; the next two variables relate to the position of the logical stdout/stdin
; cursor.  They are only meaningful when stdin/stdout are assigned to the
; console.

        CARPOS      DB ?            ; cursor position in stdin
        STARTPOS    DB ?          ; position of cursor at beginning
                                        ; of buffered input call
        PFLAG    DB ?
        VERFLG    DB ?            ; Initialize with verify off
        CONTPOS    DW ?

CHARCO      DB      00000011B           ; Allows statchks every 4 chars...

        DMAADD     DD 00000080H         ; User's disk transfer address

ENDMEM      DW      ?

switch_character    DB  '/'

device_availability DB  0FFH

            FirstArena   DW ?       ; first free block found
            BestArena    DW ?       ; best free block found
            LastArena    DW ?       ; last free block found
            AllocMethod  DB ?       ; how to alloc first(best)last
            arena_head   DW ?

; The following block of data is used by SYSINIT.  Do not change the order or
; size of this block

SYSINITVAR:
        DPBHEAD  DD ?          ; Pointer to head of DPB-FAT list
        sft_addr DD sftabl     ; Pointer to first FCB table

; The following address points to the CLOCK device
        BCLOCK DD ?
; The following address is used by DISKSTATCHK it is always points to the
; console input device header
        BCON DD ?              ; Console device entry points
        NUMIO DB ?              ; Number of disk tables
MAXSEC      DW      0                   ; Maximum allowed sector size
        BUFFHEAD DD ?          ; Pointer to head of buffer queue
DEVHEAD:
        NULDEV DD ?            ; Set to list start passed by 
					; BIOS at DOS Init

        DW      DEVTYP OR ISNULL
        short_addr  SNULDEV
        short_addr  INULDEV
        DB      "NUL     "


        DAY     DB 0
        MONTH   DB 0
        YEAR    DW 0
        DAYCNT  DW -1
        WEEKDAY DB 0

        CURDRV DB ?             ; Default to drive A
        LASTENT DW ?
        INDOS DB 0              ; DOS status for interrupt processing
        ERRORMODE DB ?          ; Flag for INT 24 processing
WPERR       DB      -1                  ; Write protect error flag
        CONSWAP DB ?
IDLEINT     DB      1
CNTCFLAG    DB      0                   ; ^C check in dispatch disabled

LASTBUFFER:               ; Buffer queue recency pointer
            DW      -1
            DW      -1

; Combination of all device call parameters

DEVCALL SRHEAD
CALLUNIT:
CALLFLSH:
        CALLMED DB ?
CALLBR:
CALLXAD:
        CALLRBYT DB ?
        DB      3 DUP(?)
CALLBPB:
        CALLSCNT DW ?
CALLSSEC    DW      ?

        CALLDEVAD DD ?             ; stash for device entry point

; Same as above for I/O calls

IOCALL  SRHEAD
IOFLSH:
IORCHR:
        IOMED DB ?
        IOXAD DD ?
        IOSCNT DW ?
        IOSSEC DW ?

; Call struct for DSKSTATCHK
DSKSTCALL       DB      DRDNDHL
                DB      0
DSKSTCOM        DB      DEVRDND
        DSKSTST DW ?
                DB      8 DUP (0)
        DSKCHRET DB ?
                DW  DEVIOBUF
                DW      ?               ; DOS segment set at Init
DSKSTCNT        DW      1
                DW      0

; Days in year
        YRTAB:
        DB      200,166                 ; Leap year
        DB      200,165
        DB      200,165
        DB      200,165

; Days of each month
        MONTAB:
        DB      31                      ; January
        DB      28                      ; February--reset each 
					; time year changes
        DB      31                      ; March
        DB      30                      ; April
        DB      31                      ; May
        DB      30                      ; June
        DB      31                      ; July
        DB      31                      ; August
        DB      30                      ; September
        DB      31                      ; October
        DB      30                      ; November
        DB      31                      ; December

        IF       IBM = 0
OEM_HANDLER     DD      -1
        END     IF

;WARNING For HIGHMEM version, these two vars must be at the end of the
; Constants segment to prevent them getting overwritten.
        CurrentPDB DW ?
        CreatePDB DB ?          ; flag for creating a process

LEAVEADDR       DW    _LEAVE


; Uninitialized data overlayed by initialization code
; Init code overlaps with data area below

virtual at INITBLOCK
        INBUF DB 128 DUP ?
        CONBUF DB 131 DUP ?              ; The rest of INBUF and console buffer
        TIMEBUF DB 6 DUP ?
        DEVIOBUF DB 2 DUP ?              ; Buffer for I/O under file assignment
        EXITHOLD DD ?

DEVFCB:                ; Uses NAME1, NAME2, NAME3 combined
; WARNING..  do not alter size or relative location of the following 4 items
; without first examining FCB_RENAME
        NAME1 DB 12 DUP ?                ; File name buffer
        ATTRIB DB ?
        NAME2 DB 13 DUP ?
        NAME3 DB 14 DUP ?

        EXTFCB DB ?

; WARNING - the following two items are accessed as a word
        CREATING DB ?
        DELALL DB ?

        FoundDel DB ?

        user_SP DW ?
        user_SS DW ?
        CONTSTK DW ?
        SECCLUSPOS DB ?         ; Position of first sector 
					; within cluster
        DSKERR DB ?
        TRANS DB ?
        READOP DB ?
        THISDRV DB ?
        THISDPB DD ?
        CLUSFAC DB ?

; WARNING - the following two items are accessed as a word
        DRIVESPEC DB ?
        ROOTSTART DB ?

        CLUSSPLIT DB ?
        INSMODE DB ?
        CLUSSAVE DW ?
        CLUSSEC DW ?
        PREREAD DW ?            ; 0 means preread; 1 means optional
        FATBYT DW ?
        DEVPT DD ?
        THISFCB DD ?           ; Address of user FCB

        NEXTADD DW ?
        RECPOS DB 4 DUP ?
        RECCNT DW ?
        LASTPOS DW ?
        CLUSNUM DW ?
        DIRSEC DW ?
        DIRSTART DW ?
        SECPOS DW ?             ; Position of first sector accessed
        VALSEC DW ?             ; Number of valid (previously written)
					; sectors
        BYTSECPOS DW ?          ; Position of first byte within sector
        BYTPOS DB 4 DUP ?                ; Byte position in file of access
        BYTCNT1 DW ?            ; No. of bytes in first sector
        BYTCNT2 DW ?            ; No. of bytes in last sector
        SECCNT DW ?             ; No. of whole sectors
        ENTFREE DW ?
        ENTLAST DW ?
        NXTCLUSNUM DW ?
        GROWCNT DD ?
        CURBUF DD ?
        VOLID DB ?
        NULLDEVPT DD ?
        CINSAV DD ?
        CINDSAV DB ?
        COUTDSAV DB ?
        COUTSAV DD ?
SaveBX  DW      ?
SaveDS  DW      ?
        ConC_spsave DW ?

        exit_code DW ?              ; exit code of last proc.
        exit_type DB ?              ; type of exit...

        IF      IBM
;For 2.00 this pads the DOS so that on a 2 disk IBM PC with no
;CONFIG.SYS file the space taken up by BIOS, DOS, res COMMAND is
;about 24K
IBMPAD  DB      540h DUP(?)
        END     IF

; make those pushes fast!!!
ALIGN 2
        DB      0A0H DUP (?)
        AuxStack DB 0A0h DUP ?
        DSKSTACK DB 0A0h DUP ?        ; Stack space
IOSTACK:

NSS         DW      ?
NSP         DW      ?

end virtual
