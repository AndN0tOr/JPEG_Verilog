#include "../headers/test.h"

void print_block_MCU(ycbcr_pixel block[16][16]){
    printf("16x16 Block:\n");
    for (int i = 0; i < 16; i++){
        for (int j = 0; j < 16; j++){
            printf("(%d, %d, %d) ", block[i][j].y, block[i][j].cb, block[i][j].cr);
        }
        printf("\n");
    }
}
void print_block_8x8(ycbcr_pixel block[8][8]){
    printf("8x8 Block:\n");
    for (int i = 0; i < 8; i++){
        for (int j = 0; j < 8; j++){
            printf("(%d, %d, %d) ", block[i][j].y, block[i][j].cb, block[i][j].cr);
        }
        printf("\n");
    }
}
void print_block_16x16_1channel(int16_t block[16][16]){
    printf("16x16 Block (Y channel):\n");
    for (int i = 0; i < 16; i++){
        for (int j = 0; j < 16; j++){
            printf("%d ", block[i][j]);
        }
        printf("\n");
    }
}
void print_block_8x8_1channel(int16_t block[8][8]){
    printf("8x8 Block:\n");
    for (int i = 0; i < 8; i++){
        for (int j = 0; j < 8; j++){
            printf("%d ", block[i][j]);
        }
        printf("\n");
    }
}
void print_DCT_block_8x8(double block[8][8]){
    printf("DCT 8x8 Block:\n");
    for (int i = 0; i < 8; i++){
        for (int j = 0; j < 8; j++){
            printf("%.2f \t", block[i][j]);
        }
        printf("\n");
    }
}
void print_DCT_block_16x16(double block[16][16]){
    printf("DCT 16x16 Block:\n");
    for (int i = 0; i < 16; i++){
        for (int j = 0; j < 16; j++){
            printf("%.2f \t", block[i][j]);
        }
        printf("\n");
    }
}
void Test_Chroma_Downsample_420(){
    // This function can be implemented to test the chroma downsampling function
    int16_t block16x16y[16][16];
    int16_t block8x8cb[8][8];
    int16_t block8x8cr[8][8];
    ycbcr_pixel block16x16[16][16];
    rgb_image* test_rgb_image = read_bitmap("test_image.bmp"); // Create a test RGB image with known values
    ycbcr_image* test_ycbcr_image = color_space_transform(test_rgb_image);
    copy_block(test_ycbcr_image, 0, 0, block16x16);
    MCU_chroma_downsample_420(block16x16, block16x16y, block8x8cb, block8x8cr);
    printf("Chroma Downsampled Cb Block:\n");
    print_block_8x8_1channel(block8x8cb);
    printf("Chroma Downsampled Cr Block:\n");
    print_block_8x8_1channel(block8x8cr);
    free_ycbcr_image(test_ycbcr_image);
    free_rgb_image(test_rgb_image);
};
void Test_DCT_8x8(){
    int16_t block[8][8] = {
        {-76, -73, -67, -62, -58, -67, -64, -55},
        {-65, -69, -73, -38, -19, -43, -59, -56},
        {-66, -69, -60, -15, 16, -24, -62, -55},
        {-65, -70, -57, -6, 26, -22, -58, -59},
        {-61, -67, -60, -24, -2, -40, -60, -58},
        {-49, -63, -68, -58, -51, -60, -70, -53},
        {-43, -57, -64, -69, -73, -67, -63, -45},
        {-41, -49, -59, -60, -63, -52, -50, -34}
    };
    // expected DCT result for the above block (calculated using a reference implementation)
    /* double expected_DCT[8][8] = {
    {-415.38, -30.19, -61.20,  27.24,  56.12, -20.10, -2.39,  0.46},
    {   4.47, -21.86, -60.76,  10.25,  13.15,  -7.09, -8.54,  4.88},
    { -46.83,   7.37,  77.13, -24.56, -28.91,   9.93,  5.42, -5.65},
    { -48.53,  12.07,  34.10, -14.76, -10.24,   6.30,  1.83,  1.95},
    {  12.12,  -6.55, -13.20,  -3.95,  -1.87,   1.75, -2.79,  3.14},
    {  -7.73,   2.91,   2.38,  -5.94,  -2.38,   0.94,  4.30,  1.85},
    {  -1.03,   0.18,   0.42,  -2.42,  -0.88,  -3.02,  4.12, -0.66},
    {  -0.17,   0.14,  -1.07,  -4.19,  -1.17,  -0.10,  0.50,  1.68}
    */
    // };
    printf("Original Block:\n");
    print_block_8x8_1channel(block);
    double DCT_block[8][8];
    DCT_8x8(block, DCT_block);
    printf("DCT Transformed Block:\n");
    print_DCT_block_8x8(DCT_block);
}

void Test_Quantization_50(){
    // This function can be implemented to test the quantization function
    
    int16_t quantized_blockY[8][8];
    int16_t quantized_blockCB[8][8];
    int16_t quantized_blockCR[8][8];
    double blockY1[8][8] ={
        { -415.38, -30.19, -61.20,  27.24,  56.12, -20.10, -2.39,  0.46},
        {   4.47, -21.86, -60.76,  10.25,  13.15,  -7.09, -8.54,  4.88},
        { -46.83,   7.37, 77.13 , -24.56 , -28.91 ,9.93 ,5.42 ,-5.65},
        { -48.53 ,12.07 ,34.10 ,-14.76 ,-10.24 ,6.30 ,1.83 ,1.95},
        { 12.12 , -6.55 , -13.20 , -3.95 ,-1.87 ,1.75 ,-2.79 ,3.14},
        {-7.73 ,2.91 ,2.38 ,-5.94 ,-2.38 ,0.94 ,4.30 ,1.85},
        {-1.03 ,0.18 ,0.42 ,-2.42 ,-0.88 ,-3.02 ,4.12 ,-0.66},
        {-0.17, 0.14, -1.07, -4.19, -1.17, -0.10,  0.50,  1.68}
    };
    double blockCB[8][8] = {
    {-240.62,  -3.11,  61.23,  -1.24, -15.63, -31.70, -59.59,  -3.00},
    {  18.07,  34.50, -32.35,  16.26, -10.10,  32.74,  45.02,  -0.54},
    {  48.07, -36.40, -10.44, -17.33,  50.51,  -6.71,  -3.29,  16.74},
    {  42.50, -35.70, -41.27,  -7.49, -35.22,  -5.02,   9.64, -35.62},
    { 192.87,  55.99,  43.00,   7.19,  -8.13, -24.81,  13.98,  32.17},
    {  67.03,  -5.69,  29.09,   1.17,  22.67,  44.26, -64.45,  -9.64},
    {-293.89,   7.07, -27.29,  40.01,  -9.69,  -7.11,  44.19,  -1.96},
    { -75.04, -37.85, -23.88, -64.30,  -1.41, -28.93,   8.37,  -1.27}
    };
    double blockCR[8][8] = {
    {205.50,  57.03, -11.81, -41.34,  79.00, -60.65,  21.13,  20.48},
    {190.28, -64.36,   9.97, -27.53, -69.62,  72.76,   1.04, -15.36},
    { -3.58,  41.93,  50.39,  71.62, -31.68,  10.88,   5.71, -69.77},
    {130.23,   0.48,   0.59, -19.92,  22.87,   5.49, -28.32,  27.76},
    {153.25, -34.21,  20.14, -46.46, -76.25,  17.87,  33.60, -16.16},
    {172.16,  50.94, -30.66,   5.85,  91.18, -36.27,  19.53,  -2.69},
    {-15.83, -26.71,  20.46, -19.60,  -5.28,  73.23, -17.14, -17.71},
    {-35.61,   3.01,  28.86,  43.91, -88.65, -43.23,  -6.41,   0.05}
    };
    Quantize_block_8x8_50(blockY1, quantized_blockY, 1);
    printf("Quantized Y Block:\n");
    print_block_8x8_1channel(quantized_blockY);
    Quantize_block_8x8_50(blockY1, quantized_blockY, 0);
    printf("Quantized Chroma Block:\n");
    print_block_8x8_1channel(quantized_blockY);
    // Expected output for y channel:
};
void Test_Zigzag_Scan_1block(){
    int16_t block[8][8] = {
        { 16, 11, 10, 16, 24, 40, 51, 61},
        { 12, 12, 14, 19, 26, 58, 60, 55},
        { 14, 13, 16, 24, 40, 57, 69, 56},
        { 14, 17, 22, 29, 51, 87, 80, 62},
        { 18, 22, 37, 56, 68,109 ,103 ,77},
        {24 ,35 ,55 ,64 ,81 ,104 ,113 ,92},
        {49 ,64 ,78 ,87 ,103 ,121 ,120 ,101},
        {72 ,92 ,95 ,98 ,112 ,100 ,103 ,99}
    };
    int16_t zigzag_array[64];
    Zigzag_scan_8x8(block, zigzag_array);
    printf("Zigzag Scanned Array:\n");
    for (int i =0; i <64; i++){
        printf("%d ", zigzag_array[i]);
    }
    printf("\n");
};
void Test_Get_Size_Value(){
    int16_t test_values[10] = {0, 1, 5, 10, 30, 98, -57, -38, -78, -128};
    printf("Value\tSize\tSize Value\n");
    for (int i = 0; i < 10; i++){
        size_value sv = get_size_value(test_values[i]);
        printf("%d\t%d\t%d\n", test_values[i], sv.size, sv.value);
    }
    printf("\n");
    printf("Expected Output: 0, 1, 3, 4, 5, 7, 7, 6, 7, 8\n");
}
void Test_Encode_DC_DPCM(){
    int16_t previous_DC = 100;
    int16_t current_DC = 150;
    size_value sv = encode_dc_dpcm(current_DC, previous_DC);
    printf("Expected DPCM Value: 50, Size: 6, Size Value: 50\n");
    printf("Previous DC: %d, Current DC: %d\n", previous_DC, current_DC);
    printf("DPCM Value: %d, Size: %d, Size Value: %d\n", current_DC - previous_DC, sv.size, sv.value);
}
void Test_Encode_Block(){
    int16_t block[8][8] = {
        {-26, -3, -6, 2, 2, -1, 0, 0} ,
        {0, -2, -4, 1, 1, 0, 0, 0} ,
        {-3, 1, 5, -1, -1, 0, 0, 0} ,
        {-3, 1, 2, -1, 0, 0, 0, 0} ,
        {1, 0, 0, 0, 0, 0, 0, 0} ,
        {0, 0, 0, 0, 0, 0, 0, 0} ,
        {0, 0, 0, 0, 0, 0, 0, 0} ,
        {0, 0, 0, 0, 0, 0, 0, 0}
    };
    init_jpeg_encoding();
    int16_t prev_dc = 0;
    printf("Luma DC AC:\n");
    Encode_block_8x8_output(block,&prev_dc, HT_DC_LUMA, HT_AC_LUMA);
    printf("\nChroma DC AC:\n");
    Encode_block_8x8_output(block,&prev_dc, HT_DC_CHROMA, HT_AC_CHROMA);

}
void Print_Huffman_bits(uint8_t symbol_byte, uint16_t value_bits, void* huffman_table){
    huffman_code* table = (huffman_code*)huffman_table;
    int16_t huff_code = table[symbol_byte].code;
    uint8_t huff_length = table[symbol_byte].length;
    Print_bits(huff_code, huff_length); // Write the Huffman code
    uint8_t value_size = symbol_byte & 0x0F; // Size is in the lower 4 bits of symbol_byte
    if (value_size > 0){
        Print_bits(value_bits, value_size); // Write the value bits (size is in the lower 4 bits of symbol_byte)
    }
}
void Print_Physical_Bytes(uint8_t byte){
    printf("%02X ", byte);
}
uint32_t bit_buffer_test = 0;
uint8_t bit_count_test = 0;
void Print_bits(uint32_t bits, uint8_t length){
    if (length == 0){
        return; // No bits to write
    }
    bit_buffer_test = (bit_buffer_test << length) | (bits & ((1 << length) - 1)); // Add new bits to buffer
    bit_count_test += length; // Update bit count

    while (bit_count_test >= 8){
        uint8_t byte_to_write = (bit_buffer_test >> (bit_count_test - 8)) & 0xFF; // Get the top 8 bits to write
        Print_Physical_Bytes(byte_to_write);
        if (byte_to_write == 0xFF){
            // If the byte is 0xFF, we need to write a zero byte after it to prevent marker confusion
            Print_Physical_Bytes(0x00);
        }
        bit_count_test -= 8; // Remove the written bits from the buffer
    }
}
void Encode_block_8x8_output(int16_t block[8][8], int16_t* previous_dc, void* dc_huffman_table, void* ac_huffman_table){
    // Bước 1: Quét Zig-zag khối 8x8 thành mảng 1 chiều 64 phần tử
    int16_t zigzag_array[64];
    Zigzag_scan_8x8(block, zigzag_array);

    // Bước 2: Mã hóa hệ số DC
    int16_t current_dc = zigzag_array[0];
    size_value dc_size_value = encode_dc_dpcm(current_dc, *previous_dc);
    *previous_dc = current_dc; // Cập nhật previous DC cho khối tiếp theo
    
    // Ghi mã Huffman cho hệ số DC
    Print_Huffman_bits(dc_size_value.size, dc_size_value.value, dc_huffman_table);
    
    // Bước 3: Mã hóa các hệ số AC
    int8_t run_length = 0;
    for (int8_t i = 1; i < 64; i++){
        if (zigzag_array[i] == 0){
            run_length++;
        } else {
            while (run_length > 15){
                // Ghi mã cho 16 số 0 liên tiếp (ZRL)
                Print_Huffman_bits(0xF0, 0, ac_huffman_table);
                run_length -= 16;
            }
            
            size_value ac_size_value = get_size_value(zigzag_array[i]);
            ac_size_value.size |= (run_length << 4); // Gộp run_length và size
            Print_Huffman_bits(ac_size_value.size, ac_size_value.value, ac_huffman_table);
            run_length = 0; // Reset run_length sau khi ghi một hệ số khác 0
        }
    }
    
    if (run_length > 0){
        // Ghi mã End of Block (EOB) nếu phần còn lại của khối toàn là số 0
        Print_Huffman_bits(0x00, 0, ac_huffman_table); // EOB symbol
    }
    
    // Đừng quên đẩy nốt các bit còn dư ra ngoài (Flush bits)
    if (bit_count_test > 0){
        uint8_t padding_bits = 8 - bit_count_test;
        uint8_t filler = (1 << padding_bits) - 1;
        Print_bits(filler, padding_bits);
    }
    bit_buffer_test = 0;
    bit_count_test = 0;
}
void Test_Performance(char* filename){
    uint64_t start_cycles, end_cycles, total_cycles;
    start_cycles = __rdtsc();
    float startTime = (float)clock() / CLOCKS_PER_SEC;
    rgb_image* image = read_bitmap(filename);
    ycbcr_image* ycbcr_image_ori = color_space_transform(image);
    jpeg_encode(ycbcr_image_ori, ycbcr_image_ori->width, ycbcr_image_ori->height);
    float endTime = (float)clock() / CLOCKS_PER_SEC;
    printf("Execution time: %f seconds\n", endTime - startTime);
    free_rgb_image(image);
    end_cycles = __rdtsc();
    total_cycles = end_cycles - start_cycles;
    printf("Total CPU cycles: %lu\n", total_cycles);
    printf("Average CPU cycles per pixel: %f\n", (double)total_cycles / (ycbcr_image_ori->width * ycbcr_image_ori->height));
    printf("Throughput: %f pixels/second\n", (ycbcr_image_ori->width * ycbcr_image_ori->height) / (endTime - startTime));
}