#ifndef TEST_H
#define TEST_H

#include <x86intrin.h>
#include <time.h>
#include <stdio.h>

#include "pixel_MCU_image.h"
#include "JPEG_Encode.h"
#include "Encoding.h"
#include "JPEG_steps.h"
#include "Huffman.h"

void print_block_MCU(ycbcr_pixel block[16][16]);
void print_block_8x8(ycbcr_pixel block[8][8]);
void print_block_16x16_1channel(int16_t block[16][16]);
void print_block_8x8_1channel(int16_t block[8][8]);
void print_DCT_block_8x8(double block[8][8]);
void print_DCT_block_16x16(double block[16][16]);
void Print_Huffman_bits(uint8_t symbol_byte, uint16_t value_bits, void* huffman_table);
void Print_Physical_Bytes(uint8_t byte);
void Print_bits(uint32_t bits, uint8_t num_bits);
void Encode_block_8x8_output(int16_t block[8][8], int16_t* previous_dc, void* dc_huffman_table, void* ac_huffman_table);
void Test_Chroma_Downsample_420();
void Test_DCT_8x8();
void Test_Quantization_50();
void Test_Get_Size_Value();
void Test_Encode_DC_DPCM();
void Test_Encode_Block();
void Test_Everything();
void Test_Performance(char* filename);



#endif /* TEST_H */
