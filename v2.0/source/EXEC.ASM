;SUBTTL $exec - load/go a program
PAGE
;
; Assembler usage:
;           LDS     DX, name
;           LES     BX, blk
;           MOV     AH, Exec
;           MOV     AL, func
;           INT     int_command
;
;       AL  Function
;       --  --------
;        0  Load and execute the program.
;        1  Load, create  the  program  header  but  do  not
;           begin execution.
;        3  Load overlay. No header created.
;
;           AL = 0 -> load/execute program
;
;           +---------------------------+
;           | WORD segment address of   |
;           | environment.              |
;           +---------------------------+
;           | DWORD pointer to ASCIZ    |
;           | command line at 80h       |
;           +---------------------------+
;           | DWORD pointer to default  |
;           | FCB to be passed at 5Ch   |
;           +---------------------------+
;           | DWORD pointer to default  |
;           | FCB to be passed at 6Ch   |
;           +---------------------------+
;
;           AL = 1 -> load program
;
;           +---------------------------+
;           | WORD segment address of   |
;           | environment.              |
;           +---------------------------+
;           | DWORD pointer to ASCIZ    |
;           | command line at 80h       |
;           +---------------------------+
;           | DWORD pointer to default  |
;           | FCB to be passed at 5Ch   |
;           +---------------------------+
;           | DWORD pointer to default  |
;           | FCB to be passed at 6Ch   |
;           +---------------------------+
;           | DWORD returned value of   |
;           | CS:IP                     |
;           +---------------------------+
;           | DWORD returned value of   |
;           | SS:IP                     |
;           +---------------------------+
;
;           AL = 3 -> load overlay
;
;           +---------------------------+
;           | WORD segment address where|
;           | file will be loaded.      |
;           +---------------------------+
;           | WORD relocation factor to |
;           | be applied to the image.  |
;           +---------------------------+
;
; Returns:
;           AX = exec_invalid_function
;              = exec_bad_format
;              = exec_bad_environment
;              = exec_not_enough_memory
;              = exec_file_not_found
;


; Converted from the MASM original, which was never assembled here: PROC.ASM
; includes this file only when IBM is clear, and this tree builds with IBM
; set, so the kernel took the stub beside the include instead and every
; external command answered EXEC failure.
;
; The original carries two builds.  Under IBM it is a separate far segment
; pair, ZEXEC_CODE and ZEXEC_DATA, with its own copies of get_user_stack and
; the SYS_RET pair, its own ctrl-C save and restore, and checks that keep the
; image it loads from overwriting the loader itself -- an EXEC that lives
; outside the resident DOS.  Nothing else in this tree knows about those
; segments, and the pieces that place them are not here, so only the near
; build below is converted; that is the one the Microsoft link used, with the
; code and data inside the DOS.
;
; PROC.ASM has ASSUME SS:DOSGROUP, so MASM reached this module's variables
; through SS wherever DS was NOTHING and through DS where an ASSUME had put
; DOSGROUP in it.  FASM has no ASSUME, so those overrides are written out.

exec_blk            DD  ?
exec_func           DB  ?
exec_fh             DW  ?
exec_rel_fac        DW  ?
exec_res_len_para   DW  ?
exec_init_IP        DW  ?
exec_init_CS        DW  ?
exec_init_SP        DW  ?
exec_init_SS        DW  ?
exec_environ        DW  ?
exec_size           DW  ?
exec_load_block     DW  ?

exec_load_high      DB  ?

; EQU is a preprocessor directive in FASM and would substitute the text "$"
; at each use, so these two are assembly-time constants instead.
exec_internal_buffer    =   $
exec_signature      DW  ?               ; must contain 4D5A  (yay zibo!)
exec_len_mod_512    DW  ?               ; low 9 bits of length
exec_pages          DW  ?               ; number of 512b pages in file
exec_rle_count      DW  ?               ; count of reloc entries
exec_par_dir        DW  ?               ; number of paragraphs before image
exec_min_BSS        DW  ?               ; minimum number of para of BSS
exec_max_BSS        DW  ?               ; max number of para of BSS
exec_SS             DW  ?               ; stack of image
exec_SP             DW  ?               ; SP of image
exec_chksum         DW  ?               ; checksum  of file (ignored)
exec_IP             DW  ?               ; IP of entry
exec_CS             DW  ?               ; CS of entry
exec_rle_table      DW  ?               ; byte offset of reloc table
exec_iov            DW  ?               ; overlay number (0 for root)
exec_dma            DW  ?
exec_internal_buffer_size   =   $-exec_internal_buffer

        procedure   _EXEC,NEAR
        ASSUME  DS:NOTHING, ES:NOTHING
;
; validate function
;
        CMP     AL,3                    ; only 0, 1 or 3 are allowed
        JNA     exec_check_2

exec_bad_fun:
        error   error_invalid_function

exec_ret_err:
        transfer    SYS_RET_ERR

exec_check_2:
        CMP     AL,2
        JZ      exec_bad_fun

        MOV     WORD [SS:exec_blk],BX   ; stash args
        MOV     WORD [SS:exec_blk+2],ES
        MOV     BYTE [SS:exec_func],AL
        MOV     BYTE [SS:exec_load_high],0
        XOR     AL,AL                   ; open for reading
        invoke  _OPEN                   ; is the file there?
        JC      exec_ret_err
        MOV     [SS:exec_fh],AX
        MOV     BX,AX
        XOR     AL,AL
        invoke  _IOCTL
        TEST    DL,devid_ISDEV
        JZ      exec_check_environ
        MOV     AL,exec_file_not_found
        transfer    SYS_RET_ERR

exec_check_environ:
        MOV     WORD [SS:exec_load_block],0

        TEST    BYTE [SS:exec_func],exec_func_overlay   ; overlays... no environment
        JNZ     exec_read_header
        LDS     SI,DWORD [SS:exec_blk]  ; get block
        MOV     AX,[SI+Exec1.Exec1_environ] ; address of environ
        OR      AX,AX
        JNZ     exec_scan_env
        MOV     DS,[SS:CurrentPDB]
        MOV     AX,[DS:Process_data_block.PDB_environ]
        MOV     [SS:exec_environ],AX
        OR      AX,AX
        JZ      exec_read_header

exec_scan_env:
        CLD
        MOV     ES,AX
        XOR     DI,DI
        MOV     CX,07FFFh               ; at most 32k of environment
        XOR     AL,AL

exec_get_environ_len:
        REPNZ   SCASB                   ; find that nul byte
        JZ      exec_check              ; CX is out... bad environment
        MOV     AL,exec_bad_environment
        JMP     exec_bomb

exec_check:
        SCASB                           ; is there another nul byte?
        JNZ     exec_get_environ_len    ; no, scan some more
        PUSH    DI
        MOV     BX,DI                   ; AX <- length of environment
        ADD     BX,0Fh
        MOV     CL,4
        SHR     BX,CL                   ; number of paragraphs needed
        PUSH    ES
        invoke  _ALLOC                  ; can we get the space?
        POP     DS
        POP     CX
        JNC     exec_save_environ
        JMP     exec_no_mem             ; nope... cry and sob

exec_save_environ:
        MOV     ES,AX
        MOV     [SS:exec_environ],AX    ; save him for a rainy day
        XOR     SI,SI
        XOR     DI,DI
        REP     MOVSB                   ; copy the environment

exec_read_header:
;
; We read in the program header into the above data area and determine
; where in this memory the image will be located.
;
        PUSH    SS
        POP     DS                      ; and put it in DS:DX
        ASSUME  DS:DOSGROUP
        MOV     CX,exec_internal_buffer_size; header size
        MOV     BX,[exec_fh]            ; from the handle
        MOV     DX,exec_signature
        PUSH    ES
        PUSH    DS
        CALL    exec_dealloc
        invoke  _READ
        CALL    exec_alloc
        POP     DS
        POP     ES
        JC      exec_bad_file
        CMP     AX,exec_internal_buffer_size; did we read the right number?
        JNZ     exec_com_filej          ; yep... continue
        CMP     WORD [exec_max_BSS],0
        JNZ     exec_check_sig
        MOV     BYTE [exec_load_high],-1
exec_check_sig:
        MOV     AX,[exec_signature]
        CMP     AX,exe_valid_signature  ; zibo arises!
        JZ      exec_save_start         ; assume com file if no signature
        CMP     AX,exe_valid_old_signature  ; zibo arises!
        JZ      exec_save_start         ; assume com file if no signature

exec_com_filej:
        JMP     exec_com_file

;
; We have the program header... determine memory requirements
;
exec_save_start:
        MOV     AX,[exec_pages]         ; get 512-byte pages
        MOV     CL,5                    ; convert to paragraphs
        SHL     AX,CL
        SUB     AX,[exec_par_dir]       ; AX = size in paragraphs
        MOV     [exec_res_len_para],AX

;
; Do we need to allocate memory?  Yes if function is not load-overlay
;
        TEST    BYTE [exec_func],exec_func_overlay
        JZ      exec_allocate           ; allocation of space
;
; get load address from block
;
        LES     DI,DWORD [exec_blk]
        MOV     AX,[ES:DI+Exec3.Exec3_load_addr]
        MOV     [exec_dma],AX
        MOV     AX,[ES:DI+Exec3.Exec3_reloc_fac]
        MOV     [exec_rel_fac],AX
        JMP     SHORT exec_find_res

exec_no_mem:
        MOV     AL,exec_not_enough_memory
        JMP     SHORT exec_bomb             ; AX should be set by _ALLOC

exec_bad_file:
        MOV     AL,exec_bad_format

exec_bomb:
        ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    AX
        MOV     BX,[SS:exec_fh]
        CALL    exec_dealloc
        invoke  _CLOSE
        POP     AX
        transfer    SYS_RET_ERR

exec_allocate:
        ASSUME  DS:DOSGROUP
        PUSH    AX
        MOV     BX,0FFFFh               ; see how much room in arena
        PUSH    DS
        invoke  _ALLOC                  ; should have carry set and BX has max
        POP     DS
        POP     AX
        ADD     AX,10h                  ; room for header
        CMP     BX,11h                  ; enough room for a header
        JB      exec_no_mem
        CMP     AX,BX                   ; is there enough for bare image?
        JA      exec_no_mem
        CMP     BYTE [exec_load_high],0 ; if load high, use max
        JNZ     exec_BX_max             ; use max
        ADD     AX,[exec_min_BSS]       ; go for min allocation
        JC      exec_no_mem             ; oops! carry
        CMP     AX,BX                   ; enough space?
        JA      exec_no_mem             ; nope...
        SUB     AX,[exec_min_BSS]
        ADD     AX,[exec_max_BSS]       ; go for the MAX
        JC      exec_BX_max
        CMP     AX,BX
        JBE     exec_got_block

exec_BX_max:
        MOV     AX,BX

exec_got_block:
        PUSH    DS
        MOV     BX,AX
        MOV     [exec_size],BX
        invoke  _ALLOC                  ; get the space
        POP     DS
        JC      exec_no_mem
        MOV     [exec_load_block],AX
        ADD     AX,10h
        CMP     BYTE [exec_load_high],0
        JZ      exec_use_ax             ; use ax for load info
        ADD     AX,[exec_size]          ; go to end
        SUB     AX,[exec_res_len_para]  ; drop off header
        SUB     AX,10h                  ; drop off pdb
exec_use_ax:
        MOV     [exec_rel_fac],AX       ; new segment
        MOV     [exec_dma],AX           ; beginning of dma

;
; Determine the location in the file of the beginning of the resident
;
exec_find_res:
        MOV     DX,[exec_par_dir]
        PUSH    DX
        MOV     CL,4
        SHL     DX,CL                   ; low word of location
        POP     AX
        MOV     CL,12
        SHR     AX,CL                   ; high word of location
        MOV     CX,AX                   ; CX <- high

;
; Read in the resident image (first, seek to it)
;
        MOV     BX,[exec_fh]
        PUSH    DS
        XOR     AL,AL
        invoke  _LSEEK                  ; seek to resident
        POP     DS

exec_big_read:                          ; Read resident into memory
        MOV     BX,[exec_res_len_para]
        CMP     BX,1000h                ; too many bytes to read?
        JB      exec_read_ok
        MOV     BX,0FE0h                ; max in one chunk FE00 bytes

exec_read_ok:
        SUB     [exec_res_len_para],BX  ; we read (soon) this many
        PUSH    BX
        MOV     CL,4
        SHL     BX,CL                   ; get count in bytes from paras
        MOV     CX,BX                   ; count in correct register
        MOV     BX,[exec_fh]            ; handle in correct register
        PUSH    DS
        MOV     DS,[SS:exec_dma]        ; Set up read buffer
        ASSUME  DS:NOTHING
        XOR     DX,DX
        PUSH    CX                      ; save our count
        CALL    exec_dealloc
        invoke  _READ                   ; WOMP!
        CALL    exec_alloc
        POP     CX                      ; get old count to verify
        POP     DS
        ASSUME  DS:DOSGROUP
        CMP     CX,AX                   ; did we read enough?
        POP     BX                      ; get paragraph count back
        JNZ     exec_do_reloc           ; and do reloc if no more to read
;
; We've read in CX bytes... bump DTA location
;

        ADD     [exec_dma],BX           ; bump dma address
        CMP     WORD [exec_res_len_para],0
        JNZ     exec_big_read

;
; The image has now been read in.  We must perform relocation to
; the current location.
;

exec_do_reloc:
        MOV     CX,[exec_rel_fac]
        MOV     AX,[exec_SS]            ; get initial SS
        ADD     AX,CX                   ; and relocate him
        MOV     [exec_init_SS],AX

        MOV     AX,[exec_SP]            ; initial SP
        MOV     [exec_init_SP],AX

        LES     AX,DWORD [exec_IP]
        MOV     [exec_init_IP],AX
        MOV     AX,ES
        ADD     AX,CX                   ; relocated...
        MOV     [exec_init_CS],AX

        XOR     CX,CX
        MOV     DX,[exec_rle_table]
        MOV     BX,[exec_fh]
        PUSH    DS
        XOR     AX,AX
        invoke  _LSEEK
        POP     DS

        JNC     exec_get_entries
exec_bad_filej:
        JMP     exec_bad_file

exec_get_entries:
        MOV     DX,[exec_rle_count]     ; Number of entries left

exec_read_reloc:
        PUSH    DX
        MOV     DX,exec_signature
        MOV     CX,((exec_internal_buffer_size)/4)*4
        MOV     BX,[SS:exec_fh]
        PUSH    DS
        CALL    exec_dealloc
        invoke  _READ
        CALL    exec_alloc
        POP     ES
        POP     DX
        JC      exec_bad_filej
        MOV     CX,(exec_internal_buffer_size)/4
        MOV     DI,exec_signature       ; Pointer to byte location in header
;
; Relocate a single address
;
        MOV     SI,[SS:exec_rel_fac]
        ASSUME  DS:NOTHING

exec_reloc_one:
        CMP     DX,0                    ; Any more entries?
        JNE     exec_get_addr
        JMP     exec_set_PDB

exec_get_addr:
        LDS     BX,DWORD [ES:DI]        ; Get ra/sa of entry
        MOV     AX,DS                   ; Relocate address of item
        ADD     AX,SI
        MOV     DS,AX
        MOV     AX,[BX]                 ; Relocate item
        ADD     AX,SI
        MOV     [BX],AX
        ADD     DI,4
        DEC     DX
        LOOP    exec_reloc_one              ; End of internal buffer?

;
; We've exhausted a single buffer's worth.  Read in the next piece
; of the relocation table.
;

        PUSH    ES
        POP     DS
        JMP     exec_read_reloc

exec_no_memj:
        JMP     exec_no_mem

;
; we have a .COM file.  First, determine if we are merely loading an overlay.
;
exec_com_file:
        ASSUME  DS:DOSGROUP
        TEST    BYTE [exec_func],exec_func_overlay
        JZ      exec_alloc_com_file
        LDS     SI,DWORD [exec_blk]     ; get arg block
        ASSUME  DS:NOTHING
        LODSW                           ; get load address
        MOV     [SS:exec_dma],AX
        JMP     SHORT exec_64k          ; read it all!

; We must allocate the max possible size block (ick!)  and set up
; CS=DS=ES=SS=PDB pointer, IP=100, SP=max size of block.
;
exec_alloc_com_file:
        ASSUME  DS:DOSGROUP
        MOV     BX,0FFFFh
        invoke  _ALLOC                  ; largest piece available as error
        OR      BX,BX
        JZ      exec_no_memj
        MOV     [SS:exec_size],BX       ; save size of allocation block
        PUSH    BX
        invoke  _ALLOC                  ; largest piece available as error
        POP     BX                      ; get size of block...
        MOV     [SS:exec_load_block],AX
        ADD     AX,10h                  ; increment for header
        MOV     [SS:exec_dma],AX
        SUB     BX,10h                  ; remember header
        CMP     BX,1000h                ; 64k or more?
        JAE     exec_64k                ; yes, read only 64k
        MOV     AX,BX                   ; convert size to bytes
        MOV     CL,4
        SHL     AX,CL
        JMP     SHORT exec_read_com

exec_64k:
        MOV     AX,0FFFFh               ; 64k-1 bytes

exec_read_com:
        ASSUME  DS:NOTHING
        PUSH    AX                      ; save number to read
        MOV     BX,[SS:exec_fh]         ; of com file
        XOR     CX,CX                   ; but seek to 0:0
        MOV     DX,CX
        XOR     AX,AX                   ; seek relative to beginning
        invoke  _LSEEK                  ; back to beginning of file
        MOV     BX,[SS:exec_fh]
        POP     CX                      ; number to read
        MOV     DS,[SS:exec_dma]
        XOR     DX,DX
        PUSH    CX
        CALL    exec_dealloc
        invoke  _READ                   ; read in com file
        CALL    exec_alloc
        POP     SI                      ; get number of bytes to read
        CMP     AX,SI                   ; did we read them all?
        JZ      exec_no_memj            ; exactly the wrong number... no memory
        TEST    BYTE [SS:exec_func],exec_func_overlay
        JNZ     exec_set_PDB            ; no starto, chumo!
        MOV     AX,[SS:exec_dma]
        SUB     AX,10h
        MOV     [SS:exec_init_CS],AX
        MOV     WORD [SS:exec_init_IP],100h ; initial IP is 100
        ; SI is at most FFFFh
        DEC     SI                      ; make room for stack
        ; SI is at most FFFEh, room for a 0!
        MOV     [SS:exec_init_SP],SI    ; max value for read is also SP!
        MOV     [SS:exec_init_SS],AX
        MOV     DS,AX
        MOV     WORD [SI],0             ; 0 for return

exec_set_PDB:
        MOV     BX,[SS:exec_fh]         ; we are finished with the file.
        CALL    exec_dealloc
        invoke  _CLOSE                  ; release the jfn
        CALL    exec_alloc
        TEST    BYTE [SS:exec_func],exec_func_overlay
        JZ      exec_build_header
        transfer    SYS_RET_OK          ; overlay load -> done

exec_build_header:
        MOV     DX,[SS:exec_load_block]
;
; assign the space to the process
;

        MOV     SI,arena.arena_owner    ; pointer to owner field

        MOV     AX,[SS:exec_environ]    ; get environ pointer
        OR      AX,AX
        JZ      NO_OWNER                ; no environment
        DEC     AX                      ; point to header
        MOV     DS,AX
        MOV     [SI],DX                 ; assign ownership
NO_OWNER:
        MOV     AX,[SS:exec_load_block] ; get load block pointer
        DEC     AX
        MOV     DS,AX                   ; point to header
        MOV     [SI],DX                 ; assign ownership

        PUSH    DX
        MOV     BYTE [SS:CreatePDB],0FFH    ; indicate a new process
        invoke  _Dup_PDB                    ; ES is now PDB
        POP     DX
        PUSH    WORD [SS:exec_environ]
        POP     WORD [ES:Process_data_block.PDB_environ]
        MOV     SI,[SS:exec_size]
        ADD     SI,DX
        MOV     [ES:Process_data_block.PDB_block_len],SI
;
; set up proper command line stuff
;
        LDS     SI,DWORD [SS:exec_blk]  ; get the block
        PUSH    DS                      ; save its location
        PUSH    SI
        LDS     SI,DWORD [SI+Exec0.Exec0_5C_FCB] ; get the 5c fcb
        MOV     CX,12                   ; copy drive, name and ext
        PUSH    CX
        MOV     DI,5Ch
        MOV     BL,[SI]
        REP     MOVSB
        XOR     AX,AX                   ; zero extent, etc for CPM
        STOSW
        STOSW
        POP     CX
        POP     SI                      ; get block
        POP     DS
        PUSH    DS                      ; save (again)
        PUSH    SI
        LDS     SI,DWORD [SI+Exec0.Exec0_6C_FCB] ; get 6C FCB
        MOV     DI,6Ch                  ; do same as above
        MOV     BH,[SI]
        REP     MOVSB
        STOSW
        STOSW
        POP     SI                      ; get block (last time)
        POP     DS
        LDS     SI,DWORD [SI+Exec0.Exec0_com_line]  ; command line
        MOV     CX,80h
        MOV     DI,CX
        REP     MOVSB                   ; Wham!

;
; Process BX into default AX (validity of drive specs on args)
;
        DEC     CL                      ; get 0FFh in CX
        CMP     BH,[SS:NUMIO]
        JBE     exec_BH_good
        MOV     BH,CL
        JMP     SHORT exec_BL
exec_BH_good:
        XOR     BH,BH
exec_BL:
        CMP     BL,[SS:NUMIO]
        JBE     exec_BL_good
        MOV     BL,CL
        JMP     SHORT exec_set_return
exec_BL_good:
        XOR     BL,BL
exec_set_return:
        invoke  get_user_stack          ; get his return address
        PUSH    WORD [SI+user_environ.user_CS]  ; suck out the CS and IP
        PUSH    WORD [SI+user_environ.user_IP]
        PUSH    WORD [SI+user_environ.user_CS]  ; suck out the CS and IP
        PUSH    WORD [SI+user_environ.user_IP]
        POP     WORD [ES:Process_data_block.PDB_Exit]
        POP     WORD [ES:Process_data_block.PDB_Exit+2]
        XOR     AX,AX
        MOV     DS,AX
        POP     WORD [DS:addr_int_terminate]    ; save them where we can get them later
        POP     WORD [DS:addr_int_terminate+2]  ; when the child exits.
        MOV     WORD [SS:DMAADD],80h
        MOV     DS,[SS:CurrentPDB]
        MOV     WORD [SS:DMAADD+2],DS
        TEST    BYTE [SS:exec_func],exec_func_no_execute
        JZ      exec_go

        LDS     SI,DWORD [SS:exec_init_SP]  ; get stack
        LES     DI,DWORD [SS:exec_blk]      ; and block for return
        MOV     [ES:DI+Exec1.Exec1_SS],DS   ; return SS

        DEC     SI                      ; 'push' default AX
        DEC     SI
        MOV     [SI],BX                 ; save default AX reg
        MOV     [ES:DI+Exec1.Exec1_SP],SI   ; return 'SP'

        LDS     AX,DWORD [SS:exec_init_IP]
        MOV     [ES:DI+Exec1.Exec1_CS],DS   ; initial entry stuff

        MOV     [ES:DI+Exec1.Exec1_IP],AX
        transfer    SYS_RET_OK

exec_go:
        LDS     SI,DWORD [SS:exec_init_IP]  ; get entry point
        CLI
        MOV     BYTE [SS:INDOS],0
        MOV     SS,[CS:exec_init_SS]    ; set up user's stack
        MOV     SP,[CS:exec_init_SP]    ; and SP
        STI
        PUSH    DS                      ; fake long call to entry
        PUSH    SI
        MOV     ES,DX                   ; set up proper seg registers
        MOV     DS,DX
        MOV     AX,BX                   ; set up proper AX
        procedure   exec_long_ret,FAR
        RETF

        procedure   exec_dealloc,near
        ASSUME      DS:NOTHING,ES:NOTHING
        PUSH        BX
        MOV         BX,arena_owner_system
        CALL        exec_do_change_owner
        POP         BX
        return

        procedure   exec_alloc,near
        PUSH        BX
        MOV         BX,[SS:CurrentPDB]
        CALL        exec_do_change_owner
        POP         BX
        return

        procedure   exec_do_change_owner,NEAR
        PUSH    DS
        PUSH    AX
        MOV     AX,[SS:exec_environ]
        OR      AX,AX
        JZ      exec_alloc_try_load
        DEC     AX
        MOV     DS,AX
        MOV     [DS:arena.arena_owner],BX
exec_alloc_try_load:
        MOV     AX,[SS:exec_load_block]
        OR      AX,AX
        JZ      exec_alloc_done
        DEC     AX
        MOV     DS,AX
        MOV     [DS:arena.arena_owner],BX
exec_alloc_done:
        POP     AX
        POP     DS
        RET
