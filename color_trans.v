module color_trans (
    input clk,
    input wire [7:0] r,
    input wire [7:0] g,
    input wire [7:0] b,
    output reg [7:0] y,
    output reg [7:0] cb,
    output reg [7:0] cr
);
    always @(posedge clk) begin
        assign y[7:0] = r[7:0];
        assign cb[7:0] = g[7:0];
        assign cr[7:0] = b[7:0];
    end
endmodule
