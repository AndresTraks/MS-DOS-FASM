
;Get/Set Extended Attrbute Equates

;The following equates are for EA types

EAISUNDEF	      equ  00H	     ; undefined
EAISLOGICAL	      equ  01H	     ; logical (0 or 1), 1 byte
EAISBINARY	      equ  02H	     ; binary integer 1, 2, or 4 bytes
EAISASCII	      equ  03H	     ; ASCII , 0 to 128 bytes
EAISDATE	      equ  04H	     ; DOS file date format, 2 bytes
EAISTIME	      equ  05H	     ; DOS file time format, 2 bytes

;The following equates are for EA flags

EASYSTEM	      equ  8000H     ; system defined, bultin
EAREADONLY	      equ  4000H     ; read-only , cannot be changed
EAHIDDEN	      equ  2000H     ; hidden from ATTRIB
EACREATEONLY	      equ  1000H     ; settable only at create time

;The following equates are for EA failure reason code (set by DOS)

EARCSUCCESS	      equ  00H	     ; success
EARCNOTFOUND	      equ  01H	     ; name not found
EARCNOSPACE	      equ  02H	     ; no space to hold name or value
EARCNOTNOW	      equ  03H	     ; name can't be set on this function
EARCNOTEVER	      equ  04H	     ; name can't be set
EARCUNDEF	      equ  05H	     ; name known to IFS but not supported
EARCDEFBAD	      equ  06H	     ; EA definition bad (type,length, etc)
EARCACCESS	      equ  07H	     ; EA access denied
EARCBADVAL	      equ  08H	     ; bad value
EARCDEVERROR	      equ  09H	     ; device error
EARCUNKNOWN	      equ  0FFFFH    ; unknown cause


;The following equates are for EA file type

EAEXISTING	     equ  00H	    ; existing file
EARTL		     equ  02H	    ; right to left
EAEXECUTABLE	     equ  03H	    ; executable program
EAINSTALLABLE	     equ  04H	    ; installable executable program
EAOVERLAY	     equ  05H	    ; program overlay
EADEV_DRIVER	     equ  06H	    ; device driver
EAIFS_DRIVER	     equ  07H	    ; ifs deriver




By_Create	      equ  0000010B	     ; set by Extended Open (create)
BY_XA		      equ  0000100B	     ; set by Get/Set XA by Handle

;Extended Attribute Structure

; Filled in where it stands -- PRINT_R asks the extended attribute
; calls for the code page with one -- so the fields are the macro's
; arguments, each defaulting to what the structure declares.
STRUC EA EA_TYPE_=0, EA_FLAGS_=0, EA_RC_=0, EA_NAMELEN_=0, \
	 EA_VALLEN_=0, EA_NAME_=0
{
.EA_TYPE     DB	      EA_TYPE_		      ; type
.EA_FLAGS    DW	      EA_FLAGS_		      ; flags
.EA_RC	    DB	      EA_RC_		      ; reason code
.EA_NAMELEN  DB	      EA_NAMELEN_		      ; name length
.EA_VALLEN   DW	      EA_VALLEN_		      ; value length
.EA_NAME     DB	      EA_NAME_		      ; name
}
match =EA_LAID_OUT, EA_LAID_OUT
{
    EA_LAID_OUT equ 1
    virtual at 0
      EA EA
      sizeof.EA = $ - EA
    end virtual
}


;Query Extended Attribute list

; and the same of the query list, which PRINT_R lays down beside it
STRUC QEA QEA_TYPE_=0, QEA_FLAGS_=0, QEA_NAMELEN_=0, QEA_NAME_=0
{
.QEA_TYPE     DB        QEA_TYPE_		       ; type
.QEA_FLAGS    DW        QEA_FLAGS_		       ; flags
.QEA_NAMELEN  DB        QEA_NAMELEN_		       ; name length
.QEA_NAME     DB        QEA_NAME_		       ; name
}
match =QEA_LAID_OUT, QEA_LAID_OUT
{
    QEA_LAID_OUT equ 1
    virtual at 0
      QEA QEA
      sizeof.QEA = $ - QEA
    end virtual
}

