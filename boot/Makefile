all:
	nasm -fbin boot.asm -o boot
	nasm -fbin second.asm -o second
	cat second >> boot
	qemu-system-x86_64 -hda boot
