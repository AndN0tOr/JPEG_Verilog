typedef enum {
  IDLE,
  PROCESSING,
  VALID
} state_t;

module dct_1d #(
  parameter IN_WIDTH = 8 // Hỗ trợ 8-bit cho Hàng, 12-bit cho Cột
)(
  input logic     rst,
  input logic     clk,
  input logic     enable,
  input logic [IN_WIDTH-1:0]  data_in,
  output logic    out_valid,
  output logic    out_ready,
  output logic signed[11:0]   dct_out   [0:7]
);

  logic signed [15:0] cos_value [0:7];
  logic signed [26:0] dct_temp_sum [0:7];
  logic [2:0] index, next_index;
  logic delay;
  state_t state, next_state;

  // Các hệ số (Đã scale với 2^14 = 16384)
  localparam signed [15:0] cos0  = 5793;  // .3536
  localparam signed [15:0] cos10 = 8035;  // .4904
  localparam signed [15:0] cos11 = 6811;  // .4157
  localparam signed [15:0] cos12 = 4551;  // .2778
  localparam signed [15:0] cos13 = 1598;  // .0975
  localparam signed [15:0] cos14 = -1598; // -.0975
  localparam signed [15:0] cos15 = -4551; // -.2778
  localparam signed [15:0] cos16 = -6811; // -.4157
  localparam signed [15:0] cos17 = -8035; // -.4904
  localparam signed [15:0] cos20 = 7568;  // .4619
  localparam signed [15:0] cos21 = 3135;  // .1913
  localparam signed [15:0] cos22 = -3135; // -.1913
  localparam signed [15:0] cos23 = -7568; // -.4619
  localparam signed [15:0] cos41 = -5793; // -.3536

  wire signed [15:0] s_data_in;
  assign s_data_in = $signed(data_in);

  always_comb begin : next_index_logic
    case(index) 
      3'b000:
      begin 
        if (enable) begin
          next_index = 3'b001;
        end else begin
          next_index = 3'b000;
        end
      end
      3'b001: next_index = 3'b010;
      3'b010: next_index = 3'b011;
      3'b011: next_index = 3'b100;
      3'b100: next_index = 3'b101;
      3'b101: next_index = 3'b110;
      3'b110: next_index = 3'b111;
      3'b111: 
      begin
        if (out_ready && out_valid) begin
          next_index = 3'b000;
        end
      end
      default: next_index = 3'b000;
    endcase
  end
  always_ff @(posedge clk or posedge rst ) begin : index_fsm
    if (rst) begin
      index <= 3'b0;
    end else begin
      index <= next_index;
    end
  end

  always_comb begin : next_state_logic
    case(state)
      IDLE: begin
        if (enable) begin
          next_state = PROCESSING;
        end 
      end
      PROCESSING: begin
        if (index == 3'b111) begin
          next_state = VALID;
        end
      end
      VALID: begin
        out_valid = 1'b1;
        if (out_ready) begin
          next_state = IDLE;
        end
      end
    endcase
  end

  always_ff @(posedge clk or posedge rst) begin : ctrl_fsm
    if (rst) begin
      state = IDLE;
    end else begin
      state = next_state;
    end
  end
  // Bảng LUT hệ số Cosine (Giữ nguyên logic của bạn)
  always_comb begin : cos_LUT_mapping
    case (index)
    3'b000: begin 
      cos_value[0] = cos0;  cos_value[1] = cos10; cos_value[2] = cos20; cos_value[3] = cos11;
      cos_value[4] = cos0;  cos_value[5] = cos12; cos_value[6] = cos21; cos_value[7] = cos13;
    end
    3'b001: begin 
      cos_value[0] = cos0;  cos_value[1] = cos11; cos_value[2] = cos21; cos_value[3] = cos14;
      cos_value[4] = cos41; cos_value[5] = cos17; cos_value[6] = cos23; cos_value[7] = cos15;
    end
    3'b010: begin 
      cos_value[0] = cos0;  cos_value[1] = cos12; cos_value[2] = cos22; cos_value[3] = cos17;
      cos_value[4] = cos41; cos_value[5] = cos13; cos_value[6] = cos20; cos_value[7] = cos11;
    end
    3'b011: begin 
      cos_value[0] = cos0;  cos_value[1] = cos13; cos_value[2] = cos23; cos_value[3] = cos15;
      cos_value[4] = cos0;  cos_value[5] = cos11; cos_value[6] = cos22; cos_value[7] = cos17;
    end
    3'b100: begin 
      cos_value[0] = cos0;  cos_value[1] = cos14; cos_value[2] = cos23; cos_value[3] = cos12;
      cos_value[4] = cos0;  cos_value[5] = cos16; cos_value[6] = cos22; cos_value[7] = cos10;
    end
    3'b101: begin 
      cos_value[0] = cos0;  cos_value[1] = cos15; cos_value[2] = cos22; cos_value[3] = cos10;
      cos_value[4] = cos41; cos_value[5] = cos14; cos_value[6] = cos20; cos_value[7] = cos16;
    end
    3'b110: begin
      cos_value[0] = cos0;  cos_value[1] = cos16; cos_value[2] = cos21; cos_value[3] = cos13;
      cos_value[4] = cos41; cos_value[5] = cos10; cos_value[6] = cos23; cos_value[7] = cos12;
    end
    3'b111: begin 
      cos_value[0] = cos0;  cos_value[1] = cos17; cos_value[2] = cos20; cos_value[3] = cos16;
      cos_value[4] = cos0;  cos_value[5] = cos15; cos_value[6] = cos21; cos_value[7] = cos14;
    end
    default: begin
      foreach (cos_value[i]) begin
        cos_value[i] = 16'b0;
      end
    end
  endcase
  end

  integer i;

  // Toàn bộ logic Tuần tự (Sequential) được gộp vào 1 khối duy nhất
  always_ff @(posedge clk or posedge rst) begin
    if (state == IDLE) begin
      foreach(dct_temp_sum[i]) begin
        dct_temp_sum[i] <= 27'b0;
      end
    end else 
    if (state == PROCESSING) begin
      if (index == 3'b000) begin
        foreach (dct_temp_sum[i]) begin
          dct_temp_sum[i] <= s_data_in * cos_value[i]; // Tự động reset bộ đếm khi index = 0
        end
      end else begin
        foreach (dct_temp_sum[i]) begin
          dct_temp_sum[i] <= dct_temp_sum[i] + (s_data_in * cos_value[i]);
        end
      end
    end

    // 3. Logic Làm tròn và Dịch bit (Shifting & Rounding)
    if (out_valid) begin 
      foreach(dct_out[i]) begin
        dct_out[i] <= dct_temp_sum[i][13] ? dct_temp_sum[i][26:14] + 1 : dct_temp_sum[i][26:14];
      end
    end
  end
endmodule