#ifndef BITMAPS_H
#define BITMAPS_H

#include <stdint.h>
#include"pixel_MCU_image.h"


#pragma pack(push, 1)

typedef struct {
    uint16_t header_field;
    uint32_t file_size;
    uint16_t reserved1;
    uint16_t reserved21;

    uint32_t data_offset;
}bmp_fileheader;

typedef struct {
    uint32_t infoheader_size;
    int32_t image_width;
    int32_t image_height;
    /* Must be 1 */
    uint16_t num_color_planes;
    uint16_t bits_per_pixel;
    uint32_t compression_method;
    uint32_t bitmap_data_size;
    /* In pixels per meter */
    int32_t horizontal_resolution;
    /* In pixels per meter */
    int32_t vertical_resolution;
    uint32_t num_of_colors;
    uint32_t num_of_important_colors;
}bmp_infoheader;
// Tai sao lai co cau truc nay?

#pragma pack(pop)

rgb_image* read_bitmap(const char* file_name);
void free_rgb_image(rgb_image* image);
void test_read_bitmap(const char* file_name);


#endif /* BITMAPS_H */