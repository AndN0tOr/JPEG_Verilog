`timescale 1ps / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

// ============================================================================
// INTERFACE
// ============================================================================
interface dct_if (
    input logic clk,
    input logic rst
);
  logic enable;
  logic [7:0] data_in;
  logic output_enable;

  logic [11:0]
      Z11_final,
      Z12_final,
      Z13_final,
      Z14_final,
      Z15_final,
      Z16_final,
      Z17_final,
      Z18_final,
      Z21_final,
      Z22_final,
      Z23_final,
      Z24_final,
      Z25_final,
      Z26_final,
      Z27_final,
      Z28_final,
      Z31_final,
      Z32_final,
      Z33_final,
      Z34_final,
      Z35_final,
      Z36_final,
      Z37_final,
      Z38_final,
      Z41_final,
      Z42_final,
      Z43_final,
      Z44_final,
      Z45_final,
      Z46_final,
      Z47_final,
      Z48_final,
      Z51_final,
      Z52_final,
      Z53_final,
      Z54_final,
      Z55_final,
      Z56_final,
      Z57_final,
      Z58_final,
      Z61_final,
      Z62_final,
      Z63_final,
      Z64_final,
      Z65_final,
      Z66_final,
      Z67_final,
      Z68_final,
      Z71_final,
      Z72_final,
      Z73_final,
      Z74_final,
      Z75_final,
      Z76_final,
      Z77_final,
      Z78_final,
      Z81_final,
      Z82_final,
      Z83_final,
      Z84_final,
      Z85_final,
      Z86_final,
      Z87_final,
      Z88_final;
endinterface

// ============================================================================
// SEQUENCE ITEM
// ============================================================================
class dct_item extends uvm_sequence_item;
  // SỬA LẠI: Phải dùng mảng 64 phần tử cho cả In và Out
  rand bit [7:0] data_in_block[64];
  bit [11:0] z_out[64];

  `uvm_object_utils_begin(dct_item)
    `uvm_field_sarray_int(data_in_block, UVM_ALL_ON)
    `uvm_field_sarray_int(z_out, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "dct_item");
    super.new(name);
  endfunction
endclass

// ============================================================================
// SEQUENCE
// ============================================================================
class dct_sequence extends uvm_sequence #(dct_item);
  `uvm_object_utils(dct_sequence)

  function new(string name = "dct_sequence");
    super.new(name);
  endfunction

  virtual task body();
    repeat (100) begin  // Rút gọn còn 100 block để chạy nhanh hơn
      req = dct_item::type_id::create("req");
      start_item(req);
      // Randomize 64 byte cho 1 block ảnh
      foreach (req.data_in_block[i]) begin
        req.data_in_block[i] = $urandom_range(0, 255);
      end
      finish_item(req);
    end
  endtask
endclass

// ============================================================================
// DRIVER
// ============================================================================
class dct_driver extends uvm_driver #(dct_item);
  `uvm_component_utils(dct_driver)
  virtual dct_if vif;

  function new(string name = "dct_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dct_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {"Virtual interface has not been set: ", get_full_name(), ".vif"})
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.enable  <= 0;
    vif.data_in <= 0;
    wait (!vif.rst);

    forever begin
      seq_item_port.get_next_item(req);
      // SỬA LẠI: Đẩy tuần tự 64 byte vào RTL (mỗi xung nhịp 1 byte)
      for (int i = 0; i < 64; i++) begin
        @(posedge vif.clk);
        vif.enable  <= 1'b1;
        vif.data_in <= req.data_in_block[i];
      end

      // Tắt enable sau khi đẩy xong 1 block
      @(posedge vif.clk);
      vif.enable <= 1'b0;

      seq_item_port.item_done();
    end
  endtask
endclass

// ============================================================================
// MONITOR
// ============================================================================
class dct_monitor extends uvm_monitor;
  `uvm_component_utils(dct_monitor)
  virtual dct_if vif;

  uvm_analysis_port #(dct_item) in_ap;
  uvm_analysis_port #(dct_item) out_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    in_ap  = new("in_ap", this);
    out_ap = new("out_ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dct_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {"Virtual interface has not been set: ", get_full_name(), ".vif"})
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      // Luồng 1: Hứng Input (Gom đủ 64 byte mới bắn lên Scoreboard)
      begin
        int count = 0;
        dct_item item_in;
        forever begin
          @(posedge vif.clk);
          if (vif.enable && !vif.rst) begin
            if (count == 0) item_in = dct_item::type_id::create("item_in");

            item_in.data_in_block[count] = vif.data_in;
            count++;

            if (count == 64) begin
              in_ap.write(item_in);
              count = 0;
            end
          end
        end
      end

      // Luồng 2: Hứng Output (GOM RÁC CỦA BẠN ĐÂY!)
      begin
        forever begin
          @(posedge vif.clk);
          if (vif.output_enable && !vif.rst) begin
            dct_item item_out = dct_item::type_id::create("item_out");

            // Map 64 dây từ interface vào mảng phần mềm
            item_out.z_out[0]  = vif.Z11_final;
            item_out.z_out[1]  = vif.Z12_final;
            item_out.z_out[2]  = vif.Z13_final;
            item_out.z_out[3]  = vif.Z14_final;
            item_out.z_out[4]  = vif.Z15_final;
            item_out.z_out[5]  = vif.Z16_final;
            item_out.z_out[6]  = vif.Z17_final;
            item_out.z_out[7]  = vif.Z18_final;
            item_out.z_out[8]  = vif.Z21_final;
            item_out.z_out[9]  = vif.Z22_final;
            item_out.z_out[10] = vif.Z23_final;
            item_out.z_out[11] = vif.Z24_final;
            item_out.z_out[12] = vif.Z25_final;
            item_out.z_out[13] = vif.Z26_final;
            item_out.z_out[14] = vif.Z27_final;
            item_out.z_out[15] = vif.Z28_final;
            item_out.z_out[16] = vif.Z31_final;
            item_out.z_out[17] = vif.Z32_final;
            item_out.z_out[18] = vif.Z33_final;
            item_out.z_out[19] = vif.Z34_final;
            item_out.z_out[20] = vif.Z35_final;
            item_out.z_out[21] = vif.Z36_final;
            item_out.z_out[22] = vif.Z37_final;
            item_out.z_out[23] = vif.Z38_final;
            item_out.z_out[24] = vif.Z41_final;
            item_out.z_out[25] = vif.Z42_final;
            item_out.z_out[26] = vif.Z43_final;
            item_out.z_out[27] = vif.Z44_final;
            item_out.z_out[28] = vif.Z45_final;
            item_out.z_out[29] = vif.Z46_final;
            item_out.z_out[30] = vif.Z47_final;
            item_out.z_out[31] = vif.Z48_final;
            item_out.z_out[32] = vif.Z51_final;
            item_out.z_out[33] = vif.Z52_final;
            item_out.z_out[34] = vif.Z53_final;
            item_out.z_out[35] = vif.Z54_final;
            item_out.z_out[36] = vif.Z55_final;
            item_out.z_out[37] = vif.Z56_final;
            item_out.z_out[38] = vif.Z57_final;
            item_out.z_out[39] = vif.Z58_final;
            item_out.z_out[40] = vif.Z61_final;
            item_out.z_out[41] = vif.Z62_final;
            item_out.z_out[42] = vif.Z63_final;
            item_out.z_out[43] = vif.Z64_final;
            item_out.z_out[44] = vif.Z65_final;
            item_out.z_out[45] = vif.Z66_final;
            item_out.z_out[46] = vif.Z67_final;
            item_out.z_out[47] = vif.Z68_final;
            item_out.z_out[48] = vif.Z71_final;
            item_out.z_out[49] = vif.Z72_final;
            item_out.z_out[50] = vif.Z73_final;
            item_out.z_out[51] = vif.Z74_final;
            item_out.z_out[52] = vif.Z75_final;
            item_out.z_out[53] = vif.Z76_final;
            item_out.z_out[54] = vif.Z77_final;
            item_out.z_out[55] = vif.Z78_final;
            item_out.z_out[56] = vif.Z81_final;
            item_out.z_out[57] = vif.Z82_final;
            item_out.z_out[58] = vif.Z83_final;
            item_out.z_out[59] = vif.Z84_final;
            item_out.z_out[60] = vif.Z85_final;
            item_out.z_out[61] = vif.Z86_final;
            item_out.z_out[62] = vif.Z87_final;
            item_out.z_out[63] = vif.Z88_final;

            out_ap.write(item_out);
          end
        end
      end
    join
  endtask
endclass

// ============================================================================
// SCOREBOARD
// ============================================================================
`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)

class dct_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(dct_scoreboard)

  uvm_analysis_imp_in #(dct_item, dct_scoreboard) in_export;
  uvm_analysis_imp_out #(dct_item, dct_scoreboard) out_export;

  dct_item in_queue[$];
  int MAX_TOLERANCE = 2;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    in_export  = new("in_export", this);
    out_export = new("out_export", this);
  endfunction

  virtual function void write_in(dct_item item);
    in_queue.push_back(item);
  endfunction

  virtual function void write_out(dct_item act_item);
    dct_item exp_item;
    bit [11:0] exp_dct[64];
    int diff;
    bit is_pass = 1;

    if (in_queue.size() == 0) begin
      `uvm_error("SCB", "Received output but queue input is empty!")
      return;
    end

    exp_item = in_queue.pop_front();
    golden_dct(exp_item.data_in_block, exp_dct);

    for (int i = 0; i < 64; i++) begin
      // SỬA LẠI: act_item.z_out[i]
      diff = $signed(exp_dct[i]) - $signed(act_item.z_out[i]);

      if (diff < 0) diff = -diff;

      if (diff > MAX_TOLERANCE) begin
        `uvm_error("SCB_Fail", $sformatf("Wrong at index %0d! Exp: %0d, Act: %0d, Diff: %0d", i,
                                         $signed(exp_dct[i]), $signed(act_item.z_out[i]), diff))
        is_pass = 0;
      end
    end

    if (is_pass) begin
      `uvm_info("SCB_pass", "1 block has verified functionally true.", UVM_MEDIUM)
    end
  endfunction

  // SỬA LẠI: Hàm phải nhận mảng 64 phần tử
  virtual function void golden_dct(bit [7:0] data_gld_in[64], ref bit [11:0] exp_gld_out[64]);
    real pi = 3.141592654;
    real cu, cv, sum, pixel_val;
    int x, y, u, v;

    for (u = 0; u < 8; u++) begin
      for (v = 0; v < 8; v++) begin
        sum = 0.0;
        for (x = 0; x < 8; x++) begin
          for (y = 0; y < 8; y++) begin
            // SỬA LẠI: Trừ 128 theo chuẩn JPEG (Level shift)
            pixel_val = real'(data_gld_in[x*8+y]) - 128.0;
            sum += pixel_val * $cos(
                (2.0 * x + 1.0) * real'(u) * pi / 16.0
            ) * $cos(
                (2.0 * y + 1.0) * real'(v) * pi / 16.0
            );
          end
        end
        cu = (u == 0) ? (1.0 / $sqrt(2.0)) : 1.0;
        cv = (v == 0) ? (1.0 / $sqrt(2.0)) : 1.0;
        sum = 0.25 * cu * cv * sum;
        exp_gld_out[u*8+v] = 12'($rtoi(sum));
      end
    end
  endfunction
endclass

// ============================================================================
// AGENT & ENV
// ============================================================================
typedef uvm_sequencer#(dct_item) dct_sequencer;

class dct_agent extends uvm_agent;
  `uvm_component_utils(dct_agent)
  dct_driver driver;
  dct_monitor monitor;
  dct_sequencer sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver = dct_driver::type_id::create("dct_driver", this);
    monitor = dct_monitor::type_id::create("dct_monitor", this);
    sequencer = dct_sequencer::type_id::create("dct_sequencer", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

class dct_env extends uvm_env;
  `uvm_component_utils(dct_env)
  dct_agent agent;
  dct_scoreboard scb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = dct_agent::type_id::create("dct_agent", this);
    scb   = dct_scoreboard::type_id::create("dct_scoreboard", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.in_ap.connect(scb.in_export);
    agent.monitor.out_ap.connect(scb.out_export);
  endfunction
endclass

// ============================================================================
// TEST
// ============================================================================
class dct_test extends uvm_test;
  `uvm_component_utils(dct_test)
  dct_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = dct_env::type_id::create("dct_env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // SỬA LẠI: Bỏ chữ "this", sequence không phải là component
    dct_sequence seq = dct_sequence::type_id::create("seq");

    phase.raise_objection(this);
    // SỬA LẠI: Phải gọi start() để nhúng sequence vào sequencer
    seq.start(env.agent.sequencer);
    #5000;  // Đợi RTL xử lý block cuối cùng
    phase.drop_objection(this);
  endtask
endclass

// ============================================================================
// MODULE TOP (NỐI DÂY DUT)
// ============================================================================
module dct_2d_tb;
  logic clk;
  logic rst;

  dct_if vif (
      clk,
      rst
  );

  dct_2d_1channel DUT (
      .clk(clk),
      .rst(rst),
      .enable(vif.enable),
      .data_in(vif.data_in),
      .output_enable(vif.output_enable),

      // GOM RÁC CỦA BẠN ĐÂY!
      .Z11_final(vif.Z11_final),
      .Z12_final(vif.Z12_final),
      .Z13_final(vif.Z13_final),
      .Z14_final(vif.Z14_final),
      .Z15_final(vif.Z15_final),
      .Z16_final(vif.Z16_final),
      .Z17_final(vif.Z17_final),
      .Z18_final(vif.Z18_final),
      .Z21_final(vif.Z21_final),
      .Z22_final(vif.Z22_final),
      .Z23_final(vif.Z23_final),
      .Z24_final(vif.Z24_final),
      .Z25_final(vif.Z25_final),
      .Z26_final(vif.Z26_final),
      .Z27_final(vif.Z27_final),
      .Z28_final(vif.Z28_final),
      .Z31_final(vif.Z31_final),
      .Z32_final(vif.Z32_final),
      .Z33_final(vif.Z33_final),
      .Z34_final(vif.Z34_final),
      .Z35_final(vif.Z35_final),
      .Z36_final(vif.Z36_final),
      .Z37_final(vif.Z37_final),
      .Z38_final(vif.Z38_final),
      .Z41_final(vif.Z41_final),
      .Z42_final(vif.Z42_final),
      .Z43_final(vif.Z43_final),
      .Z44_final(vif.Z44_final),
      .Z45_final(vif.Z45_final),
      .Z46_final(vif.Z46_final),
      .Z47_final(vif.Z47_final),
      .Z48_final(vif.Z48_final),
      .Z51_final(vif.Z51_final),
      .Z52_final(vif.Z52_final),
      .Z53_final(vif.Z53_final),
      .Z54_final(vif.Z54_final),
      .Z55_final(vif.Z55_final),
      .Z56_final(vif.Z56_final),
      .Z57_final(vif.Z57_final),
      .Z58_final(vif.Z58_final),
      .Z61_final(vif.Z61_final),
      .Z62_final(vif.Z62_final),
      .Z63_final(vif.Z63_final),
      .Z64_final(vif.Z64_final),
      .Z65_final(vif.Z65_final),
      .Z66_final(vif.Z66_final),
      .Z67_final(vif.Z67_final),
      .Z68_final(vif.Z68_final),
      .Z71_final(vif.Z71_final),
      .Z72_final(vif.Z72_final),
      .Z73_final(vif.Z73_final),
      .Z74_final(vif.Z74_final),
      .Z75_final(vif.Z75_final),
      .Z76_final(vif.Z76_final),
      .Z77_final(vif.Z77_final),
      .Z78_final(vif.Z78_final),
      .Z81_final(vif.Z81_final),
      .Z82_final(vif.Z82_final),
      .Z83_final(vif.Z83_final),
      .Z84_final(vif.Z84_final),
      .Z85_final(vif.Z85_final),
      .Z86_final(vif.Z86_final),
      .Z87_final(vif.Z87_final),
      .Z88_final(vif.Z88_final)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst = 1;
    #20 rst = 0;
  end

  initial begin
    uvm_config_db#(virtual dct_if)::set(null, "*", "vif", vif);
    run_test("dct_test");
  end
endmodule
