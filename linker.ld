ENTRY(start)

SECTIONS
{
    . = 0x10000;

    .multiboot_header ALIGN(8) : { *(.multiboot_header) }
    .text      ALIGN(4) : { *(.text*) }
    .rodata    ALIGN(4) : { *(.rodata*) }
    .data      ALIGN(4) : { *(.data*) }
    .bss       ALIGN(4) : { *(.bss*) *(COMMON) }
}
