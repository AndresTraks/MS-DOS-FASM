STRUC PAGE_FRAME_STRUC PAGE_SEG_=0, PAGE_NUM_=0
{

  .PAGE_SEG	DW	PAGE_SEG_ ;EMS page segment					     ;AN000;
  .PAGE_NUM	DW	PAGE_NUM_ ;EMS page number (only one page is used)						 ;AN000;

}
match =PAGE_FRAME_STRUC_LAID_OUT, PAGE_FRAME_STRUC_LAID_OUT
{
    PAGE_FRAME_STRUC_LAID_OUT equ 1
    virtual at 0
      PAGE_FRAME_STRUC PAGE_FRAME_STRUC 0, 0
      sizeof.PAGE_FRAME_STRUC = $ - PAGE_FRAME_STRUC
    end virtual
}
STRUC SUB_LIST DATA_OFF_=0, DATA_SEG_=0, MSG_ID_=0, FLAGS_=0, MAX_WIDTH_=0, MIN_WIDTH_=0, PAD_CHAR_=0
{
	DB	11			;							   ;AN000;
	DB	0			;							   ;AN000;
.DATA_OFF DW	DATA_OFF_ ; offset of data to be inserted 			   ;AN000;
.DATA_SEG DW	DATA_SEG_ ; offset of data to be inserted 			   ;AN000;
.MSG_ID	DB	MSG_ID_ ; n of %n						   ;AN000;
.FLAGS	DB	FLAGS_ ; Flags 						   ;AN000;
.MAX_WIDTH DB	MAX_WIDTH_ ; Maximum field width					   ;AN000;
.MIN_WIDTH DB	MIN_WIDTH_ ; Minimum field width					   ;AN000;
.PAD_CHAR DB	PAD_CHAR_ ; character for pad field				   ;AN000;
}
match =SUB_LIST_LAID_OUT, SUB_LIST_LAID_OUT
{
    SUB_LIST_LAID_OUT equ 1
    virtual at 0
      SUB_LIST SUB_LIST 0, 0, 0, 0, 0, 0, 0
      sizeof.SUB_LIST = $ - SUB_LIST
    end virtual
}
	Page 84,132 ;

TITLE	FASTINIT - initialization code for FASTOPEN  (May 13, 1988)

;ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
; The entire Fastopen component is divided into 5 modules.  They are:
; Fastopen initialization routine-1, Fastopen initialization routine-2,
; Fastopen which manages the directory/file cache buffers, the Fastseek
; which manages the cluster information cache buffers and the
; cache buffer which holds both directory and cluster information.
;
; These modules resides in different segments for the reason that they can
; be overlayed conditionally, depending on the user request.  For example
; initially all segments are loaded into the memory.  If fastopen reature is
; not requested, the segment which contains Fastseek will be overlayed over
; original Fastopen to save space.  Segmentation is also usefull when Fastopen
; and Fstseek need to copy into Expanded memory.  Following figure shows
; memory map of the FastOpen.
;
;		   Modules	      Segment
;
;	      ฺ-------------------ฟ
;	      ณ      MAIN	  ณ   CSEG_MAIN
;	      ร-------------------ด
;	      ณ   FASTINIT1	  ณ   CSEG_MAIN
;	      ร-------------------ด
;	      ณ 		  ณ
;	      ณ    FASTOPEN	  ณ   CSEG_OPEN
;	      ณ 		  ณ
;	      ร-------------------ด
;	      ณ 		  ณ
;	      ณ    FASTSEEK	  ณ   CSEG_SEEK
;	      ณ 		  ณ
;	      ร-------------------ด
;	      ณ   FASTINIT2	  ณ   CSEG_INIT
;	      ร-------------------ด
;	      ณ 		  ณ
;	      ณ   NAME AND	  ณ
;	      ณ   EXTENT	  ณ
;	      ณ   CACHE BUFFERS   ณ   CSEG_INIT
;	      ณ 		  ณ
;	      ภ-------------------ู
;
; MAIN:       This module provides DOS entry point into FASTOPEN. It also
;	      dispatch various Fastopen and Fastseek functions.  This module is
;	      in the file FASTOPEN.asm
;
; FASTINIT-1: This module is called INIT_TREE which is also a part of the
;	      Cseg_Main segment.  This basically initializes both
;	      Name and Extent drive headers, and sets up name and extent
;	      cache buffers.  This module can be found in the file
;	      FASTINIT.asm
;
; FASTINIT-1: This module is called INIT which is part of the  Cseg_Init
;	      segment.	This module parses the user commad, check memory
;	      requirements, overlay Fastopen and Fastseek code and finally
;	      installs the Fastopen to be stay resident.  This module is
;	      eventually overlayed by the cache buffers created during the
;	      buffer initialization by FASTINIT-1 ( See INIT_TREE)
;	      This module can be found in FASTINIT.asm
;
; FASTOPEN:   This module is a collection of four Fastopen functions which
;	      manage the File/Directory cache buffers. These functions are
;	      in the file FASTOPEN.asm
;
; FASTSEEK:   This module is a collection of six FastSeek functions which
;	      manage queues associated with the cluster information
;	      cache buffers.  This module is found in the file FASTSEEK.asm.
;
;
; Fastopen Code and Cache buffer Relocation
; -----------------------------------------
;    If user specifies both  n and m in the user command  and /x, then
; Cseg_Open, Cseg_Seek and Cseg_Init will be copied into a 16K page of the
; Expanded Memory.  If only n is specified, then Cseg_Open and Cseg_Init will
; be copied.  If only m is specified, then Cseg_Seek and Cseg_init will be
; copied.  After this the total size of the segments transferred will be
; deblocked from the low memory to save available user space.
;
;   If /x is not specified and only n is specified, then the Cseg_Init will
; moved over to Cseg_Seek which is followed by a deblock of memory.  If only
; m is specified, then Cseg_Seek will moved over to Cseg_Open and the
; Cseg_Init will be moved over to Cseg_Seek then deblocks the size Cseg_Open.
;
; WARNING: After every move you have to recalculate the Seg ID of moved
;	   modules depending on how far it has been displaced and then
;	   replace the Seg ID in the jump vectors used for accessing
;	   functions in the moved modules.  A wrong Seg ID can cause
;	   instant System CRASH ...@%+(@!$#@@*&...
;
; Future Enhancements:
;
;   1.	Modify Fastopen so that it can be run on removable media (Diskette).
;	At present only fixed disk is supported.
;
;   2.	Allocate all Extent buffers during initialization. Now they are
;	done in run time.  This may avoid using flags (-2) for discontinuous
;	buffers. Using (-2) requires buffers be filled with '0's during PURGE.
;
;   3.	Mark the LRU extent every time buffer is changed, so that the
;	the buffers need not be searched during buffer recycling
;
;   4;	Currently Fastopen code and cache is kept in one 16K page of the
;	Extended Memory.  This puts a restriction on the size of the cache
;	buffer available in EMS usually about 8K.  This can be avoided by
;	keeping code and cache buffers in two seperated pages, so that maximum
;	of 16K is available for cache buffers.
;ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
;
;IF1
;    %OUT ASSEMBLING: FASTINIT - FASTOPEN initialization
;ENDIF
name	FASTINIT

.XCREF
.XLIST


TRUE	   EQU	  0FFFFh									   ;AN000;
FALSE	   EQU	  0										   ;AN000;

DBCS	    =	  FALSE 									   ;AN000;
Installed   =	  TRUE										   ;AN000;

if ~ defined DEBUG
    DEBUG	= FALSE
end if

include 'DOSMAC.INC'              ;AN000;
include 'VECTOR.INC'              ;AN000;
include 'FILEMODE.INC'              ;AN000;
include 'MULT.INC'              ;AN000;
include 'VERSION.INC'

.LIST
.CREF

include 'FASTSEGS.INC'              ;AN000;
include 'FASTOPEN.INC'              ;AN000;
include 'SYSCALL.INC'  ;									   ;AN000;

;-----------------------------------------------------------------------
;		       EQUATES
;-----------------------------------------------------------------------
Top_mem 	       EQU    02h	      ;Top of memory index in PSP			  ;AN000;
Min_entry_num	       EQU    10	      ;minimum name cache entries			   ;AN000;
Max_entry_num	       EQU    999	      ;maximum name cache entries			   ;AN000;
Default_names	       EQU    34	      ;default name cache entries			   ;AN000;
DEBUG		       =    0 	      ;for callinstall					   ;AN000;
Len_source_xname       EQU    4 	      ;used for xname translate 			   ;AN000;
No_siblings	       equ    (-1)	;indicate no siblings				   ;AN000;
No_child	       equ    (-1)	;indicate no children				   ;AN000;
No_backward	       equ    (-1)	;no backward pt yet				   ;AN000;
Max_drives	       EQU    24	      ;maximum number of drives allowed 	     ;AN000;


; ----------------- MESSAGE EQUATES -------------------------------------

Not_enough_mem	       EQU	2								   ;AN000;
Invalid_switch	       EQU	3								   ;AN000;
Install1	       EQU	4								   ;AN000;
Already_install        EQU	5								   ;AN000;
Incorrect_param        EQU	6								   ;AN000;
Too_many_entries       EQU	7								   ;AN000;
Dup_drive	       EQU	8								   ;AN000;
Invalid_extent	       EQU	11								   ;AN000;
Invalid_name	       EQU	12								   ;AN000;
Ems_failed_fastinit	       EQU	13								   ;AN000;
Ems_not_install        EQU	14								   ;AN000;
Invalid_drive	       EQU	15								   ;AN000;
No_page_space	       EQU	16								   ;AN000;
Bad_Use_Message        EQU	17
Many_Ext_Entries       EQU	18
Many_Name_Entries      EQU	19


;------------ E M S SUPPORT EQUATES -------------------------------

EMS_GET_STATUS	       EQU	40H								   ;AN000;
EMS_GET_NUM_PAGES      EQU	42H								   ;AN000;
EMS_ALLOC_PAGES        EQU	43H								   ;AN000;
EMS_MAP_HANDLE	       EQU	44H								   ;AN000;
EMS_GET_VERSION        EQU	46H								   ;AN000;
EMS_SAVE_STATE	       EQU	47H								   ;AN000;
EMS_RESTORE_STATE      EQU	48H								   ;AN000;;AN000;
EMS_PAGE_SIZE	       EQU	4FH								   ;AN000;;AN000;
EMS_2F_HANDLER	       EQU	1BH								   ;AN000;;AN000;

IF	NOT IBMCOPYRIGHT

EMS_GET_COUNT	       EQU	5801H

ELSE 

EMS_GET_COUNT	       EQU	5800H								   ;AN000;

end if

EMS_GET_FRAME_ADDR     EQU	5800H								   ;AN000;
EMS_HANDLE_NAME        EQU	53H
EMS_INT 	       EQU	67H								   ;AN000;
SINGLE_SEGMENT	       EQU	 1								   ;AN000;


;-------------------- STRUCTURES ---------------------------------


BUFFER_ENTRY_SIZE      EQU    sizeof.PAGE_FRAME_STRUC



;-------------------------------------------------------------------------------
; Following two segments are used to define external variable that
; are defined in two other segments.
;-------------------------------------------------------------------------------

if SEGSEL = S_CSEG_OPEN; Cseg_Open segment
;  EXTRN   Open_name_cache_seg:word
;  EXTRN   Open_Name_Drive_Buff:word
;  EXTRN   End_Open:byte
;  EXTRN   Chk_Flag:word
;  EXTRN   VECTOR_LOOKUP:dword	  ; jump vector inside Cseg_Main to make
				; a FAR call to Fopen LookUp function within
				; the segment
end if


if SEGSEL = S_CSEG_SEEK; Cseg_Seek segment
;  EXTRN   Seek_Extent_Drive_buff:word
;  EXTRN   Seek_Name_Drive_buff:word
;  EXTRN   Seek_Name_Cache_buff:word
;  EXTRN   Seek_Name_Cache_Seg:word
;  EXTRN   Seek_Num_Of_Drives:word
;  EXTRN   Seek_Total_Ext_Count:word
;  EXTRN   Seek_Total_Name_Count:word
;  EXTRN   End_Seek:byte
;  EXTRN   Check_Flag:word
;  EXTRN   VECTOR_DELETE:dword	  ; jump vector inside Cseg_Seek to make
				; a FAR call to FSeek Delete function within
				; the segment
end if





;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
if SEGSEL = S_CSEG_MAIN;  MAIN segment

; This segment is a continuation of the Cseg_Main segment in Fastopen.asm
; and contains code to initializes name and extent drive buffers
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;ASSUME	 CS:cseg_main,DS:nothing,SS:stack,ES:nothing

;EXTRN	MAIN:FAR										   ;AN000;

IF	BUFFERFLAG

;extrn	restore_page_state:near		; HKN 8/25/88	

;extrn	ems_save_handle1:word		; HKN
;extrn	ems_page_number:word		; HKN

end if

;EXTRN	Main_Total_Ext_Count:word								   ;AN000;
;EXTRN	Main_Total_Name_Count:word								   ;AN000;
;EXTRN	Main_Name_Drive_Buff:word								   ;AN000;
;EXTRN	Main_Name_Cache_Buff:word								    ;AN000;
;EXTRN	Main_Name_Cache_Seg:word								   ;AN000;
;EXTRN	Main_Parambuff:byte									   ;AN000;
;EXTRN	Main_extent_drive_Buff:word								   ;AN000;
;EXTRN	Main_Num_Of_drives:word 								   ;AN000;
;EXTRN	Main_Ext_Count:word									   ;AN000;
;EXTRN	Main_Ext_Cache_Size:word								   ;AN000;
;EXTRN	Main_EMS_FLAG:word									   ;AN000;
;EXTRN	Main_Res_Segs:word									   ;AN000;
;EXTRN	Main_EMS_PAGE_SEG:word									   ;AN000;
;EXTRN	Main_EMS_PAGE_SIZE:word 								    ;AN000;

;EXTRN	FOPEN_Insert:dword									   ;AN000;
;EXTRN	FOPEN_Update:dword									   ;AN000;
;EXTRN	FOPEN_Delete:dword									   ;AN000;
;EXTRN	FOPEN_Lookup:dword									   ;AN000;
IF	BUFFERFLAG
;EXTRN	FOPEN_Purge:dword
end if

;EXTRN	FSEEK_Open:dword
;EXTRN	FSEEK_Close:dword
;EXTRN	FSEEK_Insert:dword
;EXTRN	FSEEK_Delete:dword
;EXTRN	FSEEK_Lookup:dword
;EXTRN	FSEEK_Truncate:dword
;EXTRN	FSEEK_Purge:dword

;*************************************************************************
;
;SUBROUTINE: INIT_TREE	  (FASTINIT-1)
;
;FUNCTION:  This routine builds 'N' name directory buffers under each drive
;	    header. The second half of this routine initializes the extent
;	    drive headers and makes the Fastopen code resident.
;
;INPUT:     Drive_cache_header, End_Caches
;
;OUTPUT:    Name_cache and Extent Cache entries installed for every
;	    drive requested.
;
;*************************************************************************
	IF  ($-Cseg_Main) MOD 16								   ;AN000;
	   times (($-Cseg_Main)+16-(($-Cseg_Main) MOD 16)) - $ db 0 ;AN000;
	end if ;AN000;
label End_Main1 word                ;AN000;


INIT_TREE:
	mov	ax,CSEG_MAIN_		       ;get addressiblity to				   ;AN000;
	mov	ds,ax			       ;DS --> Cseg_Main		      ;AN000;
;	ASSUME	ds:cseg_Main									   ;AN000;

	cmp	word [Main_Total_Name_Count],0 ;initialize Name drive headers?? 			   ;AN000;
	je	Init_Ext_Drive_Hdrs	       ;no, init extent drive headers						;AN000;

;-----------------------------------------------------------------------------
; Following code adds 'n' directory entry buffers to each Name Drive headers,
; depending on the value of 'n' specified with each drive ID
;-----------------------------------------------------------------------------
	mov	si,[Main_Name_Drive_Buff]      ;SI-->first Name drive cache buff
	mov	bx,[Main_name_cache_Buff]      ;BX-->Name cache buffer
	xor	dx,dx
	xor	ax,ax

	mov	ax,[Main_name_cache_seg]      ;get addresability to CSeg_Init
	mov	ds,ax			       ;DS=addressablity to Cseg_Init
;	ASSUME	ds:cseg_Init

Set_Up_Cache:
	mov	[si+DRIVE_CACHE_HEADER.DCH_LRU_ROOT],bx ;set to point to first name
	mov	[si+DRIVE_CACHE_HEADER.DCH_Name_Buff],bx ;set to point to first name
	mov	cx,[si+DRIVE_CACHE_HEADER.DCH_Num_Entries] ;get number of name records

;-----------------------------------------------------------------------------
;  set up MRU and LRU pointers
;  AX points to last name record
;  BX points to current name record
;  DX points to next name record
;-----------------------------------------------------------------------------
	mov	[bx+NAME_RECORD.nMRU_ptr],-1 ;make first MRU -1
	jmp	short Set_Start_fastinit

Set_Up_Names_fastinit:
	mov	[bx+NAME_RECORD.nMRU_ptr],ax ;set up MRU
; MASM worked LENGTH out as the number of elements a variable was
; declared with and SIZE as the bytes they take up.  The arrays these
; ask about are all of bytes, so the two come to the same number.
	add	ax,sizeof.NAME_RECORD

Set_Start_fastinit:
	mov	[bx+NAME_RECORD.nChild_ptr],No_child ;no children or siblings
	mov	[bx+NAME_RECORD.nSibling_ptr],No_siblings ;  right now
	mov	[bx+NAME_RECORD.nBackward_ptr],No_backward
	push	es
	push	di
	push	ax

	push	ds
	pop	es				;ES-->name cache buffer
;	ASSUME	es:Cseg_Init

	mov	ax, '  '
	mov	di, bx
	add	di, NAME_RECORD.nCmpct_Dir_Info		;blank out the Dir name area
	stosb					;the directory buffer
	stosw
	stosw
	stosw
	stosw
	stosw

	pop	ax
	pop	di
	pop	es

	mov	dx,bx				;get name offset
	add	dx,sizeof.NAME_RECORD ;get start of next name
	dec	cx				;decrement num_entries
	jcxz	Get_Next_Drive			;if zero - get next drive
	mov	[bx+NAME_RECORD.nLRU_ptr],dx ;LRU pointer - next name
	add	bx,sizeof.NAME_RECORD ;
	jmp	Set_Up_Names_fastinit

Get_Next_Drive:
	mov	[bx+NAME_RECORD.nLRU_ptr],-1 ;LRU pointer - next name

	mov	[si+DRIVE_CACHE_HEADER.DCH_MRU_ROOT],bx ;set to point to last name
	mov	bx,dx				;get pointer to next name
	cmp	[si+DRIVE_CACHE_HEADER.DCH_Sibling_ptr],No_siblings ;is there any more to set up??
	jz	Init_Ext_Drive_Hdrs		; no - set extent drive headers
	add	ax,sizeof.NAME_RECORD ; yes - get next name directory buffer
	add	si,sizeof.DRIVE_CACHE_HEADER ;point to next drive header
	jmp	Set_Up_Cache


;----------------------------------------------------------------------------
; The following section initializes the Extent Drive Headers.
; DS has addressability to MAIN segment (CSEG_MAIN) and ES has
; addressability to Cache buffer segment (CSEG_INIT)
;----------------------------------------------------------------------------
Init_Ext_Drive_Hdrs:
	 mov	 ax,CSEG_MAIN_									 ;AN000;
	 mov	 ds,ax			    ;DS-->Cseg_Main			   ;AN000;
;	 ASSUME  ds:cseg_Main									   ;AN000;
												   ;AN000;
	 cmp	word [Main_Total_Ext_Count],0 ;initialize extent drive buffers ?? 			   ;AN000;
	 jne	Init_Extent_Cache	    ;yes - continue
	 jmp	INIT_EXIT		    ;no - exit						   ;AN000;

;============================================================================
; Fill extent cache buffer with zeros. Otherwise a (-2) left in the buffer
; could generate a wrong Free buffer pointer since (-2) is the free buffer
; mark.

Init_Extent_Cache:
	mov	cx, [Main_ext_cache_size]   ; CX = extent buffer size				 ;AN000;
	mov	si,[Main_extent_drive_Buff] ; SI-->start of extent cache buff		     ;AN000;
	push	ds										   ;AN000;
	mov	ax,[Main_name_cache_seg]
	mov	ds,ax			    ; DS-->new init seg (init segment			       ;AN000;
;	ASSUME	ds:Cseg_Init									   ;AN000;
	mov	al,0			    ; pattern "0"                                              ;AN000;

Next_Byte:				    ; may be in Extended memory)
	mov	[si],al 									   ;AN000;
	inc	si										   ;AN000;
	LOOP	Next_Byte									   ;AN000;
	pop	ds			    ; retore original init seg ID			       ;AN000;
;============================================================================


Init_Set_Cache:
	 mov	si,[cs:Main_extent_drive_Buff] ; SI-->first extent drive header	     ;AN000;
	 mov	cx,[cs:Main_Num_Of_drives] ; number of drives
	 mov	dx,0			    ; drive counter
	 lea	di,[Main_ParamBuff]   ; DS:DI-->parameter buff contains			   ;AN000;
					    ; drive ID and number of extents	      ;AN000;
	 mov	 es,[cs:Main_name_cache_seg] ; ES = addressability to Cseg_Init			   ;AN000;
;	 ASSUME  es:Cseg_Init		    ;							   ;AN000;
												   ;AN000;
INIT_LOOP:				    ; ES:SI-->cache buffer				   ;AN000;
	 push	cx			    ; save counter					   ;AN000;
	 add	di,dx			    ; points to drive ID of this driv			   ;AN000;
	 xor	ax,ax										   ;AN000;
	 mov	ax,[di+2]		    ; get Extent Count					   ;AN000;
	 cmp	ax, -1			    ; any extent under this drive ??			   ;AN000;
	 je	SKIP_THIS_DRIVE 	    ; no - dont create header for this		     ;AN000;
					    ; this drive
	 mov	ax,0			    ; *** for debugging sequence count
	 mov	[es:si+DRIVE_HEADER.Extent_Count],ax ; *** use this area for sequence counting
	 xor	ax,ax										   ;AN000;
	 mov	ax,[di] 		    ; get drive ID from drive ID buff			   ;AN000;
	 mov	[es:si+DRIVE_HEADER.Drive_Number],ax ; save drive ID in drive header			   ;AN000;
	 mov	bx, sizeof.DRIVE_HEADER         ;AN000;
	 add	bx,si			    ; BX-->Free area				     ;AN000;
	 mov	[es:si+DRIVE_HEADER.Free_ptr],bx ; pointing to free area				   ;AN000;
												   ;AN000;
	 mov	[es:si+DRIVE_HEADER.MRU_Hdr_Ptr],-1 ; mark OPEN QUEUE empty				   ;AN000;
	 mov	[es:si+DRIVE_HEADER.Close_Ptr],-1 ; make CLOSE QUEUE empty				   ;AN000;
	 xor	ax,ax										   ;AN000;
	 mov	ax,[di+2]		    ; get extent count (n)				   ;AN000;
	 mov	cx, sizeof.EXTENT_HEADER   ; get extent size				     ;AN000;
	 mul	cx			    ; AX=total cache for this drive			   ;AN000;
	 mov	[es:si+DRIVE_HEADER.Buff_Size],ax ; save it as initial available size 			    ;AN000;
	 mov	[es:si+DRIVE_HEADER.Free_Size],ax ; save it as initial free size
	 add	ax, sizeof.DRIVE_HEADER   ; (2/9/88)
	 add	ax,si			    ; AX-->offset to next drive hdr			   ;AN000;
	 mov	[es:si+DRIVE_HEADER.Next_Drv_Hdr_Ptr],ax ; save next drive header ptr in			   ;AN000;
					    ; current drive header				   ;AN000;
	 mov	bx,ax										   ;AN000;
	 mov	ax,si			    ; save current header pointer			   ;AN000;
	 mov	si,bx			    ; DS:SI-->next drive header 			   ;AN000;
												   ;AN000;
SKIP_THIS_DRIVE:										   ;AN000;
	 add	dx,4			    ; update index to next drive/extent 		   ;AN000;
	 pop	cx			    ; restore loop count				   ;AN000;
	 LOOP	INIT_LOOP		    ; repeat for next drive number			   ;AN000;
												   ;AN000;
	 mov	si,ax										   ;AN000;
	 mov	[es:si+DRIVE_HEADER.Next_Drv_Hdr_Ptr],-1 ; mark current header as last
					      ; drive header
;----------------------------------------------------------------------------
; Close handles 0 - 4
;----------------------------------------------------------------------------
	mov	bx,0
Handle_Loop:
	mov	ah,03EH
	INT	21H
	inc	bx
	cmp	bx,5
	jne	Handle_Loop

;----------------------------------------------------------------------------
; Get PSP segment and find the program environment segment and deallocate
; the environment space.
;----------------------------------------------------------------------------
INIT_EXIT:
	 push  ds
	 mov   si,0081H
	 mov   ah,62H
	 INT   21H		   ; get program PSP segment					   ;AN000;

	 mov   ds,bx		   ; DS = PSP segment						   ;AN000;
	 mov   si,02CH		   ; SI-->address of enviroment segment
	 mov   ax,[si]		   ; AX = environment seg id
	 cmp   ax,0		   ; environment present ??
	 je    Dont_Dealloc	   ; no - dont deallocate
	 mov   es,ax
	 mov   ah,49H
	 INT   21H		   ; deallocate environment
Dont_Dealloc:
	 pop   ds		   ; restore DS

;----------------------------------------------------------------------------
; Keep resident the Fastopen code and cache buffers.  The size of the resident
; area is in (Main_Res_Segs). Size may vary depending on whether Fastopen or
; Fastseek or both or extent memory is specified.
;----------------------------------------------------------------------------

IF	BUFFERFLAG

	call	RESTORE_PAGE_STATE	; HKN 8/25/88

end if

	  mov	 ah,Keep_Process	      ;remain resident
	  mov	 al,0			      ;return code
	  mov	 dx,[cs:Main_Res_Segs]  ;size of area in paragraph
	  INT	 21h			      ;keep resident and then return
					      ;control to DOS

;----------------------------------------------------------------------------
; Calculate the size of the MAIN module in bytes.  First potion of this
; segment can be found in the Fastopen.asm
;----------------------------------------------------------------------------
	IF  ($-Cseg_Main) MOD 16								   ;AN000;
	   times (($-Cseg_Main)+16-(($-Cseg_Main) MOD 16)) - $ db 0 ;AN000;
	end if ;AN000;
label End_Main word                 ;AN000;


end if ; End of Cseg_Main segment
page


;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

if SEGSEL = S_CSEG_INIT

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;	 ASSUME    cs:cseg_init,ds:cseg_init,ss:stack,es:cseg_init

;	 EXTRN	  SYSPARSE:NEAR 								   ;AN000;
;	 EXTRN	  SYSLOADMSG:NEAR								   ;AN000;
;	 EXTRN	  SYSDISPMSG:NEAR								   ;AN000;

IF	BUFFERFLAG
;	extrn	save_ems_page_state:far		; HKN 8/25/88
end if


;----------------------------------------------------------------------------
; The cache buffers start from the first location of Cseg_Init.
; First portion is the NAME DRIVE HEADERS, which is followed by
; NAME CACHE BUFFER, which is followed by EXTENT DRIVE HEADER. Under each
; extent drive header its cache buffer. 24 Name drive buffers are allocated
; during assembly time.  Remaining drive and cache buffers are allocated
; during run time.  Eventhough 24 name cache buffers are allocated during
; assembly time, this number may be reduced to the specified number of drive
; numbers during run time by overlaying other drive buffers over the unused ones.
; The initialization code will be overlayed by name and extent cache buffs
; during second half of the initialization which is in the MAIN module (see INit_Tree).
;-----------------------------------------------------------------------------

label Drive_header_start byte     ;Name cache drive buffer
; Drive_Cache_Header declares something other than a zero, so the max_drives of them
; are laid down as instances.  fasm names an instance, so each
; takes the array's name and its place in it; what the program
; asks for is the label.
label Drive_Cache byte; header for 24 drives are reserved
rept Max_drives each
{
	Drive_Cache_#each DRIVE_CACHE_HEADER
}

;-----------------------------------------------------------------------------
; Anything below this point will be overlayed by the Cache Buffers
; MSG retriever is placed after Cache buffer, so that the area can be
;-----------------------------------------------------------------------------
;=============================================================================
;		   Non_Resident Data Area
;=============================================================================
label INIT_VECTOR dword
	dw INIT_TREE	;jump vector to INIT_TREE			   ;AN000;
	dw CSEG_MAIN_
label MAIN_VECTOR dword
	dw MAIN		;entry point to MAIN routine			   ;AN000;
	dw CSEG_MAIN_
source_xname		DB	" :\",0         ;used for xname translate                          ;AN000;
target_xname		DB	65 DUP (0)	;used for xname translate			   ;AN000;
user_drive		db	0		;current user drive				   ;AN000;
psp_seg 		dw	0		;segment of psp 				   ;AN000;
stack_seg_start 	dw	0		;segment of temporary stack						      ;AN000;
stack_seg_end		dw	0								   ;AN000;
num_of_drives		dw	0		;number of user specified drives						   ;AN000;
Ext_Mem 		dw	0		;=1 if exteded memory is enabled		   ;AN000;
drive_id		db     " :",0                                                              ;AN000;
Parambuff		db	50  dup (0)
Parmbuff_Ptr		dw	0								   ;AN000;
FRAME_COUNT		dw	0		;EMS frame count

IF 	IBMCOPYRIGHT

FRAME_BUFFER		DB     30h DUP(0)	;EMS frame buffer

ELSE

FRAME_BUFFER		DB	100h DUP(0)	; EMS frame buffer

end if

IF 	BUFFERFLAG
FST_PAGE		DW	0,0		; holds the second highest page above 640k
end if

Cmdline_buff		db	135  dup (0)	;command line buffer					  ;AN000;
name_cache_seg		dw	CSEG_INIT_	;default to Init1 seg					  ;AN000;
Ext_Count		dw	0		;total name extent entries				  ;AN000;
extent_drive_Buff	dw	0		;ptr to extent drive					  ;AN000;
name_cache_Buff 	dw	0		;pointer to Name cache buffer				  ;AN000;
EMS_FLAG		dw	0		;EMI flag  1= if EMI is enabled 			  ;AN000;
CHECK_QUEUE		dw	0		; = 1 if analyser is activated
RES_SEGS		dw	010H+020H	;PSP SIZE + STACK SIZE resident segment size
EMS_PAGE_SEG		DW	0		;EMS code page segment ID				  ;AN000;
EMS_PAGE_NUM		DW	0		;EMS physical page number				  ;AN000;
Total_Ext_Count 	DW	0		;Total extent entry count				  ;AN000;
Total_Name_Count	DW	0		;Total Name entry count 				  ;AN000;
Total_Cache_Size	DW	0		;Total cache buffer size (name+extent) buffer		  ;AN000;
Name_Cache_Size 	DW	0		;Total name cache size (header + entry buffs)
Name_Count		DW	0		;name entry count
Name_Drive_Buff 	DW	0		;name driver buffer address				  ;AN000;
Ext_Cache_Size		DW	0		;extent buffer size					  ;AN000;
Open_SegID		DW	0		;SegId of Cseg_Open after relocation					  ;AN000;
Seek_SegID		DW	0		;SegId of Cseg_Seek  "       "                            ;AN000;
Init_SegID		DW	0		;SegId of Cseg_Init  "       "                            ;AN000;
MAIN_Size		DW	0		;size of Cseg_Main in Paragraph 			 ;AN000;
OPEN_Size		DW	0		;size of Cseg_Open in paragraph 			 ;AN000;
SEEK_Size		DW	0		;size of Cseg_Seek in paragraph 			 ;AN000;

;-----------------------------------------------------------------------;
;	EMS Support							;
;-----------------------------------------------------------------------;
EXT_HANDLE     rw      1    ; EMS handle for reference 					 ;AN000;
EMS_PAGESIZE   rw      1    ; EMS handle for reference 					 ;AN000;
EMS_FRAME_ADDR rw      1    ; EMS handle for reference 					 ;AN000;
CURR_EMS_PAGE  rb      1    ; Current EMS page number						 ;AN000;
HANDLE_NAME    DB   'FASTOPEN',0     ; EMS handle name                                                   ;AN000;

IF	BUFFERFLAG
SAVE_MAP_ADDR	rd      1 ; HKN 8/25/88
end if

;---------------------------------------------------------------------------
;	PARSER Support
;---------------------------------------------------------------------------
CURRENT_PARM   DW   81H 	     ;POINTER INTO COMMAND OF CUREENT OPERANT				;AN000;
NEXT_PARM      DW   0		     ;POINTER INTO COMMAND OF NEXT OPERAND				;AN000;
ORDINAL        DW   0		     ;ORDINAL NUMBER OF MAIN PARSER LOOP				;AN000;
ORDINAL1       DW   0		     ;ORDINAL NUMBER OF COMPLEX ITEM LOOP				;AN000;
PREV_TYPE      DB   0		     ;PREVIOUS POSITIONAL PARAMETER TYPE

;---------------------------------------------------------------------------
; PRINT_STDOUT input parameter save area
;----------------------------------------------------------------------------
SUBST_COUNT DW	  0		   ;message substitution count					   ;AN000;
MSG_CLASS   DB	  0		   ;message class						   ;AN000;
INPUT_FLAG  DB	  0		   ;Type of INT 21 used for KBD 				   ;AN000;
MSG_NUM     DW	  0		   ;message number						   ;AN000;


;----------------------------------------------------------------------------
; Following three sublists are used by the  Message Retriever
;----------------------------------------------------------------------------
label SUBLIST1 dword     ;SUBSTITUTE LIST 1
	DB	11		   ;sublist size						   ;AN000;
	DB	0		   ;reserved							   ;AN000;
	DD	0		   ;substition data Offset					   ;AN000;
	DB	1		   ;n of %n							   ;AN000;
	DB	0		   ;data type							   ;AN000;
	DB	0		   ;maximum field width 					   ;AN000;
	DB	0		   ;minimum field width 					   ;AN000;
	DB	0		   ;characters for Pad field					   ;AN000;


label SUBLIST2 dword     ;SUBSTITUTE LIST 2
	DB	11		   ;sublist size						   ;AN000;
	DB	0		   ;reserved							   ;AN000;
	DD	0		   ;substition data Offset					   ;AN000;
	DB	2		   ;n of %n							   ;AN000;
	DB	0		   ;data type							   ;AN000;
	DB	0		   ;maximum field width 					   ;AN000;
	DB	0		   ;minimum field width 					   ;AN000;
	DB	0		   ;characters for Pad field					   ;AN000;



;--------------------------------------------------------------------------
;   PARSER  Control Blocks and Buffers
;--------------------------------------------------------------------------

label PARMS word
	    DW	    PARMSX									   ;AN000;
	    DB	    1		  ; number of delemeters					   ;AN000;
	    DB	    1		  ; extra delimeters length					   ;AN000;
	    DB	    "="           ; extra delimeter expected                                       ;AN000;
	    DB	    0		  ; extra end of line length					   ;AN000;
	    DB	    0										   ;AN000;


label PARMSX byte                  ;AN000;
par_min     DB	    1		  ; min, max positional operands allowed			   ;AN000;
par_max     DB	    2		  ; min, max positional operands allowed			   ;AN000;
	    DW	    POS1	  ; offset into positonal-1 control block			   ;AN000;
	    DW	    POS2	  ; offset into positonal-1 control block			   ;AN000;
par_sw	    DB	    1		  ; one switch							   ;AN000;
	    DW	    SWITCH	  ; offset into switch-1 control bloc				   ;AN000;
	    DB	    0		  ; no keywords 						   ;AN000;
	    DB	    0		  ; 0								   ;AN000;



;------------------ POS2 CONTROL BLOCK --------------------------------------

label POS1 word      ; positional-1 control definition
Pos1Type    DW	   0100H	; control type flag (drive only)				   ;AN000;
	    DW	   0		; function flags						   ;AN000;
	    DW	   RESULT	; offset into result buffer					   ;AN000;
	    DW	   Value_Pos1	; offset value list buffer					   ;AN000;
	    DB	   0		; number of keyword/switch synonyms				   ;AN000;


label Value_Pos1 byte      ; postional parameter value expected				      ;AN000;
	    DB	    0		; no values expected						    ;AN000;



;---------------- POS1 CONTROL BLOCK ----------------------------------------

label POS2 word         ; positional-2 control definition				     ;AN000;
Pos2Type   DW	  08502H       ; Control type (complex/integer/drive/				   ;AN000;
			       ; repeat)						  ;AN000;
	   DW	  0	       ; function flags 						   ;AN000;
	   DW	  RESULT       ; offset into result buffer					   ;AN000;
	   DW	  Value_Pos2   ; offset value list buffer					   ;AN000;
	   DB	  0	       ; number of keyword/switch synonyms				   ;AN000;

label Value_Pos2 byte
	   DB	   0	       ; either (n) or (m) will be returned



;--------------- RESULT BUFFER ---------------------------------------------

label RESULT byte   ; postional2 parameter result buffer					   ;AN000;
PosType    rb      1     ; type of operand returned					   ;AN000;
Postag	   rb      1     ; type of item tage returned					   ;AN000;
synonym    rw      1     ; offset into synonyms returned					   ;AN000;
valuelo    rw      1     ; space for drive number/integer/strin				   ;AN000;
valuehi    rw      1          ;AN000;


;---------------- SWITCH CONTROL BLOCK ------------------------------------------

label SWITCH word   ; switch control definition
	   DW	  0	       ; no match flag							   ;AN000;
	   DW	  0	       ; no function flags						   ;AN000;
	   DW	  RESULT       ; offset into result buffer					   ;AN000;
	   DW	  Value_sw1    ; offset value list buffer					   ;AN000;
	   DB	  1	       ; number of keyword/switch synonyms				   ;AN000;
E_Switch   DB	  "/X"         ; /X option for extended memory access                              ;AN000;
	   DB	  0										   ;AN000;


label Result_sw1 byte        ; switch	parameter result					   ;AN000;
	   DB	  ?	       ; type of operand returned					   ;AN000;
	   DB	  ?	       ; type of item tage returned					   ;AN000;
Swval	   rw      1     ; offset into synonyms returned					   ;AN000;
	   DB	  ?	       ; switch value							   ;AN000;


label Value_sw1 byte         ; switch parameter value expected					   ;AN000;
	   DB	   0	       ; no values expected						   ;AN000;



 



;-----------------------------------------------------------------------------
;  INIT     (FASTINIT-2)
;-----------------------------------------------------------------------------
;
;SUBROUTINE: INIT
;
;FUNCTION:  Performs FASTOPEN initialization function
;
;
;NOTE: This routine is the starting routine of FASTOPEN
;
;-----------------------------------------------------------------------------

START:
					; on entry DS and ES -->PSP				   ;AN000;
	push	cs			; DS-->Cseg_Init					   ;AN000;
	pop	ds										   ;AN000;
;	ASSUME	ds:cseg_init									   ;AN000;
	mov	[psp_seg],es ; save PSP segment for later use			   ;AN000;
	push	cs										   ;AN000;
	pop	es			; ES-->Cseg_Init					   ;AN000;
;	ASSUME	es:cseg_init									   ;AN000;

	CALL	SYSLOADMSG		; Preload messages					   ;AN000;
	jnc	Parse_Cmd_Line		; If no error, parse command line			   ;AN000;

	mov	ax,1										   ;AN000;
	CALL	SYSDISPMSG		; display error 					   ;AN000;

	mov	ah,04ch 		; Terminate						   ;AN000;
	mov	al,0			; Errorlevel 0 (Compatible)				   ;AN000;
	INT	021h			; exit to DOS

Parse_Cmd_Line: 										   ;AN000;
	CALL	PARSE			;Parse command line					   ;AN000;
	lea	si,[Parambuff];drive ID buff address					   ;AN000;
	mov	ax,[Total_Name_Count] ;							   ;AN000;
	mov	ax,[Total_Ext_Count]         ;AN000;
	mov	ax,[num_of_drives]         ;AN000;
	mov	ax,[Ext_Mem]          ;AN000;
	jnc	Check_Installed 	;no, check if Fastopen already installed
	jmp	ERROR_EXIT_fastinit		;yes - exit						   ;AN000;

Check_Installed:
	CALL	CHECK_INSTALL		; Fastopen installed ??
	jnc	Save_SegIds		; no - save segment IDs
	jmp	ERROR_EXIT_fastinit		; yes - exit

;-----------------------------------------------------------------------------
; Set seg IDs of three segments.
;-----------------------------------------------------------------------------
Save_SegIds:
	mov	word [Open_SegID], CSEG_OPEN_    ;AN000;
	mov	word [Seek_SegID], CSEG_SEEK_    ;AN000;
	mov	word [Init_SegID], CSEG_INIT_    ;AN000;

;-----------------------------------------------------------------------------
; Compute the size of segments and cache buffers.  Setup a temporary stack
; to be used by the second half of initilization.
;-----------------------------------------------------------------------------
	CALL	CHECK_MEM		;See if we have enough memory				   ;AN000;
	jnc	Chk_Extended_Mem	;yes, check for extended memory 			   ;AN000;
	jmp	ERROR_EXIT_fastinit		;no  - display not enough mem msg			   ;AN000;

;-----------------------------------------------------------------------------
; Check if Extended Memeory is specified. If true, check if Extended memory is
; available.  Get segid of one extended memory page.
;-----------------------------------------------------------------------------
Chk_Extended_Mem:
	cmp	word [Ext_Mem],1 ; enable EMS ?? 					   ;AN000;
	jne	Set_Data_Areas		; no, set data areas					   ;AN000;

	CALL	SET_EMS 		; set expanded memory					   ;AN000;
	jnc	Set_Data_Areas		; if no error						   ;AN000;
	jmp	ERROR_EXIT_fastinit		; error exit						   ;AN000;

;------------------------------------------------------------------------------
; Copy Data and segid of Init segments to Main, Open and Seek segments.
; If code is relocated, segids have to be adjusted later. (See Adjust_SegID)
;------------------------------------------------------------------------------
Set_Data_Areas:
	CALL	COPY_DATA		; copy data to other segments				   ;AN000;

;-----------------------------------------------------------------------------
; Relocate code to extended memory if extended memory is specified or
; relocate in lower memory itself.
;-----------------------------------------------------------------------------
Relocate_Code:
	CALL	RELOCATE_SEGMENT	; Relocate the code cnd buffers 			   ;AN000;

;-----------------------------------------------------------------------------
; Adjust the segids and jump vectors in other segments after code relocation
;-----------------------------------------------------------------------------
	CALL	ADJUST_SEGIDS		; adjust segment ids after relocation			   ;AN000;

;-----------------------------------------------------------------------------
; Display FASTOPEN INSTALLED message. This must be done prior to the actual
; installation.
;-----------------------------------------------------------------------------
Disp_Install_Msg:			; display FASTOPEN installed message
	MOV	AX,Install1		; message number					   ;AN000;
	MOV	[MSG_NUM],AX ; set message number					   ;AN000;
	MOV	word [SUBST_COUNT],0 ; no message						   ;AN000;
	MOV	byte [MSG_CLASS],-1 ; message class 					   ;AN000;
	MOV	byte [INPUT_FLAG],0 ; no input						   ;AN000;
	CALL	PRINT_STDOUT		; show message						   ;AN000;

;-----------------------------------------------------------------------------
; Install Fastopen
;-----------------------------------------------------------------------------
	CALL	INSTALL_FASTOPEN	; Install Fastopen					  ;AN000;
	jnc	SETUP_STACK		; Installed Ok, setup stack				  ;AN000;
	jmp	ERROR_EXIT_fastinit		; error - exit


;----------------------------------------------------------------------------
; Set Stack Values. This stack is used by the cache buffer initilization
; portion of the code. This stack area will be eventually overlayed and
; wont be used by either Fastopen or Fastseek functions in MAIN module.
;----------------------------------------------------------------------------
SETUP_STACK:
	nop										   ;AN000;
	CLI				;no interrupts allowed during stach change	   ;AN000;
	mov	SS,[stack_seg_start] ;set up new stack				   ;AN000;
	mov	SP,0			;						   ;AN000;
	STI				;interrupts ok now				   ;AN000;
	jmp	[INIT_VECTOR] ;Jump to Cseg_Main to do second
					;phase of the initialization
ERROR_EXIT_fastinit:
	mov	al,1			;set up return code
	mov	ah,Exit 		;set function code
	INT	int_command		;exit to DOS
 



;----------------------------------------------------------------------------
;  CHECK_INSTALL
;----------------------------------------------------------------------------
; Input:  None
;
; Output:
;      IF Carry = 0   -  Fastopen is not already installed
;
;      IF Carry = 1   -  Fastopen is already installed
;
;----------------------------------------------------------------------------
;  Use CALLINSTALL macro to see if FASTOPEN is already installed.
;  If carry flag set then FASTOPEN is installed. In this case display
;  Already Installed message.
;----------------------------------------------------------------------------

CHECK_INSTALL:

	push	ax				;save every registers that may
	push	bx				;be destroyed by DOS
	push	cx
	push	dx
	push	si
	push	di
	push	bp

	push	ds
	mov	bx, 1				;Fastopen function code
	mov	si, -1				;special check install code
	CallInstall fastopencom,MultDOS,42	;see if fastopen installed
	pop	ds
	jc	Install_Msg			;yes, display already installed
						;message
;----------------------------------------------------------------------------
; Check if Fastseek function is enabled. If true display Installed message
;----------------------------------------------------------------------------			   ;AN000;
	push	ds										   ;AN000;
	mov	si, -1				;special check installed code
	mov	bx, 2				;for Fastseek
	CallInstall fastopencom,MultDOS,42	;see if fastopen installed			   ;AN000;
	pop	ds										   ;AN000;
	jnc	Chk_Install_Exit		; no, exit					   ;AN000;

Install_Msg:					;installed previously display message
	MOV	AX,Already_install		;message number 					       ;AN000;
	MOV	[MSG_NUM],AX ;set message number					       ;AN000;
	MOV	word [SUBST_COUNT],0 ;no message substitution				       ;AN000;
	MOV	byte [MSG_CLASS],-1 ;message class						       ;AN000;
	MOV	byte [INPUT_FLAG],0 ;no input						       ;AN000;
	CALL	PRINT_STDOUT			;show message "Already Installed"
	stc

Chk_Install_Exit:
	pop	bp				;restore registers
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret					;return

;CHECK_INSTALL	  ENDP

 



;----------------------------------------------------------------------------
;  INSTALL_FASTOPEN
;----------------------------------------------------------------------------
; Input:     Addrss of entry point to Fastopen resident code
;
; Output:
;      IF Carry = 0
;	     Entry point to FASTOPEN resident code set
;
;      IF Carry = 1  Error
;
; Calls:     none
;----------------------------------------------------------------------------
;  Use CALLINSTALL macro to see if FASTOPEN is already installed.
;  If FASTOPEN is not installed, install it.
;  If carry flag set then FASTOPEN is installed. In this case display
;  already installed message.
;----------------------------------------------------------------------------

INSTALL_FASTOPEN:

	push	ax				;Save every registers,point reg since
	push	bx				;DOS may destroy it.
	push	cx
	push	dx
	push	si
	push	di
	push	bp

	cmp	word [Total_Name_Count], 0 ;FastOpen enabled ??				  ;AN000;
	je	Install_Ext			;no - jump

	push	ds				;yes - install fastopen
	mov	bx, 1				;tell DOS that this is the
	lds	si,[MAIN_VECTOR]
	CallInstall fastopencom,MultDOS,42	;see if fastopen installed
	pop	ds
	jc	Install_Exit			;error	- exit

;----------------------------------------------------------------------------
; Check if Fastseek functions are enabled. If true, pass MAIN routine entry
; point and the Fastseek enabled information to DOS
;----------------------------------------------------------------------------			   ;AN000;
Install_Ext:
	cmp	word [Total_Ext_Count], 0 ; Fastseek enabled ??				   ;AN000;
	jne	Ext_Install			; yes - install fastseek		      ;AN000;
	clc											   ;AN000;
	jmp	short Install_Exit		; no, exit				      ;AN000;

Ext_Install:
	push	ds										   ;AN000;
	mov	bx, 2				;tell DOS that this is the			   ;AN000;
	lds	si,[MAIN_VECTOR] ;fastseek  entry point				   ;AN000;
	CallInstall fastopencom,MultDOS,42	;see if fastopen installed			   ;AN000;
	pop	ds										   ;AN000;
	jnc	short Install_Exit
	jmp	short Install_Exit

Installx_Msg:					;installed previously display message
	MOV	AX,Already_install		;message number 					       ;AN000;
	MOV	[MSG_NUM],AX ;set message number					       ;AN000;
	MOV	word [SUBST_COUNT],0 ;no message substitution				       ;AN000;
	MOV	byte [MSG_CLASS],-1 ;message class						       ;AN000;
	MOV	byte [INPUT_FLAG],0 ;no input						       ;AN000;
	CALL	PRINT_STDOUT			;show message "Already Installed"
	stc

Install_Exit:
	pop	bp		    ;restore registers
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret			    ;return

;INSTALL_FASTOPEN    ENDP

 




;----------------------------------------------------------------------------
;  CHECK_MEM
;----------------------------------------------------------------------------
;  Function:  Compute the total size of memory required by the Fasteopen.
;	      This includes both code and the cache buffers.
;
;  Input:     Name_Count, extent_count, Drive_cache,  num_of_drives
;
;  Output:    Memory is validated, Resident segment size is calculated
;	      Temporary stack segment is set
;----------------------------------------------------------------------------
CHECK_MEM:                ; DS-->Cseg_init

;** Compute the total resident segment size and then add the cache buffer
;** size.  The Resident segment size should be adjusted again after relocation.

	mov	word [Total_Cache_Size],0 ;reset total cache size (Name +Ext)
	mov	word [Name_Cache_Size],0 ;reset Name cache buffer size
	mov	ax, End_Main             ;size of Main_Seg in bytes 			   ;AN000;
	add	ax,15										   ;AN000;
	mov	cl,4			     ;convert size to paragraph 			   ;AN000;
	shr	ax,cl			     ;by dividng by 16					   ;AN000;
	mov	[MAIN_Size], ax     ;save MAIN segment size in para			   ;AN000;
	add	[RES_SEGS],ax     ;update resident seg count 			   ;AN000;
												   ;AN000;
	mov	ax, END_OPEN             ;size of Open_Seg in bytes 			   ;AN000;
	add	ax,15										   ;AN000;
	mov	cl,4			     ;convert it to paragraph				   ;AN000;
	shr	ax,cl										   ;AN000;
	mov	[OPEN_Size], ax     ;save OPEN segment size in para			   ;AN000;
	add	[RES_SEGS],ax     ;update resident seg count 			   ;AN000;
												   ;AN000;
	mov	ax, END_SEEK             ;add size of Seek_Seg
	add	ax,15										   ;AN000;
	mov	cl,4										   ;AN000;
	shr	ax,cl			     ; convert to para (divide by 16)			   ;AN000;
	mov	[SEEK_Size], ax     ;save Seek segment size in para			   ;AN000;
	add	[RES_SEGS],ax    ;update resident seg count				   ;AN000;

;----------------------------------------------------------------------------
; Calculate the size of the NAME DRIVE HEADER BUFFERS
;----------------------------------------------------------------------------
	xor	ax,ax			    ;reset the cache size register
	cmp	word [Total_Name_Count],0 ;Fastopen  enabled ??
	je	Check_Ext_Cache 	    ;no - compute extent cache size

	mov	bx,Drive_Cache            ;get beginning of cache buff
	xor	ax,ax
	mov	al,sizeof.DRIVE_CACHE_HEADER ;get size of one name entry
	mul	[num_of_drives]    ;get total needed for drive cache
	add	ax,bx			    ;set up correct offset
	add	ax,15			    ;round up to paragraph boundary
	mov	cl,4
	shr	ax,cl			    ;convert to paragraphs
	add	[RES_SEGS],ax    ;update resident seg count
	mov	[Total_Cache_Size], ax   ;update total cache buff size
	mov	[Name_Cache_Size], ax   ;size in paragraph

; Calculate the offset of the Name cache buffers
	shl	ax,cl			    ;AX = offset to Name cache buff
	mov	[name_cache_Buff],ax   ;save Name cache address

;-----------------------------------------------------------------------------
; Compute the size of the NAME CACHE  buffer
;-----------------------------------------------------------------------------
	mov	ax,sizeof.NAME_RECORD
	mul	[Total_Name_Count]
	add	ax,15			    ;round up to paragraph boundary
	mov	cl,4
	shr	ax,cl			    ;convert to paragraphs ( divide 16)
	add	[RES_SEGS],ax    ;AX = End of Name cache buffers
	add	[Total_Cache_Size],ax   ;update total cache buff size
	add	[Name_Cache_Size], ax   ;

Check_Ext_Cache:
	cmp	word [Total_Ext_Count],0 ;Fastseek enabled ??
	je	Set_Stack		    ;no, set stack

;---------------------------------------------------------------------------
; Compute the size of the Extent cache including drive headers
;---------------------------------------------------------------------------
Compute_Ext_Cache:			    ;calculate the extent buff offset
	mov	ax,[Name_Cache_Size]
	mov	cl,4
	shl	ax,cl			    ;convert to bytes ( multiply by 16) 		   ;AN000;
	mov	[extent_drive_Buff], ax   ;save EXTENT DRIVE BUFFER address			     ;AN000;

	mov	ax, sizeof.DRIVE_HEADER         ;AN000;
	mul	[num_of_drives]    ;calc size of drive header buff			   ;AN000;
	mov	bx,ax			    ;save AX in BX					   ;AN000;
	mov	ax, sizeof.EXTENT_HEADER   ;size of one extent 				   ;AN000;
	mul	[Total_Ext_Count]    ;calc size of extent buffers			   ;AN000;
	add	ax,bx			    ;AX = size of extent buff in bytes			   ;AN000;
	mov	[Ext_Cache_Size],ax   ;save it for later use				   ;AN000;
	add	ax,15			    ;round up to paragraph boundary			   ;AN000;
	mov	cl,4										   ;AN000;
	shr	ax,cl			    ;convert to paragraphs				   ;AN000;
	add	[RES_SEGS],ax    ;update resident seg count				   ;AN000;
	add	[Total_Cache_Size],ax   ;update total cache buff size


;----------------------------------------------------------------------------
; Setup stack segment followed by the extent cache buffers.  This is a
; temporary stack used by the  drive buffer initilization code in the
; Cseg_Main segment.  This stack will be overlayed by the cache buffers.
;----------------------------------------------------------------------------
Set_Stack:
	mov	ax,[RES_SEGS]    ;AX=size of code and buffs in para
	add	ax,[psp_seg]    ;AX=segID of stack
	mov	[stack_seg_start],ax   ;start of the new STACK
	add	ax,20h			    ;add the size of the stack
	mov	[stack_seg_end],ax   ;get end of what we need

	push	ds			    ;
	mov	ds,[psp_seg]    ;access PSP for memory size
	mov	si,Top_mem
	LODSW				    ;get total memory size
	pop	ds
	sub	ax,[stack_seg_end]   ;see if there is enough for us
	jc	Not_Enough_Memory	    ;no - error exit
	sub	ax,1000h		    ;will there still be 64K ??
	jnc	Check_Reloc_Size	    ;and return

Not_Enough_Memory:
	MOV	AX,Not_enough_mem	    ;message number					   ;AN000;
	MOV	[MSG_NUM],AX    ;set message number 				   ;AN000;
	MOV	word [SUBST_COUNT],0 ;no message substitution				   ;AN000;
	MOV	byte [MSG_CLASS],-1 ;message class					   ;AN000;
	MOV	byte [INPUT_FLAG],0 ;no input						   ;AN000;
	CALL	PRINT_STDOUT		    ;show message "Insufficient Memory"                    ;AN000;
	stc				    ;set error flag					   ;AN000;
	jmp	short Set_Mem_Ret	    ;return						   ;AN000;

;------------------------------------------------------------------------------
; If relocation is needed, then recalculate the size of resident segment
; If extended memory relocation, OPEN, SEEK and INIT segments will be
; eliminated from the current resident seg.
;-----------------------------------------------------------------------------
Check_Reloc_Size:
	cmp	word [Ext_Mem],1 ; extended memory relocation ??
	jne	Set_Mem_Exit		; no - exit						   ;AN000;

;-----------------------------------------------------------------------------
; Check to see that the both code and the cache buffers fit in the
; exteneded memory one 16K page. Since the entire code segment and the
; cache buffers are going to be moved to XMA, that amount should be
; reduced from the size that should reside in the low memory.
;-----------------------------------------------------------------------------
	xor	ax,ax
	xor	bx,bx
	cmp	word [Total_Name_Count],0 ;Fastseek enabled ??
	je	Skip_Name_Size		;no - skip name size
	mov	ax, [OPEN_Size] ;size of Open seg in para				  ;AN000;
Skip_Name_Size:
	cmp	word [Total_Ext_Count],0 ;Fastseek enabled ??
	je	Skip_Ext_Size		;no - skip extent size
	mov	bx, [SEEK_Size] ;size of Seek_Seg in para				  ;AN000;
Skip_Ext_Size:
	add	ax,bx
	add	ax, [Total_Cache_Size] ;size of Init_Seg in para				  ;AN000;
	cmp	ax, 0404H		;Less than 16K ??					  ;AN000;
	jge	Not_Enough_Space	;no - display message					;AN000;

	mov	ax, [OPEN_Size] ;size of Open seg in para				  ;AN000;
	add	ax, [SEEK_Size] ;size of Seek_Seg in para				  ;AN000;
	add	ax, [Total_Cache_Size] ;reduce resident seg size				   ;AN000;
	sub	[RES_SEGS],ax ;update resident seg count				   ;AN000;

;-----------------------------------------------------------------------------
; If the code is to be moved to extended memory.  There is no reason to
; keep Init_Tree in main memory.  Remove that also to save space in base memory
;-----------------------------------------------------------------------------
	mov	ax, End_Main1        ;size of Main_Seg until Init_Tree (bytes)	      ;AN000;
	add	ax,15										   ;AN000;
	mov	cl,4			;convert size to paragraph			      ;AN000;
	shr	ax,cl			;by dividng by 16				      ;AN000;
	mov	bx,[MAIN_Size] ;bx=total size of Main seg including Init_Tree
	sub	bx,ax			;bx=size after reducing Init_Tree
	sub	[RES_SEGS],bx ;update base memory resident seg count				       ;AN000;
	jmp	short Set_Mem_Exit
					;
Not_Enough_Space:
	MOV	AX,No_page_space	; not enough space in EMS page
	MOV	[MSG_NUM],AX ; set message number
	MOV	word [SUBST_COUNT],0 ; no message
	MOV	byte [MSG_CLASS],-1 ; message class
	MOV	byte [INPUT_FLAG],0 ; no input
	CALL	PRINT_STDOUT		; display message
	mov	word [Ext_Mem], 0 ; RESET XMA FLAG
	stc
	jmp	Set_Mem_Ret

Set_Mem_Exit:											   ;AN000;
	clc											   ;AN000;

Set_Mem_Ret:
	ret											   ;AN000;

;CHECK_MEM	endp

 



;----------------------------------------------------------------------------
;  RELOCATE
;----------------------------------------------------------------------------
;  Function:  Relocate Fastopen code and buffer in base memory or in
;	      Extended Memory.	If base memory relocation, then
;	      relocate Cseg_Seek over Cseg_Open segment if the user
;	      didn't specify Fastopen (n).  Relocate Cseg_Init over Cseg_Seek
;	      if user didn't specify Fastseek feature(m). If extended memory
;	      relocation, copy Cseg_Open, Cseg_Seek and Cseg_Init to
;	      a single page in extented memory if both Fastopen and Fastseek
;	      (n and m) are specified.	Copy Cseg_open and Cseg_Init only if Fastseek
;	      feature (m) is not specified.  Copy Cseg_Seek and Cseg_Init if
;	      FastOpen feature (n) is not specified
;
;----------------------------------------------------------------------------

RELOCATE_SEGMENT:
	cmp	word [Ext_Mem],1 ; Extended memory enabled ??						;AN000;
	je	Set_Seg_Ids		; yes - do extented memory relocation
	jmp	Reloc_LOW_Mem		; no - do low memory relocation 			    ;AN000;

;----------------------------------------------------------------------------
; Move Fastopen, FastSeek or both to the Extended memory
;----------------------------------------------------------------------------
Set_Seg_Ids:
	cld				; clear direction flag (increment si and di)
	cmp	word [Total_Name_Count],0 ; Fastopen enabled ??
	jne	Set_Open_Seg		; yes - set open seg in extented memory

	mov	ax,[EMS_PAGE_SEG] ; AX = seg id of Cseg_Seek in ext mem
	mov	[Seek_SegID],ax ; save it
	jmp	Set_Seek_Seg		; no - fastopen, set Seek segment

;-----------------------------------------------------------------------------
;	 ----  Extended Memory Relocation -----
;  Setup Cseg_Open segment in Extended Memory
;------------------------------------------------------------------------------
Set_Open_Seg:
	mov	ax,CSEG_INIT_		;
	mov	ds,ax			; DS-->Cseg_Init
;	ASSUME	ds:Cseg_Init
	mov	ax,[EMS_PAGE_SEG] ; AX = seg id of Cseg_Open in ext mem
	mov	[Open_SegID],ax ; save it

Copy_Open_Seg:
	mov	ax, END_OPEN        ; size of Open seg in bytes				   ;AN000;
	mov	cl,1
	shr	ax,cl			; convert to words					   ;AN000;
	mov	cx,ax			; CX = number of WORDS to transfer			   ;AN000;
	xor	si,si			; offset of the source in low memory					;AN000;
	xor	di,di			; offset of the destination in XMA				 ;AN000;
	mov	ax,CSEG_OPEN_		; set source segID					   ;AN000;
	mov	ds,ax			; DS-->Cseg_Open					;AN000;
;	ASSUME	ds:Cseg_Open									   ;AN000;
	mov	ax,[es:Open_SegID] ; set destination XMA  seg id					;AN000;
	mov	es,ax			; ES-->Extended memory page				;AN000;
;	ASSUME	es:nothing									   ;AN000;
	REP	MOVSW			; copy Open segment to extended memory
					; SI-->Cseg_Seek segment
	mov	ax,CSEG_INIT_		; no - only Fastseek specified
	mov	ds,ax			; DS-->Cseg_Init
;	ASSUME	ds:Cseg_Init
	cmp	word [Total_Ext_Count],0 ; Fastseek enabled ??
	jne	Set_Seek_Id		; yes -set seek id

	mov	ax,CSEG_SEEK_		; only Fastopen is enabled							     ;AN000;
	sub	ax,CSEG_OPEN_		; AX = size of Cesg_Open segment			;AN000;
	add	ax,[EMS_PAGE_SEG] ; AX = new seg ID of Cseg_Init in ext			   ;AN000;
	mov	[Init_SegID],ax ; only if Fastopen is specified 	       ;AN000;
	jmp	Copy_Init_Seg		; copy init_seg to extended memory

;-----------------------------------------------------------------------------
;  Setup Cseg_Seek segment in Extended Memory
;------------------------------------------------------------------------------
Set_Seek_Id:
	mov	ax,CSEG_SEEK_		;
	sub	ax,CSEG_OPEN_		; AX = size of Cesg_Open segment			;AN000;
	add	ax,[EMS_PAGE_SEG] ; AX = new seg ID of Cseg_Seek in		       ;AN000;
	mov	[Seek_SegID],ax ; extended memory					;AN000;
	jmp	Copy_Seek_Seg

Set_Seek_Seg:				; only Fastseek is specified
	xor	si,si			; offset of the source in low memory					;AN000;
	xor	di,di			; offset of the destination in XMA				 ;AN000;

Copy_Seek_Seg:
	mov	ax, END_SEEK        ;size of Cseg_Seek in bytes				 ;AN000;
	mov	cl,1
	shr	ax,cl			; convert to words					   ;AN000;
	mov	cx,ax			; CX = number of WORDS to transfer			   ;AN000;
	xor	si,si			; offset of the source in low memory					;AN000;
	xor	di,di			; offset of the destination in XMA				 ;AN000;
	mov	ax,CSEG_SEEK_		; set source segID					   ;AN000;
	mov	ds,ax
;	ASSUME	ds:Cseg_Seek									   ;AN000;
	mov	ax,[cs:Seek_SegID] ; set destination XMA  seg id					;AN000;
	mov	es,ax
;	ASSUME	es:nothing									   ;AN000;
	REP	MOVSW			; copy Seek segment to extended memory
					; SI-->Cseg_Init segment
	mov	ax,CSEG_INIT_		; no - only Fastseek specified
	mov	ds,ax			; DS-->Cseg_Init
;	ASSUME	ds:Cseg_Init
	cmp	word [Total_Name_Count],0 ; FastOpen enabled ??
	jne	Set_Init_seg		; yes - set Init Segment

	mov	ax,CSEG_INIT_
	sub	ax,CSEG_SEEK_		; ax = size of Cseg_Seek
	add	ax,[EMS_PAGE_SEG] ; Cseg_Init id only if Fastseek is specified
	mov	[Init_SegID],ax ;
	jmp	Copy_Init_Seg		; copy cseg_init area to extentde memory

;-----------------------------------------------------------------------------
;  Setup Cseg_Init segment in Extended Memory
;------------------------------------------------------------------------------
Set_Init_seg:
	mov	ax,CSEG_INIT_		; yes - set init seg id
	sub	ax,CSEG_OPEN_		; AX = size of Open_Cseg+Seek_Cseg
	add	ax,[EMS_PAGE_SEG] ; new Cseg_Init id in XMA if both
	mov	[Init_SegID],ax ; Fastopen and Fastseek are enabled			   ;AN000;

Copy_Init_Seg:				; comes here if no Cseg_Seek is required
	xor	si,si			; offset of the source in low memory					;AN000;
	xor	di,di			; offset of the destination in XMA				 ;AN000;
	mov	ax, [Total_Cache_Size] ; size of Init seg area to be copied			 ;AN000;
	mov	cl,4			; in paragraph						  ;AN000;
	shl	ax,cl			; convert to number of bytes			       ;AN000;
	mov	cl,1			;
	shr	ax,cl			; convert to number ofwords					    ;AN000;
	mov	cx,ax			; CX = number of WORDS to transfer			   ;AN000;
	mov	ax,CSEG_INIT_		; set source segID					   ;AN000;
	mov	ds,ax
;	ASSUME	ds:Cseg_Init									   ;AN000;
	mov	ax,[Init_SegID] ; set destination XMA  seg id					;AN000;
	mov	es,ax
;	ASSUME	es:nothing									   ;AN000;
	REP	MOVSW			; copy Init segment to extended memory
	jmp	Reloc_Exit		; then return						    ;AN000;


;NOTE:	No need to adjust the resident segment size (Res_Segs) since it is
;	done in the routine (Check_Mem).


;-----------------------------------------------------------------------
;	 ---- LOW MEMORY RELOCATION ----
; Reloctae FastOpen or FastSeek or both in the low memory and adjust the
; resident size of the code.
;-----------------------------------------------------------------------
Reloc_LOW_Mem:
	cmp	word [Total_Name_Count],0 ; Fastopen function enabled ??
	jne	Check_Seek	       ; yes, check Fastseek function

; Relocate Cseg_Seek segment over Cseg_Open segment
	mov	ax, END_SEEK        ; size of Cseg_Seek in bytes				       ;AN000;
	mov	cl,1
	shr	ax,cl			; convert to words					   ;AN000;
	mov	cx,ax			; CX = number of WORDS to transfer			   ;AN000;
	xor	si,si			; offset of the source					   ;AN000;
	xor	di,di			; offset of the destination				   ;AN000;;AN000;
	mov	ax,CSEG_SEEK_		; set source segID					   ;AN000;
	mov	ds,ax			; DS:SI-->Cseg_Seek					   ;AN000;
;	ASSUME	ds:Cseg_Seek									   ;AN000;
	mov	ax,CSEG_OPEN_		; set destination seg id				   ;AN000;
	mov	es,ax			; ES:DI--> Cseg_Open				      ;AN000;
;	ASSUME	es:Cseg_Open									   ;AN000;
												   ;AN000;
	REP	MOVSW			; relocate code and cache buffer
	mov	ax,[cs:OPEN_Size] ; reduce Open seg size from
	sub	[cs:RES_SEGS],ax ; the resident size

;-----------------------------------------------------------------------
; Compute the new segID after relocation and save it
;-----------------------------------------------------------------------
	mov	ax,CSEG_INIT_		;
	mov	ds,ax			; DS-->Cseg_Init
;	ASSUME	ds:Cseg_Init
	mov	ax,CSEG_OPEN_		; AX = seg id of Cseg_Open in ext mem
	mov	[Seek_SegID],ax ; save it
												   ;AN000;
	mov	ax,[SEEK_Size] ; AX = size of Cseg_Seek
	add	ax,CSEG_OPEN_		; AX = new seg ID of Cseg_Init in ext			   ;AN000;
	mov	[Init_SegID],ax ; save it						   ;AN000;
	jmp	short Reloc_Exit	;then return						   ;AN000;

Check_Seek:
	cmp	word [Total_Ext_Count],0 ; Fastseek function enabled ??
	jne	Reloc_Exit		; yes, no need for relocation

;-----------------------------------------------------------------------
; Relocate first portion of the Cseg_Init over Cseg_Seek segment. The size
; this portion should be same as the current size of Drive cache headers
; Anything more will overlay on Cseg_Init code which is currently active.
;-----------------------------------------------------------------------
	mov	ax, sizeof.DRIVE_CACHE_HEADER ; size of one drive cache hdr
	mov	cx,Max_drives		; CX = maximum number of drives
	mul	cx			; AX = size of Cseg_Init portion
	mov	cl,1
	shr	ax,cl			; AX = size of portion in words
	mov	cx,ax			; CX = number of WORDS to transfer			   ;AN000;
	mov	si,0			; offset of the source					   ;AN000;
	mov	di,0			; offset of the destination				   ;AN000;;AN000;
	mov	ax,CSEG_INIT_		; set source segID					   ;AN000;
	mov	ds,ax			; DS:SI-->Cseg_Seek					   ;AN000;
;	ASSUME	ds:Cseg_Init									   ;AN000;
	mov	ax,CSEG_SEEK_		; set destination seg id				   ;AN000;
	mov	es,ax			; ES:DI--> Cseg_Open				      ;AN000;
;	ASSUME	es:Cseg_Seek									   ;AN000;
												   ;AN000;
	REP	MOVSW			; relocate Cseg_Init over Cseg_Seek
	mov	ax,[SEEK_Size] ; reduce Seek seg size from
	sub	[RES_SEGS],ax ; the resident size

;-----------------------------------------------------------------------
; Compute the new segID after reloaction and save it
;-----------------------------------------------------------------------
	mov	ax,CSEG_INIT_		;
	mov	ds,ax			; DS-->Cseg_Init
;	ASSUME	ds:Cseg_Init
	mov	ax,CSEG_SEEK_		; AX = seg id of Cseg_Open in ext mem
	mov	[Init_SegID],ax

Reloc_Exit:
; copy the latest RES_SEGS size to Cseg_Main
	mov	ax,CSEG_INIT_		;							   ;AN000;
	mov	ds,ax			; DS-->Cseg_Init					   ;AN000;
;	ASSUME	ds:Cseg_Init									   ;AN000;
	mov	ax,CSEG_MAIN_		; set destination seg id				   ;AN000;;AN000;
	mov	es,ax			; ES--> Cseg_Main				   ;AN000; ;AN000;
;	ASSUME	es:Cseg_Main									   ;AN000;;AN000;
	mov	ax,[RES_SEGS]          ;AN000;
	mov	[es:Main_Res_Segs],ax ; save it						   ;AN000;

	RET											   ;AN000;

;RELOCATE_SEGMENT      ENDP


 



;-----------------------------------------------------------------------
; Procedure:   COPY_DATA
;-----------------------------------------------------------------------
; Copy data values from Cseg_Init to other segments.  I the code is relocated,
; seg IDs should be updated after relocation.  This is done in "Update_SegID"
;
; Input:     Variables inside Cseg_Open, CsegSeek and Cseg_Main segments
;
; Output:    Data values copied to the above segments
;
;
;-----------------------------------------------------------------------

COPY_DATA:

	mov	ax,CSEG_INIT_									   ;AN000;
	mov	ds,ax			      ;DS--> Cseg_Init			    ;AN000;
;	ASSUME	ds:Cseg_init									   ;AN000;
	mov	ax,CSEG_MAIN_									   ;AN000;
	mov	es,ax			      ;ES--> CSEG_MAIN			    ;AN000;
;	ASSUME	es:Cseg_Main									   ;AN000;
												   ;AN000;
	mov	word [es:Main_name_cache_seg], Cseg_Init  ;AN000;
	mov	ax,[num_of_drives]         ;AN000;
	mov	[es:Main_Num_Of_drives],ax        ;AN000;
	mov	ax,[Ext_Count]          ;AN000;
	mov	[es:Main_Ext_Count],ax         ;AN000;
	mov	ax,[extent_drive_Buff]         ;AN000;
	mov	[es:Main_extent_drive_Buff],ax        ;AN000;
	mov	ax,[name_cache_Buff]         ;AN000;
	mov	[es:Main_name_cache_Buff],ax         ;AN000;
	mov	ax,[Name_Drive_Buff]         ;AN000;
	mov	[es:Main_Name_Drive_Buff],ax        ;AN000;
	mov	ax,[EMS_FLAG]
	mov	[es:Main_EMS_FLAG],ax
	mov	ax,[EMS_PAGE_SEG]          ;AN000;
	mov	[es:Main_EMS_PAGE_SEG],ax         ;AN000;

IF	BUFFERFLAG
	mov	ax, [EMS_PAGE_NUM]
	mov	[es:EMS_PAGE_NUMBER], ax      ;HKN
end if
					       
	mov	ax,EMS_PAGE_SIZE								   ;AN000;
	mov	[es:Main_EMS_PAGE_SIZE],ax         ;AN000;
	mov	ax,[Total_Ext_Count]         ;AN000;
	mov	[es:Main_Total_Ext_Count],ax        ;AN000;
	mov	ax,[Ext_Cache_Size]         ;AN000;
	mov	[es:Main_ext_cache_size],ax       ;AN000;
	mov	ax,[Total_Name_Count]         ;AN000;
	mov	[es:Main_Total_Name_Count],ax

; Copy drive buffer to MAIN segment
	 lea   si,[Parambuff]          ;AN000;
	 lea   di,[es:Main_ParamBuff]         ;AN000;
	 mov   cx,50										   ;AN000;

Paramloop:
	 mov   al,[si]										   ;AN000;
	 mov   [es:di],al									   ;AN000;
	 inc   si										   ;AN000;
	 inc   di										   ;AN000;
	 LOOP  Paramloop									   ;AN000;

;-----------------------------------------------------------------------
; Copy data values to OPEN segment (Cseg_Open)
;-----------------------------------------------------------------------
	mov	ax,CSEG_OPEN_									   ;AN000;
	mov	es,ax			      ;ES--> CSEG_Open			    ;AN000;
;	ASSUME	es:Cseg_Open									   ;AN000;
	mov	si,Drive_Cache                  ;AN000;
	mov	[es:Open_name_Drive_Buff],si        ;AN000;
	mov	word [es:Open_name_cache_seg],Cseg_Init  ;AN000;
	mov	ax,[CHECK_QUEUE]
	mov	[es:Chk_Flag],ax

;-----------------------------------------------------------------------
; Copy data values to SEEK segment (Cseg_Seek) for Fastseek functions
;-----------------------------------------------------------------------
	mov	ax,CSEG_SEEK_									   ;AN000;
	mov	es,ax			      ;ES--> CSEG_Seek			    ;AN000;
;	ASSUME	es:Cseg_Seek									   ;AN000;
	mov	si,[extent_drive_Buff]         ;AN000;
	mov	[es:Seek_extent_drive_Buff],si        ;AN000;
	mov	word [es:Seek_name_cache_seg],Cseg_Init  ;AN000;
	mov	ax,[num_of_drives]         ;AN000;
	mov	[es:Seek_Num_Of_drives],ax        ;AN000;
	mov	ax,[Total_Ext_Count]        ;AN000;
	mov	[es:Seek_Total_Ext_Count],ax        ;AN000;
	mov	ax,[Total_Name_Count]        ;AN000;
	mov	[es:Seek_Total_Name_Count],ax         ;AN000;
	mov	ax,[name_cache_Buff]         ;AN000;
	mov	[es:Seek_Name_Cache_Buff],ax         ;AN000;
	mov	ax,[Name_Drive_Buff]         ;AN000;
	mov	[es:Seek_Name_Drive_Buff],ax        ;AN000;
	mov	ax,[CHECK_QUEUE]
	mov	[es:Check_Flag],ax
												   ;AN000;
	mov	ax,CSEG_INIT_									   ;AN000;
	mov	es,ax			      ;ES addressability to CSEG_Init			   ;AN000;
;	ASSUME	es:Cseg_Init									   ;AN000;
												   ;AN000;
	ret

;COPY_DATA	ENDP




;-----------------------------------------------------------------------
; Procedure:   ADJUST_SEGIDS
;-----------------------------------------------------------------------
; Function:  Adjust segment Ids of various segments after relocation
;
; Input:   SegID Vectors
;
; Output:  SegIDs vectors are adjusted
;
; Note: The following segid and vectors are set previously either during
;	link time or during initialization time.  These SegIDS needs to
;	be changed after the code and buffers are relocated.
;-----------------------------------------------------------------------

ADJUST_SEGIDS:

	mov	ax,CSEG_INIT_									   ;AN000;
	mov	ds,ax			      ;DS addressability to Cseg_Init			   ;AN000;
;	ASSUME	ds:Cseg_init									   ;AN000;;AN000;
	mov	ax,CSEG_MAIN_									   ;AN000;
	mov	es,ax			      ;ES addressability to CSEG_MAIN			   ;AN000;
;	ASSUME	es:Cseg_Main									   ;AN000;

	mov	bx, [Init_SegID]      ; copy seg ID of Init_Seg to			   ;AN000;
	mov	[es:Main_name_cache_seg], bx  ; Main seg					   ;AN000;

	cmp	word [Total_Name_Count],0 ; Fastopen function enabled ??
	je	Adjust_Seek		      ; yes, Adjust Cseg_Seek ID

	mov	ax,[Open_SegID]          ;AN000;
	mov	es,ax			      ; ES addressability to CSEG_Open			    ;AN000;
;	ASSUME	es:Cseg_Open		      ; copy segid of init_seg to			   ;AN000;
	mov	[es:Open_name_cache_seg], bx  ; Open segment

Adjust_Seek:
	cmp	word [Total_Ext_Count],0 ;Fastopen function enabled ??
	je	Adjust_Vectors		      ;yes, check Fastseek function

	mov	ax,[Seek_SegID]          ;AN000;
	mov	es,ax			      ; ES addressability to CSEG_Seek			    ;AN000;
;	ASSUME	es:Cseg_Seek									   ;AN000;
	mov	[es:Seek_name_cache_seg], bx        ;AN000;


; Adjust seg ids of jump vectors to Fastopen and Fastseek functions				   ;AN000;
Adjust_Vectors:
	mov	ax,CSEG_MAIN_									   ;AN000;
	mov	es,ax			      ;ES addressability to CSEG_MAIN			   ;AN000;
;	ASSUME	es:Cseg_Main									   ;AN000;
					      ;DS addressability to Cseg_Init
	mov	ax, [Open_SegID]          ;AN000;
; MASM read a type name in an expression as the number of bytes it
; takes up, so BYTE on its own is 1 and WORD is 2.
	mov	word [es:FOPEN_Insert+2], ax                ;AN000;
	mov	word [es:FOPEN_Update+2], ax                ;AN000;
	mov	word [es:FOPEN_Delete+2], ax                ;AN000;
	mov	word [es:FOPEN_Lookup+2], ax                ;AN000;
IF	BUFFERFLAG
	mov	word [es:FOPEN_Purge+2], ax                ;TEL 9/29
end if


	mov	ax, [Seek_SegID]          ;AN000;
	mov	word [es:FSEEK_Open	+2], ax                   ;AN000;
	mov	word [es:FSEEK_Close+2], ax                    ;AN000;
	mov	word [es:FSEEK_Insert+2], ax                   ;AN000;
	mov	word [es:FSEEK_Delete+2], ax                   ;AN000;
	mov	word [es:FSEEK_Lookup+2], ax                   ;AN000;
	mov	word [es:FSEEK_Truncate+2], ax                 ;AN000;
	mov	word [es:FSEEK_Purge+2], ax                    ;AN000;

	cmp	word [Total_Name_Count],0 ; Fastopen function enabled ??
	je	Adjust_Delete		      ; no , exit

; Change the segID of single Jump Vector inside Cseg_Main
	mov	ax,CSEG_MAIN_									   ;AN000;;AN000;
	mov	es,ax			      ;ES addressability to CSEG_MAIN			   ;AN000;;AN000;
;	ASSUME	es:Cseg_Main									   ;AN000;;AN000;
	mov	ax,[Open_SegID]          ;AN000;
	mov	word [es:VECTOR_LookUp+2], ax               ;;AN000;AN000;

Adjust_Delete:
	cmp	word [Total_Ext_Count],0 ; Fastseek function enabled ??
	je	Adjust_Exit		      ; no , exit

; Change the segID of single Jump Vector inside Cseg_Main
	mov	ax,CSEG_MAIN_									   ;AN000;;AN000;
	mov	es,ax			      ;ES addressability to CSEG_MAIN			   ;AN000;;AN000;
;	ASSUME	es:Cseg_Main									   ;AN000;;AN000;
	mov	ax,[Seek_SegID]          ;AN000;
	mov	word [es:VECTOR_Delete+2], ax               ;;AN000;AN000;

Adjust_Exit:
	ret											   ;AN000;
					      ;return
;ADJUST_SEGIDS	ENDP



 




;******************************************************************************
; *
; *	 MODULE: PARSE
; *
; *	 FUNCTION: Parse  command line
; *
; *	 INPUT: FASTOPEN  d: {=n | (n,m) } ... /x  เ
; *		   where เ activates queue analyser for debugging
; *
; *	 OUTPUT:   Command line is parsed
; *
; *	 RETURN SEQUENCE:
; *
; *		   If CY = 0	No error
; *
; *		   If CY = 1	Error
; *
; *	 EXTERNAL REFERENCES:	SYSPARSE
; *
; *************************************************************************

EOL	       equ   (-1)	; Indicator for End-Of-Line
NOERROR        EQU    0 	   ; Return Indicator for No Errors


PARSE:

	 mov   word [num_of_drives],0 ; initialize drive count
	 mov   word [Name_Count],0
	 mov   word [Ext_Count],0
	 mov   word [Total_Name_Count],0    ;AN000;
	 mov   word [Total_Ext_Count],0    ;AN000;
	 mov   byte [PREV_TYPE],0     ;AN000;
	 mov   word [Ext_Mem],0     ;AN000;
	 mov   word [CHECK_QUEUE],0     ;AN000;
	 lea   si,[Parambuff]   ; drive ID buff address					   ;AN000;
	 mov   [Parmbuff_Ptr],si   ; save it							   ;AN000;

;----------------------------------------------------------------------------
; Get command string address from PSP
;----------------------------------------------------------------------------
	 mov   si,0081H
	 mov   ah,62H
	 INT   21H		   ; get program PSP segment					   ;AN000;
	 mov   [psp_seg],bx  ; save PSP segment						   ;AN000;
												   ;AN000;
	 mov   ds,bx		   ; DS = PSP segment						   ;AN000;
	 mov   si,0081h 	   ; SI-->beginning of parameter string in PSP
	 lea   di,[Cmdline_buff]  ; DI-->command param buffer				 ;AN000;
	 mov   cx,127		   ; copy 127 bytes from PSP					   ;AN000;

;----------------------------------------------------------------------------
; Copy command parameters from PSP  to the  command buffer
;----------------------------------------------------------------------------
Cmdloop:
	 mov   al,[ds:si]	   ; DS:SI-->Command line					   ;AN000;
	 mov   [es:di],al	   ; ES:DI-->program command buffer				   ;AN000;
	 inc   si										   ;AN000;
	 inc   di										   ;AN000;
	 LOOP  Cmdloop		   ; copy command line
	 push  cs										   ;AN000;
	 pop   ds										   ;AN000;

;----------------------------------------------------------------------------
; set parametrs for SysParse call
;----------------------------------------------------------------------------
	 xor   cx,cx		   ; no params processed so far 				    ;AN000;
	 MOV  [ORDINAL],CX  ; SAVE initial ordinal value 				    ;AN000;
	 lea   si,[Cmdline_buff]  ; ES:SI-->command line								 ;AN000;
	 lea   di,[PARMS]   ; ES:DI-->parameter
	 MOV  [CURRENT_PARM],SI  ; pointer to next positional 				     ;AN000;

	 mov   ax,0100h 	   ; Drive only
	 mov   [Pos1Type],ax  ; set positional control block 1								 ;AN000;
	 mov   ax,08502h	   ; Numeric/Complex/Drive/Repeat
	 mov   [Pos2Type],ax  ; set positional control block 2								 ;AN000;
	 mov   al,1		   ; minimum 1 positional								 ;AN000;
	 mov   [par_min],al  ;
	 mov   al,2										   ;AN000;
	 mov   [par_max],al  ; maximum 1 positional								 ;AN000;
	 jmp   short Set_Param

;----------------------------------------------------------------------------
;   MAIN PARSE LOOP
;----------------------------------------------------------------------------
PARSE_LOOP:			   ; MAIN PARSE LOOP
	 mov   ax,08502h	   ; number/drive ID/comlex/repeat
	 mov   [Pos1Type],ax  ; set positional control block								 ;AN000;
	 mov   ax,08502h	   ;
	 mov   [Pos2Type],ax  ;
	 mov   al,1		   ; minimum 1 positional								 ;AN000;
	 mov   [par_min],al  ; set min
	 mov   al,2		   ; maximum 2 positionals								  ;AN000;
	 mov   [par_max],al  ; set max										 ;AN000;

Set_Param:
	 mov   byte [par_sw],1 ; set switch flag in PARSMX
	 xor   dx,dx
	 push  cs										   ;AN000;
	 pop   es		   ; ES=DS=CS							 ;AN000;
	 LEA  DI,[PARMS]   ; ES:DI = PARSE CONTROL DEFINITON				    ;AN000;
	 MOV  SI,[CURRENT_PARM]  ; DS:SI = next positional				 ;AN000;
	 XOR  DX,DX		   ; RESERVED, INIT TO ZERO					    ;AN000;
	 MOV  CX,[ORDINAL]  ; OPERAND ORDINAL, INITIALLY 				    ;AN000;

	 CALL  SysParse 	   ; Parse current positional

	 mov   [NEXT_PARM],si  ; save pointer to next positional				  ;AN000;
	 mov   [ORDINAL],CX  ; save current ordinal					   ;AN000;
	 cmp   ax,EOL		   ; END-OF-COMMAND string ??					   ;AN000;
	 jne   Parse_Chk_Error	   ; no -  check error


;----------------------------------------------------------------------------
; If previous positional is a drive ID without Name or Extent count then assign
; default counts .
;----------------------------------------------------------------------------
	 cmp   byte [PREV_TYPE],6 ; previous param = drive ID					   ;AN000;
	 jne   Take_Exit	   ; no - exit							    ;AN000;
												   ;AN000;
	 CALL  PROC_DEFAULT	   ; yes - setup default counts for previous drive			 ;AN000;
	 jnc   Take_Exit	   ; exit						 ;AN000;
	 jmp   PARSE_ERROR	   ; error exit 							       ;AN000;

Take_Exit:
	 CALL  VERIFY_COUNTS	   ; verify the Total counts
	 jnc   Counts_Ok	   ; exit if count ok
	 jmp   PARSE_ERROR	   ; else error exit

Counts_Ok:
	 jmp   Parse_Exit	   ; normal - exit


;----------------------------------------------------------------------------
;	CHECK ERROR CONDITIONS
;----------------------------------------------------------------------------
Parse_Chk_Error:		   ; check for error conditions
	 cmp   ax,NOERROR	   ; any parse error ??
	 jne   Verify_Missing_Oper ; yes - check missing operand
	 jmp   Chk_Result	   ; no - check result buffer					     ;AN000;

Verify_Missing_Oper:
	 cmp   ax,2		   ; yes - missing operand error??
	 jne   Disp_Error	   ; no - jump							    ;AN000;

	 cmp   byte [PREV_TYPE],0 ; yes - any previous parameters ??
	 jne   Chk_prev_drive	   ; yes, previous drive id							;AN000;
	 mov	 byte [MSG_CLASS],2
	 MOV	 [MSG_NUM],AX  ; set message number 					   ;AN000;
	 MOV	 word [SUBST_COUNT],0 ; no message substitution					   ;AN000;
	 MOV	 byte [INPUT_FLAG],0 ; no input							   ;AN000;
	 CALL	 PRINT_STDOUT	   ; show message						   ;AN000;
	 stc			   ; set error flag						   ;AN000;
	 jmp   Parse_Exit	   ; exit

;----------------------------------------------------------------------------
; If previous positional is drive ID without counts then assign default counts
;----------------------------------------------------------------------------
Chk_prev_drive:
	 cmp   byte [PREV_TYPE],6 ; previous param = drive ID ??				      ;AN000;
	 jne   Take_Exit1	   ; no - exit							    ;AN000;

	 CALL  PROC_DEFAULT	   ; yes - assign default ID
	 jnc   Take_Exit1	   ; no error, verify counts						   ;AN000;
	 jmp   PARSE_ERROR	   ; error exit 							       ;AN000;

Take_Exit1:
	 CALL  VERIFY_COUNTS	   ; verify the Total counts
	 jnc   Counts_right	   ; count ok - check special case
	 jmp   PARSE_ERROR	   ; error - exit

Counts_right:
	 cmp   byte [PREV_TYPE],0 ; no previous param ?  (Special case)					 ;AN000;
	 je    Invalid_Operand	   ; no, exit ( FASTOPEN >TEMP ) case				   ;AN000;
	 clc											   ;AN000;
	 jmp   Parse_Exit	   ; exit

Invalid_Operand:		   ; else error
	 jmp   Bad_Param

Disp_Error:
	 cmp   ax, 3		   ; invalid switch type ??
	 jne   Bad_Param	   ; no -
	 jmp   Bad_Switch

;----------------------------------------------------------------------------
; If user entered เ to activate the analyser, than verify the previous
; drive case. If true, assign default name extent entries, set activation
; flag and take normal exit.
;----------------------------------------------------------------------------
Bad_Param:
	mov   si,[CURRENT_PARM]  ; SI-->current parameter (analyser hook)
	mov   al,0e0h		   ; เ (hidden character to activate analyser)
	cmp   [si],al		   ; activate analyser ??
	jne   Set_Disp_Param	   ; no - normal error
	mov   word [CHECK_QUEUE],1 ; yes - set flag to activate analyser
	clc
	jmp   Chk_prev_drive	   ; exit

Set_Disp_Param:
	mov   di,[NEXT_PARM] ; ending address of bad param  (1/6/88)
	mov   al,0
	mov   [ds:di],al	   ; set termination character
	LEA   SI,[SUBLIST1] ; DS:SI-->Substitution list					   ;AN000;
	MOV   AX,[CURRENT_PARM] ; starting address of bad parameter				  ;AN000;
	MOV   [SI+SUB_LIST.DATA_OFF],AX ; SI-->File name						   ;AN000;
	MOV   [SI+SUB_LIST.DATA_SEG],DS ; DS-->Segment						   ;AN000;
	MOV   [SI+SUB_LIST.MSG_ID],0 ; message ID							   ;AN000;
	MOV   [SI+SUB_LIST.FLAGS],010H ; ASCIIZ string, left align					   ;AN000;
	MOV   [SI+SUB_LIST.MAX_WIDTH],0 ; MAXIMUM FIELD WITH						   ;AN000;
	MOV   [SI+SUB_LIST.MIN_WIDTH],0 ; MINIMUM FIELD WITH						   ;AN000;
	mov   ax,Incorrect_param  ; Error Code					;AN000;
	MOV   [MSG_NUM],AX ; set message number						   ;AN000;
	MOV   word [SUBST_COUNT],1 ; substitution count						   ;AN000;
	MOV   byte [MSG_CLASS],-1 ; message class						   ;AN000;
	MOV   byte [INPUT_FLAG],0 ; no input							   ;AN000;
	CALL  PRINT_STDOUT	  ; display message						   ;AN000;
	stc			  ; error flag
	jmp   Parse_Exit	  ; exit		      (1/6/88 P2670)


;----------------------------------------------------------------------------
;	CHECK POSITIONAL PARAMETER TYPE
;----------------------------------------------------------------------------
Chk_Result:
	 push  es		   ; get DS back to Program data segment			   ;AN000;
	 pop   ds										   ;AN000;
	 cmp   byte [PosType],1 ; number  ?? 						   ;AN000;
	 jne   chk_switch									   ;AN000;
	 jmp   short PROC_NAME	   ; yes, process name entry					   ;AN000;

chk_switch:
	 cmp   byte [PosType],3 ; switch  ?? 						   ;AN000;
	 je    Proc_Sw		   ; yes, process switch					   ;AN000;
	 cmp   byte [PosType],6 ; drive id ??						   ;AN000;
	 je    PROC_DRIVEID	   ; yes, Process Drive ID					   ;AN000;
	 cmp   byte [PosType],4 ; complex item ??						   ;AN000;
	 jne   disp_msg 									   ;AN000;
	 jmp   PROC_COMPLEX	   ; yes, process Complex item					   ;AN000;

disp_msg:
	 mov   ax,Incorrect_param  ; no, check reult buffer					   ;AN000;
	 jmp   Bad_Param	   ; else error 						   ;AN000;

Proc_Sw: jmp   Proc_Switch	   ; process switch						   ;AN000;



;----------------------------------------------------------------------------
;	    PROCESS  DRIVE ID
;----------------------------------------------------------------------------
PROC_DRIVEID:			   ; PROCESS DRIVE ID
	 cmp   byte [PREV_TYPE],6 ; previous param = drive ID					   ;AN000;
	 jne   Check_Drive_Id_fastinit	   ; no, jump							   ;AN000;
												   ;AN000;
; if not set default name and extent entry count for previous drive
	 CALL  PROC_DEFAULT	  ;  setup default counts					   ;AN000;
	 jnc   Check_Drive_Id_fastinit	  ;								   ;AN000;
	 jmp   PARSE_ERROR									   ;AN000;

Check_Drive_Id_fastinit: 		   ; process current drive ID
	 mov   ax,[valuelo]  ; get drive letter number from result buff			   ;AN000;
				   ; C:=3 D:=4 etc, Parser drive id convention			   ;AN000;
	 add   al,040H		   ; convert to drive letter					   ;AN000;

	 CALL  CHECK_DRIVE	   ; validate drive ID ??					   ;AN000;
	 jnc   Set_Drive_Id	   ; yes, jump							   ;AN000;
	 jmp   Parse_Exit	   ; no, invalid drive id , exit				   ;AN000;

Set_Drive_Id:
	 inc   word [num_of_drives] ; update the drive count					   ;AN000;
	 xor   ax,ax										   ;AN000;
	 mov   ax,[valuelo]  ; get drive number						   ;AN000;
	 xor   ah,ah		   ; only low byte is valid					   ;AN000;;AN000;
	 mov   di,[Parmbuff_Ptr]  ; DS:DI-->driveID buffer					   ;AN000;
	 dec   ax		   ; C:=2  D:=3 E:=4 etc Fastopen drive id			   ;AN000;
	 mov   [di],ax		   ; save drive in Drive ID table				   ;AN000;
	 add   word [Parmbuff_Ptr],2 ; points to next extent count area				   ;AN000;
	 mov   al,[PosType]  ; set previous type before look for next			   ;AN000;
	 mov   [PREV_TYPE],al  ; positional parameter					   ;AN000;
	 mov   si,[NEXT_PARM]  ; get pointer to next param (switch) 			   ;AN000;
	 mov   [CURRENT_PARM],si  ;								   ;AN000;
	 jmp   PARSE_LOOP	   ; look for next posistional parameter			   ;AN000;


;----------------------------------------------------------------------------
;	PROCESS INTEGER ( C:=n )  followed by drive ID
;----------------------------------------------------------------------------
PROC_NAME:
	 cmp   byte [PREV_TYPE], 6 ; previous type = drive ID
	 je    Get_Name_Value	   ; yes - jump
	 mov   ax,Incorrect_param  ; error code 						   ;AN000;
	 jmp   Bad_Param

Get_Name_Value:
	 xor   ax,ax										   ;AN000;
	 mov   ax,[valuelo]  ; get name value						   ;AN000;
	 cmp   ax,10		   ; check validity of the count				  ;AN000;
	 jl    Bad_Name_Count
	 cmp   ax,999										   ;AN000;
	 jle   Save_Name_Count	   ; count OK, save it					      ;AN000;

Bad_Name_Count: 		   ; bad name count
	 mov   ax,Invalid_name	   ; error code 						   ;AN000;
	 jmp   PARSE_ERROR	   ; error - exit						   ;AN000;

Save_Name_Count:
	 mov   [Name_Count],ax  ; save it (name count)
	 add   [Total_Name_Count],ax ; update total name count
	 mov   di,[Parmbuff_Ptr]  ; DS:DI-->driveID buffer					   ;AN000;
	 mov   ax,-1										   ;AN000;
	 mov   [di],ax		   ; MARK this drive has no extent entry			   ;AN000;
	 add   word [Parmbuff_Ptr],2 ; points to extent count area				   ;AN000;

Set_Drive_Hdr:
	 mov   ax,[Name_Count]  ; get name count entry								 ;AN000;
	 CALL  SET_DRIVE_CACHE_HEADER	; Set Name cache header 				   ;AN000;
	 jnc   Set_Min_Max	   ; no error set min and max								     ;AN000;
	 jmp   PARSE_ERROR	   ; display error								  ;AN000;

Set_Min_Max:
	 mov   al,1										   ;AN000;
	 mov   [par_min],al  ; change min-max						    ;AN000;
	 mov   al,2										   ;AN000;;AN000;
	 mov   [par_max],al          ;AN000;
	 mov   al,[PosType]  ; set previous type before look for next			  ;AN000;
	 mov   [PREV_TYPE],al          ;AN000;
	 mov   si,[NEXT_PARM]  ; get pointer to next param (switch) 			   ;AN000;
	 mov   [CURRENT_PARM],si  ;								   ;AN000;
	 mov   word [ORDINAL],0     ;AN000;
	 Jmp   PARSE_LOOP	   ; parse nexy positional								  ;AN000;


;----------------------------------------------------------------------------
;	 PROCESS COMPLEX (n,m)	followed by a drive id
;----------------------------------------------------------------------------
PROC_COMPLEX:
	 cmp   byte [PREV_TYPE], 6 ; previous type = drive ID ??
	 je    Get_Cmplx_Item	  ; yes - ok
	 mov   ax,Incorrect_param ; no - error, previous must be drive id						     ;AN000;
	 jmp   Bad_Param	  ; display error

Get_Cmplx_Item:
	 mov   al, [PosType] ;
	 mov   [PREV_TYPE],al ; save current type as previous
	 lea   di,[valuelo] ; DI-->result buffer						   ;AN000;
	 mov   si,[di]		  ; get next positional param address		    ;AN000;
	 mov   [CURRENT_PARM],si ; SI-->first complex item					   ;AN000;
	 mov   ax,08001h	  ; Control ( Numeric/Optional )		      ;AN000;
	 mov   [Pos1Type],ax ; change pos-param control block flag 			   ;AN000;
	 mov   [Pos2Type],ax          ;AN000;
	 mov   al,1		  ; atleast 1 or maximun two positionals in complex item								 ;AN000;
	 mov   [par_min],al ; set minimum = 1
	 mov   al,2										   ;AN000;
	 mov   [par_max],al ; set maximum = 2						       ;AN000;
	 mov   word [ORDINAL1],0 ; initialize ordinal for complex item loop			   ;AN000;
	 mov   byte [par_sw],0 ; reset switch flag in PARMSX

COMPLX_LOOP:
	 xor   dx,dx
	 LEA  DI,[PARMS]   ;ES:DI = PARSE CONTROL DEFINITON				   ;AN000;
	 MOV  SI,[CURRENT_PARM]  ;SI = COMMAND STRING, NEXT PARM				   ;AN000;
	 XOR  DX,DX		   ;RESERVED, INIT TO ZERO					   ;AN000;
	 MOV  CX,[ORDINAL1]  ;OPERAND ORDINAL, INITIALLY ZERO				   ;AN000;

	 CALL  SysParse 	   ; parse positional param in complex item

	 cmp   ax,NOERROR	   ; parse error ??
	 je    Chk_Complex_Result  ; no, check result buffer				    ;AN000;
	 cmp   ax,EOL		   ; END-OF-COMMAND string ??					   ;AN000;
	 jne   Complex_Error	   ; no, check error
	 mov   si,[NEXT_PARM]  ; Set pointer to next param	       (4/3/88)
	 mov   [CURRENT_PARM],si  ; set next param address before parsing		      ;AN000;
	 jmp   PARSE_LOOP	   ; go to main parse loop

Complex_Error:
	 mov   ax,Incorrect_param  ; no, check reult buffer					   ;AN000;
	 jmp   Bad_Param	   ; display error

;-------------------------------------------------------------------------------
;    Ckeck The Result Buffer
;-------------------------------------------------------------------------------
Chk_Complex_Result:
	 mov   [ORDINAL1],cx  ; save current ordinal		;AN000; 		   ;AN000;
	 cmp   byte [PosType],1 ; positional type = number  ??
	 je    Proc_Complex_Name   ; yes, process name entry					   ;AN000;
	 cmp   byte [PosType],3 ; positional type = String ??
	 je    Miss_Param	   ; yes, process missing parameter
	 mov   ax,Incorrect_param  ; no, check reult buffer					   ;AN000;
	 jmp   Bad_Param

Miss_Param:
	 mov  [CURRENT_PARM],si  ; save current chara pointer 				   ;AN000;
	 jmp   COMPLX_LOOP	   ; get extent count


;-------------------------------------------------------------------------------
;   PROCESS NAME  ENTRY  (n)
;-------------------------------------------------------------------------------
Proc_Complex_Name:		   ; PROCESS COMPLEX ITEM
	 mov  [CURRENT_PARM],si  ; save current chara pointer 				   ;AN000;
	 cmp   cx,2		   ; second positional in the complex				      ;AN000;
	 je    Proc_Extent_Entry   ; yes, process Extent count					   ;AN000;
	 xor   ax,ax		   ; eles process Name Count					  ;AN000;
	 mov   ax,[valuelo]  ; get name value from result buffer				   ;AN000;
	 cmp   ax,10		   ; validate the name value for higher 			  ;AN000;
	 jl    Name_Error	   ; and lower boundries					   ;AN000;
	 cmp   ax,Max_entry_num    ; name entry count ok ??
	 jg    Name_Error	   ; no - error
	 jmp   short Store_Name_Count	 ; yes - store it

Name_Error:			   ; invalid name count
	 mov   ax,Invalid_name	   ; error code 						   ;AN000;
	 jmp   PARSE_ERROR	   ; display error

Store_Name_Count:
	 mov   [Name_Count],ax  ; save it (name count)			  ;AN000;		     ;AN000;
	 add   [Total_Name_Count],ax ; update total name count			    ;AN000;		       ;AN000;

	 CALL  SET_DRIVE_CACHE_HEADER	; Set Name cache header 				   ;AN000;
	 jc    Cant_Set_Header	   ; jump if error					     ;AN000;
	 jmp   COMPLX_LOOP	   ; look for extent count					   ;AN000;

Cant_Set_Header:
	 jmp   PARSE_ERROR	   ; error exit


;-------------------------------------------------------------------------------
;   PROCESS EXTENT ENTRY  (m)
;-------------------------------------------------------------------------------
Proc_Extent_Entry:
	 mov   ax,[valuelo]  ; get extent count entry
	 cmp   ax,1		   ; validate entry between 1 an 10					       ;AN000;
	 jl    Extent_Error									   ;AN000;
	 cmp   ax,10
	 jl    Set_Default_Ext	   ; if <10 set default entry 12
	 cmp   ax,Max_entry_num    ; >999 ??
	 jg    Extent_Error	   ; yes - error
	 jmp   short Store_Extent_Count  ; value OK, save it

Set_Default_Ext:		   ; for count 1 throug 9 set default count 12
	 mov   ax,12
	 jmp   short Store_Extent_Count

Extent_Error:			   ; invalid entry error
	 mov   ax,Invalid_extent   ; error code
	 jmp   PARSE_ERROR	   ; display error						  ;AN000;

Store_Extent_Count:
	 mov   [Ext_Count],ax  ; save the count
	 add   [Total_Ext_Count],ax ; update total extent count
	 mov   di,[Parmbuff_Ptr]  ; DI-->drive/extent buffer					;AN000;
	 mov   [di],ax		   ; save in buffer						   ;AN000;
	 add   word [Parmbuff_Ptr],2 ; move pointer to next extent in buffer	;AN000;
	 mov   si,[NEXT_PARM]  ; get pointer to next param
	 mov   [CURRENT_PARM],si  ; set next param address before parsing		      ;AN000;
	 mov   byte [par_sw],1 ; set switch flag in PARMSX
	 Jmp   PARSE_LOOP	   ; parse next positional parameter				  ;AN000;


;----------------------------------------------------------------------------
;	    PROCESS SWITCH (/X) OPTION
;----------------------------------------------------------------------------
Proc_Switch:
	 cmp   byte [PREV_TYPE],0 ; any previous type ??
	 je    Switch_Error	   ; no  - error
	 cmp   word [Ext_Mem],0 ; switch previously specified ??					    ;AN000;
	 je    Set_Sw_flag	   ; no, set flag						   ;AN000;

Switch_Error:
	 mov   ax,Incorrect_param  ; error code 					      ;AN000;
	 jmp   Bad_Param	   ; error - /x could be specified only once

Set_Sw_flag:
	 cmp   byte [PREV_TYPE],6 ; previous param = drive ID	12/15 P2939				     ;AN000;
	 jne   Sw_save_ptr	   ; no - continue		12/15 p2939				       ;AN000;
												   ;AN000;
	 CALL  PROC_DEFAULT	   ; yes setup default counts for previous drive		       ;AN000;
	 jnc   Sw_save_ptr	   ; no error - continue	12/15 p2939					  ;AN000;
	 jmp   short PARSE_ERROR   ; error - exit		12/15 P2939						    ;AN000;

Sw_save_ptr:
	 mov   [CURRENT_PARM],si  ; save current chara pointer 				   ;AN000;
	 mov   bx,[synonym]  ; get synonym (/x)			;AN000; 		   ;AN000;
	 cmp   bx,E_Switch         ; /X ??							   ;AN000;
	 je    Set_ExtFlag	   ; yes - check result buffer					      ;AN000;
	 jmp   Bad_Switch	   ; error exit

Set_ExtFlag:			   ; no, check reult buffer
	 mov   word [Ext_Mem],1 ; yes, set Hi Memory flag					   ;AN000;
	 mov   si,[CURRENT_PARM]  ; -->next parameter						   ;AN000;
	 mov   al,[PosType]  ; set prevvious type before look for next			   ;AN000;
	 mov   [PREV_TYPE],al          ;AN000;
	 jmp   PARSE_LOOP						;AN000;

Bad_Switch:
	mov   di,[NEXT_PARM] ; ending address of bad param  1/6/88
	mov   al,0
	mov   [ds:di],al	   ; set termination character
	LEA   SI,[SUBLIST1] ; DS:SI-->Substitution list					   ;AN000;
	MOV   AX,[CURRENT_PARM] ; starting address of bad parameter				  ;AN000;
	MOV   [SI+SUB_LIST.DATA_OFF],AX ; SI-->File name						   ;AN000;
	MOV   [SI+SUB_LIST.DATA_SEG],DS ; DS-->Segment						   ;AN000;
	MOV   [SI+SUB_LIST.MSG_ID],0 ; message ID							   ;AN000;
	MOV   [SI+SUB_LIST.FLAGS],010H ; ASCIIZ string, left align					   ;AN000;
	MOV   [SI+SUB_LIST.MAX_WIDTH],0 ; MAXIMUM FIELD WITH						   ;AN000;
	MOV   [SI+SUB_LIST.MIN_WIDTH],0 ; MINIMUM FIELD WITH						   ;AN000;
	MOV   BX,Invalid_switch   ; get message number
	MOV   [MSG_NUM],BX ; set message number						   ;AN000;
	MOV   word [SUBST_COUNT],1 ; substitution count						   ;AN000;
	MOV   byte [MSG_CLASS],-1 ; message class						   ;AN000;
	MOV   byte [INPUT_FLAG],0 ; no input							   ;AN000;
	CALL  PRINT_STDOUT	  ; display message						   ;AN000;
	stc			  ; error flag
	jmp   Parse_Exit	  ; exit		      (1/6/88 P2670)



;----------------------------------------------------------------------------
;	      PROCESS PARSE ERROR
;----------------------------------------------------------------------------
PARSE_ERROR:			   ; AX = meassage number
	MOV	byte [MSG_CLASS],-1 ; message class						   ;AN000;
	MOV	[MSG_NUM],AX  ; set message number 					   ;AN000;
	MOV	word [SUBST_COUNT],0 ; no message substitution					   ;AN000;
	MOV	byte [INPUT_FLAG],0 ; no input							   ;AN000;
	CALL	PRINT_STDOUT	   ; show message						   ;AN000;
	stc			   ; set error flag						   ;AN000;

Parse_Exit:			   ; EXIT
	push	cs										   ;AN000;
	pop	ds		   ; DS - Program data area seg 				   ;AN000;
	ret								;AN000; 		   ;AN000;
;PARSE	ENDP			   ; end of parser




;----------------------------------------------------------------------------
;
; Procedure:  PROC_DEFAULT
;
; Function:   Process default parameters if name and extend counts
;	      are not specified with the drive id.
;
;----------------------------------------------------------------------------

PROC_DEFAULT:         ; PROCESS DEFAULT
	 push  si		   ; makesure to save next chara pointer			   ;AN000;
	 mov   ax,30h		   ; get default name count					   ;AN000;
	 mov   [Name_Count],ax  ; save it							   ;AN000;
	 add   [Total_Name_Count],ax ; update total name count					   ;AN000;
	 mov   [Ext_Count],ax  ; save it				;AN000; 		   ;AN000;
	 add   [Total_Ext_Count],ax ; save it			   ;AN000;			   ;AN000;
	 mov   di,[Parmbuff_Ptr]  ; DS:DI-->parameter buffer					   ;AN000;
	 mov   [di],ax		   ; save in buffer						   ;AN000;
	 add   word [Parmbuff_Ptr],2 ; points to next drive id position
	 mov   ax,[Name_Count]          ;AN000;
	 CALL  SET_DRIVE_CACHE_HEADER	; Set Name cache header 				   ;AN000;

Default_Exit:
	 pop   si										   ;AN000;
	 ret			   ; return								   ;AN000;

;PROC_DEFAULT   ENDP




;----------------------------------------------------------------------------
; Procedure:   VERIFY_COUNTS
;
; Function:    Verify the validity of the name and extent counts

;----------------------------------------------------------------------------
VERIFY_COUNTS:

; Check the validity of NAME and EXTENT count entries
	cmp	word [Total_Ext_Count],0 ; any extent param ??					    ;AN000;
	je	Chk_Name_Count		 ; no, dont check extent count				   ;AN000;
	cmp	word [Total_Ext_Count], Max_entry_num ; check lower boundry 					  ;AN000;
	jg	Invalid_ext		 ; error if not within								;AN000;
	clc				 ; Extent Count is valid

; Extent count is OK, check Name count
Chk_Name_Count:
	cmp	word [Total_Name_Count],0 ; any name param ??							      ;AN000;
	je	Verify_Exit		 ; no, dont check extent count				  ;AN000;

	cmp	word [Total_Name_Count], Max_entry_num ;AN000;
	jg	Invalid_name_entry								   ;AN000;
	clc				 ; Name count is OK							     ;AN000;
	jmp	short Verify_Exit	 ; exit 							 ;AN000;

Invalid_ext:
	mov	ax,Many_Ext_Entries	 ; AX = error code						       ;AN000;
	stc
	jmp	short Verify_Exit									 ;AN000;

Invalid_name_entry:
	mov	ax,Many_Name_Entries	 ; AX = error code								 ;AN000;
	stc											   ;AN000;

Verify_Exit:		     ;

	RET											   ;AN000;

;VERIFY_COUNTS	ENDP





 





;=========================================================================
; CHECK_DRIVE
;-----------------------------------------------------------------------
;
;  INPUT:  AL - Drive letter
;
;  OUTPUT:
;	   If Carry = 0
;	     user_drive       set to current entered drive letter
;	     num_Of_drives  incremented
;	   If Carry = 1       error
;-----------------------------------------------------------------------
; 1) see if drive is valid and removable using int 21h IOCTL
;
; 2) use int 21h name translate to make sure that the drive is not
;    redirected, substed, on another machine, or in any other way shape
;    or form hosed.
;=========================================================================

CHECK_DRIVE:

	CALL	CONVERT_TO_CAPS 	; make sure it is a capital letter
	mov	byte [user_drive],al   ; save it in user drive
	mov	byte [source_xname],al   ; put in source string for call

	mov	bl,al			;put drive letter in bl
	sub	bl,"A"-1                ;convert to 1 based number

	mov	ah,IOCtl		;set up for removable call
	mov	al,8			;function code
	INT	int_command

	cmp	ax,1			;is drive fixed?
	jz	Okay_Drive		;yes - see if it's subst
	cmp	ax,0fh			;is drive valid?
	jnz	Hosed_Drive		;yes - but hosed

	mov	ax,Invalid_drive	; set bad drive message
	jmp	short Drive_Error	; display error message

Okay_Drive:
	lea	si,[source_xname]; set up for name translate
	lea	di,[target_xname]
	mov	ax,xNameTrans SHL 8
	INT	int_command		;do the translation

	lea	si,[source_xname];compare source and target drive
	lea	di,[target_xname]

	mov	cx,Len_source_xname	;get count of invalid chars
	repz	cmpsb			;compare until mismatch found
	jz	Check_Drive_End 	;no mismatch - exit

Hosed_Drive:
	MOV   AX,Bad_Use_Message	 ; message number

Drive_Error:
	push  ax		  ; save message number
	mov   ax,[valuelo] ; get drive letter number from result buff
				  ; C:=3 D:=4 etc, Parser drive id convention
	add   al,040H		  ; convert to drive letter
	lea   si,[drive_id] ; DS:SI-->drive letter save area
	mov   [si],al		  ; save drive letter in buffer

	LEA   SI,[SUBLIST1] ; DS:SI-->Substitution list					   ;AN000;
	MOV   AX,drive_id                  ;AN000;
	MOV   [SI+SUB_LIST.DATA_OFF],AX ; SI-->File name						   ;AN000;
	MOV   [SI+SUB_LIST.DATA_SEG],DS ; DS-->Segment						   ;AN000;
	MOV   [SI+SUB_LIST.MSG_ID],1 ; message ID							   ;AN000;
	MOV   [SI+SUB_LIST.FLAGS],010H ; ASCIIZ string, left align					   ;AN000;
	MOV   [SI+SUB_LIST.MAX_WIDTH],0 ; MAXIMUM FIELD WITH						   ;AN000;
	MOV   [SI+SUB_LIST.MIN_WIDTH],0 ; MINIMUM FIELD WITH						   ;AN000;
	POP   AX		  ; restore message number					   ;AN000;
	MOV   [MSG_NUM],AX ; set message number						   ;AN000;
	MOV   word [SUBST_COUNT],1 ; substitution count						   ;AN000;
	MOV   byte [MSG_CLASS],-1 ; message class						   ;AN000;
	MOV   byte [INPUT_FLAG],0 ; no input							   ;AN000;
	CALL  PRINT_STDOUT	  ; display message						   ;AN000;
	stc			  ; error flag

Check_Drive_End:
	ret			  ; return

;CHECK_DRIVE  endp

 



;=========================================================================
;  Procedure:  SET_DRIVE_CACHE_HEADER
;
;  Function: Set name cache drive header
;
;  Input:  ax		    contains number of entries for num_entries
;	   user_drive	    contains user drive for drive_letter
;	   num_Of_drives  contains number of caches set up so far
;	   drive_cache	    offset of drive cache headers start
;  Output:
;	   If successful:
;	     drive cache header set up
;	     user_drive 	reset to blank
;	     num_Of_drives    incremented
;	   else
;	     bx 	      set to error flag
;	     dx 	      points to error message
;-----------------------------------------------------------------------
; 1) see if drive too many drives have been entered.
; 2) Walk through drive cache headers to make sure that the drive
;    letter was not previously entered.
; 3) Set up drive cache header
;=========================================================================

SET_DRIVE_CACHE_HEADER:

	mov	cx,[num_of_drives] ;get current count of drives
	mov	bx,Drive_Cache          ;get start of name drive cache
	mov	dl,[user_drive]  ;get user entered drive
	dec	cx			  ;is this the 1st drive entered ?
	jcxz	Set_it_up		  ;yes - don't check

	cmp	word [num_of_drives],Max_drives ;no - check for maximum num of drives
	jng	We_Have_Room		  ;yes - go check for dup drives
	mov	ax,Too_many_entries	  ;set up for error message
	stc				  ;set up error flag
	jmp	short Set_dheader_Exit	  ;and exit

;-----------------------------------------------------------------------
; Search through the drive headers to see the duplicate drive exist.
; If a new drive header at the bottom of the chain for the new drive.
; If no drives exist, then create the new header as the first drive header.
;-----------------------------------------------------------------------
We_Have_Room:				  ;BX-->current drive header
	cmp	dl,[bx+DRIVE_CACHE_HEADER.DCH_Drive_letter] ;drive header exist for this drive??
	jnz	Not_Dup_Drive		  ;no - continue
	mov	ax,Dup_drive		  ;yes - set up for error message
	stc
	jmp	short Set_dheader_Exit	  ;exit

Not_Dup_Drive:
	cmp	[bx+DRIVE_CACHE_HEADER.DCH_Sibling_ptr],No_siblings ;any more header to search ??
	jz	Set_drive_sibling		  ;no - go create the new drive header
	add	bx,sizeof.DRIVE_CACHE_HEADER ;yes - get pointer to next drive header
	jmp short We_Have_Room			  ;check it

Set_drive_sibling:
	mov	cx,bx				  ;save current header address
	add	cx,sizeof.DRIVE_CACHE_HEADER ;pointer to next header
	mov	[bx+DRIVE_CACHE_HEADER.DCH_Sibling_ptr],cx ;set pointer to new header from current hdr
	mov	bx,cx				  ;BX-->new header

Set_it_up:
	mov	[bx+DRIVE_CACHE_HEADER.DCH_Drive_letter],dl ;save drive letter in new header
	mov	[bx+DRIVE_CACHE_HEADER.DCH_Sibling_ptr],No_siblings ;mark new header as last header in chain
	mov	[bx+DRIVE_CACHE_HEADER.DCH_Num_Entries],ax ;save name count in new header

Set_dheader_Exit:				  ; Exit
	ret

;SET_DRIVE_CACHE_HEADER	 ENDP





subttl	Convert to caps
page
;=========================================================================
; Procedure: Convert_to_caps
;
; CONVERT LOWER CASE CHARACTERS TO UPPER CASE
; Convert character in al to a capital letter.

;=========================================================================

CONVERT_TO_CAPS:

	cmp	al,"a"
	JNAE	No_Convert
	cmp	al,"z"
	JNBE	No_Convert
	sub	al,32

No_Convert:
	ret					;and return

;CONVERT_TO_CAPS    ENDP


 




;=========================================================================
; SET_EMS		: THIS MODULE SETS EMS FOR FASTOPEN CODE AND DATA
;			  PAGE 0 IN HIGH MEMORY IS MAPPED FOR CODE USING
;			  THE PHYSICAL PAGE FRAME  AND PAGE 1 IS
;			  MAPPED FOR DATA USING PHYSICAL PAGE FRAME NUMBER
;			  TWO PHYSICAL PAGE FRAME SEG IDs ARE SAVED AND
;			  THEY WILL BE USED BY THE (MAIN) ROUTINE.
;
;	INPUTS		: NONE
;
;	OUTPUTS 	: CY  - ERROR
;
;			  NC  - EMS_PAGE_SEG - SEG ID OF SINGLE PAGE FRAME
;=========================================================================

SET_EMS:
	CALL	EMS_CHECK1		;SEE IF EMS INSTALLED					   ;AN000;
	JNC	EMS_GET_PAGE		; yes, get page 					   ;AN000;

	MOV	word [EMS_FLAG],0 ;  Flag EMS not installed				   ;AN000;
	STC				;  Make sure carry is Clear				   ;AN000;
	JMP	EMS_EXIT	  ;  Leave check routine				     ;AN000;

EMS_GET_PAGE:
	PUSH	ES			; save ES,DI they may destroy by 2F
	PUSH	DI

IF	NOT BUFFERFLAG

	MOV	AH,EMS_2F_HANDLER
	XOR	AL,AL
	INT	2FH			; see 2F is there
	CMP	AL,0FFH
	JNE	EMS_PAGE_ERR		; error, if not

	MOV	AH,EMS_2F_HANDLER
	MOV	AL,0FFH
	MOV	DI,0FEH
	INT	2FH		       ; get EMS page
	OR	AH,AH
	JNZ	EMS_PAGE_ERR
	MOV	[EMS_PAGE_SEG],ES      ; SAVE PAGE SEG ID
	MOV	[EMS_PAGE_NUM],DI      ; SAVE PHYSICAL PAGE NUMBER

ELSE

;---------------------------------------------------------------HKN 8/25/88
;	Fastopen must get an EMS page like a well behaved program and
;	should not grab a reserved page from the BIOS.
;
	mov	cx, [FRAME_COUNT]
	xor	ax, ax
	mov	bx, ax
	mov	dx, ax
	
get_page:
	cmp	word [es:di], 0a000h      ; is the page in ax above 640K
	jb	next_page		; if no get next_page

	mov	bx, di			; we have a valid page

	inc	dx			; count the # of pages above 640K

	cmp	dx, 1
	je	next_page
	sub	di, 4
	mov	ax, [es:di]
	mov	[FST_PAGE], ax
	mov	ax, [es:di+2]
	mov	[FST_PAGE+2], ax
	mov	di, bx			; restore di

next_page:
	add	di, 4
	loop	get_page
	jne	found_page
	jmp	EMS_PAGE_ERR

found_page:
;	int	3
	cmp	dx, 1
	jne	second_last_page
	mov	di, bx
	mov	ax, [es:di]
	mov	[EMS_PAGE_SEG], ax
	mov	ax, [es:di+2]
	mov	[EMS_PAGE_NUM], ax
	jmp	save_state

second_last_page:
	mov	ax, [FST_PAGE]
	mov	[EMS_PAGE_SEG], ax
	mov	ax, [FST_PAGE+2]
	mov	[EMS_PAGE_NUM], ax

save_state:
	push	es
	mov	ax, CSEG_MAIN_
	mov	es, ax
;	assume 	es:Cseg_Main

	mov	word [SAVE_MAP_ADDR], SAVE_EMS_PAGE_STATE
	mov	word [SAVE_MAP_ADDR+2], ax
	
	mov	ax, [EMS_PAGE_SEG]
	mov	[es:Main_EMS_PAGE_SEG], ax
	pop	es
;	assume	es:Cseg_Init
	call	[SAVE_MAP_ADDR]
	jc	EMS_PAGE_ERR

;--------------------------------------------------------------------------

end if

	POP	DI
	POP	ES
	JMP	SHORT EMS_ALLOCATE_PAGE

EMS_PAGE_ERR:
	POP	DI
	POP	ES
	STC				;yes, page not found					   ;AN000;
	JMP	SHORT EMS_ERROR 	;error exit						   ;AN000;

;-----------------------------------------------------------------------
; Allocate one page
;-----------------------------------------------------------------------
EMS_ALLOCATE_PAGE:
	MOV	BX,1		     ;one page							;AN000;
	MOV	AH,EMS_ALLOC_PAGES   ;set op code				   ;AN000;
	INT	EMS_INT 	     ;allocate page							   ;AN000;
	OR	AH,AH		     ;Was there an error allocating?				;AN000;
	JNZ	EMS_ERROR	     ;yes - display error							;AN000;
	MOV	[EXT_HANDLE],DX    ;no -Save EMS handle

IF	BUFFERFLAG

;------------------------------------------------------HKN 8/25/88
;	Must save ems handle in Cseg_Main also.

	push	es
	push	ax
	mov	ax, CSEG_MAIN_
	mov	es, ax
;	assume	es:Cseg_Main
	mov	[es:EMS_SAVE_HANDLE1], dx
	pop	ax
	pop	es
;	assume	es:Cseg_Init

end if

;-----------------------------------------------------------------------
; SET HANDLE NAME TO THE PAGE HANDLE
;-----------------------------------------------------------------------
	PUSH	DS										   ;AN000;
	POP	ES										   ;AN000;
;	ASSUME	ES:CSEG_INIT									   ;AN000;
	LEA	SI,[HANDLE_NAME]    ; DS:SI-->Handle name string				   ;AN000;
	MOV	DX,[EXT_HANDLE]    ; handle number						   ;AN000;
	MOV	AH,EMS_HANDLE_NAME								   ;AN000;
	MOV	AL,1		     ; set op code code 					    ;AN000;
	INT	67H		     ; set handle							       ;AN000;
	OR	AH,AH										   ;AN000;
	JNZ	EMS_ERROR	     ; jump if error								  ;AN000;

;-----------------------------------------------------------------------
; Map logical page 0 in physical page frame FE (P254)
;-----------------------------------------------------------------------
	CALL	MAP_FRAME	    ;map two pages						   ;AN000;
	JNC	EMS_GET_SIZE	    ;no error, normal exit					   ;AN000;

;-----------------------------------------------------------------------
; Get partial page map size
;-----------------------------------------------------------------------
EMS_GET_SIZE:
	MOV	AH,EMS_PAGE_SIZE    ;Allocate requested pages				       ;AN000;
	MOV	AL,2
	INT	EMS_INT 	    ;							       ;AN000;
	OR	AH,AH
	JNZ	EMS_ERROR
	XOR	AH,AH
	MOV	[EMS_PAGESIZE],AX   ;save EMS page size
	CLC
	JMP	SHORT EMS_EXIT

EMS_ERROR:
	MOV	AX,Ems_failed_fastinit	    ;error message						   ;AN000;
	MOV	[MSG_NUM],AX   ;save message number
	MOV	word [SUBST_COUNT],0 ;no message substitution					   ;AN000;
	MOV	byte [MSG_CLASS],-1 ;message class						   ;AN000;
	MOV	byte [INPUT_FLAG],0 ;no input							   ;AN000;
	CALL	PRINT_STDOUT	    ;show message "Incorrect Parameter"                            ;AN000;
	STC			    ; set error flag						   ;AN000;

EMS_EXIT:
	RET			    ;	 Return 					       ;AN000;

;SET_EMS   ENDP
 





;=========================================================================
; EMS_CHECK1		: THIS MODULE DETERMINES WHETHER OR NOT EMS IS
;			  INSTALLED FOR THIS SESSION.
;
;	INPUTS		: NONE
;
;	OUTPUTS 	: ES:BX - FRAME ARRAY
;			  CY	- EMS NOT AVAILABLE
;			  NC	- EMS AVAILABLE
;=========================================================================

EMS_CHECK1:            ;EMS INSTALL CHECK

	PUSH	DS			;save ds						   ;AN000;
	XOR	AX,AX			;set ax to 0						   ;AN000;
	MOV	DS,AX			;set ds to 0						   ;AN000;
	CMP	word [ds:067h*4+0],0    ;see if int 67h is there				   ;AN000;
	POP	DS			;restore ds						   ;AN000;
	JE	EMS_NOT_INST1		;no, EMS not installed					   ;AN000;

	MOV	AH,EMS_GET_STATUS	;YES, GET STATUS			     ;AN000;
	INT	EMS_INT 		;INT 67H						   ;AN000;
	CMP	AH,0			;EMS MANAGER PRESENT ??
	JNE	EMS_NOT_INST1		;NO, EMS NOT INSTALLED

	MOV	AH,EMS_GET_VERSION	;YES, GET STATUS			     ;AN000;	   ;AN000;
	INT	EMS_INT 		;INT 67H						   ;AN000;;AN000;
	CMP	AH,0			;EMS MANAGER PRESENT ?? 				   ;AN000;
	JNE	EMS_NOT_INST1		;NO, EMS NOT INSTALLED					   ;AN000;

	CMP	AL,40H			;VERSION 4.0 ?? 					   ;AN000;
	JNE	EMS_NOT_INST1		;NO, EMS NOT INSTALLED					   ;AN000;

	MOV	AX,EMS_GET_COUNT
	INT	EMS_INT 		;GET ARRAY COUNT
	CMP	AH,0
	JNE	EMS_NOT_INST1

	MOV	[FRAME_COUNT],CX
	MOV	AX, BUFFER_ENTRY_SIZE
	MUL	CX			; CALCULATE THE ARRAY SIZE BE RESERVED

IF	NOT IBMCOPYRIGHT
	CMP	AX, 100h			
ELSE
	CMP	AX, 30H				
end if

	JG	EMS_NOT_INST1

	MOV	AX,EMS_GET_FRAME_ADDR	;YES, GET FRAME ADDRESS 				   ;AN000;
	PUSH	DS			;SWAP DS & ES						   ;AN000;
	POP	ES			;							   ;AN000;
	LEA	DI,[FRAME_BUFFER];ES:DI--> RESULT BUFFER 				   ;AN000;
	INT	EMS_INT 		;GET FRAME ADDRESSES						     ;AN000;
	CMP	AH,0			;IS EMS INSTALLED					   ;AN000;
	JNE	EMS_NOT_INST1		;NO,exit
	CMP	CX,[FRAME_COUNT] ;				       ;AN000;
	JNE	SHORT EMS_NOT_INST1

	CLC
	MOV	word [EMS_FLAG],1 ; EMS IS ACTIVE, SET FLAG
	JMP	EMS_CHECK1_EXIT

EMS_NOT_INST1:				;EMS NOT INSTALLED
	MOV	AX,Ems_not_install	;error message						   ;AN000;
	MOV	[MSG_NUM],AX ;set message number					   ;AN000;
	MOV	word [SUBST_COUNT],0 ;no message substitution				   ;AN000;
	MOV	byte [MSG_CLASS],-1 ;message class						   ;AN000;
	MOV	byte [INPUT_FLAG],0 ;no input						   ;AN000;
	CALL	PRINT_STDOUT		;show message
	STC				;FLAG EMS NOT INSTALLED 				   ;AN000;
												   ;AN000;
EMS_CHECK1_EXIT:			;EXIT ROUTINE
	RET				;RETURN TO CALLER					   ;AN000;

;EMS_CHECK1 ENDP


 

;=========================================================================
; MAP_FRAME		: THIS MODULE MAPS TWO LOGICAL PAGES IN THE HIGH
;			  MEMORY TO TWO PHYSICAL PAGE FEAMES IN THE LOW
;			  MEMORY.
;
;	INPUTS		: EXT_HANDLE  - HANDLE
;
;	OUTPUTD 	  CY	- ERROR
;			  NC	- PAGE IS MAPPED
;=========================================================================

MAP_FRAME:                ; MAP physical page frames
	PUSH	BX			; DMS;
	XOR	BX,BX			; Logical page 0					   ;AN000;
	MOV	AX,[EMS_PAGE_NUM] ; AL=Physical Page frame number 			;AN000;
	MOV	AH,EMS_MAP_HANDLE	; AH=EMS function to map page				      ;AN000;
	MOV	DX,[EXT_HANDLE] ; EMS handle						   ;AN000;
	INT	EMS_INT 									   ;AN000;
	OR	AH,AH			; Was there an error allocating?			   ;AN000;
	JNZ	MAP_ERROR		; yes - set flag						     ;AN000;
	CLC
	JMP	SHORT MAP_EXIT		; no - exit							;AN000;

MAP_ERROR:
	STC				; set error flag					 ;AN000;

MAP_EXIT:
	POP	BX										   ;AN000;
	RET				; return						 ;AN000;


;MAP_FRAME ENDP




 



;************************************************************
;*
;*   SUBROUTINE NAME:	   PRINT_STDOUT
;*
;*   SUBROUTINE FUNCTION:
;*	   Display the requested message to the specified handle
;*
;*   INPUT:
;*	     Paramters in parater storage area
;*	     DS:SI-->Substitution List
;*	     ES:DI-->PTR to input buffer if buffered keyboard
;*		     input is specified (DL = 0A)
;*   OUTPUT:
;*	     AX =   Single character entered if DL=01
;*		OR
;*	     ES:DI-->input buffer where string is returned if DL=0A
;*
;*	The message corresponding to the requested msg number will
;*	be written to Standard Out. Message substitution will
;*	be performed if specified
;*
;*   NORMAL EXIT:
;*	Message will be successfully written to requested handle.
;*
;*   ERROR EXIT:
;*	None.  Note that theoretically an error can be returned from
;*	SYSDISPMSG, but there is nothing that the application can do.
;*
;*   INTERNAL REFERENCES:    SysDispMsg
;*
;*   EXTERNAL REFERENCES:
;*	None
;*
;************************************************************
PRINT_STDOUT:
	PUSH	BX										   ;AN000;
	PUSH	CX										   ;AN000;
	PUSH	DX										   ;AN000;

	MOV	AX,[MSG_NUM] ; Message ID						   ;AN000;
	MOV	BX,STDOUT		; standard input message handle 			   ;AN000;
	MOV	CX,[SUBST_COUNT] ; message substitution count				   ;AN000;
	MOV	DH,[MSG_CLASS] ; message class 					   ;AN000;
	MOV	DL,[INPUT_FLAG] ; Type of INT 10 for KBD input				   ;AN000;

	CALL	SYSDISPMSG		;  AX=Extended key value if wait			   ;AN000;
					;for key						   ;AN000;
	JNC	DISP_DONE		; If CARRY SET then registers
					;will contain extended error info			   ;AN000;
					;	AX - Extended error Number
					;	BH - Error Class
					;	BL - Suggested action
DISP_DONE:				;	CH - Locus
	POP	DX										   ;AN000;
	POP	CX										   ;AN000;
	POP	BX										   ;AN000;
												   ;AN000;
	RET
;PRINT_STDOUT ENDP


end if


;===========================================================================
;;;	    STACK    SEGMENT	   SIZE = 20 PARAGRAPHS
;===========================================================================

if SEGSEL = S_STACK
		DB	64 dup("STACK   ")     ; 512  WORD STACK AREA                               ;AN000;
end if


;END		START

