; boot.S - Minimal Multiboot2 header in NASM
; minimal_multiboot2_header.asm  (NASM, elf32)
BITS 32

%define MULTIBOOT2_HEADER_MAGIC 0xE85250D6
%define MULTIBOOT_ARCHITECTURE_I386 0

section .multiboot_header align=8
multiboot_header:
    dd MULTIBOOT2_HEADER_MAGIC              ; magic
    dd MULTIBOOT_ARCHITECTURE_I386          ; architecture = i386
    dd multiboot_header_end - multiboot_header ; header_length
    dd -(MULTIBOOT2_HEADER_MAGIC + MULTIBOOT_ARCHITECTURE_I386 + (multiboot_header_end - multiboot_header))

    ; -------------------------
    ; Framebuffer request tag
	; framebuffer request (safe, widely supported)
dd 5       ; type = framebuffer
dd 24      ; size
dd 800     ; width
dd 600     ; height
dd 32      ; depth
dd 0       ; padding


    ; -------------------------
    ; End tag (must be last)
    ; -------------------------
    dd 0          ; type = end
    dd 8          ; size = 8

multiboot_header_end:


section .text
global start
extern kernelMain

start:
    cli
	mov esp, stack + 8192
	push ebx
    call kernelMain
    hlt
    jmp $
section .bss
stack: resb 8192