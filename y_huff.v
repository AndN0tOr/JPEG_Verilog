module y_huff(
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
    output reg [4:0]  output_reg_count, 
    output reg end_of_block_output,
    output reg end_of_block_empty
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
        // DC Codes (Dành riêng cho kênh Y - Luminance)
        Y_DC[0]=11'b000; Y_DC_code_length[0]=2;
        Y_DC[1]=11'b010; Y_DC_code_length[1]=2;
        Y_DC[2]=11'b100; Y_DC_code_length[2]=2;
        Y_DC[3]=11'b110; Y_DC_code_length[3]=3;
        Y_DC[4]=11'b1110; Y_DC_code_length[4]=4;
        Y_DC[5]=11'b11110; Y_DC_code_length[5]=5;
        Y_DC[6]=11'b111110; Y_DC_code_length[6]=6;
        Y_DC[7]=11'b1111110; Y_DC_code_length[7]=7;
        Y_DC[8]=11'b11111110; Y_DC_code_length[8]=8;
        Y_DC[9]=11'b111111110; Y_DC_code_length[9]=9;
        Y_DC[10]=11'b1111111110; Y_DC_code_length[10]=10;
        Y_DC[11]=11'b11111111110; Y_DC_code_length[11]=11;

        // AC Codes - JPEG Standard Luminance AC Huffman Table
        Y_AC[0] = 16'h000A; Y_AC_code_length[0] = 4;  Y_AC_run_code[8'h00] = 0;   // EOB
        Y_AC[1] = 16'h0000; Y_AC_code_length[1] = 2;  Y_AC_run_code[8'h01] = 1;   // (0,1)
        Y_AC[2] = 16'h0001; Y_AC_code_length[2] = 2;  Y_AC_run_code[8'h02] = 2;   // (0,2)
        Y_AC[3] = 16'h0004; Y_AC_code_length[3] = 3;  Y_AC_run_code[8'h03] = 3;   // (0,3)
        Y_AC[4] = 16'h000B; Y_AC_code_length[4] = 4;  Y_AC_run_code[8'h04] = 4;   // (0,4)
        Y_AC[5] = 16'h001A; Y_AC_code_length[5] = 5;  Y_AC_run_code[8'h05] = 5;   // (0,5)
        Y_AC[6] = 16'h0078; Y_AC_code_length[6] = 7;  Y_AC_run_code[8'h06] = 6;   // (0,6)
        Y_AC[7] = 16'h00F8; Y_AC_code_length[7] = 8;  Y_AC_run_code[8'h07] = 7;   // (0,7)
        Y_AC[8] = 16'h03F6; Y_AC_code_length[8] = 10; Y_AC_run_code[8'h08] = 8;   // (0,8)
        Y_AC[9] = 16'hFF82; Y_AC_code_length[9] = 16; Y_AC_run_code[8'h09] = 9;   // (0,9)
        Y_AC[10] = 16'hFF83; Y_AC_code_length[10] = 16; Y_AC_run_code[8'h0A] = 10; // (0,A)
        Y_AC[11] = 16'h0005; Y_AC_code_length[11] = 4;  Y_AC_run_code[8'h11] = 11; // (1,1)
        Y_AC[12] = 16'h0038; Y_AC_code_length[12] = 6;  Y_AC_run_code[8'h12] = 12; // (1,2)
        Y_AC[13] = 16'h00F9; Y_AC_code_length[13] = 8;  Y_AC_run_code[8'h13] = 13; // (1,3)
        Y_AC[14] = 16'h03F7; Y_AC_code_length[14] = 10; Y_AC_run_code[8'h14] = 14; // (1,4)
        Y_AC[15] = 16'hFF84; Y_AC_code_length[15] = 16; Y_AC_run_code[8'h15] = 15; // (1,5)
        Y_AC[16] = 16'h0039; Y_AC_code_length[16] = 6;  Y_AC_run_code[8'h21] = 16; // (2,1)
        Y_AC[17] = 16'h00FA; Y_AC_code_length[17] = 8;  Y_AC_run_code[8'h22] = 17; // (2,2)
        Y_AC[18] = 16'h07F6; Y_AC_code_length[18] = 11; Y_AC_run_code[8'h23] = 18; // (2,3)
        Y_AC[19] = 16'h003A; Y_AC_code_length[19] = 6;  Y_AC_run_code[8'h31] = 19; // (3,1)
        Y_AC[20] = 16'h01F6; Y_AC_code_length[20] = 9;  Y_AC_run_code[8'h32] = 20; // (3,2)
        Y_AC[21] = 16'h003B; Y_AC_code_length[21] = 6;  Y_AC_run_code[8'h41] = 21; // (4,1)
        Y_AC[22] = 16'h0079; Y_AC_code_length[22] = 7;  Y_AC_run_code[8'h51] = 22; // (5,1)
        Y_AC[23] = 16'h01F7; Y_AC_code_length[23] = 9;  Y_AC_run_code[8'hF0] = 23; // ZRL (15,0)
        // Initialize remaining entries to safe values
        for (i = 24; i < 162; i = i + 1) begin
            Y_AC[i] = 16'h000A;
            Y_AC_code_length[i] = 4;
        end
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
    reg [11:0] dc_prev;
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

    // FIFO to buffer incoming blocks (depth = 64 for better throughput)
    reg [11:0] fifo_mem [0:63][0:63]; // 64 blocks, each 64 coefficients
    reg [5:0] fifo_wr_ptr;
    reg [5:0] fifo_rd_ptr;
    wire [5:0] fifo_count = fifo_wr_ptr - fifo_rd_ptr;
    wire fifo_empty = (fifo_count == 0);
    wire fifo_full = (fifo_count == 63);

    integer j;

    // Write to FIFO when enable posedge detected
    always @(posedge clk) begin
        if (rst) begin
            fifo_wr_ptr <= 0;
        end
        else if (enable_posedge && !fifo_full) begin
            for (j = 0; j < 64; j = j + 1) begin
                fifo_mem[fifo_wr_ptr][j] <= zz[j];
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

    // Read from buffered data instead of direct input
    wire [11:0] curr_val = zz_buf[count];
    wire [11:0] diff_val = curr_val - dc_prev;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            active <= 0;
            zrl <= 0;
            dc_prev <= 0;
            push_valid <= 0;
            end_of_block_output <= 0;
            end_of_block_empty <= 0;
            fifo_rd_ptr <= 0;
        end
        else if (!active && !fifo_empty) begin
            // Start processing next block from FIFO
            for (j = 0; j < 64; j = j + 1) begin
                zz_buf[j] <= fifo_mem[fifo_rd_ptr][j];
            end
            fifo_rd_ptr <= fifo_rd_ptr + 1;

            // Calculate last_nz_idx from the block being loaded
            last_nz_idx <= 0;
            for (i = 63; i >= 1; i = i - 1) begin
                if (fifo_mem[fifo_rd_ptr][i] != 0 && last_nz_idx == 0)
                    last_nz_idx <= i;
            end

            count <= 0;
            active <= 1;
            zrl <= 0;
            push_valid <= 0;
            end_of_block_output <= 0;
            end_of_block_empty <= 0; // Will be updated based on calculated last_nz_idx
        end
        else if (active) begin
            push_valid <= 0; // Mặc định không push
            
            if (count == 0) begin
                // Xử lý hệ số DC
                dc_prev <= curr_val;
                
                push_data <= { Y_DC[calc_vli_size(diff_val)], calc_vli_amp(diff_val) };
                push_len  <= Y_DC_code_length[calc_vli_size(diff_val)] + calc_vli_size(diff_val);
                push_valid <= 1;
                count <= count + 1;
            end 
            else if (count > last_nz_idx) begin
                // Đã hết phần tử khác 0 -> Xuất mã End Of Block (EOB) = AC(0,0)
                push_data <= Y_AC[0];
                push_len  <= Y_AC_code_length[0];
                push_valid <= 1;
                
                active <= 0;
                end_of_block_output <= 1;
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
                    
                    push_data <= { Y_AC[ Y_AC_run_code[run_size_idx] ], calc_vli_amp(curr_val) };
                    push_len  <= Y_AC_code_length[ Y_AC_run_code[run_size_idx] ] + calc_vli_size(curr_val);
                    push_valid <= 1;
                    zrl <= 0;
                end
                count <= count + 1;
            end
        end else begin
            push_valid <= 0;
            end_of_block_output <= 0;
        end
    end

    // -------------------------------------------------------------------------
    // 5. BITSTREAM PACKER
    // -------------------------------------------------------------------------
    reg [63:0] bit_buffer;
    reg [6:0]  bit_cnt;

    always @(posedge clk) begin
        if (rst || enable) begin
            bit_buffer <= 0;
            bit_cnt <= 0;
            data_ready <= 0;
            output_reg_count <= 0;
        end 
        else begin
            data_ready <= 0;
            output_reg_count <= 0;

            if (push_valid) begin
                // Đẩy bit mới vào thanh ghi dịch
                bit_buffer <= (bit_buffer << push_len) | push_data;
                bit_cnt <= bit_cnt + push_len;
            end

            // Khi tích lũy đủ 32 bit, xuất ra ngoài
            if (bit_cnt >= 32) begin
                JPEG_bitstream <= bit_buffer[bit_cnt - 1 -: 32];
                bit_cnt <= bit_cnt - 32;
                data_ready <= 1;
                output_reg_count <= 32; 
            end
            
            // Xử lý xả bitstream còn dư khi kết thúc Block
            if (end_of_block_output && bit_cnt > 0 && bit_cnt < 32) begin
                // Padding bằng số 1 (Theo chuẩn bitstream JPEG)
                JPEG_bitstream <= (bit_buffer[bit_cnt - 1 -: 32]) | ((32'hFFFF_FFFF) >> bit_cnt);
                bit_cnt <= 0;
                data_ready <= 1;
                output_reg_count <= bit_cnt;
            end
        end
    end

endmodule