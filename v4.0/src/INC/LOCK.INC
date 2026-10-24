;
;Equates for LOCK
;
;LOCK functions
;
Lock_all	    equ    0
Unlock_all	    equ    1
Lock_mul_range	    equ    2
Unlock_mul_range    equ    3
Lock_read	    equ    4
Write_unlock	    equ    5
Lock_add	    equ    6

;
;Structure for Lock buffer

STRUC LockBuf
{

   Lock_position DD    0	    ; file position for LOCK
   Lock_length	 DD    0	    ; number of bytes to LOCK

}
match =LockBuf_LAID_OUT, LockBuf_LAID_OUT
{
    LockBuf_LAID_OUT equ 1
    virtual at 0
      LockBuf LockBuf
      sizeof.LockBuf = $ - LockBuf
    end virtual
}
;
