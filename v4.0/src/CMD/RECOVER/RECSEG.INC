; define the segment ordering						       ;AN000;bgb
									       ;AN000;bgb
if SEGSEL = S_DATA;AN000;bgb
end if ;put this 1st so that the recmsg works			       ;AN000;bgb
									       ;AN000;bgb
if SEGSEL = S_CODE;AN000;bgb
end if ;AN000;bgb
									       ;AN000;bgb
if SEGSEL = S_CONST;AN000;bgb
end if ;AN000;bgb
									       ;AN000;bgb
if SEGSEL = S_CSTACK;AN000;bgb
	rb      (362 - 80h) + 256    ; (362 - 80h) == IBM's ROM requirements ;AN000;bgb
end if ; (New - Old) == size of growth 				;AN005;bgb
										;AN005;bgb
if SEGSEL = S_LASTSEG;AN005;bgb
end if ;put last because 'table' writes over memory   ;AN005;bgb
										;AN000;bgb
;DG_	group	data,const,code,cstack,lastseg					;AN000;bgb
;	assume	cs:DG_,ds:DG_,es:DG_,ss:CSTACK					;AN000;bgb
