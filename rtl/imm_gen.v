module imm_gen(
    input [31:0] instr,
    output reg [31:0] imm
);
    // https://msyksphinz-self.github.io/riscv-isadoc/
    wire [6:0] opcode;
    assign opcode = instr[6:0];

    // opcode
    localparam LUI      = 7'b0110111; // lui
    localparam OP_IMM   = 7'b0010011; // addi, slti, xori, ... 
    localparam LOAD     = 7'b0000011; // lb, lbu, lh, lhu, lw
    localparam STORE    = 7'b0100011; // sb, sh, sw
    localparam BRANCH   = 7'b1100011; // beq, bne, blt, bge, bltu, bgeu
    localparam JAL      = 7'b1101111; // jal
    localparam JALR     = 7'b1100111; // jalr

    always @(*) begin
        case(opcode)
            LUI: begin
                imm = {instr[31:12], 12'b0};
            end
            OP_IMM, LOAD: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end
            STORE: begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            BRANCH: begin
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            JAL: begin
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            JALR: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end
            default: imm = 32'd0;
        endcase
    end

endmodule
