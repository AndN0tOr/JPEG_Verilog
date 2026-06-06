`timescale 1ns / 1ns
module color_trans_tb;
    reg clk, rst, enable;
    reg [23:0] data_in;
    wire out_enable;
    wire [23:0] data_out;
    color_trans modula(
        .clk(clk), 
        .rst(rst), 
        .enable(enable),
        .data_in(data_in), 
        .out_enable(out_enable), 
        .data_out(data_out)
        );
    always #5 clk = ~clk; 

    initial begin
        clk = 0;
        rst = 1;
        enable = 0;
        data_in = 24'd0;
        #30 
        rst = 0;
        #10
        enable = 1;
        data_in = {8'd255, 8'd255, 8'd255};
        // Pure white
        #10;
        data_in = {8'd0, 8'd0, 8'd0};
        // Pure black
        #10
        data_in = {8'd255, 8'd0, 8'd0};
        // Pure red
        #10 
        data_in = {8'd0, 8'd255, 8'd0};
        // Pure green
        #10
        data_in = {8'd0, 8'd0, 8'd255};
        // Pure blue
        #40
        enable = 0;
        $finish;
    end
    
    always @(posedge clk) begin
        if (out_enable)begin
            $display (
                "Time : %d ns | Valid Data! -> Y: %3d | Cb: %3d | Cr: %3d", 
                $time, data_out[23:16], data_out[15:8], data_out[7:0]);
        end
    end


endmodule