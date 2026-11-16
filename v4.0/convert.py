"""A utility under src/CMD, or a driver under src/DEV, from MASM to fasm.

usage: convert.py UTILITY [ORIGINALS]

The checkers beside this file -- checkcode, checkbare, checkassume,
checkstruc -- say whether what comes out still says what the release said.
This is what writes it.

The rules are shared, every utility having needed most of them, and
UTILITIES below holds what is true of one alone: the modules in the order its
.LNK names them, the headers it reads, the names two of its modules both
wanted, and what its segment registers start on.  Converting the next one is
an entry there, and whatever rule it is the first to need.

The sources are converted in place, which is this project's way, so what is
in the utility's own directory -- src/CMD/<UTILITY>, or wherever its DIR
says -- is the release's own text until this has run over it: that is where
it reads from unless told otherwise.  To run it again
afterwards, hand it a directory of pristine copies as ORIGINALS, each file
named as the module is or with .orig after it, and the result goes over the
sources as before.
"""
import os
import re
import sys

UTILITIES = {
    # FORMAT's seven modules in the order FORMAT.LNK names them, and the
    # seven headers they read.  DISPLAY is first because it is the module
    # that declares the segments in the order LINK is to lay them down --
    # .SEQ and five empty declarations -- and because it holds the message
    # tables and the one routine that writes to the screen.
    'FORMAT': dict(
        MODULES=('DISPLAY.ASM', 'FORINIT.ASM', 'FORLABEL.ASM', 'FORMAT.ASM',
                 'FORPROC.ASM', 'MSFOR.ASM', 'FOREXEC.ASM',
                 'FILESIZE.INC', 'FORCHNG.INC', 'FOREQU.INC', 'FORMACRO.INC',
                 'FORMSG.INC', 'FORPARSE.INC', 'FORSWTCH.INC'),
        # the modules with structured-assembly labels of their own to mark
        TAG={'FORINIT.ASM': 'I', 'FORLABEL.ASM': 'L', 'FORPROC.ASM': 'P',
             'MSFOR.ASM': 'M', 'FOREXEC.ASM': 'E'},
        # FOREXEC names the command tail DOS leaves at 80h of the prefix
        # Command_Line, and FORINIT gives the same name to the flag in its
        # data that says whether a volume label came in on the command line.
        # Two modules assembled apart could each have it; one assembly can
        # only have the one.  The prefix's is the one that gives way: it is
        # read nowhere but in FOREXEC, where the flag is read in FORINIT and
        # in FORLABEL as well.
        PRIVATE={'FOREXEC.ASM': (('Command_Line', 'Command_Line_'),)},
        # BOOT.INC, BOOT11.INC and BOOTFORM.INC are the three MSFOR reads to
        # lay a boot sector down -- the first is what MASM made of
        # MSBOOT.ASM, as DB statements -- and IOCTL.INC is where the device
        # parameters FORLABEL and MSFOR ask the driver for are declared.
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'IOCTL.INC', 'BOOT.INC', 'BOOT11.INC', 'BOOTFORM.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM'),
        # FOREXEC exchanges DS and ES before it calls EXEC and reads
        # ExitStatus with the pair the other way round, and the ASSUMEs
        # around there say DS:NOTHING -- so MASM wrote the reference through
        # ES, which is the register that still holds the data segment.  The
        # override is put back on the line, there being no ASSUME for the
        # rules to read it from.
        # Fat_Init reads the FAT's address, its size in paragraphs and the
        # value to fill it with out of the data segment, which DS holds: it
        # is called with ES on the directory buffer and sets ES to the FAT
        # itself on its second line.  The ASSUME in force where it stands is
        # one left over from the routines above it -- DS:NOTHING, ES:DATA --
        # so the override those four reads want is said on the lines here.
        # The routine that writes the directory loads DS from a far
        # pointer, and says so with ASSUME DS:NOTHING, ES:DATA -- ES is on
        # the data there and DS is not.  Nothing puts that ASSUME back, so
        # it stands over the thirty-six routines that follow, which were
        # added later and read their data the plain way, through DS; DS is
        # the data segment in every one of them, their callers having set it
        # or never changed it.  An ASSUME of our own at the first of them
        # says that, and the release's line above it is left as it was.
        # MSFOR reserves 512 bytes for the 1.x boot sector it writes on an
        # old diskette, and then lays BOOT11.INC over them with MASM's ORG:
        # the location counter goes back to the start of the reservation,
        # the include writes over it, and a second ORG puts the counter back.
        # fasm's ORG moves the counter and not the place the output goes, so
        # the image would be written after the reservation instead of into
        # it and everything below would be laid down at the wrong address.
        # The include is 512 bytes and covers the reservation exactly, so
        # what MASM ended with is the include where the reservation was.
        PATCHES={'MSFOR.ASM': [
            ('boot2\tdb\t0,0,0, "Boot 1.x"\n\tdb\t512 - 11 dup(?)\n\n'
             'REORG2\tLABEL\tBYTE\n\tORG\tBOOT2\n\tINCLUDE BOOT11.INC\n'
             '\tORG\tREORG2',
             'boot2\tLABEL\tBYTE\n\tINCLUDE BOOT11.INC\n'
             'REORG2\tLABEL\tBYTE')],
                 'FORMAT.ASM': [
            ("procedure\twrite_fat\n",
             "\tassume\tds:data,es:nothing\t; the routines from here on read"
             "\n\t\t\t\t\t; their data through DS\n\n"
             "procedure\twrite_fat\n")],
                 'FOREXEC.ASM': [
            ("\t\t cmp\t ExitStatus,No_Error",
             "\t\t cmp\t es:ExitStatus,No_Error")]},
        # BOOT.CL1, which buildmsg.py writes from BOOT.SKL, spells the
        # boot sector's message SYSMSG, which is how MSBOOT.ASM asks for it.
        # MSFOR includes the same file and reads the label as sysmsg, and
        # measures the message's offset from it.
        SPELLING={'sysmsg': 'SYSMSG'},
        # BOOTFORM.INC's BOOT_SIGNATURE is the offset of the two bytes
        # at the end of a boot sector, and MSFOR compares them against
        # 0AA55h: a number carries no width, so the width is said here.
        ABSWIDTH={'BOOT_SIGNATURE': 'word'},
        # DISPLAY.ASM's ASSUME, which every module's code segment repeats:
        # the stack is a segment of its own and ES is named where it is
        # wanted, so it starts at nothing.
        START={'cs': 'CODE', 'ds': 'DATA', 'es': None, 'ss': 'STACK'},
    ),
    # MODE's sixteen modules in the order MODE.LNK names them, and the
    # seven headers they share.  RESCODE is first because it is the resident
    # part: the serial and printer routines MODE leaves behind, which it
    # moves into its own prefix at 60H as GRAFTABL moves its handler.
    'MODE': dict(
        MODULES=('RESCODE.ASM', 'MODEECHO.ASM', 'MODELENG.ASM', 'MODEMES.ASM',
                 'MODESCRN.ASM', 'MAIN.ASM', 'MODEVID.ASM', 'MODEPRIN.ASM',
                 'MODECOM.ASM', 'SCRNTAB.ASM', 'MODECP.ASM', 'DISPLAY.ASM',
                 'TYPAMAT.ASM', 'INVOKE.ASM', 'PARSHELL.ASM', 'MODEPARS.ASM',
                 'COMMON.STC', 'MODECPEQ.INC', 'MODECPMS.INC',
                 'MODECPRO.INC', 'MODEDEFS.INC', 'MODEQUAT.INC',
                 'MODESUBS.INC'),
        TAG={'MODESCRN.ASM': 'S', 'MODECP.ASM': 'C', 'SCRNTAB.ASM': 'T',
             'MODEPRIN.ASM': 'P'},
        # The labels MODE writes by hand and five modules each have: the
        # ENDIFnn and ELSEnn that stand where a structured statement would,
        # ENDC, the ENDCASE_n of a hand-written case, and the P0 to P7 of
        # MODEPRIN's and MODEECHO's port loops.
        # And the one-letter equates: the structured statements read C and Z
        # and the rest as the flags they are named for, and MODEVID's C is
        # the position of a letter in a parameter while INVOKE's B is a
        # retry setting -- two modules giving one name two values, which
        # fasm's EQU lets by without a word.
        LOCALS=(r"ENDIF\d+", r"ELSE\d+", r"ENDC", r"ENDCASE_\d+", r"P\d",
                r"[ABCEOLPSZ]"),
        # RESCODE describes the program prefix before its ORG 100H -- the
        # environment's segment at 2CH, where the resident code goes at 60H,
        # the command line at 80H -- and a reservation there is a name for a
        # place and not a byte to lay down: the image begins at 100H, where
        # DOS enters a .COM, and LINK's zeros before that went no further
        # than EXE2BIN.
        # Four of MODE's own names are fasm's: RT reserves a ten-byte real,
        # REPEAT opens a block that assembles more than once, MATCH is how
        # fasm takes text apart, and PTEST is an instruction of a later
        # processor.  MODE means by them labels in its retry and printer
        # code and two of the parser's keywords.
        RESERVED=('RT', 'REPEAT', 'MATCH', 'PTEST'),
        # INVOKE and MODECOM each name the far pointer at 0:530H, where the
        # resident part of MODE leaves its own address: MASM assembled them
        # apart and let both have the name.  One assembly can only have the
        # one, and they are the same place, so the one the link order
        # reaches second gives way.
        # MACHINE_TYPE is three names in one.  RESCODE keeps a byte of its
        # own by that name, which half the modules read; MODESCRN names the
        # byte the ROM BIOS has at 0F000:0FFFE the same thing and reads it
        # through DS; and SCRNTAB names that same ROM byte and never reads
        # it.  So the program's byte keeps the name, MODESCRN's says what it
        # is, and SCRNTAB's declaration goes -- two of them at one address
        # is one too many whatever they are called.
        # Two more are a module and one of MODE's own headers each
        # declaring storage of the same name -- INVOKE's row_value against
        # MODESUBS.INC's, and RESCODE's PARM1 against MODEDEFS.INC's.  MASM
        # gave each module that read the header a copy of its own and the
        # modules reach theirs by offset, so the module's gives way.
        #
        # Two more are names a shared header gives a number to and MODE
        # gives storage: INC/VERSIONA.INC's MINOR_VERSION against MODECP's
        # two bytes of that name, and INC/SYSMSG.INC's colon against
        # MODEPARS's.  The header's is the one the retriever reads, so
        # MODE's gives way.
        #
        # Two of the message table's names are MODEPARS's keyword strings
        # as well -- the "RATE=%1" and "DELAY=%1" messages against the
        # RATE= and DELAY= the parser looks for -- and the strings are what
        # every module that names them reads.  Nothing reads the two
        # messages, so theirs are the names that give way.
        #
        # COM_status is two numbers: MODEPARS's request type of 93H, which
        # INVOKE reads, and the 3 RESCODE passes the ROM BIOS to ask a
        # serial port for its status.  fasm takes an EQU's value where the
        # EQU is written, and the modules are read once per segment, so
        # RESCODE's 3 stood where INVOKE wanted the 93H -- which sent the
        # status of every device through a jump table by the wrong index.
        # The resident part's number gives way, being read in the one
        # module.
        #
        # Five names mean one thing in one module and another in another,
        # which MASM allowed because it assembled them apart.  The equate
        # gives way to the storage or the procedure, and the label to the
        # storage: MODEECHO's mask for an ASCII digit against MODELENG's
        # routine of that name, its CASE against MODEPRIN's byte, MODEPRIN's
        # COLON against MODEPARS's, MODEPRIN's label against the resident
        # part's LOADED_YET, and INVOKE's REDIRECTED against MODEPRIN's.
        PRIVATE={'MODESCRN.ASM': (('MACHINE_TYPE', 'MACHINE_TYPE_ROM'),),
                 'MODEECHO.ASM': (('ascii_to_int', 'ascii_to_int_'),
                                  ('CASE', 'CASE_')),
                 'MODEPRIN.ASM': (('COLON', 'COLON_'),
                                  ('LOADED_YET', 'LOADED_YET_'),
                                  ('COUNT', 'COUNT_')),
                 'INVOKE.ASM': (('redirected', 'redirected_'),
                                ('row_value', 'row_value_'),
                                ('i', 'i_')),
                 'RESCODE.ASM': (('PARM1', 'PARM1_'),
                                 ('COM_status', 'COM_status_bios')),
                 'MODECP.ASM': (('MINOR_VERSION', 'MINOR_VERSION_'),),
                 'MODEDEFS.INC': (('RATE_equal', 'RATE_equal_msg'),
                                  ('DELAY_equal', 'DELAY_equal_msg')),
                 'MODEPARS.ASM': (('colon', 'colon_byte'),
                                  ('jump_table1', 'jump_table1_'),
                                  ('code_page_numbers_encountered',
                                   'code_page_numbers_encountered_'),
                                  ('current_packet_cp_number',
                                   'current_packet_cp_number_'))},
        # Five modules name the far pointer at 0:530H where the resident
        # part of MODE leaves its own address, three name the interrupt 14H
        # vector at 0:50H, and two the EGA's signature word: MASM assembled
        # them apart and let each have the name.  They are the same places,
        # so the module the link order reaches first declares each of them
        # and the others' declarations go; what the others wrote of them
        # reads the one declaration, the name being the same.
        PATCHES={'MODEECHO.ASM': [
            ("RESSEG\t\tDD\t?", ";RESSEG\t\tDD\t?"),
            ("VECT14H \tLABEL\tDWORD", ";VECT14H \tLABEL\tDWORD")],
                 'MODEPRIN.ASM': [
            ("RESSEG\tLABEL\tDWORD", ";RESSEG\tLABEL\tDWORD"),
            ("MOV   AX,submessage", "MOV   AX,[submessage]")],
                 'MODECOM.ASM': [
            ("RESSEG\tLABEL\tDWORD", ";RESSEG\tLABEL\tDWORD"),
            ("VECT14H    LABEL  DWORD", ";VECT14H    LABEL  DWORD")],
                 'INVOKE.ASM': [
            ("resseg\tLABEL\tDWORD", ";resseg\tLABEL\tDWORD"),
            # MASM let blanks separate a macro's arguments and ignored the
            # ones the macro had no parameter for, so the comment this line
            # lost its semicolon from went in as a second argument to a
            # macro of one and fell away.  fasm reads the line to the end.
            ('long_underline\t\t\t\t      "Status for device LPTX?"',
             'long_underline\t\t\t\t     ;"Status for device LPTX?"')],
                 'MODEVID.ASM': [
            ("SIGWORD DW\t?", ";SIGWORD DW\t?")],
                 # set_submessage_ptr takes the message whose text is to go
                 # into another message's sublist, and moves the number out
                 # of the block that describes it: a bare name was the word
                 # at the place to MASM, and the three modules that have the
                 # macro all pass it one of the message blocks MODEDEFS.INC
                 # lays down, whose first word is the number.  The brackets
                 # say so where the name is a macro's argument and the rule
                 # for storage cannot see it.
                 'MODECP.ASM': [
            ("MOV   AX,submessage", "MOV   AX,[submessage]")],
                 'MODESCRN.ASM': [
            ("MOV   AX,submessage", "MOV   AX,[submessage]")],
                 # modify_parser_control_block moves its third argument
                 # into AL, and the three kinds of argument the module
                 # passes it were three different instructions to MASM: a
                 # register for i_CL, a character for ".", and the byte at
                 # the place for colon.  One macro body cannot be all three
                 # here, so the two lines that name a place say so.  The
                 # name is the one the rules above give MODEPARS's colon,
                 # the patches going on after them.
                 'MODEPARS.ASM': [
            ("seperator_list,delete,colon_byte",
             "seperator_list,delete,[colon_byte]"),
            ("seperator_list,addd,colon_byte",
             "seperator_list,addd,[colon_byte]")],
                 'SCRNTAB.ASM': [
            ("\tMACHINE_TYPE LABEL   BYTE",
             ";\tMACHINE_TYPE LABEL   BYTE")],
                 'RESCODE.ASM': [
            ("environ_seg    DW    ?", "environ_seg    LABEL WORD"),
            # The byte this one reserves is what puts the command line's
            # first character at 81H, and the ORG says so where the
            # reservation no longer can: it is the counter the byte moved
            # and not the byte that matters, the image beginning at 100H.
            ("command_line_length  DB    ?\t\t\t;not used, just place "
             "holder to allign next field",
             "command_line_length  LABEL BYTE\t\t;not used, just place "
             "holder to allign next field\n\tORG\t81H")]},
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'STRUC.INC', 'COPYRIGH.INC', 'PATHMAC.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM'),
        # MASM began each module with the registers assumed on nothing, and
        # the modules say CS:PRINTF_CODE and DS:PRINTF_CODE for themselves.
        START={'cs': 'DGROUP', 'ds': None, 'es': None, 'ss': None},
        # The names a macro pastes together.  MASM read a name in any case
        # and fasm pastes the letters as they stand, so a paste cannot be
        # brought to the spelling of the declaration the way a reference
        # can: the declaration takes the spelling of the paste instead.
        # MODESCRN, MODEPRIN and MODECP reach a message's sublist as
        # sublist_&message, each writing the message's name in its own case.
        SPELLING={'sublist_cant_shift': 'sublist_CANT_SHIFT',
                  'sublist_shift_msg': 'sublist_SHIFT_MSG',
                  'sublist_retparto': 'sublist_RETPARTO',
                  'sublist_cpmsg8': 'sublist_cpmsg8',
                  'sublist_cpmsg10': 'sublist_cpmsg10',
                  'sublist_cpmsg17': 'sublist_cpmsg17'},
    ),
    # GRAFTABL's ten modules in the order GRAFTABL.LNK names them, and the
    # header they share.  GRTABHAN is first because it is the resident part:
    # the interrupt handler and the 1K table it answers from, which the
    # loader moves into the program's own prefix at 60H and leaves there.
    # The eight modules between are the character sets -- US, Multilingual,
    # Portuguese, Canadian French, Nordic -- and the parser.
    # APPEND's one module -- the makefile links append.obj and nothing
    # else -- with the parser switches and the macro library it reads.  Two
    # segments and no group, cseg and sseg, so the module is read once per
    # segment, and the stack is laid down in the image rather than reserved.
    # The release links the one and stops: this is an .EXE in its own right.
    #
    # APPENDM.ASM is not among them.  It held the messages before the
    # message retriever took them over -- @@11 in the module's own history
    # -- the makefile does not name it, and the appendm.inc it reads is not
    # in the release.
    #
    # Only three of SYSMAC.LIB's fourteen macros are ever called: MOVE,
    # COMP and JUMP.  The rest are converted as far as the rules reach and
    # never expanded, which is what MASM did with them too.
    'APPEND': dict(
        MODULES=('APPEND.ASM', 'APPENDP.INC', 'SYSMAC.LIB'),
        TAG={},
        SHARED=('SYSMSG.INC', 'VERSIONA.INC', 'PDB.INC', 'PARSE.ASM',
                'MSGDCL.INC', 'MSGSERV.ASM', 'PSDATA.INC', 'COPYRIGH.INC'),
        # cseg's own ASSUME, which says CS and nothing else: APPEND is
        # entered as an .EXE, with DS and ES on the program prefix, and
        # sets SS and SP itself on the stack segment.
        START={'cs': 'cseg', 'ds': None, 'es': None, 'ss': 'sseg'},
        # The three flags APPEND lays its mode word down with, nine lines
        # before it declares them: MASM resolved them on its second pass,
        # and fasm wants a number it can resolve wherever it stands rather
        # than an EQU it has not read yet.
        FORWARD=('Path_mode', 'Drive_mode', 'Enabled'),
    ),
    # NLSFUNC's two modules in the order the makefile links them, and the
    # four headers of its own that they read.  Three segments and no group
    # -- NLS_DATA for the buffers and the message text, NLS_INIT_CODE for
    # the code, and STACK -- so the modules are read once per segment, the
    # way the kernel's are, and each segment is an address space of its own.
    # The release links the two and stops: this is an .EXE in its own right.
    'NLSFUNC': dict(
        MODULES=('NLSFUNC.ASM', 'NLSPARM.ASM', 'DOESMAC.INC',
                 'FUNCDBCS.INC', 'FUNCPARM.INC', 'MSG2NLS.INC'),
        TAG={},
        SHARED=('COPYRIGH.INC', 'STRUC.INC', 'MULT.INC', 'SF.INC',
                'DOSCNTRY.INC', 'DEVSYM.INC', 'SYSMSG.INC', 'PARSE.ASM',
                'PSDATA.INC', 'MSGSERV.ASM', 'MSGDCL.INC', 'DOSSYM.INC',
                'SYSCALL.INC', 'DOSMAC.INC', 'VERSIONA.INC', 'ERROR.INC',
                'CPMFCB.INC', 'PDB.INC', 'CURDIR.INC', 'SYSVAR.INC',
                'DIRENT.INC', 'DPB.INC', 'BUFFER.INC', 'VECTOR.INC',
                'ARENA.INC', 'EXE.INC', 'FIND.INC', 'FILEMODE.INC',
                'MI.INC', 'INTNAT.INC', 'VERSION.INC'),
        # The code segment's own ASSUME, which says CS and nothing else:
        # NLSFUNC is entered as an .EXE, with DS and ES on the program
        # prefix, and sets DS itself where it wants its data.
        START={'cs': 'NLS_INIT_CODE', 'ds': None, 'es': None, 'ss': None},
        # The character the message table pads a country name out with,
        # which MSG2NLS.INC lays down three of and NLSFUNC declares
        # eighteen lines after it reads that header: MASM resolved the name
        # on its second pass, and fasm wants a number it can resolve
        # wherever it stands rather than an EQU it has not read yet.
        FORWARD=('PAD_CHAR',),
    ),
    # ASSIGN's two modules in the order the makefile links them, and the
    # headers they read.  One segment, code, and no group, so the two are
    # read once rather than once per segment -- the shape TREE, COMP and
    # GRAFTABL have.  code begins where the load module does, which for a
    # .COM is the program's own prefix: ASSGMAIN names that start
    # ASSIGN_BASE and the org 100H after it is where DOS enters.
    'ASSIGN': dict(
        MODULES=('ASSGMAIN.ASM', 'ASSGPARM.ASM', 'ASSGPARM.INC',
                 'ASSGMSG.INC'),
        TAG={},
        ONESEG=True,
        SHARED=('SYSMSG.INC', 'SYSVAR.INC', 'CURDIR.INC', 'MULT.INC',
                'PDB.INC', 'DOSMAC.INC', 'SYSCALL.INC', 'MSGSERV.ASM',
                'MSGDCL.INC', 'PSDATA.INC', 'PARSE.ASM', 'DOSSYM.INC',
                'DEVSYM.INC', 'ERROR.INC', 'VERSIONA.INC'),
        # ASSGMAIN assumes CS on the one segment and nothing else: the
        # handler it leaves resident is entered on an interrupt, with the
        # interrupted program's DS, so what it reads of its own it reads
        # through CS until the initialisation says otherwise.
        START={'cs': 'CODE', 'ds': None, 'es': None, 'ss': None},
    ),
    'GRAFTABL': dict(
        MODULES=('GRTABHAN.ASM', 'GRTABUS.ASM', 'GRTABML.ASM', 'GRTABPO.ASM',
                 'GRTABCF.ASM', 'GRTABNO.ASM', 'GRTABSM.ASM', 'GRTABPAR.ASM',
                 'GRTABP.ASM', 'GRTAB.ASM', 'GRTABMS.INC'),
        TAG={'GRTABHAN.ASM': 'H', 'GRTABPAR.ASM': 'P'},
        ONESEG=True,
        # GRTABHAN declares INSTALLED EQU 0FFH, the answer its handler gives
        # INT 2FH, and GRTAB gives the same name to the byte it keeps that
        # answer in.  MASM assembled the two apart; one assembly can only
        # have the one, and the byte is the one that is read, so the equate
        # gives way.
        PRIVATE={'GRTABHAN.ASM': (('INSTALLED', 'INSTALLED_'),)},
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'COPYRIGH.INC', 'PATHMAC.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM'),
        # MASM began each module with every register assumed on nothing,
        # and GRTABHAN says only ASSUME CS:CSEG -- its handler is entered on
        # an interrupt, with the interrupted program's DS, so what it reads
        # of its own it reads through CS.  The modules that have the segment
        # in all four registers, GRTAB among them, say so themselves.
        START={'cs': 'CSEG', 'ds': None, 'es': None, 'ss': None},
    ),
    # DEBUG's eleven modules in the order DEBUG.LNK names them, and the two
    # headers they read: DEBEQU.ASM is the numbers and the structures, and
    # SYSVER.INC is the copy of SYSVER.FAL the release shipped, which says
    # which of the two versions of the version check to assemble.
    'DEBUG': dict(
        MODULES=('DEBUG.ASM', 'DEBCOM1.ASM', 'DEBCOM2.ASM', 'DEBCOM3.ASM',
                 'DEBASM.ASM', 'DEBUASM.ASM', 'DEBERR.ASM', 'DEBCONST.ASM',
                 'DEBMES.ASM', 'DEBEMS.ASM', 'DEBDATA.ASM',
                 'DEBEQU.ASM', 'SYSVER.INC'),
        TAG={'DEBCOM1.ASM': '1', 'DEBCOM2.ASM': '2', 'DEBERR.ASM': 'E',
             'DEBEMS.ASM': 'M', 'DEBMES.ASM': 'S'},
        # Five of DEBUG's own names are fasm's: STACK says where the stack
        # of an MZ image is, LOAD and STORE read and write bytes already
        # assembled, ERR stops the assembly, and INT3 is the one-byte
        # breakpoint -- which is what DEBUG is about, so it names the place
        # it handles one after the instruction itself.
        RESERVED=('STACK', 'LOAD', 'STORE', 'ERR', 'INT3'),
        # DEBUG calls the routine that moves the cursor to the next column
        # TAB, and INC/SYSMSG.INC gives the same name to the number 9.  Only
        # DEBMES reads that header, so MASM met the two in no one module;
        # one assembly meets them both, and the routine is the one that gives
        # way, the header's name being shared with every other utility.
        #
        # Two more are a name two modules each kept for a loop of its own,
        # which MASM let them have because it assembled them apart: DEBASM
        # has TEST1 where DEBUG.ASM has the test1 the release left in by
        # hand, and DEBUASM has GET_OPCODE where DEBCOM3 has get_opcode.
        # Each is read in its own module and nowhere else, so the one the
        # link order reaches second gives way.
        PRIVATE={'DEBUG.ASM': (('TAB', 'TAB_'),),
                 'DEBCOM1.ASM': (('TAB', 'TAB_'),),
                 'DEBUASM.ASM': (('TAB', 'TAB_'),
                                 ('GET_OPCODE', 'GET_OPCODE_')),
                 'DEBASM.ASM': (('TEST1', 'TEST1_'),)},
        # DPL.ASM is the server call parameter list, which DEBEMS reads for
        # the expanded memory calls.
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM',
                'DPL.ASM'),
        # every module's code begins ASSUME CS:DG,DS:DG,ES:DG,SS:DG: one
        # group is one address space and all four registers hold it
        START={'cs': 'DG', 'ds': 'DG', 'es': 'DG', 'ss': 'DG'},
    ),
    # XCOPY's three modules and the four headers they read.  XCOPY.EQU and
    # DOS.EQU are read by two modules apiece and hold nothing but equates;
    # XMAINMSG.EQU and XINITMSG.EQU are read by one each and lay their
    # message tables down.
    'XCOPY': dict(
        MODULES=('XCOPY.ASM', 'XCPYINIT.ASM', 'XCOPYPAR.ASM',
                 'DOS.EQU', 'XCOPY.EQU', 'XINITMSG.EQU', 'XMAINMSG.EQU'),
        TAG={'XCPYINIT.ASM': 'I', 'XCOPYPAR.ASM': 'P'},
        # XCOPY.ASM declares a structure called HEADER, for what it keeps
        # about each file in the buffer, and XCOPYPAR.ASM gives the same name
        # to the macro that writes a page heading.  The macro is the one that
        # gives way: it writes nothing, where the structure's fifteen fields
        # are the shape of the buffer and are worth holding against the
        # release.
        PRIVATE={'XCOPYPAR.ASM': (('HEADER', 'HEADING_'),)},
        # DOSSYM.INC is in the list for the structures the shared headers lay
        # out, though no module reads it: XCOPY has a DOS.EQU of its own.
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM'),
        # all three modules begin their code with ASSUME CS:CSEG, DS:DGROUP
        START={'cs': 'CSEG', 'ds': None, 'es': None, 'ss': 'SSEG'},
    ),
    # PRINT's four modules in the order PRINT.LNK names them, and the one
    # header of its own they all read.  PRIDEFS.INC holds the numbers, the
    # structures and the four segment declarations; PRIDEFS.ASM is a shorter
    # copy of it that the makefile names and no module reads.
    'PRINT': dict(
        MODULES=('PRINT_RM.ASM', 'PRINT_R.ASM', 'PRINT_T.ASM',
                 'PRINT_TM.ASM', 'PRIDEFS.INC'),
        TAG={'PRINT_T.ASM': 'T'},
        # Both halves of the program have a loop called IntWhileBusy that
        # waits for the resident part to let go: PRINT_R's is the one in the
        # bootstrap cleanup, jumped to from the line under it and read
        # nowhere else, where PRINT_T's is a procedure it calls from eight
        # places.  MASM assembled the two apart; one assembly can only have
        # the one, and the local one is the one that gives way.
        PRIVATE={'PRINT_R.ASM': (('IntWhileBusy', 'IntWhileBusy_'),)},
        # PRIDEFS.INC, which every module reads, declares FALSE EQU 0, and
        # PRINT_TM says "false = 0" again over it before it sets the
        # parser's switches with it.  MASM minded neither the case nor the
        # second declaration, the value being the one already given; fasm's
        # EQU puts the text where the name stands, so the line is read as
        # "0 = 0".  It says nothing the header has not said, and goes.
        PATCHES={'PRINT_TM.ASM': [('false\t\t\t=    0',
                                   ';false\t\t\t=    0')]},
        # EA.INC is the extended attribute calls, which the resident part
        # reads a file with; DPL.ASM is the server call parameter list and
        # COPYRIGH.INC the notice PRINT_R lays down after its own name.
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM',
                'DEVSYM.INC', 'EA.INC', 'DPL.ASM', 'COPYRIGH.INC'),
        # The resident part's own ASSUME, which says CS and nothing else:
        # it is entered on an interrupt, with the interrupted program's DS,
        # so what it reads of its own it reads through CS.  The transient
        # part says ASSUME CS:DG,SS:Stack for itself at the head of each of
        # its segments.
        START={'cs': 'CODER', 'ds': None, 'es': None, 'ss': None},
        # The word PRINT_R keeps the printer's number in is laid down with
        # the value that says there is none, and the line that declares
        # that value stands under it: MASM resolved the name on its second
        # pass, and fasm wants a number it can resolve wherever it stands
        # rather than an EQU it has not read yet.
        FORWARD=('no_lptx',),
    ),
    # FASTOPEN's five modules in the order FASTOPEN.LNK names them, and the
    # one header of its own they read.  FASTSEGS.INC declares the five
    # segments in the order .seq tells LINK to lay them down -- stack,
    # cseg_main, cseg_open, cseg_seek, cseg_init -- and nothing else, which
    # is why FASTOPEN.ASM says it "cannot include in Fastopen.inc": the
    # header of that name is the shared one in src/INC.
    'FASTOPEN': dict(
        MODULES=('FASTOPEN.ASM', 'FASTSEEK.ASM', 'FASTINIT.ASM', 'FASTP.ASM',
                 'FASTSM.ASM', 'FASTSEGS.INC'),
        TAG={},
        # FASTOPEN.INC is the shared header of the same name, which holds
        # the cache's structures and the DOS equates the modules read; the
        # directory entry and the vector table come with it.
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM',
                'DEVSYM.INC', 'COPYRIGH.INC', 'FASTOPEN.INC', 'FASTSEEK.INC',
                'FASTXXXX.INC'),
        # Each of the four code segments says ASSUME CS to itself and
        # nothing else at its head: FASTOPEN is entered as an .EXE, with DS
        # and ES on the program prefix, and the resident parts are entered
        # on the multiplex interrupt with whatever the caller had.
        START={'cs': 'CSEG_INIT', 'ds': None, 'es': None, 'ss': 'STACK'},
        # FASTOPEN and FASTSEEK each open with "DEBUG=0", which their own
        # comment says is an equate only for DOSMAC.INC, and FASTINIT says
        # "Debug EQU 0" for the routine that calls the installation check
        # -- over the DEBUG=FALSE it has already set itself.  MASM minded
        # neither the case nor the third declaration, every one of them
        # being nought; fasm's EQU puts the text where the name stands, so
        # the two assignments are read as "0 = 0" on the second reading of
        # the module.  The EQU becomes an = like the others, which fasm
        # resolves wherever it stands and lets be said again.
        FORWARD=('DEBUG',),
        # Eight names each of two modules has one of, which MASM let them
        # have because it assembled them apart: FASTOPEN and FASTSEEK both
        # walk their own cache from a CHECK_IT and keep the function they
        # were called for in a func_cod, and both have a check_exit to
        # leave by; FASTOPEN and FASTINIT share five more, four of them
        # labels and the fifth FASTOPEN's EMS_FAILED against the message
        # number of that name in FASTINIT's numbered block.  Each takes the
        # name of the module it is in.
        LOCALS=('CHECK_DRIVE_ID', 'CHECK_EXIT', 'CHECK_IT', 'EMS_FAILED',
                'ERROR_EXIT', 'FUNC_COD', 'SET_START', 'SET_UP_NAMES'),
        # FASTOPEN names the way out of its dispatcher EXIT, and
        # INC/SYSCALL.INC gives the same name to the number 4CH, the DOS
        # call that ends a program.  FASTOPEN.ASM does not read that
        # header, so MASM met the two in no one module; one assembly meets
        # them both, and the label is the one that gives way, the header's
        # name being shared with every other utility.
        PRIVATE={'FASTOPEN.ASM': (('EXIT', 'EXIT_'),)},
        # The one line in FASTOPEN that leaves a reference's width unsaid.
        # Looking for the expanded memory page frame, FASTINIT reads the
        # page's segment out of the mapping table with MOV AX,ES:[DI] two
        # lines further on, and compares the same place against 0A000H
        # here with nothing to say how wide it is: the operand is a bare
        # register, so there is no name for fasm to take the width from.
        # It is the word MOV reads, and the line says so now.
        PATCHES={'FASTINIT.ASM': [
            ('\tcmp\tes:[di], 0a000h', '\tcmp\tword ptr es:[di], 0a000h')]},
    ),
    # KEYB's ten modules in the order KEYB.LNK names them, and the fifteen
    # headers of its own they read.  One segment, CODE, and no group, so
    # the modules are read once rather than once per segment -- the shape
    # TREE, COMP, GRAFTABL and ASSIGN have.  CODE begins where the load
    # module does, which for a .COM is the program's own prefix, and
    # KEYB.ASM's org 100H is where DOS enters; the release links the ten
    # and runs EXE2BIN over the result.
    #
    # Each module has a header of its own named after it that holds its
    # EXTRNs -- KEYBI9.INC for KEYBI9.ASM -- and every module reads most of
    # the others', so all thirteen are in the list.
    #
    # KBMSG.INC and KEYBMSG.INC are not: nothing includes either, and they
    # are what KEYB had before the message retriever took its text over --
    # KBMSG.INC holds the messages as DBs and KEYBMSG.INC the EXTRNs for
    # them, every line of it commented out.  Reading KBMSG.INC would be
    # worse than idle: it gives INV_FN to the text "Bad or missing Keyboard
    # Definition File" where KEYBCMD gives it to the number 9, so the one
    # line that asks the retriever for that message would have read a word
    # of the old text instead of the message number.
    'KEYB': dict(
        MODULES=('KEYB.ASM', 'KEYBI9.ASM', 'KEYBI9C.ASM', 'KEYBI2F.ASM',
                 'KEYBI48.ASM', 'KEYBCPSD.ASM', 'COMMSUBS.ASM',
                 'KEYBTBBL.ASM', 'PARSER.ASM', 'KEYBCMD.ASM',
                 'KEYBEQU.INC', 'KEYBSHAR.INC', 'KEYBSYS.INC',
                 'KEYBDCL.INC', 'KEYBMAC.INC',
                 'KEYBCMD.INC', 'KEYBTBBL.INC', 'COMMSUBS.INC',
                 'KEYBCPSD.INC', 'KEYBI2F.INC', 'KEYBI9.INC',
                 'KEYBI9C.INC', 'KEYBI48.INC'),
        TAG={},
        ONESEG=True,
        # DATA is what INC/DSEG.INC calls the ROM BIOS's data area at 40H,
        # which KEYB loads a register with to reach the keyboard flags, and
        # it is one of fasm's own words; the header calls it DATA_ and the
        # modules are given the same spelling.  K5, K6 and K7 are three of
        # KEYBI9C's translation tables, and fasm keeps K0 to K7 for the
        # mask registers of a processor thirty years off.
        RESERVED=('DATA', 'K5', 'K6', 'K7'),
        # Nine names two modules each have one of, which MASM let them have
        # because it assembled them apart: a way out called EXIT in the two
        # interrupt 9 modules, the five shift-state labels SD0 to SD4 in
        # KEYBI9C and COMMSUBS, a KEYB_INSTALLED word in KEYBTBBL and
        # another in KEYBCMD, a RESTORE_BP in KEYBI2F and another in
        # KEYBTBBL, and PARSER's FILE_NAME label against KEYBCMD's 128-byte
        # buffer of that name.  None is PUBLIC and none is EXTRN'd, so each
        # takes the name of the module it is in.
        #
        # The fourteen equates two modules both declare are left alone:
        # every one of them is given the same value in both -- PARSER and
        # KEYBCMD share the parser's result codes -- and each module
        # declares it before it reads it, which is the one thing that
        # matters when the modules are read in order.
        LOCALS=('EXIT', 'SD0', 'SD1', 'SD2', 'SD3', 'SD4', 'KEYB_INSTALLED',
                'RESTORE_BP', 'FILE_NAME'),
        # The size of the buffer the keyboard definition file is read into.
        # KEYBCMD declares it beside the buffer, which is the last module
        # the walk reads; KEYBCMD.INC, which the eight before it read, is
        # where the buffer is EXTRN'd and the size is first asked for.
        # MASM resolved the name on its second pass, and fasm wants a
        # number it can resolve wherever it stands rather than an EQU it
        # has not read yet.
        FORWARD=('FILE_BUFFER_SIZE',),
        # DSEG.INC is the ROM BIOS's data segment at 40H and POSTEQU.INC
        # the equates for what it holds, which the interrupt 9 handler
        # reads the shift states out of.
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM',
                'DEVSYM.INC', 'STRUC.INC', 'DSEG.INC', 'POSTEQU.INC'),
        # Every module says ASSUME CS:CODE, and KEYB.ASM DS:CODE with it:
        # the resident handlers are entered on an interrupt, with the
        # interrupted program's DS, so what they read of their own they
        # read through CS until the code says otherwise.
        START={'cs': 'CODE', 'ds': None, 'es': None, 'ss': None},
    ),
    # GRAPHICS's thirteen modules in the order GRAPHICS.LNK names them, and
    # the seventeen headers of its own they read: a .EXT of EXTRNs for each
    # module, a .STR of structures for the three that have any, and
    # GRMSG.EQU for the message numbers.  One segment, CODE, and no group,
    # so the modules are read once -- the shape KEYB and GRAFTABL have.
    # CODE begins where the load module does and GRAPHICS.ASM's org 100H is
    # where DOS enters; the release links the thirteen and runs EXE2BIN.
    #
    # GRCOMMON.ASM is the fourteenth and is not linked: the two printer
    # modules each INCLUDE it at the end of their own code, so the program
    # carries two copies of it and MASM gave each module the one in it.
    # GRAPHLNK.ASM reads each copy under names of its own; see the note
    # there.  GRCOMMON.EXT and GRPRINT.EXT are read by nothing at all.
    'GRAPHICS': dict(
        MODULES=('GRAPHICS.ASM', 'GRINT2FH.ASM', 'GRPATTRN.ASM',
                 'GRCTRL.ASM', 'GRCPSD.ASM', 'GRCOLPRT.ASM', 'GRBWPRT.ASM',
                 'GRINST.ASM', 'GRPARSE.ASM', 'GRPARMS.ASM', 'GRLOAD.ASM',
                 'GRLOAD2.ASM', 'GRLOAD3.ASM', 'GRCOMMON.ASM',
                 'GRBWPRT.EXT', 'GRCOLPRT.EXT', 'GRCPSD.EXT', 'GRCTRL.EXT',
                 'GRCTRL.STR', 'GRINST.EXT', 'GRINT2FH.EXT', 'GRLOAD.EXT',
                 'GRLOAD2.EXT', 'GRLOAD3.EXT', 'GRMSG.EQU', 'GRPARMS.EXT',
                 'GRPARSE.EXT', 'GRPATTRN.EXT', 'GRPATTRN.STR',
                 'GRSHAR.STR'),
        TAG={},
        ONESEG=True,
        # Four names GRLOAD2 and GRLOAD3 each have one of, and a SUBLIST in
        # GRLOAD and another in GRPARMS; none is PUBLIC and none is EXTRN'd,
        # so each takes the name of the module it is in.  That settles
        # SUBLIST against the structure of that name in INC/MSGHAN.INC as
        # well.  YES and NO, which four modules declare apiece, are left
        # alone: all four say YES EQU 1 and NO EQU 0.
        LOCALS=('RESULT_BUFFER', 'RESULT_TAG', 'RESULT_VAL', 'SUBLIST'),
        # LIMIT is the end of what the program lays down, which GRINST asks
        # for to build its tables past it.  GRLOAD3 declares it and makes
        # it PUBLIC, GRLOAD3.EXT is where GRINST reads it, and GRLOAD2 has
        # one of its own as well -- so this is not a name each module keeps
        # to itself and LOCALS would take the public one with it.  GRLOAD2's
        # is the one that gives way.
        PRIVATE={'GRLOAD2.ASM': (('LIMIT', 'LIMIT_'),)},
        # Five EQUs the walk meets before the line that declares them.
        # Three are a module reading its own further down -- GRINT2FH's
        # multiplex number, GRLOAD's carriage return, GRLOAD3's count of
        # colour bands -- and two are the lengths of the printer modules,
        # which each module declares at its end and its own .EXT asks for
        # at its head.  MASM resolved them on its second pass, and fasm
        # wants a number it can resolve wherever it stands rather than an
        # EQU it has not read yet.
        FORWARD=('PRT_SCR_2FH_NUMBER', 'LEN_OF_BW_MODULES',
                 'LEN_OF_COLOR_MODULES', 'CARRIAGE_RET', 'MAX_BANDS'),
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM',
                'DEVSYM.INC', 'STRUC.INC', 'COPYRIGH.INC'),
        # Every module says ASSUME CS:CODE,DS:CODE at its head, which is
        # what the transient runs with; where a routine is entered on an
        # interrupt instead the modules say so themselves.
        START={'cs': 'CODE', 'ds': 'CODE', 'es': None, 'ss': None},
        # GRCOMMON.ASM has no ASSUME of its own because it is never
        # assembled on its own: each printer module INCLUDEs it at the end
        # of its own code, where that module's ASSUME CS:CODE,DS:CODE
        # stands.  Converted as a module it would start on CS alone and
        # every one of its sixty-seven references would be given the CS
        # override MASM did not write.
        STARTS={'GRCOMMON.ASM': {'cs': 'CODE', 'ds': 'CODE',
                                 'es': None, 'ss': None}},
    ),
    # SHARE's four modules in the order SHARE.LNK names them, and the one
    # header of its own all three of the sharer's modules read -- SHAREHDR
    # is the specification block and nothing else.  SHARE.LNK names four
    # more after them, out of src/INC: nibdos, const2, msdata and msdosme,
    # four of the kernel's own modules, which the link file reads with
    # these and which are converted already.
    #
    # Eight segments and three address spaces.  Share, which holds the
    # whole of the sharer, is outside the group; DOSGROUP is the kernel's
    # six -- START, CONSTANTS, DATA, TABLE, CODE, LAST -- which the four
    # kernel modules fill as they fill the kernel's, and SHARELNK fills
    # CODE with a stub for each of the forty-four kernel names the sharer's
    # own modules name and the kernel's do not define; STACK is the third.
    # So the walk is the kernel's, over eight modules and eight passes.
    #
    # The sharer runs inside the kernel, entered through the jump table
    # MSCONST.ASM lays down in CONSTANTS, with the kernel's own SS -- which
    # is why the release linked the kernel's data modules in and why every
    # routine here says ASSUME SS:DOSGROUP.  What the sharer reads of the
    # kernel's it reads through SS at the offset this assembly gives it, so
    # the copy of DOSGROUP in SHARE.EXE is there for its offsets and not
    # for its bytes: nothing in it is ever read at run time.
    'SHARE': dict(
        MODULES=('GSHARE.ASM', 'GSHARE2.ASM', 'SHARESR.ASM', 'SHARELNK.ASM',
                 'SHAREHDR.INC'),
        # GSHARE and GSHARE2 are the two halves of one program and the
        # structured-assembly preprocessor numbered each from one, so eight
        # of the labels it wrote are in both.
        TAG={'GSHARE2.ASM': '2'},
        # MFT.INC is the Master File Table, which is what the sharer keeps:
        # a heap of name records at one end of its pool and a chain of lock
        # records at the other.  DPL.ASM is the server call parameter list,
        # which the sharer is handed on a call from the network redirector,
        # and DOSSEG.ASM is the kernel's segment order, which every one of
        # these modules reads to get the six segment declarations.
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM',
                'DEVSYM.INC', 'MFT.INC', 'DPL.ASM', 'DOSSEG.ASM',
                # The kernel's own modules, which the link file reads with
                # SHARE's: the four SHARE.LNK names, and the five files
                # they read between them.  Nothing here is a header the
                # sharer's modules include -- they EXTRN what they want of
                # it -- but the declarations are what say how a name is
                # spelt and how wide it is, and an EXTRN says neither.
                # Without them the sharer's own spelling of a name it did
                # not declare is the one that is written, which is how
                # WFP_Start came out of a module that EXTRNs WFP_START and
                # MS_DATA.ASM declares as WFP_START.  They are in the
                # order the linker read them, so where two of them have a
                # name the first is the one that gives the spelling.
                'NIBDOS.ASM', '../DOS/MSSW.ASM', '../DOS/MSCONST.ASM',
                'CONST2.ASM', 'MSDATA.ASM', 'MS_DATA.ASM',
                '../DOS/MSINIT.ASM', 'MSDOSME.ASM', '../DOS/DOSMES.ASM'),
        # GSHARE2's own interrupt 2FH handler, which it hooks so that a
        # second copy of SHARE finds the first, against the stub of that
        # name SHARELNK lays down for the kernel modules that call the
        # kernel's.  MASM assembled the two apart and only SHARELNK's is
        # PUBLIC, so the handler is the one that gives way.
        PRIVATE={'GSHARE2.ASM': (('INT2F', 'INT2F_'),)},
        # Four EQUs GSHARE2 reads above the line that declares them.
        # Three are message numbers, which SHARE's own block of them
        # declares at the end of the module where the parse table and the
        # routines that print them stand well above it, and the fourth says
        # a parser switch takes a file name.  MASM resolved them on its
        # second pass, and fasm wants a number it can resolve wherever it
        # stands rather than an EQU it has not read yet.
        FORWARD=('Bad_DOS_Ver', 'FILE_SWITCH', 'No_Mem_Error',
                 'Sh_Already_Loaded'),
        # Four of the fourteen routines the kernel reaches the sharer
        # through, in the spelling the jump table's entries are pasted
        # together from.  GSHARE2 declares each entry in an IRP block, as a
        # J and the name of the routine it calls -- "J&rtn proc far" -- and
        # the table below it is fourteen DDs of those names written out.
        # MASM read a name in any case, so the paste and the DD met
        # whatever case either was in; fasm pastes the letters as they
        # stand, so the name has to be spelt the one way in both.  The
        # table's spelling is the one that is kept, the other ten names
        # being in it already, and the declarations take it with them.
        #
        # And sixteen of SHARELNK's stubs, in the spelling the kernel's own
        # modules read them at.  SHARELNK writes most of its forty-four
        # names in capitals where the module that reaches one writes it in
        # mixed case -- BADCALL against MSCONST's BadCall, SYSINITTABLE
        # against MSINIT's SysInitTable, Swap_in_DOS_Len against its
        # SWAP_IN_DOS_LEN -- and MASM read the two as one name.  The
        # kernel's modules are converted already and are read as they
        # stand, so theirs is the spelling that is kept here.
        SPELLING={'mft_enter': 'MFT_Enter', 'mftclose': 'MFTClose',
                  'clr_mult_block': 'Clr_Mult_Block',
                  'mft_get': 'MFT_Get',
                  'backsp': 'BackSp', 'badcall': 'BadCall',
                  'copystr': 'CopyStr', 'fastopentable': 'FastOpenTable',
                  'header': 'Header', 'okcall': 'OKCall',
                  'packet_temp': 'Packet_Temp',
                  'stay_resident': 'Stay_resident',
                  'sysinittable': 'SysInitTable', 'twoesc': 'TwoEsc',
                  'dup_pdb$': 'Dup_PDB$',
                  'swap_in_dos': 'SWAP_IN_DOS',
                  'swap_in_dos_len': 'SWAP_IN_DOS_LEN',
                  'swap_always_area': 'SWAP_ALWAYS_AREA',
                  'swap_always_area_len': 'SWAP_ALWAYS_AREA_LEN',
                  # the four critical sections CONST2's CritPatch table
                  # names, which it pastes out of the section's own name:
                  # the sharer patches each of these addresses to a PUSH AX
                  # when it installs itself
                  'ecritdisk': 'EcritDisk', 'lcritdisk': 'LcritDisk',
                  'ecritdevice': 'EcritDevice',
                  'lcritdevice': 'LcritDevice'},
        # Every routine in the Share segment says ASSUME SS:DOSGROUP,
        # CS:SHARE at the head of the module: the sharer is called from
        # inside the kernel, which has its own data segment on SS, and
        # reads nothing through DS or ES until it says so itself.
        START={'cs': 'SHARE', 'ds': None, 'es': None, 'ss': 'DOSGROUP'},
        # SHARESR is the parser and the message retriever, which run before
        # the sharer is installed and so on SHARE's own stack, and
        # SHARELNK's stubs stand in the kernel's code segment.  Each says
        # as much at its head and neither names SS.
        STARTS={'SHARESR.ASM': {'cs': 'SHARE', 'ds': None,
                                'es': None, 'ss': None},
                'SHARELNK.ASM': {'cs': 'DOSGROUP', 'ds': None,
                                 'es': None, 'ss': None}},
        # Five places where a conditional on Installed stands round a
        # segment directive, which cannot be left to the assembler: a
        # segment is a pass of the walk here, and the IF that chooses one
        # would be read inside the guard the segment opens rather than
        # round it.  Installed is TRUE and SHARE.EXE is the only thing
        # these modules are ever assembled as -- the other way round they
        # are part of the kernel's own code segment, which is how the
        # sharer was built before it was a program -- so the dead branch
        # goes and the live one is left as the release wrote it.
        # Six places where a conditional on Installed stands round a
        # segment directive, and the two macros each half declares for
        # itself.  A conditional round a segment cannot be left to the
        # assembler: a
        # segment is a pass of the walk here, and the IF that chooses one
        # would be read inside the guard the segment opens rather than
        # round it.  Installed is TRUE and SHARE.EXE is the only thing
        # these modules are ever assembled as -- the other way round they
        # are part of the kernel's own code segment, which is how the
        # sharer was built before it was a program -- so the dead branch
        # goes and the live one is left as the release wrote it.
        EARLY={'GSHARE.ASM': [
            ("\tIF\tNOT INSTALLED\n"
             "CODE\t    SEGMENT BYTE PUBLIC 'CODE'\n"
             "\t    ASSUME  SS:DOSGROUP,CS:DOSGROUP\n"
             "\tELSE\n",
             ";\tIF\tNOT INSTALLED\n"
             ";CODE\t    SEGMENT BYTE PUBLIC 'CODE'\n"
             ";\t    ASSUME  SS:DOSGROUP,CS:DOSGROUP\n"
             ";\tELSE\n"),
            ("\t    ASSUME  SS:DOSGROUP,CS:SHARE\n\tENDIF\n",
             "\t    ASSUME  SS:DOSGROUP,CS:SHARE\n;\tENDIF\n"),
            # The two macros each of the sharer's halves declares for
            # itself.  OFF loads a register with a name's offset, which is
            # the name itself where the sharer is a segment of its own and
            # the group with the name after it where it is part of the
            # kernel's code.  It is written in fasm's shape, the body left
            # as the release wrote it; the eleven calls spell it Off and
            # off, which the rules bring to the one spelling as they bring
            # any other reference to its declaration's.  ERRNZ is
            # INC/DOSMAC.INC's own macro of that name written again, with a
            # %OUT where DOSMAC stops the assembly: it goes, and the four
            # calls are DOSMAC's, which answers to that spelling as of this
            # release.
            ("OFF\t\t\t\t   Macro reg,val\n"
             "\t\t\t\t   IF\tinstalled\n"
             "\t\t\t\t   mov\treg,OFFSET val\n"
             "\t\t\t\t   ELSE\n"
             "\t\t\t\t   mov\tsi,OFFSET DOSGROUP:val\n"
             "\t\t\t\t   ENDIF\n"
             "\t\t\t\t   ENDM\n",
             ";OFF\t\t\t\t   Macro reg,val\n"
             "\t\t\t\t   macro OFF reg,val\n"
             "\t\t\t\t   {\n"
             "\t\t\t\t   IF\tinstalled\n"
             "\t\t\t\t   mov\treg,OFFSET val\n"
             "\t\t\t\t   ELSE\n"
             "\t\t\t\t   mov\tsi,OFFSET DOSGROUP:val\n"
             "\t\t\t\t   ENDIF\n"
             "\t\t\t\t   }\n"),
            ("ERRNZ\t\t\t\t   Macro x\n"
             "\t\t\t\t   IF\tx NE 0\n"
             "\t\t\t\t   %out ERRNZ failed\n"
             "\t\t\t\t   ENDIF\n"
             "\t\t\t\t   ENDM\n",
             ";ERRNZ\t\t\t\t   Macro x\n"
             ";\t\t\t\t   IF\tx NE 0\n"
             ";\t\t\t\t   %out ERRNZ failed\n"
             ";\t\t\t\t   ENDIF\n"
             ";\t\t\t\t   ENDM\n"),],
               'GSHARE2.ASM': [
            ("\tIF\tNOT\tINSTALLED\n\n"
             "\t    CODE    SEGMENT BYTE PUBLIC 'CODE'\n\n"
             "\t    ASSUME  SS:DOSGROUP,CS:DOSGROUP\n\n"
             "\tELSE\n",
             ";\tIF\tNOT\tINSTALLED\n\n"
             ";\t    CODE    SEGMENT BYTE PUBLIC 'CODE'\n\n"
             ";\t    ASSUME  SS:DOSGROUP,CS:DOSGROUP\n\n"
             ";\tELSE\n"),
            ("\t    ASSUME  SS:DOSGROUP,CS:SHARE\n\n\tENDIF\n",
             "\t    ASSUME  SS:DOSGROUP,CS:SHARE\n\n;\tENDIF\n"),
            # The lock records the kernel's own copy of the sharer kept in
            # its code segment, and the ENDS that closed it.  The whole
            # block is the not-installed half and lays nothing down here.
            ("\n       CODE ENDS\n", "\n;      CODE ENDS\n"),
            # The IF round everything from the pool to the end of the
            # program, whose ENDIF stands after the stack segment: left in,
            # the ENDS that closes the sharer's own segment would close
            # this instead and the stack would be laid down inside a guard
            # that is never true.
            ("\nIF Installed\n\n"
             "   ASSUME CS:SHARE,DS:NOTHING,ES:NOTHING,SS:NOTHING\n",
             "\n;IF Installed\n\n"
             "   ASSUME CS:SHARE,DS:NOTHING,ES:NOTHING,SS:NOTHING\n"),
            ("   STACK ENDS\n\nENDIF\n", "   STACK ENDS\n\n;ENDIF\n"),
            # The same two, declared again in this half.
            ("OFF\t\t\t\t   Macro reg,val\n"
             "\t\t\t\t   IF\tinstalled\n"
             "\t\t\t\t   mov\treg,OFFSET val\n"
             "\t\t\t\t   ELSE\n"
             "\t\t\t\t   mov\tsi,OFFSET DOSGROUP:val\n"
             "\t\t\t\t   ENDIF\n"
             "\t\t\t\t   ENDM\n",
             ";OFF\t\t\t\t   Macro reg,val\n"
             "\t\t\t\t   macro OFF reg,val\n"
             "\t\t\t\t   {\n"
             "\t\t\t\t   IF\tinstalled\n"
             "\t\t\t\t   mov\treg,OFFSET val\n"
             "\t\t\t\t   ELSE\n"
             "\t\t\t\t   mov\tsi,OFFSET DOSGROUP:val\n"
             "\t\t\t\t   ENDIF\n"
             "\t\t\t\t   }\n"),
            ("ERRNZ\t\t\t\t   Macro x\n"
             "\t\t\t\t   IF\tx    NE 0\n"
             "\t\t\t\t   %out ERRNZ failed\n"
             "\t\t\t\t   ENDIF\n"
             "\t\t\t\t   ENDM\n",
             ";ERRNZ\t\t\t\t   Macro x\n"
             ";\t\t\t\t   IF\tx    NE 0\n"
             ";\t\t\t\t   %out ERRNZ failed\n"
             ";\t\t\t\t   ENDIF\n"
             ";\t\t\t\t   ENDM\n"),]},
        PATCHES={'GSHARE2.ASM': [
            # Four reads of a sharing local FCB, whose width MASM took
            # from the register on the other side.  INC/CPMFCB.INC lays the
            # four fields out past the end of the FCB structure, as numbers
            # measured from the reserved bytes -- fcb_l_mfs EQU
            # (sys_fcb.fcb_reserved+4) -- and MASM read an EQU of an
            # expression as a number with no type at all.  fasm keeps the
            # width the field was declared with, which is a byte, so each
            # of these came out a byte against a word register.  The width
            # is said on the line, as the kernel's own reads of the same
            # fields say it.
            ("   CMP\tBX,[SI].fcb_l_mfs\n",
             "   CMP\tBX,WORD PTR [SI].fcb_l_mfs\n"),
            ("   MOV\tBX,[SI].fcb_l_firclus\n",
             "   MOV\tBX,WORD PTR [SI].fcb_l_firclus\n"),
            ("   MOV\t[SI].FCB_l_firclus,AX\n",
             "   MOV\tWORD PTR [SI].FCB_l_firclus,AX\n"),
            ("   MOV\t[SI].FCB_l_mfs,BX\n",
             "   MOV\tWORD PTR [SI].FCB_l_mfs,BX\n"),
            # A RestoreReg with nothing to restore, standing two lines
            # above the one that restores the seven registers CPS saved.
            # MASM read the < as the start of a literal and took the rest
            # of the line for it, which was nothing, so the macro's IRP ran
            # over an empty list and the line laid down not a byte.  fasm
            # reads the arguments and finds the bracket unclosed.
            ("   RestoreReg <\n", ";   RestoreReg <\n"),
            # The room the sharer's pool has, which is the larger of the
            # 2048 bytes it asks for and whatever is left between the table
            # and the initialisation code that is thrown away -- MASM could
            # not measure that on its first pass, so the IF1 gave it the
            # 2048 and the second pass worked it out.  fasm resolves the
            # span wherever it stands, so the first pass's answer goes and
            # the second pass's is the one that is left.
            ('   IF1\nInitSpace DW PoolSize\n   ELSE\n',
             ';   IF1\n;InitSpace DW PoolSize\n;   ELSE\n'),
            ('       ENDIF\n   ENDIF\nInitLocks DW 20\n',
             '       ENDIF\n;   ENDIF\nInitLocks DW 20\n')]},
    ),
    # IFSFUNC's ten modules in the order IFSFUNC.LNK names them, and the two
    # headers of its own they read.  IFSFUNC.LNK names seven more after
    # them, out of src/INC and src/DOS: NIBDOS, CONST2, MSDATA, MSTABLE,
    # MSDISP, MSCODE and MSDOSME, seven of the kernel's own modules, which
    # the link file reads with these and which are converted already.
    # IFSFLINK goes last and is a stub for each of the hundred and
    # seventy-four kernel names the installable file system calls and those
    # seven modules do not define.
    #
    # Nine segments and three address spaces, the shape SHARE has: IFSSEG
    # holds the whole of the file system and is outside the group, DOSGROUP
    # is the kernel's six, and STACK is the third.  IFSSESS declares all
    # eight -- it cannot read DOSSEG.ASM for them, as the comment there
    # says, because START has to be PARA aligned here -- and none of the
    # declarations stands inside a conditional, so unlike SHARE there is
    # nothing for EARLY to do.
    #
    # Not one line of it came through the structured-assembly preprocessor:
    # there is no $$ label in any of the twelve files and so no TAG.
    #
    # The release links the seventeen and runs LINK's /EXEPACK over the
    # result, which is what the /EX on IFSFUNC.LNK's last line asks for.
    # Nothing here packs an .EXE and nothing needs to: DOS unpacks one as
    # it loads it, and an unpacked image is the same program.
    'IFSFUNC': dict(
        MODULES=('IFSSESS.ASM', 'IFSDIR.ASM', 'IFSFILE.ASM', 'IFSHAND.ASM',
                 'IFSDEV.ASM', 'IFSUTIL.ASM', 'IFSERROR.ASM', 'IFSFDOS.ASM',
                 'IFSINIT.ASM', 'IFSFLINK.ASM',
                 'IFSFSYM.INC', 'IFSPARSE.INC'),
        TAG={},
        # Five names IFSFUNC keeps of its own that one of the kernel modules
        # it links also has.  ErrMap24 and ErrMap24End are the table that
        # maps a DOS error to an interrupt 24H one: IFSERROR declares a pair
        # for the file system and IFSUTIL reads them, and MS_TABLE.ASM has
        # the kernel's pair with the PUBLIC commented out, so MASM saw two
        # local names and one assembly sees one.  FOO, INT2F and Leave2F are
        # IFSINIT's own interrupt 2FH handler and the word it dispatches
        # through, which are the same three names MS_CODE.ASM and
        # MS_TABLE.ASM give the kernel's.  None of the five is EXTRN'd
        # across the two, so the file system's take the underscore.
        RESERVED=('ErrMap24', 'ErrMap24End', 'FOO', 'INT2F', 'Leave2F'),
        # IFSSYM.INC is the installable file system interface, which the
        # kernel reads as well; DOSCNTRY.INC the country and code page
        # tables, EA.INC the extended attribute calls, FASTOPEN.INC and
        # FASTXXXX.INC the caches MSINIT and MS_TABLE name.
        #
        # After them the kernel's own modules, in the order the linker read
        # them, and the files they read between them.  As with SHARE, they
        # are here so that the converter can see how a name the file system
        # only EXTRNs is spelt and how wide it is -- and with a hundred and
        # seventy-four stubs there is a great deal of that.
        SHARED=('SYSCALL.INC', 'DOSSYM.INC', 'SYSMSG.INC', 'PSDATA.INC',
                'MSGHAN.INC', 'DOSMAC.INC', 'MSGDCL.INC', 'MSGSERV.ASM',
                'VERSIONA.INC', 'BPB.INC', 'BUFFER.INC', 'SYSVAR.INC',
                'VECTOR.INC', 'MULT.INC', 'DIRENT.INC', 'DPB.INC',
                'CURDIR.INC', 'CPMFCB.INC', 'FIND.INC', 'PDB.INC', 'EXE.INC',
                'SF.INC', 'ARENA.INC', 'INTNAT.INC', 'MI.INC',
                'FILEMODE.INC', 'ERROR.INC', 'VERSION.INC', 'PARSE.ASM',
                'DEVSYM.INC', 'IFSSYM.INC', 'DOSSEG.ASM', 'BUGTYP.ASM',
                'DOSCNTRY.INC', 'COPYRIGH.INC', 'EA.INC', 'FASTOPEN.INC',
                'FASTXXXX.INC',
                'NIBDOS.ASM', '../DOS/MSSW.ASM', '../DOS/MSCONST.ASM',
                'MSHEAD.ASM', 'CONST2.ASM', 'MSDATA.ASM', 'MS_DATA.ASM',
                '../DOS/MSINIT.ASM', 'MSTABLE.ASM', '../DOS/MS_TABLE.ASM',
                '../DOS/MSDISP.ASM', '../DOS/DISP.ASM', '../DOS/MSCODE.ASM',
                '../DOS/MS_CODE.ASM', 'MSDOSME.ASM', '../DOS/DOSMES.ASM',
                'DIVMES.ASM', 'YESNO.ASM'),
        # Sixty-four of IFSFLINK's stubs, in the spelling the kernel's own
        # modules read them at: it writes most of its hundred and
        # seventy-four names in capitals where the module that reaches one
        # writes it in mixed case -- TABLEDISPATCH against MS_CODE's
        # TableDispatch, STRCPY against its StrCpy -- and MASM read the two
        # as one name.  The kernel's files are converted already and are
        # read as they stand, so theirs is the spelling that is kept.
        # SKIPONE is not among them: DOSMES writes it both ways and the one
        # that is reached is the capitals, which is what IFSFLINK writes.
        SPELLING={'allocoper$': 'AllocOper$', 'assignoper$': 'AssignOper$',
                  'backsp': 'BackSp', 'bufwrite': 'BufWrite',
                  'close$': 'Close$', 'commit$': 'Commit$',
                  'copystr': 'CopyStr', 'creat$': 'Creat$',
                  'createnewfile$': 'CreateNewFile$',
                  'createtempfile$': 'CreateTempFile$',
                  'drivefromtext': 'DriveFromText', 'dskread': 'DskRead',
                  'dstrlen': 'DStrLen', 'dup2$': 'Dup2$',
                  'dup_pdb$': 'Dup_PDB$', 'ecs_call$': 'ECS_call$',
                  'exec$': 'Exec$', 'extended_open$': 'Extended_Open$',
                  'exthandle$': 'ExtHandle$', 'fake_version': 'Fake_version',
                  'fast_dispatch': 'Fast_Dispatch', 'fastinit': 'FastInit',
                  'fastret': 'FastRet', 'fcb_close$': 'FCB_Close$',
                  'fcb_create$': 'FCB_Create$', 'fcb_delete$': 'FCB_Delete$',
                  'fcb_open$': 'FCB_Open$',
                  'fcb_random_read$': 'FCB_Random_Read$',
                  'fcb_random_read_block$': 'FCB_Random_Read_Block$',
                  'fcb_random_write$': 'FCB_Random_Write$',
                  'fcb_random_write_block$': 'FCB_Random_Write_Block$',
                  'fcb_rename$': 'FCB_Rename$',
                  'fcb_seq_read$': 'FCB_Seq_Read$',
                  'fcb_seq_write$': 'FCB_Seq_Write$',
                  'file_times$': 'File_Times$',
                  'get_fcb_file_length$': 'Get_FCB_File_Length$',
                  'get_fcb_position$': 'Get_FCB_Position$',
                  'getcdsfromdrv': 'GetCDSFromDrv', 'getdevlist': 'GetDevList',
                  'getextcntry$': 'GetExtCntry$',
                  'getextendederror$': 'GetExtendedError$',
                  'getsetcdpg$': 'GetSetCdPg$', 'getthisdrv': 'GetThisDrv',
                  'gsetmediaid$': 'GSetMediaID$', 'idle': 'Idle',
                  'initcds': 'InitCDS', 'intcne0': 'intCNE0',
                  'keep_process$': 'Keep_process$', 'lockoper$': 'LockOper$',
                  'nametrans$': 'NameTrans$', 'open$': 'Open$',
                  'pjfnfromhandle': 'pJFNFromHandle', 'pointcomp': 'PointComp',
                  'scanplace': 'ScanPlace', 'servercall$': 'ServerCall$',
                  'sffromsfn': 'SFFromSFN', 'stay_resident': 'Stay_resident',
                  'strcmp': 'StrCmp', 'strcpy': 'StrCpy', 'strlen': 'StrLen',
                  'tabledispatch': 'TableDispatch', 'twoesc': 'TwoEsc',
                  'ucase': 'uCase', 'useroper$': 'UserOper$',
                  # the four critical sections CONST2's CritPatch table
                  # names, which it pastes out of the section's own name
                  'ecritdisk': 'EcritDisk', 'lcritdisk': 'LcritDisk',
                  'ecritdevice': 'EcritDevice',
                  'lcritdevice': 'LcritDevice'},
        # The one page heading in the tree whose text ends in a backslash.
        # BREAK writes nothing either way, but fasm reads a backslash as
        # the mark that a line goes on, so it took the next line with it
        # and then complained about what was left.  The heading goes out
        # commented, which is what BREAK comes to.
        # The three references to IFSR_MODE that have no register to take a
        # width from.  The macros make it a word for an open and a byte for
        # an lseek, so there is no one width for the table above to hold:
        # IFSHAND's is the lseek, and IFSFILE's two are the open.
        PATCHES={'IFSHAND.ASM': [
            ("\tMOV\tES:[BX.IFSR_MODE],MODE2",
             "\tMOV\tBYTE PTR ES:[BX.IFSR_MODE],MODE2")],
                 'IFSFILE.ASM': [
            ("        MOV     ES:[BX.IFSR_MODE],OLDCREATE_MODE",
             "        MOV     WORD PTR ES:[BX.IFSR_MODE],OLDCREATE_MODE"),
            ("        POP     ES:[BX.IFSR_MODE]",
             "        POP     WORD PTR ES:[BX.IFSR_MODE]")],
                 'IFSUTIL.ASM': [
            ("Break\t<STRIP_WFP_START - strip leading d:\\ >",
             ";Break\t<STRIP_WFP_START - strip leading d:\\ >")]},
        # The widths of the fifty-five names IFSSYM.INC's two request
        # macros make.  MASM wrote each with a type in front of it -- BYTE
        # PTR, WORD PTR, DWORD PTR -- and read a reference through the name
        # at that width; what the macro leaves here is the offset alone, so
        # the width is said here instead.  IFSR_MODE is not among them: the
        # macros give it two types, a word for an open and a byte for an
        # lseek, and both are read -- so its three lines that have nothing
        # else to take a width from say it themselves, below.
        ABSWIDTH={'IFSR_ACTION': 'word', 'IFSR_ALLOCSIZE': 'word',
                  'IFSR_ALLOCUNITS': 'word', 'IFSR_ALLOWED': 'byte',
                  'IFSR_APIFUNC': 'byte', 'IFSR_API_PARMS': 'byte',
                  'IFSR_ATTR': 'word', 'IFSR_AVAILALLOC': 'word',
                  'IFSR_BUFFER1@': 'dword', 'IFSR_BUFFER2@': 'dword',
                  'IFSR_BUFFER@': 'dword', 'IFSR_BUFSIZE': 'word',
                  'IFSR_CATEGORY': 'byte', 'IFSR_CB@': 'dword',
                  'IFSR_CONTINFO@': 'dword', 'IFSR_COUNT': 'word',
                  'IFSR_CP': 'word', 'IFSR_CPSW': 'byte',
                  'IFSR_CTLFUNC': 'byte', 'IFSR_DATE': 'word',
                  'IFSR_DEVICE_CB@': 'dword', 'IFSR_DEVICE_STATUS': 'byte',
                  'IFSR_ERROR_ACTION': 'byte', 'IFSR_ERROR_CLASS': 'byte',
                  'IFSR_ERROR_LOCUS': 'byte', 'IFSR_FLAG': 'word',
                  'IFSR_FSID': 'byte', 'IFSR_FUNC': 'byte',
                  'IFSR_I24_COUNT': 'byte', 'IFSR_I24_RESP': 'byte',
                  'IFSR_LK_LENGTH': 'dword', 'IFSR_LK_POSITION': 'dword',
                  'IFSR_LSN': 'word', 'IFSR_MATCHATTR': 'word',
                  'IFSR_MATCHATTR_47': 'word', 'IFSR_MAX_XMITT_SIZE': 'word',
                  'IFSR_MSG@': 'dword',
                  'IFSR_MSG_TYPE': 'byte', 'IFSR_NAME1@': 'dword',
                  'IFSR_NAME2@': 'dword', 'IFSR_NAME@': 'dword',
                  'IFSR_NET_NAME_ID': 'word', 'IFSR_OPEN_CB@': 'dword',
                  'IFSR_PARMS@': 'dword', 'IFSR_PID': 'word',
                  'IFSR_POSITION': 'dword', 'IFSR_RESSIZE': 'word',
                  'IFSR_SECTSIZE': 'word', 'IFSR_SIZE': 'dword',
                  'IFSR_SUBFUNC': 'byte', 'IFSR_TIME': 'word',
                  'IFSR_TYPE': 'byte', 'IFSR_UID': 'word',
                  'IFSR_USER_WORD': 'word'},
        # checkassume reports six references in IFSSESS that lost an
        # override, and they are the release's own doing rather than this
        # conversion's.  Each stands after a Context DS -- DOSMAC's macro
        # for PUSH SS/POP DS -- which leaves DS on DOSGROUP where the
        # ASSUME still says IFSSEG, so MASM wrote no override and the
        # reference goes to the kernel's data segment at the offset of a
        # name in IFSSEG.  The release writes CS: by hand on two of the
        # lines beside them, which is what the other six wanted.  They are
        # converted as MASM assembled them, which is this project's rule,
        # and so they are wrong here in the same way.
        # Every module says ASSUME SS:DOSGROUP,CS:IFSSEG at the head of
        # IFSSEG: the file system is called from inside the kernel, which
        # has its own data segment on SS, and reads nothing through DS or ES
        # until it says so itself.
        START={'cs': 'IFSSEG', 'ds': None, 'es': None, 'ss': 'DOSGROUP'},
        # IFSFLINK's stubs stand in the kernel's code segment and it says
        # ASSUME CS:dosgroup for them, naming no other register.
        STARTS={'IFSFLINK.ASM': {'cs': 'DOSGROUP', 'ds': None,
                                 'es': None, 'ss': None}},
    ),
    # DRIVER.SYS, the first of the drivers under src/DEV and the smallest of
    # them: one module in one segment, which the release linked on its own
    # and ran EXE2BIN over.  A driver is not a program -- DOS reads the
    # header at the front of the file, keeps the two addresses in it, and
    # keeps the driver as far as ENDCODE, which is where the initialisation
    # says the resident part stops -- so there is no prefix in front of it
    # and nothing to enter at, and the module's END names nobody.  What it reads of the kernel it reads through INT 2FH
    # multiplex 8, the BIOS's block driver answering, so it links nothing of
    # the kernel's and needs none of the kernel's headers: the message
    # retriever, the parser, and the BDS the BIOS keeps a drive in are all
    # of it.
    'DRIVER': dict(
        DIR='src/DEV/DRIVER',
        MODULES=('DRIVER.ASM',),
        ONESEG=True,
        SHARED=('SYSMSG.INC', 'VERSIONA.INC', 'MSGSERV.ASM', 'COPYRIGH.INC',
                'PARSE.ASM', 'PSDATA.INC', 'MSBDS.INC'),
        # The module says ASSUME CS:CODE,DS:CODE,ES:CODE at its head, and
        # names no stack: a driver is called on the caller's.
        START={'cs': 'CODE', 'ds': 'CODE', 'es': 'CODE', 'ss': None},
        # The five switch flags and the two message numbers are declared in
        # the last dozen lines of the module and read six hundred lines
        # above them: MASM resolved them on its second pass, and fasm wants
        # a number it can resolve wherever it stands rather than an EQU it
        # has not read yet.
        FORWARD=('flagdrive', 'flagcyln', 'flagseclim', 'flagheads',
                 'flagff', 'NODRIVE_MSG_NUM', 'LOADOK_MSG_NUM'),
    ),
    # ANSI.SYS, the console driver with the escape sequences in it: the four
    # modules ANSI.LNK names, in one segment and no group, and the two
    # headers they read.  ANSI.ASM is the driver proper -- the device header
    # for CON, the command table, and the sequence parser; IOCTL.ASM is the
    # generic IOCTL side, which is how MODE asks for a screen mode; ANSIINIT
    # is the initialisation and the video tables; PARSER reads the switches
    # the DEVICE= line carries.  The release links the four and runs EXE2BIN
    # over the result, as it does for DRIVER.
    'ANSI': dict(
        DIR='src/DEV/ANSI',
        MODULES=('ANSI.ASM', 'IOCTL.ASM', 'ANSIINIT.ASM', 'PARSER.ASM',
                 'ANSI.INC', 'ANSIVID.INC'),
        ONESEG=True,
        SHARED=('VECTOR.INC', 'MULT.INC', 'STRUC.INC', 'SYSMSG.INC',
                'VERSIONA.INC', 'MSGSERV.ASM', 'MSGDCL.INC', 'COPYRIGH.INC',
                'PARSE.ASM', 'PSDATA.INC'),
        # ANSI.ASM's own, which is the driver's: it is entered through the
        # kernel's call to a device driver, so what it reads of its own it
        # reads through CS until it says otherwise.  PARSER says CS:CODE and
        # nothing else.
        START={'cs': 'CODE', 'ds': None, 'es': None, 'ss': None},
        # IOCTL and ANSIINIT are both reached with DS on the driver already,
        # and say so at the head of the segment.
        STARTS={'IOCTL.ASM': {'cs': 'CODE', 'ds': 'CODE',
                              'es': None, 'ss': None},
                'ANSIINIT.ASM': {'cs': 'CODE', 'ds': 'CODE',
                                 'es': None, 'ss': None}},
        # Two of ANSI's own names are fasm's.  MATCH is the directive that
        # asks whether a name stands for the text after it, which is how
        # this conversion writes a conditional on a name; ANSI gives it to
        # the routine that has found the escape sequence it was reading.
        # ENTRY is where the loader is told to start, and ANSI gives it to
        # the second of the two addresses in the device header -- the
        # interrupt routine, which is where the kernel calls a driver with a
        # request.
        RESERVED=('MATCH', 'ENTRY'),
        # ANSI.INC declares INIT_REQ_HDR twice, with different fields: the
        # INIT request header at the top of the file and the generic IOCTL
        # one two hundred lines below it.  MASM made every field name a name
        # for its offset and nothing else, so what the second declaration
        # was called did not matter and both sets of offsets stood; here a
        # field belongs to the structure it is declared in, and a reference
        # names it.  So the second one is given the name the comment above
        # it gives it, and IOCTL.ASM's two references to MIN_FUNC and
        # REQ_PCKT_PTR come out as fields of that.
        # IOCTL.ASM line 711 has a note where a conjunction would stand,
        # written without a semicolon in front of it: MASM read the words as
        # arguments its .IF had no parameters for and dropped them, and the
        # line is "> 25 lines requested?" with the > become a gt.  There is
        # nothing to keep of it but the note, so it is made the comment it
        # was meant to be.
        EARLY={'IOCTL.ASM': [(
            "                  .IF <CS:REQ_TXT_LENGTH EQ DEFAULT_LENGTH>"
            " gt 25 lines requested?                 ;AN000;\n",
            "                  .IF <CS:REQ_TXT_LENGTH EQ DEFAULT_LENGTH>"
            "   ;gt 25 lines requested?             ;AN000;\n")],
               'ANSI.INC': [(
            "INIT_REQ_HDR    STRUC                   ;"
            "                                      ;AN000;\n"
            "                DB   13 DUP(?)          ; standard request"
            " header              ;AN000;\n"
            "MAJ_FUNC        DB   ?                  ; major function"
            "                       ;AN000;\n",
            "IOCTL_REQ_HDR   STRUC                   ;"
            "                                      ;AN000;\n"
            "                DB   13 DUP(?)          ; standard request"
            " header              ;AN000;\n"
            "MAJ_FUNC        DB   ?                  ; major function"
            "                       ;AN000;\n"),
            ("REQ_PCKT_PTR    DD   ?                  ; pointer to request"
             " packet            ;AN000;\n"
             "INIT_REQ_HDR    ENDS                    ;"
             "                                      ;AN000;\n",
             "REQ_PCKT_PTR    DD   ?                  ; pointer to request"
             " packet            ;AN000;\n"
             "IOCTL_REQ_HDR   ENDS                    ;"
             "                                      ;AN000;\n")]},
    ),
    # VDISK.SYS, the RAM disk: one module and the header it reads, which is
    # all VDISK.LNK links -- VDISK.ASM beside it is the same driver before
    # the message retriever took its text over, and nothing reads it.  Two
    # segments and no group: CSEG, which is the driver, and INT_VEC AT 0,
    # which names the two words of the INT 15H vector the driver hooks to
    # keep the extended memory it has taken.
    'VDISK': dict(
        DIR='src/DEV/VDISK',
        MODULES=('VDISKSYS.ASM', 'VDISKSYS.INC'),
        ONESEG=True,
        SHARED=('SYSMSG.INC', 'VERSIONA.INC', 'MSGSERV.ASM', 'COPYRIGH.INC',
                'PARSE.ASM', 'PSDATA.INC'),
        # The segment's own ASSUME, which says CS and nothing else: the
        # driver is entered through the two addresses in its header, with
        # the caller's DS, and says where DS is itself as it goes.
        START={'cs': 'CSEG', 'ds': None, 'es': None, 'ss': None},
        # INC/SYSMSG.INC gives FALSE and TRUE their values, in capitals,
        # and the one line of VDISK that lays a flag down with the first of
        # them spells it lower case -- one name to MASM.  The other five
        # uses are in capitals already.
        SPELLING={'false': 'FALSE'},
    ),
    # DISPLAY.SYS, the code page driver for the screen: the three modules
    # DISPLAY.LNK names and the eight headers they read between them.  One
    # segment and no group.  DISPLAY.ASM is the driver -- the device header,
    # the request dispatcher and the INT 2FH and INT 10H handlers it hooks
    # -- INIT.ASM the initialisation and the device tables, and PARSER.ASM
    # the switches the DEVICE= line carries, which say which adapter is
    # there and how many code pages to make room for.  DISPMES.ASM in the
    # same directory is the driver's text before the retriever took it over
    # and nothing links it.  The release links the three and runs EXE2BIN
    # over the result, as it does for the other drivers.
    'DISPLAY': dict(
        DIR='src/DEV/DISPLAY',
        MODULES=('DISPLAY.ASM', 'INIT.ASM', 'PARSER.ASM',
                 'MACROS.INC', 'DEF-EQU.INC', 'INT2FCOM.INC',
                 'INT10COM.INC', 'CPS-FUNC.INC', 'WRITE.INC',
                 'F-PARSER.INC', 'TABLES.INC'),
        ONESEG=True,
        SHARED=('SYSMSG.INC', 'VERSIONA.INC', 'MSGSERV.ASM', 'MSGDCL.INC',
                'COPYRIGH.INC', 'STRUC.INC', 'PARSE.ASM', 'PSDATA.INC'),
        # DISPLAY.ASM's and INIT.ASM's ASSUME, which both write at the head
        # of the segment: the driver keeps its data in its own segment and
        # reads it through DS, which it sets as it is entered.
        START={'cs': 'CODE', 'ds': 'CODE', 'es': None, 'ss': None},
        # PARSER says CS:CODE and nothing else where its segment opens,
        # and CS:CODE,DS:CODE two thirds of the way down it.
        #
        # The five headers DISPLAY.ASM reads at the foot of its segment are
        # read where it has said ASSUME DS:NOTHING, two hundred lines
        # above them: what is in them is the interrupt side of the driver
        # -- the INT 2FH and INT 10H handlers and the font writer -- which
        # is entered with the interrupted program's DS, so every reference
        # to the driver's own data is one MASM put a CS: on.  Twenty-two of
        # them lost it when these were read with DS on the segment.
        STARTS={'PARSER.ASM': {'cs': 'CODE', 'ds': None,
                               'es': None, 'ss': None},
                'INT2FCOM.INC': {'cs': 'CODE', 'ds': None,
                                 'es': None, 'ss': None},
                'INT10COM.INC': {'cs': 'CODE', 'ds': None,
                                 'es': None, 'ss': None},
                'CPS-FUNC.INC': {'cs': 'CODE', 'ds': None,
                                 'es': None, 'ss': None},
                'WRITE.INC': {'cs': 'CODE', 'ds': None,
                              'es': None, 'ss': None},
                'F-PARSER.INC': {'cs': 'CODE', 'ds': None,
                                 'es': None, 'ss': None}},
        # Four names the modules read above the line that declares each:
        # the bit that says INT 1FH wants doing, in INT10COM.INC, and three
        # of F-PARSER.INC's own in the states of its font loader.  MASM
        # resolved them on its second pass, and fasm wants a number it can
        # resolve wherever it stands rather than an EQU it has not read yet.
        FORWARD=('INTER_1FH', 'FLAG_RESTART', 'FSTAT_COMPLETE',
                 'FSTAT_FONT'),
        # WRITE.INC indexes a table with a dot in front of the index --
        # CS:CPD_FONT_DATA.[SI] -- which to MASM was the name plus what is
        # in SI, the same thing its [BX].field is.  It is the one line in
        # the release written that way, and the ordinary form of it is the
        # same reference.
        EARLY={'WRITE.INC': [(
            "        MOV     CS:CPD_FONT_DATA.[SI],AX;\n",
            "        MOV     CS:CPD_FONT_DATA[SI],AX ;\n")]},
    ),
    # PRINTER.SYS, the code page driver for the printer and DISPLAY's own
    # shape: the five modules PRINTER.LNK names and the one header they all
    # read.  CPSPM10.ASM is the driver and the fonts for the 5202 printer,
    # CPSFONT3.ASM the font writer, PRTINT2F.ASM the INT 2FH handler,
    # CPSPI07.ASM the generic IOCTL side -- which is how MODE CP PREPARE
    # hands it a .CPI file -- and PARSER.ASM the switches the DEVICE= line
    # carries.  Four more files in the directory are earlier copies of
    # three of those and the text the retriever took over; PRINTER.LNK
    # links none of them.  The release links the five and runs EXE2BIN over
    # the result with ZERO.DAT on its input, which is the 0 that answers
    # the question EXE2BIN asks about an image with fixups in it.
    'PRINTER': dict(
        DIR='src/DEV/PRINTER',
        MODULES=('CPSPM10.ASM', 'CPSFONT3.ASM', 'PRTINT2F.ASM',
                 'CPSPI07.ASM', 'PARSER.ASM', 'CPSPEQU.INC'),
        ONESEG=True,
        SHARED=('SYSMSG.INC', 'VERSIONA.INC', 'MSGSERV.ASM', 'MSGDCL.INC',
                'COPYRIGH.INC', 'STRUC.INC', 'PARSE.ASM', 'PSDATA.INC'),
        # Every module says ASSUME CS:CSEG where its segment opens and
        # names no other register: the driver is entered on an interrupt or
        # through the two addresses in its header, with whatever DS the
        # caller had, so what it reads of its own it reads through CS.
        START={'cs': 'CSEG', 'ds': None, 'es': None, 'ss': None},
    ),
    # RAMDRIVE.SYS, the other RAM disk: two modules in one segment, which
    # RAMDRIVE.LNK names in that order, and the eight headers RAMDRIVE.ASM
    # reads -- every one of them a copy of its own, kept in the driver's
    # directory, which is the copy both MASM and fasm read before the one
    # in src/INC.  Four of the eight have a namesake there and all four
    # differ from it: this driver was written against the kernel's headers
    # as they were, and kept them.
    #
    # Where VDISK takes what is left of the first megabyte or extended
    # memory through INT 15H, this one can also take expanded memory
    # through the LIM 4.0 calls EMM.INC describes, and it is the one DOS 4
    # shipped for it.  The release links the two and runs EXE2BIN over the
    # result.
    'RAMDRIVE': dict(
        DIR='src/DEV/RAMDRIVE',
        MODULES=('RAMDRIVE.ASM', 'MESSAGES.ASM',
                 'DEVSYM.INC', 'SYSCALL.INC', 'DIRENT.INC', 'MI.INC',
                 'EMM.INC', 'LOADALL.INC', 'ABOVE.INC', 'AB_MACRO.INC'),
        ONESEG=True,
        # It reads nothing out of src/INC: the message retriever is not in
        # it either -- MESSAGES.ASM holds the text itself, as the drivers
        # did before the retriever took that over.
        SHARED=(),
        # RAMDRIVE.ASM's own, at the head of the segment: the driver is
        # entered with the caller's DS and says where DS is as it goes.
        START={'cs': 'RAMCODE', 'ds': None, 'es': None, 'ss': None},
        # MESSAGES.ASM is the data, and says DS is on the segment.
        STARTS={'MESSAGES.ASM': {'cs': 'RAMCODE', 'ds': 'RAMCODE',
                                 'es': None, 'ss': None}},
    ),
    # SMARTDRV.SYS, the disk cache, and RAMDRIVE's sibling: one module in
    # one segment, with seven headers of its own beside it -- the same
    # seven RAMDRIVE keeps, written as .ASM here.  SMARTDRV.LNK links the
    # one object and the release runs EXE2BIN over it.  FLUSH13.C, FL13.ASM
    # and FLMES.ASM in the same directory build FLUSH13.EXE, a utility of
    # its own that empties the cache, and none of the three is part of the
    # driver.
    #
    # Where RAMDRIVE keeps a disk in memory, this one keeps the sectors of
    # a real disk there: it hooks INT 13H under the BIOS, so the kernel's
    # own reads go through the cache without knowing it, and the memory it
    # caches into can be above the first megabyte or in expanded memory,
    # which is why it carries the same protected-mode block mover.
    'SMARTDRV': dict(
        DIR='src/DEV/SMARTDRV',
        MODULES=('SMARTDRV.ASM', 'DEVSYM.ASM', 'SYSCALL.ASM', 'MI.ASM',
                 'EMM.ASM', 'LOADALL.ASM', 'ABOVE.ASM', 'AB_MACRO.ASM'),
        ONESEG=True,
        SHARED=(),
        # The segment's own ASSUME, which names CS and nothing else: the
        # driver is entered on an interrupt, with the interrupted program's
        # DS, and says where DS is itself as it goes.
        START={'cs': 'INT13CODE', 'ds': None, 'es': None, 'ss': None},
        # The two halves of the 24-bit address where extended memory
        # starts, which the driver lays down in its EMM control block
        # twenty-seven hundred lines above the EQUs that declare them:
        # MASM resolved them on its second pass, and fasm wants a number it
        # can resolve wherever it stands rather than an EQU it has not read
        # yet.
        FORWARD=('EXTMEM_LOW', 'EXTMEM_HIGH'),
    ),
    # COUNTRY.SYS is not a driver but a file of tables, and MKCNTRY is the
    # program that writes it: the release's build runs MKCNTRY.EXE and
    # keeps what it lays down.  One module and the header it reads, in
    # three segments and no group -- cseg for the program, dseg for the
    # country tables it writes the file out of, and sseg for a stack of a
    # hundred and twenty-eight bytes.  It is in src/DEV because COUNTRY.SYS
    # is, and it is the only thing there that is not a driver.
    'COUNTRY': dict(
        DIR='src/DEV/COUNTRY',
        MODULES=('MKCNTRY.ASM', 'MKCNTRY.INC'),
        SHARED=('COPYRIGH.INC',),
        # cseg's own ASSUME, which names the data segment as well: the
        # program is entered as an .EXE and sets DS itself.
        START={'cs': 'cseg', 'ds': 'dseg', 'es': None, 'ss': None},
        # How many countries the table holds, which the release works out
        # with MASM's %: the count is a counter the CTRYENT macro bumps
        # once per country, and "dummy %cntrycnt" passes its *value* as
        # text, so that the EQU inside the macro gives finalCNT the number
        # -- which the DW at the head of the table, written three dozen
        # lines above it, then has on the second pass.  fasm's % is not
        # that, and dropping it would give finalCNT the name rather than
        # the number: read where the DW stands, the counter is still nought
        # there.  So the macro goes and the number is taken the way fasm
        # takes one, as an assembly-time constant that the passes settle.
        EARLY={'MKCNTRY.ASM': [(
            "dummy\tmacro\tp\n"
            "finalCNT\tequ\tp\n"
            "\tendm\n"
            "\tdummy\t%cntrycnt\n",
            ";dummy\tmacro\tp\n"
            ";finalCNT\tequ\tp\n"
            ";\tendm\n"
            "finalCNT = cntrycnt\t; what the macro's % made of it\n")]},
    ),
    # XMAEM.SYS, the 80386 XMA emulator: ten modules in one segment, which
    # XMAEM.LNK names in that order, and the six headers they read between
    # them -- three of those being .MAC macro libraries, which is what the
    # release calls a header that holds nothing but macros.
    #
    # What it emulates is the XMA memory card of a 3270 PC on a machine
    # whose processor is a 386: it goes into protected mode, keeps a
    # descriptor table and an interrupt table of its own, and answers the
    # card's own interface from them, so that software written for the card
    # runs on the newer machine.  INDEINS.MAC is there because MASM 3.0 did
    # not know the 386's instructions and the release hand-assembles the
    # ones it wants.
    'XMAEM': dict(
        DIR='src/DEV/XMAEM',
        MODULES=('INDEINI.ASM', 'INDEEXC.ASM', 'INDEEMU.ASM', 'INDEXMA.ASM',
                 'INDEDMA.ASM', 'INDEI15.ASM', 'INDEIDT.ASM', 'INDEGDT.ASM',
                 'INDEMSG.ASM', 'INDEPAT.ASM',
                 'INDEACC.INC', 'INDEDAT.INC', 'INDEMSUS.INC',
                 'INDEDES.MAC', 'INDEINS.MAC', 'INDEOVP.MAC'),
        ONESEG=True,
        SHARED=('COPYRIGH.INC',),
        # INDEINI keeps a word to save BX in and calls it RBX, which is a
        # register to fasm; INDEEXC's DISPLAY is fasm's directive for
        # printing a line as it assembles, and INDEEMU's INT3 is the
        # instruction that breaks into a debugger.
        RESERVED=('RBX', 'DISPLAY', 'INT3'),
        # Labels two modules each have one of, MASM having assembled them
        # apart: INDEDMA and INDEXMA both call the way out of their own
        # handler INEXIT and OUTEXITDMA, INDEDMA and INDEEXC both halt the
        # processor at HALT, and INDEEXC and INDEI15 both go on at OK1 and
        # OK2.  INDEDMA's and INDEEXC's take the underscore.
        PRIVATE={'INDEDMA.ASM': (('INEXIT', 'INEXIT_'),
                                 ('OUTEXITDMA', 'OUTEXITDMA_'),
                                 ('HALT', 'HALT_')),
                 'INDEEXC.ASM': (('OK1', 'OK1_'), ('OK2', 'OK2_')),
                 # INDEXMA calls a selector of its own CRT_SELECTOR, where
                 # the CRT_SELECTOR the other modules read is the word
                 # INDEI15 declares and nothing in INDEXMA reads either.
                 'INDEXMA.ASM': (('CRT_SELECTOR', 'CRT_SELECTOR_'),)},
        # INDEI15's DDL names a place and says how wide it is as a number,
        # which is a width MASM read and fasm does not: its LABEL takes the
        # word for the width and not the count of bytes.  The one call is
        # DDL SP_INIT,2, the top of the monitor's stack.  So the width is
        # read inside the macro, where the number has arrived.
        # INDEEXC declares the table it writes the registers on the screen
        # from with one line per register, and reads the register's own word
        # of the stack frame as BP_&NAME, pasting the field's name together
        # out of the register's.  MASM read a field's name wherever it was
        # declared, where fasm asks for the structure as well, and a pasted
        # name is not one the rules can look up: all nineteen of them are
        # fields of BPSTACK, so that is the structure written here.
        PATCHES={'INDEEXC.ASM': [("DW      BP_#NAME",
                                  "DW      BPSTACK.BP_#NAME")],
                 'INDEI15.ASM': [(
            "NAME   LABEL   SIZE\n",
            "\tmatch =1, SIZE \\{ label NAME byte \\}\n"
            "\tmatch =2, SIZE \\{ label NAME word \\}\n"
            "\tmatch =4, SIZE \\{ label NAME dword \\}\n")]},
        # The six messages, which XMAEM.SKL names in mixed case and the
        # modules read in upper: the include file BUILDMSG writes is not one
        # the rules can see, so the spellings are said here.
        SPELLING={'welcome': 'Welcome', 'goodload': 'GoodLoad',
                  'no_80386': 'No_80386', 'was_inst': 'Was_Inst',
                  'small_parm': 'Small_Parm', 'no_mem': 'No_Mem'},
        # Every module says ASSUME CS:PROG at the head of the segment and
        # names no other register.
        START={'cs': 'PROG', 'ds': None, 'es': None, 'ss': None},
    ),
    # XMA2EMS.SYS, the expanded memory manager: one module and the ten
    # headers it reads, all of them in the one segment CSEG, which is what
    # the release's makefile assembles -- LINK over the one object and
    # EXE2BIN over the result, so this is a flat image like the other
    # drivers and not the .EXE XMAEM is.
    #
    # It is the LIM 4.0 side of the pair: XMAEM makes a 386 look like the
    # XMA card, and this hands the card's pages out as expanded memory
    # through INT 67H, which is what the device named EMMXXXX0 answers.
    # LIM40.INC and LIM40B.INC are the thirty-odd functions of the
    # specification, EMSINIT and the three diagnostics files are the
    # initialisation that is thrown away, and PARMPARS reads the DEVICE=
    # line with the kernel's own parser.
    #
    # Three more segments it declares AT 0 and lays nothing down in:
    # INT_VEC, INT_VEC15 and INT_VEC13 name the vectors for interrupts
    # 67H, 15H and 13H, which the driver hooks -- 67H for itself, 15H so
    # that nothing else hands out the extended memory it has taken, and
    # 13H to put the pages back where a disk read runs through them.
    #
    # DIAGS.ASM beside it is the diagnostics as they were before the
    # message retriever took their text over, with EMS_US.MSG holding that
    # text; the makefile reads neither.
    'XMA2EMS': dict(
        DIR='src/DEV/XMA2EMS',
        MODULES=('XMA2EMS.ASM', 'I13HOOK.INC', 'GENIOCTL.INC',
                 'LIM40.INC', 'LIM40B.INC', 'EMSINIT.INC', 'ROMSCAN.INC',
                 'PARMPARS.INC', 'XMA2EMSP.INC', 'XMA1DIAG.INC',
                 'PS2_5060.INC'),
        ONESEG=True,
        SHARED=('MSBDS.INC', 'SYSVAR.INC', 'PSDATA.INC', 'PARSE.ASM'),
        # The driver's own ST1 is the way out of its strategy routine, and
        # fasm reads it as the second register of the 8087's stack; K1 and
        # K2 in XMA1DIAG are two places in its keyboard wait, and fasm's
        # are the mask registers of a processor thirty years off.
        RESERVED=('ST1', 'K1', 'K2'),
        # Two equates a file read earlier in the module has already used:
        # XMA1DIAG declares VIRT_MODE, the bit that says the adapter is in
        # virtual mode, and EMSINIT turns it on; PS2_5060 declares
        # E_PARM_DEF and PARMPARS reads it.  MASM resolved both on its
        # second pass.
        FORWARD=('VIRT_MODE', 'E_PARM_DEF'),
        # The segment's own ASSUME, which says CS and nothing else: the
        # driver is entered through the two addresses in its header, with
        # the caller's DS, and says where DS is itself as it goes -- the
        # three ASSUME DS:INT_VEC lines in EMSINIT put it on the interrupt
        # vector table at 0.
        START={'cs': 'CSEG', 'ds': None, 'es': None, 'ss': None},
    ),
    # KEYBOARD.SYS, which is neither a driver nor a program: it is the file
    # of keyboard layouts KEYB reads, and the .SYS on the end of it is the
    # release's own naming.  Twenty modules in the order KEYBOARD.LNK names
    # them, all in the one segment CODE and all of them data -- there is not
    # an instruction in the whole of it.  KDFNOW is the file header and the
    # two tables of pointers, one by language code and one by keyboard ID;
    # the eighteen after it are a language apiece, each with its state logic
    # and its two code pages; KDFEOF is the copyright and the 1AH that ends
    # the file.  The release links the twenty and runs EXE2BIN over the
    # result.
    #
    # Five more .ASM files in the directory are earlier copies the link file
    # does not name: KDF.ASM, which the comments in the others still point
    # at for the linkage instructions, and KDFFR, KDFIT and KDFUK, each of
    # which was split in two when a second keyboard ID wanted a layout of
    # its own -- and KDFSU, Finland, which KDFSV serves instead.
    'KEYBOARD': dict(
        DIR='src/DEV/KEYBOARD',
        MODULES=('KDFNOW.ASM', 'KDFSP.ASM', 'KDFPO.ASM', 'KDFFR120.ASM',
                 'KDFFR189.ASM', 'KDFDK.ASM', 'KDFSG.ASM', 'KDFGE.ASM',
                 'KDFIT141.ASM', 'KDFIT142.ASM', 'KDFUK166.ASM',
                 'KDFUK168.ASM', 'KDFSF.ASM', 'KDFBE.ASM', 'KDFNL.ASM',
                 'KDFNO.ASM', 'KDFCF.ASM', 'KDFSV.ASM', 'KDFLA.ASM',
                 'KDFEOF.ASM',
                 'KEYBMAC.INC', 'KEYBSHAR.INC'),
        ONESEG=True,
        SHARED=('POSTEQU.INC', 'COPYRIGH.INC'),
        # Every name a module declares is its own: the twenty were assembled
        # apart, and what one lets the others have it says with a PUBLIC --
        # the state logic and the two code page tables, three names a
        # language, which KDFNOW takes with an EXTRN apiece.
        LOCALS='all',
        # The flag masks KEYBMAC's FIND_FLAG is handed by name and compares
        # by name, to say which of the four flag bytes each belongs to.  The
        # other nine it asks after are in INC/POSTEQU.INC, which says there
        # why they are written with = as well.
        NUMERIC=('SCAN_MATCH', 'EITHER_SHIFT', 'EITHER_CTL', 'EITHER_ALT',
                 'ACUTE', 'GRAVE', 'DIARESIS', 'CIRCUMFLEX', 'CEDILLA',
                 'TILDE'),
        # Every module says ASSUME CS:CODE,DS:CODE at the head of the
        # segment, which is the whole of what any of them says.
        START={'cs': 'CODE', 'ds': 'CODE', 'es': None, 'ss': None},
    ),
}

NAME = sys.argv[1].upper() if len(sys.argv) > 1 else ''
if NAME not in UTILITIES:
    sys.exit('usage: convert.py UTILITY [ORIGINALS]\n'
             '       UTILITY is one of ' + ', '.join(sorted(UTILITIES)))
U = UTILITIES[NAME]
HERE = os.path.dirname(os.path.abspath(__file__)) + '/'
# Where the utility's own modules are.  The drivers under src/DEV are
# programs of the same shape, built the same way and checked by the same
# four checkers, so they are entries here as well and say where they are.
R = HERE + U.get('DIR', 'src/CMD/' + NAME) + '/'
S = os.path.join(sys.argv[2], '') if len(sys.argv) > 2 else R
N = r"[A-Za-z_@?$][A-Za-z0-9_@?$]*"
# MASM let a label and the instruction it names share a line,
# which RECOVER writes often, so the operand rules look past one.
LED = r"^(\s*(?:" + N + r":)?\s*(?:"
MNEM = (r"mov|cmp|add|sub|inc|dec|and|or|xor|test|adc|sbb|xchg|lea|push|pop|"
        r"mul|imul|div|idiv|neg|not|shl|shr|sar|rol|ror|call|jmp|les|lds|int|"
        # A structured statement carries operands too, inside the condition
        # INC/STRUC.INC takes apart, and the rules below have to reach them.
        r"\.IF|\.ELSEIF|\.WHILE|\.UNTIL|\.REPEAT|\.WHEN|\.LEAVE|\.EXITIF")

MODULES = U['MODULES']
SUFFIX = U.get('SUFFIX', {})
HEADERS = U.get('HEADERS', ())


def shared(name):
    # A name with a directory on the front of it reaches outside src/INC:
    # SHARE's link file reads four of the kernel's modules, and three of the
    # files those read between them are in src/DOS.
    return open(os.path.normpath(HERE + 'src/INC/' + name),
                encoding='cp437', newline='').read().replace('\r\n', '\n')


def read(stem, converted=False):
    # a pristine copy is named as the module is or with .orig after it
    path = R + stem if converted else S + stem + '.orig'
    if not converted and not os.path.exists(path):
        path = S + stem
    text = open(path, encoding='cp437', newline='').read().replace('\r\n', '\n')
    # MASM read a form feed as white space: it broke the page of the listing
    # and did nothing else.  CHKFAT.ASM has one, in front of the CHAINREC
    # label, and fasm would take it for part of the name.
    return text.replace('\x0c', ' ')


def written(stem):
    return R + stem


# The labels the structured-assembly preprocessor wrote are named $$IF1 and
# the like, and $$ is fasm's name for where the output starts.  The leading
# dollars go to the end, as the kernel's $-named procedures did.
# MASM assembled the modules apart, so each could have its own $$IF9; one
# assembly reads them together and four of the generated names are in both.
# TREEPAR's carry the module's mark.
TAG = dict.fromkeys(MODULES, '')
TAG.update(U.get('TAG', {}))


def comment_at(line):
    """Where a line's comment starts, the semicolons inside quotes aside.

    MODEPARS declares a field as DB ";" -- the extra delimiter its parser
    takes -- and a comment that began at the first semicolon would take the
    quote with it and leave the string open.
    """
    quote = None
    for i, c in enumerate(line):
        if quote:
            if c == quote:
                quote = None
        elif c in '\'"':
            quote = c
        elif c == ';':
            return i
    return -1


def code_of(line):
    """A line with its comment taken off."""
    j = comment_at(line)
    return line if j < 0 else line[:j]


STRING = re.compile(r"'[^']*'|\"[^\"]*\"")


def unquoted(code, change):
    """A change made to a line's code with its string literals held out of
    the way, for a rule that has to read the line from one end.

    outside_strings above works on the pieces between the quotes, which is
    enough for a rule that reads a name wherever it stands; a rule anchored
    on the start of the line cannot see that far once the line is in pieces.
    So each literal comes out, the change is made, and they go back.
    """
    held = []

    def hide(m):
        held.append(m.group(0))
        return '\x03%d\x03' % (len(held) - 1)

    return re.sub(r"\x03(\d+)\x03", lambda m: held[int(m.group(1))],
                  change(STRING.sub(hide, code)))


def outside_strings(pattern, now, code):
    """A substitution made everywhere but inside a string.

    MODEPRIN declares L EQU "L", the letter it looks for in LPT1: renaming
    the one takes the other with it unless the quotes are left alone.
    """
    out, at = [], 0
    for m in STRING.finditer(code):
        out.append(re.sub(pattern, now, code[at:m.start()]))
        out.append(m.group(0))
        at = m.end()
    out.append(re.sub(pattern, now, code[at:]))
    return ''.join(out)


def dollars(text, tag):
    """The dollars a name begins with, moved to the end of it.

    $$ is fasm's name for where the output starts, so a name cannot begin
    with one.  EDLIN.ASM has a file name called $$$FILE as well as the
    labels the preprocessor wrote, so the run of dollars is taken whole and
    the module's mark goes after it where there is more than one -- those are
    the generated names, and the modules share some of them.
    """
    def one(m):
        marks, name = m.group(1), m.group(2)
        # the generated labels are two dollars, a word of a few letters and a
        # number -- $$IF1, $$EN3, $$DO22 -- and those are the ones the
        # modules share, so those are the ones that take the mark.  $$$FILE
        # is a name of the program's own and keeps to itself.
        made = len(marks) == 2 and re.match(r"(?i)^[A-Za-z]{1,4}\d+$", name)
        return name + marks + (tag if made else '')

    return re.sub(r"(\$+)([A-Za-z_@?][A-Za-z0-9_@?]*)", one, text)


# RECOVER asks the parser for seven of its constants by an older spelling,
# with a dollar on the front: $p_file_spc for P_File_Spc.  INC/PSDATA.INC,
# which RECPARSE.INC reads, declares them without one -- it has not had the
# dollars since before this release -- so the dollar comes off here and the
# name is the one the parser gives it.  APPEND asks for the parameter block
# the same way, $P_PARMS_Blk for the structure PSDATA.INC calls P_PARMS_Blk.
#
# This runs before the dollars are moved to the end, because afterwards
# there is no leading dollar left to take off.
def parser_names(text):
    return re.sub(r"(?i)(?<![\w$])\$(p_" + N + r")",
                  lambda m: m.group(1), text)


# Words fasm keeps for itself which the utility uses for its own -- COMP's
# getsec is an instruction of a later processor, EXE2BIN's LOAD and STORE are
# directives.  Each takes a trailing underscore, the way TCMD1A's Display_
# and TREE's RESTORE_ did.  fasm reads a directive's name whatever case it is
# written in, so a name that collides collides in every spelling.
RESERVED = U.get('RESERVED', ())

# MASM stopped at END: the assembly was over there, and whatever stood
# below was text in a file and nothing more.  GSHARE.ASM ends with the last
# two dozen lines of itself written out twice -- the END, the ELSE that
# would have closed the segment the other way, and then the whole tail of
# GOM again -- so a reading that went past the END would meet a second gom2
# and a second GOM, which one assembly cannot have.
#
# The lines below the END that carry code go out commented, the way a
# directive does.  A comment, a blank line and the end-of-file mark are left
# as they stand, being nothing either way, so this changes no module whose
# END is its last word -- which is every other one.
AFTEREND = re.compile(r"(?i)^\s*END"
                      r"(?!\s+(?:if|virtual|struc|match|macro)\b)"
                      r"(\s+" + N + r")?\s*$")


def after_end(text):
    lines = text.split('\n')
    for i, line in enumerate(lines):
        if AFTEREND.match(code_of(line)):
            rest = [';' + l if l.split(';')[0].strip(' \t\x1a') else l
                    for l in lines[i + 1:]]
            return '\n'.join(lines[:i + 1] + rest)
    return text


# The lines of a module that have to stand in for the release's own before
# anything at all reads it -- a conditional round a SEGMENT directive, which
# is a pass of the walk here and cannot be left to the assembler to choose,
# and a macro the module declares for itself, which the rules below would
# read as the code it is not.  Everything else a module needs written for it
# is in PATCHES, which goes on after the rules have had their say.
EARLY = U.get('EARLY', {})


def seg_patched(stem, text):
    for was, now in EARLY.get(stem, ()):
        assert was in text, (stem, was)
        text = text.replace(was, now, 1)
    return text


def commented(text):
    """MASM's COMMENT, which ran from its delimiter to the next one.

    XMAEM opens every module and every macro library of its own with one --
    the IBM banner, in a box of asterisks, after a COMMENT # -- and nothing
    else in the release uses the directive.  fasm has no block comment at
    all, so every line of such a block is given a semicolon of its own.
    """
    lines = text.split('\n')
    out, i = [], 0
    while i < len(lines):
        m = re.match(r"(?i)^[ \t]*COMMENT[ \t]+(\S)(.*)$", lines[i])
        if not m:
            out.append(lines[i])
            i += 1
            continue
        delim, rest = m.group(1), m.group(2)
        out.append(';' + lines[i])
        i += 1
        if delim in rest:               # it opens and closes on one line
            continue
        while i < len(lines):
            out.append(';' + lines[i])
            closed = delim in lines[i]
            i += 1
            if closed:
                break
    return '\n'.join(out)


source = {m: dollars(parser_names(after_end(commented(seg_patched(m,
                                                                  read(m))))),
                     TAG[m])
          for m in MODULES}

# MASM assembled the modules apart, so each could keep a name of its own
# that another module also used.
PRIVATE = U.get('PRIVATE', {})
for stem, pairs in PRIVATE.items():
    out = []
    # the code only: a comment keeps the word the release wrote
    for line in source[stem].split('\n'):
        j = comment_at(line)
        code, comment = (line, '') if j < 0 else (line[:j], line[j:])
        for was, now in pairs:
            # MASM read the two cases alike, so a module can declare the
            # name in one and read it in another: FASTOPEN writes EXIT
            # where the label stands and "jmp short exit" where it jumps
            # to it.  The name the table gives is written in either case,
            # the spellings being settled later like any other name's.
            code = outside_strings(r"(?i)(?<![A-Za-z0-9_@?$.])" + was
                                   + r"(?![A-Za-z0-9_@?$])", now, code)
        out.append(code + comment)
    source[stem] = '\n'.join(out)


# Labels a module keeps to itself, which MASM let every module have because
# it assembled them apart: MODE writes endif01 and p0 to p7 by hand in five
# modules apiece.  Each takes the name of the module it is in.
#
# A program whose modules say which of their names the others may have is a
# different case, and LOCALS='all' is for that one: every name a module
# declares is its own unless it makes it PUBLIC, or reads it from elsewhere
# with an EXTRN.  KEYBOARD is twenty keyboard tables assembled apart, with
# three names apiece made PUBLIC -- the logic table and the two code pages --
# and a hundred and ninety-two names declared in more than one of them,
# which is no list to write out.
LOCALS = U.get('LOCALS', ())
if LOCALS:
    everything = LOCALS == 'all'
    localpat = (None if everything
                else re.compile(r"(?i)^(?:" + "|".join(LOCALS) + r")$"))
    for stem in MODULES:
        # A header every module reads is not one of them: what it declares
        # is the same name in all of them, so the mark would make twenty
        # names of one.  KEYBSHAR.INC gives the layouts their shapes and
        # KEYBMAC.INC the macros that lay them down.
        if everything and not stem.upper().endswith('.ASM'):
            continue
        mark = stem.split('.')[0].lower()
        mine = set()
        # The names the module hands to the others, or takes from them: a
        # PUBLIC or an EXTRN names one thing across the whole program, and
        # the mark would hide it.
        theirs = set()
        if everything:
            for line in source[stem].split('\n'):
                m = re.match(r"(?i)^[ \t]*(?:PUBLIC|EXTRN)[ \t]+(.*)$",
                             code_of(line))
                if m:
                    theirs |= {w.split(':')[0].strip().lower()
                               for w in m.group(1).split(',') if w.strip()}
        for line in source[stem].split('\n'):
            # MODE writes some of its labels against the margin and some
            # of them indented, and the names it keeps to itself are
            # equates as well: one-letter ones, which the structured
            # statements want for the flags and two modules give different
            # values to.  A procedure and a byte of storage are the other
            # two shapes: FASTOPEN and FASTSEEK each declare a CHECK_IT to
            # walk their own cache with and a func_cod to keep the call's
            # function in, in segments of their own.
            code = code_of(line)
            m = re.match(r"^[ \t]*(" + N + r"):", code) \
                or re.match(r"(?i)^(" + N + r")[ \t]+(?:equ|=)[ \t]", code) \
                or re.match(r"(?i)^[ \t]*(" + N + r")[ \t]+"
                            r"(?:proc|label|d[bwdq])\b", code)
            if m and (localpat.match(m.group(1)) if localpat
                      else m.group(1).lower() not in theirs):
                mine.add(m.group(1))
        if not mine:
            continue
        out = []
        for line in source[stem].split('\n'):
            j = comment_at(line)
            code, comment = (line, '') if j < 0 else (line[:j], line[j:])
            for name in sorted(mine, key=len, reverse=True):
                # MASM read the two alike, so a module can declare the name
                # in one case and read it in another: FASTOPEN writes
                # EMS_FAILED where the label stands and "jc ems_failed"
                # where it jumps to it.  The spelling each occurrence has is
                # kept and the mark goes on the end of it, the spellings
                # being settled later like any other name's.
                code = outside_strings(r"(?i)(?<![A-Za-z0-9_@?$.])("
                                       + re.escape(name)
                                       + r")(?![A-Za-z0-9_@?$])",
                                       lambda m: '%s_%s' % (m.group(1), mark),
                                       code)
            # A name a macro pastes together is not the name until fasm has
            # put it together, so the rule above passes over it: MODELENG's
            # BREAK writes JMP ENDCASE_#destination for one of the ENDCASE_0
            # and the rest it has of its own, and the module's mark goes on
            # the end of the paste.
            def paste(m2, mark=mark, mine=mine):
                stem, arg = m2.group(1), m2.group(2)
                if not localpat or not localpat.match(stem + '0'):
                    return m2.group(0)
                # in the spelling the module's own labels have, MASM having
                # read the two alike: MODESCRN writes endcase_&X in the
                # macro and ENDCASE_0 where the label stands.
                for name in mine:
                    if name.lower().startswith(stem.lower()):
                        stem = name[:len(stem)]
                        break
                return '%s&%s&_%s' % (stem, arg, mark)

            code = re.sub(r"(?i)(?<![A-Za-z0-9_@?$.])(" + N + r")&(" + N
                          + r")(?![A-Za-z0-9_@?$&])", paste, code)
            out.append(code + comment)
        source[stem] = '\n'.join(out)


def renamed(text):
    """The reserved names given their underscore, in the code only.

    A comment keeps the word the file wrote: the assembler never reads it,
    and "load another character" is not the directive.  So does a string:
    KEYB marks the block it copies its shared data into with
    db 'SHARED DATA', and DATA is one of the names on its list -- read as
    code, the marker came out a byte longer than the release wrote it.
    """
    out = []
    for line in text.split('\n'):
        j = comment_at(line)
        code, comment = (line, '') if j < 0 else (line[:j], line[j:])
        for name in RESERVED:
            code = outside_strings(r"(?i)(?<![A-Za-z0-9_@?$.])" + name
                                   + r"(?![A-Za-z0-9_@?$])",
                                   lambda m, name=name: name + '_', code)
        out.append(code + comment)
    return '\n'.join(out)


for stem in MODULES:
    source[stem] = renamed(source[stem])


# The structures a module declares for itself.  TREE declares MSG_DESC and
# SUBLIST three times over -- in TREEQU.INC, in TREEPAR.ASM and in
# MSGHAN.INC -- and the three agree field for field, so the laying out asks
# whether it has been done and the fields here only have to reserve room:
# MSGHAN.INC's copy is the one instances are written against.
def struct_arrays(text):
    """An array of instances of a structure: NAME strucname n DUP (<>).

    MASM laid the structure down n times with the defaults it declares.
    fasm invokes a structure by naming an instance and there is no name to
    give the ones after the first, so the room is reserved under the one
    name the program uses: XCOPY indexes DTAS with BP and otherwise asks
    only for its offset.  Every field of the structure has to declare a
    zero for this to be the same bytes, which is checked.
    """
    def one(m):
        name, strucname, count, comment = (m.group(1), m.group(2), m.group(3),
                                           m.group(4) or '')
        if STRUCZERO.get(strucname.lower()):
            return ('; %s declares a zero in every field, so what the %s of'
                    ' them\n'
                    '; take up is that many zero bytes; the name is what the\n'
                    '; program asks for and the fields are reached from it.\n'
                    'label %s byte\n\ttimes %s*sizeof.%s db 0%s'
                    % (strucname, count, name, count, strucname, comment))
        # Something other than a zero in a field, so the room cannot just be
        # reserved: the instances are laid down as instances, each named
        # after the array and its place in it, under the one label the
        # program asks for.  MODEPARS writes its sixteen parm_list_entry
        # that way, every one of them starting with an item tag of 0FFH.
        return ('; %s declares something other than a zero, so the %s of them'
                '\n'
                '; are laid down as instances.  fasm names an instance, so'
                ' each\n'
                '; takes the array\'s name and its place in it; what the'
                ' program\n'
                '; asks for is the label.\n'
                'label %s byte%s\n'
                'rept %s each\n{\n\t%s_#each %s\n}'
                % (strucname, count, name, comment, count, name, strucname))

    # The same thing with no name of its own, which MASM laid down where it
    # stood: XMA2EMS writes the first of its sixty-four handle entries by
    # name and the other sixty-three on the line below it, indented, as
    # H_LOOKUP_STRUC NUM_HANDLES-1 DUP (<>).  Nothing reads them by a name
    # -- the table is indexed from the first -- so the names are this
    # conversion's own, and the structure's own name is what tells such a
    # line from a named instance of something else.
    made = [0]

    def more(m):
        lead, strucname, count = m.group(1), m.group(2), m.group(3)
        comment = m.group(4) or ''
        if STRUCZERO.get(strucname.lower()):
            return ('; %s declares a zero in every field, so what the %s of'
                    ' them\n'
                    '; take up is that many zero bytes.\n'
                    '%stimes %s*sizeof.%s db 0%s'
                    % (strucname, count, lead, count, strucname, comment))
        made[0] += 1
        name = '%s$a%d' % (strucname, made[0])
        return ('; %s declares something other than a zero, so the %s of them'
                '\n'
                '; are laid down as instances, each under a name of its own.'
                '\n'
                '%srept %s each%s\n%s{\n%s\t%s_#each %s\n%s}'
                % (strucname, count, lead, count,
                   ' ' + comment if comment else '', lead, lead,
                   name, strucname, lead))

    text = re.sub(r"(?mi)^(" + N + r")[ \t]+(" + N + r")[ \t]+(\S+)[ \t]+"
                  r"dup[ \t]*\([ \t]*<[ \t]*>[ \t]*\)[ \t]*(;[^\n]*)?$",
                  one, text)
    return re.sub(r"(?mi)^([ \t]+)(" + '|'.join(sorted(STRUCS))
                  + r")[ \t]+(\S+)[ \t]+"
                  r"dup[ \t]*\([ \t]*<[ \t]*>[ \t]*\)[ \t]*(;[^\n]*)?$",
                  more, text)


def literals(text):
    """A literal of two characters read as a number, whose bytes MASM and
    fasm lay down in opposite orders.

    MASM put the first character of a literal in the high byte, so DEBUG's
    CMP AX,"LC" matched the two characters "CL" -- which is what the
    release's own comment beside it says it is looking for -- and
    MOV AX,"DL" stored the letters of "LD".  fasm puts the first character
    in the low byte, so the characters are turned round here to keep the
    number, and the release's spelling goes in the comment.

    Only where a word is what is wanted: an operand, the value of an EQU or
    an =, and a DW or a DD.  A DB lays its characters down in order in both
    assemblers -- XCOPY writes the drive it is copying to over the first of
    a DB " :" -- and so does a field of a structure, whose default value is
    the DB the release declared it with.  Only two characters, which is the
    width of a word and the only width this can be certain of.
    """
    def turned(code):
        pieces, at, seen = [], 0, []
        for m in STRING.finditer(code):
            pieces.append(code[at:m.start()])
            s = m.group(0)
            if len(s) == 4:
                seen.append(s)
                s = s[0] + s[2] + s[1] + s[3]
            pieces.append(s)
            at = m.end()
        pieces.append(code[at:])
        return ''.join(pieces), seen

    out = []
    for line in text.split('\n'):
        j = comment_at(line)
        code, note = (line, '') if j < 0 else (line[:j], line[j:])
        wanted = re.match(LED + MNEM + r")\s+)", code, re.I) \
            or re.match(r"(?i)^[ \t]*" + N + r"[ \t]+(?:equ|=)[ \t]", code) \
            or re.match(r"(?i)^[ \t]*(?:" + N + r"[ \t]+)?d[wd][ \t]", code)
        if not wanted:
            out.append(line)
            continue
        changed, seen = turned(code)
        # a pair that reads the same either way round -- "11", "  ", "??" --
        # is laid down the same by both, and says nothing worth a note
        if changed == code:
            out.append(line)
            continue
        # the release's own spelling, so that what it wrote can still be
        # read on the line
        said = 'the release writes %s' % ', '.join(seen)
        out.append(changed + (note + '; ' + said if note.strip()
                              else '  ; ' + said))
    return '\n'.join(out)


def spaced_overrides(text):
    """The white space MASM let stand after the colon of a segment override.

    APPEND writes MOV CS: parse_flag,0FFH for the flag it keeps in its own
    code segment.  MASM read the colon and the name as one reference; the
    rules below look for the two together, so the gap is closed first.
    """
    out = []
    for line in text.split('\n'):
        j = comment_at(line)
        code, note = (line, '') if j < 0 else (line[:j], line[j:])
        out.append(outside_strings(r"(?i)\b(cs|ds|es|ss)[ \t]*:[ \t]+"
                                   r"(?=[A-Za-z_@?$\[])",
                                   lambda m: m.group(1) + ':', code) + note)
    return '\n'.join(out)


def strings(text):
    """A string instruction written with the operands it implies.

    MOVS BYTE PTR[DI],BYTE PTR[SI] is how MASM was told the width of what
    MOVSB moves: the operands name the only places the instruction can go
    to, ES:DI and DS:SI, so they say nothing but the width.  fasm takes the
    width on the mnemonic, and for CMPS it wants the two the other way
    round from MASM -- source first -- so the plainest conversion is the
    one MASM assembled to, the mnemonic with the width on the end.  All of
    these are one byte either way.

    A segment that is not the one the instruction implies does say
    something, and those are left as they stand: the kernel reads a table
    through CS with LODS byte [cs:si], which fasm takes as it is.

    The operand can be the name of a variable instead, which says the same
    thing and no more: PRINT_T scans the name it has just parsed with
    REPNE SCAS NameBuf, and says in a comment beside it that the name is
    there to tell the assembler it is a byte search.  The width is the one
    the name was declared with.
    """
    DEFAULT = {'di': 'es', 'si': 'ds'}
    SUFFIX = {'byte': 'b', 'word': 'w', 'dword': 'd'}
    # one operand: a width, PTR, and a register in brackets, either of them
    # carrying the segment MASM wrote it through
    OP = (r"(?:(cs|ds|es|ss)[ \t]*:[ \t]*)?"
          r"(byte|word|dword)[ \t]+ptr[ \t]*"
          r"\[[ \t]*(?:(cs|ds|es|ss)[ \t]*:[ \t]*)?(si|di)[ \t]*\]")

    def one(m):
        mnemonic = m.group(2)
        kinds, segs, regs = [], [], []
        for seg1, kind, seg2, reg in re.findall(r"(?i)" + OP, m.group(3)):
            kinds.append(kind.lower())
            segs.append((seg1 or seg2).lower())
            regs.append(reg.lower())
        # every operand has to have been read, and all of one width
        if not regs or len(set(kinds)) != 1:
            return m.group(0)
        if len(regs) != len(re.findall(r",", m.group(3))) + 1:
            return m.group(0)
        if any(seg and seg != DEFAULT[reg] for seg, reg in zip(segs, regs)):
            return m.group(0)
        return '%s%s%s' % (m.group(1), mnemonic, SUFFIX[kinds[0]])

    text = re.sub(r"(?i)^([ \t]*(?:rep|repe|repz|repne|repnz)?[ \t]*)"
                  r"(movs|cmps|stos|lods|scas)[ \t]+([^;\n]*?)[ \t]*$",
                  one, text, flags=re.M)

    def named(m):
        size = TYPESIZE.get(m.group(3).lower())
        if size not in (1, 2, 4):
            return m.group(0)
        return '%s%s%s%s' % (m.group(1), m.group(2),
                             {1: 'b', 2: 'w', 4: 'd'}[size], m.group(4) or '')

    return re.sub(r"(?i)^([ \t]*(?:rep|repe|repz|repne|repnz)?[ \t]*)"
                  r"(movs|cmps|stos|lods|scas)[ \t]+(" + N
                  + r")([ \t]*;[^\n]*)?$", named, text, flags=re.M)


def aliased(text):
    """A name that stands for an instance, where a field is read through it.

    KEYB's KEYBEQU.INC says SD EQU SHARED_DATA and its modules read
    SD.TABLE_OK and the rest of the shift state through it.  MASM read the
    two as one name; fasm reads a name with a dot in it as a single word,
    so SD.TABLE_OK would never meet the SD the EQU declares.  The name it
    stands for is written out where a field follows it, which leaves the
    EQU itself alone -- expanding that would make it stand for itself --
    and leaves a bare SD, which is the instance's own address either way.
    """
    if not ALIASED:
        return text
    return re.sub(r"(?i)(?<![A-Za-z0-9_@?$.])(" + "|".join(
        sorted(map(re.escape, ALIASED), key=len, reverse=True))
        + r")(?=\.)", lambda m: ALIASED[m.group(1).lower()], text)


def translated(text):
    """XLAT written with the table it reads.

    XLAT always translates through BX, so the operand MASM was given told
    it the width and the segment and nothing else -- KEYBI9 writes
    XLAT [SI].XLAT_1_BUF_ENTRY, which is not even the register it reads.
    fasm wants XLATB, or the one operand it will take where a segment has
    to be said: KEYBI9C reads two of its tables out of its own code
    segment with XLAT CS:K11, and MASM laid the CS prefix down for it.
    """
    def one(m):
        lead, operand, note = m.group(1), m.group(2) or '', m.group(3) or ''
        seg = re.search(r"(?i)\b(cs|es|ss)[ \t]*:", operand)
        if seg:
            return '%sxlat byte [%s:bx]%s' % (lead, seg.group(1).lower(), note)
        return '%sxlatb%s' % (lead, note)

    return re.sub(r"(?mi)^([ \t]*)xlat(?:[ \t]+([^;\n]+?))?[ \t]*"
                  r"(;[^\n]*)?$", one, text)


def far_pointers(text):
    """DD of a name, which MASM wrote as a far pointer.

    MASM's DD of a name laid down an offset and a segment, the segment for
    the loader to fix up.  fasm's DD of a name is the offset and nothing
    else, so the two halves are written as the two words they are, the
    second of which is the fasm segment and so is fixed up as the loader
    fixed the other up.

    The name can carry the segment it is in, which is how FORMAT's message
    sublists name theirs, or stand on its own, which is how NLSFUNC's do:
    then the segment is the one the name is declared in.  A DD of anything
    else -- a number, an expression, the ? of a reservation -- is a DD
    still, and so is a name declared somewhere this cannot see, which is
    why the bare rule asks before it rewrites.
    """
    def split(head, value, comment, segment):
        """The two words, under the name the DD was declared with.

        A DD gave its name the width of one, which the program reads it by:
        PRINT_R's INDOS is a far pointer to the kernel's busy flag and the
        resident part loads DS and SI from it with one LDS.  Two DWs would
        leave the name a word wide, so it is written over them with the
        width it had.
        """
        m = re.match(r"^([ \t]*)(" + N + r")[ \t]+$", head)
        under = '\tdw %s%s\n\tdw %s' % (value, comment, segment)
        if not m:
            return '%sdw %s%s\n\tdw %s' % (head, value, comment, segment)
        return '%slabel %s dword\n%s' % (m.group(1), m.group(2), under)

    def one(m):
        head, seg, name = m.group(1), m.group(2), m.group(3)
        return split(head, name, m.group(4) or '', SEGMAP[seg.upper()])

    text = re.sub(r"(?mi)^([ \t]*(?:" + N + r"[ \t]+)?)dd[ \t]+(" + SEGPAT
                  + r")[ \t]*:[ \t]*(" + N + r")[ \t]*(;[^\n]*)?$", one, text)

    def bare(m):
        head, name = m.group(1), m.group(2)
        where = SEGOF.get(name.lower())
        if where is None:
            return m.group(0)
        return split(head, name + m.group(3), m.group(4) or '',
                     SEGMAP[space(where)])

    return re.sub(r"(?mi)^([ \t]*(?:" + N + r"[ \t]+)?)dd[ \t]+(" + N
                  + r")([ \t]*)(;[^\n]*)?$", bare, text)


def at_far_jumps(text):
    """A jump to a FAR label in a segment AT an address, which MASM wrote as
    a direct far jump: the segment it is at and the offset in it."""
    if not FARAT:
        return text

    def one(m):
        return '%s%s%s:%s' % (m.group(1), m.group(2),
                              FARAT[m.group(3).lower()], m.group(3))

    return re.sub(r"(?i)\b(jmp|call)([ \t]+)(" + "|".join(sorted(FARAT))
                  + r")\b", one, text)


def far_names(text):
    """A CALL or JMP to a name the program declares FAR.

    MASM knew the name's distance from the PROC FAR or LABEL FAR that
    declares it -- the EXTRN in the module that calls it says the same --
    and laid down a far transfer without being told twice.  fasm takes the
    name at face value and assembles a near one, which from another address
    space goes nowhere and from the same one leaves the far RET two words
    to come back through where one was pushed.

    PRINT is where this first showed.  Its transient part jumps into the
    resident part at MoveTrans to have the print buffer set up and itself
    moved up out of the way, and the resident part calls back into the
    transient at GoDispMsg to put a message on the screen; TO_DOS, the
    resident part's own way of making a DOS call, is FAR and called from
    both.  The two are different address spaces, and all four transfers
    came out near.
    """
    if not FARSEG:
        return text

    def one(m):
        name = m.group(2)
        return '%s%s:%s' % (m.group(1), SEGMAP[FARSEG[name.lower()]], name)

    return re.sub(r"(?mi)^([ \t]*(?:jmp|call)[ \t]+)("
                  + "|".join(sorted(map(re.escape, FARSEG),
                                    key=len, reverse=True))
                  + r")(?=[ \t]*(?:;|$))", one, text)


def far_jumps(text):
    """JMP or CALL FAR PTR, which MASM assembled as a far transfer.

    CHKPROC writes JMP FAR PTR ROOTDIR twice, for a jump inside the group:
    MASM laid down a segment and an offset and left the segment for the
    loader to fill in.  fasm says the same thing as a name in a segment, and
    the segment is the group's, which is what CS already holds.  Written as
    FAR PTR and nothing else, fasm reads the pair as an address to jump
    through and assembles an indirect jump, which is right about nothing.
    """
    return re.sub(r"(?i)\b(jmp|call)([ \t]+)far[ \t]+ptr[ \t]+(" + N + r")",
                  lambda m: '%s%s%s:%s' % (m.group(1), m.group(2),
                                           SEGMAP[START['cs']], m.group(3)),
                  text)


def segment_values(text):
    """A segment named as a value, which is the address space it is in.

    CHKMSG.INC writes the segment half of a sublist's pointer as "dw data",
    the segment the value is in, and FORMAT asks for the paragraph past its
    own image with "mov bx,End_Of_Memory".  LINK resolved a reference to a
    segment as the frame it is reached through, which is the group's where
    there is one and the segment's own where there is not.
    """
    text = re.sub(r"(?mi)^([ \t]*(?:" + N + r"[ \t]+)?dw[ \t]+)(" + SEGPAT
                  + r")([ \t]*)(;[^\n]*)?$",
                  lambda m: '%s%s%s%s' % (m.group(1), segvalue(m.group(2)),
                                          m.group(3), m.group(4) or ''), text)
    # The segment can be arithmetic as well as something moved: PRINT_R
    # works out how far the transient part has been moved with SUB AX,DG,
    # the group's own paragraph taken from where it now is.
    text = re.sub(r"(?mi)^([ \t]*(?:" + N + r":)?[ \t]*"
                  r"(?:mov|add|sub|cmp)[ \t]+" + N
                  + r"[ \t]*,[ \t]*)(" + SEGPAT + r")(?![\w:.])",
                  lambda m: m.group(1) + segvalue(m.group(2)), text)

    # MASM's SEG, the segment a name is in, which fasm has no operator for:
    # FORMAT asks for SEG DATA where it is about to load DS, and the name of
    # the fasm segment is that segment.
    def seg(m):
        name = m.group(2).upper()
        where = name if name in SEGMAP else SEGOF.get(m.group(2).lower())
        # segvalue, and not SEGMAP itself, because a one-segment program
        # lays no fasm segment down: DISPLAY's DW SEG CODE is the number
        # the link file gives the name.
        return segvalue(space(where)) if where else m.group(0)

    return re.sub(r"(?i)\b(seg[ \t]+)(" + N + r")\b", seg, text)


def grouped(text):
    """The group's name, which is one address space.

    One group is one address space, which is one fasm segment: the group's
    name with an underscore after it is the name of it here, and the name on
    its own is that segment, which the loader fixes up.  A name qualified
    with the group is the offset inside it, which a bare name already is, so
    the qualifier goes where an offset is what is wanted -- after OFFSET, and
    in a DW, which is how XCOPYPAR writes the parser's pointers -- and is
    marked where it is a place, to be resolved where the ASSUMEs can be read.
    """
    def one(code):
        code = re.sub(r"(?i)\boffset[ \t]+(?:" + SEGPAT + r")[ \t]*:[ \t]*",
                      'offset ', code)
        code = re.sub(r"(?mi)^([ \t]*(?:" + N + r"[ \t]+)?d[bwdq][ \t]+"
                      r"(?:[^;\n]*,)?[ \t]*)(?:" + SEGPAT
                      + r")[ \t]*:[ \t]*",
                      lambda m: m.group(1), code)
        return re.sub(r"(?i)(?<![\w.])(" + SEGPAT + r")[ \t]*:[ \t]*",
                      lambda m: '\x01%s\x02' % m.group(1).upper(), code)

    # A segment's name inside a string is a word of the message and not a
    # qualifier: GSHARE2 hangs on an internal error with "Share: Internal
    # error", and Share is the segment the whole sharer is in, so the
    # message came out saying "[cs:Internal] error".
    out = []
    for line in text.split('\n'):
        j = comment_at(line)
        code, note = (line, '') if j < 0 else (line[:j], line[j:])
        out.append(unquoted(code, one) + note)
    return '\n'.join(out)


def nested_dup(text):
    """A DUP inside a DUP, which MASM allowed and fasm does not.

    XMAEM's INDEDAT lays the global descriptor table out as a structure and
    writes each run of descriptors as the number of them and the eight bytes
    one of them takes -- DB 16 DUP (8 DUP(0)) -- where fasm reads one DUP and
    no more.  The two counts are multiplied and the inner list is the one
    that stands, so both numbers are still in the line.
    """
    while True:
        text, n = re.subn(
            r"(?i)(\bd[bwdqt][ \t]+)([^;\n]*?)[ \t]*\bdup[ \t]*\([ \t]*"
            r"([^;\n()]*?)[ \t]*\bdup[ \t]*\(([^()\n]*)\)[ \t]*\)",
            lambda m: '%s%s*%s dup (%s)' % (m.group(1), m.group(2),
                                            m.group(3), m.group(4)),
            text)
        if not n:
            return text


def declarations(text):
    """A structure a module declares for itself, in the house shape.

    MASM's fields were names of their own and fasm takes them from the
    structure laid out once at nought, so each one gets a dot.  A field
    declared with a single value becomes a parameter with that value for its
    default, which is what an instance leaving the field out takes; a field
    declared with DUP, or with none, is written as it stands.  The laying out
    asks whether it has been done, since a structure may be declared more
    than once across the modules.
    """
    # XCOPY.ASM indents the fields of HEADER where every other structure
    # here writes them against the margin, so the indentation is part of
    # what is matched and is kept.
    # The value is whatever stands between the DB and the comment, the
    # comment being found with the quotes respected: MODEPARS declares a
    # field as DB ";".
    SCALAR = re.compile(r"(?i)^([ \t]*)(" + N + r")([ \t]+)(D[BWDQ])([ \t]+)"
                        r"(.*?)[ \t]*$")
    # The structures stand inside segments and the modules are read once
    # per segment, so the MATCH that asks whether the laying out has been
    # done -- the preprocessor's, answered on the first reading whatever the
    # pass -- would guard a VIRTUAL that no pass assembles.  The declarations
    # are gathered at the head of the module, before the first segment opens.
    out, here, fields, body, top = [], None, [], [], []
    for line in text.split('\n'):
        code = code_of(line)
        # MASM's STRUC takes nothing after it, and nothing may follow it
        # here either: MODEVID's INCLUDE STRUC.INC would otherwise open a
        # structure called INCLUDE that never ends, and everything after it
        # would be gathered into a body that is never written.
        m = re.match(r"^(" + N + r")[ \t]+STRUC[ \t]*$", code, re.I)
        if m:
            here, fields, body = m.group(1), [], []
            continue
        if here:
            if re.match(r"^" + re.escape(here) + r"[ \t]+ENDS\b", code, re.I):
                top.append('STRUC %s%s' % (here, (' ' + ', '.join(fields))
                                           if fields else ''))
                top.append('{')
                top.extend(body)
                top.append('}')
                # The measuring instance takes a zero for every field
                # whose value is a number or a name, because a name may
                # stand for one the module declares further down and fasm
                # takes an EQU's value where it is written: INVOKE declares
                # IOCTL0C_def with a mode of text and says what text is a
                # hundred and forty lines further on.  The width comes from
                # the DB or the DW and not from the value, so the size is
                # the same; a string is as wide as it is long, and stands.
                # A field whose default is a run of values is measured
                # with that run: the room is what the instance is for, and
                # a nought in its place would make the structure shorter
                # than it is.
                measure = ', '.join(
                    [value if value[:1] in ('\'', '"')
                     or re.search(r"(?i)\bdup\b", value) else '0'
                     for value in (f.split('=', 1)[1].strip()
                                   for f in fields)])
                for s in ('match =%s_LAID_OUT, %s_LAID_OUT' % (here, here),
                          '{', '    %s_LAID_OUT equ 1' % here,
                          '    virtual at 0',
                          '      %s %s%s' % (here, here,
                                             ' ' + measure if measure else ''),
                          '      sizeof.%s = $ - %s' % (here, here),
                          '    end virtual', '}'):
                    top.append(s)
                here = None
                continue
            j = comment_at(line)
            note = line[j:] if j >= 0 else ''
            m = SCALAR.match(code)
            # A field of more than one value cannot become a parameter
            # with that value for its default, the parameters being told
            # apart by commas: MODECPEQ declares a code page font's tag as
            # DB 0FFH,"FONT   ".  It is written as it stands, as a field
            # declared with DUP is.
            if m and ' dup' not in m.group(6).lower() \
                    and 'dup ' not in m.group(6).lower() \
                    and ',' not in m.group(6):
                name, value = m.group(2), m.group(6).strip()
                fields.append('%s_=%s' % (name, '0' if value == '?' else value))
                body.append('%s.%s%s%s%s%s_%s'
                            % (m.group(1), name, m.group(3), m.group(4),
                               m.group(5), name, ' ' + note if note else ''))
                continue
            # A field whose room is a run of one value rather than a value
            # of its own.  MASM counted it among the fields an instance
            # fills in -- the values are positional -- and let an instance
            # leave it out and take what the release declared, so it takes a
            # parameter like any other.  XMA2EMS's H_LOOKUP_STRUC gives each
            # handle an eight-byte name, H_NAME DB 8 DUP(0), and the first
            # entry of the table is written <0,,,,,>: six slots for six
            # fields, where five parameters would have left the last value
            # nowhere to go.  A run of question marks is not one of these --
            # that one reserves its room and is written as it stands.
            m = re.match(r"(?i)^([ \t]*)(" + N + r")([ \t]+)(D[BWDQ])([ \t]+)"
                         r"([^;,\n]*?\bdup\b[^;,\n]*?)[ \t]*$", code)
            if m and '?' not in m.group(6):
                name = m.group(2)
                fields.append('%s_=%s' % (name, m.group(6).strip()))
                body.append('%s.%s%s%s%s%s_%s'
                            % (m.group(1), name, m.group(3), m.group(4),
                               m.group(5), name, ' ' + note if note else ''))
                continue
            m = re.match(r"(?i)^([ \t]*)(" + N + r")([ \t]+)(D[BWDQ])\b", code)
            if m:                       # a field with DUP in it
                body.append(m.group(1) + '.' + line.lstrip())
                continue
            # an unnamed run of bytes: room with no name on it
            m = re.match(r"(?i)^([ \t]*)D([BWD])([ \t]+)(\S+)[ \t]+dup[ \t]*"
                         r"\([ \t]*\?[ \t]*\)", code)
            if m:
                body.append('%sR%s%s%s' % (m.group(1), m.group(2).lower(),
                                           m.group(3), m.group(4)))
                continue
            # A field with no name at all, which is one value wide: MASM
            # gave it no name to read it by, and it still counted as a
            # place an instance could fill in.  ANSI writes
            # My_IOCTL_Req_Packet REQ_PCKT 0,0,0Eh,0,?,0,?,?,?,?,? and the
            # second of those eleven values is the reserved byte between
            # INFO_LEVEL and DATA_LENGTH, so leaving it out of the
            # parameters would put every value after it one field early.
            # It takes a parameter like any other field, named after the
            # structure and the place it stands in, and what the release
            # declared is its default.
            m = re.match(r"(?i)^([ \t]*)(D[BWDQ])([ \t]+)(.*?)[ \t]*$", code)
            if m and ' dup' not in m.group(4).lower() \
                    and 'dup ' not in m.group(4).lower() \
                    and ',' not in m.group(4):
                value = m.group(4).strip()
                spare = '%s_%d_' % (here, len(fields) + 1)
                fields.append('%s=%s' % (spare, '0' if value == '?'
                                         else value))
                body.append('%s%s%s%s%s'
                            % (m.group(1), m.group(2), m.group(3), spare,
                               ' ' + note if note else ''))
                continue
            body.append(line)
            continue
        out.append(line)
    # What the layouts read, which has to stand above them.  A field can
    # reserve its room with a name rather than a number -- ANSI.INC's device
    # header says DB NAME_LEN DUP(0) for the name in it, and declares
    # NAME_LEN two lines above the structure -- and the layouts are gathered
    # at the head of the module, which puts them above that line.  fasm
    # reads an EQU where it stands, so the declaration is copied up with
    # them; the release's own line stays where it wrote it, and an EQU may
    # be given again.
    wanted, seen = [], set()
    for line in top:
        for word in re.findall(N, code_of(line)):
            if word.upper() in seen:
                continue
            for other in out:
                m = re.match(r"(?i)^(" + re.escape(word)
                             + r")[ \t]+EQU[ \t]+[^;\n]*$", code_of(other))
                if m:
                    seen.add(word.upper())
                    wanted.append(other)
                    break
    if wanted:
        wanted = ['; the layouts below read these, and an EQU is read where'
                  ' it stands'] + wanted + ['']
    return '\n'.join(wanted + top + out)

# RECPARSE.INC writes its parse tables before it reads INC/PSDATA.INC, and
# the tables ask the header for the return values a drive or a file spec is
# matched with.  MASM looked a name up on its second pass, so a table could
# name a constant the header had not declared yet; fasm reads the source
# once, and an EQU is text put in where the name is used, so the header has
# to be read first.  The four blocks the file is in are therefore laid down
# in the order parser switches, header, tables, parser -- the switches first
# because the header reads them to lay itself out, and the tables where they
# are read is all that moves.
for stem in MODULES:
    source[stem] = declarations(nested_dup(source[stem]))



# What the whole program gives storage to, and how each name is spelled where
# it is declared: one segment, so one set of each for all of it.
DATA, SIZE, spelling = set(), {}, {}
# The names an EQU gives to a place rather than to a number: the brackets
# belong where such a name is used and not where it is declared, so the line
# that declares it is left alone.
PLACED = set()
# And the ones whose value is a place with a width in front of it, which is
# more than one word wherever the name stands.
WIDE = set()
# And the ones whose value names the register that reaches the place as
# well, which is the override wherever the name stands: XMAEM's INDEINI
# reads the request header through RH EQU DS:[BX], and a reference that
# holds such a name wants no second override in front of it.
CARRIED = set()
# What each module asked a name it does not declare to be.  MASM took a
# module at a time and LINK never compared the two, so a program could
# declare a place one width and read it another: MODESUBS gives pbaud_ptr a
# BYTE label over a DW, and the two modules that store into it both ask for
# it as a WORD and so stored a word.  One assembly has to settle on a width,
# and the width the code was assembled with is the one that makes it run.
ASKED = {}
# A shared header can give storage a name as well: INC/DSEG.INC declares
# the ROM BIOS data area at 40H, which KEYB's interrupt 9 handler reads the
# keyboard flags out of, and without it those references keep the bare name
# MASM read from memory.  The headers declare their fields with a dot in
# front, which is not a name here, so what this adds is only what they
# declare at the top level.
for text in (list(source.values())
             + [read(h + '.INC', converted=True) for h in HEADERS]
             + [shared(h) for h in U['SHARED']]):
    for line in text.split('\n'):
        code = code_of(line)
        # A reservation is storage as much as a DB is.  Inside a module
        # the DB ? is still a DB at this point, the rules that turn it
        # into an RB running later; a shared header that has been
        # converted already shows the RB, which is how INC/DSEG.INC
        # declares every byte of the ROM BIOS data area.
        m = re.match(r"^[ \t]*(" + N + r")\s+(db|dw|dd|rb|rw|rd)\b",
                     code, re.I)
        if m:
            DATA.add(m.group(1).lower())
            SIZE[m.group(1).lower()] = {'db': 'byte', 'dw': 'word',
                                        'dd': 'dword', 'rb': 'byte',
                                        'rw': 'word', 'rd': 'dword'
                                        }[m.group(2).lower()]
        m = re.match(r"^[ \t]*(" + N + r")\s+label\s+(byte|word|dword)\b", code, re.I)
        if m:
            DATA.add(m.group(1).lower())
            SIZE[m.group(1).lower()] = m.group(2).lower()
        # An EQU that names a place rather than a number is storage as much
        # as a DB is: MODELENG's BIOS_date EQU ES:[DI].
        m = re.match(r"(?i)^[ \t]*(" + N + r")\s+equ\s+"
                     r"((?:cs|ds|es|ss):)?\s*\[[^\]]+\]\s*$", code)
        if m:
            DATA.add(m.group(1).lower())
            PLACED.add(m.group(1).lower())
            if m.group(2):
                CARRIED.add(m.group(1).lower())
        # And an EQU that names a place with its width, which stands for the
        # whole reference and not for an address: NLSFUNC's FILESPEC_PTR EQU
        # BYTE PTR DS:[IN_DEX].  A name like that is more than one word
        # where it is used, which the structured statements have to be told.
        m = re.match(r"(?i)^[ \t]*(" + N + r")\s+equ\s+"
                     r"(?:byte|word|dword|qword)\s+ptr\s+"
                     r"(?:(?:cs|ds|es|ss):)?\s*\[[^\]]+\]\s*$", code)
        if m:
            # not storage to the rules that put brackets round a name: the
            # brackets are in the value already
            WIDE.add(m.group(1).lower())
        # An EXTRN says what a name another module declares is, which is the
        # only word on it where that module names a place with an EQU:
        # GRTABHAN says PATCH_OFF EQU WORD PTR $-2 and GRTAB asks for it as
        # EXTRN PATCH_OFF:WORD.
        m = re.match(r"(?i)^[ \t]*EXTRN[ \t]+(.*)$", code)
        if m:
            for name, kind in re.findall(r"(?i)(" + N + r")[ \t]*:[ \t]*"
                                         r"(byte|word|dword|qword)\b",
                                         m.group(1)):
                DATA.add(name.lower())
                ASKED.setdefault(name.lower(), set()).add(kind.lower())


# A LABEL the storage under it bears out, which is most of them: DEBMES
# labels each of its message blocks WORD and lays words down there.  Such a
# declaration says what the place is, whatever a module that reads it says.
BORNEOUT = set()
for text in (list(source.values())
             + [read(h + '.INC', converted=True) for h in HEADERS]):
    want = None
    for line in text.split('\n'):
        code = code_of(line)
        m = re.match(r"(?i)^[ \t]*(" + N + r")\s+label\s+"
                     r"(byte|word|dword)\b", code)
        if m:
            want = (m.group(1).lower(), m.group(2).lower())
            continue
        m = re.match(r"^[ \t]*(db|dw|dd)\b", code, re.I)
        if m and want:
            if want[1] == {'db': 'byte', 'dw': 'word',
                           'dd': 'dword'}[m.group(1).lower()]:
                BORNEOUT.add(want[0])
            want = None
        elif code.strip():
            want = None

# A name every module that asks for it agrees about takes the width they
# asked for, where the declaration is not borne out by the storage under it:
# MODESUBS labels four of the sublist pointers BYTE over a DW, and the two
# modules that store into them both asked for a WORD and stored a word.
# Where the modules disagree the declaration stands, there being nothing
# better to go on.
for name, kinds in ASKED.items():
    if len(kinds) == 1 and name not in BORNEOUT:
        SIZE[name] = next(iter(kinds))


# MASM's LENGTH gave the number of elements a variable was declared with and
# SIZE the number of bytes they take up; fasm has neither, so the number is
# worked out from the declaration and written where it was asked for.  Every
# one of them here is a byte array, so the two come to the same.
UNIT = {'DB': 1, 'DW': 2, 'DD': 4}
COUNT = U.get('COUNT', {})
ABSWIDTH = U.get('ABSWIDTH', {})
# Whether the program has one segment, and so is read once rather than once
# per segment: TREE, GRAFTABL and the other .COM files are, and the programs
# with a group or two address spaces are not.
ONESEG = U.get('ONESEG', False)
for text in source.values():
    for line in text.split('\n'):
        # a field of a structure counts as well, and by this point it is
        # written with the dot the house gives it: GRAFTABL asks for
        # SIZE LANCHAR, which is a field of LANGUAGE.
        m = re.match(r"(?i)^[ \t]*\.?(" + N + r")\s+(db|dw|dd)\s+(\S+)"
                     r"\s+dup\s*\(", code_of(line))
        if m:
            COUNT[m.group(1).lower()] = (m.group(3),
                                         UNIT[m.group(2).upper()])


# MASM's TYPE gave the number of bytes one element of a variable takes, and
# fasm has no such operator, so the number is worked out here.  A name that
# stands for another is followed one step: DISKCOMP.EQU says VOL_SERIAL EQU
# EXT_BOOT_SERIAL, and INC/BOOTFORM.INC declares that field as a DD.
WIDTH = {'db': 1, 'dw': 2, 'dd': 4, 'dq': 8, 'rb': 1, 'rw': 2, 'rd': 4}
TYPESIZE, ALIAS = {}, {}
# The shared headers the utility reads, and the ones those read in their
# turn, for the sizes, the structures and the spellings they declare.
SHARED = U['SHARED']
READS = SHARED
for text in (list(source.values()) + [shared(h) for h in READS]):
    for line in text.split('\n'):
        code = code_of(line)
        m = re.match(r"(?i)^[ \t]*\.?(" + N + r")[ \t]+(d[bwdq]|r[bwd])\b",
                     code)
        if m:
            TYPESIZE.setdefault(m.group(1).lower(), WIDTH[m.group(2).lower()])
        m = re.match(r"(?i)^[ \t]*(" + N + r")[ \t]+equ[ \t]+(" + N
                     + r")[ \t]*$", code)
        if m:
            ALIAS.setdefault(m.group(1).lower(), m.group(2).lower())


def typed(code):
    """TYPE name, as the number of bytes MASM worked it out to be."""
    def one(m):
        name = m.group(1).lower()
        # of a structure it is the room an instance of it takes, which fasm
        # has a name of its own for
        if name in STRUC_CASE:
            return 'sizeof.' + STRUC_CASE[name]
        size = TYPESIZE.get(name) or TYPESIZE.get(ALIAS.get(name, ''))
        return str(size) if size else m.group(0)
    return re.sub(r"(?i)\bTYPE[ \t]+(" + N + r")", one, code)


def measures(code):
    """LENGTH and SIZE, as the numbers MASM worked them out to be."""
    def one(m):
        op, name = m.group(1).upper(), m.group(2)
        # SIZE of a structure is the room an instance of it takes, which
        # fasm has a name of its own for.
        if op == 'SIZE' and name.lower() in STRUC_CASE:
            return 'sizeof.' + STRUC_CASE[name.lower()]
        if name.lower() not in COUNT:
            # one of something, not an array of it: MASM read LENGTH as one
            # and SIZE as the width of the thing, which is what TYPE gives.
            width = TYPESIZE.get(name.lower())
            if width:
                return '1' if op == 'LENGTH' else str(width)
            return m.group(0)
        count, unit = COUNT[name.lower()]
        return count if op == 'LENGTH' or unit == 1 else '(%s)*%d' % (count, unit)
    return re.sub(r"(?i)\b(SIZE|LENGTH)\s+(" + N + r")", one, code)


# Whether every field of a structure declares a zero, for a rule that has to
# know.  The declarations are read in the shape they have been given here: a
# parameter for each field, defaulting to what the release wrote, and a line
# for each that lays the parameter down.
STRUCZERO = U.get('STRUCZERO', {})
for text in list(source.values()) + [shared(h) for h in READS]:
    here, zeros, defaults = None, True, {}
    for line in text.split('\n') + ['STRUC end_of_file$']:
        code = code_of(line)
        m = re.match(r"(?i)^STRUC[ \t]+(" + N + r")(.*)$", code)
        if m:
            if here is not None:
                STRUCZERO[here] = zeros
            here, zeros = m.group(1).lower(), True
            defaults = {p.split('=')[0].strip().lower(): p.split('=')[1].strip()
                        for p in m.group(2).split(',') if '=' in p}
            continue
        if here is None:
            continue
        m = re.match(r"(?i)^[ \t]*\.(?:" + N + r")[ \t]+(d[bwdq]|r[bwd])[ \t]+"
                     r"(.*\S)", code)
        if not m:
            continue
        kind, value = m.group(1).lower(), m.group(2).strip()
        value = defaults.get(value.lower(), value)
        if kind[0] == 'r' or not re.match(
                r"(?i)^(?:[^;]*dup[ \t]*\([ \t]*)?0[ \t]*\)?$", value):
            zeros = False


# The structures the headers lay out: MASM wrote an instance's fields in
# angle brackets and fasm takes them as they stand.
STRUCS = set()
# The structures a module declares for itself count as well: COMP2.ASM has
# two of its own, for the extended attribute calls.
# The shared headers RECOVER reads declare structures of their own, and a
# field of one of those is written the same way as a field of its own: the
# FCB's system file number comes from INC/DOSSYM.INC.
SHARED_STRUCS = READS
SEEN = [read(h + '.INC', converted=True) for h in HEADERS] \
       + [shared(h) for h in SHARED_STRUCS] + list(source.values())
for text in SEEN:
    STRUCS |= set(re.findall(r"(?m)^STRUC\s+(" + N + r")", text))
# the spelling each one is declared with, for SIZE to ask about
STRUC_CASE = {name.lower(): name for name in STRUCS}

# The size of an instance named on its own is the size of its first field,
# which is what MASM read a bare structure name as.
FIRST = U.get('FIRST', {})
for text in SEEN:
    for m in re.finditer(r"(?msi)^STRUC\s+(" + N + r").*?\n\{.*?\n[ \t]*\.\S+\s+"
                         r"(db|dw|dd|rb|rw|rd)\b", text):
        FIRST[m.group(1)] = {'db': 'byte', 'dw': 'word', 'dd': 'dword',
                             'rb': 'byte', 'rw': 'word',
                             'rd': 'dword'}[m.group(2).lower()]
# The name can carry a colon, with or without white space in front of it:
# ANSI writes BUF1: BUF_DATA <> and PRINTER HARD_SL1 : SLTS <,>, both of
# which MASM read as a label's colon with the instance laid down under it.
# The name and the structure's own have to be told apart by what stands
# between them -- white space, or the colon and then white space -- and the
# structure's name has to end where the alternation says it does: without
# either, PRINT's unnamed "qea <...>" read as an instance called q of the
# structure ea, and the name it needs went missing.
INSTANCE = re.compile(r"^(\s*" + N + r"(?:\s*:)?\s+)("
                      + '|'.join(sorted(STRUCS))
                      + r")\b\s*<(.*)>\s*$", re.I)
# An instance with no name of its own, which MASM laid down where it stood.
# fasm hangs an instance's fields on its name, so one has to be made up.
# It can stand at the margin as well: ANSI lays its video mode table down as
# sixteen MODE_TABLE <> against the margin under a label of its own, and
# PARSER six of its own structures the same way.
NAMELESS = re.compile(r"^(\s*)(" + '|'.join(sorted(STRUCS))
                      + r")\b\s*<(.*)>\s*$", re.I)

# Where one of them is written down.  fasm gives an instance's fields names of
# their own -- SUBLIST_VOL.SUB_VALUE_SEG -- so a reference to a field is a
# name like any other, and MASM read it from memory.
WRITTEN = set()
# and which structure it was written as, so that a field of another
# structure written on it can be told from one of its own
WRITTENAS = {}
for text in list(source.values()) + SEEN:
    for line in text.split('\n'):
        # INVOKE writes the brackets against the structure's name --
        # IOCTL0C_data_block IOCTL0C_def<> -- so they end it as a space does
        # The name can carry a colon, as it can where the instance itself
        # is written: PRINTER declares its four printer buffers
        # BUF0: BUF_DATA <,,,,,,,,,,> and reads the first of them as buf0,
        # which was one name to MASM.
        m = re.match(r"^[ \t]*(" + N + r")(?:\s*:)?\s+("
                     + '|'.join(sorted(STRUCS))
                     + r")(\s|<|$)", code_of(line), re.I)
        # the one each layout writes inside its VIRTUAL block, to measure
        # the structure by, names the structure after itself and is no
        # instance of the program's: CHKEQU.INC's DIRENT DIRENT is that.
        if m and m.group(1).lower() == m.group(2).lower():
            continue
        # An array of them is not one of them: the rules lay such a run
        # down under a LABEL and name the instances in it after the array
        # and their place in it, so a field written on the array's own name
        # is the offset of that field and has to be added.  XMA2EMS reads
        # the card a page is on as MEM_CARD_TABLE.END_PG_NUM[DI], where
        # MEM_CARD_TABLE is MEM_CARD_STRUC MAX_SLOTS DUP (<>).
        array = bool(m) and bool(
            re.match(r"(?i)^\S+[ \t]+dup[ \t]*\([ \t]*<[ \t]*>[ \t]*\)"
                     r"[ \t]*$", code_of(line)[m.end(2):].strip()))
        if m and not array:
            WRITTEN.add(m.group(1).lower())
            WRITTENAS.setdefault(m.group(1).lower(), m.group(2))
        if m:
            # one of these is a declaration like any other, so a reference
            # to it takes the spelling written here
            spelling.setdefault(m.group(1).lower(), m.group(1))
            if m.group(2) in FIRST:
                SIZE[m.group(1).lower()] = FIRST[m.group(2)]
                DATA.add(m.group(1).lower())

# The names that stand for storage, which a field is read through:
# KEYBEQU.INC's SD EQU SHARED_DATA, an instance of a structure, and
# KEYBTBBL's FB EQU FILE_BUFFER, a plain buffer with the keyboard file's
# header read over it.  The spelling the storage is declared with is the
# one written out, the aliased() rule running before the pass that settles
# spellings.
ALIASED = {was: spelling.get(now, now)
           for was, now in ALIAS.items() if now in WRITTEN or now in DATA}

# The macros the modules declare for themselves, in fasm's shapes.  DOSCALL
# asked IFNB whether it had been given a subfunction; MATCH answers the same
# question, on a blank argument and on a written one.
# The macros the modules declare for themselves, in fasm's shape.  Both
# COMPPAR.ASM and COMPSM.ASM declare the same page heading, which fasm takes
# as a redefinition.
# The page heading both COMPPAR.ASM and COMPSM.ASM declare for themselves,
# which fasm takes as a redefinition the second time.  It is variadic so the
# commas in a heading stay inside it.
# The page heading both COMPPAR.ASM and COMPSM.ASM declare for themselves,
# which fasm takes as a redefinition the second time.  It is variadic so the
# commas in a heading stay inside it.  The padding differs between the two,
# so the block is matched rather than spelled out.
HEADING = re.compile(r"(?mi)^(" + N + r")([ \t]+)MACRO([ \t]+)TEXT"
                     r"((?:[ \t]*,[ \t]*" + N + r")*)"
                     r"([ \t]*;[^\n]*)?$"
                     r"(.*?)"
                     r"^[ \t]*ENDM([ \t]*;[^\n]*)?$", re.S)


def heading(m):
    body = m.group(6)
    # The macro writes a page heading and nothing else, so its body is
    # listing directives.  MODE's asks IFB whether it was given a second
    # argument, which fasm has no answer for; a body with one of those in it
    # is kept as the comment it may as well be.
    if re.search(r"(?i)^[ \t]*IF(?:B|NB)\b", body, re.M):
        body = '\n' + ''.join(';' + l + '\n'
                              for l in body.strip('\n').split('\n'))
    return ('macro %s [TEXT]\n{' % m.group(1) + (m.group(5) or '') + body
            + '}' + (m.group(7) or ''))


# How many instances of each structure have been written with no name of
# their own, for naming the next one.  It is counted over the program and
# not over the module: ANSI lays sixteen MODE_TABLE down in ANSI.ASM and
# eight more in ANSIVID.INC, and two modules starting again at one would
# give the same made-up name to two instances.
nameless = {}

MACROS = U.get('MACROS', {})

for ending in ('\tendm\t\t\t\t;AN000;',):
    MACROS[ending] = '}'


# The lines of a module this cannot write for itself, each given as the text
# the release wrote and the text to put there -- MASM's ORG inside a segment
# wrote the filler it skipped over, where fasm's moves the address counter
# and writes nothing, and ALIGN is the same thing said in a way that writes.
# These go on after the rules above have had their say, so a patch can name
# a thing by the name they gave it: MODE's names the colon_byte the rules
# made of MODEPARS's colon.
PATCHES = U.get('PATCHES', {})


SWITCHES = {'FARSW': 'FarSW', 'DATESW': 'DateSW', 'TIMESW': 'TimeSW',
            'FILESW': 'FileSW', 'CMPXSW': 'CmpxSW', 'DRVSW': 'DrvSW',
            'QUSSW': 'QusSW', 'NUMSW': 'NumSW', 'KEYSW': 'KeySW',
            'SWSW': 'SwSW', 'VAL1SW': 'Val1SW', 'VAL2SW': 'Val2SW',
            'VAL3SW': 'Val3SW', 'INCSW': 'IncSW', 'BASESW': 'BaseSW'}


MASMREL = {'EQ': '=', 'NE': '<>', 'LT': '<', 'GT': '>', 'LE': '<=',
           'GE': '>='}


def written_over(text):
    """MASM's ORG back over what had been laid down, and the jump written
    over it.

    A table of jumps is read by index, so every entry of it is the same
    width, and both of XMAEM's are built the way MASM let a program build
    one: a REPT lays an entry down for every op-code or every port, all of
    them jumping to the routine that passes the thing through, and then an
    ORG and a JMP for each one the emulator handles itself -- the ORG moving
    the counter back into the table and the JMP written over the entry it
    lands on.  A last ORG at the table's end puts the counter back.

    fasm writes its output as it goes and cannot move back over it: an ORG
    there moves the address and not the place the output goes, so each of
    those jumps would be appended to the table instead of written into it,
    and everything after the table would stand three bytes further on for
    every one of them.  So the jump is handed to the link file's jmpover$,
    which assembles it where it belongs in a VIRTUAL block and stores the
    three bytes of it over the entry.  The call stands on the line the JMP
    was on, which keeps the module line for line; the ORG in front of it is
    a comment, and so is the ORG that closes the run, the counter never
    having moved.
    """
    lines = text.split('\n')
    out, i, inrun = [], 0, False
    while i < len(lines):
        code = code_of(lines[i])
        j = comment_at(lines[i])
        note = lines[i][j:] if j >= 0 else ''
        m = re.match(r"(?i)^([ \t]*)ORG[ \t]+(" + N + r"[ \t]*\+[^;\n]*?)"
                     r"[ \t]*$", code)
        jump = re.match(r"(?i)^[ \t]*JMP[ \t]+(" + N + r")[ \t]*$",
                        code_of(lines[i + 1]) if i + 1 < len(lines) else '')
        if m and jump:
            # The call stands where the JMP stood, that being the line
            # whose jump it writes; the ORG above it is a comment.
            out.append(';' + lines[i])
            k = comment_at(lines[i + 1])
            out.append('%sjmpover$ %s, %s%s'
                       % (re.match(r"^[ \t]*", lines[i + 1]).group(0),
                          m.group(2).strip(), jump.group(1),
                          ' ' + lines[i + 1][k:] if k >= 0 else ''))
            inrun = True
            i += 2
            continue
        # the ORG that closes the run, which put the counter back where the
        # table ended: nothing moved it, so there is nothing to put back
        if inrun and re.match(r"(?i)^[ \t]*ORG[ \t]+" + N + r"[ \t]*$", code):
            out.append(';' + lines[i])
            inrun = False
            i += 1
            continue
        out.append(lines[i])
        i += 1
    return '\n'.join(out)


def relations(text):
    """MASM's words for a comparison in a conditional, in fasm's signs.

    GSHARE2 asks whether the room between the table and the initialisation
    code that is thrown away comes to less than the pool the sharer wants
    -- IF shareinit-MFT LT PoolSize -- and fasm reads LT as a name.  Only
    the assembler's own IF is rewritten, and only a word standing alone in
    it: the structured statements the preprocessor left behind carry these
    words too, and INC/STRUC.INC is what takes those apart.
    """
    out = []
    for line in text.split('\n'):
        j = comment_at(line)
        code, note = (line, '') if j < 0 else (line[:j], line[j:])
        # RAMDRIVE writes its two assertions as IF((a - b) NE (c - d)),
        # with the bracket against the word, so the line is recognised by
        # either a space or a bracket after the IF.
        if re.match(r"(?i)^[ \t]*(?:ELSE)?IFE?[ \t(]", code):
            code = re.sub(r"(?i)(?<=\s)(" + '|'.join(MASMREL) + r")(?=\s)",
                          lambda m: MASMREL[m.group(1).upper()], code)
            # A connective between two comparisons is a logical one, which
            # fasm writes | and & where it writes OR and AND for the bits
            # of a number: DISPLAY's JUMP macro asks whether the label it
            # was given is ahead of here or further back than a short jump
            # reaches, IF (LBL&_J GE $) OR ($-LBL&_J GT 126), and fasm will
            # not have the one applied to the other.  Where both sides are
            # numbers the words are fasm's own and stand, which is what the
            # kernel's IF (NOT IBM) OR (debug) wants.
            if re.search(r"(?:>=|<=|<>|>|<|=)", code):
                code = re.sub(r"(?i)(?<=\s)(OR|AND)(?=\s)",
                              lambda m: '|' if m.group(1).upper() == 'OR'
                              else '&', code)
        out.append(code + note)
    return '\n'.join(out)


def switched(text):
    """The parser's switches, in the spellings the parser tests.

    RECPARSE.INC writes incsw and basesw in lower case, which MASM read as
    the same name as IncSW and BaseSW.  fasm minds the case, so PARSE.ASM
    would find neither set: incsw = 0 says "I have read PSDATA.INC myself"
    and basesw = 1 says "my data table is the one DS points at".
    """
    return re.sub(r"(?i)(?<![\w.])(" + '|'.join(SWITCHES) + r")(?![\w])",
                  lambda m: SWITCHES[m.group(1).upper()], text)

# = and not equ: fasm's equ is text put in where the name is used, so the $
# in it would be the address of the use and not the end of the buffer.  And
# MASM's SEG gave the segment a name lives in -- all of EXE2BIN's data is in
# DATA, and the file being converted is read into the last segment, ZLOAD.

# E2BMACRO.INC declares Procedure and INC/DOSMAC.INC declares procedure, and
# MASM saw one name: the later declaration, E2BMACRO's, is the one it used.
# MASM also took a macro's arguments apart on spaces as well as commas, so
# "procedure Main_Init near" passed two and the macro, having one parameter,
# dropped the near -- which was the default anyway.  fasm splits on commas
# only and minds the case, so the calls name the macro that was meant and
# say nothing more.
# MASM's SEG gave the segment a name lives in.  A fasm segment's name is
# that value: all of EXE2BIN's data is in DATA, and the file being converted
# is read into ZLOAD, the last of the four, which the source calls LOAD.
# Two of the values E2BTABLE.INC feeds its message macro are written with a
# segment on the front -- "Sublist = ds:sublist_msg_parserr" -- and the macro
# puts them in a DW, where what is wanted is the offset and MASM read the
# prefix as nothing.  The = stays: the modules are read once per segment, and
# an equate would still stand for the address on the next reading, where the
# name is given another value.
def split_dup(text):
    """A declaration that writes some bytes and then reserves more.

    EDLIN.ASM says TXT1 DB 0,80H DUP (?): one byte with a value and 128
    without.  fasm reserves room with a directive of its own, so the line is
    written as the two things it is, and the name still stands at the first
    of them.
    """
    def one(m):
        head, size, values, count, comment = m.groups()
        return ('%sd%s %s%s\n\tr%s      %s'
                % (head, size.lower(), values, comment or '',
                   size.lower(), count))

    text = re.sub(r"(?mi)^(" + N + r"?[ \t]+)D([BWD])[ \t]+"
                  r"([^;\n]*?),[ \t]*(\S+)[ \t]+dup[ \t]*\([ \t]*\?"
                  r"[ \t]*\)[ \t]*(;[^\n]*)?$", one, text)

    # and the other way about: CHKDATA.INC says MON_NAME DB 3 DUP (?),0,
    # three bytes without a value and one with.  The name stands at the
    # first of them here as it did there.
    def other(m):
        head, size, count, values, comment = m.groups()
        return ('%sr%s      %s%s\n\td%s %s'
                % (head, size.lower(), count, comment or '',
                   size.lower(), values))

    return re.sub(r"(?mi)^(" + N + r"?[ \t]+)D([BWD])[ \t]+(\S+)[ \t]+"
                  r"dup[ \t]*\([ \t]*\?[ \t]*\)[ \t]*,"
                  r"([^;\n]*?)[ \t]*(;[^\n]*)?$", other, text)


def offsets(text):
    """The segment a name is qualified with after OFFSET, taken off.

    EDLPARSE.ASM writes OFFSET ES:SW_B_SWITCH where it wants the address of
    that data and nothing else; the segment says nothing about a number.  The
    OFFSET itself stays until the operands have been read, so that the name
    after it is not taken for a place in memory.
    """
    # The name can stand in parentheses of its own, with no space in front
    # of them: PRINTER writes DW OFFSET(PRINTER_DESC1) for each of the
    # three printers it describes.  The parentheses say as little about a
    # number as the segment does, and with none of the space the rules
    # below look for the OFFSET would have stayed in the line.
    text = re.sub(r"(?i)\b(offset)[ \t]*\([ \t]*(" + N + r")[ \t]*\)",
                  lambda m: '%s %s' % (m.group(1), m.group(2)), text)
    text = re.sub(r"(?i)\b(offset[ \t]+)(?:cs|ds|es|ss)[ \t]*:[ \t]*",
                  lambda m: m.group(1), text)
    # The override can stand outside brackets that hold the OFFSET, and
    # the whole of it is still a number: RAMDRIVE loads the address it
    # wants the BIOS to come back to with
    #     mov word ptr [RealLoc1],cs:[offset ReturnBack]
    # where neither the brackets nor the CS: says anything about an
    # immediate.  Read as a reference it would be a move from one place in
    # memory to another, which no instruction of this processor does, and
    # fasm says so.  SMARTDRV writes the same line.
    text = re.sub(r"(?i)\b(?:cs|ds|es|ss):[ \t]*\[[ \t]*offset[ \t]+("
                  + N + r")[ \t]*\]", lambda m: 'offset ' + m.group(1), text)
    # MASM let the name stand in brackets after OFFSET as well, and the
    # brackets said no more there than the segment did: IFSUTIL asks twice
    # for OFFSET CS:[PHONEY_NAME], the name it hands the interrupt 24H
    # handler.  They have to come off with the segment, or the rules for
    # storage below read the whole of it as a place in memory and the
    # OFFSET falls away -- which is the same defect as an OFFSET that
    # became a read, by another road.
    return re.sub(r"(?i)\b(offset[ \t]+)\[[ \t]*(" + N + r"[^]\n]*?)"
                  r"[ \t]*\]", lambda m: m.group(1) + m.group(2), text)


# The structured statements INC/STRUC.INC takes a condition for.  A
# conjunction or a jump distance after one needs a comma, and THEN or DO
# after one is nothing at all.
# What a condition's operator can be called.  INC/STRUC.INC pastes the
# operator onto a j and lets the assembler read the mnemonic, which is what
# MASM's own library did, so the processor's every name for a condition is
# an operator as well as the library's own EQ, LT and GT: ANSI asks
# <[SI].SCR_ROWS E UNOCCUPIED>, which is the processor's name for equal, and
# GRAPHICS asks <AX A MAX_BLOCK_END> and <DI NA MAX_STMT_LEN>.  A rule that
# does not know the name leaves the condition's operands as they stand,
# which for a name that stands for storage is the address and not what is
# at it.
# Z and NZ are left out of it: they are how a bit test reads its answer --
# <BIT CS:HDWR_FLAG AND EGA> NZ -- and the rule for a bit test owns them.
RELOPS = (r"ABOVE|BELOW|NONZERO|ZERO|NAE|NBE|NGE|NLE|NLT|NGT|PE|PO|"
          r"NA|NB|NC|NE|NG|NL|NO|NP|NS|AE|BE|GE|LE|EQ|LT|GT|AB|BL|"
          r"A|B|C|E|G|L|O|P|S")
STATEMENTS = r"(?:IF|ELSEIF|WHILE|UNTIL|REPEAT|WHEN|LEAVE|EXITIF|SELECT)"
# A statement, its condition taken apart into the two sides of a comparison
# and the operator between them, with whatever follows the condition kept.
CONDITION = re.compile(r"(?i)^([ \t]*(?:" + N + r":)?[ \t]*)(\." + STATEMENTS
                       + r")[ \t]+"
                       r"<[ \t]*(.*?)[ \t]+"
                       r"(" + RELOPS + r")[ \t]+"
                       # as far as the last bracket, because MASM put its own
                       # round an operand of more than one word
                       r"(.*)[ \t]*>[ \t]*(.*)$")


def distances(text):
    """A conjunction or a jump distance after a structured statement's
    condition, which needs a comma in front of it.

    fasm's angle brackets close the argument they enclose, as INC/STRUC.INC
    says of itself, so .IF <AX EQ 0> AND has to be written .IF <AX EQ 0>,
    AND.  MODE writes a hundred and seventy-two of them, which is what
    MASM's own library took without one.
    """
    def one(m):
        words = re.findall(r"(?i)\b(AND|OR|NEAR|FAR|SHORT|LONG)\b",
                           m.group(2))
        return '%s%s%s' % (m.group(1),
                           ''.join(', ' + w.upper() for w in words),
                           '\t' + m.group(3) if m.group(3) else '')

    # MODE writes both at once -- .WHILE <cond> AND NEAR -- so a run of them
    # is taken together.
    return re.sub(r"(?mi)^([ \t]*(?:" + N + r":)?[ \t]*\." + STATEMENTS + r"\b"
                  r"[^;\n]*?[^;,\s])"
                  r"((?:[ \t]+(?:AND|OR|NEAR|FAR|SHORT|LONG)\b)+)"
                  r"[ \t]*(;[^\n]*)?$", one, text)


# MASM's conditionals: what opens one, what divides it and what closes it.
# ELSEIF does neither, so what tells it from the ELSE that divides one is
# that nothing follows the word.
CONDOPEN = re.compile(r"(?i)^[ \t]*IF(?:1|2|E|B|NB|DEF|NDEF|IDNI?|DIFI?)?\b")
CONDELSE = re.compile(r"(?i)^[ \t]*ELSE[ \t]*$")
CONDEND = re.compile(r"(?i)^[ \t]*ENDIF\b")


def else_ahead(lines, i):
    """Whether the conditional opened on line i has an ELSE of its own."""
    level = 0
    for line in lines[i + 1:]:
        code = code_of(line)
        if CONDOPEN.match(code):
            level += 1
        elif CONDEND.match(code):
            if not level:
                return False
            level -= 1
        elif not level and CONDELSE.match(code):
            return True
    return False


def blankness(text, stem):
    """What a macro asked about its own arguments: IFB and IFNB, whether one
    was given at all, and IFIDN and IFDIF, whether one is a particular word.

    fasm asks all of them with MATCH: against nothing for IFB, against a
    name that takes whatever there is for IFNB, and against the word itself,
    marked with an =, for IFIDN.  The braces are the macro's own, so they are
    escaped -- once for each block they stand inside, which is the macro and
    any IRP and MATCH around them -- and the ENDIF that closes one of these
    is a brace rather than an END IF.  MODE writes five of the first kind,
    which is what lets SCRN take a mode as well as a function, and APPEND's
    JUMP is twenty of the third -- one per condition a long conditional jump
    can carry.

    MASM's IFIDN reads the same either way round, where fasm's MATCH has a
    pattern and a text to match it against, so the operand that is the
    macro's own parameter is taken for the text.

    A MATCH is a block and not a conditional, and there is nothing in it to
    write an ELSE as.  Where one follows, the answer is kept in a flag: a
    MATCH of one line sets it and each branch is a MATCH that reads it, which
    is the shape INC/STRUC.INC uses to try one reading of a condition after
    another.  IFDIF is written that way whatever follows it, fasm having no
    MATCH for what a text is not -- the flag starts idn$yes and the MATCH
    that finds the word puts it to idn$no.  The two values carry the same
    mark as the flag because a program may have names of its own called yes
    and no, and the spellings those are written at are settled later.  XMAEM's INDEINS.MAC wants both: its macros
    hand-assemble the 386's instructions, and they read which register they
    were given by matching its name against a list of them.

    A conditional that is none of these opens no block of its own and is
    counted all the same, the ENDIF that closes it having to be told from the
    one that closes a MATCH around it.  F_MOD asks IFB whether it was given a
    displacement and asks IFE how long the displacement is inside the answer.
    """
    mark = stem.split('.')[0].lower()
    lines = text.split('\n')
    # What is open: a macro, or one of the IRP and REPT blocks that close
    # with ENDM as a macro does.  NLSFUNC's DOESMAC.INC declares a macro
    # inside a macro and SaveReg closes an IRP and itself with two ENDMs in
    # a row, so counting the ENDMs is the only way to know which one ends
    # the macro the IFNBs are in.
    out, nest, depth, params, flags = [], [], [], set(), [0]

    def braces():
        """The backslashes a brace of ours wants: one for each block it
        stands inside.  A REPT is fasm's REPEAT, which closes with two words
        of its own and not with a brace, so it is not one of them."""
        return '\\' * (len([n for n in nest if n != 'rept'])
                       + len([d for d in depth if d]) - 1)

    def flagged(lead, pattern, said, start, note):
        """The flag, the MATCH that sets it and the MATCH that reads it."""
        flags[0] += 1
        flag = 'idn$%s%d' % (mark, flags[0])
        depth.append(('flag', flag))
        out.append('%sdefine %s idn$%s' % (lead, flag, start))
        out.append('%smatch %s, %s %s{ define %s idn$%s %s}'
                   % (lead, pattern, said, braces(), flag,
                      'no' if start == 'yes' else 'yes', braces()))
        out.append('%smatch =idn$yes, %s %s{%s'
                   % (lead, flag, braces(), note))

    for i, line in enumerate(lines):
        code = code_of(line)
        note = line[len(code):]
        inmacro = 'macro' in nest
        m = MACRODEF.match(code)
        if m:
            nest.append('macro')
            depth = []
            params = {w.strip().lower()
                      for w in re.split(r"[ \t,]+", m.group(2))
                      if w.strip()}
            out.append(line)
            continue
        m = re.match(r"(?i)^[ \t]*(IRP|IRPC|REPT)\b[ \t]*([^;]*?)[ \t]*$", code)
        if m:
            # A REPT with two words after it is fasm's own, written by the
            # rules for an array of structures, and carries its braces with
            # it: it opens nothing here.
            if m.group(1).upper() == 'REPT' \
                    and re.match(r"^\S+[ \t]+" + N + r"$", m.group(2)):
                out.append(line)
                continue
            nest.append('rept' if m.group(1).upper() == 'REPT' else 'irp')
            out.append(line)
            continue
        if nest and MACROEND.match(code):
            nest.pop()
            out.append(line)
            continue
        m = re.match(r"(?i)^([ \t]*)IF(IDN|DIF)I?[ \t]+<(.*?)>[ \t]*,"
                     r"[ \t]*<(.*?)>[ \t]*$", code)
        if inmacro and m:
            lead, which = m.group(1), m.group(2).upper()
            left, right = m.group(3).strip(), m.group(4).strip()
            said, word = left, right
            if left.lower() not in params and right.lower() in params:
                said, word = right, left
            pattern = ' '.join('=' + w for w in word.split())
            if which == 'DIF':
                flagged(lead, pattern, said, 'yes', note)
            elif else_ahead(lines, i):
                flagged(lead, pattern, said, 'no', note)
            else:
                depth.append(('match',))
                out.append('%smatch %s, %s %s{%s'
                           % (lead, pattern, said, braces(), note))
            continue
        m = re.match(r"(?i)^([ \t]*)IF(N?)B[ \t]+<(.*?)>[ \t]*$", code)
        if inmacro and m:
            # The braces are the macro's own, and one inside another wants
            # a backslash for every level it is in: MODECPEQ's DOSCALL asks
            # about its function and then about its subfunction.
            depth.append(('blank', m.group(3), bool(m.group(2))))
            out.append('%smatch %s, %s %s{%s'
                       % (m.group(1), 'any$' if m.group(2) else '',
                          m.group(3), braces(), note))
            continue
        # A conditional of the assembler's own, which stands as it is and is
        # counted so that its ENDIF is not taken for one of ours.
        if inmacro and CONDOPEN.match(code):
            depth.append(None)
            out.append(line)
            continue
        # The other way round: what MASM wrote after an ELSE is what there
        # is to do when the argument is the other thing, which is a MATCH of
        # its own.  MODECPEQ writes one, for a call with no subfunction.
        m = CONDELSE.match(code)
        if inmacro and m and depth and depth[-1] \
                and depth[-1][0] in ('blank', 'flag'):
            lead = re.match(r"^[ \t]*", code).group(0)
            out.append('%s%s}%s' % (lead, braces(), note))
            if depth[-1][0] == 'flag':
                out.append('%smatch =idn$no, %s %s{'
                           % (lead, depth[-1][1], braces()))
            else:
                name, given = depth[-1][1], depth[-1][2]
                out.append('%smatch %s, %s %s{'
                           % (lead, '' if given else 'any$', name, braces()))
            continue
        m = re.match(r"(?i)^([ \t]*)ENDIF\b", code)
        if inmacro and m and depth:
            if depth[-1]:
                out.append('%s%s}%s' % (m.group(1), braces(), note))
                depth.pop()
            else:
                depth.pop()
                out.append(line)
            continue
        out.append(line)
    return '\n'.join(out)


def quoted_parameters(text):
    """A macro's parameter inside a quoted string, which MASM substituted
    there as it did anywhere else.

    fasm does not read inside a string, and has ` instead: it gives the text
    of the argument a parameter stands for as a string of its own, so a
    string with a parameter in the middle of it becomes the list of pieces it
    was made of.  XMAEM's INDEEXC declares one entry of its table of
    registers per register, and the name it writes on the screen is the name
    of the register itself -- DB '&NAME:' -- which is the one in the release.
    """
    def pieces(m, params):
        quote, inner, out = m.group(0)[0], m.group(0)[1:-1], []
        for part in re.split(r"&(" + N + r")", inner):
            if part == '':
                continue
            out.append('`' + part if part.lower() in params
                       else quote + part + quote)
        return ', '.join(out) or quote + quote

    out, params = [], set()
    for line in text.split('\n'):
        code = code_of(line)
        note = line[len(code):]
        m = MACRODEF.match(code)
        if m:
            params = {w.strip().lower()
                      for w in re.split(r"[ \t,]+", m.group(2)) if w.strip()}
        elif MACROEND.match(code):
            params = set()
        if params and re.search(r"['\"][^'\"\n]*&" + N, code):
            code = re.sub(r"'[^'\n]*'|\"[^\"\n]*\"",
                          lambda m: pieces(m, params), code)
        out.append(code + note)
    return '\n'.join(out)


def substituted(text):
    """MASM's & in front of a macro's parameter, which fasm does not want.

    MASM substituted a parameter where it stood as a word of its own, and an
    & in front of it said to substitute it here as well -- which is what
    <&REG1> asked for, the angle brackets otherwise being part of the word.
    fasm substitutes a parameter wherever its name stands and has nothing to
    do with the &, which it would read as part of the name.  XMAEM's macros
    are written this way throughout: IFIDN <&REG1>,<&TREG> asks which
    register the caller named.

    An & between two names is MASM's paste, and that one stays for pasted()
    to write as fasm's #.  It is the & that stands before a name and after
    something which is not one that goes.
    """
    out = []
    for line in text.split('\n'):
        j = comment_at(line)
        code, note = (line, '') if j < 0 else (line[:j], line[j:])
        out.append(re.sub(r"(?<![\w?$@])&(?=[\w?$@])", '', code) + note)
    return '\n'.join(out)


def pasted(text):
    """MASM pasted a macro's argument on to a name with &, and fasm with #.

    MODE builds the label a case jumps to out of the case's name --
    JMP ENDCASE_&destination -- and the sublist a message addresses out of
    the message's.  Both sides of the & are part of a name, which is what
    tells it from an ampersand in a string.
    """
    out = []
    for line in text.split('\n'):
        j = comment_at(line)
        code, note = (line, '') if j < 0 else (line[:j], line[j:])
        out.append(re.sub(r"(?<=[\w?$@])&(?=[\w?$@])", '#', code) + note)
    return '\n'.join(out)


def counters(text):
    """A counted loop's counter, in brackets of its own, and read from
    memory where it is kept there.

    INC/STRUC.INC takes the .FOR line apart with fasm's MATCH, which splits
    it into its tokens, so the counter arrives as a group of its own: MODE
    counts with SI in one loop and with a byte called i in another.
    """
    def one(m):
        head, place, rest, note = (m.group(1), m.group(2).strip(),
                                   m.group(3).strip(), m.group(4))
        if place.lower() in DATA:
            place = '[%s]' % place
        return '%s<<%s> %s>%s' % (head, place, rest,
                                  '\t' + note if note else '')

    # The whole of it goes in brackets, because fasm's angle brackets close
    # the argument they enclose: the counter in brackets on its own would be
    # the argument and the rest would be left over.
    return re.sub(r"(?mi)^([ \t]*\.FOR[ \t]+)(" + N + r")[ \t]*"
                  r"(=[^;\n]*?)[ \t]*(;[^\n]*)?$", one, text)


def for_loops(text, stem):
    """MASM's counted loop, as the instructions it stood for.

    INC/STRUC.INC writes the conditional statements but not .FOR and .NEXT,
    nothing else in the release having used them; MODE's four are written out
    here instead, with labels named after the module they are in.  The
    counter is tested before the body, as MASM's library tested it, and the
    step is one where none is given.  The increment stands at the top of the
    loop and the loop is entered at the test, so that what .NEXT lays down
    is the one jump back.  Nothing in MODE leaves a .FOR early, so the loop
    wants no place on the stack the conditional statements keep.
    """
    mark = stem.split('.')[0].lower()
    out, stack, n = [], [], 0
    for line in text.split('\n'):
        code = code_of(line)
        note = line[len(code):]
        m = re.match(r"(?i)^([ \t]*)\.FOR[ \t]+<<(.*?)>[ \t]*=[ \t]*(.*?)"
                     r"[ \t]+TO[ \t]+(.*?)"
                     r"(?:[ \t]+STEP[ \t]+(.*?))?[ \t]*>[ \t]*$", code)
        if m:
            n += 1
            lead, place, frm, to = (m.group(1), m.group(2), m.group(3),
                                    m.group(4))
            step = m.group(5) or '1'
            top = 'for$%s%d_top' % (mark, n)
            test = 'for$%s%d_test' % (mark, n)
            done = 'for$%s%d_out' % (mark, n)
            stack.append((lead, top, done))
            out.append('%s; .FOR %s = %s TO %s%s%s'
                       % (lead, place, frm, to,
                          '' if m.group(5) is None else ' STEP ' + step, note))
            out.append('%smov\t%s, %s' % (lead, place, frm))
            out.append('%sjmp\t%s' % (lead, test))
            out.append('%s:' % top)
            out.append('%sadd\t%s, %s' % (lead, place, step))
            out.append('%s:' % test)
            out.append('%scmp\t%s, %s' % (lead, place, to))
            out.append('%sja\t%s' % (lead, done))
            continue
        m = re.match(r"(?i)^([ \t]*)\.NEXT\b", code)
        if m and stack:
            lead, top, done = stack.pop()
            out.append('%s; .NEXT%s' % (m.group(1), note))
            out.append('%sjmp\t%s' % (lead, top))
            out.append('%s:' % done)
            continue
        out.append(line)
    return '\n'.join(out)


def conditions(text):
    """A structured statement's left operand, in brackets of its own where
    it is more than one word.

    INC/STRUC.INC takes a condition apart with fasm's MATCH, which splits it
    into tokens, so a left operand of more than one -- [cs:request], or the
    word at a place -- has to arrive as a group of its own.  MASM's library
    did its own splitting and took CS:request as it stood; where MASM needed
    the brackets the sources have them already, as <<WORD PTR ES:[SI]> NE 0>.
    """
    OPS = r"(?:" + RELOPS + r")"

    def place(word):
        """A bare name of storage, in the brackets a condition needs.

        The rules that bracket an instruction's operands do not reach inside
        a condition, which is macro text until STRUC.INC takes it apart, so
        a name there is bracketed here.
        """
        if re.match(r"^" + N + r"$", word) and word.lower() in WIDE:
            return '<%s>' % word
        return ('[%s]' % word
                if re.match(r"^" + N + r"$", word) and word.lower() in DATA
                else word)

    # A bit test is written the other way about -- BIT, the place, how to
    # read the answer, and the bits asked for -- and its operators are the
    # ones a TEST leaves in the zero flag.  GRINST tests the switches at
    # BP with <BIT CS:[BP].SWITCHES NZ BACKGROUND_SW>, which is four words
    # where MATCH can take three, so the place goes in brackets of its own
    # the way a comparison's does; STRUC.INC has a shape for that.
    BITOPS = r"(?:NZ|Z|AND|NAND)"

    def bit(m):
        head, cond, tail = m.group(1), m.group(2), m.group(3)
        inner = re.match(r"(?i)^[ \t]*bit[ \t]+(.*?)[ \t]+(" + BITOPS
                         + r")[ \t]+(.*)$", cond)
        if not inner:
            return m.group(0)
        left = place(inner.group(1).strip())
        if left.startswith('<') or not re.search(r"[\s\[\]:]", left):
            return m.group(0)
        return '%s<BIT <%s> %s %s>%s' % (head, left, inner.group(2),
                                         inner.group(3).strip(), tail)

    def one(m):
        head, cond, tail = m.group(1), m.group(2), m.group(3)
        inner = re.match(r"(?i)^[ \t]*(.*?)[ \t]+(" + OPS + r")[ \t]+(.*)$",
                         cond)
        if not inner:
            return m.group(0)
        left, right = place(inner.group(1).strip()), \
            place(inner.group(3).strip())
        # A reference with nothing in it to take a width from, against an
        # immediate too wide for a byte: MASM sized the one from the other
        # and compared words.  GRCTRL asks <ES:[DI] EQ 5140H>, the two
        # characters an LCD display answers with.  The width is said the
        # way the release says it where it says it at all -- WORD PTR,
        # which the rules for a size turn into fasm's own.  FASTINIT has
        # the same shape outside a condition and says so on the line.
        if re.match(r"(?i)^(?:(?:cs|ds|es|ss):)?\[[^\]]*\]$", left) \
                and not re.search(N, re.sub(r"(?i)\b(?:cs|ds|es|ss|"
                                            r"[abcd]x|[abcd][lh]|si|di|bp|sp)"
                                            r"\b", '', left)) \
                and re.match(r"(?i)^[0-9][0-9A-F]*H?$", right) \
                and int(right.rstrip('Hh'), 16 if right[-1] in 'Hh' else 10) \
                > 0xFF:
            left = 'WORD PTR ' + left
        if left.startswith('<') or not re.search(r"[\s\[\]:]", left):
            if right == inner.group(3).strip():
                return m.group(0)
            return '%s<%s %s %s>%s' % (head, left, inner.group(2), right, tail)
        return '%s<<%s> %s %s>%s' % (head, left, inner.group(2), right, tail)

    head = (r"(?mi)^([ \t]*(?:" + N + r":)?[ \t]*\." + STATEMENTS
            + r"\b[ \t]+)")
    text = re.sub(head + r"<([^<>]*)>(.*)$", bit, text)
    return re.sub(head + r"<([^<>]*)>(.*)$", one, text)


def thens(text):
    """THEN and DO after a structured statement's condition, which MASM's
    library only looked for.

    INC/STRUC.INC takes the condition in brackets of its own and has nothing
    to put either word in; fasm reads one as a second argument with no comma
    in front of it, and will not have it.  MODE writes twenty-two THENs and
    a handful of DOs.
    """
    def one(m):
        head, tail, comment = m.group(1), m.group(2), m.group(3)
        tail = re.sub(r"\s+", ' ',
                      re.sub(r"(?i)\b(?:THEN|DO)\b", ' ', tail)).strip()
        return '%s%s%s' % (head, ' ' + tail if tail else '',
                           '\t' + comment if comment else '')

    # a condition in brackets, and whatever MASM allowed after it
    text = re.sub(r"(?mi)^([ \t]*(?:" + N + r":)?[ \t]*\." + STATEMENTS + r"\b"
                  r"[^;\n]*>)([^;\n]*?)[ \t]*(;[^\n]*)?$", one, text)
    # or a flag, which needs none
    return re.sub(r"(?mi)^([ \t]*(?:" + N + r":)?[ \t]*\." + STATEMENTS + r"\b"
                  r"[^;\n<>]*?)[ \t]+(?:THEN|DO)\b", r"\1", text)


def places(text):
    """An EQU that names a place rather than a number.

    GRTABHAN says PATCH_OFF EQU WORD PTR $-2 for the immediate of the
    instruction just assembled, which its loader patches, and PREV_OWN EQU
    DWORD PTR JMPREV+1 for the address inside a far jump.  fasm's EQU is text
    put in where the name is used, so a $ in it would be the address of the
    use; LABEL names a place of a given size at an address taken where it is
    written, which is what MASM's EQU did here.

    MASM's THIS is the same thing at the address the line is on, which is
    how each of GRAFTABL's character tables names its own beginning:
    TABLEUS EQU THIS BYTE.
    """
    # A size in front of a place that is reached through a register is a
    # name for the whole reference, and not for an address: NLSFUNC says
    # FILESPEC_PTR EQU BYTE PTR DS:[IN_DEX] for the character its loop is
    # on, where IN_DEX is BP, and reads it as a whole operand.  That one
    # keeps its brackets and stays an EQU, fasm's being the text put in
    # where the name is used, which is what MASM's was here.
    text = re.sub(r"(?mi)^(" + N + r")([ \t]+)EQU([ \t]+)"
                  r"(byte|word|dword|qword)[ \t]+ptr[ \t]+"
                  r"((?:cs|ds|es|ss):)?[ \t]*\[([^\]]+)\][ \t]*"
                  r"(;[^\n]*)?$",
                  lambda m: '%s%sequ%s%s [%s%s]%s' % (
                      m.group(1), m.group(2), m.group(3), m.group(4).lower(),
                      (m.group(5) or '').lower(), m.group(6),
                      '\t' + m.group(7) if m.group(7) else ''),
                  text)
    text = re.sub(r"(?mi)^(" + N + r")[ \t]+EQU[ \t]+"
                  r"(byte|word|dword|qword)[ \t]+ptr[ \t]+"
                  r"([^;\n]+?)[ \t]*(;[^\n]*)?$",
                  lambda m: 'label %s %s at %s%s' % (
                      m.group(1), m.group(2).lower(), m.group(3).strip(),
                      '\t' + m.group(4) if m.group(4) else ''),
                  text)
    # An EQU whose body is a memory operand, which MODELENG uses to name
    # the BIOS date it walks with ES:DI and then reads a field of: the
    # brackets come off, so that the name can stand inside brackets of its
    # own wherever it is read.
    text = re.sub(r"(?mi)^(" + N + r")([ \t]+)EQU([ \t]+)"
                  r"((?:cs|ds|es|ss):)?[ \t]*\[([^\]]+)\][ \t]*"
                  r"(;[^\n]*)?$",
                  lambda m: '%s%sequ%s%s%s%s' % (
                      m.group(1), m.group(2), m.group(3),
                      (m.group(4) or '').lower(), m.group(5),
                      '\t' + m.group(6) if m.group(6) else ''),
                  text)
    return re.sub(r"(?mi)^(" + N + r")[ \t]+EQU[ \t]+THIS[ \t]+"
                  r"(byte|word|dword|qword)[ \t]*(;[^\n]*)?$",
                  lambda m: 'label %s %s%s' % (
                      m.group(1), m.group(2).lower(),
                      '\t' + m.group(3) if m.group(3) else ''),
                  text)


def grouped_equ(text):
    """An EQU whose value is an expression, in brackets of its own.

    MASM worked an EQU out where it was written, so GRTAB's SHIFT_SIZE_SEG
    EQU SHIFT_SIZE SHR NIBBLE_SIZE shifted the whole of SHIFT_SIZE.  fasm's
    EQU is text put in where the name is used, and there the operators around
    it bind as they will: SHIFT_SIZE is itself END_PSP-MOV_DEST, so what came
    out was END_PSP minus MOV_DEST shifted -- 0FAh where MASM had 0Ah, and
    a resident handler addressed through the wrong segment.  The brackets say
    what MASM meant, and leave the EQU able to look forward, which = is not.
    """
    def one(m):
        body = m.group(3).strip()
        if ',' in body or "'" in body or '"' in body:
            return m.group(0)
        # A value with brackets in it is a place and not a number, and the
        # brackets round it are its own: XMA2EMS reads the page allocation
        # list through PAGE_LIST_ENTRY EQU WORD PTR[SI + OFFSET
        # PAGE_ALLOC_LIST], and a pair of ours in front of that would make
        # a memory operand into something fasm cannot read at all.
        if '[' in body:
            return m.group(0)
        if not re.search(r"[-+*/]|\b(?:shl|shr|mod|and|or|xor|not)\b",
                         body, re.I):
            return m.group(0)
        return '%sequ%s(%s)%s' % (m.group(1), m.group(2), body,
                                  '\t' + m.group(4) if m.group(4) else '')

    return re.sub(r"(?mi)^(" + N + r"[ \t]+)equ([ \t]+)([^;\n]+?)[ \t]*"
                  r"(;[^\n]*)?$", one, text)


def dollar_equ(text):
    """A length worked out from the address counter, which EQU cannot hold.

    fasm's EQU is text put in where the name is used, so a $ in it would be
    the address of the use and not of the line that works the length out.
    The = takes its value where it is written, which is what MASM's EQU did.
    """
    said = [False]

    def one(m):
        head = ('' if said[0] else
                '; = and not equ: fasm\'s equ is text put in where the name is'
                ' used, so a $\n; in it would be the address of the use and not'
                ' of this line.\n')
        said[0] = True
        return '%s%s=%s%s' % (head, m.group(1), m.group(2), m.group(3))

    return re.sub(r"(?mi)^([ \t]*" + N + r"[ \t]+)EQU([ \t]+)"
                  r"([^;'\"\n]*\$[^;'\"\n]*)", one, text)


# And the ones a macro compares by name, which must not be an EQU either:
# fasm substitutes an EQU on a macro's call line before the macro sees it,
# so a name handed to a macro that asks IFIDN what it is would arrive as its
# own number and match nothing.  KEYBOARD's FIND_FLAG is handed a flag mask
# by name and asks which of the four flag bytes it belongs to, and every
# IFF and ANDF in the twenty layouts goes through it.
FORWARD = tuple(U.get('FORWARD', ())) + tuple(U.get('NUMERIC', ()))


def forwards(text):
    """An EQU a header read earlier in the module has already used.

    MASM took two passes and resolved the name on the second; fasm's EQU is
    text put in where the name is used, and a name used before its EQU means
    nothing at all.  The = is a number fasm resolves wherever it stands, so
    the ones the table names become that: NLSFUNC declares PAD_CHAR after
    the eleven headers it reads, and MSG2NLS.INC lays three of them down.

    NUMERIC names go the same way for the other reason: fasm substitutes an
    EQU on a macro's call line before the macro sees it, so a name handed to
    a macro that asks what it is -- MASM's IFIDN, fasm's MATCH -- arrives as
    its own number and matches nothing.  An = is not substituted, and the
    name arrives as the name.
    """
    if not FORWARD:
        return text
    return re.sub(r"(?mi)^([ \t]*(?:" + "|".join(FORWARD) + r")[ \t]+)"
                  r"EQU([ \t]+)", r"\1=\2", text)


def records(text):
    """SF_BITS <...>, the byte MASM's RECORD packed four fields into.

    INC/MSGHAN.INC declared it as RECORD F_ALIGN:1,F_RES:1=0,F_SIZE:2,
    F_TYPE:4 -- F_ALIGN in bit 7, F_RES in 6, F_SIZE in 5 and 4, F_TYPE in 3
    to 0.  fasm has no RECORD and the byte is wanted where a value goes,
    inside a SUBLIST, so the shifts are written there as COMPMS.INC's are.
    """
    def one(m):
        parts = [p.strip() for p in m.group(1).split(',')]
        while len(parts) < 4:
            parts.append('')
        return '(%s shl 7) or (%s shl 4) or %s' % (parts[0] or '0',
                                                   parts[2] or '0',
                                                   parts[3] or '0')
    return re.sub(r"SF_BITS\s*<([^>]*)>", one, text)


def record_fields(text):
    """MASM's RECORD, which fasm has nothing of its own for.

    A RECORD packs its fields into a byte or a word from the top down, and
    the name of a field is the number of bits to shift it by: MODEVID
    declares FLAG RECORD PR:2,...,VIDEO:2,RAM:2,NA3:1,IPL:1 for the
    equipment flag the ROM BIOS keeps at 40:10, and asks for MASK VIDEO to
    clear the two bits that say which display is attached.  So each field is
    written as the shift it stands for, and MASK as the bits it covers.
    """
    masks = {}

    def one(m):
        indent, name, body, note = (m.group(1), m.group(2), m.group(3),
                                    m.group(4) or '')
        fields = []
        for part in body.split(','):
            f, _, w = part.partition(':')
            if not w.strip().isdigit():
                return m.group(0)
            fields.append((f.strip(), int(w.strip())))
        total = sum(w for _, w in fields)
        out = ['%s;%s\tRECORD\t%s%s' % (indent, name, body, note),
               '%s; MASM packed those into %d bits from the top down; the name'
               ' of a field is' % (indent, total),
               '%s; the shift it stands for, and MASK of it the bits it'
               ' covers.' % indent]
        at = total
        for f, w in fields:
            at -= w
            masks[f.lower()] = ((1 << w) - 1) << at
            out.append('%s%s = %d' % (indent, f, at))
        return '\n'.join(out)

    text = re.sub(r"(?mi)^([ \t]*)(" + N + r")[ \t]+RECORD[ \t]+"
                  r"([A-Za-z0-9_@?$:, \t]+?)[ \t]*(;[^\n]*)?$", one, text)
    if masks:
        text = re.sub(r"(?i)\bMASK[ \t]+(" + N + r")\b",
                      lambda m: ('0%Xh' % masks[m.group(1).lower()]
                                 if m.group(1).lower() in masks
                                 else m.group(0)), text)
    return text


def tabled(text):
    return re.sub(r"(?mi)^([ \t]*" + N + r"[ \t]+=[ \t]+)(?:ds|es|cs|ss):",
                  lambda m: m.group(1), text)


# MASM took a macro's arguments apart on spaces as well as commas, so
# "procedure report,near" and "procedure Main_Init near" both passed two and
# the macro, having one parameter, dropped the near -- which was the default
# anyway.  fasm splits on commas only, so the near goes here.
PROCEDURE = (re.compile(r"(?mi)^procedure([ \t]+)(" + N
                        + r")(?:[ \t]*,[ \t]*|[ \t]+)(?:near|far)\b"),
             lambda m: 'Procedure' + m.group(1) + m.group(2))


# Which structure each field belongs to.  MASM's fields were names of their
# own, so [BP].FRAM_CHAR said all it needed to; fasm takes the offset from
# the structure it was laid out in.
FIELD = {}
# And how wide each one is, for a reference that has to say so.
FIELDSIZE = {}
# And which structure a field holds, where its room is another structure's:
# INC/FASTOPEN.INC gives NAME_RECORD a .nCmpct_Dir_Info of
# sizeof.CMPCT_DIR_INFO bytes, and FASTOPEN reads the cluster in it as
# [bp.nCmpct_Dir_Info.CDI_cluster] -- a field of the one inside a field of
# the other.
HOLDS = {}
for text in SEEN:
    here = None
    for line in text.split('\n'):
        m = re.match(r"(?i)^STRUC\s+(" + N + r")", line)
        if m:
            here = m.group(1)
        m = re.match(r"(?i)^[ \t]*\.(" + N + r")(?:[ \t]+(d[bwdq]|r[bwd])\b)?",
                     line)
        if m and here:
            FIELD[m.group(1).upper()] = (here, m.group(1))
            if m.group(2):
                FIELDSIZE[m.group(1).upper()] = {'b': 'byte', 'w': 'word',
                                                 'd': 'dword', 'q': 'qword'
                                                 }[m.group(2)[1].lower()]
            held = re.search(r"(?i)\bsizeof\.(" + N + r")\b", line)
            if held:
                HOLDS[m.group(1).upper()] = held.group(1)


# Everything the program gives a name to, so that a name which is only a
# field of a structure can be told from one that is something in its own
# right.
DECLARED = set()
# And the ones it gives a colon, which are MASM's NEAR labels: a label's
# type is NEAR whatever is laid down under it, so a field written on one is
# an address and not what is at it.  XMA2EMS builds the parser's switch
# control block by hand under X_Switch: and compares the pointer the parser
# gave back with X_Switch.P_KeyorSW, the address of the switch's own name.
LABELLED = set()
for text in SEEN:
    for line in text.split('\n'):
        code = code_of(line)
        m = re.match(r"^[ \t]*(" + N + r")[ \t]*:", code)
        if m:
            LABELLED.add(m.group(1).lower())
        for pat in (r"^[ \t]*(" + N + r"):",
                    r"^[ \t]*(" + N + r")[ \t]+(?:d[bwdq]|r[bwd]|equ|=)\b",
                    r"^[ \t]*label[ \t]+(" + N + r")\b",
                    r"^[ \t]*(" + N + r")[ \t]+label\b",
                    r"^[ \t]*macro[ \t]+(" + N + r")\b",
                    r"^[ \t]*STRUC[ \t]+(" + N + r")\b",
                    r"^[ \t]*Procedure[ \t]+(" + N + r")\b",
                    r"^[ \t]*(" + N + r")[ \t]+proc\b"):
            m = re.match(pat, code, re.I)
            if m:
                DECLARED.add(m.group(1).lower())


def bare_fields(text):
    """A field of a structure written on its own, which MASM read as the
    offset of that field.  DISKCOMP.EQU says VOL_SERIAL EQU EXT_BOOT_SERIAL,
    and that is a field of the boot record INC/BOOTFORM.INC lays out, so the
    name takes the structure it belongs to."""
    def one(m):
        path = m.group(1).split('.')
        name, rest = path[0], path[1:]
        found = FIELD.get(name.upper())
        if found is None or name.lower() in DECLARED:
            return m.group(0)
        # A word the assembler keeps for itself is not a field, whatever a
        # structure calls its own: one of MODE's is called ENDIF.
        if name.upper() in ('ENDIF', 'ENDM', 'IFB', 'IFNB', 'IFE', 'IFDEF',
                            'IFNDEF', 'ELSE', 'IF', 'IF1', 'IF2', 'ENDP',
                            'ENDS', 'PROC', 'MACRO', 'STRUC', 'RECORD'):
            return m.group(0)
        # SIZE, LENGTH and TYPE take the field's own name, and the rules for
        # them work the number out from its declaration: GRTAB says
        # TABSIZE EQU SIZE LANCHAR + SIZE LANID + SIZE LANNAME.
        if re.search(r"(?i)\b(?:size|length|type)[ \t]+$", m.string[:m.start()]):
            return m.group(0)
        # Two field names joined by a dot, which MASM added the offsets of:
        # each of them is a number and the dot said nothing more than the
        # plus does.  XMAEM's INDEINI loads the descriptor of the scrubber's
        # task with MOV AX,SCRUBBER.TSS_PTR, where SCRUBBER is the room one
        # virtual machine's entry takes in the descriptor table and TSS_PTR
        # is a word of such an entry -- two structures, and MASM read a
        # field's name wherever it was declared.
        more = [FIELD.get(p.upper()) for p in rest]
        if rest and all(f is not None for f in more):
            return '+'.join('%s.%s' % f for f in [found] + more)
        return '.'.join(['%s.%s' % found] + rest)

    out = []
    for line in text.split('\n'):
        j = comment_at(line)
        code, comment = (line, '') if j < 0 else (line[:j], line[j:])
        if not re.match(r"[ \t]*\.", code):
            # the quotes are left alone: MODEPARS declares the parser's
            # keyword as DB "COLS=",0, and cols is a field of the structure
            # INVOKE describes an IOCTL 0CH call with
            code = outside_strings(r"(?<![\w.$])(" + N + r"(?:\." + N
                                   + r")*)", one, code)
        out.append(code + comment)
    return '\n'.join(out)


# The address spaces the program has, and the fasm segment that is each of
# them.  A group is one address space whatever segments it covers, so every
# segment of a group stands for the group; a program with no group -- FORMAT
# is the first of those -- has one address space per segment, and a segment
# stands for itself.  Either way the name of the fasm segment is the name in
# the source with an underscore after it, as RECOVER's and EDLIN's DG_ is.
SEGNAME = {}
for text in source.values():
    for m in re.finditer(r"(?im)^[ \t]*(" + N + r")[ \t]+SEGMENT\b", text):
        SEGNAME.setdefault(m.group(1).upper(), m.group(1))
# A FAR label inside a SEGMENT AT, and the address that segment is at.
# GRTABHAN's DUMMY_SEG AT 0 holds one of these and no bytes: MASM wrote a
# direct far jump to it, whose address the loader patches with the previous
# owner of the interrupt vector, and the jump has to be the five bytes of
# one -- a near jump would leave the patch writing over the code after it.
# Where each SEGMENT AT is: the name of such a segment stands for that
# address, MODELENG loading the ROM BIOS's segment with MOV AX,ROM.
SEGAT = {}
FARAT = {}
for text in source.values():
    at = None
    for line in text.split('\n'):
        code = code_of(line)
        m = re.match(r"(?i)^[ \t]*(" + N + r")\s+SEGMENT\b.*?\bAT[ \t]+"
                     r"([^;]+?)[ \t]*$", code)
        if m:
            at = m.group(2).strip()
            SEGAT.setdefault(m.group(1).upper(), at)
            continue
        if re.match(r"(?i)^[ \t]*" + N + r"\s+ENDS\b", code):
            at = None
            continue
        m = re.match(r"(?i)^[ \t]*(" + N + r")\s+LABEL\s+FAR\b", code)
        if m and at is not None:
            FARAT[m.group(1).lower()] = at

GROUPED, GROUPNAME = set(), None
for text in source.values():
    for m in re.finditer(r"(?im)^[ \t]*(" + N + r")[ \t]+GROUP[ \t]+"
                         r"([^;\n]*)", text):
        GROUPNAME = m.group(1).upper()
        GROUPED |= {n.strip().upper() for n in m.group(2).split(',')
                    if n.strip()}
SEGMAP = {}
if GROUPNAME:
    SEGMAP = {name: GROUPNAME + '_' for name in GROUPED}
    SEGMAP[GROUPNAME] = GROUPNAME + '_'
# A segment the group does not hold is an address space of its own, group or
# no group: PRINT's CodeR is the resident part, which stays behind when the
# transient part in DG is let go, and the program writes both "mov ax,CodeR"
# and "offset CodeR:ListName".  Where there is no group at all this is every
# segment the modules declare.  A SEGMENT AT is not one of them: it names a
# place the program does not lay down -- MODE's ROM and SIGNITURE are the
# ROM BIOS and the EGA -- and its name stands for that address.
for name, spelt in SEGNAME.items():
    if name not in SEGAT:
        SEGMAP.setdefault(name, spelt + '_')
SEGPAT = "|".join(sorted(set(SEGMAP) | set(SEGAT), key=len, reverse=True))


def segvalue(name):
    """What a segment's name stands for where it is read as a value: the
    fasm segment of the address space it is in, or the address itself where
    the segment is one of the places the program does not lay down.

    A one-segment program lays no fasm segment down at all, so the name
    stands for the number the link file gives it, which is nought: DISPLAY
    writes DW SEG CODE for the segment of its own code twice, and INIT
    fills both of those words in with CS before anything reads them, as the
    loader would have done for a program that had a header to be relocated
    from.
    """
    if ONESEG and name.upper() in SEGMAP:
        return SEGNAME.get(name.upper(), name)
    return SEGMAP[name.upper()] if name.upper() in SEGMAP \
        else SEGAT[name.upper()]


def space(name):
    """The address space a segment's name stands for.

    Every segment of a group is the group, and a segment that is in no group
    is itself.
    """
    name = name.upper()
    if GROUPNAME and (name in GROUPED or name == GROUPNAME):
        return GROUPNAME
    return name


# Which segment each name is declared in, so that a reference to it can be
# reached through the register the ASSUME in force puts on that segment,
# which is what MASM wrote the override from.
SEGOF = {}
# And which address space each name the program declares FAR is in, for the
# CALLs and JMPs that reach it: MASM knew a name's distance from its
# declaration and laid down a far transfer, where fasm wants the segment
# written on the line.
FARSEG = {}


def declared_in(code, here):
    """What one line declares, and the segment it declares it in."""
    # A procedure is in the segment it stands in like anything else,
    # and a DD of its name is a far pointer to it: FASTOPEN's fifteen
    # jump vectors are DDs of procedures, and without this every one of
    # them was laid down with an offset and a zero segment -- which is
    # what the kernel then far-called through.
    m = re.match(r"(?i)^[ \t]*(" + N + r")\s+(?:d[bwdq]|label|proc)\b",
                 code)
    if m and here:
        SEGOF.setdefault(m.group(1).lower(), here)
    # A name an EQU gives a place rather than a number, which stands in a
    # segment like any other: RAMDRIVE says ABOVE_PID EQU WORD PTR $ - 2
    # for the immediate of the instruction it has just laid down, and reads
    # it three times with DS on nothing -- where MASM reached it through
    # CS, and this conversion reached it through whatever the block mover
    # had left in DS.
    m = re.match(r"(?i)^[ \t]*(" + N + r")\s+EQU\s+"
                 r"(?:byte|word|dword|qword|fword|tbyte)\s+ptr\b", code)
    if m and here:
        SEGOF.setdefault(m.group(1).lower(), here)
    # A name declared FAR, by a PROC, by a LABEL, or by the procedure
    # macro of INC/DOSMAC.INC.
    m = re.match(r"(?i)^[ \t]*(?:(" + N + r")\s+(?:proc|label)|"
                 r"procedure\s+(" + N + r")[ \t]*,)[ \t]*far\b", code)
    if m and here:
        FARSEG.setdefault((m.group(1) or m.group(2)).lower(), here)
    # A name given a colon and the bytes laid down under it, which MASM
    # read from memory like any other: APPEND writes version_loc: over
    # the two bytes of its version and reads them as BYTE PTR
    # version_loc.  The name is only reached through this where it
    # stands in brackets already, so a label the program jumps to is
    # none the worse for being known.
    m = re.match(r"^[ \t]*(" + N + r"):", code)
    if m and here:
        SEGOF.setdefault(m.group(1).lower(), here)
    # an instance of a structure is storage like any other
    m = re.match(r"(?i)^[ \t]*(" + N + r")[ \t]+(" + N + r")", code)
    if m and here and m.group(2).lower() in STRUC_CASE:
        SEGOF.setdefault(m.group(1).lower(), here)
    # Storage another module lays down, which MASM knew the segment of
    # because the EXTRN stands in that segment: that is how it chose the
    # register to reach the name through.  SHARE reads two dozen of the
    # kernel's variables and declares every one of them inside a CONSTANTS
    # or a DATA block of its own, both of them segments of DOSGROUP, which
    # is the group its ASSUME puts SS on -- so each of those reads is an
    # SS override, and without this not one of them had it.
    m = re.match(r"(?i)^[ \t]*ext?rn[ \t]+(.*)$", code)
    if m and here:
        for nm in re.findall(r"(?i)(" + N + r")[ \t]*:[ \t]*"
                             r"(?:byte|word|dword|qword|abs)\b", m.group(1)):
            EXTRNOF.setdefault(nm.lower(), here)


def segments_of(stem, here):
    """The names one module declares, and the names of whatever it reads
    while a segment of that module is open.

    A header of the utility's own declares no segment: APPENDP.INC holds
    the parser's switch and result blocks and APPEND.ASM reads it inside
    cseg, so what it declares is in cseg.  Reading it with the segment the
    INCLUDE stood in is what MASM did, and it is what the link file's walk
    does here.
    """
    # An IRP block, which declares its names once per item in its list:
    # the parameter, the list, and the lines gathered so far.  GSHARE2
    # declares the fourteen entries of its jump table in two of them, each
    # entry a J and the name of the routine it calls, and the table under
    # them is fourteen DDs of those names -- so without reading the block
    # the segment half of every one of them would be laid down as nought.
    irp = None
    for line in source[stem].split('\n'):
        code = code_of(line)
        if irp is not None:
            if re.match(r"(?i)^[ \t]*ENDM\b", code):
                var, items, body = irp
                irp = None
                for item in items:
                    for held in body:
                        declared_in(re.sub(r"(?i)(?<![\w?$@])"
                                           + re.escape(var)
                                           + r"(?![\w?$@])", item, held)
                                    .replace('&', ''), here)
                continue
            irp[2].append(code)
            continue
        m = re.match(r"(?i)^[ \t]*IRP[ \t]+(" + N + r")[ \t]*,[ \t]*"
                     r"<([^>]*)>", code)
        if m:
            irp = (m.group(1), [i.strip() for i in m.group(2).split(',')], [])
            continue
        m = re.match(r"(?i)^[ \t]*(" + N + r")\s+SEGMENT\b", code)
        if m:
            here = m.group(1).upper()
            here = space(here)
            continue
        if re.match(r"(?i)^[ \t]*" + N + r"\s+ENDS\b", code):
            here = None
            continue
        declared_in(code, here)
        m = re.match(r"(?i)^[ \t]*include[ \t]+'?([A-Za-z0-9_.]+)'?", code)
        if m:
            name = m.group(1).upper()
            if name in source and name != stem:
                segments_of(name, here)


# Where an EXTRN said a name is, which is read only for a name no module
# lays down itself: XCPYINIT declares EXTRN RESULT_PTR1:DWORD inside its own
# code segment where XCOPYPAR lays the word down in the data, and the
# declaration is the one that knows.
EXTRNOF = {}

for stem in MODULES:
    segments_of(stem, None)

for name, where in EXTRNOF.items():
    SEGOF.setdefault(name, where)


# The names a module gives an index register.  MASM's EQU put the register
# where the name stood, so the name is an index like the register itself:
# MODEVID reads the video state as video_info_DI.active_display, and
# MODEPARS the parsed parameters as parm_list[current_parm_DI].
NAMEDREG = set()
for text in source.values():
    for m in re.finditer(r"(?im)^[ \t]*(" + N + r")[ \t]+equ[ \t]+"
                         r"(?:bp|bx|si|di)[ \t]*(?:;[^\n]*)?$", text):
        NAMEDREG.add(m.group(1).lower())
# A name the program gives storage as well is left to the rules for storage,
# which know the width a reference to it wants.
BASEREG = NAMEDREG - DATA
# And the names an EQU gives a place in brackets, which stand where an index
# stands too: MODEVID's video_info_DI EQU [DI].
NAMEDREG |= PLACED
# the register's own name, and the names a module gives it
BASEPAT = "|".join(['bp', 'bx', 'si', 'di']
                   + sorted(map(re.escape, BASEREG), key=len, reverse=True))


# What each segment register is assumed to hold, as the ASSUMEs say.  All
# three modules begin their code with ASSUME CS:CSEG, DS:DGROUP; ES is named
# by an ASSUME of its own where it is wanted, so it starts at nothing, and
# the stack is a segment outside the group.
START = dict(U['START'])
# What a module starts on where that is not what the utility starts on: a
# file one module INCLUDEs inherits the ASSUMEs standing where the INCLUDE
# is, and is converted on its own here.
STARTS = {stem: dict(where) for stem, where in U.get('STARTS', {}).items()}
cover = [dict(START)]


def through(seg):
    """The override a reference to that segment wants, if any.

    MASM looked at the registers in this order and wrote the first that
    reached, which is why DS needs no override and the others do.
    """
    for reg in ('ds', 'ss', 'es', 'cs'):
        if cover[0].get(reg) == seg:
            return '' if reg == 'ds' else reg + ':'
    return ''


def reach(name):
    """The override a reference to this name wants, if any."""
    seg = SEGOF.get(name.lower())
    return '' if seg is None else through(seg)


def assumed(code):
    """An ASSUME, read for what it says about the segment registers."""
    m = re.match(r"(?i)^[ \t]*assume\b(.*)$", code)
    if not m:
        return
    for reg, seg in re.findall(r"(?i)\b(cs|ds|es|ss)[ \t]*:[ \t]*(" + N + r")",
                               m.group(1)):
        name = seg.upper()
        if name == 'NOTHING':
            cover[0][reg.lower()] = None
        elif name.endswith('_') and name[:-1] in SEGMAP:
            cover[0][reg.lower()] = space(name[:-1])
        else:
            cover[0][reg.lower()] = space(name)


# The names the program declares as a number rather than as storage, by an
# EQU of a character or a figure.  An alias for a name is left out: a
# reference through one of those is a reference to what it stands for.
ABSOLUTE = set()
for text in SEEN:
    for line in text.split('\n'):
        m = re.match(r"(?i)^[ \t]*(" + N + r")[ \t]+(?:equ|=)[ \t]*"
                     r"(?:'[^']*'|\"[^\"]*\"|[0-9][0-9A-Fa-f]*[hH]?)[ \t]*$",
                     code_of(line))
        if m:
            ABSOLUTE.add(m.group(1).lower())
ABSOLUTE -= DATA

# The names declared as a number by an EQU or an = to anything at all, which
# is wider than ABSOLUTE above because the value can be an expression:
# BOOTFORM.INC says BOOT_SIGNATURE = BOOT_SIZE-2, and MASM's dot added a
# number to an address the way it added a field's offset.
NUMBERED = set()
for text in SEEN:
    for line in text.split('\n'):
        m = re.match(r"(?i)^[ \t]*(" + N + r")[ \t]*(?:equ|=)[ \t]+[^ \t;]",
                     code_of(line))
        if m:
            NUMBERED.add(m.group(1).lower())
NUMBERED -= DATA


def absolutes(code):
    """Brackets round a number, which MASM read as nothing.

    A memory operand needs a segment and an offset to be in; a name the
    program declares with EQU has neither, so MASM took MOV AL,[DRVCHAR] --
    CHKPROC's way of writing the colon it puts after the drive letter -- as
    the character itself.  fasm reads the brackets as DS:003Ah.
    """
    # Brackets straight after a name are an index and not an operand of
    # their own: MODEPRIN reads LOCAL_NAME[PRN_NO], where PRN_NO is the
    # position of a character in the name.
    return re.sub(r"(?<![\w.$\]])\[[ \t]*(" + N + r")[ \t]*\]",
                  lambda m: (m.group(1) if m.group(1).lower() in ABSOLUTE
                             else m.group(0)), code)


def structures(code):
    """[BP].FRAM_CHAR, as the offset inside the structure it is a field of.

    A displacement with a dot of its own is no part of this: MODEPARS reads
    the parm_list entry after the one it is on as
    parm_list[current_parm_DI+TYPE parm_list_entry].item_tag, and the room
    an entry takes has become sizeof.parm_list_entry by now.

    What is added or taken away after the field can carry a dot of its own,
    and that part belongs to the reference: GSHARE2 finds the link in front
    of the first SFT on a name record with LEA SI,[BX].mft_sptr-sf_chain,
    so that [SI].sf_chain is the record's own pointer, and by this point the
    bare field is written sf_entry.sf_chain.  Read as a plain word it broke
    in two at the dot, the rest of it was folded in again with a plus, and
    the subtraction became an addition -- which lost the sharer every SFT
    it was given to close.
    """
    # LEA asks for an address and not for what is at it, so a width in
    # front of its operand would be nonsense.
    lea = re.match(r"(?i)^\s*(?:" + N + r":)?\s*lea\b", code) is not None

    def one(m):
        reg, field, tail = m.group(1), m.group(2), m.group(3)
        # Where MASM said the width itself -- WORD PTR in front of a field
        # it declared as a DWORD, which IFSSESS writes to fill in half of a
        # far pointer -- that width is the one that is meant, and a second
        # one from the table below would stand inside the reference.
        said = re.search(r"(?i)\b(?:byte|word|dword|qword)(?:[ \t]+ptr)?"
                         r"[ \t]*(?:(?:cs|ds|es|ss):)?[ \t]*$",
                         code[:m.start()]) is not None
        # A field of a structure that is itself inside a field, which MASM
        # added the two offsets of: the room the outer field reserves is
        # the inner structure's, and HOLDS says which.
        path = field.split('.')
        parts, holder, size = [], None, None
        for name in path:
            if holder is not None:
                parts.append('%s.%s' % (holder, name))
                holder = HOLDS.get(name.upper())
                continue
            found = FIELD.get(name.upper())
            if found is None:
                # The width such a name was declared with, where the
                # utility says so.  IFSSYM.INC's two request macros make
                # fifty-five names and MASM wrote a type in front of each
                # -- BYTE PTR, WORD PTR -- which is gone by the time the
                # offset is all that is left of it, and fifty-two of the
                # lines that read one have an immediate on the other side
                # and nothing else to take a width from.
                size = size or ABSWIDTH.get(name.upper())
                # not a field of a structure but a number of its own,
                # which MASM added the same way: INC/CPMFCB.INC declares
                # fcb_sfn as the offset of the FCB's reserved bytes, where
                # DOS keeps the system file number.
                parts.append(name)
            else:
                parts.append('%s.%s' % found)
            holder = HOLDS.get(name.upper())
        return '%s[%s+%s%s]' % ('' if size is None or lea or said
                                else size + ' ',
                                reg, '+'.join(parts),
                                tail.replace(' ', ''))
    # What follows the dot can be a number rather than a field, and the
    # dot is still the addition it is: SMARTDRV reads the second byte of a
    # sector's signature as ES:[DI.1], which is ES:[DI+1].
    code = re.sub(r"(?i)\[[ \t]*((?:(?:cs|ds|es|ss):)?(?:" + BASEPAT + r"))"
                  r"[ \t]*\.[ \t]*(\d+)[ \t]*\]",
                  lambda m: '[%s+%s]' % (m.group(1), m.group(2)), code)
    # SYS2 writes the register and the field inside the one pair of
    # brackets: [BX.dpb_first_FAT] says what [BX].dpb_first_FAT does.  This
    # goes first because what the rule below writes -- the structure's name
    # as the displacement, with the field named after it -- is of that shape
    # itself, and would be read a second time.
    code = re.sub(r"(?i)\[\s*((?:(?:cs|ds|es|ss):)?(?:" + BASEPAT + r")"
                  r"(?:\s*\+\s*(?:" + BASEPAT + r"))?"
                  r"(?:\s*[-+]\s*\w+(?!\.))?)\s*\.(" + N
                  + r"(?:\.(?:" + N + r"|\d+))*)"
                  r"((?:\s*[-+]\s*[\w.$@?]+)?)\s*\]", one, code)
    code = re.sub(r"(?i)\[\s*((?:(?:cs|ds|es|ss):)?(?:" + BASEPAT + r")"
                  r"(?:\s*\+\s*(?:" + BASEPAT + r"))?"
                  r"(?:\s*[-+]\s*\w+(?!\.))?)\s*\]\s*\.(" + N
                  + r"(?:\.(?:" + N + r"|\d+))*)"
                  r"((?:\s*[-+]\s*[\w.$@?]+)?)", one, code)
    # The index with no brackets at all, which MASM read as a reference
    # just the same: MODEVID passes video_info_DI.active_display to a macro
    # that moves it into AL.  An instruction's own operands are left to the
    # rules for storage below, which say the width where the name no longer
    # tells it; a macro's argument is not one of those, and the rules that
    # look for a mnemonic pass the line over.
    # A width in front of a reference has to stand in front of the segment
    # override as well.  The release writes the override outside the
    # brackets, as MASM wanted it -- MOV ES:[BX.IFSR_APIFUNC],IFSEOP -- and
    # a width between the two is read as part of the reference instead.
    code = re.sub(r"(?i)\b((?:cs|ds|es|ss):)(byte|word|dword|qword)"
                  r"([ \t]*\[)",
                  lambda m: '%s %s%s' % (m.group(2), m.group(1),
                                         m.group(3).strip()),
                  code)
    if NAMEDREG and not re.match(LED + MNEM + r")\s+)", code, re.I):
        code = re.sub(r"(?i)(?<![\w.$\]])((?:" + "|".join(
            sorted(map(re.escape, NAMEDREG), key=len, reverse=True))
            + r"))\s*\.(" + N + r")((?:\s*[-+]\s*[\w.$@?]+)?)",
            one, code)

    return code


def overlaid(code):
    """A structure's field written on storage the structure was not laid
    down in.

    MASM read a field name as the offset of that field, so BOOT.EXT_PHYDRV
    added it to the address of the buffer, and the three names of
    DeviceParameters.DP_BPB.BPB_MediaDescriptor were all added.  Storage
    laid down as bytes under a LABEL, which is how CHKMSG.INC writes its
    sublists and SYS1 its canned boot record, has a name for where it begins
    and none for a field inside it: the offset is added, and the width, which
    the name no longer tells, is written in front -- except after LEA, which
    asks for an address and not for what is at it.
    """
    if not re.match(LED + MNEM + r")\s+)", code, re.I):
        return code
    lea = re.match(r"(?i)^\s*(?:" + N + r":)?\s*lea\b", code) is not None

    def one(m):
        seg, base = m.group(1), m.group(2)
        fields, tail = m.group(3).split('.')[1:], m.group(4)
        # A name the program gave a colon is a NEAR label, whatever is laid
        # down under it, so the dot adds the field's offset to its address
        # and the whole of it is a number: XMA2EMS lays the parser's switch
        # control block down under X_Switch: by hand and compares the
        # pointer the parser gave back with X_Switch.P_KeyorSW.
        nearlabel = (base.lower() not in DATA and base.lower() not in WRITTEN
                     and base.lower() in LABELLED)
        if not nearlabel \
                and base.lower() not in DATA and base.lower() not in WRITTEN:
            return m.group(0)
        # already in fasm's own form: a field named with the structure it
        # belongs to, which is what the [BX].FIELD rule above writes and what
        # a source can write for itself
        if fields and FIELD.get(fields[0].upper()) \
                and FIELD[fields[0].upper()][0].lower() == base.lower():
            return m.group(0)
        # Two things standing in front of the reference say that the
        # offset is all that is to be added here, and that nothing is to be
        # bracketed or sized: OFFSET, where it is the number that is wanted
        # and not what is at it, which is how FORINIT asks for the keyword of
        # a switch's entry in the parser's table; and a size of MASM's own --
        # BYTE PTR, which is where MASM said the width -- which is the size
        # already, and which refs() brackets what follows.
        head = code[:m.start()]
        plain = nearlabel \
            or re.search(r"(?i)\boffset[ \t]*$", head) is not None \
            or re.search(r"(?i)\b(?:byte|word|dword|qword)[ \t]+ptr[ \t]*"
                         r"(?:(?:cs|ds|es|ss):)?[ \t]*$", head) is not None
        # fasm names a field only where the thing holding it was laid down
        # as an instance of a structure; anywhere else the offset is added
        laid, added, place, size = base.lower() in WRITTEN, False, base, None
        for field in fields:
            found = FIELD.get(field.upper())
            if found is None:
                # a number of the program's own, which MASM's dot added to
                # the address as it added a field's offset: MSFOR reads the
                # signature of the sector it has read as
                # ScratchBuffer.Boot_Signature.  What width to read it at is
                # the utility's to say, the number itself saying nothing.
                if field.lower() in NUMBERED:
                    place, added, laid = '%s+%s' % (place, field), True, False
                    size = ABSWIDTH.get(field.upper())
                    continue
                return m.group(0)
            # fasm names a field of an instance only where the field is
            # one of that instance's structure.  FORINIT writes
            # Switch_String_Buffer.Switch_Pointer, and Switch_Pointer is a
            # field of Switch_Return where the buffer was laid down as a
            # Switch_String_Return, so there the offset is added instead.
            owner = WRITTENAS.get(base.lower(), '') if place == base else ''
            if laid and found[0].lower() == owner.lower():
                place = '%s.%s' % (place, found[1])
            else:
                place, added = '%s+%s.%s' % (place, found[0], found[1]), True
            size = FIELDSIZE.get(field.upper())
            laid = laid and size is None
        if not added:
            return m.group(0)
        if plain:
            return '%s%s' % (place, re.sub(r"\s+", '', tail))
        return '%s[%s%s%s]' % ('' if size is None or lea else size + ' ',
                               seg.lower(), place, re.sub(r"\s+", '', tail))

    # a segment override in front of it and a displacement after it belong
    # inside the brackets the reference is given
    return re.sub(r"(?<![\w.$])((?:(?:cs|ds|es|ss):)?)(" + N + r")"
                  r"((?:\.(?:" + N + r"))+)"
                  r"((?:[ \t]*[-+][ \t]*(?:\([^)]*\)|[\w.$]+))*)",
                  one, code)


def strung(code):
    """A string instruction that names the storage it works on.

    MASM took the size from the name -- SCAS IOCTL_File_Sys scans the bytes
    of an eight byte field -- where fasm wants the size in the mnemonic and
    the registers understood.
    """
    def one(m):
        head, op, name = m.group(1), m.group(2), m.group(3)
        size = SIZE.get(name.lower())
        if size not in ('byte', 'word'):
            return m.group(0)
        return '%s%s%s' % (head, op, 'b' if size == 'byte' else 'w')

    return re.sub(r"(?i)^([ \t]*(?:rep[en]?z?[ \t]+)?)"
                  r"(scas|movs|cmps|lods|stos)[ \t]+(" + N + r")[ \t]*$",
                  one, code)


def displaced(code):
    """MASM wrote a displacement in brackets after the name: BIOSPos[2] is
    the word two bytes past BIOSPos, which fasm asks for inside the one pair
    of brackets the reference already needs."""
    return re.sub(r"(?<![\w.$\]])(" + N + r")\[([0-9][^\]]*)\]",
                  lambda m: '%s+%s' % (m.group(1), m.group(2)), code)


def fielded(code):
    """A field of a structure left outside the brackets.

    The structure rules read [BX].item_tag and [BX+DI].item_tag, where the
    register is written as itself; MODEPARS names its registers and writes
    parm_list[current_parm_DI].item_tag, which the index rule below moves
    into brackets after those rules have been by.  The field is folded in
    here, once the brackets hold what they will hold.
    """
    def one(m):
        inside, field, tail = m.group(1), m.group(2), m.group(3)
        found = FIELD.get(field.upper())
        if found is None:
            return '[%s+%s%s]' % (inside, field, tail.replace(' ', ''))
        return '[%s+%s.%s%s]' % (inside, found[0], found[1],
                                 tail.replace(' ', ''))

    # What is added or taken away after the field can be a field itself,
    # which by this point is written with the structure it belongs to:
    # GSHARE2 finds the link in front of the first SFT on a name record with
    # LEA SI,[BX].mft_sptr-sf_chain, so that [SI].sf_chain is the record's
    # own pointer.  Read as a plain word the name broke in two at the dot
    # and the rest of it was folded in again with a plus, which turned the
    # subtraction into an addition and lost the sharer every SFT it was
    # given to close.
    return re.sub(r"(?i)\[([^\]]*)\]\s*\.(" + N + r")"
                  r"((?:\s*[-+]\s*[\w.$@?]+)?)", one, code)


def indexed(code):
    """MASM wrote the index after the displacement: BUF-1[SI] is the one
    added to the other, which fasm asks for inside the brackets.  It runs
    after the sizes are in, so that the name before the bracket cannot be
    one of those."""
    # only in the operands: the mnemonic before them is not a displacement
    m = re.match(LED + MNEM + r")\s+)(.*)$", code, re.I)
    if not m:
        return code
    head, rest = m.group(1), m.group(2)
    # A place's name with an index after it, which MASM added the one to the
    # other: MODE reads the parsed parameters as
    # parm_list[DI+parm_list_entry.value1], parm_list being the name it
    # gives [BP].
    if PLACED:
        rest = re.sub(r"(?i)(?<![\w.])(" + "|".join(sorted(PLACED))
                      + r")\s*\[\s*([^\]]*?)\s*\]",
                      lambda m2: '[%s+%s]' % (m2.group(1), m2.group(2)), rest)
    # A name with a constant index after it, which MASM added the one to
    # the other as well: MODEPRIN reads LOCAL_NAME[PRN_NO], the character
    # at that position of the name.
    rest = re.sub(r"(?i)(?<![\w.\]])(" + N + r")\s*\[\s*([^\]]*?)\s*\]",
                  lambda m2: ('[%s+%s]' % (m2.group(1), m2.group(2))
                              if m2.group(1).lower() in DATA
                              and not re.match(r"(?i)^(?:bp|bx|si|di)$",
                                               m2.group(2))
                              else m2.group(0)), rest)
    # The name can be a field of an instance, which by this point is
    # written with the instance it belongs to: XMA2EMS reads the pages a
    # handle owns as HANDLE_LOOKUP_TABLE.H_PAGES[DI], the index being the
    # handle's place in the table.
    rest = re.sub(r"(?i)(?<![\w.])(?!(?:byte|word|dword|qword|ptr)\b)"
                  r"(" + PLACE + r"(?:\s*[-+]\s*[\w@?$.]+)*)\s*"
                  r"\[\s*(bp|bx|si|di)\s*\]",
                  lambda m2: '[%s+%s]' % (m2.group(2),
                                          re.sub(r"\s+", '', m2.group(1))),
                  rest)
    return head + rest


def parenthesised(code):
    """A place written with the size in brackets of its own: RECOVER.ASM
    says DS:(BYTE PTR 4) for the byte at that offset of the segment, and
    DEBCOM2 says ES:(BYTE PTR [80H]) for the same thing with the offset in
    brackets as well.  fasm asks for the size in front and the segment inside
    the one pair of brackets."""
    def one(m):
        seg, size, place = m.group(1), m.group(2), m.group(3)
        if place.startswith('[') and place.endswith(']'):
            place = place[1:-1]
        return '%s [%s:%s]' % (size.lower(), seg.lower(), place)

    return re.sub(r"(?i)\b(cs|ds|es|ss):\(\s*(" + PTRSIZES + r")\s+ptr\s+"
                  r"([^)]+?)\s*\)", one, code)


def joined(code):
    """MASM wrote two index registers as two brackets: [BX][SI] is the one
    added to the other, which fasm asks for inside one pair.  A displacement
    after the brackets -- [BX]+1 -- is added the same way, and inside them.
    MODEECHO writes the plus as well -- ES:PRINTR-2+[SI] -- which comes to
    the same thing."""
    code = re.sub(r"\]\s*\+?\s*\[", '+', code)
    # A displacement written straight after the brackets, with no sign and
    # no space: MODEVID writes [BX]SHIFCT40 for the byte at that offset of
    # the table BX points at.
    code = re.sub(r"\[([^\]]*)\](" + N + r")", r"[\1+\2]", code)
    return re.sub(r"\[([^\]]*)\]\s*([-+])\s*(\w+)",
                  lambda m: '[%s%s%s]' % (m.group(1), m.group(2), m.group(3)),
                  code)


# A place a reference can name: a name, or a name with the fields of a
# structure after it, which fasm names the same way.
PLACE = N + r"(?:\." + N + r")*"


def refs(code):
    """MASM's memory operands in fasm's brackets."""
    def ptr(m):
        size, seg, rest, tail = (m.group(1).lower(), m.group(2), m.group(3),
                                 m.group(4))
        # A size in front of a number is the width of the number and not a
        # place at all: MODEPARS writes MOV looking_for,BYTE PTR
        # con_kwrd_status_or_cp, which is one of its states and an EQU of
        # 6AH.  fasm reads a size in front of an immediate the same way.
        if not seg and not tail and rest.lower() in ABSOLUTE:
            return '%s %s' % (size, rest)
        inner = rest[1:-1] if rest.startswith('[') else rest
        return "%s [%s%s%s]" % (size, seg.lower() if seg else '', inner,
                                tail.replace(' ', ''))
    # MASM let a size stand between OFFSET and the name -- CHKMSG.INC asks
    # for "offset word ptr sernum+2" -- and an address has no size, so the
    # word here says nothing and goes.
    code = re.sub(r"(?i)\boffset\s+(?:" + PTRSIZES + r")\s+ptr\s+",
                  'offset ', code)
    # The same override written twice, once before the size and once on the
    # operand: PRINT_R has one, "CMP ES:BYTE PTR ES:[DI],0", and MASM laid
    # down the one prefix either says.  The outer one goes, the operand
    # carrying its own.
    code = re.sub(r"(?i)\b(cs|ds|es|ss):(\s*(?:" + PTRSIZES + r")\s+ptr\s*"
                  r"(?:cs|ds|es|ss):)", lambda m: m.group(2), code)
    # the override before the size, which two of RECOVER's lines write:
    # LDS DX,CS:DWORD PTR [int_24_old_off]
    code = re.sub(r"(?i)\b(cs|ds|es|ss):\s*(" + PTRSIZES + r")\s+ptr\s*"
                  r"(\[[^\]]*\]|" + PLACE + r")",
                  lambda m: '%s [%s:%s]' % (
                      m.group(2).lower(), m.group(1).lower(),
                      m.group(3)[1:-1] if m.group(3).startswith('[')
                      else m.group(3)),
                  code)
    # the place may be a number rather than a name: RESCODE writes
    # MOV BYTE PTR CS:1,27H to put a RET into the prefix
    code = re.sub(r"\b(" + PTRSIZES + r")\s+ptr\s*((?:[A-Za-z]{2}:)?)\s*"
                  r"(\[[^\]]*\]|" + PLACE + r"|\d[0-9A-Fa-f]*[hH]?)"
                  r"((?:\s*[-+]\s*[\w.$]+)*)",
                  ptr, code, flags=re.I)
    # a number after the override is an offset in that segment, which
    # XCPYINIT reads the PSP's top of memory from: MOV AX,ES:2
    code = re.sub(r"(?<![\[\w:])\b(cs|ds|es|ss):(\[[^\]]*\]|" + PLACE
                  + r"|\d[0-9A-Fa-f]*[hH]?)"
                  r"((?:\s*[-+]\s*[\w.$]+)*)",
                  lambda m: "[%s:%s%s]" % (
                      m.group(1).lower(),
                      m.group(2)[1:-1] if m.group(2).startswith('[')
                      else m.group(2),
                      m.group(3).replace(' ', '')),
                  code, flags=re.I)
    return code


# COMP2 has a word called handle and a macro whose parameter is called
# handle; inside the macro the name is the parameter, so it is left alone
# while a macro body is being read.
PARAMS = frozenset(('pfcb', 'msg', 'handle', 'func', 'subfunc'))
inmacro = [False]


def bracket(code):
    """A bare storage name, which MASM read from memory."""
    m = re.match(LED + MNEM + r")\s+)(.*)$", code, re.I)
    if not m:
        return code
    head, rest = m.group(1), m.group(2)
    # LEA asks for the address of a place, so its second operand is a memory
    # reference whatever the name stands for -- RECINIT takes the address of
    # its interrupt handlers that way, and APPEND the paragraph after the
    # end of what it keeps resident, which is a label and fifteen.
    if re.search(r"(?i)\blea\s*$", head):
        parts = rest.split(',')
        if len(parts) == 2 and re.match(r"^\s*" + N + r"(?:\." + N
                                        + r")?(?:\s*[-+]\s*\S+)?\s*$",
                                        parts[1]):
            return head + parts[0] + ',[' + parts[1].strip() + ']'
    # A transfer's target is a place and not a word read from memory, so
    # long as the name is no wider than one: MASM read CALL name as an
    # indirect call where the name is a WORD or a DWORD variable -- PRINT
    # jumps through a far pointer that way -- and as a direct one where it
    # is a label.  GRCOLPRT marks the start of its own code with
    # PRINT_MODULE_START LABEL BYTE and GRCTRL calls it.
    transfer = bool(re.search(r"(?i)\b(?:call|jmp)\s*$", head))
    out = []
    for part in rest.split(','):
        s = part.strip()
        # a storage name, a field of one, and either with a displacement on
        # the end -- MASM read all of those from memory
        m2 = re.match(r"^(" + N + r")(?:\.(" + N + r"))?"
                      r"(\s*[-+]\s*\S+)?$", s)
        if m2:
            base, field = m2.group(1), m2.group(2)
            if inmacro[0] and base.lower() in PARAMS:
                out.append(part)
                continue
            # The difference of two places is a number, not a place:
            # RAMDRIVE loads the selector of its data descriptor with
            # MOV AX,ds_des - start_gdt, the two labels standing at the
            # ends of the piece of the GDT it wants the length of.  A
            # displacement that is a number -- TABLE-2 -- still names a
            # place, so this is only where what is taken away is itself
            # one of the program's own.
            other = re.match(r"^[-+]\s*(" + N + r")$",
                             (m2.group(3) or '').strip())
            if other and other.group(1).lower() in DATA:
                out.append(part)
                continue
            if transfer and SIZE.get(base.lower()) == 'byte':
                out.append(part)
                continue
            if (field and base.lower() in WRITTEN) or \
                    (not field and base.lower() in DATA):
                part = part.replace(s, '[%s%s]' % (reach(base), s), 1)
        out.append(part)
    return head + ','.join(out)


def overridden(code):
    """A reference the source wrote in brackets itself, which MASM still
    reached through the register the ASSUME in force put on its segment.

    SYS2 walks the DPB with DS pointing at the DPB and ES at its own data,
    and the lines that put away what it found there -- MOV [SSIZE],AX --
    carry an ES: in the release and would carry none here.  LEA is left
    alone: it asks for an offset and MASM wrote no override on one.
    """
    if not re.match(LED + MNEM + r")\s+)", code, re.I) \
            or re.match(r"(?i)^\s*(?:" + N + r":)?\s*lea\b", code):
        return code

    def one(m):
        inner = m.group(1)
        # brackets that say which register already reach where they say
        if re.match(r"(?i)^\s*(?:cs|ds|es|ss)\s*:", inner):
            return m.group(0)
        # and so do brackets holding a name whose own value says which
        # register reaches it: XMAEM's INDEINI reads the request header
        # through RH EQU DS:[BX], where the release wrote no override of its
        # own because the name is one.
        if any(n.lower() in CARRIED
               for n in re.findall(r"(?<![\w.@?$])(" + N + r")", inner)):
            return m.group(0)
        # BP and SP reach through SS, which is the default there the way DS
        # is everywhere else, so a name inside such brackets is a
        # displacement and not the place: MODESUBS writes
        # MOV [BP+sublist_def.sublist_off],SI, where the field is how far
        # into the block the frame points at the pointer stands.
        if re.search(r"(?i)(?<![\w.@?$])(?:bp|sp)(?![\w.@?$])", inner):
            return m.group(0)
        # the name in the brackets that is storage, which is not always the
        # first thing in them: ASSGMAIN jumps through systab[bx], where the
        # index is written first by the time the brackets are closed, and
        # MASM reached the table through the register its ASSUME put on the
        # segment the table is in.
        for name in re.findall(r"(?<![\w.@?$])(" + N + r")", inner):
            want = reach(name)
            if want:
                return '[%s%s]' % (want, inner)
        return m.group(0)

    return re.sub(r"\[([^\[\]]*)\]", one, code)


def sized(code):
    m = re.match(LED + r"mov|cmp|add|sub|inc|dec|and|or|test|xor)\s+)(.*)$",
                 code, re.I)
    if not m or re.search(r"\b(byte|word|dword)\b", m.group(2), re.I):
        return code
    head, rest = m.group(1), m.group(2)
    parts = rest.split(',')
    # A field of a structure that stands inside a field of another: MASM
    # read the width from the field the reference ends at, where fasm reads
    # it from the first name in the expression that has one -- the room the
    # outer field reserves, which is bytes.  FASTOPEN compares a word with
    # [bp.nCmpct_Dir_Info.CDI_cluster].  The other operand being a register
    # settles nothing here, so this is said before the rule below, which
    # leaves those alone.
    for i, part in enumerate(parts):
        nested = re.match(r"(?i)^\[(?:(?:cs|ds|es|ss):)?[^\]]*?" + N + r"\.("
                          + N + r")\+" + N + r"\.(" + N + r")"
                          r"(?:[-+][\w.$]+)*\]$", part.strip())
        # The outer name has to be a field whose room is the inner
        # structure's, which HOLDS says: MODEPARS writes
        # [parm_list+...+sizeof.parm_list_entry+parm_list_entry.item_tag],
        # two dotted names of which neither is that.
        if not nested or nested.group(1).upper() not in HOLDS:
            continue
        size = FIELDSIZE.get(nested.group(2).upper())
        if not size:
            continue
        # the width goes on the operand it belongs to, which can be either
        # of the two: FASTOPEN reads the reference into a register as often
        # as it writes one to it.
        said = list(parts)
        lead = re.match(r"^[ \t]*", part).group(0)
        said[i] = '%s%s %s' % (lead, size, part.lstrip())
        return head + ','.join(said)
    ref = re.match(r"^\[(?:(?:cs|ds|es|ss):)?(" + N + r")\]$",
                   parts[0].strip(), re.I)
    if not ref:
        # A reference with nothing in it to take a width from, against an
        # immediate of more than a byte: MASM sized the one from the other,
        # as it does inside a condition.  RAMDRIVE looks for the two
        # characters of 'LO' at FC00:50 with CMP ES:[0050H],'LO', which is
        # how it knows an AT&T 6300 PLUS when it sees one.
        other = parts[1].strip() if len(parts) > 1 else ''
        wide = (len(other) == 4 and other[0] in '\'"' and other[-1] == other[0])
        if not wide and re.match(r"(?i)^[0-9][0-9A-F]*H$", other):
            wide = int(other[:-1], 16) > 0xFF
        inner = parts[0].strip()
        left = re.sub(r"(?i)\b(?:cs|ds|es|ss|[abcd]x|[abcd][lh]|si|di|bp|sp)"
                      r"\b", '', inner)
        left = re.sub(r"(?i)\b[0-9][0-9A-F]*H?\b", '', left)
        if wide and inner.startswith('[') and inner.endswith(']') \
                and not re.search(N, left):
            return head + 'word ' + rest
        return code
    size = SIZE.get(ref.group(1).lower())
    if size is None:
        return code
    other = parts[1].strip().lower() if len(parts) > 1 else ''
    if other in ('ax', 'bx', 'cx', 'dx', 'si', 'di', 'bp', 'sp', 'al', 'bl',
                 'cl', 'dl', 'ah', 'bh', 'ch', 'dh', 'cs', 'ds', 'es', 'ss'):
        return code
    return head + size + ' ' + rest


def pushed(code):
    """PUSH or POP of a place, which MASM took as a word.

    There is no other size a push can be on this processor, but fasm will
    not guess one, so the word is said.
    """
    return re.sub(r"(?i)^(\s*(?:" + N + r":)?\s*(?:push|pop)\s+)"
                  r"(\[[^\]]*\])\s*$",
                  lambda m: '%sword %s' % (m.group(1), m.group(2)), code)


def close_proc(opened, kind):
    """Close the innermost procedure of that kind, and say whether what is
    left around it is a far one."""
    for i in range(len(opened) - 1, -1, -1):
        if opened[i][0] == kind:
            del opened[i]
            break
    return opened[-1][1] if opened else False


def jumped(code):
    """JMP or CALL through a place with no width said, which MASM read as a
    near one: the word at the address.

    ANSI writes JMP WORD PTR [SI] at line 303 for the routine its state
    machine is to go to next and JMP [SI] at line 832 for the same thing.
    fasm will not guess a width, and the far form is two words rather than
    one, so the word is said.  Only where the brackets hold nothing but
    registers: a name in them has a width of its own, which may be the
    double word of a far address, and that is the width MASM read.
    """
    def one(m):
        inner = re.sub(r"(?i)\b(?:cs|ds|es|ss|[abcd]x|[abcd][lh]|si|di|bp|"
                       r"sp)\b", '', m.group(2))
        if re.search(N, inner):
            return m.group(0)
        return '%sword %s' % (m.group(1), m.group(2))

    return re.sub(r"(?i)^(\s*(?:" + N + r":)?\s*(?:jmp|call)\s+)"
                  r"(\[[^\]]*\])\s*$", one, code)


def tenbytes(code):
    """MASM's DT, which lays down ten bytes of packed decimal.

    fasm's DT is the x87's ten-byte real and will not take an integer at
    all.  VDISK's boot record reserves its ten bytes with DT 0, which is
    the digits of nought and so ten zero bytes; the only other DT in the
    release is the same line in the copy of the driver that nothing links.
    Any other value would have its digits worked out, and there is none.
    """
    return re.sub(r"(?i)^(\s*)dt(\s+)(0|\?)[ \t]*$",
                  lambda m: '%sdb%s10 dup (0)' % (m.group(1), m.group(2))
                  if m.group(3) == '0' else '%srb%s10' % (m.group(1),
                                                          m.group(2)),
                  code)


def sizes(code):
    """A type name in an expression, as the number of bytes it takes up."""
    code = re.sub(r"\b(BYTE|WORD|DWORD)\b(?!\s*\[)",
                  lambda m: {'BYTE': '1', 'WORD': '2', 'DWORD': '4'}[m.group(1)],
                  code)
    # The release wrote it in lower case as well, where the rule above would
    # have taken it for the size the conversion writes: a type name after a
    # plus or a minus is inside an expression and is the number.  FASTINIT
    # patches the segment half of each of its fourteen jump vectors with
    # "MOV WORD PTR ES:FOPEN_Insert + word, AX", the word two bytes past
    # the start of the far pointer.
    return re.sub(r"(?i)([-+][ \t]*)(byte|word|dword)\b(?![ \t]*\[)",
                  lambda m: m.group(1) + {'byte': '1', 'word': '2',
                                          'dword': '4'}[m.group(2).lower()],
                  code)


def pad(text, width, comment):
    if not comment:
        return text
    return (text + ' ' * (width - len(text)) + comment) if len(text) < width \
        else text + ' ' + comment


DIRECTIVE = re.compile(r"(?i)^[ \t]*(%OUT|ASSUME|EXTRN|PUBLIC|GROUP|\\.LALL|\\.SALL)(?:\s|$)")

# The IF1 blocks that only name the module go as comments, whole, so that no
# ENDIF of a real conditional is taken for one of theirs.  Two of them write
# the same line in each arm of an ELSE, and the comment lines between belong
# to the block as well.  PRIDEFS.INC's asks IF IBM inside its IF1, so the
# scan below follows the nesting rather than stopping at the first ENDIF,
# and it comments the block out only where nothing in it lays anything down.
IF1OPEN = re.compile(r"(?i)^[ \t]*IF1\b")
IF1DEEPER = re.compile(r"(?i)^[ \t]*IF[A-Z0-9]*\b")
IF1CLOSE = re.compile(r"(?i)^[ \t]*ENDIF\b")
IF1QUIET = re.compile(r"(?i)^[ \t]*(?:%OUT\b|;|ELSE\b)|^[ \t]*$")


IF2OPEN = re.compile(r"(?i)^[ \t]*IF2\b")
# MASM's processor directives, which said which instructions it would take.
# The widths MASM wrote with PTR.  FWORD is the six bytes SIDT and LGDT
# want -- RAMDRIVE reads the interrupt descriptor table with
# SIDT FWORD PTR [IDTDES] for the code it runs above the first
# megabyte -- and TBYTE the ten of a packed decimal.
PTRSIZES = r"byte|word|dword|qword|fword|tbyte"
PROCESSOR = re.compile(r"(?i)^[ \t]*\.(?:8086|186|286|386|486|586|287|387"
                       r"|8087)p?[ \t]*(?:;.*)?$")


def pass_two(text):
    """MASM's IF2, which held what only its second pass assembled.

    MASM made two passes and the second was the one whose output counted,
    so what stands inside such a block stands in the program and the block
    itself says nothing here: fasm reads the source as many times as it
    needs to settle the addresses and has no first pass to tell from a
    second.  Both the IF2 and the ENDIF that closes it are commented out
    and what is between them is left where it is.

    RAMDRIVE writes one at the top of its segment, round two assertions
    over the code it swaps in above the first megabyte: each prints a %OUT
    where the offset of the swapped-in copy does not line up with the
    offset of the code it replaces.  The %OUTs are comments by now, so what
    is left is the two IFs with nothing in them, which is what MASM
    assembled when the offsets did line up.  KEYB's KEYBMAC.INC has six
    more inside macros that nothing calls.
    """
    lines = text.split('\n')
    out, i = [], 0
    while i < len(lines):
        if not IF2OPEN.match(code_of(lines[i])):
            out.append(lines[i])
            i += 1
            continue
        depth, j = 1, i + 1
        while j < len(lines) and depth:
            code = code_of(lines[j])
            if IF1DEEPER.match(code):
                depth += 1
            elif IF1CLOSE.match(code):
                depth -= 1
                if not depth:
                    break
            j += 1
        if j >= len(lines) or depth:    # nothing closes it: leave it alone
            out.append(lines[i])
            i += 1
            continue
        out.append(';' + lines[i])
        out.extend(lines[i + 1:j])
        out.append(';' + lines[j])
        i = j + 1
    return '\n'.join(out)


def quiet_if1(text):
    """MASM's IF1, which held what only its first pass assembled.

    What a module put there was what wanted reading once however many passes
    the assembler made: its macro libraries, and the %OUTs that reported on
    the build.  fasm reads the source through its preprocessor once and makes
    as many passes over the result as the addresses need, so the block itself
    says nothing here: the IF1 and the ENDIF that closes it are commented out
    and what is between them is left where it is.  Every XMAEM module reads
    INDEOVP.MAC and INDEINS.MAC inside one.

    A block that says nothing but %OUT is commented out whole, the lines in
    it having nothing to leave behind.

    An IF1 with an ELSE is a different thing: what follows the ELSE is what
    the second pass assembled, so the two branches say different things and
    neither can simply stand.  SHARE writes the one of those, round the room
    its pool has, and the table says what to do with it.
    """
    lines = text.split('\n')
    out, i = [], 0
    while i < len(lines):
        if not IF1OPEN.match(code_of(lines[i])):
            out.append(lines[i])
            i += 1
            continue
        depth, j, quiet, branch = 1, i + 1, True, False
        while j < len(lines) and depth:
            code = code_of(lines[j])
            if IF1DEEPER.match(code):
                depth += 1
            elif IF1CLOSE.match(code):
                depth -= 1
                if not depth:
                    break
            elif depth == 1 and CONDELSE.match(code):
                branch = True
            elif not IF1QUIET.match(code):
                quiet = False
            j += 1
        if j >= len(lines) or depth:    # nothing closes it: leave it alone
            out.append(lines[i])
            i += 1
            continue
        if quiet:
            out.extend(';' + l for l in lines[i:j + 1])
        elif branch:
            out.append(lines[i])
            i += 1
            continue
        else:
            out.append(';' + lines[i])
            out.extend(lines[i + 1:j])
            out.append(';' + lines[j])
        i = j + 1
    return '\n'.join(out)


MACRODEF = re.compile(r"(?i)^(" + N + r")[ \t]+MACRO\b[ \t]*(.*)$")
MACROEND = re.compile(r"(?i)^[ \t]*ENDM\b")
SEGMENT = re.compile(r"(?i)^[ \t]*(" + N + r")\s+SEGMENT\b")
GROUP = re.compile(r"(?i)^[ \t]*(" + N + r")\s+GROUP\b")
SEGEND = re.compile(r"(?i)^[ \t]*(" + N + r")\s+ENDS\b")
ENDALL = re.compile(r"(?i)^\s*END(?!\s+(?:if|virtual|struc|match|macro)\b)(\s+" + N + r")?\s*$")
LABELDEF = re.compile(r"(?i)^[ \t]*(" + N + r")(\s+)label(\s+)(byte|word|dword)\s*$")
CODELABEL = re.compile(r"(?i)^[ \t]*(" + N + r")\s+label\s+(?:near|far)\s*$")
# A procedure whose name a macro pastes together, which by this point is
# written with the hash fasm pastes with: GSHARE2 declares the fourteen
# entries of its jump table in two IRP blocks, each a J and the name of the
# routine it calls -- "J&rtn proc far" -- so the name here is not one the
# release could write out.
PASTE = r"[A-Za-z_@?$][A-Za-z0-9_@?$#]*"
FARPROCEDURE = re.compile(r"(?i)^[ \t]*procedure[ \t]+" + PASTE
                          + r"[ \t]*,[ \t]*far\b")
ANYPROCEDURE = re.compile(r"(?i)^[ \t]*procedure[ \t]+" + PASTE + r"\b")
PROC = re.compile(r"(?i)^[ \t]*(" + PASTE
                  + r")\s+proc(?:\s+(near|far))?\s*$")
ENDP = re.compile(r"(?i)^[ \t]*" + PASTE + r"\s+endp\s*$")
ENDPROC = re.compile(r"(?i)^[ \t]*endproc\b")

done = {}
for stem in MODULES:
    text = source[stem]
    text = quiet_if1(text)
    text = pass_two(text)
    text = HEADING.sub(heading, text)
    for was, now in MACROS.items():
        text = text.replace(was, now)
    if stem.endswith('.ASM'):
        text = PROCEDURE[0].sub(PROCEDURE[1], text)
    text = struct_arrays(text)
    text = literals(text)
    text = aliased(text)
    text = strings(text)
    text = translated(text)
    text = spaced_overrides(text)
    text = far_pointers(text)
    text = far_jumps(text)
    text = at_far_jumps(text)
    text = far_names(text)
    text = split_dup(text)
    text = segment_values(text)
    text = grouped(text)
    text = offsets(text)
    text = quoted_parameters(text)
    text = substituted(text)
    text = blankness(text, stem)
    text = bare_fields(text)
    text = pasted(text)
    text = counters(text)
    text = for_loops(text, stem)
    text = conditions(text)
    text = thens(text)
    text = distances(text)
    text = places(text)
    text = grouped_equ(text)
    text = dollar_equ(text)
    text = forwards(text)
    text = records(text)
    text = record_fields(text)
    text = tabled(text)
    text = switched(text)
    for was, now in PATCHES.get(stem, ()):
        assert was in text, (stem, was)
        text = text.replace(was, now, 1)
    text = written_over(text)
    text = relations(text)
    out, infar, noted, measured = [], False, False, False
    # the procedures open at this line, innermost last
    opened_procs = []
    opened = []
    # the macro and REPT blocks open inside a module, which close in the
    # order they were opened and with the same word
    blocks = []
    # A file the release reads inside another module's segment is read with
    # that module's ASSUMEs in force, which are not the ones a module of its
    # own would start with: GRAPHICS's GRCOMMON.ASM is INCLUDEd at the end
    # of each printer module, where ASSUME CS:CODE,DS:CODE stands, so MASM
    # wrote no override for anything it reads.  STARTS says so for such a
    # file; everything else starts where START says.
    cover[0] = dict(STARTS.get(stem, START))
    for line in text.split('\n'):
        assumed(code_of(line))
        # a name qualified with a segment, which grouped() marked: it is
        # reached through whichever register the ASSUME in force covers that
        # address space with
        line = re.sub('\x01(\\w+)\x02',
                      lambda m: through(space(m.group(1))), line)
        j = comment_at(line)
        code, comment = (line, '') if j < 0 else (line[:j], line[j:])
        bare, was_len = code.rstrip(), len(code)

        m = MACRODEF.match(bare)
        if m:
            # A macro declared inside another, which MASM let stand and
            # declared where the outer one was called: NLSFUNC's DOESMAC.INC
            # declares the macro that writes a page heading inside the one
            # that calls an installed function.  The braces of the inner one
            # are escaped once for each macro they stand in.
            deep = '\\' * len([b for b in blocks if b != 'rept'])
            inmacro[0] = True
            blocks.append('macro')
            out.append('macro %s %s' % (m.group(1), m.group(2).strip()))
            out.append(deep + '{')
            continue
        # MASM's REPT assembled what follows a given number of times and
        # closed with ENDM like a macro; fasm's REPEAT closes with two words
        # of its own and needs no braces, so it can stand inside a macro
        # body as it is: ASSGMAIN's CallOperRange writes one entry of its
        # table of calls for each call in a range.
        m = re.match(r"(?i)^([ \t]*)REPT[ \t]+([^;]+?)[ \t]*$", bare)
        # fasm has a REPT of its own, which takes the name of the counter
        # after the count and the body in braces -- the rules above write
        # one for an array of structures -- so a REPT with two words after
        # it is already fasm's and stands.
        if m and not re.match(r"^\S+[ \t]+" + N + r"$", m.group(2)):
            blocks.append('rept')
            out.append(pad('%srepeat %s' % (m.group(1), m.group(2)),
                           was_len, comment))
            continue
        # MASM's IRP assembled what follows once for each of a list of
        # arguments, and closed with ENDM like a macro; fasm's IRP takes the
        # list the same way and the body in braces, which inside a macro are
        # escaped once for each macro the braces stand in.
        m = re.match(r"(?i)^([ \t]*)IRP[ \t]+(" + N + r")[ \t]*,[ \t]*"
                     r"<?([^;>]*)>?[ \t]*$", bare)
        if m:
            deep = '\\' * len([b for b in blocks if b != 'rept'])
            blocks.append('irp')
            out.append(pad('%sirp %s, %s %s{'
                           % (m.group(1), m.group(2), m.group(3).strip(),
                              deep), was_len, comment))
            continue
        if blocks and MACROEND.match(bare):
            what = blocks.pop()
            if what == 'irp':
                deep = '\\' * len([b for b in blocks if b != 'rept'])
                out.append(pad(re.match(r"^[ \t]*", bare).group(0)
                               + deep + '}', was_len, comment))
            elif what == 'rept':
                out.append(pad(re.match(r"^[ \t]*", bare).group(0)
                               + 'end repeat', was_len, comment))
            else:
                inmacro[0] = False
                deep = '\\' * len([b for b in blocks if b != 'rept'])
                out.append(deep + '}' + (' ' + comment if comment else ''))
            continue

        # MASM's IFE assembled what follows where its operand came to
        # nought, which fasm asks the other way round.  Where the operand is
        # a comparison -- and MASM's comparisons gave a number, so one could
        # stand inside an expression -- fasm's IF takes the comparison itself
        # and the question is the negation of it: XMAEM's F_DREG asks
        # IFE (_DREGNUM LT 8), whether the register it was given was none of
        # the eight it knows.
        m = re.match(r"(?i)^([ \t]*)IFE[ \t]+(\S.*?)[ \t]*$", bare)
        if m:
            if re.search(r">=|<=|<>|>|<|=", m.group(2)):
                out.append(pad('%sif ~ %s' % (m.group(1), m.group(2)),
                               was_len, comment))
            else:
                out.append(pad('%sif (%s) = 0' % (m.group(1), m.group(2)),
                               was_len, comment))
            continue

        # MASM assembled a JMP to a name it had not read yet as a near
        # one, three bytes of it; fasm measures the distance and writes a
        # short jump wherever one reaches.  That says nothing anywhere the
        # width of a jump is not read -- but a table of jumps is read by
        # index, and every entry of such a table has to be the same width.
        # XMAEM has the two in the release: INDEEMU lays an entry down for
        # each of the 256 op-codes, all of them jumping to the routine for
        # one the emulator does not expect, and INDEDMA one for each of the
        # 32 DMA ports.  Left to fasm the last forty of INDEEMU's came out
        # two bytes, and every entry past them stood at the wrong offset --
        # the emulator would have jumped into the middle of one.
        if [b for b in blocks if b in ('irp', 'rept')]:
            m = re.match(r"(?i)^([ \t]*)JMP([ \t]+)(" + N + r")[ \t]*$", bare)
            if m:
                out.append(pad('%sJMP%snear %s'
                               % (m.group(1), m.group(2), m.group(3)),
                               was_len, comment))
                continue

        # MASM's IFDEF asked whether a name had been given a value, which
        # fasm asks with DEFINED.  The eleven here all ask after fsexec, the
        # name that would have built RECOVER for an installable file system,
        # and nothing in the release gives it one.
        # The name can be one a macro pastes together: DISPLAY's JUMP
        # macro asks IFNDEF LBL&_J, whether the label it was given has been
        # jumped to already, and fasm pastes with # where MASM pasted with
        # &.  Read as a plain name the paste was dropped, and the macro
        # then asked after the label itself -- which is defined -- so every
        # jump took the branch for one it had seen before and measured its
        # distance from a symbol that did not exist.
        PASTED = N + r"(?:[&#]" + N + r")*"
        m = re.match(r"(?i)^([ \t]*)IFDEF\b[ \t]*(" + PASTED + r")", bare)
        if m:
            out.append(pad('%sif defined %s'
                           % (m.group(1), m.group(2).replace('&', '#')),
                           was_len, comment))
            continue
        m = re.match(r"(?i)^([ \t]*)IFNDEF\b[ \t]*(" + PASTED + r")", bare)
        if m:
            out.append(pad('%sif ~ defined %s'
                           % (m.group(1), m.group(2).replace('&', '#')),
                           was_len, comment))
            continue

        # MASM's processor directives said which instructions it would
        # accept, and fasm accepts them all in sixteen-bit mode: the line
        # says nothing here.  RAMDRIVE writes .286p for the code it swaps
        # in above the first megabyte, which uses LOADALL and the other
        # instructions a 286 added.
        if PROCESSOR.match(bare):
            out.append(';' + line)
            continue

        # MASM's EVEN put the location counter on the next even address,
        # filling what it skipped: ASSGMAIN wants its table of calls on one,
        # the handler indexing it by a word.  fasm's ALIGN is the same thing.
        m = re.match(r"(?i)^([ \t]*)EVEN[ \t]*$", bare)
        if m:
            out.append(pad('%salign 2' % m.group(1), was_len, comment))
            continue

        # MASM's LOCAL named the labels a macro wants one of per expansion,
        # which is fasm's local and the same word in lower case: APPEND's
        # JUMP writes a conditional jump over an unconditional one and wants
        # a name for the place after it.
        m = re.match(r"(?i)^([ \t]*)LOCAL([ \t]+" + N + r"(?:[ \t]*,[ \t]*"
                     + N + r")*)[ \t]*$", bare)
        if m:
            out.append(pad('%slocal%s' % (m.group(1), m.group(2)),
                           was_len, comment))
            continue

        # MASM closed a conditional with one word and fasm with two
        m = re.match(r"(?i)^([ \t]*)ENDIF\b", bare)
        if m:
            out.append('%send if%s' % (m.group(1),
                                       ' ' + comment if comment else ''))
            continue

        # MASM's ORG moved the location counter, and LINK filled what it
        # moved over with zeros.  To a number it placed what followed, which
        # is what fasm's own org does; over an expression in $ it padded to a
        # boundary -- GRTABHAN pads its resident part to a paragraph -- and
        # fasm's org moves the address and not the place the output goes, so
        # that one has to be the zeros themselves.
        # MASM's ORG backwards moved the counter back over what had just
        # been assembled, and what came next was laid over it: RESCODE
        # writes the three forms its redirection jump can take one on top of
        # another, and the image holds the last of them for the resident
        # code to patch where it stands.  fasm writes its output as it goes
        # and cannot move back over it, so the forms that are written over
        # are assembled in a VIRTUAL block at the same address, which reads
        # them and lays down nothing.
        m = re.match(r"(?i)^([ \t]*)ORG[ \t]+\$[ \t]*-[ \t]*(\d+)[ \t]*$",
                     bare)
        if m:
            lead = m.group(1)
            for i in range(len(out) - 1, -1, -1):
                if not code_of(out[i]).strip():
                    continue
                # the only one of these is a two-byte jump, and a wider
                # reach would have to know how long each line comes to
                assert m.group(2) == '2' and re.match(r"(?i)^[ \t]*j\w+[ \t]",
                                                     out[i]), (stem, out[i])
                out[i:i + 1] = [lead + 'virtual at $', out[i],
                                lead + 'end virtual']
                break
            continue

        # MASM counted an ORG from the start of the segment it stood in,
        # and a segment read into a flat address space no longer begins
        # where the address counter does: PRINT_T opens its data with
        # ORG 0, which said only that the segment starts at nought and is
        # where the walk has already put it.  fasm's org would move the
        # counter back to the start of the whole address space and leave
        # every name in the data at the wrong offset, so it goes.
        m = re.match(r"(?i)^([ \t]*)ORG[ \t]+0[ \t]*$", bare)
        if m and not ONESEG and opened and opened[-1][1] == 'guard' \
                and not [l for l in out[opened[-1][2]:]
                         if code_of(l).strip()]:
            out.append(';' + line)
            continue

        m = re.match(r"(?i)^([ \t]*)ORG[ \t]+([^;]+?)[ \t]*$", bare)
        if m and '$' in m.group(2):
            out.append(pad('%stimes (%s) - $ db 0'
                           % (m.group(1), m.group(2).strip()),
                           was_len, comment))
            continue

        if GROUP.match(bare):
            out.append(';' + line)
            continue
        m = SEGMENT.match(bare)
        if m:
            at = re.search(r"(?i)\bAT[ \t]+([^;]+?)[ \t]*$", bare)
            if at:
                # MASM's SEGMENT AT names the places in a piece of memory the
                # program does not lay down: GRTABHAN's DUMMY_SEG AT 0 holds
                # one FAR label and no bytes, to make MASM write a far jump
                # direct whose address the loader patches, and MODE's ROM and
                # VECT name what the ROM BIOS and the vector table hold.  A
                # VIRTUAL block says the same and writes nothing.
                #
                # Where the modules are read once per segment they would be
                # read once per segment too, and the names in them declared
                # as many times, so they are given a pass of their own: one
                # for all of them, there being nothing to lay down in it.
                if ONESEG:
                    opened.append((m.group(1).upper(), 'virtual', len(out)))
                    out.append('virtual at %s%s' % (at.group(1), comment))
                    continue
                if opened:
                    out.append('end if')
                opened.append((m.group(1).upper(), 'guardvirtual',
                               len(out) + 2))
                out.append('if SEGSEL = S_ABSOLUTE')
                out.append('virtual at %s%s' % (at.group(1), comment))
                continue
            if ONESEG:
                # one segment, and the modules are read once, so there is no
                # pass for the line to choose between
                opened.append((m.group(1).upper(), 'comment', len(out)))
                out.append(';' + line)
                continue
            # MASM let a segment stand inside another, and the inner one's
            # ENDS went back to the one it stood in.  FORMAT writes its data
            # that way, each piece beside the code that reads it, so the
            # module's code segment is open from its head to its end.  Here
            # a segment is a pass of its own, so what was open is closed
            # before the inner one opens and opened again after it ends.
            if opened:
                out.append('end if')
            opened.append((m.group(1).upper(), 'guard', len(out) + 1))
            out.append('if SEGSEL = S_%s%s'
                       % (opened[-1][0],
                          ' ' + comment if comment else ''))
            continue
        if SEGEND.match(bare):
            how = opened.pop()[1] if opened else 'guard'
            if how == 'guardvirtual':
                out.append('end virtual' + (' ' + comment if comment else ''))
                out.append('end if')
                if opened and opened[-1][1] == 'guard':
                    out.append('if SEGSEL = S_%s' % opened[-1][0])
                    opened[-1] = opened[-1][:2] + (len(out),)
            elif how == 'virtual':
                out.append('end virtual' + (' ' + comment if comment else ''))
            elif how == 'comment':
                out.append(';' + line)
            else:
                out.append('end if' + (' ' + comment if comment else ''))
                if opened and opened[-1][1] == 'guard':
                    out.append('if SEGSEL = S_%s' % opened[-1][0])
                    opened[-1] = opened[-1][:2] + (len(out),)
            continue
        if DIRECTIVE.match(code) or ENDALL.match(bare):
            out.append(';' + line)
            continue
        # INC/DOSMAC.INC's procedure says the distance after a comma where
        # MASM's PROC says it after a space, and a RET inside one of those
        # is a far return just the same: IFSERROR's INT_2F_5 ends with a
        # RET 2 it calls a fakey IRET, and IFSFDOS's IFSFUNC_DOSCALL@ with
        # a plain RET.  checkcode.py has read this form since it was
        # written; the conversion had not.
        # MASM let one procedure stand inside another, and PRINTER writes
        # four that way: INTERRUPT1, INTERRUPT2 and INTERRUPT3 are declared
        # inside INTERRUPT0, whose ENDP is four hundred lines below theirs,
        # and the exit every one of them returns through stands after the
        # inner three have been closed.  So the procedures open here are a
        # stack and a RET is far or near by the innermost of them: read with
        # one flag, the first inner ENDP ended the outer procedure and the
        # shared exit's RET came out near, where DOS had far-called the
        # driver.  The machine ran away into the driver's own data.
        m = FARPROCEDURE.match(bare)
        if m:
            opened_procs.append(('procedure', True))
            infar = True
        elif ANYPROCEDURE.match(bare):
            opened_procs.append(('procedure', False))
            infar = False
        m = PROC.match(bare)
        if m:
            opened_procs.append(('proc', (m.group(2) or '').lower() == 'far'))
            infar = opened_procs[-1][1]
            out.append(pad('%s:' % m.group(1), was_len, comment))
            continue
        if ENDP.match(bare):
            infar = close_proc(opened_procs, 'proc')
            out.append(';' + line)
            continue
        # INC/DOSMAC.INC's EndProc closes a procedure as well, and RECOVER
        # closes twenty-four of its own that way: int_24, the only one
        # declared FAR, is one of them, so the RETs after it are near again.
        if ENDPROC.match(bare):
            infar = close_proc(opened_procs, 'procedure')
        m = INSTANCE.match(bare)
        if m:
            # An address among the values is the name itself here, as it is
            # in an operand: APPEND fills its parameter block in with
            # OFFSET px_block1.  The line is written whole and does not
            # reach the rules that read operands, so the OFFSET comes off
            # here.
            args = re.sub(r"(?i)\boffset\s+", '', sizes(m.group(3)))
            # An instance that fills nothing in: PRINTER writes
            # REQ_NORM1 GIH <,,,,,> for the three request packets it keeps
            # and FTB1 FTBLK <,,,,,,,,,,,,> for twelve font table blocks,
            # which is MASM's way of saying every field takes the value its
            # declaration gave it.  fasm takes an argument left out as the
            # default and an empty one as nothing at all, so the commas go.
            if args.strip(', \t') == '':
                args = ''
            # A colon after the instance's name, which MASM read as a
            # label's and laid the instance down under: ANSI writes the
            # console's buffer as BUF1: BUF_DATA <>.  fasm names an
            # instance, and the name takes no colon.
            head = re.sub(r"^(\s*" + N + r")\s*:(\s*)$", r"\1\2 ",
                          m.group(1))
            out.append(pad('%s%s %s' % (head, m.group(2), args),
                           was_len, comment))
            continue
        # The same thing written with no name, which MASM wanted none for.
        # PRINT_R lays a QEA and an EA down inside the two tables it asks
        # the extended attribute calls with, each under a label the table
        # itself carries, and nothing reads the instance by a name: the one
        # given here is the structure's with a count after it.
        m = NAMELESS.match(bare)
        if m:
            kind = m.group(2)
            if inmacro[0]:
                # Inside a macro body the made-up name has to be new on
                # every expansion, which is what fasm's LOCAL is for:
                # COUNTRY's CTRYENT macro lays one CTRYSTR down for each
                # country it is called with, and a name of this
                # conversion's own would be defined over again on the
                # second call.
                args = re.sub(r"(?i)\boffset\s+", '', sizes(m.group(3)))
                out.append('%slocal anon$' % m.group(1))
                out.append(pad('%sanon$ %s %s' % (m.group(1), kind, args),
                               was_len, comment))
                continue
            nameless[kind.upper()] = nameless.get(kind.upper(), 0) + 1
            args = re.sub(r"(?i)\boffset\s+", '', sizes(m.group(3)))
            out.append(pad('%s%s$%d %s %s'
                           % (m.group(1), kind, nameless[kind.upper()],
                              kind, args), was_len, comment))
            continue
        m = re.match(r"(?i)^(\s*)INCLUDE\s+(\S+)\s*$", bare)
        if m:
            out.append(pad("%sinclude '%s'" % (m.group(1), m.group(2).upper()),
                           was_len, comment))
            continue
        m = LABELDEF.match(bare)
        if m:
            # The width the modules that read it asked for, where they all
            # asked the same and the storage under the label does not bear
            # the declaration out: MODESUBS labels the four sublist pointers
            # BYTE over a DW.
            kinds = set() if m.group(1).lower() in BORNEOUT \
                else ASKED.get(m.group(1).lower(), set())
            kind = next(iter(kinds)) if len(kinds) == 1 else m.group(4).lower()
            out.append(pad('label %s %s' % (m.group(1), kind),
                           was_len, comment))
            continue
        # LABEL NEAR names a place in the code, which is a label like any
        # other; LABEL BYTE and its like name a place in the data, and fasm
        # wants the size for those.
        m = CODELABEL.match(bare)
        if m:
            out.append(pad('%s:' % m.group(1), was_len, comment))
            continue
        # MASM assembled a far procedure's RET as a far return, with the
        # count of bytes to throw away after it where it had one: PRINT_R
        # chains interrupt 13H to the ROM by pushing the address of
        # INT_13_BACK under the ROM's own, so what comes back there is a
        # far call with the caller's flags under it, and the RET 2 that
        # ends it is a far return over them.
        # A label of its own on the line is no reason to miss it: the
        # kernel's MAP_CASE ends with "L_RET:\tRET" inside a FAR
        # procedure, and that one had to be put right by hand.
        m = infar and re.match(r"(?i)^(\s*(?:" + N + r":)?\s*)"
                               r"(ret)(\s+[0-9A-Fa-f]+h?)?\s*$", bare)
        if m:
            out.append(pad('%s%s%s' % (m.group(1),
                                       m.group(2) + ('F' if m.group(2).isupper()
                                                     else 'f'),
                                       m.group(3) or ''), was_len, comment))
            continue

        # The question mark can stand in brackets of its own, which say as
        # little as it does: XMA2EMS's EMSINIT reserves the model byte with
        # DB (?), and SELECT three words the same way.
        code = re.sub(r"(?i)^(" + N + r"?\s*)\bdb\s+\(?\?\)?\s*$",
                      r"\1rb      1", code)
        code = re.sub(r"(?i)^(" + N + r"?\s*)\bdw\s+\(?\?\)?\s*$",
                      r"\1rw      1", code)
        code = re.sub(r"(?i)^(" + N + r"?\s*)\bdd\s+\(?\?\)?\s*$",
                      r"\1rd      1", code)
        code = re.sub(r"(?i)\bdb\s+(.+?)\s+dup\s*\(\s*\?\s*\)", r"rb      \1", code)
        code = re.sub(r"(?i)\bdw\s+(.+?)\s+dup\s*\(\s*\?\s*\)", r"rw      \1", code)

        if not re.match(r"\s*(HEADER|SUBTTL|TITLE)\b", code):
            code = typed(code)
            said = measures(code)
            if said != code and not measured:
                out.append('; MASM worked LENGTH out as the number of elements'
                           ' a variable was')
                out.append('; declared with and SIZE as the bytes they take up.'
                           '  The arrays these')
                out.append('; ask about are all of bytes, so the two come to'
                           ' the same number.')
                measured = True
            code = said

        # A structured statement's condition is text until STRUC.INC takes
        # it apart, so the rules below would pass over the operands in it.
        # It is turned into the comparison STRUC.INC will make of it, run
        # through them with everything else, and put back.
        held = CONDITION.match(code)
        if held:
            # MASM put its own brackets round an operand of more than one
            # word, which the operators round it no longer need: MODE writes
            # <AX EQ <07H+19>> for a message number.
            right = held.group(5).strip()
            if right.startswith('<') and right.endswith('>'):
                right = '(%s)' % right[1:-1].strip()
            code = '%scmp %s,%s' % (' ' * len(held.group(1)), held.group(3),
                                    right)

        # The line that gives a place its name is already what it should
        # be: the brackets go where the name is used.
        m = re.match(r"(?i)^[ \t]*(" + N + r")[ \t]+equ\b", bare)
        if m and m.group(1).lower() in PLACED:
            out.append(code + comment)
            continue

        code = absolutes(code)
        code = structures(code)
        code = overlaid(code)
        code = parenthesised(code)
        code = refs(code)
        code = joined(code)
        code = indexed(code)
        code = fielded(code)
        code = displaced(code)
        code = strung(code)
        # A type name in an expression was the number of bytes it takes up.
        # WORD PTR has become a lower case size by now, so an upper case WORD
        # left over is one of those: the word pushed before a call, the high
        # half of a vector, the second of two graphic characters.
        if not re.match(r"\s*(HEADER|SUBTTL|TITLE)\b", code):
            said = sizes(code)
            if said != code and not noted:
                out.append('; MASM read a type name in an expression as the '
                           'number of bytes it')
                out.append('; takes up, so BYTE on its own is 1 and WORD is '
                           '2.')
                noted = True
            code = said

        code = bracket(code)
        code = overridden(code)
        code = re.sub(r"(?i)\boffset\s+", '', code)
        # A structured statement's operand written in angle brackets of its
        # own because MASM's library read a condition as a list of words:
        # GRINST asks .IF <AX B <OFFSET LIMIT>>, and with the OFFSET gone
        # the group holds one word, which is what it would have been
        # without the brackets.  fasm's MATCH hands the brackets to the
        # instruction, so they come off -- except round a name that stands
        # for a reference with a width, where the brackets are what tells
        # the statement it is more than one word.
        m = re.match(r"(?i)^([ \t]*(?:" + N + r":)?[ \t]*\."
                     + STATEMENTS + r"\b[ \t]*<)(.*)$", code)
        if m:
            # Only inside the condition's own brackets: the outermost pair
            # is the condition itself, and a flag written on its own --
            # NLSFUNC's .IF <NC> -- is one word in them already.
            code = m.group(1) + re.sub(
                r"<(" + N + r")>",
                lambda m2: (m2.group(0) if m2.group(1).lower() in WIDE
                            else m2.group(1)), m.group(2))
        code = sized(code)
        code = pushed(code)
        code = jumped(code)
        code = tenbytes(code)
        # The source wrote brackets of its own round a reference whose
        # field the rules have since taken apart: SMARTDRV writes
        # TEST [REGION.FLAG],REG1_P, and what the rules make of the inside
        # of it is a width and brackets again.  The outer pair says no more
        # than the inner one, and a width belongs outside them both.
        code = re.sub(r"\[[ \t]*(" + PTRSIZES + r")?[ \t]*"
                      r"(\[[^\[\]]*\])[ \t]*\]",
                      lambda m: (m.group(1) + ' ' if m.group(1) else '')
                      + m.group(2), code, flags=re.I)
        # And where the source said the width itself in front of its own
        # brackets -- MOV BYTE PTR [REGION.FLAG],0 -- the rules inside them
        # said it again.  One width is what MASM assembled.
        code = re.sub(r"(?i)\b(" + PTRSIZES + r")[ \t]+(?:" + PTRSIZES
                      + r")[ \t]*(\[)", lambda m: '%s %s' % (m.group(1),
                                                             m.group(2)),
                      code)

        if held:
            m2 = re.match(r"(?i)^\s*cmp\s+(.*?)\s*,\s*(.*?)\s*$", code)
            left, right = (m2.group(1), m2.group(2)) if m2 \
                else (held.group(3), held.group(5))
            # a left side of more than one word goes in brackets of its own,
            # because fasm's MATCH splits the condition into its tokens
            if not left.startswith('<') \
                    and (re.search(r"[\s\[\]:]", left)
                         or left.lower() in WIDE):
                left = '<%s>' % left
            code = '%s%s <%s %s %s>%s' % (held.group(1), held.group(2), left,
                                          held.group(4).upper(), right,
                                          held.group(6) or '')

        if comment and len(code) != was_len:
            stripped = code.rstrip()
            code = (stripped + ' ' * (was_len - len(stripped))) \
                if len(stripped) < was_len else stripped + ' '
        out.append(code + comment)
    done[stem] = out

# MASM did not mind what case a name was written in and fasm does, so every
# reference takes the spelling of the line that declares it.
# E2BTABLE.INC makes a message's label by handing its name to Define_Msg,
# which is where that name is declared, so a reference to it takes the
# spelling written there.
# RECOVER declares a routine by handing its name to the Procedure macro,
# which is where the name is written down, so a call to it takes the
# spelling written there: RECINIT says Procedure Init_IO and calls Init_Io.
# DOSMAC.INC's entry macro lays a label down, and its name may end in a
# dollar -- the house gives one to every $-named procedure -- so what
# follows it here is not \b, which would let the dollar be left off:
# "entry GET_IN_VARS$,FAR" was read as a declaration of GET_IN_VARS, and
# INC/SYSCALL.INC's Get_In_Vars, the number of that DOS call, then took its
# spelling from a name that is not it.  The other arms keep \b, which is
# what every utility converted so far was read with.
# A label can have white space in front of its colon -- DISPLAY's
# F-PARSER.INC writes "filetag :" and PRINTER's CPSPI07 three dozen of
# them -- and what reads it writes the name in capitals, which was one
# name to MASM.
DECL = re.compile(r"(?i)^\s*(?:(" + N + r")\s*:|(" + N + r")\s+(?:(?:db|dw|dd|"
                  r"rb|rw|rd|equ)\b|=)|label\s+(" + N + r")\b|macro\s+(" + N
                  + r")\b|Define_Msg\s+(" + N + r")\b|Procedure\s+("
                  + N + r")\b|STRUC\s+(" + N + r")\b|I_am\s+("
                  + N + r")\b|entry\s+(" + N + r")(?![\w@?$]))")
# The program's own modules name a thing first; the shared headers under
# src/INC come after, so a name they both have takes the module's spelling.
# MASM did not mind the case and fasm does, so a reference has to be written
# the way its declaration was -- INC/SYSCALL.INC calls the function Open and
# EXE2BIN asks for open.
# The include file BUILDMSG writes is read as well.  It is no module of the
# program's -- a module INCLUDEs it by name -- so nothing above has seen it,
# and the labels in it are the spellings the skeleton gave them: XMA2EMS.SKL
# names Welcome_Msg and the code asks for WELCOME_MSG, which was one name to
# MASM.  XMAEM is the same, and the thirty other programs declare their
# messages in upper case and so never showed it.
for lines in (list(done.values())
              + [open(R + n, encoding='cp437').read().split('\n')
                 for n in sorted(os.listdir(R))
                 if re.match(r"(?i)^.*\.CL[0-9A-Z]$", n)]
              + [read(h + '.INC', converted=True).split('\n')
                 for h in HEADERS]
              + [shared(h).split('\n') for h in SHARED]):
    for line in lines:
        m = DECL.match(code_of(line))
        if m:
            name = next(g for g in m.groups() if g)
            spelling.setdefault(name.lower(), name)
        # a procedure declared through the utility's own Procedure macro,
        # whose name stays on the line that calls the macro: FORPROC
        # declares Procedure YES? where FORMAT.ASM calls Yes?, and MASM read
        # the two as one name.
        m = re.match(r"(?i)^[ \t]*Procedure[ \t]+(" + N + r")",
                     code_of(line))
        if m:
            spelling.setdefault(m.group(1).lower(), m.group(1))
spelling.update({'sysdispmsg': 'SYSDISPMSG', 'sysloadmsg': 'SYSLOADMSG',
                 'sysgetmsg': 'SYSGETMSG', 'sysparse': 'SysParse'})
# and whatever spelling the utility reads a name at that is declared
# somewhere this cannot see
spelling.update(U.get('SPELLING', {}))

KEEP = set('''ax bx cx dx si di bp sp al bl cl dl ah bh ch dh cs ds es ss
byte word dword qword ptr near far short dup rb rw rd equ label macro align
org use16 if else end include format entry stack segment and or not xor shl
shr mod match'''.split())


def respell(line):
    code, sep, comment = line.partition(';')
    if re.match(r"\s*(HEADER|SUBTTL|TITLE)\b", code):
        return line
    pieces, i = [], 0
    while i < len(code):
        c = code[i]
        if c in '\'"':
            j = code.find(c, i + 1)
            j = len(code) if j < 0 else j + 1
            pieces.append(code[i:j])
            i = j
            continue
        m = re.match(N + r"|.", code[i:], re.S)
        tok = m.group(0)
        # a name after a dot is a field of the structure before it, so it
        # takes the spelling that structure declares for it
        if i > 0 and code[i - 1] == '.' and len(tok) > 1:
            found = FIELD.get(tok.upper())
            tok = found[1] if found else spelling.get(tok.lower(), tok)
        elif len(tok) > 1 and tok.lower() not in KEEP:
            tok = spelling.get(tok.lower(), tok)
        pieces.append(tok)
        i += len(m.group(0))
    return ''.join(pieces) + sep + comment


for stem, lines in done.items():
    open(written(stem), 'w', encoding='cp437', newline='\n').write(
        '\n'.join(respell(l) for l in lines))
print('storage %d, spellings %d' % (len(DATA), len(spelling)))
