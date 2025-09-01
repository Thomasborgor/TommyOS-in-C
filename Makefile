KERNEL = kernel.elf
ISO_DIR = iso
ISO = myos.iso

NASM = nasm
CC   = gcc
LD   = ld

CFLAGS = -m32 -ffreestanding -fno-stack-protector -fno-pic -Wall -Wextra -O2
LDFLAGS = -m elf_i386
OVMF = ../../Downloads/OVMF_X64.fd

all: $(KERNEL) iso

$(KERNEL): boot/boot.o kernel.o
	$(LD) $(LDFLAGS) -T linker.ld -o $@ boot/boot.o kernel.o

boot/boot.o: boot/boot.asm
	$(NASM) -f elf32 boot/boot.asm -o boot/boot.o

kernel.o: kernel.c
	$(CC) $(CFLAGS) -c kernel.c -o kernel.o

iso: $(KERNEL) grub.cfg
	rm -rf $(ISO_DIR)
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL) $(ISO_DIR)/boot/kernel.elf
	cp grub.cfg $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $(ISO) $(ISO_DIR)
	
run: $(ISO)
	qemu-system-x86_64 -cdrom $(ISO) -m 512M -bios $(OVMF)

clean:
	rm -f $(KERNEL) boot/boot.o kernel.o $(ISO)
	rm -rf $(ISO_DIR)
	
commit:
	git add .
	git commit -m "first commit"
	git branch -M main
	git push -u origin main