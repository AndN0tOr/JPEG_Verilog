module jpeg_process_fifo(
    input         clk, 
    input         rst, 
    input         enable, 
    input  [23:0] data_in, 
    output reg [31:0] JPEG_bitstream, 
    output reg    data_ready, 
    output reg [4:0]  orc_reg
);

    // -------------------------------------------------------------------------
    // 1. MODULE INSTANTIATION & WIRES
    // -------------------------------------------------------------------------
    wire [31:0] cb_JPEG_bitstream, cr_JPEG_bitstream, y_JPEG_bitstream;
    wire [5:0]  cr_orc, cb_orc, y_orc;
    wire        cb_data_ready, cr_data_ready, y_data_ready;
    wire        end_of_block_output, y_eob_empty; 
    wire        cb_eob_empty, cr_eob_empty;
    wire        y_is_last_chunk, cb_is_last_chunk, cr_is_last_chunk;

    jpeg_process jpeg_process_inst(
        .clk(clk), .rst(rst), .enable(enable), .data_in(data_in),
        .cr_JPEG_bitstream(cr_JPEG_bitstream), .cr_data_ready(cr_data_ready), .cr_orc(cr_orc), 
        .cb_JPEG_bitstream(cb_JPEG_bitstream), .cb_data_ready(cb_data_ready), .cb_orc(cb_orc), 
        .y_JPEG_bitstream(y_JPEG_bitstream),   .y_data_ready(y_data_ready),   .y_orc(y_orc), 
        .y_eob_output(end_of_block_output),    .y_eob_empty(y_eob_empty), 
        .cb_eob_empty(cb_eob_empty),           .cr_eob_empty(cr_eob_empty),
        .y_is_last_chunk(y_is_last_chunk),     .cb_is_last_chunk(cb_is_last_chunk), .cr_is_last_chunk(cr_is_last_chunk)
    );

    // -------------------------------------------------------------------------
    // 2. FWFT FIFOs (WIDTH = 39 BITS)
    // -------------------------------------------------------------------------
    wire [38:0] y_bits_out_39, cb_bits_out_39, cr_bits_out_39;
    wire        y_fifo_empty, cb_fifo_empty, cr_fifo_empty;
    wire        y_out_enable, cb_out_enable, cr_out_enable;
    
    wire cb_read_req, cr_read_req, y_read_req;

    sync_fifo_39 y_fifo(
        .clk(clk), .rst(rst), .read_req(y_read_req), 
        .write_data({y_is_last_chunk, y_orc, y_JPEG_bitstream}), .write_enable(y_data_ready), 
        .read_data(y_bits_out_39), .fifo_empty(y_fifo_empty), .rdata_valid(y_out_enable), .fifo_full()
    );
    
    sync_fifo_39 cb_fifo(
        .clk(clk), .rst(rst), .read_req(cb_read_req), 
        .write_data({cb_is_last_chunk, cb_orc, cb_JPEG_bitstream}), .write_enable(cb_data_ready), 
        .read_data(cb_bits_out_39), .fifo_empty(cb_fifo_empty), .rdata_valid(cb_out_enable), .fifo_full()
    );
    
    sync_fifo_39 cr_fifo(
        .clk(clk), .rst(rst), .read_req(cr_read_req), 
        .write_data({cr_is_last_chunk, cr_orc, cr_JPEG_bitstream}), .write_enable(cr_data_ready), 
        .read_data(cr_bits_out_39), .fifo_empty(cr_fifo_empty), .rdata_valid(cr_out_enable), .fifo_full()
    );

    // -------------------------------------------------------------------------
    // 3. FSM FOR READING FIFOS SEQUENTIALLY (FWFT Logic)
    // -------------------------------------------------------------------------
    reg [1:0] state; // 0: Idle/Y, 1: Cb, 2: Cr
    
    wire current_empty = (state == 2'd0) ? y_fifo_empty : 
                         (state == 2'd1) ? cb_fifo_empty : cr_fifo_empty;
                         
    wire [38:0] current_data_39 = (state == 2'd0) ? y_bits_out_39 : 
                                  (state == 2'd1) ? cb_bits_out_39 : cr_bits_out_39;
                                  
    wire current_is_last_chunk = current_data_39[38];
    wire [5:0]  current_orc    = current_data_39[37:32];
    wire [31:0] current_bits   = current_data_39[31:0];

    // Request to pop if we have data
    wire pop_req = !current_empty;

    assign y_read_req  = pop_req && (state == 2'd0);
    assign cb_read_req = pop_req && (state == 2'd1);
    assign cr_read_req = pop_req && (state == 2'd2);

    always @(posedge clk) begin
        if (rst) state <= 2'd0;
        else if (pop_req && current_is_last_chunk) begin
            if (state == 2'd0) state <= 2'd1;
            else if (state == 2'd1) state <= 2'd2;
            else if (state == 2'd2) state <= 2'd0;
        end
    end

    // -------------------------------------------------------------------------
    // 4. 64-BIT ACCUMULATOR (THE BIT PACKER)
    // -------------------------------------------------------------------------
    reg [63:0] bit_buffer;
    reg [6:0]  bit_count;
    
    // valid_bits is directly equal to orc! (0 to 32)
    wire [5:0]  valid_bits = current_orc;
    
    // Convert left-aligned with 1s padding to right-aligned
    // Example: if valid_bits = 0, current_bits >> 32 -> 0.
    // If valid_bits = 32, current_bits >> 0 -> current_bits.
    wire [31:0] valid_data = (valid_bits == 0) ? 32'd0 : (current_bits >> (6'd32 - valid_bits));
    
    wire [63:0] temp_buffer = (bit_buffer << valid_bits) | valid_data;
    wire [6:0]  temp_count  = bit_count + valid_bits;
    wire [31:0] out_word    = temp_buffer >> (temp_count - 7'd32);
    
    // Generate mask to keep only the remaining bits
    // Note: temp_count - 32 will be max 31.
    wire [63:0] remaining_mask = (64'h1 << (temp_count - 7'd32)) - 1;

    always @(posedge clk) begin
        if (rst) begin
            bit_buffer <= 0;
            bit_count  <= 0;
            JPEG_bitstream <= 0;
            data_ready <= 0;
            orc_reg <= 0;
        end else begin
            data_ready <= 0;
            orc_reg <= 0; // We always output full 32-bit words
            
            if (pop_req) begin
                if (temp_count >= 32) begin
                    JPEG_bitstream <= out_word;
                    data_ready <= 1;
                    bit_buffer <= temp_buffer & remaining_mask;
                    bit_count  <= temp_count - 7'd32;
                end else begin
                    bit_buffer <= temp_buffer;
                    bit_count  <= temp_count;
                end
            end
        end
    end
endmodule