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
    output reg [4:0]  output_reg_count, 
    output reg end_of_block_output,
    output reg end_of_block_empty
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
    reg [5:0] last_nz_idx;
    integer i;
    always @(*) begin
        last_nz_idx = 0;
        for (i = 63; i >= 1; i = i - 1) begin
            if (zz[i] != 0 && last_nz_idx == 0) last_nz_idx = i;
        end
    end

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
        // --- BẢNG CHROMINANCE DC MẶC ĐỊNH ---
        C_DC[0]=11'b00;         C_DC_code_length[0]=2;
        C_DC[1]=11'b01;         C_DC_code_length[1]=2;
        C_DC[2]=11'b10;         C_DC_code_length[2]=2;
        C_DC[3]=11'b110;        C_DC_code_length[3]=3;
        C_DC[4]=11'b1110;       C_DC_code_length[4]=4;
        C_DC[5]=11'b11110;      C_DC_code_length[5]=5;
        C_DC[6]=11'b111110;     C_DC_code_length[6]=6;
        C_DC[7]=11'b1111110;    C_DC_code_length[7]=7;
        C_DC[8]=11'b11111110;   C_DC_code_length[8]=8;
        C_DC[9]=11'b111111110;  C_DC_code_length[9]=9;
        C_DC[10]=11'b1111111110;C_DC_code_length[10]=10;
        C_DC[11]=11'b11111111110;C_DC_code_length[11]=11;

        // --- BẢNG CHROMINANCE AC MẶC ĐỊNH ---
        // (Vui lòng paste tiếp dữ liệu AC thực tế của bạn vào đây)
        C_AC[0] = 16'b00; C_AC_code_length[0] = 2; C_AC_run_code[1] = 0; // End Of Block
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
    reg [11:0] dc_prev;  // Lưu giá trị DC của block trước đó
    reg active;

    // Các biến dùng cho Bitstream Packer
    reg [27:0] push_data;
    reg [4:0]  push_len;
    reg push_valid;
    
    // zz đã là 12 bit, ta nối thẳng vào curr_val
    wire [11:0] curr_val = zz[count]; 
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
        end 
        else if (enable) begin
            count <= 0;
            active <= 1;
            zrl <= 0;
            push_valid <= 0;
            end_of_block_output <= 0;
            end_of_block_empty <= (last_nz_idx == 0);
        end 
        else if (active) begin
            push_valid <= 0; 
            
            if (count == 0) begin
                // Xử lý hệ số DC
                dc_prev <= curr_val;
                
                push_data <= { C_DC[calc_vli_size(diff_val)], calc_vli_amp(diff_val) };
                push_len  <= C_DC_code_length[calc_vli_size(diff_val)] + calc_vli_size(diff_val);
                push_valid <= 1;
                count <= count + 1;
            end 
            else if (count > last_nz_idx) begin
                // Đã duyệt hết các hệ số khác 0 -> Xuất mã End Of Block (EOB) = AC(0,0)
                push_data <= C_AC[0];
                push_len  <= C_AC_code_length[0];
                push_valid <= 1;
                
                active <= 0;
                end_of_block_output <= 1;
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
                    
                    push_data <= { C_AC[ C_AC_run_code[run_size_idx] ], calc_vli_amp(curr_val) };
                    push_len  <= C_AC_code_length[ C_AC_run_code[run_size_idx] ] + calc_vli_size(curr_val);
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
    // 5. BITSTREAM PACKER (Gom bit)
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
                // Shift data mới vào
                bit_buffer <= (bit_buffer << push_len) | push_data;
                bit_cnt <= bit_cnt + push_len;
            end

            // Đủ 32 bit -> Đẩy ra ngoài
            if (bit_cnt >= 32) begin
                JPEG_bitstream <= bit_buffer[bit_cnt - 1 -: 32];
                bit_cnt <= bit_cnt - 32;
                data_ready <= 1;
                output_reg_count <= 32; 
            end
            
            // Xả nốt bitstream thừa khi kết thúc Block (padding với số 1)
            if (end_of_block_output && bit_cnt > 0 && bit_cnt < 32) begin
                JPEG_bitstream <= (bit_buffer[bit_cnt - 1 -: 32]) | ((32'hFFFF_FFFF) >> bit_cnt);
                bit_cnt <= 0;
                data_ready <= 1;
                output_reg_count <= bit_cnt;
            end
        end
    end

endmodule