#ifndef JPEG_ENCODE_H
#define JPEG_ENCODE_H

#include "bitmaps.h"
#include "pixel_MCU_image.h"
#include "JPEG_steps.h"
#include "Encoding.h"
extern const uint8_t Q_LUMA_Zigzag[64];
extern const uint8_t Q_CHROMA_Zigzag[64];


void copy_block(ycbcr_image* image, int start_x, int start_y, ycbcr_pixel block[16][16]);
void jpeg_encode(ycbcr_image* image, int width, int height);
void write_16bits_big_endian(uint16_t value);
void write_jpeg_file_header(int width, int height);
void write_DQT_Table_Info();
void write_DHT_segments(uint8_t class_id, const uint8_t* bits, const uint8_t* vals);
void write_jpeg_file_footer();



#endif /* JPEG_ENCODE_H */