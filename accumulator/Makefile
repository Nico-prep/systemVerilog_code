MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT_DIR := $(abspath $(MAKEFILE_DIR))
RTL_DIR := $(PROJECT_DIR)/rtl
TB_DIR := $(PROJECT_DIR)/tb
BUILD_DIR := $(PROJECT_DIR)/build
TB_TOP ?= accumulator_tb
TB_SRC := $(TB_DIR)/$(TB_TOP).sv
RTL_SRC := $(RTL_DIR)/accumulator.svh
VVP_FILE := $(BUILD_DIR)/$(TB_TOP).vvp
VCD_FILE := $(BUILD_DIR)/$(TB_TOP).vcd
IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave

.PHONY: all build run wave clean help

all: clean run

build: $(VVP_FILE)

$(BUILD_DIR):
	mkdir -p $@

$(VVP_FILE): $(RTL_SRC) $(TB_SRC) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $@ $(TB_SRC) $(RTL_SRC)

run: $(VVP_FILE)
	$(VVP) $(VVP_FILE)

wave: $(VVP_FILE)
	@echo "Opening waveform viewer for $(VCD_FILE)"
	@if command -v $(GTKWAVE) >/dev/null 2>&1; then \
		$(GTKWAVE) $(VCD_FILE) & \
	else \
		echo "GTKWave not found. Install it with: sudo apt install gtkwave"; \
	fi

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "Available targets:"
	@echo "  make build   - compile the testbench"
	@echo "  make run     - compile and run the simulation"
	@echo "  make wave    - open the waveform viewer (requires GTKWave)"
	@echo "  make clean   - remove generated files"
	@echo "  make help    - show this help"
