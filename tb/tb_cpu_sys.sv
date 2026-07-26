`timescale 1ns/1ps
`default_nettype none

module tb_cpu_sys;
    localparam time CLK_PERIOD = 10ns;
    localparam time TIMEOUT = 1500ns;

    logic clk;
    logic reset;

    logic [31:0] debug_pc;
    logic [31:0] debug_instr;
    logic [31:0] debug_alu_result;
    logic [31:0] debug_writeback_data;
    logic [4:0]  debug_writeback_rd;
    logic        debug_reg_write;
    logic        debug_mem_write;

    int unsigned checks;
    int unsigned errors;

    localparam logic [6:0] OPCODE_LUI    = 7'b0110111;
    localparam logic [6:0] OPCODE_OP     = 7'b0110011;
    localparam logic [6:0] OPCODE_OP_IMM = 7'b0010011;
    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JAL    = 7'b1101111;
    localparam logic [6:0] OPCODE_JALR   = 7'b1100111;

    logic        sampled_reset;
    logic        jalr_pending;
    logic [31:0] expected_jalr_pc;

    cpu dut (
        .clk (clk),
        .reset (reset),
        .debug_pc (debug_pc),
        .debug_instr (debug_instr),
        .debug_alu_result (debug_alu_result),
        .debug_writeback_data (debug_writeback_data),
        .debug_writeback_rd (debug_writeback_rd),
        .debug_reg_write (debug_reg_write),
        .debug_mem_write (debug_mem_write)
    );

    // Clock init: period = 10ns
    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Stop a hung test instead of allowing the simulator to run forever.
    // Max possible number of instructions executed ～80 (80*10ns = 800ns) --> TIMEOUT set to 1500ns
    initial begin : timeout
        #(TIMEOUT);
        $fatal(1, "TIMEOUT: CPU testbench exceeded %0t", TIMEOUT);
    end

    task automatic run_cycles(input int unsigned count);
        repeat (count) @(posedge clk);
        #1ns; // Ensure non-blocking assignments are settled
    endtask

    task automatic check(
        input string test_name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        checks++;
        if (actual !== expected) begin
            errors++;
            $error("FAIL: %s expected=%08h actual=%08h",
                   test_name, expected, actual);
        end else begin
            $display("PASS: %s actual=%08h", test_name, actual);
        end
    endtask

    task automatic start_test(input int unsigned number, input string name);
        $display("\nTEST %0d: %s", number, name);
    endtask

    task automatic assertion_failed(input string message);
        errors++;
        $error("%s(%0d): ASSERTION FAILED: %s at time %0t",
               `__FILE__, `__LINE__, message, $time);
    endtask

    // Check if instruction is supported
    function automatic logic is_supported_instruction(input logic [31:0] instruction);
        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;
        begin
            opcode = instruction[6:0];
            funct3 = instruction[14:12];
            funct7 = instruction[31:25];

            case (opcode)
                OPCODE_OP: begin
                    case ({funct7, funct3})
                        {7'b0000000, 3'b000}, // add
                        {7'b0100000, 3'b000}, // sub
                        {7'b0000000, 3'b001}, // sll
                        {7'b0000000, 3'b010}, // slt
                        {7'b0000000, 3'b011}, // sltu
                        {7'b0000000, 3'b100}, // xor
                        {7'b0000000, 3'b101}, // srl
                        {7'b0100000, 3'b101}, // sra
                        {7'b0000000, 3'b110}, // or
                        {7'b0000000, 3'b111}: // and
                            is_supported_instruction = 1'b1;
                        default:
                            is_supported_instruction = 1'b0;
                    endcase
                end

                OPCODE_OP_IMM: begin
                    case (funct3)
                        3'b000, // addi
                        3'b010, // slti
                        3'b011, // sltiu
                        3'b100, // xori
                        3'b110, // ori
                        3'b111: // andi
                            is_supported_instruction = 1'b1;
                        3'b001: // slli
                            is_supported_instruction = (funct7 == 7'b0000000);
                        3'b101: // srli/srai
                            is_supported_instruction =
                                (funct7 == 7'b0000000) ||
                                (funct7 == 7'b0100000);
                        default:
                            is_supported_instruction = 1'b0;
                    endcase
                end

                OPCODE_LOAD:
                    is_supported_instruction = (funct3 == 3'b010); // lw
                OPCODE_STORE:
                    is_supported_instruction = (funct3 == 3'b010); // sw
                OPCODE_BRANCH:
                    is_supported_instruction =
                        (funct3 == 3'b000) || // beq
                        (funct3 == 3'b001) || // bne
                        (funct3 == 3'b100) || // blt
                        (funct3 == 3'b101) || // bge
                        (funct3 == 3'b110) || // bltu
                        (funct3 == 3'b111);   // bgeu
                OPCODE_LUI,
                OPCODE_JAL:
                    is_supported_instruction = 1'b1;
                OPCODE_JALR:
                    is_supported_instruction = (funct3 == 3'b000);
                default:
                    is_supported_instruction = 1'b0;
            endcase
        end
    endfunction

    // Expected behavrior for reg_write in control module
    function automatic logic instruction_writes_rd(input logic [31:0] instruction);
        logic [6:0] opcode;
        begin
            opcode = instruction[6:0];
            instruction_writes_rd =
                is_supported_instruction(instruction) &&
                ((opcode == OPCODE_OP)     ||
                 (opcode == OPCODE_OP_IMM) ||
                 (opcode == OPCODE_LOAD)   ||
                 (opcode == OPCODE_LUI)    ||
                 (opcode == OPCODE_JAL)    ||
                 (opcode == OPCODE_JALR));
        end
    endfunction

    // CPU uses synchronous reset: records reset value at posedge (later checked at negedge to ensure CPU has seen the reset)
    initial sampled_reset = 1'b0;
    always @(posedge clk)
        sampled_reset <= reset;

    // Initilize JALR tracking variables
    initial begin
        jalr_pending    = 1'b0;
        expected_jalr_pc = 32'd0;
    end

    always @(negedge clk) begin : architectural_invariants
        // x0 is hardwired to zero
        assert (dut.rf.regs[0] === 32'd0)
        else assertion_failed(
            $sformatf("x0 is not zero: x0=%08h", dut.rf.regs[0])
        );

        // Check result of a JALR captured on the previous negedge
        if (jalr_pending) begin
            assert (debug_pc[0] === 1'b0)
            else assertion_failed(
                $sformatf("JALR next PC bit 0 was not cleared: PC=%08h",
                          debug_pc)
            );

            assert (debug_pc === expected_jalr_pc)
            else assertion_failed(
                $sformatf("JALR next PC=%08h expected=%08h",
                          debug_pc, expected_jalr_pc)
            );
        end

        // Reset sampled by the CPU at the prev posedge must clear the PC
        if (sampled_reset) begin
            assert (debug_pc === 32'd0)
            else assertion_failed(
                $sformatf("reset did not clear PC: PC=%08h", debug_pc)
            );
        end

        if (!reset) begin
            // Check word aligned
            assert (debug_pc[1:0] === 2'b00)
            else assertion_failed(
                $sformatf("PC is not word-aligned: PC=%08h", debug_pc)
            );

            // Invalid/unsupported instructions
            if (!is_supported_instruction(debug_instr)) begin
                assert (!debug_reg_write && !debug_mem_write)
                else assertion_failed(
                    $sformatf(
                        "invalid instruction %08h asserted reg_write=%0b mem_write=%0b",
                        debug_instr, debug_reg_write, debug_mem_write
                    )
                );
            end

            // A memory write is legal only for the supported SW encoding
            if (debug_mem_write) begin
                assert ((debug_instr[6:0] == OPCODE_STORE) &&
                        (debug_instr[14:12] == 3'b010))
                else assertion_failed(
                    $sformatf("memory write caused by non-SW instruction %08h",
                              debug_instr)
                );
            end

            // Check decoder reg_write
            assert (debug_reg_write === instruction_writes_rd(debug_instr))
            else assertion_failed(
                $sformatf(
                    "reg_write=%0b does not match instruction %08h",
                    debug_reg_write, debug_instr
                )
            );

            // JAL and JALR must select PC+4 as their link value
            if ((debug_instr[6:0] == OPCODE_JAL) ||
                (debug_instr[6:0] == OPCODE_JALR)) begin
                assert (debug_writeback_data === (debug_pc + 32'd4))
                else assertion_failed(
                    $sformatf(
                        "jump link=%08h expected PC+4=%08h",
                        debug_writeback_data, debug_pc + 32'd4
                    )
                );
            end
        end

        // Setting up expected JALR target PC
        jalr_pending = !reset &&
                       (debug_instr[6:0] == OPCODE_JALR) &&
                       (debug_instr[14:12] == 3'b000);
        if (jalr_pending)
            expected_jalr_pc = (dut.rv1 + dut.imm) & 32'hffff_fffe;
    end

    initial begin : test_sequence
        checks = 0;
        errors = 0;
        reset  = 1'b1;

        $dumpfile("waves/cpu_sys.vcd");
        $dumpvars(0, tb_cpu_sys);
        $display("Starting SystemVerilog CPU testbench...");

        // Reset before starting (reset 1 -> 0)
        @(posedge clk);
        #1ns;
        reset = 1'b0;

        start_test(1, "instructions 1-4: ADDI, ADD, SW");
        run_cycles(4);
        check("x1",     dut.rf.regs[1], 32'd6);
        check("x2",     dut.rf.regs[2], 32'd4);
        check("x3",     dut.rf.regs[3], 32'd10);
        check("mem[0]", dut.dmem.mem[0], 32'd10);

        start_test(2, "instructions 5-8: ADDI, LW, SUB, SW");
        run_cycles(4);
        check("x1",     dut.rf.regs[1], 32'd3);
        check("x2",     dut.rf.regs[2], 32'd10);
        check("x3",     dut.rf.regs[3], 32'd7);
        check("mem[1]", dut.dmem.mem[1], 32'd7);

        start_test(3, "instructions 9-16: logical operations and stores");
        run_cycles(8);
        check("x4",     dut.rf.regs[4], 32'd15);
        check("x5",     dut.rf.regs[5], 32'd10);
        check("x6",     dut.rf.regs[6], 32'd10);
        check("x7",     dut.rf.regs[7], 32'd15);
        check("x8",     dut.rf.regs[8], 32'd5);
        check("mem[2]", dut.dmem.mem[2], 32'd10);
        check("mem[3]", dut.dmem.mem[3], 32'd15);
        check("mem[4]", dut.dmem.mem[4], 32'd5);

        start_test(4, "instructions 17-24: shifts and comparisons");
        run_cycles(8);
        check("x9",       dut.rf.regs[9],  32'd1);
        check("x10",      dut.rf.regs[10], 32'd3);
        check("x11 sll",  dut.rf.regs[11], 32'd8);
        check("x12 slli", dut.rf.regs[12], 32'd16);
        check("x13 slt",  dut.rf.regs[13], 32'd1);
        check("x14 sltu", dut.rf.regs[14], 32'd1);
        check("x15 slti", dut.rf.regs[15], 32'd1);
        check("x16 sltiu",dut.rf.regs[16], 32'd1);

        start_test(5, "instructions 25-30: logical and arithmetic right shifts");
        run_cycles(6);
        check("x17",      dut.rf.regs[17], 32'hffff_fff0);
        check("x18",      dut.rf.regs[18], 32'd2);
        check("x19 srl",  dut.rf.regs[19], 32'h3fff_fffc);
        check("x20 sra",  dut.rf.regs[20], 32'hffff_fffc);
        check("x21 srli", dut.rf.regs[21], 32'h1fff_fffe);
        check("x22 srai", dut.rf.regs[22], 32'hffff_fffe);

        start_test(6, "instructions 31-34: immediate logical operations");
        run_cycles(4);
        check("x23",      dut.rf.regs[23], 32'd15);
        check("x24 xori", dut.rf.regs[24], 32'd5);
        check("x25 ori",  dut.rf.regs[25], 32'd63);
        check("x26 andi", dut.rf.regs[26], 32'd15);

        start_test(7, "instructions 35-38: BEQ taken and not taken");
        run_cycles(2);
        check("x23 beq taken", dut.rf.regs[23], 32'd15);
        run_cycles(1);
        check("x23 beq not taken", dut.rf.regs[23], 32'd1);

        start_test(8, "instructions 39-42: BNE taken and not taken");
        run_cycles(2);
        check("x27 bne taken", dut.rf.regs[27], 32'd0);
        run_cycles(1);
        check("x27 bne not taken", dut.rf.regs[27], 32'd1);

        start_test(9, "instructions 43-46: BLT and BLTU");
        run_cycles(2);
        check("x28 blt taken", dut.rf.regs[28], 32'd0);
        run_cycles(1);
        check("x28 bltu not taken", dut.rf.regs[28], 32'd1);

        start_test(10, "instructions 47-51: BGE and BGEU");
        run_cycles(2);
        check("x29 bge/bgeu taken", dut.rf.regs[29], 32'd0);
        run_cycles(1);
        check("x29 bge/bgeu target", dut.rf.regs[29], 32'd10);

        start_test(11, "instruction 52: LUI");
        run_cycles(1);
        check("x30 lui", dut.rf.regs[30], 32'h1234_5000);

        start_test(12, "instructions 53-55: JAL");
        run_cycles(1);
        check("x31 jal link", dut.rf.regs[31], 32'h0000_00d4);
        check("x30 jal skip", dut.rf.regs[30], 32'h1234_5000);
        run_cycles(1);
        check("x5 jal target", dut.rf.regs[5], 32'd12);

        start_test(13, "instructions 56-59: JALR");
        run_cycles(1);
        check("x6 jalr base", dut.rf.regs[6], 32'd232);
        run_cycles(1);
        check("x7 jalr link", dut.rf.regs[7], 32'h0000_00e4);
        check("x5 jalr skip", dut.rf.regs[5], 32'd12);
        run_cycles(1);
        check("x5 jalr target", dut.rf.regs[5], 32'd13);

        start_test(14, "instructions 60-74: signed edges and backward control flow");
        run_cycles(4);
        check("x9 signed edge",  dut.rf.regs[9],  32'hffff_ffff);
        check("x10 signed edge", dut.rf.regs[10], 32'd1);
        check("x11 slt edge",    dut.rf.regs[11], 32'd1);
        check("x12 sltu edge",   dut.rf.regs[12], 32'd0);
        run_cycles(5);
        check("x13 negative branch", dut.rf.regs[13], 32'd1);
        run_cycles(4);
        check("x14 negative jal link",   dut.rf.regs[14], 32'h0000_0118);
        check("x15 negative jal target", dut.rf.regs[15], 32'd14);
        run_cycles(3);
        check("x16 jalr nonzero base",   dut.rf.regs[16], 32'd288);
        check("x17 jalr nonzero link",   dut.rf.regs[17], 32'h0000_0120);
        check("x18 jalr nonzero target", dut.rf.regs[18], 32'd14);

        start_test(15, "instructions 75-76: x0 write protection");
        run_cycles(2);
        check("x0 cannot overwrite", dut.rf.regs[0], 32'd0);
        check("x19 after x0 test", dut.rf.regs[19], 32'd15);

        start_test(16, "reset during execution");
        reset = 1'b1;
        run_cycles(1);
        check("pc reset middle",     debug_pc,          32'd0);
        check("x19 reset middle",    dut.rf.regs[19],   32'd0);
        check("x30 reset middle",    dut.rf.regs[30],   32'd0);
        check("mem[4] reset middle", dut.dmem.mem[4],   32'd0);

        start_test(17, "invalid instruction has no architectural side effect");
        dut.imem.mem[0] = 32'hffff_ffff;
        dut.imem.mem[1] = 32'h0110_0a13; // addi x20, x0, 17
        reset = 1'b0;
        run_cycles(1);
        check("x20 invalid skip", dut.rf.regs[20], 32'd0);
        check("pc after invalid", debug_pc, 32'd4);
        run_cycles(1);
        check("x20 after invalid", dut.rf.regs[20], 32'd17);

        $display("\nPADDING CHECK: NOP padding is harmless");
        dut.imem.mem[2] = 32'h0000_0013;
        dut.imem.mem[3] = 32'h0000_0013;
        dut.imem.mem[4] = 32'h0000_0013;
        dut.imem.mem[5] = 32'h0000_0013;
        run_cycles(4);
        check("x1 final",     dut.rf.regs[1],  32'd0);
        check("x20 final",    dut.rf.regs[20], 32'd17);
        check("x30 final",    dut.rf.regs[30], 32'd0);
        check("mem[4] final", dut.dmem.mem[4], 32'd0);

        // Final summary
        $display("\nCPU SYSTEMVERILOG TEST SUMMARY: checks=%0d errors=%0d",
                 checks, errors);
        if (errors != 0)
            $fatal(1, "CPU SYSTEMVERILOG TESTS FAILED");

        $display("ALL CPU SYSTEMVERILOG TESTS PASSED");
        $finish;
    end

endmodule

`default_nettype wire
