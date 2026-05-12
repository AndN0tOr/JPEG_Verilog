module compute_1d_dct(
    input rst,
    input clk,
    input [7:0] data_in,
    input [2:0] row, // Thực chất đây là chỉ số mẫu thời gian (n)
    output reg out_enable,
    output reg signed [11:0] dct_out0, dct_out1, dct_out2, dct_out3, dct_out4, dct_out5, dct_out6, dct_out7
);

reg signed [15:0] cos_value [0:7];
reg signed [26:0] dct_temp_sum [0:7];
reg delay;

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

// 1. SỬA LỖI MA TRẬN: Chuyển vị thành các CỘT thay vì HÀNG
always @(*) begin
    case (row)
        3'b000: begin // Cột 0 (Mẫu x0)
            cos_value[0] = cos0;  cos_value[1] = cos10; cos_value[2] = cos20; cos_value[3] = cos11;
            cos_value[4] = cos0;  cos_value[5] = cos12; cos_value[6] = cos21; cos_value[7] = cos13;
        end
        3'b001: begin // Cột 1 (Mẫu x1)
            cos_value[0] = cos0;  cos_value[1] = cos11; cos_value[2] = cos21; cos_value[3] = cos14;
            cos_value[4] = cos41; cos_value[5] = cos17; cos_value[6] = cos23; cos_value[7] = cos15;
        end
        3'b010: begin // Cột 2 (Mẫu x2)
            cos_value[0] = cos0;  cos_value[1] = cos12; cos_value[2] = cos22; cos_value[3] = cos17;
            cos_value[4] = cos41; cos_value[5] = cos15; cos_value[6] = cos20; cos_value[7] = cos11;
        end
        3'b011: begin // Cột 3 (Mẫu x3)
            cos_value[0] = cos0;  cos_value[1] = cos13; cos_value[2] = cos23; cos_value[3] = cos15;
            cos_value[4] = cos0;  cos_value[5] = cos11; cos_value[6] = cos22; cos_value[7] = cos17;
        end
        3'b100: begin // Cột 4 (Mẫu x4)
            cos_value[0] = cos0;  cos_value[1] = cos14; cos_value[2] = cos23; cos_value[3] = cos15;
            cos_value[4] = cos0;  cos_value[5] = cos11; cos_value[6] = cos22; cos_value[7] = cos17;
        end
        3'b101: begin // Cột 5 (Mẫu x5)
            cos_value[0] = cos0;  cos_value[1] = cos15; cos_value[2] = cos22; cos_value[3] = cos17;
            cos_value[4] = cos41; cos_value[5] = cos15; cos_value[6] = cos20; cos_value[7] = cos11;
        end
        3'b110: begin // Cột 6 (Mẫu x6)
            cos_value[0] = cos0;  cos_value[1] = cos16; cos_value[2] = cos21; cos_value[3] = cos14;
            cos_value[4] = cos41; cos_value[5] = cos17; cos_value[6] = cos23; cos_value[7] = cos15;
        end
        3'b111: begin // Cột 7 (Mẫu x7)
            cos_value[0] = cos0;  cos_value[1] = cos17; cos_value[2] = cos20; cos_value[3] = cos11;
            cos_value[4] = cos0;  cos_value[5] = cos12; cos_value[6] = cos21; cos_value[7] = cos13;
        end
        default: begin
            cos_value[0] = 0; cos_value[1] = 0; cos_value[2] = 0; cos_value[3] = 0; 
            cos_value[4] = 0; cos_value[5] = 0; cos_value[6] = 0; cos_value[7] = 0; 
        end
    endcase
end

// 2. Logic nhân cộng (Giữ nguyên cơ chế tự ghi đè nhịp đầu để không bị lỗi X)
integer i;
always @(posedge clk) begin
    if (row == 3'b000) begin
        // Nhịp đầu: Ghi đè để bỏ qua trạng thái X
        for (i=0; i<8; i=i+1) 
            dct_temp_sum[i] <= $signed({1'b0, data_in}) * cos_value[i];
    end else begin
        // Nhịp sau: Cộng dồn
        for (i=0; i<8; i=i+1) 
            dct_temp_sum[i] <= dct_temp_sum[i] + ($signed({1'b0, data_in}) * cos_value[i]);
    end
end

always @(posedge clk) begin
    delay <= (row == 3'b111);
    out_enable <= delay;
end

// 3. SỬA LỖI DỊCH BIT: Dịch chính xác 14 bit và có làm tròn (+ 8192)
always @(posedge clk) begin
    if (delay) begin 
        // 8192 là 2^13 (Dùng để làm tròn giá trị trước khi dịch phải 14 bit)
        dct_out0 <= (dct_temp_sum[0] + 8192) >>> 14;
        dct_out1 <= (dct_temp_sum[1] + 8192) >>> 14;
        dct_out2 <= (dct_temp_sum[2] + 8192) >>> 14;
        dct_out3 <= (dct_temp_sum[3] + 8192) >>> 14;
        dct_out4 <= (dct_temp_sum[4] + 8192) >>> 14;
        dct_out5 <= (dct_temp_sum[5] + 8192) >>> 14;
        dct_out6 <= (dct_temp_sum[6] + 8192) >>> 14;
        dct_out7 <= (dct_temp_sum[7] + 8192) >>> 14;
    end
end

endmodule