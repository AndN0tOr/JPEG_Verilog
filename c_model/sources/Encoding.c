#include <stdio.h>
#include <stdlib.h>

#include "../headers/Encoding.h"

void Write_Huffman_bits(uint8_t symbol_byte, uint16_t value_bits, void* huffman_table){
    // This function will write the Huffman bits for the given size and value using the provided Huffman table.
    // It will look up the Huffman code for the size and then write the bits for the value.
    // ...
    huffman_code* table = (huffman_code*)huffman_table;
    int16_t huff_code = table[symbol_byte].code;
    uint8_t huff_length = table[symbol_byte].length;
    Put_bits(huff_code, huff_length); // Write the Huffman code
    uint8_t value_size = symbol_byte & 0x0F; // Size is in the lower 4 bits of symbol_byte
    if (value_size > 0){
        Put_bits(value_bits, value_size); // Write the value bits (size is in the lower 4 bits of symbol_byte)
    }
}

void Write_Physical_Bytes(uint8_t byte){
    // This function will write a single byte to the output (e.g., file or memory buffer).
    // It will handle any necessary buffering and ensure that bytes are written in the correct order.
    if (jpeg_file != NULL) {
        fputc(byte, jpeg_file); // Ghi 1 byte vào file
    }
}
uint32_t bit_buffer = 0;
uint8_t bit_count = 0;
void Flush_bits(){
    // This function will flush any remaining bits in the buffer to the output, padding with zeros if necessary.
    if (bit_count > 0){
        uint8_t padding_bits = 8 - bit_count; // Calculate how many padding bits are needed
        uint8_t filler = (1 << padding_bits) - 1; // Create a filler byte with the necessary padding bits
        Put_bits(filler, padding_bits); // Write the padding bits to the output

    }
    bit_buffer = 0; // Clear the buffer
    bit_count = 0; // Reset bit count
}
void Put_bits(uint32_t bits, uint8_t length){
    // This function will put the specified number of bits into the output buffer.
    // It will handle bit buffering and ensure that bits are written to the output in the correct order.
    // ...
    if (length == 0){
        return; // No bits to write
    }
    bit_buffer = (bit_buffer << length) | (bits & ((1 << length) - 1)); // Add new bits to buffer
    bit_count += length; // Update bit count

    while (bit_count >= 8){
        uint8_t byte_to_write = (bit_buffer >> (bit_count - 8)) & 0xFF; // Get the top 8 bits to write
        Write_Physical_Bytes(byte_to_write);
        if (byte_to_write == 0xFF){
            // If the byte is 0xFF, we need to write a zero byte after it to prevent marker confusion
            Write_Physical_Bytes(0x00);
        }
        bit_count -= 8; // Remove the written bits from the buffer
    }
}
void open_jpeg_file( char* filename) {
    printf("Writing JPEG file: %s\n", filename); // For demonstration, print the file being opened
    jpeg_file = fopen(filename, "wb");
    if (jpeg_file == NULL) {
        printf("Error opening file: %s\n", filename);
    }
}
void close_jpeg_file() {
    if (jpeg_file != NULL) {
        fclose(jpeg_file); // Đóng file sau khi ghi xong
        jpeg_file = NULL; // Đặt lại con trỏ file về NULL
    }
    printf("JPEG file written.\n"); // For demonstration, print that the file has been closed
}