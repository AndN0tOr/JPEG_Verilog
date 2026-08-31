#include<stdio.h>

#include "../headers/Encoding.h"
#include "../headers/JPEG_steps.h"
#include "../headers/bitmaps.h"
#include "../headers/pixel_MCU_image.h"
#include "../headers/test.h"
#include "../headers/Huffman.h"
#include "../headers/JPEG_Encode.h"
#include "../headers/main.h"

int main(){
    
    Test_Performance("images/input/sample2.bmp");
    //Test_Encode_Block();
    //Test_Quantization_50();
    return 0;
}