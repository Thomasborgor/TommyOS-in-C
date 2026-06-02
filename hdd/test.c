#include "headers/types.h"
#include "headers/ll.h"
#include "headers/text.h"

void _start(char* arg) {
    video_offset = vga_get_cursor();
    int idx = 0;
    while(arg[idx] > 32) {
        idx++;
    }
    arg += idx+1;
    printstr(arg, 15);
    
}

#include "include/ll.c"
#include "include/text.c"
