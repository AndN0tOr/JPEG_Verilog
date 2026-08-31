#ifndef PIXEL_MCU_IMAGE_H
#define PIXEL_MCU_IMAGE_H

#include <stdint.h>
#pragma pack(push, 1)

typedef struct{
    uint8_t b;
    uint8_t g;
    uint8_t r;
}rgb_pixel;
#pragma pack(pop)
typedef struct{
    rgb_pixel ** data;
    uint32_t height;
    uint32_t width;
}rgb_image;
typedef struct {
    int8_t y;    
    int8_t cb;
    int8_t cr; 
} ycbcr_pixel;

typedef struct {
    ycbcr_pixel** data;
    uint32_t width;
    uint32_t height;
} ycbcr_image;



void copy_block(ycbcr_image* image, int start_x, int start_y, ycbcr_pixel block[16][16]);

#endif /* PIXEL_MCU_IMAGE_H */