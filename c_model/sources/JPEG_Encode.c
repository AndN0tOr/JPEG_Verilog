#include "../headers/JPEG_Encode.h"
#include "../headers/JPEG_steps.h"
#include "../headers/pixel_MCU_image.h"

const uint8_t Q_LUMA_Zigzag[64] = {
    16, 11, 12, 14, 12, 10, 16, 14, 13, 14, 18, 17, 16, 19, 24, 40,
    26, 24, 22, 22, 24, 49, 35, 37, 29, 40, 58, 51, 61, 60, 57, 51,
    56, 55, 64, 72, 92, 78, 64, 68, 87, 69, 55, 56, 80, 109, 81, 87,
    95, 98, 103, 104, 103, 62, 77, 113, 121, 112, 100, 120, 92, 101, 103, 99
};
const uint8_t Q_CHROMA_Zigzag[64] = {
    17, 18, 18, 24, 21, 24, 47, 26, 26, 47, 99, 66, 56, 66, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99
};
void write_16bit(uint16_t value) {
    Write_Physical_Bytes((value >> 8) & 0xFF);
    Write_Physical_Bytes(value & 0xFF);
}
void write_DQT_Table_Info(){
    // This function will write the DQT (Define Quantization Table) segments for the Y and Cb/Cr channels to the output file.
    // It will include the quantization tables that are used during the quantization step of JPEG encoding.
    // ...
    extern const uint8_t Q_LUMA_Zigzag[64]; // Đảm bảo mảng này đã được zíc-zắc!
    Write_Physical_Bytes(0xFF); Write_Physical_Bytes(0xDB);
    write_16bit(67); Write_Physical_Bytes(0x00); // ID 0
    for(int i=0; i<64; i++) Write_Physical_Bytes(Q_LUMA_Zigzag[i]);
    extern const uint8_t Q_CHROMA_Zigzag[64]; // Đảm bảo mảng này đã được zíc-zắc!
    Write_Physical_Bytes(0xFF); Write_Physical_Bytes(0xDB);
    write_16bit(67); Write_Physical_Bytes(0x01); // ID 1
    for(int i=0; i<64; i++) Write_Physical_Bytes(Q_CHROMA_Zigzag[i]);

}
void write_16bits_big_endian(uint16_t value){
    Write_Physical_Bytes((value >> 8) & 0xFF); // Write the high byte
    Write_Physical_Bytes(value & 0xFF); // Write the low byte
}
void write_DHT_segments(uint8_t class_id, const uint8_t* bits, const uint8_t* vals){
    // This function will write the DHT (Define Huffman Table) segments for the DC and AC Huffman tables to the output file.
    // It will include the Huffman tables for both the Y and Cb/Cr channels, which are used during the entropy coding step of JPEG encoding.
    // ...
    // 1. Generate Huffman tables for DC and AC coefficients
    Write_Physical_Bytes(0xFF);
    Write_Physical_Bytes(0xC4);
    
    // Tính chiều dài: 2 (độ dài) + 1 (class_id) + 16 (bits) + tổng vals
    uint16_t num_vals = 0;
    for(int i=0; i<16; i++) num_vals += bits[i];
    uint16_t length = 2 + 1 + 16 + num_vals;
    
    write_16bits_big_endian(length);
    Write_Physical_Bytes(class_id); // 0x00=DC_Luma, 0x10=AC_Luma, 0x01=DC_Chroma, 0x11=AC_Chroma
    
    for(int i=0; i<16; i++) Write_Physical_Bytes(bits[i]);
    for(int i=0; i<num_vals; i++) Write_Physical_Bytes(vals[i]);
}

void write_jpeg_file_header(int width, int height){
    // This function will write the necessary JPEG file header bytes to the output file.
    // It will include the SOI marker, APP0 segment, DQT segments, SOF0 segment, DHT segments, and SOS segment.
    // ...
    // 1. Write SOI marker
    Write_Physical_Bytes(0xFF);
    Write_Physical_Bytes(0xD8); // SOI marker - Start of Image
    // 2. Write APP0 segment (JFIF header)
    uint8_t app0[18] = {
        0xFF, 0xE0, // APP0 marker
        0x00, 0x10, // Length of APP0 segment(16 bytes)
        'J', 'F', 'I', 'F', 0x00, // Identifier "JFIF\0" - length: 5 bytes
        0x01, 0x01, // Version 1.01
        0x00, // Units (0: no units, 1: dots per inch, 2: dots per cm)
        0x00, 0x01, // X density (1)
        0x00, 0x01, // Y density (1)
        0x00, // Thumbnail width (0)
        0x00  // Thumbnail height (0)
    };
    for (int i = 0; i < 18; i++) {
        Write_Physical_Bytes(app0[i]);
    }
    // 3. Write DQT segments for Y, Cb, Cr channels
     // Đảm bảo mảng này đã được zíc-zắc!
    Write_Physical_Bytes(0xFF); Write_Physical_Bytes(0xDB);
    write_16bit(67); Write_Physical_Bytes(0x00); // ID 0
    for(int i=0; i<64; i++) Write_Physical_Bytes(Q_LUMA_Zigzag[i]);

 // Đảm bảo mảng này đã được zíc-zắc!
    Write_Physical_Bytes(0xFF); Write_Physical_Bytes(0xDB);
    write_16bit(67); Write_Physical_Bytes(0x01); // ID 1
    for(int i=0; i<64; i++) Write_Physical_Bytes(Q_CHROMA_Zigzag[i]);

    // 4. SOF0 segment (Start of Frame)
    Write_Physical_Bytes(0xFF);
    Write_Physical_Bytes(0xC0); // SOF0 marker - Start of Frame (Baseline DCT)
    write_16bits_big_endian(17); // Length of SOF0 segment (17 bytes)
    Write_Physical_Bytes(8); // Sample precision (8 bits per sample)

    write_16bits_big_endian(height); // Image height
    write_16bits_big_endian(width); // Image width
    Write_Physical_Bytes(3); // Number of components (3 for YCbCr)

    // Component 1: Y
    Write_Physical_Bytes(1); // Component ID (1 for Y)
    Write_Physical_Bytes(0x22); // Sampling factors (4:2:2 - horizontal: 2, vertical: 2)
    Write_Physical_Bytes(0); // Quantization table number for Y (0)
    // Component 2: Cb
    Write_Physical_Bytes(2); // Component ID (2 for Cb)
    Write_Physical_Bytes(0x11); // Sampling factors (4:2:2 - horizontal: 1, vertical: 1)
    Write_Physical_Bytes(1); // Quantization table number for Cb (1)
    // Component 3: Cr
    Write_Physical_Bytes(3); // Component ID (3 for Cr)
    Write_Physical_Bytes(0x11); // Sampling factors (4:2:2 - horizontal: 1, vertical: 1)
    Write_Physical_Bytes(1); // Quantization table number for Cr (1)
    // 5. Write DHT segments for DC and AC Huffman tables
    write_DHT_segments(0x00, STD_DC_LUMA_BITS, STD_DC_LUMA_VALS);
    write_DHT_segments(0x10, STD_AC_LUMA_BITS, STD_AC_LUMA_VALS);
    write_DHT_segments(0x01, STD_DC_CHROMA_BITS, STD_DC_CHROMA_VALS);
    write_DHT_segments(0x11, STD_AC_CHROMA_BITS, STD_AC_CHROMA_VALS);
    // 6. Write SOS segment (Start of Scan)
    uint8_t sos[14] = {
        0xFF, 0xDA, // SOS marker
        0x00, 0x0C, // Length of SOS segment (12 bytes)
        0x03, // Number of components in scan (3 for YCbCr)
        0x01, 0x00, // Component ID (1 for Y) and Huffman table numbers (DC: 0, AC: 0)
        0x02, 0x11, // Component ID (2 for Cb) and Huffman table numbers (DC: 1, AC: 1)
        0x03, 0x11, // Component ID (3 for Cr) and Huffman table numbers (DC: 1, AC: 1)
        0x00, // Start of spectral selection (not used in baseline JPEG)
        0x3F, // End of spectral selection (not used in baseline JPEG)
        0x00  // Successive approximation bit position (not used in baseline JPEG)
    };
    for (int i = 0; i < 14; i++) {
        Write_Physical_Bytes(sos[i]);
    }
}
void write_jpeg_file_footer(){
    // This function will write the necessary JPEG file footer bytes to the output file.
    // It will include the EOI marker to indicate the end of the image data.
    Write_Physical_Bytes(0xFF);
    Write_Physical_Bytes(0xD9); // EOI marker - End of Image
}




void jpeg_encode(ycbcr_image* image, int width, int height){
    ycbcr_pixel block16x16[16][16];
    int16_t block16x16y[16][16];
    int16_t block8x8cb[8][8];
    int16_t block8x8cr[8][8];
    int16_t y1[8][8];
    int16_t y2[8][8];
    int16_t y3[8][8];
    int16_t y4[8][8];
    double dct_block_y1[8][8];
    double dct_block_y2[8][8];
    double dct_block_y3[8][8];
    double dct_block_y4[8][8];
    double dct_block_cb[8][8];
    double dct_block_cr[8][8];
    int16_t quantized_blockY1[8][8];
    int16_t quantized_blockY2[8][8];
    int16_t quantized_blockY3[8][8];
    int16_t quantized_blockY4[8][8];
    int16_t quantized_blockCB[8][8];
    int16_t quantized_blockCR[8][8];
    int16_t previous_dc_y = 0;
    int16_t previous_dc_cb = 0;
    int16_t previous_dc_cr = 0;
    int16_t zigzag_array[384];
    open_jpeg_file("images/output/output.jpg");
    write_jpeg_file_header(width, height);
    init_jpeg_encoding();
    for (int y = 0; y < image->height; y += 16){
        for (int x = 0; x < image->width; x += 16){
            copy_block(image, x, y, block16x16);
            MCU_chroma_downsample_420(block16x16, block16x16y, block8x8cb, block8x8cr);
            Extract_8x8_from_16x16(block16x16y, y1, 0, 0); // Lấy block Y thứ 1
            DCT_8x8_separable(y1, dct_block_y1); // DCT cho block Y thứ 1
            Extract_8x8_from_16x16(block16x16y, y2, 0, 8); // Lấy block Y thứ 2
            DCT_8x8_separable(y2, dct_block_y2); // DCT cho block Y thứ 2
            Extract_8x8_from_16x16(block16x16y, y3, 8, 0); // Lấy block Y thứ 3
            DCT_8x8_separable(y3, dct_block_y3); // DCT cho block Y thứ 3
            Extract_8x8_from_16x16(block16x16y, y4, 8, 8); // Lấy block Y thứ 4
            DCT_8x8_separable(y4, dct_block_y4); // DCT cho block Y thứ 4
            DCT_8x8_separable(block8x8cb, dct_block_cb);
            DCT_8x8_separable(block8x8cr, dct_block_cr);
            Quantize_block_MCU_50(
                dct_block_y1, dct_block_y2, dct_block_y3, dct_block_y4,
                dct_block_cb, dct_block_cr, 
                quantized_blockY1, quantized_blockY2, quantized_blockY3, quantized_blockY4,
                quantized_blockCB, quantized_blockCR);
            Zigzag_scan_MCU(
                quantized_blockY1, quantized_blockY2, quantized_blockY3, quantized_blockY4,
                quantized_blockCB, quantized_blockCR, zigzag_array);
            MCU_Encode(zigzag_array, &previous_dc_y, &previous_dc_cb, &previous_dc_cr);
        }
    }
    Flush_bits(); // Flush any remaining bits in the buffer
    close_jpeg_file();

}