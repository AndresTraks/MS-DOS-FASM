INCLUDE 'debequ.asm'

if SEGSEL = S_CODE
end if

if SEGSEL = S_CONST
end if

if SEGSEL = S_DATA
end if


if SEGSEL = S_CODE




end if

if SEGSEL = S_CONST




        IF  SYSVER
        end if


REG8    DB      "ALCLDLBLAHCHDHBH"
REG16   DB      "AXCXDXBXSPBPSIDI"
SREG    DB      "ESCSSSDS",0,0
SIZ8    DB      "BYWODWQWTB",0,0
; 0
DISTAB  DW      ADDMN,ALUFROMREG
        DW      ADDMN,ALUFROMREG
        DW      ADDMN,ALUTOREG
        DW      ADDMN,ALUTOREG
        DW      ADDMN,ACCIMM
        DW      ADDMN,ACCIMM
        DW      PUSHMN,SEGOP
        DW      POPMN,SEGOP
        DW      ORMN,ALUFROMREG
        DW      ORMN,ALUFROMREG
        DW      ORMN,ALUTOREG
        DW      ORMN,ALUTOREG
        DW      ORMN,ACCIMM
        DW      ORMN,ACCIMM
        DW      PUSHMN,SEGOP
        DW      POPMN,SEGOP
; 10H
        DW      ADCMN,ALUFROMREG
        DW      ADCMN,ALUFROMREG
        DW      ADCMN,ALUTOREG
        DW      ADCMN,ALUTOREG
        DW      ADCMN,ACCIMM
        DW      ADCMN,ACCIMM
        DW      PUSHMN,SEGOP
        DW      POPMN,SEGOP
        DW      SBBMN,ALUFROMREG
        DW      SBBMN,ALUFROMREG
        DW      SBBMN,ALUTOREG
        DW      SBBMN,ALUTOREG
        DW      SBBMN,ACCIMM
        DW      SBBMN,ACCIMM
        DW      PUSHMN,SEGOP
        DW      POPMN,SEGOP
; 20H
        DW      ANDMN,ALUFROMREG
        DW      ANDMN,ALUFROMREG
        DW      ANDMN,ALUTOREG
        DW      ANDMN,ALUTOREG
        DW      ANDMN,ACCIMM
        DW      ANDMN,ACCIMM
        DW      ESSEGMN,ESPRE
        DW      DAAMN,NOOPERANDS
        DW      SUBMN,ALUFROMREG
        DW      SUBMN,ALUFROMREG
        DW      SUBMN,ALUTOREG
        DW      SUBMN,ALUTOREG
        DW      SUBMN,ACCIMM
        DW      SUBMN,ACCIMM
        DW      CSSEGMN,CSPRE
        DW      DASMN,NOOPERANDS
; 30H
        DW      XORMN,ALUFROMREG
        DW      XORMN,ALUFROMREG
        DW      XORMN,ALUTOREG
        DW      XORMN,ALUTOREG
        DW      XORMN,ACCIMM
        DW      XORMN,ACCIMM
        DW      SSSEGMN,SSPRE
        DW      AAAMN,NOOPERANDS
        DW      CMPMN,ALUFROMREG
        DW      CMPMN,ALUFROMREG
        DW      CMPMN,ALUTOREG
        DW      CMPMN,ALUTOREG
        DW      CMPMN,ACCIMM
        DW      CMPMN,ACCIMM
        DW      DSSEGMN,DSPRE
        DW      AASMN,NOOPERANDS
; 40H
        DW      INCMN,REGOP
        DW      INCMN,REGOP
        DW      INCMN,REGOP
        DW      INCMN,REGOP
        DW      INCMN,REGOP
        DW      INCMN,REGOP
        DW      INCMN,REGOP
        DW      INCMN,REGOP
        DW      DECMN,REGOP
        DW      DECMN,REGOP
        DW      DECMN,REGOP
        DW      DECMN,REGOP
        DW      DECMN,REGOP
        DW      DECMN,REGOP
        DW      DECMN,REGOP
        DW      DECMN,REGOP
; 50H
        DW      PUSHMN,REGOP
        DW      PUSHMN,REGOP
        DW      PUSHMN,REGOP
        DW      PUSHMN,REGOP
        DW      PUSHMN,REGOP
        DW      PUSHMN,REGOP
        DW      PUSHMN,REGOP
        DW      PUSHMN,REGOP
        DW      POPMN,REGOP
        DW      POPMN,REGOP
        DW      POPMN,REGOP
        DW      POPMN,REGOP
        DW      POPMN,REGOP
        DW      POPMN,REGOP
        DW      POPMN,REGOP
        DW      POPMN,REGOP
; 60H
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
; 70H
        DW      JOMN,SHORTJMP
        DW      JNOMN,SHORTJMP
        DW      JCMN,SHORTJMP
        DW      JNCMN,SHORTJMP
        DW      JZMN,SHORTJMP
        DW      JNZMN,SHORTJMP
        DW      JBEMN,SHORTJMP
        DW      JAMN,SHORTJMP
        DW      JSMN,SHORTJMP
        DW      JNSMN,SHORTJMP
        DW      JPEMN,SHORTJMP
        DW      JPOMN,SHORTJMP
        DW      JLMN,SHORTJMP
        DW      JGEMN,SHORTJMP
        DW      JLEMN,SHORTJMP
        DW      JGMN,SHORTJMP
; 80H
        DW      0,IMMED
        DW      0,IMMED
        DW      0,IMMED
        DW      0,SIGNIMM
        DW      TESTMN,ALUFROMREG
        DW      TESTMN,ALUFROMREG
        DW      XCHGMN,ALUFROMREG
        DW      XCHGMN,ALUFROMREG
        DW      MOVMN,ALUFROMREG
        DW      MOVMN,ALUFROMREG
        DW      MOVMN,ALUTOREG
        DW      MOVMN,ALUTOREG
        DW      MOVMN,MOVSEGTO
        DW      LEAMN,WORDTOALU
        DW      MOVMN,MOVSEGFROM
        DW      POPMN,GETADDR
; 90H
        DW      NOPMN,NOOPERANDS
        DW      XCHGMN,XCHGAX
        DW      XCHGMN,XCHGAX
        DW      XCHGMN,XCHGAX
        DW      XCHGMN,XCHGAX
        DW      XCHGMN,XCHGAX
        DW      XCHGMN,XCHGAX
        DW      XCHGMN,XCHGAX
        DW      CBWMN,NOOPERANDS
        DW      CWDMN,NOOPERANDS
        DW      CALLMN,LONGJMP
        DW      WAITMN,NOOPERANDS
        DW      PUSHFMN,NOOPERANDS
        DW      POPFMN,NOOPERANDS
        DW      SAHFMN,NOOPERANDS
        DW      LAHFMN,NOOPERANDS
; A0H
        DW      MOVMN,LOADACC
        DW      MOVMN,LOADACC
        DW      MOVMN,STOREACC
        DW      MOVMN,STOREACC
        DW      MOVBMN,NOOPERANDS
        DW      MOVWMN,NOOPERANDS
        DW      CMPBMN,NOOPERANDS
        DW      CMPWMN,NOOPERANDS
        DW      TESTMN,ACCIMM
        DW      TESTMN,ACCIMM
        DW      STOBMN,NOOPERANDS
        DW      STOWMN,NOOPERANDS
        DW      LODBMN,NOOPERANDS
        DW      LODWMN,NOOPERANDS
        DW      SCABMN,NOOPERANDS
        DW      SCAWMN,NOOPERANDS
; B0H
        DW      MOVMN,REGIMMB
        DW      MOVMN,REGIMMB
        DW      MOVMN,REGIMMB
        DW      MOVMN,REGIMMB
        DW      MOVMN,REGIMMB
        DW      MOVMN,REGIMMB
        DW      MOVMN,REGIMMB
        DW      MOVMN,REGIMMB
        DW      MOVMN,REGIMMW
        DW      MOVMN,REGIMMW
        DW      MOVMN,REGIMMW
        DW      MOVMN,REGIMMW
        DW      MOVMN,REGIMMW
        DW      MOVMN,REGIMMW
        DW      MOVMN,REGIMMW
        DW      MOVMN,REGIMMW
; C0H
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      RETMN,SAV16
        DW      RETMN,NOOPERANDS
        DW      LESMN,WORDTOALU
        DW      LDSMN,WORDTOALU
        DW      MOVMN,MEMIMM
        DW      MOVMN,MEMIMM
        DW      DBMN,SAVHEX
        DW      DBMN,SAVHEX
        DW      RETFMN,SAV16
        DW      RETFMN,NOOPERANDS
        DW      INTMN,INT3_
        DW      INTMN,SAV8
        DW      INTOMN,NOOPERANDS
        DW      IRETMN,NOOPERANDS
; D0H
        DW      0,SHIFT
        DW      0,SHIFT
        DW      0,SHIFTV
        DW      0,SHIFTV
        DW      AAMMN,CHK10
        DW      AADMN,CHK10
        DW      DBMN,SAVHEX
        DW      XLATMN,NOOPERANDS
        DW      0,M8087                 ; d8
        DW      0,M8087_D9              ; d9
        DW      0,M8087                 ; da
        DW      0,M8087_DB              ; db
        DW      0,M8087                 ; dc
        DW      0,M8087_DD              ; dd
        DW      0,M8087                 ; de
        DW      0,M8087_DF              ; df
; E0H
        DW      LOOPNZMN,SHORTJMP
        DW      LOOPZMN,SHORTJMP
        DW      LOOPMN,SHORTJMP
        DW      JCXZMN,SHORTJMP
        DW      INMN,INFIXB
        DW      INMN,INFIXW
        DW      OUTMN,OUTFIXB
        DW      OUTMN,OUTFIXW
        DW      CALLMN,JMPCALL
        DW      JMPMN,JMPCALL
        DW      JMPMN,LONGJMP
        DW      JMPMN,SHORTJMP
        DW      INMN,INVARB
        DW      INMN,INVARW
        DW      OUTMN,OUTVARB
        DW      OUTMN,OUTVARW
; F0H
        DW      LOCKMN,PREFIX
        DW      DBMN,SAVHEX
        DW      REPNZMN,PREFIX
        DW      REPZMN,PREFIX
        DW      HLTMN,NOOPERANDS
        DW      CMCMN,NOOPERANDS
        DW      0,GRP1
        DW      0,GRP1
        DW      CLCMN,NOOPERANDS
        DW      STCMN,NOOPERANDS
        DW      DIMN,NOOPERANDS
        DW      EIMN,NOOPERANDS
        DW      UPMN,NOOPERANDS
        DW      DOWNMN,NOOPERANDS
        DW      0,GRP2
        DW      0,GRP2

DBMN    DB      "D","B"+80H
        DB      "D","W"+80H
        DB      ";"+80H
ADDMN   DB      "AD","D"+80H
ADCMN   DB      "AD","C"+80H
SUBMN   DB      "SU","B"+80H
SBBMN   DB      "SB","B"+80H
XORMN   DB      "XO","R"+80H
ORMN    DB      "O","R"+80H
ANDMN   DB      "AN","D"+80H
AAAMN   DB      "AA","A"+80H
AADMN   DB      "AA","D"+80H
AAMMN   DB      "AA","M"+80H
AASMN   DB      "AA","S"+80H
CALLMN  DB      "CAL","L"+80H
CBWMN   DB      "CB","W"+80H
CLCMN   DB      "CL","C"+80H
UPMN    DB      "CL","D"+80H            ; CLD+80H
DIMN    DB      "CL","I"+80H
CMCMN   DB      "CM","C"+80H
CMPBMN  DB      "CMPS","B"+80H          ; CMPSB
CMPWMN  DB      "CMPS","W"+80H          ; CMPSW+80H
CMPMN   DB      "CM","P"+80H
CWDMN   DB      "CW","D"+80H
DAAMN   DB      "DA","A"+80H
DASMN   DB      "DA","S"+80H
DECMN   DB      "DE","C"+80H
DIVMN   DB      "DI","V"+80H
ESCMN   DB      "ES","C"+80H
        DB      "FXC","H"+80H
        DB      "FFRE","E"+80H
        DB      "FCOMP","P"+80H
        DB      "FCOM","P"+80H
        DB      "FCO","M"+80H
        DB      "FICOM","P"+80H
        DB      "FICO","M"+80H
        DB      "FNO","P"+80H
        DB      "FCH","S"+80H
        DB      "FAB","S"+80H
        DB      "FTS","T"+80H
        DB      "FXA","M"+80H
        DB      "FLDL2","T"+80H
        DB      "FLDL2","E"+80H
        DB      "FLDLG","2"+80H
        DB      "FLDLN","2"+80H
        DB      "FLDP","I"+80H
        DB      "FLD","1"+80H
        DB      "FLD","Z"+80H
        DB      "F2XM","1"+80H
        DB      "FYL2XP","1"+80H
        DB      "FYL2","X"+80H
        DB      "FPTA","N"+80H
        DB      "FPATA","N"+80H
        DB      "FXTRAC","T"+80H
        DB      "FDECST","P"+80H
        DB      "FINCST","P"+80H
        DB      "FPRE","M"+80H
        DB      "FSQR","T"+80H
        DB      "FRNDIN","T"+80H
        DB      "FSCAL","E"+80H
        DB      "FINI","T"+80H
        DB      "FDIS","I"+80H
        DB      "FEN","I"+80H
        DB      "FCLE","X"+80H
        DB      "FBL","D"+80H
        DB      "FBST","P"+80H
        DB      "FLDC","W"+80H
        DB      "FSTC","W"+80H
        DB      "FSTS","W"+80H
        DB      "FSTEN","V"+80H
        DB      "FLDEN","V"+80H
        DB      "FSAV","E"+80H
        DB      "FRSTO","R"+80H
        DB      "FADD","P"+80H
        DB      "FAD","D"+80H
        DB      "FIAD","D"+80H
        DB      "FSUBR","P"+80H
        DB      "FSUB","R"+80H
        DB      "FSUB","P"+80H
        DB      "FSU","B"+80H
        DB      "FISUB","R"+80H
        DB      "FISU","B"+80H
        DB      "FMUL","P"+80H
        DB      "FMU","L"+80H
        DB      "FIMU","L"+80H
        DB      "FDIVR","P"+80H
        DB      "FDIV","R"+80H
        DB      "FDIV","P"+80H
        DB      "FDI","V"+80H
        DB      "FIDIV","R"+80H
        DB      "FIDI","V"+80H
        DB      "FWAI","T"+80H
        DB      "FIL","D"+80H
        DB      "FL","D"+80H
        DB      "FST","P"+80H
        DB      "FS","T"+80H
        DB      "FIST","P"+80H
        DB      "FIS","T"+80H
HLTMN   DB      "HL","T"+80H
IDIVMN  DB      "IDI","V"+80H
IMULMN  DB      "IMU","L"+80H
INCMN   DB      "IN","C"+80H
INTOMN  DB      "INT","O"+80H
INTMN   DB      "IN","T"+80H
INMN    DB      "I","N"+80H             ; IN
IRETMN  DB      "IRE","T"+80H
        DB      "JNB","E"+80H
        DB      "JA","E"+80H
JAMN    DB      "J","A"+80H
JCXZMN  DB      "JCX","Z"+80H
JNCMN   DB      "JN","B"+80H
JBEMN   DB      "JB","E"+80H
JCMN    DB      "J","B"+80H
        DB      "JN","C"+80H
        DB      "J","C"+80H
        DB      "JNA","E"+80H
        DB      "JN","A"+80H
JZMN    DB      "J","Z"+80H
        DB      "J","E"+80H
JGEMN   DB      "JG","E"+80H
JGMN    DB      "J","G"+80H
        DB      "JNL","E"+80H
        DB      "JN","L"+80H
JLEMN   DB      "JL","E"+80H
JLMN    DB      "J","L"+80H
        DB      "JNG","E"+80H
        DB      "JN","G"+80H
JMPMN   DB      "JM","P"+80H
JNZMN   DB      "JN","Z"+80H
        DB      "JN","E"+80H
JPEMN   DB      "JP","E"+80H
JPOMN   DB      "JP","O"+80H
        DB      "JN","P"+80H
JNSMN   DB      "JN","S"+80H
JNOMN   DB      "JN","O"+80H
JOMN    DB      "J","O"+80H
JSMN    DB      "J","S"+80H
        DB      "J","P"+80H
LAHFMN  DB      "LAH","F"+80H
LDSMN   DB      "LD","S"+80H
LEAMN   DB      "LE","A"+80H
LESMN   DB      "LE","S"+80H
LOCKMN  DB      "LOC","K"+80H
LODBMN  DB      "LODS","B"+80H          ; LODSB
LODWMN  DB      "LODS","W"+80H          ; LODSW+80H
LOOPNZMN DB     "LOOPN","Z"+80H
LOOPZMN DB      "LOOP","Z"+80H
        DB      "LOOPN","E"+80H
        DB      "LOOP","E"+80H
LOOPMN  DB      "LOO","P"+80H
MOVBMN  DB      "MOVS","B"+80H          ; MOVSB
MOVWMN  DB      "MOVS","W"+80H          ; MOVSW+80H
MOVMN   DB      "MO","V"+80H
MULMN   DB      "MU","L"+80H
NEGMN   DB      "NE","G"+80H
NOPMN   DB      "NO","P"+80H
NOTMN   DB      "NO","T"+80H
OUTMN   DB      "OU","T"+80H            ; OUT
POPFMN  DB      "POP","F"+80H
POPMN   DB      "PO","P"+80H
PUSHFMN DB      "PUSH","F"+80H
PUSHMN  DB      "PUS","H"+80H
RCLMN   DB      "RC","L"+80H
RCRMN   DB      "RC","R"+80H
REPZMN  DB      "REP","Z"+80H
REPNZMN DB      "REPN","Z"+80H
        DB      "REP","E"+80H
        DB      "REPN","E"+80H
        DB      "RE","P"+80H
RETFMN  DB      "RET","F"+80H
RETMN   DB      "RE","T"+80H
ROLMN   DB      "RO","L"+80H
RORMN   DB      "RO","R"+80H
SAHFMN  DB      "SAH","F"+80H
SARMN   DB      "SA","R"+80H
SCABMN  DB      "SCAS","B"+80H          ; SCASB
SCAWMN  DB      "SCAS","W"+80H          ; SCASW+80H
SHLMN   DB      "SH","L"+80H
SHRMN   DB      "SH","R"+80H
STCMN   DB      "ST","C"+80H
DOWNMN  DB      "ST","D"+80H            ; STD
EIMN    DB      "ST","I"+80H            ; STI
STOBMN  DB      "STOS","B"+80H          ; STOSB
STOWMN  DB      "STOS","W"+80H          ; STOSW+80H
TESTMN  DB      "TES","T"+80H
WAITMN  DB      "WAI","T"+80H
XCHGMN  DB      "XCH","G"+80H
XLATMN  DB      "XLA","T"+80H
ESSEGMN DB      "ES",":"+80H
CSSEGMN DB      "CS",":"+80H
SSSEGMN DB      "SS",":"+80H
DSSEGMN DB      "DS",":"+80H
BADMN   DB      "??","?"+80H

M8087_TAB DB "ADD$MUL$COM$COMP$SUB$SUBR$DIV$DIVR$"
FI_TAB    DB "F$FI$F$FI$"
SIZE_TAB  DB "DWORD PTR $DWORD PTR $QWORD PTR $WORD PTR $"
          DB "BYTE PTR $TBYTE PTR $"

MD9_TAB   DB "LD$@$ST$STP$LDENV$LDCW$STENV$STCW$"
MD9_TAB2  DB "CHS$ABS$@$@$TST$XAM$@$@$LD1$LDL2T$LDL2E$"
          DB "LDPI$LDLG2$LDLN2$LDZ$@$2XM1$YL2X$PTAN$PATAN$XTRACT$"
          DB "@$DECSTP$INCSTP$PREM$YL2XP1$SQRT$@$RNDINT$SCALE$@$@$"

MDB_TAB   DB  "ILD$@$IST$ISTP$@$LD$@$STP$"
MDB_TAB2  DB  "ENI$DISI$CLEX$INIT$"

MDD_TAB   DB "LD$@$ST$STP$RSTOR$@$SAVE$STSW$"
MDD_TAB2  DB "FREE$XCH$ST$STP$"

MDF_TAB   DB "ILD$@$IST$ISTP$BLD$ILD$BSTP$ISTP$"


OPTAB   DB      11111111B               ; DB
        DW      DB_OPER
        DB      11111111B               ; DW
        DW      DW_OPER
        DB      11111111B               ; COMMENT
        DW      ASSEMLOOP
        DB      0 * 8                   ; ADD
        DW      GROUP2
        DB      2 * 8                   ; ADC
        DW      GROUP2
        DB      5 * 8                   ; SUB
        DW      GROUP2
        DB      3 * 8                   ; SBB
        DW      GROUP2
        DB      6 * 8                   ; XOR
        DW      GROUP2
        DB      1 * 8                   ; OR
        DW      GROUP2
        DB      4 * 8                   ; AND
        DW      GROUP2
        DB      00110111B               ; AAA
        DW      NO_OPER
        DB      11010101B               ; AAD
        DW      AA_OPER
        DB      11010100B               ; AAM
        DW      AA_OPER
        DB      00111111B               ; AAS
        DW      NO_OPER
        DB      2 * 8                   ; CALL
        DW      CALL_OPER
        DB      10011000B               ; CBW
        DW      NO_OPER
        DB      11111000B               ; CLC
        DW      NO_OPER
        DB      11111100B               ; CLD
        DW      NO_OPER
        DB      11111010B               ; DIM
        DW      NO_OPER
        DB      11110101B               ; CMC
        DW      NO_OPER
        DB      10100110B               ; CMPB
        DW      NO_OPER
        DB      10100111B               ; CMPW
        DW      NO_OPER
        DB      7 * 8                   ; CMP
        DW      GROUP2
        DB      10011001B               ; CWD
        DW      NO_OPER
        DB      00100111B               ; DAA
        DW      NO_OPER
        DB      00101111B               ; DAS
        DW      NO_OPER
        DB      1 * 8                   ; DEC
        DW      DCINC_OPER
        DB      6 * 8                   ; DIV
        DW      GROUP1
        DB      11011000B               ; ESC
        DW      ESC_OPER
        DB      00001001B               ; FXCH
        DW      FGROUPP
        DB      00101000B               ; FFREE
        DW      FGROUPP
        DB      11011001B               ; FCOMPP
        DW      FDE_OPER
        DB      00000011B               ; FCOMP
        DW      FGROUPX                 ; Exception to normal P instructions
        DB      00000010B               ; FCOM
        DW      FGROUPX
        DB      00010011B               ; FICOMP
        DW      FGROUPZ
        DB      00010010B               ; FICOM
        DW      FGROUPZ
        DB      11010000B               ; FNOP
        DW      FD9_OPER
        DB      11100000B               ; FCHS
        DW      FD9_OPER
        DB      11100001B               ; FABS
        DW      FD9_OPER
        DB      11100100B               ; FTST
        DW      FD9_OPER
        DB      11100101B               ; FXAM
        DW      FD9_OPER
        DB      11101001B               ; FLDL2T
        DW      FD9_OPER
        DB      11101010B               ; FLDL2E
        DW      FD9_OPER
        DB      11101100B               ; FLDLG2
        DW      FD9_OPER
        DB      11101101B               ; FLDLN2
        DW      FD9_OPER
        DB      11101011B               ; FLDPI
        DW      FD9_OPER
        DB      11101000B               ; FLD1
        DW      FD9_OPER
        DB      11101110B               ; FLDZ
        DW      FD9_OPER
        DB      11110000B               ; F2XM1
        DW      FD9_OPER
        DB      11111001B               ; FYL2XP1
        DW      FD9_OPER
        DB      11110001B               ; FYL2X
        DW      FD9_OPER
        DB      11110010B               ; FPTAN
        DW      FD9_OPER
        DB      11110011B               ; FPATAN
        DW      FD9_OPER
        DB      11110100B               ; FXTRACT
        DW      FD9_OPER
        DB      11110110B               ; FDECSTP
        DW      FD9_OPER
        DB      11110111B               ; FINCSTP
        DW      FD9_OPER
        DB      11111000B               ; FPREM
        DW      FD9_OPER
        DB      11111010B               ; FSQRT
        DW      FD9_OPER
        DB      11111100B               ; FRNDINT
        DW      FD9_OPER
        DB      11111101B               ; FSCALE
        DW      FD9_OPER
        DB      11100011B               ; FINIT
        DW      FDB_OPER
        DB      11100001B               ; FDISI
        DW      FDB_OPER
        DB      11100000B               ; FENI
        DW      FDB_OPER
        DB      11100010B               ; FCLEX
        DW      FDB_OPER
        DB      00111100B               ; FBLD
        DW      FGROUPB
        DB      00111110B               ; FBSTP
        DW      FGROUPB
        DB      00001101B               ; FLDCW
        DW      FGROUP3W
        DB      00001111B               ; FSTCW
        DW      FGROUP3W
        DB      00101111B               ; FSTSW
        DW      FGROUP3W
        DB      00001110B               ; FSTENV
        DW      FGROUP3
        DB      00001100B               ; FLDENV
        DW      FGROUP3
        DB      00101110B               ; FSAVE
        DW      FGROUP3
        DB      00101100B               ; FRSTOR
        DW      FGROUP3
        DB      00110000B               ; FADDP
        DW      FGROUPP
        DB      00000000B               ; FADD
        DW      FGROUP
        DB      00010000B               ; FIADD
        DW      FGROUPZ
        DB      00110100B               ; FSUBRP
        DW      FGROUPP
        DB      00000101B               ; FSUBR
        DW      FGROUPDS
        DB      00110101B               ; FSUBP
        DW      FGROUPP
        DB      00000100B               ; FSUB
        DW      FGROUPDS
        DB      00010101B               ; FISUBR
        DW      FGROUPZ
        DB      00010100B               ; FISUB
        DW      FGROUPZ
        DB      00110001B               ; FMULP
        DW      FGROUPP
        DB      00000001B               ; FMUL
        DW      FGROUP
        DB      00010001B               ; FIMUL
        DW      FGROUPZ
        DB      00110110B               ; FDIVRP
        DW      FGROUPP
        DB      00000111B               ; FDIVR
        DW      FGROUPDS
        DB      00110111B               ; FDIVP
        DW      FGROUPP
        DB      00000110B               ; FDIV
        DW      FGROUPDS
        DB      00010111B               ; FIDIVR
        DW      FGROUPZ
        DB      00010110B               ; FIDIV
        DW      FGROUPZ
        DB      10011011B               ; FWAIT
        DW      NO_OPER
        DB      00011000B               ; FILD
        DW      FGROUPZ
        DB      00001000B               ; FLD
        DW      FGROUPX
        DB      00001011B               ; FSTP
        DW      FGROUPX
        DB      00101010B               ; FST
        DW      FGROUPX
        DB      00011011B               ; FISTP
        DW      FGROUPZ
        DB      00011010B               ; FIST
        DW      FGROUPZ
        DB      11110100B               ; HLT
        DW      NO_OPER
        DB      7 * 8                   ; IDIV
        DW      GROUP1
        DB      5 * 8                   ; IMUL
        DW      GROUP1
        DB      0 * 8                   ; INC
        DW      DCINC_OPER
        DB      11001110B               ; INTO
        DW      NO_OPER
        DB      11001100B               ; INTM
        DW      INT_OPER
        DB      11101100B               ; IN
        DW      IN_OPER
        DB      11001111B               ; IRET
        DW      NO_OPER
        DB      01110111B               ; JNBE
        DW      DISP8_OPER
        DB      01110011B               ; JAE
        DW      DISP8_OPER
        DB      01110111B               ; JA
        DW      DISP8_OPER
        DB      11100011B               ; JCXZ
        DW      DISP8_OPER
        DB      01110011B               ; JNB
        DW      DISP8_OPER
        DB      01110110B               ; JBE
        DW      DISP8_OPER
        DB      01110010B               ; JB
        DW      DISP8_OPER
        DB      01110011B               ; JNC
        DW      DISP8_OPER
        DB      01110010B               ; JC
        DW      DISP8_OPER
        DB      01110010B               ; JNAE
        DW      DISP8_OPER
        DB      01110110B               ; JNA
        DW      DISP8_OPER
        DB      01110100B               ; JZ
        DW      DISP8_OPER
        DB      01110100B               ; JE
        DW      DISP8_OPER
        DB      01111101B               ; JGE
        DW      DISP8_OPER
        DB      01111111B               ; JG
        DW      DISP8_OPER
        DB      01111111B               ; JNLE
        DW      DISP8_OPER
        DB      01111101B               ; JNL
        DW      DISP8_OPER
        DB      01111110B               ; JLE
        DW      DISP8_OPER
        DB      01111100B               ; JL
        DW      DISP8_OPER
        DB      01111100B               ; JNGE
        DW      DISP8_OPER
        DB      01111110B               ; JNG
        DW      DISP8_OPER
        DB      4 * 8                   ; JMP
        DW      JMP_OPER
        DB      01110101B               ; JNZ
        DW      DISP8_OPER
        DB      01110101B               ; JNE
        DW      DISP8_OPER
        DB      01111010B               ; JPE
        DW      DISP8_OPER
        DB      01111011B               ; JPO
        DW      DISP8_OPER
        DB      01111011B               ; JNP
        DW      DISP8_OPER
        DB      01111001B               ; JNS
        DW      DISP8_OPER
        DB      01110001B               ; JNO
        DW      DISP8_OPER
        DB      01110000B               ; JO
        DW      DISP8_OPER
        DB      01111000B               ; JS
        DW      DISP8_OPER
        DB      01111010B               ; JP
        DW      DISP8_OPER
        DB      10011111B               ; LAHF
        DW      NO_OPER
        DB      11000101B               ; LDS
        DW      L_OPER
        DB      10001101B               ; LEA
        DW      L_OPER
        DB      11000100B               ; LES
        DW      L_OPER
        DB      11110000B               ; LOCK
        DW      NO_OPER
        DB      10101100B               ; LODB
        DW      NO_OPER
        DB      10101101B               ; LODW
        DW      NO_OPER
        DB      11100000B               ; LOOPNZ
        DW      DISP8_OPER
        DB      11100001B               ; LOOPZ
        DW      DISP8_OPER
        DB      11100000B               ; LOOPNE
        DW      DISP8_OPER
        DB      11100001B               ; LOOPE
        DW      DISP8_OPER
        DB      11100010B               ; LOOP
        DW      DISP8_OPER
        DB      10100100B               ; MOVB
        DW      NO_OPER
        DB      10100101B               ; MOVW
        DW      NO_OPER
        DB      11000110B               ; MOV
        DW      MOV_OPER
        DB      4 * 8                   ; MUL
        DW      GROUP1
        DB      3 * 8                   ; NEG
        DW      GROUP1
        DB      10010000B               ; NOP
        DW      NO_OPER
        DB      2 * 8                   ; NOT
        DW      GROUP1
        DB      11101110B               ; OUT
        DW      OUT_OPER
        DB      10011101B               ; POPF
        DW      NO_OPER
        DB      0 * 8                   ; POP
        DW      POP_OPER
        DB      10011100B               ; PUSHF
        DW      NO_OPER
        DB      6 * 8                   ; PUSH
        DW      PUSH_OPER
        DB      2 * 8                   ; RCL
        DW      ROTOP
        DB      3 * 8                   ; RCR
        DW      ROTOP
        DB      11110011B               ; REPZ
        DW      NO_OPER
        DB      11110010B               ; REPNZ
        DW      NO_OPER
        DB      11110011B               ; REPE
        DW      NO_OPER
        DB      11110010B               ; REPNE
        DW      NO_OPER
        DB      11110011B               ; REP
        DW      NO_OPER
        DB      11001011B               ; RETF
        DW      GET_DATA16
        DB      11000011B               ; RET
        DW      GET_DATA16
        DB      0 * 8                   ; ROL
        DW      ROTOP
        DB      1 * 8                   ; ROR
        DW      ROTOP
        DB      10011110B               ; SAHF
        DW      NO_OPER
        DB      7 * 8                   ; SAR
        DW      ROTOP
        DB      10101110B               ; SCAB
        DW      NO_OPER
        DB      10101111B               ; SCAW
        DW      NO_OPER
        DB      4 * 8                   ; SHL
        DW      ROTOP
        DB      5 * 8                   ; SHR
        DW      ROTOP
        DB      11111001B               ; STC
        DW      NO_OPER
        DB      11111101B               ; STD
        DW      NO_OPER
        DB      11111011B               ; EI
        DW      NO_OPER
        DB      10101010B               ; STOB
        DW      NO_OPER
        DB      10101011B               ; STOW
        DW      NO_OPER
        DB      11110110B               ; TEST
        DW      TST_OPER
        DB      10011011B               ; WAIT
        DW      NO_OPER
        DB      10000110B               ; XCHG
        DW      EX_OPER
        DB      11010111B               ; XLAT
        DW      NO_OPER
        DB      00100110B               ; ESSEG
        DW      NO_OPER
        DB      00101110B               ; CSSEG
        DW      NO_OPER
        DB      00110110B               ; SSSEG
        DW      NO_OPER
        DB      00111110B               ; DSSEG
        DW      NO_OPER

label zzopcode byte
MAXOP   = (zzopcode-OPTAB)/3

SHFTAB  DW             ROLMN,RORMN,RCLMN
        DW             RCRMN,SHLMN,SHRMN
        DW             BADMN,SARMN

IMMTAB  DW      ADDMN,ORMN,ADCMN
        DW      SBBMN,ANDMN,SUBMN
        DW      XORMN,CMPMN

GRP1TAB DW      TESTMN,BADMN,NOTMN
        DW      NEGMN,MULMN,IMULMN
        DW      DIVMN,IDIVMN

GRP2TAB DW      INCMN,DECMN,CALLMN
        DW      CALLMN,JMPMN,JMPMN
        DW      PUSHMN,BADMN

SEGTAB  DW      ESSAVE,CSSAVE,SSSAVE
        DW      DSSAVE

REGTAB  DB      "AXBXCXDXSPBPSIDIDSESSSCSIPPC"

; Flags are ordered to correspond with the bits of the flag
; register, most significant bit first, zero if bit is not
; a flag. First 16 entries are for bit set, second 16 for
; bit reset.

FLAGTAB DW      0
        DW      0
        DW      0
        DW      0
        DB      "OV"
        DB      "DN"
        DB      "EI"                    ; "STI"
        DW      0
        DB      "NG"
        DB      "ZR"
        DW      0
        DB      "AC"
        DW      0
        DB      "PE"
        DW      0
        DB      "CY"
        DW      0
        DW      0
        DW      0
        DW      0
        DB      "NV"
        DB      "UP"                    ; "CLD"
        DB      "DI"
        DW      0
        DB      "PL"
        DB      "NZ"
        DW      0
        DB      "NA"
        DW      0
        DB      "PO"
        DW      0
        DB      "NC"

        DB      80H dup (0)
label STACK_ byte


; Register save area

AXSAVE  DW      0
BXSAVE  DW      0
CXSAVE  DW      0
DXSAVE  DW      0
SPSAVE  DW      5AH
BPSAVE  DW      0
SISAVE  DW      0
DISAVE  DW      0
DSSAVE  DW      0
ESSAVE  DW      0
label RSTACK word; Stack set here so registers can be saved by pushing
SSSAVE  DW      0
CSSAVE  DW      0
IPSAVE  DW      100H
FSAVE_   DW      0

REGDIF  =      AXSAVE-REGTAB

; RAM area.

RDFLG   DB      READ
TOTREG  DB      13
DSIZ    DB      0FH
NOREGL  DB      8
DISPB   DW      128

LBUFSIZ         DB      BUFLEN
LBUFFCNT        DB      0
LINEBUF DB      0DH
        DB      BUFLEN dup (0)
PFLAG   DB      0
COLPOS  DB      0

        IF      SYSVER
CONFCB  DB      0
        DB      "PRN        "
        DB      25 DUP(0)

POUT    DD      0
COUT    DD      0
CIN     DD      0
IOBUFF  DB      3 dup (0)
IOADDR  DD      0

IOCALL          DB      22
                DB      0
IOCOM           DB      0
IOSTAT          DW      0
                DB      8 DUP (0)
IOCHRET         DB      0
                DW      IOBUFF
IOSEG           DW      0
IOCNT           DW      1
                DW      0
        end if

QFLAG   DB      0
NEWEXEC DB      0
RETSAVE DW      0

USER_PROC_PDB DW      0

HEADSAVE DW      0

label EXEC_BLOCK byte
        DW      0
label COM_LINE dword
        DW      80H
        DW      0
label COM_FCB1 dword
        DW      FCB
        DW      0
label COM_FCB2 dword
        DW      FCB + 10H
        DW      0
COM_SSSP DD      0
COM_CSIP DD      0

end if
