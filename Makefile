ctop_v:
	vlog rtl/jpeg_top.v
ctop_tb:
	vlog tb/jpeg_top_tb.v
ctop: 
	top_v top_tb_v
all: 
	vlog rtl/*.v
top_tb:
	vsim -c -do "run -all; quit" jpeg_top_tb
wrap:
	python3 scripts/create_jpeg.py
# ~/intelFPGA/18.1/modelsim_ase/bin