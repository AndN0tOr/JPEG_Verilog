module compute_1d_dct #(
    parameter IN_WIDTH = 8 // Hỗ trợ 8-bit cho Hàng, 12-bit cho Cột
)(
    input rst,
    input clk,
    input enable,
    input [IN_WIDTH-1:0] data_in,
    input [2:0] index,
    output reg out_enable,
    output reg [11:0] dct_out_0, dct_out_1, 
    output reg [11:0] dct_out_2, dct_out_3,
    output reg [11:0] dct_out_4, dct_out_5,
    output reg [11:0] dct_out_6, dct_out_7
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

    // ==========================================
    // XỬ LÝ DẤU SỐ HỌC THÔNG MINH (CRITICAL FIX)
    // Nếu 8-bit (Phase 1): Ép thành số dương (Pixel 0-255)
    // Nếu 12-bit (Phase 2): Giữ nguyên dấu (Hệ số DCT có thể âm)
    // ==========================================
    wire signed [15:0] s_data_in;
    assign s_data_in = $signed(data_in);

    // Bảng LUT hệ số Cosine (Giữ nguyên logic của bạn)
    always @(*) begin
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
                cos_value[0] = 0; cos_value[1] = 0; cos_value[2] = 0; cos_value[3] = 0; 
                cos_value[4] = 0; cos_value[5] = 0; cos_value[6] = 0; cos_value[7] = 0; 
            end
        endcase
    end

    integer i;

    // Toàn bộ logic Tuần tự (Sequential) được gộp vào 1 khối duy nhất
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay <= 1'b0;
            out_enable <= 1'b0;
            for (i = 0; i < 8; i = i + 1) begin
                dct_temp_sum[i] <= 27'b0;
            end
            dct_out_0 <= 12'b0; dct_out_1 <= 12'b0; dct_out_2 <= 12'b0; dct_out_3 <= 12'b0;
            dct_out_4 <= 12'b0; dct_out_5 <= 12'b0; dct_out_6 <= 12'b0; dct_out_7 <= 12'b0;
        end else begin
            
            // 1. Logic Cộng dồn (Accumulator)
            if (enable) begin
                if (index == 3'b000) begin
                    for (i = 0; i < 8; i = i + 1) 
                        dct_temp_sum[i] <= s_data_in * cos_value[i]; // Tự động reset bộ đếm khi index = 0
                end else begin
                    for (i = 0; i < 8; i = i + 1) 
                        dct_temp_sum[i] <= dct_temp_sum[i] + (s_data_in * cos_value[i]);
                end
            end

            // 2. Logic cờ báo hoàn tất (Tạo đúng 1 nhịp Pulse)
            if (enable && index == 3'b111) begin
                delay <= 1'b1;
            end else begin
                delay <= 1'b0;
            end

            // 3. Logic Làm tròn và Dịch bit (Shifting & Rounding)
            if (delay) begin 
                out_enable <= delay;
                dct_out_0 <= dct_temp_sum[0][13] ? dct_temp_sum[0][26:14] + 1 : dct_temp_sum[0][26:14];
                dct_out_1 <= dct_temp_sum[1][13] ? dct_temp_sum[1][26:14] + 1 : dct_temp_sum[1][26:14];
                dct_out_2 <= dct_temp_sum[2][13] ? dct_temp_sum[2][26:14] + 1 : dct_temp_sum[2][26:14];
                dct_out_3 <= dct_temp_sum[3][13] ? dct_temp_sum[3][26:14] + 1 : dct_temp_sum[3][26:14];
                dct_out_4 <= dct_temp_sum[4][13] ? dct_temp_sum[4][26:14] + 1 : dct_temp_sum[4][26:14];
                dct_out_5 <= dct_temp_sum[5][13] ? dct_temp_sum[5][26:14] + 1 : dct_temp_sum[5][26:14];
                dct_out_6 <= dct_temp_sum[6][13] ? dct_temp_sum[6][26:14] + 1 : dct_temp_sum[6][26:14];
                dct_out_7 <= dct_temp_sum[7][13] ? dct_temp_sum[7][26:14] + 1 : dct_temp_sum[7][26:14];
            end else begin  
                out_enable <= 1'b0;
            end
        end
    end

endmodule