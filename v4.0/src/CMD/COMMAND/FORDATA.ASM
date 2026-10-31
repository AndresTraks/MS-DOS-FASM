;	SCCSID = @(#)fordata.asm	1.1 85/05/14
;	SCCSID = @(#)fordata.asm	1.1 85/05/14
; Data structure definitions included by tfor.asm

STRUC for_info
{
    .for_args        DB          (sizeof.arg_unit) DUP (?)      ; argv[] structure
    .FOR_COM_START   DB          ?                      ; beginning of <command>
    .FOR_EXPAND      DW          ?                      ; * or ? item in <list>?
    .FOR_MINARG      DW          ?                      ; beginning of <list>
    .FOR_MAXARG      DW          ?                      ; end of <list>
    .forbuf          DW          64 DUP (?)             ; temporary buffer
    .fordma          DW          64 DUP (?)             ; FindFirst/Next buffer
    .FOR_VAR         DB          ?                      ; loop control variable
}
; The FOR command is laid down once, so the offsets are taken here, with no
; MATCH asking whether a reading has already taken them: the question is
; answered on the first reading of the source, which is laying down another
; segment altogether.
virtual at 0
  for_info for_info
  sizeof.for_info = $ - for_info
end virtual

; empty segment done for bogus addressing
; MASM made f the first byte of a segment of nothing, so that TFOR could write
; f.for_expand and have the field's own offset come out: the block the FOR
; command works in is one it allocates, and ES or DS points at it.  There is
; nothing here to give an offset to, so f is nought.
;for_segment     segment
f = 0
;for_segment     ends
