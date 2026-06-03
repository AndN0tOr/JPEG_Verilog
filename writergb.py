from PIL import Image
import os

def convert_bmp_to_hex(image_path, hex_path):
    if not os.path.exists(image_path):
        print(f"Error: Can't find file {image_path}")
        return

    # Mở ảnh và convert sang chuẩn RGB
    img = Image.open(image_path).convert('RGB')
    width, height = img.size
    
    # Tính kích thước padding (bội số của 8)
    pad_w = ((width + 7) // 8) * 8
    pad_h = ((height + 7) // 8) * 8
    
    print(f"Original size: {width}x{height}")
    print(f"Padded size: {pad_w}x{pad_h}")
    
    # Tạo ảnh mới đã được pad bằng cách lặp lại pixel biên (edge repeat)
    padded_img = Image.new('RGB', (pad_w, pad_h))
    padded_img.paste(img, (0, 0))
    
    # Lặp các pixel ở biên phải
    for x in range(width, pad_w):
        for y in range(height):
            padded_img.putpixel((x, y), img.getpixel((width - 1, y)))
            
    # Lặp các pixel ở biên dưới
    for y in range(height, pad_h):
        for x in range(pad_w):
            padded_img.putpixel((x, y), padded_img.getpixel((x, height - 1)))
            
    # Ghi ra file hex dạng block 8x8 (quét từ trái qua phải, trên xuống dưới)
    pixels_written = 0
    with open(hex_path, 'w') as f:
        for block_y in range(0, pad_h, 8):
            for block_x in range(0, pad_w, 8):
                # Ghi 64 pixel trong block 8x8 này
                for y in range(8):
                    for x in range(8):
                        r, g, b = padded_img.getpixel((block_x + x, block_y + y))
                        f.write(f"{r:02X}{g:02X}{b:02X}\n")
                        pixels_written += 1
                        
    print(f"[Successful] Output {pixels_written} pixels in 8x8 block format")
    print(f"File output: {hex_path}")

convert_bmp_to_hex("sample1.bmp", "input_rgb.hex")