# -*- coding: utf-8 -*-
import binascii
import os

def build_jpeg_header(width, height):
    """Tao bo JPEG Header chuan (4:4:4, Q=1)"""
    
    # 1. SOI (Start of Image) & APP0 (JFIF Header)
    header = b'\xFF\xD8'
    header += b'\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00'
    
    # 2. DQT (Bảng lượng tử hóa)
    # Luma (Y) - Mặc định theo Verilog của bạn là chia cho 1
    dqt_luma = b'\xFF\xDB\x00\x43\x00' + bytes([1] * 64)
    # Chroma (Cb/Cr) - Mặc định chia cho 1
    dqt_chroma = b'\xFF\xDB\x00\x43\x01' + bytes([1] * 64)
    header += dqt_luma + dqt_chroma
    
    # 3. SOF0 (Start of Frame) - Cấu hình ảnh Baseline
    # Format: FF C0 [Length 00 11] [Precision 08] [Height] [Width] [Components 03] ...
    sof = b'\xFF\xC0\x00\x11\x08'
    sof += height.to_bytes(2, 'big') + width.to_bytes(2, 'big')
    # Sampling factors: Y(ID:1, 1x1), Cb(ID:2, 1x1), Cr(ID:3, 1x1) -> Định dạng 4:4:4
    sof += b'\x03\x01\x11\x00\x02\x11\x01\x03\x11\x01'
    header += sof
    
    # 4. DHT (Bảng mã Huffman tiêu chuẩn JPEG)
    # Vì file chroma_huff.v và y_huff.v của bạn implement bảng chuẩn, ta dùng luôn mã chuẩn
    dht_marker = bytes.fromhex(
        "FFC401A2" # DHT Marker + Độ dài bảng
        "00" # Luma DC
        "00010501010101010100000000000000" "000102030405060708090A0B"
        "10" # Luma AC
        "0002010303020403050504040000017D" "01020300041105122131410613516107227114328191A1082342B1C11552D1F02433627282090A161718191A25262728292A3435363738393A434445464748494A535455565758595A636465666768696A737475767778797A838485868788898A92939495969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE1E2E3E4E5E6E7E8E9EAF1F2F3F4F5F6F7F8F9FA"
        "01" # Chroma DC
        "00030101010101010101010000000000" "000102030405060708090A0B"
        "11" # Chroma AC
        "00020102040403040705040400010277" "000102031104052131061241510761711322328108144291A1B1C109233352F0156272D10A162434E125F11718191A262728292A35363738393A434445464748494A535455565758595A636465666768696A737475767778797A82838485868788898A92939495969798999AA2A3A4A5A6A7A8A9AAB2B3B4B5B6B7B8B9BAC2C3C4C5C6C7C8C9CAD2D3D4D5D6D7D8D9DAE2E3E4E5E6E7E8E9EAF2F3F4F5F6F7F8F9FA"
    )
    header += dht_marker
    
    # 5. SOS (Start of Scan)
    # Format: FF DA [Length 00 0C] [Components 03] [Y 01 00] [Cb 02 11] [Cr 03 11] [Spectral & Approx 00 3F 00]
    sos = b'\xFF\xDA\x00\x0C\x03\x01\x00\x02\x11\x03\x11\x00\x3F\x00'
    header += sos
    
    return header

def byte_stuff_jpeg(data):
    """Them byte stuffing cho JPEG: Moi 0xFF phai theo sau boi 0x00"""
    result = bytearray()
    for byte in data:
        result.append(byte)
        if byte == 0xFF:
            result.append(0x00)
    return bytes(result)

def compile_jpeg(hex_file, output_jpg, width, height, endianness='big'):
    """Doc raw data tu Verilog, boc Header va xuat file anh"""
    if not os.path.exists(hex_file):
        print(f"Loi: Khong tim thay file {hex_file}")
        return

    raw_hex_str = ""
    with open(hex_file, 'r') as f:
        for line in f:
            cleaned = line.strip().replace("0x", "").replace(",", "")
            if "//" in cleaned: cleaned = cleaned.split("//")[0].strip()
            if not cleaned: continue

            if endianness == 'little' and len(cleaned) == 8:
                cleaned = cleaned[6:8] + cleaned[4:6] + cleaned[2:4] + cleaned[0:2]
            raw_hex_str += cleaned

    if len(raw_hex_str) % 2 != 0: raw_hex_str += "0"

    # Lấy Raw entropy data
    raw_data = binascii.unhexlify(raw_hex_str)

    # QUAN TRONG: Kiem tra xem Verilog da byte-stuff chua
    # Neu thay nhieu FF00 lien tiep thi da stuffed roi, khong can stuff lai
    # Neu khong thi can byte stuffing
    if raw_data.count(b'\xff\x00') < len(raw_data) // 20:
        # Chua byte-stuffed, can them
        raw_data = byte_stuff_jpeg(raw_data)
        print("[Info] Da them byte stuffing")
    else:
        print("[Info] Data da co byte stuffing tu Verilog")
    
    # Lay Header
    header = build_jpeg_header(width, height)

    # EOI Marker
    eoi = b'\xFF\xD9'

    # Gop toan bo
    final_jpeg = header + raw_data + eoi
    
    with open(output_jpg, 'wb') as out_f:
        out_f.write(final_jpeg)

    print(f"[Thanh cong] Da build xong file JPEG!")
    print(f" - Kich thuoc anh: {width}x{height}")
    print(f" - File output: {output_jpg}")

if __name__ == "__main__":
    # BAN CAN THAY DOI CHIEU RONG/CAO CUA ANH DUNG VOI FILE GOC (sample1.bmp)
    IMAGE_WIDTH = 640
    IMAGE_HEIGHT = 426

    # Thu voi big-endian (mac dinh)
    print("\n=== Thu voi big-endian ===")
    compile_jpeg("output_bitstream.hex", "output_big.jpg", IMAGE_WIDTH, IMAGE_HEIGHT, endianness='big')

    # Thu voi little-endian
    print("\n=== Thu voi little-endian ===")
    compile_jpeg("output_bitstream.hex", "output_little.jpg", IMAGE_WIDTH, IMAGE_HEIGHT, endianness='little')