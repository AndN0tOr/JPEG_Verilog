module jpeg_process(
    input clk, rst, enable,
    input [23:0] data_in,
    output [31:0] cr_JPEG_bitstream, cb_JPEG_bitstream, y_JPEG_bitstream,
    output cr_data_ready, cb_data_ready, y_data_ready,
    output [5:0] cr_orc, cb_orc, y_orc,
    output y_eob_output, y_eob_empty,
    output cb_eob_empty, cr_eob_empty,
    output y_is_last_chunk, cb_is_last_chunk, cr_is_last_chunk
);

    wire [23:0] data_out;
    wire [7:0] y_out  = data_out[23:16];
    wire [7:0] cb_out = data_out[15:8];
    wire [7:0] cr_out = data_out[7:0];
    wire enable_out;
    
    // Ignore Cb/Cr end_of_block_output signals as they are not used at top level
    wire cb_eob_out_nc, cr_eob_out_nc;

    color_trans color_trans_inst(
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_in(data_in),
        .data_out(data_out),
        .out_enable(enable_out)
    );

    cr_dqh cr_dqh_inst0(
        .clk(clk),
        .rst(rst),
        .enable(enable_out),
        .data_in(cr_out),
        .JPEG_bitstream(cr_JPEG_bitstream),
        .data_ready(cr_data_ready),
        .cr_orc(cr_orc),
        .end_of_block_output(cr_eob_out_nc),
        .end_of_block_empty(cr_eob_empty),
        .is_last_chunk(cr_is_last_chunk)
    );

    cb_dqh cb_dqh_inst0(
        .clk(clk),
        .rst(rst),
        .enable(enable_out),
        .data_in(cb_out),
        .JPEG_bitstream(cb_JPEG_bitstream),
        .data_ready(cb_data_ready),
        .cb_orc(cb_orc),
        .end_of_block_output(cb_eob_out_nc),
        .end_of_block_empty(cb_eob_empty),
        .is_last_chunk(cb_is_last_chunk)
    );

    y_dqh y_dqh_inst0(
        .clk(clk),
        .rst(rst),
        .enable(enable_out),
        .data_in(y_out),
        .JPEG_bitstream(y_JPEG_bitstream),
        .data_ready(y_data_ready),
        .y_orc(y_orc),
        .end_of_block_output(y_eob_output),
        .end_of_block_empty(y_eob_empty),
        .is_last_chunk(y_is_last_chunk)
    );

endmodule
