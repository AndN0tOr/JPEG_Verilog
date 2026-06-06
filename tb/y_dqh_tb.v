module y_dqh_tb;
reg clk, rst, enable;
reg [7:0] data_in;
wire [31:0] JPEG_bitstream;
wire data_ready;
wire [4:0] y_orc;
wire end_of_block_output;
wire end_of_block_empty;

y_dqh dut (
.clk(clk),
.rst(rst),
.enable(enable),
.data_in(data_in),
.JPEG_bitstream(JPEG_bitstream),
.data_ready(data_ready),
.y_orc(y_orc),
.end_of_block_output(end_of_block_output),
.end_of_block_empty(end_of_block_empty)
);

parameter T = 10; // clock period in ns

initial begin
    // Initialize DUT ports
    clk = 0;
    rst = 1;
    enable = 0;
    data_in = 0;

    #T; rst = 0;

    enable = 1;
    #T; data_in = 8'hAA;
    #T; data_in = 8'h55;
    #T; data_in = 8'h12;
    #T; data_in = 8'h34;

    // Hold enable for a few more cycles
    #T; #T; #T;

    // Disable enable
    enable = 0;

    // Check outputs after the last input
    #T; #T; #T;

    $finish;
end

// Clock generation
always #5 clk = ~clk;

endmodule