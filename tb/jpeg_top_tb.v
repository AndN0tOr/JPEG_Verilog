`timescale 1ns / 1ps

module jpeg_top_tb();

    reg         clk;
    reg         rst;
    reg         end_of_file_signal;
    reg         enable;
    reg  [23:0] data_in;

    wire [31:0] JPEG_bitstream;
    wire        data_ready;
    wire [4:0]  end_of_file_bitstream_count;
    wire        eof_data_partial_ready;

    integer file_in;
    integer file_out;
    integer scan_status;
    integer data_count;
    integer wait_count;
    integer pixel_count = 0;
    integer expected_blocks = 0;
    integer y_block_count = 0;

    always @(posedge clk) begin
        if (uut.u19.end_of_block_output) begin
            y_block_count = y_block_count + 1;
        end
    end

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

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        file_in  = $fopen("input_rgb.hex", "r");
        file_out = $fopen("output_bitstream.hex", "w");
        data_count = 0;

        if (file_in == 0) begin
            $display("Error: Can't find file 'input_rgb.hex'.");
            $stop;
        end

        rst = 1;
        enable = 0;
        end_of_file_signal = 0;
        data_in = 24'd0;

        #25;
        rst = 0;
        #20;

        $display("------------- Simulation started ------------");
        $display("Patching data from input.hex to the system...");

        while (!$feof(file_in)) begin
            @(posedge clk);
            scan_status = $fscanf(file_in, "%x\n", data_in);

            if (scan_status == 1) begin
                enable = 1;
                pixel_count = pixel_count + 1;
            end else begin
                enable = 0;
            end
        end

        expected_blocks = pixel_count / 64;

        @(posedge clk);
        enable = 0;
        
        $display("Input data finished. Total pixels read: %0d. Expected blocks: %0d", pixel_count, expected_blocks);
        $display("Waiting for pipeline to process all blocks...");
        
        // Wait until all blocks are processed by y_huff
        wait_count = 0;
        while (y_block_count < expected_blocks && wait_count < 10000000) begin
            @(posedge clk);
            wait_count = wait_count + 1;
        end
        
        if (y_block_count >= expected_blocks) begin
            $display("All %0d blocks processed. Waiting for FIFOs to flush...", expected_blocks);
        end else begin
            $display("Timeout waiting for blocks. Only processed %0d blocks out of %0d", y_block_count, expected_blocks);
        end
        
        // Wait additional time for FIFOs and output packer to flush
        #20000; 

        end_of_file_signal = 1;
        @(posedge clk);
        end_of_file_signal = 0;

        $display("Waiting for EOF bitstream packer to complete...");
        wait_count = 0;
        while (wait_count < 10000000 && !eof_data_partial_ready) begin
            @(posedge clk);
            wait_count = wait_count + 1;
            if (wait_count % 10000000 == 0) begin
                $display("  Still waiting... %0d outputs so far", data_count);
            end
        end

        if (eof_data_partial_ready) begin
            $display("EOF partial ready detected at time %0t", $time);
        end else begin
            $display("Timeout waiting for EOF");
        end

        #10000;

        $fclose(file_in);
        $fclose(file_out);
        $display("Simulation completed. Total outputs: %0d", data_count);
        $display("Total completed Y blocks: %0d (Expected: 4320)", y_block_count);
        $stop;
    end



    always @(posedge clk) begin
        if (data_ready) begin
            $fwrite(file_out, "%08X\n", JPEG_bitstream);
            data_count = data_count + 1;
            if (data_count <= 10 || data_count % 1000 == 0) begin
                $display("[%0t] Data #%0d: %08X", $time, data_count, JPEG_bitstream);
            end
        end

        if (eof_data_partial_ready) begin
            $fwrite(file_out, "// EOF_PARTIAL: %08X (Valid bits: %0d)\n",
                    JPEG_bitstream, end_of_file_bitstream_count);
            $display("[%0t] EOF partial: %08X (bits: %0d)", $time, JPEG_bitstream, end_of_file_bitstream_count);
        end
    end

    initial begin
        #100000;
        if (data_count == 0) begin
            $display("[WARNING] No data_ready after 100us");
        end
    end

endmodule
