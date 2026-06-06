module sync_fifo_ff (clk, rst, read_req, write_data, write_enable, rollover_write,
read_data, fifo_empty, rdata_valid);
input	clk;
input	rst;
input	read_req;
input [90:0] write_data;
input write_enable;
input rollover_write;
output [90:0]   read_data;  
output  fifo_empty; 
output	rdata_valid;
   
reg [9:0] read_ptr;
reg [9:0] write_ptr;
reg [90:0] mem [0:511];
reg [90:0] read_data;
reg rdata_valid;
wire [8:0] write_addr = write_ptr[8:0];
wire [8:0] read_addr = read_ptr[8:0];	
wire read_enable = read_req && (~fifo_empty);
assign fifo_empty = (read_ptr == write_ptr);


always @(posedge clk)
  begin
   if (rst)
      write_ptr <= 10'b0;
   else if (write_enable & !rollover_write)
      write_ptr <= write_ptr + 10'd1;
   else if (write_enable & rollover_write)
      write_ptr <= write_ptr + 10'd2;
  end

always @(posedge clk)
begin
   if (rst)
      rdata_valid <= 1'b0;
   else if (read_enable)
      rdata_valid <= 1'b1;
   else
   	  rdata_valid <= 1'b0;  
end
  
always @(posedge clk)
 begin
   if (rst)
      read_ptr <= 10'b0;
   else if (read_enable)
      read_ptr <= read_ptr + 10'd1;
end

// Mem write
always @(posedge clk)
  begin
   if (write_enable)
     mem[write_addr] <= write_data;
  end
// Mem Read
always @(posedge clk)
  begin
   if (read_enable)
      read_data <= mem[read_addr];
  end
  
endmodule