# JPEG Verilog Encoder

## About the Project
This project is my personal project, implementing a JPEG encoder in Verilog.
The aim of this project is to get the project to run, pass all the test cases and use it for my course. I have added all the required documents and images to the repository.

## 1. Structure of Project

```text
├── data:
│   ├── hex: Stores hexadecimal data for testing
│   ├── input: Input image files (bmp format)
│   └── output: Output image files (jpeg format)
│
├── docs: (not completed)
│
├── scripts:
│   ├── repetitive_code.py: Python script to auto-generate repetitive code in the design.
│   ├── writergb.py: Python script to convert image files to hexadecimal data.
│   └── create_jpeg.py: Python script to convert bitstream to JPEG images.
├── rtl:
│   ├── lib:
│   │  ├── sync_fifo.v
│   │  ├── sync_fifo_32.v
│   │  └── sync_fifo_ff.v
│   └── jpeg_core:
│     ├── color_trans.v: Color transformation module.
│     ├── compute_1d_dct.v: 1D DCT computation module.
│     ├── dct_2d_1channel.v: 2D DCT computation module.
│     ├── luma_quantizer.v: Y channel quantization module.
│     ├── chroma_quantizer.v: CbCr channel quantization module.
│     ├── chroma_huff.v: CbCr channel Huffman coding module.
│     ├── luma_huff.v: Y channel Huffman coding module.
│     ├── luma_dqh.v: Y channel DC Huffman coding module.
│     ├── cb_dqh.v: Cb channel DC Huffman coding module.
│     ├── cr_dqh.v: Cr channel DC Huffman coding module.
│     ├── jpeg_process.v: Main JPEG processing module (includes byte stuffing).
│     ├── ff_check.v: FF check module.
│     └── jpeg_top.v: Top-level module for the JPEG encoder.
│
├── tb:
|    ├── color_trans_tb.v
|    ├── compute_1d_dct_tb.v
|    ├── dct_2d_1channel_tb.v
|    ├── luma_quantizer_tb.v
|    ├── chroma_quantizer_tb.v
|    ├── chroma_huff_tb.v
|    ├── luma_huff_tb.v
|    ├── luma_dqh_tb.v
|    ├── cb_dqh_tb.v
|    ├── cr_dqh_tb.v
|    ├── jpeg_process_tb.v
|    ├── ff_check_tb.v
|    ├── jpeg_top_tb.v
│
├── README.md: This file, providing an overview of the project structure.
└── Makefile: Build and simulation automation script for the project.
