module dct_2d_1channel (
    input clk,
    input rst,        
    input enable,
    input [7:0] data_in,
    output reg output_enable,
    output [11:0] 
        Z11_final, Z12_final, Z13_final, Z14_final, Z15_final, Z16_final, Z17_final, Z18_final, 
        Z21_final, Z22_final, Z23_final, Z24_final, Z25_final, Z26_final, Z27_final, Z28_final, 
        Z31_final, Z32_final, Z33_final, Z34_final, Z35_final, Z36_final, Z37_final, Z38_final, 
        Z41_final, Z42_final, Z43_final, Z44_final, Z45_final, Z46_final, Z47_final, Z48_final, 
        Z51_final, Z52_final, Z53_final, Z54_final, Z55_final, Z56_final, Z57_final, Z58_final, 
        Z61_final, Z62_final, Z63_final, Z64_final, Z65_final, Z66_final, Z67_final, Z68_final, 
        Z71_final, Z72_final, Z73_final, Z74_final, Z75_final, Z76_final, Z77_final, Z78_final,
        Z81_final, Z82_final, Z83_final, Z84_final, Z85_final, Z86_final, Z87_final, Z88_final
);

    // --- Internal Registers ---
    reg [2:0] index_in_row; 
    reg [2:0] index_of_row;
    
    // State registers for Column Phase
    reg col_feed_enable;
    reg [2:0] col_read_row_idx;
    reg [2:0] col_read_col_idx;
    reg [2:0] index_of_col;

    // Buffers (Double Buffered to prevent data hazard)
    reg [11:0] dct_transpose_buffer_0 [0:7][0:7];
    reg [11:0] dct_transpose_buffer_1 [0:7][0:7];
    reg write_buf_sel; // 0 for buf0, 1 for buf1
    reg read_buf_sel;  // 0 for buf0, 1 for buf1
    
    // Track ready blocks
    reg [2:0] blocks_ready;

    reg [11:0] dct_result [0:7][0:7];

    wire [11:0] dct_1d_row [0:7];
    wire [11:0] dct_1d_col [0:7];
    wire dct_row_out_enable;
    wire dct_col_out_enable;

    integer i, j;

    // ==========================================
    // KHỞI TẠO BỘ ĐẾM
    // ==========================================
    always @ (posedge clk) begin
        if (rst) begin
            index_in_row <= 3'b0;
        end else begin
            if (enable) begin
                index_in_row <= index_in_row + 1'b1;
            end else begin
                index_in_row <= 3'b0; 
            end
        end
    end

    // --- Khối Hàng: Lưu kết quả vào Transpose Buffer (Ping-Pong) ---
    always @ (posedge clk) begin
        if (rst) begin
            index_of_row <= 3'b0;
            write_buf_sel <= 1'b0;
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    dct_transpose_buffer_0[i][j] <= 12'b0;
                    dct_transpose_buffer_1[i][j] <= 12'b0;
                end
            end
        end else if (dct_row_out_enable) begin
            if (write_buf_sel == 1'b0) begin
                for (i = 0; i < 8; i = i + 1) begin
                    dct_transpose_buffer_0[index_of_row][i] <= dct_1d_row[i];
                end
            end else begin
                for (i = 0; i < 8; i = i + 1) begin
                    dct_transpose_buffer_1[index_of_row][i] <= dct_1d_row[i];
                end
            end
            
            index_of_row <= index_of_row + 1'b1;
            
            // Switch write buffer when a block is fully written
            if (index_of_row == 3'd7) begin
                write_buf_sel <= ~write_buf_sel;
            end
        end
    end

    // --- Khối Điều khiển: Quét dọc Transpose Buffer để nạp cho Cột ---
    wire block_done = (dct_row_out_enable && index_of_row == 3'd7);
    wire col_phase_done = (col_feed_enable && col_read_col_idx == 3'd7 && col_read_row_idx == 3'd7);

    always @(posedge clk) begin
        if (rst) blocks_ready <= 3'b0;
        else begin
            case ({block_done, col_phase_done})
                2'b10: blocks_ready <= blocks_ready + 1'b1;
                2'b01: blocks_ready <= blocks_ready - 1'b1;
                default: blocks_ready <= blocks_ready;
            endcase
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            col_feed_enable <= 1'b0;
            col_read_row_idx <= 3'b0;
            col_read_col_idx <= 3'b0;
            read_buf_sel <= 1'b0;
        end else begin
            if (!col_feed_enable) begin
                if (blocks_ready > 0 || block_done) begin
                    col_feed_enable <= 1'b1;
                end
            end else begin
                col_read_row_idx <= col_read_row_idx + 1'b1;
                if (col_read_row_idx == 3'd7) begin
                    col_read_col_idx <= col_read_col_idx + 1'b1;
                    if (col_read_col_idx == 3'd7) begin
                        read_buf_sel <= ~read_buf_sel;
                        // Finished reading a block. Keep feeding if more blocks ready, or if a block JUST finished writing
                        if (blocks_ready > 0 || block_done) begin
                            col_feed_enable <= 1'b1; // Continue
                        end else begin
                            col_feed_enable <= 1'b0; // Stop
                        end
                    end
                end
            end
        end
    end

    // --- Khối Cột: Lưu kết quả cuối cùng ---
    always @ (posedge clk) begin
        if (rst) begin
            index_of_col <= 3'b0;
            output_enable <= 1'b0;
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    dct_result[i][j] <= 12'b0;
                end
            end
        end else begin
            if (dct_col_out_enable) begin
                for (i = 0; i < 8; i = i + 1) begin
                    dct_result[i][index_of_col] <= dct_1d_col[i]; 
                end
                index_of_col <= index_of_col + 1'b1;
                
                if (index_of_col == 3'd7) begin
                    output_enable <= 1'b1;
                end
            end else begin
                output_enable <= 1'b0; 
            end
        end
    end

    // --- Instances 1D DCT ---
    
    // JPEG Level Shift: Subtract 128 from input (shift from [0,255] to [-128,127])
    wire [7:0] data_in_shifted = data_in - 8'd128;

    // Instance 1: Xử lý Hàng
    compute_1d_dct #(
        .IN_WIDTH(8)
    ) dct_row_inst (
        .rst(rst),
        .clk(clk),
        .enable(enable),      
        .data_in(data_in_shifted),    
        .index(index_in_row), 
        .out_enable(dct_row_out_enable),
        .dct_out_0(dct_1d_row[0]), .dct_out_1(dct_1d_row[1]), 
        .dct_out_2(dct_1d_row[2]), .dct_out_3(dct_1d_row[3]),
        .dct_out_4(dct_1d_row[4]), .dct_out_5(dct_1d_row[5]),
        .dct_out_6(dct_1d_row[6]), .dct_out_7(dct_1d_row[7])
    );

    wire [11:0] col_data_in = read_buf_sel ? 
        dct_transpose_buffer_1[col_read_row_idx][col_read_col_idx] : 
        dct_transpose_buffer_0[col_read_row_idx][col_read_col_idx];

    // Instance 2: Xử lý Cột 
    compute_1d_dct #(
        .IN_WIDTH(12)
    ) dct_col_inst (
        .rst(rst),
        .clk(clk),
        .enable(col_feed_enable),
        .data_in(col_data_in), 
        .index(col_read_row_idx),
        .out_enable(dct_col_out_enable),
        .dct_out_0(dct_1d_col[0]), .dct_out_1(dct_1d_col[1]), 
        .dct_out_2(dct_1d_col[2]), .dct_out_3(dct_1d_col[3]),
        .dct_out_4(dct_1d_col[4]), .dct_out_5(dct_1d_col[5]),
        .dct_out_6(dct_1d_col[6]), .dct_out_7(dct_1d_col[7])
    );

    // --- Gán Output (Flattening) ---
    assign Z11_final = dct_result[0][0]; assign Z12_final = dct_result[0][1]; assign Z13_final = dct_result[0][2]; assign Z14_final = dct_result[0][3];
    assign Z15_final = dct_result[0][4]; assign Z16_final = dct_result[0][5]; assign Z17_final = dct_result[0][6]; assign Z18_final = dct_result[0][7];
    assign Z21_final = dct_result[1][0]; assign Z22_final = dct_result[1][1]; assign Z23_final = dct_result[1][2]; assign Z24_final = dct_result[1][3];
    assign Z25_final = dct_result[1][4]; assign Z26_final = dct_result[1][5]; assign Z27_final = dct_result[1][6]; assign Z28_final = dct_result[1][7];
    assign Z31_final = dct_result[2][0]; assign Z32_final = dct_result[2][1]; assign Z33_final = dct_result[2][2]; assign Z34_final = dct_result[2][3];
    assign Z35_final = dct_result[2][4]; assign Z36_final = dct_result[2][5]; assign Z37_final = dct_result[2][6]; assign Z38_final = dct_result[2][7];
    assign Z41_final = dct_result[3][0]; assign Z42_final = dct_result[3][1]; assign Z43_final = dct_result[3][2]; assign Z44_final = dct_result[3][3];
    assign Z45_final = dct_result[3][4]; assign Z46_final = dct_result[3][5]; assign Z47_final = dct_result[3][6]; assign Z48_final = dct_result[3][7];
    assign Z51_final = dct_result[4][0]; assign Z52_final = dct_result[4][1]; assign Z53_final = dct_result[4][2]; assign Z54_final = dct_result[4][3];
    assign Z55_final = dct_result[4][4]; assign Z56_final = dct_result[4][5]; assign Z57_final = dct_result[4][6]; assign Z58_final = dct_result[4][7];
    assign Z61_final = dct_result[5][0]; assign Z62_final = dct_result[5][1]; assign Z63_final = dct_result[5][2]; assign Z64_final = dct_result[5][3];
    assign Z65_final = dct_result[5][4]; assign Z66_final = dct_result[5][5]; assign Z67_final = dct_result[5][6]; assign Z68_final = dct_result[5][7];
    assign Z71_final = dct_result[6][0]; assign Z72_final = dct_result[6][1]; assign Z73_final = dct_result[6][2]; assign Z74_final = dct_result[6][3];
    assign Z75_final = dct_result[6][4]; assign Z76_final = dct_result[6][5]; assign Z77_final = dct_result[6][6]; assign Z78_final = dct_result[6][7];
    assign Z81_final = dct_result[7][0]; assign Z82_final = dct_result[7][1]; assign Z83_final = dct_result[7][2]; assign Z84_final = dct_result[7][3];
    assign Z85_final = dct_result[7][4]; assign Z86_final = dct_result[7][5]; assign Z87_final = dct_result[7][6]; assign Z88_final = dct_result[7][7];

endmodule
