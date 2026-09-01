`timescale 1ns/1ns

module dct_1d_tb;
  logic clk;
  logic reset;
  logic enable;
  logic [7:0] data_in;
  logic out_valid;
  logic out_ready;
  logic signed [11:0] dct_out [0:7];

  // 1. Khởi tạo module (DUT - Design Under Test)
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

  // 2. Tạo xung Clock (Tần số 100MHz -> Chu kỳ 10ns)
  always #5 clk = ~clk;

  // 3. Khai báo các kịch bản kiểm tra (Test Cases)
  localparam NUM_TESTS = 4;
  logic [7:0] test_cases [0:NUM_TESTS-1][0:7] = '{
    '{8'd52,  8'd55,  8'd61,  8'd66,  8'd70,  8'd61,  8'd64,  8'd73}, // TC1: Dữ liệu mẫu ngẫu nhiên của bạn
    '{8'd10,  8'd10,  8'd10,  8'd10,  8'd10,  8'd10,  8'd10,  8'd10}, // TC2: Thành phần DC (các mẫu đều giống hệt nhau)
    '{8'd255, 8'd0,   8'd255, 8'd0,   8'd255, 8'd0,   8'd255, 8'd0},  // TC3: Tần số cao (Thay đổi tối đa liên tục)
    '{8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0,   8'd0}   // TC4: Mảng giá trị 0
  };

  // 4. Task tự động hóa: Chạy 1 chuỗi 8 điểm dữ liệu và lấy kết quả
  task run_test_case(input int test_idx, input logic [7:0] data_test [0:7]);
    $display("--- Started Test Case %0d at %0t ---", test_idx, $time);
    
    // Bơm tuần tự 8 mẫu dữ liệu vào phần cứng
    for (int i = 0; i < 8; i++) begin
      @(negedge clk); // Đưa dữ liệu vào ở cạnh xuống (negedge) để dữ liệu ổn định trước khi DUT chốt ở sườn lên
      data_in = data_test[i];
      if (i == 0) enable = 1'b1; // Chỉ kích hoạt enable ở mẫu dữ liệu đầu tiên (D0)
      else enable = 1'b0; 
    end
    
    // Treo chờ cho đến khi cờ out_valid từ DUT báo dữ liệu đã sẵn sàng
    wait(out_valid == 1'b1);
    @(posedge clk);
    @(posedge clk);
    // In kết quả
    $display("Input Data: %p", data_test);
    $display("DCT : %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d", 
             dct_out[0], dct_out[1], dct_out[2], dct_out[3], 
             dct_out[4], dct_out[5], dct_out[6], dct_out[7]);
    $display("--------------------------------------------------\n");

    // Handshake: Phản hồi tín hiệu out_ready = 1 để DUT biết bộ nhận đã lấy dữ liệu, quay lại IDLE
    @(negedge clk);
    out_ready = 1'b1;
    
    @(negedge clk);
    out_ready = 1'b0;
    
    // Nghỉ 2 chu kỳ clock cho giãn cách trước khi chạy bài test tiếp theo
    repeat(2) @(negedge clk);
  endtask

  // 5. Khối điều khiển chính (Orchestrator)
  initial begin
    // Khởi tạo các tín hiệu ban đầu
    clk = 0;
    reset = 1;
    enable = 0;
    data_in = 0;
    out_ready = 0;

    // Đợi ổn định, sau đó hạ reset
    repeat(4) @(negedge clk);
    reset = 0;
    repeat(2) @(negedge clk);

    // Vòng lặp For chạy tự động qua toàn bộ Test Cases đã cấu hình
    for (int i = 0; i < NUM_TESTS; i++) begin
      run_test_case(i, test_cases[i]);
    end

    // Kết thúc mô phỏng
    $display("=== Completed Test Cases at %0t ===", $time);
    $finish;
  end

endmodule


