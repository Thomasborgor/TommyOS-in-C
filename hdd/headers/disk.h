void ata_read_sector(u32 lba, void* buffer);
void ata_wait_drq();
void ata_wait_busy();
DirectoryEntry* get_directory_entry(char* filename);
void list_directory(char* string);
char* convert_name_to_entry(char* name);
void loadFile(DirectoryEntry* file);
byte bootdev = 0;
unsigned char* fileData = (unsigned char*)0x20000; 
