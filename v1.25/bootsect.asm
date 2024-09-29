use16

FLOPPY_SECTORS_PER_HEAD equ 18
FLOPPY_HEADS_PER_CYLINDER equ 2

FAT12_BYTES_PER_SECTOR equ 512
FAT12_RESERVED_SECTORS equ 1
FAT12_NUMBER_OF_FATS equ 2
FAT12_SECTORS_PER_FAT equ 9
FAT12_FAT_TABLE_SIZE equ FAT12_SECTORS_PER_FAT * FAT12_BYTES_PER_SECTOR
FAT12_FAT_TABLE_SECTOR equ FAT12_RESERVED_SECTORS
FAT12_DIRECTORY_ENTRIES equ 224
FAT12_DIRECTORY_TABLE_SIZE equ FAT12_DIRECTORY_ENTRIES*32
FAT12_DIRECTORY_TABLE_SECTOR equ FAT12_FAT_TABLE_SECTOR + FAT12_NUMBER_OF_FATS*FAT12_SECTORS_PER_FAT
FAT12_DIRECTORY_TABLE_SECTOR_COUNT = FAT12_DIRECTORY_TABLE_SIZE / FAT12_BYTES_PER_SECTOR
FAT12_DATA_SECTOR equ FAT12_DIRECTORY_TABLE_SECTOR + FAT12_DIRECTORY_TABLE_SECTOR_COUNT

; IBM memory map
; 0000-03FF Real Mode Interrupt Vector Table (IVT)
; 0400-04FF BIOS Data Area (BDA)
; 0600-09FF IO.SYS (IOSEG)
; 0A00-12FF MSDOS.SYS (DOSSEG)
; 7C00-7DFF Boot sector

IOSEG           equ 0x0060  ; must match BIOSSEG in IO.ASM
IOMAXLEN        equ 2048/16 ; must match BIOSLEN/16 in IO.ASM
DOSSEG          equ IOSEG+IOMAXLEN
MSDOS_SEGMENT_DIFF equ 0x0200
FAT_TABLE_OFFSET equ (DOSSEG + MSDOS_SEGMENT_DIFF)*16
FAT_DIRECTORY_TABLE_OFFSET equ FAT_TABLE_OFFSET + FAT12_FAT_TABLE_SIZE


org 0x7C00

jmp boot

; BIOS Parameter Block (BPB)
times 3-($-$$) db 0
oem_name                db 'DOS 1.25'
bytes_per_sector        dw FAT12_BYTES_PER_SECTOR
sectors_per_cluster     db 1
reserved_sectors        dw FAT12_RESERVED_SECTORS
number_of_fats          db FAT12_NUMBER_OF_FATS
root_directory_entries  dw FAT12_DIRECTORY_ENTRIES
total_sectors           dw 80 * FLOPPY_HEADS_PER_CYLINDER * FLOPPY_SECTORS_PER_HEAD
media_descriptor        db 0xF0
sectors_per_fat         dw FAT12_SECTORS_PER_FAT

boot:
        cld
        cli
        xor bp, bp
        mov ss, bp
        mov sp, IOSEG*16
        sti
        mov [drive], dl

read_fat_table:
        xor ax, ax
        mov es, ax
        mov bx, FAT_TABLE_OFFSET
        mov al, FAT12_SECTORS_PER_FAT
        mov dx, FAT12_FAT_TABLE_SECTOR
        call read_sector
read_directory_table:
        xor ax, ax
        mov es, ax
        mov bx, FAT_DIRECTORY_TABLE_OFFSET
        mov al, FAT12_DIRECTORY_TABLE_SECTOR_COUNT
        mov dx, FAT12_DIRECTORY_TABLE_SECTOR
        call read_sector

find_io_sys:
        xor ax, ax
        mov es, ax
        mov di, io_sys_filename
        call find_file_entry
read_io_sys:
        mov dx, FAT12_DATA_SECTOR-2
        add dx, [bx+26]
        mov ax, IOSEG
        mov es, ax
        mov ax, [bx+28]
        mov cl, 9
        shr ax, cl
        inc ax
        xor bx, bx
        call read_sector

find_msdos_sys:
        xor ax, ax
        mov es, ax
        mov di, msdos_sys_filename
        call find_file_entry
read_ms_dos:
        mov dx, FAT12_DATA_SECTOR-2
        add dx, [bx+26]
        mov ax, DOSSEG
        mov es, ax
        mov ax, [bx+28]
        mov cl, 9
        shr ax, cl
        inc ax
        xor bx, bx
        call read_sector

        jmp IOSEG:0

halt:
        cli
        hlt

; Floppies have 80 cylinders, 2 heads, 18 sectors
; assume bytes per sector = 512
; assume sectors per cluster = 1
; assume total number of sectors = 2880
; assume media = 0xF0 (1.4 MB floppy)
; assume sectors per track = 18
; heads = 2 (double sided floppy)
; assume hidden sectors = 0
; FAT start = hidden + reserved

; Read al number of sectors from sector number dx to memory location es:bx
read_sector:
        push ax
        mov ax, dx
        mov ch, FLOPPY_SECTORS_PER_HEAD
        div ch
        mov cl, ah
        inc cl ; sector
        xor ah, ah
        mov ch, FLOPPY_HEADS_PER_CYLINDER
        div ch
        mov ch, al ; cylinder
        mov dh, ah ; head
        pop ax
        mov dl, [drive]
        mov ah, 2 ; read sectors from drive
        int 13h
        jc read_error
        ret

find_file_entry:
        xor ax, ax
        mov ds, ax
        mov dx, di
        mov es, ax
        mov bx, FAT_DIRECTORY_TABLE_OFFSET
        mov si, bx
find_next_file_entry:
        cmp byte [si], 0
        jz file_entry_not_found
        mov di, dx
        mov cx, 8+3
        rep cmpsb
        je file_entry_found
        add bx, 32
        mov si, bx
        jmp find_next_file_entry
file_entry_not_found:
        mov si, not_found
        jmp print_error_message
file_entry_found:
        ret

read_error:
        mov al, ah
        call print_number
        xor ax, ax
        mov ds, ax
        mov si, read_error_message

print_error_message:
        lodsb
        cmp al,0
        je halt
        mov ah, 0x0E
        mov bh, 0x00
        int 10h
        jmp print_error_message

print_number:
        push ax
        shr al, 4
        call print_digit
        pop ax
        and al, 15
        call print_digit
        ret

print_digit:
        cmp al, 9
        ja tens
        add al, '0'
        jmp ones
        tens:
        add al, 'A'-10
        ones:
        mov ah, 0x0E
        mov bh, 0x00
        int 10h
        ret

not_found           db "File entry not found!", 0
read_error_message  db "Read error!", 0
io_sys_filename     db "IO      SYS"
msdos_sys_filename  db "MSDOS   SYS"

drive db ?

times 510-($-$$) db 0
dw 0xAA55
