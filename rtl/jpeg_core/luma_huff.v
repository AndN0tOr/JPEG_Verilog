module luma_huff(
    input clk, 
    input rst, 
    input enable,
    // Ngõ vào khối 8x8 kênh Y - ĐÃ CHUYỂN SANG 12 BIT
    input [11:0] Y11, Y12, Y13, Y14, Y15, Y16, Y17, Y18, 
    input [11:0] Y21, Y22, Y23, Y24, Y25, Y26, Y27, Y28,
    input [11:0] Y31, Y32, Y33, Y34, Y35, Y36, Y37, Y38, 
    input [11:0] Y41, Y42, Y43, Y44, Y45, Y46, Y47, Y48,
    input [11:0] Y51, Y52, Y53, Y54, Y55, Y56, Y57, Y58, 
    input [11:0] Y61, Y62, Y63, Y64, Y65, Y66, Y67, Y68,
    input [11:0] Y71, Y72, Y73, Y74, Y75, Y76, Y77, Y78, 
    input [11:0] Y81, Y82, Y83, Y84, Y85, Y86, Y87, Y88,
    
    // Output GIỮ NGUYÊN
    output reg [31:0] JPEG_bitstream, 
    output reg data_ready, 
    output reg [5:0]  output_reg_count, 
    output reg end_of_block_output,
    output reg end_of_block_empty,
    output reg is_last_chunk
);

    // -------------------------------------------------------------------------
    // 1. ZIG-ZAG MAPPING BẰNG MẢNG (ARRAY) ĐÃ ĐƯỢC CHUYỂN LÊN 12-BIT
    // -------------------------------------------------------------------------
    wire [11:0] zz [0:63];

    assign zz[0]=Y11;  assign zz[1]=Y12;  assign zz[2]=Y21;  assign zz[3]=Y31;
    assign zz[4]=Y22;  assign zz[5]=Y13;  assign zz[6]=Y14;  assign zz[7]=Y23;
    assign zz[8]=Y32;  assign zz[9]=Y41;  assign zz[10]=Y51; assign zz[11]=Y42;
    assign zz[12]=Y33; assign zz[13]=Y24; assign zz[14]=Y15; assign zz[15]=Y16;
    assign zz[16]=Y25; assign zz[17]=Y34; assign zz[18]=Y43; assign zz[19]=Y52;
    assign zz[20]=Y61; assign zz[21]=Y71; assign zz[22]=Y62; assign zz[23]=Y53;
    assign zz[24]=Y44; assign zz[25]=Y35; assign zz[26]=Y26; assign zz[27]=Y17;
    assign zz[28]=Y18; assign zz[29]=Y27; assign zz[30]=Y36; assign zz[31]=Y45;
    assign zz[32]=Y54; assign zz[33]=Y63; assign zz[34]=Y72; assign zz[35]=Y81;
    assign zz[36]=Y82; assign zz[37]=Y73; assign zz[38]=Y64; assign zz[39]=Y55;
    assign zz[40]=Y46; assign zz[41]=Y37; assign zz[42]=Y28; assign zz[43]=Y38;
    assign zz[44]=Y47; assign zz[45]=Y56; assign zz[46]=Y65; assign zz[47]=Y74;
    assign zz[48]=Y83; assign zz[49]=Y84; assign zz[50]=Y75; assign zz[51]=Y66;
    assign zz[52]=Y57; assign zz[53]=Y48; assign zz[54]=Y58; assign zz[55]=Y67;
    assign zz[56]=Y76; assign zz[57]=Y85; assign zz[58]=Y86; assign zz[59]=Y77;
    assign zz[60]=Y68; assign zz[61]=Y78; assign zz[62]=Y87; assign zz[63]=Y88;

    // Tìm index cuối cùng khác 0 để chèn End Of Block (EOB) sớm
    // Tính từ zz_buf thay vì zz để đảm bảo đồng bộ với data đang xử lý
    reg [5:0] last_nz_idx;
    reg [7:0] run_size_idx;
    integer i;

    // -------------------------------------------------------------------------
    // 2. ROM BẢNG HUFFMAN (Khởi tạo bằng initial cho gọn)
    // -------------------------------------------------------------------------
    reg [10:0] Y_DC [0:11];
    reg [3:0]  Y_DC_code_length [0:11];
    reg [15:0] Y_AC [0:161];
    reg [4:0]  Y_AC_code_length [0:161];
    reg [7:0]  Y_AC_run_code [0:255]; // Dùng 256 cho an toàn index

    initial begin
        // DC Codes - JPEG Standard Luminance DC Huffman Table (Canonical)
        // BITS = [0,1,5,1,1,1,1,1,1,0,0,0,0,0,0,0]
        // Code lengths: cat 0=2, cat 1-5=3, cat 6=4, cat 7=5, ... cat 11=9
        Y_DC[0]=11'b00;          Y_DC_code_length[0]=2;   // 00
        Y_DC[1]=11'b010;         Y_DC_code_length[1]=3;   // 010
        Y_DC[2]=11'b011;         Y_DC_code_length[2]=3;   // 011
        Y_DC[3]=11'b100;         Y_DC_code_length[3]=3;   // 100
        Y_DC[4]=11'b101;         Y_DC_code_length[4]=3;   // 101
        Y_DC[5]=11'b110;         Y_DC_code_length[5]=3;   // 110
        Y_DC[6]=11'b1110;        Y_DC_code_length[6]=4;   // 1110
        Y_DC[7]=11'b11110;       Y_DC_code_length[7]=5;   // 11110
        Y_DC[8]=11'b111110;      Y_DC_code_length[8]=6;   // 111110
        Y_DC[9]=11'b1111110;     Y_DC_code_length[9]=7;   // 1111110
        Y_DC[10]=11'b11111110;   Y_DC_code_length[10]=8;  // 11111110
        Y_DC[11]=11'b111111110;  Y_DC_code_length[11]=9;  // 111111110

        // AC Codes - JPEG Standard Luminance AC Huffman Table (Canonical)
        // Generated from BITS=[0,2,1,3,3,2,4,3,5,5,4,4,0,0,1,125]
        Y_AC[0] = 16'h0000; Y_AC_code_length[0] = 2;  Y_AC_run_code[8'h01] = 0;   // (0,1)
        Y_AC[1] = 16'h0001; Y_AC_code_length[1] = 2;  Y_AC_run_code[8'h02] = 1;   // (0,2)
        Y_AC[2] = 16'h0004; Y_AC_code_length[2] = 3;  Y_AC_run_code[8'h03] = 2;   // (0,3)
        Y_AC[3] = 16'h000A; Y_AC_code_length[3] = 4;  Y_AC_run_code[8'h00] = 3;   // (0,0) EOB
        Y_AC[4] = 16'h000B; Y_AC_code_length[4] = 4;  Y_AC_run_code[8'h04] = 4;   // (0,4)
        Y_AC[5] = 16'h000C; Y_AC_code_length[5] = 4;  Y_AC_run_code[8'h11] = 5;   // (1,1)
        Y_AC[6] = 16'h001A; Y_AC_code_length[6] = 5;  Y_AC_run_code[8'h05] = 6;   // (0,5)
        Y_AC[7] = 16'h001B; Y_AC_code_length[7] = 5;  Y_AC_run_code[8'h12] = 7;   // (1,2)
        Y_AC[8] = 16'h001C; Y_AC_code_length[8] = 5;  Y_AC_run_code[8'h21] = 8;   // (2,1)
        Y_AC[9] = 16'h003A; Y_AC_code_length[9] = 6;  Y_AC_run_code[8'h31] = 9;   // (3,1)
        Y_AC[10] = 16'h003B; Y_AC_code_length[10] = 6;  Y_AC_run_code[8'h41] = 10;  // (4,1)
        Y_AC[11] = 16'h0078; Y_AC_code_length[11] = 7;  Y_AC_run_code[8'h06] = 11;  // (0,6)
        Y_AC[12] = 16'h0079; Y_AC_code_length[12] = 7;  Y_AC_run_code[8'h13] = 12;  // (1,3)
        Y_AC[13] = 16'h007A; Y_AC_code_length[13] = 7;  Y_AC_run_code[8'h51] = 13;  // (5,1)
        Y_AC[14] = 16'h007B; Y_AC_code_length[14] = 7;  Y_AC_run_code[8'h61] = 14;  // (6,1)
        Y_AC[15] = 16'h00F8; Y_AC_code_length[15] = 8;  Y_AC_run_code[8'h07] = 15;  // (0,7)
        Y_AC[16] = 16'h00F9; Y_AC_code_length[16] = 8;  Y_AC_run_code[8'h22] = 16;  // (2,2)
        Y_AC[17] = 16'h00FA; Y_AC_code_length[17] = 8;  Y_AC_run_code[8'h71] = 17;  // (7,1)
        Y_AC[18] = 16'h01F6; Y_AC_code_length[18] = 9;  Y_AC_run_code[8'h14] = 18;  // (1,4)
        Y_AC[19] = 16'h01F7; Y_AC_code_length[19] = 9;  Y_AC_run_code[8'h32] = 19;  // (3,2)
        Y_AC[20] = 16'h01F8; Y_AC_code_length[20] = 9;  Y_AC_run_code[8'h81] = 20;  // (8,1)
        Y_AC[21] = 16'h01F9; Y_AC_code_length[21] = 9;  Y_AC_run_code[8'h91] = 21;  // (9,1)
        Y_AC[22] = 16'h01FA; Y_AC_code_length[22] = 9;  Y_AC_run_code[8'hA1] = 22;  // (10,1)
        Y_AC[23] = 16'h03F6; Y_AC_code_length[23] = 10; Y_AC_run_code[8'h08] = 23;  // (0,8)
        Y_AC[24] = 16'h03F7; Y_AC_code_length[24] = 10; Y_AC_run_code[8'h23] = 24;  // (2,3)
        Y_AC[25] = 16'h03F8; Y_AC_code_length[25] = 10; Y_AC_run_code[8'h42] = 25;  // (4,2)
        Y_AC[26] = 16'h03F9; Y_AC_code_length[26] = 10; Y_AC_run_code[8'hB1] = 26;  // (11,1)
        Y_AC[27] = 16'h03FA; Y_AC_code_length[27] = 10; Y_AC_run_code[8'hC1] = 27;  // (12,1)
        Y_AC[28] = 16'h07F6; Y_AC_code_length[28] = 11; Y_AC_run_code[8'h15] = 28;  // (1,5)
        Y_AC[29] = 16'h07F7; Y_AC_code_length[29] = 11; Y_AC_run_code[8'h52] = 29;  // (5,2)
        Y_AC[30] = 16'h07F8; Y_AC_code_length[30] = 11; Y_AC_run_code[8'hD1] = 30;  // (13,1)
        Y_AC[31] = 16'h07F9; Y_AC_code_length[31] = 11; Y_AC_run_code[8'hF0] = 31;  // (15,0) ZRL
        Y_AC[32] = 16'h0FF4; Y_AC_code_length[32] = 12; Y_AC_run_code[8'h24] = 32;  // (2,4)
        Y_AC[33] = 16'h0FF5; Y_AC_code_length[33] = 12; Y_AC_run_code[8'h33] = 33;  // (3,3)
        Y_AC[34] = 16'h0FF6; Y_AC_code_length[34] = 12; Y_AC_run_code[8'h62] = 34;  // (6,2)
        Y_AC[35] = 16'h0FF7; Y_AC_code_length[35] = 12; Y_AC_run_code[8'h72] = 35;  // (7,2)
        Y_AC[36] = 16'h7FC0; Y_AC_code_length[36] = 15; Y_AC_run_code[8'h82] = 36;  // (8,2)
        Y_AC[37] = 16'hFF82; Y_AC_code_length[37] = 16; Y_AC_run_code[8'h09] = 37;  // (0,9)
        Y_AC[38] = 16'hFF83; Y_AC_code_length[38] = 16; Y_AC_run_code[8'h0A] = 38;  // (0,10)
        Y_AC[39] = 16'hFF84; Y_AC_code_length[39] = 16; Y_AC_run_code[8'h16] = 39;  // (1,6)
        Y_AC[40] = 16'hFF85; Y_AC_code_length[40] = 16; Y_AC_run_code[8'h17] = 40;  // (1,7)
        Y_AC[41] = 16'hFF86; Y_AC_code_length[41] = 16; Y_AC_run_code[8'h18] = 41;  // (1,8)
        Y_AC[42] = 16'hFF87; Y_AC_code_length[42] = 16; Y_AC_run_code[8'h19] = 42;  // (1,9)
        Y_AC[43] = 16'hFF88; Y_AC_code_length[43] = 16; Y_AC_run_code[8'h1A] = 43;  // (1,10)
        Y_AC[44] = 16'hFF89; Y_AC_code_length[44] = 16; Y_AC_run_code[8'h25] = 44;  // (2,5)
        Y_AC[45] = 16'hFF8A; Y_AC_code_length[45] = 16; Y_AC_run_code[8'h26] = 45;  // (2,6)
        Y_AC[46] = 16'hFF8B; Y_AC_code_length[46] = 16; Y_AC_run_code[8'h27] = 46;  // (2,7)
        Y_AC[47] = 16'hFF8C; Y_AC_code_length[47] = 16; Y_AC_run_code[8'h28] = 47;  // (2,8)
        Y_AC[48] = 16'hFF8D; Y_AC_code_length[48] = 16; Y_AC_run_code[8'h29] = 48;  // (2,9)
        Y_AC[49] = 16'hFF8E; Y_AC_code_length[49] = 16; Y_AC_run_code[8'h2A] = 49;  // (2,10)
        Y_AC[50] = 16'hFF8F; Y_AC_code_length[50] = 16; Y_AC_run_code[8'h34] = 50;  // (3,4)
        Y_AC[51] = 16'hFF90; Y_AC_code_length[51] = 16; Y_AC_run_code[8'h35] = 51;  // (3,5)
        Y_AC[52] = 16'hFF91; Y_AC_code_length[52] = 16; Y_AC_run_code[8'h36] = 52;  // (3,6)
        Y_AC[53] = 16'hFF92; Y_AC_code_length[53] = 16; Y_AC_run_code[8'h37] = 53;  // (3,7)
        Y_AC[54] = 16'hFF93; Y_AC_code_length[54] = 16; Y_AC_run_code[8'h38] = 54;  // (3,8)
        Y_AC[55] = 16'hFF94; Y_AC_code_length[55] = 16; Y_AC_run_code[8'h39] = 55;  // (3,9)
        Y_AC[56] = 16'hFF95; Y_AC_code_length[56] = 16; Y_AC_run_code[8'h3A] = 56;  // (3,10)
        Y_AC[57] = 16'hFF96; Y_AC_code_length[57] = 16; Y_AC_run_code[8'h43] = 57;  // (4,3)
        Y_AC[58] = 16'hFF97; Y_AC_code_length[58] = 16; Y_AC_run_code[8'h44] = 58;  // (4,4)
        Y_AC[59] = 16'hFF98; Y_AC_code_length[59] = 16; Y_AC_run_code[8'h45] = 59;  // (4,5)
        Y_AC[60] = 16'hFF99; Y_AC_code_length[60] = 16; Y_AC_run_code[8'h46] = 60;  // (4,6)
        Y_AC[61] = 16'hFF9A; Y_AC_code_length[61] = 16; Y_AC_run_code[8'h47] = 61;  // (4,7)
        Y_AC[62] = 16'hFF9B; Y_AC_code_length[62] = 16; Y_AC_run_code[8'h48] = 62;  // (4,8)
        Y_AC[63] = 16'hFF9C; Y_AC_code_length[63] = 16; Y_AC_run_code[8'h49] = 63;  // (4,9)
        Y_AC[64] = 16'hFF9D; Y_AC_code_length[64] = 16; Y_AC_run_code[8'h4A] = 64;  // (4,10)
        Y_AC[65] = 16'hFF9E; Y_AC_code_length[65] = 16; Y_AC_run_code[8'h53] = 65;  // (5,3)
        Y_AC[66] = 16'hFF9F; Y_AC_code_length[66] = 16; Y_AC_run_code[8'h54] = 66;  // (5,4)
        Y_AC[67] = 16'hFFA0; Y_AC_code_length[67] = 16; Y_AC_run_code[8'h55] = 67;  // (5,5)
        Y_AC[68] = 16'hFFA1; Y_AC_code_length[68] = 16; Y_AC_run_code[8'h56] = 68;  // (5,6)
        Y_AC[69] = 16'hFFA2; Y_AC_code_length[69] = 16; Y_AC_run_code[8'h57] = 69;  // (5,7)
        Y_AC[70] = 16'hFFA3; Y_AC_code_length[70] = 16; Y_AC_run_code[8'h58] = 70;  // (5,8)
        Y_AC[71] = 16'hFFA4; Y_AC_code_length[71] = 16; Y_AC_run_code[8'h59] = 71;  // (5,9)
        Y_AC[72] = 16'hFFA5; Y_AC_code_length[72] = 16; Y_AC_run_code[8'h5A] = 72;  // (5,10)
        Y_AC[73] = 16'hFFA6; Y_AC_code_length[73] = 16; Y_AC_run_code[8'h63] = 73;  // (6,3)
        Y_AC[74] = 16'hFFA7; Y_AC_code_length[74] = 16; Y_AC_run_code[8'h64] = 74;  // (6,4)
        Y_AC[75] = 16'hFFA8; Y_AC_code_length[75] = 16; Y_AC_run_code[8'h65] = 75;  // (6,5)
        Y_AC[76] = 16'hFFA9; Y_AC_code_length[76] = 16; Y_AC_run_code[8'h66] = 76;  // (6,6)
        Y_AC[77] = 16'hFFAA; Y_AC_code_length[77] = 16; Y_AC_run_code[8'h67] = 77;  // (6,7)
        Y_AC[78] = 16'hFFAB; Y_AC_code_length[78] = 16; Y_AC_run_code[8'h68] = 78;  // (6,8)
        Y_AC[79] = 16'hFFAC; Y_AC_code_length[79] = 16; Y_AC_run_code[8'h69] = 79;  // (6,9)
        Y_AC[80] = 16'hFFAD; Y_AC_code_length[80] = 16; Y_AC_run_code[8'h6A] = 80;  // (6,10)
        Y_AC[81] = 16'hFFAE; Y_AC_code_length[81] = 16; Y_AC_run_code[8'h73] = 81;  // (7,3)
        Y_AC[82] = 16'hFFAF; Y_AC_code_length[82] = 16; Y_AC_run_code[8'h74] = 82;  // (7,4)
        Y_AC[83] = 16'hFFB0; Y_AC_code_length[83] = 16; Y_AC_run_code[8'h75] = 83;  // (7,5)
        Y_AC[84] = 16'hFFB1; Y_AC_code_length[84] = 16; Y_AC_run_code[8'h76] = 84;  // (7,6)
        Y_AC[85] = 16'hFFB2; Y_AC_code_length[85] = 16; Y_AC_run_code[8'h77] = 85;  // (7,7)
        Y_AC[86] = 16'hFFB3; Y_AC_code_length[86] = 16; Y_AC_run_code[8'h78] = 86;  // (7,8)
        Y_AC[87] = 16'hFFB4; Y_AC_code_length[87] = 16; Y_AC_run_code[8'h79] = 87;  // (7,9)
        Y_AC[88] = 16'hFFB5; Y_AC_code_length[88] = 16; Y_AC_run_code[8'h7A] = 88;  // (7,10)
        Y_AC[89] = 16'hFFB6; Y_AC_code_length[89] = 16; Y_AC_run_code[8'h83] = 89;  // (8,3)
        Y_AC[90] = 16'hFFB7; Y_AC_code_length[90] = 16; Y_AC_run_code[8'h84] = 90;  // (8,4)
        Y_AC[91] = 16'hFFB8; Y_AC_code_length[91] = 16; Y_AC_run_code[8'h85] = 91;  // (8,5)
        Y_AC[92] = 16'hFFB9; Y_AC_code_length[92] = 16; Y_AC_run_code[8'h86] = 92;  // (8,6)
        Y_AC[93] = 16'hFFBA; Y_AC_code_length[93] = 16; Y_AC_run_code[8'h87] = 93;  // (8,7)
        Y_AC[94] = 16'hFFBB; Y_AC_code_length[94] = 16; Y_AC_run_code[8'h88] = 94;  // (8,8)
        Y_AC[95] = 16'hFFBC; Y_AC_code_length[95] = 16; Y_AC_run_code[8'h89] = 95;  // (8,9)
        Y_AC[96] = 16'hFFBD; Y_AC_code_length[96] = 16; Y_AC_run_code[8'h8A] = 96;  // (8,10)
        Y_AC[97] = 16'hFFBE; Y_AC_code_length[97] = 16; Y_AC_run_code[8'h92] = 97;  // (9,2)
        Y_AC[98] = 16'hFFBF; Y_AC_code_length[98] = 16; Y_AC_run_code[8'h93] = 98;  // (9,3)
        Y_AC[99] = 16'hFFC0; Y_AC_code_length[99] = 16; Y_AC_run_code[8'h94] = 99;  // (9,4)
        Y_AC[100] = 16'hFFC1; Y_AC_code_length[100] = 16; Y_AC_run_code[8'h95] = 100; // (9,5)
        Y_AC[101] = 16'hFFC2; Y_AC_code_length[101] = 16; Y_AC_run_code[8'h96] = 101; // (9,6)
        Y_AC[102] = 16'hFFC3; Y_AC_code_length[102] = 16; Y_AC_run_code[8'h97] = 102; // (9,7)
        Y_AC[103] = 16'hFFC4; Y_AC_code_length[103] = 16; Y_AC_run_code[8'h98] = 103; // (9,8)
        Y_AC[104] = 16'hFFC5; Y_AC_code_length[104] = 16; Y_AC_run_code[8'h99] = 104; // (9,9)
        Y_AC[105] = 16'hFFC6; Y_AC_code_length[105] = 16; Y_AC_run_code[8'h9A] = 105; // (9,10)
        Y_AC[106] = 16'hFFC7; Y_AC_code_length[106] = 16; Y_AC_run_code[8'hA2] = 106; // (10,2)
        Y_AC[107] = 16'hFFC8; Y_AC_code_length[107] = 16; Y_AC_run_code[8'hA3] = 107; // (10,3)
        Y_AC[108] = 16'hFFC9; Y_AC_code_length[108] = 16; Y_AC_run_code[8'hA4] = 108; // (10,4)
        Y_AC[109] = 16'hFFCA; Y_AC_code_length[109] = 16; Y_AC_run_code[8'hA5] = 109; // (10,5)
        Y_AC[110] = 16'hFFCB; Y_AC_code_length[110] = 16; Y_AC_run_code[8'hA6] = 110; // (10,6)
        Y_AC[111] = 16'hFFCC; Y_AC_code_length[111] = 16; Y_AC_run_code[8'hA7] = 111; // (10,7)
        Y_AC[112] = 16'hFFCD; Y_AC_code_length[112] = 16; Y_AC_run_code[8'hA8] = 112; // (10,8)
        Y_AC[113] = 16'hFFCE; Y_AC_code_length[113] = 16; Y_AC_run_code[8'hA9] = 113; // (10,9)
        Y_AC[114] = 16'hFFCF; Y_AC_code_length[114] = 16; Y_AC_run_code[8'hAA] = 114; // (10,10)
        Y_AC[115] = 16'hFFD0; Y_AC_code_length[115] = 16; Y_AC_run_code[8'hB2] = 115; // (11,2)
        Y_AC[116] = 16'hFFD1; Y_AC_code_length[116] = 16; Y_AC_run_code[8'hB3] = 116; // (11,3)
        Y_AC[117] = 16'hFFD2; Y_AC_code_length[117] = 16; Y_AC_run_code[8'hB4] = 117; // (11,4)
        Y_AC[118] = 16'hFFD3; Y_AC_code_length[118] = 16; Y_AC_run_code[8'hB5] = 118; // (11,5)
        Y_AC[119] = 16'hFFD4; Y_AC_code_length[119] = 16; Y_AC_run_code[8'hB6] = 119; // (11,6)
        Y_AC[120] = 16'hFFD5; Y_AC_code_length[120] = 16; Y_AC_run_code[8'hB7] = 120; // (11,7)
        Y_AC[121] = 16'hFFD6; Y_AC_code_length[121] = 16; Y_AC_run_code[8'hB8] = 121; // (11,8)
        Y_AC[122] = 16'hFFD7; Y_AC_code_length[122] = 16; Y_AC_run_code[8'hB9] = 122; // (11,9)
        Y_AC[123] = 16'hFFD8; Y_AC_code_length[123] = 16; Y_AC_run_code[8'hBA] = 123; // (11,10)
        Y_AC[124] = 16'hFFD9; Y_AC_code_length[124] = 16; Y_AC_run_code[8'hC2] = 124; // (12,2)
        Y_AC[125] = 16'hFFDA; Y_AC_code_length[125] = 16; Y_AC_run_code[8'hC3] = 125; // (12,3)
        Y_AC[126] = 16'hFFDB; Y_AC_code_length[126] = 16; Y_AC_run_code[8'hC4] = 126; // (12,4)
        Y_AC[127] = 16'hFFDC; Y_AC_code_length[127] = 16; Y_AC_run_code[8'hC5] = 127; // (12,5)
        Y_AC[128] = 16'hFFDD; Y_AC_code_length[128] = 16; Y_AC_run_code[8'hC6] = 128; // (12,6)
        Y_AC[129] = 16'hFFDE; Y_AC_code_length[129] = 16; Y_AC_run_code[8'hC7] = 129; // (12,7)
        Y_AC[130] = 16'hFFDF; Y_AC_code_length[130] = 16; Y_AC_run_code[8'hC8] = 130; // (12,8)
        Y_AC[131] = 16'hFFE0; Y_AC_code_length[131] = 16; Y_AC_run_code[8'hC9] = 131; // (12,9)
        Y_AC[132] = 16'hFFE1; Y_AC_code_length[132] = 16; Y_AC_run_code[8'hCA] = 132; // (12,10)
        Y_AC[133] = 16'hFFE2; Y_AC_code_length[133] = 16; Y_AC_run_code[8'hD2] = 133; // (13,2)
        Y_AC[134] = 16'hFFE3; Y_AC_code_length[134] = 16; Y_AC_run_code[8'hD3] = 134; // (13,3)
        Y_AC[135] = 16'hFFE4; Y_AC_code_length[135] = 16; Y_AC_run_code[8'hD4] = 135; // (13,4)
        Y_AC[136] = 16'hFFE5; Y_AC_code_length[136] = 16; Y_AC_run_code[8'hD5] = 136; // (13,5)
        Y_AC[137] = 16'hFFE6; Y_AC_code_length[137] = 16; Y_AC_run_code[8'hD6] = 137; // (13,6)
        Y_AC[138] = 16'hFFE7; Y_AC_code_length[138] = 16; Y_AC_run_code[8'hD7] = 138; // (13,7)
        Y_AC[139] = 16'hFFE8; Y_AC_code_length[139] = 16; Y_AC_run_code[8'hD8] = 139; // (13,8)
        Y_AC[140] = 16'hFFE9; Y_AC_code_length[140] = 16; Y_AC_run_code[8'hD9] = 140; // (13,9)
        Y_AC[141] = 16'hFFEA; Y_AC_code_length[141] = 16; Y_AC_run_code[8'hDA] = 141; // (13,10)
        Y_AC[142] = 16'hFFEB; Y_AC_code_length[142] = 16; Y_AC_run_code[8'hE1] = 142; // (14,1)
        Y_AC[143] = 16'hFFEC; Y_AC_code_length[143] = 16; Y_AC_run_code[8'hE2] = 143; // (14,2)
        Y_AC[144] = 16'hFFED; Y_AC_code_length[144] = 16; Y_AC_run_code[8'hE3] = 144; // (14,3)
        Y_AC[145] = 16'hFFEE; Y_AC_code_length[145] = 16; Y_AC_run_code[8'hE4] = 145; // (14,4)
        Y_AC[146] = 16'hFFEF; Y_AC_code_length[146] = 16; Y_AC_run_code[8'hE5] = 146; // (14,5)
        Y_AC[147] = 16'hFFF0; Y_AC_code_length[147] = 16; Y_AC_run_code[8'hE6] = 147; // (14,6)
        Y_AC[148] = 16'hFFF1; Y_AC_code_length[148] = 16; Y_AC_run_code[8'hE7] = 148; // (14,7)
        Y_AC[149] = 16'hFFF2; Y_AC_code_length[149] = 16; Y_AC_run_code[8'hE8] = 149; // (14,8)
        Y_AC[150] = 16'hFFF3; Y_AC_code_length[150] = 16; Y_AC_run_code[8'hE9] = 150; // (14,9)
        Y_AC[151] = 16'hFFF4; Y_AC_code_length[151] = 16; Y_AC_run_code[8'hEA] = 151; // (14,10)
        Y_AC[152] = 16'hFFF5; Y_AC_code_length[152] = 16; Y_AC_run_code[8'hF1] = 152; // (15,1)
        Y_AC[153] = 16'hFFF6; Y_AC_code_length[153] = 16; Y_AC_run_code[8'hF2] = 153; // (15,2)
        Y_AC[154] = 16'hFFF7; Y_AC_code_length[154] = 16; Y_AC_run_code[8'hF3] = 154; // (15,3)
        Y_AC[155] = 16'hFFF8; Y_AC_code_length[155] = 16; Y_AC_run_code[8'hF4] = 155; // (15,4)
        Y_AC[156] = 16'hFFF9; Y_AC_code_length[156] = 16; Y_AC_run_code[8'hF5] = 156; // (15,5)
        Y_AC[157] = 16'hFFFA; Y_AC_code_length[157] = 16; Y_AC_run_code[8'hF6] = 157; // (15,6)
        Y_AC[158] = 16'hFFFB; Y_AC_code_length[158] = 16; Y_AC_run_code[8'hF7] = 158; // (15,7)
        Y_AC[159] = 16'hFFFC; Y_AC_code_length[159] = 16; Y_AC_run_code[8'hF8] = 159; // (15,8)
        Y_AC[160] = 16'hFFFD; Y_AC_code_length[160] = 16; Y_AC_run_code[8'hF9] = 160; // (15,9)
        Y_AC[161] = 16'hFFFE; Y_AC_code_length[161] = 16; Y_AC_run_code[8'hFA] = 161; // (15,10)
    end

    // -------------------------------------------------------------------------
    // 3. HÀM TÍNH TOÁN BIT LENGTH & BIÊN ĐỘ
    // -------------------------------------------------------------------------
    function [3:0] calc_vli_size;
        input [11:0] val;
        reg [11:0] abs_val;
        begin
            abs_val = val[11] ? (~val + 1'b1) : val; // Trị tuyệt đối
            if (abs_val[10])      calc_vli_size = 11;
            else if (abs_val[9])  calc_vli_size = 10;
            else if (abs_val[8])  calc_vli_size = 9;
            else if (abs_val[7])  calc_vli_size = 8;
            else if (abs_val[6])  calc_vli_size = 7;
            else if (abs_val[5])  calc_vli_size = 6;
            else if (abs_val[4])  calc_vli_size = 5;
            else if (abs_val[3])  calc_vli_size = 4;
            else if (abs_val[2])  calc_vli_size = 3;
            else if (abs_val[1])  calc_vli_size = 2;
            else if (abs_val[0])  calc_vli_size = 1;
            else                  calc_vli_size = 0;
        end
    endfunction

    function [10:0] calc_vli_amp;
        input [11:0] val;
        begin
            // Theo chuẩn JPEG: Nếu âm thì Amplitude = Giá trị - 1
            calc_vli_amp = val[11] ? (val - 1'b1) : val; 
        end
    endfunction

    // -------------------------------------------------------------------------
    // 4. QUẢN LÝ TRẠNG THÁI (STATE MACHINE)
    // -------------------------------------------------------------------------
    reg [6:0] count;
    reg [3:0] zrl;
    reg signed [11:0] dc_prev;
    reg active;

    // Edge detection for enable signal
    reg enable_prev;
    wire enable_posedge = enable && !enable_prev;

    always @(posedge clk) begin
        if (rst)
            enable_prev <= 0;
        else
            enable_prev <= enable;
    end

    // FIFO to buffer incoming blocks (depth = 512 for better throughput)
    reg [11:0] fifo_mem [0:511][0:63]; // 512 blocks, each 64 coefficients
    reg [9:0] fifo_wr_ptr;
    reg [9:0] fifo_rd_ptr;
    wire [9:0] fifo_count = fifo_wr_ptr - fifo_rd_ptr;
    wire fifo_empty = (fifo_count == 0);
    wire fifo_full = (fifo_count > 509);

    integer j;

    // Write to FIFO when enable posedge detected
    always @(posedge clk) begin
        if (rst) begin
            fifo_wr_ptr <= 0;
        end
        else if (enable_posedge && !fifo_full) begin
            for (j = 0; j < 64; j = j + 1) begin
                fifo_mem[fifo_wr_ptr[8:0]][j] <= zz[j];
            end
            fifo_wr_ptr <= fifo_wr_ptr + 1;
        end
    end

    // Buffer to hold current block being processed
    reg [11:0] zz_buf [0:63];

    // Các biến dùng cho Bitstream Packer
    reg [27:0] push_data;
    reg [4:0]  push_len;
    reg push_valid;
    reg eob_trigger;

    // Read from buffered data instead of direct input
    wire signed [11:0] curr_val = $signed(zz_buf[count]);
    wire signed [11:0] diff_val = curr_val - dc_prev;

    reg [5:0] next_last_nz;
    always @(*) begin
        next_last_nz = 0;
        for (i = 1; i < 64; i = i + 1) begin
            if (fifo_mem[fifo_rd_ptr[8:0]][i] != 0)
                next_last_nz = i;
        end
    end

    // Process blocks from FIFO
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            active <= 0;
            zrl <= 0;
            dc_prev <= 0;
            push_valid <= 0;
            eob_trigger <= 0;
            end_of_block_empty <= 0;
            fifo_rd_ptr <= 0;
        end
        else if (!active && !fifo_empty) begin
            // Start processing next block from FIFO
            for (j = 0; j < 64; j = j + 1) begin
                zz_buf[j] <= fifo_mem[fifo_rd_ptr[8:0]][j];
            end
            fifo_rd_ptr <= fifo_rd_ptr + 1;

            // Calculate last_nz_idx from the block being loaded
            last_nz_idx <= next_last_nz;

            count <= 0;
            active <= 1;
            zrl <= 0;
            push_valid <= 0;
            eob_trigger <= 0;
            end_of_block_empty <= 0; // Will be updated based on calculated last_nz_idx
        end
        else if (active) begin
            push_valid <= 0; // Mặc định không push
            
            if (count == 0) begin
                // Xử lý hệ số DC
                dc_prev <= curr_val;
                
                push_data <= (Y_DC[calc_vli_size(diff_val)] << calc_vli_size(diff_val)) | (calc_vli_amp(diff_val) & ((1 << calc_vli_size(diff_val)) - 1));
                push_len  <= Y_DC_code_length[calc_vli_size(diff_val)] + calc_vli_size(diff_val);
                push_valid <= 1;
                count <= count + 1;
            end 
            else if (count > last_nz_idx) begin
                // Đã duyệt hết các hệ số khác 0
                if (last_nz_idx < 63) begin
                    // Xuất mã End Of Block (EOB) = AC(0,0)
                    push_data <= Y_AC[3];
                    push_len  <= Y_AC_code_length[3];
                    push_valid <= 1;
                end else begin
                    // Phát dummy chunk để đảm bảo is_last_chunk marker được đẩy vào FIFO
                    push_data <= 0;
                    push_len  <= 0;
                    push_valid <= 1;
                end
                
                active <= 0;
                eob_trigger <= 1;
            end 
            else begin
                // Xử lý hệ số AC
                if (curr_val == 0) begin
                    if (zrl == 15) begin
                        // ZRL = 15 -> Xuất mã (15,0)
                        push_data <= Y_AC[ Y_AC_run_code[8'hF0] ];
                        push_len  <= Y_AC_code_length[ Y_AC_run_code[8'hF0] ];
                        push_valid <= 1;
                        zrl <= 0;
                    end else begin
                        zrl <= zrl + 1;
                    end
                end 
                else begin
                    // Có giá trị khác 0 -> Kết hợp zrl và size để tra bảng Huffman
                    run_size_idx = {zrl, calc_vli_size(curr_val)};
                    
                    push_data <= (Y_AC[ Y_AC_run_code[run_size_idx] ] << calc_vli_size(curr_val)) | (calc_vli_amp(curr_val) & ((1 << calc_vli_size(curr_val)) - 1));
                    push_len  <= Y_AC_code_length[ Y_AC_run_code[run_size_idx] ] + calc_vli_size(curr_val);
                    push_valid <= 1;
                    zrl <= 0;
                end
                count <= count + 1;
            end
        end else begin
            push_valid <= 0;
            eob_trigger <= 0;
        end
    end

    // -------------------------------------------------------------------------
    // 5. BITSTREAM PACKER
    // -------------------------------------------------------------------------
    reg [63:0] bit_buffer;
    reg [6:0]  bit_cnt;
    reg flushing;

    always @(posedge clk) begin
        if (rst) begin
            bit_buffer <= 0;
            bit_cnt <= 0;
            JPEG_bitstream <= 0;
            data_ready <= 0;
            output_reg_count <= 0;
            end_of_block_output <= 0;
            flushing <= 0;
            is_last_chunk <= 0;
            eob_trigger <= 0;
        end
        else begin
            data_ready <= 0;
            output_reg_count <= 0;
            end_of_block_output <= 0;
            is_last_chunk <= 0;

            if (eob_trigger) flushing <= 1;

            if (push_valid && bit_cnt >= 32) begin
                // Vừa push data mới, vừa xả 32 bit
                bit_buffer <= (bit_buffer << push_len) | push_data;
                bit_cnt <= bit_cnt + push_len - 32;
                JPEG_bitstream <= bit_buffer[bit_cnt - 1 -: 32];
                data_ready <= 1;
                output_reg_count <= 6'd32;
            end
            else if (push_valid) begin
                // Chỉ push data mới
                bit_buffer <= (bit_buffer << push_len) | push_data;
                bit_cnt <= bit_cnt + push_len;
            end
            else if (bit_cnt >= 32) begin
                // Chỉ xả 32 bit
                JPEG_bitstream <= bit_buffer[bit_cnt - 1 -: 32];
                bit_cnt <= bit_cnt - 32;
                data_ready <= 1;
                output_reg_count <= 6'd32;
            end
            else if (flushing && bit_cnt > 0) begin
                // Xả các bit còn lại (padding 1) khi kết thúc block
                JPEG_bitstream <= (bit_buffer[31:0] << (6'd32 - bit_cnt)) | ((32'hFFFF_FFFF) >> bit_cnt);
                bit_cnt <= 0;
                data_ready <= 1;
                output_reg_count <= {1'b0, bit_cnt[4:0]};
                flushing <= 0;
                end_of_block_output <= 1;
                is_last_chunk <= 1;
            end
            else if (flushing && bit_cnt == 0) begin
                flushing <= 0;
                end_of_block_output <= 1;
                data_ready <= 1;
                output_reg_count <= 6'd0;
                is_last_chunk <= 1;
            end
        end
    end

endmodule