`timescale 1ns/1ps
`default_nettype none

module cpu_reference_model (
    input logic        clk,
    input logic        reset,
    input logic [31:0] debug_pc,
    input logic [31:0] debug_instr,
    input logic [31:0] actual_regs [0:31],
    input logic [31:0] actual_mem [0:511],
    output logic reference_complete,
    output logic [31:0] mismatch_count
);
    localparam logic [6:0] OPCODE_LUI    = 7'b0110111;
    localparam logic [6:0] OPCODE_OP     = 7'b0110011;
    localparam logic [6:0] OPCODE_OP_IMM = 7'b0010011;
    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JAL    = 7'b1101111;
    localparam logic [6:0] OPCODE_JALR   = 7'b1100111;

    logic [31:0] reference_pc;
    logic [31:0] reference_regs [0:31];
    logic [31:0] reference_mem [0:511];

    // Reset reference model
    task automatic reset_model;
        reference_pc = 32'd0;

        for (int i = 0; i < 32; i++)
            reference_regs[i] = 32'd0;

        for (int i = 0; i < 512; i++)
            reference_mem[i] = 32'd0;
    endtask

    // Modeling instructions
    task automatic model_step (input logic [31:0] instruction);
        logic [6:0] opcode = instruction[6:0];
        logic [4:0] rd     = instruction[11:7];
        logic [4:0] rs1    = instruction[19:15];
        logic [4:0] rs2    = instruction[24:20];
        logic [2:0] funct3 = instruction[14:12];
        logic [6:0] funct7 = instruction[31:25];
        logic [4:0] shamt  = instruction[24:20];

        logic [31:0] immediate_i;
        logic [31:0] immediate_s;
        logic [31:0] immediate_b;
        logic [31:0] immediate_u;
        logic [31:0] immediate_j;
        logic [31:0] address;
        logic [31:0] next_pc;

        immediate_i = {{20{instruction[31]}}, instruction[31:20]};
        immediate_s = {{20{instruction[31]}}, instruction[31:25],
                       instruction[11:7]};
        immediate_b = {{19{instruction[31]}}, instruction[31],
                       instruction[7], instruction[30:25],
                       instruction[11:8], 1'b0};
        immediate_u = {instruction[31:12], 12'b0};
        immediate_j = {{11{instruction[31]}}, instruction[31],
                       instruction[19:12], instruction[20],
                       instruction[30:21], 1'b0};

        // Default next_pc (PC + 4)
        next_pc = reference_pc + 32'd4;

        case (opcode)
            OPCODE_OP: begin
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: // add
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] + reference_regs[rs2];

                    {7'b0100000, 3'b000}: // sub
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] - reference_regs[rs2];

                    {7'b0000000, 3'b001}: // sll
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] << reference_regs[rs2][4:0];

                    {7'b0000000, 3'b010}: // slt
                        if (rd != 5'd0)
                            reference_regs[rd] =
                                ($signed(reference_regs[rs1]) <
                                 $signed(reference_regs[rs2])) ? 32'd1 : 32'd0;

                    {7'b0000000, 3'b011}: // sltu
                        if (rd != 5'd0)
                            reference_regs[rd] =
                                (reference_regs[rs1] < reference_regs[rs2]) ? 32'd1 : 32'd0;

                    {7'b0000000, 3'b100}: // xor
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] ^ reference_regs[rs2];

                    {7'b0000000, 3'b101}: // srl
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] >> reference_regs[rs2][4:0];

                    {7'b0100000, 3'b101}: // sra
                        if (rd != 5'd0)
                            reference_regs[rd] =
                                $signed(reference_regs[rs1]) >>> reference_regs[rs2][4:0];

                    {7'b0000000, 3'b110}: // or
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] | reference_regs[rs2];

                    {7'b0000000, 3'b111}: // and
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] & reference_regs[rs2];

                    default: begin
                    end
                endcase
            end

            OPCODE_OP_IMM: begin
                case (funct3)
                    3'b000: // addi
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] + immediate_i;

                    3'b001: // slli
                        if ((funct7 == 7'b0000000) && (rd != 5'd0))
                            reference_regs[rd] = reference_regs[rs1] << shamt;

                    3'b010: // slti
                        if (rd != 5'd0)
                            reference_regs[rd] =
                                ($signed(reference_regs[rs1]) < $signed(immediate_i)) ?
                                32'd1 : 32'd0;

                    3'b011: // sltiu
                        if (rd != 5'd0)
                            reference_regs[rd] =
                                (reference_regs[rs1] < immediate_i) ? 32'd1 : 32'd0;

                    3'b100: // xori
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] ^ immediate_i;

                    3'b101: begin
                        if ((funct7 == 7'b0000000) && (rd != 5'd0)) // srli
                            reference_regs[rd] = reference_regs[rs1] >> shamt;
                        else if ((funct7 == 7'b0100000) && (rd != 5'd0)) // srai
                            reference_regs[rd] = $signed(reference_regs[rs1]) >>> shamt;
                    end

                    3'b110: // ori
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] | immediate_i;

                    3'b111: // andi
                        if (rd != 5'd0)
                            reference_regs[rd] = reference_regs[rs1] & immediate_i;

                    default: begin
                    end
                endcase
            end

            OPCODE_LOAD: begin // lw
                if (funct3 == 3'b010) begin
                    address = reference_regs[rs1] + immediate_i;
                    if (rd != 5'd0)
                        reference_regs[rd] = reference_mem[address[10:2]];
                end
            end

            OPCODE_STORE: begin // sw
                if (funct3 == 3'b010) begin
                    address = reference_regs[rs1] + immediate_s;
                    reference_mem[address[10:2]] = reference_regs[rs2];
                end
            end

            OPCODE_BRANCH: begin
                case (funct3)
                    3'b000: // beq
                        if (reference_regs[rs1] == reference_regs[rs2])
                            next_pc = reference_pc + immediate_b;

                    3'b001: // bne
                        if (reference_regs[rs1] != reference_regs[rs2])
                            next_pc = reference_pc + immediate_b;

                    3'b100: // blt
                        if ($signed(reference_regs[rs1]) < $signed(reference_regs[rs2]))
                            next_pc = reference_pc + immediate_b;

                    3'b101: // bge
                        if ($signed(reference_regs[rs1]) >= $signed(reference_regs[rs2]))
                            next_pc = reference_pc + immediate_b;

                    3'b110: // bltu
                        if (reference_regs[rs1] < reference_regs[rs2])
                            next_pc = reference_pc + immediate_b;

                    3'b111: // bgeu
                        if (reference_regs[rs1] >= reference_regs[rs2])
                            next_pc = reference_pc + immediate_b;

                    default: begin
                    end
                endcase
            end

            OPCODE_LUI: begin
                if (rd != 5'd0)
                    reference_regs[rd] = immediate_u;
            end

            OPCODE_JAL: begin
                if (rd != 5'd0)
                    reference_regs[rd] = reference_pc + 32'd4;
                next_pc = reference_pc + immediate_j;
            end

            OPCODE_JALR: begin
                if (funct3 == 3'b000) begin
                    // Calculate the target from the old rs1 value before rd is updated
                    address = reference_regs[rs1] + immediate_i;
                    if (rd != 5'd0)
                        reference_regs[rd] = reference_pc + 32'd4;
                    next_pc = address & 32'hffff_fffe;
                end
            end

            default: begin
            end
        endcase

        reference_regs[0] = 32'd0;
        reference_pc = next_pc;
    endtask

    // Assert DUT state matches with reference model
    task automatic compare_state;
        assert (debug_pc === reference_pc)
        else begin
            mismatch_count++;
            $error("PC mismatch: DUT=%08h REF=%08h INSTR=%08h",
                   debug_pc, reference_pc, debug_instr);
        end

        for (int i = 0; i < 32; i++) begin
            assert (actual_regs[i] === reference_regs[i])
            else begin
                mismatch_count++;
                $error("Register x%0d mismatch: DUT=%08h REF=%08h PC=%08h INSTR=%08h",
                       i, actual_regs[i], reference_regs[i],
                       debug_pc, debug_instr);
            end
        end

        for (int i = 0; i < 512; i++) begin
            assert (actual_mem[i] === reference_mem[i])
            else begin
                mismatch_count++;
                $error("Memory word %0d mismatch: DUT=%08h REF=%08h PC=%08h INSTR=%08h",
                       i, actual_mem[i], reference_mem[i],
                       debug_pc, debug_instr);
            end
        end

        reference_complete = (mismatch_count == 32'd0);
    endtask

    // Initialize 
    initial begin
        mismatch_count     = 32'd0;
        reference_complete = 1'b1;
        reset_model();
    end

    // Capture the instruction executing at this posedge
    always @(posedge clk) begin : reference_scoreboard
        logic [31:0] executing_instruction;

        executing_instruction = debug_instr;

        if (reset)
            reset_model();
        else
            model_step(executing_instruction);

        #1ps; // Compares with ref model before testbench reports
        compare_state();
    end

endmodule

`default_nettype wire
