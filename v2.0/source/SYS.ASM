; SYS - Copies system programs IBMBIO.COM/IO.SYS and IBMDOS.COM/MSDOS.SYS
;   1.6     05/21/82  Added rev number message
;   1.61    06/04/82  Allow SYS to blank disk TimP at SCP
;   1.70    06/30/82  NON contiguous DOS allowed on 2.00 IBM.  Allows SYS to
;                     1.0 1.1 disks.
;   1.71    07/02/82  Put in CHDIRs to make sure everything done in root dir.
;   1.80    04/26/83  MZ make sys work in small machines; use full 2.0 system
;                     calls
;   1.81    07/22/83  ARR Added check in IBM version for valid FAT ID on
;                     destination because of IBM problem with SYSing to
;                     unformatted disks which are really formatted.
;                     Prints NoDest message for ridic IBM reasons, should
;                     have a better message.

FALSE   =     0
TRUE    =     -1

IBMJAPVER =   FALSE
IBMVER  =     FALSE
MSVER   =     TRUE



DOSVER_LOW      =  0136H              ; Lowest acceptable DOS version number
DOSVER_HIGH     =  020BH              ; Highest acceptable DOS version

if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_DATA
end if


if SEGSEL = S_DATA


        IF      IBMJAPVER
        end if

DEFALT  DB      0
        IF MSVER
BIOSName    DB  "A:\IO.SYS",0
DOSName     DB  "A:\MSDOS.SYS",0
        end if
        IF IBMVER OR IBMJAPVER
BIOSName    DB  "A:\IBMBIO.COM",0
DOSName     DB  "A:\IBMDOS.COM",0
        end if

BIOSInFH    DW      0; file handle of source BIOS
BIOSLenLow  DW  2 dup (0)               ; 32-bit length of BIOS
BIOSLenHigh DW  2 dup (0)               ; 32-bit length of BIOS
BIOSTime    DW  2 dup (0)               ; place to store time of BIOS write
BIOSOutFH   DW      0; fh of BIOS destination

DOSInFH     DW      0; file handle of source DOS
DOSLenLow   DW  2 dup (0)               ; 32-bit length of DOS
DOSLenHigh  DW  2 dup (0)               ; 32-bit length of DOS
DOSTime     DW  2 dup (0)               ; place to store time of DOS write
DOSOutFH    DW      0; fh of DOS destination

AllName     DB "A:\*.*",0

cbBuf       DW      0; number of bytes in buffer
pDOS        DW      0; offset of beginning of DOS in buffer
pDOSEnd     DW      0; offset of end of DOS in buffer

        IF      IBMVER OR IBMJAPVER
BOOT    DW      256 DUP (0)
        IF      IBMJAPVER
LLISTBUF DW     256 DUP (0)
        end if
        end if

        IF      IBMJAPVER
RELOC   DW      1 dup (0)
STARTSECTOR DW  1 dup (0)
        end if

label BUF byte; beginning of area for file reads

end if

if SEGSEL = S_CODE

        ASSUME  CS:DG,DS:DG,ES:DG,SS:DG

        ORG     100H

Start:
        JMP     SHORT CheckVersion

        IF      IBMVER
        DW      BOOT
        end if
HEADER  DB      "Vers 1.81"
CheckVersion:
        PUSH    AX                      ; save drive letter validity
        MOV     AH,GET_VERSION
        INT     21H                     ; get dos version
        XCHG    AH,AL                   ; Turn it around to AH.AL
        CMP     AX,DOSVER_LOW           ; is it too low?
        JB      GOTBADDOS               ; yes, error
        CMP     AX,DOSVER_HIGH          ; too high?
        JBE     OKDOS                   ; yes, go check drive letter
GOTBADDOS:
        MOV     DX,BADVER     ; message to dump
        MOV     AH,STD_CON_STRING_OUTPUT    ; standard output device
        INT     21H
        INT     20H                     ; old style exit for compatability

OKDOS:  POP     AX                      ; get drive validity
        JMP     SHORT SYS               ; go process

ERR0:   MOV     DX,BadParm    ; no drive letter
        MOV     CX,[BadParmLen]
        JMP     DisplayError

ERR1:   MOV     DX,BadDrv     ; drive letter invalid
        MOV     CX,[BadDrvLen]
        JMP     DisplayError

ERR2:   MOV     AL,[DEFALT]               ; get default drive number
        ADD     AL,'A'-1                ; turn into letter
        MOV     [SYSDRV],AL               ; place into middle of message
        MOV     DX,GETSYS
        MOV     CX,[GetSysLen]            ; length for output
        MOV     BX,stderr               ; use stderr
        MOV     AH,WRITE                ; Ask for system disk
        INT     21H
        CALL    GetKeystroke            ; wait for him to type simething
        XOR     AL,AL                   ; valid drive spec now...
SYS:
        CMP     byte [DS:5DH]," "   ; Was file specified?
        JNZ     ERR0                    ; yes, no files are allowed -> error
        CMP     AL,-1                   ; Invalid drive spec?
        JZ      ERR1                    ; yes, must have valid drive -> error
        CMP     byte [DS:5CH],0     ; No drive specified?
        JZ      ERR1                    ; yes, cannot sys to default drive error
        MOV     AH,GET_DEFAULT_DRIVE    ; Get default drive
        INT     21H
        INC     AL                      ; turn from phys drive to logical drive
        MOV     [DEFALT],AL               ; save it for possible printing
        CMP     byte [DS:5CH],AL    ; did he specify the default drive?
        JZ      ERR1                    ; yes, default drive not allowed

        IF  IBMVER              ; Check for "valid" destination
        PUSH    AX
        MOV     AL,byte [DS:5Ch]
        DEC     AL
        MOV     BX,BUF        ; Temp space
        MOV     DX,1                    ; Sector 1 (first sec of FAT)
        MOV     CX,DX                   ; One sector
        INT     25H                     ; Read Fat sector
        POP     AX                      ; Flags
        POP     AX                      ; Real AX
        JC      OKFAT                   ; Don't error here, let a CREATE or
                                        ;   some other call to the dest
                                        ;   generate a more useful INT 24H
                                        ;   error
        CMP     byte [BUF],0F8H
        JAE     OKFAT
        JMP     ERR3
OKFAT:
        end if

        ADD     AL,'A'-1                ; turn into letter
        MOV     [BIOSName],AL             ; twiddle source name
        MOV     [DOSName],AL              ; twiddle source name
        CLD
        MOV     DX,BIOSName   ; source name
        MOV     DI,BIOSInFH   ; pointer to block of data
        CALL    OpenFile
        JC      ERR2                    ; not found, go and try again
        MOV     DX,DOSName    ; source of DOS
        MOV     DI,DOSInFH    ; pointer to block of data
        CALL    OpenFile                ; Look for DOS
        JC      ERR2                    ; not there, go ask for a system disk
        MOV     CX,SP                   ; get lowest available spot
        SUB     CX,0200h+(BUF); leave room for all sorts of things
        MOV     [cbBuf],CX                ; store length away
        CALL    FillMem                 ; load up memory with files

        IF      IBMJAPVER
        CALL    READ_BOOT               ; need to copy boot sector too
        end if

        MOV     AL,byte [DS:5CH]    ; get drive of destination

        IF      IBMJAPVER
        CALL    CHECK_TRAN              ; check for bootable device
        JZ      DOSWRT                  ; ok to boot
        MOV     DX,BadDisk    ; incorrect format to boot
        MOV     CX,[BadDiskLen]
        JMP     DisplayError            ; go error and quit
DOSWRT:
        end if

        ADD     AL,'A'-1                ; convert to letter
        MOV     [BIOSName],AL             ; point names at destination drive
        MOV     [DOSName],AL
        MOV     [AllName],AL              ; look for any files

        MOV     AH,FIND_FIRST           ; look for files
        MOV     DX,AllName    ; path of where to look
        MOV     CX,attr_hidden+attr_system  ; attributes to find
        INT     21H
        JC      PUTSYS                  ; no files - go and copy

        IF      MSVER
        MOV     DL,byte [DS:5CH]    ; get drive number
        MOV     AH,GET_DRIVE_FREESPACE  ; get free space available
        INT     21H
        MUL     CX                      ; Compute size of cluster (secsiz*secperclus)
        XCHG    CX,AX                   ; move it to correct spot
        MOV     DX,BIOSName   ; who to open
        MOV     AX,[BIOSLenLow+2]         ; get low part of size
        MOV     BX,[BIOSLenHigh+2]        ; get high size
        CALL    CHKLEN                  ; open and snoop size
        JNZ     ERR4                    ; Must fit exact so MSDOS is in right place
        MOV     DX,DOSName    ; other guy to open
        MOV     AX,[DOSLenLow+2]          ; get low part of size
        MOV     BX,[DOSLenHigh+2]         ; get high size
        CALL    CHKLEN                  ; open and snoop second size
        JA      ERR4                    ; Must be enough (or too much) space
        end if

        IF      IBMVER OR IBMJAPVER
        MOV     DX,BIOSName   ; open BIOS
        MOV     CX,7                    ; attributes
        MOV     AH,FIND_FIRST
        INT     21H
        JNC     FindDos
Err3J:  JMP     ERR3                    ; not found, go and complain
FindDos:
        MOV     DX,DOSName    ; open DOS
        MOV     AH,FIND_FIRST
        INT     21H
        JC      Err3J                   ; Not found, go complain
        end if

PUTSYS:
        MOV     DX,BIOSName   ; who to change mode
        MOV     CX,0                    ; undo attributes
        MOV     AX,(CHMOD SHL 8) + 1    ; set the attributes
        INT     21h
        MOV     DX,DOSName    ; who to change mode
        MOV     CX,0                    ; undo attributes
        MOV     AX,(CHMOD SHL 8) + 1    ; set the attributes
        INT     21h
        MOV     DX,BIOSName   ; destination of BIOS
        MOV     CX,7                    ; fancy attributes
        MOV     AH,CREAT                ; make a new one
        INT     21h
        MOV     [BIOSOutFH],AX            ; save handle
        MOV     DX,DOSName    ; destination of DOS
        MOV     AH,CREAT                ; make a new one
        INT     21h
        MOV     [DOSOutFH],AX             ; save handle
Copy:
        CALL    DumpMem                 ; flush out memory
        MOV     AX,[DOSLenHigh]           ; more DOS?
        OR      AX,[DOSLenLow]            ; more low dos
        OR      AX,[BIOSLenHigh]          ; more high BIOS
        OR      AX,[BIOSLenLow]           ; more low BIOS
        JZ      AllDone                 ; nope, all done
        CALL    FillMem                 ; reload world
        JMP     Copy
ERR4:
        MOV     DX,BadSiz
        MOV     CX,[BadSizLen]
        JMP     DisplayError
AllDone:
        MOV     CX,[BIOSTime]             ; get time and date
        MOV     DX,[BIOSTime+2]
        MOV     BX,[BIOSOutFH]            ; where to stuff the time
        MOV     AX,(FILE_TIMES SHL 8) + 1
        INT     21h
        MOV     AH,CLOSE
        INT     21h

        MOV     CX,[DOSTime]              ; get time and date
        MOV     DX,[DOSTime+2]
        MOV     BX,[DOSOutFH]             ; where to stuff the time
        MOV     AX,(FILE_TIMES SHL 8) + 1
        INT     21h
        MOV     AH,CLOSE
        INT     21h

        IF      IBMVER OR IBMJAPVER
        CALL    PUTBOOT                 ; copy the boot sector also
        end if

        MOV     DX,Done       ; all finished message
        MOV     CX,[DoneLen]
        XOR     AL,AL                   ; ok error code
SERROR:
        PUSH    AX
        MOV     BX,stderr
        MOV     AH,WRITE                ; convenient place to display message
        INT     21H
        POP     AX
ErrorExit:
        MOV     AH,EXIT                 ; bye and return error code
        INT     21h

DisplayError:
        MOV     AL,1
        JMP     SERROR
FillMem:
        MOV     CX,[cbBuf]                ; get length of buffer
        MOV     BX,[BIOSInFH]             ; get bios source handle
        MOV     DX,BUF        ; point to beginning of buffer
        PUSH    CX                      ; save away total length
        CMP     [BIOSLenHigh],0           ; > 64K to read?
        JA      UseCX                   ; use CX
        CMP     [BIOSLenLow],CX           ; more left to read?
        JA      UseCX                   ; use CX
        MOV     CX,[BIOSLenLow]           ; move new
UseCX:
        MOV     AH,READ
        INT     21h                     ; read in what we can
        ADD     DX,AX                   ; update pointer for DOS Read
        MOV     [pDOS],DX                 ; point to beginning of DOS
        SUB     [BIOSLenLow],AX           ; decrement remaining
        SBB     [BIOSLenHigh],0           ; do 32 bit
        POP     CX                      ; get original length
        SUB     CX,AX                   ; this much is left

        MOV     BX,[DOSInFH]              ; get bios source handle
        CMP     [DOSLenHigh],0            ; > 64K to read?
        JA      UseCXDOS                ; use CX
        CMP     [DOSLenLow],CX            ; more left to read?
        JA      UseCXDOS                ; use CX
        MOV     CX,[DOSLenLow]            ; move new
UseCXDOS:
        MOV     AH,READ
        INT     21h                     ; read in what we can
        ADD     DX,AX                   ; update pointer for DOS Read
        MOV     [pDOSEnd],DX              ; point to End of dos DOS
        SUB     [DOSLenLow],AX            ; decrement remaining
        SBB     [DOSLenHigh],0            ; do 32 bit arithmetic
        return

OpenFile:
        MOV     AX,(OPEN SHL 8) + 0     ; open for reading only
        INT     21H                     ; Look for BIOS
        retc                            ; not found, go and try again
        STOSW                           ; stash away handle
        MOV     BX,AX                   ; get ready for seeks
        MOV     AX,(LSEEK SHL 8) + 2    ; seek relative to eof
        XOR     CX,CX                   ; zero offset
        XOR     DX,DX                   ; zero offset
        INT     21h                     ; get offsets
        STOSW                           ; save low part of size
        STOSW                           ; save low part of size
        MOV     AX,DX
        STOSW                           ; save high part of size
        STOSW                           ; save high part of size
        XOR     DX,DX                   ; zero offset
        MOV     AX,(LSEEK SHL 8) + 0    ; seek relative to beginning
        INT     21h
        MOV     AX,(FILE_TIMES SHL 8) + 0
        INT     21h                     ; get last write times
        MOV     AX,CX
        STOSW                           ; save time
        MOV     AX,DX
        STOSW                           ; save date
        return

ERR3:
        MOV     DX,NoDest
        MOV     CX,[NoDestLen]
        JMP     DisplayError

DumpMem:
        MOV     DX,BUF        ; get offset of bios start
        MOV     CX,[pDOS]                 ; beginning of next guy
        SUB     CX,DX                   ; difference is length
        JZ      DumpDos                 ; no bios to move
        MOV     BX,[BIOSOutFH]            ; where to output
        MOV     AH,WRITE
        INT     21h                     ; wham
DumpDos:
        MOV     DX,[pDOS]                 ; beginning of dos
        MOV     CX,[pDOSEnd]              ; end of dos
        SUB     CX,DX                   ; difference is length
        retz                            ; if zero no write
        MOV     BX,[DOSOutFH]             ; where to output
        MOV     AH,WRITE
        INT     21h                     ; wham
        ret

        IF      MSVER
CHKLEN:
; CX has size of cluster, DX has pointer to file name
; Returns with flags set on (size of file) - (size of hole)
        PUSH    AX                      ; old size low
        PUSH    BX                      ; old size high
        PUSH    CX                      ; old cluster size
        MOV     AH,FIND_FIRST
        MOV     CX,7                    ; attributes to search for
        INT     21H
        JC      ERR3                    ; cannot find file, error
        POP     CX                      ; get cluster size back
        MOV     DX,[DS:80h+find_buf.find_buf_size_h] ; get destination size high
        MOV     AX,[DS:80h+find_buf.find_buf_size_l] ; get size low
        ADD     AX,CX                   ; add cluster size
        ADC     DX,0                    ; 32 bit add
        SUB     AX,1                    ; adding CLUSSIZE-1
        SBB     DX,0                    ; 32 bit dec
        DIV     CX                      ; compute new cluster size
        POP     DX                      ; get old high
        POP     BX                      ; get old low
        PUSH    AX                      ; save away dividend
        MOV     AX,BX                   ; put into correct register
        ADD     AX,CX                   ; do the same as above (+CLUSSIZE-1)/CLUSSIZE
        ADC     DX,0                    ; 32 bit add
        SUB     AX,1                    ; adding CLUSSIZE-1
        SBB     DX,0                    ; 32 bit dec
        DIV     CX                      ; compute old cluster size
        POP     DX                      ; get new size
        CMP     AX,DX                   ; is old >= new?
        return
        end if

        IF      IBMJAPVER
PUTBOOT:
        CALL    READ_LLIST              ; Get the list sector and set new boot sector
        MOV     AL,byte [DS:5CH]
        DEC     AL                      ; A=0
        MOV     CX,1
        XOR     DX,DX
        MOV     BX,BOOT
        INT     26H                     ; Write out new boot sector
        POPF
        CALL    WRITE_LLIST             ; Make and write out new list sector
        RET
        end if

        IF      IBMVER
PUTBOOT:
        MOV     AH,GET_DPB
        MOV     DL,byte [DS:5Ch]    ; Target drive
        INT     21H
ASSUME  DS:NOTHING
        MOV     AL,[BX+16H]             ; Media byte
        PUSH    CS
        POP     DS
ASSUME  DS:DG
        CMP     AL,0FEH
        JB      RET1
        TEST    AL,1
        JZ      GOTBOOT
        MOV     BX,BOOT
        MOV     word [BX+17],112    ; Set number of dir entries
        MOV     word [BX+19],2*8*40 ; Set number of sectors
        INC     byte [BX+21]        ; Media = ff
        INC     word [BX+26]        ; Number of heads = 2

GOTBOOT:
        MOV     AL,byte [DS:5Ch]
        DEC     AL
        MOV     BX,BOOT       ; Boot sector
        XOR     DX,DX                   ; Sector 0
        MOV     CX,DX
        INC     CX                      ; One sector
        INT     26H                     ; Write out 8 sector boot sector
        POP     AX                      ; Flags
RET1:   RET
        end if

        IF      IBMJAPVER
READ_BOOT:
        MOV     AL,[DEFALT]
        DEC     AL                      ; A=0
        MOV     CX,1
        XOR     DX,DX
        MOV     BX,BOOT
        INT     25H
        POPF
        MOV     AX,[BOOT+108H]          ; Get old first sector of data
        MOV     [RELOC],AX
        RET

READ_LLIST:
        MOV     AL,byte [DS:5CH]
        DEC     AL                      ; A=0
        MOV     CX,1
        MOV     DX,[STARTSECTOR]
        MOV     BX,LLISTBUF
        INT     25H
        POPF
        RET

WRITE_LLIST:
        MOV     AX,[STARTSECTOR]
        MOV     DX,AX
        SUB     AX,[RELOC]              ; True reloc factor
        MOV     CL,byte [LLISTBUF+0CH]  ; Number of entries needing reloc
        XOR     CH,CH
        JCXZ    NO_RELOCS
        MOV     BX,LLISTBUF + 10H
RELLOOP:
        ADD     word [BX+2],AX
        ADD     BX,10H
        LOOP    RELLOOP
NO_RELOCS:
        MOV     AL,byte [DS:5CH]
        DEC     AL                      ; A=0
        MOV     CX,1
        MOV     BX,LLISTBUF
        INT     26H
        POPF
        RET

CHECK_TRAN:
; All registers preserved. Returns zero if SYS OK, NZ if SYS FAIL
;  AL is drive (1=A,...) AL=0 is not valid

        PUSH    BX
        PUSH    AX
        PUSH    DS
        MOV     DL,AL
        MOV     AH,GET_DPB
        INT     21H
        MOV     AX,[BX+dpb.dpb_first_sector]    ; Get new first sector of data
        MOV     BH,[BX+dpb.dpb_media]
        POP     DS
        MOV     [STARTSECTOR],AX
        MOV     [BOOT+108H],AX          ; Set new start of data in boot
        POP     AX
        PUSH    AX
        MOV     BL,AL
        INT     11H                     ; IBM EQUIP CALL
        ROL     AL,1
        ROL     AL,1
        AND     AL,3
        JNZ     NOT_SINGLE
        INC     AL
NOT_SINGLE:
        INC     AL                      ;  AL is now MAX floppy #
        CMP     BL,AL
        POP     AX
        JBE     CHECK_FLOP              ;  Is a floppy
        XOR     BL,BL                   ;  Is Hard file
        POP     BX
        RET

CHECK_FLOP:
        CMP     BH,0FBH                 ;  Only floppy that boots
        POP     BX
        RET
        end if

GetKeystroke:
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8) + STD_CON_INPUT_NO_ECHO
        INT     21H
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8) + 0
        INT     21H

        return

end if
