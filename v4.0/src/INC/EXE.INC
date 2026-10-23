;	SCCSID = @(#)exe.asm	1.1 85/04/10
;	SCCSID = @(#)exe.asm	1.1 85/04/10
BREAK <Exec and EXE file structures>
;
; EXEC arg block - load/go program
;

;
; The following get used as arguments to the EXEC system call.	They indicate
; whether or not the program is executed or whether or not a program header
; gets created.
;
exec_func_no_execute	EQU 1		; no execute bit
exec_func_overlay	EQU 2		; overlay bit

; Filled in where it stands, so the fields are the macro's arguments,
; each defaulting to what the structure declares.
STRUC Exec0 Exec0_environ_=0,Exec0_com_line_=0,Exec0_5C_FCB_=0,Exec0_6C_FCB_=0
{
.Exec0_environ	DW	Exec0_environ_; seg addr of environment
.Exec0_com_line	DD	Exec0_com_line_; pointer to asciz command line
.Exec0_5C_FCB	DD	Exec0_5C_FCB_; default fcb at 5C
.Exec0_6C_FCB	DD	Exec0_6C_FCB_; default fcb at 6C
}
match =Exec0_LAID_OUT, Exec0_LAID_OUT
{
    Exec0_LAID_OUT equ 1
    virtual at 0
      Exec0 Exec0
      sizeof.Exec0 = $ - Exec0
    end virtual
}

STRUC Exec1
{
.Exec1_environ	DW	0		; seg addr of environment
.Exec1_com_line	DD	0		; pointer to asciz command line
.Exec1_5C_FCB	DD	0		; default fcb at 5C
.Exec1_6C_FCB	DD	0		; default fcb at 6C
.Exec1_SP	DW	0		; stack pointer of program
.Exec1_SS	DW	0		; stack seg register of program
.Exec1_IP	DW	0		; entry point IP
.Exec1_CS	DW	0		; entry point CS
}
match =Exec1_LAID_OUT, Exec1_LAID_OUT
{
    Exec1_LAID_OUT equ 1
    virtual at 0
      Exec1 Exec1
      sizeof.Exec1 = $ - Exec1
    end virtual
}

STRUC Exec3
{
.Exec3_load_addr DW	0		; seg address of load point
.Exec3_reloc_fac DW	0		; relocation factor
}
match =Exec3_LAID_OUT, Exec3_LAID_OUT
{
    Exec3_LAID_OUT equ 1
    virtual at 0
      Exec3 Exec3
      sizeof.Exec3 = $ - Exec3
    end virtual
}

;
; Exit codes in upper byte
;
Exit_terminate	    EQU     0
Exit_abort	    EQU     0
Exit_Ctrl_C	    EQU     1
Exit_Hard_Error     EQU     2
Exit_Keep_process   EQU     3

;
; EXE file header
;

STRUC EXE_file
{
.exe_signature	DW  0			; must contain 4D5A  (yay zibo!)
.exe_len_mod_512 DW  0			; low 9 bits of length
.exe_pages	DW  0			; number of 512b pages in file
.exe_rle_count	DW  0			; count of reloc entries
.exe_par_dir	DW  0			; number of paragraphs before image
.exe_min_BSS	DW  0			; minimum number of para of BSS
.exe_max_BSS	DW  0			; max number of para of BSS
.exe_SS		DW  0			; stack of image
.exe_SP		DW  0			; SP of image
.exe_chksum	DW  0			; checksum  of file (ignored)
.exe_IP		DW  0			; IP of entry
.exe_CS		DW  0			; CS of entry
.exe_rle_table	DW  0			; byte offset of reloc table
.exe_iov 	DW  0			; overlay number (0 for root)
.exe_sym_tab	DD  0			; offset of symbol table in file
}
match =EXE_file_LAID_OUT, EXE_file_LAID_OUT
{
    EXE_file_LAID_OUT equ 1
    virtual at 0
      EXE_file EXE_file
      sizeof.EXE_file = $ - EXE_file
    end virtual
}

exe_valid_signature	EQU 5A4Dh
exe_valid_old_signature EQU 4D5Ah

STRUC symbol_entry
{
.sym_value	DD  0
.sym_type	DW  0
.sym_len 	DB  0
.sym_name	DB  255 dup (0)
}
match =symbol_entry_LAID_OUT, symbol_entry_LAID_OUT
{
    symbol_entry_LAID_OUT equ 1
    virtual at 0
      symbol_entry symbol_entry
      sizeof.symbol_entry = $ - symbol_entry
    end virtual
}
