`timescale 1ns / 1ps

module dct_2d_1channel_tb;

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
        .Z00_final(out[0][0]), .Z01_final(out[0][1]), .Z02_final(out[0][2]), .Z03_final(out[0][3]), .Z04_final(out[0][4]), .Z05_final(out[0][5]), .Z06_final(out[0][6]), .Z07_final(out[0][7]),
        .Z10_final(out[1][0]), .Z11_final(out[1][1]), .Z12_final(out[1][2]), .Z13_final(out[1][3]), .Z14_final(out[1][4]), .Z15_final(out[1][5]), .Z16_final(out[1][6]), .Z17_final(out[1][7]),
        .Z20_final(out[2][0]), .Z21_final(out[2][1]), .Z22_final(out[2][2]), .Z23_final(out[2][3]), .Z24_final(out[2][4]), .Z25_final(out[2][5]), .Z26_final(out[2][6]), .Z27_final(out[2][7]),
        .Z30_final(out[3][0]), .Z31_final(out[3][1]), .Z32_final(out[3][2]), .Z33_final(out[3][3]), .Z34_final(out[3][4]), .Z35_final(out[3][5]), .Z36_final(out[3][6]), .Z37_final(out[3][7]),
        .Z40_final(out[4][0]), .Z41_final(out[4][1]), .Z42_final(out[4][2]), .Z43_final(out[4][3]), .Z44_final(out[4][4]), .Z45_final(out[4][5]), .Z46_final(out[4][6]), .Z47_final(out[4][7]),
        .Z50_final(out[5][0]), .Z51_final(out[5][1]), .Z52_final(out[5][2]), .Z53_final(out[5][3]), .Z54_final(out[5][4]), .Z55_final(out[5][5]), .Z56_final(out[5][6]), .Z57_final(out[5][7]),
        .Z60_final(out[6][0]), .Z61_final(out[6][1]), .Z62_final(out[6][2]), .Z63_final(out[6][3]), .Z64_final(out[6][4]), .Z65_final(out[6][5]), .Z66_final(out[6][6]), .Z67_final(out[6][7]),
        .Z70_final(out[7][0]), .Z71_final(out[7][1]), .Z72_final(out[7][2]), .Z73_final(out[7][3]), .Z74_final(out[7][4]), .Z75_final(out[7][5]), .Z76_final(out[7][6]), .Z77_final(out[7][7])
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
            $display(">>> Fetching BLOCK %0d <<<", block_id);
            
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
            $display("Completed DCT Function for 1 Block %0d. Result:", block_id);
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

        $display("Simulation Completed!");
        #100;
        $finish;
    end

endmodule