#include <stdio.h>
#include <stdlib.h>
#include "image.h"
#include "decode128.h"


int main(void)
{
    if (sizeof(bmpHdr) != 54)
    {
        printf("Size of the bitmap header is invalid (%d). Please, check compiler options.\n", sizeof(bmpHdr));
        return 1;
    }

    ImageInfo *pImg = readBmp("result.bmp");
    if (pImg == NULL)
    {
        printf("Error opening input file result.bmp\n");
        return 1;
    }
    char result_buffer[256];
    decode128(pImg, result_buffer); // albo const char nw
    if (result_buffer == NULL) {
        printf("Błąd dekodowania Code 128\n");
    } else {
        printf("Odczytany tekst: %s\n", result_buffer);
    }
    freeImage(pImg);
    return 0;
}
