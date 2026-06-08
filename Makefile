# ==============================================================================
# Makefile for JPEG Verilog Encoder
#
# Author: Antigravity
# Date: 2026-06-08
# Description: Automates ModelSim compilation, simulation, and Python script
#              execution for the JPEG Verilog project.
# ==============================================================================

# Tool Variables
VLOG   := vlog
VSIM   := vsim
VLIB   := vlib
VMAP   := vmap
PYTHON := python3

# Directory Paths
RTL_DIR    := rtl
TB_DIR     := tb
WORK_DIR   := work
SCRIPT_DIR := scripts
DATA_DIR   := data

# Source Files
RTL_LIB_SRCS  := $(wildcard $(RTL_DIR)/lib/*.v)
RTL_CORE_SRCS := $(wildcard $(RTL_DIR)/jpeg_core/*.v)
RTL_SRCS      := $(RTL_LIB_SRCS) $(RTL_CORE_SRCS)
TB_SRCS       := $(wildcard $(TB_DIR)/*.v)

# Simulation Parameters (Can override from command line, e.g., make sim TB=color_trans_tb)
TB            ?= jpeg_top_tb

# Default Target
.PHONY: all
all: compile

# Compile Target
.PHONY: compile
compile: $(WORK_DIR)/_info

# Create work library and compile all source files
$(WORK_DIR)/_info: $(RTL_SRCS) $(TB_SRCS)
	@echo "=============================================================="
	@echo " Creating library and compiling Verilog sources..."
	@echo "=============================================================="
	@if [ ! -d $(WORK_DIR) ]; then \
		$(VLIB) $(WORK_DIR); \
	fi
	$(VLOG) -work $(WORK_DIR) $(RTL_SRCS) $(TB_SRCS)

# Run Simulation in Command-Line Mode (CLI)
.PHONY: sim
sim: compile
	@echo "=============================================================="
	@echo " Running simulation: $(TB) (CLI Mode)..."
	@echo "=============================================================="
	$(VSIM) -c -do "run -all; quit" -work $(WORK_DIR) $(TB)

# Run Simulation in GUI Mode
.PHONY: sim_gui
sim_gui: compile
	@echo "=============================================================="
	@echo " Running simulation: $(TB) (GUI Mode)..."
	@echo "=============================================================="
	$(VSIM) -do "run -all" -work $(WORK_DIR) $(TB) &

# Prepare HEX Data from Input BMP Image (Uses sample1.bmp by default)
.PHONY: prepare_hex
prepare_hex:
	@echo "=============================================================="
	@echo " Converting input BMP to HEX block format..."
	@echo "=============================================================="
	@if [ ! -f $(DATA_DIR)/input/sample1.bmp ]; then \
		echo "Error: $(DATA_DIR)/input/sample1.bmp not found!"; \
		exit 1; \
	fi
	@mkdir -p $(DATA_DIR)/hex
	cp $(DATA_DIR)/input/sample1.bmp ./sample1.bmp
	$(PYTHON) $(SCRIPT_DIR)/writergb.py
	mv input_rgb.hex $(DATA_DIR)/hex/input_rgb.hex
	rm -f sample1.bmp
	@echo "HEX input generated at $(DATA_DIR)/hex/input_rgb.hex"

# Convert Simulation Output HEX back to JPEG Image
.PHONY: create_jpeg
create_jpeg:
	@echo "=============================================================="
	@echo " Building output JPEG image from simulated bitstream..."
	@echo "=============================================================="
	@if [ ! -f $(DATA_DIR)/hex/output_bitstream.hex ]; then \
		echo "Error: Simulation output $(DATA_DIR)/hex/output_bitstream.hex not found!"; \
		exit 1; \
	fi
	@mkdir -p $(DATA_DIR)/output
	$(PYTHON) $(SCRIPT_DIR)/create_jpeg.py
	@echo "JPEG output compiled at $(DATA_DIR)/output/sample1.jpg"

# Run Full End-to-End Pipeline
# 1. Convert input BMP to HEX
# 2. Run simulation to produce bitstream HEX
# 3. Convert bitstream HEX to JPEG image
.PHONY: run_pipeline
run_pipeline: prepare_hex sim create_jpeg
	@echo "=============================================================="
	@echo " Pipeline executed successfully!"
	@echo " Input image:  $(DATA_DIR)/input/sample1.bmp"
	@echo " Output image: $(DATA_DIR)/output/sample1.jpg"
	@echo "=============================================================="

# Clean compilation and simulation artifacts
.PHONY: clean
clean:
	@echo "=============================================================="
	@echo " Cleaning build artifacts..."
	@echo "=============================================================="
	rm -rf $(WORK_DIR) transcript vsim.wlf
	rm -f $(DATA_DIR)/hex/output_bitstream.hex
	rm -f $(DATA_DIR)/output/sample1.jpg
