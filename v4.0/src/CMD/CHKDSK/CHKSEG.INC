if SEGSEL = S_PSP;an000;bgb
end if ;an000;bgb
										;an000;bgb
if SEGSEL = S_DATA;an000;bgb
end if ;an000;bgb
										;an000;bgb
if SEGSEL = S_CONST;an000;bgb
end if ;an000;bgb
										;an000;bgb
if SEGSEL = S_CODE;an000;bgb
end if ;an000;bgb
										;an000;bgb
if SEGSEL = S_CSTACK;an000;bgb
end if ;an000;bgb
										;an000;bgb
if SEGSEL = S_LASTSEG;an000;bgb;AN000;bgb
end if ;this is a pointer to the end of the pgm     ;A;an000;bgbN000;bgb
										;an000;bgb;AN000;bgb
;DG_	GROUP	data,const,code,CSTACK,lastseg					;an000;bgb
;assume	cs:DG_,ds:DG_,ss:DG_,es:DG_ 						;an000;bgb
