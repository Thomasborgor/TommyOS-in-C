#include <stdint.h>

char *videomemptr = (char*)0xA0000;

void kernelMain() {
    unsigned long long thingy = 0;
	while (thingy < 800*600) {
		videomemptr[thingy * 4] = 0x0;
		videomemptr[thingy * 4+1] = 0xff;
		videomemptr[thingy * 4+2] = 0xff;
		videomemptr[thingy * 4+2] = 0xff;
		thingy++;
	}
}
