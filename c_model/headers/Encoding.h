#ifndef ENCODING_H
#define ENCODING_H

#include <stdint.h>
#include <stdio.h>
#include "bitmaps.h"
#include "pixel_MCU_image.h"
#include "Huffman.h"

void Encode_block (int16_t block[64], int16_t* previous_dc, void* dc_huffman_table, void* ac_huffman_table);
void MCU_Encode(int16_t zigzag_array[384], int16_t *previous_dc_y, int16_t *previous_dc_cb, int16_t *previous_dc_cr);
void Write_Physical_Bytes(uint8_t byte);
void Write_Huffman_bits(uint8_t symbol_byte, uint16_t value_bits, void* huffman_table);
void Put_bits(uint32_t bits, uint8_t num_bits);
void Flush_bits();
void open_jpeg_file(char*);
void close_jpeg_file();


#endif /* ENCODING_H */