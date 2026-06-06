module task_learn(
    input clk,
    input rst,
    input enable,
    input [7:0] data_in,
    output output_enable,
    output [10:0] o11, o12, o13, o14, o15, o16, o17, o18,
    output [10:0] o21, o22, o23, o24, o25, o26, o27, o28,
    output [10:0] o31, o32, o33, o34, o35, o36, o37, o38,
    output [10:0] o41, o42, o43, o44, o45, o46, o47, o48,
    output [10:0] o51, o52, o53, o54, o55, o56, o57, o58,
    output [10:0] o61, o62, o63, o64, o65, o66, o67, o68,
    output [10:0] o71, o72, o73, o74, o75, o76, o77, o78,
    output [10:0] o81, o82, o83, o84, o85, o86, o87, o88
); 
reg [2:0] count;
integer T1, T21, T22, T23, T24, T25, T26, T27, T28, 
        T31, T32, T33, T34, T52;
integer iT1, iT21, iT22, iT23, iT24, iT25, iT26, iT27, 
        iT28, iT31, iT32, iT33, iT34, iT52;
integer Y2_mul_input, Y3_mul_input, Y4_mul_input, Y5_mul_input;
integer Y6_mul_input, Y7_mul_input, Y8_mul_input;

integer iT2_mul_input, iT3_mul_input, iT4_mul_input, iT5_mul_input;
integer iT6_mul_input, iT7_mul_input, iT8_mul_input;

always @(posedge clk)
begin
	case (count)
	3'b000:		begin
        Y2_mul_input <= T21;    Y3_mul_input <= T31;    Y4_mul_input <= T22;    Y5_mul_input <= T1;	
        Y6_mul_input <= T23;    Y7_mul_input <= T32;    Y8_mul_input <= T24;
    end
	3'b001:		begin
        Y2_mul_input <= T22;	Y3_mul_input <= T32;    Y4_mul_input <= T25;    Y5_mul_input <= T52;
        Y6_mul_input <= T28;    Y7_mul_input <= T34;    Y8_mul_input <= T26;
    end
	3'b010:		begin
        Y2_mul_input <= T23;	Y3_mul_input <= T33;    Y4_mul_input <= T28;    Y5_mul_input <= T52;
        Y6_mul_input <= T24;    Y7_mul_input <= T31;    Y8_mul_input <= T22;
    end
	3'b011:		begin
        Y2_mul_input <= T24;    Y3_mul_input <= T34;    Y4_mul_input <= T26;    Y5_mul_input <= T1;
        Y6_mul_input <= T22;    Y7_mul_input <= T33;    Y8_mul_input <= T28;
    end
	3'b100:		begin
        Y2_mul_input <= T25;	Y3_mul_input <= T34;    Y4_mul_input <= T23;    Y5_mul_input <= T1;	
        Y6_mul_input <= T27;    Y7_mul_input <= T33;    Y8_mul_input <= T21;
    end
	3'b101:		begin
        Y2_mul_input <= T26;    Y3_mul_input <= T33;    Y4_mul_input <= T21;    Y5_mul_input <= T52;
        Y6_mul_input <= T25;    Y7_mul_input <= T31;    Y8_mul_input <= T27;
    end
	3'b110:		begin
        Y2_mul_input <= T27;    Y3_mul_input <= T32;    Y4_mul_input <= T24;    Y5_mul_input <= T52;
        Y6_mul_input <= T21;    Y7_mul_input <= T34;    Y8_mul_input <= T23;
    end
	3'b111:		begin
        Y2_mul_input <= T28;    Y3_mul_input <= T31;    Y4_mul_input <= T27;    Y5_mul_input <= T1;
        Y6_mul_input <= T26;    Y7_mul_input <= T32;    Y8_mul_input <= T25;
    end 
	endcase
end
endmodule   
