# Directories
RTL_DIR = rtl
TB_DIR = tb
BUILD_DIR = build
WAVE_DIR = waves

# Verilog compiler and simulator
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Assembly to hex flow
RISCV_PREFIX = riscv64-unknown-elf
AS      = $(RISCV_PREFIX)-as
LD      = $(RISCV_PREFIX)-ld
OBJCOPY = $(RISCV_PREFIX)-objcopy
OBJDUMP = $(RISCV_PREFIX)-objdump
PYTHON  = python3

# Run unit testbench
tb_alu:
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	$(IVERILOG) -o $(BUILD_DIR)/tb_alu $(TB_DIR)/tb_alu.v $(RTL_DIR)/alu.v
	$(VVP) $(BUILD_DIR)/tb_alu

tb_regfile:
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	$(IVERILOG) -o $(BUILD_DIR)/tb_regfile $(TB_DIR)/tb_regfile.v $(RTL_DIR)/regfile.v
	$(VVP) $(BUILD_DIR)/tb_regfile

tb_imm_gen:
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	$(IVERILOG) -o $(BUILD_DIR)/tb_imm_gen $(TB_DIR)/tb_imm_gen.v $(RTL_DIR)/imm_gen.v
	$(VVP) $(BUILD_DIR)/tb_imm_gen

tb_control:
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	$(IVERILOG) -o $(BUILD_DIR)/tb_control $(TB_DIR)/tb_control.v $(RTL_DIR)/control.v
	$(VVP) $(BUILD_DIR)/tb_control

tb_pc:
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	$(IVERILOG) -o $(BUILD_DIR)/tb_pc $(TB_DIR)/tb_pc.v $(RTL_DIR)/pc.v
	$(VVP) $(BUILD_DIR)/tb_pc

tb_data_mem:
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	$(IVERILOG) -o $(BUILD_DIR)/tb_data_mem $(TB_DIR)/tb_data_mem.v $(RTL_DIR)/data_mem.v
	$(VVP) $(BUILD_DIR)/tb_data_mem

tb_instr_mem:
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	$(IVERILOG) -o $(BUILD_DIR)/tb_instr_mem $(TB_DIR)/tb_instr_mem.v $(RTL_DIR)/instr_mem.v
	$(VVP) $(BUILD_DIR)/tb_instr_mem

# CPU
PROGRAM = cpu_test

program:
	mkdir -p build tb/programs
	$(AS) -march=rv32i -mabi=ilp32 -o build/$(PROGRAM).o asm/$(PROGRAM).s
	$(LD) -m elf32lriscv -Ttext=0x0 -o build/$(PROGRAM).elf build/$(PROGRAM).o
	$(OBJCOPY) -O binary build/$(PROGRAM).elf build/$(PROGRAM).bin
	$(PYTHON) tools/bin_to_hex.py build/$(PROGRAM).bin tb/programs/$(PROGRAM).hex

# $(OBJDUMP) -d build/$(PROGRAM).elf

tb_cpu:
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	$(IVERILOG) -o $(BUILD_DIR)/tb_cpu $(TB_DIR)/tb_cpu.v $(RTL_DIR)/*.v
	$(VVP) $(BUILD_DIR)/tb_cpu

# SystemVerilog CPU testbench + coverage monitoring
tb_cpu_sys:
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	$(IVERILOG) -g2012 -s tb_cpu_sys -o $(BUILD_DIR)/tb_cpu_sys $(TB_DIR)/cpu_coverage.sv $(TB_DIR)/tb_cpu_sys.sv $(RTL_DIR)/*.v
	$(VVP) $(BUILD_DIR)/tb_cpu_sys

# Run all tests
test_all: tb_alu tb_regfile tb_imm_gen tb_control

# Test CPU from assembly
test_full: program tb_cpu

# Open waveforms
wave_alu:
	$(GTKWAVE) $(WAVE_DIR)/alu.vcd

wave_regfile:
	$(GTKWAVE) $(WAVE_DIR)/regfile.vcd

wave_imm_gen:
	$(GTKWAVE) $(WAVE_DIR)/imm_gen.vcd

wave_control:
	$(GTKWAVE) $(WAVE_DIR)/control.vcd

wave_pc:
	$(GTKWAVE) $(WAVE_DIR)/pc.vcd

wave_data_mem:
	$(GTKWAVE) $(WAVE_DIR)/data_mem.vcd

wave_instr_mem:
	$(GTKWAVE) $(WAVE_DIR)/instr_mem.vcd

wave_cpu:
	$(GTKWAVE) $(WAVE_DIR)/cpu.vcd

wave_cpu_sys:
	$(GTKWAVE) $(WAVE_DIR)/cpu_sys.vcd

# Clean generated files
clean:
	rm -rf $(BUILD_DIR)
	rm -f $(WAVE_DIR)/*.vcd

# Yosys Scripts
synth_cpu:
	mkdir -p build
	yosys -s scripts/synth_cpu.ys
