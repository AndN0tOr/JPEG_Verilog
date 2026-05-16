`timescale 1ns / 1ps

module y_dct_tb;

    // --- Tín hiệu điều khiển ---
    reg clk;
    reg rst;
    reg enable;
    reg signed [7:0] data_in;

    // --- Tín hiệu đầu ra ---
    wire output_enable;
    wire signed [11:0] out [0:7][0:7];

    // --- Khởi tạo Module y_dct ---
    dct_2d_1channel uut (
        .clk(clk), .rst(rst), .enable(enable), .data_in(data_in), .output_enable(output_enable),
        .out00(out[0][0]), .out01(out[0][1]), .out02(out[0][2]), .out03(out[0][3]), .out04(out[0][4]), .out05(out[0][5]), .out06(out[0][6]), .out07(out[0][7]),
        .out10(out[1][0]), .out11(out[1][1]), .out12(out[1][2]), .out13(out[1][3]), .out14(out[1][4]), .out15(out[1][5]), .out16(out[1][6]), .out17(out[1][7]),
        .out20(out[2][0]), .out21(out[2][1]), .out22(out[2][2]), .out23(out[2][3]), .out24(out[2][4]), .out25(out[2][5]), .out26(out[2][6]), .out27(out[2][7]),
        .out30(out[3][0]), .out31(out[3][1]), .out32(out[3][2]), .out33(out[3][3]), .out34(out[3][4]), .out35(out[3][5]), .out36(out[3][6]), .out37(out[3][7]),
        .out40(out[4][0]), .out41(out[4][1]), .out42(out[4][2]), .out43(out[4][3]), .out44(out[4][4]), .out45(out[4][5]), .out46(out[4][6]), .out47(out[4][7]),
        .out50(out[5][0]), .out51(out[5][1]), .out52(out[5][2]), .out53(out[5][3]), .out54(out[5][4]), .out55(out[5][5]), .out56(out[5][6]), .out57(out[5][7]),
        .out60(out[6][0]), .out61(out[6][1]), .out62(out[6][2]), .out63(out[6][3]), .out64(out[6][4]), .out65(out[6][5]), .out66(out[6][6]), .out67(out[6][7]),
        .out70(out[7][0]), .out71(out[7][1]), .out72(out[7][2]), .out73(out[7][3]), .out74(out[7][4]), .out75(out[7][5]), .out76(out[7][6]), .out77(out[7][7])
    );

    // --- Tạo xung Clock (100MHz) ---
    always #5 clk = ~clk;

    // --- Bộ nhớ chứa các Block Test ---
    reg signed [7:0] block1 [0:7][0:7];
    reg signed [7:0] block2 [0:7][0:7];
    reg signed [7:0] block3 [0:7][0:7];

    integer r, c;

    // ==========================================
    // TASK: HÀM IN KẾT QUẢ RA MÀN HÌNH
    // ==========================================
    task print_output;
        integer i;
        begin
            $display("-------------------------------------------------------------------------");
            for (i = 0; i < 8; i = i + 1) begin
                $display("%5d | %5d | %5d | %5d | %5d | %5d | %5d | %5d", 
                    $signed(out[i][0]), $signed(out[i][1]), $signed(out[i][2]), $signed(out[i][3]),
                    $signed(out[i][4]), $signed(out[i][5]), $signed(out[i][6]), $signed(out[i][7]));
            end
            $display("-------------------------------------------------------------------------\n");
        end
    endtask

    // ==========================================
    // TASK: HÀM NẠP 1 BLOCK DỮ LIỆU BẤT KỲ VÀO MẠCH
    // ==========================================
    task run_dct_block;
        input integer block_id;
        integer r, c;
        begin
            $display(">>> BẮT ĐẦU NẠP BLOCK %0d <<<", block_id);
            
            for (r = 0; r < 8; r = r + 1) begin
                for (c = 0; c < 8; c = c + 1) begin
                    enable = 1;
                    if (block_id == 1)      data_in = block1[r][c];
                    else if (block_id == 2) data_in = block2[r][c];
                    else                    data_in = block3[r][c];
                    #10; // Đợi 1 chu kỳ clock
                end
                enable = 0; 
                #20; // Nghỉ 2 chu kỳ giữa các hàng (Giống format cũ của bạn)
            end

            // Bắt sự kiện sườn lên của output_enable thay vì dùng wait()
            // Điều này an toàn tuyệt đối với các tín hiệu pulse (chớp 1 nhịp)
            @(posedge output_enable);
            
            #10; // Đợi thêm 1 chút cho tín hiệu ổn định trên Waveform
            $display("✅ Hoàn thành tính toán Block %0d. Kết quả:", block_id);
            print_output();
            
            // Thời gian nghỉ tĩnh giữa 2 block dữ liệu liên tiếp
            #100;
        end
    endtask


    // ==========================================
    // LUỒNG CHẠY CHÍNH (MAIN THREAD)
    // ==========================================
    initial begin
        // Khởi tạo trạng thái
        clk = 0;
        rst = 1;
        enable = 0;
        data_in = 0;

        // --- NẠP DỮ LIỆU CHO BLOCK 1 (Dữ liệu gốc của bạn) ---
        block1[0][0] = -76; block1[0][1] = -73; block1[0][2] = -67; block1[0][3] = -62; block1[0][4] = -58; block1[0][5] = -67; block1[0][6] = -64; block1[0][7] = -55;
        block1[1][0] = -65; block1[1][1] = -69; block1[1][2] = -73; block1[1][3] = -38; block1[1][4] = -19; block1[1][5] = -43; block1[1][6] = -59; block1[1][7] = -56;
        block1[2][0] = -66; block1[2][1] = -69; block1[2][2] = -60; block1[2][3] = -15; block1[2][4] =  16; block1[2][5] = -24; block1[2][6] = -62; block1[2][7] = -55;
        block1[3][0] = -65; block1[3][1] = -70; block1[3][2] = -57; block1[3][3] =  -6; block1[3][4] =  26; block1[3][5] = -22; block1[3][6] = -58; block1[3][7] = -59;
        block1[4][0] = -61; block1[4][1] = -67; block1[4][2] = -60; block1[4][3] = -24; block1[4][4] =  -2; block1[4][5] = -40; block1[4][6] = -60; block1[4][7] = -58;
        block1[5][0] = -49; block1[5][1] = -63; block1[5][2] = -68; block1[5][3] = -58; block1[5][4] = -51; block1[5][5] = -60; block1[5][6] = -70; block1[5][7] = -53;
        block1[6][0] = -43; block1[6][1] = -57; block1[6][2] = -64; block1[6][3] = -69; block1[6][4] = -73; block1[6][5] = -67; block1[6][6] = -63; block1[6][7] = -45;
        block1[7][0] = -41; block1[7][1] = -49; block1[7][2] = -59; block1[7][3] = -60; block1[7][4] = -63; block1[7][5] = -52; block1[7][6] = -50; block1[7][7] = -34;

        // --- NẠP DỮ LIỆU CHO BLOCK 2 (Mảng phẳng một màu) ---
        for (r = 0; r < 8; r = r + 1) begin
            for (c = 0; c < 8; c = c + 1) begin
                block2[r][c] = 50; // Toàn bộ mang giá trị 50
            end
        end

        // --- NẠP DỮ LIỆU CHO BLOCK 3 (Mảng kẻ sọc dọc xen kẽ) ---
        for (r = 0; r < 8; r = r + 1) begin
            for (c = 0; c < 8; c = c + 1) begin
                block3[r][c] = (c % 2 == 0) ? 100 : -100;
            end
        end

        // --- THỰC THI MÔ PHỎNG ---
        #20 rst = 0; // Nhả Reset để bắt đầu
        #20;

        // Chạy lần lượt 3 block bằng hàm Task (rất gọn gàng)
        run_dct_block(1);
        run_dct_block(2);
        run_dct_block(3);

        $display("🚀 MÔ PHỎNG HOÀN TẤT TOÀN BỘ!");
        #100;
        $finish;
    end

endmodule