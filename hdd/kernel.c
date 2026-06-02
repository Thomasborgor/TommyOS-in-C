
#define NUM_COMMANDS 6
#include "headers/types.h"
#include "headers/text.h"
#include "headers/ll.h"
#include "headers/disk.h"
#include "headers/commands.h"
char cmdBuffer[128];
int cmdBufferIndex = 0;
char *commands[];
int commandLengths[];
void (*handlers[])(char*);


void _start() {
    
    asm volatile (
        "mov %%dl, %0"
        : "=r"(bootdev)
    );
    for (int x = 0; x < 80*25; x++) {
        video[x] = 0x0f00;
    }
    printstr("TommyOSx86 v0.1", 0x0F);

    vga_set_cursor(video_offset);
    char key = '\0';
    




    while(1) {
        printstr("\n> ", 15);
        vga_set_cursor(video_offset);
        if (video_offset >= 80*25) {
            scroll_screen(video_offset);
            vga_set_cursor(video_offset);
        }
        
        
        while(1) {
            if (cmdBufferIndex >=127 ) continue;
            key = getkey();
            if (key == '\b') {
                if (cmdBufferIndex == 0) {
                    continue;
                }
                printc('\b', 15);
                vga_set_cursor(video_offset);
                cmdBufferIndex--;
                continue;
            }
            if (key == '\n') {
                break;
            }
            
            printc(key, 15);
            vga_set_cursor(video_offset);
            if (key != '\b' && key != '\n' && key >= 32) cmdBuffer[cmdBufferIndex] = key;
            cmdBufferIndex++;
        }
        printc('\n', 15);
        cmdBuffer[cmdBufferIndex] = '\0';
        for (int i = 0; i < NUM_COMMANDS; i++) {
            if (strcmplen(cmdBuffer, commands[i], commandLengths[i]) == 0) {
                handlers[i](cmdBuffer);
                goto past;

            }
        }  
        
        DirectoryEntry* possibleFile;
        
        possibleFile = get_directory_entry(convert_name_to_entry(cmdBuffer));
        if (possibleFile == 0) {printstr("Invalid command.", 15);}
        else {
            if (possibleFile->attribute & 0x1) {
                printstr("Read-only file.", 15);
                goto past;
            }
            loadFile(possibleFile);
            void (*func)(char*) = (void (*)(char*))fileData;
            func(cmdBuffer);

        }
        past:
        cmdBufferIndex = 0;

    }
}

char *commands[] = {
    "help",
    "dir",
    "echo ",
    "about",
    "file ",
    "clear"
};

int commandLengths[] = {
    4, 3, 5, 5, 5, 5
};

void (*handlers[])(char*) = {help, list_directory, echo, about, get_file_info, clear};


#include "include/text.c"
#include "include/ll.c"
#include "include/disk.c"
#include "include/commands.c"