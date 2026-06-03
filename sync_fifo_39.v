`timescale 1ns / 100ps

module sync_fifo_39 (
    input clk, 
    input rst, 
    input read_req, 
    input [38:0] write_data, 
    input write_enable,
    output [38:0] read_data, 
    output fifo_empty, 
    output rdata_valid, 
    output fifo_full
);

    reg [11:0] read_ptr;
    reg [11:0] write_ptr;
    reg [38:0] mem [0:2047];

    wire [10:0] write_addr = write_ptr[10:0];
    wire [10:0] read_addr = read_ptr[10:0];
    
    wire read_enable = read_req && (~fifo_empty);
    
    assign fifo_empty = (read_ptr == write_ptr);
    assign fifo_full = (write_ptr[10:0] == read_ptr[10:0]) && (write_ptr[11] != read_ptr[11]);

    // Write Pointer
    always @(posedge clk) begin
        if (rst)
            write_ptr <= 12'b0;
        else if (write_enable && ~fifo_full)
            write_ptr <= write_ptr + 12'b1;
    end

    // Read Pointer
    always @(posedge clk) begin
        if (rst)
            read_ptr <= 12'b0;
        else if (read_enable)
            read_ptr <= read_ptr + 12'b1;
    end

    // Mem write
    always @(posedge clk) begin
        if (write_enable && ~fifo_full)
            mem[write_addr] <= write_data;
    end

    // FWFT Mem Read
    assign read_data = mem[read_addr];
    assign rdata_valid = ~fifo_empty;
  
endmodule
