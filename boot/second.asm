[org 0x7f00]
bits 32

start:
    mov esi, string
    call print

    mov edi, sector_buffer
    mov eax, 0          ; LBA = 0
    mov cl,2
    call read_sector

    mov esi, sector_buffer
    call print_sector

    jmp $


; -----------------------------------
; PRINT STRING
; -----------------------------------
print:
    mov ebx, [cursor_offset]

.l:
    mov al, [esi]
    inc esi

    test al, al
    jz .done

    mov [0xb8000 + ebx], al
    mov byte [0xb8000 + ebx + 1], 0x07

    add ebx, 2
    jmp .l

.done:
    mov [cursor_offset], ebx
    ret


; -----------------------------------
; PRINT SECTOR AS ASCII
; -----------------------------------
print_sector:
    mov ebx, [cursor_offset]

    mov ecx, 512*2
    mov edi, esi
    .l:
    mov al, [edi]
    mov [0xb8000 + ebx], al
    inc edi
    add ebx, 2 
    loop .l

    mov [cursor_offset], ebx
    ret


; -----------------------------------
; ATA PIO READ SECTOR
; EAX=LBA
; CL=num sectors
; EDI=destination
; -----------------------------------
read_sector:
               pushfd
               and eax, 0x0FFFFFFF
               push eax
               push ebx
               push ecx
               push edx
               push edi

               mov ebx, eax         ; Save LBA in RBX
               
               mov edx, 0x01F6      ; Port to send drive and bit 24 - 27 of LBA
               shr eax, 24          ; Get bit 24 - 27 in al
               or al, 11100000b     ; Set bit 6 in al for LBA mode
               out dx, al

               mov edx, 0x01F2      ; Port to send number of sectors
               mov al, cl           ; Get number of sectors from CL
               out dx, al
               
               mov edx, 0x1F3       ; Port to send bit 0 - 7 of LBA
               mov eax, ebx         ; Get LBA from EBX
               out dx, al

               mov edx, 0x1F4       ; Port to send bit 8 - 15 of LBA
               mov eax, ebx         ; Get LBA from EBX
               shr eax, 8           ; Get bit 8 - 15 in AL
               out dx, al


               mov edx, 0x1F5       ; Port to send bit 16 - 23 of LBA
               mov eax, ebx         ; Get LBA from EBX
               shr eax, 16          ; Get bit 16 - 23 in AL
               out dx, al

               mov edx, 0x1F7       ; Command port
               mov al, 0x20         ; Read with retry.
               out dx, al

.still_going:  in al, dx
               test al, 8           ; the sector buffer requires servicing.
               jz .still_going      ; until the sector buffer is ready.

               mov eax, 256         ; to read 256 words = 1 sector
               xor bx, bx
               mov bl, cl           ; read CL sectors
               mul bx
               mov ecx, eax         ; RCX is counter for INSW
               mov edx, 0x1F0       ; Data port, in and out
               rep insw             ; in to [RDI]

               pop edi
               pop edx
               pop ecx
               pop ebx
               pop eax
               popfd
               ret


; -----------------------------------
; DATA
; -----------------------------------
string db 'Sector 0 dump:',0

cursor_offset dd 160
sector_buffer:
times 511-($-$$) db 0
db '!'