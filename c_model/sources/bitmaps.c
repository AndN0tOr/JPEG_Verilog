#include<stdio.h>
#include<stdlib.h>

#include "../headers/bitmaps.h"

rgb_image* read_bitmap(const char* file_name){
    bmp_fileheader fileheader;
    bmp_infoheader infoheader;
    rgb_image* image;
    FILE* file;

    file = fopen(file_name, "rb");
    if (file == NULL){
        printf("Error reading file '%s'", file_name);
        return NULL;
    }else {
        printf("Reading file '%s' successful", file_name);
    }

    // read fileheader
    fread(&fileheader, sizeof(fileheader), 1, file);

    if (fileheader.header_field != 19778){
        printf("\nError, provided file is not a bitmap file. Has magic identifier: 0x%x", fileheader.header_field);
        fclose(file);
        return NULL;
    }
    printf("\nMagic num: 0x%x", fileheader.header_field);
    printf("\nFilesize: %.2lfMB", fileheader.file_size / (double)1048576);
    printf("\nDataoffset (byte): %d", fileheader.data_offset);
    printf("\n");


    // read infoheader
    fread(&infoheader, sizeof(infoheader), 1, file);

    printf("\nInfoheader size: %d bytes", infoheader.infoheader_size);
    if (infoheader.infoheader_size < 40) {
        printf("\nError, infoheader has unsupported size: %dbytes", infoheader.infoheader_size);
        fclose(file);
        return NULL;
    }
    // Skip extra bytes if infoheader is larger than expected
    // if (infoheader.infoheader_size > 40) {
    //     fseek(file, infoheader.infoheader_size - 40, SEEK_CUR);
    // }
    
    printf("\nImage pixel resolution: %d x %d", infoheader.image_width, infoheader.image_height);

    if (infoheader.num_color_planes != 1) {
        printf("\nError, number of color planes not supported: %d", infoheader.num_color_planes);
        fclose(file);
        return NULL;
    }
    printf("\nColor depth (bits per pixel): %d", infoheader.bits_per_pixel);
    if (infoheader.bits_per_pixel != 24) {
        printf("\nError, color depth of %d is not supported, only 24 is supported", infoheader.bits_per_pixel);
        fclose(file);
        return NULL;
    }
    if (infoheader.compression_method != 0) {
        printf("\nError, compression method unsupported, header value: %d", infoheader.compression_method);
        fclose(file);
        return NULL;
    }
    /* Allocate memory for 2d array with image data */
    image = malloc(sizeof(rgb_image));
    if (image == NULL) {
        printf("Memory allocation failed");
        fclose(file);
        return NULL;
    }
    image->height = infoheader.image_height;
    image->width = infoheader.image_width;

    image->data = malloc(infoheader.image_width * sizeof(rgb_pixel*));

    if (image->data == NULL){
        printf("Memory allocation failed");
        free(image);
        fclose(file);
        return NULL;
    }
    for (int i = 0; i < infoheader.image_width; i++){
        image->data[i] = malloc(infoheader.image_height*sizeof(rgb_pixel));
        if (image ->data[i] == NULL){
            printf("Memory allocation failed.");
            // free all previously allocated memory.
            for (int k = 0; k < i; k++){
                free(image->data[k]);
            }
            free(image->data);
            free(image);
            return NULL;
        }
    }

    /* Skip to data*/
    fseek(file, fileheader.data_offset, SEEK_SET);

    uint8_t padding = (4 - (infoheader.image_width * 3 % 4)) % 4;

    printf("\nReading pixel data... padding=%d", padding);
    for (int i = infoheader.image_height - 1; i>= 0; i--){
        for (int j = 0; j < infoheader.image_width; j++){
            fread(&image ->data[j][i], 3, 1, file);
        }
        fseek(file, padding, SEEK_CUR);
    }
    /* printf("\npixel values rgb %d %d %d", image_data[1919][0].r, image_data[1919][0].g, image_data[1919][0].b); */

    fclose(file);
    printf("\nFile closed\n");
    return image;
}
void free_rgb_image(rgb_image* image){
    if (image == NULL){
        return;
    }
    for (int i = 0; i < image->width; i++){
        free(image->data[i]);
    }
    free(image->data);
    free(image);
    printf("Memory for this image is cleared.\n");
}
void test_read_bitmap(const char* file_name){
    rgb_image* image = read_bitmap(file_name);
    if (image == NULL){
        printf("Error reading bitmap file");
        return;
    }
    printf("\nImage dimensions: %d x %d\n", image->width, image->height);
    printf("%d\n", image -> data[388][388].r);
    printf("%d\n", image -> data[388][388].g);
    printf("%d\n", image -> data[388][388].b);
    free_rgb_image(image);
}


