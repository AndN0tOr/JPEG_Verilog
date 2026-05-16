`timescale 1ns / 1ps

module jpeg_top_tb();

    // -----------------------------------------------------------
    // 1. Khai báo tín hiệu kết nối
    // -----------------------------------------------------------
    reg         clk;
    reg         rst;
    reg         end_of_file_signal;
    reg         enable;
    reg  [23:0] data_in;

    wire [31:0] JPEG_bitstream;
    wire        data_ready;
    wire [4:0]  end_of_file_bitstream_count;
    wire        eof_data_partial_ready;

    // -----------------------------------------------------------
    // 2. Khai báo biến xử lý File I/O
    // -----------------------------------------------------------
    integer file_in;
    integer file_out;
    integer scan_status;

    // -----------------------------------------------------------
    // 3. Khởi tạo module jpeg_top
    // -----------------------------------------------------------
    jpeg_top uut (
        .clk(clk), 
        .rst(rst), 
        .end_of_file_signal(end_of_file_signal), 
        .enable(enable), 
        .data_in(data_in), 
        .JPEG_bitstream(JPEG_bitstream), 
        .data_ready(data_ready), 
        .end_of_file_bitstream_count(end_of_file_bitstream_count), 
        .eof_data_partial_ready(eof_data_partial_ready)
    );

    // -----------------------------------------------------------
    // 4. Tạo Clock (Tần số 100MHz -> Chu kỳ 10ns)
    // -----------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -----------------------------------------------------------
    // 5. Main Process: Đọc file và bơm dữ liệu
    // -----------------------------------------------------------
    initial begin
        // Mở file (ModelSim sẽ tìm file này trong thư mục chứa project)
        file_in  = $fopen("input_rgb.hex", "r");
        file_out = $fopen("output_bitstream.hex", "w");
        
        if (file_in == 0) begin
            $display("Error: Can't find file 'input_rgb.hex'. Run the Python code firsr.");
            $stop;
        end

        // Khởi tạo hệ thống
        rst = 1;
        enable = 0;
        end_of_file_signal = 0;
        data_in = 24'd0;

        #25;
        rst = 0; // Nhả reset
        #20;

        $display("------------- Simulation started ------------");
        $display("Patching data from input.hex to the system...");

        // Bơm từng dòng dữ liệu từ file vào module
        while (!$feof(file_in)) begin
            @(posedge clk);
            scan_status = $fscanf(file_in, "%x\n", data_in);
            
            if (scan_status == 1) begin
                enable = 1;
            end else begin
                enable = 0;
            end
        end

        // Hết file -> Tắt enable, bật cờ End of File
          @(posedge clk);
            end_of_file_signal = 1;
            @(posedge clk);
            end_of_file_signal = 0;

            // Tăng thời gian chờ lên 50,000 ns thay vì 2,000 ns
            #50000; 
            
            $fclose(file_in);
            $fclose(file_out); // BẮT BUỘC phải có lệnh này
            $stop;
    end

    // -----------------------------------------------------------
    // 6. Monitor Process: Ghi dữ liệu đầu ra
    // -----------------------------------------------------------
    always @(posedge clk) begin
        // Ghi các block 32-bit chẵn
        if (data_ready) begin
            $fwrite(file_out, "%08X\n", JPEG_bitstream);
        end
        
        // Ghi phần bit lẻ cuối cùng khi nhận EOF
        if (eof_data_partial_ready) begin
            $fwrite(file_out, "// EOF_PARTIAL: %08X (Valid bits: %0d)\n", 
                    JPEG_bitstream, end_of_file_bitstream_count);
        end
    end

endmodule