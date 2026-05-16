from PIL import Image
import os

def convert_bmp_to_hex(image_path, hex_path):
    if not os.path.exists(image_path):
        print(f"Error: Can't not find file {image_path}")
        return

    # Mở ảnh và convert sang chuẩn RGB
    img = Image.open(image_path).convert('RGB')
    width, height = img.size
    
    # Lấy toàn bộ dữ liệu pixel
    pixels = list(img.getdata())
    
    # Ghi ra file text dạng mã Hex (mỗi pixel 1 dòng)
    with open(hex_path, 'w') as f:
        for r, g, b in pixels:
            # Format: RRGGBB
            f.write(f"{r:02X}{g:02X}{b:02X}\n")
            
    print(f"[Successful] Output {width}x{height} = {len(pixels)} pixels")
    print(f"File output: {hex_path}")
convert_bmp_to_hex("sample1.bmp", "input_rgb.hex")