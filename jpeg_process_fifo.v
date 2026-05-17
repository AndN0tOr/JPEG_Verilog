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
    // 1. KHAI BÁO TÍN HIỆU RÕ RÀNG (ĐÃ FIX LỖI 1-BIT TRUNCATION)
    // -------------------------------------------------------------------------
    wire [31:0] cb_JPEG_bitstream, cr_JPEG_bitstream, y_JPEG_bitstream;
    wire [4:0]  cr_orc, cb_orc, y_orc;
    wire [31:0] y_bits_out;
    wire        y_out_enable;
    wire        cb_data_ready, cr_data_ready, y_data_ready;
    wire        end_of_block_output, y_eob_empty; 
    wire        cb_eob_empty, cr_eob_empty;
    wire        y_fifo_empty;
    
    // Khai báo rõ ràng 32-bit để tránh Verilog tự ngầm định 1-bit
    wire [31:0] cr_bits_out1, cr_bits_out2, cb_bits_out1, cb_bits_out2;
    wire [31:0] cr_JPEG_bitstream1, cr_JPEG_bitstream2;
    wire [31:0] cb_JPEG_bitstream1, cb_JPEG_bitstream2;
    wire [31:0] cr_bits_out, cb_bits_out;

    wire        cr_fifo_empty1, cr_fifo_empty2, cb_fifo_empty1, cb_fifo_empty2;
    wire        cr_out_enable1, cr_out_enable2, cb_out_enable1, cb_out_enable2;
    wire        cr_fifo_empty, cb_fifo_empty;
    wire        cr_out_enable, cb_out_enable;
    wire        cb_write_enable1, cb_write_enable2, cr_write_enable1, cr_write_enable2;
    wire        cb_read_req1, cb_read_req2, cr_read_req1, cr_read_req2;

    wire cb_write_enable = cb_data_ready; // Bỏ && !cb_eob_empty
    wire cr_write_enable = cr_data_ready; // Bỏ && !cr_eob_empty
    wire y_write_enable  = y_data_ready;  // Bỏ && !y_eob_empty

    // Các thanh ghi dồn kênh và dịch bit
    reg [4:0]   orc, orc_cb, orc_cr, old_orc_reg, sorc_reg, roll_orc_reg;
    reg [4:0]   orc_1, orc_2, orc_3, orc_4, orc_5, orc_reg_delay;
    reg [4:0]   edge_ro_1, edge_ro_2, edge_ro_3, edge_ro_4, edge_ro_5;
    reg [31:0]  jpeg_ro_1, jpeg_ro_2, jpeg_ro_3, jpeg_ro_4, jpeg_ro_5, jpeg_delay;
    reg [31:0]  jpeg, jpeg_1, jpeg_2, jpeg_3, jpeg_4, jpeg_5, jpeg_6;
    reg [4:0]   cr_orc_1, cb_orc_1, y_orc_1;
    reg         cr_out_enable_1, cb_out_enable_1, y_out_enable_1;
    
    // Mảng thanh ghi dịch cho tín hiệu điều khiển (Thay vì viết 35 dòng rời rạc)
    reg [35:1]  en;
    reg [8:1]   br;
    reg [4:1]   eob;
    reg [7:1]   roll;
    reg [4:0]   static_orc [1:6];
    
    reg [2:0]   bits_mux, old_orc_mux, read_mux;
    reg         bits_ready, rollover, rollover_eob;
    reg         eobe_1, cb_read_req, cr_read_req, y_read_req;
    reg         eob_early_out_enable, fifo_mux;

    integer i;

    // -------------------------------------------------------------------------
    // 2. KẾT NỐI MODULE (INSTANTIATIONS)
    // -------------------------------------------------------------------------
    jpeg_process jpeg_process_inst(
        .clk(clk), .rst(rst), .enable(enable), .data_in(data_in),
        .cr_JPEG_bitstream(cr_JPEG_bitstream), .cr_data_ready(cr_data_ready), .cr_orc(cr_orc), 
        .cb_JPEG_bitstream(cb_JPEG_bitstream), .cb_data_ready(cb_data_ready), .cb_orc(cb_orc), 
        .y_JPEG_bitstream(y_JPEG_bitstream),   .y_data_ready(y_data_ready),   .y_orc(y_orc), 
        .y_eob_output(end_of_block_output),    .y_eob_empty(y_eob_empty), 
        .cb_eob_empty(cb_eob_empty),           .cr_eob_empty(cr_eob_empty)
    );

    sync_fifo_32 cb_fifo_inst0(.clk(clk), .rst(rst), .read_req(cb_read_req1), .write_data(cb_JPEG_bitstream1), .write_enable(cb_write_enable1), .read_data(cb_bits_out1), .fifo_empty(cb_fifo_empty1), .rdata_valid(cb_out_enable1));
    sync_fifo_32 cb_fifo_inst1(.clk(clk), .rst(rst), .read_req(cb_read_req2), .write_data(cb_JPEG_bitstream2), .write_enable(cb_write_enable2), .read_data(cb_bits_out2), .fifo_empty(cb_fifo_empty2), .rdata_valid(cb_out_enable2));   
    sync_fifo_32 u16(.clk(clk), .rst(rst), .read_req(cr_read_req1), .write_data(cr_JPEG_bitstream1), .write_enable(cr_write_enable1), .read_data(cr_bits_out1), .fifo_empty(cr_fifo_empty1), .rdata_valid(cr_out_enable1));
    sync_fifo_32 u24(.clk(clk), .rst(rst), .read_req(cr_read_req2), .write_data(cr_JPEG_bitstream2), .write_enable(cr_write_enable2), .read_data(cr_bits_out2), .fifo_empty(cr_fifo_empty2), .rdata_valid(cr_out_enable2));       
    sync_fifo_32 u17(.clk(clk), .rst(rst), .read_req(y_read_req),   .write_data(y_JPEG_bitstream),   .write_enable(y_write_enable),   .read_data(y_bits_out),   .fifo_empty(y_fifo_empty),   .rdata_valid(y_out_enable));           

    // -------------------------------------------------------------------------
    // 3. FIFO PING-PONG & ROUTING
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) fifo_mux <= 0;
        else if (end_of_block_output) fifo_mux <= ~fifo_mux;
    end
    
    // Cr
    assign cr_read_req1       = fifo_mux ? 1'b0 : cr_read_req;
    assign cr_read_req2       = fifo_mux ? cr_read_req : 1'b0;
    assign cr_JPEG_bitstream1 = fifo_mux ? cr_JPEG_bitstream : 32'd0;
    assign cr_JPEG_bitstream2 = fifo_mux ? 32'd0 : cr_JPEG_bitstream;
    assign cr_write_enable1   = fifo_mux && cr_write_enable;
    assign cr_write_enable2   = !fifo_mux && cr_write_enable;
    assign cr_bits_out        = fifo_mux ? cr_bits_out2 : cr_bits_out1;
    assign cr_fifo_empty      = fifo_mux ? cr_fifo_empty2 : cr_fifo_empty1;
    assign cr_out_enable      = fifo_mux ? cr_out_enable2 : cr_out_enable1;

    // Cb
    assign cb_read_req1       = fifo_mux ? 1'b0 : cb_read_req;
    assign cb_read_req2       = fifo_mux ? cb_read_req : 1'b0;
    assign cb_JPEG_bitstream1 = fifo_mux ? cb_JPEG_bitstream : 32'd0;
    assign cb_JPEG_bitstream2 = fifo_mux ? 32'd0 : cb_JPEG_bitstream;
    assign cb_write_enable1   = fifo_mux && cb_write_enable;
    assign cb_write_enable2   = !fifo_mux && cb_write_enable;
    assign cb_bits_out        = fifo_mux ? cb_bits_out2 : cb_bits_out1;
    assign cb_fifo_empty      = fifo_mux ? cb_fifo_empty2 : cb_fifo_empty1;
    assign cb_out_enable      = fifo_mux ? cb_out_enable2 : cb_out_enable1;

    // -------------------------------------------------------------------------
    // 4. PIPELINE REGISTERS (DELAY CHAINS)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            en <= 0; br <= 0; eob <= 0; roll <= 0;
            data_ready <= 0; eobe_1 <= 0; eob_early_out_enable <= 0;
            for(i=1; i<=6; i=i+1) static_orc[i] <= 0;
        end else begin 
            en  <= {en[34:1], end_of_block_output};
            br  <= {br[7:1], bits_ready & !eobe_1};
            eob <= {eob[3:1], end_of_block_output};
            
            roll[1] <= rollover;
            roll[2] <= roll[1];
            roll[3] <= roll[2];
            roll[4] <= roll[3] | rollover_eob; 
            roll[5] <= roll[4]; 
            roll[6] <= roll[5]; 
            roll[7] <= roll[6]; 
            
            static_orc[1] <= sorc_reg; 
            for(i=2; i<=6; i=i+1) static_orc[i] <= static_orc[i-1];
            
            data_ready <= br[6] & roll[5];
            eobe_1 <= y_eob_empty;
            eob_early_out_enable <= y_out_enable & y_out_enable_1 & eob[2]; 
        end
    end 

    always @(posedge clk) begin
        if (rst) rollover_eob <= 0; 
        else if (br[3]) rollover_eob <= old_orc_reg >= roll_orc_reg;
    end

    // -------------------------------------------------------------------------
    // 5. CONTROL MUXES
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        // bits_mux
        if (rst)        bits_mux <= 3'b001; 
        else if (en[3]) bits_mux <= 3'b010; 
        else if (en[19])bits_mux <= 3'b100; 
        else if (en[35])bits_mux <= 3'b001;
        
        // old_orc_mux
        if (rst)        old_orc_mux <= 3'b001;
        else if (en[1]) old_orc_mux <= 3'b010;
        else if (en[6]) old_orc_mux <= 3'b100;
        else if (en[22])old_orc_mux <= 3'b001;
        
        // read_mux
        if (rst)        read_mux <= 3'b001;
        else if (en[1]) read_mux <= 3'b010;
        else if (en[17])read_mux <= 3'b100;
        else if (en[33])read_mux <= 3'b001;
    end 

    always @(posedge clk) begin
        y_read_req  <= (!y_fifo_empty  && read_mux == 3'b001);
        cb_read_req <= (!cb_fifo_empty && read_mux == 3'b010);
        cr_read_req <= (!cr_fifo_empty && read_mux == 3'b100);
    end 

    always @(posedge clk) begin
        case (bits_mux)
            3'b001: begin jpeg <= y_bits_out;  bits_ready <= y_out_enable;  sorc_reg <= orc;    orc_reg <= orc;    rollover <= y_out_enable_1 & !eob[4] & !eob_early_out_enable; end
            3'b010: begin jpeg <= cb_bits_out; bits_ready <= cb_out_enable; sorc_reg <= orc_cb; orc_reg <= orc_cb; rollover <= cb_out_enable_1 & cb_out_enable; end
            3'b100: begin jpeg <= cr_bits_out; bits_ready <= cr_out_enable; sorc_reg <= orc_cr; orc_reg <= orc_cr; rollover <= cr_out_enable_1 & cr_out_enable; end
            default:begin jpeg <= y_bits_out;  bits_ready <= y_out_enable;  sorc_reg <= orc;    orc_reg <= orc;    rollover <= y_out_enable_1 & !eob[4]; end
        endcase

        case (old_orc_mux)
            3'b001: begin roll_orc_reg <= orc;    old_orc_reg <= orc_cr; end
            3'b010: begin roll_orc_reg <= orc_cb; old_orc_reg <= orc;    end
            3'b100: begin roll_orc_reg <= orc_cr; old_orc_reg <= orc_cb; end
            default:begin roll_orc_reg <= orc;    old_orc_reg <= orc_cr; end
        endcase
    end

    // -------------------------------------------------------------------------
    // 6. LOGARITHMIC BARREL SHIFTER & STATE REGISTERS (GIỮ NGUYÊN PIPELINE)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            orc <= 0; orc_cb <= 0; orc_cr <= 0;
            cr_out_enable_1 <= 0; cb_out_enable_1 <= 0; y_out_enable_1 <= 0; 
            cr_orc_1 <= 0; cb_orc_1 <= 0; y_orc_1 <= 0;
        end else begin
            if (en[20]) orc <= orc_cr + cr_orc_1;
            if (eob[1]) orc_cb <= orc + y_orc_1; 
            if (en[5])  orc_cr <= orc_cb + cb_orc_1;
            
            cr_out_enable_1 <= cr_out_enable;
            cb_out_enable_1 <= cb_out_enable;
            y_out_enable_1  <= y_out_enable;
            
            if (end_of_block_output) begin 
                cr_orc_1 <= cr_orc; cb_orc_1 <= cb_orc; y_orc_1 <= y_orc;
            end
        end
    end 

    // Pipeline shifts
    always @(posedge clk) begin
        if (rst) begin
            jpeg_1 <= 0; orc_1 <= 0; jpeg_delay <= 0; orc_reg_delay <= 0;
        end else if (bits_ready) begin 
            jpeg_1 <= (orc_reg >= 16) ? jpeg >> 16 : jpeg;
            orc_1 <= (orc_reg >= 16) ? orc_reg - 16 : orc_reg;
            jpeg_delay <= jpeg;
            orc_reg_delay <= orc_reg;
        end
    end 

    always @(posedge clk) begin
        if (rst) begin
            jpeg_2 <= 0; orc_2 <= 0; jpeg_ro_1 <= 0; edge_ro_1 <= 0;
        end else if (br[1]) begin 
            jpeg_2 <= (orc_1 >= 8) ? jpeg_1 >> 8 : jpeg_1;
            orc_2 <= (orc_1 >= 8) ? orc_1 - 8 : orc_1;
            jpeg_ro_1 <= (orc_reg_delay <= 16) ? jpeg_delay << 16 : jpeg_delay; 
            edge_ro_1 <= (orc_reg_delay <= 16) ? orc_reg_delay : orc_reg_delay - 16;
        end
    end 

    always @(posedge clk) begin
        if (rst) begin
            jpeg_3 <= 0; orc_3 <= 0; jpeg_ro_2 <= 0; edge_ro_2 <= 0;
        end else if (br[2]) begin 
            jpeg_3 <= (orc_2 >= 4) ? jpeg_2 >> 4 : jpeg_2;
            orc_3 <= (orc_2 >= 4) ? orc_2 - 4 : orc_2;
            jpeg_ro_2 <= (edge_ro_1 <= 8) ? jpeg_ro_1 << 8 : jpeg_ro_1; 
            edge_ro_1 <= (edge_ro_1 <= 8) ? edge_ro_1 : edge_ro_1 - 8;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            jpeg_4 <= 0; orc_4 <= 0; jpeg_ro_3 <= 0; edge_ro_3 <= 0;
        end else if (br[3]) begin 
            jpeg_4 <= (orc_3 >= 2) ? jpeg_3 >> 2 : jpeg_3;
            orc_4 <= (orc_3 >= 2) ? orc_3 - 2 : orc_3;
            jpeg_ro_3 <= (edge_ro_2 <= 4) ? jpeg_ro_2 << 4 : jpeg_ro_2; 
            edge_ro_3 <= (edge_ro_2 <= 4) ? edge_ro_2 : edge_ro_2 - 4;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            jpeg_5 <= 0; orc_5 <= 0; jpeg_ro_4 <= 0; edge_ro_4 <= 0;
        end else if (br[4]) begin 
            jpeg_5 <= (orc_4 >= 1) ? jpeg_4 >> 1 : jpeg_4;
            orc_5 <= (orc_4 >= 1) ? orc_4 - 1 : orc_4;
            jpeg_ro_4 <= (edge_ro_3 <= 2) ? jpeg_ro_3 << 2 : jpeg_ro_3; 
            edge_ro_4 <= (edge_ro_3 <= 2) ? edge_ro_3 : edge_ro_3 - 2;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            jpeg_ro_5 <= 0; edge_ro_5 <= 0;
        end else if (br[5]) begin 
            jpeg_ro_5 <= (edge_ro_4 <= 1) ? jpeg_ro_4 << 1 : jpeg_ro_4; 
            edge_ro_5 <= (edge_ro_4 <= 1) ? edge_ro_4 : edge_ro_4 - 1;
        end
    end

    // -------------------------------------------------------------------------
    // 7. GHÉP BIT ĐẦU RA BẰNG VÒNG LẶP FOR (Thay thế hàng trăm dòng lệnh cũ)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            jpeg_6 <= 0; 
        end else if (br[5] | br[6]) begin 
            for (i = 1; i < 32; i = i + 1) begin
                jpeg_6[i] <= (roll[5] & (static_orc[5] > (31 - i))) ? jpeg_ro_5[i] : jpeg_5[i];
            end
            jpeg_6[0] <= jpeg_5[0];
        end
    end 

    always @(posedge clk) begin
        if (rst) begin
            JPEG_bitstream <= 0;
        end else begin
            for (i = 0; i < 32; i = i + 1) begin
                if (br[7] & roll[6])
                    JPEG_bitstream[i] <= jpeg_6[i];
                else if (br[6] && (static_orc[6] <= (31 - i))) 
                    JPEG_bitstream[i] <= jpeg_6[i];
            end
        end
    end

endmodule