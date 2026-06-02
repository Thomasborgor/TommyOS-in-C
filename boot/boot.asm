[org 0x7c00]
bits 16

mov ax, 0x10
mov es, ax
mov ah, 0x02
mov al, 1
mov cx, 2
mov dh, 0

mov bx, 0x7e00

int 0x13
bits 16


cli
mov ax, 0
mov ds, ax
mov es, ax
mov ss, ax
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



mov [0xb8000], 'A'
jmp 0x7f00

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


db 'this is a sector test', 0
times 510-($-$$) db 0
dw 0xaa55