"""A utility under src/CMD from MASM to fasm, in place.

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
in src/CMD/<UTILITY> is the release's own text until this has run over it:
that is where it reads from unless told otherwise.  To run it again
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
}

NAME = sys.argv[1].upper() if len(sys.argv) > 1 else ''
if NAME not in UTILITIES:
    sys.exit('usage: convert.py UTILITY [ORIGINALS]\n'
             '       UTILITY is one of ' + ', '.join(sorted(UTILITIES)))
U = UTILITIES[NAME]
HERE = os.path.dirname(os.path.abspath(__file__)) + '/'
R = HERE + 'src/CMD/' + NAME + '/'
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
    return open(HERE + 'src/INC/' + name,
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
# name is the one the parser gives it.
def parser_names(text):
    return re.sub(r"(?i)(?<![\w$])\$(p_" + N + r")",
                  lambda m: m.group(1), text)


# Words fasm keeps for itself which the utility uses for its own -- COMP's
# getsec is an instruction of a later processor, EXE2BIN's LOAD and STORE are
# directives.  Each takes a trailing underscore, the way TCMD1A's Display_
# and TREE's RESTORE_ did.  fasm reads a directive's name whatever case it is
# written in, so a name that collides collides in every spelling.
RESERVED = U.get('RESERVED', ())

source = {m: parser_names(dollars(read(m), TAG[m]))
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
            code = outside_strings(r"(?<![A-Za-z0-9_@?$.])" + was
                                   + r"(?![A-Za-z0-9_@?$])", now, code)
        out.append(code + comment)
    source[stem] = '\n'.join(out)


# Labels a module keeps to itself, which MASM let every module have because
# it assembled them apart: MODE writes endif01 and p0 to p7 by hand in five
# modules apiece.  Each takes the name of the module it is in.
LOCALS = U.get('LOCALS', ())
if LOCALS:
    localpat = re.compile(r"(?i)^(?:" + "|".join(LOCALS) + r")$")
    for stem in MODULES:
        mark = stem.split('.')[0].lower()
        mine = set()
        for line in source[stem].split('\n'):
            # MODE writes some of its labels against the margin and some
            # of them indented, and the names it keeps to itself are
            # equates as well: one-letter ones, which the structured
            # statements want for the flags and two modules give different
            # values to.
            code = code_of(line)
            m = re.match(r"^[ \t]*(" + N + r"):", code) \
                or re.match(r"(?i)^(" + N + r")[ \t]+(?:equ|=)[ \t]", code)
            if m and localpat.match(m.group(1)):
                mine.add(m.group(1))
        if not mine:
            continue
        out = []
        for line in source[stem].split('\n'):
            j = comment_at(line)
            code, comment = (line, '') if j < 0 else (line[:j], line[j:])
            for name in sorted(mine, key=len, reverse=True):
                code = outside_strings(r"(?<![A-Za-z0-9_@?$.])"
                                       + re.escape(name)
                                       + r"(?![A-Za-z0-9_@?$])",
                                       '%s_%s' % (name, mark), code)
            # A name a macro pastes together is not the name until fasm has
            # put it together, so the rule above passes over it: MODELENG's
            # BREAK writes JMP ENDCASE_#destination for one of the ENDCASE_0
            # and the rest it has of its own, and the module's mark goes on
            # the end of the paste.
            def paste(m2, mark=mark, mine=mine):
                stem, arg = m2.group(1), m2.group(2)
                if not localpat.match(stem + '0'):
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
    and "load another character" is not the directive.
    """
    out = []
    for line in text.split('\n'):
        j = comment_at(line)
        code, comment = (line, '') if j < 0 else (line[:j], line[j:])
        for name in RESERVED:
            code = re.sub(r"(?i)(?<![A-Za-z0-9_@?$.])" + name
                          + r"(?![A-Za-z0-9_@?$])", name + '_', code)
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

    return re.sub(r"(?mi)^(" + N + r")[ \t]+(" + N + r")[ \t]+(\S+)[ \t]+"
                  r"dup[ \t]*\([ \t]*<[ \t]*>[ \t]*\)[ \t]*(;[^\n]*)?$",
                  one, text)


def far_pointers(text):
    """DD of a qualified name, which MASM wrote as a far pointer.

    MASM's DD of a name laid down an offset and a segment, the segment for
    the loader to fix up.  fasm's DD of a name is the offset and nothing
    else, so the two halves are written as the two words they are.
    """
    def one(m):
        head, seg, name = m.group(1), m.group(2), m.group(3)
        return '%sdw %s%s\n\tdw %s' % (head, name, m.group(4) or '',
                                       SEGMAP[seg.upper()])

    return re.sub(r"(?mi)^([ \t]*(?:" + N + r"[ \t]+)?)dd[ \t]+(" + SEGPAT
                  + r")[ \t]*:[ \t]*(" + N + r")[ \t]*(;[^\n]*)?$", one, text)


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
    text = re.sub(r"(?mi)^([ \t]*dw[ \t]+)(" + SEGPAT
                  + r")([ \t]*)(;[^\n]*)?$",
                  lambda m: '%s%s%s%s' % (m.group(1), segvalue(m.group(2)),
                                          m.group(3), m.group(4) or ''), text)
    text = re.sub(r"(?mi)^([ \t]*(?:" + N + r":)?[ \t]*mov[ \t]+" + N
                  + r"[ \t]*,[ \t]*)(" + SEGPAT + r")(?![\w:.])",
                  lambda m: m.group(1) + segvalue(m.group(2)), text)

    # MASM's SEG, the segment a name is in, which fasm has no operator for:
    # FORMAT asks for SEG DATA where it is about to load DS, and the name of
    # the fasm segment is that segment.
    def seg(m):
        name = m.group(2).upper()
        where = name if name in SEGMAP else SEGOF.get(m.group(2).lower())
        return SEGMAP[space(where)] if where else m.group(0)

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
    text = re.sub(r"(?i)\boffset[ \t]+(?:" + SEGPAT + r")[ \t]*:[ \t]*",
                  'offset ', text)
    text = re.sub(r"(?mi)^([ \t]*(?:" + N + r"[ \t]+)?d[bwdq][ \t]+"
                  r"(?:[^;\n]*,)?[ \t]*)(?:" + SEGPAT + r")[ \t]*:[ \t]*",
                  lambda m: m.group(1), text)
    return re.sub(r"(?i)(?<![\w.])(" + SEGPAT + r")[ \t]*:[ \t]*",
                  lambda m: '\x01%s\x02' % m.group(1).upper(), text)


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
    SCALAR = re.compile(r"(?i)^([ \t]*)(" + N + r")([ \t]+)(D[BWD])([ \t]+)"
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
                measure = ', '.join(
                    [value if value[:1] in ('\'', '"') else '0'
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
            m = re.match(r"(?i)^([ \t]*)(" + N + r")([ \t]+)(D[BWD])\b", code)
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
            body.append(line)
            continue
        out.append(line)
    return '\n'.join(top + out)

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
    source[stem] = declarations(source[stem])



# What the whole program gives storage to, and how each name is spelled where
# it is declared: one segment, so one set of each for all of it.
DATA, SIZE, spelling = set(), {}, {}
# The names an EQU gives to a place rather than to a number: the brackets
# belong where such a name is used and not where it is declared, so the line
# that declares it is left alone.
PLACED = set()
# What each module asked a name it does not declare to be.  MASM took a
# module at a time and LINK never compared the two, so a program could
# declare a place one width and read it another: MODESUBS gives pbaud_ptr a
# BYTE label over a DW, and the two modules that store into it both ask for
# it as a WORD and so stored a word.  One assembly has to settle on a width,
# and the width the code was assembled with is the one that makes it run.
ASKED = {}
for text in (list(source.values())
             + [read(h + '.INC', converted=True) for h in HEADERS]):
    for line in text.split('\n'):
        code = code_of(line)
        m = re.match(r"^[ \t]*(" + N + r")\s+(db|dw|dd)\b", code, re.I)
        if m:
            DATA.add(m.group(1).lower())
            SIZE[m.group(1).lower()] = {'db': 'byte', 'dw': 'word',
                                        'dd': 'dword'}[m.group(2).lower()]
        m = re.match(r"^[ \t]*(" + N + r")\s+label\s+(byte|word|dword)\b", code, re.I)
        if m:
            DATA.add(m.group(1).lower())
            SIZE[m.group(1).lower()] = m.group(2).lower()
        # An EQU that names a place rather than a number is storage as much
        # as a DB is: MODELENG's BIOS_date EQU ES:[DI].
        m = re.match(r"(?i)^[ \t]*(" + N + r")\s+equ\s+"
                     r"(?:(?:cs|ds|es|ss):)?\s*\[[^\]]+\]\s*$", code)
        if m:
            DATA.add(m.group(1).lower())
            PLACED.add(m.group(1).lower())
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
INSTANCE = re.compile(r"^(\S+\s+)(" + '|'.join(sorted(STRUCS))
                      + r")\s*<(.*)>\s*$", re.I)

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
        m = re.match(r"^[ \t]*(" + N + r")\s+(" + '|'.join(sorted(STRUCS))
                     + r")(\s|<|$)", code_of(line), re.I)
        # the one each layout writes inside its VIRTUAL block, to measure
        # the structure by, names the structure after itself and is no
        # instance of the program's: CHKEQU.INC's DIRENT DIRENT is that.
        if m and m.group(1).lower() == m.group(2).lower():
            continue
        if m:
            WRITTEN.add(m.group(1).lower())
            WRITTENAS.setdefault(m.group(1).lower(), m.group(2))
            # one of these is a declaration like any other, so a reference
            # to it takes the spelling written here
            spelling.setdefault(m.group(1).lower(), m.group(1))
            if m.group(2) in FIRST:
                SIZE[m.group(1).lower()] = FIRST[m.group(2)]
                DATA.add(m.group(1).lower())

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


MACROS = U.get('MACROS', {})

for ending in ('\tendm\t\t\t\t;AN000;',):
    MACROS[ending] = '}'

# MASM's ORG inside a segment wrote the filler it skipped over; fasm's moves
# the address counter and writes nothing, which would put the addresses out
# of step with the file.  ALIGN is the same thing said in a way that writes.
PATCHES = U.get('PATCHES', {})


SWITCHES = {'FARSW': 'FarSW', 'DATESW': 'DateSW', 'TIMESW': 'TimeSW',
            'FILESW': 'FileSW', 'CMPXSW': 'CmpxSW', 'DRVSW': 'DrvSW',
            'QUSSW': 'QusSW', 'NUMSW': 'NumSW', 'KEYSW': 'KeySW',
            'SWSW': 'SwSW', 'VAL1SW': 'Val1SW', 'VAL2SW': 'Val2SW',
            'VAL3SW': 'Val3SW', 'INCSW': 'IncSW', 'BASESW': 'BaseSW'}


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
    return re.sub(r"(?i)\b(offset[ \t]+)(?:cs|ds|es|ss)[ \t]*:[ \t]*",
                  lambda m: m.group(1), text)


# The structured statements INC/STRUC.INC takes a condition for.  A
# conjunction or a jump distance after one needs a comma, and THEN or DO
# after one is nothing at all.
STATEMENTS = r"(?:IF|ELSEIF|WHILE|UNTIL|REPEAT|WHEN|LEAVE|EXITIF|SELECT)"
# A statement, its condition taken apart into the two sides of a comparison
# and the operator between them, with whatever follows the condition kept.
CONDITION = re.compile(r"(?i)^([ \t]*)(\." + STATEMENTS + r")[ \t]+"
                       r"<[ \t]*(.*?)[ \t]+"
                       r"(EQ|NE|LT|GT|LE|GE|AE|BE|AB|BL)[ \t]+"
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
    return re.sub(r"(?mi)^([ \t]*\." + STATEMENTS + r"\b"
                  r"[^;\n]*?[^;,\s])"
                  r"((?:[ \t]+(?:AND|OR|NEAR|FAR|SHORT|LONG)\b)+)"
                  r"[ \t]*(;[^\n]*)?$", one, text)


def blankness(text):
    """IFB and IFNB inside a macro, which asked whether an argument was
    given at all.

    fasm asks it with MATCH: against nothing for IFB, and against a name
    that takes whatever there is for IFNB.  The braces are the macro's own,
    so they are escaped, and the ENDIF that closes one of these is a brace
    rather than an END IF.  MODE writes five of them, which is what lets
    SCRN take a mode as well as a function.
    """
    out, inmacro, depth = [], False, []
    for line in text.split('\n'):
        code = code_of(line)
        note = line[len(code):]
        if MACRODEF.match(code):
            inmacro, depth = True, []
            out.append(line)
            continue
        if inmacro and MACROEND.match(code):
            inmacro = False
            out.append(line)
            continue
        m = re.match(r"(?i)^([ \t]*)IF(N?)B[ \t]+<(.*?)>[ \t]*$", code)
        if inmacro and m:
            # The braces are the macro's own, and one inside another wants
            # a backslash for every level it is in: MODECPEQ's DOSCALL asks
            # about its function and then about its subfunction.
            depth.append((m.group(3), bool(m.group(2))))
            out.append('%smatch %s, %s %s{%s'
                       % (m.group(1), 'any$' if m.group(2) else '',
                          m.group(3), '\\' * len(depth), note))
            continue
        # The other way round: what MASM wrote after an ELSE is what there
        # is to do when the argument is the other thing, which is a MATCH of
        # its own.  MODECPEQ writes one, for a call with no subfunction.
        m = re.match(r"(?i)^([ \t]*)ELSE[ \t]*$", code)
        if inmacro and m and depth:
            name, given = depth[-1]
            out.append('%s%s}%s' % (m.group(1), '\\' * len(depth), note))
            out.append('%smatch %s, %s %s{'
                       % (m.group(1), '' if given else 'any$', name,
                          '\\' * len(depth)))
            continue
        m = re.match(r"(?i)^([ \t]*)ENDIF\b", code)
        if inmacro and m and depth:
            out.append('%s%s}%s' % (m.group(1), '\\' * len(depth), note))
            depth.pop()
            continue
        out.append(line)
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
    OPS = r"(?:EQ|NE|LT|GT|LE|GE|AE|BE|AB|BL|ABOVE|BELOW)"

    def place(word):
        """A bare name of storage, in the brackets a condition needs.

        The rules that bracket an instruction's operands do not reach inside
        a condition, which is macro text until STRUC.INC takes it apart, so
        a name there is bracketed here.
        """
        return ('[%s]' % word
                if re.match(r"^" + N + r"$", word) and word.lower() in DATA
                else word)

    def one(m):
        head, cond, tail = m.group(1), m.group(2), m.group(3)
        inner = re.match(r"(?i)^[ \t]*(.*?)[ \t]+(" + OPS + r")[ \t]+(.*)$",
                         cond)
        if not inner:
            return m.group(0)
        left, right = place(inner.group(1).strip()), \
            place(inner.group(3).strip())
        if left.startswith('<') or not re.search(r"[\s\[\]:]", left):
            if right == inner.group(3).strip():
                return m.group(0)
            return '%s<%s %s %s>%s' % (head, left, inner.group(2), right, tail)
        return '%s<<%s> %s %s>%s' % (head, left, inner.group(2), right, tail)

    return re.sub(r"(?mi)^([ \t]*\." + STATEMENTS + r"\b[ \t]+)"
                  r"<([^<>]*)>(.*)$", one, text)


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
    text = re.sub(r"(?mi)^([ \t]*\." + STATEMENTS + r"\b"
                  r"[^;\n]*>)([^;\n]*?)[ \t]*(;[^\n]*)?$", one, text)
    # or a flag, which needs none
    return re.sub(r"(?mi)^([ \t]*\." + STATEMENTS + r"\b"
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


# Everything the program gives a name to, so that a name which is only a
# field of a structure can be told from one that is something in its own
# right.
DECLARED = set()
for text in SEEN:
    for line in text.split('\n'):
        code = code_of(line)
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
        name = m.group(1)
        found = FIELD.get(name.upper())
        if found is None or name.lower() in DECLARED:
            return name
        # A word the assembler keeps for itself is not a field, whatever a
        # structure calls its own: one of MODE's is called ENDIF.
        if name.upper() in ('ENDIF', 'ENDM', 'IFB', 'IFNB', 'IFE', 'IFDEF',
                            'IFNDEF', 'ELSE', 'IF', 'IF1', 'IF2', 'ENDP',
                            'ENDS', 'PROC', 'MACRO', 'STRUC', 'RECORD'):
            return name
        # SIZE, LENGTH and TYPE take the field's own name, and the rules for
        # them work the number out from its declaration: GRTAB says
        # TABSIZE EQU SIZE LANCHAR + SIZE LANID + SIZE LANNAME.
        if re.search(r"(?i)\b(?:size|length|type)[ \t]+$", m.string[:m.start()]):
            return name
        return '%s.%s' % (found[0], found[1])

    out = []
    for line in text.split('\n'):
        j = comment_at(line)
        code, comment = (line, '') if j < 0 else (line[:j], line[j:])
        if not re.match(r"[ \t]*\.", code):
            # the quotes are left alone: MODEPARS declares the parser's
            # keyword as DB "COLS=",0, and cols is a field of the structure
            # INVOKE describes an IOCTL 0CH call with
            code = outside_strings(r"(?<![\w.$])(" + N + r")", one, code)
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
if GROUPNAME:
    SEGMAP = {name: GROUPNAME + '_' for name in GROUPED}
    SEGMAP[GROUPNAME] = GROUPNAME + '_'
else:
    SEGMAP = {name: spelt + '_' for name, spelt in SEGNAME.items()}
SEGPAT = "|".join(sorted(set(SEGMAP) | set(SEGAT), key=len, reverse=True))


def segvalue(name):
    """What a segment's name stands for where it is read as a value: the
    fasm segment of the address space it is in, or the address itself where
    the segment is one of the places the program does not lay down."""
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
for text in source.values():
    here = None
    for line in text.split('\n'):
        code = code_of(line)
        m = re.match(r"(?i)^[ \t]*(" + N + r")\s+SEGMENT\b", code)
        if m:
            here = m.group(1).upper()
            here = space(here)
            continue
        if re.match(r"(?i)^[ \t]*" + N + r"\s+ENDS\b", code):
            here = None
            continue
        m = re.match(r"(?i)^[ \t]*(" + N + r")\s+(?:d[bwdq]|label)\b", code)
        if m and here:
            SEGOF.setdefault(m.group(1).lower(), here)
        # an instance of a structure is storage like any other
        m = re.match(r"(?i)^[ \t]*(" + N + r")[ \t]+(" + N + r")", code)
        if m and here and m.group(2).lower() in STRUC_CASE:
            SEGOF.setdefault(m.group(1).lower(), here)


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
    """
    def one(m):
        reg, field, tail = m.group(1), m.group(2), m.group(3)
        found = FIELD.get(field.upper())
        if found is None:
            # not a field of a structure but a number of its own, which
            # MASM added the same way: INC/CPMFCB.INC declares fcb_sfn as
            # the offset of the FCB's reserved bytes, where DOS keeps the
            # system file number.
            return '[%s+%s%s]' % (reg, field, tail.replace(' ', ''))
        owner, spelt = found
        return '[%s+%s.%s%s]' % (reg, owner, spelt, tail.replace(' ', ''))
    # SYS2 writes the register and the field inside the one pair of
    # brackets: [BX.dpb_first_FAT] says what [BX].dpb_first_FAT does.  This
    # goes first because what the rule below writes -- the structure's name
    # as the displacement, with the field named after it -- is of that shape
    # itself, and would be read a second time.
    code = re.sub(r"(?i)\[\s*((?:(?:cs|ds|es|ss):)?(?:" + BASEPAT + r")"
                  r"(?:\s*\+\s*(?:" + BASEPAT + r"))?"
                  r"(?:\s*[-+]\s*\w+(?!\.))?)\s*\.(" + N + r")"
                  r"((?:\s*[-+]\s*\w+)?)\s*\]", one, code)
    code = re.sub(r"(?i)\[\s*((?:(?:cs|ds|es|ss):)?(?:" + BASEPAT + r")"
                  r"(?:\s*\+\s*(?:" + BASEPAT + r"))?"
                  r"(?:\s*[-+]\s*\w+(?!\.))?)\s*\]\s*\.(" + N + r")"
                  r"((?:\s*[-+]\s*\w+)?)", one, code)
    # The index with no brackets at all, which MASM read as a reference
    # just the same: MODEVID passes video_info_DI.active_display to a macro
    # that moves it into AL.  An instruction's own operands are left to the
    # rules for storage below, which say the width where the name no longer
    # tells it; a macro's argument is not one of those, and the rules that
    # look for a mnemonic pass the line over.
    if NAMEDREG and not re.match(LED + MNEM + r")\s+)", code, re.I):
        code = re.sub(r"(?i)(?<![\w.$\]])((?:" + "|".join(
            sorted(map(re.escape, NAMEDREG), key=len, reverse=True))
            + r"))\s*\.(" + N + r")((?:\s*[-+]\s*\w+)?)", one, code)
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
        if base.lower() not in DATA and base.lower() not in WRITTEN:
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
        plain = re.search(r"(?i)\boffset[ \t]*$", head) is not None \
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

    return re.sub(r"(?i)\[([^\]]*)\]\s*\.(" + N + r")"
                  r"((?:\s*[-+]\s*\w+)?)", one, code)


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
    rest = re.sub(r"(?i)(?<![\w.])(?!(?:byte|word|dword|qword|ptr)\b)"
                  r"(" + N + r"(?:\s*[-+]\s*[\w@?$]+)*)\s*"
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

    return re.sub(r"(?i)\b(cs|ds|es|ss):\(\s*(byte|word|dword)\s+ptr\s+"
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
    code = re.sub(r"(?i)\boffset\s+(?:byte|word|dword)\s+ptr\s+",
                  'offset ', code)
    # the override before the size, which two of RECOVER's lines write:
    # LDS DX,CS:DWORD PTR [int_24_old_off]
    code = re.sub(r"(?i)\b(cs|ds|es|ss):\s*(byte|word|dword)\s+ptr\s*"
                  r"(\[[^\]]*\]|" + PLACE + r")",
                  lambda m: '%s [%s:%s]' % (
                      m.group(2).lower(), m.group(1).lower(),
                      m.group(3)[1:-1] if m.group(3).startswith('[')
                      else m.group(3)),
                  code)
    # the place may be a number rather than a name: RESCODE writes
    # MOV BYTE PTR CS:1,27H to put a RET into the prefix
    code = re.sub(r"\b(byte|word|dword)\s+ptr\s*((?:[A-Za-z]{2}:)?)\s*"
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
    # its interrupt handlers that way.
    if re.search(r"(?i)\blea\s*$", head):
        parts = rest.split(',')
        if len(parts) == 2 and re.match(r"^\s*" + N + r"(?:\." + N
                                        + r")?\s*$", parts[1]):
            return head + parts[0] + ',[' + parts[1].strip() + ']'
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
        base = re.match(r"^(" + N + r")", inner)
        return m.group(0) if not base else '[%s%s]' % (reach(base.group(1)),
                                                       inner)

    return re.sub(r"\[([^\[\]]*)\]", one, code)


def sized(code):
    m = re.match(LED + r"mov|cmp|add|sub|inc|dec|and|or|test|xor)\s+)(.*)$",
                 code, re.I)
    if not m or re.search(r"\b(byte|word|dword)\b", m.group(2), re.I):
        return code
    head, rest = m.group(1), m.group(2)
    parts = rest.split(',')
    ref = re.match(r"^\[(?:(?:cs|ds|es|ss):)?(" + N + r")\]$",
                   parts[0].strip(), re.I)
    if not ref:
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


def sizes(code):
    """A type name in an expression, as the number of bytes it takes up."""
    return re.sub(r"\b(BYTE|WORD|DWORD)\b(?!\s*\[)",
                  lambda m: {'BYTE': '1', 'WORD': '2', 'DWORD': '4'}[m.group(1)],
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
# to the block as well.
IF1BLOCK = re.compile(r"(?mi)^([ \t]*IF1\b.*\n"
                      r"(?:[ \t]*(?:%OUT\b|;).*\n|[ \t]*ELSE\b.*\n)+"
                      r"[ \t]*ENDIF\b.*\n)")


def commented(block):
    return ''.join(';' + l + '\n' for l in block.group(1).rstrip('\n').split('\n'))
MACRODEF = re.compile(r"(?i)^(" + N + r")[ \t]+MACRO\b[ \t]*(.*)$")
MACROEND = re.compile(r"(?i)^[ \t]*ENDM\b")
SEGMENT = re.compile(r"(?i)^[ \t]*(" + N + r")\s+SEGMENT\b")
GROUP = re.compile(r"(?i)^[ \t]*(" + N + r")\s+GROUP\b")
SEGEND = re.compile(r"(?i)^[ \t]*(" + N + r")\s+ENDS\b")
ENDALL = re.compile(r"(?i)^\s*END(?!\s+(?:if|virtual|struc|match|macro)\b)(\s+" + N + r")?\s*$")
LABELDEF = re.compile(r"(?i)^[ \t]*(" + N + r")(\s+)label(\s+)(byte|word|dword)\s*$")
CODELABEL = re.compile(r"(?i)^[ \t]*(" + N + r")\s+label\s+(?:near|far)\s*$")
PROC = re.compile(r"(?i)^[ \t]*(" + N + r")\s+proc(?:\s+(near|far))?\s*$")
ENDP = re.compile(r"(?i)^[ \t]*" + N + r"\s+endp\s*$")
ENDPROC = re.compile(r"(?i)^[ \t]*endproc\b")

done = {}
for stem in MODULES:
    text = source[stem]
    text = IF1BLOCK.sub(commented, text)
    text = HEADING.sub(heading, text)
    for was, now in MACROS.items():
        text = text.replace(was, now)
    if stem.endswith('.ASM'):
        text = PROCEDURE[0].sub(PROCEDURE[1], text)
    text = struct_arrays(text)
    text = far_pointers(text)
    text = far_jumps(text)
    text = at_far_jumps(text)
    text = split_dup(text)
    text = segment_values(text)
    text = grouped(text)
    text = offsets(text)
    text = blankness(text)
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
    text = records(text)
    text = record_fields(text)
    text = tabled(text)
    text = switched(text)
    for was, now in PATCHES.get(stem, ()):
        assert was in text, (stem, was)
        text = text.replace(was, now, 1)
    out, infar, noted, measured = [], False, False, False
    opened = []
    cover[0] = dict(START)
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
            inmacro[0] = True
            out.append('macro %s %s' % (m.group(1), m.group(2).strip()))
            out.append('{')
            continue
        if inmacro[0] and MACROEND.match(bare):
            inmacro[0] = False
            out.append('}' + (' ' + comment if comment else ''))
            continue

        # MASM's IFDEF asked whether a name had been given a value, which
        # fasm asks with DEFINED.  The eleven here all ask after fsexec, the
        # name that would have built RECOVER for an installable file system,
        # and nothing in the release gives it one.
        m = re.match(r"(?i)^([ \t]*)IFDEF\b[ \t]*(" + N + r")", bare)
        if m:
            out.append(pad('%sif defined %s' % (m.group(1), m.group(2)),
                           was_len, comment))
            continue
        m = re.match(r"(?i)^([ \t]*)IFNDEF\b[ \t]*(" + N + r")", bare)
        if m:
            out.append(pad('%sif ~ defined %s' % (m.group(1), m.group(2)),
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
                    opened.append((m.group(1).upper(), 'virtual'))
                    out.append('virtual at %s%s' % (at.group(1), comment))
                    continue
                if opened:
                    out.append('end if')
                opened.append((m.group(1).upper(), 'guardvirtual'))
                out.append('if SEGSEL = S_ABSOLUTE')
                out.append('virtual at %s%s' % (at.group(1), comment))
                continue
            if ONESEG:
                # one segment, and the modules are read once, so there is no
                # pass for the line to choose between
                opened.append((m.group(1).upper(), 'comment'))
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
            opened.append((m.group(1).upper(), 'guard'))
            out.append('if SEGSEL = S_%s%s' % (opened[-1][0], comment))
            continue
        if SEGEND.match(bare):
            how = opened.pop()[1] if opened else 'guard'
            if how == 'guardvirtual':
                out.append('end virtual' + (' ' + comment if comment else ''))
                out.append('end if')
                if opened and opened[-1][1] == 'guard':
                    out.append('if SEGSEL = S_%s' % opened[-1][0])
            elif how == 'virtual':
                out.append('end virtual' + (' ' + comment if comment else ''))
            elif how == 'comment':
                out.append(';' + line)
            else:
                out.append('end if' + (' ' + comment if comment else ''))
                if opened and opened[-1][1] == 'guard':
                    out.append('if SEGSEL = S_%s' % opened[-1][0])
            continue
        if DIRECTIVE.match(code) or ENDALL.match(bare):
            out.append(';' + line)
            continue
        m = PROC.match(bare)
        if m:
            infar = (m.group(2) or '').lower() == 'far'
            out.append(pad('%s:' % m.group(1), was_len, comment))
            continue
        if ENDP.match(bare):
            infar = False
            out.append(';' + line)
            continue
        # INC/DOSMAC.INC's EndProc closes a procedure as well, and RECOVER
        # closes twenty-four of its own that way: int_24, the only one
        # declared FAR, is one of them, so the RETs after it are near again.
        if ENDPROC.match(bare):
            infar = False
        m = INSTANCE.match(bare)
        if m:
            out.append(pad('%s%s %s' % (m.group(1), m.group(2),
                                        sizes(m.group(3))),
                           was_len, comment))
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
        # MASM assembled a far procedure's RET as a far return.
        if infar and re.match(r"(?i)^\s*ret\s*$", bare):
            out.append(pad(code.rstrip().replace('RET', 'RETF')
                           .replace('ret', 'retf'), was_len, comment))
            continue

        code = re.sub(r"(?i)^(" + N + r"?\s*)\bdb\s+\?\s*$", r"\1rb      1", code)
        code = re.sub(r"(?i)^(" + N + r"?\s*)\bdw\s+\?\s*$", r"\1rw      1", code)
        code = re.sub(r"(?i)^(" + N + r"?\s*)\bdd\s+\?\s*$", r"\1rd      1", code)
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
        code = sized(code)
        code = pushed(code)

        if held:
            m2 = re.match(r"(?i)^\s*cmp\s+(.*?)\s*,\s*(.*?)\s*$", code)
            left, right = (m2.group(1), m2.group(2)) if m2 \
                else (held.group(3), held.group(5))
            # a left side of more than one word goes in brackets of its own,
            # because fasm's MATCH splits the condition into its tokens
            if not left.startswith('<') and re.search(r"[\s\[\]:]", left):
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
DECL = re.compile(r"(?i)^\s*(?:(" + N + r"):|(" + N + r")\s+(?:(?:db|dw|dd|"
                  r"rb|rw|rd|equ)\b|=)|label\s+(" + N + r")\b|macro\s+(" + N
                  + r")\b|Define_Msg\s+(" + N + r")\b|Procedure\s+("
                  + N + r")\b|STRUC\s+(" + N + r")\b)")
# The program's own modules name a thing first; the shared headers under
# src/INC come after, so a name they both have takes the module's spelling.
# MASM did not mind the case and fasm does, so a reference has to be written
# the way its declaration was -- INC/SYSCALL.INC calls the function Open and
# EXE2BIN asks for open.
for lines in (list(done.values())
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
