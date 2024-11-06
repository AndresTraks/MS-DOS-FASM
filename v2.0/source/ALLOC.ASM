;
; xenix memory calls for MSDOS
;
; CAUTION: The following routines rely on the fact that arena_signature and
; arena_owner_system are all equal to zero and are contained in DI.
;

;TITLE ALLOC.ASM - memory arena manager
        ASSUME  SS:DOSGROUP,CS:DOSGROUP

;SUBTTL memory allocation utility routines

PAGE
;
; arena_free_process
; input:    BX - PID of process
; output:   free all blocks allocated to that PID
;
        procedure   arena_free_process,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        MOV     DI,arena.arena_signature
        MOV     AX,[SS:arena_head]
        CALL    check_signature         ; ES <- AX, check for valid block

arena_free_process_loop:
        jnc arena_free_process_loop_noret
arena_free_process_loop_ret:
        ret
arena_free_process_loop_noret:
        PUSH    ES
        POP     DS
        CMP     [DS:arena.arena_owner],BX     ; is block owned by pid?
        JNZ     arena_free_next         ; no, skip to next
        MOV     [DS:arena.arena_owner],DI     ; yes... free him

arena_free_next:
        CMP     BYTE [DS:DI],arena_signature_end
                                        ; end of road, Jack?
        jz arena_free_process_loop_ret  ; never come back no more
        CALL    arena_next              ; next item in ES/AX carry set if trash
        JMP     arena_free_process_loop

;
; arena_next
; input:    DS - pointer to block head
; output:   AX,ES - pointers to next head
;           carry set if trashed arena
;
        procedure   arena_next,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        MOV     AX,DS                   ; AX <- current block
        ADD     AX,[DS:arena.arena_size]      ; AX <- AX + current block length
        INC     AX                      ; remember that header!
;
;       fall into check_signature and return
;
;       CALL    check_signature         ; ES <- AX, carry set if error
;       RET

;
; check_signature
; input:    AX - address of block header
; output:   ES=AX, carry set if signature is bad
;
        procedure   check_signature,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        MOV     ES,AX                   ; ES <- AX
        CMP     BYTE [ES:DI],arena_signature_normal
                                        ; IF next signature = not_end THEN
        JZ      check_signature_ok      ;   GOTO ok
        CMP     BYTE [ES:DI],arena_signature_end
                                        ; IF next signature = end then
        JZ      check_signature_ok      ;   GOTO ok
        STC                             ; set error
        return

check_signature_ok:
        CLC
check_signature_ret:
        return

;
; Coalesce - combine free blocks ahead with current block
; input:    DS - pointer to head of free block
; output:   updated head of block, AX is next block
;           carry set -> trashed arena
;
        procedure   coalesce,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        CMP     BYTE [DS:DI],arena_signature_end
                                        ; IF current signature = END THEN
        jz check_signature_ret          ;   GOTO ok
        CALL    arena_next              ; ES, AX <- next block, Carry set if error
        jc check_signature_ret          ; IF no error THEN GOTO check

coalesce_check:
        CMP     [ES:arena.arena_owner],DI
        jnz check_signature_ret         ; IF next block isnt free THEN return
        MOV     CX,[ES:arena.arena_size]      ; CX <- next block size
        INC     CX                      ; CX <- CX + 1 (for header size)
        ADD     [DS:arena.arena_size],CX      ; current size <- current size + CX
        MOV     CL,[ES:DI]              ; move up signature
        MOV     [DS:DI],CL
        JMP     coalesce                ; try again

;SUBTTL $Alloc - allocate space in memory
PAGE
;
;   Assembler usage:
;           MOV     BX,size
;           MOV     AH,Alloc
;           INT     21h
;         AX:0 is pointer to allocated memory
;         BX is max size if not enough memory
;
;   Description:
;           Alloc returns  a  pointer  to  a  free  block of
;       memory that has the requested  size  in  paragraphs.
;
;   Error return:
;           AX = error_not_enough_memory
;              = error_arena_trashed
;
        procedure   _ALLOC,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING

        XOR     AX,AX
        MOV     DI,AX

        MOV     [SS:FirstArena],AX         ; init the options
        MOV     [SS:BestArena],AX
        MOV     [SS:LastArena],AX

        PUSH    AX                      ; alloc_max <- 0
        MOV     AX,[SS:arena_head]         ; AX <- beginning of arena
        CALL    check_signature         ; ES <- AX, carry set if error
        JC      alloc_err               ; IF error THEN GOTO err

alloc_scan:
        PUSH    ES
        POP     DS                      ; DS <- ES
        CMP     [DS:arena.arena_owner],DI
        JZ      alloc_free              ; IF current block is free THEN examine

alloc_next:
        CMP     BYTE [DS:DI],arena_signature_end
                                        ; IF current block is last THEN
        JZ      alloc_end               ;   GOTO end
        CALL    arena_next              ; AX, ES <- next block, Carry set if error
        JNC     alloc_scan              ; IF no error THEN GOTO scan

alloc_err:
        POP     AX

alloc_trashed:
        error   error_arena_trashed

alloc_end:
        CMP     [SS:FirstArena],0
        JNZ     alloc_do_split

alloc_fail:
        invoke  get_user_stack
        POP     BX
        MOV     [SI+user_environ.user_BX],BX
        error   error_not_enough_memory

alloc_free:
        CALL    coalesce                ; add following free block to current
        JC      alloc_err               ; IF error THEN GOTO err
        MOV     CX,[DS:arena.arena_size]

        POP     DX                      ; check for max found size
        CMP     CX,DX
        JNA     alloc_test
        MOV     DX,CX

alloc_test:
        PUSH    DX
        CMP     BX,CX                   ; IF BX > size of current block THEN
        JA      alloc_next              ;   GOTO next

        CMP     [SS:FirstArena],0
        JNZ     alloc_best
        MOV     [SS:FirstArena],DS         ; save first one found
alloc_best:
        CMP     [SS:BestArena],0
        JZ      alloc_make_best         ; initial best
        PUSH    ES
        MOV     ES,[SS:BestArena]
        CMP     [ES:arena.arena_size],CX      ; is size of best larger than found?
        POP     ES
        JBE     alloc_last
alloc_make_best:
        MOV     [SS:BestArena],DS          ; assign best
alloc_last:
        MOV     [SS:LastArena],DS          ; assign last
        JMP     alloc_next

;
; split the block high
;
alloc_do_split_high:
        MOV     DS,[SS:LastArena]
        MOV     CX,[DS:arena.arena_size]
        SUB     CX,BX
        MOV     DX,DS
        JE      alloc_set_owner         ; sizes are equal, no split
        ADD     DX,CX                   ; point to next block
        MOV     ES,DX                   ; no decrement!
        DEC     CX
        XCHG    BX,CX                   ; bx has size of lower block
        JMP     alloc_set_sizes         ; cx has upper (requested) size

;
; we have scanned memory and have found all appropriate blocks
; check for the type of allocation desired; first and best are identical
; last must be split high
;
alloc_do_split:
        CMP     BYTE [SS:AllocMethod], 1
        JA      alloc_do_split_high
        MOV     DS,[SS:FirstArena]
        JB      alloc_get_size
        MOV     DS,[SS:BestArena]
alloc_get_size:
        MOV     CX,[DS:arena.arena_size]
        SUB     CX,BX                   ; get room left over
        MOV     AX,DS
        MOV     DX,AX                   ; save for owner setting
        JE      alloc_set_owner         ; IF BX = size THEN (don't split)
        ADD     AX,BX
        INC     AX                      ; remember the header
        MOV     ES,AX                   ; ES <- DS + BX (new header location)
        DEC     CX                      ; CX <- size of split block
alloc_set_sizes:
        MOV     [DS:arena.arena_size],BX      ; current size <- BX
        MOV     [ES:arena.arena_size],CX      ; split size <- CX
        MOV     BL,arena_signature_normal
        XCHG    BL,[DS:DI]              ; current signature <- 4D
        MOV     [ES:DI],BL              ; new block sig <- old block sig
        MOV     [ES:arena.arena_owner],DI

alloc_set_owner:
        MOV     DS,DX
        MOV     AX,[SS:CurrentPDB]
        MOV     [DS:arena.arena_owner],AX
        MOV     AX,DS
        INC     AX
        POP     BX
        transfer    SYS_RET_OK

;SUBTTL $SETBLOCK - change size of an allocated block (if possible)
PAGE
;
;   Assembler usage:
;           MOV     ES,block
;           MOV     BX,newsize
;           MOV     AH,setblock
;           INT     21h
;         if setblock fails for growing, BX will have the maximum
;         size possible
;   Error return:
;           AX = error_invalid_block
;              = error_arena_trashed
;              = error_not_enough_memory
;              = error_invalid_function
;
        procedure   _SETBLOCK,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        MOV     DI,arena.arena_signature
        MOV     AX,ES
        DEC     AX
        CALL    check_signature
        JNC     setblock_grab

setblock_bad:
        JMP     alloc_trashed

setblock_grab:
        MOV     DS,AX
        CALL    coalesce
        JC      setblock_bad
        MOV     CX,[DS:arena.arena_size]
        PUSH    CX
        CMP     BX,CX
        JBE     alloc_get_size
        JMP     alloc_fail

;SUBTTL $DEALLOC - free previously allocated piece of memory
PAGE
;
;   Assembler usage:
;           MOV     ES,block
;           MOV     AH,dealloc
;           INT     21h
;
;   Error return:
;           AX = error_invalid_block
;              = error_arena_trashed
;
        procedure   _DEALLOC,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        MOV     DI,arena.arena_signature
        MOV     AX,ES
        DEC     AX
        CALL    check_signature
        JC      dealloc_err
        MOV     [ES:arena.arena_owner],DI
        transfer    SYS_RET_OK

dealloc_err:
        error   error_invalid_block

;SUBTTL $AllocOper - get/set allocation mechanism
PAGE
;
;   Assembler usage:
;           MOV     AH,AllocOper
;           MOV     BX,method
;           MOV     AL,func
;           INT     21h
;
;   Error return:
;           AX = error_invalid_function
;
        procedure   _AllocOper,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        CMP     AL,1
        JB      AllocOperGet
        JZ      AllocOperSet
        error   error_invalid_function
AllocOperGet:
        MOV     AL,BYTE [SS:AllocMethod]
        XOR     AH,AH
        transfer    SYS_RET_OK
AllocOperSet:
        MOV     [SS:AllocMethod],BL
        transfer    SYS_RET_OK

do_ext
