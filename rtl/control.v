module control (
    input [6:0] opcode,
    input [2:0] func3,
    input [6:0] func7,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg alu_src,         // 0 = rv2, 1 = imm
    output reg branch,
    output reg jump,
    output reg [3:0] alu_ctrl,  // 0 = add, 1 = sub, ... 
    output reg [1:0] result_src // 00 = ALU result, 01 = mem read data, 10 = PC + 4, 11 = imm
);
    // opcode
    localparam LUI      = 7'b0110111; // lui
    localparam OP       = 7'b0110011; // add, sub, ...
    localparam OP_IMM   = 7'b0010011; // addi, slti, xori, ... 
    localparam LOAD     = 7'b0000011; // lb, lbu, lh, lhu, lw
    localparam STORE    = 7'b0100011; // sb, sh, sw
    localparam BRANCH   = 7'b1100011; // beq, bne, blt, bge, bltu, bgeu
    localparam JAL      = 7'b1101111; // jal
    localparam JALR     = 7'b1100111; // jalr

    // func3
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

    localparam BEQ3     = ADD3;
    localparam BNE3     = SLL3;
    localparam BLT3     = XOR3;
    localparam BGE3     = SRL3;
    localparam BLTU3    = OR3;
    localparam BGEU3    = AND3;

    // func7
    localparam ADD7     = 7'b0000000;
    localparam SLL7     = ADD7;
    localparam SLT7     = ADD7;
    localparam SLTU7    = ADD7;
    localparam XOR7     = ADD7;
    localparam SRL7     = ADD7;
    localparam OR7      = ADD7;
    localparam AND7     = ADD7;
    localparam SUB7     = 7'b0100000;
    localparam SRA7     = SUB7;

    // alu_ctrl
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

    // result_src
    localparam RESULT_ALU = 2'b00;
    localparam RESULT_MEM = 2'b01;
    localparam RESULT_PC4 = 2'b10;
    localparam RESULT_IMM = 2'b11;

    always @(*) begin
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        alu_src     = 1'b0;
        branch      = 1'b0;
        jump        = 1'b0;
        alu_ctrl    = ALU_ADD;
        result_src  = RESULT_ALU;

        case(opcode)
            LUI: begin
                reg_write   = 1'b1;
                result_src  = RESULT_IMM;
            end
            OP: begin
                reg_write   = 1'b1;
                alu_src     = 1'b0;

                case({func7, func3})
                    {ADD7, ADD3}:   alu_ctrl = ALU_ADD;
                    {SUB7, SUB3}:   alu_ctrl = ALU_SUB;
                    {SLL7, SLL3}:   alu_ctrl = ALU_SLL;
                    {SLT7, SLT3}:   alu_ctrl = ALU_SLT;
                    {SLTU7, SLTU3}: alu_ctrl = ALU_SLTU;
                    {XOR7, XOR3}:   alu_ctrl = ALU_XOR;
                    {SRL7, SRL3}:   alu_ctrl = ALU_SRL;
                    {SRA7, SRA3}:   alu_ctrl = ALU_SRA;
                    {OR7, OR3}:     alu_ctrl = ALU_OR;
                    {AND7, AND3}:   alu_ctrl = ALU_AND;
                    default:        alu_ctrl = ALU_ADD;
                endcase
            end
            OP_IMM: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;

                case(func3)
                    ADD3:    alu_ctrl = ALU_ADD;
                    SLL3:    alu_ctrl = ALU_SLL;
                    SLT3:    alu_ctrl = ALU_SLT;
                    SLTU3:   alu_ctrl = ALU_SLTU;
                    XOR3:    alu_ctrl = ALU_XOR;
                    SRL3:    alu_ctrl = (func7 == SRA7) ? ALU_SRA : ALU_SRL;
                    OR3:     alu_ctrl = ALU_OR;
                    AND3:    alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            LOAD: begin
                reg_write   = 1'b1;
                mem_read    = 1'b1;
                alu_src     = 1'b1;
                alu_ctrl    = ALU_ADD;
                result_src  = RESULT_MEM;
            end
            STORE: begin
                mem_write   = 1'b1;
                alu_src     = 1'b1;
                alu_ctrl    = ALU_ADD;
            end
            BRANCH: begin
                branch      = 1'b1;

                case(func3)
                    BEQ3, BNE3:   alu_ctrl = ALU_SUB;
                    BLT3, BGE3:   alu_ctrl = ALU_SLT;
                    BLTU3, BGEU3: alu_ctrl = ALU_SLTU;
                    default:      alu_ctrl = ALU_SUB;
                endcase
            end
            JAL: begin
                reg_write   = 1'b1;
                jump        = 1'b1;
                result_src  = RESULT_PC4;
            end
            JALR: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                jump        = 1'b1;
                alu_ctrl    = ALU_ADD;
                result_src  = RESULT_PC4;
            end
            default: begin
            end
        endcase
    end

endmodule
