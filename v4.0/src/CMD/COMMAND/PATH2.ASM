 PAGE 80,132
;	SCCSID = @(#)path2.asm	1.1 85/05/14
;	SCCSID = @(#)path2.asm	1.1 85/05/14
.sall
.xlist
.xcref
include 'DOSSYM.INC'
    include 'COMSW.ASM'
    include 'COMSEG.ASM'
    include 'COMEQU.ASM'
.list
.cref


if SEGSEL = S_DATARES
;	EXTRN	FORFLAG:BYTE
end if


BREAK <PATH.Asm>
;----------------------------------------------------------------------------
;    PATH.ASM contains the routines to perform pathname incovation.  Path and
;    Parse share a temporary buffer and argv[] definitions.  <Path_Search>,
;    given a pathname, attempts to find a corresponding executable or batch
;    file on disk.  Directories specified in the user's search path will be
;    searched for a matching file, if a match is not found in the current
;    directory and if the pathname is actually only an MSDOS filename.
;    <Path_Search> assumes that the parsed command name can be found in
;    argv[0] -- in other words, <Parseline> should be executed prior to
;    <Path_Search>.  Alternatively, the command name and appropriate
;    information could be placed in argv[0], or <Path_Search> could be
;    (easily) modified to make no assumptions about where its input is found.
;    Please find enclosed yet another important routine, <Save_Args>, which
;    places the entire arg/argv[]/argbuf structure on a piece of newly
;    allocated memory.	This is handy for for-loop processing, and anything
;    else that wants to save the whole shebang and then process other command
;    lines.
;
; Alan L, OS/MSDOS				    August 15, 1983
;
; ENTRY:
;   <Path_Search>:	    argv[0].
;   <Save_Args>:	    bytes to allocate in addition to arg structure
; EXIT:
;   <Path_Search>:	    success flag, best pathname match in EXECPATH.
;   <Save_Args>:	    success flag, segment address of new memory
; NOTE(S):
;   *	<Argv_calc> handily turns an array index into an absolute pointer.
;	The computation depends on the size of an argv[] element (arg_ele).
;   *	<Parseline> calls <cparse> for chunks of the command line.  <Cparse>
;	does not function as specified; see <Parseline> for more details.
;   *	<Parseline> now knows about the flags the internals of COMMAND.COM
;	need to know about.  This extra information is stored in a switch_flag
;	word with each command-line argument; the switches themselves will not
;	appear in the resulting arg structure.
;   *	With the exception of CARRY, flags are generally preserved across calls.
;---------------
; CONSTANTS:
;---------------
    DEBUGx	equ	    FALSE	; prints out debug info
;---------------
; DATA:
;---------------

if SEGSEL = S_TRANSPACE	;AC000;
;	EXTRN	arg:byte
;	EXTRN	BADPMES_ptr:word
;	EXTRN	curdrv:byte
;	EXTRN	EXECPATH:byte
;	EXTRN	ext_entered:byte	;AN005;
;	EXTRN	fbuf:byte
;	EXTRN	pathinfo:word
;	EXTRN	psep_char:byte
;	EXTRN	string_ptr_2:word
;	EXTRN	tpbuf:byte
end if

if SEGSEL = S_TRANCODE	;AC000;

;assume cs:trangroup, ds:trangroup, es:trangroup, ss:nothing


BREAK <SEARCH>
;----------------------------------------------------------------------------
;   SEARCH, when given a pathname, attempts to find a file with
; one of the following extensions:  .com, .exe, .bat (highest to
; lowest priority).  Where conflicts arise, the extension with
; the highest priority is favored.
; ENTRY:
;   DX		--	pointer to null-terminated pathname
;   fbuf	--	dma buffer for findfirst/next
; EXIT:
;   AX		--	8)  file found with .com extension
;			4)  file found with .exe extension
;			2)  file found with .bat extension
;			0)  no such file to be found
;   (if AX is non-zero:)
;   [search_best]	identical to AX
;   [search_best_buf]	null-terminated filename
; NOTES:
;   1)	Requires caller to have allocated a dma buffer and executed a setdma.
;---------------
; CONSTANTS:
;---------------
search_file_not_found	    equ 	0
search_com		    equ 	8
search_exe		    equ 	4
search_bat		    equ 	2
fname_len		    equ 	8
fname_max_len		    equ 	13
dot			    equ 	'.'
wildchar		    equ 	'?'

;---------------
; DATA:
;---------------
if SEGSEL = S_TRANSPACE	;AC000;
;	EXTRN	search_best:byte
;	EXTRN	search_best_buf:byte
;	EXTRN	search_curdir_buf:byte
;	EXTRN	search_error:word
end if

;---------------
procedure   SEARCH,NEAR
;---------------
	push	CX
	push	DX
	push	DI
	push	SI
	pushf

	push	DX				; check drivespec (save pname ptr)
	mov	DI, DX				; working copy of pathname
	mov	SI, search_curdir_buf
	xor	DX, DX				; zero means current drive
	cmp	byte [DI+1],':'                 ; is there a drive spec?
	jne	search_dir_check
	mov	DL, [DI]			; get the drive byte
	and	DL, NOT 20H			; uppercase the sucker
	sub	DL, '@'                         ; and convert to drive number

search_dir_check:
	trap	Current_Dir			; can we get the drive's current
	pop	DX				; directory?  If we can't we'll
	jc	search_invalid_drive		; assume it's a bad drive...

	mov	CX, search_attr 		; filetypes to search for
	trap	Find_First			; request first match, if any
	jc	search_no_file
	mov	byte [search_best], search_file_not_found
	mov	byte [search_best_buf], ANULL      ; nothing's been found, yet

search_loop:
	call	Search_Ftype			; determine if .com, &c...
	cmp	AL, [search_best] ; better than what we've found so far?
	jle	search_next			; no, look for another
	mov	[search_best], AL ; found something... save its code
	mov	SI, fbuf+find_buf.find_buf_pname
	mov	DI, search_best_buf
	mov	CX, fname_max_len
	cld
	rep	movsb				; save complete pathname representation
	cmp	AL, search_com			; have we found the best of all?
	je	search_done

search_next:					; keep on looking
	mov	CX, search_attr
	trap	Find_Next			; next match
	jnc	search_loop

search_done:					; it's all over with...
	mov	AL, [search_best] ; pick best to return with
	cmp	byte [ext_entered],1       ;AN005; Did user request a specific ext?
	jz	search_exit			;AN005; no - exit
	mov	al,[ext_entered] ;AN005; yes - get the real file type back
	mov	[search_best],al ;AN005; save the real file type
	jmp     search_exit

search_invalid_drive:				; Tell the user path/drive
	mov	DX, [search_error]		; appropriate error message
	invoke	STD_PRINTF			; and pretend no file found

search_no_file: 				; couldn't find a match
	mov	AX, search_file_not_found

search_exit:
	popf
	pop	SI
	pop	DI
	pop	DX
	pop	CX
	ret
;---------------
EndProc SEARCH
;----------------------------------------------------------------------------


BREAK <Search_Ftype>
;----------------------------------------------------------------------------
;   SEARCH_FTYPE determines the type of a file by examining its extension.
; ENTRY:
;   fbuf    --	    dma buffer containing filename
; EXIT:
;   AX	    --	    file code, as given in search header
; NOTE(S):
;   *	Implicit assumption that NULL == search_file_not_found
;---------------
; DATA:
;---------------
if SEGSEL = S_TRANDATA	;AC000;
;	extrn	comext:byte,exeext:byte,batext:byte
end if
;---------------
procedure   Search_Ftype,NEAR
;---------------
	push	DI
	push	si
	mov	AX, ANULL			; find the end of the filename
	mov	DI, fbuf+find_buf.find_buf_pname
	mov	CX, fname_max_len
	cld
	repnz	scasb				; search for the terminating null
	jnz	ftype_exit			; weird... no null byte at end
	sub	di,5				; . + E + X + T + NULL
;
; Compare .COM
;
	mov	si,comext
	mov	ax,di
	cmpsw
	jnz	ftype_exe
	cmpsw
	jnz	ftype_exe
	mov	AX, search_com			; success!
	jmp     ftype_exit
;
; Compare .EXE
;

ftype_exe:					; still looking... now for '.exe'
	mov	di,ax
	mov	si,exeext
	cmpsw
	jnz	ftype_bat
	cmpsw
	jnz	ftype_bat
	mov	AX, search_exe			; success!
	jmp     ftype_exit
;
; Compare .BAT
;

ftype_bat:					; still looking... now for '.bat'
	mov	di,ax
	mov	si,batext
	cmpsw
	jnz	ftype_fail
	cmpsw
	jnz	ftype_fail
	mov	AX, search_bat			; success!
	jmp     ftype_exit

ftype_fail:					; file doesn't match what we need
	mov	ax,ANULL

ftype_exit:
	cmp	byte [ext_entered],1       ;AN005; was an extension entered?
	jz	ftype_done			;AN005; no - exit
	cmp	ax,ANULL			;AN005; was any match found
	jz	ftype_done			;AN005; no - exit
	mov	[ext_entered],al ;AN005; save the match type found
	mov	AX, search_com			;AN005; send back best was found to stop search

ftype_done:					;AN005;
	pop	SI
	pop	DI
	ret

;---------------
EndProc Search_Ftype
;----------------------------------------------------------------------------


BREAK <Strip>
;----------------------------------------------------------------------------
;    STRIP copies the source string (argv[0]) into the destination buffer,
; replacing any extension with wildcards.
; ENTRY:
;	BX		--		maximum length of destination buffer
;	DS:SI		--		address of destination buffer
;	argv[0] 	--		command name to be stripped
; EXIT:
;	CF		--		set if failure, clear if successful
; NOTE(S):
;---------------
procedure   Strip,NEAR
;---------------
	push	AX
	push	BX
	push	CX
	push	DX
	push	DI
	push	SI
	pushf

	mov	byte [ext_entered],1       ;AN005; assume no extension on file name
	mov	DX, word [ds:ARG+arg_unit.argv+0+argv_ele.argpointer]      ; save pointer to beginning of argstring
	mov	DI, word [ds:ARG+arg_unit.argv+0+argv_ele.argstartel]      ; beginning of last pathname element
	cmp	byte [DI], 0      ; *STARTEL == NULL means no command
	jz	strip_error
	mov	CX, DX				; compute where end of argstring lies
	add	CX, word [ds:ARG+arg_unit.argv+0+argv_ele.arglen]
	sub	CX, DI				; and then find length of last element
	inc	CX				; include null as well
	mov	AL, dot 			; let's find the filetype extension
	cld
	repnz	scasb				; wind up pointing to either null or dot
	jcxz	process_ext			;AN005; if no extension found, just continue
	mov	byte [ext_entered],0       ;AN005; we found an extension
	mov	al,ANULL			;AN005; continue scanning until the
	repnz	scasb				;AN005;    end of line is reached.

process_ext:					;AN005;
	mov	CX, DI				; pointer to end of argstring yields
	sub	CX, DX				; number of bytes to be copied
	sub	BX, 4				; can argstring fit into dest. buffer?
	cmp	CX, BX
	jg	strip_error			; if not, we must have a bad pathname
	mov	DI, SI				; destination buffer
	mov	SI, DX				; source is beginning of pathname
	cld
	rep	movsb				; SI=arg,DI=buffer,CX=argend-argbeg
	cmp	byte [ext_entered],1       ;AN005; if an extension was entered
	jnz	skip_wilds			;AN005;    don't set up wildcard ext.

	dec	DI				; overwrite null or dot
	stosb					; with a dot
	mov	AL, wildchar			; now add wildcards
	stosb
	stosb
	stosb
	mov	AL, ANULL			; and a terminating null
	stosb

skip_wilds:					;AN005;
	popf
	clc					; chill out...
	jmp     strip_exit

strip_error:
	popf
	stc

strip_exit:
	pop	SI
	pop	DI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret
;---------------
EndProc Strip
;----------------------------------------------------------------------------


BREAK <Save_Args>
;----------------------------------------------------------------------------
;   SAVE_ARGS attempts to preserve the existing argv[]/argvcnt/argbuffer
; structure in newly allocated memory.	The argv[] structure is found at the
; beginning of this area.  The caller indicates how much extra space is
; needed in the resulting structure; Save_Args returns a segment number and
; an offset into that area, indicating where the caller may preserve its own
; data.  Note that <argvcnt> can be found at <offset-2>.
; ENTRY:
;   BX	    --	    size (in bytes) of extra area to allocate
; EXIT:
;   AX	    --	    segment of new area.
;   CF	    --	    set if unable to save a copy.
; NOTE(S):
;   1)	The allocated area will be AT LEAST the size requested -- since
;	the underlying MSDOS call, <alloc> returns an integral number of
;	paragraphs.
;   2)	It is an error if MSDOS can't allocate AT LEAST as much memory
;	as the caller of Save_Args requests.
;   3)	AX is undefined if CF indicates an error.
;---------------
procedure   Save_Args,NEAR
;---------------
	push	BX
	push	CX
	push	DX
	push	DI
	push	SI
	push	BP
	pushf
	add	BX, sizeof.arg_unit + 0FH  ; space for arg structure, round up
	mov	CL, 4				; to paragraph size and convert
	shr	BX, CL				; size in bytes to size in paragraphs
	trap	Alloc
	jc	save_error
	mov	BP, AX				; save segment id
	push	ES				; save TRANGROUP address
	mov	ES, AX				; switch to new memory segment
;assume	ES:nothing
	mov	CX, sizeof.arg_unit        ; get back structure size
	xor	DI, DI				; destination is new memory area
	mov	SI, ARG                  ; source is arg structure
	rep	movsb				; move that sucker!
	mov	CX, word [ARG+arg_unit.argvcnt]    ; adjust argv pointers
	xor	AX, AX				; base address for argv_calc
	mov	SI, ARG+arg_unit.argbuf - arg_unit.argbuf

save_ptr_loop:
	dec	CX				; exhausted all args?
	jl	save_done
	mov	BX, CX				; get arg index and
	invoke	argv_calc			; convert to a pointer
	mov	DX, word [ds:ARG+arg_unit.argv+BX+argv_ele.argpointer]
	sub	DX, SI				; adjust argpointer
	mov	word [es:arg_unit+arg_unit.argv+BX+argv_ele.argpointer], DX
	mov	DX, word [ds:ARG+arg_unit.argv+BX+argv_ele.argstartel]
	sub	DX, SI				; and adjust argstartel
	mov	word [es:arg_unit+arg_unit.argv+BX+argv_ele.argstartel], DX
	mov	DX, word [ds:ARG+arg_unit.argv+BX+argv_ele.arg_ocomptr]
	sub	DX, SI				; and adjust arg_ocomptr
	mov	word [es:arg_unit+arg_unit.argv+BX+argv_ele.arg_ocomptr], DX
	jmp	save_ptr_loop

save_done:
	pop	ES				; back we go to TRANGROUP
;assume	ES:trangroup
	mov	AX, BP				; restore segment id
	jmp     save_ok

save_error:
	popf
	stc
	jmp     save_exit

save_ok:
	popf
	clc
save_exit:
	pop	BP
	pop	SI
	pop	DI
	pop	DX
	pop	CX
	pop	BX
	ret
;---------------
EndProc Save_Args
;----------------------------------------------------------------------------

end if
;END
