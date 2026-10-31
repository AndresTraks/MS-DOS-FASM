;	SCCSID = @(#)comseg.asm 1.1 85/05/14
;	SCCSID = @(#)comseg.asm 1.1 85/05/14
; The following are all of the segments used in the load order

if SEGSEL = S_CODERES	;AC000; resident code
end if

if SEGSEL = S_DATARES	;AC000; resident data
end if

if SEGSEL = S_BATARENA	;AC000; space for DOS ALLOCATE header
end if

if SEGSEL = S_BATSEG	;AC000; AUTOEXEC batch segment
end if

if SEGSEL = S_ENVARENA	;AC000; space for DOS ALLOCATE header
end if

if SEGSEL = S_ENVIRONMENT	;AC000; Default COMMAND environment
end if

if SEGSEL = S_INIT	;AC000; Initialization code
end if

if SEGSEL = S_TAIL	;AC000; End of Init - start of Transient
end if

if SEGSEL = S_TRANCODE	;AC000; Transient code
end if

if SEGSEL = S_TRANDATA	;AC000; Transient data area
end if

if SEGSEL = S_TRANSPACE	;AC000; Transient modifiable data area
end if

if SEGSEL = S_TRANTAIL	;AC000; End of Transient
end if

;RESGROUP  GROUP CODERES,DATARES,BATARENA,BATSEG,ENVARENA,ENVIRONMENT,INIT,TAIL
;TRANGROUP GROUP TRANCODE,TRANDATA,TRANSPACE,TRANTAIL
