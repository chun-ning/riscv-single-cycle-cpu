`timescale 1ns / 1ps

module tb_control;
    reg [6:0] opcode;
    reg [2:0] func3;
    reg [6:0] func7;

    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire alu_src;
    wire branch;
    wire jump;
    wire [3:0] alu_ctrl;
    wire [1:0] result_src;

    localparam LUI      = 7'b0110111;
    localparam OP       = 7'b0110011;
    localparam OP_IMM   = 7'b0010011;
    localparam LOAD     = 7'b0000011;
    localparam STORE    = 7'b0100011;
    localparam BRANCH   = 7'b1100011;
    localparam JAL      = 7'b1101111;
    localparam JALR     = 7'b1100111;

    localparam ADD3     = 3'b000;
    localparam SUB3     = ADD3;
    localparam SLL3     = 3'b001;
    localparam SLT3     = 3'b010;
    localparam SLTU3    = 3'b011;
    localparam XOR3     = 3'b100;
    localparam SRL3     = 3'b101;
    localparam SRA3     = SRL3;
    localparam OR3      = 3'b110;
    localparam AND3     = 3'b111;

    localparam ADD7     = 7'b0000000;
    localparam SUB7     = 7'b0100000;
    localparam SRA7     = SUB7;

    localparam ALU_ADD  = 4'h0;
    localparam ALU_SUB  = 4'h1;
    localparam ALU_AND  = 4'h2;
    localparam ALU_OR   = 4'h3;
    localparam ALU_XOR  = 4'h4;
    localparam ALU_SLL  = 4'h5;
    localparam ALU_SRL  = 4'h6;
    localparam ALU_SRA  = 4'h7;
    localparam ALU_SLT  = 4'h8;
    localparam ALU_SLTU = 4'h9;

    localparam RESULT_ALU = 2'b00;
    localparam RESULT_MEM = 2'b01;
    localparam RESULT_PC4 = 2'b10;
    localparam RESULT_IMM = 2'b11;

    integer errors;

    control dut(
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .branch(branch),
        .jump(jump),
        .alu_ctrl(alu_ctrl),
        .result_src(result_src)
    );

    task check;
        input [255:0] test_name;
        input exp_reg_write;
        input exp_mem_read;
        input exp_mem_write;
        input exp_alu_src;
        input exp_branch;
        input exp_jump;
        input [3:0] exp_alu_ctrl;
        input [1:0] exp_result_src;
        begin
            #1;
            if ((reg_write !== exp_reg_write) ||
                (mem_read !== exp_mem_read) ||
                (mem_write !== exp_mem_write) ||
                (alu_src !== exp_alu_src) ||
                (branch !== exp_branch) ||
                (jump !== exp_jump) ||
                (alu_ctrl !== exp_alu_ctrl) ||
                (result_src !== exp_result_src)) begin
                $display("FAIL: test=%s opcode=%b func3=%b func7=%b exp reg_write=%b mem_read=%b mem_write=%b alu_src=%b branch=%b jump=%b alu_ctrl=%h result_src=%b got reg_write=%b mem_read=%b mem_write=%b alu_src=%b branch=%b jump=%b alu_ctrl=%h result_src=%b",
                         test_name, opcode, func3, func7,
                         exp_reg_write, exp_mem_read, exp_mem_write,
                         exp_alu_src, exp_branch, exp_jump,
                         exp_alu_ctrl, exp_result_src,
                         reg_write, mem_read, mem_write, alu_src, branch, jump,
                         alu_ctrl, result_src);
                errors = errors + 1;
            end else begin
                $display("PASS: test=%s opcode=%b func3=%b func7=%b reg_write=%b mem_read=%b mem_write=%b alu_src=%b branch=%b jump=%b alu_ctrl=%h result_src=%b",
                         test_name, opcode, func3, func7,
                         reg_write, mem_read, mem_write, alu_src, branch, jump,
                         alu_ctrl, result_src);
            end
        end
    endtask

    initial begin
        $dumpfile("waves/control.vcd");
        $dumpvars(0, tb_control);

        errors = 0;

        $display("Starting control test...");

        // LUI: write immediate to rd
        opcode = LUI;
        func3 = 3'b000;
        func7 = 7'b0000000;
        check("LUI", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD, RESULT_IMM);

        // OP / R-type ALU operations
        opcode = OP;
        func3 = ADD3;
        func7 = ADD7;
        check("OP ADD", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD, RESULT_ALU);

        opcode = OP;
        func3 = SUB3;
        func7 = SUB7;
        check("OP SUB", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_SUB, RESULT_ALU);

        opcode = OP;
        func3 = SLL3;
        func7 = ADD7;
        check("OP SLL", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_SLL, RESULT_ALU);

        opcode = OP;
        func3 = SLT3;
        func7 = ADD7;
        check("OP SLT", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_SLT, RESULT_ALU);

        opcode = OP;
        func3 = SLTU3;
        func7 = ADD7;
        check("OP SLTU", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_SLTU, RESULT_ALU);

        opcode = OP;
        func3 = XOR3;
        func7 = ADD7;
        check("OP XOR", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_XOR, RESULT_ALU);

        opcode = OP;
        func3 = SRL3;
        func7 = ADD7;
        check("OP SRL", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_SRL, RESULT_ALU);

        opcode = OP;
        func3 = SRA3;
        func7 = SRA7;
        check("OP SRA", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_SRA, RESULT_ALU);

        opcode = OP;
        func3 = OR3;
        func7 = ADD7;
        check("OP OR", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_OR, RESULT_ALU);

        opcode = OP;
        func3 = AND3;
        func7 = ADD7;
        check("OP AND", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_AND, RESULT_ALU);

        // OP_IMM / I-type ALU operations
        opcode = OP_IMM;
        func3 = ADD3;
        func7 = ADD7;
        check("OP_IMM ADDI", 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, ALU_ADD, RESULT_ALU);

        opcode = OP_IMM;
        func3 = SLL3;
        func7 = ADD7;
        check("OP_IMM SLLI", 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, ALU_SLL, RESULT_ALU);

        opcode = OP_IMM;
        func3 = SRL3;
        func7 = ADD7;
        check("OP_IMM SRLI", 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, ALU_SRL, RESULT_ALU);

        opcode = OP_IMM;
        func3 = SRA3;
        func7 = SRA7;
        check("OP_IMM SRAI", 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, ALU_SRA, RESULT_ALU);

        opcode = OP_IMM;
        func3 = AND3;
        func7 = ADD7;
        check("OP_IMM ANDI", 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, ALU_AND, RESULT_ALU);

        // LOAD / STORE
        opcode = LOAD;
        func3 = 3'b010;
        func7 = 7'b0000000;
        check("LOAD", 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, ALU_ADD, RESULT_MEM);

        opcode = STORE;
        func3 = 3'b010;
        func7 = 7'b0000000;
        check("STORE", 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, ALU_ADD, RESULT_ALU);

        // BRANCH comparisons
        opcode = BRANCH;
        func3 = 3'b000;
        func7 = 7'b0000000;
        check("BRANCH BEQ", 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, ALU_SUB, RESULT_ALU);

        opcode = BRANCH;
        func3 = 3'b100;
        func7 = 7'b0000000;
        check("BRANCH BLT", 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, ALU_SLT, RESULT_ALU);

        opcode = BRANCH;
        func3 = 3'b110;
        func7 = 7'b0000000;
        check("BRANCH BLTU", 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, ALU_SLTU, RESULT_ALU);

        // Jumps
        opcode = JAL;
        func3 = 3'b000;
        func7 = 7'b0000000;
        check("JAL", 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALU_ADD, RESULT_PC4);

        opcode = JALR;
        func3 = 3'b000;
        func7 = 7'b0000000;
        check("JALR", 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, ALU_ADD, RESULT_PC4);

        // Unsupported opcode
        opcode = 7'b0000000;
        func3 = 3'b000;
        func7 = 7'b0000000;
        check("DEFAULT unsupported opcode", 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD, RESULT_ALU);

        if (errors == 0) begin
            $display("All control tests passed.");
        end else begin
            $display("control tests failed with %0d error(s).", errors);
        end

        $finish;
    end

endmodule
