`timescale 1ns/1ps
`default_nettype none

// Functional coverage monitoring
module cpu_coverage (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instruction,
    input  logic [31:0] rv1,
    input  logic [31:0] rv2,
    input  logic [31:0] immediate,
    input  logic [3:0]  alu_ctrl,
    input  logic        branch_taken,
    input  logic [4:0]  writeback_rd,
    output logic        coverage_complete
);
    localparam logic [6:0] OPCODE_LUI    = 7'b0110111;
    localparam logic [6:0] OPCODE_OP     = 7'b0110011;
    localparam logic [6:0] OPCODE_OP_IMM = 7'b0010011;
    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JAL    = 7'b1101111;
    localparam logic [6:0] OPCODE_JALR   = 7'b1100111;

    localparam int NUM_INSTRUCTION_BINS = 30;
    localparam int NUM_BRANCH_BINS      = 6;
    localparam int NUM_ALU_BINS         = 10;
    localparam int NUM_CORNER_BINS      = 7;

    logic [NUM_INSTRUCTION_BINS-1:0] instruction_coverage;
    logic [NUM_BRANCH_BINS-1:0]      branch_taken_coverage;
    logic [NUM_BRANCH_BINS-1:0]      branch_not_taken_coverage;
    logic [NUM_ALU_BINS-1:0]         alu_coverage;
    logic [NUM_CORNER_BINS-1:0]      corner_coverage;

    assign coverage_complete =
        (&instruction_coverage)      &&
        (&branch_taken_coverage)     &&
        (&branch_not_taken_coverage) &&
        (&alu_coverage)              &&
        (&corner_coverage);

    initial begin
        instruction_coverage      = '0;
        branch_taken_coverage     = '0;
        branch_not_taken_coverage = '0;
        alu_coverage              = '0;
        corner_coverage           = '0;
    end

    function automatic int branch_bin(input logic [2:0] funct3);
        begin
            case (funct3)
                3'b000: branch_bin = 0; // beq
                3'b001: branch_bin = 1; // bne
                3'b100: branch_bin = 2; // blt
                3'b101: branch_bin = 3; // bge
                3'b110: branch_bin = 4; // bltu
                3'b111: branch_bin = 5; // bgeu
                default: branch_bin = -1;
            endcase
        end
    endfunction

    function automatic int instruction_bin(input logic [31:0] instr);
        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;
        int         bbin;
        begin
            opcode = instr[6:0];
            funct3 = instr[14:12];
            funct7 = instr[31:25];
            instruction_bin = -1;

            case (opcode)
                OPCODE_OP: begin
                    case ({funct7, funct3})
                        {7'b0000000, 3'b000}: instruction_bin = 0;  // add
                        {7'b0100000, 3'b000}: instruction_bin = 1;  // sub
                        {7'b0000000, 3'b001}: instruction_bin = 2;  // sll
                        {7'b0000000, 3'b010}: instruction_bin = 3;  // slt
                        {7'b0000000, 3'b011}: instruction_bin = 4;  // sltu
                        {7'b0000000, 3'b100}: instruction_bin = 5;  // xor
                        {7'b0000000, 3'b101}: instruction_bin = 6;  // srl
                        {7'b0100000, 3'b101}: instruction_bin = 7;  // sra
                        {7'b0000000, 3'b110}: instruction_bin = 8;  // or
                        {7'b0000000, 3'b111}: instruction_bin = 9;  // and
                        default: instruction_bin = -1;
                    endcase
                end

                OPCODE_OP_IMM: begin
                    case (funct3)
                        3'b000: instruction_bin = 10; // addi
                        3'b001: instruction_bin =
                            (funct7 == 7'b0000000) ? 11 : -1; // slli
                        3'b010: instruction_bin = 12; // slti
                        3'b011: instruction_bin = 13; // sltiu
                        3'b100: instruction_bin = 14; // xori
                        3'b101: begin
                            if (funct7 == 7'b0000000)
                                instruction_bin = 15; // srli
                            else if (funct7 == 7'b0100000)
                                instruction_bin = 16; // srai
                        end
                        3'b110: instruction_bin = 17; // ori
                        3'b111: instruction_bin = 18; // andi
                        default: instruction_bin = -1;
                    endcase
                end

                OPCODE_LOAD:
                    instruction_bin = (funct3 == 3'b010) ? 19 : -1; // lw
                OPCODE_STORE:
                    instruction_bin = (funct3 == 3'b010) ? 20 : -1; // sw
                OPCODE_BRANCH: begin
                    bbin = branch_bin(funct3);
                    instruction_bin = (bbin >= 0) ? 21 + bbin : -1;
                end
                OPCODE_JAL:
                    instruction_bin = 27;
                OPCODE_JALR:
                    instruction_bin = (funct3 == 3'b000) ? 28 : -1;
                OPCODE_LUI:
                    instruction_bin = 29;
                default:
                    instruction_bin = -1;
            endcase
        end
    endfunction

    function automatic int count_instruction_bins;
        int count;
        begin
            count = 0;
            for (int i = 0; i < NUM_INSTRUCTION_BINS; i++)
                count += instruction_coverage[i];
            count_instruction_bins = count;
        end
    endfunction

    function automatic int count_branch_bins(input logic [NUM_BRANCH_BINS-1:0] mask);
        int count;
        begin
            count = 0;
            for (int i = 0; i < NUM_BRANCH_BINS; i++)
                count += mask[i];
            count_branch_bins = count;
        end
    endfunction

    function automatic int count_alu_bins;
        int count;
        begin
            count = 0;
            for (int i = 0; i < NUM_ALU_BINS; i++)
                count += alu_coverage[i];
            count_alu_bins = count;
        end
    endfunction

    function automatic int count_corner_bins;
        int count;
        begin
            count = 0;
            for (int i = 0; i < NUM_CORNER_BINS; i++)
                count += corner_coverage[i];
            count_corner_bins = count;
        end
    endfunction

    // Sample stable decode and operand values halfway between active edges.
    always @(negedge clk) begin : sample_functional_coverage
        int ibin;
        int bbin;

        if (!reset) begin
            ibin = instruction_bin(instruction);
            if (ibin >= 0)
                instruction_coverage[ibin] = 1'b1;

            // alu_ctrl encodings 0-9 are the ten ALU operations in this core.
            if ((ibin >= 0) && (alu_ctrl <= 4'h9))
                alu_coverage[alu_ctrl] = 1'b1;

            if (instruction[6:0] == OPCODE_BRANCH) begin
                bbin = branch_bin(instruction[14:12]);
                if (bbin >= 0) begin
                    if (branch_taken)
                        branch_taken_coverage[bbin] = 1'b1;
                    else
                        branch_not_taken_coverage[bbin] = 1'b1;
                end
            end

            // Defined corner-case bins for this project.
            if ((rv1 == 32'd0) || (rv2 == 32'd0))
                corner_coverage[0] = 1'b1; // zero operand
            if (rv1[31] || rv2[31])
                corner_coverage[1] = 1'b1; // negative operand
            if (immediate == 32'd0)
                corner_coverage[2] = 1'b1; // zero immediate
            if (immediate[31])
                corner_coverage[3] = 1'b1; // negative immediate
            if (writeback_rd == 5'd0)
                corner_coverage[4] = 1'b1; // destination x0
            if (((instruction[6:0] == OPCODE_BRANCH) ||
                 (instruction[6:0] == OPCODE_JAL)) && immediate[31])
                corner_coverage[5] = 1'b1; // backward branch/jump
            if ((rv1[31] != rv2[31]) &&
                ((instruction[14:12] == 3'b010) ||
                 (instruction[14:12] == 3'b011)))
                corner_coverage[6] = 1'b1; // signed/unsigned comparison edge
        end
    end

    task automatic report_missing_branch_bins;
        begin
            if (!branch_taken_coverage[0])     $display("  MISSING: BEQ taken");
            if (!branch_not_taken_coverage[0]) $display("  MISSING: BEQ not taken");
            if (!branch_taken_coverage[1])     $display("  MISSING: BNE taken");
            if (!branch_not_taken_coverage[1]) $display("  MISSING: BNE not taken");
            if (!branch_taken_coverage[2])     $display("  MISSING: BLT taken");
            if (!branch_not_taken_coverage[2]) $display("  MISSING: BLT not taken");
            if (!branch_taken_coverage[3])     $display("  MISSING: BGE taken");
            if (!branch_not_taken_coverage[3]) $display("  MISSING: BGE not taken");
            if (!branch_taken_coverage[4])     $display("  MISSING: BLTU taken");
            if (!branch_not_taken_coverage[4]) $display("  MISSING: BLTU not taken");
            if (!branch_taken_coverage[5])     $display("  MISSING: BGEU taken");
            if (!branch_not_taken_coverage[5]) $display("  MISSING: BGEU not taken");
        end
    endtask

    task automatic report;
        int instruction_hits;
        int branch_taken_hits;
        int branch_not_taken_hits;
        int alu_hits;
        int corner_hits;
        begin
            instruction_hits      = count_instruction_bins();
            branch_taken_hits     = count_branch_bins(branch_taken_coverage);
            branch_not_taken_hits = count_branch_bins(branch_not_taken_coverage);
            alu_hits              = count_alu_bins();
            corner_hits           = count_corner_bins();

            $display("\nFUNCTIONAL COVERAGE REPORT");
            $display("--------------------------");
            $display("Supported instructions:    %0d/%0d (%0.1f%%)",
                     instruction_hits, NUM_INSTRUCTION_BINS,
                     100.0 * instruction_hits / NUM_INSTRUCTION_BINS);
            $display("Branch taken outcomes:      %0d/%0d (%0.1f%%)",
                     branch_taken_hits, NUM_BRANCH_BINS,
                     100.0 * branch_taken_hits / NUM_BRANCH_BINS);
            $display("Branch not-taken outcomes:  %0d/%0d (%0.1f%%)",
                     branch_not_taken_hits, NUM_BRANCH_BINS,
                     100.0 * branch_not_taken_hits / NUM_BRANCH_BINS);
            $display("ALU operations:             %0d/%0d (%0.1f%%)",
                     alu_hits, NUM_ALU_BINS,
                     100.0 * alu_hits / NUM_ALU_BINS);
            $display("Defined corner cases:       %0d/%0d (%0.1f%%)",
                     corner_hits, NUM_CORNER_BINS,
                     100.0 * corner_hits / NUM_CORNER_BINS);

            if (!coverage_complete) begin
                $display("Coverage holes:");
                report_missing_branch_bins();
            end

            $display("NOTE: Percentages are functional coverage of the defined bins, not proof of complete CPU correctness.");
        end
    endtask

endmodule

`default_nettype wire
