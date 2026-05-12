`timescale 1ns/1ns
module compute_1d_dct_tb;
reg clk;
reg [7:0] data_in;
reg reset;
reg [2:0] row;
wire out_enable;
wire signed [11:0] dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7;
compute_1d_dct uut (
    .clk(clk),
    .rst(reset),
    .data_in(data_in),
    .row(row),
    .out_enable(out_enable),
    .dct_out0(dct_out0), .dct_out1(dct_out1), .dct_out2(dct_out2), .dct_out3(dct_out3),
    .dct_out4(dct_out4), .dct_out5(dct_out5), .dct_out6(dct_out6), .dct_out7(dct_out7)
);
always #5 clk = ~clk;
initial begin
    // Initialize inputs
    clk = 0;
    reset = 1;
    row = 0;
    data_in = 0;
    #20; // Wait for 20 ns
    reset = 0; // Deassert reset

    data_in = 8'd52; // Example input data
    row = 3'b000; // Example row index

    // Wait for some time and change inputs to test different cases
    #10;
    $display("Time: %t, DCT Outputs for row %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, row, dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7, out_enable);    
    data_in = 8'd55; // Max input data
    row = 3'b001; // Next row index

    #10;
    $display("Time: %t, DCT Outputs for row %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b",
    $time, row, dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7, out_enable);    
    data_in = 8'd61; // Another example input
    row = 3'b010; // Next row index

    #10;
    $display("Time: %t, DCT Outputs for row %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, row, dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7, out_enable);    
    data_in = 8'd66; // Another example input
    row = 3'b011; // Next row index

    #10;
    $display("Time: %t, DCT Outputs for row %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, row, dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7, out_enable);    
    data_in = 8'd70; // Another example input
    row = 3'b100; // Next row index

    #10;
    $display("Time: %t, DCT Outputs for row %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, row, dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7, out_enable);    
    data_in = 8'd61; // Another example input
    row = 3'b101; // Next row index

    #10;
    $display("Time: %t, DCT Outputs for row %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, row, dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7, out_enable);    
    data_in = 8'd64; // Another example input
    row = 3'b110; // Next row index

    #10;
    $display("Time: %t, DCT Outputs for row %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, row, dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7, out_enable);    
    data_in = 8'd73; // Another example input
    row = 3'b111; // Next row index

    #10;
    $display("Time: %t, DCT Outputs for row %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, row, dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7, out_enable);
    // Finish simulation
    #10;
    $display("Time: %t, DCT Outputs for row %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, row, dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7, out_enable);


    #10;
    $display("Time: %t, DCT Outputs for row %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
    $time, row, dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7, out_enable);
    $finish;
end

endmodule