label VGA_TABLE byte                ;AN000;
    MODE_TABLE$16 MODE_TABLE  1, 1,, 16,  -1,  -1, 40, -1 ; mode	1 Ä¿ To give preference;AN000;
    MODE_TABLE$17 MODE_TABLE  0, 1,, 16,  -1,  -1, 40, -1 ; mode	0  ³ of COxx over      ;AN000;
    MODE_TABLE$18 MODE_TABLE  3, 1,, 16,  -1,  -1, 80, -1 ; mode	3  ³ BWxx.	       ;AN000;
    MODE_TABLE$19 MODE_TABLE  2, 1,, 16,  -1,  -1, 80, -1 ; mode	2 ÄÙ	(see text)     ;AN000;
    MODE_TABLE$20 MODE_TABLE  7, 1,,  0,  -1,  -1, 80, -1 ; mode	7		       ;AN000;
    MODE_TABLE$21 MODE_TABLE 13, 2,, 16, 320, 200, 40, 25 ; mode 13		       ;AN000;
    MODE_TABLE$22 MODE_TABLE 14, 2,, 16, 640, 200, 80, 25 ; mode 14		       ;AN000;
    MODE_TABLE$23 MODE_TABLE 15, 2,,  0, 640, 350, 80, 25 ; mode 15		       ;AN000;
    MODE_TABLE$24 MODE_TABLE 16, 2,, 16, 640, 350, 80, 25 ; mode 16		       ;AN000;
    MODE_TABLE$25 MODE_TABLE 17, 2,,  2, 640, 480, 80, 30 ; mode 17		       ;AN000;
    MODE_TABLE$26 MODE_TABLE 18, 2,, 16, 640, 480, 80, 30 ; mode 18		       ;AN000;
    MODE_TABLE$27 MODE_TABLE 19, 2,,256, 320, 200, 40, 25 ; mode 19		       ;AN000;
; = and not equ: fasm's equ is text put in where the name is used, so a $
; in it would be the address of the use and not of this line.
VGA_NUM 	 =  (($ - VGA_TABLE)/(sizeof.MODE_TABLE)) ;AN000;

label MCGA_TABLE byte                ;AN000;
    MODE_TABLE$28 MODE_TABLE 17, 2,,  2, 640, 480, 80, 30 ; mode 17		       ;AN000;
    MODE_TABLE$29 MODE_TABLE 19, 2,,256, 320, 200, 40, 25 ; mode 19		       ;AN000;
MCGA_NUM	 =  (($ - MCGA_TABLE)/(sizeof.MODE_TABLE)) ;AN000;

label EGA_5154_TABLE byte                ;AN000;
    MODE_TABLE$30 MODE_TABLE  1, 1,, 16,  -1,  -1, 40, 43 ; mode	1 Ä¿ To give preference;AN000;
    MODE_TABLE$31 MODE_TABLE  0, 1,, 16,  -1,  -1, 40, 43 ; mode	0  ³ of COxx over      ;AN000;
    MODE_TABLE$32 MODE_TABLE  3, 1,, 16,  -1,  -1, 80, 43 ; mode	3  ³ BWxx.	       ;AN000;
    MODE_TABLE$33 MODE_TABLE  2, 1,, 16,  -1,  -1, 80, 43 ; mode	2 ÄÙ	(see text)     ;AN000;
    MODE_TABLE$34 MODE_TABLE 13, 2,, 16, 320, 200, 40, 25 ; mode 13		       ;AN000;
    MODE_TABLE$35 MODE_TABLE 14, 2,, 16, 640, 200, 80, 25 ; mode 14		       ;AN000;
    MODE_TABLE$36 MODE_TABLE 16, 2,, 16, 640, 350, 80, 25 ; mode 16		       ;AN000;
EGA_5154_NUM	 =  (($ - EGA_5154_TABLE)/(sizeof.MODE_TABLE)) ;AN000;

label EGA_5153_TABLE byte                ;AN000;
    MODE_TABLE$37 MODE_TABLE 13, 2,, 16, 320, 200, 40, 25 ; mode 13		       ;AN000;
    MODE_TABLE$38 MODE_TABLE 14, 2,, 16, 640, 200, 80, 25 ; mode 14		       ;AN000;
EGA_5153_NUM	 =  (($ - EGA_5153_TABLE)/(sizeof.MODE_TABLE)) ;AN000;

label EGA_5151_TABLE byte                ;AN000;
    MODE_TABLE$39 MODE_TABLE  7, 1,,  0,  -1,  -1, 80, 43 ; mode	7		       ;AN000;
    MODE_TABLE$40 MODE_TABLE 15, 2,,  0, 640, 350, 80, 25 ; mode 15		       ;AN000;
EGA_5151_NUM	 =  (($ - EGA_5151_TABLE)/(sizeof.MODE_TABLE)) ;AN000;

label MONO_TABLE byte                ;AN000;
    MODE_TABLE$41 MODE_TABLE  7, 1,,  0,  -1,  -1, 80, 25 ; mode	7		       ;AN000;
MONO_NUM	 =  (($ - MONO_TABLE)/(sizeof.MODE_TABLE)) ;AN000;

label COLOR_TABLE byte                ;AN000;
    MODE_TABLE$42 MODE_TABLE  1, 1,, 16,  -1,  -1, 40, 25 ; mode	1 Ä¿ To give preference;AN000;
    MODE_TABLE$43 MODE_TABLE  0, 1,, 16,  -1,  -1, 40, 25 ; mode	0  ³ of COxx over      ;AN000;
    MODE_TABLE$44 MODE_TABLE  3, 1,, 16,  -1,  -1, 80, 25 ; mode	3  ³ BWxx.	       ;AN000;
    MODE_TABLE$45 MODE_TABLE  2, 1,, 16,  -1,  -1, 80, 25 ; mode	2 ÄÙ	(see text)     ;AN000;
    MODE_TABLE$46 MODE_TABLE  4, 2,,  4, 320, 200, 40, 25 ; mode	4		       ;AN000;
    MODE_TABLE$47 MODE_TABLE  5, 2,,  2, 320, 200, 40, 25 ; mode	5		       ;AN000;
    MODE_TABLE$48 MODE_TABLE  6, 2,,  2, 640, 200, 80, 25 ; mode	6		       ;AN000;
COLOR_NUM	 =  (($ - COLOR_TABLE)/(sizeof.MODE_TABLE)) ;AN000;
