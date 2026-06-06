module chroma_huff(
    input clk, 
    input rst, 
    input enable,
    // Ngõ vào của khối 8x8 kênh Cb (hoặc Cr) - ĐÃ CHUYỂN SANG 12 BIT
    input [11:0] C11, C12, C13, C14, C15, C16, C17, C18, 
    input [11:0] C21, C22, C23, C24, C25, C26, C27, C28,
    input [11:0] C31, C32, C33, C34, C35, C36, C37, C38, 
    input [11:0] C41, C42, C43, C44, C45, C46, C47, C48,
    input [11:0] C51, C52, C53, C54, C55, C56, C57, C58, 
    input [11:0] C61, C62, C63, C64, C65, C66, C67, C68,
    input [11:0] C71, C72, C73, C74, C75, C76, C77, C78, 
    input [11:0] C81, C82, C83, C84, C85, C86, C87, C88,
    
    // Output GIỮ NGUYÊN
    output reg [31:0] JPEG_bitstream, 
    output reg data_ready, 
    output reg [5:0]  output_reg_count, 
    output reg end_of_block_output,
    output reg end_of_block_empty,
    output reg is_last_chunk
);

    // -------------------------------------------------------------------------
    // 1. ZIG-ZAG MAPPING BẰNG MẢNG (Đã chuyển sang 12 bit)
    // -------------------------------------------------------------------------
    wire [11:0] zz [0:63];

    assign zz[0]=C11;  assign zz[1]=C12;  assign zz[2]=C21;  assign zz[3]=C31;
    assign zz[4]=C22;  assign zz[5]=C13;  assign zz[6]=C14;  assign zz[7]=C23;
    assign zz[8]=C32;  assign zz[9]=C41;  assign zz[10]=C51; assign zz[11]=C42;
    assign zz[12]=C33; assign zz[13]=C24; assign zz[14]=C15; assign zz[15]=C16;
    assign zz[16]=C25; assign zz[17]=C34; assign zz[18]=C43; assign zz[19]=C52;
    assign zz[20]=C61; assign zz[21]=C71; assign zz[22]=C62; assign zz[23]=C53;
    assign zz[24]=C44; assign zz[25]=C35; assign zz[26]=C26; assign zz[27]=C17;
    assign zz[28]=C18; assign zz[29]=C27; assign zz[30]=C36; assign zz[31]=C45;
    assign zz[32]=C54; assign zz[33]=C63; assign zz[34]=C72; assign zz[35]=C81;
    assign zz[36]=C82; assign zz[37]=C73; assign zz[38]=C64; assign zz[39]=C55;
    assign zz[40]=C46; assign zz[41]=C37; assign zz[42]=C28; assign zz[43]=C38;
    assign zz[44]=C47; assign zz[45]=C56; assign zz[46]=C65; assign zz[47]=C74;
    assign zz[48]=C83; assign zz[49]=C84; assign zz[50]=C75; assign zz[51]=C66;
    assign zz[52]=C57; assign zz[53]=C48; assign zz[54]=C58; assign zz[55]=C67;
    assign zz[56]=C76; assign zz[57]=C85; assign zz[58]=C86; assign zz[59]=C77;
    assign zz[60]=C68; assign zz[61]=C78; assign zz[62]=C87; assign zz[63]=C88;

    // Tìm index cuối cùng khác 0 để chèn End Of Block (EOB)
    // Tính từ zz_buf thay vì zz để đảm bảo đồng bộ với data đang xử lý
    reg [5:0] last_nz_idx;
    integer i;

    // -------------------------------------------------------------------------
    // 2. ROM BẢNG HUFFMAN CHO CHROMINANCE (Cb/Cr)
    // -------------------------------------------------------------------------
    reg [10:0] C_DC [0:11];
    reg [3:0]  C_DC_code_length [0:11];
    reg [15:0] C_AC [0:161];
    reg [4:0]  C_AC_code_length [0:161];
    reg [7:0]  C_AC_run_code [0:255]; 

    reg [7:0] run_size_idx;

    initial begin
        // --- BẢNG CHROMINANCE DC (JPEG Standard - Canonical) ---
        // BITS = [0,3,1,1,1,1,1,1,1,1,1,0,0,0,0,0]
        C_DC[0]=11'b00;          C_DC_code_length[0]=2;   // 00
        C_DC[1]=11'b01;          C_DC_code_length[1]=2;   // 01
        C_DC[2]=11'b10;          C_DC_code_length[2]=2;   // 10
        C_DC[3]=11'b110;         C_DC_code_length[3]=3;   // 110
        C_DC[4]=11'b1110;        C_DC_code_length[4]=4;   // 1110
        C_DC[5]=11'b11110;       C_DC_code_length[5]=5;   // 11110
        C_DC[6]=11'b111110;      C_DC_code_length[6]=6;   // 111110
        C_DC[7]=11'b1111110;     C_DC_code_length[7]=7;   // 1111110
        C_DC[8]=11'b11111110;    C_DC_code_length[8]=8;   // 11111110
        C_DC[9]=11'b111111110;   C_DC_code_length[9]=9;   // 111111110
        C_DC[10]=11'b1111111110; C_DC_code_length[10]=10; // 1111111110
        C_DC[11]=11'b11111111110;C_DC_code_length[11]=11; // 11111111110
 
        // --- BẢNG CHROMINANCE AC (JPEG Standard - Canonical) ---
        // BITS = [ 0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77]
        C_AC[0] = 16'h0000; C_AC_code_length[0] = 2;  C_AC_run_code[8'h00] = 0;   // (0,0) EOB
        C_AC[1] = 16'h0001; C_AC_code_length[1] = 2;  C_AC_run_code[8'h01] = 1;   // (0,1)
        C_AC[2] = 16'h0004; C_AC_code_length[2] = 3;  C_AC_run_code[8'h02] = 2;   // (0,2)
        C_AC[3] = 16'h000A; C_AC_code_length[3] = 4;  C_AC_run_code[8'h03] = 3;   // (0,3)
        C_AC[4] = 16'h000B; C_AC_code_length[4] = 4;  C_AC_run_code[8'h11] = 4;   // (1,1)
        C_AC[5] = 16'h0018; C_AC_code_length[5] = 5;  C_AC_run_code[8'h04] = 5;   // (0,4)
        C_AC[6] = 16'h0019; C_AC_code_length[6] = 5;  C_AC_run_code[8'h05] = 6;   // (0,5)
        C_AC[7] = 16'h001A; C_AC_code_length[7] = 5;  C_AC_run_code[8'h21] = 7;   // (2,1)
        C_AC[8] = 16'h001B; C_AC_code_length[8] = 5;  C_AC_run_code[8'h31] = 8;   // (3,1)
        C_AC[9] = 16'h0038; C_AC_code_length[9] = 6;  C_AC_run_code[8'h06] = 9;   // (0,6)
        C_AC[10] = 16'h0039; C_AC_code_length[10] = 6;  C_AC_run_code[8'h12] = 10;  // (1,2)
        C_AC[11] = 16'h003A; C_AC_code_length[11] = 6;  C_AC_run_code[8'h41] = 11;  // (4,1)
        C_AC[12] = 16'h003B; C_AC_code_length[12] = 6;  C_AC_run_code[8'h51] = 12;  // (5,1)
        C_AC[13] = 16'h0078; C_AC_code_length[13] = 7;  C_AC_run_code[8'h07] = 13;  // (0,7)
        C_AC[14] = 16'h0079; C_AC_code_length[14] = 7;  C_AC_run_code[8'h61] = 14;  // (6,1)
        C_AC[15] = 16'h007A; C_AC_code_length[15] = 7;  C_AC_run_code[8'h71] = 15;  // (7,1)
        C_AC[16] = 16'h00F6; C_AC_code_length[16] = 8;  C_AC_run_code[8'h13] = 16;  // (1,3)
        C_AC[17] = 16'h00F7; C_AC_code_length[17] = 8;  C_AC_run_code[8'h22] = 17;  // (2,2)
        C_AC[18] = 16'h00F8; C_AC_code_length[18] = 8;  C_AC_run_code[8'h32] = 18;  // (3,2)
        C_AC[19] = 16'h00F9; C_AC_code_length[19] = 8;  C_AC_run_code[8'h81] = 19;  // (8,1)
        C_AC[20] = 16'h01F4; C_AC_code_length[20] = 9;  C_AC_run_code[8'h08] = 20;  // (0,8)
        C_AC[21] = 16'h01F5; C_AC_code_length[21] = 9;  C_AC_run_code[8'h14] = 21;  // (1,4)
        C_AC[22] = 16'h01F6; C_AC_code_length[22] = 9;  C_AC_run_code[8'h42] = 22;  // (4,2)
        C_AC[23] = 16'h01F7; C_AC_code_length[23] = 9;  C_AC_run_code[8'h91] = 23;  // (9,1)
        C_AC[24] = 16'h01F8; C_AC_code_length[24] = 9;  C_AC_run_code[8'hA1] = 24;  // (10,1)
        C_AC[25] = 16'h01F9; C_AC_code_length[25] = 9;  C_AC_run_code[8'hB1] = 25;  // (11,1)
        C_AC[26] = 16'h01FA; C_AC_code_length[26] = 9;  C_AC_run_code[8'hC1] = 26;  // (12,1)
        C_AC[27] = 16'h03F6; C_AC_code_length[27] = 10; C_AC_run_code[8'h09] = 27;  // (0,9)
        C_AC[28] = 16'h03F7; C_AC_code_length[28] = 10; C_AC_run_code[8'h23] = 28;  // (2,3)
        C_AC[29] = 16'h03F8; C_AC_code_length[29] = 10; C_AC_run_code[8'h33] = 29;  // (3,3)
        C_AC[30] = 16'h03F9; C_AC_code_length[30] = 10; C_AC_run_code[8'h52] = 30;  // (5,2)
        C_AC[31] = 16'h03FA; C_AC_code_length[31] = 10; C_AC_run_code[8'hF0] = 31;  // (15,0) ZRL
        C_AC[32] = 16'h07F6; C_AC_code_length[32] = 11; C_AC_run_code[8'h15] = 32;  // (1,5)
        C_AC[33] = 16'h07F7; C_AC_code_length[33] = 11; C_AC_run_code[8'h62] = 33;  // (6,2)
        C_AC[34] = 16'h07F8; C_AC_code_length[34] = 11; C_AC_run_code[8'h72] = 34;  // (7,2)
        C_AC[35] = 16'h07F9; C_AC_code_length[35] = 11; C_AC_run_code[8'hD1] = 35;  // (13,1)
        C_AC[36] = 16'h0FF4; C_AC_code_length[36] = 12; C_AC_run_code[8'h0A] = 36;  // (0,10)
        C_AC[37] = 16'h0FF5; C_AC_code_length[37] = 12; C_AC_run_code[8'h16] = 37;  // (1,6)
        C_AC[38] = 16'h0FF6; C_AC_code_length[38] = 12; C_AC_run_code[8'h24] = 38;  // (2,4)
        C_AC[39] = 16'h0FF7; C_AC_code_length[39] = 12; C_AC_run_code[8'h34] = 39;  // (3,4)
        C_AC[40] = 16'h3FE0; C_AC_code_length[40] = 14; C_AC_run_code[8'hE1] = 40;  // (14,1)
        C_AC[41] = 16'h7FC2; C_AC_code_length[41] = 15; C_AC_run_code[8'h25] = 41;  // (2,5)
        C_AC[42] = 16'h7FC3; C_AC_code_length[42] = 15; C_AC_run_code[8'hF1] = 42;  // (15,1)
        C_AC[43] = 16'hFF88; C_AC_code_length[43] = 16; C_AC_run_code[8'h17] = 43;  // (1,7)
        C_AC[44] = 16'hFF89; C_AC_code_length[44] = 16; C_AC_run_code[8'h18] = 44;  // (1,8)
        C_AC[45] = 16'hFF8A; C_AC_code_length[45] = 16; C_AC_run_code[8'h19] = 45;  // (1,9)
        C_AC[46] = 16'hFF8B; C_AC_code_length[46] = 16; C_AC_run_code[8'h1A] = 46;  // (1,10)
        C_AC[47] = 16'hFF8C; C_AC_code_length[47] = 16; C_AC_run_code[8'h26] = 47;  // (2,6)
        C_AC[48] = 16'hFF8D; C_AC_code_length[48] = 16; C_AC_run_code[8'h27] = 48;  // (2,7)
        C_AC[49] = 16'hFF8E; C_AC_code_length[49] = 16; C_AC_run_code[8'h28] = 49;  // (2,8)
        C_AC[50] = 16'hFF8F; C_AC_code_length[50] = 16; C_AC_run_code[8'h29] = 50;  // (2,9)
        C_AC[51] = 16'hFF90; C_AC_code_length[51] = 16; C_AC_run_code[8'h2A] = 51;  // (2,10)
        C_AC[52] = 16'hFF91; C_AC_code_length[52] = 16; C_AC_run_code[8'h35] = 52;  // (3,5)
        C_AC[53] = 16'hFF92; C_AC_code_length[53] = 16; C_AC_run_code[8'h36] = 53;  // (3,6)
        C_AC[54] = 16'hFF93; C_AC_code_length[54] = 16; C_AC_run_code[8'h37] = 54;  // (3,7)
        C_AC[55] = 16'hFF94; C_AC_code_length[55] = 16; C_AC_run_code[8'h38] = 55;  // (3,8)
        C_AC[56] = 16'hFF95; C_AC_code_length[56] = 16; C_AC_run_code[8'h39] = 56;  // (3,9)
        C_AC[57] = 16'hFF96; C_AC_code_length[57] = 16; C_AC_run_code[8'h3A] = 57;  // (3,10)
        C_AC[58] = 16'hFF97; C_AC_code_length[58] = 16; C_AC_run_code[8'h43] = 58;  // (4,3)
        C_AC[59] = 16'hFF98; C_AC_code_length[59] = 16; C_AC_run_code[8'h44] = 59;  // (4,4)
        C_AC[60] = 16'hFF99; C_AC_code_length[60] = 16; C_AC_run_code[8'h45] = 60;  // (4,5)
        C_AC[61] = 16'hFF9A; C_AC_code_length[61] = 16; C_AC_run_code[8'h46] = 61;  // (4,6)
        C_AC[62] = 16'hFF9B; C_AC_code_length[62] = 16; C_AC_run_code[8'h47] = 62;  // (4,7)
        C_AC[63] = 16'hFF9C; C_AC_code_length[63] = 16; C_AC_run_code[8'h48] = 63;  // (4,8)
        C_AC[64] = 16'hFF9D; C_AC_code_length[64] = 16; C_AC_run_code[8'h49] = 64;  // (4,9)
        C_AC[65] = 16'hFF9E; C_AC_code_length[65] = 16; C_AC_run_code[8'h4A] = 65;  // (4,10)
        C_AC[66] = 16'hFF9F; C_AC_code_length[66] = 16; C_AC_run_code[8'h53] = 66;  // (5,3)
        C_AC[67] = 16'hFFA0; C_AC_code_length[67] = 16; C_AC_run_code[8'h54] = 67;  // (5,4)
        C_AC[68] = 16'hFFA1; C_AC_code_length[68] = 16; C_AC_run_code[8'h55] = 68;  // (5,5)
        C_AC[69] = 16'hFFA2; C_AC_code_length[69] = 16; C_AC_run_code[8'h56] = 69;  // (5,6)
        C_AC[70] = 16'hFFA3; C_AC_code_length[70] = 16; C_AC_run_code[8'h57] = 70;  // (5,7)
        C_AC[71] = 16'hFFA4; C_AC_code_length[71] = 16; C_AC_run_code[8'h58] = 71;  // (5,8)
        C_AC[72] = 16'hFFA5; C_AC_code_length[72] = 16; C_AC_run_code[8'h59] = 72;  // (5,9)
        C_AC[73] = 16'hFFA6; C_AC_code_length[73] = 16; C_AC_run_code[8'h5A] = 73;  // (5,10)
        C_AC[74] = 16'hFFA7; C_AC_code_length[74] = 16; C_AC_run_code[8'h63] = 74;  // (6,3)
        C_AC[75] = 16'hFFA8; C_AC_code_length[75] = 16; C_AC_run_code[8'h64] = 75;  // (6,4)
        C_AC[76] = 16'hFFA9; C_AC_code_length[76] = 16; C_AC_run_code[8'h65] = 76;  // (6,5)
        C_AC[77] = 16'hFFAA; C_AC_code_length[77] = 16; C_AC_run_code[8'h66] = 77;  // (6,6)
        C_AC[78] = 16'hFFAB; C_AC_code_length[78] = 16; C_AC_run_code[8'h67] = 78;  // (6,7)
        C_AC[79] = 16'hFFAC; C_AC_code_length[79] = 16; C_AC_run_code[8'h68] = 79;  // (6,8)
        C_AC[80] = 16'hFFAD; C_AC_code_length[80] = 16; C_AC_run_code[8'h69] = 80;  // (6,9)
        C_AC[81] = 16'hFFAE; C_AC_code_length[81] = 16; C_AC_run_code[8'h6A] = 81;  // (6,10)
        C_AC[82] = 16'hFFAF; C_AC_code_length[82] = 16; C_AC_run_code[8'h73] = 82;  // (7,3)
        C_AC[83] = 16'hFFB0; C_AC_code_length[83] = 16; C_AC_run_code[8'h74] = 83;  // (7,4)
        C_AC[84] = 16'hFFB1; C_AC_code_length[84] = 16; C_AC_run_code[8'h75] = 84;  // (7,5)
        C_AC[85] = 16'hFFB2; C_AC_code_length[85] = 16; C_AC_run_code[8'h76] = 85;  // (7,6)
        C_AC[86] = 16'hFFB3; C_AC_code_length[86] = 16; C_AC_run_code[8'h77] = 86;  // (7,7)
        C_AC[87] = 16'hFFB4; C_AC_code_length[87] = 16; C_AC_run_code[8'h78] = 87;  // (7,8)
        C_AC[88] = 16'hFFB5; C_AC_code_length[88] = 16; C_AC_run_code[8'h79] = 88;  // (7,9)
        C_AC[89] = 16'hFFB6; C_AC_code_length[89] = 16; C_AC_run_code[8'h7A] = 89;  // (7,10)
        C_AC[90] = 16'hFFB7; C_AC_code_length[90] = 16; C_AC_run_code[8'h82] = 90;  // (8,2)
        C_AC[91] = 16'hFFB8; C_AC_code_length[91] = 16; C_AC_run_code[8'h83] = 91;  // (8,3)
        C_AC[92] = 16'hFFB9; C_AC_code_length[92] = 16; C_AC_run_code[8'h84] = 92;  // (8,4)
        C_AC[93] = 16'hFFBA; C_AC_code_length[93] = 16; C_AC_run_code[8'h85] = 93;  // (8,5)
        C_AC[94] = 16'hFFBB; C_AC_code_length[94] = 16; C_AC_run_code[8'h86] = 94;  // (8,6)
        C_AC[95] = 16'hFFBC; C_AC_code_length[95] = 16; C_AC_run_code[8'h87] = 95;  // (8,7)
        C_AC[96] = 16'hFFBD; C_AC_code_length[96] = 16; C_AC_run_code[8'h88] = 96;  // (8,8)
        C_AC[97] = 16'hFFBE; C_AC_code_length[97] = 16; C_AC_run_code[8'h89] = 97;  // (8,9)
        C_AC[98] = 16'hFFBF; C_AC_code_length[98] = 16; C_AC_run_code[8'h8A] = 98;  // (8,10)
        C_AC[99] = 16'hFFC0; C_AC_code_length[99] = 16; C_AC_run_code[8'h92] = 99;  // (9,2)
        C_AC[100] = 16'hFFC1; C_AC_code_length[100] = 16; C_AC_run_code[8'h93] = 100; // (9,3)
        C_AC[101] = 16'hFFC2; C_AC_code_length[101] = 16; C_AC_run_code[8'h94] = 101; // (9,4)
        C_AC[102] = 16'hFFC3; C_AC_code_length[102] = 16; C_AC_run_code[8'h95] = 102; // (9,5)
        C_AC[103] = 16'hFFC4; C_AC_code_length[103] = 16; C_AC_run_code[8'h96] = 103; // (9,6)
        C_AC[104] = 16'hFFC5; C_AC_code_length[104] = 16; C_AC_run_code[8'h97] = 104; // (9,7)
        C_AC[105] = 16'hFFC6; C_AC_code_length[105] = 16; C_AC_run_code[8'h98] = 105; // (9,8)
        C_AC[106] = 16'hFFC7; C_AC_code_length[106] = 16; C_AC_run_code[8'h99] = 106; // (9,9)
        C_AC[107] = 16'hFFC8; C_AC_code_length[107] = 16; C_AC_run_code[8'h9A] = 107; // (9,10)
        C_AC[108] = 16'hFFC9; C_AC_code_length[108] = 16; C_AC_run_code[8'hA2] = 108; // (10,2)
        C_AC[109] = 16'hFFCA; C_AC_code_length[109] = 16; C_AC_run_code[8'hA3] = 109; // (10,3)
        C_AC[110] = 16'hFFCB; C_AC_code_length[110] = 16; C_AC_run_code[8'hA4] = 110; // (10,4)
        C_AC[111] = 16'hFFCC; C_AC_code_length[111] = 16; C_AC_run_code[8'hA5] = 111; // (10,5)
        C_AC[112] = 16'hFFCD; C_AC_code_length[112] = 16; C_AC_run_code[8'hA6] = 112; // (10,6)
        C_AC[113] = 16'hFFCE; C_AC_code_length[113] = 16; C_AC_run_code[8'hA7] = 113; // (10,7)
        C_AC[114] = 16'hFFCF; C_AC_code_length[114] = 16; C_AC_run_code[8'hA8] = 114; // (10,8)
        C_AC[115] = 16'hFFD0; C_AC_code_length[115] = 16; C_AC_run_code[8'hA9] = 115; // (10,9)
        C_AC[116] = 16'hFFD1; C_AC_code_length[116] = 16; C_AC_run_code[8'hAA] = 116; // (10,10)
        C_AC[117] = 16'hFFD2; C_AC_code_length[117] = 16; C_AC_run_code[8'hB2] = 117; // (11,2)
        C_AC[118] = 16'hFFD3; C_AC_code_length[118] = 16; C_AC_run_code[8'hB3] = 118; // (11,3)
        C_AC[119] = 16'hFFD4; C_AC_code_length[119] = 16; C_AC_run_code[8'hB4] = 119; // (11,4)
        C_AC[120] = 16'hFFD5; C_AC_code_length[120] = 16; C_AC_run_code[8'hB5] = 120; // (11,5)
        C_AC[121] = 16'hFFD6; C_AC_code_length[121] = 16; C_AC_run_code[8'hB6] = 121; // (11,6)
        C_AC[122] = 16'hFFD7; C_AC_code_length[122] = 16; C_AC_run_code[8'hB7] = 122; // (11,7)
        C_AC[123] = 16'hFFD8; C_AC_code_length[123] = 16; C_AC_run_code[8'hB8] = 123; // (11,8)
        C_AC[124] = 16'hFFD9; C_AC_code_length[124] = 16; C_AC_run_code[8'hB9] = 124; // (11,9)
        C_AC[125] = 16'hFFDA; C_AC_code_length[125] = 16; C_AC_run_code[8'hBA] = 125; // (11,10)
        C_AC[126] = 16'hFFDB; C_AC_code_length[126] = 16; C_AC_run_code[8'hC2] = 126; // (12,2)
        C_AC[127] = 16'hFFDC; C_AC_code_length[127] = 16; C_AC_run_code[8'hC3] = 127; // (12,3)
        C_AC[128] = 16'hFFDD; C_AC_code_length[128] = 16; C_AC_run_code[8'hC4] = 128; // (12,4)
        C_AC[129] = 16'hFFDE; C_AC_code_length[129] = 16; C_AC_run_code[8'hC5] = 129; // (12,5)
        C_AC[130] = 16'hFFDF; C_AC_code_length[130] = 16; C_AC_run_code[8'hC6] = 130; // (12,6)
        C_AC[131] = 16'hFFE0; C_AC_code_length[131] = 16; C_AC_run_code[8'hC7] = 131; // (12,7)
        C_AC[132] = 16'hFFE1; C_AC_code_length[132] = 16; C_AC_run_code[8'hC8] = 132; // (12,8)
        C_AC[133] = 16'hFFE2; C_AC_code_length[133] = 16; C_AC_run_code[8'hC9] = 133; // (12,9)
        C_AC[134] = 16'hFFE3; C_AC_code_length[134] = 16; C_AC_run_code[8'hCA] = 134; // (12,10)
        C_AC[135] = 16'hFFE4; C_AC_code_length[135] = 16; C_AC_run_code[8'hD2] = 135; // (13,2)
        C_AC[136] = 16'hFFE5; C_AC_code_length[136] = 16; C_AC_run_code[8'hD3] = 136; // (13,3)
        C_AC[137] = 16'hFFE6; C_AC_code_length[137] = 16; C_AC_run_code[8'hD4] = 137; // (13,4)
        C_AC[138] = 16'hFFE7; C_AC_code_length[138] = 16; C_AC_run_code[8'hD5] = 138; // (13,5)
        C_AC[139] = 16'hFFE8; C_AC_code_length[139] = 16; C_AC_run_code[8'hD6] = 139; // (13,6)
        C_AC[140] = 16'hFFE9; C_AC_code_length[140] = 16; C_AC_run_code[8'hD7] = 140; // (13,7)
        C_AC[141] = 16'hFFEA; C_AC_code_length[141] = 16; C_AC_run_code[8'hD8] = 141; // (13,8)
        C_AC[142] = 16'hFFEB; C_AC_code_length[142] = 16; C_AC_run_code[8'hD9] = 142; // (13,9)
        C_AC[143] = 16'hFFEC; C_AC_code_length[143] = 16; C_AC_run_code[8'hDA] = 143; // (13,10)
        C_AC[144] = 16'hFFED; C_AC_code_length[144] = 16; C_AC_run_code[8'hE2] = 144; // (14,2)
        C_AC[145] = 16'hFFEE; C_AC_code_length[145] = 16; C_AC_run_code[8'hE3] = 145; // (14,3)
        C_AC[146] = 16'hFFEF; C_AC_code_length[146] = 16; C_AC_run_code[8'hE4] = 146; // (14,4)
        C_AC[147] = 16'hFFF0; C_AC_code_length[147] = 16; C_AC_run_code[8'hE5] = 147; // (14,5)
        C_AC[148] = 16'hFFF1; C_AC_code_length[148] = 16; C_AC_run_code[8'hE6] = 148; // (14,6)
        C_AC[149] = 16'hFFF2; C_AC_code_length[149] = 16; C_AC_run_code[8'hE7] = 149; // (14,7)
        C_AC[150] = 16'hFFF3; C_AC_code_length[150] = 16; C_AC_run_code[8'hE8] = 150; // (14,8)
        C_AC[151] = 16'hFFF4; C_AC_code_length[151] = 16; C_AC_run_code[8'hE9] = 151; // (14,9)
        C_AC[152] = 16'hFFF5; C_AC_code_length[152] = 16; C_AC_run_code[8'hEA] = 152; // (14,10)
        C_AC[153] = 16'hFFF6; C_AC_code_length[153] = 16; C_AC_run_code[8'hF2] = 153; // (15,2)
        C_AC[154] = 16'hFFF7; C_AC_code_length[154] = 16; C_AC_run_code[8'hF3] = 154; // (15,3)
        C_AC[155] = 16'hFFF8; C_AC_code_length[155] = 16; C_AC_run_code[8'hF4] = 155; // (15,4)
        C_AC[156] = 16'hFFF9; C_AC_code_length[156] = 16; C_AC_run_code[8'hF5] = 156; // (15,5)
        C_AC[157] = 16'hFFFA; C_AC_code_length[157] = 16; C_AC_run_code[8'hF6] = 157; // (15,6)
        C_AC[158] = 16'hFFFB; C_AC_code_length[158] = 16; C_AC_run_code[8'hF7] = 158; // (15,7)
        C_AC[159] = 16'hFFFC; C_AC_code_length[159] = 16; C_AC_run_code[8'hF8] = 159; // (15,8)
        C_AC[160] = 16'hFFFD; C_AC_code_length[160] = 16; C_AC_run_code[8'hF9] = 160; // (15,9)
        C_AC[161] = 16'hFFFE; C_AC_code_length[161] = 16; C_AC_run_code[8'hFA] = 161; // (15,10)
    end

    // -------------------------------------------------------------------------
    // 3. HÀM TÍNH TOÁN BIT LENGTH & BIÊN ĐỘ
    // -------------------------------------------------------------------------
    function [3:0] calc_vli_size;
        input [11:0] val;
        reg [11:0] abs_val;
        begin
            abs_val = val[11] ? (~val + 1'b1) : val; // Lấy trị tuyệt đối
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
            // Chuẩn JPEG: Nếu số âm thì trừ đi 1 để mã hóa
            calc_vli_amp = val[11] ? (val - 1'b1) : val; 
        end
    endfunction

    // -------------------------------------------------------------------------
    // 4. QUẢN LÝ TRẠNG THÁI (STATE MACHINE)
    // -------------------------------------------------------------------------
    reg [6:0] count;
    reg [3:0] zrl;       // Đếm số lượng số 0 liên tiếp (Zero Run Length)
    reg signed [11:0] dc_prev;  // Lưu giá trị DC của block trước đó
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
                
                push_data <= (C_DC[calc_vli_size(diff_val)] << calc_vli_size(diff_val)) | (calc_vli_amp(diff_val) & ((1 << calc_vli_size(diff_val)) - 1));
                push_len  <= C_DC_code_length[calc_vli_size(diff_val)] + calc_vli_size(diff_val);
                push_valid <= 1;
                count <= count + 1;
            end 
            else if (count > last_nz_idx) begin
                // Đã duyệt hết các hệ số khác 0
                if (last_nz_idx < 63) begin
                    // Xuất mã End Of Block (EOB) = AC(0,0)
                    push_data <= C_AC[0];
                    push_len  <= C_AC_code_length[0];
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
                        push_data <= C_AC[ C_AC_run_code[8'hF0] ];
                        push_len  <= C_AC_code_length[ C_AC_run_code[8'hF0] ];
                        push_valid <= 1;
                        zrl <= 0;
                    end else begin
                        zrl <= zrl + 1;
                    end
                end 
                else begin
                    // Có giá trị khác 0
                    run_size_idx = {zrl, calc_vli_size(curr_val)};
                    
                    push_data <= (C_AC[ C_AC_run_code[run_size_idx] ] << calc_vli_size(curr_val)) | (calc_vli_amp(curr_val) & ((1 << calc_vli_size(curr_val)) - 1));
                    push_len  <= C_AC_code_length[ C_AC_run_code[run_size_idx] ] + calc_vli_size(curr_val);
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
    // 5. BITSTREAM PACKER (Gom bit)
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