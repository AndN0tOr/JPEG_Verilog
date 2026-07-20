color_trans_compile:
	vlog ../rtl/jpeg_core/color_trans.v
	vlog ../work color_trans_tb.sv
color_trans_sim:
	vsim -c -do "run -all; quit" color_trans_tb

color_trans_tb: color_trans_compile color_trans_sim

dct_2d_lint:
	verible-verilog-lint dct_2d_tb.sv
dct_2d_compile:
	vlog ../rtl/jpeg_core/dct_2d_1channel.v
	vlog ../rtl/jpeg_core/compute_1d_dct.v
	vlog dct_2d_tb.sv
dct_2d_sim:
	vsim -c -do "run -all; quit" dct_2d_tb
dct_2d_tb: dct_2d_compile dct_2d_sim

vmap:
	vmap -work ../work
.PHONY: clean
clean:
	rm -r work
	rm transcript