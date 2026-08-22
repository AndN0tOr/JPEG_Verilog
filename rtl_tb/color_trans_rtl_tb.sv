`timescale 1ns / 1ns
`include "../rtl/jpeg_core/color_trans.sv"

module color_trans_rtl_tb;
    logic       clk;
    logic       rst;
    logic       enable;
    data_in_t   data_in;
    logic       out_enable;
    data_out_t  data_out;
    color_trans DUT(
        .clk(clk), 
        .rst(rst), 
        .enable(enable),
        .data_in(data_in), 
        .out_enable(out_enable), 
        .data_out(data_out)
        );

    always #5 clk = ~clk; 

    function data_out_t get_ref_data_out(data_in_t data_in);
      data_out_t data_out_ref;
      int y_32, cb_32, cr_32;
      assign y_32 = $rtoi(data_in.r * 0.299 + 0.587 * data_in.g + 0.114 * data_in.b);
      assign cb_32 = $rtoi(128 - 0.168736 * data_in.r - 0.331264 * data_in.g + 0.5*data_in.b);
      assign cr_32 = $rtoi(128 + 0.5* data_in.r - 0.418688 * data_in.g - 0.081312 * data_in.b);

      data_out_ref.y = (y_32 > 255) ? 8'd255 : (y_32 < 0) ? 8'd0 : y_32[7:0];
      data_out_ref.cb = (cb_32 > 255) ? 8'd255 : (cb_32 < 0) ? 8'd0 : cb_32[7:0];
      data_out_ref.cr = (cr_32 > 255) ? 8'd255 : (cr_32 < 0) ? 8'd0 : cr_32[7:0];

      return data_out_ref;
    endfunction
    
    initial begin
        clk = 0;
        rst = 1;
        enable = 0;
        data_in = 24'd0;
        #30 
        rst = 0;
        #10
        enable = 1;
        data_in = '{8'd255, 8'd255, 8'd255};  #10; // White
        data_in = '{8'd0,   8'd0,   8'd0  };  #10; // Black
        data_in = '{8'd255, 8'd0,   8'd0  };  #10; // Red
        data_in = '{8'd0,   8'd255, 8'd0  };  #10; // Green
        data_in = '{8'd0,   8'd0,   8'd255};  #10; // Blue
        data_in = '{8'd37,  8'd142, 8'd219};  #10
        data_in = '{8'd201, 8'd54,  8'd87 };  #10
        data_in = '{8'd16,  8'd231, 8'd104};  #10
        data_in = '{8'd245, 8'd173, 8'd29 };  #10
        data_in = '{8'd92,  8'd41,  8'd198};  #10
        data_in = '{8'd134, 8'd217, 8'd63 };  #10
        data_in = '{8'd255, 8'd96,  8'd12 };  #10
        data_in = '{8'd73,  8'd188, 8'd240};  #10
        data_in = '{8'd159, 8'd22,  8'd116};  #10
        data_in = '{8'd48,  8'd245, 8'd176};  #10
        data_in = '{8'd224, 8'd118, 8'd67 };  #40
        enable = 0;
        $finish;
    end
    
    always @(posedge clk) begin
        if (out_enable)begin
            $display (
                "Time : %d ns | -> Y: %3d | Cb: %3d | Cr: %3d", 
                $time, data_out.y, data_out.cb, data_out.cr);
        end
    end


endmodule