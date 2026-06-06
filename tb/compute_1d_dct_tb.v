`timescale 1ns/1ns
module compute_1d_dct_tb;
reg clk;
reg [7:0] data_in;
reg reset;
reg enable;
reg [2:0] index;
wire out_enable;
wire signed [11:0] dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7;
compute_1d_dct #(
    .IN_WIDTH(8)
) uut (
    .clk(clk),
    .rst(reset),
    .enable(enable),
    .data_in(data_in),
    .index(index),
    .out_enable(out_enable),
    .dct_out_0(dct_out_0), .dct_out_1(dct_out_1), .dct_out_2(dct_out_2), .dct_out_3(dct_out_3),
    .dct_out_4(dct_out_4), .dct_out_5(dct_out_5), .dct_out_6(dct_out_6), .dct_out_7(dct_out_7)
);
always #5 clk = ~clk;
initial begin
    // Initialize inputs
    clk = 0;
    reset = 1;
    index = 0;
    enable = 0;
    data_in = 0;
    #20; // Wait for 20 ns
    reset = 0; // Deassert reset

    enable = 1;
    data_in = 8'd52; // Example input data
    index = 3'b000; // Example index index

    // Wait for some time and change inputs to test different cases
    #10;
    $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, index, dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7, out_enable);    
    data_in = 8'd55; // Max input data
    index = 3'b001; // Next index index

    #10;
    $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b",
    $time, index, dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7, out_enable);    
    data_in = 8'd61; // Another example input
    index = 3'b010; // Next index index

    #10;
    $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, index, dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7, out_enable);    
    data_in = 8'd66; // Another example input
    index = 3'b011; // Next index index

    #10;
    $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, index, dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7, out_enable);    
    data_in = 8'd70; // Another example input
    index = 3'b100; // Next index index

    #10;
    $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, index, dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7, out_enable);    
    data_in = 8'd61; // Another example input
    index = 3'b101; // Next index index

    #10;
    $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, index, dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7, out_enable);    
    data_in = 8'd64; // Another example input
    index = 3'b110; // Next index index

    #10;
    $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, index, dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7, out_enable);    
    data_in = 8'd73; // Another example input
    index = 3'b111; // Next index index

    #10;
    $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, index, dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7, out_enable);
    // Finish simulation
    index = 3'b000;
    data_in = 8'd52;
    #10;
    $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, index, dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7, out_enable);
    index = 3'b001;
    data_in = 8'd55;

    #10;
    $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, index, dct_out_0, dct_out_1, dct_out_2, dct_out_3, dct_out_4, dct_out_5, dct_out_6, dct_out_7, out_enable);
    
    $finish;
end

endmodule