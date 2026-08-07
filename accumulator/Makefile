MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT_DIR := $(abspath $(MAKEFILE_DIR))
RTL_DIR := $(PROJECT_DIR)/rtl
TB_DIR := $(PROJECT_DIR)/tb
BUILD_DIR := $(PROJECT_DIR)/build
TB_TOP ?= accumulator_tb
TB_SRC := $(TB_DIR)/$(TB_TOP).sv

ifeq ($(TB_TOP),accumulator_tb)
RTL_SRC := $(RTL_DIR)/accumulator.svh
else ifeq ($(TB_TOP),accumulator_signed_tb)
RTL_SRC := $(RTL_DIR)/accumulator_signed.svh
else ifeq ($(TB_TOP),accumulator_parametric_tb)
RTL_SRC := $(RTL_DIR)/accumulator_parametric.svh
else
$(error Unsupported TB_TOP=$(TB_TOP); use accumulator_tb or accumulator_signed_tb or accumulator_parametric_tb)
endif

VVP_FILE := $(BUILD_DIR)/$(TB_TOP).vvp
VCD_FILE := $(BUILD_DIR)/$(TB_TOP).vcd
ACCUMULATOR_VCD := $(BUILD_DIR)/accumulator_tb.vcd
SIGNED_VCD := $(BUILD_DIR)/accumulator_signed_tb.vcd
PARAMETRIC_VCD := $(BUILD_DIR)/accumulator_parametric_tb.vcd
IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave

.PHONY: all build run wave clean help signed signed-build parametric parametric-build

all: clean run

build: $(VVP_FILE)

$(BUILD_DIR):
	mkdir -p $@

$(VVP_FILE): $(RTL_SRC) $(TB_SRC) | $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $@ $(TB_SRC) $(RTL_SRC)

run: $(VVP_FILE)
	$(VVP) $(VVP_FILE)

wave:
	@if [ -f $(ACCUMULATOR_VCD) ]; then \
		echo "Opening waveform viewer for $(ACCUMULATOR_VCD)"; \
		if command -v $(GTKWAVE) >/dev/null 2>&1; then \
			$(GTKWAVE) $(ACCUMULATOR_VCD) & \
		else \
			echo "GTKWave not found. Install it with: sudo apt install gtkwave"; \
		fi \
	else \
		echo "Waveform file $(ACCUMULATOR_VCD) not found. Run make build or make run first."; \
	fi

signed:
	$(MAKE) TB_TOP=accumulator_signed_tb run

signed-build:
	$(MAKE) TB_TOP=accumulator_signed_tb build

signed-wave:
	@if [ -f $(SIGNED_VCD) ]; then \
		echo "Opening waveform viewer for $(SIGNED_VCD)"; \
		if command -v $(GTKWAVE) >/dev/null 2>&1; then \
			$(GTKWAVE) $(SIGNED_VCD) & \
		else \
			echo "GTKWave not found. Install it with: sudo apt install gtkwave"; \
		fi \
	else \
		echo "Waveform file $(SIGNED_VCD) not found. Run make signed-build or make signed first."; \
	fi

parametric:
	$(MAKE) TB_TOP=accumulator_parametric_tb run

parametric-build:
	$(MAKE) TB_TOP=accumulator_parametric_tb build

parametric-wave:
	@if [ -f $(PARAMETRIC_VCD) ]; then \
		echo "Opening waveform viewer for $(PARAMETRIC_VCD)"; \
		if command -v $(GTKWAVE) >/dev/null 2>&1; then \
			$(GTKWAVE) $(PARAMETRIC_VCD) & \
		else \
			echo "GTKWave not found. Install it with: sudo apt install gtkwave"; \
		fi \
	else \
		echo "Waveform file $(PARAMETRIC_VCD) not found. Run make parametric-build or make parametric first."; \
	fi

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "Available targets:"
	@echo "  make build           - compile the testbench for TB_TOP (default accumulator_tb)"
	@echo "  make run             - compile and run the simulation for TB_TOP"
	@echo "  make signed          - compile and run accumulator_signed_tb"
	@echo "  make signed-build    - compile accumulator_signed_tb only"
	@echo "  make parametric      - compile and run accumulator_parametric_tb"
	@echo "  make parametric-build - compile accumulator_parametric_tb only"
	@echo "  make wave            - open the waveform viewer (requires GTKWave)"
	@echo "  make clean           - remove generated files"
	@echo "  make help            - show this help"
	@echo "Variables: TB_TOP=accumulator_tb or accumulator_signed_tb"
