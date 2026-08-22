`timescale 1ps / 1ps


/* Note: Internal assignment will shut off immediately after the enable goes low, 
we should have something to keep it working till the last data processed*/
typedef struct packed {logic [7:0] r, g, b;} data_in_t;
typedef struct packed {logic [7:0] y, cb, cr;} data_out_t;

module color_trans_sv(
    input  logic      clk,
    input  logic      rst,
    input  logic      enable,      // aka en_prod
    input  data_in_t  data_in,
    output logic      out_enable,
    output data_out_t data_out
);

  localparam logic [7:0] COEFF_Y  [0:2] = '{8'd77, 8'd150, 8'd29};
  localparam logic [7:0] COEFF_Cb [0:2] = '{8'd43, 8'd84, 8'd128};
  localparam logic [7:0] COEFF_Cr [0:2] = '{8'd128, 8'd107, 8'd21};
  localparam logic [15:0] offset = 16'd32768;

  logic [15:0] Y_prod [0:2];
  logic [15:0] Cb_prod[0:2];
  logic [15:0] Cr_prod[0:2];
  logic [15:0] Y_temp, Cb_temp, Cr_temp;

  logic en_temp, en_rounding;

  always_ff @(posedge clk) begin
    if (enable) begin
      Y_prod[0]  <= COEFF_Y[0] * data_in.r;
      Y_prod[1]  <= COEFF_Y[1] * data_in.g;
      Y_prod[2]  <= COEFF_Y[2] * data_in.b;
      Cb_prod[0] <= COEFF_Cb[0] * data_in.r;
      Cb_prod[1] <= COEFF_Cb[1] * data_in.g;
      Cb_prod[2] <= COEFF_Cb[2] * data_in.b;
      Cr_prod[0] <= COEFF_Cr[0] * data_in.r;
      Cr_prod[1] <= COEFF_Cr[1] * data_in.g;
      Cr_prod[2] <= COEFF_Cr[2] * data_in.b;
    end
    if (en_temp) begin
      Y_temp  <= Y_prod[0] + Y_prod[1] + Y_prod[2];
      Cb_temp <= offset - Cb_prod[0] - Cb_prod[1] + Cb_prod[2];
      Cr_temp <= offset + Cr_prod[0] - Cr_prod[1] - Cr_prod[2];
    end
    if (en_rounding) begin
      data_out.y <= (Y_temp[7] && Y_temp[15:8] != 8'd255) ? Y_temp[15:8] + 1'b1 : Y_temp[15:8];
      data_out.cb <= (Cb_temp[7] && Cb_temp[15:8] != 8'd255) ? Cb_temp[15:8] + 1'b1 : Cb_temp[15:8];
      data_out.cr <= (Cr_temp[7] && Cr_temp[15:8] != 8'd255) ? Cr_temp[15:8] + 1'b1 : Cr_temp[15:8];
    end
  end

  // -------------------------Pipeline Stage --------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      en_temp <= 0;
      en_rounding <= 0;
      out_enable <= 0;
    end else begin
      en_temp <= enable;
      en_rounding <= en_temp;
      out_enable <= en_rounding;
    end
  end
endmodule
