#ifndef JPEG_STEPS_H
#define JPEG_STEPS_H

#define _USE_MATH_DEFINES
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>

#include "bitmaps.h"
#include "pixel_MCU_image.h"

extern const double cos_LUT[8][8];

ycbcr_image* color_space_transform(const rgb_image* rgb_image);
void free_ycbcr_image(ycbcr_image* ycbcr_image);
void MCU_chroma_downsample_420(ycbcr_pixel array16x16[16][16], int16_t block16x16y[16][16], int16_t block8x8cb[8][8], int16_t block8x8cr[8][8]);
void DCT_8x8(int16_t block8x8[8][8], double dct_block[8][8]);
void DCT_8x8_separable(int16_t block8x8[8][8], double dct_block[8][8]);
void getTestDCT_8x8();
void Quantize_block_MCU_50(
    double blockYY1[8][8], double blockY2[8][8], double blockY3[8][8], double blockY4[8][8],
    double blockCB[8][8], double blockCR[8][8],
    int16_t quantized_blockY1[8][8], int16_t quantized_blockY2[8][8], int16_t quantized_blockY3[8][8], int16_t quantized_blockY4[8][8],
    int16_t quantized_blockCB[8][8], int16_t quantized_blockCR[8][8]);
void Quantize_block_8x8_50(double block8x8[8][8], int16_t quantized_block[8][8], int8_t Y_Chroma);
void getTestQuantization();
void Extract_8x8_from_16x16(int16_t block16x16[16][16], int16_t block8x8[8][8], int start_row, int start_col);
void Zigzag_scan_8x8(int16_t block[8][8], int16_t* zigzag_array);
void Zigzag_scan_MCU(
    int16_t blockY1[8][8], int16_t blockY2[8][8], int16_t blockY3[8][8], int16_t blockY4[8][8],
    int16_t blockCB[8][8], int16_t blockCR[8][8],
    int16_t zigzag_array[384]);


#endif /* JPEG_STEPS_H */