BITS 16
org 0x7c00
jmp short bootloader_start
nop

; ---------------- BPB ----------------

OEMLabel            db "TOMBOOT "
BytesPerSector      dw 512
SectorsPerCluster   db 4
ReservedForBoot     dw 4
NumberOfFats        db 2
RootDirEntries      dw 512
LogicalSectors      dw 20000
MediumByte          db 0F8h
SectorsPerFat       dw 20
SectorsPerTrack     dw 32
Sides               dw 2
HiddenSectors       dd 0
LargeSectors       dd 0
DriveNo            db 0x80
Signature          db 41
VolumeID           dd 49346075h
VolumeLabel        db "TOMMYOS    "
FileSystem         db "FAT16   "

; ---------------- CODE ----------------

bootloader_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [bootdev], dl

	mov ah, 8			; Get drive parameters
	int 13h

	and cx, 3Fh			; Maximum sector number
	mov [SectorsPerTrack], cx	; Sector numbers start at 1
	movzx dx, dh			; Maximum head number
	add dx, 1			; Head numbers start at 0 - add 1 for total
	mov [Sides], dx

    ;Load 16 directory entries at a time
    ;See if any match our KERNEL  BIN
    ;If so, then start loading that file
    ;into 0x1000:0x0000.
    ;Once we finish, we will switch to 32 bit mode
    ;then finally jump to 0x10000.

    ;for simplicity, I will assume that 
    ;the kernel is the first entry in the root directory.
    ;If you change this, that's on you.
    ;fix it yourself.

    ;important math:
    ;sector calculation: ((cluster-2) * secPerCluster) + 76
    ;First cluster offset is 0x1C in directory
    ;root dir is sector 44 + 1 so 45
    
    
    mov ax, 0x0000
    mov es, ax
    mov dl, [bootdev] ;load the root dir
    mov ax, 44
    call l2hts
    mov ax, 0x0201
    mov bx, buffer
    int 0x13
    jc bad

    mov ax, word [buffer+0x1A] ;get first cluster
    mov [cluster], ax

    mov ax, 4 ;load the fat table thingy
    call l2hts
    mov ax, 0x0214
    mov bx, buffer
    int 13h
    jc bad

load_loop:
    mov ax, [cluster]
    sub ax, 2
    xor cx, cx
    mov cl, [SectorsPerCluster]
    
    mul cx
    add ax, 76
    
    call l2hts
    mov bx, 0
    mov ax, [pointer]
    mov es, ax
    
    
    mov ax, 0x0204
    int 13h
    jc bad
    mov ax, 0x0000
    mov es, ax
    mov bx, [cluster]
    shl bx, 1
    
    mov ax, [buffer+bx]
    
    mov [cluster], ax

    cmp ax, 0xfff8
    jae end
    add [pointer], word 0x80
    

    jmp load_loop

bad:
mov ax, 0x0e01
int 0x10
jmp $

l2hts:			; Calculate head, track and sector settings for int 13h
			; IN: logical sector in AX, OUT: correct registers for int 13h
	push bx
	push ax

	mov bx, ax			; Save logical sector

	mov dx, 0			; First the sector
	div word [SectorsPerTrack]
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	mov dx, 0			; Now calculate the head
	div word [SectorsPerTrack]
	mov dx, 0
	div word [Sides]
	mov dh, dl			; Head/side
	mov ch, al			; Track

	pop ax
	pop bx

	mov dl, byte [bootdev]		; Set correct device

	ret
    

end:

cli

mov sp, 0x900
seta20:
in al, 0x64
test al, 0x2
jnz seta20

mov al, 0xd1
out 0x64, al
seta201:
in al, 0x64
test al, 0x2
jnz seta201

mov al, 0xdf
out 0x60, al

seta202:
in al, 0x64
test al, 0x2
jnz seta202
lgdt [gdt_descriptor]
mov eax, cr0
or eax, 0x1
mov cr0, eax

jmp CODE_SEG:pm_init

bits 32
pm_init:

mov ax, DATA_SEG
mov ds, ax
mov es, ax
mov ss, ax
mov fs, ax
mov gs, ax

mov ebp, 0x9000
mov esp, ebp
mov dl, byte [bootdev]
jmp CODE_SEG:0x10000


%macro GDT_SEG 3
    ;; limit [0-15]   base [16-31]
    dw ((%2) & 0xffff), ((%1) & 0xffff)
    ;; base [32-39]            access byte [40-47]
    db (((%1) >> 16) & 0xff), ((0x90 | (%3)) & 0xff)
    ;; flags[52-55] limit [48-51]      base [56-63]
    db (0xC0 | (((%2) >> 16) & 0xf)), (((%1) >> 24) & 0xff)
%endmacro

;; Segment access-byte flags
%define SEG_DATA       0b00000000 ; [3]      the descriptor defines a data segment
%define SEG_EXECUTABLE 0b00001000 ; [3]      the descriptor defines an executable code segment
%define SEG_XREADABLE  0b00000010 ; [1]      for code segments only :: read access is allowed
%define SEG_DWRITEABLE 0b00000010 ; [1]      for data segments only :: write access is allowed
%define SEG_ACCESSED   0b00000001 ; [0]      the cpu will set the accessed bit when the segment is accessed unless set to 1 in advance


;; Setting a minial Bootsector GDT
gdt:
    ;; The GDT starts with a null segment descriptor :: 8 null bytes
    null_descriptor:
        dd 0x0 ; null double word
        dd 0x0 ; null double word

    ;; Code segment descriptor
    code_descriptor:
        GDT_SEG 0, 0xfffff, (SEG_EXECUTABLE | SEG_XREADABLE)

    ;; Data segment descriptor
    data_descriptor:
        GDT_SEG 0, 0xfffff, (SEG_DATA | SEG_DWRITEABLE)


;; GDT descriptor :: GDT size [16 bits], GDT address [32 bits]
gdt_descriptor:
    dw $ - gdt - 1 ; size of the GDT, always less 1 of the true size
    dd gdt                     ; GDT start address


; Define some handy constants for the GDT segment descriptor offsets, which
; are what segment registers must contain when in protected mode. For example,
; when we set DS=0x10 in PM, the CPU knows that we mean it to use the
; segment described at offset 0x10 (16 bytes) in our GDT, which in our
; case is the DATA segment (0x0 -> NULL :: 0x08 -> CODE :: 0x10 -> DATA)
CODE_SEG equ code_descriptor - gdt
DATA_SEG equ data_descriptor - gdt


; ---------------- calculate FAT + root layout ----------------

bootdev db 0
cluster dw 0
pointer dw 0x1000

times 510-($-$$) db 'X'
dw 0xAA55
buffer:
