`timescale 1ns/1ps

module y_huff_tb;
    reg clk, rst, enable;
    reg [11:0] Y11, Y12, Y13, Y14, Y15, Y16, Y17, Y18, 
    Y21, Y22, Y23, Y24, Y25, Y26, Y27, Y28,
    Y31, Y32, Y33, Y34, Y35, Y36, Y37, Y38, 
    Y41, Y42, Y43, Y44, Y45, Y46, Y47, Y48,
    Y51, Y52, Y53, Y54, Y55, Y56, Y57, Y58, 
    Y61, Y62, Y63, Y64, Y65, Y66, Y67, Y68,
    Y71, Y72, Y73, Y74, Y75, Y76, Y77, Y78, 
    Y81, Y82, Y83, Y84, Y85, Y86, Y87, Y88;
    wire [31:0] JPEG_bitstream;
    wire data_ready, end_of_block_output, end_of_block_empty;
    wire [4:0] output_reg_count;

    task print_output;
        begin
            $display("JPEG_bitstream: %h", JPEG_bitstream);
            $display("data_ready: %b", data_ready);
            $display("end_of_block_output: %b", end_of_block_output);
            $display("end_of_block_empty: %b", end_of_block_empty);
            $display("output_reg_count: %d", output_reg_count);
        end
    endtask
    y_huff uut(
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .Y11(Y11), .Y12(Y12), .Y13(Y13), .Y14(Y14), .Y15(Y15), .Y16(Y16), .Y17(Y17), .Y18(Y18), 
        .Y21(Y21), .Y22(Y22), .Y23(Y23), .Y24(Y24), .Y25(Y25), .Y26(Y26), .Y27(Y27), .Y28(Y28),
        .Y31(Y31), .Y32(Y32), .Y33(Y33), .Y34(Y34), .Y35(Y35), .Y36(Y36), .Y37(Y37), .Y38(Y38), 
        .Y41(Y41), .Y42(Y42), .Y43(Y43), .Y44(Y44), .Y45(Y45), .Y46(Y46), .Y47(Y47), .Y48(Y48),
        .Y51(Y51), .Y52(Y52), .Y53(Y53), .Y54(Y54), .Y55(Y55), .Y56(Y56), .Y57(Y57), .Y58(Y58), 
        .Y61(Y61), .Y62(Y62), .Y63(Y63), .Y64(Y64), .Y65(Y65), .Y66(Y66), .Y67(Y67), .Y68(Y68),
        .Y71(Y71), .Y72(Y72), .Y73(Y73), .Y74(Y74), .Y75(Y75), .Y76(Y76), .Y77(Y77), .Y78(Y78), 
        .Y81(Y81), .Y82(Y82), .Y83(Y83), .Y84(Y84), .Y85(Y85), .Y86(Y86), .Y87(Y87), .Y88(Y88),
        .JPEG_bitstream(JPEG_bitstream),
        .data_ready(data_ready),
        .output_reg_count(output_reg_count),
        .end_of_block_output(end_of_block_output),
        .end_of_block_empty(end_of_block_empty)
    );
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (data_ready) begin
            $display("TIME: %0t | data_ready: 1 | Count: %d bits | JPEG_bitstream: %h", $time, output_reg_count, JPEG_bitstream);
        end
        if (end_of_block_output) begin
            $display("TIME: %0t | end_of_block_output: 1 | EOB Empty: %b | JPEG_bitstream: %h (Last bits: %d)", $time, end_of_block_empty, JPEG_bitstream, output_reg_count);
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        enable = 0;
        
        repeat(2) @(negedge clk);
        rst = 0;
        enable = 1;
        Y11 = -12'd26; Y12 = -12'd3;  Y13 = -12'd6;  Y14 = 12'd2;  Y15 = 12'd2;  Y16 = -12'd1; Y17 = 12'd0; Y18 = 12'd0;
        Y21 = 12'd0;   Y22 = -12'd2; Y23 = -12'd4;  Y24 = 12'd1;  Y25 = 12'd1;  Y26 = 12'd0;  Y27 = 12'd0; Y28 = 12'd0;
        Y31 = -12'd3;  Y32 = 12'd1;  Y33 = 12'd5;   Y34 = -12'd1; Y35 = -12'd1; Y36 = 12'd0;  Y37 = 12'd0; Y38 = 12'd0;
        Y41 = -12'd3;  Y42 = 12'd1;  Y43 = 12'd2;   Y44 = -12'd1; Y45 = 12'd0;  Y46 = 12'd0;  Y47 = 12'd0; Y48 = 12'd0;
        Y51 = 12'd1;   Y52 = 12'd0;  Y53 = 12'd0;   Y54 = 12'd0;  Y55 = 12'd0;  Y56 = 12'd0;  Y57 = 12'd0; Y58 = 12'd0;
        Y61 = 12'd0;   Y62 = 12'd0;  Y63 = 12'd0;   Y64 = 12'd0;  Y65 = 12'd0;  Y66 = 12'd0;  Y67 = 12'd0; Y68 = 12'd0;
        Y71 = 12'd0;   Y72 = 12'd0;  Y73 = 12'd0;   Y74 = 12'd0;  Y75 = 12'd0;  Y76 = 12'd0;  Y77 = 12'd0; Y78 = 12'd0;
        Y81 = 12'd0;   Y82 = 12'd0;  Y83 = 12'd0;   Y84 = 12'd0;  Y85 = 12'd0;  Y86 = 12'd0;  Y87 = 12'd0; Y88 = 12'd0;
        @(negedge clk);
        enable = 0;
        
        // Chờ module xử lý xong toàn bộ block
        wait(end_of_block_output == 1);
        
        // Đợi thêm vài chu kỳ
        repeat(100000) @(posedge clk);
        
        $display("Simulation Finished.");
        $finish;
    end
endmodule