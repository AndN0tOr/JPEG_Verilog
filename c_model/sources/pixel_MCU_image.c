#include "../headers/pixel_MCU_image.h"

void copy_block(ycbcr_image* image, int start_x, int start_y, ycbcr_pixel block[16][16]){
    for (int i = 0; i < 16; i++){
        for (int j = 0; j < 16; j++){
            int px = start_x + j;
            int py = start_y + i;
            
            if (px >= image->width)  px = image->width - 1;
            if (py >= image->height) py = image->height - 1;
            block[i][j] = image->data[px][py];
        }
    }
}


