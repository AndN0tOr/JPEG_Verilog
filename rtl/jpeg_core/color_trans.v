`timescale 1ps/1ps


/* Note: Internal assignment will shut off immediately after the enable goes low, 
we should have something to keep it working till the last data processed*/
module color_trans (
    input clk, rst,
    input enable,
    input [23:0] data_in,
    output reg out_enable,
    output [23:0] data_out
);
    wire [7:0] r, g, b;

    wire [7:0] Y1 = 8'd77;
    wire [7:0] Y2 = 8'd150;
    wire [7:0] Y3 = 8'd29;

    wire [7:0] Cb1 = 8'd43;
    wire [7:0] Cb2 = 8'd84;
    wire [7:0] Cb3 = 8'd128;

    wire [7:0] Cr1 = 8'd128;
    wire [7:0] Cr2 = 8'd107;
    wire [7:0] Cr3 = 8'd21;

    reg [15:0] Y_temp, Cb_temp, Cr_temp;

    reg [15:0] Y1_product, Y2_product, Y3_product;
    reg [15:0] Cb1_product, Cb2_product, Cb3_product;
    reg [15:0] Cr1_product, Cr2_product, Cr3_product;
    reg [7:0] Y, Cb, Cr;

    reg en_1, en_2;

    assign r[7:0] = data_in[23:16];
    assign g[7:0] = data_in[15:8];
    assign b[7:0] = data_in[7:0];

    assign data_out[23:16] = Y[7:0];
    assign data_out[15:8] = Cb[7:0];
    assign data_out[7:0] = Cr[7:0];


    always @(posedge clk)
    begin
        if (rst) begin
            Y1_product <= 0;
            Y2_product <= 0;
            Y3_product <= 0;
            Cb1_product <= 0;
            Cb2_product <= 0;
            Cb3_product <= 0;
            Cr1_product <= 0;
            Cr2_product <= 0;
            Cr3_product <= 0;
            Y_temp  <= 0;
            Cb_temp <= 0;
            Cr_temp <= 0;
        end
        else begin
            if (enable) begin
                Y1_product <= Y1 * r[7:0];
                Y2_product <= Y2 * g[7:0];
                Y3_product <= Y3 * b[7:0];
                Cb1_product <= Cb1 * r[7:0];
                Cb2_product <= Cb2 * g[7:0];
                Cb3_product <= Cb3 * b[7:0];
                Cr1_product <= Cr1 * r[7:0];
                Cr2_product <= Cr2 * g[7:0];
                Cr3_product <= Cr3 * b[7:0];
            end
            if (en_1) begin
                Y_temp <= Y1_product + Y2_product + Y3_product;
                Cb_temp <= 16'd32768 - Cb1_product - Cb2_product + Cb3_product;
                Cr_temp <= 16'd32768 + Cr1_product - Cr2_product - Cr3_product;
            end
        end
    end
    always @(posedge clk)
    begin
        if (rst) begin
            Y <= 0;
            Cb <=0;
            Cr <= 0;
        end
        else if (en_2) begin
            Y <= (Y_temp[7] && Y_temp[15:8] != 8'd255) ?  Y_temp[15:8] + 1'b1 : Y_temp[15:8];
            Cb <= (Cb_temp[7] && Cb_temp[15:8] != 8'd255) ? Cb_temp[15:8] + 1'b1 : Cb_temp[15:8];
            Cr <= (Cr_temp[7] && Cr_temp[15:8] != 8'd255) ? Cr_temp[15:8] + 1'b1 : Cr_temp[15:8];
        end
    end
    
    always @(posedge clk)
    begin 
        if (rst) begin
            en_1 <= 0;
            en_2 <= 0;
        end
        else begin
            en_1 <= enable;
            en_2 <= en_1;
            out_enable <= en_2;
        end
    end
endmodule
