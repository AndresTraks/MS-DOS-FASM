;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	MACRO definitions for expanded memory manager
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	1. MACRO to save mapping context in case somebody else has
;	   mapped the page registers.
;
macro save_mapping_context 
{
local	save_agn_m,save_err_m,save_ok_m,save_exit_m
;	
;	the save mapping call for the above board -->
;
;		mov	ah,47h
;		mov	dx,handle
;		int	67h
;
;	on return ax = 0 signifies success
;
;
	push	ax		; save registers
	push	dx
;
;	set up emm registers and execute call to save mapping context
;
save_agn_m:
	mov	dx,[cs:ABOVE_PID]		; get emm handle
	mov	ah,ABOVE_SAVE_MAP_PID	; save map call
	int	67h			; call the manager
	or	ah,ah			; is there an error?
	jz	save_ok_m			; if not we are done
;
;	error in saving mapping context, check for error
;
	cmp	ah,ABOVE_ERROR_BUSY	; if the emm manager was busy
	jz	save_agn_m		; we would like to try again
;
;	unrecoverable error, indicate error type in al
;
	pop	dx
	pop	dx			; pop the regs off the stack
;
	mov	al,02h			; drive not ready
	cmp	ah,ABOVE_ERROR_CNTXT_NO_STACK	;
	jz	save_err_m
	cmp	ah,ABOVE_ERROR_SECOND_SAVE	;
	ja	save_err_m
	mov	al,0ch			; general failure
save_err_m:
	stc
	jmp	short save_exit_m
save_ok_m:
	clc
	pop	dx
	pop	ax			; restore registers
save_exit_m:
}
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	2. MACRO to restore the mapping context saved earlier
;
macro restore_mapping_context 
{
local	rest_agn_m, rest_ok_m, rest_exit_m
;
;	the restore above map call -->
;
;		mov	ah,48h
;		mov	dx,handle
;		int	67h
;	ah = 0 is success
;	
;
	push	ax
	pushf
;
rest_agn_m:
	mov	dx,[cs:ABOVE_PID]	; get emm handle
	mov	ah,ABOVE_RESTORE_MAP_PID ; restore map call
	int	67h			; call manager
	or	ah,ah			; is there any error
	jz	rest_ok_m			; if not go to finish up
;
;	error condition, check for recoverable error
;
	cmp	ah,ABOVE_ERROR_BUSY	; if manager was busy
	jz	rest_agn_m		; we sure can try again
	cmp	ah,ABOVE_ERROR_NO_CNTXT	;
	jz	rest_ok_m			; ignore invalid pid error
;
;	unrecoverable error
;
	pop	dx
	pop	dx
	mov	al,0ch			; general failure
	stc
	jmp	short rest_exit_m
;
rest_ok_m:
	popf
	pop	ax
rest_exit_m:
;
}
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	3. MACRO to map a page in the physical page map onto a logical
;	   page.
;
;	the map above page requires
;		mov	ah,44h
;		mov	dx,handle
;		mov	al,physical_page# (0-3)
;		mov	bx,logical_page#
;		int	67H
;	ah = 0 success and this routine zaps ax,dx and bx
;
macro map_page 
{
local	map_agn_m,map_exit_m,map_fin_m
;
	mov	ah,ABOVE_MAP	; function map page
	mov	dx,[cs:ABOVE_PID]	; get emm handle
;
	push	ax
;
map_agn_m:
	pop	ax
	push	ax
	push	bx
	push	dx		; "damn call above_map zaps these registers"
;
	int	67h		; map call
	pop	dx
	pop	bx
;
	or	ah,ah		; is there an error?
	jz	map_fin_m		; if not go to finish up
;
;	error condition - check for recoverable error
;
	cmp	ah,ABOVE_ERROR_BUSY	; if manager was busy
	jz	map_agn_m			; we sure can try again
;
;	unrecoverable error
;	
	pop	ax
	mov	al,02h			; device not ready error
	stc
	jmp	short map_exit_m
;
;	exit point
;
map_fin_m:
	clc
	pop	ax
map_exit_m:
;
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;			OTHER MACROS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	1) MACRO to switch es:di with ds:si
;
macro src_dest_switch 
{
;
	push	ds
	push	es
	push	si
	mov	si,di
	pop	di
	pop	ds
	pop	es
;
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
