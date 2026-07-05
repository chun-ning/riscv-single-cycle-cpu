# Directories
RTL_DIR = rtl
TB_DIR = tb
BUILD_DIR = build
WAVE_DIR = waves

# Verilog compiler and simulator
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

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

# Run all tests
test_all: tb_alu tb_regfile tb_imm_gen tb_control

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

# Clean generated files
clean:
	rm -rf $(BUILD_DIR)
	rm -f $(WAVE_DIR)/*.vcd