      title   FIND Messages

macro Message	sym,text {
;public	sym,sym#_len
sym	db  text
sym#_len db  $-sym
}

CR	equ	0dh			;A Carriage Return
LF	equ	0ah			;A Line Feed

if SEGSEL = S_CODE

;	PUBLIC	heading
	Message heading,<CR,LF,"---------- ">

end if
;	end
