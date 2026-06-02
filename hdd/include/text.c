void printc(char c, unsigned char color) {
    if (c == '\n') {
        video_offset = (video_offset/80 + 1) * 80;
        vga_set_cursor(video_offset);
        return;
    }
    if (c == '\b') {
        video_offset--;
        video[video_offset] = 15 * 16 * 16 + ' ';
        vga_set_cursor(video_offset);
        return;
    }
    video[video_offset] = color * 16 * 16 + (unsigned char)c;
    video_offset++;
}

void printstr(char* string, byte color) {
    int offset = 0;
    while (1) {
        if (string[offset] == 0) return;
        printc(string[offset], color);
        offset++;
    }
    
}

void printint(unsigned short n) {
    if (n >= 10) {
        printint(n/10);
    }
    printc('0' + n % 10, 0x0f);
}

int strcmplen(char* a, char* b, int len) {
    for (int i = 0; i < len; i++) {
        if (a[i] != b[i]) {
            return (unsigned char)a[i] - (unsigned char)b[i];
        }

        if (a[i] == '\0' && b[i] == '\0') {
            return 0;
        }
    }
    return 0;
}

int strcmp(char* a, char* b) {
    int idx = 0;
    int accumulator = 0;
    while (1) {
        if ((a[idx] == '\0' && b[idx] != '\0') || (b[idx] == '\0' && a[idx] != '\0')) return -1;
        if ((a[idx] == '\0' && b[idx] == '\0')) return accumulator;
        accumulator += a[idx];
        accumulator -= b[idx];
        idx += 1;
    }
}

void strcpy(char* a, char* b) {
    int idx = 0;
    while (1) {
        if (a[idx] == '\0') break;
        b[idx] = a[idx];
        idx++;
    }
}

void listfile(DirectoryEntry* entry, unsigned char color) {
    for (int i = 0; i < 11; i++) {
        if (entry->filename[i] == ' ' && i>7) break;
        if (entry->filename[i] == ' ') { printc('.', 0x0f); i = 7; continue;}
        printc(entry->filename[i], 0x0f);
    }
    printstr("\n", 0);
    printint(entry->size);
    printstr(" bytes\nFlags:", 15);
    if (entry->attribute & 1) {
        printstr("\nRead-only",15);
    }
    if (entry->attribute & 0b10) {
        printstr("\nHidden",15);
    }
    if (entry->attribute & 0b100) {
        printstr("\nSystem",15);
    }
    if (entry->attribute & 0b1000) {
        printstr("\nVolume label",15);
    }
}
void vga_set_cursor(unsigned short pos) {
    outb(0x3D4, 0x0F);              // cursor low byte index
    outb(0x3D5, (unsigned char)(pos & 0xFF));

    outb(0x3D4, 0x0E);              // cursor high byte index
    outb(0x3D5, (unsigned char)((pos >> 8) & 0xFF));
}

void scroll_screen(unsigned int n) {
    int cursor_past = video_offset % 80;
    unsigned int lines_past = ((n-2000) / 80 + 1) * 80;
    for (int i = 0; i < 2000; i++) {
        video[i] = video[i+lines_past];
    }
    for (int i = 0; i < lines_past; i++) {
        video[2000+i] = 0x0f00;
    }

    video_offset = 80*24 + cursor_past;
    
}

unsigned short vga_get_cursor(void) {
    unsigned short pos;

    outb(0x3D4, 0x0F);      // select low byte
    pos = inb(0x3D5);

    outb(0x3D4, 0x0E);      // select high byte
    pos |= ((unsigned short)inb(0x3D5)) << 8;

    return pos;
}