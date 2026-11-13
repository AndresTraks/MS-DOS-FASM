; Converted to fasm.  The six SEGMENT AT blocks here name places in low
; memory that no program lays down -- the interrupt vectors, the ROM BIOS
; data area at 40H, the video buffer -- so each is a VIRTUAL block, which
; declares the names and writes nothing.  MASM counted a name in a SEGMENT
; AT from the segment's own base, so the blocks are VIRTUAL AT 0 and the
; names are the offsets they were; the address each segment is at is the
; equate above it, which is what the segment's name stood for where a
; program loaded a register with it.
;
; STACK and DATA are fasm's own words, so those two are STACK_ and DATA_;
; nothing reads STACK_ and KEYB loads a register with DATA_ to reach the
; keyboard flags.
;
;
; Five of KEYB's ten modules read this, so the declarations are laid
; out once and the guard the other headers use says when: a MATCH that
; holds only while the name it asks about has no value of its own.
match =DSEG_LAID_OUT, DSEG_LAID_OUT
{
DSEG_LAID_OUT equ 1
;---Revised 8-17-84 FOR KBX	(ADDED ADDITIONAL KEYBOARD FLAG - KB_FLAG_3)
;----------------------------------------
;	 0286 INTERRUPT LOCATIONS (READ):
;----------------------------------------
ABS0 = 0			; where the segment is
virtual at 0
label STG_LOC0 byte
	ORG 2*4
label NMI_PTR word
	ORG 5*4
label INT5_PTR word
	ORG 8*4
label INT_ADDR word
label INT_PTR dword
	ORG 10H*4
label VIDEO_INT word
	ORG 13H*4			; NEW FDISK
label ORG_VECTOR dword
	ORG 18H*4
label BASIC_PTR word
	ORG 19H*4
label BOOT_VEC dword
label BOOT_VECTOR dword
	ORG 1DH*4
label PARM_PTR dword  ; POINTER TO VIDEO PARMS
	ORG 1EH*4
label DISK_POINTER dword
	ORG 01FH*4
label EXT_PTR dword
	ORG 40H*4			; DISKETTE POINTER
label DISK_VECTOR dword
       ORG 41H*4
label HF_TBL_VEC dword
	ORG 46H*4
label HF1_TBL_VEC dword
	ORG 70H*4
label SLAVE_INT_PTR dword
label RTC_INT_VEC dword  ; REAL TIME CLOCK INT
	ORG 76H*4			; FIXED DISK INTERRUPT VECTOR
label HDISK_INT dword
	ORG	400H
label DATA_AREA byte  ;ABSOLUTE LOCATION OF DATA SEGMENT
label DATA_WORD word
	ORG	0500H
label MFG_TEST_RTN
	ORG	7C00H
label BOOT_LOCN
end virtual
PAGE
;------------------------------------------------
; STACK -- USED DURING INITIALIZATION ONLY	:
;------------------------------------------------
STACK_ = 30H			; where the segment is
virtual at 0
	rw 128
label TOS word
end virtual
;----------------------------------------
;	ROM BIOS DATA AREAS		:
;----------------------------------------
DATA_ = 40H			; where the segment is
virtual at 0
;DATA_BASE	 LABEL	 BYTE
RS232_BASE	rw 4  ; ADDRESSES OF RS232 ADAPTERS
PRINTER_BASE	rw 4  ; ADDRESSES OF PRINTERS
EQUIP_FLAG	rw 1  ; INSTALLED HARDWARE
MFG_TST 	rb 1  ; INITIALIZATION FLAG
MEMORY_SIZE	rw 1  ; MEMORY SIZE IN K BYTES
MFG_ERR_FLAG	rb 1  ; SCRATCHPAD FOR MANUFACTURING
		rb 1  ; ERROR CODES
PAGE
;----------------------------------------
;	KEYBOARD DATA AREAS		:
;----------------------------------------
KB_FLAG 	rb 1
KB_FLAG_1	rb 1  ; SECOND BYTE OF KEYBOARD STATUS
ALT_INPUT	rb 1  ; STORAGE FOR ALTERNATE KEYPAD ENTRY
BUFFER_HEAD	rw 1  ; POINTER TO HEAD OF KEYBOARD BUFFER
BUFFER_TAIL	rw 1  ; POINTER TO TAIL OF KEYBOARD BUFFER
KB_BUFFER	rw 16  ; ROOM FOR 15 ENTRIES
label KB_BUFFER_END word

;------ HEAD = TAIL INDICATES THAT THE BUFFER IS EMPTY

;----------------------------------------
;	DISKETTE DATA AREAS		:
;----------------------------------------
SEEK_STATUS	rb 1  ; DRIVE RECALIBRATION STATUS
					; BIT 3-0 = DRIVE 3-0 NEEDS RECAL
					; BEFORE NEXT SEEK IF BIT IS = 0
MOTOR_STATUS	rb 1  ; MOTOR STATUS
					; BIT 3-0 = DRIVE 3-0 IS CURRENTLY
					;   RUNNING
					; BIT 7 = CURRENT OPERATION IS A WRITE,
					;   REQUIRES DELAY
MOTOR_COUNT	rb 1  ; TIME OUT COUNTER FOR DRIVE TURN OFF
DISKETTE_STATUS rb 1  ; RETURN CODE STATUS BYTE
label CMD_BLOCK byte
label HD_ERROR byte
NEC_STATUS	rb 7  ; STATUS BYTES FROM NEC
PAGE
;----------------------------------------
;	VIDEO DISPLAY DATA AREA 	:
;----------------------------------------
CRT_MODE	rb 1  ; CURRENT CRT MODE
CRT_COLS	rw 1  ; NUMBER OF COLUMNS ON SCREEN
CRT_LEN 	rw 1  ; LENGTH OF REGEN IN BYTES
CRT_START	rw 1  ; STARTING ADDRESS IN REGEN BUFFER
CURSOR_POSN	rw 8  ; CURSOR FOR EACH OF UP TO 8 PAGES
CURSOR_MODE	rw 1  ; CURRENT CURSOR MODE SETTING
ACTIVE_PAGE	rb 1  ; CURRENT PAGE BEING DISPLAYED
ADDR_6845	rw 1  ; BASE ADDRESS FOR ACTIVE DISPLAY CARD
CRT_MODE_SET	rb 1  ; CURRENT SETTING OF THE 3X8 REGISTER
CRT_PALLETTE	rb 1  ; CURRENT PALLETTE SETTING COLOR CARD
PAGE
;----------------------------------------
;	POST DATA AREA			:
;----------------------------------------
IO_ROM_INIT	rw 1  ; PNTR TO OPTIONAL I/O ROM INIT ROUTINE
IO_ROM_SEG	rw 1  ; POINTER TO IO ROM SEGMENT
INTR_FLAG	rb 1  ; FLAG TO INDICATE AN INTERRUPT HAPPEND
;----------------------------------------
;	TIMER DATA AREA 		:
;----------------------------------------
TIMER_LOW	rw 1  ; LOW WORD OF TIMER COUNT
TIMER_HIGH	rw 1  ; HIGH WORD OF TIMER COUNT
TIMER_OFL	rb 1  ; TIMER HAS ROLLED OVER SINCE LAST READ
;----------------------------------------
;	SYSTEM DATA AREA		:
;----------------------------------------
BIOS_BREAK	rb 1  ; BIT 7=1 IF BREAK KEY HAS BEEN HIT
RESET_FLAG	rw 1  ; WORD=1234H IF KEYBOARD RESET UNDERWAY
PAGE
;----------------------------------------
;	HARD FILE DATA AREAS		:
;----------------------------------------
DISK_STATUS1	rb 1
HF_NUM		rb 1
CONTROL_BYTE	rb 1
PORT_OFF	rb 1
;------------------------------------------------------
;	PRINTER AND RS232 TIME-OUT VARIABLES	      :
;------------------------------------------------------
PRINT_TIM_OUT	rb 4
RS232_TIM_OUT	rb 4
;----------------------------------------
;	ADDITIONAL KEYBOARD DATA AREA	:
;----------------------------------------
BUFFER_START	rw 1
BUFFER_END	rw 1
;---------------------------------------
;	ADDITIONAL FLOPPY DATA	       ;
;---------------------------------------
	ORG	8BH
LASTRATE	rb 1  ; LAST DATA RATE SELECTED
PAGE
;---------------------------------------
;	ADDITIONAL HARD FILE DATA      :
;---------------------------------------
	ORG	8CH
HF_STATUS	rb 1  ; STATUS REGISTER
HF_ERROR	rb 1  ; ERROR REGISTER
HF_INT_FLAG	rb 1  ; HARD FILE INTERRUPT FLAG
HF_CNTRL	rb 1  ; COMBO HARD FILE/FLOPPY CARD BIT 0=1
;----------------------------------------
;	ADDITIONAL DISKETTE AREA       :
;----------------------------------------
	ORG	90H
label DSK_STATE byte
		rb 1  ; DRIVE 0 MEDIA STATE
		rb 1  ; DRIVE 1 MEDIA STATE
		rb 1  ; DRIVE 0 OPERATION START STATE
		rb 1  ; DRIVE 1 OPERATION START STATE
DSK_TRK 	rb 1  ; DRIVE 0 PRESENT CYLINDER
		rb 1  ; DRIVE 1 PRESENT CYLINDER
		rb 1  ; RESERVED
;----------------------------------------				AEV
;	ADDITIONAL KEYBOARD FLAG FOR KBX:				AEV
;----------------------------------------				AEV
	ORG	96H			;				AEV
KB_FLAG_3	rb 1  ;				AEV
;----------------------------------------
;	ADDITIONAL KEYBOARD LED FLAG	:
;----------------------------------------
	ORG	97H
KB_FLAG_2	rb 1
PAGE
;----------------------------------------
;	REAL TIME CLOCK DATA AREA	:
;----------------------------------------
	ORG	98H
USER_FLAG	rw 1  ; OFFSET ADDR OF USERS WAIT FLAG
USER_FLAG_SEG	rw 1  ; SEG ADDR OF USER WAIT FLAG
RTC_LOW 	rw 1  ; LOW WORD OF USER WAIT FLAG
RTC_HIGH	rw 1  ; HIGH WORD OF USER WAIT FLAG
RTC_WAIT_FLAG	rb 1  ; WAIT ACTIVE FLAG
end virtual
;----------------------------------------
;	EXTRA DATA AREA 		:
;----------------------------------------
XXDATA = 50H			; where the segment is
virtual at 0
STATUS_BYTE	rb 1
end virtual
;----------------------------------------
;	VIDEO DISPLAY BUFFER		:
;----------------------------------------
VIDEO_RAM = 0B800H			; where the segment is
virtual at 0
label REGEN byte
label REGENW word
	rb 16384
end virtual
}
