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
    // 1. TÍN HIỆU KẾT NỐI VỚI CÁC SUBMODULES (Giữ nguyên gốc)
    // -------------------------------------------------------------------------
    wire [31:0] cb_JPEG_bitstream, cr_JPEG_bitstream, y_JPEG_bitstream;
    wire [4:0]  cr_orc, cb_orc, y_orc;
    wire [31:0] y_bits_out;
    wire        y_out_enable;
    wire        cb_data_ready, cr_data_ready, y_data_ready;
    wire        end_of_block_output, y_eob_empty; 
    wire        cb_eob_empty, cr_eob_empty;
    wire        y_fifo_empty;
    
    wire [31:0] cr_bits_out1, cr_bits_out2, cb_bits_out1, cb_bits_out2;
    wire        cr_fifo_empty1, cr_fifo_empty2, cb_fifo_empty1, cb_fifo_empty2;
    wire        cr_out_enable1, cr_out_enable2, cb_out_enable1, cb_out_enable2;

    wire cb_write_enable = cb_data_ready && !cb_eob_empty;
    wire cr_write_enable = cr_data_ready && !cr_eob_empty;
    wire y_write_enable  = y_data_ready  && !y_eob_empty;

    wire cr_read_req, cb_read_req, y_read_req;

    reg [63:0] next_buffer;
    reg [5:0]  next_count;
    // -------------------------------------------------------------------------
    // 2. INSTANTIATIONS (Giữ nguyên không đổi)
    // -------------------------------------------------------------------------
    jpeg_process u14(
        .clk(clk), .rst(rst), .enable(enable), .data_in(data_in),
        .cr_JPEG_bitstream(cr_JPEG_bitstream), .cr_data_ready(cr_data_ready), .cr_orc(cr_orc), 
        .cb_JPEG_bitstream(cb_JPEG_bitstream), .cb_data_ready(cb_data_ready), .cb_orc(cb_orc), 
        .y_JPEG_bitstream(y_JPEG_bitstream),   .y_data_ready(y_data_ready),   .y_orc(y_orc), 
        .y_eob_output(end_of_block_output),    .y_eob_empty(y_eob_empty), 
        .cb_eob_empty(cb_eob_empty),           .cr_eob_empty(cr_eob_empty)
    );

    sync_fifo_32 u15(.clk(clk), .rst(rst), .read_req(cb_read_req1), .write_data(cb_JPEG_bitstream1), .write_enable(cb_write_enable1), .read_data(cb_bits_out1), .fifo_empty(cb_fifo_empty1), .rdata_valid(cb_out_enable1));
    sync_fifo_32 u25(.clk(clk), .rst(rst), .read_req(cb_read_req2), .write_data(cb_JPEG_bitstream2), .write_enable(cb_write_enable2), .read_data(cb_bits_out2), .fifo_empty(cb_fifo_empty2), .rdata_valid(cb_out_enable2));	
    sync_fifo_32 u16(.clk(clk), .rst(rst), .read_req(cr_read_req1), .write_data(cr_JPEG_bitstream1), .write_enable(cr_write_enable1), .read_data(cr_bits_out1), .fifo_empty(cr_fifo_empty1), .rdata_valid(cr_out_enable1));
    sync_fifo_32 u24(.clk(clk), .rst(rst), .read_req(cr_read_req2), .write_data(cr_JPEG_bitstream2), .write_enable(cr_write_enable2), .read_data(cr_bits_out2), .fifo_empty(cr_fifo_empty2), .rdata_valid(cr_out_enable2));		
    sync_fifo_32 u17(.clk(clk), .rst(rst), .read_req(y_read_req),   .write_data(y_JPEG_bitstream),   .write_enable(y_write_enable),   .read_data(y_bits_out),   .fifo_empty(y_fifo_empty),   .rdata_valid(y_out_enable));			

    // -------------------------------------------------------------------------
    // 3. LOGIC ĐIỀU KHIỂN PING-PONG FIFO CỦA TÁC GIẢ GỐC
    // -------------------------------------------------------------------------
    reg fifo_mux;
    always @(posedge clk) begin
        if (rst) fifo_mux <= 0;
        else if (end_of_block_output) fifo_mux <= ~fifo_mux;
    end
    

    assign cr_read_req1 = fifo_mux ? 0 : cr_read_req;
    assign cr_read_req2 = fifo_mux ? cr_read_req : 0;
    assign cr_JPEG_bitstream1 = fifo_mux ? cr_JPEG_bitstream : 0;
    assign cr_JPEG_bitstream2 = fifo_mux ? 0 : cr_JPEG_bitstream;
    assign cr_write_enable1 =  fifo_mux && cr_write_enable;
    assign cr_write_enable2 = !fifo_mux && cr_write_enable;
    assign cr_bits_out   = fifo_mux ? cr_bits_out2 : cr_bits_out1;
    assign cr_fifo_empty = fifo_mux ? cr_fifo_empty2 : cr_fifo_empty1;
    assign cr_out_enable = fifo_mux ? cr_out_enable2 : cr_out_enable1;

    assign cb_read_req1 = fifo_mux ? 0 : cb_read_req;
    assign cb_read_req2 = fifo_mux ? cb_read_req : 0;
    assign cb_JPEG_bitstream1 = fifo_mux ? cb_JPEG_bitstream : 0;
    assign cb_JPEG_bitstream2 = fifo_mux ? 0 : cb_JPEG_bitstream;
    assign cb_write_enable1 =  fifo_mux && cb_write_enable;
    assign cb_write_enable2 = !fifo_mux && cb_write_enable;
    assign cb_bits_out   = fifo_mux ? cb_bits_out2 : cb_bits_out1;
    assign cb_fifo_empty = fifo_mux ? cb_fifo_empty2 : cb_fifo_empty1;
    assign cb_out_enable = fifo_mux ? cb_out_enable2 : cb_out_enable1;

    // -------------------------------------------------------------------------
    // 4. BỘ ĐỊNH TUYẾN ĐỌC (THAY THẾ CHUỖI 35 THANH GHI ENABLE)
    // -------------------------------------------------------------------------
    reg [35:1] dly; // Dịch vòng (Delay chain) kích hoạt bởi end_of_block
    always @(posedge clk) begin
        if (rst) dly <= 0;
        else dly <= {dly[34:1], end_of_block_output};
    end

    reg [2:0] read_mux; // 001: Y, 010: Cb, 100: Cr
    always @(posedge clk) begin
        if (rst)          read_mux <= 3'b001; 
        else if (dly[1])  read_mux <= 3'b010; 
        else if (dly[17]) read_mux <= 3'b100; 
        else if (dly[33]) read_mux <= 3'b001; 
    end

    assign y_read_req  = (!y_fifo_empty  && read_mux == 3'b001);
    assign cb_read_req = (!cb_fifo_empty && read_mux == 3'b010);
    assign cr_read_req = (!cr_fifo_empty && read_mux == 3'b100);

    // Chốt lưu trữ ORC (Số lượng bit hợp lệ) từ các block trước khi đẩy vào Packer
    reg [4:0] y_orc_latch, cb_orc_latch, cr_orc_latch;
    always @(posedge clk) begin
        if (rst) begin
            y_orc_latch <= 0; cb_orc_latch <= 0; cr_orc_latch <= 0;
        end else if (end_of_block_output) begin
            y_orc_latch <= y_orc;
            cb_orc_latch <= cb_orc;
            cr_orc_latch <= cr_orc;
        end
    end

    // -------------------------------------------------------------------------
    // 5. BITSTREAM PACKER TỐI ƯU (THAY THẾ MỚ SHIFT REGISTER LOẰNG NGOẰNG)
    // -------------------------------------------------------------------------
    reg [63:0] bit_buffer;
    reg [5:0]  bit_count;

    wire       any_out_enable = y_out_enable | cb_out_enable | cr_out_enable;
    
    // Ghép đúng tín hiệu dựa trên việc FIFO nào đang nhả dữ liệu
    wire [4:0] current_orc   = y_out_enable ? y_orc_latch :
                               cb_out_enable ? cb_orc_latch : 
                               cr_orc_latch;
                               
    wire [31:0] current_bits = y_out_enable ? y_bits_out :
                               cb_out_enable ? cb_bits_out : 
                               cr_bits_out;

    always @(posedge clk) begin
        if (rst) begin
            bit_buffer <= 0;
            bit_count  <= 0;
            JPEG_bitstream <= 0;
            data_ready <= 0;
            orc_reg <= 0;
        end else begin
            data_ready <= 0; // Xóa cờ data_ready mỗi chu kỳ
            
            next_buffer = bit_buffer;
            next_count  = bit_count;

            // Nạp dữ liệu mới vào chuỗi
            if (any_out_enable) begin
                // Shift trái và append bits mới (đóng gói MSB First chuẩn JPEG)
                next_buffer = (next_buffer << current_orc) | (current_bits & ((1<<current_orc)-1));
                next_count  = next_count + current_orc;
            end

            // Đẩy ra ngoài khi đủ một khối 32 bits
            if (next_count >= 32) begin
                JPEG_bitstream <= next_buffer[next_count - 1 -: 32];
                data_ready <= 1;
                next_count = next_count - 32;
            end

            // Cập nhật các registers
            bit_buffer <= next_buffer;
            bit_count  <= next_count;
            orc_reg    <= next_count[4:0]; // Báo hiệu số bit bị dư lại (rollover)
        end
    end

endmodule