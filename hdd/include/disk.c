
void ata_wait_busy() {
    while (inb(0x1F7) & 0x80);
}

void ata_wait_drq() {
    while (!(inb(0x1F7) & 0x08));
}

void ata_read_sector(u32 lba, void* buffer) {
    u16* buf = (u16*)buffer;

    ata_wait_busy();

    outb(0x1F2, 1); // sector count

    outb(0x1F3, (u8)lba);
    outb(0x1F4, (u8)(lba >> 8));
    outb(0x1F5, (u8)(lba >> 16));

    outb(0x1F6, 0xE0 | ((lba >> 24) & 0x0F));

    outb(0x1F7, 0x20); // READ SECTORS

    ata_wait_busy();
    ata_wait_drq();

    for (int i = 0; i < 256; i++)
        buf[i] = inw(0x1F0);
}

DirectoryEntry* get_directory_entry(char* filename) {
    static unsigned char buf[512];

    for (int x = 0; x < 16; x++) {
        ata_read_sector(x + 44, buf);
        if (buf[0] == 0) return 0;
        for (int i = 0; i < 16; i++) {
            DirectoryEntry* entry = (DirectoryEntry*)(buf + i * sizeof(DirectoryEntry));

            if (strcmplen(entry->filename, filename, 11) == 0) {
                return entry;
            }
        }
    }

    return 0;
}

void list_directory(char* string) {
    unsigned char buf[512];
    video_offset-=80; //fix alignment issues
    for (int x = 0; x < 16; x++) {
        ata_read_sector(x + 44, buf);
        
        for (int i = 0; i < 16; i++) {
            if (buf[32*i] == 0 || buf[32*i] == 0xe5) return;
            if (buf[32*i + 11] & 0b10) continue;
            printc('\n', 15);
            for (int j = 0; j < 11; j++) {
                if (buf[32*i+j] == ' ' && j < 7) {j = 7; printc('.', 15); continue;}
                if (buf[32*i+j] == ' ' && j > 7) break;
                printc(buf[32*i+j], 15);
            }
            
        }
        
    }
}

void loadFile(DirectoryEntry* file) {
    static unsigned short fatTable[256*20];

    for (int x = 0; x < 20; x++) {
        ata_read_sector(4 + x, fatTable + (x * 256));
    }
    unsigned short* fat = (unsigned short*)fatTable;
    unsigned short cluster = file->startCluster;

    int offset = 0;

    while (cluster < 0xFFF8) { // FAT16 end-of-chain

        int baseSector = 76 + (cluster - 2) * 4;

        for (int j = 0; j < 4; j++) {
            ata_read_sector(baseSector + j,
                fileData + offset + (j * 512));
        }

        offset += 2048;

        cluster = fat[cluster]; // FOLLOW CHAIN
    }
}

char* convert_name_to_entry(char* name) {
    static char good_filename[11];

    // fill with spaces first (important for FAT)
    for (int i = 0; i < 11; i++) {
        good_filename[i] = ' ';
    }

    int i = 0;
    int j = 0;

    // copy filename (before dot)
    while (name[i] && name[i] != '.' && j < 8) {
        good_filename[j++] = name[i++];
    }

    // skip dot
    if (name[i] == '.') i++;

    // copy extension (max 3 chars)
    j = 8;
    int k = 0;
    while (name[i] && k < 3) {
        good_filename[j++] = name[i++];
        k++;
    }

    return good_filename;
}