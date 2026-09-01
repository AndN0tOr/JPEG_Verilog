color_trans_compile:
	vlog ../rtl/jpeg_core/color_trans.sv
	vlog ../rtl_tb/color_trans_tb.sv
color_trans_sim:
	vsim -c -do "run -all; quit" color_trans_tb

color_trans_tb: color_trans_compile color_trans_sim

dct_1d_compile:
	vlog ../rtl/jpeg_core/dct_1d.sv
	vlog ../rtl_tb/dct_1d_tb.sv
dct_1d_sim:
	vsim -c -do "run -all; quit" dct_1d_tb

dct_1d_tb: dct_1d_compile dct_1d_sim

dct_2d_compile:
	vlog ../rtl/jpeg_core/dct_2d_1channel.v
	vlog ../rtl/jpeg_core/compute_1d_dct.v
	vlog ../rtl_tb/dct_2d_tb.sv
dct_2d_sim:
	vsim -c -do "run -all; quit" dct_2d_tb
dct_2d_tb: dct_2d_compile dct_2d_sim

chroma_quant_compile:
	vlog ../rtl/jpeg_core/chroma_quantizer.v
	vlog chroma_quant_tb.sv
chroma_quant_sim:
	vsim -c -do "run -all; quit" chroma_quant_tb
chroma_quant_tb: chroma_quant_compile chroma_quant_sim

luma_quant_compile:
	vlog ../rtl/jpeg_core/luma_quantizer.v
	vlog luma_quant_tb.sv
luma_quant_sim:
	vsim -c -do "run -all; quit" luma_quantizer_tb
vmap:
	vmap -work ../work
.PHONY: clean
clean:
	rm -r work
	rm transcript