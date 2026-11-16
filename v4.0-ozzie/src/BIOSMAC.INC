; BIOSMAC.INC - the MASM directives these sources use that FASM has not.
;
; This file is this repository's and not the release's: bin/DISK2/BIOS has no
; macro file, because the directives below are MASM's own.
;
; ASSUME tells MASM which segment or group a register holds, so that it knows
; whether a reference needs an override and which one.  FASM wants the
; override written on the reference instead, which is what the conversion
; does, so there is nothing left for ASSUME to say -- but the lines are kept,
; a macro that does nothing, because they are how each source says what it
; believed and because checkassume.py reads them to check that belief against
; the overrides.

macro ASSUME [name]
{
}
