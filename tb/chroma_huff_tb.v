`timescale 1ns/1ps

module chroma_huff_tb;
    reg clk, rst, enable;
    reg [11:0] C11, C12, C13, C14, C15, C16, C17, C18, 
    C21, C22, C23, C24, C25, C26, C27, C28,
    C31, C32, C33, C34, C35, C36, C37, C38, 
    C41, C42, C43, C44, C45, C46, C47, C48,
    C51, C52, C53, C54, C55, C56, C57, C58, 
    C61, C62, C63, C64, C65, C66, C67, C68,
    C71, C72, C73, C74, C75, C76, C77, C78, 
    C81, C82, C83, C84, C85, C86, C87, C88;
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
    chroma_huff uut(
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .C11(C11), .C12(C12), .C13(C13), .C14(C14), .C15(C15), .C16(C16), .C17(C17), .C18(C18), 
        .C21(C21), .C22(C22), .C23(C23), .C24(C24), .C25(C25), .C26(C26), .C27(C27), .C28(C28),
        .C31(C31), .C32(C32), .C33(C33), .C34(C34), .C35(C35), .C36(C36), .C37(C37), .C38(C38), 
        .C41(C41), .C42(C42), .C43(C43), .C44(C44), .C45(C45), .C46(C46), .C47(C47), .C48(C48),
        .C51(C51), .C52(C52), .C53(C53), .C54(C54), .C55(C55), .C56(C56), .C57(C57), .C58(C58), 
        .C61(C61), .C62(C62), .C63(C63), .C64(C64), .C65(C65), .C66(C66), .C67(C67), .C68(C68),
        .C71(C71), .C72(C72), .C73(C73), .C74(C74), .C75(C75), .C76(C76), .C77(C77), .C78(C78), 
        .C81(C81), .C82(C82), .C83(C83), .C84(C84), .C85(C85), .C86(C86), .C87(C87), .C88(C88),
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
        C11 = -12'd26; C12 = -12'd3;  C13 = -12'd6;  C14 = 12'd2;  C15 = 12'd2;  C16 = -12'd1; C17 = 12'd0; C18 = 12'd0;
        C21 = 12'd0;   C22 = -12'd2; C23 = -12'd4;  C24 = 12'd1;  C25 = 12'd1;  C26 = 12'd0;  C27 = 12'd0; C28 = 12'd0;
        C31 = -12'd3;  C32 = 12'd1;  C33 = 12'd5;   C34 = -12'd1; C35 = -12'd1; C36 = 12'd0;  C37 = 12'd0; C38 = 12'd0;
        C41 = -12'd3;  C42 = 12'd1;  C43 = 12'd2;   C44 = -12'd1; C45 = 12'd0;  C46 = 12'd0;  C47 = 12'd0; C48 = 12'd0;
        C51 = 12'd1;   C52 = 12'd0;  C53 = 12'd0;   C54 = 12'd0;  C55 = 12'd0;  C56 = 12'd0;  C57 = 12'd0; C58 = 12'd0;
        C61 = 12'd0;   C62 = 12'd0;  C63 = 12'd0;   C64 = 12'd0;  C65 = 12'd0;  C66 = 12'd0;  C67 = 12'd0; C68 = 12'd0;
        C71 = 12'd0;   C72 = 12'd0;  C73 = 12'd0;   C74 = 12'd0;  C75 = 12'd0;  C76 = 12'd0;  C77 = 12'd0; C78 = 12'd0;
        C81 = 12'd0;   C82 = 12'd0;  C83 = 12'd0;   C84 = 12'd0;  C85 = 12'd0;  C86 = 12'd0;  C87 = 12'd0; C88 = 12'd0;
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