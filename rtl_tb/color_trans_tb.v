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
        #10
        data_in = {8'd37, 8'd142, 8'd219};

        #10
        data_in = {8'd201, 8'd54, 8'd87};

        #10
        data_in = {8'd16, 8'd231, 8'd104};

        #10
        data_in = {8'd245, 8'd173, 8'd29};

        #10
        data_in = {8'd92, 8'd41, 8'd198};

        #10
        data_in = {8'd134, 8'd217, 8'd63};

        #10
        data_in = {8'd255, 8'd96, 8'd12};

        #10
        data_in = {8'd73, 8'd188, 8'd240};

        #10
        data_in = {8'd159, 8'd22, 8'd116};

        #10
        data_in = {8'd48, 8'd245, 8'd176};

        #10
        data_in = {8'd224, 8'd118, 8'd67};
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