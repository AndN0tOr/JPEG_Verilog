module cr_dqh(
    input         clk,
    input         rst,
    input         enable,
    input  [7:0]  data_in,
    output [31:0] JPEG_bitstream, 
    output        data_ready, 
    output [4:0]  cr_orc,         // Đổi tên từ y_orc sang cr_orc
    output        end_of_block_output,
    output        end_of_block_empty
);

    wire dct_enable, quantizer_enable;
    
    // Wires nối từ DCT sang Quantizer
    wire [11:0] Z11, Z12, Z13, Z14, Z15, Z16, Z17, Z18;
    wire [11:0] Z21, Z22, Z23, Z24, Z25, Z26, Z27, Z28;
    wire [11:0] Z31, Z32, Z33, Z34, Z35, Z36, Z37, Z38;
    wire [11:0] Z41, Z42, Z43, Z44, Z45, Z46, Z47, Z48;
    wire [11:0] Z51, Z52, Z53, Z54, Z55, Z56, Z57, Z58;
    wire [11:0] Z61, Z62, Z63, Z64, Z65, Z66, Z67, Z68;
    wire [11:0] Z71, Z72, Z73, Z74, Z75, Z76, Z77, Z78;
    wire [11:0] Z81, Z82, Z83, Z84, Z85, Z86, Z87, Z88;
    
    // Wires nối từ Quantizer sang Huffman
    wire [11:0] Q11, Q12, Q13, Q14, Q15, Q16, Q17, Q18; 	
    wire [11:0] Q21, Q22, Q23, Q24, Q25, Q26, Q27, Q28; 
    wire [11:0] Q31, Q32, Q33, Q34, Q35, Q36, Q37, Q38; 
    wire [11:0] Q41, Q42, Q43, Q44, Q45, Q46, Q47, Q48; 
    wire [11:0] Q51, Q52, Q53, Q54, Q55, Q56, Q57, Q58; 
    wire [11:0] Q61, Q62, Q63, Q64, Q65, Q66, Q67, Q68; 
    wire [11:0] Q71, Q72, Q73, Q74, Q75, Q76, Q77, Q78; 
    wire [11:0] Q81, Q82, Q83, Q84, Q85, Q86, Q87, Q88; 

    // 1. Khối 2D-DCT (Dùng chung module cho cả Y, Cb, Cr)
    dct_2d_1channel cr_dct_inst(
        .clk(clk), .rst(rst), .enable(enable), .data_in(data_in), 
        .Z11_final(Z11), .Z12_final(Z12), .Z13_final(Z13), .Z14_final(Z14), .Z15_final(Z15), .Z16_final(Z16), .Z17_final(Z17), .Z18_final(Z18), 
        .Z21_final(Z21), .Z22_final(Z22), .Z23_final(Z23), .Z24_final(Z24), .Z25_final(Z25), .Z26_final(Z26), .Z27_final(Z27), .Z28_final(Z28), 
        .Z31_final(Z31), .Z32_final(Z32), .Z33_final(Z33), .Z34_final(Z34), .Z35_final(Z35), .Z36_final(Z36), .Z37_final(Z37), .Z38_final(Z38), 
        .Z41_final(Z41), .Z42_final(Z42), .Z43_final(Z43), .Z44_final(Z44), .Z45_final(Z45), .Z46_final(Z46), .Z47_final(Z47), .Z48_final(Z48), 
        .Z51_final(Z51), .Z52_final(Z52), .Z53_final(Z53), .Z54_final(Z54), .Z55_final(Z55), .Z56_final(Z56), .Z57_final(Z57), .Z58_final(Z58), 
        .Z61_final(Z61), .Z62_final(Z62), .Z63_final(Z63), .Z64_final(Z64), .Z65_final(Z65), .Z66_final(Z66), .Z67_final(Z67), .Z68_final(Z68), 
        .Z71_final(Z71), .Z72_final(Z72), .Z73_final(Z73), .Z74_final(Z74), .Z75_final(Z75), .Z76_final(Z76), .Z77_final(Z77), .Z78_final(Z78), 
        .Z81_final(Z81), .Z82_final(Z82), .Z83_final(Z83), .Z84_final(Z84), .Z85_final(Z85), .Z86_final(Z86), .Z87_final(Z87), .Z88_final(Z88), 
        .output_enable(dct_enable)
    ); 
	
    // 2. Khối Quantizer cho Cr
    chroma_quantizer cr_quant(
        .clk(clk), .rst(rst), .enable(dct_enable),
        .Z11(Z11), .Z12(Z12), .Z13(Z13), .Z14(Z14), .Z15(Z15), .Z16(Z16), .Z17(Z17), .Z18(Z18), 
        .Z21(Z21), .Z22(Z22), .Z23(Z23), .Z24(Z24), .Z25(Z25), .Z26(Z26), .Z27(Z27), .Z28(Z28),
        .Z31(Z31), .Z32(Z32), .Z33(Z33), .Z34(Z34), .Z35(Z35), .Z36(Z36), .Z37(Z37), .Z38(Z38), 
        .Z41(Z41), .Z42(Z42), .Z43(Z43), .Z44(Z44), .Z45(Z45), .Z46(Z46), .Z47(Z47), .Z48(Z48),
        .Z51(Z51), .Z52(Z52), .Z53(Z53), .Z54(Z54), .Z55(Z55), .Z56(Z56), .Z57(Z57), .Z58(Z58), 
        .Z61(Z61), .Z62(Z62), .Z63(Z63), .Z64(Z64), .Z65(Z65), .Z66(Z66), .Z67(Z67), .Z68(Z68),
        .Z71(Z71), .Z72(Z72), .Z73(Z73), .Z74(Z74), .Z75(Z75), .Z76(Z76), .Z77(Z77), .Z78(Z78), 
        .Z81(Z81), .Z82(Z82), .Z83(Z83), .Z84(Z84), .Z85(Z85), .Z86(Z86), .Z87(Z87), .Z88(Z88),
        .Q11(Q11), .Q12(Q12), .Q13(Q13), .Q14(Q14), .Q15(Q15), .Q16(Q16), .Q17(Q17), .Q18(Q18), 
        .Q21(Q21), .Q22(Q22), .Q23(Q23), .Q24(Q24), .Q25(Q25), .Q26(Q26), .Q27(Q27), .Q28(Q28),
        .Q31(Q31), .Q32(Q32), .Q33(Q33), .Q34(Q34), .Q35(Q35), .Q36(Q36), .Q37(Q37), .Q38(Q38), 
        .Q41(Q41), .Q42(Q42), .Q43(Q43), .Q44(Q44), .Q45(Q45), .Q46(Q46), .Q47(Q47), .Q48(Q48),
        .Q51(Q51), .Q52(Q52), .Q53(Q53), .Q54(Q54), .Q55(Q55), .Q56(Q56), .Q57(Q57), .Q58(Q58), 
        .Q61(Q61), .Q62(Q62), .Q63(Q63), .Q64(Q64), .Q65(Q65), .Q66(Q66), .Q67(Q67), .Q68(Q68),
        .Q71(Q71), .Q72(Q72), .Q73(Q73), .Q74(Q74), .Q75(Q75), .Q76(Q76), .Q77(Q77), .Q78(Q78), 
        .Q81(Q81), .Q82(Q82), .Q83(Q83), .Q84(Q84), .Q85(Q85), .Q86(Q86), .Q87(Q87), .Q88(Q88),
        .out_enable(quantizer_enable)
    );

    // 3. Khối Huffman cho Cr (Lưu ý: Có phép vị tự/Transpose ma trận Qij -> Cji như bản gốc)
    chroma_huff cr_huff(
        .clk(clk), .rst(rst), .enable(quantizer_enable), 
        .C11(Q11), .C12(Q21), .C13(Q31), .C14(Q41), .C15(Q51), .C16(Q61), .C17(Q71), .C18(Q81), 
        .C21(Q12), .C22(Q22), .C23(Q32), .C24(Q42), .C25(Q52), .C26(Q62), .C27(Q72), .C28(Q82),
        .C31(Q13), .C32(Q23), .C33(Q33), .C34(Q43), .C35(Q53), .C36(Q63), .C37(Q73), .C38(Q83), 
        .C41(Q14), .C42(Q24), .C43(Q34), .C44(Q44), .C45(Q54), .C46(Q64), .C47(Q74), .C48(Q84),
        .C51(Q15), .C52(Q25), .C53(Q35), .C54(Q45), .C55(Q55), .C56(Q65), .C57(Q75), .C58(Q85), 
        .C61(Q16), .C62(Q26), .C63(Q36), .C64(Q46), .C65(Q56), .C66(Q66), .C67(Q76), .C68(Q86),
        .C71(Q17), .C72(Q27), .C73(Q37), .C74(Q47), .C75(Q57), .C76(Q67), .C77(Q77), .C78(Q87), 
        .C81(Q18), .C82(Q28), .C83(Q38), .C84(Q48), .C85(Q58), .C86(Q68), .C87(Q78), .C88(Q88),
        .JPEG_bitstream(JPEG_bitstream), 
        .data_ready(data_ready), 
        .output_reg_count(cr_orc),
        .end_of_block_output(),
        .end_of_block_empty(end_of_block_empty)
    );	

endmodule