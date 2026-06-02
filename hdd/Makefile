all:
	nasm -fbin boot.asm -o boot.bin
	dd if=/dev/zero of=disk.img bs=1M count=10
	rm disk.img
	mkdosfs -C disk.img 10000 -F16 -M0xF8
	dd if=boot.bin of=disk.img bs=512 count=1 conv=notrunc
	gcc -m32 -ffreestanding -nostdlib -fno-pie -fno-stack-protector -c kernel.c -o kernel.o
	ld -m elf_i386 -T kernel.ld -o kernel.elf kernel.o
	objcopy -O binary kernel.elf kernel.bin
	gcc -m32 -ffreestanding -nostdlib -fno-pie -fno-stack-protector -c test.c -o test.o
	ld -m elf_i386 -T test.ld -o test.elf test.o
	objcopy -O binary test.elf test.bin
	mcopy -i disk.img kernel.bin ::KERNEL.BIN
	mcopy -i disk.img test.bin ::TEST.BIN
	mcopy -i disk.img kernel.c ::KERNEL.C
	mattrib -i disk.img +r +h +s ::KERNEL.BIN