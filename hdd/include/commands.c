void help(char* string) {
    printstr("Availible commands:\n", 15);
    for (int i = 0; i < NUM_COMMANDS; i++) {
        printstr(commands[i], 15);
        printc('\n', 15);
    }
    vga_set_cursor(video_offset);
}

void about(char* string) {
    printstr("TommyOSx86 v0.1", 15);
    vga_set_cursor(video_offset);
}

void echo(char* string) {
    printstr(string+5, 15);
    vga_set_cursor(video_offset);
}

void get_file_info(char* string) {
    DirectoryEntry* file;
    file = get_directory_entry(convert_name_to_entry(string+5));
    if (file == 0) {
        printstr("File not found.\n", 15);
        return;
    }
    listfile(file, 15);
}

void clear(char* string) {
    for (int i = 0; i < 2000; i++) {
        video[i] = 0x0f00;
    }
    video_offset = 0;
    vga_set_cursor(0);
}