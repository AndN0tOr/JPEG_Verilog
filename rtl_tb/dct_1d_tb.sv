`timescale 1ns/1ns

module dct_1d_tb;
  logic clk;
  logic reset;
  logic enable;
  logic [7:0] data_in;
  logic out_valid;
  logic out_ready;
  logic signed [11:0] dct_out [0:7];

  
  dct_1d #(
      .IN_WIDTH(8)
  ) uut (
      .clk(clk),
      .rst(reset),
      .enable(enable),
      .data_in(data_in),
      .out_valid(out_valid),
      .out_ready(out_ready),
      .dct_out(dct_out)
  );

  always #5 clk = ~clk;

  
  localparam NUM_TESTS = 4;
  logic [7:0] test_cases [0:NUM_TESTS-1][0:7] = '{
    '{8'd52,  8'd55,  8'd61,  8'd66,  8'd70,  8'd61,  8'd64,  8'd73}, // TC1: Dữ liệu mẫu ngẫu nhiên của bạn
    '{8'd10,  8'd10,  8'd10,  8'd10,  8'd10,  8'd10,  8'd10,  8'd10}, // TC2: Thành phần DC (các mẫu đều giống hệt nhau)
    '{8'd255, 8'd0,   8'd255, 8'd0,   8'd255, 8'd0,   8'd255, 8'd0},  // TC3: Tần số cao (Thay đổi tối đa liên tục)
    '{8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0}   // TC4: Mảng giá trị 0
  };

  
  task run_test_case(input int test_idx, input logic [7:0] data_test [0:7]);
    $display("--- Started Test Case %0d at %0t ---", test_idx, $time);
    
    // Bơm tuần tự 8 mẫu dữ liệu vào phần cứng
    for (int i = 0; i < 8; i++) begin
      @(negedge clk); 
      data_in = data_test[i];
      if (i == 0) enable = 1'b1; 
      else enable = 1'b0; 
    end
    
    wait(out_valid == 1'b1);
    @(posedge clk);
    @(posedge clk);
    // In kết quả
    $display("Input Data: %p", data_test);
    $display("DCT : %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d", 
             dct_out[0], dct_out[1], dct_out[2], dct_out[3], 
             dct_out[4], dct_out[5], dct_out[6], dct_out[7]);
    $display("--------------------------------------------------\n");

    
    @(negedge clk);
    out_ready = 1'b1;
    
    @(negedge clk);
    out_ready = 1'b0;
    
    repeat(2) @(negedge clk);
  endtask

  initial begin
    clk = 0;
    reset = 1;
    enable = 0;
    data_in = 0;
    out_ready = 0;

    repeat(4) @(negedge clk);
    reset = 0;
    repeat(2) @(negedge clk);

    for (int i = 0; i < NUM_TESTS; i++) begin
      run_test_case(i, test_cases[i]);
    end
    $display("=== Completed Test Cases at %0t ===", $time);
    $finish;
  end

endmodule


