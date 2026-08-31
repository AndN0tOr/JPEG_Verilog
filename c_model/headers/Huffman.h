#ifndef HUFFMAN_H
#define HUFFMAN_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include "Encoding.h"

extern FILE *jpeg_file;

typedef struct{
    int16_t value;
    int8_t size;
}size_value;

typedef struct{
    uint16_t code;
    uint8_t length;
}huffman_code;
extern const uint8_t STD_DC_LUMA_BITS[16];
extern const uint8_t STD_DC_LUMA_VALS[12];
extern const uint8_t STD_AC_LUMA_BITS[16];
extern const uint8_t STD_AC_LUMA_VALS[162];
extern const uint8_t STD_DC_CHROMA_BITS[16];
extern const uint8_t STD_DC_CHROMA_VALS[12];
extern const uint8_t STD_AC_CHROMA_BITS[16];
extern const uint8_t STD_AC_CHROMA_VALS[162];
extern huffman_code HT_DC_LUMA[256];
extern huffman_code HT_AC_LUMA[256];
extern huffman_code HT_DC_CHROMA[256];
extern huffman_code HT_AC_CHROMA[256];
size_value get_size_value(int16_t value);
size_value encode_dc_dpcm(int16_t current_dc, int16_t previous_dc);
void generate_huffman_table(const uint8_t* bits, const uint8_t* vals, huffman_code* table);
void init_jpeg_encoding();




#endif // HUFFMAN_H