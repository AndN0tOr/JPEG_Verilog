`timescale 1ns/1ns
module dct_1d_tb;
  logic clk;
  logic [7:0] data_in;
  logic reset;
  logic enable;
  logic [2:0] index;
  logic out_enable;
  logic signed [11:0] dct_out[0:7];
  dct_1d #(
      .IN_WIDTH(8)
  ) uut (
      .clk(clk),
      .rst(reset),
      .enable(enable),
      .data_in(data_in),
      .index(index),
      .out_enable(out_enable),
      .dct_out(dct_out)
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
      $time, index, dct_out[0], dct_out[1], dct_out[2], dct_out[3], dct_out[4], dct_out[5], dct_out[6], dct_out[7], out_enable);    
      data_in = 8'd55; // Max input data
      index = 3'b001; // Next index index

      #10;
      $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b",
      $time, index, dct_out[0], dct_out[1], dct_out[2], dct_out[3], dct_out[4], dct_out[5], dct_out[6], dct_out[7], out_enable);    
      data_in = 8'd61; // Another example input
      index = 3'b010; // Next index index

      #10;
      $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
      $time, index, dct_out[0], dct_out[1], dct_out[2], dct_out[3], dct_out[4], dct_out[5], dct_out[6], dct_out[7], out_enable);    
      data_in = 8'd66; // Another example input
      index = 3'b011; // Next index index

      #10;
      $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
      $time, index, dct_out[0], dct_out[1], dct_out[2], dct_out[3], dct_out[4], dct_out[5], dct_out[6], dct_out[7], out_enable);    
      data_in = 8'd70; // Another example input
      index = 3'b100; // Next index index

      #10;
      $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
      $time, index, dct_out[0], dct_out[1], dct_out[2], dct_out[3], dct_out[4], dct_out[5], dct_out[6], dct_out[7], out_enable);    
      data_in = 8'd61; // Another example input
      index = 3'b101; // Next index index

      #10;
      $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
      $time, index, dct_out[0], dct_out[1], dct_out[2], dct_out[3], dct_out[4], dct_out[5], dct_out[6], dct_out[7], out_enable);    
      data_in = 8'd64; // Another example input
      index = 3'b110; // Next index index

      #10;
      $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
      $time, index, dct_out[0], dct_out[1], dct_out[2], dct_out[3], dct_out[4], dct_out[5], dct_out[6], dct_out[7], out_enable);    
      data_in = 8'd73; // Another example input
      index = 3'b111; // Next index index

      #10;
      $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
      $time, index, dct_out[0], dct_out[1], dct_out[2], dct_out[3], dct_out[4], dct_out[5], dct_out[6], dct_out[7], out_enable);    
      // Finish simulation
      index = 3'b000;
      data_in = 8'd52;
      #10;
      $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
      $time, index, dct_out[0], dct_out[1], dct_out[2], dct_out[3], dct_out[4], dct_out[5], dct_out[6], dct_out[7], out_enable);    
      index = 3'b001;
      data_in = 8'd55;

      #10;
      $display("Time: %t, DCT Outputs for index %b: %d, %d, %d, %d, %d, %d, %d, %d, out_enable: %b", 
      $time, index, dct_out[0], dct_out[1], dct_out[2], dct_out[3], dct_out[4], dct_out[5], dct_out[6], dct_out[7], out_enable);    
      
      $finish;
  end

endmodule