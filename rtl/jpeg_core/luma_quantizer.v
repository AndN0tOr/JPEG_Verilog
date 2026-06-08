module luma_quantizer(
    input clk, rst, enable,
    // Ngõ vào giữ nguyên giao diện
    input [11:0] Z11, Z12, Z13, Z14, Z15, Z16, Z17, Z18, Z21, Z22, Z23, Z24, Z25, Z26, Z27, Z28,
    input [11:0] Z31, Z32, Z33, Z34, Z35, Z36, Z37, Z38, Z41, Z42, Z43, Z44, Z45, Z46, Z47, Z48,
    input [11:0] Z51, Z52, Z53, Z54, Z55, Z56, Z57, Z58, Z61, Z62, Z63, Z64, Z65, Z66, Z67, Z68,
    input [11:0] Z71, Z72, Z73, Z74, Z75, Z76, Z77, Z78, Z81, Z82, Z83, Z84, Z85, Z86, Z87, Z88,
    // Ngõ ra giữ nguyên giao diện
    output [11:0] Q11, Q12, Q13, Q14, Q15, Q16, Q17, Q18, Q21, Q22, Q23, Q24, Q25, Q26, Q27, Q28,
    output [11:0] Q31, Q32, Q33, Q34, Q35, Q36, Q37, Q38, Q41, Q42, Q43, Q44, Q45, Q46, Q47, Q48,
    output [11:0] Q51, Q52, Q53, Q54, Q55, Q56, Q57, Q58, Q61, Q62, Q63, Q64, Q65, Q66, Q67, Q68,
    output [11:0] Q71, Q72, Q73, Q74, Q75, Q76, Q77, Q78, Q81, Q82, Q83, Q84, Q85, Q86, Q87, Q88,
    output reg out_enable
);

// -----------------------------------------------------------------------------
// 1. PARAMETERS 
// This quantization table implies standard quantization for quality level 50 for Y component 
// -----------------------------------------------------------------------------
parameter Q1_1=16, Q1_2=11, Q1_3=10, Q1_4=16, Q1_5=24, Q1_6=40, Q1_7=51, Q1_8=61;
parameter Q2_1=12, Q2_2=12, Q2_3=14, Q2_4=19, Q2_5=26, Q2_6=58, Q2_7=60, Q2_8=55;
parameter Q3_1=14, Q3_2=13, Q3_3=16, Q3_4=24, Q3_5=40, Q3_6=57, Q3_7=69, Q3_8=56;
parameter Q4_1=14, Q4_2=17, Q4_3=22, Q4_4=29, Q4_5=51, Q4_6=87, Q4_7=80, Q4_8=62;
parameter Q5_1=18, Q5_2=22, Q5_3=37, Q5_4=56, Q5_5=68, Q5_6=109, Q5_7=103, Q5_8=77;
parameter Q6_1=24, Q6_2=35, Q6_3=55, Q6_4=64, Q6_5=81, Q6_6=104, Q6_7=113, Q6_8=92;
parameter Q7_1=49, Q7_2=64, Q7_3=78, Q7_4=87, Q7_5=103, Q7_6=121, Q7_7=120, Q7_8=101;
parameter Q8_1=72, Q8_2=92, Q8_3=95, Q8_4=98, Q8_5=112, Q8_6=100, Q8_7=103, Q8_8=99;

parameter QQ1_1=4096/Q1_1, QQ1_2=4096/Q1_2, QQ1_3=4096/Q1_3, QQ1_4=4096/Q1_4, QQ1_5=4096/Q1_5, QQ1_6=4096/Q1_6, QQ1_7=4096/Q1_7, QQ1_8=4096/Q1_8;
parameter QQ2_1=4096/Q2_1, QQ2_2=4096/Q2_2, QQ2_3=4096/Q2_3, QQ2_4=4096/Q2_4, QQ2_5=4096/Q2_5, QQ2_6=4096/Q2_6, QQ2_7=4096/Q2_7, QQ2_8=4096/Q2_8;
parameter QQ3_1=4096/Q3_1, QQ3_2=4096/Q3_2, QQ3_3=4096/Q3_3, QQ3_4=4096/Q3_4, QQ3_5=4096/Q3_5, QQ3_6=4096/Q3_6, QQ3_7=4096/Q3_7, QQ3_8=4096/Q3_8;
parameter QQ4_1=4096/Q4_1, QQ4_2=4096/Q4_2, QQ4_3=4096/Q4_3, QQ4_4=4096/Q4_4, QQ4_5=4096/Q4_5, QQ4_6=4096/Q4_6, QQ4_7=4096/Q4_7, QQ4_8=4096/Q4_8;
parameter QQ5_1=4096/Q5_1, QQ5_2=4096/Q5_2, QQ5_3=4096/Q5_3, QQ5_4=4096/Q5_4, QQ5_5=4096/Q5_5, QQ5_6=4096/Q5_6, QQ5_7=4096/Q5_7, QQ5_8=4096/Q5_8;
parameter QQ6_1=4096/Q6_1, QQ6_2=4096/Q6_2, QQ6_3=4096/Q6_3, QQ6_4=4096/Q6_4, QQ6_5=4096/Q6_5, QQ6_6=4096/Q6_6, QQ6_7=4096/Q6_7, QQ6_8=4096/Q6_8;
parameter QQ7_1=4096/Q7_1, QQ7_2=4096/Q7_2, QQ7_3=4096/Q7_3, QQ7_4=4096/Q7_4, QQ7_5=4096/Q7_5, QQ7_6=4096/Q7_6, QQ7_7=4096/Q7_7, QQ7_8=4096/Q7_8;
parameter QQ8_1=4096/Q8_1, QQ8_2=4096/Q8_2, QQ8_3=4096/Q8_3, QQ8_4=4096/Q8_4, QQ8_5=4096/Q8_5, QQ8_6=4096/Q8_6, QQ8_7=4096/Q8_7, QQ8_8=4096/Q8_8;

// -----------------------------------------------------------------------------
// 2. MAP INPUTS VÀ MULTIPLIERS VÀO MẢNG (ARRAY)
// -----------------------------------------------------------------------------
wire [11:0] Z_in [0:63];
assign Z_in[0]=Z11; assign Z_in[1]=Z12; assign Z_in[2]=Z13; assign Z_in[3]=Z14; assign Z_in[4]=Z15; assign Z_in[5]=Z16; assign Z_in[6]=Z17; assign Z_in[7]=Z18;
assign Z_in[8]=Z21; assign Z_in[9]=Z22; assign Z_in[10]=Z23; assign Z_in[11]=Z24; assign Z_in[12]=Z25; assign Z_in[13]=Z26; assign Z_in[14]=Z27; assign Z_in[15]=Z28;
assign Z_in[16]=Z31; assign Z_in[17]=Z32; assign Z_in[18]=Z33; assign Z_in[19]=Z34; assign Z_in[20]=Z35; assign Z_in[21]=Z36; assign Z_in[22]=Z37; assign Z_in[23]=Z38;
assign Z_in[24]=Z41; assign Z_in[25]=Z42; assign Z_in[26]=Z43; assign Z_in[27]=Z44; assign Z_in[28]=Z45; assign Z_in[29]=Z46; assign Z_in[30]=Z47; assign Z_in[31]=Z48;
assign Z_in[32]=Z51; assign Z_in[33]=Z52; assign Z_in[34]=Z53; assign Z_in[35]=Z54; assign Z_in[36]=Z55; assign Z_in[37]=Z56; assign Z_in[38]=Z57; assign Z_in[39]=Z58;
assign Z_in[40]=Z61; assign Z_in[41]=Z62; assign Z_in[42]=Z63; assign Z_in[43]=Z64; assign Z_in[44]=Z65; assign Z_in[45]=Z66; assign Z_in[46]=Z67; assign Z_in[47]=Z68;
assign Z_in[48]=Z71; assign Z_in[49]=Z72; assign Z_in[50]=Z73; assign Z_in[51]=Z74; assign Z_in[52]=Z75; assign Z_in[53]=Z76; assign Z_in[54]=Z77; assign Z_in[55]=Z78;
assign Z_in[56]=Z81; assign Z_in[57]=Z82; assign Z_in[58]=Z83; assign Z_in[59]=Z84; assign Z_in[60]=Z85; assign Z_in[61]=Z86; assign Z_in[62]=Z87; assign Z_in[63]=Z88;

wire [13:0] QM [0:63];
assign QM[0]=QQ1_1; assign QM[1]=QQ1_2; assign QM[2]=QQ1_3; assign QM[3]=QQ1_4; assign QM[4]=QQ1_5; assign QM[5]=QQ1_6; assign QM[6]=QQ1_7; assign QM[7]=QQ1_8;
assign QM[8]=QQ2_1; assign QM[9]=QQ2_2; assign QM[10]=QQ2_3; assign QM[11]=QQ2_4; assign QM[12]=QQ2_5; assign QM[13]=QQ2_6; assign QM[14]=QQ2_7; assign QM[15]=QQ2_8;
assign QM[16]=QQ3_1; assign QM[17]=QQ3_2; assign QM[18]=QQ3_3; assign QM[19]=QQ3_4; assign QM[20]=QQ3_5; assign QM[21]=QQ3_6; assign QM[22]=QQ3_7; assign QM[23]=QQ3_8;
assign QM[24]=QQ4_1; assign QM[25]=QQ4_2; assign QM[26]=QQ4_3; assign QM[27]=QQ4_4; assign QM[28]=QQ4_5; assign QM[29]=QQ4_6; assign QM[30]=QQ4_7; assign QM[31]=QQ4_8;
assign QM[32]=QQ5_1; assign QM[33]=QQ5_2; assign QM[34]=QQ5_3; assign QM[35]=QQ5_4; assign QM[36]=QQ5_5; assign QM[37]=QQ5_6; assign QM[38]=QQ5_7; assign QM[39]=QQ5_8;
assign QM[40]=QQ6_1; assign QM[41]=QQ6_2; assign QM[42]=QQ6_3; assign QM[43]=QQ6_4; assign QM[44]=QQ6_5; assign QM[45]=QQ6_6; assign QM[46]=QQ6_7; assign QM[47]=QQ6_8;
assign QM[48]=QQ7_1; assign QM[49]=QQ7_2; assign QM[50]=QQ7_3; assign QM[51]=QQ7_4; assign QM[52]=QQ7_5; assign QM[53]=QQ7_6; assign QM[54]=QQ7_7; assign QM[55]=QQ7_8;
assign QM[56]=QQ8_1; assign QM[57]=QQ8_2; assign QM[58]=QQ8_3; assign QM[59]=QQ8_4; assign QM[60]=QQ8_5; assign QM[61]=QQ8_6; assign QM[62]=QQ8_7; assign QM[63]=QQ8_8;

// -----------------------------------------------------------------------------
// 3. PIPELINE REGISTERS
// -----------------------------------------------------------------------------
reg signed [11:0] Z_ext  [0:63]; // Sign-extended input (12-bit, same range as Z_in)
reg signed [23:0] Z_temp [0:63]; // Stage 1: Phép nhân
reg signed [23:0] Z_del  [0:63]; // Stage 2: Delay
reg        [11:0] Q_out  [0:63]; // Stage 3: Làm tròn và xuất

reg enable_1, enable_2, enable_3;

// Quản lý tín hiệu Enable pipeline
always @(posedge clk) begin
    if (rst) begin
        enable_1 <= 0;
        enable_2 <= 0;
        enable_3 <= 0;
        out_enable <= 0;
    end else begin
        enable_1 <= enable;
        enable_2 <= enable_1;
        enable_3 <= enable_2;
        out_enable <= enable_3;
    end
end

// -----------------------------------------------------------------------------
// 4. MẠCH TOÁN HỌC (GENERATE LOOP)
// -----------------------------------------------------------------------------
genvar i;
generate
    for (i = 0; i < 64; i = i + 1) begin : quantizer_channels
        always @(posedge clk) begin
            if (rst) begin
                Z_ext[i]  <= 0;
                Z_temp[i] <= 0;
                Z_del[i]  <= 0;
                Q_out[i]  <= 0;
            end else begin
                // Stage 0: Mở rộng bit dấu của Z (từ 11 bit -> 12 bit bù hai)
                if (enable)
                    Z_ext[i] <= $signed({Z_in[i][11], Z_in[i]});
                
                // Stage 1: Nhân với QM. Định dạng {1'b0, QM[i]} ép QM thành số dương có dấu
                if (enable_1)
                    Z_temp[i] <= Z_ext[i] * $signed({1'b0, QM[i]});
                
                // Stage 2: Cấp Delay (theo đúng thiết kế gốc)
                if (enable_2)
                    Z_del[i] <= Z_temp[i];
                
                // Stage 3: Chia cho 4096 (lấy bit [23:12]) và làm tròn
                // Round half away from zero:
                //   - Dương (Z_del[23]=0): nếu bit[11]=1 (frac >= 0.5) thì round up (+1)
                if (enable_3)
                    Q_out[i] <= Z_del[i][23:12] + Z_del[i][11];
            end
        end
    end
endgenerate

// -----------------------------------------------------------------------------
// 5. MAP OUTPUTS TỪ MẢNG (ARRAY) LÊN PORTS
// -----------------------------------------------------------------------------
assign Q11=Q_out[0]; assign Q12=Q_out[1]; assign Q13=Q_out[2]; assign Q14=Q_out[3]; assign Q15=Q_out[4]; assign Q16=Q_out[5]; assign Q17=Q_out[6]; assign Q18=Q_out[7];
assign Q21=Q_out[8]; assign Q22=Q_out[9]; assign Q23=Q_out[10]; assign Q24=Q_out[11]; assign Q25=Q_out[12]; assign Q26=Q_out[13]; assign Q27=Q_out[14]; assign Q28=Q_out[15];
assign Q31=Q_out[16]; assign Q32=Q_out[17]; assign Q33=Q_out[18]; assign Q34=Q_out[19]; assign Q35=Q_out[20]; assign Q36=Q_out[21]; assign Q37=Q_out[22]; assign Q38=Q_out[23];
assign Q41=Q_out[24]; assign Q42=Q_out[25]; assign Q43=Q_out[26]; assign Q44=Q_out[27]; assign Q45=Q_out[28]; assign Q46=Q_out[29]; assign Q47=Q_out[30]; assign Q48=Q_out[31];
assign Q51=Q_out[32]; assign Q52=Q_out[33]; assign Q53=Q_out[34]; assign Q54=Q_out[35]; assign Q55=Q_out[36]; assign Q56=Q_out[37]; assign Q57=Q_out[38]; assign Q58=Q_out[39];
assign Q61=Q_out[40]; assign Q62=Q_out[41]; assign Q63=Q_out[42]; assign Q64=Q_out[43]; assign Q65=Q_out[44]; assign Q66=Q_out[45]; assign Q67=Q_out[46]; assign Q68=Q_out[47];
assign Q71=Q_out[48]; assign Q72=Q_out[49]; assign Q73=Q_out[50]; assign Q74=Q_out[51]; assign Q75=Q_out[52]; assign Q76=Q_out[53]; assign Q77=Q_out[54]; assign Q78=Q_out[55];
assign Q81=Q_out[56]; assign Q82=Q_out[57]; assign Q83=Q_out[58]; assign Q84=Q_out[59]; assign Q85=Q_out[60]; assign Q86=Q_out[61]; assign Q87=Q_out[62]; assign Q88=Q_out[63];

endmodule