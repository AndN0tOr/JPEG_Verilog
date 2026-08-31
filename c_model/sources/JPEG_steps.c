#include "../headers/JPEG_steps.h"

const double cos_LUT[8][8] = {
    { 1.000000,  0.980785,  0.923880,  0.831470,  0.707107,  0.555570,  0.382683,  0.195090},
    { 1.000000,  0.831470,  0.382683, -0.195090, -0.707107, -0.980785, -0.923880, -0.555570},
    { 1.000000,  0.555570, -0.382683, -0.980785, -0.707107,  0.195090,  0.923880,  0.831470},
    { 1.000000,  0.195090, -0.923880, -0.555570,  0.707107,  0.831470, -0.382683, -0.980785},
    { 1.000000, -0.195090, -0.923880,  0.555570,  0.707107, -0.831470, -0.382683,  0.980785},
    { 1.000000, -0.555570, -0.382683,  0.980785, -0.707107, -0.195090,  0.923880, -0.831470},
    { 1.000000, -0.831470,  0.382683,  0.195090, -0.707107,  0.980785, -0.923880,  0.555570},
    { 1.000000, -0.980785,  0.923880, -0.831470,  0.707107, -0.555570,  0.382683, -0.195090}
};
ycbcr_image* color_space_transform(const rgb_image* rgb_image){
    ycbcr_image* ycbcr_image = malloc(sizeof(*ycbcr_image));
    if (ycbcr_image == NULL){
        printf("Memory allocation failed");
        return NULL;
    }
    ycbcr_image->width = rgb_image->width;
    ycbcr_image->height = rgb_image->height;

    ycbcr_image->data = malloc(rgb_image->width * sizeof(ycbcr_pixel*));
    if (ycbcr_image->data == NULL){
        printf("Memory allocation failed");
        free(ycbcr_image);
        return NULL;
    }
    for (int i = 0; i < rgb_image->width; i++){
        ycbcr_image->data[i] = malloc(rgb_image->height * sizeof(ycbcr_pixel));
        if (ycbcr_image ->data[i] == NULL){
            printf("Memory allocation failed.");
            // free all previously allocated memory.
            for (int k = 0; k < i; k++){
                free(ycbcr_image->data[k]);
            }
            free(ycbcr_image->data);
            free(ycbcr_image);
            return NULL;
        }
    }

    for (int i = 0; i < rgb_image->height; i++){
        for (int j = 0; j < rgb_image->width; j++){
            uint8_t r = rgb_image->data[j][i].r;
            uint8_t g = rgb_image->data[j][i].g;
            uint8_t b = rgb_image->data[j][i].b;

            ycbcr_pixel pixel;
            uint8_t y = 0.299*r + 0.587*g + 0.114*b;
            uint8_t cb = -0.168736*r - 0.331264*g + 0.5*b  + 128;
            uint8_t cr = 0.5*r - 0.418688*g - 0.081312*b  + 128;

            pixel.y = y - 128; // Center Y around 0 for DCT
            pixel.cb = cb - 128;
            pixel.cr = cr - 128;

            ycbcr_image->data[j][i] = pixel;
        }
    }

    return ycbcr_image;
}
void free_ycbcr_image(ycbcr_image* ycbcr_image){
    if (ycbcr_image == NULL){
        return;
    }
    for (int i = 0; i < ycbcr_image->width; i++){
        free(ycbcr_image->data[i]);
    }
    free(ycbcr_image->data);
    free(ycbcr_image);
    printf("Memory for this image is cleared.\n");
}
void MCU_chroma_downsample_420(
    ycbcr_pixel array16x16[16][16], 
    int16_t block16x16y[16][16],
    int16_t block8x8cb[8][8], 
    int16_t block8x8cr[8][8]
){
    for (int i = 0; i < 8; i++){
        for (int j = 0; j < 8; j++){
            int16_t sumcb = 0;
            int16_t sumcr = 0;
            for (int m = 0; m < 2; m++){
                for (int n = 0; n < 2; n++){
                    sumcb += array16x16[i*2 + m][j*2 + n].cb;
                    sumcr += array16x16[i*2 + m][j*2 + n].cr;
                    block16x16y[i*2 + m][j*2 + n] = array16x16[i*2 + m][j*2 + n].y;

                }
            }
            block8x8cb[i][j] = (sumcb / 4); 
            block8x8cr[i][j] = (sumcr / 4); 
        }
    }
}
void DCT_8x8(int16_t block8x8[8][8], double dct_block[8][8]){
    // DCT implementation goes here
    for (int i = 0; i < 8; i++){
        for (int j = 0; j < 8; j++){
            double sum = 0.0;
            for (int x = 0; x < 8; x++){
                for (int y = 0; y < 8; y++){
                    sum += block8x8[x][y] * cos_LUT[x][i] * cos_LUT[y][j];
                }
            }
            double ci = (i == 0) ? (1.0 / sqrt(2)) : 1.0;
            double cj = (j == 0) ? (1.0 / sqrt(2)) : 1.0;
            dct_block[i][j] = 0.25 * ci * cj * sum;
        }
    }
}
void dct_1d(double array1d [8], double dct_block[8]){
    double dct_1row [8];
    for (int dct_index = 0; dct_index < 8; dct_index++){
        double sum_dct = 0;
        for (int in_index = 0; in_index < 8; in_index++){
            sum_dct += array1d[in_index] * cos_LUT[in_index][dct_index];
        }   
        double cu = (dct_index == 0) ? (1.0 / sqrt(2.0)) : 1.0;
        dct_block[dct_index] = 0.5 * sum_dct * cu;
    }
}
void DCT_8x8_separable(int16_t input_array[8][8], double output_array[8][8]){
    /* Normally, if we use normal dct_2d algorithm, it would take 64 * 64 to complete a function for 8x8 block
    Instead, we can use this algorithm, based on seperability of the matrix, with the complexity reduced 4 times
    compared to the old one.*/
    double temp_matrix [8][8];
    // Firstly, we use the dct_1d function to scan the entire matrix. This would take 8 * 8 * 8 operations
    // And store the computed results to a temporary matrix.
    double input_matrix [8][8];
    for (int row = 0; row < 8; row++){
        for (int col = 0; col <8; col++){
            input_matrix[row][col] = (double)input_array[row][col];
        }
    }
    for (int i = 0; i < 8; i++){
        dct_1d(input_matrix[i], temp_matrix[i]);    
    }
    // Then, we re-compute the temporary matrix, still using 1d_dct, but column by column.
    // Because C store values in rows, we must extract the values by column manually.
    // For each time stored a column successfully, we use them to compute the final outputs.
    // And again, this step take  8 * 8 * 8 operatios which total is 16 * 64, 1/4 compared to the original.
    for (int col = 0; col < 8; col++){
        double col_in[8];
        double col_out[8];
        for (int row = 0; row < 8; row ++){
            col_in[row] = temp_matrix[row][col];
        }
        dct_1d(col_in, col_out);
        for (int row = 0; row < 8; row++){
            output_array[row][col] = col_out[row];
        }
    }  
}
void Quantize_block_MCU_50(double blockY1[8][8], double blockY2[8][8], double blockY3[8][8], double blockY4[8][8],
    double blockCB[8][8], double blockCR[8][8],
    int16_t quantized_blockY1[8][8], int16_t quantized_blockY2[8][8], int16_t quantized_blockY3[8][8], int16_t quantized_blockY4[8][8],
    int16_t quantized_blockCB[8][8], int16_t quantized_blockCR[8][8])
    {
    // Quantization implementation goes here
    // This function will quantize the DCT coefficients using a standard quantization matrix for quality factor 50.
    uint8_t quant_matrix_Y_50[8][8] = {
        16, 11, 10, 16, 24, 40, 51, 61,
        12, 12, 14, 19, 26, 58, 60, 55,
        14, 13, 16, 24, 40, 57, 69, 56,
        14, 17, 22, 29, 51, 87, 80, 62,
        18, 22, 37, 56, 68, 109, 103, 77,
        24, 35, 55, 64, 81, 104, 113, 92,
        49, 64, 78, 87, 103, 121, 120, 101,
        72, 92, 95, 98, 112, 100, 103, 99
    };
    uint8_t quant_matrix_C_50[8][8] = {
        17, 18, 24, 47, 99, 99, 99, 99,
        18, 21, 26, 66, 99, 99, 99, 99,
        24, 26, 56, 99, 99, 99, 99, 99,
        47, 66, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99 ,99 ,99 ,99 ,99 ,99 ,99 ,99
    };
    // quantization for Y channel
    for (int i = 0; i < 8; i++){
        for (int j = 0; j < 8; j++){
            quantized_blockY1[i][j] = round(blockY1[i][j] / quant_matrix_Y_50[i][j]);
            quantized_blockY2[i][j] = round(blockY2[i][j] / quant_matrix_Y_50[i][j]);
            quantized_blockY3[i][j] = round(blockY3[i][j] / quant_matrix_Y_50[i][j]);
            quantized_blockY4[i][j] = round(blockY4[i][j] / quant_matrix_Y_50[i][j]);
        }
    }
    // quantization for Cb and Cr channels

    for (int i = 0; i < 8; i++){
        for (int j = 0; j < 8; j++){
            quantized_blockCB[i][j] = round(blockCB[i][j] / quant_matrix_C_50[i][j]);
            quantized_blockCR[i][j] = round(blockCR[i][j] / quant_matrix_C_50[i][j]);
        }
    }
}
void Quantize_block_8x8_50(double block8x8[8][8], int16_t quantized_block[8][8], int8_t Y_Chroma){
    uint8_t quant_matrix_Y_50[8][8] = {
        16, 11, 10, 16, 24, 40, 51, 61,
        12, 12, 14, 19, 26, 58, 60, 55,
        14, 13, 16, 24, 40, 57, 69, 56,
        14, 17, 22, 29, 51, 87, 80, 62,
        18, 22, 37, 56, 68, 109, 103, 77,
        24, 35, 55, 64, 81, 104, 113, 92,
        49, 64, 78, 87, 103, 121, 120, 101,
        72, 92, 95, 98, 112, 100, 103, 99
    };
    uint8_t quant_matrix_C_50[8][8] = {
        17, 18, 24, 47, 99, 99, 99, 99,
        18, 21, 26, 66, 99, 99, 99, 99,
        24, 26, 56, 99, 99, 99, 99, 99,
        47, 66, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99 ,99 ,99 ,99 ,99 ,99 ,99 ,99
    };
    if (Y_Chroma == 1){
        for (int i = 0; i < 8; i++){
            for (int j = 0; j < 8; j++){
                quantized_block[i][j] = round(block8x8[i][j] / quant_matrix_Y_50[i][j]);
            }
        }
    }else{
        for (int i = 0; i < 8; i++){
            for (int j = 0; j < 8; j++){
                quantized_block[i][j] = round(block8x8[i][j] / quant_matrix_C_50[i][j]);
            }
        }
    }
}
void getTestQuantization(){
    double input_array[8][8] = {
        {1, 2, 3, 4, 5, 6, 7, 8},
        {9, 10, 11, 12, 13, 14, 15, 16},
        {17, 18, 19, 20, 21, 22, 23, 24},
        {25, 26, 27, 28, 29, 30, 31, 32},
        {33, 34, 35, 36, 37, 38, 39, 40},
        {41, 42, 43, 44, 45, 46, 47, 48},
        {49, 50, 51, 52, 53, 54, 55, 56},
        {57, 58, 59, 60, 61, 62, 63, 64}
    };
    int16_t output_array[8][8];
    Quantize_block_8x8_50(input_array, output_array, 0);
    for (int i = 0; i < 8; i++){
        for (int j = 0; j < 8; j++){
            printf("%d ", output_array[i][j]);
        }
        printf("\n");
    }   
}
const int16_t zigzag_order[64] = {
        0, 1, 8, 16, 9, 2, 3, 10,
        17, 24, 32, 25, 18, 11, 4, 5,
        12, 19, 26, 33, 40, 48, 41, 34,
        27, 20, 13, 6, 7, 14, 21, 28,
        35, 42, 49, 56, 57, 50, 43, 36,
        29, 22, 15, 23, 30, 37, 44, 51,
        58, 59, 52, 45, 38, 31, 39, 46,
        53, 60, 61, 54, 47, 55, 62, 63
    };
void Zigzag_scan_8x8(int16_t block[8][8], int16_t* zigzag_array){
    int index = 0;
    // Zigzag scan for the 8x8 block
    int16_t *linear_block = (int16_t*)block;
    for (int i = 0; i < 64; i++){
        zigzag_array[i] = linear_block[zigzag_order[i]];
    }
}
void Extract_8x8_from_16x16(int16_t block16x16[16][16], int16_t block8x8[8][8], int start_row, int start_col){
    for (int i = 0; i < 8; i++){
        for (int j = 0; j < 8; j++){
            block8x8[i][j] = block16x16[start_row + i][start_col + j];
        }
    }
}
void Zigzag_scan_MCU(
    int16_t blockY1[8][8], int16_t blockY2[8][8], int16_t blockY3[8][8], int16_t blockY4[8][8],
    int16_t blockCB[8][8], int16_t blockCR[8][8],
    int16_t zigzag_array[384])
{
   
    // Zigzag scan Y channel for the 16x16 block of all channels
    Zigzag_scan_8x8(blockY1, zigzag_array);
    Zigzag_scan_8x8(blockY2, zigzag_array + 64);
    Zigzag_scan_8x8(blockY3, zigzag_array + 128);
    Zigzag_scan_8x8(blockY4, zigzag_array + 192);
    // Scan for Cb and Cr channels
    Zigzag_scan_8x8(blockCB, zigzag_array + 256);
    Zigzag_scan_8x8(blockCR, zigzag_array + 320);
}






