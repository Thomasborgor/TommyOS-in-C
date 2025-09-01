#include <stdint.h>

char *videomemptr = (char*)0xA0000;

void kernelMain() {
    uint32_t width  = 800;     // framebuffer width
    uint32_t height = 600;     // framebuffer height
    uint32_t pitch  = 200;    // bytes per row = width * 4 (32-bit color)

    uint32_t color = 0x00FF00FF; // ARGB/XRGB

    for (uint32_t y = 0; y < height; y++) {
        uint32_t *row = (uint32_t*)(videomemptr + y * pitch);
        for (uint32_t x = 0; x < width; x++) {
            row[x] = color;
        }
    }

    while (1) { asm("hlt"); }
}
