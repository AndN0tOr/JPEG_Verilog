`timescale 1ps / 1ps

// ============================================================================
// 1. IMPORT THƯ VIỆN UVM (Bắt buộc phải nằm ở trên cùng)
// ============================================================================
import uvm_pkg::*;
`include "uvm_macros.svh"

// ============================================================================
// 2. INTERFACE
// ============================================================================
interface color_trans_if (
    input logic clk,
    input logic rst
);
  logic        enable;
  logic [23:0] data_in;
  logic        out_enable;
  logic [23:0] data_out;
endinterface

// ============================================================================
// 3. SEQUENCE ITEM (Gói dữ liệu)
// ============================================================================
class color_item extends uvm_sequence_item;
  rand bit [23:0] rgb_in;
  bit      [23:0] ycbcr_out;

  `uvm_object_utils_begin(color_item)
    `uvm_field_int(rgb_in, UVM_ALL_ON)
    `uvm_field_int(ycbcr_out, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "color_item");
    super.new(name);
  endfunction
endclass

// ============================================================================
// 4. SEQUENCE (Kịch bản tạo dữ liệu)
// ============================================================================
class color_sequence extends uvm_sequence #(color_item);
  `uvm_object_utils(color_sequence)

  function new(string name = "color_sequence");
    super.new(name);
  endfunction

  virtual task body();
    repeat (1000) begin
      req = color_item::type_id::create("req");
      start_item(req);

      // Bypass lỗi svverification license bằng cách tự gán giá trị random
      req.rgb_in = $urandom();

      finish_item(req);
    end
  endtask
endclass

// ============================================================================
// 5. DRIVER (Lái tín hiệu vào RTL)
// ============================================================================
class color_driver extends uvm_driver #(color_item);
  `uvm_component_utils(color_driver)
  virtual color_trans_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual color_trans_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {"Giao diện ảo chưa được set cho: ", get_full_name(), ".vif"})
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.enable  <= 0;
    vif.data_in <= 0;
    wait (!vif.rst);

    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      vif.enable  <= 1'b1;
      vif.data_in <= req.rgb_in;
      seq_item_port.item_done();

      // Chèn 1 xung clk nghỉ để giả lập data không liên tục (tùy chọn)
      // @(posedge vif.clk); vif.enable <= 1'b0; 
    end
  endtask
endclass

// ============================================================================
// 6. MONITOR (Thu thập dữ liệu In/Out)
// ============================================================================
class color_monitor extends uvm_monitor;
  `uvm_component_utils(color_monitor)
  virtual color_trans_if vif;

  uvm_analysis_port #(color_item) in_ap;
  uvm_analysis_port #(color_item) out_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    in_ap  = new("in_ap", this);
    out_ap = new("out_ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual color_trans_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {"Giao diện ảo chưa được set cho: ", get_full_name(), ".vif"})
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      // Bắt Input
      forever begin
        @(posedge vif.clk);
        if (vif.enable && !vif.rst) begin
          color_item item_in = color_item::type_id::create("item_in");
          item_in.rgb_in = vif.data_in;
          in_ap.write(item_in);
        end
      end

      // Bắt Output
      forever begin
        @(posedge vif.clk);
        if (vif.out_enable && !vif.rst) begin
          color_item item_out = color_item::type_id::create("item_out");
          item_out.ycbcr_out = vif.data_out;
          out_ap.write(item_out);
        end
      end
    join
  endtask
endclass

// ============================================================================
// 7. SCOREBOARD (Mô hình chuẩn & Kiểm tra lỗi)
// ============================================================================
`uvm_analysis_imp_decl(_in)
`uvm_analysis_imp_decl(_out)

class color_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(color_scoreboard)

  uvm_analysis_imp_in #(color_item, color_scoreboard) in_export;
  uvm_analysis_imp_out #(color_item, color_scoreboard) out_export;

  color_item in_queue[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    in_export  = new("in_export", this);
    out_export = new("out_export", this);
  endfunction

  virtual function void write_in(color_item item);
    in_queue.push_back(item);
  endfunction

  virtual function void write_out(color_item act_item);
    color_item exp_item;
    bit [7:0] r, g, b;
    bit [15:0] y_tmp, cb_tmp, cr_tmp;
    bit [7:0] exp_y, exp_cb, exp_cr;

    if (in_queue.size() == 0) begin
      `uvm_error("SCB", "Nhận Output nhưng Queue Input trống!")
      return;
    end

    exp_item = in_queue.pop_front();

    r = exp_item.rgb_in[23:16];
    g = exp_item.rgb_in[15:8];
    b = exp_item.rgb_in[7:0];

    // Công thức RTL
    y_tmp = (77 * r) + (150 * g) + (29 * b);
    cb_tmp = 32768 - (43 * r) - (84 * g) + (128 * b);
    cr_tmp = 32768 + (128 * r) - (107 * g) - (21 * b);

    // Logic làm tròn
    exp_y = (y_tmp[7] && y_tmp[15:8] != 8'd255) ? y_tmp[15:8] + 1'b1 : y_tmp[15:8];
    exp_cb = (cb_tmp[7] && cb_tmp[15:8] != 8'd255) ? cb_tmp[15:8] + 1'b1 : cb_tmp[15:8];
    exp_cr = (cr_tmp[7] && cr_tmp[15:8] != 8'd255) ? cr_tmp[15:8] + 1'b1 : cr_tmp[15:8];

    if ({exp_y, exp_cb, exp_cr} !== act_item.ycbcr_out) begin
      `uvm_error("SCB_FAIL", $sformatf("SAI SỐ! RGB: %06h | EXP: %02h_%02h_%02h | ACT: %06h",
                                       exp_item.rgb_in, exp_y, exp_cb, exp_cr, act_item.ycbcr_out))
    end else begin
      `uvm_info("SCB_PASS", $sformatf(
                "KHỚP! RGB: %06h -> YCbCr: %06h", exp_item.rgb_in, act_item.ycbcr_out), UVM_HIGH)
    end
  endfunction
endclass

// ============================================================================
// 8. CÁC KHỐI GOM (Agent, Env, Test)
// ============================================================================
typedef uvm_sequencer#(color_item) color_sequencer;

class color_agent extends uvm_agent;
  `uvm_component_utils(color_agent)
  color_driver    driver;
  color_monitor   monitor;
  color_sequencer sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver    = color_driver::type_id::create("driver", this);
    monitor   = color_monitor::type_id::create("monitor", this);
    sequencer = color_sequencer::type_id::create("sequencer", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

class color_env extends uvm_env;
  `uvm_component_utils(color_env)
  color_agent      agent;
  color_scoreboard scb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = color_agent::type_id::create("agent", this);
    scb   = color_scoreboard::type_id::create("scb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.in_ap.connect(scb.in_export);
    agent.monitor.out_ap.connect(scb.out_export);
  endfunction
endclass

class color_test extends uvm_test;
  `uvm_component_utils(color_test)
  color_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = color_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    color_sequence seq = color_sequence::type_id::create("seq");

    phase.raise_objection(this);
    seq.start(env.agent.sequencer);
    #100;  // Bù trễ pipeline 3 xung nhịp để đợi output cuối cùng
    phase.drop_objection(this);
  endtask
endclass

// ============================================================================
// 9. MODULE TOP
// ============================================================================
module color_trans_tb;
  logic clk;
  logic rst;

  // 9.1 Khởi tạo Interface
  color_trans_if vif (
      clk,
      rst
  );

  // 9.2 Kết nối RTL (DUT)
  color_trans DUT (
      .clk(vif.clk),
      .rst(vif.rst),
      .enable(vif.enable),
      .data_in(vif.data_in),
      .out_enable(vif.out_enable),
      .data_out(vif.data_out)
  );

  // 9.3 Khởi tạo Clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 9.4 Reset và Chạy UVM
  initial begin
    rst = 1;
    #20 rst = 0;
  end

  // 9.5 Cấu hình và Chạy UVM (BẮT BUỘC chạy ở Time 0)
  initial begin
    // Đẩy interface vào database để Driver/Monitor lấy ra dùng
    uvm_config_db#(virtual color_trans_if)::set(null, "*", "vif", vif);

    // Gọi UVM Test ngay lập tức ở thời điểm 0
    run_test("color_test");
  end
endmodule
