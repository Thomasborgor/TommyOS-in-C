static inline void outb(u16 port, u8 value) {
    asm volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline u8 inb(u16 port) {
    u8 ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline u16 inw(u16 port) {
    u16 ret;
    asm volatile ("inw %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}


char keymapLower[] = {
    9, 8,'1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
    '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n', 11,
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', 4, 5, 6,
    'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 2, 1, 3, ' '
};
char keymapUpper[] = {
    9, 8,'!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '\b',
    '\t', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n', 11,
    'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', 4, 5, 6,
    'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 2, 1, 3, ' '
};


byte shift = 0;

char getkey() {
    while (1) {
        if (!(inb(0x64) & 1)) continue;

        unsigned char scancode = inb(0x60);

        // key release
        if (scancode & 0x80) {
            scancode &= 0x7F;

            if (scancode == 0x2A || scancode == 0x36) {
                shift = 0;
            }

            continue;
        }

        // key press

        if (scancode == 0x2A || scancode == 0x36) {
            shift = 1;
            continue;
        }

        if (keymapLower[scancode] == 0)
            continue;

        return shift ? keymapUpper[scancode]
                     : keymapLower[scancode];
    }
}