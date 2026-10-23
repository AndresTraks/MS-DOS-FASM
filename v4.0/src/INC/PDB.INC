;	SCCSID = @(#)pdb.asm	1.1 85/04/10
BREAK <Process data BLOCK>

;
; Process data block (otherwise known as program header)
;

FilPerProc	    EQU     20

STRUC Process_data_block
{
.PDB_Exit_Call	    DW	    0		; INT int_abort system terminate
.PDB_block_len	    DW	    0		; size of execution block
		    DB	    0
.PDB_CPM_Call	    DB	5 dup (0)	; ancient call to system
.PDB_Exit	    DD	    0		; pointer to exit routine
.PDB_Ctrl_C	    DD	    0		; pointer to ^C routine
.PDB_Fatal_abort     DD	    0		; pointer to fatal error
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
.PDB_Parent_PID	    DW	    0		; PID of parent (terminate PID)
.PDB_JFN_Table	    DB	FilPerProc dup (0)
					; indices into system table
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
.PDB_environ	    DW	    0		; seg addr of environment
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
.PDB_User_stack	    DD	    0		; stack of self during system calls
.PDB_JFN_Length	    DW	    0		; number of handles allowed
.PDB_JFN_Pointer     DD	    0		; pointer to JFN table
.PDB_Next_PDB	    DD	    0		; pointer to nested PDB's
.PDB_PAD1	    DB	    14h dup (0)
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
.PDB_Call_system     DB	    5 dup (0)	; portable method of system call
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
.PDB_PAD2	    DB	    7h dup (0)
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
}
match =Process_data_block_LAID_OUT, Process_data_block_LAID_OUT
{
    Process_data_block_LAID_OUT equ 1
    virtual at 0
      Process_data_block Process_data_block
      sizeof.Process_data_block = $ - Process_data_block
    end virtual
}

PDB_InterCon	EQU	BYTE PTR PDB_PAD1	; 2/12/KK
PDB_Append	EQU	BYTE PTR PDB_PAD1+1	; 2/12/KK
